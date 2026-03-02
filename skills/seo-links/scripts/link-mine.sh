#!/usr/bin/env bash
# link-mine.sh — Mine competitor backlinks via DataForSEO or web search fallback
set -euo pipefail

COMPETITOR="${1:?Usage: link-mine.sh <competitor-domain> [--limit 50]}"
LIMIT=50
YOUR_DOMAIN=""

while [[ $# -gt 1 ]]; do
  case "$2" in
    --limit) LIMIT="$3"; shift 2 ;;
    --domain) YOUR_DOMAIN="$3"; shift 2 ;;
    *) shift ;;
  esac
done

echo "🔗 Mining backlinks for: $COMPETITOR (limit: $LIMIT)"

if [[ -n "${DATAFORSEO_LOGIN:-}" && -n "${DATAFORSEO_PASSWORD:-}" ]]; then
  echo "Using DataForSEO Backlinks API..."
  
  RESPONSE=$(curl -s -X POST "https://api.dataforseo.com/v3/backlinks/backlinks/live" \
    -u "${DATAFORSEO_LOGIN}:${DATAFORSEO_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d "[{
      \"target\": \"${COMPETITOR}\",
      \"mode\": \"as_is\",
      \"limit\": ${LIMIT},
      \"order_by\": [\"rank,desc\"],
      \"filters\": [\"dofollow\",\"=\",true]
    }]")
  
  echo "$RESPONSE" | jq -r '
    .tasks[0].result[0].items[]? | 
    "DR: \(.domain_from_rank // "?") | \(.url_from) | Anchor: \(.anchor // "none") | Type: \(.type // "unknown")"
  ' 2>/dev/null || echo "Error parsing DataForSEO response"
  
  TOTAL=$(echo "$RESPONSE" | jq -r '.tasks[0].result[0].total_count // 0')
  echo ""
  echo "Total backlinks found: $TOTAL (showing top $LIMIT)"
  
else
  echo "No DataForSEO credentials. Using web search fallback..."
  echo ""
  echo "Searching for resource pages linking to $COMPETITOR..."
  echo "---"
  
  QUERIES=(
    "\"${COMPETITOR}\" resources"
    "\"${COMPETITOR}\" best tools"
    "\"${COMPETITOR}\" roundup"
    "\"${COMPETITOR}\" review"
    "\"${COMPETITOR}\" alternative"
  )
  
  for Q in "${QUERIES[@]}"; do
    echo "Query: $Q"
    echo "(Run this in your browser or via web_search tool)"
    echo ""
  done
  
  echo "Tip: For full backlink data, set up DataForSEO (\$50/month)."
  echo "Without it, you can still find resource pages and roundups manually."
fi
