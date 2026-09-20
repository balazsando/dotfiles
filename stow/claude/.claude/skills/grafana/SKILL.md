---
name: grafana
description: "Grafana dashboards, panels, visualizations, variables, transformations, dashboard JSON, provisioning, unified alerting, data sources, and the Grafana HTTP API. Also for writing or debugging PromQL (Prometheus/Mimir), LogQL (Loki), and Tempo trace queries, and for tuning query cost and cardinality."
argument-hint: "the dashboard, query, alert, or API task"
---

# Grafana

Emitting meters and Observations is `micrometer`; production log triage is `app-bug-detection`.
This skill is dashboards, queries, alerting, and the Grafana API.

Source of truth: the official docs index at <https://grafana.com/llms.txt> — prefer the `.md`
page versions it links. Community sources only when the official docs do not answer.

## MCP servers

Registered: `grafana` (default, non-prod), `grafana-prep` and `grafana-prep-connector`
(pre-prod), `grafana-prod` (production). Prefer their tools over hand-rolled HTTP calls.
`grafana_api_request` covers what no dedicated tool does.

- Reads (search, query, get, list) run freely.
- Writes (`update_dashboard`, `create_*`, `alerting_manage_*`, `update_*`, `delete_*`,
  `install_plugin`) change a shared instance — confirm first and name the instance.
- `grafana-prod` is read-only in practice.
- Hand the user a `generate_deeplink` link instead of describing navigation.

