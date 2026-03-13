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
  - [Test-Spec Alignment Gate (STANDARD+ 경로)](#test-spec-alignment-gate-standard-경로)
  - [Agent 출력물 검증 게이트](#agent-출력물-검증-게이트)
  - [Inline Issue Capture (P-010)](#inline-issue-capture-p-010)
  - [Ground Truth 검증 게이트](#ground-truth-검증-게이트)
  - [Self-correction (Step 6 전 자가 검증)](#self-correction-step-6-전-자가-검증)
- [Step 6 이후: Verification](#step-6-이후-verification)

## Pre-Phase: Base Branch Sync & Worktree 생성

1. default branch 감지 (`auto`이면 main/master 자동 감지)
2. `git fetch {remote} {base_branch}` 실행 (원격 최신 동기화)
3. `.claude/memory/branch-name.md`에서 사용자가 입력한 브랜치명 읽기
4. worktree 생성: `git worktree add .claude/worktrees/{branch-name} -b {branch-name} origin/{base_branch}`
5. 해당 worktree로 작업 디렉토리 이동
6. base commit SHA를 `.claude/memory/base-commit.md`에 기록

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

## Critical Rules

- All verification/review: ONLY changed files (git diff based). 변경하지 않은 파일을 리뷰하면 노이즈가 증가하고 핵심 변경점을 놓칠 수 있다.
- Use `.claude/workflow/scripts/*.sh` for deterministic tasks (save context)
- Record findings in `.claude/memory/unit-{name}/*.md` after each step
- **병렬 Unit 파일 격리**: 병렬 Unit 실행 시 공유 파일(decision-journal.md, failure-log.md 등)에 동시 쓰기를 방지한다. 각 Unit은 자신의 `unit-{name}/` 디렉토리에만 기록하고, Integration Stage에서 오케스트레이터가 병합한다. session-scoped 파일(retrospective.md, project-memory.json)은 오케스트레이터만 기록한다.
- Read memory files at start of each step
- Tests: NEVER use real DB or external APIs. 테스트가 실제 시스템에 부작용을 일으키면 프로덕션 데이터가 손상되거나 외부 서비스에 의도치 않은 요청이 발생한다. mock/stub만 사용하라.
- Commands: NEVER access real external systems. CONTEXT-SENSITIVE 규칙에 해당하는 경우 SKILL.md의 판단 절차를 따른다.
- **환각 방지**: 읽지 않은 코드에 대해 추측하지 않는다. 파일은 반드시 Read로 열어본 후에 의견을 제시한다. 추측 기반 수정은 새로운 버그를 만들 수 있다.
- **Anti-hardcoding**: 테스트를 통과시키기 위해 특정 입력값을 하드코딩하지 않는다. 일반적 해결책을 구현한다. 하드코딩은 테스트만 통과시키고 실제 문제를 숨긴다.
- **Auto-Verification Hook**: 소스코드 파일 수정(Edit/Write) 후 `verify-commands.md`의 빌드/린트 명령을 즉시 실행한다. 실패 시 **Stop-and-Fix Gate 적용** — 수정 완료 전까지 다음 작업 진행 금지. `.md`, `.json` 등 비소스코드는 제외. (SKILL.md Cross-Cutting Protocol 참조)
- **Step Transition Gate**: Step N에서 Step N+1로 진입하기 전에 `verify-commands.md`의 빌드/린트/테스트를 실행하여 전부 통과해야 한다. 이전 Step의 미수정 실패를 다음 Step으로 넘기면 디버깅이 기하급수적으로 어려워진다. 실패 시 Stop-and-Fix Gate가 자동 발동된다. (SMALL 경로에서도 적용)
- **Plan Immutability**: Phase A에서 확정된 `plan-summary.md`는 Phase B 이후 암묵적으로 변경할 수 없다. 변경이 필요한 경우 다음 절차를 따른다: (1) 변경 사유를 `.claude/memory/plan-amendments.md`에 기록, (2) 영향받는 Unit/Step 식별, (3) 사용자에게 변경 승인 요청 (AskUserQuestion), (4) 승인 후 plan-summary.md와 관련 memory 파일 일괄 갱신. 이 절차 없이 계획을 조용히 변경하면 Acceptance Criteria와 실제 구현이 괴리되어 Step 17에서 대규모 재작업이 발생한다.
- **Step Progress Pulse (P-007)**: 각 Step 완료 시 사용자에게 1줄 상태를 출력한다 (AskUserQuestion이 아닌 단순 텍스트 출력이므로 사용자를 중단시키지 않는다). 형식: `[Step {N}/{total}] {Step명} 완료 — {핵심 결과 요약}`. 예: `[Step 7/17] Expert Review 완료 — CRITICAL 0, HIGH 2, MEDIUM 5`. Phase B-E 시작 시 예상 Step 수를 안내한다: `{경로} 경로: Steps 5-{N} ({M} steps)`.

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
- Spawn `executor`, parallel for independent files (maxTurns: SKILL.md Subagent 사용 기준 테이블 참조 — SMALL 50, STANDARD 100, LARGE 200)
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
- **Step 5d: VERIFY** — 전체 테스트 스위트를 실행한다. 모든 테스트가 통과한 후에 다음 단계로 진행한다
- **Step 5e: Working Example Spot-check** — Unit 구현 완료 후, plan-summary.md의 Behavior Changes에서 핵심 시나리오 1개를 선택하여 실제 동작을 확인한다 (테스트 통과 ≠ 실제 동작). CLI 실행, curl dry-run, 또는 사용 예제 코드 실행으로 검증. 실패 시 Step 5b로 회귀.

- Run via tmux: build + test + typecheck simultaneously

### Test-Spec Alignment Gate (STANDARD+ 경로)

TDD RED(Step 5a) 직후, GREEN(Step 5b) 전에 fresh `test-alignment-checker` subagent가 테스트와 AC의 정합성을 독립 검증한다. 동일 executor가 테스트 + 구현 모두 작성하면 해석 편향이 양쪽에 동일하게 반영되어 "self-congratulation machine"이 된다 — 구현 코드가 없는 시점에서 테스트의 AC 정합성을 검증하여 이를 방지한다.

- **트리거**: STANDARD+ 경로에서만 적용. SMALL 경로는 skip
- **전달**: plan-summary.md의 Acceptance Criteria(Mechanical + Behavioral Checks) + 작성된 테스트 코드. 구현 코드 없음 (아직 미작성)
- **프롬프트**: "이 테스트들이 Acceptance Criteria의 모든 시나리오를 정확하게 커버하는지 검증하세요. (1) 누락된 AC 시나리오, (2) AC 해석의 정확성 (예: '5회 실패' = 연속? 누적?), (3) edge case 커버리지를 확인하세요."
- **결과**:
  - 모든 AC 커버 → Step 5b(GREEN)로 진행
  - 누락/해석 오류 발견 → executor에게 테스트 보완 지시 (max 2회)
- **Save**: `.claude/memory/unit-{name}/test-alignment-check.md`

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

### Self-correction (Step 6 전 자가 검증)

executor가 구현을 완료하면, Step 6으로 넘기기 전에 plan-summary.md의 Acceptance Criteria와 대조한다:
1. **Code Changes** 목록의 각 항목이 구현되었는지 확인
2. **Tests** 목록의 테스트가 작성되었는지 확인
3. **Quality Gates** 조건을 충족하는지 확인
4. 누락 항목이 있으면 자체적으로 보완한 후 Step 6으로 진행

- Save: `.claude/memory/unit-{name}/implementation.md`

### Unit Retrospective Checkpoint

Unit의 마지막 Step 완료 시 (SMALL: Step 8, STANDARD+: Step 17), **Phase-End Auto-Retrospective** 프로토콜을 실행한다 (SKILL.md Cross-Cutting Protocol 참조). 해당 Unit 구현 중 축적된 사용자 피드백에서 반복 패턴을 탐지하고, 필요 시 boost-capture를 백그라운드로 트리거한다.

## Step 6 이후: Verification

Step 6부터 Step 17까지의 검증 단계는 [phase-b-verification.md](phase-b-verification.md)를 참조한다.
