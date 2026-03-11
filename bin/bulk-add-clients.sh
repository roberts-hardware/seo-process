#!/usr/bin/env bash
# Bulk add clients from CSV file
# Usage: ./bin/bulk-add-clients.sh clients.csv

set -euo pipefail

CSV_FILE="${1:?Usage: bulk-add-clients.sh <csv-file>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "❌ Error: CSV file not found: $CSV_FILE"
  exit 1
fi

echo "╔════════════════════════════════════════════════════════════"
echo "║ Bulk Client Onboarding from CSV"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# Count clients (excluding header)
TOTAL_CLIENTS=$(($(wc -l < "$CSV_FILE") - 1))
echo "Found $TOTAL_CLIENTS clients in CSV"
echo ""

CURRENT=0
SUCCESS=0
FAILED=0

# Read CSV line by line (skip header)
tail -n +2 "$CSV_FILE" | while IFS=, read -r client_id site_url business_type phone years_in_business \
  primary_city_1 zip_1 response_time_1 \
  primary_city_2 zip_2 response_time_2 \
  primary_city_3 zip_3 response_time_3 \
  secondary_cities services competitors \
  location_code min_search_volume state county || [[ -n "$client_id" ]]; do

  ((CURRENT++)) || true

  echo "─────────────────────────────────────────────────────────"
  echo "[$CURRENT/$TOTAL_CLIENTS] Onboarding: $client_id"
  echo "─────────────────────────────────────────────────────────"
  echo ""

  # Validate required fields
  if [[ -z "$client_id" ]] || [[ -z "$site_url" ]]; then
    echo "❌ Skipping: Missing client_id or site_url"
    ((FAILED++)) || true
    continue
  fi

  # Create client directory structure
  WORKSPACE="$REPO_ROOT/workspace/$client_id"

  if [[ -d "$WORKSPACE" ]]; then
    echo "⚠️  Client already exists: $client_id (skipping)"
    continue
  fi

  echo "Creating workspace..."
  mkdir -p "$WORKSPACE/seo/snapshots"
  mkdir -p "$WORKSPACE/seo/health"
  mkdir -p "$WORKSPACE/brand"
  mkdir -p "$WORKSPACE/content"

  # Parse competitors
  COMPETITORS_YAML=""
  if [[ -n "$competitors" ]]; then
    IFS=';' read -ra COMP_ARRAY <<< "$competitors"
    for comp in "${COMP_ARRAY[@]}"; do
      comp=$(echo "$comp" | xargs | sed -e 's|https\?://||' -e 's|/$||' -e 's|www\.||')
      COMPETITORS_YAML+="  - $comp"$'\n'
    done
  fi

  # Parse services
  SERVICES_YAML=""
  if [[ -n "$services" ]]; then
    IFS=';' read -ra SERVICE_ARRAY <<< "$services"
    for svc in "${SERVICE_ARRAY[@]}"; do
      svc=$(echo "$svc" | xargs | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
      SERVICES_YAML+="  - \"$svc\""$'\n'
    done
  fi

  # Parse secondary cities
  SECONDARY_YAML=""
  if [[ -n "$secondary_cities" ]]; then
    IFS=';' read -ra SECONDARY_ARRAY <<< "$secondary_cities"
    for city in "${SECONDARY_ARRAY[@]}"; do
      city=$(echo "$city" | xargs)
      SECONDARY_YAML+="    - \"$city\""$'\n'
    done
  fi

  # Build primary service areas
  PRIMARY_AREAS=""
  if [[ -n "$primary_city_1" ]]; then
    PRIMARY_AREAS+="    - name: \"$primary_city_1\""$'\n'
    PRIMARY_AREAS+="      zip: \"$zip_1\""$'\n'
    PRIMARY_AREAS+="      response_time: \"$response_time_1\""$'\n'
  fi
  if [[ -n "$primary_city_2" ]]; then
    PRIMARY_AREAS+="    - name: \"$primary_city_2\""$'\n'
    PRIMARY_AREAS+="      zip: \"$zip_2\""$'\n'
    PRIMARY_AREAS+="      response_time: \"$response_time_2\""$'\n'
  fi
  if [[ -n "$primary_city_3" ]]; then
    PRIMARY_AREAS+="    - name: \"$primary_city_3\""$'\n'
    PRIMARY_AREAS+="      zip: \"$zip_3\""$'\n'
    PRIMARY_AREAS+="      response_time: \"$response_time_3\""$'\n'
  fi

  # Parse domain from URL
  DOMAIN=$(echo "$site_url" | sed -e 's|https\?://||' -e 's|/$||' -e 's|www\.||')

  # Create config file
  cat > "$WORKSPACE/seo/config.yaml" <<EOF
# SEO Process Client Configuration
# Client: $client_id

client_id: $client_id
site: "sc-domain:$DOMAIN"
site_url: "$site_url"
business_type: "${business_type:-roofing}"

phone: "${phone:-(000) 000-0000}"
years_in_business: ${years_in_business:-25}

licenses:
  - "License TBD"
certifications:
  - "Certification TBD"

service_areas:
  primary:
$PRIMARY_AREAS  secondary:
$SECONDARY_YAML

services:
$SERVICES_YAML

competitors:
$COMPETITORS_YAML

target_positions: [5, 20]
min_search_volume: ${min_search_volume:-30}
location_code: ${location_code:-2840}

language: "en"
state: "${state:-PA}"
county: "${county:-County Name}"

schedule:
  discover: "Sunday 8pm"
  monitor: "Sunday 9pm"
  health: "Monday 9am"
  compete: "Friday 3pm"
EOF

  # Create .gitkeep files
  touch "$WORKSPACE/brand/.gitkeep"
  touch "$WORKSPACE/content/.gitkeep"
  touch "$WORKSPACE/seo/snapshots/.gitkeep"
  touch "$WORKSPACE/seo/health/.gitkeep"

  echo "✅ Created: $client_id"
  echo "   Site: $site_url"
  echo "   Type: ${business_type:-roofing}"
  echo ""

  ((SUCCESS++)) || true

done

echo ""
echo "╔════════════════════════════════════════════════════════════"
echo "║ Bulk Onboarding Complete"
echo "╚════════════════════════════════════════════════════════════"
echo ""
echo "✅ Success: $SUCCESS clients"
echo "❌ Failed: $FAILED clients"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Review each client config:"
echo "   ls workspace/*/seo/config.yaml"
echo ""
echo "2. Find location codes for each client:"
echo "   ./bin/find-location-code.sh \"City, State\""
echo ""
echo "3. Update configs with correct location codes"
echo ""
echo "4. Add service account to each client's GSC property:"
echo "   seo-process-automation@raleigh-seo-kit.iam.gserviceaccount.com"
echo ""
echo "5. Test each client:"
echo "   ./bin/test-gsc-access.sh <client-id>"
echo ""
echo "6. Commit to git:"
echo "   git add workspace/"
echo "   git commit -m \"Bulk onboard $SUCCESS clients\""
echo "   git push"
echo ""
