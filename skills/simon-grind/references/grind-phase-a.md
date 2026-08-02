# Grind Phase A Enhancements

> Base: `~/.claude/skills/simon-dev/references/phase-a-planning.md`
> 이 문서는 simon Phase A에 대한 grind 전용 추가/변경사항만 기술합니다.

## Batch Question Protocol (P-002)

grind의 "사람 개입 최소화" 철학에 맞게, Phase A의 사용자 인터뷰를 압축한다.

**원칙:**
- Phase A 전체에서 AskUserQuestion은 **최대 5회**로 제한한다
- 도메인별 순차 인터뷰를 한 번의 통합 질문으로 묶는다
- confidence_threshold를 **0.85**로 상향하여 MEDIUM confidence 항목은 에이전트 자체 판단 + 기록
- Step 2/4 에스컬레이션 체크포인트를 하나로 통합하여 Steps 2-4 전체에서 누적된 에스컬레이션만 한 번에 제시

**적용:**
1. Step 0 + Step 1-A-B: 1회 AskUserQuestion (scope 확인 + 핵심 가정 검증을 통합)
2. Step 1-B: 1회 AskUserQuestion (계획서 초안 교정 — AI-First Draft)
3. Steps 2-4 통합 에스컬레이션: 1회 AskUserQuestion (모든 [USER-ESCALATION] 항목 일괄)
4. Step 4-B: 1회 AskUserQuestion (CRITICAL [REQUIRES-USER] 일괄 + 도메인팀 핵심 우려 통합)
5. Phase A 최종 확인: 1회 AskUserQuestion ("구현을 시작할까요?")

**예외 (non-escapable):** LOW confidence + HIGH impact 항목은 반드시 포함하되, 별도 라운드가 아닌 해당 회차의 질문에 통합한다.

> **Note:** Batch Question Protocol은 per-step의 `interview_max_rounds` 제한을 대체(supersede)한다. 개별 Step의 라운드 제한 대신 Phase A 전체에서 5회로 관리한다.

## Step 0: Scope Challenge + Assumption Collection (Enhanced)

simon Step 0에 추가:
- **Assumption collection**: architect must explicitly list ALL assumptions with confidence score and impact level
- **Clarification questions**: identify ambiguous/underspecified aspects
- Initialize `.claude/memory/assumptions-registry.md`
- Present structured format:
  ```
  ## Scope 분석 결과
  ### 추천 경로: [SMALL/STANDARD/LARGE] (이유)
  ### 확인이 필요한 가정들:
  1. [가정] — Confidence: MEDIUM — 맞나요?
  ### 질문:
  1. [모호한 부분에 대한 질문]
  ```
- User responses → update `assumptions-registry.md`
- Rejected → architect re-evaluates scope decisions
- **모든 path에서 max retry = 10** (path는 실행 Step만 결정)

## Step 1-A-B: Analysis Verification Checkpoint (NEW)

Purpose: Step 1-A 결과를 plan 작성 전에 사용자와 검증.

**도메인별 순차 인터뷰** — 각 Code Design Team 도메인을 차례로 AskUserQuestion:

- **Round 1: 코드 컨벤션** (convention-expert) — 감지된 패턴, 제안
- **Round 2: 언어/프레임워크 관용구** (idiom-expert) — 공식 문서 기반 권장사항
- **Round 3: 설계 패턴** (design-pattern-expert, auto-detect 시) — 아키텍처 패턴, 범위 경계
- **Round 4: 테스트 구조** (testability-expert, auto-detect 시) — 재사용 가능 코드, 테스트 전략

- 각 라운드는 별도 AskUserQuestion (해당 도메인에 질문 없으면 skip)
- **Escape hatch**: "진행해" → 남은 라운드 skip
  - **Exception**: LOW confidence + HIGH impact 항목은 탈출 불가
- Major corrections → re-run Step 1-A (max 2 times)

## Step 1-B: Plan Creation (3-Phase Structured Interview)

### Phase 1: Draft Creation (no user interaction)
- simon Step 1-B와 동일 + Step 1-A-B 결과 + `assumptions-registry.md` 입력 추가
- Plan에 추가 섹션: **Fallback strategies per Unit**, **Alternative implementation approaches** (at least 2 per Unit), **"Assumptions made" section** (confidence + impact)

### Phase 2: 도메인별 순차 인터뷰 (max 5 rounds)

- **Round 1: 요구사항 명확화** — 모호하거나 불충분한 요구사항
- **Round 2: 설계 결정** — 여러 유효한 접근법이 있는 선택지
- **Round 3: 범위 경계** — In scope / Out of scope 확인
- **Round 4: 제약조건 검증** — 기술적/비즈니스 제약
- **Round 5: 리스크 인지** — 식별된 위험, 수용 가능 여부

- 각 라운드: max 5 questions (`max_questions_per_round`)
- **Escape hatch**: "진행해" → skip (except LOW+HIGH items: non-escapable)

### Phase 3: Plan Finalization
- Unconfirmed assumptions → "planner's best judgment" + reasoning documented
- Update `assumptions-registry.md`

## Steps 2-4: Plan Review + User Escalation (Enhanced)

simon Steps 2-4에 추가:

### `[USER-ESCALATION]` Tag
- 토론 중 어느 agent든 `[USER-ESCALATION reason="..."]`로 사용자 입력 필요 항목을 표시
- **Deadlocks about user intent** → IMMEDIATE escalation

### Step 2 Deadlock Breakers
- Iteration 5: architect joins as mediator
- Iteration 7: architect proposes compromise
- Iteration 9: lead forces decision based on majority reasoning

### 도메인별 에스컬레이션 체크포인트 (Step 2 후, Steps 3-4 후)
- `[USER-ESCALATION]` items를 agent별로 그룹화하여 순차 제시
- **Escape hatch**: "진행해" → 에이전트 다수결 (except LOW+HIGH items)
- Responses → update plan + `assumptions-registry.md`

## Step 4-B: Expert Plan Review (4-Phase Interactive Resolution)

### Phase 1: Concern Classification
- simon Step 4-B와 동일한 팀 구조
- **Enhanced consensus**: 2 rounds + **10 extra rounds** if no consensus
- Each concern tagged: `[TECHNICAL]`, `[REQUIRES-USER]`, `[AMBIGUOUS]`

### Phase 2: Technical Resolution (no user interaction)
- `[TECHNICAL]` concerns: planner modifies plan
- CRITICAL → planner revision → Step 2 (max **10** loops)
- HIGH: mandatory notes. MEDIUM: record.

### Phase 3: 도메인팀별 순차 인터랙티브 해결
- **Pre-pass**: CRITICAL `[REQUIRES-USER]`/`[AMBIGUOUS]` 먼저 일괄 제시 (non-escapable)
- 이후 도메인팀별 순차 제시 (해당 팀에 항목 없으면 skip)
- **Escape hatch**: "진행해" → 전문가 권장안 적용

### Phase 4: Final Synthesis
- 모든 해결 결과 반영한 요약 제시
- "구현을 시작할까요?" (Yes / 추가 질문 / 수정 필요)
- 추가 질문/수정 → max 2 additional rounds
