---
description: "Review a merge request against its linked Jira ticket with structured, severity-based feedback"
---

The text after `/jira-mr-reviewer` is the merge request to review (URL, MR ID, or source branch)
plus any additional instructions.

1. Identify the merge request from the arguments. If none is present, ask for one before
   proceeding.
2. Determine the state file path: `.cursor/state/jira-mr-reviewer-<MR-ID-or-branch>.json`
   relative to the current repo root. Create the parent directory if it doesn't exist. If a state
   file already exists for this MR, tell the agent to resume from it instead of starting over.
3. Delegate to the `jira-mr-reviewer-agent` subagent in the foreground (this command is
   interactive — the agent's CLARIFY state blocks on your input). Prompt: the MR identifier, the
   resolved state file path, and any additional instructions verbatim.
4. Relay the agent's structured review output (Ticket Context, Domain Context Notes,
   CRITICAL/MAJOR/MINOR/INFORMATIONAL sections, Summary) back to the user directly, unabridged.
5. If the agent reaches CLARIFY, forward its questions to the user and resume the same agent once
   answered — never spawn a second one.
