#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/retry-with-backoff.sh"

git_push_with_rebase() {
    echo "Attempting to push changes..."

    # Try to push
    if git push 2>&1; then
        echo "✓ Successfully pushed changes"
        return 0
    fi

    local exit_code=$?

    # If push failed, try to pull and rebase in case remote has new commits
    echo "Push failed, attempting to pull and rebase..."

    if git pull --rebase; then
        echo "Rebased successfully, retrying push..."
        if git push; then
            echo "✓ Successfully pushed after rebase"
            return 0
        fi
    fi

    # If we get here, both attempts failed
    return $exit_code
}

# Retry push with exponential backoff (3 attempts: 10s, 30s, 60s)
retry_with_backoff 3 git_push_with_rebase
