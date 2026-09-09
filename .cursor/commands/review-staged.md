---
description: "Audit changes against the release bar — findings by severity, nothing written"
---

Audit what is about to enter this repository and report the findings, or that it is clean. This
is the evaluation `/release` runs before it writes anything, without the release.

The text after `/review-staged` sets the scope: paths narrow it to those files, a rev range
(`<tag>..HEAD`) audits that range plus the working tree, empty audits the staged set.

Reports only. Nothing is written or fixed, and staging, unstaging and committing stay with
the user — the `git` rule's **Git operations** prohibitions are not suspended here.

## Steps

1. **Scope** — `git diff --cached --stat`, then `git diff --cached` for the content; for a rev
   range, `git log --oneline <range>`, `git diff <range>` and `git status --porcelain` for the
   uncommitted work. Nothing in scope → say so and stop. Read the diffs; never judge a file from
   its path or a commit subject alone.
2. **Check** — `bash check-ai-parity.sh`; `bash -n` or `sh -n` (matching the shebang) on every
   shell file in scope; `bash stow.sh -n` if anything under `stow/` or `.stowrc` is in scope.
3. **Read for findings**:
   - **Sensitive** — anything the project `CLAUDE.md` forbids in a tracked file: credential,
     internal hostname, IP, cluster or namespace name, registry or service endpoint, company,
     product, board, ticket key, repository path, colleague name or email. Cover the diff and any
     text about to be written from it. Name the file and the kind; never print the value.
   - **Blocker** — it could not be installed: a step 2 check fails, a bootstrap or stow step that
     cannot succeed on a clean machine, a package pointing at a file that is not there, a script
     that is not re-runnable.
   - **Critical** — it installs but is wrong: a documented command, path, flag, or guard that no
     longer matches what the repository actually does.
   - **Inconsistency** — two tracked sources contradicting each other: `README.md` against
     `docs/ARCHITECTURE.md` (layout blocks, package list, bootstrap steps), `VERSION` against the
     README badge and the newest changelog heading, a command against the skill it loads, a Claude
     file against its Cursor twin, a package-list or bootstrap change whose `README.md` and
     `docs/ARCHITECTURE.md` lines were left behind.
   - **Not shippable** — a generated or machine-local artifact (`repos.txt`, `.claude/state/`,
     graph output), a secrets file, an editor or OS leftover.
   - **Unrelated** — belongs to a different commit than the rest of the set, or pure churn mixed
     into a behaviour change. Staged scope only; not a finding for a rev range.
4. **Report** — the findings and nothing else, worst severity first:

   ```
   <severity> — <path>:<line> — <what is wrong> — <smallest fix>
   ```

   Then one closing line: `clean` when there is none, otherwise `unstage first` followed by
   `git restore --staged <paths>` for the files that should not go in as they are.

## Rules

- No preamble, no diff recap, no summary paragraph, no line for a file that is fine.
- Never downgrade or soften a finding to keep a commit moving; a Sensitive one is never a note.
- Depth beyond the audit is not this command's job — `/mr-review` does the full review, and
  `~/.claude/skills/code-review-practices/SKILL.md` is the standard it applies.
- Never run `git add`, `git restore --staged`, or `git commit`; print the command instead.
- Ask rather than guess when a file is plausibly deliberate but looks unrelated — the user may
  be splitting work across commits.
