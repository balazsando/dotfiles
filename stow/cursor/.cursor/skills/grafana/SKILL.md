---
name: grafana
description: Expert guidance for Grafana dashboards, visualizations, queries, alerting, and observability using official Grafana documentation.
argument-hint: What Grafana task do you need help with? (e.g. "create a dashboard variable", "write PromQL", "debug a dashboard", "provision dashboards", "set up alerting", "use Grafana HTTP API")
---

# Grafana Expert

## Purpose

This skill provides expert assistance for all Grafana-related tasks.

Automatically use this skill whenever the user asks about:

- Grafana dashboards
- Panels and visualizations
- Dashboard variables
- Transformations
- Alerting
- Prometheus / PromQL
- Loki / LogQL
- Tempo
- Mimir
- Data sources
- Dashboard JSON
- Dashboard provisioning
- Grafana APIs
- Performance tuning
- Troubleshooting dashboards

---

# Documentation Source

Always use the official Grafana LLM documentation index as the primary source of truth.

Primary documentation:

<https://grafana.com/llms.txt>

This file provides an AI-friendly index of the official Grafana documentation and should be consulted first to locate the relevant documentation pages. Prefer the Markdown (`.md`) versions of documentation pages whenever available, as they are optimized for automated readers. Grafana explicitly publishes these machine-readable indexes for AI tools.

Only use community articles or Stack Overflow if the official documentation does not answer the question.

---
# Reference Files
Use these files for structured, reusable guidance:

- [./references/llms-index.md](./references/llms-index.md) - how to use Grafana's official LLM doc index (`grafana.com/llms.txt`)
- [./references/query-languages.md](./references/query-languages.md) - PromQL / LogQL guidance and performance pitfalls
- [./references/dashboard-provisioning-and-json.md](./references/dashboard-provisioning-and-json.md) - dashboard JSON and provisioning workflows
- [./references/alerting.md](./references/alerting.md) - unified alerting workflow and common failure modes
- [./references/http-api.md](./references/http-api.md) - Grafana HTTP API entry points and safe implementation patterns
---

# Behavior

Always:

1. Determine which Grafana component is involved.
2. Consult the official documentation before answering when documentation is required.
3. Explain both *how* and *why*.
4. Prefer current Grafana features over deprecated ones.
5. Mention version-specific behavior if applicable.
6. Provide production-ready recommendations.

---

# Dashboard Reviews

When reviewing dashboards:

- identify usability issues
- identify visualization issues
- identify inefficient queries
- verify panel units
- verify legends
- verify thresholds
- verify variables
- verify transformations
- suggest improvements

---

# Query Reviews

When reviewing PromQL or LogQL:

- explain the query
- validate syntax
- identify expensive operations
- suggest optimizations
- explain trade-offs
- mention cardinality concerns
- preserve query semantics unless instructed otherwise

---

# Dashboard Creation

When creating dashboards:

- choose the most appropriate visualization
- recommend panel titles
- recommend units
- recommend thresholds
- recommend legends
- recommend transformations
- recommend variables
- recommend time ranges
- recommend alert rules where appropriate

Avoid unnecessary visual clutter.

---

# Troubleshooting

When debugging Grafana issues, systematically verify:

- datasource connectivity
- query correctness
- dashboard variables
- transformations
- field overrides
- permissions
- time range
- panel configuration
- alert configuration

Do not assume the problem without explaining how it was diagnosed.

---

# Best Practices

Prefer:

- official Grafana features
- reusable dashboard variables
- maintainable queries
- readable dashboards
- clear panel naming
- minimal query cost

Avoid:

- deprecated features
- unnecessary transformations
- duplicated queries
- excessive dashboard complexity

Always explain trade-offs and recommend the simplest maintainable solution.
