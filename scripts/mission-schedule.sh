#!/usr/bin/env bash
set -euo pipefail

: "${1:?Usage: $0 <morning|afternoon|night>}"
SESSION_DIR="/home/kingjjy_game/.openclaw/workspace"
LOG_FILE="$SESSION_DIR/memory/mission-schedule.log"
TODAY=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M:%S')
MODE="$1"

append_log() {
  mkdir -p "$SESSION_DIR/memory"
  printf "[%s %s] %s\n" "$TODAY" "$TIME" "$1" >> "$LOG_FILE"
}

case "$MODE" in
  morning)
    append_log "[아침] 완료한 일 1개라도 오늘 한 번은 반드시 축하. 미션 컨트롤 핵심 3개만 점검: 앱/자동화, 재무/투자, Hebbal 전환."
    ;;
  afternoon)
    append_log "[오후] 미션 컨트롤에서 체크리스트 1개 이상 진행 + 실행 단위 1건 완료. 불완료는 내일 1개로만 축소."
    ;;
  night)
    append_log "[밤] 하루 마감: 오늘 완료 미션 적어도 1개 기록, 내일 첫 1개 액션 1개만 남겨둠. 백업/스냅샷 점검."
    ;;
  *)
    append_log "[오류] 잘못된 모드: $MODE (morning/afternoon/night)"
    ;;
esac

append_log "[상태] 미션 스테이트먼트 근접도 점검 준비 완료"
