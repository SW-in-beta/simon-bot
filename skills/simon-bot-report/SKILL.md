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

### Session Isolation Protocol

런타임 산출물을 홈 디렉토리에 세션별로 격리 저장한다. 모든 `.claude/reports/` 경로를 `{SESSION_DIR}/reports/`로 해석한다.

**Step 0에서 SESSION_DIR 결정:**
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
SESSION_ID="report-$(date +%Y%m%d-%H%M%S)"
SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${SESSION_ID}"
mkdir -p "${SESSION_DIR}/reports"
```

프로젝트의 `.claude/workflow/` (config, scripts)는 공유 설정이므로 프로젝트 디렉토리에서 그대로 읽는다.

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
- Spawn `explore-medium`: 주제 관련 디렉토리/파일 구조 스캔
  - 관련 모듈, 클래스, 함수 식별
  - 의존성 관계 파악
  - 설정 파일, 테스트 파일 포함
- 사용자가 파일/디렉토리를 지정한 경우: 해당 범위 중심으로 탐색
- 지정하지 않은 경우: 주제 키워드로 codebase 전체 탐색

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
- Spawn `writer`:
  - 입력: Step 1 탐색 결과 + Step 2 코드 설계 분석 + Step 3 전문가 토론 결과
  - 템플릿의 플레이스홀더를 실제 분석 내용으로 채움
  - **Language:** config.yaml의 `language` 설정 (기본: `ko`)
  - 코드 스니펫은 실제 코드에서 발췌 (핵심 부분만)
  - 다이어그램은 ASCII art 또는 Mermaid 형식
  - 전문가 토론 결과를 적절한 섹션에 배치
  - 미결정 사항은 "**추후 결정 필요**" 또는 "**추후 문제가 될 수 있음**" 표시

**4-C: 출력**
1. `.claude/reports/{document-type}-{topic-slug}.md`에 파일 저장
2. 사용자에게 전체 내용을 화면에 출력
3. 저장 경로 안내

**4-D: Knowledge Base 갱신**
- 보고서의 핵심 발견사항(CRITICAL/HIGH)을 `.claude/reports/knowledge-base.md`에 누적 append한다
- 형식: `## [{날짜}] {주제} — {핵심 발견 3줄 요약} | 관련 파일: {파일 목록}`
- 이 누적 기록은 향후 Step 1-0에서 활용된다

### Step 5: Interactive Guided Review (인터랙티브 가이드 리뷰)

**목적**: 보고서의 각 섹션을 순서대로 하나씩 제시하며, 사용자와 대화형으로 리뷰 진행.

**5-A: 리뷰 개요 제시**
- 사용자에게 전체 리뷰 개요를 먼저 보여줌:
  - 문서 유형 (RFC / 현황 분석 / 커스텀)
  - 총 섹션 수
  - 각 섹션의 제목 리스트 (순서대로)
  - 저장 경로
- "리뷰를 시작하겠습니다" 안내

**5-B: 순차 리뷰 루프**
- 보고서의 섹션을 순서대로 하나씩 제시
- **각 섹션마다**:
  1. **섹션 내용 제시**: 섹션 제목, 본문 내용을 마크다운으로 출력 (코드 스니펫, 다이어그램 포함)
  2. **AskUserQuestion으로 피드백 수집**:
     - **OK**: 다음 섹션으로 진행
     - **수정 요청**: 사용자의 피드백을 받아 `writer`로 즉시 수정 → 수정된 결과를 다시 제시 → 재확인 (max 3회)
     - **추가 분석 필요**: 관련 Step (1-3)으로 회귀하여 추가 분석 후 섹션 재작성
     - **질문 있음**: 사용자 질문에 답변 후 다시 OK/수정 요청 선택
  3. 리뷰 결과 기록: `.claude/reports/review-progress-{topic-slug}.md`에 각 섹션의 리뷰 상태 (OK / 수정완료 / 보류) 기록
- **모든 섹션 리뷰 완료 후**:
  - 전체 리뷰 요약 출력 (OK 수, 수정된 수, 보류 수)
  - 수정된 섹션이 있다면: 최종 보고서 파일을 업데이트하여 저장
  - 보류 항목이 있다면: 보고서 말미에 "**추후 보완 필요**" 섹션으로 기록

**5-C: 최종 확인**
- AskUserQuestion: "모든 섹션 리뷰가 완료되었습니다. 추가 수정이 필요하신가요?"
  - **완료**: 최종 보고서 저장 경로 안내
  - **구현 시작 (simon-bot)**: 이 분석 결과를 컨텍스트로 simon-bot 워크플로를 시작합니다
  - **프로젝트 관리 (simon-bot-pm)**: 이 분석 결과를 기반으로 PM 워크플로를 시작합니다
  - **양식 변경**: Step 4에서 다른 템플릿으로 재생성
  - **추가 리뷰**: 5-B로 돌아가 특정 섹션 재리뷰

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

- 코드를 수정하지 않는다 (읽기 전용 분석). 이 스킬의 목적은 사전 분석이므로, 코드를 변경하면 분석 결과의 객관성을 잃는다. 전문가 에이전트 spawn 시 도구 범위를 Read/Glob/Grep으로 제한한다 (P-011).
- 외부 시스템에 접근하지 않는다. 분석 대상은 로컬 코드베이스에 한정된다.
- 실제 DB나 API를 호출하지 않는다. 운영 환경에 영향을 줄 수 있는 행위를 방지하기 위함이다.
- 분석 결과는 `.claude/reports/`에만 저장한다. 산출물의 위치를 일원화하여 추적과 관리를 용이하게 한다.
- 기존 코드나 설정 파일을 변경하지 않는다. 분석 과정에서 의도치 않은 부작용을 예방하기 위함이다.
