#!/usr/bin/env bash
# Send notification to team after automated runs
# Usage: ./bin/notify-team.sh <schedule-name> <status> [message]

set -euo pipefail

SCHEDULE_NAME="${1:?Usage: notify-team.sh <schedule-name> <status> [message]}"
STATUS="${2:?Usage: notify-team.sh <schedule-name> <status> [message]}"
MESSAGE="${3:-}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Configuration (set these in .env or here)
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
EMAIL_TO="${EMAIL_TO:-}"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Count clients
NUM_CLIENTS=$(find "$REPO_ROOT/workspace" -mindepth 1 -maxdepth 1 -type d ! -name ".*" | wc -l | tr -d ' ')

# Determine emoji and color based on status
if [[ "$STATUS" == "success" ]]; then
  EMOJI="✅"
  COLOR="good"
elif [[ "$STATUS" == "failure" ]]; then
  EMOJI="❌"
  COLOR="danger"
else
  EMOJI="ℹ️"
  COLOR="warning"
fi

# Build notification message
NOTIFICATION_TITLE="$EMOJI SEO Process: $SCHEDULE_NAME"
NOTIFICATION_BODY="Status: $STATUS
Clients: $NUM_CLIENTS
Time: $TIMESTAMP"

if [[ -n "$MESSAGE" ]]; then
  NOTIFICATION_BODY="$NOTIFICATION_BODY
Details: $MESSAGE"
fi

# Add GitHub link to generated content
GITHUB_REPO="https://github.com/roberts-hardware/seo-process"

if [[ "$SCHEDULE_NAME" == "content-weekly" ]]; then
  NOTIFICATION_BODY="$NOTIFICATION_BODY

📝 View Generated Content:
$GITHUB_REPO/tree/main/workspace

📊 Quality Reports:
Check workspace/*/content/quality-reports/"
fi

NOTIFICATION_BODY="$NOTIFICATION_BODY

🔗 View All Results: $GITHUB_REPO"

# Send to Slack if configured
if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
  echo "📤 Sending Slack notification..."

  curl -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d @- <<EOF 2>/dev/null || true
{
  "attachments": [
    {
      "color": "$COLOR",
      "title": "$NOTIFICATION_TITLE",
      "text": "$NOTIFICATION_BODY",
      "footer": "SEO Process Automation",
      "ts": $(date +%s)
    }
  ]
}
EOF

  echo "✅ Slack notification sent"
fi

# Send email if configured
if [[ -n "$EMAIL_TO" ]] && command -v mail >/dev/null 2>&1; then
  echo "📧 Sending email notification..."

  echo "$NOTIFICATION_BODY" | mail -s "$NOTIFICATION_TITLE" "$EMAIL_TO" || true

  echo "✅ Email sent to $EMAIL_TO"
fi

# Log notification
LOG_FILE="$REPO_ROOT/logs/notifications.log"
mkdir -p "$REPO_ROOT/logs"
echo "[$TIMESTAMP] $NOTIFICATION_TITLE - $STATUS" >> "$LOG_FILE"

echo ""
echo "Team notification sent!"
