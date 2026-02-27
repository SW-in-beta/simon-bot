#!/bin/bash
# simon-bot: Run project tests
# Usage: bash run-tests.sh [project-dir]

set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "=== simon-bot: Test Execution ==="

# Detect project type and run tests
if [ -f "package.json" ]; then
    echo "[Node.js] Running tests..."
    if grep -q '"test"' package.json; then
        npm test 2>&1
    else
        echo "[SKIP] No test script found in package.json"
    fi
elif [ -f "Cargo.toml" ]; then
    echo "[Rust] Running cargo test..."
    cargo test 2>&1
elif [ -f "go.mod" ]; then
    echo "[Go] Running go test..."
    go test ./... 2>&1
elif [ -f "pom.xml" ]; then
    echo "[Java/Maven] Running mvn test..."
    mvn test -q 2>&1
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "[Java/Gradle] Running gradle test..."
    gradle test 2>&1
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "[Python] Running pytest..."
    if command -v pytest &> /dev/null; then
        pytest 2>&1
    else
        python -m pytest 2>&1
    fi
else
    echo "[WARN] Unknown project type. Skipping tests."
    exit 0
fi

echo "=== Test Execution: COMPLETE ==="
