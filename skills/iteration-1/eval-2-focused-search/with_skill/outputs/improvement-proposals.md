# Phase 4: 개선안 승인 & 적용 (DRY-RUN)

> **DRY-RUN 모드**: 실제 스킬 파일을 수정하지 않고, 모든 제안을 자동 승인하여 proposed diffs를 생성합니다.

## 승인 결과

| ID | 제목 | 심각도 | 판정 |
|---|---|---|---|
| P-001 | 컨텍스트 활용률 모니터링 & 선제적 Compaction | HIGH | **적용** |
| P-002 | 세션 진입 프로토콜에 Startup Verification | MEDIUM | **적용** |
| P-003 | Altitude Calibration 원칙 도입 | HIGH | **적용** |
| P-004 | 서브에이전트 반환 크기 가이드라인 | MEDIUM | **적용** |
| P-005 | Instructions vs Guidance 이원 분류 | HIGH | **적용** |
| P-006 | Just-In-Time Retrieval 전문가 프롬프트 최적화 | MEDIUM | **적용** |
| P-007 | Compaction 후 Critical State 복원 검증 | HIGH | **적용** |
| P-008 | Step Progress에 컨텍스트 활용률 표시 | LOW | **적용** |
| P-009 | Reference Loading Policy 전략 선택 기준 | MEDIUM | **적용** |

---

## Proposed Diffs

### P-001: 컨텍스트 활용률 모니터링 & 선제적 Compaction 트리거

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: Context Window Management 섹션

```diff
 ## Context Window Management

 컨텍스트 윈도우가 자동 압축(compact)되므로, 토큰 예산 걱정으로 작업을 조기에 중단하지 않는다. 압축이 발생해도 `.claude/memory/`에 상태가 저장되어 있으므로 작업을 계속 진행한다.

+### 선제적 Compaction 전략
+
+자동 압축에만 의존하면 이미 회상 정확도가 저하된(context rot) 상태에서 압축이 실행될 수 있다.
+Step 전환 시점에서 다음을 권장한다:
+
+1. `/context`로 활용률을 확인한다
+2. 70% 이상이면 핵심 상태(현재 Step, 활성 규칙, Done-When Checks)를 memory 파일에 저장한 후 `/compact`를 실행한다
+3. 이전 Step의 도구 결과(긴 빌드 출력, 대량 grep 결과 등)는 compaction 시 자연스럽게 요약되어 컨텍스트 효율이 향상된다
+
+이를 통해 "attention budget"을 효율적으로 사용하고, 후반 Step에서의 성능 저하를 방지한다.
+
 ### 새 세션 시작 프로토콜
```

---

### P-002: 세션 진입 프로토콜에 Startup Verification 추가

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: Context Window Management > 새 세션 시작 프로토콜

```diff
 ### 새 세션 시작 프로토콜

 새 세션에서 작업을 재개할 때 다음 순서를 따른다:
 1. `pwd`로 현재 디렉토리 확인
 2. `CONTEXT.md` + `.claude/memory/*.md` 읽기
 3. `git log --oneline -10`으로 최근 변경 확인
 4. 마지막 완료 Step 이후부터 재개
+5. `verify-commands.md`의 빌드 명령을 실행하여 이전 세션의 코드가 정상 상태인지 확인한다. 실패 시 이전 세션의 미수정 이슈를 먼저 해결한 후 작업을 재개한다. 이를 통해 이전 세션에서 문서화되지 않은 버그가 새 작업에 누적되는 것을 방지한다.
```

---

### P-003: Altitude Calibration 원칙 도입

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: Cross-Cutting Protocols (Reference Loading Policy 앞)

```diff
+### Prompt Altitude Calibration
+
+에이전트에게 전달하는 프롬프트의 구체성 수준을 의도적으로 조절한다. 너무 구체적이면 경직되어 예외 상황에 대응하지 못하고, 너무 모호하면 행동 신호가 부족하여 기대와 다른 결과를 낳는다.
+
+- **Instruction** (행동 지시): 구체적으로 — "E2E 테스트를 Playwright로 작성한다", "빌드 실패 시 다음 Step으로 진행하지 않는다"
+- **Guidance** (행동 규범): 유연하게 — "테스트는 서로 독립적이어야 한다", "plan-summary.md에 명시된 변경만 구현한다"
+
+프롬프트 작성 시 각 지시문이 Instruction인지 Guidance인지 구분하고, Guidance에 불필요한 구체성을 넣거나 Instruction에서 핵심 세부사항을 빠뜨리지 않는다.
+
 ### Reference Loading Policy (컨텍스트 효율)
```

---

### P-004: 서브에이전트 반환 크기 가이드라인 명시

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: Subagent 사용 기준 섹션 끝

```diff
 단일 파일 수정, 간단한 검색, 단순 명령 실행은 직접 수행한다. 불필요한 subagent 생성은 컨텍스트를 낭비한다.

+서브에이전트가 결과를 반환할 때, 전체 분석 내용이 아닌 압축된 요약(1,000-2,000 토큰)을 반환한다. 상세 분석은 memory 파일에 저장하고, 반환값에는 핵심 결론과 파일 참조만 포함한다. 서브에이전트 내부의 심층 작업 컨텍스트가 오케스트레이터로 유출되면 오케스트레이터의 attention budget을 불필요하게 소비하기 때문이다.
+
 ### Over-engineering 방지
```

---

### P-005: Instructions vs Guidance 이원 분류 체계 도입

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: Cross-Cutting Protocols 섹션 도입부 (## Cross-Cutting Protocols 직후)

```diff
 ## Cross-Cutting Protocols

+이 섹션의 프로토콜은 두 종류로 나뉜다:
+- **Instruction** (행동 지시): 특정 상황에서 반드시 수행해야 할 구체적 행동. 무시하면 워크플로가 깨진다.
+  - Auto-Verification Hook, Stop-and-Fix Gate, Deterministic Gate Principle, Step Transition Gate
+- **Guidance** (행동 규범): 전반적으로 따라야 할 원칙이지만 상황에 따라 유연하게 적용 가능. 무시하면 품질이 저하된다.
+  - Over-engineering 방지, Parallel Tool Invocation, Prompt Altitude Calibration, Docs-First Protocol
+
+LLM은 두 종류를 구분하지 못하면 모든 것을 Guidance로 취급하여 중요한 게이트를 건너뛸 수 있다. Instruction을 명시적으로 식별하여 준수율을 높인다.
+
 ### Error Resilience
```

---

### P-006: Just-In-Time Retrieval 전문가 프롬프트 최적화

**파일**: `~/.claude/skills/simon-bot/references/phase-a-planning.md`
**위치**: Step 4-B 통합 전문가 팀 생성 섹션 앞

```diff
 ### 통합 전문가 팀 생성 (Agent Teams 제약: 세션당 1팀)

 > **Agent Teams Fallback**: Agent Teams 미활성 시 `agent-teams.md`의 Fallback 절차를 따른다.

+> **컨텍스트 효율**: 전문가 팀에 plan-summary.md 전체를 전달하지 않는다. 각 도메인 전문가에게 관련 섹션의 경량 식별자(섹션 마커, 파일 경로)를 전달하고, 필요한 부분만 직접 Read하도록 지시한다. 예: Safety Team에는 plan-summary.md의 Concerns 섹션 + 인증/보안 관련 코드 경로만, Data Team에는 Task 섹션 + DB 관련 파일 경로만 전달한다. 이를 통해 전문가별 컨텍스트 소비를 줄이고 관련 정보에 집중하도록 한다.

 `TeamCreate(team_name="expert-review", description="도메인 전문가 통합 리뷰 팀")`
```

---

### P-007: Compaction 후 Critical State 복원 검증

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: Context Window Management > 선제적 Compaction 전략 다음 (P-001 이후)

```diff
+### Compaction 후 상태 검증
+
+자동 또는 수동 compaction 후 다음 항목이 컨텍스트에 유지되고 있는지 확인한다:
+1. 현재 진행 중인 Step 번호와 상태
+2. 활성 Forbidden Rules (특히 ABSOLUTE FORBIDDEN)
+3. 현재 Unit의 Done-When Checks
+
+유지되지 않는 항목이 있으면 해당 memory 파일을 다시 읽는다. compaction 시 규칙이 소실되면 게이트가 무력화될 수 있으므로(Deterministic Gate Principle 참조), 이 검증으로 구조적으로 방지한다.
+
 ### 새 세션 시작 프로토콜
```

---

### P-008: Step Progress에 컨텍스트 활용률 표시

**파일**: `~/.claude/skills/simon-bot/references/phase-b-implementation.md`
**위치**: Step Progress Pulse (P-007) 규칙 내

```diff
 - **Step Progress Pulse (P-007)**: 각 Step 완료 시 사용자에게 1줄 상태를 출력한다 (AskUserQuestion이 아닌 단순 텍스트 출력이므로 사용자를 중단시키지 않는다). 형식: `[Step {N}/{total}] {Step명} 완료 — {핵심 결과 요약}`. 예: `[Step 7/17] Expert Review 완료 — CRITICAL 0, HIGH 2, MEDIUM 5`. Phase B-E 시작 시 예상 Step 수를 안내한다: `{경로} 경로: Steps 5-{N} ({M} steps)`.
+  컨텍스트 활용률이 60%를 초과한 경우 Step Progress Pulse에 활용률을 표시한다: `[Step 7/17] Expert Review 완료 — CRITICAL 0, HIGH 2 | ctx: 68%`. 사용자가 세션 분할 시점을 사전에 인지할 수 있다.
```

---

### P-009: Reference Loading Policy에 전략 선택 기준 추가

**파일**: `~/.claude/skills/simon-bot/SKILL.md`
**위치**: Context Window Management 섹션 내 (세션 분할 경계 앞)

```diff
+### 작업 특성별 컨텍스트 전략 선택
+
+작업 특성에 따라 컨텍스트 관리 전략을 선택한다:
+- **Compaction 중심**: 광범위한 대화가 필요한 작업 (Phase A 인터뷰, 디버깅). `/compact`와 세션 분할을 적극 활용
+- **Note-taking 중심**: 명확한 마일스톤이 있는 반복 개발 (Phase B-E TDD 사이클). Decision Journal, CONTEXT.md, memory 파일에 상태를 기록하여 compaction 후에도 복원 가능하게 함
+- **Multi-agent 중심**: 병렬 탐색이 유리한 분석 작업 (Step 4-B 전문가 패널, Step 7 검증). 서브에이전트의 독립 컨텍스트를 활용하여 오케스트레이터의 컨텍스트를 보존
+
+이 스킬은 이미 세 전략을 모두 사용한다. 새로운 상황에서 적절한 전략을 선택할 때 위 기준을 참고한다.
+
 ### 세션 분할 경계
```

---

## 적용 기록 (applied-log.md에 추가될 내용)

```markdown
## [AUTO-BOOST] 2026-03-13 (DRY-RUN)
- 검색 범위: 첫 실행 (최근 2주)
- 소스: 4건 분석
  - https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html
  - https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
  - https://medium.com/@rentierdigital/... (paywall — 스니펫 기반)
  - https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- 적용: 9건 / 보류: 0건 / 거부: 0건

### 적용된 변경
1. [simon-bot] 선제적 Compaction 전략 — Workflow Architect / 파일: SKILL.md / 변경: Context Window Management에 선제적 compaction 가이드 추가
2. [simon-bot] 세션 진입 Startup Verification — Workflow Architect / 파일: SKILL.md / 변경: 새 세션 시작 프로토콜에 빌드 검증 단계 추가
3. [simon-bot] Prompt Altitude Calibration — Prompt Engineer / 파일: SKILL.md / 변경: Cross-Cutting에 Instruction vs Guidance 구체성 수준 가이드 추가
4. [simon-bot] 서브에이전트 반환 크기 가이드라인 — Prompt Engineer / 파일: SKILL.md / 변경: Subagent 사용 기준에 1,000-2,000 토큰 반환 가이드 추가
5. [simon-bot] Instructions vs Guidance 이원 분류 — Innovation Scout / 파일: SKILL.md / 변경: Cross-Cutting Protocols 도입부에 분류 체계 추가
6. [simon-bot] Just-In-Time Retrieval 전문가 프롬프트 — Innovation Scout / 파일: phase-a-planning.md / 변경: 전문가 팀 컨텍스트 최적화 가이드 추가
7. [simon-bot] Compaction 후 상태 검증 — Quality & Safety Guardian / 파일: SKILL.md / 변경: compaction 후 critical state 복원 검증 절차 추가
8. [simon-bot] Step Progress 컨텍스트 표시 — DX Specialist / 파일: phase-b-implementation.md / 변경: 활용률 60% 초과 시 Progress에 ctx 표시
9. [simon-bot] 컨텍스트 전략 선택 기준 — Skill Craft Specialist / 파일: SKILL.md / 변경: 작업 특성별 Compaction/Note-taking/Multi-agent 전략 선택 가이드 추가
```
