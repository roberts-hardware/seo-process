#!/usr/bin/env bash
# Update location codes and run discovery for first 5 clients
# Run this on the server where DataForSEO credentials work

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "╔════════════════════════════════════════════════════════════"
echo "║ Updating Location Codes & Running Discovery"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# Find location codes
echo "📍 Finding location codes..."
echo ""

echo "1. Beaver Falls, PA:"
BEAVER_FALLS=$(./bin/find-location-code.sh "Beaver Falls, PA" | grep -A 1 "Beaver Falls,Pennsylvania" | tail -1 | awk '{print $1}')
echo "   Code: $BEAVER_FALLS"
echo ""

echo "2. Raleigh, NC:"
RALEIGH=$(./bin/find-location-code.sh "Raleigh, NC" | grep -A 1 "Raleigh,North Carolina" | tail -1 | awk '{print $1}')
echo "   Code: $RALEIGH"
echo ""

# Update configs
echo "📝 Updating configs..."
echo ""

# Beaver Valley Janitorial - already set to 1023967 (Beaver County)
# This should be Beaver Falls city-level
if [[ -n "$BEAVER_FALLS" ]]; then
  sed -i "s/location_code: 1023967/location_code: $BEAVER_FALLS/" workspace/beaver-valley-janitorial-supply/seo/config.yaml
  echo "✅ Updated Beaver Valley Janitorial to $BEAVER_FALLS"
fi

# Update Raleigh-based clients
for client in clearwater_aquariums road_home_rescue the_fish_room raleigh_digital carolina_wildlife_removal; do
  if [[ -f "workspace/$client/seo/config.yaml" ]] && [[ -n "$RALEIGH" ]]; then
    # These have location_code: 1026152 which might be Wake County
    # Update to Raleigh city-level
    sed -i "s/location_code: 1026152/location_code: $RALEIGH/" "workspace/$client/seo/config.yaml"
    echo "✅ Updated $client to Raleigh code $RALEIGH"
  fi
done

echo ""
echo "╔════════════════════════════════════════════════════════════"
echo "║ Running Discovery for First 5 Clients"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# List of first 5 clients (skipping capitol_pain and uni_k_wax)
CLIENTS=(
  "beaver-valley-janitorial-supply"
  "c_kalcevic_roofing"
  "clearwater_aquariums"
  "road_home_rescue"
  "the_fish_room"
)

COUNT=1
TOTAL=5

for CLIENT in "${CLIENTS[@]}"; do
  echo "─────────────────────────────────────────────────────────"
  echo "[$COUNT/$TOTAL] Running discovery: $CLIENT"
  echo "─────────────────────────────────────────────────────────"
  echo ""

  # Test GSC access first
  echo "🔑 Testing GSC access..."
  if ./bin/test-gsc-access.sh "$CLIENT" 2>&1 | grep -q "All Tests Passed"; then
    echo "✅ GSC access confirmed"
    echo ""

    # Run discovery
    echo "🔍 Running discovery (limit 20)..."
    if ./bin/run-discovery.sh "$CLIENT" --limit 20; then
      echo "✅ Discovery complete for $CLIENT"
    else
      echo "❌ Discovery failed for $CLIENT"
    fi
  else
    echo "⚠️  GSC access not available for $CLIENT"
    echo "   Add service account to GSC first:"
    echo "   seo-process-automation@raleigh-seo-kit.iam.gserviceaccount.com"
  fi

  echo ""
  ((COUNT++))
done

echo "╔════════════════════════════════════════════════════════════"
echo "║ Complete"
echo "╚════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Add service account to remaining clients' GSC"
echo "2. Run discovery for remaining clients"
echo "3. Generate content briefs"
echo ""
