---
name: clean-code
description: "Readability and maintainability: naming, function and class design, formatting, error handling, test quality, code smells, SOLID, DRY, FIRST. Use when writing, refactoring, or reviewing code for clarity and complexity."
argument-hint: "file, function, or snippet to evaluate or improve"
---

# Clean Code

House rules, after *Clean Code* (Robert C. Martin). Language skills (`java-standards`) and the
project's conventions win where they are more specific. Comments: the documentation contract
(`CLAUDE.md` in Claude, the `documentation` rule in Cursor) — rename or extract instead of
explaining.

## Names

- Reveal intent: `elapsedTimeInDays`, not `d`. Searchable constants instead of magic numbers.
- No abbreviations, encodings (`m_`, `I` prefix), or type suffixes (`nameString`).
- Classes are nouns, never vague (`Manager`, `Processor`, `Data`, `Info`); methods are verbs;
  booleans are predicates (`isReady`, `hasError`).
- One word per concept — do not mix `fetch` / `retrieve` / `get`. No puns: separate names for
  separate semantics.

## Functions

- Small: rarely over 20 lines. Blocks inside `if` / `else` / `while` ideally one call.
- Do one thing, at one level of abstraction. If a sub-function can be extracted with a name that
  is not a restatement of the code, the original did more than one thing.
- Stepdown order: callers above callees, high level first.
- Arguments: 0–2; 3 is a smell; 4+ needs a reason. Related arguments become an object. No flag
  (boolean) arguments — split the function.
- No hidden side effects. Command/query separation: change state or return a value, not both.

## Error handling

- Exceptions, not return codes or error flags. Messages carry enough context to act on.
- Extract `try`/`catch` bodies into their own function; error handling is one thing.
- Define exception classes by how callers handle them. Translate third-party exceptions into
  domain ones at the boundary.
- Do not return or pass `null` where `Optional`, an empty collection, or an exception fits.

## Classes

- Small by responsibility, not lines: one reason to change. A name that needs "And" or "Or"
  has too many.
- High cohesion — most methods use most fields; low cohesion means split.
- Law of Demeter: no train wrecks (`a.getB().getC().doSomething()`).
- Separate construction from use: wiring lives in configuration, not in unrelated constructors.
- Member order: public static constants → private static fields → private instance fields →
  public methods, each followed by the private helpers it calls.

## Formatting

The project formatter owns layout; never fight it. Blank lines between concepts, none inside
one thought. Lines ≤ 120 characters.

## Tests

FIRST — fast, independent, repeatable, self-validating. One concept per test, given–when–then
structure, same care as production code.

## Smells

Rigidity, fragility, immobility, needless complexity, needless repetition, opacity. Duplication
is removed when it is real, not when two lines merely look alike.
