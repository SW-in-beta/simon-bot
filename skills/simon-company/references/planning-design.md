# Planning & Design Phases (Phase 1-2)

## 목차
- [Phase 1: Discovery & Spec](#phase-1-discovery--spec)
  - [1-A: Vision Interview (AI-First Draft Protocol)](#1-a-vision-interview-ai-first-draft-protocol)
  - [1-A': Discovery Interview Protocol (의뢰 모드)](#1-a-discovery-interview-protocol-의뢰-모드)
  - [1-B: Feature Specification (WHAT)](#1-b-feature-specification-what)
  - [1-C: Story Mapping](#1-c-story-mapping)
  - [1-D: Constitution](#1-d-constitution)
  - [1-Plan Review: planner-critic-architect 3인 검증](#1-plan-review-planner-critic-architect-3인-검증)
  - [1-TRP: Triple Review 실행](#1-trp-triple-review-실행)
- [Phase 2: Architecture & Design Sprint](#phase-2-architecture--design-sprint)
  - [2-A: CTO Architecture Decision](#2-a-cto-architecture-decision)
  - [2-B: Design Sprint (Design팀 활성 시)](#2-b-design-sprint-design팀-활성-시)
  - [2-C: Data Model Design (DBA팀 활성 시)](#2-c-data-model-design-dba팀-활성-시)
  - [2-D: Infrastructure Blueprint (DevOps팀 활성 시)](#2-d-infrastructure-blueprint-devops팀-활성-시)
  - [2-E: ML Architecture (ML팀 활성 시)](#2-e-ml-architecture-ml팀-활성-시)
  - [2-F: Expert Panel Review (도메인 전문가 검증)](#2-f-expert-panel-review-도메인-전문가-검증)
  - [2-TRP: Triple Review](#2-trp-triple-review)
  - [2-Commit: 산출물 Git 커밋](#2-commit-산출물-git-커밋)
  - [PRD Assembly](#prd-assembly)

Phase 1 (Discovery & Spec)과 Phase 2 (Architecture & Design Sprint)의 상세 프로세스.

---

## Phase 1: Discovery & Spec

실행 모드에 따라 1-A 단계가 달라진다:
- **자동/승인 모드** → 1-A: AI-First Draft Protocol (빠르고 효율적)
- **의뢰 모드** → 1-A': Discovery Interview Protocol (심층 인터뷰로 점진적 구체화)

산출물(1-B ~ 1-E)은 동일하다.

---

### 1-A: Vision Interview (AI-First Draft Protocol)

> **적용 조건**: 자동 진행 또는 승인 후 진행 모드일 때.

simon-pm의 AI-First Draft 방식을 채택한다.

**프로토콜:**
1. 사용자의 초기 요청에서 비전/기능/대상 사용자를 추출하여 Spec 초안을 작성
2. 초안을 제시: "이 방향으로 진행할까요? 수정할 부분이 있으면 알려주세요."
3. 사용자가 교정 (빈 칸을 채우는 대신, 잘못된 부분만 수정)
4. 미해결 항목만 추가 인터뷰

**인터뷰 분량 가이드:** 3-5 라운드, 총 8-12개 질문, 한 번에 2-3개씩

**커버할 주제:**
- **비전**: 무엇을, 왜, 누구를 위해
- **핵심 기능**: Must-have / Nice-to-have / Out of scope
- **세부 시나리오**: 각 핵심 기능의 상세 동작, 엣지 케이스
- **규모/환경**: 예상 사용자 수, 배포 환경, 시간 제약

**Design팀 참여 (활성 시):** 핵심 사용자 흐름, 핵심 화면 구성, 에러/빈 상태 UX, 접근성 요구 수준

기술 스택은 이 단계에서 묻지 않음 — Phase 2에서 CTO가 결정.

---

### 1-A': Discovery Interview Protocol (의뢰 모드)

> **적용 조건**: 의뢰 모드일 때.

상세 프로세스: `references/discovery-interview.md` 참조

### 1-B: Feature Specification (WHAT)

`~/.claude/skills/simon-pm/references/spec-template.md` 템플릿을 사용하여 Spec을 작성한다.

**Spec 핵심 구성:**
1. **User Stories** — P1/P2/P3 우선순위 + Given/When/Then
2. **Functional Requirements** — FR-001 형식, [NEEDS CLARIFICATION] 최대 3개
3. **Edge Cases** — 경계 조건, 에러 시나리오, 동시성
4. **Key Entities** — 개념적 엔티티 관계
5. **Success Criteria** — 기술 무관, 측정 가능

**INVEST 기준 적용:**

| 기준 | 설명 | 검증 질문 |
|------|------|----------|
| **I**ndependent | 다른 스토리와 독립적으로 구현 가능 | "이 스토리를 단독으로 구현/테스트할 수 있는가?" |
| **N**egotiable | 구현 방식이 아닌 목적을 기술 | "의도는 명확하되, 구현 방법은 열려 있는가?" |
| **V**aluable | 사용자에게 명확한 가치 제공 | "완료되면 사용자가 뭘 할 수 있게 되는가?" |
| **E**stimable | 규모를 추정할 수 있음 | "S/M/L로 추정할 수 있는가?" |
| **S**mall | 한 Sprint 내 완료 가능한 크기 | "simon이 한 번에 처리 가능한 규모인가? (파일 5-15개)" |
| **T**estable | 완료 여부를 객관적으로 검증 가능 | "Given/When/Then으로 AC를 작성할 수 있는가?" |

INVEST 미충족 User Story는 충족할 때까지 분할하거나 재작성한다.

Save: `.claude/company/spec.md`

### 1-C: Story Mapping

사용자 여정을 기반으로 기능을 계층적으로 구조화한다.

**Story Map 구조:**
```
Activity:   [가입/온보딩]         [핵심 기능]            [관리/설정]
              │                      │                      │
Tasks:      이메일가입            콘텐츠 생성              프로필 관리
            소셜가입              콘텐츠 조회              알림 설정
            온보딩               콘텐츠 수정/삭제          계정 삭제
              │                      │                      │
Stories:    US-001 이메일 입력    US-005 글 작성          US-010 이름 변경
(P1)        US-002 비밀번호 설정  US-006 글 목록          US-011 비번 변경
              │                      │                      │
Stories:    US-003 소셜 연동      US-007 태그 필터        US-012 알림 관리
(P2)        US-004 프로필 사진    US-008 검색             US-013 다크모드
              │                      │
Stories:                          US-009 AI 추천
(P3)
```

**Walking Skeleton 식별:** 각 Activity의 최소 필수 Task를 수평으로 연결 → Sprint 1의 목표

**Release 계획:**
- Release 1 (Walking Skeleton): P1 Stories 중 핵심 흐름
- Release 2: 나머지 P1 + P2 일부
- Release 3: P2 나머지 + P3

Save: `.claude/company/story-map.md`

### 1-D: Constitution

```markdown
# Constitution: [프로젝트명]

## Core Principles
1. [예: "사용자 경험 최우선"]
2. [예: "보안은 타협 불가"]

## Quality Gates
- 테스트 커버리지: 80%
- TRP 3라운드 통과 필수
- OWASP Top 10 준수

## Constraints
- [기술적 제약]
- [비즈니스 제약]
- [시간 제약]
```

Save: `.claude/company/constitution.md`

### 1-Plan Review: planner-critic-architect 3인 검증

**Step 1**: planner가 Spec + Story Map 초안 작성 (1-A ~ 1-C에서 완료)

**Step 2**: critic이 4축 평가:
- **Completeness** (1-5): 요구사항 커버리지
- **Feasibility** (1-5): 기술적 실현 가능성
- **Safety** (1-5): 리스크 관리
- **Clarity** (1-5): 명확성 — [NEEDS CLARIFICATION] 3개 이하

모든 항목 4점 이상이면 통과, 아니면 수정 후 재평가 (max 3회).

**Step 3**: architect가 구조 검증
- Story 간 의존성 복잡도 (YAGNI/KISS)
- Walking Skeleton 커버리지
- Release 계획의 점진적 가치 전달 적합성
- severity 기반 routing: Minor → Step 2 재검증, Major → Step 1 재작성

Save: `.claude/company/quality/spec-review-scores.md`

### 1-TRP: Triple Review 실행

quality-gates.md의 Phase 1 체크리스트를 사용하여 3라운드 검토 수행.
검토 후 사용자에게 최종 Spec + Story Map + Constitution을 제시하고 승인을 받는다.

---

## Phase 2: Architecture & Design Sprint

Spec이 확정되면 여러 팀이 **병렬로** 자신의 영역을 설계한다. 2-TRP에서 전체 정합성을 검증한다.

### 2-A: CTO Architecture Decision

simon-pm의 `references/technical-architecture.md` 프로세스를 따른다.

**Step 1: CTO Agent** — Spec + Story Map + 사용자 선호 + 규모 예상치를 입력으로 → 기술 스택 추천 + 근거, 아키텍처 패턴, 대안 비교표, 기술적 리스크

**Step 2: Dev Lead Agent** — CTO 추천을 구현 관점에서 검증, 숨겨진 복잡성/리스크 지적

**Step 3: 사용자 최종 결정** — AskUserQuestion으로 확인

**Step 4: [NEEDS CLARIFICATION] 해소** — researcher 에이전트로 미결 항목 조사

**Step 5: Implementation Plan (STICC 기반)**

```markdown
## Situation
- 현재 상태: [Greenfield / 기존 코드베이스 상태]

## Task
- 기술 스택: [언어, 프레임워크, DB, 캐시, 메시지큐]
- 아키텍처 패턴: [계층형, 클린, 마이크로서비스 등]
- 주요 컴포넌트 목록 + 역할

## Intent
- 품질 속성 (확장성, 유지보수성, 보안 등)
- 기술 선택의 근본 이유

## Concerns
- 기술적 리스크 목록
- NOT in scope

## Acceptance Criteria
- 각 팀이 독립 구현 가능, 계약 기반 연동
```

Save: `.claude/company/architecture.md`

### 2-B: Design Sprint (Design팀 활성 시)

**병렬 실행**: CTO Architecture와 동시 진행.

**Step 1: 사용자 흐름도** (Story Map 기반, Mermaid graph TD)

**Step 2: 와이어프레임** — 각 핵심 화면의 ASCII 와이어프레임

**Step 3: 디자인 토큰** — colors, typography, spacing, breakpoints를 JSON으로 정의

**Step 4: 컴포넌트 트리** — Layout/Shared Components 계층 구조

**Step 5: 접근성 요구사항**
- WCAG 2.1 AA 준수, 키보드 네비게이션, 스크린 리더 호환
- 색상 대비 4.5:1 이상
- 호버 전용 인터랙션 금지 (모바일 터치 디바이스 접근 불가)
- 동적 콘텐츠에 `aria-live`, 아이콘 전용 버튼에 `aria-label` 필수

**Step 6: 디자인 토큰 → 코드 매핑 가이드**

| 토큰 용도 | CSS 변수 | Tailwind 클래스 | 금지 (하드코드) |
|----------|---------|----------------|---------------|
| 배경 기본 | --background | bg-background | bg-white, bg-zinc-50 |
| 텍스트 기본 | --foreground | text-foreground | text-black, text-zinc-900 |
| 주요 색상 | --primary | bg-primary, text-primary | bg-blue-600, text-blue-600 |
| 보조 텍스트 | --muted-foreground | text-muted-foreground | text-gray-500, text-zinc-600 |
| 에러/위험 | --destructive | bg-destructive, text-destructive | bg-red-500, text-red-500 |
| 비활성 배경 | --muted | bg-muted | bg-gray-100, bg-zinc-100 |

예외: 외부 브랜드 색상(카카오 #FEE500 등)은 CSS 변수로 정의 권장, 불가하면 하드코드 허용.

이 매핑 가이드는 Phase 3의 Component Contract에 포함되어 Frontend 팀의 구현 기준이 된다.

Save: `.claude/company/design/` (wireframes.md, tokens.json, components.md, accessibility.md, user-flows.md, token-mapping.md, `mockups/*.html` — 선택)

`mockups/*.html` (선택) — 핵심 화면 1-2개의 클릭 가능한 self-contained HTML 목업. 텍스트 wireframe의 보완재로, 사용자가 화면 구성을 클릭해보며 판단하게 한다.

### 2-C: Data Model Design (DBA팀 활성 시)

**병렬 실행**: CTO Architecture와 동시 진행.

**Step 0: Ground Truth — 기존 스키마 Introspection**

애플리케이션 스키마를 설계하기 전에, 이미 존재하는 테이블과 외부 관리형 서비스의 스키마를 먼저 조사한다. 실제 스키마를 모르고 설계하면 구현 시 NOT NULL 위반, 타입 불일치 등 런타임 오류가 발생한다.

**Existing 프로젝트:**
```bash
# 모든 테이블 목록 조회
\dt *.*
# 각 테이블의 전체 스키마 (컬럼, 타입, NULL 허용, 기본값, 제약조건)
\d table_name
```

**관리형 서비스 (Supabase, Firebase 등):**
```bash
# Supabase 예시 — 시스템 테이블 스키마 전체 조사
\d auth.users
\d auth.sessions
\d storage.objects
\d storage.buckets
# 각 테이블의 모든 컬럼, NOT NULL 제약, DEFAULT 값을 기록
```

**기록 형식** — `.claude/company/external-schemas.md`에 저장:
```markdown
# External Schema Registry

## auth.users (Supabase Auth — GoTrue 관리)
| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | uuid | NO | gen_random_uuid() | PK |
| email | varchar(255) | YES | | |
| email_change | varchar(255) | NO | '' | 빈 문자열 기본값 — NULL 불가, INSERT 시 반드시 포함 |
| encrypted_password | varchar(255) | YES | | |
| ...전체 컬럼 기록... |

### 주의사항
- GoTrue가 내부적으로 모든 컬럼을 Go string으로 스캔하므로 NULL 허용 컬럼이라도 빈 문자열('')로 초기화 필요
- auth.users에 직접 INSERT 시 email_change, email_change_token_new 등 필수 컬럼 누락 주의
```

**Greenfield 프로젝트:**
- 관리형 서비스를 사용할 경우 해당 서비스의 시스템 테이블을 위와 같이 조사
- 순수 Greenfield면 이 단계 건너뛰기

이 결과물은 Phase 3의 Data Contract와 Phase 4의 구현에서 **필수 참조**된다.

**Step 1: ER 다이어그램** — Mermaid erDiagram으로 엔티티 관계 표현

**Step 2: 스키마 초안** — 테이블 정의, 정규화 수준, 소프트/하드 삭제 전략

**Step 3: 인덱스 전략** — 주요 쿼리 패턴 기반, 복합/부분 인덱스 식별

**Step 4: 마이그레이션 계획** — 의존성 기반 순서, 롤백 가능한 설계, 시드 데이터 전략

Save: `.claude/company/db-schema.md`

### 2-D: Infrastructure Blueprint (DevOps팀 활성 시)

**병렬 실행**: CTO Architecture와 동시 진행.

**Step 1: 인프라 아키텍처** — Client → CDN → LB → App Servers → DB/Cache (Mermaid)

**Step 2: CI/CD 파이프라인 설계** — Push → Lint → Build → Test → Security Scan → Deploy (Staging) → Smoke → Deploy (Prod)

**Step 3: 배포 전략** — Small: 단일 서버 직접 배포 / Medium: Blue-Green/Rolling / Large: Canary + Feature Flags

**Step 4: 모니터링 전략** — 4 Golden Signals, 구조화된 로그(JSON), 임계값 기반 알림 + 이상 탐지

Save: `.claude/company/deployment/infra-blueprint.md`

### 2-E: ML Architecture (ML팀 활성 시)

**병렬 실행**: CTO Architecture와 동시 진행.

**Step 1: 모델 아키텍처** — 문제 유형 정의, 모델 선택 근거, 입력/출력 스키마

**Step 2: 데이터 파이프라인** — 수집 → 전처리 → 피처 엔지니어링 → 학습 → 평가

**Step 3: 서빙 아키텍처** — 배치 vs 실시간 추론, API 엔드포인트, 모델 버전 관리

Save: `.claude/company/ml-architecture.md`

### 2-F: Expert Panel Review (도메인 전문가 검증)

**팀 구성 (프로젝트 특성에 따라 활성화):**

| 도메인팀 | 활성화 조건 | 핵심 검증 관점 |
|---------|-----------|---------------|
| **Data Team** | DB 사용 시 | 스키마 정규화, 쿼리 성능, 데이터 무결성 |
| **Integration Team** | 외부 API/이벤트 사용 시 | API 계약 정합성, 이벤트 흐름, 장애 격리 |
| **Safety Team** | 항상 활성 | 인증/인가, 주입 공격, 데이터 노출, 안정성 |
| **Ops Team** | DevOps 활성 시 | 인프라 확장성, 모니터링 충분성, 장애 대응 |

**검증 프로세스:**
1. 각 도메인팀이 해당 설계 산출물을 독립적으로 분석
2. 팀 내 토론으로 우려사항 합의 (CRITICAL / HIGH / MEDIUM)
3. CRITICAL → 설계 수정 후 재검증 (max 2회)
4. HIGH → 설계에 주의사항으로 추가, 구현 시 반드시 반영
5. MEDIUM → 기록만, 구현 시 참고

**각 concern 포함 정보:** 우려사항 설명, severity + 합의 근거, 권장 대응 방안, 재평가 트리거 조건

Save: `.claude/company/quality/expert-concerns.md`

사용자에게 주요 우려사항(HIGH+) 요약 보고 → AskUserQuestion으로 진행 여부 확인.

### 2-TRP: Triple Review

각 트랙(Architecture, Design, DB, Infra, ML)의 산출물별로 TRP를 실행한다.
전체 정합성 검증은 R3 Lead Review에서 CTO가 수행:
- 모든 트랙의 설계가 Architecture와 정합하는가?
- 트랙 간 인터페이스 충돌이 없는가?
- Expert Panel의 HIGH+ 우려사항이 설계에 반영되었는가?
- 기술 부채를 과도하게 쌓지 않았는가?

### 2-Commit: 산출물 Git 커밋

모든 트랙이 TRP를 통과하면 Phase 2 산출물을 Git에 커밋한다.

```bash
git add .claude/company/architecture.md .claude/company/design/ .claude/company/db-schema.md .claude/company/quality/
git commit -m "chore: Phase 2 Architecture + Design Sprint 산출물 확정"
```

Phase 1도 마찬가지:
```bash
git add .claude/company/spec.md .claude/company/story-map.md .claude/company/constitution.md
git commit -m "chore: Phase 1 Spec + Story Map 확정"
```

### PRD Assembly

모든 트랙이 TRP를 통과하면, 전체 산출물을 종합하여 PRD를 조립한다:

```markdown
# PRD: [프로젝트명]

## 1. Overview (Spec)
## 2. Goals & Non-Goals (Spec)
## 3. User Stories & Acceptance Criteria (Spec)
## 4. Story Map & Release Plan (Story Map)
## 5. Technical Architecture (Architecture)
## 6. Technical Context (Architecture)
## 7. Design System (Design — 활성 시)
## 8. Data Model (DBA — 활성 시)
## 9. Infrastructure (DevOps — 활성 시)
## 10. ML Architecture (ML — 활성 시)
## 11. Expert Panel Concerns (HIGH+ 항목)
## 12. Constraints & Principles (Constitution)
## 13. Success Criteria (Spec)
```

Save: `.claude/company/prd.md`

사용자에게 PRD를 제시하고 최종 승인을 받는다.
