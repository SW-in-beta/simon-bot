---
name: simon-pm
description: "프로젝트 매니저 - 앱 전체를 기획하고 simon에게 작업을 분배하여 완성합니다. Use when: (1) 새 앱/서비스를 처음부터 만들고 싶을 때 ('앱 만들어줘', '서비스 구축해줘', '프로젝트 시작하자'), (2) 대규모 마이그레이션이나 리팩토링을 체계적으로 진행할 때, (3) 여러 기능을 조율하며 전체 프로젝트를 완성해야 할 때. 단일 기능이 아닌 '전체 프로젝트'를 관리하는 PM 역할입니다. 다중 팀(3+) 필요한 대규모 프로젝트는 /simon-company를 직접 호출하세요."
compatibility:
  tools: [Agent, AskUserQuestion]
  skills: [simon, simon-grind, simon-report, simon-code-review, git-push-pr]
---

# simon-pm

프로젝트 매니저 스킬. 사용자와 인터뷰하며 PRD를 작성하고, 작업을 분해하여 simon/simon-grind에게 분배한 뒤, 전체 프로젝트 완성까지 관리합니다.

> **Progressive Disclosure**: 각 Phase의 참조 파일은 해당 Phase 진입 시점에만 로딩한다. 모든 참조 파일을 한꺼번에 읽지 않는다 — 컨텍스트 윈도우를 절약하고 현재 Phase에 집중하기 위함이다.

## Scope Guard

이 스킬은 **여러 기능을 조율하는 전체 프로젝트 관리**를 위한 것입니다. 소규모 작업에 PM 워크플로를 적용하면 오버헤드만 늘어나므로, 아래 기준으로 적용 여부를 먼저 판단합니다:

| 기준 | simon-pm 적용 | simon-dev로 리다이렉트 |
|------|-------------------|------------------------|
| 기능(Feature) 수 | 3개 이상 | 1-2개 |
| 예상 변경 파일 수 | 15개 이상 | 15개 미만 |
| 기능 간 의존성 | 있음 | 없음 |
| PRD/작업 분해 필요 | 필요 | 불필요 (범위가 이미 명확) |

**리다이렉트 시 행동**: 사용자에게 왜 simon-pm이 과한지 간략히 설명하고, simon-dev 사용을 제안한다. 강제하지 말고 사용자가 그래도 PM 워크플로를 원하면 진행한다.

---

## Instructions

이 스킬은 7단계 파이프라인으로 동작합니다:

| Phase | 이름 | 핵심 | 참조 파일 |
|-------|------|------|----------|
| 0 | Project Setup | 프로젝트 유형 판별, 실행 모드 선택 | [project-setup.md](references/project-setup.md) |
| 1 | Spec-Driven Design | 인터뷰 → Spec(WHAT) → Architecture(HOW) → PRD | [spec-driven-design.md](references/spec-driven-design.md), [spec-template.md](references/spec-template.md), [technical-architecture.md](references/technical-architecture.md) |
| 2 | Task Breakdown | PRD → 기능 분해 → 의존성 그래프 → 실행 계획 | [task-breakdown.md](references/task-breakdown.md) |
| 3 | Environment Setup | 프로젝트 뼈대, 의존성, 설정 | [environment-setup.md](references/environment-setup.md) |
| 4 | Feature Execution | simon-dev/simon-grind 파이프라인으로 기능별 구현 + 진행 관리 | [feature-execution.md](references/feature-execution.md) |
| 5 | Full Verification | 전체 레벨 통합 검증 | [full-verification.md](references/full-verification.md) |
| 6 | Delivery | 최종 보고, 가이드 리뷰, PR 생성 | [delivery.md](references/delivery.md) |

**Reference Loading Policy**: 각 Phase 진입 시 해당 행의 "참조 파일"만 읽는다. 이전/이후 Phase의 참조 파일은 로딩하지 않는다.

**Dependencies**: simon/simon-grind 스킬을 활용합니다. Claude Code의 Agent 및 Agent Teams 기능을 사용합니다.

## Cross-Cutting Protocols

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules, Agent Teams, Cognitive Independence 공통 프로토콜 포함.

### Monitor Protocol (대시보드 연동)

> **Shared Protocol**: `~/.claude/skills/_shared/monitor-protocol.md` 읽기.

각 Phase 시작/완료 시 `step_start`/`step_complete` 이벤트를 발신한다. emit.sh가 SESSION_DIR과 skill을 자동 감지하므로 별도 인자 불필요. Step ID는 `{phase_num}/{step}` 형식 (예: `0/setup`, `1/1-A`, `4/exec`).

**Phase 0 완료 시 workflow_start 발신:**
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh workflow_start "" "PM 워크플로 시작" '{"skill":"simon-pm","branch":"pm-session","task":"'"$PROJECT_NAME"'","scope":"PM","workflow_steps":[{"id":"0/setup","name":"Project Setup","phase":"0"},{"id":"1/1-A","name":"Vision Interview","phase":"1"},{"id":"1/1-B","name":"Feature Spec","phase":"1"},{"id":"1/1-C","name":"Technical Architecture","phase":"1"},{"id":"1/1-D","name":"PRD Assembly","phase":"1"},{"id":"1/1-E","name":"Spec Freeze","phase":"1"},{"id":"2/2-A","name":"Feature Decomposition","phase":"2"},{"id":"2/2-B","name":"Dependency Analysis","phase":"2"},{"id":"2/2-C","name":"Bot Assignment","phase":"2"},{"id":"2/2-D","name":"Execution Plan","phase":"2"},{"id":"3/setup","name":"Environment Setup","phase":"3"},{"id":"4/exec","name":"Feature Execution","phase":"4"},{"id":"5/verify","name":"Full Verification","phase":"5"},{"id":"6/delivery","name":"Delivery","phase":"6"}]}'
```

**Phase 1-C 완료 시 (CTO+Dev Lead 패널 후):**
`.pending-event.json` 작성 후 emit:
```json
{
  "skill": "simon-pm",
  "step": "1/1-C",
  "type": "expert_panel",
  "title": "CTO + Dev Lead 기술 결정",
  "data": {
    "panel_name": "CTO + Dev Lead Panel",
    "opinions": [각 전문가의 {"role":"...", "opinion":"...", "severity":"..."}],
    "consensus": "기술 결정 합의",
    "action_items": ["결정 사항"]
  }
}
```
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh pending
```

**Phase 2-C 완료 시 (봇 할당 결정):**
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh decision "2/2-C" "봇 할당 결정" '{"decision":"Feature별 simon/grind 할당","rationale":"복잡도 기반 할당","alternatives":[]}'
```

**Phase 4 피처 위임 시:**
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh child_session "4/exec" "Feature N: 기능명 → simon-dev 위임" '{"child_session_id":"feat/xxx","delegated_skill":"simon-dev","feature":"기능명","force_path":"SMALL"}'
```

**Phase 5 검증 게이트:**
`.pending-event.json` 작성 후 emit:
```json
{
  "skill": "simon-pm",
  "step": "5/verify",
  "type": "gate_pass 또는 gate_fail",
  "title": "Full Verification {통과|실패}",
  "data": {
    "gate_name": "Full Verification",
    "checks": [{"name": "항목명", "passed": true/false}],
    "passed_count": N,
    "total_count": M
  }
}
```
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh pending
```

**Phase 6 완료 시 workflow_complete:**
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh workflow_complete "" "PM 워크플로 완료" '{"status":"success","summary":"프로젝트 완료 요약"}'
```

### Decision Trail

주요 판단 지점에서 사용자에게 1줄 판단 근거를 함께 제시한다. PM이 왜 그렇게 결정했는지 투명하게 보여주어야 사용자가 방향을 교정할 수 있다.

적용 지점:
- **Feature 분배** (Phase 2): 각 Feature에 simon vs simon-grind를 할당한 이유
- **실행 순서 결정** (Phase 2): 그룹 구성과 병렬/순차 선택 이유
- **Re-planning** (Phase 4): 작업 변경이 필요한 이유 또는 불필요한 이유
- **Bot 전환** (Phase 4): simon에서 simon-grind로 전환하는 이유

형식 예시: `[판단] F3를 simon-grind로 할당 — 외부 API 3개 연동 + 기존 코드 광범위 수정`

### Session Isolation Protocol (확장 — PM 전용)

PM 세션의 SESSION_DIR은 브랜치명 대신 타임스탬프 기반으로 결정한다:
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
SESSION_ID="pm-$(date +%Y%m%d-%H%M%S)"
SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${SESSION_ID}"
mkdir -p "${SESSION_DIR}/pm"
echo "${SESSION_DIR}" > "${SESSION_DIR}/pm/session-path.txt"
```

**경로 매핑** — 이 스킬과 모든 레퍼런스 파일에서 아래 런타임 경로는 `{SESSION_DIR}` 기준으로 해석한다:

| 스킬 내 표기 | 실제 저장 위치 |
|-------------|--------------|
| `.claude/pm/*` | `{SESSION_DIR}/pm/*` |

**Bot 파견 시 결과 경로 전달**: simon-dev에게 Feature 구현을 위임할 때, 결과 파일 경로 `{SESSION_DIR}/pm/tasks/{task-id}/result.md`를 명시적으로 전달한다. Bot은 자체 `{SESSION_DIR}/memory/`에 작업하되, 완료 시 결과를 PM이 지정한 경로에 기록한다.

### Error Resilience (확장 — PM Phase별)

**Phase별 복구 전략:**

| Phase | 실패 유형 | 복구 전략 |
|-------|----------|----------|
| Phase 0-2 (기획) | 에이전트 응답 실패 | 재시도 (max 3) → 단독 분석으로 fallback |
| Phase 3 (환경) | 의존성 설치 실패 | 대안 버전 시도 → 사용자에게 수동 설치 요청 |
| Phase 4 (실행) | simon-dev 3회 실패 | simon-grind로 자동 전환 |
| Phase 4 (실행) | Feature 간 충돌 | Re-planning Gate 활성화 → 의존성 재분석 |
| Phase 5 (검증) | 테스트 실패 | CRITICAL/HIGH 이슈는 해당 Feature의 Bot에 재위임 |
| Phase 6 (전달) | PR 생성 실패 | git 상태 점검 → 브랜치 정리 → 재시도 |

`~/.claude/skills/simon-dev/references/error-resilience.md`의 상세 프로토콜을 Phase 4-5에서 적용한다.

### Subagent 사용 기준

단일 파일 수정이나 간단한 작업은 PM이 직접 수행한다. Subagent는 독립적 컨텍스트가 필요한 병렬 작업에만 사용한다. Subagent를 불필요하게 spawn하면 컨텍스트 전달 오버헤드와 조율 비용이 생기기 때문이다.

**핵심 판단 기준**: "이 작업의 중간 도구 출력(파일 읽기, 로그 스캔, 테스트 출력)이 메인 컨텍스트에 필요한가, 아니면 결론만 필요한가?" 결론만 필요하면 → Subagent.

| 상황 | 중간 출력 볼륨 | 수행 방식 |
|------|--------------|----------|
| 단일 파일 수정, 설정 변경, 간단한 스크립트 | 낮음 | PM 직접 수행 |
| 독립적인 Feature 구현, 전문 분석(CTO/보안 리뷰) | 높음 (다수 파일 탐색) | Subagent spawn |
| 같은 파일을 건드리는 여러 작업 | 낮음 | 순차로 직접 수행 (병렬 불가) |
| Phase 5 Architecture/Security Review (다수 파일 스캔) | 높음 | Subagent spawn — 결과 요약만 반환 |
| PRD 기반 task 분해 (architect 에이전트 분석) | 중간 | Subagent spawn — tasks.json만 반환 |
| 다른 서비스 코드베이스 요약 (기술 리서치) | 높음 | Subagent spawn — research.md 요약만 반환 |

Subagent spawn prompt에는 반드시 "결론과 필수 액션만 반환, 중간 탐색 출력은 반환 금지" 문구를 포함한다 (simon-dev SKILL.md의 Result-Only 반환 원칙 참조).

### State Management

모든 상태는 `{SESSION_DIR}/pm/` 하위에 저장 (Session Isolation Protocol 참조):

| 파일 | 내용 |
|------|------|
| `state.json` | 전체 진행 상태 (현재 phase, 실행 모드) |
| `spec.md` | Feature Specification (WHAT — 요구사항, 시나리오, 성공 기준) |
| `constitution.md` | Project Constitution (원칙, 품질 게이트, 제약) |
| `research.md` | 기술 리서치 결과 ([NEEDS CLARIFICATION] 해소) |
| `plan.md` | Implementation Plan (HOW — 기술 스택, 아키텍처, 기술 컨텍스트) |
| `prd.md` | PRD 문서 (spec + plan 종합) |
| `tasks.json` | 작업 목록 + 의존성 + 상태 |
| `tasks/{task-id}/spec.md` | 개별 작업 명세 |
| `tasks/{task-id}/result.md` | 작업 결과 |
| `progress.md` | 진행 현황 보고 |
| `verification.md` | 최종 검증 결과 |

---

<!-- Decomposition Note: Phase 0-1은 사용자 인터랙션 중심, Phase 2-3은 계획/준비, Phase 4-6은 실행/검증/전달. 이 3개 그룹은 독립적인 서브스킬로 분리 가능하다. 분리 시 state.json이 handoff 매개체가 된다. -->

## Phase 0: Project Setup

> **Reference Loading**: Phase 0 진입 시 [project-setup.md](references/project-setup.md) 읽기

> **[MONITOR]** Phase 0 시작 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 0/setup "Project Setup"`

프로젝트 유형(Greenfield/Existing)과 실행 모드(자동/승인)를 추론하여 한 번에 제시하고, 사용자 교정을 받은 뒤 초기 상태를 저장한다.

> **[MONITOR]** Phase 0 완료 시 `workflow_start` 이벤트 발신 (Monitor Protocol 참조).
> **[MONITOR]** Phase 0 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 0/setup "완료"`

<!-- Decomposition Note: Phase 0은 독립 실행 가능. 입력=사용자 요청, 출력=state.json. -->

---

## Phase 1: Spec-Driven Design (Interactive)

> **Reference Loading**: Phase 1 진입 시 [spec-driven-design.md](references/spec-driven-design.md), [spec-template.md](references/spec-template.md), [technical-architecture.md](references/technical-architecture.md) 읽기

Spec-Driven Development 기반 설계. WHAT(요구사항)과 HOW(기술 결정)를 분리하여 체계적으로 진행한다.
사용자와 인터뷰하고, 전문가 에이전트 패널이 기술 결정을 지원한다.

이 단계가 전체 프로젝트의 품질을 결정하므로, 충분한 대화와 분석을 통해 구체화한다.

> **[MONITOR]** Phase 1 시작 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 1/1-A "Vision Interview"`

- **1-A: Vision Interview** — AI-First Draft Protocol로 인터뷰. 초안 제시 → 사용자 교정
> **[MONITOR]** 1-A 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 1/1-A "완료"` → `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 1/1-B "Feature Spec"`
- **1-B: Feature Specification (WHAT)** — `planner` 에이전트가 Spec 작성. Save: `.claude/pm/spec.md`
> **[MONITOR]** 1-B 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 1/1-B "완료"` → `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 1/1-C "Technical Architecture"`
- **1-C: Technical Architecture (HOW)** — CTO + Dev Lead 패널의 기술 결정. Research, Constitution, Plan 완성

> **[MONITOR]** Phase 1-C 완료 시 `expert_panel` 이벤트 발신 (Monitor Protocol 참조).
> **[MONITOR]** 1-C 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 1/1-C "완료"` → `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 1/1-D "PRD Assembly"`

- **1-D: PRD Assembly & Review** — Spec + Plan + Constitution 종합 → 사용자 승인
> **[MONITOR]** 1-D 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 1/1-D "완료"` → `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 1/1-E "Spec Freeze"`
- **1-E: Spec Freeze** — 승인 후 Spec 동결. 이후 변경은 명시적 수정 절차 필수 (변경 요청 → 영향 분석 → 사용자 승인 → 문서 갱신). Spec drift 방지
> **[MONITOR]** 1-E 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 1/1-E "완료"`

<!-- Decomposition Note: Phase 1은 독립 실행 가능. 입력=state.json+사용자 요청, 출력=spec.md/plan.md/constitution.md/research.md/prd.md. -->

---

## Phase 2: Task Breakdown

> **Reference Loading**: Phase 2 진입 시 [task-breakdown.md](references/task-breakdown.md) 읽기

PRD를 구현 가능한 단위 작업(Feature)으로 분해한다.

> **[MONITOR]** Phase 2 시작 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 2/2-A "Feature Decomposition"`

- **2-A: Feature Decomposition** — `architect`가 PRD 분석. 각 Feature는 파일 5-15개, 단일 관심사
> **[MONITOR]** 2-A 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 2/2-A "완료"` → `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 2/2-B "Dependency Analysis"`
- **2-B: Dependency Analysis** — 의존성 그래프, 병렬/순차 그룹, Critical Path 최적화
> **[MONITOR]** 2-B 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 2/2-B "완료"` → `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 2/2-C "Bot Assignment"`
- **2-C: Complexity Assessment & Bot Assignment** — simon vs simon-grind 자동 할당

> **[MONITOR]** Phase 2-C 완료 시 `decision` 이벤트 발신 (Monitor Protocol 참조).
> **[MONITOR]** 2-C 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 2/2-C "완료"` → `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 2/2-D "Execution Plan"`

- **2-D: Execution Plan 생성** — `tasks.json`에 저장
> **[MONITOR]** 2-D 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 2/2-D "완료"`
- **2-E: 실행 계획 리뷰** — 사용자에게 시각적 제시 → 승인/수정/Bot 변경

<!-- Decomposition Note: Phase 2는 Phase 1 출력에만 의존. 입력=prd.md+spec.md+constitution.md, 출력=tasks.json. -->

---

## Phase 3: Environment Setup

> **Reference Loading**: Phase 3 진입 시 [environment-setup.md](references/environment-setup.md) 읽기

> **[MONITOR]** Phase 3 시작 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 3/setup "Environment Setup"`

기능 구현 전에 프로젝트 환경을 준비한다. Scaffolding → Dependencies → Git Setup → 환경 검증.

> **[MONITOR]** Phase 3 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 3/setup "완료"`

<!-- Decomposition Note: Phase 3은 Phase 2와 독립적으로 실행 가능 (plan.md만 있으면 됨). Phase 2와 병렬 실행도 이론적으로 가능하나, tasks.json의 Feature 목록이 환경에 영향을 줄 수 있어 순차 실행 권장. -->

---

## Phase 4: Feature Execution

> **Reference Loading**: Phase 4 진입 시 [feature-execution.md](references/feature-execution.md) 읽기

각 Feature를 simon 또는 simon-grind에게 위임하여 구현한다.

> **[MONITOR]** Phase 4 시작 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 4/exec "Feature Execution"`
> **[MONITOR]** 각 Feature 위임 시 `child_session` 이벤트 발신 (Monitor Protocol 참조).

`execution_groups` 순서대로 진행하며, 각 그룹 완료 후 통합 검증 + Re-planning Gate를 거친다. 진행 현황을 `.claude/pm/progress.md`에 유지한다.

> **[MONITOR]** Phase 4 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 4/exec "완료"`

**Plan Reuse Protocol**: PM이 simon-dev에게 Feature를 위임할 때, simon-dev의 Handoff Manifest(P-009) 형식으로 컨텍스트를 전달한다:

```json
{
  "from_skill": "simon-pm",
  "to_skill": "simon-dev",
  "force_path": "SMALL",
  "transfer_files": ["tasks/{task-id}/spec.md", "constitution.md", "research.md (관련 항목)"],
  "skip_steps": ["Step 0", "Step 1-A"],
  "context_note": "PM이 Spec과 Plan을 이미 수립함. Task Spec을 requirements.md로 사용."
}

```

PM Phase 1에서 CTO 패널이 식별한 기술 제약과 gotchas도 전달한다 — plan.md의 기술 제약 → simon-dev의 expert-plan-concerns.md 초기값, research.md → Docs-First 중복 조회 방지. simon-dev은 Startup의 Handoff Manifest 처리에서 이 manifest를 감지하여 Phase A를 자동 간소화한다.

Handoff Notification 형식: `[Handoff] PM → simon-dev (F{N}: {기능명}): PM 계획 재사용, Phase A 간소화 (SMALL path)`

<!-- Decomposition Note: Phase 4는 가장 큰 Phase. Feature 단위로 subagent에 위임하는 구조이므로 이미 내부적으로 분해되어 있다. -->

---

## Phase 5: Full Verification

> **Reference Loading**: Phase 5 진입 시 [full-verification.md](references/full-verification.md) 읽기

> **[MONITOR]** Phase 5 시작 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 5/verify "Full Verification"`

모든 Feature 완료 후, 전체 프로젝트 수준에서 통합 검증을 수행한다.

검증 단계: Integration(브랜치 통합) → Full Build & Test → Integration Testing(E2E) → Architecture Review → Security Review(OWASP) → Issue Resolution(CRITICAL/HIGH 즉시 수정, MEDIUM 사용자 판단, max 3 rounds) → Verification Report 작성.

Save: `.claude/pm/verification.md`

> **[MONITOR]** 검증 완료 시 `gate_pass`/`gate_fail` 이벤트 발신 (Monitor Protocol 참조).
> **[MONITOR]** Phase 5 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 5/verify "완료"`

<!-- Decomposition Note: Phase 5는 독립 실행 가능. 입력=통합된 코드베이스+prd.md, 출력=verification.md. 외부 검증 도구와 연계 시 별도 스킬로 분리 가능. -->

---

## Phase 6: Delivery (사용자 인터랙티브)

> **Reference Loading**: Phase 6 진입 시 [delivery.md](references/delivery.md) 읽기

> **[MONITOR]** Phase 6 시작 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start 6/delivery "Delivery"`

Final Report → Guided Review → **Code Review (simon-code-review)** → Completion Summary → Finalization(커밋, PR 생성).

> **[MONITOR]** 워크플로 종료 시 `workflow_complete` 이벤트 발신 (Monitor Protocol 참조).
> **[MONITOR]** Phase 6 완료 시: `bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete 6/delivery "완료"`

> **INSTRUCTION (Draft PR 필수)**: PR 생성은 반드시 `simon-code-review` 스킬을 통해 수행한다. PM이 직접 `gh pr create`를 실행하는 것은 금지다. simon-code-review가 Draft PR 생성 + 인라인 코드 리뷰를 담당한다.

**simon-code-review 연결**: Guided Review 완료 후, PR 생성 전에 `simon-code-review` 스킬을 호출하여 Draft PR + 인라인 코드 리뷰를 수행한다. PM이 관리하는 프로젝트도 simon 직접 실행과 동일한 수준의 코드 리뷰를 받아야 하기 때문이다. simon-code-review는 STANDALONE 모드로 동작하며, diff 분석 → review-sequence 자체 생성 → 인라인 리뷰를 수행한다.

<!-- Decomposition Note: Phase 6은 독립 실행 가능. 입력=verification.md+progress.md, 출력=PR+retrospective.md. -->

---

## Success Criteria

프로젝트 완료 전 모두 검증한다. 하나라도 미충족이면 완료 불가 -- 출시 후 발견되는 결함보다 이 시점에서 잡는 것이 비용이 훨씬 낮다.

- [ ] PRD의 모든 Must-have 기능 구현 완료
- [ ] 전체 빌드 성공
- [ ] 전체 테스트 스위트 통과 (0 failures)
- [ ] 통합 테스트 통과
- [ ] 아키텍처 리뷰 CRITICAL 없음
- [ ] 보안 리뷰 CRITICAL 없음
- [ ] 사용자 가이드 리뷰 완료
- [ ] 미해결 결정사항 문서화됨

---

## Global Forbidden Rules

`~/.claude/skills/simon-dev/references/forbidden-rules.md`의 3계층 규칙(ABSOLUTE / CONTEXT-SENSITIVE / AUDIT-REQUIRED)을 전체 적용한다. Runtime Guard(P-008)도 Phase 4-5에서 적용한다.

---

## Context Window Management

컨텍스트 부족 시 세션 분할 경계:

| 경계 | 시점 | 저장 상태 |
|------|------|----------|
| 1 | Phase 1 완료 후 | spec.md, plan.md, constitution.md, research.md, prd.md |
| 2 | Phase 2 완료 후 | tasks.json, tasks/*/spec.md |
| 2.5 | Phase 3 완료 후 | state.json (phase=4 ready), 환경 검증 결과 |
| 3 | Phase 4 중간 (그룹 완료 시) | progress.md, tasks/*/result.md |
| 4 | Phase 5 완료 후 | verification.md |

Phase 4 진입 시 PM은 Phase 1-3의 "과정"(인터뷰 대화, 패널 토론 기록, scaffolding 출력)을 컨텍스트에서 제거하고, `state.json`의 `load_files`가 가리키는 "결과물"만 로딩한다. Phase 1-3의 상세 맥락이 필요한 상황(Re-planning Gate에서 spec 변경 필요 등)이 발생하면 그때 선택적으로 읽는다.

복원: `.claude/pm/state.json` + 해당 시점의 저장 파일 읽기 → 다음 Phase/Step 이어서 실행

### Compact Hint (PM Phase별)

컨텍스트 활용률 45% 이상 시 `/compact <hint>` 실행. 방향 없는 압축은 PRD나 기술 결정을 잘라낼 수 있으므로 반드시 hint를 명시한다:

| Phase | Compact Hint |
|-------|-------------|
| Phase 1 (Spec-Driven Design) | `focus on user requirements from interview, feature list, and technical constraints. Drop interview conversation turns and exploration.` |
| Phase 2 (Task Breakdown) | `focus on tasks.json structure, dependency graph, and bot assignments. Drop PRD prose and architecture discussion.` |
| Phase 4 (Feature Execution) | `focus on tasks completion status, current feature being executed, and blocking issues. Drop previous features' implementation details.` |
| Phase 5 (Full Verification) | `focus on verification failures, CRITICAL/HIGH issues, and resolution status. Drop passing test output.` |

**Bot 위임 후** (Feature Execution 중): 완료된 Feature의 구현 세부사항은 compaction 대상이다. `tasks/{task-id}/result.md`에 저장되어 있으므로 컨텍스트에 유지할 필요 없다. Hint에 `drop completed feature implementation details, keep result file paths only`를 항상 포함한다.

**ship 모드**: hint를 자동 적용. **guided 모드**: hint 확인 후 실행.
