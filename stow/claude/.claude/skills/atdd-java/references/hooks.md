# Hooks and Lifecycle Reference (Java/Cucumber)

## Execution Order

```
@BeforeAll (static, once per suite)
  └── @Before (per scenario, after Background steps are queued)
        └── Background steps
              └── Scenario steps
                    └── @BeforeStep / @AfterStep (per step)
        └── @After (per scenario, always runs even on failure)
@AfterAll (static, once per suite)
```

## Scenario Hooks

### @Before

Runs before the **first step** of each scenario. Use for resetting state, seeding mocks.

```java
import io.cucumber.java.Before;
import io.cucumber.java.Scenario;

public class Hooks {

    private final AppState state;

    public Hooks(AppState state) {      // PicoContainer injects shared state
        this.state = state;
    }

    @Before
    public void beforeEach() {
        state.reset();
    }

    // With scenario metadata
    @Before
    public void beforeEach(Scenario scenario) {
        System.out.println("Starting: " + scenario.getName());
        state.reset();
    }

    // Ordered execution (lower = first)
    @Before(order = 10)
    public void setupDatabase() { ... }

    @Before(order = 20)
    public void setupMocks() { ... }
}
```

> Prefer `Background:` for setup that should be visible to business readers. Use `@Before` for low-level technical setup (start server, reset DB).

### @After

Runs after the **last step** of each scenario — even when the scenario fails.

```java
@After
public void afterEach(Scenario scenario) {
    if (scenario.isFailed()) {
        // Attach a screenshot, log dump, or state snapshot to the report
        byte[] screenshot = takeScreenshot();
        scenario.attach(screenshot, "image/png", "failure-screenshot");

        // Or attach text
        scenario.attach(state.toString(), "text/plain", "state-dump");
    }
}

@After(order = 100)
public void closeBrowser() {
    if (driver != null) driver.quit();
}
```

### Conditional Hooks (Tag-scoped)

```java
// Only runs for scenarios tagged @browser
@Before("@browser")
public void startBrowser() {
    driver = new ChromeDriver();
}

@After("@browser and not @headless")
public void closeBrowser(Scenario scenario) {
    driver.quit();
}

// Complex tag expressions
@Before("@database or @integration")
public void seedDatabase() { ... }
```

## Global Hooks (Suite-Level)

### @BeforeAll / @AfterAll

Run **once** per suite. Must be `static`.

```java
import io.cucumber.java.BeforeAll;
import io.cucumber.java.AfterAll;

public class SuiteHooks {

    private static MockServer mockServer;

    @BeforeAll
    public static void startMockServer() {
        mockServer = MockServer.start(8080);
    }

    @AfterAll
    public static void stopMockServer() {
        if (mockServer != null) mockServer.stop();
    }
}
```

> With `cucumber-junit-platform-engine`, `@BeforeAll` runs once per JVM by default. With JUnit 4, it's per runner class.

## Step Hooks

### @BeforeStep / @AfterStep

Run before and after **every step**. Use sparingly — noisy in reports.

```java
import io.cucumber.java.BeforeStep;
import io.cucumber.java.AfterStep;

public class StepHooks {

    @BeforeStep
    public void beforeStep(Scenario scenario) {
        // e.g., start timing
    }

    @AfterStep
    public void afterStep(Scenario scenario) {
        // e.g., log step duration, capture screenshot on failure
        if (scenario.isFailed()) {
            scenario.attach("step failed", "text/plain", "step-failure");
        }
    }
}
```

## Sharing State Between Glue Classes

Cucumber creates **new instances of each glue class per scenario** — no static state, no shared singletons.

### Pattern: Shared State Object (PicoContainer)

```java
// AppState.java — plain POJO, no annotations
public class AppState {
    public MockJiraClient mockJira;
    public Issue fetchedIssue;
    public Exception fetchError;

    public void reset() {
        mockJira = new MockJiraClient();
        fetchedIssue = null;
        fetchError = null;
    }
}
```

Any glue class (steps or hooks) that declares `AppState` as a constructor parameter gets the **same instance** within a scenario:

```java
public class IssueSteps {
    private final AppState state;
    public IssueSteps(AppState state) { this.state = state; }
}

public class Hooks {
    private final AppState state;
    public Hooks(AppState state) { this.state = state; }
}
```

No registration required — PicoContainer discovers and injects automatically.

## World Pattern (Self-contained Steps)

For small suites: put all steps and state in a single class.

```java
public class IssueSteps {
    // State lives here — fresh per scenario because Cucumber re-instantiates
    private MockJiraClient mockJira = new MockJiraClient();
    private Issue fetchedIssue;
    private Exception fetchError;

    @Given("a Jira issue {string} exists")
    public void aJiraIssueExists(String key) { ... }

    @Before
    public void reset() {
        mockJira = new MockJiraClient();
        fetchedIssue = null;
        fetchError = null;
    }
}
```

Scale to shared state class once you have more than one step definition file.

## Scenario Object

Available in `@Before`, `@After`, `@BeforeStep`, `@AfterStep` as a parameter.

```java
@After
public void after(Scenario scenario) {
    scenario.getName();           // "Fetch an existing issue"
    scenario.getId();             // "issue-fetch;fetch-an-existing-issue"
    scenario.getStatus();         // PASSED, FAILED, SKIPPED, PENDING, UNDEFINED
    scenario.isFailed();          // boolean
    scenario.getSourceTagNames(); // ["@smoke", "@regression"]

    // Attach data to the Cucumber report
    scenario.attach(bytes, "image/png", "screenshot");
    scenario.attach("text message", "text/plain", "debug-log");
    scenario.log("Step completed at " + Instant.now());
}
```

## cucumber.properties (JUnit 5 configuration)

`src/test/resources/cucumber.properties`:

```properties
cucumber.glue=com.example.steps
cucumber.features=src/test/resources/features
cucumber.plugin=pretty, html:target/cucumber.html, json:target/cucumber.json
cucumber.filter.tags=not @wip
cucumber.execution.order=random
cucumber.publish.quiet=true
```

Or `junit-platform.properties` for JUnit 5:

```properties
cucumber.glue=com.example.steps
cucumber.plugin=pretty, html:target/cucumber.html
cucumber.filter.tags=not @wip
```

## Parallel Execution (JUnit 5)

```properties
# junit-platform.properties
cucumber.execution.parallel.enabled=true
cucumber.execution.parallel.config.strategy=dynamic
```

Scenarios run in parallel. **Each scenario must be fully isolated** — no shared mutable static state. Verify with:

```bash
mvn test -Dcucumber.execution.parallel.enabled=true
```
