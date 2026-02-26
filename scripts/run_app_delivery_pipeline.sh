#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/home/kingjjy_game/.openclaw/workspace"
if [ -f "$WORKDIR/.delivery.env" ]; then
  # Allow KEY=VALUE (non-export) and VALUE-only env lines in .delivery.env
  set -a
  # shellcheck disable=SC1090
  source "$WORKDIR/.delivery.env"
  set +a
fi

: "${GITHUB_REPO:=kingjjygame-cmd/Openclaw-build-repo}"
: "${GITHUB_REF:=master}"
: "${DELIVERY_EMAIL:=kingjjy.game@gmail.com}"

export GITHUB_REPO
export GITHUB_REF
export DELIVERY_EMAIL

export OPEN_CLAW_DELIVERY_REPORT_PATH="/tmp/openclaw_delivery_report.json"
export OPEN_CLAW_DELIVERY_REPORT_READY="/tmp/openclaw_delivery_report.ready"
export OPEN_CLAW_DELIVERY_REPORT_LATEST="/tmp/openclaw_delivery_report.latest.json"

report_done() {
  if [ -f "$OPEN_CLAW_DELIVERY_REPORT_PATH" ]; then
    cp "$OPEN_CLAW_DELIVERY_REPORT_PATH" "$OPEN_CLAW_DELIVERY_REPORT_LATEST"
    rm -f "$OPEN_CLAW_DELIVERY_REPORT_READY"
    touch "$OPEN_CLAW_DELIVERY_REPORT_READY"
    python3 - <<'PY'
import json
from pathlib import Path
path = Path('/tmp/openclaw_delivery_report.json')
try:
    data = json.loads(path.read_text())
except Exception:
    print('[pipeline] delivery report parse failed')
else:
    print('[pipeline] delivery final')
    print(f"[pipeline] status={data.get('status')} run_id={data.get('run_id')} attempt={data.get('attempt')}")
    if data.get('run_url'):
        print(f"[pipeline] run_url={data.get('run_url')}")
    if data.get('artifact_id'):
        print(f"[pipeline] artifact_id={data.get('artifact_id')}")
    if data.get('browser_link'):
        print(f"[pipeline] browser_link={data.get('browser_link')}")
    if data.get('direct_link'):
        print(f"[pipeline] direct_link={data.get('direct_link')}")
    if data.get('size') is not None:
        print(f"[pipeline] size={data.get('size')}")
    if data.get('sha256'):
        print(f"[pipeline] sha256={data.get('sha256')}")
PY
  else
    echo '[pipeline] delivery report 없음'
    rm -f "$OPEN_CLAW_DELIVERY_REPORT_LATEST"
    cat > "$OPEN_CLAW_DELIVERY_REPORT_READY" <<'EOF'
{"status":"missing_report"}
EOF
  fi
}

on_exit() {
  report_done
}
trap on_exit EXIT

rm -f "$OPEN_CLAW_DELIVERY_REPORT_READY"

echo "[pipeline] delivery env check"
if [ "${SKIP_GOG_CHECK:-false}" != "true" ]; then
  python3 "$WORKDIR/scripts/check_delivery_env.py"
fi

echo "[pipeline] start retry pipeline"
python3 -u "$WORKDIR/scripts/ci_build_and_deliver.py"