# Web Search Results: AI Coding Agent & Claude Code Best Practices (2026-03)

## 검색 날짜: 2026-03-13

---

## 소스 1: Claude Code 공식 Best Practices (Anthropic)
- **URL**: https://code.claude.com/docs/en/best-practices
- **유형**: 공식 문서
- **관련성**: ★★★ (직접 관련)

### 핵심 내용
- **컨텍스트 윈도우가 핵심 제약**: 채워질수록 성능이 저하됨. 관리가 가장 중요.
- **자기 검증 수단 제공**: 테스트, 스크린샷, 기대 출력을 제공하면 성능이 극적으로 향상됨. "가장 높은 레버리지를 가진 단일 행동"
- **탐색 → 계획 → 구현 → 커밋 4단계 워크플로**: Plan Mode로 탐색/계획 분리
- **CLAUDE.md 관리**: 200줄 이내 유지, 자주 적용되는 규칙만. "Would removing this cause Claude to make mistakes?" 테스트
- **Subagent로 조사 위임**: 탐색이 메인 컨텍스트를 오염시키지 않도록 격리
- **실패 패턴 5가지**: Kitchen sink session, 반복 수정, 과도한 CLAUDE.md, trust-then-verify gap, 무한 탐색
- **`/clear`를 자주 사용**: 무관한 작업 사이에 컨텍스트 리셋
- **2회 이상 수정 실패 시**: `/clear` 후 학습한 내용으로 더 구체적인 프롬프트로 재시작
- **Hooks**: "must happen every time" 액션에 사용 — CLAUDE.md는 advisory, Hooks는 deterministic
- **Fan-out 패턴**: `claude -p`로 루프 돌며 대규모 마이그레이션 병렬 처리

---

## 소스 2: Skill Authoring Best Practices (Anthropic 공식)
- **URL**: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- **유형**: 공식 문서
- **관련성**: ★★★ (직접 관련)

### 핵심 내용
- **Concise is key**: 컨텍스트 윈도우는 공공재. 토큰 경쟁. "Claude is already very smart" — 모르는 것만 추가
- **자유도 조절**: 작업의 취약성에 맞게 높은/중간/낮은 자유도 선택. 취약한 작업은 정확한 스크립트, 유연한 작업은 텍스트 지시문
- **모든 모델에서 테스트**: Haiku에서 충분한 가이드? Opus에서 과잉 설명 아닌지?
- **Naming convention**: gerund form 권장 (processing-pdfs, analyzing-spreadsheets)
- **Description은 3인칭으로**: "Processes Excel files" (O), "I can help you" (X), "You can use this" (X)
- **Progressive Disclosure**: SKILL.md는 500줄 이내, 참조 파일은 1단계 깊이까지만
- **100줄 초과 참조 파일에 TOC**: Claude가 부분 읽기할 때 전체 범위 파악 가능
- **깊은 중첩 참조 금지**: SKILL.md → advanced.md → details.md (X), SKILL.md에서 직접 참조 (O)
- **Evaluation-Driven Development**: eval을 먼저 만들고, 그 다음 스킬 작성. 실제 문제 해결 보장
- **Claude A/B 패턴**: Claude A가 스킬 설계, Claude B가 테스트. 반복 개선.
- **Feedback Loop 패턴**: Run validator → fix errors → repeat. 품질을 크게 향상.
- **Template pattern**: 엄격 vs 유연 사용 분리
- **Verifiable intermediate outputs**: 계획 → 검증 → 실행 순서로 오류 조기 감지

---

## 소스 3: Effective Context Engineering for AI Agents (Anthropic Engineering)
- **URL**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- **유형**: 공식 엔지니어링 블로그
- **관련성**: ★★★ (직접 관련)

### 핵심 내용
- **Context Engineering > Prompt Engineering**: 어떤 정보가 모델의 제한된 attention budget에 들어가는지 큐레이팅
- **Context rot**: 토큰 증가 → 리콜 정확도 감소. n² pairwise relationships
- **최소 high-signal 토큰 세트**: 간결함이 아닌 정보 밀도 최적화
- **Goldilocks zone**: 너무 구체적(brittle if-else)도, 너무 모호(context-assuming)도 안 됨
- **Just-in-Time Context Retrieval**: 사전 로딩 대신 경량 식별자(파일 경로, 쿼리, 링크) 유지 → 런타임에 동적 로딩
- **Compaction**: 컨텍스트 한계 접근 시 대화 이력 요약. 아키텍처 결정, 미해결 이슈 보존
- **Structured Note-Taking**: 컨텍스트 윈도우 밖의 외부 메모리(NOTES.md, to-do lists) 활용
- **Sub-Agent Architectures**: 전문 서브에이전트가 집중 작업 후 압축 요약(1,000-2,000 토큰) 반환
- **Minimal Viable Tool Sets**: 도구 세트 비대화 방지. 사람이 어떤 도구를 쓸지 확정 못하면 AI도 못함
- **"Do the simplest thing that works"**: 최소한의 프롬프트로 시작, 관찰된 실패 모드 기반 반복

---

## 소스 4: Claude Code Skills 공식 문서
- **URL**: https://code.claude.com/docs/en/skills
- **유형**: 공식 문서
- **관련성**: ★★★ (직접 관련)

### 핵심 내용
- **Agent Skills open standard**: 여러 AI 도구에서 작동
- **Bundled skills**: `/simplify`, `/batch`, `/debug`, `/loop`, `/claude-api`
- **`context: fork`**: 격리된 subagent에서 실행. 메인 대화 오염 방지
- **`agent` field**: Explore, Plan, general-purpose, code-reviewer 또는 커스텀 subagent
- **`disable-model-invocation: true`**: 부작용 있는 워크플로에 사용 (deploy, commit 등)
- **`user-invocable: false`**: 배경 지식용, 사용자가 직접 호출할 필요 없음
- **`allowed-tools`**: 스킬 활성 시 도구 제한 (읽기 전용 모드 등)
- **String substitutions**: `$ARGUMENTS`, `$ARGUMENTS[N]`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`
- **Dynamic context injection**: `!`command`` 구문으로 셸 명령 실행 후 결과 삽입
- **스킬 설명 character budget**: 컨텍스트 윈도우의 2%, fallback 16,000자. 스킬 많으면 예산 초과 가능
- **`SLASH_COMMAND_TOOL_CHAR_BUDGET`**: 환경변수로 제한 오버라이드 가능

---

## 소스 5: Custom TDD Workflow (alexop.dev)
- **URL**: https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/
- **유형**: 블로그 / 실전 사례
- **관련성**: ★★☆

### 핵심 내용
- **컨텍스트 오염 문제**: 단일 컨텍스트에서 TDD 불가 — 테스트 작성자의 분석이 구현자에 bleeding
- **3-Phase Agent System**: RED(테스트 작성) → GREEN(최소 구현) → REFACTOR(리팩토링) 각각 별도 subagent
- **Phase Gate**: "Do NOT proceed to Green phase until test failure is confirmed"
- **UserPromptSubmit Hook**: 스킬 활성화율 20% → 84%로 향상. 훅이 강제 평가 지시를 주입
- **TDD를 아키텍처 문제로 취급**: 행동적 권장이 아닌 구조적 강제
- **"Do NOT" 가드**: 스킬 정의에 명시적 금지 조항

---

## 소스 6: Complete Guide to Agentic Coding 2026 (teamday.ai)
- **URL**: https://www.teamday.ai/blog/complete-guide-agentic-coding-2026
- **유형**: 종합 가이드
- **관련성**: ★★☆

### 핵심 내용
- **5가지 핵심 에이전트 패턴**: Prompt Chaining, Routing, Parallelization, Orchestrator-Workers, Evaluator-Optimizer
- **Orchestrator-Workers**: 코딩에 가장 일반적인 패턴
- **Evaluator-Optimizer**: 반복 개선 — 하나가 생성, 다른 하나가 평가+피드백
- **Agent-Friendly 언어**: Go, TypeScript, Rust가 magic-heavy 프레임워크보다 나음
- **빠른 컴파일/테스트 피드백**: 생산적 반복의 핵심
- **병렬 에이전트에 격리된 리소스**: 동기화 merge point 설정
- **6가지 함정**: 조기 복잡화, 맹목적 신뢰, 정리 안 된 코드베이스, 불충분한 자동 테스트, 컨텍스트 과부하, 버려진 패턴
- **Vibe coding vs Agentic engineering**: Karpathy 구분 — 실험적 vs 프로덕션 레디

---

## 소스 7: 7 Claude Code Best Practices for 2026 (eesel.ai)
- **URL**: https://www.eesel.ai/blog/claude-code-best-practices
- **유형**: 블로그 / 실전 팁
- **관련성**: ★★☆

### 핵심 내용
- **다중 CLAUDE.md 파일**: 루트 + 서브디렉토리별 focused context
- **계획 후 실행**: (1) 계획 요청 (2) 코딩 금지 명시 (3) 리뷰/수정 (4) 승인 후 코딩
- **커스텀 도구/명령**: .claude/commands에 재사용 가능한 프롬프트 템플릿
- **Git 워크플로**: feature branch + worktree 병렬 작업
- **Sub-agent로 컨텍스트 관리**: 복잡한 워크플로에서 focused context 유지
- **Headless mode + Hooks**: CI/CD 파이프라인 자동화

---

## 소스 8: Agent Teams Architecture
- **URL**: https://claudefa.st/blog/guide/agents/agent-teams (외 다수)
- **유형**: 가이드 / 블로그
- **관련성**: ★★☆

### 핵심 내용
- **Subagents vs Agent Teams**: Subagents는 단일 세션 내, Agent Teams는 세션 간 조율
- **2-16 agents**: Claude Opus 4.6 (2026-02-05) 출시와 함께
- **7x 토큰 사용량**: 단일 세션 대비. 독립 작업에 적합, 순차/동일파일 작업에는 비효율
- **Task claiming**: 파일 잠금으로 경쟁 조건 방지
- **Inbox-based messaging**: 에이전트 간 직접 통신

---

## 소스 9: Claude Code Hooks Patterns
- **URL**: https://code.claude.com/docs/en/hooks-guide (외 다수)
- **유형**: 공식 문서 + 가이드
- **관련성**: ★★☆

### 핵심 내용
- **PreToolUse**: 유일하게 action을 block할 수 있는 훅. 보안 게이트, 파일 보호, 필수 리뷰 강제
- **PostToolUse**: 파일 변경 후 자동 포매팅, 테스트 실행, 로깅
- **SessionStart**: 최신 버그 리포트 pull 등 세션 초기화
- **Stop**: 세션 종료 시 staging branch push 등
- **Prompt hook vs Command hook**: LLM 기반(유연) vs bash 기반(결정론적)
- **Skill 내 scoped hooks**: 스킬 라이프사이클에 특화된 훅 설정 가능

---

## 소스 10: Context Engineering & Prompt Engineering Trends
- **URL**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents (외 다수)
- **유형**: 엔지니어링 블로그 / 가이드
- **관련성**: ★★☆

### 핵심 내용
- **LLM 추론 성능 3,000 토큰 이후 저하**: 실용적 sweet spot은 150-300 단어
- **Context Engineering의 부상**: 프롬프트 문구 최적화에서 "어떤 컨텍스트 구성이 원하는 행동을 가장 잘 이끌어내는가"로 전환
- **시스템 프롬프트 명확성**: 극도로 명확하고 단순한 직접적 언어, 적절한 추상 수준
- **Zero-shot 먼저 시도**: few-shot 전에 zero-shot 시도 권장
- **불확실성 표현 허용**: AI에게 추측 대신 불확실성을 명시적으로 표현할 수 있는 권한 부여 → 환각 감소

---

## Sources

- [Best Practices for Claude Code - Official Docs](https://code.claude.com/docs/en/best-practices)
- [Skill authoring best practices - Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Effective context engineering for AI agents - Anthropic Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Forcing Claude Code to TDD - alexop.dev](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)
- [The Complete Guide to Agentic Coding in 2026 - teamday.ai](https://www.teamday.ai/blog/complete-guide-agentic-coding-2026)
- [7 Claude Code best practices for 2026 - eesel.ai](https://www.eesel.ai/blog/claude-code-best-practices)
- [Claude Code Agent Teams Guide](https://claudefa.st/blog/guide/agents/agent-teams)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [10 Must-Have Skills for Claude - Medium](https://medium.com/@unicodeveloper/10-must-have-skills-for-claude-and-any-coding-agent-in-2026-b5451b013051)
- [CLAUDE.md Best Practices - UX Planet](https://uxplanet.org/claude-md-best-practices-1ef4f861ce7c)
- [Claude Code best practices for enterprise teams - Portkey](https://portkey.ai/blog/claude-code-best-practices-for-enterprise-teams/)
- [Claude Code Best Practices - GitHub (shanraisshan)](https://github.com/shanraisshan/claude-code-best-practice)
- [Claude Code Best Practices - GitHub (awattar)](https://github.com/awattar/claude-code-best-practices)
- [Agentic Coding Handbook TDD](https://tweag.github.io/agentic-coding-handbook/WORKFLOW_TDD/)
- [Prompt Engineering Best Practices 2026 - Lakera](https://www.lakera.ai/blog/prompt-engineering-guide)
- [Prompt engineering best practices - Claude](https://claude.com/blog/best-practices-for-prompt-engineering)
- [Claude Code Customization Guide - alexop.dev](https://alexop.dev/posts/claude-code-customization-guide-claudemd-skills-subagents/)
