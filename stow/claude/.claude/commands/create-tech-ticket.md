---
description: "Create a technical backlog Jira ticket from a short prompt"
argument-hint: "<what the ticket should cover>"
---

When invoked with `$ARGUMENTS`:

1. Treat `$ARGUMENTS` as the ticket prompt. If it is empty, ask what the ticket should cover before proceeding.
2. Spawn the `create-tech-ticket-agent` via the Agent tool with `run_in_background: false` (this command is interactive — the agent blocks on your approval before creating anything).
   - `description`: `"Draft $JIRA_PROJECT_KEY tech ticket"`
   - `prompt`: `$ARGUMENTS` verbatim.
3. Relay the agent's draft (Summary, fields, Component, full Description) back to the user unabridged and forward their approval or edits to the same agent via SendMessage — do not spawn a second agent.
4. After creation, relay the ticket key, URL, and TECH Backlog placement status.

The agent owns the summary and description format, the scope → tag → component mapping, and the
machine-local conventions in `~/.claude/local/jira-conventions.md`. Never skip the approval step
unless the user explicitly says "create without review" or "just create it".
