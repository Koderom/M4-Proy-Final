#!/usr/bin/env bash

set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-8080}"

HEALTH_PATH="${HEALTH_PATH:-/health}"

URL="http://${HOST}:${PORT}${HEALTH_PATH}"

echo "======================================"
echo "Health Check"
echo "======================================"
echo "URL: $URL"
echo ""

if curl -sf "$URL" >/dev/null; then
    echo "✅ Health Check OK"
    exit 0
else
    echo "❌ Health Check FAILED"
    exit 1
fi