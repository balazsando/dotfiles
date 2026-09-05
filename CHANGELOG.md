# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1] — 2026-09-05

Hotfix release.

### Fixed

- `prepare-commit-msg` exited 1 on any commit with no body — the final `&&` list
  in the subject-rewrite block is false when `$body` is empty, and its status
  became the script's. Git aborted the commit with no message. Added `exit 0`.

### Security

- Moved the last organization-specific values out of tracked config. Jira project
  and board ids and the workflow type/status names left `env.zsh`; the
  kubeconfig-switching aliases, `kcsv`, and `fwd` left `aliases.zsh` — all now in
  `~/.config/zsh/secrets`. The TECH Backlog sprint id and sprint custom field left
  the `jira-tech-ticket-creator` agent for `local/jira-conventions.md`.
- The `kubectl` skill no longer names the environment aliases, the stack suffixes,
  or the Helm configuration repositories in its frontmatter or body — it defers to
  `local/work-environments.md`, as the Cursor rule already did.

### Documentation

- `docs/ARCHITECTURE.md` claimed `bw-upload.zsh` refuses to upload any file
  containing `BW_SESSION`. No such guard exists. Replaced with what actually
  keeps the key off disk: `bw-restore.sh` never persists it.
- Removed the stale line stating that `bw-restore.sh` injects the active BW
  session into `~/.config/zsh/secrets`. It does not, and the claim contradicted
  the Step 4 note directly above it.

---

## [1.0.0] — 2026-09-05

First public release. GNU Stow + mise dotfiles for Debian/Ubuntu/WSL2.

### Added

- `install.sh` — guarded, idempotent bootstrap: APT packages, WSL PATH guard,
  Bitwarden CLI, secrets restore, Oh-My-Zsh, pinned binaries, cursor-agent,
  zsh as login shell, mise toolchain, GNU Stow, tmux TPM, git identity,
  MCP server registration, post-install.
- `stow.sh` — auto-discovering, idempotent restow with a combined conflict pre-scan.
- `sync.sh` — pre-migration export (wsl.conf, repo list, Bitwarden upload).
- `dottest` — run the bootstrap in a throwaway Debian container.
- Bitwarden transport for everything machine-specific: shell secrets, git
  credentials, kubeconfigs, CA certificates, repo manifest, and AI assistant
  context — restored by `bw-restore.sh`, uploaded by `bw-upload.zsh`.
- Configuration for zsh, Neovim/LazyVim, tmux, lf, bat, git, Maven, mise,
  posting, and the Claude Code / Cursor assistant trees.

### Security

- No machine- or organization-specific values are committed. Everything
  private is held in `~/.config/zsh/secrets` and the vault, and consumed as
  variables by the tracked configuration.
- `--no-folding` in `.stowrc` keeps `~/.config/zsh/` a real directory, so the
  secrets file is never created inside the working tree.
- Vault listings are written to a private temp file removed on exit; the
  Bitwarden session key is never persisted to disk.
- Binaries fetched from GitHub are pinned to an immutable commit and verified
  against a recorded SHA256; MCP packages are pinned to exact versions.
