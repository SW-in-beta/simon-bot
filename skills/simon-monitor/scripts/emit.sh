#!/usr/bin/env bash
# emit.sh — simon* 워크플로 이벤트 발신기 (자동 감지, 위치 인자)
#
# Claude Code의 각 Bash 호출은 독립된 셸이므로, $E 변수나 $SESSION_DIR을
# 유지할 수 없다. 이 스크립트는 git context에서 세션을 자동 감지하여
# 한 줄로 이벤트를 발신할 수 있게 한다.
#
# Usage:
#   emit.sh <type> <step> <title> [data_json]
#   emit.sh pending                              # .pending-event.json 발신
#
# Examples:
#   emit.sh step_start A/0 "Scope Challenge 시작"
#   emit.sh step_complete A/0 "STANDARD 경로 결정" '{"verdict":"STANDARD"}'
#   emit.sh expert_panel A/1-A "Code Design Team" '{"panel_name":"CDT","opinions":[]}'
#   emit.sh workflow_start "" "워크플로 시작" '{"skill":"simon","branch":"feat/x"}'
#   emit.sh pending                              # SESSION_DIR/.pending-event.json 사용
#
# 실패 시 exit 0 — 모니터링이 워크플로를 방해하면 안 된다.

# 실패해도 워크플로를 중단하지 않음
trap 'exit 0' ERR

# --- 세션 디렉토리 자동 감지 ---
detect_session_dir() {
  # 1) 환경변수로 명시된 경우
  if [[ -n "${SIMON_SESSION_DIR:-}" ]]; then
    echo "$SIMON_SESSION_DIR"
    return
  fi

  # 2) git context에서 추론
  local toplevel branch project_slug session_dir
  toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  branch=$(git branch --show-current 2>/dev/null) || return 1
  [[ -z "$toplevel" || -z "$branch" ]] && return 1

  project_slug=$(echo "$toplevel" | tr '/' '-')
  session_dir="$HOME/.claude/projects/${project_slug}/sessions/${branch}"

  # events.jsonl 또는 workflow-state.json이 있는 세션만 유효
  if [[ -f "${session_dir}/events.jsonl" ]] || [[ -f "${session_dir}/memory/workflow-state.json" ]]; then
    echo "$session_dir"
    return
  fi

  # 3) 해당 프로젝트의 가장 최근 세션 (브랜치명이 다를 수 있음)
  local latest
  latest=$(find "$HOME/.claude/projects/${project_slug}/sessions" \
    -name "workflow-state.json" -o -name "events.jsonl" 2>/dev/null \
    | xargs ls -t 2>/dev/null | head -1)
  if [[ -n "$latest" ]]; then
    echo "$(dirname "$(dirname "$latest")")"
    return
  fi

  return 1
}

# --- 스킬명 자동 감지 ---
detect_skill() {
  local session_dir="$1"
  local state_file="${session_dir}/memory/workflow-state.json"
  if [[ -f "$state_file" ]]; then
    python3 -c "
import json
with open('$state_file') as f:
    print(json.load(f).get('skill', 'unknown'))
" 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# --- 메인 ---
SESSION_DIR=$(detect_session_dir) || exit 0
[[ -z "$SESSION_DIR" ]] && exit 0

mkdir -p "$SESSION_DIR"
EVENTS_FILE="${SESSION_DIR}/events.jsonl"
SKILL=$(detect_skill "$SESSION_DIR")

# UUID 생성
generate_uuid() {
  if command -v uuidgen &>/dev/null; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    python3 -c "import uuid; print(uuid.uuid4())"
  fi
}

EVENT_ID=$(generate_uuid)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- pending 모드: .pending-event.json 발신 ---
if [[ "${1:-}" == "pending" ]]; then
  PENDING_FILE="${SESSION_DIR}/.pending-event.json"
  [[ ! -f "$PENDING_FILE" ]] && exit 0

  python3 -c "
import json
with open('${PENDING_FILE}') as f:
    pending = json.load(f)
event = {
    'id': '${EVENT_ID}',
    'timestamp': '${TIMESTAMP}',
    'skill': pending.get('skill', '${SKILL}'),
    'step': pending.get('step'),
    'type': pending.get('type', 'unknown'),
    'title': pending.get('title', ''),
    'data': pending.get('data', {})
}
print(json.dumps(event, ensure_ascii=False))
" >> "$EVENTS_FILE"
  rm -f "$PENDING_FILE"
  exit 0
fi

# --- CLI 모드: 위치 인자로 발신 ---
TYPE="${1:-}"
STEP="${2:-}"
TITLE="${3:-}"
DATA="${4:-}"
[[ -z "$DATA" ]] && DATA="{}"

[[ -z "$TYPE" ]] && exit 0

# 환경변수로 Python에 전달 (셸 이스케이프 문제 회피)
export _EMIT_ID="$EVENT_ID"
export _EMIT_TS="$TIMESTAMP"
export _EMIT_SKILL="$SKILL"
export _EMIT_STEP="$STEP"
export _EMIT_TYPE="$TYPE"
export _EMIT_TITLE="$TITLE"
export _EMIT_DATA="$DATA"

python3 << 'PYEOF' >> "$EVENTS_FILE"
import json, os

data_str = os.environ.get("_EMIT_DATA", "{}")
try:
    data = json.loads(data_str) if data_str.strip() else {}
except Exception:
    data = {}

step_val = os.environ.get("_EMIT_STEP", "")

event = {
    "id": os.environ["_EMIT_ID"],
    "timestamp": os.environ["_EMIT_TS"],
    "skill": os.environ.get("_EMIT_SKILL", "unknown"),
    "step": step_val if step_val else None,
    "type": os.environ["_EMIT_TYPE"],
    "title": os.environ.get("_EMIT_TITLE", ""),
    "data": data
}
print(json.dumps(event, ensure_ascii=False))
PYEOF
