#!/bin/bash

set -euo pipefail

echo "Current directory:"
pwd

echo "Reports directory:"
ls -ld test/reports

echo "Docker compose mount:"
docker compose \
	--profile tools \
  -f test/docker-compose.test.yml \
  config | grep -A3 reports

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/test/reports"
chown 1000:1000 "$REPO_ROOT/test/reports"

if [ -z "${VAULT_WPSCAN_API_TOKEN:-}" ]; then
		echo "ERROR: VAULT_WPSCAN_API_TOKEN is not set"
		exit 1
fi

docker compose \
	--profile tools \
  -f test/docker-compose.test.yml \
  run --rm \
  --entrypoint sh \
  wpscan \
  -c 'id && mount | grep reports && ls -ld /reports'

echo "Starting WPScan container..."

docker compose --profile tools -f test/docker-compose.test.yml run --rm \
		wpscan \
		--no-update \
		--url http://wordpress \
		--enumerate vp,vt,u \
    --format json \
		--output /reports/wpscan-report.json

echo "WPScan finished"

if [ ! -f test/reports/wpscan-report.json ]; then
				echo "ERROR: WPScan report wasn't generated"
				exit 1
fi
