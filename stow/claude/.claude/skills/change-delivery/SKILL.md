---
name: change-delivery
description: "Mechanics shared by every command that changes code on a dedicated branch: preconditions, base-branch resolution, the per-run worktree and its cleanup, build and test validation per build system, coverage expectation, commit and push rules, and the hand-back report. Load when running /deliver, /sonar-bot, /bugfix-bot, /renovate-bot, or any command that carries the git commit exception."
argument-hint: "the command carrying the commit exception"
---

# Change delivery

Each command keeps its own policy and branch name; mechanics are here. The bots (`/sonar-bot`,
`/bugfix-bot`, `/renovate-bot`) also read `references/bot-run.md`.

## 1. Preconditions (stop conditions)

Stop and ask; never work around one.

- The base branch cannot be resolved (below).
- The command's own input is empty: no report, no ticket, no target.

The user's checkout is never edited, and is switched only to hand a reused branch to its worktree
(§3).

## 2. Base branch

The base is the remote's default branch, as set on the host:

```
git fetch --prune origin
git remote set-head origin --auto
git symbolic-ref --short refs/remotes/origin/HEAD
```

If unset, take the first that exists: `develop`, `release`, the newest `release/*`, `main`,
`master`. State the resolved base before editing anything.

## 3. Worktree

Every run works in its own worktree on its own branch, created before the first edit, named by
the command. Parallel runs need it; the user's checkout stays untouched.

```
git worktree prune
wt="${XDG_STATE_HOME:-$HOME/.local/state}/worktrees/<repo>/<branch>"
git worktree add --no-track -b <branch> "$wt" origin/<base>
```

- Edit, build and commit only inside `$wt`. The path is outside `$REPOS_DIR` so repository
  scanners (jirlab) never list it.
- Every git write (`add`, `commit`, `push`, `rebase`, `branch -D`) names the literal worktree
  path — `git -C <path> …` — or runs with its cwd inside it. The `git-guard` hook blocks git
  writes anywhere else, and `--no-verify` or a plain `--force` push everywhere.
- It starts at `origin/<base>` as fetched in §2 — never the local base ref or the current
  branch. `--no-track` is required: a branch tracking the base makes `git pull` merge it and lets
  `git push` target it.
- Suffix `-2`, `-3` … when the branch name is taken. Never edit or commit on a protected branch
  — the base, `main`, `master`, `develop`, `release`, `release/*`.
- **Reuse.** When the command reuses the user's current branch, its tree must be clean
  (`git status --porcelain` empty; otherwise stop and ask). Switch the user's checkout to the
  base (`git switch <base>`), then `git worktree add "$wt" <branch>` and continue as above. The
  report says the checkout now sits on the base.

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

## 5. Commit and push

One commit per run unless the command says otherwise, body listing what changed and why, one line
per issue. Stage the paths you changed by name: `git add -A` sweeps in workspace artifacts that
must not ship.

Subject and trailers per the git contract (`CLAUDE.md` in Claude, the `git` rule in Cursor).
Push (`git -C <worktree> push origin <branch>`) and open a merge request only when the command says so (`--mr`,
or a bot).

## 6. Clean up

Last step of every run, also a failed or skipped one:

`git worktree remove "$wt"`, then `git worktree prune`. When it refuses over untracked files,
name them in the report, then `--force`. The local branch stays for review, pushed or not; only a
run that committed nothing deletes it, in the same command
(`git worktree remove "$wt" && git branch -D <branch>`). A run that dies before this is caught by
`wt-prune.sh` at the next session start.

## 7. Hand back

Report once, in this order: work skipped and why, the branch name and whether it is pushed, the
commit SHAs, the merge request URLs, the build command and
result, then any non-derivable exception. No narrative recap.

Last, any domain fact the run uncovered that the knowledge base in `doc-repos.md` lacks or
contradicts — a quirk, a decision, a source conflict — as a proposed line with its target page.
Propose only; never edit that repository from a delivery run.
