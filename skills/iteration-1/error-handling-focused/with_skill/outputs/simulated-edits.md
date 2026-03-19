# Simulated Edits (실제 파일 미수정)

이 문서는 simon-bot-boost 스킬 테스트 실행에서, 실제 스킬 파일을 수정하는 대신 어떤 편집이 수행되었을지를 기록합니다.

## Edit 1: simon-bot/references/error-resilience.md — P-001 (Clean Context Retry)

**파일**: `~/.claude/skills/simon-bot/references/error-resilience.md`
**위치**: CODE_LOGIC 실패 처리 섹션(116행) 뒤, WORKFLOW_ERROR 실패 처리 섹션(118행) 앞

**추가할 내용**:
```markdown
### 컨텍스트 오염 방지 (Clean Context Retry)

동일 유형 실패가 연속 3회 발생하면, 다음 시도는 subagent를 spawn하여 격리된 컨텍스트에서 수행한다. subagent에게는 다음만 전달한다:
1. 원래 요구사항 (plan-summary.md 해당 부분)
2. 실패 로그 요약 — 전체 컨텍스트가 아닌 핵심 교훈만 (에러 유형, 실패 원인 1줄 요약)
3. "이전에 시도하여 실패한 접근법" 목록 (접근법 이름과 실패 이유만, 코드 자체는 제외)

실패한 코드 자체를 전달하지 않는 이유: 실패한 접근법의 상세 코드가 컨텍스트에 남아 있으면, 같은 방향의 변형만 시도하게 되어 근본적으로 다른 접근을 방해한다. 깨끗한 컨텍스트에서 교훈만 가지고 시작하면 더 창의적인 해결책을 찾을 확률이 높아진다.
```

**Edit 도구 사용 시 old_string/new_string**:
- old_string: `## WORKFLOW_ERROR 실패 처리`
- new_string:
```
### 컨텍스트 오염 방지 (Clean Context Retry)

동일 유형 실패가 연속 3회 발생하면, 다음 시도는 subagent를 spawn하여 격리된 컨텍스트에서 수행한다. subagent에게는 다음만 전달한다:
1. 원래 요구사항 (plan-summary.md 해당 부분)
2. 실패 로그 요약 — 전체 컨텍스트가 아닌 핵심 교훈만 (에러 유형, 실패 원인 1줄 요약)
3. "이전에 시도하여 실패한 접근법" 목록 (접근법 이름과 실패 이유만, 코드 자체는 제외)

실패한 코드 자체를 전달하지 않는 이유: 실패한 접근법의 상세 코드가 컨텍스트에 남아 있으면, 같은 방향의 변형만 시도하게 되어 근본적으로 다른 접근을 방해한다. 깨끗한 컨텍스트에서 교훈만 가지고 시작하면 더 창의적인 해결책을 찾을 확률이 높아진다.

## WORKFLOW_ERROR 실패 처리
```

---

## Edit 2: simon-bot/references/error-resilience.md — P-003 (근본 원인 해결 원칙)

**파일**: `~/.claude/skills/simon-bot/references/error-resilience.md`
**위치**: 공통 원칙 섹션, 131행 "에러를 무시하고 넘어가지 않는다" 뒤

**추가할 내용**:
```markdown
- 에러의 근본 원인을 해결한다 — 에러 메시지를 억제하거나(catch로 삼키기), assertion 기대값을 현재 출력으로 변경하거나, 로깅을 비활성화하는 수정은 하지 않는다. 이런 수정은 빌드를 통과시키지만 근본 원인을 남겨, 이후 더 큰 문제로 재발한다.
```

**Edit 도구 사용 시 old_string/new_string**:
- old_string:
```
- 에러를 무시하고 넘어가지 않는다 — 분석 후 수정을 시도한다
- 실패 유형을 분류한 후에 복구를 시작한다
```
- new_string:
```
- 에러를 무시하고 넘어가지 않는다 — 분석 후 수정을 시도한다
- 에러의 근본 원인을 해결한다 — 에러 메시지를 억제하거나(catch로 삼키기), assertion 기대값을 현재 출력으로 변경하거나, 로깅을 비활성화하는 수정은 하지 않는다. 이런 수정은 빌드를 통과시키지만 근본 원인을 남겨, 이후 더 큰 문제로 재발한다.
- 실패 유형을 분류한 후에 복구를 시작한다
```

---

## Edit 3: simon-bot-grind/references/grind-error-resilience.md — P-001 (Escalation Ladder Clean Context)

**파일**: `~/.claude/skills/simon-bot-grind/references/grind-error-resilience.md`
**위치**: Escalation Ladder 테이블, 108행 부근 (Attempt 4~6 행)

**변경할 내용**:

- old_string:
```
| 4 ~ 6 | **Root Cause Analysis**: spawn `architect` to diagnose WHY it keeps failing, then `executor` applies the deeper fix | 같은 실수가 반복되면 표면이 아닌 근본 원인을 찾아야 함 |
```
- new_string:
```
| 4 ~ 6 | **Root Cause Analysis (Clean Context)**: subagent를 spawn하여 격리된 컨텍스트에서 `architect`가 진단. 이전 실패의 교훈 요약과 실패한 접근법 목록만 전달하고, 실패한 코드 자체는 제외한다. 오염된 컨텍스트에서 벗어나 근본 원인을 새롭게 분석한다. | 같은 실수가 반복되면 표면이 아닌 근본 원인을 찾아야 하며, 이전 실패의 잔재가 분석을 왜곡하지 않도록 깨끗한 컨텍스트에서 시작한다 |
```

---

## Edit 4: simon-bot/SKILL.md — P-002 (Hook 기반 강화 권장 수준 상향)

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: 59행 부근, Hook 기반 강화 문단

**변경할 내용**:

- old_string:
```
**Hook 기반 강화 (선택사항)**: `.claude/workflow/scripts/auto-verify.sh`를 작성하고 settings.json의 `hooks.PostToolUse`에 등록하면 Edit/Write 후 셸 레벨에서 자동 실행되어 LLM 기억에 의존하지 않는 결정론적 검증이 가능하다.
```
- new_string:
```
**Hook 기반 강화 (권장)**: `.claude/workflow/scripts/auto-verify.sh`를 작성하고 settings.json의 `hooks.PostToolUse`에 등록하면 Edit/Write 후 셸 레벨에서 자동 실행된다. LLM 기억에 의존하는 검증은 컨텍스트 압축 시 누락될 수 있지만, hooks는 매번 결정론적으로 실행되어 검증 누락을 원천 차단한다. 프로젝트에 빌드/린트 명령이 있다면 우선적으로 설정하라.
```

---

## 변경 요약

| 파일 | Edit 수 | 제안 |
|------|---------|------|
| simon-bot/references/error-resilience.md | 2 | P-001, P-003 |
| simon-bot-grind/references/grind-error-resilience.md | 1 | P-001 |
| simon-bot/SKILL.md | 1 | P-002 |
| **합계** | **4** | **3제안** |
