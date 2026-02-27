#!/bin/bash
# simon-bot: Find potential dead code in changed files
# Usage: bash find-dead-code.sh [base-branch] [project-dir]

set -euo pipefail

BASE_BRANCH="${1:-main}"
PROJECT_DIR="${2:-.}"
cd "$PROJECT_DIR"

echo "=== simon-bot: Dead Code Detection ==="

# Get changed files
if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
    if git rev-parse --verify "master" &>/dev/null; then
        BASE_BRANCH="master"
    else
        BASE_BRANCH="HEAD~1"
    fi
fi

CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || git diff --name-only "$BASE_BRANCH" HEAD)

if [ -z "$CHANGED_FILES" ]; then
    echo "No changed files found."
    exit 0
fi

echo "Scanning changed files for dead code patterns..."
echo ""

for file in $CHANGED_FILES; do
    [ -f "$file" ] || continue

    echo "--- $file ---"

    # Check for commented-out code blocks
    if grep -n "^\s*//.*function\|^\s*//.*class\|^\s*//.*const\|^\s*//.*let\|^\s*//.*var\|^\s*#.*def \|^\s*#.*class " "$file" 2>/dev/null; then
        echo "  [WARN] Commented-out code detected"
    fi

    # Check for console.log / print statements (debug code)
    if grep -n "console\.log\|console\.debug\|print(\|debugger;" "$file" 2>/dev/null; then
        echo "  [WARN] Debug statements detected"
    fi

    # Check for TODO/FIXME that might indicate incomplete removal
    if grep -n "TODO.*remove\|FIXME.*remove\|TODO.*delete\|FIXME.*delete" "$file" 2>/dev/null; then
        echo "  [WARN] TODO remove/delete markers found"
    fi

    echo ""
done

# Check for unused imports (TypeScript/JavaScript)
if echo "$CHANGED_FILES" | grep -qE "\.(ts|tsx|js|jsx)$"; then
    echo "--- Unused Import Check (TS/JS) ---"
    for file in $(echo "$CHANGED_FILES" | grep -E "\.(ts|tsx|js|jsx)$"); do
        [ -f "$file" ] || continue
        # Simple heuristic: find imports and check if the imported name is used
        while IFS= read -r line; do
            imported=$(echo "$line" | grep -oP "import\s+\{?\s*\K[^}]+(?=\s*\}?\s*from)" | tr ',' '\n' | sed 's/\s//g' | sed 's/as.*//')
            for name in $imported; do
                [ -z "$name" ] && continue
                count=$(grep -c "\b$name\b" "$file" 2>/dev/null || echo "0")
                if [ "$count" -le 1 ]; then
                    echo "  [WARN] $file: '$name' imported but possibly unused"
                fi
            done
        done < <(grep "^import" "$file" 2>/dev/null)
    done
fi

echo ""
echo "=== Dead Code Detection: COMPLETE ==="
