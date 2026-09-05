---
description: Create a technical backlog Jira ticket from a short prompt. Drafts an agile user story, asks for approval, then creates the ticket and adds it to TECH Backlog.
tools: [read_file, mcp_atlassian-rovo-mcp_*, mcp_jira_jira_*]
---

# create-tech-ticket

Create a Jira ticket on the **TECH Backlog** from the user's prompt.

## Input

The text after `/create-tech-ticket` is the ticket prompt. If empty, ask what the ticket should cover.

## Instructions

1. Read and follow the subagent at `~/.cursor/agents/jira-tech-ticket-creator.md` (or `stow/cursor/.cursor/agents/jira-tech-ticket-creator.md` in dotfiles).
2. Execute its full workflow: draft → approval → create → add to TECH Backlog.
3. Do not skip the approval step unless the user explicitly says "create without review" or "just create it".

## Quick reference

Field defaults (project, board, sprint, label, priority), the reference tickets, and the
scope → summary-tag → component mapping are machine-local.

**Read `~/.cursor/local/jira-conventions.md` first.** If it is missing, ask the user for the
project key, board, and target sprint instead of guessing.

Invariant regardless of project:

| Field | Value |
|-------|-------|
| Type | Task |
| Summary | `[TECH][AREA] Title` — AREA must match the scope table |
| Description | User Story → Context → Acceptance Criteria → Definition of Done |

## Output

Return the draft for approval, then after creation:

- Ticket key and URL
- Confirmation it was added to TECH Backlog
