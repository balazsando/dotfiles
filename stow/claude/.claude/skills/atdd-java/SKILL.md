---
name: atdd-java
description: "ATDD/BDD in Java with Cucumber and Gherkin: feature files, @Given/@When/@Then step definitions, JUnit 4/5 wiring, @Before/@After hooks, sharing state between steps, tag filtering, DataTables and DocStrings, and adding acceptance tests to a Maven or Gradle project."
argument-hint: "Describe the feature or acceptance test to implement (e.g., 'add feature for user login', 'test REST API', 'add ATDD to Spring Boot service')"
---

# ATDD in Java with Cucumber

## When to Use

- Starting a new feature with an outside-in acceptance test first (red-green-refactor)
- Writing Gherkin `.feature` files as executable specifications
- Implementing `@Given`/`@When`/`@Then` step definitions in Java
- Wiring Cucumber into JUnit 5 or JUnit 4
- Setting up `@Before`/`@After` hooks for scenario setup/teardown
- Filtering scenarios with tag expressions
- Testing REST APIs, domain services, or database interactions

## Core Concepts

| Term | Meaning |
|------|---------|
| Feature | A `.feature` file describing one capability in Gherkin |
| Scenario | A concrete example of behaviour |
| Step | A `Given`/`When`/`Then`/`And`/`But` line mapped to a Java method |
| Step Definition | Annotated Java method matching a step via expression or regex |
| Glue | The package(s) where Cucumber scans for step definitions and hooks |
| World / State | Instance variables in step-definition classes — new instance per scenario |

## ATDD Cycle

```
1. Write .feature file  (acceptance criterion — RED)
2. Run tests            → steps are undefined/pending
3. Scaffold step defs   (copy snippets from output)
4. Implement step logic → steps fail with assertion errors
5. Implement production code to make steps pass (GREEN)
6. Refactor            → re-run, all green
7. Repeat for next scenario
```

## Project Layout

```
src/
  main/java/com/example/
    IssueService.java           ← production code
  test/
    java/com/example/
      steps/
        IssueSteps.java         ← step definitions
        Hooks.java              ← @Before/@After hooks
      runner/
        RunCucumberTest.java    ← JUnit 5 suite runner
    resources/
      features/
        issue_fetch.feature     ← Gherkin scenarios
      cucumber.properties       ← Cucumber configuration
```

## Step 1 — Write the Feature File

See [Gherkin reference](./references/gherkin.md) for full syntax.

```gherkin
# src/test/resources/features/issue_fetch.feature
Feature: Fetch Jira issue
  In order to plan work
  As a developer
  I need to fetch a Jira issue by key

  Scenario: Fetch an existing issue
    Given a Jira issue "PROJ-1" exists with summary "Fix login bug"
    When I fetch issue "PROJ-1"
    Then I should see the summary "Fix login bug"

  Scenario: Fetch a non-existent issue
    Given no Jira issue "PROJ-999" exists
    When I fetch issue "PROJ-999"
    Then I should receive a not-found error
```

## Step 2 — Wire the Test Runner

Dependencies and the JUnit 5 / JUnit 4 runner: [setup reference](./references/setup.md). Once per
project — skip it in a project that already runs Cucumber.

## Step 3 — Scaffold Step Definitions

Run tests once — Cucumber prints unimplemented snippets. Implement them:

```java
// src/test/java/com/example/steps/IssueSteps.java
package com.example.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static org.assertj.core.api.Assertions.assertThat;

public class IssueSteps {

    private final IssueState state;

    // Cucumber instantiates glue classes per scenario.
    // Inject shared state via constructor (PicoContainer does this automatically).
    public IssueSteps(IssueState state) {
        this.state = state;
    }

    @Given("a Jira issue {string} exists with summary {string}")
    public void aJiraIssueExistsWithSummary(String key, String summary) {
        state.mockJira.stubIssue(key, summary);
    }

    @Given("no Jira issue {string} exists")
    public void noJiraIssueExists(String key) {
        state.mockJira.stubNotFound(key);
    }

    @When("I fetch issue {string}")
    public void iFetchIssue(String key) {
        try {
            state.fetchedIssue = state.service.fetchIssue(key);
        } catch (IssueNotFoundException e) {
            state.fetchError = e;
        }
    }

    @Then("I should see the summary {string}")
    public void iShouldSeeTheSummary(String expected) {
        assertThat(state.fetchedIssue).isNotNull();
        assertThat(state.fetchedIssue.getSummary()).isEqualTo(expected);
    }

    @Then("I should receive a not-found error")
    public void iShouldReceiveANotFoundError() {
        assertThat(state.fetchError).isNotNull()
            .isInstanceOf(IssueNotFoundException.class);
    }
}
```

## Step 4 — Share State Between Steps

Cucumber creates a **new instance** of each glue class per scenario: no static fields, no shared
singletons. Put the scenario's state in a plain object and take it as a constructor parameter —
every glue class that declares it gets the same instance. Pattern and wiring:
[hooks reference](./references/hooks.md#sharing-state-between-glue-classes).

## Step 5 — Hooks

`@Before` resets the state object, `@After` attaches failure evidence when `scenario.isFailed()`,
`@BeforeAll` / `@AfterAll` own the expensive suite-level resources. Tag-scoped hooks, step hooks
and execution order: [hooks reference](./references/hooks.md).

## Step Matching

Prefer **Cucumber Expressions** (`{int}`, `{string}`, `{word}`) over regex; reach for regex only
when the match is genuinely complex. Parameter types, optional text, alternation and custom
`@ParameterType`: [Gherkin reference](./references/gherkin.md#cucumber-expressions-step-matching).

DataTables and DocStrings, and the Java types a table maps to:
[Gherkin reference](./references/gherkin.md#data-tables).

## Running Tests

```bash
# Run all acceptance tests
mvn test

# Run only scenarios tagged @smoke
mvn test -Dcucumber.filter.tags="@smoke"

# Run scenarios NOT tagged @wip
mvn test -Dcucumber.filter.tags="not @wip"

# Run with pretty output
mvn test -Dcucumber.plugin="pretty"

# Dry run (check all steps defined, no execution)
mvn test -Dcucumber.execution.dry-run=true

# Run specific feature file
mvn test -Dcucumber.features="src/test/resources/features/issue_fetch.feature"

# With Gradle
./gradlew test --tests "RunCucumberTest"
```

## Tags

House policy: `@wip` marks work in progress and CI runs `not @wip`; `@smoke` marks the fast
subset. Tag placement, inheritance and the expression operators:
[Gherkin reference](./references/gherkin.md#tags).

## Quality Gates

- [ ] Feature file written before production code (red first)
- [ ] Scenarios are readable by a non-engineer
- [ ] State shared only via injected state object — no static fields
- [ ] Each scenario is independent (reset in `@Before`)
- [ ] Mocks/fakes used for external dependencies (HTTP, DB, queues)
- [ ] `@wip` and `@smoke` tags applied consistently
- [ ] Tests run in CI with `not @wip` filter
- [ ] Assertions use AssertJ or JUnit assertions, not `System.out`
- [ ] `@After` captures failure evidence (screenshot, logs, state dump)

## Dependency Injection

PicoContainer is the default — zero config, constructor injection. Spring, Guice and CDI, with
WireMock, RestAssured and Testcontainers patterns:
[integration reference](./references/integration.md).

## References

- [Setup — dependencies and runner](./references/setup.md)
- [Gherkin syntax](./references/gherkin.md)
- [Hooks and lifecycle](./references/hooks.md)
- [Integration and DI patterns](./references/integration.md)
- [Feature file skeleton](./assets/feature.template) - starting point for a new `.feature` file
- [Cucumber for Java GitHub (cucumber-jvm)](https://github.com/cucumber/cucumber-jvm)
- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/)
- [Cucumber Java API reference](https://cucumber.io/docs/cucumber/api/?lang=java)
- [cucumber-junit-platform-engine docs](https://github.com/cucumber/cucumber-jvm/tree/main/cucumber-junit-platform-engine)
