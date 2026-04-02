---
name: simon-bot-ci-fix
description: "CI 실패 자동 수정 — PR의 CI 체크를 모니터링하고, 실패 시 로그 분석→에러 분류→코드 수정→푸시→재확인 사이클을 최대 5회 반복합니다. Use when: (1) CI 실패를 수정하고 싶을 때 ('CI 고쳐줘', 'CI 실패 수정해줘', 'build 실패', 'test 실패'), (2) simon-bot-review에서 CI Watch 단계로 자동 호출, (3) PR checks가 실패해서 수정이 필요할 때 ('checks 실패', 'lint 에러'). CI 실패와 관련된 모든 상황에서 이 스킬을 사용하세요."
compatibility:
  tools: [Agent]
  skills: [git-commit]
model: sonnet
---

# simon-bot-ci-fix

PR의 CI 체크를 모니터링하고, 실패 시 자동으로 수정하는 스킬. 에러 유형별 전문 복구 전략으로 최대 5회 사이클을 반복하여 모든 체크가 통과할 때까지 수정한다.

## Mode Detection

1. **입력 파라미터 확인**: PR 번호, 브랜치명, SESSION_DIR이 전달되었는지 확인
2. **DELEGATED 모드**: PR 번호가 전달됨 (simon-bot-review 또는 다른 스킬에서 호출)
3. **STANDALONE 모드**: PR 번호 미전달 → 자동 감지
   ```bash
   gh pr view --json number,url --jq '{number: .number, url: .url}'
   ```
   PR 없으면 사용자에게 안내: "현재 브랜치에 PR이 없습니다. PR 번호를 알려주세요."

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules 공통 프로토콜 포함.

### STANDALONE SESSION_DIR 설정

STANDALONE 모드에서는 preamble의 Session Isolation Protocol에 따라 SESSION_DIR을 직접 결정한다.

## Workflow

```
[Mode Detection] → PR 번호 확보
     ↓
Step 1: CI 상태 확인 ←──────────────┐
     ↓                               │
  모두 통과? ── Yes → 결과 보고       │
     │                               │
    No                               │
     ↓                               │
Step 2: 실패 로그 수집                │
     ↓                               │
Step 3: 에러 분류                     │
     ↓                               │
  ENV만? ── Yes → 결과 보고 (수정불가) │
     │                               │
    No                               │
     ↓                               │
Step 4: 진단 + 수정                   │
     ↓                               │
  [GATE] 구조적 변경? → 사용자 확인   │
     ↓                               │
Step 5: 커밋 + 푸시 ─── cycle < 5 ───┘
     │
  cycle >= 5
     ↓
결과 보고 (미해결 실패 포함)
```

## Step 1: CI 상태 확인

CI 체크 상태를 확인한다. push 직후에는 CI가 아직 시작되지 않았을 수 있으므로 대기 로직을 포함한다.

```bash
CHECKS=$(gh pr checks {pr_number} 2>&1)
```

**체크 상태 해석:**
- 모든 체크 pass → **SUCCESS** → 결과 보고
- 실패한 체크 존재 → Step 2
- 체크가 pending → 30초 대기 후 재확인 (최대 10회, 5분)
- 체크가 하나도 등록되지 않음 → 60초 대기 후 재확인 (최대 5회, CI 트리거 대기)

**진행 상황 기록:**
```bash
echo "## Cycle {N} - $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> {SESSION_DIR}/memory/ci-fix-progress.md
echo "Status: CHECKING" >> {SESSION_DIR}/memory/ci-fix-progress.md
```

## Step 2: 실패 로그 수집

실패한 각 체크의 상세 로그를 수집한다.

```bash
# 실패한 체크의 run ID 수집
gh pr checks {pr_number} --json name,state,link \
  --jq '[.[] | select(.state == "FAILURE")]'
```

각 실패한 run에 대해:
```bash
# URL에서 run ID 추출
RUN_ID=$(echo "{run_url}" | grep -oE '[0-9]+$')

# 실패 로그 가져오기 (마지막 200줄)
gh run view {run_id} --log-failed 2>&1 | tail -200
```

로그가 200줄을 초과하면 에러 패턴 중심으로 필터링한다:
- 컴파일 에러: `error:`, `Error:`, `FAIL` 패턴
- 테스트 실패: `FAILED`, `AssertionError`, `Expected ... got` 패턴
- lint: `warning:`, `error:` + 파일:줄 번호

수집한 로그를 `{SESSION_DIR}/memory/ci-failure-logs.md`에 저장한다.

## Step 3: 에러 분류

수집된 로그를 분석하여 에러 유형을 분류한다. 키워드 기반으로 빠르게 1차 분류한 후, 애매한 경우 로그 내용을 정밀 분석한다.

| 유형 | 키워드 패턴 | 특성 |
|------|------------|------|
| **BUILD** | `compilation failed`, `syntax error`, `cannot find module`, `import error`, `undefined reference` | 코드 빌드 자체 실패 |
| **TEST** | `FAIL`, `AssertionError`, `expected`, `test.*failed`, `coverage below` | 테스트 실패 또는 커버리지 미달 |
| **LINT** | `lint`, `eslint`, `flake8`, `golangci-lint`, `formatting`, `gofmt` | 코드 스타일/포맷 위반 |
| **TYPE** | `type error`, `typecheck`, `mypy`, `tsc`, `type mismatch` | 타입 체크 실패 |
| **ENV** | `timeout`, `connection refused`, `permission denied`, `rate limit`, `out of memory`, `docker`, `service unavailable` | 인프라/환경 문제 |

**분류 결과 기록:**
```markdown
## 에러 분류 (Cycle {N})
- **체크명**: {check_name}
- **유형**: BUILD / TEST / LINT / TYPE / ENV
- **핵심 에러**: {에러 메시지 1줄 요약}
- **관련 파일**: {file:line} (파악 가능한 경우)
```

**ENV 유형 처리**: ENV로 분류된 실패는 코드 수정으로 해결할 수 없다. 수정 대상에서 제외하고 결과 보고에 "ENV 실패 (수정 불가)"로 기록한다. 모든 실패가 ENV면 결과 보고로 직행한다.

## Step 4: 진단 + 수정

에러 유형별로 진단하고 수정한다. 여러 유형이 동시에 실패한 경우 **BUILD → TYPE → TEST → LINT** 순서로 처리한다 — 빌드가 안 되면 다운스트림 체크도 실패하므로, 상류 에러부터 해결해야 의미 있는 진전이 가능하다.

### BUILD 수정
1. 에러 메시지에서 파일:줄 번호 추출
2. 해당 파일 Read → 에러 원인 파악
3. 일반적 원인과 수정 방향:
   - **import 누락**: 필요한 패키지/모듈 import 추가
   - **삭제된 참조**: 삭제된 함수/변수를 참조하는 코드 수정
   - **인터페이스 불일치**: 함수 시그니처 변경에 따른 호출부 수정
   - **문법 오류**: 오타, 괄호 불일치 등
4. 수정 적용

### TEST 수정
1. 실패한 테스트 파일과 에러 메시지 파악
2. 테스트 코드와 실제 코드 모두 Read
3. **핵심 판단** — 테스트가 올바른지, 구현이 잘못된 건지 구분한다:
   - 테스트의 기대값이 의도적으로 변경된 로직과 일치하지 않는 경우 → 테스트 수정
   - 구현 로직에 실제 버그가 있는 경우 → 구현 수정
   - **판단 불가 시**: 두 가지 해석을 모두 기록하고 사용자 확인 요청 ([GATE] 구조적 변경)
4. 수정 적용

### LINT 수정
1. lint 도구가 보고한 파일:줄 번호와 규칙 확인
2. 프로젝트의 자동 수정 명령 시도:
   - `.claude/workflow/config.yaml`에 `lint-fix` 명령이 정의되어 있는지 확인
   - 없으면 프로젝트 언어에 맞는 기본 명령 시도:
     - Go: `gofmt -w .`, `goimports -w .`
     - Python: `black .`, `isort .`
     - JS/TS: `npx eslint --fix .`
3. 자동 수정으로 해결되지 않은 항목은 수동 수정

### TYPE 수정
1. 타입 에러 메시지에서 파일:줄, 기대 타입, 실제 타입 추출
2. 해당 파일 Read → 타입 불일치 원인 파악
3. 수정 적용 (타입 선언 수정, 타입 변환 추가, 제네릭 파라미터 조정 등)

### [GATE] 구조적 변경 감지

아래 중 하나에 해당하면 구조적 변경으로 판단하고 **사용자 확인**을 받는다:
- 테스트 로직 변경 (assert 조건 변경, 테스트 삭제)
- 새로운 의존성 추가 (go.mod, package.json, requirements.txt 변경)
- API 시그니처 변경
- 데이터 모델/스키마 변경

**STANDALONE 모드**: 사용자에게 직접 변경 내용과 이유를 설명하고 승인 요청.
**DELEGATED 모드**: `{SESSION_DIR}/memory/ci-fix-status.md`에 `[USER_CONFIRM_NEEDED]` 태그 + 변경 내용을 기록한다. 호출자(simon-bot-review)가 사용자에게 전달.

## Step 5: 커밋 + 푸시

수정한 파일들을 커밋하고 푸시한다.

1. `git diff --name-only`로 수정된 파일 확인
2. 커밋 생성:
   ```bash
   git add {modified_files}
   git commit -m "fix(ci): {수정 내용 요약}"
   ```
3. 푸시:
   ```bash
   git push
   ```
4. PR에 수정 내용 코멘트:
   ```bash
   gh pr comment {pr_number} --body "**CI Fix (Cycle {N})**
   - **유형**: {BUILD/TEST/LINT/TYPE}
   - **수정**: {변경 요약}
   - **수정 파일**: {file1}, {file2}"
   ```
5. 사이클 카운터 확인:
   - cycle < 5 → Step 1로 복귀 (CI 재확인)
   - cycle >= 5 → 결과 보고

## 결과 보고

CI 수정 작업의 최종 결과를 기록한다.

**결과 파일**: `{SESSION_DIR}/memory/ci-watch-result.md`

```markdown
## CI Fix Result
- **총 사이클**: {N}회
- **최종 상태**: ALL_PASS / PARTIAL_FIX / ENV_ONLY / MAX_CYCLES_REACHED
- **수정된 체크**: {check1}, {check2}
- **미해결 체크**: {check3 (ENV)}, ...
- **수정 커밋**: {commit_hash1}, {commit_hash2}

### 사이클별 기록
| Cycle | 실패 체크 | 에러 유형 | 수정 내용 | 결과 |
|-------|----------|-----------|----------|------|
| 1 | build-go | BUILD | import 누락 수정 | FIXED |
| 2 | test-unit | TEST | assertion 수정 | FIXED |
```

**STANDALONE 모드**: 결과를 사용자에게 직접 출력한다.
**DELEGATED 모드**: 결과 파일만 저장하고 종료. 호출자가 결과를 활용한다.

## Progress Signal (DELEGATED 모드)

호출자가 CI 수정 진행 상황을 파악할 수 있도록 상태를 파일로 기록한다:

**파일**: `{SESSION_DIR}/memory/ci-fix-status.md`

```markdown
status: IN_PROGRESS | DONE | USER_CONFIRM_NEEDED
cycle: {N}
last_update: {ISO timestamp}
fixes_applied: {N}
remaining_failures: {N}
```

## simon-bot-review 연동

simon-bot-review는 CI Watch 단계에서 이 스킬을 background agent로 위임한다. Background agent는 Skill 도구를 직접 사용할 수 없으므로, 이 SKILL.md를 Read한 뒤 지시를 따르는 방식으로 실행한다.

**simon-bot-review에서의 호출 패턴:**
```
Agent(run_in_background=true):
  "다음 파일을 Read하고 그 지시를 따라 CI 수정을 실행하라:
   ~/.claude/skills/simon-bot-ci-fix/SKILL.md

   컨텍스트:
   - PR 번호: {pr_number}
   - 브랜치: {branch}
   - SESSION_DIR: {session_dir}
   - 모드: DELEGATED"
```

이 패턴을 사용하면:
- CI 수정 로직이 이 스킬 파일 한 곳에만 존재한다 (단일 진실의 원천)
- Background agent가 fresh context에서 실행되므로 컨텍스트 소진 문제가 없다
- STANDALONE/DELEGATED 양쪽 경로에서 동일한 수정 품질을 보장한다
