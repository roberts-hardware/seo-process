#!/usr/bin/env bash
# Install required Python dependencies for SEO automation
# Usage: ./bin/install-dependencies.sh

set -euo pipefail

echo "📦 Installing Python dependencies for SEO automation..."
echo ""

# Check Python 3 is available
if ! command -v python3 &> /dev/null; then
  echo "❌ Error: python3 not found"
  echo ""
  echo "Install Python 3:"
  echo "  macOS: brew install python3"
  echo "  Ubuntu/Debian: sudo apt install python3 python3-pip"
  echo "  CentOS/RHEL: sudo yum install python3 python3-pip"
  exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "✅ Found: $PYTHON_VERSION"
echo ""

# Install google-auth library for service account authentication
echo "Installing google-auth (for Search Console API with service accounts)..."
python3 -m pip install --user --upgrade google-auth

if python3 -c "import google.auth" 2>/dev/null; then
  echo "✅ google-auth installed successfully"
else
  echo "❌ Failed to install google-auth"
  echo ""
  echo "Try manually:"
  echo "  pip3 install google-auth"
  exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════"
echo "║ Dependencies Installed!"
echo "╚════════════════════════════════════════════════════════════"
echo ""
echo "You can now use service account authentication for GSC API."
echo ""
echo "Next steps:"
echo "  1. ./bin/setup-google-auth.sh (if not done yet)"
echo "  2. ./bin/test-gsc-access.sh <client-id>"
echo ""
