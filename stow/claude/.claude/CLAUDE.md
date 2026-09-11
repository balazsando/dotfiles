# Claude Code Global Instructions

Machine-wide rules. Project `CLAUDE.md` overrides them; repository documentation (`/docs`,
`README.md`, ADRs) overrides both.

This file routes — it does not teach. Domain rules live in skills, loaded on demand.

---

## Routing

Read the skill file when the work starts; do not rely on memory. Skills live in
`~/.claude/skills/<name>/SKILL.md`.

| When | Load |
| --- | --- |
| Exploring an unfamiliar or large codebase — "how does X connect to Y" | `graphify` (`/graphify .`, then `graphify query`) |
| Writing or changing Java / Spring / Maven code | `java-standards`, then `clean-code` |
| Micrometer meters, naming, tags, Observation API, or registries | `micrometer` |
| Spring Boot 4 observability wiring — Actuator, auto-instrumentation, OTLP, Prometheus scrape | `spring-observability`, then `micrometer` |
| Structural decision, new component, abstraction boundary | `design-patterns` |
| Ports and adapters, layering, where a class belongs in a hexagonal service | `hexagonal-architecture` |
| Changing behaviour, or adding feature / API / domain tests | `atdd` |
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
| Running or writing a delivery agent — reports, questions, status | `agent-workflow` |
| Long-form output — report, plan, summary — or a context-heavy session | `economy-of-words` |

Prefer the simplest solution and do not force a pattern; project conventions beat skill defaults;
say so plainly when no skill applies rather than inventing a process.

---

## Economy of words

Simple English, in the shortest form that is still complete and correct.

- Answer first. No preamble, no restating the question, no closing recap.
- Match length and structure to the content. Headers and bullets are for genuinely multi-part
  answers, not for two sentences.
- State each fact once — not in the intro, the body, and the conclusion.
- Match reasoning depth to difficulty. A lookup does not need deliberation.
- Search before reading, read line ranges, and carry a conclusion forward rather than the
  evidence it came from.
- When editing a file, cut what adds nothing rather than carrying it forward.
- Never trade away a caveat, an edge case, a needed question, or a verification run to save
  words.

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

**Never add tooling attribution** — no bot `Co-Authored-By` trailers, no `*-Session:` links, no
"Generated with" footers — to commits, tags, or merge request descriptions. The hook strips them
from commit messages as a safety net, but cannot touch MR descriptions and is bypassed by
`--no-verify`.

**Inside the exceptions**, each owns its own limits — read them there, they are not repeated here.
Common to all: never `--no-verify`, never touch existing history, and never `--force` on a
shared branch without explicit authorization.

---

## Documentation

- Never add comments.
- Javadoc, or the language-specific equivalent, on interfaces only.
- Documentation lives in `/docs` and `README.md`.
- In a flow that includes `doc-writer-agent`, it owns `/docs` and `README.md` — the other
  agents leave them alone. A flow without it edits them directly.
