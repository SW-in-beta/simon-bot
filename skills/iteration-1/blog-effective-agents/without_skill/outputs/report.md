# simon-bot Skills Improvement Report

Based on: "Building Effective Agents" by Anthropic Engineering
(https://www.anthropic.com/engineering/building-effective-agents)

---

## 1. Executive Summary

Anthropic의 "Building Effective Agents" 블로그 포스트는 에이전트 시스템 설계의 핵심 원칙과 패턴을 제시한다. 이 보고서는 해당 원칙들을 simon-bot 스킬 패밀리(simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report, simon-bot-sessions)에 대입하여 개선 기회를 분석한다.

**핵심 메시지**: "Success prioritizes building the appropriate system for specific needs over maximum sophistication." -- 가장 정교한 시스템이 아니라, 필요에 적합한 시스템을 만드는 것이 성공이다.

---

## 2. Blog Key Principles vs Current Skills

### 2.1 Simplicity First -- "Don't Build Agents When Workflows Suffice"

**Blog 원칙**: 단일 LLM 호출 + retrieval + in-context examples로 충분한 경우 복잡한 시스템을 만들지 마라. 복잡도는 증명된 필요에 의해서만 증가시켜라.

**현재 상태**:
- `simon-bot`의 19-step pipeline은 모든 코드 변경에 적용됨 (SMALL/STANDARD/LARGE path 분기는 있으나 최소가 Step 0~8 + 17~19로 여전히 12단계)
- `simon-bot-grind`는 모든 retry 한계를 10으로 올려 극단적 복잡성을 추가
- `simon-bot-pm`은 7-phase, 각 phase 내 다수 sub-step

**개선 제안**:

| # | 제안 | 대상 스킬 | 우선순위 |
|---|------|----------|---------|
| S1 | **MICRO path 신설**: 단일 파일 변경, 간단한 버그 수정 등에 대해 Step 0 (scope) -> Step 5 (구현) -> Step 6 (검증) -> 커밋의 3-step 축약 경로 도입. 현재 SMALL path도 12단계라 간단한 작업에 과도함 | simon-bot | HIGH |
| S2 | **Adaptive complexity**: Step 0의 scope 판별을 더 세분화하여 MICRO/SMALL/STANDARD/LARGE 4단계로 나누고, 각 경로별 스킵 가능한 단계를 명확히 정의 | simon-bot | HIGH |
| S3 | **grind 모드 자동 전환**: simon-bot에서 시작하되 연속 실패 시에만 자동으로 grind 확장을 활성화하는 방식 검토. 처음부터 retry 10회를 설정하는 것은 "start simple" 원칙에 위배 | simon-bot-grind | MEDIUM |

### 2.2 Workflow Patterns -- 적합한 패턴 선택

Blog은 5가지 workflow 패턴을 제시:
1. **Prompt Chaining** -- 순차적 LLM 호출 + 중간 게이트
2. **Routing** -- 입력 분류 후 전문 처리기로 분배
3. **Parallelization** -- 독립 작업 병렬 실행 / 동일 작업 다중 관점
4. **Orchestrator-Workers** -- 중앙 LLM이 동적으로 작업 분배
5. **Evaluator-Optimizer** -- 생성-평가 반복 루프

**현재 스킬별 패턴 매핑**:

| 스킬 | 주요 패턴 | 분석 |
|------|----------|------|
| simon-bot | Prompt Chaining (19-step sequential) + Parallelization (Agent Teams) + Evaluator-Optimizer (Step 2-4 review loops) | 패턴이 혼합되어 있으나, 핵심은 prompt chaining. 중간 게이트(calibration checklist 등)가 잘 설계됨 |
| simon-bot-grind | Evaluator-Optimizer (10회 retry + escalation ladder) | 강한 evaluator-optimizer loop. 단, Blog이 경고하는 "compounding error" 리스크가 높음 |
| simon-bot-pm | Orchestrator-Workers (PM이 simon-bot들에게 작업 분배) | Blog 패턴 중 가장 정교한 orchestrator-workers를 사용. 적절한 사용 사례 |
| simon-bot-report | Prompt Chaining + Parallelization (5개 도메인팀 병렬 분석) | Blog의 sectioning parallelization과 잘 맞음 |
| simon-bot-sessions | 단순 CRUD 유틸리티 | workflow/agent 패턴 불필요. 현재 적절 |

**개선 제안**:

| # | 제안 | 대상 스킬 | 우선순위 |
|---|------|----------|---------|
| W1 | **Routing 레이어 신설**: 사용자 요청을 받으면 먼저 라우터가 MICRO/simon-bot/simon-bot-grind/simon-bot-pm/simon-bot-report 중 적합한 스킬로 자동 분배. 현재는 사용자가 직접 스킬을 선택해야 함. Blog의 routing 패턴을 최상위에 적용 | 신규 (meta-router) | HIGH |
| W2 | **Parallelization 강화 (Voting)**: Step 2-4 Plan Review에서 동일 계획에 대해 독립적 critic 2-3명을 병렬 실행하고 결과를 종합하는 voting 패턴 도입. 현재 순차 토론보다 다양한 관점 확보 가능 | simon-bot | MEDIUM |
| W3 | **Evaluator-Optimizer에 명확한 종료 기준**: simon-bot-grind의 10회 retry는 "clear evaluation criteria"와 "demonstrable improvement"가 있어야 의미 있음. 각 retry에서 개선 측정 지표(테스트 통과율, 에러 수 등)를 명시적으로 추적하고, 3회 연속 개선 없으면 조기 종료하는 메커니즘 추가 | simon-bot-grind | HIGH |

### 2.3 Transparency -- "Show Your Planning Steps"

**Blog 원칙**: 에이전트의 계획 단계를 사용자에게 명시적으로 보여줘야 한다.

**현재 상태**:
- simon-bot은 Phase A에서 계획을 사용자에게 보여주고 피드백을 받음 (좋음)
- 그러나 Phase B-E 실행 중에는 사용자에게 중간 상태가 잘 보이지 않음
- simon-bot-grind의 Progress Pulse(연속 3회 실패 시 보고)는 좋은 시작이지만 정상 진행에도 visibility 필요

**개선 제안**:

| # | 제안 | 대상 스킬 | 우선순위 |
|---|------|----------|---------|
| T1 | **Step-level progress bar**: 각 Step 시작/완료 시 사용자에게 간결한 1-line 상태 보고. 예: "[Step 7/19] Bug/Security Review -- 3 issues found, 2 fixed" | simon-bot | MEDIUM |
| T2 | **Decision log 투명화**: Agent Team 토론에서 도출된 주요 결정과 그 근거를 사용자에게 요약 제시. 현재는 파일에만 저장되고 사용자가 별도로 읽어야 함 | simon-bot | MEDIUM |
| T3 | **PM progress dashboard**: simon-bot-pm의 Phase 4 실행 중 전체 Feature 진행 상황을 주기적으로 사용자에게 시각적 요약 제시 | simon-bot-pm | LOW |

### 2.4 Agent-Computer Interface (ACI) -- Tool Design Excellence

**Blog 원칙**: 도구 설계에 HCI 수준의 투자를 하라. 파라미터명, 문서화, 에러 방지(poka-yoke) 원칙이 핵심. "Anthropic's SWE-bench agent required more tool optimization than prompt refinement."

**현재 상태**:
- simon-bot의 도구(Agent Teams, subagents, manage-sessions.sh)는 내부적으로 사용됨
- manage-sessions.sh는 CLI 도구로, 사용자가 직접 사용하지 않고 스킬을 통해 호출됨
- Agent에게 주어지는 역할(architect, executor, writer 등)의 정의가 references 파일에 분산

**개선 제안**:

| # | 제안 | 대상 스킬 | 우선순위 |
|---|------|----------|---------|
| A1 | **Agent role specification 표준화**: 각 subagent 역할(architect, executor, critic, planner 등)에 대해 명확한 역할 정의, 입출력 형식, edge case 처리 방법을 하나의 참조 문서로 통합. Blog의 "tool documentation" 원칙을 agent 역할에도 적용 | simon-bot | MEDIUM |
| A2 | **Structured output 강제**: Agent Team 토론 결과가 자유 형식 텍스트가 아닌, severity/category/recommendation 구조화된 형식으로 출력되도록 강제. 후속 Step에서의 파싱과 활용이 용이해짐 | simon-bot, simon-bot-report | MEDIUM |
| A3 | **Poka-yoke for file paths**: Blog에서 상대경로를 절대경로로 바꿔 에러를 제거한 사례 참조. 모든 file path 관련 작업에서 절대경로를 강제하는 검증 게이트 추가 | simon-bot | LOW |

### 2.5 Augmented LLM -- Retrieval, Tools, Memory

**Blog 원칙**: 기본 building block은 retrieval + tools + memory로 강화된 LLM.

**현재 상태**:
- **Retrieval**: Context7 MCP를 통한 라이브러리 문서 조회 (Step 1-A) -- 좋음
- **Tools**: Agent Teams, git worktree, manage-sessions.sh -- 풍부함
- **Memory**: `.claude/memory/` 파일 기반 persistence, retrospective.md, user-feedback-log.md -- 잘 설계됨

**개선 제안**:

| # | 제안 | 대상 스킬 | 우선순위 |
|---|------|----------|---------|
| M1 | **Cross-session memory accumulation**: 현재 retrospective.md는 세션 단위로 기록되지만, 프로젝트 수준에서 "이 프로젝트에서 반복되는 패턴"을 누적 학습하는 구조가 약함. 프로젝트별 learnings DB(패턴, 안티패턴, 자주 실패하는 영역) 구축 | simon-bot | MEDIUM |
| M2 | **Retrieval 확장**: 현재 Context7은 외부 라이브러리 문서만 조회. 프로젝트 내부의 이전 PR, 이전 구현 결정 히스토리도 retrieval 대상에 포함 | simon-bot | LOW |

### 2.6 When to Use Agents -- "Trust in the Environment"

**Blog 원칙**: Agent는 환경 피드백(tool 결과, 코드 실행)으로 "ground truth"를 얻는다. Sandbox 환경과 적절한 guardrail이 필수.

**현재 상태**:
- git worktree 격리는 좋은 sandbox 패턴
- Global Forbidden Rules로 위험 명령 차단 -- 좋음
- 다만 실행 환경의 "ground truth" 활용이 체계적이지 않음

**개선 제안**:

| # | 제안 | 대상 스킬 | 우선순위 |
|---|------|----------|---------|
| E1 | **Test result as feedback loop**: Step 5 TDD에서 테스트 결과를 구조화된 피드백으로 파싱하여 다음 시도의 컨텍스트에 명시적으로 포함. 현재는 "테스트 통과 여부"만 보는 것으로 추정됨 -- 실패 테스트의 assertion message, stack trace 등을 요약하여 구조적 피드백으로 변환 | simon-bot | HIGH |
| E2 | **Build output structured feedback**: 빌드 에러를 카테고리화(import error, type error, syntax error 등)하여 agent에게 구조화된 형태로 전달 | simon-bot, simon-bot-grind | MEDIUM |

### 2.7 Cost & Latency Awareness

**Blog 원칙**: Agent는 높은 비용과 compounding error 잠재력이 있다. Workflow는 예측 가능하지만 유연성이 낮다.

**현재 상태**:
- simon-bot-grind의 10회 retry는 비용/시간이 매우 높을 수 있음
- Agent Teams(5개 도메인팀, 다수 전문가)는 token 소비가 큼
- 비용/시간 추적 메커니즘이 없음

**개선 제안**:

| # | 제안 | 대상 스킬 | 우선순위 |
|---|------|----------|---------|
| C1 | **Cost-aware decision points**: Step 0 scope 판별 시 예상 agent 호출 수와 예상 소요 시간을 사용자에게 제시. "STANDARD path: approx. 15 agent calls, ~30min" | simon-bot | MEDIUM |
| C2 | **Progressive agent activation**: Agent Team의 5개 도메인팀을 항상 전부 활성화하지 말고, auto-detect 결과에 따라 관련 없는 팀은 실제로 스킵. 현재 "auto-detect"이 있지만 실제 스킵 여부가 불명확 | simon-bot, simon-bot-report | MEDIUM |
| C3 | **Grind budget cap**: simon-bot-grind에 총 retry 예산 상한(예: 전체 합계 30회)을 설정하여 무한 루프 방지. 개별 Step 10회 x N Step = 잠재적으로 수십~수백 회 retry 가능 | simon-bot-grind | HIGH |

---

## 3. Skill-Specific Detailed Analysis

### 3.1 simon-bot (Core Pipeline)

**강점** (Blog 원칙과 부합):
- Prompt Chaining + 중간 게이트(Calibration Checklist) -- Blog의 "programmatic gates validate intermediate steps" 권장사항 준수
- Agent Teams 토론 구조 -- Blog의 voting/parallelization 패턴 활용
- Memory persistence -- Session continuity 보장
- Error classification (ENV_INFRA vs CODE_LOGIC) -- 구조적 실패 대응
- Global Forbidden Rules -- Blog의 "guardrails" 권장사항
- User Interaction Recording -- 자기 개선 루프

**개선 영역**:
1. **최소 경로가 너무 무거움**: SMALL path도 12 step. Blog는 "start with simple prompts, add complexity only when justified" 강조
2. **중간 투명성 부족**: Phase B-E에서 사용자에게 진행 상황 전달이 부족
3. **환경 피드백 구조화 미흡**: 테스트/빌드 결과를 구조적 피드백으로 변환하는 단계 부재

### 3.2 simon-bot-grind (Resilient Variant)

**강점**:
- Escalation Ladder (simple fix -> root cause -> strategy pivot -> last stand) -- 체계적 실패 대응
- Checkpoint/rollback -- 안전한 실험
- Progress Pulse -- 사용자 awareness 유지
- Feedback-First Principle -- "빠르게 실패하고 학습"은 Blog의 환경 피드백 활용과 일치

**개선 영역**:
1. **무제한 retry는 Blog 원칙에 위배**: Blog는 "higher costs and compounding error potential"을 경고. 10회 retry가 모든 Step에 적용되면 총 비용이 폭발적
2. **개선 측정 없는 retry**: Blog의 evaluator-optimizer는 "clear evaluation criteria"와 "demonstrable improvement"를 전제. 현재 retry는 단순 재시도 횟수만 추적하고, 시도 간 개선도를 측정하지 않음
3. **Compounding error risk**: Step N의 잘못된 수정이 Step N+1에서 더 큰 문제를 야기할 수 있음. Checkpoint은 있지만 rollback 결정이 자동화되어 있지 않음

### 3.3 simon-bot-pm (Project Manager)

**강점**:
- Orchestrator-Workers 패턴 -- Blog이 "complex tasks with unpredictable subtask requirements"에 추천하는 패턴과 정확히 일치
- Scope Guard -- 불필요한 복잡성 방지 (Blog 원칙 부합)
- Spec-Driven Design -- WHAT과 HOW 분리는 좋은 설계
- Expert Panel -- Routing + Parallelization의 조합

**개선 영역**:
1. **Phase 4의 Feature Execution이 블랙박스**: PM이 simon-bot에게 작업을 위임하지만 실행 중 feedback loop가 약함. Blog의 orchestrator-workers는 "synthesizes results"를 강조 -- 단순 위임이 아닌 중간 결과 확인 및 방향 조정 필요
2. **Failure Recovery가 단순**: 3단계(자동진단 -> grind 전환 -> 에스컬레이션)로 Blog의 evaluator-optimizer 패턴을 적용할 여지 있음

### 3.4 simon-bot-report (Analysis)

**강점**:
- Read-only 원칙 -- 안전한 분석
- 5개 도메인팀 병렬 분석 -- Blog의 sectioning parallelization 패턴
- Interactive Guided Review -- Blog의 "transparency" 원칙 실천
- 구조화된 출력 (CRITICAL/HIGH/MEDIUM severity)

**개선 영역**:
1. **Step 2와 Step 3의 중복**: Code Design Team이 Step 2에서 분석하고, Step 3에서 다시 등장. 두 단계를 통합하거나 Step 2를 Step 3의 사전 준비로 명확히 구분
2. **고정 전문가 구성**: Blog의 routing 패턴처럼, 분석 주제에 따라 관련 도메인팀만 활성화하는 동적 라우팅이 더 효율적

### 3.5 simon-bot-sessions (Utility)

**강점**:
- 단순한 CRUD 유틸리티로 Blog의 "simplicity" 원칙에 부합
- 복잡한 agent 패턴을 사용하지 않음 -- 적절

**개선 영역**:
1. **resume 시 컨텍스트 복원이 파일 목록 기반**: 더 스마트한 복원을 위해 "마지막 완료 Step"과 "다음 실행 Step"을 명시적으로 기록/복원하면 이어가기가 더 자연스러울 수 있음

---

## 4. Cross-Cutting Improvement Themes

### Theme A: Routing Layer (Entry Point Optimization)

현재 사용자가 5개 스킬 중 적합한 것을 직접 선택해야 한다. Blog의 routing 패턴을 적용하여:

```
User Request
    |
    v
[Router] -- 분류 --> simon-bot (MICRO/SMALL/STANDARD/LARGE)
                  --> simon-bot-grind (자동 전환으로만 진입)
                  --> simon-bot-pm (프로젝트 수준)
                  --> simon-bot-report (분석만)
                  --> simon-bot-sessions (세션 관리)
```

**구현 방법**: 각 스킬의 description에 있는 키워드 매칭을 넘어서, 요청 분석 -> 적합 스킬 추천 -> 사용자 확인의 라우팅 워크플로 도입.

### Theme B: Feedback-Driven Iteration (Ground Truth Utilization)

Blog의 핵심 인사이트 중 하나: "Agents gain ground truth from environmental feedback (tool results, code execution)."

현재 스킬들은 환경 피드백(테스트 결과, 빌드 출력, lint 결과)을 받지만, 이를 구조화된 형태로 변환하여 다음 결정에 활용하는 체계가 약하다.

**제안**: 모든 환경 피드백을 `{type, severity, message, context, suggested_action}` 형태로 파싱하는 공통 피드백 파서를 도입하고, 이를 retry/review 단계에서 활용.

### Theme C: Progressive Complexity (Gradual Escalation)

Blog: "Start with simple prompts, optimize comprehensively, add multi-step systems only when justified by measured improvements."

**현재 문제**: simon-bot과 simon-bot-grind가 별개 스킬로, 사용자가 미리 복잡도를 선택해야 함.

**제안**: 하나의 통합 파이프라인에서 실패에 따라 복잡도가 자동 상승하는 모델:
- Level 0: 단순 구현 (MICRO path)
- Level 1: 표준 파이프라인 (simon-bot SMALL)
- Level 2: 전체 파이프라인 (simon-bot STANDARD)
- Level 3: 열일 모드 (grind 확장 자동 활성화)

각 Level은 이전 Level에서 실패한 경우에만 활성화.

### Theme D: Framework Warning

Blog: "Frameworks create abstraction layers obscuring underlying prompts and responses, complicating debugging. Start with direct LLM API usage."

simon-bot 스킬 자체가 일종의 "framework" 역할을 한다. 19-step pipeline은 강력하지만, 디버깅이 어려울 수 있다.

**제안**:
- 각 Step의 입력/출력을 `.claude/memory/`에 명시적으로 기록 (현재도 일부 수행하지만, 모든 Step에 일관되게)
- 실패 시 해당 Step의 입출력을 빠르게 확인할 수 있는 디버그 모드 도입

---

## 5. Priority Matrix

### Immediate (HIGH priority, high impact)

| # | 제안 | 대상 | 예상 효과 |
|---|------|------|----------|
| S1 | MICRO path 신설 | simon-bot | 간단한 작업의 효율 대폭 향상 |
| S2 | Adaptive complexity (4-tier scope) | simon-bot | 불필요한 오버헤드 제거 |
| W1 | Routing 레이어 | 전체 | 사용자 경험 개선, 적합 스킬 자동 선택 |
| W3 | Evaluator-Optimizer 종료 기준 | simon-bot-grind | 비용 절감, compounding error 방지 |
| C3 | Grind budget cap | simon-bot-grind | 무한 retry 방지 |
| E1 | Test result structured feedback | simon-bot | TDD 루프 효율 향상 |

### Short-term (MEDIUM priority)

| # | 제안 | 대상 | 예상 효과 |
|---|------|------|----------|
| S3 | grind 모드 자동 전환 | simon-bot-grind | Progressive complexity 실현 |
| W2 | Voting 패턴 도입 (Plan Review) | simon-bot | 다양한 관점 확보 |
| T1 | Step-level progress bar | simon-bot | 투명성 향상 |
| T2 | Decision log 투명화 | simon-bot | 사용자 신뢰 향상 |
| A1 | Agent role specification 표준화 | simon-bot | 일관된 agent 품질 |
| A2 | Structured output 강제 | simon-bot, report | 후속 처리 효율 |
| C1 | Cost-aware decision points | simon-bot | 사용자 기대치 관리 |
| C2 | Progressive agent activation | simon-bot, report | 비용 절감 |
| E2 | Build output structured feedback | simon-bot, grind | 디버깅 효율 향상 |
| M1 | Cross-session memory accumulation | simon-bot | 장기 학습 효과 |

### Long-term (LOW priority, exploratory)

| # | 제안 | 대상 | 예상 효과 |
|---|------|------|----------|
| T3 | PM progress dashboard | simon-bot-pm | 대규모 프로젝트 관리 편의 |
| A3 | Poka-yoke for file paths | simon-bot | 사소한 에러 방지 |
| M2 | Retrieval 확장 (PR history) | simon-bot | 맥락 풍부화 |

---

## 6. Anti-Patterns to Watch (Blog Warnings Applied)

Blog이 경고하는 안티패턴이 현재 스킬에 존재하는 영역:

1. **Over-engineering before validation**: simon-bot-grind의 전체 retry 한계를 10으로 설정하는 것은 필요 이전에 복잡도를 추가하는 패턴. "실패 빈도 데이터에 기반한 적응적 한계"가 Blog 원칙에 더 부합.

2. **Framework abstraction trap**: 19-step pipeline 자체가 추상화 레이어. 새로운 팀 멤버나 다른 프로젝트에서 디버깅이 어려울 수 있음. 각 step의 역할과 건너뛸 수 있는 조건을 더 명확히 문서화 필요.

3. **Compounding errors in long chains**: 19-step sequential chain에서 초기 step(planning)의 오류가 후속 step에 전파될 수 있음. Blog은 "programmatic gates"를 권장하며 이미 Calibration Checklist이 있지만, Phase B-E 진입 후에도 중간 검증 게이트(Step 6 Purpose Alignment 외 추가)가 있으면 좋겠음.

4. **Autonomous agent without sufficient guardrails**: simon-bot-grind가 10회 retry를 자율적으로 진행하는 동안, "ground truth" 확인이 충분한가? 매 retry가 환경 피드백(테스트 결과)에 기반하는지 확인 필요.

---

## 7. Conclusion

simon-bot 스킬 패밀리는 이미 Blog에서 제시하는 많은 패턴(prompt chaining, parallelization, orchestrator-workers, evaluator-optimizer, guardrails, memory)을 잘 활용하고 있다. 특히 Agent Teams를 통한 전문가 토론, TDD 기반 구현, 체계적 리뷰 파이프라인은 우수하다.

가장 큰 개선 기회는 **"Simplicity First"** 원칙의 적용이다:
1. 간단한 작업을 위한 경량 경로(MICRO path)
2. 복잡도의 자동 점진적 상승(Progressive complexity)
3. 스킬 자동 라우팅(Routing layer)

그 다음으로 중요한 것은 **환경 피드백의 구조화**(테스트/빌드 결과 파싱)와 **비용 인식**(retry 예산, agent 활성화 최적화)이다.

Blog의 핵심 메시지를 한 문장으로 요약하면: **"필요한 만큼만 복잡하게, 그 복잡성은 측정된 개선으로 정당화하라."** 이 원칙을 simon-bot 스킬 발전의 나침반으로 삼을 것을 권장한다.
