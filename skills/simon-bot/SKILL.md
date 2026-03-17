---
name: simon-bot
description: "19-step 딥 워크플로 — 계획, 구현, 검증을 최고 수준의 엄격함으로 수행합니다. Use when: (1) 새 기능/피처 구현 (\"피처 구현해줘\", \"새 기능 만들어줘\", \"코드 작성해줘\"), (2) 전문가 리뷰 패널이 필요한 체계적 계획 수립, (3) git worktree 기반 병렬 실행, (4) PR 전 종합 코드 검증이 필요할 때. 코드 변경이 수반되는 모든 중대한 작업에 이 스킬을 사용하세요."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
  skills: [simplify, git-commit]
---

# simon-bot

Deep workflow skill with 19-step quality pipeline.

## Instructions

You are executing the **simon-bot** deep workflow. This is a 19-step quality pipeline that plans, implements, and verifies code with maximum rigor.

## State-Driven Execution

**매 턴(응답) 시작 시 반드시 실행하는 루틴** — compaction, 세션 재개, 작업 전환 후 복귀 등 어떤 상황에서도 적용된다. 이 루틴이 없으면 compaction 후 현재 위치를 잃고 이전 Step을 반복하거나 건너뛸 수 있다:

1. `{SESSION_DIR}/memory/workflow-state.json` 읽기
2. `current_step`에 해당하는 Phase의 reference 로딩
3. 해당 Step 실행
4. **Step 완료 즉시** workflow-state.json 갱신

workflow-state.json이 없으면 Startup부터 시작한다.

```json
{
  "current_phase": "A",
  "current_step": "0",
  "scope": null,
  "completed_steps": [],
  "next_step": "0",
  "blocked": false,
  "blocked_reason": null,
  "last_updated": "2026-03-17T00:00:00+09:00"
}
```

**갱신 규칙:**
- Step 시작: `current_step` 갱신
- Step 완료: `completed_steps`에 추가, `next_step` 갱신
- Phase 전환: `current_phase` 갱신
- 중단/에러: `blocked: true`, `blocked_reason` 기록
- SMALL path에서 Steps 9-16 skip 시: `skipped_steps`에 기록, `skip_reason` 명시

## Cross-Cutting Protocols

이 섹션의 프로토콜은 두 종류로 나뉜다:
- **Instruction** (행동 지시): 특정 상황에서 반드시 수행해야 할 구체적 행동. 무시하면 워크플로가 깨진다.
  - Auto-Verification Hook, Stop-and-Fix Gate, Deterministic Gate Principle, Step Transition Gate
- **Guidance** (행동 규범): 전반적으로 따라야 할 원칙이지만 상황에 따라 유연하게 적용 가능. 무시하면 품질이 저하된다.
  - Over-engineering 방지, Parallel Tool Invocation, Prompt Altitude Calibration, Docs-First Protocol

LLM은 두 종류를 구분하지 못하면 모든 것을 Guidance로 취급하여 중요한 게이트를 건너뛸 수 있다. Instruction을 명시적으로 식별하여 준수율을 높인다.

### Error Resilience

모든 실패를 ENV_INFRA / CODE_LOGIC / WORKFLOW_ERROR로 분류한 후 자동 복구한다. 사용자가 명시적으로 중단을 요청하지 않는 한 워크플로를 중단하지 않는다.
For detailed protocol, read [error-resilience.md](references/error-resilience.md).

### Session Isolation Protocol

동시에 여러 세션이 같은 레포에서 작업할 때 런타임 파일의 충돌을 방지한다. 세션별 런타임 데이터를 홈 디렉토리에 격리 저장한다.
For detailed protocol (SESSION_DIR 결정, 경로 매핑, PM 파견 시 결과 경로), read [cross-cutting-protocols.md](references/cross-cutting-protocols.md).

### Agent Teams

이 워크플로는 Agent Teams 기능을 우선 사용한다 (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필요). TeamCreate 실패 시 subagent 기반 fallback으로 자동 전환한다.

For lifecycle, rules, fallback, termination protocol details, read [agent-teams.md](references/agent-teams.md).

Agent Team 운영 중 오케스트레이터는 TaskList를 주기적으로 확인하여 사용자에게 진행 상황을 보고한다. 상세 프로토콜은 `agent-teams.md`의 Heartbeat Protocol 섹션 참조.

### Cognitive Independence

검증 에이전트가 진정한 독립성을 유지하려면 구조적 분리(별도 subagent)만으로 부족하다 — 인지적 독립(Blind-First, Adversarial Default, Fresh Subagent, What-not-Why Handoff)이 필요하다.
For detailed protocol, read [context-separation.md](references/context-separation.md).

### Decision Journal

주요 판단 지점(경로 선택, 전문가 합의, 재시도 결정)에서 사용자에게 1줄 판단 근거를 제시하고, `.claude/memory/decision-journal.md`에 누적 기록한다.

사용자 출력 형식 예시 (P-004):
- `[Decision] SMALL 경로 선택 — 변경 파일 3개, 외부 연동 없음.`
- `[Decision] STANDARD 경로 — 변경 파일 8개, 외부 API 1개 연동.`
- `[Decision] Step 7 CRITICAL 수정 완료 → Step 8 — SQL injection 파라미터 바인딩 수정.`
- `[Decision] Plan 수정 거부 — 캐시 레이어 추가는 과도, YAGNI 적용.`

파일 기록 형식 (append):
```
| Step | Decision | Chosen | Rejected | Rationale |
|------|----------|--------|----------|-----------|
| 0 | 경로 선택 | SMALL | STANDARD, LARGE | 변경 파일 3개, 외부 연동 없음 |
```

**Anti-Oscillation Rule**: 새로운 결정을 내리기 전에 decision-journal.md를 확인한다. 이전에 명시적으로 기각한 접근법(Rejected 열)을 다시 선택하려면, 이전 기각 시점 이후에 새로운 정보가 발생했음을 기록해야 한다. "다시 해보자"는 허용되지 않는다 — "X 정보가 새로 확인되었으므로 이전 기각 사유가 무효화되어 다시 시도한다"만 허용된다.

### Auto-Verification Hook (P-001)

모든 소스코드 파일 수정(Edit/Write) 후, `verify-commands.md`의 빌드/린트 명령을 즉시 실행한다. Phase B-E 전체에 적용되는 자동 피드백 루프다.

- **빌드+린트**: 항상 실행
- **테스트**: 변경된 파일과 관련된 테스트만 실행 (전체 스위트는 Step 5d VERIFY에서)
- **실패 시**: **Stop-and-Fix Gate 적용** (아래 참조)
- **적용 제외**: `.md` 파일, `.json` 설정 파일, 커밋 메시지 등 비소스코드
- **코드 품질 검토**: 구현 일단락 시점(Step 5 완료, Refinement Cycle 완료, Integration 완료)에서 `/simplify` 스킬을 실행하여 변경 코드의 재사용성, 품질, 효율성을 검토한다.

**Hook 기반 구조적 강제**: Forbidden Rules는 `~/.claude/settings.json`의 `hooks.PreToolUse`에 등록된 `forbidden-guard.sh`로 결정론적 차단된다. ABSOLUTE FORBIDDEN 패턴 매칭 시 exit 2로 명령이 차단되며, 컨텍스트 압축·장시간 세션·다중 에이전트 상황에서도 100% 작동한다. `auto-verify.sh`도 `hooks.PostToolUse`에 등록하여 Edit/Write 후 빌드/린트를 자동 실행할 수 있다.

```bash
# auto-verify.sh 동작 흐름:
# 1. $TOOL_NAME이 Edit/Write가 아니면 → exit 0
# 2. $FILE_PATH 확장자가 .md/.json/.yaml이면 → exit 0 (비소스코드)
# 3. verify-commands.md에서 빌드/린트 명령 추출 후 실행
# 4. 실패 시 exit 1 → Claude Code가 실패 감지 → Stop-and-Fix Gate 진입

# settings.json 등록:
{
  "hooks": {
    "PostToolUse": [{
      "type": "command",
      "command": ".claude/workflow/scripts/auto-verify.sh"
    }]
  }
}
```

### Deterministic Gate Principle

게이트 검증에서 파일 존재 확인, 빌드/린트/테스트 실행, 패턴 매칭, 카운터 비교 등 결정론적으로 수행 가능한 작업은 bash 스크립트를 우선 사용한다. LLM은 스크립트 실행 결과(PASS/FAIL + 실패 항목)만 받아 후속 판단(수정 방향, 전략 전환)에 집중한다. 결정론적 검증을 LLM 기억에 의존하면, 컨텍스트 압축 시 규칙이 소실되어 게이트가 무력화될 수 있기 때문이다.

### Composable CLI Script Toolkit

`workflow/scripts/`의 스크립트는 구조화된 출력, 파이프 호환, 자기 문서화, 컨텍스트 전처리를 따른다.
For detailed principles, read [cross-cutting-protocols.md](references/cross-cutting-protocols.md).

### Stop-and-Fix Gate

빌드, 린트, 타입체크, 테스트 중 하나라도 실패하면 **반드시 수정한 후에만** 다음 파일 수정, 다음 Step 진입, 사용자 보고 등 어떤 작업도 하지 않는다. "나중에 고치겠다"는 허용되지 않는다 — 미수정 실패는 누적되어 디버깅 비용이 기하급수적으로 증가하기 때문이다.

수정 후에는 **동일 검증 명령을 재실행(Fix-Verify Loop)**하여 통과를 확인한다. 재실행에서도 실패하면 Error Resilience 프로토콜을 적용한다.

ENV_INFRA로 테스트 실행 자체가 불가능한 경우, 사용자 명시적 승인 후에만 테스트를 SKIP할 수 있으며, 이때도 build + typecheck는 반드시 통과해야 한다.

### Parallel Tool Invocation

독립적인 도구 호출(Read, Grep, Glob 등)은 병렬로 실행한다. 의존성이 있는 호출만 순차 실행한다. 병렬화로 컨텍스트 소비를 줄이고 응답 속도를 높인다.

### Prompt Altitude Calibration

에이전트에게 전달하는 프롬프트의 구체성 수준을 의도적으로 조절한다. 너무 구체적이면 경직되어 예외 상황에 대응하지 못하고, 너무 모호하면 행동 신호가 부족하여 기대와 다른 결과를 낳는다.

- **Instruction** (행동 지시): 구체적으로 — "E2E 테스트를 Playwright로 작성한다", "빌드 실패 시 다음 Step으로 진행하지 않는다"
- **Guidance** (행동 규범): 유연하게 — "테스트는 서로 독립적이어야 한다", "plan-summary.md에 명시된 변경만 구현한다"

프롬프트 작성 시 각 지시문이 Instruction인지 Guidance인지 구분하고, Guidance에 불필요한 구체성을 넣거나 Instruction에서 핵심 세부사항을 빠뜨리지 않는다.

### Reference Loading Policy (컨텍스트 효율)

각 Phase 진입 시 해당 Phase의 레퍼런스 파일만 읽는다. 모든 레퍼런스를 사전 로딩하지 않는다.

| 트리거 | 읽을 파일 |
|--------|----------|
| Phase A 진입 | `phase-a-planning.md` |
| Phase B-E 구현 진입 | `phase-b-implementation.md` |
| Phase B-E 검증 진입 (Step 6+) | `phase-b-verification.md` |
| Integration/Review 진입 | `integration-and-review.md` |
| Agent Team 생성 시 | `agent-teams.md` |
| 에러 발생 시 | `error-resilience.md` |
| Step 6/7/17 검증 진입 시 | `context-separation.md` |
| 전문가 팀 findings 작성 시 | `expert-output-schema.md` |
| Forbidden Rules 참조 필요 시 | `forbidden-rules.md` |
| 외부 라이브러리/서비스 사용 시 | `docs-first-protocol.md` |
| Startup 또는 세션 복원 시 | `cross-cutting-protocols.md` |

이전에 로딩한 레퍼런스 내용은 컨텍스트 압축을 통해 유지된다. 압축이 심하게 이루어지지 않은 한 재읽기는 불필요하다.

### Subagent 사용 기준

subagent는 다음 경우에 사용한다:
1. 독립적 컨텍스트가 필요한 병렬 작업
2. 다른 전문성이 필요한 역할 분리
3. 대량의 코드 탐색
4. 독립 검증이 품질을 높이는 경우 (Cognitive Independence — `context-separation.md` 참조)
   - CRITICAL/HIGH 판정의 교차 검증, 3회+ 동일 실패 반복 시 fresh perspective
   - 결정론적 검증(빌드, 테스트 실행)은 제외 — 코드 실행으로 확인 가능한 것에 subagent를 쓰지 않음

단일 파일 수정, 간단한 검색, 단순 명령 실행은 직접 수행한다. 불필요한 subagent 생성은 컨텍스트를 낭비한다.

**역할별 maxTurns 가이드라인:**

| 용도 | maxTurns | 예시 |
|------|----------|------|
| 코드 탐색 | 20 | explore-medium, explore-quick |
| 구현 (TDD) — SMALL | 50 | executor (단일 Unit) |
| 구현 (TDD) — STANDARD | 100 | executor (복합 Unit) |
| 구현 (TDD) — LARGE | 200 | executor (대규모 Unit) |
| 검증/리뷰 | 30 | reviewer, verifier (.claude/agents/) |
| 전략 판단 | 30 | architect, security-reviewer |
| expert team member | 20 | Agent Team 내 전문가 |

maxTurns 초과 시 에이전트가 자동 종료된다. 오케스트레이터는 종료 사유를 사용자에게 보고하고, 필요 시 더 높은 maxTurns로 재시도할지 결정한다.

### Over-engineering 방지

plan-summary.md에 명시된 변경만 구현한다. 변경하지 않는 코드에 docstring, 주석, 타입 어노테이션을 추가하지 않는다. 범위 밖의 개선을 발견하면 `.claude/memory/unresolved-decisions.md`에 기록만 한다.

### User Interaction Recording

매 단계에서 사용자 응답(AskUserQuestion, PR 피드백 등)을 받을 때마다, 워크플로/스킬 개선에 반영할 만한 인사이트를 `.claude/memory/user-feedback-log.md`에 누적 기록한다.

기록 형식 (append):
```
## [Step N] {단계명}
- **User said**: (사용자 발언 요약)
- **Interpretation**: (의도 해석)
- **Skill implication**: (스킬/워크플로 개선점, 없으면 "None")
```

이 기록은 Step 20에서 스킬 자기 개선의 입력이 된다. 사용자의 교정, 불만, 반복 요청에 특히 주의를 기울여 기록할 것.

### Phase-End Auto-Retrospective

Step 20(마지막 단계)에 도달하지 못하더라도 사용자 피드백이 증발되지 않도록, 각 Phase 경계에서 경량 회고를 자동 실행한다.

**트리거 시점:**

| 시점 | 조건 |
|------|------|
| Phase A 완료 후 | Calibration Checklist 통과 직후 |
| 각 Unit 완료 후 | Step 8 (SMALL) 또는 Step 17 (STANDARD+) 완료 시 |
| Integration 완료 후 | integration-result.md 저장 직후 |

**실행 절차:**

1. `user-feedback-log.md`에서 해당 Phase 구간의 기록을 스캔한다
2. 패턴 탐지:
   - **반복 교정** (2건+ 동일 유형 수정 요청) → `AUTO_CAPTURE`
   - **워크플로 마찰** (특정 단계에서 불만/지연) → `AUTO_CAPTURE`
   - 패턴 없음 → `SKIP`
3. `AUTO_CAPTURE` 시:
   - `simon-bot-boost-capture`의 동작을 따라 백그라운드 Agent를 spawn하여 인사이트 리포트를 `~/.claude/boost/insights/`에 저장한다
   - 포그라운드에서는 1줄 통보만: `[Retro] {Phase} 피드백 {N}건 감지 → 개선 인사이트 캡처 중`
   - 사용자 확인 없이 자동 실행 (boost-capture의 스냅샷 확인 단계를 생략)
4. `SKIP` 시: `[Retro] {Phase} — 개선 패턴 없음` 1줄만 출력하고 즉시 다음 Phase로 진행
5. retrospective.md에 체크포인트 append:
   ```
   ## Phase-End Checkpoint: {Phase}
   - **시점**: {timestamp}
   - **피드백 건수**: {N}건
   - **감지 패턴**: {패턴 요약 또는 "없음"}
   - **캡처**: {boost insight 파일명 또는 "N/A"}
   ```

**Step 20과의 관계**: Phase-end 회고가 이미 캡처한 패턴은 Step 20에서 중복 처리하지 않는다. Step 20은 전체 워크플로를 관통하는 종합 패턴(Phase 간 교차 패턴)에만 집중한다. 컨텍스트 부족으로 Step 20이 실행되지 않아도, 핵심 인사이트는 Phase-end에서 이미 캡처된 상태이므로 안전하다.

**오버헤드**: user-feedback-log.md 스캔 + 1줄 출력 = 최소 컨텍스트 소비. boost-capture는 백그라운드이므로 포그라운드 작업에 영향 없음.

### Handoff Notification

스킬 전환(simon-bot → simon-bot-review 등) 시 사용자에게 1줄 통보를 출력한다. 갑작스러운 스킬 전환으로 인한 사용자 혼란을 방지한다.

형식: `[Handoff] {현재 스킬} → {다음 스킬}: {목적 1줄 설명}`
예시: `[Handoff] simon-bot → simon-bot-review: Draft PR 생성 및 코드 리뷰 진행합니다.`

### Docs-First Protocol

라이브러리·DB·프레임워크·외부 서비스 사용 시 공식 문서를 먼저 조회한다.
For detailed protocol (적용 기준, 도구 우선순위, 조회 불가 시 대응), read [docs-first-protocol.md](references/docs-first-protocol.md).

## Startup

Startup 단계는 순서 의존성이 있으므로 순차 실행한다.

1. `.claude/workflow/` 존재 확인. 없으면: `bash ~/.claude/skills/simon-bot/install.sh --project-only`
2. 워크플로 파일 읽기 (parallel OK):
   - `.claude/workflow/config.yaml`
   - `.claude/memory/retrospective.md` (있으면)
   - `.claude/project-memory.json` (있으면 Read — 이전 세션에서 학습된 빌드 에러 패턴, 테스트 환경 quirk, 기각된 접근법 포함)
   - `.claude/memory/handoff-manifest.json` (있으면 — P-009 Handoff 감지)
3. **브랜치명 자동 생성** (P-001): 사용자 요청에서 브랜치명을 자동 생성한다. 예: "인증 기능 추가해줘" → `feat/add-auth`. AskUserQuestion 없이 통보: `[Default] Branch: feat/add-auth — 변경하려면 알려주세요.` → `.claude/memory/branch-name.md`에 저장
3-B. **SESSION_DIR 초기화**: 브랜치명 확정 후 세션 디렉토리를 생성한다.
   ```bash
   PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
   SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${branch_name}"
   mkdir -p "${SESSION_DIR}/memory" "${SESSION_DIR}/reports"
   ```
   이후 모든 `.claude/memory/`, `.claude/reports/` 경로는 `{SESSION_DIR}` 기준으로 해석한다.
3-C. **workflow-state.json 초기화**: `{SESSION_DIR}/memory/workflow-state.json`에 초기 스키마를 기록한다 (State-Driven Execution 섹션 참조). 이미 존재하면 기존 세션 복원으로 판단하고 덮어쓰지 않는다.
4. **Handoff Manifest 처리** (P-009): `.claude/memory/handoff-manifest.json`이 존재하면:
   - `context_files`를 자동 로딩하여 컨텍스트 복원
   - `skip_steps`에 명시된 Step은 건너뛰기
   - `failure_context`가 있으면 `failure-log.md` 초기값으로 설정
   - `force_path`가 있으면 Step 0 Scope Challenge를 skip하고 해당 경로로 직행 (단, `config.yaml`의 `high_impact_paths`에 매칭되는 파일이 포함되면 STANDARD 이상을 강제)
5. **Pre-flight 환경 검증**: Phase A 진입 전에 bash 기반 환경 검증을 수행한다 (LLM 토큰 0). Phase A에서 전문가 패널 분석과 계획서 작성에 대량 토큰을 소비한 후에야 환경 문제를 발견하는 것을 방지한다.
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

**Step 19: simon-bot-review 스킬 호출**
- Step 18-B 완료 후 `simon-bot-review` 스킬을 호출하여 Draft PR 생성, 인라인 코드 리뷰, CI Watch, 피드백 루프를 위임
- simon-bot-review가 Completion Summary 출력 및 최종 마무리(retrospective, CONTEXT.md 갱신) 처리
- simon-bot-review는 CONNECTED 모드로 자동 감지됨 (review-sequence.md 존재)

> **분해 패턴**: Step 19는 원래 simon-bot 내부에 인라인되어 있었으나, PR 리뷰가 독립적으로도 유용하여 `simon-bot-review` 스킬로 추출되었다. 스킬이 비대해질 때 이 패턴(독립 호출 가능한 단계를 별도 스킬로 분리, 연결 모드/독립 모드 양립)을 참고하라.

**Step 20: Self-Improvement (회고 기반 스킬 개선)**
- 워크플로 전반의 사용자 피드백 종합 (user-feedback-log.md)
- `project-memory.json` 갱신 — 이번 세션에서 발견한 빌드 에러 패턴, 환경 quirk, 기각된 접근법을 추가
- Finding Acceptance Summary 분석 — 수용률 < 50% 도메인의 프롬프트 검토, REJECTED 사유 패턴 분석
- 스킬 개선 패턴 식별 → 사용자 확인 → skill-creator 호출

> **컨텍스트 주의**: Step 20은 워크플로 마지막 단계로, 컨텍스트가 거의 소진된 상태일 수 있다. 컨텍스트가 부족하면 Step 20을 건너뛰고, retrospective.md에 "Step 20 미실행 — 컨텍스트 부족"을 기록한다. 사용자 피드백 중 중요한 패턴이 있으면 `.claude/boost/insights/`에 캡처(simon-bot-boost-capture)하여 별도 세션에서 처리한다.

## Success Criteria

워크플로 완료 전 모두 검증한다. 모든 항목이 충족된 후에 완료로 판정한다.

- [ ] 모든 테스트가 RED→GREEN 사이클로 작성됨
- [ ] 전체 테스트 스위트 통과 (0 failures)
- [ ] 빌드 성공 + 타입체크 통과
- [ ] 보안 리뷰 CRITICAL 없음
- [ ] 전문가 우려사항 HIGH 이상 모두 반영됨
- [ ] 코드 리뷰 통과
- [ ] PR 리뷰 완료 — 모든 리뷰 코멘트 resolved (simon-bot-review Step 5에서 검증)
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

세션 복원 시 memory 파일과 실제 상태의 정합성을 검증한다 (상세: simon-bot-sessions/SKILL.md의 resume Step 2 참조):
1. `plan-summary.md`의 Unit 목록 ↔ `unit-*/` 디렉토리 일치
2. `CONTEXT.md` 진행 상태 ↔ 실제 memory 파일 존재 여부
3. `session-meta.json`의 `last_commit_hash` ↔ 실제 git HEAD
4. 불일치 시 `git log --oneline` 기반으로 실제 진행 상태를 재구성 (**Git 이력을 SSoT로 우선**)

## Context Window Management

컨텍스트 윈도우가 자동 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다. 압축이 발생해도 `.claude/memory/`에 상태가 저장되어 있으므로 작업을 계속 진행한다.

For detailed protocols (선제적 Compaction, Compaction 후 상태 검증, 새 세션 시작, 세션 분할 경계), read [cross-cutting-protocols.md](references/cross-cutting-protocols.md).

## Memory Persistence

Record at: Step 완료 시, agent 전환 시, loop rollback 시, Unit 완료 시.
각 Step 시작 전에 관련 memory 파일을 읽는다 — 이전 판단과 상태를 복원하여 일관된 진행을 보장하기 위함이다.

## Unresolved Decision Tracking

미해결 결정사항 → `.claude/memory/unresolved-decisions.md`에 기록.
Step 18 report에 "may bite you later" warning 포함. 암묵적 기본값 대신 명시적으로 결정사항을 문서화한다.
