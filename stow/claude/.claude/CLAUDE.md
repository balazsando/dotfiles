# Claude Code Global Instructions

Project-level CLAUDE.md files override these global rules.
If repository documentation exists (`/docs`, `README.md`, architecture notes, ADRs), that takes precedence over both.

---

# 1. Dependency Injection Rules

Use constructor injection by default.

- Prefer constructor injection in all cases
- Avoid field injection unless explicitly required by a framework
- Do not use `@Autowired` on constructors when a single constructor exists
- Dependencies must be passed via constructor parameters
- Dependency fields should be `final` whenever possible
- Avoid setter injection unless explicitly required by a framework

---

# 2. Coding Guidelines

General principles:

- Follow SOLID, DRY, YAGNI, and KISS principles
- Keep classes small, cohesive, and focused
- Use domain-driven naming
- Avoid unnecessary complexity
- Prefer maintainability over cleverness

Modern Java usage:

- Use modern Java (21+) features when they improve readability, safety, or maintainability
- Do not use newer language features if they reduce clarity

Preferred:

- Clear and explicit logic
- Readable and maintainable code
- Predictable control flow
- Low cognitive overhead

Avoid:

- Overly complex functional chains
- Unnecessary abstractions
- Hidden side effects
- Clever but hard-to-read solutions
- Premature optimization

Lombok:

- Allowed for boilerplate reduction
- Avoid overuse in complex logic
- Do not hide important behavior behind annotations

---

# 3. Separation of Concerns

- Do not mix business logic with infrastructure concerns
- Do not place persistence, HTTP, or framework logic inside domain models
- Keep classes focused on a single responsibility
- Avoid god classes handling multiple responsibilities
- Prefer clear layering even in simple projects
- Keep boundaries explicit and enforceable

---

# 4. Testing Guidelines

Testing rules:

- Test behavior, not implementation details
- Prefer testing observable outcomes
- Mock only external dependencies
- Avoid over-mocking
- Keep tests readable and deterministic

Test structure:

- Use given / when / then structure
- Prefer parameterized tests when multiple inputs validate the same behavior

TDD preference:

- Prefer test-first iterations when practical
- Write failing tests → implement minimal fix → refactor safely

---

# 5. Maven Dependency Management

- Define shared versions in parent dependency management
- Do not duplicate versions in child modules
- Align dependency versions across modules
- Avoid unnecessary transitive dependencies
- Respect scope separation: compile, test, provided, optional

---

# 6. Code Generation and Refactoring Behavior

- Identify correct architectural layer before changes
- Preserve existing behavior unless explicitly requested otherwise
- Prefer incremental refactoring
- Remove duplication when safe
- Do not introduce new architecture unless justified
- Keep changes simple and maintainable

---

# 7. Claude Code Workflow

For multistep tasks:

- Understand request, constraints, and repository context first
- Break work into steps
- Use TDD where applicable
- Validate continuously during execution
- Refactor safely after correctness is established
- Ensure final output is production-ready

Key Claude Code features to leverage:

- Use Agent tool for complex, multi-step tasks that benefit from specialized agents
- Use Bash tool for shell operations; prefer dedicated tools (Read, Edit, Write) when they fit
- Use TaskCreate/TaskUpdate for tracking progress on complex work
- Use Artifact for visual communication (HTML, Markdown dashboards)
- Use /code-review for code review tasks
- Use /verify skill to validate changes work end-to-end
- Use /run skill to test changes in the live app

---

# 8. Nullability Annotations

- Use `@NotNull` for non-null contracts
- Use `@Nullable` only when null is explicitly allowed
- Prefer `Optional` for explicit absence modeling
- Avoid ambiguous null usage

---

# 9. Coding Skills Workflow

For every coding task (implementation, refactoring, bug fix, or test work), load these skills
before writing code — read the skill file when the task starts, do not rely on memory:

- `design-patterns` — structural decisions, abstraction boundaries, pattern evaluation
- `atdd-java` (or `atdd-go`) — behavior changes, feature/API/domain tests
- `clean-code` — naming, function size, readability, code smells

Rules:

- Prefer the simplest solution; do not force a pattern. If no pattern adds value, say so and implement plainly.
- Write or update a failing scenario first when practical (red → green → refactor).
- If Cucumber/Godog is not present and the change is trivial, use the project's existing test style — but keep given/when/then structure.
- Project conventions win over skill defaults when they conflict.

---

# 10. Slash Commands

These are available as slash commands, invoke them directly. Each spawns the matching
agent in `~/.claude/agents/`:

- `/ticket-to-merge` — implement a Jira ticket end-to-end and open a merge request
- `/jira-mr-reviewer` — review a merge request against its linked Jira ticket
- `/create-tech-ticket` — create a technical backlog ticket from a short prompt
- `/enhance-jira-description` — rewrite a Jira description into a sourced user story
- `/dotfiles-devops` — consult the dotfiles DevOps specialist for stow/bootstrap work

---

# 11. General Constraints

- Prefer explicit code over implicit behavior
- Avoid hidden side effects
- Avoid overengineering
- Keep solutions simple and maintainable
- Make changes intentional and traceable

---

# 12. Formatting Rules

- Use Eclipse formatter (`./formatter.xml`) if present otherwise use global formatter rules (`~/.java/formatter.xml`)
- Always use LF line endings
- Prefer early returns over deep nesting
- Do not manually reformat code
- Insert one empty line before `return` or `throw` (unless block is trivial)

---

# 13. Git Operations

**Committing and history rewriting are prohibited.** The single exception is the
`ticket-to-merge` command/agent while it is running.

## Always allowed

- Read git history, diffs, status, blame, logs, and branch state

## Prohibited (outside `ticket-to-merge`)

- `git commit` in any form, including `--amend`
- Staging or unstaging — `git add`, `git rm --cached`, `git restore --staged`, index edits
- Any history-altering command: `rebase`, `reset --hard`, `cherry-pick`, `revert`, `filter-branch`, `push --force`
- Creating, deleting, or moving tags and branches

If asked to commit outside that exception, decline and say the work is staged for the user to
commit themselves. Leave the working tree with the changes in place; do not stage them.

## Commit message format

Write the commit subject as `[category]-[message]` and nothing else:

```
feat-add widget
fix-bw upload session handling
docs-update install steps
```

The `prepare-commit-msg` hook expands that into
`[TICKET] [emoji]([category]): [Message]` — it derives the emoji, capitalises the
title, and prefixes the ticket key parsed from the branch name.

- Do **not** hand-write the expanded form; the hook only transforms subjects
  matching `^[a-zA-Z]+-.+`, so a pre-formatted subject is left untouched.
- Do **not** add the ticket key manually — it comes from the branch.
- Categories: `feat` `fix` `docs` `chore` `refactor` `style` `test` `deploy`
  `typo` `revert` `version`.

Never add tooling attribution — no bot `Co-Authored-By` trailers, no
`*-Session:` links, no "Generated with" footers — to commits, tags, or merge
request descriptions. The hook strips them from commit messages as a safety net,
but it cannot touch MR descriptions and is bypassed by `--no-verify`.

## Inside `ticket-to-merge`

The agent owns the full branch → commit → push → merge request flow. Within that run:

- Commit and push freely on its own feature branch
- Never `--force` on `main`/`master`/`develop` without explicit user authorization
- Never skip hooks (`--no-verify`) without an explicit user request
- Write commit messages that explain the "why" behind the change
- Ask before pushing to any shared branch

---

# 14. MCP Configuration

MCP servers are registered at user scope in `~/.claude.json` (managed by the `claude mcp` CLI, not hand-edited).

- Source of truth for this dotfiles setup: `~/.claude/mcp-servers.json` — exactly one MCP config per agent, no duplicates
- Apply/refresh registration by running: `~/.claude/bin/install-mcp-servers.sh`
- Stdio launcher scripts are shared with Cursor and live in `~/.local/share/dotfiles/scripts/` (`jira-mcp.sh`, `sonarqube-mcp.sh`) — edit them there, never fork a per-agent copy
- Cursor's equivalent config is `~/.cursor/mcp.json`; keep the two server lists in step when adding or removing a server
- Do not duplicate or commit sensitive configuration in project repositories
- When updating MCP integrations, edit `mcp-servers.json` in the dotfiles repo, then re-run the install script — never hand-edit `~/.claude.json` directly

---

# 15. Documentation Repositories and Maintenance

Documentation is considered part of the implementation.

## Documentation repositories

The documentation repositories for this machine — their canonical URLs, roles, and any
read-only restrictions — are configured per machine, not versioned here.

**If `~/.claude/local/doc-repos.md` exists, read it and follow it** before answering anything
about where documentation lives or writing docs that reference another repository. If it is
missing, use the project's own `README.md` and `/docs` and say the wider documentation map is
not configured, rather than guessing at repository names or URLs.

Whatever that file lists, these rules always hold:

- Local clones are for agent file access only — **never** put local filesystem paths into shared
  markdown that colleagues will follow.
- When linking across repositories, resolve `git remote get-url origin` and use the full remote
  URL. Never reference `~/...` or absolute local paths in shared docs.
- Treat any repository the local file marks read-only as strictly read-only: no edits, no
  commits, no merge requests, no "improvements" in place. Read it, then extract what you need
  into the project's own `/docs`.
- Do not invent infrastructure facts when an authoritative document already records them —
  extract and cite it instead.

## Maintenance rules

When making changes that affect behavior, architecture, configuration, APIs, workflows, or developer experience:

- Always determine whether existing documentation requires updating
- Prefer updating existing documentation instead of creating new files whenever appropriate
- Keep documentation synchronized with the implemented code
- Update the most appropriate source of truth:
  - Project `README.md`
  - Existing files under the project's `/docs` directory
  - The shared knowledge-base repository listed in `~/.claude/local/doc-repos.md`, for reusable business knowledge, architecture, standards, or workflows
  - Cross-check / extract from the architecture-document repository listed there (read-only) when the change touches deployment, environments, networking, or platform topology
- Do not duplicate documentation across multiple locations unless explicitly justified
- If no documentation update is necessary, explicitly state why
- Documentation changes should be completed as part of the same implementation whenever possible

---

# 16. Claude Code Specific Guidance

### Tool Usage

- **Read/Edit/Write tools:** Use these for file operations instead of cat/sed when possible
- **Bash tool:** Use for shell operations that don't fit dedicated tools
- **Agent tool:** Spawn agents for complex multi-step tasks, research, or parallel work
- **Artifact tool:** Render visual outputs (HTML, Markdown) for dashboards, diagrams, etc.

### Feature-First Verification

For UI and frontend changes:

- Start the dev server and use the feature in a browser before reporting completion
- Test the golden path and edge cases
- Monitor for regressions in other features
- Type checking and tests verify correctness, not feature correctness

### When to Ask Confirmation

Ask before risky actions:

- Destructive operations (delete files, drop tables, force-push)
- Hard-to-reverse operations (amend published commits, reset --hard)
- Actions visible to others (push to shared branches, comment on PRs/issues)
- Uploading to third-party services (sensitive content)

---
