#!/usr/bin/env bash
# Get Google Search Console access token from application default credentials

set -euo pipefail

CREDS_FILE="$HOME/.config/gcloud/application_default_credentials.json"

if [[ ! -f "$CREDS_FILE" ]]; then
  echo "ERROR: Application default credentials not found" >&2
  echo "Run: gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/webmasters.readonly" >&2
  exit 1
fi

# Extract token from credentials using oauth2l or manual token exchange
# For now, export the path so libraries can use it
export GOOGLE_APPLICATION_CREDENTIALS="$CREDS_FILE"

# Try to use gcloud with the creds
TOKEN=$(gcloud auth application-default print-access-token 2>/dev/null || echo "")

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Could not get access token from application default credentials" >&2
  exit 1
fi

echo "$TOKEN"
