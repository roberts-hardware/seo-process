#!/usr/bin/env bash
# Add a new client to the SEO process system
# Usage: ./bin/add-client.sh <client-id> <site-url> <competitors>
#
# Example:
#   ./bin/add-client.sh acmeplumbing https://acmeplumbing.com "competitor1.com,competitor2.com"

set -euo pipefail

CLIENT_ID="${1:?Usage: add-client.sh <client-id> <site-url> <competitors>}"
SITE_URL="${2:?Usage: add-client.sh <client-id> <site-url> <competitors>}"
COMPETITORS="${3:-}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$REPO_ROOT/workspace/$CLIENT_ID"

# Validate client ID format (lowercase, alphanumeric, dashes/underscores only)
if [[ ! "$CLIENT_ID" =~ ^[a-z0-9_-]+$ ]]; then
  echo "❌ Error: Client ID must be lowercase, alphanumeric, with dashes/underscores only"
  echo "   Example: acmeplumbing, ace-roofing, joes_hvac"
  exit 1
fi

# Check if client already exists
if [[ -d "$WORKSPACE" ]]; then
  echo "⚠️  Warning: Client workspace already exists: $WORKSPACE"
  echo ""
  read -p "Overwrite existing client? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
  echo "Removing existing workspace..."
  rm -rf "$WORKSPACE"
fi

echo "🎯 Adding new client: $CLIENT_ID"
echo "   Site: $SITE_URL"
[[ -n "$COMPETITORS" ]] && echo "   Competitors: $COMPETITORS"
echo ""

# Create directory structure
echo "📁 Creating workspace structure..."
mkdir -p "$WORKSPACE/seo/snapshots"
mkdir -p "$WORKSPACE/seo/health"
mkdir -p "$WORKSPACE/brand"
mkdir -p "$WORKSPACE/content"

# Parse domain from URL
DOMAIN=$(echo "$SITE_URL" | sed -e 's|https\?://||' -e 's|/$||' -e 's|www\.||')

# Format competitors for YAML
COMPETITORS_YAML=""
if [[ -n "$COMPETITORS" ]]; then
  IFS=',' read -ra COMP_ARRAY <<< "$COMPETITORS"
  for comp in "${COMP_ARRAY[@]}"; do
    comp=$(echo "$comp" | xargs) # trim whitespace
    comp=$(echo "$comp" | sed -e 's|https\?://||' -e 's|/$||' -e 's|www\.||')
    COMPETITORS_YAML+="  - $comp"$'\n'
  done
else
  COMPETITORS_YAML="  # - competitor1.com"$'\n'"  # - competitor2.com"$'\n'
fi

# Create config file
echo "⚙️  Creating configuration file..."
cat > "$WORKSPACE/seo/config.yaml" <<EOF
# SEO Process Client Configuration
# Client: $CLIENT_ID

# Client identifier (lowercase, dashes for spaces)
client_id: $CLIENT_ID

# Google Search Console property URL
# Format: sc-domain:example.com  OR  https://example.com/
site: "sc-domain:$DOMAIN"

# Actual website URL (used for health checks)
site_url: "$SITE_URL"

# Business type (determines content templates)
# Options: roofing, plumbing, hvac, electrical, landscaping, general_contractor
business_type: "roofing"

# Client contact information
phone: "(000) 000-0000"  # TODO: Add real phone number
years_in_business: 25     # TODO: Update

# Licenses and certifications
licenses:
  - "License #123456"     # TODO: Add real licenses
certifications:
  - "Certification Name"  # TODO: Add certifications

# Service areas
service_areas:
  primary:
    - name: "City Name"           # TODO: Add primary service cities
      zip: "00000"
      response_time: "30-60 min"
  secondary:
    - "Secondary City 1"          # TODO: Add secondary areas
    - "Secondary City 2"

# Services offered
services:
  - "service_1"                   # TODO: Replace with actual services
  - "service_2"                   # Example: commercial_roofing, residential_roofing
  - "service_3"

# Competitor domains to monitor (for gap analysis)
competitors:
$COMPETITORS_YAML

# Strike zone: Target ranking positions to prioritize
# Default [5, 20] means positions 5-20 (page 1-2)
target_positions: [5, 20]

# Minimum monthly search volume to consider
# Lower for local SEO since search volumes are smaller
# Local businesses: 20-50
# Regional businesses: 50-100
# National: 100+
min_search_volume: 30

# DataForSEO location code
# IMPORTANT: Use CITY-level for local SEO, not country-level!
#
# Find your location code:
#   ./bin/find-location-code.sh "City Name, State"
#
# Examples:
#   1021866 = Cranberry Township, PA
#   1023768 = Los Angeles, CA
#   1023191 = New York, NY
#   1021621 = Chicago, IL
#   2840 = United States (too broad - don't use for local!)
#
# See: https://docs.dataforseo.com/v3/serp/google/locations/
location_code: 2840  # TODO: Change to city-level! Run ./bin/find-location-code.sh

# Language code
language: "en"

# Geographic info (for templates)
state: "PA"           # TODO: Update
county: "County Name" # TODO: Update

# Optional: Schedule reference (not enforced by scripts)
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

echo "✅ Client workspace created!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Edit configuration file:"
echo "   nano $WORKSPACE/seo/config.yaml"
echo ""
echo "   Required updates:"
echo "   - business_type (roofing, plumbing, hvac, etc.)"
echo "   - phone number"
echo "   - service_areas (primary cities)"
echo "   - services offered"
echo "   - location_code (CITY-level, not country!)"
echo "   - state and county"
echo ""
echo "2. Find location code for city-level targeting:"
echo "   ./bin/find-location-code.sh \"City Name, State\""
echo ""
echo "3. Ensure GSC access:"
echo "   - Add service account to Google Search Console"
echo "   - Property: $DOMAIN"
echo ""
echo "4. (Optional) Run brand interview:"
echo "   clawd skills/seo-forge/brand-interview.md"
echo "   # Save to: $WORKSPACE/brand/voice.md"
echo ""
echo "5. Run initial discovery:"
echo "   ./bin/run-for-client.sh $CLIENT_ID skills/seo-agent/scripts/seo-discover.sh --limit 20"
echo ""
echo "6. Run initial monitoring:"
echo "   ./bin/run-for-client.sh $CLIENT_ID skills/seo-agent/scripts/seo-monitor.sh"
echo ""
echo "7. Generate content briefs:"
echo "   ./bin/generate-content-briefs.sh $CLIENT_ID"
echo ""
echo "8. Commit to git:"
echo "   git add workspace/$CLIENT_ID"
echo "   git commit -m \"Add client: $CLIENT_ID\""
echo "   git push"
echo ""
echo "📁 Workspace: $WORKSPACE"
