---
description: "Audit the Java checkouts as one system — version drift, removable dependencies, structure — plan cross-repo refactors in build order, then commit the approved ones locally"
argument-hint: "[--regression] [refactor goal]"
---

Audit the Java rows of `~/.claude/local/work-repos.md` as one system; missing file → ask. With a
refactor goal in `$ARGUMENTS`, also plan it across them.

Steps 1–7 are read-only. After the user approves the plan, steps 8–9 carry the git commit
exception: local commits only, never pushed.

Load `java-standards` and `hexagonal-architecture`, and `change-delivery` for step 8. Run
every read-only command in parallel across checkouts.

## Steps

1. **Inventory** — per checkout: coordinates, parent, imported BOMs, Java and plugin versions,
   each declared dependency with its effective version (`mvn -q help:effective-pom`), and which
   artifacts it publishes. `git fetch` first; a checkout that is dirty, off its default branch, or
   behind it is audited as it stands and flagged.
2. **Chain** — the graph of internal artifacts: who publishes, who consumes, at which version.
   Topological order; flag cycles and consumers pinned behind the latest published version.
3. **Versions** — a matrix of every third-party artifact and plugin declared in more than one
   checkout. Each drift gets one target: the newest stable release (per `/renovate-bot` Collect)
   when every consumer can take it without a migration, otherwise the highest already in use.
   Name the single place that should own it — an existing shared parent or BOM in the table, or
   propose one.
4. **Removable** — per checkout, each candidate with its evidence:
   - declared but unused — `mvn -q dependency:analyze`, then grep for reflection, starters,
     annotation processors, runtime and test-runtime use before calling it removable;
   - a version restated where the parent or a BOM already manages it;
   - declared twice, or already arriving transitively at the same version and scope;
   - excluded and re-added, or overridden to an older version than the managed one.
5. **Structure** — parent and BOM hierarchy, module boundaries, code duplicated across
   checkouts, shared modules that only one consumer uses, and layering against
   `hexagonal-architecture`. Each proposal names what moves where and what it unblocks; none
   without a concrete gain.
6. **Pipeline versions** — read each checkout's `.gitlab-ci.yml` and the templates it includes
   from the `ci-templates` row to learn how a version is derived (pom, tag, pipeline counter,
   release job). From the current pom version and latest tag, predict the version each pipeline
   publishes on its next merge to the default branch. A rule the files do not show is
   **unknown**, never guessed.
7. **Plan** — with a refactor goal, or for the proposals the user picks: the chain from step 2
   cut to the affected repositories, one row per merge request in build order — repository,
   change, artifact version it consumes (predicted in step 6), version it will publish, and what
   waits on it. Repositories with no edge between them share a wave and can merge in parallel.
8. **Execute** — only after the user approves the plan or picks rows from it; nothing approved →
   stop at the report. Wave by wave, per repository, in the checkout itself (no worktrees):
   - **Baseline** — on the default branch, every deployable whose runtime classpath the row
     changes saves its quick-regression baseline: `QUICK_SAVE=<base> bin/regress quick <app>`,
     with the harness in `~/.claude/local/work-repos.md`.
   - **Branch** — `change-delivery` §1–5 on `refactor/housekeep-<slug>-<YYYYMMDD>`, one slug
     for the whole run. An existing branch is checked out and rebased onto `origin/<base>`; a
     conflict aborts the rebase and skips that repository. One commit per concern —
     `chore-unify dependency versions`, `chore-remove unused dependencies`, `refactor-…` per
     structural change — each green.
   - **Versions** — an upstream installs its branch under a unique version no pipeline publishes:
     its current version, as the branch states it, with `-housekeep-<slug>` before any
     `-SNAPSHOT` (`mvn -q install -DskipTests -Drevision=<unique>`), so it never shadows a Nexus
     artifact. Consumers build against it from the command line (`-D<version property>=<unique>`);
     only a literal pin is edited, and left unstaged. Never bump `.mvn/maven.config` or a version
     property to a predicted version, and never re-derive the unique version after a rebase moves
     the predictions: step 7's predicted versions are for the merges and live in the plan table
     only.
   - **Quick regression** — after the last commit, on the branch:
     `QUICK_AGAINST=<base> bin/regress quick <app>`. It replays every recorded exchange against
     stubbed BUs and compares responses and the requests sent to the BUs; no BU is called.

   A failed precondition, red build or quick-regression difference skips that repository and
   everything that waits on it; say which. Every checkout ends on its default branch.
9. **Regression** — only when `$ARGUMENTS` contains `--regression`; otherwise
   skipped, and the report marks every row `regression not run`. Every deployable whose runtime
   classpath changed in step 8 runs `bin/regress all`, per the README of the harness in
   `~/.claude/local/work-repos.md`: baseline the default branch, branch side the step 8 branch
   checked out again, upstreams installed under their unique versions. It replays the committed
   recordings; never refresh them (`postman/pm run`, `regress capture`) — that calls the BUs.
   A difference blocks the repository until it is explained or fixed; a fix is a new commit on
   the same branch, followed by a fresh run. Libraries count through the deployables that
   consume them; a deployable without a harness configuration is reported as untested.

   Docker is a precondition of the quick and the full regression: when `docker info` fails, stop
   and ask the user to start Docker — never skip the run or substitute a weaker check.

## Report

Steps 1–7: sections in step order, most impact first within each, every finding with file and
line. End with the plan table, or with the top proposals to choose from when no goal was given,
then wait for approval.

Steps 8–9: `change-delivery` §6 per repository, then the plan table with each row's branch,
commit SHAs, quick and full regression results (pass, the differences, untested, or not run),
and done or skipped. Nothing is pushed; merge requests are the user's call after review.
