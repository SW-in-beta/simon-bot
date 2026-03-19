# 실행 계획: simon-bot-review (STANDALONE 모드)

## 전제 조건

- 현재 브랜치: `feat/add-auth`
- Base 브랜치: `main`
- `.claude/memory/review-sequence.md` 미존재 → **STANDALONE 모드** 감지
- 사용자 맥락: JWT 토큰 기반 인증 미들웨어 + 로그인/로그아웃 API 엔드포인트

---

## Mode Detection

### 읽을 파일
- `.claude/memory/review-sequence.md` — 존재 여부 확인 → **미존재 확인** → STANDALONE 모드 진입

### 판단
- review-sequence.md 없음 → Step 0부터 시작
- `.claude/memory/branch-name.md`, `.claude/reports/`, `.claude/memory/pr-info.md` 존재 여부도 확인하지만, STANDALONE이므로 대부분 없을 것으로 예상

---

## Step 0: Standalone 분석

### Step 0-A: 변경사항 수집

**명령어 (병렬 실행):**

```bash
# 1. Base branch 감지
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
# 실패 시 main → master 순서로 시도

# 2. 변경사항 수집 (3개 병렬)
git diff main...HEAD
git log main...HEAD --oneline
git diff main...HEAD --stat
```

**파일 읽기:**
- `git diff main...HEAD --stat`의 결과로 변경된 파일 목록을 확인
- 변경된 파일 **전체**를 Read tool로 읽기 (diff만으로는 변경 전 맥락 파악 불충분)
- 예상 파일: 인증 미들웨어, 로그인/로그아웃 핸들러, JWT 유틸리티, 테스트 파일, 라우트 설정 등

### Step 0-B: Agent Team 분석 (2개 Agent 병렬 spawn)

**Agent 1: architect agent**

지시사항:
- 전체 diff를 받아 **논리적 변경 단위(Logical Change Unit)**로 그룹핑
- 데이터/호출 흐름 순서 (상류 → 하류)로 정렬
- 각 변경 단위: 제목, 변경 동기, 관련 파일 목록(역할), 다른 단위와의 연관, 리뷰 순서 결정 근거
- 코드베이스 내 유사 패턴 비교 분석
- 산출물: `.claude/memory/review-sequence-draft-arch.md`

**Agent 2: writer agent**

지시사항:
- 전체 diff + 변경 파일을 읽고, 각 주요 변경에 대해:
  - 변경 전 상태 (Before Context)
  - 변경 내용 (What Changed)
  - 핵심 코드 변경 (Before/After diff 발췌)
  - 리뷰 포인트 (번호 매긴 구체적 기술 포인트)
  - 미수정 사유, 유사 패턴 비교
  - 전문가 수준 우려사항 (보안, 성능, 데이터 정합성, 에러 핸들링)
  - 트레이드오프
- 산출물: `.claude/memory/review-sequence-draft-writer.md`

### Step 0-C: 통합 및 교차 검증

**읽을 파일:**
- `.claude/memory/review-sequence-draft-arch.md`
- `.claude/memory/review-sequence-draft-writer.md`

**수행 작업:**
1. architect의 변경 단위 구조를 기본 골격으로 사용
2. writer의 맥락/우려사항/트레이드오프를 각 변경 단위에 매핑
3. 불일치 검증:
   - architect가 분리한 단위를 writer가 합쳐야 한다고 판단한 경우 → 리뷰 흐름 기준으로 판단
   - writer가 발견한 우려사항이 architect의 리뷰 포인트에 없는 경우 → 추가

**산출물:** `.claude/memory/review-sequence.md` (review-sequence.md 포맷으로 통합 저장)

### Step 0-D: Report 생성

**수행 작업:**
- review-sequence.md 기반으로 간략 report 생성:
  - Before/After 요약
  - 주요 리뷰 포인트
  - 트레이드오프
  - 우려사항
  - 변경 파일 목록

**산출물:** `.claude/reports/feat-add-auth-report.md`

---

## Step 1: Draft PR 생성

### 명령어 (순차 실행)

```bash
# 1. 브랜치명 확인
git branch --show-current
# → feat/add-auth

# 2. 브랜치 push
git push -u origin feat/add-auth

# 3. Draft PR 생성 (report 파일을 body-file로 사용)
gh pr create --draft \
  --title "feat: JWT 토큰 기반 인증 미들웨어 및 로그인/로그아웃 API 구현" \
  --body-file .claude/reports/feat-add-auth-report.md
```

### PR description에 Review Guide 섹션 추가

PR 생성 후, body를 편집하여 Review Guide 추가:
```bash
# PR 번호 확인 후 body 편집
gh pr edit {pr_number} --body "$(cat <<'EOF'
{기존 report 내용}

## Review Guide

### 논리적 변경 단위
1. {변경 단위 1 한줄 요약}
2. {변경 단위 2 한줄 요약}
...

### 리뷰 순서 안내
{왜 이 순서인지 설명}

### 추가 맥락
{있으면 기술}
EOF
)"
```

### 산출물
- `.claude/memory/pr-info.md` — PR URL과 번호 저장

---

## Step 2: 인라인 코드 리뷰 작성

### 리뷰 준비

**명령어:**
```bash
# PR diff 확인
gh pr diff {pr_number}
```

**읽을 파일:**
- `.claude/memory/review-sequence.md`

**수행 작업:**
- 각 변경 단위의 핵심 파일/라인 번호 매핑
- diff의 `+` 라인에서 **실제 파일 라인 번호** 추출 (GitHub API가 요구하는 형식)
- 변경 단위의 핵심 변경이 시작되는 라인 (함수/메서드 시그니처 또는 핵심 로직의 첫 줄)을 코멘트 위치로 선택

### 인라인 코멘트 작성

각 변경 단위에 대해 **STANDALONE 모드 양식** 적용:

```markdown
**[변경 단위 N: {제목}]**

**변경 동기**: {왜 이 변경이 필요한지}
**변경 전 상태**: {구체적 코드 동작 수준}
**변경 내용**: {구체적으로 어떤 부분을 어떻게 개선/추가했는지}
**관련 변경 단위**: {의존/호출/데이터 흐름 관계}
**리뷰 포인트**:
1. {구체적 기술 포인트}
2. {미수정 사유}
3. {유사 패턴 비교}
**전문가 우려사항**: {Step 0에서 architect/writer가 도출한 우려사항}
**트레이드오프**: {설계 결정과 그 이유}
```

- 대표 파일 1-2개: 풍부한 맥락의 인라인 코멘트
- 나머지 파일: 1-2줄 역할 설명

### 리뷰 제출

**산출물:** `.claude/memory/review-payload.json`

```bash
# owner/repo 확인
gh repo view --json owner,name

# 리뷰 제출
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input .claude/memory/review-payload.json
```

### Fallback

인라인 리뷰 API 호출 실패 시 (line 매핑 오류 등):
```bash
gh pr comment {pr_number} --body "{변경 단위별 리뷰 내용}"
```
사용자에게 fallback 적용 사실을 알림.

---

## Step 3: CI Watch + 리뷰 안내

### CI Watch (Background Agent)

Step 2 완료 직후, **background agent** 시작:

```
Agent(run_in_background=true)
```

Agent에 전달할 컨텍스트:
- PR 번호 (`.claude/memory/pr-info.md`에서 읽기)
- 브랜치명: `feat/add-auth`
- 프로젝트 빌드/테스트 명령 (`.claude/workflow/config.yaml` 확인, 있으면 사용)

**CI 모니터링 루프 (max 3 cycles):**

```bash
# 1. CI 상태 확인
gh pr checks {pr_number} --watch --fail-fast
# --watch 미지원 시 30초 간격 polling:
# gh pr checks {pr_number}

# 2. 모든 체크 통과 → 종료, 결과 기록
# 3. CI 실패 시:
#    a. gh run view {run_id} --log-failed
#    b. 실패 유형 분류: BUILD / TEST / LINT / ENV
#    c. ENV 유형은 수정하지 않음 — 결과에 기록만
#    d. 진단 → 수정 → 커밋 (fix(ci): {수정 내용}) → 푸시
#    e. PR에 코멘트로 수정 내용 요약
#    f. CI 재실행 대기 → 1번으로 복귀
```

**산출물:** `.claude/memory/ci-watch-result.md`

### 사용자 리뷰 안내

CI Watch 시작 후, 사용자에게 메시지 출력:

> "Draft PR에 코드 리뷰를 작성했습니다: {PR_URL}
> PR에서 리뷰를 확인하시고, 궁금한 점이나 수정 요청을 코멘트로 남겨주세요.
> 피드백이 준비되면 말씀해주세요.
> (CI를 모니터링하고 있습니다 — 실패하면 자동으로 수정합니다.)"

---

## Step 4: 피드백 루프

사용자 승인까지 아래 4-A ~ 4-E를 반복한다.

### 4-A: 피드백 수집

```bash
# CI Watch 결과 확인
# → .claude/memory/ci-watch-result.md 읽기

# PR 코멘트 수집
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments    # 인라인 리뷰 코멘트
gh api repos/{owner}/{repo}/issues/{pr_number}/comments    # 일반 PR 코멘트
```

### 4-B: 코드 수정

피드백 분류 후 처리:
- **질문**: PR 코멘트로 답변 (`gh api` reply)
- **수정 요청**: 코드 수정 → git-commit 스킬로 커밋 → `git push` → PR 코멘트로 "수정 완료" 답변
- **승인/OK**: 해당 코멘트 resolve 처리

### 4-C: 인라인 리뷰 재작성

수정된 변경 단위에 대해서만 **수정 반영 양식**으로 새 코멘트 작성:

```markdown
**[변경 단위 N: {제목}] — 수정 반영**

**피드백 요약**: {사용자 요청 원문 인용}
**수정 내용**: {Before/After 코드 발췌}
**영향 범위**: {다른 변경 단위 영향. 없으면 "영향 없음"}
```

기존 코멘트 resolve 처리 후, 새 위치에 코멘트 작성.

### 4-D: CI Watch 재시작

코드 변경 후 CI Watch background agent 재시작 (Step 3과 동일 로직, max 3 cycles).

### 4-E: 수정 완료 안내

> "피드백 반영 완료했습니다: {수정 요약}
> PR에서 확인해주세요: {PR_URL}
> (CI를 다시 모니터링하고 있습니다.)"

### 종료 조건

사용자가 "LGTM" / "approve" / "승인" / PR ready 전환 요청 시 루프 종료 → Step 5로 진행.

---

## Step 5: 마무리

```bash
# 사용자 요청에 따라 PR 상태 전환
gh pr ready {pr_number}    # Ready 전환 요청 시
# 또는 Draft 유지
```

**산출물:** `.claude/memory/feedback.md` (피드백 영속 기록)

**Completion Summary 출력:**
```
=== 리뷰 완료 ===
PR: #{number} ({Draft/Ready})
리뷰 라운드: {N}회
수정 커밋: {N}개
CI 수정: {N}건
미해결 코멘트: {N}건
===
```

---

## 전체 산출물 목록

| 단계 | 파일 경로 | 설명 |
|------|-----------|------|
| Step 0-B | `.claude/memory/review-sequence-draft-arch.md` | architect agent 산출물 |
| Step 0-B | `.claude/memory/review-sequence-draft-writer.md` | writer agent 산출물 |
| Step 0-C | `.claude/memory/review-sequence.md` | 통합 리뷰 시퀀스 |
| Step 0-D | `.claude/reports/feat-add-auth-report.md` | 간략 report |
| Step 1 | `.claude/memory/pr-info.md` | PR URL/번호 |
| Step 2 | `.claude/memory/review-payload.json` | 인라인 리뷰 페이로드 |
| Step 3 | `.claude/memory/ci-watch-result.md` | CI 모니터링 결과 |
| Step 5 | `.claude/memory/feedback.md` | 피드백 영속 기록 |

## 전체 실행 흐름 요약

```
Mode Detection (review-sequence.md 미존재 확인)
  ↓
Step 0-A: git diff/log/stat + 변경 파일 전체 Read (병렬)
  ↓
Step 0-B: architect agent + writer agent (병렬 Agent spawn)
  ↓
Step 0-C: 두 산출물 통합 → review-sequence.md
  ↓
Step 0-D: report 생성 → .claude/reports/feat-add-auth-report.md
  ↓
Step 1: git push → gh pr create --draft → pr-info.md 저장 → Review Guide 추가
  ↓
Step 2: gh pr diff → 라인 매핑 → review-payload.json → gh api 제출 (실패 시 fallback)
  ↓
Step 3: CI Watch background agent 시작 + 사용자에게 리뷰 안내
  ↓
Step 4: 피드백 루프 (4-A→4-B→4-C→4-D→4-E, 승인까지 반복)
  ↓
Step 5: PR 상태 전환 + feedback.md + Completion Summary
```
