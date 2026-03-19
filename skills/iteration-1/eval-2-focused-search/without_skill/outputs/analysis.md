# Analysis: simon-bot Skills vs Latest Claude Code Best Practices

분석일: 2026-03-13

## 분석 방법론

1. Claude Code 공식 문서 6개 페이지에서 프롬프트 엔지니어링 및 컨텍스트 관리 최신 기법 추출
2. simon-bot 계열 12개 스킬(SKILL.md) 전수 분석
3. 현재 스킬이 잘 하고 있는 점, 최신 기법 대비 갭, 개선 가능 영역 도출

---

## 1. 현재 스킬이 잘 하고 있는 점

### 1-A. 컨텍스트 관리 (강점)

| 항목 | 현재 구현 | 평가 |
|------|----------|------|
| Reference Loading Policy | Phase별 선택적 로딩 | 공식 권장사항 완벽 부합 |
| Session Isolation Protocol | 홈 디렉토리 기반 세션별 격리 | 공식 서브에이전트 패턴 선행 구현 |
| Memory Persistence | 단계별 상태 파일 저장 | 세션 분할/복원 기반 잘 설계됨 |
| 세션 분할 경계 | Phase A/Integration/Step 18 기준 | 명확한 분할점 정의 |
| Composable CLI Script Toolkit | CLI로 데이터 사전 압축 후 LLM 전달 | 공식 "pipe" 철학과 일치 |

### 1-B. 프롬프트 엔지니어링 (강점)

| 항목 | 현재 구현 | 평가 |
|------|----------|------|
| Deterministic Gate Principle | 결정론적 검증은 bash, LLM은 판단만 | 공식 hooks 철학과 일치 |
| Stop-and-Fix Gate | 실패 즉시 수정 강제 | 검증 기반 접근법 |
| Decision Journal | Anti-Oscillation Rule 포함 | 체계적 의사결정 기록 |
| Error Resilience 분류 | ENV_INFRA / CODE_LOGIC / WORKFLOW_ERROR | 구조적 에러 처리 |
| Cognitive Independence | Blind-First 리뷰 프로토콜 | 리뷰 품질 보장 |

### 1-C. 스킬 구조 (강점)

| 항목 | 현재 구현 | 평가 |
|------|----------|------|
| Progressive Disclosure | references/ 분리, Phase별 로딩 지시 | 잘 설계됨 |
| Skill Decomposition | simon-bot → simon-bot-review 분리 | 독립 호출 + 연결 모드 양립 |
| Expert Panel Pattern | 6인 전문가 패널 (boost) | 다각적 분석 |
| Self-Improvement (Step 20) | 워크플로 자기 개선 | 메타 개선 루프 |

---

## 2. 갭 분석: 최신 기법 대비 부족한 영역

### GAP-1: 서브에이전트 영구 메모리 (Persistent Memory) 미활용

**최신 기법**: 서브에이전트에 `memory: user|project|local` 필드를 설정하면 세션 간 학습을 자동 축적. MEMORY.md 첫 200줄이 매 호출 시 자동 주입됨.

**현재 상태**: simon-bot은 자체 `.claude/memory/` 파일 시스템으로 상태를 관리하지만, Claude Code 네이티브의 서브에이전트 영구 메모리 기능을 활용하지 않음. 커스텀 서브에이전트(`.claude/agents/`)를 아직 정의하지 않음.

**영향**: 전문가 에이전트(architect, security-reviewer 등)가 세션 간에 학습을 축적할 수 없어, 매번 동일한 코드베이스 패턴을 재탐색해야 함.

### GAP-2: 동적 컨텍스트 주입 (!`command` 구문) 미활용

**최신 기법**: SKILL.md에서 `!`command``로 셸 명령 출력을 스킬 콘텐츠에 동적 삽입. Claude가 보기 전에 전처리됨.

**현재 상태**: simon-bot은 Startup에서 bash 명령을 순차 실행하여 상태를 로딩하지만, `!`command`` 전처리 구문을 사용하지 않음. 모든 환경 정보 수집이 LLM 턴을 소비함.

**영향**: 스킬 로딩 시 환경 정보(git 상태, 브랜치, 프로젝트 설정 등)를 자동 삽입하면 Startup 단계에서 여러 LLM 턴을 절약할 수 있음.

### GAP-3: 커스텀 서브에이전트 정의 (`.claude/agents/`) 미활용

**최신 기법**: `.claude/agents/` 또는 `~/.claude/agents/`에 커스텀 서브에이전트를 Markdown 파일로 정의. 모델, 도구, 권한, 훅, 스킬 사전로딩 등을 선언적으로 설정 가능.

**현재 상태**: simon-bot은 `Agent(subagent_type="general-purpose")` 호출 시 매번 프롬프트를 인라인으로 전달. 재사용 가능한 에이전트 정의가 없음.

**영향**: architect, security-reviewer, executor 등 반복 사용하는 에이전트 역할을 사전 정의하면:
- 일관된 도구 제한 및 권한
- 스킬 사전로딩으로 도메인 지식 자동 주입
- 영구 메모리로 세션 간 학습

### GAP-4: ultrathink / Extended Thinking 명시적 활용 미비

**최신 기법**: 스킬 콘텐츠에 "ultrathink" 포함 시 해당 스킬 실행 중 extended thinking 자동 활성화. Opus 4.6의 adaptive reasoning과 연동.

**현재 상태**: simon-bot 스킬 어디에도 "ultrathink" 키워드가 없음. Phase A의 아키텍처 분석, Step 7의 보안 리뷰 등 깊은 추론이 필요한 단계에서 명시적으로 확장 추론을 요청하지 않음.

**영향**: 복잡한 아키텍처 결정이나 보안 리뷰에서 reasoning 깊이가 부족할 수 있음.

### GAP-5: /compact 커스터마이징 지시 부재

**최신 기법**: CLAUDE.md에 "When compacting, always preserve the full list of modified files and any test commands" 같은 지시를 포함하면 자동 압축 시 중요 컨텍스트 보존 가능. /compact <instructions>로 초점 지정도 가능.

**현재 상태**: simon-bot의 Context Window Management 섹션은 "자동 압축되므로 걱정하지 마라"고만 명시. 압축 시 무엇을 보존해야 하는지에 대한 지시가 없음.

**영향**: 자동 압축 시 plan-summary, decision-journal, failure-log 등 핵심 워크플로 상태가 소실될 수 있음.

### GAP-6: context: fork / 서브에이전트 실행 스킬 패턴 미활용

**최신 기법**: SKILL.md frontmatter에 `context: fork`와 `agent: Explore|Plan|커스텀`을 설정하면 스킬이 격리된 서브에이전트에서 실행됨. 메인 컨텍스트 오염 없이 무거운 작업 수행 가능.

**현재 상태**: simon-bot-boost-capture만 유사 패턴(background Agent spawn)을 사용. 나머지 스킬은 모두 메인 컨텍스트에서 실행.

**영향**: simon-bot-report (사전 분석) 등 읽기 전용 분석 스킬을 `context: fork, agent: Explore`로 실행하면 메인 컨텍스트를 보호할 수 있음.

### GAP-7: /btw (side question) 활용 안내 없음

**최신 기법**: `/btw` 명령으로 컨텍스트 히스토리에 들어가지 않는 일회성 질문 가능. 디테일 확인에 컨텍스트 소비 없음.

**현재 상태**: 워크플로 중 사용자 질문을 모두 AskUserQuestion으로 처리하며, /btw 활용 패턴이 없음.

**영향**: 사용자가 진행 상황이나 세부사항을 확인할 때 불필요한 컨텍스트 소비 발생.

### GAP-8: 스킬 내 훅 정의 미활용

**최신 기법**: SKILL.md frontmatter에서 hooks를 직접 정의하여 스킬 활성 시에만 작동하는 훅 설정 가능.

**현재 상태**: Auto-Verification Hook을 SKILL.md 본문에서 텍스트로 안내하지만, frontmatter의 `hooks` 필드로 선언적 정의하지 않음.

**영향**: Auto-Verification이 LLM 기억에 의존하는 advisory 수준. 훅으로 선언하면 결정론적 실행이 보장됨.

### GAP-9: isolation: worktree 서브에이전트 미활용

**최신 기법**: 서브에이전트에 `isolation: worktree`를 설정하면 임시 git worktree에서 실행. 변경 없으면 자동 정리.

**현재 상태**: simon-bot은 자체 worktree 관리 로직을 구현하고 있음. Claude Code 네이티브 `isolation: worktree` 기능은 사용하지 않음.

**영향**: 네이티브 worktree 격리를 활용하면 커스텀 worktree 관리 코드를 줄이고 자동 정리도 활용 가능.

### GAP-10: 스킬 description 최적화 여지

**최신 기법**: description은 Claude가 자동 호출 결정에 사용하는 핵심 필드. "Use when:" 조건이 명확하고 실사용 키워드를 포함해야 함. 스킬 간 경계가 명확해야 함.

**현재 상태**: description이 매우 길고 상세하여 (simon-bot: 약 200자+), 컨텍스트 예산(2% of context window)을 빠르게 소비. 특히 12개 스킬의 description이 모두 로딩되면 상당한 토큰 소비.

**영향**: 공식 문서에서 "If you have many skills, they may exceed the character budget" 경고. description을 간결하게 줄이되 트리거 정확도는 유지해야 함.

---

## 3. 프롬프트 엔지니어링 관점 심층 분석

### 3-A. 에이전트 역할 정의 구체성

**현재**: simon-bot은 전문가 역할(architect, security-reviewer 등)을 Agent 호출 시 인라인 프롬프트로 전달. 매번 역할 정의를 반복.

**기회**: `.claude/agents/`에 사전 정의하면:
- 일관된 역할 정의 보장
- 도구 범위를 선언적으로 제한 (현재 P-011로 텍스트 지시)
- 스킬 사전로딩으로 도메인 지식 자동 주입

### 3-B. Few-shot 예시 활용

**현재**: decision-journal의 예시, User Interaction Recording의 예시 등 일부 있으나, 대부분의 단계에서 출력 형식 예시가 부족.

**기회**: 핵심 산출물(expert findings, code design analysis 등)에 대한 good/bad 예시를 references에 추가하면 출력 품질이 향상됨.

### 3-C. 프롬프트 지시의 행동적 구체성

**현재**: "검증한다", "분석한다" 같은 추상적 지시가 일부 존재. 특히 Phase B-E의 Step 설명이 SKILL.md에서는 1-2줄 요약이고, references에서 상세 내용이 있는 구조.

**기회**: 공식 best practices의 "Provide specific context in your prompts" 원칙에 따라, 각 Step의 핵심 판단 기준을 SKILL.md 수준에서 명시하면 references 로딩 전에도 기본 판단이 가능.

### 3-D. 검증 수단 사전 정의

**현재**: Auto-Verification Hook이 빌드/린트/테스트를 실행하지만, 각 Step의 "이 Step이 성공했다"의 기준이 명시적이지 않은 경우 있음.

**기회**: 각 Step에 "검증 명령어" + "성공 기준"을 pair로 명시하면 Stop-and-Fix Gate의 실효성 강화.

---

## 4. 컨텍스트 관리 관점 심층 분석

### 4-A. 컨텍스트 소비 프로파일

simon-bot 19-step 파이프라인에서 컨텍스트를 가장 많이 소비하는 구간:

1. **Phase A (Planning)**: 전문가 패널 토론, 코드 분석 — 대량 파일 읽기
2. **Step 7 (Bug/Security/Performance Review)**: 도메인팀 Agent Team 분석
3. **Step 18 (Work Report)**: Before/After 다이어그램, 보고서 작성

**기회**: Phase A의 코드 분석과 Step 7의 도메인 분석을 서브에이전트 영구 메모리로 누적하면, 반복 프로젝트에서 탐색 비용이 감소.

### 4-B. 자동 압축 시 보존 전략

**현재**: "자동 압축이 발생해도 `.claude/memory/`에 상태가 저장되어 있으므로 작업을 계속 진행한다"

**문제**: 자동 압축은 대화 히스토리를 요약하는 것이지, 워크플로 상태를 보존하는 것이 아님. 중요한 워크플로 결정(decision-journal의 내용)이 압축 시 소실될 수 있음.

**기회**:
- 프로젝트 CLAUDE.md에 "When compacting, preserve: current step, active plan-summary decisions, failure-log patterns" 추가
- 핵심 상태를 파일에 저장하는 것 외에, 압축 후 재로딩할 파일 목록을 명시

### 4-C. 스킬 간 컨텍스트 전달

**현재**: simon-bot → simon-bot-review 전환 시 review-sequence.md, branch-name.md 등 파일 기반 핸드오프.

**기회**: `context: fork` + `skills` 사전로딩으로 핸드오프할 때 필요한 도메인 지식을 자동 주입하면 전환 비용 감소.

### 4-D. description 토큰 예산

**현재**: 12개 simon-bot 계열 스킬의 description이 모두 세션 시작 시 로딩됨. 각 description이 200-400자로, 총 3000-5000자 추정.

**공식 제한**: 스킬 description 예산은 컨텍스트 윈도우의 2% (fallback 16,000자). 다른 스킬(git-commit, git-push-pr 등)도 로딩되므로 예산 압박 가능.

**기회**:
- description을 핵심 트리거 키워드 중심으로 간결하게 축소
- `disable-model-invocation: true`인 스킬은 description이 컨텍스트에 로딩되지 않으므로, 수동 호출만 필요한 스킬에 적용 고려

---

## 5. 요약: 우선순위별 개선 영역

### CRITICAL (즉시 적용 가치 높음)
1. **GAP-5**: /compact 보존 지시 추가 — 워크플로 상태 소실 방지
2. **GAP-8**: 스킬 내 hooks frontmatter로 Auto-Verification 선언적 정의
3. **GAP-2**: !`command` 동적 컨텍스트 주입으로 Startup 최적화

### HIGH (중기 개선)
4. **GAP-3**: 커스텀 서브에이전트 정의 (architect, security-reviewer 등)
5. **GAP-4**: ultrathink 키워드 전략적 배치
6. **GAP-10**: description 간결화 및 토큰 예산 최적화
7. **GAP-1**: 서브에이전트 영구 메모리 활용

### MEDIUM (점진 개선)
8. **GAP-6**: context: fork 패턴 적용 (simon-bot-report 등)
9. **GAP-7**: /btw 활용 가이드
10. **GAP-9**: isolation: worktree 네이티브 활용
