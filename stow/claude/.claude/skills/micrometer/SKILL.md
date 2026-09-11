---
name: micrometer
description: "Instrument JVM code with Micrometer: MeterRegistry, Counters, Timers, Gauges, DistributionSummary, LongTaskTimer, naming, tags and cardinality, MeterFilter, Observation API, and SimpleMeterRegistry tests. Not Spring Boot Actuator wiring — that is spring-observability."
argument-hint: "the meter, observation, or registry change"
---

# Micrometer

Vendor-neutral JVM observability facade — SLF4J for metrics (and, via Observation, for
metrics plus traces). Instrument once; pick the registry last.

Source of truth: https://docs.micrometer.io/micrometer/reference/

Spring Boot starters, Actuator exposure, auto-instrumentation, and Boot 4 OTLP wiring are
`spring-observability`. PromQL and dashboards are `grafana`. Project conventions override
this skill.

## Which primitive

A meter is identified by **name + tags**. Recording must be cheap and must not throw.

| Need | Use |
| --- | --- |
| Short-duration latency and its rate | `Timer` — never a `DistributionSummary` for time |
| Count of events with no duration | `Counter` — skip it if a Timer or Summary already records the same events |
| Current value (queue depth, heap, in-flight gauge) | `Gauge` / `TimeGauge` / `MultiGauge` |
| Distribution of magnitudes that are not time (payload size) | `DistributionSummary` |
| Work still running | `LongTaskTimer` |
| Wrap a monotonically increasing function you do not own | `FunctionCounter` / `FunctionTimer` |

One meter per signal. Do not add a Counter beside a Timer for the same operation.

Default custom Observation (metrics and a span from one lifecycle):

```java
Observation.createNotStarted("orders.process", observationRegistry)
    .lowCardinalityKeyValue("operation", "process")
    .observe(() -> processOrder(order));
```

Use `openScope()` with `try`/`catch`/`finally` only when the result must be inspected.
Call `observation.error(exception)` before rethrowing, then `stop()` exactly once.
`observe(...)` does start/scope/error/stop when the callback throws.

`Timer.Sample` when tags depend on the result:

```java
Timer.Sample sample = Timer.start(registry);
Response response = call();
sample.stop(Timer.builder("http.client.requests")
    .tag("status", statusClass(response))
    .register(registry));
```

Keep the project's existing style (`ObservationRegistry` vs `MeterRegistry` / `@Timed`).
Do not introduce Observation beside meters unless a span is required.

Meter builders, gauges, filters, and tests: [references/meters.md](references/meters.md).
Observation handlers and conventions: [references/observation.md](references/observation.md).

## Naming and tags

Lowercase words separated by `.`. Each registry's `NamingConvention` maps that to the
backend (`http.server.requests` → Prometheus `http_server_requests_duration_seconds`).
Override with `registry.config().namingConvention(...)` only when the project already does.

The **name** must be a useful pivot on its own (`database.calls` + tag `db`, not a shared
`calls` meter sliced only by `class`). Tag keys use the same dotted lowercase form.

Tag values are non-null. Bound every value that can come from input: user ids, request ids,
raw URLs, exception messages, tokens, payloads, and unbounded URI paths (map 404s to
`NOT_FOUND`) must never be metric tags. High-cardinality values belong on traces only, as
Observation high-cardinality key values.

Common tags (`stack`, `region`, `instance`) go on the registry **before** binders:

```java
registry.config().commonTags("stack", "prod", "region", "us-east-1");
```

Further `commonTags` calls append.

## Observation cardinality

Only **low-cardinality** key values become metric tags (`DefaultMeterObservationHandler`).
High-cardinality key values stay on the span. Put names and default tags in an
`ObservationConvention` so instrumentation code does not own the naming.

On stop, the handler records a `Timer` tagged with those low-cardinality keys plus `error`
(`none` or the exception class). In-flight work is a `LongTaskTimer` named `<name>.active`.
`Observation.event` increments a `Counter`.

## Registries

`SimpleMeterRegistry` in tests. Production: the project's existing registry, or the
implementation docs at
https://docs.micrometer.io/micrometer/reference/implementations.html
(Prometheus, OTLP, and the rest). `CompositeMeterRegistry` when more than one backend
must receive the same meters.

Do not add a second registry or a second instrumentation stack beside the one the
project already publishes.
