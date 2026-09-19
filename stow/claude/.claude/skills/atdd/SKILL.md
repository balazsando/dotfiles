---
name: atdd
description: "ATDD/BDD with Gherkin feature files and executable specifications — step definitions, scenario state, hooks, tag filtering, DataTables and DocStrings. Java/Cucumber and Go/Godog wiring in references/. Use when adding feature, API, or domain acceptance tests."
argument-hint: "Describe the feature or acceptance test to implement (e.g., 'add feature for user login', 'test REST API', 'add ATDD to an existing service')"
---

# ATDD with Gherkin

Language-neutral here. Wiring, step-definition syntax, hooks and test doubles per language:

- `references/java.md` — Cucumber-JVM: Maven/Gradle, JUnit 5/4 runner, PicoContainer/Spring DI,
  WireMock, RestAssured, Testcontainers.
- `references/go.md` — Godog: `godog.TestSuite`, `context.Context` state, `httptest`, testify.
- `references/gherkin.md` — full Gherkin syntax, step matching, DataTables, DocStrings.
- `assets/feature.template` — skeleton for a new `.feature` file.

## Feature file

One capability per `.feature` file; scenarios state intent a non-engineer can read, not
mechanics. Full syntax: `references/gherkin.md`.

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

## Runner

Once per project; skip it where the suite already runs. Dependencies, runner and layout:
`references/java.md` or `references/go.md`.

## Step definitions

Run the suite once — the runner prints snippets for every undefined step. Implement them against
an **interface**, never a concrete external client: that seam is what the acceptance test swaps.
Every external dependency (HTTP, DB, queues) gets a fake or mock; assertions use the test
library, never printed output.

## Scenario state

Every scenario starts clean and must pass in any order, alone or in parallel. State lives in a
per-scenario carrier — an injected state object (Java) or `context.Context` (Go). Never a static
field, package-level variable, or shared singleton.

## Hooks

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

## External

- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/)
- [cucumber-jvm](https://github.com/cucumber/cucumber-jvm) · [godog](https://github.com/cucumber/godog)
