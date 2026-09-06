---
name: jira-api
description: "Calling the Jira Cloud REST API v3 from code: issues, sprints, boards, worklogs, transitions, comments, projects, users. Covers auth, pagination, JQL search, ADF for descriptions and comments, time tracking, and Go HTTP client patterns."
argument-hint: 'What Jira resource or operation do you need? (e.g. "search issues by JQL", "log work", "transition issue", "get sprint board")'
---

# Jira REST API v3 (Cloud)

Base URL: `https://<your-domain>.atlassian.net/rest/api/3`  
Reference: https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/  
OpenAPI: https://dac-static.atlassian.com/cloud/jira/platform/swagger-v3.v3.json

## Authentication

Use **HTTP Basic Auth** for scripts/bots/integrations:
- Username: your Atlassian account email
- Password: an API token (https://id.atlassian.com/manage-profile/security/api-tokens)

```
Authorization: Basic base64(<email>:<api-token>)
```

In Go:
```go
req.SetBasicAuth(email, apiToken)
```

Always send `Content-Type: application/json` on POST/PUT requests.  
For multipart/form-data (file uploads), add: `X-Atlassian-Token: no-check`

## Pagination

Jira uses `startAt` / `maxResults` style pagination (not page numbers):

```json
{
  "startAt": 0,
  "maxResults": 50,
  "total": 200,
  "isLast": false,
  "values": [...]
}
```

- Set `maxResults` to a large value (e.g. 1000) to find the actual cap.
- Loop: increment `startAt` by `maxResults` until `isLast` is `true` or returned items < `maxResults`.
- `total` may not always be present — always check `isLast` or count returned items.

### Ordering

Use `?orderBy=name` (ascending), `?orderBy=-name` (descending).

### Expansion

Request extra fields with `?expand=names,renderedFields,transitions`.

## JQL (Jira Query Language)

Used for issue search (`/rest/api/3/search`):

```
project = "MYPROJ" AND sprint in openSprints() AND assignee = currentUser() ORDER BY updated DESC
```

Common JQL fields: `project`, `issuetype`, `status`, `assignee`, `reporter`, `sprint`, `labels`, `fixVersion`, `priority`, `created`, `updated`, `summary ~ "text"`

## Common Patterns (Go)

### Authenticated GET
```go
req, _ := http.NewRequest("GET", jiraURL+"/rest/api/3/issue/PROJ-1", nil)
req.SetBasicAuth(email, token)
req.Header.Set("Accept", "application/json")
resp, err := http.DefaultClient.Do(req)
```

### POST with JSON body
```go
body, _ := json.Marshal(map[string]any{...})
req, _ := http.NewRequest("POST", jiraURL+"/rest/api/3/issue", bytes.NewReader(body))
req.SetBasicAuth(email, token)
req.Header.Set("Content-Type", "application/json")
```

### ADF (Atlassian Document Format) for descriptions/comments
Use ADF for `description`, `comment.body`, `environment` fields in v3:
```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "paragraph",
      "content": [{ "type": "text", "text": "Your text here" }]
    }
  ]
}
```

## Key Endpoints Quick Reference

| Task | Method | Endpoint |
|------|--------|----------|
| Get issue | GET | `/rest/api/3/issue/{issueIdOrKey}` |
| Create issue | POST | `/rest/api/3/issue` |
| Update issue | PUT | `/rest/api/3/issue/{issueIdOrKey}` |
| Delete issue | DELETE | `/rest/api/3/issue/{issueIdOrKey}` |
| Search issues (JQL) | GET | `/rest/api/3/search?jql=...&startAt=0&maxResults=50` |
| Search issues (POST) | POST | `/rest/api/3/search` |
| Get issue transitions | GET | `/rest/api/3/issue/{issueIdOrKey}/transitions` |
| Transition issue | POST | `/rest/api/3/issue/{issueIdOrKey}/transitions` |
| Assign issue | PUT | `/rest/api/3/issue/{issueIdOrKey}/assignee` |
| Get comments | GET | `/rest/api/3/issue/{issueIdOrKey}/comment` |
| Add comment | POST | `/rest/api/3/issue/{issueIdOrKey}/comment` |
| Add worklog | POST | `/rest/api/3/issue/{issueIdOrKey}/worklog` |
| Get worklogs | GET | `/rest/api/3/issue/{issueIdOrKey}/worklog` |
| List projects | GET | `/rest/api/3/project/search` |
| Get project | GET | `/rest/api/3/project/{projectIdOrKey}` |
| Get boards | GET | `/rest/agile/1.0/board` |
| Get sprints for board | GET | `/rest/agile/1.0/board/{boardId}/sprint` |
| Get sprint issues | GET | `/rest/agile/1.0/sprint/{sprintId}/issue` |
| Get current user | GET | `/rest/api/3/myself` |
| Search users | GET | `/rest/api/3/user/search?query=...` |
| Get user | GET | `/rest/api/3/user?accountId=...` |
| List issue types | GET | `/rest/api/3/issuetype` |
| List statuses | GET | `/rest/api/3/status` |
| List priorities | GET | `/rest/api/3/priority` |
| Get issue fields | GET | `/rest/api/3/field` |

> **Agile endpoints** (`/rest/agile/1.0/...`) are separate from the core API — boards and sprints live there.

## Transition an Issue (Status Change)

1. Get available transitions: `GET /rest/api/3/issue/{key}/transitions`
2. Find the target `id` in the response.
3. POST to apply: 
```json
POST /rest/api/3/issue/{key}/transitions
{ "transition": { "id": "21" } }
```

## Log Work (Worklog)

```json
POST /rest/api/3/issue/{key}/worklog
{
  "timeSpent": "8h",
  "started": "2026-04-22T08:00:00.000+0000",
  "comment": {
    "version": 1,
    "type": "doc",
    "content": [{"type": "paragraph", "content": [{"type": "text", "text": "Daily work"}]}]
  }
}
```

`timeSpent` uses Jira duration format: `1w`, `2d`, `4h`, `30m`.

## Error Handling

| HTTP Code | Meaning |
|-----------|---------|
| 200/201/204 | Success |
| 400 | Bad request — check body / missing required fields |
| 401 | Unauthorized — check Basic Auth credentials |
| 403 | Forbidden — insufficient permissions |
| 404 | Not found — check issue key / project key |
| 429 | Rate limited — back off and retry |

Error response body:
```json
{ "errorMessages": ["..."], "errors": { "fieldName": "message" } }
```

## Full API Group Catalog

See [./references/api-groups.md](./references/api-groups.md) for the complete list of all API groups.
