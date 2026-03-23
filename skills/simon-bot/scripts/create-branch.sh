#!/usr/bin/env bash
set -euo pipefail

# Pre-Phase 브랜치 생성 스크립트
# git fetch 없이 브랜치를 생성하는 것을 구조적으로 방지한다.
# Usage: create-branch.sh <branch-name> [base-branch] [use-worktree]

BRANCH_NAME="${1:?Usage: create-branch.sh <branch-name> [base-branch] [use-worktree]}"
BASE_BRANCH="${2:-main}"
USE_WORKTREE="${3:-true}"

# 1. Remote sync (필수 — set -e로 실패 시 자동 중단)
echo "[Branch] Fetching origin/${BASE_BRANCH}..."
git fetch origin "${BASE_BRANCH}" || {
  echo "[ERROR] git fetch failed. Network issue?" >&2
  exit 1
}

# 2. Branch creation from origin (not local)
if [ "${USE_WORKTREE}" = "true" ]; then
  WORKTREE_PATH=".claude/worktrees/${BRANCH_NAME}"
  echo "[Branch] Creating worktree at ${WORKTREE_PATH} from origin/${BASE_BRANCH}..."
  git worktree add "${WORKTREE_PATH}" -b "${BRANCH_NAME}" "origin/${BASE_BRANCH}"
  echo "[Branch] Worktree created: ${WORKTREE_PATH}"
else
  echo "[Branch] Creating branch ${BRANCH_NAME} from origin/${BASE_BRANCH}..."
  git checkout -b "${BRANCH_NAME}" "origin/${BASE_BRANCH}"
fi

# 3. Record base commit
BASE_SHA=$(git rev-parse "origin/${BASE_BRANCH}")
echo "[Branch] Base commit: ${BASE_SHA}"
