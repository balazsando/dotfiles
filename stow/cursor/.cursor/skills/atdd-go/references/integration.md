# Integration Testing Patterns with Godog

Patterns for testing against real or mocked integration layers (HTTP APIs, databases, subprocesses).

## Pattern 1 — Interface-based Mocking (preferred for unit-level ATDD)

Define the integration interface once; inject mock in Before hook, real impl in production.

```go
// internal/integration/jira.go
type JiraIntegration interface {
    FetchIssue(ctx context.Context, key string) (*Issue, error)
    CreateIssue(ctx context.Context, req CreateIssueRequest) (*Issue, error)
}
```

```go
// features_test/jira_steps_test.go
type mockJira struct {
    issues map[string]*Issue
}

func (m *mockJira) FetchIssue(_ context.Context, key string) (*Issue, error) {
    if issue, ok := m.issues[key]; ok {
        return issue, nil
    }
    return nil, fmt.Errorf("issue %s not found", key)
}

func (m *mockJira) CreateIssue(_ context.Context, req CreateIssueRequest) (*Issue, error) {
    issue := &Issue{Key: "PROJ-" + strconv.Itoa(len(m.issues)+1), Summary: req.Summary}
    m.issues[issue.Key] = issue
    return issue, nil
}
```

Inject in `Before`:

```go
sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
    return context.WithValue(ctx, jiraKey{}, &mockJira{issues: make(map[string]*Issue)}), nil
})
```

## Pattern 2 — httptest.Server (for HTTP integration tests)

Use when testing code that makes real HTTP calls:

```go
var testServer *httptest.Server

func InitializeTestSuite(sc *godog.TestSuiteContext) {
    sc.BeforeSuite(func() {
        testServer = httptest.NewServer(newJiraMockHandler())
    })
    sc.AfterSuite(func() { testServer.Close() })
}

func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
        client := NewJiraClient(testServer.URL, "test-token")
        return context.WithValue(ctx, jiraClientKey{}, client), nil
    })
    // register steps...
}
```

Handler example:

```go
func newJiraMockHandler() http.Handler {
    mux := http.NewServeMux()
    mux.HandleFunc("/rest/api/3/issue/PROJ-1", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]any{
            "key":    "PROJ-1",
            "fields": map[string]any{"summary": "Fix login bug"},
        })
    })
    mux.HandleFunc("/rest/api/3/issue/", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusNotFound)
    })
    return mux
}
```

## Pattern 3 — Real Integration (end-to-end, tagged @e2e)

Mark end-to-end scenarios with `@e2e` and skip in unit test runs:

```gherkin
@e2e
Scenario: Fetch real Jira issue
  Given Jira is accessible
  When I fetch issue "PROJ-1"
  Then I should see a summary
```

In test suite, gate on env:

```go
Options: &godog.Options{
    Tags: os.Getenv("GODOG_TAGS"), // set to "~@e2e" by default in CI
}
```

Or conditionally skip in `Before`:

```go
sc.Before(func(ctx context.Context, s *godog.Scenario) (context.Context, error) {
    for _, tag := range s.Tags {
        if tag.Name == "@e2e" && os.Getenv("JIRA_BASE_URL") == "" {
            return ctx, godog.ErrSkip
        }
    }
    return ctx, nil
})
```

## jirlab Architecture Alignment

Per `docs/architecture.md` / project conventions:

| Layer | ATDD Role |
|-------|-----------|
| `internal/tui/` | Not tested with godog; use unit tests |
| `internal/integration/` | Define interfaces here; mock in step tests |
| `internal/service/` | HTTP clients — use httptest.Server in acceptance tests |
| `features/` | Feature files live at project root |
| `*_acceptance_test.go` | Test files; name clearly separate from unit tests |

Example acceptance test file placement:

```
features/
  jira_issue.feature
  gitlab_mr.feature
  kube_pods.feature
internal/
  integration/
    jira.go            ← interface
    jira_mock_test.go  ← mock for acceptance tests
jira_acceptance_test.go  ← TestFeatures + step defs
```

## Asserting HTTP Calls Were Made

When using `httptest.Server`, record calls to assert interactions:

```go
type recordingHandler struct {
    calls []string
    next  http.Handler
}

func (h *recordingHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    h.calls = append(h.calls, r.Method+" "+r.URL.Path)
    h.next.ServeHTTP(w, r)
}

// In Then step:
func iShouldHaveFetchedIssue(ctx context.Context, key string) error {
    rec := ctx.Value(recorderKey{}).(*recordingHandler)
    expected := "GET /rest/api/3/issue/" + key
    for _, call := range rec.calls {
        if call == expected {
            return nil
        }
    }
    return fmt.Errorf("expected call %q not found in %v", expected, rec.calls)
}
```

## Testify + Godog

```go
import (
    "github.com/cucumber/godog"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

// assert: non-fatal, reports and continues
func iShouldSeeSummary(ctx context.Context, expected string) error {
    got := ctx.Value(summaryKey{}).(string)
    assert.Equal(godog.T(ctx), expected, got)
    return nil
}

// require: fatal, stops the step immediately
func theTokenMustBePresent(ctx context.Context) error {
    token, _ := ctx.Value(tokenKey{}).(string)
    require.NotEmpty(godog.T(ctx), token, "auth token must be set")
    return nil
}
```

Requires `TestingT: t` in `godog.Options`.

## Common Gotchas

- **Return `nil` error for expected negative cases**: when testing error paths, store the error in context and assert in the `Then` step — don't return it from the `When` step or the scenario fails early.
- **Don't share state across scenarios**: reset everything in `Before`.
- **Context key collisions**: always use unexported struct types as keys, never strings.
- **Step regex greediness**: prefer `([^"]*)` over `(.*)` in quoted string patterns.
