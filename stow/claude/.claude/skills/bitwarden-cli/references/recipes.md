# Bitwarden CLI — working recipes

Extracted from `bw-upload.zsh` and `bw-restore.sh`. These are the shapes that survived repeated
breakage; prefer adapting them over writing new ones.

---

## Unlock, with session reuse

```bash
bw_ensure_unlocked() {
  # Fast path — no prompt when the caller already exported a live session.
  if [[ -n "${BW_SESSION:-}" ]]; then
    local state
    state=$(bw status --session "$BW_SESSION" 2>/dev/null | jq -r '.status' 2>/dev/null) || state=""
    [[ "$state" == "unlocked" ]] && { log_ok "Vault already unlocked (session reused)"; return 0; }
  fi

  local bw_status                      # NOT `status` — read-only in zsh
  bw_status=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null) || bw_status=""
  if [[ -z "$bw_status" || "$bw_status" == "null" ]]; then
    log_err "Could not read Bitwarden status. Try: bw login   (or: unset BW_SESSION)"
    bw status || true                  # unredirected — show the real error
    exit 1
  fi

  case "$bw_status" in
    unauthenticated) export BW_SESSION="$(bw login  --raw)" ;;
    locked)          export BW_SESSION="$(bw unlock --raw)" ;;
    unlocked)        : ;;
    *) log_err "Unknown Bitwarden status: $bw_status"; exit 1 ;;
  esac
}
```

## Fetch the vault once

```bash
_bw_cache="$(mktemp -t bw-items.XXXXXXXXXX)"
chmod 600 "$_bw_cache"
trap 'rm -f "$_bw_cache"' EXIT INT TERM HUP

bw sync --session "$BW_SESSION" >/dev/null || log_warn "Sync failed — using cached vault"
bw list items --session "$BW_SESSION" > "$_bw_cache"
[[ -s "$_bw_cache" ]] || { log_err "Failed to fetch Bitwarden items"; exit 1; }
```

Read from it with `jq`, never with another `bw` call:

```bash
id=$(jq -r --arg n "$name" 'first(.[] | select(.name == $n) | .id)    // empty' "$_bw_cache")
notes=$(jq -r --arg n "$name" 'first(.[] | select(.name == $n) | .notes) // ""' "$_bw_cache")
```

## Upsert a file as a secure note

`bw create item` / `bw edit item` take **base64-encoded JSON** on the command line.

```zsh
bw_upsert_note() {
  local name="$1" file="$2"
  [[ -f "$file" ]] || { log_warn "File not found, skipping: $file"; return 0; }

  # Encrypted notes cap at 10000 chars and base64 inflates ~4/3 — compress early.
  local src="$file" tmp=""
  if (( $(stat -c%s "$file") > 6500 )); then
    tmp=$(mktemp); { print -r -- '#gz#'; gzip -9 -c "$file" | base64 -w0 } >"$tmp"
    src="$tmp"
  fi

  local id json cached
  id=$(jq -r --arg n "$name" 'first(.[] | select(.name == $n) | .id) // empty' "$_bw_cache")

  if [[ -n "$id" ]]; then
    cached=$(jq -r --arg n "$name" 'first(.[] | select(.name == $n) | .notes) // ""' "$_bw_cache")
    if [[ "$cached" == "$(<"$src")" ]]; then     # idempotent: skip identical bytes
      [[ -n "$tmp" ]] && rm -f "$tmp"
      log_skip "Unchanged: $name"; return 0
    fi
    json=$(bw get item "$id" --session "$BW_SESSION" | jq --rawfile notes "$src" '.notes = $notes')
    bw edit item "$id" "$(print -rn -- "$json" | base64 -w0)" --session "$BW_SESSION" >/dev/null
  else
    json=$(jq -n --arg name "$name" --rawfile notes "$src" \
      '{type: 2, name: $name, notes: $notes, secureNote: {type: 0}}')
    bw create item "$(print -rn -- "$json" | base64 -w0)" --session "$BW_SESSION" >/dev/null
  fi
  [[ -n "$tmp" ]] && rm -f "$tmp"
}
```

`jq --rawfile` embeds file content without quoting or newline damage — never interpolate it into
a JSON string by hand.

**Secure note item shape:** `type: 2` and `secureNote: {type: 0}` are both required; omitting the
inner object creates an item the CLI will not read back as a note.

## Restore a note to a file

```bash
bw_restore_file() {
  local name="$1" dest="$2" mode="${3:-600}" content
  content=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .notes // empty' "$_bw_cache")
  [[ -n "$content" ]] || { log_warn "Not found in Bitwarden: $name — skipping"; return 0; }

  if [[ "$content" == '#gz#'* ]]; then
    content=$(printf '%s' "${content#\#gz\#}" | tr -d '\n' | base64 -d | gunzip) \
      || { log_err "Failed to decompress $name"; return 1; }
  fi

  mkdir -p "$(dirname "$dest")"

  # A truncated download here breaks TLS in a way that is hard to trace later.
  if [[ "$dest" == *.crt || "$dest" == *.pem ]]; then
    printf '%s' "$content" | grep -q -- '-----BEGIN' \
      || { log_warn "Skipping $dest — not a valid PEM block (partial download?)"; return 0; }
  fi

  if [[ -f "$dest" && "$(<"$dest")" == "$content" ]]; then
    chmod "$mode" "$dest"; log_ok "Unchanged: $dest"; return 0
  fi
  printf '%s\n' "$content" > "$dest"
  chmod "$mode" "$dest"
}
```

## Parallel restore

`bw_restore_file` only reads the cache and writes one path, so calls are independent:

```bash
for item in "${names[@]}"; do
  bw_restore_file "$item" "$HOME/target/${item#prefix/}" 644 &
done
wait
```

Two background writers must never target the same path — that was the `~/.cursor/local`
duplicate-write bug. One destination per item; symlink the second reader at the first.

## Item namespace

| Item name | Restores to |
| --- | --- |
| `dotfiles/zsh_secrets` | `~/.config/zsh/secrets` (600) |
| `dotfiles/git-credentials` | `~/.config/git/credentials` (600) |
| `dotfiles/kube/<file>` | `~/.kube/<file>` (600) |
| `dotfiles/certs/<file>` | `~/certs/<file>` (644) |
| `dotfiles/ai/<file>` | `~/.claude/local/<file>` (644) |
| `dotfiles/repos` | `$DOTFILES/repos.txt` |

Select a group with a prefix query rather than listing names:

```bash
mapfile -t names < <(jq -r '.[] | select(.name | startswith("dotfiles/ai/")) | .name' "$_bw_cache")
```
