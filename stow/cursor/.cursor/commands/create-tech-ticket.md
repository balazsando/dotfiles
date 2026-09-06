---
description: "Create a technical backlog Jira ticket from a short prompt"
---

The text after `/create-tech-ticket` is the ticket prompt. If it is empty, ask what the ticket
should cover before proceeding.

1. Delegate to the `create-tech-ticket-agent` subagent in the foreground (this command is
   interactive — the agent blocks on your approval before creating anything). Pass the ticket
   prompt verbatim.
2. Relay the agent's draft (Summary, fields, Component, full Description) back to the user
   unabridged and forward their approval or edits to the same agent — resume it, do not spawn a
   second one.
3. After creation, relay the ticket key, URL, and TECH Backlog placement status.

The agent owns the summary and description format, the scope → tag → component mapping, and the
machine-local conventions in `~/.cursor/local/jira-conventions.md`. Never skip the approval step
unless the user explicitly says "create without review" or "just create it".
