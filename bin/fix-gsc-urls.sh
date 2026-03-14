#!/usr/bin/env bash
# Fix GSC site URLs - remove https:// from sc-domain prefix
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "Fixing GSC site URLs in all client configs..."
echo ""

COUNT=0

for config in workspace/*/seo/config.yaml; do
  if grep -q "sc-domain:https://" "$config"; then
    # Extract the current site line
    SITE_LINE=$(grep "^site:" "$config")

    # Create the fixed version
    FIXED_LINE=$(echo "$SITE_LINE" | sed 's|sc-domain:https://|sc-domain:|')

    # Use perl for cross-platform in-place editing
    perl -pi -e "s|sc-domain:https://|sc-domain:|g" "$config"

    CLIENT=$(basename $(dirname $(dirname "$config")))
    echo "✅ Fixed: $CLIENT"
    ((COUNT++))
  fi
done

echo ""
echo "Fixed $COUNT client configs"
