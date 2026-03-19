# REST API 명세서

## 1. 공통 사항

### Base URL
```
프로덕션: https://api.recopilot.example.com/api/v1
스테이징: https://api-staging.recopilot.example.com/api/v1
```

### 인증
모든 요청에 `Authorization` 헤더를 포함해야 한다.
```
Authorization: Bearer {api_key}
```

### 공통 헤더
| 헤더 | 필수 | 설명 |
|------|------|------|
| Authorization | Y | API Key |
| Content-Type | Y (POST) | application/json |
| X-Request-ID | N | 요청 추적 ID (없으면 서버에서 생성) |
| Accept | N | application/json (기본값) |

### 공통 에러 응답 형식
```json
{
  "error": {
    "code": "INVALID_PARAMETER",
    "message": "limit must be between 1 and 50",
    "details": {
      "field": "limit",
      "value": 100,
      "constraint": "max=50"
    }
  },
  "request_id": "req_abc123"
}
```

### HTTP 상태 코드
| 코드 | 설명 |
|------|------|
| 200 | 성공 |
| 201 | 생성 성공 |
| 400 | 잘못된 요청 |
| 401 | 인증 실패 |
| 403 | 권한 부족 |
| 404 | 리소스 없음 |
| 429 | 속도 제한 초과 |
| 500 | 서버 내부 오류 |
| 503 | 서비스 일시 중단 |

### 속도 제한 헤더
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1709812800
```

---

## 2. 추천 API (Recommendation)

### 2-1. 개인 추천 조회

```
GET /recommendations/{user_id}
```

**Path 파라미터:**
| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| user_id | string | Y | 사용자 ID |

**Query 파라미터:**
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|----------|------|------|--------|------|
| limit | int | N | 10 | 추천 상품 수 (1~50) |
| offset | int | N | 0 | 페이지네이션 오프셋 |
| category | string | N | - | 카테고리 필터 |
| exclude_purchased | bool | N | true | 구매 상품 제외 여부 |
| exclude_items | string | N | - | 제외할 상품 ID (쉼표 구분) |

**응답 (200 OK):**
```json
{
  "user_id": "usr_456",
  "recommendations": [
    {
      "item_id": "itm_001",
      "score": 0.952,
      "rank": 1,
      "reason_type": "collaborative_filtering"
    },
    {
      "item_id": "itm_002",
      "score": 0.913,
      "rank": 2,
      "reason_type": "collaborative_filtering"
    }
  ],
  "recommendation_id": "rec_abc123",
  "model_version": "v2.1.0",
  "generated_at": "2026-03-07T10:00:00Z",
  "total_count": 50,
  "metadata": {
    "strategy": "matrix_factorization",
    "fallback_used": false,
    "experiment_id": "exp_001",
    "variant_id": "treatment"
  },
  "pagination": {
    "offset": 0,
    "limit": 10,
    "has_more": true
  }
}
```

**에러 응답:**
- `404`: 사용자를 찾을 수 없는 경우 (이 경우에도 폴백 추천은 제공 가능)
- `400`: 잘못된 파라미터 (limit 범위 초과 등)

---

### 2-2. 유사 상품 추천 조회

```
GET /recommendations/items/{item_id}/similar
```

**Path 파라미터:**
| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| item_id | string | Y | 기준 상품 ID |

**Query 파라미터:**
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|----------|------|------|--------|------|
| limit | int | N | 10 | 유사 상품 수 (1~30) |

**응답 (200 OK):**
```json
{
  "item_id": "itm_789",
  "similar_items": [
    {
      "item_id": "itm_010",
      "similarity_score": 0.872,
      "rank": 1
    },
    {
      "item_id": "itm_011",
      "similarity_score": 0.821,
      "rank": 2
    }
  ],
  "model_version": "v2.1.0",
  "total_count": 25
}
```

**에러 응답:**
- `404`: 상품을 찾을 수 없는 경우

---

### 2-3. 배치 추천 요청

```
POST /recommendations/batch
```

**요청 Body:**
```json
{
  "user_ids": ["usr_001", "usr_002", "usr_003"],
  "limit": 10,
  "exclude_purchased": true
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| user_ids | array[string] | Y | 사용자 ID 목록 (최대 100개) |
| limit | int | N | 사용자당 추천 수 (기본: 10) |
| exclude_purchased | bool | N | 구매 상품 제외 (기본: true) |

**응답 (200 OK):**
```json
{
  "results": [
    {
      "user_id": "usr_001",
      "status": "success",
      "recommendations": [
        {"item_id": "itm_001", "score": 0.95, "rank": 1}
      ],
      "recommendation_id": "rec_batch_001"
    },
    {
      "user_id": "usr_002",
      "status": "success",
      "recommendations": [
        {"item_id": "itm_005", "score": 0.88, "rank": 1}
      ],
      "recommendation_id": "rec_batch_002"
    },
    {
      "user_id": "usr_003",
      "status": "fallback",
      "recommendations": [
        {"item_id": "itm_100", "score": 0.70, "rank": 1}
      ],
      "recommendation_id": "rec_batch_003"
    }
  ],
  "summary": {
    "total": 3,
    "success": 2,
    "fallback": 1,
    "failed": 0
  }
}
```

---

### 2-4. 추천 피드백 전송

```
POST /recommendations/{recommendation_id}/feedback
```

**Path 파라미터:**
| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| recommendation_id | string | Y | 추천 ID |

**요청 Body:**
```json
{
  "user_id": "usr_456",
  "item_id": "itm_001",
  "action": "click",
  "timestamp": "2026-03-07T10:05:00Z",
  "context": {
    "position": 1,
    "page": "home"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| user_id | string | Y | 사용자 ID |
| item_id | string | Y | 상품 ID |
| action | string | Y | 액션 (click, dismiss, purchase, impression) |
| timestamp | string | Y | ISO 8601 시각 |
| context | object | N | 추가 컨텍스트 |

**응답 (201 Created):**
```json
{
  "feedback_id": "fb_xyz789",
  "status": "accepted"
}
```

---

## 3. 관리자 API (Admin)

### 3-1. 대시보드 요약

```
GET /admin/dashboard/summary
```

**응답 (200 OK):**
```json
{
  "period": "today",
  "kpis": {
    "total_requests": 125000,
    "total_requests_change": 0.05,
    "ctr": 0.082,
    "ctr_change": 0.12,
    "conversion_rate": 0.031,
    "conversion_rate_change": 0.08,
    "avg_response_time_ms": 45,
    "error_rate": 0.001
  },
  "model": {
    "current_version": "v2.1.0",
    "algorithm": "als",
    "last_trained_at": "2026-03-07T03:00:00Z",
    "next_training_at": "2026-03-08T03:00:00Z",
    "status": "serving"
  },
  "system": {
    "api_status": "healthy",
    "cache_hit_rate": 0.92,
    "fallback_ratio": 0.15
  }
}
```

---

### 3-2. 성능 지표 조회

```
GET /admin/dashboard/metrics
```

**Query 파라미터:**
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|----------|------|------|--------|------|
| period | string | N | 7d | 기간 (1d, 7d, 30d, 90d) |
| start_date | string | N | - | 시작일 (YYYY-MM-DD) |
| end_date | string | N | - | 종료일 (YYYY-MM-DD) |
| granularity | string | N | daily | 집계 단위 (hourly, daily, weekly) |
| category | string | N | - | 카테고리 필터 |

**응답 (200 OK):**
```json
{
  "period": {
    "start": "2026-03-01",
    "end": "2026-03-07",
    "granularity": "daily"
  },
  "metrics": [
    {
      "date": "2026-03-01",
      "total_requests": 120000,
      "total_impressions": 95000,
      "total_clicks": 7800,
      "total_conversions": 2900,
      "ctr": 0.082,
      "conversion_rate": 0.031,
      "avg_response_time_ms": 42,
      "p99_response_time_ms": 180,
      "fallback_ratio": 0.14,
      "coverage": 0.85,
      "unique_items_recommended": 12500
    }
  ]
}
```

---

### 3-3. 모델 목록 조회

```
GET /admin/models
```

**Query 파라미터:**
| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|----------|------|------|--------|------|
| status | string | N | - | 상태 필터 (trained, serving, archived) |
| limit | int | N | 20 | 결과 수 |
| offset | int | N | 0 | 오프셋 |

**응답 (200 OK):**
```json
{
  "models": [
    {
      "model_id": "model_2026030700",
      "model_version": "v2.1.0",
      "algorithm": "als",
      "status": "serving",
      "hyperparameters": {
        "n_factors": 100,
        "n_iterations": 20,
        "regularization": 0.1
      },
      "offline_metrics": {
        "precision_at_10": 0.18,
        "recall_at_10": 0.12,
        "ndcg_at_10": 0.22,
        "map": 0.14,
        "coverage": 0.85
      },
      "training_data": {
        "start_date": "2025-12-07",
        "end_date": "2026-03-07",
        "total_interactions": 15000000,
        "total_users": 500000,
        "total_items": 100000
      },
      "trained_at": "2026-03-07T03:45:00Z",
      "deployed_at": "2026-03-07T04:00:00Z"
    }
  ],
  "total_count": 15,
  "pagination": {
    "offset": 0,
    "limit": 20,
    "has_more": false
  }
}
```

---

### 3-4. 모델 롤백

```
POST /admin/models/{model_id}/rollback
```

**요청 Body:**
```json
{
  "reason": "v2.1.0 모델의 CTR이 이전 대비 10% 하락"
}
```

**응답 (200 OK):**
```json
{
  "status": "success",
  "previous_model": "v2.1.0",
  "rolled_back_to": "v2.0.0",
  "effective_at": "2026-03-07T10:30:00Z"
}
```

---

### 3-5. 실험 목록 조회

```
GET /admin/experiments
```

**응답 (200 OK):**
```json
{
  "experiments": [
    {
      "experiment_id": "exp_001",
      "name": "MF vs ItemCF 비교",
      "status": "running",
      "variants": [
        {
          "variant_id": "control",
          "model_version": "v2.0.0",
          "traffic_ratio": 0.5,
          "is_control": true
        },
        {
          "variant_id": "treatment",
          "model_version": "v2.1.0",
          "traffic_ratio": 0.5,
          "is_control": false
        }
      ],
      "results": {
        "control": {
          "sample_size": 25000,
          "ctr": 0.075,
          "conversion_rate": 0.028
        },
        "treatment": {
          "sample_size": 24800,
          "ctr": 0.082,
          "conversion_rate": 0.031,
          "p_value_ctr": 0.003,
          "is_significant": true
        }
      },
      "start_date": "2026-02-28",
      "end_date": "2026-03-14"
    }
  ]
}
```

---

### 3-6. 실험 생성

```
POST /admin/experiments
```

**요청 Body:**
```json
{
  "name": "ALS vs SVD++ 비교",
  "description": "ALS 모델과 SVD++ 모델의 실제 성능 비교",
  "variants": [
    {
      "variant_id": "control",
      "model_id": "model_2026030700",
      "traffic_ratio": 0.5,
      "is_control": true
    },
    {
      "variant_id": "treatment",
      "model_id": "model_2026030701",
      "traffic_ratio": 0.5,
      "is_control": false
    }
  ],
  "metrics": ["ctr", "conversion_rate", "revenue_per_user"],
  "start_date": "2026-03-08",
  "end_date": "2026-03-22",
  "min_sample_size": 10000
}
```

**응답 (201 Created):**
```json
{
  "experiment_id": "exp_002",
  "status": "draft",
  "created_at": "2026-03-07T11:00:00Z"
}
```

---

### 3-7. 사용자 추천 미리보기

```
GET /admin/users/{user_id}/preview
```

**응답 (200 OK):**
```json
{
  "user_id": "usr_456",
  "profile": {
    "total_interactions": 150,
    "total_purchases": 12,
    "top_categories": ["electronics", "books", "fashion"],
    "is_cold_start": false,
    "last_seen_at": "2026-03-07T09:45:00Z"
  },
  "current_recommendations": {
    "strategy": "matrix_factorization",
    "model_version": "v2.1.0",
    "items": [
      {"item_id": "itm_001", "score": 0.95, "rank": 1, "category": "electronics"},
      {"item_id": "itm_002", "score": 0.91, "rank": 2, "category": "books"}
    ]
  },
  "recent_activity": [
    {
      "event_type": "purchase",
      "item_id": "itm_100",
      "timestamp": "2026-03-06T15:00:00Z"
    },
    {
      "event_type": "click",
      "item_id": "itm_200",
      "timestamp": "2026-03-07T09:30:00Z"
    }
  ]
}
```

---

## 4. 이벤트 수집 API

### 4-1. 행동 이벤트 전송

```
POST /events
```

**요청 Body:**
```json
{
  "events": [
    {
      "event_id": "evt_abc123",
      "user_id": "usr_456",
      "item_id": "itm_789",
      "event_type": "click",
      "event_value": null,
      "timestamp": "2026-03-07T10:30:00Z",
      "session_id": "ses_def456",
      "platform": "web",
      "context": {
        "page": "/products/789",
        "referrer": "recommendation",
        "position": 3,
        "recommendation_id": "rec_abc123"
      }
    }
  ]
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| events | array | Y | 이벤트 배열 (최대 100개) |
| events[].event_id | string | Y | 이벤트 고유 ID (멱등성 보장) |
| events[].user_id | string | Y | 사용자 ID |
| events[].item_id | string | Y | 상품 ID |
| events[].event_type | string | Y | 이벤트 유형 |
| events[].timestamp | string | Y | ISO 8601 시각 |

**응답 (202 Accepted):**
```json
{
  "accepted": 1,
  "rejected": 0,
  "errors": []
}
```

---

## 5. 헬스체크

### 5-1. 서비스 상태 확인

```
GET /health
```

**응답 (200 OK):**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2026-03-07T10:00:00Z",
  "dependencies": {
    "redis": "healthy",
    "postgres": "healthy",
    "model": "serving"
  }
}
```

### 5-2. 준비 상태 확인

```
GET /ready
```

**응답 (200 OK):**
```json
{
  "ready": true
}
```
