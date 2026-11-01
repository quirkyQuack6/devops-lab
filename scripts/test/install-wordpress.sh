#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

# Экспортируем переменные для docker compose
export VAULT_MYSQL_ROOT_PASS
export VAULT_MYSQL_USER
export VAULT_MYSQL_PASS
export VAULT_MYSQL_DATABASE
export VAULT_WP_ADMIN
export VAULT_WP_ADMIN_PASS
export VAULT_WP_EMAIL

echo "Waiting for WordPress HTTP to be reachable on port 8008..."
# Ждем, пока Apache не начнет отвечать. Это гарантирует, что docker-entrypoint.sh
# завершился, wp-config.php сгенерирован и права выставлены.
until curl -sf http://localhost:8008 > /dev/null 2>&1; do
  echo -n "."
  sleep 3
done
echo " Ready!"

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
