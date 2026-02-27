#!/bin/bash
# simon-bot: Run type checking
# Usage: bash typecheck.sh [project-dir]

set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "=== simon-bot: Type Check ==="

if [ -f "tsconfig.json" ]; then
    echo "[TypeScript] Running tsc --noEmit..."
    npx tsc --noEmit 2>&1
elif [ -f "pyproject.toml" ] && grep -q "mypy" pyproject.toml 2>/dev/null; then
    echo "[Python/mypy] Running mypy..."
    mypy . 2>&1
elif [ -f "mypy.ini" ] || [ -f ".mypy.ini" ]; then
    echo "[Python/mypy] Running mypy..."
    mypy . 2>&1
elif [ -f "go.mod" ]; then
    echo "[Go] Running go vet..."
    go vet ./... 2>&1
elif [ -f "Cargo.toml" ]; then
    echo "[Rust] Running cargo check..."
    cargo check 2>&1
else
    echo "[SKIP] No type checker detected."
    exit 0
fi

echo "=== Type Check: PASS ==="
