# 시스템 아키텍처 설계

## 1. 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────────┐
│                        클라이언트 레이어                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  웹/앱 서비스  │  │  관리자 대시보드 │  │  외부 서비스 (이메일 등)  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────────┘  │
└─────────┼──────────────────┼────────────────────┼──────────────────┘
          │                  │                    │
          ▼                  ▼                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        API Gateway / Load Balancer                   │
│                   (인증, 속도 제한, 라우팅, TLS)                       │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌────────────────┐ ┌────────────┐ ┌──────────────────┐
│ Recommendation │ │ Admin API  │ │ Event Collector  │
│ Service (API)  │ │ Service    │ │ Service          │
│ ┌────────────┐ │ │            │ │                  │
│ │ A/B Router │ │ │ 대시보드    │ │ 이벤트 수집/검증  │
│ │ Cache Layer│ │ │ 메트릭 집계  │ │                  │
│ │ Fallback   │ │ │ 모델 관리   │ │                  │
│ └────────────┘ │ └─────┬──────┘ └────────┬─────────┘
└───────┬────────┘       │                  │
        │                │                  ▼
        ▼                │         ┌────────────────┐
┌───────────────┐        │         │ Message Queue   │
│  Redis Cache  │        │         │ (Kafka/Kinesis) │
│ (추천 결과     │        │         └───────┬────────┘
│  캐싱)        │        │                 │
└───────┬───────┘        │                 ▼
        │                │        ┌─────────────────┐
        ▼                │        │ ETL Pipeline     │
┌───────────────┐        │        │ (Airflow/Spark)  │
│ Recommendation│        │        └───────┬─────────┘
│ Store (DB)    │◄───────┘                │
│               │                         ▼
│ - 사전계산 결과│                ┌─────────────────┐
│ - 모델 메타   │                │ Data Warehouse   │
│ - 실험 설정   │                │ (BigQuery/       │
└───────────────┘                │  Redshift)       │
                                 └────────┬────────┘
                                          │
                                          ▼
                                 ┌─────────────────┐
                                 │ ML Training      │
                                 │ Pipeline         │
                                 │ ┌─────────────┐  │
                                 │ │ 전처리       │  │
                                 │ │ 모델 학습    │  │
                                 │ │ 평가         │  │
                                 │ │ 결과 생성    │  │
                                 │ └─────────────┘  │
                                 └────────┬────────┘
                                          │
                                          ▼
                                 ┌─────────────────┐
                                 │ Model Registry   │
                                 │ (MLflow 등)      │
                                 └─────────────────┘
```

## 2. 서비스 구성

### 2-1. Recommendation Service (추천 서빙 서비스)
| 항목 | 내용 |
|------|------|
| 역할 | 추천 결과 API 서빙 |
| 언어/프레임워크 | Go (Gin/Echo) 또는 Python (FastAPI) |
| 통신 | REST API (외부), gRPC (내부 서비스 간) |
| 캐싱 | Redis (사전 계산 결과 캐싱, TTL: 1시간) |
| 특징 | A/B 라우터, 폴백 체인, 속도 제한 |

### 2-2. Admin API Service (관리자 API 서비스)
| 항목 | 내용 |
|------|------|
| 역할 | 대시보드 데이터 제공, 모델/실험 관리 |
| 언어/프레임워크 | Python (FastAPI) |
| 통신 | REST API |
| 데이터 소스 | DW (집계 지표), Recommendation Store (모델 메타) |

### 2-3. Event Collector Service (이벤트 수집 서비스)
| 항목 | 내용 |
|------|------|
| 역할 | 사용자 행동 이벤트 수집, 검증, 메시지 큐 전달 |
| 언어/프레임워크 | Go (고성능 처리) |
| 통신 | REST API (이벤트 수신), Kafka Producer |
| 특징 | 스키마 검증, DLQ 처리, 높은 처리량 |

### 2-4. ETL Pipeline (데이터 파이프라인)
| 항목 | 내용 |
|------|------|
| 역할 | 이벤트 데이터 처리, 변환, 적재 |
| 기술 | Apache Spark / Apache Airflow |
| 입력 | Kafka → S3 (raw events) |
| 출력 | DW (집계 테이블), Feature Store |
| 스케줄 | Near-Real-Time (5분) + Daily Batch |

### 2-5. ML Training Pipeline (모델 학습 파이프라인)
| 항목 | 내용 |
|------|------|
| 역할 | 모델 학습, 평가, 추천 결과 사전 계산 |
| 기술 | Python, Spark MLlib / implicit / surprise |
| 오케스트레이션 | Airflow |
| 입력 | DW (사용자-아이템 상호작용 데이터) |
| 출력 | 모델 아티팩트 (Model Registry), 추천 결과 (Redis/DB) |
| 스케줄 | Daily (새벽 3시) |

### 2-6. Admin Dashboard (관리자 대시보드)
| 항목 | 내용 |
|------|------|
| 역할 | 추천 성능 모니터링, 모델/실험 관리 UI |
| 기술 | Next.js + React + TypeScript |
| 차트 | Recharts 또는 Apache ECharts |
| 인증 | OAuth2 / SSO |

## 3. 데이터 저장소

### 3-1. 저장소 구성
| 저장소 | 기술 | 용도 | 데이터 |
|--------|------|------|--------|
| 이벤트 원본 | S3/GCS (Parquet) | 원본 이벤트 아카이브 | 전체 행동 로그 |
| 메시지 큐 | Kafka | 이벤트 스트리밍 | 실시간 이벤트 |
| DW | BigQuery/Redshift | 분석/집계 | 집계 지표, 상호작용 행렬 |
| 추천 결과 캐시 | Redis Cluster | 실시간 서빙 | 사전 계산 추천 결과 |
| 메타데이터 DB | PostgreSQL | 서비스 메타 | 모델 버전, 실험 설정, API Key |
| 모델 저장소 | MLflow / S3 | 모델 아티팩트 | 학습된 모델 파일 |

### 3-2. 데이터 흐름

```
[사용자 행동]
    │
    ▼
[Event Collector] ──▶ [Kafka] ──▶ [Spark Streaming] ──▶ [S3 (Parquet)]
                                         │
                                         ▼
                                  [DW (집계 테이블)]
                                         │
                         ┌───────────────┼───────────────┐
                         ▼               ▼               ▼
                  [ML Training]   [Admin Dashboard]  [실시간 지표]
                         │
                         ▼
                  [Model Registry]
                         │
                         ▼
                  [추천 결과 생성]
                         │
                         ▼
                  [Redis Cache] ◄──── [Recommendation Service]
```

## 4. 배포 아키텍처

### 4-1. 인프라 구성 (Kubernetes 기반)
```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                      │
│                                                           │
│  ┌─────────────────┐  ┌─────────────────┐               │
│  │ reco-api         │  │ admin-api        │               │
│  │ Deployment (3+)  │  │ Deployment (2)   │               │
│  │ HPA: CPU 70%     │  │                  │               │
│  └─────────────────┘  └─────────────────┘               │
│                                                           │
│  ┌─────────────────┐  ┌─────────────────┐               │
│  │ event-collector  │  │ admin-dashboard  │               │
│  │ Deployment (3+)  │  │ Deployment (2)   │               │
│  │ HPA: CPU 70%     │  │                  │               │
│  └─────────────────┘  └─────────────────┘               │
│                                                           │
│  ┌─────────────────────────────────────────┐             │
│  │ CronJob: ml-training (Daily 03:00)      │             │
│  └─────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────┘

┌─────────────────┐  ┌─────────────┐  ┌──────────────┐
│ Redis Cluster   │  │ PostgreSQL  │  │ Kafka Cluster│
│ (Managed)       │  │ (Managed)   │  │ (Managed)    │
└─────────────────┘  └─────────────┘  └──────────────┘
```

### 4-2. 스케일링 전략
| 서비스 | 스케일링 방식 | 기준 |
|--------|-------------|------|
| Recommendation API | HPA | CPU 70%, 요청 수 |
| Event Collector | HPA | CPU 70%, Kafka lag |
| Admin API | 고정 (2 replicas) | - |
| ML Training | 배치 Job | 데이터 크기에 따라 리소스 조정 |

## 5. 보안 설계

### 5-1. 인증/인가
| 대상 | 방식 | 설명 |
|------|------|------|
| 추천 API | API Key | 서비스 간 통신 인증 |
| 관리자 대시보드 | OAuth2 / SSO | 사내 인증 시스템 연동 |
| 관리자 API | JWT + RBAC | 역할 기반 접근 제어 |

### 5-2. 데이터 보안
- 전송 중 암호화: TLS 1.3
- 저장 시 암호화: AES-256 (S3, DB)
- 개인 식별 정보: user_id는 해시 처리, PII 미수집
- 로그: API Key, user_id 마스킹

## 6. 모니터링 및 알림

### 6-1. 모니터링 스택
| 도구 | 용도 |
|------|------|
| Prometheus + Grafana | 시스템 메트릭 (CPU, 메모리, 요청 수, 지연) |
| ELK Stack / Loki | 로그 수집 및 검색 |
| Datadog / New Relic | APM (선택) |
| PagerDuty / Slack | 알림 전달 |

### 6-2. 주요 알림 규칙
| 알림 | 조건 | 심각도 |
|------|------|--------|
| API 응답 지연 | P99 > 500ms (5분 지속) | Warning |
| API 응답 지연 | P99 > 1000ms (5분 지속) | Critical |
| API 에러율 | 5xx > 1% (5분 지속) | Warning |
| API 에러율 | 5xx > 5% (5분 지속) | Critical |
| 모델 학습 실패 | 학습 Job 실패 | Critical |
| 데이터 지연 | Kafka consumer lag > 100,000 | Warning |
| 캐시 히트율 | Redis hit rate < 80% | Warning |
| 추천 커버리지 | 폴백 비율 > 30% | Warning |

## 7. 기술 스택 요약

| 계층 | 기술 |
|------|------|
| 추천 API | Go (Gin) 또는 Python (FastAPI) |
| 관리자 API | Python (FastAPI) |
| 관리자 대시보드 | Next.js + React + TypeScript |
| 데이터 파이프라인 | Apache Spark + Apache Airflow |
| ML 프레임워크 | Python (implicit / surprise / Spark MLlib) |
| 모델 관리 | MLflow |
| 캐시 | Redis Cluster |
| 메시지 큐 | Apache Kafka |
| 메타데이터 DB | PostgreSQL |
| 데이터 웨어하우스 | BigQuery / Redshift |
| 오브젝트 스토리지 | S3 / GCS |
| 컨테이너 오케스트레이션 | Kubernetes |
| CI/CD | GitHub Actions |
| 모니터링 | Prometheus + Grafana |
| 로그 | ELK Stack / Loki |
