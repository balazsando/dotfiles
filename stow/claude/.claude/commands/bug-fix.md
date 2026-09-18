---
description: "Fix production bugs found in Loki logs, on a dedicated branch"
argument-hint: "[--since <duration>] [--service <name>] [--issue <n>] [--limit <n>]"
---

Fix the production bugs whose root cause is confirmed in this repository; report the rest.
`$ARGUMENTS` passes through to detection: `--since`, `--service`, `--limit`, plus `--issue <n>`
to fix only the nth issue of the report.

## Rules

- All log access goes through the `app-bug-detection` skill — load it first and never query the
  `grafana-prod` MCP server directly.
- Branch, validation, commit and report mechanics: the `change-delivery` skill. Load it, and the
  language skills the code needs (`java-standards`, then `clean-code`, for Java/Spring/Maven).
- This command carries the `~/.claude/CLAUDE.md` **Git operations** commit exception: its own
  `fix/*` branch. Never push, never open a merge request.
- Fix only what the report attributes to project code with the line confirmed locally.
  Environment issues, expected noise, and low-confidence findings are reported, not patched.
- Never weaken, skip or delete an existing test to make a fix pass.
- Stop and ask when the report is empty, the service match is ambiguous, or a fix would change
  public API or behaviour beyond the bug — plus the `change-delivery` §1 stop conditions.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2.
2. **Detect** — run `app-bug-detection` with `$ARGUMENTS`. State the service and window.
3. **Triage** — keep the application bugs with a verified suspect line, highest impact first.
   List what you are skipping and why.
4. **Branch** — `change-delivery` §3, prefix `fix/`, before the first edit.
5. **Fix, one issue at a time**:
   1. A regression test that fails for the reported defect. Skip only where the project has no
      test setup.
   2. The smallest fix that turns it green.
   3. `change-delivery` §4. Red → revert this issue's changes and report it as skipped.
   4. `change-delivery` §5, one commit per issue: subject `fix-…`, body the defect and
      `file:line`.
6. **Report** — `change-delivery` §6, plus non-derivable detection skips and exceptions.
