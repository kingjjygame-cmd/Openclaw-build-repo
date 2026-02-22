# OpenClaw Android TODO 앱 (시연 빌드)

안드로이드에서 바로 돌아가는 Expo 앱입니다. 현재는 **테스트 배포(Preview) APK 자동생성 + 완료 메일 전송**까지 준비되어 있습니다.

---
## 1) 바로 실행 (로컬)
```bash
cd /home/kingjjy_game/.openclaw/workspace/app-android-todo
npm install
npm run android
```

## 2) 테스트 배포(Preview APK) 자동화
아래는 `kingjjy.game@gmail.com`로 빌드 완료 메일을 보내는 자동 스크립트입니다.

### 2-1) Expo EAS 토큰 준비
1. https://expo.dev/settings/access-tokens 에서 **Access Token** 생성
2. 쉘에 한 번 세팅
```bash
export EXPO_TOKEN=<생성한 토큰>
```

### 2-2) 실행
```bash
cd /home/kingjjy_game/.openclaw/workspace/app-android-todo
./scripts/build-then-mail-android.sh
```

기본 수신: `TARGET_EMAIL`(기본값: `kingjjy.game@gmail.com`)

```bash
TARGET_EMAIL="본인주소" ./scripts/build-then-mail-android.sh
```

### 동작
1. EAS Preview 빌드 시작
2. 빌드 완료까지 폴링
3. APK가 직접 추출 가능하면 다운로드
4. `gog send`로 `kingjjy.game@gmail.com`로 메일 전송

---
## 3) 배포 체크리스트
- 앱 이름: OpenClaw Todo
- 패키지명: `com.moka.openclawtodo`
- Android 8+ 권장
- 민감 정보 없음 (현재는 로컬 상태 기반 샘플 앱)

## 4) 현재 구현 기능
- 할일 추가(우선순위/마감일)
- 완료/미완료 토글
- 검색 + 미완료 필터
- 마감일 초과 경고
- 삭제

## 5) 다음 단계
원하면 여기서 바로 이어서
- 앱 아이콘/스플래시 교체
- 로컬 DB(SQLite/WatermelonDB) 영구저장
- 푸시 알림 리마인더
- Google/카카오 로그인
- Play Store 업로드용 AAB
