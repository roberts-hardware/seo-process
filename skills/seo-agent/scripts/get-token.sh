#!/usr/bin/env bash
set -euo pipefail

# Exposes ACCESS_TOKEN for seo-agent scripts.
# Priority:
# 1) Existing ACCESS_TOKEN env var
# 2) GSC_ACCESS_TOKEN env var
# 3) Generate from GOOGLE_APPLICATION_CREDENTIALS (service account) using Python
# 4) gcloud auth print-access-token

_get_token_main() {
  if [[ -n "${ACCESS_TOKEN:-}" ]]; then
    export ACCESS_TOKEN
    return 0
  fi

  if [[ -n "${GSC_ACCESS_TOKEN:-}" ]]; then
    export ACCESS_TOKEN="$GSC_ACCESS_TOKEN"
    return 0
  fi

  # Try to generate token from service account key using Python
  if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]] && [[ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    # Find the generate-gsc-token.py script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    TOKEN_GENERATOR="$REPO_ROOT/bin/generate-gsc-token.py"

    if [[ -f "$TOKEN_GENERATOR" ]] && command -v python3 >/dev/null 2>&1; then
      ACCESS_TOKEN="$(python3 "$TOKEN_GENERATOR" "$GOOGLE_APPLICATION_CREDENTIALS" 2>/dev/null || true)"
      if [[ -n "${ACCESS_TOKEN}" ]]; then
        export ACCESS_TOKEN
        return 0
      fi
    fi
  fi

  # Fallback to default gcloud auth
  if command -v gcloud >/dev/null 2>&1; then
    ACCESS_TOKEN="$(gcloud auth print-access-token 2>/dev/null || true)"
    if [[ -n "${ACCESS_TOKEN}" ]]; then
      export ACCESS_TOKEN
      return 0
    fi
  fi

  echo "ERROR: Unable to get Google access token." >&2
  echo "Set GSC_ACCESS_TOKEN (or ACCESS_TOKEN), or configure GOOGLE_APPLICATION_CREDENTIALS" >&2
  echo "" >&2
  echo "If using service account, install: pip3 install google-auth" >&2
  return 1
}

# If sourced, return from caller instead of exiting script.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  _get_token_main
else
  _get_token_main
  exit $?
fi
