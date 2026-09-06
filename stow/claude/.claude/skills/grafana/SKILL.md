---
name: grafana
description: "Grafana dashboards, panels, visualizations, variables, transformations, dashboard JSON, provisioning, unified alerting, data sources, and the Grafana HTTP API. Also for writing or debugging PromQL (Prometheus/Mimir), LogQL (Loki), and Tempo trace queries, and for tuning query cost and cardinality."
argument-hint: "What Grafana task do you need help with? (e.g. \"create a dashboard variable\", \"write PromQL\", \"debug a dashboard\", \"provision dashboards\", \"set up alerting\", \"use Grafana HTTP API\")"
---

# Grafana

# Documentation Source

Always use the official Grafana LLM documentation index as the primary source of truth.

Primary documentation:

<https://grafana.com/llms.txt>

This file provides an AI-friendly index of the official Grafana documentation and should be consulted first to locate the relevant documentation pages. Prefer the Markdown (`.md`) versions of documentation pages whenever available, as they are optimized for automated readers. Grafana explicitly publishes these machine-readable indexes for AI tools.

Only use community articles or Stack Overflow if the official documentation does not answer the question.

---

# Grafana MCP Server

This environment registers Grafana MCP servers in `~/.claude/mcp-servers.json`: `grafana`,
`grafana-prep` (pre-prod), and `grafana-prod` (production — read-only use, see the
`app-bug-detection` skill for log triage). Prefer the MCP tools over hand-rolled HTTP API calls or
`curl` — they are authenticated, read the live instance, and return structured results.

Typical mappings:

| Task | Prefer |
| --- | --- |
| Find a dashboard | `search_dashboards`, `get_dashboard_by_uid` |
| Inspect a panel's queries | `get_dashboard_panel_queries` |
| Run PromQL | `query_prometheus`, `list_prometheus_metric_names` |
| Run LogQL | `query_loki_logs`, `list_loki_label_names` |
| Check data sources | `list_datasources`, `check_datasources_health` |
| Alerting | `alerting_manage_rules`, `alerting_manage_silences`, `list_alert_groups` |
| Profiling | `query_pyroscope`, `list_pyroscope_profile_types` |
| Docs lookup | `search_docs`, `get_doc` |
| Anything not covered | `grafana_api_request` |

Rules:

- Read operations (search, query, get) may be run freely to answer a question.
- Write operations (`update_dashboard`, `create_datasource`, `alerting_manage_*`,
  `create_incident`, `delete_snapshot`, `install_plugin`) change a shared instance —
  confirm with the user before calling them, and say which instance (prod vs pre-prod)
  you are about to touch.
- Use `generate_deeplink` to hand the user a clickable dashboard, panel, or Explore link
  instead of describing navigation steps.
- If the MCP server is unavailable, fall back to `references/http-api.md`.

---
# Reference Files
Use these files for structured, reusable guidance:

- [./references/llms-index.md](./references/llms-index.md) - how to use Grafana's official LLM doc index (`grafana.com/llms.txt`)
- [./references/query-languages.md](./references/query-languages.md) - PromQL / LogQL guidance and performance pitfalls
- [./references/dashboard-provisioning-and-json.md](./references/dashboard-provisioning-and-json.md) - dashboard JSON and provisioning workflows
- [./references/alerting.md](./references/alerting.md) - unified alerting workflow and common failure modes
- [./references/http-api.md](./references/http-api.md) - Grafana HTTP API entry points and safe implementation patterns
- [./references/examples.md](./references/examples.md) - worked examples for the tasks above
---

# How to work

1. Identify the component involved (dashboard, panel, query, datasource, alert).
2. Consult the official docs before answering when the answer depends on them; prefer current
   features over deprecated ones and note version-specific behaviour.
3. Explain how *and* why, and say how you diagnosed a problem rather than asserting a cause.

**Reviewing a dashboard** — check usability, visualization choice, query cost, units, legends,
thresholds, variables, and transformations.

**Reviewing PromQL/LogQL** — explain the query, validate syntax, flag expensive operations and
cardinality risks, suggest optimisations, and preserve semantics unless told otherwise.

**Creating a dashboard** — pick the visualization that fits the data, then set titles, units,
thresholds, legends, transformations, variables, and time range deliberately. Add alert rules
where they earn their place. Avoid visual clutter, duplicated queries, and unnecessary
transformations.

**Troubleshooting** — work through datasource connectivity, query correctness, variables,
transformations, field overrides, permissions, time range, and panel/alert configuration.

Always recommend the simplest maintainable solution and state the trade-offs.
