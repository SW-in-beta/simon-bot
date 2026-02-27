#!/bin/bash
# simon-bot: Check file and function sizes in changed files
# Usage: bash check-sizes.sh [base-branch] [project-dir] [max-file-lines] [max-func-lines]

set -euo pipefail

BASE_BRANCH="${1:-main}"
PROJECT_DIR="${2:-.}"
MAX_FILE_LINES="${3:-300}"
MAX_FUNC_LINES="${4:-50}"
cd "$PROJECT_DIR"

echo "=== simon-bot: Size Check ==="
echo "Thresholds: file=${MAX_FILE_LINES} lines, function=${MAX_FUNC_LINES} lines"
echo ""

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

OVERSIZED_FILES=0
OVERSIZED_FUNCS=0

echo "--- File Size Check ---"
for file in $CHANGED_FILES; do
    [ -f "$file" ] || continue
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -gt "$MAX_FILE_LINES" ]; then
        echo "  [WARN] $file: $lines lines (exceeds $MAX_FILE_LINES)"
        OVERSIZED_FILES=$((OVERSIZED_FILES + 1))
    fi
done

if [ "$OVERSIZED_FILES" -eq 0 ]; then
    echo "  All files within size limit."
fi

echo ""
echo "--- Function Size Check ---"

for file in $(echo "$CHANGED_FILES" | grep -E "\.(ts|tsx|js|jsx|py|go|rs|java)$"); do
    [ -f "$file" ] || continue

    # Simple function detection and line counting
    case "$file" in
        *.ts|*.tsx|*.js|*.jsx)
            # Match function/method declarations and count lines to closing brace
            grep -n "function \|=> {$\|async \|^\s*\w\+(.*).*{$" "$file" 2>/dev/null | while IFS=: read -r line_num content; do
                # Count lines until matching closing brace (simple heuristic)
                remaining=$(tail -n +"$line_num" "$file" | head -n "$((MAX_FUNC_LINES + 10))" | wc -l | tr -d ' ')
                if [ "$remaining" -gt "$MAX_FUNC_LINES" ]; then
                    func_name=$(echo "$content" | grep -oP "(function\s+\K\w+|\w+(?=\s*[=(]))" | head -1)
                    echo "  [WARN] $file:$line_num ${func_name:-anonymous}: potentially > $MAX_FUNC_LINES lines"
                    OVERSIZED_FUNCS=$((OVERSIZED_FUNCS + 1))
                fi
            done
            ;;
        *.py)
            grep -n "^\s*def \|^\s*async def " "$file" 2>/dev/null | while IFS=: read -r line_num content; do
                func_name=$(echo "$content" | grep -oP "(def\s+\K\w+)")
                echo "  [INFO] $file:$line_num $func_name (manual review recommended)"
            done
            ;;
    esac
done

if [ "$OVERSIZED_FUNCS" -eq 0 ]; then
    echo "  No obviously oversized functions detected."
fi

echo ""
echo "--- Summary ---"
echo "Oversized files: $OVERSIZED_FILES"
echo "Potentially oversized functions: $OVERSIZED_FUNCS"
echo ""
echo "=== Size Check: COMPLETE ==="
