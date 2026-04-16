# Grind Phase B-E Step Overrides

## 목차
- [Pre-Phase](#pre-phase)
- [Step 5: Implementation (with Build Resilience)](#step-5-implementation-with-build-resilience)
- [Step 6: Purpose Alignment](#step-6-purpose-alignment-max-10-step6_executor)
- [Step 7: Review (Enhanced Loop)](#step-7-review-enhanced-loop)
- [Step 8: Regression Verification](#step-8-regression-verification-max-10-step7_8)
- [Step 9: File/Function Splitting](#step-9-filefunction-splitting)
- [Step 11: Side Effect Check](#step-11-side-effect-check-max-10-step9_11_refactor)
- [Step 12: Full Change Review](#step-12-full-change-review-max-10-step12_major)
- [Step 13: Dead Code Cleanup](#step-13-dead-code-cleanup-max-10-step13_cleanup)
- [Step 14: Code Quality](#step-14-code-quality-max-10-step14_quality)
- [Step 15: Flow Verification](#step-15-flow-verification-max-10-step15_flow)
- [Step 16: MEDIUM Issues](#step-16-medium-issues-max-10-step16)
- [Step 17: Production Readiness](#step-17-production-readiness-max-10-step17_readiness)
- [Integration](#integration-max-10-integration_conflict)
- [Grind Cross-Model Diagnosis (Tier 2+ 공통)](#grind-cross-model-diagnosis-tier-2-공통)
- [Steps 18-20 Overrides](#steps-18-20-overrides)

> Base: `~/.claude/skills/simon/references/phase-b-implementation.md`
> 이 문서는 각 Step의 grind 전용 변경사항(주로 retry 확장 + escalation ladder)만 기술합니다.

## Pre-Phase

simon과 동일 + **초기 체크포인트 생성**:
- `git tag checkpoint-initial` in worktree
- Record in `.claude/memory/checkpoints.md`

CONTEXT.md 추가 항목:
```markdown
## 열일 현황
- 총 재시도: 0회
- 전략 전환: 0회
- 수용된 트레이드오프: 0건
- Retry Budget: 50/50 (잔여/전체)
```

## Step 5: Implementation (with Build Resilience)

추가 읽기: `.claude/memory/failure-log.md` (이전 Unit 패턴 확인)

### Build/Test Verification Loop (max 10: `step5_build_retry`)

1. Run build + test + typecheck
2. ALL pass → Step 6
3. ANY fails:
   - **Attempt 1-3**: `executor` fixes immediate error
   - **Attempt 4-6**: **fresh executor** spawn + `architect` Root Cause Analysis → fresh executor가 targeted fix (What-not-Why Handoff 적용)
   - **Attempt 7-9**: **Strategy Pivot** (`step5_strategy_pivot`)
     - Checkpoint: `git tag checkpoint-step5-attempt{N}`
     - **fresh architect + executor** spawn → 요구사항 + 실패 이력(what)만 전달
     - fresh architect proposes: different pattern / simplified scope / different test strategy / alternative library
     - fresh executor implements from checkpoint
   - **Attempt 10**: **Last Stand** — 완전 fresh context (최소 정보만 전달) architect + executor
     - Fails → `.claude/memory/escalation-report.md` + AskUserQuestion (skip Unit option)

> **[MONITOR]** 재시도 시: 매 attempt 시작 시 `retry` 이벤트, 실패 시 `error` 이벤트, 전략 전환 시 `decision` 이벤트를 발신한다 (SKILL.md의 Monitor Protocol 참조).

## Step 6: Purpose Alignment (max 10: `step6_executor`)

- **Attempt 1-3**: executor auto-fix
- **Attempt 4-6**: **fresh executor** spawn + architect re-analyzes requirements → fresh executor가 re-fix
- **Attempt 7-9**: **fresh architect + executor** spawn → scope adjustment or alternative interpretation
- **Attempt 10**: 완전 fresh context architect + executor final collaborative fix
- **Major misalignment**: → Step 1-B (check failure-log first: if already revisited, escalate to user)

## Step 7: Review (Enhanced Loop)

### 7-A: Enhanced consensus (+10 extra rounds if needed)
- If auto-fix fails for CRITICAL/HIGH:
  - Follow escalation ladder
  - architect may → Step 5 with strategy pivot, OR determine false positive

### 7-B: Prior Concern Verification (max 10: `step7b_recheck`)
- After attempt 5: architect evaluates if concern is implementable in current architecture
  - If not: record as "architectural limitation" + propose follow-up task
- After attempt 8: scope reduction — partial fix + document remainder

## Step 8: Regression Verification (max 10: `step7_8`)

- **Loop 1-3**: Simple fix and re-verify
- **Loop 4-5**: Root cause — WHY do fixes keep causing regressions?
- **Loop 6-8**: Strategy pivot — checkpoint + "rewrite with better isolation" or "add integration test"
- **Loop 9**: Scope reduction — fix most critical regression, document rest
- **Loop 10**: Last stand → escalation report + AskUserQuestion


#### Blame Protocol (grind 강화)

regression 실패 발견 시, base branch에서 동일 테스트를 실행하여 원인을 증명한다:

1. `git stash` → base branch checkout → 동일 테스트 실행
2. base에서도 실패 → `[PRE-EXISTING]` — 무관함이 증명됨
3. base에서 통과 → `[INTRODUCED]` — 반드시 수정 필요
4. 검증 불가 → `[UNVERIFIED]` + 리스크로 명시

**grind 특화**: 10회 재시도 압력 하에서 "기존 결함" 합리화가 빈번하게 발생할 수 있다. WTF-Likelihood에 "[UNVERIFIED] regression 무시" 이벤트를 +10%로 반영하여 폭주를 감지한다.

## Step 9: File/Function Splitting

- **Save checkpoint** before splitting: `git tag checkpoint-step9`

## Step 11: Side Effect Check (max 10: `step9_11_refactor`)

- **Attempt 1-3**: Minor → executor fix
- **Attempt 4-6**: Major → **rollback to checkpoint-step9** → re-attempt with less aggressive splitting
- **Attempt 7-8**: "minimal split" — only absolutely necessary
- **Attempt 9**: "targeted split" — single worst offender only
- **Attempt 10**: skip splitting entirely, keep original (acceptable trade-off)

## Step 12: Full Change Review (max 10: `step12_major`)

- **Attempt 1-3**: Minor → executor. Major → Step 9
- **Attempt 4-6**: architect mediates between findings and constraints
- **Attempt 7-8**: architect + code-reviewer negotiate must-fix vs nice-to-have
- **Attempt 9**: prioritize: fix security/correctness, accept style/design
- **Attempt 10**: record remaining as "accepted trade-offs"

### Step 12 Cross-Model Verification (항상 실행)

Step 12 Full Change Review에서는 교차검증을 **항상** 실행한다 (`~/.claude/skills/_shared/cross-model-verification.md` 참조). 전체 변경사항을 다른 모델의 시각으로 독립 검증하여, Claude가 반복 수정 과정에서 놓칠 수 있는 이슈를 포착한다.

**실행**: Attempt 1의 architect 리뷰와 **병렬로** `codex review` 실행:
```bash
codex review --base {base_branch} \
  -c 'model_reasoning_effort="xhigh"' \
  --enable web_search_cached \
  "전체 변경사항의 일관성, 설계 품질, 잠재적 문제 분석."
```

**결과**: Codex findings를 architect의 findings와 reconcile한다. `[CODEX-ONLY]` 이슈는 executor 수정 대상에 추가. `[CROSS-MODEL-CONFIRM]` 이슈는 우선 수정 대상.

**Codex 실패 시**: `[CODEX-UNAVAILABLE]` 태깅 후 architect 리뷰만으로 진행.

## Step 13: Dead Code Cleanup (max 10: `step13_cleanup`)

- Attempt 1-5: fix breakage
- Attempt 6-9: rollback + more conservative cleanup
- Attempt 10: skip problematic files

## Step 14: Code Quality (max 10: `step14_quality`)

- Attempt 1-5: executor improves iteratively
- Attempt 6-8: architect identifies highest-impact improvements
- Attempt 9-10: accept current quality level with justification

## Step 15: Flow Verification (max 10: `step15_flow`)

- Attempt 1-3: trace root cause → executor fix
- Attempt 4-6: architect end-to-end flow analysis → structural fix
- Attempt 7-9: simplify flow, reduce complexity
- Attempt 10: document broken flow path as known limitation

## Step 16: MEDIUM Issues (max 10: `step16`)

- Iteration 1-3: Fix one by one (highest impact first)
- Iteration 4-6: Batch remaining, architect prioritizes
- Iteration 7-8: collaborative fix session
- Iteration 9: fix only security/correctness issues
- Iteration 10: record unfixed as "accepted" with risk assessment

## Step 17: Production Readiness (max 10: `step17_readiness`)

- **Attempt 1-3**: executor fixes
- **Attempt 4-6**: architect comprehensive diagnosis
- **Attempt 7-8**: **Triage mode** — Must fix / Should fix / Nice to fix → `.claude/memory/unit-{name}/triage.md`
- **Attempt 9**: security-reviewer re-evaluates real vs theoretical risks
- **Attempt 10**: fix blocking only, document everything else

## Integration (max 10: `integration_conflict`)

- Attempt 1-3: architect + executor resolve conflicts
- Attempt 4-6: semantic merge analysis (understand intent of both sides)
- Attempt 7-8: alternative integration order
- Attempt 9: partial integration (non-conflicting Units first)
- Attempt 10: last stand → AskUserQuestion with conflict details
- Post-integration build failure → Step 5 build resilience loop (max 10)

## Grind Cross-Model Diagnosis (Tier 2+ 공통)

Attempt 4에 진입하면 (Tier 2 escalation), Claude의 Root Cause Analysis와 **병렬로** Codex에 독립 진단을 의뢰한다 (`~/.claude/skills/_shared/cross-model-verification.md` 참조). 기존 Claude 진단이 3회 실패했으므로, 다른 모델의 관점이 돌파구를 제공할 수 있다.

**적용 Step**: Step 5, 7, 8, 12, 17의 Attempt 4+ (Tier 2 진입 시)

**실행**:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task \
  --effort xhigh \
  "다음 에러/실패를 독립적으로 진단하라: {에러 메시지 또는 실패 테스트 목록}. 근본 원인과 수정 방향을 제시하라."
```

**결과 활용**:
- Claude 진단과 Codex 진단이 **일치** → 해당 방향으로 즉시 수정 (높은 신뢰도)
- **불일치** → Codex 진단을 먼저 시도한다 (기존 방향은 이미 실패했으므로)
- failure-log.md에 `[CROSS-MODEL-DIAGNOSIS]` 태깅으로 양쪽 진단 결과를 기록한다

**Codex 실패 시**: 기존 escalation ladder를 그대로 진행한다.

## Steps 18-20 Overrides

> **[GATE — 필수 실행]** Step 18-19는 SMALL/STANDARD/LARGE **모든 경로**에서 반드시 실행한다. grind 모드에서도 예외 없음. Step 19는 simon-code-review 스킬을 호출하여 Draft PR 생성 + 인라인 리뷰를 위임한다. 직접 `gh pr create`를 실행하는 것은 금지다.

### Step 18 추가 내용
- **18-A Report 열일 Summary section**: total retries, strategy pivots, accepted trade-offs, failure patterns, escalation reports, retry budget 사용량
- **18-B Review Sequence 추가**: strategy pivots, accepted trade-offs, retry history per change unit
- **18-C Draft PR description**: 열일 Summary 포함

### Step 19 (PR-Based Code Review) 열일 확장

#### 19-CI: CI Watch (max 10: `ci_watch_fix`)

simon의 CI Watch(max 3)를 10회로 확장하고, escalation ladder를 적용한다.

- **Cycle 1-3**: executor 직접 수정 — 로그에서 에러를 읽고 즉시 수정
- **Cycle 4-6**: architect 근본 원인 분석 → 구조적 수정
  - 같은 CI 단계가 반복 실패하면 테스트/빌드 구조 자체를 점검
  - Checkpoint: `git tag checkpoint-ci-watch-attempt{N}`
- **Cycle 7-9**: Strategy pivot
  - 테스트 전략 변경 (mock 방식, 테스트 데이터, CI 설정 조정)
  - 이전 checkpoint으로 롤백 후 다른 접근법 시도
- **Cycle 10**: Last stand — 실패 원인 + 시도 내역 상세 보고
  - `.claude/memory/ci-watch-result.md`에 전체 failure-log 기록
  - PR 코멘트로 사용자에게 수동 개입 필요 알림

CI fix도 failure-log.md에 기록하여 Step 20 피드백 종합에 반영한다.

#### 19-A: PR 리뷰 코멘트 추가 맥락
- 각 변경 단위에 열일 관련 정보 포함:
  - 전략 전환이 있었던 부분: 원래 접근법 → 최종 접근법 설명
  - 수용된 트레이드오프: 무엇을 포기했고 왜
  - 재시도 히스토리: 반복 실패했던 부분과 최종 해결 방법

#### 19-C: 피드백 루프 (max 10: `step19_review`)
- PR 피드백 수정 시 escalation ladder 적용:
  - Attempt 1-3: executor 직접 수정 + push + PR reply
  - Attempt 4-6: architect 분석 — 피드백의 근본 원인 파악 후 구조적 수정
  - Attempt 7-8: 사용자에게 대안 제시 (PR 코멘트로)
  - Attempt 9: architect + executor collaborative revision
  - Attempt 10: "needs manual attention" 으로 PR 코멘트 + escalation-report.md

#### 19-D
- CONTEXT.md에 열일 Summary 반영

### Step 20: Self-Improvement (열일 확장)
- 20-A 피드백 종합에 열일 특이사항 추가:
  - 재시도가 많았던 단계 → 워크플로에 사전 방지 메커니즘 필요?
  - 전략 전환 패턴 → escalation ladder 순서 최적화 필요?
  - 수용된 트레이드오프 → 품질 기준 조정 필요?
- failure-log.md 패턴도 스킬 개선 입력으로 활용
