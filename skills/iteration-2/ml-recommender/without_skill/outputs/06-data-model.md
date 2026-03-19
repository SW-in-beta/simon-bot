# 데이터 모델 설계

## 1. 이벤트 데이터 (S3 / Kafka)

### 1-1. 사용자 행동 이벤트 (Raw Event)
```
테이블명: raw_events (Parquet, S3)
파티셔닝: year/month/day/hour
```

| 컬럼 | 타입 | 설명 | 예시 |
|------|------|------|------|
| event_id | STRING (UUID) | 이벤트 고유 ID | "evt_abc123" |
| user_id | STRING | 사용자 ID | "usr_456" |
| item_id | STRING | 상품 ID | "itm_789" |
| event_type | STRING (ENUM) | 이벤트 유형 | "click" |
| event_value | FLOAT | 이벤트 값 (평점 등) | 4.5 |
| timestamp | TIMESTAMP | 이벤트 발생 시각 | "2026-03-07T10:30:00Z" |
| session_id | STRING | 세션 ID | "ses_def456" |
| platform | STRING (ENUM) | 플랫폼 | "web" |
| page | STRING | 페이지 경로 | "/products/789" |
| referrer | STRING | 유입 경로 | "recommendation" |
| position | INT | 추천 슬롯 내 위치 | 3 |
| recommendation_id | STRING | 연관 추천 ID | "rec_ghi789" |
| created_at | TIMESTAMP | 레코드 적재 시각 | "2026-03-07T10:30:05Z" |

---

## 2. 분석/집계 테이블 (Data Warehouse)

### 2-1. 사용자-아이템 상호작용 (모델 학습용)
```
테이블명: user_item_interactions
갱신 주기: Daily Batch
```

| 컬럼 | 타입 | 설명 |
|------|------|------|
| user_id | STRING | 사용자 ID |
| item_id | STRING | 상품 ID |
| interaction_score | FLOAT | 가중 상호작용 점수 |
| view_count | INT | 조회 횟수 |
| click_count | INT | 클릭 횟수 |
| cart_count | INT | 장바구니 추가 횟수 |
| purchase_count | INT | 구매 횟수 |
| rating | FLOAT | 평점 (있는 경우) |
| last_interaction_at | TIMESTAMP | 마지막 상호작용 시각 |
| first_interaction_at | TIMESTAMP | 첫 상호작용 시각 |

**인덱스:** (user_id, item_id) - Primary Key

**interaction_score 계산 공식:**
```
score = (view_count * 1.0) + (click_count * 1.5) + (cart_count * 3.0)
        + (purchase_count * 5.0) + (rating * 1.0)
        + time_decay_factor
```

### 2-2. 사용자 프로필 (집계)
```
테이블명: user_profiles
갱신 주기: Daily Batch
```

| 컬럼 | 타입 | 설명 |
|------|------|------|
| user_id | STRING | 사용자 ID |
| total_interactions | INT | 총 상호작용 수 |
| total_items_interacted | INT | 상호작용한 고유 상품 수 |
| total_purchases | INT | 총 구매 수 |
| avg_rating | FLOAT | 평균 평점 |
| top_categories | ARRAY<STRING> | 상위 관심 카테고리 |
| first_seen_at | TIMESTAMP | 첫 활동 시각 |
| last_seen_at | TIMESTAMP | 마지막 활동 시각 |
| is_cold_start | BOOLEAN | 콜드 스타트 여부 (상호작용 < 5) |
| segment | STRING | 사용자 세그먼트 |

### 2-3. 아이템 프로필 (집계)
```
테이블명: item_profiles
갱신 주기: Daily Batch
```

| 컬럼 | 타입 | 설명 |
|------|------|------|
| item_id | STRING | 상품 ID |
| category | STRING | 카테고리 |
| total_interactions | INT | 총 상호작용 수 |
| total_users_interacted | INT | 상호작용한 고유 사용자 수 |
| total_purchases | INT | 총 구매 수 |
| avg_rating | FLOAT | 평균 평점 |
| popularity_score | FLOAT | 인기도 점수 |
| is_active | BOOLEAN | 활성 상태 |
| created_at | TIMESTAMP | 상품 등록 시각 |
| is_cold_start | BOOLEAN | 콜드 스타트 여부 (상호작용 < 5) |

### 2-4. 추천 성능 지표 (집계)
```
테이블명: recommendation_metrics
갱신 주기: 5분 (Near-Real-Time)
```

| 컬럼 | 타입 | 설명 |
|------|------|------|
| date | DATE | 날짜 |
| hour | INT | 시간 (0~23) |
| model_version | STRING | 모델 버전 |
| experiment_id | STRING | 실험 ID (nullable) |
| variant_id | STRING | 변형 ID (nullable) |
| strategy | STRING | 추천 전략 (cf/fallback) |
| total_requests | INT | 총 추천 요청 수 |
| total_impressions | INT | 총 노출 수 |
| total_clicks | INT | 총 클릭 수 |
| total_conversions | INT | 총 전환 수 |
| ctr | FLOAT | 클릭률 |
| conversion_rate | FLOAT | 전환율 |
| avg_response_time_ms | FLOAT | 평균 응답 시간 (ms) |
| p99_response_time_ms | FLOAT | P99 응답 시간 (ms) |
| fallback_ratio | FLOAT | 폴백 사용 비율 |
| unique_items_recommended | INT | 고유 추천 상품 수 |
| coverage | FLOAT | 커버리지 |

---

## 3. 서비스 메타데이터 (PostgreSQL)

### 3-1. 모델 버전 관리
```sql
CREATE TABLE models (
    id              SERIAL PRIMARY KEY,
    model_id        VARCHAR(50) UNIQUE NOT NULL,
    model_version   VARCHAR(20) NOT NULL,
    algorithm       VARCHAR(50) NOT NULL,        -- 'als', 'svd', 'item_cf', 'user_cf'
    status          VARCHAR(20) NOT NULL,         -- 'training', 'trained', 'serving', 'archived'
    hyperparameters JSONB,
    training_data   JSONB,                        -- 학습 데이터 범위 정보
    offline_metrics JSONB,                        -- Precision@K, NDCG 등
    artifact_path   VARCHAR(500),                 -- Model Registry 경로
    trained_at      TIMESTAMP,
    deployed_at     TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- offline_metrics 예시:
-- {
--   "precision_at_10": 0.18,
--   "recall_at_10": 0.12,
--   "ndcg_at_10": 0.22,
--   "map": 0.14,
--   "coverage": 0.85,
--   "training_samples": 15000000,
--   "training_duration_sec": 3600
-- }
```

### 3-2. A/B 테스트 실험
```sql
CREATE TABLE experiments (
    id              SERIAL PRIMARY KEY,
    experiment_id   VARCHAR(50) UNIQUE NOT NULL,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    status          VARCHAR(20) NOT NULL,         -- 'draft', 'running', 'completed', 'cancelled'
    start_date      DATE,
    end_date        DATE,
    min_sample_size INT DEFAULT 10000,
    created_by      VARCHAR(100),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE experiment_variants (
    id              SERIAL PRIMARY KEY,
    experiment_id   VARCHAR(50) REFERENCES experiments(experiment_id),
    variant_id      VARCHAR(50) NOT NULL,
    model_id        VARCHAR(50) REFERENCES models(model_id),
    traffic_ratio   FLOAT NOT NULL,               -- 0.0 ~ 1.0
    is_control      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(experiment_id, variant_id)
);

CREATE TABLE experiment_results (
    id              SERIAL PRIMARY KEY,
    experiment_id   VARCHAR(50) REFERENCES experiments(experiment_id),
    variant_id      VARCHAR(50) NOT NULL,
    date            DATE NOT NULL,
    sample_size     INT,
    ctr             FLOAT,
    conversion_rate FLOAT,
    revenue_per_user FLOAT,
    p_value_ctr     FLOAT,
    p_value_cvr     FLOAT,
    is_significant  BOOLEAN,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE(experiment_id, variant_id, date)
);
```

### 3-3. API Key 관리
```sql
CREATE TABLE api_keys (
    id              SERIAL PRIMARY KEY,
    api_key_hash    VARCHAR(64) UNIQUE NOT NULL,   -- SHA-256 해시
    client_name     VARCHAR(100) NOT NULL,
    permissions     JSONB,                          -- 허용 엔드포인트 목록
    rate_limit      INT DEFAULT 100,               -- 초당 최대 요청 수
    is_active       BOOLEAN DEFAULT TRUE,
    expires_at      TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
```

### 3-4. 추천 로그
```sql
CREATE TABLE recommendation_logs (
    id                  BIGSERIAL PRIMARY KEY,
    recommendation_id   VARCHAR(50) NOT NULL,
    user_id             VARCHAR(50) NOT NULL,
    model_version       VARCHAR(20),
    experiment_id       VARCHAR(50),
    variant_id          VARCHAR(50),
    strategy            VARCHAR(30),               -- 'cf', 'popular', 'curated'
    items_recommended   JSONB,                      -- [{item_id, score, rank}]
    response_time_ms    INT,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- 파티셔닝: created_at 기준 월별 파티션
-- 인덱스: (recommendation_id), (user_id, created_at)
-- 보관 기간: 90일 (이후 S3 아카이브)
```

---

## 4. 캐시 데이터 (Redis)

### 4-1. 사전 계산 추천 결과
```
Key:    reco:user:{user_id}
Value:  JSON Array
TTL:    3600초 (1시간)
```
```json
[
  {"item_id": "itm_001", "score": 0.95, "rank": 1},
  {"item_id": "itm_002", "score": 0.91, "rank": 2},
  ...
]
```

### 4-2. 유사 아이템
```
Key:    reco:similar:{item_id}
Value:  JSON Array
TTL:    3600초 (1시간)
```
```json
[
  {"item_id": "itm_010", "similarity": 0.87, "rank": 1},
  {"item_id": "itm_011", "similarity": 0.82, "rank": 2},
  ...
]
```

### 4-3. 인기 상품 (폴백용)
```
Key:    reco:popular:global
Key:    reco:popular:category:{category_id}
Value:  JSON Array
TTL:    1800초 (30분)
```

### 4-4. A/B 테스트 사용자 할당
```
Key:    ab:{experiment_id}:{user_id}
Value:  variant_id
TTL:    실험 종료일까지
```

---

## 5. ERD (Entity Relationship Diagram)

```
┌──────────────┐     ┌────────────────────┐     ┌──────────────────┐
│   models     │     │   experiments      │     │   api_keys       │
├──────────────┤     ├────────────────────┤     ├──────────────────┤
│ model_id (PK)│◄──┐ │ experiment_id (PK) │     │ id (PK)          │
│ model_version│    │ │ name               │     │ api_key_hash     │
│ algorithm    │    │ │ status             │     │ client_name      │
│ status       │    │ │ start_date         │     │ rate_limit       │
│ offline_     │    │ │ end_date           │     │ is_active        │
│   metrics    │    │ └─────────┬──────────┘     └──────────────────┘
└──────────────┘    │           │
                    │           │ 1:N
                    │ ┌─────────┴──────────┐
                    │ │ experiment_variants │
                    │ ├────────────────────┤
                    └─┤ model_id (FK)      │
                      │ experiment_id (FK) │
                      │ variant_id         │
                      │ traffic_ratio      │
                      └─────────┬──────────┘
                                │
                                │ 1:N
                      ┌─────────┴──────────┐
                      │ experiment_results  │
                      ├────────────────────┤
                      │ experiment_id (FK) │
                      │ variant_id         │
                      │ date               │
                      │ ctr                │
                      │ conversion_rate    │
                      │ p_value            │
                      └────────────────────┘

┌──────────────────────┐
│ recommendation_logs  │
├──────────────────────┤
│ recommendation_id    │
│ user_id              │
│ model_version        │
│ experiment_id        │
│ items_recommended    │
│ response_time_ms     │
│ created_at           │
└──────────────────────┘
```
