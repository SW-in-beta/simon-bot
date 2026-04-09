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

모든 subagent spawn 시 프롬프트 **첫 블록**에 XML 구조화 태그를 사용한다 (`_shared/preamble.md` "Agent Prompt Structure" 참조):

```
<role>
{role_name} — {한줄 목적}
Mode: DISCUSSION | VERIFICATION
- DISCUSSION: 다른 팀원의 findings를 읽고 반응한다. 합의를 목표로 한다.
- VERIFICATION: 이전 findings/결론을 참조하지 않는다. 독립 분석이 당신의 가치다.
Tools ALLOWED: [{허용 목록}]
Tools FORBIDDEN: [{금지 목록}] — 금지 도구 사용 시 결과를 무효화한다
</role>

<context>
- Project: {프로젝트명}
- Scope: {탐색/수정 가능 파일 범위}
- Current branch: {current_branch} — 현재 작업 기준. 코드베이스 탐색 시 이 브랜치 상태를 사용한다.
- Base branch: origin/{base_branch} — main/master 기준 조회(머지 여부, 최신 변경 등) 시 이 ref를 사용한다. git fetch는 Startup에서 완료됨.
- Prior findings: {이전 단계 결과 요약 또는 "없음"}
</context>

<instructions>
1. {구체적 수행 단계}
2. Output: {출력 파일 경로} in {포맷}
3. Done: {완료 조건}을 충족하면 오케스트레이터에게 보고하고 종료
</instructions>
```

XML 태그로 구조화하면 compaction 후에도 역할/맥락/지시가 분리되어 유지된다. `<instructions>` 시작 부분에 핵심 지시를 배치하여 손실을 방지한다.

## Subagent 반환 Status Prefix

subagent가 결과를 반환할 때 다음 prefix를 사용한다:

- `DONE: {결과 요약}` — 정상 완료
- `PARTIAL: {완료 항목} / {미완료 항목과 사유}` — 부분 완료 (maxTurns 소진 등)
- `ERROR: [{TYPE}/{SUBTYPE}] {에러 요약}` — error-resilience.md의 분류와 통합

오케스트레이터는 이 prefix로 후속 분기를 결정한다.

## Model Heterogeneity 가이드라인

> **공식 모델 정책**: 이 매핑은 simon 패밀리 전체(simon, simon-grind, simon-code-review, simon-report, simon-pm, simon-study, simon-oncall, simon-company 등)에 적용된다. 각 스킬에서 Agent/subagent를 spawn할 때 이 테이블의 역할별 권장 모델을 따른다. 개별 스킬에 명시적 `model:` 지정이 있으면 그것이 우선한다.

역할별로 최적의 모델을 선택한다. 모든 역할에 동일 모델을 사용하면 비용 대비 효과가 떨어진다 — 탐색은 빠른 모델이, 검증은 정확한 모델이 적합하다.

| 역할 | 권장 모델 | 근거 |
|------|----------|------|
| executor | sonnet | 코드 생성 + 도구 사용이 주 작업, 속도와 품질 균형 |
| verifier | opus | 미묘한 불일치/논리 오류 감지에 높은 추론 능력 필요 |
| alignment-checker | opus | AC 대비 구현 정합성 판단은 추론 집약적 |
| expert team member | sonnet | 도메인별 체크리스트 기반 분석, sonnet으로 충분 |
| devil-advocate | opus | 기존 findings의 반증 생성은 높은 추론 능력 필요 |
| explore | haiku | 파일 탐색/검색은 빠른 응답이 중요, 복잡한 추론 불필요 |
| planner/architect | sonnet | 계획 수립은 도구 사용 + 구조화가 중심 |
| security-reviewer | opus | 보안 취약점 감지에 높은 정밀도 필요 |
| production-readiness-auditor | opus | 최종 프로덕션 감사, 미묘한 이슈 감지 |
| writer | sonnet | 템플릿 기반 보고서/문서 생성, 구조화 중심 |
| fact-checker | sonnet | 공식 문서 조회 + 사실 대조, 도구 중심 작업 |
| spec-validator | sonnet | 기술 AC → 사용자 시나리오 변환, 기계적 변환 |
| ci-watch | sonnet | CI 폴링 + 에러 분류 + 코드 수정, 패턴 매칭 기반 |
| comment-watcher | sonnet | PR 댓글 폴링 + 분류, 기계적 폴링 |
| internal-researcher | sonnet | Confluence/Slack 검색 스크립트 실행 + 결과 요약, 도구 중심 |
| data-researcher | sonnet | 데이터 스킬 호출 + SQL 실행, 도구 중심 |

**Override 조건**: `config.yaml`의 `model_override` 설정이 있으면 위 기본값을 덮어쓴다. 비용 제한이 있으면 모든 역할을 sonnet으로 통일할 수 있다.
