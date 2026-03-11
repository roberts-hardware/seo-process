# Migration Strategy: Preserving Existing Rankings

## Current Situation

**CKalcevic has STRONG rankings in Beaver Falls:**
- Position 1-2 for commercial keywords
- Position 1 for residential keywords
- 100+ impressions on emergency keywords
- **These rankings took years to build - we MUST preserve them**

**Problem:**
- Switching to hub & spoke could temporarily drop Beaver Falls rankings
- Need to maintain ranking momentum while restructuring

---

## Strategy: Hybrid Migration (Best of Both)

### Option 1: Keep Existing Beaver Falls Pages (RECOMMENDED)

**DO NOT delete or redirect existing high-performing pages**

**Keep as-is:**
- Any page currently ranking positions 1-10
- Any page getting 50+ impressions/month
- Any page with backlinks

**Action:**
1. Audit all existing pages in GSC
2. Identify pages in positions 1-10
3. Keep those pages live
4. Add NEW hub pages alongside them
5. Interlink old pages with new hubs

**Example:**
```
KEEP: /commercial-roofing-beaver-falls/ (ranks #1)
ADD:  /commercial-roofing/ (new hub)
ADD:  /beaver-falls/ (new location hub)

Internal linking:
- /commercial-roofing-beaver-falls/ → links to /commercial-roofing/ and /beaver-falls/
- /commercial-roofing/ → links to /commercial-roofing-beaver-falls/ and /beaver-falls/
- /beaver-falls/ → links to /commercial-roofing-beaver-falls/ and /commercial-roofing/
```

**Result:**
- ✅ Preserve existing rankings
- ✅ Add new hub authority
- ✅ Multiple pages can rank for same query (more SERP real estate)
- ✅ No traffic drop during transition

---

### Option 2: 301 Redirect (ONLY if content is weak)

**Only redirect pages that:**
- Rank below position 20
- Get <10 impressions/month
- Have no backlinks
- Are duplicate/thin content

**Example:**
```
REDIRECT: /emergency-repair-cranberry/ (doesn't exist yet, no rankings)
TO:       /cranberry-township/ (new hub with emergency section)

REDIRECT: /metal-roofing-mars/ (ranks position 45, 2 impressions/month)
TO:       /metal-roofing/ (new service hub)
```

---

## Recommended Page Structure for CKalcevic

### Tier 1: Hub Pages (NEW)
- /commercial-roofing/
- /residential-roofing/
- /emergency-roof-repair/
- /metal-roofing/
- /roof-repair/
- /cranberry-township/
- /wexford/
- /butler-county/

### Tier 2: High-Performing Legacy Pages (KEEP)
- /commercial-roofing-beaver-falls/ (ranks #1 - DO NOT TOUCH)
- /roof-repair-beaver-falls/ (ranks #1 - KEEP)
- /roofer-beaver-falls/ (ranks #1 - KEEP)
- Any other pages ranking positions 1-10

### Tier 3: New Supporting Pages
- /beaver-falls/ (NEW location hub to complement existing pages)
- /mars/
- /seven-fields/

### Tier 4: Redirect or Delete
- Pages ranking 20+ with no traffic
- Duplicate content pages
- Outdated service pages

---

## Migration Checklist

### Phase 1: Audit (Week 1)
- [ ] Export all pages from GSC with rankings
- [ ] Identify pages in positions 1-10 (KEEP these)
- [ ] Identify pages with 50+ impressions/month (KEEP these)
- [ ] Check backlink profile (ahrefs/semrush) - note pages with backlinks
- [ ] Create keep/redirect/delete spreadsheet

### Phase 2: Publish New Hubs (Week 2-3)
- [ ] Publish all service hubs
- [ ] Publish primary location hubs
- [ ] DO NOT redirect anything yet
- [ ] Let new pages start indexing

### Phase 3: Interlink (Week 4)
- [ ] Add links FROM new hubs TO existing high-performers
- [ ] Add links FROM existing pages TO new hubs
- [ ] Update navigation to feature new hubs
- [ ] Submit new pages to GSC

### Phase 4: Monitor (Week 5-8)
- [ ] Watch new hub rankings climb
- [ ] Ensure old page rankings stay stable
- [ ] Track impressions on both old and new pages

### Phase 5: Optimize (Week 9+)
- [ ] If new hubs rank well, consider redirecting weak old pages
- [ ] Keep high-performers forever
- [ ] Continue building authority on hubs

---

## Example: Beaver Falls Migration

**Current state:**
- /commercial-roofing-beaver-falls/ ranks #1
- Gets 45 impressions/month
- 0 clicks (CTR problem, not ranking problem)

**New structure:**
1. **KEEP** /commercial-roofing-beaver-falls/ (it's winning!)
2. **ADD** /commercial-roofing/ (service hub)
3. **ADD** /beaver-falls/ (location hub)

**Interlinking:**

On `/commercial-roofing/`:
```markdown
### Beaver Falls
We've been serving Beaver Falls businesses for over 25 years with
comprehensive commercial roofing services. Our local presence means
fast response times and deep knowledge of Beaver Falls properties.

[Learn more about our Beaver Falls commercial roofing →](/commercial-roofing-beaver-falls/)
[All Beaver Falls roofing services →](/beaver-falls/)
```

On `/commercial-roofing-beaver-falls/`:
```markdown
**Looking for other commercial roofing services?**
[View our complete commercial roofing capabilities →](/commercial-roofing/)

**Beaver Falls residents:**
[See all our Beaver Falls roofing services →](/beaver-falls/)
```

On `/beaver-falls/`:
```markdown
### Commercial Roofing
Serving Beaver Falls businesses with TPO, EPDM, and metal roofing.
[Complete commercial roofing services →](/commercial-roofing/)
[Beaver Falls commercial roofing details →](/commercial-roofing-beaver-falls/)
```

**Result:**
- 3 pages all ranking for "commercial roofing beaver falls"
- More SERP real estate
- Different pages serve different user intent
- No rankings lost

---

## What About Cranberry/Wexford?

**No existing content = no migration needed**

**Just publish:**
- /cranberry-township/ (NEW)
- /wexford/ (NEW)

**These will rank from scratch - no risk**

---

## General Rule

**If it's ranking in top 10 and getting traffic → KEEP IT**
**If it's not ranking or getting traffic → Redirect or improve it**

When in doubt, KEEP. You can always redirect later, but you can't undo a redirect that tanked your rankings.
