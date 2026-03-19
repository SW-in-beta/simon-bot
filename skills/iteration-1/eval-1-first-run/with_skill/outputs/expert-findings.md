# Phase 3: 전문가 패널 분석

6명의 전문가를 병렬 spawn하여 독립 분석 → 교차 토론 → 합의 도출 3라운드를 수행했다.

## 컨텍스트

- **소스**: 3개 기사 (Addy Osmani, Simon Willison, MIT Missing Semester)
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-sessions
- **기존 적용 내역**: applied-log.md의 ~80건 적용 기록 참조 (중복 방지)

---

## Expert 1: Workflow Architect

### 독립 분석 결과

**발견 1: Rewind-First Recovery Pattern (MIT)**

현재 simon-bot의 에러 복구는 Stop-and-Fix Gate → Error Resilience → 재시도 순서다. MIT 강의에서 "Rewind over Steer" 패턴을 강조한다 — 잘못된 방향을 수정할 때 steering message를 추가하는 것보다 conversation을 rewind하는 것이 더 효과적이다.

simon-bot-grind의 Escalation Ladder에서 Attempt 4+ 시점에 "fresh context"를 spawn하는 것은 이미 부분적으로 이 패턴을 채택했지만, 명시적인 "rewind 판단 기준"이 없다. 현재 Progress Detection은 "진전 없는 재시도 2회"를 기준으로 전략 전환을 하지만, "잘못된 방향으로 진전이 있는 경우"는 감지하지 못한다.

**제안**: simon-bot-grind에 "Direction Validation Check" 추가 — 매 Attempt 후 "현재 접근이 원래 요구사항에서 멀어지고 있지 않은지" 확인하는 단계. plan-summary.md의 AC와 현재 diff를 비교.

**발견 2: Spec Balance Gate (MIT)**

MIT 강의에서 "과소 사양(under-spec)과 과다 사양(over-spec) 모두 문제"라고 지적한다. simon-bot Phase A의 Step 1-B에서 STICC Framework 기반 계획서를 생성하는데, 계획서의 "상세도 수준"에 대한 명시적 가이드라인이 없다.

현재 Over-engineering 방지 원칙이 있지만, 이는 구현 단계(Phase B-E)에 초점을 맞추고 있다. 계획 단계에서 "계획이 너무 상세한지/너무 추상적인지" 판단하는 기준이 필요하다.

**제안**: Phase A Step 1-B에 "Spec Granularity Check" 추가 — "각 AC가 구현 없이 검증 가능한 수준인가?"를 기준으로 판단.

---

## Expert 2: Prompt Engineer

### 독립 분석 결과

**발견 1: In-Context Learning 강화 (Addy Osmani)**

Addy Osmani는 "원하는 패턴의 기존 코드를 예시로 제공하면 일관성이 65% 향상된다"고 보고한다. simon-bot Step 5에서 executor에게 code-design-analysis.md의 컨벤션을 전달하지만, 구체적인 "좋은 예시" 코드 스니펫을 전달하는 지침은 없다.

현재 Phase A Step 1-A의 Code Design Team이 프로젝트 컨벤션을 분석하지만, 분석 결과는 "규칙" 형태(예: "함수명은 camelCase")로 저장된다. "실제 코드 예시" 첨부가 더 효과적이다.

**제안**: code-design-analysis.md에 "Example Code Snippets" 섹션 추가 — 프로젝트에서 발견한 모범 코드 2-3개를 원문 그대로 포함. Step 5 executor에게 이 예시를 참조하도록 지시.

**발견 2: Explicit Guardrail Prompting (Addy Osmani)**

Addy Osmani가 제안하는 "hallucination보다 질문 요청" 가드레일이 simon-bot에 직접 적용 가능하다. 현재 Docs-First Protocol이 외부 지식 조회를 강제하지만, "모를 때 어떻게 행동해야 하는지"에 대한 명시적 지시가 부족하다.

이미 applied-log.md에서 Docs-First Protocol이 적용되어 있으므로, 이 제안은 Docs-First Protocol의 "조회 불가 시" 처리를 강화하는 방향으로 변형한다.

**제안**: Docs-First Protocol의 "조회 불가 시" 섹션에 "확인할 수 없는 정보는 사용자에게 명시적으로 보고하고 판단을 요청한다" 원칙 추가. 현재 "가장 가까운 정보 기반 구현"은 잠재적 hallucination 위험.

---

## Expert 3: Innovation Scout

### 독립 분석 결과

**발견 1: AI-Assisted Cross-Review (Addy Osmani)**

Addy Osmani는 "두 번째 AI 세션으로 첫 번째 세션의 코드를 리뷰"하는 접근을 제안한다. simon-bot은 이미 Cognitive Independence(Blind-First, Fresh Subagent)를 활용하지만, 이는 같은 워크플로 내의 subagent에 한정된다.

새로운 관점: "완전히 다른 프롬프트/역할의 AI"로 리뷰하는 것. 예를 들어, simon-bot의 전문가 패널은 모두 "simon-bot 워크플로 개선" 맥락에서 분석하지만, "일반적인 코드 리뷰어" 관점의 외부 에이전트가 추가되면 워크플로 관성에 빠진 blind spot을 발견할 수 있다.

그러나 이 접근은 이미 simon-bot-review의 CONNECTED 모드 Blind-First 2-Pass로 부분적 달성되어 있으므로, 중복 위험이 있다.

**판정**: 기존 메커니즘과 상당 부분 겹침. **Not Recommended**.

**발견 2: Debugging Spiral Early Exit (MIT)**

MIT 강의에서 "debugging spiral"에 대한 경고가 있다. simon-bot-grind의 Progress Detection이 이를 부분적으로 해결하지만, "spiral 감지" 자체는 정량적 비교(실패 수, 에러 메시지)에 의존한다.

MIT 접근: "에이전트를 중단하고 문제를 재정의"하는 것이 더 효과적. simon-bot-grind에 이미 "Problem Redefinition Check"가 보류 목록(applied-log.md P-009)에 있으므로, 이를 활성화하는 방향으로 제안.

**제안**: simon-bot-grind의 stall_threshold 도달 시, 단순 전략 전환 전에 "문제 재정의 단계"를 의무화 — "원래 문제가 무엇이었는지, 현재 무엇을 해결하려 하는지, 범위가 변질되지 않았는지" 확인.

---

## Expert 4: Quality & Safety Guardian

### 독립 분석 결과

**발견 1: Safety Isolation Levels (MIT)**

MIT 강의에서 에이전트의 안전 운영을 위한 격리 수준을 체계화한다: 도구 호출 확인(기본) → 격리 환경(VM/컨테이너) → 출력 검토. simon-bot의 Forbidden Rules 3계층(ABSOLUTE/CONTEXT-SENSITIVE/AUDIT-REQUIRED)이 유사한 목적이지만, "실행 환경 격리"에 대한 명시적 가이드가 없다.

그러나 simon-bot은 Claude Code 환경에서 실행되므로, VM/컨테이너 격리는 Claude Code의 기본 권한 모델에 의해 처리된다. 추가 격리 지침은 불필요.

**판정**: 현재 Forbidden Rules로 충분. **Not Recommended**.

**발견 2: Context Window Degradation Monitoring (MIT + Addy Osmani)**

MIT와 Addy Osmani 모두 "컨텍스트 윈도우가 채워질수록 성능이 저하된다"고 경고한다. simon-bot의 Context Window Management 섹션에서 "자동 압축이 발생해도 작업을 계속 진행한다"고 되어 있으나, 압축 후 "핵심 규칙이 유실되었는지" 확인하는 메커니즘이 없다.

이미 Deterministic Gate Principle과 Hook 기반 검증으로 "LLM 기억에 의존하지 않는" 구조를 일부 달성했지만, Cross-Cutting Protocol 준수 여부(예: TDD, Stop-and-Fix) 자체는 여전히 LLM 기억에 의존한다.

**제안**: 컨텍스트 압축(compact) 발생 후, 다음 Step 진입 전에 "Critical Protocol Recall Check" 실행 — `.claude/memory/` 파일에서 현재 활성화된 프로토콜 목록을 읽어 자기 점검. auto-verify.sh Hook이 이를 일부 보완하지만, Hook이 설정되지 않은 프로젝트에서는 취약.

---

## Expert 5: DX Specialist

### 독립 분석 결과

**발견 1: Commit as Save Points (Addy Osmani)**

Addy Osmani는 "커밋을 세이브포인트로 활용하여 빠른 롤백이 가능하게 한다"고 강조한다. simon-bot의 Integration Stage에서 커밋이 발생하지만, Phase B-E 구현 중간에는 워크트리 내에서 커밋 없이 작업이 진행된다.

simon-bot-grind의 checkpoint 시스템(`git tag checkpoint-step{N}-attempt{M}`)이 유사한 목적이지만, 일반 simon-bot에는 없다. 실패 시 롤백 가능한 "safe point"가 구현 중간에 필요하다.

그러나 일반 simon-bot은 grind만큼 재시도가 빈번하지 않으므로, 모든 Step에 checkpoint를 추가하는 것은 과도하다.

**판정**: 일반 simon-bot에는 불필요한 복잡성. grind에는 이미 존재. **Not Recommended**.

**발견 2: Progress Transparency (Addy Osmani + MIT)**

두 소스 모두 "AI가 무엇을 하고 있는지 사용자가 항상 알 수 있어야 한다"고 강조한다. simon-bot의 Phase B-E 자동 실행 시 Progress Pulse가 의무화되어 있지만(applied-log.md 확인), Pulse의 내용이 "연속 3회 실패 / 전략 전환 / 누적 15회 재시도"라는 이벤트 기반이다.

MIT 접근: 사용자가 "현재 어느 단계인지, 전체 중 얼마나 진행되었는지" 항상 파악할 수 있어야 한다. 이벤트 기반 Pulse 외에, "매 Step 완료 시 진행률 보고"가 있으면 DX가 향상된다.

이미 CONTEXT.md에 진행 상태가 기록되고, simon-bot-sessions의 Context Dashboard가 이를 시각화하지만, 자동 실행 중에는 사용자가 CONTEXT.md를 직접 읽어야 한다.

**제안**: Phase B-E 자동 실행 시 매 Step 완료 시점에 1줄 진행 보고를 사용자에게 출력. 형식: `[Step N/19] {단계명} 완료 — {소요 시간}, {다음 단계}`. 현재 Progress Pulse의 이벤트 기반 보고를 보완.

---

## Expert 6: Skill Craft Specialist

### 사전 로딩: skill-best-practices.md 확인 완료

### 독립 분석 결과

**발견 1: Skills Loading Optimization (MIT)**

MIT 강의에서 "Skills prevent context bloat by loading conditionally"를 강조한다. simon-bot의 Reference Loading Policy가 이를 잘 구현하고 있다. 그러나 SKILL.md 본문에서 Cross-Cutting Protocols 섹션이 ~160줄을 차지하며, 이 중 상당수는 첫 실행 시에만 필요한 설정 지침(Session Isolation Protocol, Auto-Verification Hook 등)이다.

SKILL.md가 389줄로 500줄 제한 이내이지만, 매 세션마다 이 160줄이 로딩되는 것은 비효율적이다. Cross-Cutting Protocols를 별도 reference로 분리하면 SKILL.md가 ~230줄로 줄어들어 핵심 워크플로에 더 많은 컨텍스트를 할당할 수 있다.

**제안**: simon-bot SKILL.md의 Cross-Cutting Protocols를 `references/cross-cutting-protocols.md`로 분리. SKILL.md에는 포인터만 남기고 "Startup에서 읽기" 지시 추가.

**발견 2: Specification Balance in Skill Design (MIT + Addy Osmani)**

MIT의 "Specification Balance" 개념을 스킬 설계에 적용하면: simon-bot-grind SKILL.md는 "모든 Step에 10회 retry" 테이블이 있지만, 각 Step의 구체적 retry 로직은 references에 위임되어 있어 적절한 balance를 유지하고 있다.

그러나 Grind Config Overrides의 YAML 블록(~50줄)이 SKILL.md에 인라인되어 있다. 이 설정값은 읽기 참조용이므로 reference로 이동해도 무방하다.

**제안**: 현재 SKILL.md가 184줄로 충분히 작으므로, 분리 시 조율 오버헤드가 이점보다 클 수 있다. **보류 권장**.

---

## 교차 토론 (Round 2)

### Workflow Architect → Quality & Safety Guardian 피드백

"Direction Validation Check" 제안에 대해, Quality Guardian이 "plan-summary.md AC와 diff 비교"는 결정론적 검증 도구로 구현 가능하다고 보강. bash 스크립트로 diff의 변경 파일이 plan-summary.md의 Unit 대상 파일과 일치하는지 확인하는 것이 첫 단계.

### Prompt Engineer → Innovation Scout 피드백

"Example Code Snippets" 제안에 대해, Innovation Scout이 "코드 예시의 컨텍스트 비용"을 우려. 예시 2-3개가 각각 10-20줄이면 추가 60줄이 code-design-analysis.md에 추가된다. 이는 Step 5 executor에게 전달되는 컨텍스트를 증가시킨다. 대안: 예시 코드의 파일 경로만 기록하고, executor가 필요 시 직접 Read하도록 지시.

### DX Specialist → Workflow Architect 피드백

"매 Step 완료 시 1줄 보고" 제안에 대해, Workflow Architect가 "Step 수가 19개이므로 과도한 출력이 될 수 있다"고 우려. 대안: Phase 경계(A/B-E/Integration/Review)에서만 진행률 보고, Step 단위는 CONTEXT.md에 기록.

---

## 합의 도출 (Round 3)

### 최종 제안 목록

| ID | 제안 제목 | 심각도 | 대상 스킬 | 합의 |
|----|-----------|--------|-----------|------|
| P-001 | Direction Validation Check | HIGH | simon-bot-grind | 5/6 동의 (DX Specialist: 구현 복잡도 우려) |
| P-002 | Code Example Reference in Code Design Analysis | MEDIUM | simon-bot | 6/6 동의 (경로만 기록하는 경량 버전) |
| P-003 | Docs-First "Unknown" Escalation | MEDIUM | simon-bot | 6/6 동의 |
| P-004 | Problem Redefinition at Stall | HIGH | simon-bot-grind | 6/6 동의 |
| P-005 | Critical Protocol Recall Check | MEDIUM | simon-bot | 4/6 동의 (Innovation Scout + DX: Hook이 더 나은 해결책) |
| P-006 | Phase-level Progress Report | MEDIUM | simon-bot | 6/6 동의 (Phase 경계 보고로 변형) |
| P-007 | Cross-Cutting Protocols Reference 분리 | LOW | simon-bot | 4/6 동의 (Quality Guardian + Prompt Engineer: 500줄 이내이므로 급하지 않음) |

### Not Recommended

| 아이디어 | 이유 |
|-----------|------|
| AI-Assisted Cross-Review (외부 에이전트) | simon-bot-review Blind-First 2-Pass로 이미 달성 |
| Safety Isolation Levels 추가 | Claude Code 기본 권한 모델로 충분 |
| Commit as Save Points (일반 simon-bot) | grind에 이미 존재, 일반 bot에는 과도 |
| Grind Config YAML 분리 | 184줄로 충분히 작아 조율 오버헤드가 더 큼 |
