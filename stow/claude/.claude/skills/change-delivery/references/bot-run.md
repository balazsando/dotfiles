# Bot run

Read by `/sonar-bot`, `/bugfix-bot` and `/renovate-bot` on top of `SKILL.md`.

## Start

`SKILL.md` §1–2, then `git switch --detach origin/<base>`. Collect on this head, and branch
every group from it (`<head>`, from `git rev-parse HEAD`).

## Groups

Collect every item, sort it into the command's groups — an item that fits two goes to the
heavier — and fill each group up to its cap, highest impact first.

## Branch name

`<prefix>/<bot>-<group>-<YYYYMMDD>`, the run date in UTC, with the prefix and groups the command
lists. Every bot branch matches:

```
^(refactor|fix|chore)/(sonar|bugfix|renovate)-bot-[a-z0-9-]+-[0-9]{8}(-[0-9]+)?$
```

## Subagents

Spawn one subagent per non-empty group — or per item where the command says so — with the item
list, the branch name, `<head>`, the command's commit rule, `SKILL.md` §4–5, and this file. Each
subagent:

1. Creates its branch in its own worktree:
   `git worktree add --no-track -b <branch> ../<repo>-worktrees/<branch> <head>`.
2. Fixes each item with the smallest edit, loading the language skills the code needs.
3. Validates per `SKILL.md` §4. Reverts an item that fails or proves harder than its group, and
   hands it back.
4. Commits per the command, pushes, and opens a merge request (GitLab MCP, or `glab`) titled with
   the group, its description listing each item and, where behaviour changes, what changes.
5. Removes the worktree and returns the merge request URL and the dropped items.

Keep existing tests intact; change one only where the item's intended behaviour change requires
it, and name it in the merge request. The parent reports per `SKILL.md` §6, one line per group.
