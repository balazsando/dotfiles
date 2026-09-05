# GitLab REST API v4 — Resource Catalog

Source: https://docs.gitlab.com/api/api_resources/

## Project Resources (`/projects/:id/...`)

| Resource | Endpoint(s) |
|----------|-------------|
| Access requests | `/projects/:id/access_requests` |
| Access tokens | `/projects/:id/access_tokens` |
| Cluster agents | `/projects/:id/cluster_agents` |
| Branches | `/projects/:id/repository/branches`, `/projects/:id/repository/merged_branches` |
| Commits | `/projects/:id/repository/commits`, `/projects/:id/statuses` |
| Container registry | `/projects/:id/registry/repositories` |
| Custom attributes | `/projects/:id/custom_attributes` |
| Dependencies | `/projects/:id/dependencies` |
| Deploy keys | `/projects/:id/deploy_keys` |
| Deploy tokens | `/projects/:id/deploy_tokens` |
| Deployments | `/projects/:id/deployments` |
| Discussions (threaded comments) | `/projects/:id/issues/.../discussions`, `/projects/:id/merge_requests/.../discussions`, `/projects/:id/commits/.../discussions` |
| Draft notes | `/projects/:id/merge_requests/.../draft_notes` |
| Emoji reactions | `/projects/:id/issues/.../award_emoji`, `/projects/:id/merge_requests/.../award_emoji` |
| Environments | `/projects/:id/environments` |
| Events | `/projects/:id/events` |
| Feature flags | `/projects/:id/feature_flags` |
| Freeze periods | `/projects/:id/freeze_periods` |
| Integrations | `/projects/:id/integrations` |
| Invitations | `/projects/:id/invitations` |
| Issue boards | `/projects/:id/boards` |
| Issue links | `/projects/:id/issues/.../links` |
| Issues | `/projects/:id/issues` |
| Issues statistics | `/projects/:id/issues_statistics` |
| Iterations | `/projects/:id/iterations` |
| Job token scope | `/projects/:id/job_token_scope` |
| Jobs | `/projects/:id/jobs`, `/projects/:id/pipelines/.../jobs` |
| Job artifacts | `/projects/:id/jobs/:job_id/artifacts` |
| Labels | `/projects/:id/labels` |
| Members | `/projects/:id/members` |
| Merge request approvals | `/projects/:id/approvals`, `/projects/:id/merge_requests/.../approvals` |
| Merge requests | `/projects/:id/merge_requests` |
| Merge trains | `/projects/:id/merge_trains` |
| Notes (comments) | `/projects/:id/issues/.../notes`, `/projects/:id/merge_requests/.../notes` |
| Notification settings | `/projects/:id/notification_settings` |
| Packages | `/projects/:id/packages` |
| Pages settings | `/projects/:id/pages` |
| Pipeline schedules | `/projects/:id/pipeline_schedules` |
| Pipeline triggers | `/projects/:id/triggers` |
| Pipelines | `/projects/:id/pipelines` |
| Project badges | `/projects/:id/badges` |
| Project milestones | `/projects/:id/milestones` |
| Project snippets | `/projects/:id/snippets` |
| Project vulnerabilities | `/projects/:id/vulnerabilities` |
| Project wikis | `/projects/:id/wikis` |
| Project variables | `/projects/:id/variables` |
| Projects & webhooks | `/projects`, `/projects/:id/hooks` |
| Protected branches | `/projects/:id/protected_branches` |
| Protected environments | `/projects/:id/protected_environments` |
| Protected tags | `/projects/:id/protected_tags` |
| Releases | `/projects/:id/releases` |
| Release links | `/projects/:id/releases/.../assets/links` |
| Repositories | `/projects/:id/repository` |
| Repository files | `/projects/:id/repository/files` |
| Repository submodules | `/projects/:id/repository/submodules` |
| Resource label events | `/projects/:id/issues/.../resource_label_events`, `/projects/:id/merge_requests/.../resource_label_events` |
| Runners | `/projects/:id/runners` |
| Search | `/projects/:id/search` |
| Tags | `/projects/:id/repository/tags` |
| Validate CI YAML | `/projects/:id/ci/lint` |
| Vulnerability exports | `/projects/:id/vulnerability_exports` |
| Vulnerability findings | `/projects/:id/vulnerability_findings` |

## Group Resources (`/groups/:id/...`)

| Resource | Endpoint(s) |
|----------|-------------|
| Access requests | `/groups/:id/access_requests` |
| Access tokens | `/groups/:id/access_tokens` |
| Custom attributes | `/groups/:id/custom_attributes` |
| Deploy tokens | `/groups/:id/deploy_tokens` |
| Discussions | `/groups/:id/epics/.../discussions` |
| Epic issues | `/groups/:id/epics/.../issues` |
| Epic links | `/groups/:id/epics/.../epics` |
| Epics | `/groups/:id/epics` |
| Groups & subgroups | `/groups`, `/groups/.../subgroups` |
| Group badges | `/groups/:id/badges` |
| Group issue boards | `/groups/:id/boards` |
| Group iterations | `/groups/:id/iterations` |
| Group labels | `/groups/:id/labels` |
| Group variables | `/groups/:id/variables` |
| Group milestones | `/groups/:id/milestones` |
| Group releases | `/groups/:id/releases` |
| Group wikis | `/groups/:id/wikis` |
| Invitations | `/groups/:id/invitations` |
| Issues | `/groups/:id/issues` |
| Linked epics | `/groups/:id/epics/.../related_epics` |
| Member roles | `/groups/:id/member_roles` |
| Members | `/groups/:id/members` |
| Merge requests | `/groups/:id/merge_requests` |
| Notes | `/groups/:id/epics/.../notes` |
| Notification settings | `/groups/:id/notification_settings` |
| Search | `/groups/:id/search` |

## Standalone Resources

| Resource | Endpoint(s) |
|----------|-------------|
| Applications | `/applications` |
| Audit events | `/audit_events` |
| Avatar | `/avatar` |
| Broadcast messages | `/broadcast_messages` |
| Code snippets | `/snippets` |
| Deploy keys | `/deploy_keys` |
| Deploy tokens | `/deploy_tokens` |
| Events | `/events`, `/users/:id/events` |
| Issues | `/issues` |
| Issues statistics | `/issues_statistics` |
| Jobs | `/job` |
| Merge requests | `/merge_requests` |
| Namespaces | `/namespaces` |
| Notification settings | `/notification_settings` |
| Pages domains | `/pages/domains` |
| Personal access tokens | `/personal_access_tokens` |
| Projects | `/users/:id/projects` |
| Runners | `/runners` |
| Search | `/search` |
| Settings | `/application/settings` |
| Statistics | `/application/statistics` |
| System hooks | `/hooks` |
| To-dos | `/todos` |
| Topics | `/topics` |
| Users | `/users` |
| Metadata | `/metadata` |
| License | `/license` |

## Template Resources

| Template | Endpoint |
|----------|----------|
| Dockerfile templates | `/templates/dockerfiles` |
| `.gitignore` templates | `/templates/gitignores` |
| GitLab CI YAML templates | `/templates/gitlab_ci_ymls` |
| License templates | `/templates/licenses` |
