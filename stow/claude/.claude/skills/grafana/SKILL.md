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

Registered per environment, app and connector: `grafana-test` / `grafana-test-connector`,
`grafana-prep` / `grafana-prep-connector`, `grafana-prod` / `grafana-prod-connector`. Prefer their
tools over hand-rolled HTTP calls.
Each exposes only search, datasource, Prometheus, Loki, dashboard, folder, Tempo and navigation
tools; anything else goes through the Grafana HTTP API.

- Reads (search, query, get, list) run freely.
- Test and prod are read-only (`--disable-write`). Prep stays writable for prototyping
  dashboards — a shared instance, so confirm every write on prep first.
- Hand the user a `generate_deeplink` link instead of describing navigation.

