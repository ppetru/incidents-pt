#!/bin/bash
# Create a GitHub issue to alert about extended workflow failures

ISSUE_TITLE="⚠️ Data Scraping Workflow Failing"
ISSUE_LABEL="automated,bug"

echo "Checking for existing open issues..."

# Check if there's already an open issue with this title
existing_issue=$(gh issue list \
    --state open \
    --search "in:title ${ISSUE_TITLE}" \
    --json number \
    --jq '.[0].number')

if [ -n "$existing_issue" ]; then
    echo "✓ Issue already exists: #${existing_issue}"
    echo "Adding a comment to the existing issue..."

    gh issue comment "${existing_issue}" --body "$(cat <<EOF
Still failing as of $(date -u '+%Y-%m-%d %H:%M:%S UTC').

Workflow run: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}
EOF
)"
    exit 0
fi

echo "Creating new issue..."

# Get recent workflow run details
recent_runs=$(gh run list \
    --workflow="scrape.yml" \
    --limit=5 \
    --json databaseId,conclusion,createdAt,url \
    --jq '.[] | "- [\(.conclusion)] \(.createdAt | split("T")[0]) \(.createdAt | split("T")[1] | split(".")[0]) UTC - [Run #\(.databaseId)](\(.url))"')

# Create the issue
gh issue create \
    --title "${ISSUE_TITLE}" \
    --label "${ISSUE_LABEL}" \
    --body "$(cat <<EOF
## Problem

The data scraping workflow has been failing consecutively for an extended period (likely 1+ hours).

## Recent Workflow Runs

${recent_runs}

## Possible Causes

1. **Remote server issues**: The ANEPC API server may be down or experiencing issues
2. **Network connectivity**: GitHub Actions may be having network issues
3. **API changes**: The remote API endpoint may have changed
4. **GitHub API errors**: Internal Server Error when pushing to the repository
5. **SSL/TLS issues**: Certificate or handshake problems with the remote server

## Next Steps

1. Check if the ANEPC API is accessible: https://prociv-agserver.geomai.mai.gov.pt/arcgis/rest/services/Ocorrencias_Base/FeatureServer/0/query?f=geojson&where=0=0&outFields=*
2. Review recent workflow run logs for specific error messages
3. If the issue persists, consider:
   - Adjusting retry parameters
   - Adding more detailed error logging
   - Setting up alternative data sources

## Auto-generated

This issue was automatically created by the workflow monitoring system.

Current run: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}
EOF
)"

echo "✓ Issue created successfully"
