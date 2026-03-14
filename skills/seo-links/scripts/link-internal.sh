#!/usr/bin/env bash
# link-internal.sh — Audit internal link structure
set -e

DOMAIN="${1:?Usage: link-internal.sh <your-domain> [--sitemap URL]}"
SITEMAP="${3:-https://${DOMAIN}/sitemap.xml}"

echo "🕸️ Auditing internal links for: $DOMAIN"
echo "Sitemap: $SITEMAP"

# Fetch sitemap and extract URLs
echo ""
echo "Fetching sitemap..."
URLS=$(curl -s -A "Mozilla/5.0 (compatible; SEOKit/1.0)"L "$SITEMAP" 2>/dev/null | grep -oP '<loc>\K[^<]+' | head -50)

if [[ -z "$URLS" ]]; then
  echo "No sitemap found or empty. Trying sitemap_index..."
  URLS=$(curl -s -A "Mozilla/5.0 (compatible; SEOKit/1.0)"L "$SITEMAP" 2>/dev/null | grep -oP '<loc>\K[^<]+' | head -5 | while read -r SUB; do
    curl -s -A "Mozilla/5.0 (compatible; SEOKit/1.0)"L "$SUB" 2>/dev/null | grep -oP '<loc>\K[^<]+' | head -20
  done)
fi

if [[ -z "$URLS" ]]; then
  echo "No sitemap found. Crawling site to discover pages..."

  # Simple bash-based crawler
  declare -A VISITED
  declare -A TO_CRAWL
  DISCOVERED_URLS=""

  # Start with homepage
  TO_CRAWL["https://${DOMAIN}/"]=1
  MAX_PAGES=50
  PAGE_COUNT=0

  echo "Starting crawl from https://${DOMAIN}/ (max: $MAX_PAGES pages)"

  while [[ ${#TO_CRAWL[@]} -gt 0 ]] && [[ $PAGE_COUNT -lt $MAX_PAGES ]]; do
    # Get first URL to crawl
    CURRENT_URL=""
    for url in "${!TO_CRAWL[@]}"; do
      CURRENT_URL="$url"
      break
    done

    # Remove from TO_CRAWL
    unset TO_CRAWL["$CURRENT_URL"]

    # Skip if already visited
    if [[ -n "${VISITED[$CURRENT_URL]:-}" ]]; then
      continue
    fi

    # Mark as visited
    VISITED["$CURRENT_URL"]=1
    DISCOVERED_URLS="$DISCOVERED_URLS$CURRENT_URL"$'\n'
    PAGE_COUNT=$((PAGE_COUNT + 1))

    echo "Crawling [$PAGE_COUNT/$MAX_PAGES]: $CURRENT_URL"

    # Fetch page and extract links
    PAGE_HTML=$(curl -s -L -A "Mozilla/5.0 (compatible; SEOBot/1.0)" --max-time 10 "$CURRENT_URL" 2>/dev/null || true)

    if [[ -z "$PAGE_HTML" ]]; then
      continue
    fi

    # Extract all href links
    LINKS=$(echo "$PAGE_HTML" | grep -oP 'href=["'\'']\K[^"'\'']+' | grep -v '^#' | grep -v '^javascript:' | grep -v '^mailto:' | grep -v '^tel:' || true)

    # Process each link
    while IFS= read -r LINK; do
      [[ -z "$LINK" ]] && continue

      # Convert relative URLs to absolute
      if [[ "$LINK" =~ ^https?:// ]]; then
        FULL_URL="$LINK"
      elif [[ "$LINK" =~ ^/ ]]; then
        FULL_URL="https://${DOMAIN}${LINK}"
      else
        # Skip relative paths without leading slash
        continue
      fi

      # Only add if it's on the same domain and not visited
      if [[ "$FULL_URL" =~ ^https?://(www\.)?${DOMAIN} ]] && [[ -z "${VISITED[$FULL_URL]:-}" ]]; then
        # Remove URL fragments and query strings for crawling purposes
        CLEAN_URL=$(echo "$FULL_URL" | sed 's/#.*//' | sed 's/?.*//')
        TO_CRAWL["$CLEAN_URL"]=1
      fi
    done <<< "$LINKS"

    # Rate limiting
    sleep 0.2
  done

  URLS=$(echo "$DISCOVERED_URLS" | sed '/^$/d')

  if [[ -z "$URLS" ]]; then
    echo "❌ No URLs discovered during crawl"
    exit 1
  fi

  URL_COUNT=$(echo "$URLS" | wc -l)
  echo "✅ Crawled and discovered $URL_COUNT pages"
fi

URL_COUNT=$(echo "$URLS" | wc -l)
echo "Found $URL_COUNT pages"
echo ""

# Check internal links for each page
echo "Analyzing internal link structure..."
echo "======================================"

declare -A INBOUND_COUNT

# First pass: count inbound links
while IFS= read -r PAGE; do
  SLUG=$(echo "$PAGE" | sed "s|https://${DOMAIN}||")
  INBOUND_COUNT["$SLUG"]=0
done <<< "$URLS"

while IFS= read -r PAGE; do
  BODY=$(curl -s -A "Mozilla/5.0 (compatible; SEOKit/1.0)"L --max-time 10 "$PAGE" 2>/dev/null)
  INTERNAL_LINKS=$(echo "$BODY" | grep -oP "href=\"\K[^\"]*" | grep -E "^/|^https://${DOMAIN}" | sed "s|https://${DOMAIN}||" | sort -u)
  
  SLUG=$(echo "$PAGE" | sed "s|https://${DOMAIN}||")
  LINK_COUNT=$(echo "$INTERNAL_LINKS" | grep -c . || true)
  
  echo "📄 ${SLUG} → ${LINK_COUNT} outbound internal links"
  
  # Count inbound
  while IFS= read -r LINK; do
    [[ -z "$LINK" ]] && continue
    CURRENT="${INBOUND_COUNT[$LINK]:-0}"
    INBOUND_COUNT["$LINK"]=$((CURRENT + 1))
  done <<< "$INTERNAL_LINKS"
  
done <<< "$(echo "$URLS" | head -20)"

echo ""
echo "======================================"
echo "🏝️ ORPHAN PAGES (0 inbound internal links):"
for SLUG in "${!INBOUND_COUNT[@]}"; do
  if [[ "${INBOUND_COUNT[$SLUG]}" -eq 0 ]]; then
    echo "  ⚠️  $SLUG"
  fi
done

echo ""
echo "📊 THIN INTERNAL LINKING (< 3 inbound):"
for SLUG in "${!INBOUND_COUNT[@]}"; do
  COUNT="${INBOUND_COUNT[$SLUG]}"
  if [[ "$COUNT" -gt 0 && "$COUNT" -lt 3 ]]; then
    echo "  ⚡ $SLUG ($COUNT inbound links)"
  fi
done
