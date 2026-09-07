---
name: jira-tickets
description: "Operating on Jira tickets through the Jira and Atlassian Rovo MCP servers: reading an issue with its comments, links and remote links, writing a description or creating an issue, sprint placement, the tool-priority chain, and the approval gate before any write. Owns all ticket MCP access. Use when reading a ticket for requirements or when creating or updating one."
argument-hint: "ticket key, or the ticket to create"
---

# Jira tickets

Single owner of everything that talks to a Jira MCP server. Agents and commands that need ticket
data follow this file instead of calling the MCP their own way. Writing Go or HTTP code against
the REST API is a different job — that is `jira-api`.

## Conventions are machine-local

Project key, board and sprint ids, labels, and the scope → summary-tag → component mapping are
**not** in this repository. **Read `~/.claude/local/jira-conventions.md` before drafting or
filing anything.** If it is missing, ask for the project key, board, and target sprint rather
than guessing — a ticket on the wrong board is cleaned up by hand.

Connection details come from the environment: `$JIRA_URL`, `$JIRA_EMAIL`, `$JIRA_TOKEN`,
`$JIRA_PROJECT_KEY`, `$JIRA_BOARD_ID` (set in `~/.config/zsh/secrets`). A bare number means
`$JIRA_PROJECT_KEY` unless context makes another key obvious.

## Read

Take only what the caller asked for; a full issue dump is expensive and mostly irrelevant.

| Need | Jira MCP | Rovo MCP fallback |
| --- | --- | --- |
| Issue fields | `jira_get_issue` | `getJiraIssue` |
| Comments | `jira_get_issue_comments` | — |
| Linked issues | `jira_get_issue_links` | — |
| External links | — | `getJiraIssueRemoteIssueLinks` |

Read comments before concluding anything: a reopened ticket usually carries its real requirement
there. Follow URLs found in the description or comments (Confluence, merge requests, dashboards)
only when they bear on the question asked.

## Write

**Never write without showing the draft and getting an explicit yes.** Show the ticket key and
URL, the full proposed content, and one line on what changed. Then ask. Skip the gate only if the
user said "just create it" / "update without review".

| Need | First | Fallback |
| --- | --- | --- |
| Create an issue | `createJiraIssue` | curl with `$JIRA_EMAIL` / `$JIRA_TOKEN` |
| Update fields or description | `jira_update_issue` | `editJiraIssue` |
| Sprint or backlog placement | `jira_move_issues_to_sprint` | `editJiraIssue` with the sprint field |
| Verify the result | `getJiraIssue` | `jira_get_issue` |

If `createJiraIssue` fails on required custom fields, call `getJiraIssueTypeMetaWithFields` for
the project and issue type and set only the fields it reports as required. If sprint placement
fails both ways, report the created key and say it must be dragged into place by hand.

Never invent a custom-field value. Never create a second ticket when the user already gave a key.

## Grounding

Every statement in a ticket traces to something read — the ticket, a link, the knowledge base, or
the code. A section that cannot be filled from a source says so ("no test plan found in ticket or
repo"); it is never filled with a plausible guess. Return the key and
`$JIRA_URL/browse/<KEY>` after any write.
