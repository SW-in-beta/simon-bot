# Phase A: Planning (Detailed Instructions)

## 목차
- [Step 0: Scope Challenge](#step-0-scope-challenge)
  - [X-Y Problem Detection (P-005)](#x-y-problem-detection-p-005)
  - [Impact-Aware Path Selection (P-001)](#impact-aware-path-selection-p-001)
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
- [다음 단계 → phase-a-review.md](phase-a-review.md)
  - Steps 2-4: Plan Review (Agent Team)
  - Step 4-B: Expert Plan Review
  - Phase A Calibration Checklist

## Step I/O Interface

각 Step의 입력과 출력 아티팩트. 새 세션에서 Step N을 시작하려면 `Input` 파일들이 SESSION_DIR에 있어야 한다.

| Step | Input (필수) | Output (생성) |
|------|-------------|--------------|
| Step 0 | (없음 — git 이력만) | `memory/codebase-health.md`, `memory/plan-summary.md` (scope section) |
| Step 1-A | `memory/codebase-health.md` | `memory/requirements.md`, `memory/code-design-analysis.md`, `memory/verify-commands.md`, `memory/env-context.md` |
| Step 1-B | `memory/requirements.md`, `memory/code-design-analysis.md` | `memory/plan-summary.md` (완성본) |
| Steps 2-4 | `memory/plan-summary.md`, `memory/requirements.md`, `memory/code-design-analysis.md` | `memory/plan-summary.md` (리뷰 반영), `memory/plan-review-scores.md` |
| Step 4-B | `memory/plan-summary.md`, `memory/code-design-analysis.md` | `memory/expert-plan-concerns.md`, `memory/plan-summary.md` (CRITICAL 반영) |

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

### Codebase Health Pre-scan (architect spawn 전)

> **Reference Loading**: `~/.claude/skills/_shared/codebase-health-prescan.md` 읽기 — 5개 diagnostic 명령, 해석 가이드, 한계점 포함.

architect spawn 전에 git 이력 기반 정량 진단을 실행한다. 코드를 읽기 전에 "어디가 불안정한가"를 수 초 만에 파악하여, scope 판별과 탐색 우선순위에 활용하기 위함이다.

churn + bug hotspot + firefighting (명령 1, 2, 5)을 실행한다.

```bash
# 1. High-churn 파일 (항상 실행)
git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20

# 2. Bug hotspot (항상 실행)
git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20

# 3. Firefighting 빈도 (항상 실행)
git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback' | wc -l
```

**Cross-Analysis**: churn Top-20과 bug hotspot Top-20 양쪽에 등장하는 파일을 "고위험 코드"로 플래그한다.

결과를 `{SESSION_DIR}/memory/codebase-health.md`에 저장. architect에게 이 데이터를 전달하여:
- 변경 대상이 고위험 영역과 겹치면 STANDARD 이상을 권장
- Step 1-A explore-medium에 탐색 우선순위 전달
- Step 4-B Expert Review에 정량적 리스크 컨텍스트 전달

**▶ EMIT** `subagent_spawn` @ `A/0` — architect 서브에이전트에 scope 분석 위임 (스텝 흐름의 일부, 생략 불가)
```bash
$E --step "A/0" --type subagent_spawn --title "architect 서브에이전트 시작" --data '{"agent_name":"architect","agent_type":"Explore","task":"git history 분석 + scope 판별","background":false}' 2>/dev/null || true
```

- Spawn `architect`: Analyze git history for past problem areas (codebase-health.md 데이터 활용)
- Identify "What already exists" - existing code that solves parts of the request
- Determine minimum viable change
- Flag if scope exceeds 8 files or 2 new classes
- Present 2 review paths to user via AskUserQuestion:
  - **STANDARD**: Steps 5-17 full pipeline
  - **LARGE**: Steps 5-17 + extended failure mode analysis
- **ship 모드 자동 결정**: ship 모드에서는 이 AskUserQuestion을 생략하고, AI가 변경 파일 수 기준으로 자동 선택한다 (10개 이하→STANDARD, 그 이상→LARGE)
- Record decision in `.claude/memory/plan-summary.md`

**Step Output Artifacts** (Step 1-A 진입 전 필요):
- `memory/codebase-health.md` — git 이력 기반 고위험 파일 목록 (churn + bug hotspot)
- `memory/plan-summary.md` — scope section: STANDARD/LARGE 결정 및 근거

**▶ EMIT** `decision` @ `A/0` — 실행 경로 결정 (스텝 흐름의 일부, 생략 불가)
```bash
$E --step "A/0" --type decision --title "실행 경로 결정: $SCOPE" --data '{"decision":"'"$SCOPE"' path 선택","rationale":"'"$RATIONALE"'","alternatives":[]}' 2>/dev/null || true
```

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

변경 파일이 `high_impact_paths`에 매칭되면 LARGE 경로를 권장한다. 보안·인증·마이그레이션 관련 코드는 단순 변경이라도 영향 범위가 크기 때문이다.

### Phase A Common Rationalizations

| 합리화 | 현실 |
|--------|------|
| "스펙이 명확하니까 Step 0은 건너뛰자" | Scope Challenge가 STANDARD/LARGE를 결정한다. 건너뛰면 과도한 파이프라인을 돌리거나 필요한 검증을 누락한다 |
| "코드를 보면 아니까 인터뷰는 필요 없다" | 비즈니스 결정(우선순위, 제약, 의도)은 코드에 없다. Interview Guard를 따른다 |
| "계획은 대충 써도 구현하면서 맞추면 된다" | plan-summary.md가 불완전하면 executor가 임의로 해석한다. Done-When Checks가 없으면 Step 17에서 완료 판정이 불가능하다 |
| "Expert Review까지는 과하다" | CRITICAL 이슈는 구현 후 발견하면 재작업 비용이 10배다. Phase A에서 잡는 것이 가장 싸다 |

## Step 1-A: Project Analysis + Code Design Analysis

### Graphify Knowledge Graph 활용 (탐색 전)

`graphify-out/GRAPH_REPORT.md`가 존재하면 `~/.claude/skills/_shared/graphify-context.md`를 읽고 아래 순서로 활용한다. 그래프가 없으면 이 섹션을 건너뛰고 explore-medium부터 진행한다.

1. GRAPH_REPORT.md 읽기 → god nodes, communities, surprising connections 추출
2. 사용자 요청과 관련된 community 식별 → explore-medium의 탐색 범위를 해당 community 중심으로 축소
3. 변경 대상이 god node에 해당하면 Scope Challenge에서 STANDARD 이상을 권장하는 추가 근거로 활용
4. `graphify explain "대상모듈"`로 연결된 파일 목록을 확보하여 Reference chain traversal의 시작점으로 사용
5. cross-community 연결이 발견되면 Step 4-B Expert Review에 파급 범위 경고 전달

그래프 쿼리 결과가 부족하면 반드시 Grep/Read로 폴백한다 — 그래프는 탐색 가속기이지 유일한 소스가 아니다.

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
7. **Churn-guided prioritization**: `codebase-health.md`가 존재하면, churn 상위 파일이 변경 대상 범위와 겹치는지 확인한다. 겹치는 파일은 우선 심층 탐색 대상으로 지정한다 — "이 파일이 왜 자주 변경되는가?"를 파악하면 구현 중 사이드 이펙트를 사전 예측할 수 있다. 고위험 파일(churn + bug hotspot 교차)은 Step 4-B 전문가 리뷰에서도 우선 검토 대상으로 전달한다.

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

**▶ EMIT** `expert_panel` @ `A/1-A` — Code Design Team 분석 결과 발신 (스텝 흐름의 일부, 생략 불가). `.pending-event.json` 작성 후 실행:
```json
{
  "skill": "simon",
  "step": "A/1-A",
  "type": "expert_panel",
  "title": "Code Design Team 분석",
  "data": {
    "panel_name": "Code Design Team",
    "opinions": [각 전문가의 {"role":"...", "opinion":"...", "severity":"INFO|LOW|MEDIUM|HIGH|CRITICAL"}],
    "consensus": "합의 내용",
    "action_items": ["액션1", "액션2"]
  }
}
```
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit-event.sh --session "$SESSION_DIR" 2>/dev/null || true
```

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

**Step Output Artifacts** (Step 1-B 진입 전 필요):
- `memory/requirements.md` — 요구사항 분석 (사용자 의도, 기술 제약)
- `memory/code-design-analysis.md` — 코드 설계 컨텍스트 (아키텍처, Known Gotchas, Design Context)
- `memory/verify-commands.md` — 빌드/테스트/린트 통합 검증 명령
- `memory/env-context.md` — 실행 환경 스냅샷 (런타임, Docker 상태, ENV 변수)

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

### Cross-Session State 디렉토리 보장

Phase A 시작 시 `state/` 디렉토리를 생성한다. gotchas.jsonl, standup.jsonl 등 Cross-Session State 파일의 저장소이다. 이 디렉토리가 없으면 Phase-End Auto-Retrospective와 simon-code-review의 기록이 실패한다.

```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel 2>/dev/null | tr '/' '-')
STATE_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/state"
mkdir -p "${STATE_DIR}"
```

### Gotchas Registry 로딩

`~/.claude/projects/{slug}/state/gotchas.jsonl`이 존재하면 로딩하여 `code-design-analysis.md`에 "Known Gotchas" 섹션으로 포함한다 — 이 프로젝트에서 Claude가 반복적으로 잘못하는 패턴을 사전에 인지하여 동일 실수를 방지한다. gotchas는 프로젝트별로 세션을 거듭하며 축적되는 가장 가치 높은 콘텐츠이다.

```bash
# 로딩 예시
jq -r '.gotcha' "${STATE_DIR}/gotchas.jsonl" 2>/dev/null | head -20
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
  - [ ] POST /login (잘못된 비밀번호) → 401 + "Invalid email or password"
        verify: curl -s -o /dev/null -w "%{http_code}" -X POST localhost:3000/api/login -d '{"email":"test@test.com","password":"wrong"}'
  - [ ] {Trigger: 어떤 입력/조건} → {Observable: 기대 결과}
        verify: {실행 가능한 검증 명령}
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

각 파일에 대해 구체적인 변경 내용을 한 문장으로 설명한다. "수정"이라고만 적지 않고 무엇을 수정하는지 명시한다 (예: `internal/handler/campaign.go | 수정 | POST /campaigns 핸들러에 PacingService 의존성 주입 추가`).

#### Unit 파싱 마커

plan-summary.md의 각 Unit 섹션을 `<!-- UNIT:unit-1 START -->` / `<!-- UNIT:unit-1 END -->` 마커로 감싼다. `sed -n '/<!-- UNIT:unit-1 START -->/,/<!-- UNIT:unit-1 END -->/p' plan-summary.md`로 특정 Unit 전체를 정확하게 추출할 수 있어 CLI 스크립트의 파싱 안정성이 보장된다.

- Save to `.claude/memory/plan-summary.md`

**Step Output Artifacts** (Steps 2-4 진입 전 필요):
- `memory/plan-summary.md` — STICC 구조 완성본 (Situation/Task/Intent/Concerns/AC/End State, Unit 파싱 마커 포함). 이후 모든 Phase의 핵심 입력 — 새 세션에서 Step 2 이후를 시작하려면 이 파일 하나로 충분한 계획 컨텍스트를 복원할 수 있다.

- Use subagent with planner role for plan creation

## 다음 단계

Steps 2-4 (Plan Review), Step 4-B (Expert Plan Review), Phase A Calibration Checklist의 상세 지침은 [`phase-a-review.md`](phase-a-review.md)를 참조하세요.
