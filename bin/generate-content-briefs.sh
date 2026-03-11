#!/usr/bin/env bash
# Generate content briefs from SEO data and client config
# Usage: ./bin/generate-content-briefs.sh <client-id>

set -euo pipefail

CLIENT_ID="${1:?Usage: generate-content-briefs.sh <client-id>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$REPO_ROOT/workspace/$CLIENT_ID"
CONFIG="$WORKSPACE/seo/config.yaml"
CONTENT_DIR="$WORKSPACE/content"

# Validate workspace exists
if [[ ! -d "$WORKSPACE" ]]; then
  echo "❌ Error: Client workspace not found: $WORKSPACE"
  echo "Run: ./bin/add-client.sh $CLIENT_ID <site-url> <competitors>"
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Error: Config file not found: $CONFIG"
  exit 1
fi

echo "📋 Generating content briefs for $CLIENT_ID..."
echo ""

# Create content directory if needed
mkdir -p "$CONTENT_DIR"

# Extract config values
BUSINESS_TYPE=$(grep '^business_type:' "$CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"' || echo "roofing")
PHONE=$(grep '^phone:' "$CONFIG" 2>/dev/null | awk '{$1=""; print $0}' | tr -d '"' | xargs || echo "(000) 000-0000")
COMPANY_NAME=$(echo "$CLIENT_ID" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
SITE_URL=$(grep '^site_url:' "$CONFIG" | awk '{print $2}' | tr -d '"')

# Extract primary service areas from config
PRIMARY_AREAS=$(grep -A 50 'service_areas:' "$CONFIG" 2>/dev/null | grep -A 30 'primary:' | grep 'name:' | awk -F'"' '{print $2}' || echo "")

if [[ -z "$PRIMARY_AREAS" ]]; then
  echo "⚠️  Warning: No service areas found in config. Using defaults."
  PRIMARY_AREAS="Area 1
Area 2
Area 3"
fi

# Extract services from config (stop at next YAML section)
SERVICES=$(sed -n '/^services:/,/^[a-z]/p' "$CONFIG" 2>/dev/null | grep '  - ' | sed 's/^  - //' | tr -d '"' || echo "")

if [[ -z "$SERVICES" ]]; then
  echo "⚠️  Warning: No services found in config. Using defaults."
  SERVICES="service_1
service_2
service_3"
fi

# Count how many briefs we'll generate
NUM_SERVICES=$(echo "$SERVICES" | wc -l | tr -d ' ')
NUM_LOCATIONS=$(echo "$PRIMARY_AREAS" | wc -l | tr -d ' ')
TOTAL_BRIEFS=$((NUM_SERVICES + NUM_LOCATIONS))

echo "Business Type: $BUSINESS_TYPE"
echo "Services: $NUM_SERVICES"
echo "Locations: $NUM_LOCATIONS"
echo "Total Briefs: $TOTAL_BRIEFS"
echo ""

# Function to convert snake_case to Title Case
to_title_case() {
  echo "$1" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1'
}

# Generate service hub briefs
echo "📝 Generating service hub briefs..."
while IFS= read -r SERVICE; do
  [[ -z "$SERVICE" ]] && continue

  SERVICE_SLUG="$SERVICE"
  SERVICE_TITLE=$(to_title_case "$SERVICE")

  echo "  - $SERVICE_TITLE"

  cat > "$CONTENT_DIR/brief-$SERVICE_SLUG.md" <<EOF
# Content Brief: $SERVICE_TITLE

**Generated:** $(date +%Y-%m-%d)
**Client:** $CLIENT_ID
**Target Keyword:** "$SERVICE_TITLE"
**Page Type:** Service Hub

---

## Page Details

- **URL:** /$SERVICE_SLUG/
- **Word Count:** 3,000 words (service hub)
- **Page Type:** Service Hub
- **Intent:** Informational + Transactional

## Target Keywords

**Primary:**
- "$SERVICE_TITLE"
- "$SERVICE_TITLE services"

**Secondary:**
- "$SERVICE_TITLE near me"
- "professional $SERVICE_TITLE"
- "$SERVICE_TITLE contractor"

**Location-modified (include all):**
$(echo "$PRIMARY_AREAS" | while IFS= read -r AREA; do
  [[ -z "$AREA" ]] && continue
  echo "- \"$SERVICE_TITLE $AREA\""
done)

## Service Areas to Feature

This service hub should link to all location pages:

$(echo "$PRIMARY_AREAS" | while IFS= read -r AREA; do
  [[ -z "$AREA" ]] && continue
  AREA_SLUG=$(echo "$AREA" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  echo "- $AREA → Link: /$AREA_SLUG/"
done)

## Content Structure

### Introduction (300 words)
- Overview of $SERVICE_TITLE services
- Mention service area coverage
- Establish expertise and credentials

### Service Details (1,500 words)
Break down into subsections:
- What is $SERVICE_TITLE?
- Types/variations of $SERVICE_TITLE
- Process/methodology
- Materials/equipment used
- Timeline expectations

### Why Choose Us (400 words)
- Years of experience
- Credentials and certifications
- Quality guarantees
- Customer testimonials

### Service Areas (500 words) ← CRITICAL FOR SEO
Create individual subsections for each primary location:

$(echo "$PRIMARY_AREAS" | while IFS= read -r AREA; do
  [[ -z "$AREA" ]] && continue
  AREA_SLUG=$(echo "$AREA" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  cat <<SUBSECTION
#### $AREA
[150-200 words about serving this location]
- Mention $SERVICE_TITLE work in $AREA
- Reference local landmarks/neighborhoods
- Include response time
- **Link:** [Learn more about our $AREA services →](/$AREA_SLUG/)

SUBSECTION
done)

### FAQs (400 words)
10 frequently asked questions about $SERVICE_TITLE

### CTAs Throughout
- Phone: $PHONE
- Free estimate offers
- Emergency service availability (if applicable)

## Internal Linking Strategy

**Link TO (from this page):**
- All location hub pages (in Service Areas section)
- 2-3 related service pages (in Related Services section)
- Homepage

**Expect links FROM:**
- All location hub pages (in their services overview)
- Related service pages
- Homepage navigation

## SEO Optimization

**Title Tag:** "$SERVICE_TITLE | [County/Region] | $COMPANY_NAME"
**Meta Description:** "Expert $SERVICE_TITLE in [County]. [Key benefit 1], [Key benefit 2]. Free estimates. Call $PHONE"

**Schema Markup:**
- Service schema
- Organization schema
- LocalBusiness with areaServed

## Template Reference

**Use template:** templates/$BUSINESS_TYPE/$SERVICE_SLUG.md
(If template doesn't exist, use: templates/$BUSINESS_TYPE/service-hub-template.md)

## Writing Notes

- Focus on DEPTH over breadth for this service
- Each location mention should be substantive (100+ words)
- Use keyword variations naturally
- Include local landmarks for each area
- Add specific examples and case studies
- Emphasize expertise and credentials

---

**Next Steps:**
1. Review this brief
2. Open template file
3. Customize template with client details
4. Write comprehensive service content
5. Add location-specific details for each area
6. Include 10 relevant FAQs
7. Add internal links as specified
8. Time estimate: 4-6 hours
EOF

done <<< "$SERVICES"

# Generate location hub briefs
echo ""
echo "📝 Generating location hub briefs..."
while IFS= read -r AREA; do
  [[ -z "$AREA" ]] && continue

  AREA_SLUG=$(echo "$AREA" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  echo "  - $AREA"

  cat > "$CONTENT_DIR/brief-$AREA_SLUG.md" <<EOF
# Content Brief: $AREA

**Generated:** $(date +%Y-%m-%d)
**Client:** $CLIENT_ID
**Target Keywords:** "$BUSINESS_TYPE $AREA", "$BUSINESS_TYPE contractor $AREA"
**Page Type:** Location Hub

---

## Page Details

- **URL:** /$AREA_SLUG/
- **Word Count:** 2,200 words (location hub)
- **Page Type:** Location Hub
- **Intent:** Transactional + Local

## Target Keywords

**Primary:**
- "$(echo $BUSINESS_TYPE | sed 's/_/ /g') $AREA"
- "$(echo $BUSINESS_TYPE | sed 's/_/ /g') contractor $AREA"
- "$(echo $BUSINESS_TYPE | sed 's/_/ /g') services $AREA"

**Secondary:**
- "$AREA $(echo $BUSINESS_TYPE | sed 's/_/ /g')"
- "$(echo $BUSINESS_TYPE | sed 's/_/ /g') companies $AREA"
- "local $(echo $BUSINESS_TYPE | sed 's/_/ /g') $AREA"

**Service-modified (include all):**
$(echo "$SERVICES" | while IFS= read -r SERVICE; do
  [[ -z "$SERVICE" ]] && continue
  SERVICE_TITLE=$(to_title_case "$SERVICE")
  echo "- \"$SERVICE_TITLE $AREA\""
done)

## Services to Cover

This location hub should link to all service pages:

$(echo "$SERVICES" | while IFS= read -r SERVICE; do
  [[ -z "$SERVICE" ]] && continue
  SERVICE_TITLE=$(to_title_case "$SERVICE")
  echo "- $SERVICE_TITLE → Link: /$SERVICE/"
done)

## Content Structure

### Introduction (200 words)
- Establish local presence in $AREA
- Years serving this area
- Understanding of local properties/needs
- Call to action with phone number

### Services Overview (800 words)
Brief description of each service FOR THIS LOCATION:

$(echo "$SERVICES" | while IFS= read -r SERVICE; do
  [[ -z "$SERVICE" ]] && continue
  SERVICE_TITLE=$(to_title_case "$SERVICE")
  cat <<SUBSECTION
#### $SERVICE_TITLE
[150-200 words about this service in $AREA]
- How it applies to $AREA properties
- Local examples/case studies
- **Link:** [Complete $SERVICE_TITLE services →](/$SERVICE/)

SUBSECTION
done)

### Why Choose Us for $AREA (400 words)
- Local expertise and knowledge
- Response times for $AREA
- Understanding of $AREA properties
- Portfolio of $AREA projects

### $AREA Service Area Details (400 words)
- ZIP code(s)
- Neighborhoods/subdivisions served
- Response time specifics
- Adjacent areas also covered
- Property types (residential/commercial/both)

### Common Issues in $AREA (200 words)
- Location-specific problems
- Weather challenges
- Common property types and their needs

### FAQs (300 words)
6-8 $AREA-specific questions

### CTAs Throughout
- Phone: $PHONE
- Free estimates
- Fast response times for $AREA

## Internal Linking Strategy

**Link TO (from this page):**
- All service hub pages (in Services Overview section)
- 1-2 adjacent location pages (in Service Area Details)
- Homepage

**Expect links FROM:**
- All service hub pages (in their service areas section)
- Adjacent location pages
- Homepage navigation

## Local Research Needed

Before writing, research:
- **ZIP code(s):** [Look up on Google Maps]
- **Neighborhoods:** [List major subdivisions/areas]
- **Property types:** [Residential? Commercial? Both?]
- **Local landmarks:** [Schools, parks, shopping centers to reference]
- **Response time:** [Estimate drive time from business location]

## SEO Optimization

**Title Tag:** "$BUSINESS_TYPE Services $AREA | $COMPANY_NAME"
**Meta Description:** "Expert $BUSINESS_TYPE in $AREA. [Service 1], [Service 2], [Service 3]. Free estimates. Call $PHONE"

**Schema Markup:**
- LocalBusiness schema
- Service schema for each service
- GeoCoordinates for $AREA

## Template Reference

**Use template:** templates/$BUSINESS_TYPE/location-hub.md
(If template doesn't exist, use: templates/$BUSINESS_TYPE/location-hub-template.md)

## Writing Notes

- Focus on LOCAL RELEVANCE for this area
- Each service mention should be location-specific
- Reference actual neighborhoods/landmarks
- Include specific response time
- Emphasize local expertise
- Keep service descriptions brief (detailed info on service hub)
- Link to service hubs for comprehensive information

---

**Next Steps:**
1. Review this brief
2. Research $AREA details (ZIP, neighborhoods, landmarks)
3. Open template file
4. Customize with local information
5. Write location-specific service descriptions
6. Add 6-8 location FAQs
7. Include internal links as specified
8. Time estimate: 3-4 hours
EOF

done <<< "$PRIMARY_AREAS"

# Summary
echo ""
echo "✅ Content brief generation complete!"
echo ""
echo "📁 Location: $CONTENT_DIR/"
echo "📄 Generated: $TOTAL_BRIEFS briefs"
echo "   - Service hubs: $NUM_SERVICES"
echo "   - Location hubs: $NUM_LOCATIONS"
echo ""
echo "Next steps:"
echo "1. Review briefs in $CONTENT_DIR/"
echo "2. Use bin/auto-generate-page.sh to create 80% complete pages"
echo "3. Or manually write using templates in templates/$BUSINESS_TYPE/"
echo ""
echo "Estimated total writing time: $((NUM_SERVICES * 5 + NUM_LOCATIONS * 3)) hours"
echo "(vs. $((TOTAL_BRIEFS * 6)) hours from scratch = $((TOTAL_BRIEFS * 6 - (NUM_SERVICES * 5 + NUM_LOCATIONS * 3))) hours saved)"
