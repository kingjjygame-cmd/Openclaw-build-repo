# OpenClaw Android TODO 앱 (시연 빌드)

안드로이드에서 바로 돌아가는 Expo 앱입니다. 현재는 **테스트 배포(Preview) APK 자동생성 + 완료 메일 전송**까지 준비되어 있습니다.

---
## 1) 바로 실행 (로컬)
```bash
cd /home/kingjjy_game/.openclaw/workspace/app-android-todo
npm install
npm run android
```

---
## 2) 무료 테스트 환경 (권장: 가장 빠름)
EAS 인증 토큰/빌드 계정이 없어도, **Expo Go**로 즉시 테스트 가능해요. 

```bash
cd /home/kingjjy_game/.openclaw/workspace/app-android-todo
./scripts/free-env-start.sh
```

실행 중 화면에 뜨는 QR/URL로 휴대폰의 **Expo Go**에 접속하면 앱을 바로 테스트할 수 있습니다.

장점:
- 별도 인증/빌드 계정 불필요
- 즉시 실행(로컬 테스트)
- APK 파일 생성 없이도 동작 확인 가능

주의:
- Expo Go에서는 제한적 네이티브 기능(푸시, 특정 네이티브 모듈) 검증이 어려울 수 있음.

---
## 3) GitHub Actions로 APK 빌드 (권장)
이 방법은 로컬에서 `npm run free-env` 없이 GitHub에서 바로 APK를 생성합니다.

### 3-1) 워크플로우 개요
- `master` 브랜치 push 또는 수동 실행 시 `app-android-todo` 기준 빌드 실행
- `android/app/build/outputs/apk/debug/app-debug.apk` 생성
- GitHub Artifacts로 파일 보관 (30일)

### 3-2) 실행 방법
1. GitHub 저장소에 소스 push
2. Actions 탭 → **Android APK Build (GitHub Actions)** 실행
3. 완료 후 Artifacts에서 `openclaw-todo-debug-apk` 다운로드

장점:
- APK 파일 생성
- 별도 `EXPO_TOKEN` 불필요
- 로컬 환경이 없어도 빌드 가능

주의:
- 기본은 Debug APK(`assembleDebug`)이므로 배포용 서명(AAB)은 별도 설정 필요.

---
## 4) 테스트 배포(Preview APK) 자동화
아래는 `kingjjy.game@gmail.com`로 빌드 완료 메일을 보내는 자동 스크립트입니다.

### 4-1) Expo EAS 토큰 준비
1. https://expo.dev/settings/access-tokens 에서 **Access Token** 생성
2. 쉘에 한 번 세팅
```bash
export EXPO_TOKEN=<생성한 토큰>
```

### 4-2) 실행
```bash
cd /home/kingjjy_game/.openclaw/workspace/app-android-todo
./scripts/build-then-mail-android.sh
# 또는
npm run deploy:test
```

기본 수신: `TARGET_EMAIL`(기본값: `kingjjy.game@gmail.com`)

```bash
TARGET_EMAIL="본인주소" ./scripts/build-then-mail-android.sh
```

동작:
1. EAS Preview 빌드 시작
2. 빌드 완료까지 폴링
3. APK가 직접 추출 가능하면 다운로드
4. `gog send`로 `kingjjy.game@gmail.com`로 메일 전송

---
## 5) 배포 방식 비교
- 무료 경로(추천): `free-env-start.sh` + Expo Go 실행
- GitHub Actions: `Debug APK` 자동 생성 + Artifact 배포
- 빠른 실제 설치 체험: EAS preview 빌드 (`npm run deploy:test`)

---
## 6) 배포 체크리스트
- 앱 이름: OpenClaw Todo
- 패키지명: `com.moka.openclawtodo`
- Android 8+ 권장
- 민감 정보 없음 (현재는 로컬 상태 기반 샘플 앱)

## 7) 현재 구현 기능
- 할일 추가(우선순위/마감일)
- 완료/미완료 토글
- 검색 + 미완료 필터
- 마감일 초과 경고
- 삭제

## 8) 다음 단계
원하면 여기서 바로
- 앱 아이콘/스플래시 교체
- 로컬 DB(SQLite/WatermelonDB) 영구저장
- 푸시 알림 리마인더
- Google/카카오 로그인
- Play Store 업로드용 AAB