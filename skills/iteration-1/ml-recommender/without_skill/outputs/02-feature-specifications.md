# 기능 명세서 (Feature Specifications)

## 시스템 개요

사용자의 행동 데이터(조회, 클릭, 구매, 평점 등)를 기반으로 Collaborative Filtering 알고리즘을 적용하여 개인화된 상품 추천을 제공하는 시스템. REST API를 통해 추천 결과를 서빙하고, 관리자 대시보드에서 추천 성능을 모니터링한다.

---

## 1. 데이터 수집 및 처리 (Data Ingestion & Processing)

### 1.1 사용자 행동 데이터 수집

| 항목 | 내용 |
|------|------|
| 설명 | 사용자의 상품 관련 행동 이벤트를 실시간/배치로 수집 |
| 수집 이벤트 | `view` (상품 조회), `click` (상품 클릭), `add_to_cart` (장바구니 추가), `purchase` (구매), `rating` (평점) |
| 데이터 포맷 | `{ user_id, item_id, event_type, timestamp, metadata }` |
| 수집 방식 | 실시간 - Kafka/Kinesis 기반 스트리밍, 배치 - 일 단위 ETL |

### 1.2 데이터 전처리

| 항목 | 내용 |
|------|------|
| Implicit Feedback 변환 | 행동 이벤트를 가중치 기반 암묵적 피드백으로 변환 (view=1, click=2, add_to_cart=3, purchase=5) |
| 데이터 정제 | 봇 트래픽 필터링, 이상치 제거, 중복 이벤트 제거 |
| User-Item Matrix 생성 | 희소 행렬(Sparse Matrix) 형태로 사용자-상품 상호작용 매트릭스 생성 |
| Cold Start 처리 | 최소 상호작용 수 미달 사용자/상품 식별 및 폴백 전략 적용 |

### 1.3 데이터 저장소

| 저장소 | 용도 | 기술 |
|--------|------|------|
| 이벤트 스토어 | 원본 행동 이벤트 저장 | Kafka + S3/GCS |
| 피처 스토어 | 전처리된 피처 저장 | Redis (온라인) / Parquet (오프라인) |
| 추천 결과 캐시 | 사전 계산된 추천 결과 | Redis |
| 메타데이터 DB | 사용자/상품 메타정보 | PostgreSQL |

---

## 2. 추천 모델 (Recommendation Model)

### 2.1 Collaborative Filtering 모델

#### 2.1.1 기본 모델: ALS (Alternating Least Squares)

| 항목 | 내용 |
|------|------|
| 알고리즘 | Implicit ALS (Hu et al., 2008) |
| 입력 | User-Item 상호작용 매트릭스 (암묵적 피드백) |
| 출력 | 사용자별 상위 N개 추천 상품 리스트 + 점수 |
| 하이퍼파라미터 | factors=128, regularization=0.01, iterations=15, alpha=40 |
| 학습 주기 | 일 1회 전체 재학습 + 4시간마다 증분 업데이트 |

#### 2.1.2 고도화 모델: Neural Collaborative Filtering (NCF)

| 항목 | 내용 |
|------|------|
| 알고리즘 | GMF + MLP 하이브리드 (He et al., 2017) |
| 적용 시점 | Phase 2 (기본 모델 안정화 이후) |
| 장점 | 비선형 사용자-상품 관계 학습 가능 |

### 2.2 모델 평가 지표

| 지표 | 설명 | 목표값 |
|------|------|--------|
| Precision@K | 추천 K개 중 관련 상품 비율 | >= 0.15 |
| Recall@K | 전체 관련 상품 중 추천된 비율 | >= 0.10 |
| NDCG@K | 순위 가중 관련성 점수 | >= 0.20 |
| MAP | 평균 정밀도의 평균 | >= 0.12 |
| Hit Rate | 추천 목록에 1개 이상 관련 상품 포함 비율 | >= 0.40 |
| Coverage | 전체 상품 중 추천에 등장하는 상품 비율 | >= 0.30 |
| Diversity | 추천 목록 내 상품 간 다양성 | 모니터링 |

### 2.3 Cold Start 전략

| 대상 | 전략 |
|------|------|
| 신규 사용자 | 인기 상품 기반 추천 (Popularity Fallback) |
| 신규 상품 | 상품 메타데이터 기반 Content-Based 보조 추천 |
| 최소 기준 | 사용자: 5건 이상 상호작용, 상품: 10건 이상 상호작용 |

---

## 3. REST API (Recommendation Serving API)

### 3.1 API 엔드포인트

#### 3.1.1 개인화 추천 조회

```
GET /api/v1/recommendations/{user_id}
```

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| user_id | path | Y | 사용자 고유 ID |
| limit | query | N | 추천 상품 수 (기본값: 20, 최대: 100) |
| category | query | N | 카테고리 필터 |
| exclude_purchased | query | N | 구매 상품 제외 여부 (기본값: true) |

응답 예시:
```json
{
  "user_id": "user_12345",
  "recommendations": [
    {
      "item_id": "item_001",
      "score": 0.95,
      "rank": 1,
      "reason": "similar_users_purchased"
    }
  ],
  "model_version": "als-v1.2.0",
  "generated_at": "2026-03-07T10:00:00Z",
  "fallback_used": false,
  "metadata": {
    "total_candidates": 5000,
    "filtered_count": 20
  }
}
```

#### 3.1.2 유사 상품 추천 조회

```
GET /api/v1/items/{item_id}/similar
```

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| item_id | path | Y | 상품 고유 ID |
| limit | query | N | 유사 상품 수 (기본값: 10) |

#### 3.1.3 행동 이벤트 수집

```
POST /api/v1/events
```

요청 본문:
```json
{
  "user_id": "user_12345",
  "item_id": "item_001",
  "event_type": "click",
  "timestamp": "2026-03-07T10:00:00Z",
  "metadata": {
    "source": "search",
    "position": 3
  }
}
```

#### 3.1.4 배치 추천 조회

```
POST /api/v1/recommendations/batch
```

요청 본문:
```json
{
  "user_ids": ["user_001", "user_002", "user_003"],
  "limit": 10
}
```

#### 3.1.5 추천 피드백

```
POST /api/v1/recommendations/{user_id}/feedback
```

요청 본문:
```json
{
  "item_id": "item_001",
  "feedback_type": "clicked|dismissed|purchased",
  "timestamp": "2026-03-07T10:00:00Z"
}
```

### 3.2 API 비기능 요구사항

| 항목 | 요구사항 |
|------|----------|
| 응답 시간 | p50 < 50ms, p99 < 200ms |
| 처리량 | 최소 1,000 RPS |
| 가용성 | 99.9% SLA |
| 인증 | API Key 기반 인증 |
| Rate Limiting | API Key별 1,000 req/min |
| 캐싱 | Redis 캐시, TTL 1시간 |
| 버전 관리 | URL 기반 API 버전 관리 (/v1/) |
| 에러 처리 | 표준 HTTP 상태 코드 + JSON 에러 응답 |

### 3.3 에러 응답 형식

```json
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "사용자를 찾을 수 없습니다",
    "details": {
      "user_id": "user_99999"
    }
  },
  "request_id": "req_abc123"
}
```

---

## 4. 관리자 대시보드 (Admin Dashboard)

### 4.1 대시보드 페이지 구성

#### 4.1.1 메인 대시보드 (Overview)

| 위젯 | 내용 |
|------|------|
| 실시간 추천 요청 수 | 분당/시간당 API 호출 수 추이 그래프 |
| 오늘의 핵심 지표 | CTR, 전환율, 추천 커버리지 카드 |
| 모델 상태 | 현재 활성 모델 버전, 마지막 학습 시간, 상태 |
| 시스템 헬스 | API 응답시간, 에러율, 캐시 히트율 |

#### 4.1.2 추천 성능 모니터링 (Performance)

| 위젯 | 내용 |
|------|------|
| 오프라인 지표 추이 | Precision@K, Recall@K, NDCG@K 시계열 그래프 |
| 온라인 지표 추이 | CTR, 전환율, 매출 기여도 시계열 그래프 |
| 모델 버전별 비교 | 각 모델 버전의 성능 지표 비교 테이블 |
| A/B 테스트 현황 | 실험 그룹별 성능 비교, 통계적 유의성 |

#### 4.1.3 사용자 분석 (User Analytics)

| 위젯 | 내용 |
|------|------|
| 사용자 세그먼트 분포 | Cold/Warm/Hot 사용자 비율 파이 차트 |
| 사용자별 추천 조회 | 특정 사용자의 추천 결과 및 반응 히스토리 |
| 상호작용 히트맵 | 시간대별 사용자 행동 패턴 |

#### 4.1.4 상품 분석 (Item Analytics)

| 위젯 | 내용 |
|------|------|
| 추천 빈도 상위 상품 | 가장 많이 추천된 상품 Top N |
| Long-tail 커버리지 | 추천에 등장하는 상품 분포 |
| 카테고리별 추천 성능 | 카테고리별 CTR, 전환율 비교 |

#### 4.1.5 시스템 모니터링 (System)

| 위젯 | 내용 |
|------|------|
| API 성능 | 응답시간 분포, 에러율, RPS |
| 모델 학습 히스토리 | 학습 시작/종료 시간, 소요 시간, 데이터 크기 |
| 데이터 파이프라인 상태 | ETL 작업 성공/실패 현황 |
| 리소스 사용량 | CPU, 메모리, GPU 사용률 |

### 4.2 대시보드 기능 요구사항

| 기능 | 설명 |
|------|------|
| 기간 필터 | 1일/7일/30일/커스텀 기간 선택 |
| 자동 새로고침 | 30초/1분/5분 주기 자동 갱신 |
| 데이터 내보내기 | CSV/PDF 형식 리포트 다운로드 |
| 알림 설정 | 성능 지표 임계치 기반 Slack/이메일 알림 |
| 권한 관리 | 관리자/뷰어 역할 기반 접근 제어 |
| 반응형 UI | 데스크톱/태블릿 지원 |

### 4.3 알림 규칙 예시

| 조건 | 심각도 | 알림 채널 |
|------|--------|-----------|
| API 응답시간 p99 > 500ms (5분 지속) | Warning | Slack |
| API 에러율 > 5% (3분 지속) | Critical | Slack + PagerDuty |
| 모델 학습 실패 | Critical | Slack + 이메일 |
| CTR 전일 대비 30% 하락 | Warning | Slack |
| 추천 커버리지 < 20% | Warning | 이메일 |

---

## 5. 시스템 아키텍처 개요

```
[클라이언트/프론트엔드]
        │
        ▼
[API Gateway] ── 인증/Rate Limit
        │
        ▼
[추천 API 서버 (FastAPI)]
   ├── Redis Cache (추천 결과 캐시)
   ├── PostgreSQL (메타데이터)
   └── Feature Store (피처)
        │
        ▼
[모델 서빙 레이어]
   └── 사전 계산된 추천 결과 (Redis)
       또는 실시간 추론 (모델 서버)

[데이터 파이프라인]
   ├── Kafka (실시간 이벤트)
   ├── Airflow (배치 ETL)
   └── S3/GCS (데이터 레이크)

[모델 학습 파이프라인]
   ├── Spark (데이터 전처리)
   ├── 학습 서버 (GPU)
   └── MLflow (모델 레지스트리)

[관리자 대시보드 (Next.js)]
   ├── 대시보드 API (FastAPI)
   └── Grafana (시스템 모니터링 임베딩)
```

---

## 6. 기술 스택 요약

| 영역 | 기술 |
|------|------|
| 추천 모델 | Python, implicit (ALS), PyTorch (NCF) |
| 모델 서빙 | FastAPI, Redis |
| API 서버 | FastAPI (Python) 또는 Go |
| 데이터 파이프라인 | Apache Kafka, Apache Airflow, Apache Spark |
| 데이터 저장소 | PostgreSQL, Redis, S3/GCS |
| 모델 관리 | MLflow |
| 관리자 대시보드 | Next.js, React, Recharts |
| 모니터링 | Prometheus, Grafana |
| 인프라 | Kubernetes, Docker |
| CI/CD | GitHub Actions |
