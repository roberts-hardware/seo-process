#!/usr/bin/env bash
# Activate service account with proper Search Console scopes
# Usage: ./bin/activate-service-account.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "🔑 Activating service account for Search Console access..."
echo ""

# Load .env to get credentials path
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

# Check for service account key
if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  echo "❌ Error: GOOGLE_APPLICATION_CREDENTIALS not set in .env"
  echo ""
  echo "Run: ./bin/setup-google-auth.sh"
  exit 1
fi

if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  echo "❌ Error: Service account key file not found:"
  echo "   $GOOGLE_APPLICATION_CREDENTIALS"
  exit 1
fi

echo "✅ Found service account key: $GOOGLE_APPLICATION_CREDENTIALS"
echo ""

# Activate the service account
echo "Activating service account..."
gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"

echo ""
echo "✅ Service account activated!"
echo ""

# Set as default for application-default
echo "Setting application-default credentials..."
export GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"

# Test access
echo "Testing Search Console API access..."
echo ""

SERVICE_EMAIL=$(jq -r '.client_email' "$GOOGLE_APPLICATION_CREDENTIALS")
echo "Service account: $SERVICE_EMAIL"
echo ""

# Get access token with proper scopes
TOKEN=$(gcloud auth print-access-token)

# Test GSC API
RESPONSE=$(curl -s "https://www.googleapis.com/webmasters/v3/sites" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  echo "❌ Still getting API error:"
  echo "$RESPONSE" | jq '.error'
  echo ""
  echo "Make sure you added this email to Google Search Console:"
  echo "  $SERVICE_EMAIL"
  echo ""
  exit 1
else
  SITE_COUNT=$(echo "$RESPONSE" | jq -r '.siteEntry // [] | length')
  echo "✅ Success! Access to $SITE_COUNT site(s):"
  echo ""
  echo "$RESPONSE" | jq -r '.siteEntry[]? | "  • \(.siteUrl) (\(.permissionLevel))"'
  echo ""
fi

echo "╔════════════════════════════════════════════════════════════"
echo "║ Service Account Ready!"
echo "╚════════════════════════════════════════════════════════════"
echo ""
echo "You can now run:"
echo "  ./bin/test-gsc-access.sh ckalcevicroofing"
echo "  ./bin/run-discovery.sh ckalcevicroofing --limit 10"
echo ""
