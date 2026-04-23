---
name: simon-dev
description: "19-step 딥 워크플로 — 계획, 구현, 검증을 최고 수준의 엄격함으로 수행합니다. Use when: (1) 새 기능/피처 구현 (\"피처 구현해줘\", \"새 기능 만들어줘\", \"코드 작성해줘\"), (2) 전문가 리뷰 패널이 필요한 체계적 계획 수립, (3) git worktree 기반 병렬 실행, (4) PR 전 종합 코드 검증이 필요할 때. 체계적 계획-구현-검증 사이클이 필요한 피처 구현에 적합합니다. Don't use when: 분석만 필요 → simon-report. 3개+ 기능 프로젝트 관리 → simon-pm. '끝까지 해결해' 등 끈질긴 해결 요청 → simon-grind."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
  skills: [simplify, git-commit]
---

# simon

Deep workflow skill with 19-step quality pipeline.

## Instructions

You are executing the **simon** deep workflow. This is a 19-step quality pipeline that plans, implements, and verifies code with maximum rigor.

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

모든 소스코드 수정 후 빌드/린트를 즉시 실행한다. 실패 시 Stop-and-Fix Gate 적용. Forbidden Rules는 `forbidden-guard.sh` (PreToolUse), 빌드 검증은 `auto-verify.sh` (PostToolUse)로 구조적 강제. 구현 일단락 시점에서 `/simplify` 실행. 상세 동작과 settings.json 등록은 [cross-cutting-protocols.md](references/cross-cutting-protocols.md) 참조.

### Deterministic Gate Principle

게이트 검증에서 파일 존재 확인, 빌드/린트/테스트 실행, 패턴 매칭, 카운터 비교 등 결정론적으로 수행 가능한 작업은 bash 스크립트를 우선 사용한다. LLM은 스크립트 실행 결과(PASS/FAIL + 실패 항목)만 받아 후속 판단(수정 방향, 전략 전환)에 집중한다. 결정론적 검증을 LLM 기억에 의존하면, 컨텍스트 압축 시 규칙이 소실되어 게이트가 무력화될 수 있기 때문이다.

### Composable CLI Script Toolkit

`workflow/scripts/`의 스크립트는 구조화된 출력, 파이프 호환, 자기 문서화, 컨텍스트 전처리를 따른다.
For detailed principles, read [cross-cutting-protocols.md](references/cross-cutting-protocols.md).

### Monitor Protocol (대시보드 연동) — 필수

> **Shared Protocol**: `~/.claude/skills/_shared/monitor-protocol.md` 읽기.

**Step Lifecycle**: ① `step_start` 발신 → ② 본 작업 수행 → ③ 중간 이벤트 즉시 발신 → ④ `step_complete` 발신. 발신 명령: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh <type> <step> <title> [data_json]`. Reference 파일의 `▶ EMIT` 마커 위치에서 해당 이벤트를 발신한다. 발신 실패는 워크플로를 중단하지 않지만, 발신 자체를 건너뛰는 것은 금지.

### Phase Progress Dashboard

Phase 전환 시 `[######....] Step {current}/{total} ({percent}%)` 형식으로 진행 상황을 출력한다. 각 Step 완료 시 `[Progress] Step {N}/{total} 완료 — {Step명}` 1줄 경량 출력을 추가한다 (ship/guided 모드).

### Stop-and-Fix Gate

빌드, 린트, 타입체크, 테스트 중 하나라도 실패하면 **반드시 수정한 후에만** 다음 파일 수정, 다음 Step 진입, 사용자 보고 등 어떤 작업도 하지 않는다. "나중에 고치겠다"는 허용되지 않는다 — 미수정 실패는 누적되어 디버깅 비용이 기하급수적으로 증가하기 때문이다.

수정 후에는 **동일 검증 명령을 재실행(Fix-Verify Loop)**하여 통과를 확인한다. 재실행에서도 실패하면 Error Resilience 프로토콜을 적용한다.

ENV_INFRA로 테스트 실행 자체가 불가능한 경우, 사용자 명시적 승인 후에만 테스트를 SKIP할 수 있으며, 이때도 build + typecheck는 반드시 통과해야 한다.


### Reference Loading Policy (컨텍스트 효율)

각 Phase 진입 시 해당 Phase의 레퍼런스 파일만 읽는다. **Tier 1 파일은 256K 토큰 이내에 로딩되어야 한다** — Opus 4.6의 정확도가 256K 이후 ~70%로 하락하므로, 핵심 규칙은 초기에 로딩하여 높은 정확도 영역에 배치한다.

| 트리거 | 읽을 파일 | Tier | 비고 |
|--------|----------|------|------|
| Startup 또는 세션 복원 시 | `cross-cutting-protocols.md` | 1 | CWM, Session Isolation 등 핵심 프로토콜 |
| Startup 또는 세션 복원 시 | `gotchas.md` | 1 | 워크플로 실수 패턴 + Red Flags |
| Phase A 진입 | `phase-a-planning.md` | 1 | 계획 품질이 전체 파이프라인 품질을 결정 |
| Phase A Steps 2-4, 4-B, Calibration 진입 | `phase-a-review.md` | 1 | Plan Review, Expert Review, Calibration Checklist 상세 지침 |
| Phase B-E 구현 진입 | `phase-b-implementation.md` | 1 | TDD, Critical Rules 등 구현 핵심 |
| Phase B-E 검증 진입 (Step 6+) | `phase-b-verification.md` | 2 | Step 6+ 진입 시 로딩 |
| Integration/Review 진입 | `integration-and-review.md` | 2 | 후반 단계 |
| Step 6/7/17 검증 진입 시 | `context-separation.md` | 2 | 검증 시에만 필요 |
| Step 6/7/17 검증 진입 시 | `review-rubric.md` | 2 | 검증 시에만 필요 |
| Agent Team 생성 시 | `agent-teams.md` | 3 | on-demand |
| 에러 발생 시 | `error-resilience.md` | 3 | on-demand |
| 전문가 팀 findings 작성 시 | `expert-output-schema.md` | 3 | on-demand |
| Forbidden Rules 참조 필요 시 | `forbidden-rules.md` | 3 | PreToolUse 훅으로 구조적 강제됨 |
| 외부 라이브러리/서비스 사용 시 | `docs-first-protocol.md` | 3 | on-demand |
| Gate 조건 참조 필요 시 | `gate-definitions.md` | 3 | on-demand |
| 산출물 생성 시 (Step 1-B, 18) | `generation-style-guide.md` | 3 | on-demand |
| 코드 탐색 시 (`graphify-out/` 존재 시) | `~/.claude/skills/_shared/graphify-context.md` | 3 | on-demand, 그래프 없으면 skip |
| Startup (3-E 단계) | `~/.claude/skills/_shared/monitor-protocol.md` | 2 | Startup 필수. emit.sh 실패는 허용하되 발신 시도 자체는 건너뛰지 않음 |

**Tier 정의:**
- **Tier 1 (Early Load)**: 256K 이내에 반드시 로딩. compaction 후에도 최우선 재로딩
- **Tier 2 (Phase Load)**: 해당 Phase 진입 시 로딩. compaction 후 현재 Phase의 Tier 2만 재로딩
- **Tier 3 (On-Demand)**: 필요 시점에만 로딩. compaction 후 재로딩 불필요 (on-demand 트리거로 자연스럽게 재로딩)

**Phase 전환 시 Tier 2 Unload 규칙**:

Phase 전환이 완료되면 (workflow-state.json의 `current_phase` 갱신 후), 이전 Phase에서만 사용된 Tier 2 파일은 컨텍스트 attention 영역에서 해제한다. "해제"는 파일을 삭제하는 것이 아니라, 이후 스텝에서 해당 파일의 내용을 참조하지 않음을 의미한다 — 파일은 SESSION_DIR에 영구 보존된다.

| Phase 전환 | 언로드 대상 (Tier 2) | 이유 |
|-----------|---------------------|------|
| Phase A → Phase B 진입 | `phase-a-review.md`, `context-separation.md`(Step 6 전까지), `review-rubric.md`(Step 6 전까지) | Phase B 구현 단계에서 Phase A 검토 지침은 불필요 |
| Step 5 완료 → Step 6 진입 | `phase-b-implementation.md`의 TDD 섹션 상세 | Step 6부터는 검증 중심으로 전환 |
| Integration 단계 진입 | `phase-b-verification.md`, `phase-b-implementation.md` 등 Phase B 전용 Tier 2 | Integration은 별도 컨텍스트 필요 |

**컨텍스트 활용률 45% 이상일 때 Phase 전환 시**: 즉시 `/compact`를 실행하며 이전 Phase Tier 2를 보존 프롬프트에서 명시적으로 제외한다. 구체적인 compact hint는 `cross-cutting-protocols.md`의 Phase별 Compact Hint 테이블을 참조한다.

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

단일 파일 수정, 간단한 검색, 단순 명령 실행은 직접 수행한다. 불필요한 subagent 생성은 컨텍스트를 낭비한다.

**Result-Only 반환 원칙** (오케스트레이터 컨텍스트 보호):

Subagent spawn 전에 리트머스 테스트를 적용한 뒤, 아래 반환 규약을 준수한다.

| 반환해야 하는 것 | 반환하지 말아야 하는 것 |
|-----------------|------------------------|
| PASS/FAIL 판정 + 근거 1~3줄 | 전체 빌드 로그 |
| 발견된 이슈 목록 (severity + 파일경로) | grep 원본 결과 |
| 권장 액션 (구체적) | 탐색 과정의 중간 파일 내용 |
| 저장한 파일 경로 목록 | agent 내부 토론 기록 |

**Spawn Prompt 필수 문구** (`full_output: true` 제외): `"결론과 필수 액션만 반환하라. 발견한 내용은 {파일경로}에 저장하고, 반환값은 'STATUS: PASS/FAIL, 발견 {N}건, 저장: {파일경로}'로 제한한다."`

**역할별 도구 범위, maxTurns, 반환 규약:**
Agent spawn 시 [agent-capability-matrix.md](references/agent-capability-matrix.md) 참조. Spawn Prompt Template과 Status Prefix 규약을 포함한다.

### Multi-Agent Saturation Guard

multi-agent 구조(Agent Team, Devil's Advocate, Verification Layer)는 단일 에이전트로 달성 불가능한 품질을 제공하지만 overhead도 동반한다. 다음 조건에서 multi-agent를 축소하여 비용 대비 효과를 최적화한다:

**축소 조건** (하나라도 해당 시):
- Step 4-B findings 5건 이하 + CRITICAL 0건 → Verification Layer를 single verifier로 축소 (Blind-First는 유지)
- 이전 5세션 Harness Stress Test에서 특정 multi-agent Step의 추가 발견율 10% 미만 → optional 전환, Decision Journal에 근거 기록

**축소 불가** (multi-agent 필수):
- config.yaml의 high_impact_paths 매칭 파일 포함
- Step 7 Verification Layer
- LARGE 경로의 모든 multi-agent Step

### Over-engineering 방지

plan-summary.md에 명시된 변경만 구현한다. 범위 밖 개선(docstring, 주석, 타입 어노테이션 등)을 발견하면 `.claude/memory/unresolved-decisions.md`에 기록만 한다 — 범위 밖 수정은 리뷰어의 인지 부하를 높이고, 의도치 않은 동작 변경 위험이 있으며, PR의 변경 범위가 불명확해져 승인이 지연되기 때문이다.

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

스킬 전환(simon → simon-code-review 등) 시 사용자에게 1줄 통보를 출력한다. 갑작스러운 스킬 전환으로 인한 사용자 혼란을 방지한다.

형식: `[Handoff] {현재 스킬} → {다음 스킬}: {목적 1줄 설명}`
예시: `[Handoff] simon → simon-code-review: Draft PR 생성 및 코드 리뷰 진행합니다.`

### On-Demand Session Hooks

사용자가 세션 중간에 명시적으로 활성화하면 세션 종료까지 지속되는 동적 제약이다. `{SESSION_DIR}/memory/session-modifiers.json`에 기록되고, `forbidden-guard.sh`가 참조하여 추가 제약을 적용한다.

- **`/careful`**: CONTEXT-SENSITIVE 규칙을 ABSOLUTE로 격상. git push, 외부 API, DB 명령 등이 모두 차단된다 — 프로덕션 인접 코드 작업 시 안전 수준을 높이기 위함이다.
- **`/freeze <dir>`**: 지정된 디렉토리 외 파일의 Edit/Write를 차단한다 — 대규모 코드베이스에서 의도치 않은 파일 수정을 결정론적으로 방지한다.
- **`/scope-lock`**: plan-summary.md의 NOT in scope 항목에 해당하는 파일 수정을 차단한다 — grind의 10회 재시도 중 scope creep을 사전에 방지한다.

Startup에서 이전 세션의 `session-modifiers.json`을 복원하여 활성 hooks를 유지한다. 세션 종료 시 자동 해제되어 일반 작업에 불필요한 마찰을 주지 않는다.

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

### Interaction Mode

config.yaml의 `interaction_mode` 설정에 따라 사용자 인터랙션 수준을 조절한다:

- **ship**: test failure, build failure, CRITICAL security finding, merge conflict에서만 정지. 나머지는 AI 자동 결정 + Decision Journal 기록. "한 번 입력 후 PR URL까지."
- **guided** (기본값): 핵심 판단점(경로 선택, CRITICAL 이슈)에서만 AskUserQuestion. 대부분 자동 진행.
    - **자율 완주 범위 (사용자 확인 불필요)**: 커밋 생성, 브랜치 푸시, PR Draft 생성, Integration Stage의 merge/rebase, emit.sh 발신, session 파일 갱신, worktree upstream 설정, 테스트·빌드 재시도. 이 단계들은 파이프라인의 기계적 실행 단계이며, 사용자 판단이 필요한 핵심 판단점이 아니다. AskUserQuestion을 사용하면 파이프라인 자율성이 깨지고 "한 번 입력 후 PR URL까지"라는 ship 철학이 무너진다.
    - **확인이 필요한 핵심 판단점**: Scope Challenge 경로 선택(STANDARD vs LARGE), CRITICAL 보안/데이터 이슈 발견, plan 단계의 비즈니스 결정, merge conflict, 실패 재시도 한계 초과 후 전략 전환.
- **interactive**: 모든 AskUserQuestion 유지. 현재 동작과 동일.

Startup에서 `config.yaml`의 `interaction_mode`를 읽고, 없으면 `guided`를 기본값으로 사용한다.

## Startup

> **HARD GATE**: Startup은 건너뛸 수 없다. 사용자가 즉시 구현을 요청하더라도, Startup이 완료되지 않은 상태에서 Phase A 또는 그 이후 단계에 진입하는 것은 절대 금지다. SESSION_DIR 초기화, workflow-state.json 생성, Monitor workflow_start 발신이 완료된 후에만 다음 단계로 진행한다. "이미 안다", "이번엔 급하니까"는 Startup 생략 사유가 되지 않는다.

Startup 단계는 순서 의존성이 있으므로 순차 실행한다.

1. `.claude/workflow/` 존재 확인. 없으면: `bash ~/.claude/skills/simon/install.sh --project-only`
2. 워크플로 파일 읽기 (parallel OK):
   - `.claude/workflow/config.yaml`
   - `.claude/memory/retrospective.md` (있으면)
   - `.claude/project-memory.json` (있으면 Read — 이전 세션에서 학습된 빌드 에러 패턴, 테스트 환경 quirk, 기각된 접근법 포함)
   - `.claude/memory/handoff-manifest.json` (있으면 — P-009 Handoff 감지)
2-B. **Prior Context Brief** (P-001): 사용자 요청에서 키워드를 추출하고, `~/.claude/projects/{slug}/state/decisions.jsonl`에서 관련 결정사항을 검색하여 Prior Context Brief를 합성한다.
   ```bash
   # 키워드 추출 후 jq로 decisions.jsonl 검색
   jq -s --arg kw "{keyword}" '[.[] | select(.decision | ascii_downcase | contains($kw | ascii_downcase))] | sort_by(.timestamp) | reverse | .[0:5]' decisions.jsonl
   ```
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
3-E. **Monitor 자동 시작 + 주소 통보 + workflow_start 발신**: 단일 공유 서버 설계 (세션마다 별도 서버 안 띄움, 포트 충돌은 3847→3857 폴백). 상세 bash 블록과 workflow_start 이벤트 스키마는 [startup-bootstrap.md](references/startup-bootstrap.md)의 "Monitor 자동 시작" 및 "workflow_start 발신" 섹션 참조.
   - **통보 의무**: 실제 포트를 포함한 한 줄 통보 `[Monitor] {상태} — http://localhost:{포트}` 필수. 이 통보가 없으면 사용자가 대시보드에 접근 불가.
3-F. **Startup Completion Gate** — Deterministic Gate Principle 적용. bash로 필수 파일 존재와 monitor 실행을 확인한 후에만 Phase A 진입. 상세 bash 스크립트는 [startup-bootstrap.md](references/startup-bootstrap.md)의 "Startup Completion Gate" 섹션 참조.
   필수: workflow-state.json + session-meta.json 존재. 선택: Monitor URL 통보 완료, workflow_start 이벤트 발신 시도 완료. FAIL 시 해당 단계로 돌아가 재수행.
4. **Handoff Manifest 처리** (P-009): `.claude/memory/handoff-manifest.json`이 존재하면:
   - `context_files`를 자동 로딩하여 컨텍스트 복원
   - `skip_steps`에 명시된 Step은 건너뛰기
   - `failure_context`가 있으면 `failure-log.md` 초기값으로 설정
   - `force_path`가 있으면 Step 0 Scope Challenge를 skip하고 해당 경로로 직행 (단, `config.yaml`의 `high_impact_paths`에 매칭되는 파일이 포함되면 STANDARD 이상을 강제)
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

**Step 0: Scope Challenge**
- `architect` agent: git history 분석, 최소 변경 결정, scope 판별
- 2 review paths 제시 (STANDARD / LARGE)
- **Output**: `memory/codebase-health.md`, `memory/plan-summary.md` (scope section)

**Step 1-A: Project Analysis + Code Design Analysis**
- `graphify-out/GRAPH_REPORT.md` 존재 시: `~/.claude/skills/_shared/graphify-context.md` 읽기 → god nodes/communities로 전체 구조 선파악 후 탐색 범위 축소
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

**Steps 9-16:**
- Step 9: File/Function Splitting
- Step 10: Integration/Reuse Review
- Step 11: Side Effect Check — **subagent 위임**: 변경 파일의 caller 체인 탐색(Grep + Read) 결과를 요약만 반환. 중간 탐색 출력은 subagent 컨텍스트에서 소비
- Step 12: Full Change Review (code-reviewer subagent)
- Step 13: Dead Code Cleanup
- Step 14: Code Quality Assessment
- Step 15: Flow Verification
- Step 16: MEDIUM Issue Resolution

**Step 8-B Subagent 원칙**: importers grep 및 영향 파일 분석은 subagent에 위임하고, "영향 파일 목록 + 조치 필요 여부" 결론만 반환받는다. grep 출력 원문이 메인 컨텍스트에 축적되는 것을 방지한다.

**Step 17: Production Readiness** — `architect` + `security-reviewer` 최종 검증 + Finding Acceptance Summary 산출 (도메인별 수용률)

## Integration & Review

> **INSTRUCTION (모든 경로 필수)**: Integration → Step 18 → Step 19는 **모든 경로**에서 반드시 실행한다. Step 18-19를 건너뛰면 인라인 코드 리뷰가 누락되어 PR 품질이 보장되지 않는다.

For detailed instructions, read [integration-and-review.md](references/integration-and-review.md).

**Integration Stage** — 모든 Unit 완료 후 브랜치 커밋, 충돌 해결, build + test 검증

**Step 18: Work Report + Review Sequence**
- 18-A: writer subagent: Before/After 다이어그램, 트레이드오프, 리스크 보고서
- 18-B: architect subagent: 논리적 변경 단위 그룹핑 + 리뷰 순서 결정

**Step 19: simon-code-review 스킬 호출**
- Step 18-B 완료 후 `simon-code-review` 스킬을 호출하여 Draft PR 생성, 인라인 코드 리뷰, CI Watch, 피드백 루프를 위임
- simon-code-review가 Completion Summary 출력 및 최종 마무리(retrospective, CONTEXT.md 갱신) 처리
- simon-code-review는 CONNECTED 모드로 자동 감지됨 (review-sequence.md 존재)

> **분해 패턴**: Step 19는 원래 simon 내부에 인라인되어 있었으나, PR 리뷰가 독립적으로도 유용하여 `simon-code-review` 스킬로 추출되었다. 스킬이 비대해질 때 이 패턴(독립 호출 가능한 단계를 별도 스킬로 분리, 연결 모드/독립 모드 양립)을 참고하라.

**Step 20: Self-Improvement (별도 세션 위임)**
- Handoff Manifest를 통해 retrospective.md, user-feedback-log.md를 전달
- 새 세션에서 워크플로 전반의 종합 패턴 분석 + evaluator tuning loop 데이터 수집
- Phase-End Auto-Retrospective가 이미 Phase별 핵심 인사이트를 캡처하므로, Step 20 미실행 시에도 핵심 피드백은 보존됨
- 실행: 사용자가 `/retro`를 호출하거나, simon 완료 시 자동 Handoff
- **Standup Entry**: simon-code-review 완료 시점에 이미 기록됨 (Step 19). Step 20에서는 standup을 기록하지 않는다
- **Gotcha 축적**: Phase-End Auto-Retrospective에서 이미 Phase별로 기록됨. Step 20은 Phase 간 교차 패턴에서 발견된 gotcha만 `~/.claude/projects/{slug}/state/gotchas.jsonl`에 추가로 기록한다 (중복 방지: 기존 파일을 읽어 동일 패턴이 없는 경우에만 append)

### Harness Stress Test (데이터 수집)

각 Step 완료 시 workflow-state.json에 Step별 효용 데이터(발견 이슈 수, 소요 턴 수)를 기록한다. 5세션+ 누적 후 Step 20(또는 boost-review)에서 '0건 발견 80%+ Step'을 병합 후보로 제안한다 -- 모델 진화에 따라 불필요해진 Step을 데이터 기반으로 식별하기 위함이다.

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
