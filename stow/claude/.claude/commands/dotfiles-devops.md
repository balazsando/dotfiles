---
description: "Organise, deploy, or troubleshoot a dotfiles repo — stow packages, symlinks, bootstrap"
argument-hint: "<question or task>"
---

Handle the dotfiles task in `$ARGUMENTS`; ask for one if it is missing. Goal: a fresh machine
comes up from one command, with no manual steps and no secrets in version control.

Load `dotfiles`. Java, Kubernetes, Grafana, or editor configuration inside the repo
goes to the skill that owns it.

## Steps

1. **Read before proposing** — the packages, `.stowrc`, `stow.sh`, `install.sh`, and any
   bootstrap scripts. Match what is there; never restructure a working repo to fit a preference.
2. **Diagnose from the filesystem** — `stow.sh -n` or `stow --simulate`, `readlink` on the
   suspect paths, the package's own tree. State what you observed before what you conclude.
3. **Change the smallest thing that fixes it.** A conflict is usually one file in the wrong
   package, not a reason to redesign the layout. Scripts stay idempotent, with a failure message
   per precondition and dry-run support where they change the filesystem.
4. **Verify** — re-run the simulation, check the symlinks resolve, and name the commands you ran.
