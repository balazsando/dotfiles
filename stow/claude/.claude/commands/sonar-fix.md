---
description: "Fix straightforward SonarQube issues on a dedicated branch with one local commit"
argument-hint: "[project key or name] [--severity ...] [--new-code] [--path <glob>]"
---

Fix the SonarQube findings that are mechanically safe; leave everything else in the report.

`$ARGUMENTS` is optional: a SonarQube project key or name to skip project matching, plus filters
(`--severity`, `--new-code`, `--path`, `--rule`).

## Rules

- All SonarQube access goes through the `sonarqube-validation` skill — load it first and never
  call the `sonarqube` MCP server directly.
- Branch, validation, commit and report mechanics: the `change-delivery` skill. Load it.
- This command carries the `~/.claude/CLAUDE.md` **Git operations** commit exception: its own
  `refactor/*` branch, one local commit. Never push, never open a merge request.
- Fix only behaviour-preserving changes provable by a compile plus the existing tests; every
  change maps to a real issue key from the collected report.
- The fixes below are mechanical and single-file, so this command edits directly rather than
  spawning a developer: anything needing judgement is on the skip list. Never widen that list.
- Stop and ask when the project match is ambiguous or the build cannot be validated locally —
  plus the `change-delivery` §1 stop conditions.

## Steps

1. **Preconditions and base branch** — `change-delivery` §1–2.
2. **Project** — match it with the validation skill (§2), passing any project argument through.
   State key and name before editing anything.
3. **Issues** — collect the report with the validation skill (§3): the base branch, 40 issues per
   run, honouring the filters. Apply its §4 interpretation — stale, generated, and suppressed
   hits are out.
4. **Branch** — `change-delivery` §3, prefix `refactor/`, before any edit.
5. **Fix** — bugs → vulnerabilities → smells, highest severity first. Smallest edit per issue,
   project formatter, no new abstractions, no drive-by reformatting.
6. **Validate** — `change-delivery` §4. Revert any fix that fails and skip that issue.
7. **Commit** — `change-delivery` §5, subject `fix-…` (bugs, vulnerabilities), `refactor-…`
   (smells) or `style-…`; body lists rule and `file:line` per issue.
8. **Report** — `change-delivery` §6, plus the validation skill's §5 report.

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
