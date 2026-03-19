# Phase 2: 소스 요약본

## 소스 1: Context Engineering for Coding Agents
- **URL**: https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html
- **출처**: Martin Fowler (Birgitta Böckeler)
- **날짜**: 2026-03
- **핵심 내용**: 프롬프트 엔지니어링에서 컨텍스트 엔지니어링으로의 패러다임 전환을 체계적으로 정리. 코딩 에이전트의 컨텍스트를 Instructions(직접 행동 지시)와 Guidance(행동 규범)로 구분하고, 파일 기반 컨텍스트 패턴(Always-loaded rules, Path-scoped rules, Lazy-loading skills)을 분류.
- **주요 기법/패턴**:
  1. **3-tier 컨텍스트 로딩**: Always-loaded (CLAUDE.md) → Path-scoped (조건부 rules) → On-demand (skills)
  2. **3가지 제어 모델**: LLM-Controlled (스킬, MCP) / Human-Controlled (슬래시 커맨드) / Software-Triggered (hooks, lifecycle)
  3. **선택적 로딩 철학**: "not too little, not too much" — 에이전트는 과도한 컨텍스트에서도 성능이 저하된다
  4. **점진적 구축**: 처음부터 모든 것을 넣지 말고, 실패 모드 기반으로 점진적으로 추가
  5. **서브에이전트 패턴**: 의도적 컨텍스트 분리, 비용 최적화, 제2의 의견(다른 모델로)
  6. **확률적 실행의 한계**: "ensure", "prevent" 같은 용어에도 불구하고 결정론적 보장 불가 — 적절한 인간 감독 수준 선택 필요
- **simon-bot 관련성**:
  - **simon-bot SKILL.md**: Reference Loading Policy와 직접 대응. 현재 Phase별 lazy-loading은 이미 잘 구현되어 있으나, "Instructions vs Guidance" 구분을 명시적으로 도입하면 프롬프트 품질 향상 가능
  - **simon-bot 전체**: 점진적 컨텍스트 구축 원칙을 레퍼런스 파일 관리에 적용 가능
  - **컨텍스트 관리**: "Software-Triggered" 모델이 simon-bot의 Auto-Verification Hook과 정확히 대응 — 이 패턴의 이론적 근거 보강 가능

## 소스 2: Effective Context Engineering for AI Agents
- **URL**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- **출처**: Anthropic Engineering Blog
- **날짜**: 2026-02
- **핵심 내용**: Anthropic 공식 컨텍스트 엔지니어링 가이드. "가장 작은 고신호 토큰 집합을 찾는 것"이 핵심 원칙. Context rot(토큰 증가에 따른 회상 정확도 감소), 주의력 예산(attention budget) 개념 도입.
- **주요 기법/패턴**:
  1. **Altitude Calibration**: 프롬프트의 구체성 수준 조절 — 너무 구체적이면 취약, 너무 모호하면 효과 없음. "행동을 효과적으로 안내할 만큼 구체적이되, 강력한 휴리스틱을 제공할 만큼 유연하게"
  2. **Tool 설계 원칙**: 자기 완결적, 명확한 용도, 비모호한 파라미터, 최소 기능 중복, 토큰 효율적 반환
  3. **Just-In-Time Retrieval**: 사전 데이터 처리 대신 경량 식별자(파일 경로, 저장된 쿼리, 웹 링크)를 유지하고 런타임에 동적 로딩
  4. **Progressive Disclosure**: 에이전트가 탐색을 통해 점진적으로 컨텍스트 발견 — 파일 크기, 명명 규칙, 타임스탬프가 행동 신호 역할
  5. **Tool Result Clearing**: 이전 도구 호출 결과를 정리하는 것이 가장 안전하고 가벼운 compaction 형태
  6. **구조화된 노트 테이킹 (Agentic Memory)**: 에이전트가 외부 파일에 정기적으로 메모를 작성하고, 필요 시 다시 로딩 — "최소 오버헤드로 영속적 메모리 제공"
  7. **서브에이전트 반환 크기**: 심층 작업 후 "압축된 요약"을 반환 — 일반적으로 1,000-2,000 토큰
  8. **전략 선택 기준**: Compaction(광범위한 대화용) / Note-taking(명확한 마일스톤이 있는 반복 개발용) / Multi-agent(병렬 탐색이 유리한 복잡한 분석용)
- **simon-bot 관련성**:
  - **simon-bot**: Reference Loading Policy(Just-In-Time 패턴과 일치), Decision Journal(Agentic Memory 패턴과 일치), Context Window Management(compaction 전략 보강 가능)
  - **프롬프트 엔지니어링**: Altitude Calibration 개념을 전문가 패널 프롬프트에 적용 가능 — 현재 전문가별 지시가 너무 구체적이거나 모호한 부분 점검
  - **서브에이전트**: 반환 크기 가이드라인(1,000-2,000 토큰)을 명시적으로 적용 가능

## 소스 3: Claude Code Prompt Contracts (검색 스니펫 기반)
- **URL**: https://medium.com/@rentierdigital/i-stopped-vibe-coding-and-started-prompt-contracts-claude-code-went-from-gambling-to-shipping-4080ef23efac
- **출처**: Medium (paywall — 검색 스니펫 기반 분석)
- **날짜**: 2026-03
- **핵심 내용**: "프롬프트 계약" 패턴 — 명확한 입출력 계약을 통해 비결정적 프롬프트 실행을 일관된 결과 도출로 전환. "Vibe Coding"(감 기반 코딩)에서 벗어나 계약 기반 접근으로 전환.
- **주요 기법/패턴**:
  1. **Prompt Contract 패턴**: 프롬프트에 입력 조건, 출력 형식, 성공 기준을 명시적 "계약"으로 정의
  2. **검증 가능한 출력**: 자동 검증이 가능한 형태로 출력 형식을 설계
  3. **계약-검증 루프**: 계약 → 실행 → 검증 → 피드백 사이클
- **simon-bot 관련성**:
  - **simon-bot**: STICC Framework(Situation-Task-Intent-Concerns-Acceptance Criteria)가 이미 계약적 접근과 유사. Acceptance Criteria를 더 강화하고, 검증 가능한 형태로 표준화 가능
  - **전문가 패널**: 전문가 출력 스키마(expert-output-schema.md)를 "계약" 패턴으로 강화 — 각 전문가의 입력 조건과 출력 기대값을 명시

## 보충 소스: Effective Harnesses for Long-Running Agents
- **URL**: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- **출처**: Anthropic Engineering Blog
- **날짜**: 2026-02
- **핵심 내용**: 장시간 에이전트의 실전 하네스 설계. Two-agent 아키텍처(Initializer + Coding Agent), 세션 간 상태 관리, 한-기능-한-세션 규칙.
- **주요 기법/패턴**:
  1. **Two-Agent Architecture**: Initializer Agent(최초 환경 구축) + Coding Agent(점진적 구현)
  2. **Feature List File (JSON)**: 200+ 기능 목록, passes 상태 추적, 에이전트가 편집 금지
  3. **Session Entry Protocol**: pwd → git log + progress 읽기 → feature 선택 → 서버 구동 → 검증 테스트
  4. **One-Feature-Per-Session Rule**: 컨텍스트 윈도우 경계에서 반쯤 구현된 기능 방지
  5. **Startup Verification Testing**: 새 기능 작업 전 기존 기능 기본 검증 실행
  6. **claude-progress.txt**: 세션 간 진행 상태를 문서화하는 핵심 아티팩트
- **simon-bot 관련성**:
  - **simon-bot**: Session Isolation Protocol, Context Window Management와 직접 대응. 현재 SESSION_DIR 기반 격리가 이미 구현되어 있으나, Session Entry Protocol 패턴을 더 구조적으로 적용 가능
  - **simon-bot-sessions**: 세션 재개 프로토콜과 직접 관련. State Integrity Check(P-004)와 유사한 패턴

## 대상 스킬 선택적 로딩

소스 분석 결과, 가장 관련 있는 스킬:
1. **simon-bot** (핵심) — 프롬프트 엔지니어링, 컨텍스트 관리, 서브에이전트 패턴 모두 해당
2. **simon-bot (references/)** — context-separation.md, phase-a-planning.md, phase-b-implementation.md가 직접 개선 대상
3. **simon-bot-grind** — 장시간 에이전트 패턴(One-Feature-Per-Session)이 grind 워크플로에 관련될 수 있음

이미 simon-bot/SKILL.md는 로딩 완료. 추가로 필요한 레퍼런스는 전문가 패널에서 개별 로딩.
