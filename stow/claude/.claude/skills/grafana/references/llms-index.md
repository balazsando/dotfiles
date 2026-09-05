# Grafana LLM Documentation Index (`grafana.com/llms.txt`)

Grafana publishes an AI-friendly index of its official documentation pages at:

`https://grafana.com/llms.txt`

## What this file is for

Use `llms.txt` as the primary "map" when you need to answer a Grafana question with high confidence:

1. Identify the Grafana component from the user request (dashboards, panels, variables, alerting, HTTP API, provisioning, etc.).
2. Find the most relevant keywords in `llms.txt`.
3. Open the linked official documentation page(s).
4. Prefer `.md`-rendered documentation pages when available (they are optimized for automated readers).

## How to use it during answers

- If the question is specifically about *how to configure something in Grafana*, consult the official docs page first.
- If the question is ambiguous, ask a clarifying question, then use the index to locate the right configuration section.
- If the official docs do not contain the needed details, only then use community sources.

## Typical keywords

If the user asks about:

- "dashboards / panels / variables / transformations" -> look for dashboard configuration and visualization docs.
- "PromQL / LogQL" -> look for query language docs and examples for the specific datasource.
- "alerting" -> look for unified alerting and notification policy docs.
- "HTTP API" -> look for dashboard/provisioning API reference.
- "provisioning" -> look for dashboards provisioning docs and the provisioning YAML schema.

