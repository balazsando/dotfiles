# Bot run

Read by `/sonar-bot`, `/bugfix-bot` and `/renovate-bot` on top of `SKILL.md`.

## Start

`SKILL.md` §1–2, then `<head>` = `git rev-parse origin/<base>`. Collect in a detached worktree
at `<head>` (`git worktree add --detach "$wt" <head>`, `$wt` per §3 with branch `collect`),
removed once the groups are set. Every group branches from `<head>`.

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
list, the branch name, `<head>`, the command's commit rule, `SKILL.md` §3–6, and this file. Each
subagent:

1. Creates its worktree per `SKILL.md` §3, from `<head>` instead of `origin/<base>`.
2. Fixes each item with the smallest edit, loading the language skills the code needs.
3. Validates per `SKILL.md` §4. Reverts an item that fails, proves harder than its group, or
   survives three fix attempts, and hands it back.
4. Commits per the command, pushes, and opens a merge request (GitLab MCP, or `glab`) titled with
   the group, its description listing each item and, where behaviour changes, what changes.
5. Cleans up per `SKILL.md` §6 and returns the merge request URL and the dropped items.

Keep existing tests intact; change one only where the item's intended behaviour change requires
it, and name it in the merge request. The parent reports per `SKILL.md` §7, one line per group.
