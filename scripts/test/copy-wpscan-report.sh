#!/bin/bash

CID=$(docker create -v test_wpscan_reports:/data alpine)

trap 'docker rm -f "$CID" >/dev/null 2>&1 || true' EXIT

docker cp \
  "$CID":/data/wpscan-report.json \
  test/reports/wpscan-report.json
