#!/usr/bin/env bash
# Run a script for a client and auto-sync results to GitHub
# Usage: ./bin/run-and-sync.sh <client-id> <script-path> [script-args...]
#
# Example:
#   ./bin/run-and-sync.sh acmeplumbing skills/seo-agent/scripts/seo-discover.sh --limit 20

set -euo pipefail

CLIENT_ID="${1:?Usage: run-and-sync.sh <client-id> <script-path> [args...]}"
SCRIPT_PATH="${2:?Usage: run-and-sync.sh <client-id> <script-path> [args...]}"
shift 2
SCRIPT_ARGS="$@"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Determine script name for commit message
SCRIPT_NAME=$(basename "$SCRIPT_PATH" .sh)

echo "🚀 Running $SCRIPT_NAME for $CLIENT_ID..."
echo ""

# Run the script
"$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" "$SCRIPT_PATH" $SCRIPT_ARGS

echo ""
echo "─────────────────────────────────────────────────"
echo ""

# Sync to GitHub
"$REPO_ROOT/bin/sync-workspace.sh" "$CLIENT_ID" "$SCRIPT_NAME results for $CLIENT_ID"
