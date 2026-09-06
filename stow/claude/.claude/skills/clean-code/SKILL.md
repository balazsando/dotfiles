---
name: clean-code
description: "Readability and maintainability: naming, function and class design, comments, formatting, error handling, test quality, code smells, SOLID, DRY, FIRST. Use when writing, refactoring, or reviewing code for clarity and complexity."
argument-hint: "file, function, or snippet to evaluate or improve"
---

# Clean Code

Source: *Clean Code* — Robert C. Martin (Uncle Bob)

> "The only way to go fast is to keep the code clean."

## When to Use

- Writing a new function, class, or module and want to apply clean code from the start
- Refactoring existing code to improve readability or reduce complexity
- Naming a variable, function, or class and unsure if the name is clear enough
- Auditing a file for code smells
- Improving test quality using FIRST principles
- Applying Single Responsibility or other SOLID principles

## Workflow

### 1. Audit — Identify Violations

Scan the target code using [the rules reference](./references/rules.md). Look for violations in this priority order:

1. **Names** — unclear, abbreviated, misleading, or encoded names
2. **Functions** — too large, doing more than one thing, mixed abstraction levels
3. **Comments** — redundant, stale, or compensating for bad code
4. **Error handling** — returning null, using error codes instead of exceptions
5. **Classes** — too large, low cohesion, multiple responsibilities
6. **Tests** — missing, brittle, or violating FIRST
7. **Formatting / structure** — inconsistent vertical/horizontal spacing

### 2. Prioritize

| Priority | Issue type |
|----------|-----------|
| High | Incorrect behavior risk (null returns, swallowed exceptions, misleading names) |
| Medium | Maintainability (large functions, low cohesion, duplication) |
| Low | Polish (formatting, minor naming nits, unnecessary comments) |

### 3. Refactor — Iteratively

Apply changes in small steps. **Never make the code worse to make it cleaner.** After each step:
- Code must still pass all tests
- Each function must still do exactly one thing
- Run the full test suite before committing

### 4. Validate

- [ ] All names reveal intent without needing a comment to explain them
- [ ] Every function is small and does one thing at one level of abstraction
- [ ] No comments that explain *what* — only *why* when not obvious
- [ ] No null returns or null parameters
- [ ] Tests cover the changed code and follow FIRST
- [ ] No duplication (DRY)
- [ ] Classes have a single, clear responsibility

## Quick Rules (Full details in [rules.md](./references/rules.md))

### Names
- Use intention-revealing names: `elapsedTimeInDays` not `d`
- No abbreviations, encodings (`m_`, `I`), or type suffixes (`nameString`)
- Classes → nouns; Methods → verbs; Booleans → predicates (`isReady`, `hasError`)
- One word per concept: don't mix `fetch`/`retrieve`/`get` for the same operation

### Functions
- **Small** — ideally ≤ 20 lines, rarely more than one screen
- **Do one thing** — if you can extract a meaningful sub-function, the original did more than one thing
- **One level of abstraction** — don't mix high-level logic with low-level details in the same function
- **≤ 2 arguments** preferred; > 3 is a strong smell
- **No side effects** — a function named `checkPassword` must not also initialize a session
- **Command/Query separation** — a function either changes state or returns a value, not both

### Comments
- The best comment is no comment — rename or restructure until the code is self-documenting
- Acceptable: legal headers, intent explanation, warning of consequences, TODO
- Never: commented-out code, redundant restating of code, misleading or stale comments

### Error Handling
- Use exceptions, not return codes or error flags
- Never return `null` — throw an exception or use a Null Object / Optional
- Never pass `null` as an argument
- Wrap third-party APIs so exceptions are translated to domain types
- Provide context in exception messages

### Classes
- **Small** — measured by responsibilities, not line count
- **Single Responsibility Principle** — one reason to change
- **High cohesion** — instance variables used by most methods
- **Open/Closed** — open for extension, closed for modification
- Organize: public static constants → private static variables → private instance variables → public functions → private utilities

### Tests (FIRST)
- **Fast** — tests must run quickly or they won't be run
- **Independent** — no test depends on another
- **Repeatable** — same result in any environment
- **Self-Validating** — boolean pass/fail, no manual inspection
- **Timely** — written just before the production code (TDD) or at worst in the same PR

### Emergence (Kent Beck's 4 Rules, in priority order)
1. Runs all the tests
2. Contains no duplication
3. Expresses the intent of the programmer
4. Minimizes the number of classes and methods
