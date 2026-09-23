---
description: "Fix production bugs from Loki logs in two groups, one merge request per group"
argument-hint: "[--since <duration>] [--service <name>] [--limit <n>]"
---

Fix production bugs, one merge request per group. `$ARGUMENTS` passes through to detection.

Load `app-bug-detection` (all log access) and `change-delivery` with its `references/bot-run.md`.
This command carries the git commit exception: branches `fix/bugfix-bot-<group>-<YYYYMMDD>`,
pushed, with merge requests.

1. **Start** — `bot-run.md` §Start.
2. **Collect** — `app-bug-detection` with `$ARGUMENTS`. Keep application bugs whose suspect line
   is verified locally; report the rest.
3. **Group**:
   - **`local`**, at most 10 — a local fix with one obvious solution. One commit.
   - **`structural`**, at most 3 — spans files, changes a signature, or needs a design choice. One
     commit per bug.
4. **Run** — `bot-run.md`. Each fix starts with a regression test that fails for the defect.
   Subject `fix-…`; body the defect and `file:line`.
