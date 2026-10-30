---
name: jira-tickets
description: "Operating on Jira tickets through the Jira MCP server and REST v2: reading an issue with its comments, links and remote links, the active sprint, releases and worklogs; writing a description, comment, labels, status, worklog or a new issue; sprint placement, and the approval gate before any write. Owns all ticket MCP access. Use when reading a ticket for requirements or when creating or updating one."
argument-hint: "ticket key, or the ticket to create"
---

# Jira tickets

Single owner of everything that talks to a Jira MCP server. Commands that need ticket data follow
this file instead of calling the MCP their own way.

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

| Need | Tool |
| --- | --- |
| Issue fields | `jira_get_issue` |
| Comments | `jira_get_issue_comments` |
| Linked issues | `jira_get_issue_links` |
| External links | curl `GET $JIRA_URL/rest/api/2/issue/<KEY>/remotelink` |
| Active sprint | `jira_get_sprints` (`$JIRA_BOARD_ID`, active), then `jira_get_sprint_issues` |
| Releases | `jira_get_versions` |
| Worklogs | `jira_get_issue_worklogs`, `jira_get_user_worklogs` |

Read comments before concluding anything: a reopened ticket usually carries its real requirement
there. Follow URLs found in the description or comments (Confluence, merge requests, dashboards)
only when they bear on the question asked.

## Write

**Never write without showing the draft and getting an explicit yes.** Show the ticket key and
URL, the full proposed content, and one line on what changed. Then ask. Skip the gate only if the
user said "just create it" / "update without review".

| Need | Tool |
| --- | --- |
| Create an issue | `jira_create_issue`, without a formatted description |
| Formatted description | curl `PUT $JIRA_URL/rest/api/2/issue/<KEY>`, body `{"fields":{"description":"<wiki markup>"}}` |
| Comment with formatting or a link | curl `POST`/`PUT $JIRA_URL/rest/api/2/issue/<KEY>/comment[/<id>]`, body `{"body":"<wiki markup>"}` |
| Plain comment | `jira_add_comment` |
| Labels, fix versions, other fields | `jira_update_issue` (`labels: {add, remove}`) |
| Status | `jira_get_transitions`, then `jira_transition_issue` |
| Log work | `jira_add_worklog` |
| Sprint or backlog placement | `jira_move_issues_to_sprint` / `jira_move_issues_to_backlog` |
| Verify the result | `jira_get_issue` |

The MCP stores `description` and comment bodies as plain text, so markup stays raw. Formatted text
goes through REST v2 as wiki markup, never v3 ADF: same content, a fraction of the tokens.
Authenticate with `-u "$JIRA_EMAIL:$JIRA_TOKEN"`. Wiki markup: `h2.` headings, `*` / `#` lists
(`**` nests), `*bold*`, `{{code}}`, `{code}…{code}` blocks, `[text|url]` links.

If `jira_create_issue` fails on required custom fields, call `jira_get_create_metadata` for the
project and issue type and set only the fields it reports as required. If sprint placement
fails, report the created key and say it must be dragged into place by hand.

Never invent a custom-field value. Never create a second ticket when the user already gave a key.

## Grounding

Every statement in a ticket traces to something read — the ticket, a link, the documentation
repositories, or the code. A section that cannot be filled from a source says so ("no test plan
found in ticket or repo"); it is never filled with a plausible guess. Return the key and
`$JIRA_URL/browse/<KEY>` after any write.
