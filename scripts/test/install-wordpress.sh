#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

# Exporting variables for docker compose
export VAULT_MYSQL_ROOT_PASS
export VAULT_MYSQL_USER
export VAULT_MYSQL_PASS
export VAULT_MYSQL_DATABASE
export VAULT_WP_ADMIN
export VAULT_WP_ADMIN_PASS
export VAULT_WP_EMAIL

echo "Waiting for WordPress files to be copied to volume..."
# Waiting for docker-entrypoint.sh to copy core-files to volume.
# It's more reliable than check HTTP-response..
until docker compose -f test/docker-compose.test.yml exec -T wordpress test -f /var/www/html/wp-includes/version.php; do
  echo -n "."
  sleep 2
done
echo " Files ready!"

# Generating wp-config.php via WP-CLI.
echo "Generating wp-config.php..."
docker compose -f test/docker-compose.test.yml run --rm \
  wordpress-cli config create \
  --dbname="${VAULT_MYSQL_DATABASE}" \
	--dbuser="${VAULT_MYSQL_USER}" \
	--dbpass="${VAULT_MYSQL_PASS}" \
	--dbhost="db:3306" \
  --force

if docker compose -f test/docker-compose.test.yml run --rm \
		wordpress-cli core is-installed --url="http://wordpress"; then
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
