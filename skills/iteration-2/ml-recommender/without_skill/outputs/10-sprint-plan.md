# 스프린트 계획 (Sprint Plan)

## 전체 타임라인

```
Phase 2: 데이터 파이프라인     Phase 3: 모델 개발        Phase 4: API 개발
├── Sprint 1 (2주) ──┤├── Sprint 3 (2주) ──┤├── Sprint 5 (2주) ──┤
├── Sprint 2 (2주) ──┤├── Sprint 4 (2주) ──┤├── Sprint 6 (2주) ──┤

Phase 5: 대시보드              Phase 6: 통합/출시
├── Sprint 7 (2주) ──┤├── Sprint 9 (2주) ──┤
├── Sprint 8 (2주) ──┤

총 기간: 약 18주 (4.5개월)
```

---

## Sprint 1 (Week 1~2): 데이터 수집 기반 구축

### 목표
이벤트 수집 인프라 구축 및 기본 데이터 파이프라인 완성

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| US-401-1 | Kafka 클러스터 프로비저닝 및 토픽 설정 | 3 | Data Eng | To Do |
| US-401-2 | Event Collector 서비스 기본 구현 (REST 엔드포인트 + Kafka Producer) | 5 | BE Eng | To Do |
| US-401-3 | 이벤트 스키마 정의 및 검증 로직 구현 | 3 | BE/Data Eng | To Do |
| INFRA-1 | PostgreSQL, Redis 프로비저닝 | 2 | BE Eng | To Do |
| INFRA-2 | 프로젝트 리포지토리 셋업, CI 기본 설정 | 2 | BE Eng | To Do |

**총 SP:** 15

### 완료 기준
- [ ] Kafka 토픽으로 이벤트 발행 가능
- [ ] Event Collector API가 이벤트를 수신하고 Kafka에 전달
- [ ] 스키마 검증 실패 이벤트가 DLQ로 전달

---

## Sprint 2 (Week 3~4): 데이터 파이프라인 완성

### 목표
ETL 파이프라인 구축, DW 적재, 학습용 데이터 준비

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| US-401-4 | Kafka → S3 이벤트 적재 (Spark Streaming / Kafka Connect) | 5 | Data Eng | To Do |
| US-401-5 | S3 → DW 집계 테이블 ETL (Airflow DAG) | 5 | Data Eng | To Do |
| US-402 | 이벤트 데이터 품질 모니터링 | 3 | Data Eng | To Do |
| DATA-1 | user_item_interactions 테이블 생성 및 집계 로직 | 3 | Data Eng | To Do |

**총 SP:** 16

### 완료 기준
- [ ] 이벤트가 S3에 Parquet 형태로 저장
- [ ] DW에 user_item_interactions 테이블 갱신
- [ ] Airflow DAG 자동 실행 확인
- [ ] 데이터 품질 리포트 생성

---

## Sprint 3 (Week 5~6): 추천 모델 개발

### 목표
ALS 모델 학습 파이프라인 구축 및 오프라인 평가

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| ML-1 | 학습 데이터 전처리 파이프라인 (상호작용 점수 계산, 행렬 생성) | 5 | ML Eng | To Do |
| ML-2 | ALS 모델 학습 구현 (implicit 라이브러리) | 5 | ML Eng | To Do |
| ML-3 | 오프라인 평가 프레임워크 (Precision@K, NDCG@K 등) | 5 | ML Eng | To Do |
| ML-4 | MLflow 모델 레지스트리 연동 | 3 | ML Eng | To Do |

**총 SP:** 18

### 완료 기준
- [ ] ALS 모델 학습 완료 (테스트 데이터 기준)
- [ ] 오프라인 평가 지표가 목표값 이상
- [ ] 모델 아티팩트가 MLflow에 저장
- [ ] 하이퍼파라미터 튜닝 결과 기록

---

## Sprint 4 (Week 7~8): 모델 고도화 및 배치 파이프라인

### 목표
추천 결과 사전 계산, 폴백 모델, 학습 스케줄링

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| ML-5 | 추천 결과 사전 계산 (Top-50 per user) | 5 | ML Eng | To Do |
| ML-6 | Item-Based CF 유사 아이템 계산 | 3 | ML Eng | To Do |
| ML-7 | 인기 상품 기반 폴백 모델 | 2 | ML Eng | To Do |
| ML-8 | Airflow DAG: 일일 학습 파이프라인 자동화 | 5 | ML/Data Eng | To Do |
| ML-9 | Redis 추천 결과 적재 모듈 | 3 | ML/BE Eng | To Do |

**총 SP:** 18

### 완료 기준
- [ ] 전체 사용자 추천 결과가 Redis에 적재
- [ ] 유사 아이템 결과가 Redis에 적재
- [ ] 일일 학습 파이프라인 자동 실행 및 성공
- [ ] 폴백 체인 동작 확인

---

## Sprint 5 (Week 9~10): 추천 API 개발

### 목표
핵심 추천 API 엔드포인트 구현 및 배포

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| US-201 | 개인 추천 API (GET /recommendations/{user_id}) | 5 | BE Eng | To Do |
| US-102-API | 유사 상품 API (GET /recommendations/items/{item_id}/similar) | 3 | BE Eng | To Do |
| US-202 | API 인증 (API Key) 및 속도 제한 | 5 | BE Eng | To Do |
| US-103-API | 콜드 스타트 폴백 체인 구현 | 3 | BE Eng | To Do |
| API-1 | OpenAPI 문서 자동 생성 | 2 | BE Eng | To Do |

**총 SP:** 18

### 완료 기준
- [ ] 개인 추천 API P99 < 200ms
- [ ] 유사 상품 API 동작
- [ ] API Key 인증 및 속도 제한 동작
- [ ] 콜드 스타트 사용자에 폴백 추천 제공
- [ ] Swagger 문서 접근 가능

---

## Sprint 6 (Week 11~12): API 고도화 및 A/B 테스트

### 목표
배치 API, 피드백 API, A/B 테스트 프레임워크 구현

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| US-203 | 배치 추천 API | 5 | BE Eng | To Do |
| US-204 | 추천 피드백 API | 3 | BE Eng | To Do |
| US-304-BE | A/B 테스트 라우터 (트래픽 분배, 사용자 할당) | 8 | BE Eng | To Do |
| API-2 | 추천 로그 기록 (recommendation_logs) | 3 | BE Eng | To Do |

**총 SP:** 19

### 완료 기준
- [ ] 배치 API로 100명 동시 추천 5초 이내
- [ ] 피드백 API로 클릭/구매 이벤트 수집
- [ ] A/B 테스트 트래픽 분배 동작
- [ ] 추천 로그가 DB에 기록

---

## Sprint 7 (Week 13~14): 관리자 대시보드 (기본)

### 목표
대시보드 홈, 성능 지표 조회, 시스템 상태 모니터링

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| US-301 | 대시보드 홈 (KPI 요약 카드) | 5 | FE Eng | To Do |
| US-302 | 성능 추이 그래프 (일/주/월) | 8 | FE Eng | To Do |
| US-306 | 시스템 상태 모니터링 화면 | 3 | FE Eng | To Do |
| ADMIN-1 | Admin API: 대시보드 요약 / 메트릭 조회 | 5 | BE Eng | To Do |
| ADMIN-2 | 관리자 인증 (OAuth2/SSO) | 3 | BE/FE Eng | To Do |

**총 SP:** 24

### 완료 기준
- [ ] 대시보드 홈에서 CTR, 전환율, 요청 수 확인 가능
- [ ] 기간별 성능 추이 그래프 동작
- [ ] API 응답 시간, 에러율 모니터링 가능
- [ ] 관리자 로그인 동작

---

## Sprint 8 (Week 15~16): 관리자 대시보드 (고급)

### 목표
모델 관리, A/B 테스트 관리, 사용자 미리보기

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| US-303 | 모델 버전 관리 화면 | 8 | FE Eng | To Do |
| US-304 | A/B 테스트 실험 관리 화면 | 8 | FE Eng | To Do |
| US-305 | 사용자 추천 미리보기 | 5 | FE Eng | To Do |
| ADMIN-3 | Admin API: 모델 관리, 실험 관리 | 5 | BE Eng | To Do |

**총 SP:** 26

### 완료 기준
- [ ] 모델 버전 목록, 비교, 롤백 기능 동작
- [ ] A/B 테스트 생성, 조회, 종료 가능
- [ ] 특정 사용자 추천 미리보기 동작

---

## Sprint 9 (Week 17~18): 통합 테스트 및 출시

### 목표
E2E 테스트, 성능 테스트, 점진적 출시

### 스토리
| ID | 스토리 | SP | 담당 | 상태 |
|----|--------|-----|------|------|
| QA-1 | E2E 테스트 (전체 플로우) | 5 | QA/BE Eng | To Do |
| QA-2 | 부하 테스트 (API 5,000 RPS) | 5 | QA/BE Eng | To Do |
| QA-3 | 장애 시나리오 테스트 (Redis 다운, 모델 부재 등) | 3 | QA/BE Eng | To Do |
| RELEASE-1 | 카나리 배포 설정 (1% → 10% → 50% → 100%) | 3 | BE/DevOps | To Do |
| RELEASE-2 | 운영 문서 작성 (런북, 알림 설정) | 2 | 전체 | To Do |
| RELEASE-3 | 기존 서비스 추천 API 연동 | 5 | BE Eng | To Do |

**총 SP:** 23

### 완료 기준
- [ ] E2E 테스트 전체 통과
- [ ] 5,000 RPS에서 P99 < 200ms 확인
- [ ] 장애 시 폴백 정상 동작
- [ ] 카나리 배포로 프로덕션 트래픽 처리 시작

---

## 전체 SP 요약

| Sprint | 기간 | Phase | 총 SP |
|--------|------|-------|-------|
| Sprint 1 | Week 1~2 | 데이터 파이프라인 | 15 |
| Sprint 2 | Week 3~4 | 데이터 파이프라인 | 16 |
| Sprint 3 | Week 5~6 | 모델 개발 | 18 |
| Sprint 4 | Week 7~8 | 모델 개발 | 18 |
| Sprint 5 | Week 9~10 | API 개발 | 18 |
| Sprint 6 | Week 11~12 | API 개발 | 19 |
| Sprint 7 | Week 13~14 | 대시보드 | 24 |
| Sprint 8 | Week 15~16 | 대시보드 | 26 |
| Sprint 9 | Week 17~18 | 통합/출시 | 23 |
| **합계** | **18주** | | **177 SP** |

**팀 벨로시티 목표:** 스프린트당 18~20 SP

---

## 의존성 다이어그램

```
Sprint 1 (인프라, 이벤트 수집)
    │
    ▼
Sprint 2 (ETL, DW)
    │
    ├──────────────────┐
    ▼                  ▼
Sprint 3 (모델 학습)   Sprint 5 (API, Redis 의존)
    │                  │
    ▼                  ▼
Sprint 4 (결과 계산 → Redis)  Sprint 6 (A/B, 피드백)
    │                  │
    └──────┬───────────┘
           │
           ▼
    Sprint 7 (대시보드 기본)
           │
           ▼
    Sprint 8 (대시보드 고급)
           │
           ▼
    Sprint 9 (통합/출시)
```

> 참고: Sprint 5(API)는 Sprint 4(Redis 적재) 결과에 의존하지만,
> API 스켈레톤과 인증/속도제한은 병렬 개발 가능하여 일부 겹칠 수 있다.
