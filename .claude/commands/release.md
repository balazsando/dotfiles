---
description: "Prepare the next version — changelog entry, VERSION, README badge, guards"
argument-hint: "[major|minor|patch|<x.y.z>]"
---

Prepare a release of this repository. `$ARGUMENTS` is the bump level or an explicit version;
if empty, propose one from the actual changes and ask.

Prepares files only. Committing, tagging, and pushing stay with the user — the **Git
operations** rules in `~/.claude/CLAUDE.md` are not suspended for this command.

## Steps

1. **Scope** — `git describe --tags --abbrev=0` for the last tag, then
   `git log --oneline <tag>..HEAD` and `git status --porcelain`. Both committed and uncommitted
   work count. Read the actual diffs; never write an entry from a commit subject alone.
2. **Version** — current in `VERSION`. Apply `$ARGUMENTS`, or propose: breaking change to the
   bootstrap flow or package layout → major; new package, skill, command, or capability → minor;
   fixes and documentation only → patch. State the reasoning in one line.
3. **Drift check** — before writing anything, confirm `README.md` and `docs/ARCHITECTURE.md`
   still describe the repository as it now is: the layout blocks, the package list, and the
   bootstrap steps. They have contradicted each other before. Fix what is stale, and say so.
4. **Changelog** — a new `## [x.y.z] — YYYY-MM-DD` section above the previous one, grouped
   `Added` / `Changed` / `Fixed` / `Security` / `Documentation` (omit empty groups). One line
   under the heading saying what the release is for.
5. **Bump** — `VERSION`, and the README badge `version-<x.y.z>-blue`. Both, together.
6. **Verify** — `bash check-ai-parity.sh`, `bash stow.sh -n`, and a syntax check on every shell
   file touched (`sh -n` or `bash -n`, matching the shebang).
7. **Hand over** — print the commands for the user to run, and stop:

   ```
   git add -A && git commit -m "version-<x.y.z>"
   git tag -a v<x.y.z> -m "<x.y.z>"
   git push origin <branch> && git push origin v<x.y.z>
   ```

## Rules

- Every entry traces to a real change in the diff. Never pad a section, never carry an entry
  over from a previous release, never describe intent that was not implemented.
- Write for someone reading the repository in a year: what changed and why it mattered, not the
  file list. Skip pure churn.
- The project `CLAUDE.md` no-leak rules apply to the changelog and the tag message.
- No tooling attribution anywhere, per `~/.claude/CLAUDE.md`.
- Stop and ask if the last tag is missing, `VERSION` disagrees with the badge or the newest
  changelog heading, or the working tree holds unrelated work that should not ship.
