#!/usr/bin/env bash
# Automated Google Cloud Service Account Setup
# This script creates a service account for SEO Process automation
# Usage: ./bin/setup-google-auth.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CREDENTIALS_DIR="$REPO_ROOT/credentials"
SERVICE_ACCOUNT_NAME="seo-process-automation"

echo "╔════════════════════════════════════════════════════════════"
echo "║ Google Cloud Service Account Setup"
echo "║ For continuous SEO automation (no expiration)"
echo "╚════════════════════════════════════════════════════════════"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "❌ Error: gcloud CLI not installed"
  echo ""
  echo "Install it:"
  echo "  macOS: brew install google-cloud-sdk"
  echo "  Linux: https://cloud.google.com/sdk/docs/install"
  echo ""
  exit 1
fi

# Step 1: Get current project
echo "📋 Step 1: Getting your Google Cloud project..."
echo ""

CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")

if [[ -z "$CURRENT_PROJECT" ]]; then
  echo "⚠️  No default project set."
  echo ""
  echo "Available projects:"
  gcloud projects list --format="table(projectId,name)"
  echo ""
  read -p "Enter your project ID: " PROJECT_ID

  gcloud config set project "$PROJECT_ID"
  CURRENT_PROJECT="$PROJECT_ID"
else
  echo "Current project: $CURRENT_PROJECT"
  echo ""
  read -p "Use this project? (Y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo "Available projects:"
    gcloud projects list --format="table(projectId,name)"
    echo ""
    read -p "Enter your project ID: " PROJECT_ID

    gcloud config set project "$PROJECT_ID"
    CURRENT_PROJECT="$PROJECT_ID"
  fi
fi

echo ""
echo "✅ Using project: $CURRENT_PROJECT"
echo ""

# Step 2: Enable required APIs
echo "📋 Step 2: Enabling required APIs..."
echo ""

echo "  Enabling Search Console API..."
gcloud services enable searchconsole.googleapis.com --quiet 2>/dev/null || true

echo "  Enabling IAM API..."
gcloud services enable iam.googleapis.com --quiet 2>/dev/null || true

echo ""
echo "✅ APIs enabled"
echo ""

# Step 3: Check if service account exists
echo "📋 Step 3: Creating service account..."
echo ""

SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_NAME@$CURRENT_PROJECT.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &>/dev/null; then
  echo "⚠️  Service account already exists: $SERVICE_ACCOUNT_EMAIL"
  echo ""
  read -p "Use existing service account? (Y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
else
  echo "Creating service account: $SERVICE_ACCOUNT_NAME"

  gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
    --display-name="SEO Process Automation" \
    --description="Service account for automated SEO monitoring across multiple clients"

  echo ""
  echo "✅ Service account created"
fi

echo ""
echo "Service account email: $SERVICE_ACCOUNT_EMAIL"
echo ""

# Step 4: Create credentials directory
echo "📋 Step 4: Setting up credentials directory..."
echo ""

mkdir -p "$CREDENTIALS_DIR"
chmod 700 "$CREDENTIALS_DIR"

echo "✅ Credentials directory ready: $CREDENTIALS_DIR"
echo ""

# Step 5: Generate and download key
echo "📋 Step 5: Generating service account key..."
echo ""

KEY_FILE="$CREDENTIALS_DIR/seo-service-account-key.json"

if [[ -f "$KEY_FILE" ]]; then
  echo "⚠️  Key file already exists: $KEY_FILE"
  echo ""
  read -p "Regenerate new key? (y/N) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Backing up old key..."
    mv "$KEY_FILE" "$KEY_FILE.backup-$(date +%Y%m%d-%H%M%S)"
  else
    echo "Using existing key."
    echo ""
    echo "✅ Key file: $KEY_FILE"
    echo ""
  fi
fi

if [[ ! -f "$KEY_FILE" ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Generating new key..."

  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SERVICE_ACCOUNT_EMAIL"

  chmod 600 "$KEY_FILE"

  echo ""
  echo "✅ Key generated: $KEY_FILE"
  echo ""
fi

# Step 6: Update .env file
echo "📋 Step 6: Updating .env configuration..."
echo ""

ENV_FILE="$REPO_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Creating .env file..."
  cp "$REPO_ROOT/.env.example" "$ENV_FILE"
fi

# Add or update GOOGLE_APPLICATION_CREDENTIALS
if grep -q "^GOOGLE_APPLICATION_CREDENTIALS=" "$ENV_FILE"; then
  # Update existing line
  sed -i.bak "s|^GOOGLE_APPLICATION_CREDENTIALS=.*|GOOGLE_APPLICATION_CREDENTIALS=\"$KEY_FILE\"|" "$ENV_FILE"
  rm -f "$ENV_FILE.bak"
  echo "Updated GOOGLE_APPLICATION_CREDENTIALS in .env"
else
  # Add new line
  echo "" >> "$ENV_FILE"
  echo "# Google Service Account (auto-configured)" >> "$ENV_FILE"
  echo "GOOGLE_APPLICATION_CREDENTIALS=\"$KEY_FILE\"" >> "$ENV_FILE"
  echo "Added GOOGLE_APPLICATION_CREDENTIALS to .env"
fi

# Update project ID
if grep -q "^GOOGLE_CLOUD_PROJECT=" "$ENV_FILE"; then
  sed -i.bak "s|^GOOGLE_CLOUD_PROJECT=.*|GOOGLE_CLOUD_PROJECT=\"$CURRENT_PROJECT\"|" "$ENV_FILE"
  rm -f "$ENV_FILE.bak"
else
  echo "GOOGLE_CLOUD_PROJECT=\"$CURRENT_PROJECT\"" >> "$ENV_FILE"
fi

echo ""
echo "✅ .env file updated"
echo ""

# Step 7: Test authentication
echo "📋 Step 7: Testing authentication..."
echo ""

export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"

echo "Testing API access..."
if gcloud auth application-default print-access-token &>/dev/null; then
  echo "✅ Authentication working!"
else
  echo "⚠️  Warning: Could not test authentication (may need to set up GSC access first)"
fi

echo ""

# Step 8: Instructions for Google Search Console
echo "╔════════════════════════════════════════════════════════════"
echo "║ IMPORTANT: Add Service Account to Google Search Console"
echo "╚════════════════════════════════════════════════════════════"
echo ""
echo "For EACH client domain, you need to grant access:"
echo ""
echo "1. Go to: https://search.google.com/search-console"
echo ""
echo "2. Select a property (e.g., ckalcevicroofing.com)"
echo ""
echo "3. Click Settings (gear icon) → Users and permissions"
echo ""
echo "4. Click 'Add user'"
echo ""
echo "5. Enter this email:"
echo "   ┌──────────────────────────────────────────────────────┐"
echo "   │ $SERVICE_ACCOUNT_EMAIL"
echo "   └──────────────────────────────────────────────────────┘"
echo ""
echo "6. Permission: Full (or Restricted for read-only)"
echo ""
echo "7. Click 'Add'"
echo ""
echo "8. Repeat for each client domain"
echo ""
echo "───────────────────────────────────────────────────────────"
echo ""

# Copy email to clipboard if possible
if command -v pbcopy &>/dev/null; then
  echo "$SERVICE_ACCOUNT_EMAIL" | pbcopy
  echo "✅ Service account email copied to clipboard!"
  echo ""
elif command -v xclip &>/dev/null; then
  echo "$SERVICE_ACCOUNT_EMAIL" | xclip -selection clipboard
  echo "✅ Service account email copied to clipboard!"
  echo ""
fi

# Summary
echo "╔════════════════════════════════════════════════════════════"
echo "║ Setup Complete!"
echo "╚════════════════════════════════════════════════════════════"
echo ""
echo "✅ Service account created: $SERVICE_ACCOUNT_NAME"
echo "✅ Key file saved: $KEY_FILE"
echo "✅ .env file configured"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Add service account to Google Search Console (see instructions above)"
echo ""
echo "2. Test GSC access for a client:"
echo "   ./bin/test-gsc-access.sh ckalcevicroofing"
echo ""
echo "3. If test succeeds, you're ready for automation!"
echo "   ./bin/run-discovery.sh ckalcevicroofing --limit 5"
echo ""
echo "───────────────────────────────────────────────────────────"
echo ""
echo "💡 Pro tip: This authentication NEVER expires!"
echo "   Perfect for continuous automation via cron jobs."
echo ""
