#!/usr/bin/env bash
# Link analysis - Broken links + internal link opportunities
# Usage: ./bin/run-link-analysis.sh <client-id>

set -euo pipefail

CLIENT_ID="${1:?Usage: run-link-analysis.sh <client-id>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔════════════════════════════════════════════════════════════"
echo "║ Link Analysis: $CLIENT_ID"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# Get site URL from config
CONFIG="$REPO_ROOT/workspace/$CLIENT_ID/seo/config.yaml"
if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Config not found: $CONFIG"
  exit 1
fi

SITE_URL=$(grep "^site_url:" "$CONFIG" | awk '{print $2}' | tr -d '"' | tr -d "'")

if [[ -z "$SITE_URL" ]]; then
  echo "❌ site_url not found in config"
  exit 1
fi

echo "🌐 Site: $SITE_URL"
echo ""

# 1. Broken link check
echo "🔗 Step 1/2: Checking for broken links..."
if "$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-links/scripts/link-broken.sh "$SITE_URL"; then
  echo "✅ Broken link check complete"
else
  echo "⚠️  Broken link check failed"
fi
echo ""

# 2. Internal link opportunities
echo "🔗 Step 2/2: Finding internal link opportunities..."
if "$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-links/scripts/link-internal.sh "$SITE_URL"; then
  echo "✅ Internal link analysis complete"
else
  echo "⚠️  Internal link analysis failed"
  echo "   Note: Sites without sitemaps require Cloudflare API credentials"
fi
echo ""

echo "╔════════════════════════════════════════════════════════════"
echo "║ Link Analysis Complete"
echo "╚════════════════════════════════════════════════════════════"
