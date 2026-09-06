---
name: economy-of-words
description: "House standard for long-form output — reports, plans, summaries, documentation — and for keeping a session's context lean: what to cut from a deliverable, how to scope a tool call, and when to write notes to a file instead of carrying context. The brevity floor itself is an always-on rule; read this when the output is long-form or the session is accumulating context."
---

# Economy of words

The floor is an always-on rule and holds without this file: answer first, each fact once,
structure proportional to the content, and never cut a caveat, a needed question, or a
verification to save words. This is the rest.

## Deliverables

Length signals nothing about quality.

- Cut hedges and filler: *it's worth noting that*, *in order to*, *I hope this helps*.
- Do not explain what the question shows the reader already knows.
- One clarifying question if one is needed, not three in case.
- A request to be thorough or exhaustive overrides all of this.

## Tool use and context

Each call costs a model turn plus whatever it returns into context.

- Scope the query — a filter or a line cap beats a full dump.
- Summarise tool output or cite `file:line`; never paste it back in full.
- Delegate to a subagent to keep bulk data out of context, not to offload thinking — and give it
  everything it needs to succeed on the first try.
- Context is an attention budget, not storage. A window full of half-relevant dumps reasons worse
  than a small one — a correctness problem before a cost one.
- Retrieve just in time, not just in case.
- For long work, write decisions and the remaining plan to a file. Notes survive compaction;
  context does not.

## Before sending

The floor again, as a check:

Would deleting the first sentence lose anything? Does the last paragraph repeat the body? Is the
structure proportional to the content? Did a caveat get cut to save words — if so, put it back.
