---
name: spring-observability
description: "Spring Boot 4 observability wiring: Actuator, auto vs custom instrumentation, Boot Micrometer/OTLP starters, Prometheus scrape, annotation properties, and span outcomes in a Spring service. Meter types, naming, tags, and the Observation API are the micrometer skill."
argument-hint: "Describe the Spring Boot operation, request, or instrumentation diff"
---

# Spring Boot observability

Load `micrometer` first for meter types, naming, tags, `MeterFilter`, and the Observation
API. This skill is the Boot 4 layer around that: starters, Actuator, auto-instrumentation,
and where custom work belongs in a Spring service.

Limit the change to operation performance, profiling, and request success/failure rates.

**Project first.** Observation names, meter names, tag vocabulary, placement, and test
style in the consuming project override this skill. Do not add a second tracing stack, a
second metric style, or spans in a layer the project forbids.

## Baseline (Boot 4)

Confirm Spring Boot 4. Follow the project's BOM; do not pin versions the BOM already
manages.

- Metrics: `spring-boot-starter-micrometer-metrics` when the project is not already pulling
  Micrometer through Actuator or another starter it uses.
- Tracing/OTLP: `spring-boot-starter-opentelemetry` (Spring's Micrometer + OTLP support).
  Do not add `io.opentelemetry.instrumentation:opentelemetry-spring-boot-starter`,
  `@WithSpan`, or `otel.*` configuration — those are a different stack.
- Prometheus scrape: `io.micrometer:micrometer-registry-prometheus`. Expose
  `/actuator/prometheus` with Boot 4 `management.endpoints.web.exposure` and
  `management.endpoint.prometheus.access` (not `management.endpoint.prometheus.enabled`).

Read the project's current properties before changing exposure or export.

Common tags: Boot `management.metrics.tags.*` or a `MeterRegistryCustomizer` bean — before
binders. See `micrometer` for the registry-level API.

## Custom vs automatic

Inspect existing auto-instrumentation first. Spring MVC/WebFlux, `RestClient`/`RestTemplate`/
`WebClient`, data access, messaging, and schedulers already emit duration and outcome when
those starters are on the classpath.

| Already covered | Action |
| --- | --- |
| HTTP server/client, repository, listener, or scheduler already has a useful span/timer | Do not add a custom observation. Do not `@Observed`/`@Timed` it to rename it. |
| Costly or important application operation with no useful auto signal | One custom observation at that operation boundary — not around helpers. |
| Duration/outcome needed, span not needed | `Timer` or `Counter` only, matching the project's existing meter style. |

One observation per operation. Nested spans for implementation details are noise. If both
auto and custom fire for the same work, remove the duplicate or disable one source
(`ObservationPredicate` or `management.*.observations`).

`@Observed` / `@Timed` / `@Counted` require `management.observations.annotations.enabled=true`
and `spring-boot-starter-aspectj`. Prefer `ObservationRegistry` in code unless the project
already uses those annotations.

If the project already instruments with `MeterRegistry` / `Timer.Sample` / `@Timed`, keep
that style. Do not introduce Observation beside it unless a span is required and the project
has no other span API.

## Outcomes

Known outcomes must be represented. Do not mark successful work `ERROR`. Do not leave a
known failure `UNSET`. Rules for `observation.error`, business-rejection tags, and
cardinality are in `micrometer`.

If you own an OpenTelemetry `Span`, set `StatusCode.OK` after success is known and before
`end()`. Micrometer's OpenTelemetry bridge sets `OK` when a still-`UNSET` span ends.

## Tests

Where the project can assert it, cover at least success vs failure of the instrumented
operation (and a returned business rejection if it changes metrics). Prefer the project's
test utilities, or Boot 4 `spring-boot-starter-micrometer-metrics-test`. Do not add tests
this skill cannot run in the consuming repo.

## Review checklist

- [ ] Project conventions (placement, names, meter style) were followed over this skill.
- [ ] Boot 4 starters and properties only; no community OTel starter, `@WithSpan`, or
      `otel.*`.
- [ ] Auto-instrumentation was checked; no duplicate noisy span or meter.
- [ ] Custom work is one costly or important operation, not helpers.
- [ ] Tags are low cardinality; span attributes are meaningful (`micrometer`).
- [ ] Success, expected rejection, and failure are distinguishable; span status matches
      the known outcome.
- [ ] Tests cover success vs failure of that operation where practical.

Authoritative references:

- https://docs.spring.io/spring-boot/reference/actuator/observability.html
- https://docs.spring.io/spring-boot/reference/actuator/tracing.html
- https://docs.micrometer.io/micrometer/reference/
