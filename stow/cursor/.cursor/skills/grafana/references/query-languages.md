# PromQL / LogQL Guidance (and Performance Pitfalls)

This reference covers common patterns you'll encounter when helping with:

- metric queries in Prometheus-compatible datasources (PromQL)
- log filtering and aggregation in Loki-compatible datasources (LogQL)

When answering, preserve semantics: keep the same metric/log selection and only change what is necessary to fix the issue.

---

## PromQL: common building blocks

### Label matchers

Use label matchers to control the exact series:

- equality: `{job="api-server"}`
- regex: `{route=~"/v[0-9]+/.*"}` (powerful but can be expensive)
- negative: `{env!="prod"}`

Prefer equality matchers over regex matchers when you can.

### Range vectors and rates

Most "per-second" rates should use `rate()` (or `irate()` when you truly need instant/high churn):

- `rate(http_requests_total{...}[5m])`

For counters:

- use `rate()` / `increase()` instead of dividing raw counter values

### Aggregation

Use `sum by (...)`, `avg by (...)`, etc. to reduce cardinality:

- `sum by (service) (rate(requests_total{...}[5m]))`

Keep the `by (...)` set minimal (only what you need to display or alert on).

---

## LogQL: common building blocks

### Filtering logs

Start with a selector that narrows scope:

- `{app="payments", level="error"}`

Then apply content filters:

- `|= "timeout"`
- `|~ "timeout|deadline exceeded"` (regex content filter)

Avoid overly broad regex when simple substring filters work.

### Range and aggregation

When you need counts over time, use aggregation over the time window (for example, count-per-window patterns).

---

## Performance checklist (both PromQL + LogQL)

Before suggesting a query change, check:

- Time range: do not require extremely long lookbacks unless necessary.
- Selector selectivity: tighten `{...}` matchers first.
- Avoid high-cardinality grouping: don't `by (...)` on labels with unbounded values.
- Prefer pre-aggregation: if you repeatedly compute the same expression for dashboards/alerts, suggest recording rules (Prometheus) or query-layer aggregation patterns.
- Avoid "regex everywhere": replace with exact matchers where possible.
- Preserve alert semantics: if you modify queries used in alerts, ensure thresholds and "for" durations still make sense.

---

## Troubleshooting flow

When the user says "my query is slow" or "results are wrong", ask for:

1. Datasource type and version (Prometheus/Loki variants)
2. Current query and time range
3. Expected result vs actual result
4. Rough cardinality symptoms (many series, missing labels, etc.)

Then:

- verify selectors first
- adjust aggregation/grouping
- only then adjust math/rates/counts

