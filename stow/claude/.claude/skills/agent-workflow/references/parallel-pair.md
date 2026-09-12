# Parallel developer and test engineer

Only against the architect's stubs, with isolated trees. The developer works in the main
worktree, the test engineer in its own (`git worktree add --detach <path> HEAD`), off the files
the developer owns. Both commit in their own tree; neither merges.

Return `PAUSED`, not `DONE`, until resumed on the merged tree. What you cannot fix from the test
side goes to the developer as `test-fail.md`.
