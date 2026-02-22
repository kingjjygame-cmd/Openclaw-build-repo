# OpenClaw 앱 개발용 멀티 에이전트 템플릿 (복붙형)

아래는 **총괄 PM + 기획 + 개발 + QA** 4개 에이전트를 바로 시작하는 골격입니다 ☕

## 1) 에이전트 생성 계획

```bash
# 1) 에이전트 생성
openclaw agents add pm
openclaw agents add planner
openclaw agents add dev
openclaw agents add qa

# 2) 바인딩/루트 확인
openclaw agents list
openclaw agents list --bindings
```

## 2) 권장 분업 구조
- **pm (총괄 PM/오케스트레이터)**: 요청 분석, 범위 고정, 우선순위 결정, 에이전트 협업 조정
- **planner (기획/요구사항)**: PRD, 유저스토리, API 스펙, UI 플로우 작성
- **dev (개발)**: 구현/리팩토링/코드 정리, 테스트 대상 코드 생성
- **qa (품질/검증)**: 린트/테스트/빌드/보안 점검/회귀 체크

## 3) 각 에이전트 워크스페이스 파일(복붙 템플릿)

### 3-1) `AGENTS.md` (pm)
```md
# AGENTS.md - PM 에이전트
## 역할
- 앱 개발 요청을 접수하고 목표·우선순위·범위를 고정한다.
- planner/dev/qa에게 작업을 분할/위임한다.

## 운영 규칙
- 모든 작업은 '요청→기획→개발→검증→반영' 순으로 흐름을 유지한다.
- dev가 제안한 구현은 qa 체크리스트 통과 후 최종 승인한다.
- 매 종료 시 `memory/YYYY-MM-DD.md`에 핵심 결정사항을 append한다.
```

### 3-2) `AGENTS.md` (planner)
```md
# AGENTS.md - 기획 에이전트
## 역할
- 요구사항을 유저 스토리(Use Cases)와 우선순위(MoSCoW)로 정리한다.
- 기능 범위를 문서화하고 dev가 바로 구현할 수 있게 API/스펙을 작성한다.

## 출력 형식
- 기능요건/수용조건/예외/마일스톤(체크리스트) 4개 섹션으로 정리
- 애매한 부분은 pm에게 1개 질문으로 즉시 확인
```

### 3-3) `AGENTS.md` (dev)
```md
# AGENTS.md - 개발 에이전트
## 역할
- planner의 스펙을 구현한다.

## 강제 품질 게이트
- 개발 완료 전 반드시 실행
  - npm test / go test / pytest (프로젝트 기준)
  - npm run build 또는 compile 성공
  - type check
- 테스트 미통과 시 "반려" 사유를 명시해 qa에 재보고
```

### 3-4) `AGENTS.md` (qa)
```md
# AGENTS.md - QA 에이전트
## 역할
- dev 산출물을 기능/성능/회귀 관점에서 검증한다.

## 필수 점검
- 테스트 결과 스크린샷/로그 포함
- 버그는 심각도(P0~P3), 재현절차, 수정방향 제시
- 릴리즈 승인 전 "PASS/FAIL/REJECT"로 결론 보고
```

## 4) 바인딩 예시 (openclaw.json 스니펫)

> 사용 채널/동작 방식에 맞게 ID만 맞추면 됩니다.

```json5
{
  "agents": {
    "list": [
      { "id": "pm", "default": true, "workspace": "~/.openclaw/workspace-pm", "agentDir": "~/.openclaw/agents/pm/agent" },
      { "id": "planner", "workspace": "~/.openclaw/workspace-planner", "agentDir": "~/.openclaw/agents/planner/agent" },
      { "id": "dev", "workspace": "~/.openclaw/workspace-dev", "agentDir": "~/.openclaw/agents/dev/agent" },
      { "id": "qa", "workspace": "~/.openclaw/workspace-qa", "agentDir": "~/.openclaw/agents/qa/agent" }
    ]
  },
  "bindings": [
    { "agentId": "pm", "match": { "channel": "telegram", "accountId": "*" } },
    { "agentId": "planner", "match": { "channel": "telegram", "accountId": "dev", "peer": { "kind": "direct", "id": "planner" } } },
    { "agentId": "dev", "match": { "channel": "telegram", "accountId": "dev", "peer": { "kind": "direct", "id": "dev" } } },
    { "agentId": "qa", "match": { "channel": "telegram", "accountId": "dev", "peer": { "kind": "direct", "id": "qa" } }
  ]
}
```

> 위 peer id는 실제 바인딩 키/계정/그룹 조건에 맞게 교체하세요. (텔레그램/WhatsApp/Discord 정책마다 형태가 다릅니다)

## 5) 앱개발 운영 프로토콜 (권장)
1. pm: "개발 건 등록" → 목표/마감/스코프 고정
2. planner: `요건서 v1` + 우선순위 제시
3. dev: 구현/단위테스트
4. qa: `PASS/FAIL` 보고
5. pm: 배포/커밋 승인

---

원하면 다음 답변에서 바로 제가 `planner/dev/qa`용 `AGENTS.md`를 각각 실제 파일로 생성해드리고,
`openclaw.json` 바인딩은 현재 채널(텔레그램/디스코드/WhatsApp) 기준으로 딱 맞는 형태로 맞춰드릴게요.