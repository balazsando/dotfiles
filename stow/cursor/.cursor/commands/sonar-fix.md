---
description: "Fix straightforward SonarQube issues on a dedicated branch with one local commit"
---

Fix the SonarQube findings that are mechanically safe; leave everything else in the report.

The text after `/sonar-fix` is optional: a SonarQube project key or name to skip project
matching, plus filters (`--severity`, `--new-code`, `--path`, `--rule`).

## Rules

- All SonarQube access goes through the `sonarqube-validation` skill — load it first and never
  call the `sonarqube` MCP server directly.
- This command carries the global-instructions rule's **Git operations** commit exception: its own
  `sonar-cleanup/*` branch, one local commit. Never push, never open a merge request, never touch
  existing history.
- Fix only behaviour-preserving changes provable by a compile plus the existing tests; every
  change maps to a real issue key from the collected report.
- Stop and ask when the working tree is dirty, the project match is ambiguous, the default branch
  is ambiguous, or the build cannot be validated locally.

## Steps

1. **Repo** — `git fetch --prune origin`. A dirty `git status --porcelain` is a stop condition.
2. **Base branch** — `git remote set-head origin --auto`, then
   `git symbolic-ref --short refs/remotes/origin/HEAD`. If unset, first existing of `develop`,
   `release`, newest `release/*`, `main`, `master`.
3. **Project** — match it with the validation skill (§2), passing any project argument through.
   State key and name before editing anything.
4. **Issues** — collect the report with the validation skill (§3): the base branch, 40 issues per
   run, honouring the filters. Apply its §4 interpretation — stale, generated, and suppressed
   hits are out.
5. **Branch** — `git switch -c sonar-cleanup/<project-key>-$(date +%Y%m%d) origin/<base>`,
   before any edit.
6. **Fix** — bugs → vulnerabilities → smells, highest severity first. Smallest edit per issue,
   project formatter, no new abstractions, no drive-by reformatting.
7. **Validate** — the project's own build and tests for the touched modules
   (`mvn -pl <mods> -am verify`, `./gradlew :<mod>:test`, `go test ./...`, `npm test`). Revert
   any fix that fails and skip that issue; never commit a red build.
8. **Commit** — one commit, subject `fix-…` (bugs, vulnerabilities), `refactor-…` (smells) or
   `style-…`; body lists rule and `file:line` per issue. No `--no-verify`, no attribution trailers.
9. **Report** — the validation skill's §5 report, plus base and new branch, commit SHA, fixed
   issues, skipped issues with reasons, build result, and that nothing was pushed.

## Fix / skip

**Fix:** unused imports, fields, params; unreachable or commented-out code; redundant
modifiers, casts, type arguments; `isEmpty()`, `Objects.equals`, `StandardCharsets`, diamond;
log placeholders instead of concatenation; missing `@Override` / `serialVersionUID`; `final`
where the compiler allows; missing braces; an early return replacing an `else`;
try-with-resources over an unconditional `finally` close; private or local naming; formatting
only on lines another fix already touches.

**Skip and report:** cognitive-complexity and method-length refactors, duplicated blocks,
security hotspots, crypto and randomness swaps, concurrency, exception-handling semantics,
public API or visibility changes, reflection/serialisation/DI-driven code, missing tests,
dependency upgrades, generated or vendored files, anything already suppressed via
`@SuppressWarnings` or `NOSONAR`, and anything the local file no longer matches.

Nullability, `StringBuilder`, and deprecated-API findings qualify only when the whole change
fits in one method as an obvious 1:1 replacement.
