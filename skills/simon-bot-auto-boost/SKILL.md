---
name: simon-bot-auto-boost
description: "자동 웹 검색 기반 스킬 개선 — Claude Code 공식 문서, Hacker News, YouTube, Medium, dev.to 등에서 최신 AI 코딩 에이전트 best practices를 자동 검색하고, 전문가 패널 분석을 거쳐 simon-bot 계열 스킬을 개선합니다. Use when: (1) '자동으로 개선점 찾아줘', '최신 사례 검색해서 반영해줘', '새로운 거 있나 찾아봐', (2) 'auto boost', 'auto-boost', (3) '스킬 자동 업데이트', '최신 트렌드 반영', (4) Claude Code나 AI 에이전트 관련 최신 정보를 찾아 스킬에 반영하고 싶을 때. simon-bot-boost와 다른 점: boost는 사용자가 링크를 제공하지만, auto-boost는 자동으로 웹 검색하여 최신 콘텐츠를 발견합니다."
compatibility:
  tools: [Agent, WebSearch, WebFetch, TeamCreate, SendMessage]
  skills: [simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report, simon-bot-sessions, simon-bot-review, simon-company]
---

# simon-bot-auto-boost

웹을 자동 검색하여 최신 AI 코딩 에이전트 best practices를 발견하고, 전문가 패널 분석 → 사용자 승인 → 적용 → 검증 → 테스트까지 완료하는 스킬.

## simon-bot-boost와의 관계

| | simon-bot-boost | simon-bot-auto-boost |
|---|---|---|
| 입력 | 사용자가 링크 제공 | 자동 웹 검색 |
| 검색 범위 | 단일 리소스 | 다중 소스 (docs, HN, Medium, YouTube 등) |
| 시간 필터 | 없음 | 마지막 검색 이후 콘텐츠만 |
| 분석 | 전문가 패널 6인 | 전문가 패널 6인 (동일) |
| 검증 | 기본 무결성 + 형식 품질 | 기본 무결성 + 형식 품질 + 스킬 가이드라인 + 스모크 테스트 |

분석 대상 스킬은 simon-bot-boost와 동일:
simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report, simon-bot-sessions, simon-bot-review, simon-company

## 상태 파일

`~/.claude/boost/auto-boost-state.json`에 검색 이력을 기록한다.

```json
{
  "last_search_at": "2026-03-13T14:00:00+09:00",
  "processed_urls": ["https://..."],
  "search_history": [
    {
      "searched_at": "2026-03-13T14:00:00+09:00",
      "urls_found": 12,
      "urls_selected": 5,
      "improvements_applied": 3
    }
  ]
}
```

- 첫 실행 시 파일이 없으면 생성하고, 최근 2주를 기본 검색 범위로 사용한다.
- `processed_urls`가 200개를 초과하면 오래된 항목부터 정리한다 (무한 증가 방지).

---

## Phase 1: 상태 로드 & 검색

### Step 1-1: 상태 로드

`~/.claude/boost/auto-boost-state.json`을 읽는다.

사용자에게 현재 상태를 간단히 보고한다:
> "마지막 검색: {날짜}. {날짜} 이후 새로운 콘텐츠를 검색합니다."

첫 실행이면:
> "첫 실행입니다. 최근 2주간의 콘텐츠를 검색합니다."

### Step 1-2: 검색 실행

아래 4개 카테고리의 검색 쿼리를 WebSearch로 **병렬** 실행한다.
날짜 필터를 포함하여 `last_search_at` 이후 콘텐츠만 찾는다.
`{year}`는 현재 연도, `{date_filter}`는 `after:{last_search_date}` 형식.

**카테고리 1 — Claude Code 공식 & 핵심**
```
"Claude Code" best practices {year}
"Claude Code" tips workflow {year}
"Claude Code" MCP hooks skills
site:docs.anthropic.com claude code
site:github.com/anthropics claude-code
```

**카테고리 2 — 커뮤니티 & 뉴스**
```
site:news.ycombinator.com "Claude Code"
site:news.ycombinator.com "agentic coding" OR "AI coding agent"
"Claude Code" site:reddit.com {year}
```

**카테고리 3 — 튜토리얼 & 사례**
```
site:medium.com "Claude Code" OR "AI coding agent" workflow {year}
site:dev.to "Claude Code" OR "agentic coding"
"Claude Code" tutorial OR guide {year}
site:youtube.com "Claude Code" {year}
```

**카테고리 4 — AI 코딩 에이전트 일반**
```
AI coding agent workflow best practices {year}
"agentic coding" patterns tips {year}
LLM coding assistant prompt engineering {year}
coding agent skills workflow automation {year}
```

카테고리별로 Agent를 spawn하여 병렬 검색하면 처리량이 크게 향상된다.

### Step 1-3: 결과 정리 & 중복 제거

검색 결과를 정리한다:
1. `processed_urls`에 있는 URL 제거 (이미 처리됨)
2. 중복 URL 제거
3. 관련성 기준으로 정렬 — Claude Code 직접 관련 > AI 에이전트 일반, 구체적 기법 포함 > 일반 소개, 최신 > 오래된 것
4. 상위 15개 이내로 후보 축소

결과가 없으면 사용자에게 알리고 종료:
> "{last_search_at} 이후 새로운 관련 콘텐츠가 발견되지 않았습니다."

결과가 있으면 표 형태로 제시한다:

```
| # | 제목 | 출처 | 날짜 | 관련성 | 요약 |
|---|------|------|------|--------|------|
| 1 | ... | HN | 2026-03-10 | ★★★ | ... |
| 2 | ... | Medium | 2026-03-08 | ★★☆ | ... |
```

사용자가 분석할 항목을 선택한다. "전체" 선택도 가능.

---

## Phase 2: 콘텐츠 추출 & 분석 준비

### Step 2-1: 콘텐츠 추출

선택된 URL들을 WebFetch로 병렬 가져온다.

접근 제한 대처:
- Medium paywall: 검색 스니펫 기반으로 분석
- YouTube: 영상 설명문 + 댓글 기반 분석
- WebFetch 실패: 건너뛰고 사용자에게 알림, 검색 스니펫으로 대체 시도

각 콘텐츠의 소스 요약본을 생성한다:

```markdown
## 소스: {제목}
- URL: {url}
- 출처: {platform}
- 날짜: {date}
- 핵심 내용: {2-3문장}
- 주요 기법/패턴: ...
- simon-bot 관련성: {어떤 스킬의 어떤 부분에 적용 가능한지}
```

소스 요약본을 `~/.claude/boost/report-auto-{timestamp}.md`에 저장한다.

### Step 2-2: 대상 스킬 선택적 로딩

모든 스킬을 한 번에 로딩하면 컨텍스트가 낭비된다.
소스 요약본의 관련성을 기반으로 가장 관련 있는 2-3개 스킬의 SKILL.md만 로딩한다.
나머지 스킬은 전문가 패널에서 필요 시 개별 전문가가 직접 읽는다.

---

## Phase 3: 전문가 패널 분석

simon-bot-boost의 6인 전문가 패널과 동일한 구조를 사용한다.

**전문가 구성:**
1. **Workflow Architect** — 워크플로 구조, 단계 순서, 게이트 설계
2. **Prompt Engineer** — 프롬프트 품질, 지시문 명확성, 예시 적절성
3. **Innovation Scout** — 새로운 기법, 패턴, 도구 활용 가능성
4. **Quality & Safety Guardian** — 에러 처리, 안전장치, 엣지케이스
5. **DX Specialist** — 개발자 경험, 피드백 루프, 사용 편의성
6. **Skill Craft Specialist** — 스킬 구조, progressive disclosure, 트리거링
   > Skill Craft Specialist는 분석 전 `~/.claude/skills/simon-bot-boost/references/skill-best-practices.md`를 읽는다.

**실행:**
- Agent Team 사용 가능 → TeamCreate로 팀 토론 (3라운드: 독립 분석 → 교차 토론 → 합의 도출)
- Agent Team 사용 불가 → 6개 Agent를 병렬 spawn, 결과를 `~/.claude/boost/expert-findings/auto-{timestamp}/`에 기록 후 오케스트레이터가 통합

**각 전문가에게 제공하는 컨텍스트:**
- 소스 요약본 (Phase 2)
- 관련 스킬의 SKILL.md 내용
- `~/.claude/boost/applied-log.md` 최근 항목 (중복 제안 방지)

**분석 결과 형식:**
```markdown
### [P-001] 제안 제목
- **전문가**: Workflow Architect
- **심각도**: CRITICAL / HIGH / MEDIUM / LOW
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md, references/phase-a-planning.md
- **출처**: {어떤 소스에서 영감을 받았는지}
- **현재 상태**: {현재 코드/지시문}
- **개선안**: {구체적 변경 내용}
- **근거**: {왜 이 변경이 필요한지}
- **전문가 합의**: {동의/반대 의견}
```

---

## Phase 4: 개선안 승인 & 적용

### Step 4-1: 개선 보고서 제시

전문가 제안을 심각도 순(CRITICAL → HIGH → MEDIUM → LOW)으로 정렬하여 사용자에게 제시한다.

**인터랙티브 개별 리뷰**: 각 제안을 하나씩 상세히 설명하고 판단을 요청한다.
10개+ 제안을 한 번에 판단하는 것은 과도한 부담이므로, 하나씩 맥락을 전달하고 즉시 판단을 받는다.

각 제안 설명 시 포함:
- **현재 상태**: 현재 코드/스킬이 어떻게 되어 있는지 (파일:줄 수준)
- **제안 내용**: before/after 또는 추가 내용 예시
- **기대 효과와 비용**: 왜 더 나은지 + 추가 비용
- **기존 메커니즘과의 관계**: 유사 기능이 있다면 어떻게 다른지

사용자 판단: **적용** / **보류** / **거부**

### Step 4-2: 변경 적용

승인된 제안을 대상 스킬 파일에 적용한다:
- 같은 파일에 대한 여러 제안은 배치로 묶어 한 번에 적용
- 적용 전 diff 미리보기 제공, 사용자 최종 확인 후 Edit
- 변경 순서: references/ 파일 → SKILL.md (의존성 방향)
- 기존 스킬의 구조와 톤을 유지하고, 기존 기능을 깨뜨리지 않도록 주의

적용 기록을 `~/.claude/boost/applied-log.md`에 추가:
```markdown
## [AUTO-BOOST] {날짜}
- 검색 범위: {last_search_at} ~ {now}
- 소스: {분석한 URL 목록}
- 적용: {N}건 / 보류: {N}건 / 거부: {N}건

### 적용된 변경
1. [{스킬}] {제안 제목} — {전문가} / 파일: {경로} / 변경: {요약}
```

---

## Phase 5: 검증 & 테스트

적용된 변경이 스킬 품질을 저하시키지 않았는지 확인하는 3단계 검증.

### Step 5-1: 기본 무결성 검증

변경된 모든 파일에 대해 아래 항목을 검증하고, 결과를 파일별 테이블로 출력한다.
"모든 항목 통과"라는 요약만으로는 불충분 — 각 파일의 각 항목을 명시적으로 보고해야 실제 검증이 수행되었음을 보장할 수 있다.

검증 항목:
- YAML frontmatter 유효성 (SKILL.md 파일)
- references/ 파일 참조 경로 존재 여부
- 스킬 간 상호 참조 유효성
- 변경 내용이 의도대로 반영되었는지 (Read로 재확인)

```
| 파일 | frontmatter | 참조 경로 | 상호 참조 | 내용 반영 | 결과 |
|------|-------------|-----------|-----------|-----------|------|
| simon-bot/SKILL.md | OK | OK | OK | OK | PASS |
```

FAIL 항목이 있으면 즉시 수정한다.

### Step 5-2: 스킬 작성 가이드라인 검증

> **Reference Loading**: `~/.claude/skills/simon-bot-boost/references/skill-best-practices.md`를 반드시 Read한다.

skill-best-practices.md의 6개 카테고리 전 항목을 변경된 스킬에 대해 명시적으로 실행한다:

1. **Progressive Disclosure** — SKILL.md 500줄 이내, 3단계 로딩 활용, reference 포인터 명확, 로딩 시점 지시
2. **Skill Decomposition** — 독립 sub-workflow 묶임 여부, 컨텍스트 소진 징후, 순환 의존
3. **Description 트리거링** — "Use when:" 조건, 인접 스킬 경계, 실사용 키워드
4. **Writing Patterns** — 명령형, Why 설명, 예시 포함, ALWAYS/NEVER 남용 없음
5. **Frontmatter 유효성** — name/description 존재, description 길이, YAML 문법
6. **Reference 구조** — 도메인별 분리, 로딩 시점 명시, 300줄 초과 시 TOC

결과를 카테고리별 테이블로 출력한다. FAIL 항목은 수정 후 재검증.

### Step 5-3: 스모크 테스트

변경된 각 스킬이 정상적으로 로드되고 첫 단계가 실행되는지 확인한다.

Agent를 spawn하여 해당 스킬의 대표적 트리거 프롬프트로 실행한다:
- 스킬이 정상 트리거되는지
- SKILL.md가 파싱되고 첫 Step 지시가 실행되는지
- 참조 파일 로딩 지시가 작동하는지

전체 워크플로 실행은 불필요 — 스킬이 깨지지 않았다는 확인이 목적이다.
에러 발생 시 원인을 파악하고 수정한 뒤 재실행한다.

---

## Phase 6: 상태 업데이트 & 완료

### Step 6-1: 상태 파일 업데이트

`~/.claude/boost/auto-boost-state.json`을 업데이트한다:
- `last_search_at`: 현재 시각으로 갱신
- `processed_urls`: 이번에 처리한 URL 추가 (200개 초과 시 오래된 항목 정리)
- `search_history`: 이번 검색 기록 추가

### Step 6-2: 최종 요약

```
## Auto-Boost 완료 요약

- 검색 범위: {last_search_at} ~ {now}
- 발견한 콘텐츠: {N}건
- 선택하여 분석: {N}건
- 전문가 제안: {N}건
- 적용: {N}건 / 보류: {N}건 / 거부: {N}건
- 다음 실행 시 검색 시작점: {now}

### 적용된 주요 변경
1. ...
2. ...
```

### Step 6-3: 동기화 안내

스킬 파일이 변경되었으므로 simon-bot-sync가 세션 종료 시 자동으로 동기화한다.
즉시 동기화가 필요하면 `/simon-bot-sync`를 안내한다.

---

## 에러 처리

| 상황 | 대처 |
|------|------|
| WebSearch 실패 | 쿼리를 변형하여 재시도 (최대 3회) |
| WebFetch 실패 | URL 건너뛰고 사용자 알림, 검색 스니펫으로 대체 분석 |
| 전문가 패널 실패 | Agent Team → 개별 Agent 폴백 |
| 상태 파일 손상 | 백업 후 초기 상태로 재생성, 사용자 알림 |
| 검색 결과 0건 | 사용자에게 알리고 정상 종료 |

## Global Rules

- 스킬 파일 수정 시 반드시 Read → Edit 순서 (Write로 덮어쓰기 금지)
- 사용자 확인 없이 스킬 파일을 수정하지 않음
- 원본 자료를 그대로 복사하지 않음 — simon-bot 맥락에 맞게 재해석
- 기존 스킬의 Global Forbidden Rules는 절대 약화시키지 않음
- 모든 중간/최종 결과물은 `~/.claude/boost/`에 저장
- 적용 기록(applied-log.md)은 항상 유지
