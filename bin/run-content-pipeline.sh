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

# 2. Get config to extract location code
CONFIG="$REPO_ROOT/workspace/$CLIENT_ID/seo/config.yaml"
LOCATION_CODE=$(grep "^location_code:" "$CONFIG" | awk '{print $2}' || echo "2840")

# 3. Count briefs and select top 2
BRIEF_DIR="$REPO_ROOT/workspace/$CLIENT_ID/content/briefs"
if [[ ! -d "$BRIEF_DIR" ]]; then
  echo "⚠️  No briefs directory found"
  exit 0
fi

BRIEFS=($(ls -1t "$BRIEF_DIR"/*.md 2>/dev/null | head -n "$CONTENT_LIMIT" || true))

if [[ ${#BRIEFS[@]} -eq 0 ]]; then
  echo "⚠️  No briefs to process"
  exit 0
fi

echo "📝 Found ${#BRIEFS[@]} briefs to process (limit: $CONTENT_LIMIT)"
echo ""

# 4. Create research directory
RESEARCH_DIR="$REPO_ROOT/workspace/$CLIENT_ID/content/research"
mkdir -p "$RESEARCH_DIR"

# 5. For each brief, run research
COUNT=0
for BRIEF in "${BRIEFS[@]}"; do
  ((COUNT++))
  BRIEF_NAME=$(basename "$BRIEF" .md)

  echo "─────────────────────────────────────────────────────────"
  echo "[$COUNT/$CONTENT_LIMIT] Processing: $BRIEF_NAME"
  echo "─────────────────────────────────────────────────────────"
  echo ""

  # Extract target keyword from brief (first H1 or filename)
  TARGET_KEYWORD=$(grep "^# " "$BRIEF" | head -1 | sed 's/^# //' || echo "$BRIEF_NAME" | tr '-' ' ')

  if [[ -z "$TARGET_KEYWORD" ]]; then
    echo "⚠️  Could not extract keyword from brief, skipping"
    continue
  fi

  echo "🎯 Target keyword: $TARGET_KEYWORD"
  echo ""

  # Research
  echo "🔍 Step 2/4: Running keyword research..."
  RESEARCH_FILE="$RESEARCH_DIR/${BRIEF_NAME}-research.json"

  if "$REPO_ROOT/bin/run-for-client.sh" "$CLIENT_ID" \
      skills/seo-forge/scripts/seo-research.sh \
      "$TARGET_KEYWORD" \
      --location "$LOCATION_CODE" \
      --json > "$RESEARCH_FILE" 2>&1; then
    echo "✅ Research complete"
  else
    echo "⚠️  Research failed, skipping this brief"
    continue
  fi
  echo ""

  # Content creation
  echo "✍️  Step 3/4: Creating content with AI..."
  if "$REPO_ROOT/bin/create-content.sh" "$CLIENT_ID" "$BRIEF" "$RESEARCH_FILE"; then
    echo "✅ Content created"
    ARTICLE_FILE="$REPO_ROOT/workspace/$CLIENT_ID/content/articles/${BRIEF_NAME}.md"
  else
    echo "❌ Content creation failed, skipping quality check"
    continue
  fi
  echo ""

  # Quality check
  echo "🔍 Step 4/4: Quality check..."
  if "$REPO_ROOT/bin/check-content-quality.sh" "$ARTICLE_FILE" "$BRIEF"; then
    echo "✅ Quality check passed"
  else
    echo "⚠️  Quality issues detected - review required"
  fi
  echo ""

  # Rate limiting between pieces
  if [[ $COUNT -lt $CONTENT_LIMIT ]]; then
    echo "⏳ Waiting 30s before next piece..."
    sleep 30
  fi
done

echo "╔════════════════════════════════════════════════════════════"
echo "║ Content Pipeline Complete"
echo "║ Processed: $COUNT briefs"
echo "╚════════════════════════════════════════════════════════════"
