# PR #42 리뷰 피드백 반영 실행 계획

## 개요

PR #42에 남긴 리뷰 코멘트(인증 미들웨어 에러 핸들링 개선)를 확인하고, 코드를 수정한 뒤 다시 리뷰하는 전체 과정을 기술한다.

---

## Step 1: PR 정보 및 리뷰 코멘트 수집 (병렬 실행)

동시에 세 가지 정보를 수집한다.

### 1-1. PR 메타데이터 확인

```bash
gh pr view 42 --json title,body,headRefName,baseRefName,state,files
```

- PR의 브랜치명, 상태, 변경 파일 목록을 파악한다.

### 1-2. 리뷰 코멘트 확인

```bash
gh api repos/{owner}/{repo}/pulls/42/comments
```

- 인증 미들웨어 에러 핸들링 관련 코멘트의 정확한 내용, 대상 파일, 라인 번호를 확인한다.

### 1-3. PR 리뷰(일반 코멘트) 확인

```bash
gh pr view 42 --comments
```

- 인라인 코멘트 외에 일반 리뷰 코멘트가 있는지도 확인한다.

---

## Step 2: PR 브랜치로 전환

```bash
gh pr checkout 42
```

- PR의 head 브랜치를 로컬에 체크아웃한다.

---

## Step 3: 대상 코드 분석 (병렬 실행)

### 3-1. 인증 미들웨어 파일 탐색

```bash
# Glob 도구로 미들웨어 관련 파일 검색
Glob: **/middleware/**auth* , **/auth*middleware*
```

### 3-2. 에러 핸들링 패턴 분석

```bash
# Grep 도구로 현재 에러 핸들링 패턴 검색
Grep: pattern="catch|throw|error|Error" path=<미들웨어 파일 경로>
```

### 3-3. 리뷰 코멘트가 지적한 구체적 라인 확인

```bash
# Read 도구로 해당 파일의 전체 내용 확인
Read: file_path=<리뷰에서 지적한 파일 경로>
```

---

## Step 4: 코드 수정

리뷰 코멘트의 구체적 내용에 따라 Edit 도구로 수정한다. 일반적인 인증 미들웨어 에러 핸들링 개선 사항은 다음을 포함할 수 있다.

- **구체적 에러 타입 분기**: 토큰 만료, 토큰 누락, 토큰 위변조 등 케이스별 분기 처리
- **적절한 HTTP 상태 코드 반환**: 401 Unauthorized vs 403 Forbidden 구분
- **에러 메시지 표준화**: 클라이언트에 노출할 메시지와 내부 로그용 메시지 분리
- **에러 로깅 추가**: 보안 관련 에러는 반드시 로깅

```bash
# Edit 도구로 해당 파일 수정
Edit: file_path=<대상 파일>, old_string=<기존 코드>, new_string=<개선된 코드>
```

---

## Step 5: 테스트 (TDD 준수)

### 5-1. 기존 테스트 실행

```bash
# 프로젝트의 테스트 러너에 따라 다름 (예시)
npm test -- --grep "auth middleware"
# 또는
npx vitest run <미들웨어 테스트 파일>
```

### 5-2. 리뷰 피드백 관련 테스트 추가/수정

수정한 에러 핸들링 시나리오에 대한 테스트가 없다면 추가한다.

- 토큰 만료 시 401 응답 확인
- 토큰 누락 시 401 응답 확인
- 잘못된 토큰 시 401 응답 확인
- 권한 부족 시 403 응답 확인
- 에러 응답 body 형식 검증

### 5-3. 전체 테스트 스위트 실행 (background)

```bash
# run_in_background: true
npm test
```

---

## Step 6: Lint 및 빌드 확인 (병렬, background)

```bash
# run_in_background: true
npm run lint
```

```bash
# run_in_background: true
npm run build
```

---

## Step 7: 커밋 및 푸시

사용자에게 커밋 요청을 확인한 뒤 진행한다.

```bash
# 변경 파일 확인
git status
git diff

# 커밋 (사용자 승인 후)
git add <수정된 파일들>
git commit -m "$(cat <<'EOF'
fix: 인증 미들웨어 에러 핸들링 개선

- PR #42 리뷰 피드백 반영
- 에러 타입별 분기 처리 및 적절한 HTTP 상태 코드 반환

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"

# 푸시
git push
```

---

## Step 8: 수정 결과 리뷰

### 8-1. 변경 사항 diff 확인

```bash
gh pr diff 42
```

### 8-2. 자체 코드 리뷰 수행

수정된 코드를 다시 읽으며 다음을 점검한다.

- 리뷰 코멘트에서 요청한 사항이 모두 반영되었는지
- 에러 핸들링이 빠진 경로(edge case)가 없는지
- 보안상 민감한 정보가 에러 응답에 노출되지 않는지
- 기존 동작에 대한 regression이 없는지
- 테스트 커버리지가 충분한지 (80% 이상)

### 8-3. PR에 리뷰 결과 코멘트 남기기

```bash
gh pr comment 42 --body "리뷰 피드백 반영 완료. 변경 사항:
- <구체적 수정 내용 요약>
- 관련 테스트 추가/수정 완료
다시 확인 부탁드립니다."
```

---

## 핵심 원칙

| 원칙 | 적용 |
|------|------|
| 병렬 처리 | Step 1(PR 정보 수집), Step 3(코드 분석), Step 6(lint/build)은 병렬 실행 |
| Background 실행 | 전체 테스트, lint, build는 background로 실행하여 대기 시간 최소화 |
| TDD | 에러 핸들링 수정 전에 실패 테스트 확인, 수정 후 통과 확인 |
| 범위 준수 | 리뷰 코멘트가 요청한 범위만 수정, 불필요한 리팩토링 금지 |
| 커밋 시점 | 사용자 명시적 요청 후에만 커밋 생성 |
