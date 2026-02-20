---
name: noapi-google-search-mcp
description: Assist with enabling Google search-like workflows without Brave API key by evaluating MCP/구성 대체 경로, 링크 기반 설정 체크리스트, 에러 트러블슈팅, and fallback plan.
user-invocable: true
metadata: { "openclaw": { "emoji": "🔎", "homepage": "https://discuss.pytorch.kr/t/noapi-google-search-mcp-google-search-api-key-mcp/8968" } }
---

# noapi-google-search-mcp

## Purpose
- Help user configure/search with MCP options discussed in the linked thread when Brave API key is not used.
- Diagnose search failures quickly (configuration, client/server mismatch, env var, network, tool compatibility).

## Trigger
Use this skill when user asks:
- "noapi-google-search-mcp"
- 링크 `discuss.pytorch.kr/t/noapi-google-search-mcp-google-search-api-key-mcp/8968`
- Brave API 없이 구글 검색/웹 검색 대체 방식을 묻는 경우

## Procedure
1. Confirm goal
   - 원한 동작: CLI 검색인지, MCP 도구 검색인지, 웹 요약인지
   - 사용 환경: OS, Node/Python 버전, MCP 클라이언트(`cline`, `cursor`, custom)
2. Gather current setup (ask or inspect manually)
   - MCP 서버 바이너리 이름/버전
   - MCP 설정 파일 위치 및 실행 명령
   - 관련 env (예: GOOGLE_API_KEY 계열, SERP/스크랩핑 엔드포인트, 프록시)
   - 네트워크 정책(방화벽/프록시/출구 정책)
3. Validate required components
   - MCP가 실행 가능한지 (`--help` 또는 버전 확인)
   - 클라이언트가 해당 서버를 로드하는지
   - 서버가 구독 중인 도메인 접근 가능한지
4. Provide troubleshooting
   - “설정 즉시 점검” 5-step 체크리스트를 짧게 제공
   - 에러 로그의 핵심 라인 추출해 문제 가설 2~3개 제시
5. If no reliable claim is verifiable, mark as hypothesis and request user confirmation.

## Output format
- 한 번에 적용할 수 있는 순서로:
  1) 결론
  2) 근거
  3) 바로 할 일 1~3
  4) 추가 확인 사항

## Safety
- Never claim unsupported/legal-risky bypass behaviors as guaranteed.
- Never expose secrets (API keys, tokens, session cookies) in clear text.
- Prefer legal/official endpoint-first guidance; report when behavior may violate service terms.
