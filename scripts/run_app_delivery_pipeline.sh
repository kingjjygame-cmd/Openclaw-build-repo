#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/home/kingjjy_game/.openclaw/workspace"

# Preserve explicit env values before loading .delivery.env (which may contain placeholders)
ORIG_GITHUB_TOKEN="${GITHUB_TOKEN-__OPENCLAW_ORIG__}"
ORIG_GOG_ACCOUNT="${GOG_ACCOUNT-__OPENCLAW_ORIG__}"
ORIG_GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD-__OPENCLAW_ORIG__}"
ORIG_TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN-__OPENCLAW_ORIG__}"
ORIG_TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID-__OPENCLAW_ORIG__}"
ORIG_GITHUB_REPO="${GITHUB_REPO-__OPENCLAW_ORIG__}"
ORIG_GITHUB_REF="${GITHUB_REF-__OPENCLAW_ORIG__}"
ORIG_DELIVERY_EMAIL="${DELIVERY_EMAIL-__OPENCLAW_ORIG__}"
ORIG_ONE_SHOT="${ONE_SHOT-__OPENCLAW_ORIG__}"
ORIG_MAX_RETRIES="${MAX_RETRIES-__OPENCLAW_ORIG__}"
ORIG_SEND_MAIL="${SEND_MAIL-__OPENCLAW_ORIG__}"

if [ -f "$WORKDIR/.delivery.env" ]; then
  # shellcheck disable=SC1090
  source "$WORKDIR/.delivery.env"
fi

restore_if_needed() {
  local var_name="$1"
  local orig_value="${2}"
  if [ "$orig_value" != "__OPENCLAW_ORIG__" ] && [ -z "${!var_name-}" ]; then
    printf -v "$var_name" '%s' "$orig_value"
    export "$var_name"
  fi
}

restore_if_needed GITHUB_TOKEN "$ORIG_GITHUB_TOKEN"
restore_if_needed GOG_ACCOUNT "$ORIG_GOG_ACCOUNT"
restore_if_needed GOG_KEYRING_PASSWORD "$ORIG_GOG_KEYRING_PASSWORD"
restore_if_needed TELEGRAM_BOT_TOKEN "$ORIG_TELEGRAM_BOT_TOKEN"
restore_if_needed TELEGRAM_CHAT_ID "$ORIG_TELEGRAM_CHAT_ID"
restore_if_needed GITHUB_REPO "$ORIG_GITHUB_REPO"
restore_if_needed GITHUB_REF "$ORIG_GITHUB_REF"
restore_if_needed DELIVERY_EMAIL "$ORIG_DELIVERY_EMAIL"
restore_if_needed ONE_SHOT "$ORIG_ONE_SHOT"
restore_if_needed MAX_RETRIES "$ORIG_MAX_RETRIES"
restore_if_needed SEND_MAIL "$ORIG_SEND_MAIL"

unset ORIG_GITHUB_TOKEN ORIG_GOG_ACCOUNT ORIG_GOG_KEYRING_PASSWORD ORIG_TELEGRAM_BOT_TOKEN ORIG_TELEGRAM_CHAT_ID ORIG_GITHUB_REPO ORIG_GITHUB_REF ORIG_DELIVERY_EMAIL ORIG_ONE_SHOT ORIG_MAX_RETRIES ORIG_SEND_MAIL

: "${GITHUB_REPO:=kingjjygame-cmd/Openclaw-build-repo}"
: "${GITHUB_REF:=master}"
: "${DELIVERY_EMAIL:=kingjjy.game@gmail.com}"
: "${ONE_SHOT:=0}"
: "${MAX_RETRIES:=0}"
: "${SEND_MAIL:=0}"

export GITHUB_REPO GITHUB_REF DELIVERY_EMAIL ONE_SHOT MAX_RETRIES SEND_MAIL
if [ -n "${GITHUB_TOKEN-}" ]; then
  export GITHUB_TOKEN
fi
if [ -n "${GOG_ACCOUNT-}" ]; then
  export GOG_ACCOUNT
fi
if [ -n "${GOG_KEYRING_PASSWORD-}" ]; then
  export GOG_KEYRING_PASSWORD
fi
if [ -n "${TELEGRAM_BOT_TOKEN-}" ]; then
  export TELEGRAM_BOT_TOKEN
fi
if [ -n "${TELEGRAM_CHAT_ID-}" ]; then
  export TELEGRAM_CHAT_ID
fi

echo "[pipeline] delivery env check"
python3 /home/kingjjy_game/.openclaw/workspace/scripts/check_delivery_env.py

echo "[pipeline] start retry pipeline"
python3 /home/kingjjy_game/.openclaw/workspace/scripts/ci_build_and_deliver.py
