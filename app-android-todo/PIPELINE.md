# 앱 개발 자동화 파이프라인 (요구사항 반영)

## 1) 기획/요구사항 정리
- 매 작업 시작 전 `요구사항`을 아래 5개로 정리
  - 목표/성과 지표
  - 제약 조건
  - 승인 기준(Definition of Done)
  - 리스크
  - 롤백 기준
- 실행 예시: 오늘자 핵심 기획 = 앱 동작 범위, 설치 방식, 검증 기준(부팅/기본 화면)

## 2) 코딩
- 기능 단위 PR/커밋
- 각 기능은 단일 실행 액션(완료/검증 가능) 기준으로 나눔

## 3) GitHub Action 빌드
- 워크플로우: `.github/workflows/android-apk.yml`
- 트리거: `workflow_dispatch` 또는 `master` push
- 아티팩트: `openclaw-todo-debug-apk`

### 3-1) 결과 polling + 실패 시 디버깅/재시도
- 오케스트레이터: `scripts/ci_build_and_deliver.py`
- 동작:
  1. `workflow_dispatch` 디스패치
  2. run 상태 polling
  3. 실패하면 `실패 step`를 로그로 추출 후 즉시 재시도

### 3-2) 결과 polling + success 시 검증
- 아티팩트 `.apk` 내려받기
- 크기/매니페스트 검증
- `adb` 장비가 있으면 install/패키지 확인

## 4) 전달
- 성공 검증 후 `gog gmail send`로
  `kingjjy.game@gmail.com`으로 APK 첨부 전송
- `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID` 설정 시 텔레그램 알림 발송

## 5) 5분 정체 대응
- 오케스트레이터에서 `queued/in_progress` 상태가 300초 이상 업데이트 없는 경우
  자동으로 타임아웃 판단 후 해당 run 취소 + 즉시 재시도

## 실행 명령
```bash
cd /home/kingjjy_game/.openclaw/workspace
python3 scripts/check_delivery_env.py
python3 scripts/ci_build_and_deliver.py
# 또는
bash scripts/run_app_delivery_pipeline.sh
```
