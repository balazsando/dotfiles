---
description: "Implement a Jira ticket end-to-end and open a merge request"
---

The text after `/ticket-to-merge` is the Jira ticket key plus any additional instructions.

1. Extract the Jira ticket key (e.g. `PROJ-2803`) from the arguments. If none is present, ask for
   one before proceeding.
2. Determine the state file path: `.cursor/state/ticket-to-merge-<TICKET-KEY>.json` relative to
   the current repo root. Create the parent directory if it doesn't exist. If a state file for
   this ticket already exists, tell the agent to resume from it instead of starting over.
3. Delegate to the `ticket-to-merge-agent` subagent in the foreground (this command is
   interactive — the agent's CLARIFY state blocks on your input). Prompt: the ticket key, the
   resolved state file path, and any additional instructions verbatim, so the agent can
   substitute `{{TICKET}}` and `{{STATE_FILE}}`.
4. Relay the agent's state machine output (current state, actions taken, next state, and any
   CLARIFY questions) back to the user directly — do not summarize away blocking questions.
5. If the agent reaches CLARIFY, forward its questions to the user and resume the same agent once
   answered — never spawn a second one.
