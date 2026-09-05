# Hooks and Suite-Level Setup Reference

## Hook Registration Points

```
TestSuiteInitializer  → runs once before all features
ScenarioInitializer   → runs per scenario; registers steps + scenario hooks
```

## Suite-Level Hooks (TestSuiteInitializer)

Use for expensive one-time setup: start a DB, spin up a test HTTP server.

```go
func TestFeatures(t *testing.T) {
    suite := godog.TestSuite{
        TestSuiteInitializer: InitializeTestSuite,
        ScenarioInitializer:  InitializeScenario,
        Options: &godog.Options{
            Format:   "pretty",
            Paths:    []string{"features"},
            TestingT: t,
        },
    }
    if suite.Run() != 0 {
        t.Fatal("non-zero status: acceptance tests failed")
    }
}

func InitializeTestSuite(sc *godog.TestSuiteContext) {
    sc.BeforeSuite(func() {
        // start test server, open DB connection
        testServer = httptest.NewServer(newRouter())
    })
    sc.AfterSuite(func() {
        // shutdown
        testServer.Close()
    })
}
```

## Scenario-Level Hooks

```go
func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Before(func(ctx context.Context, s *godog.Scenario) (context.Context, error) {
        // called before each scenario
        // seed data, reset mock, inject dependencies into context
        mockJira := newMockJiraClient()
        return context.WithValue(ctx, jiraClientKey{}, mockJira), nil
    })

    sc.After(func(ctx context.Context, s *godog.Scenario, err error) (context.Context, error) {
        // called after each scenario (err is non-nil if scenario failed)
        if err != nil {
            // log state for diagnosis
        }
        return ctx, nil
    })

    // register steps
    sc.Step(`^...`, myStep)
}
```

## Step-Level Hooks

```go
func InitializeScenario(sc *godog.ScenarioContext) {
    sc.StepContext().Before(func(ctx context.Context, st *godog.Step) (context.Context, error) {
        // called before each step
        return ctx, nil
    })
    sc.StepContext().After(func(ctx context.Context, st *godog.Step, status godog.StepResultStatus, err error) (context.Context, error) {
        // called after each step
        return ctx, nil
    })
}
```

## Injecting Dependencies via context.Context

The cleanest pattern: inject mocks/clients in `Before`, retrieve in steps.

```go
// Key types — unexported to prevent collisions
type jiraClientKey struct{}
type gitLabClientKey struct{}

func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
        ctx = context.WithValue(ctx, jiraClientKey{}, newMockJiraClient())
        ctx = context.WithValue(ctx, gitLabClientKey{}, newMockGitLabClient())
        return ctx, nil
    })
    sc.Step(`^I fetch issue "([^"]*)"$`, iFetchIssue)
}

func iFetchIssue(ctx context.Context, key string) (context.Context, error) {
    client := ctx.Value(jiraClientKey{}).(JiraClient)
    issue, err := client.FetchIssue(ctx, key)
    if err != nil {
        return context.WithValue(ctx, fetchErrKey{}, err), nil
    }
    return context.WithValue(ctx, fetchResultKey{}, issue), nil
}
```

## Using a State Struct (alternative pattern)

When many steps share state, a struct pointer can be cleaner than chained context values:

```go
type scenarioState struct {
    jira   JiraClient
    result *Issue
    fetchErr error
}

func InitializeScenario(sc *godog.ScenarioContext) {
    s := &scenarioState{}

    sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
        s.jira = newMockJiraClient()
        s.result = nil
        s.fetchErr = nil
        return ctx, nil
    })

    sc.Step(`^I fetch issue "([^"]*)"$`, s.iFetchIssue)
    sc.Step(`^I should see the summary "([^"]*)"$`, s.iShouldSeeTheSummary)
}

func (s *scenarioState) iFetchIssue(ctx context.Context, key string) error {
    s.result, s.fetchErr = s.jira.FetchIssue(ctx, key)
    return nil
}
```

> ⚠️ When using concurrency (`Concurrency > 1` in Options), each scenario **must** get its own `*scenarioState`. Instantiate it inside `Before`, not outside `InitializeScenario`.

## Randomization

```go
Options: &godog.Options{
    Randomize: time.Now().UTC().UnixNano(),
    // ...
}
```

Helps surface hidden dependencies between scenarios.

## Concurrency

```go
Options: &godog.Options{
    Concurrency: 4,
    // ...
}
```

All scenarios must be stateless / isolated. Run with `-race` to detect issues:

```bash
go test -race ./... -run TestFeatures
```

## Embedding Feature Files (compile into binary)

```go
//go:embed features/*
var features embed.FS

Options: &godog.Options{
    Paths: []string{"features"},
    FS:    features,
}
```

## Format Options

| Format | Description |
|--------|-------------|
| `pretty` | Full coloured output with step text |
| `progress` | Dots per step, compact |
| `junit` | JUnit XML (for CI) |
| `cucumber` | Cucumber JSON (for HTML reporters) |

Switch format by `-v` flag in tests:

```go
format := "progress"
for _, arg := range os.Args {
    if arg == "-test.v=true" {
        format = "pretty"
    }
}
```
