#!/usr/bin/env bash
set -euo pipefail

echo "Testing GSC API access with application default credentials..."
TOKEN=$(gcloud auth application-default print-access-token)
echo "Token obtained: ${TOKEN:0:20}..."

echo ""
echo "Fetching GSC sites list..."
curl -s "https://www.googleapis.com/webmasters/v3/sites" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq '.'
