# MCP servers and git hooks

## MCP servers

Both assistants run the same server list; each registers it its own way.

**Claude Code.** Servers are registered at user scope in `~/.claude.json`, managed by the
`claude mcp` CLI — never hand-edit it. The source of truth is `~/.claude/mcp-servers.json`, one
config per server, applied with `~/.claude/bin/install-mcp-servers.sh`, which also removes a
registered server the file no longer lists. A server added to the file but never applied is not
registered. Java intelligence is the `jdtls-lsp` plugin, which
runs Mason's `jdtls` from `PATH`.

**Cursor.** `~/.cursor/mcp.json`, read directly; restart the agent to apply. Same server list,
`${env:VAR}` instead of `${VAR}`, plus `serena` — Cursor has no LSP plugin of its own. The two
configs are maintained separately and need not match line for line, but the *shared* server list
stays in step when one is added or removed.

Registered: `sonarqube`, `jira`, `gitlab` (`@zereight/mcp-gitlab` with `$GITLAB_TOKEN`, not
GitLab's own remote server, which has no events, files or branches; `GITLAB_TOOLSETS` preloads
core, merge requests, pipelines (jobs, runners, artifacts) and user events; others load
per session through `discover_tools`; never `api`, which bypasses the server's safety checks), `postman`
(remote, Full tool set — `/validation-request` needs its folder tools — `$POSTMAN_API_KEY`), and
six Grafana
instances, app and connector per environment: `grafana-test` / `grafana-test-connector`,
`grafana-prep` / `grafana-prep-connector`, `grafana-prod` / `grafana-prod-connector` (`$GRAFANA_URL_<ENV>`,
`C` suffix for connector). Every Grafana entry passes `--enabled-tools` with the toolsets the
skills use; test and prod add `--disable-write`, prep stays writable for dashboard prototyping.
`grafana-prod` is the only one `app-bug-detection` queries. Cursor-only: `serena`. Atlassian's Rovo server and Cursor's Atlassian
plugin are deliberately absent: `jira` plus REST v2 covers them (see `jira-tickets`).

Serena reuses Mason's `jdtls` instead of downloading its own, through
`ls_specific_settings.java.jdtls_path` and `lombok_path` in `~/.serena/serena_config.yml` —
untracked (absolute paths), appended by `install.sh` after Neovim has synced. The Cursor GUI does
not load `env.zsh`, so the `serena` entry carries `JAVA_HOME` and an sdkman `java` on `PATH`
itself. `serena-agent` is installed from `packages/uv-tools.txt`. Cursor's Serena MCP uses
`--context ide` (built-in; file and shell tools stay with Cursor). `--context ide-assistant`
aliases to `claude-code` and is the wrong context here.

Prefer a plain `npx`/`uvx` entry over a launcher script. The one remaining launcher
(`~/.local/share/dotfiles/scripts/jira-mcp.sh`) is shared by both assistants — edit it there,
never fork a per-assistant copy. Cursor only injects the env vars listed in `mcp.json`, which is the
one case that still justifies a launcher.

Node ignores the OS trust store. `env.zsh` rebuilds the `~/certs` bundle through `node-ca.sh` on
every shell start and exports `NODE_EXTRA_CA_CERTS`; a server reaching an internal host lists that
variable in its `env` block.

A skill fronts the server it owns: callers go through the skill, never at the MCP tools directly.
Never duplicate or commit sensitive configuration into a project repository.

---

## Hooks

Git hooks are stowed from `stow/git/.githooks/` and enabled globally by `core.hooksPath`, so they
run in **every** repository on the machine — a new hook must be safe in a work repo, not just
this one. `prepare-commit-msg` expands `category-message` into the final subject and strips
tooling attribution. `commit-msg` rejects a subject it could not expand, in delivery worktrees
only. `pre-commit` runs `leak-guard.sh --staged`, in the dotfiles repo only.

Write them in POSIX `sh`: `shopt` and other bash-only builtins fail there, and a `.sh` extension
does not make a file bash. Keep them fast — a slow or noisy hook gets bypassed reflexively, which
is worse than no hook.

**Assistant hooks.** Claude's live `~/.claude/settings.json` is never stowed: it holds machine-local
work context. The tracked part is `~/.claude/settings.base.json` (model, plugins, `permissions.deny`,
hooks); `~/.claude/bin/install-settings.sh` merges it with `~/.claude/local/settings.local.json`
(the untracked keys, extracted and uploaded by `bw-upload.zsh`), and merges the same hooks into
`~/.cursor/hooks.json` beside ponytail's. The base owns every key it names; add a hook or a deny
rule there, never in the live file. Scripts live in `~/.claude/bin/`, shared by both assistants:

- `git-guard.sh` (Claude `PreToolUse` Bash and the GitLab merge request tools, Cursor
  `beforeShellExecution` and `beforeMCPExecution`) — git writes only in a delivery worktree; never
  `--no-verify`, a plain `--force` push, or `git add -A`/`.`; no tooling attribution in a merge
  request. Exit 2 blocks in both.
- `leak-guard.sh` (Claude `PreToolUse` Write/Edit, Cursor `preToolUse` Write) — blocks an edit to
  the dotfiles repo containing a term from `~/.claude/local/leak-terms.md` (one per line, `#`
  comments). Messages name the line number, never the term. Shell-written files bypass it; the
  `pre-commit` hook catches those.
- `dotfiles-check.sh` (Claude `Stop`, Cursor `stop`) — with uncommitted AI config in the dotfiles
  repo, runs `check-ai-parity.sh`, `stow.sh -n`, and `check-ai-hooks.sh` when a hook changed; a
  failure goes back to the agent.
- `wt-prune.sh --hook` (session start) — removes delivery worktrees idle > 12 h and clean; keeps
  and reports dirty ones.

`check-ai-hooks.sh` at the repo root tests the guards and `commit-msg`; run it after changing one.
