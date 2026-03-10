# SEO Kit — No Outreach Setup (Applied)

Status: installed in OpenClaw workspace skills.

## What was set up

- Cloned repo to: `/home/bot-father/.openclaw/workspace/seo-kit`
- Installed skills to: `/home/bot-father/.openclaw/workspace/skills/`
  - `seo-forge` ✅
  - `seo-health` ✅
  - `seo-checklist` ✅
  - `seo-images` ✅
  - `seo-agent` (works after DataForSEO env is configured)
- Made all skill scripts executable.

## No-outreach mode

For now, do **not** run:
- `link-mine.sh`
- `link-mentions.sh`
- `link-broken.sh`
- `link-prospect.sh`

Safe to run:
- `seo-forge` (interview, research, writing)
- `seo-health` (speed, crawl, image audits)
- `seo-agent` discovery/monitoring once DataForSEO is set

## Next required auth

### Google Search Console (required)
Use the `gog` flow from `SETUP.md`, then test with:

```bash
bash /home/bot-father/.openclaw/workspace/skills/seo-forge/scripts/seo-check.sh
```

### DataForSEO (optional, but enables seo-agent fully)

```bash
export DATAFORSEO_LOGIN="you@example.com"
export DATAFORSEO_PASSWORD="your_api_password"
```

Then test:

```bash
bash /home/bot-father/.openclaw/workspace/skills/seo-agent/scripts/seo-check.sh
```

## Suggested weekly no-outreach loop

- Monday: discovery + monitoring + health
- Tuesday/Wednesday: content briefs + article drafting
- Friday: health re-check + update internal links only

Internal links only command:

```bash
bash /home/bot-father/.openclaw/workspace/skills/seo-links/scripts/link-internal.sh
```

(Keep other link scripts off until you decide to enable outreach.)
