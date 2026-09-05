---
description: "Review a merge request against its linked Jira ticket with structured, severity-based feedback"
argument-hint: "<MR-URL-or-branch> [additional instructions]"
---

When invoked with `$ARGUMENTS`:

1. Identify the merge request to review (URL, MR ID, or source branch) from the arguments. If none is present, ask for one before proceeding.
2. Determine the state file path: `.claude/state/jira-mr-reviewer-<MR-ID-or-branch>.json` relative to the current repo root. Create the parent directory if it doesn't exist. If a state file already exists for this MR, tell the agent to resume from it instead of starting over.
3. Spawn the `jira-mr-reviewer` agent via the Agent tool with `run_in_background: false` (this command is interactive — the agent's CLARIFY state blocks on your input, so it must run in the foreground of this conversation).
   - `description`: `"MR review: <MR identifier>"`
   - `prompt`: include the MR identifier, the resolved state file path, and any additional instructions from `$ARGUMENTS` verbatim.
4. Relay the agent's structured review output (Ticket Context, Domain Context Notes, CRITICAL/MAJOR/MINOR/INFORMATIONAL sections, Summary) back to the user directly, unabridged.
5. If the agent reaches CLARIFY, forward its questions to the user and resume the same agent (via SendMessage, not a new spawn) once answered.
