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
| Structural decision, new component, abstraction boundary | `design-patterns` |
| Changing behaviour, or adding feature / API / domain tests | `atdd-java` (Go: `atdd-go`) |
| Reviewing a diff, merge request, or PR | `code-review-practices` |
| After changing code in a repo with a SonarQube project | `sonarqube-validation` |
| Production errors, exceptions, "what is failing in prod" | `app-bug-detection` |
| Dotfiles, stow packages, symlinks, bootstrap | `dotfiles`, `stow` |
| Kubernetes, clusters, an environment's state | `kubectl` |
| Grafana, dashboards, PromQL / LogQL, alerting | `grafana` |
| Calling the Jira, GitLab, or Microsoft Graph APIs | `jira-api`, `gitlab-api`, `msgraph-go` |
| Neovim, LazyVim, tmux configuration | `neovim-lua`, `lazyvim`, `nvim-tmux` |
| Bitwarden CLI (`bw`), secrets upload/restore, vault scripting | `bitwarden-cli` |
| Adding or changing a skill, agent, command, AI rule, or MCP server | `ai-config` |
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

**Committing and history rewriting are prohibited.** The only exceptions are `ticket-to-merge`,
`/sonar-fix`, and `/bug-fix` while they are running. Reading history, diffs, status, blame, logs,
and branch state is always allowed.

Prohibited outside those three commands: `git commit` (including `--amend`); staging or unstaging
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
Common to all three: never `--no-verify`, never touch existing history, and never `--force` on a
shared branch without explicit authorization.

---

## Documentation

Documentation is part of the implementation, not a follow-up. When a change affects behaviour,
architecture, configuration, APIs, workflows, or developer experience, update the right source of
truth in the same change — the project `README.md`, its `/docs`, or the shared knowledge base.
Prefer updating an existing document over adding one, never duplicate content across two places,
and say explicitly when no documentation change is needed.

**Read `~/.claude/local/doc-repos.md`** before saying where documentation lives or referencing
another repository. If it is missing, use the project's own `README.md` and `/docs` and say the
documentation map is not configured — never guess at a repository name.

- Local clones are for file access only. Link across repositories with the remote URL from
  `git remote get-url origin`, never a local path.
- A repository marked read-only is strictly read-only: extract what you need into the current
  project's `/docs`, never edit it in place.
- Do not invent infrastructure facts an authoritative document already records — extract and cite.

