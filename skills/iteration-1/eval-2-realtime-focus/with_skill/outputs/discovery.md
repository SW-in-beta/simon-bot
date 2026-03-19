# 프로젝트 분석: CheeR93

마라톤 실시간 응원 플랫폼. 주자의 위치를 실시간으로 추적하고, 응원자에게 주자 접근 알림을 전달한다.

## 모드

**CONNECTED 모드** — `.claude/company/` 디렉토리에 simon-company 산출물 존재 (architecture.md, db-schema.md, prd.md, contracts/, tasks/, 등)

---

## 기동 방법

- **패키지 매니저**: pnpm (pnpm-lock.yaml 존재, pnpm-workspace.yaml로 모노레포 구성)
- **기동 명령어**: `pnpm dev` (Next.js dev 서버)
- **빌드**: `pnpm build && pnpm start` (프로덕션)
- **포트**: 3000 (Next.js 기본)
- **의존 서비스**: Supabase (Auth, Database, Realtime, Storage)
- **Worker**: `worker/` 디렉토리 — 별도 Node.js 프로세스 (`pnpm --filter cheer93-worker dev`)
- **필수 환경 변수**:
  - `NEXT_PUBLIC_SUPABASE_URL` — Supabase 프로젝트 URL
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY` — Supabase anon key
  - `SUPABASE_SERVICE_ROLE_KEY` — Supabase service role key (admin 클라이언트용)
  - `NEXT_PUBLIC_KAKAO_MAP_KEY` — 카카오 맵 JavaScript API 키
  - `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT` — Web Push VAPID
  - `NEXT_PUBLIC_VAPID_PUBLIC_KEY` — 클라이언트 사이드 VAPID 공개키
  - `COOLSMS_API_KEY`, `COOLSMS_API_SECRET`, `COOLSMS_SENDER_NUMBER` — SMS 알림
  - `ENCRYPTION_KEY` — 전화번호 암호화 (pgcrypto)
- **Worker 환경 변수**: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SMARTCHIP_XOR_KEY`

---

## 라우트 맵

| URL | 페이지 | 인증 필요 | 비고 |
|-----|--------|----------|------|
| `/` | 랜딩 페이지 | 아니오 | 관리자 로그인 링크만 존재 |
| `/login` | 로그인 페이지 | 아니오 | 카카오 OAuth (LoginButton 컴포넌트) |
| `/admin` | 대회 목록 | 예 | middleware에서 세션 체크 |
| `/admin/races/new` | 대회 생성 폼 | 예 | RaceForm 컴포넌트 |
| `/admin/races/[raceId]` | 대회 상세 | 예 | 상태 관리, GPX 업로드, 코스 미리보기 |
| `/admin/races/[raceId]/dashboard` | 실시간 대시보드 | 예 | DashboardClient — 통계 실시간 갱신 |
| `/race/[smartchipId]` | 관전자 지도 (메인) | 아니오 | SpectatorMapClient — 핵심 화면 |
| `/race/[smartchipId]/join` | 주자 자가등록 | 예 | RunnerRegForm |
| `/race/[smartchipId]/readyshot` | 레디샷 등록 | 예 | ReadyShotForm |
| `/auth/callback` | OAuth 콜백 | 아니오 | Supabase Auth 콜백 처리 |

---

## 인증

- **방식**: Supabase Auth (카카오 OAuth)
- **미들웨어**: `src/middleware.ts` — `updateSession()` 호출로 쿠키 기반 세션 유지
- **테스트 계정**: 시뮬레이션 스크립트가 `runner{bib}@simulation.local` / `simulation-password-123` 계정을 `auth.admin.createUser()`로 생성
- **역할**: race_staff 테이블의 role 컬럼 (`owner`, `admin`)
- **인증 불필요 경로**: `/race/[smartchipId]` (관전자 지도) — 익명 세션 토큰 (localStorage)으로 spectator 식별

---

## 핵심 셀렉터 (E2E 테스트에서 검증됨)

| 요소 | 셀렉터 | 페이지 |
|------|--------|--------|
| 대회명 제목 | `getByRole('heading', { name: '대회 관리' })` | /admin |
| 새 대회 만들기 | `getByRole('link', { name: '새 대회 만들기' })` | /admin |
| 대회명 필드 | `getByLabel('대회명')` | /admin/races/new |
| 대회 날짜 필드 | `getByLabel('대회 날짜')` | /admin/races/new |
| SmartChip ID 필드 | `getByLabel('SmartChip 대회 ID')` | /admin/races/new |
| 대회 생성 버튼 | `getByRole('button', { name: '대회 생성' })` | /admin/races/new |
| 대회 시작 버튼 | `getByRole('button', { name: /대회 시작/ })` | /admin/races/[raceId] |
| 바텀시트 | `getByTestId('bottom-sheet')` | /race/[smartchipId] |
| 카카오 지도 | `getByTestId('kakao-map')` | /race/[smartchipId] |
| 새로고침 버튼 | `getByRole('button', { name: '새로고침' })` | /race/[smartchipId] |
| 드래그 핸들 | `getByTestId('drag-handle')` | /race/[smartchipId] |
| 접근 알림 컨테이너 | `getByTestId('approach-alert-container')` | /race/[smartchipId] |
| 주자 마커 | `getByTestId('runner-marker-{runnerId}')` | /race/[smartchipId] |
| 연결 상태 (재연결 중) | `role="alert"` + "재연결 중..." | /race/[smartchipId] |

---

## API 엔드포인트

| 메서드 | 경로 | 설명 | 모킹 필요 |
|--------|------|------|----------|
| GET | `/api/positions?raceId=` | 주자 현재 위치 조회 (runner_current_positions) | 아니오 (DB 직접 조회) |
| POST | `/api/races/[raceId]/gpx` | GPX 파일 업로드 → course_points 저장 | 아니오 |
| POST | `/api/notifications/push` | Web Push 알림 발송 | 예 (VAPID 키 필요) |
| POST | `/api/notifications/sms` | SMS 알림 발송 | 예 (CoolSMS API 키 필요) |
| Supabase Realtime | `race:{raceId}` 채널 | 실시간 위치/split/상태 브로드캐스트 | 아니오 (Supabase 제공) |

---

## DB 스키마 요약

### 핵심 테이블과 관계

```
profiles (id=auth.users.id)
    └── runners (user_id → profiles.id)
    └── race_staff (user_id → profiles.id)

races (id)
    ├── race_staff (race_id → races.id)
    ├── runners (race_id → races.id)
    │   ├── tracking_positions (runner_id → runners.id)
    │   ├── runner_current_positions (runner_id → runners.id, PK)
    │   └── split_records (runner_id → runners.id)
    ├── course_points (race_id → races.id)
    └── spectators (race_id → races.id)
        ├── push_subscriptions (spectator_id → spectators.id)
        └── notification_logs (spectator_id → spectators.id)
```

### 시드 데이터 삽입 순서

1. `races` — 대회 생성
2. `profiles` + auth user — 사용자 생성
3. `race_staff` — 관리자 연결
4. `runners` — 주자 등록 (race_id, user_id 필요)
5. `course_points` — 코스 좌표 (GPX 파싱 결과)
6. `spectators` — 응원자 생성 (session_token 기반)
7. `runner_current_positions` — 주자 현재 위치 (UPSERT)
8. `tracking_positions` — 시계열 위치 데이터
9. `split_records` — 구간 기록

---

## 모킹 대상

| 대상 | 이유 | 대안 |
|------|------|------|
| Garmin LiveTrack API | 실제 GPS 기기 필요 | 시뮬레이션 스크립트로 직접 DB INSERT + Realtime 브로드캐스트 |
| SmartChip 결과 서버 | 외부 서비스 | 위와 동일 |
| 카카오 맵 API | `NEXT_PUBLIC_KAKAO_MAP_KEY` 필요 | 키가 없으면 지도 미로딩 (스켈레톤 표시) |
| Web Push (VAPID) | VAPID 키 필요 | 알림 발송 없이 인앱 배너만 확인 가능 |
| CoolSMS | API 키 필요 | SMS 시나리오 제외 |

**핵심 포인트**: 실시간 위치 추적은 외부 API 모킹 없이 **시뮬레이션 스크립트**(`scripts/simulation/`)로 완전히 재현 가능. 이 스크립트가 DB에 직접 데이터를 넣고 Supabase Realtime으로 브로드캐스트하므로, Worker 프로세스 없이도 실시간 기능을 시연할 수 있다.

---

## 유저스토리별 코드 플로우 추적

### 플로우 1: US-6.2 "응원자가 지도에서 주자 실시간 위치를 본다"

이것이 데모의 핵심 플로우다.

#### 사용자 동작 경로
```
/race/{smartchipId} 접속 → 지도 렌더링 → 주자 마커 실시간 이동 관찰
```

#### 코드 실행 흐름

**1. [Server] 페이지 접근 — 초기 데이터 로딩**
- 파일: `src/app/race/[smartchipId]/page.tsx`
- `getRaceBySmartchipId(smartchipId)` → races 테이블에서 대회 조회
- `supabase.from('course_points').select(*)` → 코스 좌표 로드
- `supabase.from('runners').select('*, profiles(display_name)')` → 위치 동의한 주자 목록
- 5km 단위 kmMarkers 필터링
- `SpectatorMapClient`에 props 전달

**2. [Client] SpectatorMapClient 마운트**
- 파일: `src/app/race/[smartchipId]/SpectatorMapClient.tsx`
- `getOrCreateSessionToken()` → localStorage에서 익명 세션 토큰 생성/복구
- `spectators` 테이블에 UPSERT (race_id + session_token)
- `useRealtimePositions(race.id)` 호출

**3. [Client] Realtime 채널 구독**
- 파일: `src/hooks/useRealtimePositions.ts`
- `supabase.channel('race:{raceId}')` 생성
- 3개 이벤트 리스너 등록:
  - `position_update` → positions Map 갱신 (runnerId별 lat/lng/km/pace/confidence)
  - `split_update` → splits Map 갱신
  - `race_status_change` → 대회 상태 변경 반영
- `.subscribe()` → connectionStatus: 'connecting' → 'connected'

**4. [External/Worker] 위치 데이터 발행**
- **Worker 경로** (프로덕션):
  - `worker/src/index.ts` → 30초 간격 폴링
  - `Poller.pollOnce()` → live 대회 조회 → 주자별 어댑터 호출
  - GarminAdapter: `livetrack.garmin.com/services/session/{id}/trackpoints` 호출
  - SmartChipAdapter: `smartchipresult.com/runner/{bib}` → XOR 복호화 → 코스 보간
  - `Broadcaster.broadcastPositionUpdate()` → `supabase.channel('race:{raceId}').send('position_update', ...)`
- **시뮬레이션 경로** (데모):
  - `scripts/simulation/runner.ts` → data.json에서 타임라인 로드
  - 각 step마다: tracking_positions INSERT + runner_current_positions UPSERT + Realtime broadcast
  - `--speed N` 옵션으로 속도 조절 (10배속, 60배속 등)

**5. [Client] position_update 수신 → UI 갱신**
- `useRealtimePositions` → positions Map 업데이트
- `useMarkerInterpolation` → 2초간 선형 보간 (lerp)으로 부드러운 마커 이동
  - `requestAnimationFrame` 루프로 60fps 애니메이션
  - from → to 사이를 `INTERPOLATION_DURATION_MS=2000`에 걸쳐 보간
- `RunnerMarker` → Kakao Maps CustomOverlay의 position 업데이트
  - confidence별 UI 차이: high=불투명 실선, medium=반투명 점선, low=회색 최소 표시

**6. [Client] 하단 RunnerList 갱신**
- BottomSheet 내 RunnerList 컴포넌트
- positions Map에서 각 주자의 currentKm, currentPace 표시
- 클릭 시 → `map.setCenter(runnerPosition)` + `map.setLevel(3)`으로 해당 주자에 줌인

#### 시연을 위한 사전 데이터
- `races` 1개 (status: 'live', smartchip_id 설정)
- `course_points` N개 (GPX 파싱 결과 — seed-course.gpx 활용 가능)
- `runners` 5명 (각기 다른 pace, location_consent: true)
- `profiles` 5명 (display_name 설정)
- `runner_current_positions` 5개 (초기 위치)
- 시뮬레이션 스크립트 실행 중 (실시간 브로드캐스트)

#### 핵심 관찰 포인트
- 지도 위 마커가 **부드럽게 이동** (2초 보간 애니메이션)
- 마커에 배번, 이름, 페이스 표시
- BottomSheet의 주자 목록에서 km, 페이스 실시간 갱신
- 연결 상태 표시줄 (connected일 때 숨김, 재연결 시 노란 바)

---

### 플로우 2: US-5.3 "구간 기록 (Split) 생성 및 브로드캐스트"

#### 코드 실행 흐름

**1. [Worker/Simulation] Split 감지**
- 파일: `worker/src/split.ts` → `detectSplits()`
- previousKm과 currentKm 사이의 정수 km 경계를 탐지
- 선형 보간으로 통과 시각 추정 → splitTime(구간 소요), splitPace, cumulativeTime 산출

**2. [Worker/Simulation] Realtime 브로드캐스트**
- `broadcaster.broadcastSplitUpdate(raceId, { runnerId, km, splitTime, splitPace, cumulativeTime })`
- `split_records` 테이블에 INSERT

**3. [Client] split_update 수신**
- `useRealtimePositions` → splits Map 갱신
- SplitTable 컴포넌트에서 구간 기록 표시 가능

#### 핵심 관찰 포인트
- 시뮬레이션 콘솔에서 `[101] 1km 통과 - 구간: 00:04:00, 누적: 00:04:00` 같은 로그
- 클라이언트에서 실시간 수신 확인

---

### 플로우 3: US-6.3 + US-6.4 "응원 위치 설정 → 주자 접근 알림"

#### 사용자 동작 경로
```
/race/{smartchipId} → 응원 위치 설정 (GPS 자동감지 또는 km 수동입력) → 대기 → 주자 접근 시 인앱 알림
```

#### 코드 실행 흐름

**1. [Client] CheerLocationForm**
- 파일: `src/components/form/CheerLocationForm.tsx`
- GPS 자동감지: `navigator.geolocation.getCurrentPosition()` → `snapToCourse()` → 가장 가까운 코스 지점으로 스냅
- km 수동입력: `findClosestByKm()` → coursePoints 중 가장 가까운 지점
- 제출: `spectators` 테이블 UPDATE (cheer_lat, cheer_lng, cheer_km, nickname)

**2. [Client] ETA 계산**
- 파일: `src/hooks/useEtaCalculation.ts`
- `etaSeconds = (cheerKm - currentKm) * currentPace`
- status: 'approaching' (주자가 응원 지점 앞), 'passed' (이미 통과), 'waiting' (데이터 부족)

**3. [Client] 알림 트리거**
- 파일: `src/hooks/useNotificationTrigger.ts`
- `ETA_TRIGGER_SECONDS = 180` (3분 이내)
- `THROTTLE_SECONDS = 30` (30초 중복 방지)
- 조건 충족 시 → `onNotification` 콜백 + `activeAlerts` 상태 갱신

**4. [Client] 인앱 알림 배너**
- 파일: `src/components/alert/ApproachAlert.tsx`
- AlertBanner 최대 3개 동시 표시
- 최소화 → MiniBadge로 전환
- 배너 탭 → `onFocusRunner(runnerId)` → 지도에서 해당 주자로 이동

#### 시연을 위한 사전 데이터
- 위 플로우 1의 데이터 + spectators 테이블에 cheer_km 설정된 응원자
- 시뮬레이션에서 주자가 해당 km에 접근하도록 타이밍 조절

#### 핵심 관찰 포인트
- 주자가 응원 지점 3분 거리에 도달하면 **인앱 배너 팝업**
- 배너에 주자 이름, ETA 표시
- 배너 탭 시 지도가 해당 주자 위치로 포커스

---

### 플로우 4: US-2.1 + US-2.3 + US-2.4 "대회 생성 → GPX 업로드 → 대회 시작"

#### 사용자 동작 경로
```
/login → 카카오 OAuth → /admin → "새 대회 만들기" → /admin/races/new → 폼 작성 → 제출 → /admin/races/[raceId] → GPX 업로드 → "대회 시작 (Live)" 클릭
```

#### 코드 실행 흐름

**1. [Server] 인증**
- `/login` → LoginButton → Supabase OAuth (카카오)
- 콜백: `/auth/callback/route.ts` → `supabase.auth.exchangeCodeForSession()`
- 성공 시 → `/admin`으로 리다이렉트

**2. [Server] 대회 생성**
- `createRaceAction(name, raceDate, smartchipId)` (Server Action)
- `src/lib/race.ts` → `createRace()`:
  - 인증 확인 → races INSERT → race_staff INSERT (owner 역할)
  - smartchip_id UNIQUE 제약 위반 시 에러 반환

**3. [Client → API] GPX 업로드**
- `GpxUploader` 컴포넌트 → `POST /api/races/[raceId]/gpx`
- GPX XML 파싱 → course_points INSERT → total_distance_km UPDATE

**4. [Client] 대회 상태 변경**
- `RaceStatusControl` → `updateRaceStatusAction(raceId, 'live')`
- AlertDialog로 확인 → races.status UPDATE (scheduled → live)
- 유효 전이: scheduled → live → finished

#### 시연을 위한 사전 데이터
- 카카오 OAuth 인증이 가능한 계정 (또는 seed 계정)
- seed-course.gpx 파일 (supabase/ 디렉토리에 존재)

---

### 플로우 5: US-7.1 "관리자 실시간 모니터링 대시보드"

#### 사용자 동작 경로
```
/admin/races/[raceId]/dashboard → 실시간 통계 확인
```

#### 코드 실행 흐름

**1. [Client] DashboardClient**
- 파일: `src/app/admin/races/[raceId]/dashboard/DashboardClient.tsx`
- `useRealtimePositions(race.id)` → 동일한 Realtime 채널 구독
- 6개 StatCard:
  - 활주 중 (running count)
  - 완주 (finished count)
  - DNF (dnf count)
  - 평균 페이스 (positions에서 pace > 0인 것들 평균)
  - Garmin 주자 수
  - SmartChip 주자 수
- `aria-live="polite"` + `aria-atomic="true"`로 접근성 확보

#### 핵심 관찰 포인트
- 실시간으로 통계 숫자 변동
- 주자 완주 시 running 감소, finished 증가
- 평균 페이스 실시간 재계산

---

## 시뮬레이션 시스템 상세

프로젝트에 이미 완성된 시뮬레이션 시스템이 있다. 이것이 데모의 핵심 인프라다.

### 데이터 생성 (`scripts/simulation/generate.ts`)
```bash
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npx tsx scripts/simulation/generate.ts --gpx supabase/seed-course.gpx
```
- 대회 1개 생성 (status: scheduled → live)
- 주자 5명 (배번 101~105, 페이스 4분~6분/km, smartchip/garmin 혼합)
- 응원자 3명 (1km, 3km, 5km 지점)
- 시계열 타임라인 → data.json 저장

### 실시간 재생 (`scripts/simulation/runner.ts`)
```bash
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npx tsx scripts/simulation/runner.ts --speed 10
```
- data.json 로드 → 30초 간격 포인트를 speed 배수로 재생
- 각 step: tracking_positions INSERT + runner_current_positions UPSERT + Realtime broadcast
- split 감지 시 split_records INSERT + split_update broadcast
- 완주 시 runners.status → 'finished'

### 주자 설정
| 배번 | 페이스 (초/km) | 풀마라톤 환산 | 데이터 소스 |
|------|---------------|-------------|-----------|
| 101 | 240 (4분) | ~2h49m | smartchip |
| 102 | 270 (4분30초) | ~3h10m | smartchip |
| 103 | 300 (5분) | ~3h31m | smartchip |
| 104 | 330 (5분30초) | ~3h52m | garmin |
| 105 | 360 (6분) | ~4h13m | garmin |

### 실시간 데이터 흐름 (시뮬레이션)
```
runner.ts step N
  ├── DB: tracking_positions INSERT (시계열)
  ├── DB: runner_current_positions UPSERT (최신)
  ├── Realtime: position_update broadcast
  │     └── 모든 구독 클라이언트 수신
  │           ├── SpectatorMapClient → 마커 이동 (보간)
  │           └── DashboardClient → 통계 갱신
  ├── split 감지 시:
  │     ├── DB: split_records INSERT
  │     └── Realtime: split_update broadcast
  └── 완주 시:
        └── DB: runners.status → 'finished'
```

---

## 실시간 통신 아키텍처 상세

### Supabase Realtime 채널 구조

```
채널: race:{raceId}
  ├── 이벤트: position_update
  │   payload: {
  │     runners: [{
  │       runnerId, lat, lng, currentKm, currentPace,
  │       confidence ('high'|'medium'|'low'),
  │       source ('garmin'|'smartchip'),
  │       timestamp
  │     }]
  │   }
  │
  ├── 이벤트: split_update
  │   payload: {
  │     runnerId, km, splitTime, splitPace, cumulativeTime
  │   }
  │
  └── 이벤트: race_status_change
      payload: {
        raceId, status ('scheduled'|'live'|'finished')
      }
```

### 클라이언트 보간 시스템

```
position_update 수신 (30초 간격)
  → useRealtimePositions: positions Map 갱신
  → useMarkerInterpolation:
      - 이전 위치(from)에서 새 위치(to)까지 2000ms 선형 보간
      - requestAnimationFrame 60fps 루프
      - lerp(a, b, t): a + (b - a) * t
  → RunnerMarker: Kakao CustomOverlay.setPosition() 호출
```

### ETA + 알림 파이프라인

```
positions Map (실시간)
  → useEtaCalculation(positions, cheerKm):
      - etaSeconds = (cheerKm - currentKm) * currentPace
      - status: approaching | passed | waiting
  → useNotificationTrigger(etas, runners):
      - etaSeconds <= 180 (3분) → 트리거
      - 30초 throttle (같은 주자)
      - activeAlerts 리스트 갱신
  → ApproachAlert → AlertBanner (최대 3개)
```
