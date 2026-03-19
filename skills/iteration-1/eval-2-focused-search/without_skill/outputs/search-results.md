# Web Search Results: Claude Code Agent Workflow Best Practices

검색일: 2026-03-13

## 검색 소스 & 범위

Claude Code 공식 문서가 2026년 3월 기준으로 `code.claude.com/docs/en/` 으로 이전되었으며, 대폭 업데이트된 상태임. 아래 6개 핵심 페이지에서 프롬프트 엔지니어링 및 컨텍스트 관리 관련 최신 정보를 추출함.

---

## 소스 1: Claude Code Best Practices (공식)
- URL: https://code.claude.com/docs/en/best-practices
- 유형: 공식 문서
- 최종 업데이트: 2026년 (버전 미명시, 현재 최신)

### 핵심 인사이트

**1. 컨텍스트 윈도우가 가장 중요한 리소스**
- "Most best practices are based on one constraint: Claude's context window fills up fast, and performance degrades as it fills."
- LLM 성능은 컨텍스트가 채워질수록 저하됨
- 커스텀 상태줄로 컨텍스트 사용량 지속 모니터링 권장

**2. 검증 수단 제공이 가장 높은 레버리지**
- "This is the single highest-leverage thing you can do"
- 테스트, 스크린샷, 예상 출력 등 Claude가 자기 검증할 수 있는 수단 제공
- UI 변경은 Chrome 확장으로 시각 검증

**3. 탐색 → 계획 → 실행 → 커밋 4단계**
- Plan Mode (Shift+Tab)로 탐색/계획 단계에서는 읽기 전용
- Ctrl+G로 계획을 텍스트 편집기에서 직접 수정
- 범위가 명확한 작은 작업은 계획 단계 생략 가능

**4. 프롬프트 구체성**
- 구체적 파일 참조, 제약조건 명시, 예시 패턴 지정
- @ 파일 참조로 파일 내용 직접 제공
- URL, 이미지, 파이프 데이터 등 리치 컨텐츠 제공

**5. CLAUDE.md 작성 원칙**
- 200줄 이내 목표
- "Would removing this cause Claude to make mistakes?" 기준으로 정리
- 강조가 필요하면 "IMPORTANT", "YOU MUST" 등 사용
- 정기적으로 검토하고 prune

**6. 서브에이전트 활용 패턴**
- 탐색/조사를 서브에이전트에 위임하여 메인 컨텍스트 보호
- "Use subagents to investigate X" 패턴으로 컨텍스트 격리
- 구현 후 검증에도 서브에이전트 활용

**7. 일반적 실패 패턴 5가지**
- Kitchen sink session (무관한 작업 혼재)
- Correcting over and over (2회 교정 실패 후 /clear)
- Over-specified CLAUDE.md (너무 길어 무시됨)
- Trust-then-verify gap (검증 없는 신뢰)
- Infinite exploration (범위 미지정 탐색)

**8. Claude에게 인터뷰 받기 패턴**
- "Interview me in detail using the AskUserQuestion tool"
- 기술 구현, UI/UX, 엣지 케이스, 트레이드오프 질문
- 인터뷰 후 스펙을 SPEC.md로 저장, 새 세션에서 구현

---

## 소스 2: Skills System (공식)
- URL: https://code.claude.com/docs/en/skills
- 유형: 공식 문서

### 핵심 인사이트

**1. 스킬은 Agent Skills 오픈 표준 기반**
- https://agentskills.io 표준 준수
- Claude Code 전용 확장: invocation control, subagent execution, dynamic context injection

**2. 번들 스킬 — /simplify, /batch, /debug, /loop, /claude-api**
- `/simplify`: 3개 리뷰 에이전트 병렬 스폰 (코드 재사용, 품질, 효율성)
- `/batch`: 대규모 병렬 변경 오케스트레이션 (5-30 독립 작업 단위, 각각 git worktree)
- `/loop`: 반복 실행 (cron 기반)
- `/debug`: 세션 디버그 로그 분석

**3. 호출 제어 (disable-model-invocation / user-invocable)**
- `disable-model-invocation: true` — 사용자만 호출 (deploy, commit 등 부작용 있는 스킬)
- `user-invocable: false` — Claude만 호출 (배경 지식 스킬)

**4. 동적 컨텍스트 주입 (!`command` 구문)**
- 셸 명령 출력을 스킬 콘텐츠에 동적 삽입
- 전처리 → Claude는 최종 결과만 수신
- 예: `!`gh pr diff``, `!`gh pr view --comments``

**5. 서브에이전트에서 스킬 실행 (context: fork)**
- 스킬을 격리된 서브에이전트에서 실행
- agent 필드로 실행 환경 지정 (Explore, Plan, general-purpose, 커스텀)
- 명시적 지시가 있는 스킬만 의미 있음

**6. 스킬 디렉토리 지원 파일**
- SKILL.md (필수) + template, examples, scripts 등
- SKILL.md는 500줄 이내 권장
- 상세 참조는 별도 파일로 분리

**7. 문자열 치환 변수**
- $ARGUMENTS, $ARGUMENTS[N], $N (위치별)
- ${CLAUDE_SESSION_ID}, ${CLAUDE_SKILL_DIR}

**8. ultrathink 키워드**
- 스킬 콘텐츠에 "ultrathink" 포함 시 extended thinking 활성화

---

## 소스 3: Sub-agents (공식)
- URL: https://code.claude.com/docs/en/sub-agents
- 유형: 공식 문서

### 핵심 인사이트

**1. 내장 서브에이전트 유형**
- Explore (Haiku, 읽기 전용, 탐색 최적화)
- Plan (상속 모델, 읽기 전용, 계획 수립)
- general-purpose (상속 모델, 전체 도구, 복합 작업)

**2. 서브에이전트 영구 메모리 (memory 필드)**
- `memory: user` — 모든 프로젝트에서 학습 유지
- `memory: project` — 프로젝트별 학습 (VCS 공유 가능)
- `memory: local` — 프로젝트별 학습 (VCS 미포함)
- MEMORY.md 첫 200줄 자동 로딩, 상세는 별도 파일

**3. 스킬 사전 로딩 (skills 필드)**
- 서브에이전트에 스킬 콘텐츠를 사전 주입
- 부모 대화의 스킬을 상속하지 않음 — 명시적 목록 필요

**4. MCP 서버 범위 지정 (mcpServers 필드)**
- 서브에이전트 전용 MCP 서버 인라인 정의
- 메인 컨텍스트에 도구 설명 없이 서브에이전트에만 제공

**5. 조건부 규칙 (hooks)**
- PreToolUse 훅으로 서브에이전트 도구 사용 전 검증
- 예: 읽기 전용 DB 쿼리만 허용

**6. 포그라운드/백그라운드 실행**
- 포그라운드: 블로킹, 권한 프롬프트 전달
- 백그라운드: 동시 실행, 사전 권한 승인 필요

**7. isolation: worktree**
- 서브에이전트를 임시 git worktree에서 실행
- 변경 없으면 자동 정리

**8. 서브에이전트 자동 컴팩션**
- 95% 용량 시 자동 컴팩션 트리거
- CLAUDE_AUTOCOMPACT_PCT_OVERRIDE로 조기 트리거 가능

---

## 소스 4: Memory & Context Management (공식)
- URL: https://code.claude.com/docs/en/memory
- 유형: 공식 문서

### 핵심 인사이트

**1. CLAUDE.md vs Auto Memory**
- CLAUDE.md: 사용자 작성, 지시/규칙, 매 세션 로딩
- Auto Memory: Claude 자동 작성, 학습/패턴, 작업 트리별

**2. .claude/rules/ 디렉토리**
- 경로별 조건 규칙 (paths 필드로 glob 매칭)
- 파일 유형별 규칙 범위 지정
- 심볼릭 링크로 프로젝트 간 공유

**3. @path/to/import 구문**
- CLAUDE.md에서 외부 파일 임포트
- 상대/절대 경로, 재귀 임포트 (최대 5홉)
- 개인 설정은 홈 디렉토리 파일 임포트

**4. Auto Memory 메커니즘**
- MEMORY.md 첫 200줄 세션 시작 시 자동 로딩
- 200줄 초과 내용은 로딩되지 않음
- 상세 내용은 별도 토픽 파일 (on-demand 읽기)
- 프로젝트별 디렉토리: `~/.claude/projects/<project>/memory/`

**5. claudeMdExcludes 설정**
- 모노레포에서 다른 팀의 CLAUDE.md 제외
- glob 패턴으로 절대 경로 매칭

**6. InstructionsLoaded 훅**
- 어떤 instruction 파일이 언제, 왜 로딩되었는지 로깅
- 경로별 규칙 및 lazy-loaded 파일 디버깅용

**7. /compact 커스터마이징**
- CLAUDE.md에 "When compacting, always preserve X" 지시 가능
- /compact <instructions>로 압축 초점 지정
- /rewind → Summarize from here로 부분 압축

---

## 소스 5: Agent Teams (공식, Experimental)
- URL: https://code.claude.com/docs/en/agent-teams
- 유형: 공식 문서 (실험적 기능)

### 핵심 인사이트

**1. Agent Teams vs Subagents**
- Subagents: 결과만 보고, 상호 통신 불가
- Agent Teams: 공유 태스크 리스트, 직접 메시징, 자기 조율
- Agent Teams는 토큰 비용이 훨씬 높음

**2. TeammateIdle / TaskCompleted 훅**
- TeammateIdle: 팀원 idle 시 코드 2로 피드백 전송하여 작업 지속
- TaskCompleted: 태스크 완료 시 코드 2로 완료 방지 및 피드백

**3. 계획 승인 요구 (require plan approval)**
- 팀원에게 plan mode 강제 → 리드 승인 후 구현
- "only approve plans that include test coverage" 등 기준 제시

**4. 적절한 팀 규모: 3-5명**
- 팀원당 5-6개 태스크
- 더 많아도 수확 체감, 조율 오버헤드 증가

**5. 파일 충돌 회피**
- 각 팀원이 다른 파일 세트 소유하도록 작업 분할

---

## 소스 6: Hooks Reference (공식)
- URL: https://code.claude.com/docs/en/hooks
- 유형: 공식 문서

### 핵심 인사이트

**1. 훅 이벤트 전체 목록**
- SessionStart, PreToolUse, PostToolUse, Notification, Stop, SessionEnd
- SubagentStart, SubagentStop
- WorktreeCreate, WorktreeRemove
- InstructionsLoaded
- TeammateIdle, TaskCompleted (Agent Teams)

**2. 훅 유형: command, http, prompt**
- command: 셸 명령 실행
- http: HTTP 엔드포인트 호출
- prompt: LLM 프롬프트 (소형 모델로 실행)

**3. 비동기 훅 (async: true)**
- 논블로킹 실행, 결과를 기다리지 않음
- 로깅, 모니터링에 적합

**4. 스킬 내 훅 정의**
- SKILL.md frontmatter에서 훅 직접 정의
- 스킬 활성 시에만 작동

**5. Exit code 의미**
- 0: 성공, 계속 진행
- 1: 오류 (오류 메시지 표시)
- 2: 작업 차단 + 피드백 메시지 전달

---

## 소스 7: Common Workflows (공식)
- URL: https://code.claude.com/docs/en/common-workflows
- 유형: 공식 문서

### 핵심 인사이트

**1. Extended Thinking / Adaptive Reasoning**
- Opus 4.6: 적응형 reasoning (effort level로 동적 할당)
- "ultrathink" 키워드: 해당 턴만 high effort
- Option+T / Alt+T: 세션 중 thinking 토글
- MAX_THINKING_TOKENS 환경 변수로 예산 제한

**2. /btw (side question)**
- 컨텍스트에 들어가지 않는 일회성 질문
- 디테일 확인에 컨텍스트 소비 없음

**3. --worktree 플래그**
- `claude --worktree feature-auth`로 격리된 worktree 생성
- `.claude/worktrees/<name>/`에 생성, 자동 브랜치

**4. Notification 훅으로 데스크톱 알림**
- permission_prompt, idle_prompt, auth_success, elicitation_dialog 매처

**5. Unix 파이프라인 활용**
- `cat error.log | claude -p "explain"`
- `--output-format json/stream-json` 구조화 출력
- CI/CD 파이프라인 통합
