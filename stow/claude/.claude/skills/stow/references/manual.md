# GNU Stow — reference

Terminology, layouts, folding, ignore lists, `.stowrc`, multiple stow
directories, and `chkstow`. Read when the task needs detail beyond `SKILL.md`.

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

## Target Maintenance with `chkstow`

```bash
chkstow -b    # report dangling symlinks (pointing nowhere)
chkstow -a    # report links pointing outside any stow directory
chkstow -l    # report stow-owned links alongside non-stow files
```

---

