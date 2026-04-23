#!/usr/bin/env bash
# progress-detect.sh — failure-log.md의 최근 2건 재시도 결과를 비교하여 진행 상태를 판정
# Usage: progress-detect.sh <failure-log-path>
# Output: JSON {"status": "PROGRESS|STALL|REGRESS", "prev_errors": N, "curr_errors": N, "changed_lines": N, "failing_tests_delta": N}
#
# 3가지 출력 상태:
#   PROGRESS — 에러 수 감소. 계속 진행.
#   STALL    — 에러 수 동일 (2회 연속 시 전략 전환 트리거).
#   REGRESS  — 에러 수 증가 (failing_tests_delta > 0) 또는 새 에러 카테고리 도입.
#              → checkpoint 롤백 + /rewind 힌트 출력 대상.
set -euo pipefail
FAILURE_LOG="${1:?Usage: progress-detect.sh <failure-log-path>}"
if [[ ! -f "$FAILURE_LOG" ]]; then echo '{"status":"NO_DATA","prev_errors":0,"curr_errors":0,"changed_lines":0,"failing_tests_delta":0}'; exit 0; fi
# Extract last 2 attempt blocks (separated by "## Attempt")
BLOCKS=$(grep -c "^## Attempt" "$FAILURE_LOG" 2>/dev/null || echo 0)
if [[ "$BLOCKS" -lt 2 ]]; then echo '{"status":"NO_DATA","prev_errors":0,"curr_errors":0,"changed_lines":0,"failing_tests_delta":0}'; exit 0; fi
# Count error lines in last 2 blocks
PREV_ERRORS=$(awk '/^## Attempt/{n++} n==('$BLOCKS'-1){print}' "$FAILURE_LOG" | grep -ci "error\|fail\|panic" || echo 0)
CURR_ERRORS=$(awk '/^## Attempt/{n++} n=='$BLOCKS'{print}' "$FAILURE_LOG" | grep -ci "error\|fail\|panic" || echo 0)
CHANGED=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -oP '\d+ file' | grep -oP '\d+' || echo 0)
# failing_tests_delta: 양수면 퇴행, 음수면 개선, 0이면 변화 없음
DELTA=$((CURR_ERRORS - PREV_ERRORS))
# 새 에러 카테고리 감지 (이전 블록에 없던 에러 유형이 현재 블록에 나타나는지)
PREV_CATS=$(awk '/^## Attempt/{n++} n==('$BLOCKS'-1){print}' "$FAILURE_LOG" | grep -oiP "(TypeError|ValueError|ImportError|SyntaxError|AttributeError|KeyError|IndexError|RuntimeError|AssertionError|NotImplementedError)" | sort -u || true)
CURR_CATS=$(awk '/^## Attempt/{n++} n=='$BLOCKS'{print}' "$FAILURE_LOG" | grep -oiP "(TypeError|ValueError|ImportError|SyntaxError|AttributeError|KeyError|IndexError|RuntimeError|AssertionError|NotImplementedError)" | sort -u || true)
NEW_CATS=$(comm -13 <(echo "$PREV_CATS") <(echo "$CURR_CATS") 2>/dev/null | wc -l | tr -d ' ' || echo 0)
if [[ "$CURR_ERRORS" -lt "$PREV_ERRORS" ]]; then STATUS="PROGRESS"
elif [[ "$CURR_ERRORS" -eq "$PREV_ERRORS" && "$NEW_CATS" -eq 0 ]]; then STATUS="STALL"
elif [[ "$DELTA" -gt 0 || "$NEW_CATS" -gt 0 ]]; then STATUS="REGRESS"
else STATUS="STALL"; fi
echo "{\"status\":\"$STATUS\",\"prev_errors\":$PREV_ERRORS,\"curr_errors\":$CURR_ERRORS,\"changed_lines\":$CHANGED,\"failing_tests_delta\":$DELTA}"
