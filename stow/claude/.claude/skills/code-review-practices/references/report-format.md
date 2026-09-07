# Structured review report

For a review handed back as one document (a merge request, a workflow's review stage) rather
than as inline comments. The inline severity labels in `SKILL.md` still apply per comment; this
is how the whole review is shaped. Same finding, two scales:

| Report severity | Inline label | Meaning |
| --- | --- | --- |
| CRITICAL | `MUST:` | Breaks an acceptance criterion, security, data loss, wrong core logic |
| MAJOR | `MUST:` | Architectural violation, missing error handling, wrong edge case, missing test for a stated criterion |
| MINOR | `Nit:` / `Consider:` | Readability, naming, a small local simplification |
| INFORMATIONAL | `FYI:` | Observation, alternative, context worth recording |

## Shape

```markdown
## Scope
<what was reviewed: branch or MR, commit range, files>

## Requirements
<criterion → met / not met / not verifiable, one line each; omit when no criteria were supplied>

## CRITICAL
- <finding> — `file:line` — <what to do>

## MAJOR / MINOR / INFORMATIONAL
- <same shape; omit an empty section>

## Verdict
READY | CHANGES REQUESTED — <one sentence>
```

## Rules

- Every finding carries a `file:line`. A finding with no location is not actionable — drop it or
  turn it into a question.
- Judge the change that is there, not the one you would have written. An alternative you prefer
  is INFORMATIONAL unless the code is wrong.
- Unverifiable is its own answer. Never mark a criterion met because the code looks plausible.
- One CRITICAL is enough for CHANGES REQUESTED. Never soften a finding to reach READY, and never
  invent one to look thorough.
- No fixes, no diffs, no edits — the report is the whole output.
