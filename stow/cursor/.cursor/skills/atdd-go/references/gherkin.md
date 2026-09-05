# Gherkin Syntax Reference

For use with `github.com/cucumber/godog`.

## File Structure

```gherkin
Feature: <title>
  <description — optional, free text>

  Background:
    Given <shared step for all scenarios>

  Scenario: <title>
    Given <precondition>
    When  <action>
    Then  <expected outcome>
    And   <additional outcome>
    But   <exclusion>

  Scenario Outline: <parameterized title>
    Given there are <start> items
    When I remove <remove>
    Then there should be <remaining>

    Examples:
      | start | remove | remaining |
      | 12    | 5      | 7         |
      | 5     | 3      | 2         |
```

## Keywords

| Keyword | Purpose |
|---------|---------|
| `Feature:` | Names the feature; one per file |
| `Background:` | Steps run before every scenario in the file |
| `Scenario:` | A single concrete example |
| `Scenario Outline:` | Parameterized scenario with an Examples table |
| `Examples:` | Table of values for Scenario Outline |
| `Given` | Sets up precondition / initial state |
| `When` | Describes the action / event |
| `Then` | Describes expected outcome |
| `And` | Continues the previous keyword's intent |
| `But` | Like `And`, typically used for negative cases |
| `@tag` | Marks a feature, scenario, or outline |
| `#` | Comment |
| `"""` | Docstring (multiline string argument) |
| `|` | Data Table |

## Tags

Tags go on the line above `Feature:`, `Scenario:`, or `Scenario Outline:`.

```gherkin
@smoke
Feature: User authentication

  @wip
  Scenario: Login with valid credentials
    ...

  @slow @integration
  Scenario: Login with LDAP
    ...
```

Tags are inherited: a tag on `Feature:` applies to all scenarios in that file.

## Data Tables

Passed as `*godog.Table` to the step function:

```gherkin
Given the following users exist:
  | name  | email           | role  |
  | Alice | alice@test.com  | admin |
  | Bob   | bob@test.com    | user  |
```

```go
func theFollowingUsersExist(ctx context.Context, table *godog.Table) error {
    for _, row := range table.Rows[1:] { // skip header
        name  := row.Cells[0].Value
        email := row.Cells[1].Value
        role  := row.Cells[2].Value
        _ = name; _ = email; _ = role
        // seed your store
    }
    return nil
}
```

## Docstrings

Multiline string passed as `string` or `*godog.DocString`:

```gherkin
When I send the following JSON body:
  """
  {
    "key": "PROJ-1",
    "summary": "Fix login"
  }
  """
```

```go
func iSendTheFollowingJSONBody(ctx context.Context, body *godog.DocString) (context.Context, error) {
    // body.Content is the raw string
    return context.WithValue(ctx, reqBodyKey{}, body.Content), nil
}
```

## Scenario Outline Step Pattern

Godog replaces `<placeholder>` values automatically:

```gherkin
Scenario Outline: Remove items
  Given there are <start> items
  When I remove <remove>
  Then there should be <remaining>

  Examples:
    | start | remove | remaining |
    | 12    | 5      | 7         |
    | 5     | 3      | 2         |
```

The same step functions are reused; parameters are injected from each row.

## Background

Runs before every scenario in the file. Useful for seeding common state:

```gherkin
Background:
  Given the database is empty
  And the following config is loaded from "testdata/config.yaml"
```

## Naming Conventions

- Feature files: `features/<domain>.feature` — kebab-case
- One `Feature:` per file
- Scenario names: sentence-case, describe behaviour not implementation
- Step text: imperative present tense — "I fetch", "there are", "I should see"
- Avoid technical jargon in step text visible to non-engineers

## Step Regex Patterns

| Match | Pattern |
|-------|---------|
| Integer | `(\d+)` |
| Quoted string | `"([^"]*)"` |
| Any word | `(\w+)` |
| Optional word | `(?:word )?` |
| Boolean flag | `(enabled\|disabled)` |
| Float | `(\d+\.\d+)` |

## Anti-patterns

- **Conjunctive steps**: `Given I am logged in and have an issue open` — split into two steps
- **UI language in domain features**: `When I click the Submit button` in a domain test — use intent, not mechanics
- **Imperative features**: listing every click/keystroke — keep scenarios declarative
- **Giant Backgrounds**: more than 3–4 background steps signals a scenario doing too much
