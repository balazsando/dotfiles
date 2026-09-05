---
name: atdd-java
description: "ATDD (Acceptance Test-Driven Development) skill for Java using Cucumber/Gherkin. Use when writing feature files, defining @Given/@When/@Then step definitions, wiring up Cucumber with JUnit 5 or JUnit 4, applying BDD red-green-refactor cycles, using @Before/@After hooks, sharing state between steps, filtering scenarios with tags, testing HTTP APIs or domain services, using DataTables and DocStrings, or adding ATDD to an existing Java/Maven/Gradle project."
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

## Installation

### Maven

```xml
<properties>
  <cucumber.version>7.22.0</cucumber.version>
</properties>

<dependencies>
  <!-- Core -->
  <dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-java</artifactId>
    <version>${cucumber.version}</version>
    <scope>test</scope>
  </dependency>

  <!-- JUnit 5 runner (recommended) -->
  <dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-junit-platform-engine</artifactId>
    <version>${cucumber.version}</version>
    <scope>test</scope>
  </dependency>
  <dependency>
    <groupId>org.junit.platform</groupId>
    <artifactId>junit-platform-suite</artifactId>
    <scope>test</scope>
  </dependency>
  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
  </dependency>

  <!-- OR JUnit 4 runner (legacy) -->
  <!-- <dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-junit</artifactId>
    <version>${cucumber.version}</version>
    <scope>test</scope>
  </dependency> -->
</dependencies>
```

### Gradle (Kotlin DSL)

```kotlin
val cucumberVersion = "7.22.0"
dependencies {
    testImplementation("io.cucumber:cucumber-java:$cucumberVersion")
    testImplementation("io.cucumber:cucumber-junit-platform-engine:$cucumberVersion")
    testImplementation("org.junit.platform:junit-platform-suite")
    testImplementation("org.junit.jupiter:junit-jupiter")
}
```

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

### JUnit 5 (recommended)

```java
// src/test/java/com/example/runner/RunCucumberTest.java
package com.example.runner;

import org.junit.platform.suite.api.*;

@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("features")
@ConfigurationParameter(key = "cucumber.glue", value = "com.example.steps")
@ConfigurationParameter(key = "cucumber.plugin", value = "pretty, html:target/cucumber.html")
public class RunCucumberTest {}
```

Or use `src/test/resources/junit-platform.properties`:

```properties
cucumber.glue=com.example.steps
cucumber.plugin=pretty, html:target/cucumber.html
cucumber.publish.quiet=true
```

### JUnit 4 (legacy)

```java
@RunWith(Cucumber.class)
@CucumberOptions(
    features = "src/test/resources/features",
    glue = "com.example.steps",
    plugin = {"pretty", "html:target/cucumber.html"},
    tags = "not @wip"
)
public class RunCucumberTest {}
```

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

Cucumber creates a **new instance** of each glue class per scenario. Use a shared state class injected via [PicoContainer](#dependency-injection):

```java
// src/test/java/com/example/steps/IssueState.java
package com.example.steps;

public class IssueState {
    public MockJiraClient mockJira = new MockJiraClient();
    public IssueService service = new IssueService(mockJira);
    public Issue fetchedIssue;
    public Exception fetchError;
}
```

Cucumber-PicoContainer dependency:

```xml
<dependency>
  <groupId>io.cucumber</groupId>
  <artifactId>cucumber-picocontainer</artifactId>
  <version>${cucumber.version}</version>
  <scope>test</scope>
</dependency>
```

Any glue class with a constructor parameter that matches another glue class type gets it injected automatically — no configuration needed.

## Step 5 — Hooks

See [hooks reference](./references/hooks.md) for full patterns.

```java
// src/test/java/com/example/steps/Hooks.java
package com.example.steps;

import io.cucumber.java.Before;
import io.cucumber.java.After;
import io.cucumber.java.BeforeAll;
import io.cucumber.java.AfterAll;
import io.cucumber.java.Scenario;

public class Hooks {

    private final IssueState state;

    public Hooks(IssueState state) {
        this.state = state;
    }

    @BeforeAll
    public static void beforeAll() {
        // Start test server, initialize DB — runs once before all scenarios
    }

    @Before
    public void beforeEach(Scenario scenario) {
        // Reset state before each scenario
        state.fetchedIssue = null;
        state.fetchError = null;
        state.mockJira.reset();
    }

    @After
    public void afterEach(Scenario scenario) {
        if (scenario.isFailed()) {
            // Attach debug info to the report
            scenario.attach("State dump...", "text/plain", "debug");
        }
    }

    @AfterAll
    public static void afterAll() {
        // Tear down server, close DB — runs once after all scenarios
    }
}
```

## Cucumber Expressions vs Regex

Prefer **Cucumber Expressions** (cleaner) over regex unless you need complex matching:

```java
// Cucumber Expression (recommended)
@Given("there are {int} items in the {word} category")
public void thereAreItems(int count, String category) { ... }

// Regex (for complex patterns)
@Given("^there are (\\d+) items?$")
public void thereAreItems(int count) { ... }
```

Built-in parameter types:

| Type | Example step text | Java type |
|------|-------------------|-----------|
| `{int}` | `42` | `int` / `Integer` |
| `{long}` | `9999999999` | `long` |
| `{float}` | `3.14` | `float` |
| `{double}` | `3.14159` | `double` |
| `{word}` | `admin` | `String` |
| `{string}` | `"quoted text"` | `String` |
| `{}` | anything | `String` |

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

```gherkin
@smoke
Feature: Issue management

  @wip
  Scenario: Work in progress
    Given ...

  @regression @critical
  Scenario: Must-pass regression
    Given ...
```

Tag expressions:

| Expression | Effect |
|-----------|--------|
| `@smoke` | Only tagged `@smoke` |
| `not @wip` | Exclude `@wip` |
| `@smoke and @fast` | Both tags |
| `@smoke or @regression` | Either tag |
| `(@smoke or @ui) and not @slow` | Compound |

## DataTables

See [Gherkin reference](./references/gherkin.md#data-tables) for full patterns.

```gherkin
Given the following issues exist:
  | key    | summary         | status |
  | PROJ-1 | Fix login bug   | Open   |
  | PROJ-2 | Add dark mode   | Closed |
```

```java
@Given("the following issues exist:")
public void theFollowingIssuesExist(List<Map<String, String>> rows) {
    for (var row : rows) {
        state.mockJira.stubIssue(row.get("key"), row.get("summary"), row.get("status"));
    }
}
```

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

## Dependency Injection Options

| Library | When to use |
|---------|-------------|
| PicoContainer (`cucumber-picocontainer`) | Zero-config, constructor injection — default choice |
| Spring (`cucumber-spring`) | Spring Boot integration tests with `@SpringBootTest` |
| Guice (`cucumber-guice`) | Guice-based applications |
| CDI (`cucumber-cdi2`) | Jakarta EE applications |

See [integration patterns reference](./references/integration.md).

## References

- [Gherkin syntax](./references/gherkin.md)
- [Hooks and lifecycle](./references/hooks.md)
- [Integration and DI patterns](./references/integration.md)
- [Cucumber for Java GitHub (cucumber-jvm)](https://github.com/cucumber/cucumber-jvm)
- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/)
- [Cucumber Java API reference](https://cucumber.io/docs/cucumber/api/?lang=java)
- [cucumber-junit-platform-engine docs](https://github.com/cucumber/cucumber-jvm/tree/main/cucumber-junit-platform-engine)
