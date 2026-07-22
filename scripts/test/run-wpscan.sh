#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/test/reports"
chown 1000:1000 "$REPO_ROOT/test/reports"

if [ -z "${VAULT_WPSCAN_API_TOKEN:-}" ]; then
		echo "ERROR: VAULT_WPSCAN_API_TOKEN is not set"
		exit 1
fi

echo "Host:"
pwd
ls -ld test
ls -ld test/reports
stat test/reports

docker compose \
	--profile tools \
	-f test/docker-compose.test.yml \
	run --rm wpscan-init

echo "Starting WPScan container..."

set +e

docker compose --profile tools -f test/docker-compose.test.yml run \
		wpscan \
		--update \
		--url http://wordpress \
		--enumerate vp,vt,u \
    --format json \
		--output /reports/wpscan-report.json

WPSCAN_EXIT_CODE=$?

echo "WPScan exit code: $WPSCAN_EXIT_CODE"

set -e

if [ "$WPSCAN_EXIT_CODE" -ne 0 ]; then
		exit "$WPSCAN_EXIT_CODE"
fi

echo "WPScan finished"

#if [ ! -f test/reports/wpscan-report.json ]; then
#				echo "ERROR: WPScan report wasn't generated"
#				exit 1
#fi
