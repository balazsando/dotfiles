---
description: "Free a full Loki volume, fix the files a full disk broke, start Loki, and detach"
---

Break-glass recovery of a single-binary Loki on a filesystem object store whose volume is full.
Speed beats care: the alternative is wiping the volume. No dry runs.

Load `kubectl`. Read `~/.claude/local/work-environments.md`; missing → stop and say so.

## 1. Target

- Resolve the environment from the current monitoring checkout through the environment map. Not a
  monitoring checkout → ask which one.
- Prod → state the environment and confirm each mutating command, per `kubectl`.
- The user has already scaled the Loki deployment to 0. Not at 0 → stop and say so; never scale it
  down yourself.
- From the deployment, read the PVC claims, their mount paths, and the pod `securityContext`. From
  the Loki configmap, read `retention_period` and the chunk, index, and cache directories.

## 2. Shell pod

The Loki image has no `/bin/sh`. Use an image already in the namespace that has a shell (an
alpine-based one), so nothing new is pulled. Create pod `loki-fsck` that runs `sleep`, with the
deployment's `securityContext` and both PVCs mounted at the deployment's paths. Wait until it is
Ready.

## 3. Free space — one `exec`

Fixed rule: drop every index table that holds logs older than 7 days, and every chunk those tables
reference. No more, no less.

1. `df -h` on both mounts.
2. Table `index_<d>` (`<d>` = days since the epoch) covers `[d, d+1)` days. Drop every table with
   `d × 86400 < now − 7 × 86400` s. `F` = start of the oldest dropped table, `T` = end of the
   newest, both in ms.
3. Chunks: a chunk is referenced by every table its time range overlaps. Its key ends in
   `<from>:<through>:<checksum>`, hex ms. Delete every chunk with `from < T` and `through ≥ F`, in
   **one** `find | awk` pass (compare as hex strings, `F` and `T` zero-padded to the key's width),
   then empty directories. Never run a per-file shell loop: 150k files take more than 10 minutes.
   Keys not in that shape → stop and report; never select chunks by modification time.
4. Delete the dropped tables from the shipped index and from every cache directory.
5. Delete every zero-byte file under the index and compactor directories. A full disk leaves them,
   and on start Loki fails with `EOF` / `mmap, size 0`.
6. Print `df -h` again.

Never `pkill -f` a pattern that also appears in the `exec` script: it kills that shell.

## 4. Start and validate

Delete `loki-fsck` (the PVCs are RWO), scale to 1, `rollout status`, wait about 90 s, then read the
pod status and `level=error` lines.

- `Running` and no restarts → done. While agents resend their backlog, `ingestion rate limit
  exceeded` lines are expected.
- Crash → scale to 0, recreate `loki-fsck`, fix the file the error names (truncated `.gz` →
  `gzip -t`, then delete), and repeat this step.

## 5. Detach and report

Confirm `loki-fsck` is gone. Report the environment, the space freed, the tables dropped, the
chunks removed and how many of them also overlapped a kept table, and the pod state. Report
whether retention left anything older than the oldest table. Report the headroom:
`retention_period` × the daily rate (chunk bytes freed ÷ days dropped), against the PVC size. If
it does not fit, propose a lower retention or a larger volume in the values file.
Mention any drift between the live configmap and the values file.
