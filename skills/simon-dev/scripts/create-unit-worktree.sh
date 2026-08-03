#!/usr/bin/env bash
set -euo pipefail

# Pre-Phase Unit Fan-out 스크립트
# create-branch.sh와 달리 git fetch를 하지 않는다 — Unit 브랜치의 base는
# origin이 아니라 이미 base stability 검증을 통과한 로컬 feature 브랜치다.
# Usage: create-unit-worktree.sh <unit-name> <feature-branch> <feature-worktree-path>

UNIT_NAME="${1:?Usage: create-unit-worktree.sh <unit-name> <feature-branch> <feature-worktree-path>}"
FEATURE_BRANCH="${2:?Usage: create-unit-worktree.sh <unit-name> <feature-branch> <feature-worktree-path>}"
FEATURE_WORKTREE_PATH="${3:?Usage: create-unit-worktree.sh <unit-name> <feature-branch> <feature-worktree-path>}"

UNIT_BRANCH="${FEATURE_BRANCH}/unit-${UNIT_NAME}"
PARENT_DIR="$(dirname "${FEATURE_WORKTREE_PATH}")"
WORKTREE_BASENAME="$(basename "${FEATURE_WORKTREE_PATH}")"
UNIT_WORKTREE_PATH="${PARENT_DIR}/${WORKTREE_BASENAME}--unit-${UNIT_NAME}"

echo "[Unit Worktree] Creating ${UNIT_WORKTREE_PATH} from local branch ${FEATURE_BRANCH} (no fetch — already validated)..."
git -C "${FEATURE_WORKTREE_PATH}" worktree add "${UNIT_WORKTREE_PATH}" -b "${UNIT_BRANCH}" "${FEATURE_BRANCH}" || {
  echo "[ERROR] worktree add failed for unit-${UNIT_NAME}." >&2
  exit 1
}

echo "[Unit Worktree] Copying read-only plan artifacts (.claude/memory)..."
mkdir -p "${UNIT_WORKTREE_PATH}/.claude/memory"
for f in plan-summary.md code-design-analysis.md verify-commands.md expert-plan-concerns.md; do
  if [ -f "${FEATURE_WORKTREE_PATH}/.claude/memory/${f}" ]; then
    cp "${FEATURE_WORKTREE_PATH}/.claude/memory/${f}" "${UNIT_WORKTREE_PATH}/.claude/memory/${f}"
  fi
done

echo "[Unit Worktree] Unit branch: ${UNIT_BRANCH}"
echo "${UNIT_WORKTREE_PATH}"
