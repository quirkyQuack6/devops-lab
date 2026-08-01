#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

REPORT_DIR="test/reports/trivy/images"

mkdir -p "$REPORT_DIR"

WORKSPACE="${HOST_WORKSPACE:-$PWD}"
echo "Workspace for Docker: $WORKSPACE"

while read -r image; do
		echo "Scanning $image..."
		
		docker run --rm \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-v "$WORKSPACE":/work \
				-w /work \
				aquasec/trivy:0.72.0 \
				image \
				--format json \
				--output "$REPORT_DIR/$(echo "$image" | tr '/:' '__').json" \
				"$image"

done < <(./scripts/test/get-docker-images.sh)

