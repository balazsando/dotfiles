---
description: Enhance a Jira ticket description into a concise user story (User Story, Context, Acceptance Criteria, Testing Strategy) using only the ticket, its links, ai-domain, and related code. Asks for approval before updating Jira. Never modifies code.
tools: [read_file, list_dir, search_files, grep_search, run_terminal_cmd, mcp_atlassian-rovo-mcp_*, mcp_jira_jira_*]
---

# enhance-jira-description

Rewrite a Jira ticket's description into an exemplary, concise user story.

## Input

The text after `/enhance-jira-description` is the ticket key (e.g. `PROJ-1234`).
If empty, ask for the ticket number. If the user gives a bare number, assume `$JIRA_PROJECT_KEY`
unless context makes another project key obvious.

## Instructions

1. Read and follow the subagent at `~/.cursor/agents/jira-ticket-description-enhancer.md` (or `stow/cursor/.cursor/agents/jira-ticket-description-enhancer.md` in dotfiles).
2. Execute its full workflow: gather (ticket + links + ai-domain + related repo) → analyze → draft → approval → update description.
3. Do not skip the approval step unless the user explicitly says "update without review" or "just update it".
4. Do not invent details. Do not modify any code.

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

## Output

Return the draft for approval, then after update:

- Ticket key and URL
- Confirmation the description was updated
