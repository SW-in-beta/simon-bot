# Agent Teams Protocol (Cross-Cutting — Agent Team 사용 단계)

**이 워크플로는 Claude Code Agent Teams 기능을 사용합니다.** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필요)

Agent Teams는 subagent와 달리, 팀원들이 **서로 직접 메시지**를 주고받고, **공유 작업 목록**으로 자체 조율하며, 각자 **독립된 컨텍스트 윈도우**에서 동작합니다.

## 제약사항

- 세션당 한 번에 **하나의 팀**만 운영 가능
- 새 팀을 만들기 전에 반드시 기존 팀을 해산(`TeamDelete`)해야 함
- 팀원은 자신의 하위 팀을 만들 수 없음 (리더만 가능)

## 팀 생명주기

1. **생성**: `TeamCreate(team_name="...", description="...")` — 팀 + 공유 작업 목록 생성
2. **작업 정의**: `TaskCreate(subject="...", description="...", activeForm="...")` — 작업 생성 (의존관계: `addBlockedBy`)
3. **팀원 spawn**: `Agent(subagent_type="general-purpose", team_name="...", name="...")` — 병렬 spawn 가능
4. **작업 수행**: 팀원들이 `TaskList` → `TaskUpdate(owner=자신)` → 작업 수행 → `TaskUpdate(status="completed")` → 다음 작업
5. **직접 토론**: `SendMessage(type="message", recipient="팀원명", content="...", summary="...")`
6. **해산**: 모든 팀원에게 `SendMessage(type="shutdown_request")` → 팀원 승인 → `TeamDelete()`

## 팀원 prompt 작성 규칙

- 역할/전문 분야를 명확히 기술
- 수행할 작업의 컨텍스트 파일 경로를 명시
- "TaskList로 작업을 확인하고 claim하세요. SendMessage로 다른 팀원과 토론하세요."를 포함
- 최종 결과물 경로와 형식을 지정
- Agent Team 멤버 spawn 시 `maxTurns: 20`을 기본 적용 (SKILL.md Subagent 사용 기준 테이블 참조)

## 팀원 subagent_type 선택

- 코드 탐색/분석 위주: `general-purpose` (모든 도구 접근 가능)
- 팀원은 자체 컨텍스트 윈도우를 가지므로, 오케스트레이터 컨텍스트와 독립
- 역할별 도구 범위/maxTurns: [agent-capability-matrix.md](agent-capability-matrix.md) 참조

## Sequential Team Orchestration (Team Handoff Protocol)

"세션당 한 팀만" 제약으로 인해 워크플로에서 여러 팀이 순차적으로 생성-해산-재생성된다. 팀 전환 시 정보 손실을 방지하기 위한 프로토콜.

### Team Sequence Map

```
Code Design Team → Plan Review Team → Expert Review Team → (Phase B) → Impl Review Team
```

각 화살표에서 Team Handoff가 발생한다.

### Team Handoff Document

팀 해산(`TeamDelete`) 직전에 반드시 handoff 문서를 생성한다:

**파일**: `.claude/memory/{team-name}-handoff.md`

**형식**:
```markdown
## Team Handoff: {team-name}

### 핵심 결론 (3줄 이내)
- (이 팀이 도출한 가장 중요한 결론)

### 미해결 사항
- (합의에 도달하지 못한 항목)

### 다음 팀에 전달할 컨텍스트
- (다음 팀이 반드시 알아야 할 맥락)

### 산출물 참조
- (이 팀이 생성/수정한 파일 목록)
```

### 새 팀 생성 시 규칙

1. 이전 팀의 handoff 문서를 팀원 spawn 시 프롬프트에 포함
2. TaskCreate의 첫 번째 Task에 "이전 팀 handoff 검토"를 추가
3. handoff에 미해결 사항이 있으면 새 팀의 초기 토론 주제로 설정

## Heartbeat Protocol (Team 진행 상황 보고)

Agent Team 운영 중 오케스트레이터는 사용자에게 진행 상황을 주기적으로 보고한다. Agent Team 토론은 수 분이 소요되므로, 사용자가 "지금 뭘 하고 있는지" 파악할 수 있어야 한다.

**Heartbeat 주기:**
- 팀 생성 후 60초 뒤 첫 보고
- 이후 2분 간격으로 보고
- 팀 해산 시 최종 요약 보고

**Heartbeat 형식:**
```
[Team:{team-name}] 진행 중... ({완료된 Task}/{전체 Task} 완료)
```

**구현:** 오케스트레이터가 TaskList를 호출하여 상태를 확인하고, 텍스트 출력으로 사용자에게 보고한다. AskUserQuestion이 아닌 단순 텍스트 출력이므로 작업 흐름을 중단하지 않는다.

**컨텍스트 비용:** TaskList 1회 호출 + 1줄 출력 = 최소한의 오케스트레이터 컨텍스트 소비. 팀 멤버의 작업에는 영향 없음.

## Agent Team 토론 종료 프로토콜 (P-005)

토론이 정상적으로 합의에 도달하지 못하는 경우를 대비한 종료 시나리오별 행동 규칙.

| 시나리오 | 조건 | 행동 |
|---------|------|------|
| **정상 합의** | 모든 팀원이 결론에 동의 | 정상 종료 → 합의 결과를 산출물에 반영 |
| **부분 합의** | Max iteration 도달 + 일부 항목만 합의 | 합의 항목은 반영, 미합의 항목은 severity 한 단계 하향 후 기록 |
| **합의 없음** | Max iteration 도달 + 전체 미합의 | 리더가 단독 판단, Decision Journal에 `[Decision] 리더 단독 판단 — {근거}` 기록 |
| **교착** | 2회 연속 동일 논점 반복 | 즉시 리더 판단으로 전환, 토론 종료 |

**적용 규칙:**
- 교착 감지: 연속 2회의 토론 라운드에서 동일 논점이 새로운 논거 없이 반복되면 교착으로 판정
- 리더 단독 판단 시 반드시 근거를 Decision Journal에 기록하여 추적 가능성 확보
- 미합의 항목의 severity 하향은 "증거 불충분"을 반영한 보수적 판단

## Fallback: Agent Teams 미활성 시

Agent Teams 기능이 비활성(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 미설정)인 환경에서는 일반 subagent 기반 대체 방식을 사용한다.

### 감지 방법

팀 생성 시 `TeamCreate`를 시도한다. 실패하면(기능 미활성, 도구 미존재 등) 즉시 Fallback 모드로 전환한다.

### Fallback 절차

Agent Teams의 `TeamCreate → TaskCreate → Agent spawn with team_name → SendMessage → TeamDelete` 대신:

1. **전문가 개별 spawn**: 각 전문가를 `Agent(subagent_type="general-purpose")`로 spawn한다. prompt에 전문가 역할과 분석 대상을 명시한다.
2. **공유 파일 경로에 findings 기록**: 각 subagent는 분석 결과를 `.claude/memory/expert-findings/{expert-name}.md`에 기록한다. 이 경로가 Agent Teams의 공유 작업 목록을 대체한다.
3. **오케스트레이터의 교차 검증**: 모든 subagent 완료 후, 오케스트레이터가 전체 findings 파일을 읽고 교차 검증(cross-verification)을 수행한다. 이것이 Agent Teams의 "토론(SendMessage)" 단계를 대체한다.
   - 전문가 간 상충되는 의견이 있으면 오케스트레이터가 판단하여 최종 합의를 도출한다.
   - 합의 결과를 동일한 최종 산출물 파일(예: `code-design-analysis.md`, `expert-plan-concerns.md`)에 기록한다.
4. **정리**: `SendMessage`나 `TaskList`, `TeamDelete`는 사용하지 않는다. subagent 완료로 자동 정리된다.

### Fallback의 특성

- 실시간 peer messaging(SendMessage)이 없으므로 전문가 간 직접 토론은 불가하다. 대신 오케스트레이터가 findings를 종합하여 교차 검증한다.
- 최종 산출물의 품질과 형식은 Agent Teams 사용 시와 동등하다.
- 워크플로의 다른 모든 규칙(scope, anti-goals, severity routing, loop limits 등)은 동일하게 적용된다.

### 적용 범위

이 fallback은 Agent Teams를 사용하는 모든 단계에 적용된다:
- simon-bot: Code Design Team (Step 1-A), Plan Review Team (Steps 2-4), Expert Review Team (Step 4-B), Impl Review Team (Step 7)
- simon-bot-grind: 위 모든 단계 + grind 확장
- simon-bot-report: Code Design Analysis (Step 2), Domain Expert Team (Step 3)

Fallback 모드로 전환 시 `.claude/memory/agent-teams-status.md`에 기록:
```
Mode: subagent-fallback
Reason: TeamCreate failed / AGENT_TEAMS env not set
Timestamp: {timestamp}
```
