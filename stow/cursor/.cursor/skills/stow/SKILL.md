---
name: stow
description: "GNU Stow symlink farm manager skill. Use when setting up Stow for dotfile management, structuring a stow directory, stowing/unstowing/restowing packages, handling conflicts, using --dotfiles mode (dot- prefix), writing .stowrc config, setting up ignore lists (.stow-local-ignore / .stow-global-ignore), mixing -S/-D/-R operations in one invocation, managing multiple stow directories, or using --adopt to absorb existing files."
argument-hint: "Describe the Stow task (e.g., 'stow my zsh config', 'unstow a package', 'resolve a conflict', 'set up dotfiles repo with stow', 'use --dotfiles flag', 'ignore README files', 'adopt existing dotfiles')"
---

# GNU Stow Skill

## Purpose
GNU Stow (v2.4.1) is a **symlink farm manager**. It takes packages living in separate subdirectories of a *stow directory* and symlinks their contents into a single *target directory* — typically `$HOME` for dotfiles, or `/usr/local` for compiled software.

> Stow stores **no state** between runs — it is always safe to re-run.
> Stow will **never delete** any files, directories, or links inside the stow directory.

Manual: https://www.gnu.org/software/stow/manual/stow.html

---

## Terminology

| Term | Meaning | Dotfiles example |
|---|---|---|
| **Package** | Named subdirectory inside the stow dir | `zsh`, `nvim`, `git` |
| **Stow directory** | Root that contains all packages | `~/dotfiles` |
| **Target directory** | Where symlinks are created | `$HOME` |
| **Installation image** | File layout inside a package, mirroring the target tree | `zsh/.zshrc` mirrors `~/.zshrc` |

### Path anatomy

```
~/dotfiles/zsh/.zshrc
│          │   └── installation image file
│          └── package directory  (package name = "zsh")
└── stow directory
```

After `stow zsh`, Stow creates:
```
~/.zshrc  →  ../dotfiles/zsh/.zshrc   (relative symlink)
```

---

## Install

```bash
sudo apt install stow        # Debian / Ubuntu / WSL2
brew install stow            # macOS
sudo pacman -S stow          # Arch Linux
sudo dnf install stow        # Fedora / RHEL
```

---

## Dotfiles Repo Layouts

### Classic — hidden files inside package dirs

The package directory structure mirrors `$HOME` exactly:

```
~/dotfiles/
├── zsh/
│   └── .zshrc                 → ~/.zshrc
├── git/
│   ├── .gitconfig             → ~/.gitconfig
│   └── .gitignore_global      → ~/.gitignore_global
├── nvim/
│   └── .config/
│       └── nvim/              → ~/.config/nvim/
├── tmux/
│   └── .tmux.conf             → ~/.tmux.conf
└── ssh/
    └── .ssh/
        └── config             → ~/.ssh/config
```

```bash
cd ~/dotfiles
stow zsh git nvim tmux
```

### `--dotfiles` layout — visible names with `dot-` prefix

Avoids a stow directory full of hidden files. Stow maps `dot-foo` → `.foo` at the target.

```
~/dotfiles/
├── zsh/
│   └── dot-zshrc              → ~/.zshrc
├── git/
│   └── dot-gitconfig          → ~/.gitconfig
├── nvim/
│   └── dot-config/
│       └── nvim/              → ~/.config/nvim/
└── tmux/
    └── dot-tmux.conf          → ~/.tmux.conf
```

```bash
cd ~/dotfiles
stow --dotfiles zsh git nvim tmux
```

> `dot-` prefix is only mapped if `--dotfiles` is passed.  
> Works on files **and** directories (e.g. `dot-config/` → `.config/`).

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

## Tree Folding

When all files in a subdirectory belong to a single package, Stow creates **one symlink for the whole directory** instead of individual file symlinks. This is called *tree folding*.

```
nvim/.config/nvim/init.lua
nvim/.config/nvim/lua/
```

Result: `~/.config/nvim  →  ../dotfiles/nvim/.config/nvim`

**Tree unfolding** happens automatically when a second package needs a file in an already-folded directory — Stow replaces the dir symlink with a real directory and links individual files.

### Disable folding with `--no-folding`

```bash
stow --no-folding nvim
# creates: ~/.config/nvim/  (real directory)
# creates: ~/.config/nvim/init.lua  →  ../dotfiles/nvim/.config/nvim/init.lua
```

> Use `--no-folding` when other tools (e.g. package managers, editors) need to write files into the same directory that Stow manages.

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

## Ignore Lists

Stow ignores files matching patterns in ignore lists. **Per-package** lists take priority over the global one.

### Per-package: `.stow-local-ignore`

Place in the **root of the package directory** (e.g. `~/dotfiles/zsh/.stow-local-ignore`).
Perl regular expressions, one per line. When this file exists, the global ignore is not consulted.

```
# ~/dotfiles/zsh/.stow-local-ignore
\.git
\.gitignore
README(\.md|\.txt|\.rst)?
LICENSE(\.md|\.txt)?
.*~
.*\.bak
.*\.orig
```

### Global: `~/.stow-global-ignore`

Applied to all packages that don't have a `.stow-local-ignore`.

```
# ~/.stow-global-ignore
\.git
\.gitignore
\.DS_Store
README(\.md|\.txt|\.rst)?
LICENSE(\.md|\.txt)?
.*~
.*\.bak
.*\.orig
```

### Built-in defaults (always ignored)

```
CVS   RCS   .cvsignore   *,v
.svn  _darcs  .hg  .git  .bzr
.*~   .#*   *.orig   *.rej
```

### Inline `--ignore` on the command line

```bash
stow --ignore='.*\.md' --ignore='LICENSE' zsh
stow --ignore='.*\.(orig|bak|dist)' nvim
```

---

## Resource File (`.stowrc`)

Default options written to a file so you don't repeat them on every invocation.

### Global: `~/.stowrc`

```
# ~/.stowrc
--target=$HOME
--verbose=1
--dotfiles
```

### Per-stow-dir: `~/dotfiles/.stowrc`

Loaded when Stow is run from (or with `-d`) that directory. Takes precedence over `~/.stowrc`.

```
# ~/dotfiles/.stowrc
--dotfiles
--ignore=README\.md
--ignore=LICENSE
--ignore=\.git
```

> Stow prepends `.stowrc` contents to `ARGV` at runtime — equivalent to typing those flags every time.

---

## Multiple Stow Directories

Multiple stow dirs can point at the same target. Each is managed independently:

```bash
# System software
cd /usr/local/stow && sudo stow perl emacs

# User dotfiles
cd ~/dotfiles && stow zsh nvim

# Work-specific overrides (higher precedence via --override)
cd ~/work-dotfiles && stow --override=\.gitconfig git-work
```

Ownership of a symlink is determined by which stow directory it points into.
Use `--defer` (lower precedence) and `--override` (higher precedence) to control conflicts between directories.

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

## Target Maintenance with `chkstow`

```bash
chkstow -b    # report dangling symlinks (pointing nowhere)
chkstow -a    # report links pointing outside any stow directory
chkstow -l    # report stow-owned links alongside non-stow files
```

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
