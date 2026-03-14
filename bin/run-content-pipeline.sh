#!/usr/bin/env bash
# Content pipeline - Generate briefs, research, and create content
# Limits to 2 content pieces per client per run
# Usage: ./bin/run-content-pipeline.sh <client-id>

set -euo pipefail

CLIENT_ID="${1:?Usage: run-content-pipeline.sh <client-id>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTENT_LIMIT=2

echo "╔════════════════════════════════════════════════════════════"
echo "║ Content Pipeline: $CLIENT_ID"
echo "║ Limit: $CONTENT_LIMIT pieces"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# 1. Generate content briefs from discovery data
echo "📋 Step 1/4: Generating content briefs..."
if "$REPO_ROOT/bin/generate-content-briefs.sh" "$CLIENT_ID"; then
  echo "✅ Briefs generated"
else
  echo "❌ Brief generation failed"
  exit 1
fi
echo ""

# 2. Count briefs and select top 2
BRIEF_DIR="$REPO_ROOT/workspace/$CLIENT_ID/content/briefs"
if [[ ! -d "$BRIEF_DIR" ]]; then
  echo "⚠️  No briefs directory found"
  exit 0
fi

BRIEFS=($(ls -1 "$BRIEF_DIR"/*.md 2>/dev/null | head -n "$CONTENT_LIMIT" || true))

if [[ ${#BRIEFS[@]} -eq 0 ]]; then
  echo "⚠️  No briefs to process"
  exit 0
fi

echo "📝 Found ${#BRIEFS[@]} briefs to process (limit: $CONTENT_LIMIT)"
echo ""

# 3. For each brief, run research and create content
COUNT=0
for BRIEF in "${BRIEFS[@]}"; do
  ((COUNT++))
  BRIEF_NAME=$(basename "$BRIEF" .md)

  echo "─────────────────────────────────────────────────────────"
  echo "[$COUNT/$CONTENT_LIMIT] Processing: $BRIEF_NAME"
  echo "─────────────────────────────────────────────────────────"
  echo ""

  # Research
  echo "🔍 Step 2/4: Running research..."
  # TODO: Add research script when available
  # if "$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-forge/scripts/seo-research.sh "$BRIEF"; then
  #   echo "✅ Research complete"
  # else
  #   echo "⚠️  Research failed, continuing anyway"
  # fi
  echo "⚠️  Research script not yet integrated - skipping"
  echo ""

  # Create content
  echo "✍️  Step 3/4: Creating content..."
  # TODO: Add content creation script
  # This would use the brief + research to generate the article
  echo "⚠️  Content creation not yet integrated - skipping"
  echo ""

  # Quality check
  echo "✅ Step 4/4: Quality check..."
  # TODO: Add quality check script when available
  # if "$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" skills/seo-forge/scripts/seo-check.sh "$ARTICLE"; then
  #   echo "✅ Quality check passed"
  # else
  #   echo "⚠️  Quality issues detected"
  # fi
  echo "⚠️  Quality check not yet integrated - skipping"
  echo ""
done

echo "╔════════════════════════════════════════════════════════════"
echo "║ Content Pipeline Complete"
echo "║ Processed: $COUNT briefs"
echo "╚════════════════════════════════════════════════════════════"
