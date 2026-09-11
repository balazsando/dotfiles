# Meter types

Builders register as the last step. Prefer `Timer.builder` / `Counter.builder` when you need
description, base unit, or tags; `registry.timer` / `registry.counter` is enough otherwise.

## Timer

Short-duration latencies. Always pass a `TimeUnit` or `Duration`; the registry publishes in
the backend's base unit. Negative values are invalid. Do not use a `DistributionSummary` for
time.

```java
Timer timer = Timer.builder("http.server.requests")
    .description("inbound HTTP")
    .tag("method", "GET")
    .register(registry);

timer.record(() -> handle());
timer.recordCallable(() -> result());
```

`Timer.start(registry)` + `sample.stop(timer)` when tags are known only after the call.
`FunctionTimer` wraps a monotonically increasing count-and-total-time pair you do not own —
never a boxed `Number`, which cannot change.

`@Timed` needs the project's AspectJ/`TimedAspect` setup. Spring Boot: `spring-observability`.

## Counter

Positive increments only. Alert and graph the **rate**, not the absolute count.

```java
Counter.builder("queue.published")
    .baseUnit("messages")
    .tag("destination", "orders")
    .register(registry)
    .increment();
```

`FunctionCounter` wraps a monotonically increasing function (cache eviction count). Same
immutability warning as `FunctionTimer`.

## Gauge

Current value. The registry holds a **weak** reference to the observed object — keep your
own strong reference or the gauge silently disappears.

```java
AtomicInteger queue = new AtomicInteger();
Gauge.builder("orders.queue.size", queue, AtomicInteger::get)
    .register(registry);
```

Never a Gauge for something you should count or time. `TimeGauge` when the value is a
duration. `MultiGauge` for a set of tagged rows rebuilt together.

## DistributionSummary

Magnitude of events that are not time (payload bytes, batch size).

```java
DistributionSummary.builder("http.request.size")
    .baseUnit("bytes")
    .register(registry)
    .record(bytes);
```

## LongTaskTimer

In-flight work. One sample per running task; it contributes until `stop()`.

```java
LongTaskTimer ltt = LongTaskTimer.builder("job.active").register(registry);
LongTaskTimer.Sample sample = ltt.start();
try {
    runJob();
} finally {
    sample.stop();
}
```

## MeterFilter

Applied in order on `registry.config()`: deny/accept registration, transform ids, configure
distribution statistics.

```java
registry.config()
    .meterFilter(MeterFilter.ignoreTags("too.much.information"))
    .meterFilter(MeterFilter.denyNameStartsWith("jvm"))
    .meterFilter(MeterFilter.maximumAllowableTags("http.server.requests", "uri", 100,
        MeterFilter.deny()));
```

`map` filters must be static (depend only on the `Meter.Id`). Dynamic tags belong in the
instrumentation or an `ObservationFilter`. Convenience: `commonTags`, `replaceTagValues`,
`denyUnless`, `forMeters(predicate, delegate)`. Distribution: merge a partial
`DistributionStatisticConfig` (percentiles, SLOs, histogram bounds) with the incoming config.

## Tests

```java
SimpleMeterRegistry registry = new SimpleMeterRegistry();
// …exercise code that records against this registry…
assertThat(registry.get("http.server.requests").tag("status", "2xx").timer().count())
    .isEqualTo(1);
```

`io.micrometer:micrometer-test` when the project already uses it. Spring Boot test starter
is `spring-observability`.
