#!/usr/bin/env python3
"""
Generate Google Search Console access token from service account key.
Includes proper webmasters scopes.

Usage: python3 generate-gsc-token.py /path/to/service-account-key.json
"""

import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: generate-gsc-token.py /path/to/service-account-key.json", file=sys.stderr)
        sys.exit(1)

    service_account_file = sys.argv[1]

    if not os.path.exists(service_account_file):
        print(f"Error: Service account key file not found: {service_account_file}", file=sys.stderr)
        sys.exit(1)

    try:
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request

        # Define Search Console scopes
        SCOPES = [
            'https://www.googleapis.com/auth/webmasters.readonly',
            'https://www.googleapis.com/auth/webmasters'
        ]

        # Load credentials from service account key
        credentials = service_account.Credentials.from_service_account_file(
            service_account_file,
            scopes=SCOPES
        )

        # Refresh to get access token
        credentials.refresh(Request())

        # Print the access token
        print(credentials.token)

    except ImportError:
        print("Error: google-auth library not installed", file=sys.stderr)
        print("", file=sys.stderr)
        print("Install it with one of these commands:", file=sys.stderr)
        print("  pip3 install google-auth", file=sys.stderr)
        print("  python3 -m pip install --user google-auth", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error generating token: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
