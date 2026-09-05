---
name: code-review-practices
description: "Code review skill based on Google Engineering Practices. Use when reviewing a pull request, merge request, or diff; checking code quality, correctness, tests, naming, comments, style, security, or design; writing review feedback or comments; auditing code health. Covers the full reviewer workflow: navigate → inspect → comment."
argument-hint: "file path, diff, or PR description to review"
---

# Code Review

## Standard

> Approve a CL once it **definitely improves overall code health**, even if imperfect. Seek continuous improvement, not perfection. Never approve a CL that degrades code health.

- Technical facts override opinions and preferences.
- Style guide is the absolute authority on style. Personal preferences that aren't in the guide → prefix with `Nit:`.
- Design decisions are based on engineering principles, not personal taste.

## Step 1 — Take a Broad View

1. Read the description / PR summary. Does this change make sense? Is the scope appropriate?
2. If the change shouldn't happen at all (wrong direction, deprecated system, out of scope), say so immediately and suggest an alternative — courteously.
3. If the CL is too large to reason about, ask the author to split it.

## Step 2 — Examine the Main Part First

1. Identify the file(s) with the most logical changes — that's the core.
2. Review core design before everything else.
3. If there are **major design problems**, report them immediately — don't finish reviewing the rest first.
   - Reason: author may have already started follow-up work based on the same design.

## Step 3 — Review the Remainder

Go through remaining files in a logical sequence (tests → implementation → config is a common order). See [checklist](./references/checklist.md) for what to verify in each file.

## Comment Severity Labels

Always label the severity so the author can prioritize:

| Label | Meaning |
|-------|---------|
| `MUST:` | Blocking — must be resolved before approval |
| `Nit:` | Minor polish, technically correct but not critical |
| `Optional:` / `Consider:` | Good idea but not required in this CL |
| `FYI:` | Informational — no action expected now |

## Comment Writing Rules

- Comment on the **code**, never on the developer.
- Always explain **why**, not just what is wrong.
- Balance pointing out problems vs. giving direct guidance — let the developer decide when possible.
- If code is hard to understand: ask for clarification *and* encourage a rewrite, not just an explanation in the review tool.
- Acknowledge good things — reinforce positive practices explicitly.

## Approval Checklist (Quick)

See [full checklist](./references/checklist.md) for details.

- [ ] Design makes sense and fits the system
- [ ] Functionality is correct for users (end-users and future developers)
- [ ] No unnecessary complexity or over-engineering
- [ ] Adequate and well-designed tests
- [ ] Clear, unambiguous names
- [ ] Comments explain *why*, not *what*; no stale TODOs
- [ ] Relevant documentation updated
- [ ] Style guide followed
- [ ] Security: no OWASP Top 10 issues (injection, broken auth, sensitive data exposure, etc.)
- [ ] Concurrency is safe (no races, deadlocks)
- [ ] UI changes look sensible (if applicable)
