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

# Check if google-auth is already installed
if python3 -c "import google.auth" 2>/dev/null; then
  echo "✅ google-auth already installed"
else
  echo "Installing google-auth (for Search Console API with service accounts)..."
  echo ""

  # Try system package manager first (for Debian/Ubuntu with externally-managed Python)
  if command -v apt &> /dev/null; then
    echo "Detected apt package manager (Debian/Ubuntu)"
    echo "Installing via apt (requires sudo)..."
    echo ""
    sudo apt update -qq
    sudo apt install -y python3-google-auth

    if python3 -c "import google.auth" 2>/dev/null; then
      echo "✅ google-auth installed successfully via apt"
    else
      echo "❌ apt install failed, trying pip..."
      python3 -m pip install --user --upgrade google-auth 2>/dev/null || python3 -m pip install --break-system-packages --upgrade google-auth
    fi

  # Try yum for CentOS/RHEL
  elif command -v yum &> /dev/null; then
    echo "Detected yum package manager (CentOS/RHEL)"
    echo "Installing via yum (requires sudo)..."
    echo ""
    sudo yum install -y python3-google-auth

  # Try pip for macOS or other systems
  else
    echo "Installing via pip..."
    python3 -m pip install --user --upgrade google-auth 2>/dev/null || {
      echo "⚠️  pip --user failed, trying with --break-system-packages..."
      python3 -m pip install --break-system-packages --upgrade google-auth
    }
  fi

  # Final check
  if python3 -c "import google.auth" 2>/dev/null; then
    echo "✅ google-auth installed successfully"
  else
    echo "❌ Failed to install google-auth"
    echo ""
    echo "Try manually:"
    echo "  Debian/Ubuntu: sudo apt install python3-google-auth"
    echo "  CentOS/RHEL: sudo yum install python3-google-auth"
    echo "  Other: pip3 install google-auth"
    exit 1
  fi
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
