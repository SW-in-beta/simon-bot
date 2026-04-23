# Phase B-E: Implementation & Verification (Detailed Instructions)

After Phase A is confirmed, use background agents (`Agent(run_in_background=true)`) for parallel unit execution.
Each Unit runs in an **isolated git worktree**. Independent Units run in **parallel**.

## 목차
- [Pre-Phase: Base Branch Sync & Worktree 생성](#pre-phase-base-branch-sync--worktree-생성)
  - [Unit Runbook 자동 생성](#unit-runbook-자동-생성)
  - [CONTEXT.md 생성](#contextmd-생성)
- [Critical Rules](#critical-rules)
- [Pre-Step: Test Environment Setup](#pre-step-test-environment-setup)
- [Step 5: Implementation (TDD 필수)](#step-5-implementation-tdd-필수)
  - [기존 구현 참조 (P-013)](#기존-구현-참조-p-013)
  - [TDD Cycle (RED → GREEN → REFACTOR)](#tdd-cycle-red--green--refactor)
  - [Test Case Summary 생성 (Step 5c-post)](#test-case-summary-생성-step-5c-post)
  - [Test-Spec Alignment Gate](#test-spec-alignment-gate)
  - [Agent 출력물 검증 게이트](#agent-출력물-검증-게이트)
  - [Inline Issue Capture (P-010)](#inline-issue-capture-p-010)
  - [Ground Truth 검증 게이트](#ground-truth-검증-게이트)
  - [Post-Implementation Simplicity Check](#post-implementation-simplicity-check)
  - [Step 5 Common Rationalizations](#step-5-common-rationalizations)
  - [Self-correction (Step 6 전 자가 검증)](#self-correction-step-6-전-자가-검증)
- [Step 6 이후: Verification](#step-6-이후-verification)

## Step I/O Interface

각 Step의 입력과 출력 아티팩트. 새 세션에서 Step N을 시작하려면 `Input` 파일들이 SESSION_DIR에 있어야 한다.

| Step | Input (필수) | Output (생성) |
|------|-------------|--------------|
| Pre-Phase | `memory/plan-summary.md`, `memory/expert-plan-concerns.md`, `memory/code-design-analysis.md`, `memory/verify-commands.md` | `CONTEXT.md`, `memory/unit-{name}/runbook.md` |
| Step 5 | `memory/unit-{name}/runbook.md`, `memory/code-design-analysis.md`, `memory/verify-commands.md` | `memory/unit-{name}/test-case-summary.md`, `memory/unit-{name}/inline-issues.md`, `memory/unit-{name}/implementation.md` |

## Pre-Phase: Base Branch Sync & Worktree 생성

> **[GATE — Remote Sync]** 브랜치 생성 전 원격 동기화는 **필수**다. `git fetch` 없이 브랜치를 생성하면 stale한 로컬 main을 기반으로 작업하게 되어, 원격에 이미 머지된 커밋(다른 팀원의 변경, 버그 수정 등)을 놓치고 conflict가 발생할 수 있다.

1. default branch 감지 (`auto`이면 main/master 자동 감지)
2. `.claude/memory/branch-name.md`에서 사용자가 입력한 브랜치명 읽기
3. **[필수] `scripts/create-branch.sh`로 브랜치 생성** — 원격 동기화 + `origin/{base_branch}` 기반 생성을 구조적으로 보장:
   ```bash
   bash ~/.claude/skills/simon-dev/scripts/create-branch.sh {branch-name} {base_branch} true
   ```
   - 인자: `<branch-name> [base-branch=main] [use-worktree=true]`
   - 스크립트가 `git fetch origin {base_branch}` → `origin/{base_branch}` 기반 worktree/branch 생성 → base commit SHA 출력을 순차 수행
   - `set -e`로 fetch 실패 시 자동 중단 — fetch 없이 브랜치를 생성하는 것을 구조적으로 방지
4. 해당 worktree로 작업 디렉토리 이동
5. base commit SHA를 `.claude/memory/base-commit.md`에 기록 (스크립트 출력의 마지막 줄에서 추출)
6-B. **session-meta.json 갱신**: Phase B 진입을 반영한다.
   ```json
   { "current_phase": "B", "current_step": 5, "last_activity": "{ISO-8601}" }
   ```
   session-meta.json이 없으면 Startup에서 생성되지 않은 것이므로, Startup의 3-D 스키마로 초기화한 뒤 갱신한다.
7. **[GATE — Base Stability]** worktree에서 빌드+기존 테스트를 실행하여 base branch가 안정적인지 검증한다. 깨진 base 위에 구현하면 Phase B 전체가 낭비되기 때문이다.
   - `verify-commands.md`의 빌드/테스트 명령 실행
   - **PASS** → Unit Runbook 생성으로 진행
   - **FAIL** → 구현 진입 차단. 실패 원인을 분석하고 대응:
     - base branch 자체의 문제 → 사용자에게 보고 (`[Base Unstable] {실패 요약} — base branch 수정이 필요합니다.`)
     - 환경 설정 문제 (의존성 미설치 등) → setup-test-env.sh 재실행 후 재시도 (최대 2회)
   - **테스트 환경 미구성 시** (setup-test-env.sh exit code 1): 빌드+타입체크만 통과하면 PASS로 간주

**중요:** 현재 로컬 브랜치를 checkout/변경하지 않음 (안전)

### Unit Runbook 자동 생성

`plan-summary.md`에서 현재 Unit에 해당하는 정보만 추출하여 `.claude/memory/unit-{name}/runbook.md`를 생성한다. executor 에이전트에게 전체 계획서 대신 이 runbook만 전달하여 컨텍스트 소비를 줄이고 집중도를 높인다.

```markdown
# Unit Runbook: {name}

## 목표
{plan-summary.md의 해당 Unit 설명}

## 변경 파일
{Files Changed 테이블에서 해당 Unit 파일만 필터}

## Done-When Checks
{Acceptance Criteria의 해당 Unit Done-When 항목}

## 주의사항
{expert-plan-concerns.md에서 해당 파일/도메인 관련 HIGH+ 항목만 필터}

## Decision Authority

plan-summary.md의 Files Changed 테이블과 code-design-analysis.md가 아래 기준의 판단 근거다.

### 자율 결정 (보고 불필요)
- Files Changed 테이블에 명시된 파일 내의 구현 세부사항 (내부 함수 분할, 변수/상수 네이밍)
- code-design-analysis.md 패턴 범위 내의 에러 처리 방식 선택
- 테스트 헬퍼/픽스처 설계
- 코드 내 주석/구조 정리

### 통보 후 진행 (decision-journal에 기록)
- Files Changed에 없는 파일 수정 (1-2개 이내)
- 기존 함수의 시그니처 변경 (파라미터 추가/타입 변경)
- 새 유틸리티 함수/상수 정의

### 에스컬레이션 필수 (오케스트레이터 판단 대기)
- 새 패키지/모듈/디렉토리 생성
- 외부 의존성(라이브러리) 추가
- 다른 Unit의 파일 수정
- plan-summary.md의 AC와 충돌하는 구현 방향
- Done-When Checks를 달성할 수 없다고 판단될 때

## 참고 컨텍스트
{code-design-analysis.md에서 해당 파일/모듈의 컨벤션 발췌}
```

### CONTEXT.md 생성

워크트리 루트에 `CONTEXT.md` 생성하고, `.git/info/exclude`에 추가 (커밋에서 제외).

```markdown
# [브랜치명]: [작업 요약]

## 목표
[plan-summary.md에서 Goal 발췌]

## 현재 진행 상태
- [x] Phase A: Planning
- [ ] Step 5: Implementation (TDD)
- [ ] Step 6: Purpose Alignment
- [ ] Step 7: Expert Review
- [ ] Step 8: Regression Verification
- [ ] Steps 9-16: Refinement Cycle (STANDARD+ only)
- [ ] Step 17: Production Readiness
- [ ] Integration
- [ ] Step 18: Work Report + Draft PR
- [ ] Step 19: PR-Based Code Review

## 핵심 결정사항
[plan-summary.md에서 주요 결정 발췌]

## 주의사항 (전문가 우려)
[expert-plan-concerns.md에서 HIGH 이상 발췌]

## 현재 상태
- **진행 중**: Step {N} — {설명}
- **마지막 검증**: {build/test/lint 결과 1줄 요약}
- **블로커**: (없으면 생략)

## 성공 기준
- [ ] RED→GREEN TDD 사이클 완료
- [ ] 전체 테스트 통과 (0 failures)
- [ ] 빌드 + 타입체크 통과
- [ ] 보안 리뷰 CRITICAL 없음
- [ ] 코드 리뷰 통과
- [ ] 사용자 가이드 리뷰 완료
- [ ] 미해결 결정사항 문서화됨
- [ ] CONTEXT.md 최종 갱신됨

## 실행 로그
| Step | 시작 | 종료 | 결과 | 비고 |
|------|------|------|------|------|
| 5 | — | — | — | — |

## 알려진 이슈
- (현재 없음)

## 메모리 파일 맵
- plan-summary.md — 전체 계획
- code-design-analysis.md — 코드 설계 분석
- expert-plan-concerns.md — 전문가 우려사항
- success-criteria.md — 완료 체크리스트
```

**갱신 시점**: 각 Step 완료 시 즉시 해당 항목을 갱신한다. 여러 Step을 한꺼번에 모아서 갱신하지 않는다. 또한 Step 내에서도 중요 이벤트(전략 변경, 블로커 발생, 검증 실패 등) 발생 시 "현재 상태"와 "실행 로그"를 즉시 갱신하여 컨텍스트 압축 후에도 최신 상태를 복원할 수 있도록 한다.

**Step Output Artifacts** (Step 5 진입 전 필요):
- `CONTEXT.md` — 브랜치 목표·현재 진행 상태·핵심 결정·주의사항을 담은 워크트리 루트 파일. 새 세션에서 단독 로딩으로 Phase B 전체 컨텍스트 복원 가능
- `memory/unit-{name}/runbook.md` — Unit별 목표·변경 파일·Done-When Checks·주의사항·Decision Authority 요약

## Critical Rules

- All verification/review: ONLY changed files (git diff based). 변경하지 않은 파일을 리뷰하면 노이즈가 증가하고 핵심 변경점을 놓칠 수 있다.
- Use `.claude/workflow/scripts/*.sh` for deterministic tasks (save context)
- Record findings in `.claude/memory/unit-{name}/*.md` after each step
- **병렬 Unit 파일 격리**: 병렬 Unit 실행 시 공유 파일(decision-journal.md, failure-log.md 등)에 동시 쓰기를 방지한다. 각 Unit은 자신의 `unit-{name}/` 디렉토리에만 기록하고, Integration Stage에서 오케스트레이터가 병합한다. session-scoped 파일(retrospective.md, project-memory.json)은 오케스트레이터만 기록한다.
- Read memory files at start of each step
- **테스트 격리**: 테스트는 mock/stub으로 외부 의존성을 격리한다. 테스트가 실제 DB나 외부 API를 호출하면 프로덕션 데이터가 손상되거나 의도치 않은 외부 요청이 발생하기 때문이다.
- Commands: NEVER access real external systems. CONTEXT-SENSITIVE 규칙에 해당하는 경우 SKILL.md의 판단 절차를 따른다.
- **코드 확인 후 의견**: 파일은 Read로 열어본 후에 의견을 제시한다. 추측 기반 수정은 기존 코드의 숨겨진 의도를 놓쳐 새로운 버그를 만들기 때문이다.
- **Intent-Before-Fix Gate**: 기존 코드를 **제거, 단순화, 또는 "버그"로 판단**하여 수정하기 전에 다음을 순서대로 확인한다 (버그 수정뿐 아니라 "중복 제거", "불필요한 검증 삭제", "단순화" 판단에도 동일하게 적용한다):
  1. `git blame {file}` — 해당 라인의 작성자와 커밋 해시 확인
  2. `git show {commit_hash}` — 커밋 전체를 확인하여 if/else 양쪽에서 동일 작성자가 서로 다른 패턴을 사용했는지 확인
  3. 커밋 메시지 또는 PR 설명을 읽어 의도 파악
  4. 같은 커밋/작성자가 if와 else에 다른 패턴을 사용했다면 → 의도적 설계로 가정, 수정 전 decision-journal에 근거 기록 후 사용자에게 확인
  이 게이트는 리뷰 중 발견된 패턴 불일치(if vs else, A 함수 vs B 함수 등)에 필수 적용한다.
- **일반적 해결책 우선**: 모든 유효한 입력에 대해 올바르게 동작하는 일반적 해결책을 구현한다. 특정 테스트 입력에 맞춘 하드코딩은 해당 테스트만 통과시키고 실제 문제를 숨기기 때문이다.
- **Auto-Verification Hook**: 소스코드 파일 수정(Edit/Write) 후 `verify-commands.md`의 빌드/린트 명령을 즉시 실행한다. 실패 시 **Stop-and-Fix Gate 적용** — 수정 완료 전까지 다음 작업 진행 금지. `.md`, `.json` 등 비소스코드는 제외. (SKILL.md Cross-Cutting Protocol 참조)
- **Step Transition Gate**: Step N에서 Step N+1로 진입하기 전에 `verify-commands.md`의 빌드/린트/테스트를 실행하여 전부 통과해야 한다. 이전 Step의 미수정 실패를 다음 Step으로 넘기면 디버깅이 기하급수적으로 어려워진다. 실패 시 Stop-and-Fix Gate가 자동 발동된다. (모든 경로에서 적용)
- **Plan Immutability**: Phase A에서 확정된 `plan-summary.md`는 Phase B 이후 암묵적으로 변경할 수 없다. 변경이 필요한 경우 다음 절차를 따른다: (1) 변경 사유를 `.claude/memory/plan-amendments.md`에 기록, (2) 영향받는 Unit/Step 식별, (3) 사용자에게 변경 승인 요청 (AskUserQuestion), (4) 승인 후 plan-summary.md와 관련 memory 파일 일괄 갱신. 이 절차 없이 계획을 조용히 변경하면 Acceptance Criteria와 실제 구현이 괴리되어 Step 17에서 대규모 재작업이 발생한다.
- **Step Progress Pulse (P-007)**: 각 Step 완료 시 사용자에게 1줄 상태를 출력한다 (AskUserQuestion이 아닌 단순 텍스트 출력이므로 사용자를 중단시키지 않는다). 형식: `[Step {N}/{total}] {Step명} 완료 — {핵심 결과 요약}`. 예: `[Step 7/17] Expert Review 완료 — CRITICAL 0, HIGH 2, MEDIUM 5`. Phase B-E 시작 시 예상 Step 수를 안내한다: `{경로} 경로: Steps 5-{N} ({M} steps)`.

  **2-Tier Pulse (FAIL/HIGH+ 시 자동 확장)**:

  Tier 1(항상 출력)은 기존 형식을 유지한다. FAIL/CRITICAL/HIGH가 있을 때만 Tier 2(3-5줄 상세)를 자동 추가하여, 사용자가 memory 파일을 직접 읽지 않고도 핵심 이슈와 처리 결과를 파악할 수 있게 한다.

  ```
  Tier 1: [Step 7/17] Expert Review 완료 — CRITICAL 0, HIGH 2, MEDIUM 5
  Tier 2 (HIGH+ 있을 때만):
    - [Performance] N+1 쿼리 — internal/repo/user.go:47 → eager loading 적용 완료
    - [Security] Rate limiting 부재 — internal/handler/auth.go:23 → middleware 추가 완료
  ```

  auto-resolve된 항목은 `→ {수정 내용} 완료`로 표시한다. 미해결 항목은 `→ [미해결] {사유}` 태그를 붙인다.

  Tier 2가 5줄을 초과할 경우, CRITICAL/HIGH만 포함하고 나머지는 `  + MEDIUM {N}건 (상세: unit-{name}/review-findings.md)` 1줄로 요약한다.

## Pre-Step: Test Environment Setup

- Run `.claude/workflow/scripts/setup-test-env.sh`
- **Exit code 해석:**
  - `0` = 환경 준비 완료 → 테스트 진행
  - `1` = toolchain 문제 → 테스트 skip, build/typecheck 진행
  - `2` = **ENV_INFRA 실패** → Error Resilience의 ENV_INFRA 복구 Ladder 적용 (최대 5회)
- Docker/docker-compose 자동 감지, 포트 충돌 감지 포함
- Save result: `.claude/memory/test-env-status.md`

## Step 5: Implementation (TDD 필수)

- **먼저 읽기**: `expert-plan-concerns.md`, `code-design-analysis.md`, `verify-commands.md`
- **검증 명령 활용**: `verify-commands.md`에 기록된 통합 검증 명령을 TDD 사이클의 VERIFY 단계에서 사용. 프로젝트 고유의 lint/build/test를 한번에 실행하여 빠른 피드백을 확보한다.
- **Docs-First**: 처음 사용하는 라이브러리 API·DB 기능·프레임워크 설정은 구현 전 context7 또는 WebFetch로 공식 문서를 조회한다. 코드베이스에 이미 동일 패턴이 있으면 생략 가능.
**▶ EMIT** `subagent_spawn` @ `B/5` — executor 서브에이전트 시작
```bash
$E --step "B/5" --type subagent_spawn \
  --title "executor 서브에이전트 시작" \
  --data '{"agent_name":"executor","agent_type":"general-purpose","task":"TDD 구현","background":true}' \
  2>/dev/null || true
```

- Spawn `executor`, parallel for independent files (maxTurns: SKILL.md Subagent 사용 기준 테이블 참조 — STANDARD 100, LARGE 200)
- executor에게 코드를 전달할 때도 Context Preparation 원칙을 적용한다 — 파일 전체가 아닌 변경 대상 함수/메서드 단위로 추출하고, diff는 노이즈를 제거한 후 전달한다.
- executor는 code-design-analysis.md의 컨벤션과 패턴을 따라 구현
- 전문가 우려사항 중 HIGH 이상 항목을 구현 시 반드시 고려

### 기존 구현 참조 (P-013)

executor는 구현을 시작하기 전에 유사 기능의 기존 구현을 먼저 찾아야 한다:

1. **유사 구현 탐색**: 현재 구현할 기능과 유사한 기존 구현을 2-3개 찾는다. 함수 이름이 아닌 기능의 목적으로 검색한다 (Multi-term search: 동의어/관련어 활용)
2. **패턴 기록**: 발견된 구현체의 에러 처리 스타일, 리턴 타입, 네이밍 규칙, 테스트 구조를 메모한다
3. **패턴 따르기**: code-design-analysis.md가 다른 패턴을 명시적으로 권장하지 않는 한, 발견된 기존 패턴을 따른다
4. **검색 결과 0건 시**: 다른 용어로 최소 2회 재시도한 후에 "유사 구현 없음"으로 판단한다

이를 통해 기존 코드베이스와 일관된 구현을 보장하고, 이미 검증된 패턴을 재활용한다.

### TDD Cycle (RED → GREEN → REFACTOR)

TDD 사이클을 따르는 이유: 테스트를 먼저 작성하면 요구사항을 코드로 명세화하고, 구현이 요구사항을 충족하는지 즉시 확인할 수 있다.

- **Step 5a: RED** — 실패하는 테스트 먼저 작성하고, 테스트가 실패하는지 확인한다
- **Step 5b: GREEN** — 테스트를 통과시키는 최소한의 구현 코드를 작성하고, 테스트 통과를 확인한다
- **Step 5c: REFACTOR** — 테스트 통과 상태를 유지하며 코드를 정리한다. 불필요하면 skip
- **Step 5c-post: Test Case Summary** — 아래 [Test Case Summary 생성](#test-case-summary-생성-step-5c-post) 섹션 참조
- **Step 5d: VERIFY** — 전체 테스트 스위트를 실행한다. 모든 테스트가 통과한 후에 다음 단계로 진행한다
- **Step 5e: Working Example Spot-check** — Unit 구현 완료 후, plan-summary.md의 Behavior Changes에서 핵심 시나리오 1개를 선택하여 실제 동작을 확인한다 (테스트 통과 ≠ 실제 동작). CLI 실행, curl dry-run, 또는 사용 예제 코드 실행으로 검증. 실패 시 Step 5b로 회귀.

### TDD Cycle 반성 단계

각 TDD 단계의 도구 결과를 받은 직후, 다음 동작으로 넘어가기 전에 결과의 의미를 반성한다. 도구 결과에 곧바로 반응하면 false green(잘못된 이유로 통과)이나 부수적 실패를 놓칠 수 있기 때문이다.

**RED 이후 — Contrastive Failure Validation (CP-008, 필수)**:

테스트 실패 로그를 확인한 후, 다음 두 가지를 명시적으로 작성한다:

1. **"올바른 이유로 실패하는 증거"**: 실패 메시지가 AC와 직접 연결되는 부분을 인용한다. 예: `AssertionError: expected 401 but got 200` → AC의 "잘못된 비밀번호 시 401 반환"과 대응
2. **"잘못된 이유로 실패할 가능성"**: import 오류, 설정 누락, fixture 미생성, 테스트 자체의 버그 등 AC와 무관한 실패 원인을 나열한다

두 번째 항목에서 후보가 발견되면, 해당 가능성을 먼저 제거한 후 GREEN 단계로 진행한다. "올바른 이유로 실패하는 증거"를 먼저 작성하여 정답 확신을 높인 후 반증을 탐색하는 순서를 따른다.

잘못된 이유 후보가 없으면 바로 GREEN으로 진행한다 — 분석 과부하를 방지한다.

**GREEN 이후**: "이 테스트가 올바른 이유로 통과하고 있는가? 하드코딩이나 trivial implementation으로 통과한 것은 아닌가?"

**GREEN 실패 재시도 시 (2회차부터) — Forced Reflection:**

GREEN 단계에서 테스트 통과에 실패하여 재시도할 때, 2회차부터 아래 3개 질문에 명시적으로 답한 후 코드 수정에 착수한다. 반성 없이 즉시 재시도하면 같은 접근을 반복할 위험이 있다.

1. "이전 시도에서 무엇이 실패했는가?" — 구체적 에러 메시지를 인용한다
2. "이번 시도에서 무엇을 다르게 하는가?" — 변경할 파일과 접근법을 명시한다
3. "같은 접근을 반복하고 있는가?" — YES면 대안 접근법 2개를 도출한 후 가장 다른 것을 선택한다

이 reflection은 simon 기본에만 적용한다. simon-grind에는 이미 Mini-Contract + Hypothesis Reset Protocol이 동일 목적을 더 정교하게 수행한다.

**VERIFY 이후**: "새 테스트가 통과하면서 기존 테스트가 깨진 것은 없는가? 경고(warning)가 새로 발생한 것은 없는가? 테스트 실행 시간이 비정상적으로 늘어난 것은 없는가?"

- Run via tmux: build + test + typecheck simultaneously

### Test Case Summary 생성 (Step 5c-post)

REFACTOR 이후 테스트 구조가 안정된 시점에서, 각 테스트의 분류를 `.claude/memory/unit-{name}/test-case-summary.md`에 기록한다. 이 요약은 Step 18-B(review-sequence)와 simon-code-review의 인라인 코멘트에서 소비되므로, 리뷰어가 테스트 코드를 열지 않고도 커버리지 충분성을 판단할 수 있게 하는 핵심 산출물이다.

```markdown
# Test Case Summary: Unit {name}

## 테스트 파일: {test_file_path}

### Happy Path (정상 동작 검증)
- `{test_function_name}`: {검증 내용 1줄 설명}

### Edge Cases (경계 조건 검증)
- `{test_function_name}`: {검증 내용 1줄 설명}

### Error Cases (에러 처리 검증)
- `{test_function_name}`: {검증 내용 1줄 설명}

### Boundary (경계값 검증)
- `{test_function_name}`: {검증 내용 1줄 설명}
```

**분류 기준**:
- **Happy Path**: AC의 Behavioral Checks에서 정상 흐름에 해당하는 시나리오
- **Edge Case**: 정상 범위이지만 특이한 입력/상태 (빈 리스트, 최대값, 동시 호출 등)
- **Error Case**: 명시적 에러 발생이 기대되는 시나리오 (잘못된 입력, 권한 없음 등)
- **Boundary**: 경계값 (0, -1, MAX_INT, 빈 문자열 등)

빈 카테고리는 생략한다. 테스트가 여러 카테고리에 걸치면 주된 목적 기준으로 하나만 선택한다. executor가 테스트를 방금 작성한 시점이므로 추가 분석 없이 즉시 기록 가능하다.

### Test-Spec Alignment Gate

TDD RED(Step 5a) 직후, GREEN(Step 5b) 전에 fresh `test-alignment-checker` subagent가 테스트와 AC의 정합성을 독립 검증한다. 동일 executor가 테스트 + 구현 모두 작성하면 해석 편향이 양쪽에 동일하게 반영되어 "self-congratulation machine"이 된다 — 구현 코드가 없는 시점에서 테스트의 AC 정합성을 검증하여 이를 방지한다.

- **트리거**: 모든 경로에서 적용
- **전달**: plan-summary.md의 Acceptance Criteria(Mechanical + Behavioral Checks) + 작성된 테스트 코드. 구현 코드 없음 (아직 미작성)
- **프롬프트**: "이 테스트들이 Acceptance Criteria의 모든 시나리오를 정확하게 커버하는지 검증하세요. (1) 누락된 AC 시나리오, (2) AC 해석의 정확성 (예: '5회 실패' = 연속? 누적?), (3) edge case 커버리지를 확인하세요. (4) 각 테스트 함수를 Happy Path / Edge Case / Error Case / Boundary로 분류하고, 아래 포맷으로 정리하세요."
- **결과**:
  - 모든 AC 커버 → Step 5b(GREEN)로 진행
  - 누락/해석 오류 발견 → executor에게 테스트 보완 지시 (max 2회)
- **Save**: `.claude/memory/unit-{name}/test-alignment-check.md`
- **산출물 포맷** — 포맷을 명시하지 않으면 자유형식 텍스트가 산출되어 하류 파이프라인에서 활용이 어렵다:
  ```markdown
  ## Test Coverage Summary
  | 테스트 함수 | 검증 유형 | 대응 AC | 시나리오 설명 |
  |------------|----------|--------|-------------|
  | test_example | happy path | AC-1 | 정상 입력으로 처리 성공 |

  ## 커버리지 판정
  - Happy path: {N}개 / Edge case: {N}개 / Error case: {N}개
  - 누락 시나리오: {있으면 나열, 없으면 "없음"}
  ```

### Agent 출력물 검증 게이트

Agent가 "완료"를 보고하면 즉시 검증한다:
1. `plan-summary.md`의 Files Changed 테이블에서 기대 파일 목록 추출
2. 실제 worktree에서 파일 존재 여부 확인 (`Glob`)
3. 누락 파일 → agent 재실행 (max 2회)
4. 빌드 확인: `go build ./...` (또는 해당 언어 컴파일 명령)

검증이 통과한 후에 다음 Step으로 진행한다.

### Inline Issue Capture (P-010)

Step 5-8 구현 중 발견된 비실패성 이슈(설계 우려, 테스트 어려움, 문서 불일치, 성능 의심)를 즉시 기록한다. Auto-Verification Hook은 빌드/린트 실패만 감지하므로, 이 프로토콜은 그 외 이슈를 포착한다.

- 이슈 발견 시 `.claude/memory/unit-{name}/inline-issues.md`에 즉시 append:
  ```markdown
  ## [ISSUE-{N}] {한줄 요약}
  - **발견 시점**: Step {N}, {파일명}:{라인}
  - **유형**: design-concern / testability / doc-mismatch / performance / other
  - **재현 조건**: {어떤 상황에서 문제가 되는지}
  - **현재 대응**: 즉시 수정 / 기록만 (사유: ...)
  - **후속 필요**: Step 7 Expert Review에서 검토 필요 여부
  ```
- Step 7 Expert Review 시 `inline-issues.md`를 전문가 팀에 자동 전달하여 리뷰 정밀도를 높인다

### Ground Truth 검증 게이트

모든 코드 변경 Step 완료 후 빌드/테스트/타입체크를 실행하고, 결과를 다음 Step의 입력으로 전달한다. 이를 통해 각 단계가 정확한 현재 상태를 기반으로 판단하도록 보장한다.

```
verify-commands.md의 명령 실행 → 결과를 .claude/memory/unit-{name}/ground-truth.md에 기록
```

### "Boil the Lake" 완전성 원칙

AI 토큰 비용은 사실상 0이므로, 항상 완전한 구현을 해야 한다. "나중에 하겠다"는 인간이 시간 제약 때문에 쓰는 전략이지, AI에게는 해당하지 않는다. plan-summary의 AC에 포함된 모든 항목은 이 PR에서 완료한다 — TODO, partial implementation, "follow-up PR에서 처리" 등 모든 형태의 지름길을 금지한다.

아래 패턴은 발견 즉시 자가 교정한다. 완성 불가능한 사유가 있으면 decision-journal에 기록:

- BAD: "이 엣지 케이스는 follow-up PR에서 처리" → AC에 포함된 것이면 지금 처리
- BAD: "80% 커버리지면 충분하므로 error case 테스트 생략" → 최소 happy/edge/error 각 1개
- BAD: "간단한 구현이므로 테스트 불필요" → TDD는 예외 없음
- BAD: "TODO: 성능 최적화" → AC에 성능 기준이 있으면 지금 확인
- BAD: "시간 절약을 위해 validation 생략" → boundary에서의 validation은 필수
- BAD: "이 부분은 다음 iteration에서" → AC 범위 내이면 지금 구현
- OK: "NOT in scope에 명시된 항목은 구현하지 않음" → plan-summary 참조

### Post-Implementation Simplicity Check

Step 5 구현 완료 후, Self-correction 진입 전에 복잡도를 자기 검증한다 — TDD REFACTOR 단계의 구체적 가이드:

- 더 적은 줄로 동일 기능을 구현할 수 있는가?
- 추상화가 복잡도를 정당화하는가? (세 번째 사용 전까지 추상화하지 않는다)
- Staff Engineer가 "왜 이렇게 간단히 안 했어?"라고 할 만한 부분이 있는가?
- 가설적 미래 요구사항이 아닌 현재 요구사항을 구현했는가?

해당 사항 발견 시 즉시 리팩토링한다. 테스트가 통과하는 상태를 유지하면서 단순화한다.

### Step 5 Common Rationalizations

| 합리화 | 현실 |
|--------|------|
| "이건 간단하니까 테스트 먼저 안 써도 돼" | 간단한 코드가 복잡해진다. 테스트는 동작을 문서화한다. TDD는 예외 없음 |
| "빌드를 나중에 한 번에 돌리자" | 미수정 실패가 누적되어 디버깅 비용이 기하급수적으로 증가한다. Stop-and-Fix Gate 위반 |
| "이 파일도 관련이 있으니 같이 고치자" | Plan Immutability 위반이다. unresolved-decisions.md에 기록만 한다 |
| "일단 통과시키고 나중에 리팩토링하자" | 나중은 오지 않는다. REFACTOR 단계에서 지금 정리한다 |

### Self-correction (Step 6 전 자가 검증)

executor가 구현을 완료하면, Step 6으로 넘기기 전에 plan-summary.md의 Acceptance Criteria와 대조한다:
1. **Code Changes** 목록의 각 항목이 구현되었는지 확인
2. **Tests** 목록의 테스트가 작성되었는지 확인하고, 각 검증 유형(happy path / edge case / error case)이 최소 1개 이상 존재하는지 확인한다. happy path만 있고 edge/error case가 없으면 보완한다
3. **Quality Gates** 조건을 충족하는지 확인
4. 누락 항목이 있으면 자체적으로 보완한 후 Step 6으로 진행

- Save: `.claude/memory/unit-{name}/implementation.md`

**Step Output Artifacts** (Step 6 진입 전 필요):
- `memory/unit-{name}/test-case-summary.md` — TDD 테스트 케이스 분류 요약 (Happy Path / Edge Cases / Error Cases / Boundary)
- `memory/unit-{name}/inline-issues.md` — 구현 중 발견된 비실패성 이슈 (Step 7 Expert Review 입력)
- `memory/unit-{name}/implementation.md` — Self-correction 완료 기록 (AC 대조 결과)

### Unit Retrospective Checkpoint

Unit의 마지막 Step 완료 시 (Step 17), **Phase-End Auto-Retrospective** 프로토콜을 실행한다 (SKILL.md Cross-Cutting Protocol 참조). 해당 Unit 구현 중 축적된 사용자 피드백에서 반복 패턴을 탐지하고, 필요 시 boost-capture를 백그라운드로 트리거한다.

## Step 6 이후: Verification

Step 6부터 Step 17까지의 검증 단계는 [phase-b-verification.md](phase-b-verification.md)를 참조한다.
