#!/usr/bin/env bash
# classify-error.sh — 에러 출력을 키워드 기반으로 분류하여 JSON 반환
# 사용: some_command 2>&1 | classify-error.sh
# 출력: {"type": "ENV_INFRA|CODE_LOGIC|WORKFLOW_ERROR", "subtype": "...", "next_action": "..."}
# exit 0=분류 성공, 1=분류 불가(LLM 판단 필요)
set -euo pipefail

input=$(cat)

# ENV_INFRA 패턴 (우선순위 1 — 인프라가 안 되면 코드 수정도 의미 없음)
if echo "$input" | grep -qiE 'connection refused|Cannot connect to the Docker daemon|ECONNREFUSED|timeout exceeded|connect: connection refused'; then
  echo '{"type":"ENV_INFRA","subtype":"NETWORK_ERROR","next_action":"Retry with exponential backoff (max 3). If persistent, check network/service availability."}'
  exit 0
fi

if echo "$input" | grep -qiE 'command not found|not found in PATH|version mismatch|No such file or directory.*bin/'; then
  echo '{"type":"ENV_INFRA","subtype":"TOOL_UNAVAILABLE","next_action":"Install missing tool (asdf/brew/apt). Check .tool-versions or package.json for required version."}'
  exit 0
fi

if echo "$input" | grep -qiE 'no space left on device|OOMKilled|out of memory|Cannot allocate memory|disk quota exceeded'; then
  echo '{"type":"ENV_INFRA","subtype":"RESOURCE_LIMIT","next_action":"Clean resources (docker prune, cache clear). Reduce batch size if applicable."}'
  exit 0
fi

if echo "$input" | grep -iE 'permission denied|EACCES|Operation not permitted' | grep -qivE 'assert|expected.*but got'; then
  echo '{"type":"ENV_INFRA","subtype":"PERMISSION_ERROR","next_action":"Use accessible path or request user to grant permission."}'
  exit 0
fi

if echo "$input" | grep -qiE 'port already in use|address already in use|EADDRINUSE'; then
  echo '{"type":"ENV_INFRA","subtype":"NETWORK_ERROR","next_action":"Kill process on port or use alternative port."}'
  exit 0
fi

if echo "$input" | grep -qiE 'docker.*error|compose.*failed|unhealthy|Cannot connect to the Docker'; then
  echo '{"type":"ENV_INFRA","subtype":"TOOL_UNAVAILABLE","next_action":"Check Docker daemon status. Run docker compose up -d if needed."}'
  exit 0
fi

# WORKFLOW_ERROR 패턴 (우선순위 2)
if echo "$input" | grep -qiE 'gate check failed|calibration.*fail|gate.*not.*pass'; then
  echo '{"type":"WORKFLOW_ERROR","subtype":"GATE_FAILURE","next_action":"Re-run the failing step. Check gate-definitions.md for pass conditions."}'
  exit 0
fi

if echo "$input" | grep -qiE 'agent.*timeout|subagent.*timeout|maxTurns exceeded'; then
  echo '{"type":"WORKFLOW_ERROR","subtype":"AGENT_TIMEOUT","next_action":"Re-spawn agent with higher maxTurns. Or perform task directly."}'
  exit 0
fi

if echo "$input" | grep -qiE 'invalid state|state.*corrupt|workflow-state.*invalid|memory.*not found'; then
  echo '{"type":"WORKFLOW_ERROR","subtype":"STATE_CORRUPTION","next_action":"Reconstruct state from git log. Resume from last known good commit."}'
  exit 0
fi

# CODE_LOGIC 패턴 (우선순위 3)
if echo "$input" | grep -qiE 'compilation failed|type mismatch|cannot find module|does not exist.*import|undefined reference|cannot resolve'; then
  echo '{"type":"CODE_LOGIC","subtype":"BUILD_FAILURE","next_action":"Fix based on error message. Check imports and type definitions."}'
  exit 0
fi

if echo "$input" | grep -qiE 'FAIL|assert|expected.*but got|test.*failed|― FAIL'; then
  echo '{"type":"CODE_LOGIC","subtype":"TEST_FAILURE","next_action":"Analyze failing test. Fix implementation to match test expectation."}'
  exit 0
fi

if echo "$input" | grep -qiE 'lint.*error|eslint|golangci-lint|formatting.*error|gofmt'; then
  echo '{"type":"CODE_LOGIC","subtype":"LINT_VIOLATION","next_action":"Run auto-fix (gofmt, eslint --fix). Manual fix if auto-fix insufficient."}'
  exit 0
fi

if echo "$input" | grep -qiE 'TypeError|SyntaxError|ReferenceError|undefined is not|null pointer|panic:'; then
  echo '{"type":"CODE_LOGIC","subtype":"BUILD_FAILURE","next_action":"Fix runtime type error. Check null/undefined handling."}'
  exit 0
fi

if echo "$input" | grep -qiE 'design conflict|architecture.*violation|dependency.*direction'; then
  echo '{"type":"CODE_LOGIC","subtype":"DESIGN_CONFLICT","next_action":"Review plan-summary.md. Align implementation with architecture."}'
  exit 0
fi

# 분류 불가 — LLM 판단 필요
exit 1
