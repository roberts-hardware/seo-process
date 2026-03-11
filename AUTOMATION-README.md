# SEO Process Automation System

## Quick Start Guide for Team Deployment

This automation system enables your team to deploy hub & spoke SEO architecture across 10+ clients efficiently.

---

## 🚀 Client Onboarding (15 minutes)

### 1. Add New Client

```bash
./bin/add-client.sh <client-id> <site-url> "competitor1.com,competitor2.com"
```

**Example:**
```bash
./bin/add-client.sh acmeplumbing https://acmeplumbing.com "competitor1.com,competitor2.com"
```

This creates:
- `workspace/acmeplumbing/` directory structure
- Pre-configured `seo/config.yaml` template
- Brand, content, and health directories

### 2. Configure Client

Edit the generated config file:
```bash
nano workspace/<client-id>/seo/config.yaml
```

**Critical fields to update:**
- `business_type` - roofing, plumbing, hvac, electrical, landscaping
- `phone` - Client's phone number
- `service_areas.primary` - Primary cities they serve
- `services` - Services they offer (use snake_case)
- `location_code` - **MUST be city-level** (see below)
- `state` and `county` - Geographic info
- `years_in_business` - How long they've been in business
- `licenses` and `certifications` - Credentials

### 3. Find Location Code (CRITICAL!)

```bash
./bin/find-location-code.sh "City Name, State"
```

**Examples:**
```bash
./bin/find-location-code.sh "Cranberry Township, PA"
# Returns: 1021866

./bin/find-location-code.sh "Los Angeles, CA"
# Returns: 1023768
```

**⚠️ Important:** Use CITY-level codes, NOT country-level (2840 = USA is too broad)

### 4. Ensure Google Search Console Access

Add the service account to GSC:
- Property: client's domain
- Permission: "Read" access minimum
- Service account email is in your `.env` file

---

## 📊 Running SEO Operations

### Discovery (Find Strike Zone Keywords)

```bash
./bin/run-discovery.sh <client-id> --limit 20
```

**What it does:**
- Finds keywords in positions 5-20 (strike zone)
- Identifies quick-win opportunities
- Saves to `workspace/<client-id>/seo/opportunities.json`

### Monitoring (Track All Rankings)

```bash
./bin/run-monitor.sh <client-id>
```

**What it does:**
- Pulls ALL keyword rankings from GSC
- Creates snapshot with timestamp
- Saves to `workspace/<client-id>/seo/snapshots/`

### Health Checks (Site Technical SEO)

```bash
./bin/run-health-check.sh <client-id>
```

**What it does:**
- Page speed test
- Crawl test (broken links, etc.)
- Image optimization check
- Saves to `workspace/<client-id>/seo/health/`

### Run + Auto-Sync to GitHub

```bash
./bin/run-and-sync.sh <client-id> <script-path> [args]
```

**Examples:**
```bash
# Discovery + sync
./bin/run-and-sync.sh acmeplumbing skills/seo-agent/scripts/seo-discover.sh --limit 20

# Monitoring + sync
./bin/run-and-sync.sh acmeplumbing skills/seo-agent/scripts/seo-monitor.sh
```

---

## 📝 Content Creation Workflow

### Step 1: Generate Content Briefs

```bash
./bin/generate-content-briefs.sh <client-id>
```

**What it generates:**
- Briefs for ALL service hubs (e.g., `brief-commercial_roofing.md`)
- Briefs for ALL location hubs (e.g., `brief-cranberry-township.md`)
- Includes target keywords, structure, word count, internal linking strategy

**Output:** `workspace/<client-id>/content/brief-*.md`

### Step 2: Create Templates (One-Time Setup)

Create business-type templates in `templates/`:

```
templates/
├── roofing/
│   ├── service-hub-template.md
│   ├── location-hub-template.md
│   ├── commercial_roofing.md (optional: service-specific)
│   └── residential_roofing.md
├── plumbing/
│   ├── service-hub-template.md
│   └── location-hub-template.md
├── hvac/
    └── ...
```

**Template variables:**
- `{{COMPANY_NAME}}` - Auto-replaced with client name
- `{{PHONE}}` - Client phone number
- `{{YEARS_IN_BUSINESS}}` - Years in business
- `{{STATE}}` / `{{COUNTY}}` - Geographic info
- `{{SERVICE_NAME}}` / `{{LOCATION_NAME}}` - Service/location title
- `{{SERVICE_AREAS_SECTION}}` - Auto-generated location links
- `{{SERVICES_SECTION}}` - Auto-generated service links

### Step 3: Auto-Generate Pages (80% Complete)

```bash
./bin/auto-generate-page.sh <client-id> service <service-name>
./bin/auto-generate-page.sh <client-id> location <location-name>
```

**Examples:**
```bash
# Generate service hub
./bin/auto-generate-page.sh acmeplumbing service commercial_plumbing

# Generate location hub
./bin/auto-generate-page.sh acmeplumbing location seattle
```

**What it does:**
- Loads template for business type
- Replaces ALL `{{VARIABLES}}` with client data
- Generates 80% complete page
- Creates placeholder sections for manual customization

**Output:** `workspace/<client-id>/content/<page-name>.md`

### Step 4: Customize Content (1-2 hours per page)

1. Open the auto-generated file
2. Search for `[` to find placeholder sections
3. Fill in location-specific or service-specific details
4. Add examples, case studies, local landmarks
5. Review and polish

**Time savings:**
- Service hub: 4-5 hours (vs. 6-8 hours from scratch)
- Location hub: 2-3 hours (vs. 4-5 hours from scratch)

---

## 🔄 Automated Scheduling (10+ Clients)

### Set Up Cron Jobs

Add to crontab (`crontab -e`):

```cron
# All clients: Monday 9am - Discovery + Monitoring
0 9 * * 1 ~/seo-process/bin/schedule-all-clients.sh monday-morning

# All clients: Friday 3pm - Health checks
0 15 * * 5 ~/seo-process/bin/schedule-all-clients.sh friday-afternoon
```

### Master Scheduler

```bash
./bin/schedule-all-clients.sh <schedule-name>
```

**Available schedules:**
- `monday-morning` - Discovery + monitoring for all clients
- `friday-afternoon` - Health checks for all clients
- `weekly-compete` - Competitor analysis for all clients

**What it does:**
- Auto-discovers all clients in workspace/
- Runs operations sequentially (rate limiting built-in)
- Auto-syncs results to GitHub
- Logs success/failure for each client

---

## 📊 Dashboard Setup (Cloudflare Pages)

### Generate Client Index

```bash
./bin/generate-client-index.sh
```

**What it creates:**
- `workspace/clients.json` - Index of all clients with metadata

### Dashboard Architecture

**Data source:** GitHub raw URLs pointing to workspace files

**Frontend (Cloudflare Pages):**
1. Loads `clients.json` to show client list
2. Client dropdown selector
3. Displays for each client:
   - Latest rankings
   - Strike zone opportunities
   - Content status
   - Health metrics
   - Performance trends (chart)

**Read-only:** Dashboard displays data, doesn't trigger operations

### Deploy Dashboard

1. Create Cloudflare Pages project
2. Connect to GitHub repo
3. Build settings:
   - Framework: React/Vue/Svelte (your choice)
   - Build command: `npm run build`
   - Output directory: `dist`
4. Set environment variables (if needed for auth)
5. Deploy

**URL structure:**
- `/` - Client list
- `/<client-id>` - Client detail view

---

## 🔄 Git Workflow

### Sync Workspace to GitHub

```bash
# Sync one client
./bin/sync-workspace.sh <client-id> "Commit message"

# Sync all clients
./bin/sync-workspace.sh all "Weekly update"
```

**What gets synced:**
- SEO data (snapshots, opportunities)
- Content files
- Health check results
- Config changes

**What's excluded (`.gitignore`):**
- `.env` files (credentials stay local)
- `**/credentials.json`
- Temporary files

---

## 📋 Complete Workflow Example

### New Client: "ABC Plumbing" in Seattle

**Week 1: Onboarding (30 minutes)**
```bash
# 1. Add client
./bin/add-client.sh abcplumbing https://abcplumbing.com "competitor1.com,competitor2.com"

# 2. Edit config
nano workspace/abcplumbing/seo/config.yaml
# Set business_type: "plumbing"
# Set location_code: 1023473 (Seattle)
# Set service_areas: Seattle, Bellevue, Redmond
# Set services: commercial_plumbing, residential_plumbing, drain_cleaning

# 3. Find location code
./bin/find-location-code.sh "Seattle, WA"
# Update location_code in config

# 4. Initial data collection
./bin/run-and-sync.sh abcplumbing skills/seo-agent/scripts/seo-discover.sh --limit 20
./bin/run-and-sync.sh abcplumbing skills/seo-agent/scripts/seo-monitor.sh
```

**Week 2: Content Planning (5 minutes)**
```bash
# Generate all content briefs
./bin/generate-content-briefs.sh abcplumbing

# Output: 6+ briefs (3 services × 3 locations)
```

**Week 3-4: Content Production (24 hours)**
```bash
# Auto-generate pages (saves 60% time)
./bin/auto-generate-page.sh abcplumbing service commercial_plumbing
./bin/auto-generate-page.sh abcplumbing service residential_plumbing
./bin/auto-generate-page.sh abcplumbing location seattle

# Writers customize each page: 2-3 hours each
# Total: 6 pages × 3 hours = 18 hours (vs. 36 hours from scratch)
```

**Week 5: Deploy + Monitor**
- Upload content to abcplumbing.com
- Submit to GSC
- Monitor indexing
- Dashboard updates automatically

---

## 🎯 Team Roles

### SEO Strategist
- Client onboarding (30 min per client)
- Config setup
- Review content briefs
- Monitor dashboard

### Content Writer
- Customize auto-generated pages (3-4 hours per page)
- Add local details
- Ensure brand voice

### Developer (Optional)
- Publish content to client sites
- Build Cloudflare Pages dashboard

---

## 📊 Scaling Metrics

**Manual Approach (Old Way):**
- 80 hours per client
- 10 clients = 800 hours

**Automated Approach (New Way):**
- 25 hours per client
- 10 clients = 250 hours

**Time Savings: 550 hours (69%)**

At $100/hour: **$55,000 saved** across 10 clients

---

## 🛠️ Troubleshooting

### GSC Authentication Error
```bash
# Re-authenticate
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/webmasters.readonly
```

### Discovery Returns No Results
- Check `location_code` is city-level (not 2840)
- Verify GSC access for the domain
- Lower `min_search_volume` for small markets (20-30)

### Content Briefs Missing Services
- Ensure `services:` section in config has list items with `  - ` prefix
- Use snake_case for service names
- Each service on new line

### Auto-Generate Page Fails
- Check template exists: `templates/<business-type>/`
- Verify all config fields are filled
- Run `generate-content-briefs.sh` first

---

## 📚 File Structure Reference

```
seo-process/
├── bin/                           # All automation scripts
│   ├── add-client.sh             # Client onboarding
│   ├── generate-content-briefs.sh # Auto-generate briefs
│   ├── auto-generate-page.sh     # Auto-generate pages
│   ├── run-for-client.sh         # Core wrapper
│   ├── run-discovery.sh          # Discovery shortcut
│   ├── run-monitor.sh            # Monitoring shortcut
│   ├── run-health-check.sh       # Health check shortcut
│   ├── sync-workspace.sh         # Git sync
│   ├── run-and-sync.sh           # Run + auto-sync
│   ├── schedule-all-clients.sh   # Master scheduler
│   └── generate-client-index.sh  # Dashboard index
├── workspace/
│   ├── <client-id>/
│   │   ├── seo/
│   │   │   ├── config.yaml       # Client config
│   │   │   ├── snapshots/        # Ranking history
│   │   │   └── health/           # Health checks
│   │   ├── content/              # Content briefs + pages
│   │   └── brand/                # Voice profiles
│   └── clients.json              # Dashboard index
├── templates/
│   ├── roofing/
│   ├── plumbing/
│   └── hvac/
└── skills/                       # SEO process skills
    ├── seo-agent/
    ├── seo-health/
    └── seo-forge/
```

---

## 🎓 Next Steps

1. **Set up first client:** Use CKalcevic as template
2. **Create templates:** Build templates for each business type
3. **Deploy dashboard:** Set up Cloudflare Pages
4. **Enable automation:** Add cron jobs for 10+ clients
5. **Train team:** Share this README with writers

---

## 📞 Support

Questions? Check:
- `TEAM-AUTOMATION-SYSTEM.md` - Full system architecture
- `HUB-SPOKE-IMPLEMENTATION-GUIDE.md` - Content strategy
- `MIGRATION-STRATEGY.md` - Preserving existing rankings

**Ready to scale to unlimited clients!** 🚀
