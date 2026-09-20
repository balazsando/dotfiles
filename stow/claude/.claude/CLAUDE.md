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
| Metrics, tracing, Observation API, Actuator, OTLP, Prometheus scrape | `micrometer` |
| Ports and adapters, layering, where a class belongs in a hexagonal service | `hexagonal-architecture` |
| Writing feature, API, or domain acceptance tests | `atdd` |
| Reviewing a diff, merge request, or PR | `code-review-practices` |
| Reading, creating, or updating a Jira ticket | `jira-tickets` |
| SonarQube issues, quality gate, or report | `sonarqube-validation` |
| Production errors, exceptions, "what is failing in prod" | `app-bug-detection` |
| Dotfiles, stow packages, symlinks, bootstrap | `dotfiles` |
| Kubernetes, clusters, an environment's state | `kubectl` |
| Grafana, dashboards, PromQL / LogQL, alerting | `grafana` |
| Neovim, LazyVim, tmux configuration | `lazyvim`, `nvim-tmux` |
| Bitwarden CLI (`bw`), secrets upload/restore, vault scripting | `bitwarden-cli` |
| Adding or changing a skill, agent, command, AI rule, or MCP server | `ai-config` |

Project conventions beat skill defaults. When no skill applies, say so rather than inventing a
process.

---

## Economy of words

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

## Machine-local overlay

Machine-local specifics — Jira project keys, boards, documentation repositories, cluster names —
live in `~/.claude/local/`, unversioned. Read the file a command or skill names; if it is
missing, ask rather than guess.

---

## Git operations

**Committing and history rewriting are prohibited.** The only exceptions are `/deliver`,
`/sonar-fix`, and `/bug-fix` while they are running. Reading history, diffs, status, blame, logs,
and branch state is always allowed.

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

**Never add tooling attribution** — no bot `Co-Authored-By` trailers, no `*-Session:` links, no
"Generated with" footers — to commits, tags, or merge request descriptions. The hook strips them
from commit messages as a safety net, but cannot touch MR descriptions and is bypassed by
`--no-verify`.

**Inside the exceptions**, each owns its own limits — read them there, they are not repeated here.
Common to all: never `--no-verify`, never touch existing history, and never `--force` on a
shared branch without explicit authorization.

---

## Documentation

- Never add comments. Exceptions: Javadoc, or the language's equivalent, on interfaces and
  contracts when the signature does not already convey the intent; `// given`, `// when`,
  `// then` markers in tests.
- Documentation lives in `/docs` and `README.md`.
