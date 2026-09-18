# Claude Code Global Instructions

Machine-wide rules. Project `CLAUDE.md` overrides them; repository documentation (`/docs`,
`README.md`, ADRs) overrides both.

This file routes, and it holds the standing contracts. Domain knowledge lives in skills, loaded
on demand.

---

## Routing

Read the skill file when the work starts; do not rely on memory. Skills live in
`~/.claude/skills/<name>/SKILL.md`.

| When | Load |
| --- | --- |
| Writing or changing Java / Spring / Maven code | `java-standards`, then `clean-code` |
| Micrometer meters, naming, tags, Observation API, or registries | `micrometer` |
| Spring Boot 4 observability wiring — Actuator, auto-instrumentation, OTLP, Prometheus scrape | `spring-observability`, then `micrometer` |
| Structural decision, new component, abstraction boundary | `design-patterns` |
| Ports and adapters, layering, where a class belongs in a hexagonal service | `hexagonal-architecture` |
| Changing behaviour, or adding feature / API or domain tests | `atdd` |
| Reviewing a diff, merge request, or PR | `code-review-practices` |
| Reading, creating, or updating a Jira ticket | `jira-tickets` |
| Running a command that branches, validates, and commits | `change-delivery` |
| After changing code in a repo with a SonarQube project | `sonarqube-validation` |
| Production errors, exceptions, "what is failing in prod" | `app-bug-detection` |
| Dotfiles, stow packages, symlinks, bootstrap | `dotfiles`, `stow` |
| Kubernetes, clusters, an environment's state | `kubectl` |
| Grafana, dashboards, PromQL / LogQL, alerting | `grafana` |
| Calling the Jira or GitLab APIs | `jira-api`, `gitlab-api` |
| Neovim, LazyVim, tmux configuration | `neovim-lua`, `lazyvim`, `nvim-tmux` |
| Bitwarden CLI (`bw`), secrets upload/restore, vault scripting | `bitwarden-cli` |
| Adding or changing a skill, agent, command, AI rule, or MCP server | `ai-config` |
| Multi-stage development work — feature, refactor, ticket | `/deliver` or `/ticket-to-merge`, which orchestrate the specialised agents |
| Orchestrating delivery agents — session directory, spawn, routing, status | `orchestration` |
| Running a delivery agent — reports, research, status, commits | `agent-workflow` |

Prefer the simplest solution and do not force a pattern; project conventions beat skill defaults;
say so plainly when no skill applies rather than inventing a process.

---

# Communication

Use simple English in the shortest form that is still complete and correct.

- Answer first. No preamble, restatement, or closing recap.
- Match length and structure to the content. Use headers and bullets only when they improve clarity.
- State each fact once.
- Match reasoning depth to difficulty. Simple tasks need simple reasoning.
- Cut filler, hedging, repetition, and obvious explanations.
- Do not explain what the user already knows.
- Ask only the clarifying question that is actually needed.
- Never remove a necessary caveat, edge case, question, or verification step to save words.
- Keep technical details, constraints, errors, and conclusions intact.
- Use exact code, commands, paths, identifiers, and error messages.
- A request for thoroughness or exhaustiveness overrides this rule.

The goal is not to say less. The goal is to say nothing unnecessary.

---

## Implementation

Understand the problem fully, then stop at the first solution that satisfies it.

Prefer, in order:

1. Nothing, if it does not need to exist.
2. Existing code in the codebase.
3. Standard library.
4. Platform or framework features.
5. Existing dependencies.
6. Simpler existing implementation.
7. Minimum necessary custom code.

- Read the relevant code and trace the real flow before implementing.
- Make the smallest correct change.
- Avoid speculative abstractions, extensibility, generalization, and future-proofing.
- Do not modify unrelated code.
- Never remove validation, error handling, security, accessibility, or data-loss protection to reduce code.
- Verify with appropriate tests or validation.

Lazy about the solution, never lazy about understanding the problem.

---

## Machine-local overlay

Machine-local specifics — Jira project keys, boards, documentation repositories, cluster names —
live in `~/.claude/local/`, unversioned. Read the file a command or skill names; if it is
missing, ask rather than guess.

---

## Git operations

**Committing and history rewriting are prohibited.** The only exceptions are `/deliver`,
`/ticket-to-merge`, `/sonar-fix`, and `/bug-fix` while they are running, and the agents they
spawn. Reading history, diffs, status, blame, logs, and branch state is always allowed.

Prohibited outside those commands: `git commit` (including `--amend`); staging or unstaging
(`git add`, `git rm --cached`, `git restore --staged`, index edits); any history-altering command
(`rebase`, `reset --hard`, `cherry-pick`, `revert`, `filter-branch`, `push --force`); creating,
deleting, or moving tags and branches. If asked to commit outside those exceptions, decline and
leave the changes unstaged for the user.

**Commit message format.** Write the subject as `category-message` and nothing else
(`feat-add widget`, `fix-bw upload session handling`). The `prepare-commit-msg` hook expands it to
`[TICKET] [emoji]([category]): [Message]` — deriving emoji, capitalising, and prefixing the ticket
parsed from the branch. Do not hand-write the expanded form and do not add the ticket yourself.
Categories: `feat` `fix` `docs` `chore` `refactor` `style` `test` `deploy` `typo` `revert`
`version`.

**Inside the exceptions**, each owns its own limits — read them there, they are not repeated here.
Common to all: never `--no-verify`, never touch existing history, and never `--force` on a
shared branch without explicit authorization.

---

## Documentation

- Never add comments.
- Javadoc, or the language-specific equivalent, on interfaces only.
- Documentation lives in `/docs` and `README.md`.
- Of the delivery agents, only `doc-writer-agent` edits `/docs` and `README.md`.
