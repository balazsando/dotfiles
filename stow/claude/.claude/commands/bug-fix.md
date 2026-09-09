---
description: "Fix production bugs found in Loki logs, on a dedicated branch with one local commit"
argument-hint: "[--since <duration>] [--service <name>] [--issue <n>] [--limit <n>]"
---

Fix the production bugs whose root cause is confirmed in this repository; report the rest.
`$ARGUMENTS` passes through to detection: `--since`, `--service`, `--limit`, plus `--issue <n>`
to fix only the nth issue of the report.

You triage and own git. The fixing and the tests belong to agents.

## Rules

- All log access goes through the `app-bug-detection` skill — load it first and never query the
  `grafana-prod` MCP server directly.
- Branch, validation, commit and report mechanics: the `change-delivery` skill. Load it.
- This command carries the `~/.claude/CLAUDE.md` **Git operations** commit exception: its own
  `bugfix/*` branch, one local commit. Never push, never open a merge request.
- Fix only what the report attributes to project code with the line confirmed locally.
  Environment issues, expected noise, and low-confidence findings are reported, not patched.
- Stop and ask when the report is empty, the service match is ambiguous, or a fix would change
  public API or behaviour beyond the bug — plus the `change-delivery` §1 stop conditions.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2.
2. **Detect** — run `app-bug-detection` with `$ARGUMENTS`. State the service and window.
3. **Triage** — keep the application bugs with a verified suspect line, highest impact first.
   List what you are skipping and why. This ranking is yours; the agents do not re-triage.
4. **Branch** — `change-delivery` §3, prefix `bugfix/`, before the first edit.
5. **Fix** — one issue at a time. Spawn `developer-agent` with the defect, its `file:line`, and
   the evidence from the report — not the whole report. Smallest change that removes the cause.
6. **Regression test** — spawn `test-engineer-agent` with the defect and the developer's notes,
   to add the test that fails on the bug. Skip only where the project has no test setup for it.
7. **Validate** — `change-delivery` §4. Revert and skip any fix that fails; never commit red.
8. **Commit** — `change-delivery` §5, subject `fix-…`, body listing each issue as exception,
   `file:line`, and what changed.
9. **Report** — `change-delivery` §6, plus the detection scope line.
