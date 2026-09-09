# ATDD in Java — Cucumber-JVM

Section order mirrors `go.md`.

## 1. Dependencies

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

Add `cucumber-picocontainer` (same version, test scope) as soon as two glue classes share a state
object — see §5.

## 2. Test runner

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

Or configure in `src/test/resources/junit-platform.properties`:

```properties
cucumber.glue=com.example.steps
cucumber.features=src/test/resources/features
cucumber.plugin=pretty, html:target/cucumber.html, json:target/cucumber.json
cucumber.filter.tags=not @wip
cucumber.execution.order=random
cucumber.publish.quiet=true
```

`cucumber.properties` takes the same keys and is read for both runners.

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

## 3. Project layout

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
      junit-platform.properties ← Cucumber configuration
```

## 4. Step definitions

```java
package com.example.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;
import static org.assertj.core.api.Assertions.assertThat;

public class IssueSteps {

    private final ScenarioState state;

    // Cucumber instantiates glue classes per scenario.
    // Inject shared state via constructor (PicoContainer does this automatically).
    public IssueSteps(ScenarioState state) {
        this.state = state;
    }

    @Given("an issue {string} exists with summary {string}")
    public void anIssueExistsWithSummary(String key, String summary) {
        state.mockIssues.stubIssue(key, summary);
    }

    @Given("no issue {string} exists")
    public void noIssueExists(String key) {
        state.mockIssues.stubNotFound(key);
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

## 5. Sharing state between glue classes

Cucumber creates a **new instance of each glue class per scenario** — no static state, no shared
singletons. Declare the state as a plain class; every glue class that takes it as a constructor
parameter gets the **same instance** within a scenario. PicoContainer discovers and injects it with
no registration.

```java
// ScenarioState.java — plain POJO, no annotations
public class ScenarioState {
    public MockIssueClient mockIssues;
    public Issue fetchedIssue;
    public Exception fetchError;

    public void reset() {
        mockIssues = new MockIssueClient();
        fetchedIssue = null;
        fetchError = null;
    }
}
```

```java
public class IssueSteps {
    private final ScenarioState state;
    public IssueSteps(ScenarioState state) { this.state = state; }
}

public class Hooks {
    private final ScenarioState state;
    public Hooks(ScenarioState state) { this.state = state; }
}
```

**World pattern** — for a suite with one step-definition file, keep state as instance fields of
that class; Cucumber re-instantiates it per scenario. Move to a shared state class as soon as a
second file needs the same data.

### DI options

| Library | Import | When to use |
|---------|--------|-------------|
| PicoContainer | `cucumber-picocontainer` | Zero-config constructor injection; default for non-framework apps |
| Spring | `cucumber-spring` | Spring Boot integration tests; reuse the application context |
| Guice | `cucumber-guice` | Guice-based apps |
| CDI | `cucumber-cdi2` | Jakarta EE / Quarkus |

**Spring** needs exactly one `@CucumberContextConfiguration` class in the glue path, and shared
state beans must be `@Scope("cucumber-glue")`:

```java
@CucumberContextConfiguration
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class ContextConfig { }

@Component
@Scope("cucumber-glue")
public class ScenarioState { public ResponseEntity<?> lastResponse; }

public class ApiSteps {
    @Autowired private TestRestTemplate restTemplate;
    @Autowired private ScenarioState state;

    @When("I GET {string}")
    public void iGet(String path) {
        state.lastResponse = restTemplate.getForEntity(path, String.class);
    }
}
```

## 6. Hooks and lifecycle

```
@BeforeAll (static, once per suite)
  └── @Before (per scenario, before Background steps)
        └── Background steps
              └── Scenario steps
                    └── @BeforeStep / @AfterStep (per step)
        └── @After (per scenario, always runs even on failure)
@AfterAll (static, once per suite)
```

```java
import io.cucumber.java.*;

public class Hooks {

    private final ScenarioState state;
    public Hooks(ScenarioState state) { this.state = state; }

    @Before
    public void beforeEach() { state.reset(); }

    @Before(order = 10)              // lower order runs first
    public void setupDatabase() { ... }

    @Before("@browser")              // tag-scoped; accepts tag expressions
    public void startBrowser() { driver = new ChromeDriver(); }

    @After
    public void afterEach(Scenario scenario) {
        if (scenario.isFailed()) {
            scenario.attach(takeScreenshot(), "image/png", "failure-screenshot");
            scenario.attach(state.toString(), "text/plain", "state-dump");
        }
    }

    @After("@browser and not @headless")
    public void closeBrowser() { driver.quit(); }
}
```

`@BeforeAll` / `@AfterAll` must be `static` and own suite-level resources (stub server, container).
With `cucumber-junit-platform-engine` they run once per JVM; with JUnit 4, once per runner class.

`@BeforeStep` / `@AfterStep` run around every step — useful for timing or per-step evidence, noisy
in reports otherwise.

The `Scenario` object is available in every hook:

```java
scenario.getName();           // "Fetch an existing issue"
scenario.getId();
scenario.getStatus();         // PASSED, FAILED, SKIPPED, PENDING, UNDEFINED
scenario.isFailed();
scenario.getSourceTagNames(); // ["@smoke", "@regression"]
scenario.attach(bytes, "image/png", "screenshot");
scenario.log("Step completed at " + Instant.now());
```

## 7. Test doubles and integration

### Interface-based fake (domain/service level)

```java
public interface IssueClient {
    Issue fetchIssue(String key) throws IssueNotFoundException;
}

public class MockIssueClient implements IssueClient {
    private final Map<String, Issue> issues = new HashMap<>();

    public void stubIssue(String key, String summary) {
        issues.put(key, new Issue(key, summary));
    }

    @Override
    public Issue fetchIssue(String key) throws IssueNotFoundException {
        if (!issues.containsKey(key)) throw new IssueNotFoundException(key);
        return issues.get(key);
    }
}
```

The service under test receives the fake from the state object:

```java
public class ScenarioState {
    public MockIssueClient mockIssues = new MockIssueClient();
    public IssueService service = new IssueService(mockIssues);
}
```

### WireMock (code that makes real HTTP calls)

`com.github.tomakehurst:wiremock-jre8`, test scope.

```java
public class SuiteHooks {
    static WireMockServer wireMock;

    @BeforeAll
    public static void startWireMock() {
        wireMock = new WireMockServer(8089);
        wireMock.start();
    }

    @AfterAll
    public static void stopWireMock() { wireMock.stop(); }
}

public class IssueSteps {
    @Given("an issue {string} exists with summary {string}")
    public void anIssueExists(String key, String summary) {
        SuiteHooks.wireMock.stubFor(
            get(urlEqualTo("/api/issue/" + key))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("{\"key\":\"" + key + "\",\"summary\":\"" + summary + "\"}")));
    }

    @Given("no issue {string} exists")
    public void noIssueExists(String key) {
        SuiteHooks.wireMock.stubFor(
            get(urlEqualTo("/api/issue/" + key)).willReturn(aResponse().withStatus(404)));
    }
}
```

Reset stubs per scenario: `@Before public void resetWireMock() { SuiteHooks.wireMock.resetAll(); }`

### Testcontainers (real database)

```java
public class SuiteHooks {
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @BeforeAll
    public static void startDb() {
        postgres.start();
        System.setProperty("spring.datasource.url", postgres.getJdbcUrl());
    }

    @AfterAll
    public static void stopDb() { postgres.stop(); }
}
```

Reset data per scenario in `@Before` with `@Transactional` (Spring) or manual SQL.

### Tag-based environment gating

```java
@Before("@e2e")
public void checkE2eEnvironment() {
    String baseUrl = System.getenv("APP_BASE_URL");
    Assumptions.assumeTrue(baseUrl != null && !baseUrl.isBlank(),
        "Skipping @e2e: APP_BASE_URL not set");
}
```

## 8. Assertions

AssertJ or JUnit assertions in `Then` steps. For HTTP, RestAssured (`io.rest-assured:rest-assured`,
test scope):

```java
@When("I GET {string}")
public void iGet(String path) {
    state.lastResponse = given().baseUri("http://localhost:8080").when().get(path);
}

@Then("the response status is {int}")
public void theResponseStatusIs(int expected) {
    state.lastResponse.then().statusCode(expected);
}

@Then("the response body contains {string}")
public void theResponseBodyContains(String expected) {
    assertThat(state.lastResponse.getBody().asString()).contains(expected);
}
```

## 9. Running tests

```bash
mvn test                                              # all acceptance tests
mvn test -Dcucumber.filter.tags="@smoke"              # only @smoke
mvn test -Dcucumber.filter.tags="not @wip"            # CI default
mvn test -Dcucumber.plugin="pretty"                   # readable output
mvn test -Dcucumber.execution.dry-run=true            # all steps defined? no execution
mvn test -Dcucumber.features="src/test/resources/features/issue_fetch.feature"
mvn test -Dcucumber.filter.tags="not @e2e"            # skip environment-dependent
./gradlew test --tests "RunCucumberTest"              # Gradle
```

Parallel execution (JUnit 5), in `junit-platform.properties`:

```properties
cucumber.execution.parallel.enabled=true
cucumber.execution.parallel.config.strategy=dynamic
```

Every scenario must be fully isolated — no shared mutable static state.

## 10. Gotchas

- **Static state between scenarios**: glue instances are new per scenario, but `static` fields
  persist. Never use `static` for scenario state.
- **Swallowing exceptions in `When`**: catch the expected exception and store it in state; assert
  it in the `Then` step rather than letting it fail the scenario early.
- **Ambiguous step definitions**: two matching patterns throw
  `AmbiguousStepDefinitionsException` — make the Cucumber Expression more specific.
- **Glue package misconfigured**: steps reported "undefined" despite existing means
  `cucumber.glue` points at the wrong package.
- **`@CucumberContextConfiguration` must be unique**: only one class in the glue path may carry it.
