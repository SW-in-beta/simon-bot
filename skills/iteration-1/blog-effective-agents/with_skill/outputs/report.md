# simon-bot Boost Report

## Source
- **자료**: [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) (Anthropic Engineering Blog)
- **분석일**: 2026-03-06

## Executive Summary

Anthropic의 "Building Effective Agents" 블로그는 에이전트 시스템 설계의 핵심 원칙으로 **단순함 우선**, **투명성**, **도구 인터페이스 품질(ACI)**을 제시한다. 이 원칙들을 simon-bot 계열 스킬에 대입하면, (1) 워크플로 단계의 과잉 복잡성을 줄일 수 있는 경로 분기(Routing) 패턴 도입, (2) Evaluator-Optimizer 루프의 명시적 종료 조건 강화, (3) 도구/에이전트 인터페이스에 poka-yoke 원칙 적용, (4) 환경 피드백 기반 진행 평가(Ground Truth) 체계 강화, (5) 프레임워크 추상화 계층 최소화 등 구체적인 개선 기회가 식별된다. 특히 simon-bot의 19-step 파이프라인은 이미 높은 수준의 체계를 갖추고 있지만, Anthropic이 경고하는 "불필요한 복잡성 추가" 함정에 일부 노출되어 있으며, 명시적 탈출 조건과 단순화 경로가 보강되어야 한다.

---

## Expert Panel Analysis

### Expert 1: Workflow Architect (워크플로 설계 전문가)

**독립 분석:**

simon-bot의 19-step 파이프라인은 Anthropic이 설명하는 **Prompt Chaining** 패턴의 고도화 버전이다. 블로그의 핵심 메시지인 "Finding the simplest solution possible, and only increasing complexity when needed"에 비추어 보면, 19개 전체 스텝을 항상 실행하는 것은 과잉일 수 있다. 현재 SMALL/STANDARD/LARGE 경로 분기가 있지만, 이는 Step 0에서 한 번만 판별되며, 실행 중간에 복잡도가 예상보다 낮다고 판명되었을 때 동적으로 스텝을 건너뛰는 메커니즘이 부족하다.

Anthropic의 **Routing** 패턴은 "입력을 분류하여 전문화된 후속 작업으로 전달"하는 구조인데, simon-bot에서는 Step 0의 scope 판별이 이에 해당하지만, 더 세분화될 수 있다. 또한 **Orchestrator-Workers** 패턴은 simon-bot의 Agent Team 구조와 유사하지만, 블로그는 "subtasks aren't pre-defined, but determined by the orchestrator"라는 동적 분해를 강조하는 반면 simon-bot의 Agent Team은 사전 정의된 역할 구성이 대부분이다.

**교차 토론 반영:**

Expert 5(DX)의 "사용자가 단순한 작업에도 무거운 파이프라인을 경험한다"는 피드백에 동의한다. Expert 4(Quality)의 "단순화가 품질 저하를 초래할 수 있다"는 우려는 타당하나, Anthropic의 조언대로 "demonstrably improves outcomes"인 스텝만 유지하는 것이 옳다.

---

### Expert 2: Prompt Engineer (프롬프트 엔지니어링 전문가)

**독립 분석:**

블로그의 **ACI(Agent-Computer Interface)** 원칙은 simon-bot의 에이전트 역할 정의에 직접 적용된다. 현재 simon-bot의 에이전트들(architect, planner, critic, executor 등)은 SKILL.md와 references/ 파일에 역할이 서술되어 있지만, Anthropic이 강조하는 수준의 "example usage, edge cases, input format requirements, and clear boundaries from other tools"는 부족하다.

특히 블로그의 "Give the model enough tokens to 'think' before it writes itself into a corner" 원칙은 simon-bot의 Agent Team 토론 구조에서 중요하다. 현재 Task 1(독립 분석) → Task 2(교차 토론) → Task 3(합의 도출) 구조는 좋지만, 각 Task의 출력 포맷이 충분히 구조화되어 있지 않아 모델이 "자기 논리에 갇히는" 현상이 발생할 수 있다.

블로그의 **투명성(Transparency)** 원칙 — "explicitly showing the agent's planning steps" — 은 simon-bot의 사용자 보고 체계에 반영되어야 한다. 현재 각 스텝 완료 시 메모리에 기록하지만, 사용자에게 "왜 이 판단을 했는지"를 명시적으로 보여주는 구조는 부족하다.

**교차 토론 반영:**

Expert 3(Innovation)의 "Evaluator-Optimizer 패턴을 명시적으로 도입하자"에 동의하며, 이 패턴의 프롬프트 설계에서 평가 기준(evaluation criteria)을 구조화된 형태로 명시하는 것이 핵심이라고 강조한다.

---

### Expert 3: Innovation Scout (기술 혁신 탐색가)

**독립 분석:**

블로그에서 식별한 도입 가능한 새로운 패턴:

1. **Evaluator-Optimizer 패턴의 명시적 적용**: simon-bot의 Step 2-4(Plan Review)는 planner + critic의 반복이지만, 블로그가 설명하는 Evaluator-Optimizer 패턴처럼 "하나가 생성, 다른 하나가 구조화된 평가를 제공하는 루프"로 명시적으로 재구성하면 종료 조건이 더 명확해진다. 현재는 "max 3 iterations"이라는 횟수 기반 종료만 있고, "평가 점수가 임계값을 넘으면 종료"같은 품질 기반 종료가 없다.

2. **Routing 패턴의 Phase B 적용**: Step 5-16에서 각 스텝이 순차 실행되지만, 실제로 Step 9-16의 각 스텝은 "해당 이슈가 감지되었을 때만" 실행하는 조건부 라우팅이 더 효율적이다.

3. **Parallelization의 Voting 변형**: 코드 리뷰(Step 12)나 보안 리뷰(Step 7)에서 동일한 리뷰를 여러 프롬프트로 병렬 수행하여 다양한 관점을 확보하는 Voting 패턴은 현재 미활용.

4. **Ground Truth 기반 진행 평가**: 블로그의 "agents must gain ground truth from the environment at each step"은 simon-bot에서 각 스텝 완료 후 빌드/테스트 결과를 환경 피드백으로 활용하는 것과 일치하지만, 이를 더 체계적으로 매 스텝 후 검증 게이트로 표준화할 수 있다.

**교차 토론 반영:**

Expert 1(Architect)의 "동적 스텝 건너뛰기" 제안과 Voting 패턴을 결합하면, "복수 에이전트가 빠르게 검증하여 추가 분석 불필요 판단 시 스킵"하는 구조가 가능하다. Expert 4(Quality)의 "Voting이 비용을 증가시킨다"는 지적은 타당하므로 CRITICAL 판정 항목에만 선택적 적용을 제안한다.

---

### Expert 4: Quality & Safety Guardian (품질/안전 전문가)

**독립 분석:**

블로그는 "The autonomous nature of agents means higher costs, and the potential for compounding errors"라고 경고한다. simon-bot-grind의 10회 재시도 전략은 이 "compounding errors" 위험에 직접 노출되어 있다. 블로그가 권장하는 "extensive testing in sandboxed environments, along with the appropriate guardrails"와 "stopping conditions (such as a maximum number of iterations)"는 grind에 이미 구현되어 있지만, 에러 축적 감지 메커니즘은 보강이 필요하다.

현재 grind의 Auto-Diagnosis에서 `diagnosis_threshold: 5`(5회 실패 후 근본 원인 분석)는 있지만, **같은 유형의 에러가 반복되는지 감지하는 패턴 매칭**이 명시적이지 않다. 블로그가 강조하는 "ground truth from the environment"를 활용하여, 매 재시도 후 환경 상태(테스트 결과, 빌드 로그)를 구조적으로 비교하여 "진전이 있는지 없는지"를 판별하는 메커니즘이 필요하다.

simon-bot의 Global Forbidden Rules는 견고하다. 그러나 블로그의 poka-yoke 원칙에 따르면, 금지 규칙을 "위반 시 차단"하는 수동적 방어뿐 아니라 "위반하기 어렵게 인터페이스를 설계"하는 능동적 방어도 도입해야 한다.

**교차 토론 반영:**

Expert 1(Architect)의 "동적 단순화" 제안은 품질 게이트를 통과한 경우에만 허용되어야 한다. 스텝 스킵의 조건을 "이전 스텝의 환경 피드백이 특정 품질 임계값 이상"으로 정의하면 안전하게 단순화할 수 있다.

---

### Expert 5: Developer Experience (DX) Specialist (개발자 경험 전문가)

**독립 분석:**

블로그의 "Start by using LLM APIs directly: many patterns can be implemented in a few lines of code"는 스킬 사용자 관점에서 중요한 시사점이 있다. simon-bot의 19-step 파이프라인은 강력하지만, 단순한 기능 구현에도 전체 파이프라인을 거치는 것은 과잉이다. 현재 SMALL 경로가 Step 9-16을 건너뛰지만, Phase A(계획)는 동일하게 무거운 인터뷰와 전문가 패널을 거친다.

simon-bot-pm의 Scope Guard 패턴은 좋은 모범 사례인데, simon-bot 자체에도 유사한 "이 작업에 19-step이 정말 필요한가?"라는 자가 진단이 Phase A 초기에 더 적극적으로 이루어져야 한다.

블로그가 강조하는 **투명성** — "explicitly showing the agent's planning steps" — 은 사용자 경험에 직결된다. 현재 simon-bot은 각 스텝 완료 시 메모리에 기록하지만, 사용자에게 실시간으로 "지금 어디이고, 왜 이걸 하고 있고, 다음에 뭘 할 것인지"를 보여주는 Progress Dashboard 개념이 부족하다.

simon-bot-sessions의 resume 흐름도 블로그의 "agents can pause for human feedback at checkpoints"와 일치하지만, 복원 시 사용자에게 "이전 세션에서 어디까지 했고, 무엇이 성공/실패했는지"를 한눈에 보여주는 요약이 더 풍부해야 한다.

**교차 토론 반영:**

Expert 2(Prompt)의 "판단 근거 투명성" 제안과 결합하여, 각 주요 판단 지점에서 "이 결정을 한 이유: ..."를 사용자에게 1줄로 보여주는 Decision Trail 패턴을 제안한다. Expert 3(Innovation)의 "Routing 패턴"은 DX 관점에서도 "사용자가 불필요한 대기를 하지 않는" 효과가 있어 강력히 지지한다.

---

## Improvement Proposals

### [P-001] Phase B 조건부 라우팅 도입 (Conditional Routing for Steps 9-16)
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: SKILL.md, references/phase-b-implementation.md
- **카테고리**: 워크플로 구조
- **현재 상태**: STANDARD/LARGE 경로에서 Step 9-16이 모두 순차 실행된다. 각 스텝이 이슈를 발견하지 못해도 다음 스텝으로 진행하며, "이 스텝이 필요한가?"를 동적으로 판단하지 않는다.
- **제안 내용**: Anthropic의 Routing 패턴을 적용하여, Step 5(구현) 완료 후 빠른 진단 스캔(Quick Triage)을 실행한다. 진단 결과에 따라 Step 9-16 중 실제로 필요한 스텝만 활성화하는 조건부 라우팅을 도입한다. 예: 파일 수가 적으면 Step 9(File Splitting) 스킵, 외부 연동이 없으면 Step 10(Integration Review) 스킵, dead code가 감지되지 않으면 Step 13 스킵.
- **기대 효과**: 불필요한 스텝 실행 제거로 지연 시간과 비용 절감. Anthropic의 "only increase complexity when needed" 원칙 준수. 컨텍스트 윈도우 소비 절약.
- **근거**: 블로그의 Routing 패턴 — "classifies an input and directs it to a specialized followup task"; "Finding the simplest solution possible, and only increasing complexity when needed."
- **전문가 합의**: Architect(강력 지지), Innovation(지지), DX(지지), Quality(조건부 동의 — Quick Triage의 판별 기준이 보수적이어야 한다), Prompt(중립)

### [P-002] Evaluator-Optimizer 루프에 품질 기반 종료 조건 추가
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: SKILL.md, references/phase-a-planning.md, references/grind-phase-a.md
- **카테고리**: 워크플로 구조 / 품질/안전
- **현재 상태**: Step 2-4의 Plan Review 루프는 횟수 기반 종료만 있다 (simon-bot: max 3, grind: max 10). "계획의 품질이 충분한가?"를 구조적으로 평가하는 기준이 없어, 이미 좋은 계획도 최대 횟수까지 반복하거나, 나쁜 계획이 횟수를 채워 통과할 수 있다.
- **제안 내용**: Anthropic의 Evaluator-Optimizer 패턴을 명시적으로 적용한다. critic이 각 반복에서 구조화된 평가 점수(예: completeness, feasibility, safety, clarity 각 1-5점)를 부여하고, 모든 항목이 임계값(예: 4점) 이상이면 조기 종료한다. 임계값 미달 시에만 다음 반복으로 진행한다. 이를 통해 "좋은 계획은 빠르게 통과, 나쁜 계획은 끝까지 개선" 효과를 달성한다.
- **기대 효과**: 불필요한 반복 제거 (좋은 계획의 경우 1-2회에 종료 가능). 품질 기준의 명시화로 계획 품질 일관성 향상. grind에서 10회 반복의 효율성 대폭 개선.
- **근거**: 블로그의 Evaluator-Optimizer 패턴 — "works well when we have clear evaluation criteria, and when iterative refinement provides measurable value."
- **전문가 합의**: Architect(지지), Prompt(강력 지지 — 평가 기준 구조화가 핵심), Innovation(지지), Quality(강력 지지 — 품질 게이트 명확화), DX(지지 — 불필요한 대기 감소)

### [P-003] 에이전트 역할 정의에 ACI 원칙 적용 (Few-shot + 경계 명시)
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report
- **대상 파일**: references/phase-a-planning.md, references/phase-b-implementation.md, references/agent-teams.md (모든 에이전트 역할 정의 부분)
- **카테고리**: 프롬프트 품질
- **현재 상태**: 에이전트 역할(architect, planner, critic, executor 등)은 간략한 설명과 분석 항목 목록으로 정의되어 있다. Anthropic이 도구 정의에 요구하는 수준의 "example usage, edge cases, input format requirements, and clear boundaries from other tools"가 부족하다.
- **제안 내용**: 각 에이전트 역할 정의에 다음을 추가한다:
  - **Good Output Example**: 해당 에이전트가 만들어야 하는 출력물의 구체적 예시 (Few-shot)
  - **Boundary Clarification**: "이 에이전트가 하지 않는 것" 명시 (예: "architect는 코드를 직접 작성하지 않는다", "critic은 대안을 제시하지 않고 문제점만 지적한다")
  - **Input Format**: 에이전트가 받아야 하는 입력의 구조 명시
  - **Failure Mode**: 이 에이전트가 흔히 실수하는 패턴과 방지법
- **기대 효과**: 에이전트 출력의 일관성과 품질 향상. 역할 혼동으로 인한 "architect가 코드를 쓰고, executor가 설계를 하는" 상황 방지. 블로그의 "tool design deserves just as much prompt engineering attention as your overall prompts" 원칙 실현.
- **근거**: 블로그의 ACI 원칙 — "Ensure tool usage is obvious from descriptions and parameters"; "Include example usage, edge cases, input requirements"; 도구 설계에 "HCI 수준의 엄격함" 적용.
- **전문가 합의**: Prompt(강력 지지 — 핵심 개선), Architect(지지), Innovation(지지), Quality(지지 — 역할 혼동이 에러의 근본 원인 중 하나), DX(지지)

### [P-004] Ground Truth 검증 게이트 표준화
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: SKILL.md, references/phase-b-implementation.md, references/grind-phase-b.md
- **카테고리**: 품질/안전
- **현재 상태**: 일부 스텝(Step 5의 빌드 확인, Step 8의 리그레션 검증)에서 환경 피드백을 확인하지만, "매 스텝 후 환경으로부터 ground truth를 확인한다"는 체계적 프로토콜은 없다. 스텝 간 전이가 주로 에이전트의 자체 판단에 의존한다.
- **제안 내용**: Anthropic의 "agents must gain ground truth from the environment at each step" 원칙을 표준 프로토콜로 도입한다. 모든 코드 변경 스텝(Step 5, 6, 7-8, 9-16) 완료 후 반드시 환경 검증(빌드 성공, 테스트 통과, 타입체크)을 실행하고, 그 결과를 다음 스텝의 입력으로 전달하는 "Verification Gate" 패턴을 표준화한다. 게이트 실패 시에만 재시도/에스컬레이션 로직이 작동한다.
- **기대 효과**: 에러 축적(compounding errors) 조기 차단. 에이전트의 자체 판단에만 의존하지 않고 객관적 환경 피드백 기반 진행. grind에서 "의미 없는 재시도" (같은 빌드 에러를 반복 수정) 감소.
- **근거**: 블로그 — "agents must gain 'ground truth' from the environment at each step (such as tool call results or code execution) to assess its progress."
- **전문가 합의**: Quality(강력 지지 — 핵심 안전 개선), Architect(지지), Innovation(지지), Prompt(중립), DX(지지 — 무의미한 반복 대기 감소)

### [P-005] grind 재시도에 Progress Detection 도입
- **심각도**: HIGH
- **대상 스킬**: simon-bot-grind
- **대상 파일**: SKILL.md, references/grind-error-resilience.md, references/grind-phase-b.md
- **카테고리**: 품질/안전
- **현재 상태**: grind는 최대 10회 재시도를 하지만, "이전 시도 대비 진전이 있는가?"를 체계적으로 판별하지 않는다. Feedback-First Principle("Attempt 1-3에서는 빠르게 수정")은 좋지만, 에러가 동일한 근본 원인에서 반복되는지 감지하는 메커니즘이 `diagnosis_threshold: 5`로 늦다.
- **제안 내용**: 매 재시도 후 이전 시도의 환경 피드백(빌드 로그, 테스트 결과)과 현재 시도의 결과를 구조적으로 비교하는 "Progress Detection" 메커니즘을 도입한다. 비교 항목: (1) 실패하는 테스트 수의 변화, (2) 에러 메시지의 동일성, (3) 변경된 코드 라인 수. 진전이 없는 재시도가 2회 연속되면 즉시 전략 전환(현재의 5회 대기 대신)을 트리거한다.
- **기대 효과**: 무의미한 재시도 시간 절약. 블로그가 경고하는 "compounding errors" 위험 조기 대응. 컨텍스트 윈도우 낭비 방지.
- **근거**: 블로그 — "the potential for compounding errors"; "gain ground truth from the environment at each step to assess its progress."
- **전문가 합의**: Quality(강력 지지), Architect(지지), Innovation(지지), DX(강력 지지 — 사용자 대기 시간 감소), Prompt(중립)

### [P-006] 사용자 대면 투명성 프로토콜 (Decision Trail)
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: SKILL.md (Cross-Cutting Protocols 섹션), references/phase-a-planning.md, references/phase-b-implementation.md
- **카테고리**: DX
- **현재 상태**: 각 스텝 완료 시 메모리 파일에 결과를 기록하지만, 사용자에게 "지금 무엇을 왜 하고 있는지"를 실시간으로 보여주는 표준 프로토콜이 없다. User Interaction Recording은 사용자 발언을 기록하지만, 에이전트의 판단 근거를 보여주는 것은 아니다.
- **제안 내용**: Anthropic의 투명성 원칙("explicitly showing the agent's planning steps")을 구현하는 Decision Trail 프로토콜을 Cross-Cutting Protocol로 추가한다. 주요 판단 지점(경로 선택, 전문가 합의, 재시도 결정, 스텝 스킵 등)에서 사용자에게 1-2줄의 판단 근거를 제시한다. 형식 예: `[Decision] SMALL 경로 선택 — 변경 파일 3개, 외부 연동 없음, 단일 관심사.`
- **기대 효과**: 사용자가 워크플로의 진행을 이해하고 신뢰할 수 있게 됨. 잘못된 판단을 사용자가 조기에 교정할 기회 제공. 디버깅 시 "왜 이 경로를 탔는지" 추적 가능.
- **근거**: 블로그 — "Prioritize transparency by explicitly showing planning steps."
- **전문가 합의**: DX(강력 지지), Prompt(지지), Architect(지지), Quality(지지 — 잘못된 경로 조기 감지), Innovation(중립)

### [P-007] poka-yoke 원칙의 Global Forbidden Rules 강화
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: SKILL.md (Global Forbidden Rules 섹션)
- **카테고리**: 품질/안전
- **현재 상태**: Global Forbidden Rules는 "하지 마라" 목록으로 구성되어 있다. 이는 수동적 방어(위반 시 차단)에 해당한다.
- **제안 내용**: Anthropic의 poka-yoke 원칙("Change the arguments so that it is harder to make mistakes")을 적용하여, 금지 규칙의 일부를 "실수하기 어려운 구조"로 전환한다. 예: (1) `git push` 명령 사용 시 항상 `--dry-run`을 먼저 실행하도록 강제하는 프로토콜, (2) 데이터베이스 관련 명령은 읽기 전용 연결 문자열만 허용, (3) 파일 삭제 시 휴지통(`.claude/trash/`) 경유 강제. 금지 목록 자체는 유지하되, "위반을 시도하기 전에 안전한 경로로 자동 리디렉션"하는 능동적 방어 계층을 추가한다.
- **기대 효과**: 금지 규칙 위반 자체가 구조적으로 어려워짐. 에이전트의 실수로 인한 위반 가능성 감소.
- **근거**: 블로그 — "poka-yoke your tools. Change the arguments so that it is harder to make mistakes."
- **전문가 합의**: Quality(강력 지지), Architect(지지), DX(지지), Innovation(지지), Prompt(중립)

### [P-008] simon-bot-pm에 Orchestrator-Workers 패턴 명시화
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot-pm
- **대상 파일**: SKILL.md (Phase 4: Feature Execution)
- **카테고리**: 워크플로 구조
- **현재 상태**: simon-bot-pm의 Phase 4는 사전에 정의된 tasks.json의 실행 계획을 순서대로 실행한다. 실행 중에 새로운 Feature가 필요하거나 기존 Feature를 분할해야 하는 상황이 발생해도, 동적으로 작업을 재분해하는 메커니즘이 없다.
- **제안 내용**: Anthropic의 Orchestrator-Workers 패턴을 적용하여, Phase 4 실행 중에 PM(Orchestrator)이 각 Feature 결과를 평가하고, 필요 시 동적으로 작업을 추가/분할/재배치할 수 있는 "Dynamic Re-planning" 게이트를 각 execution group 완료 시점에 추가한다.
- **기대 효과**: 실행 중 발견된 예상치 못한 복잡성에 유연하게 대응. 블로그의 "subtasks aren't pre-defined, but determined by the orchestrator" 원칙에 부합.
- **근거**: 블로그의 Orchestrator-Workers 패턴 — "Suited for complex tasks where you can't predict the subtasks needed."
- **전문가 합의**: Architect(강력 지지), Innovation(지지), DX(지지 — 사용자가 수동으로 재계획할 필요 감소), Quality(조건부 동의 — 재계획 시 사용자 확인 필요), Prompt(중립)

### [P-009] simon-bot-report에 Parallelization Voting 패턴 도입
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot-report
- **대상 파일**: SKILL.md (Step 3: Domain Expert Team Discussion)
- **카테고리**: 신기법 도입
- **현재 상태**: Step 3의 5개 도메인팀은 각각 다른 관점에서 분석한다 (Sectioning 패턴). 그러나 동일 관점에서 복수의 분석을 수행하여 다양한 출력을 확보하는 Voting 패턴은 활용하지 않는다.
- **제안 내용**: CRITICAL severity 후보 항목에 대해, Safety Team이 동일 항목을 2-3회 독립 분석하여 일관되게 CRITICAL로 판정되는지 확인하는 Voting 검증 단계를 추가한다. Voting 합의에 실패하면 (예: 3회 중 1회만 CRITICAL) severity를 재평가한다.
- **기대 효과**: CRITICAL 판정의 신뢰도 향상. 과잉 경고(false alarm) 감소.
- **근거**: 블로그의 Parallelization Voting 변형 — "Running the same task multiple times to get diverse outputs"; "Content appropriateness evaluation with threshold management."
- **전문가 합의**: Innovation(강력 지지), Quality(지지), Architect(조건부 — 비용 대비 효과 검증 필요), DX(중립), Prompt(지지)

### [P-010] simon-bot-sessions 복원 시 Context Dashboard 제공
- **심각도**: LOW
- **대상 스킬**: simon-bot-sessions
- **대상 파일**: SKILL.md (resume 섹션)
- **카테고리**: DX
- **현재 상태**: resume 시 `.claude/memory/` 파일들을 읽어 맥락을 복원하고 "현재 상태 요약 보고"를 하지만, 보고의 형식과 내용이 표준화되어 있지 않다.
- **제안 내용**: resume 시 표준화된 Context Dashboard를 제시한다:
  ```
  === Session Resume: {branch-name} ===
  Phase: B (Implementation) | Step: 7/19 (Bug/Security Review)
  Last Action: Step 6 완료 (Purpose Alignment PASS)
  Pending Issues: 0 CRITICAL, 2 HIGH
  Test Status: 47/50 passing (3 skipped)
  Context Files: plan-summary.md, code-design-analysis.md, requirements.md
  Decision Trail: [Step 0] STANDARD path | [Step 1-B] 3-round interview
  Next Step: Step 7 — 도메인팀 에이전트 리뷰 시작
  ===
  ```
- **기대 효과**: 세션 복원 시 사용자가 즉시 상황을 파악. 블로그의 투명성 원칙과 human-in-the-loop 체크포인트 패턴에 부합.
- **근거**: 블로그 — "agents can pause for human feedback at checkpoints"; 투명성 원칙.
- **전문가 합의**: DX(강력 지지), Architect(지지), Quality(지지), Prompt(지지), Innovation(중립)

### [P-011] 프레임워크 추상화 최소화 가이드라인 추가
- **심각도**: LOW
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: SKILL.md (Cross-Cutting Protocols), references/agent-teams.md
- **카테고리**: 워크플로 구조
- **현재 상태**: Agent Teams, subagent spawn, background agents 등 다층적 에이전트 오케스트레이션을 활용하지만, "이 추상화가 정말 필요한가?"를 판단하는 가이드라인이 없다.
- **제안 내용**: Anthropic의 경고 — "frameworks create extra layers of abstraction that can obscure the underlying prompts and responses" — 를 반영하여, 에이전트 오케스트레이션 사용 시 "단일 에이전트로 충분한가?"를 먼저 판단하는 가이드라인을 Cross-Cutting Protocol에 추가한다. Agent Team은 진정한 다관점 토론이 필요할 때만 사용하고, 단순 순차 작업은 단일 에이전트의 Chain-of-Thought로 처리하도록 권장한다.
- **기대 효과**: 불필요한 에이전트 오버헤드 감소. 컨텍스트 윈도우 효율성 향상.
- **근거**: 블로그 — "don't hesitate to reduce abstraction layers and build with basic components as you move to production."
- **전문가 합의**: Architect(지지), DX(지지), Innovation(중립 — 이미 Agent Teams를 잘 활용하고 있음), Quality(중립), Prompt(지지)

---

## Cross-Cutting Observations

### 1. 단순함과 견고함의 균형
simon-bot 계열 스킬은 **견고함(Rigor)** 에 최적화되어 있다. 19개 스텝, 5개 도메인팀, 10회 재시도 등 모든 설계가 "최고 품질"을 목표로 한다. 블로그는 이를 부정하지 않지만, "add complexity only when it demonstrably improves outcomes"라는 원칙을 통해 **상황에 따른 유연한 복잡도 조절**을 강조한다. P-001(조건부 라우팅), P-002(품질 기반 종료), P-011(추상화 최소화)은 모두 이 균형점을 찾기 위한 제안이다.

### 2. 환경 피드백 체계의 표준화
블로그의 가장 강력한 메시지 중 하나인 "ground truth from the environment"는 simon-bot 전체에 걸쳐 표준 프로토콜로 승격되어야 한다. 현재는 일부 스텝에서만 빌드/테스트 확인이 이루어지며, P-004(Verification Gate)와 P-005(Progress Detection)는 이를 체계화하는 쌍둥이 제안이다.

### 3. 에이전트 인터페이스의 품질
블로그의 ACI 원칙은 도구뿐 아니라 에이전트 역할 정의에도 적용된다. simon-bot의 모든 에이전트 역할(architect, planner, critic, executor, 각 도메인 전문가 등)은 사실상 "내부 도구"이며, P-003의 ACI 원칙 적용은 전 스킬에 걸친 공통 개선이다.

### 4. 투명성의 사용자 가치
블로그가 강조하는 투명성은 P-006(Decision Trail)과 P-010(Context Dashboard)으로 구체화되지만, 더 넓게는 **모든 스킬이 "지금 무엇을 왜 하고 있는지"를 사용자에게 보여주는 표준 프로토콜**이 필요하다. 이는 User Interaction Recording과는 반대 방향 — 사용자의 말을 기록하는 것이 아니라, 에이전트의 판단을 사용자에게 보여주는 것 — 이다.

---

## Not Recommended

### 1. 전체 파이프라인을 단순 Prompt Chaining으로 축소
블로그의 Prompt Chaining 패턴은 "고정된 하위 작업으로 깨끗하게 분해 가능한 작업"에 적합하다. simon-bot의 19-step 파이프라인은 하위 작업 간에 복잡한 피드백 루프(Step 2-4의 반복, Step 7-8의 리뷰-수정 루프)가 있어 순수 Chaining으로 축소하면 품질이 심각하게 저하된다. **조건부 라우팅(P-001)으로 부분 최적화하되, 전체 구조는 유지하는 것이 옳다.**

### 2. Agent Teams 완전 폐지
블로그의 "reduce abstraction layers" 조언을 극단적으로 해석하여 Agent Teams를 완전히 제거하는 것은 부적절하다. simon-bot의 Agent Team 토론 구조(Step 4-B의 도메인팀, Code Design Team)는 단일 에이전트로는 달성하기 어려운 다관점 분석을 제공한다. **P-011에서 제안한 대로 "필요성 판단 가이드라인"을 추가하되, Agent Teams 자체는 유지해야 한다.**

### 3. Voting 패턴의 전면 도입
블로그의 Voting 패턴(동일 작업을 여러 번 실행)은 비용이 높다. simon-bot의 모든 리뷰 스텝에 Voting을 도입하면 비용이 2-3배 증가한다. **P-009에서 제안한 대로 CRITICAL 판정 검증에만 선택적으로 적용하는 것이 적절하다.**

### 4. 사용자 인터랙션 완전 제거 (Full Autonomy)
블로그는 에이전트의 자율성을 인정하면서도 "human review remains crucial"과 "pause for human feedback at checkpoints"를 강조한다. simon-bot의 AskUserQuestion 기반 인터랙션을 제거하여 완전 자율 에이전트로 만드는 것은 블로그의 조언에 반한다. **현재의 인터랙션 지점은 유지하되, P-006(Decision Trail)로 인터랙션의 품질을 높이는 것이 옳다.**

### 5. 에러 재시도 횟수 감소 (grind의 10 → 3)
블로그의 "simplicity" 원칙으로 grind의 재시도 횟수를 줄이는 것은 grind의 존재 이유("끝날 때까지 끝난 게 아니다")를 훼손한다. **대신 P-005(Progress Detection)로 무의미한 재시도를 조기 차단하는 것이 더 나은 접근이다.**
