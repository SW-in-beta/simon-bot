# Summary: InstaClone 소셜 미디어 웹앱 — Phase 0 & Phase 1 산출물

**Date**: 2026-03-07
**Project**: InstaClone - 소셜 미디어 웹앱
**Scope**: Phase 0 (Company Setup) + Phase 1 (Discovery & Spec)

---

## Phase 0: Company Setup

### 프로젝트 유형
- **Greenfield** (새 프로젝트)
- **실행 모드**: 자동 진행

### 팀 편성 (roster.json)
8개 팀 활성화, 1개 팀 비활성화:

| 팀 | 활성 | 편성 이유 |
|----|------|----------|
| PM | O | 항상 활성 |
| CTO | O | 항상 활성 |
| Design | O | 소셜 미디어 웹앱 다수 화면 UI/UX 필요 |
| Frontend | O | 사진 피드, 인터랙션 등 복잡한 웹 클라이언트 |
| Backend | O | 인증, 이미지 업로드, API, 알림 서버 로직 |
| QA | O | 항상 활성, 동시성/엣지 케이스 중요 |
| DBA | O | 복잡한 관계형 데이터 모델 (User, Post, Follow, Like, Comment, Notification) |
| DevOps | O | 이미지 스토리지, CI/CD, 컨테이너화 |
| ML | X | 피드가 단순 최신순이므로 ML 불필요 |

### 산출물
- `roster.json` — 팀 편성 + Decision Trail
- `state.json` — 프로젝트 상태 관리

---

## Phase 1: Discovery & Spec

### 1-A/B: Spec (spec.md)

**14개 User Story** (INVEST 기준 충족, 모두 Given/When/Then Acceptance Scenarios 포함):

| 우선순위 | Stories | 요약 |
|---------|---------|------|
| P1 (8개) | US-1~US-8 | 가입/로그인, 사진 업로드, 피드, 팔로우, 좋아요, 댓글, 프로필, 알림 |
| P2 (4개) | US-9~US-12 | 프로필 편집, 사용자 검색, 게시물 삭제, 게시물 상세 |
| P3 (2개) | US-13~US-14 | 탐색 페이지, 비밀번호 변경 |

**13개 Functional Requirements** (FR-001~FR-013) — WHAT만 기술, HOW 미포함
**7개 Edge Cases** (EC-001~EC-007) — 동시성, 삭제된 리소스, 자기 팔로우 등
**6개 Key Entities** — User, Post, Like, Comment, Follow, Notification
**6개 Success Criteria** — 측정 가능한 수치 (피드 500ms, 좋아요 200ms 등)

### 1-C: Story Map (story-map.md)

**5개 Activity** 기반 사용자 여정:
1. 가입/인증
2. 콘텐츠 생성
3. 콘텐츠 소비
4. 소셜 인터랙션
5. 알림/관리

**Walking Skeleton**: 가입 -> 사진 업로드 -> 팔로우 -> 피드 조회 -> 좋아요/댓글 -> 알림 확인

**Release 계획**:
- Release 1 (Sprint 1-3): P1 — Walking Skeleton, 핵심 흐름 완성
- Release 2 (Sprint 4): P2 — 사용자 경험 완성도 향상
- Release 3 (Sprint 5): P3 — 성장 기능 및 보안 강화

**의존성 그래프**: 순환 의존성 없음, US-1(가입)이 루트 노드

### 1-D: Constitution (constitution.md)

**5개 Core Principles**: 사용자 경험 최우선, 보안 타협 불가, KISS, 점진적 전달, 데이터 무결성
**Quality Gates**: 커버리지 80%+, TRP 3라운드, OWASP Top 10, WCAG 2.1 AA
**명시적 Out of Scope**: 모바일 앱, 비디오, 스토리, DM, 해시태그, 소셜 로그인, 푸시 알림 등

---

## 검증 결과

### Plan Review (planner-critic-architect)

| 검증 | 결과 | 점수 |
|------|------|------|
| Critic — Completeness | PASS | 5/5 |
| Critic — Feasibility | PASS | 5/5 |
| Critic — Safety | PASS | 4/5 |
| Critic — Clarity | PASS | 5/5 |
| Architect — YAGNI/KISS | PASS | - |
| Architect — 의존성 | PASS | - |
| Architect — Walking Skeleton | PASS | - |
| **종합** | **PASS** | **19/20** |

### TRP (Triple Review Protocol)

| Round | 검토자 | 판정 |
|-------|--------|------|
| R1: Self-Review | PM | PASS (12/12 체크리스트 항목 통과) |
| R2: Cross-Review | Design Lead | PASS (5/5 체크리스트 항목 통과) |
| R3: Lead Review | CTO | APPROVED (Quality Level: Excellent) |

---

## 산출물 파일 목록

| 파일 | 설명 |
|------|------|
| `roster.json` | 팀 편성 + Decision Trail |
| `state.json` | 프로젝트 상태 (Phase 1 완료) |
| `spec.md` | Feature Specification (14 User Stories, 13 FRs, 7 ECs) |
| `story-map.md` | Story Map + Walking Skeleton + Release 계획 |
| `constitution.md` | 프로젝트 원칙, 품질 게이트, 제약 조건 |
| `quality/spec-review-scores.md` | planner-critic-architect 검증 결과 |
| `quality/phase-1-review.md` | TRP 3라운드 검토 결과 |

---

## 다음 단계 (Phase 2)

Phase 1이 승인되었으므로, Phase 2 (Architecture & Design Sprint)로 진행 가능:
- CTO: 기술 스택 결정, 아키텍처 설계
- Design: 와이어프레임, 디자인 토큰, 컴포넌트 트리
- DBA: ER 다이어그램, 스키마 설계, 인덱스 전략
- DevOps: 인프라 아키텍처, CI/CD 파이프라인 설계
