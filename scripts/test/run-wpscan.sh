#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/test/reports"

if [ -z "${VAULT_WPSCAN_API_TOKEN:-}" ]; then
		echo "ERROR: VAULT_WPSCAN_API_TOKEN is not set"
		exit 1
fi

docker compose \
	--profile tools \
	-f test/docker-compose.test.yml \
	run --rm wpscan-init

echo "Starting WPScan container..."

docker compose --profile tools -f test/docker-compose.test.yml run --rm -T \
		wpscan \
		--no-update \
		--url http://wordpress \
		--enumerate vp,vt,u \
		--verbose \
    --format json \
		--output /reports/wpscan-report.json

echo "WPScan finished"

