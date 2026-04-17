# Event Schema

## 목차
- [Envelope (모든 이벤트 공통)](#envelope-모든-이벤트-공통)
- [Event Types](#event-types)
  - [workflow_start](#workflow_start)
  - [workflow_complete](#workflow_complete)
  - [step_start / step_complete / step_skip](#step_start)
  - [expert_panel](#expert_panel)
  - [subagent_spawn / subagent_result](#subagent_spawn)
  - [decision](#decision)
  - [gate_pass / gate_fail](#gate_pass--gate_fail)
  - [error / retry](#error)
  - [user_input / artifact / child_session](#user_input)
- [Severity Levels](#severity-levels-expert_panel에서-사용)

## Envelope (모든 이벤트 공통)

```json
{
  "id": "uuid-v4",
  "timestamp": "2026-04-13T14:30:00Z",
  "skill": "simon | simon-grind | simon-pm",
  "step": "A/1-A",
  "type": "event_type",
  "title": "사람이 읽을 수 있는 제목",
  "data": {}
}
```

### step 형식

Phase prefix + Step ID로 고유 식별:
- `startup/3` — Startup 단계의 Step 3
- `A/0` — Phase A의 Step 0 (Scope Challenge)
- `A/1-A` — Phase A의 Step 1-A
- `B/5` — Phase B의 Step 5 (Implementation)
- `review/18-A` — Review의 Step 18-A

simon-pm은 Phase 번호 사용:
- `0/setup` — Phase 0
- `1/1-A` — Phase 1의 Step 1-A
- `4/exec` — Phase 4의 Feature Execution

`step`이 `null`이면 워크플로 전체에 대한 이벤트 (workflow_start, workflow_complete).

---

## Event Types

### workflow_start

워크플로 시작. 반드시 첫 번째 이벤트.

```json
{
  "type": "workflow_start",
  "step": null,
  "title": "워크플로 시작",
  "data": {
    "skill": "simon",
    "branch": "feat/add-auth",
    "task": "인증 기능 추가",
    "scope": "STANDARD",
    "session_id": "feat/add-auth",
    "parent_session_id": null
  }
}
```

`parent_session_id`: simon-pm이 simon을 위임할 때 PM 세션 ID.

### workflow_complete

워크플로 종료.

```json
{
  "type": "workflow_complete",
  "step": null,
  "title": "워크플로 완료",
  "data": {
    "status": "success | failed | partial",
    "summary": "전체 요약",
    "duration_ms": 360000,
    "artifacts": ["requirements.md", "plan-summary.md"]
  }
}
```

### step_start

단계 시작.

```json
{
  "type": "step_start",
  "step": "A/1-A",
  "title": "프로젝트 분석 + 코드 설계 분석",
  "data": {
    "description": "프로젝트 구조 스캔, graphify 그래프 참조, Code Design Team 분석"
  }
}
```

### step_complete

단계 완료.

```json
{
  "type": "step_complete",
  "step": "A/1-A",
  "title": "프로젝트 분석 완료",
  "data": {
    "summary": "DDD 아키텍처 확인, 3개 바운디드 컨텍스트 식별",
    "artifacts": ["requirements.md", "code-design-analysis.md"],
    "duration_ms": 45000
  }
}
```

### step_skip

단계 스킵 (SMALL 경로 등).

```json
{
  "type": "step_skip",
  "step": "B/9",
  "title": "File/Function Splitting 스킵",
  "data": {
    "reason": "SMALL 경로: Steps 9-16 생략"
  }
}
```

### expert_panel

전문가 패널 토론 결과.

```json
{
  "type": "expert_panel",
  "step": "A/1-A",
  "title": "Code Design Team 분석",
  "data": {
    "panel_name": "Code Design Team",
    "opinions": [
      {
        "role": "Convention Expert",
        "opinion": "기존 프로젝트의 DDD 레이어 구조를 유지해야 합니다. domain/ 하위에 새 aggregate를 추가하는 형태.",
        "severity": "INFO"
      },
      {
        "role": "Idiom Expert",
        "opinion": "Go 1.24의 range-over-func 패턴 적용 가능. 기존 코드와 일관성 유지 필요.",
        "severity": "MEDIUM"
      },
      {
        "role": "Design Pattern Expert",
        "opinion": "Repository 패턴이 이미 사용 중. 새 엔티티도 같은 패턴 적용.",
        "severity": "INFO"
      },
      {
        "role": "Testability Expert",
        "opinion": "인터페이스 기반 DI 유지. Mock 생성이 용이하도록 인터페이스를 consumer 패키지에 정의.",
        "severity": "INFO"
      }
    ],
    "consensus": "DDD 패턴 유지, Repository 인터페이스 추가, Go 1.24 관용구 적용",
    "action_items": [
      "domain/auth/ 디렉토리 생성",
      "AuthRepository 인터페이스 정의",
      "기존 테스트 패턴 따르기"
    ]
  }
}
```

### subagent_spawn

서브에이전트 호출.

```json
{
  "type": "subagent_spawn",
  "step": "A/1-A",
  "title": "project-analyzer 서브에이전트 시작",
  "data": {
    "agent_name": "project-analyzer",
    "agent_type": "Explore",
    "task": "프로젝트 구조 분석: 디렉토리 구조, 주요 패턴, 의존성",
    "background": false
  }
}
```

### subagent_result

서브에이전트 결과.

```json
{
  "type": "subagent_result",
  "step": "A/1-A",
  "title": "project-analyzer 결과",
  "data": {
    "agent_name": "project-analyzer",
    "summary": "Go DDD 프로젝트. 3개 바운디드 컨텍스트(user, campaign, billing). Repository 패턴 사용.",
    "key_findings": [
      "cmd/server/main.go에서 DI 구성",
      "domain/ 하위에 aggregate별 패키지",
      "infra/repository/ 하위에 구현체"
    ],
    "duration_ms": 12000
  }
}
```

### decision

의사결정 기록.

```json
{
  "type": "decision",
  "step": "A/0",
  "title": "실행 경로 결정: STANDARD",
  "data": {
    "decision": "STANDARD path 선택",
    "rationale": "변경 파일 15+, 2개 패키지 간 의존성 존재, 기존 테스트 수정 필요",
    "alternatives": [
      {"option": "SMALL", "rejected_reason": "변경 범위가 SMALL 기준(~5 파일) 초과"},
      {"option": "LARGE", "rejected_reason": "새 서비스가 아닌 기존 서비스 확장"}
    ]
  }
}
```

### gate_pass / gate_fail

게이트 체크 결과.

```json
{
  "type": "gate_pass",
  "step": "A/calibration",
  "title": "Phase A Calibration 통과",
  "data": {
    "gate_name": "Phase A Calibration Checklist",
    "checks": [
      {"name": "requirements.md 존재", "passed": true},
      {"name": "plan-summary.md 존재", "passed": true},
      {"name": "Done-When 체크 정의됨", "passed": true},
      {"name": "expert-plan-concerns.md 존재", "passed": true},
      {"name": "scope 분류 완료", "passed": true},
      {"name": "NOT in scope 정의됨", "passed": true},
      {"name": "파일 변경 목록 작성됨", "passed": true}
    ],
    "passed_count": 7,
    "total_count": 7
  }
}
```

```json
{
  "type": "gate_fail",
  "step": "B/17",
  "title": "Production Readiness 실패",
  "data": {
    "gate_name": "Done-When Checks",
    "checks": [
      {"name": "모든 테스트 통과", "passed": true},
      {"name": "빌드 성공", "passed": true},
      {"name": "보안 리뷰 통과", "passed": false}
    ],
    "passed_count": 2,
    "total_count": 3,
    "action": "retry — 보안 리뷰 이슈 수정 후 재시도"
  }
}
```

### error

에러 발생.

```json
{
  "type": "error",
  "step": "B/5",
  "title": "빌드 실패",
  "data": {
    "message": "go build: undefined: AuthRepository",
    "category": "build",
    "will_retry": true,
    "attempt": 2,
    "max_attempts": 3
  }
}
```

### retry

재시도 (주로 simon-grind).

```json
{
  "type": "retry",
  "step": "B/5",
  "title": "구현 재시도 (3/10)",
  "data": {
    "attempt": 3,
    "max_attempts": 10,
    "tier": "early",
    "strategy": "modified",
    "changes": "인터페이스 시그니처 수정 후 재시도",
    "previous_error": "타입 불일치: AuthRepository vs *AuthRepository"
  }
}
```

### user_input

사용자 입력/피드백.

```json
{
  "type": "user_input",
  "step": "A/1-B",
  "title": "사용자 피드백: 플랜 수정",
  "data": {
    "input_type": "feedback",
    "content": "JWT 대신 OAuth2를 사용해주세요",
    "impact": "plan-summary.md 수정 필요"
  }
}
```

### artifact

아티팩트 생성/갱신.

```json
{
  "type": "artifact",
  "step": "A/1-A",
  "title": "requirements.md 생성",
  "data": {
    "file": "requirements.md",
    "action": "created",
    "summary": "3개 핵심 요구사항, 2개 비기능 요구사항 정의"
  }
}
```

### child_session

자식 세션 생성 (simon-pm → simon 위임).

```json
{
  "type": "child_session",
  "step": "4/exec",
  "title": "Feature 1: 인증 시스템 → simon 위임",
  "data": {
    "child_session_id": "feat/auth",
    "delegated_skill": "simon",
    "feature": "인증 시스템",
    "force_path": "SMALL"
  }
}
```

---

## Severity Levels (expert_panel에서 사용)

| Level | 의미 |
|-------|------|
| `CRITICAL` | 반드시 수정 — 플랜 수정 필요 |
| `HIGH` | 수정 권장 — 경고 추가 |
| `MEDIUM` | 기록 — 구현 시 참고 |
| `LOW` | 참고 사항 |
| `INFO` | 정보 제공 |
