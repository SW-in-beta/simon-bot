# CheeR93 환경 점검 리포트

**점검 일시**: 2026-03-12
**프로젝트 경로**: `/Users/simon.lee/projects/cheer93/`

---

## 1. 런타임 환경

| 항목 | 상태 | 값 | 비고 |
|------|------|-----|------|
| Node.js | OK | v25.5.0 | CI에서는 Node 22 사용 (차이 있음) |
| pnpm | OK | 10.32.0 | |
| Supabase CLI | OK | 2.78.0 | |
| Playwright | OK | 1.58.2 | |
| Docker (Rancher Desktop) | OK | 29.1.4-rd | Supabase 로컬 실행 시 필요 |
| TypeScript | OK | 5.x (package.json) | |

---

## 2. 의존성 설치 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| 루트 node_modules | OK | pnpm으로 설치 완료 |
| worker node_modules | OK | pnpm workspace로 설치됨 (`.package-lock.json` 없지만 pnpm이므로 정상) |
| .next (빌드 캐시) | OK | BUILD_ID 존재 (Mar 11 17:18 빌드) |

---

## 3. 환경변수 점검

### 3.1 설정 완료 (OK)

| 변수 | 상태 | 비고 |
|------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | OK | `https://uzfgjfvtabtvgmeshlhm.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | OK | JWT 토큰 설정됨 |
| `SUPABASE_SERVICE_ROLE_KEY` | OK | JWT 토큰 설정됨 |
| `SUPABASE_DB_PASSWORD` | OK | 설정됨 (`.env.local.example`에는 없는 추가 변수) |
| `NEXT_PUBLIC_KAKAO_MAP_KEY` | OK | JavaScript SDK 앱키 설정됨 |
| `VAPID_PUBLIC_KEY` | OK | VAPID 키페어 설정됨 |
| `VAPID_PRIVATE_KEY` | OK | VAPID 키페어 설정됨 |
| `VAPID_SUBJECT` | OK | `mailto:cheer93@example.com` |
| `NEXT_PUBLIC_VAPID_PUBLIC_KEY` | OK | 클라이언트용 VAPID 공개키 |
| `ENCRYPTION_KEY` | OK | 전화번호 암호화 키 설정됨 |

### 3.2 미설정 (주의)

| 변수 | 상태 | 영향 |
|------|------|------|
| `COOLSMS_API_KEY` | 미설정 | SMS 알림 불가 (P3 기능이므로 시연에 영향 없음) |
| `COOLSMS_API_SECRET` | 미설정 | SMS 알림 불가 |
| `COOLSMS_SENDER_NUMBER` | 미설정 | SMS 알림 불가 |

### 3.3 Worker 전용 변수 (별도 확인 필요)

Worker (`worker/src/index.ts`)는 다음 환경변수를 요구한다:

| 변수 | 설정 위치 | 상태 |
|------|-----------|------|
| `SUPABASE_URL` | Worker 환경 | `.env.local`에 `NEXT_PUBLIC_SUPABASE_URL`로만 존재. Worker 실행 시 별도 export 필요 |
| `SUPABASE_SERVICE_ROLE_KEY` | Worker 환경 | `.env.local`에 존재하지만 Worker는 `SUPABASE_URL` (NEXT_PUBLIC_ 접두사 없이) 참조 |
| `SMARTCHIP_XOR_KEY` | Worker 환경 | 기본값 `smartchip2026` 사용 (선택) |

> **주의**: Worker에서 `process.env.SUPABASE_URL`을 참조하는데, `.env.local`에는 `NEXT_PUBLIC_SUPABASE_URL`로 설정되어 있다. Worker 실행 시 `SUPABASE_URL` 환경변수를 별도로 설정해야 한다.

### 3.4 시뮬레이션 스크립트 전용 변수

`scripts/simulation/generate.ts`와 `runner.ts`도 동일하게 `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`를 참조한다 (NEXT_PUBLIC_ 접두사 없이).

---

## 4. 외부 서비스 연결 점검

### 4.1 Supabase API

| 테스트 | 결과 | 비고 |
|--------|------|------|
| REST API 접속 (anon key) | **HTTP 200** | 정상 연결 |
| `races` 테이블 조회 | **빈 배열 `[]`** | 테이블 존재, 데이터 없음 |
| `runners` 테이블 조회 | **빈 배열 `[]`** | 테이블 존재, 데이터 없음 |
| `course_points` 테이블 조회 | **빈 배열 `[]`** | 테이블 존재, 데이터 없음 |

> **결론**: Supabase 연결 정상. 마이그레이션은 적용된 상태이지만 시연 데이터가 없다. 시뮬레이션 스크립트로 데이터 생성 필요.

### 4.2 Kakao Maps API

| 테스트 | 결과 | 비고 |
|--------|------|------|
| REST API 테스트 (keyword 검색) | **HTTP 401** | 예상된 결과. `.env.local`의 키는 JavaScript SDK 앱키이며, REST API 키와 다름. 지도 렌더링은 프론트에서 SDK를 통해 동작하므로 별도 검증은 브라우저에서 필요 |

> **결론**: JavaScript SDK 앱키가 설정되어 있으므로, 실제 지도 동작은 브라우저에서 확인해야 한다.

### 4.3 Web Push (VAPID)

VAPID 키페어가 설정되어 있다. Web Push 발송은 Supabase + VAPID 키로 동작하며, 브라우저에서 Service Worker 등록 후 테스트 가능하다.

---

## 5. 포트 사용 현황

| 포트 | 용도 | 상태 |
|------|------|------|
| **3000** | Next.js 개발 서버 | **사용 중** (node PID 7270이 점유) |
| 54321 | Supabase API (로컬) | 사용 가능 |
| 54322 | Supabase DB (로컬) | 사용 가능 |
| 54323 | Supabase Studio (로컬) | 사용 가능 |

> **주의**: 포트 3000이 이미 사용 중이다. 시연 전 기존 프로세스를 종료하거나, `next dev -p 3001` 등으로 다른 포트를 사용해야 한다.

---

## 6. 코드 품질 점검

### 6.1 테스트 (Vitest)

| 항목 | 결과 |
|------|------|
| 테스트 파일 | **59개 모두 통과** |
| 테스트 케이스 | **480개 모두 통과** |
| 실행 시간 | 33.34초 |

### 6.2 린트 (ESLint)

| 항목 | 결과 |
|------|------|
| 에러 | **0개** |
| 경고 | **3개** (아래 참조) |

경고 내용:
1. `src/app/api/notifications/push/route.ts` - `_eta` 미사용 변수
2. `src/components/race/ReadyShot.tsx` - `<img>` 대신 `<Image />` 사용 권장
3. `src/components/race/RunnerInfo.tsx` - `<img>` 대신 `<Image />` 사용 권장

> **결론**: 시연에 영향 없는 경고 수준.

### 6.3 TypeScript 컴파일

| 항목 | 결과 |
|------|------|
| 컴파일 에러 | **15개** (테스트 파일에서만 발생) |

에러 발생 위치 (모두 테스트 파일):
- `src/__tests__/security/rate-limit.test.ts` - `afterEach` 미선언 (vitest globals 설정 문제)
- `src/app/admin/races/[raceId]/dashboard/__tests__/DashboardClient.test.tsx` - spread argument 타입 에러
- 여러 `__tests__/*.test.tsx` 파일 - `Window & typeof globalThis` 타입 캐스팅 에러
- `src/hooks/__tests__/useRealtimePositions.test.ts` - 튜플 타입 호환성 에러
- `src/lib/kakao/__tests__/maps.test.ts` - Window 타입 캐스팅 에러 (5건)

> **결론**: 모든 TS 에러가 테스트 파일에서만 발생한다. Vitest는 자체적으로 타입 검사 없이 실행하므로 테스트 통과에 영향 없음. 프로덕션 코드는 타입 에러 없음. 시연에 영향 없음.

---

## 7. 시연 준비 체크리스트

### 필수 (시연 전 반드시 수행)

- [ ] **시연 데이터 생성**: DB에 데이터가 없다. 시뮬레이션 스크립트 실행 필요:
  ```bash
  SUPABASE_URL=https://uzfgjfvtabtvgmeshlhm.supabase.co \
  SUPABASE_SERVICE_ROLE_KEY=<서비스롤키> \
  npx tsx scripts/simulation/generate.ts --gpx supabase/seed-course.gpx
  ```
- [ ] **포트 3000 확보**: 현재 점유 중인 프로세스 종료 (`kill 7270`) 또는 다른 포트 사용
- [ ] **개발 서버 시작**: `pnpm dev`
- [ ] **카카오맵 동작 확인**: 브라우저에서 지도 렌더링 되는지 확인 (JavaScript SDK 앱키 유효성)
- [ ] **카카오 OAuth 설정 확인**: Supabase Auth에서 카카오 OAuth Provider가 활성화되어 있는지 Supabase Dashboard에서 확인 필요

### 시연 시 실시간 데이터 재생

시뮬레이션 데이터 생성 후 실시간 재생:
```bash
SUPABASE_URL=https://uzfgjfvtabtvgmeshlhm.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<서비스롤키> \
npx tsx scripts/simulation/runner.ts --speed 10
```
- `--speed 1`: 실시간 (느림)
- `--speed 10`: 10배속 (시연 권장)
- `--speed 60`: 60배속 (빠른 확인)

### 선택 (시연 품질 향상)

- [ ] **Web Push 알림 테스트**: 브라우저에서 알림 권한 허용 후 응원 위치 설정 -> 주자 접근 시 알림 확인
- [ ] **Worker 실행 (선택)**: Worker는 Garmin/SmartChip 데이터를 폴링하는 역할. 시뮬레이션 스크립트가 직접 DB에 쓰므로 시연 시 Worker 없이도 동작 가능
- [ ] **E2E 테스트**: `pnpm test:e2e` (Playwright, 개발 서버 필요)

---

## 8. 잠재적 이슈 및 주의사항

### 8.1 Worker 환경변수 불일치
Worker는 `SUPABASE_URL`을 참조하지만 `.env.local`에는 `NEXT_PUBLIC_SUPABASE_URL`만 있다. Worker를 로컬에서 실행하려면 별도로 `SUPABASE_URL` 환경변수를 설정해야 한다.

### 8.2 Git 리모트 미설정
`git remote -v` 결과가 비어 있다. GitHub 리포지토리 연결이 필요한 경우 별도 설정 필요.

### 8.3 CI vs 로컬 Node.js 버전 차이
- 로컬: Node.js 25.5.0
- CI (ci.yml): Node.js 22

현재 시연에는 영향 없지만, CI 실행 시 호환성 이슈 가능성 있음.

### 8.4 CoolSMS 미설정
SMS 알림 기능(P3)이 동작하지 않는다. 카카오톡 알림톡 관련 기능도 시연 불가.

### 8.5 빈 시드 파일
`supabase/seed.sql`이 비어 있다. 로컬 Supabase 사용 시 `supabase db reset` 후 데이터가 없으므로 시뮬레이션 스크립트로 데이터를 넣어야 한다.

---

## 9. 요약

| 영역 | 판정 | 설명 |
|------|------|------|
| 런타임 환경 | **정상** | Node, pnpm, Supabase CLI 모두 설치됨 |
| 의존성 | **정상** | node_modules 설치 완료 |
| 환경변수 (핵심) | **정상** | Supabase, Kakao, VAPID 모두 설정됨 |
| 환경변수 (부가) | **부분 미설정** | CoolSMS 미설정 (P3, 시연 무관) |
| Supabase 연결 | **정상** | API 200, 테이블 존재 확인 |
| 시연 데이터 | **없음** | 시뮬레이션 스크립트 실행 필요 |
| 테스트 | **정상** | 59 파일, 480 케이스 전수 통과 |
| 린트 | **정상** | 에러 0, 경고 3 (시연 무관) |
| 포트 | **충돌** | 3000번 포트 사용 중, 해제 필요 |

**총평**: 환경 세팅은 대체로 양호하다. 시연을 위해 (1) 포트 3000 확보, (2) 시뮬레이션 데이터 생성 두 가지만 수행하면 즉시 시연 가능한 상태다.
