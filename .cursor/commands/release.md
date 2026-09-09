---
description: "Audit, then prepare the next version — changelog entry, VERSION, README badge, guards"
---

Prepare a release of this repository. The text after `/release` is the bump level or an
explicit version; if empty, propose one from the actual changes and ask.

Prepares files only. Committing, tagging, and pushing stay with the user — the
`git` rule's **Git operations** prohibitions are not suspended for this command.

## Steps

1. **Scope** — `git describe --tags --abbrev=0` for the last tag, then
   `git log --oneline <tag>..HEAD` and `git status --porcelain`. Both committed and uncommitted
   work count. Read the actual diffs; never write an entry from a commit subject alone.
2. **Version** — current in `VERSION`. Apply the argument, or propose: breaking change to the
   bootstrap flow or package layout → major; new package, skill, command, or capability → minor;
   fixes and documentation only → patch. State the reasoning in one line.
3. **Audit** — before writing anything, run `/review-staged` over the release scope
   (`<tag>..HEAD` plus the working tree) and cover the changelog text about to be written with
   it. It owns the checks and the finding categories; do not restate them here.
4. **Push back or proceed** — any Sensitive, Blocker, or Critical finding stops the release:
   report the audit output, write nothing, and hand the decision back. Documentation that is
   unambiguously stale, fix in place and say so; an inconsistency that needs a decision is
   pushed back like the rest. Only a clean audit continues to step 5.
5. **Changelog** — a new `## [x.y.z] — YYYY-MM-DD` section above the previous one, grouped
   `Added` / `Changed` / `Fixed` / `Security` / `Documentation` (omit empty groups). One line
   under the heading saying what the release is for.
6. **Bump** — `VERSION`, and the README badge `version-<x.y.z>-blue`. Both, together.
7. **Verify** — re-run the step 3 audit after the edits.
8. **Hand over** — print the commands for the user to run, and stop:

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
- Never downgrade a finding, and never write one into the changelog as though it were an
  intended change, to keep the release moving. Whether to release anyway is the user's call; a
  re-run of `/release` starts from a fresh audit.
- The project `CLAUDE.md` no-leak rules apply to the changelog, the tag message, and the audit
  report itself — name the variable or the file, never print the value.
- No tooling attribution anywhere, per the `git` rule.
- Stop and ask if the last tag is missing, or the working tree holds unrelated work that should
  not ship.
