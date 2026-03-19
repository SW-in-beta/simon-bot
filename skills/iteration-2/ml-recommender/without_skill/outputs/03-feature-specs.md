# 기능 명세서 (Feature Specifications)

## 1. 기능 목록 요약

| ID | 기능명 | 우선순위 | 복잡도 | 담당 Squad |
|----|--------|----------|--------|-----------|
| F-001 | 사용자 행동 데이터 수집 | P0 | 높음 | Data / Backend |
| F-002 | 협업 필터링 모델 학습 | P0 | 높음 | ML |
| F-003 | 추천 결과 제공 REST API | P0 | 중간 | Backend |
| F-004 | 관리자 대시보드 | P0 | 중간 | Frontend |
| F-005 | A/B 테스트 프레임워크 | P1 | 중간 | Backend |
| F-006 | 콜드 스타트 대응 | P1 | 중간 | ML / Backend |
| F-007 | 추천 로그 및 피드백 수집 | P1 | 낮음 | Backend |

---

## 2. 상세 기능 명세

### F-001: 사용자 행동 데이터 수집

#### 개요
사용자의 서비스 내 행동(상품 조회, 클릭, 장바구니 추가, 구매, 평점 등)을 수집하여
추천 모델의 입력 데이터로 활용할 수 있는 파이프라인을 구축한다.

#### 수집 대상 이벤트
| 이벤트 | 설명 | 가중치 (기본) |
|--------|------|---------------|
| `page_view` | 상품 상세 페이지 조회 | 1.0 |
| `click` | 상품 클릭 | 1.5 |
| `add_to_cart` | 장바구니 추가 | 3.0 |
| `purchase` | 구매 완료 | 5.0 |
| `rating` | 평점 부여 | 평점값 (1~5) |
| `wishlist` | 위시리스트 추가 | 2.5 |
| `search` | 검색 (검색어 포함) | 0.5 |

#### 이벤트 데이터 스키마
```json
{
  "event_id": "uuid",
  "user_id": "string",
  "item_id": "string",
  "event_type": "enum(page_view|click|add_to_cart|purchase|rating|wishlist|search)",
  "event_value": "float (optional, e.g., rating value)",
  "timestamp": "ISO 8601",
  "session_id": "string",
  "platform": "enum(web|ios|android)",
  "context": {
    "page": "string",
    "referrer": "string",
    "position": "int (추천 슬롯 내 위치)",
    "recommendation_id": "string (추천에 의한 클릭인 경우)"
  }
}
```

#### 기술 요구사항
- 이벤트 수집: HTTP 엔드포인트 또는 기존 이벤트 버스 연동
- 메시지 큐: Kafka 또는 AWS Kinesis
- 저장소: 원본 이벤트는 S3/GCS (Parquet), 집계 데이터는 DW (BigQuery/Redshift)
- 처리량: 최소 초당 10,000 이벤트 처리
- 지연: 이벤트 발생 후 5분 이내 DW 반영 (Near-Real-Time)

#### 수락 기준
- [ ] 모든 정의된 이벤트 타입을 수집할 수 있다
- [ ] 이벤트 유실률 0.1% 이하
- [ ] 중복 이벤트 제거 (idempotent processing)
- [ ] 이벤트 스키마 유효성 검증 (invalid 이벤트 별도 DLQ 적재)
- [ ] 최근 90일 데이터 조회 가능

---

### F-002: 협업 필터링 모델 학습

#### 개요
수집된 사용자 행동 데이터를 기반으로 협업 필터링 모델을 학습하고,
사용자별 추천 상품 목록을 생성한다.

#### 모델 종류

##### 2-1. User-Based Collaborative Filtering
- 유사한 행동 패턴을 가진 사용자 그룹을 찾고, 해당 그룹이 선호하는 상품을 추천
- 유사도 측정: 코사인 유사도, 피어슨 상관계수
- 적합 케이스: 사용자 수 < 상품 수인 경우

##### 2-2. Item-Based Collaborative Filtering
- 사용자가 선호한 상품과 유사한 상품을 추천
- 유사도 측정: 코사인 유사도, Adjusted Cosine
- 적합 케이스: 상품 수 < 사용자 수인 경우, 아이템 유사도가 비교적 안정적

##### 2-3. Matrix Factorization (ALS / SVD)
- 사용자-아이템 상호작용 행렬을 저차원 잠재 인자(latent factor)로 분해
- 알고리즘: ALS (Alternating Least Squares), SVD++
- 주 모델로 사용 (성능 및 확장성 우수)

#### 학습 파이프라인
```
[행동 데이터 (S3)]
    → [전처리 (Spark/Pandas)]
    → [상호작용 행렬 생성]
    → [모델 학습 (ALS/SVD)]
    → [오프라인 평가]
    → [모델 저장 (Model Registry)]
    → [추천 결과 사전 계산]
    → [추천 결과 저장 (Redis/DB)]
```

#### 하이퍼파라미터
| 파라미터 | 설명 | 기본값 | 탐색 범위 |
|----------|------|--------|-----------|
| `n_factors` | 잠재 인자 수 | 100 | 50~300 |
| `n_iterations` | 학습 반복 수 | 20 | 10~50 |
| `regularization` | 정규화 계수 | 0.1 | 0.01~1.0 |
| `alpha` | 암시적 피드백 신뢰도 | 40 | 10~100 |
| `min_interactions` | 최소 상호작용 수 | 5 | 3~10 |

#### 오프라인 평가 지표
| 지표 | 설명 | 목표값 |
|------|------|--------|
| Precision@K (K=10) | 상위 K개 추천 중 관련 상품 비율 | >= 0.15 |
| Recall@K (K=10) | 전체 관련 상품 중 상위 K개에 포함된 비율 | >= 0.10 |
| NDCG@K (K=10) | 순위 고려한 추천 품질 | >= 0.20 |
| MAP | Mean Average Precision | >= 0.12 |
| 커버리지 | 추천 가능 상품 비율 | >= 80% |

#### 학습 스케줄
- 전체 재학습: 1일 1회 (새벽 배치)
- 증분 업데이트: 향후 고려 (Phase 2+)

#### 수락 기준
- [ ] 오프라인 평가에서 목표 지표 달성
- [ ] 학습 파이프라인이 스케줄에 따라 자동 실행
- [ ] 모델 버전 관리 (이전 모델로 롤백 가능)
- [ ] 학습 실패 시 알림 발송
- [ ] 학습 소요 시간 2시간 이내 (1,000만 상호작용 기준)

---

### F-003: 추천 결과 제공 REST API

#### 개요
학습된 모델의 추천 결과를 REST API로 제공한다.
사전 계산된 추천 결과를 캐시에서 서빙하여 저지연을 보장한다.

#### API 엔드포인트

##### 3-1. 개인 추천
```
GET /api/v1/recommendations/{user_id}
```
| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `user_id` | path | Y | 사용자 ID |
| `limit` | query | N | 추천 상품 수 (기본: 10, 최대: 50) |
| `offset` | query | N | 페이지네이션 오프셋 (기본: 0) |
| `category` | query | N | 카테고리 필터 |
| `exclude_purchased` | query | N | 구매한 상품 제외 (기본: true) |

**응답 (200 OK)**
```json
{
  "user_id": "user_123",
  "recommendations": [
    {
      "item_id": "item_456",
      "score": 0.95,
      "rank": 1,
      "reason_type": "collaborative_filtering"
    }
  ],
  "recommendation_id": "rec_abc123",
  "model_version": "v2.1.0",
  "generated_at": "2026-03-07T10:00:00Z",
  "total_count": 50,
  "metadata": {
    "strategy": "matrix_factorization",
    "fallback_used": false
  }
}
```

##### 3-2. 유사 상품 추천
```
GET /api/v1/recommendations/items/{item_id}/similar
```
| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `item_id` | path | Y | 기준 상품 ID |
| `limit` | query | N | 추천 상품 수 (기본: 10) |

**응답 (200 OK)**
```json
{
  "item_id": "item_456",
  "similar_items": [
    {
      "item_id": "item_789",
      "similarity_score": 0.87,
      "rank": 1
    }
  ],
  "model_version": "v2.1.0"
}
```

##### 3-3. 배치 추천
```
POST /api/v1/recommendations/batch
```
```json
{
  "user_ids": ["user_1", "user_2", "user_3"],
  "limit": 10
}
```

##### 3-4. 추천 피드백
```
POST /api/v1/recommendations/{recommendation_id}/feedback
```
```json
{
  "user_id": "user_123",
  "item_id": "item_456",
  "action": "click|dismiss|purchase",
  "timestamp": "2026-03-07T10:05:00Z"
}
```

#### 비기능 요구사항
| 항목 | 요구사항 |
|------|----------|
| 응답 시간 | P50: 50ms, P99: 200ms |
| 가용성 | 99.9% |
| 처리량 | 초당 5,000 요청 |
| 인증 | API Key 또는 OAuth2 Bearer Token |
| 속도 제한 | 클라이언트당 초당 100 요청 |

#### 에러 응답
| 상태 코드 | 설명 |
|-----------|------|
| 400 | 잘못된 요청 파라미터 |
| 401 | 인증 실패 |
| 404 | 사용자/상품 없음 |
| 429 | 속도 제한 초과 |
| 500 | 서버 내부 오류 |
| 503 | 서비스 일시 중단 (모델 업데이트 중) |

#### 수락 기준
- [ ] 모든 API 엔드포인트가 정의된 스키마대로 동작
- [ ] P99 응답 시간 200ms 이하
- [ ] 콜드 스타트 사용자에 대해 폴백 추천 제공
- [ ] API 문서 (OpenAPI/Swagger) 자동 생성
- [ ] 속도 제한 및 인증 동작

---

### F-004: 관리자 대시보드

#### 개요
추천 시스템의 성능 지표를 실시간으로 모니터링하고,
모델 및 A/B 테스트를 관리할 수 있는 웹 기반 대시보드를 제공한다.

#### 화면 구성

##### 4-1. 대시보드 홈
- 주요 KPI 요약 카드 (CTR, 전환율, 일 추천 요청 수)
- 일별/주별 추이 그래프
- 모델 상태 (현재 버전, 마지막 학습 시간, 다음 학습 예정)
- 시스템 상태 (API 응답 시간, 에러율)

##### 4-2. 추천 성능 분석
- 추천 CTR 추이 (일별, 주별, 월별)
- 추천 → 구매 전환 퍼널
- 카테고리별 추천 성능
- 추천 커버리지 및 다양성 지표
- 인기도 편향 분석 (long-tail 추천 비율)

##### 4-3. 모델 관리
- 모델 버전 목록 및 학습 이력
- 오프라인 평가 지표 비교 (버전별)
- 모델 롤백 버튼
- 학습 파이프라인 상태 및 로그

##### 4-4. A/B 테스트 관리
- 실험 생성/종료
- 실험별 성능 비교 (통계적 유의성 포함)
- 트래픽 분배 설정

##### 4-5. 사용자/아이템 탐색
- 특정 사용자의 추천 결과 미리보기
- 특정 상품의 유사 상품 조회
- 사용자 행동 이력 조회

#### 대시보드 API (Backend)
```
GET  /api/v1/admin/dashboard/summary
GET  /api/v1/admin/dashboard/metrics?period=7d
GET  /api/v1/admin/models
POST /api/v1/admin/models/{model_id}/rollback
GET  /api/v1/admin/experiments
POST /api/v1/admin/experiments
GET  /api/v1/admin/users/{user_id}/preview
```

#### 비기능 요구사항
- 데이터 갱신 주기: 5분 (Near-Real-Time)
- 과거 데이터 조회: 최근 90일
- 접근 제어: 관리자 권한 필요 (RBAC)
- 반응형 웹 (데스크탑 최적화, 태블릿 지원)

#### 수락 기준
- [ ] 모든 정의된 화면이 구현되어 있다
- [ ] 지표 데이터가 5분 이내 갱신된다
- [ ] 최소 3개 이상의 기간 필터 (일/주/월) 지원
- [ ] 모델 롤백 기능이 정상 동작
- [ ] 관리자 인증/인가 적용

---

### F-005: A/B 테스트 프레임워크

#### 개요
추천 모델/전략 간 성능을 비교하기 위한 A/B 테스트 인프라를 제공한다.

#### 실험 설정
```json
{
  "experiment_id": "exp_001",
  "name": "MF vs ItemCF 비교",
  "description": "Matrix Factorization과 Item-Based CF 성능 비교",
  "status": "running",
  "variants": [
    {
      "variant_id": "control",
      "model_version": "v2.0.0",
      "traffic_ratio": 0.5
    },
    {
      "variant_id": "treatment",
      "model_version": "v2.1.0",
      "traffic_ratio": 0.5
    }
  ],
  "metrics": ["ctr", "conversion_rate", "revenue_per_user"],
  "start_date": "2026-03-07",
  "end_date": "2026-03-21",
  "min_sample_size": 10000
}
```

#### 트래픽 분배
- 해시 기반 사용자 할당 (일관된 경험 보장)
- 다중 실험 동시 실행 지원 (상호 배타적 그룹)

#### 수락 기준
- [ ] 실험 생성/시작/종료가 가능하다
- [ ] 트래픽이 설정된 비율로 분배된다
- [ ] 같은 사용자는 실험 기간 동안 같은 variant를 본다
- [ ] 통계적 유의성 검정 (p-value) 결과를 제공한다

---

### F-006: 콜드 스타트 대응

#### 개요
신규 사용자 또는 신규 상품에 대해 추천이 불가능한 콜드 스타트 문제를 해결한다.

#### 전략
| 유형 | 전략 | 설명 |
|------|------|------|
| 신규 사용자 | 인기 상품 추천 | 전체/카테고리별 인기 상품 |
| 신규 사용자 | 온보딩 선호도 | 가입 시 관심 카테고리/상품 선택 |
| 신규 상품 | 카테고리 기반 | 같은 카테고리 인기 상품 위치에 배치 |
| 신규 상품 | 랜덤 노출 | 탐색(exploration) 목적으로 랜덤 노출 |

#### 폴백 체인
```
1. 개인화 추천 (CF 모델)
   ↓ (추천 결과 없음 또는 부족)
2. 세그먼트 기반 추천 (유사 사용자 그룹의 인기 상품)
   ↓ (세그먼트 정보 없음)
3. 전체 인기 상품 추천
   ↓ (인기 상품도 없음)
4. 큐레이션 상품 (수동 설정)
```

#### 수락 기준
- [ ] 행동 데이터가 없는 신규 사용자에게도 추천이 제공된다
- [ ] 폴백 체인이 순서대로 동작한다
- [ ] 대시보드에서 폴백 사용 비율을 확인할 수 있다

---

### F-007: 추천 로그 및 피드백 수집

#### 개요
추천 결과의 노출, 클릭, 전환 등을 추적하여 추천 성능 측정의 근거를 마련한다.

#### 추적 데이터
| 이벤트 | 설명 |
|--------|------|
| `recommendation_served` | 추천 결과 API 응답 |
| `recommendation_impressed` | 추천 결과가 실제로 사용자에게 노출 |
| `recommendation_clicked` | 추천 상품 클릭 |
| `recommendation_converted` | 추천 상품 구매 |

#### 수락 기준
- [ ] 모든 추천 요청에 고유 `recommendation_id`가 부여된다
- [ ] 노출/클릭/전환 이벤트가 추천과 연결된다
- [ ] 대시보드에서 퍼널 분석이 가능하다
