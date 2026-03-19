# Final Summary: simon-bot 스킬 개선 조사 결과

분석일: 2026-03-13
초점: 프롬프트 엔지니어링 + 컨텍스트 관리

---

## 조사 방법

Claude Code 공식 문서(code.claude.com/docs)가 2026년 초 대폭 리뉴얼됨. 아래 6개 핵심 페이지에서 최신 기법을 추출하고, simon-bot 계열 12개 스킬의 현재 상태와 교차 분석함.

| 페이지 | 핵심 수확 |
|--------|----------|
| Best Practices | 컨텍스트 윈도우가 가장 중요한 리소스, 검증 수단 제공이 최고 레버리지, 서브에이전트로 컨텍스트 격리 |
| Skills | !`command` 동적 주입, context: fork, ultrathink 키워드, 스킬 내 hooks 정의 |
| Sub-agents | 영구 메모리(memory 필드), 스킬 사전로딩(skills 필드), isolation: worktree, MCP 범위 지정 |
| Memory | /compact 커스터마이징, .claude/rules/ 경로별 규칙, claudeMdExcludes, InstructionsLoaded 훅 |
| Agent Teams | TeammateIdle/TaskCompleted 훅, 계획 승인 요구, 팀 규모 3-5명 |
| Common Workflows | ultrathink/adaptive reasoning, /btw 사이드 질문, --worktree 플래그 |

---

## 핵심 발견

### simon-bot이 이미 잘 하고 있는 것

1. **Reference Loading Policy** — Phase별 선택적 로딩은 공식 권장사항을 선행 구현한 것
2. **Session Isolation Protocol** — 홈 디렉토리 기반 세션 격리는 서브에이전트 영구 메모리의 설계 철학과 일치
3. **Deterministic Gate Principle** — bash 스크립트 기반 결정론적 검증은 hooks 기반 강화의 방향과 일치
4. **Composable CLI Script Toolkit** — 유닉스 파이프라인 철학은 공식 문서의 "pipe in, pipe out" 패턴과 동일
5. **Cognitive Independence (Blind-First)** — 리뷰 품질 보장 패턴으로 업계에서도 드문 수준의 설계

### 가장 큰 개선 기회 3가지 (프롬프트 엔지니어링 + 컨텍스트 관리)

**1. 자동 압축 시 워크플로 상태 보존 (P-001)**
- 현재: "압축이 발생해도 계속 진행"이라고만 명시
- 문제: decision-journal, failure-log 등 핵심 상태가 압축 시 대화에서 소실
- 해결: /compact 보존 지시 + 압축 후 자동 재로딩 파일 목록 명시

**2. hooks frontmatter로 Auto-Verification 결정론적 실행 (P-002)**
- 현재: Auto-Verification이 "권장사항"으로 텍스트 안내
- 문제: LLM 기억에 의존, 컨텍스트 압축 후 규칙 소실 가능
- 해결: SKILL.md frontmatter hooks 필드로 선언적 정의

**3. !`command` 동적 컨텍스트 주입 (P-003)**
- 현재: Startup에서 5-8 LLM 턴으로 환경 정보 수집
- 문제: 환경 정보 수집에 불필요한 토큰 소비
- 해결: !`command` 전처리로 0 LLM턴 환경 정보 삽입

---

## 제안 목록 (우선순위순)

| ID | 제목 | 심각도 | 대상 | 핵심 효과 |
|----|------|--------|------|----------|
| P-001 | /compact 보존 지시 | CRITICAL | simon-bot, grind, pm | 자동 압축 시 워크플로 상태 연속성 보장 |
| P-002 | hooks frontmatter Auto-Verification | CRITICAL | simon-bot | 결정론적 검증, LLM 기억 의존 제거 |
| P-003 | !`command` 동적 주입 | CRITICAL | simon-bot, grind, review | Startup 3-5턴 절약 |
| P-004 | 커스텀 서브에이전트 정의 | HIGH | simon-bot | 일관된 역할, 도구 제한, 세션 간 학습 |
| P-005 | ultrathink 전략적 배치 | HIGH | simon-bot, grind | 핵심 판단의 추론 깊이 향상 |
| P-006 | description 간결화 | HIGH | 전체 12개 | 토큰 예산 40-50% 절약 |
| P-007 | 서브에이전트 영구 메모리 | HIGH | simon-bot | 반복 세션 탐색 시간 50%+ 감소 |
| P-008 | context: fork (report) | MEDIUM | simon-bot-report | 분석 시 메인 컨텍스트 보호 |
| P-009 | /btw 활용 가이드 | MEDIUM | simon-bot | 불필요한 컨텍스트 소비 감소 |
| P-010 | 스킬 사전로딩 핸드오프 | MEDIUM | simon-bot | 핸드오프 시 로딩 턴 절약 |

---

## 적용 시 주의사항

1. **!`command` 출력 크기**: 스킬 콘텐츠에 포함되므로, 출력이 긴 명령은 지양. fallback (`|| echo "..."`) 필수.
2. **hooks frontmatter 호환성**: auto-verify.sh가 없는 프로젝트에서도 에러 없이 통과해야 함.
3. **description 축소 후 트리거 테스트**: skill-creator eval로 트리거 정확도 반드시 검증.
4. **ultrathink 비용**: 토큰 비용 증가하므로 5개 핵심 지점에만 제한.
5. **context: fork 제한**: 대화 히스토리에 접근 불가하므로, 사용자 맥락 전달이 필요한 경우 부적합.

---

## 검증 전략

### 정적 검증
- YAML frontmatter 유효성
- reference 파일 경로 존재
- skill-best-practices.md 6개 카테고리 체크

### 트리거 테스트
- 대표 프롬프트 10개로 각 스킬 트리거 정확도 확인
- description 변경 전/후 비교

### 스모크 테스트
- 각 스킬의 Startup이 정상 실행되는지 확인
- hooks, !`command`, 커스텀 에이전트가 올바르게 작동하는지 확인

### 실제 워크플로 테스트
- 소규모 프로젝트에서 SMALL path 전체 실행
- 자동 압축 유발 후 연속성 확인

---

## 다음 단계 (실제 적용 시)

1. P-001 (compact 보존 지시)부터 적용 — 위험도 가장 낮고 효과 즉시 확인 가능
2. P-003 (!`command`)을 소규모로 테스트 — Startup에 1-2개 명령만 먼저 도입
3. P-002 (hooks frontmatter) — auto-verify.sh가 이미 있는 프로젝트에서 테스트
4. P-004 (커스텀 에이전트) — architect 하나만 먼저 정의하여 검증
5. P-006 (description 간결화) — skill-creator eval로 트리거 정확도 확보 후 일괄 적용

---

## 미비한 점 / 한계

- **실제 웹 커뮤니티 (Hacker News, Reddit, Medium 등) 검색 미수행**: WebSearch 도구가 이 세션에서 사용 불가하여 공식 문서에만 의존함. 커뮤니티에서 발견되는 비공식 패턴이나 실전 사례는 포함되지 않음.
- **다른 AI 코딩 에이전트 (Cursor, Windsurf, Cline 등) 벤치마킹 미수행**: 경쟁 도구의 워크플로 패턴 비교가 추가 인사이트를 제공할 수 있음.
- **실제 토큰 사용량 측정 미수행**: 개선 효과의 정량적 추정은 실제 실행 데이터가 필요함.

이 한계는 simon-bot-auto-boost 스킬을 통해 WebSearch를 활용한 후속 조사로 보완할 수 있음.
