# Architecture & Design

This document explains the design decisions behind the dotfiles repository. It is the authoritative reference for understanding, maintaining, and extending the bootstrap pipeline.

---

## Repository Layout

```
dotfiles/
├── stow/                    # GNU Stow packages — each subdirectory maps to $HOME
│   ├── bat/                 # bat syntax-highlighter config + Catppuccin themes
│   ├── bin/                 # Standalone binaries (e.g. win32yank.exe for WSL clipboard)
│   ├── claude/              # Claude Code: CLAUDE.md, role agents, commands, skills, MCP config
│   ├── cursor/              # Cursor: rules, commands, MCP config (skills/agents shared from claude/)
│   ├── git/                 # .gitconfig, .githooks, .config/git/{ignore,credentials}
│   ├── java/                # Maven settings.xml, Eclipse formatter
│   ├── lf/                  # lf file manager config
│   ├── mise/                # .mise.toml — all runtime + tool declarations
│   ├── nvim/                # LazyVim / Neovim config
│   ├── posting/             # Posting HTTP client config
│   ├── scripts/             # Operational scripts → ~/.local/share/dotfiles/scripts/
│   ├── tmux/                # tmux config
│   └── zsh/                 # .zshrc, .p10k.zsh, ~/.config/zsh/ fragments
├── host/                    # Machine-specific config — copied, never symlinked
│   ├── wsl.conf             # Applied to /etc/wsl.conf on WSL machines
│   └── work-wsl/            # Work machine WSL overrides
├── packages/
│   ├── apt.txt              # System packages installed in step 1
│   ├── pip.txt              # pip packages (if any)
│   └── uv-tools.txt         # Python CLI tools installed as isolated uv tools
├── docs/
│   └── ARCHITECTURE.md      # This file
├── CLAUDE.md                # Project rules — never publish secrets (.cursor/rules/ mirrors it)
├── .claude/commands/        # Project commands: /release, /review-staged (.cursor/commands/ mirrors them)
├── install.sh               # Bootstrap entry point — Debian/Ubuntu/WSL2
├── stow.sh                  # Idempotent re-stow — safe to run at any time
├── check-ai-parity.sh       # Guard: skills/agents live only in stow/claude (see AI config)
├── sync.sh                  # Pre-migration export (wsl.conf, repos, BW secrets)
├── CHANGELOG.md             # Keep a Changelog, SemVer — updated with every release
├── VERSION                  # Current version, mirrored by the README badge
└── repos.txt                # Repo manifest (gitignored — restored from Bitwarden)

Scripts resolve the repo through `$DOTFILES` (exported by install.sh, defaulting to
`~/dotfiles`), so a clone in any location works.
```

---

## Bootstrap Philosophy

The install pipeline is designed around three constraints:

1. **Corporate VPN / custom CA certs** — many packages fail TLS validation before company certificates are installed.
2. **WSL2 PATH contamination** — Windows injects its own `PATH` into WSL, which can shadow Linux binaries.
3. **Idempotency** — the script must be safe to re-run on a partially-bootstrapped machine.

These constraints drive the step ordering. Every design decision below traces back to one of them.

---

## Step-by-Step Rationale

### Step 1 — APT packages

System-level packages from `packages/apt.txt`. This includes `npm`, `stow`, `zsh`, `curl`, `git`, and build essentials. These are the only tools that can be installed without cert trust because they come from Debian mirrors over HTTP or system-trusted HTTPS.

> `npm` is installed via APT here (not mise) because the Bitwarden CLI (`bw`) must be available before mise can run. Once mise installs Node, the global npm prefix is re-pointed so there is no conflict.

### Step 2 — WSL PATH guard

WSL2 appends Windows `PATH` entries to the Linux environment by default. This is useful generally, but catastrophic during bootstrap: if `bw.exe` (Windows Bitwarden) appears before `bw` (Linux CLI) in `PATH`, the BW unlock step silently invokes the wrong binary.

The guard scans `PATH` for non-System32 `/mnt/c/` entries. If found:

1. Copies `host/wsl.conf` to `/etc/wsl.conf` — sets `appendWindowsPath=false`.
2. Exits with instructions to run `wsl --shutdown`.

A full WSL restart is required for the `wsl.conf` change to take effect. The script detects `WSL_DISTRO_NAME` to only force-exit inside WSL (not in a plain Linux VM).

### Step 3 — Bitwarden CLI (installed before mise)

The BW CLI is installed via `npm install -g @bitwarden/cli` using the APT-managed Node. It must exist before mise because step 4 fetches secrets that may include corporate CA certificates needed for `mise install`.

`tree-sitter-cli` is bundled here for efficiency since npm is already invoked.

### Step 4 — Bitwarden secrets + VPN certs

`bw-restore.sh` retrieves the following from Bitwarden secure notes (all under `dotfiles/` prefix):

| BW item | Destination |
|---|---|
| `dotfiles/zsh_secrets` | `~/.config/zsh/secrets` |
| `dotfiles/git-credentials` | `~/.config/git/credentials` |
| `dotfiles/kube/<filename>` | `~/.kube/<filename>` |
| `dotfiles/certs/<filename>` | `~/certs/<filename>` |
| `dotfiles/repos` | `$DOTFILES/repos.txt` |
| `dotfiles/ai/<filename>` | `~/.claude/local/<filename>` (`~/.cursor/local` symlinks to it) |

`NODE_TLS_REJECT_UNAUTHORIZED=0` is set around the Bitwarden CLI calls. **This is deliberate and must not be "fixed".** The corporate CA that would validate the connection is itself stored in the vault (`dotfiles/certs/*`) and is only installed into the system trust store at the end of the restore. On a fresh machine the certificate needed to verify the connection is on the far side of that same connection, so no ordering avoids it.

The accepted exposure is the `bw login` / `unlock` / `sync` / `list` traffic on first run. Everything the script writes is created under `umask 077`, and the vault cache is a `mktemp` file, mode 600, removed by an `EXIT` trap — `bw list items` is the entire vault in plaintext and must not outlive the process.

After restore, `sudo update-ca-certificates` installs the fetched certs into the system trust store. All subsequent TLS calls (mise, git, npm) proceed with full certificate validation.

`BW_SESSION` is **not** persisted. Writing it to `~/.config/zsh/secrets` turned a session-scoped unlock key into a durable one, and since that file is uploaded as `dotfiles/zsh_secrets`, the key ended up stored inside the vault it unlocks. `bw-restore.sh` therefore never writes it to disk — it lives only in the environment of the running script, so it cannot reach `dotfiles/zsh_secrets` on the next upload.

### Step 5 — Oh-My-Zsh + plugins

OMZ, `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `powerlevel10k` are cloned with `--depth=1`. Each is guarded to skip if already present.

### Step 6 — GitHub binary installs

Binaries not available in any package manager (e.g. `jirlab`) are fetched from GitHub and placed in `/usr/local/bin`. Pinned to an immutable commit and verified against a recorded SHA256 before install — tracking a branch meant whatever sat on it at that moment was installed as root, unverified.

`cursor-agent` is installed from Cursor's official installer (`https://cursor.com/install`). Not from npm: the npm package named `cursor-agent` is an unrelated third-party project.

### Step 7 — Default shell

`chsh` sets zsh as the login shell. This must happen before Neovim / tmux post-install steps, which expect a zsh environment.

### Step 8 — mise + all tools

mise is the unified tool version manager. It replaces: nvm (Node), pyenv (Python), gvm (Go), SDKMAN (Java/Maven), and manual binary installs.

`stow/mise/.mise.toml` is trusted and activated in bash mode so that `mise install` has access to the full tool set. After installation, the npm global prefix is re-pointed to `~/.npm-global` so that globally installed npm packages survive mise Node upgrades.

### Step 9 — GNU Stow

`stow.sh` symlinks all packages from `stow/` into `$HOME`. See the **Stow Strategy** section below.

### Step 10 — tmux TPM

TPM (Tmux Plugin Manager) is cloned separately from the main tool install because it is not available in mise.

### Step 11 — Git identity

`~/.gitconfig` (versioned) includes `~/.gitconfig_local` (not versioned) for user name and email. If secrets were restored from BW in step 4, `GIT_USER_NAME` and `GIT_USER_EMAIL` are already set. Otherwise the user is prompted interactively and `~/.config/zsh/secrets` is created.

### Step 11c — Agent token tooling

Both tools hook *below* the agent rather than wrapping it: rtk rewrites the agent's bash calls through a `PreToolUse` hook, graphify is a skill it calls. Registration targets `~/.claude/settings.json` and `~/.claude/skills/` — live runtime state, the same reason MCP servers go through the CLI in step 11b. `~/.claude/settings.json` stays untracked: it carries machine-local work context.

Only the graphify skill is registered here. The rtk hook is left to the `claude` and `ai` shell functions, which check it on every launch — one code path instead of two, and it self-heals if `settings.json` is reset.

Two choices keep the tools out of tracked files. `rtk init --hook-only` suppresses `RTK.md` and its `@`-reference. The graphify row in `stow/claude/.claude/CLAUDE.md`'s routing table makes `graphify install`'s own registration a no-op — `~/.claude/CLAUDE.md` symlinks into that tracked file.

Ordered after step 8 (provides `uv`) and step 9 (the CLAUDE.md symlink must exist).

### Step 12 — Post-install

- **`addcerts.sh`** — imports `~/certs/*.crt` into the Java keystore (requires Java from mise step 8).
- **Neovim** — runs `Lazy! sync` headlessly to bootstrap plugins.
- **tmux TPM** — installs tmux plugins non-interactively.
- **`repos-restore.sh`** — clones repos from `repos.txt`. Silently skips VPN-gated repos.

---

## Stow Strategy

### Package auto-discovery

`stow.sh` uses `find -maxdepth 1 -mindepth 1 -type d` to enumerate packages. Adding a new package requires only creating a directory — no script edits.

### No `.bak` files

Stow creates `.bak` backup files when it encounters a real file at a symlink target. This is prevented by:

1. **Pre-removing known conflicts** — `rm -f ~/.zshrc` removes the distro default before stowing.
2. **Pre-creating directories** — `mkdir -p ~/.config/nvim` ensures Stow cannot fold the entire directory into a single symlink. LazyVim writes lockfiles and caches inside `~/.config/nvim/`, so it must remain a real directory.
3. **`--no-folding`** in the repo-root `.stowrc` — prevents Stow from collapsing entire directories when only some files are managed. Each file is linked individually. This is load-bearing: it keeps `~/.config/zsh/` a real directory holding symlinks, so `~/.config/zsh/secrets` is **not** created inside the working tree.
4. **`--restow`** — removes existing symlinks and re-adds them, rather than failing on pre-existing links.

### Mixed file/folder linking

Some packages link individual files (e.g. `zsh/.zshrc`); others link entire subdirectory trees (e.g. `bat/.config/bat/`). `--no-folding` ensures Stow handles both correctly without creating unintended folder-level symlinks.

### Pruning dangling links

Stow only unstows what a package still *contains*, so deleting a file from a package leaves its symlink behind in `$HOME`, now pointing at nothing. Nothing in a plain restow removes it, and a stale link is indistinguishable from a live one to the tool that reads it — which is how a deleted Cursor skill kept being discovered.

After stowing, `stow.sh` walks the top-level paths the packages actually claim, removes every symlink that dangles into `$STOW_DIR`, and then `rmdir`s the directories those removals emptied — stopping short of the top-level deployed directory itself. `-n` reports what it would prune instead.

### XDG-compliant layout

Where possible, configs follow XDG base directory conventions:

| Path | Purpose |
|---|---|
| `~/.config/zsh/secrets` | Sensitive shell exports (not versioned) |
| `~/.config/git/ignore` | Global gitignore (git reads this automatically) |
| `~/.config/git/credentials` | Credential store (pointed to by `.gitconfig`) |

---

## Secret Management

All sensitive files are stored in Bitwarden as **Secure Notes** under the `dotfiles/` prefix. Nothing sensitive is committed to this repository.

**Upload (pre-migration):** `sync.sh` calls `bw-upload.zsh` which upserts each file as a secure note. The upsert is idempotent — safe to run repeatedly.

**Restore (on new machine):** `bw-restore.sh` fetches all items and writes them to their target paths. It does **not** write the active BW session into `~/.config/zsh/secrets` — see **Step 4** above.

**Session handling:** `BW_SESSION` lives only for the duration of the script. Export it yourself (`export BW_SESSION=$(bw unlock --raw)`) if you want it in the current shell.

**`repos.txt`** is treated as a secret because it may contain URLs to private/internal repositories. It is gitignored and stored in Bitwarden under `dotfiles/repos`.

---

## Day-to-Day Workflows

```bash
# Re-stow after adding/moving dotfiles
bash stow.sh
mise run stow       # equivalent via mise task

# Pull latest dotfiles and restow
mise run sync       # git pull --ff-only + stow.sh

# Upgrade mise-managed tools and uv tools
mise run update-tools

# Move a $HOME file into the dotfiles repo
relocate ~/.config/somefile --package zsh

# Before migrating to a new machine
bash sync.sh        # exports wsl.conf, repos, uploads BW secrets

# Manually decode a JWT
jwtdecode <token>

# Upload secrets to Bitwarden
zsh ~/.local/share/dotfiles/scripts/bw-upload.zsh

# Restore secrets on a new machine
bash ~/.local/share/dotfiles/scripts/bw-restore.sh
```

---

## Adding a New Package

1. Create `stow/<package-name>/` mirroring the target path structure from `$HOME`.
2. Place config files inside, preserving the relative path.
3. Run `bash stow.sh` — auto-discovery handles the rest.

Example — adding a new tool `foo` with config at `~/.config/foo/config.toml`:
```
stow/
└── foo/
    └── .config/
        └── foo/
            └── config.toml
```

---

## Extending install.sh

Each step follows the pattern:
```bash
step "Step name"
if <already-done-guard>; then
  skip "reason"
else
  run <command>
  ok "success message"
fi
```

- Use `has <cmd>` to check binary presence.
- Use `run` instead of bare commands — honours `--dry-run`.
- Guard every step — the script must be safe to re-run.
- Keep the step header to one line.

---

## AI assistant configuration

Two assistants (Claude Code, Cursor) run against one machine. Their instruction sets were
duplicated package-for-package until v1.1.0; every rule change had to be applied twice, and the
copies drifted between edits.

**One authoring location.** Skills and agents live only in `stow/claude/.claude/`; Cursor
discovers `~/.claude/skills/` and `~/.claude/agents/` natively, so no second copy and no sync
step are needed. A same-named file under `stow/cursor/` would take precedence and shadow the
shared original — and the failure is invisible, because the assistant still finds *a* skill.
`check-ai-parity.sh` fails on exactly that, and `stow.sh` runs it before stowing, so the contract
holds at deploy time rather than by convention. What remains Cursor-specific, and why, is in
`README.md`.

**Instruction layering.** Five layers, no overlap: a *command* dispatches and relays, an *agent*
owns its workflow and output format, a *skill* owns domain knowledge and any MCP server it
fronts, the *router* (`CLAUDE.md`) owns only the mapping from situation to skill, and Cursor's
*rules* carry the standing contracts that must hold before any skill is read. The router is
loaded on every request, so it routes and never teaches; depth lives in skills, and the long
tail one level deeper in each skill's `references/`. Restating one layer's content in another is
the defect this structure exists to prevent.

Cursor has no router: it discovers skills by their `description`, so a rule exists only to state
a standing contract (`alwaysApply`) or to bind a file type to a skill (`globs`) — never to
duplicate the routing table. The always-on rules that mirror a `CLAUDE.md` section — git,
documentation, precedence — are the tree's only intentional duplication.

**Agents are roles, not pipelines.** Until v1.3.0 the heavy workflows were single agents that
ran a whole task end to end — `ticket-to-merge-agent` read the ticket, designed, implemented,
tested, judged its own work, committed and opened the merge request. Everything it read stayed
in one window, so the review reasoned over the noise of the implementation, and the agent that
wrote a test was the one that wanted it to pass. Those are now six narrow agents —
requirements, architect, developer, test engineer, reviewer, doc writer — each with one
responsibility, a `tools:` fence, an explicit limits section, and one output file. Commands
(`/deliver`, `/ticket-to-merge`, `/mr-review`, `/bug-fix`) sequence them, decide which stages a
task actually needs, and own git; no agent commits. `/mr-review` is the only command that runs
the reviewer, so the verdict is a separate request against a finished branch — not a stage of
the same run that implemented the change. `/deliver` sizes the roster — small
(developer, test engineer), medium (plus requirements), deep (plus architect and docs) — and
anything unanswerable is deep. Size never drops the test engineer; only a diff with no behaviour
to assert does — documentation, formatter output, configuration no runtime reads — and then the
tests are skipped rather than handed to the developer, so the author of the code never judges
it. A diff that outgrows its estimate escalates mid-run.

**Stubs are what makes the deep flow parallel.** The architect does not only describe the
structure, it writes the compiling stubs that fix it — signatures and file existence, never
bodies — against the project's own build. The developer then fills the bodies while the test
engineer writes tests from the criteria and those same stubs, the two running at once. That is
not only faster: the test engineer never receives `implementation.md`, so it cannot copy the
implementation's branches back as assertions, which the old sequential order could only ask it
not to do. Both halves need isolation, so the test engineer gets a detached worktree and its
tests come back as a patch — `/deliver` carries no commit exception, so nothing is committed or
merged. Where the isolation costs too much, the two stages run in order instead: no safe
isolation, no concurrency. Agents cannot renegotiate mid-task, so parallelism is only ever safe
against a contract frozen in a file before both start.

**Hand-offs are artifacts, not transcripts.** Each stage writes one brief into
`.claude/state/<slug>/` and the command passes the *path* to the next agent. Nothing carries the
original prompt, the previous agent's reasoning, or its tool output. The reviewer deliberately
never sees the implementer's notes — it judges the diff against the criteria instead of
re-deriving the author's argument. Agents never call each other: a blocked agent returns
`BLOCKED:` and the command routes it, which makes circular delegation impossible rather than
discouraged.

**Shared mechanics are skills, not copied steps.** `/bug-fix` and `/sonar-fix` had the same
branch, validate, commit and report boilerplate written out in four files; it now lives once in
`change-delivery`. Every Jira MCP call lives in `jira-tickets`, the way Sonar and Loki access
already lived in `sonarqube-validation` and `app-bug-detection`. There is no formatter agent:
formatting is a build step, so it is a bounded permission inside the agents that build — a
subagent spawn would cost more than the command it would run. The rules for adding the next
agent, skill or command are in `ai-config/references/agent-architecture.md`.

**What earns a resident slot.** A rule loaded on every request must change behaviour on a turn
where the matching skill would never load — prohibitions and defaults qualify, reference
knowledge does not. Git, documentation and graphify qualify: by the time you would think to look them up,
the commit, the omission, or the grep has already happened. Brevity qualifies for its floor only, because
the turns it governs are the ones too small to trigger a skill. MCP configuration does not — it
is consulted when `mcp.json` is open — so it lives in `ai-config` and the router keeps a
table row. This is why `CLAUDE.md` is 121 lines and the Cursor rules 142.

**Machine-local overlay.** Anything organisation-specific — project keys, board ids,
documentation repositories, cluster names — lives in `~/.claude/local/*.md`, restored from
Bitwarden and never tracked. Skills name the file to read; they never inline its contents.
`~/.cursor/local` symlinks to the same directory, so one copy serves both.

---

## MCP servers

Cursor (`~/.cursor/mcp.json`) and Claude Code (`~/.claude/mcp-servers.json`) share the same server list. Prefer a plain `npx` entry with a pinned version and the credentials passed through `env`; add a launcher script under `~/.local/share/dotfiles/scripts/` only when a server needs logic the JSON cannot express.

Cursor only injects env vars listed in `mcp.json`, so every variable a server needs must appear in its `env` block. Values come from `~/.config/zsh/secrets` via the interactive shell — a server launched from a GUI that skips interactive zsh sees nothing, which is the one case that still justifies a launcher.

`jira-mcp.sh` is the remaining launcher: it renames `$JIRA_URL`/`$JIRA_TOKEN` to the `JIRA_BASE_URL`/`JIRA_API_TOKEN` names `mcp-jira-cloud` expects and sources `secrets` as a fallback.

Node ignores the OS trust store, so internal hosts fail TLS verification without the corporate chain. `env.zsh` rebuilds the `~/certs` bundle through `node-ca.sh` on every shell start and exports `NODE_EXTRA_CA_CERTS`; MCP servers inherit it by listing that variable in their `env` block.

---

## Known Limitations

- **WSL restart is non-negotiable.** There is no way to reload `wsl.conf` without a full restart of the WSL distribution. The script cannot continue automatically after setting `appendWindowsPath=false`.
- **BW session expiry.** Bitwarden sessions expire after inactivity. If the bootstrap runs after a long delay, `bw unlock` will need to be called again.
- **VPN-gated repos.** `repos-restore.sh` silently skips repos that cannot be cloned. Check the output for warnings after install.
- **Docker.** The APT `docker.io` package provides Docker but may not be the latest version. For production use, consider the official Docker apt repo.
