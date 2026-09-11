---
description: "Fix production bugs found in Loki logs, on a dedicated branch"
argument-hint: "[--since <duration>] [--service <name>] [--issue <n>] [--limit <n>]"
---

Fix the production bugs whose root cause is confirmed in this repository; report the rest.
`$ARGUMENTS` passes through to detection: `--since`, `--service`, `--limit`, plus `--issue <n>`
to fix only the nth issue of the report.

You triage and orchestrate. The fixing, the builds and the commits belong to agents —
`~/.claude/skills/agent-workflow/SKILL.md` carries the report directory, question routing and
status rules.

## Rules

- All log access goes through the `app-bug-detection` skill — load it first and never query the
  `grafana-prod` MCP server directly.
- Branch and report mechanics: the `change-delivery` skill. Load it.
- This command carries the `~/.claude/CLAUDE.md` **Git operations** commit exception for the
  agents it spawns: its own `fix/*` branch. Never push, never open a merge request.
- Fix only what the report attributes to project code with the line confirmed locally.
  Environment issues, expected noise, and low-confidence findings are reported, not patched.
- Stop and ask when the report is empty, the service match is ambiguous, or a fix would change
  public API or behaviour beyond the bug — plus the `change-delivery` §1 stop conditions.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2. Create `$REPORTS` and write
   `prompt.md`.
2. **Detect** — run `app-bug-detection` with `$ARGUMENTS`. State the service and window.
3. **Triage** — keep the application bugs with a verified suspect line, highest impact first.
   List what you are skipping and why. This ranking is yours; the agents do not re-triage.
4. **Branch** — `change-delivery` §3, prefix `fix/`, before the first edit.
5. **Fix** — one issue at a time. Spawn `developer-agent` with the defect and its `file:line` —
   not the whole report. It builds and commits its own fix; a `FAILED` return leaves no commit
   and the issue is reported as skipped.
6. **Regression test** — spawn `test-engineer-agent` with the defect and the developer's commit.
   It builds green and commits its own tests. Skip only where the project has no test setup.
7. **Report** — `change-delivery` §6, plus non-derivable detection skips and exceptions.
