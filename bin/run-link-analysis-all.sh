#!/usr/bin/env bash
# Run link analysis for all clients
# Usage: ./bin/run-link-analysis-all.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_DIR="$REPO_ROOT/workspace"

echo "╔════════════════════════════════════════════════════════════"
echo "║ Link Analysis - All Clients"
echo "║ Started: $(date)"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# Find all clients
CLIENTS=""
for dir in "$WORKSPACE_DIR"/*/ ; do
  if [[ -d "$dir" ]]; then
    CLIENT_ID=$(basename "$dir")

    # Skip non-client directories
    if [[ "$CLIENT_ID" == .* ]] || [[ "$CLIENT_ID" == "seo" ]] || [[ "$CLIENT_ID" == "seo-agent" ]] || [[ "$CLIENT_ID" == "test-client" ]]; then
      continue
    fi

    # Check if valid client
    if [[ -f "$dir/seo/config.yaml" ]]; then
      CLIENTS="$CLIENTS$CLIENT_ID"$'\n'
    fi
  fi
done

CLIENTS=$(echo "$CLIENTS" | sed '/^$/d')
NUM_CLIENTS=$(echo "$CLIENTS" | wc -l | tr -d ' ')

echo "📊 Processing $NUM_CLIENTS clients"
echo ""

SUCCESS=0
FAILED=0

while IFS= read -r CLIENT_ID; do
  [[ -z "$CLIENT_ID" ]] && continue

  echo "─────────────────────────────────────────────────────────"
  echo "🎯 Client: $CLIENT_ID"
  echo "─────────────────────────────────────────────────────────"
  echo ""

  if "$REPO_ROOT/bin/run-link-analysis.sh" "$CLIENT_ID"; then
    echo "✅ Link analysis complete for $CLIENT_ID"
    ((SUCCESS++))
  else
    echo "❌ Link analysis failed for $CLIENT_ID"
    ((FAILED++))
  fi

  echo ""
  sleep 10  # Rate limiting

done <<< "$CLIENTS"

# Sync to GitHub
"$REPO_ROOT/bin/sync-workspace.sh" all "Monthly link analysis results" || true

echo "╔════════════════════════════════════════════════════════════"
echo "║ Link Analysis Complete"
echo "║ Finished: $(date)"
echo "║ Success: $SUCCESS"
echo "║ Failed: $FAILED"
echo "╚════════════════════════════════════════════════════════════"

# Notify team
if [[ $FAILED -gt 0 ]]; then
  "$REPO_ROOT/bin/notify-team.sh" "link-analysis" "failure" "$SUCCESS succeeded, $FAILED failed" || true
  exit 1
else
  "$REPO_ROOT/bin/notify-team.sh" "link-analysis" "success" "$SUCCESS clients analyzed" || true
fi
