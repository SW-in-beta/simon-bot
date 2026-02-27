#!/bin/bash
# simon-bot: Extract changed files and diff for review
# Usage: bash extract-diff.sh [base-branch] [project-dir]
# Output: List of changed files and their diffs

set -euo pipefail

BASE_BRANCH="${1:-main}"
PROJECT_DIR="${2:-.}"
cd "$PROJECT_DIR"

echo "=== simon-bot: Change Extraction ==="
echo "Base branch: $BASE_BRANCH"
echo ""

# Try main, then master
if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
    if git rev-parse --verify "master" &>/dev/null; then
        BASE_BRANCH="master"
    else
        echo "[WARN] Neither main nor master branch found. Using HEAD~1"
        BASE_BRANCH="HEAD~1"
    fi
fi

echo "--- Changed Files ---"
git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || git diff --name-only "$BASE_BRANCH" HEAD
echo ""

echo "--- File Stats ---"
git diff --stat "$BASE_BRANCH"...HEAD 2>/dev/null || git diff --stat "$BASE_BRANCH" HEAD
echo ""

echo "--- Full Diff ---"
git diff "$BASE_BRANCH"...HEAD 2>/dev/null || git diff "$BASE_BRANCH" HEAD

echo ""
echo "=== Change Extraction: COMPLETE ==="
