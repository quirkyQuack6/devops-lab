#!/bin/bash

set -euo pipefail

docker compose -f minio/docker-compose.yml up -d
