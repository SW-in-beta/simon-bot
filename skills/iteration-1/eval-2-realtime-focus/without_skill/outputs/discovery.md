# cheer93 프로젝트 실시간 기능 분석 (Discovery)

## 프로젝트 개요

**cheer93**은 마라톤 응원 서비스로, 관중(spectator)이 실시간으로 주자(runner)의 위치를 추적하고, 주자가 응원 지점에 접근하면 알림을 받는 모바일 웹 애플리케이션이다.

- **스택**: Next.js 15 + React 19 + Supabase + Tailwind + shadcn/ui
- **지도**: 카카오맵 SDK
- **Worker**: 별도 Node.js 폴링 워커 (Fly.io 배포)
- **알림**: Web Push (VAPID) + CoolSMS

---

## 아키텍처 전체 흐름

```
[외부 데이터 소스]           [Worker (30초 폴링)]              [Supabase]             [클라이언트]

Garmin LiveTrack API  --->  GarminAdapter.fetchPositions()
SmartChip Result Page --->  SmartChipAdapter.fetchPositions()
                                    |
                              Poller.pollOnce()
                                    |
                            +-------+-------+
                            |               |
                     DB 저장 (INSERT/UPSERT) |
                            |               |
              tracking_positions     runner_current_positions
              (시계열 이력)           (최신 위치 UPSERT)
                                            |
                                  Broadcaster.broadcastPositionUpdate()
                                  Broadcaster.broadcastSplitUpdate()
                                            |
                                    Supabase Realtime
                                    (channel broadcast)
                                            |
                                   useRealtimePositions()
                                            |
                               useMarkerInterpolation()
                                            |
                                  SpectatorMapClient
                                  (카카오맵 렌더링)
```

---

## 실시간 위치 추적 시스템

### 1. 데이터 수집 (Worker)

**경로**: `/worker/src/`

#### 폴링 주기
- `POLL_INTERVAL_MS = 30_000` (30초)
- `Poller.pollOnce()`가 live 상태인 모든 대회를 순회하며 위치 수집

#### 어댑터 패턴 (Strategy Pattern)
두 가지 위치 데이터 소스를 어댑터 인터페이스로 추상화:

| 어댑터 | 소스 | 신뢰도 | 수집 방식 |
|--------|------|--------|-----------|
| `GarminAdapter` | Garmin LiveTrack API | `high` (GPS 직접) | HTTPS API 호출, 마지막 trackPoint의 lat/lon/speed/distance 추출 |
| `SmartChipAdapter` | smartchipresult.com | `high`/`medium`/`low` (경과 시간 기반) | HTML 스크래핑 + XOR 복호화, 매트 통과 km 기반 코스 보간 |

#### SmartChip 위치 보간 로직
SmartChip은 GPS가 아닌 매트 통과 시점(km)만 제공하므로, 코스 경로 위에 보간하여 좌표를 추정한다:
1. 마지막 매트 통과 km + (경과 시간 / 페이스) = 추정 현재 km
2. `interpolatePosition(coursePoints, estimatedKm)` -> 코스 polyline 위의 좌표로 변환
3. 경과 시간에 따라 신뢰도(confidence) 결정: <5분=high, <15분=medium, 그 외=low

#### 데이터 저장
- `tracking_positions`: 시계열 이력 (INSERT)
- `runner_current_positions`: 최신 위치만 유지 (UPSERT on runner_id)

### 2. 실시간 브로드캐스트

**경로**: `/worker/src/broadcaster.ts`

Supabase Realtime의 **Broadcast** 기능 사용 (DB 변경 감지가 아닌 직접 channel send):

```
채널명: `race:{raceId}`
이벤트 3종:
  - position_update: 모든 주자의 최신 위치 일괄 전송
  - split_update: km 구간 기록 통과 시 개별 전송
  - race_status_change: 대회 상태 변경 (scheduled -> live -> finished)
```

### 3. 클라이언트 실시간 수신

**경로**: `/src/hooks/useRealtimePositions.ts`

- Supabase channel subscribe로 3개 이벤트 수신
- `positions`: `Map<runnerId, RunnerPosition>` - 모든 주자의 최신 위치
- `splits`: `Map<runnerId, SplitUpdatePayload[]>` - km별 구간 기록
- `raceStatus`: 대회 상태 실시간 반영
- `connectionStatus`: connected / connecting / disconnected
- `refresh()`: 수동 새로고침 (runner_current_positions DB 직접 조회, 5초 쓰로틀)

### 4. 마커 보간 애니메이션

**경로**: `/src/hooks/useMarkerInterpolation.ts`

30초 간격 위치 업데이트 사이의 끊김을 해소하기 위한 클라이언트 측 선형 보간:
- `INTERPOLATION_DURATION_MS = 2000` (2초간 부드러운 이동)
- `requestAnimationFrame` 기반 lerp 애니메이션
- 이전 위치 -> 새 위치 사이를 2초에 걸쳐 선형 보간

---

## 응원 기능 시스템

### 1. 응원 위치 설정

**경로**: `/src/components/form/CheerLocationForm.tsx`

관중이 자신의 응원 위치를 코스 위에 설정:
- **GPS 자동감지**: `navigator.geolocation` -> `snapToCourse()` (haversine 최근접점)
- **수동 km 입력**: km 값으로 가장 가까운 course_point 매핑
- `spectators` 테이블에 `cheer_lat`, `cheer_lng`, `cheer_km` 저장

### 2. ETA 계산

**경로**: `/src/hooks/useEtaCalculation.ts`

```
ETA(초) = (cheerKm - currentKm) * currentPace
```

- `cheerKm`: 관중의 응원 위치 (km)
- `currentKm`: 주자의 현재 위치 (km)
- `currentPace`: 현재 페이스 (초/km)
- 상태: approaching(접근중), passed(통과), waiting(대기)

### 3. 알림 트리거

**경로**: `/src/hooks/useNotificationTrigger.ts`

- `ETA_TRIGGER_SECONDS = 180` (3분 이내 도착 예상 시 트리거)
- `THROTTLE_SECONDS = 30` (동일 주자 30초 내 중복 알림 방지)
- 알림 채널: in_app, web_push, sms

### 4. 접근 알림 UI

**경로**: `/src/components/alert/ApproachAlert.tsx` + `AlertBanner.tsx`

- 최대 3개 배너 동시 표시
- 5초 후 자동 최소화 (MiniBadge로 전환)
- "약 N분 후 도착 예정" + 추정치 여부 표시
- ReadyShot 아바타 표시
- 클릭 시 해당 주자 위치로 지도 포커스

### 5. 알림 발송 API

| 채널 | 엔드포인트 | 구현 |
|------|-----------|------|
| Web Push | `POST /api/notifications/push` | VAPID + web-push 라이브러리 |
| SMS | `POST /api/notifications/sms` | CoolSMS API, pgp_sym_encrypt 전화번호 복호화 |

공통: 30초 throttle, notification_logs 이력 기록

---

## 관전자 화면 (SpectatorMapClient)

**경로**: `/src/app/race/[smartchipId]/SpectatorMapClient.tsx`

### UI 구성
1. **ConnectionStatus**: 상단 연결 상태 바 (연결 중: 노란색, 끊김: 빨간색)
2. **KakaoMap**: 전체 화면 지도
   - CoursePolyline: 코스 경로 표시
   - KmMarker: 5km 간격 마커
   - RunnerMarker: 주자 위치 (confidence별 스타일 차별화)
3. **FloatingButton**: 우측 하단 수동 새로고침
4. **BottomSheet**: 드래그 가능한 하단 시트 (80px / 40vh / 85vh)
   - RaceStatus: 대회 상태, 주자 수 요약
   - RunnerList: 주자 목록 + 현재 km/페이스

### 접근 방식
- URL: `/race/{smartchipId}` (로그인 불필요, 익명 세션)
- 세션 토큰 로컬스토리지 관리
- spectators 테이블 upsert로 관전자 등록

---

## 관리자 대시보드

**경로**: `/src/app/admin/races/[raceId]/dashboard/DashboardClient.tsx`

- `useRealtimePositions` 동일 훅 사용
- 통계 카드 6종: 활주 중, 완주, DNF, 평균 페이스, Garmin 수, SmartChip 수
- `RaceStatusControl`: scheduled -> live -> finished 상태 전이 (FSM)

---

## 데이터베이스 스키마 (실시간 관련)

| 테이블 | 용도 |
|--------|------|
| `races` | 대회 (status: scheduled/live/finished) |
| `runners` | 주자 (status: registered/running/finished/dnf, data_source: garmin/smartchip) |
| `course_points` | GPX 파싱 결과, 코스 보간 기준점 |
| `tracking_positions` | 30초 간격 위치 시계열 이력 |
| `runner_current_positions` | 주자별 최신 위치 (UPSERT) |
| `spectators` | 관전자 (익명 세션, 응원 위치, 암호화 전화번호) |
| `split_records` | km별 구간 기록 |
| `push_subscriptions` | Web Push 구독 정보 |
| `notification_logs` | 알림 전송 이력 (throttle 판단) |

---

## 핵심 기술적 특징

1. **Supabase Broadcast (WebSocket 아닌 Realtime Channel)**: DB 변경 감지(postgres_changes)가 아니라 Worker가 직접 channel.send()로 브로드캐스트. 이렇게 하면 DB write와 broadcast를 분리할 수 있고, batch 전송이 가능.

2. **이중 보간 전략**:
   - 서버 측: SmartChip 매트 데이터를 코스 polyline 위 좌표로 보간 (`worker/src/interpolation.ts`)
   - 클라이언트 측: 30초 간격 업데이트 사이를 2초 lerp 애니메이션으로 부드럽게 (`useMarkerInterpolation`)

3. **Confidence 기반 마커 표현**:
   - high: 불투명 실선 (#1B4D3E 배경)
   - medium: 반투명 점선 (0.5 opacity)
   - low: 회색 텍스트만 (0.6 opacity, "마지막 확인: Nkm (M분 전)")

4. **익명 세션 기반 관전**: 로그인 없이 smartchip_id 공유 링크로 접근, localStorage 세션 토큰

5. **전화번호 암호화**: pgp_sym_encrypt/decrypt로 DB 내 암호화 저장, RPC를 통한 복호화

---

## 현재 한계점 및 데모 시 주의사항

1. **외부 API 의존성**: Garmin LiveTrack API와 SmartChip 사이트가 실제로 동작해야 Worker가 데이터를 수집함
2. **카카오맵 API 키 필요**: `NEXT_PUBLIC_KAKAO_MAP_KEY` 환경변수
3. **Supabase 인스턴스 필요**: 로컬 Supabase 또는 클라우드 인스턴스
4. **seed 데이터 부재**: `seed.sql`이 빈 파일, `seed-course.gpx`만 존재 (서울시청-서대문 약 5km 시뮬레이션 코스)
5. **Worker 별도 실행**: `worker/` 디렉토리에서 별도로 실행해야 함 (`tsx watch src/index.ts`)
