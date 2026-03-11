#!/usr/bin/env bash
# find-location-code.sh — Find DataForSEO location code for a city
#
# Usage: bin/find-location-code.sh "Atlanta, GA"

set -euo pipefail

SEARCH_TERM="${1:?Usage: find-location-code.sh \"City, State\"}"

# Check for credentials
if [[ -z "${DATAFORSEO_LOGIN:-}" || -z "${DATAFORSEO_PASSWORD:-}" ]]; then
  # Try loading from .env
  if [[ -f ".env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  fi
fi

if [[ -z "${DATAFORSEO_LOGIN:-}" || -z "${DATAFORSEO_PASSWORD:-}" ]]; then
  echo "ERROR: DataForSEO credentials not found" >&2
  echo "Set DATAFORSEO_LOGIN and DATAFORSEO_PASSWORD in .env or environment" >&2
  exit 1
fi

echo "🔍 Searching for: $SEARCH_TERM"
echo ""

RESPONSE=$(curl -s "https://api.dataforseo.com/v3/serp/google/locations" \
  -u "${DATAFORSEO_LOGIN}:${DATAFORSEO_PASSWORD}" \
  -G --data-urlencode "search=$SEARCH_TERM")

# Check for errors
if echo "$RESPONSE" | jq -e '.status_code != 20000' >/dev/null 2>&1; then
  echo "ERROR: $(echo "$RESPONSE" | jq -r '.status_message')" >&2
  exit 1
fi

# Parse and display results
RESULTS=$(echo "$RESPONSE" | jq -r '
  .tasks[0].result[] |
  "  \(.location_code) - \(.location_name), \(.country_iso_code) (type: \(.location_type))"
')

if [[ -z "$RESULTS" ]]; then
  echo "No results found for \"$SEARCH_TERM\""
  echo ""
  echo "Try searching with different formats:"
  echo "  - \"Atlanta\""
  echo "  - \"Atlanta, GA\""
  echo "  - \"Atlanta Georgia\""
  exit 0
fi

echo "📍 Found locations:"
echo "$RESULTS"
echo ""
echo "Usage: Copy the location code to your client's config.yaml"
echo "       Example: location_code: 1014044  # Atlanta, GA"
