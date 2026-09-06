# Frontmatter shapes — skill, agent, command, Cursor rule

## Frontmatter

**Skill** — `skills/<name>/SKILL.md`:
```yaml
---
name: kebab-case-name          # must match the directory name
description: "When to load this, in trigger terms — this is what routing matches on"
argument-hint: "what the caller should supply"
---
```

**Agent** — `agents/<name>-agent.md`:
```yaml
---
name: <name>-agent             # must match the filename
description: "What it does and when to use it"
---
```

**Command** — `commands/<name>.md`:
```yaml
---
description: "One line, shown in the command list"
argument-hint: "[--flag <v>] <required>"
---
```

**Cursor rule** — `rules/<name>.mdc`. Exactly one application mode:

```yaml
---
description: What this rule governs      # trigger text; required for Apply Intelligently
globs:                                   # Apply to Specific Files; omit for intelligent/always
  - "**/*.java"
  - "**/pom.xml"
alwaysApply: false                       # true = every chat; globs and description ignored
---
```

Write `globs` as a YAML list, one quoted pattern per line — the comma-joined string form is
ambiguous and easy to get wrong when a pattern grows.

| `alwaysApply` | `globs` | `description` | When it loads |
| --- | --- | --- | --- |
| `true` | — | — | Every chat |
| `false` | set | ignored | Matching file in context |
| `false` | omit | set | Agent decides from the description |
| `false` | omit | omit | Only when `@`-mentioned |

The skill `description` is the routing signal — write it as the situation that should trigger it,
not as a summary of the contents. Nothing reads a skill's prose to decide whether to load it.
