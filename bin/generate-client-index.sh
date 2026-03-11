#!/usr/bin/env bash
# Generate clients.json index file for dashboard
# Usage: ./bin/generate-client-index.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_DIR="$REPO_ROOT/workspace"
OUTPUT_FILE="$WORKSPACE_DIR/clients.json"

echo "📊 Generating client index for dashboard..."
echo ""

# Find all client directories
if [[ ! -d "$WORKSPACE_DIR" ]]; then
  echo "❌ Error: Workspace directory not found: $WORKSPACE_DIR"
  exit 1
fi

CLIENTS=$(find "$WORKSPACE_DIR" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -exec basename {} \; | sort)

if [[ -z "$CLIENTS" ]]; then
  echo "⚠️  No clients found in workspace"
  echo "[]" > "$OUTPUT_FILE"
  echo "✅ Created empty index: $OUTPUT_FILE"
  exit 0
fi

NUM_CLIENTS=$(echo "$CLIENTS" | wc -l | tr -d ' ')
echo "Found $NUM_CLIENTS clients"
echo ""

# Start JSON array
echo "[" > "$OUTPUT_FILE"

FIRST=true
while IFS= read -r CLIENT_ID; do
  [[ -z "$CLIENT_ID" ]] && continue

  CONFIG="$WORKSPACE_DIR/$CLIENT_ID/seo/config.yaml"

  if [[ ! -f "$CONFIG" ]]; then
    echo "  ⚠️  Skipping $CLIENT_ID (no config file)"
    continue
  fi

  echo "  Processing: $CLIENT_ID"

  # Extract config values
  SITE_URL=$(grep '^site_url:' "$CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "")
  BUSINESS_TYPE=$(grep '^business_type:' "$CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "unknown")
  PHONE=$(grep '^phone:' "$CONFIG" 2>/dev/null | awk '{$1=""; print $0}' | tr -d '"' | xargs || echo "")

  # Find latest snapshot
  LATEST_SNAPSHOT=$(find "$WORKSPACE_DIR/$CLIENT_ID/seo/snapshots" -name "*.json" -type f 2>/dev/null | sort -r | head -1 || echo "")
  SNAPSHOT_DATE=""
  if [[ -n "$LATEST_SNAPSHOT" ]]; then
    SNAPSHOT_DATE=$(basename "$LATEST_SNAPSHOT" .json | sed "s/${CLIENT_ID//./}_com-//")
  fi

  # Count content files
  CONTENT_COUNT=$(find "$WORKSPACE_DIR/$CLIENT_ID/content" -name "*.md" ! -name "brief-*" ! -name "*GUIDE*" ! -name "*STRATEGY*" ! -name "*TEMPLATE*" -type f 2>/dev/null | wc -l | tr -d ' ')

  # Add comma separator if not first
  if [[ "$FIRST" == "true" ]]; then
    FIRST=false
  else
    echo "," >> "$OUTPUT_FILE"
  fi

  # Write client entry
  CLIENT_NAME=$(echo "$CLIENT_ID" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

  echo "  {" >> "$OUTPUT_FILE"
  echo "    \"id\": \"$CLIENT_ID\"," >> "$OUTPUT_FILE"
  echo "    \"name\": \"$CLIENT_NAME\"," >> "$OUTPUT_FILE"
  echo "    \"site_url\": \"$SITE_URL\"," >> "$OUTPUT_FILE"
  echo "    \"business_type\": \"$BUSINESS_TYPE\"," >> "$OUTPUT_FILE"
  echo "    \"phone\": \"$PHONE\"," >> "$OUTPUT_FILE"
  echo "    \"last_snapshot\": \"$SNAPSHOT_DATE\"," >> "$OUTPUT_FILE"
  echo "    \"content_pages\": $CONTENT_COUNT," >> "$OUTPUT_FILE"
  echo "    \"workspace_path\": \"workspace/$CLIENT_ID\"" >> "$OUTPUT_FILE"
  echo "  }" >> "$OUTPUT_FILE"

done <<< "$CLIENTS"

# Close JSON array
echo "" >> "$OUTPUT_FILE"
echo "]" >> "$OUTPUT_FILE"

echo ""
echo "✅ Client index generated: $OUTPUT_FILE"
echo "   Total clients: $NUM_CLIENTS"
echo ""
echo "📤 Don't forget to sync to GitHub:"
echo "   git add $OUTPUT_FILE"
echo "   git commit -m \"Update client index\""
echo "   git push"
