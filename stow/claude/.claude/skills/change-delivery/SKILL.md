---
name: change-delivery
description: "Mechanics shared by every command that changes code on a dedicated branch: preconditions, base-branch resolution, branch naming, build and test validation per build system, coverage expectation, commit rules, and the hand-back report. Load when running /deliver, /ticket-to-merge, /bug-fix, /sonar-fix, or any command that carries the git commit exception."
argument-hint: "the command carrying the commit exception, and its branch prefix"
---

# Change delivery

Mechanics for every command that changes code on its own branch. Each command keeps its own
policy — what to fix, which roles to invoke — and takes the rest from here.

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

Never edit or commit on a protected branch — the resolved base, and `main`, `master`,
`develop`, `release`, `release/*`. Standing on one of those, branch before the first edit.
Standing anywhere else, that branch is the run's branch: stay on it and say so, unless the run
has a ticket key its name does not carry.

```
git switch -c <prefix>/<slug> --no-track origin/<base>
```

It starts at `origin/<base>` as fetched in §2, so it is already current — never branch from the
local base ref or from the current branch. `--no-track` is required: a branch that tracks the
base makes a bare `git pull` merge it and lets `git push` target it. Suffix `-2`, `-3` … when the
name is taken.

Prefix is `feature/`, `fix/` or `refactor/` — nothing else: `fix/` (`/bug-fix`), `refactor/`
(`/sonar-fix`), whichever fits the change (`/deliver`, `/ticket-to-merge`). Start the slug with
the ticket key when one is known (`feature/ABC-123-add-widget`) — the `prepare-commit-msg` hook
only matches `[A-Z][A-Z0-9]+-[0-9]+` in the branch name. Slugify names containing spaces.

## 4. Validate

Whoever edits, builds: each agent for the modules it touched, a command that edits directly for
its own changes. A command that only spawns agents never runs a build.

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
- Never commit a red build: work that does not reach its bar is reported as skipped instead.

## 5. Commit

One commit per agent, or one commit for a command that edits directly instead of spawning one —
body listing what changed and why, one line per issue. Stage the paths you changed by name:
`git add -A` sweeps in workspace artifacts that must not ship.

Subject `category-message` per the **Commit message format** in `~/.claude/CLAUDE.md`. Never
`--no-verify`. No attribution trailers. Never touch existing history. Never push and never
open a merge request unless the invoking command says so explicitly.

## 6. Hand back

Git status/diff and the last validation command are authoritative for files and the build
result. Report once, in this order, only what those do not already show: work skipped and why,
the run's branch and whether it was created or reused, commit SHA, whether anything was pushed,
then any non-derivable exception. No narrative recap.
