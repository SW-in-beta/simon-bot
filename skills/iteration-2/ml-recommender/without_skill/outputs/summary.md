# Phase 1 산출물 요약 - RecoPilot 추천 시스템

## 프로젝트 개요
사용자 행동 기반 협업 필터링(Collaborative Filtering) 상품 추천 시스템.
REST API로 추천 결과를 제공하고, 관리자 대시보드에서 추천 성능 지표를 모니터링한다.

---

## 산출물 목록

| # | 파일명 | 설명 | 주요 내용 |
|---|--------|------|-----------|
| 1 | `01-project-overview.md` | 프로젝트 개요 | 배경, 목표, 범위, KPI, 마일스톤, 리스크 요약 |
| 2 | `02-team-composition.md` | 팀 구성 및 역할 | 8명 팀 구성, RACI 매트릭스, 협업 방식 |
| 3 | `03-feature-specs.md` | 기능 명세서 | 7개 핵심 기능 상세 명세, 수락 기준 |
| 4 | `04-user-stories.md` | 사용자 스토리 | 4개 Epic, 16개 User Story, 총 104 SP |
| 5 | `05-architecture-design.md` | 시스템 아키텍처 | 6개 서비스 구성, 데이터 흐름, 배포/보안 설계 |
| 6 | `06-data-model.md` | 데이터 모델 | 이벤트 스키마, DW 테이블, PostgreSQL ERD, Redis 키 설계 |
| 7 | `07-api-specification.md` | REST API 명세 | 추천 API 4개, 관리자 API 7개, 이벤트 API 1개 엔드포인트 |
| 8 | `08-ml-model-design.md` | ML 모델 설계 | ALS 모델 상세, 학습 파이프라인, 평가 체계, 콜드 스타트 전략 |
| 9 | `09-tech-stack-decision.md` | 기술 스택 ADR | 9개 기술 의사결정 기록 (Go API, implicit, Redis, Kafka 등) |
| 10 | `10-sprint-plan.md` | 스프린트 계획 | 9개 스프린트 (18주), Sprint별 스토리 배분, 의존성 |
| 11 | `11-risk-mitigation.md` | 리스크 분석 | 8개 리스크 식별, 완화 전략, 우선순위 매트릭스 |

---

## 핵심 수치 요약

| 항목 | 값 |
|------|-----|
| 총 팀 규모 | 8명 (FTE 약 6.3명) |
| 총 기능 수 | 7개 (P0: 4개, P1: 3개) |
| 총 사용자 스토리 | 16개 |
| 총 스토리 포인트 | 104 SP (기획 기준) / 177 SP (스프린트 분배 기준) |
| 총 스프린트 | 9개 (18주, 약 4.5개월) |
| API 엔드포인트 | 12개 |
| 주요 기술 스택 | Go (API), Python (ML), Next.js (대시보드) |
| 추천 알고리즘 | ALS (주), Item CF (보조), Popularity (폴백) |
| 목표 API P99 | 200ms 이하 |
| 목표 CTR 개선 | 기존 대비 +20% |
| 식별된 리스크 | 8개 (최우선: 콜드 스타트, 모델 성능, 데이터 편향) |

---

## 파일 위치
모든 산출물은 아래 경로에 저장되어 있다:
```
/Users/simon.lee/.claude/skills/simon-company-workspace/iteration-2/ml-recommender/without_skill/outputs/
```
