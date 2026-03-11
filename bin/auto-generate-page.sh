#!/usr/bin/env bash
# Auto-generate page content from template + client config
# Usage: ./bin/auto-generate-page.sh <client-id> <service|location> <page-name>

set -euo pipefail

CLIENT_ID="${1:?Usage: auto-generate-page.sh <client-id> <service|location> <page-name>}"
PAGE_TYPE="${2:?Usage: auto-generate-page.sh <client-id> <service|location> <page-name>}"
PAGE_NAME="${3:?Usage: auto-generate-page.sh <client-id> <service|location> <page-name>}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$REPO_ROOT/workspace/$CLIENT_ID"
CONFIG="$WORKSPACE/seo/config.yaml"
CONTENT_DIR="$WORKSPACE/content"

# Validate inputs
if [[ "$PAGE_TYPE" != "service" ]] && [[ "$PAGE_TYPE" != "location" ]]; then
  echo "❌ Error: PAGE_TYPE must be 'service' or 'location'"
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Error: Config file not found: $CONFIG"
  exit 1
fi

mkdir -p "$CONTENT_DIR"

echo "🤖 Auto-generating $PAGE_TYPE page: $PAGE_NAME"
echo ""

# Load client configuration
BUSINESS_TYPE=$(grep '^business_type:' "$CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "roofing")
COMPANY_NAME=$(echo "$CLIENT_ID" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
PHONE=$(grep '^phone:' "$CONFIG" 2>/dev/null | awk '{$1=""; print $0}' | tr -d '"' | xargs || echo "(000) 000-0000")
YEARS=$(grep '^years_in_business:' "$CONFIG" 2>/dev/null | awk '{print $2}' || echo "25")
SITE_URL=$(grep '^site_url:' "$CONFIG" | awk '{print $2}' | tr -d '"')
STATE=$(grep '^state:' "$CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "PA")
COUNTY=$(grep '^county:' "$CONFIG" 2>/dev/null | awk '{$1=""; print $0}' | tr -d '"' | xargs || echo "County")

# Extract primary service areas
PRIMARY_AREAS=$(grep -A 50 'service_areas:' "$CONFIG" 2>/dev/null | grep -A 30 'primary:' | grep 'name:' | awk -F'"' '{print $2}' || echo "")
SERVICES=$(grep -A 50 'services:' "$CONFIG" 2>/dev/null | grep '  - ' | sed 's/  - //' | tr -d '"' || echo "")

echo "Configuration loaded:"
echo "  Business: $BUSINESS_TYPE"
echo "  Company: $COMPANY_NAME"
echo "  Phone: $PHONE"
echo "  Years: $YEARS"
echo "  State: $STATE"
echo "  County: $COUNTY"
echo ""

# Select template
if [[ "$PAGE_TYPE" == "service" ]]; then
  TEMPLATE="$REPO_ROOT/templates/$BUSINESS_TYPE/$PAGE_NAME.md"

  # Fallback to generic service hub template
  if [[ ! -f "$TEMPLATE" ]]; then
    TEMPLATE="$REPO_ROOT/templates/$BUSINESS_TYPE/service-hub-template.md"
  fi

  # Fallback to generic template across all business types
  if [[ ! -f "$TEMPLATE" ]]; then
    TEMPLATE="$REPO_ROOT/templates/service-hub-template.md"
  fi

  OUTPUT_FILE="$CONTENT_DIR/$PAGE_NAME.md"

else # location
  TEMPLATE="$REPO_ROOT/templates/$BUSINESS_TYPE/location-hub.md"

  # Fallback to generic location hub template
  if [[ ! -f "$TEMPLATE" ]]; then
    TEMPLATE="$REPO_ROOT/templates/location-hub-template.md"
  fi

  OUTPUT_FILE="$CONTENT_DIR/location-$PAGE_NAME.md"
fi

# Check if template exists
if [[ ! -f "$TEMPLATE" ]]; then
  echo "⚠️  Warning: Template not found: $TEMPLATE"
  echo ""
  echo "Creating basic template placeholder..."

  # Create a basic template
  cat > "$OUTPUT_FILE" <<EOF
---
title: "TITLE PLACEHOLDER - Edit This"
meta_description: "META DESCRIPTION PLACEHOLDER"
url_slug: "/$PAGE_NAME/"
page_type: "$PAGE_TYPE"
---

# HEADLINE PLACEHOLDER

[INTRODUCTION PARAGRAPH - Replace with actual content]

**Phone:** $PHONE

---

## Section 1

[Content here]

## Section 2

[Content here]

## Get Started

Call us today: $PHONE

---

⚠️ **This page was auto-generated without a template.**
⚠️ **Please write full content using the brief in: $CONTENT_DIR/brief-$PAGE_NAME.md**
EOF

  echo "✅ Created placeholder: $OUTPUT_FILE"
  echo ""
  echo "⚠️  No template found. You'll need to write this page manually."
  echo "📋 Use the content brief: $CONTENT_DIR/brief-$PAGE_NAME.md"
  exit 0
fi

echo "Using template: $TEMPLATE"
echo ""

# Helper function to convert snake_case to Title Case
to_title_case() {
  echo "$1" | sed 's/_/ /g' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1'
}

# For service pages
if [[ "$PAGE_TYPE" == "service" ]]; then
  SERVICE_NAME=$(to_title_case "$PAGE_NAME")

  # Generate service area links section
  SERVICE_AREAS_SECTION=""
  while IFS= read -r AREA; do
    [[ -z "$AREA" ]] && continue
    AREA_SLUG=$(echo "$AREA" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    SERVICE_AREAS_SECTION+="### $AREA

[Paragraph about serving $AREA with $SERVICE_NAME services. Mention local expertise, response times, and projects completed.]

[Learn more about our $AREA services →](/$AREA_SLUG/)

"
  done <<< "$PRIMARY_AREAS"

  # Replace placeholders
  sed -e "s|{{COMPANY_NAME}}|$COMPANY_NAME|g" \
      -e "s|{{PHONE}}|$PHONE|g" \
      -e "s|{{YEARS_IN_BUSINESS}}|$YEARS|g" \
      -e "s|{{STATE}}|$STATE|g" \
      -e "s|{{COUNTY}}|$COUNTY|g" \
      -e "s|{{SERVICE_NAME}}|$SERVICE_NAME|g" \
      -e "s|{{SERVICE_SLUG}}|$PAGE_NAME|g" \
      -e "s|{{SITE_URL}}|$SITE_URL|g" \
      -e "s|{{BUSINESS_TYPE}}|$BUSINESS_TYPE|g" \
      -e "s|{{SERVICE_AREAS_SECTION}}|$SERVICE_AREAS_SECTION|g" \
      "$TEMPLATE" > "$OUTPUT_FILE"

else # location
  LOCATION_NAME=$(to_title_case "$PAGE_NAME")

  # Generate services section
  SERVICES_SECTION=""
  while IFS= read -r SERVICE; do
    [[ -z "$SERVICE" ]] && continue
    SERVICE_TITLE=$(to_title_case "$SERVICE")
    SERVICES_SECTION+="### $SERVICE_TITLE

[Brief description of $SERVICE_TITLE services in $LOCATION_NAME. Mention local projects and expertise.]

[Complete $SERVICE_TITLE services →](/$SERVICE/)

"
  done <<< "$SERVICES"

  # Replace placeholders
  sed -e "s|{{COMPANY_NAME}}|$COMPANY_NAME|g" \
      -e "s|{{PHONE}}|$PHONE|g" \
      -e "s|{{YEARS_IN_BUSINESS}}|$YEARS|g" \
      -e "s|{{STATE}}|$STATE|g" \
      -e "s|{{COUNTY}}|$COUNTY|g" \
      -e "s|{{LOCATION_NAME}}|$LOCATION_NAME|g" \
      -e "s|{{LOCATION_SLUG}}|$PAGE_NAME|g" \
      -e "s|{{SITE_URL}}|$SITE_URL|g" \
      -e "s|{{BUSINESS_TYPE}}|$BUSINESS_TYPE|g" \
      -e "s|{{SERVICES_SECTION}}|$SERVICES_SECTION|g" \
      "$TEMPLATE" > "$OUTPUT_FILE"
fi

echo "✅ Generated: $OUTPUT_FILE"
echo ""
echo "📊 Status: ~80% complete"
echo ""
echo "✏️  Next steps:"
echo "1. Open: $OUTPUT_FILE"
echo "2. Review content brief: $CONTENT_DIR/brief-$PAGE_NAME.md"
echo "3. Fill in placeholder sections marked [...]"
echo "4. Add location-specific or service-specific details"
echo "5. Customize examples and case studies"
echo "6. Review internal links"
echo "7. Estimated time to complete: 1-2 hours"
echo ""
echo "💡 Tip: Search for '[' to find sections needing customization"
