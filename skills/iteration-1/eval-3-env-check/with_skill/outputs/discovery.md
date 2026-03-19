# 프로젝트 분석: CheeR93

## 모드
**CONNECTED 모드** — `.claude/company/` 디렉토리 존재. simon-company 산출물(spec, prd, architecture, db-schema, story-map, contracts, tasks) 전체 활용 가능.

## 프로젝트 개요
마라톤 실시간 응원 플랫폼. 주자의 위치를 실시간으로 추적하고, 코스 위 응원자에게 주자 접근 알림(인앱/Web Push/SMS)을 전달한다.

### 사용자 역할
| 역할 | 설명 | 인증 |
|------|------|------|
| 관리자 | 대회 생성/관리 | 카카오 OAuth 필수 |
| 주자 | 대회 참가, 자가등록 | 로그인 필수 |
| 응원자 | 공유 링크로 접속, 실시간 추적 | 로그인 불필요 (익명) |

---

## 기동 방법
- **패키지 매니저**: pnpm (pnpm-lock.yaml 확인됨, v10.32.0)
- **모노레포**: pnpm-workspace.yaml — `worker/` 패키지 포함
- **기동 명령어**: `pnpm dev` (Next.js dev 서버)
- **빌드 명령어**: `pnpm build && pnpm start`
- **포트**: 3000 (기본)
- **의존 서비스**: Supabase (클라우드, https://uzfgjfvtabtvgmeshlhm.supabase.co)
- **Worker**: Fly.io 배포용 (`worker/` 디렉토리, tsx watch src/index.ts)
- **Node.js 버전**: .nvmrc/.node-version 없음, Dockerfile에서 node:20-alpine 사용
- **현재 Node.js**: v25.5.0 (Dockerfile과 불일치 — 20 vs 25)

### 필수 환경 변수
| 변수 | 용도 | 설정 상태 |
|------|------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase 프로젝트 URL | ✅ 설정됨 |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase 익명 키 | ✅ 설정됨 |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase 서비스 역할 키 | ✅ 설정됨 |
| `SUPABASE_DB_PASSWORD` | Supabase DB 비밀번호 | ✅ 설정됨 (.env.local.example에 없는 추가 변수) |
| `NEXT_PUBLIC_KAKAO_MAP_KEY` | Kakao Maps JavaScript SDK 키 | ✅ 설정됨 |
| `VAPID_PUBLIC_KEY` | Web Push VAPID 공개키 | ✅ 설정됨 |
| `VAPID_PRIVATE_KEY` | Web Push VAPID 비밀키 | ✅ 설정됨 |
| `VAPID_SUBJECT` | Web Push VAPID 제목 | ✅ 설정됨 |
| `NEXT_PUBLIC_VAPID_PUBLIC_KEY` | 클라이언트 VAPID 공개키 | ✅ 설정됨 |
| `COOLSMS_API_KEY` | CoolSMS API 키 | ❌ 미설정 (빈 값) |
| `COOLSMS_API_SECRET` | CoolSMS API 시크릿 | ❌ 미설정 (빈 값) |
| `COOLSMS_SENDER_NUMBER` | CoolSMS 발신 번호 | ❌ 미설정 (빈 값) |
| `ENCRYPTION_KEY` | 전화번호 암호화 키 (pgcrypto) | ✅ 설정됨 |

---

## 라우트 맵

| URL | 페이지/파일 | 인증 필요 | 비고 |
|-----|-----------|----------|------|
| `/` | `src/app/page.tsx` | 아니오 | 랜딩 페이지 (관리자 로그인 링크) |
| `/login` | `src/app/login/page.tsx` | 아니오 | 카카오 OAuth 로그인 |
| `/auth/callback` | `src/app/auth/callback/route.ts` | 아니오 | OAuth 콜백 라우트 |
| `/admin` | `src/app/admin/page.tsx` | 예 (미들웨어) | 대회 목록 (관리자) |
| `/admin/races/new` | `src/app/admin/races/new/page.tsx` | 예 | 대회 생성 |
| `/admin/races/[raceId]` | `src/app/admin/races/[raceId]/page.tsx` | 예 | 대회 상세/관리 |
| `/admin/races/[raceId]/dashboard` | `src/app/admin/races/[raceId]/dashboard/page.tsx` | 예 | 관리자 대시보드 |
| `/race/[smartchipId]` | `src/app/race/[smartchipId]/page.tsx` | 아니오 | 응원자 지도 (익명 접근) |
| `/race/[smartchipId]/join` | `src/app/race/[smartchipId]/join/page.tsx` | 예 | 주자 자가등록 |
| `/race/[smartchipId]/readyshot` | `src/app/race/[smartchipId]/readyshot/page.tsx` | 예 | 레디샷 사진 등록 |

### 미들웨어
`src/middleware.ts` → `/admin` 경로 접근 시 로그인 여부 확인, 미로그인이면 `/login`으로 리다이렉트.

---

## 인증
- **방식**: Supabase Auth + 카카오 OAuth
- **로그인 페이지**: `/login` — `LoginButton` 컴포넌트 (카카오 로그인 버튼)
- **콜백**: `/auth/callback` — 코드 교환 후 `/admin`으로 리다이렉트
- **미들웨어**: `src/lib/supabase/middleware.ts` — `createServerClient`로 세션 관리
- **테스트 계정**: seed.sql 비어있음 — 별도 시드 계정 없음
- **응원자 인증**: 불필요 (익명 세션, `x-session-token` 헤더)
- **역할**: 관리자 (race_staff), 주자, 응원자 (익명)

---

## API 엔드포인트

| 메서드 | 경로 | 설명 | 모킹 필요 |
|--------|------|------|----------|
| POST | `/api/races/[raceId]/gpx` | GPX 파일 업로드/파싱 | 아니오 |
| GET | `/api/positions` | 주자 현재 위치 조회 | 아니오 |
| POST | `/api/notifications/push` | Web Push 알림 발송 | 아니오 (VAPID 키 있음) |
| POST | `/api/notifications/sms` | SMS 문자 알림 발송 | 예 (CoolSMS 키 없음) |

### Server Actions
- `src/app/admin/actions/race.ts` — 대회 관련 서버 액션
- `src/app/race/[smartchipId]/join/actions.ts` — 주자 등록 액션
- `src/app/race/[smartchipId]/readyshot/actions.ts` — 레디샷 업로드 액션

---

## DB 스키마 요약

Supabase PostgreSQL (클라우드). 19개 마이그레이션 파일.

### 핵심 테이블
| 테이블 | 역할 |
|--------|------|
| `profiles` | 사용자 프로필 (auth.users 확장) |
| `races` | 대회 정보 (name, date, smartchip_id, status) |
| `race_staff` | 대회별 관리자 |
| `runners` | 주자 (bib_number, garmin_url, location_consent) |
| `course_points` | GPX 코스 보간 지점 |
| `tracking_positions` | 주자 위치 시계열 (30초 간격) |
| `runner_current_positions` | 최신 위치 (UPSERT) |
| `split_records` | km별 구간 기록 |
| `spectators` | 익명 응원자 |
| `push_subscriptions` | Web Push 구독 |
| `notification_logs` | 알림 전송 이력 |

**시드 데이터**: `supabase/seed.sql` — 비어있음. 시연용 데이터 별도 준비 필요.

---

## 핵심 셀렉터 (E2E 테스트 기반)

E2E 테스트 파일 5개 존재:
- `e2e/admin-flow.spec.ts`
- `e2e/cheer-alert.spec.ts`
- `e2e/race-finish.spec.ts`
- `e2e/spectator-map.spec.ts`
- `e2e/split-records.spec.ts`

테스트 fixture:
- `e2e/fixtures/auth.ts` — 인증 fixture
- `e2e/fixtures/test-helpers.ts` — 테스트 헬퍼

### 주요 UI 요소
| 요소 | 셀렉터 (추정) | 페이지 |
|------|-------------|--------|
| 카카오 로그인 버튼 | `LoginButton` 컴포넌트 | `/login` |
| 지도 컨테이너 | `[data-testid="kakao-map"]` | `/race/[id]` |
| 코스 폴리라인 | `CoursePolyline` 컴포넌트 | `/race/[id]` |
| 주자 마커 | `RunnerMarker` 컴포넌트 | `/race/[id]` |
| 응원 마커 | `CheerMarker` 컴포넌트 | `/race/[id]` |
| km 마커 | `KmMarker` 컴포넌트 | `/race/[id]` |
| 마커 클러스터 | `MarkerCluster` 컴포넌트 | `/race/[id]` |
| 대회 상세 | `CourseSection`, `RaceStatusControlWrapper` | `/admin/races/[id]` |
| 대시보드 | `DashboardClient`, `StatCard` | `/admin/races/[id]/dashboard` |

---

## 컴포넌트 구조

```
src/components/
├── alert/          — 알림 관련 컴포넌트
├── cheer/          — 응원 관련
├── form/           — 폼 컴포넌트 (LoginButton, CheerLocationForm 등)
├── map/            — 지도 컴포넌트 (KakaoMap, CoursePolyline, RunnerMarker, CheerMarker, KmMarker, MarkerCluster)
├── race/           — 대회 관련 컴포넌트
├── shared/         — 공유 컴포넌트
└── ui/             — shadcn/ui 컴포넌트
```

---

## Worker (Fly.io)

- **경로**: `worker/`
- **역할**: 위치 데이터 수집 (30초 폴링)
- **구조**:
  - `src/index.ts` — 진입점
  - `src/poller.ts` — 폴링 로직
  - `src/broadcaster.ts` — Realtime 브로드캐스트
  - `src/split.ts` — 구간 기록
  - `src/interpolation.ts` — 위치 보간
  - `src/adapters/` — Garmin/SmartChip 어댑터
- **환경 변수**: worker/.env 파일 없음 (Fly.io secrets로 관리 추정)
- **로컬 실행**: `pnpm --filter cheer93-worker dev` (tsx watch)

---

## 시뮬레이션

- **경로**: `scripts/simulation/`
- **파일**: `generate-core.ts`, `generate.ts`, `runner.ts`, `interpolation.ts`
- **용도**: 테스트/시연용 시뮬레이션 데이터 생성
- **GPX 코스**: `supabase/seed-course.gpx` (시드 코스 데이터 존재)

---

## 모킹 대상

| 항목 | 이유 | 우선순위 |
|------|------|---------|
| CoolSMS API | API 키 미설정 | 필수 모킹 (SMS 시나리오 시연 시) |
| 카카오 OAuth | 실제 OAuth 흐름은 시연에서 복잡 | 선택 (bypass 또는 직접 로그인) |
| Garmin LiveTrack API | 외부 비공식 API | 시뮬레이션으로 대체 |
| SmartChip 크롤링 | 외부 서비스 | 시뮬레이션으로 대체 |

---

## 외부 서비스 의존성

| 서비스 | 용도 | 상태 |
|--------|------|------|
| Supabase (클라우드) | Auth, DB, Realtime, Storage | ✅ REST/Auth 접속 정상 |
| Kakao Maps SDK | 지도 렌더링 | ✅ JavaScript SDK 키 설정됨 |
| Fly.io Worker | 위치 수집 | ⚠️ 로컬 실행 필요 |
| CoolSMS | SMS 알림 | ❌ API 키 미설정 |
| VAPID Web Push | 브라우저 알림 | ✅ 키 설정됨 |

---

## 기술 스택

| 분류 | 기술 | 버전 |
|------|------|------|
| 프레임워크 | Next.js (App Router) | 15.5.12 |
| UI | React | 19.x |
| 언어 | TypeScript | 5.x |
| 스타일링 | Tailwind CSS | 4.x |
| UI 라이브러리 | shadcn/ui | 4.0.2 |
| BaaS | Supabase (Auth, DB, Realtime, Storage) | 2.99.0 |
| 지도 | Kakao Maps JavaScript SDK v3 | - |
| 폰트 | Pretendard | 1.3.9 |
| 토스트 | Sonner | 2.0.7 |
| 테스트 | Vitest + Playwright | 4.0.18 / 1.58.2 |
| 패키지 매니저 | pnpm | 10.32.0 |
