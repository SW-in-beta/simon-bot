---
name: simon-bot-grind
description: "열일모드 — simon-bot의 끈질긴 변형. 모든 재시도 한계를 10으로 설정하고, 자동 진단/복구/전략 전환으로 끝까지 물고 늘어집니다. Use when: (1) 반드시 성공해야 하는 고위험 피처 (\"절대 실패하면 안 돼\", \"끝까지 해결해\", \"포기하지 마\"), (2) 빌드/테스트 실패가 잦은 복잡한 코드베이스, (3) 사람 개입 최소화하고 끝까지 자동으로 해결하고 싶을 때. simon-bot보다 더 강력한 자동 복구가 필요하면 이 스킬을 사용하세요."
compatibility:
  tools: [Agent, AskUserQuestion]
  skills: [simon-bot]
---

# simon-bot-grind

**열일모드** — 끝날 때까지 끝난 게 아니다.

## Base Workflow

**이 스킬은 simon-bot 19-step pipeline을 기반으로 합니다.**
기본 워크플로는 `~/.claude/skills/simon-bot/SKILL.md`와 그 `references/` 파일들을 따릅니다.

이 문서는 grind 전용 확장사항만 기술합니다:
- **모든 재시도 한계 = 10** (포기하지 않는다)
- **새 재시도 지점** at previously non-retrying steps
- **자동 진단 시스템** — failure tracking + strategy pivots
- **체크포인트/롤백** for safe experimentation
- **Confidence Scoring & Assumption Registry** — structured user interviews

### Session Isolation Protocol

simon-bot의 Session Isolation Protocol을 상속한다. Startup에서 SESSION_DIR을 동일하게 결정하고, 모든 `.claude/memory/` 경로를 `{SESSION_DIR}/memory/`로 해석한다. grind 전용 파일(`failure-log.md`, `checkpoints.md`, `assumptions-registry.md`, `escalation-report.md`)도 동일하게 `{SESSION_DIR}/memory/`에 저장한다.

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
  step19_review: 10             # simon-bot-review 피드백 루프 내 재시도
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
  # 조정 가이드: SMALL path는 30, STANDARD는 50(기본값), LARGE는 80.
  # 외부 API 연동이 많은 작업은 +20 가산 — 환경 변수에 의한 실패가 빈번.
  budget_warning_pct: 70        # 예산 N% 소비 시 사용자 경고

  # ── Checkpoint Policy ─────────────────────
  checkpoint_policy:
    tier_boundary: true    # Attempt 3→4, 6→7 전환 시 자동 checkpoint
    on_progress: true      # Progress Detection "진전 있음" 시 best 태그
    strategy_pivot: true   # 기존과 동일
    rollback_target: best  # pivot 시 initial 대신 best로 롤백 (없으면 initial)
```

### Reference Loading Policy

| 트리거 | 읽을 파일 |
|--------|----------|
| Startup | simon-bot SKILL.md + grind SKILL.md |
| Phase A 진입 | grind-phase-a.md + simon-bot phase-a-planning.md |
| Phase B-E 진입 | grind-phase-b.md + simon-bot phase-b-implementation.md |
| 에러 발생 시 | grind-error-resilience.md |
| Cross-cutting 참조 시 | grind-cross-cutting.md |

## Instructions

You are executing **simon-bot-grind** (열일모드). Follow the simon-bot 19-step pipeline with the overrides below. Read simon-bot's SKILL.md and references as the base, then apply grind enhancements.

**Core Philosophy: "끝날 때까지 끝난 게 아니다. 진단하고, 적응하고, 다시 시도한다."**

**Feedback-First Principle: "빠르게 꺼내고, 빠르게 실패하고, 빠르게 배운다."**
무거운 분석보다 빠른 실행 + 피드백이 더 나은 결과를 만든다. Attempt 1-3에서는 과도한 root cause analysis 없이 빠르게 수정을 시도하고, 실패로부터 학습한 정보를 다음 시도에 즉각 반영한다. 분석은 Attempt 4부터 깊어진다.

**Anti-Hardcoding Principle: "테스트를 속이지 않는다."**
재시도가 쌓일수록 "일단 통과만 시키자"는 유혹이 커지지만, 특정 입력값에 대한 하드코딩은 다른 입력에서 깨진다. 항상 일반적 해결책을 구현하고, 테스트가 잘못된 것 같으면 우회하지 말고 보고한다.

## Cross-Cutting: Error Resilience (Enhanced)

모든 실패를 세분화된 트리 구조(ENV_INFRA/CODE_LOGIC 및 하위 유형)로 분류한 후 **10회까지** 자동 복구한다. Escalation Ladder를 소진하기 전에 사용자에게 넘기지 않는다 -- 자동 복구 여지가 있는데 사용자에게 떠넘기는 것은 grind의 가치를 낭비하는 것이기 때문이다.
For detailed 10-attempt ladder + error classification tree, read [grind-error-resilience.md](references/grind-error-resilience.md).

## Cross-Cutting: Auto-Diagnosis, Checkpoints, Confidence, Progress Detection, Retry Budget

- **Auto-Diagnosis**: 모든 실패를 failure-log.md에 기록, 패턴 감지 후 전략 전환
- **Progress Detection**: 매 재시도 후 이전 결과와 구조적 비교 (실패 수, 에러 메시지, 변경 라인 수). 진전 없는 재시도가 2회 연속되면 즉시 전략 전환 -- 같은 접근법의 무의미한 반복을 방지한다.
- **Total Retry Budget**: 워크플로 전체에 총 재시도 예산(기본 50회) 적용. 70% 소비 시 경고, 100% 소비 시 사용자 승인 필요 -- 개별 Step에만 집중하다 전체 비용을 놓치는 것을 방지한다.
- **Checkpoint**: 전략 전환 전 `git tag checkpoint-step{N}-attempt{M}` -- 롤백 가능
- **Confidence Scoring**: Phase A 모든 agent 출력에 confidence + impact 태깅, assumptions-registry.md 추적
- **Progress Pulse**: 연속 3회 실패 / 전략 전환 / 누적 15회 재시도 / 예산 70% 소비 시 사용자에게 중간 상황 보고. 자동 조종 중에도 주기적 경로 확인이 필요하다.

For detailed protocols, read [grind-cross-cutting.md](references/grind-cross-cutting.md).

## Cross-Cutting: Phase-End Auto-Retrospective

simon-bot의 Phase-End Auto-Retrospective 프로토콜을 상속한다. 동일 시점(Phase A 완료, Unit 완료, Integration 완료)에서 user-feedback-log.md를 스캔하고, 패턴 감지 시 boost-capture를 백그라운드로 자동 트리거한다. grind의 retry가 많을수록 사용자 교정 빈도도 높아지므로, Phase-end 회고의 가치가 더욱 크다.

## Cross-Cutting: Docs-First Protocol

simon-bot의 Docs-First Protocol을 상속한다 (`~/.claude/skills/simon-bot/references/docs-first-protocol.md` 참조). 재시도 맥락에서 특히 중요: 학습 데이터 기반 기억으로 구현했다가 실패한 경우, 재시도 전에 반드시 공식 문서를 조회하여 정확한 API/설정을 확인한다.

## Cross-Cutting: Cognitive Independence

simon-bot의 Cognitive Independence 프로토콜을 상속한다. 검증 에이전트의 독립성은 grind에서 특히 중요하다 — 10회 재시도 압력 하에서 검증 에이전트가 "이번에는 봐주자"는 태도를 가지면 품질이 급격히 저하된다.
For detailed protocol, read `~/.claude/skills/simon-bot/references/context-separation.md`.

## Startup

simon-bot Startup과 동일 (P-001 브랜치명 자동 생성, P-009 Handoff Manifest 감지 포함) + 추가:
3. **Initialize failure tracking**: `.claude/memory/failure-log.md` 생성/초기화 (Handoff Manifest의 `failure_context`가 있으면 초기값으로 설정)
4. **Initialize checkpoints**: `.claude/memory/checkpoints.md` 생성/초기화

## Phase A: Planning (Enhanced with Structured Interviews)

simon-bot Phase A를 따르되, grind 확장사항을 적용합니다.
For detailed Phase A enhancements, read [grind-phase-a.md](references/grind-phase-a.md).

**주요 변경사항:**
- **Step 0**: Assumption collection 추가 — 모든 가정에 confidence/impact 태깅
- **Step 1-A-B** (NEW): Code Design Team 분석 결과를 도메인별 순차 인터뷰로 사용자 검증
- **Step 1-B**: 3-Phase 구조 (Draft → 도메인별 순차 인터뷰 5 rounds → Finalization)
- **Steps 2-4**: `[USER-ESCALATION]` tag + deadlock breakers (5: mediator, 7: compromise, 9: force)
- **Step 4-B**: 4-Phase Interactive Resolution (Classify → Technical → Interactive → Synthesis)

## Phase B-E: Implementation (Enhanced with Retry)

simon-bot Phase B-E를 따르되, 모든 Step에 10회 retry + escalation ladder를 적용합니다.
For per-step override details, read [grind-phase-b.md](references/grind-phase-b.md).

**핵심 패턴 (모든 Step 공통):**
- Attempt 1-3: Simple fix (`executor`)
- Attempt 4-6: Root Cause Analysis (`architect` → `executor`)
- Attempt 7-9: Strategy Pivot (checkpoint → alternative approach)
- Attempt 10: Last Stand (architect + executor collaborative)

**Step별 주요 변경:**

| Step | Base (simon-bot) | Grind Override |
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
| 19 (simon-bot-review) | base delegation | simon-bot-review 스킬로 위임 (grind 재시도는 simon-bot-review 내부에서 적용) |

## Success Criteria (Extended)

simon-bot의 체크리스트 + 추가:
- [ ] **열일 Summary 포함** (재시도 횟수, 전략 전환, 수용된 트레이드오프, 잔여 retry budget)
- [ ] **모든 에스컬레이션 리포트 해결됨 또는 문서화됨**
- [ ] **failure-log.md 패턴이 Step 20 피드백 종합에 반영됨**
- [ ] **Anti-hardcoding 준수** (테스트 통과를 위한 하드코딩 없음)

## Context Window Management

simon-bot과 동일한 세션 분할 경계. **추가 주의**: 재시도가 많을수록 컨텍스트 소비가 빠르므로, 경계 2 전에 잔여량을 반드시 확인.

## Memory Persistence (Extended)

simon-bot에 추가:
- **On every failure**: failure-log.md entry (+ retry budget 잔여량 갱신)
- **On every strategy pivot**: checkpoint tag + pivot description
- **On every escalation**: escalation-report.md

Always read `.claude/memory/failure-log.md` AND relevant memory files before starting any step.

## Global Forbidden Rules / Session Management / Unresolved Decision Tracking

simon-bot과 동일. Unresolved Decision Tracking에 추가:
- **Accepted trade-offs**: Step 17 triage에서 수용된 이슈
- **Skipped improvements**: retry 예산 내 해결 불가한 품질 이슈
