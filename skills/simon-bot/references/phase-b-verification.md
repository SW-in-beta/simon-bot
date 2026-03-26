# Phase B-E: Verification (Detailed Instructions)

구현(phase-b-implementation.md) 완료 후 검증 단계를 수행한다.

## 목차
- [Step 6: Purpose Alignment Review](#step-6-purpose-alignment-review)
  - [AC별 Verdict 테이블 (P-003)](#ac별-verdict-테이블)
  - [6-B: Working Example 검증](#6-b-working-example-검증)
  - [6-C: Playwright 브라우저 검증 (선택)](#6-c-playwright-브라우저-검증-선택)
- [Step 7: Bug/Security/Performance Review — 도메인팀 Agent Team 토론](#step-7-bugsecurityperformance-review--도메인팀-agent-team-토론)
  - [7-A: 구현 결과 검증 (Agent Team 토론)](#7-a-구현-결과-검증-agent-team-토론)
  - [Interaction Boundary Analysis (P-001)](#interaction-boundary-analysis-p-001)
  - [Verification Layer (P-003) — Blind-First Protocol](#verification-layer-p-003--blind-first-protocol)
  - [Reproducibility Gate (P-007)](#reproducibility-gate-p-007)
  - [Finding Acceptance Tracking (P-008)](#finding-acceptance-tracking-p-008)
  - [7-B: 사전 우려사항 대조 검증](#7-b-사전-우려사항-대조-검증)
  - [Devil's Advocate (False Negative 탐지)](#devils-advocate-false-negative-탐지--standard-only)
  - [7-C: Findings 보고 (2-tier)](#7-c-findings-보고-2-tier)
- [Step 8: Regression Verification](#step-8-regression-verification)
- [Refinement Cycle (STANDARD+ 경로)](#refinement-cycle-p-006-standard-경로-step-8-완료-후)
  - [Refinement Iteration (max 3회)](#refinement-iteration-max-3회)
  - [Refinement 결과 기록](#refinement-결과-기록)
- [Step 17: Production Readiness — Fresh Context Audit](#step-17-production-readiness--fresh-context-audit)

## Step 6: Purpose Alignment Review

구현 과정을 목격하지 않은 **fresh context alignment-checker** subagent에 위임한다. 구현 중 형성된 해석 편향을 제거하고, "계획서를 처음 읽는 개발자"의 시각으로 정합성을 검증한다 (`context-separation.md`의 Fresh Subagent 원칙).

- Spawn `alignment-checker` (fresh subagent): **plan-summary.md + git diff만** 전달. 구현 과정 컨텍스트(inline-issues.md, 토론 기록 등)는 의도적으로 제외
- 프롬프트: "당신은 이 계획서를 처음 읽는 개발자입니다. git diff가 계획서의 의도를 올바르게 구현했는지 검증하세요. **반드시 Acceptance Criteria의 각 항목(Mechanical Checks + Behavioral Checks)에 대해 아래 Verdict 테이블 형식으로 판정하세요.** '전반적으로 일치합니다' 같은 요약 판정은 금지합니다."

### AC별 Verdict 테이블

alignment-checker와 production-readiness-auditor는 반드시 아래 형식으로 판정을 출력한다. "전반적으로..." 형태의 포괄적 판정은 명시적으로 금지한다 — 부분 누락이 "전반적 OK" 판정에 흡수되는 것을 방지하기 위함이다.

```markdown
## Verdict Table
| AC | Status | Evidence |
|----|--------|----------|
| AC-1: {항목명} | PASS | {구체적 근거: diff 위치, 코드 스니펫} |
| AC-2: {항목명} | FAIL | {미충족 사유: 어떤 부분이 빠졌는지} |
| AC-3: {항목명} | NEEDS-HUMAN-REVIEW | {판단 불가 사유: 비즈니스 로직 의도 확인 필요} |
```

**Verdict 경로:**
- **PASS**: 구현이 AC를 충족함을 코드에서 확인
- **FAIL**: AC 미충족 — 구체적 미충족 사유 명시
- **NEEDS-HUMAN-REVIEW**: AI가 판단하기 어려운 영역 (비즈니스 로직 의도, 보안의 실질적 위험도, 외부 시스템 의존 등). PENDING으로 유지하고 다음 사용자 인터랙션 지점에서 일괄 제시
  - **남용 방지**: 전체 판정의 20%를 초과하면 경고를 출력하고, 판단 근거를 재검토한다

**결과 처리:**
- 모든 AC가 PASS → Step 7로 진행
- FAIL 존재 → Minor: executor auto-fix (max 3 times). Major: → Step 1-B (plan itself was insufficient)
- NEEDS-HUMAN-REVIEW 존재 → PENDING 항목을 사용자에게 보고, 승인 후 진행

- Save: `.claude/memory/unit-{name}/alignment-verdict.md`

### 6-B: Working Example 검증

테스트 통과 ≠ 실제 동작 확인. 며칠 후 "사실 이건 구현 안 됐었네"를 방지하기 위해, 실제로 코드가 의도대로 동작하는지 시연 가능한 수준으로 확인한다.

- `architect`가 plan-summary.md의 **Behavior Changes (Before → After)**를 기준으로 검증 시나리오 1-2개 도출
- `executor`가 실제 실행 또는 실행 가능한 스크립트/curl 명령으로 동작 확인
  - CLI 도구: 실제 명령 실행
  - API: curl/httpie 명령 예시 작성 (실제 외부 호출은 금지 — mock server 또는 dry-run)
  - 라이브러리: 간단한 사용 예제 코드 작성 + 실행
- 결과를 `.claude/memory/unit-{name}/working-example.md`에 기록
- **검증 실패 시**: Step 5로 회귀 (구현 누락)

### 6-C: 브라우저 검증 (선택)

`config.yaml`의 `browser_verification: true` 설정 시 활성화. 프론트엔드 프로젝트에서 "빌드 통과 + 테스트 통과 ≠ 렌더링 정상" gap을 해소한다.

- **도구 우선순위**: gstack browse > Playwright MCP. gstack browse(`~/.claude/skills/gstack/browse/dist/browse`)가 설치되어 있으면 우선 사용한다 — 데몬 모델로 ~100ms/명령이며 ARIA 기반 ref 시스템으로 요소 선택이 안정적이다. 미설치 시 Playwright MCP로 fallback.
- **전제 조건**: (gstack browse 또는 Playwright MCP) + dev server 실행 중
- **미설치 시**: 경고만 출력하고 graceful skip (`[Skip] 브라우저 도구 미설치 — 브라우저 검증 건너뜀`)
- **검증 방식**:
  1. plan-summary.md의 Behavioral Checks 중 UI 관련 항목을 추출
  2. 각 Behavioral Check에 대해 브라우저 검증 실행:
     - **gstack browse**: `$B goto {url}` → `$B snapshot -i` → `$B click/fill @ref` → `$B snapshot -D` (diff) → `$B screenshot {path}` → `$B is visible/enabled {selector}`
     - **Playwright MCP**: 각 AC별 독립 브라우저 에이전트를 병렬 spawn
  3. 반응형 레이아웃 검증 (gstack browse 설치 시): `$B responsive /tmp/{unit-name}` → mobile/tablet/desktop 스크린샷 자동 생성
  4. 결과를 Verdict 테이블 형식으로 통합
- **결과**: `.claude/memory/unit-{name}/browser-verification.md`에 AC별 스크린샷 경로 + verdict 기록
- **FAIL 시**: Step 5로 회귀 (렌더링 버그 수정)

## Step 7: Bug/Security/Performance Review — 도메인팀 Agent Team 토론

### 7-A: 구현 결과 검증 (Agent Team 토론)

#### Context Preparation (Subagent 컨텍스트 사전 필터링)

Subagent에게 데이터를 전달하기 전에, 불필요한 노이즈를 제거하여 "순도 100%"의 정보만 전달한다.

- **diff 전달 시**: 자동 생성 파일(*.lock, *.min.js, go.sum, generated/)을 제거하고, 공백/포맷팅만 변경된 hunk를 제거한 후 전달한다. 파일별 변경 통계 + 핵심 함수 시그니처 변경 요약을 먼저 전달하고, 필요 시 상세 diff를 추가 제공한다.
- **코드 전달 시**: 파일 전체가 아닌 변경된 함수/메서드 단위로 추출하여 전달한다.
- **CLI 도구 활용**: `summarize-diff.sh` 등 컨텍스트 전처리 스크립트가 있으면 우선 사용한다.

원본 데이터를 통째로 넘기면 컨텍스트가 낭비되고 에이전트가 노이즈에 주의를 뺏긴다.

- Step 4-B와 동일한 통합 전문가 팀 구조 (`TeamCreate(team_name="impl-review")`)
- 추가 컨텍스트: `plan-summary.md`, `expert-plan-concerns.md`, `code-design-analysis.md`, `inline-issues.md` (있으면), **실제 git diff**

**에이전트 역할별 도구 접근 범위 (P-011):**
[agent-capability-matrix.md](agent-capability-matrix.md)의 Role × Permission Table을 참조하여 spawn prompt에 ROLE_IDENTITY 블록을 포함한다. 역할별 Tools Forbidden을 명시적으로 전달하여 역할 이탈을 구조적으로 방지한다.

### Findings Volume-Adaptive Processing

7-A 토론 합의 후 findings volume에 따라 검증 파이프라인을 조절한다. multi-agent 전체를 항상 실행하면 findings 0건에서도 컨텍스트가 낭비되어 후반 Step 품질이 저하되기 때문이다 (SKILL.md Multi-Agent Saturation Guard 참조).

| CRITICAL/HIGH | MEDIUM | 적용 파이프라인 |
|:------------:|:------:|---------------|
| 0 | 0-3 | 7-B(사전 우려 대조) → 7-C(보고) → Step 8. Verification Layer + Devil's Advocate skip |
| 0 | 4+ | 7-B → 7-C → Step 8. Devil's Advocate skip |
| 1+ | any | Full pipeline (Verification Layer → Reproducibility Gate → 7-B → Devil's Advocate → 7-C → 7-D) |

**예외**: config.yaml의 `high_impact_paths` 매칭 파일이 포함되면 findings 건수와 무관하게 full pipeline 강제.

Decision Journal 기록: `[Decision] Step 7 Volume-Adaptive — CRITICAL {N}, HIGH {N}, MEDIUM {N}건 → {skip된 단계} skip.`

**Findings 품질 원칙 — "깊이 > 수량" (P-008):**
각 전문가 에이전트 prompt에 포함:
> "구체적 근거가 있는 5건이 모호한 설명의 20건보다 낫다. 각 finding에는 (1) 구체적 코드 위치, (2) 왜 문제인지, (3) 영향 범위를 반드시 포함하라. 추측성 보고와 변경하지 않은 코드에 대한 일반 조언은 포함하지 마라."

#### Output Validation Gate

전문가 출력 수신 후 Findings Schema 필수 필드를 결정론적으로 검증한다:

필수 필드: `FINDING_ID`, `SEVERITY`, `FILE`, `ISSUE`, `RECOMMENDATION`

- SEVERITY 유효값: CRITICAL/HIGH/MEDIUM
- FILE 형식: `{path}:{line}`
- 누락 시: 전문가에게 누락 필드 명시 → 재출력 요청 (최대 2회)
- 2회 후에도 누락: 사용 가능한 필드만으로 진행 + WARNING 기록

### Expert Review 반성 원칙

전문가 에이전트가 코드를 탐색(Grep/Read)한 후 finding을 작성하기 전에, 다음을 자문한다:
- 내가 찾은 것이 실제 문제인가, 아니면 컨텍스트 부족으로 인한 오해인가?
- 이 코드의 의도를 정확히 이해하고 있는가?
- caller/callee를 확인하면 내 판단이 바뀔 수 있는가?

도구 결과를 받은 직후에 바로 결론을 내리지 않고, 한 번 반성한 후 finding을 작성한다. 이 원칙은 false positive(오진)를 줄이기 위함이다.

### Interaction Boundary Analysis (P-001)

"diff only" 기본 규칙을 유지하되, 변경된 코드가 기존 코드와 맞닿는 경계면을 검증한다:

1. **Primary Scope**: git diff 대상 파일의 변경된 코드 (기존과 동일)
2. **Interaction Boundary**: 변경된 함수의 caller/callee 1-depth까지 Grep으로 탐색. "변경된 코드의 가정이 기존 코드의 실제 동작과 일치하는가"를 검증한다. 전체 호출 트리가 아닌 직접 호출 관계만 확인한다.
3. **Impact-Aware Path Selection**: `config.yaml`의 `high_impact_paths`(auth, crypto, migration 등)에 매칭되는 파일이 변경되면, 변경량이 SMALL이더라도 최소 STANDARD 리뷰 경로를 강제한다.

이 분석은 "변경이 기존 코드의 잠재 버그를 활성화"하는 클래스의 버그를 탐지하기 위한 것이다. diff 스코프 기본 유지로 노이즈 증가를 최소화한다.

- **Shared Tasks** (5단계, Blind-First 적용 — `context-separation.md` 참조):
  - Task 0 **[BLIND REVIEW]**: git diff만 전달, expert-plan-concerns.md와 inline-issues.md는 아직 제공하지 않음. "이 변경에서 버그, 보안, 성능 이슈를 독립적으로 찾으라." → findings (`references/expert-output-schema.md`의 Findings Schema를 따른다)
  - Task 1 **[CROSS-CHECK]**: expert-plan-concerns.md + inline-issues.md 공개 → Task 0의 독립 findings와 대조. 독립적으로 동일 이슈를 발견한 경우 `[INDEPENDENT-CONFIRM]` 태깅 (높은 신뢰도 신호). 사전 우려사항 중 Task 0에서 발견되지 않은 것은 추가 검토
  - Task 2: 직접 메시지로 토론
  - Task 3: 팀 합의 → findings.md (CRITICAL/HIGH/MEDIUM)
- CRITICAL/HIGH [VERIFIED] → executor auto-fix, MEDIUM + [UNVERIFIED] → record

### Verification Layer (P-003) — Blind-First Protocol

Task 3 합의 후, executor 전달 전에 CRITICAL/HIGH findings를 **Blind-First 2-phase**로 독립 검증한다 (`context-separation.md`의 Blind-First + Adversarial Default 원칙):

**Phase 1 (Blind)**: 각 CRITICAL/HIGH finding에 대해 **verifier 에이전트**를 spawn. finding 원문(ISSUE, SEVERITY)을 전달하지 않고, **코드 위치(파일:줄 범위)만** 전달한다.
- 프롬프트: "이 코드에서 보안, 정확성, 성능 이슈가 있는지 독립적으로 분석하세요. 이 코드가 문제없다면 '이슈 없음'이라고 판정하세요."
- EVIDENCE의 코드 스니펫이 **실제 코드와 일치하는지** 확인 (환각 방지)

**Phase 2 (Cross-check)**: Phase 1의 독립 분석 결과와 원래 finding을 대조한다.
- 프롬프트: "이제 원래 finding을 공개합니다. 당신의 독립 분석과 비교하세요. **이 finding이 틀렸을 가능성을 적극 탐색하세요** (Adversarial Default)."
- 독립 분석과 finding이 일치 → `[CONFIRMED]` + `VERIFICATION_STATUS: VERIFIED`
- 독립 분석에서 해당 이슈 미발견 → 구체적 재현 경로를 제시하여 재판정. 재현 불가 시 → `[DISPUTED]` + MEDIUM으로 하향 + `VERIFICATION_STATUS: UNVERIFIED` + 하향 근거 기록

executor는 `VERIFIED` findings만 CRITICAL/HIGH로 처리한다. verifier는 finding 생성자와 다른 에이전트여야 한다.

### Reproducibility Gate (P-007)

executor가 CRITICAL/HIGH 이슈를 수정하기 전에 재현성을 먼저 확인한다:

1. **재현 테스트 작성**: CRITICAL/HIGH finding에 대해 이슈를 재현하는 실패 테스트를 먼저 작성한다 (TDD의 RED 단계와 동일)
2. **재현 성공 (테스트 실패)**: 이슈가 실재함이 증명됨 → 수정 진행
3. **재현 실패 (테스트 통과)**: 이슈가 재현되지 않음 → severity를 MEDIUM으로 자동 하향하고, 하향 근거를 기록
4. **코드 기반 이슈의 요건**: 전문가가 보고할 때 구체적 입력/조건을 명시해야 함. "~할 수 있다" 식의 추측은 MEDIUM으로 자동 하향

이 게이트는 CRITICAL/HIGH에만 적용한다. MEDIUM 이슈에는 적용하지 않는다.

### Finding Acceptance Tracking (P-008)

executor가 finding을 수정 완료하면 `ACCEPTANCE_STATUS`를 갱신한다:
- 수정 적용 완료 → `ACCEPTED` + 사유
- Reproducibility Gate에서 재현 실패 → `REJECTED` + "재현 불가"
- 사용자가 수정을 되돌린 경우 → `REJECTED` + 사유

Step 17에서 전체 findings의 수용률을 자동 산출한다 (도메인별).

### 7-B: 사전 우려사항 대조 검증

- `.claude/memory/expert-plan-concerns.md` 읽기
- `.claude/memory/expert-discussions/*-discussion.md` 읽기 (토론 맥락 + trigger_condition 확인)
- 각 concern의 `trigger_condition`을 실제 구현 결과와 대조하여, 조건이 충족된 concern은 severity를 재평가한다
- Spawn `architect`: 사전 우려사항 중 누락 항목 대조
- 누락 발견 → executor fix → 7-A 재검증 (max 1회)

- Use security-reviewer + code-reviewer subagents
- Save: `.claude/memory/unit-{name}/review-findings.md`

#### Findings 구조화 병행 저장

review-findings.md(사람 읽기용)와 함께 review-findings.jsonl(CLI 조회용)을 병행 유지한다. jq로 필터링/집계하여 LLM에 결과만 전달함으로써 컨텍스트를 절약한다.

```jsonl
{"id": "F-001", "domain": "safety", "severity": "CRITICAL", "file": "auth/handler.go", "line": 42, "status": "ACCEPTED"}
{"id": "F-002", "domain": "data", "severity": "HIGH", "file": "db/query.go", "line": 15, "status": "REJECTED"}
```

활용 예: `jq -s '[.[] | select(.status=="ACCEPTED" and .severity=="CRITICAL")]' review-findings.jsonl`

마크다운만으로 충분한 문서(plan-summary.md 등 구조화된 산문)는 JSONL 병행 대상이 아니다.

**Findings Pipeline Integrity (P-009)**: 모든 리뷰 단계에서 `expert-output-schema.md`의 Findings Schema를 공통 출력 포맷으로 사용한다. findings는 **append-only**로 누적하며, 기존 finding을 삭제하거나 덮어쓰지 않는다. executor 수정 완료 시 **Severity-First Ordering** 적용 — CRITICAL → HIGH → MEDIUM 순서로 검증한다.

### Devil's Advocate (False Negative 탐지 — STANDARD+ only)

Step 7 findings 확정 후, findings와 토론 기록을 **보지 않은** devil-advocate subagent를 spawn하여 false negative(보고되지 않은 문제)를 탐지한다. Verification Layer(P-003)가 false positive를 필터하는 것의 보완재다 (`context-separation.md`의 Fresh Subagent + Adversarial Default 원칙).

- **트리거**: STANDARD+ 경로 또는 `config.yaml`의 `high_impact_paths` 매칭 시. SMALL 경로에는 미적용
- **전달**: git diff + plan-summary.md만. Step 7 findings, 토론 기록, inline-issues.md는 **의도적으로 제외** (What-not-Why Handoff)
- **프롬프트**: "이 변경에서 발생할 수 있는 가장 위험한 문제 3가지를 찾으세요. 이미 누군가가 리뷰했다고 가정하지 마세요."
- **결과 처리**:
  - Step 7 findings에 없는 새 이슈 발견 → 기존 findings에 추가 (`[DEVIL-ADVOCATE]` 태깅)
  - Step 7 findings와 중복 → `[INDEPENDENT-CONFIRM]` 태깅으로 신뢰도 강화
  - 이슈 없음 → 기록만 ("Devil's Advocate가 추가 이슈를 발견하지 못함")
- **Save**: `.claude/memory/unit-{name}/devil-advocate-findings.md`

### 7-C: Findings 보고 (2-tier)

Step 7 findings를 사용자에게 보고할 때 인지 부담을 줄이기 위해 계층화한다:

- **Tier 1 (상세)**: CRITICAL — 전체 finding 내용 표시 (코드 위치, 문제, 영향, 수정 방향)
- **Tier 2 (1줄 요약)**: HIGH — `[HIGH] {한줄 요약} ({파일:줄})` 형식
- **Tier 3 (건수만)**: MEDIUM — `MEDIUM {N}건 발견 (상세: review-findings.md)` 형식

사용자가 HIGH/MEDIUM 상세를 원하면 즉시 제공한다.

### 7-D: Fix-First 분류 (Findings 수정 전 분류)

findings를 executor에 전달하기 전에 AUTO-FIX / ASK로 분류하여, 명확한 이슈는 즉시 수정하고 설계 판단이 필요한 것만 사용자에게 확인한다:

**AUTO-FIX** (사용자 확인 없이 즉시 수정):
- SQL injection → parameterized query로 교체
- Dead code 제거
- Import 정리 / unused variable 제거
- N+1 쿼리 → eager loading 적용
- 명확한 타입 에러 수정
- 누락된 에러 반환 (함수 시그니처로 명확한 경우)

**ASK** (사용자 확인 후 수정):
- Race condition (올바른 해결 방향이 여러 가지)
- 설계/아키텍처 변경
- LLM 신뢰 경계 (trust boundary) 이슈
- 복잡한 리팩토링
- 성능 최적화 (트레이드오프 존재)
- 비즈니스 로직 수정

**분류 기준**: 올바른 수정 방향이 **하나**로 명확하면 AUTO-FIX, **여러 가지**이면 ASK.
CRITICAL severity이면 AUTO-FIX 대상이라도 수정 후 반드시 사용자에게 보고한다.

**executor 처리 순서**:
1. AUTO-FIX 항목을 일괄 수정 + 커밋 (각 수정의 before/after 기록)
2. ASK 항목을 사용자에게 일괄 제시 (AskUserQuestion)
3. 사용자 승인된 항목 수정
4. 빌드/테스트 재실행 (Stop-and-Fix Gate 적용)

## Step 8: Regression Verification

- Spawn `architect`: Step 7 fixes가 기존 기능 깨뜨리지 않았는지 확인
- Regression → executor fix → Step 7 re-review (max 2 loops)

#### Blame Protocol

regression 실패 발견 시, "기존 결함"이라는 주장은 증명 없이 수용하지 않는다:

1. regression 실패 감지 → `git stash` → base branch checkout → 동일 테스트 실행
2. base에서도 실패 → `[PRE-EXISTING]` 태깅 — 이 regression은 자신의 변경과 무관함이 증명됨
3. base에서 통과 → `[INTRODUCED]` 태깅 — 반드시 수정 필요
4. 검증 불가(base checkout 실패, 테스트 환경 차이 등) → `[UNVERIFIED — may or may not be related]` 태깅 + 리스크로 명시

증명 없이 "관련 없음" 주장은 명시적으로 금지한다. "Pre-existing without receipts is a lazy claim."
결과를 `unit-{name}/regression-blame.md`에 기록한다.

#### Regression Test 의무 생성

CRITICAL/HIGH finding 수정 시, 수정 전에 반드시 해당 이슈를 재현하는 실패 테스트를 먼저 작성한다:

1. **기존 테스트 패턴 학습**: 같은 디렉토리의 기존 테스트 파일에서 naming, imports, assertion style 참조
2. **Codepath tracing**: input → branch → failure point → edge cases를 따라 테스트 케이스 도출
3. **실패 테스트 작성** → 실패 확인 → 코드 수정 → 통과 확인
4. 통과하면 커밋, 실패하면 1회 수정 시도, 그래도 실패하면 삭제하고 수정만 진행
5. 테스트 파일에 attribution comment 포함:
   ```
   // Regression: {FINDING_ID} — {what broke}
   // Found by simon-bot Step 7 on {YYYY-MM-DD}
   ```

### Build-QA Re-cycle

Step 7에서 CRITICAL/HIGH 수정으로 인한 코드 변경이 20줄 이상이거나 새 파일이 추가된 경우, Step 6(Purpose Alignment)을 재실행한다. 대규모 수정이 원래 계획의 의도에서 벗어났을 가능성을 사전에 차단하기 위함이다.

**트리거 조건** (하나라도 해당 시 재실행):
- CRITICAL/HIGH finding 수정으로 변경된 코드가 20줄 이상 (`git diff --stat`으로 측정)
- 수정 과정에서 새 파일이 추가됨

**재실행 절차**:
1. Step 6(Purpose Alignment Review)을 동일한 방식으로 재실행한다 (fresh subagent, plan-summary.md + git diff)
2. Step 6 재실행에서 **PASS** → Step 8(Regression Verification)로 정상 진행
3. Step 6 재실행에서 **FAIL** → 수정 방향이 계획 의도에서 벗어남. FAIL 사유를 기반으로 수정 방향을 조정한 후 Step 7을 재실행한다
4. 재실행 이력을 `.claude/memory/unit-{name}/build-qa-recycle.md`에 기록한다

--- SMALL path skips to Step 17 here ---

## Refinement Cycle (P-006, STANDARD+ 경로, Step 8 완료 후)

ARC-AGI에서 영감을 받은 반복 개선 루프. 기존 Steps 9-16의 개별 단계를 "Generate → Self-improve → Verify → Correct" 사이클로 통합하여, 필요한 만큼만 반복하고 품질이 충족되면 즉시 종료한다.

### Refinement Iteration (max 3회)

각 iteration에서:

**1. Scan (Generate)** — `architect`가 전체 diff를 스캔하여 개선 대상을 분류:
- **Splitting**: 50줄+ 함수 또는 300줄+ 파일
- **Reuse**: 중복 코드 또는 재사용 가능 패턴
- **Dead Code**: 사용되지 않는 코드
- **Flow Issues**: 다중 파일 간 흐름 문제
- **Quality Issues**: 코드 품질 (가독성, 네이밍, 에러 처리)
- **MEDIUM Issues**: 이전 Step에서 누적된 MEDIUM 이슈

**2. Fix (Self-improve)** — `executor`가 발견된 이슈를 일괄 수정

**3. Verify (Verify)** — 수정 후 빌드/테스트/타입체크 실행 + `/simplify` 스킬로 코드 품질 검토

**4. Check (Correct)** — 새로운 이슈 발생 여부 확인:
- 새 이슈 없음 → Cycle 종료, Step 17로 진행
- 새 이슈 발생 → 다음 iteration으로 (남은 iteration 내에서)
- max iteration 도달 → 잔여 MEDIUM 이슈는 기록 후 Step 17로 진행

### Refinement 결과 기록

`.claude/memory/unit-{name}/refinement-result.md`:
```markdown
## Refinement Cycle Result
- Iterations: {N}/3
- Issues found: {총 발견 수}
- Issues fixed: {수정 수}
- Remaining MEDIUM: {잔여 수} (기록만)
- Exit reason: clean / max-iterations
```

## Step 17: Production Readiness — Fresh Context Audit

전 과정(Step 5-16)을 목격한 에이전트 대신, 완전 새 컨텍스트의 **production-readiness-auditor**에게 최종 검증을 위임한다. "이미 확인한 것"이라는 편향(boiling frog effect)을 제거하고, 불완전 수정과 MEDIUM 조합 효과를 포착한다 (`context-separation.md`의 Fresh Subagent 원칙).

- **참조**: Success Criteria 체크리스트의 기술적 항목을 이 단계에서 검증

### 도메인별 Hard Threshold Gate

각 도메인(Security, Performance, Data, Integration, Code Design)의 CRITICAL/HIGH finding 중 ACCEPTED+VERIFIED가 100%여야 한다. 어느 한 도메인이라도 미달이면 해당 도메인의 미해결 finding을 나열하고 FAIL 판정한다.

**검증 절차**:
1. `review-findings.jsonl`에서 도메인별 CRITICAL/HIGH finding을 집계한다:
   ```bash
   jq -s 'group_by(.domain) | .[] | {domain: .[0].domain, total: length, resolved: [.[] | select(.status=="ACCEPTED" and .verification_status=="VERIFIED")] | length}' review-findings.jsonl
   ```
2. 각 도메인의 `resolved / total`이 100%인지 확인한다
3. 미달 도메인이 있으면:
   - 해당 도메인의 미해결 finding 목록을 출력한다 (ID, severity, file, issue, status)
   - Step 17 전체를 **FAIL** 판정한다
   - 미해결 finding을 executor에게 전달하여 수정 후 재검증한다

- Spawn **fresh `production-readiness-auditor`** subagent: **plan-summary.md + 최종 git diff + verify-commands.md만** 전달. 중간 과정 산출물(inline-issues.md, review-findings.md, 토론 기록)은 **의도적으로 제외**
- 프롬프트: "당신은 이 코드를 처음 보는 시니어 엔지니어입니다. 프로덕션 배포 전 최종 검증을 수행하세요. **반드시 Success Criteria의 각 항목에 대해 Verdict 테이블 형식(PASS/FAIL/NEEDS-HUMAN-REVIEW)으로 판정하세요.** '전반적으로 양호합니다' 같은 요약 판정은 금지합니다."
- 별도로 `security-reviewer` (fresh subagent)를 parallel spawn — 보안 관점 독립 검증
- **테스트 커버리지 검증**: `verify-commands.md`에 커버리지 측정 명령이 있으면 실행하여 80% 이상인지 확인. 미달 시 FAIL 판정하고 커버리지가 부족한 모듈을 리포트에 명시
- **[GATE — Done-When Checks JSON]**: `workflow-state.json`의 `done_when_checks` 배열에서 `verified: false` 항목이 있으면 FAIL. 각 미검증 항목을 나열하고, 해당 검증을 수행한 뒤 `verified: true`로 갱신한다. 모든 항목이 `verified: true`여야 이 게이트를 통과한다 — JSON boolean은 LLM이 Markdown 체크리스트를 임의로 체크하는 것과 달리 명시적 갱신이 필요하므로 조기 완료 선언을 구조적으로 방지한다.
- Final checklist: requirements met, build passes, tests pass, coverage ≥ 80%, no security issues, all done_when_checks verified
- NEEDS-HUMAN-REVIEW 판정이 있으면 PENDING 항목을 사용자에게 일괄 제시
- Minor: executor fix. Major: → relevant Phase. Critical: → Step 1-B
- Save: `.claude/memory/unit-{name}/final-check.md`
