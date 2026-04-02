---
name: simon-bot-boost-capture
description: "작업 중 스킬 개선점 백그라운드 캡처 — 현재 세션 컨텍스트를 자동 분석하여 개선 인사이트 리포트를 남기고, 작업 흐름을 즉시 이어갑니다. Use when: (1) 작업 중 스킬의 비효율·문제점을 발견했을 때 ('이거 개선점인데', '이 부분 아쉽다', '캡처해줘'), (2) simon-bot/grind/pm 실행 중 특정 단계에서 문제가 반복될 때, (3) 스킬 개선 아이디어가 떠올랐지만 지금 적용하기 어려울 때, (4) '나중에 고쳐야지', '이건 boost 감이다' 같은 메모성 언급. 작업을 멈추지 않고 개선점을 기록하는 모든 상황에서 이 스킬을 사용하세요."
compatibility:
  tools: [Agent]
model: sonnet
---

# simon-bot-boost-capture

작업 중 발견한 스킬 개선점을 백그라운드로 분석·기록하는 경량 스킬.

세션 컨텍스트 오염을 최소화하기 위해 포그라운드 작업은 스냅샷 확인까지만 수행하고, 상세 분석은 백그라운드 Agent에 위임한다. 축적된 인사이트는 `simon-bot-boost`의 Review 모드에서 일괄 처리한다.

## Step 1: Context Snapshot

현재 세션의 대화 흐름에서 개선 관련 컨텍스트를 자동 추출한다.

**추출 대상:**
- 실행 중인 스킬과 현재 단계 (Step)
- 문제·비효율이 발생한 지점
- 에러 메시지 (있다면)
- 사용자가 수동 보정하거나 지적한 부분

**스냅샷 제시:**

```
캡처 스냅샷:
- 대상 스킬: {skill_name}
- 대상 섹션: {step/section}
- 관찰: {1-2줄 요약}
- 개선 방향: {1줄 제안}

이 내용으로 캡처할까요? (수정할 부분이 있으면 말씀해주세요)
```

- 확인 → Step 2
- 수정 요청 → 사용자 입력으로 대체 → Step 2

## Step 2: Background Dispatch

확정된 스냅샷으로 백그라운드 Agent를 spawn하고, 현재 작업으로 즉시 복귀한다.

**Agent spawn:**

```
Agent(
    description="boost insight 리포트 작성",
    run_in_background=true,
    prompt=아래 템플릿
)
```

**Agent Prompt 템플릿:**

```
## 임무
스킬 개선 인사이트를 분석하고 리포트를 작성하라.

## 관찰 내용
{확정된 스냅샷 전체}

## 작업
1. 대상 스킬 파일 Read:
   - ~/.claude/skills/{target_skill}/SKILL.md
   - 스냅샷에서 언급된 섹션의 reference 파일 (있다면)

2. 관찰과 현재 스킬 코드를 대조 분석:
   - 문제의 근본 원인이 스킬의 어느 부분에 있는지
   - 구체적으로 어떤 코드/지시문을 어떻게 바꿔야 하는지
   - 변경이 다른 스킬에 전파되는지

3. ~/.claude/boost/insights/ 디렉토리에 리포트 저장 (없으면 mkdir -p로 생성)

## 리포트 형식
파일명: {YYYY-MM-DD}-{HHmm}-{slug}.md

내용:
---
status: pending
severity: HIGH | MEDIUM | LOW
target_skill: {skill_name}
target_section: {step/section}
captured_at: {ISO datetime}
---

# {제목}

## 관찰
(세션에서 구체적으로 무슨 일이 있었는지)

## 현재 스킬 코드 분석
(해당 부분의 현재 코드, 왜 문제인지)
(파일 경로와 해당 섹션 명시)

## 개선 제안
(무엇을 어떻게 바꾸면 좋을지 — before/after 포함)

## 기대 효과
(변경 시 어떤 개선이 예상되는지)

## 영향 범위
(이 변경이 다른 스킬이나 워크플로에 미치는 영향)
```

**사용자 안내 후 즉시 복귀:**

> 백그라운드에서 분석 중입니다. 완료 시 `~/.claude/boost/insights/`에 저장됩니다.

이 메시지 이후 캡처 관련 추가 출력을 하지 않는다. 사용자의 원래 작업으로 복귀한다.

### Auto-Capture Mode

사용자 개입 없이 워크플로 비효율을 자동 감지하여 캡처한다. 세션당 최대 3건.

**자동 감지 패턴**:
- 같은 Step에서 3회 이상 재시도 (동일 에러 반복)
- 예상 소요 시간의 2배 이상 경과
- 동일 파일을 3회 이상 반복 읽기 (필요한 정보를 찾지 못하는 징후)
- subagent가 동일 실패를 2회 이상 보고

**캡처 조건**: 위 패턴 중 하나라도 감지되면, 현재 작업을 중단하지 않고 백그라운드로 인사이트 리포트를 `.claude/boost/auto-captures/`에 기록한다.

**Calibration bar**: gstack의 예시 — `$B js "await fetch(...)"` 실패는 스킬이 처리해야 할 수준. 사용자의 앱 버그, 네트워크 에러, 사용자 코드 버그는 캡처 대상이 아니다.

## Rules

- **포그라운드 최소화**: 스냅샷 제시 + 확인이 전부. 스킬 파일 읽기, 상세 분석은 모두 백그라운드.
- **즉시 복귀**: Agent spawn 후 현재 작업을 이어간다. 완료를 기다리지 않는다.
- **저장 위치**: `~/.claude/boost/insights/`
- **상태 관리**: 리포트 `status`는 `pending`으로 시작. `simon-bot-boost` Review 모드에서 `applied` / `rejected` / `deferred`로 변경.
- **컨텍스트 보호**: 이 스킬의 존재 이유는 컨텍스트 오염 방지. 불필요한 출력을 절대 하지 않는다.
- **실패 복구**: 백그라운드 Agent가 완료 알림에서 실패를 보고하면, 스냅샷 내용을 `~/.claude/boost/insights/` 디렉토리에 최소 형태(frontmatter + 관찰 섹션만)로 직접 저장한다. 상세 분석 없이라도 관찰 기록은 보존되어야 한다 — 다음 boost-review 세션에서 보완 분석이 가능하다.
- **중복 방지**: 스냅샷 제시 전에 `~/.claude/boost/insights/`의 최근 파일 5개의 제목을 확인한다. 동일 스킬의 동일 섹션에 대한 유사 관찰이 `pending` 상태로 이미 존재하면 사용자에게 "유사 인사이트가 이미 있습니다: {파일명}. 추가 캡처할까요?"라고 확인한다.
