---
name: design-patterns
description: "Choosing, applying, or reviewing GoF and enterprise design patterns — Strategy, Factory, Observer, Repository, Unit of Work and the rest — refactoring toward a pattern, and evaluating architectural structure. Java 21 idioms; prefers the simplest solution and composition over inheritance."
argument-hint: "problem description, codebase area, or pattern name to evaluate"
---

# Design Patterns Skill

## Objective

Apply design patterns only when they provide a clear benefit. Prefer the simplest solution that satisfies the requirements.

## Guidelines

1. Analyze whether a design pattern is appropriate. Do **not** force one.
2. If no pattern adds value, explicitly state that and implement the simplest maintainable solution.
3. When recommending a pattern:
   - Explain why it fits the problem.
   - Describe the trade-offs.
   - Mention viable alternatives and why they were not chosen.
   - Provide an idiomatic Java 21 implementation.
   - Follow SOLID principles.
   - Prefer composition over inheritance.
   - Integrate with the existing codebase instead of introducing unnecessary abstractions.
4. Avoid overengineering and speculative abstractions.
5. Use established terminology from the Gang of Four (GoF) and Enterprise Application Architecture.

## Primary References

Use these as the canonical references, in priority order:

1. Refactoring.Guru (GoF patterns)
   https://refactoring.guru/design-patterns

2. Martin Fowler – Patterns of Enterprise Application Architecture
   https://martinfowler.com/eaaCatalog/

3. SourceMaking – Design Patterns
   https://sourcemaking.com/design_patterns

If the references differ:
- Prefer Refactoring.Guru for classic GoF patterns.
- Prefer Martin Fowler for enterprise application patterns.

## When to Use

- Designing or refactoring a component where multiple implementations, extension points, or decoupling are required
- Reviewing code for unnecessary pattern complexity or missing abstraction at a real variation point
- Choosing between GoF creational, structural, or behavioral patterns
- Applying enterprise patterns (Repository, Unit of Work, Data Mapper, Service Layer, etc.) in layered applications
- Explaining why a pattern should **not** be applied

## Workflow

### 1. Understand the Problem

Before naming a pattern:

- Identify the **variation point** (what changes vs. what stays stable)
- Count concrete cases today and realistically expected soon (YAGNI)
- Read surrounding code for existing conventions — match them
- Confirm constraints: framework, testability, team familiarity, performance

### 2. Decide — Pattern or Simplicity?

Use this decision order:

1. Can a plain function, record, or single class solve it? → **No pattern**
2. Is the variation real and already present (≥2 implementations or a clear near-term second)? → Consider pattern
3. Does the framework already provide the abstraction (Spring `@Bean`, JPA repositories, etc.)? → **Use framework, don't reinvent**
4. Would the pattern obscure more than it clarifies? → **No pattern**

If no pattern adds value, say so explicitly and proceed with the simplest maintainable solution.

### 3. Select and Justify

When a pattern fits, document:

| Field | Content |
|-------|---------|
| Pattern | GoF or Fowler name |
| Problem | What forces make this pattern appropriate |
| Why this pattern | Mapping from forces to pattern intent |
| Trade-offs | Complexity, indirection, test cost, runtime cost |
| Alternatives rejected | e.g. inheritance, switch statements, inline duplication — and why |
| Integration | How it fits existing packages, DI, and naming |

Consult [patterns.md](./references/patterns.md) for quick applicability notes.

### 4. Implement (Java 21)

- Constructor injection; `final` dependencies
- Composition over inheritance; favor interfaces at variation boundaries
- Use records for immutable value objects and DTOs
- Use sealed types when a closed hierarchy is intentional
- Use `switch` pattern matching where it replaces fragile `instanceof` chains
- Keep pattern participants small and named by domain, not pattern (`PaymentProcessor` not `PaymentStrategyImpl`)
- Do not introduce interfaces with a single implementation unless a second is imminent and agreed

### 5. Validate

- [ ] The variation point is real, not speculative
- [ ] Simpler alternatives were considered and rejected with reasons
- [ ] Implementation follows project DI, layering, and naming conventions
- [ ] Tests cover behavior at the abstraction boundary, not pattern plumbing
- [ ] No extra layers, factories, or builders without demonstrated need

## Additional Resources

- Pattern catalog and applicability notes: [patterns.md](./references/patterns.md)
- Code quality baseline: use the `clean-code` skill for naming, functions, and SOLID details
