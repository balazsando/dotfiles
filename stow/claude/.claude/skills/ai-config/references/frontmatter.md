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
description: "What it does, when to use it, and what it will not do"
tools: Read, Grep, Glob, Edit, Bash, mcp__server__tool   # omit = inherits everything
---
```

`tools:` is the capability fence — list the smallest set the responsibility needs. MCP tools go
in by full name (`mcp__jira__jira_get_issue`); there is no server-wide wildcard, and a name that
does not resolve is simply absent, so a missing server costs nothing. Omitting the key inherits
every tool the session has, which is what the old compound agents did and why they could commit,
write Jira, and reformat a repository from a review task.

Claude Code enforces `tools:`; treat Cursor's handling of it as unverified. State every limit in
the body as well — the `## Limits` section is the contract of record, the frontmatter is the
guard rail. `model:` is accepted too; leave it unset unless a role has a measured reason.

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
