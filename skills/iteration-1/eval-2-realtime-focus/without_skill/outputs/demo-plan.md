# cheer93 데모 계획 - 실시간 위치 추적 & 응원 기능

## 데모 목표

외부 API(Garmin, SmartChip) 없이 **로컬 환경에서 실시간 위치 추적과 응원 알림 기능을 라이브로 시연**할 수 있는 환경을 구축한다.

---

## 1. 사전 준비

### 1.1 환경 구성

```bash
# Supabase 로컬 시작
cd /Users/simon.lee/projects/cheer93
npx supabase start

# 환경변수 설정 (.env.local)
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<supabase start 출력값>
SUPABASE_SERVICE_ROLE_KEY=<supabase start 출력값>
NEXT_PUBLIC_KAKAO_MAP_KEY=<카카오맵 JavaScript 키>
VAPID_SUBJECT=mailto:demo@cheer93.kr
VAPID_PUBLIC_KEY=<web-push generate-vapid-keys>
VAPID_PRIVATE_KEY=<web-push generate-vapid-keys>
```

### 1.2 마이그레이션 적용

```bash
npx supabase db reset  # 모든 마이그레이션 적용
```

---

## 2. 더미 데이터 전략

### 2.1 시드 데이터 SQL

외부 API 의존 없이 데모하려면 DB에 직접 더미 데이터를 넣고, Worker 대신 시뮬레이터 스크립트로 위치를 업데이트해야 한다.

```sql
-- ===== 1. 대회 생성 =====
INSERT INTO races (id, name, race_date, status, smartchip_id, total_distance_km)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  '2026 서울 마라톤 데모',
  '2026-03-15',
  'live',           -- 데모용으로 바로 live 상태
  'demo2026',
  5.00
);

-- ===== 2. 관리자 프로필 =====
-- (Supabase auth.users에 테스트 유저 필요; 로컬에서는 supabase dashboard에서 생성)
-- 프로필은 auth trigger로 자동 생성된다고 가정

-- ===== 3. 코스 포인트 (seed-course.gpx 기반) =====
-- GPX 파서가 생성하는 것과 동일한 course_points
-- 서울시청 -> 광화문 -> 경복궁 -> 서대문 (약 5km, 50개 포인트)
-- 아래는 주요 지점만 발췌, 전체는 GPX 업로드 API로 생성 권장

INSERT INTO course_points (race_id, km, lat, lng, cumulative_distance, seq) VALUES
('11111111-1111-1111-1111-111111111111', 0.000, 37.56650, 126.97784, 0, 0),
('11111111-1111-1111-1111-111111111111', 0.056, 37.56700, 126.97782, 55.60, 1),
('11111111-1111-1111-1111-111111111111', 0.133, 37.56770, 126.97778, 133.39, 2),
('11111111-1111-1111-1111-111111111111', 0.222, 37.56850, 126.97774, 222.32, 3),
('11111111-1111-1111-1111-111111111111', 0.311, 37.56930, 126.97770, 311.25, 4),
('11111111-1111-1111-1111-111111111111', 0.400, 37.57010, 126.97766, 400.18, 5),
('11111111-1111-1111-1111-111111111111', 0.500, 37.57100, 126.97760, 500.11, 6),
('11111111-1111-1111-1111-111111111111', 0.611, 37.57200, 126.97754, 611.15, 7),
('11111111-1111-1111-1111-111111111111', 0.722, 37.57300, 126.97748, 722.20, 8),
('11111111-1111-1111-1111-111111111111', 0.833, 37.57400, 126.97740, 833.25, 9),
('11111111-1111-1111-1111-111111111111', 0.944, 37.57500, 126.97732, 944.30, 10),
('11111111-1111-1111-1111-111111111111', 1.055, 37.57600, 126.97724, 1055.35, 11),
('11111111-1111-1111-1111-111111111111', 1.166, 37.57700, 126.97716, 1166.40, 12),
('11111111-1111-1111-1111-111111111111', 1.277, 37.57800, 126.97708, 1277.45, 13),
('11111111-1111-1111-1111-111111111111', 1.388, 37.57900, 126.97700, 1388.50, 14),
('11111111-1111-1111-1111-111111111111', 1.500, 37.58000, 126.97690, 1500.00, 15),
('11111111-1111-1111-1111-111111111111', 1.611, 37.58100, 126.97680, 1611.00, 16),
('11111111-1111-1111-1111-111111111111', 1.722, 37.58200, 126.97668, 1722.00, 17),
('11111111-1111-1111-1111-111111111111', 1.833, 37.58300, 126.97656, 1833.00, 18),
('11111111-1111-1111-1111-111111111111', 1.944, 37.58400, 126.97644, 1944.00, 19),
('11111111-1111-1111-1111-111111111111', 2.050, 37.58420, 126.97540, 2050.00, 20),
('11111111-1111-1111-1111-111111111111', 2.160, 37.58430, 126.97430, 2160.00, 21),
('11111111-1111-1111-1111-111111111111', 2.270, 37.58435, 126.97320, 2270.00, 22),
('11111111-1111-1111-1111-111111111111', 2.380, 37.58440, 126.97210, 2380.00, 23),
('11111111-1111-1111-1111-111111111111', 2.490, 37.58440, 126.97100, 2490.00, 24),
('11111111-1111-1111-1111-111111111111', 2.600, 37.58435, 126.96990, 2600.00, 25),
('11111111-1111-1111-1111-111111111111', 2.710, 37.58430, 126.96880, 2710.00, 26),
('11111111-1111-1111-1111-111111111111', 2.820, 37.58420, 126.96770, 2820.00, 27),
('11111111-1111-1111-1111-111111111111', 2.930, 37.58400, 126.96660, 2930.00, 28),
('11111111-1111-1111-1111-111111111111', 3.040, 37.58380, 126.96550, 3040.00, 29),
('11111111-1111-1111-1111-111111111111', 3.150, 37.58300, 126.96460, 3150.00, 30),
('11111111-1111-1111-1111-111111111111', 3.260, 37.58200, 126.96380, 3260.00, 31),
('11111111-1111-1111-1111-111111111111', 3.370, 37.58100, 126.96300, 3370.00, 32),
('11111111-1111-1111-1111-111111111111', 3.480, 37.58000, 126.96220, 3480.00, 33),
('11111111-1111-1111-1111-111111111111', 3.590, 37.57900, 126.96140, 3590.00, 34),
('11111111-1111-1111-1111-111111111111', 3.700, 37.57800, 126.96060, 3700.00, 35),
('11111111-1111-1111-1111-111111111111', 3.810, 37.57700, 126.95980, 3810.00, 36),
('11111111-1111-1111-1111-111111111111', 3.920, 37.57600, 126.95900, 3920.00, 37),
('11111111-1111-1111-1111-111111111111', 4.030, 37.57500, 126.95820, 4030.00, 38),
('11111111-1111-1111-1111-111111111111', 4.140, 37.57400, 126.95740, 4140.00, 39),
('11111111-1111-1111-1111-111111111111', 4.250, 37.57300, 126.95660, 4250.00, 40),
('11111111-1111-1111-1111-111111111111', 4.360, 37.57200, 126.95580, 4360.00, 41),
('11111111-1111-1111-1111-111111111111', 4.470, 37.57100, 126.95500, 4470.00, 42),
('11111111-1111-1111-1111-111111111111', 4.580, 37.57000, 126.95420, 4580.00, 43),
('11111111-1111-1111-1111-111111111111', 4.690, 37.56900, 126.95340, 4690.00, 44),
('11111111-1111-1111-1111-111111111111', 4.800, 37.56800, 126.95260, 4800.00, 45),
('11111111-1111-1111-1111-111111111111', 4.910, 37.56700, 126.95180, 4910.00, 46),
('11111111-1111-1111-1111-111111111111', 5.000, 37.56600, 126.95100, 5000.00, 47);

-- ===== 4. 주자 프로필 (auth 없이는 profiles에 직접 INSERT 필요) =====
-- Supabase 로컬에서 테스트 유저 3명 생성 후 UUID 기입
-- 또는 RLS를 임시 비활성화하고 직접 INSERT

-- 예시 UUID (실제 auth.users의 id로 교체 필요)
INSERT INTO profiles (id, display_name) VALUES
('aaaa0001-0001-0001-0001-000000000001', '김민수'),
('aaaa0002-0002-0002-0002-000000000002', '이서연'),
('aaaa0003-0003-0003-0003-000000000003', '박지훈')
ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;

-- ===== 5. 주자 등록 =====
INSERT INTO runners (id, race_id, user_id, bib_number, status, location_consent, data_source) VALUES
('bbbb0001-0001-0001-0001-000000000001', '11111111-1111-1111-1111-111111111111', 'aaaa0001-0001-0001-0001-000000000001', '93', 'running', true, 'garmin'),
('bbbb0002-0002-0002-0002-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaa0002-0002-0002-0002-000000000002', '42', 'running', true, 'smartchip'),
('bbbb0003-0003-0003-0003-000000000003', '11111111-1111-1111-1111-111111111111', 'aaaa0003-0003-0003-0003-000000000003', '7', 'running', true, 'smartchip');

-- ===== 6. 초기 위치 (runner_current_positions) =====
INSERT INTO runner_current_positions (runner_id, race_id, lat, lng, current_pace, current_km, confidence) VALUES
('bbbb0001-0001-0001-0001-000000000001', '11111111-1111-1111-1111-111111111111', 37.57200, 126.97754, 300, 0.611, 'high'),
('bbbb0002-0002-0002-0002-000000000002', '11111111-1111-1111-1111-111111111111', 37.56930, 126.97770, 330, 0.311, 'medium'),
('bbbb0003-0003-0003-0003-000000000003', '11111111-1111-1111-1111-111111111111', 37.56770, 126.97778, 360, 0.133, 'high');

-- ===== 7. 관전자 (데모용) =====
INSERT INTO spectators (id, race_id, session_token, nickname, cheer_lat, cheer_lng, cheer_km)
VALUES (
  'cccc0001-0001-0001-0001-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'demo-session-token-001',
  '서울 응원단',
  37.57500, 126.97732, 0.944  -- 광화문 광장 부근 (약 1km 지점)
);
```

### 2.2 데모 시뮬레이터 스크립트

Worker를 대체하여 Supabase에 직접 위치를 업데이트하고 브로드캐스트하는 스크립트.

```typescript
// scripts/demo-simulator.ts
// 실행: npx tsx scripts/demo-simulator.ts

import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = process.env.SUPABASE_URL ?? 'http://127.0.0.1:54321'
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY ?? '<키>'

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

const RACE_ID = '11111111-1111-1111-1111-111111111111'
const CHANNEL = `race:${RACE_ID}`

// 코스 포인트 (간략화 - 실제로는 DB에서 조회)
const COURSE_POINTS = [
  { km: 0.000, lat: 37.56650, lng: 126.97784 },
  { km: 0.500, lat: 37.57100, lng: 126.97760 },
  { km: 1.000, lat: 37.57500, lng: 126.97732 },
  { km: 1.500, lat: 37.58000, lng: 126.97690 },
  { km: 2.000, lat: 37.58400, lng: 126.97644 },
  { km: 2.500, lat: 37.58440, lng: 126.97100 },
  { km: 3.000, lat: 37.58380, lng: 126.96550 },
  { km: 3.500, lat: 37.58000, lng: 126.96220 },
  { km: 4.000, lat: 37.57500, lng: 126.95820 },
  { km: 4.500, lat: 37.57000, lng: 126.95420 },
  { km: 5.000, lat: 37.56600, lng: 126.95100 },
]

interface SimRunner {
  id: string
  name: string
  bib: string
  paceSecPerKm: number   // 초/km
  currentKm: number
  confidence: 'high' | 'medium' | 'low'
  source: 'garmin' | 'smartchip'
}

const runners: SimRunner[] = [
  { id: 'bbbb0001-0001-0001-0001-000000000001', name: '김민수', bib: '93', paceSecPerKm: 300, currentKm: 0.611, confidence: 'high', source: 'garmin' },
  { id: 'bbbb0002-0002-0002-0002-000000000002', name: '이서연', bib: '42', paceSecPerKm: 330, currentKm: 0.311, confidence: 'medium', source: 'smartchip' },
  { id: 'bbbb0003-0003-0003-0003-000000000003', name: '박지훈', bib: '7', paceSecPerKm: 360, currentKm: 0.133, confidence: 'high', source: 'smartchip' },
]

function interpolate(km: number): { lat: number; lng: number } {
  if (km <= 0) return COURSE_POINTS[0]
  if (km >= 5) return COURSE_POINTS[COURSE_POINTS.length - 1]

  let lo = 0
  for (let i = 0; i < COURSE_POINTS.length - 1; i++) {
    if (COURSE_POINTS[i].km <= km && COURSE_POINTS[i + 1].km > km) {
      lo = i
      break
    }
  }

  const p1 = COURSE_POINTS[lo]
  const p2 = COURSE_POINTS[lo + 1]
  const ratio = (km - p1.km) / (p2.km - p1.km)

  return {
    lat: p1.lat + (p2.lat - p1.lat) * ratio,
    lng: p1.lng + (p2.lng - p1.lng) * ratio,
  }
}

const TICK_INTERVAL_MS = 5000  // 데모용: 5초마다 업데이트 (실제 서비스는 30초)

async function tick() {
  const now = new Date().toISOString()
  const positions = []

  for (const runner of runners) {
    // 5초 동안 이동한 거리 (km)
    const kmPerTick = (TICK_INTERVAL_MS / 1000) / runner.paceSecPerKm
    runner.currentKm = Math.min(5.0, runner.currentKm + kmPerTick)

    const coord = interpolate(runner.currentKm)

    positions.push({
      runnerId: runner.id,
      lat: coord.lat,
      lng: coord.lng,
      currentKm: Math.round(runner.currentKm * 100) / 100,
      currentPace: runner.paceSecPerKm,
      confidence: runner.confidence,
      source: runner.source,
      timestamp: now,
    })

    // DB 업데이트
    await supabase.from('runner_current_positions').upsert({
      runner_id: runner.id,
      race_id: RACE_ID,
      lat: coord.lat,
      lng: coord.lng,
      current_pace: runner.paceSecPerKm,
      current_km: Math.round(runner.currentKm * 100) / 100,
      confidence: runner.confidence,
    }, { onConflict: 'runner_id' })

    // 이력 저장
    await supabase.from('tracking_positions').insert({
      runner_id: runner.id,
      race_id: RACE_ID,
      lat: coord.lat,
      lng: coord.lng,
      speed: 1000 / runner.paceSecPerKm,
      source: runner.source,
      recorded_at: now,
    })
  }

  // 브로드캐스트
  const channel = supabase.channel(CHANNEL)
  await channel.send({
    type: 'broadcast',
    event: 'position_update',
    payload: { runners: positions },
  })

  const kmLine = runners.map(r => `${r.name}(#${r.bib}): ${r.currentKm.toFixed(2)}km`).join(' | ')
  console.log(`[${new Date().toLocaleTimeString()}] ${kmLine}`)

  // 스플릿 감지 (정수 km 교차 시)
  for (const runner of runners) {
    const prevKm = runner.currentKm - (TICK_INTERVAL_MS / 1000) / runner.paceSecPerKm
    const currentFloor = Math.floor(runner.currentKm)
    const prevFloor = Math.floor(prevKm)
    if (currentFloor > prevFloor && currentFloor > 0) {
      const splitKm = currentFloor
      const cumulativeSeconds = splitKm * runner.paceSecPerKm
      await channel.send({
        type: 'broadcast',
        event: 'split_update',
        payload: {
          runnerId: runner.id,
          km: splitKm,
          splitTime: runner.paceSecPerKm,
          splitPace: runner.paceSecPerKm,
          cumulativeTime: cumulativeSeconds,
        },
      })
      console.log(`  >> 스플릿: ${runner.name} ${splitKm}km 통과!`)
    }
  }

  // 5km 완주 체크
  for (const runner of runners) {
    if (runner.currentKm >= 5.0) {
      console.log(`  >> ${runner.name} 완주!`)
    }
  }
}

console.log('=== cheer93 데모 시뮬레이터 시작 ===')
console.log(`대회: ${RACE_ID}`)
console.log(`주자: ${runners.map(r => `${r.name}(#${r.bib}, ${r.paceSecPerKm}초/km)`).join(', ')}`)
console.log(`업데이트 간격: ${TICK_INTERVAL_MS / 1000}초`)
console.log('---')

const interval = setInterval(async () => {
  await tick()
  if (runners.every(r => r.currentKm >= 5.0)) {
    console.log('\n=== 모든 주자 완주! 시뮬레이터 종료 ===')
    clearInterval(interval)
    process.exit(0)
  }
}, TICK_INTERVAL_MS)

tick()  // 즉시 첫 tick 실행
```

### 2.3 더미 데이터 특징

| 주자 | 배번 | 페이스 | 소스 | 5km 예상 소요시간 |
|------|------|--------|------|-------------------|
| 김민수 | #93 | 5'00"/km (300초) | Garmin (high) | 25분 |
| 이서연 | #42 | 5'30"/km (330초) | SmartChip (medium) | 27.5분 |
| 박지훈 | #7 | 6'00"/km (360초) | SmartChip (high) | 30분 |

- 관전자 응원 위치: 광화문 광장 (약 1km 지점) -> 주자가 접근하면 알림 트리거 확인 가능
- 시뮬레이터 5초 간격으로 업데이트 (실제 30초보다 빠르게 데모 진행)
- 약 2.5~5분 내에 모든 주자가 완주하는 타임라인

---

## 3. 데모 시나리오 (총 약 10분)

### Act 1: 설정 및 컨텍스트 (2분)

**화면**: 관리자 대시보드

1. 프로젝트 소개: "cheer93은 마라톤 응원 서비스입니다. 주자의 실시간 위치를 관중에게 보여주고, 주자가 가까이 오면 알림을 보냅니다."
2. 관리자 대시보드 (`/admin/races/{raceId}/dashboard`) 표시:
   - 6개 통계 카드 (활주 중: 3, Garmin: 1, SmartChip: 2)
   - "대회가 이미 live 상태입니다"

### Act 2: 실시간 위치 추적 데모 (4분)

**화면**: 관전자 지도 (2개 디바이스 또는 브라우저 탭)

1. **시뮬레이터 시작**: 터미널에서 `npx tsx scripts/demo-simulator.ts` 실행
2. **관전자 화면 오픈**: `/race/demo2026` 접속
3. 시연 포인트:
   - **ConnectionStatus**: 상단 연결 상태 표시 확인 (connected 시 사라짐)
   - **코스 polyline**: 서울시청-광화문-경복궁-서대문 코스 표시
   - **RunnerMarker 3개**: 배번/이름/페이스 라벨과 함께 이동
     - #93 김민수: 실선 마커 (Garmin, high confidence)
     - #42 이서연: 점선 마커 (SmartChip, medium confidence)
     - #7 박지훈: 실선 마커 (SmartChip, high confidence -> 시간 경과 시 medium으로 전환 시연 가능)
   - **lerp 애니메이션**: 마커가 2초간 부드럽게 이동하는 것 확인
   - **BottomSheet**: 드래그해서 올려 RunnerList 확인 (현재 km, 페이스 실시간 갱신)
4. **수동 새로고침**: 플로팅 버튼 클릭 -> DB에서 최신 위치 다시 로드

### Act 3: 응원 기능 데모 (3분)

**화면**: 관전자 지도 + 응원 위치 설정

1. **응원 위치 설정**:
   - CheerLocationForm에서 km 수동입력 "1" 입력 -> 광화문 광장 1km 지점 매핑
   - 또는 GPS 자동감지 (데모 환경에서는 수동입력이 안정적)
2. **접근 알림 트리거 대기**:
   - 시뮬레이터가 진행되며 김민수(#93)가 1km 지점에 접근
   - ETA < 180초(3분) 시 ApproachAlert 배너 등장
   - "#93 김민수 - 약 2분 후 도착 예정 [추정]" 배너 확인
3. **알림 동작 시연**:
   - 배너 클릭 -> 지도가 해당 주자 위치로 포커스
   - 배너 X 버튼 -> 닫기
   - 5초 후 자동 최소화 -> MiniBadge 표시
   - 나머지 주자(이서연, 박지훈)도 순차적으로 알림 도착

### Act 4: 관리자 관점 + 마무리 (1분)

**화면**: 관리자 대시보드

1. 대시보드의 실시간 통계 변화 확인 (평균 페이스 갱신)
2. 스플릿 기록: "김민수 1km 통과!" 같은 로그 확인
3. "이것이 cheer93의 실시간 추적과 응원 알림 기능입니다" 마무리

---

## 4. 데모 실행 체크리스트

### 사전 준비 (D-1)

- [ ] Supabase 로컬 인스턴스 구동 확인 (`npx supabase status`)
- [ ] 마이그레이션 적용 (`npx supabase db reset`)
- [ ] 더미 데이터 SQL 실행 (auth.users 생성 -> profiles 자동 생성 -> 나머지 테이블)
- [ ] 카카오맵 API 키 유효성 확인
- [ ] `pnpm install` + `pnpm dev` 로컬 구동 확인
- [ ] 시뮬레이터 스크립트 단독 실행 테스트
- [ ] 브라우저 2개 탭: 관리자 대시보드 + 관전자 지도

### 데모 당일

- [ ] Supabase 시작
- [ ] Next.js dev 서버 시작 (`pnpm dev`)
- [ ] 관전자 화면 접속 확인 (`http://localhost:3000/race/demo2026`)
- [ ] 관리자 대시보드 접속 확인
- [ ] 시뮬레이터 실행 (`npx tsx scripts/demo-simulator.ts`)
- [ ] 마커 이동 및 알림 동작 확인

### 비상 대비

- **카카오맵 로딩 실패 시**: NEXT_PUBLIC_KAKAO_MAP_KEY 재확인, 허용 도메인에 localhost 추가
- **Realtime 연결 안 될 시**: Supabase 로컬의 Realtime 기능 활성화 확인 (`config.toml`의 `[realtime]` 섹션)
- **시뮬레이터 브로드캐스트 실패 시**: SUPABASE_SERVICE_ROLE_KEY 확인, channel 이름 `race:{RACE_ID}` 일치 확인
- **마커 안 보일 시**: runner의 `location_consent = true` 확인, `runner_current_positions`에 데이터 존재 확인

---

## 5. 시연 시 강조할 기술 포인트

1. **Supabase Broadcast 기반 실시간 통신**: PostgreSQL DB 변경 감지가 아닌 Worker -> Broadcast Channel -> Client 직접 전달. DB write와 실시간 전달 분리.

2. **이중 보간 전략**: 서버(SmartChip 매트 -> 코스 좌표 보간) + 클라이언트(30초 간격 -> 2초 lerp 애니메이션). 데이터 갱신 주기의 한계를 UX로 극복.

3. **Confidence 시각화**: Garmin GPS(high) vs SmartChip 추정(medium/low) 데이터 품질을 마커 스타일로 직관적 표현.

4. **ETA 기반 알림**: 단순 거리가 아닌 "현재 페이스 기반 도착 예상 시간" 계산. `(cheerKm - currentKm) * currentPace`.

5. **익명 세션 관전**: 로그인 없이 smartchip_id 공유 링크만으로 관전 가능. 마라톤 현장에서 QR 코드 배포 시나리오.
