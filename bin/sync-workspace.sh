#!/usr/bin/env bash
# Sync workspace data to GitHub
# Usage: ./bin/sync-workspace.sh <client-id|all> [commit-message]

set -euo pipefail

CLIENT_ARG="${1:?Usage: sync-workspace.sh <client-id|all> [commit-message]}"
COMMIT_MSG="${2:-Update workspace data}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO_ROOT"

# Check if git repo
if [[ ! -d ".git" ]]; then
  echo "❌ Error: Not a git repository"
  exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  echo "📦 Syncing workspace data to GitHub..."
  echo ""

  if [[ "$CLIENT_ARG" == "all" ]]; then
    echo "🔄 Syncing all client workspaces..."
    git add workspace/
  else
    CLIENT_ID="$CLIENT_ARG"
    WORKSPACE="workspace/$CLIENT_ID"

    if [[ ! -d "$WORKSPACE" ]]; then
      echo "❌ Error: Client workspace not found: $WORKSPACE"
      exit 1
    fi

    echo "🔄 Syncing workspace: $CLIENT_ID..."
    git add "$WORKSPACE/"
  fi

  # Show what we're committing
  echo ""
  echo "Changes to commit:"
  git status --short | grep "^[AM]" || echo "  (no staged changes)"
  echo ""

  # Commit
  git commit -m "$COMMIT_MSG" || {
    echo "⚠️  Nothing to commit (or commit failed)"
    exit 0
  }

  # Push
  echo ""
  echo "📤 Pushing to GitHub..."
  git push || {
    echo "❌ Error: Failed to push to GitHub"
    echo "   You may need to: git pull --rebase"
    exit 1
  }

  echo ""
  echo "✅ Workspace synced to GitHub successfully!"
  echo ""
  echo "📊 Dashboard will update automatically (Cloudflare Pages)"
  echo "   Allow 1-2 minutes for deployment"

else
  echo "✅ No changes to sync (workspace up to date)"
fi
