# Phase A: Planning (Detailed Instructions)

## 목차
- [Step 0: Scope Challenge](#step-0-scope-challenge)
  - [X-Y Problem Detection (P-005)](#x-y-problem-detection-p-005)
  - [Impact-Aware Path Selection (P-001)](#impact-aware-path-selection-p-001)
  - [SMALL Fast Track (P-002)](#small-fast-track-p-002)
- [Step 1-A: Project Analysis + Code Design Analysis](#step-1-a-project-analysis--code-design-analysis)
  - [Search Strategy for Code Exploration (P-013)](#search-strategy-for-code-exploration-p-013)
  - [Agent Team: Code Design Team](#agent-team-code-design-team-explore-medium-완료-후)
  - [통합 검증 명령 탐지 (Feedback Loop 기반)](#통합-검증-명령-탐지-feedback-loop-기반)
  - [사내 자료 맥락 연구 (Design Intent Research)](#사내-자료-맥락-연구-design-intent-research)
- [Step 1-B: Plan Creation](#step-1-b-plan-creation)
  - [AI-First Draft Protocol (P-005)](#ai-first-draft-protocol-p-005)
  - [Interview Guard](#interview-guard)
  - [질문 vs 진행 판단 기준표 (P-006)](#질문-vs-진행-판단-기준표-p-006)
  - [계획서 구조 (STICC Framework)](#계획서-구조-sticc-framework)
- [Steps 2-4: Plan Review (Agent Team)](#steps-2-4-plan-review-agent-team)
  - [Step 2: Plan Review](#step-2-plan-review)
  - [Step 3: Meta Verification](#step-3-meta-verification)
  - [Step 4: Over-engineering Check](#step-4-over-engineering-check)
- [Step 4-B: Expert Plan Review](#step-4-b-expert-plan-review--도메인팀-agent-team-토론)
  - [팀 활성화 규칙](#팀-활성화-규칙-configyaml--expert_panelteam_activation)
  - [통합 전문가 팀 생성](#통합-전문가-팀-생성-agent-teams-제약-세션당-1팀)
  - [도메인별 작업 정의](#도메인별-작업-정의-taskcreate)
  - [토론 로그 저장](#토론-로그-저장-필수)
  - [Findings 품질 원칙 (P-008)](#findings-품질-원칙--깊이--수량-p-008)
  - [Agent Scope Anti-Goals (P-003)](#agent-scope-anti-goals-p-003)
  - [Lead의 Cross-team Synthesis](#lead의-cross-team-synthesis)
- [Phase A Calibration Checklist](#phase-a-calibration-checklist-phase-b-진입-전-검증)

### Phase A Progress Pulse

Phase A에서 Agent Team 토론이나 Expert Review가 진행되는 동안, 사용자에게 1줄 진행 상태를 출력한다. AskUserQuestion이 아닌 단순 텍스트 출력으로, 사용자 흐름을 중단시키지 않되 가시성을 확보한다.

출력 형식:
```
[Phase A] Code Design Team 토론 시작 (convention, idiom, design-pattern, testability)
[Phase A] Code Design Team 합의 완료 — code-design-analysis.md 저장
[Phase A] Plan Review 시작 (planner ↔ critic, max 3 iterations)
[Phase A] Plan Review 2/3 완료 — Completeness 4, Feasibility 5, Safety 4, Clarity 3
[Phase A] Expert Review 시작 (Safety + Code Design + auto-detect 팀)
[Phase A] Expert Review 완료 — CRITICAL 0, HIGH 2, MEDIUM 7
```

각 Agent Team 생성/해산, 토론 완료, 주요 checkpoint에서 해당 형식의 1줄을 출력한다.

## Step 0: Scope Challenge

- Spawn `architect`: Analyze git history for past problem areas
- Identify "What already exists" - existing code that solves parts of the request
- Determine minimum viable change
- Flag if scope exceeds 8 files or 2 new classes
- Present 3 review paths to user via AskUserQuestion:
  - **SMALL**: Steps 5-8 + 17 only
  - **STANDARD**: Steps 5-17 full pipeline
  - **LARGE**: Steps 5-17 + extended failure mode analysis
- **ship 모드 자동 결정**: ship 모드에서는 이 AskUserQuestion을 생략하고, AI가 변경 파일 수 기준으로 자동 선택한다 (3개 이하→SMALL, 10개 이하→STANDARD, 그 이상→LARGE)
- Record decision in `.claude/memory/plan-summary.md`

### X-Y Problem Detection (P-005)

사용자가 특정 구현 방법을 요청할 때 ("Redis를 추가해줘", "캐시 레이어를 넣어줘"), 먼저 근본 목적을 확인한다:
- "이 변경으로 해결하려는 실제 문제가 무엇인가요?" (1회만 질문)
- 사용자의 답변에서 요청(Y)과 실제 문제(X)의 불일치가 감지되면:
  - `[X-Y 감지] {Y} 요청이지만, 실제 문제는 {X}인 것 같습니다. {Y'} 대안이 더 적합할 수 있습니다.`
- 사용자가 원래 요청을 고수하면 그대로 진행 (강제하지 않음)

### Impact-Aware Path Selection (P-001)

`config.yaml`에 `high_impact_paths`를 정의한다:

```yaml
high_impact_paths:
  - "auth/**"
  - "crypto/**"
  - "migration/**"
  - "middleware/security*"
```

변경 파일이 `high_impact_paths`에 매칭되면, 변경량이 SMALL이더라도 최소 STANDARD 경로를 강제한다. 보안·인증·마이그레이션 관련 코드는 단순 변경이라도 영향 범위가 크기 때문이다.

### SMALL Fast Track (P-002)

Step 0에서 SMALL로 판별 시 Phase A를 압축 실행한다:
- Step 1-A: 구조 스캔만 (Code Design Team skip)
- Step 1-B: AI-First Draft 방식으로 간결 계획서 작성 (Task + End State만). 사용자 인터뷰는 초안 교정 1회로 축소
- Steps 2-4: 단일 critic subagent 1회 리뷰로 통합 (Agent Team 미생성)
- Step 4-B: Safety + Code Design always 멤버만 경량 리뷰
- 사용자 인터랙션: Step 0+1-B 통합, Expert Review CRITICAL만 확인 (총 2회)

### Phase A Common Rationalizations

| 합리화 | 현실 |
|--------|------|
| "스펙이 명확하니까 Step 0은 건너뛰자" | Scope Challenge가 SMALL/STANDARD/LARGE를 결정한다. 건너뛰면 과도한 파이프라인을 돌리거나 필요한 검증을 누락한다 |
| "코드를 보면 아니까 인터뷰는 필요 없다" | 비즈니스 결정(우선순위, 제약, 의도)은 코드에 없다. Interview Guard를 따른다 |
| "계획은 대충 써도 구현하면서 맞추면 된다" | plan-summary.md가 불완전하면 executor가 임의로 해석한다. Done-When Checks가 없으면 Step 17에서 완료 판정이 불가능하다 |
| "Expert Review까지는 과하다" | CRITICAL 이슈는 구현 후 발견하면 재작업 비용이 10배다. Phase A에서 잡는 것이 가장 싸다 |

## Step 1-A: Project Analysis + Code Design Analysis

- Spawn `explore-medium`: Scan project structure
- Spawn `analyst`: Generate analysis report + recommend principles
- Use Context7 MCP (`resolve-library-id` → `query-docs`) for library docs — **Docs-First Protocol**: 기술 스택의 설정·마이그레이션·플러그인에 대해 학습 데이터 기반 기억이 아닌 공식 문서에서 확인한 정보를 사용한다. 조회 불가 시 기억으로 추측하지 않고 사용자에게 직접 확인을 요청한다.
- Auto-generate allowed command list based on detected stack
- Use subagent for deep codebase exploration if codebase is large
- **Auto-detect experts**: 스캔 결과를 `config.yaml`의 `expert_panel.specialists[].detect` 키워드와 매칭하여 활성화할 전문가 목록 결정

### Search Strategy for Code Exploration (P-013)

코드베이스 탐색 에이전트(explore-medium, analyst 등)는 다음 검색 전략을 따른다. grep 단일 검색은 문자열만 매칭하므로 관련성 있는 코드를 놓칠 수 있다.

1. **Structural scan first**: Glob으로 디렉토리 구조를 파악하고, 도메인 경계(DDD layers, 모듈 분리)를 식별한다
2. **Multi-term search**: 하나의 개념에 대해 동의어/관련어로 다중 검색한다
   - 예: "authentication" 탐색 시 → "auth", "login", "session", "token", "jwt", "credentials"로도 검색
   - 예: "payment" 탐색 시 → "billing", "charge", "invoice", "transaction"으로도 검색
3. **Pattern-based search**: 하나의 인스턴스를 발견하면, 동일 패턴이 코드베이스에 다른 곳에도 있는지 검색하여 일관성을 확인한다 ("이것이 유일한 구현인가, 변형이 있는가?")
4. **Reference chain traversal**: 관련 파일을 찾으면 import/importer를 추적하여 변경 영역의 의존성 그래프를 구축한다
5. **NEVER 단일 검색으로 결론**: 검색 결과 0건이면 다른 용어로 최소 2회 재시도한 후에 "존재하지 않는다"고 결론낸다
6. **Data-layer traversal scan (해당 시)**: 새 필드를 여러 레이어에 걸쳐 추가하는 경우, 기존 유사 필드 1개를 선정하여 전체 코드베이스를 grep한다. 결과를 쓰기 경로 / 읽기 경로 / 변환 레이어 / 스키마로 분류하고, 분류된 모든 파일을 plan-summary.md Files Changed에 포함한다.

### Agent Team: Code Design Team (explore-medium 완료 후)

- `config.yaml`의 `expert_panel.domain_teams.code-design` 참조
- 목적: 레포의 코드 설계 컨텍스트를 사전 분석하여 이후 모든 단계에서 활용

> **Agent Teams Fallback**: Agent Teams 미활성 시 `agent-teams.md`의 Fallback 절차를 따른다.

**1) 팀 생성**: `TeamCreate(team_name="code-design", description="코드 설계 분석 팀")`

**2) 작업 정의** (`TaskCreate`):
- Task "분석": "각자 도메인별 레포 분석 → findings 작성" (`activeForm="레포 분석 중"`)
- Task "토론": "다른 팀원의 findings를 읽고 직접 메시지로 토론" (`addBlockedBy=["분석"]`, `activeForm="패턴 토론 중"`)
- Task "합의": "팀 합의 도출 → .claude/memory/code-design-analysis.md 작성" (`addBlockedBy=["토론"]`, `activeForm="합의문 작성 중"`)

**3) 팀원 spawn** (병렬, `team_name="code-design"`):
- `Agent(name="convention-expert")` (always)
  — 네이밍 규칙, 디렉토리 구조, 에러 핸들링 패턴, import 순서, CLAUDE.md / .editorconfig / linter 설정, 유사 기능 기존 구현체 탐색
- `Agent(name="idiom-expert")` (always)
  — Context7 MCP로 프레임워크/라이브러리 공식 문서 조회, 언어 공식 가이드, 프레임워크 권장 패턴 및 anti-pattern
- `Agent(name="design-pattern-expert")` (auto-detect)
  — Clean Architecture / Layered / Hexagonal 등 식별, 의존성 방향, 인터페이스 사용 패턴
- `Agent(name="testability-expert")` (auto-detect)
  — 기존 테스트 구조, mock/fixture 패턴 파악

**4) 팀원 자율 운영**: 팀원들이 TaskList에서 작업을 claim하고, SendMessage로 직접 토론

**5) 팀 해산**: 모든 팀원에게 `SendMessage(type="shutdown_request")` → `TeamDelete()`

### 통합 검증 명령 탐지 (Feedback Loop 기반)

프로젝트의 기존 빌드/린트/테스트 통합 검증 수단을 파악하여 이후 모든 단계에서 빠른 피드백 루프로 활용한다.
AI의 실수를 가장 빠르게 잡아내는 것은 자동화된 검증이다. 이 단계에서 검증 명령을 파악해두면, 이후 매 구현 단계에서 즉각적인 피드백을 받을 수 있다.

탐지 대상:
- `Makefile` / `justfile` / `taskfile.yml` — `make verify`, `make test`, `make lint` 등
- `package.json` scripts — `npm test`, `npm run lint`, `npm run build`
- CI 설정 (`.github/workflows/`, `.gitlab-ci.yml`) — CI에서 실행하는 검증 명령
- 프로젝트 `README.md`의 개발 가이드

파악한 명령을 `.claude/memory/verify-commands.md`에 기록:
```markdown
## 통합 검증 명령
- Build: `make build` / `go build ./...`
- Test: `make test` / `go test ./...`
- Lint: `make lint` / `golangci-lint run`
- Typecheck: (해당 시)
- Coverage: `go test -coverprofile=coverage.out ./...` / `pytest --cov` (해당 시)
- All-in-one: `make verify` (있으면)
```

- Save: `.claude/memory/requirements.md`, `.claude/memory/code-design-analysis.md`, `.claude/memory/verify-commands.md`

### 실행 환경 스냅샷 (env-context.md)

탐지한 환경 정보를 `.claude/memory/env-context.md`에 기록한다. "문서는 맞지만 환경이 달라 실패"하는 환경 맹점 패턴을 Phase B 구현 전에 해소하기 위함이다.

```bash
# 자동 수집 (verify-commands.md 생성 직후 실행)
{
  echo "OS: $(uname -sr)"
  echo "Runtime: $(go version 2>/dev/null || node --version 2>/dev/null || python --version 2>/dev/null || echo 'unknown')"
  echo "Docker: $(docker info --format '{{.ServerVersion}}' 2>/dev/null || echo 'not running')"
  echo "Key ENV:"
  env | grep -E 'APP_ENV|DB_HOST|REDIS_URL|SERVICE_URL|DATABASE_URL' 2>/dev/null | head -10 || echo "(none detected)"
} > .claude/memory/env-context.md
```

환경 정보가 코드 동작에 영향을 줄 수 있는 경우(feature flag, 외부 서비스 URL 등) 추가 항목을 수동으로 기록한다. executor subagent에게 Unit Runbook과 함께 env-context.md를 전달하여 "환경 맹점" 패턴을 방지한다.

### Gotchas Registry 로딩

`~/.claude/projects/{slug}/state/gotchas.jsonl`이 존재하면 로딩하여 `code-design-analysis.md`에 "Known Gotchas" 섹션으로 포함한다 — 이 프로젝트에서 Claude가 반복적으로 잘못하는 패턴을 사전에 인지하여 동일 실수를 방지한다. gotchas는 프로젝트별로 세션을 거듭하며 축적되는 가장 가치 높은 콘텐츠이다.

```bash
# 로딩 예시
jq -r '.gotcha' gotchas.jsonl 2>/dev/null | head -20
```

executor에게 전달되는 Unit Runbook에도 관련 gotchas를 카테고리로 필터링하여 "주의사항"에 추가한다.

### Structured Research Protocol (Step 1-A)

explore-medium과 analyst에게 다음 리서치 프레임워크를 적용한다. 단일 가설 확인 패턴(하나의 해석을 세우고 뒷받침 증거만 모으는 것)은 확인 편향을 일으키기 때문이다.

**1. 초기 가설 생성 (2-3개)**
프로젝트 구조 초기 스캔 후, 아키텍처/패턴에 대한 경쟁 가설을 수립한다.
예:
- H1: "Clean Architecture (의존성 역전 적용)" — 신뢰도: 0.4
- H2: "Layered Architecture (전통적 N-tier)" — 신뢰도: 0.3
- H3: "혼합 (모듈별 상이한 패턴)" — 신뢰도: 0.3

**2. 증거 수집 (각 가설에 대해)**
각 가설을 지지하는 증거와 반박하는 증거를 의도적으로 탐색한다.
수집 후 각 가설의 신뢰도를 갱신한다.

**3. 자기 비판**
"내 현재 최고 신뢰도 가설에서 가장 약한 부분은 무엇인가?"를 자문하고, 그 약점을 검증할 추가 탐색을 수행한다.

**4. 조사 노트 기록**
`.claude/memory/research-notes.md`에 가설, 증거, 신뢰도 변화를 기록:

| 가설 | 초기 신뢰도 | 지지 증거 | 반박 증거 | 최종 신뢰도 |
|------|-----------|----------|----------|-----------|

### 사내 자료 맥락 연구 (Design Intent Research)

코드 탐색과 가설 수립 이후, 코드만으로 설계 의도를 파악하기 어려운 경우에 사내 자료를 추가 탐색한다. 코드는 "무엇을 하는지"를 보여주지만, "왜 이렇게 만들었는지"는 RFC, Slack 논의, 커밋 히스토리에 있다. 이 맥락 없이 구현하면 원래 설계 의도에 반하는 코드를 작성하거나, 이미 검토·폐기된 대안을 다시 시도하는 낭비가 발생한다.

**트리거 조건** — 다음 중 하나에 해당하면 수행:
- 코드에 비직관적인 패턴이 있고 그 이유를 코드만으로 추론할 수 없을 때
- 변경 대상이 여러 서비스/모듈에 걸치는 cross-cutting concern일 때
- 기존 코드에 주석·TODO로 설계 결정이 언급되지만 맥락이 불충분할 때
- Structured Research Protocol에서 가설 간 신뢰도 차이가 좁아 판별이 어려울 때

**리서치 수단:**

Confluence — RFC, 설계 문서, 기술 결정 기록:
```bash
~/.claude/skills/buzzvil-confluence/scripts/search.sh -q "검색어" -s DEM -f
~/.claude/skills/buzzvil-confluence/scripts/search.sh -q "검색어" -s DEM -l rfc -f
```

Slack — 당시 논의, 의사결정 맥락:
```bash
~/.claude/skills/buzzvil-slack/scripts/search.sh -q "검색어" -c dev-demand
~/.claude/skills/buzzvil-slack/scripts/fetch_thread.sh "https://buzzvil.slack.com/archives/..."
```

Git history — 관련 코드의 변경 이력과 커밋 메시지:
```bash
git log --oneline --all --grep="키워드" | head -10
git blame -L start,end file_path
```

**검색 키워드 선정:**
- 코드에서 발견된 핵심 키워드 (기능명, 모듈명, 패턴명)
- Structured Research Protocol에서 수립한 가설의 핵심 개념
- git blame으로 발견된 관련 커밋 메시지의 키워드

**결과 통합:**
- 발견한 설계 의도/맥락을 `code-design-analysis.md`의 "Design Context" 섹션에 추가
- 반드시 출처 링크 포함 (Confluence URL, Slack permalink, 커밋 해시)
- 발견한 맥락이 구현 계획과 충돌하면 plan-summary.md의 Concerns에 "설계 충돌" 항목으로 반영
- 이미 검토·폐기된 대안이 발견되면 plan-summary.md의 "NOT in scope"에 근거와 함께 기록

## Step 1-B: Plan Creation

- Spawn `planner` in interview mode
- Input: User request + Step 0 scope + Step 1-A analysis + `.claude/memory/code-design-analysis.md`
- Split work into Units: max 3-5 files, 200 lines per Unit, single concern
- Build dependency graph: parallel vs sequential groups
- Use Context7 for SDK documentation needed for implementation

### Step 1-B Interview Gating (Inversion Pattern)

인터뷰를 3-Phase 구조로 진행한다. 각 Phase에 gate를 두어 불완전한 상태에서 다음으로 넘어가지 않는다.

| Phase | 목적 | 완료 조건 (Gate) | AI-First Draft 적용 |
|-------|------|-----------------|-------------------|
| 1. AI-First Draft | plan-summary.md 초안 생성 | 6개 필수 섹션(Situation/Task/Intent/Concerns/AC/End State) 존재 | AI가 초안 생성 |
| 2. User Correction | 사용자 교정 | 사용자 응답 수신 (ship 모드: auto-skip) | 사용자가 교정 |
| 3. Residual Interview | 미해결 비즈니스 결정 해소 | 미해결 항목 == 0 OR 사용자가 "진행" 선택 | 미해결 항목 기반 질문만 |

각 Phase 시작 시: `[Interview Phase {N}/3] {Phase명}`
각 Phase 완료 시: `[Interview Phase {N}/3 완료] {Gate 충족 요약}`
**EXPLICIT GATE: 미해결 비즈니스 결정이 존재하면 Step 2(Plan Review)로 진행하지 않는다.**

### AI-First Draft Protocol (P-005)

사용자가 처음부터 답하는 것보다, AI가 초안을 제시하고 사용자가 교정하는 것이 더 빠르고 정확하다.

1. Step 1-A 분석 + 사용자 요청에서 계획서 초안을 먼저 작성한다
2. 초안을 사용자에게 제시: "이 계획으로 진행할까요? 수정할 부분이 있으면 알려주세요."
3. 사용자는 빈 칸을 채우는 대신, 잘못된 부분만 교정한다
4. 교정 후 인터뷰는 미해결 항목(비즈니스 결정, 트레이드오프)에만 집중한다
5. **ship 모드 자동 결정**: ship 모드에서는 AI-First Draft를 교정 없이 확정한다. 사용자에게 초안을 제시하지 않고, Decision Journal에 "ship 모드: AI-First Draft 자동 확정"을 기록한 후 즉시 다음 단계로 진행한다

이 방식은 인터뷰 라운드를 줄이고, 사용자의 인지 부담을 낮추며, 더 정확한 계획서를 빠르게 도출한다.

### Contrastive Self-Check (CP-001)

planner가 AI-First Draft를 생성한 직후, 사용자에게 제시하기 전에 다음을 수행한다. "그럴듯해 보이지만 잘못된 계획"이 critic-planner 루프까지 올라가는 것을 사전에 방지하기 위함이다.

**Step A** — 이 계획이 성공할 가장 강한 이유 3가지 (정답 근거):
1. 요구사항 충족 근거
2. 코드베이스 패턴 일치 근거
3. Unit 분할의 의존성 그래프 부합 근거

**Step B** — 이 계획이 실패할 가장 강한 이유 2가지 (Contrastive Anchors):
1. 숨겨진 의존성이나 누락된 파일 변경이 있다면?
2. 요구사항의 어떤 부분이 계획에서 누락되었다면?

Step B의 항목이 타당하면 초안을 수정한 후 사용자에게 제시한다. 수정 후에도 해소되지 않으면 Concerns/Unresolved decisions에 포함한다. plan-summary.md에 `## Contrastive Anchors` 섹션으로 기록하여 Step 2 critic이 antipattern 대조 검증 시 활용한다.

**SMALL 경로**: Step B를 1문장 요약으로 제한하여 Fast Track의 간결성을 유지한다.

### Interview Guard

- 코드를 먼저 충분히 탐색한 뒤, 코드에서 답할 수 있는 질문은 하지 않는다
- Step 0 scope + Step 1-A 분석 결과에서 이미 파악된 정보를 다시 묻지 않는다
- 사용자에게는 비즈니스 결정, 엣지케이스, 스코프 경계, 트레이드오프만 질문한다

### Interview Anti-patterns (금지)

- BAD: "이 프로젝트는 어떤 프레임워크를 사용하나요?" → code-design-analysis.md에서 확인 가능
- BAD: "테스트는 어떤 구조로 작성하나요?" → 기존 테스트 파일에서 확인 가능
- BAD: (교정 완료 후) "혹시 다른 요구사항이 있나요?" → 열린 질문 금지, 미해결 항목 기반으로만 질문
- OK: "로그인 실패 시 5회 제한은 연속 실패인가요, 누적 실패인가요?" → 비즈니스 결정
- OK: "결제 실패 시 사용자에게 즉시 알림을 보내야 하나요, 재시도 후 알림인가요?" → 비즈니스 결정

#### 질문 vs 진행 판단 기준표 (P-006)

| 판단 | 기준 | 예시 |
|------|------|------|
| **코드에서 확인 → 진행** | 기술적 사실, 기존 구현 패턴 | 프레임워크 버전, 디렉토리 구조, 에러 핸들링 패턴, import 경로, DB 스키마, 기존 API 스펙 |
| **사용자 확인 → 질문** | 비즈니스 의도, 트레이드오프 선택 | 엣지케이스 동작, 성능 vs 단순성 트레이드오프, 인증 방식 선택, 외부 연동 범위, 사용자 시나리오 우선순위 |
| **추론 가능 → 진행 + 통보** | 코드와 요청에서 높은 확률로 추론 가능 | 네이밍 규칙 (기존 패턴 따르기), 테스트 전략 (기존 구조 따르기), 에러 메시지 문구 |

**원칙:** "이 정보를 코드에서 5분 안에 확인할 수 있는가?" → Yes이면 묻지 않고 확인한다. "이 결정의 결과가 사용자의 비즈니스에 영향을 미치는가?" → Yes이면 반드시 질문한다.

### 계획서 구조 (STICC Framework)

계획서(`plan-summary.md`)는 다음 구조를 따른다. 단, 계획서에 "STICC"라는 메타 텍스트를 포함하지 않는다.

**1. Situation (현재 상태)**:
- 현재 시스템의 관련 부분이 어떤 상태인지
- 왜 이 작업이 필요한지 (배경, 문제점, 기회)

**2. Task (구체적 작업)**:
- Unit 분할 (max 3-5 files, 200 lines per Unit, single concern)
- 각 Unit별 변경 대상 파일 목록 (파일 경로 + 변경 유형: 신규/수정/삭제)
- Implementation order (dependency graph: parallel vs sequential)
- Development principles (TDD/DDD/Clean Architecture as confirmed)

**3. Intent (의도와 목적)**:
- 이 작업이 달성하려는 근본적 목적 (단순히 "뭘 하는지"가 아니라 "왜 하는지")
- 성공 기준: 이 작업이 완료되면 시스템이 어떤 상태가 되어야 하는지

**4. Concerns (우려사항과 리스크)**:
- Expected risks
- "NOT in scope" section (명시적으로 하지 않을 것)
- "Unresolved decisions" section (결정되지 않은 사항)

**5. Acceptance Criteria (인수 기준)** — 4개 하위 섹션으로 분할:
- **Code Changes**: 구현해야 할 코드 변경사항 목록
- **Tests**: 작성/수정해야 할 테스트 목록 (파일 패턴 수준)
- **Quality Gates**: 통과해야 할 품질 기준 (build, typecheck, lint, 특정 성능 기준 등)
- **Done-When Checks**: 각 Unit별 완료 판정 기준. 2계층(Mechanical + Behavioral)으로 구성한다.

  **Mechanical Checks** — 기계적으로 검증 가능한 조건. `verify-commands.md` 기반:
  ```
  ## Unit: {name}
  ### Mechanical Checks
  - [ ] 빌드 성공 (verify-commands.md의 Build 명령)
  - [ ] 해당 Unit 테스트 전체 통과 (verify-commands.md의 Test 명령, 대상 경로 필터)
  - [ ] 린트/타입체크 통과 (verify-commands.md의 Lint/Typecheck 명령)
  - [ ] 테스트 커버리지 ≥ 80% (verify-commands.md의 Coverage 명령, 해당 시)
  - [ ] plan-summary.md의 해당 Unit Code Changes 항목 전부 구현 확인
  ```

  **Behavioral Checks** — 기능의 실제 동작을 검증하는 행동적 수용 기준. "빌드 통과 ≠ 기능 동작" gap을 구조적으로 해소한다. 각 항목은 **Trigger + Observable + Verify Command** 3요소를 필수로 포함한다:
  ```
  ### Behavioral Checks
  - [ ] {Trigger: 어떤 입력/조건} → {Observable: 기대 결과}
        verify: {실행 가능한 검증 명령}
  ```
  예시:
  ```
  ### Behavioral Checks
  - [ ] POST /login (잘못된 비밀번호) → 401 + "Invalid email or password"
        verify: curl -s -o /dev/null -w "%{http_code}" -X POST localhost:3000/api/login -d '{"email":"test@test.com","password":"wrong"}'
  - [ ] POST /login (올바른 비밀번호) → 200 + Set-Cookie 헤더 존재
        verify: curl -s -D - -X POST localhost:3000/api/login -d '{"email":"test@test.com","password":"correct"}' | grep Set-Cookie
  ```

  **Behavior Changes → Behavioral Checks 변환 규칙**: End State의 Behavior Changes(Before → After) 각 항목을 Behavioral Check 후보로 자동 변환한다. 모든 Behavior Change가 Behavioral Check가 되어야 하는 것은 아니지만, 변환 가능한 항목은 반드시 Done-When에 포함한다.

**6. End State (최종 상태 명세)** — 구현 전에 "완료"의 모습을 구체적으로 정의:
- **Files Changed 테이블**:
  ```
  | File | Action | Summary |
  |------|--------|---------|
  | path/to/file.py | 신규 | 새 서비스 클래스 |
  | path/to/existing.py | 수정 | 기존 핸들러에 새 분기 추가 |
  ```
- **Behavior Changes**: Before → After 형식으로 동작 변화 명세
- **Test Targets**: 테스트 대상 파일 패턴

**Files Changed 테이블 작성 예시 (좋은 예)**:
```
| File | Action | Summary |
|------|--------|---------|
| internal/pacing/service.go | 신규 | 예산 페이싱 로직을 담당하는 PacingService 구현 |
| internal/pacing/service_test.go | 신규 | PacingService 단위 테스트 (경계값, 에러 케이스 포함) |
| internal/handler/campaign.go | 수정 | POST /campaigns 핸들러에 PacingService 의존성 주입 + 페이싱 활성화 분기 추가 |
| internal/handler/campaign_test.go | 수정 | 페이싱 활성화/비활성화 시나리오 테스트 추가 |
| internal/model/campaign.go | 수정 | Campaign 구조체에 PacingEnabled, DailyBudget 필드 추가 |
| db/migrations/20260305_add_pacing.sql | 신규 | campaigns 테이블에 pacing_enabled, daily_budget 컬럼 추가 |
```
각 파일에 대해 구체적인 변경 내용을 한 문장으로 설명한다. "수정"이라고만 적지 않고 무엇을 수정하는지 명시한다.

#### Unit 파싱 마커

plan-summary.md의 각 Unit 섹션에 CLI 파싱을 위한 표준 마커를 포함한다. 이 마커를 사용하면 `sed -n '/<!-- UNIT:unit-1 START -->/,/<!-- UNIT:unit-1 END -->/p' plan-summary.md`로 특정 Unit의 전체 내용을 정확하게 추출할 수 있어, CLI 스크립트의 plan-summary.md 파싱 안정성이 보장된다.

```markdown
<!-- UNIT:unit-1 START -->
## Unit 1: {제목}
...
### Files Changed
...
### Done-When Checks
...
<!-- UNIT:unit-1 END -->
```

- Save to `.claude/memory/plan-summary.md`
- Use subagent with planner role for plan creation

### Spec Validation — AC 사용자 시나리오 확인 (STANDARD+ 경로)

Step 1-B 완료 후, 기술 용어로 작성된 AC가 사용자의 실제 의도와 일치하는지 확인한다. "spec이 처음부터 틀리면 모든 검증이 무의미"하기 때문이다.

- **트리거**: STANDARD+ 경로에서만 적용. SMALL 경로는 skip
- **절차**:
  1. `spec-validator` subagent (model: sonnet)가 plan-summary.md의 Acceptance Criteria(특히 Behavioral Checks)를 **구체적 사용자 시나리오**로 번역
  2. 기술 용어를 사용자가 이해할 수 있는 언어로 변환
  3. 사용자에게 AskUserQuestion으로 확인 요청

- **변환 예시**:
  - 기술 AC: `POST /api/auth/login에 invalid credentials → 401 + {error: 'INVALID_CREDENTIALS'}`
  - 사용자 시나리오: "로그인 화면에서 틀린 비밀번호를 입력하고 '로그인' 버튼을 누르면, 화면에 'INVALID_CREDENTIALS'라는 에러 코드가 표시됩니다. 이게 맞나요?"

- **결과 처리**:
  - 사용자 "맞다" → Phase A 이후 단계로 진행
  - 사용자 "아니다" / 수정 요청 → AC 수정 후 plan-summary.md 갱신

## Steps 2-4: Plan Review (Agent Team)

> **Agent Teams Fallback**: Agent Teams 미활성 시 `agent-teams.md`의 Fallback 절차를 따른다.

**팀 생성**: `TeamCreate(team_name="plan-review", description="계획 리뷰 팀")`
- 컨텍스트: `.claude/memory/plan-summary.md`, `.claude/memory/requirements.md`, `.claude/memory/code-design-analysis.md`

**팀원 spawn** (병렬, `team_name="plan-review"`):
- `Agent(name="planner")` — plan 수정/방어 담당
- `Agent(name="critic")` — 논리/실현성 검증 담당
- `Agent(name="architect")` — 구조 검증 + YAGNI/KISS 검증 담당

### Step 2: Plan Review
- Task "plan-review": critic ←→ planner 직접 토론 (`SendMessage`로)
- Max 3 iterations (config `loop_limits.critic_planner`)
- **품질 기반 조기 종료**: critic이 매 iteration 종료 시 4개 축을 1-5점으로 평가한다:
  - **Completeness** (요구사항 커버리지)
  - **Feasibility** (기술적 실현 가능성)
  - **Safety** (보안/안정성 리스크 관리)
  - **Clarity** (계획서 명확성, 모호함 없음)
  - 모든 항목 4점 이상이면 남은 iteration 없이 조기 종료한다
  - 평가 결과를 `.claude/memory/plan-review-scores.md`에 기록한다

### Step 3: Meta Verification
- Task "meta-verify" (`addBlockedBy=["plan-review"]`): architect가 critic의 리뷰를 cross-verify
- Severity-based routing:
  - Minor (detail-level): → Step 2 task 재생성
  - Major (structural): → lead에게 보고 → Step 1-B (with failure reason)

### Step 4: Over-engineering Check
- Task "yagni-check" (`addBlockedBy=["meta-verify"]`): architect가 YAGNI/KISS 관점으로 plan 검증
- architect ←→ planner 직접 토론으로 합의 도출
- Severity-based routing: Minor → Step 2, Major → Step 1-B

**Step 4 완료 시**: 모든 팀원에게 `SendMessage(type="shutdown_request")` → `TeamDelete()`
- Steps 2-4 are executed as a combined plan review cycle

## Step 4-B: Expert Plan Review — 도메인팀 Agent Team 토론

- 목적: 구현 전에 도메인 전문가들이 **팀 내 토론**을 통해 우려사항/위험요소를 사전에 식별
- `config.yaml`의 `expert_panel` 섹션 참조
- Read expert prompts from `.claude/workflow/prompts/*.md`

### 팀 활성화 규칙 (`config.yaml` → `expert_panel.team_activation`)

- SMALL path: Safety Team + Code Design Team (always 멤버만: appsec, stability, convention, idiom)
- STANDARD path: Safety + Code Design (always) + auto-detect된 Data/Integration/Ops 팀
- LARGE path: 전체 + extended failure mode analysis

### 통합 전문가 팀 생성 (Agent Teams 제약: 세션당 1팀)

> **Agent Teams Fallback**: Agent Teams 미활성 시 `agent-teams.md`의 Fallback 절차를 따른다.

`TeamCreate(team_name="expert-review", description="도메인 전문가 통합 리뷰 팀")`

팀원 spawn (병렬, `team_name="expert-review"`):

**Data Team** (min_active 2, auto-detect):
- `Agent(name="rdbms-expert")`, `Agent(name="cache-expert")`, `Agent(name="nosql-expert")`

**Integration Team** (min_active 2, auto-detect):
- `Agent(name="sync-api-expert")`, `Agent(name="async-expert")`, `Agent(name="external-integration-expert")`, `Agent(name="messaging-expert")`

**Safety Team** (always — appsec + stability 항상 활성):
- `Agent(name="appsec-expert")`, `Agent(name="auth-expert")`, `Agent(name="infrasec-expert")`, `Agent(name="stability-expert")`

**Ops Team** (min_active 2, auto-detect):
- `Agent(name="infra-expert")`, `Agent(name="observability-expert")`, `Agent(name="performance-expert")`, `Agent(name="concurrency-expert")`

**Code Design Team** (always — convention + idiom 항상 활성):
- `Agent(name="convention-expert-review")`, `Agent(name="idiom-expert-review")`, `Agent(name="design-pattern-expert-review")`, `Agent(name="testability-expert-review")`
- Step 1-A의 `.claude/memory/code-design-analysis.md` 활용

### 도메인별 작업 정의 (`TaskCreate`)

각 도메인팀별 3단계:
- Task "{도메인}-분석": plan-summary.md 검토 → 도메인별 findings 작성
- Task "{도메인}-토론": 다른 팀원의 findings 읽고 직접 토론 (`addBlockedBy=["{도메인}-분석"]`)
- Task "{도메인}-합의": 팀 합의 → 도메인별 findings.md (CRITICAL/HIGH/MEDIUM severity) (`addBlockedBy=["{도메인}-토론"]`)

### 토론 로그 저장 (필수)

팀원 prompt에 다음 규칙을 포함:
> "토론 시 핵심 논점과 결론을 `.claude/memory/expert-discussions/{도메인}-discussion.md`에 기록하세요."

기록 형식:
```markdown
## [우려 ID]: [한줄 요약]
- [전문가A → 전문가B]: 논점 요약
- [전문가B → 전문가A]: 반박/동의 요약
- [합의]: 최종 결론 + severity + 근거
```

### Cross-Examiner Protocol (CP-006)

도메인팀 합의 완료 후, CRITICAL/HIGH findings에 대해 전담 `cross-examiner` 에이전트가 청문회식 반증을 수행한다. Finding 제기자가 자신의 finding을 반증하면 형식적 반론으로 전락할 수 있으므로, 독립 에이전트가 전담하여 Cognitive Independence를 보장한다.

**절차**:
1. 도메인팀 합의 완료 후, CRITICAL/HIGH findings 목록을 수집
2. `cross-examiner` subagent를 spawn하여 각 finding에 대해:
   - "이 concern이 과도하게 평가되었을 반증"을 코드 근거(Read/Grep) 기반으로 탐색
   - 반증의 최소 요건: 코드에서 확인 가능한 근거 1개 이상
3. 반증이 성공한 finding은 architect에게 severity 재검토를 제안
4. 결과를 `expert-plan-concerns.md`의 해당 finding에 `cross_examination` 필드로 추가

**예외**: 수학적으로 명확한 버그(SQL injection 직접 concatenation, 하드코딩된 비밀번호 등)에는 Cross-Examiner를 적용하지 않는다 — 반증의 여지가 없는 명백한 결함에 자원을 낭비하지 않기 위함이다.

**SMALL 경로**: Cross-Examiner를 skip하고 기존 경량 리뷰를 유지한다.

### Findings 품질 원칙 — "깊이 > 수량" (P-008)

각 전문가 에이전트 prompt에 다음 품질 원칙을 포함:
> 각 finding은 (1) 구체적 코드 위치, (2) 왜 문제인지, (3) 영향 범위를 포함한다.
> 구체적 근거가 있는 5건이 모호한 설명의 20건보다 낫다.

<finding_quality_examples>
**Good finding** (구체적, 검증 가능):
- 코드 위치: `internal/auth/handler.go:47` — `ValidateToken()` 함수
- 문제: JWT 서명 검증 없이 payload를 디코딩하여 사용. 공격자가 변조된 토큰으로 다른 사용자의 세션에 접근 가능
- 영향 범위: `/api/protected/*` 하위 모든 엔드포인트 (현재 12개)
- severity: CRITICAL

**Bad finding** (모호, 검증 불가):
- 코드 위치: auth 모듈
- 문제: 인증 처리가 불안전할 수 있음
- 영향 범위: 시스템 전반
- severity: HIGH

**Scope 밖 finding** (변경하지 않는 코드에 대한 일반 조언 — 작성하지 않는다):
- 코드 위치: `internal/user/repository.go:15`
- 문제: 기존 코드에 에러 래핑이 없음 (이번 변경과 무관)
- → git diff 대상 파일만 검토한다.
</finding_quality_examples>

**Self-Contrastive Validation (CP-002)**: 각 finding 작성 후, 즉시 다음 두 가지를 생성한다:
1. **WHY_VALID**: 이 finding이 정당한 이유 (구체적 코드 증거 열거)
2. **WHY_WRONG**: 이 finding이 잘못된 가능성 (False Positive, ORM/프레임워크가 이미 처리, scope 밖, over-severity 등)

WHY_WRONG 작성 후 반드시 코드에서 직접 확인(Read/Grep)하여 판정한다. 반증이 지지보다 강하면 finding을 폐기하거나 severity를 하향하고, REJECTION_DETAIL에 사유를 기록한다. "추측 기반 반증"은 금지 — 코드 확인 없이 반증을 채택하면 실제 취약점을 놓칠 수 있다.

예시:
```
FINDING: JWT 서명 검증 누락
WHY_VALID: ValidateToken()이 jwt.Parse() 호출 시 signing method 검증 비활성화 (handler.go:47)
WHY_WRONG: 미들웨어 레이어에서 이미 검증? → middleware/ 확인 필요
→ 미들웨어 확인 결과: 없음 → finding 유지 (CRITICAL)
```

**안전 제약**: CRITICAL 보안 finding에서 WHY_WRONG으로 severity를 하향하려면 사용자 명시 승인이 필수다 — 논문의 23/120 오판 위험에 대응.

- MEDIUM findings가 10개 이상이면 architect가 영향도 기준 상위 5개만 활성 처리하고 나머지는 backlog로 분류
- 핵심 비즈니스 로직 > 내부 유틸리티 순으로 분석 깊이를 조절

### Agent Scope Anti-Goals (P-003)

각 전문가 에이전트 prompt에 다음을 포함:
> "이 리뷰의 목적은 {도메인} 관점의 우려사항 식별입니다. 코드 스타일 교정, 범위 밖 리팩토링 제안, 변경하지 않은 파일에 대한 의견은 scope 밖입니다. git diff 대상 파일만 검토하세요."

이를 통해 에이전트가 범위를 벗어나 불필요한 의견을 생성하는 것을 방지한다.

### Lead의 Cross-team Synthesis

- **출력 형식**: 모든 전문가는 `references/expert-output-schema.md`의 Findings Schema를 따른다.

각 findings 출력 형식:
- **우려사항**: CRITICAL / HIGH / MEDIUM 심각도 (팀 합의 기반)
- **권장사항**: 구현 시 고려해야 할 구체적 주의점
- **토론 근거**: 어떤 전문가가 어떤 논거로 해당 severity에 합의했는지
- **질문**: 계획에서 불명확한 부분
- **재평가 트리거**: 구현 시 어떤 조건이 발생하면 이 concern의 severity를 재평가해야 하는지 (예: "만약 캐시 레이어를 도입하면 이 concern은 HIGH로 상향")

CRITICAL → `planner`에게 전달하여 계획 수정 → Step 2로 회귀 (max 2회)
HIGH → 계획에 주의사항으로 추가, 구현 시 반드시 반영
MEDIUM → 기록만 하고 구현 시 참고

- Save: `.claude/memory/expert-plan-concerns.md`
- 각 concern에 `trigger_condition` 필드를 포함하여, Step 7의 Impl Review Team이 구현 결과와 대조할 수 있도록 한다

### Fact-checking 검증 (CRITICAL/HIGH concerns)

expert-plan-concerns.md 저장 후, **CRITICAL/HIGH concerns 중 기술적 사실에 기반한 주장**을 독립 fact-checker subagent로 검증한다. 전문가의 환각 기반 concern이 검증 없이 전체 파이프라인(Step 5→7→17→18)을 관통하는 것을 방지한다.

**검증 대상** (사실적 주장만):
- "X 라이브러리는 ~를 지원하지 않는다"
- "Y 버전에서 ~가 변경/제거되었다"
- "Z API의 동작이 ~이다"
- 검증 가능한 기술적 사실에 기반한 CRITICAL/HIGH concerns

**검증 대상 아님** (의견/판단):
- "이 설계는 유지보수가 어렵다"
- "이 접근법은 확장성이 부족하다"
- 주관적 판단이나 미래 예측

**검증 절차**:
1. CRITICAL/HIGH concerns에서 사실적 주장을 추출
2. 각 주장에 대해 **fact-checker subagent** (model: sonnet) spawn
3. fact-checker가 Context7 MCP(`resolve-library-id` → `query-docs`)로 공식 문서 조회 + 실제 라이브러리 코드 확인
4. 검증 결과:
   - `[FACT-VERIFIED]`: 사실 확인됨 → concern 유지
   - `[FACT-DISPUTED]`: 사실과 불일치 → concern에 태깅 + 근거 기록. 구현 시 이 concern은 무시해도 됨
5. 결과를 expert-plan-concerns.md에 반영 (해당 concern에 태그 추가)

- 사용자에게 주요 우려사항 요약 보고 (AskUserQuestion으로 진행 여부 확인). Fact-checking 결과도 함께 보고
- Update: `CONTEXT.md` — Phase A 완료 표시, 핵심 결정사항 및 전문가 우려(HIGH+) 갱신

## Phase A Calibration Checklist (Phase B 진입 전 검증)

### Ship Mode 동작 매트릭스 (Phase A)

ship 모드에서는 CRITICAL security finding과 build/test failure 외에 AskUserQuestion을 호출하지 않는다 — "한 번 입력 후 PR URL까지"의 약속을 100% 이행하기 위함이다.

| 지점 | ship 모드 동작 |
|------|---------------|
| Step 0: Scope Challenge | AI가 변경 파일 수 기준 자동 선택 + 1줄 통보 |
| Step 1-B: Plan Interview | AI-First Draft 확정, 교정 없이 진행 |
| Step 1-B: Spec Validation | Skip + Decision Journal 기록 |
| Steps 2-4: Plan Review | 에스컬레이션 없이 AI 자동 판정 |
| Step 4-B: Expert CRITICAL | 자동 수정 시도 + Decision Journal 기록. 자동 수정 실패 시에만 정지 |
| Calibration Checklist | 실패 항목 자동 보정 시도. 빌드/테스트 실패만 정지 |


Calibration Checklist의 검증 항목은 파일 존재 여부, 섹션 존재 여부 등 결정론적 작업이다. CLI 스크립트(`calibration-check.sh` 등)가 있으면 이를 우선 사용하고, 결과만 받아 FAIL 항목을 수정한다.

모든 항목이 충족된 후에 Phase B로 진입한다. 미충족 항목이 있으면 해당 단계로 돌아가 보완한 후 재검증한다.

| # | 검증 항목 | 확인 방법 | 미충족 시 |
|---|----------|----------|----------|
| 1 | 코드베이스 탐색 완료 | `requirements.md` + `code-design-analysis.md` 존재 및 비어있지 않음 | → Step 1-A |
| 2 | 인터뷰 완료 | `plan-summary.md`에 Unresolved decisions이 비어있거나 구현에 영향 없음 | → Step 1-B |
| 3 | 계획서에 파일 경로 포함 | Task 섹션 + End State Files Changed 테이블에 구체적 파일 경로 | → Step 1-B |
| 4 | Acceptance Criteria 3분할 | Code Changes / Tests / Quality Gates 섹션 모두 존재 | → Step 1-B |
| 5 | End State Files Changed 테이블 존재 | File \| Action \| Summary 형식 | → Step 1-B |
| 6 | End State Behavior Changes 존재 | Before → After 형식 | → Step 1-B |
| 7 | Test Targets 섹션 존재 | 테스트 대상 파일 패턴 명시 | → Step 1-B |
| 8 | Done-When Checks 존재 | 각 Unit별 기계적 검증 조건 명시 | → Step 1-B |
| 9 | Behavioral Checks 존재 | Behavior Changes의 검증 가능 항목이 Done-When Behavioral Checks에 포함 | → Step 1-B |
| 10 | 탐색 완성도 자기 평가 | code-design-analysis.md에 Structured Research Protocol(P-013)의 경쟁 가설 2개 이상 존재하고, 각 가설에 반박 증거 탐색이 수행되었는지 확인. "탐색 비중 높을수록 재작업 3~4배 감소" 원칙의 구조적 강제 | → Step 1-A |

누락 항목 발견 시 사용자에게 보고하지 않고 자동으로 해당 단계를 재실행하여 보완한다.

### Phase A Retrospective Checkpoint

Calibration Checklist 통과 직후, **Phase-End Auto-Retrospective** 프로토콜을 실행한다 (SKILL.md Cross-Cutting Protocol 참조). Phase A 동안 축적된 사용자 피드백(인터뷰 교정, 계획서 수정 요청 등)에서 반복 패턴을 탐지하고, 필요 시 boost-capture를 백그라운드로 트리거한다.
