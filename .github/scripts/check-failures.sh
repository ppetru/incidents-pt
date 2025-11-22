#!/bin/bash
# Check if workflow has been failing for an extended period
# Returns exit code 1 if threshold reached, 0 otherwise

WORKFLOW_NAME="scrape.yml"
FAILURE_THRESHOLD=${1:-12}  # Default: 12 consecutive failures = 1 hour at 5min intervals

echo "Checking recent workflow runs..."

# Get last 20 workflow runs and their conclusions
# Format: conclusion (success, failure, cancelled, etc.)
conclusions=$(gh run list \
    --workflow="${WORKFLOW_NAME}" \
    --limit=20 \
    --json conclusion \
    --jq '.[] | .conclusion')

if [ -z "$conclusions" ]; then
    echo "Warning: Could not fetch workflow run history"
    exit 0
fi

# Count consecutive failures from the most recent run
consecutive_failures=0
while IFS= read -r conclusion; do
    if [ "$conclusion" = "failure" ]; then
        consecutive_failures=$((consecutive_failures + 1))
    else
        # Stop counting at first non-failure
        break
    fi
done <<< "$conclusions"

echo "Consecutive failures: ${consecutive_failures}"
echo "Threshold: ${FAILURE_THRESHOLD}"

if [ $consecutive_failures -ge $FAILURE_THRESHOLD ]; then
    echo "⚠ Failure threshold reached!"
    echo "The workflow has failed ${consecutive_failures} consecutive times."
    exit 1
else
    echo "✓ Failure count is below threshold"
    exit 0
fi
