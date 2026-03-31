#!/usr/bin/env bash
# simon-bot Session Manager
# Usage: bash manage-sessions.sh <command> [args]
#
# Commands:
#   list                  - 작업 현황 (git log + 워크트리 + 브랜치 + 상태 파일)
#   search <keyword>      - 키워드로 세션 검색
#   info <branch-name>    - 특정 세션/브랜치 상세 정보
#   delete <branch-name>  - 세션 삭제 (워크트리 + 브랜치)

set -euo pipefail

COMMAND="${1:-help}"
BRANCH="${2:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

case "$COMMAND" in
  list)
    echo -e "${CYAN}=== 작업 현황 ===${NC}"
    echo ""

    # 1. Current branch + recent commits
    # Compute sessions directory
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$GIT_ROOT" ]; then
      PROJECT_SLUG=$(echo "$GIT_ROOT" | tr '/' '-')
      SESSIONS_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions"
    else
      SESSIONS_DIR=""
    fi

    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    echo -e "${GREEN}## 현재 브랜치: ${CURRENT_BRANCH}${NC}"
    echo ""
    echo "최근 커밋:"
    git log --oneline -15 2>/dev/null || echo "  (커밋 없음)"
    echo ""

    # Uncommitted changes
    MODIFIED_COUNT=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MODIFIED_COUNT" -gt 0 ]; then
      echo -e "${YELLOW}미커밋 변경: ${MODIFIED_COUNT} files${NC}"
      git status --short 2>/dev/null
    else
      echo "미커밋 변경: 없음"
    fi
    echo ""

    # 2. Active worktrees (skip main)
    echo -e "${GREEN}## 워크트리 세션${NC}"
    WT_COUNT=0
    FIRST=1
    while IFS= read -r line; do
      WT_PATH=$(echo "$line" | awk '{print $1}')
      WT_BRANCH=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')

      # Skip main worktree (first entry)
      if [ "$FIRST" -eq 1 ]; then
        FIRST=0
        continue
      fi

      WT_COUNT=$((WT_COUNT + 1))
      LAST_COMMIT=$(git -C "$WT_PATH" log -1 --format="%h %s (%cr)" 2>/dev/null || echo "N/A")
      HAS_MEMORY="No"
      [ -d "$WT_PATH/.claude/memory" ] && HAS_MEMORY="Yes"

      DESC=""
      if [ -n "$SESSIONS_DIR" ] && [ -f "${SESSIONS_DIR}/${WT_BRANCH}/memory/CONTEXT.md" ]; then
        DESC=$(head -1 "${SESSIONS_DIR}/${WT_BRANCH}/memory/CONTEXT.md" | sed 's/^#* *//')
      elif [ -f "$WT_PATH/.claude/memory/CONTEXT.md" ]; then
        DESC=$(head -1 "$WT_PATH/.claude/memory/CONTEXT.md" | sed 's/^#* *//')
      fi

      echo "  [${WT_COUNT}] ${WT_BRANCH}"
      [ -n "$DESC" ] && echo "      Desc: $DESC"
      echo "      Path: $WT_PATH"
      echo "      Last: $LAST_COMMIT"
      echo "      Memory: $HAS_MEMORY"
      echo ""
    done < <(git worktree list 2>/dev/null)

    if [ "$WT_COUNT" -eq 0 ]; then
      echo "  (없음)"
    fi
    echo ""

    # 3. Local branches (not main/master, not current)
    echo -e "${GREEN}## 피처 브랜치${NC}"
    BR_COUNT=0
    while IFS= read -r branch; do
      branch=$(echo "$branch" | xargs)
      [ -z "$branch" ] && continue
      [ "$branch" = "main" ] && continue
      [ "$branch" = "master" ] && continue
      [ "$branch" = "$CURRENT_BRANCH" ] && continue

      BR_COUNT=$((BR_COUNT + 1))
      LAST_COMMIT=$(git log -1 --format="%h %s (%cr)" "$branch" 2>/dev/null || echo "N/A")
      echo "  [${BR_COUNT}] ${branch}"
      echo "      Last: $LAST_COMMIT"
    done < <(git branch --format='%(refname:short)' 2>/dev/null)

    if [ "$BR_COUNT" -eq 0 ]; then
      echo "  (없음)"
    fi
    echo ""

    # 4. Project state files
    echo -e "${GREEN}## 프로젝트 상태 파일${NC}"
    if [ -d ".claude/memory" ]; then
      MEM_COUNT=$(find .claude/memory -maxdepth 1 \( -name '*.md' -o -name '*.json' \) 2>/dev/null | wc -l | tr -d ' ')
      echo "  .claude/memory/: ${MEM_COUNT} files"
      if [ -f ".claude/memory/session-meta.json" ]; then
        echo "    session-meta.json: 존재"
      fi
    else
      echo "  .claude/memory/: (없음)"
    fi
    if [ -f ".claude/company/state.json" ]; then
      echo "  .claude/company/state.json: 존재"
    fi
    echo ""
    ;;

  info)
    if [ -z "$BRANCH" ]; then
      echo -e "${RED}Error: 브랜치명을 입력하세요.${NC}"
      echo "Usage: bash manage-sessions.sh info <branch-name>"
      exit 1
    fi

    # Find worktree by branch name (if exists)
    WT_PATH=""
    while IFS= read -r line; do
      if echo "$line" | grep -q "\[$BRANCH\]"; then
        WT_PATH=$(echo "$line" | awk '{print $1}')
        break
      fi
    done < <(git worktree list 2>/dev/null)

    # Check if branch exists (even without worktree)
    BRANCH_EXISTS=$(git branch --list "$BRANCH" 2>/dev/null | wc -l | tr -d ' ')
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

    if [ -z "$WT_PATH" ] && [ "$BRANCH_EXISTS" -eq 0 ] && [ "$BRANCH" != "$CURRENT_BRANCH" ]; then
      echo -e "${RED}Error: '$BRANCH' 브랜치를 찾을 수 없습니다.${NC}"
      echo ""
      echo "사용 가능한 브랜치:"
      git branch --format='  %(refname:short)' 2>/dev/null
      exit 1
    fi

    echo -e "${CYAN}=== Session Info: $BRANCH ===${NC}"
    echo ""

    if [ "$BRANCH" = "$CURRENT_BRANCH" ]; then
      echo -e "${GREEN}Type:${NC} 현재 브랜치"
      WT_PATH=""  # main worktree는 별도 워크트리가 아님
    elif [ -n "$WT_PATH" ]; then
      echo -e "${GREEN}Type:${NC} 워크트리 세션"
      echo -e "${GREEN}Path:${NC} $WT_PATH"
    else
      echo -e "${GREEN}Type:${NC} 로컬 브랜치"
    fi
    echo ""

    # Recent commits (use worktree path if available, otherwise branch ref)
    echo -e "${GREEN}Recent commits:${NC}"
    if [ -n "$WT_PATH" ]; then
      git -C "$WT_PATH" log -10 --format="  %h %s (%cr)" 2>/dev/null || echo "  N/A"
    else
      git log -10 --format="  %h %s (%cr)" "$BRANCH" 2>/dev/null || echo "  N/A"
    fi
    echo ""

    # Changed files in last commit
    if [ -n "$WT_PATH" ]; then
      DIFF_COUNT=$(git -C "$WT_PATH" diff --name-only HEAD~1 2>/dev/null | wc -l | tr -d ' ')
    else
      DIFF_COUNT=$(git diff --name-only "${BRANCH}~1" "$BRANCH" 2>/dev/null | wc -l | tr -d ' ')
    fi
    echo -e "${GREEN}Changed files (last commit):${NC} $DIFF_COUNT"
    echo ""

    # Memory files (worktree or current directory)
    echo -e "${GREEN}Memory files:${NC}"
    CHECK_PATH="${WT_PATH:-.}"
    if [ -d "$CHECK_PATH/.claude/memory" ]; then
      find "$CHECK_PATH/.claude/memory" \( -name "*.md" -o -name "*.json" \) -type f 2>/dev/null | while read -r f; do
        REL_PATH="${f#$CHECK_PATH/}"
        SIZE=$(wc -l < "$f" | tr -d ' ')
        echo "  $REL_PATH ($SIZE lines)"
      done
    else
      echo "  (없음)"
    fi
    echo ""

    # Company state (current directory only)
    if [ -f ".claude/company/state.json" ]; then
      echo -e "${GREEN}Company state:${NC} 존재"
      echo ""
    fi

    # Git status (only for worktree or current branch)
    if [ -n "$WT_PATH" ]; then
      echo -e "${GREEN}Git status:${NC}"
      git -C "$WT_PATH" status --short 2>/dev/null || echo "  clean"
    elif [ "$BRANCH" = "$CURRENT_BRANCH" ]; then
      echo -e "${GREEN}Git status:${NC}"
      git status --short 2>/dev/null || echo "  clean"
    fi
    ;;

  delete)
    if [ -z "$BRANCH" ]; then
      echo -e "${RED}Error: 브랜치명을 입력하세요.${NC}"
      echo "Usage: bash manage-sessions.sh delete <branch-name>"
      exit 1
    fi

    # Find worktree by branch name
    WT_PATH=""
    while IFS= read -r line; do
      if echo "$line" | grep -q "\[$BRANCH\]"; then
        WT_PATH=$(echo "$line" | awk '{print $1}')
        break
      fi
    done < <(git worktree list 2>/dev/null)

    if [ -z "$WT_PATH" ]; then
      echo -e "${RED}Error: '$BRANCH' 브랜치의 워크트리를 찾을 수 없습니다.${NC}"
      exit 1
    fi

    echo -e "${YELLOW}삭제 대상:${NC}"
    echo "  Worktree: $WT_PATH"
    echo "  Branch:   $BRANCH"
    echo ""

    # Remove worktree
    echo -e "Worktree 제거 중..."
    git worktree remove "$WT_PATH" --force 2>/dev/null
    echo -e "${GREEN}Worktree 제거 완료${NC}"

    # Delete branch
    echo -e "Branch 삭제 중..."
    git branch -D "$BRANCH" 2>/dev/null || echo -e "${YELLOW}로컬 브랜치가 이미 없거나 삭제 실패${NC}"
    echo -e "${GREEN}Branch 삭제 완료${NC}"

    echo ""
    echo -e "${GREEN}세션 '$BRANCH' 삭제 완료.${NC}"
    ;;

  search)
    KEYWORD="$BRANCH"
    if [ -z "$KEYWORD" ]; then
      echo -e "${RED}Error: 검색 키워드를 입력하세요.${NC}"
      echo "Usage: bash manage-sessions.sh search <keyword>"
      exit 1
    fi

    echo -e "${CYAN}=== 세션 검색: '$KEYWORD' ===${NC}"
    echo ""

    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    if [ -n "$GIT_ROOT" ]; then
      PROJECT_SLUG=$(echo "$GIT_ROOT" | tr '/' '-')
      SESSIONS_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions"
    else
      SESSIONS_DIR=""
    fi

    FOUND=0

    # Search worktrees
    while IFS= read -r line; do
      WT_PATH=$(echo "$line" | awk '{print $1}')
      WT_BRANCH=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')
      [ -z "$WT_BRANCH" ] && continue

      MATCH=""
      echo "$WT_BRANCH" | grep -qi "$KEYWORD" && MATCH="branch"
      git -C "$WT_PATH" log -10 --format="%s" 2>/dev/null | grep -qi "$KEYWORD" && MATCH="${MATCH:+$MATCH, }commits"
      for CTX in "${SESSIONS_DIR}/${WT_BRANCH}/memory/CONTEXT.md" "$WT_PATH/.claude/memory/CONTEXT.md"; do
        [ -f "$CTX" ] && grep -qi "$KEYWORD" "$CTX" 2>/dev/null && MATCH="${MATCH:+$MATCH, }CONTEXT.md" && break
      done

      if [ -n "$MATCH" ]; then
        FOUND=$((FOUND + 1))
        LAST=$(git -C "$WT_PATH" log -1 --format="%h %s (%cr)" 2>/dev/null || echo "N/A")
        echo -e "  [${FOUND}] ${GREEN}${WT_BRANCH}${NC} (worktree)"
        echo "      Match: $MATCH"
        echo "      Last:  $LAST"
        echo ""
      fi
    done < <(git worktree list 2>/dev/null)

    # Search branches (skip those already found as worktrees)
    while IFS= read -r branch; do
      branch=$(echo "$branch" | xargs)
      [ -z "$branch" ] && continue
      git worktree list 2>/dev/null | grep -q "\[$branch\]" && continue

      MATCH=""
      echo "$branch" | grep -qi "$KEYWORD" && MATCH="branch"
      git log -10 --format="%s" "$branch" 2>/dev/null | grep -qi "$KEYWORD" && MATCH="${MATCH:+$MATCH, }commits"

      if [ -n "$MATCH" ]; then
        FOUND=$((FOUND + 1))
        LAST=$(git log -1 --format="%h %s (%cr)" "$branch" 2>/dev/null || echo "N/A")
        echo -e "  [${FOUND}] ${GREEN}${branch}${NC} (branch)"
        echo "      Match: $MATCH"
        echo "      Last:  $LAST"
        echo ""
      fi
    done < <(git branch --format='%(refname:short)' 2>/dev/null)

    # Search home sessions (archived)
    if [ -n "$SESSIONS_DIR" ] && [ -d "$SESSIONS_DIR" ]; then
      for session_dir in "$SESSIONS_DIR"/*/; do
        [ -d "$session_dir" ] || continue
        SN=$(basename "$session_dir")
        git worktree list 2>/dev/null | grep -q "\[$SN\]" && continue
        git branch --list "$SN" 2>/dev/null | grep -q . && continue

        MATCH=""
        echo "$SN" | grep -qi "$KEYWORD" && MATCH="session"
        CTX="${session_dir}memory/CONTEXT.md"
        [ -f "$CTX" ] && grep -qi "$KEYWORD" "$CTX" 2>/dev/null && MATCH="${MATCH:+$MATCH, }CONTEXT.md"

        if [ -n "$MATCH" ]; then
          FOUND=$((FOUND + 1))
          DESC=""
          [ -f "$CTX" ] && DESC=$(head -1 "$CTX" | sed 's/^#* *//')
          echo -e "  [${FOUND}] ${YELLOW}${SN}${NC} (archived)"
          echo "      Match: $MATCH"
          [ -n "$DESC" ] && echo "      Desc:  $DESC"
          echo ""
        fi
      done
    fi

    if [ "$FOUND" -eq 0 ]; then
      echo "  '$KEYWORD'와 일치하는 세션이 없습니다."
    else
      echo -e "${GREEN}총 ${FOUND}건${NC}"
    fi
    ;;

  help|*)
    echo "simon-bot Session Manager"
    echo ""
    echo "Usage: bash manage-sessions.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list                  작업 현황 (git log + 워크트리 + 브랜치 + 상태 파일)"
    echo "  search <keyword>     키워드로 세션 검색 (브랜치명, 커밋, CONTEXT.md)"
    echo "  info <branch-name>   특정 세션/브랜치 상세 정보"
    echo "  delete <branch-name> 세션 삭제 (워크트리 + 브랜치)"
    echo ""
    echo "Examples:"
    echo "  bash manage-sessions.sh list"
    echo "  bash manage-sessions.sh search auth"
    echo "  bash manage-sessions.sh info feat/add-auth"
    echo "  bash manage-sessions.sh info main"
    echo "  bash manage-sessions.sh delete feat/add-auth"
    ;;
esac
