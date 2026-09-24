#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

mkdir -p "$REPO_ROOT/test/reports"
chmod 777 "$REPO_ROOT/test/reports"

if [ -z "${VAULT_WPSCAN_API_TOKEN:-}" ]; then
		echo "ERROR: VAULT_WPSCAN_API_TOKEN is not set"
		exit 1
fi

REPORT_FILE="$REPO_ROOT/test/reports/wpscan-report.json"

echo "Starting WPScan container..."

# WPScan exit codes:
#   0 - scan finished, no vulnerable items found
#   5 - scan finished, vulnerable items found
#   * - real error (invalid CLI params, unreachable target, DB issues, ...)
# Code 5 is not trusted blindly: the JSON report is re-checked below, because
# WPScan reports EVERY known CVE for components whose version it could not
# detect (e.g. plugin readme.txt answers HTTP 403). Such findings are
# unconfirmed and must not fail the pipeline.
scan_status=0
docker compose --profile tools -f test/docker-compose.test.yml run --rm -T \
		wpscan \
		--no-update \
		--url http://wordpress \
		--enumerate vp,vt,u \
		--verbose \
    --format json \
		--output /reports/wpscan-report.json || scan_status=$?

if [ "$scan_status" -ne 0 ] && [ "$scan_status" -ne 5 ]; then
    echo "ERROR: WPScan terminated with unexpected exit code: $scan_status"
    exit "$scan_status"
fi

if [ ! -f "$REPORT_FILE" ]; then
    echo "ERROR: WPScan report not found: $REPORT_FILE"
    exit 1
fi

# Emit TSV rows: <confirmed|unconfirmed> <component> <version> <vuln title>
JQ_FILTER='
  def ver: (.version // null) | if type == "object" then (.number // null) else . end;
  def vulns: (.vulnerabilities // []);
  [
    ( .version // null | select(. != null)
      | { name: "wordpress-core", ver: (.number // null), vulns: (.vulnerabilities // []) } ),
    ( (.main_theme // null) | select(. !=null)
		  | { name: ("theme:" + (.slug // "main")), ver: ver, vulns: vulns } ),
    ( (.plugins // {}) | to_entries[]
      | { name: ("plugin:" + .key), ver: (.value | ver), vulns: (.value | vulns) } ),
    ( (.themes // {}) | to_entries[]
      | { name: ("theme:" + .key), ver: (.value | ver), vulns: (.value | vulns) } )
  ]
	| map(select((.vulns | length) > 0))
	| map(. as $i | $i.vulns[] | { component: $i.name, ver: $i.ver, title: (.title // "unknown") })
	| .[]
	| [ (if (.ver == null or .ver == "") then "unconfirmed" else "confirmed" end),
      .component, (.ver // "version-not-detected"), .title ]
	| @tsv
'

if command -v jq >/dev/null 2>&1; then
    findings="$(jq -r "$JQ_FILTER" "$REPORT_FILE")"
elif command -v python3 >/dev/null 2>&1; then
    findings="$(python3 - "$REPORT_FILE" <<'PY'
import json, sys

data = json.load(open(sys.argv[1]))
rows = []

def ver(v):
  return v.get("number") if isinstance(v, dict) else v

def clean(s):
  return str(s).replace("\t","").replace("\n","")

def emit(name, version, vulns):
  for x in (vulns or []):
    kind = "unconfirmed" if version in (None, "") else "confirmed"
    rows.append("\t".join([kind, name, version or "version-not-detected", clean(x.get("title", "unknown"))]))

core = data.get("version")
if core:
  emit("wordpress-core", core.get("number"), core.get("vulnerabilities"))
mt = data.get("main_theme")
if mt:
  emit("theme:" + (mt.get("slug") or "main"), ver(mt.get("version")), mt.get("vulnerabilities"))
for group, prefix in (("plugins", "plugin:"),("themes", "theme:")):
	for slug, obj in (data.get(group) or {}).items():
		emit(prefix + slug, ver(obj.get("version")), obj.get("vulnerabilities"))
print("\n".join(rows))
PY
)"
else
  echo "ERROR: neither jq nor python3 is available to analyze $REPORT_FILE"
	exit 1
fi

confirmed="$(printf '%s\n' "$findings" | awk -F'\t' '$1=="confirmed"{c++} END{print c+0}')"
unconfirmed="$(printf '%s\n' "$findings" | awk -F'\t' '$1=="unconfirmed"{c++} END{print c+0}')"

if [ "$confirmed" -gt 0 ]; then
	echo "ERROR: confirmed vulnerabilities detected."
	printf '%s\n' "$findings" | awk -F'\t' '$1=="confirmed"{printf " - %s (version %s): %s\n", $2, $3, $4}'
  echo "Report: test/reports/wpscan-report.json"
	exit 5
fi

if [ "$unconfirmed" -gt 0 ]; then
  echo "WARNING: $unconfirmed finding(s) on components whose version could not be detected."
	echo "WPScan assumes the worst case for such components; nothing is confirmed -> non-fatal"
	printf '%s\n' "$findings" | awk -F'\t' '$1=="unconfirmed"{printf " - %s: %s\n", $2, $4}'
fi

echo "==========================
WPScan summary
==========================
Target: http://wordpress
Report: test/reports/wpscan-report.json
WPScan exit code: $scan_status
Confirmed vulnerabilities: $confirmed
Unconfirmed findings: $unconfirmed
Status: completed"

exit 0
