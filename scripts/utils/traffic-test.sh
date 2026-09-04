#!/usr/bin/env bash

set -euo pipefail

NGINX_HOST="${1:-192.168.56.102}"

INSTANCE_PATH="${INSTANCE_PATH:-/api/instance}"

TOTAL_REQUESTS="${TOTAL_REQUESTS:-20}"

echo "======================================"
echo "Traffic Test"
echo "======================================"

echo "Nginx: $NGINX_HOST"
echo "Requests: $TOTAL_REQUESTS"
echo ""

for i in $(seq 1 "$TOTAL_REQUESTS"); do

    response=$(curl -sf \
        "http://${NGINX_HOST}${INSTANCE_PATH}" \
        2>/dev/null || echo "ERROR")

    echo "$i -> $response"

done

echo ""

echo "======================================"
echo "Traffic Test finalizado"
echo "======================================"