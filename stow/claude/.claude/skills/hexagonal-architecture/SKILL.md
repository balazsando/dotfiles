---
name: hexagonal-architecture
description: "Hexagonal Architecture (Ports and Adapters) for Java/Spring services — the inward dependency rule, package layout, where ports belong, what adapters own, and how to test each ring. Load when designing, implementing, refactoring, or reviewing domain logic, application services, REST/messaging adapters, or external integrations. Project conventions override it."
argument-hint: "Optional: the module, class, or boundary to apply it to"
---

# Hexagonal Architecture

Business rules stay independent of the framework, transport, persistence, and any external
API. Dependencies point inward only:

```text
adapters → application → domain
```

Class shape, injection, and Lombok rules come from `java-standards`; structural pattern
choices from `design-patterns`. This skill owns only the boundaries.

## Package layout

```text
<root>.<module>
├── domain/                  plain Java: concepts, rules, value objects, domain services
├── application/
│   ├── ports/in/            use-case interfaces the driving adapters call
│   ├── ports/out/           capabilities the use cases need from outside
│   └── service/             use-case orchestration and application policy
├── adapters/
│   ├── in/                  REST controllers, message listeners, schedulers, CLI
│   └── out/                 HTTP/GraphQL clients, producers, persistence
└── infrastructure/
    └── configuration/       bean wiring, properties, technical policy
```

- `domain` imports nothing but the JDK and domain-owned types — no framework, transport,
  persistence, or client-library types, and no annotations from them.
- A port lives with the application, not the adapter: the application declares what it
  needs, the adapter satisfies it.
- Name an outbound port for the need (`StockPort`), the adapter for the technology
  (`HttpStockClient`). A port named after its technology is a leaked boundary.
- A shared `common` module may hold domain primitives and cross-cutting types; it must not
  depend on deployable modules.

## Implementation rules

1. Identify the use case and the domain rule before choosing framework or transport types.
2. Put a port at every boundary where application behaviour needs an external capability.
3. Keep protocol DTOs, headers, serialization, retries, auth, and client errors inside
   adapters. Map at the adapter boundary in both directions.
4. Never pass an HTTP, messaging, persistence, or framework type inward. Translate external
   errors into application or domain failures at the edge.
5. Application services orchestrate, validate, and sequence — no transport or client detail,
   no infrastructure imports.
6. Constructor injection only, dependencies `final`; no `@Autowired` on a single constructor.
7. Prefer plain classes, records, and enums in the domain over framework annotations.
8. Do not add an interface for a single implementation unless it is a real boundary or a
   second implementation is imminent.
9. Prefer composition and the simplest design; do not force a pattern to satisfy the shape.

## Testing

- Domain rules and application services: no Spring context, fakes at the outbound ports.
- Acceptance scenarios: drive through the inbound port or a thin adapter; replace external
  systems at the outbound ports (see `atdd`).
- Adapters: tested separately for mapping, serialization, protocol, and auth behaviour.
- A test that needs the whole context to exercise a business rule is a signal the rule
  escaped the domain.

## Review checklist

- [ ] Dependencies point inward only.
- [ ] Domain has no framework or infrastructure imports.
- [ ] Application code depends on ports, never on a client or template directly.
- [ ] Adapters own mapping, protocol, and error translation.
- [ ] Ports named for the need; adapters named for the technology.
- [ ] Constructor injection throughout, dependencies `final`.
- [ ] Each behaviour tested at the ring that owns it.

When an existing module cannot follow this, document the exception and its migration path
rather than silently reversing a dependency direction.
