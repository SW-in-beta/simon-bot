---
name: simon-bot-review
description: "PR 기반 코드 리뷰 — Draft PR 생성, 인라인 코드 리뷰 코멘트, CI Watch, 피드백 루프를 수행합니다. Use when: (1) simon-bot/grind 작업 완료 후 자동 호출, (2) 사용자가 직접 'PR 만들어줘', '리뷰해줘', '코드 리뷰', 'Draft PR' 요청, (3) 브랜치 작업 완료 후 PR + 인라인 리뷰가 필요할 때. simon-bot이 생성한 review-sequence.md가 있으면 활용하고, 없으면 독자적으로 diff를 분석하여 동일 품질의 리뷰를 생성합니다."
compatibility:
  tools: [Agent, AskUserQuestion]
  skills: [git-commit]
---

# simon-bot-review

PR 기반 코드 리뷰 스킬. Draft PR을 생성하고, 논리적 변경 단위별 인라인 코드 리뷰를 작성하며, CI 모니터링과 사용자 피드백 루프를 반복한다.

## Mode Detection

스킬 시작 시 모드를 자동 감지한다:

1. `.claude/memory/review-sequence.md` 존재 확인
2. **존재 → CONNECTED 모드** (simon-bot/grind에서 넘어온 것)
   - `.claude/memory/branch-name.md` 읽기
   - `.claude/reports/{feature-name}-report.md` 확인 → PR description에 활용
   - `.claude/memory/plan-summary.md` 확인 → 계획 매핑용
   - `.claude/memory/pr-info.md` 확인 → 이미 PR이 있으면 재사용
3. **미존재 → STANDALONE 모드**
   - `git diff {base-branch}...HEAD`로 변경사항 분석
   - Agent team으로 review-sequence.md 자체 생성
   - Report도 자체 생성
4. 이후 워크플로는 양 모드 동일

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules, Agent Teams, Cognitive Independence 공통 프로토콜 포함.

### Session Isolation Protocol (확장)

**SESSION_DIR 결정**: CONNECTED 모드에서는 simon-bot이 전달한 `{SESSION_DIR}`을 사용한다. STANDALONE 모드에서는 현재 브랜치명으로 직접 결정한다 (preamble의 SESSION_DIR 결정 bash 참조).

## Workflow

```
[Mode Detection]
     ↓
[STANDALONE only] → Step 0: Diff 분석 + review-sequence 생성
     ↓
Step 1: Draft PR 생성
     ↓
Step 2: 인라인 코드 리뷰 작성
     ↓
Step 3: CI Watch (background) + 사용자에게 리뷰 안내
     ↓
Step 4: 피드백 루프 ──────────────────────┐
  4-A: 사용자 피드백 수집 (PR 코멘트)      │
  4-B: [GATE] 전문가 검증 → 코드 수정      │
  4-C: 수정된 부분에 인라인 리뷰 재작성     │
  4-D: [GATE] CI Watch 재시작 (코드 변경 시 필수) │
  4-E: 사용자에게 수정 완료 안내            │
       ↓                                   │
  사용자 승인? ─── No ─────────────────────┘
       │
      Yes
       ↓
Step 5: 마무리
```

### 중단 복구 프로토콜

어떤 Step에서든 외부 요인(push 실패, API 오류, 사용자 개입 등)으로 흐름이 중단되었다가 재개될 때, 반드시 아래 체크리스트를 따른다:

1. 현재 Step의 완료 여부 확인 — 부분 완료 상태면 미완료 하위 단계부터 재개
2. **잔여 워크플로 전체를 확인** — 현재 Step 완료 후 남은 Step(특히 Step 2 인라인 리뷰)을 순서대로 실행
3. "사용자에게 안내"는 흐름의 종료가 아니라 **일시 정지** — 안내 후에도 대기 상태를 유지하고, 문제 해결 시 자동 재개

**금지 패턴**: push/PR 생성 등 하나의 하위 작업 해결 후 "완료"로 간주하고 후속 Step을 누락하는 것. 특히 Step 2(인라인 리뷰)는 이 스킬의 핵심 가치이므로 절대 누락해서는 안 된다.

## Step 0: Standalone 분석 (STANDALONE 모드만)

STANDALONE 모드에서는 simon-bot의 Step 18-A/B에 해당하는 분석을 자체적으로 수행한다. simon-bot이 전문가 패널을 거쳐 생성하는 review-sequence와 동등한 품질을 위해 agent team을 구성한다.

For detailed instructions, read [standalone-analysis.md](references/standalone-analysis.md).

## Step 1: Draft PR 생성

> **핵심 제약**: PR은 반드시 **Draft** 상태로 생성한다. Draft 상태는 리뷰 워크플로의 전제 조건이며, Step 5에서 사용자 승인 후에만 Ready로 전환한다.

1. 브랜치명 확인: `.claude/memory/branch-name.md` 또는 현재 브랜치 (`git branch --show-current`)
2. 브랜치 push:
   ```bash
   git push -u origin {branch-name}
   ```
   **push 실패 시 복구 절차:**
   - hooks 차단(exit 2) → 차단 사유 확인 후 사용자에게 보고. 사용자가 수동으로 push하면 push 성공을 확인하고 **Step 1의 나머지 하위 단계(3~7)부터 자동 재개**한다.
   - 인증/네트워크 실패 → Error Resilience의 ENV_INFRA/NETWORK_ERROR 절차 적용. 복구 성공 시 push 재시도 후 Step 1 계속 진행.
   - **핵심 규칙**: push 실패로 사용자에게 안내한 후, 사용자가 문제를 해결하면 **Step 2(인라인 리뷰)까지의 전체 잔여 워크플로를 자동 재개**한다. "PR 생성까지만 진행하고 멈추는" 것은 금지 — 인라인 리뷰, CI Watch, 피드백 루프까지가 하나의 완결 단위다.
3. Report 파일 확인:
   - `.claude/reports/{feature-name}-report.md` 존재 → `--body-file`로 사용
   - 미존재 → review-sequence.md 기반으로 간략 요약 생성하여 사용
4. **Draft PR 생성** — `--draft` 플래그는 **필수**다. 일반 PR로 생성하면 안 된다:
   ```bash
   gh pr create --draft \
     --title "{type}: {feature summary}" \
     --body-file {report-path}
   ```
5. **[GATE — Draft 상태 검증]** PR 생성 직후 Draft 상태를 확인한다. Draft가 아니면 즉시 전환한다:
   ```bash
   IS_DRAFT=$(gh pr view {pr_number} --json isDraft --jq '.isDraft')
   if [ "$IS_DRAFT" != "true" ]; then
     gh pr ready {pr_number} --undo
   fi
   ```
6. PR URL과 번호 저장: `.claude/memory/pr-info.md`
7. PR description에 **Review Guide** 섹션 추가:
   - 논리적 변경 단위 수 + 각 단위 한줄 요약
   - 리뷰 순서 안내 (왜 이 순서인지)
   - 추가 맥락 (있으면)

## Step 2: 인라인 코드 리뷰 작성

### Review Mode

리뷰 깊이를 사전 선택한다. CONNECTED 모드에서는 simon-bot의 scope에 따라 자동 매핑된다:

| Review Mode | 적용 | CONNECTED 자동 매핑 |
|-------------|------|-------------------|
| **THOROUGH** | 모든 변경 단위에 Full 양식 + Architecture Impact + 영향 분석 | LARGE scope |
| **STANDARD** | 대표 파일 Full 양식 + 보조 파일 간략 + 영향 분석 | STANDARD scope |
| **QUICK** | 핵심 파일만 리뷰 포인트 중심, 영향 분석 생략 | SMALL scope |

STANDALONE 모드에서는 diff 크기 기반 자동 추천: 50줄 미만→QUICK, 50-300줄→STANDARD, 300줄+→THOROUGH.
선택한 모드를 유지한다. 컨텍스트 소비가 커져도 후반 변경 단위의 리뷰를 얕게 하지 않는다.

> **Reference Loading**: [review-strategy.md](references/review-strategy.md) + [inline-review-format.md](references/inline-review-format.md) 읽기

**리뷰 사이클 카운터 초기화**: `echo "1" > {SESSION_DIR}/memory/review-cycle-counter.md`

CONNECTED 모드에서는 **Blind-First 2-Pass**를 적용한다:
- Pass 1 (Blind): diff만으로 독립 분석 + **독립 severity 판정** + 기존 패턴 스캔 + 공식 문서 검증
- Pass 2 (Informed): review-sequence.md와 대조 + severity 불일치 시 [SEVERITY-DISPUTED] 태깅

각 변경 단위의 대표 파일 1-2개에 집중하여 인라인 코멘트를 작성하고, 영향 분석 Pass로 변경되지 않았지만 영향받는 코드를 식별하여 **해당 파일에 `[영향 분석: ...]` 양식의 인라인 코멘트를 작성한다** (review-payload.json의 comments 배열에 포함). Review Summary Body에 Architecture Impact 섹션과 영향 분석 요약을 포함한다 (STANDARD+ 경로).

상세 절차, 코멘트 양식, 대규모 PR 처리, fallback은 review-strategy.md 참조.

## Step 3: CI Watch + 리뷰 안내

### CI Watch (Background Agent)

Step 2 완료 직후, background agent를 시작한다:
```
Agent(run_in_background=true)
```

Agent에 전달할 컨텍스트:
- PR 번호 (`.claude/memory/pr-info.md`)
- 브랜치명 (`.claude/memory/branch-name.md`)
- 프로젝트 빌드/테스트 명령 (`.claude/workflow/config.yaml`, 있으면)
- 현재 worktree 경로

**CI 모니터링 루프 (max 3 cycles):**

1. CI 상태 확인:
   ```bash
   gh pr checks {pr_number} --watch --fail-fast
   ```
   `--watch`가 지원되지 않으면 30초 간격 polling:
   ```bash
   gh pr checks {pr_number}
   ```
2. 모든 체크 통과 → CI Watch 종료, 결과 기록
3. CI 실패 시:
   a. 실패한 run의 로그 확인: `gh run view {run_id} --log-failed`
   b. 실패 유형 분류: BUILD / TEST / LINT / ENV
   c. **ENV 유형은 수정하지 않는다** — 코드 변경으로 해결 불가, 결과에 기록만
   d. 진단 → 수정 → 커밋 (`fix(ci): {수정 내용}`) → 푸시
   e. PR에 코멘트로 수정 내용 요약
   f. CI 재실행 대기 → 1번으로 복귀

**결과 저장:** `.claude/memory/ci-watch-result.md`

### 사용자 리뷰 안내

CI Watch 시작 후, 사용자에게 알림:
> "Draft PR에 코드 리뷰를 작성했습니다: {PR_URL}
> PR에서 리뷰를 확인하시고, 궁금한 점이나 수정 요청을 코멘트로 남겨주세요.
> 댓글을 달면 1분 내로 자동 감지하여 반영합니다.
> (CI도 모니터링하고 있습니다 — 실패하면 자동으로 수정합니다.)"

### Comment Auto-Watch (Background Agent)

리뷰 안내 직후, CI Watch와 동일한 패턴으로 background agent를 시작하여 PR 댓글을 폴링한다. CronCreate는 실제 실행 환경에서 안정적으로 동작하지 않으므로, `Agent(run_in_background=true)` + 내부 polling loop 패턴을 사용한다.

**마지막 확인 시점 초기화:**
Step 2 리뷰 제출 직후의 타임스탬프를 `{SESSION_DIR}/memory/last-comment-check.md`에 저장한다:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ" > {SESSION_DIR}/memory/last-comment-check.md
```

**Background Agent 시작:**
```
Agent(run_in_background=true)
```

Agent에 전달할 컨텍스트:
- PR 번호, owner, repo (`.claude/memory/pr-info.md`)
- SESSION_DIR 경로
- 리뷰 사이클 카운터 파일 경로: `{SESSION_DIR}/memory/review-cycle-counter.md`
- 전문가 검증 프로토콜: `~/.claude/skills/simon-bot-review/references/expert-comment-review.md`
- 인라인 리뷰 양식: `~/.claude/skills/simon-bot-review/references/inline-review-format.md`

**댓글 감지 폴링 루프 (60초 간격, 종료 조건 충족까지 반복):**

1. `{SESSION_DIR}/memory/last-comment-check.md`의 시점 읽기
2. gh api로 PR 댓글(인라인 + 일반) 수집, 해당 시점 이후 새 사용자 댓글만 필터링 (AI 작성 댓글 제외):
   ```bash
   SINCE=$(cat {SESSION_DIR}/memory/last-comment-check.md)
   # 인라인 리뷰 코멘트
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
     --jq "[.[] | select(.created_at > \"${SINCE}\") | select(.user.type != \"Bot\")]"
   # 일반 PR 코멘트
   gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
     --jq "[.[] | select(.created_at > \"${SINCE}\") | select(.user.type != \"Bot\")]"
   ```
3. 새 댓글 없으면 → 60초 대기 후 1번으로 복귀
4. 새 댓글 있으면:
   a. `{SESSION_DIR}/memory/review-cycle-counter.md`의 값을 +1 (현재 리뷰 사이클 R{N})
   b. 코멘트를 질문/수정요청/승인으로 분류
   c. 승인/OK → resolve 처리
   d. 질문 또는 수정 요청 → 반드시 아래 순서를 따른다:
      i.  코멘트의 도메인 식별 (아키텍처/성능/보안/테스트/비즈니스로직/코드스타일 등)
      ii. `Agent(subagent_type='general-purpose')`로 해당 도메인 전문가를 spawn하여 검증.
          전문가에게 코멘트 원문 + 관련 코드 + PR 맥락을 전달.
          전문가 프로토콜 상세: `~/.claude/skills/simon-bot-review/references/expert-comment-review.md`
      iii. 전문가 verdict를 `{SESSION_DIR}/memory/expert-verdicts/{comment_id}.md`에 저장
      iv. verdict(AGREE/PARTIAL/COUNTER)에 따라:
           - AGREE → 코드 수정 → 커밋 → 푸시 → `[R{N}]` Before/After 포함 대댓글
           - PARTIAL → 수정된 방식으로 변경 → `[R{N}]` Before/After + 이유 대댓글
           - COUNTER → 코드 변경 없이 `[R{N}]` 전문가 근거로 반론 대댓글
      **[GATE]** 전문가 Agent 호출 없이 직접 수정하거나 답변하는 것은 금지.
   e. 수정된 부분에 `[R{N}]` 접두사로 인라인 리뷰 재작성
      (양식: `~/.claude/skills/simon-bot-review/references/inline-review-format.md`)
   f. 사용자에게 수정 완료 안내
   g. `last-comment-check.md`를 현재 시점으로 갱신
5. **종료 조건 확인**: 새 댓글 중 "LGTM" / "approve" / "승인" 패턴이 있으면 → 폴링 종료, Step 5로 진행 안내
6. 종료 조건 미충족 → 60초 대기 후 1번으로 복귀

## Step 4: 피드백 루프

Comment Auto-Watch가 새 댓글을 감지하면 자동으로 4-A~4-E를 실행한다. 사용자가 직접 "피드백 준비됐어"라고 말해도 동일하게 실행된다.

### 4-A: 피드백 수집

1. **CI Watch 결과 확인**: `.claude/memory/ci-watch-result.md` 읽기
   - CI Watch가 아직 실행 중이면 현재 상태를 사용자에게 보고
   - CI fix로 변경된 부분이 있으면 사용자에게 요약 제시
2. **PR 코멘트 수집** (마지막 확인 시점 이후의 새 댓글만):
   ```bash
   SINCE=$(cat {SESSION_DIR}/memory/last-comment-check.md)
   # 인라인 리뷰 코멘트 (코드에 달린 댓글)
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
     --jq "[.[] | select(.created_at > \"${SINCE}\") | select(.user.type != \"Bot\")]"
   # 일반 PR 코멘트
   gh api repos/{owner}/{repo}/issues/{pr_number}/comments \
     --jq "[.[] | select(.created_at > \"${SINCE}\") | select(.user.type != \"Bot\")]"
   ```
3. **확인 시점 갱신**: 처리 완료 후 `last-comment-check.md`를 현재 시점으로 갱신

### 4-A-2: Fix-First 분류

수집된 피드백 코멘트를 전문가 검증 전에 AUTO-FIX / ASK로 분류한다:

**AUTO-FIX** (전문가 검증 생략, 즉시 적용):
- 오타/typo 수정
- 변수/함수 rename
- 주석/문서 수정
- import 정리
- 포맷팅/lint 지적
- dead code 제거

**ASK** (기존 전문가 검증 유지):
- 로직 변경
- 설계/아키텍처 결정
- 성능/보안 관련 지적
- API contract 변경
- 비즈니스 로직 수정

분류 기준: 코드 **로직** 변경이 수반되는지. 로직 변경 없는 표면적 수정은 AUTO-FIX.
severity가 CRITICAL이면 무조건 ASK. 분류가 애매하면 ASK 쪽으로.

AUTO-FIX 항목은 즉시 수정 + 인라인 대댓글(`[R{N}] AUTO-FIX: {변경 내용}`).
ASK 항목만 Step 4-B의 전문가 검증 파이프라인으로 전달.

### 4-B: 전문가 검증 + 코드 수정

> **[GATE — 전문가 검증]** 질문 또는 수정 요청 코멘트에 대해, 전문가 Agent 검증을 거치지 않고 코드를 수정하거나 대댓글로 답변하는 것은 **금지**한다.
> 구현자가 리뷰어를 겸하면 자기 코드의 맹점을 놓치므로, 독립적 전문가의 검증이 코드 품질의 핵심 게이트다.

**처리 흐름:**

1. 리뷰 사이클 카운터를 증가시킨다: `{SESSION_DIR}/memory/review-cycle-counter.md`의 값을 +1
2. 코멘트 분류: 질문 / 수정 요청 / 승인
3. **승인/OK**: 해당 코멘트 resolve 처리 (전문가 검증 불필요)
4. **질문 또는 수정 요청** — 아래 순서를 반드시 따른다:
   a. 코멘트의 도메인 식별 (아키텍처, 성능, 보안, 테스트, 비즈니스 로직, 코드 스타일 등)
   b. `Agent(subagent_type="general-purpose")`로 해당 도메인 전문가를 spawn하여 검증. 코멘트 원문 + 관련 코드 + PR 맥락을 전달
   c. 전문가 verdict를 `{SESSION_DIR}/memory/expert-verdicts/{comment_id}.md`에 저장 — verdict 파일이 존재해야 코드 수정 진행 가능
   d. verdict에 따라:
      - **AGREE**: 코드 수정 → 커밋 → 푸시 → Before/After 포함 대댓글 (양식: `[R{N}]` 접두사)
      - **PARTIAL**: 수정된 방식으로 코드 변경 → Before/After + 다르게 적용한 이유 대댓글
      - **COUNTER**: 코드 변경 없이 전문가의 기술적 근거로 반론 대댓글

> **Reference Loading**: 전문가 선정 기준(8개 도메인 매핑), Agent 프롬프트 템플릿, verdict 파일 저장 절차, 의견 충돌 처리 프로토콜은 [expert-comment-review.md](references/expert-comment-review.md)를 읽는다. 이 파일 없이는 전문가를 올바르게 호출할 수 없다.

### 4-C: 인라인 리뷰 재작성

수정된 변경 단위에 대해서만 새 인라인 코멘트를 작성한다.

- 기존 코멘트의 해당 항목은 resolve 처리
- 수정된 코드 위치에 **수정 반영 양식**으로 새 코멘트 작성 (양식은 `references/inline-review-format.md` 참조)
- 변경 없는 부분은 건드리지 않음

### 4-D: CI Watch 재시작

> **[GATE — CI Watch 필수]** 4-B/4-C에서 코드가 변경되어 push한 경우, CI Watch 재시작을 **생략해서는 안 된다**. 코드 변경 없이 댓글만 남긴 COUNTER verdict의 경우에만 이 단계를 건너뛸 수 있다.

코드가 변경되었으므로 CI Watch를 background agent로 재시작한다:

1. **코드 변경 여부 확인**: 4-B에서 AGREE 또는 PARTIAL verdict로 코드를 수정 + push했는지 확인
   - 수정 + push 있음 → CI Watch 시작 (아래 2번으로)
   - 수정 없음 (COUNTER만) → 4-E로 진행
2. **Background Agent 시작**: Step 3의 CI Watch와 동일한 로직을 적용한다 (run_in_background=true)
   - `gh pr checks {pr_number} --watch --fail-fast` 또는 30초 간격 polling
   - CI 실패 시: 로그 확인 → 진단 → 수정 → 커밋 → 푸시 (max 3 cycles)
   - 결과를 `{SESSION_DIR}/memory/ci-watch-result.md`에 갱신
3. **4-E로 진행**: CI Watch는 background에서 실행하므로 4-E(수정 완료 안내)로 즉시 진행한다

### 4-E: 수정 완료 안내

사용자에게 수정 내용 요약 보고:
> "피드백 반영 완료했습니다: {수정 요약}
> PR에서 확인해주세요: {PR_URL}
> (댓글 자동 감지 + CI 모니터링 계속 중입니다.)"

### 종료 조건

사용자가 "LGTM" / "approve" / "승인" / PR ready 전환을 요청하면:
1. Comment Auto-Watch background agent가 자동 종료 (종료 조건 감지)
2. Step 5로 진행

## Step 5: 마무리

### Review Readiness Dashboard

Step 5 시작 시, 모든 검증 결과를 통합 대시보드로 사용자에게 제시한다:

```
=== Review Readiness ===
Build:      {CLEARED|NOT CLEARED}
Tests:      {CLEARED|NOT CLEARED} ({passed}/{total})
Lint:       {CLEARED|NOT CLEARED}
Security:   {CLEARED|NOT CLEARED} (CRITICAL {N}, HIGH {N})
CI:         {CLEARED|PENDING|NOT CLEARED} ({passed}/{total} checks)
Comments:   {CLEARED|NOT CLEARED} ({unresolved} unresolved)
─────────────────────
VERDICT:    {READY TO MERGE | BLOCKED — {blocking items}}
===
```

각 항목의 상태:
- **CLEARED**: 해당 검증 통과
- **NOT CLEARED**: 해당 검증 실패 또는 미실행
- **PENDING**: 아직 실행 중 (CI 등)

VERDICT는 모든 항목이 CLEARED일 때만 READY TO MERGE. 하나라도 NOT CLEARED면 BLOCKED + 구체적 blocking items 나열.

이 대시보드를 PR description의 하단에도 포함한다.

1. PR 상태 확인 — 사용자 요청에 따라:
   - Ready 전환: `gh pr ready {pr_number}`
   - Draft 유지: 그대로 둠
2. **피드백 영속 기록**: `.claude/memory/feedback.md`
3. **Completion Summary 출력**:
   ```
   === 리뷰 완료 ===
   PR: #{number} ({Draft/Ready})
   리뷰 라운드: {N}회
   수정 커밋: {N}개
   CI 수정: {N}건
   미해결 코멘트: {N}건
   ===
   ```
4. CONNECTED 모드인 경우:
   - `.claude/memory/retrospective.md` 기록
   - `CONTEXT.md` 최종 상태 갱신
