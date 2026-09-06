---
description: "Enhance a Jira ticket description into a concise, sourced user story"
---

The text after `/enhance-jira-description` is the ticket key (e.g. `PROJ-1234`). If it is empty,
ask for the ticket number. If the user gives a bare number, assume `$JIRA_PROJECT_KEY` unless
context makes another project key obvious.

1. Delegate to the `enhance-jira-description-agent` subagent in the foreground (this command is
   interactive — the agent blocks on your approval before updating Jira). Prompt: the resolved
   ticket key plus any additional instructions verbatim.
2. Relay the agent's proposed description back to the user unabridged and forward their approval
   or edits to the same agent — resume it, do not spawn a second one.
3. After the update, relay the ticket key, URL, and confirmation that the description was updated.

The agent owns the description format, the sources it may draw on, and the grounding rules. Never
skip the approval step unless the user explicitly says "update without review" or "just update it".
