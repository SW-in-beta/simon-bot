# Review Rubric (리뷰 판정 기준)

모든 검증 단계(Step 6, 7, 17)에서 공통으로 참조하는 판정 기준 문서.

## Severity 판정 기준

| Severity | 기준 | 예시 |
|----------|------|------|
| **CRITICAL** | 프로덕션 데이터 손실, 보안 경계 파괴, 서비스 전체 장애 가능. "지금 수정하지 않으면 사고가 날 수 있는" 수준 | SQL injection 취약점, 인증 우회(체크 제거), 무한 루프로 서비스 다운, 암호화 키 평문 노출, 마이그레이션에서 NOT NULL 컬럼 데이터 유실 |
| **HIGH** | 특정 조건에서 오동작, 성능 심각 저하, 기능의 실질적 결함. 사용자에게 직접 잘못된 결과가 노출됨 | 동시성 버그(race condition), N+1 쿼리, 캐시 무효화 누락으로 stale data 표시, 에러 처리 누락으로 데이터 불일치, 런타임 타입 불일치 |
| **MEDIUM** | 코드 품질 저하, 컨벤션 불일치, 잠재적 문제. 즉시 장애 없음 | 네이밍 불일치, 불필요한 복잡성, 테스트 커버리지 부족, 컴파일 타임에 잡히는 타입 문제, 누락된 로깅 |

**경계 사례 판단 원칙:**
- 단순 성능 저하나 코드 스타일 문제는 CRITICAL이 아니다
- "모든 요청에서 발생" → CRITICAL/HIGH, "특정 조건에서만" → HIGH/MEDIUM
- 컴파일 타임 감지 → MEDIUM, 런타임에만 드러남 → HIGH
- 데이터 손실 없고 시간이 지나면 자연 해소 → HIGH (CRITICAL 아님)

## Finding 품질 기준 (전 Step 공통)

> "구체적 근거가 있는 5건이 모호한 설명의 20건보다 낫다."

### 필수 요소

각 finding은 반드시 아래 요소를 포함한다:

1. **구체적 코드 위치**: `파일:줄` 형식 (예: `internal/auth/handler.go:47`)
2. **근거**: 추측이 아닌 증거. OBSERVE → TRACE → HYPOTHESIZE → VERIFY 프로세스를 거친 결과
3. **영향 범위**: 어떤 엔드포인트/모듈/사용자가 영향받는지 구체적 명시
4. **수정 방향**: 구체적 수정 방안 (`RECOMMENDATION` 필드)

### 품질 원칙

- **깊이 > 수량**: 5건의 정밀한 finding이 20건의 피상적 finding보다 우선
- **증거 기반**: VERIFY 없이 HYPOTHESIZE만으로 finding을 작성하지 않는다
- **Scope 준수**: 변경하지 않은 코드에 대한 일반 조언은 포함하지 않는다
- **핵심 우선**: 핵심 비즈니스 로직 > 내부 유틸리티 순으로 분석 깊이 조절
- **반성 의무**: 도구 결과를 받은 직후 결론 내리지 않고, "실제 문제인가, 컨텍스트 부족 오해인가?" 자문 후 작성

### Good vs Bad Finding 예시

**Good** (구체적, 검증 가능):
```
FILE: internal/auth/handler.go:47
ISSUE: JWT 서명 검증 없이 payload 디코딩 사용. 변조 토큰으로 타 사용자 세션 접근 가능
EVIDENCE: ValidateToken()이 jwt.Parse()의 signature 검증 옵션을 비활성화 (L47-49)
RECOMMENDATION: jwt.ParseWithClaims()로 교체 + signing method 검증 추가
```

**Bad** (모호, 검증 불가):
```
FILE: auth 모듈
ISSUE: 인증 처리가 불안전할 수 있음
RECOMMENDATION: 보안을 개선하세요
```

## Step 6: Purpose Alignment 판정 기준

### AC별 Verdict 테이블 (필수)

alignment-checker는 반드시 아래 형식으로 출력한다. "전반적으로 일치합니다" 형태의 포괄적 판정은 금지한다.

```markdown
| AC | Status | Evidence |
|----|--------|----------|
| AC-1: {항목명} | PASS | {diff 위치, 코드 스니펫} |
| AC-2: {항목명} | FAIL | {미충족 사유: 어떤 부분이 빠졌는지} |
| AC-3: {항목명} | NEEDS-HUMAN-REVIEW | {판단 불가 사유} |
```

### Verdict 경로

| Verdict | 조건 | 후속 조치 |
|---------|------|----------|
| **PASS** | AC를 코드에서 충족 확인 | 진행 |
| **FAIL** | AC 미충족 — 구체적 사유 명시 | Minor: auto-fix (max 3회), Major: Step 1-B 회귀 |
| **NEEDS-HUMAN-REVIEW** | 비즈니스 로직 의도, 보안 위험도, 외부 시스템 의존 등 AI 판단 어려움 | PENDING으로 유지 → 사용자에게 일괄 제시 |

### 남용 방지 규칙

- NEEDS-HUMAN-REVIEW가 전체 판정의 **20% 초과** 시 경고 출력
- 경고 발생 시 판단 근거를 재검토하고, 코드에서 확인 가능한 항목은 PASS/FAIL로 변경

### Mechanical / Behavioral 검증 범위

- **Mechanical Checks**: 빌드, 테스트, 린트, 커버리지 — 명령 실행 결과로 판정
- **Behavioral Checks**: Trigger + Observable + Verify Command 3요소 — 실행 결과로 판정

## Step 7: Domain Review 판정 기준

### 도메인별 핵심 체크 항목

**Security (Safety Team)**:
- 인증/인가 경로 우회 또는 약화 여부
- 입력 검증 누락 (injection, XSS, path traversal)
- 암호화/해싱 적정성 (평문 저장, 약한 알고리즘)
- Secret/credential 노출 여부

**Performance (Ops Team)**:
- N+1 쿼리 도입 여부
- 불필요한 반복/중복 연산
- 리소스 누수 (연결, 파일 핸들, goroutine)
- 동시성 이슈 (race condition, deadlock)

**Data (Data Team)**:
- 마이그레이션 안전성 (데이터 유실, 롤백 가능 여부)
- 트랜잭션 경계 적정성 (partial failure 처리)
- 캐시 일관성 (무효화 누락, stale data)
- 상태 변경의 원자성

**Integration (Integration Team)**:
- API 계약 변경의 하위 호환성
- 외부 서비스 장애 시 graceful degradation
- 메시지 순서/중복 처리
- 타임아웃/재시도 정책

**Code Design (Code Design Team)**:
- 기존 컨벤션/패턴과의 일관성
- 의존성 방향 위반 여부
- 테스트 가능성 (DI, 인터페이스 분리)
- SOLID/DRY 원칙 준수

### Blind-First Protocol 적용

1. **Task 0 (BLIND)**: diff만 전달, 사전 우려사항 미공개. 독립 분석
2. **Task 1 (CROSS-CHECK)**: 사전 우려사항 공개 → 독립 findings와 대조
3. **Task 2-3**: 팀 토론 → 합의 → Severity 확정

동일 이슈 독립 발견 시 `[INDEPENDENT-CONFIRM]` 태깅 (높은 신뢰도 신호).

### Verification Layer (CRITICAL/HIGH)

- Phase 1 (Blind): 코드 위치만 전달, finding 원문 미전달. 독립 분석
- Phase 2 (Cross-check): 원래 finding 공개 → 대조. 일치 시 `[VERIFIED]`, 불일치 시 재판정
- 재현 불가 시 MEDIUM으로 하향 + `[UNVERIFIED]` + 하향 근거 기록

## Step 17: Production Readiness 판정 기준

### 필수 통과 조건

| 항목 | 통과 조건 | 검증 방법 |
|------|----------|----------|
| 테스트 | 전체 테스트 스위트 통과 (0 failures) | verify-commands.md 실행 |
| 빌드 | 빌드 성공 + 타입체크 통과 | verify-commands.md 실행 |
| 보안 | CRITICAL finding 0건 | review-findings.md/jsonl 확인 |
| 전문가 우려 | HIGH 이상 전부 반영 | expert-plan-concerns.md 대조 |
| 커버리지 | 80% 이상 (측정 가능 시) | verify-commands.md Coverage 명령 |

### Verdict 테이블 (필수)

production-readiness-auditor는 Success Criteria 각 항목에 대해 아래 형식으로 판정:

```markdown
| Criteria | Status | Evidence |
|----------|--------|----------|
| 전체 테스트 통과 | PASS/FAIL | 테스트 실행 결과 |
| 빌드+타입체크 | PASS/FAIL | 빌드 로그 |
| 보안 CRITICAL 0건 | PASS/FAIL | findings 목록 |
| HIGH 우려 반영 | PASS/FAIL | 반영 내역 |
```

"전반적으로 양호합니다" 포괄 판정은 금지한다.

### Finding Acceptance Summary

Step 17에서 전체 findings의 수용률을 도메인별로 산출:

```
| Domain | Total | Accepted | Rejected | Rate |
|--------|-------|----------|----------|------|
| safety | 3 | 2 | 1 | 67% |
| data | 2 | 2 | 0 | 100% |
```

### 결과 처리

- 모든 항목 PASS → Integration Stage로 진행
- Minor FAIL → executor auto-fix
- Major FAIL → 관련 Phase로 회귀
- Critical FAIL → Step 1-B 회귀
