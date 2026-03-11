#!/usr/bin/env bash
# Shortcut to run SEO discovery for a client
# Usage: ./bin/run-discovery.sh <client-id> [--limit N]

CLIENT_ID="${1:?Usage: run-discovery.sh <client-id> [--limit N]}"
shift
ARGS="$@"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

exec "$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-agent/scripts/seo-discover.sh $ARGS
