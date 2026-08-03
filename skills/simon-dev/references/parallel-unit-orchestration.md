# Parallel Unit Orchestration (Detailed Instructions)

Phase A의 Execution Groups 표에서 병렬 Unit이 2개 이상 확정된 경우에만 이 파일을 로딩한다. Unit이 1개뿐이거나 전부 sequential이면 이 파일은 필요 없다 — Pre-Phase/Step 5는 기존 단일 Unit 절차(phase-b-implementation.md)를 그대로 따른다.

**설계 원칙**: 이 프로토콜은 Unit마다 **실제 git worktree**를 만든다(문서만 존재하던 기존 "isolated worktree" 선언을 실행 가능하게 만드는 것이 이 파일의 목적). 각 Unit이 물리적으로 분리된 워크트리에서 실행되면, 공유 워크스페이스 모델에서 발생하는 문제들(다른 Unit의 미완성 코드가 빌드에 섞임, 공유 로그 파일 lost-update, `git stash`가 다른 Unit 변경까지 날림)이 **파일시스템 격리로 구조적으로 사라진다**. 남는 문제는 두 가지뿐이다 — (1) 흩어진 워크트리를 다시 하나로 합치는 절차, (2) Unit별로 다른 진행 상태를 추적하는 스키마. 이 파일은 이 두 가지를 다룬다.

## 목차
- [적용 조건](#적용-조건)
- [Pre-Phase: Unit Worktree Fan-out](#pre-phase-unit-worktree-fan-out)
- [Unit Runbook 배치 생성](#unit-runbook-배치-생성)
- [Step 5: Parallel Classification Gate + 동시 발신](#step-5-parallel-classification-gate--동시-발신)
- [Spawn Prompt의 parallel_context 블록](#spawn-prompt의-parallel_context-블록)
- [상태 스키마: units 맵](#상태-스키마-units-맵)
- [진행 보고: Unit 식별자 + CONTEXT.md 2계층](#진행-보고-unit-식별자--contextmd-2계층)
- [에스컬레이션 큐잉 (BLOCKED 상태)](#에스컬레이션-큐잉-blocked-상태)
- [Fan-in 배리어와 Group 순회](#fan-in-배리어와-group-순회)
- [Stop-and-Fix의 Cross-Unit 예외 처리](#stop-and-fix의-cross-unit-예외-처리)
- [Blame Protocol의 병렬-안전 변형](#blame-protocol의-병렬-안전-변형)
- [Integration Stage: Unit 병합 절차](#integration-stage-unit-병합-절차)
- [fan-out 상한: Step 5-6까지만 병렬](#fan-out-상한-step-5-6까지만-병렬)

## 적용 조건

Phase A의 Execution Groups 표(phase-a-planning.md)에서 같은 Group에 Unit이 2개 이상이면 이 파일의 절차가 발동한다. 최대 동시 병렬 수는 3으로 제한한다(simon-pm `feature-execution.md`의 검증된 상한과 동일 — 리소스/디스크/컨텍스트 비용 때문). Group의 Unit이 4개 이상이면 3개씩 나누어 순차 배치로 처리한다.

## Pre-Phase: Unit Worktree Fan-out

phase-b-implementation.md의 기존 Pre-Phase 1-7단계(브랜치 생성, base stability 검증)는 변경 없이 그대로 실행한다 — 이 단계는 **feature worktree** 하나를 만드는 절차이며, 이후 이 worktree가 모든 Unit worktree의 부모가 된다.

feature worktree의 base stability 검증(GATE — Base Stability)을 통과한 직후, Unit 수가 2개 이상이면 아래 3-B 단계를 추가로 실행한다.

**3-B. Unit Worktree 생성** (Parallel Group 단위, 최대 3개씩):

```bash
# feature worktree 안에서 실행 (fetch 불필요 — 이미 검증된 로컬 브랜치를 base로 사용)
FEATURE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
FEATURE_WORKTREE=$(git rev-parse --show-toplevel)

for UNIT in unit-a unit-b unit-c; do   # 현재 Parallel Group의 Unit들 (최대 3개)
  bash ~/.claude/skills/simon-dev/scripts/create-unit-worktree.sh \
    "${UNIT}" "${FEATURE_BRANCH}" "${FEATURE_WORKTREE}"
done
```

`create-unit-worktree.sh`는 `create-branch.sh`와 달리 `git fetch`를 하지 않는다 — Unit 브랜치의 base는 origin이 아니라 **이미 base stability 검증을 통과한 로컬 feature 브랜치**이기 때문이다(fetch 재실행은 불필요한 네트워크 호출이자, feature 브랜치와 다른 시점의 origin 상태를 끌어올 위험이 있다). 스크립트는 Unit 워크트리를 feature 워크트리의 **형제 디렉토리**(`{feature-worktree}--unit-{name}`)로 생성하고, `.claude/memory/`의 읽기 전용 계획 산출물(`plan-summary.md`, `code-design-analysis.md`, `verify-commands.md`, `expert-plan-concerns.md`)을 복사한다 — Unit 워크트리는 feature 워크트리의 `.claude/memory`를 공유하지 않으므로(워크트리는 `.git`만 공유하고 작업 디렉토리는 독립적이다) 계획 컨텍스트를 명시적으로 전달해야 한다.

**후속 Parallel Group**(의존성 있는 Group)은 선행 Group이 Integration 병합을 마친 뒤 갱신된 feature 브랜치를 base로 동일 절차를 반복한다 — 후속 Unit이 선행 Unit의 산출물을 참조할 수 있게 하기 위함이다.

Unit worktree 경로는 `unit-{name}` → worktree path 매핑으로 `workflow-state.json`의 `units` 맵에 기록한다(아래 [상태 스키마](#상태-스키마-units-맵) 참조).

## Unit Runbook 배치 생성

`phase-b-implementation.md`의 "Unit Runbook 자동 생성" 절차는 **Unit 1개를 대상으로 한 서술**이라 그대로 따르면 "runbook 생성 → 즉시 spawn"을 Unit마다 반복하게 되고, 이러면 spawn 자체가 턴을 넘나들며 순차 발신되어 동시 실행이 성립하지 않는다.

Unit이 2개 이상이면: **Step 5 spawn 전에 같은 Parallel Group의 모든 Unit runbook을 일괄 생성**한다. 각 runbook은 해당 Unit의 워크트리 경로(`.claude/memory/unit-{name}/runbook.md`가 아니라, 이제 각 Unit이 자기 워크트리를 가지므로 그 워크트리 안의 `.claude/memory/runbook.md`)에 저장한다. Runbook 내용 자체(목표/변경 파일/Done-When/주의사항/Decision Authority/코드 생성 제약)는 phase-b-implementation.md의 기존 템플릿을 그대로 사용한다.

## Step 5: Parallel Classification Gate + 동시 발신

**[Gate — Parallel Classification, 필수, Step 5 진입 직전]**

Unit이 2개 이상이면 spawn 직전 1줄로 인용한다 — 인용 없이 순차 진행하는 것은 기본값으로 허용하지 않는다:

```
[Parallel] unit-a + unit-b — Group 1, 워크트리 분리 완료 → 동시 spawn
[Sequential] unit-c — Group 2, unit-a 산출물에 의존 → Group 1 병합 후 실행
```

이 인용은 `SKILL.md:161`의 "Spawn 여부" 게이트와 다른 축이다 — `SKILL.md:161`은 "subagent를 쓸지"를 판정하고, 이 게이트는 "이미 쓰기로 한 subagent들을 동시에 부를지"를 판정한다.

**[Rule — 동시 발신]** `[Parallel]`로 판정된 Group의 executor는 **하나의 응답 안에서 여러 `Agent(run_in_background=true)` tool call을 동시에 포함**하여 spawn한다. 이 하네스에서 실제 동시 실행을 만드는 유일한 메커니즘은 "같은 메시지에 여러 tool_use 블록"이다 — `run_in_background=true`는 이미 기본 동작이며 그 자체로는 동시성을 만들지 않는다. 앞 Unit의 결과를 기다린 뒤 다음 Unit을 spawn하면 `[Parallel]` 판정과 모순된다.

각 executor의 `Scope`(agent-capability-matrix.md Spawn Prompt Template의 `<context>` 블록)는 그 Unit 자신의 워크트리 경로로 제한한다 — 물리적으로 다른 디렉토리이므로 다른 Unit의 파일에 접근할 경로 자체가 없다.

## Spawn Prompt의 parallel_context 블록

Unit이 2개 이상을 같은 턴에 병렬 spawn할 때만, `agent-capability-matrix.md`의 `<context>`와 `<constraints>` 사이에 다음 블록을 추가한다(단일 Unit이면 생략):

```
<parallel_context>
- 동시 실행 중인 다른 Unit: {sibling_unit_names} — 각자 독립된 워크트리(${WORKTREE_PATH})에서 작업하므로 파일 충돌은 구조적으로 없다.
- 공유 인터페이스 Contract (해당 시): {오케스트레이터가 spawn 전 확정한 필드명·타입·포맷}
  예: "POST /orders 응답 필드는 order_id:string, status:enum(pending|paid|failed)"
- 통합 시점: Integration Stage에서 오케스트레이터가 이 Unit의 브랜치를 feature 브랜치에 병합한다. 이 Unit은 다른 Unit의 산출물을 지금 직접 참조/import하지 않는다.
- 에스컬레이션 발생 시: AskUserQuestion을 직접 호출하지 않는다. 아래 [에스컬레이션 큐잉](#에스컬레이션-큐잉-blocked-상태) 절차를 따른다.
</parallel_context>
```

`_shared/preamble.md`의 "병렬 에이전트 간 API Contract 불일치" 경고가 요구만 하고 템플릿이 없던 자리를 이 블록이 채운다.

## 상태 스키마: units 맵

`workflow-state.json`(feature 워크트리에 1개만 존재 — Unit 워크트리는 자체 workflow-state.json을 갖지 않는다, 오케스트레이터가 각 Unit executor의 반환값을 받아 이 파일에 기록하는 **단일 writer** 구조이므로 동시 쓰기 레이스가 없다)에 Unit이 2개 이상일 때만 `units` 맵을 추가한다:

```json
{
  "current_phase": "B",
  "current_step": "B/5",
  "units": {
    "unit-a": {
      "worktree": "/path/to/{feature-worktree}--unit-a",
      "branch": "{feature-branch}/unit-a",
      "current_step": "B/7",
      "status": "in_progress",
      "parallel_group": "G1"
    },
    "unit-b": {
      "worktree": "/path/to/{feature-worktree}--unit-b",
      "branch": "{feature-branch}/unit-b",
      "current_step": "B/17",
      "status": "completed",
      "parallel_group": "G1"
    }
  }
}
```

`status`는 `not_started | in_progress | blocked | completed | failed` 중 하나. 오케스트레이터는 각 Unit executor의 `DONE:`/`PARTIAL:`/`ERROR:`/`BLOCKED:` 반환(agent-capability-matrix.md Status Prefix + 아래 [에스컬레이션 큐잉](#에스컬레이션-큐잉-blocked-상태)의 BLOCKED 추가분)을 받을 때마다 해당 Unit의 `current_step`/`status`를 갱신한다.

**G-INT(Integration Gate) 판정**: `units` 맵이 존재하면 "모든 Unit의 Step 17 완료"는 `jq '.units | to_entries | all(.value.status == "completed")'`로 결정론적으로 판정한다 — LLM 기억에 의존하지 않는다(`gate-definitions.md`의 Deterministic Gate Principle과 일치).

## 진행 보고: Unit 식별자 + CONTEXT.md 2계층

Step Progress Pulse(`phase-b-implementation.md:229`)에 Unit 식별자를 접두사로 붙인다:

```
[unit-a 7/17] Expert Review 완료 — CRITICAL 0, HIGH 1
[unit-b 17/17] DONE
```

상태 전이(시작/완료/BLOCKED)가 있을 때만 집계 라인을 추가한다(매 pulse마다 출력하면 verbose화되므로 금지):

```
[Parallel Summary] unit-a 7/17 · unit-b DONE · unit-c 대기(Group 2)
```

feature 워크트리의 `CONTEXT.md`(단일 파일, 오케스트레이터만 갱신)의 "현재 진행 상태" 섹션을 Unit별 표로 확장한다:

```markdown
## 현재 상태 (Unit별)
| Unit | 워크트리 | 진행 중 Step | 상태 | 마지막 검증 |
|------|----------|------------|------|------------|
| unit-a | {feature-wt}--unit-a | Step 7 — Expert Review | in_progress | build/test 통과 |
| unit-b | {feature-wt}--unit-b | Step 17 | completed | build/test 통과 |
```

각 Unit 워크트리 안의 `.claude/memory/runbook.md`가 그 Unit 하나의 상세를 담당하고, feature 워크트리의 `CONTEXT.md`가 전체 그림을 담당하는 2계층 구조다 — 새 파일(`UNITS.md` 등)을 추가로 만들지 않고 기존 `CONTEXT.md`를 확장하는 것으로 충분하다.

## 에스컬레이션 큐잉 (BLOCKED 상태)

병렬 Unit executor는 `phase-b-implementation.md`의 "에스컬레이션 필수" 트리거(다른 Unit의 파일 수정 — Option B에서는 물리적으로 불가능하므로 해당 없음, 새 패키지/모듈 추가, AC와 충돌하는 구현 방향, Done-When 달성 불가)를 만나면 **AskUserQuestion을 직접 호출하지 않는다**. 대신:

1. 자기 워크트리의 `.claude/memory/escalation.md`에 질문을 기록
2. `BLOCKED: escalation.md 참조 — {한줄 요약}` 형식으로 즉시 반환하며 종료 (agent-capability-matrix.md Status Prefix에 `BLOCKED` 추가)
3. 오케스트레이터가 이 반환을 받으면 `units.{name}.status`를 `blocked`로 갱신

오케스트레이터는 한 턴에 여러 Unit이 BLOCKED로 돌아올 수 있음을 전제로, 큐를 만들어 순차 처리한다:

```
[Escalation Queue] 2건 대기 — unit-b(재시도 정책 미명시), unit-c(외부 API 타임아웃 기준)
```

AskUserQuestion 질문 텍스트에는 항상 `[unit-{name}]` 접두사를 강제하여 사용자가 맥락을 잃지 않게 한다. 사용자 응답을 받으면 해당 Unit을 **동일 워크트리에서** runbook에 답변을 반영해 재spawn한다 — 워크트리를 새로 만들지 않는다. BLOCKED 상태의 Unit이 있어도 같은 Group의 다른(BLOCKED 아닌) Unit은 계속 진행한다 — 이는 Autonomous Progression Invariant(tool-call-first)의 위반이 아니라 설계된 예외다. 오케스트레이터가 AskUserQuestion으로 턴을 닫아도, 이미 spawn된 다른 Unit의 background 실행은 계속된다.

## Fan-in 배리어와 Group 순회

같은 Parallel Group의 모든 Unit이 `completed` 또는 `failed`로 귀결될 때까지 다음 Group으로 진입하지 않는다. `failed` Unit은 원인 분석 후 재spawn(max 2회) — 같은 Group 내 `completed` Unit은 재실행하지 않는다.

Group 전원이 `completed`이면: Integration 절차([Integration Stage: Unit 병합 절차](#integration-stage-unit-병합-절차) 참조)로 해당 Group을 feature 브랜치에 병합한 뒤, 다음 Group의 Unit worktree를 생성한다.

## Stop-and-Fix의 Cross-Unit 예외 처리

Option B(워크트리 분리)에서는 한 Unit의 빌드/테스트가 다른 Unit의 미완성 코드에 영향받지 않는다 — 각 워크트리가 물리적으로 분리된 작업 디렉토리이기 때문이다. 따라서 `error-resilience.md`의 CODE_LOGIC 재시도 사다리는 **정상적으로 자기 Unit의 실패 원인에만 수렴**하며, 별도의 cross-unit 재분류 로직이 필요 없다.

단, 재시도 사다리 소진(6회) 후 `simon-grind로 전환`을 선택하는 경우, grind는 **해당 Unit의 워크트리 안에서만** Attempt 1부터 시작한다 — 다른 Unit의 진행에는 영향을 주지 않는다. `.claude/memory/failure-log.md`/`checkpoints.md` 초기화도 그 Unit의 워크트리 범위로 한정한다.

## Blame Protocol의 병렬-안전 변형

`phase-b-verification.md`의 Blame Protocol은 `git stash` → base checkout → 재테스트 순서를 쓴다. **주의**: `git stash`의 `refs/stash`는 같은 저장소를 공유하는 모든 워크트리에 걸쳐 공유되는 참조다 — 두 Unit이 같은 순간 각자의 워크트리에서 `git stash`를 실행하면 이 공유 참조에서 충돌할 수 있다.

병렬 Unit의 Blame Protocol은 `git stash` 대신 **자기 브랜치로의 임시 WIP 커밋**을 사용한다:

```bash
git add -A && git commit -m "wip: blame protocol temp" --no-verify
git checkout "${FEATURE_BRANCH}"   # base 대신 병합 시점의 feature 브랜치 기준
# 동일 테스트 실행
git checkout -   # 원래 Unit 브랜치로 복귀
git reset --soft HEAD~1   # WIP 커밋 되돌리기 (변경사항은 유지)
```

커밋은 해당 Unit의 브랜치에만 존재하므로 다른 Unit과 충돌할 여지가 없다.

## Integration Stage: Unit 병합 절차

`integration-and-review.md`의 Integration Stage 1번 항목("모든 변경사항은 Startup에서 생성한 worktree의 브랜치에 커밋")은 Unit이 1개일 때만 유효하다. Unit이 2개 이상이면, Group의 모든 Unit이 `completed`가 된 직후 feature 워크트리에서 병합 스크립트를 실행한다:

```bash
cd "${FEATURE_WORKTREE}"
bash ~/.claude/skills/simon-dev/scripts/merge-units.sh unit-a unit-b
```

`merge-units.sh`가 수행하는 작업 (Unit마다 순차):
1. `git merge --no-ff {feature-branch}/unit-{name}` — Unit 브랜치를 feature 브랜치로 병합. 충돌 시 exit 2로 중단 → 기존 절차와 동일하게 `architect` 분석 + `executor` 해결(`integration-and-review.md:21`)
2. `.claude/memory/unit-{name}/`(review-findings.md, inline-issues.md, test-case-summary.md 등 이미 Unit-네임스페이스된 산출물)를 Unit 워크트리에서 feature 워크트리로 통째로 복사
3. `decision-journal.md`/`unresolved-decisions.md`/`plan-amendments.md`(각 Unit 워크트리 안에서는 이미 최상위 경로였지만, 그 워크트리 자체가 그 Unit 전용이라 사실상 격리되어 있었다)를 feature 워크트리의 동일 파일에 `## [unit-{name}]` 헤더로 구분하여 append — Step 18-A writer subagent가 이 병합된 파일에서 Deviations Log를 추출한다
4. 병합 완료된 Unit 워크트리를 `git worktree remove`로 정리

병합 후 G-INT의 나머지 조건(전체 빌드, 전체 테스트, Working Example)을 feature 워크트리에서 검증한다.

## fan-out 상한: Step 5-6까지만 병렬

병렬 spawn은 Step 5(Implementation)와 Step 6(Purpose Alignment)까지만 적용한다 — 이 두 Step은 순수 Sub-agent/Fresh 패턴(agent-teams.md)이라 fan-out에 구조적 장애물이 없다. Step 7(Bug/Security/Performance Review)부터는 Hybrid 패턴(blind sub-agent → Agent Team 토론)이고, Agent Teams는 세션당 팀 1개만 운영 가능하다(`agent-teams.md`) — Unit마다 동시에 별도 Team을 띄울 수 없으므로, Step 7부터는 Group 내 Unit들을 **순차로** 처리한다(각 Unit은 여전히 자기 워크트리에서 독립적으로 Step 7-17을 진행하되, Agent Team 토론 자체는 한 번에 한 Unit씩).
