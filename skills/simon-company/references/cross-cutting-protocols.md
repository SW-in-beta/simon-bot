# Cross-Cutting Protocols

Sprint 실행 전반에 걸친 공통 프로토콜.

## Triple Review Protocol (TRP)

모든 Phase의 핵심 산출물은 **3라운드 검토**를 통과해야 다음 Phase로 진행한다.

| Round | 검토자 | 관점 | 통과 기준 |
|-------|--------|------|----------|
| **R1: Self-Review** | 산출물 작성 팀 | "내가 빠뜨린 건 없는가?" | Phase별 체크리스트 100% PASS |
| **R2: Cross-Review** | 다른 전문 팀 | "내 팀이 이걸로 일할 수 있는가?" | 실행 가능성 + 연동성 검증 |
| **R3: Lead Review** | CTO 또는 담당 VP | "프로젝트 비전과 품질 기준에 부합하는가?" | 전략적 정합성 + 최종 승인 |

**실패 시**: 실패한 라운드부터 재검토 (이전 통과 라운드 유지). 3회 연속 실패 → CEO가 사용자에게 에스컬레이션. 검토 결과는 `.claude/company/quality/phase-{N}-review.md`에 누적 기록.

**경량 TRP (Minor Phase용):**
설정 파일 변경, 문서 갱신 등 위험도가 낮은 산출물에는 경량 TRP를 적용할 수 있다:
- R1 (Self-Review)만 수행 + R3 (Lead)는 사후 확인
- R2 (Cross-Review)는 생략
- 적용 조건: 산출물이 코드 변경을 포함하지 않고, 다른 팀의 작업에 직접 영향을 주지 않을 때
- 판단은 CEO가 하고, `[Decision] 경량 TRP 적용 — {이유}` 형식으로 기록

For checklists and review agent prompts → read [quality-gates.md](quality-gates.md)

## Dynamic Team Roster

프로젝트 특성에 따라 필요한 팀만 편성한다.

| 팀 | 활성화 조건 |
|----|------------|
| **PM, CTO, QA** | 항상 |
| **Design** | UI/UX가 필요한 프로젝트 |
| **Frontend** | 사용자 인터페이스가 있는 프로젝트 |
| **Backend** | API, 비즈니스 로직이 필요한 프로젝트 |
| **DBA** | DB가 필요한 프로젝트 |
| **DevOps** | 배포/인프라가 필요한 프로젝트 |
| **ML** | ML/AI 기능이 포함된 프로젝트 |

For team definitions, agent prompts, activation logic → read [team-roster.md](team-roster.md)

## Decision Trail

주요 판단 지점에서 1줄 판단 근거를 제시한다:
- **Team Activation** (Phase 0): 팀 편성/제외 이유
- **Architecture Decisions** (Phase 2): 기술 선택 이유
- **Task Assignment** (Phase 3): 팀별 작업 할당 이유
- **TRP Rejection** (모든 Phase): 리젝 사유와 기대 수정 방향
- **Deployment Strategy** (Phase 6): 배포 전략 선택 이유

형식: `[Decision] Design팀 비활성화 — CLI 프로젝트로 UI 없음`

## Session Isolation Protocol

동시에 여러 세션이 같은 레포에서 작업할 때 `.claude/company/` 하위 런타임 파일의 충돌을 방지한다. 세션별 런타임 데이터를 홈 디렉토리에 격리 저장한다.

**Phase 0에서 SESSION_DIR 결정:**
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
SESSION_ID="company-$(date +%Y%m%d-%H%M%S)"
SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${SESSION_ID}"
mkdir -p "${SESSION_DIR}/company"
echo "${SESSION_DIR}" > "${SESSION_DIR}/company/session-path.txt"
```

**경로 매핑** — 이 스킬과 모든 레퍼런스 파일에서 아래 런타임 경로는 `{SESSION_DIR}` 기준으로 해석한다:

| 스킬 내 표기 | 실제 저장 위치 |
|-------------|--------------|
| `.claude/company/*` | `{SESSION_DIR}/company/*` |

프로젝트의 `.claude/workflow/` (config, scripts)는 공유 설정이므로 프로젝트 디렉토리에서 그대로 읽는다.

**simon-pm 위임 시**: Phase 4에서 simon-pm subagent를 spawn할 때, `{SESSION_DIR}`을 전달하여 PM이 동일 세션 디렉토리 내에서 작업하도록 한다.

## Shared Context Protocol

Sprint 실행 중 팀 간 컨텍스트를 **파일 기반으로** 공유한다. 프롬프트 텍스트 전달에만 의존하면 컨텍스트 압축 시 정보가 손실되므로, 디스크의 공유 파일을 Single Source of Truth로 사용한다.

**핵심 메커니즘:**

| 메커니즘 | 파일 위치 | 작성 시점 | 읽기 시점 |
|---------|----------|----------|----------|
| **Sprint Shared Context** | `.claude/company/sprints/sprint-{N}/shared-context.md` | CEO가 Sprint 시작 시 초기화 + 각 Feature 완료 시 업데이트 | 모든 Feature Bot이 구현 시작 전 필수 Read |
| **Structured Result** | `.claude/company/tasks/{feature-id}/result.md` | Feature 완료 시 담당 Bot이 표준 형식으로 작성 | 후속 의존 Feature의 Bot이 필수 Read |
| **External Schema Registry** | `.claude/company/external-schemas.md` | Phase 2에서 실제 시스템 introspect 후 작성 | DBA/Backend Bot이 코드 작성 전 필수 Read |

**원칙:**
- 파일 경로만 알려주지 말고, Task Spec에 관련 계약 내용을 **인라인**으로 포함한다
- 모든 팀 산출물에 **Integration Notes** 섹션을 포함하여, 다른 팀이 이 산출물을 사용할 때 알아야 할 사항을 명시한다
- Sprint Review/Retro에서 발견된 이슈는 shared-context.md에 누적 기록한다

For detailed templates and process → read [contracts-execution.md](contracts-execution.md)

## Spec-Driven Development (SDD)

`spec.md`는 기능 요구사항의 **Single Source of Truth**다. 아키텍처, 계약, 구현, 테스트 — 모든 것이 Spec에서 시작하고, Spec과 대조하여 검증한다. Spec 없이 구현하면 "무엇을 만드는지" 모른 채 코드를 쓰는 것과 같다.

**원칙:**
1. **Spec-First**: 구현 코드를 한 줄도 쓰기 전에, 해당 기능의 User Story + Acceptance Criteria가 `spec.md`에 존재해야 한다
2. **Spec-as-Reference**: 모든 Phase에서 `spec.md`를 기준 문서로 참조한다. "왜 이 기능을 만드는가?"의 답은 항상 Spec에 있다
3. **Spec-Traceable**: 구현 결과물은 Spec의 User Story ID로 추적 가능해야 한다 (Task Spec → User Story 매핑)
4. **Spec-Verified**: Sprint Review에서 구현을 Spec의 Acceptance Criteria와 대조 검증한다. AC를 통과하지 못하면 DoD 미충족이다

**Phase별 적용:**

| Phase | Spec 활용 |
|-------|----------|
| **Phase 1** | spec.md 작성 (User Stories + AC) — 이후 모든 Phase의 입력 |
| **Phase 2** | 아키텍처/설계가 spec.md의 요구사항을 충족하는지 검증 |
| **Phase 3** | 각 Feature의 Task Spec에 `spec.md`의 해당 User Story + AC를 인라인 |
| **Phase 4** | Bot이 구현 전 Task Spec의 User Story + AC를 읽고, 구현 후 AC 대조 |
| **Phase 5** | 테스트 계획이 spec.md의 모든 P1 User Story를 커버하는지 검증 |
| **Phase 7** | 최종 검증에서 spec.md의 전체 AC 충족률 보고 |

## Ground Truth Verification (GTV)

계약 문서가 아무리 정교해도, 실제 시스템 상태와 다르면 무의미하다. GTV는 문서와 실제 시스템의 일치를 보장한다.

**적용 시점:**
- **Phase 2 (설계)**: 기존/관리형 서비스의 실제 DB 스키마를 introspect하여 `external-schemas.md`에 기록. `\d table_name`, `SHOW CREATE TABLE` 등으로 실제 컬럼·제약·기본값을 전부 수집한다.
- **Phase 3 (계약)**: Data Contract에 외부 스키마 참조를 포함한다. INSERT/UPDATE 대상 테이블의 NOT NULL 컬럼 전체 목록을 명시한다.
- **Phase 4 (구현)**: Bot이 DB 관련 코드 작성 전 `\d table_name`으로 실제 스키마를 확인한다. 계약과 불일치 시 계약을 먼저 수정하고 구현한다.

For detailed introspection process → read [planning-design.md](planning-design.md) (Phase 2-C)

## Docs-First Protocol

LLM의 학습 데이터에 의존하지 않고 공식 문서를 먼저 조회하는 원칙. 자세한 프로토콜은 `~/.claude/skills/simon-dev/references/docs-first-protocol.md` 참조.

**적용 시점:**
- **Phase 2 (설계)**: 기술 스택 선택 시 공식 문서로 기능·제약·호환성을 확인한다.
- **Phase 4 (구현)**: 처음 사용하는 API/설정에 대해 공식 문서를 조회하고, 조회한 문서 소스를 result.md에 기록한다.
- **Phase 6 (배포)**: 외부 서비스 설정 안내 시 공식 문서를 조회한다. 서비스명 변경·UI 경로 변경을 WebSearch로 확인한다.

## Subagent 및 Agent Team 사용 기준

| 상황 | 수행 방식 |
|------|----------|
| 단일 파일 수정, 간단한 설정 | CEO 직접 수행 |
| TRP 리뷰 | 리뷰어 역할의 subagent spawn |
| Sprint 코드 구현 (전체 Feature) | simon-pm subagent → simon/grind 관리 |
| Sprint Review / Retro | Agent Team (TeamCreate → SendMessage로 팀 리드 소집) |
| 전문 팀 분석 (Architecture, Design) | subagent |

## Error Resilience

`~/.claude/skills/simon-dev/references/error-resilience.md`의 프로토콜을 적용한다.
추가: 팀 간 충돌 → CTO 중재 / TRP 교착 → CEO 스코프 축소 또는 사용자 에스컬레이션 / Bot 3회 실패 → simon-grind 자동 전환.

For state management, artifact persistence, context window management → read [operational-protocols.md](operational-protocols.md)
For agile methodology details (INVEST, Story Mapping, DEEP, Sprint Cycle, Plan Review) → read [operational-protocols.md](operational-protocols.md)
