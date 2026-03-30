# Cross-Cutting Protocols (Detail)

## 목차
- [Session Isolation Protocol](#session-isolation-protocol)
- [Composable CLI Script Toolkit](#composable-cli-script-toolkit)
- [Docs-First Protocol](#docs-first-protocol)
- [Context Window Management](#context-window-management)

## Clean Working Tree Check

Startup에서 worktree 생성 전에 working tree의 clean 여부를 검증한다:

```bash
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "[Working Tree] 미커밋 변경사항이 있습니다."
fi
```

dirty 상태 감지 시: ship 모드에서는 경고만 출력하고 계속 진행. guided/interactive 모드에서는 AskUserQuestion으로 확인.

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


### Cross-Session State

세션 간 구조화된 상태를 `~/.claude/projects/{slug}/state/`에 jsonl로 관리한다:

- `reviews.jsonl`: 리뷰 결과 (severity, file, finding, resolution, timestamp, expires_at)
- `decisions.jsonl`: 아키텍처 결정 (decision, rationale, rejected_alternatives, timestamp)
- `test-insights.jsonl`: 반복 실패 패턴, 환경 의존 테스트 목록
- `gotchas.jsonl` — 프로젝트에서 Claude가 반복적으로 잘못하는 패턴. **유효기간 없음** (영구 축적). 카테고리: build, convention, test, api, infra.

**유효기간**: 7일. Startup에서 유효 항목만 로딩하여 이전 세션의 이슈를 사전 인지한다.
**기록 시점**: Step 완료 시 해당 Step의 판단/결과를 append한다.
**포맷**: 한 줄에 하나의 JSON 객체. jq로 필터링 가능.
## Phase-End Auto-Retrospective

Step 20(마지막 단계)에 도달하지 못하더라도 사용자 피드백이 증발되지 않도록, 각 Phase 경계에서 경량 회고를 자동 실행한다.

**트리거 시점:**

| 시점 | 조건 |
|------|------|
| Phase A 완료 후 | Calibration Checklist 통과 직후 |
| 각 Unit 완료 후 | Step 8 (SMALL) 또는 Step 17 (STANDARD+) 완료 시 |
| Integration 완료 후 | integration-result.md 저장 직후 |

**실행 절차:**

1. `user-feedback-log.md`에서 해당 Phase 구간의 기록을 스캔한다
2. 패턴 탐지:
   - **반복 교정** (2건+ 동일 유형 수정 요청) → `AUTO_CAPTURE`
   - **워크플로 마찰** (특정 단계에서 불만/지연) → `AUTO_CAPTURE`
   - 패턴 없음 → `SKIP`
3. `AUTO_CAPTURE` 시:
   - `simon-bot-boost-capture`의 동작을 따라 백그라운드 Agent를 spawn하여 인사이트 리포트를 `~/.claude/boost/insights/`에 저장한다
   - 포그라운드에서는 1줄 통보만: `[Retro] {Phase} 피드백 {N}건 감지 → 개선 인사이트 캡처 중`
   - 사용자 확인 없이 자동 실행 (boost-capture의 스냅샷 확인 단계를 생략)
4. `SKIP` 시: `[Retro] {Phase} — 개선 패턴 없음` 1줄만 출력하고 즉시 다음 Phase로 진행
5. retrospective.md에 체크포인트 append:
   ```
   ## Phase-End Checkpoint: {Phase}
   - **시점**: {timestamp}
   - **피드백 건수**: {N}건
   - **감지 패턴**: {패턴 요약 또는 "없음"}
   - **캡처**: {boost insight 파일명 또는 "N/A"}
   ```

**Step 20과의 관계**: Phase-end 회고가 이미 캡처한 패턴은 Step 20에서 중복 처리하지 않는다. Step 20은 전체 워크플로를 관통하는 종합 패턴(Phase 간 교차 패턴)에만 집중한다. 컨텍스트 부족으로 Step 20이 실행되지 않아도, 핵심 인사이트는 Phase-end에서 이미 캡처된 상태이므로 안전하다.

**오버헤드**: user-feedback-log.md 스캔 + 1줄 출력 = 최소 컨텍스트 소비. boost-capture는 백그라운드이므로 포그라운드 작업에 영향 없음.

## Structured Step Result Protocol

Step 완료 시 workflow-state.json에 해당 Step의 결과를 구조화하여 기록한다. compaction 후에도 오케스트레이터가 "어느 Step까지 어떤 결과로 완료했는지"를 즉시 파악할 수 있도록 SSoT 역할을 한다.

```json
"step_results": {
  "6": {"status": "DONE", "verdict": "PASS", "artifacts": ["unit-auth/alignment-verdict.md"]},
  "7": {"status": "DONE", "verdict": "PASS_WITH_FIXES", "fixes_applied": 3, "artifacts": ["unit-auth/review-findings.md"]}
}
```

**status 값**: `DONE` | `PARTIAL` | `BLOCKED` | `ERROR`
- `DONE`: 정상 완료
- `PARTIAL`: 부분 완료 (maxTurns 소진, 컨텍스트 부족 등) — 미완료 항목 명시
- `BLOCKED`: 사용자 판단 필요 (NEEDS-HUMAN-REVIEW 항목 존재)
- `ERROR`: 에러 발생 — error-resilience.md의 분류와 연동

Step 전환 시 오케스트레이터는 `step_results[이전 Step].status`를 확인하여 라우팅을 결정한다. `PARTIAL`이면 재시도 여부를, `ERROR`이면 에러 복구 전략을 판단한다.

## Context Window Management

자동 압축(AUTOCOMPACT)은 비활성화되어 있다. compaction은 항상 수동으로 실행하며, 보존 대상을 `/compact <프롬프트>`로 명시적으로 지정한다. 이를 통해 256K 고정확도 영역에 핵심 정보를 배치할 수 있다. 압축이 발생해도 `.claude/memory/`에 상태가 저장되어 있으므로 작업을 계속 진행한다.

### Compaction Preservation Priority

compaction 전 memory 파일 저장과 compaction 후 재로딩 시, 다음 우선순위를 적용한다. Opus 4.6은 256K 토큰 이내에서 ~90% 정확도를 보이고 이후 ~70%로 하락하므로, P0-P1이 256K 이내에 위치하도록 재로딩 순서를 관리한다.

| 우선순위 | 분류 | 내용 | 저장 위치 | 근거 |
|---------|------|------|----------|------|
| **P0 — SSoT** | 현재 위치 + 규칙 | workflow-state.json (현재 Step, step_results, active_hooks, done_when_checks), verify-commands.md, forbidden-rules 활성 상태 | workflow-state.json | compaction 후 "지금 뭘 해야 하는지"를 복원하는 최소 정보. 이것 없이는 작업 재개 불가 |
| **P1 — 판단 기준** | 게이트 판정에 필요한 기준 | plan-summary.md의 Acceptance Criteria, expert-plan-concerns.md의 CRITICAL/HIGH 항목, Decision Journal의 기각된 대안 + 무효화 조건 | CONTEXT.md에 발췌 포함 | Step 6/7/17 게이트 판정의 입력. 이것이 소실되면 게이트가 기준 없이 판정하게 됨 |
| **P2 — 맥락** | 현재 Unit의 구현 맥락 | 현재 Unit의 runbook.md, inline-issues.md, test-case-summary.md, 최근 실패 로그 (failure-log 최근 3건) | unit-{name}/ 디렉토리 | 구현/디버깅 연속성. 파일에서 재로딩 가능하므로 compaction summary에 포함 불필수 |
| **P3 — 이력** | 완료된 Step의 결과 | 이전 Unit의 review-findings, alignment-verdict, 빌드 로그, grep 결과 | step_results 요약으로 충분 | compaction 시 가장 먼저 요약/제거 대상. 필요 시 파일에서 재로딩 |

### 선제적 Compaction 전략

자동 압축(AUTOCOMPACT)은 비활성화되어 있다. compaction은 항상 **수동으로 `/compact <보존 프롬프트>`를 실행**하여, 무엇을 보존할지 명시적으로 지정한다.

Step 전환 시점에서 다음을 수행한다 (**Instruction** — 상태 저장은 필수):

1. `/context`로 활용률을 확인한다
2. **45% 이상이면** 다음 절차를 따른다:
   - P0 확인: workflow-state.json이 현재 Step과 done_when_checks를 정확히 반영하는지 확인
   - P1 확인: CONTEXT.md의 "주의사항" 섹션에 expert-plan-concerns.md의 CRITICAL/HIGH 항목이 포함되어 있는지 확인. 누락 시 추가
   - P1 확인: Decision Journal에서 기각된 대안의 무효화 조건이 기록되어 있는지 확인
   - **보존 프롬프트 생성**: 현재 Phase/Step에 맞는 보존 항목을 작성하여 `/compact <프롬프트>` 실행 (아래 Interactive Compaction Protocol 참조)
3. **70% 이상 (Hard Compaction)**: 45%에서 compaction했는데도 다시 70%에 도달하면, 현재 Step 완료 후 세션 분할을 검토한다
4. 이전 Step의 도구 결과(긴 빌드 출력, 대량 grep 결과 등)는 compaction 시 자연스럽게 요약되어 컨텍스트 효율이 향상된다

### Interactive Compaction Protocol

compaction 실행 시 보존 대상을 사용자와 협의하여 `/compact <프롬프트>`에 전달한다. 모델의 재량이 아닌 **사용자가 보존 대상을 통제**한다.

**절차:**
1. Phase/Step 상태에 기반하여 기본 보존 프롬프트를 **제안**한다
2. 사용자에게 "추가로 남기고 싶은 정보가 있나요?"를 확인한다
3. 사용자 추가 항목을 반영하여 최종 프롬프트를 작성하고 `/compact <최종 프롬프트>` 실행

**Phase별 기본 보존 항목:**

| Phase | 기본 보존 항목 |
|-------|---------------|
| A (Planning) | 현재 Step, 사용자 요구사항, 인터뷰 답변, expert findings CRITICAL/HIGH, 기각된 대안과 이유 |
| B-E (Implementation) | 현재 Step/Unit, plan-summary AC, TDD 진행 상태, inline-issues, 최근 빌드/테스트 결과, gotchas |
| Verification (6/7/17) | 현재 Step, done_when_checks 미완료 항목, findings 목록, verify-commands |
| Integration | 현재 Step, 모든 Unit 완료 상태, 충돌 해결 이력, integration test 결과 |

**ship/guided 모드 특칙**: ship 모드에서는 사용자 확인 없이 Phase별 기본 보존 항목으로 자동 실행한다. guided/interactive 모드에서만 사용자 확인을 거친다.

이를 통해 "attention budget"을 효율적으로 사용하고, 후반 Step에서의 성능 저하를 방지한다.

**45% 임계값 이후에도 현재 Step을 완료한 후 분할 여부를 판단한다. 현재 Step 도중에 조기 종료하지 않는다.**

### Context-Aware Recovery

컨텍스트 사용률이 높은 상태에서 에러가 발생하면, 에러 복구 자체가 추가 컨텍스트를 소비하여 악순환에 빠질 수 있다. 이를 방지하기 위해 임계값별 복구 전략을 적용한다:

**85% (Tier 1 — Context Diet)**: 에러 복구를 시작하기 전에 다음을 먼저 수행한다:
1. `{SESSION_DIR}/memory/recovery-checkpoint.md`에 현재 상태를 저장한다 (현재 Step, 에러 내용, 진행 중이던 작업, 남은 작업 목록)
2. **Reference Unloading**: 이미 완료된 Phase의 reference 파일 내용을 적극적으로 해제한다 (Reference Loading Policy의 Phase별 선택적 로딩과 연동)
3. `/compact`를 실행하여 컨텍스트를 확보한 후 에러 복구를 진행한다
4. 복구 완료 후 recovery-checkpoint.md를 참조하여 작업을 재개한다

**88% (Tier 2 — Capability Reduction)**: 컨텍스트 압축만으로 충분하지 않은 경우 검증 파이프라인을 경량화한다:
1. Agent Team 사용을 중단하고 Fallback 모드(subagent 개별 spawn + 오케스트레이터 종합)로 전환한다 — Agent Team의 실시간 토론(SendMessage)은 컨텍스트를 많이 소비하므로 Fallback이 더 효율적이다
2. Multi-Agent Saturation Guard의 축소 조건을 강제 적용한다 (SKILL.md 참조)
3. `[Degradation] 88% — Agent Team → Fallback 모드 전환, multi-agent 축소` 1줄 통보
4. workflow-state.json에 `"degradation_level": "lean"` 기록 — Step 17과 Step 20이 축소된 검증을 인지하고 보완 검증 필요 여부를 판단한다

**90% (Tier 3 — Progress Summary + Session Split)**: 세션 분할을 트리거한다.
1. `{SESSION_DIR}/memory/progress-summary.md`를 자동 생성한다:
   - 완료 Steps 목록 + 각 Step의 status/verdict (workflow-state.json step_results에서 추출)
   - 현재 Step + 진행률
   - 핵심 산출물 파일 목록
   - 미완료 작업 + 진행 중 에러
   - 복원 우선순위
2. 세션 분할 경계에 따라 새 세션에서 재개한다
3. 새 세션 시작 시 **progress-summary.md를 최우선 로딩**하여 전체 memory 재읽기 없이 핵심 맥락을 빠르게 복원한다

### Compaction 후 상태 검증

자동 또는 수동 compaction 후 다음 파일을 **무조건 재로딩**한다 ("기억하고 있는지 판단"하는 비용보다 "1개 파일 다시 읽는" 비용이 더 예측 가능하고 안전하기 때문이다). **순서를 준수하여 P0-P1이 256K 이내에 배치되도록 한다**:

1. `{SESSION_DIR}/memory/workflow-state.json` — 현재 Step 번호와 상태 복원 (P0 SSoT)
2. CONTEXT.md — 추가 맥락 복원 (P1 — AC, expert concerns 발췌 포함)
3. 현재 Phase의 Tier 1 레퍼런스 파일 — 핵심 규칙 복원 (Reference Loading Policy 참조)
4. 현재 Step의 Tier 2 레퍼런스 파일 — Done-When Checks 복원
5. `jq '.hooks.PreToolUse' ~/.claude/settings.json` — forbidden-guard.sh 등록 확인 (P0 결정론적 검증)
6. expert-plan-concerns.md의 CRITICAL/HIGH 항목 (P1 — CONTEXT.md 발췌와 원본 대조)

Tier 3 파일은 재로딩하지 않음 (on-demand 트리거로 필요 시 자연스럽게 로딩).

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

### Step 17 및 Integration에서의 Evidence 의무

Step 17(Production Readiness)과 Integration 단계에서 `done_when_checks`의 `evidence` 필드를 반드시 채워야 한다. 컨텍스트 부족을 이유로 검증을 생략하거나 통과로 간주하는 것은 명시적으로 금지한다.

**금지 출력 예시** (이와 유사한 표현 모두 금지):
- "컨텍스트가 부족하므로 나머지는 통과로 간주합니다"
- "이전 단계에서 확인했으므로 PASS입니다"
- "시간 관계상 나머지 항목은 생략합니다"

evidence 필드가 비어 있거나 위와 같은 면책 표현이 포함된 경우 해당 체크는 `verified: false`로 유지되며, Step 17의 게이트를 통과할 수 없다. 컨텍스트가 부족하면 세션을 분할하여 새 세션에서 검증을 완료한다.
