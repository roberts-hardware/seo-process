#!/usr/bin/env bash
# Test Google Search Console API access
# Usage: ./bin/test-gsc-access.sh [client-id]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT_ID="${1:-}"

echo "╔════════════════════════════════════════════════════════════"
echo "║ Testing Google Search Console API Access"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# Load environment variables
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
  echo "✅ Loaded .env configuration"
else
  echo "⚠️  No .env file found (using system defaults)"
fi

echo ""

# Check for service account credentials
if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  if [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    echo "✅ Using service account: $GOOGLE_APPLICATION_CREDENTIALS"
  else
    echo "❌ Error: Service account key file not found:"
    echo "   $GOOGLE_APPLICATION_CREDENTIALS"
    echo ""
    echo "Run: ./bin/setup-google-auth.sh"
    exit 1
  fi
else
  echo "⚠️  No GOOGLE_APPLICATION_CREDENTIALS set"
  echo "   Trying application default credentials..."
fi

echo ""

# Get access token using Python generator (includes proper scopes)
echo "🔑 Getting access token..."

TOKEN=""

# Try Python generator first (has proper scopes)
if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]] && [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  TOKEN_GENERATOR="$REPO_ROOT/bin/generate-gsc-token.py"

  if [[ -f "$TOKEN_GENERATOR" ]]; then
    if TOKEN=$(python3 "$TOKEN_GENERATOR" "$GOOGLE_APPLICATION_CREDENTIALS" 2>&1); then
      echo "✅ Access token obtained: ${TOKEN:0:20}..."
    else
      echo "❌ Error: Could not generate token from service account"
      echo ""
      echo "Python error: $TOKEN"
      echo ""
      echo "Install dependencies: ./bin/install-dependencies.sh"
      exit 1
    fi
  else
    echo "❌ Error: Token generator not found: $TOKEN_GENERATOR"
    exit 1
  fi
else
  # Fallback to gcloud (may not have proper scopes)
  echo "⚠️  GOOGLE_APPLICATION_CREDENTIALS not set, trying gcloud..."
  if TOKEN=$(gcloud auth application-default print-access-token 2>&1); then
    echo "✅ Access token obtained: ${TOKEN:0:20}..."
    echo "⚠️  Warning: This may not have Search Console scopes"
  else
    echo "❌ Error: Could not get access token"
    echo ""
    echo "Try running: ./bin/setup-google-auth.sh"
    exit 1
  fi
fi

echo ""

# Test 1: List all GSC sites
echo "📋 Test 1: Fetching all GSC sites you have access to..."
echo ""

SITES_RESPONSE=$(curl -s "https://www.googleapis.com/webmasters/v3/sites" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

# Check for error
if echo "$SITES_RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
  echo "❌ API Error:"
  echo "$SITES_RESPONSE" | jq '.error'
  echo ""
  echo "Common issues:"
  echo "  • Service account not added to Google Search Console"
  echo "  • Search Console API not enabled in Google Cloud"
  echo ""
  echo "Run: ./bin/setup-google-auth.sh (follow instructions)"
  exit 1
fi

# Count sites
SITE_COUNT=$(echo "$SITES_RESPONSE" | jq -r '.siteEntry // [] | length')

if [[ "$SITE_COUNT" -eq 0 ]]; then
  echo "⚠️  No sites found!"
  echo ""
  echo "This means the service account has not been added to any GSC properties."
  echo ""
  echo "Add service account to GSC:"
  if [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    SERVICE_EMAIL=$(jq -r '.client_email' "$GOOGLE_APPLICATION_CREDENTIALS")
    echo "  Email: $SERVICE_EMAIL"
  fi
  echo "  URL: https://search.google.com/search-console"
  echo ""
  exit 1
else
  echo "✅ Found $SITE_COUNT site(s):"
  echo ""
  echo "$SITES_RESPONSE" | jq -r '.siteEntry[] | "  • \(.siteUrl) (\(.permissionLevel))"'
  echo ""
fi

# Test 2: Test specific client if provided
if [[ -n "$CLIENT_ID" ]]; then
  CONFIG="$REPO_ROOT/workspace/$CLIENT_ID/seo/config.yaml"

  if [[ ! -f "$CONFIG" ]]; then
    echo "⚠️  Client config not found: $CONFIG"
    echo ""
    echo "Available clients:"
    find "$REPO_ROOT/workspace" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -exec basename {} \;
    echo ""
    exit 1
  fi

  SITE_URL=$(grep '^site:' "$CONFIG" | awk '{print $2}' | tr -d '"')

  if [[ -z "$SITE_URL" ]]; then
    echo "❌ Error: No site URL found in config"
    exit 1
  fi

  echo "📋 Test 2: Checking access to client site..."
  echo "   Client: $CLIENT_ID"
  echo "   Site: $SITE_URL"
  echo ""

  # Check if site is in the list
  if echo "$SITES_RESPONSE" | jq -e ".siteEntry[] | select(.siteUrl == \"$SITE_URL\")" >/dev/null 2>&1; then
    PERMISSION=$(echo "$SITES_RESPONSE" | jq -r ".siteEntry[] | select(.siteUrl == \"$SITE_URL\") | .permissionLevel")
    echo "✅ Access confirmed!"
    echo "   Permission level: $PERMISSION"
    echo ""

    # Try to fetch some data
    echo "📊 Test 3: Fetching sample data (last 7 days)..."
    echo ""

    START_DATE=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)

    QUERY_RESPONSE=$(curl -s "https://www.googleapis.com/webmasters/v3/sites/$SITE_URL/searchAnalytics/query" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"startDate\": \"$START_DATE\",
        \"endDate\": \"$END_DATE\",
        \"dimensions\": [\"query\"],
        \"rowLimit\": 5
      }")

    if echo "$QUERY_RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
      echo "❌ Error fetching data:"
      echo "$QUERY_RESPONSE" | jq '.error'
    else
      ROW_COUNT=$(echo "$QUERY_RESPONSE" | jq -r '.rows // [] | length')
      if [[ "$ROW_COUNT" -gt 0 ]]; then
        echo "✅ Successfully fetched $ROW_COUNT sample keywords!"
        echo ""
        echo "Sample keywords:"
        echo "$QUERY_RESPONSE" | jq -r '.rows[] | "  • \(.keys[0]) - \(.impressions) impressions"' | head -5
        echo ""
      else
        echo "⚠️  No data returned (site may be new or have no search traffic)"
        echo ""
      fi
    fi
  else
    echo "❌ No access to this site!"
    echo ""
    echo "Service account needs to be added to: $SITE_URL"
    echo ""
    if [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
      SERVICE_EMAIL=$(jq -r '.client_email' "$GOOGLE_APPLICATION_CREDENTIALS")
      echo "Add this email to GSC:"
      echo "  $SERVICE_EMAIL"
      echo ""
      echo "Steps:"
      echo "  1. Go to: https://search.google.com/search-console"
      echo "  2. Select property: $SITE_URL"
      echo "  3. Settings → Users and permissions → Add user"
      echo "  4. Enter: $SERVICE_EMAIL"
      echo "  5. Permission: Full"
    fi
    echo ""
    exit 1
  fi
fi

echo "╔════════════════════════════════════════════════════════════"
echo "║ All Tests Passed! ✅"
echo "╚════════════════════════════════════════════════════════════"
echo ""
echo "You're ready to run SEO automation!"
echo ""
echo "Try:"
echo "  ./bin/run-discovery.sh $CLIENT_ID --limit 5"
echo "  ./bin/run-monitor.sh $CLIENT_ID"
echo ""
