#!/usr/bin/env bash
set -euo pipefail

# Integration Stage: N개 Unit 브랜치 + 흩어진 .claude/memory 산출물을
# feature 워크트리로 병합한다. feature 워크트리 안에서 실행해야 한다.
# Usage: merge-units.sh <unit-name-1> [unit-name-2] ...

if [ "$#" -eq 0 ]; then
  echo "[ERROR] No unit names provided. Usage: merge-units.sh <unit-name-1> [unit-name-2] ..." >&2
  exit 1
fi

FEATURE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
FEATURE_WORKTREE_PATH="$(git rev-parse --show-toplevel)"
PARENT_DIR="$(dirname "${FEATURE_WORKTREE_PATH}")"
WORKTREE_BASENAME="$(basename "${FEATURE_WORKTREE_PATH}")"

for UNIT in "$@"; do
  UNIT_BRANCH="${FEATURE_BRANCH}/unit-${UNIT}"
  UNIT_WORKTREE_PATH="${PARENT_DIR}/${WORKTREE_BASENAME}--unit-${UNIT}"

  echo "[Merge] unit-${UNIT}: merging branch ${UNIT_BRANCH} into ${FEATURE_BRANCH}..."
  if ! git merge --no-ff "${UNIT_BRANCH}" -m "merge: unit-${UNIT} 병합"; then
    echo "[CONFLICT] unit-${UNIT} 브랜치 병합 충돌 — architect 분석 필요 (integration-and-review.md Integration Stage 3번 항목 절차 적용)" >&2
    exit 2
  fi

  echo "[Merge] unit-${UNIT}: unit-namespaced 산출물 복사..."
  if [ -d "${UNIT_WORKTREE_PATH}/.claude/memory/unit-${UNIT}" ]; then
    mkdir -p "${FEATURE_WORKTREE_PATH}/.claude/memory/unit-${UNIT}"
    cp -R "${UNIT_WORKTREE_PATH}/.claude/memory/unit-${UNIT}/." "${FEATURE_WORKTREE_PATH}/.claude/memory/unit-${UNIT}/"
  fi

  echo "[Merge] unit-${UNIT}: 최상위 로그 파일(decision-journal 등) 병합..."
  for LOGFILE in decision-journal.md unresolved-decisions.md plan-amendments.md; do
    SRC="${UNIT_WORKTREE_PATH}/.claude/memory/${LOGFILE}"
    if [ -f "${SRC}" ]; then
      DEST="${FEATURE_WORKTREE_PATH}/.claude/memory/${LOGFILE}"
      {
        echo ""
        echo "## [unit-${UNIT}]"
        cat "${SRC}"
      } >> "${DEST}"
    fi
  done

  echo "[Merge] unit-${UNIT}: 워크트리 정리..."
  git worktree remove "${UNIT_WORKTREE_PATH}" --force 2>/dev/null || echo "[WARN] worktree remove 실패 — 수동 정리 필요: ${UNIT_WORKTREE_PATH}"
  git branch -d "${UNIT_BRANCH}" 2>/dev/null || true
done

echo "[Merge] 전체 Unit 병합 완료: $*"
