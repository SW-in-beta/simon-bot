#!/usr/bin/env bash
# progress-detect.sh — failure-log.md의 최근 2건 재시도 결과를 비교하여 진행 상태를 판정
# Usage: progress-detect.sh <failure-log-path>
# Output: JSON {"status": "PROGRESS|STALL|REGRESS", "prev_errors": N, "curr_errors": N, "changed_lines": N}
set -euo pipefail
FAILURE_LOG="${1:?Usage: progress-detect.sh <failure-log-path>}"
if [[ ! -f "$FAILURE_LOG" ]]; then echo '{"status":"NO_DATA","prev_errors":0,"curr_errors":0,"changed_lines":0}'; exit 0; fi
# Extract last 2 attempt blocks (separated by "## Attempt")
BLOCKS=$(grep -c "^## Attempt" "$FAILURE_LOG" 2>/dev/null || echo 0)
if [[ "$BLOCKS" -lt 2 ]]; then echo '{"status":"NO_DATA","prev_errors":0,"curr_errors":0,"changed_lines":0}'; exit 0; fi
# Count error lines in last 2 blocks
PREV_ERRORS=$(awk '/^## Attempt/{n++} n==('$BLOCKS'-1){print}' "$FAILURE_LOG" | grep -ci "error\|fail\|panic" || echo 0)
CURR_ERRORS=$(awk '/^## Attempt/{n++} n=='$BLOCKS'{print}' "$FAILURE_LOG" | grep -ci "error\|fail\|panic" || echo 0)
CHANGED=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -oP '\d+ file' | grep -oP '\d+' || echo 0)
if [[ "$CURR_ERRORS" -lt "$PREV_ERRORS" ]]; then STATUS="PROGRESS"
elif [[ "$CURR_ERRORS" -eq "$PREV_ERRORS" ]]; then STATUS="STALL"
else STATUS="REGRESS"; fi
echo "{\"status\":\"$STATUS\",\"prev_errors\":$PREV_ERRORS,\"curr_errors\":$CURR_ERRORS,\"changed_lines\":$CHANGED}"
