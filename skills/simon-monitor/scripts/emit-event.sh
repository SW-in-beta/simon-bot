#!/usr/bin/env bash
# emit-event.sh — simon* 워크플로 이벤트 발신기
# .pending-event.json을 읽어 events.jsonl에 적재
#
# Usage:
#   emit-event.sh --session <SESSION_DIR>
#   emit-event.sh --session <SESSION_DIR> --skill simon --step "A/1-A" --type step_start --title "제목" [--data '{"key":"val"}']
#
# Mode 1 (file-based): SESSION_DIR/.pending-event.json이 있으면 그 내용을 사용
# Mode 2 (cli-args): --step, --type, --title로 직접 지정

set -euo pipefail

SESSION_DIR=""
SKILL=""
STEP=""
TYPE=""
TITLE=""
DATA="{}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session)  SESSION_DIR="$2"; shift 2 ;;
    --skill)    SKILL="$2"; shift 2 ;;
    --step)     STEP="$2"; shift 2 ;;
    --type)     TYPE="$2"; shift 2 ;;
    --title)    TITLE="$2"; shift 2 ;;
    --data)     DATA="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$SESSION_DIR" ]]; then
  echo "Error: --session is required" >&2
  exit 1
fi

EVENTS_FILE="${SESSION_DIR}/events.jsonl"
PENDING_FILE="${SESSION_DIR}/.pending-event.json"

# Generate UUID
generate_uuid() {
  if command -v uuidgen &>/dev/null; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    python3 -c "import uuid; print(uuid.uuid4())"
  fi
}

# ISO 8601 timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EVENT_ID=$(generate_uuid)

# Mode 1: Read from .pending-event.json
if [[ -f "$PENDING_FILE" ]]; then
  # Read pending event and merge with envelope
  python3 -c "
import json, sys

with open('${PENDING_FILE}') as f:
    pending = json.load(f)

event = {
    'id': '${EVENT_ID}',
    'timestamp': '${TIMESTAMP}',
    'skill': pending.get('skill', '${SKILL}') or '',
    'step': pending.get('step'),
    'type': pending.get('type', 'unknown'),
    'title': pending.get('title', ''),
    'data': pending.get('data', {})
}

print(json.dumps(event, ensure_ascii=False))
"  >> "$EVENTS_FILE"

  rm -f "$PENDING_FILE"

# Mode 2: CLI arguments
elif [[ -n "$TYPE" ]]; then
  python3 -c "
import json

data_str = '''${DATA}'''
try:
    data = json.loads(data_str) if data_str.strip() else {}
except:
    data = {}

event = {
    'id': '${EVENT_ID}',
    'timestamp': '${TIMESTAMP}',
    'skill': '${SKILL}',
    'step': '${STEP}' if '${STEP}' else None,
    'type': '${TYPE}',
    'title': '${TITLE}',
    'data': data
}

print(json.dumps(event, ensure_ascii=False))
" >> "$EVENTS_FILE"

else
  echo "Error: No .pending-event.json found and no --type specified" >&2
  exit 1
fi
