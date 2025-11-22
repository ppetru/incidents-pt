#!/bin/bash
# Generic retry function with exponential backoff
# Usage: retry_with_backoff <max_attempts> <command...>

retry_with_backoff() {
    local max_attempts="${1}"
    shift
    local attempt=1
    local delay=10

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts: $*"

        if "$@"; then
            echo "✓ Command succeeded on attempt $attempt"
            return 0
        fi

        local exit_code=$?

        if [ $attempt -lt $max_attempts ]; then
            echo "✗ Command failed with exit code $exit_code. Retrying in ${delay}s..."
            sleep $delay
            # Exponential backoff: 10s, 30s, 60s
            delay=$((delay * 3))
            if [ $delay -gt 60 ]; then
                delay=60
            fi
        else
            echo "✗ Command failed after $max_attempts attempts"
            return $exit_code
        fi

        attempt=$((attempt + 1))
    done
}

# If script is called directly (not sourced), execute the retry function
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <max_attempts> <command...>"
        exit 1
    fi
    retry_with_backoff "$@"
fi
