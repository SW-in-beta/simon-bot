# Analysis: simon-bot Skills vs. Latest Best Practices

## 분석 날짜: 2026-03-13

---

## 1. 분석 방법론

10개 이상의 최신 소스(Anthropic 공식 문서, 엔지니어링 블로그, 커뮤니티 가이드, 실전 사례)를 수집하고, simon-bot 패밀리 12개 스킬과 교차 비교했다. 분석 축은 다음 6개다:

1. **스킬 구조 & Progressive Disclosure** — 공식 가이드라인 대비 현재 상태
2. **컨텍스트 관리** — Context Engineering 원칙 부합 여부
3. **결정론적 제어** — Hooks 활용 수준
4. **TDD & 검증 루프** — 최신 TDD 아키텍처 패턴 반영
5. **에이전트 패턴** — Subagent/Agent Teams 최적 활용
6. **DX(Developer Experience)** — 사용자 경험 품질

---

## 2. 현재 스킬 강점 (이미 Best Practice를 잘 따르고 있는 부분)

### 2-1. Progressive Disclosure 적극 활용
simon-bot SKILL.md는 Reference Loading Policy를 명시하여 Phase별로 필요한 레퍼런스만 로딩한다. 이것은 Anthropic 공식 문서의 "Just-in-Time Context Retrieval" 원칙과 정확히 일치한다.

### 2-2. Deterministic Gate Principle
빌드/린트/테스트 실행 같은 결정론적 검증을 bash 스크립트로 수행하고, LLM은 결과만 받아 판단하는 구조. Anthropic의 "Never send an LLM to do a linter's job" 원칙에 부합.

### 2-3. Stop-and-Fix Gate
실패 시 즉시 수정하는 강제 게이트. 공식 best practices의 "Address root causes, not symptoms"와 일치.

### 2-4. Error Resilience 체계
3계층 분류(ENV_INFRA/CODE_LOGIC/WORKFLOW_ERROR)와 자동 복구. simon-bot-grind의 10-attempt ladder는 업계 최고 수준.

### 2-5. Session Isolation Protocol
홈 디렉토리 기반 세션 격리로 워크트리 삭제 시에도 데이터 보존. 설계가 견고하다.

### 2-6. Cognitive Independence (Blind-First)
simon-bot-review의 Blind-First 2-Pass 리뷰는 구현자 anchoring을 방지하는 구조적 장치. 공식 문서의 "Fresh context improves code review" 원칙을 구조적으로 구현.

### 2-7. Anti-Oscillation Rule
Decision Journal에서 이전에 기각한 접근법을 새 정보 없이 재선택하는 것을 금지. 컨텍스트 낭비 방지에 매우 효과적.

---

## 3. 개선 기회 분석

### 3-1. SKILL.md 크기 & Description 형식

**현재 상태**: simon-bot/SKILL.md는 약 389줄로 500줄 제한 이내이지만, description이 매우 길고 1인칭/2인칭 표현을 사용한다.

**Best Practice 기준**:
- Anthropic 공식: "Description은 3인칭으로. 'I can help you' (X), 'You can use this' (X)"
- description 최대 1024자, trigger-rich하되 3인칭
- name 필드: 소문자+숫자+하이픈만 허용 (이미 준수)

**Gap**: simon-bot-boost의 description은 2인칭 혼용("이 스킬을 사용하세요"). simon-bot-auto-boost도 마찬가지. 공식 가이드와 불일치하지만, 실제 트리거링에 미치는 영향은 불확실하다.

### 3-2. Hooks 활용 부족

**현재 상태**: Auto-Verification Hook(P-001)을 "권장사항"으로 언급하고, 설정 가이드를 제공하지만, 실제로 스킬 frontmatter에 hooks를 정의하지 않는다.

**Best Practice 기준**:
- 공식 문서: "Hooks are deterministic and guarantee the action happens" vs "CLAUDE.md instructions are advisory"
- 스킬 frontmatter에 `hooks` 필드로 스킬 라이프사이클 hooks 정의 가능
- PostToolUse hook으로 매 편집 후 자동 검증이 결정론적으로 보장됨
- TDD 사례(alexop.dev)에서 UserPromptSubmit hook으로 스킬 활성화율 20%→84% 향상

**Gap**: simon-bot의 핵심 불변식(Auto-Verification)이 LLM 기억에 의존하고 있다. SKILL.md에서 "컨텍스트 압축 시 규칙이 소실되어 게이트가 무력화될 수 있기 때문이다"라고 스스로 위험을 인식하면서도, hooks를 "권장사항"으로만 두고 있다.

### 3-3. `context: fork` 미활용

**현재 상태**: Agent/subagent를 직접 spawn하는 방식 사용. `context: fork` frontmatter를 사용하지 않는다.

**Best Practice 기준**:
- 공식 문서: `context: fork`는 격리된 subagent에서 실행, 메인 대화 오염 방지
- `agent` 필드로 Explore, Plan, code-reviewer 등 지정 가능
- 150-250ms 오버헤드로 경량

**Gap**: simon-bot-report 같은 읽기 전용 분석 스킬에서 `context: fork` + `agent: Explore`가 적합할 수 있다. 다만 현재 스킬의 복잡한 다단계 워크플로에서는 fork가 적합하지 않을 수 있어 신중한 판단이 필요하다.

### 3-4. TDD Phase Isolation

**현재 상태**: simon-bot은 TDD를 "RED → GREEN → REFACTOR → VERIFY"로 명시하지만, 단일 executor subagent 내에서 모든 phase를 실행한다.

**Best Practice 기준**:
- alexop.dev 사례: "단일 컨텍스트에서 LLM은 진정한 TDD를 따를 수 없다 — 테스트 작성자의 분석이 구현자에게 bleeding"
- 3개 독립 subagent(Test Writer, Implementer, Refactorer)로 phase 격리
- Phase Gate로 테스트 실패 확인 전 다음 phase 진행 금지

**Gap**: 현재 구조에서는 테스트 작성 시 이미 구현 방향을 알고 있는 상태에서 테스트를 작성할 가능성이 있다. 다만, 이 수준의 TDD 격리는 simon-bot의 이미 복잡한 워크플로에 추가 오버헤드를 더할 수 있으므로, 비용-효과 분석이 필요하다.

### 3-5. Compaction 지시문 부재

**현재 상태**: Context Window Management 섹션에서 "자동 압축되므로 작업을 조기에 중단하지 않는다"고만 언급.

**Best Practice 기준**:
- 공식 문서: CLAUDE.md에 "When compacting, always preserve the full list of modified files and any test commands" 같은 압축 지침 포함 가능
- `/compact <instructions>`로 커스텀 압축 가능
- 핵심 결정, 파일 상태, 커맨드를 보존하도록 명시적 지시

**Gap**: simon-bot은 `.claude/memory/`에 상태를 저장하지만, 압축 시 보존해야 할 항목을 LLM에게 명시하지 않는다. 압축이 발생할 때 현재 Step, 미해결 이슈, 진행 중인 Plan 등이 소실될 수 있다.

### 3-6. Skill Description Budget 인식 부족

**현재 상태**: 12개 simon-bot 패밀리 스킬의 description이 모두 매우 길다 (대부분 200-300자 이상). 총 description 문자 수가 상당하다.

**Best Practice 기준**:
- 공식 문서: "스킬 설명은 컨텍스트 윈도우의 2%로 제한, fallback 16,000자"
- 스킬이 많으면 예산 초과 가능 → 일부 스킬이 제외됨
- `SLASH_COMMAND_TOOL_CHAR_BUDGET` 환경변수로 제한 오버라이드 가능

**Gap**: 12개 스킬의 긴 description이 총 예산에서 큰 비중을 차지할 수 있다. 트리거링에 필수적이지 않은 설명("simon-bot보다 더 강력한 자동 복구가 필요하면 이 스킬을 사용하세요" 등)을 줄이면 예산 효율을 높일 수 있다.

### 3-7. Dynamic Context Injection (`!`command``) 미활용

**현재 상태**: 스킬 시작 시 bash 명령으로 환경 정보를 수집하지만, frontmatter 수준의 dynamic injection을 사용하지 않는다.

**Best Practice 기준**:
- 공식 문서: `!`command``로 스킬 로딩 시점에 셸 명령 실행 후 결과 자동 삽입
- 예: `!`gh pr diff``, `!`git log --oneline -5``

**Gap**: simon-bot의 Startup에서 `.claude/workflow/config.yaml` 읽기, `.claude/memory/*.md` 읽기 등을 수동으로 수행한다. 일부는 `!`command``로 사전 주입하면 토큰 효율이 높아질 수 있다. 다만, 현재 Startup 절차가 조건부 분기를 많이 포함하므로 단순 대체는 어려울 수 있다.

### 3-8. `allowed-tools` 미활용

**현재 상태**: simon-bot-report는 "전문가 에이전트 spawn 시 도구 범위를 Read/Glob/Grep으로 제한한다 (P-011)"라고 텍스트로 지시하지만, frontmatter `allowed-tools`를 사용하지 않는다.

**Best Practice 기준**:
- 공식 문서: `allowed-tools` frontmatter 필드로 스킬 활성 시 도구 제한
- 결정론적 제어: LLM 지시가 아닌 시스템 수준 제한

**Gap**: 텍스트 지시("도구 범위를 Read/Glob/Grep으로 제한")는 LLM이 무시할 수 있다. `allowed-tools: Read, Grep, Glob` frontmatter가 확실한 제한을 보장한다. 다만, simon-bot-report처럼 내부에서 다양한 도구를 사용하는 복잡한 스킬에서는 전체 스킬 수준의 제한이 적절하지 않을 수 있다. 서브에이전트 수준에서의 제한이 더 적합.

### 3-9. 스킬 간 Description 경계 모호

**현재 상태**: simon-bot과 simon-bot-grind의 description이 유사한 키워드를 사용. "새 기능/피처 구현"은 둘 다에 해당될 수 있다.

**Best Practice 기준**:
- 공식 문서: "인접 스킬 경계 구분" — 유사 스킬 간 명확한 트리거 구분 필요
- Description에서 "Use when" + "Don't use when" 패턴으로 경계 명확화

**Gap**: 사용자가 "코드 작성해줘"라고 하면 simon-bot과 simon-bot-grind 중 어떤 것이 트리거될지 모호할 수 있다. description에 경계 조건을 더 명확히 하면 도움이 된다.

### 3-10. Evaluation-Driven Development 부재

**현재 상태**: simon-bot-boost에 Step 6: Verification이 있지만, 스킬 변경 후 eval 테스트를 실행하는 체계가 없다.

**Best Practice 기준**:
- 공식 문서: "Create evaluations BEFORE writing extensive documentation"
- 3개 이상의 eval 시나리오로 스킬 효과 측정
- Claude A/B 패턴으로 반복 개선

**Gap**: simon-bot-auto-boost에 "스모크 테스트"(Step 5-3)가 있지만, 구조화된 eval 프레임워크가 아니다. 스킬 변경이 실제 사용 시나리오에서 효과적인지 체계적으로 측정하는 수단이 없다.

---

## 4. Cross-Cutting Observations

### 4-1. "Advisory vs Deterministic" 갭
simon-bot은 많은 규칙을 텍스트 지시문으로 강제하려 한다. 하지만 Anthropic 공식 입장은 명확하다: "CLAUDE.md instructions are advisory, hooks are deterministic." 핵심 불변식(빌드 검증, 파일 보호, 도구 제한)은 hooks로 전환하는 것이 구조적으로 더 견고하다.

### 4-2. 컨텍스트 비용 인식
12개 스킬의 description 총량, SKILL.md의 길이, reference 파일의 수가 상당하다. Anthropic의 "컨텍스트 윈도우는 공공재" 원칙에 비추어, 각 토큰의 비용-효과를 재평가할 필요가 있다. "Does Claude really need this explanation?"

### 4-3. 복잡성과 효과의 균형
simon-bot은 19-step pipeline으로, 업계에서 가장 정교한 에이전트 워크플로 중 하나다. 새로운 기법 도입 시 복잡성 증가 vs 실제 효과 향상의 균형을 신중히 판단해야 한다. 모든 best practice가 이 수준의 복잡한 워크플로에 그대로 적용되는 것은 아니다.

---

## 5. 분석 대상 스킬별 요약

| 스킬 | 주요 강점 | 주요 개선 기회 |
|------|----------|--------------|
| simon-bot | Progressive Disclosure, Deterministic Gate, Session Isolation | Hooks 활용, Compaction 지시, TDD Phase Isolation |
| simon-bot-grind | 10-attempt ladder, Checkpoint/Rollback, Progress Detection | Total Retry Budget의 동적 조정 가이드 강화 |
| simon-bot-pm | Scope Guard, Plan Reuse Protocol, Decision Trail | Phase 간 세션 분할 경계에서의 상태 검증 강화 |
| simon-bot-report | 읽기 전용 분석, Code Design Team | `context: fork` 도입 검토, `allowed-tools` frontmatter |
| simon-bot-review | Blind-First 2-Pass, Comment Auto-Watch | 대규모 PR 처리 전략 강화 (이미 있지만 경량화 가능) |
| simon-bot-sessions | Git SSoT, 다층 소스 스캔, State Integrity Check | session-meta.json 자동 생성 안정성 |
| simon-bot-boost | 6인 전문가 패널, 커버리지 체크 | Evaluation framework 도입 |
| simon-bot-auto-boost | 4카테고리 검색, 시간 필터 | 검색 결과 품질 평가 메트릭 추가 |
| simon-bot-boost-capture | 백그라운드 최소 오버헤드 | 현재 잘 설계됨 |
| simon-bot-boost-review | 실시간 검증, 상태 관리 | applied-log.md와 insights/ 통합 뷰 |
| simon-bot-sync | 단방향 동기화, README 자동 갱신 | 동기화 검증 체크섬 추가 |

---

## Sources

- [Best Practices for Claude Code - Official Docs](https://code.claude.com/docs/en/best-practices)
- [Skill authoring best practices - Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Effective context engineering for AI agents - Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Forcing Claude Code to TDD - alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)
- [The Complete Guide to Agentic Coding in 2026](https://www.teamday.ai/blog/complete-guide-agentic-coding-2026)
- [7 Claude Code best practices for 2026](https://www.eesel.ai/blog/claude-code-best-practices)
