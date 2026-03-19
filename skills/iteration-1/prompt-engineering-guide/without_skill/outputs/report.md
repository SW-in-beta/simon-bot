# Simon-Bot Prompt Quality Improvement Report

Based on: Anthropic Prompt Engineering Best Practices (Claude 4.6)
Analysis date: 2026-03-06

---

## Executive Summary

Anthropic의 최신 프롬프트 엔지니어링 가이드를 기준으로 simon-bot 스킬 5종(simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report, simon-bot-sessions)을 분석했습니다. 전반적으로 구조화와 단계별 설계는 우수하나, 가이드의 핵심 원칙들을 적용하면 품질을 한 단계 높일 수 있는 영역이 다수 발견되었습니다.

**주요 발견:**
- XML 태그 구조화가 거의 사용되지 않음 (가이드 핵심 원칙 위반)
- 역할(Role) 설정이 명시적이지 않음
- 예시(Few-shot examples)가 전무함
- 컨텍스트/동기 부여가 일부 규칙에서 누락됨
- Claude 4.6 모델 특성에 맞지 않는 과도한 지시가 존재함
- 서브에이전트 과용 가능성에 대한 가이드라인 부재
- 상태 관리에 구조화된 형식(JSON)과 비구조화 텍스트의 혼용 전략이 부족함

---

## 1. XML 태그 구조화 (Critical - 전 스킬 공통)

### 가이드 원칙
> "XML tags help Claude parse complex prompts unambiguously, especially when your prompt mixes instructions, context, examples, and variable inputs."

### 현재 상태
모든 스킬이 마크다운(headings, tables, code blocks)으로만 구조화되어 있음. XML 태그가 단 하나도 사용되지 않음.

### 개선 제안

**simon-bot SKILL.md**: 최상위 섹션들을 XML 태그로 감싸서 지시사항/컨텍스트/규칙을 명확히 구분해야 합니다.

```
현재:
## Cross-Cutting Protocols
### Error Resilience
모든 실패를 ENV_INFRA vs CODE_LOGIC으로 분류 후 자동 복구...

개선:
<cross_cutting_protocols>
  <error_resilience>
    모든 실패를 ENV_INFRA vs CODE_LOGIC으로 분류 후 자동 복구...
  </error_resilience>
</cross_cutting_protocols>
```

**Global Forbidden Rules**: 금지 규칙은 특히 XML 태그로 강조해야 합니다.

```
현재:
## Global Forbidden Rules
- `git push --force` ...

개선:
<forbidden_actions>
  <action command="git push --force">다른 사람의 커밋을 영구 삭제할 수 있음</action>
  <action command="rm -rf">복구 불가능한 파일 삭제</action>
  ...
</forbidden_actions>
```

**적용 대상**: simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report, simon-bot-sessions 모두

**우선순위**: 높음 - XML 태그는 가이드에서 "misinterpretation을 줄이는" 핵심 기법으로 제시됨

---

## 2. 역할(Role) 설정 명시화 (High - 전 스킬 공통)

### 가이드 원칙
> "Setting a role in the system prompt focuses Claude's behavior and tone for your use case. Even a single sentence makes a difference."

### 현재 상태
- simon-bot: "You are executing the **simon-bot** deep workflow." -- 역할이 아닌 작업 설명
- simon-bot-grind: "You are executing **simon-bot-grind**" -- 동일 문제
- simon-bot-pm: 역할 설정 없이 바로 Phase 설명으로 진입
- simon-bot-report: "You are executing the **simon-bot-report** skill." -- 작업 설명
- simon-bot-sessions: 역할 설정 없음

### 개선 제안

각 스킬의 Instructions 시작 부분에 명확한 역할 정의를 추가해야 합니다.

```
simon-bot:
"You are a senior software engineer executing a rigorous 19-step quality pipeline.
Your mandate is to plan, implement, and verify code changes with maximum rigor,
ensuring every change passes TDD, expert review, and production readiness checks."

simon-bot-grind:
"You are a relentless problem-solving engineer who never gives up. You diagnose failures,
adapt strategies, and retry with increasing sophistication until the task succeeds."

simon-bot-pm:
"You are a technical project manager who orchestrates complex multi-feature projects.
You interview stakeholders, create specifications, decompose work, and coordinate
multiple implementation agents to deliver complete projects."

simon-bot-report:
"You are a senior technical analyst who produces pre-implementation analysis documents.
You coordinate expert team discussions and synthesize findings into actionable reports."

simon-bot-sessions:
"You are a session management assistant for simon-bot worktree-based work sessions.
You help users list, inspect, resume, and clean up their ongoing work sessions."
```

---

## 3. 컨텍스트/동기 부여 추가 (High - 전 스킬 공통)

### 가이드 원칙
> "Providing context or motivation behind your instructions... can help Claude better understand your goals and deliver more targeted responses."

가이드의 예시: "NEVER use ellipses" 대신 "Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them."

### 현재 상태
많은 규칙이 "무엇을" 하라고만 말하고 "왜" 하는지 설명하지 않음.

**문제 사례들:**
- simon-bot: "Interview Guard: 코드에서 알 수 있는 건 묻지 않음. 비즈니스 결정만 질문" -- 왜?
- simon-bot: "CONTEXT.md 최종 상태 갱신됨" -- 왜 중요한지?
- simon-bot-grind: "Checkpoint: 전략 전환 전 git tag" -- 왜?
- simon-bot-pm: "기술 스택은 이 단계에서 묻지 않는다" -- 왜?

### 개선 제안

각 지시사항에 간결한 동기/이유를 덧붙여야 합니다.

```
현재:
"Interview Guard: 코드에서 알 수 있는 건 묻지 않음. 비즈니스 결정만 질문"

개선:
"Interview Guard: 코드에서 알 수 있는 건 묻지 않음. 비즈니스 결정만 질문.
사용자의 시간을 존중하기 위함 — 코드 분석으로 답을 얻을 수 있는 질문은
사용자를 불필요하게 방해하는 것이므로, 오직 사용자만 답할 수 있는
비즈니스/우선순위 결정만 질문한다."
```

```
현재:
"기술 스택은 이 단계에서 묻지 않는다 — 1-C에서 전문가 패널이 추천한다."

개선:
"기술 스택은 이 단계에서 묻지 않는다. 요구사항(WHAT)이 확정되기 전에
기술 결정(HOW)을 내리면 특정 기술에 맞춰 요구사항이 왜곡될 수 있다.
1-C에서 전문가 패널이 확정된 요구사항을 기반으로 최적의 스택을 추천한다."
```

---

## 4. Few-Shot 예시 추가 (High - simon-bot, simon-bot-pm)

### 가이드 원칙
> "Examples are one of the most reliable ways to steer Claude's output format, tone, and structure. A few well-crafted examples (known as few-shot or multishot prompting) can dramatically improve accuracy and consistency."
> "Include 3-5 examples for best results."
> "Wrap examples in `<example>` tags"

### 현재 상태
5개 스킬 모두 examples가 전무합니다. 코드 블록으로 JSON 스키마나 파일 형식을 보여주는 것은 있지만, 실제 입출력 예시(few-shot)는 없음.

### 개선 제안

**simon-bot - Step 0 (Scope Challenge)에 예시 추가:**

```xml
<examples>
  <example>
    <user_request>로그인 API에 2FA 옵션 추가해줘</user_request>
    <scope_assessment>
      SMALL: 단일 API 엔드포인트 변경 + 테스트 추가
      변경 범위: auth/ 디렉토리 내 2-3 파일
      추천 path: SMALL (Step 5 → Step 8 → Step 17)
    </scope_assessment>
  </example>
  <example>
    <user_request>결제 시스템을 Stripe에서 Toss Payments로 전환해줘</user_request>
    <scope_assessment>
      LARGE: 다중 모듈 (payment, order, billing) 변경 + 외부 연동
      변경 범위: 15+ 파일, 3개 서비스 영향
      추천 path: LARGE (전체 19-step)
    </scope_assessment>
  </example>
</examples>
```

**simon-bot-pm - Phase 1-A (Vision Interview)에 예시 추가:**

```xml
<examples>
  <example>
    <context>사용자가 "TODO 앱 만들어줘"라고만 말한 경우</context>
    <interview_round_1>
      1. 이 TODO 앱의 주요 사용자는 누구인가요? (개인용? 팀 협업용?)
      2. 가장 중요한 기능 3가지를 꼽자면 무엇인가요?
    </interview_round_1>
  </example>
  <example>
    <context>사용자가 상세 요구사항을 이미 제공한 경우</context>
    <interview_round_1>
      말씀하신 내용을 정리하면:
      - 팀 협업용 칸반 보드
      - 실시간 알림 필수
      - Slack 연동 희망
      맞는지 확인 부탁드립니다. 추가로:
      1. 예상 동시 사용자 수는 어느 정도인가요?
    </interview_round_1>
  </example>
</examples>
```

**simon-bot-report - Step 0-B (사용자 입력 수집)에 예시 추가:**

분석 주제가 모호할 때 vs 구체적일 때의 대응 예시를 추가하면 일관성이 크게 향상됩니다.

---

## 5. Claude 4.6 모델 특성 대응 (High - simon-bot, simon-bot-grind)

### 가이드 원칙 (과도한 지시 조절)
> "Claude Opus 4.5 and Claude Opus 4.6 are also more responsive to the system prompt than previous models. If your prompts were designed to reduce undertriggering on tools or skills, these models may now overtrigger. The fix is to dial back any aggressive language."
> "Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'"

### 가이드 원칙 (과도한 탐색 억제)
> "Claude Opus 4.6 does significantly more upfront exploration than previous models... If your prompts previously encouraged the model to be more thorough, you should tune that guidance."
> "Replace blanket defaults with more targeted instructions."

### 현재 상태
- simon-bot: "최고 수준의 엄격함으로 수행" (description) -- 과잉 품질 추구 유발 가능
- simon-bot-grind: "모든 재시도 한계 = 10" "포기하지 않는다" -- 4.6에서는 과도할 수 있음
- 전반적으로 강한 어조의 지시가 많음: "절대 중단되지 않는다", "반드시", "금지"

### 개선 제안

**4.6에서의 과잉 엄격함 조절을 위한 가이드 추가:**

```xml
<effort_calibration>
모든 단계에서 접근 방식을 선택할 때, 하나를 선택하고 밀고 나가라.
새로운 정보가 기존 판단을 직접 반박하지 않는 한 결정을 재검토하지 마라.
두 접근법을 저울질하고 있다면, 하나를 선택하고 끝까지 가봐라.
선택한 접근이 실패하면 그때 방향을 수정할 수 있다.
</effort_calibration>
```

이 문구는 가이드에서 직접 제공한 overthinking 방지 프롬프트입니다.

**simon-bot-grind의 Core Philosophy 조절:**

```
현재: "끝날 때까지 끝난 게 아니다. 진단하고, 적응하고, 다시 시도한다."
추가: "단, 무의미한 반복은 피한다. 동일한 실패가 3회 연속 발생하면
      즉시 전략을 전환하고, 이전과 다른 접근법을 시도한다."
```

---

## 6. 서브에이전트 과용 방지 (High - simon-bot, simon-bot-pm)

### 가이드 원칙
> "Claude Opus 4.6 has a strong predilection for subagents and may spawn them in situations where a simpler, direct approach would suffice."
> "Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams that don't need to share state. For simple tasks, sequential operations, single-file edits, or tasks where you need to maintain context across steps, work directly rather than delegating."

### 현재 상태
- simon-bot: Agent Teams를 적극 활용하지만, "언제 서브에이전트를 쓰지 않아야 하는지"에 대한 가이드가 없음
- simon-bot-pm: deep-executor, architect, CTO agent 등 다수 에이전트를 spawn하나 직접 처리 기준이 없음

### 개선 제안

각 스킬에 서브에이전트 사용 기준을 명시해야 합니다.

```xml
<subagent_policy>
서브에이전트는 다음 경우에만 사용한다:
- 병렬 실행이 가능한 독립적 작업 (예: 여러 Unit의 동시 구현)
- 격리된 컨텍스트가 필요한 작업 (예: 워크트리 내 구현)
- 전문 도메인 지식이 필요한 토론 (예: Agent Team 리뷰)

다음 경우에는 직접 처리한다:
- 단일 파일 수정
- 간단한 grep/read 작업
- 순차적 의존성이 있는 작업
- 상태를 공유해야 하는 작업
</subagent_policy>
```

---

## 7. 상태 관리 전략 개선 (Medium - simon-bot, simon-bot-grind)

### 가이드 원칙
> "Use structured formats for state data: When tracking structured information (like test results or task status), use JSON"
> "Use unstructured text for progress notes: Freeform progress notes work well for tracking general progress"
> "Use git for state tracking: Git provides a log of what's been done and checkpoints that can be restored."

### 현재 상태
- simon-bot: `.claude/memory/*.md` 파일들은 모두 마크다운 (비구조화 텍스트)
- simon-bot-grind: failure-log.md, checkpoints.md도 마크다운
- simon-bot-pm: tasks.json은 JSON (좋음), 나머지는 마크다운

### 개선 제안

상태 데이터와 진행 노트를 구분해야 합니다.

```
구조화 데이터 (JSON으로 전환 권장):
- failure-log.md → failure-log.json (실패 횟수, 유형, 전략 추적)
- checkpoints.md → checkpoints.json (체크포인트 목록, 상태)
- unresolved-decisions.md → 핵심 추적 필드는 JSON, 설명은 텍스트

비구조화 텍스트 (현재대로 유지):
- plan-summary.md (계획 서술)
- retrospective.md (회고록)
- feedback.md (사용자 피드백)
```

**failure-log.json 예시:**
```json
{
  "failures": [
    {
      "step": 5,
      "attempt": 3,
      "type": "CODE_LOGIC",
      "error": "type assertion panic in handler",
      "strategy": "simple_fix",
      "resolved": true
    }
  ],
  "total_failures": 5,
  "total_pivots": 1,
  "current_strategy": "root_cause_analysis"
}
```

---

## 8. 컨텍스트 윈도우 관리 강화 (Medium - simon-bot, simon-bot-grind)

### 가이드 원칙
> "Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely... do not stop tasks early due to token budget concerns."
> "As you approach your token budget limit, save your current progress and state to memory before the context window refreshes."

### 현재 상태
- simon-bot: 세션 분할 경계를 정의하고 있지만, 컨텍스트 소진 시 자동 행동에 대한 지침이 부족
- simon-bot-grind: "경계 2 전에 잔여량을 반드시 확인" 정도만 언급

### 개선 제안

```xml
<context_window_management>
컨텍스트 윈도우는 한계에 도달하면 자동으로 compact됩니다.
따라서 토큰 예산 걱정으로 작업을 조기 중단하지 마세요.

컨텍스트 한계에 가까워지면:
1. 현재 진행 상태를 .claude/memory/에 저장
2. 현재 Step 번호와 남은 작업을 명확히 기록
3. 다음 세션에서 바로 이어갈 수 있도록 CONTEXT.md 갱신

항상 최대한 자율적이고 지속적으로 작업하며,
컨텍스트 잔여량에 관계없이 작업을 인위적으로 조기 종료하지 마세요.
</context_window_management>
```

---

## 9. "무엇을 하지 마라" 대신 "무엇을 하라" (Medium - 전 스킬 공통)

### 가이드 원칙
> "Tell Claude what to do instead of what not to do"

### 현재 상태
Global Forbidden Rules가 모두 "하지 마라" 형식입니다. 이는 필요한 경우이긴 하나, 가능한 곳에서는 긍정형으로 전환하는 것이 좋습니다.

### 개선 제안

금지 규칙 자체는 유지하되, 대안 행동을 병기합니다.

```
현재:
- `git push --force` / `git push -f` — 다른 사람의 커밋을 영구 삭제할 수 있음

개선:
- `git push --force` 대신 `git push --force-with-lease`를 사용한다
  (다른 사람의 커밋이 있으면 자동으로 거부됨)
- 단, --force-with-lease도 사용자 명시적 요청이 있을 때만 허용
```

```
현재:
- 암묵적 기본값 사용 금지

개선:
- 모든 결정사항을 명시적으로 기록한다. 기본값을 사용할 때도
  "X를 Y로 결정 (기본값 사용, 이유: ...)"와 같이 기록한다.
```

---

## 10. 자율성과 안전성의 균형 명시 (Medium - simon-bot, simon-bot-grind)

### 가이드 원칙
> "Consider the reversibility and potential impact of your actions. You are encouraged to take local, reversible actions like editing files or running tests, but for actions that are hard to reverse, affect shared systems, or could be destructive, ask the user before proceeding."

### 현재 상태
- Global Forbidden Rules에 금지 목록이 있지만, "자율 행동 OK" vs "확인 필요" 경계가 불명확
- simon-bot-grind는 자율성이 매우 높은데, 되돌리기 어려운 행동의 경계가 명확하지 않음

### 개선 제안

```xml
<autonomy_levels>
자율 실행 (확인 불필요):
- 파일 읽기/수정
- 테스트 실행
- 로컬 빌드
- git commit (로컬)
- 워크트리 생성/삭제

확인 후 실행 (AskUserQuestion):
- git push (원격에 영향)
- PR 생성/수정
- 브랜치 삭제
- 외부 서비스 호출 의심 시
- 계획에서 크게 벗어나는 전략 전환
</autonomy_levels>
```

---

## 11. Hallucination 방지 가이드라인 추가 (Medium - simon-bot, simon-bot-report)

### 가이드 원칙
> "Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering."

### 현재 상태
코드를 먼저 읽고 분석하라는 암묵적 기대는 있지만, 명시적인 hallucination 방지 지침이 없음.

### 개선 제안

```xml
<investigate_before_answering>
열어보지 않은 코드에 대해 추측하지 마라.
특정 파일이 언급되면, 답변 전에 반드시 해당 파일을 Read해야 한다.
코드베이스에 대한 질문에 답할 때는 관련 파일을 먼저 조사하고 읽어라.
조사하기 전에는 코드에 대한 어떤 주장도 하지 마라.
근거 있고 hallucination 없는 답변만 제공한다.
</investigate_before_answering>
```

이 문구는 가이드에서 직접 제공한 hallucination 방지 프롬프트의 번역입니다.

---

## 12. Long Context 프롬프팅 기법 적용 (Medium - simon-bot-report)

### 가이드 원칙
> "Put longform data at the top... above your query, instructions, and examples."
> "Ground responses in quotes: For long document tasks, ask Claude to quote relevant parts of the documents first before carrying out its task."

### 현재 상태
simon-bot-report의 Step 2-3에서 대량의 코드 분석 결과를 처리하지만, 인용(quoting) 기반 분석 전략이 없음.

### 개선 제안

```
Step 2 (Code Design Analysis)에 추가:
"분석 시 핵심 코드 부분을 먼저 <quotes> 태그로 인용한 뒤,
인용된 코드를 근거로 분석 결과를 작성한다.
이는 대량의 코드 컨텍스트에서 noise를 줄이고
분석의 정확도를 높이기 위함이다."
```

---

## 13. 과잉 엔지니어링 방지 (Medium - simon-bot, simon-bot-pm)

### 가이드 원칙
> "Claude Opus 4.5 and Claude Opus 4.6 have a tendency to overengineer by creating extra files, adding unnecessary abstractions, or building in flexibility that wasn't requested."

### 현재 상태
- simon-bot: Step 4 (Over-engineering Check with YAGNI/KISS)가 있어 좋음
- 하지만 구현 단계(Step 5)에서의 과잉 엔지니어링 방지는 약함
- simon-bot-pm: Phase 3 (Environment Setup)에서 과잉 scaffolding 위험

### 개선 제안

```xml
<avoid_overengineering>
직접 요청되었거나 명확히 필요한 변경만 수행한다. 솔루션을 단순하고 집중적으로 유지한다:

- 범위: 요청 범위를 벗어나는 기능 추가, 리팩토링, "개선"을 하지 않는다.
  버그 수정에 주변 코드 정리가 필요하지 않다. 단순한 기능에 추가 설정 가능성이 필요하지 않다.
- 문서화: 변경하지 않은 코드에 docstring, 주석, 타입 어노테이션을 추가하지 않는다.
  로직이 자명하지 않은 곳에만 주석을 단다.
- 추상화: 일회성 작업에 헬퍼, 유틸리티, 추상화를 만들지 않는다.
  가상의 미래 요구사항을 위해 설계하지 않는다.
  적절한 복잡도는 현재 작업에 필요한 최소한이다.
</avoid_overengineering>
```

---

## 14. 테스트 통과에 집착하지 않기 (Low - simon-bot, simon-bot-grind)

### 가이드 원칙
> "Claude can sometimes focus too heavily on making tests pass at the expense of more general solutions, or may use workarounds like helper scripts"

### 현재 상태
simon-bot의 TDD 필수 정책(RED -> GREEN -> REFACTOR)은 좋지만, 테스트만 통과시키는 하드코딩 방지 가이드가 없음.

### 개선 제안

Step 5 (Implementation)에 추가:

```xml
<implementation_quality>
테스트를 통과시키기 위한 하드코딩이나 workaround를 사용하지 마라.
모든 유효한 입력에 대해 올바르게 동작하는 범용적 솔루션을 구현하라.
테스트는 정확성을 검증하기 위한 것이지, 솔루션을 정의하는 것이 아니다.
테스트가 잘못되었다고 판단되면, workaround 대신 사용자에게 알려라.
</implementation_quality>
```

---

## 15. 병렬 도구 호출 최적화 (Low - 전 스킬 공통)

### 가이드 원칙
> "Claude's latest models excel at parallel tool execution... Read several files at once to build context faster"

### 현재 상태
simon-bot: "parallel OK"라고 표시된 곳이 있지만, 구체적인 병렬화 지침이 부족.

### 개선 제안

```xml
<parallel_execution>
독립적인 도구 호출은 항상 병렬로 실행한다.
예: 여러 파일을 읽을 때 한 번에 모두 Read 호출.
단, 이전 호출 결과에 의존하는 호출은 순차로 실행한다.
파라미터를 추측하거나 placeholder를 사용하지 마라.
</parallel_execution>
```

---

## 16. 임시 파일 정리 (Low - simon-bot, simon-bot-grind)

### 가이드 원칙
> "If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task."

### 현재 상태
워크트리 내에서 임시 파일을 생성할 수 있으나 정리 정책이 없음.

### 개선 제안

Step 17 (Production Readiness) 또는 Integration Stage에 추가:

```
"임시로 생성한 테스트 스크립트, 디버그 파일, 헬퍼 파일이 있다면
최종 커밋 전에 모두 삭제한다."
```

---

## 스킬별 개선 요약

### simon-bot (주 워크플로)
| # | 개선 항목 | 우선순위 | 관련 가이드 원칙 |
|---|----------|---------|----------------|
| 1 | XML 태그 구조화 | Critical | Structure prompts with XML tags |
| 2 | 역할 설정 명시화 | High | Give Claude a role |
| 3 | 지시사항에 동기/컨텍스트 추가 | High | Add context to improve performance |
| 4 | Scope Challenge에 few-shot 예시 | High | Use examples effectively |
| 5 | 4.6 모델용 과잉 탐색 억제 | High | Overthinking and excessive thoroughness |
| 6 | 서브에이전트 사용 기준 명시 | High | Subagent orchestration |
| 7 | 상태 파일 구조화 (JSON) | Medium | State management best practices |
| 8 | 컨텍스트 윈도우 자율 관리 지침 | Medium | Context awareness |
| 9 | 금지규칙에 대안 행동 병기 | Medium | Tell what to do, not what not to do |
| 10 | 자율성 레벨 명시 | Medium | Balancing autonomy and safety |
| 11 | Hallucination 방지 지침 | Medium | Minimizing hallucinations |
| 13 | 구현 단계 과잉 엔지니어링 방지 | Medium | Overeagerness |
| 14 | 테스트 하드코딩 방지 | Low | Avoid focusing on passing tests |
| 15 | 병렬 도구 호출 지침 | Low | Optimize parallel tool calling |
| 16 | 임시 파일 정리 정책 | Low | Reduce file creation |

### simon-bot-grind (열일모드)
| # | 개선 항목 | 우선순위 |
|---|----------|---------|
| 1 | XML 태그 구조화 | Critical |
| 2 | 역할 설정 ("끈질긴 엔지니어") | High |
| 5 | 4.6에서 과잉 재시도 억제 균형 | High |
| 7 | failure-log를 JSON으로 전환 | Medium |
| 10 | 자율성 vs 확인 경계 명확화 | Medium |

### simon-bot-pm (프로젝트 매니저)
| # | 개선 항목 | 우선순위 |
|---|----------|---------|
| 1 | XML 태그 구조화 | Critical |
| 2 | 역할 설정 ("기술 PM") | High |
| 4 | Vision Interview에 few-shot 예시 | High |
| 6 | 서브에이전트 사용 기준 | High |
| 13 | Phase 3 과잉 scaffolding 방지 | Medium |

### simon-bot-report (사전 분석)
| # | 개선 항목 | 우선순위 |
|---|----------|---------|
| 1 | XML 태그 구조화 | Critical |
| 2 | 역할 설정 ("시니어 기술 분석가") | High |
| 11 | Hallucination 방지 지침 | Medium |
| 12 | Long context 인용 기반 분석 | Medium |

### simon-bot-sessions (세션 관리)
| # | 개선 항목 | 우선순위 |
|---|----------|---------|
| 1 | XML 태그 구조화 | Critical |
| 2 | 역할 설정 ("세션 관리 어시스턴트") | High |

---

## 구현 로드맵 제안

### Phase 1 (즉시 적용 가능 - 1일)
1. 모든 스킬에 명시적 역할(Role) 설정 추가
2. 핵심 섹션에 XML 태그 도입 (Instructions, Forbidden Rules, Cross-Cutting)
3. Hallucination 방지 + 과잉 엔지니어링 방지 프롬프트 삽입

### Phase 2 (단기 - 1주)
4. 주요 Step들에 few-shot 예시 추가 (각 스킬 2-3개씩)
5. 모든 지시사항에 동기/컨텍스트 추가
6. 서브에이전트 사용 정책 명시
7. 4.6 모델 특성 대응 가이드 삽입

### Phase 3 (중기 - 2주)
8. 상태 파일 구조 리팩토링 (핵심 추적 데이터 JSON 전환)
9. 자율성 레벨 매트릭스 정의 및 적용
10. 컨텍스트 윈도우 자동 관리 지침 통합
11. 병렬 도구 호출 최적화 지침 추가

---

## 참고: 가이드에서 가져온 그대로 사용할 수 있는 프롬프트 스니펫

아래는 Anthropic 가이드에서 직접 제공하는 프롬프트로, simon-bot 스킬에 그대로 삽입 가능합니다.

### 1. Overthinking 방지
```text
When you're deciding how to approach a problem, choose an approach and commit to it.
Avoid revisiting decisions unless you encounter new information that directly contradicts
your reasoning. If you're weighing two approaches, pick one and see it through.
You can always course-correct later if the chosen approach fails.
```

### 2. Hallucination 방지
```xml
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file,
you MUST read the file before answering. Make sure to investigate and read relevant files
BEFORE answering questions about the codebase. Never make any claims about code before
investigating unless you are certain of the correct answer.
</investigate_before_answering>
```

### 3. 과잉 엔지니어링 방지
```text
Avoid over-engineering. Only make changes that are directly requested or clearly necessary.
Keep solutions simple and focused. Don't add features, refactor code, or make "improvements"
beyond what was asked. Don't create helpers, utilities, or abstractions for one-time operations.
The right amount of complexity is the minimum needed for the current task.
```

### 4. 테스트 하드코딩 방지
```text
Implement a solution that works correctly for all valid inputs, not just the test cases.
Do not hard-code values or create solutions that only work for specific test inputs.
Tests are there to verify correctness, not to define the solution.
If the task is unreasonable or any of the tests are incorrect, inform me rather than
working around them.
```

### 5. 병렬 도구 호출
```xml
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls,
make all of the independent tool calls in parallel. Never use placeholders or guess missing
parameters in tool calls.
</use_parallel_tool_calls>
```

### 6. 컨텍스트 윈도우 관리
```text
Your context window will be automatically compacted as it approaches its limit, allowing
you to continue working indefinitely. Do not stop tasks early due to token budget concerns.
As you approach your token budget limit, save your current progress and state to memory.
Always be as persistent and autonomous as possible and complete tasks fully.
```

---

## 결론

simon-bot 스킬 시스템은 이미 업계 최고 수준의 체계적 워크플로를 갖추고 있습니다. 19-step pipeline, Agent Teams, 에러 복구 체계, 세션 관리 등 아키텍처적 완성도가 높습니다.

그러나 Anthropic의 프롬프트 엔지니어링 가이드 관점에서 보면, **프롬프트 자체의 표현 방식**에서 개선 여지가 있습니다. 핵심은:

1. **XML 태그로 구조화** -- Claude가 복잡한 프롬프트를 모호함 없이 파싱하도록
2. **명시적 역할 설정** -- 행동과 톤을 집중시키도록
3. **Few-shot 예시** -- 출력 형식과 품질의 일관성을 높이도록
4. **동기/컨텍스트 추가** -- Claude가 규칙의 의도를 이해하고 일반화하도록
5. **4.6 모델 특성 대응** -- 과잉 탐색/과잉 엔지니어링을 적절히 억제하도록

이 다섯 가지만 적용해도 전체 스킬의 프롬프트 품질이 크게 향상될 것입니다.
