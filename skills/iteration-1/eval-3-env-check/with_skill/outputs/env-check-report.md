# 환경 점검 보고서: CheeR93

점검 일시: 2026-03-12
프로젝트 경로: `/Users/simon.lee/projects/cheer93/`

---

## 1. 환경 변수 검증

### 설정 완료 (9/12)

| 변수 | 상태 | 검증 방법 |
|------|------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | ✅ 설정됨 | `.env.local` 확인 — `https://uzfgjfvtabtvgmeshlhm.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | ✅ 설정됨 | JWT 형식 확인, REST API 200 응답 |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ 설정됨 | JWT 형식 확인 |
| `NEXT_PUBLIC_KAKAO_MAP_KEY` | ✅ 설정됨 | JavaScript SDK 앱키 형식 (`1383447e...`) — JS SDK용 키는 REST API 인증과 다르므로 브라우저 렌더링 시 확인 필요 |
| `VAPID_PUBLIC_KEY` | ✅ 설정됨 | Base64url 형식 확인 |
| `VAPID_PRIVATE_KEY` | ✅ 설정됨 | Base64url 형식 확인 |
| `VAPID_SUBJECT` | ✅ 설정됨 | `mailto:cheer93@example.com` |
| `NEXT_PUBLIC_VAPID_PUBLIC_KEY` | ✅ 설정됨 | `VAPID_PUBLIC_KEY`와 동일 값 |
| `ENCRYPTION_KEY` | ✅ 설정됨 | 64자 hex 문자열 확인 |

### 미설정 (3/12)

| 변수 | 상태 | 영향 범위 |
|------|------|----------|
| `COOLSMS_API_KEY` | ❌ 빈 값 | SMS 알림 발송 불가 |
| `COOLSMS_API_SECRET` | ❌ 빈 값 | SMS 알림 발송 불가 |
| `COOLSMS_SENDER_NUMBER` | ❌ 빈 값 | SMS 알림 발송 불가 |

### 추가 확인된 변수

| 변수 | 상태 | 비고 |
|------|------|------|
| `SUPABASE_DB_PASSWORD` | ✅ 설정됨 | `.env.local.example`에는 없지만 `.env.local`에 설정됨 |

---

## 2. 인프라 상태 확인

### Supabase (클라우드)

| 항목 | 상태 | 상세 |
|------|------|------|
| REST API | ✅ 정상 | `https://uzfgjfvtabtvgmeshlhm.supabase.co/rest/v1/` → HTTP 200 |
| Auth | ✅ 정상 | `/auth/v1/health` → HTTP 200 |
| Realtime | ✅ 정상 | `/realtime/v1/websocket` → HTTP 401 (인증 필요 = 서비스 자체는 동작) |
| Storage | ✅ 정상 | `/storage/v1/` → HTTP 404 (루트 경로 미존재 = 서비스 자체는 동작) |

**Supabase 로컬 (supabase CLI)**:
- 상태: ❌ 미실행 (`supabase status` → "No such container: supabase_db_cheer93")
- 비고: 이 프로젝트는 클라우드 Supabase를 사용하므로 로컬 Supabase는 필수가 아님. `.env.local`의 URL이 클라우드를 가리킴.

### Docker

| 항목 | 상태 |
|------|------|
| Docker Desktop/Rancher | ✅ 실행 중 (`docker info` 성공) |
| docker-compose.yml | ℹ️ 없음 (DB 등 인프라를 Docker로 관리하지 않음 — Supabase 클라우드 사용) |

### Worker (Fly.io)

| 항목 | 상태 | 상세 |
|------|------|------|
| 소스 코드 | ✅ 존재 | `worker/src/` — index.ts, poller.ts, broadcaster.ts 등 |
| 의존성 | ⚠️ 미설치 | `worker/node_modules/` 내 패키지 0개 |
| 환경 변수 | ⚠️ 미설정 | `worker/.env` 파일 없음 |
| Fly.io 배포 | ℹ️ 미확인 | `fly.toml` 존재하지만 배포 상태 미확인 |

---

## 3. 포트 가용성

| 포트 | 상태 | 상세 |
|------|------|------|
| 3000 | ❌ 점유 중 | PID 7270 (`node`) — **다른 프로젝트("InstaClone")가 실행 중** |

**상세 분석**: `curl http://localhost:3000` 응답에서 `<title>InstaClone</title>` 확인. CheeR93 프로젝트가 아닌 다른 Next.js 앱이 포트 3000을 점유하고 있음.

---

## 4. Node.js 버전

| 항목 | 값 | 비고 |
|------|-----|------|
| 현재 시스템 | v25.5.0 | |
| Dockerfile 지정 | node:20-alpine | Worker용 |
| .nvmrc / .node-version | 없음 | 버전 제약 미지정 |
| package.json engines | 없음 | 버전 제약 미지정 |

**평가**: Node.js 25.x는 최신 Nightly/Current 버전으로, 프로젝트의 Dockerfile은 node:20을 사용. Next.js 15.x는 Node.js 18.x 이상을 요구하므로 25.x에서도 동작하지만, 일부 호환성 이슈 가능성 있음.

---

## 5. 의존성 설치 상태

| 항목 | 상태 | 상세 |
|------|------|------|
| 루트 `node_modules/` | ✅ 설치됨 | 773개 패키지 |
| `pnpm-lock.yaml` | ✅ 존재 | |
| `.next/` 빌드 | ✅ 존재 | BUILD_ID: `_kAf6XX1MMV-fn14Qf48n` (2025-03-11 빌드) |
| Playwright 브라우저 | ✅ 설치됨 | chromium-1208, chromium_headless_shell-1208 |
| Worker 의존성 | ⚠️ 미설치 | `worker/node_modules/` 패키지 0개 |

---

## 6. 시드 데이터

| 항목 | 상태 |
|------|------|
| `supabase/seed.sql` | ⚠️ 비어있음 (0 bytes) |
| `supabase/seed-course.gpx` | ✅ 존재 (3919 bytes — 시뮬레이션용 코스) |
| 시뮬레이션 스크립트 | ✅ 존재 (`scripts/simulation/generate.ts`, `runner.ts` 등) |

---

## 7. E2E 테스트 인프라

| 항목 | 상태 |
|------|------|
| `playwright.config.ts` | ✅ 존재 — baseURL: `http://localhost:3000` |
| E2E 테스트 파일 | ✅ 5개 (admin-flow, cheer-alert, race-finish, spectator-map, split-records) |
| 테스트 fixture | ✅ `e2e/fixtures/auth.ts`, `e2e/fixtures/test-helpers.ts` |
| Playwright 브라우저 | ✅ chromium 설치됨 |

---

## 종합 점검 결과

```
✅ 환경 변수: 9/12 설정됨
✅ Supabase 클라우드: REST API, Auth, Realtime 모두 정상
✅ Docker: 실행 중
✅ 루트 의존성: 설치 완료 (773개 패키지)
✅ Next.js 빌드: 존재 (프로덕션 빌드 가능)
✅ Playwright: 브라우저 설치 완료 (chromium-1208)
✅ E2E 테스트: 5개 테스트 + fixture 준비
✅ 시뮬레이션 스크립트: 존재
✅ GPX 코스 데이터: 시드 파일 존재

⚠️ CoolSMS API 키 3개: 미설정
   → 선택 1: API 키를 지금 설정 (export COOLSMS_API_KEY=..., COOLSMS_API_SECRET=..., COOLSMS_SENDER_NUMBER=...)
   → 선택 2: SMS 알림 엔드포인트(/api/notifications/sms)를 모킹하여 시연 (SMS 발송을 시뮬레이션)
   → 선택 3: SMS 알림 관련 시나리오를 시연에서 제외 (인앱 + Web Push만 시연)

⚠️ Worker 의존성: 미설치
   → 조치: `pnpm --filter cheer93-worker install` 실행 필요
   → 시연에서 Worker를 로컬로 실행할 경우에만 필요. 시뮬레이션 스크립트로 대체 가능.

⚠️ Worker 환경 변수: worker/.env 미존재
   → 조치: Worker에 SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY 등 설정 필요
   → 시뮬레이션 스크립트 사용 시 불필요

⚠️ seed.sql 비어있음: 시연용 더미 데이터 별도 생성 필요
   → 조치: 시뮬레이션 스크립트(`scripts/simulation/generate.ts`) 활용 또는 수동 시드

⚠️ Node.js 버전 불일치: 시스템 v25.5.0 vs Dockerfile node:20
   → 경고 수준. 로컬 개발에서는 대부분 문제없지만, Worker 빌드 시 차이 발생 가능.

❌ 포트 3000 점유: 다른 프로젝트(InstaClone, PID 7270)가 실행 중
   → 선택 1: 해당 프로세스를 종료 (kill 7270)
   → 선택 2: CheeR93을 다른 포트로 실행 (PORT=3001 pnpm dev)
   → 주의: Playwright config의 baseURL이 localhost:3000으로 고정되어 있으므로, 포트 변경 시 config 수정 또는 프로세스 종료 권장
```

---

## 필수 조치 사항 (시연 전 반드시 해결)

### ❌ 포트 3000 점유 해소
포트 3000에서 다른 프로젝트가 실행 중. 시연을 위해 반드시 해결 필요.

**권장 조치**: `kill 7270`으로 InstaClone 프로세스 종료 후 CheeR93 기동.

**이유**: Playwright config(`playwright.config.ts`)에서 `baseURL: 'http://localhost:3000'`으로 하드코딩되어 있고, `webServer.command`도 `pnpm dev`로 설정. 포트를 변경하면 E2E 테스트와 시연 스크립트 모두 수정이 필요.

---

## 선택 조치 사항 (사용자 결정 필요)

### ⚠️ CoolSMS API 키 미설정
SMS 알림 기능(US-7.2)을 시연하려면 3가지 옵션 중 선택 필요.

**권장**: 선택 2 (모킹) — SMS 발송 응답을 모킹하여 시연. 실제 SMS 발송 없이도 알림 플로우를 보여줄 수 있음.

### ⚠️ Worker 로컬 실행 여부
시연에서 실시간 위치 추적을 보여주려면:
- **옵션 A**: Worker 로컬 실행 (의존성 설치 + .env 설정 필요)
- **옵션 B**: 시뮬레이션 스크립트로 직접 DB에 위치 데이터 삽입 + Realtime Broadcast (Worker 불필요)

**권장**: 옵션 B — 시뮬레이션 스크립트(`scripts/simulation/`)가 이미 존재하고, 외부 API(Garmin/SmartChip) 의존 없이 동작.

---

## 환경 점검 요약

| 카테고리 | 총 항목 | ✅ | ⚠️ | ❌ |
|---------|--------|-----|-----|-----|
| 환경 변수 | 12 | 9 | 0 | 3 (CoolSMS) |
| 인프라 | 5 | 4 | 0 | 1 (포트 점유) |
| 의존성 | 4 | 3 | 1 (Worker) | 0 |
| 데이터 | 2 | 1 | 1 (seed.sql 빈 파일) | 0 |
| **합계** | **23** | **17** | **2** | **4** |

**결론**: ❌ 항목 1개(포트 3000 점유)를 해결하고, ⚠️ 항목에 대한 사용자 결정이 내려지면 시연 준비를 진행할 수 있다.
