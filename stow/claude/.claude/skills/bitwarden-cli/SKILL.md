---
name: bitwarden-cli
description: "Scripting the Bitwarden CLI (bw): unlocking and session handling, storing and restoring files as secure notes, upserting items, the encrypted-note size ceiling, batching to avoid per-item round trips, TLS behind a corporate CA, and debugging silent failures. Use when writing or fixing bw-upload/bw-restore or any script that reads or writes a Bitwarden vault."
argument-hint: "What bw operation is failing or being built (e.g. 'upload fails silently', 'note too long', 'prompts for password every item')"
---

# Bitwarden CLI

`bw` is a Node application with a stateful session model and several undocumented ceilings.
Nearly every failure in this repo's history came from one of the six traps below, not from
getting the command wrong.

Working implementations: `bw-upload.zsh` and `bw-restore.sh` in
`stow/scripts/.local/share/dotfiles/scripts/`. Copy their shape rather than reinventing it.
Full snippets in `references/recipes.md`.

---

## The six traps

### 1. `status` is a read-only variable in zsh

```zsh
local status                      # zsh: read-only variable: status
status=$(bw status | jq -r .status)
```

`$status` is zsh's alias for `$?`. Name it `bw_status`, `state`, anything else. This bites only
in `.zsh` scripts — bash is fine — which is why it survives review.

### 2. `shopt` does not exist outside bash

`shopt -s nullglob` in a file run as `sh` gives `shopt: not found` and then the script proceeds
with unexpanded globs. Either commit to `#!/usr/bin/env bash` **and invoke it with bash**, or use
zsh's `setopt nullglob`. A `.sh` extension does not make it bash — check how callers run it.

### 3. Notes are capped at 10,000 **encrypted** characters

The limit applies after encryption, and base64 inflates by ~4/3, so the practical raw ceiling is
well below 10,000. Above ~6,500 bytes, compress:

```zsh
{ print -r -- '#gz#'; gzip -9 -c "$file" | base64 -w0 } > "$tmp"
```

The reader detects the `#gz#` prefix and reverses it. Without this, uploads of a kubeconfig or a
long overlay file fail with *"The field Notes exceeds the maximum encrypted value length of
10000 characters."*

### 4. One `bw list items`, never `bw get` per file

Each `bw` invocation starts a Node process and decrypts the vault. Per-item calls make a 20-file
sync take minutes and re-prompt constantly. Fetch the whole vault once into a mode-600 temp file
and query it with `jq`:

```bash
_bw_cache="$(mktemp -t bw-items.XXXXXXXXXX)"; chmod 600 "$_bw_cache"
trap 'rm -f "$_bw_cache"' EXIT INT TERM HUP
bw list items --session "$BW_SESSION" > "$_bw_cache"
```

That cache holds the **entire vault in plaintext**. Mode 600, `trap`-removed, never inside a repo
working tree, never a path a later step might commit.

### 5. Sessions: reuse, `--raw`, never persist

Unlocking returns a session key that every later call needs. Three rules:

- **`--raw`** — `bw unlock --raw` prints only the key. Without it you parse a human sentence, and
  a second prompt appears.
- **Fast path first** — if `$BW_SESSION` is set, `bw status --session "$X"` and skip the prompt
  when it says `unlocked`. Omitting this is why a script asks for the master password on every
  run.
- **Never write `BW_SESSION` to disk.** It is a durable unlock key; storing it in the secrets file
  puts the key to the vault inside the thing the vault protects.

Dispatch on `bw status`: `unauthenticated` → `bw login --raw`, `locked` → `bw unlock --raw`,
`unlocked` → reuse.

### 6. TLS behind a corporate CA — and the bootstrap paradox

`bw` is Node, so it ignores the OS trust store and needs `NODE_EXTRA_CA_CERTS`. On a fresh
machine the CA that would validate the connection **is itself in the vault**, so no ordering
solves it. That single case justifies `NODE_TLS_REJECT_UNAUTHORIZED=0`, scoped to the bootstrap
run only:

```bash
if node_ca_setup; then _tls_mode="verified"; else
  export NODE_TLS_REJECT_UNAUTHORIZED=0; _tls_mode="UNVERIFIED — bootstrapping"; fi
```

Print the mode. A silent downgrade is the dangerous version. Never apply it to a run that already
has `~/certs`.

---

## Debugging a silent failure

`bw` writes errors to stderr and exits non-zero, and the usual idiom throws both away:

```bash
state=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null) || state=""
```

With `set -e` and `pipefail` the script then dies with no message, or continues on an empty
string. To diagnose: **drop the `2>/dev/null` first** and re-run. Then check, in order —

1. `bw status` — is it `unauthenticated`, `locked`, or an unreachable server?
2. Is `$BW_SESSION` stale? `unset BW_SESSION` and retry.
3. TLS — does `bw sync` fail while `curl` to the same host works? Missing `NODE_EXTRA_CA_CERTS`.
4. Is the payload over the size ceiling (trap 3)?
5. `bw --version` — the JSON shape of `bw status` and item objects has changed across majors.

Keep the error path loud: `|| log_warn "…"` on every `bw` call that is allowed to fail, and an
`exit 1` on every one that is not.

---

## Rules

- **Idempotent by default.** Compare the cached `.notes` against the file and skip when equal —
  it turns a re-run into a no-op and avoids rewriting identical bytes.
- **Everything optional.** Every source file and directory may be absent; warn and continue.
  A restore on a half-provisioned machine must not abort.
- **Validate what you write.** A truncated download that lands in `~/certs` breaks TLS in a way
  that is hard to trace. Check the shape (`-----BEGIN` for PEM) before writing.
- **`umask 077`** at the top of any script that writes secrets, plus an explicit `chmod` per file.
- **Never echo note content** into logs or terminal output — that is the value itself. Log the
  item name and the outcome.
- Items follow one namespace, `dotfiles/<area>/<filename>`, so a restore can select by prefix.
