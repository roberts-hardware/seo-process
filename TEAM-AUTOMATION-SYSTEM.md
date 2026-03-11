# Team Automation System: Multi-Client SEO Deployment

## Overview

**Problem:** You have 10+ local service clients who all need the same site architecture
**Solution:** Automated hub & spoke deployment system that uses live SEO data

**Time savings:** 400-600 hours across 10 clients vs. manual approach

---

## System Architecture

```
Client Onboarding
    ↓
Run Discovery/Monitoring (automated via cron)
    ↓
Generate Content Briefs (automated script)
    ↓
Writer produces content (from templates)
    ↓
Publish to client site
    ↓
Monitor performance (automated)
    ↓
Display in Mission Control Dashboard (Cloudflare Pages)
```

---

## Phase 1: Client Onboarding (15 minutes)

### Step 1: Add Client to System

```bash
# Run the client onboarding script
./bin/add-client.sh newclient https://newclient.com "competitor1.com,competitor2.com"
```

This creates:
- `workspace/newclient/seo/config.yaml`
- `workspace/newclient/brand/`
- `workspace/newclient/content/`

### Step 2: Configure Client Details

Edit `workspace/newclient/seo/config.yaml`:

```yaml
client_id: newclient
site: "sc-domain:newclient.com"
site_url: "https://newclient.com"
business_type: "roofing" # or "plumbing", "hvac", "electrical"
location_code: 1023768  # Los Angeles (find using bin/find-location-code.sh)

# Service areas (primary locations)
service_areas:
  primary:
    - name: "Los Angeles"
      zip: "90001"
      response_time: "30-60 min"
    - name: "Santa Monica"
      zip: "90401"
      response_time: "45-75 min"
  secondary:
    - "Beverly Hills"
    - "Culver City"

# Services offered
services:
  - "commercial_roofing"
  - "residential_roofing"
  - "emergency_repair"
  - "metal_roofing"
  - "roof_repair"

# Client brand details
phone: "(123) 456-7890"
years_in_business: 25
licenses:
  - "CA Contractor License #123456"
certifications:
  - "GAF Master Elite"
```

**Time: 15 minutes**

---

## Phase 2: Data Collection (Automated - Runs Weekly)

### Automated Discovery & Monitoring

**Cron job runs weekly:**
```cron
# Every Monday at 9am
0 9 * * 1 ~/seo-process/bin/run-and-sync.sh newclient skills/seo-agent/scripts/seo-discover.sh --limit 20
5 9 * * 1 ~/seo-process/bin/run-and-sync.sh newclient skills/seo-agent/scripts/seo-monitor.sh
```

**Output stored in:**
- `workspace/newclient/seo/snapshots/` (monitoring data)
- `workspace/newclient/seo/opportunities.json` (discovery data)

**Synced to GitHub** → **Cloudflare Pages dashboard** shows live data

---

## Phase 3: Content Brief Generation (AUTOMATED)

### Script: `bin/generate-content-briefs.sh`

**Purpose:** Analyzes SEO data and generates content briefs automatically

```bash
#!/usr/bin/env bash
# Generate content briefs from SEO data

CLIENT_ID="${1:?Usage: generate-content-briefs.sh <client-id>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$REPO_ROOT/workspace/$CLIENT_ID"

echo "Generating content briefs for $CLIENT_ID..."

# Load client config
CONFIG="$WORKSPACE/seo/config.yaml"
BUSINESS_TYPE=$(grep 'business_type:' "$CONFIG" | awk '{print $2}' | tr -d '"')
PHONE=$(grep 'phone:' "$CONFIG" | awk '{print $2}' | tr -d '"')

# Get primary service areas from config
PRIMARY_AREAS=$(grep -A10 'primary:' "$CONFIG" | grep 'name:' | awk -F'"' '{print $2}')

# Analyze discovery data to find gaps
# (What locations are they NOT ranking for?)
DISCOVERY="$WORKSPACE/seo/snapshots/$(ls -t "$WORKSPACE/seo/snapshots" | head -1)"

# Generate service hub briefs
for SERVICE in $(grep -A20 'services:' "$CONFIG" | grep '  - ' | awk '{print $2}' | tr -d '"'); do
  echo "Generating brief for service: $SERVICE..."

  cat > "$WORKSPACE/content/brief-$SERVICE.md" <<EOF
# Content Brief: $(echo $SERVICE | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')

**Generated:** $(date +%Y-%m-%d)
**Client:** $CLIENT_ID
**Target Keyword:** "$(echo $SERVICE | sed 's/_/ /g')"

## Page Details
- **URL:** /$SERVICE/
- **Word Count:** 3,000 words
- **Page Type:** Service Hub

## Target Keywords
- Primary: "$(echo $SERVICE | sed 's/_/ /g')"
- Secondary: "$(echo $SERVICE | sed 's/_/ /g') services"
- Location: "$(echo $SERVICE | sed 's/_/ /g') [each city]"

## Service Areas to Mention
$(echo "$PRIMARY_AREAS" | while read AREA; do echo "- $AREA"; done)

## Content Structure
[Copy from template based on business type]

## Internal Links Required
- Link to each location hub with anchor: "$(echo $SERVICE | sed 's/_/ /g') in [City]"
- Link to related services

## CTAs
- Phone: $PHONE
- Free estimate offer
- 24/7 emergency (if applicable)

## Template
[Use: templates/$BUSINESS_TYPE/$SERVICE.md]
EOF

done

# Generate location hub briefs
echo "$PRIMARY_AREAS" | while read AREA; do
  AREA_SLUG=$(echo "$AREA" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  echo "Generating brief for location: $AREA..."

  cat > "$WORKSPACE/content/brief-$AREA_SLUG.md" <<EOF
# Content Brief: $AREA

**Generated:** $(date +%Y-%m-%d)
**Client:** $CLIENT_ID
**Target Keyword:** "roofer $AREA" (adjust for business type)

## Page Details
- **URL:** /$AREA_SLUG/
- **Word Count:** 2,200 words
- **Page Type:** Location Hub

## Target Keywords
- Primary: "roofer $AREA", "roofing $AREA"
- Secondary: "[business type] [area]", "[business type] contractor [area]"

## Services to Cover
$(grep -A20 'services:' "$CONFIG" | grep '  - ' | awk '{print "- " $2}' | tr -d '"' | sed 's/_/ /g')

## Content Structure
[Copy from template: templates/$BUSINESS_TYPE/location-hub.md]

## Internal Links Required
- Link to each service hub
- Link to adjacent location pages

## Local Details Needed
- Neighborhoods in $AREA
- ZIP code
- Response time
- Local projects (before/after photos)

## Template
[Use: templates/$BUSINESS_TYPE/location-hub.md]
EOF

done

echo "✓ Generated $(ls "$WORKSPACE/content/brief-"* | wc -l) content briefs"
echo "Location: $WORKSPACE/content/"
```

**Usage:**
```bash
./bin/generate-content-briefs.sh newclient
```

**Output:** Content briefs for all service + location pages

**Time: 2 minutes (automated)**

---

## Phase 4: Content Production

### Templates by Business Type

**Structure:**
```
templates/
├── roofing/
│   ├── commercial_roofing.md
│   ├── residential_roofing.md
│   ├── emergency_repair.md
│   ├── location-hub.md
├── plumbing/
│   ├── commercial_plumbing.md
│   ├── residential_plumbing.md
│   ├── emergency_plumbing.md
│   ├── location-hub.md
├── hvac/
│   ├── commercial_hvac.md
│   ├── residential_hvac.md
│   ├── location-hub.md
```

### Writer Workflow

**1. Writer receives brief:**
- `workspace/newclient/content/brief-commercial-roofing.md`

**2. Opens template:**
- `templates/roofing/commercial_roofing.md`

**3. Finds placeholders:**
```markdown
# {{SERVICE_NAME}} in {{COUNTY}}, {{STATE}}

For over {{YEARS_IN_BUSINESS}} years, {{COMPANY_NAME}} has been...

**24/7 Emergency Service:** {{PHONE}}

## Service Areas: {{COUNTY}} & Beyond

### {{PRIMARY_CITY_1}}
[Paragraph about serving this location]
[Learn more: {{PRIMARY_CITY_1}} {{SERVICE_TYPE}} →]({{URL}})

### {{PRIMARY_CITY_2}}
[Paragraph about serving this location]
```

**4. Replaces with client data:**
- Pulls from `workspace/newclient/seo/config.yaml`
- Auto-filled by script OR manual find-replace

**5. Customizes content:**
- Adds local details
- Adjusts for brand voice
- Adds internal links

**Time: 3-4 hours per page (vs. 6+ hours from scratch)**

---

## Phase 5: Automation Script

### Script: `bin/auto-generate-page.sh`

```bash
#!/usr/bin/env bash
# Auto-generate page from template + client config

CLIENT_ID="$1"
PAGE_TYPE="$2"  # "service" or "location"
PAGE_NAME="$3"  # "commercial_roofing" or "cranberry-township"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$REPO_ROOT/workspace/$CLIENT_ID/seo/config.yaml"

# Load client variables
COMPANY_NAME=$(grep 'client_id:' "$CONFIG" | awk '{print $2}' | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
PHONE=$(grep 'phone:' "$CONFIG" | awk '{print $2}' | tr -d '"')
YEARS=$(grep 'years_in_business:' "$CONFIG" | awk '{print $2}')
BUSINESS_TYPE=$(grep 'business_type:' "$CONFIG" | awk '{print $2}' | tr -d '"')
STATE="PA"  # or parse from config
COUNTY="Butler County"  # or parse from config

# Load template
if [[ "$PAGE_TYPE" == "service" ]]; then
  TEMPLATE="$REPO_ROOT/templates/$BUSINESS_TYPE/$PAGE_NAME.md"
else
  TEMPLATE="$REPO_ROOT/templates/$BUSINESS_TYPE/location-hub.md"
fi

# Replace placeholders
sed -e "s/{{COMPANY_NAME}}/$COMPANY_NAME/g" \
    -e "s/{{PHONE}}/$PHONE/g" \
    -e "s/{{YEARS_IN_BUSINESS}}/$YEARS/g" \
    -e "s/{{STATE}}/$STATE/g" \
    -e "s/{{COUNTY}}/$COUNTY/g" \
    "$TEMPLATE" > "$REPO_ROOT/workspace/$CLIENT_ID/content/$PAGE_NAME.md"

echo "✓ Generated: workspace/$CLIENT_ID/content/$PAGE_NAME.md"
echo "Next: Review and customize content"
```

**Usage:**
```bash
./bin/auto-generate-page.sh newclient service commercial_roofing
./bin/auto-generate-page.sh newclient location cranberry-township
```

**Output:** 80% complete content page, needs 20% customization

**Time savings: 70%**

---

## Phase 6: Mission Control Dashboard

### Cloudflare Pages Dashboard

**Purpose:** Team can see all client SEO data in one place

**URL:** `https://seo-dashboard.yourcompany.com`

**Dashboard Features:**

```javascript
// src/pages/index.jsx
import { loadAllClients } from '../lib/data'

export default function Dashboard() {
  const clients = loadAllClients() // Reads from GitHub workspace/clients.json

  return (
    <div>
      <h1>Mission Control</h1>

      {clients.map(client => (
        <ClientCard key={client.id}>
          <h2>{client.name}</h2>

          {/* Latest Rankings */}
          <RankingsSummary clientId={client.id} />

          {/* Strike Zone Opportunities */}
          <StrikeZone clientId={client.id} />

          {/* Content Status */}
          <ContentStatus clientId={client.id} />

          {/* Performance Trend */}
          <PerformanceChart clientId={client.id} />
        </ClientCard>
      ))}
    </div>
  )
}
```

**Data Source:** GitHub workspace files (synced automatically)

**Client Detail View:**
```
https://seo-dashboard.yourcompany.com/ckalcevicroofing

- Current Rankings (last snapshot)
- Strike Zone Keywords (positions 5-20)
- Content Gaps (missing location/service combos)
- Performance Trends (12-week chart)
- Next Actions (auto-generated from data)
```

---

## Complete Workflow Example

### New Client: "ABC Plumbing" in Seattle

**Day 1: Onboarding (30 minutes)**
```bash
# 1. Add client
./bin/add-client.sh abcplumbing https://abcplumbing.com "competitor1.com,competitor2.com"

# 2. Edit config
nano workspace/abcplumbing/seo/config.yaml
# Set: business_type: "plumbing"
# Set: location_code: 1023473 (Seattle)
# Set: service_areas: Seattle, Bellevue, Redmond
# Set: services: commercial_plumbing, residential_plumbing, emergency_plumbing
```

**Week 1: Data Collection (Automated)**
```bash
# Cron runs these automatically
./bin/run-for-client.sh abcplumbing seo-discover.sh
./bin/run-for-client.sh abcplumbing seo-monitor.sh
```

**Week 2: Content Briefs (5 minutes)**
```bash
# Generate all content briefs
./bin/generate-content-briefs.sh abcplumbing

# Output:
# - workspace/abcplumbing/content/brief-commercial-plumbing.md
# - workspace/abcplumbing/content/brief-residential-plumbing.md
# - workspace/abcplumbing/content/brief-emergency-plumbing.md
# - workspace/abcplumbing/content/brief-seattle.md
# - workspace/abcplumbing/content/brief-bellevue.md
# - workspace/abcplumbing/content/brief-redmond.md
```

**Week 3-4: Content Production (40 hours)**
```bash
# Auto-generate 80% complete pages
./bin/auto-generate-page.sh abcplumbing service commercial_plumbing
./bin/auto-generate-page.sh abcplumbing service residential_plumbing
./bin/auto-generate-page.sh abcplumbing location seattle

# Writer spends 3-4 hours per page customizing
# Total: 6 pages × 4 hours = 24 hours (vs. 60+ hours from scratch)
```

**Week 5: Publishing**
- Upload content to abcplumbing.com
- Submit URLs to GSC
- Monitor indexing

**Week 6-12: Automated Monitoring**
- Weekly discovery/monitoring runs automatically
- Data syncs to GitHub
- Dashboard updates automatically
- Team reviews dashboard weekly

**Week 12+: Optimization**
- Dashboard shows which pages rank well
- Auto-generate briefs for supporting content
- Rinse and repeat

---

## Team Roles

**1. SEO Strategist (You)**
- Client onboarding (30 min per client)
- Config setup
- Review content briefs
- Monitor dashboard

**2. Content Writer**
- Customize auto-generated pages (4 hours per page)
- Add local details
- Ensure brand voice

**3. Developer (Optional)**
- Publish content to client sites
- Build Cloudflare Pages dashboard

---

## Scaling Metrics

**Manual Approach (Old Way):**
- Client onboarding: 2 hours
- Research: 8 hours
- Content briefs: 10 hours
- Writing: 60 hours (10 pages × 6 hours)
- **Total: 80 hours per client**
- **10 clients: 800 hours**

**Automated Approach (New Way):**
- Client onboarding: 30 minutes
- Research: Automated
- Content briefs: 5 minutes (automated)
- Writing: 24 hours (10 pages × 2.4 hours with templates)
- **Total: 25 hours per client**
- **10 clients: 250 hours**

**Time savings: 550 hours (69%)**

---

## Next Steps to Build This

**Phase 1: Core Scripts (Week 1)**
- [ ] `bin/add-client.sh` (✅ already exists)
- [ ] `bin/find-location-code.sh` (✅ already exists)
- [ ] `bin/generate-content-briefs.sh` (NEW - need to build)
- [ ] `bin/auto-generate-page.sh` (NEW - need to build)

**Phase 2: Templates (Week 2)**
- [ ] Create templates/roofing/ directory
- [ ] Create templates/plumbing/ directory
- [ ] Create templates/hvac/ directory
- [ ] Port CKalcevic content to template format

**Phase 3: Dashboard (Week 3-4)**
- [ ] Build Cloudflare Pages dashboard
- [ ] Connect to GitHub workspace data
- [ ] Client list view
- [ ] Client detail view with charts

**Phase 4: Deploy (Week 5+)**
- [ ] Deploy CKalcevic (first client)
- [ ] Monitor results
- [ ] Refine templates
- [ ] Deploy next 2-3 clients
- [ ] Scale to all 10+ clients

---

## ROI Calculation

**Cost to build automation:**
- Scripts: 20 hours
- Templates: 30 hours
- Dashboard: 40 hours
- **Total: 90 hours**

**Payback after:**
- 2 clients: 90 hours saved (break-even)
- 10 clients: 550 hours saved
- 20 clients: 1,200 hours saved

**At $100/hour:**
- 10 clients = $55,000 saved
- 20 clients = $120,000 saved

**Worth building: YES**

---

## Questions?

This system allows your team to:
✅ Onboard clients in 30 minutes
✅ Auto-generate content briefs from live SEO data
✅ Produce content 70% faster with templates
✅ Monitor all clients from one dashboard
✅ Scale to unlimited clients

Ready to build this?
