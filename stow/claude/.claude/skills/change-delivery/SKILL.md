---
name: change-delivery
description: "Mechanics shared by every command that changes code on a dedicated branch: preconditions, base-branch resolution, branch naming, build and test validation per build system, coverage expectation, the single-commit rule, and the hand-back report. Load when running /ticket-to-merge, /bug-fix, /sonar-fix, or any command that carries the git commit exception."
argument-hint: "the command carrying the commit exception, and its branch prefix"
---

# Change delivery

The half that `/ticket-to-merge`, `/bug-fix` and `/sonar-fix` used to restate. Each command
keeps its own policy — what to fix, which roles to invoke — and takes the mechanics from here.

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

`git switch -c <prefix>/<slug>-$(date +%Y%m%d) --no-track origin/<base>` — before the first
edit, never after. `--no-track` is required: a branch that tracks the base makes a bare
`git pull` merge it and lets `git push` target it.

Prefixes: `bugfix/` (`/bug-fix`), `sonar-cleanup/` (`/sonar-fix`), the ticket key lowercased
(`/ticket-to-merge`). Slugify names containing spaces.

## 4. Validate

Run the project's own build for the touched modules only:

| Build | Command |
| --- | --- |
| Maven | `mvn -pl <modules> -am verify` |
| Gradle | `./gradlew :<module>:test` |
| Go | `go test ./...` |
| Node | `npm test` |

- Formatting is part of the build, not a separate pass: run the project's formatter
  (`spotless:apply`, `gofmt`, `prettier`) **only** when the build requires it, and never as a
  change of its own.
- Coverage ≥ 80 % on new or changed code where the project measures it. Below that, say the
  number and why it is justified — never pad with assertion-free tests.
- A change whose validation fails is reverted and reported as skipped. Never commit a red build.

## 5. Commit

One commit. Subject `category-message` per the **Commit message format** in
`~/.claude/CLAUDE.md`; the body lists what changed and why, one line per issue or criterion.

Never `--no-verify`. No attribution trailers. Never touch existing history. Never push and never
open a merge request unless the invoking command says so explicitly.

## 6. Hand back

Report, in this order: the scope line (what was in, what was out), work done with `file:line`,
work skipped with the reason, the validation result, base branch, new branch, commit SHA, and
whether anything was pushed. Those facts once each, per `economy-of-words` — no narrative
recap of the run.
