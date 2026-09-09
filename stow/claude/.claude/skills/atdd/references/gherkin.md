# Gherkin syntax reference

Language-neutral, with Java and Go bindings called out where the mapping differs.

## Feature File Structure

```gherkin
# language: en  (optional header; omit for English)
@tag1 @tag2
Feature: <Short title — one capability>
  <Free-form description. Ignored at runtime.
  Use Markdown. Describe business rules and context here.>

  Background:
    Given <shared precondition for every scenario in this feature>

  Rule: <A business rule (Gherkin 6+)>
    Background:
      Given <shared precondition for every scenario in this rule>

    Scenario: <Happy path>
      Given <initial state>
      When  <action>
      Then  <expected outcome>
      And   <additional assertion>
      But   <negative assertion>

    @wip
    Scenario: <In progress>
      Given <not yet implemented>

    Scenario Outline: <Parameterized title>
      Given there are <start> items
      When  I remove <remove>
      Then  there should be <remaining>

      @smoke
      Examples:
        | start | remove | remaining |
        | 12    | 5      | 7         |
        | 5     | 3      | 2         |
```

## Primary Keywords

| Keyword | Purpose |
|---------|---------|
| `Feature:` | Describes one feature; one per file |
| `Rule:` | Groups scenarios sharing a business rule (Gherkin 6+) |
| `Scenario:` / `Example:` | A single concrete test (synonyms) |
| `Scenario Outline:` / `Scenario Template:` | Parameterised scenario |
| `Examples:` / `Scenarios:` | Data table for Scenario Outline |
| `Background:` | Steps run before every scenario (after the before-hooks) |
| `Given` | Sets up initial context / precondition |
| `When` | Describes an action or event |
| `Then` | Describes expected outcome — use assertions here |
| `And` | Continues previous keyword |
| `But` | Like `And`, typically for negatives |
| `*` | Bullet-point style; replaces any step keyword |
| `"""` | Doc String delimiter |
| `\|` | Data Table cell separator |
| `@` | Tag |
| `#` | Comment |

Godog does not implement `Rule:`; keep rule grouping to separate feature files there.

## Tags

Tags go on the line **above** `Feature:`, `Rule:`, `Scenario:`, `Scenario Outline:`, or `Examples:`.

```gherkin
@billing @critical
Feature: Billing

  @smoke
  Scenario: Basic payment
    ...

  @slow @database
  Scenario: Bulk import
    ...
```

Tags are **inherited**: a tag on `Feature:` applies to all its scenarios.

Tag expressions — Cucumber-JVM (`cucumber.filter.tags`, `@CucumberOptions`):

```
@smoke                       → only @smoke
not @wip                     → exclude @wip
@smoke and @fast             → both tags
@smoke or @regression        → either tag
(@smoke or @ui) and not @slow
```

Godog (`godog.Options.Tags`, `--godog.tags`) uses the older operator set:

```
@wip                         → only @wip
~@wip                        → exclude @wip
@smoke && ~@slow             → compound
@smoke,@wip                  → OR
```

## Scenario Outline

```gherkin
Scenario Outline: Process <amount> items
  Given there are <start> items
  When  I process <amount>
  Then  there should be <remaining>

  Examples:
    | start | amount | remaining |
    | 10    | 3      | 7         |
    | 5     | 2      | 3         |
```

Each row generates a separate test; `<placeholder>` values are substituted before matching, so the
same step definitions are reused. Tag individual `Examples:` tables:

```gherkin
@slow
Examples: Large dataset
  | start | amount | remaining |
  | 1000  | 500    | 500       |
```

## Background

Runs `Given` steps before every scenario in the `Feature` (or `Rule`), **after** the before-hooks.

```gherkin
Background:
  Given the application is running
  And the database is seeded with test data
```

Keep `Background` to ≤4 steps. If it grows, use a higher-level step (`Given the system is set up`).

## Data Tables

Passed as the **last argument** to the step.

```gherkin
Given the following users exist:
  | name  | email                  | role  |
  | Alice | alice@example.invalid  | admin |
  | Bob   | bob@example.invalid    | user  |
```

Escape `|` in cells as `\|`, newlines as `\n`, backslash as `\\`.

### Java

```java
// List of maps — most flexible, header row becomes keys
@Given("the following users exist:")
public void theFollowingUsersExist(List<Map<String, String>> rows) {
    rows.forEach(row -> create(row.get("name"), row.get("email"), row.get("role")));
}

// Simple list (single column, no header)
@Given("the following items:")
public void theFollowingItems(List<String> items) { ... }

// Map (two columns: key | value)
@Given("the config:")
public void theConfig(Map<String, String> config) { ... }

// Raw DataTable for full control
@Given("the matrix:")
public void theMatrix(DataTable table) {
    List<List<String>> raw = table.asLists();
    // or: table.asMaps(), table.asMap(String.class, String.class)
}
```

### Go

Arrives as `*godog.Table`; no automatic mapping.

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

## Doc Strings

Multiline text passed as the last argument. The content-type annotation (`"""json`) is
informational; the raw string is what reaches the step.

```gherkin
When I submit the following JSON:
  """json
  {
    "key": "PROJ-1",
    "summary": "Fix the bug"
  }
  """
```

```java
@When("I submit the following JSON:")
public void iSubmitTheFollowingJSON(String body) {
    // dedented to the opening """
    state.requestBody = body;
}
```

```go
func iSubmitTheFollowingJSON(ctx context.Context, body *godog.DocString) (context.Context, error) {
    // body.Content is the raw string
    return context.WithValue(ctx, reqBodyKey{}, body.Content), nil
}
```

## Step Matching — Cucumber Expressions (Java)

Prefer over regex unless the match is genuinely complex.

```java
// Built-in types
@Given("there are {int} items")
@When("the user {string} logs in")
@Then("the response code is {int}")

// Optional text
@Given("there is/are {int} item(s)")

// Alternation
@Given("I am on the login/home page")

// Anonymous {}: matches anything, maps to String
@Given("I navigate to {}")

// Custom parameter type
@ParameterType("admin|user|guest")
public Role role(String name) { return Role.valueOf(name.toUpperCase()); }

@Given("I am logged in as {role}")
public void iAmLoggedInAs(Role role) { ... }
```

| Type | Example step text | Java type |
|------|-------------------|-----------|
| `{int}` | `42` | `int` / `Integer` |
| `{long}` | `9999999999` | `long` |
| `{float}` | `3.14` | `float` |
| `{double}` | `3.14159` | `double` |
| `{word}` | `admin` | `String` |
| `{string}` | `"quoted text"` | `String` |
| `{}` | anything | `String` |

## Step Matching — Regex (Go)

Godog matches on regex. Capture groups map positionally to the step function's parameters, after
the optional leading `context.Context`.

| Match | Pattern |
|-------|---------|
| Integer | `(\d+)` |
| Quoted string | `"([^"]*)"` |
| Any word | `(\w+)` |
| Optional word | `(?:word )?` |
| Boolean flag | `(enabled\|disabled)` |
| Float | `(\d+\.\d+)` |

Anchor with `^...$` and prefer `([^"]*)` over `(.*)` inside quotes — a greedy group swallows the
rest of the step and produces a match that looks right until a second argument appears.

## Naming Conventions

- Feature files: `<domain>.feature`, kebab-case — `src/test/resources/features/` (Java),
  `features/` at project root (Go)
- One `Feature:` per file
- Scenario titles: sentence-case, describe intent not implementation
- Step text: imperative present tense — "I fetch", "there are", "I should see"
- Avoid UI/technical jargon in steps visible to business stakeholders

## Common Anti-patterns

| Anti-pattern | Better alternative |
|-------------|-------------------|
| `Given I click the Submit button` | `Given I submit the form` — intent, not mechanics |
| `Given I am logged in and have 5 items` | Split into two steps (conjunctive steps) |
| Listing every click and keystroke | Keep scenarios declarative, not imperative |
| Long `Background` (>4 steps) | Higher-level step or `Rule`-scoped background |
| `Then I check the database for user X` | Observe system output, not internal state |
| Scenario depends on previous scenario's state | Each scenario must be fully independent |
