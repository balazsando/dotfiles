---
name: micrometer
description: "JVM metrics and tracing with Micrometer, and its Spring Boot 4 wiring: MeterRegistry, Counters, Timers, Gauges, DistributionSummary, LongTaskTimer, naming, tags and cardinality, MeterFilter, the Observation API, SimpleMeterRegistry tests, Actuator, auto vs custom instrumentation, Boot Micrometer/OTLP starters, Prometheus scrape, and span outcomes."
argument-hint: "the meter, observation, registry, or Spring Boot instrumentation change"
---

# Micrometer

Vendor-neutral JVM observability facade — SLF4J for metrics (and, via Observation, for
metrics plus traces). Instrument once; pick the registry last.

Source of truth: https://docs.micrometer.io/micrometer/reference/

- [references/observation.md](references/observation.md) — handlers, conventions, outcomes.
- [references/spring-boot.md](references/spring-boot.md) — Boot 4 starters, Actuator,
  auto-instrumentation, what gets a custom observation. Read it in a Spring Boot service.

PromQL and dashboards are `grafana`.

## Project first

Observation names, meter names, tag vocabulary, placement, and meter style in the project
override this skill. Keep its style (`ObservationRegistry` vs `MeterRegistry` / `Timer.Sample` /
`@Timed`); introduce Observation beside meters only when a span is required and the project has
no other span API. Never add a second registry, metric style, or tracing stack beside the one it
already publishes. Check existing auto-instrumentation before adding any of your own.

## Which primitive

A meter is identified by **name + tags**. Recording must be cheap and must not throw. One meter
per signal — no Counter beside a Timer or Summary that already records the same events.

| Need | Use |
| --- | --- |
| Short-duration latency and its rate | `Timer` — never a `DistributionSummary` for time |
| Count of events with no duration | `Counter` |
| Current value (queue depth, heap, in-flight gauge) | `Gauge` / `TimeGauge` / `MultiGauge` |
| Distribution of magnitudes that are not time (payload size) | `DistributionSummary` |
| Work still running | `LongTaskTimer` |
| Wrap a monotonically increasing function you do not own | `FunctionCounter` / `FunctionTimer` |

Default custom Observation (metrics and a span from one lifecycle):

```java
Observation.createNotStarted("orders.process", observationRegistry)
    .lowCardinalityKeyValue("operation", "process")
    .observe(() -> processOrder(order));
```

`observe(...)` does start/scope/error/stop, including when the callback throws. Use
`openScope()` with `try`/`catch`/`finally` only when the result must be inspected: call
`observation.error(exception)` before rethrowing, then `stop()` exactly once.

`Timer.Sample` when tags depend on the result:

```java
Timer.Sample sample = Timer.start(registry);
Response response = call();
sample.stop(Timer.builder("http.client.requests")
    .tag("status", statusClass(response))
    .register(registry));
```

## Naming and tags

Lowercase words separated by `.`. Each registry's `NamingConvention` maps that to the
backend (`http.server.requests` → Prometheus `http_server_requests_duration_seconds`).
Override with `registry.config().namingConvention(...)` only when the project already does.

The **name** must be a useful pivot on its own (`database.calls` + tag `db`, not a shared
`calls` meter sliced only by `class`). Tag keys use the same dotted lowercase form.

Tag values are non-null. Bound every value that can come from input: user ids, request ids,
raw URLs, exception messages, tokens, payloads, and unbounded URI paths (map 404s to
`NOT_FOUND`) must never be metric tags. High-cardinality values belong on traces only, as
Observation high-cardinality key values — only low-cardinality key values become metric tags.
Put names and default tags in an `ObservationConvention` so instrumentation code does not own
the naming.

Common tags (`stack`, `region`, `instance`) go on the registry **before** binders; further
`commonTags` calls append:

```java
registry.config().commonTags("stack", "prod", "region", "us-east-1");
```

## Registries

`SimpleMeterRegistry` in tests. Production: the project's existing registry, or the
implementation docs at https://docs.micrometer.io/micrometer/reference/implementations.html
(Prometheus, OTLP, and the rest). `CompositeMeterRegistry` when more than one backend must
receive the same meters.
