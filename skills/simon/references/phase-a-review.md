# Phase A: Plan Review (Detailed Instructions)

> **연속 문서**: 이 파일은 `phase-a-planning.md`의 후속 문서입니다.
> Phase A Steps 0, 1-A, 1-B는 `phase-a-planning.md`를 참조하세요.

## 목차
- [Step 1-B-post: Spec Validation](#step-1-b-post-spec-validation--ac-사용자-시나리오-확인)
- [Steps 2-4: Plan Review (Agent Team)](#steps-2-4-plan-review-agent-team)
  - [Step 2: Plan Review](#step-2-plan-review)
  - [Step 3: Meta Verification](#step-3-meta-verification)
  - [Step 4: Over-engineering Check](#step-4-over-engineering-check)
- [Step 4-B: Expert Plan Review](#step-4-b-expert-plan-review--도메인팀-agent-team-토론)
  - [팀 활성화 규칙](#팀-활성화-규칙-configyaml--expert_panelteam_activation)
  - [통합 전문가 팀 생성](#통합-전문가-팀-생성-agent-teams-제약-세션당-1팀)
  - [도메인별 작업 정의](#도메인별-작업-정의-taskcreate)
  - [토론 로그 저장](#토론-로그-저장-필수)
  - [Findings 품질 원칙 (P-008)](#findings-품질-원칙--깊이--수량-p-008)
  - [Agent Scope Anti-Goals (P-003)](#agent-scope-anti-goals-p-003)
  - [Lead의 Cross-team Synthesis](#lead의-cross-team-synthesis)
- [Phase A Calibration Checklist](#phase-a-calibration-checklist-phase-b-진입-전-검증)

## Step 1-B-post: Spec Validation — AC 사용자 시나리오 확인

Step 1-B 완료 후, 기술 용어로 작성된 AC가 사용자의 실제 의도와 일치하는지 확인한다. "spec이 처음부터 틀리면 모든 검증이 무의미"하기 때문이다.

- **트리거**: 모든 경로에서 적용
- **절차**:
  1. `spec-validator` subagent (model: sonnet)가 plan-summary.md의 Acceptance Criteria(특히 Behavioral Checks)를 **구체적 사용자 시나리오**로 번역
  2. 기술 용어를 사용자가 이해할 수 있는 언어로 변환
  3. 사용자에게 AskUserQuestion으로 확인 요청

- **변환 예시**:
  - 기술 AC: `POST /api/auth/login에 invalid credentials → 401 + {error: 'INVALID_CREDENTIALS'}`
  - 사용자 시나리오: "로그인 화면에서 틀린 비밀번호를 입력하고 '로그인' 버튼을 누르면, 화면에 'INVALID_CREDENTIALS'라는 에러 코드가 표시됩니다. 이게 맞나요?"

- **결과 처리**:
  - 사용자 "맞다" → Steps 2-4 진행
  - 사용자 "아니다" / 수정 요청 → AC 수정 후 plan-summary.md 갱신

## Steps 2-4: Plan Review (Agent Team)

> **Agent Teams Fallback**: Agent Teams 미활성 시 `agent-teams.md`의 Fallback 절차를 따른다.

**팀 생성**: `TeamCreate(team_name="plan-review", description="계획 리뷰 팀")`
- 컨텍스트: `.claude/memory/plan-summary.md`, `.claude/memory/requirements.md`, `.claude/memory/code-design-analysis.md`

**팀원 spawn** (병렬, `team_name="plan-review"`):
- `Agent(name="planner")` — plan 수정/방어 담당
- `Agent(name="critic")` — 논리/실현성 검증 담당
- `Agent(name="architect")` — 구조 검증 + YAGNI/KISS 검증 담당

### Step 2: Plan Review
- Task "plan-review": critic ←→ planner 직접 토론 (`SendMessage`로)
- Max 3 iterations (config `loop_limits.critic_planner`)
- **품질 기반 조기 종료**: critic이 매 iteration 종료 시 4개 축을 1-5점으로 평가한다:
  - **Completeness** (요구사항 커버리지)
  - **Feasibility** (기술적 실현 가능성)
  - **Safety** (보안/안정성 리스크 관리)
  - **Clarity** (계획서 명확성, 모호함 없음)
  - 모든 항목 4점 이상이면 남은 iteration 없이 조기 종료한다
  - 평가 결과를 `.claude/memory/plan-review-scores.md`에 기록한다

### Step 3: Meta Verification
- Task "meta-verify" (`addBlockedBy=["plan-review"]`): architect가 critic의 리뷰를 cross-verify
- Severity-based routing:
  - Minor (detail-level): → Step 2 task 재생성
  - Major (structural): → lead에게 보고 → Step 1-B (with failure reason)

### Step 4: Over-engineering Check
- Task "yagni-check" (`addBlockedBy=["meta-verify"]`): architect가 YAGNI/KISS 관점으로 plan 검증
- architect ←→ planner 직접 토론으로 합의 도출
- Severity-based routing: Minor → Step 2, Major → Step 1-B

**Step 4 완료 시**: 모든 팀원에게 `SendMessage(type="shutdown_request")` → `TeamDelete()`
- Steps 2-4 are executed as a combined plan review cycle

**Step Output Artifacts** (Step 4-B 진입 전 필요):
- `memory/plan-summary.md` — 리뷰 반영 최종본 (critic 교정 + Contrastive Anchors 포함)
- `memory/plan-review-scores.md` — 4축 품질 점수 (Completeness/Feasibility/Safety/Clarity, 각 iteration 결과)

## Step 4-B: Expert Plan Review — 도메인팀 Agent Team 토론

- 목적: 구현 전에 도메인 전문가들이 **팀 내 토론**을 통해 우려사항/위험요소를 사전에 식별
- `config.yaml`의 `expert_panel` 섹션 참조
- Read expert prompts from `.claude/workflow/prompts/*.md`

### 팀 활성화 규칙 (`config.yaml` → `expert_panel.team_activation`)

- STANDARD path: Safety + Code Design (always) + auto-detect된 Data/Integration/Ops 팀
- LARGE path: 전체 + extended failure mode analysis

### 통합 전문가 팀 생성 (Agent Teams 제약: 세션당 1팀)

> **Agent Teams Fallback**: Agent Teams 미활성 시 `agent-teams.md`의 Fallback 절차를 따른다.

`TeamCreate(team_name="expert-review", description="도메인 전문가 통합 리뷰 팀")`

팀원 spawn (병렬, `team_name="expert-review"`):

**Data Team** (min_active 2, auto-detect):
- `Agent(name="rdbms-expert")`, `Agent(name="cache-expert")`, `Agent(name="nosql-expert")`

**Integration Team** (min_active 2, auto-detect):
- `Agent(name="sync-api-expert")`, `Agent(name="async-expert")`, `Agent(name="external-integration-expert")`, `Agent(name="messaging-expert")`

**Safety Team** (always — appsec + stability 항상 활성):
- `Agent(name="appsec-expert")`, `Agent(name="auth-expert")`, `Agent(name="infrasec-expert")`, `Agent(name="stability-expert")`

**Ops Team** (min_active 2, auto-detect):
- `Agent(name="infra-expert")`, `Agent(name="observability-expert")`, `Agent(name="performance-expert")`, `Agent(name="concurrency-expert")`

**Code Design Team** (always — convention + idiom 항상 활성):
- `Agent(name="convention-expert-review")`, `Agent(name="idiom-expert-review")`, `Agent(name="design-pattern-expert-review")`, `Agent(name="testability-expert-review")`
- Step 1-A의 `.claude/memory/code-design-analysis.md` 활용

### 도메인별 작업 정의 (`TaskCreate`)

각 도메인팀별 3단계:
- Task "{도메인}-분석": plan-summary.md 검토 → 도메인별 findings 작성
- Task "{도메인}-토론": 다른 팀원의 findings 읽고 직접 토론 (`addBlockedBy=["{도메인}-분석"]`)
- Task "{도메인}-합의": 팀 합의 → 도메인별 findings.md (CRITICAL/HIGH/MEDIUM severity) (`addBlockedBy=["{도메인}-토론"]`)

### 토론 로그 저장 (필수)

팀원 prompt에 다음 규칙을 포함:
> "토론 시 핵심 논점과 결론을 `.claude/memory/expert-discussions/{도메인}-discussion.md`에 기록하세요."

기록 형식:
```markdown
## [우려 ID]: [한줄 요약]
- [전문가A → 전문가B]: 논점 요약
- [전문가B → 전문가A]: 반박/동의 요약
- [합의]: 최종 결론 + severity + 근거
```

### Cross-Examiner Protocol (CP-006)

도메인팀 합의 완료 후, CRITICAL/HIGH findings에 대해 전담 `cross-examiner` 에이전트가 청문회식 반증을 수행한다. Finding 제기자가 자신의 finding을 반증하면 형식적 반론으로 전락할 수 있으므로, 독립 에이전트가 전담하여 Cognitive Independence를 보장한다.

**절차**:
1. 도메인팀 합의 완료 후, CRITICAL/HIGH findings 목록을 수집
2. `cross-examiner` subagent를 spawn하여 각 finding에 대해:
   - "이 concern이 과도하게 평가되었을 반증"을 코드 근거(Read/Grep) 기반으로 탐색
   - 반증의 최소 요건: 코드에서 확인 가능한 근거 1개 이상
3. 반증이 성공한 finding은 architect에게 severity 재검토를 제안
4. 결과를 `expert-plan-concerns.md`의 해당 finding에 `cross_examination` 필드로 추가

**예외**: 수학적으로 명확한 버그(SQL injection 직접 concatenation, 하드코딩된 비밀번호 등)에는 Cross-Examiner를 적용하지 않는다 — 반증의 여지가 없는 명백한 결함에 자원을 낭비하지 않기 위함이다.

### Findings 품질 원칙 — "깊이 > 수량" (P-008)

각 전문가 에이전트 prompt에 다음 품질 원칙을 포함:
> 각 finding은 (1) 구체적 코드 위치, (2) 왜 문제인지, (3) 영향 범위를 포함한다.
> 구체적 근거가 있는 5건이 모호한 설명의 20건보다 낫다.

<finding_quality_examples>
**Good finding** (구체적, 검증 가능):
- 코드 위치: `internal/auth/handler.go:47` — `ValidateToken()` 함수
- 문제: JWT 서명 검증 없이 payload를 디코딩하여 사용. 공격자가 변조된 토큰으로 다른 사용자의 세션에 접근 가능
- 영향 범위: `/api/protected/*` 하위 모든 엔드포인트 (현재 12개)
- severity: CRITICAL

**Bad finding** (모호, 검증 불가):
- 코드 위치: auth 모듈
- 문제: 인증 처리가 불안전할 수 있음
- 영향 범위: 시스템 전반
- severity: HIGH

**Scope 밖 finding** (변경하지 않는 코드에 대한 일반 조언 — 작성하지 않는다):
- 코드 위치: `internal/user/repository.go:15`
- 문제: 기존 코드에 에러 래핑이 없음 (이번 변경과 무관)
- → git diff 대상 파일만 검토한다.
</finding_quality_examples>

**Self-Contrastive Validation (CP-002)**: 각 finding 작성 후, 즉시 다음 두 가지를 생성한다:
1. **WHY_VALID**: 이 finding이 정당한 이유 (구체적 코드 증거 열거)
2. **WHY_WRONG**: 이 finding이 잘못된 가능성 (False Positive, ORM/프레임워크가 이미 처리, scope 밖, over-severity 등)

WHY_WRONG 작성 후 반드시 코드에서 직접 확인(Read/Grep)하여 판정한다. 반증이 지지보다 강하면 finding을 폐기하거나 severity를 하향하고, REJECTION_DETAIL에 사유를 기록한다. "추측 기반 반증"은 금지 — 코드 확인 없이 반증을 채택하면 실제 취약점을 놓칠 수 있다.

예시:
```
FINDING: JWT 서명 검증 누락
WHY_VALID: ValidateToken()이 jwt.Parse() 호출 시 signing method 검증 비활성화 (handler.go:47)
WHY_WRONG: 미들웨어 레이어에서 이미 검증? → middleware/ 확인 필요
→ 미들웨어 확인 결과: 없음 → finding 유지 (CRITICAL)
```

**안전 제약**: CRITICAL 보안 finding에서 WHY_WRONG으로 severity를 하향하려면 사용자 명시 승인이 필수다 — 논문의 23/120 오판 위험에 대응.

- MEDIUM findings가 10개 이상이면 architect가 영향도 기준 상위 5개만 활성 처리하고 나머지는 backlog로 분류
- 핵심 비즈니스 로직 > 내부 유틸리티 순으로 분석 깊이를 조절

### Agent Scope Anti-Goals (P-003)

각 전문가 에이전트 prompt에 다음을 포함:
> "이 리뷰의 목적은 {도메인} 관점의 우려사항 식별입니다. 코드 스타일 교정, 범위 밖 리팩토링 제안, 변경하지 않은 파일에 대한 의견은 scope 밖입니다. git diff 대상 파일만 검토하세요."

이를 통해 에이전트가 범위를 벗어나 불필요한 의견을 생성하는 것을 방지한다.

### Lead의 Cross-team Synthesis

- **출력 형식**: 모든 전문가는 `references/expert-output-schema.md`의 Findings Schema를 따른다.

각 findings 출력 형식:
- **우려사항**: CRITICAL / HIGH / MEDIUM 심각도 (팀 합의 기반)
- **권장사항**: 구현 시 고려해야 할 구체적 주의점
- **토론 근거**: 어떤 전문가가 어떤 논거로 해당 severity에 합의했는지
- **질문**: 계획에서 불명확한 부분
- **재평가 트리거**: 구현 시 어떤 조건이 발생하면 이 concern의 severity를 재평가해야 하는지 (예: "만약 캐시 레이어를 도입하면 이 concern은 HIGH로 상향")

CRITICAL → `planner`에게 전달하여 계획 수정 → Step 2로 회귀 (max 2회)
HIGH → 계획에 주의사항으로 추가, 구현 시 반드시 반영
MEDIUM → 기록만 하고 구현 시 참고

- Save: `.claude/memory/expert-plan-concerns.md`
- 각 concern에 `trigger_condition` 필드를 포함하여, Step 7의 Impl Review Team이 구현 결과와 대조할 수 있도록 한다

**Step Output Artifacts** (Phase B 진입 전 필요):
- `memory/expert-plan-concerns.md` — 도메인 전문가 우려사항 (CRITICAL/HIGH/MEDIUM severity, trigger_condition, fact-checking 태그 포함)
- `memory/plan-summary.md` — CRITICAL concern 반영 최종본 (Phase B 전체의 기준 문서)

**▶ EMIT** `expert_panel` @ `A/4-B` — 도메인팀 Expert Plan Review 결과 (스텝 흐름의 일부, 생략 불가). `.pending-event.json` 작성 후 실행:
```json
{
  "skill": "simon",
  "step": "A/4-B",
  "type": "expert_panel",
  "title": "도메인팀 Expert Plan Review",
  "data": {
    "panel_name": "Domain Expert Panel",
    "opinions": [CRITICAL/HIGH/MEDIUM findings를 {"role":"팀명", "opinion":"finding 요약", "severity":"레벨"} 형식으로],
    "consensus": "전체 합의",
    "action_items": ["CRITICAL/HIGH 대응 액션"]
  }
}
```
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit-event.sh --session "$SESSION_DIR" 2>/dev/null || true
```

### Fact-checking 검증 (CRITICAL/HIGH concerns)

expert-plan-concerns.md 저장 후, **CRITICAL/HIGH concerns 중 기술적 사실에 기반한 주장**을 독립 fact-checker subagent로 검증한다. 전문가의 환각 기반 concern이 검증 없이 전체 파이프라인(Step 5→7→17→18)을 관통하는 것을 방지한다.

**검증 대상** (사실적 주장만):
- "X 라이브러리는 ~를 지원하지 않는다"
- "Y 버전에서 ~가 변경/제거되었다"
- "Z API의 동작이 ~이다"
- 검증 가능한 기술적 사실에 기반한 CRITICAL/HIGH concerns

**검증 대상 아님** (의견/판단):
- "이 설계는 유지보수가 어렵다"
- "이 접근법은 확장성이 부족하다"
- 주관적 판단이나 미래 예측

**검증 절차**:
1. CRITICAL/HIGH concerns에서 사실적 주장을 추출
2. 각 주장에 대해 **fact-checker subagent** (model: sonnet) spawn
3. fact-checker가 Context7 MCP(`resolve-library-id` → `query-docs`)로 공식 문서 조회 + 실제 라이브러리 코드 확인
4. 검증 결과:
   - `[FACT-VERIFIED]`: 사실 확인됨 → concern 유지
   - `[FACT-DISPUTED]`: 사실과 불일치 → concern에 태깅 + 근거 기록. 구현 시 이 concern은 무시해도 됨
5. 결과를 expert-plan-concerns.md에 반영 (해당 concern에 태그 추가)

- 사용자에게 주요 우려사항 요약 보고 (AskUserQuestion으로 진행 여부 확인). Fact-checking 결과도 함께 보고
- Update: `CONTEXT.md` — Phase A 완료 표시, 핵심 결정사항 및 전문가 우려(HIGH+) 갱신

## Phase A Calibration Checklist (Phase B 진입 전 검증)

### Ship Mode 동작 매트릭스 (Phase A)

ship 모드에서는 CRITICAL security finding과 build/test failure 외에 AskUserQuestion을 호출하지 않는다 — "한 번 입력 후 PR URL까지"의 약속을 100% 이행하기 위함이다.

| 지점 | ship 모드 동작 |
|------|---------------|
| Step 0: Scope Challenge | AI가 변경 파일 수 기준 자동 선택 + 1줄 통보 |
| Step 1-B: Plan Interview | AI-First Draft 확정, 교정 없이 진행 |
| Step 1-B: Spec Validation | Skip + Decision Journal 기록 |
| Steps 2-4: Plan Review | 에스컬레이션 없이 AI 자동 판정 |
| Step 4-B: Expert CRITICAL | 자동 수정 시도 + Decision Journal 기록. 자동 수정 실패 시에만 정지 |
| Calibration Checklist | 실패 항목 자동 보정 시도. 빌드/테스트 실패만 정지 |


Calibration Checklist의 검증 항목은 파일 존재 여부, 섹션 존재 여부 등 결정론적 작업이다. CLI 스크립트(`calibration-check.sh` 등)가 있으면 이를 우선 사용하고, 결과만 받아 FAIL 항목을 수정한다.

모든 항목이 충족된 후에 Phase B로 진입한다. 미충족 항목이 있으면 해당 단계로 돌아가 보완한 후 재검증한다.

| # | 검증 항목 | 확인 방법 | 미충족 시 |
|---|----------|----------|----------|
| 1 | 코드베이스 탐색 완료 | `requirements.md` + `code-design-analysis.md` 존재 및 비어있지 않음 | → Step 1-A |
| 2 | 인터뷰 완료 | `plan-summary.md`에 Unresolved decisions이 비어있거나 구현에 영향 없음 | → Step 1-B |
| 3 | 계획서에 파일 경로 포함 | Task 섹션 + End State Files Changed 테이블에 구체적 파일 경로 | → Step 1-B |
| 4 | Acceptance Criteria 3분할 | Code Changes / Tests / Quality Gates 섹션 모두 존재 | → Step 1-B |
| 5 | End State Files Changed 테이블 존재 | File \| Action \| Summary 형식 | → Step 1-B |
| 6 | End State Behavior Changes 존재 | Before → After 형식 | → Step 1-B |
| 7 | Test Targets 섹션 존재 | 테스트 대상 파일 패턴 명시 | → Step 1-B |
| 8 | Done-When Checks 존재 | 각 Unit별 기계적 검증 조건 명시 | → Step 1-B |
| 9 | Behavioral Checks 존재 | Behavior Changes의 검증 가능 항목이 Done-When Behavioral Checks에 포함 | → Step 1-B |
| 10 | 탐색 완성도 자기 평가 | code-design-analysis.md에 Structured Research Protocol(P-013)의 경쟁 가설 2개 이상 존재하고, 각 가설에 반박 증거 탐색이 수행되었는지 확인. "탐색 비중 높을수록 재작업 3~4배 감소" 원칙의 구조적 강제 | → Step 1-A |

누락 항목 발견 시 사용자에게 보고하지 않고 자동으로 해당 단계를 재실행하여 보완한다.

**▶ EMIT** `gate_pass`/`gate_fail` @ `A/calibration` — Calibration 결과 (스텝 흐름의 일부, 생략 불가). `.pending-event.json` 작성 후 실행:
```json
{
  "skill": "simon",
  "step": "A/calibration",
  "type": "gate_pass 또는 gate_fail",
  "title": "Phase A Calibration {통과|실패}",
  "data": {
    "gate_name": "Phase A Calibration Checklist",
    "checks": [{"name": "항목명", "passed": true/false} 7개 항목],
    "passed_count": N,
    "total_count": 7
  }
}
```
```bash
bash ~/.claude/skills/simon-monitor/scripts/emit-event.sh --session "$SESSION_DIR" 2>/dev/null || true
```

### Phase A Retrospective Checkpoint

Calibration Checklist 통과 직후, **Phase-End Auto-Retrospective** 프로토콜을 실행한다 (SKILL.md Cross-Cutting Protocol 참조). Phase A 동안 축적된 사용자 피드백(인터뷰 교정, 계획서 수정 요청 등)에서 반복 패턴을 탐지하고, 필요 시 boost-capture를 백그라운드로 트리거한다.
