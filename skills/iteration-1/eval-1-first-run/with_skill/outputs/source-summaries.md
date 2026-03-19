# Phase 2: 콘텐츠 추출 & 소스 요약

## 소스 1: My LLM coding workflow going into 2026

- **URL**: https://addyosmani.com/blog/ai-coding-workflow/
- **출처**: addyosmani.com (개인 블로그)
- **날짜**: 2026
- **핵심 내용**: Google Chrome 팀의 Addy Osmani가 공유한 AI 코딩 워크플로. 구조화된 계획-코드-테스트-커밋 사이클을 강조하며, LLM을 "방향이 필요한 페어 프로그래머"로 취급해야 한다고 주장. 컨텍스트 관리와 검증이 핵심 테마.
- **주요 기법/패턴**:
  1. **Custom Instruction Files (CLAUDE.md)**: 스타일 가이드, 네이밍 컨벤션, 프로젝트별 규칙 포함
  2. **In-context Learning**: 원하는 패턴의 기존 코드를 예시로 제공하여 일관성 확보
  3. **Explicit Guardrails**: "hallucination보다 질문 요청" 등 명시적 가드레일
  4. **Plan-Code-Test-Commit Cycle**: 소규모 태스크 단위, 커밋을 "세이브포인트"로 활용
  5. **MCP 도구 활용**: 컨텍스트 번들링으로 관련 코드만 선택 제공
  6. **AI-assisted Code Review**: 두 번째 AI 세션으로 교차 리뷰
  7. **Git worktree 병렬 실험**: 브랜치/워크트리로 병렬 AI 실험 격리
- **simon-bot 관련성**:
  - **simon-bot**: Plan-Code-Test-Commit 사이클이 Phase B-E의 TDD + Auto-Verification Hook과 정합. AI-assisted Code Review가 Step 12와 유사하나, "두 번째 AI 세션" 접근이 Cognitive Independence 강화에 활용 가능. Git worktree 병렬 실험은 이미 Unit 기반 워크트리 사용 중
  - **simon-bot-grind**: Guardrails 패턴이 grind의 Anti-Hardcoding Principle과 일치. 모델 전환 접근(여러 모델 시도)이 Strategy Pivot의 변형으로 활용 가능
  - **simon-bot-boost**: 컨텍스트 번들링 기법이 Step 2 선택적 로딩과 정합

## 소스 2: Writing about Agentic Engineering Patterns (Simon Willison)

- **URL**: https://simonwillison.net/2026/Feb/23/agentic-engineering-patterns/
- **출처**: simonwillison.net (개인 블로그)
- **날짜**: 2026-02-23
- **핵심 내용**: Simon Willison의 에이전틱 엔지니어링 패턴 시리즈. "코드 작성 비용이 급격히 하락한 시대"에서 전문 소프트웨어 엔지니어가 에이전트를 활용하는 패턴을 체계화. Red/Green TDD 패턴을 에이전트 워크플로에 적용하는 방법을 상세 설명. "vibe coding"과 구별되는 "expertise amplification" 관점.
- **주요 기법/패턴**:
  1. **Red/Green TDD with Agents**: 테스트 먼저 작성, 에이전트가 구현 → 더 간결하고 신뢰성 높은 코드
  2. **Writing Code is Cheap Now**: 코드 생성 비용 하락에 따른 워크프랙티스 재조정
  3. **Expertise Amplification**: 에이전트는 비프로그래머용 도구가 아니라, 전문가의 역량을 증폭하는 도구
  4. **Transparency about Agent Usage**: LLM 사용 시 투명성 정책 유지
- **simon-bot 관련성**:
  - **simon-bot**: TDD 필수 원칙(Step 5)과 직접적으로 정합. "코드 작성 비용 하락" 관점이 Phase B-E의 병렬 실행 전략과 연결
  - **simon-bot-grind**: "Expertise Amplification" 관점이 grind의 핵심 철학 "끝날 때까지 끝난 게 아니다"와 공명 — 에이전트의 끈기를 전문가의 역량으로 전환
  - **simon-bot-review**: 투명성 정책이 Review Summary Body의 "AI가 분석한 부분 명시" 접근과 연결 가능

## 소스 3: Agentic Coding (MIT Missing Semester)

- **URL**: https://missing.csail.mit.edu/2026/agentic-coding/
- **출처**: MIT CSAIL (대학 강의 자료)
- **날짜**: 2026
- **핵심 내용**: MIT의 "The Missing Semester of Your CS Education" 시리즈에 새로 추가된 에이전틱 코딩 강의. 에이전트의 아키텍처(대화형 AI + 도구 접근), 효과적인 사양 작성, 피드백 루프, 컨텍스트 윈도우 최적화, 멀티 에이전트 패턴을 체계적으로 다룸.
- **주요 기법/패턴**:
  1. **Context Window Optimization**: Clear/Rewind/Compaction/llms.txt/AGENTS.md/Skills/Subagents — 7가지 컨텍스트 관리 방법
  2. **Multi-Agent Patterns**: 병렬 에이전트 + git worktree 격리, 서브에이전트 위임
  3. **Feedback Loop Design**: 자율 반복 검증 (테스트/린터/타입체커), 수동 피드백은 자동 실행 불가 시만
  4. **Rewind over Steer**: 잘못된 방향 수정 시 steering message보다 conversation rewind가 효과적
  5. **Specification Balance**: 과소/과다 사양 모두 문제 — 반복 가능한 수준의 적절한 상세도
  6. **Safety Practices**: 격리 환경(VM, 컨테이너), 도구 호출 확인, 출력 검토
  7. **Debugging Spiral Awareness**: 디버깅 스파이럴 인식 및 조기 중단
- **simon-bot 관련성**:
  - **simon-bot**: Context Window Management 섹션과 직접 정합. "Rewind over Steer" 패턴이 Decision Journal의 Anti-Oscillation Rule과 유사한 목적(잘못된 방향 수정). Feedback Loop Design이 Auto-Verification Hook + Stop-and-Fix Gate와 정합
  - **simon-bot-grind**: "Debugging Spiral Awareness"가 Progress Detection(2회 연속 정체 시 전략 전환)과 직접 대응. "Specification Balance"가 Phase A 인터뷰의 과도한 질문 방지와 연결
  - **simon-bot-sessions**: Context Window Optimization의 7가지 방법이 세션 관리 전략에 참고 가능. 특히 Compaction 시점 판단 기준

## 대상 스킬 선택적 로딩

소스 요약을 기반으로 가장 관련성이 높은 스킬 2-3개를 선택:

1. **simon-bot** (코어) — 3개 소스 모두 워크플로 구조, 컨텍스트 관리, TDD, 피드백 루프와 관련
2. **simon-bot-grind** — 디버깅 스파이럴, 전략 전환, 진전 감지와 관련
3. **simon-bot-sessions** — 컨텍스트 윈도우 최적화, 세션 관리와 관련

로딩한 파일:
- `~/.claude/skills/simon-bot/SKILL.md` (389줄) — 완료
- `~/.claude/skills/simon-bot-grind/SKILL.md` (184줄) — 완료
- `~/.claude/skills/simon-bot-boost/SKILL.md` (392줄) — 완료 (비교 참조용)
- `~/.claude/boost/applied-log.md` — 완료 (중복 제안 방지)
- `~/.claude/skills/simon-bot-boost/references/skill-best-practices.md` — 완료 (검증용)
