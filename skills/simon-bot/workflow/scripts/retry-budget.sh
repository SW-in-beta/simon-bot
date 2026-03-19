#!/usr/bin/env bash
# retry-budget.sh — failure-log.jsonl 항목 수를 카운트하여 예산 상태 보고
# 사용: retry-budget.sh <failure-log.jsonl 경로> [total_budget]
# 출력: {"consumed": N, "remaining": N, "total": N, "pct": N}
# exit 0=정상, 1=70% 도달(경고), 2=100% 소진(중단)
set -euo pipefail

LOG_FILE="${1:?Usage: retry-budget.sh <failure-log.jsonl> [total_budget]}"
TOTAL="${2:-50}"

if [ ! -f "$LOG_FILE" ]; then
  echo "{\"consumed\": 0, \"remaining\": $TOTAL, \"total\": $TOTAL, \"pct\": 0}"
  exit 0
fi

CONSUMED=$(wc -l < "$LOG_FILE" | tr -d ' ')
REMAINING=$((TOTAL - CONSUMED))
if [ "$REMAINING" -lt 0 ]; then
  REMAINING=0
fi

if [ "$TOTAL" -gt 0 ]; then
  PCT=$((CONSUMED * 100 / TOTAL))
else
  PCT=100
fi

echo "{\"consumed\": $CONSUMED, \"remaining\": $REMAINING, \"total\": $TOTAL, \"pct\": $PCT}"

if [ "$PCT" -ge 100 ]; then
  exit 2
elif [ "$PCT" -ge 70 ]; then
  exit 1
else
  exit 0
fi
