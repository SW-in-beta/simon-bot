# Startup Bootstrap — Monitor & Completion Gate

## Monitor 자동 시작 + 주소 통보

simon-monitor는 **단일 공유 서버**로 운영한다. 세션마다 별도 서버를 띄울 필요가 없으며, 포트 충돌은 3847→3857 폴백으로 해결한다.

```bash
MONITOR_PID_FILE=/tmp/simon-monitor.pid
MONITOR_PORT_FILE=/tmp/simon-monitor.port
MONITOR_PORT=""

find_available_port() {
  for p in $(seq 3847 3857); do
    if ! lsof -iTCP:$p -sTCP:LISTEN >/dev/null 2>&1; then
      echo $p; return 0
    fi
  done
  return 1
}

if ! ([ -f "$MONITOR_PID_FILE" ] && kill -0 $(cat "$MONITOR_PID_FILE") 2>/dev/null); then
  [ -f "$MONITOR_PID_FILE" ] && rm "$MONITOR_PID_FILE"
  MONITOR_PORT=$(find_available_port) || MONITOR_PORT=""
  if [ -n "$MONITOR_PORT" ]; then
    nohup python3 ~/.claude/skills/simon-monitor/scripts/server.py \
      --session "$SESSION_DIR" --port "$MONITOR_PORT" > /tmp/simon-monitor.log 2>&1 &
    echo $! > "$MONITOR_PID_FILE"
    echo "$MONITOR_PORT" > "$MONITOR_PORT_FILE"
    MONITOR_STATUS="시작"
  else
    MONITOR_STATUS="실패(3847-3857 포트 모두 점유)"
  fi
else
  MONITOR_PORT=$(cat "$MONITOR_PORT_FILE" 2>/dev/null || echo 3847)
  MONITOR_STATUS="이미 실행 중"
fi
MONITOR_URL="http://localhost:${MONITOR_PORT:-3847}"
[ -n "$MONITOR_PORT" ] && open "$MONITOR_URL" 2>/dev/null || true
```

**통보 의무**: bash 실행 직후 반드시 아래 형식으로 **실제 포트**를 포함하여 한 줄 통보한다.
```
[Monitor] {시작|이미 실행 중|실패(...)} — http://localhost:{MONITOR_PORT}
```

`lsof`가 없는 환경에서는 `find_available_port`가 모두 "비어있음"으로 판정할 수 있다. 이 경우 첫 시도 포트로 시작하되 bind 실패 시 server.py 로그(/tmp/simon-monitor.log)를 확인하여 다음 포트로 재시도한다.

## workflow_start 발신

대시보드가 전체 Step 목록을 렌더링하는 데 필요하다. `$BRANCH`는 `.claude/memory/branch-name.md`에서, `$TASK_SUMMARY`는 사용자 요청에서 추출한다. emit.sh가 없거나 실패하면 무시하고 진행.

```bash
bash ~/.claude/skills/simon-monitor/scripts/emit.sh workflow_start "" "워크플로 시작" '{"skill":"simon","branch":"'"$BRANCH"'","task":"'"$TASK_SUMMARY"'","scope":"TBD","workflow_steps":[{"id":"A/0","name":"Scope Challenge","phase":"A"},{"id":"A/1-A","name":"Project Analysis","phase":"A"},{"id":"A/1-B","name":"Plan Creation","phase":"A"},{"id":"A/2","name":"Plan Review","phase":"A"},{"id":"A/3","name":"Meta Verification","phase":"A"},{"id":"A/4","name":"Over-engineering Check","phase":"A"},{"id":"A/4-B","name":"Expert Plan Review","phase":"A"},{"id":"A/calibration","name":"Phase A Calibration","phase":"A"},{"id":"B/5","name":"Implementation","phase":"B"},{"id":"B/6","name":"Purpose Alignment","phase":"B"},{"id":"B/7","name":"Code Review","phase":"B"},{"id":"B/8","name":"Regression Verification","phase":"B"},{"id":"B/9","name":"File/Function Splitting","phase":"B"},{"id":"B/10","name":"Integration/Reuse Review","phase":"B"},{"id":"B/11","name":"Side Effect Check","phase":"B"},{"id":"B/12","name":"Full Change Review","phase":"B"},{"id":"B/13","name":"Dead Code Cleanup","phase":"B"},{"id":"B/14","name":"Code Quality","phase":"B"},{"id":"B/15","name":"Flow Verification","phase":"B"},{"id":"B/16","name":"MEDIUM Issue Resolution","phase":"B"},{"id":"B/17","name":"Production Readiness","phase":"B"},{"id":"review/18-A","name":"Work Report","phase":"review"},{"id":"review/18-B","name":"Review Sequence","phase":"review"},{"id":"review/19","name":"Code Review","phase":"review"}]}'
```

## Startup Completion Gate

Deterministic Gate Principle 적용. bash로 필수 파일 존재와 monitor 실행을 확인한 후에만 Phase A 진입.

```bash
echo "=== Startup Completion Gate ==="
test -f "${SESSION_DIR}/memory/workflow-state.json" && echo "OK workflow-state.json" || echo "FAIL workflow-state.json 없음"
test -f "${SESSION_DIR}/memory/session-meta.json" && echo "OK session-meta.json" || echo "FAIL session-meta.json 없음"
(test -f /tmp/simon-monitor.pid && kill -0 $(cat /tmp/simon-monitor.pid) 2>/dev/null) && echo "OK monitor 실행 중" || echo "WARN monitor 미실행 (허용)"
```

체크리스트:
- [ ] `${SESSION_DIR}/memory/workflow-state.json` 존재 (필수)
- [ ] `${SESSION_DIR}/memory/session-meta.json` 존재 (필수)
- [ ] Monitor URL 사용자 통보 완료 (실제 서버 실행은 failure tolerant)
- [ ] workflow_start 이벤트 발신 시도 완료 (emit.sh 실패 시 skip 기록)

FAIL 항목이 있으면 Phase A 진입을 중단하고 해당 단계(3-C/3-D/3-E)로 돌아가 재수행한다.
