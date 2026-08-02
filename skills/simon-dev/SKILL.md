---
name: simon-dev
description: "19-step 딥 워크플로 — 계획, 구현, 검증을 최고 수준의 엄격함으로 수행합니다. Use when: (1) 새 기능/피처 구현 (\"피처 구현해줘\", \"새 기능 만들어줘\", \"코드 작성해줘\"), (2) 전문가 리뷰 패널이 필요한 체계적 계획 수립, (3) git worktree 기반 병렬 실행, (4) PR 전 종합 코드 검증이 필요할 때. 체계적 계획-구현-검증 사이클이 필요한 피처 구현에 적합합니다. Don't use when: 분석만 필요 → simon-report. 3개+ 기능 프로젝트 관리 → simon-pm. '끝까지 해결해' 등 끈질긴 해결 요청 → simon-grind."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
  skills: [simplify, git-commit]
---

# simon-dev

Deep workflow skill with 19-step quality pipeline.

## Instructions

You are executing the **simon-dev** deep workflow. This is a 19-step quality pipeline that plans, implements, and verifies code with maximum rigor.

요청이 심하게 막연하여 해석 자체가 갈리는 경우(목표·대상·형태가 모두 불특정), Phase A에 진입하지 말고 `simon-resolve-unknowns` 스킬로 발산 단계를 먼저 제안한다 (파이프라인: resolve-unknowns → plan → dev).

## State-Driven Execution

**매 턴(응답) 시작 시 반드시 실행하는 루틴** — compaction, 세션 재개, 작업 전환 후 복귀 등 어떤 상황에서도 적용된다. 이 루틴이 없으면 compaction 후 현재 위치를 잃고 이전 Step을 반복하거나 건너뛸 수 있다:

1. `{SESSION_DIR}/memory/workflow-state.json` 읽기
2. `current_step`에 해당하는 Phase의 reference 목록 확인 (Reference Loading Policy 테이블)
3. `references_loaded` 필드에 해당 reference가 없거나, 있더라도 `loaded_at`이 현재 `session_id` 이전이면 → 재로딩. 그 외에는 → 스킵. Compaction 감지는 **결정론적 JSON 비교**로 수행한다 — 아래 보조 조건 중 하나라도 해당하면 재로딩 트리거:
   - 조건 1: 세션 재개 (session_id 불일치 또는 없음)
   - 조건 2: `/compact` 명령 직후
   - 조건 3: `loaded_at`이 현재 `session_id`(ISO-8601) 이전인 Tier 1 항목이 존재 (compaction 소실 의심)
   - 조건 4: 매 턴 시작 시 Tier 1 파일 하나라도 `references_loaded`에 없음 (방어적 재로딩)

   Compaction 감지 시 **Tier별 선택적 초기화**: Tier 1은 강제 재로딩, Tier 2는 현재 Phase에 해당하는 것만 재로딩, Tier 3는 초기화하지 않음 (on-demand 트리거로 자연스럽게 재로딩). "이전에 읽었으니 알고 있다"가 LLM 기억이 아닌 JSON 기록에 기반해야 핵심 규칙 소실을 방지한다.

   **원칙**: "기억 판단 비용 > 1개 파일 재로딩 비용" — 의심스러우면 재로딩한다.
3-B. **이전 Step 산출물 로딩** (세션 독립성 핵심): `step_outputs[prev_step]`에 기록된 파일들을 로딩한다.
  - **새 세션 감지 시** (workflow-state.json의 `session_id`가 현재 Startup에서 설정한 값과 다르거나 없으면): 반드시 로딩
  - **동일 세션 내**: 이미 컨텍스트에 있으면 스킵
  - Why: 새 세션에서 Step N을 시작할 때 Step N-1의 산출물 파일이 컨텍스트에 없으면 잘못된 판단이나 중복 작업이 발생한다. `step_outputs`는 Step 완료 시 기록되므로, 이 파일들을 로딩하면 이전 Step의 결과를 즉시 복원할 수 있다.
4. 해당 Step 실행
5. **Step 완료 즉시** workflow-state.json 갱신 (`references_loaded` + `step_outputs` 포함)

workflow-state.json이 없으면 Startup부터 시작한다.

**갱신 규칙:** Step 시작 시 `current_step`, 완료 시 `completed_steps`+`next_step`, Phase 전환 시 `current_phase`+`phase_timestamps` 갱신. 중단/에러: `blocked: true`. Step skip 시 `skipped_steps` 기록. Phase A 완료 시 Done-When Checks → `done_when_checks` 배열 추출 (`verified: false` 초기값). Step 5d/6/17 검증 통과 시 `verified: true` 갱신. Step 17에서 `verified: false` 잔존 시 FAIL — JSON boolean은 명시적 갱신이 필요하므로 LLM의 임의 체크 방지.

**Step 산출물 추적 (세션 독립성):** Step 완료 시 `step_outputs[step_id]`에 해당 Step이 생성한 핵심 파일의 경로 목록(SESSION_DIR 기준 상대 경로)을 기록한다. 이 목록이 다음 세션의 진입점이 된다 — 새 세션에서 Step N을 시작할 때 `step_outputs[prev_step]`을 읽으면 이전 Step의 산출물을 즉시 로딩할 수 있다. **Startup 시 `session_id`를 ISO-8601 타임스탬프로 기록**하여, 새 세션과 compaction 복구를 구분한다.

```json
{
  "current_step": "B/7", "session_id": "2026-04-14T10:30:00+09:00",
  "step_outputs": {"A/0": ["memory/codebase-health.md"], "A/1-B": ["memory/plan-summary.md"], "B/5": ["memory/unit-{name}/test-case-summary.md"]},
  "references_loaded": {"cross-cutting-protocols.md": {"loaded_at": "2026-04-17T10:30:00+09:00", "tier": 1}}
}
```

`loaded_at` 필드가 없는 기존 항목은 "미지정 = 재로딩 필요"로 보수 처리한다 (호환성).

### Cross-Session State

세션 간 구조화된 상태를 `~/.claude/projects/{slug}/state/`에 jsonl로 관리한다. Startup에서 유효 항목만 로딩하여 이전 세션의 이슈를 사전 인지한다 (상세: `cross-cutting-protocols.md`의 Cross-Session State 섹션 참조).

## Workflow Gotchas & Red Flags

Compaction 후에도 소실되지 않도록 Startup에서 로딩한다. For full list of gotchas (G-WF-001~008) and red flags, read [gotchas.md](references/gotchas.md).

## Cross-Cutting Protocols

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules, Agent Teams, Cognitive Independence 공통 프로토콜 포함.

### Session Isolation Protocol (확장)

For detailed protocol (SESSION_DIR 결정, 경로 매핑, PM 파견 시 결과 경로), read [cross-cutting-protocols.md](references/cross-cutting-protocols.md).

### Agent Teams (확장)

For lifecycle, rules, fallback, termination protocol details, read [agent-teams.md](references/agent-teams.md).

Agent Team 운영 중 오케스트레이터는 TaskList를 주기적으로 확인하여 사용자에게 진행 상황을 보고한다. 상세 프로토콜은 `agent-teams.md`의 Heartbeat Protocol 섹션 참조.

### Decision Journal

주요 판단 지점에서 사용자에게 1줄 판단 근거를 제시하고, `.claude/memory/decision-journal.md`에 누적 기록한다. 상세 형식(Contrastive Decision, Anti-Oscillation Rule)은 [cross-cutting-protocols.md](references/cross-cutting-protocols.md) 참조.

### Auto-Verification Hook (P-001)

모든 소스코드 수정 후 빌드/린트를 즉시 실행한다. 실패 시 Stop-and-Fix Gate 적용. Forbidden Rules는 `forbidden-guard.sh` (PreToolUse), 빌드 검증은 `auto-verify.sh` (PostToolUse)로 구조적 강제. 구현 완료 후 Integration Stage에서 `/simplify` 스킬을 **필수 게이트로 1회 실행**한다(skip 불가, [integration-and-review.md](references/integration-and-review.md)). 상세 동작과 settings.json 등록은 [cross-cutting-protocols.md](references/cross-cutting-protocols.md) 참조.

### Deterministic Gate Principle

게이트 검증에서 파일 존재 확인, 빌드/린트/테스트 실행, 패턴 매칭, 카운터 비교 등 결정론적으로 수행 가능한 작업은 bash 스크립트를 우선 사용한다. LLM은 스크립트 실행 결과(PASS/FAIL + 실패 항목)만 받아 후속 판단(수정 방향, 전략 전환)에 집중한다. 결정론적 검증을 LLM 기억에 의존하면, 컨텍스트 압축 시 규칙이 소실되어 게이트가 무력화될 수 있기 때문이다.

### Composable CLI Script Toolkit

`workflow/scripts/`의 스크립트는 구조화된 출력, 파이프 호환, 자기 문서화, 컨텍스트 전처리를 따른다.
For detailed principles, read [cross-cutting-protocols.md](references/cross-cutting-protocols.md).

### Phase Progress Dashboard

Phase 전환 시 `[######....] Step {current}/{total} ({percent}%)` 형식으로 진행 상황을 출력한다. 각 Step 완료 시 `[Progress] Step {N}/{total} 완료 — {Step명}` 1줄 경량 출력을 추가한다 (ship/guided 모드).

### Stop-and-Fix Gate

빌드, 린트, 타입체크, 테스트 중 하나라도 실패하면 **반드시 수정한 후에만** 다음 파일 수정, 다음 Step 진입, 사용자 보고 등 어떤 작업도 하지 않는다. "나중에 고치겠다"는 허용되지 않는다 — 미수정 실패는 누적되어 디버깅 비용이 기하급수적으로 증가하기 때문이다.

수정 후에는 **동일 검증 명령을 재실행(Fix-Verify Loop)**하여 통과를 확인한다. 재실행에서도 실패하면 Error Resilience 프로토콜을 적용한다.

ENV_INFRA로 테스트 실행 자체가 불가능한 경우, 사용자 명시적 승인 후에만 테스트를 SKIP할 수 있으며, 이때도 build + typecheck는 반드시 통과해야 한다.

### Autonomous Step Progression (Narration-Trap 방지)

자율 완주 구간에서 Step 완료를 턴 경계로 취급하지 않는다. 하위 단계(subagent/Agent 반환, 스킬 호출 복귀, SendMessage 토큰, 검증 명령 종료)가 반환된 직후, 같은 턴에서 **다음 Step의 첫 tool call을 가장 먼저 emit**한다 (tool-call-first). 위반 판정은 어휘가 아닌 행동 기준이다 — 하위 작업 결과를 요약하는 문장(`"Step N 완료. 다음은 …"` 류, 이 표현에 국한되지 않음)이 다음 tool call보다 먼저 emit되고 턴이 닫히면 위반이다. 종료 내레이션으로 턴을 닫으면 모델이 턴 종료 리듬에 self-conditioning되어 파이프라인이 멈추고 사용자가 "계속"을 입력해야 재개된다. 상태 보고가 필요하면 다음 Step의 tool call을 먼저 호출한 뒤 1줄 경량 보고를 덧붙인다 (GOOD/BAD 예시는 preamble.md의 Autonomous Progression Invariant 참조).

턴 종료는 **Interaction Mode의 "확인이 필요한 핵심 판단점"(AskUserQuestion), 워크플로 최종 완료, 자동 복구 불가 차단 상태**에서만 허용된다. "자율 완주 범위"(커밋·푸시·PR Draft·Integration merge·재시도·session 갱신 등)에서는 내레이션으로 턴을 닫지 않는다. 정본은 `~/.claude/skills/_shared/preamble.md`의 "Autonomous Progression Invariant" 참조.

### Reference Loading Policy (컨텍스트 효율)

각 Phase 진입 시 해당 Phase의 레퍼런스 파일만 읽는다. **Tier 1 파일은 컨텍스트 초반부(보수적 기준 256K 이내)에 로딩되어야 한다** — 긴 컨텍스트 후반부의 정확도 하락에 대비해 핵심 규칙을 초기에 배치한다 (측정 근거: Opus 4.6 기준 256K 이후 ~70%로 하락. Fable 5는 1M 컨텍스트이나 정확도 커브 미공개 — 모델 변경 시 재검토).

| 트리거 | 읽을 파일 | Tier | 비고 |
|--------|----------|------|------|
| Startup 또는 세션 복원 시 | `cross-cutting-protocols.md` | 1 | CWM, Session Isolation 등 핵심 프로토콜 |
| Startup 또는 세션 복원 시 | `gotchas.md` | 1 | 워크플로 실수 패턴 + Red Flags |
| Phase A 진입 | `phase-a-planning.md` | 1 | 계획 품질이 전체 파이프라인 품질을 결정 |
| Phase A Steps 2-4, 4-B, Calibration 진입 | `phase-a-review.md` | 1 | Plan Review, Expert Review, Calibration Checklist 상세 지침 |
| Phase B-E 구현 진입 | `phase-b-implementation.md` | 1 | TDD, Critical Rules 등 구현 핵심 |
| Phase B-E 구현 진입 | `~/.claude/skills/_shared/lazy-output-discipline.md` | 1 | Economy of Means — 같은 커버리지를 최소 코드로 (테스트·검증은 제외) |
| Phase B-E 검증 진입 (Step 6+) | `phase-b-verification.md` | 2 | Step 6+ 진입 시 로딩 |
| Integration/Review 진입 | `integration-and-review.md` | 2 | 후반 단계 |
| Step 6/7/17 검증 진입 시 | `context-separation.md` | 2 | 검증 시에만 필요 |
| Step 6/7/17 검증 진입 시 | `review-rubric.md` | 2 | 검증 시에만 필요 |
| Step 17 진입 | Tail Reminder (파일 아님 — 3-5줄 압축 재확인) | — | Forbidden Rules 활성 상태, Plan Immutability(G-WF-001), done_when_checks 미해결 시 통과 금지를 진입 직전에 재확인. 긴 검증 체인 끝에서 초반 규칙이 attention에서 소실되는 것을 방지 (Tier 2 Unload로 구현 규칙이 해제된 상태이기 때문) |
| Agent Team 생성 시 | `agent-teams.md` | 3 | on-demand |
| 에러 발생 시 | `error-resilience.md` | 3 | on-demand |
| 전문가 팀 findings 작성 시 | `expert-output-schema.md` | 3 | on-demand |
| Forbidden Rules 참조 필요 시 | `forbidden-rules.md` | 3 | PreToolUse 훅으로 구조적 강제됨 |
| 외부 라이브러리/서비스 사용 시 | `docs-first-protocol.md` | 3 | on-demand |
| Gate 조건 참조 필요 시 | `gate-definitions.md` | 3 | on-demand |
| 산출물 생성 시 (Step 1-B, 18) | `generation-style-guide.md` | 3 | on-demand |

> **Tier 정의와 Phase 전환 시 Tier 2 Unload 규칙**(언로드 대상 테이블, 45%+ 전환 시 compact 지침 포함)은 [cross-cutting-protocols.md](references/cross-cutting-protocols.md)의 "Reference Tier 운용" 섹션 참조 — Startup Tier 1로 항상 로딩되므로 세션 내내 유효하다.

### Subagent 사용 기준

**핵심 리트머스 테스트**: "이 작업의 중간 도구 출력이 나중에 다시 필요한가, 결론만 필요한가?" 결론만 필요하다면 → subagent.

subagent는 다음 경우에 사용한다:
1. 독립적 컨텍스트가 필요한 병렬 작업
2. 다른 전문성이 필요한 역할 분리
3. 대량의 코드 탐색 — 탐색 결과의 요약만 메인 컨텍스트로 반환하고, 중간 Read/Grep 출력은 subagent 컨텍스트에서만 소비
4. 독립 검증이 품질을 높이는 경우 (Cognitive Independence — `context-separation.md` 참조)
   - CRITICAL/HIGH 판정의 교차 검증, 3회+ 동일 실패 반복 시 fresh perspective
   - 결정론적 검증(빌드, 테스트 실행)은 제외 — 코드 실행으로 확인 가능한 것에 subagent를 쓰지 않음
5. 중간 출력이 대량인 작업 — spec 파일 대조 검증, git 변경 기반 문서 작성, 타 서비스 코드베이스 요약

단일 파일 수정, 간단한 검색, 단순 명령 실행은 직접 수행한다. 불필요한 subagent 생성은 컨텍스트를 낭비한다. Spawn 직전 오케스트레이터는 위 5개 기준 중 어느 것에 해당하는지 1줄로 인용한다 (예: `[Spawn] 기준 3 — 대량 코드 탐색`) — 인용할 기준이 없으면 직접 수행한다. 이 규율은 토큰 절약이 아니라 신뢰성 목적이다: 근거 없는 subagent 증식은 `_shared/preamble.md`의 Inter-Agent Communication Gotchas(병렬 파일 충돌, 프롬프트 핵심 지시 소실, API Contract 불일치)의 발생 확률을 높인다.

**Result-Only 반환 원칙** (오케스트레이터 컨텍스트 보호): 반환 계약과 상세 표는 `_shared/preamble.md`의 Subagent Result-Only Contract를 따른다.

**Spawn 출력 계약** (`full_output: true` 제외): spawn 프롬프트는 반환 형식 `STATUS: PASS/FAIL, 발견 {N}건, 저장: {파일경로}`를 요구하고, 중간 탐색 출력은 반환하지 않도록 지시한다 — 감싸는 문구는 맥락에 맞게 표현한다. 오케스트레이터는 반환값의 `^STATUS: (PASS|FAIL)` 패턴을 확인한다.

**역할별 도구 범위, maxTurns, 반환 규약:**
Agent spawn 시 [agent-capability-matrix.md](references/agent-capability-matrix.md) 참조. Spawn Prompt Template과 Status Prefix 규약을 포함한다.

### Multi-Agent Saturation Guard

multi-agent 구조(Agent Team, Devil's Advocate, Verification Layer)는 단일 에이전트로 달성 불가능한 품질을 제공하지만 overhead도 동반한다. 축소/병합 후보 판단 전에 반드시 `context-separation.md`의 "검증 지시 제거 판단 기준"(A. 제거 후보 / B. 유지 대상)을 먼저 적용한다 — B 유형(Fresh Subagent/Blind-First/Cross-Model/결정론적 게이트)은 축소 논의 대상이 아니다. 다음 조건에서 multi-agent를 축소하여 비용 대비 효과를 최적화한다:

**축소 조건** (하나라도 해당 시):
- Step 4-B findings 5건 이하 + CRITICAL 0건 → Verification Layer를 single verifier로 축소 (Blind-First는 유지)
- 이전 5세션 Harness Stress Test에서 특정 multi-agent Step의 추가 발견율 10% 미만 → optional 전환, Decision Journal에 근거 기록

**축소 불가** (multi-agent 필수):
- config.yaml의 high_impact_paths 매칭 파일 포함
- Step 7 Verification Layer
- LARGE 경로의 모든 multi-agent Step

### Over-engineering 방지

plan-summary.md에 명시된 변경만 구현한다. 범위 밖 개선(docstring, 주석, 타입 어노테이션 등)을 발견하면 `.claude/memory/unresolved-decisions.md`에 기록하고, 발견 즉시 1줄로 통보한 뒤 요청된 스코프대로 계속 진행한다: `[Scope] {한 줄 설명} 발견 — 계획 범위 밖이라 미적용, unresolved-decisions.md에 기록`. 통보는 정보 제공이지 턴 종료 사유가 아니다 (Autonomous Progression 유지). 범위 밖 수정을 하지 않는 이유: 리뷰어의 인지 부하를 높이고, 의도치 않은 동작 변경 위험이 있으며, PR의 변경 범위가 불명확해져 승인이 지연되기 때문이다.

**Reference-Literal Rule**: 사용자가 특정 파일을 레퍼런스로 명시하면("X 파일 보고 해줘", "X 참고해서 추가해줘") 해당 파일의 구조·필드·스타일을 그대로 복사하는 것이 기본값이다. 타겟 환경의 기존 패턴이 레퍼런스와 달라도 사용자 지시가 우선한다. 리소스 타입을 결정하는 필드(`kind`, `schedule`, `suspend`, `tier` 등)는 절대 자의적으로 생략하지 않는다. 타겟 환경 기존 패턴과 레퍼런스가 충돌하면 Confusion Management Protocol을 적용하여 사용자에게 확인한다 — 자동 결정하지 않는다.

### User Interaction Recording (필수)

사용자의 교정·피드백·거부·수정 요청이 발생할 때마다 **즉시** `.claude/memory/user-feedback-log.md`에 append한다. 이 파일은 Phase-End Auto-Retrospective의 gotcha 감지와 Step 20 자기 개선의 핵심 입력이다 — 기록이 누락되면 gotcha 축적 파이프라인 전체가 동작하지 않는다.

**기록 트리거** (아래 중 하나라도 발생 시 즉시 기록):
- AskUserQuestion에 대한 사용자 응답
- 사용자가 계획·구현·결과를 교정("아니 그게 아니라", "이건 빼줘" 등)
- 사용자가 접근 방향을 변경("다른 방법으로 해줘")
- PR 리뷰 피드백

**형식**: `## [Step N] {단계명}` 아래 3항목:
- **User said**: 사용자 발언 요약
- **Interpretation**: 이 피드백의 의미 (무엇이 잘못되었는지)
- **Skill implication**: 워크플로/스킬에 대한 시사점

파일이 없으면 생성한다. 교정·불만·반복 요청에 특히 주의.

### Phase-End Auto-Retrospective

For Phase-End Auto-Retrospective protocol, read [cross-cutting-protocols.md](references/cross-cutting-protocols.md).

### Handoff Notification

스킬 전환(simon-dev → simon-code-review 등) 시 사용자에게 1줄 통보를 출력한다. 갑작스러운 스킬 전환으로 인한 사용자 혼란을 방지한다.

형식: `[Handoff] {현재 스킬} → {다음 스킬}: {목적 1줄 설명}`
예시: `[Handoff] simon-dev → simon-code-review: Draft PR 생성 및 코드 리뷰 진행합니다.`

### On-Demand Session Hooks
> ⚠ **미구현 — 설계만 존재**: session-modifiers.json을 읽는 hook 코드와 /scope-lock 스킬은 없다. 현존 /careful은 gstack 플러그인의 별개 스킬(경고 전용)이다.
- 설계 항목: **`/careful`**(CONTEXT-SENSITIVE→ABSOLUTE 격상), **`/freeze <dir>`**(지정 디렉토리 수정 차단 — freeze 스킬은 실존, guard 연동만 미구현), **`/scope-lock`**(NOT in scope 파일 수정 차단)

### Handoff Manifest (Instruction)

스킬 전환 시 `{SESSION_DIR}/memory/handoff-manifest.json`을 생성하여 컨텍스트 전달을 결정론적으로 보장한다.

**필드**: `from_skill`, `to_skill`, `trigger_step`, `transfer_files`(로딩할 파일), `block_files`(로딩 금지), `session_dir`, `distilled_brief`.

수신 스킬은 transfer_files만 로딩하고 block_files는 제외 — What-not-Why Handoff 규칙이 내장되어 Cognitive Independence 위반을 구조적으로 방지한다.

**`distilled_brief`**는 수신 스킬이 파일을 읽기 전에 방향을 설정하는 "1페이지 브리핑"이다. 스키마(JSON 예시), 작성 규칙, 금지 항목(Why Pollution)의 상세는 [handoff-manifest-brief.md](references/handoff-manifest-brief.md) 참조. 핵심 필드: `what_was_done`, `key_decisions`, `critical_constraints`, `do_not_retry`, `recommended_entry`. `do_not_retry`는 `/rewind + re-prompt` 패턴의 구조적 구현.

### AskUserQuestion Standard Format (Guidance)

For AskUserQuestion format, read [generation-style-guide.md](references/generation-style-guide.md).

### Docs-First Protocol

라이브러리·DB·프레임워크·외부 서비스 사용 시 공식 문서를 먼저 조회한다.
For detailed protocol (적용 기준, 도구 우선순위, 조회 불가 시 대응), read [docs-first-protocol.md](references/docs-first-protocol.md).

### OpenSpec Spec Capture (조건부)

대상 레포에 `openspec/`가 초기화되어 있으면(`[ -d "$(git rev-parse --show-toplevel)/openspec" ] && command -v openspec`) 구현 결과를 레포에 커밋되는 행위계약 스펙으로 남긴다 — Propose(Phase A Calibration 직후, `openspec-propose` 호출)와 Archive(Step 18 직전, `openspec-archive-change` 호출) 두 시점. 게이트 미충족 시 전체 skip + 1줄 통보. 활성 조건·저장 위치·호출 규약·behavior-contract 분리 원칙 상세는 [openspec-capture.md](references/openspec-capture.md) 참조.

### Interaction Mode

config.yaml의 `interaction_mode` 설정에 따라 사용자 인터랙션 수준을 조절한다:

- **ship**: test failure, build failure, CRITICAL security finding, merge conflict에서만 정지. 나머지는 AI 자동 결정 + Decision Journal 기록. "한 번 입력 후 PR URL까지."
- **guided** (기본값): 핵심 판단점(경로 선택, CRITICAL 이슈)에서만 AskUserQuestion. 대부분 자동 진행.
    - **자율 완주 범위 (사용자 확인 불필요)**: 커밋 생성, 브랜치 푸시, PR Draft 생성, Integration Stage의 merge/rebase, emit.sh 발신, session 파일 갱신, worktree upstream 설정, 테스트·빌드 재시도. 이 단계들은 파이프라인의 기계적 실행 단계이며, 사용자 판단이 필요한 핵심 판단점이 아니다. AskUserQuestion을 사용하면 파이프라인 자율성이 깨지고 "한 번 입력 후 PR URL까지"라는 ship 철학이 무너진다.
    - **확인이 필요한 핵심 판단점**: Scope Challenge 경로 선택(STANDARD vs LARGE), CRITICAL 보안/데이터 이슈 발견, plan 단계의 비즈니스 결정, merge conflict, 실패 재시도 한계 초과 후 전략 전환.
- **interactive**: 모든 AskUserQuestion 유지. 현재 동작과 동일.

Startup에서 `config.yaml`의 `interaction_mode`를 읽고, 없으면 `guided`를 기본값으로 사용한다.

## Startup

> **HARD GATE**: Startup 완료 여부는 3-E Startup Completion Gate가 결정론적으로 판정한다 — 이 판정 없이 Phase A로 진행하지 않는다 (SESSION_DIR 없이 진행하면 세션 상태·복구 능력이 유실되기 때문).

Startup 단계는 순서 의존성이 있으므로 순차 실행한다.

1. `.claude/workflow/` 존재 확인. 없으면: `bash ~/.claude/skills/simon-dev/install.sh --project-only`
2. 워크플로 파일 읽기 (parallel OK):
   - `.claude/workflow/config.yaml`
   - `.claude/memory/retrospective.md` (있으면)
   - `.claude/project-memory.json` (있으면 Read — 이전 세션에서 학습된 빌드 에러 패턴, 테스트 환경 quirk, 기각된 접근법 포함)
   - `.claude/memory/handoff-manifest.json` (있으면 — P-009 Handoff 감지)
2-B. **Prior Context Brief** (P-001): 사용자 요청에서 키워드를 추출하고, `~/.claude/projects/{slug}/state/decisions.jsonl`에서 관련 결정사항을 검색하여 Prior Context Brief를 합성한다. 검색 명령 상세는 [startup-bootstrap.md](references/startup-bootstrap.md)의 "Prior Context Brief 검색" 섹션 참조.
   - 매칭 결정이 있으면: `{SESSION_DIR}/memory/prior-context-brief.md`에 요약 저장 — 각 결정의 decision, rationale, rejected_alternatives를 1줄씩 요약
   - 매칭 결정이 없으면: skip (빈 파일 생성하지 않음)
   - Phase A Step 1에서 Prior Context Brief를 architect에게 전달하여 이전 결정과 일관된 계획 수립을 유도한다
3. **브랜치명 자동 생성** (P-001): 사용자 요청에서 브랜치명을 자동 생성한다. 예: "인증 기능 추가해줘" → `feat/add-auth`. AskUserQuestion 없이 통보: `[Default] Branch: feat/add-auth — 변경하려면 알려주세요.` → `.claude/memory/branch-name.md`에 저장
   > **주의**: 이 단계에서는 브랜치명만 결정한다. 실제 git 브랜치 생성은 Phase B Pre-Phase에서 `git fetch origin {base_branch}` 후 `origin/{base_branch}` 기반으로 수행한다. Startup에서 `git checkout -b`로 직접 브랜치를 생성하는 것은 **금지** — stale한 로컬 main을 사용하여 원격에 머지된 커밋을 놓칠 수 있다.
3-A. **원격 ref 동기화** (P-001): 브랜치명 결정 직후 원격 상태를 로컬로 가져온다.
   ```bash
   git fetch origin
   ```
   - 로컬 워킹 디렉토리와 현재 브랜치는 변경되지 않는다. 원격 추적 ref(`origin/*`)만 갱신된다.
   - 이후 main/master 기준 조회(`origin/main`, `git log origin/main..HEAD` 등)는 이 시점에 동기화된 ref를 사용한다.
   - 실패 시 워크플로를 중단하지 않는다. 실패 시: `[Warning] git fetch 실패 — 원격 ref 없이 진행`
3-B. **SESSION_DIR 초기화**: 브랜치명 확정 후 세션 디렉토리를 생성한다.
   ```bash
   PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
   SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${branch_name}"
   mkdir -p "${SESSION_DIR}/memory" "${SESSION_DIR}/reports"
   ```
   이후 모든 `.claude/memory/`, `.claude/reports/` 경로는 `{SESSION_DIR}` 기준으로 해석한다.
3-C. **workflow-state.json 초기화**: `{SESSION_DIR}/memory/workflow-state.json`에 초기 스키마를 기록한다 (State-Driven Execution 섹션 참조). 이미 존재하면 기존 세션 복원으로 판단하고 덮어쓰지 않는다.
3-D. **session-meta.json 초기화**: `{SESSION_DIR}/memory/session-meta.json`에 세션 메타데이터 생성 (필드: `branch`, `skill`, `current_phase`, `current_step`, `total_steps`, `status`, `last_activity`, `last_commit_hash`). 이미 존재하면 기존 세션 복원으로 판단하고 덮어쓰지 않는다. Phase/Step 전환 시 `current_phase`, `current_step`, `last_activity` 갱신. 커밋 생성 시 `last_commit_hash` 갱신.
3-E. **Startup Completion Gate** — Deterministic Gate Principle 적용. bash로 필수 파일 존재를 확인한 후에만 Phase A 진입. 상세 bash 스크립트는 [startup-bootstrap.md](references/startup-bootstrap.md)의 "Startup Completion Gate" 섹션 참조.
   필수: workflow-state.json + session-meta.json 존재. FAIL 시 해당 단계로 돌아가 재수행.
4. **Handoff Manifest 처리** (P-009): `.claude/memory/handoff-manifest.json`이 존재하면:
   - `transfer_files`(별칭 `context_files` 호환)를 자동 로딩하여 컨텍스트 복원. `block_files`는 로딩하지 않음 (Cognitive Independence 보호)
   - `distilled_brief`를 먼저 처리하여 `what_was_done`, `key_decisions`, `critical_constraints`, `do_not_retry`, `recommended_entry`로 방향 설정 (transfer_files 읽기 전)
   - `skip_steps`에 명시된 Step은 건너뛰기 (`completed_steps`로 표시하고 다음 Step으로 진행)
   - `failure_context`가 있으면 `failure-log.md` 초기값으로 설정
   - `force_path`가 있으면 Step 0 Scope Challenge를 skip하고 해당 경로로 직행 (단, `config.yaml`의 `high_impact_paths`에 매칭되는 파일이 포함되면 STANDARD 이상을 강제)
   - **`from_skill == "simon-plan"` 케이스** (Phase A 완전 위임): simon-plan이 Phase A 전체(Scope/Plan/Review/Expert Review)를 인터뷰 형식으로 이미 완료했으므로, `skip_steps`가 `A/0`~`A/Calibration`을 포함하면 **Phase A 전체를 건너뛰고 Phase B Pre-Phase부터 시작한다**. transfer_files에 포함된 `plan-summary.md`, `codebase-health.md`, `requirements.md`, `code-design-analysis.md`, `expert-plan-concerns.md`, `verify-commands.md`, `env-context.md`는 Phase A 산출물과 동일 역할이므로 그대로 `step_outputs`에 등록한다. Linear 이슈 동기화는 simon-plan이 이미 수행했으므로 중복 업데이트하지 않는다 — distilled_brief의 `linear_issue` 필드만 참조하여 PR description 링크 등에 활용.
5. **Context Completeness Assessment**: SESSION_DIR 초기화 후 핵심 memory 파일의 존재/유효성을 평가한다.
   - 검증 대상: `config.yaml`, `workflow-state.json`, `session-meta.json`, `handoff-manifest.json` (있으면), `retrospective.md` (있으면)
   - 판정 기준:
     - **FULL**: config.yaml 존재 + workflow-state/session-meta 정상 초기화
     - **PARTIAL**: config.yaml 존재하지만 일부 memory 파일 누락/불일치 (State Integrity Check 항목 참조)
     - **MISSING**: config.yaml 자체가 없음 → install.sh 재실행
   - 1줄 통보: `[Context Quality: {FULL|PARTIAL|MISSING}] — {상세}`
   - PARTIAL인 경우: 누락된 파일을 명시하고 작업을 계속 진행한다. 세션 복원 시 State Integrity Check에서 git 이력 기반 재구성이 가능하다.
6. **Pre-flight 환경 검증**: Phase A 진입 전에 bash 기반 환경 검증을 수행한다 (LLM 토큰 0). Phase A에서 전문가 패널 분석과 계획서 작성에 대량 토큰을 소비한 후에야 환경 문제를 발견하는 것을 방지한다.
   - `.claude/workflow/scripts/preflight.sh` 실행 (없으면 skip)
   - 검증 항목: 빌드 도구 존재, 런타임 버전, Docker 상태 (필요 시), 디스크 여유, 포트 충돌
   - 실패 시: Phase A 진입 차단, 사용자에게 환경 수정 요청
   - 기존 `setup-test-env.sh`(Phase B Pre-Step)와의 관계: preflight는 "빠른 선행 검증"(필수 도구 존재 여부), setup은 "상세 환경 구성"(테스트 DB 생성, 컨테이너 구동 등)

## Phase A: Planning (Interactive with User)

For detailed step instructions, read [phase-a-planning.md](references/phase-a-planning.md).

**Unknowns Gate (Step 0 진입 전, 1분 이내 판단)**

요청에 unknowns가 많은 상태로 Phase A를 진행하면 인터뷰가 겉돌고 plan이 추측 위에 세워진다. Step 0 진입 전에 모호성 신호를 평가한다:

- 목표가 결과물 수준으로 기술되지 않음 ("뭔가 만들어줘", "대충", "알아서")
- 사용자가 해당 영역이 낯설다고 밝힘 ("이 쪽 처음 봐", "잘 몰라")
- 성공 조건/수용 기준을 요청에서 도출할 수 없음
- 합리적 해석이 2개 이상으로 갈라져 서로 다른 구현이 나옴
- "보면 안다" 성격의 기준(비주얼/UX/톤)이 작업의 핵심

**신호 2개 이상이면** AskUserQuestion으로 제안한다: ① `simon-resolve-unknowns` 선실행 (권장 — 발산으로 unknowns 해소 후 브리프를 들고 복귀) ② 그대로 진행 (Phase A 인터뷰로 커버 가능한 수준) ③ 사용자가 즉석에서 보완 설명. 신호 1개 이하면 게이트를 통과하고 언급하지 않는다.

**게이트 skip 조건**: `handoff-manifest.json`이 존재하면 (simon-resolve-unknowns 또는 simon-plan을 이미 거침) 이 게이트를 건너뛴다. ①을 선택받으면 Skill tool로 simon-resolve-unknowns를 호출하고, 그 산출물(refined-brief.md, unknowns-ledger.md, manifest)을 받아 Phase A를 재개한다 — ledger의 Resolved는 인터뷰 재질문 금지, Rejected는 do_not_retry로 취급.

**Step 0: Scope Challenge**
- `architect` agent: git history 분석, 최소 변경 결정, scope 판별
- 2 review paths 제시 (STANDARD / LARGE)
- **Output**: `memory/codebase-health.md`, `memory/plan-summary.md` (scope section)

**Step 1-A: Project Analysis + Code Design Analysis**
- subagent: 프로젝트 구조 스캔 + 분석
- Context7 MCP로 라이브러리 문서 조회
- **Agent Team: Code Design Team** — convention/idiom/design-pattern/testability experts 토론
- Save: `requirements.md`, `code-design-analysis.md`
- **Output**: `memory/requirements.md`, `memory/code-design-analysis.md`, `memory/verify-commands.md`, `memory/env-context.md`

**Step 1-B: Plan Creation**
- subagent (planner role) in interview mode
- STICC Framework 기반 계획서 (Situation → Task → Intent → Concerns → Acceptance Criteria → End State)
- Interview Guard: 코드에서 알 수 있는 건 묻지 않음. 비즈니스 결정만 질문
- **plan-summary.md 필수 섹션** — 이 섹션이 누락되면 Phase B의 TDD 품질과 Step 6 Purpose Alignment 정밀도가 저하된다:
  - STICC Framework (Situation, Task, Intent, Concerns, Acceptance Criteria)
  - **Done-When Checks**: Mechanical (빌드/테스트 명령) + Behavioral (구체적 입출력 검증)
  - End State: Files Changed 테이블, Behavior Changes (Before→After), Test Targets
  - NOT in scope: 범위 밖 항목 명시
- Save: `plan-summary.md`
- **Output**: `memory/plan-summary.md` — **이후 모든 Phase의 핵심 입력**. 새 세션에서 Step 2 이후를 시작하려면 이 파일 하나만 있으면 충분한 계획 컨텍스트를 복원할 수 있다.

**Steps 2-4: Plan Review (Agent Team)**
- planner + critic + architect 직접 토론
- Step 2: Plan Review (max 3 iterations)
- Step 3: Meta Verification (cross-verify)
- Step 4: Over-engineering Check (YAGNI/KISS)
- **Output**: `memory/plan-summary.md` (리뷰 반영 최종본), `memory/plan-review-scores.md`

**Step 4-B: Expert Plan Review — 도메인팀 Agent Team 토론**
- 5개 도메인팀 (Data/Integration/Safety/Ops/Code Design) 통합 전문가 팀
- 도메인 내 + 도메인 간 교차 토론
- CRITICAL → 계획 수정, HIGH → 주의사항 추가, MEDIUM → 기록
- Save: `expert-plan-concerns.md`
- **Output**: `memory/expert-plan-concerns.md`, `memory/plan-summary.md` (CRITICAL 반영 최종본)

**Phase A Calibration Checklist** — 7개 항목 자동 검증 후 Phase B 진입.

**Spec Capture — Propose** (조건부): Calibration 통과 후, 레포에 `openspec/`가 있으면 `openspec-propose` 스킬을 호출하여 plan-summary.md를 `openspec/changes/<branch-name>/`로 캡처한다. gate·매핑 규칙은 "OpenSpec Spec Capture (조건부)" 프로토콜 참조. openspec/ 없으면 skip.

## Phase B-E: Implementation & Verification

For detailed step instructions, read [phase-b-implementation.md](references/phase-b-implementation.md).

After Phase A, use background agents (`Agent(run_in_background=true)`) for parallel unit execution.
Each Unit: isolated git worktree. Independent Units: parallel.

**Pre-Phase**: Base branch sync → worktree 생성 → CONTEXT.md 생성
- **Output**: `CONTEXT.md`, `memory/unit-{name}/runbook.md`

**Step 5: Implementation (TDD 필수)**
- executor subagent, code-design-analysis.md 컨벤션 준수
- RED → GREEN → REFACTOR → VERIFY (전체 테스트 통과 필수)
- Agent 출력물 검증 게이트 (파일 존재 + 빌드 확인)
- **Inline Issue Capture** (P-010): 구현 중 발견된 비실패성 이슈를 즉시 `inline-issues.md`에 기록, Step 7에 전달
- **Output**: `memory/unit-{name}/test-case-summary.md`, `memory/inline-issues.md`

**Step 6: Purpose Alignment** — 구현이 요구사항과 일치하는지 검증
- **Output**: `memory/unit-{name}/alignment-verdict.md`, `memory/unit-{name}/working-example.md`

**Step 7: Bug/Security/Performance Review** — 도메인팀 Agent Team으로 구현 검증 + 사전 우려사항 대조 + Reproducibility Gate (P-007: CRITICAL/HIGH 이슈는 재현 테스트 후 수정) + 에이전트 역할별 도구 범위 명시 (P-011)
- **Output**: `memory/unit-{name}/review-findings.md`

**Step 8: Regression Verification** — Step 7 수정이 기존 기능 깨뜨리지 않았는지 확인
- **Output**: `CONTEXT.md` (갱신 — 검증 결과 반영)

**Step 8-B: 경량 Cross-Impact 체크**
변경된 파일의 importers를 grep으로 확인하여 영향받는 파일 목록을 파악한다. 예상 외 영향 파일이 발견되면 Step 17에서 architect에게 보고한다. "국소 최적화 — 한 곳 고치면 다른 곳이 깨짐" 패턴(G-WF 참조)을 구조적으로 감지한다.

**Refinement Cycle (Step 8 완료 후 — 구 Steps 9-16 대체):**
- Scan → Fix → Verify → Check 4단계 반복(max 3회), 품질 충족 시 조기 종료. 구 Steps 9-16의 개별 단계(파일/함수 분할, 재사용 리뷰, Side Effect Check, 전체 리뷰, 데드코드 정리, 품질 평가, 흐름 검증, MEDIUM 처리)는 이 사이클의 Scan 분류 항목으로 통합되었다. 상세와 Side Effect Check(구 Step 11)의 subagent 위임 원칙(caller 체인 탐색 → 요약만 반환) 정본은 [phase-b-verification.md](references/phase-b-verification.md)의 Refinement Cycle·"Side Effect Check" 섹션 참조

**Step 8-B Subagent 원칙**: importers grep 및 영향 파일 분석은 subagent에 위임하고, "영향 파일 목록 + 조치 필요 여부" 결론만 반환받는다. grep 출력 원문이 메인 컨텍스트에 축적되는 것을 방지한다.

**Step 17: Production Readiness** — `architect` + `security-reviewer` 최종 검증 + Finding Acceptance Summary 산출 (도메인별 수용률). NEEDS-HUMAN-REVIEW 판정 발생 시 gate-definitions.md의 처리 경로를 따른다 — 사람 확인 없이 Step 18 진입 금지.

## Integration & Review

> **INSTRUCTION (모든 경로 필수)**: Integration → Step 18 → Step 19는 **모든 경로**에서 반드시 실행한다. Step 18-19를 건너뛰면 인라인 코드 리뷰가 누락되어 PR 품질이 보장되지 않는다.

For detailed instructions, read [integration-and-review.md](references/integration-and-review.md).

**Integration Stage** — 모든 Unit 완료 후 브랜치 커밋, 충돌 해결, build + test 검증

**Spec Capture — Archive** (조건부): Integration build+test 통과 후 Step 18 진입 전, Propose 단계가 실행됐던 경우(openspec/ 존재) `openspec-archive-change` 스킬을 호출하여 델타를 `openspec/specs/`로 병합한다. 상세·머지 후 archive 대안은 "OpenSpec Spec Capture (조건부)" 프로토콜 참조.

**Step 18: Work Report + Review Sequence**
- 18-A: writer subagent: Before/After 다이어그램, 트레이드오프, 리스크 보고서
- 18-B: architect subagent: 논리적 변경 단위 그룹핑 + 리뷰 순서 결정

**Step 19: simon-code-review 스킬 호출**
- Step 18-B 완료 후 `simon-code-review` 스킬을 호출하여 Draft PR 생성, 인라인 코드 리뷰, CI Watch, 피드백 루프를 위임
- simon-code-review가 Completion Summary 출력 및 최종 마무리(retrospective, CONTEXT.md 갱신) 처리
- simon-code-review는 CONNECTED 모드로 자동 감지됨 (review-sequence.md 존재)

> **분해 패턴**: Step 19는 원래 simon-dev 내부에 인라인되어 있었으나, PR 리뷰가 독립적으로도 유용하여 `simon-code-review` 스킬로 추출되었다. 스킬이 비대해질 때 이 패턴(독립 호출 가능한 단계를 별도 스킬로 분리, 연결 모드/독립 모드 양립)을 참고하라.

**Step 20: Self-Improvement (별도 세션 위임)**
- Handoff Manifest를 통해 retrospective.md, user-feedback-log.md를 전달
- 새 세션에서 워크플로 전반의 종합 패턴 분석 + evaluator tuning loop 데이터 수집
- Phase-End Auto-Retrospective가 이미 Phase별 핵심 인사이트를 캡처하므로, Step 20 미실행 시에도 핵심 피드백은 보존됨
- 실행: 사용자가 `/retro`를 호출하거나, simon-dev 완료 시 자동 Handoff
- **Standup Entry**: simon-code-review 완료 시점에 이미 기록됨 (Step 19). Step 20에서는 standup을 기록하지 않는다
- **Gotcha 축적**: Phase-End Auto-Retrospective에서 이미 Phase별로 기록됨. Step 20은 Phase 간 교차 패턴에서 발견된 gotcha만 `~/.claude/projects/{slug}/state/gotchas.jsonl`에 추가로 기록한다 (중복 방지: 기존 파일을 읽어 동일 패턴이 없는 경우에만 append)
- **자기 측정**: Harness Stress Test 데이터가 5세션 이상 누적되면 Step 20 자신을 '0건 발견 80%+ 병합 후보' 평가의 1순위 대상으로 삼는다 — 이미 Standup(Step 19)·Gotcha(Phase-End)가 선행 기록되므로, 데이터가 중복을 확인하면 Step 20을 Phase-End Auto-Retrospective로 흡수한다.

### Harness Stress Test (데이터 수집)

각 Step 완료 시 workflow-state.json에 Step별 효용 데이터(발견 이슈 수, 소요 턴 수, `context_tokens_at_step_start` 버킷: `<256K`/`256K-512K`/`>512K`)를 기록한다. 5세션+ 누적 후 Step 20(또는 boost-review)에서 '0건 발견 80%+ Step'을 병합 후보로 제안한다 -- 모델 진화에 따라 불필요해진 Step을 데이터 기반으로 식별하기 위함이다. context_tokens 버킷은 Tier 1 "256K 이내 배치" 규칙(Reference Loading Policy)의 실측 검증용이다 — 버킷별 게이트 FAIL율/재작업 빈도 비교로 임계값 재검토 근거를 쌓되, 임계값 자체는 실측 근거가 쌓이기 전까지 변경하지 않는다.
단, `context-separation.md`의 Step × 원칙 매트릭스에서 Fresh Subagent/Blind-First가 표시된 Step(현재 Step 6, Step 7 Verification Layer, Step 17, Devil's Advocate)은 '0건 발견' 병합 후보 규칙에서 제외한다 — 이 Step들의 설계 목적은 새 이슈 발견이 아니라 독립 시행의 수렴으로 신뢰도를 높이는 것(Monte Carlo Verification Principle)이라, 잘 구현된 코드에서 0건 발견은 실패가 아니라 정상 동작이다. 유용성은 `[INDEPENDENT-CONFIRM]` 대 `[DISPUTED]` 비율로 별도 추적하고, 극단적 편향이 장기간 지속될 때만 사용자에게 근거와 함께 제시한다 — 자동 병합은 하지 않는다.

## Success Criteria

워크플로 완료 전 모두 검증한다. 모든 항목이 충족된 후에 완료로 판정한다.

- [ ] 모든 테스트가 RED→GREEN 사이클로 작성됨
- [ ] 전체 테스트 스위트 통과 (0 failures)
- [ ] 빌드 성공 + 타입체크 통과
- [ ] 보안 리뷰 CRITICAL 없음
- [ ] 전문가 우려사항 HIGH 이상 모두 반영됨
- [ ] 코드 리뷰 통과
- [ ] PR 리뷰 완료 — 모든 리뷰 코멘트 resolved (simon-code-review Step 5에서 검증)
- [ ] 미해결 결정사항 문서화됨
- [ ] CONTEXT.md 최종 상태 갱신됨
- [ ] retrospective.md 기록됨
- [ ] (openspec/ 있는 레포) 스펙 캡처/아카이브 완료 — `openspec/specs/` 갱신 또는 `changes/<name>/` 델타 PR 포함

검증 시점: Step 17 (기술적 항목), Step 19-C (전체 최종 검증), Step 20 (스킬 개선)

## Global Forbidden Rules

되돌릴 수 없는 피해를 방지하기 위해 ABSOLUTE FORBIDDEN / CONTEXT-SENSITIVE / AUDIT-REQUIRED 3계층으로 분류된다. hooks.PreToolUse에서 자동 차단된다. 차단 시 에러 메시지를 확인하고 안전한 대안을 탐색한다.

For full rule list and Runtime Guard (P-008), read [forbidden-rules.md](references/forbidden-rules.md).

## Session Management

스크립트: `.claude/workflow/scripts/manage-sessions.sh`
- `list` — 활성 워크트리 목록
- `info <branch>` — 세션 상세 정보
- `delete <branch>` — 세션 삭제

이전 세션 이어가기: list → info → 워크트리로 이동 → `.claude/memory/` 복원

### State Integrity Check (P-004)

세션 복원 시 memory 파일과 실제 상태의 정합성을 검증한다 (상세: simon-sessions/SKILL.md의 resume Step 2 참조):
1. `plan-summary.md`의 Unit 목록 ↔ `unit-*/` 디렉토리 일치
2. `CONTEXT.md` 진행 상태 ↔ 실제 memory 파일 존재 여부
3. `session-meta.json`의 `last_commit_hash` ↔ 실제 git HEAD
4. 불일치 시 `git log --oneline` 기반으로 실제 진행 상태를 재구성 (**Git 이력을 SSoT로 우선**)

## Context Window Management

컨텍스트 윈도우가 자동 압축(compact)되므로 토큰 예산 걱정으로 조기 중단하지 않는다. 상태는 `.claude/memory/`에 유지됨. 상세 프로토콜은 [cross-cutting-protocols.md](references/cross-cutting-protocols.md) 참조.

## Memory Persistence & Unresolved Decisions

Step 완료·agent 전환·loop rollback·Unit 완료 시 기록. Step 시작 전 관련 memory 파일 읽기 (이전 판단 복원). 미해결 결정 → `.claude/memory/unresolved-decisions.md`, Step 18에 "may bite you later" warning 포함.

## Core Reminders (전 구간 상시 적용 — 파일 끝 배치는 세션 후반 환기용, 끝부분 리마인더 페어링 패턴)

- **Stop-and-Fix Gate**: 빌드/린트/타입체크/테스트 실패 상태로 다음 파일 수정·다음 Step 진입·사용자 보고를 하지 않는다.
- **tool-call-first & 파이프라인 완주**: 하위 단계 반환 직후 같은 턴에 다음 Step의 tool call을 먼저 emit한다 (종료 내레이션으로 턴 닫기 금지). Integration → Step 18 → Step 19는 모든 경로에서 실행한다 — 인라인 코드 리뷰 누락 금지.
- **Scope 고정**: plan-summary.md 명시 변경만 구현, 범위 밖 발견은 `[Scope]` 1줄 통보 + unresolved-decisions.md 기록.
- **검증 구조 보호**: Fresh Subagent/Blind-First/Cross-Model/결정론적 게이트는 축소·병합 논의 대상이 아니다 (`context-separation.md`의 검증 지시 제거 판단 기준).
