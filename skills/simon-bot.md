---
name: simon-bot
description: "19-step deep workflow plugin that plans, implements, and verifies code with maximum rigor. Use when: (1) Building new features with quality pipeline, (2) Need scope-first planning with expert review panel, (3) Want parallel execution in isolated git worktrees, (4) Need comprehensive code verification before PR."
---

# simon-bot

Deep workflow skill with 19-step quality pipeline.

## Instructions

You are executing the **simon-bot** deep workflow. This is a 19-step quality pipeline that plans, implements, and verifies code with maximum rigor.

### Error Resilience Protocol (Cross-Cutting — ALL Steps)

**ABSOLUTE RULE: 워크플로는 사용자가 명시적으로 중단을 요청하지 않는 한 절대 중단되지 않는다.**

어떤 단계에서든 명령어 실행(빌드, 테스트, 타입체크, 린트 등)이 실패하면:

1. **절대 워크플로를 중단하지 말 것** — 에러 출력을 읽고 분석을 시작
2. **에러 원인 분석**: 에러 메시지, 스택 트레이스, 관련 파일을 분석하여 근본 원인 파악
3. **수정 시도**: `executor`를 spawn하여 문제를 수정 (최대 3회)
4. **3회 실패 시**: `architect` (opus)를 spawn하여 Root Cause Analysis 수행 → 더 깊은 수정 시도 (최대 3회 추가)
5. **6회 모두 실패 시**: 사용자에게 AskUserQuestion으로 상황 보고 + 선택지 제시:
   - 다른 접근법으로 재시도
   - 해당 단계를 건너뛰고 다음으로 진행
   - 워크플로 중단 (사용자가 명시적으로 선택한 경우에만)

**금지 사항:**
- 에러가 발생했다고 "워크플로를 종료합니다" / "중단합니다" 라고 선언하는 것
- 사용자에게 묻지 않고 자의적으로 워크플로를 포기하는 것
- 에러를 무시하고 넘어가는 것 (반드시 분석 후 수정 시도해야 함)

**적용 범위:** build 실패, test 실패, typecheck 실패, lint 실패, docker 명령 실패, git 명령 실패, script 실행 실패 등 모든 종류의 명령어 실행 실패에 적용

### Startup

**IMPORTANT: Execute these steps SEQUENTIALLY, not in parallel.**

1. Determine if `.omc/workflow/` exists in the current project. If not, run the init script:
   ```
   bash ~/.claude/skills/simon-bot/install.sh --project-only
   ```
2. After Step 1 confirms workflow files exist, read these (can be parallel):
   - Workflow config: `.omc/workflow/config.yaml`
   - Retrospective (if exists, skip if not): `.omc/memory/retrospective.md`
   - Project memory (if exists, skip if not): use `project_memory_read` MCP tool
3. **브랜치명 입력받기** (AskUserQuestion):
   - 사용자에게 작업용 브랜치명을 입력받음 (예: `feat/add-auth`, `fix/login-bug`)
   - 입력받은 브랜치명을 `.omc/memory/branch-name.md`에 저장
   - 이 브랜치명은 이후 worktree 생성, Integration, PR 생성에 모두 사용됨

### Phase A: Planning (Interactive with User)

**Step 0: Scope Challenge**
- Spawn `architect` (opus): Analyze git history for past problem areas
- Identify "What already exists" - existing code that solves parts of the request
- Determine minimum viable change
- Flag if scope exceeds 8 files or 2 new classes
- Present 3 review paths to user via AskUserQuestion:
  - **SMALL**: Steps 5-8 + 17 only
  - **STANDARD**: Steps 5-17 full pipeline
  - **LARGE**: Steps 5-17 + extended failure mode analysis
- Record decision in `.omc/memory/plan-summary.md`

**Step 1-A: Project Analysis + Code Design Analysis**
- Spawn `explore-medium` (sonnet): Scan project structure
- Spawn `analyst` (opus): Generate analysis report + recommend principles
- Use Context7 MCP (`resolve-library-id` → `query-docs`) for library docs
- Auto-generate allowed command list based on detected stack
- Skill: Use `/deepsearch` if codebase is large
- **Auto-detect experts**: 스캔 결과를 `config.yaml`의 `expert_panel.specialists[].detect` 키워드와 매칭하여 활성화할 전문가 목록 결정
- **Agent Team: Code Design Team** (explore-medium 완료 후 병렬 실행):
  - `config.yaml`의 `expert_panel.domain_teams.code-design` 참조
  - 목적: 레포의 코드 설계 컨텍스트를 사전 분석하여 이후 모든 단계에서 활용
  - Agent Team 생성 (teammate 모델: opus):
    - **convention-expert** (always): `explore-medium`으로 plan 관련 디렉토리의 기존 코드 패턴 분석
      - 네이밍 규칙, 디렉토리 구조, 에러 핸들링 패턴, import 순서
      - CLAUDE.md / .editorconfig / linter 설정 읽기
      - 유사 기능의 기존 구현체 탐색
    - **idiom-expert** (always): Context7 MCP로 사용 중인 프레임워크/라이브러리 공식 문서 조회
      - 언어 공식 가이드 (Effective Go, PEP 8, TypeScript handbook 등)
      - 프레임워크 공식 권장 패턴 및 anti-pattern
    - **design-pattern-expert** (auto-detect): 기존 코드의 아키텍처 패턴 파악
      - Clean Architecture / Layered / Hexagonal 등 식별
      - 의존성 방향, 인터페이스 사용 패턴
    - **testability-expert** (auto-detect): 기존 테스트 구조, mock/fixture 패턴 파악
  - Shared tasks:
    - Task 1: 각자 도메인별 레포 분석
    - Task 2: 서로 발견한 패턴 공유 및 토론 (예: convention-expert가 "repository 패턴 사용 중" → design-pattern-expert가 "DIP도 적용, domain 패키지에 interface 정의하는 관행")
    - Task 3: 팀 합의 → `.omc/memory/code-design-analysis.md` 작성
  - Agent Team 해산
- Save: `.omc/memory/requirements.md`, `.omc/memory/code-design-analysis.md`

**Step 1-B: Plan Creation**
- Spawn `planner` (opus) in interview mode
- Input: User request + Step 0 scope + Step 1-A analysis + **`.omc/memory/code-design-analysis.md`** (Code Design Team 분석 결과)
- Split work into Units: max 3-5 files, 200 lines per Unit, single concern
- Build dependency graph: parallel vs sequential groups
- Use Context7 for SDK documentation needed for implementation
- Required sections in plan:
  - Goal and completion criteria
  - Unit breakdown with file lists
  - Implementation order
  - Development principles (TDD/DDD/Clean Architecture as confirmed)
  - "NOT in scope" section
  - "Unresolved decisions" section
  - Expected risks
- Save to `.omc/memory/plan-summary.md`
- Skill: Use `/plan`

**Steps 2-4: Plan Review (Agent Team)**

**Agent Team 생성**: Steps 2-4 전체에 걸쳐 하나의 지속 Agent Team을 사용합니다.
- 목적: planner, critic, architect가 직접 토론하여 plan 품질을 높임
- Agent Team 생성 (teammate 모델: opus):
  - **planner**: plan 수정/방어 담당
  - **critic**: 논리/실현성 검증 담당
  - **architect**: 구조 검증 + YAGNI/KISS 검증 담당
- 컨텍스트: `.omc/memory/plan-summary.md`, `.omc/memory/requirements.md`, `.omc/memory/code-design-analysis.md`

**Step 2: Plan Review**
- Shared task: "critic이 plan을 리뷰하고 planner에게 직접 피드백"
- critic ←→ planner 직접 토론 (orchestrator 중계 없이)
- critic이 이슈 발견 시 planner에게 직접 메시지로 수정 요청
- planner는 수정 이유를 critic에게 직접 설명/반박 가능
- Max 3 iterations (config `loop_limits.critic_planner`)

**Step 3: Meta Verification**
- Shared task: "architect가 critic의 리뷰를 cross-verify"
- architect → critic/planner에게 직접 메시지로 검증 결과 전달
- architect는 Steps 2의 토론 맥락을 보고 있으므로 더 정확한 판단 가능
- Severity-based routing:
  - Minor (detail-level): → Step 2 task 재할당
  - Major (structural): → lead에게 보고 → Step 1-B (with failure reason)

**Step 4: Over-engineering Check**
- Shared task: "architect가 YAGNI/KISS 관점으로 plan 검증"
- architect → planner에게 직접 토론: "이 부분은 과잉이다, 이유는..."
- planner → architect에게 직접 반박: "이건 필요하다, 근거는..."
- 직접 토론으로 합의 도출
- Severity-based routing:
  - Minor (some items excessive): → Step 2 task 재할당
  - Major (entire design excessive): → lead에게 보고 → Step 1-B (with failure reason)

**Step 4 완료 시**: Agent Team 해산
- Skill: Use `/ralplan` for Steps 2-4 combined

**Step 4-B: Expert Plan Review — 도메인팀 Agent Team 토론 (사전 우려 검토)**
- 목적: 구현 전에 도메인 전문가들이 **팀 내 토론**을 통해 우려사항/위험요소를 사전에 식별
- `config.yaml`의 `expert_panel` 섹션 참조 (specialists, domain_teams, team_activation)
- Read expert prompts from `.omc/workflow/prompts/*.md`

- **팀 활성화 규칙** (`config.yaml` → `expert_panel.team_activation`):
  - SMALL path: Safety Team + Code Design Team (always 멤버만: appsec, stability, convention, idiom)
  - STANDARD path: Safety + Code Design (always) + auto-detect된 Data/Integration/Ops 팀
  - LARGE path: 전체 + extended failure mode analysis

- **5개 도메인팀 병렬 Agent Team 생성** (각 팀 teammate 모델: opus):

  - **Data Team** (min_active 2, auto-detect):
    - members: rdbms-expert, cache-expert, nosql-expert
    - 토론 초점: 데이터 일관성, 캐시 무효화 전략, 스토리지 간 정합성

  - **Integration Team** (min_active 2, auto-detect):
    - members: sync-api-expert, async-expert, external-integration-expert, messaging-expert
    - 토론 초점: 동기/비동기 경계, 에러 전파, 장애 격리

  - **Safety Team** (always — appsec + stability 항상 활성):
    - members: appsec-expert, auth-expert, infrasec-expert, stability-expert
    - 토론 초점: 보안 경계, 인증 우회, 장애 복구

  - **Ops Team** (min_active 2, auto-detect):
    - members: infra-expert, observability-expert, performance-expert, concurrency-expert
    - 토론 초점: 운영 안정성, 관측 가능성, 성능

  - **Code Design Team** (always — convention + idiom 항상 활성):
    - members: convention-expert, idiom-expert, design-pattern-expert, testability-expert
    - 토론 초점: 레포 컨벤션, 언어 관용구, 설계 패턴, 테스트 가능성
    - **Step 1-A의 `.omc/memory/code-design-analysis.md` 활용** (사전 분석 결과)

- **각 Agent Team의 Shared Tasks** (3단계 토론):
  - Task 1: 각 teammate가 독립적으로 plan-summary.md 검토 → 도메인별 findings 작성
  - Task 2: 다른 teammate의 findings를 읽고 **직접 메시지로 반박/보강 토론**
    - 예: rdbms-expert → cache-expert: "이 테이블 write 빈도가 높은데 캐시 TTL이 너무 길다"
    - 예: appsec-expert → auth-expert: "이 인증 플로우에서 토큰 탈취 시나리오가 누락됐다"
    - 예: convention-expert → design-pattern-expert: "이 레포는 repository 패턴인데 plan에 없다"
  - Task 3: 팀 합의 도출 → 팀별 findings.md 작성 (CRITICAL/HIGH/MEDIUM severity)

- **각 팀에 전달할 컨텍스트**:
  - `.omc/memory/plan-summary.md` (전체 계획)
  - `.omc/memory/requirements.md` (요구사항)
  - `.omc/memory/code-design-analysis.md` (Code Design Team 사전 분석)
  - 각 teammate의 expert prompt (`.omc/workflow/prompts/{expert}.md`)
  - `config.yaml` → `domain_teams.{team}.cross_topics` (교차 토론 주제)

- **Lead의 Cross-team Synthesis**:
  - 5개 팀의 findings를 통합
  - 도메인 간 충돌 식별 (예: Data Team "캐시 TTL 30초 권장" vs Integration Team "외부 API 타임아웃 60초")
  - 최종 `expert-plan-concerns.md` 작성

- 각 findings 출력 형식:
  - **우려사항**: CRITICAL / HIGH / MEDIUM 심각도 (팀 합의 기반)
  - **권장사항**: 구현 시 고려해야 할 구체적 주의점
  - **토론 근거**: 어떤 전문가가 어떤 논거로 해당 severity에 합의했는지
  - **질문**: 계획에서 불명확한 부분
- CRITICAL 우려가 있으면: `planner`에게 전달하여 계획 수정 → Step 2로 회귀 (max 2회)
- HIGH 우려: 계획에 주의사항으로 추가, 구현 시 반드시 반영
- MEDIUM 우려: 기록만 하고 구현 시 참고
- Save: `.omc/memory/expert-plan-concerns.md`
- 사용자에게 주요 우려사항 요약 보고 (AskUserQuestion으로 진행 여부 확인)

### Phase B-E: Implementation & Verification (ralph + ultrawork AUTO)

After Phase A is confirmed, activate ralph + ultrawork mode automatically.
Each Unit runs in an **isolated git worktree**.
Independent Units run in **parallel**.

**Pre-Phase: Base Branch Sync & Worktree 생성**
- 목적: 최신 main/master 기준으로 작업용 worktree 생성
- 절차:
  1. default branch 감지 (`auto`이면 main/master 자동 감지)
  2. `git fetch {remote} {base_branch}` 실행 (원격 최신 동기화)
  3. `.omc/memory/branch-name.md`에서 사용자가 입력한 브랜치명 읽기
  4. worktree 생성: `git worktree add .claude/worktrees/{branch-name} -b {branch-name} origin/{base_branch}`
  5. 해당 worktree로 작업 디렉토리 이동
  6. base commit SHA를 `.omc/memory/base-commit.md`에 기록
- **중요:** 현재 로컬 브랜치를 checkout/변경하지 않음 (안전)
- Save: `.omc/memory/base-commit.md`

**CRITICAL RULES:**
- All verification/review: ONLY changed files (git diff based)
- Use `.omc/workflow/scripts/*.sh` for deterministic tasks (save context)
- Record findings in `.omc/memory/unit-{name}/*.md` after each step
- Read memory files at start of each step
- Tests: NEVER use real DB or external APIs (mock/stub only)
- Commands: NEVER access real external systems (no curl to prod, no real DB connections)

**Pre-Step: Test Environment Setup**
- Run `.omc/workflow/scripts/setup-test-env.sh` to check and set up test environment
- If environment is already ready: proceed with tests immediately
- If environment is NOT ready: attempt automatic setup:
  - Node.js: `npm install`
  - Python: `pip install -r requirements.txt` or `pip install -e ".[test]"`
  - Go: `go mod download`
  - Java/Maven: `mvn dependency:resolve`
  - Rust/Gradle: toolchain check only (deps resolved at build time)
- If setup succeeds: proceed with tests normally
- If setup fails (toolchain missing, install error): skip tests (build and typecheck still run)
- This setup is embedded in `run-tests.sh` — every test invocation auto-triggers
- Configurable via `test_env` section in `config.yaml`
- Save result: `.omc/memory/test-env-status.md`

**For each Unit (in isolated worktree):**

**Step 5: Implementation**
- **먼저 읽기**:
  - `.omc/memory/expert-plan-concerns.md` (Step 4-B 전문가 우려사항)
  - `.omc/memory/code-design-analysis.md` (Step 1-A Code Design Team 분석 — 레포 컨벤션, 기존 패턴, 공식 권장사항)
- Spawn `executor` (opus), parallel for independent files
- executor는 code-design-analysis.md의 컨벤션과 패턴을 따라 구현해야 함
- 전문가 우려사항 중 HIGH 이상 항목을 구현 시 반드시 고려
- If TDD selected: Write tests first, then implement
- Run via tmux: build + test + typecheck simultaneously
- Skill: `/tdd` if TDD was selected
- Save: `.omc/memory/unit-{name}/implementation.md`

**Step 6: Purpose Alignment Review**
- Spawn `architect` (opus): Check implementation matches requirements
- Minor: executor auto-fix (max 3 times)
- Major: → Step 1-B (plan itself was insufficient)

**Step 7: Bug/Security/Performance Review — 도메인팀 Agent Team 토론**
- Read expert prompts from `.omc/workflow/prompts/*.md`
- **7-A: 구현 결과 검증 (Agent Team 토론)**
  - Step 4-B와 동일한 5개 도메인팀 Agent Team 구조 사용
  - `config.yaml` → `expert_panel` 참조 (동일 팀 활성화 규칙 적용)
  - 각 도메인팀에 추가 컨텍스트 제공:
    - `.omc/memory/plan-summary.md` (계획)
    - `.omc/memory/expert-plan-concerns.md` (Step 4-B 결과)
    - `.omc/memory/code-design-analysis.md` (Step 1-A Code Design 분석)
    - **실제 git diff** (`.omc/workflow/scripts/extract-diff.sh` 출력)
  - 각 Agent Team의 Shared Tasks (4단계):
    - Task 0 (신규): "Step 4-B에서 우리 팀이 지적한 concern이 구현에 반영됐는지 확인"
    - Task 1: 각 teammate가 독립적으로 실제 diff 검토 → 도메인별 findings 작성
    - Task 2: 다른 teammate의 findings를 읽고 직접 메시지로 반박/보강 토론
    - Task 3: 팀 합의 도출 → 팀별 findings.md 작성 (CRITICAL/HIGH/MEDIUM severity)
  - Lead의 Cross-team Synthesis → 통합 findings
  - tmux: build + test + typecheck simultaneously
  - CRITICAL/HIGH → executor auto-fix, MEDIUM → record
- **7-B: 사전 우려사항 대조 검증**
  - 읽기: `.omc/memory/expert-plan-concerns.md` (Step 4-B 결과)
  - Spawn `architect` (opus): 사전 우려사항 중 구현에서 누락된 항목이 있는지 대조
  - 누락된 우려사항 발견 시: executor auto-fix → 7-A 전문가 재검증 (max 1회)
  - 모두 반영 확인 시: 통과
- Skill: `/security-review` + `/code-review`
- Save: `.omc/memory/unit-{name}/review-findings.md`

**Step 8: Regression Verification**
- Spawn `architect` (opus): Verify Step 7 fixes didn't break anything
- Regression found: executor fix → Step 7 re-review (max 2 loops)

--- SMALL path skips to Step 17 here ---

**Step 9: File/Function Splitting**
- Spawn `architect` (opus): Detect oversized functions/files
- Thresholds from config.yaml (default: 50 lines function, 300 lines file)
- Split based on confirmed principles (DDD→domain, Clean→layer, default→SRP)
- Spawn `executor` (opus): Execute splits

**Step 10: Integration/Reuse Review**
- Spawn `architect` (opus): Find duplicate code, reuse opportunities
- Spawn `executor` (opus): Refactor as needed

**Step 11: Side Effect Check**
- Spawn `architect` (opus): Verify refactoring didn't change behavior
- Minor: executor fix. Major: → Step 9

**Step 12: Full Change Review**
- Spawn `code-reviewer` (opus): Review entire diff
- Minor: executor fix. Major: → Step 9
- Skill: `/code-review`

**Step 13: Dead Code Cleanup**
- Run `.omc/workflow/scripts/find-dead-code.sh`
- Spawn `architect` (opus) → `executor` (opus): Clean up

**Step 14: Code Quality Assessment**
- Spawn `code-reviewer` (opus): Final quality evaluation

**Step 15: Flow Verification**
- Spawn `architect` (opus): Verify all flows work correctly
- **항상 검증 (백엔드/데이터 흐름)**:
  - 백엔드 내부 흐름 (요청 → 서비스 → 리포지토리 → 응답)
  - 데이터 흐름 (입력 → 변환 → 저장 → 조회 경로)
  - 에러 전파 흐름 (어디서 발생 → 어디서 처리 → 최종 응답)
  - 이벤트/메시지 흐름 (발행 → 소비 → 후속 처리)
- **조건부 검증 (프론트엔드 변경 감지 시)**:
  - UX 흐름 (사용자 액션 → UI 상태 변화)
  - 화면 전환 흐름
  - 폼 제출/검증 흐름

**Step 16: MEDIUM Issue Resolution**
- Spawn `architect` (opus): Process all accumulated MEDIUM issues
- Analyze ripple effects, fix if needed
- Max 3 iterations until stable
- Save: `.omc/memory/unit-{name}/quality-findings.md`

**Step 17: Production Readiness**
- Spawn `architect` + `security-reviewer` (opus, parallel)
- Final checklist: requirements met, build passes, tests pass, no security issues
- Minor: executor fix. Major: → relevant Phase. Critical: → Step 1-B
- Save: `.omc/memory/unit-{name}/final-check.md`

### Integration Stage (after all Units complete)

1. 모든 변경사항은 Startup에서 생성한 worktree의 브랜치에 커밋
2. 브랜치명: `.omc/memory/branch-name.md` 참조
3. If conflict: `architect` (opus) analyzes + `executor` (opus) resolves
4. Full build + test pass verification
5. Save: `.omc/memory/integration-result.md`
- **NOTE**: Draft PR은 이 단계에서 생성하지 않음. Step 19-C 리뷰 완료 후 생성.

### Step 18: Work Report + Review Sequence 준비

- Spawn `writer` (opus)
- Use template: `.omc/workflow/templates/report-template.md`
- **Language:** Follow `language` setting in `.omc/workflow/config.yaml` (default: `ko` for Korean)
- Contents:
  - Before/After flow diagrams
  - Key review points (with code snippets)
  - Trade-offs considered
  - Potential risks
  - Test results explained
  - NOT in scope items
  - Unresolved decisions (with "may bite you later" warnings)
- Save: `.omc/reports/{feature-name}-report.md`

**18-B: Review Sequence 생성**
- Spawn `architect` (opus): 전체 변경사항을 **논리적 변경 단위(Logical Change Unit)**로 그룹핑
- 논리적 변경 단위 = 하나의 목적/기능을 달성하기 위해 함께 변경된 파일들의 묶음
  - 예: "새 서비스 클래스 추가" → `service.py` + `test_service.py` + `constants.py`
  - 예: "기존 커맨드에 새 파라미터 추가" → `command.py` + `test_command.py`
- **정렬 기준**: 데이터/호출 흐름 순서 (상류 → 하류)
  - 예: 모델/상수 정의 → 서비스 로직 → 커맨드/엔트리포인트 → 테스트
- **필수 입력**: `.omc/memory/plan-summary.md`를 읽어 각 변경 단위가 계획의 어떤 Unit/목표에 해당하는지 매핑
- 각 논리적 변경 단위에 포함할 정보:
  - **제목**: 이 변경이 무엇을 하는지 한 줄 요약
  - **계획 매핑**: `plan-summary.md`의 어떤 Unit/목표를 구현한 것인지 (예: "Unit 2: 피드 파싱 로직 구현"의 일부)
  - **변경 이유**: 왜 이 변경이 필요한지
  - **변경 전 상태 (Before Context)**: 변경 전 해당 코드/모듈이 어떤 상태였고 어떤 역할을 하고 있었는지
    - 신규 파일이면: "해당 없음 (신규 생성)"
    - 기존 파일 수정이면: 변경 전 코드의 역할, 동작 방식, 한계점을 설명
  - **변경 내용 (What Changed)**: 구체적으로 어떤 부분을 어떻게 개선/추가했는지
  - **관련 파일 목록**: 변경된 파일과 각 파일의 역할
  - **핵심 코드 변경**: Before/After diff (중요 부분만 발췌)
  - **리뷰 포인트**: 특별히 주의 깊게 봐야 할 부분
  - **다른 변경 단위와의 연관**: 이 변경이 다른 논리적 변경 단위와 어떻게 맞물리는지 (의존/호출/데이터 흐름 관계)
  - **전문가 우려사항 반영**: Step 4-B/7에서 이 변경과 관련된 우려가 있었다면 어떻게 반영했는지
  - **트레이드오프**: 이 변경에서 내린 설계 결정과 그 이유
- Save: `.omc/memory/review-sequence.md` (순서가 있는 리스트)

### Step 19: Interactive Guided Review (인터랙티브 가이드 리뷰)

**목적**: 변경사항을 논리적 흐름 순서대로 하나씩 제시하며, 사용자와 대화형으로 리뷰 진행. 각 변경이 계획의 어디에 해당하고, 기존 코드 대비 어떻게 개선되었는지 풍부한 맥락을 제공.

**19-A: 리뷰 개요 제시 (계획 매핑 기반)**
- `.omc/memory/plan-summary.md`와 `.omc/memory/review-sequence.md`를 함께 읽어 계획-구현 매핑 개요를 구성
- 사용자에게 보여줄 내용:
  - **계획 요약 리마인드**: 원래 계획의 목표와 핵심 요구사항 (1-2문장)
  - **구현 매핑 테이블**: 계획의 각 Unit/목표가 어떤 논리적 변경 단위로 구현되었는지 매핑
    ```
    | 계획 Unit | 구현된 변경 단위 | 핵심 변경 |
    |-----------|-----------------|----------|
    | Unit 1: 피드 모델 정의 | #1 모델 추가, #2 상수 정의 | 새 모델 2개, enum 3개 |
    | Unit 2: 파싱 로직 | #3 파서 구현 | 기존 파서 확장 |
    ```
  - **변경 단위 간 관계도**: 변경 단위들이 어떻게 맞물리는지 흐름 설명
    - 예: "#1에서 정의한 모델을 #3 파서가 사용하고, #4 커맨드가 #3을 호출하여 최종 실행"
    - 데이터/호출 흐름 방향으로 서술
  - **리뷰 진행 순서 안내**: 왜 이 순서로 리뷰하는지 (상류→하류, 기반→활용 등)
- "이 순서로 하나씩 리뷰를 진행하겠습니다" 안내

**19-B: 순차 리뷰 루프 (풍부한 맥락 제공)**
- `.omc/memory/review-sequence.md`에서 순서대로 하나씩 제시
- **각 논리적 변경 단위마다**:
  1. **맥락 제시** (마크다운으로 출력):
     - **계획 매핑**: "이 변경은 계획의 [Unit N: 제목]을 구현합니다"
     - **변경 전 상태 (Before)**:
       - 기존 파일 수정인 경우: 변경 전 코드가 어떤 역할을 하고 있었는지, 동작 방식, 한계점
       - 신규 파일인 경우: "해당 없음 (신규 생성)" + 왜 새 파일이 필요한지
     - **변경 내용 (What We Changed)**: 구체적으로 어떤 부분을 어떻게 개선/추가했는지
     - **핵심 코드 diff**: Before/After (중요 부분 발췌)
     - **다른 변경 단위와의 연관**: 이전/이후 변경 단위와 어떤 관계인지
       - 예: "이 서비스는 #1에서 추가한 모델을 사용하며, #4 커맨드에서 호출됩니다"
     - **리뷰 포인트**: 특별히 주의 깊게 봐야 할 부분
     - **전문가 우려사항 반영**: 관련 우려가 있었다면 어떻게 반영했는지
     - **트레이드오프**: 설계 결정과 그 이유
  2. **AskUserQuestion으로 피드백 수집**:
     - **OK**: 다음 변경 단위로 진행
     - **수정 요청**: 사용자의 피드백을 받아 `executor` (opus)로 즉시 수정 → 수정된 결과를 다시 제시 → 재확인 (max 3회)
     - **질문 있음**: 사용자 질문에 답변 후 다시 OK/수정 요청 선택
  3. 리뷰 결과 기록: `.omc/memory/review-progress.md`에 각 단위의 리뷰 상태 (OK / 수정완료 / 보류) 기록
- **모든 단위 리뷰 완료 후**:
  - 전체 리뷰 요약 출력 (OK 수, 수정된 수, 보류 수)
  - 수정이 있었다면: build + test 재실행하여 통과 확인
  - 보류 항목이 있다면: `.omc/memory/unresolved-decisions.md`에 기록

**19-C: PR 생성 및 최종 마무리**
- 수정이 있었다면 커밋 후 브랜치를 원격에 push
- AskUserQuestion: "모든 리뷰가 완료되었습니다. PR을 생성할까요?"
  - **Draft PR 생성**: `gh pr create --draft` 실행 (base: `{base_branch}`, head: 사용자 브랜치)
  - **Ready PR 생성**: `gh pr create` 실행 (Draft 없이 바로 Ready)
  - **추가 수정 필요**: 19-B로 돌아가 추가 리뷰
- PR 생성 시 Step 18 보고서 내용을 PR description에 포함
- **피드백 영속 기록**: `.omc/memory/feedback.md`에 저장 (세션 종료 후에도 유지)
  - 각 논리적 변경 단위별 피드백 내용, 수정 요청사항, 완료 여부
  - 새 세션에서 `manage-sessions.sh info {branch}`로 확인 가능
- Record in `.omc/memory/retrospective.md` (auto-referenced next run)

### Global Forbidden Rules

NEVER execute any of these under ANY circumstances:
- `git push --force` / `git push -f`
- `git merge` to main/master branch
- `rm -rf`
- `DROP TABLE` / `TRUNCATE`
- Commit `.env` or secret files
- `chmod 777`
- `eval` with untrusted input
- `curl | sh` or `wget | sh`
- `curl`/`wget` to real external endpoints
- `mysql`/`psql`/`redis-cli`/`mongosh` to real databases
- `ssh`/`scp`/`sftp` to real servers
- Any test that calls real DB or external API

### Session Management (세션 관리)

이전 세션을 찾거나, 이어서 작업하거나, 삭제할 때 사용.
스크립트: `.omc/workflow/scripts/manage-sessions.sh`

**사용 가능 명령:**
- `list` - 현재 활성 워크트리(세션) 목록
- `info <branch-name>` - 특정 세션 상세 정보 (커밋, 메모리 파일, 상태)
- `delete <branch-name>` - 세션 삭제 (워크트리 + 브랜치)

**이전 세션 이어서 작업하기:**
1. `bash manage-sessions.sh list`로 세션 목록 확인
2. `bash manage-sessions.sh info {branch}`로 상세 정보 확인
3. 해당 워크트리 경로로 이동하여 작업 계속
4. `.omc/memory/` 파일들을 읽어 이전 작업 맥락 복원

**리뷰 피드백 전달하기:**
1. 사용자가 브랜치명으로 세션을 지정
2. 해당 워크트리로 이동
3. `.omc/memory/feedback.md`에 피드백 기록
4. Step 19 (Retrospective) 플로우를 이어서 실행

### Memory Persistence

Record state at these checkpoints:
- After each Step completion: findings/results
- On agent transition: previous agent's conclusions
- On loop rollback: why and what to fix
- On Unit completion: full unit summary

Always read relevant `.omc/memory/*.md` before starting any step.

### Unresolved Decision Tracking

Throughout all phases, if any decision is left unresolved:
- Record in `.omc/memory/unresolved-decisions.md`
- Include in Step 18 report with "may bite you later" warning
- Never silently default to unstated options
