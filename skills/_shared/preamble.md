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

## Agent Teams & Sub-agent Selection

이 워크플로는 Agent Teams와 Sub-agents를 목적에 따라 구분하여 사용한다:

- **Agent Teams**: 서로 다른 관점의 에이전트가 공유 목표를 향해 토론하여 합의를 도출할 때 — 각 팀원이 다른 팀원의 의견을 보고 반응하는 것이 결과 품질을 높이는 경우.
- **Sub-agents**: 독립적인 분석/검증이 수렴하여 신뢰도를 높일 때 — 각 에이전트가 다른 에이전트의 결론을 모르는 것이 결과 품질을 높이는 경우 (Monte Carlo 원리).

Agent Teams 사용에는 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 환경변수가 필요하다. TeamCreate 실패 시 subagent 기반 fallback으로 자동 전환한다.
상세 프로토콜(선택 기준, 생명주기, Fallback)은 `~/.claude/skills/simon-bot/references/agent-teams.md`를 참조한다.

## Cognitive Independence

검증 에이전트가 진정한 독립성을 유지하려면 구조적 분리(별도 subagent)만으로 부족하다 — 인지적 독립(Blind-First, Adversarial Default, Fresh Subagent, What-not-Why Handoff)이 필요하다.
상세 프로토콜은 `~/.claude/skills/simon-bot/references/context-separation.md`를 참조한다.

## Cross-Model Verification

Claude 단독 검증의 한계를 보완하기 위해 Codex(OpenAI)를 교차검증 레이어로 활용한다. 서로 다른 학습 데이터와 추론 방식을 가진 모델이 독립적으로 같은 결론에 도달하면, 단일 모델의 반복 검증보다 구조적으로 더 높은 신뢰도를 제공한다 (Monte Carlo 원리의 cross-model 확장). 중요도 기반 트리거로 CRITICAL/HIGH findings, 전체 리뷰(Step 12, simon-bot-review), 보안 변경 등에 적용된다.
상세 프로토콜은 `~/.claude/skills/_shared/cross-model-verification.md`를 참조한다.

## Agent Prompt Structure

subagent 또는 Agent Team 멤버에게 역할을 전달할 때 XML 태그로 구조화한다. 자연어 혼합 전달은 compaction 시 역할/맥락/지시가 섞여 손실될 수 있기 때문이다.

**표준 구조:**
```
<role>
시니어 보안 엔지니어. OWASP Top 10 관점에서 코드를 분석한다.
</role>

<context>
- 프로젝트: {project_name}
- 대상 파일: {file_list}
- 이전 단계 결과: {prior_findings_summary}
</context>

<instructions>
1. {file_list}의 모든 파일을 읽고 보안 취약점을 분석한다.
2. findings를 expert-output-schema.md 형식으로 {output_path}에 저장한다.
3. CRITICAL/HIGH 발견 시 즉시 보고한다.
</instructions>
```

**태그 설명:**
- `<role>`: 에이전트의 정체성과 전문성 (WHO)
- `<context>`: 작업에 필요한 배경 정보 — 파일 목록, 이전 결과, 제약 조건 (WHAT)
- `<instructions>`: 구체적 수행 단계와 완료 조건 (HOW)

핵심 지시는 `<instructions>` 시작 부분에 배치한다 — 긴 `<context>` 뒤에 핵심이 오면 compaction 시 손실 위험이 있다.

## "Boil the Lake" 완전성 원칙

AI 토큰 비용은 사실상 0이므로, 항상 완전한 구현을 해야 한다. TODO, partial implementation, "follow-up PR에서 처리" 등 모든 형태의 지름길을 금지한다. plan/spec의 AC에 포함된 모든 항목은 현재 작업에서 완료한다. "나중에 하겠다"는 인간의 시간 제약 전략이지, AI에게는 해당하지 않는다.

상세 anti-patterns는 `~/.claude/skills/simon-bot/references/phase-b-implementation.md`의 "Boil the Lake" 섹션을 참조한다.

## Inter-Agent Communication Gotchas

multi-agent 워크플로에서 반복적으로 발생하는 실패 패턴이다. 모든 subagent spawn 시 이 패턴을 인지한다:

- **maxTurns 소진**: subagent가 작업을 완료하지 못하고 종료될 수 있다. 오케스트레이터는 반환된 결과의 완전성을 검증한다 — 기대한 출력 파일이 존재하는지, 내용이 비어있지 않은지 확인한다.
- **Scope 이탈**: subagent 프롬프트에 수정 가능 파일 목록을 명시한다. "관련 파일을 수정해라"보다 "X, Y, Z 파일만 수정 가능"이 범위 이탈을 방지한다.
- **병렬 파일 충돌**: 병렬 subagent가 같은 파일을 수정할 가능성이 있으면, 병렬 대신 순차 실행한다. git worktree로 격리한 뒤 병합 시 충돌을 감지하는 것도 대안이다.
- **프롬프트 핵심 지시 소실**: subagent 프롬프트는 핵심 지시를 앞부분에 배치한다. 긴 컨텍스트 뒤에 핵심 지시를 넣으면 압축 시 손실될 수 있다.
