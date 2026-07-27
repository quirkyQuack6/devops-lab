#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

terraform -chdir=terraform init \
		-reconfigure \
		-migrate-state \
		-input=false \
		-backend-config="access_key=${AWS_ACCESS_KEY_ID}" \
		-backend-config="secret_key=${AWS_SECRET_ACCESS_KEY}"
