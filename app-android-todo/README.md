# OpenClaw Android TODO 앱 (시연 빌드)

안드로이드에서 바로 돌아가는 Expo 앱입니다. 지금은 로컬 테스트/배포용으로 바로 실행 가능한 상태입니다.

## 1) 실행(빠른 테스트)
```bash
cd /home/kingjjy_game/.openclaw/workspace/app-android-todo
npm install
npm run android
```

- Android 에뮬레이터 또는 USB 디버깅 기기가 필요합니다.
- 또는 Expo Go로 실행해 기능 확인 가능합니다.

## 2) APK 빌드(실배포)
EAS 빌드는 클라우드에서 APK를 생성합니다.

```bash
cd /home/kingjjy_game/.openclaw/workspace/app-android-todo
npx expo login
npx eas-cli login
npx eas-cli build:configure
npm run build:preview-apk
```

빌드가 끝나면 나오는 APK 링크를 받아 휴대폰에 설치하면 됩니다.

> EAS 계정이 없으면 회원가입 후 로그인 필요

## 3) 배포 체크리스트
- 앱 이름: OpenClaw Todo
- 패키지명: `com.moka.openclawtodo`
- 권장 최소 Android 8+
- 저장소에 민감정보 없음 (현재 앱은 로컬 상태만 사용)

## 4) 현재 구현 기능
- 할일 추가(우선순위/마감일)
- 완료/미완료 토글
- 검색 + 미완료 필터
- 마감일 초과 표시
- 삭제

## 5) 다음 단계(원하면 바로 해드릴 수 있음)
- 푸시 알림 리마인더
- 로컬 DB(Room/SQLite) 영구 저장
- Google/카카오 로그인 연동
- Google Play 출시용 AAB 빌드
