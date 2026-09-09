# ATDD in Go — Godog

Section order mirrors `java.md`.

## 1. Dependencies

```bash
go get github.com/cucumber/godog@latest
```

No CLI tool needed — use `go test` only; the godog CLI is deprecated. `github.com/stretchr/testify`
if you want assertion helpers (§8).

## 2. Test suite wiring

In a `*_test.go` file in the same package as the code under test:

```go
package myfeature_test

import (
    "testing"
    "github.com/cucumber/godog"
)

func TestFeatures(t *testing.T) {
    suite := godog.TestSuite{
        TestSuiteInitializer: InitializeTestSuite,
        ScenarioInitializer:  InitializeScenario,
        Options: &godog.Options{
            Format:    "pretty",
            Paths:     []string{"features"},
            TestingT:  t,
            Randomize: time.Now().UTC().UnixNano(), // surfaces hidden inter-scenario deps
        },
    }
    if suite.Run() != 0 {
        t.Fatal("non-zero status: failed acceptance tests")
    }
}
```

`TestingT: t` is what makes testify assertions and `godog.T(ctx)` work.

Format options: `pretty` (full coloured output), `progress` (dots), `junit` (CI XML), `cucumber`
(JSON for HTML reporters). Switch on verbosity if useful:

```go
format := "progress"
for _, arg := range os.Args {
    if arg == "-test.v=true" {
        format = "pretty"
    }
}
```

Feature files can be compiled into the binary:

```go
//go:embed features/*
var features embed.FS

Options: &godog.Options{Paths: []string{"features"}, FS: features}
```

## 3. Project layout

```
features/
  issue_fetch.feature      ← Gherkin scenarios, project root
internal/
  integration/
    issues.go              ← the interface acceptance tests swap
    issues_mock_test.go    ← fake for acceptance tests
  myfeature/
    myfeature.go           ← production code
issues_acceptance_test.go  ← TestFeatures + step definitions
```

Keep step-definition files alongside the code they test, named clearly apart from unit tests. A
project's own `docs/architecture.md` wins where it disagrees with this:

| Layer | ATDD role |
|-------|-----------|
| `internal/tui/`, `internal/cmd/` | Not tested with godog; use unit tests |
| `internal/integration/` | Define interfaces here; mock in step tests |
| `internal/service/` | HTTP clients — use `httptest.Server` in acceptance tests |
| `features/` | Feature files, project root |
| `*_acceptance_test.go` | Step definitions and the suite entry point |

## 4. Step definitions

Register in `InitializeScenario`; `go test` prints snippets for every undefined step.

```go
func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Step(`^an issue "([^"]*)" exists with summary "([^"]*)"$`, anIssueExistsWithSummary)
    sc.Step(`^no issue "([^"]*)" exists$`, noIssueExists)
    sc.Step(`^I fetch issue "([^"]*)"$`, iFetchIssue)
    sc.Step(`^I should see the summary "([^"]*)"$`, iShouldSeeTheSummary)
    sc.Step(`^I should receive a not-found error$`, iShouldReceiveANotFoundError)
}
```

## 5. Sharing state between steps

Thread state through `context.Context`. Keys are **unexported struct types**, never strings, so
they cannot collide.

```go
type issueCtxKey struct{}
type errCtxKey struct{}

func anIssueExistsWithSummary(ctx context.Context, key, summary string) (context.Context, error) {
    store := map[string]string{key: summary}
    return context.WithValue(ctx, issueCtxKey{}, store), nil
}

func noIssueExists(ctx context.Context, key string) (context.Context, error) {
    return context.WithValue(ctx, issueCtxKey{}, map[string]string{}), nil
}

func iFetchIssue(ctx context.Context, key string) (context.Context, error) {
    store, _ := ctx.Value(issueCtxKey{}).(map[string]string)
    summary, ok := store[key]
    if !ok {
        return context.WithValue(ctx, errCtxKey{}, fmt.Errorf("issue %s not found", key)), nil
    }
    return context.WithValue(ctx, issueCtxKey{}, summary), nil
}

func iShouldSeeTheSummary(ctx context.Context, expected string) error {
    got, _ := ctx.Value(issueCtxKey{}).(string)
    if got != expected {
        return fmt.Errorf("expected summary %q, got %q", expected, got)
    }
    return nil
}

func iShouldReceiveANotFoundError(ctx context.Context) error {
    if err, _ := ctx.Value(errCtxKey{}).(error); err == nil {
        return errors.New("expected an error but got none")
    }
    return nil
}
```

**State struct alternative** — when many steps share the same data, a struct pointer with methods
as step functions reads better than chained context values:

```go
type scenarioState struct {
    issues   IssueIntegration
    result   *Issue
    fetchErr error
}

func InitializeScenario(sc *godog.ScenarioContext) {
    s := &scenarioState{}

    sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
        s.issues = newMockIssues()
        s.result = nil
        s.fetchErr = nil
        return ctx, nil
    })

    sc.Step(`^I fetch issue "([^"]*)"$`, s.iFetchIssue)
    sc.Step(`^I should see the summary "([^"]*)"$`, s.iShouldSeeTheSummary)
}

func (s *scenarioState) iFetchIssue(ctx context.Context, key string) error {
    s.result, s.fetchErr = s.issues.FetchIssue(ctx, key)
    return nil
}
```

With `Concurrency > 1`, each scenario **must** get its own `*scenarioState` — instantiate it inside
`Before`, not outside `InitializeScenario`.

## 6. Hooks and lifecycle

```
TestSuiteInitializer  → BeforeSuite / AfterSuite, once around all features
ScenarioInitializer   → per scenario; registers steps and scenario/step hooks
```

```go
func InitializeTestSuite(sc *godog.TestSuiteContext) {
    sc.BeforeSuite(func() { testServer = httptest.NewServer(newRouter()) })
    sc.AfterSuite(func() { testServer.Close() })
}

func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Before(func(ctx context.Context, s *godog.Scenario) (context.Context, error) {
        // seed data, reset mocks, inject dependencies into the context
        ctx = context.WithValue(ctx, issueClientKey{}, newMockIssueClient())
        return ctx, nil
    })

    sc.After(func(ctx context.Context, s *godog.Scenario, err error) (context.Context, error) {
        // err is non-nil when the scenario failed — dump state for diagnosis
        return ctx, nil
    })

    sc.StepContext().Before(func(ctx context.Context, st *godog.Step) (context.Context, error) {
        return ctx, nil
    })
    sc.StepContext().After(func(ctx context.Context, st *godog.Step,
        status godog.StepResultStatus, err error) (context.Context, error) {
        return ctx, nil
    })

    sc.Step(`^...`, myStep)
}
```

The `*godog.Scenario` in a hook carries `.Name`, `.Tags` and the step list — tag-scoped behaviour
is an explicit check on `s.Tags`, there is no tag-filtered hook registration.

## 7. Test doubles and integration

### Interface-based fake (preferred)

Step definitions call an **integration interface**, never a concrete service — that interface is
the seam the acceptance test swaps.

```go
// internal/integration/issues.go
type IssueIntegration interface {
    FetchIssue(ctx context.Context, key string) (*Issue, error)
    CreateIssue(ctx context.Context, req CreateIssueRequest) (*Issue, error)
}
```

```go
// issues_acceptance_test.go
type mockIssues struct {
    issues map[string]*Issue
}

func (m *mockIssues) FetchIssue(_ context.Context, key string) (*Issue, error) {
    if issue, ok := m.issues[key]; ok {
        return issue, nil
    }
    return nil, fmt.Errorf("issue %s not found", key)
}

func (m *mockIssues) CreateIssue(_ context.Context, req CreateIssueRequest) (*Issue, error) {
    issue := &Issue{Key: "PROJ-" + strconv.Itoa(len(m.issues)+1), Summary: req.Summary}
    m.issues[issue.Key] = issue
    return issue, nil
}

sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
    return context.WithValue(ctx, issuesKey{}, &mockIssues{issues: map[string]*Issue{}}), nil
})
```

### httptest.Server (code that makes real HTTP calls)

```go
var testServer *httptest.Server

func InitializeTestSuite(sc *godog.TestSuiteContext) {
    sc.BeforeSuite(func() { testServer = httptest.NewServer(newIssueMockHandler()) })
    sc.AfterSuite(func() { testServer.Close() })
}

func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
        client := NewIssueClient(testServer.URL, os.Getenv("API_TOKEN"))
        return context.WithValue(ctx, issueClientKey{}, client), nil
    })
}

func newIssueMockHandler() http.Handler {
    mux := http.NewServeMux()
    mux.HandleFunc("/api/issue/PROJ-1", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]any{"key": "PROJ-1", "summary": "Fix login bug"})
    })
    mux.HandleFunc("/api/issue/", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusNotFound)
    })
    return mux
}
```

Record calls when the interaction itself is the assertion:

```go
type recordingHandler struct {
    calls []string
    next  http.Handler
}

func (h *recordingHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    h.calls = append(h.calls, r.Method+" "+r.URL.Path)
    h.next.ServeHTTP(w, r)
}

func iShouldHaveFetchedIssue(ctx context.Context, key string) error {
    rec := ctx.Value(recorderKey{}).(*recordingHandler)
    expected := "GET /api/issue/" + key
    for _, call := range rec.calls {
        if call == expected {
            return nil
        }
    }
    return fmt.Errorf("expected call %q not found in %v", expected, rec.calls)
}
```

### Tag-based environment gating

Tag end-to-end scenarios `@e2e`, exclude them by default (`Tags: os.Getenv("GODOG_TAGS")` set to
`~@e2e` in CI), or skip them when the environment is absent:

```go
sc.Before(func(ctx context.Context, s *godog.Scenario) (context.Context, error) {
    for _, tag := range s.Tags {
        if tag.Name == "@e2e" && os.Getenv("API_BASE_URL") == "" {
            return ctx, godog.ErrSkip
        }
    }
    return ctx, nil
})
```

## 8. Assertions

Returning a non-nil `error` fails the step. testify gives better messages via `godog.T(ctx)`
(requires `TestingT: t`):

```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

// assert: non-fatal, reports and continues
func iShouldSeeTheSummary(ctx context.Context, expected string) error {
    got, _ := ctx.Value(summaryKey{}).(string)
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

## 9. Running tests

```bash
go test ./... -run TestFeatures                       # all acceptance tests
go test -v ./... -run TestFeatures                    # verbose
go test -v -run ^TestFeatures$/^Fetch_an_existing_issue$   # one scenario
go test -v -run TestFeatures -- --godog.tags=@wip     # tag filter
go test -race ./... -run TestFeatures                 # isolation check
```

Parallel scenarios:

```go
Options: &godog.Options{Concurrency: 4}
```

All scenarios must be stateless and isolated; verify with `-race`.

## 10. Gotchas

- **Return `nil` from a `When` step on an expected error**: store the error in context and assert
  it in `Then`, or the scenario fails before reaching the assertion.
- **Don't share state across scenarios**: reset everything in `Before`; with `Concurrency > 1` the
  state carrier must be created inside `Before`.
- **Context key collisions**: always unexported struct types as keys, never strings.
- **Step regex greediness**: prefer `([^"]*)` over `(.*)` in quoted patterns.
- **No `Rule:` support**: godog does not implement it — split rule groups into separate features.
