#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

if docker compose -f test/docker-compose.test.yml run --rm \
		wordpress-cli wp --url=http://wordpress core is-installed; then
		echo "Alresdy installed"
else
		docker compose -f test/docker-compose.test.yml run --rm\
			wordpress-cli wp core install \
			--url=http://wordpress \
			--title='testlab' \
			--admin_user=pepino \
			--admin_password=204melling204 \
			--admin_email=vahrutdinov@gmail.com
fi
