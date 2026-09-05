# Grafana Skill Examples

## Example 1: Create a dashboard variable

User request:
"Create a Grafana variable `service` from my Prometheus label `service` and use it in a panel query."

What the skill does:
- Suggest a variable type (`query` variable for Prometheus labels)
- Provide a safe variable query (label values query pattern)
- Show how to reference it in panel queries (e.g. `$service` and escaping rules)
- Check that the variable results match the label names used in metrics

---

## Example 2: Explain and improve PromQL

User request:
"This PromQL is slow: `sum(rate(http_requests_total{path=~\"/api/.*\"}[5m])) by (route)`-what's wrong?"

What the skill does:
- Explains each component (selectors, range vector, `rate`, aggregation)
- Calls out potential performance/cardinality issues (regex matchers, grouping by `route`)
- Suggests safer alternatives (more selective matchers, smaller time range, fewer grouping labels)
- Preserves semantics unless the user asks for a behavior change

---

## Example 3: Provision a dashboard via YAML

User request:
"I want to provision these dashboards from `/etc/dashboards` and keep UI edits disabled."

What the skill does:
- Produces a `provisioning/dashboards/*.yaml` provider configuration using `apiVersion: 1` and `type: file`
- Sets `allowUiUpdates: false`
- Suggests `foldersFromFilesStructure: true` when you want folder mirroring
- Ensures you keep `uid` stable across updates

---

## Example 4: Set up unified alerting

User request:
"Create an alert that fires when `error_rate` is above 1% for 5 minutes."

What the skill does:
- Maps the request to unified alerting concepts (rule group, evaluation interval, condition, `for`)
- Ensures the query returns a numeric condition
- Recommends labels/annotations needed for routing and notifications
- Mentions no-data/error handling choices and how to debug them

---

## Example 5: Update a dashboard via HTTP API

User request:
"Deploy this dashboard JSON automatically using an API token."

What the skill does:
- Uses `Authorization: Bearer <token>`
- Uses `POST /api/dashboards/db`
- Sets `overwrite: true` and recommends including `folderUid` (and version behavior when needed)
- Produces a curl command that posts the dashboard payload

