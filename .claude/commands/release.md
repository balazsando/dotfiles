---
description: "Audit, then prepare the next version — changelog entry, VERSION, README badge, guards"
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
3. **Audit** — before writing anything, audit the release scope and every file it touches. Run
   `bash check-ai-parity.sh`, `bash stow.sh -n`, and a syntax check on each shell file in scope
   (`sh -n` or `bash -n`, matching the shebang). Then read for:
   - **Sensitive** — anything the project `CLAUDE.md` forbids in a tracked file: credentials,
     internal hostnames, IPs, cluster or namespace names, registry and service endpoints,
     company, product, board, ticket-key, repository path, colleague name or email. Cover the
     diff, the files about to be written, and the changelog text about to be written.
   - **Blocker** — the release could not be installed: a verification command fails, a bootstrap
     or stow step that cannot succeed on a clean machine, a package pointing at a file that is
     not there.
   - **Critical** — it installs but is wrong: a documented command, path, flag, or guard that no
     longer matches what the repository actually does.
   - **Inconsistency** — two tracked sources contradicting each other: `README.md` against
     `docs/ARCHITECTURE.md` (layout blocks, package list, bootstrap steps), `VERSION` against
     the README badge and the newest changelog heading, a command against the skill it loads,
     a Claude file against its Cursor twin.
4. **Push back or proceed** — any Blocker, Critical, or Sensitive finding stops the release:
   report each as `severity — path:line — what is wrong — the smallest fix`, write nothing, and
   hand the decision back. Documentation that is unambiguously stale, fix in place and say so;
   an inconsistency that needs a decision is pushed back like the rest. Only a clean audit
   continues to step 5.
5. **Changelog** — a new `## [x.y.z] — YYYY-MM-DD` section above the previous one, grouped
   `Added` / `Changed` / `Fixed` / `Security` / `Documentation` (omit empty groups). One line
   under the heading saying what the release is for.
6. **Bump** — `VERSION`, and the README badge `version-<x.y.z>-blue`. Both, together.
7. **Verify** — re-run the step 3 commands after the edits.
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
- No tooling attribution anywhere, per `~/.claude/CLAUDE.md`.
- Stop and ask if the last tag is missing, or the working tree holds unrelated work that should
  not ship.
