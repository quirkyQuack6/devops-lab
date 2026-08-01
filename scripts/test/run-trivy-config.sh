#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

WORKSPACE="${HOST_WORKSPACE:-$PWD}"
echo "Workspace for Docker: $WORKSPACE"

REPORT_DIR="test/reports/trivy"

mkdir -p "$REPORT_DIR"

# Отладка
#echo "PWD=$(pwd)"
#echo "REPORT_DIR=$REPORT_DIR"
#ls -la
#ls -la test
#ls -la test/reports || true
#find . -maxdepth 2 -type f | sort

docker run --rm \
	-v "$WORKSPACE":/work \
	-w /work \
	aquasec/trivy:0.72.0 \
	config . \
	--ignorefile .trivyignore \
	--skip-dirs config/grafana/dashboards	\
	--skip-dirs minio/data \
	--skip-dirs test/reports \
	--format json \
	--output "$REPORT_DIR/config.json"
