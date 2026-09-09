---
name: atdd
description: "ATDD/BDD with Gherkin feature files and executable specifications — the outside-in cycle, step definitions, hooks, tag filtering, DataTables and DocStrings. Java/Cucumber and Go/Godog wiring in references/. Use when adding feature, API, or domain acceptance tests."
argument-hint: "Describe the feature or acceptance test to implement (e.g., 'add feature for user login', 'test REST API', 'add ATDD to an existing service')"
---

# ATDD with Gherkin

Language-neutral here. Wiring, step-definition syntax, hooks and test doubles per language:

- `references/java.md` — Cucumber-JVM: Maven/Gradle, JUnit 5/4 runner, PicoContainer/Spring DI,
  WireMock, RestAssured, Testcontainers.
- `references/go.md` — Godog: `godog.TestSuite`, `context.Context` state, `httptest`, testify.
- `references/gherkin.md` — full Gherkin syntax, step matching, DataTables, DocStrings.
- `assets/feature.template` — skeleton for a new `.feature` file.

## When to Use

- Starting a feature with an outside-in acceptance test first (red-green-refactor)
- Writing `.feature` files as executable specifications
- Implementing `Given`/`When`/`Then` step definitions
- Wiring the Cucumber/Godog suite into the project's test runner
- Setting up per-scenario and suite-level hooks
- Filtering scenarios with tag expressions
- Testing REST APIs, domain services, or database interactions

## Core Concepts

| Term | Meaning |
|------|---------|
| Feature | A `.feature` file describing one capability in Gherkin |
| Scenario | A concrete example of behaviour |
| Step | A `Given`/`When`/`Then`/`And`/`But` line mapped to a function or method |
| Step Definition | The code matched to a step by expression or regex |
| Glue / Initializer | Where the runner finds step definitions and hooks |
| Scenario state | Data threaded between steps — fresh per scenario, never global |

## ATDD Cycle

```
1. Write .feature file  (acceptance criterion — RED)
2. Run tests            → steps are undefined/pending
3. Scaffold step defs   (copy the snippets the runner prints)
4. Implement step logic → steps fail with assertion errors
5. Implement production code to make steps pass (GREEN)
6. Refactor            → re-run, all green
7. Repeat for next scenario
```

Feature file first, always. A scenario written after the code describes what was built, not what
was asked for.

## Step 1 — Write the Feature File

Full syntax: `references/gherkin.md`.

```gherkin
Feature: Fetch issue
  In order to plan work
  As a developer
  I need to fetch an issue by key

  Scenario: Fetch an existing issue
    Given an issue "PROJ-1" exists with summary "Fix login bug"
    When I fetch issue "PROJ-1"
    Then I should see the summary "Fix login bug"

  Scenario: Fetch a non-existent issue
    Given no issue "PROJ-999" exists
    When I fetch issue "PROJ-999"
    Then I should receive a not-found error
```

## Step 2 — Wire the Runner

Once per project; skip it where the suite already runs. Dependencies, runner and layout:
`references/java.md` or `references/go.md`.

## Step 3 — Scaffold Step Definitions

Run the suite once — the runner prints snippets for every undefined step. Implement them against
an **interface**, never a concrete external client: that seam is what the acceptance test swaps.

## Step 4 — Scenario State

Every scenario starts clean and must pass in any order, alone or in parallel. State lives in a
per-scenario carrier — an injected state object (Java) or `context.Context` (Go). Never a static
field, package-level variable, or shared singleton.

## Step 5 — Hooks

Per-scenario hooks reset state and inject test doubles; the after-hook captures failure evidence.
Suite-level hooks own the expensive resources (server, container, DB) started once. Prefer
`Background:` for setup a business reader should see; use hooks for technical setup.

## Step Matching

Match on intent, and keep the pattern as specific as the step text allows — two patterns that both
match give an ambiguous-step error. Prefer the framework's expression syntax over regex where it
exists, and reach for regex only when the match is genuinely complex.

## Tags

House policy: `@wip` marks work in progress and CI runs `not @wip`; `@smoke` marks the fast subset.
Tags are inherited — a tag on `Feature:` applies to every scenario in it. Placement, inheritance
and expression operators: `references/gherkin.md`.

Gate scenarios that need an unavailable environment on a tag (`@e2e`) plus an env-var check in the
before-hook, so a missing environment skips rather than fails.

## Quality Gates

- [ ] Feature file written before production code (red first)
- [ ] Scenarios readable by a non-engineer — intent, not mechanics
- [ ] State per scenario only — no static or package-level state
- [ ] Each scenario independent and order-free
- [ ] Mocks/fakes for every external dependency (HTTP, DB, queues)
- [ ] `@wip` and `@smoke` applied consistently; CI filters `not @wip`
- [ ] Assertions use the test library, never printed output
- [ ] After-hook captures failure evidence (state dump, logs, screenshot)

## References

- [Gherkin syntax](./references/gherkin.md)
- [Java / Cucumber-JVM](./references/java.md)
- [Go / Godog](./references/go.md)
- [Feature file skeleton](./assets/feature.template)
- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/)
- [cucumber-jvm](https://github.com/cucumber/cucumber-jvm) · [godog](https://github.com/cucumber/godog)
