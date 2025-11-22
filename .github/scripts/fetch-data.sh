#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/retry-with-backoff.sh"

URL='https://prociv-agserver.geomai.mai.gov.pt/arcgis/rest/services/Ocorrencias_Base/FeatureServer/0/query?f=geojson&where=0=0&outFields=*'
OUTPUT_FILE="${1:-incidents.json}"
TEMP_FILE="${OUTPUT_FILE}.tmp"

fetch_and_validate() {
    echo "Fetching data from ANEPC API..."

    # Fetch data with timeout and fail on HTTP errors
    # Use custom OpenSSL config for legacy server compatibility
    OPENSSL_CONF=.github/workflows/openssl.cnf curl \
        --fail \
        --silent \
        --show-error \
        --max-time 60 \
        --location \
        "${URL}" > "${TEMP_FILE}"

    # Validate that it's valid JSON
    if ! jq empty "${TEMP_FILE}" 2>/dev/null; then
        echo "✗ Error: Response is not valid JSON"
        cat "${TEMP_FILE}"
        rm -f "${TEMP_FILE}"
        return 1
    fi

    # Pretty-print the JSON and save to output file
    jq . "${TEMP_FILE}" > "${OUTPUT_FILE}"
    rm -f "${TEMP_FILE}"

    echo "✓ Successfully fetched and validated data"
    return 0
}

# Retry fetch with exponential backoff (3 attempts: 10s, 30s, 60s)
retry_with_backoff 3 fetch_and_validate
