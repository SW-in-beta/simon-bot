#!/bin/bash
# simon-bot installer
# Usage:
#   ./install.sh              # Full install (global skill + project workflow)
#   ./install.sh --global     # Global skill only
#   ./install.sh --project-only  # Project workflow files only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
MODE="${1:-full}"

echo "=== simon-bot Installer ==="
echo ""

# ============================================
# Global Skill Installation
# ============================================
install_global() {
    echo "[1/2] Installing global skill..."

    # Create skills directory if not exists
    mkdir -p "$SKILLS_DIR"

    # Copy skill file (or symlink for dev)
    if [ -L "$SKILLS_DIR/simon-bot.md" ]; then
        rm "$SKILLS_DIR/simon-bot.md"
    fi

    cp "$SCRIPT_DIR/skills/simon-bot.md" "$SKILLS_DIR/simon-bot.md"
    echo "  Skill installed: $SKILLS_DIR/simon-bot.md"
    echo ""
}

# ============================================
# Project Workflow Installation
# ============================================
install_project() {
    echo "[2/2] Installing project workflow files..."

    # Find project root (git root or current dir)
    if git rev-parse --show-toplevel &>/dev/null; then
        PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    else
        PROJECT_ROOT="$(pwd)"
    fi

    WORKFLOW_DIR="$PROJECT_ROOT/.omc/workflow"
    MEMORY_DIR="$PROJECT_ROOT/.omc/memory"
    REPORTS_DIR="$PROJECT_ROOT/.omc/reports"

    # Create directories
    mkdir -p "$WORKFLOW_DIR/prompts"
    mkdir -p "$WORKFLOW_DIR/scripts"
    mkdir -p "$WORKFLOW_DIR/templates"
    mkdir -p "$MEMORY_DIR"
    mkdir -p "$REPORTS_DIR"

    # Copy config (only if not exists, to preserve user modifications)
    if [ ! -f "$WORKFLOW_DIR/config.yaml" ]; then
        cp "$SCRIPT_DIR/workflow/config.yaml" "$WORKFLOW_DIR/config.yaml"
        echo "  Config: $WORKFLOW_DIR/config.yaml"
    else
        echo "  Config: SKIPPED (already exists, preserving user modifications)"
    fi

    # Copy prompts (only if not exists)
    for prompt in "$SCRIPT_DIR/workflow/prompts/"*.md; do
        filename=$(basename "$prompt")
        if [ ! -f "$WORKFLOW_DIR/prompts/$filename" ]; then
            cp "$prompt" "$WORKFLOW_DIR/prompts/$filename"
            echo "  Prompt: $filename"
        else
            echo "  Prompt: $filename SKIPPED (already exists)"
        fi
    done

    # Copy scripts (always overwrite - these are deterministic)
    for script in "$SCRIPT_DIR/workflow/scripts/"*.sh; do
        filename=$(basename "$script")
        cp "$script" "$WORKFLOW_DIR/scripts/$filename"
        chmod +x "$WORKFLOW_DIR/scripts/$filename"
        echo "  Script: $filename"
    done

    # Copy templates (only if not exists)
    for template in "$SCRIPT_DIR/workflow/templates/"*.md; do
        filename=$(basename "$template")
        if [ ! -f "$WORKFLOW_DIR/templates/$filename" ]; then
            cp "$template" "$WORKFLOW_DIR/templates/$filename"
            echo "  Template: $filename"
        else
            echo "  Template: $filename SKIPPED (already exists)"
        fi
    done

    # Initialize memory files
    if [ ! -f "$MEMORY_DIR/retrospective.md" ]; then
        echo "# simon-bot Retrospective Log" > "$MEMORY_DIR/retrospective.md"
        echo "" >> "$MEMORY_DIR/retrospective.md"
        echo "Feedback and workflow improvements are recorded here." >> "$MEMORY_DIR/retrospective.md"
        echo "This file is automatically referenced at the start of each run." >> "$MEMORY_DIR/retrospective.md"
    fi

    if [ ! -f "$MEMORY_DIR/unresolved-decisions.md" ]; then
        echo "# Unresolved Decisions" > "$MEMORY_DIR/unresolved-decisions.md"
        echo "" >> "$MEMORY_DIR/unresolved-decisions.md"
        echo "Decisions that were not fully resolved during implementation." >> "$MEMORY_DIR/unresolved-decisions.md"
    fi

    echo ""
    echo "  Project root: $PROJECT_ROOT"
}

# ============================================
# Run Installation
# ============================================
case "$MODE" in
    --global)
        install_global
        ;;
    --project-only)
        install_project
        ;;
    full|*)
        install_global
        install_project
        ;;
esac

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Usage:"
echo "  In Claude Code, type: /simon-bot"
echo "  Or say: \"simon-bot으로 구현해줘\""
echo ""
