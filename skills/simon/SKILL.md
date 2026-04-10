---
name: simon
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
3. `references_loaded` 필드에 해당 reference가 없으면 → 재로딩. 있으면 → 스킵. Compaction 감지 시 **Tier별 선택적 초기화** — Tier 1은 강제 재로딩, Tier 2는 현재 Phase에 해당하는 것만 재로딩, Tier 3는 초기화하지 않음 (on-demand 트리거로 자연스럽게 재로딩). "이전에 읽었으니 알고 있다"가 LLM 기억이 아닌 JSON 기록에 기반해야 핵심 규칙 소실을 방지한다.
4. 해당 Step 실행
5. **Step 완료 즉시** workflow-state.json 갱신 (`references_loaded` 포함)

workflow-state.json이 없으면 Startup부터 시작한다.

**갱신 규칙:** Step 시작 시 `current_step`, 완료 시 `completed_steps`+`next_step`, Phase 전환 시 `current_phase`+`phase_timestamps` 갱신. 중단/에러: `blocked: true`. SMALL skip 시 `skipped_steps` 기록. Phase A 완료 시 Done-When Checks → `done_when_checks` 배열 추출 (`verified: false` 초기값). Step 5d/6/17 검증 통과 시 `verified: true` 갱신. Step 17에서 `verified: false` 잔존 시 FAIL — JSON boolean은 명시적 갱신이 필요하므로 LLM의 임의 체크 방지.

### Cross-Session State

세션 간 구조화된 상태를 `~/.claude/projects/{slug}/state/`에 jsonl로 관리한다. Startup에서 유효 항목만 로딩하여 이전 세션의 이슈를 사전 인지한다 (상세: `cross-cutting-protocols.md`의 Cross-Session State 섹션 참조).

## Workflow Gotchas

Claude가 이 워크플로에서 반복적으로 범하는 실수. 각 항목은 실제 실패에서 추출되었다. SKILL.md에 상주하므로 compaction 후에도 소실되지 않는다. Step 20(Self-Improvement)에서 새 gotcha를 추가하여 세션을 거듭할수록 축적한다.

### G-WF-001: 계획 밖 파일 조용히 수정
executor가 plan-summary.md의 Files Changed에 없는 파일을 "관련 파일이니까" 수정한다. → Plan Immutability 절차를 따른다 (phase-b-implementation.md Critical Rules).

### G-WF-002: Behavioral Check 없이 Step 17 통과 시도
"빌드+테스트 통과 = 완료"로 판단하여 Behavioral Check의 verify command를 실행하지 않는다. → done_when_checks에 `verified: false` 항목이 있으면 G-PROD Gate FAIL.

### G-WF-003: 인터뷰에서 코드로 확인 가능한 사항을 질문
"어떤 프레임워크를 사용하나요?" 등 code-design-analysis.md로 답할 수 있는 질문을 한다. → Interview Guard + Anti-patterns 목록 참조.

### G-WF-004: compaction 후 workflow-state.json 재로딩 누락
compaction 후 현재 Step을 기억에 의존하여 이전 Step을 반복하거나 건너뛴다. → State-Driven Execution 루틴: 매 턴 시작 시 workflow-state.json 읽기 필수.

### G-WF-005: 전문가 finding을 severity 확인 없이 전부 수정
MEDIUM finding까지 모두 수정하여 scope creep이 발생한다. → CRITICAL → 계획 수정, HIGH → 주의사항 추가, MEDIUM → 기록만.

### G-WF-006: 기존 코드 패턴 불일치를 확인 없이 버그로 단정
if 브랜치와 else 브랜치에서 다른 변수명 패턴을 발견하고, git blame 확인 없이 "버그"로 단정하여 수정한다. → Intent-Before-Fix Gate (Critical Rules): git blame → git show → 커밋 전체 확인 후 의도적 설계 여부를 판단한 뒤 수정 여부를 결정한다.

### G-WF-007: 단일 레이어 함수 분석으로 최종 동작 단정
cpccpm.Throttle()이 ThrottleBy=100을 반환하는 것만 보고 "이 함수는 100을 반환한다"고 결론낸 사례처럼, 한 레이어의 반환값만 보고 시스템 전체 동작을 단정한다. → "이 함수가 X를 반환한다"고 주장하려면: (1) 해당 함수의 반환값을 직접 확인, (2) 그 함수를 호출하는 caller 코드를 grep으로 찾아 반환값이 어떻게 가공되는지 확인, (3) 최종 사용처(로그 출력, API 응답 등)까지 추적. 한 레이어만 읽고 결론 내는 것은 "검증했다"에 해당하지 않는다.

### G-WF-008: 가설 고착 — 동일 방향 3회 실패 후 가설 리셋 없이 재시도
첫 가설이 틀렸음을 시사하는 신호(동일 에러 반복, STALL 감지)에도 불구하고 같은 방향으로 계속 재시도한다. grind의 10회 재시도 환경에서 "열심히 했지만 결국 같은 방법을 10번 시도한 것"이 되는 사례. → 동일 전략으로 3회 연속 실패 시: "현재 접근의 근본 가정이 무엇인가?"를 명시적으로 자문하고, 대안 가설을 최소 2개 도출한다. grind에서는 grind-cross-cutting.md의 Hypothesis Reset Protocol을 따른다.

## Red Flags (워크플로 미준수 징후)

이 징후가 보이면 워크플로가 올바르게 실행되고 있지 않다. 즉시 멈추고 원인을 파악한다:

- workflow-state.json 갱신 없이 3개 이상의 Step을 진행함
- Plan에 없는 파일을 조용히 수정하고 있음
- "나중에 테스트 작성하겠다"고 기록함
- 100줄 이상 코드를 작성했는데 빌드/테스트를 실행하지 않음
- Step 6 Purpose Alignment을 "명백히 통과"로 건너뜀
- 전문가 리뷰에서 CRITICAL을 보고도 다음 Step으로 진행함
- "이건 간단하니까 SMALL 경로"라고 결정했지만 5개+ 파일을 수정함
- 스펙과 기존 코드가 충돌하는데 Confusion Management 없이 임의 해석으로 진행함

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

### Phase Progress Dashboard (Guidance)

Phase 전환 시 사용자에게 시각적 진행 상황을 제공한다:

```
=== Progress ===
[######....] Step {current}/{total} ({percent}%)
Phase A: DONE (4m37s) | Phase B: IN PROGRESS (12m) | Integration: PENDING
Tests: {pass}/{total} | Build: {status}
===
```

ship 모드: Phase 전환 시에만. guided 모드: AskUserQuestion 응답 시에도. interactive 모드: 매 Step 완료 시.

**Step 완료 경량 출력** (ship/guided 모드): Phase 전환 외에도 각 Step 완료 시 1줄 non-blocking 출력을 추가한다. AskUserQuestion이 아니므로 워크플로를 중단하지 않는다 — 장시간 자동 실행 중 "살아 있다"는 신호가 없으면 사용자가 불필요하게 개입할 수 있다.

형식: `[Progress] Step {N}/{total} 완료 — {Step명}`

### Stop-and-Fix Gate

빌드, 린트, 타입체크, 테스트 중 하나라도 실패하면 **반드시 수정한 후에만** 다음 파일 수정, 다음 Step 진입, 사용자 보고 등 어떤 작업도 하지 않는다. "나중에 고치겠다"는 허용되지 않는다 — 미수정 실패는 누적되어 디버깅 비용이 기하급수적으로 증가하기 때문이다.

수정 후에는 **동일 검증 명령을 재실행(Fix-Verify Loop)**하여 통과를 확인한다. 재실행에서도 실패하면 Error Resilience 프로토콜을 적용한다.

ENV_INFRA로 테스트 실행 자체가 불가능한 경우, 사용자 명시적 승인 후에만 테스트를 SKIP할 수 있으며, 이때도 build + typecheck는 반드시 통과해야 한다.


### Reference Loading Policy (컨텍스트 효율)

각 Phase 진입 시 해당 Phase의 레퍼런스 파일만 읽는다. **Tier 1 파일은 256K 토큰 이내에 로딩되어야 한다** — Opus 4.6의 정확도가 256K 이후 ~70%로 하락하므로, 핵심 규칙은 초기에 로딩하여 높은 정확도 영역에 배치한다.

| 트리거 | 읽을 파일 | Tier | 비고 |
|--------|----------|------|------|
| Startup 또는 세션 복원 시 | `cross-cutting-protocols.md` | 1 | CWM, Session Isolation 등 핵심 프로토콜 |
| Phase A 진입 | `phase-a-planning.md` | 1 | 계획 품질이 전체 파이프라인 품질을 결정 |
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

**Tier 정의:**
- **Tier 1 (Early Load)**: 256K 이내에 반드시 로딩. compaction 후에도 최우선 재로딩
- **Tier 2 (Phase Load)**: 해당 Phase 진입 시 로딩. compaction 후 현재 Phase의 Tier 2만 재로딩
- **Tier 3 (On-Demand)**: 필요 시점에만 로딩. compaction 후 재로딩 불필요 (on-demand 트리거로 자연스럽게 재로딩)

### Subagent 사용 기준

subagent는 다음 경우에 사용한다:
1. 독립적 컨텍스트가 필요한 병렬 작업
2. 다른 전문성이 필요한 역할 분리
3. 대량의 코드 탐색
4. 독립 검증이 품질을 높이는 경우 (Cognitive Independence — `context-separation.md` 참조)
   - CRITICAL/HIGH 판정의 교차 검증, 3회+ 동일 실패 반복 시 fresh perspective
   - 결정론적 검증(빌드, 테스트 실행)은 제외 — 코드 실행으로 확인 가능한 것에 subagent를 쓰지 않음

단일 파일 수정, 간단한 검색, 단순 명령 실행은 직접 수행한다. 불필요한 subagent 생성은 컨텍스트를 낭비한다.

**역할별 도구 범위, maxTurns, 반환 규약:**
Agent spawn 시 [agent-capability-matrix.md](references/agent-capability-matrix.md) 참조. Spawn Prompt Template과 Status Prefix 규약을 포함한다.

### Multi-Agent Saturation Guard

multi-agent 구조(Agent Team, Devil's Advocate, Verification Layer)는 단일 에이전트로 달성 불가능한 품질을 제공하지만 overhead도 동반한다. 다음 조건에서 multi-agent를 축소하여 비용 대비 효과를 최적화한다:

**축소 조건** (하나라도 해당 시):
- Step 7에서 CRITICAL/HIGH 0건 + MEDIUM 3건 이하 → Devil's Advocate skip
- Step 4-B findings 5건 이하 + CRITICAL 0건 → Verification Layer를 single verifier로 축소 (Blind-First는 유지)
- 이전 5세션 Harness Stress Test에서 특정 multi-agent Step의 추가 발견율 10% 미만 → optional 전환, Decision Journal에 근거 기록

**축소 불가** (multi-agent 필수):
- config.yaml의 high_impact_paths 매칭 파일 포함
- STANDARD+ 경로의 Step 7 Verification Layer
- LARGE 경로의 모든 multi-agent Step

### Over-engineering 방지

plan-summary.md에 명시된 변경만 구현한다. 범위 밖 개선(docstring, 주석, 타입 어노테이션 등)을 발견하면 `.claude/memory/unresolved-decisions.md`에 기록만 한다 — 범위 밖 수정은 리뷰어의 인지 부하를 높이고, 의도치 않은 동작 변경 위험이 있으며, PR의 변경 범위가 불명확해져 승인이 지연되기 때문이다.

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

스킬 전환 시 `{SESSION_DIR}/memory/handoff-manifest.json`을 생성하여 컨텍스트 전달을 결정론적으로 보장한다. 필드: `from_skill`, `to_skill`, `trigger_step`, `transfer_files`(로딩할 파일), `block_files`(로딩 금지), `context_note`, `session_dir`. 수신 스킬은 transfer_files만 로딩하고 block_files는 제외 — What-not-Why Handoff 규칙이 내장되어 Cognitive Independence 위반을 구조적으로 방지한다.

### AskUserQuestion Standard Format (Guidance)

For AskUserQuestion format, read [generation-style-guide.md](references/generation-style-guide.md).

### Docs-First Protocol

라이브러리·DB·프레임워크·외부 서비스 사용 시 공식 문서를 먼저 조회한다.
For detailed protocol (적용 기준, 도구 우선순위, 조회 불가 시 대응), read [docs-first-protocol.md](references/docs-first-protocol.md).

### Interaction Mode

config.yaml의 `interaction_mode` 설정에 따라 사용자 인터랙션 수준을 조절한다:

- **ship**: test failure, build failure, CRITICAL security finding, merge conflict에서만 정지. 나머지는 AI 자동 결정 + Decision Journal 기록. "한 번 입력 후 PR URL까지."
- **guided** (기본값): 핵심 판단점(경로 선택, CRITICAL 이슈)에서만 AskUserQuestion. 대부분 자동 진행.
- **interactive**: 모든 AskUserQuestion 유지. 현재 동작과 동일.

Startup에서 `config.yaml`의 `interaction_mode`를 읽고, 없으면 `guided`를 기본값으로 사용한다.

## Startup

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
- 3 review paths 제시 (SMALL / STANDARD / LARGE)
- SMALL 판별 시 **Fast Track** 적용: Phase A 압축 실행 (상세: phase-a-planning.md)

**Step 1-A: Project Analysis + Code Design Analysis**
- subagent: 프로젝트 구조 스캔 + 분석
- Context7 MCP로 라이브러리 문서 조회
- **Agent Team: Code Design Team** — convention/idiom/design-pattern/testability experts 토론
- Save: `requirements.md`, `code-design-analysis.md`

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

**Step 1-B-ext: Plan HTML 렌더링 (Report Viewer 통합)**

> **통합 프로토콜**: `~/.claude/skills/_shared/report-viewer/integration-guide.md` 참조

plan-summary.md 저장 직후 HTML Report Viewer를 실행하여 사용자가 계획서를 시각적으로 검토할 수 있게 한다.

```bash
REPORT_VIEWER="$HOME/.claude/skills/_shared/report-viewer/render-report.sh"
if [ -x "$REPORT_VIEWER" ]; then
  $REPORT_VIEWER "{SESSION_DIR}/memory/plan-summary.md" --open
fi
```

Viewer 활성 시: "계획서를 브라우저에서 열었습니다. Steps 2-4 자동 리뷰와 병행하여 확인해주세요." 안내 후 Steps 2-4 진행. Steps 2-4 완료 후 코멘트 피드백 루프(integration-guide.md)를 실행하여 사용자 피드백 수집.

Viewer 미활성 시: 기존 방식대로 터미널에 계획서를 출력하고 진행.

**Steps 2-4: Plan Review (Agent Team)**
- planner + critic + architect 직접 토론
- Step 2: Plan Review (max 3 iterations)
- Step 3: Meta Verification (cross-verify)
- Step 4: Over-engineering Check (YAGNI/KISS)

**Step 4-B: Expert Plan Review — 도메인팀 Agent Team 토론**
- 5개 도메인팀 (Data/Integration/Safety/Ops/Code Design) 통합 전문가 팀
- 도메인 내 + 도메인 간 교차 토론
- CRITICAL → 계획 수정, HIGH → 주의사항 추가, MEDIUM → 기록
- Save: `expert-plan-concerns.md`

**Phase A Calibration Checklist** — 7개 항목 자동 검증 후 Phase B 진입.

## Phase B-E: Implementation & Verification

For detailed step instructions, read [phase-b-implementation.md](references/phase-b-implementation.md).

After Phase A, use background agents (`Agent(run_in_background=true)`) for parallel unit execution.
Each Unit: isolated git worktree. Independent Units: parallel.

**Pre-Phase**: Base branch sync → worktree 생성 → CONTEXT.md 생성

**Step 5: Implementation (TDD 필수)**
- executor subagent, code-design-analysis.md 컨벤션 준수
- RED → GREEN → REFACTOR → VERIFY (전체 테스트 통과 필수)
- Agent 출력물 검증 게이트 (파일 존재 + 빌드 확인)
- **Inline Issue Capture** (P-010): 구현 중 발견된 비실패성 이슈를 즉시 `inline-issues.md`에 기록, Step 7에 전달

**Step 6: Purpose Alignment** — 구현이 요구사항과 일치하는지 검증

**Step 7: Bug/Security/Performance Review** — 도메인팀 Agent Team으로 구현 검증 + 사전 우려사항 대조 + Reproducibility Gate (P-007: CRITICAL/HIGH 이슈는 재현 테스트 후 수정) + 에이전트 역할별 도구 범위 명시 (P-011)

**Step 8: Regression Verification** — Step 7 수정이 기존 기능 깨뜨리지 않았는지 확인

**Step 8-B (SMALL path only): 경량 Cross-Impact 체크**
변경된 파일의 importers를 grep으로 확인하여 영향받는 파일 목록을 파악한다. 예상 외 영향 파일이 발견되면 Step 17에서 architect에게 보고한다. "국소 최적화 — 한 곳 고치면 다른 곳이 깨짐" 패턴(G-WF 참조)을 SMALL 경로에서도 구조적으로 감지한다.

--- SMALL path skips to Step 17 ---

**Steps 9-16** (STANDARD+ only):
- Step 9: File/Function Splitting
- Step 10: Integration/Reuse Review
- Step 11: Side Effect Check
- Step 12: Full Change Review (code-reviewer subagent)
- Step 13: Dead Code Cleanup
- Step 14: Code Quality Assessment
- Step 15: Flow Verification
- Step 16: MEDIUM Issue Resolution

**Step 17: Production Readiness** — `architect` + `security-reviewer` 최종 검증 + Finding Acceptance Summary 산출 (도메인별 수용률)

## Integration & Review

> **INSTRUCTION (모든 경로 필수)**: Integration → Step 18 → Step 19는 SMALL/STANDARD/LARGE **모든 경로**에서 반드시 실행한다. SMALL path가 skip하는 것은 Step 9-16(Refinement Cycle)뿐이다. Step 18-19를 건너뛰면 인라인 코드 리뷰가 누락되어 PR 품질이 보장되지 않는다.

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
