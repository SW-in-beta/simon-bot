# Phase 4: 개선 제안 & 승인

## Executive Summary

3개 소스(Addy Osmani, Simon Willison, MIT Missing Semester)에서 추출한 인사이트를 6인 전문가 패널이 분석하여 7건의 개선 제안을 도출했다. 기존 applied-log.md의 ~80건 적용 기록과 대조하여 중복을 제거했으며, 대부분의 소스 내용이 이미 simon-bot에 반영된 높은 수준의 기존 개선 위에 증분적 개선을 제안한다.

## 제안 목록 (심각도 순)

| ID | 제목 | 심각도 | 대상 스킬 | 판정 |
|----|-------|--------|-----------|------|
| P-001 | Direction Validation Check | HIGH | simon-bot-grind | **적용** |
| P-004 | Problem Redefinition at Stall | HIGH | simon-bot-grind | **적용** |
| P-002 | Code Example Reference in Code Design Analysis | MEDIUM | simon-bot | **적용** |
| P-003 | Docs-First "Unknown" Escalation | MEDIUM | simon-bot | **적용** |
| P-005 | Critical Protocol Recall Check | MEDIUM | simon-bot | **적용** |
| P-006 | Phase-level Progress Report | MEDIUM | simon-bot | **적용** |
| P-007 | Cross-Cutting Protocols Reference 분리 | LOW | simon-bot | **적용** |

**DRY-RUN 모드: 모든 제안을 자동 승인합니다.**

---

## P-001: Direction Validation Check

- **심각도**: HIGH
- **전문가**: Workflow Architect
- **대상 스킬**: simon-bot-grind
- **대상 파일**: `~/.claude/skills/simon-bot-grind/references/grind-cross-cutting.md`
- **출처**: MIT Missing Semester — "Rewind over Steer" 패턴
- **현재 상태**: simon-bot-grind의 Progress Detection은 "실패 수, 에러 메시지, 변경 라인 수"를 정량적으로 비교하여 "진전 없는 재시도 2회"를 감지한다. 그러나 "잘못된 방향으로 진전이 있는 경우"(실패 수가 줄지만 원래 요구사항에서 멀어지는 경우)는 감지하지 못한다.
- **개선안**: Progress Detection에 "Direction Validation" 단계를 추가한다. 매 재시도 후, 현재 diff가 plan-summary.md의 AC(Acceptance Criteria)와 여전히 정렬되어 있는지 확인한다. 정렬되지 않으면 "Direction Drift" 경고를 발생시키고, rewind를 고려하도록 한다.
- **근거**: MIT 강의에서 "에이전트가 잘못된 방향으로 열심히 나아가는 것"이 가장 비용이 큰 실패 패턴으로 지적됨
- **전문가 합의**: 5/6 동의 (DX Specialist만 구현 복잡도 우려)

### Proposed Diff

```markdown
# grind-cross-cutting.md에 추가

## Direction Validation Check

매 재시도 후 Progress Detection과 함께 실행한다.

**목적**: 실패 수가 줄어도 요구사항에서 멀어지고 있을 수 있다. 진전(progress)과 방향(direction)을 분리하여 평가한다.

**실행 절차**:
1. `git diff` 출력에서 변경된 파일 목록 추출
2. plan-summary.md의 해당 Unit AC 목록과 대조
3. 변경이 AC와 무관한 파일에 집중되어 있으면 "Direction Drift" 경고

**Direction Drift 감지 시 행동**:
- 사용자에게 1줄 경고: `[Direction Drift] 변경이 AC와 무관한 영역에 집중되어 있습니다. 원래 문제를 재확인합니다.`
- plan-summary.md의 AC를 재읽기
- 현재 접근법이 원래 문제를 해결하는지 자가 점검
- 필요 시 checkpoint로 롤백 후 방향 수정
```

---

## P-004: Problem Redefinition at Stall

- **심각도**: HIGH
- **전문가**: Innovation Scout
- **대상 스킬**: simon-bot-grind
- **대상 파일**: `~/.claude/skills/simon-bot-grind/references/grind-cross-cutting.md`
- **출처**: MIT Missing Semester — "Debugging Spiral" 경고 + applied-log.md 보류 항목(P-009)
- **현재 상태**: stall_threshold(기본 2회) 도달 시 "전략 전환"을 수행한다. 그러나 전략 전환은 "다른 방법으로 같은 문제를 해결"하는 것이며, "문제 자체를 재정의"하는 단계가 없다. 범위 변질(scope creep)이나 문제 오해가 원인인 경우 전략 전환만으로는 해결되지 않는다.
- **개선안**: stall_threshold 도달 시, 전략 전환 전에 "Problem Redefinition Check"를 의무 실행한다.
- **근거**: MIT 강의에서 "debugging spiral에 빠지면 에이전트를 중단하고 문제를 재정의하라"고 권고. applied-log.md에서 이 제안이 이미 보류(deferred) 상태였으므로 활성화를 추천
- **전문가 합의**: 6/6 동의

### Proposed Diff

```markdown
# grind-cross-cutting.md의 Progress Detection 섹션에 추가

### Problem Redefinition Check

stall_threshold 도달 시, 전략 전환 전에 반드시 실행한다 — 같은 문제를 다른 방법으로 공략하는 것과, 문제 자체를 잘못 이해하고 있는 것은 다르다.

**실행 절차**:
1. plan-summary.md에서 원래 요구사항과 AC를 다시 읽는다
2. 현재 해결하려는 문제를 1문장으로 정리한다
3. 원래 요구사항과 비교: 범위가 변질되지 않았는가?
4. failure-log.md의 최근 실패 패턴을 검토: 문제 정의가 잘못된 징후가 있는가?

**범위 변질 감지 시**:
- decision-journal.md에 기록: `[Problem Redefinition] 원래 문제: X, 현재 시도: Y, 변질 원인: Z`
- 원래 문제로 범위를 축소하고, 변질된 부분은 unresolved-decisions.md에 기록
- checkpoint로 롤백 후 원래 범위로 재시작
```

---

## P-002: Code Example Reference in Code Design Analysis

- **심각도**: MEDIUM
- **전문가**: Prompt Engineer
- **대상 스킬**: simon-bot
- **대상 파일**: `~/.claude/skills/simon-bot/references/phase-a-planning.md`
- **출처**: Addy Osmani — "In-Context Learning으로 일관성 65% 향상"
- **현재 상태**: Phase A Step 1-A의 Code Design Team이 code-design-analysis.md에 프로젝트 컨벤션을 "규칙" 형태로 기록한다 (예: "함수명은 camelCase", "에러 처리는 Result 타입 사용"). 그러나 구체적인 코드 예시가 없어 executor가 규칙을 자기 방식으로 해석할 여지가 있다.
- **개선안**: code-design-analysis.md에 "Example File Paths" 섹션을 추가한다. 프로젝트에서 발견한 모범 코드의 파일 경로 2-3개를 기록하고, Step 5 executor에게 "구현 전 이 파일들을 Read하여 패턴을 파악하라"고 지시한다.
- **근거**: Addy Osmani가 "코드 예시를 직접 보여주면 LLM의 일관성이 크게 향상된다"고 보고. 경로만 기록하여 컨텍스트 비용을 최소화하는 경량 접근.
- **전문가 합의**: 6/6 동의 (Innovation Scout 제안으로 경로만 기록하는 경량 버전으로 확정)

### Proposed Diff

```markdown
# phase-a-planning.md의 Step 1-A Code Design Analysis 섹션 끝에 추가

#### Example File Paths

code-design-analysis.md에 컨벤션 규칙과 함께 모범 구현 파일 경로를 기록한다 — 규칙만으로는 해석 여지가 남지만, 실제 코드 예시를 참조하면 일관성이 크게 향상된다.

```
## Example Files
- 에러 처리 패턴: `src/services/user-service.ts` (L30-55)
- API 응답 구조: `src/controllers/auth-controller.ts` (L10-40)
- 테스트 작성 스타일: `tests/unit/user-service.test.ts` (L1-30)
```

Step 5 executor에게: "구현 시작 전 Example Files의 경로를 Read하여 프로젝트 패턴을 파악한 뒤, 동일한 패턴을 따라 구현한다."
```

---

## P-003: Docs-First "Unknown" Escalation

- **심각도**: MEDIUM
- **전문가**: Prompt Engineer
- **대상 스킬**: simon-bot
- **대상 파일**: `~/.claude/skills/simon-bot/references/docs-first-protocol.md`
- **출처**: Addy Osmani — "Explicit Guardrails: hallucination보다 질문 요청"
- **현재 상태**: Docs-First Protocol의 "조회 불가 시" 처리가 "가장 가까운 정보 기반으로 구현하되, 불확실성을 주석으로 표시"로 되어 있다. 이는 잠재적 hallucination 위험이 있다 — LLM이 "가장 가까운 정보"를 자체적으로 판단하면, 그 판단 자체가 부정확할 수 있다.
- **개선안**: "조회 불가 시" 처리에 "사용자 에스컬레이션" 경로를 추가한다. 확인할 수 없는 정보는 사용자에게 명시적으로 보고하고 판단을 요청한다.
- **근거**: Addy Osmani의 "hallucination보다 질문 요청" 가드레일과 일치
- **전문가 합의**: 6/6 동의

### Proposed Diff

```markdown
# docs-first-protocol.md의 "조회 불가 시" 섹션 수정

### 조회 불가 시 처리 (수정)

1. Context7 → WebFetch → 학습 데이터 순으로 시도 (기존)
2. **모든 소스에서 확인 불가 시**: 사용자에게 에스컬레이션
   - 형식: `[Docs-First] {라이브러리/API}의 {기능}에 대해 공식 문서를 확인할 수 없습니다. 학습 데이터 기반 추정: {추정 내용}. 이대로 진행할까요?`
   - 사용자 승인 후에만 추정 기반 구현 진행
   - 추정 기반 구현 시 코드에 `// TODO: 공식 문서 확인 필요 — 추정 기반 구현` 마커 추가
3. ~~가장 가까운 정보 기반 구현~~ → 사용자 승인 없이 추정 기반 구현하지 않음
```

---

## P-005: Critical Protocol Recall Check

- **심각도**: MEDIUM
- **전문가**: Quality & Safety Guardian
- **대상 스킬**: simon-bot
- **대상 파일**: `~/.claude/skills/simon-bot/SKILL.md`
- **출처**: MIT Missing Semester + Addy Osmani — "컨텍스트 윈도우 성능 저하"
- **현재 상태**: Context Window Management에서 "자동 압축이 발생해도 작업을 계속 진행한다"고 되어 있다. Deterministic Gate Principle과 auto-verify.sh Hook이 일부 규칙의 준수를 보장하지만, Hook이 설정되지 않은 프로젝트에서는 Cross-Cutting Protocol 준수가 LLM 기억에 의존한다. 컨텍스트 압축 후 TDD 규칙이나 Stop-and-Fix Gate 같은 핵심 규칙이 약화될 수 있다.
- **개선안**: Context Window Management 섹션에 "압축 후 프로토콜 리콜" 가이드를 추가한다.
- **근거**: MIT와 Addy Osmani 모두 컨텍스트 윈도우 성능 저하를 핵심 과제로 지적
- **전문가 합의**: 4/6 동의 (Innovation Scout + DX: Hook이 근본 해결책이므로 이 제안은 보조적)

### Proposed Diff

```markdown
# simon-bot SKILL.md의 Context Window Management 섹션에 추가

### 압축 후 프로토콜 리콜

컨텍스트 압축(compact) 발생 후, 다음 Step 진입 전에 `.claude/memory/` 파일을 재읽기하여 핵심 프로토콜을 상기한다 — 압축 과정에서 Cross-Cutting Protocol(TDD, Stop-and-Fix, Docs-First 등)의 세부 규칙이 약화될 수 있기 때문이다.

리콜 대상 (최소):
- `plan-summary.md` — 현재 AC와 범위
- `decision-journal.md` — 이전 결정과 기각 사유
- `failure-log.md` — 최근 실패 패턴 (grind 전용)

auto-verify.sh Hook이 설정된 프로젝트에서는 빌드/린트 규칙이 Hook으로 보장되므로, 리콜 범위를 `plan-summary.md`와 `decision-journal.md`로 축소할 수 있다.
```

---

## P-006: Phase-level Progress Report

- **심각도**: MEDIUM
- **전문가**: DX Specialist
- **대상 스킬**: simon-bot
- **대상 파일**: `~/.claude/skills/simon-bot/references/phase-b-implementation.md`
- **출처**: Addy Osmani + MIT Missing Semester — "사용자가 항상 현재 상태를 알 수 있어야 한다"
- **현재 상태**: Phase B-E 자동 실행 중 Progress Pulse가 이벤트 기반(연속 3회 실패, 전략 전환 등)으로 발생한다. 정상 진행 중에는 사용자가 진행 상황을 알기 어렵다 — CONTEXT.md에 기록되지만 자동 실행 중에는 사용자가 직접 읽어야 한다.
- **개선안**: Phase 경계(Phase A 완료, Phase B-E 각 Unit 완료, Integration 완료, Review 완료)에서 1줄 진행 보고를 사용자에게 출력한다.
- **근거**: MIT 강의에서 "사용자가 현재 어느 단계인지, 전체 중 얼마나 진행되었는지" 파악 필요성 강조
- **전문가 합의**: 6/6 동의 (Step 단위가 아닌 Phase 단위로 변형하여 출력 과다 방지)

### Proposed Diff

```markdown
# phase-b-implementation.md의 Critical Rules 섹션에 추가

### Phase-level Progress Report

Phase 경계에서 사용자에게 1줄 진행 보고를 출력한다 — 자동 실행 중에도 사용자가 전체 진행을 파악할 수 있어야 한다.

보고 시점과 형식:
- Phase A 완료: `[Progress] Phase A 완료 — 계획 수립 완료, Unit {N}개 식별, Phase B 시작합니다.`
- Unit 완료: `[Progress] Unit {M}/{N} 완료 — {Unit 이름}, 다음: Unit {M+1}.`
- Integration 완료: `[Progress] Integration 완료 — 전체 빌드/테스트 통과, Step 18 보고서 작성 시작.`
- Review 완료: `[Progress] Review 완료 — PR 생성, 리뷰 코멘트 {N}건 처리 완료.`

이 보고는 기존 Progress Pulse(이벤트 기반)와 병행한다. Progress Pulse는 문제 발생 시, Phase-level Report는 정상 진행 시 작동하여 사용자가 항상 상태를 파악할 수 있다.
```

---

## P-007: Cross-Cutting Protocols Reference 분리

- **심각도**: LOW
- **전문가**: Skill Craft Specialist
- **대상 스킬**: simon-bot
- **대상 파일**: `~/.claude/skills/simon-bot/SKILL.md` → `~/.claude/skills/simon-bot/references/cross-cutting-protocols.md` (신규)
- **출처**: MIT Missing Semester — "Skills prevent context bloat by loading conditionally"
- **현재 상태**: simon-bot SKILL.md의 Cross-Cutting Protocols 섹션이 ~160줄을 차지한다. SKILL.md 전체가 389줄로 500줄 제한 이내이지만, 매 세션마다 160줄의 Cross-Cutting 지침이 로딩된다. 이 중 Session Isolation Protocol, Auto-Verification Hook, Composable CLI Script Toolkit 등은 Startup 또는 첫 실행 시에만 필요하다.
- **개선안**: Cross-Cutting Protocols를 `references/cross-cutting-protocols.md`로 분리하고, SKILL.md에는 포인터와 핵심 원칙(Stop-and-Fix Gate, TDD 등 매 Step에서 참조하는 항목)만 남긴다.
- **근거**: MIT 강의에서 조건부 로딩의 중요성 강조. 389줄→~230줄로 축소 시 핵심 워크플로에 더 많은 컨텍스트 할당 가능
- **전문가 합의**: 4/6 동의 (Quality Guardian + Prompt Engineer: 급하지 않으나 방향은 올바름)

### Proposed Diff

```markdown
# simon-bot SKILL.md — Cross-Cutting Protocols 섹션을 축소

## Cross-Cutting Protocols

핵심 프로토콜을 아래에 요약한다. 전체 상세 내용은 Startup에서 로딩:

> **Reference Loading**: Startup 시 [cross-cutting-protocols.md](references/cross-cutting-protocols.md)를 읽는다.

### Stop-and-Fix Gate (인라인 유지 — 매 Step에서 참조)
(기존 내용 유지)

### Parallel Tool Invocation (인라인 유지 — 매 Step에서 참조)
(기존 내용 유지)

### Reference Loading Policy (인라인 유지 — 매 Step에서 참조)
(기존 내용 유지)

--- 아래 섹션은 references/cross-cutting-protocols.md로 이동 ---
- Error Resilience
- Session Isolation Protocol
- Agent Teams
- Cognitive Independence
- Decision Journal
- Auto-Verification Hook
- Deterministic Gate Principle
- Composable CLI Script Toolkit
- Subagent 사용 기준
- Over-engineering 방지
- User Interaction Recording
- Handoff Notification
- Docs-First Protocol
```

```markdown
# 신규 파일: references/cross-cutting-protocols.md

# Cross-Cutting Protocols (상세)

SKILL.md에서 포인터로 참조되는 Cross-Cutting Protocols의 전체 내용.

## Error Resilience
(SKILL.md에서 이동)

## Session Isolation Protocol
(SKILL.md에서 이동)

... (나머지 섹션들)
```

---

## Cross-Cutting Observations

여러 스킬에 공통 적용되는 패턴:

1. **3개 소스 모두 "컨텍스트 관리"를 핵심 과제로 지적** — simon-bot의 Reference Loading Policy, 세션 분할 경계, Memory Persistence가 이를 잘 대응하고 있다
2. **TDD-first 접근의 보편적 합의** — Addy Osmani, Simon Willison, MIT 모두 "테스트 먼저, 에이전트가 구현"을 최적 패턴으로 제시. simon-bot의 Step 5 TDD 필수가 이와 정확히 일치
3. **Plan-before-Execute** — 3개 소스 모두 강조. simon-bot의 Phase A가 이를 구현

## Not Recommended

| 아이디어 | 출처 | 기각 이유 |
|-----------|------|-----------|
| AI-Assisted Cross-Review (외부 에이전트) | Addy Osmani | simon-bot-review Blind-First 2-Pass로 이미 달성 |
| Safety Isolation Levels (VM/컨테이너) | MIT | Claude Code 기본 권한 모델로 충분 |
| Commit as Save Points (일반 simon-bot) | Addy Osmani | grind의 checkpoint로 이미 존재, 일반 bot에는 과도 |
| Grind Config YAML reference 분리 | MIT | 184줄로 충분히 작아 조율 오버헤드가 이점 초과 |

## 적용 기록 (proposed)

```markdown
## [AUTO-BOOST] 2026-03-13
- 검색 범위: 첫 실행 (최근 2주)
- 소스: 3건 분석 (Addy Osmani, Simon Willison, MIT Missing Semester)
- 적용: 7건 / 보류: 0건 / 거부: 0건

### 적용된 변경
1. [simon-bot-grind] Direction Validation Check — Workflow Architect / 파일: grind-cross-cutting.md / Progress Detection에 방향 검증 추가
2. [simon-bot-grind] Problem Redefinition at Stall — Innovation Scout / 파일: grind-cross-cutting.md / stall 시 문제 재정의 의무화
3. [simon-bot] Code Example Reference — Prompt Engineer / 파일: phase-a-planning.md / code-design-analysis에 예시 파일 경로 추가
4. [simon-bot] Docs-First Unknown Escalation — Prompt Engineer / 파일: docs-first-protocol.md / 조회 불가 시 사용자 에스컬레이션 추가
5. [simon-bot] Critical Protocol Recall Check — Quality Guardian / 파일: SKILL.md / 압축 후 프로토콜 리콜 추가
6. [simon-bot] Phase-level Progress Report — DX Specialist / 파일: phase-b-implementation.md / Phase 경계 진행 보고 추가
7. [simon-bot] Cross-Cutting Protocols 분리 — Skill Craft Specialist / 파일: SKILL.md → cross-cutting-protocols.md / ~160줄 분리
```
