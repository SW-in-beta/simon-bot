# Improvement Proposals: simon-bot 계열 스킬 개선안

분석일: 2026-03-13
초점 영역: 프롬프트 엔지니어링 + 컨텍스트 관리

---

## P-001: /compact 보존 지시 추가 (Context Preservation Directive)

- **심각도**: CRITICAL
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: 각 스킬의 SKILL.md (Context Window Management 섹션)
- **카테고리**: 컨텍스트 관리

### 현재 상태

simon-bot SKILL.md의 "Context Window Management" 섹션 (줄 356-378):
```
컨텍스트 윈도우가 자동 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다.
압축이 발생해도 `.claude/memory/`에 상태가 저장되어 있으므로 작업을 계속 진행한다.
```

### 문제 시나리오

자동 압축 발생 시 대화 히스토리가 요약되면서:
- 현재 실행 중인 Step 번호와 Phase가 소실
- decision-journal에 기록한 기각 사유(Anti-Oscillation Rule에 필요)가 대화에서 사라짐
- failure-log의 패턴(grind 전략 전환 판단에 필요)이 대화에서 사라짐
- Step 7 전문가 findings 중 해결 완료/미완료 구분이 소실

### 제안 내용

**Before** (simon-bot SKILL.md, Context Window Management):
```
컨텍스트 윈도우가 자동 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다.
```

**After**:
```
컨텍스트 윈도우가 자동 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다.

### Compact 보존 지시

자동 압축 시 아래 워크플로 상태가 보존되도록 프로젝트 CLAUDE.md에 다음 지시를 추가한다:

"When compacting, always preserve: current Phase and Step number, active plan-summary key decisions,
decision-journal entries (especially Rejected alternatives), failure-log error patterns and counts,
expert findings resolution status (RESOLVED/PENDING), and file paths of all modified files."

압축 후에는 반드시 다음 파일을 재로딩하여 워크플로 상태를 복원한다:
1. `{SESSION_DIR}/memory/decision-journal.md` — 기각 사유 확인 (Anti-Oscillation Rule)
2. `{SESSION_DIR}/memory/plan-summary.md` — 현재 계획 확인
3. `CONTEXT.md` — 진행 상태 확인

grind의 failure-log.md와 checkpoints.md도 동일하게 재로딩한다.
```

### 기대 효과

- 자동 압축 후 워크플로 상태 연속성 보장
- Anti-Oscillation Rule이 압축 후에도 작동
- 재시도 전략 전환 판단에 필요한 failure 패턴 보존

### 검증 방법

1. 긴 세션에서 자동 압축을 유발 (많은 파일 읽기/쓰기)
2. 압축 후 "현재 어느 Step인지 알려줘"로 상태 인식 확인
3. 압축 후 이전에 기각한 접근법을 제안하는지 확인 (Anti-Oscillation)

---

## P-002: 스킬 내 hooks frontmatter로 Auto-Verification 선언적 정의

- **심각도**: CRITICAL
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (frontmatter + Auto-Verification Hook 섹션)
- **카테고리**: 프롬프트 엔지니어링 / 결정론적 실행

### 현재 상태

simon-bot SKILL.md 줄 76-104에서 Auto-Verification Hook을 텍스트로 안내하며, ".claude/settings.json의 hooks.PostToolUse에 등록하면" 이라고 권장사항으로 기술:

```
**Hook 기반 강화 (권장사항 — 프로젝트 첫 실행 시 설정)**: `auto-verify.sh`를 `.claude/settings.json`의
`hooks.PostToolUse`에 등록하면, Edit/Write 후 셸 레벨에서 자동 실행되어...
```

### 문제 시나리오

- 스킬이 "권장사항"으로만 훅을 안내하므로, 프로젝트에 설정이 안 되어 있으면 Auto-Verification이 LLM 기억에만 의존
- 컨텍스트 압축 후 Auto-Verification 규칙이 소실될 수 있음
- 프로젝트마다 수동으로 settings.json을 설정해야 함

### 제안 내용

SKILL.md frontmatter에 hooks 필드를 추가하여 스킬 활성 시 자동으로 Auto-Verification이 작동하도록 선언:

**Before** (frontmatter):
```yaml
---
name: simon-bot
description: "19-step 딥 워크플로..."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
  skills: [simplify, git-commit]
---
```

**After** (frontmatter):
```yaml
---
name: simon-bot
description: "19-step 딥 워크플로..."
compatibility:
  tools: [Agent, AskUserQuestion, TeamCreate, SendMessage]
  skills: [simplify, git-commit]
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "bash -c 'FILE=\"$TOOL_INPUT_PATH\"; EXT=\"${FILE##*.}\"; case \"$EXT\" in md|json|yaml|yml|toml) exit 0 ;; esac; if [ -f .claude/workflow/scripts/auto-verify.sh ]; then .claude/workflow/scripts/auto-verify.sh; else exit 0; fi'"
---
```

본문의 Auto-Verification Hook 섹션도 업데이트:
```
### Auto-Verification Hook (P-001)

이 스킬의 frontmatter hooks에 의해 Edit/Write 후 자동으로 검증이 실행된다.
스킬이 활성화된 동안 결정론적으로 실행되므로, 컨텍스트 압축과 무관하게 100% 실행이 보장된다.

- **빌드+린트**: 항상 실행
- **테스트**: 변경된 파일과 관련된 테스트만 실행
- **실패 시**: Stop-and-Fix Gate 적용
- **적용 제외**: .md, .json, .yaml 등 비소스코드 (matcher에서 자동 필터)
```

### 기대 효과

- Auto-Verification이 결정론적으로 실행 (LLM 기억 의존 제거)
- 프로젝트별 settings.json 설정 불필요
- 스킬 활성 시에만 작동하므로 다른 작업에 간섭 없음

### 검증 방법

1. 스킬 로딩 후 소스 파일 편집 → auto-verify.sh 실행 여부 확인
2. .md 파일 편집 → auto-verify.sh 미실행 확인
3. auto-verify.sh 없는 프로젝트에서도 에러 없이 통과 확인

---

## P-003: !`command` 동적 컨텍스트 주입으로 Startup 최적화

- **심각도**: CRITICAL
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-review
- **대상 파일**: SKILL.md (Startup 섹션)
- **카테고리**: 컨텍스트 관리

### 현재 상태

simon-bot Startup (줄 196-220)에서 5개 단계를 순차 실행:
1. `.claude/workflow/` 존재 확인
2. config.yaml 읽기 + 메모리 파일 읽기
3. 브랜치명 자동 생성
3-B. SESSION_DIR 초기화
4. Handoff Manifest 처리
5. Pre-flight 환경 검증

각 단계가 LLM 턴을 소비하여 Startup에만 5-8턴 사용.

### 제안 내용

`!`command`` 전처리 구문을 활용하여 Startup에서 환경 정보를 0 LLM턴으로 수집:

```yaml
---
name: simon-bot
...
---

# simon-bot

## Environment Context (자동 주입)

- 현재 브랜치: !`git branch --show-current 2>/dev/null || echo "detached"`
- 프로젝트 루트: !`git rev-parse --show-toplevel 2>/dev/null || pwd`
- workflow 존재: !`test -d .claude/workflow && echo "EXISTS" || echo "MISSING"`
- config.yaml: !`cat .claude/workflow/config.yaml 2>/dev/null || echo "NOT FOUND"`
- 최근 커밋: !`git log --oneline -5 2>/dev/null || echo "no commits"`
- Handoff Manifest: !`cat .claude/memory/handoff-manifest.json 2>/dev/null || echo "NONE"`
```

이렇게 하면 스킬 로딩 시점에 환경 정보가 자동 삽입되어, LLM이 첫 턴부터 환경 상태를 파악한 상태로 시작함.

Startup 단계를 간소화:
```
## Startup

Environment Context가 자동 주입되었으므로, 아래만 순차 실행한다:

1. **workflow 존재 확인**: Environment Context의 `workflow 존재`가 "MISSING"이면 install.sh 실행
2. **retrospective.md 읽기**: !`cat`으로 주입된 config.yaml 외에 추가로 retrospective.md 읽기 (있으면)
3. **브랜치명 자동 생성 + SESSION_DIR 초기화**: (기존과 동일)
4. **Handoff Manifest 처리**: Environment Context에서 NONE이 아니면 처리
5. **Pre-flight 검증**: preflight.sh 실행 (있으면)
```

### 기대 효과

- Startup에서 3-5 LLM 턴 절약 (환경 정보 수집이 0턴)
- 스킬 로딩 즉시 환경 상태를 파악하여 빠른 판단 가능
- config.yaml 내용이 바로 보이므로 별도 Read 불필요

### 주의사항

- !`command` 출력이 스킬 콘텐츠에 포함되어 description 예산에 영향을 줄 수 있음 — 출력이 긴 명령은 지양
- 명령 실행 실패 시 fallback 출력 필수 (|| echo "...")

### 검증 방법

1. 스킬 트리거 시 Environment Context가 올바르게 주입되는지 확인
2. workflow 미설치 프로젝트에서 "MISSING"이 표시되는지 확인
3. Startup 턴 수를 이전과 비교 측정

---

## P-004: 커스텀 서브에이전트 정의 (.claude/agents/)

- **심각도**: HIGH
- **대상 스킬**: simon-bot (전문가 에이전트 패턴 전반)
- **대상 파일**: 새 파일 생성 (`~/.claude/agents/` 하위)
- **카테고리**: 프롬프트 엔지니어링

### 현재 상태

simon-bot이 전문가 에이전트를 호출할 때 매번 인라인 프롬프트로 역할을 정의:
- architect: 아키텍처 분석, 최소 변경 결정
- security-reviewer: 보안 리뷰
- executor: TDD 구현
- writer: 보고서 작성

각 호출마다 프롬프트를 재구성하므로:
- 일관성 부족 (같은 역할이 다른 표현으로 정의될 수 있음)
- 도구 범위가 텍스트 지시에 의존 (P-011)
- 세션 간 학습 불가

### 제안 내용

`~/.claude/agents/`에 재사용 가능한 에이전트 정의 파일 생성:

**파일 1: `~/.claude/agents/simon-architect.md`**
```yaml
---
name: simon-architect
description: 아키텍처 분석, 최소 변경 결정, 코드 구조 리뷰. simon-bot Phase A와 Step 17에서 사용.
tools: Read, Grep, Glob, Bash
model: inherit
memory: user
---

당신은 소프트웨어 아키텍트입니다. 코드 구조, 의존성 방향, 모듈 분리를 분석합니다.

분석 시:
1. 변경 범위를 최소화하는 접근법 우선
2. 기존 패턴과의 일관성 확인
3. YAGNI/KISS 원칙 적용
4. 구체적 파일 경로와 라인 번호 참조

코드를 수정하지 않습니다. 읽기 전용 분석만 수행합니다.
```

**파일 2: `~/.claude/agents/simon-security-reviewer.md`**
```yaml
---
name: simon-security-reviewer
description: 보안 취약점 분석, OWASP 기준 리뷰. simon-bot Step 7과 Step 17에서 사용.
tools: Read, Grep, Glob, Bash
model: inherit
memory: user
---

당신은 시니어 보안 엔지니어입니다.

리뷰 항목:
- Injection 취약점 (SQL, XSS, 커맨드 인젝션)
- 인증/인가 결함
- 코드 내 시크릿/크레덴셜
- 안전하지 않은 데이터 처리
- 입력 검증

각 발견에 구체적 라인 참조와 수정 제안을 포함합니다.
심각도 분류: CRITICAL / HIGH / MEDIUM / LOW
```

**파일 3: `~/.claude/agents/simon-executor.md`**
```yaml
---
name: simon-executor
description: TDD 기반 코드 구현. simon-bot Step 5에서 사용.
tools: Read, Write, Edit, Bash, Grep, Glob
model: inherit
---

당신은 TDD 전문 개발자입니다.

구현 원칙:
1. RED: 실패하는 테스트 먼저 작성 → 실패 확인
2. GREEN: 테스트를 통과하는 최소 코드 작성
3. REFACTOR: 중복 제거, 네이밍 개선 (테스트 통과 유지)

code-design-analysis.md의 컨벤션을 준수합니다.
테스트를 속이기 위한 하드코딩을 하지 않습니다.
```

### simon-bot SKILL.md 변경

에이전트 호출 부분에서 인라인 프롬프트 대신 커스텀 에이전트 참조:

**Before** (references/phase-a-planning.md 등):
```
Spawn `architect` agent: git history 분석...
```

**After**:
```
`simon-architect` 에이전트에게 위임: git history 분석...
```

### 기대 효과

- 일관된 역할 정의 보장
- 도구 범위가 frontmatter에서 선언적으로 제한 (텍스트 지시 대체)
- `memory: user`로 architect/security-reviewer가 세션 간 학습 축적
- 스킬 본문에서 역할 정의 중복 제거 → 컨텍스트 절약

### 검증 방법

1. `claude agents`로 에이전트 목록 확인
2. simon-bot 실행 시 커스텀 에이전트가 정상 호출되는지 확인
3. 여러 세션 후 에이전트 메모리 디렉토리에 학습 누적되는지 확인

---

## P-005: ultrathink 키워드 전략적 배치

- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: references/phase-a-planning.md, references/phase-b-verification.md
- **카테고리**: 프롬프트 엔지니어링

### 현재 상태

simon-bot 스킬 어디에도 "ultrathink" 키워드가 없음. 모든 단계에서 동일한 추론 깊이.

### 제안 내용

깊은 추론이 필요한 핵심 단계에만 "ultrathink" 키워드를 배치:

1. **Phase A Step 0 (Scope Challenge)** — references/phase-a-planning.md
   - 변경 범위 판단은 프로젝트 성공의 핵심 결정
   - `> ultrathink: 변경 범위, 위험, 최소 변경 경로를 깊이 분석한다.`

2. **Phase A Step 4-B (Expert Plan Review)** — references/phase-a-planning.md
   - 도메인 전문가 교차 검증이 계획 품질을 결정
   - `> ultrathink: 도메인 간 교차 영향과 예상하지 못한 상호작용을 깊이 분석한다.`

3. **Step 7 (Bug/Security/Performance Review)** — references/phase-b-verification.md
   - 보안/성능 이슈는 깊은 추론이 필요
   - `> ultrathink: 보안 취약점, 성능 병목, 엣지 케이스를 깊이 분석한다.`

4. **Step 17 (Production Readiness)** — references/phase-b-verification.md
   - 프로덕션 배포 전 최종 판단
   - `> ultrathink: 프로덕션 환경에서의 위험, 롤백 전략, 모니터링 포인트를 깊이 분석한다.`

5. **grind Attempt 7+ (Strategy Pivot)** — references/grind-phase-b.md
   - 5회 이상 실패 후 전략 전환은 근본 원인 분석이 필요
   - `> ultrathink: 반복 실패의 근본 원인과 대안 전략을 깊이 분석한다.`

### 기대 효과

- 핵심 판단 지점에서 Opus 4.6의 적응형 reasoning이 high effort로 동작
- 아키텍처 결정, 보안 리뷰, 전략 전환의 품질 향상
- 비핵심 단계에서는 기존 속도 유지

### 주의사항

- ultrathink는 토큰 비용이 증가하므로 남용 금지
- 모든 Step이 아닌, 판단 영향도가 높은 5개 지점에만 제한 배치

### 검증 방법

1. verbose 모드 (Ctrl+O)에서 ultrathink 배치 단계에서 thinking 토큰이 증가하는지 확인
2. Step 0의 scope 판단 품질 비교 (ultrathink 전/후)

---

## P-006: description 간결화 및 토큰 예산 최적화

- **심각도**: HIGH
- **대상 스킬**: 전체 simon-bot 계열 12개 스킬
- **대상 파일**: 각 SKILL.md의 frontmatter description
- **카테고리**: 컨텍스트 관리

### 현재 상태

현재 description 예시 (simon-bot):
```
"19-step 딥 워크플로 — 계획, 구현, 검증을 최고 수준의 엄격함으로 수행합니다. Use when: (1) 새 기능/피처 구현 ("피처 구현해줘", "새 기능 만들어줘", "코드 작성해줘"), (2) 전문가 리뷰 패널이 필요한 체계적 계획 수립, (3) git worktree 기반 병렬 실행, (4) PR 전 종합 코드 검증이 필요할 때. 코드 변경이 수반되는 모든 중대한 작업에 이 스킬을 사용하세요."
```

약 250자. 12개 스킬 합산 시 약 3000-4000자로 추정.

공식 문서에 따르면: "The budget scales dynamically at 2% of the context window, with a fallback of 16,000 characters." 다른 스킬(git-commit, worktree 등 약 20개)의 description도 합산되므로 예산 압박 발생 가능.

### 제안 내용

description을 핵심 트리거 키워드와 1줄 역할 설명으로 축소하되, "Use when:" 패턴의 트리거 정확도는 유지:

| 스킬 | Before (요약) | After (제안) |
|------|--------------|-------------|
| simon-bot | 250자+ | `19-step 딥 워크플로 — 피처 구현, 코드 작성, 체계적 계획+구현+검증. Use when: 코드 변경이 수반되는 중대한 기능 구현.` |
| simon-bot-grind | 200자+ | `열일모드 — simon-bot의 끈질긴 변형. 10회 재시도, 자동 진단/복구. Use when: 절대 실패하면 안 되는 고위험 구현.` |
| simon-bot-pm | 200자+ | `프로젝트 매니저 — 앱 전체를 기획하고 simon-bot에게 분배. Use when: 새 앱/서비스, 대규모 마이그레이션, 전체 프로젝트 관리.` |
| simon-bot-review | 250자+ | `PR 코드 리뷰 — Draft PR, 인라인 리뷰, CI Watch, 피드백 루프. Use when: PR 리뷰, 코드 리뷰 필요.` |
| simon-bot-sessions | 200자+ | `세션 관리 — 작업 현황 파악, 이전 작업 재개. Use when: 현황 확인, 이어서 해줘, resume.` |
| simon-bot-report | 200자+ | `사전 분석 보고서 — RFC, 현황 분석서, 기술 문서 생성. Use when: RFC 작성, 코드 분석, 기술 조사.` |
| simon-bot-boost | 250자+ | `외부 자료 → 스킬 개선. Use when: 링크를 주며 스킬 개선 요청.` |
| simon-bot-auto-boost | 300자+ | `자동 웹 검색 → 스킬 개선. Use when: 자동으로 최신 사례 검색해서 반영.` |
| simon-bot-boost-capture | 250자+ | `작업 중 스킬 개선점 캡처. Use when: 스킬 문제점 발견, 나중에 고치고 싶을 때.` |
| simon-bot-boost-review | 200자+ | `축적된 인사이트 리뷰 & 적용. Use when: 캡처된 개선안 처리, boost review.` |
| simon-bot-grind | 이미 위에서 | — |
| simon-bot-sync | 150자 | (자동 트리거 스킬이므로 description 변경 영향 적음) |

### 기대 효과

- description 총 토큰 약 40-50% 감소
- 다른 스킬과의 예산 경쟁 완화
- 트리거 키워드가 짧고 명확해져 매칭 정확도 유지 또는 향상

### 주의사항

- description 축소 후 트리거 테스트 필수 (기존에 잘 트리거되던 프롬프트가 여전히 작동하는지)
- 각 스킬의 skill-creator eval을 활용하여 트리거 정확도 검증

### 검증 방법

1. `/context` 명령으로 스킬 description 예산 사용량 확인
2. 대표적 트리거 프롬프트 10개로 각 스킬 트리거 정확도 테스트
3. 축소 전/후 비교

---

## P-007: 서브에이전트 영구 메모리 활용

- **심각도**: HIGH
- **대상 스킬**: simon-bot (P-004와 연계)
- **대상 파일**: `~/.claude/agents/` 하위 에이전트 정의 파일
- **카테고리**: 컨텍스트 관리

### 현재 상태

전문가 에이전트가 세션 간에 학습을 축적하지 못함. 매 세션마다 같은 코드베이스 패턴을 처음부터 탐색.

### 제안 내용

P-004에서 정의한 커스텀 에이전트에 `memory: user` 필드 추가 (이미 P-004에 포함됨).

추가로, 에이전트 프롬프트에 메모리 관리 지시 삽입:

```markdown
## Memory Management

작업 완료 후 다음을 agent memory에 기록한다:
- 발견한 코드 패턴 (아키텍처, 테스트 구조, 에러 처리)
- 프로젝트별 관례 (네이밍, 디렉토리 구조)
- 반복 발견되는 이슈 패턴
- 핵심 파일 위치와 역할

새 작업 시작 전에 기존 memory를 참조하여 탐색 시간을 단축한다.
```

### 기대 효과

- 동일 프로젝트에서 반복 세션 시 탐색 시간 50%+ 감소
- architect가 프로젝트 아키텍처를 "기억"하여 일관된 결정
- security-reviewer가 이전에 발견한 패턴을 누적

### 검증 방법

1. 첫 세션: architect 에이전트 실행 → `~/.claude/agent-memory/simon-architect/` 확인
2. 두 번째 세션: 동일 프로젝트에서 architect 실행 → 이전 학습 참조 여부 확인
3. 탐색에 소비된 턴 수 비교

---

## P-008: context: fork 패턴 적용 (simon-bot-report)

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot-report
- **대상 파일**: SKILL.md frontmatter
- **카테고리**: 컨텍스트 관리

### 현재 상태

simon-bot-report는 읽기 전용 분석 스킬이지만 메인 컨텍스트에서 실행. 대량의 코드 탐색과 전문가 토론이 메인 컨텍스트를 소비.

### 제안 내용

simon-bot-report를 `context: fork, agent: general-purpose`로 실행하도록 변경:

```yaml
---
name: simon-bot-report
description: "사전 분석 보고서 작성..."
context: fork
agent: general-purpose
allowed-tools: Read, Grep, Glob, Bash(gh *), Agent
---
```

단, 이 변경은 simon-bot-report가 독립 호출될 때만 적용됨. simon-bot 내부에서 호출될 때는 기존 동작 유지.

### 기대 효과

- 보고서 생성 시 메인 컨텍스트 오염 없음
- 독립 호출 시 대량 코드 탐색이 격리된 컨텍스트에서 수행

### 주의사항

- context: fork는 대화 히스토리를 볼 수 없으므로, 사용자가 이전 대화에서 맥락을 전달한 경우 문제
- 보고서 결과가 요약되어 돌아오므로, 상세 내용은 파일로 저장해야 함

### 검증 방법

1. `/simon-bot-report` 독립 호출 시 메인 컨텍스트 토큰 소비 측정
2. 보고서 품질이 기존과 동등한지 확인

---

## P-009: /btw 활용 가이드 추가

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot (Cross-Cutting Protocols)
- **대상 파일**: SKILL.md
- **카테고리**: 컨텍스트 관리

### 현재 상태

워크플로 진행 중 사용자의 모든 질문/확인이 메인 컨텍스트에 누적됨.

### 제안 내용

Cross-Cutting Protocols에 `/btw` 활용 안내 추가:

```markdown
### Side Questions Protocol

워크플로 진행 중 사용자에게 진행 상황이나 세부사항을 확인받을 때, 컨텍스트에 남길 필요가 없는 질문은
`/btw`를 사용하도록 안내한다. `/btw`의 응답은 대화 히스토리에 들어가지 않아 컨텍스트를 절약한다.

적용 시점:
- "현재 Step 몇 번이야?" 같은 상태 확인 질문
- "이 파일이 뭐 하는 파일이야?" 같은 일회성 지식 질문
- "그 에러 메시지 다시 보여줘" 같은 이전 출력 재확인

비적용: 워크플로 방향 결정에 영향을 주는 피드백은 반드시 메인 컨텍스트에서 처리
```

### 기대 효과

- 긴 워크플로에서 불필요한 컨텍스트 소비 감소
- 자동 압축 빈도 감소

---

## P-010: 스킬 간 핸드오프에 스킬 사전로딩 활용

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot (simon-bot-review 호출 부분)
- **대상 파일**: references/integration-and-review.md
- **카테고리**: 프롬프트 엔지니어링 / 컨텍스트 관리

### 현재 상태

simon-bot → simon-bot-review 핸드오프 시 파일 기반으로 컨텍스트를 전달 (review-sequence.md, branch-name.md 등).

### 제안 내용

P-004의 커스텀 에이전트와 연계하여, simon-bot-review를 서브에이전트로 호출할 때 관련 스킬을 사전로딩:

```yaml
---
name: simon-code-reviewer
description: 코드 리뷰 전문 에이전트
skills:
  - simon-bot-review
  - git-commit
---
```

이렇게 하면 simon-bot-review의 SKILL.md 전체 내용이 서브에이전트 컨텍스트에 사전 주입되어, 스킬 발견/로딩 과정이 생략됨.

### 기대 효과

- 핸드오프 시 스킬 로딩 턴 절약
- 리뷰 에이전트가 즉시 워크플로 시작 가능

---

## 요약: 검증 전략

모든 제안의 검증은 다음 3단계로 진행:

### 단계 1: 정적 검증
- YAML frontmatter 유효성
- reference 파일 경로 존재
- 스킬 간 상호 참조 유효성
- skill-best-practices.md 6개 카테고리 체크

### 단계 2: 트리거 테스트
- 대표적 사용자 프롬프트 10개로 스킬 트리거 정확도 확인
- description 변경 시 기존 트리거가 여전히 작동하는지 검증

### 단계 3: 스모크 테스트
- 각 스킬의 Startup/첫 단계가 정상 실행되는지 확인
- hooks frontmatter가 올바르게 파싱되는지 확인
- !`command` 출력이 정상 삽입되는지 확인
- 커스텀 에이전트가 정상 호출되는지 확인

### 단계 4: 실제 워크플로 테스트
- 소규모 프로젝트에서 simon-bot SMALL path 전체 실행
- 자동 압축 유발 후 워크플로 연속성 확인
- grind 모드에서 3회+ 재시도 후 전략 전환 확인
