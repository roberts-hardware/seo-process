#!/usr/bin/env bash
# Core wrapper script for multi-client SEO process
# Usage: bin/run-for-client.sh <client-id> <script-path> [args...]

set -euo pipefail

# Validate arguments
if [[ $# -lt 2 ]]; then
  echo "Usage: $(basename "$0") <client-id> <script-path> [args...]" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  $(basename "$0") acme skills/seo-agent/scripts/seo-discover.sh --limit 20" >&2
  echo "  $(basename "$0") techco skills/seo-health/scripts/health-speed.sh https://techco.com" >&2
  exit 1
fi

CLIENT_ID="$1"
SCRIPT_PATH="$2"
shift 2

# Validate client ID (alphanumeric, dash, underscore only)
if [[ ! "$CLIENT_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Error: Invalid client ID '$CLIENT_ID'" >&2
  echo "Client ID must contain only letters, numbers, dashes, and underscores" >&2
  exit 1
fi

# Get repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Set up client workspace paths
CLIENT_WORKSPACE="$REPO_ROOT/workspace/$CLIENT_ID"
export CLAWD_WORKSPACE="$CLIENT_WORKSPACE"
export SEO_CLIENT_ID="$CLIENT_ID"
export SEO_WORKSPACE_ROOT="$CLIENT_WORKSPACE"

# Create workspace directory structure if it doesn't exist
mkdir -p "$CLIENT_WORKSPACE/brand"
mkdir -p "$CLIENT_WORKSPACE/seo/snapshots"
mkdir -p "$CLIENT_WORKSPACE/seo/health"
mkdir -p "$CLIENT_WORKSPACE/content"

# Load credentials (priority order: existing env > client .env > shared .env)
# 1. Load shared .env if it exists
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a  # Export all variables
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env"
  set +a
fi

# 2. Load client-specific .env (overrides shared)
if [[ -f "$CLIENT_WORKSPACE/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$CLIENT_WORKSPACE/.env"
  set +a
fi

# Change to repo root (fixes relative path issues in scripts)
cd "$REPO_ROOT"

# Resolve script path (handle both absolute and relative)
if [[ "$SCRIPT_PATH" == /* ]]; then
  FULL_SCRIPT_PATH="$SCRIPT_PATH"
else
  FULL_SCRIPT_PATH="$REPO_ROOT/$SCRIPT_PATH"
fi

# Validate script exists
if [[ ! -f "$FULL_SCRIPT_PATH" ]]; then
  echo "Error: Script not found: $SCRIPT_PATH" >&2
  exit 1
fi

# Validate script is executable
if [[ ! -x "$FULL_SCRIPT_PATH" ]]; then
  echo "Error: Script is not executable: $SCRIPT_PATH" >&2
  echo "Run: chmod +x $SCRIPT_PATH" >&2
  exit 1
fi

# Execute the script with all remaining arguments
exec "$FULL_SCRIPT_PATH" "$@"
