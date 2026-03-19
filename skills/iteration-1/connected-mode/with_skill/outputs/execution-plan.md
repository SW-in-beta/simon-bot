# Execution Plan: CONNECTED 모드 PR 생성 + 인라인 리뷰

## 사용자 요청 분석

> "simon-bot 작업이 끝났고 .claude/memory/review-sequence.md가 준비됐어. .claude/memory/branch-name.md에 feat/add-auth가 적혀있고, .claude/reports/add-auth-report.md도 있어. PR 만들고 인라인 리뷰 진행해줘."

## Mode Detection

### 판정: CONNECTED 모드

- `.claude/memory/review-sequence.md` **존재함** → CONNECTED 모드 확정
- `.claude/memory/branch-name.md` 존재 → 내용: `feat/add-auth`
- `.claude/reports/add-auth-report.md` 존재 → PR body로 활용
- `.claude/memory/plan-summary.md` 존재 → 인라인 코멘트의 계획 매핑 항목에 활용

**Step 0 (Standalone 분석)은 SKIP** — CONNECTED 모드이므로 review-sequence가 이미 준비되어 있다.

---

## Step 1: Draft PR 생성

### 1-1. 파일 읽기 (병렬)

다음 파일들을 **병렬로** 읽는다:

| 파일 | 목적 |
|------|------|
| `.claude/memory/branch-name.md` | 브랜치명 확인 (`feat/add-auth`) |
| `.claude/reports/add-auth-report.md` | PR body 내용 |
| `.claude/memory/review-sequence.md` | Review Guide 섹션 작성용 |
| `.claude/memory/plan-summary.md` | 인라인 코멘트 계획 매핑용 (Step 2에서 사용) |
| `.claude/memory/pr-info.md` | 이미 PR이 있는지 확인 (없으면 새로 생성) |

### 1-2. 브랜치 push

```bash
git push -u origin feat/add-auth
```

### 1-3. PR body 준비

`.claude/reports/add-auth-report.md`의 내용을 PR body의 기본 내용으로 사용한다.

여기에 **Review Guide** 섹션을 append한다:
- `review-sequence.md`에서 논리적 변경 단위 수 + 각 단위 한줄 요약 추출
- 리뷰 순서 안내 (왜 이 순서인지)
- 추가 맥락 (있으면)

최종 body를 임시 파일에 저장하거나 HEREDOC으로 전달한다.

### 1-4. Draft PR 생성

```bash
gh pr create --draft \
  --title "feat: add-auth 기능 추가" \
  --body-file .claude/reports/add-auth-report.md
```

> 주: 실제 title은 review-sequence.md와 report 내용을 분석하여 적절한 feature summary를 결정한다. `--body-file`로 report를 사용하되, Review Guide 섹션을 추가한 수정 버전을 사용할 수 있다. body가 길면 `--body-file`로 임시 파일을 전달하고, Review Guide 섹션이 포함된 최종 body를 별도로 구성한다.

### 1-5. PR 정보 저장

PR 생성 결과에서 URL과 번호를 추출하여 `.claude/memory/pr-info.md`에 저장한다.

### 1-6. Review Guide 섹션 추가

PR body에 Review Guide가 누락되었으면 `gh pr edit`으로 body를 업데이트한다:

```bash
gh pr edit {pr_number} --body "$(cat <<'EOF'
{기존 report 내용}

---

## Review Guide

**논리적 변경 단위: N개**

| 순서 | 변경 단위 | 한줄 요약 |
|------|-----------|-----------|
| 1 | {제목} | {요약} |
| 2 | {제목} | {요약} |
| ... | ... | ... |

**리뷰 순서 안내**: {데이터/호출 흐름 상류→하류 순서로 배치한 이유}

**추가 맥락**: {있으면}
EOF
)"
```

---

## Step 2: 인라인 코드 리뷰 작성

### 2-1. 리뷰 준비 (병렬)

다음을 **병렬로** 실행한다:

```bash
# PR diff 확인
gh pr diff {pr_number}
```

```
# review-sequence.md는 이미 Step 1에서 읽었으므로 메모리에 있음
# plan-summary.md도 이미 읽었으므로 메모리에 있음
```

### 2-2. 라인 번호 매핑

`gh pr diff` 출력에서 각 변경 단위의 핵심 파일/라인 번호를 추출한다:
- diff의 `+` 라인에서 **실제 파일 라인 번호**를 추출 (GitHub API는 diff 라인이 아닌 파일의 실제 라인 번호를 사용)
- 각 변경 단위의 핵심 변경이 시작되는 라인 (함수/메서드 시그니처 또는 핵심 로직의 첫 줄)을 코멘트 위치로 선택

### 2-3. 인라인 코멘트 작성

각 변경 단위에 대해 **CONNECTED 모드 양식**으로 코멘트를 작성한다:

```markdown
**[변경 단위 N: {제목}]**

**계획 매핑**: {plan-summary.md의 어떤 Unit/목표를 구현한 것인지}
**변경 전 상태**: {구체적 코드 동작 수준}
**변경 내용**: {구체적으로 어떤 부분을 어떻게 개선/추가했는지}
**관련 변경 단위**: {의존/호출/데이터 흐름}
**리뷰 포인트**:
1. {구체적 기술 포인트 — 코드 수준 근거 포함}
2. {미수정 사유}
3. {유사 패턴 비교}
**전문가 우려사항**: {review-sequence.md의 우려사항 + 반영 내용}
**트레이드오프**: {한계 명시 + 선택 이유}
```

- **대표 파일 1-2개**: 위 전체 양식으로 풍부한 맥락의 인라인 코멘트
- **나머지 파일**: 1-2줄 역할 설명만 ("이 테스트는 변경 단위 1의 새 분기를 검증합니다")

### 2-4. review-payload.json 구성

`.claude/memory/review-payload.json` 파일을 생성한다:

```json
{
  "body": "",
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/...",
      "line": 42,
      "body": "**[변경 단위 1: ...]**\n\n..."
    },
    ...
  ]
}
```

### 2-5. 리뷰 제출

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input .claude/memory/review-payload.json
```

### 2-6. Fallback 처리

API 호출이 실패하면 (line 매핑 오류 등):
- 변경 단위별 PR 일반 코멘트로 대체:
  ```bash
  gh pr comment {pr_number} --body "{변경 단위 리뷰 내용}"
  ```
- 사용자에게 fallback이 적용되었음을 알린다.

---

## Step 3: CI Watch + 리뷰 안내

### 3-1. CI Watch (Background Agent)

Step 2 완료 직후, **background agent**를 시작한다:

```
Agent(run_in_background=true)
```

Agent에 전달할 컨텍스트:
- PR 번호 (`.claude/memory/pr-info.md`에서)
- 브랜치명 (`feat/add-auth`)
- 프로젝트 빌드/테스트 명령 (`.claude/workflow/config.yaml` 확인, 있으면)
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
2. 모든 체크 통과 → CI Watch 종료, 결과를 `.claude/memory/ci-watch-result.md`에 기록
3. CI 실패 시:
   a. `gh run view {run_id} --log-failed`로 실패 로그 확인
   b. 실패 유형 분류: BUILD / TEST / LINT / ENV
   c. **ENV 유형은 수정하지 않는다** — 기록만
   d. BUILD/TEST/LINT → 진단 → 수정 → `fix(ci): {수정 내용}` 커밋 → push
   e. PR에 코멘트로 수정 내용 요약
   f. CI 재실행 대기 → 1번으로 복귀

### 3-2. 사용자 리뷰 안내

CI Watch 시작 후, 사용자에게 메시지 출력:

> "Draft PR에 코드 리뷰를 작성했습니다: {PR_URL}
> PR에서 리뷰를 확인하시고, 궁금한 점이나 수정 요청을 코멘트로 남겨주세요.
> 피드백이 준비되면 말씀해주세요.
> (CI를 모니터링하고 있습니다 — 실패하면 자동으로 수정합니다.)"

---

## Step 4: 피드백 루프

사용자 승인("LGTM" / "approve" / "승인" / PR ready 전환 요청)까지 반복한다.

### 4-A: 피드백 수집

1. CI Watch 결과 확인: `.claude/memory/ci-watch-result.md` 읽기
   - 아직 실행 중이면 현재 상태를 사용자에게 보고
   - CI fix로 변경된 부분이 있으면 요약 제시
2. PR 코멘트 수집:
   ```bash
   # 인라인 리뷰 코멘트
   gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
   # 일반 PR 코멘트
   gh api repos/{owner}/{repo}/issues/{pr_number}/comments
   ```

### 4-B: 코드 수정

피드백을 분류하여 처리:
- **질문**: PR 코멘트로 답변 (`gh api` reply)
- **수정 요청**: 코드 수정 → 커밋 → push → PR 코멘트로 "수정 완료" 답변
- **승인/OK**: 해당 코멘트 resolve 처리

### 4-C: 인라인 리뷰 재작성

수정된 변경 단위에 대해서만:
- 기존 코멘트 resolve 처리
- 수정된 코드 위치에 **수정 반영 양식**으로 새 코멘트 작성:
  ```markdown
  **[변경 단위 N: {제목}] — 수정 반영**

  **피드백 요약**: {사용자 요청 원문 인용}
  **수정 내용**: {Before/After 코드 발췌}
  **영향 범위**: {다른 변경 단위에 미치는 영향 또는 "영향 없음"}
  ```
- 변경 없는 부분은 건드리지 않음

### 4-D: CI Watch 재시작

코드 변경 후 CI Watch background agent를 재시작한다 (Step 3과 동일 로직, max 3 cycles).

### 4-E: 수정 완료 안내

> "피드백 반영 완료했습니다: {수정 요약}
> PR에서 확인해주세요: {PR_URL}
> (CI를 다시 모니터링하고 있습니다.)"

---

## Step 5: 마무리

사용자 승인 후:

1. PR 상태 확인 — 사용자 요청에 따라:
   - Ready 전환: `gh pr ready {pr_number}`
   - Draft 유지: 그대로 둠
2. 피드백 영속 기록: `.claude/memory/feedback.md`
3. Completion Summary 출력:
   ```
   === 리뷰 완료 ===
   PR: #{number} ({Draft/Ready})
   리뷰 라운드: {N}회
   수정 커밋: {N}개
   CI 수정: {N}건
   미해결 코멘트: {N}건
   ===
   ```
4. CONNECTED 모드이므로 추가 기록:
   - `.claude/memory/retrospective.md` 기록
   - `CONTEXT.md` 최종 상태 갱신

---

## 생성되는 Artifact 목록

| Artifact | 경로 | 생성 시점 |
|----------|------|-----------|
| PR (Draft) | GitHub 원격 | Step 1 |
| PR 정보 | `.claude/memory/pr-info.md` | Step 1-5 |
| 인라인 리뷰 payload | `.claude/memory/review-payload.json` | Step 2-4 |
| 인라인 리뷰 코멘트 | GitHub PR 인라인 코멘트 | Step 2-5 |
| CI Watch 결과 | `.claude/memory/ci-watch-result.md` | Step 3-1 |
| 피드백 기록 | `.claude/memory/feedback.md` | Step 5-2 |
| 회고 | `.claude/memory/retrospective.md` | Step 5-4 |

## 읽는 파일 목록

| 파일 | 읽는 시점 | 목적 |
|------|-----------|------|
| `.claude/memory/review-sequence.md` | Step 1-1 | 변경 단위 구조, Review Guide, 인라인 코멘트 작성 |
| `.claude/memory/branch-name.md` | Step 1-1 | 브랜치명 확인 (`feat/add-auth`) |
| `.claude/reports/add-auth-report.md` | Step 1-1 | PR body |
| `.claude/memory/plan-summary.md` | Step 1-1 | 인라인 코멘트의 계획 매핑 항목 |
| `.claude/memory/pr-info.md` | Step 1-1 | 기존 PR 존재 여부 확인 |
| `.claude/workflow/config.yaml` | Step 3-1 | 프로젝트 빌드/테스트 명령 (있으면) |
| `.claude/memory/ci-watch-result.md` | Step 4-A | CI Watch 결과 확인 |

## 실행하는 명령어 목록

| 명령어 | 시점 | 목적 |
|--------|------|------|
| `git push -u origin feat/add-auth` | Step 1-2 | 브랜치 push |
| `gh pr create --draft --title "..." --body-file ...` | Step 1-4 | Draft PR 생성 |
| `gh pr edit {pr_number} --body "..."` | Step 1-6 | Review Guide 섹션 추가 |
| `gh pr diff {pr_number}` | Step 2-1 | PR diff 확인 + 라인 번호 매핑 |
| `gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --method POST --input .claude/memory/review-payload.json` | Step 2-5 | 인라인 리뷰 제출 |
| `gh pr comment {pr_number} --body "..."` | Step 2-6 (fallback) | 인라인 실패 시 일반 코멘트 |
| `gh pr checks {pr_number} --watch --fail-fast` | Step 3-1 | CI 모니터링 |
| `gh run view {run_id} --log-failed` | Step 3-1 (CI 실패 시) | 실패 로그 확인 |
| `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments` | Step 4-A | 인라인 리뷰 코멘트 수집 |
| `gh api repos/{owner}/{repo}/issues/{pr_number}/comments` | Step 4-A | 일반 PR 코멘트 수집 |
| `gh pr ready {pr_number}` | Step 5-1 (사용자 요청 시) | PR ready 전환 |
