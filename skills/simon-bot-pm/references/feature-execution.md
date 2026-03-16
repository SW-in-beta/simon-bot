# Feature Execution Protocol

Phase 4에서 각 Feature를 실행하는 상세 프로토콜.

## 목차
1. [Scope Guard](#scope-guard)
2. [Subagent 사용 기준](#subagent-사용-기준)
3. [Task Spec 생성](#task-spec-생성)
4. [Agent Spawn Protocol](#agent-spawn-protocol)
5. [그룹 간 통합 검증](#그룹-간-통합-검증)
6. [Failure Recovery Details](#failure-recovery-details)
7. [Progress Reporting](#progress-reporting)

---

## Scope Guard

각 Feature는 Task Spec에 명시된 변경만 구현한다. 요청하지 않은 추상화, 불필요한 헬퍼 파일 생성, 미래를 대비한 유연성 추가는 하지 않는다.

## Subagent 사용 기준

단일 파일 수정이나 간단한 설정 변경은 PM이 직접 수행한다. Subagent는 독립적 컨텍스트가 필요한 Feature 구현에만 spawn한다.

## Task Spec 생성

각 Feature 실행 전, `.claude/pm/tasks/{feature-id}/spec.md`를 생성한다.

```markdown
# Task Spec: {Feature ID} - {Feature Name}

## Context
- PRD 참조: .claude/pm/prd.md의 관련 섹션
- 선행 Feature 결과: (의존하는 Feature의 result.md 참조)

## Requirements
- PRD에서 추출한 구체적 요구사항
- 사용자 스토리
- 수용 기준

## Technical Constraints
- 사용할 기술/프레임워크
- 기존 코드와의 연동 방식
- 아키텍처 제약

## Files (Expected)
- 생성/수정할 파일 목록 (예상)

## Tests
- 작성해야 할 테스트 유형과 범위

## Acceptance Criteria
- [ ] 기준 1
- [ ] 기준 2
- ...
```

## Agent Spawn Protocol

### Bot 선택에 따른 실행

**simon-bot 할당 Feature:**

`general-purpose` agent를 spawn. 프롬프트에 다음을 포함:

```
당신은 아래 Feature를 구현하는 전문 구현자입니다.

[Task Spec 내용]

## 핵심 실행 파이프라인

1. **코드베이스 탐색** — 관련 코드 파악, 기존 패턴/컨벤션 학습
2. **구현 계획 수립** — 변경할 파일 목록, 순서 결정
3. **TDD 구현** — RED (실패 테스트 작성) → GREEN (최소 구현) → REFACTOR (정리) → VERIFY (전체 테스트)
4. **자체 코드 리뷰** — 버그, 보안, 성능 관점에서 자체 검토
5. **전체 빌드 + 테스트 통과 확인**

## 필수 규칙

- **TDD 필수**: 테스트를 먼저 작성하고 실패를 확인한 후 구현
- **Anti-hardcoding**: 특정 테스트 입력값을 하드코딩하지 않고 일반적 해결책 구현
- **Auto-Verification**: 소스코드 수정 후 빌드/린트 즉시 실행, 실패 시 수정 후 진행
- **환각 방지**: 읽지 않은 파일에 대해 추측하지 않고 반드시 Read로 확인
- **Over-engineering 방지**: Task Spec에 명시된 변경만 구현. 불필요한 추상화/헬퍼 생성 금지
- **테스트에서 실제 DB/외부 API 호출 금지** — mock/stub만 사용

## 참고 컨텍스트

- 코드 설계 컨벤션: .claude/memory/code-design-analysis.md (있으면 읽기)
- 프로젝트 규칙: CLAUDE.md (있으면 읽기)
- 기존 코드 패턴을 최우선으로 따름

완료 시 결과를 .claude/pm/tasks/{feature-id}/result.md에 저장.
```

### deep-executor 프롬프트 필수 포함 항목 (Lean Prompt 원칙)

deep-executor 프롬프트에는 **Task Spec + 핵심 실행 파이프라인 + 참고 파일 경로**만 포함한다. 공통 규칙(Forbidden Rules, Error Resilience 등)은 전문을 인라인하지 않고, "반드시 읽으라"는 포인터로 전달한다. 규칙 전문을 매 Feature마다 반복 포함하면 컨텍스트가 낭비되고, 규칙 업데이트 시 feature-execution.md도 함께 수정해야 하는 유지보수 부담이 발생하기 때문이다.

**프롬프트에 직접 포함:**
- Task Spec 전체 내용
- 핵심 실행 파이프라인 (코드베이스 탐색 → 구현 계획 → TDD → 자체 리뷰 → 빌드/테스트)
- 참고 컨텍스트 (code-design-analysis.md, CLAUDE.md 경로)

**포인터로 전달 (executor가 직접 Read):**
- [ ] `forbidden-rules.md` — 절대 위반 금지 규칙 (ABSOLUTE / CONTEXT-SENSITIVE / AUDIT-REQUIRED 3계층)
- [ ] `error-resilience.md` — 에러 발생 시 분류 및 복구 프로토콜
- [ ] `verify-commands.md` — 빌드/린트/테스트 명령
- [ ] Auto-Verification Hook, Anti-Hardcoding, Runtime Guard — SKILL.md Cross-Cutting에서 자동 적용

**simon-bot-grind 추가 포인터:**
- [ ] `grind-error-resilience.md` — Escalation Ladder + Strategy Pivot
- [ ] `grind-cross-cutting.md` — Progress Detection, Retry Budget
- [ ] Checkpoint System: 전략 전환 전 git tag
- [ ] Total Retry Budget 추적

**Feature 크기별 실행 경로** (Phase A는 PM이 이미 수행했으므로 제외):
- 소형 Feature (파일 5개 미만): Steps 5-8 + 17 (SMALL 경로)
- 중/대형 Feature: Steps 5-17 (STANDARD 경로)

**simon-bot-grind 할당 Feature:**

동일한 프롬프트에 아래 섹션을 추가:

```
## 열일모드 추가 규칙

- 모든 재시도 한계 = 10
- 빌드/테스트 실패 시: Attempt 1-3 즉시 수정, Attempt 4-6 근본 원인 분석, Attempt 7-9 전략 전환, Attempt 10 최후 시도
- 체크포인트: 전략 전환 전 `git tag checkpoint-step-attempt{N}`
- 실패를 .claude/memory/failure-log.md에 기록
- 에스컬레이션 전까지 포기하지 않고 계속 시도
```

### 병렬 실행

같은 그룹의 독립적 Feature들은 `run_in_background: true`로 병렬 spawn:

```
Group 2 실행:
  Agent A (background) → F2: 사용자 인증
  Agent B (background) → F3: 데이터 모델
  → 모두 완료 대기
  → 그룹 통합 검증
```

병렬 실행 시 주의:
- 같은 파일을 수정하는 Feature는 병렬 실행하지 않는다 -- 머지 충돌이 불가피하기 때문 (Phase 2에서 보장)
- 각 Feature는 독립된 워크트리에서 작업
- 최대 병렬 수: 3 (리소스 제약)

### 순차 실행

의존성 체인의 Feature는 순차 실행:

```
F1 완료 → F1 결과를 F4 spec에 반영 → F4 실행
```

## 그룹 간 통합 검증

각 실행 그룹 완료 후:

1. 모든 Feature 브랜치의 변경사항을 메인 작업 브랜치에 머지
2. 전체 빌드 확인
3. 전체 테스트 실행
4. 충돌 발생 시: `architect` 분석 → `executor` 해결

### Re-planning Gate

통합 검증이 끝나면 PM이 그룹 결과를 평가한다:

- 완료된 Feature의 결과가 예상과 다른가? (구조 변경, 예상 외 의존성 발생 등)
- 후속 그룹의 Task Spec을 수정하거나 작업을 분할/병합/재배치할 필요가 있는가?

재계획이 필요한 경우:
1. 변경 내용과 1줄 판단 근거를 사용자에게 제시한다
2. 사용자 승인을 받은 후 `tasks.json`과 `execution_groups`를 갱신한다
3. 갱신된 계획에 따라 다음 그룹을 실행한다

재계획이 불필요하면 그대로 다음 그룹으로 진행한다.

## Failure Recovery Details

### 1단계: 자동 진단

실패 발생 시 즉시:
1. 에러 로그 분석
2. 실패 원인 분류:
   - **ENV_INFRA**: 의존성 누락, 환경 설정, 네트워크 등
   - **CODE_LOGIC**: 로직 에러, 타입 에러, 테스트 실패 등
3. 원인에 맞는 수정 시도

### 2단계: Bot 전환

simon-bot으로 실행 중 3회 연속 실패 시:
- 자동으로 simon-bot-grind 모드로 전환
- 기존 진행 상태 유지한 채 grind의 강화된 재시도 로직 적용
- `.claude/pm/tasks.json`의 해당 Feature `bot` 필드를 `simon-bot-grind`로 갱신

**Handoff Manifest (P-009):** Bot 전환 시 `.claude/memory/handoff-manifest.json`에 전환 컨텍스트를 기록하여 이전 실패 이력이 전달되도록 한다:
```json
{
  "from_skill": "simon-bot",
  "to_skill": "simon-bot-grind",
  "timestamp": "ISO-8601",
  "dispatch_mode": "PM",
  "context_files": [
    ".claude/pm/tasks/{feature-id}/spec.md",
    ".claude/pm/tasks/{feature-id}/result.md",
    ".claude/memory/failure-log.md"
  ],
  "failure_context": {
    "last_step": 5,
    "failure_count": 3,
    "last_error_summary": "...",
    "attempted_strategies": ["..."]
  },
  "skip_steps": [],
  "force_path": "SMALL"
}
```
전환받는 스킬은 Startup 시 이 manifest를 감지하여 `context_files`를 자동 로딩하고, `failure_context`를 failure-log.md 초기값으로 사용한다.

**force_path 필드**: PM이 Feature의 scope를 이미 판단한 경우, `force_path`에 경로를 지정하면 simon-bot이 Step 0 Scope Challenge를 skip하고 해당 경로로 직행한다. 단, `config.yaml`의 `high_impact_paths`에 매칭되는 파일이 포함되면 STANDARD 이상을 강제한다.

### PM_DISPATCH 모드

PM이 simon-bot에게 Feature 구현을 위임할 때, Handoff Manifest에 `"dispatch_mode": "PM"`을 포함한다. simon-bot이 이 플래그를 감지하면:

- **Phase A 전체 SKIP**: Step 0 ~ Step 4-B + Calibration Checklist를 건너뛴다. PM이 Phase 1-2에서 이미 전문가 분석과 계획 수립을 완료했으므로 재분석은 중복이다.
- **Task Spec → plan-summary.md**: PM이 전달한 `tasks/{task-id}/spec.md`를 simon-bot의 `plan-summary.md`로 직접 사용한다.
- **PM 산출물 참조**: `code-design-analysis.md`와 `expert-plan-concerns.md`를 PM 세션에서 그대로 참조한다.
- **Phase B Pre-Phase부터 시작**: worktree 생성, CONTEXT.md 생성부터 진행한다.
- 이 규칙은 **Instruction**이다: `high_impact_paths` 매칭과 무관하게 적용한다.

**PM_DISPATCH에서도 유지되는 Step**: Step 5(TDD 구현), Step 6(Purpose Alignment), Step 7(Expert Review — 구현 결과 검증), Step 8(Regression), Step 17(Production Readiness). 코드 수준 검증은 PM이 대체할 수 없다.

### 3단계: 사용자 에스컬레이션

grind 모드에서도 해결 불가 시:
- 현재까지의 시도 내용과 에러 요약
- 가능한 대안 제시
- AskUserQuestion으로 사용자 결정 요청:
  - 다른 접근 방식 시도
  - Feature 스코프 축소
  - Feature 보류 (나머지 Feature 계속 진행)
  - 프로젝트 중단

## Progress Reporting

### Auto Mode

각 Feature 완료/실패 시 사용자에게 한 줄 보고:
```
[F2/6] 사용자 인증 ✓ 완료 (simon-bot-grind, 12min)
[F3/6] 데이터 모델 ✓ 완료 (simon-bot, 8min)
→ Group 2 통합 검증 통과. Group 3 자동 시작...
```

### Approval Mode

각 Feature 완료 시 상세 보고 후 AskUserQuestion:
```
[F2: 사용자 인증] 완료 보고

구현 내용:
- JWT 기반 인증 시스템
- 로그인/로그아웃/토큰 갱신 API
- 미들웨어 인증 체크

변경 파일: 8개
테스트: 12개 (all pass)
브랜치: feat/f2-auth

다음 작업으로 진행할까요? (F3: 데이터 모델)
```
