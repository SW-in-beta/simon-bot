# simon-bot Boost Report

## Source
- **자료**: [Prompting best practices](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/claude-prompting-best-practices) (Anthropic Official Prompt Engineering Guide)
- **분석일**: 2026-03-06

## Executive Summary

Anthropic의 최신 프롬프트 엔지니어링 가이드를 simon-bot 계열 5개 스킬과 교차 분석한 결과, 12개의 개선 제안을 도출했다. 가장 핵심적인 발견은: (1) simon-bot 스킬들의 에이전트 지시문이 "왜(WHY)" 맥락 없이 "무엇을(WHAT)" 위주로 작성되어 있어 Claude 4.6의 맥락 기반 일반화 능력을 충분히 활용하지 못하고 있고, (2) 과잉 트리거링을 유발할 수 있는 강압적 언어(MUST, NEVER, CRITICAL, MANDATORY)가 과도하게 사용되고 있으며, (3) 병렬 도구 호출과 subagent 위임의 최적화 가이드가 부재하고, (4) few-shot 예시와 XML 태그 구조화라는 검증된 기법이 에이전트 프롬프트에 거의 활용되지 않고 있다는 점이다. 이 개선들을 적용하면 에이전트 행동의 정확도, 컨텍스트 효율성, 사용자 경험이 의미있게 향상될 것으로 기대한다.

## Improvement Proposals

### [P-001] 에이전트 지시문에 "왜(WHY)" 맥락 추가 — 동기 기반 지시로 전환
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report
- **대상 파일**: SKILL.md, references/phase-a-planning.md, references/phase-b-implementation.md, references/error-resilience.md
- **카테고리**: 프롬프트 품질
- **현재 상태**: 현재 대부분의 지시문이 "무엇을 하라"만 기술한다. 예: "Tests: NEVER use real DB or external APIs (mock/stub only)" -- 왜 안 되는지 맥락이 없다. Global Forbidden Rules도 일부만 이유를 기술하고, 나머지는 행위만 나열한다. 에이전트 spawn 시 역할 기술도 "convention-expert: 네이밍 규칙, 디렉토리 구조..." 식으로 할 일만 나열된다.
- **제안 내용**: 가이드의 "Add context to improve performance" 원칙을 적용하여, 핵심 지시문에 동기/맥락을 추가한다. 모든 규칙에 일일이 추가할 필요는 없고, 위반 시 심각한 결과를 초래하는 규칙, 에이전트가 반복적으로 어기는 규칙, 맥락이 있으면 일반화가 가능한 규칙을 우선 대상으로 한다. 예: "Tests: NEVER use real DB or external APIs (mock/stub only)" 를 "Tests: NEVER use real DB or external APIs. 테스트가 실제 시스템에 부작용을 일으키면 프로덕션 데이터가 손상되거나 외부 서비스에 의도치 않은 요청이 발생한다. mock/stub만 사용하라."로 변경. 이렇게 하면 Claude가 유사한 상황(예: 테스트에서 실제 메시지 큐 접속)에도 같은 원칙을 자발적으로 적용한다.
- **기대 효과**: Claude 4.6은 맥락에서 일반화하는 능력이 뛰어나므로, 이유를 알려주면 명시적으로 나열하지 않은 유사 상황에서도 올바르게 행동할 확률이 높아진다. 규칙의 정신을 이해하게 되어 "규칙에 적시되지 않은 변종" 위반이 줄어든다.
- **근거**: 가이드의 "Add context to improve performance" 섹션 -- "Providing context or motivation behind your instructions... can help Claude better understand your goals and deliver more targeted responses." + "Claude is smart enough to generalize from the explanation."
- **전문가 합의**: Prompt Engineer(주도), Quality & Safety Guardian(강력 동의 -- 안전 규칙의 맥락 이해가 특히 중요), Workflow Architect(동의), DX Specialist(동의 -- 에이전트가 맥락을 이해하면 불필요한 사용자 질문도 줄어듦), Innovation Scout(동의)

---

### [P-002] 강압적 언어 톤다운 — Claude 4.6 과잉 트리거링 방지
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report
- **대상 파일**: SKILL.md (전체), references/* (전체)
- **카테고리**: 프롬프트 품질
- **현재 상태**: 스킬 전반에 "ABSOLUTE RULE", "MANDATORY", "MUST", "NEVER", "CRITICAL", "반드시", "절대", "금지" 등 강압적 언어가 빈번하게 사용된다. 예: "MANDATORY TDD Cycle", "ABSOLUTE RULE: 워크플로는... 절대 중단되지 않는다", "검증 통과 전까지 다음 Step 진행 금지", "하나라도 미충족이면 완료 불가". 이전 모델에서는 이런 강조가 필요했을 수 있으나, Claude 4.6에서는 역효과를 낼 수 있다.
- **제안 내용**: 가이드의 조언("Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'")에 따라, 강압적 언어를 단계적으로 톤다운한다. 전략: (1) 진짜 safety-critical한 규칙(Global Forbidden Rules)은 강한 언어 유지, (2) 워크플로 흐름 제어("다음 Step 진행 금지" 등)는 자연스러운 조건문 형태로("테스트가 모두 통과한 후에 다음 단계로 진행한다"), (3) 품질 관련 지시("MANDATORY TDD")는 이유와 함께 부드럽게("TDD 사이클을 따른다. RED-GREEN-REFACTOR를 통해 구현이 요구사항을 정확히 만족하는지 확인할 수 있다").
- **기대 효과**: Claude 4.6이 불필요하게 과잉 반응하거나, 사소한 조건 미충족에 경직되게 멈추는 현상을 방지한다. 전체적인 지시 따르기(instruction following) 정확도가 오히려 향상될 수 있다.
- **근거**: 가이드의 "Tool usage" 섹션 -- "Claude Opus 4.5 and Claude Opus 4.6 are also more responsive to the system prompt than previous models. If your prompts were designed to reduce undertriggering on tools or skills, these models may now overtrigger. The fix is to dial back any aggressive language."
- **전문가 합의**: Prompt Engineer(주도), Innovation Scout(강력 동의), DX Specialist(동의), Workflow Architect(조건부 동의 -- safety-critical 규칙은 유지해야), Quality & Safety Guardian(부분 동의 -- Global Forbidden Rules의 강도는 절대 약화시키지 말 것. 이는 기존 Global Rules와도 일치)

---

### [P-003] 에이전트 프롬프트에 Few-shot 예시 도입
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: references/phase-a-planning.md (Step 1-B 계획서), references/phase-b-implementation.md (Step 5 TDD), references/integration-and-review.md (Step 18-B review-sequence)
- **카테고리**: 프롬프트 품질 / 신기법 도입
- **현재 상태**: 에이전트(planner, executor, architect 등)에게 spawn 시 주어지는 프롬프트에 구체적인 출력 예시가 거의 없다. 계획서 구조(STICC), 커밋 메시지 형식, review-payload 구조 등이 템플릿으로 주어지지만, "좋은 출력"과 "나쁜 출력"을 대비하는 few-shot 예시는 없다. 특히 plan-summary.md의 품질이 초기 계획 작성 시마다 들쑥날쑥할 수 있다.
- **제안 내용**: 가이드의 "Use examples effectively" 원칙에 따라, 핵심 에이전트 프롬프트에 1-2개의 구체적 few-shot 예시를 `<example>` 태그로 추가한다. 대상: (1) Step 1-B 계획서의 "End State" 섹션 -- 잘 작성된 Files Changed 테이블 + Behavior Changes 예시 1개, (2) Step 5 TDD 사이클 -- RED-GREEN-REFACTOR의 구체적 코드 변경 흐름 예시 1개, (3) Step 18-B review-sequence -- 좋은 논리적 변경 단위 그룹핑 예시 1개. 예시는 간결하게 유지하되, 출력 형식과 수준을 명확히 보여준다.
- **기대 효과**: 에이전트 출력의 일관성과 품질이 극적으로 향상된다. 가이드에 따르면 "A few well-crafted examples can dramatically improve accuracy and consistency."
- **근거**: 가이드의 "Use examples effectively" 섹션 + "Include 3-5 examples for best results."
- **전문가 합의**: Prompt Engineer(주도), DX Specialist(강력 동의 -- 결과물 품질이 일관되면 사용자 수정 요청이 줄어듦), Workflow Architect(동의), Quality & Safety Guardian(동의), Innovation Scout(동의)

---

### [P-004] 병렬 도구 호출 최적화 지시 추가
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report
- **대상 파일**: SKILL.md (Cross-Cutting Protocols 섹션), references/phase-b-implementation.md
- **카테고리**: 워크플로 구조 / 프롬프트 품질
- **현재 상태**: simon-bot은 "병렬 실행"을 Unit 수준(background agent)과 Agent Teams로 지원하지만, 개별 에이전트가 도구를 병렬로 호출하는 것에 대한 명시적 가이드가 없다. 예: executor가 여러 파일을 읽거나, architect가 여러 모듈을 동시에 탐색할 때 순차 호출하면 불필요하게 느려진다. Step 1-A의 "병렬로 실행" 지시는 있지만, 이는 스킬 문서 수준의 단계 병렬이지 에이전트 내부의 도구 호출 병렬이 아니다.
- **제안 내용**: Cross-Cutting Protocols에 병렬 도구 호출 최적화 지시를 추가한다. 가이드에서 제공하는 프롬프트를 simon-bot 맥락에 맞게 재해석: "독립적인 도구 호출(파일 읽기, grep, glob 등)은 병렬로 실행한다. 의존성이 있는 호출(이전 결과가 다음 파라미터에 필요한 경우)만 순차 실행한다. 특히 Step 1-A 코드 탐색, Step 5 구현, Step 7 리뷰에서 여러 파일을 동시에 읽어 컨텍스트를 빠르게 확보하라."
- **기대 효과**: 에이전트의 작업 속도가 향상되고, 컨텍스트 윈도우 사용이 효율적으로 된다.
- **근거**: 가이드의 "Optimize parallel tool calling" 섹션 -- "These models will run multiple speculative searches during research, read several files at once to build context faster."
- **전문가 합의**: Workflow Architect(주도), Innovation Scout(강력 동의), DX Specialist(동의 -- 속도 향상은 직접적 DX 개선), Prompt Engineer(동의), Quality & Safety Guardian(동의)

---

### [P-005] Subagent 과잉 위임 방지 가이드 추가
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: SKILL.md (Cross-Cutting Protocols), references/agent-teams.md
- **카테고리**: 워크플로 구조 / 품질.안전
- **현재 상태**: simon-bot은 거의 모든 작업을 subagent/Agent Team에 위임하는 구조다. 이는 복잡한 작업에 적합하지만, 가이드에 따르면 Claude Opus 4.6은 subagent를 과도하게 생성하는 경향이 있다. 현재 스킬에는 "언제 subagent가 불필요한지"에 대한 가이드가 없다. 예: 단순한 파일 수정에도 executor를 spawn하거나, 간단한 grep으로 해결 가능한 탐색에도 explore-medium을 생성할 수 있다.
- **제안 내용**: agent-teams.md 또는 Cross-Cutting Protocols에 subagent 사용 기준을 추가한다. "subagent는 (1) 독립적 컨텍스트가 필요한 병렬 작업, (2) 다른 전문성이 필요한 역할 분리, (3) 대량의 코드를 탐색해야 하는 경우에 사용한다. 단일 파일 수정, 간단한 검색, 단순 명령 실행은 직접 수행한다."
- **기대 효과**: 불필요한 subagent 오버헤드가 줄어들고, 컨텍스트 윈도우 효율성이 향상된다.
- **근거**: 가이드의 "Subagent orchestration" 섹션 -- "Claude Opus 4.6 has a strong predilection for subagents and may spawn them in situations where a simpler, direct approach would suffice."
- **전문가 합의**: Workflow Architect(주도), DX Specialist(동의 -- 불필요한 대기 시간 감소), Innovation Scout(동의), Prompt Engineer(동의), Quality & Safety Guardian(조건부 동의 -- 격리가 필요한 위험 작업은 여전히 subagent 필요)

---

### [P-006] 컨텍스트 윈도우 인식 + 자율 지속 지시 강화
- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: SKILL.md (Context Window Management 섹션)
- **카테고리**: 워크플로 구조 / DX
- **현재 상태**: simon-bot은 "세션 분할 경계"를 정의하고 있어 컨텍스트 부족 시 어디서 끊을지 가이드한다. 하지만 가이드가 강조하는 두 가지가 부재하다: (1) "컨텍스트 소진이 다가와도 조기에 멈추지 말라"는 지시, (2) 컨텍스트 전환 시 상태 저장/복원을 위한 구체적 프로토콜. 현재는 복원 가이드가 ".claude/memory/ + CONTEXT.md 읽기"로 간략하게만 되어 있다.
- **제안 내용**: Context Window Management 섹션에 두 가지를 추가한다. (1) 자율 지속 지시: "컨텍스트 윈도우가 자동으로 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다. 예산 한계가 다가오면 현재 진행 상태와 다음 할 일을 .claude/memory/에 저장한 후 자연스럽게 이어간다." (2) 새 컨텍스트 시작 프로토콜: "새 세션에서 재개할 때: (a) pwd 확인, (b) CONTEXT.md + .claude/memory/*.md 읽기, (c) git log로 최근 변경 확인, (d) 마지막 완료된 Step 이후부터 재개."
- **기대 효과**: 긴 작업(STANDARD/LARGE path)에서 에이전트가 "컨텍스트가 부족합니다"라며 조기 종료하는 현상을 방지하고, 세션 간 전환이 매끄러워진다.
- **근거**: 가이드의 "Context awareness and multi-window workflows" 섹션 -- "do not stop tasks early due to token budget concerns... save your current progress and state to memory before the context window refreshes."
- **전문가 합의**: Workflow Architect(주도), DX Specialist(강력 동의), Innovation Scout(동의), Quality & Safety Guardian(동의 -- 상태 저장 프로토콜이 데이터 무결성을 보장), Prompt Engineer(동의)

---

### [P-007] Self-correction 패턴 명시적 도입
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: references/phase-b-implementation.md (Step 5, Step 12), references/integration-and-review.md (Step 18)
- **카테고리**: 신기법 도입
- **현재 상태**: simon-bot은 이미 많은 검증 단계(Step 6 Purpose Alignment, Step 7 Review, Step 8 Regression 등)를 가지고 있으나, 이들은 "다른 에이전트가 검증하는" 구조다. 가이드가 권장하는 "자기 검증(self-check)" 패턴 -- 에이전트가 자기 출력을 스스로 검증하는 것 -- 은 명시적으로 도입되어 있지 않다. 특히 executor가 구현을 완료한 직후, 다음 검증 단계로 넘기기 전에 자체 점검을 하면 불필요한 왕복을 줄일 수 있다.
- **제안 내용**: Step 5 구현 완료 후, Step 6으로 넘기기 전에 executor 자체 검증 단계를 추가한다: "구현을 완료하기 전에, plan-summary.md의 Acceptance Criteria와 대조하여 누락된 항목이 없는지 확인하라. 특히 End State의 Files Changed 테이블과 실제 변경을 비교하라." 마찬가지로 Step 18 보고서 작성 시 writer에게: "보고서 초안 완성 후, plan-summary.md의 핵심 결정사항이 모두 반영되었는지 확인하라."
- **기대 효과**: 에이전트 간 불필요한 왕복(executor -> architect -> executor 반복)이 줄어들어 전체 워크플로 속도가 향상되고, 더 높은 품질의 첫 결과물이 나온다.
- **근거**: 가이드의 Thinking 섹션 -- "Ask Claude to self-check. Append something like 'Before you finish, verify your answer against [test criteria].' This catches errors reliably, especially for coding and math."
- **전문가 합의**: Prompt Engineer(주도), Workflow Architect(동의 -- 왕복 감소는 구조적 효율), Innovation Scout(동의), Quality & Safety Guardian(동의), DX Specialist(동의)

---

### [P-008] 과잉 엔지니어링 방지 지시 추가 (simon-bot-pm 특히)
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-pm
- **대상 파일**: simon-bot/references/phase-b-implementation.md (Step 5), simon-bot-pm/SKILL.md (Phase 3, Phase 4)
- **카테고리**: 프롬프트 품질 / DX
- **현재 상태**: simon-bot에는 Step 4 Over-engineering Check (YAGNI/KISS)가 있어 계획 단계에서 과잉을 잡지만, 구현 단계(Step 5)에서 executor가 실제 코드를 작성할 때의 과잉 엔지니어링 방지 지시가 없다. simon-bot-pm은 전체 프로젝트를 다루므로 Phase 3 scaffolding과 Phase 4 feature execution에서 과잉 가능성이 더 높다. 가이드에 따르면 Claude 4.6은 "extra files, unnecessary abstractions, flexibility that wasn't requested"를 만드는 경향이 있다.
- **제안 내용**: Step 5 executor 프롬프트와 simon-bot-pm Phase 4 feature spec에 과잉 엔지니어링 방지 가이드를 추가한다. 가이드의 프롬프트를 simon-bot 맥락으로 재해석: "plan-summary.md에 명시된 변경만 구현한다. 코드 품질 개선, 리팩토링, 추가 추상화는 계획에 포함된 경우에만 수행한다. 변경하지 않는 코드에 docstring/주석/타입 어노테이션을 추가하지 않는다. 현재 요구사항에 필요하지 않은 방어적 코딩이나 에러 핸들링을 추가하지 않는다."
- **기대 효과**: 구현 범위가 계획에 충실하게 유지되어, Step 6-8 검증에서 "계획에 없는 변경" 관련 지적이 줄어들고, 전체 워크플로 시간이 단축된다.
- **근거**: 가이드의 "Overeagerness" 섹션 -- "Claude Opus 4.5 and Claude Opus 4.6 have a tendency to overengineer... add specific guidance to keep solutions minimal."
- **전문가 합의**: Workflow Architect(주도), DX Specialist(동의), Prompt Engineer(동의), Innovation Scout(동의), Quality & Safety Guardian(조건부 동의 -- 보안 관련 방어적 코딩은 예외로 허용해야)

---

### [P-009] 환각 방지 지시 추가 — "조사 후 답변" 원칙
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-report
- **대상 파일**: simon-bot/references/phase-b-implementation.md (Step 7, Step 12), simon-bot-report/SKILL.md (Step 3)
- **카테고리**: 품질.안전
- **현재 상태**: 코드 리뷰 단계(Step 7, Step 12)에서 리뷰어 에이전트가 실제 코드를 열어보지 않고 추측 기반으로 지적하는 환각 리스크가 있다. simon-bot-report의 전문가 토론에서도 탐색 결과에 없는 코드 패턴을 "있다"고 주장할 수 있다. 현재 이에 대한 명시적 방지 지시가 없다.
- **제안 내용**: 리뷰/분석 에이전트 프롬프트에 환각 방지 지시를 추가한다: "읽지 않은 코드에 대해 추측하지 않는다. 사용자가 언급하거나 계획에 포함된 파일은 반드시 Read로 열어본 후에 의견을 제시한다. 확실하지 않으면 확인 후 답변한다." 이 지시를 `<investigate_before_answering>` XML 태그로 감싸 명확하게 분리한다.
- **기대 효과**: 코드 리뷰와 분석의 신뢰성이 향상되고, "존재하지 않는 문제"를 수정하느라 시간을 낭비하는 일이 줄어든다.
- **근거**: 가이드의 "Minimizing hallucinations in agentic coding" 섹션 -- "Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering."
- **전문가 합의**: Quality & Safety Guardian(주도), Prompt Engineer(강력 동의), Workflow Architect(동의), DX Specialist(동의), Innovation Scout(동의)

---

### [P-010] XML 태그 구조화로 에이전트 프롬프트 명확성 향상
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: references/phase-a-planning.md, references/phase-b-implementation.md, references/agent-teams.md
- **카테고리**: 프롬프트 품질
- **현재 상태**: 에이전트 spawn 시 프롬프트가 자연어로 구성되어 있으며, 지시사항(instructions), 컨텍스트(context), 참조 파일 경로(references), 기대 출력 형식(output format)이 명확히 분리되지 않는다. 예: Step 4-B 전문가 팀원 프롬프트에서 역할 설명, 작업 지시, 출력 형식, 참조 파일이 산문으로 혼재한다.
- **제안 내용**: 핵심 에이전트 프롬프트(executor, architect, planner, reviewer 등)의 구조를 XML 태그로 정리한다. 예시 구조: `<role>`, `<context_files>`, `<instructions>`, `<constraints>`, `<output_format>`. 모든 에이전트 프롬프트를 한꺼번에 바꿀 필요 없이, 가장 중요한 executor(Step 5)와 planner(Step 1-B) 프롬프트부터 적용한다.
- **기대 효과**: 에이전트가 지시의 각 부분(무엇을 해야 하는지, 어떤 맥락인지, 무엇을 출력해야 하는지)을 더 정확하게 구분하여 오해석이 줄어든다.
- **근거**: 가이드의 "Structure prompts with XML tags" 섹션 -- "XML tags help Claude parse complex prompts unambiguously, especially when your prompt mixes instructions, context, examples, and variable inputs."
- **전문가 합의**: Prompt Engineer(주도), Innovation Scout(동의), Workflow Architect(동의), DX Specialist(동의), Quality & Safety Guardian(동의)

---

### [P-011] 하드코딩/테스트 통과 집착 방지 지시 추가
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: references/phase-b-implementation.md (Step 5)
- **카테고리**: 품질.안전
- **현재 상태**: simon-bot은 TDD를 강제하며 "전체 테스트 스위트 통과"를 요구한다. 이것 자체는 좋지만, 가이드는 Claude가 "테스트를 통과시키기 위해 하드코딩하거나, 특정 테스트 입력에만 동작하는 해결책"을 만들 수 있다고 경고한다. simon-bot-grind에서 retry가 많아질수록 이 위험이 커진다 -- 10번째 시도에서 "일단 테스트만 통과시키자"는 유혹이 있다.
- **제안 내용**: Step 5 TDD 사이클에 다음 지시를 추가한다: "테스트를 통과시키기 위해 특정 테스트 입력값을 하드코딩하지 않는다. 모든 유효한 입력에 대해 올바르게 동작하는 일반적 해결책을 구현한다. 테스트는 정확성을 검증하는 도구이지, 해결책을 정의하는 것이 아니다. 테스트가 부정확하다고 판단되면, 테스트를 우회하지 말고 이를 보고하라." simon-bot-grind에도 동일 지시를 retry 컨텍스트에 추가한다.
- **기대 효과**: 구현 코드의 일반성과 견고함이 향상되며, 특히 grind 모드의 많은 retry에서도 품질이 유지된다.
- **근거**: 가이드의 "Avoid focusing on passing tests and hard-coding" 섹션 전체
- **전문가 합의**: Quality & Safety Guardian(주도), Prompt Engineer(동의), Workflow Architect(동의), Innovation Scout(동의), DX Specialist(동의)

---

### [P-012] simon-bot-sessions 컨텍스트 복원 프로토콜 강화
- **심각도**: LOW
- **대상 스킬**: simon-bot-sessions
- **대상 파일**: SKILL.md (resume 섹션)
- **카테고리**: DX
- **현재 상태**: simon-bot-sessions의 resume 플로우는 .claude/memory/ 파일들을 읽어 맥락을 복원하지만, 가이드가 권장하는 다단계 복원 프로토콜(파일시스템 탐색 + git log + 테스트 실행)이 빠져있다. 특히 git log로 마지막 작업 이력을 확인하는 단계가 없어, 세션 복원 시 "어디까지 했는지"를 정확히 파악하기 어려울 수 있다.
- **제안 내용**: resume 플로우에 추가 단계를 넣는다: (1) `.claude/memory/` 파일 읽기 (기존), (2) `git log --oneline -10`으로 최근 커밋 확인 (신규), (3) `CONTEXT.md` 읽어 마지막 완료된 Step 확인 (강화), (4) `git status`로 미커밋 변경사항 확인 (신규). 이렇게 하면 memory 파일에 기록되지 않은 작업도 git에서 발견할 수 있다.
- **기대 효과**: 세션 복원의 정확도가 높아지고, "이전 작업 상태를 정확히 몰라서 처음부터 다시 하는" 상황이 줄어든다.
- **근거**: 가이드의 "Multi-context window workflows" 섹션 -- "Review progress.txt, tests.json, and the git logs." + "Use git for state tracking: Git provides a log of what's been done and checkpoints that can be restored."
- **전문가 합의**: DX Specialist(주도), Workflow Architect(동의), Innovation Scout(동의), Quality & Safety Guardian(동의), Prompt Engineer(동의)

---

## Cross-Cutting Observations

### 1. "지시의 맥락화"는 가장 높은 ROI를 가진 개선이다
P-001(WHY 맥락 추가)은 모든 스킬에 걸쳐 적용 가능하며, 구현 비용이 낮고 효과가 크다. 가이드가 반복적으로 강조하는 핵심 원칙이기도 하다. 모든 다른 제안보다 먼저 적용하는 것을 권장한다.

### 2. Claude 4.6 시대에 맞는 "톤 보정"이 필요하다
P-002(강압적 언어 톤다운)와 P-005(subagent 과잉 방지)는 같은 근본 원인에서 비롯된다: simon-bot 스킬이 이전 세대 모델의 한계를 보완하기 위해 만들어진 패턴을 여전히 유지하고 있다는 점. Claude 4.6의 향상된 지시 따르기 능력에 맞춰 전체적인 톤과 전략을 업데이트할 필요가 있다.

### 3. 구조(XML) + 예시(Few-shot) 조합이 에이전트 품질을 결정한다
P-003(Few-shot 예시)과 P-010(XML 태그 구조화)은 함께 적용할 때 시너지가 크다. 구조화된 프롬프트 안에 구조화된 예시를 넣으면, 에이전트 출력의 일관성이 극적으로 향상될 수 있다.

### 4. simon-bot-report는 현재 상태가 가장 양호하다
simon-bot-report는 이미 에이전트 간 역할 분리, 구조화된 출력 형식, 단계적 리뷰를 잘 갖추고 있다. P-009(환각 방지)만 추가하면 충분하다.

### 5. simon-bot-grind의 retry 집중적 특성상 추가 보호가 필요하다
P-011(하드코딩 방지)은 simon-bot에서도 적용 가능하지만, simon-bot-grind에서 특히 중요하다. 10회 retry 동안 품질을 유지하려면 "테스트 통과가 목적이 아니라 올바른 구현이 목적"이라는 원칙이 강하게 각인되어야 한다.

## Not Recommended

### 1. Prefill 제거 마이그레이션 -- 해당 없음
가이드가 "prefilled responses on the last assistant turn are no longer supported"라고 안내하지만, simon-bot 스킬들은 API 호출 수준이 아닌 Claude Code 에이전트 수준에서 동작하므로 prefill을 사용하지 않는다. 마이그레이션 대상이 아니다.

### 2. Adaptive Thinking 설정 변경 -- 스킬 수준에서 제어 불가
가이드가 adaptive thinking과 effort 파라미터를 상세히 다루지만, 이는 API 호출 수준의 설정이다. SKILL.md에서 에이전트의 thinking 방식을 직접 제어할 수 없으므로, 이 제안은 채택하지 않는다. 다만 P-002의 톤다운이 간접적으로 thinking 효율에 긍정적 영향을 줄 수 있다.

### 3. 프론트엔드 디자인 스킬 도입 -- 범위 외
가이드의 Frontend Design 섹션은 UI 중심 프로젝트에 유용하지만, simon-bot은 범용 코드 워크플로 스킬이므로 프론트엔드 특화 지시를 포함시키는 것은 적절하지 않다. 필요 시 별도 스킬로 분리하는 것이 맞다.

### 4. Structured Outputs (JSON schema) 강제 -- 과도한 제약
가이드가 Structured Outputs를 도구 호출이나 분류에 권장하지만, simon-bot 에이전트의 출력은 마크다운 문서가 대부분이므로 JSON schema를 강제하는 것은 유연성을 해칠 수 있다. 다만 tasks.json(simon-bot-pm)이나 review-payload.json 같은 구조화된 출력에는 이미 적용되어 있다.

### 5. 모든 에이전트 프롬프트에 `<thinking>` 태그 예시 삽입 -- 비용 대비 효과 불확실
가이드가 "Multishot examples work with thinking. Use `<thinking>` tags inside your few-shot examples"라고 안내하지만, 모든 에이전트 프롬프트에 thinking 예시까지 넣으면 프롬프트가 과도하게 길어져 컨텍스트 효율이 떨어진다. P-003의 few-shot 예시로 충분하다.
