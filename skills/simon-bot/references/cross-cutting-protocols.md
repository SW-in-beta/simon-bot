# Cross-Cutting Protocols (Detail)

## 목차
- [Session Isolation Protocol](#session-isolation-protocol)
- [Composable CLI Script Toolkit](#composable-cli-script-toolkit)
- [Docs-First Protocol](#docs-first-protocol)
- [Context Window Management](#context-window-management)

## Session Isolation Protocol

동시에 여러 세션이 같은 레포에서 작업할 때 `.claude/` 하위 런타임 파일의 충돌을 방지한다. 세션별 런타임 데이터를 홈 디렉토리에 격리 저장한다.

**Startup에서 SESSION_DIR 결정** (Startup Step 3 브랜치명 생성 직후):
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
SESSION_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions/${branch_name}"
mkdir -p "${SESSION_DIR}/memory" "${SESSION_DIR}/reports"
```

**경로 매핑** — 이 스킬과 모든 레퍼런스 파일에서 아래 런타임 경로는 `{SESSION_DIR}` 기준으로 해석한다:

| 스킬 내 표기 | 실제 저장 위치 |
|-------------|--------------|
| `.claude/memory/*` | `{SESSION_DIR}/memory/*` |
| `.claude/reports/*` | `{SESSION_DIR}/reports/*` |

프로젝트의 `.claude/workflow/` (config, scripts)는 공유 설정이므로 프로젝트 디렉토리에서 그대로 읽는다. `.claude/boost/`는 이미 홈 디렉토리 기반이므로 매핑 불필요.

**PM 파견 시 결과 경로**: simon-bot-pm이 이 스킬을 호출할 때 `PM_RESULT_PATH`를 전달하면, 작업 결과(result.md)를 해당 경로에 기록한다.

## Composable CLI Script Toolkit

`workflow/scripts/`의 스크립트는 Composable CLI 원칙을 따른다:

1. **구조화된 출력**: `--json` 플래그 지원 시 JSON 출력을 생성하여 jq 파이프 가능
2. **파이프 호환**: 다른 스크립트의 출력을 stdin으로 받아 처리할 수 있는 구조
3. **자기 문서화**: 각 스크립트가 `--help`를 지원하여 Claude Code가 자가 학습 가능
4. **컨텍스트 전처리**: diff 요약, AC 추출, 에러 분류 등 LLM에 전달할 데이터를 사전 압축

유닉스 파이프라인 철학 — 작은 도구들을 조합하여 복잡한 결과를 만드는 composability — 을 따른다. LLM에 원본 데이터를 통째로 전달하지 않고, CLI로 핵심만 추출하여 전달함으로써 컨텍스트 효율을 극대화한다.

## Docs-First Protocol

라이브러리·DB·프레임워크·외부 서비스 등을 사용할 때, 학습 데이터 기반 기억에 의존하지 않고 공식 문서를 먼저 조회한다. LLM의 학습 데이터는 버전·API 시그니처·설정 방법에 대해 오래되었거나 부정확할 수 있기 때문이다.

For detailed protocol (적용 기준, 도구 우선순위, 조회 불가 시 대응), read [docs-first-protocol.md](docs-first-protocol.md).

## Context Window Management

컨텍스트 윈도우가 자동 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다. 압축이 발생해도 `.claude/memory/`에 상태가 저장되어 있으므로 작업을 계속 진행한다.

### 선제적 Compaction 전략

자동 압축에만 의존하면 이미 회상 정확도가 저하된(context rot) 상태에서 압축이 실행될 수 있다.
Step 전환 시점에서 다음을 수행한다 (**Instruction** — 상태 저장은 필수):

1. `/context`로 활용률을 확인한다
2. 70% 이상이면 핵심 상태(현재 Step, 활성 규칙, Done-When Checks)를 memory 파일에 저장한 후 `/compact`를 실행한다
3. 이전 Step의 도구 결과(긴 빌드 출력, 대량 grep 결과 등)는 compaction 시 자연스럽게 요약되어 컨텍스트 효율이 향상된다

이를 통해 "attention budget"을 효율적으로 사용하고, 후반 Step에서의 성능 저하를 방지한다.

### Compaction 후 상태 검증

자동 또는 수동 compaction 후 다음 파일을 **무조건 재로딩**한다 ("기억하고 있는지 판단"하는 비용보다 "1개 파일 다시 읽는" 비용이 더 예측 가능하고 안전하기 때문이다):

1. `{SESSION_DIR}/memory/workflow-state.json` — 현재 Step 번호와 상태 복원 (SSoT)
2. CONTEXT.md — 추가 맥락 복원
3. 현재 Step의 레퍼런스 파일 — Done-When Checks 복원
4. `jq '.hooks.PreToolUse' ~/.claude/settings.json` — forbidden-guard.sh 등록 확인 (결정론적 검증)

"유지되지 않는 항목이 있으면"이라는 조건부 재로딩이 아닌, compaction 감지 시 무조건 재로딩으로 안전을 보장한다.

### 새 세션 시작 프로토콜

새 세션에서 작업을 재개할 때 다음 순서를 따른다:
1. `pwd`로 현재 디렉토리 확인
2. `CONTEXT.md` + `.claude/memory/*.md` 읽기
3. `git log --oneline -10`으로 최근 변경 확인
4. 마지막 완료 Step 이후부터 재개

### 세션 분할 경계

컨텍스트 부족 시 아래 경계에서 세션을 분할한다:

| 경계 | 시점 | 저장 상태 |
|------|------|----------|
| 1 | Phase A 완료 후 | plan-summary, code-design-analysis, expert-plan-concerns, requirements |
| 2 | Integration 완료 후 | integration-result, unit-*/implementation, unit-*/review-findings |
| 3 | Step 18 완료 후 | review-sequence, report |

복원: `.claude/memory/` + `CONTEXT.md` 읽기 → 다음 Step 이어서 실행
