#!/usr/bin/env bash
# Starts SonarQube MCP via Docker Desktop from WSL.
# SONARQUBE_TOKEN and SONARQUBE_URL must be set in the shell profile.
set -euo pipefail

if [[ -z "${SONARQUBE_TOKEN:-}" ]]; then
  echo "SONARQUBE_TOKEN environment variable is not set." >&2
  exit 1
fi

if [[ -z "${SONARQUBE_URL:-}" ]]; then
  echo "SONARQUBE_URL environment variable is not set." >&2
  exit 1
fi

DOCKER_BIN="${DOCKER_BIN:-/mnt/c/Program Files/Docker/Docker/resources/bin/docker.exe}"

if [[ ! -x "$DOCKER_BIN" ]]; then
  if command -v docker >/dev/null 2>&1; then
    DOCKER_BIN="$(command -v docker)"
  else
    echo "Docker is not available. Start Docker Desktop or set DOCKER_BIN." >&2
    exit 1
  fi
fi

exec "$DOCKER_BIN" run --init --pull=always -i --rm \
  -e SONARQUBE_TOKEN \
  -e SONARQUBE_URL \
  sonarsource/sonarqube-mcp
