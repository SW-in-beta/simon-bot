# Quality Gates — Triple Review Protocol (TRP)

## 목차
- [TRP 실행 절차](#trp-실행-절차)
  - [Round 1: Self-Review (자체 점검)](#round-1-self-review-자체-점검)
  - [Round 2: Cross-Review (교차 검토)](#round-2-cross-review-교차-검토)
  - [Round 3: Lead Review (리드 승인)](#round-3-lead-review-리드-승인)
- [TRP Round Differentiation](#trp-round-differentiation)
  - [TRP Anti-patterns](#trp-anti-patterns)
- [Phase별 체크리스트](#phase별-체크리스트)
  - [Phase 1: Discovery & Spec](#phase-1-discovery--spec)
  - [Phase 2: Architecture & Design Sprint](#phase-2-architecture--design-sprint)
  - [Phase 3: Sprint Planning & Backlog](#phase-3-sprint-planning--backlog)
  - [Phase 4: Sprint Execution — Feature별 + Sprint 단위](#phase-4-sprint-execution--feature별--sprint-단위)
  - [Phase 5: QA & Integration](#phase-5-qa--integration)
  - [Phase 6: Deployment & Operations](#phase-6-deployment--operations)
- [TRP 결과 저장 형식](#trp-결과-저장-형식)
- [Escalation Protocol](#escalation-protocol)
  - [TRP 교착 상태 처리](#trp-교착-상태-처리)

모든 Phase의 핵심 산출물은 3라운드 검토를 통과해야 한다. 이 문서는 각 라운드의 상세 절차, Phase별 체크리스트, 리뷰 에이전트 프롬프트를 정의한다.

---

## TRP 실행 절차

### Round 1: Self-Review (자체 점검)

산출물을 작성한 팀/에이전트가 자신의 결과물을 체크리스트로 검증한다.

**실행 방식**: 산출물 작성 에이전트가 작업 완료 후 즉시 수행. 별도 subagent 불필요.

**리뷰 프롬프트 템플릿:**
```
당신은 방금 작성한 산출물의 자체 검토를 수행합니다.
아래 체크리스트의 모든 항목을 하나씩 검증하세요.

[Phase별 R1 체크리스트 삽입]

검증 결과를 다음 형식으로 작성하세요:

## Self-Review: Phase {N} - {Phase Name}
### 체크리스트 결과:
- [x] 항목 1 - PASS (근거: ...)
- [ ] 항목 2 - FAIL (이유: ..., 수정 방향: ...)

### 종합 판정: PASS / FAIL
### FAIL 항목 수정 계획: (FAIL 시)
```

### Round 2: Cross-Review (교차 검토)

다른 전문 팀의 관점에서 "이 산출물로 내 팀이 일할 수 있는가?"를 검증한다.

**실행 방식**: `general-purpose` subagent를 spawn. 교차 검토 팀의 역할과 전문성을 프롬프트에 명시.

**리뷰 프롬프트 템플릿:**
```
당신은 {Cross-Review팀 역할}입니다. 다른 팀이 작성한 산출물을 검토합니다.
당신의 관점에서 이 산출물의 품질과 실행 가능성을 평가하세요.

검토 대상: {산출물 파일 경로}
당신의 전문 영역: {팀 전문성}

아래 체크리스트로 검증하되, 체크리스트에 없더라도
당신의 전문성에서 발견되는 문제는 추가로 지적하세요.

[Phase별 R2 체크리스트 삽입]

검증 결과를 다음 형식으로 작성하세요:

## Cross-Review: Phase {N} - {Phase Name}
### 검토자: {역할}
### 체크리스트 결과:
- [x] 항목 1 - PASS
- [ ] 항목 2 - FAIL (이유: ..., 제안: ...)

### 추가 발견사항:
- [severity] {발견 내용}

### 종합 판정: PASS / FAIL
```

### Round 3: Lead Review (리드 승인)

CTO 또는 담당 VP가 전략적 정합성과 최종 품질을 검증한다. 가장 엄격한 기준을 적용한다.

**실행 방식**: `general-purpose` subagent를 spawn. CTO/VP 역할의 엄격한 리뷰어로 설정.

**리뷰 프롬프트 템플릿:**
```
당신은 이 프로젝트의 {CTO/VP 역할}입니다. 깐깐한 기술 리더로서
산출물의 최종 승인 여부를 결정합니다.

당신은 높은 기준을 가지고 있습니다:
- "괜찮은 수준"은 통과가 아닙니다. "우수한 수준"이어야 합니다.
- 모호하거나 불완전한 부분은 반드시 지적합니다.
- 미래에 문제가 될 소지가 있는 설계는 사전에 잡아냅니다.
- 프로젝트 Constitution에 위배되는 내용은 즉시 리젝합니다.

검토 대상: {산출물 파일 경로}
프로젝트 Constitution: .claude/company/constitution.md
이전 라운드 결과: {R1, R2 결과 파일 경로}

[Phase별 R3 체크리스트 삽입]

검증 결과를 다음 형식으로 작성하세요:

## Lead Review: Phase {N} - {Phase Name}
### 검토자: {CTO/VP 역할}
### 전략적 정합성: PASS / FAIL
### 품질 수준: Excellent / Good / Acceptable / Below Standard
### 체크리스트 결과:
- [x] 항목 1 - PASS
- [ ] 항목 2 - FAIL (이유: ..., 기대 수준: ...)

### 종합 판정: APPROVED / REJECTED
### REJECTED 사유: (있으면)
### 수정 지시사항: (있으면, 구체적으로)
```

---

## TRP Round Differentiation

각 라운드는 서로 다른 관점에서 검증한다. "검증하라"는 자명한 지시이므로, 각 라운드의 고유한 초점을 명시한다.

| Round | 역할 | 검증 초점 | 검증하지 않는 것 |
|-------|------|----------|---------------|
| R1 Self | 산출물 소유팀 | 내부 완전성: 누락 항목, 논리적 일관성, spec 대비 커버리지 | 다른 팀 산출물과의 정합성 |
| R2 Cross | 인접팀 | 인터페이스 정합성: 나의 입력으로 사용할 때 문제 없는가? 계약 준수? | 내부 구현 품질 (R1의 영역) |
| R3 Lead | CTO/CEO | 시스템 수준: 전체 아키텍처 정합성, 비기능 요구사항(성능, 보안, 확장성), 비즈니스 목표 부합 | R1/R2에서 PASS된 항목의 재검증 (FAIL만 재확인) |

### TRP Anti-patterns
- R2에서 "코드 스타일이 안 맞다" → R1의 영역, Cross에서는 인터페이스만 검증
- R3에서 "변수명이 모호하다" → R1의 영역, Lead는 시스템 수준에 집중
- R1에서 "다른 팀의 API가 변경되면 어떻게 하나" → R2의 영역, Self는 자기 산출물에 집중

---

## Phase별 체크리스트

### Phase 1: Discovery & Spec

**R1 (PM Self-Review):**
- [ ] 모든 User Story에 P1/P2/P3 우선순위가 있는가?
- [ ] P1 스토리만으로 MVP가 가능한가?
- [ ] 각 스토리에 Given/When/Then 수용 시나리오가 있는가?
- [ ] 모든 User Story가 INVEST 기준을 충족하는가? (Independent, Negotiable, Valuable, Estimable, Small, Testable)
- [ ] Story Map이 사용자 여정을 Activity → Task → Story로 구조화하고 있는가?
- [ ] Walking Skeleton(핵심 흐름의 최소 구현)이 Release 1로 식별되었는가?
- [ ] Functional Requirements에 기술 구현 디테일이 섞이지 않았는가?
- [ ] [NEEDS CLARIFICATION] 마커가 3개 이하인가?
- [ ] Success Criteria가 측정 가능하고 기술에 무관한가?
- [ ] Edge Cases가 최소 3개 이상 식별되었는가?
- [ ] Constitution의 Core Principles가 명확한가?
- [ ] planner-critic-architect 검증을 통과했는가? (4축 모두 4점 이상)

**R2 (Design Cross-Review — Design팀 활성 시):**
- [ ] 사용자 시나리오에 UX 관점 빈틈이 없는가?
- [ ] 핵심 사용자 흐름(happy path)이 명확한가?
- [ ] 에러 상태의 사용자 경험이 정의되어 있는가?
- [ ] 접근성 요구사항이 고려되었는가?
- [ ] 화면/인터랙션 관련 요구사항이 충분히 구체적인가?

**R2 (CTO Cross-Review — Design팀 비활성 시):**
- [ ] 기술적으로 구현 가능한 요구사항인가?
- [ ] 성능/규모 관련 요구사항이 현실적인가?
- [ ] 보안 관련 요구사항이 누락되지 않았는가?

**R3 (CTO Lead-Review):**
- [ ] Spec의 범위가 프로젝트 목표에 적합한가? (과도하지도 부족하지도 않은가)
- [ ] 우선순위가 비즈니스 가치와 일치하는가?
- [ ] 기술적 리스크가 식별되고 대응 가능한가?
- [ ] Constitution이 팀 전체가 따를 수 있는 수준인가?
- [ ] Success Criteria가 실제로 측정 가능한가?

### Phase 2: Architecture & Design Sprint

**R1 (각 팀 Self-Review):**

CTO Architecture:
- [ ] 기술 스택 선택 시 공식 문서로 기능·제약·호환성을 확인했는가? **(Docs-First)** — 학습 데이터 기반 기억이 아닌 공식 문서에서 확인한 정보를 근거로 제시
- [ ] 기술 스택 선택에 명확한 근거가 있는가?
- [ ] 대안이 최소 2개 비교되었는가?
- [ ] 규모(Scale)에 적합한 아키텍처인가?
- [ ] 기술적 리스크가 식별되고 대응 방안이 있는가?
- [ ] 아키텍처 다이어그램이 있는가?

Design (활성 시):
- [ ] 모든 핵심 화면의 와이어프레임이 있는가?
- [ ] 사용자 흐름도가 완성되었는가?
- [ ] 디자인 토큰(색상, 타이포, 간격)이 정의되었는가?
- [ ] 컴포넌트 트리가 정의되었는가?
- [ ] 반응형 브레이크포인트가 정의되었는가?

DBA (활성 시):
- [ ] ER 다이어그램이 있는가?
- [ ] 인덱스 전략이 정의되었는가?
- [ ] 마이그레이션 순서가 결정되었는가?
- [ ] 데이터 정합성 규칙이 명시되었는가?

DevOps (활성 시):
- [ ] 배포 전략이 결정되었는가?
- [ ] CI/CD 파이프라인 구조가 설계되었는가?
- [ ] 환경별(dev/staging/prod) 차이가 정의되었는가?
- [ ] 모니터링 전략이 수립되었는가?

**R2 (Cross-Review 매핑):**
- CTO Architecture → DBA + DevOps가 교차 검토 (인프라·데이터 정합성)
- Design → Frontend가 교차 검토 (구현 가능성)
- DBA → Backend가 교차 검토 (쿼리 효율성, ORM 매핑)
- DevOps → Backend + QA가 교차 검토 (배포 가능성, 테스트 파이프라인)

**R3 (CTO Lead-Review):**
- [ ] 모든 팀의 설계가 Architecture와 정합하는가?
- [ ] 팀간 인터페이스 충돌이 없는가?
- [ ] 기술 부채를 과도하게 쌓지 않았는가?
- [ ] Constitution 원칙을 준수하는가?
- [ ] 전체 설계가 Spec의 요구사항을 충족하는가? **(SDD: spec.md의 P1 User Story 전체가 아키텍처로 구현 가능한지 추적 확인)**

### Phase 3: Sprint Planning & Backlog

**R1 (CTO Self-Review):**
- [ ] 모든 팀간 인터페이스에 계약이 정의되었는가?
- [ ] API 엔드포인트에 요청/응답 스키마가 있는가?
- [ ] 에러 코드와 에러 응답 형식이 통일되었는가?
- [ ] 공유 타입이 정의되었는가?
- [ ] Product Backlog가 DEEP 원칙을 따르는가? (Detailed, Estimated, Emergent, Prioritized)
- [ ] 각 Feature에 STICC 기반 Task Spec이 있는가?
- [ ] 규모 추정(S/M/L)이 완료되었는가? XL 항목은 분할되었는가?
- [ ] DoR/DoD 기준이 모든 팀에 명확하게 정의되었는가?
- [ ] Feature 간 의존성이 정확한가?
- [ ] 각 Feature의 파일 소유권이 명확한가?
- [ ] Sprint 1이 Walking Skeleton을 구현하는가?
- [ ] 병렬 실행 가능한 Feature가 최대한 묶여 있는가?

**R2 (각 팀 Cross-Review):**
각 팀이 자신에게 할당된 Feature의 Spec과 Contract을 검토:
- [ ] 이 계약만으로 내 팀이 독립적으로 구현할 수 있는가?
- [ ] 모호한 부분이 없는가?
- [ ] 내 팀의 Feature가 DoR을 충족하는가?
- [ ] 내 팀의 Feature 범위가 적절한가?
- [ ] 필요한 의존성이 모두 명시되었는가?

**R3 (CEO Lead-Review):**
- [ ] Sprint 계획이 점진적 가치 전달을 보장하는가?
- [ ] 전체 실행 계획이 현실적인가?
- [ ] 병렬/순차 구성이 최적인가?
- [ ] Bot 할당(simon-bot vs grind)이 적절한가?
- [ ] 예상 소요 시간이 합리적인가?
- [ ] 리스크가 높은 Feature가 식별되고 대비되었는가?

### Phase 4: Sprint Execution — Feature별 + Sprint 단위

**R1 (구현 팀 Self-Review):**
- [ ] TDD 사이클(RED→GREEN→REFACTOR)을 따랐는가?
- [ ] 모든 테스트가 통과하는가?
- [ ] 빌드 + 린트가 통과하는가?
- [ ] Contract(API, Data, Component)을 정확히 준수하는가?
- [ ] 파일 소유권을 벗어난 수정이 없는가?
- [ ] 하드코딩이 없는가?
- [ ] **Pre-Implementation Verification을 수행했는가?** (Sprint Shared Context Read, 계약 확인, 실제 스키마 대조)
- [ ] **result.md를 Structured Result Template 형식으로 작성했는가?**
- [ ] **Sprint Shared Context의 Team Progress를 업데이트했는가?** (Integration Notes, Discovered Constraints 포함)
- [ ] (DBA/Backend) **실제 DB 스키마(`\d table`)와 코드의 쿼리/INSERT가 일치하는가?** (NOT NULL 컬럼 누락 없음)
- [ ] (DBA) Seed 데이터가 외부 테이블(auth.users 등)의 모든 NOT NULL 컬럼에 값을 제공하는가?
- [ ] (Frontend) 디자인 토큰을 일관되게 사용하는가? (하드코드 색상 `bg-red-500`, `#FF0000` 대신 `bg-destructive`, `text-muted-foreground` 등 CSS 변수 기반 토큰 사용)
- [ ] (Frontend) 외부 브랜드 색상(카카오 노랑 등)을 제외한 모든 색상이 디자인 토큰을 참조하는가?
- [ ] (Frontend) 빈 상태(empty state), 로딩 상태, 에러 상태의 UI가 구현되었는가?
- [ ] (Frontend) 모바일에서 호버 전용 인터랙션이 없는가? (터치 디바이스 접근성)
- [ ] (Frontend) `aria-live`, `aria-label` 등 접근성 속성이 동적 콘텐츠와 아이콘 버튼에 적용되었는가?
- [ ] **spec.md의 해당 User Story AC를 모두 충족하는가? (SDD)** — Task Spec의 Spec Reference에 인라인된 Given/When/Then 시나리오와 구현 결과 대조
- [ ] Task Spec의 Acceptance Criteria를 모두 충족하는가?
- [ ] DoD 기준을 모두 충족하는가? (테스트 커버리지 80%+, 기술 부채 0건 또는 기록)
- [ ] 처음 사용하는 API/라이브러리/프레임워크 설정에 대해 공식 문서를 조회했는가? **(Docs-First)** — 조회한 문서 소스를 result.md에 기록
- [ ] **[코드 안전성] catch 블록에서 에러를 삼키는 패턴(silent fail)이 없는가?** — `catch` 후 빈 배열/null/undefined 반환 시 반드시 에러 로깅 + 호출자 전파 필요
- [ ] **[코드 안전성] `any` 타입 사용이 0건인가?** — 불가피한 경우 사유 주석 필수. `unknown` + 타입 가드로 대체 가능한지 먼저 검토
- [ ] **[코드 안전성] 모든 subscription/listener/timer에 cleanup 코드가 있는가?** — React useEffect return, Supabase channel.unsubscribe(), clearInterval 등
- [ ] **[코드 안전성] 외부 입력에 경계값 검증이 있는가?** — API 파라미터의 숫자 범위, 문자열 최대 길이, enum 허용값 검증
- [ ] **[코드 안전성] 주요 함수의 에러 경로에 대한 테스트가 존재하는가?** — 네트워크 실패, 잘못된 입력, 권한 부족 시나리오 테스트

**R2 (관련 팀 Cross-Review):**
- [ ] 계약대로 연동이 가능한가? (실제 호출/응답 형식 확인)
- [ ] 공유 타입이 올바르게 사용되었는가?
- [ ] 에러 처리가 계약과 일치하는가? — (1) Contract에 정의된 에러 코드가 모두 구현되었는가? (2) **에러가 silent fail 없이 호출자까지 전파되는가?** (3) 에러 응답 형식이 계약과 일치하는가?
- [ ] 내 팀 Feature와 충돌하는 변경이 없는가?
- [ ] **result.md의 Integration Notes를 확인하고, 내 팀의 구현과 정합성이 맞는가?**
- [ ] **Sprint Shared Context에 기록된 Discovered Constraints가 내 팀 코드에 영향을 주지 않는가?**
- [ ] (DBA→Backend) **Data Contract의 테이블 ↔ API 매핑이 실제 구현과 일치하는가?**
- [ ] (Backend→Frontend) **API 응답 형식이 계약과 일치하는가?** (실제 응답을 확인, 문서만 보지 않음)
- [ ] (Design→Frontend) 디자인 토큰이 일관되게 적용되었는가? (색상, 타이포, 간격, 반지름)
- [ ] (Design→Frontend) 와이어프레임/컴포넌트 트리와 실제 구현이 일치하는가?
- [ ] (Design→Frontend) 반응형 브레이크포인트가 design/에 정의된 대로 적용되었는가?
- [ ] (Design→Frontend) 접근성 요구사항(WCAG AA, 키보드 네비게이션, 색상 대비 4.5:1)이 충족되는가?

**R3 (CTO Lead-Review):**
- [ ] 아키텍처 패턴을 따르는가?
- [ ] 코드 품질이 프로덕션 수준인가?
- [ ] 보안 취약점이 없는가?
- [ ] 불필요한 복잡성이 없는가? (Over-engineering)
- [ ] 테스트 커버리지가 충분한가?
- [ ] **팀 간 계약 정합성이 유지되는가?** (Sprint Shared Context의 Cross-Team Issues 확인)
- [ ] **Discovered Constraints가 계약에 반영 필요한 항목이 있는가?** (있으면 다음 Sprint 전에 계약 업데이트)

### Phase 5: QA & Integration

**R1 (QA Self-Review):**
- [ ] 테스트 계획이 PRD의 모든 User Story를 커버하는가?
- [ ] E2E 시나리오가 핵심 사용자 흐름을 커버하는가?
- [ ] 엣지 케이스 테스트가 포함되었는가?
- [ ] 성능 테스트 기준이 Success Criteria와 일치하는가?
- [ ] 보안 테스트가 OWASP Top 10을 커버하는가?
- [ ] **코드 패턴 스캔(5-A2)이 완료되고 모든 항목이 PASS인가?** — FAIL 항목은 수정 후 재스캔 완료
- [ ] **통합 테스트가 Feature 간 연동을 실제로 검증하는가?** — 단위 테스트만으로는 불충분, API 호출 → DB 반영 → 이벤트 전파 등 흐름 검증

**R2 (Backend+Frontend Cross-Review):**
- [ ] 테스트 시나리오가 실제 사용 패턴을 반영하는가?
- [ ] 놓친 시나리오가 없는가?
- [ ] 테스트 환경이 프로덕션과 충분히 유사한가?

**R3 (CTO Lead-Review):**
- [ ] 전체 시스템이 프로덕션 레디인가?
- [ ] CRITICAL/HIGH 이슈가 모두 해결되었는가?
- [ ] 성능이 Success Criteria를 충족하는가?
- [ ] 보안 감사 결과가 수용 가능한가?

### Phase 6: Deployment & Operations

**R1 (DevOps Self-Review):**
- [ ] CI/CD 파이프라인이 정상 동작하는가?
- [ ] Dockerfile이 최적화되었는가? (multi-stage, 불필요한 레이어 없음)
- [ ] 환경 변수가 하드코딩되지 않았는가?
- [ ] 시크릿이 안전하게 관리되는가?
- [ ] 모니터링 대시보드가 핵심 지표를 커버하는가?
- [ ] 알림 규칙이 적절한 임계값을 가지는가?
- [ ] 런북이 주요 장애 시나리오를 커버하는가?
- [ ] 롤백 절차가 테스트되었는가?
- [ ] 외부 서비스 설정 안내 시 공식 문서를 조회했는가? **(Docs-First)** — 서비스명 변경·UI 경로 변경을 WebSearch로 확인

**R2 (Backend+QA Cross-Review):**
- [ ] CI 파이프라인에서 모든 테스트가 실행되는가?
- [ ] 배포 과정에서 다운타임이 최소화되는가?
- [ ] 모니터링이 비즈니스 핵심 지표를 포함하는가?
- [ ] 알림이 실제 문제를 감지할 수 있는가?

**R3 (CTO Lead-Review):**
- [ ] 인프라가 예상 트래픽을 처리할 수 있는가?
- [ ] 보안 베스트 프랙티스를 따르는가?
- [ ] 비용이 합리적인가?
- [ ] 재해 복구(DR) 전략이 있는가?
- [ ] 배포 전략이 프로젝트 규모에 적합한가?

---

## TRP 결과 저장 형식

각 TRP 라운드 결과는 `.claude/company/quality/phase-{N}-review.md`에 저장:

```markdown
# TRP: Phase {N} - {Phase Name}

## Round 1: Self-Review
- Reviewer: {팀/역할}
- Date: {timestamp}
- Verdict: PASS/FAIL
- Details: [체크리스트 결과]

## Round 2: Cross-Review
- Reviewer: {팀/역할}
- Date: {timestamp}
- Verdict: PASS/FAIL
- Details: [체크리스트 결과]

## Round 3: Lead Review
- Reviewer: {CTO/VP}
- Date: {timestamp}
- Verdict: APPROVED/REJECTED
- Quality Level: Excellent/Good/Acceptable/Below Standard
- Details: [체크리스트 결과]

## Revision History
- Rev 1: [수정 내용] → Re-reviewed from R{N}
```

---

## Escalation Protocol

### TRP 교착 상태 처리

같은 라운드에서 3회 연속 FAIL 시:
1. CEO가 실패 패턴을 분석하여 근본 원인 식별
2. 사용자에게 상황 보고:
   ```
   [TRP Escalation] Phase {N} - Round {R}
   - 3회 연속 실패 항목: {항목 목록}
   - 근본 원인 분석: {원인}
   - 제안 대응:
     a) 범위 축소 (해당 항목 제외)
     b) 기준 완화 (사용자 판단)
     c) 다른 접근 방식 시도
   ```
3. 사용자 결정에 따라 진행
