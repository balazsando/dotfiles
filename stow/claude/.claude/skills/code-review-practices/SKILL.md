---
name: code-review-practices
description: "Reviewing a pull request, merge request, or diff: correctness, tests, naming, style, security, design, and code health, and how to label and report the findings."
argument-hint: "file path, diff, or PR description to review"
---

# Code Review

Approve a change once it **definitely improves overall code health**, even if imperfect; never
one that degrades it. Technical facts and the style guide beat opinion — a preference the guide
does not state is a `Nit:`, never blocking. Judge the change that is there, not the one you
would have written.

Review the core design first. A change that should not happen at all, or a major design problem,
is reported before the rest of the files.

What to check: [references/checklist.md](references/checklist.md). A review handed back as one
document (`/mr-review`): [references/report-format.md](references/report-format.md).

Label every inline comment: `MUST:` blocking, `Nit:` minor polish, `Consider:` optional,
`FYI:` informational. Say why, not just what.
