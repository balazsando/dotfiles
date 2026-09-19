---
name: change-delivery
description: "Mechanics shared by every command that changes code on a dedicated branch: preconditions, base-branch resolution, branch naming, build and test validation per build system, coverage expectation, commit rules, and the hand-back report. Load when running /deliver, /bug-fix, /sonar-fix, or any command that carries the git commit exception."
argument-hint: "the command carrying the commit exception, and its branch prefix"
---

# Change delivery

Each command keeps its own policy; mechanics are here.

## 1. Preconditions (stop conditions)

Stop and ask; never work around one.

- `git status --porcelain` is non-empty — a dirty tree.
- The default branch cannot be resolved (below).
- The command's own input is empty: no report, no ticket, no target.

## 2. Base branch

```
git fetch --prune origin
git remote set-head origin --auto
git symbolic-ref --short refs/remotes/origin/HEAD
```

If unset, take the first that exists: `develop`, `release`, the newest `release/*`, `main`,
`master`. State the resolved base before editing anything.

## 3. Branch

Never edit or commit on a protected branch — the resolved base, `main`, `master`, `develop`,
`release`, `release/*`. Every run works on its own branch, created before the first edit.
Reuse the current branch instead only when it is not protected and its name carries the run's
ticket key or matches its subject; say so.

```
git switch -c <prefix>/<slug> --no-track origin/<base>
```

It starts at `origin/<base>` as fetched in §2, so it is already current — never branch from the
local base ref or from the current branch. `--no-track` is required: a branch that tracks the
base makes a bare `git pull` merge it and lets `git push` target it. Suffix `-2`, `-3` … when the
name is taken.

Prefix is `feature/`, `fix/` or `refactor/` — nothing else: `fix/` (`/bug-fix`), `refactor/`
(`/sonar-fix`), whichever fits the change (`/deliver`). Start the slug with the ticket key when
one is known (`feature/ABC-123-add-widget`) — the `prepare-commit-msg` hook only matches
`[A-Z][A-Z0-9]+-[0-9]+` in the branch name. Slugify names containing spaces.

## 4. Validate

Build the modules you touched. **Compile** — production and test sources compile; use it to see
a new test fail for the right reason. **Green** — the suite passes.

| Build | Compile | Green |
| --- | --- | --- |
| Maven | `mvn -pl <modules> -am test-compile` | `mvn -pl <modules> -am verify` |
| Gradle | `./gradlew :<module>:compileTestJava` | `./gradlew :<module>:test` |
| Go | `go test -run '^$' ./...` | `go test ./...` |
| Node | the project's typecheck / test compile | `npm test` |

- Formatting is part of the build, not a separate pass: run the project's formatter
  (`spotless:apply`, `gofmt`, `prettier`) **only** when the build requires it, and never as a
  change of its own.
- Coverage ≥ 80 % on new or changed code where the project measures it, and only on a green bar.
  Below that, say the number and why it is justified — never pad with assertion-free tests.
- Never commit unless the suite is green. Report the work as skipped.

## 5. Commit

One commit per run unless the command says otherwise, body listing what changed and why, one line
per issue. Stage the paths you changed by name: `git add -A` sweeps in workspace artifacts that
must not ship.

Subject and trailers per the git contract in `~/.claude/CLAUDE.md`. Never push and never open a
merge request unless the invoking command says so explicitly.

## 6. Hand back

Git status/diff and the last validation command are authoritative for files and the build
result. Report once, in this order, only what those do not already show: work skipped and why,
the run's branch and whether it was created or reused, the commit SHAs, whether anything was
pushed, then any non-derivable exception. No narrative recap.
