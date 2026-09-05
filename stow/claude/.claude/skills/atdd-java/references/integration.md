# Integration and DI Patterns (Java/Cucumber)

## Dependency Injection Options

| Library | Import | When to use |
|---------|--------|-------------|
| PicoContainer | `cucumber-picocontainer` | Zero-config; constructor injection; default choice for non-framework apps |
| Spring | `cucumber-spring` | Spring Boot integration tests; reuse application context |
| Guice | `cucumber-guice` | Guice-based apps |
| CDI | `cucumber-cdi2` | Jakarta EE / Quarkus |

## PicoContainer (Default Choice)

No configuration. Add the dependency:

```xml
<dependency>
  <groupId>io.cucumber</groupId>
  <artifactId>cucumber-picocontainer</artifactId>
  <version>${cucumber.version}</version>
  <scope>test</scope>
</dependency>
```

Declare shared state as a plain class. Cucumber creates one instance per scenario and injects it into every glue class that requests it:

```java
// Shared state — one instance per scenario
public class ScenarioState {
    public MockServiceClient mockClient = new MockServiceClient();
    public ResponseEntity<?> lastResponse;
    public Exception lastError;

    public void reset() {
        mockClient = new MockServiceClient();
        lastResponse = null;
        lastError = null;
    }
}

// Any glue class: declare constructor parameter
public class ApiSteps {
    private final ScenarioState state;
    public ApiSteps(ScenarioState state) { this.state = state; }
}

public class Hooks {
    private final ScenarioState state;
    public Hooks(ScenarioState state) { this.state = state; }

    @Before
    public void reset() { state.reset(); }
}
```

## Spring Boot Integration

For acceptance tests that boot the full application context:

```xml
<dependency>
  <groupId>io.cucumber</groupId>
  <artifactId>cucumber-spring</artifactId>
  <version>${cucumber.version}</version>
  <scope>test</scope>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-test</artifactId>
  <scope>test</scope>
</dependency>
```

```java
// ContextConfig.java — the single @SpringBootTest class in the glue package
@CucumberContextConfiguration
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class ContextConfig {
    // Optionally override beans for test
}
```

Inject Spring beans into step definitions:

```java
public class ApiSteps {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ScenarioState state;  // Must be @Scope("cucumber-glue")

    @When("I GET {string}")
    public void iGet(String path) {
        state.lastResponse = restTemplate.getForEntity(path, String.class);
    }
}
```

For shared state with Spring DI, use `@Scope("cucumber-glue")`:

```java
@Component
@Scope("cucumber-glue")
public class ScenarioState {
    public ResponseEntity<?> lastResponse;
    // ...
}
```

## WireMock — HTTP Stub Server

Best for testing code that makes real HTTP calls without a live backend:

```xml
<dependency>
  <groupId>com.github.tomakehurst</groupId>
  <artifactId>wiremock-jre8</artifactId>
  <version>2.35.2</version>
  <scope>test</scope>
</dependency>
```

```java
import com.github.tomakehurst.wiremock.WireMockServer;
import static com.github.tomakehurst.wiremock.client.WireMock.*;

public class SuiteHooks {

    static WireMockServer wireMock;

    @BeforeAll
    public static void startWireMock() {
        wireMock = new WireMockServer(8089);
        wireMock.start();
    }

    @AfterAll
    public static void stopWireMock() {
        wireMock.stop();
    }
}

// In step definitions:
public class JiraSteps {

    @Given("a Jira issue {string} exists with summary {string}")
    public void aJiraIssueExists(String key, String summary) {
        SuiteHooks.wireMock.stubFor(
            get(urlEqualTo("/rest/api/3/issue/" + key))
                .willReturn(aResponse()
                    .withStatus(200)
                    .withHeader("Content-Type", "application/json")
                    .withBody("{\"key\":\"" + key + "\",\"fields\":{\"summary\":\"" + summary + "\"}}")
                )
        );
    }

    @Given("no Jira issue {string} exists")
    public void noJiraIssueExists(String key) {
        SuiteHooks.wireMock.stubFor(
            get(urlEqualTo("/rest/api/3/issue/" + key))
                .willReturn(aResponse().withStatus(404))
        );
    }
}
```

Reset stubs before each scenario:

```java
@Before
public void resetWireMock() {
    SuiteHooks.wireMock.resetAll();
}
```

## Interface-Based Mocking (Unit-Level ATDD)

For domain/service tests without HTTP:

```java
// Define the interface in production code
public interface JiraClient {
    Issue fetchIssue(String key) throws IssueNotFoundException;
}

// Implement a controllable fake in tests
public class MockJiraClient implements JiraClient {
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

In step definitions, the service under test receives the mock:

```java
public class ScenarioState {
    public MockJiraClient mockJira = new MockJiraClient();
    public IssueService service = new IssueService(mockJira); // inject mock
    // ...
}
```

## REST API Testing with RestAssured

```xml
<dependency>
  <groupId>io.rest-assured</groupId>
  <artifactId>rest-assured</artifactId>
  <scope>test</scope>
</dependency>
```

```java
import io.restassured.response.Response;
import static io.restassured.RestAssured.*;

public class ApiSteps {

    private final ScenarioState state;
    public ApiSteps(ScenarioState state) { this.state = state; }

    @When("I GET {string}")
    public void iGet(String path) {
        state.lastResponse = given()
            .baseUri("http://localhost:8080")
            .when()
            .get(path);
    }

    @Then("the response status is {int}")
    public void theResponseStatusIs(int expectedStatus) {
        state.lastResponse.then().statusCode(expectedStatus);
    }

    @Then("the response body contains {string}")
    public void theResponseBodyContains(String expected) {
        assertThat(state.lastResponse.getBody().asString()).contains(expected);
    }
}
```

## Database Testing with Testcontainers

For acceptance tests that need a real DB:

```xml
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>postgresql</artifactId>
  <scope>test</scope>
</dependency>
```

```java
public class SuiteHooks {

    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:15-alpine");

    @BeforeAll
    public static void startDb() {
        postgres.start();
        System.setProperty("spring.datasource.url", postgres.getJdbcUrl());
    }

    @AfterAll
    public static void stopDb() {
        postgres.stop();
    }
}
```

Reset data per-scenario in `@Before` using `@Transactional` (Spring) or manual SQL.

## Tag-Based Environment Gating

Skip integration/e2e scenarios when the environment is not available:

```java
@Before("@e2e")
public void checkE2eEnvironment() {
    String baseUrl = System.getenv("APP_BASE_URL");
    Assumptions.assumeTrue(baseUrl != null && !baseUrl.isBlank(),
        "Skipping @e2e: APP_BASE_URL not set");
}
```

Run integration tests separately in CI:

```bash
# Unit + acceptance (no @e2e)
mvn test -Dcucumber.filter.tags="not @e2e"

# Full e2e suite
APP_BASE_URL=https://staging.example.com mvn test -Dcucumber.filter.tags="@e2e"
```

## Common Gotchas

- **Static state between scenarios**: Cucumber creates new glue class instances per scenario, but `static` fields persist. Never use `static` for scenario state.
- **Swallowing exceptions in When steps**: Catch expected exceptions and store them in state; don't let them propagate until the `Then` step.
- **Ambiguous step definitions**: If two `@Given` patterns both match, Cucumber throws `AmbiguousStepDefinitionsException`. Use more specific Cucumber Expressions.
- **Glue package misconfigured**: If steps are "undefined" despite existing, check `cucumber.glue` points to the correct package.
- **`@CucumberContextConfiguration` must be unique**: Only one class in the glue path may carry this annotation for Spring tests.
