---
description: "Organise, deploy, or troubleshoot a dotfiles repo — stow packages, symlinks, bootstrap"
argument-hint: "<question or task>"
---

Handle the dotfiles task in `$ARGUMENTS`; ask for one if it is missing. Goal: a fresh machine
comes up from one command, with no manual steps and no secrets in version control.

Load `dotfiles`. Java, Kubernetes, Grafana, or editor configuration inside the repo
goes to the skill that owns it.

Read the packages, `.stowrc`, `stow.sh` and `install.sh` before proposing anything, and match
what is there — a conflict is usually one file in the wrong package, not a reason to redesign.
Scripts stay idempotent, with a failure message per precondition and a dry run where they change
the filesystem. Verify with `stow.sh -n` and `readlink` on the touched paths.
