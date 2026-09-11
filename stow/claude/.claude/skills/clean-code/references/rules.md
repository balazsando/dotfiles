# Clean Code Rules Reference

Source: *Clean Code* — Robert C. Martin

---

## Chapter 2 — Meaningful Names

| Rule | Bad | Good |
|------|-----|------|
| Reveal intent | `int d;` | `int elapsedTimeInDays;` |
| Avoid disinformation | `accountList` (if not a List) | `accounts` |
| Make meaningful distinctions | `getActiveAccount()` vs `getActiveAccounts()` vs `getActiveAccountInfo()` | one clear name |
| Use pronounceable names | `genymdhms` | `generationTimestamp` |
| Use searchable names | `7` (magic number) | `MAX_CLASSES_PER_STUDENT = 7` |
| No encodings / Hungarian | `m_description`, `IShapeFactory` | `description`, `ShapeFactory` |
| No mental mapping | single-letter loop vars (except `i`, `j`, `k` in tiny loops) | descriptive names |
| Classes → nouns | `Manager`, `Processor`, `Data`, `Info` (vague) | `Customer`, `WikiPage`, `Account` |
| Methods → verbs | `name()` | `getName()`, `setName()`, `isPosted()` |
| One word per concept | `fetch`/`retrieve`/`get` mixed | pick one and stick to it |
| No puns | `add()` meaning both "append" and "insert" | separate names for separate semantics |
| Domain names are fine | obscure abbreviations | `JobQueue`, `AccountVisitor` (pattern names) |
| Add meaningful context | `state` (ambiguous) | `addrState` or better: an `Address` class |

---

## Chapter 3 — Functions

### Size
- Functions should be **small**. Rarely more than 20 lines.
- Blocks inside `if`, `else`, `while` should ideally be one line (a function call).

### Do One Thing
> "Functions should do one thing. They should do it well. They should do it only."

- If you can extract another function with a name that is not a restatement of the implementation, the original function does more than one thing.

### One Level of Abstraction Per Function
- Don't mix `getHtml()` (high-level) with `append("\n")` (low-level) in the same function.
- The **Stepdown Rule**: code should read like a newspaper — high-level summaries at the top, details below.

### Arguments
| Count | Verdict |
|-------|---------|
| 0 (niladic) | Ideal |
| 1 (monadic) | Good |
| 2 (dyadic) | Acceptable |
| 3 (triadic) | Avoid if possible |
| 4+ (polyadic) | Requires exceptional justification |

- **Flag arguments** (boolean params) are ugly — they declare the function does two things. Split it.
- If multiple args are related, wrap them in an object: `makeCircle(Point center, double radius)` not `makeCircle(double x, double y, double radius)`.

### Side Effects
- A function named `checkPassword` must not also initialize a session. That's a hidden side effect.
- **Command/Query Separation**: functions either *do* something (command) or *answer* something (query), never both.

### Error Handling
- Extract try/catch bodies into their own functions.
- Error handling *is* one thing — a function that handles errors should do nothing else.

### DRY — Don't Repeat Yourself
- Duplication may be the root of all evil in software. Every duplication is a maintenance risk.

---

## Chapter 4 — Comments

The documentation rule in `~/.claude/CLAUDE.md` decides what may exist: no comments, and
documentation on interfaces only. What remains here is cleanup — delete redundant, misleading,
mandated, journal, noise, commented-out and nonlocal comments as you find them, and rename or
extract instead of explaining.

---

## Chapter 5 — Formatting

### Vertical
- **Openness** — blank lines between concepts (imports, class sections, methods)
- **Density** — related lines are close together, no blank lines inside a single logical thought
- **Distance** — functions called by a function should be close to it (caller above callee)
- **Ordering** — high-level functions first; important declarations at the top

### Horizontal
- Lines should be short — aim for ≤ 120 characters; never scroll horizontally
- Spaces around operators: `a + b` not `a+b`
- No spaces between function name and `(`: `function(args)` not `function (args)`
- Consistent indentation — never fight the formatter; configure and commit to it

---

## Chapter 6 — Objects and Data Structures

| Aspect | Objects | Data Structures |
|--------|---------|-----------------|
| Hides | Implementation | Nothing (data is public) |
| Exposes | Behavior | Data |
| Easy to add | New types (no existing code changes) | New functions |
| Hard to add | New functions (all types must change) | New types |

- **Law of Demeter**: a method of class C should only call methods on: C itself, objects created inside the method, objects passed as arguments, objects held in instance variables.  
  Violation → "train wrecks": `a.getB().getC().doSomething()`

---

## Chapter 7 — Error Handling

- **Use exceptions, not return codes.** Callers can ignore return codes; exceptions cannot be silently ignored.
- **Write `try-catch-finally` first** when writing code that can throw — defines the scope and guarantees.
- **Provide context**: exception messages should contain enough info to understand the failure.
- **Define exception classes by caller need** — how the caller catches and handles them matters more than their source.
- **Don't return `null`** — throw an exception or return a Null Object / empty collection / Optional.
- **Don't pass `null`** — if a method receives null and doesn't expect it, it will fail later in a confusing way.
- Wrap third-party libraries: catch their exceptions and translate to your domain exceptions.

---

## Chapter 8 — Boundaries

- Write **learning tests** for third-party APIs — small, focused tests that verify your understanding.
- Define your own interface for external systems you don't control yet.
- Keep third-party code at the boundary; don't let it bleed into your domain.

---

## Chapter 9 — Unit Tests (FIRST)

| Letter | Property | Detail |
|--------|----------|--------|
| F | Fast | Tests must run in milliseconds; slow tests aren't run |
| I | Independent | No test relies on another; any order must work |
| R | Repeatable | Same result in dev, CI, offline, any environment |
| S | Self-Validating | Pass or fail — no manual log inspection needed |
| T | Timely | Written before or alongside production code (TDD), at worst in the same PR |

### Clean Test Rules
- **One assert per test** (or at least one concept per test)
- **Build-Operate-Check** (Given-When-Then) structure
- Tests are **first-class citizens** — they get the same care as production code
- A dirty test suite is as bad as no tests

---

## Chapter 10 — Classes

### Size
- Measured in **responsibilities**, not lines.
- If you struggle to name the class without using "And", "Or", "Manager", "Processor" — it has too many responsibilities.

### Single Responsibility Principle (SRP)
- A class should have **one reason to change**.
- Common violation: a class that manages both business logic and persistence.

### High Cohesion
- Instance variables should be used by most methods.
- Low cohesion → split the class.

### Open/Closed Principle (OCP)
- Open for extension, closed for modification.
- New behavior via new classes/interfaces, not modifications to existing ones.

### Organizing for Change
- Isolate concrete details behind interfaces so changes are contained.
- `DIP` (Dependency Inversion): depend on abstractions, not concretions.

### Standard Class Organization
```
public static constants
private static variables
private instance variables
─────────────────────────
public functions
  private utilities called by the public function above
```

---

## Chapter 11 — Systems

- **Separate construction from use**: application startup wiring is different from runtime logic. Use factories, DI containers, or main methods to build the object graph.
- Don't build objects in constructors of unrelated classes — that couples construction to use.

---

## Chapter 12 — Emergence (Kent Beck's 4 Rules)

In priority order:

1. **Runs all the tests** — a system that cannot be tested cannot be verified.
2. **No duplication** — the primary enemy of a well-designed system.
3. **Expresses intent** — the code should clearly communicate what it does.
4. **Minimizes classes and methods** — avoid dogmatic over-abstraction.

---

## Chapter 13 — Concurrency

- Keep concurrency-related code **separate** from other code.
- **Limit scope of shared data** — use the fewest shared data structures possible.
- Use **copies of data** rather than sharing where feasible.
- Make threads as **independent as possible** — each thread works on its own world.
- Know your platform's threading primitives; don't roll your own.
- Test concurrency code under stress conditions — bugs are often timing-sensitive.

---

## Code Smells Quick Reference

| Smell | Description |
|-------|-------------|
| Rigidity | Changing one thing requires changing many others |
| Fragility | Changes break unrelated things |
| Immobility | Code can't be reused without taking too much with it |
| Viscosity | Doing the right thing is harder than the hack |
| Needless complexity | Infrastructure for problems that don't exist |
| Needless repetition | Duplicated code |
| Opacity | Code that is hard to read and understand |
