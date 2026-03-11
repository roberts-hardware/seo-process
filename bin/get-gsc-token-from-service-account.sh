#!/usr/bin/env bash
# Generate Google Search Console access token from service account key
# This includes the proper webmasters scope
# Usage: ./bin/get-gsc-token-from-service-account.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Load .env
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

# Check for service account key
if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  echo "❌ Error: GOOGLE_APPLICATION_CREDENTIALS not set in .env" >&2
  exit 1
fi

if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
  echo "❌ Error: Service account key file not found: $GOOGLE_APPLICATION_CREDENTIALS" >&2
  exit 1
fi

# Create Python script to generate token with proper scopes
python3 - "$GOOGLE_APPLICATION_CREDENTIALS" <<'PYTHON_SCRIPT'
import sys
import json
import time
import base64
import hashlib
import urllib.request
import urllib.parse

def generate_jwt(service_account_file, scopes):
    """Generate a signed JWT for service account authentication"""
    with open(service_account_file, 'r') as f:
        sa_data = json.load(f)

    # JWT Header
    header = {
        "alg": "RS256",
        "typ": "JWT"
    }

    # JWT Claim Set
    now = int(time.time())
    claim_set = {
        "iss": sa_data["client_email"],
        "scope": scopes,
        "aud": "https://oauth2.googleapis.com/token",
        "exp": now + 3600,
        "iat": now
    }

    # Encode header and claim set
    def b64encode_url(data):
        return base64.urlsafe_b64encode(json.dumps(data).encode()).decode().rstrip('=')

    jwt_header = b64encode_url(header)
    jwt_claim_set = b64encode_url(claim_set)
    jwt_unsigned = f"{jwt_header}.{jwt_claim_set}"

    # Sign with private key
    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import padding
        from cryptography.hazmat.backends import default_backend

        private_key = serialization.load_pem_private_key(
            sa_data["private_key"].encode(),
            password=None,
            backend=default_backend()
        )

        signature = private_key.sign(
            jwt_unsigned.encode(),
            padding.PKCS1v15(),
            hashes.SHA256()
        )

        jwt_signature = base64.urlsafe_b64encode(signature).decode().rstrip('=')
        return f"{jwt_unsigned}.{jwt_signature}"

    except ImportError:
        print("❌ Error: 'cryptography' package not installed", file=sys.stderr)
        print("", file=sys.stderr)
        print("Install it with:", file=sys.stderr)
        print("  pip3 install cryptography", file=sys.stderr)
        print("  or: python3 -m pip install cryptography", file=sys.stderr)
        sys.exit(1)

def get_access_token(jwt):
    """Exchange JWT for access token"""
    data = urllib.parse.urlencode({
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': jwt
    }).encode()

    req = urllib.request.Request(
        'https://oauth2.googleapis.com/token',
        data=data,
        headers={'Content-Type': 'application/x-www-form-urlencoded'}
    )

    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode())
        return result['access_token']

if __name__ == '__main__':
    service_account_file = sys.argv[1]

    # Include both Search Console scopes
    scopes = ' '.join([
        'https://www.googleapis.com/auth/webmasters.readonly',
        'https://www.googleapis.com/auth/webmasters'
    ])

    try:
        jwt = generate_jwt(service_account_file, scopes)
        token = get_access_token(jwt)
        print(token)
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
PYTHON_SCRIPT
