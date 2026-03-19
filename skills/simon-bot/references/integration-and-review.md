# Integration & Review (Detailed Instructions)

## 목차
- [Integration Stage](#integration-stage-after-all-units-complete)
  - [커밋 메시지 상세화 (실행 이력 관리)](#커밋-메시지-상세화-실행-이력-관리)
- [Step 18: Work Report + Draft PR](#step-18-work-report--draft-pr)
  - [18-A: Report](#18-a-report)
  - [18-B: Review Sequence 생성](#18-b-review-sequence-생성)
  - [Findings Pipeline Integration (P-009)](#findings-pipeline-integration-p-009)
- [Step 19: simon-bot-review 스킬 호출](#step-19-simon-bot-review-스킬-호출)
- [Step 20: Self-Improvement (회고 기반 스킬 개선)](#step-20-self-improvement-회고-기반-스킬-개선)
  - [20-A: 피드백 종합](#20-a-피드백-종합)
  - [20-B: 개선 제안](#20-b-개선-제안)
  - [20-C: 스킬 업데이트](#20-c-스킬-업데이트)
- [Retrospective 기록 형식](#retrospective-기록-형식)

## Integration Stage (after all Units complete)

1. 모든 변경사항은 Startup에서 생성한 worktree의 브랜치에 커밋
2. 브랜치명: `.claude/memory/branch-name.md` 참조
3. If conflict: `architect` analyzes + `executor` resolves
4. Full build + test pass verification
5. **Working Example 재실행 (P-007)**: Step 6-B에서 정의한 Working Example 시나리오를 통합 환경에서 재실행하여 "테스트 통과 ≠ 실제 동작" 문제를 포착한다. `.claude/memory/unit-{name}/working-example.md`의 시나리오 참조. 실패 시 executor 수정 → 재검증 (max 3회).
6. `/simplify` 스킬 실행: 통합된 전체 변경 코드의 재사용성, 품질, 효율성 검토
7. Save: `.claude/memory/integration-result.md`
8. Update: `CONTEXT.md` — Integration 완료 표시, 성공 기준 중간 갱신
9. **Integration Retrospective Checkpoint**: **Phase-End Auto-Retrospective** 프로토콜을 실행한다 (SKILL.md Cross-Cutting Protocol 참조). Phase B-E 전체에서 축적된 사용자 피드백에서 반복 패턴을 탐지하고, 필요 시 boost-capture를 백그라운드로 트리거한다.

### 커밋 메시지 상세화 (실행 이력 관리)

문서가 아닌 **실행 이력이 SSoT(Single Source of Truth)**다. 새 세션에서도 Git 이력만으로 맥락을 파악할 수 있도록, 커밋 메시지 **body**에 다음 정보를 포함한다.

> **git-commit 스킬과의 관계**: 커밋의 제목(type + description)은 git-commit 스킬의 semantic commit 형식을 따른다. 이 섹션은 **body 부분**의 가이드라인으로, git-commit이 생성하는 제목 뒤에 추가하는 맥락 정보다.

```
{type}: {변경 요약}    ← git-commit 스킬이 생성

[해결 방식] 어떤 접근법으로 문제를 해결했는지
[난관/트레이드오프] 구현 중 마주친 어려움이나 수용한 트레이드오프 (있으면)
[의사결정] 왜 이 방식을 선택했는지, 고려한 대안 (있으면)

Refs: Unit {N} — {Unit 목적 한줄 요약}
```

이 형식은 `git log --oneline`으로도 흐름을 파악할 수 있고, `git log`로 세부 맥락까지 추적할 수 있게 한다. Unit별 커밋이므로 각 커밋이 하나의 논리적 변경 단위를 대표한다.

## Step 18: Work Report + Draft PR

> **[GATE — 필수 실행]** Step 18-19는 SMALL/STANDARD/LARGE **모든 경로**에서 반드시 실행한다. 경로나 변경 규모에 관계없이 skip 불가. PR 생성은 Step 19에서 simon-bot-review 스킬이 담당한다 — simon-bot/grind가 직접 `gh pr create`를 실행하는 것은 금지다.

**IMPORTANT: Step 18은 반드시 foreground에서 실행한다.**

> **Background Agent 사용 기준 (전체 워크플로 공통)**:
> - **OK**: 빌드/테스트 검증, 독립적 Unit 병렬 실행
> - **NO**: 다음 Step의 입력 파일을 생성하는 작업, 후속 단계가 즉시 의존하는 산출물

### 18-A: Report

- Spawn `writer` — Use template: `.claude/workflow/templates/report-template.md`
- **Language:** Follow `language` setting in `config.yaml` (default: `ko`)
- Contents:
  - Before/After flow diagrams
  - Key review points (with code snippets)
  - Trade-offs considered
  - Potential risks
  - Test results explained
  - NOT in scope items
  - Unresolved decisions (with "may bite you later" warnings)
- Save: `.claude/reports/{feature-name}-report.md`

### 18-B: Review Sequence 생성

- Spawn `architect`: 전체 변경사항을 **논리적 변경 단위(Logical Change Unit)**로 그룹핑
- 논리적 변경 단위 = 하나의 목적/기능을 달성하기 위해 함께 변경된 파일들의 묶음
- **정렬 기준**: 데이터/호출 흐름 순서 (상류 → 하류)
- **필수 입력**: `.claude/memory/plan-summary.md`를 읽어 각 변경 단위가 계획의 어떤 Unit/목표에 해당하는지 매핑

각 논리적 변경 단위에 포함할 정보:
- **제목**: 이 변경이 무엇을 하는지 한 줄 요약
- **계획 매핑**: `plan-summary.md`의 어떤 Unit/목표를 구현한 것인지
- **변경 이유**: 왜 이 변경이 필요한지
- **변경 전 상태 (Before Context)**: 변경 전 코드/모듈의 상태와 역할
- **변경 내용 (What Changed)**: 구체적으로 어떤 부분을 어떻게 개선/추가했는지
- **관련 파일 목록**: 변경된 파일과 각 파일의 역할
- **핵심 코드 변경**: Before/After diff (중요 부분만 발췌)
- **리뷰 포인트**: 특별히 주의 깊게 봐야 할 부분
- **다른 변경 단위와의 연관**: 의존/호출/데이터 흐름 관계
- **전문가 우려사항 반영**: Step 4-B/7에서 관련 우려 반영 내용
- **트레이드오프**: 설계 결정과 그 이유
- **아키텍처 영향 분석**: code-design-analysis.md 대비 구현된 변경의 아키텍처 영향 (의존성 방향, 모듈 경계, 확장성, 데이터 흐름). STANDARD+ 경로에서만 포함. 이 정보는 simon-bot-review의 Review Summary Architecture Impact 섹션에서 활용된다.
- **테스트 커버리지 요약**: `.claude/memory/unit-{name}/test-case-summary.md`에서 해당 변경 단위의 테스트 분류를 발췌. 어떤 시나리오가 Happy Path로 검증되고, 어떤 시나리오가 Edge/Error Case로 검증되는지 포함한다. test-case-summary.md가 없으면 테스트 코드를 직접 분석하여 동등한 분류를 생성한다. (예: "Happy Path 2개, Edge Case 3개, Error Case 1개 — 빈 입력, 최대 길이 초과, DB 타임아웃 등 검증")
- **영향 분석**: 변경되지 않았지만 영향받을 수 있는 코드. 변경된 함수의 직접 호출자, 인터페이스 소비자, 공유 상태 독자, 데이터 흐름 하류를 1-depth로 Grep 탐색하여 식별한다. 각 항목에 파일:라인, 영향받는 이유, 필요 조치를 포함한다.

- Save: `.claude/memory/review-sequence.md`

### Findings Pipeline Integration (P-009)

review-sequence.md 작성 시, Step 7의 `review-findings.md`에서 CRITICAL/HIGH findings를 구조화된 형태로 포함한다:

```markdown
### {변경 단위명}
**전문가 검증 완료 이슈:**
| ID | Severity | File:Line | Issue | Verification | Acceptance |
|----|----------|-----------|-------|-------------|------------|
| {finding_id} | {severity} | {file:line} | {issue 요약} | {VERIFIED/UNVERIFIED} | {status} |
```

이 매핑은 Step 19(simon-bot-review)에서 인라인 코멘트 생성의 입력이 된다. findings의 FINDING_ID, SEVERITY, FILE:LINE, EVIDENCE 정보가 손실되지 않도록 한다.

## Step 19: simon-bot-review 스킬 호출

Step 18-B 완료 후, simon-bot-review 스킬 호출 전에 `{SESSION_DIR}/memory/handoff-manifest.json`을 생성한다 (SKILL.md의 Handoff Manifest 참조). transfer_files에 review-sequence.md, branch-name.md, {feature-name}-report.md, plan-summary.md를 포함하고, block_files에 implementation.md, inline-issues.md를 포함하여 Cognitive Independence를 구조적으로 보장한다.

그 후 `simon-bot-review` 스킬을 호출하여 Draft PR 생성부터 인라인 코드 리뷰, CI Watch, 피드백 루프, 최종 마무리까지 위임한다.

**simon-bot-review 중단 시 복구 책임**: simon-bot-review 실행 중 push 실패, API 오류 등으로 흐름이 중단되면, 문제 해결 후 simon-bot-review의 잔여 워크플로(특히 Step 2 인라인 리뷰, Step 3 CI Watch)를 자동 재개해야 한다. PR 생성만으로 Step 19가 "완료"되지 않는다 — simon-bot-review의 Completion Summary가 출력될 때까지가 Step 19의 범위다.

simon-bot-review는 `.claude/memory/review-sequence.md`를 감지하여 CONNECTED 모드로 동작하며, 아래 산출물을 활용한다:
> **Blind-First 2-Pass**: CONNECTED 모드에서 simon-bot-review는 review-sequence.md를 읽기 전에 diff를 먼저 독립 분석하여, 구현자 프레이밍에 anchoring되지 않는 독립적 리뷰를 수행한다 (`context-separation.md` 참조).
- `.claude/memory/review-sequence.md` (Step 18-B 산출물)
- `.claude/memory/branch-name.md`
- `.claude/reports/{feature-name}-report.md` (Step 18-A 산출물)
- `.claude/memory/plan-summary.md` (계획 매핑용)

simon-bot-review가 처리하는 항목:
- Draft PR 생성 + Review Guide 섹션 추가
- 인라인 코드 리뷰 코멘트 작성 (변경 단위별, 풍부한 맥락 포함)
- CI Watch (background agent)
- 사용자 PR 피드백 수집 → 수정 → 인라인 리뷰 재작성 → CI 재검증 루프
- 최종 마무리 (PR ready 전환, feedback.md, retrospective.md, CONTEXT.md 갱신)
- Completion Summary 출력

## Step 20: Self-Improvement (회고 기반 스킬 개선)

워크플로 전체에서 축적된 사용자 피드백을 분석하여, 스킬 자체의 개선이 필요한지 판단하고 적용한다.

이 단계의 목적: simon-bot/simon-bot-grind가 매 사용마다 조금씩 더 나아지는 자기 개선 루프를 만드는 것. 사용자가 반복적으로 같은 불편을 겪거나, 워크플로의 특정 부분이 계속 마찰을 일으킨다면, 그건 스킬 자체를 고쳐야 한다는 신호다.

> **Phase-End Auto-Retrospective와의 관계**: Phase 경계에서 이미 캡처된 인사이트(`~/.claude/boost/insights/`)와 retrospective.md의 Phase-End Checkpoint 기록을 먼저 확인한다. 이미 캡처된 패턴은 중복 분석하지 않고, Step 20은 **Phase 간 교차 패턴** (여러 Phase에 걸쳐 반복되는 문제)에 집중한다. 컨텍스트 부족으로 Step 20이 실행되지 않아도, 핵심 인사이트는 Phase-end에서 이미 캡처된 상태이므로 안전하다.

### 20-A: 피드백 종합

1. `.claude/memory/user-feedback-log.md` 전체 읽기
2. `~/.claude/boost/insights/`에서 이번 세션에서 Phase-End Auto-Retrospective가 캡처한 인사이트 확인 — 이미 캡처된 패턴을 식별하여 중복 분석을 방지한다
3. 패턴 식별 (이미 캡처된 패턴 제외):
   - **Phase 간 교차 패턴**: 여러 Phase에 걸쳐 반복된 문제 (Phase-end에서 개별적으로는 감지되지 않았지만 전체를 보면 드러나는 패턴)
   - **반복 교정**: 사용자가 2회 이상 같은 유형의 수정을 요청한 패턴
   - **워크플로 마찰**: 특정 단계에서 반복적으로 불만/지연이 발생한 패턴
   - **선호도 패턴**: 사용자가 일관되게 선호하는 방식 (코드 스타일, 커뮤니케이션 방식 등)
   - **과잉 엔지니어링**: 불필요하다고 지적된 단계나 검증
4. 각 패턴을 분류:
   - `CONFIG`: config.yaml에 옵션 추가로 해결 가능
   - `WORKFLOW`: 워크플로 단계/순서 변경 필요
   - `CAPABILITY`: 새 기능/도구 필요
   - `REMOVAL`: 불필요한 단계 제거

- **반복 교정 → Gotchas 자동 변환**: user-feedback-log.md에서 2건+ 동일 유형 수정 요청(반복 교정)이 감지되면, 해당 패턴이 프로젝트 고유 gotcha인지 판단한다. 프로젝트 고유이면 `~/.claude/projects/{slug}/state/gotchas.jsonl`에 append한다 — 형식: `{"id": "G-xxx", "category": "...", "gotcha": "...", "source_step": "Step 20", "source_session": "{branch}", "added_at": "YYYY-MM-DD"}`. project-memory.json의 빌드 에러 패턴과 중복되지 않도록 교차 확인한다.

### 20-B: 개선 제안

1. 일회성 선호가 아닌 **체계적 패턴**만 제안 대상으로 선별
2. 각 제안에 포함:
   - 무엇을 변경할지
   - 왜 변경이 필요한지 (어떤 피드백에서 도출)
   - 예상 영향 범위
3. 사용자에게 요약 제시 (AskUserQuestion):
   > "이번 워크플로에서 N개의 개선 패턴을 발견했습니다:
   > 1. [패턴 설명] — [제안]
   > 2. [패턴 설명] — [제안]
   > 스킬 개선을 진행할까요?"

### 20-C: 스킬 업데이트

사용자가 동의하면:
1. **skill-creator** 스킬을 호출하여 개선 실행
2. 변경 내용을 `retrospective.md`에 기록
3. 변경하지 않기로 한 항목도 이유와 함께 기록

사용자가 거절하거나 개선 패턴이 없으면:
- retrospective.md만 기록하고 종료

## Retrospective 기록 형식

`.claude/memory/retrospective.md` 구조:

```markdown
# Retrospective: {feature-name}

## Summary
- Branch: {branch}
- Scope: SMALL / STANDARD / LARGE
- PR: {url}

## What Went Well
- (워크플로에서 잘 작동한 부분)

## What Could Be Better
- (마찰이 있었던 부분, 개선 여지)

## User Feedback Patterns
- (user-feedback-log.md에서 추출한 주요 패턴)

## Skill Improvements Applied
- [ ] Change 1: rationale
- [ ] Change 2: rationale

## Lessons for Future Sessions
- (다음 세션의 Phase A에서 참고할 교훈)
```

이 파일은 다음 세션의 Startup에서 읽혀 Phase A 계획에 반영된다.
