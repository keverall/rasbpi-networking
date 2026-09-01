#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: export-dashboard <uid> [--output <filename>]"
    exit 1
fi

UID="$1"
shift
OUTPUT=""
while [ $# -gt 0 ]; do
    case $1 in
        --output) OUTPUT="$2"; shift 2;;
        *) echo "Unknown option: $1"; exit 1;;
    esac
done

RESPONSE=$(curl -sf -u "${GF_USER:-admin}:${GF_PASS:-admin}" \
    "http://127.0.0.1:3000/api/dashboards/uid/${UID}")

if [ $? -ne 0 ]; then
    echo "Error: Dashboard with UID '${UID}' not found or API unreachable"
    exit 1
fi

TITLE=$(echo "$RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('dashboard', {}).get('title', 'dashboard'))
")

if [ -z "$OUTPUT" ]; then
    SAFE_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]+/-/g' | sed 's/^-//;s/-$//')
    OUTPUT="${SAFE_TITLE}-${UID}.json"
fi

OUTPUT_PATH="grafana/dashboards/${OUTPUT}"

echo "$RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
dashboard = d.get('dashboard', {})
dashboard.pop('id', None)
print(json.dumps(dashboard, indent=2))
" > "$OUTPUT_PATH"

echo "Exported dashboard '${TITLE}' (UID: ${UID})"
echo "Saved to: ${OUTPUT_PATH}"
