# Sprint Planning & Execution (Phase 3-4)

## 목차
- [Phase 3: Sprint Planning & Backlog](#phase-3-sprint-planning--backlog)
  - [3-A: Inter-Team Contract Definition](#3-a-inter-team-contract-definition)
  - [3-B: Product Backlog 구성 (DEEP 원칙)](#3-b-product-backlog-구성-deep-원칙)
  - [3-C: Definition of Ready / Definition of Done](#3-c-definition-of-ready--definition-of-done)
  - [3-D: Sprint Planning](#3-d-sprint-planning)
- [Phase 4: Sprint Execution (Iterative)](#phase-4-sprint-execution-iterative)
  - [실행 아키텍처](#실행-아키텍처)
  - [Sprint Cycle](#sprint-cycle)
  - [4-A: Sprint Planning (매 Sprint 시작)](#4-a-sprint-planning-매-sprint-시작)
  - [4-B: Sprint Execution (simon-pm 위임)](#4-b-sprint-execution-simon-pm-위임)
  - [4-C: Sprint Review (Agent Team)](#4-c-sprint-review-agent-team)
  - [4-D: Sprint Retrospective (Agent Team)](#4-d-sprint-retrospective-agent-team)
  - [4-E: Backlog Refinement (Re-planning)](#4-e-backlog-refinement-re-planning)
  - [Failure Recovery](#failure-recovery)
  - [Progress Tracking](#progress-tracking)
  - [Sprint 실행 중 Progress Polling](#sprint-실행-중-progress-polling)

Phase 3 (Sprint Planning & Backlog)과 Phase 4 (Sprint Execution — Iterative)의 상세 프로세스.

---

## Phase 3: Sprint Planning & Backlog

### 3-A: Inter-Team Contract Definition

팀들이 독립적으로 구현하려면, 팀 간 인터페이스를 사전에 합의해야 한다. 계약 없이 병렬 구현을 시작하면 통합 시 재작업이 불가피하다.

**계약 유형별 템플릿**: `references/contract-templates.md` 참조
- API Contract (Backend ↔ Frontend, Backend ↔ ML) → Save: `.claude/company/contracts/api-spec.md`
- Data Contract (Backend ↔ DBA) → Save: `.claude/company/contracts/data-contracts.md`
- Component Contract (Design ↔ Frontend) → Save: `.claude/company/contracts/component-contracts.md`
- Event Contract (해당 시) → Save: `.claude/company/contracts/event-contracts.md`

### 3-B: Product Backlog 구성 (DEEP 원칙)

PRD + Architecture + Design + Contracts를 기반으로 Story Map의 Stories를 **Product Backlog**으로 변환한다.

**DEEP 원칙:**
- **Detailed** (적절히 상세): 상위 우선순위 항목은 즉시 구현 가능한 수준으로 상세, 하위는 대략적
- **Estimated** (규모 추정): 각 Feature에 S/M/L 규모 추정
- **Emergent** (변화 수용): Sprint마다 백로그를 재조정할 수 있음
- **Prioritized** (우선순위): P1 → P2 → P3 순서, Walking Skeleton 먼저

**규모 추정 기준:**

| 규모 | 파일 수 | 복잡도 | Bot 권장 |
|------|---------|--------|---------|
| **S** | 1-3개 | 단순 CRUD, 설정 | simon |
| **M** | 4-8개 | 비즈니스 로직 포함, 연동 있음 | simon |
| **L** | 9-15개 | 복잡한 로직, 다중 연동 | simon-grind |
| **XL** | 15개+ | → **분할 필수** (L 이하로) | - |

**각 Feature의 Task Spec (STICC 기반):**

각 Feature에 대해 `.claude/company/tasks/{feature-id}/spec.md`를 생성:

```markdown
# Task Spec: {Feature ID} - {Feature Name}

## Team: {담당 팀}
## Size: S / M / L
## Bot: simon | simon-grind

## Situation (현재 상태)
- 이 Feature 구현 전의 시스템 상태
- 선행 Feature 결과: {의존 Feature의 result.md}

## Task (구체적 작업)
- 변경 대상 파일 목록 (파일 경로 + 변경 유형)
- 구현해야 할 기능 목록

## Intent (의도와 목적)
- 이 Feature가 사용자에게 제공하는 가치

## Concerns (우려사항)
- Expert Panel에서 제기된 관련 concern
- 기술적 리스크

## Acceptance Criteria
### Code Changes
- [ ] 구현 항목 1
- [ ] 구현 항목 2

### Tests
- [ ] 테스트 항목 1

### Quality Gates
- [ ] 빌드 성공
- [ ] 린트 통과
- [ ] 테스트 커버리지 80%+

## File Ownership
- [이 Feature가 생성/수정할 파일 목록]
- 다른 팀 소유 파일 수정 금지

## Contract Compliance
- [준수해야 할 API/Data/Component Contract 항목]

## Spec Reference (spec.md에서 인라인 — SDD 원칙)
### User Story
[이 Feature가 구현하는 spec.md의 User Story 전문 — ID, 설명, 우선순위 포함]

### Acceptance Criteria
[해당 User Story의 Given/When/Then AC 전문 — 이것이 구현 완료의 기준이다]

## Context Bundle (CEO가 구성 — 경로 참조 금지, 내용 인라인 필수)

### Relevant Contracts (인라인)
[이 Feature와 관련된 계약 내용을 직접 복사·붙여넣기]
- API Contract: 이 Feature가 구현/소비하는 엔드포인트의 Request/Response 전체 명세
- Data Contract: 관련 테이블 ↔ API 매핑 전체
- Component Contract: 관련 컴포넌트의 Props, States, 토큰 규격

### External Schema Reference (DBA/Backend Feature 시 필수)
[`.claude/company/external-schemas.md`에서 관련 테이블의 전체 스키마를 복사]
- 특히 NOT NULL 컬럼, DEFAULT 값, 제약 조건을 빠짐없이 포함

### Sprint Shared Context
[`.claude/company/sprints/sprint-{N}/shared-context.md`에서 관련 팀 진행 상황 복사]
- 선행 Feature의 Integration Notes
- 다른 팀이 발견한 Gotchas

### Dependent Feature Results
[선행 Feature의 result.md에서 Integration Points + Discovered Constraints 복사]
```

**Structured Result Template:**

Feature 완료 시 `.claude/company/tasks/{feature-id}/result.md`에 아래 형식으로 기록한다. 이 파일은 후속 Feature의 Context Bundle에 인라인되므로, **다른 팀이 읽을 것을 전제**로 작성한다.

```markdown
# Result: {Feature ID} - {Feature Name}

## Team: {담당 팀}
## Status: completed

## Artifacts Created
| Type | Path | Description |
|------|------|-------------|
| 코드 | src/api/users.ts | 사용자 CRUD API |
| 테스트 | tests/api/users.test.ts | 12개 테스트 케이스 |
| 마이그레이션 | supabase/migrations/001_users.sql | users 테이블 생성 |

## API Endpoints (Backend Feature 시)
| Method | Path | Request Body | Response | Auth |
|--------|------|-------------|----------|------|
| POST | /api/users | { email, password } | 201: { id, email } | 불필요 |
| GET | /api/users/:id | - | 200: { id, email, name } | Bearer JWT |

## DB Changes (DBA Feature 시)
| Table | Action | Key Columns | Constraints |
|-------|--------|-------------|-------------|
| users | CREATE | id (uuid PK), email (unique), name | email NOT NULL |

## Integration Notes (다른 팀이 반드시 읽어야 할 사항)
- Frontend: POST /api/users 호출 시 409 DUPLICATE_EMAIL 에러 핸들링 필요
- DBA: users 테이블의 email 컬럼에 UNIQUE 인덱스 추가됨

## Discovered Constraints (구현 중 발견한 계약에 없던 제약)
- Supabase auth.users의 email_change 컬럼은 NOT NULL — seed.sql에 반드시 빈 문자열 포함
- JWT 토큰 만료 시간이 3600초로 하드코딩됨 (Supabase 대시보드에서 변경 필요)

## Verification
- [ ] 빌드 성공
- [ ] 테스트 통과 (12/12)
- [ ] Contract 준수 확인
- [ ] Sprint Shared Context 업데이트 완료
```

**분해 원칙:**
- 각 Feature는 **단일 팀이 소유** — 파일 소유권이 겹치지 않아야 한다
- 각 Feature는 simon 하나가 처리할 수 있는 크기 (파일 5-15개)
- Feature 간 의존성 최소화 — 병렬 실행을 가능하게 한다
- Contract을 기준으로 팀 간 경계를 나눈다
- User Story 단위로 그룹핑 — P1/P2/P3 우선순위 존중

**팀별 Feature 유형:**

| 팀 | 전형적 Feature | 산출물 |
|----|---------------|--------|
| DBA | DB 스키마 + 마이그레이션 | migration 파일, seed 데이터 |
| Backend | API 엔드포인트 + 비즈니스 로직 | API 코드 + 테스트 |
| Frontend | 화면 + 상호작용 | 컴포넌트 + 페이지 + 테스트 |
| DevOps | CI/CD + Docker + IaC | 설정 파일 |
| ML | 모델 + 파이프라인 | 모델 코드 + 학습 스크립트 |

Save: `.claude/company/backlog.json`

### 3-C: Definition of Ready / Definition of Done

**Definition of Ready (DoR) — Feature 시작 전 필수 조건:**

| # | 항목 | 미충족 시 |
|---|------|----------|
| 1 | INVEST 기준 충족 (Independent, Valuable, Small, Testable) | Story 재분할 |
| 2 | Acceptance Criteria 명시 (Given/When/Then) | PM이 보완 |
| 3 | 관련 Contract 정의 완료 | Contract 먼저 작성 |
| 4 | 의존 Feature 완료 또는 Mock/Stub 준비 | 의존성 해소 먼저 |
| 5 | 파일 소유권 확정 | CTO 조율 |
| 6 | 규모 추정 완료 (S/M/L) | 팀 리드 추정 |

DoR을 통과하지 않은 Feature는 Sprint에 포함하지 않는다.

**Definition of Done (DoD) — Feature 완료 기준:**

| # | 항목 | 검증 방법 |
|---|------|----------|
| 1 | 모든 Acceptance Criteria 통과 | 자동화 테스트 |
| 2 | 테스트 커버리지 80%+ | 커버리지 리포트 |
| 3 | 빌드 성공 + 린트 통과 | CI 검증 |
| 4 | Contract 준수 확인 (API, Data, Component) | Cross-Review |
| 5 | TRP R1-R3 통과 | 검토 기록 |
| 6 | 기술 부채 0건 또는 명시적 기록 | Self-Review |
| 7 | 코드 커밋 완료 | Git 확인 |
| 7a | **에러 처리 안전성**: 모든 catch 블록이 에러를 로깅하고 호출자에게 전파하는가? (silent fail 금지 — catch 후 빈 값/undefined 반환 금지) | Self-Review + grep 검증 |
| 7b | **타입 안전성**: `any` 타입 사용이 0건인가? (불가피한 경우 `// eslint-disable-next-line @typescript-eslint/no-explicit-any` + 사유 주석 필수) | Self-Review + grep 검증 |
| 7c | **리소스 정리**: 모든 subscription/listener/timer에 대응하는 cleanup 코드가 있는가? (useEffect return, unsubscribe, clearInterval 등) | Self-Review |
| 7d | **입력 경계값 검증**: 외부 입력(API 파라미터, 사용자 입력, 환경 변수)에 범위/형식 검증이 있는가? | Self-Review |
| 7e | **에러 경로 테스트**: 주요 함수의 에러 경로(네트워크 실패, 잘못된 입력, 권한 부족 등)에 대한 테스트가 존재하는가? | 테스트 파일 확인 |
| 8 | **spec.md의 해당 User Story AC 전체 충족 (SDD)** | Self-Review — Task Spec의 Spec Reference AC와 구현 대조 |
| 9 | **result.md를 Structured Result Template으로 작성** | Self-Review |
| 10 | **Sprint Shared Context의 Team Progress 업데이트** (Integration Notes, Discovered Constraints) | Self-Review |
| 11 | **(DBA/Backend) 실제 DB 스키마와 코드 쿼리 일치 확인** (`\d table` 대조) | Self-Review |
| 12 | **(DBA) Seed 데이터의 NOT NULL 컬럼 누락 없음** (외부 테이블 포함) | Self-Review |
| 13 | (Frontend) 디자인 토큰 일관 사용 — 하드코드 색상 없음 | Self-Review + Design Cross-Review |
| 14 | (Frontend) 빈/에러/로딩 상태 UI 구현 | Self-Review |
| 15 | (Frontend) 접근성: aria-live, aria-label, 호버 전용 인터랙션 없음 | Self-Review |

### 3-D: Sprint Planning

Story Map의 Release 구조와 Feature 의존성을 기반으로 Sprint를 구성한다.

**Sprint 구성 원칙:**
- **Sprint 1은 Walking Skeleton**: 핵심 흐름의 최소 구현 (가입 → 핵심 기능 → 결과 확인)
- 각 Sprint는 **동작하는 소프트웨어 증분(increment)** 산출
- Sprint 내 Feature들은 가능한 한 독립적 (병렬 실행 가능)
- 의존성 있는 Feature는 같은 Sprint의 앞 순서에 배치

**Sprint 계획 시각화:**

```
Sprint 1 (Walking Skeleton) ─┬─ [F1: 초기 설정] (DevOps, simon)
                              ├─ [F2: DB 스키마] (DBA, simon)
                              └─ [F3: 기본 인증 API] (Backend, simon)
         ↓
Sprint 2 ─┬─ [F4: 사용자 인증 UI] (Frontend, simon)
           ├─ [F5: 상품 API] (Backend, simon-grind)
           └─ [F6: 상품 목록 UI] (Frontend, simon)
         ↓
Sprint 3 ─┬─ [F7: 결제 API] (Backend, simon-grind)
           ├─ [F8: 관리자 대시보드] (Frontend, simon)
           └─ [F9: CI/CD 파이프라인] (DevOps, simon)
         ↓
Sprint 4 (Hardening) ─── [F10: 모니터링 + 성능 최적화] (DevOps + QA)
```

AskUserQuestion으로 사용자 승인 후 Phase 4 진행.

Save: `.claude/company/sprint-plan.md`

---

## Phase 4: Sprint Execution (Iterative)

### 실행 아키텍처

CEO가 직접 개별 Feature agent를 관리하지 않는다. 대신:
- **simon-pm**: Sprint의 모든 코드 구현을 위임받아 simon/grind를 관리
- **Agent Team**: Sprint Review/Retro 시 팀 리드를 소집하여 Cross-Review 수행

### Sprint Cycle

```
for each sprint in sprint_plan:

    ═══ 4-A: Sprint Planning ═══
    DoR 검증 → 실행 순서 결정 → Bot 할당

    ═══ 4-B: Sprint Execution (simon-pm 위임) ═══
    simon-pm subagent 스폰 (background)
    CEO는 TaskOutput polling으로 진행 상황 모니터링

    ═══ 4-C: Sprint Review (Agent Team) ═══
    TeamCreate로 팀 리드 소집 → Cross-Review → DoD 검증 + TRP + 통합 검증
    사용자에게 Sprint 결과 데모 → TeamDelete로 해산

    ═══ 4-D: Sprint Retrospective (Agent Team) ═══
    TeamCreate → Keep/Problem/Try 논의 → TeamDelete

    ═══ 4-E: Backlog Refinement ═══
    다음 Sprint를 위한 백로그 재조정

    진행 상황 보고
```

### Sprint Shared Context 초기화

각 Sprint 시작 시 CEO가 `.claude/company/sprints/sprint-{N}/shared-context.md`를 생성한다. 이 파일은 Sprint 동안 모든 팀이 기여하고 참조하는 **살아있는 문서**다.

```markdown
# Sprint {N} Shared Context

## External Schemas (Phase 2 GTV 결과에서 복사)
[이 Sprint에서 사용하는 외부 테이블 스키마 — external-schemas.md에서 관련 부분 인라인]

## Active Contracts (Phase 3 결과에서 관련 부분 인라인)
### API Contract
[이 Sprint의 Feature가 구현/소비하는 API 엔드포인트 명세]
### Data Contract
[이 Sprint에서 사용하는 테이블 ↔ API 매핑]
### Component Contract
[이 Sprint의 Frontend Feature 관련 컴포넌트 규격]

## Team Progress & Outputs
각 Feature 완료 시 담당 팀이 아래 형식으로 항목을 추가한다:

### {Team} — {Feature ID}: {Feature Name} [completed]
- **생성/변경**: [파일, 테이블, 엔드포인트 목록]
- **Integration Notes**: [다른 팀이 알아야 할 사항]
- **Discovered Constraints**: [계약에 없던 제약사항]
- **Gotchas**: [비직관적인 동작, 예상과 다른 점]

## Cross-Team Issues (Sprint Review/Retro에서 발견된 이슈)
[Sprint Review/Retro에서 나온 팀 간 이슈를 누적 기록]
```

**규칙:**
1. CEO가 Sprint 시작 시 External Schemas + Active Contracts를 인라인으로 채워 초기화
2. 각 Feature Bot은 구현 완료 시 Team Progress 섹션에 항목 추가 (result.md 작성과 동시)
3. 모든 Feature Bot은 구현 시작 전 이 파일을 **반드시 Read**
4. Sprint Review/Retro에서 발견된 이슈는 Cross-Team Issues에 누적

### 4-A: Sprint Planning (매 Sprint 시작)

1. **DoR 게이트**: 이번 Sprint의 모든 Feature가 DoR을 통과하는지 확인
   - 미통과 Feature → Sprint에서 제외하고 다음 Sprint으로 이동
   - 의존 Feature가 이전 Sprint에서 완료되지 않은 경우 → Mock/Stub으로 대체 가능한지 판단

2. **실행 순서 결정**: Sprint 내 Feature 의존성 그래프 작성
   - 독립적 Feature → simon-pm이 병렬 실행
   - 의존적 Feature → simon-pm에게 순서 지정

3. **Bot 할당 가이드** (simon-pm에 전달):
   - S/M → simon, L → simon-grind
   - 이전 Sprint에서 실패 이력이 있는 팀 → simon-grind 우선

### 4-B: Sprint Execution (simon-pm 위임)

CEO가 simon-pm을 **background subagent**로 스폰한다. simon-pm은 Sprint의 모든 코드 생산 팀(FE, BE, DBA, DevOps, QA, ML)의 Feature를 관리한다.

**위임 프롬프트**: `references/sprint-execution-templates.md` 의 "simon-pm 위임 프롬프트" 참조

**Pre-Implementation Verification (각 Feature Bot 필수):**

Feature Bot이 코드 작성을 시작하기 전에 반드시 수행하는 검증 단계. Task Spec의 Context Bundle에 포함된 정보를 확인하고, 실제 시스템 상태와 대조한다.

| 팀 | 필수 검증 항목 | 검증 방법 |
|----|--------------|----------|
| **DBA** | 외부 테이블 스키마 일치 확인 | `\d table_name`으로 실제 스키마 조회 → Context Bundle의 External Schema와 대조 |
| **Backend** | API Contract의 엔드포인트 명세 확인 | Context Bundle의 API Contract 읽기 → 구현할 엔드포인트 목록 확인 |
| **Backend** | 사용할 DB 테이블 스키마 확인 | Context Bundle의 Data Contract + External Schema 읽기 → NOT NULL 컬럼/기본값 확인 |
| **Frontend** | 소비할 API 엔드포인트 확인 | Context Bundle의 API Contract 읽기 → Request/Response 형식 확인 |
| **Frontend** | 디자인 토큰/컴포넌트 규격 확인 | Context Bundle의 Component Contract 읽기 |
| **모든 팀** | Sprint Shared Context 확인 | shared-context.md Read → 다른 팀의 Integration Notes/Gotchas 파악 |
| **모든 팀** | 선행 Feature 결과 확인 | 의존 Feature의 result.md Read → Integration Notes/Discovered Constraints 파악 |
| **모든 팀** | **Spec의 User Story + AC 확인 (SDD)** | Task Spec의 Spec Reference 섹션 Read → 구현할 기능의 목적과 완료 기준 파악 |

**불일치 발견 시**: 구현을 멈추고 CEO에게 보고 → Contract 수정 후 재개

simon-pm은:
1. Feature를 독립적인 작업으로 분해
2. 각 작업에 simon 또는 simon-grind 배정
3. 병렬 실행 가능한 작업은 동시 실행 (max 3)
4. 의존성 있는 작업은 순차 실행
5. 완료된 Feature의 DoD 1차 검증 (R1 Self-Review)
6. **Feature 완료 시 result.md 작성 + shared-context.md 업데이트 확인**

### Sprint @reviewer Teammate (Feature 3개+ Sprint)

Feature 3개 이상인 Sprint에서 실시간 교차 검증을 수행하는 전용 읽기 전용 리뷰어를 Agent Team에 추가한다. 검증이 Sprint Review(4-C)에서 사후적으로만 이루어지면, Feature 간 인터페이스 불일치를 너무 늦게 발견하여 대규모 재작업이 발생할 수 있다.

**역할 구성:**
- **도구**: Read, Glob, Grep, Bash(빌드/린트/테스트 실행만) — Edit/Write 금지
- **트리거**: 각 Feature의 simon이 Step 8(SMALL) 또는 Step 17(STANDARD+)을 완료할 때 자동 리뷰 수행
- **비율**: 빌더 3-4명당 리뷰어 1명

**리뷰 범위:**
1. **Contract 준수 확인**: Feature의 구현이 `contracts/`의 API/Data/Component Contract을 준수하는지 검증
2. **공유 파일 수정 감지**: Feature가 자신의 File Ownership 외의 파일을 수정했는지 git diff로 확인
3. **전체 빌드/테스트 통과**: 해당 Feature 커밋 후 전체 빌드 + 테스트 통과 확인
4. **Sprint Shared Context 일관성**: result.md와 shared-context.md가 갱신되었는지 확인

**이슈 발견 시 행동:**
- CRITICAL (Contract 위반, 빌드 실패): 해당 Feature의 simon에게 즉시 SendMessage로 전달 → Sprint Review 전 조기 수정
- HIGH (공유 파일 수정): CEO에게 보고 → 파일 소유권 재확인
- LOW (shared-context 미갱신): 해당 Feature의 simon에게 알림

**적용 조건:** Feature 2개 이하 Sprint에서는 오버헤드가 이득보다 크므로 적용하지 않는다. Sprint Review(4-C)의 사후 검증으로 충분하다.

**Spawn Prompt:**
```
<role>
sprint-reviewer — Sprint 실행 중 실시간 교차 검증 리뷰어
Mode: VERIFICATION
Tools ALLOWED: [Read, Glob, Grep, Bash(빌드/린트/테스트만)]
Tools FORBIDDEN: [Edit, Write] — 읽기 전용으로 코드를 수정하지 않는다
</role>

<context>
- contracts/ 디렉토리의 API/Data/Component Contract
- Sprint Shared Context (.claude/company/sprints/sprint-{N}/shared-context.md)
- Feature별 File Ownership (tasks/{feature-id}/spec.md)
</context>

<instructions>
1. Feature 완료 알림 수신 시 해당 Feature의 diff를 확인한다
2. contracts/ 준수, 파일 소유권, 빌드/테스트 통과를 검증한다
3. 이슈 발견 시 severity 분류 후 해당 Feature의 simon 또는 CEO에게 보고한다
</instructions>
```

### 4-C: Sprint Review (Agent Team)

Sprint의 모든 Feature가 완료되면 **Agent Team**으로 팀 리드를 소집하여 검증한다.

**Step 1: Team 소집**
```
TeamCreate:
  name: "Sprint-{N}-Review"
  members: CEO (facilitator) + CTO (architecture guardian) + 해당 Sprint 참여 팀 리드
```

**Step 2: DoD 검증** — Acceptance Criteria, 테스트 커버리지 80%+, 빌드+린트, Contract 준수

**Step 3: Cross-Review via SendMessage** — 팀 리드 간 계약 준수 검증
(흐름 예시: `references/sprint-execution-templates.md` 참조)

이 과정이 TRP의 R2 (Cross-Review)를 대체한다.

**Step 4: TRP 최종**
- R1: simon-pm이 이미 수행 (Feature 완료 시 Self-Review)
- R2: Agent Team Cross-Review (Step 3)
- R3: CTO Lead-Review (아키텍처/품질 최종 검증)

**Step 5: Sprint Integration** — 전체 빌드, Feature 간 연동 테스트, 회귀 테스트

**Step 6: Sprint Demo** — 사용자에게 결과 보고
(보고 형식: `references/sprint-execution-templates.md` 참조)

**Step 7: Team 해산** → `TeamDelete: "Sprint-{N}-Review"`

### 4-D: Sprint Retrospective (Agent Team)

Sprint Review 완료 후 프로세스 개선점을 식별한다.

**Step 1**: `TeamCreate: "Sprint-{N}-Retro"` (CEO + CTO + 활성 팀 리드)
**Step 2**: SendMessage로 Keep/Problem/Try 논의 (예시: `references/sprint-execution-templates.md` 참조)

**Step 3: 개선 액션 도출**

| 카테고리 | 개선 액션 | 적용 Sprint |
|---------|----------|-------------|
| Keep | Task Spec + Contract 기반 구현 유지 | 계속 |
| Problem → Try | API Mock 선행 제공 → 의존 Feature 대기 시간 감소 | Sprint N+1 |
| Problem → Try | Feature별 CI 통합 테스트 → Sprint 마지막 병목 해소 | Sprint N+1 |

**기록 항목:** DoR/DoD 기준 조정, 팀 간 계약 수정, Bot 전환 이력, TRP 반복 리젝 패턴

Save: `.claude/company/sprints/sprint-{N}-retro.md`

**Step 4**: `TeamDelete: "Sprint-{N}-Retro"`

### 4-E: Backlog Refinement (Re-planning)

Sprint Retro 결과를 바탕으로 다음 Sprint의 백로그를 재조정한다.

**재조정 대상:**
- 이월된 Feature → 다음 Sprint 상위에 배치
- 새로운 요구사항 → 백로그에 추가 (DEEP 원칙 적용)
- 기술 부채 → severity에 따라 우선순위 결정
- 계약 수정 필요 시 → Contract 업데이트 후 관련 Feature 재검토
- Retro 개선 액션 → 다음 Sprint의 DoR/실행 방식에 반영

**변경이 큰 경우 (Sprint 범위 20%+ 변경):** AskUserQuestion으로 승인 후 `backlog.json` + `sprint-plan.md` 갱신

### Failure Recovery

| 실패 유형 | 1차 | 2차 | 3차 |
|----------|-----|-----|-----|
| simon-pm 실패 | 에러 로그 → 재스폰 | Spec 수정 후 재시도 | 사용자 에스컬레이션 |
| 빌드 실패 | 내부 자동 수정 | simon-grind 전환 | 사용자 에스컬레이션 |
| Contract 위반 | Cross-Review에서 발견 → 수정 | 계약 자체 수정 제안 | CTO 중재 |
| 파일 소유권 침범 | 복원 + 올바른 팀에 재위임 | 계약 재조정 | CTO 중재 |
| 팀간 의존성 실패 | 실행 순서 재조정 | Sprint 범위 조정 | 사용자 에스컬레이션 |
| DoD 미충족 | 다음 Sprint로 이월 | simon-grind 재시도 | 사용자 에스컬레이션 |

### Progress Tracking

`.claude/company/progress.md`에 Sprint별 + 팀별 진행 현황:

```markdown
## Progress — Sprint 2/4 — [8/15 Features] ████████████░░░░░ 53%

### Sprint 2 (Current) — simon-pm 관리 중:
| Feature | Team | Status | DoD | Notes |
|---------|------|--------|-----|-------|
| F4 | Backend | completed | PASS | |
| F5 | Frontend | running | - | simon-pm 관리 중 |
| F6 | Backend | pending | - | DoR: OK |

### Sprint History:
| Sprint | Features | Completed | Carry-over | Notes |
|--------|----------|-----------|------------|-------|
| 1 | 3 | 3 | 0 | Walking Skeleton 완료 |
| 2 | 5 | 2 (진행중) | - | |
```

### Sprint 실행 중 Progress Polling

**Polling 프로토콜:**
1. **완료 알림 수신 시**: 즉시 progress.md 갱신 + 사용자에게 Sprint 결과 보고
2. **running 상태일 때**: TaskOutput(block=false)로 현재 진행 상태 확인
3. **사용자 질문 시**: 최신 progress.md 기반으로 현황 보고

**보고 형식:**
```
[Sprint 2 진행] F4 완료 (Backend) | F5 실행 중 (Frontend) | F6 대기 중
전체: 9/15 Features ██████████████░░░ 60%
```

매 Sprint 완료 시 갱신.
