---
description: "Update third-party dependencies in three groups, one merge request per group or migration"
---

Keep third-party dependencies and build plugins current.

Load `change-delivery` with its `references/bot-run.md`. This command carries the git commit
exception: branches `chore/renovate-bot-<group>-<YYYYMMDD>`, pushed, with merge requests.

1. **Start** — `bot-run.md` §Start.
2. **Collect** — each third-party version declared in the build files, literal or property. A
   BOM or parent is one entry; its managed versions move with it. Find the newest stable release
   of each: `https://repo1.maven.org/maven2/<group/as/path>/<artifact>/maven-metadata.xml` in
   parallel for Maven and Gradle, `go list -u -m all`, `npm outdated`. Read the release notes of
   each update that is not a patch.
3. **Group**:
   - **`bump`**, no limit — no source change needed. One commit.
   - **`deprecation`**, at most 10 — replaces deprecated or removed calls, nothing more. One
     commit per dependency.
   - **`migration`**, at most 3 — a migration across the code. Its own subagent, branch and merge
     request each; the group is `migration-<artifact>`, the dependency's artifact id slugified.
4. **Run** — `bot-run.md`. Subject `chore-…`; body each dependency with old → new
   version.
