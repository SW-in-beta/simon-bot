#!/usr/bin/env bash
# done-when-eval.sh — plan-summary.md의 Mechanical Done-When Checks를 자동 평가한다.
#
# 사용법: done-when-eval.sh <plan-summary.md> <verify-commands.md> [unit-name]
#   프로젝트 루트(워크트리)에서 실행한다 — 검증 명령이 상대 경로를 사용하기 때문.
# 출력(JSON): {"mechanical":"PASS(2/2)","failed":[...],"skipped_manual":[...],"exit_loop":true}
#   exit_loop      : 실행 가능한 명령이 1개 이상이고 전부 통과하면 true → grind는 해당 Step 재시도를 조기 종료
#   skipped_manual : 명령으로 환원되지 않는 항목(예: "Code Changes 전부 구현 확인") — LLM이 별도 판단
#   Behavioral Checks는 이 스크립트의 범위가 아니다 (LLM 평가 유지).
set -u

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }
[ "${1:-}" = "--help" ] && usage

PLAN="${1:?plan-summary.md 경로 필요 (--help 참조)}"
VERIFY="${2:?verify-commands.md 경로 필요}"
UNIT="${3:-}"

[ -f "$PLAN" ] || { echo '{"error":"plan-summary not found","exit_loop":false}'; exit 1; }
[ -f "$VERIFY" ] || { echo '{"error":"verify-commands not found","exit_loop":false}'; exit 1; }

# verify-commands.md에서 키(Build/Test/...)의 첫 번째 백틱 명령 추출
lookup_cmd() {
  grep -m1 -E "^- *${1}:" "$VERIFY" | sed -n 's/[^`]*`\([^`]*\)`.*/\1/p'
}

# Mechanical Checks 섹션 추출 (unit 지정 시 해당 Unit 블록 내에서만)
extract_checks() {
  if [ -n "$UNIT" ]; then
    awk -v u="## Unit: ${UNIT}" '
      $0 == u {inunit=1; next}
      inunit && /^## /  {exit}
      inunit            {print}' "$PLAN"
  else
    cat "$PLAN"
  fi | awk '/^### Mechanical Checks/{m=1; next} m && (/^###/ || /^## /){m=0} m{print}'
}

PASS=0; TOTAL=0
FAILED="[]"; SKIPPED="[]"

append_json_arr() { # $1=현재 배열 $2=추가 항목(JSON)
  if [ "$1" = "[]" ]; then printf '[%s]' "$2"; else printf '%s,%s]' "${1%]}" "$2"; fi
}

CHECKS=$(extract_checks)

while IFS= read -r line; do
  case "$line" in
    "- ["*"]"*) ;;          # 체크 항목("- [ ]" / "- [x]")만 처리
    *) continue ;;
  esac

  CMD=""
  # 1) 항목 자체에 백틱 명령이 있으면 우선 사용 (공백 또는 / 포함 = 명령으로 간주)
  inline=$(printf '%s' "$line" | sed -n 's/[^`]*`\([^`]*\)`.*/\1/p')
  case "$inline" in
    *" "*|*/*) CMD="$inline" ;;
  esac
  # 2) verify-commands.md 키 참조 (영문 키 우선)
  if [ -z "$CMD" ]; then
    for key in Build Test Lint Typecheck Coverage All-in-one; do
      case "$line" in *"$key"*) CMD=$(lookup_cmd "$key"); break ;; esac
    done
  fi
  # 3) 한글 키워드 폴백
  if [ -z "$CMD" ]; then
    case "$line" in
      *빌드*)     CMD=$(lookup_cmd Build) ;;
      *커버리지*) CMD=$(lookup_cmd Coverage) ;;
      *테스트*)   CMD=$(lookup_cmd Test) ;;
      *린트*)     CMD=$(lookup_cmd Lint) ;;
      *타입*)     CMD=$(lookup_cmd Typecheck) ;;
    esac
  fi

  desc=$(printf '%s' "$line" | sed 's/^- \[.\] *//; s/\\/\\\\/g; s/"/\\"/g' | cut -c1-100)
  if [ -z "$CMD" ]; then
    SKIPPED=$(append_json_arr "$SKIPPED" "\"$desc\"")
    continue
  fi

  TOTAL=$((TOTAL+1))
  if out=$(eval "$CMD" 2>&1); then
    PASS=$((PASS+1))
  else
    tail=$(printf '%s' "$out" | tail -3 | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g' | cut -c1-200)
    cmd_esc=$(printf '%s' "$CMD" | sed 's/\\/\\\\/g; s/"/\\"/g')
    FAILED=$(append_json_arr "$FAILED" "{\"check\":\"$desc\",\"cmd\":\"$cmd_esc\",\"tail\":\"$tail\"}")
  fi
done <<EOF
$CHECKS
EOF

EXIT_LOOP=false
[ "$TOTAL" -gt 0 ] && [ "$PASS" -eq "$TOTAL" ] && EXIT_LOOP=true

printf '{"mechanical":"PASS(%d/%d)","failed":%s,"skipped_manual":%s,"exit_loop":%s}\n' \
  "$PASS" "$TOTAL" "$FAILED" "$SKIPPED" "$EXIT_LOOP"
