#!/usr/bin/env bash
# budget-tracker.sh — failure-log.md에서 재시도 횟수를 집계하여 잔여 예산 출력
# Usage: budget-tracker.sh <failure-log-path> [total-budget]
# Output: JSON {"used": N, "total": N, "remaining": N, "percent_used": N, "warning": bool}
set -euo pipefail
FAILURE_LOG="${1:?Usage: budget-tracker.sh <failure-log-path> [total-budget]}"
TOTAL="${2:-50}"
if [[ ! -f "$FAILURE_LOG" ]]; then echo "{\"used\":0,\"total\":$TOTAL,\"remaining\":$TOTAL,\"percent_used\":0,\"warning\":false}"; exit 0; fi
USED=$(grep -c "^## Attempt" "$FAILURE_LOG" 2>/dev/null || echo 0)
REMAINING=$((TOTAL - USED))
if [[ $REMAINING -lt 0 ]]; then REMAINING=0; fi
PERCENT=$((USED * 100 / TOTAL))
WARNING=false
if [[ $PERCENT -ge 70 ]]; then WARNING=true; fi
echo "{\"used\":$USED,\"total\":$TOTAL,\"remaining\":$REMAINING,\"percent_used\":$PERCENT,\"warning\":$WARNING}"
