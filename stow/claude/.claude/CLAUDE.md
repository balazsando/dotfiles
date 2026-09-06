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
| Adding or changing a skill, agent, command, or AI rule | `claude-config` |

Prefer the simplest solution and do not force a pattern; project conventions beat skill defaults;
say so plainly when no skill applies rather than inventing a process.

---

## Commands and agents

`/sonar-fix` and `/bug-fix` own their steps inline and use a skill for external data
(`sonarqube-validation`, `app-bug-detection`). Every other command only dispatches: it spawns
`<command>-agent`, relays the agent's output unabridged, and resumes that same agent via
SendMessage rather than spawning a second one.

The layers do not overlap. A command owns argument parsing, dispatch, and relaying. An agent owns
its workflow, output format, and constraints. A skill owns domain knowledge and any MCP server it
fronts. Never restate one layer's content in another — reference it.

Machine-local specifics — Jira project keys, boards, documentation repositories — live in
`~/.claude/local/`, unversioned. Read the file a command names; if it is missing, ask rather than
guess.

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

## MCP configuration

MCP servers are registered at user scope in `~/.claude.json`, managed by the `claude mcp` CLI —
never hand-edit it.

- Source of truth: `~/.claude/mcp-servers.json` — one config per server, no duplicates. Apply with
  `~/.claude/bin/install-mcp-servers.sh`.
- Registered: `sonarqube`, `jira`, `atlassian-rovo-mcp`, `gitlab`, and three distinct Grafana
  instances — `grafana` (the default non-prod instance, `$GRAFANA_URL`), `grafana-prep`
  (pre-prod), and `grafana-prod` (production, read-only; the only one `app-bug-detection`
  queries). After editing the source of truth, re-run the install script — a server added to the
  file but never applied is not registered.
- Prefer a plain `npx`/`uvx` entry over a launcher script. The one remaining launcher
  (`~/.local/share/dotfiles/scripts/jira-mcp.sh`) is shared with Cursor — edit it there, never fork
  a per-agent copy.
- Cursor keeps its own config at `~/.cursor/mcp.json`. The two are maintained separately and need
  not match line for line; keep the *server list* in step when adding or removing one.
- Never duplicate or commit sensitive configuration into project repositories.

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

---

## Working agreements

**Multi-step work** — understand the request, constraints, and repository first; break it into
steps; validate continuously rather than at the end; refactor once it is correct.

**Verification** — type checks and tests prove correctness, not that a feature works. For UI and
frontend changes, start the app (`/run`), use the feature, check the golden path and obvious edge
cases, and watch for regressions elsewhere. Use `/code-review` on a finished diff.
