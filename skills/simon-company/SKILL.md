---
name: simon-company
description: "풀스택 소프트웨어 회사 — 다중 전문 팀(PM, Design, FE, BE, QA, DBA, DevOps, ML)이 기획→배포→운영까지 협업합니다. 이 스킬은 명시적 호출 전용입니다. '/simon-company' 직접 호출 시에만 사용하세요. 암묵적으로 추론하여 자동 호출하지 마세요. Do NOT use when: 팀 2개 이하로 충분한 프로젝트 — simon-bot-pm을 사용하세요."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
  skills: [simon-bot-pm, simon-bot, simon-bot-grind, simon-bot-report, git-push-pr]
---

# simon-company

풀 라이프사이클 소프트웨어 회사 스킬. 전문 팀들이 기획부터 배포·운영까지 협업하여 프로덕션 레벨의 서비스를 완성합니다.

핵심 철학:
- **"모든 산출물은 3번 검증한다. 리드는 깐깐하다. 통과하지 못하면 재작업한다."**
- **"작게 만들고, 빠르게 검증하고, 피드백을 반영한다."** (Agile Sprint Cycle)
- **"Spec이 곧 기준이다. 모든 구현은 Spec에서 시작하고 Spec으로 검증한다."** (Spec-Driven Development)

> **Progressive Disclosure**: 이 파일은 오케스트레이션 계층(WHAT + WHEN)이다. 각 Phase의 HOW는 `references/` 하위의 레퍼런스 파일에 정의되어 있다. 각 Phase 진입 시 해당 레퍼런스만 읽고, 모든 레퍼런스를 미리 로드하지 않는다.

## Scope Guard

이 스킬은 **다중 팀 협업이 필요한 대규모 프로젝트**를 위한 것입니다.

| 기준 | simon-company | simon-bot-pm으로 리다이렉트 |
|------|--------------|---------------------------|
| 필요 팀 수 | 3개 이상 (예: BE+FE+DevOps) | 1-2개 (BE만, 또는 BE+FE) |
| 인프라 필요 | CI/CD, 배포, 모니터링 필요 | 로컬 실행으로 충분 |
| 디자인 필요 | UI/UX 설계 필요 | API나 CLI 위주 |
| 예상 Feature 수 | 5개 이상 | 3-4개 |

**리다이렉트 시**: 왜 simon-company가 과한지 설명하고, simon-bot-pm 또는 simon-bot 사용을 제안한다. 사용자가 그래도 원하면 진행한다.

---

## Instructions

이 스킬은 8단계 파이프라인으로 동작합니다. 모든 단계에 **Triple Review Protocol(TRP)**이 적용됩니다.

| Phase | 이름 | 핵심 팀 | 산출물 | TRP 적용 |
|-------|------|---------|--------|---------|
| 0 | Company Setup | CEO | roster.json, state.json | - |
| 1 | Discovery & Spec | PM, Design | spec.md, constitution.md, story-map.md | O |
| 2 | Architecture & Design Sprint | CTO, Design, DBA, DevOps | architecture.md, design/, db-schema.md | O |
| 3 | Sprint Planning & Backlog | CTO, All Leads | contracts/, backlog.json, sprint-plan.md | O |
| 4 | Sprint Execution (Iterative) | FE, BE, ML, DBA, DevOps | 구현 코드 (Sprint 단위 반복) | O (Sprint별) |
| 5 | QA & Integration | QA, Security | test-report.md, security-audit.md | O |
| 6 | Deployment & Operations | DevOps, QA | CI/CD, Dockerfile, monitoring | O |
| 7 | Delivery & Handoff | CEO, All Leads | final-report.md, PR | O |

**Dependencies**: simon-bot-pm + simon-bot/simon-bot-grind 스킬을 실행 에이전트로, Agent Team (TeamCreate/SendMessage)을 Sprint 조율에 사용합니다.

<!-- Decomposition Note: Phase 0-3 (기획/설계)과 Phase 4-7 (실행/검증)은 독립적으로 분리 가능한 경계다. Phase 0-3 산출물이 Git에 커밋되면 Phase 4-7은 별도 스킬로도 실행 가능하다. -->

---

## Cross-Cutting Protocols

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules, Agent Teams, Cognitive Independence 공통 프로토콜 포함.

> **Reference Loading**: [cross-cutting-protocols.md](references/cross-cutting-protocols.md) 읽기

Sprint 실행 전반에 걸친 공통 프로토콜. Shared Context, Conflict Resolution, Quality Gates, Context Window Management 포함.

---

## Phase 0: Company Setup (P-001 Zero-Config)

<!-- Decomposition Note: Phase 0은 독립 실행 가능. 이 Phase의 산출물(roster.json, state.json)만으로 후속 Phase 진입 조건이 충족된다. -->

> Reference Loading: `team-roster.md`

**0-A: 단일 통합 확인**

사용자 요청에서 프로젝트 유형, 팀 편성, 실행 모드를 AI가 모두 추론하고 한 번에 제시하여 교정받는다.

```
[Default] 프로젝트 설정:
- 유형: {Greenfield|Existing} — {추론 근거}
- 팀 편성: {PM, CTO, ...} — {선정 이유}
- 실행 모드: {자동 진행|승인 후 진행|의뢰 모드} — {추론 근거}
- 변경하려면 알려주세요. (팀 추가/제거, 모드 변경 등)
```

- **의뢰 모드 자동 감지:** 불명확한 요청 → 의뢰 모드를 기본값으로 제시.
- **Scope Guard 자동 적용:** 팀 2개 이하 → simon-bot-pm 리다이렉트를 기본값에 포함.
- **Existing 프로젝트**: `git log --oneline -20`으로 현재 상태 파악, 통합 확인에 "현재 상태" 항목 포함. "simon-bot-report로 사전 분석 먼저?" 선택사항 제시.

**0-B: 초기 상태 저장** — `roster.json`과 `state.json`을 `.claude/company/`에 생성.

---

## Phase 1: Discovery & Spec (Interactive)

<!-- Decomposition Note: Phase 1은 Phase 0 완료만 필요. PM+Design만으로 독립 실행 가능하며, 산출물(spec.md, story-map.md, constitution.md)이 Git에 커밋되면 Phase 2의 유일한 입력이 된다. -->

> **Phase Transition Gate**: Phase 0 → 1 진입 전 `state.json`, `roster.json` 파일 존재 확인. 없으면 BLOCK.

> Reference Loading: `planning-design.md` + `team-roster.md`

PM팀이 주도하고, Design팀이 참여하여 요구사항을 정의한다.

**모드별 분기:** 자동/승인 모드 → AI-First Draft / 의뢰 모드 → 구조화된 인터뷰

**핵심 산출물:**
- `spec.md` — Feature Specification (INVEST 기준 User Stories + Given/When/Then AC)
- `story-map.md` — Story Mapping (Activity → Task → Story 계층, Walking Skeleton 식별)
- `constitution.md` — 프로젝트 원칙, 품질 게이트, 제약 조건

**검증:** planner-critic-architect 3인 검증 후 TRP (R1-PM Self, R2-Design Cross, R3-CTO Lead).
사용자에게 최종 Spec + Story Map을 제시하고 승인받은 후 Phase 2로 진행.

For detailed process → read [planning-design.md](references/planning-design.md)

---

## Phase 2: Architecture & Design Sprint

<!-- Decomposition Note: Phase 2는 Phase 1 산출물(spec.md, story-map.md)만 필요. CTO/Design/DBA/DevOps/ML 각 트랙은 내부적으로 병렬 실행 가능하며, 트랙별로 독립적 TRP를 수행한다. -->

> **Phase Transition Gate**: Phase 1 → 2 진입 전 `spec.md`, `story-map.md`, `constitution.md` 파일 존재 확인. 없으면 BLOCK — 파일로 저장 후 진행.

> Reference Loading: `planning-design.md` + `team-roster.md`

Spec이 확정되면 CTO, Design, DBA, DevOps가 **병렬로** 자신의 영역을 설계한다.

**핵심 산출물:**
- `architecture.md` — CTO 기술 아키텍처
- `design/` — 와이어프레임, 디자인 토큰, 컴포넌트 트리, 접근성 (Design팀 활성 시)
- `db-schema.md` — ER 다이어그램, 스키마, 인덱스 전략 (DBA팀 활성 시)
- `deployment/infra-blueprint.md` — 인프라 아키텍처, CI/CD, 배포 전략 (DevOps팀 활성 시)
- `ml-architecture.md` — 모델 아키텍처, 학습 파이프라인 (ML팀 활성 시)
- `quality/expert-concerns.md` — Expert Panel 도메인 전문가 검증 결과

**검증:** 각 산출물별 TRP (R1-각 팀 Self, R2-교차 검토, R3-CTO Lead 전체 정합성).
모든 트랙 TRP 통과 후 PRD를 조립하여 사용자 최종 승인.

For detailed process → read [planning-design.md](references/planning-design.md)

---

## Phase 3: Sprint Planning & Backlog

<!-- Decomposition Note: Phase 3은 Phase 2 산출물(architecture.md, design/, db-schema.md, prd.md)이 필요. 산출물(contracts/, backlog.json, sprint-plan.md)이 Git에 커밋되면 Phase 4의 유일한 입력이 된다. Phase 3까지가 '기획/설계'와 '실행'의 자연스러운 분리 경계이다. -->

> **Phase Transition Gate**: Phase 2 → 3 진입 전 `architecture.md`, `prd.md` + (DBA 활성 시) `db-schema.md` + (Design 활성 시) `design/` 파일 존재 확인. 없으면 BLOCK.

> Reference Loading: `contracts-execution.md`

팀들이 독립적으로 구현하기 전에, 팀 간 인터페이스를 합의하고 **Agile 백로그**를 구성한다.

**핵심 산출물:**
- `contracts/` — API Contract (OpenAPI), Data Contract, Component Contract, Event Contract
- `backlog.json` — Product Backlog (DEEP 원칙, S/M/L 규모 추정, STICC Task Spec)
- `tasks/{feature-id}/spec.md` — 각 Feature의 STICC 기반 Task Spec
- `sprint-plan.md` — Sprint별 Feature 할당 (Walking Skeleton → Release 순)
- DoR/DoD 기준 확정

**검증:** TRP (R1-CTO Self, R2-각 팀 Cross "이 계약으로 독립 구현 가능한가?", R3-CEO Lead).
사용자 승인 후 Phase 4로 진행.

For detailed process → read [contracts-execution.md](references/contracts-execution.md)

---

## Phase 4: Sprint Execution (Iterative)

<!-- Decomposition Note: Phase 4는 Phase 3 산출물만으로 독립 실행 가능. 각 Sprint도 내부적으로 독립 단위다(Sprint N의 커밋이 완료되면 Sprint N+1은 별도 세션에서 실행 가능). -->

> **Phase Transition Gate**: Phase 3 → 4 진입 전 `contracts/`, `backlog.json`, `sprint-plan.md` 파일 존재 확인. 없으면 BLOCK.

> Reference Loading: `contracts-execution.md` + (TRP 실행 시) `quality-gates.md`

Sprint 단위로 Feature를 구현하고 검증하는 **반복 사이클**. **simon-bot-pm**에 코드 구현을 위임하고, **Agent Team**으로 팀 리드를 소집하여 Review/Retro를 수행한다.

**실행 아키텍처:**
```
simon-company (CEO)
├─ Phase 0-3: CEO 직접 수행 + TRP 리뷰어
└─ Phase 4: Sprint마다 반복
     ├─ simon-bot-pm (subagent): Sprint 코드 구현 위임
     └─ Agent Team: Sprint Review/Retro 시 팀 리드 소집
```

**Sprint Cycle (반복):**
```
for each sprint in sprint_plan:
    4-A: Sprint Planning — DoR 검증, 실행 순서, Bot 할당
    4-B: Sprint Execution — simon-bot-pm subagent (background)
    4-C: Sprint Review — Agent Team Cross-Review + TRP + 통합 검증
    4-D: Sprint Retro — Keep/Problem/Try
    4-E: Re-planning — 다음 Sprint 백로그 조정
    → 사용자에게 진행 상황 보고
```

**Progress Tracking:** `.claude/company/progress.md`에 Sprint별 + 팀별 현황 유지.

For detailed process (위임 프로토콜, Agent Team 활용, Failure Recovery) → read [contracts-execution.md](references/contracts-execution.md)

---

## Phase 5: QA & Integration

<!-- Decomposition Note: Phase 5는 Phase 4 완료(모든 Sprint 코드 구현)만 필요. QA 전담팀이 독립적으로 수행 가능하다. -->

> Reference Loading: `phase-5-qa.md` + (TRP 실행 시) `quality-gates.md`

전담 QA팀이 **통합 수준** 검증에 집중한다 (개별 Feature 테스트는 Phase 4에서 완료).

**핵심 활동:** Test Plan 수립 → **Code Pattern Scan** → Integration Testing → Performance Testing → Security Audit (OWASP Top 10)
**검증:** TRP (R1-QA Self, R2-Backend+Frontend Cross, R3-CTO Lead 프로덕션 레디니스)
이슈: CRITICAL/HIGH → 즉시 수정, MEDIUM → 사용자 판단.

For detailed process → read [phase-5-qa.md](references/phase-5-qa.md)

---

## Phase 6: Deployment & Operations

<!-- Decomposition Note: Phase 6은 Phase 5 완료만 필요. DevOps팀이 독립적으로 수행 가능하다. Phase 5-6은 'QA/배포' 묶음으로 함께 분리할 수도 있다. -->

> Reference Loading: `phase-6-deployment.md` + (TRP 실행 시) `quality-gates.md`

DevOps팀이 인프라 코드와 운영 준비를 완성한다.

**핵심 활동:** CI/CD Pipeline → Containerization → IaC → Monitoring & Alerting → Operations Readiness → **Deployment Checklist Generation** (infra-blueprint + runbook에서 배포 체크리스트 자동 생성, `state.json`에 등록)
**검증:** TRP (R1-DevOps Self, R2-Backend+QA Cross, R3-CTO Lead 프로덕션 안정성)

For detailed process → read [phase-6-deployment.md](references/phase-6-deployment.md)

---

## Phase 7: Delivery & Handoff

<!-- Decomposition Note: Phase 7은 Phase 6 완료만 필요. 검증+보고+PR 생성이 핵심이며, CEO가 독립적으로 수행 가능하다. -->

> Reference Loading: `phase-7-delivery.md`

**7-A: Final Verification** — 전체 빌드 + 테스트 + 린트 통과 확인, TRP 결과 취합, 미해결 이슈 목록
**7-B: Final Report** — PRD 대비 구현 현황, 팀별 기여, 검증 결과, 아키텍처, 미해결/보류, 향후 개선
**7-C: Guided Review** — 사용자에게 팀별 주요 산출물 순차 리뷰 → 피드백 → 수정 반영
**7-D: Completion Summary (P-012):**
```
=== 프로젝트 완료 ===
팀: {활성팀 목록}
Sprints: {N}회 완료
Features: {completed}/{total} 완료
변경: {N} 파일 (+{added} / -{removed} lines)
테스트: 전체 {pass}/{total} 통과
TRP: 전체 Phase {N}회 3라운드 통과
보안: CRITICAL {N}, HIGH {N}
미해결: {N}건
===
```
**7-E: Finalization** — 최종 커밋, PR 생성 (AskUserQuestion 후 `/git-push-pr`), 프로젝트 회고

For detailed process → read [phase-7-delivery.md](references/phase-7-delivery.md)

---

## Success Criteria

프로젝트 완료 전 모두 검증한다. 미충족 시 완료 불가.

- [ ] PRD의 모든 Must-have 기능 구현 완료
- [ ] 전체 빌드 성공 + 테스트 스위트 통과 (0 failures)
- [ ] 모든 Phase의 TRP 3라운드 통과 기록 있음
- [ ] 팀간 계약(Contract) 준수 확인
- [ ] 아키텍처 리뷰 CRITICAL 없음
- [ ] 보안 리뷰 CRITICAL 없음
- [ ] QA 테스트 통과
- [ ] 인프라 코드 완성 (CI/CD, Docker, 모니터링)
- [ ] 배포 런북 작성 완료
- [ ] 사용자 가이드 리뷰 완료
- [ ] 미해결 결정사항 문서화됨

---

## Global Forbidden Rules

`~/.claude/skills/simon-bot/references/forbidden-rules.md`의 3계층 규칙(ABSOLUTE / CONTEXT-SENSITIVE / AUDIT-REQUIRED)을 전체 적용한다. Runtime Guard(P-008)도 Phase 4-6에서 적용한다.

추가 금지:
- TRP 검토를 스킵하거나 형식적으로만 수행하는 것 — 각 라운드는 실질적 검증이어야 한다
- 팀간 계약(Contract) 없이 구현을 시작하는 것 — 나중에 통합할 때 재작업이 발생한다
- 다른 팀 소유 파일을 직접 수정하는 것 — 파일 소유권을 존중해야 머지 충돌을 방지한다

---

## Context Window Management

### Phase 4 세션 분할

Phase 4(Sprint Execution)는 Sprint 반복 사이클을 포함하므로, 각 Sprint 완료 시점이 자연스러운 세션 분할 지점이다.

| 경계 | 시점 | 저장 상태 |
|------|------|----------|
| 4-a | Sprint N 완료 후 | state.json (Sprint 진행 상태), 완료된 태스크 목록, 잔여 Sprint 계획 |

Sprint 완료 시 `state.json`에 Sprint 진행 상태를 기록한다:
```json
{
  "phase": 4,
  "phase_status": "in_progress",
  "current_substep": "4-B",
  "current_sprint": 2,
  "total_sprints": 4,
  "completed_tasks": ["TASK-001", "TASK-002"],
  "remaining_sprints": [3, 4],
  "active_checklists": []
}
```

다음 세션에서 `state.json`을 읽고 잔여 Sprint부터 이어간다. `phase_status`로 Phase 완료 여부를 명확히 구분하고, `active_checklists`가 있으면 해당 체크리스트 파일을 읽어 세부 진행 상태를 파악한다. 이를 통해 Phase 5(QA), 6(Deployment), 7(Delivery)가 컨텍스트 소진으로 누락되는 것을 방지한다.

For Checklist Protocol details (SSoT 역할 분리, 형식 표준, 적용 범위) → read [operational-protocols.md](references/operational-protocols.md)

---

## Reference Loading Policy

각 Phase 진입 시 해당 Phase의 레퍼런스 파일만 읽는다:
- **Phase 0-2** → `planning-design.md` + `team-roster.md`
- **Phase 3-4** → `contracts-execution.md`
- **Phase 5** → `phase-5-qa.md`
- **Phase 6** → `phase-6-deployment.md`
- **Phase 7** → `phase-7-delivery.md`
- **TRP 실행 시** → `quality-gates.md`
- **운영 프로토콜 참조 시** → `operational-protocols.md`
