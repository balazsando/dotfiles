---
description: "Enhance a Jira ticket description into a concise, sourced user story"
argument-hint: "<TICKET-KEY>"
---

When invoked with `$ARGUMENTS`:

1. Treat `$ARGUMENTS` as the ticket key (e.g. `PROJ-1234`). If it is empty, ask for the ticket number. If the user gives a bare number, assume `$JIRA_PROJECT_KEY` unless context makes another project key obvious.
2. Spawn the `jira-ticket-description-enhancer` agent via the Agent tool with `run_in_background: false` (this command is interactive — the agent blocks on your approval before updating Jira).
   - `description`: `"Enhance <TICKET-KEY> description"`
   - `prompt`: the resolved ticket key plus any additional instructions from `$ARGUMENTS` verbatim.
3. Relay the agent's proposed description back to the user unabridged and forward their approval or edits to the same agent via SendMessage — do not spawn a second agent.
4. After the update, relay the ticket key, URL, and confirmation that the description was updated.

## Description format

```markdown
### User Story

> As a [user], I want [capability], so that [value].

### Context

<Brief, factual background from gathered sources.>

### Acceptance Criteria

- <Concise, testable criterion>

### Testing Strategy

<How the change should be verified. If unknown from sources, say so.>
```

The agent grounds every claim in the ticket, its links, the `ai-domain` knowledge base, and the related repository. It never invents details and never modifies code. Never skip the approval step unless the user explicitly says "update without review" or "just update it".
