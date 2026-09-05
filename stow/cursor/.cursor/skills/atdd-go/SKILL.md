---
name: atdd-go
description: "ATDD (Acceptance Test-Driven Development) skill for Go using Godog (Cucumber/Gherkin). Use when writing feature files, defining Given/When/Then step definitions, wiring up godog test suites, applying BDD red-green-refactor cycles, integrating acceptance tests with go test, using scenario hooks (Before/After), filtering with tags, testing HTTP APIs or domain services with godog, or adding ATDD to an existing Go project."
argument-hint: "Describe the feature or acceptance test to implement (e.g., 'add feature for user login', 'test Jira issue fetch', 'add ATDD to HTTP API')"
---

# ATDD in Go with Godog

## When to Use

- Starting a new feature with an outside-in acceptance test first
- Writing Gherkin `.feature` files for business-readable specifications
- Implementing `Given`/`When`/`Then` step definitions in Go
- Wiring `godog.TestSuite` into `go test`
- Adding Before/After hooks for setup and teardown
- Filtering and running specific scenarios via tags
- Integrating acceptance tests with domain or integration layer mocks

## Core Concepts

| Term | Meaning |
|------|---------|
| Feature | A capability described in Gherkin, stored in `features/*.feature` |
| Scenario | A concrete example of the feature behaviour |
| Step | A `Given`/`When`/`Then`/`And`/`But` line; each maps to a Go function |
| Step Definition | A Go function registered with a regex/string pattern |
| ScenarioContext | The hook point where step definitions are registered |
| context.Context | Used to pass state between steps safely (no shared struct needed) |

## Installation

```bash
go get github.com/cucumber/godog@latest
```

No CLI tool needed — use `go test` only (the godog CLI is deprecated).

## ATDD Cycle

```
1. Write .feature file  (acceptance criterion — RED)
2. Run go test          → steps are undefined/pending
3. Scaffold step defs   → steps fail with real logic
4. Implement production code to make steps pass (GREEN)
5. Refactor             → re-run, all green
6. Repeat for next scenario
```

## Project Layout

```
internal/
  myfeature/
    myfeature.go          ← production code
features/
  myfeature.feature       ← Gherkin scenarios
myfeature_test.go         ← TestFeatures + step definitions
```

Keep step definition files alongside the code they test (`*_test.go` in the same package).

## Step 1 — Write the Feature File

See [Gherkin reference](./references/gherkin.md) for full syntax.

```gherkin
# features/issue_fetch.feature
Feature: Fetch Jira issue
  In order to plan work
  As a developer
  I need to be able to fetch a Jira issue by key

  Scenario: Fetch an existing issue
    Given a Jira issue "PROJ-1" exists with summary "Fix login bug"
    When I fetch issue "PROJ-1"
    Then I should see the summary "Fix login bug"

  Scenario: Fetch a non-existent issue
    Given no Jira issue "PROJ-999" exists
    When I fetch issue "PROJ-999"
    Then I should receive a not-found error
```

## Step 2 — Wire the Test Suite

In `*_test.go` in the **same package** as the production code:

```go
package myfeature_test

import (
    "testing"
    "github.com/cucumber/godog"
)

func TestFeatures(t *testing.T) {
    suite := godog.TestSuite{
        ScenarioInitializer: InitializeScenario,
        Options: &godog.Options{
            Format:   "pretty",
            Paths:    []string{"features"},
            TestingT: t,
        },
    }
    if suite.Run() != 0 {
        t.Fatal("non-zero status: failed acceptance tests")
    }
}
```

## Step 3 — Scaffold Step Definitions

Run `go test` once — godog prints unimplemented step snippets. Copy them:

```go
func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Step(`^a Jira issue "([^"]*)" exists with summary "([^"]*)"$`, aJiraIssueExistsWithSummary)
    sc.Step(`^no Jira issue "([^"]*)" exists$`, noJiraIssueExists)
    sc.Step(`^I fetch issue "([^"]*)"$`, iFetchIssue)
    sc.Step(`^I should see the summary "([^"]*)"$`, iShouldSeeTheSummary)
    sc.Step(`^I should receive a not-found error$`, iShouldReceiveANotFoundError)
}
```

## Step 4 — Implement Step Definitions with context.Context

Use `context.Context` to thread state through steps. No shared mutable structs.

```go
type issueCtxKey struct{}
type errCtxKey struct{}

func aJiraIssueExistsWithSummary(ctx context.Context, key, summary string) (context.Context, error) {
    // seed a fake/mock store
    store := map[string]string{key: summary}
    return context.WithValue(ctx, issueCtxKey{}, store), nil
}

func noJiraIssueExists(ctx context.Context, key string) (context.Context, error) {
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
    err, _ := ctx.Value(errCtxKey{}).(error)
    if err == nil {
        return errors.New("expected an error but got none")
    }
    return nil
}
```

## Step 5 — Hooks

See [hooks reference](./references/hooks.md) for full patterns.

```go
func InitializeScenario(sc *godog.ScenarioContext) {
    sc.Before(func(ctx context.Context, sc *godog.Scenario) (context.Context, error) {
        // seed DB, start server, reset state
        return ctx, nil
    })
    sc.After(func(ctx context.Context, sc *godog.Scenario, err error) (context.Context, error) {
        // cleanup, close connections
        return ctx, nil
    })

    // register steps
    sc.Step(`...`, myStep)
}
```

## Running Tests

```bash
# Run all acceptance tests
go test ./... -run TestFeatures

# Run with verbose output
go test -v ./... -run TestFeatures

# Run a single scenario by name
go test -v -run ^TestFeatures$/^Fetch_an_existing_issue$

# Run only scenarios tagged @wip
go test -v -run TestFeatures -- --godog.tags=@wip
```

## Tags

```gherkin
@wip
Scenario: My in-progress scenario
    ...

@smoke @critical
Scenario: Must-pass regression check
    ...
```

Filter expressions:
- `@wip` — run tagged
- `~@wip` — exclude tagged
- `@smoke && ~@slow` — compound
- `@smoke,@wip` — OR

## Using testify Assertions

```go
import "github.com/stretchr/testify/assert"

func iShouldSeeTheSummary(ctx context.Context, expected string) error {
    got, _ := ctx.Value(issueCtxKey{}).(string)
    assert.Equal(godog.T(ctx), expected, got)
    return nil
}
```

Requires `TestingT: t` set in `godog.Options`.

## Integration Layer Pattern (jirlab)

Per project architecture: step definitions call the **integration interface**, not services directly.

```go
type JiraIntegration interface {
    FetchIssue(ctx context.Context, key string) (*Issue, error)
}

type scenarioState struct {
    jira   JiraIntegration
    result *Issue
    err    error
}
```

Inject the real or mock implementation in `Before` hook. See [integration testing patterns](./references/integration.md).

## Quality Gates

- [ ] Feature file written before any production code (red first)
- [ ] Steps use `context.Context` for state — no package-level variables
- [ ] Each scenario is independent and can run in any order
- [ ] Mocks/fakes used for external dependencies (Jira, GitLab, HTTP)
- [ ] `go test ./... -race` passes (no race conditions in concurrent scenarios)
- [ ] Tags used to mark `@wip` and `@smoke` appropriately
- [ ] Feature file is readable by a non-engineer

## References

- [Gherkin syntax](./references/gherkin.md)
- [Hooks and suite-level setup](./references/hooks.md)
- [Integration testing patterns](./references/integration.md)
- [godog GitHub](https://github.com/cucumber/godog)
- [godog pkg docs](https://pkg.go.dev/github.com/cucumber/godog)
- [Gherkin reference](https://cucumber.io/docs/gherkin/reference/)
