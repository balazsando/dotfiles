#!/usr/bin/env bash
# Starts mcp-jira-cloud using pre-configured JIRA_* environment variables.
# JIRA_EMAIL, JIRA_TOKEN, and JIRA_URL must be set in the shell profile
# (~/.config/zsh/secrets). Cursor/Claude MCP configs pass those through;
# this script also loads secrets as a fallback for GUI launches that do
# not inherit the interactive zsh environment.
set -euo pipefail

if [[ -z "${JIRA_TOKEN:-}" || -z "${JIRA_URL:-}" || -z "${JIRA_EMAIL:-}" ]]; then
  if [[ -f "${HOME}/.config/zsh/secrets" ]]; then
    set +u
    # shellcheck disable=SC1091
    source "${HOME}/.config/zsh/secrets"
    set -u
  fi
fi

if [[ -z "${JIRA_TOKEN:-}" ]]; then
  echo "JIRA_TOKEN environment variable is not set." >&2
  exit 1
fi

if [[ -z "${JIRA_EMAIL:-}" ]]; then
  echo "JIRA_EMAIL environment variable is not set." >&2
  exit 1
fi

if [[ -z "${JIRA_URL:-}" ]]; then
  echo "JIRA_URL environment variable is not set." >&2
  exit 1
fi

export JIRA_EMAIL
export JIRA_API_TOKEN="$JIRA_TOKEN"
export JIRA_BASE_URL="${JIRA_URL%/}"

source "$(dirname "${BASH_SOURCE[0]}")/node-ca.sh"
node_ca_setup || true

# Pinned — this runs with a live Jira token in its environment.
exec npx --yes mcp-jira-cloud@4.4.0
