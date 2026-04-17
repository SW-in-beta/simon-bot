# simon* 스킬 계측 가이드 (Instrumentation Guide)

이 문서는 simon, simon-grind, simon-pm 스킬에 이벤트 발신을 추가하는 방법을 설명합니다.

## 원칙

1. **이벤트 발신 실패는 워크플로를 중단하지 않아야 한다** — 모니터링은 부가 기능
2. **핵심 지점에서만 발신** — 모든 행동을 로깅하면 오히려 노이즈. 의미 있는 전환점에서만
3. **구조화된 데이터** — 사람이 읽을 수 있되, 기계도 파싱할 수 있는 JSON

## 발신 방법

> **참고:** `emit.sh`는 git 컨텍스트에서 `SESSION_DIR`을 자동 감지하고, `workflow-state.json`에서 skill 정보를 읽습니다. `--session`과 `--skill` 인자는 더 이상 필요하지 않으며, 실패는 내부적으로 처리됩니다.

### 방법 1: .pending-event.json (권장 — 복잡한 payload)

```markdown
<!-- SKILL.md에 추가할 지시 -->
이벤트 발신: `{SESSION_DIR}/.pending-event.json`에 작성 후 실행:

\```json
{
  "step": "A/1-A",
  "type": "expert_panel",
  "title": "Code Design Team 분석",
  "data": {
    "panel_name": "Code Design Team",
    "opinions": [
      {"role": "<역할>", "opinion": "<핵심 의견 1-2문장>", "severity": "<INFO|LOW|MEDIUM|HIGH|CRITICAL>"}
    ],
    "consensus": "<합의 내용>",
    "action_items": ["<액션1>", "<액션2>"]
  }
}
\```

\```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh pending
\```
```

### 방법 2: CLI 인자 (간단한 이벤트)

```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh <type> <step> <title> [data_json]
```

---

## simon 계측 포인트

### Startup

| 위치 | 이벤트 | 비고 |
|------|--------|------|
| workflow-state.json 초기화 후 | `workflow_start` | **필수** — skill, branch, task, scope |
| preflight.sh 통과 후 | `step_complete` for startup/6 | |

### Phase A: Planning

| 위치 | 이벤트 | 비고 |
|------|--------|------|
| Step 0 시작 | `step_start` A/0 | |
| architect 서브에이전트 호출 시 | `subagent_spawn` | agent_name, task |
| architect 결과 수신 시 | `subagent_result` | summary, key_findings |
| 경로 결정 시 (SMALL/STANDARD/LARGE) | `decision` | rationale, alternatives |
| Step 0 완료 | `step_complete` A/0 | |
| Step 1-A 시작 | `step_start` A/1-A | |
| Code Design Team 토론 후 | `expert_panel` | opinions, consensus, action_items |
| Step 1-A 완료 | `step_complete` A/1-A | artifacts 포함 |
| Step 1-B planner 호출 시 | `subagent_spawn` | |
| Step 1-B 완료 | `step_complete` A/1-B | |
| Steps 2-4 내부 리뷰 후 | `expert_panel` | planner + critic + architect |
| Step 4-B Domain Expert 리뷰 후 | `expert_panel` | 5개 도메인팀 |
| Phase A Calibration | `gate_pass` or `gate_fail` | 7개 체크 |

### Phase B-E: Implementation

| 위치 | 이벤트 | 비고 |
|------|--------|------|
| Step 5 executor 호출 시 | `subagent_spawn` | background: true |
| Step 5 executor 완료 시 | `subagent_result` | 구현 요약 |
| Step 7 코드 리뷰 패널 후 | `expert_panel` | Security/Performance/Bug |
| Step 17 Done-When 체크 | `gate_pass` or `gate_fail` | 체크 항목별 |
| SMALL 경로에서 Steps 9-16 스킵 시 | `step_skip` (각각) | |

### Review

| 위치 | 이벤트 | 비고 |
|------|--------|------|
| Step 18-A writer 호출 시 | `subagent_spawn` | |
| Step 18-A 완료 | `step_complete` + `artifact` | |
| Step 19 simon-code-review 위임 시 | `decision` | CONNECTED/STANDALONE |
| 워크플로 종료 시 | `workflow_complete` | **필수** — status, summary |

---

## simon-grind 추가 계측 포인트

simon의 모든 포인트 + 다음 추가:

| 위치 | 이벤트 | 비고 |
|------|--------|------|
| 빌드/테스트 실패 시 | `error` | message, category, attempt |
| 재시도 시작 시 | `retry` | attempt, max, tier, strategy |
| 전략 전환 시 | `decision` | pivot 근거 |
| 체크포인트 생성 시 | `artifact` | checkpoint tag |
| Progress Pulse (3연속 실패 등) | `error` | 누적 실패 정보 |

---

## simon-pm 계측 포인트

| 위치 | 이벤트 | 비고 |
|------|--------|------|
| Phase 0 완료 | `workflow_start` | skill: simon-pm |
| Phase 1-C CTO+Dev Lead 패널 후 | `expert_panel` | 기술 결정 |
| Phase 2-A architect 결과 | `subagent_result` | 피처 분해 결과 |
| Phase 2-C 봇 할당 결정 | `decision` | simon vs grind 할당 근거 |
| Phase 4 피처 위임 시 | `child_session` | child_session_id, feature |
| Phase 5 검증 게이트 | `gate_pass`/`gate_fail` | |
| Phase 6 완료 | `workflow_complete` | |

---

## 계측 추가 절차

1. 대상 스킬의 SKILL.md (또는 reference 파일) 열기
2. 해당 위치에 이벤트 발신 지시 추가
3. `$SESSION_DIR`은 `emit.sh`가 git 컨텍스트에서 자동 감지하므로 별도로 전달할 필요 없음
4. 테스트: mock session으로 워크플로 일부 실행 → events.jsonl 확인

### 새 스킬 계측 시 최소 필수 이벤트

- `workflow_start` (시작)
- `step_start` / `step_complete` (각 주요 단계)
- `workflow_complete` (종료)

이 3종류만 있으면 대시보드 타임라인이 동작합니다. 나머지(expert_panel, subagent 등)는 점진적으로 추가하세요.
