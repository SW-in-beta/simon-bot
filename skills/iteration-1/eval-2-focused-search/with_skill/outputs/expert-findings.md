# Phase 3: 전문가 패널 분석

> 6인 전문가 패널이 소스 요약본과 simon-bot 스킬을 분석하여 개선 제안을 도출합니다.
> **사용자 포커스**: 프롬프트 엔지니어링, 컨텍스트 관리

---

## Expert 1: Workflow Architect — 워크플로 구조, 단계 순서, 게이트 설계

### [P-001] 컨텍스트 활용률 모니터링 & 선제적 Compaction 트리거

- **전문가**: Workflow Architect
- **심각도**: HIGH
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Context Window Management 섹션)
- **출처**: Anthropic Engineering Blog — "Context rot" 개념, 40-60% 활용 범위 전략, "Tool Result Clearing"
- **현재 상태**: Context Window Management 섹션에서 "컨텍스트 윈도우가 자동 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다"라고만 기술. 수동적 대응(자동 압축에 의존)이며, 선제적 관리 전략이 없다.
- **개선안**:
  1. Step 전환 시점에서 컨텍스트 활용률 체크 권장사항 추가 — "Step 전환 시 /context로 활용률을 확인하고, 70% 이상이면 핵심 상태를 memory 파일에 저장한 후 /compact를 실행한다"
  2. "Tool Result Clearing" 전략 추가 — "이전 Step의 도구 결과(긴 빌드 출력, 대량 grep 결과 등)는 컨텍스트에서 자연스럽게 희석된다. Step 전환 시 /compact를 실행하면 이런 불필요한 도구 결과가 요약되어 컨텍스트 효율이 향상된다"
- **근거**: Anthropic 블로그에서 "context rot — 토큰 증가에 따른 회상 정확도 감소"를 공식 인정. 자동 압축에만 의존하면 이미 성능이 저하된 상태에서 압축이 실행될 수 있다. 선제적 관리로 "attention budget"을 효율적으로 사용 가능.
- **전문가 합의**: 동의. 다만 매 Step마다 강제하면 오버헤드이므로, "권장사항" 수준으로.

### [P-002] 세션 진입 프로토콜에 Startup Verification 추가

- **전문가**: Workflow Architect
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Context Window Management > 새 세션 시작 프로토콜)
- **출처**: Anthropic Engineering Blog — "Effective Harnesses for Long-Running Agents", Session Entry Protocol, Startup Verification Testing
- **현재 상태**: 새 세션 시작 프로토콜이 `pwd` → CONTEXT.md + memory 읽기 → git log → 재개 순서. 기존 기능의 기본 검증 단계가 없다.
- **개선안**: 세션 재개 시 4번 이후에 "5. `verify-commands.md`의 빌드 명령을 실행하여 이전 세션의 코드가 정상 상태인지 확인한다. 실패 시 이전 세션의 미수정 이슈를 먼저 해결한다" 추가
- **근거**: Anthropic의 장시간 에이전트 하네스에서 "Startup Verification Testing"이 핵심 패턴으로 식별됨. 이전 세션에서 문서화되지 않은 버그가 남아있을 수 있으며, 새 기능 작업 전 기존 기능 검증이 문제 누적을 방지.
- **전문가 합의**: 동의. 기존 Pre-flight 환경 검증과 보완적 — Pre-flight는 환경, 이것은 코드 상태 검증.

---

## Expert 2: Prompt Engineer — 프롬프트 품질, 지시문 명확성, 예시 적절성

### [P-003] Altitude Calibration 원칙 도입 — 프롬프트 구체성 수준 가이드

- **전문가**: Prompt Engineer
- **심각도**: HIGH
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Cross-Cutting Protocols 하위 새 섹션), references/phase-a-planning.md (전문가 팀 프롬프트)
- **출처**: Anthropic Engineering Blog — "Altitude Calibration" 개념
- **현재 상태**: 전문가 에이전트 프롬프트에 구체성 수준 가이드가 없다. 일부 프롬프트(Adversarial Default)는 잘 캘리브레이션되어 있으나, SKILL.md 전체에 이 원칙이 명시적으로 문서화되어 있지 않다.
- **개선안**: Cross-Cutting Protocols에 "Prompt Altitude Calibration" 섹션 추가:
  ```
  ### Prompt Altitude Calibration

  에이전트에게 전달하는 프롬프트의 구체성 수준을 의도적으로 조절한다.
  너무 구체적이면 경직되어 예외 상황에 대응하지 못하고,
  너무 모호하면 행동 신호가 부족하여 기대와 다른 결과를 낳는다.

  - Instructions (행동 지시): 구체적으로 — "E2E 테스트를 Playwright로 작성한다"
  - Guidance (행동 규범): 유연하게 — "테스트는 서로 독립적이어야 한다"

  프롬프트 작성 시 각 지시문이 Instruction인지 Guidance인지 구분하고,
  Guidance에 불필요한 구체성을 넣거나 Instruction에서 핵심 세부사항을 빠뜨리지 않는다.
  ```
- **근거**: Anthropic 블로그에서 "specific enough to guide behavior effectively, yet flexible enough to provide strong heuristics"를 원칙으로 제시. 현재 SKILL.md는 Writing Patterns(skill-best-practices.md)에서 명령형/Why 설명/예시를 다루지만, 구체성 수준의 의도적 조절은 다루지 않는다.
- **전문가 합의**: 동의. 기존 Writing Patterns와 보완적 관계.

### [P-004] 서브에이전트 반환 크기 가이드라인 명시

- **전문가**: Prompt Engineer
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Subagent 사용 기준 섹션)
- **출처**: Anthropic Engineering Blog — "서브에이전트가 압축된 요약을 반환 — 일반적으로 1,000-2,000 토큰"
- **현재 상태**: Subagent 사용 기준에서 "언제 사용할지"는 잘 정의되어 있으나, 반환값의 크기와 형식에 대한 가이드가 없다.
- **개선안**: Subagent 사용 기준 섹션에 추가:
  ```
  서브에이전트가 결과를 반환할 때, 전체 분석 내용이 아닌 압축된 요약(1,000-2,000 토큰)을
  반환한다. 상세 분석은 memory 파일에 저장하고, 반환값에는 핵심 결론과 파일 참조만 포함한다.
  이를 통해 오케스트레이터의 컨텍스트 소비를 최소화한다.
  ```
- **근거**: Anthropic 블로그에서 "condensed, distilled summary (typically 1,000-2,000 tokens)"를 명시적 가이드로 제시. 현재 simon-bot에서 서브에이전트 반환값이 과도하게 길어지면 오케스트레이터의 컨텍스트를 불필요하게 소비한다.
- **전문가 합의**: 동의. 실질적 컨텍스트 절약 효과.

---

## Expert 3: Innovation Scout — 새로운 기법, 패턴, 도구 활용 가능성

### [P-005] Instructions vs Guidance 이원 분류 체계 도입

- **전문가**: Innovation Scout
- **심각도**: HIGH
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Cross-Cutting Protocols 하위 새 섹션 또는 Reference Loading Policy 확장)
- **출처**: Martin Fowler 블로그 — "Instructions vs Guidance" 이원 분류
- **현재 상태**: SKILL.md의 지시문들이 "직접 행동 지시"와 "행동 규범/원칙"을 구분하지 않고 혼재. 예: Stop-and-Fix Gate(Instruction)와 Over-engineering 방지(Guidance)가 동일 수준으로 기술.
- **개선안**: Cross-Cutting Protocols 섹션 도입부에 이원 분류 개념을 명시:
  ```
  ### Instruction과 Guidance 구분

  이 스킬의 지시문은 두 종류로 나뉜다:
  - **Instruction** (행동 지시): 특정 상황에서 반드시 수행해야 할 구체적 행동.
    예: "소스코드 수정 후 verify-commands.md의 빌드/린트 명령을 즉시 실행한다"
  - **Guidance** (행동 규범): 전반적으로 따라야 할 원칙이지만 상황에 따라 유연하게 적용.
    예: "plan-summary.md에 명시된 변경만 구현한다"

  Instruction을 무시하면 워크플로가 깨지고, Guidance를 무시하면 품질이 저하된다.
  LLM은 두 종류를 구분하지 못하면 모든 것을 Guidance로 취급하여 중요한 게이트를 건너뛸 수 있다.
  ```
- **근거**: Martin Fowler 블로그에서 Instructions와 Guidance의 혼재가 프롬프트 효과를 저하시키는 핵심 요인으로 식별. 현재 simon-bot의 Cross-Cutting Protocols 중 일부(Stop-and-Fix Gate, Auto-Verification Hook)는 결정론적 Instruction이지만, 다른 것들(Over-engineering 방지, Parallel Tool Invocation)은 유연한 Guidance다. 이를 명시적으로 구분하면 LLM의 준수율이 향상된다.
- **전문가 합의**: 동의. 기존 구조를 크게 바꾸지 않으면서 프롬프트 효과를 개선하는 경제적 방법.

### [P-006] Just-In-Time Retrieval 패턴으로 전문가 프롬프트 최적화

- **전문가**: Innovation Scout
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot
- **대상 파일**: references/phase-a-planning.md (Step 4-B 전문가 팀)
- **출처**: Anthropic Engineering Blog — "Just-In-Time Retrieval" 패턴, "lightweight identifiers"
- **현재 상태**: Step 4-B에서 전문가 팀 생성 시 plan-summary.md, requirements.md, code-design-analysis.md를 전체 전달. 전문가별로 필요한 부분이 다름에도 동일한 컨텍스트를 모두에게 전달.
- **개선안**: 전문가별 컨텍스트 최적화:
  - Safety Team: plan-summary.md의 Concerns + Code Changes 섹션 + 인증/보안 관련 코드 경로만
  - Data Team: plan-summary.md의 Task + DB 관련 파일 경로만
  - 각 전문가에게 전체 문서 대신 "경량 식별자(파일 경로, 섹션 마커)"를 전달하고, 필요한 부분만 직접 Read하도록 지시
- **근거**: Anthropic 블로그에서 "maintain lightweight identifiers and dynamically load data at runtime using tools"를 핵심 패턴으로 제시. 전체 문서를 모든 전문가에게 전달하면 불필요한 컨텍스트 소비 + 관련 없는 정보로 인한 주의력 분산.
- **전문가 합의**: 부분 동의. Unit Runbook이 이미 유사한 패턴을 구현하고 있으나, 전문가 팀에는 아직 미적용. 다만 구현 복잡성이 있어 MEDIUM 유지.

---

## Expert 4: Quality & Safety Guardian — 에러 처리, 안전장치, 엣지케이스

### [P-007] Compaction 후 Critical State 복원 검증

- **전문가**: Quality & Safety Guardian
- **심각도**: HIGH
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Context Window Management 섹션)
- **출처**: Anthropic Engineering Blog — "Structured Note-Taking (Agentic Memory)", "Art of Compaction"
- **현재 상태**: "압축이 발생해도 `.claude/memory/`에 상태가 저장되어 있으므로 작업을 계속 진행한다"고만 기술. 압축 후 critical state가 실제로 복원되었는지 검증하는 절차가 없다.
- **개선안**: Context Window Management 섹션에 Compaction 후 검증 절차 추가:
  ```
  ### Compaction 후 상태 검증

  자동 또는 수동 compaction 후 다음 항목이 컨텍스트에 유지되고 있는지 확인한다:
  1. 현재 진행 중인 Step 번호와 상태
  2. 활성 Forbidden Rules (특히 ABSOLUTE FORBIDDEN)
  3. 현재 Unit의 Done-When Checks

  유지되지 않는 항목이 있으면 해당 memory 파일을 다시 읽는다.
  이를 통해 compaction으로 인한 규칙 소실("컨텍스트 압축 시 규칙이 소실되어
  게이트가 무력화")을 방지한다.
  ```
- **근거**: Anthropic 블로그에서 "Art of Compaction — balance between aggressive and conservative summarization"을 강조. simon-bot의 기존 "Deterministic Gate Principle"이 LLM 기억 의존의 위험을 인지하고 있으나, compaction 직후 검증은 명시되어 있지 않다.
- **전문가 합의**: 동의. Deterministic Gate Principle과 보완적.

---

## Expert 5: DX Specialist — 개발자 경험, 피드백 루프, 사용 편의성

### [P-008] Step Progress에 컨텍스트 활용률 표시

- **전문가**: DX Specialist
- **심각도**: LOW
- **대상 스킬**: simon-bot
- **대상 파일**: references/phase-b-implementation.md (Step Progress Pulse P-007)
- **출처**: Martin Fowler 블로그 — "Transparency Requirements", Claude Code의 /context 명령
- **현재 상태**: Step Progress Pulse가 `[Step {N}/{total}] {Step명} 완료 — {핵심 결과 요약}` 형식. 컨텍스트 상태 정보를 포함하지 않아 사용자가 세션 분할 시점을 판단하기 어렵다.
- **개선안**: Step Progress Pulse에 선택적 컨텍스트 표시 추가:
  ```
  컨텍스트 활용률이 60%를 초과한 경우, Step Progress Pulse에 활용률을 표시한다:
  [Step 7/17] Expert Review 완료 — CRITICAL 0, HIGH 2 | ctx: 68%

  이를 통해 사용자가 세션 분할 시점을 사전에 인지할 수 있다.
  ```
- **근거**: Martin Fowler 블로그에서 "Tools should provide visibility into context utilization"을 강조. 사용자에게 컨텍스트 상태를 투명하게 공유하면 세션 분할 판단이 용이.
- **전문가 합의**: 부분 동의. 유용하지만 구현 가능성에 의문 — /context 명령의 출력을 자동 파싱하는 것이 현실적이지 않을 수 있으므로 LOW.

---

## Expert 6: Skill Craft Specialist — 스킬 구조, progressive disclosure, 트리거링

> Skill Craft Specialist는 `~/.claude/skills/simon-bot-boost/references/skill-best-practices.md`를 참조하여 분석합니다.

### [P-009] Reference Loading Policy에 "전략 선택 기준" 추가

- **전문가**: Skill Craft Specialist
- **심각도**: MEDIUM
- **대상 스킬**: simon-bot
- **대상 파일**: SKILL.md (Reference Loading Policy 섹션)
- **출처**: Anthropic Engineering Blog — "Task-Dependent Strategy Selection" (Compaction vs Note-taking vs Multi-agent)
- **현재 상태**: Reference Loading Policy가 "Phase 진입 시 해당 레퍼런스만 읽는다"는 로딩 시점 규칙을 잘 정의하고 있으나, 장시간 작업에서의 컨텍스트 관리 전략 선택 가이드가 없다.
- **개선안**: Context Window Management 또는 Reference Loading Policy에 전략 선택 가이드 추가:
  ```
  ### 장시간 작업의 컨텍스트 전략 선택

  작업 특성에 따라 컨텍스트 관리 전략을 선택한다:
  - **Compaction 중심**: 광범위한 대화가 필요한 작업 (Phase A 인터뷰, 디버깅)
  - **Note-taking 중심**: 명확한 마일스톤이 있는 반복 개발 (Phase B-E TDD 사이클)
  - **Multi-agent 중심**: 병렬 탐색이 유리한 분석 작업 (Step 4-B 전문가 패널, Step 7 검증)

  이 스킬은 이미 세 전략을 모두 사용한다:
  - Decision Journal, CONTEXT.md = Note-taking
  - /compact, 세션 분할 = Compaction
  - Agent Teams, subagent = Multi-agent
  ```
- **근거**: Anthropic 블로그에서 세 가지 전략의 선택 기준을 명시적으로 제시. simon-bot이 이미 세 전략을 모두 사용하고 있으나, 이를 의식적으로 선택하는 가이드가 없어 새로운 상황에서 적절한 전략을 선택하기 어렵다. 기존 구조를 코드화하는 것이므로 구조 변경 없이 문서 수준 개선.
- **전문가 합의**: 동의. 기존 패턴을 명시적으로 문서화하는 것이므로 위험도 낮음.

---

## 통합 요약

| ID | 제목 | 전문가 | 심각도 | 대상 |
|---|---|---|---|---|
| P-001 | 컨텍스트 활용률 모니터링 & 선제적 Compaction | Workflow Architect | HIGH | simon-bot/SKILL.md |
| P-002 | 세션 진입 프로토콜에 Startup Verification | Workflow Architect | MEDIUM | simon-bot/SKILL.md |
| P-003 | Altitude Calibration 원칙 도입 | Prompt Engineer | HIGH | simon-bot/SKILL.md |
| P-004 | 서브에이전트 반환 크기 가이드라인 | Prompt Engineer | MEDIUM | simon-bot/SKILL.md |
| P-005 | Instructions vs Guidance 이원 분류 | Innovation Scout | HIGH | simon-bot/SKILL.md |
| P-006 | Just-In-Time Retrieval 전문가 프롬프트 최적화 | Innovation Scout | MEDIUM | references/phase-a-planning.md |
| P-007 | Compaction 후 Critical State 복원 검증 | Quality & Safety Guardian | HIGH | simon-bot/SKILL.md |
| P-008 | Step Progress에 컨텍스트 활용률 표시 | DX Specialist | LOW | references/phase-b-implementation.md |
| P-009 | Reference Loading Policy 전략 선택 기준 | Skill Craft Specialist | MEDIUM | simon-bot/SKILL.md |

**중복 확인**: applied-log.md의 기존 적용 기록과 대조한 결과, 위 9개 제안은 모두 기존에 적용되지 않은 새로운 제안입니다.
