# Spring Boot 4 wiring

The Boot layer around Micrometer: starters, Actuator, auto-instrumentation, and where custom
work belongs in a Spring service.

## Baseline

Confirm Spring Boot 4. Follow the project's BOM; do not pin versions the BOM already manages.
Read the project's current properties before changing exposure or export.

- Metrics: `spring-boot-starter-micrometer-metrics` when the project is not already pulling
  Micrometer through Actuator or another starter it uses.
- Tracing/OTLP: `spring-boot-starter-opentelemetry` (Spring's Micrometer + OTLP support).
  Never `io.opentelemetry.instrumentation:opentelemetry-spring-boot-starter`, `@WithSpan`, or
  `otel.*` configuration — those are a different stack.
- Prometheus scrape: `io.micrometer:micrometer-registry-prometheus`. Expose
  `/actuator/prometheus` with `management.endpoints.web.exposure` and
  `management.endpoint.prometheus.access` (not `management.endpoint.prometheus.enabled`).
- Common tags: `management.metrics.tags.*` or a `MeterRegistryCustomizer` bean.

## Custom vs automatic

Spring MVC/WebFlux, `RestClient`/`RestTemplate`/`WebClient`, data access, messaging, and
schedulers already emit duration and outcome when those starters are on the classpath.

| Already covered | Action |
| --- | --- |
| HTTP server/client, repository, listener, or scheduler already has a useful span/timer | No custom observation. No `@Observed`/`@Timed` just to rename it. |
| Costly or important application operation with no useful auto signal | One custom observation at that operation boundary — not around helpers. |
| Duration/outcome needed, span not needed | `Timer` or `Counter` only. |

One observation per operation; nested spans for implementation details are noise. If auto and
custom both fire for the same work, remove the duplicate or disable one source
(`ObservationPredicate` or `management.*.observations`).

`@Observed` / `@Timed` / `@Counted` need `management.observations.annotations.enabled=true` and
`spring-boot-starter-aspectj`. Prefer `ObservationRegistry` in code unless the project already
uses the annotations.

## Outcomes

Rules are in `observation.md`. If you own an OpenTelemetry `Span`, set `StatusCode.OK` after
success is known and before `end()`; Micrometer's OpenTelemetry bridge sets `OK` when a
still-`UNSET` span ends.

## Tests

Cover success vs failure of the instrumented operation (and a returned business rejection if it
changes metrics) where the project can assert it. Prefer the project's test utilities, or
`spring-boot-starter-micrometer-metrics-test`.

References:

- https://docs.spring.io/spring-boot/reference/actuator/observability.html
- https://docs.spring.io/spring-boot/reference/actuator/tracing.html
