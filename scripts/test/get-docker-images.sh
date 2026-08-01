#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

find . -name "docker-compose*.yml" -print0 |
while IFS= read -r -d '' compose; do
		docker compose -f "$compose" config --no-interpolate \
				| awk '/image:/ {print $2}'
done | sort -u | grep -v '^alpine$'
