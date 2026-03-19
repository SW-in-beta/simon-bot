# 프로젝트 분석: CheeR93 — 마라톤 실시간 응원 플랫폼

**모드**: CONNECTED (`.claude/company/` 산출물 활용)

---

## 기동 방법

- **패키지 매니저**: pnpm (pnpm-lock.yaml 확인)
- **기동 명령어**: `pnpm run dev` (개발) / `pnpm run build && pnpm start` (프로덕션)
- **포트**: 3000 (Next.js 기본)
- **의존 서비스**: Supabase (클라우드 — uzfgjfvtabtvgmeshlhm.supabase.co), Fly.io Worker (위치 수집)
- **모노레포**: pnpm workspace (루트 + `worker/`)
- **필수 환경 변수**:
  | 변수 | 상태 | 용도 |
  |------|------|------|
  | `NEXT_PUBLIC_SUPABASE_URL` | 설정됨 | Supabase 접속 |
  | `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 설정됨 | Supabase 클라이언트 |
  | `SUPABASE_SERVICE_ROLE_KEY` | 설정됨 | Supabase 서버(admin) |
  | `NEXT_PUBLIC_KAKAO_MAP_KEY` | 설정됨 | 카카오맵 |
  | `VAPID_PUBLIC_KEY` / `VAPID_PRIVATE_KEY` | 설정됨 | Web Push |
  | `NEXT_PUBLIC_VAPID_PUBLIC_KEY` | 설정됨 | Web Push (클라이언트) |
  | `VAPID_SUBJECT` | 설정됨 | Web Push |
  | `COOLSMS_API_KEY` | **미설정** | SMS 알림 |
  | `COOLSMS_API_SECRET` | **미설정** | SMS 알림 |
  | `COOLSMS_SENDER_NUMBER` | **미설정** | SMS 알림 |
  | `ENCRYPTION_KEY` | 설정됨 | 전화번호 암호화 |

  **CoolSMS 키 미설정**: SMS 알림 시나리오는 모킹 필요 또는 제외 대상.

---

## 라우트 맵

| URL | 페이지 | 인증 필요 | 비고 |
|-----|--------|----------|------|
| `/` | 랜딩 페이지 | 아니오 | "관리자 로그인" 버튼만 있음 |
| `/login` | 로그인 페이지 | 아니오 | 카카오 OAuth, 이미 로그인 시 `/admin`으로 리다이렉트 |
| `/auth/callback` | OAuth 콜백 | 아니오 | 카카오 인증 후 리다이렉트 처리 |
| `/admin` | 대회 목록 (관리자) | 예 | `getRaces()` — race_staff 기반 필터 |
| `/admin/races/new` | 대회 생성 | 예 | RaceForm (대회명, 날짜, SmartChip ID) |
| `/admin/races/[raceId]` | 대회 상세/관리 | 예 | GPX 업로드, 상태 변경, 주자 목록 |
| `/admin/races/[raceId]/dashboard` | 관리자 대시보드 | 예 (staff) | 실시간 통계 (P2) |
| `/race/[smartchipId]` | 응원자 지도 | 아니오 | 핵심 화면 — 코스 Polyline + 주자 마커 + 실시간 추적 |
| `/race/[smartchipId]/join` | 주자 자가등록 | 예 | 배번, Garmin URL, 위치 동의 |
| `/race/[smartchipId]/readyshot` | 레디샷 사진 등록 | 예 | 주자 사진 업로드 (P3) |

---

## 인증

- **방식**: Supabase Auth + 카카오 OAuth
- **로그인 플로우**: `LoginButton` → `supabase.auth.signInWithOAuth({ provider: 'kakao' })` → `/auth/callback` → `exchangeCodeForSession(code)` → `/admin` 리다이렉트
- **테스트 계정**: 시뮬레이션 스크립트가 `runner{BIB}@simulation.local` 계정을 자동 생성함 (비밀번호: `simulation-password-123`)
- **역할**: 관리자(race_staff owner/admin), 주자(runners), 응원자(spectators — 익명 세션 토큰)
- **시연용**: 카카오 OAuth 실제 로그인 필요. 또는 시뮬레이션 스크립트가 데이터를 직접 삽입하므로, 응원자 화면(`/race/[smartchipId]`)은 로그인 없이 접근 가능

---

## 핵심 셀렉터

| 요소 | 셀렉터 | 페이지 |
|------|--------|--------|
| 카카오 로그인 버튼 | `button[aria-label="카카오 계정으로 로그인"]` | `/login` |
| 대회명 입력 | `#race-name` | `/admin/races/new` |
| 대회 날짜 입력 | `#race-date` | `/admin/races/new` |
| SmartChip ID 입력 | `#smartchip-id` | `/admin/races/new` |
| 대회 생성 버튼 | `button[type="submit"]` (텍스트: "대회 생성") | `/admin/races/new` |
| GPX 업로드 영역 | `.cursor-pointer` (드래그앤드롭) | `/admin/races/[raceId]` |
| 상태 변경 버튼 | 텍스트: "대회 시작 (Live)" / "대회 종료" | `/admin/races/[raceId]` |
| 확인 다이얼로그 | `AlertDialogAction` (텍스트: "확인") | 대회 상태 변경 시 |
| 카카오맵 컨테이너 | `[data-testid="kakao-map"]` | `/race/[smartchipId]` |
| BottomSheet | `[data-testid="bottom-sheet"]` | `/race/[smartchipId]` |
| 주자 마커 | `[data-testid="runner-marker-{id}"]` | `/race/[smartchipId]` |
| 새로고침 버튼 | `button[aria-label="새로고침"]` | `/race/[smartchipId]` |
| 연결 상태 | `[role="alert"]` (텍스트: "재연결 중..." / "실시간 모드 비활성화") | `/race/[smartchipId]` |
| 알림 배너 | `[data-testid="alert-banner"]` | `/race/[smartchipId]` |
| 알림 컨테이너 | `[data-testid="approach-alert-container"]` | `/race/[smartchipId]` |
| 알림 닫기 | `button[aria-label="알림 닫기"]` | 알림 배너 내 |
| 배번 입력 | `#bib-number` | `/race/[smartchipId]/join` |
| Garmin URL 입력 | `#garmin-url` | `/race/[smartchipId]/join` |
| 위치 동의 체크박스 | `#location-consent` | `/race/[smartchipId]/join` |
| 등록 버튼 | `button[type="submit"]` (텍스트: "등록") | `/race/[smartchipId]/join` |
| GPS 자동감지 탭 | `TabsTrigger` (텍스트: "GPS 자동감지") | 응원 위치 설정 |
| km 수동입력 탭 | `TabsTrigger` (텍스트: "km 수동입력") | 응원 위치 설정 |
| km 입력 필드 | `#km-input` | 응원 위치 설정 |
| 닉네임 입력 | `#nickname-input` | 응원 위치 설정 |
| 대시보드 통계 카드 | `[role="region"][aria-label="실시간 통계"]` | `/admin/races/[raceId]/dashboard` |

---

## API 엔드포인트

| 메서드 | 경로 | 설명 | 모킹 필요 |
|--------|------|------|----------|
| GET | `/api/positions?raceId={uuid}` | 주자 현재 위치 일괄 조회 (수동 새로고침) | 아니오 |
| POST | `/api/races/[raceId]/gpx` | GPX 파일 업로드 + 파싱 + course_points 저장 | 아니오 |
| POST | `/api/notifications/push` | Web Push 알림 발송 | 아니오 (VAPID 키 있음) |
| POST | `/api/notifications/sms` | SMS 문자 알림 발송 | **예** (CoolSMS 키 미설정) |
| WS | Supabase Realtime `race:{raceId}` 채널 | 실시간 위치/split/상태 브로드캐스트 | 아니오 |

### Supabase Realtime 이벤트
| 이벤트 | 채널 | 페이로드 | 발신자 |
|--------|------|---------|--------|
| `position_update` | `race:{raceId}` | `{ runners: [{ runnerId, lat, lng, currentKm, currentPace, confidence, source, timestamp }] }` | Worker / 시뮬레이션 |
| `split_update` | `race:{raceId}` | `{ runnerId, km, splitTime, splitPace, cumulativeTime }` | Worker / 시뮬레이션 |
| `race_status_change` | `race:{raceId}` | `{ raceId, status }` | 관리자 액션 |

---

## DB 스키마 요약

### 핵심 테이블과 관계

```
profiles (auth.users 확장, PK: id)
  └──< race_staff (FK: user_id, race_id) >── races
  └──< runners (FK: user_id, race_id) >── races

races (PK: id)
  ├──< course_points (FK: race_id) — GPX 파싱 보간 지점
  ├──< spectators (FK: race_id) — 익명 응원자
  ├──< runners (FK: race_id) — 참가 주자
  └──< race_staff (FK: race_id) — 관리자

runners (PK: id)
  ├──< tracking_positions (FK: runner_id) — 위치 시계열
  ├──< runner_current_positions (FK: runner_id) — 최신 위치 UPSERT
  ├──< split_records (FK: runner_id) — km별 구간 기록
  └──< notification_logs (FK: runner_id)

spectators (PK: id)
  ├──< push_subscriptions (FK: spectator_id)
  └──< notification_logs (FK: spectator_id)
```

### 주요 필드

**races**: `id`, `name`, `race_date`, `smartchip_id` (UNIQUE), `status` (scheduled/live/finished), `total_distance_km`, `course_gpx_url`, `started_at`

**runners**: `id`, `race_id`, `user_id`, `bib_number`, `garmin_livetrack_url`, `location_consent`, `data_source` (garmin/smartchip), `status` (registered/running/finished/dnf), `ready_shot_url`

**runner_current_positions**: `runner_id` (PK/FK), `race_id`, `lat`, `lng`, `current_pace`, `current_km`, `confidence` (high/medium/low)

**spectators**: `id`, `race_id`, `session_token`, `nickname`, `cheer_lat`, `cheer_lng`, `cheer_km`, `phone_encrypted`, `phone_consent`

**course_points**: `id`, `race_id`, `lat`, `lng`, `km`, `cumulative_distance`, `seq`

### 시드 데이터 삽입 순서
1. races
2. course_points (race_id 참조)
3. profiles + auth.users (시뮬레이션 스크립트가 admin API로 생성)
4. race_staff (race_id + user_id)
5. runners (race_id + user_id)
6. spectators (race_id)
7. runner_current_positions (runner_id + race_id)
8. tracking_positions / split_records (시뮬레이션 실행 시 동적 생성)

---

## 모킹 대상

| 항목 | 이유 | 모킹 방법 |
|------|------|-----------|
| CoolSMS API | API 키 미설정 | SMS 시나리오 제외 또는 `/api/notifications/sms` 목 응답 |
| 카카오 OAuth | 실제 카카오 계정 필요 | 시뮬레이션 스크립트가 Supabase Admin API로 사용자 직접 생성하므로, 관리자 화면은 실제 로그인 필요. 응원자 화면은 로그인 불필요 |
| Garmin LiveTrack API | 실제 Garmin 데이터 없음 | 시뮬레이션 스크립트가 DB에 직접 데이터 삽입 + Broadcast |
| SmartChip 크롤링 | 실제 대회 데이터 없음 | 시뮬레이션 스크립트가 DB에 직접 데이터 삽입 + Broadcast |

### 시뮬레이션 스크립트 (핵심 도구)

이 프로젝트는 `scripts/simulation/` 에 완전한 시뮬레이션 시스템이 구축되어 있다:

1. **`generate.ts`**: 시뮬레이션 데이터 생성
   - GPX 파일로 대회 + 코스 + 5명 주자 + 3명 응원자 생성
   - 주자별 페이스: 4'00"/km ~ 6'00"/km
   - 응원자 위치: 1km, 3km, 5km 지점
   - 데이터를 `data.json`에 저장
   - 명령어: `npx tsx scripts/simulation/generate.ts --gpx supabase/seed-course.gpx`

2. **`runner.ts`**: 실시간 위치 시뮬레이션 실행
   - 30초 간격으로 위치 DB INSERT + Realtime Broadcast
   - 속도 조절 가능 (1x, 10x, 60x)
   - split 기록 자동 생성 + broadcast
   - 완주 처리 자동
   - 명령어: `npx tsx scripts/simulation/runner.ts --speed 10`

3. **시드 GPX**: `supabase/seed-course.gpx` (약 4KB, 테스트용 코스)

---

## 기술 스택 상세

- **프레임워크**: Next.js 15.5 (App Router) + React 19 + TypeScript 5
- **스타일링**: Tailwind CSS 4 + shadcn/ui + Pretendard 폰트
- **BaaS**: Supabase (Auth, PostgreSQL, Realtime Broadcast, Storage)
- **지도**: Kakao Maps API v3 (글로벌 스크립트 로딩, `window.kakao.maps`)
- **테스트**: Vitest (단위) + Playwright (E2E)
- **알림**: Web Push (VAPID) + CoolSMS (SMS) + 인앱 배너
- **Worker**: Fly.io Node.js 프로세스 (30초 폴링)
- **Toast**: Sonner

---

## 유저스토리별 코드 플로우 추적

### 플로우 1: US-1.1 "카카오 OAuth 로그인"

#### 사용자 동작 경로
`/` → "관리자 로그인" 클릭 → `/login` → "카카오 로그인" 클릭 → 카카오 OAuth → `/auth/callback` → `/admin`

#### 코드 실행 흐름
1. **[UI]** `src/app/page.tsx` — Link href="/login"
2. **[UI]** `src/app/login/page.tsx` — 서버 컴포넌트, 이미 로그인 시 redirect('/admin')
3. **[UI]** `src/components/form/LoginButton.tsx:15` — `handleLogin()` → `supabase.auth.signInWithOAuth({ provider: 'kakao', redirectTo: '/auth/callback' })`
4. **[외부]** 카카오 OAuth 인증 → code 파라미터로 콜백
5. **[API]** `src/app/auth/callback/route.ts:4` — `supabase.auth.exchangeCodeForSession(code)` → 성공 시 `/admin`으로 리다이렉트
6. **[DB]** Supabase Auth가 자동으로 auth.users + profiles 트리거 (`00013_triggers.sql`)

#### 시연을 위한 사전 데이터
- 카카오 개발자 앱 설정 (Supabase Auth에 카카오 provider 연동 필수)
- 시연자의 카카오 계정

#### 핵심 관찰 포인트
- 카카오 노란색 로그인 버튼 (FEE500 배경)
- OAuth 리다이렉트 후 `/admin` 자동 이동
- Loader2 스피너 애니메이션

---

### 플로우 2: US-2.1+2.3 "대회 생성 + GPX 업로드"

#### 사용자 동작 경로
`/admin` → "새 대회 만들기" → `/admin/races/new` → 폼 입력 → 제출 → `/admin/races/[raceId]` → GPX 업로드 → 지도 미리보기

#### 코드 실행 흐름
1. **[UI]** `src/app/admin/page.tsx` — Link href="/admin/races/new"
2. **[UI]** `src/app/admin/races/new/page.tsx` → `RaceForm` 컴포넌트
3. **[UI]** `src/components/form/RaceForm.tsx:72` — `handleSubmit()` → 클라이언트 유효성 검사 (필수값, SmartChip ID 숫자만)
4. **[API]** `src/app/admin/actions/race.ts` → `createRaceAction()` → `lib/race.ts:createRace()`
5. **[DB]** races INSERT + race_staff INSERT (owner 역할)
6. **[UI]** 성공 시 `router.push(/admin/races/${result.data.id})`
7. **[UI]** 대회 상세 페이지 — `CourseSection` → `GpxUploader` 표시
8. **[UI]** `src/components/form/GpxUploader.tsx` — 파일 드래그앤드롭 또는 클릭
9. **[API]** POST `/api/races/[raceId]/gpx` — FormData로 GPX 파일 전송
10. **[서버]** `src/app/api/races/[raceId]/gpx/route.ts` — GPX 파싱 (`lib/gpx/parser.ts`) → course_points INSERT → races UPDATE (total_distance_km, course_gpx_url)
11. **[UI]** `window.location.reload()` → `CoursePreview` 컴포넌트로 전환 → 카카오맵에 Polyline + KmMarker 표시

#### 시연을 위한 사전 데이터
- 로그인된 관리자 계정
- `supabase/seed-course.gpx` 파일 (또는 실제 마라톤 GPX)

#### 핵심 관찰 포인트
- 폼 유효성 검사 에러 메시지 (빈 필드, 비숫자 SmartChip ID)
- GPX 드래그앤드롭 UI
- 업로드 완료 후 지도에 코스 선 + 5km 간격 마커 표시
- "업로드 완료" 상태 (총 거리 km + 포인트 수)

---

### 플로우 3: US-2.4 "대회 상태 변경 (scheduled → live)"

#### 사용자 동작 경로
`/admin/races/[raceId]` → "대회 시작 (Live)" 클릭 → 확인 다이얼로그 → "확인" → 상태 변경

#### 코드 실행 흐름
1. **[UI]** `RaceStatusControlWrapper.tsx` → `RaceStatusControl.tsx`
2. **[UI]** `RaceStatusControl.tsx:64` — AlertDialog 트리거 → "정말 대회를 시작하시겠습니까?"
3. **[UI]** "확인" 클릭 → `handleConfirm()` → `updateRaceStatusAction(raceId, 'live')`
4. **[API]** `lib/race.ts:updateRaceStatus()` — race_staff 권한 확인 → 상태 전이 유효성 (scheduled→live만 허용) → races UPDATE
5. **[DB]** races.status = 'live', started_at = now()
6. **[UI]** `router.refresh()` → Badge가 "예정"(outline)에서 "진행 중"(빨간색 #E53E3E)으로 변경

#### 핵심 관찰 포인트
- AlertDialog 확인 UX (실수 방지)
- Badge 색상 즉시 변경 (회색 → 빨간색)
- 이 시점부터 Worker가 폴링 시작 (또는 시뮬레이션이 데이터 전송 시작)

---

### 플로우 4: US-3.1 "주자 자가 등록"

#### 사용자 동작 경로
공유 링크 `/race/{smartchipId}/join` → 로그인 → 배번/Garmin URL/위치 동의 입력 → "등록"

#### 코드 실행 흐름
1. **[UI]** `src/app/race/[smartchipId]/join/page.tsx` — 서버 컴포넌트
   - 비로그인: LoginButton 표시
   - 이미 등록: "이미 등록되었습니다" 표시
   - 미등록: RunnerRegForm 표시
2. **[UI]** `RunnerRegForm.tsx:63` — `handleSubmit()` → 유효성 검사 (배번 필수)
3. **[API]** `join/actions.ts` → `registerRunnerAction()` → `lib/runner.ts:registerRunner()`
4. **[DB]** runners INSERT — data_source = garmin(URL있으면) / smartchip(없으면)
5. **[UI]** 성공 시 "등록이 완료되었습니다" 녹색 텍스트

#### 시연을 위한 사전 데이터
- 생성된 대회의 smartchipId
- 로그인된 사용자

#### 핵심 관찰 포인트
- 위치 동의 체크박스 미체크 시 등록 버튼 비활성화
- Garmin URL은 선택사항
- 배번 중복 시 에러 메시지

---

### 플로우 5: US-5.1+5.2 "응원자 공유 링크 접속 + 지도 실시간 추적" (핵심 시나리오)

#### 사용자 동작 경로
`/race/{smartchipId}` → 지도 로딩 → 코스 선 + 주자 마커 표시 → 실시간 위치 갱신

#### 코드 실행 흐름
1. **[UI]** `src/app/race/[smartchipId]/page.tsx` — 서버 컴포넌트
   - `getRaceBySmartchipId(smartchipId)` → 대회 정보
   - `supabase.from('course_points')` → 코스 좌표
   - `supabase.from('runners').select('*, profiles(display_name)')` → 주자 목록 (location_consent=true만)
   - 5km 간격 KM 마커 계산
2. **[UI]** `SpectatorMapClient.tsx` — 클라이언트 컴포넌트 (핵심)
   - `useRealtimePositions(race.id)` → Supabase Realtime 구독
   - `useMarkerInterpolation(positions)` → requestAnimationFrame + lerp 보간 (2초 부드러운 이동)
   - 익명 세션 토큰 생성 → spectators UPSERT
3. **[Realtime]** `useRealtimePositions.ts:86`
   - `supabase.channel('race:{raceId}')` 구독
   - `position_update` → positions Map 갱신
   - `split_update` → splits Map 갱신
   - `race_status_change` → raceStatus 갱신
   - 연결 상태: connected/connecting/disconnected
4. **[UI]** 지도 렌더링
   - `KakaoMap` → 카카오맵 SDK 로딩 + 맵 초기화
   - `CoursePolyline` → `kakao.maps.Polyline` (녹색 #1B4D3E, opacity 0.7)
   - `KmMarker` → 5km 간격 마커
   - `RunnerMarker` → `kakao.maps.CustomOverlay` + React Portal
     - high 신뢰도: 녹색 실선 (#1B4D3E), 배번 + 이름 + 페이스
     - medium: 반투명 (0.5), 점선 테두리
     - low: 회색 텍스트 "마지막 확인: Xkm (Y분 전)"
5. **[UI]** BottomSheet — 스냅포인트 80px/40vh/85vh, 터치 드래그
   - `RaceStatus` — Badge(진행 중) + 전체/활주/완주 카운트
   - `RunnerList` — 주자별 배번(원형 뱃지) + 이름 + 현재km + 페이스

#### 수동 새로고침 플로우
- FloatingButton(새로고침) 클릭 → `handleRefresh()` → 5초 쓰로틀 → `useRealtimePositions.refresh()` → `runner_current_positions` SELECT

#### 시연을 위한 사전 데이터
- live 상태의 대회 + GPX 코스 + 주자 등록 완료
- 시뮬레이션 스크립트 실행 중 (위치 데이터 지속 전송)

#### 핵심 관찰 포인트
- **카카오맵에 코스 폴리라인 표시** (녹색 선)
- **주자 마커가 지도 위에서 부드럽게 이동** (lerp 보간)
- **30초마다 주자 위치 업데이트** (시뮬레이션 속도에 따라 가속)
- **BottomSheet 스와이프** (80px → 40vh → 85vh)
- **주자 클릭 시 지도 센터링** + 줌 레벨 3
- **주자별 실시간 페이스 표시** (예: 5'30"/km)
- **ConnectionStatus 배너** (연결 상태)
- **5km 마커** 코스 위에 표시

---

### 플로우 6: US-5.3+5.4 "응원 위치 설정 + 주자 접근 알림"

#### 사용자 동작 경로
응원 위치 설정 (GPS 감지 또는 km 수동 입력) → 주자 접근 시 알림 배너 표시

#### 코드 실행 흐름
1. **[UI]** `CheerLocationForm.tsx` — Tabs (GPS 자동감지 / km 수동입력)
   - GPS: `navigator.geolocation.getCurrentPosition()` → `snapToCourse()` (가장 가까운 코스 포인트)
   - 수동: km 입력 → `findClosestByKm()` → 가장 가까운 coursePoint
2. **[DB]** spectators UPDATE (cheer_lat, cheer_lng, cheer_km, nickname)
3. **[Hook]** `useEtaCalculation(positions, cheerKm)` — 각 주자별 ETA 계산
   - `etaSeconds = (cheerKm - currentKm) * currentPace`
   - status: approaching(ETA 있음) / passed(이미 지남) / waiting(데이터 없음)
   - isEstimated: smartchip 소스면 true
4. **[Hook]** `useNotificationTrigger(etas, runners)` — ETA ≤ 180초(3분)이면 알림 발동
   - 30초 쓰로틀 (같은 주자 중복 방지)
   - `activeAlerts` 배열에 추가
   - `onNotification` 콜백 호출
5. **[UI]** `ApproachAlert` → `AlertBanner` 컴포넌트
   - 주자 이름 + "약 N분 후 도착 예정"
   - SmartChip 소스면 "추정" 노란 뱃지
   - ReadyShot 사진 (등록된 경우)
   - 5초 후 자동 최소화 (MiniBadge)
   - 클릭 시 해당 주자 위치로 지도 이동

#### 핵심 관찰 포인트
- **알림 배너 슬라이드-인 애니메이션** (translate-y-0 transition)
- **"약 2분 후 도착 예정"** 실시간 ETA
- **"추정" 노란 뱃지** (SmartChip 데이터 소스)
- **5초 후 자동 최소화** → 우측 상단 MiniBadge
- **최대 3개 배너** + overflow 카운트
- **알림 탭 시 지도 이동**

---

### 플로우 7: US-4.4 "구간 기록 (Split)"

#### 코드 실행 흐름
1. **[Worker]** `worker/src/poller.ts:98` — `processSplits()`
   - 이전 km vs 현재 km 비교 → `detectSplits()`
2. **[Worker]** `worker/src/split.ts:20` — `detectSplits()`
   - 정수 km 경계 교차 탐지 (1km, 2km, ...)
   - 선형 보간으로 정확한 통과 시간 추정
   - split_time, split_pace, cumulative_time 산출
3. **[DB]** split_records INSERT
4. **[Realtime]** `split_update` Broadcast → 클라이언트 splits Map 갱신

#### 시뮬레이션에서의 처리
- `runner.ts` 가 직접 split 감지 + DB INSERT + Broadcast 수행
- 콘솔에 `[101] 1km 통과 - 구간: 00:04:00, 누적: 00:04:00` 출력

---

### 플로우 8: US-6.2 "관리자 대시보드"

#### 사용자 동작 경로
`/admin/races/[raceId]/dashboard`

#### 코드 실행 흐름
1. **[서버]** `dashboard/page.tsx` — 인증 + staff 권한 확인
2. **[UI]** `DashboardClient.tsx` — `useRealtimePositions(race.id)` 구독
3. **[UI]** 6개 StatCard 실시간 갱신:
   - 활주 중 (Activity 아이콘)
   - 완주 (Award 아이콘)
   - DNF (AlertTriangle 아이콘)
   - 평균 페이스 (Timer 아이콘) — `formatPace(avgPace)`
   - Garmin 주자 수 (Watch 아이콘)
   - SmartChip 주자 수 (Cpu 아이콘)

---

## 디자인 특징

### 색상 체계
- **Primary**: hsl(153 36% 21%) — 진한 녹색 (#1B4D3E), 주자 마커/코스선/브랜드
- **Accent**: hsl(19 100% 60%) — 오렌지, 접근 중 주자 마커/응원 마커
- **Secondary**: hsl(215 19% 25%) — 진한 남색
- **Live**: hsl(0 72% 57%) — 빨간색 (#E53E3E), 라이브 상태 뱃지
- **Success**: hsl(145 45% 43%) — 녹색
- **Warning**: hsl(25 76% 49%) — 경고 오렌지

### UI 패턴
- **모바일 퍼스트**: max-w-[375px] 기준, dvh 사용
- **BottomSheet**: 스냅포인트 3단계 (80px/40vh/85vh)
- **FloatingButton**: 우측 하단 고정
- **ConnectionStatus**: 상단 전체너비 배너 (노란/빨간)
- **44x44px 최소 터치 타겟**: 모든 버튼에 min-h-[44px]
- **Pretendard 폰트**: 가변 폰트 (로컬 호스팅)
- **Sonner Toast**: 알림 메시지

---

## 기존 E2E 테스트 파일 (검증된 셀렉터와 플로우)

| 파일 | 시나리오 | 핵심 셀렉터/패턴 |
|------|---------|----------------|
| `e2e/admin-flow.spec.ts` | 관리자 흐름 (대회 생성, GPX 업로드, 상태 변경) | `createTestRace()`, `createTestCoursePoints()` |
| `e2e/spectator-map.spec.ts` | 관전자 지도 렌더링 + 실시간 업데이트 | `getByTestId('bottom-sheet')`, `broadcastPositionUpdate()` |
| `e2e/cheer-alert.spec.ts` | 응원 알림 + 실시간 위치 반영 | `getByTestId('alert-banner')`, ETA 트리거 |
| `e2e/split-records.spec.ts` | 구간 기록 | split_update Broadcast |
| `e2e/race-finish.spec.ts` | 대회 종료 | status 변경 |
| `e2e/fixtures/test-helpers.ts` | 테스트 헬퍼 (데이터 생성/삭제) | `createTestRace()`, `createTestUser()`, `broadcastPositionUpdate()` 등 |
