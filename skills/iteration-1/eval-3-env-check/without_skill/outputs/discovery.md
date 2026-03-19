# CheeR93 프로젝트 탐색 결과

## 프로젝트 개요

**CheeR93**는 마라톤 실시간 응원 플랫폼이다. 주자의 위치를 실시간으로 추적하고, 응원자에게 주자 접근 알림을 전달하는 웹 애플리케이션.

- **프로젝트 경로**: `/Users/simon.lee/projects/cheer93/`
- **Git 커밋**: 3개 (초기 커밋 + 전체 구현 + gitignore 수정)
- **Git 리모트**: 설정되지 않음

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 프레임워크 | Next.js 15.5.12 (App Router) |
| 언어 | TypeScript 5.x |
| UI | React 19, Tailwind CSS 4, shadcn/ui (base-nova 스타일) |
| 폰트 | Pretendard Variable (로컬 woff2) |
| 지도 | Kakao Maps JavaScript SDK |
| 백엔드 | Supabase (Auth, Database, Realtime, Storage) |
| 알림 | Web Push (VAPID, web-push 라이브러리) |
| SMS | CoolSMS (미설정 상태) |
| Worker | 별도 Node.js 프로세스 (Fly.io 배포 대상, pnpm workspace) |
| 테스트 | Vitest 4 (단위), Playwright 1.58 (E2E) |
| 패키지매니저 | pnpm 10.32 |
| 배포 | Vercel (웹), Fly.io (워커), Supabase (DB) |

---

## 디렉토리 구조

```
cheer93/
├── src/
│   ├── app/
│   │   ├── page.tsx              # 랜딩 페이지
│   │   ├── layout.tsx            # 루트 레이아웃 (Pretendard, Toaster)
│   │   ├── login/page.tsx        # 카카오 OAuth 로그인
│   │   ├── auth/callback/route.ts # OAuth 콜백
│   │   ├── admin/                # 관리자 대시보드 (인증 필요)
│   │   │   ├── page.tsx          # 대회 목록
│   │   │   ├── races/new/        # 대회 생성
│   │   │   └── races/[raceId]/   # 대회 상세 + 대시보드
│   │   ├── race/[smartchipId]/   # 응원자 페이지 (인증 불필요)
│   │   │   ├── page.tsx          # 지도 + 실시간 추적
│   │   │   ├── SpectatorMapClient.tsx
│   │   │   ├── join/             # 주자 자가등록
│   │   │   └── readyshot/        # 레디샷 사진 등록
│   │   └── api/
│   │       ├── notifications/    # Web Push API
│   │       ├── positions/        # 위치 데이터 API
│   │       └── races/            # 대회 API
│   ├── components/
│   │   ├── ui/                   # shadcn/ui 컴포넌트
│   │   ├── map/                  # 카카오맵 관련 (KakaoMap, RunnerMarker, CheerMarker, KmMarker)
│   │   ├── race/                 # 레이스 관련 (RunnerInfo, ReadyShot)
│   │   ├── form/                 # 폼 컴포넌트 (LoginButton, CheerLocationForm)
│   │   ├── alert/                # 알림 컴포넌트
│   │   ├── cheer/                # 응원 관련
│   │   └── shared/               # 공통 컴포넌트
│   ├── hooks/
│   │   ├── useRealtimePositions.ts   # Supabase Realtime 위치 구독
│   │   ├── useMarkerInterpolation.ts # 마커 부드러운 이동
│   │   ├── useEtaCalculation.ts      # ETA 계산
│   │   └── useNotificationTrigger.ts # 알림 트리거
│   ├── lib/
│   │   ├── supabase/             # Supabase 클라이언트 (client, server, admin, middleware)
│   │   ├── gpx/                  # GPX 파서
│   │   ├── interpolation/        # 위치 보간 (polyline)
│   │   ├── kakao/                # 카카오맵 SDK 로더
│   │   ├── notifications/        # Web Push 발송
│   │   ├── course-snap.ts        # 코스 스냅
│   │   ├── image-resize.ts       # 이미지 리사이즈
│   │   ├── race.ts               # 레이스 데이터 로직
│   │   ├── runner.ts             # 러너 데이터 로직
│   │   └── storage.ts            # 스토리지 로직
│   ├── types/                    # 타입 정의
│   ├── constants/                # 상수
│   ├── middleware.ts             # /admin 인증 보호
│   └── __tests__/                # 단위 테스트
├── worker/                       # 위치 폴링 워커 (별도 프로세스)
│   ├── src/
│   │   ├── index.ts              # 엔트리 (30초 간격 폴링)
│   │   ├── poller.ts             # 폴링 로직
│   │   ├── broadcaster.ts        # Realtime 브로드캐스트
│   │   ├── split.ts              # Split 기록 생성
│   │   ├── interpolation.ts      # 위치 보간
│   │   └── adapters/             # Garmin, SmartChip 어댑터
│   ├── Dockerfile                # Node 20 Alpine
│   └── fly.toml                  # Fly.io (nrt 리전, 256MB)
├── supabase/
│   ├── config.toml               # 로컬 Supabase 설정
│   ├── migrations/               # 19개 마이그레이션 파일
│   └── seed.sql                  # 빈 시드 파일
├── scripts/
│   └── simulation/               # 시뮬레이션 스크립트
│       ├── generate.ts           # 데이터 생성 (대회+주자+응원자)
│       ├── runner.ts             # 실시간 위치 시뮬레이션
│       ├── generate-core.ts      # 핵심 생성 로직
│       └── interpolation.ts      # 보간 유틸
├── e2e/                          # Playwright E2E 테스트
│   ├── admin-flow.spec.ts
│   ├── cheer-alert.spec.ts
│   ├── race-finish.spec.ts
│   ├── spectator-map.spec.ts
│   └── split-records.spec.ts
├── public/
│   ├── sw.js                     # 서비스 워커 (PWA)
│   └── fonts/PretendardVariable.woff2
└── .github/workflows/
    ├── ci.yml                    # CI (lint + test + build)
    ├── deploy.yml                # 배포 (Vercel + Fly.io + Supabase)
    └── data-purge.yml            # 데이터 퍼지
```

---

## 데이터베이스 스키마

19개 마이그레이션으로 구성된 Supabase PostgreSQL 스키마:

| 테이블 | 설명 |
|--------|------|
| `profiles` | 사용자 프로필 |
| `races` | 마라톤 대회 (smartchip_id를 공유 코드로 사용) |
| `race_staff` | 대회 스태프 (관리자, 응원단장) |
| `runners` | 주자 (bib_number, 위치 동의, 데이터 소스) |
| `course_points` | 코스 좌표 (GPX에서 파싱) |
| `spectators` | 응원자 (세션 토큰, 응원 위치) |
| `tracking_positions` | 시계열 위치 데이터 |
| `runner_current_positions` | 주자 최신 위치 (UPSERT) |
| `split_records` | km별 구간 기록 |
| `push_subscriptions` | Web Push 구독 |
| `notification_logs` | 알림 발송 이력 |

추가로: triggers, indexes, RLS policies, 전화번호 복호화 RPC, Storage policies 마이그레이션 포함.

---

## 사용자 흐름 (시연 시나리오)

1. **관리자 흐름**: 카카오 OAuth 로그인 -> `/admin` 대회 생성 -> GPX 업로드 -> 주자 등록 -> 대회 시작 (live)
2. **응원자 흐름**: `/race/{smartchipId}` 공유 링크 접속 (비로그인) -> 지도에서 주자 실시간 추적 -> 응원 위치 설정 -> 접근 알림 수신
3. **시뮬레이션**: `scripts/simulation/generate.ts`로 데이터 생성 -> `scripts/simulation/runner.ts`로 실시간 재생

---

## 핵심 의존성 및 외부 서비스

| 서비스 | 용도 | 필수 여부 |
|--------|------|-----------|
| Supabase (Cloud) | Auth, DB, Realtime, Storage | 필수 |
| Kakao Maps JS SDK | 지도 렌더링 | 필수 (프론트엔드) |
| Web Push (VAPID) | 브라우저 알림 | 알림 기능에 필수 |
| CoolSMS | SMS 알림 | 선택 (P3 기능) |
| Fly.io | Worker 배포 | 프로덕션만 |
| Vercel | 웹 배포 | 프로덕션만 |
| Docker (Rancher Desktop) | Supabase 로컬 개발 | 로컬 개발 시 선택 |
