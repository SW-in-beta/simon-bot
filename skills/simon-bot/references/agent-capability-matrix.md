# Agent Capability Matrix

에이전트 역할별 도구 범위, maxTurns, 출력 포맷을 정의한다. spawn prompt에 해당 행의 Tools Forbidden과 Output을 반드시 포함한다.

## Role × Permission Table

| Role | Tools Allowed | Tools Forbidden | maxTurns | Output |
|------|-------------|----------------|----------|--------|
| executor | All (Forbidden Rules + Auto-Verify 적용) | — | 50/100/200 (경로별) | 코드 + ground-truth.md |
| alignment-checker | Read, Glob, Grep | Edit, Write, Bash(변경성) | 30 | verdict-table.md |
| verifier | Read, Glob, Grep | Edit, Write, Bash(변경성) | 30 | verification-result.md |
| expert team member | Read, Glob, Grep | Edit, Write, Bash(변경성) | 20 | Findings Schema (`expert-output-schema.md`) |
| planner/architect | Read, Glob, Grep, AskUserQuestion | Edit, Write | 30 | plan-summary.md |
| devil-advocate | Read, Glob, Grep | Edit, Write, Bash(변경성) | 20 | devil-advocate-findings.md |
| security-reviewer | Read, Glob, Grep | Edit, Write, Bash(변경성) | 30 | security-findings.md |
| production-readiness-auditor | Read, Glob, Grep, Bash(읽기 전용) | Edit, Write | 30 | final-check.md |
| explore | Read, Glob, Grep | Edit, Write, Agent | 20 | 탐색 결과 |

**maxTurns by 경로:**
- SMALL: executor 50, 검증 20
- STANDARD: executor 100, 검증 30
- LARGE: executor 200, 검증 30

maxTurns 초과 시 에이전트가 자동 종료된다. 오케스트레이터는 종료 사유를 사용자에게 보고하고, 필요 시 더 높은 maxTurns로 재시도할지 결정한다.

## Spawn Prompt Template

모든 subagent spawn 시 프롬프트 **첫 블록**에 다음을 포함한다:

```
## ROLE_IDENTITY
- You are: {role_name} ({한줄 목적})
- Tools ALLOWED: [{허용 목록}]
- Tools FORBIDDEN: [{금지 목록}] — 금지 도구 사용 시 결과를 무효화한다
- Output: {출력 파일 경로} in {포맷}
- Scope: {탐색/수정 가능 파일 범위}
- Done: {완료 조건}을 충족하면 오케스트레이터에게 보고하고 종료
```

이 블록은 compaction 후에도 역할 정체성을 유지한다. Tools FORBIDDEN을 명시적으로 포함하여 역할 이탈을 구조적으로 방지한다.

## Subagent 반환 Status Prefix

subagent가 결과를 반환할 때 다음 prefix를 사용한다:

- `DONE: {결과 요약}` — 정상 완료
- `PARTIAL: {완료 항목} / {미완료 항목과 사유}` — 부분 완료 (maxTurns 소진 등)
- `ERROR: [{TYPE}/{SUBTYPE}] {에러 요약}` — error-resilience.md의 분류와 통합

오케스트레이터는 이 prefix로 후속 분기를 결정한다.
