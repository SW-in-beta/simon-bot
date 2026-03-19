# Summary: ML Recommender - Phase 0 & Phase 1 실행 결과

**Date**: 2026-03-07
**Project**: 사용자 행동 기반 상품 추천 시스템 (Collaborative Filtering)

---

## Phase 0: Company Setup 결과

### 프로젝트 유형
- **Greenfield** (새 프로젝트)

### 팀 편성 (Dynamic Roster)
9개 팀 전원 활성화. 사용자 요청에서 추출한 키워드(REST API, 관리자 대시보드, collaborative filtering, 모니터링)를 기반으로 편성함.

| 팀 | 활성 여부 | 편성 근거 |
|----|----------|----------|
| PM | O | 항상 활성 |
| CTO | O | 항상 활성 |
| Design | O | 관리자 대시보드 UI/UX 설계 필요 |
| Frontend | O | 대시보드 웹 인터페이스 구현 필요 |
| Backend | O | REST API + 관리자 API + 이벤트 수집 API 필요 |
| QA | O | 항상 활성 |
| DBA | O | 행동 로그, 상품 데이터, 지표 등 대량 데이터 저장 필요 |
| DevOps | O | ML 서빙 인프라, API 배포, CI/CD, 모니터링 필요 |
| **ML** | **O** | **Collaborative Filtering 모델 설계, 학습 파이프라인, 서빙 필요** |

### 실행 모드
- 자동 진행 (완료 즉시 다음 단계로)

### 산출물
- `roster.json` - 팀 편성 정보
- `state.json` - 프로젝트 상태

---

## Phase 1: Discovery & Spec 결과

### 1-A: Vision Interview
사용자 요청에서 비전/기능/대상을 추출하여 Spec 초안을 AI-First Draft로 작성. 미해결 항목 없이 [NEEDS CLARIFICATION] 0개로 완성.

### 1-B: Feature Specification

**11개 User Story 작성** (INVEST 기준 전수 충족):

| ID | 제목 | Priority | 팀 관련성 |
|----|------|----------|----------|
| US-1 | 사용자 행동 데이터 수집 | P1 | BE, DBA |
| US-2 | 상품 추천 API | P1 | BE, ML |
| US-3 | 상품 카탈로그 관리 API | P1 | BE, DBA |
| US-4 | Collaborative Filtering 모델 학습 | P1 | **ML** |
| US-5 | 추천 성능 지표 대시보드 | P1 | FE, Design, BE |
| US-6 | 관리자 인증 | P1 | BE, FE |
| US-7 | 모델 학습 스케줄링 및 수동 트리거 | P2 | **ML**, FE, BE |
| US-8 | A/B 테스트 관리 | P2 | **ML**, BE, FE |
| US-9 | 추천 제외/부스트 규칙 관리 | P2 | BE, FE |
| US-10 | 추천 결과 설명 | P3 | **ML**, BE |
| US-11 | 실시간 이벤트 스트림 대시보드 | P3 | FE, BE |

**ML-Specific Stories 분석**:
- **US-4** (P1): CF 모델 학습 - 데이터 전처리, user-item matrix 생성, ALS/SVD 학습, 평가 지표(RMSE, Precision@K) 산출
- **US-7** (P2): 모델 재학습 자동화 - 스케줄링, 수동 트리거, 무중단 학습
- **US-8** (P2): A/B 테스트 - 모델 간 트래픽 분배, 통계적 유의성 판정, 승자 모델 승격
- **US-10** (P3): 추천 설명 생성 - 유사 사용자 기반 설명, cold start 폴백 설명

### 1-C: Story Mapping

**4개 Activity 구조화**:
1. 데이터 수집 (행동 이벤트, 상품 카탈로그)
2. 추천 생성 (추천 API, cold start, 비즈니스 규칙, 설명)
3. 관리자 모니터링 (인증, 지표 대시보드)
4. 모델 관리 (학습, 스케줄링, A/B 테스트)

**ML 파이프라인 Activity 매핑**:
```
데이터 수집(US-1) → 전처리/피처(US-4 내부) → 모델 학습(US-4) → 모델 평가(US-4 내부) → 모델 서빙(US-2)
```

**Walking Skeleton (Sprint 1)**:
```
상품 등록(US-3) → 행동 이벤트 수집(US-1) → CF 모델 학습(US-4) → 추천 API(US-2) → 관리자 인증(US-6) → 성능 지표 확인(US-5)
```

**Release 계획**:
- Release 1: P1 6개 Story (핵심 흐름 end-to-end)
- Release 2: P2 3개 Story (운영 기능 강화)
- Release 3: P3 2개 Story (고도화)

### 1-D: Constitution

5개 Core Principles 확정:
1. 추천 품질 최우선
2. 서비스 무중단
3. 데이터 기반 의사결정
4. 보안 타협 불가
5. **재현 가능한 ML** (학습 데이터, 하이퍼파라미터, 랜덤 시드 기록)

Quality Gates: 테스트 80%+, 응답 200ms, 처리량 1000/s, 커버리지 70%+, **Precision@10 >= 0.1**

### 1-Plan Review
- Critic 4축 평가: Completeness(5), Feasibility(4), Safety(4), Clarity(5) → **통과**
- Architect 구조 검증: YAGNI/KISS 모두 PASS → **통과**

### 1-TRP: Triple Review
- R1 (PM Self): 12개 체크리스트 항목 전수 PASS
- R2 (Design Cross): 5개 체크리스트 항목 전수 PASS, MEDIUM 발견 2건 (빈 상태 UX, 모바일 반응형 — Phase 2에서 해결)
- R3 (CTO Lead): 5개 체크리스트 항목 전수 PASS, Quality Level: Excellent → **APPROVED**

---

## 산출물 목록

| 파일 | 설명 | Phase |
|------|------|-------|
| `roster.json` | 팀 편성 정보 (9개 팀) | 0 |
| `state.json` | 프로젝트 상태 | 0 |
| `spec.md` | Feature Specification (11개 User Story) | 1 |
| `story-map.md` | Story Map + Walking Skeleton + Release 계획 + ML 파이프라인 | 1 |
| `constitution.md` | 프로젝트 원칙, Quality Gates, 제약 조건 | 1 |
| `spec-review-scores.md` | planner-critic-architect 검증 결과 | 1 |
| `phase-1-review.md` | TRP 3라운드 검토 결과 | 1 |

---

## 핵심 관찰

1. **ML 팀이 동적 편성에 올바르게 포함됨**: "collaborative filtering" 키워드에서 ML 팀 활성화가 자동 트리거됨
2. **ML-specific Stories가 INVEST 기준을 충족**: 특히 US-4(모델 학습)가 독립적(I), 테스트 가능(T - RMSE/P@K 기준), 추정 가능(E - M/L 규모)
3. **ML 파이프라인이 Story Map에 통합**: 별도 사일로가 아닌 전체 사용자 여정의 일부로 배치
4. **Walking Skeleton에 ML 포함**: Sprint 1에서 단순한 CF 구현으로 end-to-end 검증 가능
5. **ML 재현성 원칙이 Constitution에 명시**: 학습 데이터/하이퍼파라미터/시드 기록 의무화
