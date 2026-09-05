#!/usr/bin/env bash
# Registers this dotfiles repo's MCP servers into Claude Code's user-scope
# config (~/.claude.json), since that file is live runtime state (sessions,
# credentials, project cache) and must never be stow-symlinked directly.
#
# Source of truth: ../mcp-servers.json (next to this script once stowed).
# Safe to re-run: removes then re-adds each server.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVERS_FILE="$SCRIPT_DIR/../mcp-servers.json"

if ! command -v claude >/dev/null 2>&1; then
  echo "error: claude CLI not found on PATH" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

# Expand ${HOME} here so the tracked file stays free of a baked-in home dir.
for name in $(jq -r '.mcpServers | keys[]' "$SERVERS_FILE"); do
  json=$(jq -c --arg n "$name" --arg home "$HOME" \
    '.mcpServers[$n] | walk(if type == "string" then gsub("\\$\\{HOME\\}"; $home) else . end)' \
    "$SERVERS_FILE")
  echo "Registering MCP server: $name"
  claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
  claude mcp add-json "$name" "$json" --scope user
done

echo "Done. Verify with: claude mcp list"
