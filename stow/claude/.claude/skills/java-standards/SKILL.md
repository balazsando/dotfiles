---
name: java-standards
description: "House standards for Java, Spring, and Maven. Load before writing or changing Java code or build files — dependency injection, class design and separation of concerns, Java 21 usage, Lombok, nullability, test structure, dependency management, formatting. Project conventions override it."
argument-hint: "Optional: the class, module, or pom to apply the standards to"
---

# Java Standards

House rules for Java work. Depth lives elsewhere: `clean-code` for naming and function-level
smells, `design-patterns` for structural choices, `atdd-java` for acceptance tests. This file is
what those skills do not cover — the conventions specific to this machine's projects.

## Dependency injection

- Constructor injection by default; dependency fields `final` wherever the compiler allows.
- No `@Autowired` on a class's single constructor.
- Field and setter injection only when a framework genuinely requires it.
- Declare a bean with a stereotype — `@Component`, `@Service`, `@Repository`, `@RestController` —
  not a `@Configuration` + `@Bean` pair. Keep `@Bean` for types you do not own or cannot annotate.
- Exception: in a hexagonal project the application layer stays framework-free. Those services
  carry no stereotype; declare them as `@Bean` from a `@Configuration` in the infrastructure layer.

## Class design

- SOLID, DRY, YAGNI, KISS. Small, cohesive, domain-named classes; no god classes.
- Keep business logic out of infrastructure and infrastructure out of domain models — no
  persistence, HTTP, or framework annotations on a domain type.
- Prefer clear layering even in small projects, and keep the boundaries enforceable.
- Identify the right layer before changing anything; do not introduce new architecture unless the
  change justifies it.

## Writing the code

- Java 21+ features when they improve readability, safety, or maintainability — not for their own
  sake. Explicit logic and predictable control flow beat clever functional chains.
- Prefer early returns over deep nesting. One empty line before a `return` or `throw`, unless it
  is the only statement in its block.
- No hidden side effects, no premature optimisation, no abstraction without a second caller.
- Lombok is required for boilerplate — getters, setters, constructors, builders,
  `equals`/`hashCode`. Hand-written boilerplate is a defect; a `record` has none to remove. It
  must never hide behaviour or complex logic.
- One operation per line, two at most. Name an intermediate variable instead of stacking calls —
  low cognitive load is what the rest of this section is for.
- Javadoc on public API only, and only where the signature is not enough — contracts, thrown
  exceptions, units, nullability. None on private or self-explanatory members, no `@param` that
  repeats the parameter name.
- Preserve existing behaviour unless the task says otherwise; refactor incrementally and remove
  duplication only when it is safe.

## Nullability

- `@NotNull` for non-null contracts, `@Nullable` only where null is genuinely allowed.
- `Optional` to model absence in return types. Never leave nullability ambiguous.

## Tests

- Test observable behaviour, not implementation details. Mock external dependencies only.
- Unit-test business logic, integration-test adapters. POJOs, configuration classes and
  straightforward delegation get no test at all.
- Name a unit test `test<MethodUnderTest>` plus the case when one method has several:
  `testApplyDiscount`, `testApplyDiscountExpiredCoupon`.
- The instance under test is called `underTest`.
- Given / when / then structure, each part marked with a `// given`, `// when`, `// then` comment;
  parameterise when several inputs prove the same behaviour.
- Prefer test-first iterations: failing test → minimal implementation → refactor.
- Keep tests deterministic and readable; past those markers, a test that needs a comment to be
  understood is a smell.

## Maven

- Shared versions in the parent's `dependencyManagement`; never repeat a version in a child module.
- Align versions across modules, avoid unnecessary transitives, and respect scope separation
  (`compile`, `test`, `provided`, `optional`).

## Formatting

- Eclipse formatter: `./formatter.xml` when the project has one, otherwise `~/.java/formatter.xml`.
- LF line endings. Never hand-reformat code the formatter owns, and never reformat lines the change
  does not otherwise touch.
