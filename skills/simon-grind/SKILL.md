---
name: simon-grind
description: "열일모드 — simon-dev의 끈질긴 변형. 모든 재시도 한계를 10으로 설정하고, 자동 진단/복구/전략 전환으로 끝까지 물고 늘어집니다. Use when: (1) 반드시 성공해야 하는 고위험 피처 (\"절대 실패하면 안 돼\", \"끝까지 해결해\", \"포기하지 마\"), (2) 빌드/테스트 실패가 잦은 복잡한 코드베이스, (3) 사람 개입 최소화하고 끝까지 자동으로 해결하고 싶을 때. simon-dev이 실패했거나 반복 재시도가 필요한 작업에 적합합니다. Do NOT use when: 사용자가 끈질긴 해결을 명시적으로 요청하지 않은 일반 피처 구현 — simon-dev로 충분하다. simon-dev이 3회+ 실패한 작업을 이어받을 때도 적합하다."
compatibility:
  tools: [Agent, AskUserQuestion]
  skills: [simon-dev]
---

# simon-grind

**열일모드** — 끝날 때까지 끝난 게 아니다.

## Base Workflow

**이 스킬은 simon-dev 19-step pipeline을 기반으로 합니다.**
기본 워크플로는 `~/.claude/skills/simon-dev/SKILL.md`와 그 `references/` 파일들을 따릅니다.

이 문서는 grind 전용 확장사항만 기술합니다:
- **모든 재시도 한계 = 10** (포기하지 않는다)
- **새 재시도 지점** at previously non-retrying steps
- **자동 진단 시스템** — failure tracking + strategy pivots
- **체크포인트/롤백** for safe experimentation
- **Confidence Scoring & Assumption Registry** — structured user interviews

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules, Agent Teams, Cognitive Independence 공통 프로토콜 포함.

### Session Isolation Protocol (확장)

grind 전용 파일(`failure-log.md`, `checkpoints.md`, `assumptions-registry.md`, `escalation-report.md`)도 동일하게 `{SESSION_DIR}/memory/`에 저장한다.

### Grind Scripts

`scripts/` 디렉토리의 결정론적 스크립트로 grind 핵심 메커니즘을 강제한다. LLM 기억에 의존하면 compaction 후 상태를 잃을 수 있으므로, 스크립트 출력에 기반하여 판단한다.

- `progress-detect.sh <failure-log>` — 최근 2건 재시도 비교 → `PROGRESS`/`STALL`/`REGRESS` JSON 출력. Stall detection의 판정 근거로 사용.
- `budget-tracker.sh <failure-log> [budget]` — 잔여 예산 JSON 출력. 70%+ 소비 시 `warning: true`. 매 재시도 시작 전에 실행하여 예산 상태를 확인한다.
- `checkpoint.sh <step> <attempt> <checkpoints-md>` — `git tag checkpoint-step{N}-attempt{M}` + checkpoints.md 원자적 갱신. 전략 전환 전에 반드시 실행한다.

## Grind Config Overrides

```yaml
loop_limits:
  # ── Existing (ALL → 10) ──────────────────────
  critic_planner: 10            # 3 → 10  (Step 2)
  step4b_critical: 10           # 2 → 10  (Step 4-B)
  step7b_recheck: 10            # 1 → 10  (Step 7-B)
  step7_8: 10                   # 2 → 10  (Step 7-8)
  step16: 10                    # 3 → 10  (Step 16)
  step6_executor: 10            # 3 → 10  (Step 6)

  # ── New Retry Points (ALL = 10) ──────────────
  step5_build_retry: 10         # build/test failure retry
  step5_strategy_pivot: 10      # full strategy pivot
  step9_11_refactor: 10         # refactoring loop
  step12_major: 10              # review loop
  step17_readiness: 10          # production readiness
  step19_review: 10             # simon-code-review 피드백 루프 내 재시도
  ci_watch_fix: 10              # CI failure auto-fix cycles
  expert_consensus_extra: 10    # extra discussion rounds
  integration_conflict: 10      # conflict resolution
  test_env_setup: 10            # test environment setup
  step13_cleanup: 10            # dead code cleanup
  step14_quality: 10            # quality improvement
  step15_flow: 10               # flow verification

  # ── Interview Protocol ───────────────────────
  interview_max_rounds: 5
  confidence_threshold: 0.85
  step1a_verification: true
  step2_4_escalation: true
  step4b_interactive: true
  max_questions_per_round: 5

  # ── Auto-Diagnosis ──────────────────────────
  diagnosis_threshold: 5        # Failures before root cause analysis
  pivot_threshold: 10           # Strategy pivots before human escalation

  # ── Progress Detection ─────────────────────
  stall_threshold: 2            # 진전 없는 연속 재시도 N회 시 전략 즉시 전환
  # 조정 가이드: 단순 버그 수정은 2(기본값) 유지.
  # 아키텍처 수준 변경이나 복잡한 통합 작업은 3-4로 상향 —
  # 이런 작업은 3~4회차에 누적 이해로 해결되는 경우가 있다.

  # ── Total Retry Budget ─────────────────────
  total_retry_budget: 50        # 워크플로 전체 재시도 예산
  # 조정 가이드: STANDARD는 50(기본값), LARGE는 80.
  # 외부 API 연동이 많은 작업은 +20 가산 — 환경 변수에 의한 실패가 빈번.
  budget_warning_pct: 70        # 예산 N% 소비 시 사용자 경고

  # ── Checkpoint Policy ─────────────────────
  checkpoint_policy:
    tier_boundary: true    # Attempt 3→4, 6→7 전환 시 자동 checkpoint
    on_progress: true      # Progress Detection "진전 있음" 시 best 태그
    strategy_pivot: true   # 기존과 동일
    rollback_target: best  # pivot 시 initial 대신 best로 롤백 (없으면 initial)

  # ── Per-Attempt Efficiency ───────────────
  per_attempt_warning_turns: 30   # 개별 attempt가 30턴 이상 소비 시 경고
  total_turns_warning: 200        # 전체 누적 턴이 200 이상 시 사용자에게 경고
```

### Reference Loading Policy

| 트리거 | 읽을 파일 |
|--------|----------|
| Startup | grind SKILL.md + simon-dev의 workflow-state.json 스키마 및 Reference Loading Policy 테이블만 참조 (전체 SKILL.md 로딩은 Phase 진입 시) |
| Phase A 진입 | grind-phase-a.md + simon-dev phase-a-planning.md |
| Phase B-E 진입 | grind-phase-b.md + simon-dev phase-b-implementation.md |
| 에러 발생 시 | grind-error-resilience.md |
| Cross-cutting 참조 시 | grind-cross-cutting.md |
| 코드 탐색 시 (graphify-out/ 존재 시) | `~/.claude/skills/_shared/graphify-context.md` — 그래프 기반 탐색으로 진입점·영향범위 파악 효율화 |
| Startup (workflow-state.json 초기화 후) | `~/.claude/skills/_shared/monitor-protocol.md` | on-demand, monitor 미실행 시 skip |

> **Note**: 초기 로딩을 경량화하여 grind의 재시도 집약적 특성에서 컨텍스트를 절약한다.

## Instructions

You are executing **simon-grind** (열일모드). Follow the simon 19-step pipeline with the overrides below. Read simon's SKILL.md and references as the base, then apply grind enhancements.

**Core Philosophy: "끝날 때까지 끝난 게 아니다. 진단하고, 적응하고, 다시 시도한다."**

**Feedback-First Principle: "빠르게 꺼내고, 빠르게 실패하고, 빠르게 배운다."**
무거운 분석보다 빠른 실행 + 피드백이 더 나은 결과를 만든다. Attempt 1-3에서는 과도한 root cause analysis 없이 빠르게 수정을 시도하고, 실패로부터 학습한 정보를 다음 시도에 즉각 반영한다. 분석은 Attempt 4부터 깊어진다.

**Anti-Hardcoding Principle: "테스트를 속이지 않는다."**
재시도가 쌓일수록 "일단 통과만 시키자"는 유혹이 커지지만, 특정 입력값에 대한 하드코딩은 다른 입력에서 깨진다. 항상 일반적 해결책을 구현하고, 테스트가 잘못된 것 같으면 우회하지 말고 보고한다.

### Mini-Contract Protocol

각 Attempt Tier(초기 1-3, 중기 4-6, 후기 7-9) 시작 시 현재 상태를 분석하여 Mini-Contract를 failure-log.md에 기록한다:

```json
{"tier": 2, "goal": "근본 원인 파악", "success_criteria": ["에러 분류 완료", "재현 테스트 작성"], "exit_condition": "success_criteria 충족 또는 3회 시도 소진"}
```

Progress Detection이 이 Mini-Contract의 success_criteria를 기준으로 '진전 있음/없음'을 판단한다 — 기계적 비교(실패 수, 에러 메시지)에 목적 기반 판단을 추가하여 '목표 없는 반복'을 방지한다.

## Cross-Cutting: Monitor Protocol (대시보드 연동)

simon-dev의 Monitor Protocol을 상속한다 (`~/.claude/skills/_shared/monitor-protocol.md` 참조). emit.sh가 skill을 자동 감지한다.

**grind 전용 이벤트 — 모든 재시도 시점에서 발신:**

빌드/테스트 실패 시:
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh error "{STEP_ID}" "빌드/테스트 실패" '{"message":"에러 메시지","category":"build|test|lint|type","will_retry":true,"attempt":N,"max_attempts":10}'
```

재시도 시작 시:
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh retry "{STEP_ID}" "재시도 (N/10)" '{"attempt":N,"max_attempts":10,"tier":"early|mid|late|final","strategy":"direct|modified|pivot","changes":"변경 내용","previous_error":"이전 에러"}'
```

전략 전환(pivot) 시:
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh decision "{STEP_ID}" "전략 전환" '{"decision":"새 전략","rationale":"전환 근거","alternatives":[{"option":"이전 전략","rejected_reason":"실패 사유"}]}'
```

체크포인트 생성 시:
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh artifact "{STEP_ID}" "체크포인트 생성" '{"file":"checkpoint-step{N}-attempt{M}","action":"created","summary":"전략 전환 전 체크포인트"}'
```

## Cross-Cutting: Error Resilience (Enhanced)

모든 실패를 세분화된 트리 구조(ENV_INFRA/CODE_LOGIC 및 하위 유형)로 분류한 후 **10회까지** 자동 복구한다. Escalation Ladder를 소진하기 전에 사용자에게 넘기지 않는다 -- 자동 복구 여지가 있는데 사용자에게 떠넘기는 것은 grind의 가치를 낭비하는 것이기 때문이다.
For detailed 10-attempt ladder + error classification tree, read [grind-error-resilience.md](references/grind-error-resilience.md).

## Cross-Cutting: Auto-Diagnosis, Checkpoints, Confidence, Progress Detection, Retry Budget

- **Auto-Diagnosis**: 모든 실패를 failure-log.md에 기록, 패턴 감지 후 전략 전환
- **Progress Detection**: 매 재시도 후 이전 결과와 구조적 비교. `progress-detect.sh`가 출력하는 3가지 상태별 대응:
  - `PROGRESS`: 계속 진행.
  - `STALL` (진전 없음 2회 연속): 즉시 전략 전환 — 같은 접근법의 무의미한 반복을 방지한다.
  - `REGRESS` (퇴행 — failing_tests_delta > 0 또는 새 에러 도입): checkpoint 롤백 + 세션 레벨 오염 의심 → 사용자에게 /rewind 힌트 텍스트 출력 (블로킹 X):
    ```
    [REGRESS 감지 — Step {N}, Attempt {M}]
    이전보다 실패가 {delta}건 늘었습니다. checkpoint-{tag}로 자동 롤백했습니다.
    /rewind (Esc Esc)를 사용하면 더 효과적일 수 있습니다:
      1. 파일 읽기 직후 지점으로 돌아가기
      2. 다음 제약으로 re-prompt: "{current_approach}는 {실패_이유} 때문에 불가. {suggested_alternative} 방향으로."
      3. 또는 계속 진행 (grind가 다음 tier로 자동 전환)
    ```
    사용자가 /rewind를 쓰지 않으면 grind는 다음 tier로 자동 전환. ship 모드는 출력 후 즉시 다음 tier로 진행.
- **Total Retry Budget**: 워크플로 전체에 총 재시도 예산(기본 50회) 적용. 70% 소비 시 경고, 100% 소비 시 사용자 승인 필요 -- 개별 Step에만 집중하다 전체 비용을 놓치는 것을 방지한다.
- **Checkpoint**: 전략 전환 전 `git tag checkpoint-step{N}-attempt{M}` -- 롤백 가능
- **Confidence Scoring**: Phase A 모든 agent 출력에 confidence + impact 태깅, assumptions-registry.md 추적
- **Progress Pulse**: 연속 3회 실패 / 전략 전환 / 누적 15회 재시도 / 예산 70% 소비 시 사용자에게 중간 상황 보고. 자동 조종 중에도 주기적 경로 확인이 필요하다.

For detailed protocols, read [grind-cross-cutting.md](references/grind-cross-cutting.md).

## Cross-Cutting: Phase-End Auto-Retrospective

simon-dev의 Phase-End Auto-Retrospective 프로토콜을 상속한다. 동일 시점(Phase A 완료, Unit 완료, Integration 완료)에서 user-feedback-log.md를 스캔하고, 패턴 감지 시 boost-capture를 백그라운드로 자동 트리거한다. grind의 retry가 많을수록 사용자 교정 빈도도 높아지므로, Phase-end 회고의 가치가 더욱 크다.

## Cross-Cutting: Docs-First Protocol

simon-dev의 Docs-First Protocol을 상속한다 (`~/.claude/skills/simon-dev/references/docs-first-protocol.md` 참조). 재시도 맥락에서 특히 중요: 학습 데이터 기반 기억으로 구현했다가 실패한 경우, 재시도 전에 반드시 공식 문서를 조회하여 정확한 API/설정을 확인한다.

## Cross-Cutting: Cognitive Independence

simon-dev의 Cognitive Independence 프로토콜을 상속한다. 검증 에이전트의 독립성은 grind에서 특히 중요하다 — 10회 재시도 압력 하에서 검증 에이전트가 "이번에는 봐주자"는 태도를 가지면 품질이 급격히 저하된다.
For detailed protocol, read `~/.claude/skills/simon-dev/references/context-separation.md`.

## Startup

simon-dev Startup과 동일 (P-001 브랜치명 자동 생성, P-009 Handoff Manifest 감지 포함) + 추가:
3. **Initialize failure tracking**: `.claude/memory/failure-log.md` 생성/초기화 (Handoff Manifest의 `failure_context`가 있으면 초기값으로 설정)
4. **Initialize checkpoints**: `.claude/memory/checkpoints.md` 생성/초기화
5. **Monitor 상태 확인 + workflow_start 발신**:
   1. 모니터 실행 여부를 확인한다: `[ -f /tmp/simon-monitor.pid ] && kill -0 $(cat /tmp/simon-monitor.pid) 2>/dev/null`
   2. 모니터가 실행 중이지 않으면 사용자에게 1회 통보한다 (AskUserQuestion이 아닌 텍스트 출력):
      `[Monitor] 실시간 대시보드가 꺼져 있습니다. 원하시면 새 터미널에서 /simon-monitor를 실행하세요. 워크플로는 계속 진행합니다.`
   3. `~/.claude/skills/_shared/monitor-protocol.md` 읽기. 워크플로 시작 이벤트 발신:
   ```bash
   bash ~/.claude/skills/simon-monitor/scripts/emit.sh workflow_start "" "열일모드 워크플로 시작" '{"skill":"simon-grind","branch":"'"$BRANCH"'","task":"'"$TASK_SUMMARY"'","scope":"TBD","workflow_steps":[{"id":"A/0","name":"Scope Challenge","phase":"A"},{"id":"A/1-A","name":"Project Analysis","phase":"A"},{"id":"A/1-B","name":"Plan Creation","phase":"A"},{"id":"A/2","name":"Plan Review","phase":"A"},{"id":"A/3","name":"Meta Verification","phase":"A"},{"id":"A/4","name":"Over-engineering Check","phase":"A"},{"id":"A/4-B","name":"Expert Plan Review","phase":"A"},{"id":"B/5","name":"Implementation","phase":"B"},{"id":"B/6","name":"Purpose Alignment","phase":"B"},{"id":"B/7","name":"Code Review","phase":"B"},{"id":"B/8","name":"Regression Verification","phase":"B"},{"id":"B/17","name":"Production Readiness","phase":"B"},{"id":"review/18-A","name":"Work Report","phase":"review"},{"id":"review/18-B","name":"Review Sequence","phase":"review"},{"id":"review/19","name":"Code Review","phase":"review"}]}' \
     2>/dev/null || true
   ```
   open http://localhost:3847 2>/dev/null || true

## Phase A: Planning (Enhanced with Structured Interviews)

simon-dev Phase A를 따르되, grind 확장사항을 적용합니다.
For detailed Phase A enhancements, read [grind-phase-a.md](references/grind-phase-a.md).

**주요 변경사항:**
- **Step 0**: Assumption collection 추가 — 모든 가정에 confidence/impact 태깅
- **Step 1-A-B** (NEW): Code Design Team 분석 결과를 도메인별 순차 인터뷰로 사용자 검증
- **Step 1-B**: 3-Phase 구조 (Draft → 도메인별 순차 인터뷰 5 rounds → Finalization)
- **Steps 2-4**: `[USER-ESCALATION]` tag + deadlock breakers (5: mediator, 7: compromise, 9: force)
- **Step 4-B**: 4-Phase Interactive Resolution (Classify → Technical → Interactive → Synthesis)

## Phase B-E: Implementation (Enhanced with Retry)

simon-dev Phase B-E를 따르되, 모든 Step에 10회 retry + escalation ladder를 적용합니다.
For per-step override details, read [grind-phase-b.md](references/grind-phase-b.md).

**재시도 원칙 (모든 Step 공통):**
- 초기(1-3): 최소 변경으로 직접 수정한다. 과도한 분석보다 빠른 피드백이 낫다.
- 중기(4-6): 실패 패턴을 분석하여 근본 원인을 파악한 뒤 수정한다.
- 후기(7-9): 접근 방식 자체를 변경한다. checkpoint로 안전망을 확보한 뒤 대안을 시도한다.
- 최종(10): 사용 가능한 모든 정보를 종합하여 최후 시도한다.

각 Step에서 "근본 원인 분석"과 "접근 방식 변경"의 구체적 의미는 Step 성격에 따라 다르다 — Step 5(빌드 실패)의 전략 전환과 Step 12(코드 리뷰)의 전략 전환은 완전히 다른 행동이기 때문이다. 상세는 grind-phase-b.md 참조.

**Step별 주요 변경:**

| Step | Base (simon-dev) | Grind Override |
|------|------------------|----------------|
| 5 | No build retry | **10 retries + 10 pivots**, checkpoint system |
| 6 | 3 auto-fix | **10** with requirement re-analysis |
| 7-B | 1 re-review | **10** with architectural limitation detection |
| 7-8 | 2 loops | **10** with root cause + strategy pivot |
| 9-11 | No loop | **10** with rollback to checkpoint-step9 |
| 12 | No loop | **10** with mediation + trade-off negotiation |
| 13-15 | No retry | **10** each with progressive fallback |
| 16 | 3 iterations | **10** progressive + batch + collaborative |
| 17 | No retry | **10** with triage mode |
| Integration | No retry | **10** with semantic merge + partial integration |
| 19 (simon-code-review) | base delegation | simon-code-review 스킬로 위임 (grind 재시도는 simon-code-review 내부에서 적용) |

## Success Criteria (Extended)

simon-dev의 체크리스트 + 추가:
- [ ] **열일 Summary 포함** (재시도 횟수, 전략 전환, 수용된 트레이드오프, 잔여 retry budget)
- [ ] **모든 에스컬레이션 리포트 해결됨 또는 문서화됨**
- [ ] **failure-log.md 패턴이 Step 20 피드백 종합에 반영됨**
- [ ] **Anti-hardcoding 준수** (테스트 통과를 위한 하드코딩 없음)

## Context Window Management

simon-dev과 동일한 세션 분할 경계. **추가 주의**: 재시도가 많을수록 컨텍스트 소비가 빠르므로, 경계 2 전에 잔여량을 반드시 확인.

### Failure-Log Compaction Directive

재시도가 쌓이면서 failure-log.md가 컨텍스트의 주요 소비원이 된다. 다음 시점에서 선제적으로 `/compact`를 실행한다:

**트리거 조건** (하나라도 충족 시):
- 누적 재시도 10회 도달 (전체 예산 20% 소비)
- 컨텍스트 활용률 40% 이상 (simon-dev의 45%보다 5pp 낮게 — 재시도 자체가 컨텍스트를 빠르게 소비)
- failure-log.md 엔트리 5건 이상 누적

**Grind 전용 보존 프롬프트**:
```
keep: failure-log 마지막 3건 attempt 전체 + 나머지는 "attempt N: {에러 분류}/{요약}" 1줄로 압축.
keep: 현재 Step 번호, 잔여 retry budget, 현재 tier, 현재 Mini-Contract.
keep: 성공한 checkpoint 태그 목록 (best checkpoint).
drop: 개별 빌드 출력 전체, grep 결과 원본, 이미 완료된 Step의 에러 상세.
```

**실행 시기**: 현재 attempt 완료 직후, 다음 attempt 시작 전. attempt 도중 압축 시 수정 맥락이 유실된다.

**ship 모드**: 보존 프롬프트를 자동 적용하여 사용자 확인 없이 실행.
**guided 모드**: 보존 프롬프트를 제안하고 사용자 추가 항목 확인 후 실행.

## Memory Persistence (Extended)

simon-dev에 추가:
- **On every failure**: failure-log.md entry (+ retry budget 잔여량 갱신)
- **On every strategy pivot**: checkpoint tag + pivot description
- **On every escalation**: escalation-report.md

Always read `.claude/memory/failure-log.md` AND relevant memory files before starting any step.

## Global Forbidden Rules / Session Management / Unresolved Decision Tracking

simon-dev과 동일. Unresolved Decision Tracking에 추가:
- **Accepted trade-offs**: Step 17 triage에서 수용된 이슈
- **Skipped improvements**: retry 예산 내 해결 불가한 품질 이슈
