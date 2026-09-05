---
description: "Implement a Jira ticket end-to-end and open a merge request"
argument-hint: "<TICKET-KEY> [additional instructions]"
---

When invoked with `$ARGUMENTS`:

1. Extract the Jira ticket key (e.g. `PROJ-2803`) from the arguments. If none is present, ask for one before proceeding.
2. Determine the state file path: `.claude/state/ticket-to-merge-<TICKET-KEY>.json` relative to the current repo root. Create the parent directory if it doesn't exist. If a state file for this ticket already exists, tell the agent to resume from it instead of starting over.
3. Spawn the `ticket-to-merge-agent` via the Agent tool with `run_in_background: false` (this command is interactive — the agent's CLARIFY state blocks on your input, so it must run in the foreground of this conversation).
   - `description`: `"Ticket -> MR: <TICKET-KEY>"`
   - `prompt`: include the ticket key, the resolved state file path, and any additional instructions from `$ARGUMENTS` verbatim, so the agent can substitute `{{TICKET}}` and `{{STATE_FILE}}`.
4. Relay the agent's state machine output (current state, actions taken, next state, and any CLARIFY questions) back to the user directly — do not summarize away blocking questions.
5. If the agent reaches CLARIFY, forward its questions to the user and resume the same agent (via SendMessage, not a new spawn) once answered.
