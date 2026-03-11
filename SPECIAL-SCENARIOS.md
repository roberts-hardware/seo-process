# Special Client Scenarios

## Scenario 1: Multi-Location Single Domain (40+ Locations)

**Example:** unikwax.com has 40 locations all on one website

### Strategy: Treat as ONE Client with Many Service Areas

Instead of creating 40 separate clients, create **one client** with 40 service areas.

### Configuration

**File:** `workspace/unikwax/seo/config.yaml`

```yaml
client_id: unikwax
site: "sc-domain:unikwax.com"
site_url: "https://unikwax.com"
business_type: "auto_detailing"  # or whatever they do

# Contact info (corporate)
phone: "(555) 123-4567"
years_in_business: 15

# ALL 40 locations as service areas
service_areas:
  primary:
    - name: "New York City"
      zip: "10001"
      response_time: "30-60 min"
    - name: "Los Angeles"
      zip: "90001"
      response_time: "30-60 min"
    - name: "Chicago"
      zip: "60601"
      response_time: "30-60 min"
    # ... add all 40 locations here
  secondary:
    - "Newark"
    - "Pasadena"
    # ... nearby cities

# Services (what they offer at ALL locations)
services:
  - "auto_detailing"
  - "ceramic_coating"
  - "paint_correction"
  - "interior_cleaning"

# Competitors
competitors:
  - competitor1.com
  - competitor2.com

# Location targeting
# IMPORTANT: Use the PRIMARY market or headquarters location
# OR use a broader regional code if truly national
location_code: 1023191  # New York, NY (if NYC is primary market)
# OR: 2840 (United States) if truly national with no primary market

min_search_volume: 50  # Higher since covering multiple markets
```

### Content Generation Strategy

**With 40 locations, you have 2 options:**

#### Option A: Hub & Spoke (Recommended for 40+ locations)

**Service Hubs (5-10 pages):**
- `/auto-detailing/` - Links to all 40 locations
- `/ceramic-coating/` - Links to all 40 locations
- `/paint-correction/` - etc.

**Location Hubs (40 pages):**
- `/new-york/` - Brief overview, links to service hubs
- `/los-angeles/` - Brief overview, links to service hubs
- `/chicago/` - etc.

**Total pages:** ~50 (vs. 200+ with hybrid approach)

**Generate briefs:**
```bash
./bin/generate-content-briefs.sh unikwax
# Creates 50 briefs automatically
```

#### Option B: Prioritize Top Markets

If 40 pages is too many, prioritize:

**Primary markets (10 locations):**
- Highest revenue
- Most traffic
- Strategic importance

**Create full location pages for top 10, mention others in service hubs**

```yaml
service_areas:
  primary:  # Top 10 - get full location pages
    - name: "New York City"
      zip: "10001"
      response_time: "30-60 min"
    - name: "Los Angeles"
      zip: "90001"
      response_time: "30-60 min"
    # ... 8 more
  secondary:  # Other 30 - mentioned but no dedicated pages
    - "Phoenix"
    - "Houston"
    # ... 28 more
```

### SEO Monitoring

**Discovery/Monitoring works the same:**
```bash
./bin/run-discovery.sh unikwax --limit 50
./bin/run-monitor.sh unikwax
```

**Google Search Console shows data for ALL locations** since they're all on one domain.

### Automation

**Runs automatically every week** just like any other client - no special configuration needed.

---

## Scenario 2: White-Labeled Clients (Fillungo Partnership)

**Example:** You're white-labeled with Fillungo, some clients are on Fillungo's GSC account

### Two Approaches

#### Approach A: Add Your Service Account to Fillungo's GSC (Recommended)

**What to do:**
1. Ask Fillungo (Scott) to add your service account to each client's GSC property
2. Service account email: `seo-process-automation@raleigh-seo-kit.iam.gserviceaccount.com`
3. Permission needed: **Full** or **Restricted** (read-only is fine)

**Where Fillungo adds it:**
- Go to: https://search.google.com/search-console
- Select client property
- Settings → Users and permissions → Add user
- Enter: `seo-process-automation@raleigh-seo-kit.iam.gserviceaccount.com`
- Permission: Full
- Add

**Benefits:**
- ✅ Your automation works normally
- ✅ No additional configuration needed
- ✅ Fillungo maintains ownership
- ✅ You get read/write access via service account

**After Fillungo adds access:**
```bash
# Test it works
./bin/test-gsc-access.sh fillungo-client-1

# If successful, you're done!
```

#### Approach B: Create Separate Service Account for Fillungo Clients

**If Fillungo prefers separate credentials:**

1. **Fillungo creates their own service account** in their Google Cloud project
2. **Fillungo shares the service account key** with you
3. **You configure per-client credentials**

**Setup:**

```bash
# Store Fillungo's service account key
mkdir -p credentials/fillungo
# Copy key to: credentials/fillungo/service-account-key.json
```

**In each Fillungo client's config:**

```yaml
# workspace/fillungo-client-1/seo/config.yaml

client_id: fillungo-client-1
site: "sc-domain:fillungoclient.com"
site_url: "https://fillungoclient.com"

# ... other config ...

# OPTIONAL: Override service account for this client
# If not specified, uses default from .env
# google_application_credentials: "/home/user/seo-process/credentials/fillungo/service-account-key.json"
```

**Note:** Currently our scripts don't support per-client credentials. You'd need to either:
- Use Approach A (add your service account to their GSC), OR
- Temporarily switch `.env` credentials when running Fillungo clients

#### Approach C: Run Fillungo Clients Separately

**Create a separate workspace for Fillungo clients:**

```bash
# Clone the repo to a different directory
cd ~
git clone https://github.com/roberts-hardware/seo-process.git seo-process-fillungo
cd seo-process-fillungo

# Configure with Fillungo's credentials
cp .env.example .env
nano .env
# Set GOOGLE_APPLICATION_CREDENTIALS to Fillungo's service account key

# Onboard Fillungo clients here
./bin/add-client.sh fillungo-client-1 https://client1.com

# Run automation for Fillungo clients
./bin/schedule-all-clients.sh monday-morning
```

**Pros:**
- ✅ Complete separation
- ✅ Different credentials per partnership
- ✅ Easy to manage multiple white-label relationships

**Cons:**
- ❌ Need to manage multiple repos/directories
- ❌ Separate cron jobs

### Recommended: Approach A

**Ask Scott/Fillungo to add your service account to their clients' GSC.**

This is the simplest and most maintainable approach.

---

## Scenario 3: Mixing Both Issues

**Example:** Fillungo has a client (unikwax) with 40 locations

**Solution:** Combine both strategies:

1. **Ask Fillungo to add your service account** to unikwax's GSC
2. **Configure unikwax as a single client** with 40 service areas
3. Everything else works normally

```bash
./bin/add-client.sh unikwax https://unikwax.com "competitors"
nano workspace/unikwax/seo/config.yaml
# Add all 40 locations as service_areas
```

---

## CSV Bulk Import for Special Scenarios

### Multi-Location Clients

**In CSV, you can only specify 3 primary cities directly.**

For clients with 40 locations:

**Option 1: Use CSV for basic setup, then manually edit config**

```csv
client_id,site_url,...,primary_city_1,zip_1,...,secondary_cities,...
unikwax,https://unikwax.com,...,New York,10001,...,See config for all 40,...
```

Then after import:
```bash
nano workspace/unikwax/seo/config.yaml
# Add all 40 locations manually
```

**Option 2: Create a separate CSV format for multi-location clients**

We can create a Python script that reads:
- `clients.csv` - Standard clients
- `multi-location-clients.csv` - Separate file with all locations

### White-Labeled Clients

**Just include them in the CSV normally:**

```csv
client_id,site_url,...
fillungo-client-1,https://client1.com,...
fillungo-client-2,https://client2.com,...
```

Then ask Fillungo to add your service account to each property.

---

## Quick Decision Tree

**Is the client on one domain with multiple locations?**
- **YES, <10 locations:** Create 1 client, add all locations to config
- **YES, 10-40 locations:** Create 1 client, prioritize top 10 for full pages
- **YES, 40+ locations:** Create 1 client, use hub & spoke architecture

**Is the client under a partner's GSC account?**
- **YES:** Ask partner to add your service account (easiest)
- **YES, partner says no:** Use separate service account for that partner
- **YES, multiple partners:** Consider separate repo per partner

**Is it BOTH multi-location AND white-labeled?**
- Combine both strategies
- Ask partner to add service account
- Configure as single client with many locations

---

## Summary Table

| Scenario | Configuration | GSC Access | Content Strategy |
|----------|---------------|------------|------------------|
| **40 locations, one domain** | 1 client config, 40 service areas | Add service account once | Hub & spoke (50 pages) |
| **White-labeled (Fillungo)** | Normal client config | Partner adds service account | Standard approach |
| **Both** | 1 client, 40 areas | Partner adds service account | Hub & spoke |
| **Multiple partners** | Separate repo per partner | Each partner adds their SA | Standard per repo |

---

## Questions?

**For unikwax specifically:**
1. Is it under your GSC or Fillungo's?
2. Do all 40 locations need content, or prioritize top markets?
3. What's the business type/services?

**For Fillungo clients:**
1. Ask Scott to add: `seo-process-automation@raleigh-seo-kit.iam.gserviceaccount.com`
2. To each client property in GSC
3. Full or Restricted permission (either works)

Once those are answered, we can optimize the setup!
