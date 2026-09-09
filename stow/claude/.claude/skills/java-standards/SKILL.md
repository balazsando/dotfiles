---
name: java-standards
description: "House standards for Java, Spring, and Maven. Load before writing or changing Java code or build files — the canonical class shape to copy, dependency injection, layering, Java 21 usage, Lombok, nullability, dependency management, formatting. Project conventions override it."
argument-hint: "Optional: the class, module, or pom to apply the standards to"
---

# Java Standards

Copy the class shape from [references/examples.md](./references/examples.md). The rules below
are what an example cannot show. Depth lives elsewhere: `clean-code` for naming and
function-level smells, `design-patterns` for structural choices, `atdd` for acceptance
tests, and [references/tests.md](./references/tests.md) for writing unit tests.

## Rules an example cannot show

**Injection.** Field and setter injection only when a framework genuinely requires it. Keep
`@Bean` for types you do not own or cannot annotate. In a hexagonal project the application layer
stays framework-free: those services carry no stereotype and are declared as `@Bean` from a
`@Configuration` in the infrastructure layer.

**Layering.** Business logic never in infrastructure, infrastructure never in a domain model — no
persistence, HTTP, or framework annotation on a domain type. Identify the right layer before
changing anything; do not introduce new architecture unless the change justifies it.

**Restraint.** SOLID, DRY, YAGNI, KISS. No god classes, no hidden side effects, no premature
optimisation, no abstraction without a second caller. Java 21 features when they improve
readability or safety, not for their own sake — explicit logic beats a clever functional chain.
Preserve existing behaviour unless the task says otherwise; remove duplication only when it is
safe.

**Lombok** is required for boilerplate — getters, setters, constructors, builders,
`equals`/`hashCode`. Hand-written boilerplate is a defect; a `record` has none to remove. It must
never hide behaviour or complex logic.

**Javadoc** on public API only, and only where the signature is not enough — contracts, thrown
exceptions, units, nullability. None on private or self-explanatory members, and no `@param` that
merely repeats the parameter name.

**Nullability.** `@NotNull` for non-null contracts, `@Nullable` only where null is genuinely
allowed, `Optional` to model absence in a return type. Never leave nullability ambiguous.

**Maven.** Shared versions in the parent's `dependencyManagement`; never repeat a version in a
child module. Align versions across modules, avoid unnecessary transitives, and respect scope
separation (`compile`, `test`, `provided`, `optional`).

**Formatting.** The Eclipse formatter owns it: `./formatter.xml` when the project has one,
otherwise `~/.java/formatter.xml` — 4 spaces, 120 columns, LF. Never hand-reformat what the
formatter owns, and never reformat lines the change does not otherwise touch.

## Tests

Writing them: [references/tests.md](./references/tests.md) — the test skeleton to copy, plus what
gets a test at all. Changing production code does not require that depth; writing a test does.
