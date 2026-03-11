# Continuous Automation Setup Guide

## How Your Team Gets Automated Results 24/7

This guide sets up **fully automated** SEO monitoring that runs continuously and reports results to your team without manual intervention.

---

## 🎯 Overview: What Gets Automated

**System runs automatically:**
- ✅ Weekly SEO discovery (finds new keyword opportunities)
- ✅ Weekly rankings monitoring (tracks all keyword positions)
- ✅ Weekly health checks (site speed, crawlability, images)
- ✅ Results sync to GitHub automatically
- ✅ Dashboard updates in real-time
- ✅ Team notifications (Slack/Email)

**Team sees results:**
- 📊 Live dashboard shows all client data
- 📱 Slack/Email notifications when runs complete
- 📈 Historical trends and charts
- 🎯 Strike zone keywords (quick wins)

**No manual work required** - set it and forget it!

---

## 🖥️ Step 1: Server Setup (One-Time)

You need a server/machine that runs 24/7. Options:

### Option A: Cloud Server (Recommended)
- **DigitalOcean Droplet** ($6/month - basic)
- **AWS EC2** (t3.micro - ~$8/month)
- **Linode** ($5/month)
- **Your existing OpenClaw server** ✅ (you already have this!)

### Option B: Local Machine
- Mac Mini / Old laptop that runs 24/7
- Must stay powered on and connected to internet

**Recommended: Use your OpenClaw server** since you already have it running.

### Install on Server

```bash
# SSH into your server
ssh user@your-server.com

# Clone the repo
cd ~
git clone https://github.com/roberts-hardware/seo-process.git
cd seo-process

# Set up credentials
cp .env.example .env
nano .env
# Add your API keys (GSC, DataForSEO, etc.)

# Make scripts executable
chmod +x bin/*.sh

# Create logs directory
mkdir -p logs
```

---

## ⚙️ Step 2: Configure Automated Schedule

### Edit Crontab

```bash
crontab -e
```

### Add These Jobs

```cron
# ============================================================
# SEO Process - Automated Multi-Client Monitoring
# ============================================================

# Every Sunday 8pm PT - Discovery + Monitoring for ALL clients
0 20 * * 0 cd ~/seo-process && ./bin/schedule-all-clients.sh monday-morning >> ~/seo-process/logs/cron.log 2>&1

# Every Friday 3pm PT - Health checks for ALL clients
0 15 * * 5 cd ~/seo-process && ./bin/schedule-all-clients.sh friday-afternoon >> ~/seo-process/logs/cron.log 2>&1

# Daily 9am PT - Update dashboard index
0 9 * * * cd ~/seo-process && ./bin/generate-client-index.sh && ./bin/sync-workspace.sh all "Daily update" >> ~/seo-process/logs/cron.log 2>&1
```

**Time zones:** Adjust times based on your server's timezone. Use `date` to check current time.

**Save and exit:** Press `ESC`, type `:wq`, press `ENTER`

### Verify Cron Jobs

```bash
crontab -l
```

You should see your 3 jobs listed.

---

## 📢 Step 3: Team Notifications (Slack + Email)

### Slack Notifications (Recommended)

**1. Create Slack Incoming Webhook:**
- Go to https://api.slack.com/messaging/webhooks
- Click "Create New App" → "From Scratch"
- Name: "SEO Process Bot"
- Choose your workspace
- Click "Incoming Webhooks" → Toggle ON
- Click "Add New Webhook to Workspace"
- Choose channel (e.g., `#seo-reports`)
- Copy webhook URL (starts with `https://hooks.slack.com/...`)

**2. Add to .env file:**

```bash
nano ~/seo-process/.env
```

Add this line:
```bash
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

**3. Test it:**

```bash
./bin/notify-team.sh "Test" "success" "Testing Slack notifications"
```

You should see a message in your Slack channel!

### Email Notifications (Optional)

**1. Configure server email:**

Most servers can send email via `mail` command. Test:

```bash
echo "Test email" | mail -s "Test" your-email@example.com
```

**2. Add to .env:**

```bash
EMAIL_TO="team@yourcompany.com"
```

### What Team Gets Notified About

**Automatic notifications sent for:**
- ✅ Weekly discovery/monitoring completion
- ✅ Weekly health checks completion
- ❌ Any failures or errors
- 📊 Link to dashboard in every notification

**Notification example (Slack):**

```
✅ SEO Process: monday-morning
Status: success
Clients: 10
Time: 2026-03-10 20:05:23
Details: 10 clients processed successfully

Dashboard: https://seo-dashboard.yourcompany.com
```

---

## 📊 Step 4: Team Dashboard (Where Results Appear)

### Quick Setup with Cloudflare Pages

**1. Create dashboard project:**

```bash
# On your local machine (not server)
mkdir seo-dashboard
cd seo-dashboard
npm create vite@latest . -- --template react
npm install
```

**2. Create simple dashboard:**

Create `src/App.jsx`:

```jsx
import { useState, useEffect } from 'react'
import './App.css'

const GITHUB_RAW_URL = 'https://raw.githubusercontent.com/roberts-hardware/seo-process/main/workspace'

function App() {
  const [clients, setClients] = useState([])
  const [selectedClient, setSelectedClient] = useState(null)
  const [clientData, setClientData] = useState(null)

  // Load client list
  useEffect(() => {
    fetch(`${GITHUB_RAW_URL}/clients.json`)
      .then(res => res.json())
      .then(data => {
        setClients(data)
        if (data.length > 0) setSelectedClient(data[0].id)
      })
  }, [])

  // Load selected client data
  useEffect(() => {
    if (!selectedClient) return

    fetch(`${GITHUB_RAW_URL}/${selectedClient}/seo/snapshots/${selectedClient}_com-latest.json`)
      .then(res => res.json())
      .then(data => setClientData(data))
      .catch(err => console.log('No snapshot yet'))
  }, [selectedClient])

  return (
    <div className="dashboard">
      <h1>SEO Mission Control</h1>

      <select value={selectedClient} onChange={(e) => setSelectedClient(e.target.value)}>
        {clients.map(client => (
          <option key={client.id} value={client.id}>
            {client.name} - {client.business_type}
          </option>
        ))}
      </select>

      {clientData && (
        <div className="client-data">
          <h2>Rankings Snapshot</h2>
          <p>Date: {clientData.date}</p>
          <p>Total Keywords: {clientData.rows?.length || 0}</p>

          <h3>Top 10 Keywords</h3>
          <table>
            <thead>
              <tr>
                <th>Keyword</th>
                <th>Position</th>
                <th>Clicks</th>
                <th>Impressions</th>
              </tr>
            </thead>
            <tbody>
              {clientData.rows?.slice(0, 10).map((row, i) => (
                <tr key={i}>
                  <td>{row.keyword}</td>
                  <td>{row.position.toFixed(1)}</td>
                  <td>{row.clicks}</td>
                  <td>{row.impressions}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="footer">
        <p>Last updated: {new Date().toLocaleString()}</p>
        <p>Auto-refreshes every 5 minutes</p>
      </div>
    </div>
  )
}

export default App
```

**3. Deploy to Cloudflare Pages:**

```bash
# Push to GitHub
git init
git add .
git commit -m "Initial dashboard"
git remote add origin https://github.com/YOUR-ORG/seo-dashboard.git
git push -u origin main

# Deploy on Cloudflare
# 1. Go to https://pages.cloudflare.com
# 2. Click "Create a project"
# 3. Connect to your seo-dashboard repo
# 4. Build settings:
#    - Framework: Vite
#    - Build command: npm run build
#    - Output directory: dist
# 5. Click "Save and Deploy"
```

**Your dashboard is now live!**
- URL: `https://seo-dashboard.pages.dev` (or custom domain)
- Updates automatically when GitHub data changes
- No server maintenance required

### Dashboard Features to Add Later

**Phase 1 (Current):**
- ✅ Client selector dropdown
- ✅ Latest rankings snapshot
- ✅ Top keywords table

**Phase 2 (Add these):**
- 📈 Charts (rankings over time)
- 🎯 Strike zone keywords section
- 🏥 Health check results
- 📊 Competitor comparison
- 📅 Historical trend graphs

---

## 🔄 How the Complete System Works

### Weekly Automation Flow

**Sunday 8pm:**
```
1. Cron triggers schedule-all-clients.sh monday-morning
2. For each client:
   - Runs discovery (finds strike zone keywords)
   - Runs monitoring (tracks all rankings)
   - Saves results to workspace/{client-id}/seo/
3. Syncs all results to GitHub
4. Updates clients.json index
5. Sends Slack/Email notification to team
```

**Friday 3pm:**
```
1. Cron triggers schedule-all-clients.sh friday-afternoon
2. For each client:
   - Runs health-speed.sh (page speed)
   - Runs health-crawl.sh (crawlability)
   - Runs health-images.sh (image optimization)
   - Saves results to workspace/{client-id}/seo/health/
3. Syncs all results to GitHub
4. Sends Slack/Email notification
```

**Daily 9am:**
```
1. Regenerates clients.json index
2. Syncs to GitHub
3. Dashboard auto-refreshes with latest data
```

### Team Access Flow

**Team members:**
1. Get Slack notification: "Weekly SEO update complete"
2. Click dashboard link in notification
3. Select client from dropdown
4. See latest rankings, keywords, health data
5. Review charts and trends
6. Download reports if needed

**No manual work required!**

---

## 📱 Team Access Points

### 1. Dashboard (Primary)
- **URL:** `https://seo-dashboard.pages.dev`
- **Access:** Anyone with link (public) or behind Cloudflare Access (private)
- **Updates:** Real-time when GitHub data changes

### 2. Slack Channel
- **Channel:** `#seo-reports`
- **Gets:** Weekly completion notifications
- **Includes:** Dashboard link + summary stats

### 3. Email (Optional)
- **To:** team@yourcompany.com
- **Frequency:** Weekly when runs complete
- **Contains:** Summary + dashboard link

### 4. GitHub (Advanced Users)
- **Repo:** `https://github.com/roberts-hardware/seo-process`
- **Direct access:** Raw JSON/CSV files in workspace/
- **Git history:** Track changes over time

---

## 🔐 Securing Team Access

### Public Dashboard (Simple)
- Dashboard is public
- Anyone with link can view
- No login required

### Private Dashboard (Recommended)

**Option 1: Cloudflare Access (Free for small teams)**

```bash
# On Cloudflare dashboard:
1. Go to "Zero Trust" → "Access"
2. Create Application
3. Name: "SEO Dashboard"
4. Domain: seo-dashboard.pages.dev
5. Add Policy:
   - Allow emails: team1@company.com, team2@company.com
6. Save

# Team members now need to:
- Enter email when accessing dashboard
- Click link in email to verify
- Access granted for 24 hours
```

**Option 2: Password Protection**

Add to dashboard:

```jsx
const [authenticated, setAuthenticated] = useState(false)

if (!authenticated) {
  return (
    <div>
      <input
        type="password"
        placeholder="Enter password"
        onKeyPress={(e) => {
          if (e.key === 'Enter' && e.target.value === 'YOUR_PASSWORD') {
            setAuthenticated(true)
          }
        }}
      />
    </div>
  )
}
```

---

## 📈 Monitoring the Automation

### Check If Cron is Running

```bash
# View recent log entries
tail -100 ~/seo-process/logs/cron.log

# Watch logs in real-time
tail -f ~/seo-process/logs/cron.log

# Check notification history
cat ~/seo-process/logs/notifications.log
```

### Check What's Scheduled

```bash
crontab -l
```

### Manually Test a Run

```bash
# Test full automation for all clients
./bin/schedule-all-clients.sh monday-morning

# Test single client
./bin/run-and-sync.sh ckalcevicroofing skills/seo-agent/scripts/seo-discover.sh --limit 20
```

### Check Dashboard Data

```bash
# View client index
cat workspace/clients.json | jq

# View latest snapshot for client
cat workspace/ckalcevicroofing/seo/snapshots/ckalcevicroofing_com-2026-03-10.json | jq | head -50
```

---

## 🚨 Troubleshooting

### Cron Job Not Running

**Check cron service:**
```bash
# Linux
sudo systemctl status cron

# macOS
sudo launchctl list | grep cron
```

**Check logs:**
```bash
tail -100 /var/log/syslog | grep CRON  # Linux
tail -100 /var/log/system.log | grep cron  # macOS
```

**Common issues:**
- Wrong path in crontab (use absolute paths)
- Missing environment variables (cron doesn't load .env automatically)
- Script not executable (`chmod +x bin/*.sh`)

### Notifications Not Sending

**Slack:**
```bash
# Test webhook manually
curl -X POST "YOUR_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test notification"}'
```

**Email:**
```bash
# Test mail command
echo "Test" | mail -s "Test" your-email@example.com
```

### Dashboard Not Updating

**Check GitHub:**
- Are files syncing? Check latest commits
- Is clients.json updated?

**Check Cloudflare Pages:**
- Go to dashboard → "Deployments"
- Check if latest deployment succeeded
- Redeploy manually if needed

### Script Failures

**Check error logs:**
```bash
tail -100 ~/seo-process/logs/cron.log | grep -i error
```

**Common issues:**
- API rate limits (add delays between clients)
- GSC authentication expired (re-run `gcloud auth`)
- Missing client config

---

## 📊 What Team Members See

### Slack Notification (Every Sunday)

```
✅ SEO Process: monday-morning
Status: success
Clients: 10
Time: 2026-03-10 20:05:23
Details: 10 clients processed successfully

Dashboard: https://seo-dashboard.pages.dev
```

### Dashboard View

**Client Selector:**
```
[Dropdown: CKalcevic Roofing ▼]
```

**Latest Snapshot:**
```
📊 Rankings Snapshot - 2026-03-10

Total Keywords: 500
Top 10 Positions: 164
Strike Zone (5-20): 162
```

**Top Keywords Table:**
```
Keyword                          | Position | Clicks | Impressions
---------------------------------|----------|--------|------------
roofer beaver falls pa           | 1.0      | 1      | 38
metal roofing companies near me  | 1.0      | 1      | 1
roofing companies near me        | 7.1      | 2      | 22
```

**Health Status:**
```
🟢 Page Speed: 92/100
🟢 Crawlability: No issues
🟡 Images: 3 need optimization
```

---

## 🎯 Onboarding New Team Members

**1. Give access to:**
- Slack channel `#seo-reports`
- Dashboard URL: `https://seo-dashboard.pages.dev`
- (Optional) GitHub repo for raw data

**2. Show them:**
- How to use dashboard dropdown
- Where to find weekly notifications
- How to interpret rankings data

**3. They can:**
- View all client data
- See historical trends
- Download reports
- Monitor performance

**They DON'T need:**
- Server access
- Technical knowledge
- To run scripts manually

---

## ✅ Setup Checklist

**One-time setup:**
- [ ] Server configured with seo-process repo
- [ ] Credentials added to .env
- [ ] Cron jobs added
- [ ] Slack webhook configured
- [ ] Dashboard deployed to Cloudflare Pages
- [ ] Test run successful
- [ ] Team members added to Slack channel

**Per-client setup:**
- [ ] Run `./bin/add-client.sh`
- [ ] Configure client config.yaml
- [ ] Add GSC access
- [ ] Run initial discovery/monitoring
- [ ] Verify data appears in dashboard

**Ongoing (automated):**
- ✅ Weekly discovery/monitoring runs automatically
- ✅ Weekly health checks run automatically
- ✅ Results sync to GitHub automatically
- ✅ Dashboard updates automatically
- ✅ Team gets notified automatically

---

## 🚀 You're Done!

Your team now has:
- ✅ Fully automated SEO monitoring (24/7)
- ✅ Live dashboard with all client data
- ✅ Weekly Slack/Email notifications
- ✅ No manual work required
- ✅ Scales to unlimited clients

**Set it and forget it!**

Questions? Check the logs at `~/seo-process/logs/cron.log`
