#!/usr/bin/env bash
# stow.sh — Idempotent restow of all dotfile packages
#
# Auto-discovers packages from the stow/ directory — no manual edits needed.
# Usage: bash stow.sh [-n]   (-n = dry run, no changes)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$DOTFILES/stow"
TARGET_DIR="$HOME"

# Anchor CWD to repo root so stow always finds .stowrc (--no-folding lives there).
cd "$DOTFILES"

DRY_RUN=false
[[ "${1:-}" == "-n" ]] && {
  DRY_RUN=true
  echo "▶ DRY RUN — no changes will be made"
}

# ─── Preflight ────────────────────────────────────────────────────────────────
[[ -d "$STOW_DIR" ]] || {
  echo "✗ stow/ directory not found in $DOTFILES"
  exit 1
}

if ! command -v stow &>/dev/null; then
  echo "✗ GNU Stow not found — install it: sudo apt install stow"
  exit 1
fi

_stow_ver=$(stow --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
_maj=$(echo "$_stow_ver" | cut -d. -f1)
_min=$(echo "$_stow_ver" | cut -d. -f2)
[[ "$_maj" -lt 2 || ("$_maj" -eq 2 && "$_min" -lt 3) ]] &&
  echo "⚠ GNU Stow $_stow_ver — 2.3+ recommended (sudo apt upgrade stow)"

echo "▶ GNU Stow $_stow_ver  |  $STOW_DIR → $TARGET_DIR"

if ! $DRY_RUN; then
  # Back up a real ~/.zshrc instead of destroying it; a symlink is ours or stale.
  if [[ -L "$TARGET_DIR/.zshrc" ]]; then
    rm -f "$TARGET_DIR/.zshrc"
  elif [[ -f "$TARGET_DIR/.zshrc" ]]; then
    if [[ -e "$TARGET_DIR/.zshrc.pre-stow" ]]; then
      rm -f "$TARGET_DIR/.zshrc"
    else
      mv "$TARGET_DIR/.zshrc" "$TARGET_DIR/.zshrc.pre-stow"
      echo "  ⚠ existing ~/.zshrc backed up → ~/.zshrc.pre-stow"
    fi
  fi
  [[ -L "$TARGET_DIR/.config/nvim" ]] && rm -f "$TARGET_DIR/.config/nvim"
fi

# ─── Auto-discover packages ───────────────────────────────────────────────────
mapfile -t PACKAGES < <(
  find "$STOW_DIR" -maxdepth 1 -mindepth 1 -type d ! -name '.*' |
    sort | xargs -I{} basename {}
)

[[ ${#PACKAGES[@]} -gt 0 ]] || {
  echo "✗ No packages found in stow/"
  exit 1
}

# ─── Conflict pre-scan ────────────────────────────────────────────────────────
# One combined run — also the only way to catch conflicts *between* packages.
_stow_args=(--dir="$STOW_DIR" --target="$TARGET_DIR" --restow)

if ! $DRY_RUN; then
  if ! output=$(stow "${_stow_args[@]}" --simulate "${PACKAGES[@]}" 2>&1); then
    echo "✗ Stow conflicts detected — resolve before applying:"
    printf '%s\n' "$output" | sed 's/^/  /'
    echo ""
    echo "  Tip: remove or relocate the conflicting files, then re-run stow.sh"
    exit 1
  fi
fi

# ─── Restow ───────────────────────────────────────────────────────────────────
$DRY_RUN && _stow_args+=(--simulate)

if stow "${_stow_args[@]}" "${PACKAGES[@]}" 2>&1; then
  printf '  ✔ %s\n' "${PACKAGES[@]}"
else
  echo "✗ Combined restow failed — retrying per package to isolate:"
  for pkg in "${PACKAGES[@]}"; do
    if stow "${_stow_args[@]}" "$pkg" 2>&1; then
      echo "  ✔ $pkg"
    else
      echo "  ✗ $pkg"
    fi
  done
  exit 1
fi

# ─── Post-stow ────────────────────────────────────────────────────────────────
if ! $DRY_RUN; then
  echo ""
  echo "▶ All packages stowed"

  # Reinitialize mise after stowing config (allows new tools to be found)
  if command -v mise &>/dev/null; then
    mise trust "$TARGET_DIR/.mise.toml" 2>/dev/null || true
    eval "$(mise activate bash)"
    echo "  ✔ mise reinitialized"
  fi

  # Rebuild bat cache if available
  command -v bat &>/dev/null && bat cache --build >/dev/null 2>&1 && echo "  ✔ bat theme cache rebuilt"
else
  echo "▶ Dry run complete — run without -n to apply"
fi
