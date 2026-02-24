#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPO:=kingjjygame-cmd/Openclaw-build-repo}"
: "${GITHUB_REF:=master}"
: "${DELIVERY_EMAIL:=kingjjy.game@gmail.com}"

export GITHUB_REPO
export GITHUB_REF
export DELIVERY_EMAIL

echo "[pipeline] delivery env check"
python3 /home/kingjjy_game/.openclaw/workspace/scripts/check_delivery_env.py

echo "[pipeline] start retry pipeline"
python3 /home/kingjjy_game/.openclaw/workspace/scripts/ci_build_and_deliver.py
