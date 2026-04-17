---
name: simon-monitor
description: "simon* 워크플로 실시간 시각화 대시보드 — simon, simon-grind, simon-pm 파이프라인의 모든 단계를 웹에서 실시간 추적합니다. 전문가 패널 의견, 서브에이전트 호출/결과, 의사결정 근거, 게이트 통과/실패를 시각적으로 확인합니다. Use when: (1) simon/grind/pm 워크플로를 실시간 모니터링하고 싶을 때 ('모니터', '대시보드', '워크플로 보여줘', '진행 상황'), (2) 완료된 세션의 실행 이력을 리뷰할 때 ('세션 리뷰', '실행 이력'), (3) 워크플로가 제대로 실행됐는지 검증할 때 ('워크플로 검증', '단계 확인')."
---

# simon-monitor

simon* 워크플로(simon, simon-grind, simon-pm)의 실행 과정을 웹 대시보드로 실시간 시각화한다.

## 핵심 동작

대시보드가 보여주는 것:
- 워크플로 단계별 진행 상황 (pending → running → completed/failed/skipped)
- 전문가 패널 의견과 토론 결과 (Code Design Team, Domain Expert Team 등)
- 서브에이전트 호출 내역과 반환 결과
- 의사결정 기록과 근거 (어떤 선택지 중 무엇을 왜 골랐는지)
- 게이트 통과/실패 이력

## 사용 모드

### 1. 모니터링 시작 (`/simon-monitor` 또는 `/simon-monitor start`)

현재 프로젝트의 활성 세션 또는 지정된 세션의 대시보드를 연다.

**실행 순서:**

1. 세션 디렉토리 결정
   - 사용자가 세션 경로를 지정하면 그것을 사용
   - 아니면 현재 프로젝트의 가장 최근 세션을 자동 감지:
     ```bash
     # 가장 최근 events.jsonl이 있는 세션 찾기 (중첩 브랜치명 대응)
     find ~/.claude/projects -path "*/sessions/*/events.jsonl" 2>/dev/null | xargs ls -t 2>/dev/null | head -1 | xargs dirname
     ```
   - 세션이 없으면 사용자에게 안내: "아직 모니터링할 세션이 없습니다. simon/grind/pm 워크플로를 먼저 시작하세요."

2. 기존 서버 정리
   ```bash
   if [ -f /tmp/simon-monitor.pid ]; then
     kill $(cat /tmp/simon-monitor.pid) 2>/dev/null
     rm /tmp/simon-monitor.pid
   fi
   ```

3. 대시보드 서버 시작 (백그라운드)
   ```bash
   nohup python3 ~/.claude/skills/simon-monitor/scripts/server.py \
     --session "<SESSION_DIR>" --port 3847 > /tmp/simon-monitor.log 2>&1 &
   echo $! > /tmp/simon-monitor.pid
   ```

4. 브라우저에서 열기
   ```bash
   open http://localhost:3847
   ```

5. 사용자에게 안내:
   "대시보드를 열었습니다 (http://localhost:3847). 워크플로가 실행되면 실시간으로 업데이트됩니다."

### 2. 세션 목록 확인 (`/simon-monitor sessions`)

```bash
python3 ~/.claude/skills/simon-monitor/scripts/server.py --list-sessions
```

### 3. 모니터링 종료 (`/simon-monitor stop`)

```bash
if [ -f /tmp/simon-monitor.pid ]; then
  kill $(cat /tmp/simon-monitor.pid) 2>/dev/null
  rm /tmp/simon-monitor.pid
  echo "모니터링 종료됨"
else
  echo "실행 중인 모니터가 없습니다"
fi
```

## 이벤트 발신 (simon* 스킬에서의 호출)

simon* 워크플로 실행 중 주요 지점에서 이벤트를 발신한다. 이벤트는 `{SESSION_DIR}/events.jsonl`에 한 줄 JSON으로 적재된다.

### 발신 방법

**간단한 이벤트 (위치 인자):**
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh <type> <step> <title> [data_json]
```

SESSION_DIR과 skill은 자동 감지된다 (git context + workflow-state.json).

예시:
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_start A/0 "Scope Challenge 시작"
bash ~/.claude/skills/simon-monitor/scripts/emit.sh step_complete A/0 "STANDARD 결정" '{"verdict":"STANDARD"}'
```

**복잡한 payload (.pending-event.json):**

1. `{SESSION_DIR}/.pending-event.json`에 JSON 작성:
```json
{
  "step": "A/1-A",
  "type": "expert_panel",
  "title": "Code Design Team 분석",
  "data": {
    "panel_name": "Code Design Team",
    "opinions": [
      {"role": "Convention Expert", "opinion": "기존 DDD 패턴을 따라야 합니다", "severity": "MEDIUM"}
    ],
    "consensus": "DDD 패턴 유지, 신규 기능만 추가"
  }
}
```

2. 발신:
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh pending
```

**폴백: workflow-state.json 감시:**

서버는 `workflow-state.json`도 0.5초마다 감시하여 step 전환 시 자동으로 기본 이벤트(step_start, step_complete, step_skip)를 생성한다. 명시적 발신이 빠져도 기본 진행 타임라인은 보장된다.

### 이벤트 발신 시점

워크플로의 이벤트 발신 포인트는 `references/instrumentation-guide.md`에 정리되어 있다. 핵심 포인트:

| 시점 | 이벤트 타입 | 내용 |
|------|------------|------|
| 단계 시작 | `step_start` | 단계 ID, 설명 |
| 단계 완료 | `step_complete` | 요약, 생성된 아티팩트, 소요 시간 |
| 전문가 패널 | `expert_panel` | 각 전문가 의견, 합의, 액션 아이템 |
| 서브에이전트 호출 | `subagent_spawn` | 에이전트 이름, 유형, 작업 내용 |
| 서브에이전트 결과 | `subagent_result` | 결과 요약, 핵심 발견, 소요 시간 |
| 의사결정 | `decision` | 결정 내용, 근거, 고려한 대안 |
| 게이트 통과/실패 | `gate_pass`/`gate_fail` | 체크 항목별 결과, 후속 조치 |
| 에러/재시도 | `error`/`retry` | 에러 내용, 재시도 전략, 시도 횟수 |

이벤트 스키마 상세: `references/event-schema.md`

### workflow_start 이벤트 (필수)

워크플로 시작 시 반드시 첫 이벤트로 발신:
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh workflow_start null "워크플로 시작" \
  '{"skill":"simon","branch":"feat/add-auth","task":"인증 기능 추가","scope":"STANDARD","session_id":"feat/add-auth","parent_session_id":null}'
```

## 주의사항

- 서버는 `127.0.0.1`에서만 리스닝 (외부 접근 불가)
- 이벤트 파일이 없는 세션도 빈 대시보드로 열림 (이벤트가 들어오면 자동 표시)
- simon-pm이 simon을 위임하면 자식 세션의 이벤트도 함께 표시 (`parent_session_id`로 연결)
- emit-event.sh가 없거나 실패해도 워크플로 자체는 중단되지 않아야 함 — 이벤트 발신 실패는 무시
- `scripts/generate-mock-events.py` — 테스트용 모의 이벤트를 생성하여 대시보드 동작을 검증할 수 있음 (`python3 scripts/generate-mock-events.py --session <SESSION_DIR> --all`)
