# Integration & Review (Detailed Instructions)

## 목차
- [Integration Stage](#integration-stage-after-all-units-complete)
  - [커밋 메시지 상세화 (실행 이력 관리)](#커밋-메시지-상세화-실행-이력-관리)
- [Step 18: Work Report + Draft PR](#step-18-work-report--draft-pr)
  - [18-A: Report](#18-a-report)
  - [18-B: Review Sequence 생성](#18-b-review-sequence-생성)
  - [Findings Pipeline Integration (P-009)](#findings-pipeline-integration-p-009)
- [Step 19: simon-code-review 스킬 호출](#step-19-simon-code-review-스킬-호출)
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
6-A. **[GATE — 필수, skip 불가, 결정론적] 주석 노이즈 스캔**: `.claude/workflow/scripts/check-comment-noise.sh` 를 실행한다(인자 없으면 origin/main→master→HEAD~1 자동 폴백).

   - **exit 1 (FAIL)** — 코드 변경 없이 주석만 추가된 hunk / 변경 이력·이관 경과 서술 / 세션 산출물 참조(`design.md`, `Decision N`, `tasks N.N`)가 검출됐다. 이 세 패턴은 [phase-b-implementation.md](phase-b-implementation.md) 주석 최소화의 예외 1~5 어디에도 해당하지 않으므로 **AUTO-FIX로 제거**한다(로직 무변경이라 사용자 확인 불필요). 제거 후 스크립트를 재실행해 exit 0을 확인한다.
   - **exit 0 + `[GATE-WARN]`** — 선언부에 붙지 않은 연속 3줄 이상 산문 주석 블록이거나 주석 비율이 임계를 넘었다. 목록의 각 주석에 대해 **"예외 1~5 중 몇 번인가"를 1줄로 답하고, 답하지 못하는 주석은 삭제**한다. 사용자가 명시적으로 요청한 주석은 유지한다. 이 판정은 LLM 몫이며 스크립트는 후보만 제시한다.
   - **exit 0 + `[GATE-PASS]`** — 다음 단계로 진행.

   Why 이 게이트가 `/simplify` 앞에 별도로 존재하는가: `/simplify`는 관점별 findings 상한이 있는 다중 에이전트 도구여서, 파일 전체에 산재한 100건 단위의 저-salience 주석 노이즈가 굵직한 발견들과 경쟁해 구조적으로 밀린다. 볼륨형 문제는 계수로 잡고, 판단형 문제만 `/simplify`에 맡긴다. 또한 주석 규칙은 이미 한 번(2026-06) 텍스트로만 강화되었다가 실패했으므로, 이번에는 측정 가능한 게이트를 둔다.

6-B. **[GATE — 필수, skip 불가] `/simplify` 스킬 실행**: 6-A를 통과한 diff를 대상으로 재사용성·품질·효율성을 정리한다. 이 게이트는 모든 경로에서 구현 완료 후 **반드시 1회** 실행한다 — simplify는 변경 diff 전체를 보는 도구이므로, 모든 Unit이 병합된 이 시점이 권위 있는 단일 실행 지점이다. Phase B Step 5의 Post-Implementation Simplicity Check(per-unit 경량 자기 검증)와 달리, 여기서는 실제 `/simplify` 스킬을 호출한다. **주석 노이즈는 6-A가 담당하므로 `/simplify`에 위임하지 않는다.**
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

> **[GATE — 필수 실행]** Step 18-19는 STANDARD/LARGE **모든 경로**에서 반드시 실행한다. 경로나 변경 규모에 관계없이 skip 불가. PR 생성은 Step 19에서 simon-code-review 스킬이 담당한다 — simon/grind가 직접 `gh pr create`를 실행하는 것은 금지다.

**IMPORTANT: Step 18은 반드시 foreground에서 실행한다.**

> **Background Agent 사용 기준 (전체 워크플로 공통)**:
> - **OK**: 빌드/테스트 검증, 독립적 Unit 병렬 실행
> - **NO**: 다음 Step의 입력 파일을 생성하는 작업, 후속 단계가 즉시 의존하는 산출물

### 18-A: Report

- Spawn `writer` (model: sonnet) — Use template: `.claude/workflow/templates/report-template.md`
- **컨텍스트 보호 원칙**: writer subagent는 git diff, unit-{name}/review-findings.md, plan-summary.md를 직접 읽고 보고서를 파일에 저장한다. 오케스트레이터는 writer에게 컨텍스트를 통째로 전달하거나, writer의 중간 탐색 출력을 메인 컨텍스트로 받지 않는다. **반환값: 파일 경로 1줄** (`DONE: .claude/reports/{feature-name}-report.md 생성 완료`). 보고서 내용이 필요하면 메인이 직접 파일을 Read한다.
- **Language:** Follow `language` setting in `config.yaml` (default: `ko`)
- Contents:
  - Before/After flow diagrams
  - Key review points (with code snippets)
  - Trade-offs considered
  - Potential risks
  - Test results explained
  - NOT in scope items
  - Unresolved decisions (with "may bite you later" warnings)

**Deviations from Plan**: writer subagent가 (a) decision-journal.md에서 plan-summary.md 서술과 다른 결정만 필터링, (b) inline-issues.md 중 계획 범위 관련 항목을 병합하여 "계획: X → 구현: Y — 사유: Z" 형식 3-5줄로 요약한다. 이탈이 없으면 "None"으로 명시한다. PR description에 포함되어 리뷰어가 계획 대비 실제 구현의 차이를 즉시 파악하게 한다. (새 데이터를 만들지 않는다 — 기존 두 로그의 재구성이다)

**이해 체크 (LARGE 스코프 한정, 선택적)**: Work Report 말미에 변경사항에 대한 3문항 이내 이해 확인 질문을 포함한다 (예: "X 상황에서 동작이 어떻게 달라지는가"). 사용자가 답하면 실제 구현과 대조해 다른 지점을 짚어 재설명한다 — grind 재시도가 누적된 경로일수록 의도 표류 검증 가치가 크다. STANDARD/SMALL에는 생성하지 않는다.

- Save: `.claude/reports/{feature-name}-report.md`

### 18-B: Review Sequence 생성

- Spawn `architect` (model: sonnet): 전체 변경사항을 **논리적 변경 단위(Logical Change Unit)**로 그룹핑
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
- **아키텍처 영향 분석**: code-design-analysis.md 대비 구현된 변경의 아키텍처 영향 (의존성 방향, 모듈 경계, 확장성, 데이터 흐름). STANDARD+ 경로에서만 포함. 이 정보는 simon-code-review의 Review Summary Architecture Impact 섹션에서 활용된다.
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

이 매핑은 Step 19(simon-code-review)에서 인라인 코멘트 생성의 입력이 된다. findings의 FINDING_ID, SEVERITY, FILE:LINE, EVIDENCE 정보가 손실되지 않도록 한다.

### gstack 스킬 제안 (Post-Report)

Step 18 완료 후, gstack이 설치되어 있으면(`~/.claude/skills/gstack/SKILL.md` 존재) 현재 프로젝트 상황에 맞는 gstack 스킬을 제안한다:

- **프론트엔드 변경이 포함된 경우**: `/design-review` (시각적 QA — 스크린샷 비교, 간격/정렬 검증)
- **보안 관련 변경이 포함된 경우**: `/cso` (OWASP + STRIDE 보안 감사)
- **배포 준비가 된 경우 (PR 이후)**: `/ship` → `/land-and-deploy` → `/canary` (배포 파이프라인)
- **성능에 민감한 변경인 경우**: `/benchmark` (Core Web Vitals, 번들 사이즈 측정)
- **대규모 문서 변경이 필요한 경우**: `/document-release` (README/ARCHITECTURE/CHANGELOG 동기화)
- **디버깅이 필요한 경우**: `/investigate` (4단계 근본 원인 분석)

형식: "gstack 스킬 제안: 이 변경에는 `/design-review`(UI 시각적 QA)가 도움이 될 수 있습니다."

사용자가 거부하면 제안을 중단한다. gstack 미설치 시 이 섹션 전체를 건너뛴다.

## Step 19: simon-code-review 스킬 호출

Step 18-B 완료 후, simon-code-review 스킬 호출 전에 `{SESSION_DIR}/memory/handoff-manifest.json`을 생성한다 (SKILL.md의 Handoff Manifest 참조). transfer_files에 review-sequence.md, branch-name.md, {feature-name}-report.md, plan-summary.md를 포함하고, block_files에 implementation.md, inline-issues.md를 포함하여 Cognitive Independence를 구조적으로 보장한다.

그 후 `simon-code-review` 스킬을 호출하여 Draft PR 생성부터 인라인 코드 리뷰, CI Watch, 피드백 루프, 최종 마무리까지 위임한다.

**simon-code-review 중단 시 복구 책임**: simon-code-review 실행 중 push 실패, API 오류 등으로 흐름이 중단되면, 문제 해결 후 simon-code-review의 잔여 워크플로(특히 Step 2 인라인 리뷰, Step 3 CI Watch)를 자동 재개해야 한다. PR 생성만으로 Step 19가 "완료"되지 않는다 — simon-code-review의 Completion Summary가 출력될 때까지가 Step 19의 범위다.

simon-code-review는 `.claude/memory/review-sequence.md`를 감지하여 CONNECTED 모드로 동작하며, 아래 산출물을 활용한다:
> **Blind-First 2-Pass**: CONNECTED 모드에서 simon-code-review는 review-sequence.md를 읽기 전에 diff를 먼저 독립 분석하여, 구현자 프레이밍에 anchoring되지 않는 독립적 리뷰를 수행한다 (`context-separation.md` 참조).
- `.claude/memory/review-sequence.md` (Step 18-B 산출물)
- `.claude/memory/branch-name.md`
- `.claude/reports/{feature-name}-report.md` (Step 18-A 산출물)
- `.claude/memory/plan-summary.md` (계획 매핑용)

simon-code-review가 처리하는 항목:
- Draft PR 생성 + Review Guide 섹션 추가
- 인라인 코드 리뷰 코멘트 작성 (변경 단위별, 풍부한 맥락 포함)
- CI Watch (background agent)
- 사용자 PR 피드백 수집 → 수정 → 인라인 리뷰 재작성 → CI 재검증 루프
- 최종 마무리 (PR ready 전환, feedback.md, retrospective.md, CONTEXT.md 갱신)
- Completion Summary 출력

**▶ EMIT** `workflow_complete` @ `null` — 워크플로 종료 이벤트
```bash
$E --type workflow_complete \
  --title "워크플로 완료" \
  --data '{"status":"success","summary":"전체 요약"}' \
  2>/dev/null || true
```

## Step 20: Self-Improvement (회고 기반 스킬 개선)

워크플로 전체에서 축적된 사용자 피드백을 분석하여, 스킬 자체의 개선이 필요한지 판단하고 적용한다.

이 단계의 목적: simon/simon-grind가 매 사용마다 조금씩 더 나아지는 자기 개선 루프를 만드는 것. 사용자가 반복적으로 같은 불편을 겪거나, 워크플로의 특정 부분이 계속 마찰을 일으킨다면, 그건 스킬 자체를 고쳐야 한다는 신호다.

> **Phase-End Auto-Retrospective와의 관계**: Phase 경계에서 이미 캡처된 인사이트(`~/.claude/boost/insights/`)와 retrospective.md의 Phase-End Checkpoint 기록을 먼저 확인한다. 이미 캡처된 패턴은 중복 분석하지 않고, Step 20은 **Phase 간 교차 패턴** (여러 Phase에 걸쳐 반복되는 문제)에 집중한다. 컨텍스트 부족으로 Step 20이 실행되지 않아도, 핵심 인사이트는 Phase-end에서 이미 캡처된 상태이므로 안전하다.

**자기 측정**: Harness Stress Test 데이터가 5세션 이상 누적되면 Step 20 자신을 '0건 발견 80%+ 병합 후보' 평가의 1순위 대상으로 삼는다 — 이미 Standup(Step 19)·Gotcha(Phase-End)가 선행 기록되므로, 데이터가 중복을 확인하면 Step 20을 Phase-End Auto-Retrospective로 흡수한다.

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

- **반복 교정 → Gotchas 자동 변환 (중복 방지)**: Phase-End Auto-Retrospective에서 Phase별 gotcha가 이미 기록되어 있으므로, Step 20에서는 **Phase 간 교차 패턴**에서 도출된 gotcha만 추가한다. `state/` 디렉토리가 없으면 `mkdir -p`로 생성한 뒤 (Step 20은 별도 세션에서 실행될 수 있으므로), 기존 `~/.claude/projects/{slug}/state/gotchas.jsonl`을 읽어 동일 패턴이 없는 경우에만 append한다.
  형식: `{"id": "G-xxx", "category": "...", "gotcha": "...", "source_step": "Step 20", "source_session": "{branch}", "added_at": "YYYY-MM-DD"}`

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
- Scope: STANDARD / LARGE
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
