# Jira REST API v3 — API Group Catalog

Source: https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/

All endpoints are under `https://<domain>.atlassian.net/rest/api/3/` unless noted.

## Core Issue Operations

| Group | Key Endpoints |
|-------|---------------|
| Issues | `/issue`, `/issue/{id}` |
| Issue search | `/search` (GET with `?jql=`, or POST with body) |
| Issue comments | `/issue/{id}/comment`, `/issue/{id}/comment/{commentId}` |
| Issue worklogs | `/issue/{id}/worklog`, `/issue/{id}/worklog/{worklogId}` |
| Issue attachments | `/issue/{id}/attachments`, `/attachment/{id}` |
| Issue transitions | `/issue/{id}/transitions` |
| Issue links | `/issueLink`, `/issueLink/{linkId}`, `/issueLinkType` |
| Issue remote links | `/issue/{id}/remotelink` |
| Issue votes | `/issue/{id}/votes` |
| Issue watchers | `/issue/{id}/watchers` |
| Issue assignee | `/issue/{id}/assignee` |
| Issue bulk operations | `/issue/bulkCreate`, `/issue/bulk` |
| Issue priorities | `/priority`, `/priority/{id}` |
| Issue resolutions | `/resolution`, `/resolution/{id}` |
| Issue types | `/issuetype`, `/issuetype/{id}` |
| Issue fields | `/field` |
| Issue properties | `/issue/{id}/properties/{propertyKey}` |

## Agile (Boards & Sprints)

> Base: `https://<domain>.atlassian.net/rest/agile/1.0/`

| Group | Key Endpoints |
|-------|---------------|
| Boards | `/board`, `/board/{boardId}` |
| Sprints | `/board/{boardId}/sprint`, `/sprint/{sprintId}`, `/sprint/{sprintId}/issue` |
| Board backlog | `/board/{boardId}/backlog` |
| Board issues | `/board/{boardId}/issue` |
| Epics | `/board/{boardId}/epic`, `/epic/{epicId}/issue` |

## Projects

| Group | Key Endpoints |
|-------|---------------|
| Projects | `/project`, `/project/search`, `/project/{key}` |
| Project components | `/project/{key}/components`, `/component/{id}` |
| Project versions | `/project/{key}/versions`, `/version/{id}` |
| Project roles | `/project/{key}/role`, `/project/{key}/role/{id}` |
| Project features | `/project/{key}/features` |
| Project categories | `/projectCategory`, `/projectCategory/{id}` |
| Project types | `/projectType`, `/projectType/{key}` |
| Project properties | `/project/{key}/properties/{propertyKey}` |

## Users & Groups

| Group | Key Endpoints |
|-------|---------------|
| Myself | `/myself` |
| Users | `/user`, `/user?accountId=`, `/user/bulk` |
| User search | `/user/search?query=`, `/user/assignable/search` |
| User properties | `/user/properties/{propertyKey}` |
| Groups | `/group`, `/groups/picker` |
| Group and user picker | `/groupuserpicker` |

## JQL

| Group | Key Endpoints |
|-------|---------------|
| JQL autocomplete | `/jql/autocompletedata` |
| JQL parse | `/jql/parse` |
| JQL sanitize | `/jql/sanitize` |
| JQL functions | `/jql/function/computation` |

## Workflows & Statuses

| Group | Key Endpoints |
|-------|---------------|
| Workflows | `/workflow`, `/workflow/search` |
| Workflow schemes | `/workflowscheme`, `/workflowscheme/{id}` |
| Workflow statuses | `/status`, `/status/{idOrName}` |
| Workflow status categories | `/statuscategory`, `/statuscategory/{id}` |
| Workflow transition rules | `/workflow/rule/config` |

## Permissions & Schemes

| Group | Key Endpoints |
|-------|---------------|
| Permissions | `/permissions`, `/permissions/check` |
| Permission schemes | `/permissionscheme`, `/permissionscheme/{id}` |
| Issue security schemes | `/issuesecurityschemes` |
| Notification schemes | `/notificationscheme` |

## Screens & Fields

| Group | Key Endpoints |
|-------|---------------|
| Screens | `/screens`, `/screens/{id}` |
| Screen tabs | `/screens/{id}/tabs`, `/screens/{id}/tabs/{tabId}` |
| Screen tab fields | `/screens/{id}/tabs/{tabId}/fields` |
| Screen schemes | `/screenscheme` |
| Field configurations | `/fieldconfiguration` |
| Field schemes | `/fieldconfigurationscheme` |
| Issue type schemes | `/issuetypescheme` |
| Issue type screen schemes | `/issuetypescreenscheme` |

## Time Tracking

| Group | Key Endpoints |
|-------|---------------|
| Time tracking | `/configuration/timetracking`, `/configuration/timetracking/list` |
| Worklogs | `/issue/{id}/worklog`, `/worklog/list`, `/worklog/updated` |

## Filters & Dashboards

| Group | Key Endpoints |
|-------|---------------|
| Filters | `/filter`, `/filter/{id}`, `/filter/search` |
| Filter sharing | `/filter/{id}/permission` |
| Dashboards | `/dashboard`, `/dashboard/{id}` |

## Webhooks & App

| Group | Key Endpoints |
|-------|---------------|
| Webhooks | `/webhook`, `/webhook/refresh`, `/webhook/failed` |
| App properties | `/addon/properties` |
| Audit records | `/auditing/record` |

## Server & Admin

| Group | Key Endpoints |
|-------|---------------|
| Server info | `/serverInfo` |
| Labels | `/label` |
| Jira settings | `/application-properties`, `/configuration` |
| License metrics | `/instance/license` |
| Tasks (async) | `/task/{taskId}` |
