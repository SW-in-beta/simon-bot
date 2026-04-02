# Buzzvil 서비스 레포 매핑

문의 키워드로 관련 레포를 찾기 위한 참조 테이블.
모든 레포는 `~/buzzvil/{레포명}`에 위치하며, 없으면 `gh repo clone Buzzvil/{레포명} ~/buzzvil/{레포명} -- --depth 1`로 클론.

## 광고 서빙 (Ad Serving)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| adserver | Django 기반 광고 플랫폼 — 광고 서빙, 추적, 관리의 핵심. Lineitem, Creative, Campaign 등 광고 엔티티 관리 | 광고 서버, lineitem, creative, campaign, 광고 등록, 광고 노출, Elasticsearch sync, 광고 상태 |
| biddersvc | 실시간 입찰 엔진 — 입찰 요청 처리, 최적 광고 선택, 밀리초 단위 응답 | 입찰, bidding, RTB, 광고 할당, 타게팅, 광고 안 나와요, 광고 매칭, 필터링 |
| adnsvc | 외부 Ad Network 연동 — 외부 네트워크에 요청을 보내 광고 할당 | 외부 광고, ad network, ADN, 네트워크 광고, 외부 매체, 미디에이션 |
| adrecommender | ML 기반 광고 추천 — CTR/수익 예측, 동적 입찰, 배치 최적화, Triton 서빙 | 추천, CTR 예측, ML 모델, 입찰 최적화, 추천 로직, Triton, 모델 서빙 |

## 광고 추적/분석 (Tracking & Analytics)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| adtracker | 광고 이벤트 추적/분석 — impression, click, conversion 등 이벤트 수집 및 처리 | 클릭, 노출, 전환, 이벤트 추적, tracking, impression, conversion, 로그, product feed |
| statssvc | gRPC 통계 API — Athena 기반 비즈니스 메트릭 집계 및 제공 | 통계, stats, 리포트, 매출, 수치, Athena, 집계, 대시보드 숫자 |

## 광고 운영 (Ad Operations)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| adpacingsvc | 광고 예산 패이싱 — 할당 상태 모니터링, 예산 소진 속도 조절, 광고 비활성화 | 패이싱, 예산, 소진, 일예산, budget, pacing, 광고 꺼짐, 광고 중단, spend |
| segmentsvc | 오디언스 세그먼트 관리 — 규칙 기반 프로필 분류, 광고 타게팅 | 세그먼트, 오디언스, 타게팅 조건, 프로필, 사용자 그룹 |

## 대시보드/관리 (Dashboard & Management)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| dash | 광고 성과 대시보드 웹 UI (React) | 대시보드, dash, 성과 화면, UI, 프론트엔드, 화면 깨짐 |
| dash-api-gateway | 대시보드 BFF — 대시보드 프론트엔드와 백엔드 서비스 사이 API 게이트웨이 | 대시보드 API, BFF, 게이트웨이, 대시보드 에러 |
| ads-center | 셀프서빙 광고 관리 플랫폼 (Next.js) — 광고주가 직접 광고 주문/관리 | 광고센터, 셀프서빙, 광고주 화면, 주문 관리, 광고 만들기 |
| nokta | 전사 계정 관리 플랫폼 — 멀티시스템 계정 동기화, 접근 제어 | 계정 관리, 권한, 접근 제어, 계정 생성, 리스크 탐지 |

## 보상/포인트 (Rewards & Points)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| pointsvc | 포인트 관리 (Go, DynamoDB) — 포인트 적립/차감 처리 | 포인트, 적립, 차감, point, 리워드 지급, 포인트 안 들어와요 |
| extpointprovidersvc | 외부 포인트 제공자 연동 — 외부 시스템과 포인트 API 연동 | 외부 포인트, 외부 적립, 제휴 포인트, 포인트 연동 |
| postbacksvc | 포스트백 워커 — 퍼블리셔에게 결과(적립 등) 콜백 전송 | postback, 콜백, 퍼블리셔 통보, 적립 결과 전달, 포스트백 실패 |
| rewardedcontent | 보상형 콘텐츠 — 콘텐츠 제공 및 클릭 캡핑 관리 | 보상형 콘텐츠, 클릭 제한, 캡핑, 콘텐츠 노출 |

## 인증 (Auth)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| auth | 인증/인가 서비스 — OAuth, 이메일, SMTP | 로그인, 인증, 인가, 토큰, OAuth, 권한, 로그인 안 돼요 |

## 정산 (Billing)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| billingsvc | 빌링/정산 서비스 — 재무 리포트 API 제공 | 빌링, 정산, 청구, 재무, 결제, 매출 리포트, 인보이스 |

## API/인프라 (API & Infra)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| buzzapis | API 인터페이스 정의 중앙 저장소 — Proto 정의, 다중 언어 코드 생성 | proto, API 정의, gRPC, 인터페이스 변경, 스키마 |
| buzzflow | ML 파이프라인 관리 — SageMaker 파이프라인, MLflow, Slack ChatOps | ML 파이프라인, SageMaker, 모델 학습, MLflow |

## 클라이언트/SDK (Client & SDK)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| buzzad | Django 기반 광고 SDK/플랫폼 — 광고 서빙 및 운영 관리 | SDK, 클라이언트 광고, buzzad, 광고 연동 |
| buzzscreen-api | BuzzScreen 잠금화면 광고 API | 버즈스크린, 잠금화면, BuzzScreen, 잠금화면 광고 |

## 기타 (Etc)

| 레포 | 설명 | 문의 키워드 |
|------|------|------------|
| weathersvc | 날씨 API (gRPC, AccuWeather) | 날씨, weather, 날씨 타게팅 |
| adnreportsvc | Ad Network 리포트 서비스 | 네트워크 리포트, ADN 리포트, 외부 매체 리포트 |

## 레포 선택 가이드

문의 내용에서 레포를 특정하기 어려울 때 참고:

1. **"광고가 안 나와요"** → biddersvc (입찰/매칭) → adpacingsvc (예산/패이싱) → adserver (광고 상태)
2. **"숫자가 이상해요"** → statssvc (통계 집계) → adtracker (이벤트 수집)
3. **"대시보드에서 에러"** → dash-api-gateway (API) → dash (UI) → statssvc (데이터)
4. **"포인트 관련"** → pointsvc (적립/차감) → postbacksvc (퍼블리셔 콜백) → extpointprovidersvc (외부 연동)
5. **"광고 설정/등록"** → adserver (엔티티 관리) → ads-center (셀프서빙 UI)
6. **"ML/추천 관련"** → adrecommender (모델 서빙) → buzzflow (파이프라인)
7. **"인증/권한"** → auth (인증) → nokta (계정 관리)
