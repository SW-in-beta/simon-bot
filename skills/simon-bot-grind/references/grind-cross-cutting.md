# Grind Cross-Cutting Systems

## 목차
1. [Auto-Diagnosis System](#auto-diagnosis-system)
2. [Checkpoint System](#checkpoint-system)
3. [Confidence Scoring & Assumption Registry](#confidence-scoring--assumption-registry)
4. [Total Retry Budget (워크플로 전체 재시도 예산)](#total-retry-budget-워크플로-전체-재시도-예산)
5. [Progress Pulse (중간 상황 보고)](#progress-pulse-중간-상황-보고)
6. [Escalation Report Format](#escalation-report-format)
7. [Agent Teams Fallback](#agent-teams-fallback)
8. [Docs-First Protocol](#docs-first-protocol)

---

## Auto-Diagnosis System

This system operates across ALL steps. On ANY failure:

### Failure Tracking Protocol

Record every failure in `.claude/memory/failure-log.md`:
```
## [Step N] Attempt M — {timestamp}
- **Error type**: build / test / typecheck / review-rejection / consensus-failure
- **Error summary**: (1-2 lines)
- **Files involved**: list
- **Previous attempts**: what was tried
- **Metrics**: failing_tests={N}, error_signature={hash/key}, changed_lines={N}
```

Check failure patterns before each retry.

#### Failure Log 구조화 병행 저장

failure-log.md(사람 읽기용)와 함께 failure-log.jsonl(CLI 조회용)을 병행 유지한다. grind의 특성상 failure-log가 매우 길어질 수 있으므로(Step당 10회 재시도 × 다수 Step), 전체 파일을 LLM이 읽는 대신 jq로 필터링된 결과만 전달한다.

```jsonl
{"step": 5, "attempt": 3, "error_type": "CODE_LOGIC", "subtype": "TEST_FAILURE", "error_summary": "TestAuth: expected 200 got 401", "timestamp": "2026-03-13T14:30:00"}
```

활용 예:
- 동일 에러 반복 횟수: `jq -s '[.[] | .error_summary] | group_by(.) | map({error: .[0], count: length}) | sort_by(-.count)' failure-log.jsonl`
- 특정 Step 실패 수: `jq -s '[.[] | select(.step == 5)] | length' failure-log.jsonl`

decision-journal.md도 동일 패턴으로 decision-journal.jsonl을 병행한다.

### Progress Detection (재시도 진전 감지)

매 재시도 후 이전 시도의 환경 피드백(빌드 로그, 테스트 결과)과 현재 결과를 구조적으로 비교한다.
같은 실패를 반복하면 더 많이 시도해봐야 결과가 달라지지 않기 때문이다.

**비교 항목:**
1. **실패 테스트 수 변화** — 이전 attempt 대비 failing test count 증감
2. **에러 메시지 동일성** — 동일 에러 시그니처가 반복되는지 (에러 메시지의 핵심 키워드/코드 비교)
3. **변경된 코드 라인 수** — 이전 attempt 대비 실질적으로 달라진 코드 양

**진전(Progress) 판정 기준:**
- 실패 테스트 수가 줄었거나, 에러 메시지가 달라졌거나, 의미 있는 코드 변경이 있으면 → "진전 있음"
- 위 세 항목 모두 변화 없으면 → "진전 없음(stalled)"

**비교 예시 (Few-shot, P-004):**

```
예시 1 — 진전 있음:
  Attempt 2: failing_tests=5, error="TypeError: undefined is not a function"
  Attempt 3: failing_tests=2, error="Expected 200 but got 404"
  → 실패 수 감소(5→2) + 에러 메시지 변화 → 진전 있음

예시 2 — 진전 없음:
  Attempt 3: failing_tests=3, error="Connection refused on port 5432"
  Attempt 4: failing_tests=3, error="Connection refused on port 5432"
  → 실패 수 동일 + 에러 동일 + 코드 변경 없음 → 진전 없음 (stalled)

예시 3 — 진전 있음:
  Attempt 4: failing_tests=0, build="FAIL: missing import"
  Attempt 5: failing_tests=1, build="SUCCESS"
  → 빌드 실패→성공, 테스트 단계까지 진입 → 진전 있음
```

Progress Detection의 비교 항목(실패 테스트 수, 에러 메시지 동일성, 변경 라인 수)은 모두 결정론적으로 계산 가능하다. CLI 도구(`detect-progress.sh` 등)가 있으면:
- 실패 수 delta를 정량적으로 계산
- 에러 시그니처의 해시 비교로 동일성 판별
- `git diff --stat`으로 변경량 추출
- 결과를 JSON으로 출력하여 LLM에 결과만 전달

LLM은 `progress: false`일 때만 전략 전환 의사결정에 관여한다. 매 재시도마다 이전/현재 결과를 컨텍스트에 올려 비교하는 대신, CLI가 정량 비교 후 결과만 전달하면 토큰 소비를 대폭 줄인다.

## Direction Validation Check

매 재시도 후 Progress Detection과 함께 실행한다.

**목적**: 실패 수가 줄어도 요구사항에서 멀어지고 있을 수 있다. 진전(progress)과 방향(direction)을 분리하여 평가한다.

**실행 절차**:
1. `git diff` 출력에서 변경된 파일 목록 추출
2. plan-summary.md의 해당 Unit AC 목록과 대조
3. 변경이 AC와 무관한 파일에 집중되어 있으면 "Direction Drift" 경고

**Direction Drift 감지 시 행동**:
- 사용자에게 1줄 경고: `[Direction Drift] 변경이 AC와 무관한 영역에 집중되어 있습니다. 원래 문제를 재확인합니다.`
- plan-summary.md의 AC를 재읽기
- 현재 접근법이 원래 문제를 해결하는지 자가 점검
- 필요 시 checkpoint로 롤백 후 방향 수정

**Stall Detection Rule:**
- 진전 없는 재시도가 **2회 연속** 되면 현재 전략을 즉시 전환한다 (다음 escalation tier로 점프).
  - 예: Attempt 2에서 stalled 2회 → Attempt 4-6 tier(Root Cause Analysis)로 즉시 이동
  - 예: Attempt 5에서 stalled 2회 → Attempt 7-9 tier(Strategy Pivot)로 즉시 이동
- 이유: 같은 tier 내에서 같은 접근법을 반복하는 것은 시간 낭비이며, 빠른 전략 전환이 해결 확률을 높인다.
- 이 규칙은 escalation ladder의 attempt 번호를 건너뛰는 것이지, 총 시도 횟수 자체를 줄이는 것이 아니다.

### Problem Redefinition Check

stall_threshold 도달 또는 Strategy Pivot 발생 시, 전략 전환 전에 반드시 실행한다 — 같은 문제를 다른 방법으로 공략하는 것과, 문제 자체를 잘못 이해하고 있는 것은 다르다.

**실행 절차**:
1. plan-summary.md에서 원래 요구사항, AC, Intent를 다시 읽는다
2. 현재 해결하려는 문제를 1문장으로 정리한다
3. 원래 요구사항과 비교: 범위가 변질되지 않았는가?
4. failure-log.md의 최근 실패 패턴을 검토: 문제 정의가 잘못된 징후가 있는가?

**범위 변질 또는 문제 재정의 감지 시**:
- decision-journal.md에 기록: `[Problem Redefinition] 원래 문제: X, 현재 시도: Y, 변질 원인: Z`
- failure-log.md에 `[PROBLEM_REDEFINED]` 태그 기록
- 문제 재정의가 필요하면 plan-summary.md를 업데이트
- 원래 문제로 범위를 축소하고, 변질된 부분은 unresolved-decisions.md에 기록
- checkpoint로 롤백 후 원래 범위로 재시작

### Strategy Pivot Examples

- Implementation approach change (different algorithm, different library)
- Architecture change (split into smaller units, change layer boundaries)
- Test strategy change (integration → unit test, or vice versa)
- Dependency resolution (different package version, alternative dependency)
- Scope reduction (implement core only, defer edge cases)
- Complete rewrite of the problematic section

### Fresh Context Handoff Protocol

Escalation Ladder에서 fresh context spawn 시 다음 정보 분리를 준수한다 (`context-separation.md`의 What-not-Why Handoff 원칙):

**Fresh Agent에게 전달 (What):**
- plan-summary.md (요구사항)
- 최신 git diff (현재 코드 상태)
- 에러 메시지 / 실패 테스트 목록 / 빌드 로그
- checkpoint tag (롤백 지점)
- failure-log.md의 **Attempt 번호 + Error summary만** (Previous attempts의 구체적 수정 내용은 제외)

**전달하지 않는 것 (Why):**
- 이전 architect의 Root Cause Analysis 결론
- 이전 executor의 수정 방향과 판단 근거
- failure-log.md의 "왜 이 접근이 실패했는지"에 대한 분석
- Strategy Pivot에서 기각된 대안의 기각 사유

이 분리를 통해 같은 10회 재시도에서 3-4개의 genuinely 다른 관점을 확보한다. "같은 사고방식으로 10번 반복" 대신 "3-4가지 다른 접근"이 가능해진다.

### Anti-Oscillation Check

Strategy Pivot 전에 `.claude/memory/decision-journal.md`를 확인한다. 이전에 시도했다가 실패하고 명시적으로 기각한 전략을 다시 선택하려면, 기각 시점 이후에 새로운 정보(새로운 에러 메시지, 환경 변화, 외부 의존성 업데이트 등)가 확인되었음을 failure-log.md에 기록해야 한다. "다시 해보자"는 허용되지 않는다 — 같은 전략을 같은 조건에서 반복하면 결과도 같다.


### Model-Level Escalation (P-009)

연속 5회 실패 시, 현재 모델의 능력 한계일 수 있으므로 모델 레벨을 한 단계 올려 재시도한다:
- sonnet → opus 전환 (subagent의 모델 파라미터 변경)
- 전환 사유를 failure-log.md에 기록: `[MODEL_ESCALATION] sonnet→opus, reason: {N}회 연속 실패`
- opus에서도 실패 시 기존 Escalation Ladder를 따른다

### Time Guard (P-009)

단일 Step에서 과도한 시간이 소요되는 것을 방지한다.

**구현 방식** (bash 타임스탬프 기반):
- Step 시작 시: `date +%s > /tmp/.simon-bot-step-start`
- 매 재시도 시작 시 경과 시간 확인:
  ```bash
  START=$(cat /tmp/.simon-bot-step-start 2>/dev/null || echo 0)
  NOW=$(date +%s)
  ELAPSED=$(( (NOW - START) / 60 ))
  ```
- 기본 상한: Step당 15분 (config.yaml `time_guard_minutes`로 조정 가능)
- 상한 초과 시: Progress Pulse를 발동하여 사용자에게 경과 시간과 함께 보고
- 목적: "끈질기게"가 "무한정"이 되는 것을 방지

### Pivot Divergence Check (P-009)

전략 전환이 3회 이상 발생하면, 각 전환의 방향이 수렴하고 있는지 확인한다:
- 수렴 (같은 방향의 점진적 조정) → 계속 진행
- 발산 (매번 완전히 다른 방향) → 근본 원인을 재분석하지 않고 표면적 전략만 바꾸고 있을 가능성. Problem Redefinition Check 강제 실행

## Checkpoint System

- Before each strategy pivot, save checkpoint: `git stash` or `git tag checkpoint-step{N}-attempt{M}`
- If new strategy also fails, can rollback to checkpoint and try next alternative
- Save: `.claude/memory/checkpoints.md` (list of checkpoint tags with descriptions)

#### Tier 경계 Checkpoint

Escalation Ladder의 tier 전환 시 자동으로 checkpoint를 생성한다. 중간 성공 상태를 보존하여, 상위 tier의 전략이 기존 성과를 파괴했을 때 최선 상태로 롤백할 수 있게 한다.

| 전환 | checkpoint 태그 | 이유 |
|------|----------------|------|
| Attempt 3→4 (Simple fix → Root Cause Analysis) | `checkpoint-unit-{name}-step{N}-tier2` | Simple fix 성과 보존 |
| Attempt 6→7 (Root Cause → Strategy Pivot) | `checkpoint-unit-{name}-step{N}-tier3` | Root Cause Analysis 성과 보존 |
| Strategy Pivot 시 | `checkpoint-unit-{name}-step{N}-attempt{M}` | 기존과 동일 |

#### Progress-linked Checkpoint

Progress Detection에서 "진전 있음" 판정 시(실패 수 감소, 에러 메시지 변화, 의미 있는 코드 변경 중 1개 이상 충족), 해당 상태를 `checkpoint-unit-{name}-step{N}-best` 태그로 보존한다.

Strategy Pivot 시 롤백 대상:
1. `checkpoint-*-best` (가장 최근의 "진전 있음" 상태) — 우선
2. `checkpoint-initial` (best가 없는 경우) — fallback

이 방식으로 "부분 성공 상태"를 구조적으로 보존하여, 10회 재시도 중 실질적으로 3-4개의 다른 시작점을 확보한다.

## Confidence Scoring & Assumption Registry

Every agent output in Phase A must include confidence assessments.

### Confidence Levels

- **HIGH** (≥0.9): No user confirmation needed, record only
- **MEDIUM** (0.7–0.9): User confirmation needed if agents disagree
- **LOW** (<0.7): Automatic user confirmation required

### Assumption Registry (`.claude/memory/assumptions-registry.md`)

```markdown
## Assumptions Registry
| # | Assumption | Confidence | Impact | Status | Source Step | User Response |
|---|-----------|-----------|--------|--------|------------|---------------|
| 1 | ... | LOW | HIGH | Unverified | Step 0 | — |
```

### Escalation Rules

| Confidence | Impact | Action |
|-----------|--------|--------|
| LOW | HIGH | **MUST** ask user (blocking, 탈출 불가) |
| LOW | LOW | 인터뷰 라운드에 포함 (탈출 가능) |
| MEDIUM + 의견 불일치 | any | 인터뷰 라운드에 포함 (탈출 가능) |
| HIGH | any | 기록만, 사용자 확인 불필요 |

### Protocol

1. Every agent output in Phase A must tag assumptions with `[ASSUMPTION confidence=X impact=Y]: description`
2. Orchestrator collects all assumptions and updates `assumptions-registry.md`
3. LOW confidence or MEDIUM+disagreement assumptions queue for user interview
4. User responses update registry status to Verified/Rejected
5. Rejected assumptions trigger re-analysis of dependent decisions

## Total Retry Budget (워크플로 전체 재시도 예산)

개별 Step마다 10회 재시도가 가능하지만, 워크플로 전체로 보면 무한 재시도는 비효율적이다.
전체 예산을 설정하면 "숲을 보지 못하고 나무만 파는" 상황을 방지할 수 있다.

### 기본 설정
- **total_retry_budget: 50** (전체 워크플로에서 사용할 수 있는 총 재시도 횟수)
- 사용자가 시작 시 다른 값을 지정할 수 있다 (예: "예산 100으로 해줘")

### 차감 규칙
- 각 Step에서 재시도할 때마다 예산에서 1 차감
- 첫 번째 시도(Attempt 1)는 차감하지 않음 — 재시도(Attempt 2+)부터 차감
- 현재 잔여 예산은 failure-log.md 상단에 기록

### 경고 및 에스컬레이션
- **예산 70% 소비 시** (기본: 35회 재시도 누적): Progress Pulse로 사용자에게 경고
  ```
  [Budget Warning — {consumed}/{total} retries used]
  - 가장 많이 소비한 Step: Step {N} ({X}회)
  - 남은 예산: {remaining}회
  - 예상 남은 작업: {remaining_steps}
  - 계속 진행할까요? (Y/예산 추가/우선순위 조정)
  ```
- **예산 100% 소비 시**: 강제 에스컬레이션 — 더 이상 자동 재시도 불가
  - 사용자가 추가 예산을 부여하면 계속 진행 (예: "+20")
  - 사용자가 중단을 선택하면 현재까지의 결과물로 마무리

재시도 예산 차감과 경고 발동은 단순 카운터 관리이므로, CLI 도구(`retry-budget.sh` 등)로 파일 기반 카운터를 관리하면 LLM 기억 의존을 제거할 수 있다. 스크립트가 70% 도달 시 경고, 100% 도달 시 중단을 exit code로 트리거하여 컨텍스트 압축으로 인한 카운트 손실 위험을 구조적으로 차단한다.

### Progress Pulse와의 연계
- Progress Pulse 보고에 항상 "잔여 예산: {N}회" 포함
- 예산 경고는 Progress Pulse의 발동 조건에 추가됨

## Progress Pulse (중간 상황 보고)

자동 조종 중에도 경로 이탈을 감지하려면 사람에게 주기적으로 상황을 보여줘야 한다.

### 발동 조건
- 단일 Step에서 **연속 3회 실패** 시 (escalation 전 중간 보고)
- **전략 전환(Strategy Pivot)** 발생 시
- **누적 재시도 15회** 도달 시 (전체 워크플로 기준)
- **Total Retry Budget 70% 소비** 시

### 보고 내용 (AskUserQuestion)
```
[Progress Pulse — Step {N}, Attempt {M}]
- 현재 상태: {무엇을 하고 있는지}
- 실패 원인: {최근 실패 요약}
- 진전 여부: {Progress Detection 결과 — 개선/정체/악화}
- 다음 전략: {어떻게 시도할 계획인지}
- 누적 현황: 재시도 {X}회, 전략 전환 {Y}회
- 잔여 예산: {remaining}/{total} 회
- 계속 진행할까요?
  - **계속**: 현재 전략으로 계속 진행
  - **피드백**: 사용자 힌트를 반영하여 재시도
  - **전략 변경**: 다른 접근법으로 전환 (구체적 방향 제시 가능)
  - **중단**: 현재까지의 결과물로 마무리
  - **예산 추가**: 재시도 예산 추가 (예: "+20")
```

### 원칙
- Progress Pulse는 **에스컬레이션이 아니다** — 문제 해결을 사용자에게 떠넘기는 것이 아니라, 경로 이탈을 조기에 감지하기 위한 상황 공유. "Escalation Ladder 소진 전 에스컬레이션 금지" 원칙과 충돌하지 않는다.
- **경량 체크포인트** — 사용자가 "계속"이면 즉시 재개. 사용자 피드백이 있으면 반영 후 재시도.
- Progress Pulse를 통해 받은 피드백도 `user-feedback-log.md`에 기록

## Escalation Report Format

When human escalation is needed, generate `.claude/memory/escalation-report.md`:

```markdown
# Escalation Report — Step {N}, Unit {name}

## Problem Summary
(1-2 sentences)

## Failure Timeline
| Attempt | Action Taken | Result |
|---------|-------------|--------|
| 1 | ... | ... |
| 10 | ... | ... |

## Root Cause Analysis
(Architect's diagnosis)

## Strategy Pivots Attempted
1. (description + why it failed)

## Recommendation
- [ ] Option A: (description)
- [ ] Option B: (description)
- [ ] Option C: Skip this and proceed

## Context Files
- failure-log.md, checkpoints.md, unit-{name}/implementation.md
```

## Agent Teams Fallback

Agent Teams가 비활성 상태일 때의 대체 전략은 `~/.claude/skills/simon-bot/references/agent-teams-fallback.md`를 따른다. grind의 "절대 멈추지 않는다" 원칙에 따라, Agent Teams 실패는 워크플로 중단 사유가 아니다. failure-log.md에 기록 후 subagent fallback으로 자동 전환한다.

## Docs-First Protocol

simon-bot의 Docs-First Protocol(`~/.claude/skills/simon-bot/SKILL.md` Cross-Cutting Protocols 참조)을 상속한다.

**grind 맥락 추가 규칙**: 학습 데이터 기반 기억으로 구현하여 실패한 경우, 재시도 전에 반드시 공식 문서를 조회한다. failure-log.md에 "docs-not-checked"로 분류하여 같은 유형의 실패를 반복하지 않도록 한다.
