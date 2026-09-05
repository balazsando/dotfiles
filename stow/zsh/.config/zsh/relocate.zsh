#!/usr/bin/env zsh
# relocate.zsh — Move a file/dir from $HOME into the dotfiles stow repo and re-stow.
# Usage: relocate <path> [--package <pkg>]
#
# The file is moved into stow-packages/<pkg>/<rel-path-from-HOME>/
# and GNU Stow recreates the symlink in $HOME.
# Default package: "extras" (created on first use — add it to stow.sh PACKAGES manually).
#
# Sourced by .zshrc: defines the relocate() function.

relocate() {
  emulate -L zsh
  setopt err_return no_unset

  local repo="${DOTFILES:-$HOME/dotfiles}"
  local pkg="extras"
  local input=""

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --package|-p) shift; pkg="$1" ;;
      *)            input="$1" ;;
    esac
    shift
  done

  if [[ -z "$input" ]]; then
    echo "Usage: relocate <path> [--package <pkg>]"
    echo "  Moves the file into stow-packages/<pkg>/ and re-stows the package."
    echo "  Default package: extras"
    return 1
  fi

  # Resolve source path
  local src
  src=$(realpath "$input" 2>/dev/null) || { echo "Cannot resolve path: $input"; return 1; }

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    echo "Path does not exist: $src"
    return 1
  fi

  # Must be under HOME
  case "$src" in
    "$HOME"/*) ;;
    *) echo "Path must be inside \$HOME: $src"; return 1 ;;
  esac

  # Must not already be a stow-managed symlink pointing into this repo
  if [[ -L "$src" ]] && [[ "$(readlink -f "$src")" == "$repo"/* ]]; then
    echo "Already managed by stow: $src → $(readlink "$src")"
    return 1
  fi

  local rel="${src#$HOME/}"
  local pkg_dir="$repo/stow/$pkg"
  local dst="$pkg_dir/$rel"

  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "Destination already exists in stow package: $dst"
    return 1
  fi

  mkdir -p "${dst:h}"

  # Move into stow package
  mv "$src" "$dst"
  echo "Moved:   $src"
  echo "     →   $dst"

  # Re-stow the package so the symlink is created
  if command -v stow &>/dev/null; then
    stow --dir="$repo/stow" --target="$HOME" --restow "$pkg" \
      && echo "Stowed:  ~/$rel → stow/$pkg/$rel" \
      || { echo "stow failed — check for conflicts"; return 1; }
  else
    ln -s "$dst" "$src"
    echo "Linked:  ~/$rel → $dst (stow not available)"
  fi

  echo ""
  echo "Next steps:"
  echo "  cd $repo && git add stow/$pkg/$rel && git commit -m 'feat: relocate ~/$rel'"
}
