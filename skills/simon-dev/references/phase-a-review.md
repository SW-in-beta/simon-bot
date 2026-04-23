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

### Expert Persona Protocol (ExpertPrompting 원칙 적용)

각 전문가 spawn 시 시스템 프롬프트에 반드시 **Identity + Goal + First Check** 3요소를 포함한다. 역할 이름만 전달하면 일반 조언만 반환되며, 도메인 특유의 위험 패턴 탐색이 이루어지지 않는다 (ExpertPrompting, arXiv:2305.14688: 상세 배경 명시 시 48.5% 응답 품질 향상).

표준 페르소나 템플릿:
```
Identity: "너는 [N년간 X 분야] 전문가다"
Goal: "이 리뷰에서 [특정 위험 패턴]을 모두 찾아낸다"
First Check: "[도메인 우선순위 목록] 순서로 확인한다"
```

도메인별 기본 페르소나 (`.claude/workflow/prompts/*.md`에 프로젝트별 정의가 있으면 그것을 우선):

| 전문가 | Identity | Goal | First Check |
|--------|----------|------|-------------|
| `appsec-expert` | 10년간 웹 보안 감사 전문 엔지니어 | OWASP Top 10 취약점 경로를 모두 탐색 | 접근제어 → 암호화 → 인젝션 → 인증 → 로깅 |
| `auth-expert` | 인증·인가 시스템 설계 전문 엔지니어 | 인증 우회·권한 상승 경로 식별 | 세션 관리 → 토큰 검증 → 권한 경계 → CSRF |
| `infrasec-expert` | 클라우드 인프라 보안 전문 엔지니어 | 인프라 레이어 노출·구성 오류 탐색 | 비밀 노출 → 네트워크 경계 → IAM 권한 → 로그 |
| `stability-expert` | 대규모 분산 시스템 장애 대응 SRE | 모든 실패 경로에서 graceful 동작 확인 | 타임아웃 → 재시도 정책 → circuit breaker → 리소스 누수 |
| `rdbms-expert` | 대용량 OLTP 시스템(1억+ TPS) 설계 DB 아키텍트 | DB 레이어의 장애·성능 저하·데이터 불일치 경로 식별 | 트랜잭션 경계 → N+1 패턴 → 마이그레이션 안전성 → 인덱스 |
| `cache-expert` | 분산 캐시 시스템 설계 전문 엔지니어 | 캐시 일관성 파괴·스탬피드·오염 경로 탐색 | 무효화 시점 → TTL 설계 → cache stampede → 부분 실패 |
| `performance-expert` | 고트래픽 서비스 성능 튜닝 전문 엔지니어 | 이번 변경이 유발할 성능 저하 경로 식별 | 루프 내 쿼리 → 중복 연산 → 동시성 병목 → 메모리 누수 |
| `concurrency-expert` | 동시성 프로그래밍 전문 엔지니어 | race condition·deadlock·livelock 경로 탐색 | 공유 상태 → 락 순서 → 채널 사용 → atomic 연산 |
| `observability-expert` | 프로덕션 모니터링·디버깅 전문 엔지니어 | 이번 변경으로 관측 불가능해지는 경로 식별 | 로그 커버리지 → 메트릭 누락 → 에러 전파 추적 → 알림 |

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

### Adversarial Review — 항상 실행 (CP-007)

도메인팀 합의 완료 직후, **모든 경로에서 항상** `adversarial-reviewer` subagent를 spawn하여 팀들이 공통으로 놓쳤을 수 있는 blind spot을 능동 탐색한다. 전문가들의 findings 수와 무관하게 실행 — findings가 많아도 팀 전체가 같은 사각지대를 공유할 수 있기 때문이다 (IUI '24: DA는 경로에 관계없이 의사결정 정확도를 통계적으로 유의미하게 향상).

Cross-Examiner와 역할이 다르다 — Cross-Examiner는 "발견된 findings의 false positive"를 탐지하고, Adversarial Review는 "발견되지 않은 위험"을 능동 탐색한다.

**adversarial-reviewer에게 적용할 3가지 전략** (CHI '25, arXiv:2504.12424):

1. **반사실적 사고**: 각 Unit의 핵심 경로에서 "이 가정이 깨지면?" 탐색
   - "이 API 호출이 실패하면?", "이 쿼리가 0건 반환하면?", "동시 요청이 2배라면?"
   
2. **암묵적 가정 감사**: 설계가 당연하게 여기는 것 중 코드에서 명시되지 않은 것
   - "이 호출 순서가 항상 보장되는가?", "이 값이 항상 유효하다고 가정하는가?"

3. **Silent Failure 집중 탐색**: 에러를 삼키거나 기본값으로 조용히 대체하는 패턴
   - `err := ...; _ = err`, 빈 catch 블록, `value || defaultValue` 탐색

**출력**: 동일한 Findings Schema (`FINDING_ID: adversarial-{seq}`). 도메인팀이 이미 발견한 이슈와 동일하면 `[DUPLICATE-CONFIRMED]` 태깅 — severity 상향 신호로 활용.

결과를 `expert-plan-concerns.md`의 `## Adversarial Review` 섹션에 추가.

### Historical Concerns Cross-Reference (Brain Query)

Adversarial Review 완료 후, Phase A-1에서 저장해둔 `.claude/memory/brain-historical-context.md`(우려/인시던트 축)와 현재 `expert-plan-concerns.md`를 대조하여 "과거에 이미 아파본 것"이 blind 전문가팀에서 누락됐는지 확인한다. 전문가팀과 adversarial-reviewer가 코드와 plan만 보고 독립적으로 판단한 **이후**에 역사적 데이터를 주입하는 것이 핵심 — anchor bias를 피하면서도 제도적 기억은 보강한다.

**Brain 파일이 없거나 "해당 없음"이면 이 섹션은 skip.**

**절차** (brain-matcher subagent, fresh context):
1. Input: `expert-plan-concerns.md` 전체 + `brain-historical-context.md`의 `## 과거 우려/인시던트` 섹션만
2. 각 brain 항목에 대해 `expert-plan-concerns.md`와 매칭:
   - **[HISTORICAL-MATCH]**: 동일/유사 concern이 이미 존재 → 해당 concern의 severity를 한 단계 상향 (MEDIUM→HIGH, HIGH→CRITICAL). 근거로 brain 출처(vault 경로)를 `historical_evidence` 필드에 추가. CRITICAL 상향은 보안 finding이 아닌 한 자동 적용, 보안은 fact-checker로 전달
   - **[HISTORICAL-GAP]**: 전문가팀이 놓친 과거 우려 → 새 concern으로 추가. 단, brain 기록이 현재 계획에도 해당되는지 fact-checker로 재검증 필요 (코드가 이미 해결했을 수 있음)
   - **[HISTORICAL-STALE]**: 과거 우려가 현재 코드 구조에서는 더 이상 해당하지 않음 → `brain-historical-context.md`에 `(obsolete)` 태깅만 남기고 무시
3. 역방향 체크: `expert-plan-concerns.md`에만 있고 brain에는 없는 CRITICAL/HIGH concern 목록을 `brain-seed-candidates.md`로 출력 — simon-brain-dump에서 wiki 추가 후보로 활용

**출력 위치**:
- `expert-plan-concerns.md`의 `## Historical Context` 섹션 (append)
- `.claude/memory/brain-seed-candidates.md` (novel concerns, simon-brain-dump 연계)

이 단계는 "제도적 기억 보강"이지 "전문가 판단 대체"가 아니다 — brain이 비어도 전문가 판단은 유효하고, brain 결과와 충돌하면 **더 높은 severity를 채택**한다 (miss 비용 > noise 비용).

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

### Phase A → Phase B Context Handoff (컨텍스트 전환)

Phase A에서 Phase B로 전환하는 시점은 컨텍스트 rot의 주요 발생 지점이다. Phase A 인터뷰, Agent Team 토론, 전문가 리뷰 등의 중간 산출물은 Phase B에서 참조되지 않는다. 이 상태에서 Phase B를 시작하면 불필요한 컨텍스트가 모델의 주의를 분산시킨다.

**Phase B 진입 전 컨텍스트 수렴 체크** (결정론적):
```bash
# Phase A 산출물 중 Phase B 필수 파일만 존재 확인
REQUIRED=("memory/plan-summary.md" "memory/code-design-analysis.md" "memory/expert-plan-concerns.md" "memory/verify-commands.md")
MISSING=()
for f in "${REQUIRED[@]}"; do
  [ -f "${SESSION_DIR}/${f}" ] || MISSING+=("$f")
done
[ ${#MISSING[@]} -eq 0 ] && echo "OK Phase B 진입 가능" || echo "MISSING: ${MISSING[*]}"
```

**컨텍스트 과부하 경고 조건** (하나라도 해당 시 `/compact` 권장 통보):
- Phase A Agent Team 토론 내용이 직접 컨텍스트에 존재하는 경우 (`plan-summary.md`에 이미 요약됨)
- Step 1-B 인터뷰 대화가 직접 컨텍스트에 존재하는 경우 (`requirements.md`에 이미 요약됨)

해당 조건 적용 시 다음 통보를 출력하고 Phase B를 시작한다 (강제 중단하지 않는다):

```
[Context] Phase A 중간 기록이 컨텍스트에 남아 있습니다.
  핵심 문서: plan-summary.md, code-design-analysis.md, expert-plan-concerns.md
  /compact "plan-summary.md, expert-plan-concerns.md 기준으로 Phase B 구현 시작. 인터뷰 대화와 Agent Team 토론은 제외." 를 실행하면 Phase B 집중도가 높아집니다.
  계속 진행하려면 그냥 두어도 됩니다 — plan-summary.md가 SSoT입니다.
```

구체적인 compact hint는 `cross-cutting-protocols.md`의 Phase별 Compact Hint 테이블을 참조한다.
