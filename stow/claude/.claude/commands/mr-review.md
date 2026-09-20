---
description: "Review a merge request or branch against its acceptance criteria, with severity-ranked findings"
argument-hint: "<MR-URL | MR-ID | branch> [--ticket <KEY>] [--sonar]"
---

Review the target in `$ARGUMENTS`; ask for one if it is missing. Review only: no edits, no
commits, and nothing posted to the merge request unless asked.

Load `code-review-practices` and its `references/report-format.md`, which owns the report and the
severity rules. Also `java-standards` `references/tests.md` when the diff touches Java tests, and
`sonarqube-validation` only with `--sonar`.

## Steps

1. **Target** — a merge request URL or id (GitLab MCP, or `glab`) or a branch, resolved to a base
   and head commit. State the range.
2. **Criteria** — the ticket from `--ticket` or the branch name, read through `jira-tickets`. No
   ticket → say the review runs without acceptance criteria.
3. **Review** — `git diff <base>...<head>`. Each criterion: met, not met, or not verifiable. Then
   design, tests (behaviour, not implementation), the documentation rule, and code health.
4. **Report** — per `report-format.md`, unabridged.

Findings are not fixes. To act on them, run `/deliver` with the ticket and the findings as
clarification, or fix them in a normal session.
