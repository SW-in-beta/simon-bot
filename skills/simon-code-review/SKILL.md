---
name: simon-code-review
description: "PR 기반 코드 리뷰 — Draft PR 생성, 인라인 코드 리뷰 코멘트, CI Watch, 피드백 루프를 수행합니다. Use when: (1) simon-dev/grind 작업 완료 후 자동 호출, (2) 사용자가 직접 'PR 만들어줘', '리뷰해줘', '코드 리뷰', 'Draft PR' 요청, (3) 브랜치 작업 완료 후 PR + 인라인 리뷰가 필요할 때. simon-dev이 생성한 review-sequence.md가 있으면 활용하고, 없으면 독자적으로 diff를 분석하여 동일 품질의 리뷰를 생성합니다."
compatibility:
  tools: [Agent, AskUserQuestion]
  skills: [git-commit]
---

# simon-code-review

PR 기반 코드 리뷰 스킬. Draft PR을 생성하고, 논리적 변경 단위별 인라인 코드 리뷰를 작성하며, CI 모니터링과 사용자 피드백 루프를 반복한다.

## Mode Detection

스킬 시작 시 모드를 자동 감지한다:

1. `.claude/memory/review-sequence.md` 존재 확인
2. **존재 → CONNECTED 모드** (simon/grind에서 넘어온 것)
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

**SESSION_DIR 결정**: CONNECTED 모드에서는 simon-dev이 전달한 `{SESSION_DIR}`을 사용한다. STANDALONE 모드에서는 현재 브랜치명으로 직접 결정한다 (preamble의 SESSION_DIR 결정 bash 참조).

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

STANDALONE 모드에서는 simon-dev의 Step 18-A/B에 해당하는 분석을 자체적으로 수행한다. simon-dev이 전문가 패널을 거쳐 생성하는 review-sequence와 동등한 품질을 위해 agent team을 구성한다.

For detailed instructions, read [standalone-analysis.md](references/standalone-analysis.md).

## Step 1: Draft PR 생성

> **핵심 제약**: PR은 반드시 **Draft** 상태로 생성한다. Draft 상태는 리뷰 워크플로의 전제 조건이며, Step 5에서 사용자 승인 후에만 Ready로 전환한다.

1. 브랜치명 확인: `.claude/memory/branch-name.md` 또는 현재 브랜치 (`git branch --show-current`)
2. **[GATE — 기존 PR 감지]** 현재 브랜치에 이미 PR이 존재하는지 확인한다:
   ```bash
   EXISTING_PR=$(gh pr view --json number,isDraft,url,state \
     --jq '{number: .number, isDraft: .isDraft, url: .url, state: .state}' 2>/dev/null)
   ```
   - **PR 없음** (`gh pr view` 실패) → 3번(브랜치 push)으로 진행
   - **PR 있고 state=MERGED 또는 CLOSED** → 기존 PR은 사용 불가. 새 브랜치 + 새 PR 경로:
     1. 사용자에게 보고: "PR #{number}는 이미 {MERGED|CLOSED} 상태입니다. 새 브랜치를 생성합니다."
     2. `origin/main` (또는 기본 브랜치) 기반 새 브랜치 생성 + 현재 변경사항 cherry-pick
     3. 3번(브랜치 push)부터 정상 진행
   - **PR 있고 state=OPEN, Draft 상태** → PR 번호/URL 저장 후 7번(PR URL 저장)으로 건너뛰기
   - **PR 있고 state=OPEN, 일반(Ready) 상태** → 즉시 Draft로 전환 후 7번으로 건너뛰기:
     ```bash
     gh pr ready {pr_number} --undo
     ```
3. 브랜치 push:
   ```bash
   git push -u origin {branch-name}
   ```
   **push 실패 시 복구 절차:**
   - hooks 차단(exit 2) → 차단 사유 확인 후 사용자에게 보고. 사용자가 수동으로 push하면 push 성공을 확인하고 **Step 1의 나머지 하위 단계(3~7)부터 자동 재개**한다.
   - 인증/네트워크 실패 → Error Resilience의 ENV_INFRA/NETWORK_ERROR 절차 적용. 복구 성공 시 push 재시도 후 Step 1 계속 진행.
   - **핵심 규칙**: push 실패로 사용자에게 안내한 후, 사용자가 문제를 해결하면 **Step 2(인라인 리뷰)까지의 전체 잔여 워크플로를 자동 재개**한다. "PR 생성까지만 진행하고 멈추는" 것은 금지 — 인라인 리뷰, CI Watch, 피드백 루프까지가 하나의 완결 단위다.
4. Report 파일 확인:
   - `.claude/reports/{feature-name}-report.md` 존재 → `--body-file`로 사용
   - 미존재 → review-sequence.md 기반으로 간략 요약 생성하여 사용
4-B. **PR body 스타일 변환** — report.md 또는 자체 생성 요약을 `--body-file`로 사용하기 전에 아래 기준으로 문서를 변환한다:
   - **고유명사 최소화 (단, 사내 공용 도메인 용어는 예외)**: 외부에서 의미를 모를 수 있는 약어·라이브러리·고유 프로젝트명·이전 PR 식별자만 풀어 쓴다. 사내 모든 팀이 같은 단어로 부르는 도메인 핵심 용어(예: `lineitem`, `biddersvc`)는 풀어 쓰지 않고 그대로 둔다. 판단이 애매하면 사용자에게 확인한다. (예: "ZQPR PR(1f1239ce)" → "이전에 머지된 비슷한 작업"; "biddersvc의 lineitem"은 그대로)
   - **전문 용어 한국어 풀이**: 영문 약어(DFC, RPI 등 신규 프로젝트 약어), proto/optional 등 일반적 기술 용어를 의미 중심으로 설명 (예: "proto optional 필드" → "값이 없을 수도 있는 선택적 항목")
   - **존대 사용**: "~이다", "~함" 대신 "~입니다", "~합니다"
   - **코드 식별자 유지**: 필드명·파일 경로·타입명·함수명은 코드 리뷰어 정확성을 위해 원문 그대로 유지
   변환 결과를 임시 파일(`{SESSION_DIR}/memory/pr-body-draft.md`)에 저장한 뒤 `--body-file`로 사용한다.
5. **Draft PR 생성** — `--draft` 플래그는 **필수**다. 일반 PR로 생성하면 안 된다:
   ```bash
   gh pr create --draft \
     --title "{type}: {feature summary}" \
     --body-file {SESSION_DIR}/memory/pr-body-draft.md
   ```
6. **[GATE — Draft 상태 검증]** PR 생성 직후 Draft 상태를 확인한다. Draft가 아니면 즉시 전환한다:
   ```bash
   IS_DRAFT=$(gh pr view {pr_number} --json isDraft --jq '.isDraft')
   if [ "$IS_DRAFT" != "true" ]; then
     gh pr ready {pr_number} --undo
   fi
   ```
7. PR URL과 번호 저장: `.claude/memory/pr-info.md`
8. PR description에 **Review Guide** 섹션 추가:
   - 논리적 변경 단위 수 + 각 단위 한줄 요약
   - 리뷰 순서 안내 (왜 이 순서인지)
   - 추가 맥락 (있으면)

## Step 2: 인라인 코드 리뷰 작성

### Review Mode

리뷰 깊이를 사전 선택한다. CONNECTED 모드에서는 simon의 scope에 따라 자동 매핑된다:

| Review Mode | 적용 | CONNECTED 자동 매핑 |
|-------------|------|-------------------|
| **THOROUGH** | 모든 변경 단위에 Full 양식 + Architecture Impact + 영향 분석 | LARGE scope |
| **STANDARD** | 대표 파일 Full 양식 + 보조 파일 간략 + 영향 분석 | STANDARD scope |
| **QUICK** | 핵심 파일만 리뷰 포인트 중심, 영향 분석 생략 | SMALL scope |

STANDALONE 모드에서는 diff 크기 기반 자동 추천: 50줄 미만→QUICK, 50-300줄→STANDARD, 300줄+→THOROUGH.
선택한 모드를 유지한다. 컨텍스트 소비가 커져도 후반 변경 단위의 리뷰를 얕게 하지 않는다.

> **Reference Loading**: [review-strategy.md](references/review-strategy.md) + [inline-review-format.md](references/inline-review-format.md) 읽기

**리뷰 사이클 카운터 초기화**: `echo "1" > {SESSION_DIR}/memory/review-cycle-counter.md`

**Cross-Model 3-Pass**를 적용한다 (모드 무관 — CONNECTED/STANDALONE 모두):
- Pass 1 (Blind): diff만으로 독립 분석 + **독립 severity 판정** + 기존 패턴 스캔 + 공식 문서 검증 + **제거/단순화 코드의 git history 확인**
- Pass 2 (Informed): review-sequence.md와 대조 + severity 불일치 시 [SEVERITY-DISPUTED] 태깅 (CONNECTED 모드만)
- Pass 3 (Cross-Model): Codex 독립 리뷰 → Cross-Model Reconciliation (**항상 실행**, `~/.claude/skills/_shared/cross-model-verification.md` 참조)

각 변경 단위의 대표 파일 1-2개에 집중하여 인라인 코멘트를 작성하고, 영향 분석 Pass로 변경되지 않았지만 영향받는 코드를 식별하여 **해당 파일에 `[영향 분석: ...]` 양식의 인라인 코멘트를 작성한다** (review-payload.json의 comments 배열에 포함). Review Summary Body에 Architecture Impact 섹션과 영향 분석 요약을 포함한다 (STANDARD+ 경로).

상세 절차, 코멘트 양식, 대규모 PR 처리, fallback은 review-strategy.md 참조.

## Step 3: CI Watch + 리뷰 안내

### CI Watch (simon-ci-fix 위임)

Step 2 완료 직후, CI 모니터링 + 자동 수정을 **simon-ci-fix** 스킬에 위임한다. Background agent가 스킬 파일을 직접 읽고 실행하므로, CI 수정이 fresh context에서 전용 로직으로 수행된다.

```
Agent(run_in_background=true, model="sonnet"):
  "다음 파일을 Read하고 그 지시를 따라 CI 수정을 실행하라:
   ~/.claude/skills/simon-ci-fix/SKILL.md

   컨텍스트:
   - PR 번호: {pr_number}
   - 브랜치: {branch}
   - SESSION_DIR: {SESSION_DIR}
   - 모드: DELEGATED
   - 결과 저장: {SESSION_DIR}/memory/ci-watch-result.md"
```

**결과 저장:** `{SESSION_DIR}/memory/ci-watch-result.md` (simon-ci-fix가 자동 생성)
**진행 상태:** `{SESSION_DIR}/memory/ci-fix-status.md` (polling 가능)

### 사용자 리뷰 안내

CI Watch 시작 후, 사용자에게 알림:
> "Draft PR에 코드 리뷰를 작성했습니다: {PR_URL}
> PR에서 리뷰를 확인하시고, 궁금한 점이나 수정 요청을 코멘트로 남겨주세요.
> 코멘트를 남기신 뒤 알려주시면 반영합니다.
> (CI도 모니터링하고 있습니다 — 실패하면 자동으로 수정합니다.)"

### 피드백 기준 시점 저장

Step 4에서 새 댓글만 수집할 수 있도록, Step 2 리뷰 제출 직후의 타임스탬프를 `{SESSION_DIR}/memory/last-comment-check.md`에 저장한다:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ" > {SESSION_DIR}/memory/last-comment-check.md
```

리뷰 안내 후 PR 댓글을 폴링하지 않는다. 피드백 처리는 사용자의 알림을 트리거로 Step 4에서 수행한다.

## Step 4: 피드백 루프

사용자가 "피드백 준비됐어", "코멘트 달았어" 등으로 피드백 완료를 알리면 4-A~4-E를 실행한다.

### 4-A: 피드백 수집

1. **CI Watch 결과 확인**: `.claude/memory/ci-watch-result.md` 읽기
   - CI Watch가 아직 실행 중이면 현재 상태를 사용자에게 보고
   - CI fix로 변경된 부분이 있으면 사용자에게 요약 제시
2. **PR 코멘트 수집** (마지막 확인 시점 이후의 새 댓글만):
   ```bash
   SINCE=$(cat {SESSION_DIR}/memory/last-comment-check.md)
   # 인라인 리뷰 코멘트 (코드에 달린 댓글)
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate \
     --jq "[.[] | select(.created_at > \"${SINCE}\") | select(.user.type != \"Bot\") | {
       id: .id,
       body: .body,
       path: .path,
       line: .line,
       start_line: .start_line,
       position: .position,
       original_line: .original_line,
       diff_hunk: .diff_hunk,
       created_at: .created_at
     }]"
   # 일반 PR 코멘트
   gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate \
     --jq "[.[] | select(.created_at > \"${SINCE}\") | select(.user.type != \"Bot\")]"
   ```

   **[필수] diff_hunk 기반 코드 범위 결정**:
   각 인라인 코멘트에 대해 `diff_hunk`와 라인 범위(`start_line`~`line`)를 반드시 확인한다.
   - `start_line`이 존재하면 다중 라인 선택 — `start_line`부터 `line`까지의 모든 코드가 수정 스코프
   - `diff_hunk`에서 `+`로 시작하는 라인들을 추출하여 선택 범위의 실제 식별자 목록을 구성
   - body 텍스트에서 식별자를 추론하는 것은 금지 — diff_hunk가 정보의 원천

   **[필수] outdated 코멘트 분기 (`position: null`)**:
   `position`이 `null`이거나 `line`이 `null`인 코멘트는 **이후 커밋으로 코드가 이동·변경되어 원래 위치가 유효하지 않은 상태**다. 이 경우 diff_hunk가 현재 코드와 대응하지 않으므로 위치만으로 대상을 확정할 수 없다. 아래를 순서대로 수행한다:

   1. body에 백틱 또는 식별자 형태(`snake_case`/`camelCase`)로 언급된 함수·변수명을 추출한다
   2. 그 식별자를 현재 브랜치에서 `grep`으로 찾아 실제 위치를 확정한다
   3. 식별자 언급이 없거나 grep 결과가 복수/0건이면 **코드를 수정하기 전에** 대댓글로 되묻는다: `이 코멘트가 가리키는 대상이 {추정}인지 확인 부탁드립니다 — 코드 변경으로 원래 위치 정보가 유실되었습니다.`

   잘못 추측해 다른 곳을 고치면 리뷰어가 "제가 코멘트를 남긴 부분은 그 부분이 아닌데요"를 다시 써야 하고, 이 되물음의 비용이 확인 질문 1회보다 훨씬 크다. 위치 정보가 살아 있는 코멘트(대다수)는 이 절차 대상이 아니다.

3. **확인 시점 갱신**: 처리 완료 후 `last-comment-check.md`를 현재 시점으로 갱신

> **Reference Loading**: Step 4-B 전문가 spawn 전 `~/.claude/skills/simon-dev/references/review-rubric.md`를 반드시 Read하여 spawn 프롬프트에 severity 판정 기준으로 포함한다 — 기준 없는 severity 판정은 세션마다 흔들린다.

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

AUTO-FIX 항목은 즉시 수정하되, 대댓글은 건별로 달지 않는다 — 사용자의 코드 로직·결론을 바꾸지 않는 수정이므로 보고 비중도 그에 맞게 낮춘다. 한 리뷰 사이클 내 AUTO-FIX 항목을 모아 PR 일반 코멘트 1건으로 일괄 보고하고(`[R{N}] AUTO-FIX 일괄 반영: 오타 {n}건, rename {n}건 — 상세는 커밋 {hash}`), 각 인라인 코멘트 thread는 resolve 처리만 한다 ("반영됨" 표시는 유지, 건별 대댓글 텍스트는 생성하지 않음 — 코멘트 수만큼 알림이 발생하는 것을 방지).
ASK 항목만 Step 4-B의 전문가 검증 파이프라인으로 전달.

### 4-B: 전문가 검증 + 코드 수정

> **[GATE — 전문가 검증]** 질문 또는 수정 요청 코멘트에 대해, 전문가 Agent 검증을 거치지 않고 코드를 수정하거나 대댓글로 답변하는 것은 **금지**한다.
> 구현자가 리뷰어를 겸하면 자기 코드의 맹점을 놓치므로, 독립적 전문가의 검증이 코드 품질의 핵심 게이트다.

**처리 흐름:**

1. 리뷰 사이클 카운터를 증가시킨다: `{SESSION_DIR}/memory/review-cycle-counter.md`의 값을 +1
2. 코멘트 분류: 질문 / 수정 요청 / 승인

   "질문"은 그대로 처리하지 않고 **아래 3종으로 재분류**한다 — 세 경우의 올바른 대응이 서로 다르고, 오판이 양방향으로 발생했다(의견을 물었는데 코드를 바꿔버림 / 지금 고치라는데 후속 PR로 미룸):

   | 재분류 | 판별 신호 | 대응 |
   |---|---|---|
   | **기술 설명 요청** | "~는 무엇인가요", "~는 왜 필요한가요", "동작 원리가 궁금합니다" — 코드 동작 설명만 요구 | 코드 변경 없이 설명 대댓글만 작성 |
   | **의견 요청** | "의견을 제시해주세요", "어떻게 생각하세요", "~하는게 좋을까요" **또는** 미래·가정 표현("~생기면", "나중에", "향후")으로 아직 없는 기능을 논의 | `OPINION` verdict — **코드를 먼저 바꾸지 않는다.** 옵션별 장단점을 제시하고 결정을 기다린다 |
   | **수정 여부 판단 요청** | 현재 구현이 맞는지 묻는 질문 | 기존 AGREE/PARTIAL/COUNTER로 처리 |

   기본값: 코멘트 대상이 **이번 diff가 이미 건드린 파일**이고 변경 범위가 작으면(같은 파일 내 시그니처·스타일 수준) **즉시 적용**한다. "범용성이 필요하다", "다른 PR이 맞겠다" 같은 자체 판단으로 후속 PR로 미루지 않는다 — 사용자가 먼저 요청한 경우만 예외다.

3. **승인/OK**: 해당 코멘트 resolve 처리 (전문가 검증 불필요)
4. **질문 또는 수정 요청** — 아래 순서를 반드시 따른다:
   a. 코멘트의 도메인 식별 (아키텍처, 성능, 보안, 테스트, 비즈니스 로직, 코드 스타일 등)
   b. `Agent(subagent_type="general-purpose")`로 해당 도메인 전문가를 spawn하여 검증. 코멘트 원문 + 관련 코드 + PR 맥락을 전달
   c. 전문가 verdict를 `{SESSION_DIR}/memory/expert-verdicts/{comment_id}.md`에 저장 — verdict 파일이 존재해야 코드 수정 진행 가능
   **[컨텍스트 격리]** 전문가 Agent는 verdict 전문을 파일에 저장하고, 반환값은 경량 형식으로 제한한다:
   `{AGREE|PARTIAL|COUNTER}: {1줄 사유} [verdict: {SESSION_DIR}/memory/expert-verdicts/{comment_id}.md]`
   상세 근거가 필요하면 verdict 파일을 선택적으로 Read한다.
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

### 4-D: CI Watch 재시작 (simon-ci-fix 위임)

> **[GATE — CI Watch 필수]** 4-B/4-C에서 코드가 변경되어 push한 경우, CI Watch 재시작을 **생략해서는 안 된다**. 코드 변경 없이 댓글만 남긴 COUNTER verdict의 경우에만 이 단계를 건너뛸 수 있다.

코드가 변경되었으므로 CI Watch를 simon-ci-fix에 위임한다:

1. **코드 변경 여부 확인**: 4-B에서 AGREE 또는 PARTIAL verdict로 코드를 수정 + push했는지 확인
   - 수정 + push 있음 → CI Watch 시작 (아래 2번으로)
   - 수정 없음 (COUNTER만) → 4-E로 진행
2. **simon-ci-fix 위임**: Step 3과 동일한 패턴으로 background agent를 시작한다:
   ```
   Agent(run_in_background=true, model="sonnet"):
     "다음 파일을 Read하고 그 지시를 따라 CI 수정을 실행하라:
      ~/.claude/skills/simon-ci-fix/SKILL.md

      컨텍스트:
      - PR 번호: {pr_number}
      - 브랜치: {branch}
      - SESSION_DIR: {SESSION_DIR}
      - 모드: DELEGATED
      - 결과 저장: {SESSION_DIR}/memory/ci-watch-result.md"
   ```
3. **4-E로 진행**: CI Watch는 background에서 실행하므로 4-E(수정 완료 안내)로 즉시 진행한다

> **[GATE — verdict 대조]** Step 4-E 진입 전 bash로 `ls {SESSION_DIR}/memory/expert-verdicts/*.md | wc -l`과 이번 사이클에서 처리한 질문/수정요청 코멘트 수를 대조한다. 불일치하면 누락 코멘트를 식별해 Step 4-B로 회귀한다 — 전문가 검증 게이트가 prose로만 존재하면 긴 피드백 루프의 compaction에서 소실될 수 있기 때문이다.

### 4-E: 수정 완료 안내

사용자에게 수정 내용 요약 보고:
> "피드백 반영 완료했습니다: {수정 요약}
> PR에서 확인해주세요: {PR_URL}
> (CI 모니터링은 계속 중입니다. 추가 코멘트를 남기시면 알려주세요.)"

### 종료 조건

사용자가 "LGTM" / "approve" / "승인" / PR ready 전환을 요청하면 Step 5로 진행한다.

## Step 5: 마무리

### Review Readiness Dashboard

Step 5 시작 시, 모든 검증 결과를 통합 대시보드로 사용자에게 제시한다:

```
=== Review Readiness ===
VERDICT:    {READY TO MERGE | BLOCKED — {blocking items}}
─────────────────────
Build:      {CLEARED|NOT CLEARED}
Tests:      {CLEARED|NOT CLEARED} ({passed}/{total})
Lint:       {CLEARED|NOT CLEARED}
Security:   {CLEARED|NOT CLEARED} (CRITICAL {N}, HIGH {N})
CI:         {CLEARED|PENDING|NOT CLEARED} ({passed}/{total} checks)
Comments:   {CLEARED|NOT CLEARED} ({unresolved} unresolved)
===
```

VERDICT를 최상단에 두는 이유: 반복 노출되는 상태 대시보드에서 사용자가 세부 항목을 읽지 않고도 "지금 머지 가능한가"를 즉시 판단할 수 있어야 한다 (outcome-first). 세부 항목은 결론의 근거로 아래에 배치한다.

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
5. **Standup Entry 기록** (CONNECTED/INDEPENDENT 모두):
   세션 요약을 `~/.claude/projects/{slug}/state/standup.jsonl`에 append한다 — 다음 세션의 Startup에서 최근 5개 entry를 자동 로딩하여 이전 세션의 학습과 미해결 결정을 사전 인지한다. Step 20(Self-Improvement)이 컨텍스트 소진으로 실행되지 않아도 standup이 확실히 기록되도록 이 시점(리뷰 완료 직후)에 기록한다.
   형식:
   ```json
   {"skill": "simon-dev", "branch": "{branch}", "date": "YYYY-MM-DD", "status": "completed|partial", "pr": "#{number}", "key_decisions": ["..."], "gotchas_learned": ["..."], "unresolved": ["..."]}
   ```
   - `key_decisions`: decision-journal.md에서 주요 결정 2-3개 추출
   - `gotchas_learned`: 세션 중 발견한 프로젝트 gotcha 요약
   - `unresolved`: 미해결 이슈 (있으면)
   - `state/` 디렉토리는 Phase A Startup에서 이미 생성되어 있음. INDEPENDENT 모드에서 디렉토리가 없으면 `mkdir -p`로 생성

## Core Reminders (전 구간 상시 적용)

파일 끝 배치는 의도적이다 — 긴 본문의 핵심 불변식을 세션 후반 시점에도 환기한다 (끝부분 리마인더 페어링 패턴):

- **PR은 항상 Draft로 생성** — Ready 전환은 Step 5에서 사용자 승인 후에만.
- **Step 2 인라인 리뷰는 절대 생략 불가** — push/PR 생성만으로 "완료" 처리 금지. 중단 후 재개 시에도 잔여 워크플로(인라인 리뷰 → CI Watch → 피드백 루프)를 끝까지 이어간다.
- **Step 4-B 전문가 검증 게이트** 없이 코드 수정·대댓글 작성 금지.
- **코드 변경을 push했다면 CI Watch 재시작 필수** (4-D).
