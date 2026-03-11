#!/usr/bin/env bash
# Master scheduler - runs operations for all clients
# Usage: ./bin/schedule-all-clients.sh <schedule-name>
#
# Schedule names:
#   monday-morning    - Discovery + monitoring for all clients
#   friday-afternoon  - Health checks for all clients
#   weekly-compete    - Competitor analysis for all clients
#
# Example cron:
#   0 9 * * 1 ~/seo-process/bin/schedule-all-clients.sh monday-morning
#   0 15 * * 5 ~/seo-process/bin/schedule-all-clients.sh friday-afternoon

set -euo pipefail

SCHEDULE_NAME="${1:?Usage: schedule-all-clients.sh <schedule-name>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_DIR="$REPO_ROOT/workspace"

# Find all client directories (must have seo/config.yaml)
if [[ ! -d "$WORKSPACE_DIR" ]]; then
  echo "❌ Error: Workspace directory not found: $WORKSPACE_DIR"
  exit 1
fi

# Only include directories that have a valid client config
CLIENTS=""
for dir in "$WORKSPACE_DIR"/*/ ; do
  if [[ -d "$dir" ]]; then
    CLIENT_ID=$(basename "$dir")

    # Skip hidden directories and non-client directories
    if [[ "$CLIENT_ID" == .* ]] || [[ "$CLIENT_ID" == "seo" ]] || [[ "$CLIENT_ID" == "seo-agent" ]]; then
      continue
    fi

    # Check if valid client (has config file)
    if [[ -f "$dir/seo/config.yaml" ]]; then
      CLIENTS="$CLIENTS$CLIENT_ID"$'\n'
    fi
  fi
done

CLIENTS=$(echo "$CLIENTS" | sed '/^$/d')  # Remove empty lines

if [[ -z "$CLIENTS" ]]; then
  echo "⚠️  No valid clients found in workspace"
  echo ""
  echo "Clients must have: workspace/{client-id}/seo/config.yaml"
  echo ""
  echo "Add a client with: ./bin/add-client.sh <client-id> <site-url> <competitors>"
  exit 0
fi

NUM_CLIENTS=$(echo "$CLIENTS" | wc -l | tr -d ' ')

echo "╔════════════════════════════════════════════════════════════"
echo "║ SEO Process - Master Scheduler"
echo "║ Schedule: $SCHEDULE_NAME"
echo "║ Clients: $NUM_CLIENTS"
echo "║ Started: $(date)"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# Track results
SUCCESS=0
FAILED=0
SKIPPED=0

case "$SCHEDULE_NAME" in
  monday-morning)
    echo "📋 Running: Discovery + Monitoring for all clients"
    echo ""

    while IFS= read -r CLIENT_ID; do
      [[ -z "$CLIENT_ID" ]] && continue

      echo "─────────────────────────────────────────────────"
      echo "🎯 Client: $CLIENT_ID"
      echo "─────────────────────────────────────────────────"

      # Discovery
      echo ""
      echo "1/2 Discovery..."
      if "$REPO_ROOT/bin/run-and-sync.sh" "$CLIENT_ID" skills/seo-agent/scripts/seo-discover.sh --limit 20; then
        echo "✅ Discovery complete"
      else
        echo "❌ Discovery failed"
        ((FAILED++))
        continue
      fi

      # Monitoring
      echo ""
      echo "2/2 Monitoring..."
      if "$REPO_ROOT/bin/run-and-sync.sh" "$CLIENT_ID" skills/seo-agent/scripts/seo-monitor.sh; then
        echo "✅ Monitoring complete"
        ((SUCCESS++))
      else
        echo "❌ Monitoring failed"
        ((FAILED++))
      fi

      echo ""

      # Rate limiting: wait 30 seconds between clients
      sleep 30

    done <<< "$CLIENTS"
    ;;

  friday-afternoon)
    echo "🏥 Running: Health checks for all clients"
    echo ""

    while IFS= read -r CLIENT_ID; do
      [[ -z "$CLIENT_ID" ]] && continue

      echo "─────────────────────────────────────────────────"
      echo "🎯 Client: $CLIENT_ID"
      echo "─────────────────────────────────────────────────"

      # Health checks
      if "$REPO_ROOT/bin/run-health-check.sh" "$CLIENT_ID"; then
        # Sync to GitHub
        "$REPO_ROOT/bin/sync-workspace.sh" "$CLIENT_ID" "Health check results for $CLIENT_ID"
        echo "✅ Health checks complete"
        ((SUCCESS++))
      else
        echo "❌ Health checks failed"
        ((FAILED++))
      fi

      echo ""

      # Rate limiting
      sleep 30

    done <<< "$CLIENTS"
    ;;

  weekly-compete)
    echo "🥊 Running: Competitor analysis for all clients"
    echo ""

    while IFS= read -r CLIENT_ID; do
      [[ -z "$CLIENT_ID" ]] && continue

      echo "─────────────────────────────────────────────────"
      echo "🎯 Client: $CLIENT_ID"
      echo "─────────────────────────────────────────────────"

      # Competitor analysis
      if "$REPO_ROOT/bin/run-and-sync.sh" "$CLIENT_ID" skills/seo-agent/scripts/seo-compete.sh; then
        echo "✅ Competitor analysis complete"
        ((SUCCESS++))
      else
        echo "❌ Competitor analysis failed"
        ((FAILED++))
      fi

      echo ""

      # Rate limiting
      sleep 30

    done <<< "$CLIENTS"
    ;;

  *)
    echo "❌ Error: Unknown schedule: $SCHEDULE_NAME"
    echo ""
    echo "Valid schedules:"
    echo "  monday-morning    - Discovery + monitoring"
    echo "  friday-afternoon  - Health checks"
    echo "  weekly-compete    - Competitor analysis"
    exit 1
    ;;
esac

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════"
echo "║ Schedule Complete"
echo "║ Finished: $(date)"
echo "║ Success: $SUCCESS"
echo "║ Failed: $FAILED"
echo "║ Skipped: $SKIPPED"
echo "╚════════════════════════════════════════════════════════════"

# Update dashboard index
echo ""
echo "📊 Updating dashboard index..."
"$REPO_ROOT/bin/generate-client-index.sh" >/dev/null 2>&1 || true
"$REPO_ROOT/bin/sync-workspace.sh" all "Automated $SCHEDULE_NAME update" >/dev/null 2>&1 || true

# Notify team
if [[ $FAILED -gt 0 ]]; then
  "$REPO_ROOT/bin/notify-team.sh" "$SCHEDULE_NAME" "failure" "$SUCCESS succeeded, $FAILED failed" || true
  exit 1
else
  "$REPO_ROOT/bin/notify-team.sh" "$SCHEDULE_NAME" "success" "$SUCCESS clients processed successfully" || true
fi
