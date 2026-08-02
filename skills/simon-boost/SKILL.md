---
name: simon-boost
description: "외부 자료 분석 → simon-* 스킬 개선 제안 & 적용. 링크(블로그, GitHub, 논문, 아티클 등)를 받으면 전문가 패널이 내용을 분석하여 모든 simon-* 계열 스킬의 개선점을 찾아냅니다. Use when: (1) 링크를 주며 '이거 반영해줘', '이거 보고 스킬 개선해줘', (2) AI 에이전트 워크플로 관련 자료를 발견했을 때, (3) 다른 사람의 스킬/워크플로를 참고하고 싶을 때, (4) 새로운 기법이나 방법론을 simon에 녹이고 싶을 때. 링크를 전달받아 스킬을 개선하는 모든 상황에서 이 스킬을 사용하세요."
compatibility:
  tools: [Agent, AskUserQuestion, WebFetch, TeamCreate, SendMessage]
  # 분석 대상 스킬은 _shared/boost-target-skills.md(디렉토리 스캔)가 SSoT — frontmatter에 열거하지 않음 (drift 방지)
---

# simon-boost

외부 자료에서 인사이트를 추출하여 simon 계열 스킬을 강화하는 스킬.

링크 하나가 simon 패밀리 전체의 부스터가 됩니다.

## Instructions

You are executing **simon-boost**. 사용자가 제공한 링크의 내용을 전문가 패널이 분석하고, simon 계열 스킬들의 구체적인 개선안을 도출한 뒤, 사용자 확인 후 적용합니다.

## Target Skills

> **Reference Loading**: 분석 대상 목록은 `~/.claude/skills/_shared/boost-target-skills.md`를 읽는다 — 실제 대상은 `ls ~/.claude/skills/simon*/SKILL.md` 스캔이 SSoT다 (SKILL.md 없는 workspace 디렉토리 제외, 수동 목록 drift 방지).

references/ 디렉토리의 하위 파일들과 `_shared/*.md`도 분석 대상에 포함.

## Step 0: Input Collection

**0-A: 링크 수집**

사용자가 이미 링크를 제공했으면 바로 진행. 아직이면 AskUserQuestion:
> 분석할 링크를 알려주세요. (블로그, GitHub, 논문, 아티클 등 모두 가능)

여러 링크도 가능 — 각각 분석 후 통합.

**0-B: 관심사 확인 (선택)**

사용자가 특별히 관심 있는 영역이 있는지 확인:
> 특별히 관심 있는 개선 영역이 있나요? (없으면 전방위 분석합니다)
> - 워크플로 구조 (단계 추가/제거/순서)
> - 프롬프트/지시문 품질
> - 새로운 기법/도구 도입
> - 에러 처리/안전성
> - 전부 다

사용자가 "전부" 또는 별다른 언급이 없으면 전방위 분석.

## Step 1: Content Extraction

**1-A: 링크 내용 가져오기**

WebFetch로 링크 내용을 가져온다.

- 웹페이지: WebFetch로 본문 추출
- GitHub 레포: 주요 파일들 (README, SKILL.md, workflow 관련 파일) 탐색
- PDF/논문: 가능한 범위 내에서 내용 추출

**1-B: 핵심 내용 정리**

가져온 내용에서 simon 스킬 개선과 관련될 수 있는 핵심 내용을 정리:

```markdown
## Source Summary
- **제목**: ...
- **유형**: 블로그 / GitHub / 논문 / 기타
- **핵심 주제**: ...
- **주요 아이디어** (bullet points):
  - ...
- **관련 기법/패턴/도구**: ...
```

Save: `.claude/boost/source-summary-{slug}.md`

## Step 2: Target Skill Loading (선택적)

분석 전에 대상 스킬들의 현재 상태를 파악하되, 컨텍스트 효율을 위해 선택적으로 로딩한다.

**2-A: 관련 스킬 식별**

Step 1의 자료 요약에서 가장 관련성이 높은 스킬 1-3개를 식별한다:
- 워크플로 구조 관련 → simon (코어)
- 재시도/복구 관련 → simon-grind
- 프로젝트 관리 관련 → simon-pm
- 분석/보고서 관련 → simon-report
- 세션 관리 관련 → simon-sessions

**2-B: 단계적 로딩**

1. 식별된 스킬의 SKILL.md만 먼저 읽기 (references는 아직 읽지 않음)
2. SKILL.md에서 개선 대상 영역을 좁힌 후, 해당 references 파일만 추가 로딩
3. 나머지 스킬은 Step 3 전문가 패널에서 필요 시 개별 전문가가 직접 읽기

**예시:**
- 자료가 "에러 복구 전략"에 관한 것이면:
  - simon-dev SKILL.md + references/error-resilience.md
  - simon-grind SKILL.md + references/grind-error-resilience.md
  - 나머지 스킬은 SKILL.md description만 참조

이 방식으로 컨텍스트 소비를 1/3 이하로 줄이면서도 정확한 분석이 가능하다.

## Step 3: Expert Panel Analysis (Agent Team)

> **Reference Loading**: `~/.claude/skills/_shared/expert-panel-boost.md` 읽기 — 6인 전문가 패널 구성, 분석 항목, 토론 프로토콜, Agent Teams Fallback 포함.

전문가들이 각자의 관점에서 자료를 분석하고, simon 스킬들의 개선점을 찾아냅니다. 전문가 구성(인원·역할)과 토론 프로토콜은 위 공유 파일이 SSoT다 — 여기 복제하지 않는다.

**Agent Team 해산**

## Step 4: Improvement Report

전문가 패널의 분석 결과를 통합하여 개선 제안 리포트를 생성한다.

> **Reference Loading**: Step 4 진입 시 [examples.md](references/examples.md) 읽기

좋은 제안과 나쁜 제안의 구체적 예시는 [references/examples.md](references/examples.md)를 참조한다.

### 리포트 구조

```markdown
# simon Boost Report

## Source
- **자료**: [제목](링크)
- **분석일**: YYYY-MM-DD

## Executive Summary
(3-5줄로 핵심 인사이트 요약)

## Improvement Proposals

### [P-001] 제안 제목
- **심각도**: CRITICAL / HIGH / MEDIUM / LOW
- **대상 스킬**: simon, simon-grind, ...
- **대상 파일**: SKILL.md, references/phase-a-planning.md, ...
- **카테고리**: 워크플로 구조 / 프롬프트 품질 / 신기법 도입 / 품질·안전 / DX / 스킬 형식·구조
- **현재 상태**: (현재 어떻게 되어 있는지)
- **제안 내용**: (구체적으로 무엇을 어떻게 바꿀지)
- **기대 효과**: (왜 이게 더 나은지)
- **근거**: (자료의 어떤 내용에서 착안했는지)
- **전문가 합의**: (어떤 전문가들이 동의했는지, 반대 의견이 있었다면 포함)

### [P-002] ...
(반복)

## Cross-Cutting Observations
(여러 스킬에 공통 적용되는 패턴이나 개선 방향)

## Not Recommended
(자료에서 발견했지만 simon에 맞지 않아 채택하지 않은 아이디어와 그 이유)
```

### 리포트 제시

1. Save: `.claude/boost/report-{slug}.md`
2. Executive Summary와 전체 제안 목록(P-001~P-00N 제목 + 심각도)을 사용자에게 출력하여 전체 그림을 제공한다
3. **Severity 기반 배치 리뷰** (expert-panel-boost.md의 Proposal Severity Rubric 기준):
   - **CRITICAL / HIGH / 전문가 간 이견 항목** → 하나씩 상세 설명 후 개별 확인. 설명에 반드시 포함: 현재 상태(파일:줄 수준 인용), 문제 시나리오, 제안 내용(before/after), 변경 대상 파일, 기대 효과와 비용, 기존 메커니즘과의 관계, 근거(자료의 어느 부분인지)
   - **MEDIUM** → 클러스터(주제) 단위로 묶어 요약 설명 후 일괄 확인 — 클러스터 내 취사선택 가능
   - **LOW + 전문가 전원 동의** → 자동 적용하고 최종 요약에서 사후 보고 (사용자가 이의 시 롤백)
   - 사용자가 리뷰 방식을 직접 지정하면 그것이 우선한다
   - 제안 20건 이상이면 severity/대상 스킬 필터가 있는 self-contained HTML 트리아지 뷰를 함께 생성하는 옵션을 제안한다
   - 확인 질문은 AskUserQuestion을 사용하되, 직전 설명이 길면 질문 팝업이 본문을 가릴 수 있다 — 상세 설명 턴과 질문 턴을 분리하거나 텍스트 답변을 받는다

## Step 5: Apply Improvements

사용자가 "적용" 또는 "수정 후 적용"으로 선택한 제안들을 실제 스킬 파일에 반영한다.

**5-A: 변경 계획 수립**

적용할 제안들을 파일별로 그룹핑:
- 같은 파일에 대한 여러 제안은 한 번에 적용
- 변경 순서: references/ 파일 → SKILL.md (의존성 방향)
- 각 변경의 diff 미리보기 준비

**5-A-2: 커버리지 체크**

Agent 분배 후, 적용 실행 전에 모든 제안과 대상 파일이 누락 없이 배정되었는지 교차 확인한다. 이전 세션에서 5개 agent에 10개 제안을 분배했을 때 phase-b-implementation.md의 TOC가 어떤 agent에도 배정되지 않아 누락된 사례가 있었다.

확인 방법:
1. 적용 대상 제안 목록(P-xxx)과 각 제안의 대상 파일 목록을 나열
2. Agent별 배정 내역을 나열
3. 두 목록을 교차 대조하여 빠진 제안이나 파일이 없는지 확인
4. 누락 발견 시 배정 재조정 후 진행

**5-B: 변경 미리보기**

실제 적용 전에 각 파일의 변경 사항을 사용자에게 보여준다:

```
~/.claude/skills/simon-dev/SKILL.md
  - Line 58: Step 1-A에 새로운 분석 항목 추가
  - Line 95: Step 5에 검증 게이트 강화

~/.claude/skills/simon-dev/references/phase-a-planning.md
  - Section "Step 1-B": 인터뷰 프로토콜 개선
```

AskUserQuestion:
> 위 변경사항을 적용할까요? (전체 적용 / 개별 선택 / 취소)

**5-C: 적용**

사용자 승인 후 Edit 도구로 각 파일 수정. 변경 시 주의사항:
- 기존 스킬의 구조와 톤을 유지
- 새로운 내용이 기존 흐름에 자연스럽게 녹아들도록
- 기존 기능을 깨뜨리지 않도록
- 변경 이유를 주석이 아닌 자연스러운 지시문으로 포함

**5-D: 변경 기록**

적용된 변경사항을 기록:

Save/Append: `.claude/boost/applied-log.md`
```markdown
## [YYYY-MM-DD] {자료 제목}
- **P-001**: {제안 제목} → 적용 (simon SKILL.md, phase-a-planning.md)
- **P-002**: {제안 제목} → 수정 후 적용 (simon-grind SKILL.md)
- **P-003**: {제안 제목} → 기각 (이유: ...)
```

## Step 6: Verification

적용 후 스킬 파일의 무결성과 형식적 품질을 검증한다.

> **Reference Loading**: [skill-best-practices.md](references/skill-best-practices.md)를 반드시 Read한다. Step 3 Expert 6이 이미 읽었더라도 다시 읽는다 — Step 3과 Step 6 사이에 스킬 파일이 변경되었으므로 검증 시점의 최신 체크리스트가 필요하다.

**6-A: 기본 무결성 검증**

변경된 모든 파일에 대해 아래 항목을 검증하고, 결과를 파일별 테이블로 출력한다. "모든 항목 통과"라는 요약만으로는 검증이 충분하지 않다 — 각 파일의 각 항목을 명시적으로 보고해야 실제로 검증이 수행되었음을 보장할 수 있다.

검증 항목:
- YAML frontmatter 유효성 (SKILL.md 파일)
- references/ 파일 참조 경로 존재 여부
- 스킬 간 상호 참조 유효성 (simon-grind → simon 등)
- 변경 내용이 의도대로 반영되었는지 (Read로 재확인)

출력 형식:
```
| 파일 | frontmatter | 참조 경로 | 상호 참조 | 내용 반영 | 결과 |
|------|-------------|-----------|-----------|-----------|------|
| simon-dev/SKILL.md | OK | OK | OK | OK | PASS |
| simon-dev/references/phase-b-implementation.md | N/A | OK | N/A | OK | PASS |
```

FAIL 항목이 있으면 즉시 원인을 파악하고 수정안을 제시한다.

**6-B: 형식 품질 검증 (Skill Craft Gate)**

변경이 적용된 스킬 파일들에 대해 [skill-best-practices.md](references/skill-best-practices.md)의 전 카테고리 전 항목을 명시적으로 실행한다 (카테고리 개수·목록은 원본 파일이 SSoT — 여기 복제하지 않는다). "대충 확인"이 아니라, 각 항목을 하나씩 체크하고 결과를 테이블로 보고한다 — 이전 세션에서 이 절차를 생략하여 TOC 누락 등의 문제를 사용자가 직접 지적해야 했던 사례가 있었다.

> **Reference Loading**: [skill-best-practices.md](references/skill-best-practices.md)를 반드시 Read한다. Step 3 Expert 6이 이미 읽었더라도 다시 읽는다 — Step 3과 Step 6 사이에 파일 변경이 발생했을 수 있고, 검증 시점에 최신 체크리스트를 참조해야 정확한 검증이 가능하다.

검증 절차:
1. skill-best-practices.md를 Read
2. 변경된 각 스킬 파일에 대해 전 카테고리의 전 항목을 순회:
   - **Progressive Disclosure**: SKILL.md 500줄 이내, 3단계 로딩 활용, reference 포인터 명확성, 로딩 시점 지시
   - **Skill Decomposition**: 독립 sub-workflow 묶임 여부, 컨텍스트 소진 징후, 순환 의존
   - **Description 트리거링**: "Use when:" 조건 존재, 인접 스킬 경계 구분, 실사용 키워드 포함
   - **Writing Patterns**: 명령형, Why 설명, 예시 포함, ALWAYS/NEVER 남용 없음
   - **Frontmatter 유효성**: name/description 존재, description 길이, compatibility 정확성, YAML 문법
   - **Reference 구조**: 도메인별 분리, 로딩 시점 명시, 불필요 파일 없음, 300줄 초과 시 TOC
3. 결과를 카테고리별 테이블로 출력:

```
| 카테고리 | 항목 | 결과 | 비고 |
|----------|------|------|------|
| Progressive Disclosure | SKILL.md 500줄 이내 | PASS (297줄) | |
| Progressive Disclosure | reference 포인터 명확 | PASS | |
| Reference 구조 | 300줄 초과 TOC | FAIL | phase-b.md 365줄, TOC 없음 |
```

4. FAIL 항목이 있으면 수정안을 제시하고 사용자 승인 후 적용

## Step 7: Summary

사용자에게 최종 요약 보고:

```markdown
## Boost Complete

**자료**: [제목](링크)
**적용**: N개 제안 반영
**보류**: N개 (추후 재검토)
**기각**: N개

### 적용된 변경 요약
- simon: ... (N개 파일 수정)
- simon-grind: ... (N개 파일 수정)
- ...

### 다음에 확인할 것
- (적용된 변경이 실제 워크플로 실행 시 잘 동작하는지)
- (보류된 제안 재검토 시점)
```

## Global Rules

- 스킬 파일 수정 시 반드시 Read → Edit 순서 (Write로 덮어쓰기 금지)
- 사용자 확인 없이 스킬 파일을 수정하지 않음
- 원본 자료의 내용을 그대로 복사하지 않음 — simon 맥락에 맞게 재해석
- 기존 스킬의 Global Forbidden Rules는 절대 약화시키지 않음
- 적용 기록(applied-log.md)은 항상 유지하여 변경 이력 추적 가능
- 모든 중간/최종 결과물은 `.claude/boost/`에 저장
- **진행 체크포인트**: 각 Step 경계에서 1줄 진행 보고를 출력한다 — `[Step N 완료] {핵심 결과 요약} — Step N+1 시작` 형식. 전문가 패널 분석처럼 수 분간 무응답인 구간에서 사용자가 진행 상태를 알 수 있게 한다 (AskUserQuestion 아님, 단순 텍스트)
