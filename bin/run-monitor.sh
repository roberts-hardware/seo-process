#!/usr/bin/env bash
# Shortcut to run SEO monitoring for a client
# Usage: ./bin/run-monitor.sh <client-id>

CLIENT_ID="${1:?Usage: run-monitor.sh <client-id>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

exec "$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-agent/scripts/seo-monitor.sh
