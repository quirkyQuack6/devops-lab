#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

VM_IP=$(terraform -chdir="$REPO_ROOT/terraform" output -raw interfaces)

cat > "$REPO_ROOT/ansible/hosts.ini" <<EOF
[node]
node1 ansible_host=$VM_IP

[node: vars]
ansible_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
EOF

echo "Inventory generated"
cat "$REPO_ROOT/ansible/hosts.ini"
