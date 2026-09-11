# Observation

One lifecycle, many handlers: metrics, traces, logs. Check existing instrumentation before
adding your own.

## Pieces

| Type | Role |
| --- | --- |
| `ObservationRegistry` | handlers, predicates, filters |
| `Observation` | start, scope, event, error, stop |
| `Observation.Context` | name, low/high cardinality key values, error |
| `ObservationConvention` | name and tags as configuration, not call-site code |
| `ObservationHandler` | reacts to lifecycle (meter, tracing, logging) |
| `ObservationPredicate` / `ObservationFilter` | enable/disable or mutate before handlers |

Convention precedence: caller-supplied, then a matching global convention, then the
instrumentation default.

```java
Observation.createNotStarted(new OrderConvention(), new OrderContext(order), registry)
    .observe(() -> process(order));
```

Low-cardinality key values → metric tags. High-cardinality key values → traces only.

## Default meters

With `DefaultMeterObservationHandler` registered:

- `Timer` `<name>` on stop — low-cardinality tags plus `error` (`none` or exception class)
- `LongTaskTimer` `<name>.active` from start until stop
- `Counter` on `Observation.event` — low-cardinality tags at event time

## Outcomes

- Failure: `observation.error(exception)` then propagate. Span status `ERROR`.
- Success: stop without `error()`. Do not set `ERROR` in an unconditional `finally`.
- Expected business rejection: not `ERROR`. Bounded outcome tag (`accepted` / `rejected`).

## HTTP / messaging libraries

Prefer Micrometer's `SenderContext` / `ReceiverContext` and the matching tracing handlers
so parent-child context propagates on the wire. Details:
https://docs.micrometer.io/micrometer/reference/observation/instrumenting.html
