# Mission Control (Next.js 운영용) 초기 설정/실행 가이드

준영님의 환경에서 바로 쓰는 **로컬 미션 컨트롤 대시보드**입니다.

## 1) 환경 재설정(초기화) 실행 순서

### 0. 디렉터리 이동
```bash
cd /home/kingjjy_game/.openclaw/workspace/mission-control
```

### 1. 기존 실행 정리 (선택)
```bash
# 실행 중이면 터미널에서 Ctrl+C
# 또는 기존 프로세스 종료 후
```

### 2. 의존성 재설치 (클린 재설치)
```bash
rm -rf node_modules package-lock.json
npm install
```

### 3. 타입/빌드 검증
```bash
npm run build
```

### 4. 로컬 실행
```bash
npm run dev
```

- 브라우저: http://localhost:3000

### 5. 운영 모드 실행(운영 테스트 시)
```bash
npm run build
npm run start
```
`start`는 `next start`로 기본 **3000번 포트**에서 정적 빌드 결과를 서빙합니다.

## 2) 데이터 저장 방식 (운영 포인트)
- 현재 미션 데이터는 브라우저 `localStorage`(`mission-control:data:v1`)에 저장됩니다.
- 브라우저 캐시/스토리지를 지우면 데이터가 초기화됩니다.
- 앱 안의 **"로컬 데이터 초기화"** 버튼은 동일 키를 삭제하고 기본 샘플 데이터로 되돌립니다.

## 3) 운영용 사용법
- 미션 등록: 상단 폼에서 제목/목표/마감일/우선순위 입력 후 등록
- 상태 전환: 각 카드의 드롭다운(진행중/완료/지연/대기)
- 체크리스트: 항목 체크 시 자동으로 진행률 반영
- 진행률 조정: 슬라이더로 수동 조정 가능(체크리스트 반영과 독립)
- 오늘 메모: 오늘 한 줄을 입력 후 `메모 저장`
- 백업/복구: 브라우저 콘솔에서 `localStorage.getItem('mission-control:data:v1')` 로 JSON 추출 가능

## 4) 운영 확장 포인트
- 사용자 계정별 분리: localStorage 키를 `mission-control:data:v1-<user>`로 분리
- 외부 DB 연동: Supabase/Firestore로 바꾸면 멀티 디바이스 동기화 가능
- 인증 추가: 사내 운영면은 NextAuth 또는 미들웨어 인증 미들웨어 추가 권장

## 5) 기본 체크리스트
- [ ] `npm run build` 통과
- [ ] `npm run dev` 접속 가능
- [ ] 미션 추가/삭제/체크리스트 동작 확인
- [ ] 데이터 저장 후 새로고침해도 유지 확인
- [ ] `로컬 데이터 초기화`가 원치 않는 경우 확인(운영 모드에서는 권한 분리 추가 권고)
