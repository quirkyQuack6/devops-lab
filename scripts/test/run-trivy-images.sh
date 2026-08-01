#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

REPORT_DIR="test/reports/trivy/images"
REPORT_FILE="$(echo "$image" | tr '/:' '__').json"

mkdir -p "$REPORT_DIR"

WORKSPACE="${HOST_WORKSPACE:-$PWD}"
echo "Workspace for Docker: $WORKSPACE"

docker run --rm \
		-v trivy-cache:/root/.cache/trivy \
		aquasec/trivy:0.72.0 \
		image --download-db-only

while read -r image; do
		echo "Scanning $image..."
		
		timeout 10m docker run --rm \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-v trivy-cache:/root/.cache/trivy \
				-v "$WORKSPACE/$REPORT_DIR":/reports \
				aquasec/trivy:0.72.0 \
				image \
				--scanners vuln \
				--no-progress \
				--skip-db-update \
				--format json \
				--output "/reports/$REPORT_FILE" \
				"$image"

done < <(./scripts/test/get-docker-images.sh)

