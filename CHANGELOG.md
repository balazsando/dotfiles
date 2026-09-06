# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] — 2026-09-06

Splits the assistant instruction set along load cost: what must hold on every request stays
resident, everything else moves one level deeper into a skill or a skill's `references/`. Cursor
gets one rule per concern instead of a single mirror of the Claude router.

### Added

- `economy-of-words` skill and its always-on counterpart in the router and Cursor rules — a
  brevity floor for every turn, with the long-form and context-budget guidance loaded on demand.
- Cursor rules split one concern per file: always-on `git`, `documentation`, `layers`,
  `economy-of-words`, plus `globs`-scoped `java` and `neovim` that pull in the matching skill
  when a file of that type is open. Cursor discovers skills by their `description`, so a rule
  no longer restates the routing table.
- `references/` for `ai-config` (frontmatter shapes; MCP registration and git hooks), `lazyvim`
  (setup and extras; LSP and tooling) and `nvim-tmux` (`.tmux.conf` patterns; session
  scripting). Each `SKILL.md` now names which file answers which task.
- Spring, Lombok, Javadoc and test-naming conventions in `java-standards` — stereotype over
  `@Configuration` + `@Bean` (with the hexagonal exception), Lombok required for boilerplate,
  `underTest` and `test<MethodUnderTest>` naming, explicit given/when/then markers.

### Changed

- `claude-config` renamed to `ai-config`: it governs both assistants, and now also owns MCP
  server registration, which left the router. `stow.sh` prunes the old skill's dangling link.
- The router keeps routing, prohibitions, and the machine-local overlay only. The MCP,
  command-and-agent-layering and working-agreement sections moved into `ai-config` — the router
  is read on every request, so prose there is paid for by work that will never use it.
- `/release` audits before it writes: parity, stow dry run and shell syntax, then a read for
  sensitive content, install blockers, wrong documentation, and sources contradicting each
  other. Any of the first three stops the release and hands the findings back instead of a bump.

### Documentation

- `docs/ARCHITECTURE.md` explains the five instruction layers and what earns a resident slot —
  a rule loaded on every request must change behaviour on a turn where its skill would never
  load. `README.md` describes the Cursor rules as they are now.

---

## [1.1.0] — 2026-09-06

Restructures the AI assistant configuration: skills and agents are authored once and shared
between Claude Code and Cursor instead of maintained as two drifting copies, with a guard that
fails the stow when a copy reappears.

### Added

- `check-ai-parity.sh` — fails, naming the offenders, if any skill or agent exists under
  `stow/cursor/.cursor/`. `stow.sh` runs it before stowing, so the sharing contract is enforced
  at deploy time rather than by convention.
- `stow.sh` prunes dangling symlinks after stowing, then removes the directories they emptied.
  Stow only unstows what a package still contains, so deleting a file left its link behind — and
  a stale skill link is indistinguishable from a live one to the assistant that reads it. `-n`
  reports what it would prune.
- Root `CLAUDE.md` and `.cursor/rules/no-leaks.mdc` — the repository is public, so what may never
  enter a tracked file is now stated in the repository itself rather than assumed.
- `/release` (`.claude/commands/`, mirrored in `.cursor/commands/`) — prepares a version:
  changelog entry from the real diff, `VERSION` and README badge together, a README/ARCHITECTURE
  drift check, and the verification run. It prepares files only; committing and tagging stay
  with the user.
- `/sonar-fix` and `/bug-fix` — the two commands that own their steps inline and carry a scoped
  commit exception (`sonar-cleanup/*`, `bugfix/*`; one local commit, never pushed). Backed by two
  new skills, `sonarqube-validation` and `app-bug-detection`, which own all access to the
  `sonarqube` and `grafana-prod` MCP servers.
- Skills `java-standards` (the Java/Spring/Maven rules lifted out of the router),
  `bitwarden-cli` (session handling, the encrypted-note size ceiling, batching, TLS behind a
  corporate CA), and `claude-config` (where a rule belongs across router / command / agent /
  skill, and the Claude–Cursor sharing contract).
- `grafana-prod` MCP server — a third, read-only Grafana instance, the only one
  `app-bug-detection` queries.

### Changed

- Skills and agents now live only in `stow/claude/.claude/`. Cursor discovers `~/.claude/skills/`
  and `~/.claude/agents/` natively, so the 40-odd duplicated files under `stow/cursor/.cursor/`
  were deleted rather than re-synced. The cursor package keeps only what is platform-specific:
  the `.mdc` router rule, thin command dispatchers, and `mcp.json`.
- The global `CLAUDE.md` is a router, not a manual: a situation → skill table, the command/agent/
  skill layering contract, git operations, and MCP configuration. Domain rules that were inlined
  there moved into skills. `global-instructions.mdc` mirrors the same contract for Cursor, and
  the `coding-skills`, `jira-workflow`, and `k8s-environments` rules it absorbed were removed.
- Agents are named `<command>-agent`, matching the command that dispatches them, so the
  dispatch target is derivable rather than remembered.
- `bw-restore.sh` writes machine-local AI context once, to `~/.claude/local/`, and symlinks
  `~/.cursor/local` to it. It previously restored every file twice, letting the two overlays
  diverge. An existing non-empty `~/.cursor/local` directory is left in place with a warning
  rather than deleted.
- The `sonarqube` MCP server runs from a pinned `npx` package instead of a Docker launcher
  script; `sonarqube-mcp.sh` is deleted. `NODE_EXTRA_CA_CERTS` is passed through so it can reach
  an internal host.
- `env.zsh` sources `node-ca.sh` and rebuilds the CA bundle on shell start instead of exporting
  a path that may not exist yet. MCP servers launched from that shell inherit a bundle that is
  actually current.
- Long skills split their depth into `references/`: `dotfiles`, `stow`, and `grafana` now load a
  short SKILL.md and reach for the detail only when needed. Skill descriptions were rewritten to
  say when to load the skill rather than restate its table of contents.

### Fixed

- `node-ca.sh` used a glob to concatenate `~/certs/*.crt`. It is sourced from every interactive
  shell, and zsh errors loudly on a no-match, so a machine with no certificates printed an error
  on every prompt. Uses `find -exec` now.
- The tmux `M-d` split binding shelled out to `tmux display -p` inside a `run-shell` the shell
  had already expanded, so the comparison ran on empty operands and the split direction was
  arbitrary. Uses tmux format substitution, and compares against the client size rather than
  assuming a 2:1 cell aspect.

### Documentation

- `docs/ARCHITECTURE.md` gains an **AI assistant configuration** section — one authoring
  location and why the shadowing failure is invisible, the four-layer instruction split, and the
  machine-local overlay — plus the dangling-link pruning under **Stow Strategy**. Its MCP section
  no longer describes the deleted SonarQube launcher.
- Both layout blocks were out of step with the repository and with each other: `ARCHITECTURE.md`
  was missing the root `CLAUDE.md`, `.claude/commands/`, `check-ai-parity.sh`, `CHANGELOG.md`
  and `VERSION`; `README.md` was missing `host/work-wsl/` and `packages/pip.txt`. Both now list
  what is there.
- `README.md` documents the Claude/Cursor sharing contract and what may not enter a tracked file.

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
