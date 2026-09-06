---
description: "Fix production bugs found in Loki logs, on a dedicated branch with one local commit"
---

Fix the production bugs whose root cause is confirmed in this repository; report the rest.

The text after `/bug-fix` is optional and passes through to detection: `--since`, `--service`,
`--limit`, plus `--issue <n>` to fix only the nth issue of the report.

## Rules

- All log access goes through the `app-bug-detection` skill — load it first and never query the
  `grafana-prod` MCP server directly.
- This command carries the `git` rule's commit exception: its own `bugfix/*` branch, one
  local commit. Never push, never open a merge request, never touch existing history.
- Fix only what the report attributes to project code with the line confirmed locally. Environment
  issues, expected noise, and low-confidence findings are reported, not patched.
- Smallest change that removes the cause — no refactors, no drive-by cleanup, no new abstractions.
- Stop and ask when the working tree is dirty, the service match is ambiguous, the default branch
  is ambiguous, the report is empty, or the fix would change public API or behaviour beyond the
  bug.

## Steps

1. **Repo** — `git fetch --prune origin`. A dirty `git status --porcelain` is a stop condition.
2. **Base branch** — `git remote set-head origin --auto`, then
   `git symbolic-ref --short refs/remotes/origin/HEAD`. If unset, first existing of `develop`,
   `release`, newest `release/*`, `main`, `master`.
3. **Detect** — run the `app-bug-detection` skill with the given arguments and take its report.
   State the service name and window before editing anything.
4. **Triage** — keep the issues marked as application bugs with a verified suspect line, highest
   impact first; list what you are skipping and why.
5. **Branch** — `git switch -c bugfix/<service-slug>-$(date +%Y%m%d) origin/<base>`, before any
   edit. Slugify the service name — the pom description may contain spaces.
6. **Fix** — one issue at a time, following the project's architecture and conventions. Add or
   extend a test that fails on the bug first when the project's test setup allows it.
7. **Validate** — the project's own build and tests for the touched modules
   (`mvn -pl <mods> -am verify`, `./gradlew :<mod>:test`). Revert any fix that fails and skip that
   issue; never commit a red build.
8. **Commit** — one commit, subject `fix-…`; body lists each issue as exception, `file:line`, and
   what changed. No `--no-verify`, no attribution trailers.
9. **Report** — the detection scope line, issues fixed with their diffs summarised, issues skipped
   with reasons, build result, branch and commit SHA, and that nothing was pushed.
