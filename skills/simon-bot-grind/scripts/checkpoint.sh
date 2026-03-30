#!/usr/bin/env bash
# checkpoint.sh — git tag checkpoint-step{N}-attempt{M} 생성 + checkpoints.md 갱신
# Usage: checkpoint.sh <step> <attempt> <checkpoints-md-path>
# Output: Created tag name
set -euo pipefail
STEP="${1:?Usage: checkpoint.sh <step> <attempt> <checkpoints-md-path>}"
ATTEMPT="${2:?}"
CHECKPOINTS_MD="${3:?}"
TAG="checkpoint-step${STEP}-attempt${ATTEMPT}"
git tag -f "$TAG" HEAD 2>/dev/null || { echo "ERROR: git tag failed"; exit 1; }
mkdir -p "$(dirname "$CHECKPOINTS_MD")"
echo "| $(date +%Y-%m-%dT%H:%M:%S) | $TAG | $(git rev-parse --short HEAD) | Step $STEP, Attempt $ATTEMPT |" >> "$CHECKPOINTS_MD"
echo "$TAG"
