---
name: stow
description: "GNU Stow: structuring a stow directory, stowing/unstowing/restowing packages, resolving conflicts, --dotfiles mode, .stowrc, ignore lists, mixing -S/-D/-R in one invocation, multiple stow directories, and --adopt."
argument-hint: "Describe the Stow task (e.g., 'stow my zsh config', 'unstow a package', 'resolve a conflict', 'set up dotfiles repo with stow', 'use --dotfiles flag', 'ignore README files', 'adopt existing dotfiles')"
---

# GNU Stow Skill

## Purpose
GNU Stow (v2.4.1) is a **symlink farm manager**. It takes packages living in separate subdirectories of a *stow directory* and symlinks their contents into a single *target directory* — typically `$HOME` for dotfiles, or `/usr/local` for compiled software.

> Stow stores **no state** between runs — it is always safe to re-run.
> Stow will **never delete** any files, directories, or links inside the stow directory.

Manual: https://www.gnu.org/software/stow/manual/stow.html

**Detail lives in `references/manual.md`** — terminology and path anatomy, installation, the two
repo layouts (classic and `--dotfiles`), tree folding, ignore lists, `.stowrc`, multiple stow
directories, and `chkstow`. Read it when the task needs more than the operations below.

---

## Command Syntax

```
stow [options] [action-flag] package ...
```

### Action flags

| Flag | Long form | Description |
|---|---|---|
| *(default)* | `-S` / `--stow` | **Stow** — create symlinks in the target directory |
| `-D` | `--delete` | **Unstow** — remove symlinks from the target directory |
| `-R` | `--restow` | **Restow** — unstow then stow again; prunes stale symlinks |

### Options

| Flag | Description |
|---|---|
| `-d DIR` / `--dir=DIR` | Set stow directory (default: `$STOW_DIR` env var, or current dir) |
| `-t DIR` / `--target=DIR` | Set target directory (default: parent of the stow directory) |
| `-n` / `--no` / `--simulate` | **Dry run** — show what would happen without changing anything |
| `-v` / `--verbose[=N]` | Verbose output (levels 0–5); `-v` increments by 1 |
| `--dotfiles` | Map `dot-foo` → `.foo` in target (dotfiles mode) |
| `--no-folding` | Always create real directories; disable tree folding |
| `--adopt` | Move existing plain files into the package, then stow *(modifies stow dir!)* |
| `--ignore=REGEXP` | Skip files matching Perl regexp (anchored at end of filename) |
| `--defer=REGEXP` | Skip if already stowed by another package (lower precedence) |
| `--override=REGEXP` | Force overwrite of files already stowed by another package |
| `-V` / `--version` | Print version and exit |
| `-h` / `--help` | Print help and exit |

---

## Common Usage Patterns

### Basic stow / unstow / restow

```bash
cd ~/dotfiles

stow zsh                          # stow (default action)
stow -D zsh                       # unstow (remove symlinks)
stow -R zsh                       # restow (prune + re-link)

stow -nv zsh                      # dry run with verbose output
stow -nvR zsh                     # dry run of restow
```

### Explicit dirs (safe from any cwd)

```bash
stow -d ~/dotfiles -t ~ zsh
stow -d ~/dotfiles -t ~ -R nvim tmux git
```

### Stow all packages at once

```bash
cd ~/dotfiles
stow */                           # every subdirectory as a package
```

### Mix operations in one command

```bash
# Unstow old vim, stow neovim — single atomic pass
stow -D vim -S nvim

# Restow zsh, add new git package
stow -R zsh -S git
```

---

## Adopting Existing Files (`--adopt`)

When a plain file already exists at the target (not owned by any Stow package), Stow normally refuses with a conflict. `--adopt` moves the file *into* the stow package first, then creates the symlink.

```bash
# Scenario: ~/.zshrc exists but ~/dotfiles/zsh/.zshrc does not yet
stow --adopt zsh

# Result:
# - ~/.zshrc is moved to ~/dotfiles/zsh/.zshrc
# - ~/.zshrc becomes a symlink → ../dotfiles/zsh/.zshrc

# Review what changed, then commit:
git -C ~/dotfiles diff
git -C ~/dotfiles add zsh/.zshrc
git -C ~/dotfiles commit -m "chore: adopt zshrc"
```

> ⚠️ `--adopt` **modifies files inside your stow directory**. Always review with `git diff` afterwards.

---

## Conflicts

A **conflict** occurs when Stow wants to create a symlink but the path already exists as:
- a plain file not owned by any Stow package, or
- a symlink pointing to a different Stow package.

Stow uses **deferred operation** — it plans the entire operation first and reports *all* conflicts before aborting. No partial changes are made.

### Resolving conflicts

| Situation | Fix |
|---|---|
| Plain file exists, you want to absorb it | `stow --adopt PKG` then `git diff` |
| Plain file exists, you want to keep both | `mv ~/.file ~/.file.bak` then `stow PKG` |
| Symlink owned by another package | `stow --override=path PKG` |
| Skip if another package owns it | `stow --defer=path PKG` |

---

## Bootstrap Script

```bash
#!/usr/bin/env bash
# bootstrap-stow.sh — idempotent, restow all packages
set -euo pipefail

DOTFILES="$HOME/dotfiles"
PACKAGES=(zsh git nvim tmux lf ssh)

cd "$DOTFILES"

for pkg in "${PACKAGES[@]}"; do
  if [ -d "$pkg" ]; then
    echo "Restowing $pkg..."
    stow --dotfiles --restow --target="$HOME" "$pkg"
  else
    echo "Skipping $pkg (directory not found)"
  fi
done

echo "Done."
```

---

## Full Dotfiles Workflow

### Add a new config to Stow management

```bash
# 1. Create the package directory mirroring $HOME
mkdir -p ~/dotfiles/alacritty/.config/alacritty

# 2. Move the real file into the package
mv ~/.config/alacritty/alacritty.toml \
   ~/dotfiles/alacritty/.config/alacritty/alacritty.toml

# 3. Stow it (creates symlink)
cd ~/dotfiles && stow alacritty

# 4. Verify
ls -la ~/.config/alacritty/alacritty.toml
# lrwxrwxrwx ... → ../dotfiles/alacritty/.config/alacritty/alacritty.toml

# 5. Commit
git -C ~/dotfiles add alacritty
git -C ~/dotfiles commit -m "chore: add alacritty config"
```

### Edit a managed config

```bash
# Edit directly in the package — symlink makes it live immediately
$EDITOR ~/dotfiles/zsh/.zshrc
```

### After adding or removing files inside a package

```bash
cd ~/dotfiles
stow -R zsh       # restow prunes stale symlinks and adds new ones
```

### Remove Stow management of a package

```bash
cd ~/dotfiles
stow -D alacritty   # removes symlinks; package files in ~/dotfiles are untouched
```

---

## Common Gotchas

| Problem | Fix |
|---|---|
| Conflict: file already exists | Use `--adopt` or `mv` the file away first |
| Symlink destination looks wrong | Run from the stow dir, or pass `-d` and `-t` explicitly |
| Config changes not live | Nothing to do — symlinks are live; only re-stow if *structure* changed |
| Dir symlink blocks other tool writes | Use `--no-folding` so Stow creates real dirs |
| `.gitignore` in package silently ignored | Built-in defaults ignore `\.gitignore`; add `.stow-local-ignore` to override |
| `--dotfiles` not mapping `dot-` prefix | Flag must be passed on every invocation — add it to `.stowrc` |
| `stow */` stows `.stowrc` as a package | Use explicit package list, or put `.stowrc` outside package dirs |
| `--adopt` pulled wrong content | `git -C ~/dotfiles checkout HEAD -- pkg/file` to restore |
| Stow ran from wrong directory | Target defaults to *parent* of stow dir — always use `-t ~` or run from inside stow dir |

---

## Quick Reference Card

```bash
stow PKG                          # stow (install symlinks)
stow -D PKG                       # unstow (remove symlinks)
stow -R PKG                       # restow (unstow + stow; prune stale)
stow -nv PKG                      # dry run + verbose preview
stow -nvR PKG                     # dry run of restow
stow --dotfiles PKG               # dot-foo → .foo mapping
stow --no-folding PKG             # always create real directories
stow --adopt PKG                  # absorb existing plain files into package
stow -t ~ PKG                     # explicit target directory
stow -d ~/dotfiles -t ~ PKG       # explicit stow and target dirs
stow -S PKG1 -D PKG2              # mix stow + unstow in one pass
stow -R PKG1 -S PKG2              # restow one, stow another
stow --ignore='.*\.md' PKG        # skip markdown files
stow --defer='\.gitconfig' PKG    # skip if already owned by another package
stow --override='\.gitconfig' PKG # force overwrite another package's link
stow */                            # stow every subdirectory as a package
chkstow -b                        # find dangling symlinks in target
```

---

## Quality Checklist

- [ ] Run `stow -nv` (dry run) before any real stow operation
- [ ] Package directory layout mirrors `$HOME` exactly
- [ ] `.stow-local-ignore` or `~/.stow-global-ignore` excludes `README`, `LICENSE`, `.git`
- [ ] `~/.stowrc` or `dotfiles/.stowrc` sets `--target` and `--dotfiles` so stow is safe from any cwd
- [ ] After adding/removing files in a package, run `stow -R` to prune stale symlinks
- [ ] Use `--no-folding` when other tools write into the same directories
- [ ] Use `--adopt` + `git diff` workflow to safely absorb pre-existing dotfiles
- [ ] Run `chkstow -b` periodically to catch dangling symlinks

---

## Key References

- Manual: https://www.gnu.org/software/stow/manual/stow.html
- Homepage: https://www.gnu.org/software/stow/
- Source: https://git.savannah.gnu.org/git/stow.git
- Tutorial video (GNU Stow + dotfiles): https://www.youtube.com/watch?v=y6XCebnB9gs
