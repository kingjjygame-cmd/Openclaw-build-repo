#!/usr/bin/env bash
set -euo pipefail

# Free-friendly Android test workflow (no EAS billing required):
# 1) Install deps
# 2) Run Expo Go-compatible development server
# 3) Optionally print QR and deep-link steps

cd "/home/kingjjy_game/.openclaw/workspace/app-android-todo"

if [[ ! -d node_modules ]]; then
  echo "[INFO] node_modules 없어서 npm install 실행합니다."
  npm install
fi

echo "[INFO] Expo 개발 서버(무료) 시작"
echo "- Android 기기(Expo Go 앱)에서 아래 QR로 연결하세요"

echo "- 만약 Expo CLI가 오래전 버전이면 업그레이드 알림이 뜰 수 있습니다."

echo "- 실행 완료 후 로그에서 QR 코드/URL로 접속합니다."

echo ""
npx expo start
