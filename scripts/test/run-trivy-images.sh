#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

REPORT_DIR="test/reports/trivy/images"

mkdir -p "$REPORT_DIR"

WORKSPACE="${HOST_WORKSPACE:-$PWD}"
echo "Workspace for Docker: $WORKSPACE"

docker run --rm \
		-v trivy-cache:/root/.cache/trivy \
		aquasec/trivy:0.72.0 \
		image --download-db-only

while read -r image; do
		echo "Scanning $image..."

		REPORT_FILE="$(echo "$image" | tr '/:' '__').json"
    success=false
		LOG_FILE="$REPORT_DIR/$(echo "$image" | tr '/:' '__').error.log"

		for attempt in 1 2 3; do
		    if timeout 5m docker run --rm \
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
				     "$image" \
						 >"$LOG_FILE" 2>&1;
		    then
				    echo "✓ Scan completed"
						rm -f "$LOG_FILE"
						success=true
				    break
				fi
				echo "Attempt $attempt failed"
				if (( attempt != 3 )); then
						echo "Retrying..."
				fi
		done
		
		if [[ "$success" != true ]]; then
				echo "Skipping $image"
				echo "$image" >> "$REPORT_DIR/skipped-images.txt"
		fi

done < <(./scripts/test/get-docker-images.sh)

