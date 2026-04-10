#!/bin/bash
# simon installer
# Usage:
#   ./install.sh              # Full install (global skill + project workflow)
#   ./install.sh --global     # Global skill only
#   ./install.sh --project-only  # Project workflow files only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
MODE="${1:-full}"

echo "=== simon Installer ==="
echo ""

# ============================================
# Global Skill Installation
# ============================================
install_global() {
    echo "[1/2] Installing global skills..."

    # Helper: install a single skill directory
    # Usage: install_skill <skill-name>
    install_skill() {
        local skill_name="$1"
        local src_dir="$SCRIPT_DIR/skills/$skill_name"
        local dest_dir="$SKILLS_DIR/$skill_name"

        echo "  Installing $skill_name..."

        # Remove old flat-file skill if exists (migration)
        if [ -f "$SKILLS_DIR/${skill_name}.md" ]; then
            rm "$SKILLS_DIR/${skill_name}.md"
            echo "    Migrated: removed old ${skill_name}.md"
        fi

        # Create destination directory
        mkdir -p "$dest_dir"

        # Copy SKILL.md
        cp "$src_dir/SKILL.md" "$dest_dir/SKILL.md"
        echo "    SKILL.md installed"

        # Copy references/ subdirectory if it exists
        if [ -d "$src_dir/references" ]; then
            mkdir -p "$dest_dir/references"
            for f in "$src_dir/references/"*.md; do
                [ -f "$f" ] && cp "$f" "$dest_dir/references/"
            done
            echo "    references/ copied"
        fi

        # Copy templates/ subdirectory if it exists
        if [ -d "$src_dir/templates" ]; then
            mkdir -p "$dest_dir/templates"
            for f in "$src_dir/templates/"*.md; do
                [ -f "$f" ] && cp "$f" "$dest_dir/templates/"
            done
            echo "    templates/ copied"
        fi
    }

    # Install all skills
    install_skill "simon"
    install_skill "simon-auto-boost"
    install_skill "simon-boost"
    install_skill "simon-boost-capture"
    install_skill "simon-boost-review"
    install_skill "simon-ci-fix"
    install_skill "simon-grind"
    install_skill "simon-pm"
    install_skill "simon-report"
    install_skill "simon-code-review"
    install_skill "simon-sessions"
    install_skill "simon-company"
    install_skill "simon-presenter"
    install_skill "simon-web-search"

    echo ""

    # Copy install.sh to main skill dir (for project-only install from skill context)
    SKILL_DIR="$SKILLS_DIR/simon"
    cp "$SCRIPT_DIR/install.sh" "$SKILL_DIR/install.sh"
    chmod +x "$SKILL_DIR/install.sh"
    echo "  Installer: $SKILL_DIR/install.sh"

    # Copy workflow files (source for project-only install)
    mkdir -p "$SKILL_DIR/workflow/prompts"
    mkdir -p "$SKILL_DIR/workflow/scripts"
    mkdir -p "$SKILL_DIR/workflow/templates"

    cp "$SCRIPT_DIR/workflow/config.yaml" "$SKILL_DIR/workflow/config.yaml"

    for f in "$SCRIPT_DIR/workflow/prompts/"*.md; do
        [ -f "$f" ] && cp "$f" "$SKILL_DIR/workflow/prompts/"
    done
    for f in "$SCRIPT_DIR/workflow/scripts/"*.sh; do
        [ -f "$f" ] && cp "$f" "$SKILL_DIR/workflow/scripts/" && chmod +x "$SKILL_DIR/workflow/scripts/$(basename "$f")"
    done
    for f in "$SCRIPT_DIR/workflow/templates/"*.md; do
        [ -f "$f" ] && cp "$f" "$SKILL_DIR/workflow/templates/"
    done

    echo "  Workflow files copied to skill directory"

    # Install git pre-commit hook for secret scanning
    local hook_src="$SCRIPT_DIR/hooks/secret-scan.sh"
    if [ -f "$hook_src" ]; then
        # Install pre-commit hook to simon repo (if .git exists)
        if [ -d "$SCRIPT_DIR/.git/hooks" ]; then
            cat > "$SCRIPT_DIR/.git/hooks/pre-commit" << 'HOOK_EOF'
#!/bin/bash
HOOKS_DIR="$(git rev-parse --show-toplevel)/hooks"
if [[ -x "$HOOKS_DIR/secret-scan.sh" ]]; then
    "$HOOKS_DIR/secret-scan.sh"
else
    echo "Warning: secret-scan.sh not found at $HOOKS_DIR/secret-scan.sh" >&2
fi
HOOK_EOF
            chmod +x "$SCRIPT_DIR/.git/hooks/pre-commit"
            echo "  Pre-commit hook: installed (secret scanning)"
        fi
    fi

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
        echo "# simon Retrospective Log" > "$MEMORY_DIR/retrospective.md"
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
echo "  In Claude Code, type: /simon"
echo "  Or say: \"simon으로 구현해줘\""
echo ""
