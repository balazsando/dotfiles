---
description: "Enhance a Jira ticket description into a concise, sourced user story"
---

Rewrite the description of the ticket named after `/enhance-jira-description`. Empty → ask for
the key. Any further text is extra instructions.

Load `jira-tickets` — it owns the MCP tool chain, the approval gate, and the grounding rule. This
command owns the sources and the format. The description field only: no other Jira field, no
code, no files.

## Sources, in order

1. **The ticket** — fields, description, comments, linked and remote issues.
2. **Its links** — Confluence pages, merge requests, dashboards, other tickets.
3. **The documentation repositories** named in `~/.cursor/local/doc-repos.md`, for the "why".
   Missing file → say so and skip this source.
4. **The code** the ticket affects, read-only. Labels, components, and the summary point to the
   repository.

An unavailable or inconclusive source is a stated gap, never a guess.

## Format

```markdown
### User Story

> As a [user], I want [capability], so that [value].

### Context

<Factual background: why it matters, what exists today, constraints found in the sources.>

### Acceptance Criteria

- <Concise, testable criterion>

### Testing Strategy

<How the change is verified — test levels, manual steps, environments.>
```

- Merge still-valid existing content into the new structure; never keep two versions of a fact.
  Flag what is stale or contradicted by the code.
- Criteria and testing strategy are for QA, BA and PM: observable outcomes and how to check them,
  never an implementation recipe.
- Restate ADR decisions in plain language — no ADR numbers or titles.
- An already-accurate description gets the minimal fix, not a rewrite.

## Then

Show the key, URL, current summary, the full proposed description, and one line on what was
preserved, changed, and flagged. Write after the yes.
