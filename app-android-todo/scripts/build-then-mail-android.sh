#!/usr/bin/env bash
set -euo pipefail

: "${TARGET_EMAIL:=kingjjy.game@gmail.com}"
: "${GOG_ACCOUNT:=$TARGET_EMAIL}"
: "${BUILD_PROFILE:=preview}"
: "${PLATFORM:=android}"
: "${PROJECT_DIR:=/home/kingjjy_game/.openclaw/workspace/app-android-todo}"
: "${POLL_INTERVAL:=20}"

if [[ -z "${EXPO_TOKEN:-}" ]]; then
  echo "[ERR] EXPO_TOKEN is not set."
  echo "Set it first: export EXPO_TOKEN=your_expo_programmatic_token"
  exit 1
fi

cd "$PROJECT_DIR"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

log "[1/5] Start EAS build (no-wait)"
BUILD_START="$(EXPO_TOKEN="$EXPO_TOKEN" npx eas-cli build -p "$PLATFORM" -e "$BUILD_PROFILE" --json --non-interactive --no-wait)"
BUILD_START_FILE="/tmp/eas-build-start-$$.json"
printf '%s' "$BUILD_START" > "$BUILD_START_FILE"

BUILD_ID=$(python3 - <<PY "$BUILD_START_FILE"
import json,sys
p=sys.argv[1]
text=open(p).read()
# pick last JSON object in output
start=text.rfind('{')
obj=json.loads(text[start:])
print(obj.get('id') or obj.get('buildId') or '')
PY
)

if [[ -z "$BUILD_ID" ]]; then
  echo "[ERR] Build id not parsed"
  echo "$BUILD_START"
  exit 1
fi

log "build started: $BUILD_ID"

while true; do
  BUILD_VIEW="$(EXPO_TOKEN="$EXPO_TOKEN" npx eas-cli build:view "$BUILD_ID" --json)"
  BUILD_VIEW_FILE="/tmp/eas-build-view-$$.json"
  printf '%s' "$BUILD_VIEW" > "$BUILD_VIEW_FILE"

  read -r BUILD_STATUS BUILD_PAGE ARTIFACT_URL < <(python3 - <<PY "$BUILD_VIEW_FILE"
import json,sys
p=sys.argv[1]
obj=json.loads(open(p).read())
status = obj.get('status') or obj.get('build',{}).get('status','')
page = obj.get('url') or obj.get('build',{}).get('url','')
artifact = ''
if isinstance(obj.get('artifactUrl'), str):
    artifact = obj['artifactUrl']
elif isinstance(obj.get('artifacts'), dict):
    for k in ['applicationArchiveUrl','archiveUrl','url','buildUrl']:
        if isinstance(obj['artifacts'].get(k), str):
            artifact = obj['artifacts'][k]
            break
elif isinstance(obj.get('build'), dict):
    b=obj['build']
    if isinstance(b.get('artifacts'), dict):
        for k in ['applicationArchiveUrl','archiveUrl','url','buildUrl']:
            if isinstance(b['artifacts'].get(k), str):
                artifact = b['artifacts'][k]
                break
    if not artifact and isinstance(b.get('url'), str):
        artifact = b.get('url')
print(status)
print(page)
print(artifact)
PY
)

  log "status=$BUILD_STATUS"
  [[ -n "$BUILD_PAGE" ]] && log "build page: $BUILD_PAGE"

  if [[ "$BUILD_STATUS" == "finished" ]]; then
    break
  fi
  if [[ "$BUILD_STATUS" == "errored" || "$BUILD_STATUS" == "canceled" ]]; then
    echo "[ERR] build failed: $BUILD_STATUS"
    echo "$BUILD_VIEW"
    exit 1
  fi
  sleep "$POLL_INTERVAL"
done

log "[3/5] Build finished"

mkdir -p "$PROJECT_DIR/dist"
APK_PATH=""
if [[ -n "$ARTIFACT_URL" && "$ARTIFACT_URL" == *.apk* ]]; then
  APK_PATH="$PROJECT_DIR/dist/openclaw-todo-${BUILD_PROFILE}-${BUILD_ID}.apk"
  log "[4/5] Downloading artifact: $APK_PATH"
  wget -q -O "$APK_PATH" "$ARTIFACT_URL"
else
  log "[WARN] artifact URL not directly usable"
fi

if [[ -n "$APK_PATH" && -f "$APK_PATH" ]]; then
  log "[5/5] Sending APK attached to $TARGET_EMAIL"
  BODY=$'안드로이드 테스트 APK가 빌드 완료되어 첨부합니다.\n\n빌드ID: '
  BODY+="$BUILD_ID\n빌드 페이지: $BUILD_PAGE"
  GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-}" \
    gog gmail send --account "$GOG_ACCOUNT" --to="$TARGET_EMAIL" --subject="[Android Test] OpenClaw Todo APK 완료" --body "$BODY" --attach="$APK_PATH" --force
else
  log "[5/5] Sending completion notice only"
  BODY=$'안드로이드 테스트 빌드가 완료되었습니다.\n\n빌드ID: '
  BODY+="$BUILD_ID\n빌드 페이지: $BUILD_PAGE\n\napk 직접 첨부 링크를 아래에서 받으실 수 있습니다."
  GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-}" \
    gog gmail send --account "$GOG_ACCOUNT" --to="$TARGET_EMAIL" --subject="[Android Test] OpenClaw Todo 빌드 완료" --body "$BODY" --force
fi

log "Done"
