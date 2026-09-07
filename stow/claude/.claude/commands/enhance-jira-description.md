---
description: "Enhance a Jira ticket description into a concise, sourced user story"
argument-hint: "<TICKET-KEY>"
---

When invoked with `$ARGUMENTS`:

1. Treat `$ARGUMENTS` as the ticket key (e.g. `PROJ-1234`). If it is empty, ask for the ticket number. If the user gives a bare number, assume `$JIRA_PROJECT_KEY` unless context makes another project key obvious.
2. Spawn the `enhance-jira-description-agent` via the Agent tool in the foreground (this command is interactive — the agent blocks on your approval before updating Jira).
   - `description`: `"Enhance <TICKET-KEY> description"`
   - `prompt`: the resolved ticket key plus any additional instructions from `$ARGUMENTS` verbatim.
3. Relay the agent's proposed description back to the user unabridged and forward their approval or edits to the same agent via SendMessage — do not spawn a second agent.
4. After the update, relay the ticket key, URL, and confirmation that the description was updated.

The agent owns the description format, the sources it may draw on, and the grounding rules. Never
skip the approval step unless the user explicitly says "update without review" or "just update it".
