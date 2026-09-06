---
name: gitlab-api
description: "Calling the GitLab REST API v4 from code: merge requests, issues, pipelines, branches, repositories, groups, users, CI/CD jobs, runners. Covers auth, pagination, error handling, and Go HTTP client patterns."
argument-hint: 'What GitLab resource or operation do you need? (e.g. "list merge requests", "create branch", "trigger pipeline")'
---

# GitLab REST API v4

Base URL: `<GITLAB_API_URL>/api/v4`  
Reference: https://docs.gitlab.com/api/api_resources/

## Authentication

Always send a `PRIVATE-TOKEN` header:
```
PRIVATE-TOKEN: <personal-access-token>
```

Or as a query param: `?private_token=<token>`

Required token scope depends on the operation:
- `read_api` — read-only
- `api` — full read/write (needed for creating/updating resources)

## Pagination

List endpoints return paginated results. Use these query params:
- `?page=1&per_page=100` (max `per_page` is 100)
- Response headers: `X-Total`, `X-Total-Pages`, `X-Next-Page`, `X-Page`

To get all pages, loop until `X-Next-Page` is empty.

## Common Patterns (Go)

### Authenticated GET
```go
req, _ := http.NewRequest("GET", apiURL+"/projects/"+id+"/merge_requests", nil)
req.Header.Set("PRIVATE-TOKEN", token)
resp, err := http.DefaultClient.Do(req)
```

### POST with JSON body
```go
body, _ := json.Marshal(map[string]any{"title": "My MR", "source_branch": "feat", "target_branch": "main"})
req, _ := http.NewRequest("POST", apiURL+"/projects/"+id+"/merge_requests", bytes.NewReader(body))
req.Header.Set("PRIVATE-TOKEN", token)
req.Header.Set("Content-Type", "application/json")
```

### URL-encode project ID
Project `:id` can be numeric ID or `namespace%2Frepo` (URL-encoded path).

## Procedure: Finding the Right Endpoint

1. Identify the **resource type** (issue, MR, pipeline, branch, user, group…).
2. Identify the **context** (project-scoped, group-scoped, or standalone).
3. Look up the endpoint pattern in [./references/api-resources.md](./references/api-resources.md).
4. Check the official docs page linked in the resource table for request parameters.
5. Construct the request with proper auth, content-type, and pagination if needed.

## Key Resources Quick Reference

| Task | Endpoint |
|------|----------|
| List project MRs | `GET /projects/:id/merge_requests` |
| Create MR | `POST /projects/:id/merge_requests` |
| Merge an MR | `PUT /projects/:id/merge_requests/:mr_iid/merge` |
| List issues | `GET /projects/:id/issues` |
| Create issue | `POST /projects/:id/issues` |
| List branches | `GET /projects/:id/repository/branches` |
| Create branch | `POST /projects/:id/repository/branches` |
| List pipelines | `GET /projects/:id/pipelines` |
| Trigger pipeline | `POST /projects/:id/pipeline` |
| List pipeline jobs | `GET /projects/:id/pipelines/:pipeline_id/jobs` |
| List MR approvals | `GET /projects/:id/merge_requests/:mr_iid/approvals` |
| Get project | `GET /projects/:id` |
| List user projects | `GET /users/:id/projects` |
| Search globally | `GET /search?scope=projects&search=foo` |
| Current user | `GET /user` |
| List group members | `GET /groups/:id/members` |

## Error Handling

| HTTP Code | Meaning |
|-----------|---------|
| 200/201 | Success |
| 400 | Bad request — check required params |
| 401 | Unauthorized — check token |
| 403 | Forbidden — insufficient token scope |
| 404 | Not found — check project ID / resource IID |
| 422 | Unprocessable — validation error (check response body) |
| 429 | Rate limited — back off and retry |

Always check `resp.StatusCode` and decode error body on non-2xx responses.

## Full Resource Catalog

See [./references/api-resources.md](./references/api-resources.md) for the complete list of all project, group, and standalone endpoints.
