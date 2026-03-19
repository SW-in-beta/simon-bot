# Improvement Proposals for simon-bot Skills

## 제안 날짜: 2026-03-13

---

## Executive Summary

12개 simon-bot 패밀리 스킬을 10개 이상의 최신 소스(Anthropic 공식 문서, Context Engineering 블로그, TDD 사례, 커뮤니티 가이드)와 교차 분석한 결과, **10개의 구체적 개선 제안**을 도출했다. 핵심 테마는 3가지다:

1. **Advisory → Deterministic 전환**: 텍스트 지시에 의존하는 핵심 불변식을 hooks/frontmatter로 전환
2. **컨텍스트 효율 최적화**: Description 축소, Compaction 지시, Dynamic Injection 활용
3. **최신 플랫폼 기능 채택**: `context: fork`, `allowed-tools`, skill-scoped hooks, `$ARGUMENTS` 활용

---

## Proposals

### [P-001] Auto-Verification Hook을 frontmatter hooks로 승격

- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: SKILL.md (Auto-Verification Hook 섹션)
- **카테고리**: 품질/안전 — Deterministic 제어 강화

**현재 상태**:
Auto-Verification Hook(P-001)은 "권장사항"으로 기술되어 있고, `.claude/settings.json`에 수동 등록을 안내한다. SKILL.md 자체에서 "컨텍스트 압축 시 규칙이 소실되어 게이트가 무력화될 수 있다"고 위험을 인식하면서도, 해결책인 hooks 등록을 "Hook 기반 강화 (권장사항)"으로만 두고 있다.

**문제 시나리오**:
긴 세션에서 컨텍스트 압축이 발생하면, LLM이 "모든 소스코드 파일 수정 후 빌드/린트 명령을 즉시 실행"이라는 지시를 잊고, 빌드 깨진 상태로 다음 Step에 진입할 수 있다.

**제안 내용**:
스킬 frontmatter에 `hooks` 필드를 추가하여 스킬 라이프사이클 수준의 결정론적 검증을 보장한다. 스킬이 활성화되면 hooks가 자동으로 등록된다.

```yaml
# simon-bot/SKILL.md frontmatter에 추가
hooks:
  PostToolUse:
    - type: command
      command: "${CLAUDE_SKILL_DIR}/workflow/scripts/auto-verify.sh"
      trigger:
        tool_name: [Edit, Write]
```

SKILL.md 본문의 "Hook 기반 강화 (권장사항)" 섹션을 "Auto-Verification Hook은 frontmatter hooks로 결정론적으로 실행된다"로 변경한다.

**기대 효과**:
- 컨텍스트 압축과 무관하게 100% 실행 보장
- 수동 settings.json 등록 불필요 (스킬 활성화 시 자동)
- SKILL.md가 자체 인식한 위험("게이트 무력화")을 구조적으로 해소

**근거**: Anthropic 공식 — "Hooks are deterministic and guarantee the action happens. CLAUDE.md instructions are advisory."

**주의사항**: `${CLAUDE_SKILL_DIR}` 변수가 실제로 스킬 hooks에서 지원되는지 확인 필요. 지원하지 않으면 절대 경로 사용.

---

### [P-002] Compaction 보존 지시문 추가

- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: SKILL.md (Context Window Management 섹션)
- **카테고리**: 컨텍스트 관리

**현재 상태**:
Context Window Management 섹션에서 "자동 압축(compact)되므로 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다"만 언급. 어떤 정보를 보존해야 하는지에 대한 지시가 없다.

**문제 시나리오**:
컨텍스트 압축 시 현재 진행 중인 Step 번호, 미해결 CRITICAL 이슈, Decision Journal의 최근 결정 등이 소실되어 작업이 혼란에 빠질 수 있다.

**제안 내용**:
Context Window Management 섹션에 압축 보존 지시문을 추가한다:

```markdown
### Compaction 보존 항목

컨텍스트 압축 시 다음 정보를 반드시 보존한다:
- 현재 Phase/Step 번호와 상태
- 미해결 CRITICAL/HIGH 이슈 목록
- Decision Journal의 최근 5개 결정
- 변경된 파일 목록과 검증 명령어
- Plan의 Unit 목록과 의존성 그래프
- 현재 SESSION_DIR 경로

이 목록은 CLAUDE.md의 압축 지시와 동일한 효과를 가진다:
"When compacting, always preserve: current step, unresolved issues, recent decisions, modified files, test commands, and session directory."
```

**기대 효과**:
- 압축 후에도 작업 연속성 보장
- `.claude/memory/` 파일로 복원 가능하지만, 재읽기 없이도 핵심 정보를 유지
- 세션 분할 빈도 감소

**근거**: Anthropic 공식 — "Customize compaction behavior in CLAUDE.md with instructions like 'When compacting, always preserve the full list of modified files and any test commands'"

---

### [P-003] Description 3인칭 통일 & 예산 최적화

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-boost, simon-bot-auto-boost, simon-bot-grind, simon-bot-pm, simon-bot-report, simon-bot-review, simon-bot-sessions, simon-bot-boost-capture, simon-bot-boost-review
- **대상 파일**: 각 SKILL.md frontmatter description
- **카테고리**: 스킬 형식/구조

**현재 상태**:
대부분의 description이 2인칭("이 스킬을 사용하세요", "코드 변경이 수반되는 모든 중대한 작업에 이 스킬을 사용하세요")을 사용한다. 또한 description이 매우 길어(200-300자+) 총 description budget을 많이 소비한다.

**제안 내용**:

Before (simon-bot):
```yaml
description: "19-step 딥 워크플로 — 계획, 구현, 검증을 최고 수준의 엄격함으로 수행합니다. Use when: (1) 새 기능/피처 구현 (\"피처 구현해줘\", \"새 기능 만들어줘\", \"코드 작성해줘\"), (2) 전문가 리뷰 패널이 필요한 체계적 계획 수립, (3) git worktree 기반 병렬 실행, (4) PR 전 종합 코드 검증이 필요할 때. 코드 변경이 수반되는 모든 중대한 작업에 이 스킬을 사용하세요."
```

After (simon-bot):
```yaml
description: "19-step 딥 워크플로로 계획, 구현, 검증을 수행한다. Use when: 새 기능 구현, 체계적 계획 수립, git worktree 병렬 실행, PR 전 종합 코드 검증. Not: 단순 수정, 분석만 필요한 경우."
```

핵심 변경:
1. 3인칭/비인칭으로 통일 ("수행한다", "수행합니다" 대신 "수행한다")
2. 중복 표현 제거 ("피처 구현해줘", "새 기능 만들어줘", "코드 작성해줘"는 하나로)
3. "Not:" 절 추가로 경계 명확화
4. "이 스킬을 사용하세요" 같은 2인칭 지시 제거

**기대 효과**:
- Anthropic 공식 가이드라인 준수 (3인칭)
- Description budget 절약 (~30-40% 단축 추정)
- 인접 스킬 간 경계 명확화 (Not: 절)

**근거**: Anthropic 공식 — "Always write in third person. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems."

---

### [P-004] simon-bot-report에 `context: fork` + `allowed-tools` 적용

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot-report
- **대상 파일**: SKILL.md frontmatter
- **카테고리**: 신기법 도입

**현재 상태**:
simon-bot-report는 읽기 전용 분석 스킬로, Global Rules에서 "코드를 수정하지 않는다"를 명시하고, "전문가 에이전트 spawn 시 도구 범위를 Read/Glob/Grep으로 제한한다 (P-011)"라고 텍스트로 지시한다.

**문제 시나리오**:
텍스트 지시만으로는 LLM이 실수로 Edit/Write 도구를 사용할 수 있다. 특히 컨텍스트가 길어진 후반부에서.

**제안 내용**:

```yaml
# simon-bot-report/SKILL.md frontmatter
---
name: simon-bot-report
description: "코드베이스를 전문가팀 토론 구조로 분석하여 RFC, 현황 분석서, 커스텀 양식의 문서를 생성한다. Use when: RFC 작성, 기존 시스템 현황 분석, 기술 조사, 커스텀 기술 문서 작성. Not: 코드 변경이 필요한 경우."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
allowed-tools: Read, Grep, Glob, Bash(gh *), WebFetch
---
```

**주의사항**: `allowed-tools`가 스킬 전체에 적용되므로, Step 4-B에서 writer가 파일을 Write해야 하는 부분과 충돌할 수 있다. 보고서 파일을 `.claude/reports/`에 쓰는 것은 필요하므로, `allowed-tools`에 `Write`를 포함하되 특정 경로만 허용하는 것이 이상적이나, 현재 Claude Code에서 경로 기반 tool 제한을 지원하는지 확인이 필요하다.

**대안**: `allowed-tools` 대신 PreToolUse hook으로 `.claude/reports/` 외 경로에 대한 Write를 차단하는 방식이 더 정밀하다.

**기대 효과**:
- 읽기 전용 제약의 결정론적 보장
- 실수로 인한 코드 수정 방지
- "코드를 수정하지 않는다" 규칙의 구조적 강제

**근거**: Anthropic 공식 — "`allowed-tools` field to limit which tools Claude can use when a skill is active"

---

### [P-005] TDD Phase Gate 강화

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: references/phase-b-implementation.md (Step 5 TDD 섹션)
- **카테고리**: 워크플로 구조

**현재 상태**:
Step 5에서 "RED → GREEN → REFACTOR → VERIFY" TDD 사이클을 명시하지만, 단일 executor subagent가 모든 phase를 실행한다. Phase 간 gate 검증이 텍스트 지시에 의존한다.

**제안 내용**:

Phase Gate를 bash 기반 결정론적 검증으로 강화한다:

```markdown
### TDD Phase Gate (결정론적 검증)

**RED Phase Gate**: 테스트 실행 결과가 FAIL인지 bash로 확인한다.
```bash
# 테스트 실행 후 exit code 확인
test_result=$(.claude/workflow/scripts/run-tests.sh --target {test_file} 2>&1)
if [ $? -eq 0 ]; then
  echo "GATE FAIL: 테스트가 이미 통과함 — RED phase에서 실패하는 테스트가 필요"
  exit 1
fi
echo "GATE PASS: 테스트 실패 확인 → GREEN phase 진입 가능"
```

**GREEN Phase Gate**: 테스트 실행 결과가 PASS인지 확인한다.

이 gate는 LLM 판단이 아닌 코드 실행으로 확인하므로, 컨텍스트 압축과 무관하게 TDD 규율이 유지된다.
```

완전한 subagent 분리(3개 독립 agent)까지는 가지 않되, 결정론적 phase gate로 TDD 규율을 강화한다. 이는 현재 워크플로 복잡성을 크게 늘리지 않으면서도 핵심 이점을 확보한다.

**기대 효과**:
- "테스트가 이미 통과하는 상태에서 GREEN phase 진입" 방지
- TDD 규율의 결정론적 보장
- Deterministic Gate Principle과 일관된 접근

**근거**: alexop.dev — "TDD 강제를 행동적 권장이 아닌 아키텍처 문제로 취급"

---

### [P-006] `${CLAUDE_SKILL_DIR}` & `${CLAUDE_SESSION_ID}` 활용

- **심각도**: LOW
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: SKILL.md (Startup, 스크립트 경로 참조)
- **카테고리**: 신기법 도입

**현재 상태**:
스킬 내에서 스크립트 경로를 하드코딩한다: `~/.claude/skills/simon-bot/workflow/scripts/preflight.sh`, `~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh` 등.

**제안 내용**:

`${CLAUDE_SKILL_DIR}`을 활용하여 경로를 상대적으로 참조한다:

Before:
```markdown
`.claude/workflow/scripts/preflight.sh` 실행 (없으면 skip)
```

After:
```markdown
`${CLAUDE_SKILL_DIR}/workflow/scripts/preflight.sh` 실행 (없으면 skip)
```

`${CLAUDE_SESSION_ID}`를 세션 디렉토리 생성에 활용 가능:

```markdown
SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${CLAUDE_SESSION_ID}"
```

**기대 효과**:
- 스킬 디렉토리 이동 시에도 스크립트 참조가 깨지지 않음
- 세션 ID의 고유성 보장 (현재는 브랜치명 기반이라 충돌 가능)

**근거**: Anthropic 공식 — "Use `${CLAUDE_SKILL_DIR}` in bash injection commands to reference scripts or files bundled with the skill, regardless of the current working directory."

**주의사항**: `${CLAUDE_SESSION_ID}`로 세션 디렉토리를 만들면 현재 브랜치명 기반 디렉토리 구조와 호환성 문제가 생길 수 있다. 기존 세션 복원 로직을 고려해야 한다.

---

### [P-007] 스킬 트리거 경계 명확화 (simon-bot vs simon-bot-grind)

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: SKILL.md frontmatter description
- **카테고리**: DX (Developer Experience)

**현재 상태**:
- simon-bot: "Use when: 새 기능/피처 구현, 전문가 리뷰 패널, git worktree 병렬 실행, PR 전 종합 코드 검증"
- simon-bot-grind: "Use when: 반드시 성공해야 하는 고위험 피처, 빌드/테스트 실패 잦은 복잡 코드베이스, 사람 개입 최소화"

**문제 시나리오**:
"피처 구현해줘"라는 요청에 두 스킬 모두 트리거 가능. simon-bot-grind의 "Use when" 조건 중 "반드시 성공해야 하는"은 대부분의 피처에 해당한다고 해석될 수 있다.

**제안 내용**:

simon-bot description에 명시적 경계 추가:
```
Not: 빌드/테스트 반복 실패가 예상되는 복잡한 작업 (→ simon-bot-grind 사용).
```

simon-bot-grind description에 역방향 경계 추가:
```
Not: 표준적인 기능 구현 (→ simon-bot 사용). 반복 실패가 예상되거나 사용자가 명시적으로 '끝까지' '포기하지 마' 등을 언급할 때만.
```

**기대 효과**:
- 트리거 모호성 해소
- 사용자 의도에 따른 정확한 스킬 선택
- 불필요한 grind 오버헤드 방지

**근거**: Anthropic 공식 Skill Best Practices — "인접 스킬 경계 구분"

---

### [P-008] Dynamic Context Injection으로 Startup 경량화

- **심각도**: LOW
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Startup 섹션)
- **카테고리**: 컨텍스트 관리

**현재 상태**:
Startup에서 여러 파일(config.yaml, retrospective.md, project-memory.json, handoff-manifest.json)을 순차적으로 Read한다. 각 Read가 컨텍스트를 소비한다.

**제안 내용**:

`!`command`` 구문으로 Startup 시 핵심 컨텍스트를 사전 주입한다:

```yaml
---
name: simon-bot
description: "..."
---

## Current Project Context
- Config: !`cat .claude/workflow/config.yaml 2>/dev/null || echo "No config"`
- Last retrospective: !`head -20 .claude/memory/retrospective.md 2>/dev/null || echo "None"`
- Handoff manifest: !`cat .claude/memory/handoff-manifest.json 2>/dev/null || echo "None"`
```

**주의사항**:
- `!`command``는 스킬 로딩 시점에 1회 실행되므로, 세션 중 변경된 파일은 반영되지 않는다.
- `.claude/memory/` 경로가 Session Isolation Protocol에 의해 `{SESSION_DIR}/memory/`로 매핑되는데, `!`command``가 이 매핑을 인식하는지 확인 필요.
- 조건부 분기(Handoff Manifest 존재 여부 등)가 복잡하여 단순 대체가 어려울 수 있다.

**기대 효과**:
- Read 도구 호출 감소 → 컨텍스트 효율 향상
- Startup 토큰 소비 절약

**근거**: Anthropic 공식 — "The `!`command`` syntax runs shell commands before the skill content is sent to Claude."

---

### [P-009] Evaluation Framework 도입

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot-boost, simon-bot-auto-boost
- **대상 파일**: 새 파일 (references/eval-framework.md 또는 기존 스킬에 섹션 추가)
- **카테고리**: 품질/안전

**현재 상태**:
simon-bot-auto-boost의 Step 5-3에 "스모크 테스트"가 있지만, 구조화된 eval 프레임워크가 없다. 스킬 변경이 실제 사용 시나리오에서 효과적인지 체계적으로 측정하지 않는다.

**제안 내용**:

스킬 변경 후 실행하는 eval 시나리오 세트를 정의한다:

```markdown
### Evaluation Scenarios

각 대상 스킬에 대해 최소 3개의 대표 시나리오를 정의하고, 변경 전/후 비교한다.

**simon-bot eval 시나리오 예시:**
1. 간단한 버그 수정 요청 → SMALL path 정상 동작 확인
2. 새 API 엔드포인트 추가 요청 → STANDARD path + 전문가 패널 동작 확인
3. 세션 중단 후 재개 → 상태 복원 + 작업 연속성 확인

**측정 항목:**
- 스킬 트리거 정확도 (의도한 스킬이 활성화되는지)
- 첫 Step 정상 진입 여부
- Reference 파일 로딩 지시 실행 여부
- Gate 검증 실행 여부
```

**기대 효과**:
- 스킬 변경의 회귀(regression) 감지
- "잘 동작했는데 변경 후 깨졌다" 상황 방지
- 객관적 품질 측정 기반

**근거**: Anthropic 공식 — "Create evaluations BEFORE writing extensive documentation. This ensures your Skill solves real problems rather than documenting imagined ones."

---

### [P-010] Reference 파일 TOC 체계화

- **심각도**: LOW
- **대상 스킬**: simon-bot
- **대상 파일**: references/ 내 300줄 초과 파일들
- **카테고리**: 스킬 형식/구조

**현재 상태**:
simon-bot의 reference 파일들(phase-a-planning.md, phase-b-implementation.md 등)의 길이와 TOC 존재 여부를 확인하지 못했지만, 복잡한 워크플로 특성상 300줄을 초과할 가능성이 높다.

**제안 내용**:

300줄 초과하는 모든 reference 파일에 TOC를 추가한다:

```markdown
# Phase B: Implementation

## Contents
- Step 5: Implementation (TDD)
- Step 6: Purpose Alignment
- Step 7: Bug/Security/Performance Review
- Step 8: Regression Verification
- Step 9-16: STANDARD+ Steps
- Step 17: Production Readiness

## Step 5: Implementation (TDD)
...
```

**기대 효과**:
- Claude가 부분 읽기(`head -100`) 시에도 전체 범위 파악 가능
- 필요한 섹션만 정확히 탐색
- 불필요한 전체 파일 로딩 방지

**근거**: Anthropic 공식 Skill Best Practices — "For reference files longer than 100 lines, include a table of contents at the top."

---

## Not Recommended (채택하지 않은 아이디어)

### NR-1: TDD 3-Agent 완전 분리
alexop.dev의 3개 독립 subagent(Test Writer, Implementer, Refactorer) 패턴은 이론적으로 우수하지만, simon-bot의 이미 복잡한 19-step pipeline에 추가하면 복잡성이 과도해진다. P-005의 결정론적 Phase Gate로 핵심 이점을 확보하면서 복잡성 증가를 최소화하는 것이 더 적절하다.

### NR-2: `context: fork`로 simon-bot 전체 실행
simon-bot은 다단계 인터랙티브 워크플로로, 사용자와의 지속적 대화가 필요하다. `context: fork`는 격리된 1회성 실행에 적합하므로, 메인 워크플로에는 부적합하다.

### NR-3: Gerund naming convention 전환
Anthropic이 gerund form (processing-pdfs 등)을 권장하지만, simon-bot 패밀리는 이미 `simon-bot-*` 네이밍이 확립되어 있고 사용자에게 익숙하다. 네이밍 변경은 기존 사용 패턴을 깨뜨리고 이점이 미미하다.

### NR-4: `disable-model-invocation: true` 적용
simon-bot은 사용자가 직접 호출할 수도, Claude가 자동으로 트리거할 수도 있어야 한다. 자동 트리거를 비활성화하면 DX가 저하된다.

### NR-5: Description을 영어로 전환
Anthropic 공식 예시는 영어지만, simon-bot의 사용자 기반과 CLAUDE.md 글로벌 설정(language: ko)을 고려하면 한국어 description이 더 적절하다. 트리거링이 시맨틱 매칭 기반이므로, 한국어 키워드가 한국어 요청과 더 잘 매칭될 수 있다.

---

## Priority Summary

| 우선순위 | 제안 | 심각도 | 변경 범위 | 예상 효과 |
|---------|------|--------|----------|----------|
| 1 | P-001: Auto-Verify Hook 승격 | HIGH | simon-bot, grind frontmatter | 핵심 불변식의 구조적 보장 |
| 2 | P-002: Compaction 보존 지시문 | HIGH | simon-bot, grind, pm SKILL.md | 긴 세션 안정성 대폭 향상 |
| 3 | P-003: Description 최적화 | MEDIUM | 전체 스킬 frontmatter | 트리거 정확도 + 예산 효율 |
| 4 | P-005: TDD Phase Gate | MEDIUM | phase-b-implementation.md | TDD 규율 결정론적 보장 |
| 5 | P-007: 트리거 경계 명확화 | MEDIUM | simon-bot, grind description | 사용자 경험 향상 |
| 6 | P-009: Eval Framework | MEDIUM | boost, auto-boost | 변경 품질 측정 기반 |
| 7 | P-004: Report allowed-tools | MEDIUM | simon-bot-report frontmatter | 읽기 전용 보장 |
| 8 | P-010: Reference TOC | LOW | references/ 파일들 | 부분 읽기 효율 |
| 9 | P-006: CLAUDE_SKILL_DIR 활용 | LOW | SKILL.md 경로 참조 | 이식성 향상 |
| 10 | P-008: Dynamic Injection | LOW | SKILL.md Startup | 컨텍스트 절약 (제한적) |

---

## Sources

- [Best Practices for Claude Code - Official Docs](https://code.claude.com/docs/en/best-practices)
- [Skill authoring best practices - Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Effective context engineering for AI agents - Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Forcing Claude Code to TDD - alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)
- [The Complete Guide to Agentic Coding in 2026](https://www.teamday.ai/blog/complete-guide-agentic-coding-2026)
- [7 Claude Code best practices for 2026](https://www.eesel.ai/blog/claude-code-best-practices)
- [Claude Code Agent Teams Guide](https://claudefa.st/blog/guide/agents/agent-teams)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
