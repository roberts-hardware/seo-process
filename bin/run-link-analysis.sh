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
LINK_OUTPUT=$("$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-links/scripts/link-internal.sh "$SITE_URL" 2>&1) || LINK_EXIT=$?

if [[ ${LINK_EXIT:-0} -eq 0 ]]; then
  echo "$LINK_OUTPUT"
  echo "✅ Internal link analysis complete"
elif echo "$LINK_OUTPUT" | grep -q "Could not fetch sitemap"; then
  echo "⚠️  Internal link analysis skipped (no sitemap found)"
  echo "   Add sitemap.xml to $SITE_URL for internal link analysis"
else
  echo "$LINK_OUTPUT"
  echo "⚠️  Internal link analysis failed"
fi
echo ""

echo "╔════════════════════════════════════════════════════════════"
echo "║ Link Analysis Complete"
echo "╚════════════════════════════════════════════════════════════"
