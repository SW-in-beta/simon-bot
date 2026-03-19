#!/usr/bin/env bash
# detect-progress.sh — failure-log.jsonl의 최근 2항목을 비교하여 진전 여부 판정
# 사용: detect-progress.sh <failure-log.jsonl 경로>
# 출력: {"progress": true/false, "failing_tests_delta": N, "error_changed": bool, "lines_changed": N}
# exit 0=진전 있음, 1=진전 없음(stalled)
set -euo pipefail

LOG_FILE="${1:?Usage: detect-progress.sh <failure-log.jsonl>}"

if [ ! -f "$LOG_FILE" ]; then
  echo '{"progress": true, "failing_tests_delta": 0, "error_changed": true, "lines_changed": 0}'
  exit 0
fi

LINE_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')

if [ "$LINE_COUNT" -lt 2 ]; then
  echo '{"progress": true, "failing_tests_delta": 0, "error_changed": true, "lines_changed": 0}'
  exit 0
fi

# 최근 2행 추출
PREV=$(tail -2 "$LOG_FILE" | head -1)
CURR=$(tail -1 "$LOG_FILE")

# 실패 테스트 수 비교
PREV_FAILS=$(echo "$PREV" | grep -oE '"failing_tests":\s*[0-9]+' | grep -oE '[0-9]+' || echo "0")
CURR_FAILS=$(echo "$CURR" | grep -oE '"failing_tests":\s*[0-9]+' | grep -oE '[0-9]+' || echo "0")
DELTA=$((CURR_FAILS - PREV_FAILS))

# 에러 메시지 변경 여부
PREV_ERROR=$(echo "$PREV" | grep -oE '"error_signature":\s*"[^"]*"' | sed 's/"error_signature":\s*"//' | sed 's/"$//' || echo "")
CURR_ERROR=$(echo "$CURR" | grep -oE '"error_signature":\s*"[^"]*"' | sed 's/"error_signature":\s*"//' | sed 's/"$//' || echo "")

if [ "$PREV_ERROR" = "$CURR_ERROR" ]; then
  ERROR_CHANGED=false
else
  ERROR_CHANGED=true
fi

# 변경된 코드 라인 수 (git diff --stat)
LINES_CHANGED=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion|[0-9]+ deletion' | grep -oE '[0-9]+' | paste -sd+ - | bc 2>/dev/null || echo "0")

# 진전 판정: 세 항목 모두 변화 없으면 stalled
PROGRESS=false
if [ "$DELTA" -lt 0 ]; then
  PROGRESS=true
elif [ "$ERROR_CHANGED" = true ]; then
  PROGRESS=true
elif [ "${LINES_CHANGED:-0}" -gt 0 ]; then
  PROGRESS=true
fi

echo "{\"progress\": $PROGRESS, \"failing_tests_delta\": $DELTA, \"error_changed\": $ERROR_CHANGED, \"lines_changed\": ${LINES_CHANGED:-0}}"

if [ "$PROGRESS" = true ]; then
  exit 0
else
  exit 1
fi
