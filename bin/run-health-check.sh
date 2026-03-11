#!/usr/bin/env bash
# Run all health checks for a client
# Usage: ./bin/run-health-check.sh <client-id>

set -euo pipefail

CLIENT_ID="${1:?Usage: run-health-check.sh <client-id>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$REPO_ROOT/workspace/$CLIENT_ID"
CONFIG="$WORKSPACE/seo/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Error: Client config not found: $CONFIG"
  exit 1
fi

# Get site URL from config
SITE_URL=$(grep '^site_url:' "$CONFIG" | awk '{print $2}' | tr -d '"')

if [[ -z "$SITE_URL" ]]; then
  echo "❌ Error: site_url not found in config"
  exit 1
fi

echo "🏥 Running health checks for $CLIENT_ID"
echo "   Site: $SITE_URL"
echo ""

# Run all 3 health checks
echo "1/3 Running speed test..."
"$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-health/scripts/health-speed.sh "$SITE_URL"

echo ""
echo "2/3 Running crawl test..."
"$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-health/scripts/health-crawl.sh "$SITE_URL"

echo ""
echo "3/3 Running image optimization test..."
"$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-health/scripts/health-images.sh "$SITE_URL"

echo ""
echo "✅ All health checks complete!"
echo "📁 Results: $WORKSPACE/seo/health/"
