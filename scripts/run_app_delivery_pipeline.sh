#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/home/kingjjy_game/.openclaw/workspace"
if [ -f "$WORKDIR/.delivery.env" ]; then
  # shellcheck disable=SC1090
  source "$WORKDIR/.delivery.env"
fi


: "${GITHUB_REPO:=kingjjygame-cmd/Openclaw-build-repo}"
: "${GITHUB_REF:=master}"
: "${DELIVERY_EMAIL:=kingjjy.game@gmail.com}"

export GITHUB_REPO
export GITHUB_REF
export DELIVERY_EMAIL

echo "[pipeline] delivery env check"
if [ "${SKIP_GOG_CHECK:-false}" != "true" ]; then
  python3 /home/kingjjy_game/.openclaw/workspace/scripts/check_delivery_env.py
fi

echo "[pipeline] start retry pipeline"
python3 /home/kingjjy_game/.openclaw/workspace/scripts/ci_build_and_deliver.py
