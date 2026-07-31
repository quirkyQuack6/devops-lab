#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

REPORT_DIR="test/reports/trivy"

mkdir -p "$REPORT_DIR"

docker run --rm \
	-v "$PWD":/work \
	-w /work \
	aquasec/trivy:0.72.0 \
	config . \
  --skip-dirs config/grafana/dashboards	\
	--skip-dirs minio/data \
	--skip-dirs test/reports \
	--format json \
	--output "$REPORT_DIR/config.json"
