#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

ansible-playbook \
		-i ansible/hosts.ini \
		ansible/playbook.yml \
		--extra-vars "
        mysql_root_password=$VAULT_MYSQL_ROOT_PASS
				mysql_password=$VAULT_MYSQL_PASS
				mysql_user=$VAULT_MYSQL_USER
				mysql_exp_user=$VAULT_MYSQL_EXP_USER
				mysql_database=$VAULT_MYSQL_DATABASE
				telegram_bot_token=$VAULT_TG_TOKEN
				telegram_chat_id=$VAULT_TG_CHAT
    "
