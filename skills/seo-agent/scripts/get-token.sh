#!/usr/bin/env bash
set -euo pipefail

# Exposes ACCESS_TOKEN for seo-agent scripts.
# Priority:
# 1) Existing ACCESS_TOKEN env var
# 2) GSC_ACCESS_TOKEN env var
# 3) gcloud auth print-access-token

_get_token_main() {
  if [[ -n "${ACCESS_TOKEN:-}" ]]; then
    export ACCESS_TOKEN
    return 0
  fi

  if [[ -n "${GSC_ACCESS_TOKEN:-}" ]]; then
    export ACCESS_TOKEN="$GSC_ACCESS_TOKEN"
    return 0
  fi

  if command -v gcloud >/dev/null 2>&1; then
    ACCESS_TOKEN="$(gcloud auth print-access-token 2>/dev/null || true)"
    if [[ -n "${ACCESS_TOKEN}" ]]; then
      export ACCESS_TOKEN
      return 0
    fi
  fi

  echo "ERROR: Unable to get Google access token." >&2
  echo "Set GSC_ACCESS_TOKEN (or ACCESS_TOKEN), or run: gcloud auth login" >&2
  return 1
}

# If sourced, return from caller instead of exiting script.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  _get_token_main
else
  _get_token_main
  exit $?
fi
