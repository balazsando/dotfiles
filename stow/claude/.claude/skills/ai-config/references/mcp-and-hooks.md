# MCP servers and git hooks

## MCP servers

Both assistants run the same server list; each registers it its own way.

**Claude Code.** Servers are registered at user scope in `~/.claude.json`, managed by the
`claude mcp` CLI — never hand-edit it. The source of truth is `~/.claude/mcp-servers.json`, one
config per server, applied with `~/.claude/bin/install-mcp-servers.sh`. A server added to the
file but never applied is not registered.

**Cursor.** `~/.cursor/mcp.json`, read directly; restart the agent to apply. Same server list,
`${env:VAR}` instead of `${VAR}`. The two configs are maintained separately and need not match
line for line, but the *server list* stays in step when one is added or removed.

Registered: `sonarqube`, `jira`, `atlassian-rovo-mcp`, `gitlab`, and three distinct Grafana
instances — `grafana` (the default non-prod instance, `$GRAFANA_URL`), `grafana-prep` (pre-prod),
and `grafana-prod` (production, read-only; the only one `app-bug-detection` queries).

Prefer a plain `npx`/`uvx` entry over a launcher script. The one remaining launcher
(`~/.local/share/dotfiles/scripts/jira-mcp.sh`) is shared by both assistants — edit it there,
never fork a per-agent copy. Cursor only injects the env vars listed in `mcp.json`, which is the
one case that still justifies a launcher.

A skill fronts the server it owns: callers go through the skill, never at the MCP tools directly.
Never duplicate or commit sensitive configuration into a project repository.

---

## Hooks

Git hooks are stowed from `stow/git/.githooks/` and enabled globally by `core.hooksPath`, so they
run in **every** repository on the machine — a new hook must be safe in a work repo, not just
this one. `prepare-commit-msg` expands `category-message` into the final subject and strips
tooling attribution.

Write them in POSIX `sh`: `shopt` and other bash-only builtins fail there, and a `.sh` extension
does not make a file bash. Keep them fast — a slow or noisy hook gets bypassed reflexively, which
is worse than no hook.

Claude Code's own hooks would live in `~/.claude/settings.json`, which is **deliberately not
tracked**: it holds machine- and repo-specific context that must not be published. Do not stow,
copy, or quote it here.

A hook whose registration cannot be tracked is a hook a new machine silently lacks, so prefer a
rule in the skill that owns the subject over a hook that must be re-added by hand per machine.
Cursor is the exception: `~/.cursor/hooks.json` holds no machine context, so a Cursor hook can be
stowed like any other config.
