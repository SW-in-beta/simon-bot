# Execution Plan: PR #42 피드백 루프 처리

## 상황 분석

사용자 요청: "PR #42에 리뷰 피드백을 남겼어. 인증 미들웨어의 에러 핸들링을 개선해달라는 코멘트가 있어. 수정 반영하고 다시 리뷰해줘."

- 현재 위치: **Step 4 (피드백 루프)** 진행 중
- PR #42가 이미 존재 (`.claude/memory/pr-info.md`에 기록됨)
- 리포: Buzzvil/example-repo
- 사용자가 PR에 인라인 코멘트를 남긴 상태 → 4-A ~ 4-E 사이클 1회 실행

---

## Step 4-A: 피드백 수집

### 읽을 파일

1. `.claude/memory/pr-info.md` — PR 번호(#42)와 URL 확인
2. `.claude/memory/ci-watch-result.md` — 이전 CI Watch 결과 확인 (존재하면)
3. `.claude/memory/review-sequence.md` — 기존 변경 단위 구조 확인 (피드백이 어떤 변경 단위에 해당하는지 매핑용)
4. `.claude/memory/branch-name.md` — 브랜치명 확인

### 실행할 명령 (병렬)

```bash
# PR 인라인 리뷰 코멘트 수집 (코드에 달린 댓글)
gh api repos/Buzzvil/example-repo/pulls/42/comments

# PR 일반 코멘트 수집 (이슈 코멘트)
gh api repos/Buzzvil/example-repo/issues/42/comments
```

### 이 단계의 산출물

- 피드백 목록 분류 결과 (메모리에 유지):
  - "인증 미들웨어의 에러 핸들링 개선" → **수정 요청**으로 분류
  - 코멘트의 정확한 내용, 파일 경로, 라인 번호, comment_id 파악

---

## Step 4-B: 코드 수정

### 읽을 파일

1. 피드백이 가리키는 **인증 미들웨어 파일** (경로는 PR 코멘트의 `path` 필드에서 추출, 예: `src/middleware/auth.py` 또는 `src/middleware/auth.ts`)
2. 인증 미들웨어가 호출하는 **관련 에러 핸들링 모듈** (import 추적)
3. 해당 미들웨어의 **테스트 파일** (에러 핸들링 관련 테스트 케이스 확인)
4. 코드베이스 내 **유사한 에러 핸들링 패턴** — 일관성 확보를 위해 다른 미들웨어의 에러 핸들링 방식 참조

### 코드 수정 작업

1. PR 코멘트의 구체적 요청을 분석하여 에러 핸들링 개선 내용 결정
   - 예: try-catch 블록 추가/개선, 에러 타입별 분기 처리, 적절한 HTTP 상태 코드 반환, 에러 로깅 추가 등
2. 인증 미들웨어 파일 수정 (Edit 도구 사용)
3. 필요시 테스트 파일 수정/추가
   - CLAUDE.md TDD 원칙: 버그 수정 시 실패 테스트부터 작성 → 하지만 이 경우 "개선"이므로 기존 테스트 보완이 더 적절할 수 있음
   - 에러 핸들링 시나리오별 테스트 케이스 추가

### 실행할 명령

```bash
# 테스트 실행 (수정 후 검증) — 프로젝트 테스트 명령에 따라 다름
# 예: pytest, npm test, go test 등
# run_in_background: true로 실행하여 다음 작업 병행 가능
```

### 커밋 및 푸시

```bash
# 변경 파일 스테이징
git add src/middleware/auth.py tests/test_auth_middleware.py  # (실제 파일 경로에 맞게)

# 커밋 (git-commit 스킬 사용, semantic commit + Korean description)
git commit -m "$(cat <<'EOF'
fix: 인증 미들웨어 에러 핸들링 개선

PR #42 피드백 반영: {구체적 수정 내용 요약}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"

# 푸시
git push
```

### PR 코멘트로 수정 완료 답변

```bash
# 원본 코멘트에 reply
gh api repos/Buzzvil/example-repo/pulls/42/comments/{comment_id}/replies \
  --method POST \
  -f body="수정 완료했습니다. {구체적 수정 내용 요약}"
```

---

## Step 4-C: 인라인 리뷰 재작성

### 읽을 파일

1. `gh pr diff 42` — 수정 후 최신 diff 확인
2. `.claude/memory/review-sequence.md` — 수정된 변경 단위 식별
3. `references/inline-review-format.md` — 피드백 반영 리뷰 양식 확인 (이미 읽음)

### 리뷰 작성 작업

1. 기존 인라인 코멘트 중 수정된 변경 단위의 코멘트를 resolve 처리
2. 수정된 코드 위치에 **수정 반영 양식**으로 새 인라인 코멘트 작성:

```markdown
**[변경 단위 N: {인증 미들웨어 관련 제목}] — 수정 반영**

**피드백 요약**: {사용자 코멘트 원문 인용 — "인증 미들웨어의 에러 핸들링을 개선해달라"}
**수정 내용**: {Before/After 코드 발췌 — 예: 기존에는 모든 에러를 500으로 반환했으나, 이제 401/403/500을 구분하여 반환}
**영향 범위**: {다른 변경 단위에 미치는 영향 — 예: "영향 없음" 또는 "에러 응답 형식 변경으로 프론트엔드 에러 핸들링에 영향"}
```

3. 변경되지 않은 부분의 기존 코멘트는 건드리지 않음

### review-payload.json 구성 및 제출

```bash
# .claude/memory/review-payload.json 작성 (Write 도구)
# 수정된 파일의 실제 라인 번호 매핑 필수

# 리뷰 제출
gh api repos/Buzzvil/example-repo/pulls/42/reviews \
  --method POST \
  --input .claude/memory/review-payload.json
```

### Fallback

API 호출 실패 시 (line 매핑 오류 등) → PR 일반 코멘트로 대체:

```bash
gh pr comment 42 --body "{수정 반영 리뷰 내용}"
```

사용자에게 fallback 적용 사실 고지.

---

## Step 4-D: CI Watch 재시작

### 실행할 명령

Background agent 시작 (Agent tool, `run_in_background: true`):

Agent에 전달할 컨텍스트:
- PR 번호: 42
- 브랜치명: `.claude/memory/branch-name.md`에서 읽은 값
- 프로젝트 빌드/테스트 명령: `.claude/workflow/config.yaml` (있으면)

Agent 내부 로직 (max 3 cycles):

```bash
# CI 상태 확인
gh pr checks 42 --watch --fail-fast

# 실패 시:
# 1. gh run view {run_id} --log-failed
# 2. 실패 유형 분류 (BUILD/TEST/LINT/ENV)
# 3. ENV는 수정 불가 → 기록만
# 4. 나머지 → 진단 → 수정 → 커밋(fix(ci): ...) → 푸시
# 5. PR 코멘트로 수정 내용 요약
# 6. 재실행 대기 → 1번 복귀
```

### 산출물

`.claude/memory/ci-watch-result.md` 갱신

---

## Step 4-E: 수정 완료 안내

### 사용자에게 출력할 메시지

```
피드백 반영 완료했습니다:
- 인증 미들웨어의 에러 핸들링을 개선했습니다: {구체적 수정 내용 1-2줄 요약}
- 수정된 코드에 인라인 리뷰를 새로 작성했습니다.

PR에서 확인해주세요: {PR_URL}
(CI를 다시 모니터링하고 있습니다 — 실패하면 자동으로 수정합니다.)
```

---

## 종료 조건 판단

사용자의 다음 응답을 대기:
- "LGTM" / "approve" / "승인" / PR ready 전환 요청 → **Step 5: 마무리**로 이동
- 추가 피드백 → **Step 4-A로 복귀** (다음 피드백 루프 사이클)

---

## 산출물 요약

| 산출물 | 유형 | 설명 |
|--------|------|------|
| 인증 미들웨어 수정 코드 | 코드 변경 | 에러 핸들링 개선 |
| 테스트 코드 (필요시) | 코드 변경 | 에러 핸들링 시나리오 테스트 |
| Git 커밋 1개 | 커밋 | `fix: 인증 미들웨어 에러 핸들링 개선` |
| PR 코멘트 reply | GitHub API | 원본 피드백에 수정 완료 답변 |
| `.claude/memory/review-payload.json` | 파일 | 수정 반영 인라인 리뷰 |
| 인라인 리뷰 코멘트 (수정 반영 양식) | GitHub API | 수정된 변경 단위에 대한 리뷰 |
| `.claude/memory/ci-watch-result.md` | 파일 갱신 | CI 모니터링 결과 |
| 사용자 안내 메시지 | 출력 | 수정 완료 + PR 확인 요청 |

---

## 전체 실행 순서 (의존성 그래프)

```
[4-A] 피드백 수집 (병렬: pr-info 읽기 + PR 코멘트 2종 API + ci-watch-result 읽기)
  ↓
[4-B] 코드 수정 (직렬: 코드 분석 → 수정 → 테스트 → 커밋 → 푸시 → reply)
  ↓
[4-C + 4-D] 병렬 실행:
  ├─ [4-C] 인라인 리뷰 재작성 (diff 확인 → payload 구성 → API 제출)
  └─ [4-D] CI Watch background agent 시작
  ↓
[4-E] 수정 완료 안내 (4-C 완료 후)
```
