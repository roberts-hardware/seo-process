## Hub & Spoke Architecture - Implementation Guide
**CKalcevic Roofing - Scalable SEO Site Structure**

---

## What We Built

### Two Types of Hub Pages

**1. SERVICE HUBS** (covers all locations)
- `/commercial-roofing/` ✅ Created
- `/residential-roofing/` (to be created)
- `/emergency-roof-repair/` (to be created)
- `/metal-roofing/` (to be created)
- `/roof-repair/` (to be created)

**2. LOCATION HUBS** (covers all services)
- `/cranberry-township/` ✅ Created
- `/wexford/` (to be created)
- `/butler-county/` (to be created)
- `/beaver-falls/` (to be created)
- `/mars/` `/seven-fields/` `/evans-city/` (supporting pages)

**Total Pages:** ~12-15 (vs. 42+ with hybrid model)

---

## How Internal Linking Works

### From SERVICE Hub → LOCATION Hubs

**Example: Commercial Roofing page `/commercial-roofing/`**

Links to location pages with keyword-rich anchor text:
```
"We serve businesses throughout Butler County, including:
- [commercial roofing services in Cranberry Township →](/cranberry-township/)
- [Wexford commercial roofing →](/wexford/)
- [Butler County businesses →](/butler-county/)"
```

**Section on service page:**
```markdown
## Service Areas: Butler County & Beyond

### Cranberry Township
Our core service area with fastest response times. We've completed hundreds
of commercial roofing projects in Cranberry Township's business districts,
from office parks on Cranberry Woods Drive to retail centers along Route 19.

[Learn more about our Cranberry Township services →](/cranberry-township/)
```

---

### From LOCATION Hub → SERVICE Hubs

**Example: Cranberry Township page `/cranberry-township/`**

Links to service pages with keyword-rich anchor text:
```
"Our Cranberry Township roofing services include:

### Commercial Roofing
Flat roofing systems, metal roofing, and preventative maintenance for
Cranberry Township businesses.
[Explore our commercial roofing services →](/commercial-roofing/)

### Emergency Roof Repair
24/7 emergency response for Cranberry Township properties.
[24/7 emergency roof repair services →](/emergency-roof-repair/)

### Metal Roofing
Long-lasting metal roofing solutions for Cranberry Township homes.
[Discover metal roofing options →](/metal-roofing/)
```

---

## How Google Ranks This for "Commercial Roofing Cranberry Township"

**Query:** "commercial roofing cranberry township"

**Google's Evaluation:**

1. **`/commercial-roofing/` page:**
   - Primary keyword: "commercial roofing" ✅
   - Mentions "Cranberry Township" 15+ times ✅
   - Links to Cranberry Township page with anchor "Cranberry Township commercial roofing" ✅
   - Comprehensive 3,000+ words ✅
   - High-quality content authority ✅

2. **`/cranberry-township/` page:**
   - Primary keyword: "Cranberry Township" ✅
   - Has section on "Commercial Roofing" ✅
   - Links to commercial roofing page ✅
   - Location-specific content ✅

3. **Reinforcement signals:**
   - Homepage → both pages
   - Both pages → homepage
   - Bidirectional linking between service ↔ location
   - Schema markup with serviceArea and areaServed
   - NAP consistency
   - GMB profile

**Result:** Both pages can rank for "commercial roofing cranberry township"
- Commercial page ranks from service authority
- Cranberry page ranks from location authority
- Google sees clear topical relevance

**Which ranks higher?** Usually the SERVICE hub (`/commercial-roofing/`) because:
- More comprehensive content about commercial roofing
- Higher authority (backlinks tend to go to service pages)
- Better serves informational intent ("what is commercial roofing?")

But the LOCATION hub (`/cranberry-township/`) ranks well for:
- "roofer cranberry township"
- "roofing contractor cranberry township"
- "roofing services cranberry township"
- More transactional, local intent searches

---

## Internal Linking Strategy

### Anchor Text Patterns

**From Service → Location:**
✅ "commercial roofing in Cranberry Township"
✅ "Cranberry Township commercial roofing services"
✅ "serving Cranberry Township businesses"
❌ "click here"
❌ "learn more"
❌ "this page"

**From Location → Service:**
✅ "commercial roofing services"
✅ "expert commercial roofing"
✅ "professional commercial roofers"
❌ "commercial roofing" (exact match - looks spammy if overused)

### Link Placement

**Contextual links (best):**
```markdown
"We specialize in TPO, EPDM, and PVC roofing systems for
businesses in [Cranberry Township](/cranberry-township/),
ensuring your commercial property stays protected year-round."
```

**Section links (good):**
```markdown
### Serving Cranberry Township
[paragraph about Cranberry]
[Learn more about our Cranberry Township services →](/cranberry-township/)
```

**Navigation links (okay but not primary):**
- Header menu
- Footer
- Sidebar

### How Many Links?

**Per page:**
- 3-5 contextual links to key pages (service ↔ location)
- 2-3 related service pages
- 1-2 supporting pages

**Example for `/commercial-roofing/` page:**

Links out to:
1. `/cranberry-township/` (contextual)
2. `/wexford/` (contextual)
3. `/butler-county/` (contextual)
4. `/emergency-roof-repair/` (related service)
5. `/metal-roofing/` (related service)
6. `/residential-roofing/` (related service)
7. Homepage

Total: 7 internal links = good ratio for 3,000-word page

---

## Content Depth Requirements

### Service Hubs (3,000-3,500 words)

**Required sections:**
1. Introduction (200 words)
2. Service details (1,500 words)
   - Multiple subsections
   - Deep dive into each service variation
3. Why choose us (400 words)
4. Service areas (500 words) ← CRITICAL for location linking
5. FAQs (400 words)
6. CTAs throughout

**Goal:** Become the AUTHORITY page for that service

### Location Hubs (2,000-2,500 words)

**Required sections:**
1. Introduction (200 words)
2. Services overview (800 words)
   - Brief description of each service
   - Link to service hub for details
3. Why choose us for this location (400 words)
   - Local expertise
   - Response times
   - Local projects
4. Location-specific information (400 words)
   - Neighborhoods served
   - Common issues in this area
   - Local building codes/requirements
5. FAQs (300 words)
6. CTAs throughout

**Goal:** Become the AUTHORITY page for that location

---

## Schema Markup Strategy

### Service Hub Schema

```json
{
  "@context": "https://schema.org",
  "@type": "Service",
  "serviceType": "Commercial Roofing",
  "provider": {
    "@type": "LocalBusiness",
    "name": "CKalcevic Roofing",
    "telephone": "(724) 494-5614",
    "areaServed": [
      {
        "@type": "City",
        "name": "Cranberry Township",
        "containedIn": "PA"
      },
      {
        "@type": "City",
        "name": "Wexford",
        "containedIn": "PA"
      }
    ]
  }
}
```

### Location Hub Schema

```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "CKalcevic Roofing - Cranberry Township",
  "telephone": "(724) 494-5614",
  "address": {
    "@type": "PostalAddress",
    "addressLocality": "Cranberry Township",
    "addressRegion": "PA",
    "postalCode": "16066"
  },
  "areaServed": {
    "@type": "City",
    "name": "Cranberry Township"
  },
  "hasOfferCatalog": {
    "@type": "OfferCatalog",
    "name": "Roofing Services",
    "itemListElement": [
      {
        "@type": "Offer",
        "itemOffered": {
          "@type": "Service",
          "name": "Commercial Roofing",
          "url": "https://ckalcevicroofing.com/commercial-roofing/"
        }
      },
      {
        "@type": "Offer",
        "itemOffered": {
          "@type": "Service",
          "name": "Residential Roofing",
          "url": "https://ckalcevicroofing.com/residential-roofing/"
        }
      }
    ]
  }
}
```

---

## Scalability Examples

### Adding a New Service

**Old way (Hybrid):**
- Create 7 new pages (one per location)
- Write 7 versions of similar content
- Manage 7 URLs
- 7 sets of schema markup

**New way (Hub & Spoke):**
- Create 1 new service hub page
- Add links from each location hub
- Add to service navigation
- 1 schema markup

**Time saved:** 85%

### Adding a New Location

**Old way (Hybrid):**
- Create 6 new pages (one per service)
- Write 6 versions of similar content
- Manage 6 URLs

**New way (Hub & Spoke):**
- Create 1 new location hub
- Add to service area sections on service hubs
- Add to location navigation

**Time saved:** 80%

### Updating Service Information

**Example:** "We now offer 30-year warranties on TPO roofing"

**Old way:**
- Update commercial-roofing-cranberry-township.md
- Update commercial-roofing-wexford.md
- Update commercial-roofing-mars.md
- Update commercial-roofing-beaver-falls.md
- ... 7 total edits

**New way:**
- Update /commercial-roofing/ (1 edit)
- Done.

---

## Page Hierarchy

```
Homepage
│
├── Service Hubs (Tier 1)
│   ├── Commercial Roofing (3,000 words, high authority)
│   ├── Residential Roofing (3,000 words, high authority)
│   ├── Emergency Repair (2,500 words, high authority)
│   ├── Metal Roofing (2,500 words)
│   └── Roof Repair (2,500 words)
│
└── Location Hubs (Tier 1)
    ├── Cranberry Township (2,000 words, primary)
    ├── Wexford (2,000 words, primary)
    ├── Butler County (2,000 words, broad hub)
    ├── Beaver Falls (2,000 words, strong performance)
    ├── Mars (1,500 words, supporting)
    ├── Seven Fields (1,500 words, supporting)
    └── Evans City (1,500 words, supporting)
```

**All pages are 1 click from homepage**
- Better for SEO (shallow site architecture)
- Better for UX (easy navigation)
- Equal link equity distribution

---

## Content Template: Service Hub

```markdown
# [Service Name] in Butler County, PA

[Introduction paragraph mentioning service areas]

## Our [Service] Services

### [Sub-service 1]
[Detailed content]

### [Sub-service 2]
[Detailed content]

### [Sub-service 3]
[Detailed content]

## Why Choose CKalcevic for [Service]?

### [Benefit 1]
### [Benefit 2]
### [Benefit 3]

## Service Areas: Butler County & Beyond

### [Primary Location 1]
[Paragraph about serving this location]
[Link to location hub]

### [Primary Location 2]
[Paragraph about serving this location]
[Link to location hub]

### [Primary Location 3]
[Paragraph about serving this location]
[Link to location hub]

## [Service] FAQs

[8-10 FAQs]

## Get Started

[CTA]

## Related Services

- [Link to related service 1]
- [Link to related service 2]
- [Link to related service 3]
```

---

## Content Template: Location Hub

```markdown
# Expert Roofing Services in [Location], PA

[Introduction establishing local presence]

## Our Roofing Services in [Location]

### [Service 1]
[Brief description]
[Link to service hub]

### [Service 2]
[Brief description]
[Link to service hub]

### [Service 3]
[Brief description]
[Link to service hub]

## Why [Location] Chooses CKalcevic Roofing

### Local Expertise
[Local knowledge, response times]

### Understanding [Location] Properties
[Neighborhoods, property types]

### [Location] Weather Expertise
[Local climate challenges]

## [Location] Service Area Details

[ZIP codes, neighborhoods, response times]

## Common Roofing Issues in [Location]

[Location-specific problems and solutions]

## [Location] Roofing FAQs

[6-8 location-specific FAQs]

## Get Started

[CTA]

## Our Services

- [Link to service hub 1]
- [Link to service hub 2]
- [Link to service hub 3]

## Nearby Service Areas

- [Link to adjacent location 1]
- [Link to adjacent location 2]
```

---

## Implementation Checklist

### Phase 1: Create Service Hubs
- [ ] Commercial Roofing (✅ done)
- [ ] Residential Roofing
- [ ] Emergency Roof Repair
- [ ] Metal Roofing
- [ ] Roof Repair
- [ ] Roof Replacement

### Phase 2: Create Primary Location Hubs
- [ ] Cranberry Township (✅ done)
- [ ] Wexford
- [ ] Butler County
- [ ] Beaver Falls

### Phase 3: Create Supporting Location Pages
- [ ] Mars
- [ ] Seven Fields
- [ ] Evans City
- [ ] Warrendale
- [ ] Gibsonia

### Phase 4: Internal Linking
- [ ] Add location links to all service hubs
- [ ] Add service links to all location hubs
- [ ] Add related service cross-links
- [ ] Add adjacent location cross-links

### Phase 5: Schema Markup
- [ ] Service schema on all service hubs
- [ ] LocalBusiness schema on all location hubs
- [ ] Breadcrumb schema
- [ ] Validate all schema

### Phase 6: Technical SEO
- [ ] XML sitemap updated
- [ ] Internal linking audit
- [ ] Page speed optimization
- [ ] Mobile optimization
- [ ] Submit to GSC

---

## Tracking & Monitoring

### What to Track in GSC

**Service Hubs - Track rankings for:**
- "[service]" (e.g., "commercial roofing")
- "[service] butler county"
- "[service] [location]" (e.g., "commercial roofing cranberry township")
- "[service] near me"

**Location Hubs - Track rankings for:**
- "roofer [location]"
- "roofing [location]"
- "[service] [location]" (will compete with service hub)
- "roofing contractor [location]"

### Expected Performance

**Week 4-6:**
- Pages indexed
- Initial impressions
- Positions 10-30

**Week 8-12:**
- Service hubs: positions 5-15 for main keywords
- Location hubs: positions 5-15 for location keywords
- Combined queries ranking on both pages

**Week 16-24:**
- Service hubs: positions 1-5 for service keywords
- Location hubs: positions 1-5 for location keywords
- Dominating local search results

---

## Reusability for Other Clients

This architecture works for ANY multi-location home services business:

**Service hubs remain the same:**
- Plumbing
- HVAC
- Electrical
- Landscaping
- etc.

**Location hubs change per client:**
- Client A: Cranberry, Wexford, Mars
- Client B: Squirrel Hill, Shadyside, Oakland
- Client C: Entire metro area

**Time to implement per client:**
- Initial setup: 40-60 hours (write all hubs)
- Additional locations: 3-4 hours each
- Additional services: 5-8 hours each

**vs. Hybrid model:**
- Initial setup: 80-120 hours
- Additional locations: 10-15 hours each
- Additional services: 15-20 hours each

**ROI:** Hub & spoke saves 40-50% of content creation time while delivering better SEO results.

---

## Questions?

This architecture is:
✅ Scalable
✅ Maintainable
✅ SEO-effective
✅ User-friendly
✅ Future-proof

Ready to implement for all your clients.
