---
name: simon-bot-report
description: "사전 분석 보고서 작성 — 코드베이스를 전문가팀 토론 구조로 분석하여 RFC, 현황 분석서, 또는 사용자 지정 양식의 문서를 생성합니다. Use when: (1) 새 기능 도입 전 RFC 작성 (\"RFC 써줘\", \"기술 제안서 만들어줘\"), (2) 기존 시스템 현황 분석 (\"코드 분석해줘\", \"현황 파악해줘\", \"아키텍처 리뷰\"), (3) 기술적 의사결정을 위한 사전 조사 (\"기술 조사해줘\"), (4) 커스텀 양식의 기술 문서 작성. 코드 변경 없이 분석만 필요할 때 이 스킬을 사용하세요."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
---

# simon-bot-report

사전 분석 보고서 작성 스킬. 전문가팀 토론 기반 심층 분석 후 사용자 지정 양식으로 문서를 생성합니다.

## Instructions

You are executing the **simon-bot-report** skill. This skill analyzes a codebase topic using expert team discussions (from simon-bot's domain team structure) and produces a pre-implementation document in the user's chosen format.

**This is NOT a post-implementation report. It is a PRE-work analysis document** (RFC, 현황 분석, 기술 제안서 등).

> **도구 제한**: 이 스킬은 분석용이다. 프로젝트 소스 코드를 Edit/Write하지 않는다. 보고서 파일(`{SESSION_DIR}/reports/`)만 Write한다.

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules, Agent Teams, Cognitive Independence 공통 프로토콜 포함.

### Session Isolation Protocol (확장 — Report 전용)

Report 세션의 SESSION_DIR은 타임스탬프 기반으로 결정한다:
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
SESSION_ID="report-$(date +%Y%m%d-%H%M%S)"
SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${SESSION_ID}"
mkdir -p "${SESSION_DIR}/reports"
```

### Read-Only Guard Hook

Report 스킬의 "코드 수정 금지" ABSOLUTE 규칙을 결정론적으로 강제한다. 산문 지시는 compaction 후 소실될 수 있지만, hook은 세션 동안 100% 작동한다.

`report-readonly-guard.sh` (PreToolUse):
- `$TOOL_NAME`이 Edit 또는 Write일 때 활성화
- `$FILE_PATH`가 `{SESSION_DIR}/reports/`나 `~/.claude/` 하위이면 → 허용 (exit 0)
- 그 외 경로 → 차단 (exit 2), 메시지: "simon-bot-report는 분석 전용입니다. 프로젝트 소스 코드 수정은 차단됩니다."

settings.json에 등록하여 report 세션 동안만 활성화한다. simon-bot의 `forbidden-guard.sh`와 독립 동작한다.

### Reference Loading Policy

| 트리거 | 읽을 파일 |
|--------|----------|
| Step 3 Domain Expert 진입 | `references/domain-teams.md` |
| Step 4-B Document Generation 진입 | `references/examples.md` |

### Step 0: Input Collection (P-001 AI-First Draft)

**0-A: 워크플로 설정 확인**
- `.claude/workflow/config.yaml`이 존재하면 읽기 (language, experts 설정 활용)
- 없으면 기본값 사용 (language: ko)

**0-B: AI-First Draft 입력 수집**

사용자 요청에서 문서 유형, 분석 주제, 분석 범위를 AI가 자동 추론하고 한 번에 제시한다. 3-4회의 AskUserQuestion을 1회로 축소.

```
[Default] 보고서 설정:
- 문서 유형: {RFC|현황 분석서|커스텀} — {추론 근거}
- 분석 주제: {주제 요약}
- 분석 범위: {자동 탐색|특정 경로}
- 변경하려면 알려주세요.
```

사용자가 교정하면 반영, 교정 없으면 기본값으로 진행. 커스텀 양식의 경우에만 양식 세부사항을 추가 질문.

**기록:**
- `.claude/reports/input-{topic-slug}.md`에 입력 내용 저장

### Step 1: Codebase Exploration

**목적:** 분석 주제와 관련된 코드를 탐색하여 컨텍스트 확보

**1-0: Report Memory (이전 보고서 참조)**
- `.claude/reports/` 디렉토리의 기존 보고서 목록을 스캔한다
- 현재 분석 주제와 관련된 이전 보고서가 있으면 핵심 발견사항을 컨텍스트로 활용한다
- 이전 보고서의 발견사항 중 아직 해결되지 않은 항목을 "기존 이슈"로 표시한다
- 이전 보고서가 없으면 이 단계를 skip한다

**1-A: 구조 탐색**
- Spawn `explore-medium` (model: haiku): 주제 관련 디렉토리/파일 구조 스캔
  - 관련 모듈, 클래스, 함수 식별
  - 의존성 관계 파악
  - 설정 파일, 테스트 파일 포함
- 사용자가 파일/디렉토리를 지정한 경우: 해당 범위 중심으로 탐색
- 지정하지 않은 경우: 주제 키워드로 codebase 전체 탐색

**1-A-ext: Cross-service 의존성 추적**
- 1-A에서 식별한 핵심 모듈이 다른 서비스/레포의 코드를 호출하거나 참조하는 경우:
  - gRPC proto import, HTTP client 호출, 공유 라이브러리 참조를 Grep으로 추적한다
  - 로컬에 해당 서비스/레포가 존재하면 (`~/buzzvil/` 등) 관련 코드까지 탐색 범위에 포함한다
  - 로컬에 존재하지 않으면 "**[외부 의존성]** — {서비스명}: 로컬에 코드 없음, 확인 불가"로 기록한다
- 이 단계의 목적은 단일 서비스 내부만 보고 전체 흐름을 오해하는 것을 방지하기 위함이다

**1-B: 핵심 코드 읽기**
- 탐색 결과에서 핵심 파일 5-15개 선별
- Read tool로 핵심 로직 파악
- 데이터 흐름, 에러 처리, 인터페이스 구조 메모

**중간 보고 (Progressive Disclosure):**
- 탐색 완료 시 사용자에게 한 줄 요약 출력: "탐색 완료. N개 파일에서 M개 핵심 모듈 식별."
- 이 중간 출력은 진행 상황 프리뷰이며, 최종 보고서가 정본이다.

**Save:** `.claude/reports/exploration-{topic-slug}.md`

### Step 2: Code Design Analysis (Agent Team)

**목적:** simon-bot Step 1-A의 Code Design Team 구조를 활용하여 코드 설계 컨텍스트 분석

**단일 통합 팀 생성** (Agent Teams 제약: 세션당 1팀, 세션 기본 모델 사용):

`TeamCreate(team_name="code-design-analysis", description="코드 설계 분석 전문가 팀")`

- **convention-expert** (always):
  - 분석 대상 디렉토리의 기존 코드 패턴 분석
  - 네이밍 규칙, 디렉토리 구조, 에러 핸들링 패턴
  - CLAUDE.md / linter 설정 참조
  - 유사 기능의 기존 구현체 탐색

- **idiom-expert** (always):
  - 사용 중인 프레임워크/라이브러리의 공식 권장 패턴 확인
  - Context7 MCP 활용 (가능한 경우)
  - 언어 공식 가이드 기반 관용구 확인

- **design-pattern-expert** (auto-detect):
  - 기존 코드의 아키텍처 패턴 식별
  - Clean Architecture / DDD / Layered 등
  - 의존성 방향, 인터페이스 사용 패턴

- **testability-expert** (auto-detect):
  - 기존 테스트 구조, mock/fixture 패턴 파악
  - 테스트 커버리지 현황

> **Agent Teams Fallback**: Agent Teams 미활성 시, 각 전문가를 개별 `Agent(subagent_type="general-purpose")` subagent로 spawn하고, 결과를 오케스트레이터가 취합하여 교차 검증한다.

**Shared Tasks:**
- Task 1: 각자 도메인별 분석
- Task 2: 서로의 발견 공유 및 토론
- Task 3: 팀 합의 → 통합 분석 결과 작성

**Agent Team 해산**

**Agent Teams Fallback**: Agent Teams가 비활성 상태이면 `~/.claude/skills/simon-bot/references/agent-teams.md`의 Fallback 섹션을 참조하여 subagent fallback을 적용한다.

**중간 보고 (Progressive Disclosure):**
- 코드 설계 분석 완료 시 사용자에게 주요 발견 요약 출력 (예: "코드 설계 분석 완료. 주요 발견: Layered Architecture 사용 중, 테스트 커버리지 낮음, 네이밍 규칙 일관됨.")
- 이 중간 출력은 진행 상황 프리뷰이며, 최종 보고서가 정본이다.

**Save:** `.claude/reports/code-design-{topic-slug}.md`

### Step 3: Domain Expert Team Discussion

**목적:** simon-bot Step 4-B의 도메인팀 Agent Team 토론 구조를 활용하여 심층 분석

> **Reference Loading**: [domain-teams.md](references/domain-teams.md) 읽기

6개 도메인 전문가 팀(Data, Integration, Safety, Ops, Code Design)이 각자의 관점에서 코드베이스를 분석한다. 팀 구성과 각 도메인의 분석 항목은 domain-teams.md 참조.

**Save:** `.claude/reports/expert-findings-{topic-slug}.md`

### Step 4: Document Generation

**목적:** 수집된 모든 분석 결과를 사용자가 선택한 양식으로 정리

**4-A: 템플릿 로딩**
- RFC → `~/.claude/skills/simon-bot-report/templates/rfc.md`
- 현황 분석 → `~/.claude/skills/simon-bot-report/templates/analysis.md`
- 커스텀 → 사용자가 지정한 양식/섹션 사용

**4-B: 문서 작성**

> **Reference Loading**: Step 4-B 진입 시 [examples.md](references/examples.md) 읽기

- 작성 전 [예시 문서](references/examples.md)를 읽어 기대 톤과 구체성 수준을 확인한다
- Spawn `writer` (model: sonnet):
  - 입력: Step 1 탐색 결과 + Step 2 코드 설계 분석 + Step 3 전문가 토론 결과
  - 템플릿의 플레이스홀더를 실제 분석 내용으로 채움
  - **Language:** config.yaml의 `language` 설정 (기본: `ko`)
  - 코드 스니펫은 실제 코드에서 발췌 (핵심 부분만)
  - 다이어그램은 ASCII art 또는 Mermaid 형식
  - 전문가 토론 결과를 적절한 섹션에 배치
  - 미결정 사항은 "**추후 결정 필요**" 또는 "**추후 문제가 될 수 있음**" 표시
  - **주장-근거 연결 필수 (Assertion-Evidence Linking):**
    - 보고서의 모든 사실 주장(시스템이 X를 한다, Y는 Z 목적이다 등)에는 코드 근거(`파일경로:라인` 또는 Read로 확인한 코드 스니펫)를 반드시 첨부한다
    - Step 1-3에서 코드로 확인하지 못한 내용은 **절대 확정적으로 기술하지 않는다**. 다음 중 하나로 표시한다:
      - `**[미확인]**` — 코드를 찾지 못했거나 읽지 않은 경우
      - `**[추정]** — {추정 근거}` — 간접 증거는 있으나 직접 확인하지 못한 경우
    - writer는 문서 작성 완료 후, 모든 사실 주장에 코드 근거가 있는지 자체 검증(self-audit)한다. 근거 없는 주장이 발견되면 해당 문장에 `[미확인]` 태그를 추가한다

**4-C: 출력**
1. `.claude/reports/{document-type}-{topic-slug}.md`에 파일 저장
2. HTML Report Viewer로 렌더링 후 출력:
   ```bash
   REPORT_VIEWER="$HOME/.claude/skills/_shared/report-viewer/render-report.sh"
   if [ -x "$REPORT_VIEWER" ]; then
     $REPORT_VIEWER "{markdown_file}" --open
   fi
   ```
   - Viewer 활성: 브라우저에서 보고서를 열고 저장 경로 안내
   - Viewer 미활성: 기존 방식대로 터미널에 전체 내용 출력 + 저장 경로 안내

**4-D: Knowledge Base 갱신**
- 보고서의 핵심 발견사항(CRITICAL/HIGH)을 `.claude/reports/knowledge-base.md`에 누적 append한다
- 형식: `## [{날짜}] {주제} — {핵심 발견 3줄 요약} | 관련 파일: {파일 목록}`
- 이 누적 기록은 향후 Step 1-0에서 활용된다

**Gotchas 연동**: 보고서의 Code Design 분석 결과 중 "이 프로젝트의 관습이 Claude의 기본 패턴과 다른 항목"을 `~/.claude/projects/{slug}/state/gotchas.jsonl`에 append한다 — 코드 변경 없는 분석(report)에서도 gotchas를 축적하여 이후 simon-bot 실행 시 사전 인지하기 위함이다. 형식: `{"id": "G-xxx", "category": "convention|build|test", "gotcha": "...", "source_step": "report", "source_session": "report-{slug}", "added_at": "YYYY-MM-DD"}`.

### Step 5: Report Review

**목적**: 보고서를 사용자가 검토하고 피드백을 반영하는 리뷰 과정.

> **HTML Report Viewer 통합**: `~/.claude/skills/_shared/report-viewer/integration-guide.md`의 코멘트 피드백 루프 프로토콜을 적용한다. Viewer 미활성 시 기존 순차 리뷰 방식으로 fallback.

**5-A: 리뷰 진행**

**Viewer 활성 시 (HTML 코멘트 리뷰 루프):**

integration-guide.md의 "코멘트 피드백 루프" 프로토콜을 따른다:
1. 사용자에게 안내: "보고서를 브라우저에서 열었습니다. 내용을 확인하시고 코멘트를 남겨주세요. 완료되면 '리뷰 완료'라고 말씀해주세요."
2. 사용자가 "리뷰 완료" → 코멘트 JSON 읽기
3. 각 코멘트의 intent(fix/question/expand/approve)에 따라 마크다운 수정
4. HTML 재생성 → "N개 코멘트를 처리했습니다. 추가 코멘트가 있으면 '리뷰 완료', 완료되었으면 '확정'이라고 말씀해주세요."
5. 사용자가 "확정" → 리뷰 종료

**Viewer 미활성 시 (순차 리뷰 루프):**
- 보고서의 섹션을 순서대로 하나씩 제시
- 각 섹션마다 AskUserQuestion으로 피드백 수집 (OK / 수정 요청 / 추가 분석 / 질문)
- 수정 요청 시 `writer`로 즉시 수정 → 재확인 (max 3회)
- 모든 섹션 리뷰 완료 후 전체 요약

**5-B: 최종 확인**
- "모든 리뷰가 완료되었습니다. 추가 수정이 필요하신가요?"
  - **완료**: 최종 보고서 저장 경로 안내
  - **구현 시작 (simon-bot)**: 분석 결과를 컨텍스트로 simon-bot 워크플로 시작
  - **프로젝트 관리 (simon-bot-pm)**: 분석 결과를 기반으로 PM 워크플로 시작
  - **양식 변경**: Step 4에서 다른 템플릿으로 재생성
  - **추가 리뷰**: 5-A로 돌아가 재리뷰

### Configuration

이 스킬은 `.claude/workflow/config.yaml`이 있으면 다음 설정을 활용합니다:
- `language`: 보고서 작성 언어 (기본: ko)
- `experts`: 전문가 구성 (always / auto_detect)
- `model_policy`: 에이전트 모델 (기본: 세션 모델)

config.yaml이 없어도 기본값으로 동작합니다.

### Output Files

모든 중간 결과 및 최종 문서는 `.claude/reports/`에 저장됩니다:

| 파일 | 내용 |
|------|------|
| `input-{slug}.md` | 사용자 입력 (주제, 범위, 양식) |
| `exploration-{slug}.md` | Step 1 코드 탐색 결과 |
| `code-design-{slug}.md` | Step 2 코드 설계 분석 |
| `expert-findings-{slug}.md` | Step 3 전문가 토론 결과 |
| `{type}-{slug}.md` | 최종 보고서 (rfc/analysis/custom) |

### Global Rules

`~/.claude/skills/simon-bot/references/forbidden-rules.md`의 3계층 규칙(ABSOLUTE / CONTEXT-SENSITIVE / AUDIT-REQUIRED)을 전체 적용한다. 추가로:

- **미검증 추측을 사실로 기술하지 않는다 (ABSOLUTE).** 코드를 Read/Grep으로 직접 확인하지 않은 내용을 확정적으로 기술하는 것은 금지다. 검증 수단(로컬 코드, 설정 파일, SQL 등)이 존재하는데 확인하지 않고 추측으로 기술하면 보고서의 신뢰성이 파괴된다. 확인하지 못한 내용은 반드시 "**[미확인]** — 추가 확인 필요" 또는 "**[추정]** — {추정 근거}"로 표시한다. 이 규칙은 모든 Step(1-4)의 모든 에이전트(탐색, 설계 분석, 도메인 전문가, writer)에 공통 적용된다. 각 에이전트 spawn 시 이 규칙을 프롬프트에 포함한다.
- 코드를 수정하지 않는다 (읽기 전용 분석). 이 스킬의 목적은 사전 분석이므로, 코드를 변경하면 분석 결과의 객관성을 잃는다. 전문가 에이전트 spawn 시 도구 범위를 Read/Glob/Grep으로 제한한다 (P-011).
- 외부 시스템에 접근하지 않는다. 분석 대상은 로컬 코드베이스에 한정된다.
- 실제 DB나 API를 호출하지 않는다. 운영 환경에 영향을 줄 수 있는 행위를 방지하기 위함이다.
- 분석 결과는 `.claude/reports/`에만 저장한다. 산출물의 위치를 일원화하여 추적과 관리를 용이하게 한다.
- 기존 코드나 설정 파일을 변경하지 않는다. 분석 과정에서 의도치 않은 부작용을 예방하기 위함이다.
