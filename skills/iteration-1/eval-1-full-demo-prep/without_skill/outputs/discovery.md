# CheeR93 프로젝트 분석 보고서

## 1. 프로젝트 개요

**CheeR93**은 마라톤 실시간 응원 플랫폼이다. 주자의 위치를 실시간으로 추적하여 코스 위 응원자에게 주자 접근 알림을 전달한다.

### 핵심 가치 제안 (투자자 관점)
1. **응원자가 로그인 없이** 공유 링크만으로 주자의 실시간 위치를 추적할 수 있다
2. **ETA 기반 멀티채널 알림** -- 주자가 가까워지면 인앱/Web Push/SMS로 "약 N분 후 도착" 알림을 받는다
3. **이질적 데이터 소스 통합** -- Garmin GPS 좌표 직접 수집 + SmartChip 매트 통과 보간이라는 서로 다른 데이터를 하나의 실시간 지도에 통합한다

### 사용자 역할

| 역할 | 설명 | 인증 |
|------|------|------|
| **관리자** | 대회를 생성/관리하는 사람 | 카카오 OAuth 필수 |
| **주자** | 대회에 참가하여 달리는 사람 | 자가등록 시 로그인 필수 |
| **응원자** | 공유 링크로 접속하여 주자를 응원하는 사람 | 로그인 불필요 (익명 가능) |

---

## 2. 기술 스택

| 분류 | 기술 | 역할 |
|------|------|------|
| 프레임워크 | Next.js 15.x (App Router) + React 19.x + TypeScript 5.x | SSR, 라우팅, API Routes |
| 스타일링 | Tailwind CSS 4.x + shadcn/ui + Pretendard 폰트 | 모바일 퍼스트 반응형 UI |
| BaaS | Supabase (Auth, PostgreSQL, Realtime Broadcast, Storage) | 인증, DB, 실시간 통신 |
| 지도 | Kakao Maps API v3 + CustomOverlay | 국내 마라톤 코스 렌더링 |
| Worker | Fly.io (30초 폴링) | 위치 수집 파이프라인 |
| SMS | CoolSMS v4 API | 문자 알림 |
| Push | Web Push (VAPID) | 브라우저 푸시 알림 |
| 테스트 | Vitest + Playwright | 단위/통합/E2E 테스트 |
| 배포 | Vercel (프론트) + Fly.io (Worker) + Supabase (DB) | 3-tier 배포 |

---

## 3. 시스템 아키텍처

```
[Garmin LiveTrack / SmartChip]
          |
    [Fly.io Worker] -- 30초 폴링
          |
    +-----------+
    | Supabase  |
    | - DB INSERT (tracking_positions, runner_current_positions)
    | - Realtime Broadcast (position_update, split_update)
    +-----------+
          |
    [Next.js App (Vercel)]
          |
    +------------------+
    | 클라이언트 (브라우저) |
    | - Kakao Maps 지도  |
    | - 마커 보간 애니메이션 |
    | - ETA 계산 (클라이언트) |
    | - 알림 트리거       |
    +------------------+
```

### 핵심 아키텍처 결정

1. **Realtime Broadcast 전용** -- Postgres Changes 미사용. DB와 Realtime 부하를 완전 분리
2. **어댑터 패턴** -- `LocationAdapter` 인터페이스로 Garmin/SmartChip 격리. 새 소스 추가 시 어댑터만 추가
3. **클라이언트 측 ETA 계산** -- 응원자별로 다른 위치 기준이므로 서버 계산 비효율. `position_update` 수신 시 클라이언트에서 재계산
4. **SmartChip 3단계 신뢰도** -- 매트 통과 후 경과 시간 기반 (5분: high/실선, 15분: medium/반투명, 15분 초과: low/숨김)
5. **마커 보간 애니메이션** -- `requestAnimationFrame` + lerp로 부드러운 마커 이동

---

## 4. 데이터 모델

### 핵심 테이블 (11개)

| 테이블 | 역할 |
|--------|------|
| `profiles` | 사용자 프로필 (auth.users 확장) |
| `races` | 마라톤 대회 (scheduled/live/finished) |
| `race_staff` | 대회별 관리자 (owner/admin) |
| `runners` | 대회 참가 주자 (배번, Garmin URL, 동의 여부) |
| `tracking_positions` | 주자 위치 시계열 (30초 간격) |
| `runner_current_positions` | 주자 최신 위치 (UPSERT) |
| `split_records` | km별 구간 기록 |
| `course_points` | GPX 파싱 결과 코스 보간 지점 |
| `spectators` | 익명 응원자 (세션 토큰 기반) |
| `push_subscriptions` | Web Push 구독 (VAPID) |
| `notification_logs` | 알림 전송 이력 (throttle 판단) |

- RLS(Row Level Security) 전 테이블 적용
- 전화번호 pgcrypto 암호화
- 대회 종료 90일 후 위치 데이터 자동 파기

---

## 5. 구현 현황 분석

### 프론트엔드 -- 구현 완료 확인된 화면/컴포넌트

| 경로/컴포넌트 | 상태 | 설명 |
|--------------|------|------|
| `/` (랜딩) | 완료 | CheeR93 로고 + 관리자 로그인 링크 |
| `/login` | 완료 | 카카오 OAuth 로그인 (LoginButton) |
| `/auth/callback` | 완료 | OAuth 콜백 핸들러 |
| `/admin` | 완료 | 대회 목록 (RaceCard 컴포넌트) |
| `/admin/races/new` | 완료 | 대회 생성 폼 (RaceForm) |
| `/admin/races/[raceId]` | 완료 | 대회 상세 -- 정보, 상태 관리, GPX 업로드, 코스 미리보기 |
| `/admin/races/[raceId]/dashboard` | 완료 | 관리자 대시보드 -- 6개 StatCard (활주/완주/DNF/평균 페이스/Garmin/SmartChip) |
| `/race/[smartchipId]` | 완료 | 응원자 지도 -- KakaoMap + CoursePolyline + RunnerMarker + BottomSheet |
| `/race/[smartchipId]/join` | 완료 | 주자 자가등록 (RunnerRegForm) |
| `/race/[smartchipId]/readyshot` | 완료 | 레디샷 사진 업로드 |

### 핵심 컴포넌트

| 컴포넌트 | 설명 |
|----------|------|
| `KakaoMap` | Kakao Maps 래퍼 -- 로딩 상태, 스켈레톤 UI |
| `CoursePolyline` | 코스 선 Polyline 렌더링 |
| `RunnerMarker` | 주자 마커 -- CustomOverlay + React Portal, 3단계 신뢰도 시각화 |
| `KmMarker` | km 지점 마커 |
| `CheerMarker` | 응원 위치 마커 |
| `MarkerCluster` | 밀집 마커 클러스터링 |
| `CoursePreview` | 관리자용 코스 미리보기 |
| `BottomSheet` | 스와이프 가능한 바텀시트 (snap points: 80px/40vh/85vh) |
| `AlertBanner` | 주자 접근 알림 배너 (5초 후 자동 최소화, 레디샷 표시) |
| `ApproachAlert` | 알림 컨테이너 (최대 3개 배너 + overflow 카운트) |
| `ConnectionStatus` | Realtime 연결 상태 표시 |
| `FloatingButton` | 새로고침 등 플로팅 액션 버튼 |
| `GpxUploader` | GPX 파일 업로드 (드래그앤드롭, 유효성 검증) |
| `RaceStatusControl` | 대회 상태 전환 (scheduled -> live -> finished) |
| `CheerLocationForm` | 응원 위치 설정 (GPS/수동 입력) |
| `PhoneForm` | 전화번호 등록 (SMS 알림용, 동의 절차) |
| `PushPermission` | Web Push 알림 권한 요청 |
| `ReadyShotForm` | 레디샷 사진 업로드 |

### 핵심 Hooks

| Hook | 역할 |
|------|------|
| `useRealtimePositions` | Supabase Realtime Broadcast 구독. position_update/split_update/race_status_change 이벤트 수신 |
| `useMarkerInterpolation` | requestAnimationFrame + lerp로 마커 부드러운 이동 |
| `useEtaCalculation` | 응원자 위치 기준 주자별 ETA(초) 계산 |
| `useNotificationTrigger` | ETA <= 180초 시 알림 발동, 30초 throttle |

### API Routes

| 경로 | 역할 |
|------|------|
| `/api/races/[raceId]/gpx` | GPX 파일 업로드 + 파싱 + course_points INSERT |
| `/api/positions` | 수동 새로고침 (runner_current_positions fetch) |
| `/api/notifications/push` | Web Push 알림 발송 (VAPID) |
| `/api/notifications/sms` | SMS 알림 발송 (CoolSMS) |

### Worker (Fly.io)

| 파일 | 역할 |
|------|------|
| `worker/src/index.ts` | 엔트리포인트 -- 30초 폴링, graceful shutdown (SIGTERM/SIGINT) |
| `worker/src/poller.ts` | 핵심 폴링 로직 -- live 대회 조회 -> 주자별 어댑터 순회 -> DB INSERT -> Broadcast -> Split 감지 |
| `worker/src/broadcaster.ts` | Supabase Realtime Broadcast 발행 |
| `worker/src/adapters/garmin.ts` | Garmin LiveTrack 비공식 API 어댑터 |
| `worker/src/adapters/smartchip.ts` | SmartChip 매트 통과 크롤링 + 위치 보간 어댑터 |
| `worker/src/interpolation.ts` | SmartChip 위치 보간 (누적 거리 기반 이진 탐색 + 선형 보간) |
| `worker/src/split.ts` | Split 기록 감지 (km 통과 시점) |

### 시뮬레이션 시스템

| 파일 | 역할 |
|------|------|
| `scripts/simulation/generate.ts` | 시뮬레이션 데이터 생성 -- GPX 파싱, 대회/주자/응원자 생성, 시계열 데이터 생성 -> data.json |
| `scripts/simulation/runner.ts` | 실시간 시뮬레이션 실행 -- data.json 로드, step별 DB INSERT + Broadcast, 속도 조절 (1x/10x/60x) |
| `scripts/simulation/generate-core.ts` | 순수 계산 로직 (timeline 생성, split 계산) |
| `scripts/simulation/interpolation.ts` | 보간 유틸리티 |

### E2E 테스트 (Playwright)

| 파일 | 시나리오 |
|------|----------|
| `e2e/admin-flow.spec.ts` | 관리자 흐름 (대회 생성, GPX 업로드 등) |
| `e2e/spectator-map.spec.ts` | 관전자 지도 (렌더링, 주자 목록, 실시간 업데이트, 새로고침) |
| `e2e/cheer-alert.spec.ts` | 응원 알림 (주자 접근 시 UI 갱신) |
| `e2e/split-records.spec.ts` | 구간 기록 |
| `e2e/race-finish.spec.ts` | 대회 종료 |

### DB 마이그레이션 -- 19개 파일 완비

`supabase/migrations/` 디렉토리에 00001~00019까지 19개 마이그레이션 파일 존재. 테이블 생성, 트리거, 인덱스, RLS 정책, 스토리지 정책까지 모두 포함.

---

## 6. 디자인 시스템

### 커스텀 디자인 토큰 (globals.css에서 확인)

- **Primary**: `hsl(153 36% 21%)` -- 딥 그린 (러닝/스포츠 이미지)
- **Secondary**: `hsl(215 19% 25%)` -- 다크 블루
- **Accent**: `hsl(19 100% 60%)` -- 비비드 오렌지 (접근 알림, CTA)
- **Live**: `hsl(0 72% 57%)` -- 레드 (대회 진행 중 뱃지)
- **Success**: `hsl(145 45% 43%)` -- 그린 (완주 등)
- **지도 전용 토큰**: runner-marker, runner-marker-approaching, cheer-marker, course-line, km-marker 색상
- **z-index 시스템**: map(0) < course-line(10) < km-marker(20) < runner-marker(30) < cheer-marker(35) < floating-button(40) < bottom-sheet(50) < header(60) < alert-banner(70) < modal(80)
- **애니메이션 시스템**: duration-fast(150ms), duration-normal(300ms), duration-slow(500ms), ease-bounce
- **폰트**: Pretendard Variable (가변 폰트, 45~920 weight)

---

## 7. 비용 구조 (투자자 관점)

| 시기 | 월 비용 |
|------|---------|
| 개발 기간 | **$0** (모든 서비스 Free 플랜) |
| 대회 당일 | **~$25 + SMS** (Supabase Pro $25 + CoolSMS ~2,000~12,000원) |

- Vercel Hobby (무료) -> Pro ($20/월) 확장 가능
- Fly.io Free (shared-cpu-1x, 256MB)
- 대회 없는 달은 비용 0

---

## 8. 리스크 및 완화 전략

| 리스크 | 영향 | 완화 |
|--------|------|------|
| Garmin 비공식 API 차단 | 높음 | 어댑터 격리 + SmartChip 자동 전환 |
| SmartChip 보간 오차 (+-1km) | 중간 | 3단계 신뢰도 UI + "추정" 레이블 |
| Supabase Free 200 동시 연결 | 높음 | 대회 당일 Pro 전환 (500 연결) + REST 폴백 |
| Kakao Maps API 장애 | 높음 | 텍스트 기반 주자 현황 폴백 (TextRunnerStatus 컴포넌트 존재 확인) |

---

## 9. 차별화 포인트 (경쟁 우위)

1. **제로 프릭션 접근** -- 응원자는 앱 설치도, 로그인도 필요 없다. 공유 링크 한 번 클릭으로 실시간 추적
2. **듀얼 데이터 소스 통합** -- Garmin GPS(고정밀) + SmartChip 매트 통과(범용)를 하나의 인터페이스로 통합
3. **ETA 기반 선제적 알림** -- 단순 위치 표시가 아니라, "3분 후 도착 예정"이라는 행동 가능한 정보를 전달
4. **초경량 인프라 비용** -- 대회 당일만 $25, 나머지는 무료. 소규모 지역 마라톤 대회에 최적화
5. **시뮬레이션 내장** -- 실제 대회 없이도 완전한 시연이 가능한 시뮬레이션 시스템 내장
