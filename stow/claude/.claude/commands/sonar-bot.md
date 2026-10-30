---
description: "Fix SonarQube issues in risk-graded groups, one merge request per group"
argument-hint: "[project key or name] [--severity ...] [--new-code] [--path <glob>] [--rule <key>]"
---

Fix SonarQube issues, one merge request per risk group. `$ARGUMENTS` is optional: a project key
or name, plus filters passed to collection.

Load `sonarqube-validation` (all Sonar access) and `change-delivery` with its
`references/bot-run.md`. This command carries the git commit exception: branches
`refactor/sonar-bot-<group>-<YYYYMMDD>`, pushed, with merge requests.

1. **Start** — `bot-run.md` §Start.
2. **Collect** — `sonarqube-validation` §2–4. State the project key and name.
3. **Group**:
   - **`local`** — behaviour-preserving, one file, one obvious solution: unused code, idiom swaps,
     missing `@Override`, naming, try-with-resources, private extraction. One commit.
   - **`structural`**, at most 10 — behaviour-preserving, but spans files, adds a type, changes a
     non-private signature, or has more than one reasonable design. One commit per issue; the merge
     request states the design chosen.
   - **`semantic`**, at most 3 — changes what the code observably does: exception handling, crypto
     and randomness, concurrency, public API contracts. One commit per issue.
   Dependency upgrades belong to `/renovate-bot`; security hotspots are reported, never fixed.
4. **Run** — `bot-run.md`. Subject `fix-…` for bugs and vulnerabilities, else
   `refactor-…`; body the rule and `file:line`.
