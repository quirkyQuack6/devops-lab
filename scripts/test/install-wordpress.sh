#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

if docker compose -f test/docker-compose.test.yml run --rm \
		wordpress-cli wp --url=http://wordpress core is-installed; then
		echo "Already installed"
    exit 0
fi

if docker compose -f test/docker-compose.test.yml run --rm \
     wordpress-cli wp core install \
     --url=http://wordpress \
     --title='testlab' \
			   --admin_user="${VAULT_WP_ADMIN}" \
			   --admin_password="${VAULT_WP_ADMIN_PASS}" \
			   --admin_email="${VAULT_WP_EMAIL}";
then
   echo
   echo "Test environment is ready."
else
   echo "Error: WordPress installation failed."
   exit 1
fi
