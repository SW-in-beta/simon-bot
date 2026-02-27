#!/bin/bash
# simon-bot: Verify project builds successfully
# Usage: bash verify-build.sh [project-dir]

set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "=== simon-bot: Build Verification ==="

# Detect project type and run appropriate build
if [ -f "package.json" ]; then
    echo "[Node.js] Running build..."
    if grep -q '"build"' package.json; then
        npm run build 2>&1
    else
        echo "[SKIP] No build script found in package.json"
    fi
elif [ -f "Cargo.toml" ]; then
    echo "[Rust] Running cargo build..."
    cargo build 2>&1
elif [ -f "go.mod" ]; then
    echo "[Go] Running go build..."
    go build ./... 2>&1
elif [ -f "pom.xml" ]; then
    echo "[Java/Maven] Running mvn compile..."
    mvn compile -q 2>&1
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "[Java/Gradle] Running gradle build..."
    gradle build -x test 2>&1
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "[Python] Checking syntax..."
    python -m py_compile $(find . -name "*.py" -not -path "./venv/*" -not -path "./.venv/*" | head -50) 2>&1
else
    echo "[WARN] Unknown project type. Skipping build."
    exit 0
fi

echo "=== Build Verification: PASS ==="
