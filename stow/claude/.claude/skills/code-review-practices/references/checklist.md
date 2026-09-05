# Code Review Checklist

Reference: [Google Engineering Practices](https://google.github.io/eng-practices/review/reviewer/looking-for.html)

## Design

- Does the overall architecture of the change make sense?
- Does this change belong in this codebase, or should it be a library / separate service?
- Does it integrate cleanly with the rest of the system?
- Is now the right time to add this functionality?

## Functionality

- Does the code do what the developer intended?
- Is what was intended good for end-users and future developer-users?
- Edge cases handled?
- No obvious bugs readable from the code?
- UI changes: are they sensible, do they look correct? (Consider requesting a demo.)

## Complexity

- No individual line, function, or class that is harder to understand than it needs to be?
- No over-engineering — solving a speculative future problem instead of the known current one?
- No unnecessary abstractions or generics?

## Tests

- Appropriate test level added: unit / integration / e2e?
- Tests are in the same CL as production code (except emergencies)?
- Tests are correct — do they actually fail when code breaks?
- No false positives — tests pass for wrong code?
- Tests make simple, focused assertions?
- Tests themselves are not overly complex?

## Naming

- Names fully communicate what the item is or does?
- Not so long they become hard to read?

## Comments

- Comments explain *why*, not *what*?
- If a comment explains *what*, can the code be simplified instead?
- No outdated TODOs or comments that contradict the new code?
- Complex algorithms / regex: comments explaining logic are appropriate here.

## Style & Consistency

- Follows the project / language style guide?
- Personal style preferences that aren't in the guide → `Nit:` only, never blocking.
- If existing code is inconsistent with the style guide, encourage the author to file a bug/TODO rather than mixing style changes into this CL.
- Author should not include mass reformatting mixed with functional changes.

## Documentation

- READMEs, API docs, or other docs updated if the change affects:
  - How to build, test, interact with, or release the code?
  - Public interfaces or behavior?
- Deprecated / deleted code: check if associated documentation should also be removed.

## Security (OWASP Top 10)

- **Injection**: No unsanitized user input in SQL, shell commands, or eval?
- **Broken Auth**: Auth checks present and correct? No hardcoded credentials?
- **Sensitive Data**: No secrets, tokens, or PII logged or exposed?
- **Access Control**: Authorization enforced at every relevant endpoint/function?
- **Cryptography**: Using well-known libraries? No homebrew crypto?
- **Dependencies**: No newly introduced dependency with known vulnerabilities?
- **Error handling**: Errors don't leak stack traces or internal details to users?

## Concurrency

- No race conditions?
- No potential deadlocks?
- Locking / synchronization is minimal and correct?

## Context

- Read the change in the context of the full file, not just the diff hunk.
- Is the change improving or degrading overall system code health?
- Does the changed function/class still need to be broken up after this addition?

## Mentoring Opportunities

- If a comment is purely educational and not blocking, prefix with `Nit:` or `FYI:`.
- Acknowledge good practices explicitly — reinforcement is as important as correction.
