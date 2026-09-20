---
description: "Create a technical backlog Jira ticket from a short prompt"
---

Turn the text after `/create-tech-ticket` into one technical backlog ticket. Empty → ask what it
should cover.

Load `jira-tickets` — it owns the MCP tool chain, `~/.cursor/local/jira-conventions.md`, the
approval gate, and the grounding rule. This command owns the scope inference and the format.
Jira only; no repository changes.

## Scope

The scope table in the conventions file drives both the summary tag and the component.

1. Match the prompt's repository or service hints against the table.
2. A prompt spanning several areas takes the **primary** change location; secondary scope goes in
   Context.
3. Ambiguous between two areas, or too vague for testable criteria → **one** focused question,
   then draft.
4. Never fall back to the most common scope.

## Description

```markdown
## User Story

**As a** <role>
**I want** <capability or change>
**So that** <business or technical benefit>

---

## Context

<Background, motivation, constraints, scope.>

---

# Acceptance Criteria

## <Section name>

<Numbered, testable criteria, grouped by functional area.>

## Definition of Done

* <Concrete completion checks>
```

Criteria are testable and specific, and cover edge cases, regression scope, and non-functional
checks when they apply. Reuse a reference ticket's structure, never its content.

## Draft, then create

```
**Summary:** [TECH][AREA] Title
**Project:** $JIRA_PROJECT_KEY | **Type:** Task | **Label:** TECH | **Priority:** Normal
**Component:** <from the scope table, or none>   **Backlog:** TECH Backlog

### Description
<full description>
```

After the yes, create through the `jira-tickets` write chain and place it on the TECH Backlog with
the sprint id and field from the conventions file's **TECH Backlog sprint** section. Report the
key, URL, summary, placement result, and any field that could not be set.
