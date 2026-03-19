# Shared Protocols (simon-bot 패밀리 공통)

이 파일은 simon-bot 패밀리 전체가 공유하는 Cross-Cutting Protocol을 정의한다.
각 스킬의 SKILL.md에서 `> **Shared Protocols**: ~/.claude/skills/_shared/preamble.md 읽기` 로 참조한다.

## Session Isolation Protocol

동시에 여러 세션이 같은 레포에서 작업할 때 런타임 파일의 충돌을 방지한다. 세션별 런타임 데이터를 홈 디렉토리에 격리 저장한다.

**SESSION_DIR 결정** (Startup 시 실행):
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
BRANCH=$(git branch --show-current)
SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${BRANCH}"
mkdir -p "${SESSION_DIR}/memory" "${SESSION_DIR}/reports"
```

모든 `.claude/memory/` 경로를 `{SESSION_DIR}/memory/`로, `.claude/reports/` 경로를 `{SESSION_DIR}/reports/`로 해석한다.
프로젝트의 `.claude/workflow/` (config, scripts)는 공유 설정이므로 프로젝트 디렉토리에서 그대로 읽는다.

## Error Resilience

모든 실패를 ENV_INFRA / CODE_LOGIC / WORKFLOW_ERROR로 분류한 후 자동 복구한다.
사용자가 명시적으로 중단을 요청하지 않는 한 워크플로를 중단하지 않는다.
상세 프로토콜은 `~/.claude/skills/simon-bot/references/error-resilience.md`를 참조한다.

## Forbidden Rules

되돌릴 수 없는 피해를 방지하기 위해 ABSOLUTE FORBIDDEN / CONTEXT-SENSITIVE / AUDIT-REQUIRED 3계층으로 분류된다.
hooks.PreToolUse에서 자동 차단된다. 차단 시 에러 메시지를 확인하고 안전한 대안을 탐색한다.
상세 규칙은 `~/.claude/skills/simon-bot/references/forbidden-rules.md`를 참조한다.

## Agent Teams

이 워크플로는 Agent Teams 기능을 우선 사용한다 (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필요).
TeamCreate 실패 시 subagent 기반 fallback으로 자동 전환한다.
상세 프로토콜은 `~/.claude/skills/simon-bot/references/agent-teams.md`를 참조한다.

## Cognitive Independence

검증 에이전트가 진정한 독립성을 유지하려면 구조적 분리(별도 subagent)만으로 부족하다 — 인지적 독립(Blind-First, Adversarial Default, Fresh Subagent, What-not-Why Handoff)이 필요하다.
상세 프로토콜은 `~/.claude/skills/simon-bot/references/context-separation.md`를 참조한다.

## Inter-Agent Communication Gotchas

multi-agent 워크플로에서 반복적으로 발생하는 실패 패턴이다. 모든 subagent spawn 시 이 패턴을 인지한다:

- **maxTurns 소진**: subagent가 작업을 완료하지 못하고 종료될 수 있다. 오케스트레이터는 반환된 결과의 완전성을 검증한다 — 기대한 출력 파일이 존재하는지, 내용이 비어있지 않은지 확인한다.
- **Scope 이탈**: subagent 프롬프트에 수정 가능 파일 목록을 명시한다. "관련 파일을 수정해라"보다 "X, Y, Z 파일만 수정 가능"이 범위 이탈을 방지한다.
- **병렬 파일 충돌**: 병렬 subagent가 같은 파일을 수정할 가능성이 있으면, 병렬 대신 순차 실행한다. git worktree로 격리한 뒤 병합 시 충돌을 감지하는 것도 대안이다.
- **프롬프트 핵심 지시 소실**: subagent 프롬프트는 핵심 지시를 앞부분에 배치한다. 긴 컨텍스트 뒤에 핵심 지시를 넣으면 압축 시 손실될 수 있다.
