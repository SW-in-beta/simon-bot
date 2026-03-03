#!/bin/bash
# simon-bot: Check and set up test environment
# Usage: bash setup-test-env.sh [project-dir]
# Exit code 0 = ready (proceed with tests), 1 = setup failed (skip tests)

set -uo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "=== simon-bot: Test Environment Setup ==="

if [ -f "package.json" ]; then
    if [ -d "node_modules" ]; then
        echo "[Node.js] Test environment ready (node_modules exists)."
        exit 0
    else
        echo "[Node.js] node_modules missing. Running npm install..."
        if npm install 2>&1; then
            echo "[Node.js] Setup complete."
            exit 0
        else
            echo "[Node.js] npm install failed. Skipping tests."
            exit 1
        fi
    fi
elif [ -f "Cargo.toml" ]; then
    if command -v cargo &>/dev/null; then
        echo "[Rust] Test environment ready (cargo available)."
        exit 0
    else
        echo "[Rust] cargo not found. Cannot set up environment. Skipping tests."
        exit 1
    fi
elif [ -f "go.mod" ]; then
    if command -v go &>/dev/null; then
        echo "[Go] Test environment ready (go available)."
        if [ ! -f "go.sum" ]; then
            echo "[Go] go.sum missing. Running go mod download..."
            go mod download 2>&1
        fi
        exit 0
    else
        echo "[Go] go not found. Cannot set up environment. Skipping tests."
        exit 1
    fi
elif [ -f "pom.xml" ]; then
    if command -v mvn &>/dev/null; then
        if [ -d "$HOME/.m2/repository" ]; then
            echo "[Java/Maven] Test environment ready (mvn + .m2 cache exists)."
            exit 0
        else
            echo "[Java/Maven] Dependencies missing. Running mvn dependency:resolve..."
            if mvn dependency:resolve -q 2>&1; then
                echo "[Java/Maven] Setup complete."
                exit 0
            else
                echo "[Java/Maven] Dependency resolution failed. Skipping tests."
                exit 1
            fi
        fi
    else
        echo "[Java/Maven] mvn not found. Cannot set up environment. Skipping tests."
        exit 1
    fi
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    if command -v gradle &>/dev/null || [ -f "./gradlew" ]; then
        echo "[Java/Gradle] Test environment ready (gradle available)."
        exit 0
    else
        echo "[Java/Gradle] gradle not found. Cannot set up environment. Skipping tests."
        exit 1
    fi
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    if command -v pytest &>/dev/null || python -m pytest --version &>/dev/null 2>&1; then
        echo "[Python] Test environment ready (pytest available)."
        exit 0
    else
        echo "[Python] pytest not found. Installing dependencies..."
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt 2>&1 && echo "[Python] Setup complete." && exit 0
        elif [ -f "pyproject.toml" ]; then
            pip install -e ".[test]" 2>&1 || pip install -e ".[dev]" 2>&1 || pip install pytest 2>&1
            if command -v pytest &>/dev/null || python -m pytest --version &>/dev/null 2>&1; then
                echo "[Python] Setup complete."
                exit 0
            fi
        fi
        echo "[Python] Setup failed. Skipping tests."
        exit 1
    fi
else
    echo "[WARN] Unknown project type. Cannot set up test environment. Skipping tests."
    exit 1
fi
