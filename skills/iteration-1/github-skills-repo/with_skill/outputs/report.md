# simon-bot Boost Report

## Source
- **자료**: [Claude Agent SDK for Python](https://github.com/anthropics/claude-code-sdk-python)
- **분석일**: 2026-03-06

## Executive Summary

Claude Agent SDK for Python은 Claude Code 에이전트를 프로그래밍 방식으로 구축하기 위한 공식 SDK로, Hook 기반 생명주기 제어, 세밀한 도구 권한 콜백, 구조화된 에러 계층, In-Process MCP 서버, 다중 에이전트 정의 등 성숙한 에이전트 프레임워크 패턴을 제공한다. 이 자료에서 simon-bot 계열 스킬에 적용 가능한 핵심 인사이트는 다음과 같다: (1) Hook/Gate 패턴을 통한 단계 전환 시 체계적 검증 강화, (2) 구조화된 에러 계층 분류를 통한 복구 전략 세분화, (3) 도구 권한 콜백 개념을 활용한 Forbidden Rules의 동적/계층적 적용, (4) Permission Mode 개념을 활용한 스킬 내 자율성 수준 동적 조절, (5) 세션 관리 API의 구조화된 메타데이터 모델 도입.

---

## Improvement Proposals

### [P-001] Phase 전환 Gate에 Hook 패턴 도입 — 명시적 Pre/Post Condition 체계화

- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: `SKILL.md`, `references/phase-a-planning.md`, `references/phase-b-implementation.md`
- **카테고리**: 워크플로 구조
- **현재 상태**: Phase A → B 전환 시 "Phase A Calibration Checklist"라는 7개 항목 자동 검증이 존재하지만, 각 Step 간 전환 시에는 명시적인 pre-condition/post-condition 체크가 없다. Step 완료 판단이 암묵적이어서 불완전한 상태로 다음 Step에 진입할 수 있다.
- **제안 내용**: SDK의 `PreToolUse`/`PostToolUse` Hook 패턴을 차용하여, 각 Step과 Phase에 `PreStep`/`PostStep` Gate를 명시적으로 정의한다.
  - **PreStep Gate**: 해당 Step 시작 전 충족해야 할 조건 목록 (필수 파일 존재, 이전 Step 출력물 검증, 빌드 상태 등)
  - **PostStep Gate**: 해당 Step 완료 판정 조건 (산출물 존재, 품질 기준 충족, 테스트 통과 등)
  - Phase A Calibration Checklist를 PostPhase Gate의 한 사례로 일반화
  - 예: Step 5(구현) PostStep Gate = {파일 존재 + 빌드 성공 + 테스트 GREEN + code-design-analysis.md 컨벤션 준수 확인}
  - 예: Step 7(리뷰) PreStep Gate = {Step 5-6 PostStep Gate 통과 + 구현 파일 목록 확인}
- **기대 효과**: 불완전한 산출물이 다음 단계로 전파되는 것을 방지. 실패 지점을 정확히 식별 가능. grind 모드에서 재시도 시 어느 Gate에서 실패했는지 명확히 알 수 있어 진단 정확도 향상.
- **근거**: SDK의 `PreToolUse` Hook이 도구 실행 전에 입력을 검증하고 위험한 명령을 차단하는 패턴. 이를 워크플로 Step 수준으로 확장하면 각 단계 전환의 안전성이 크게 향상된다.
- **전문가 합의**: Workflow Architect(주도), Quality Guardian(강력 지지), DX Specialist(Gate 실패 시 사용자 메시지 명확성 조건 추가). Innovation Scout는 과도한 Gate가 속도를 저하시킬 수 있다고 우려했으나, SMALL path에서는 경량 Gate만 적용하는 것으로 합의.

---

### [P-002] 에러 분류 체계 세분화 — SDK 에러 계층 모델 도입

- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-grind
- **대상 파일**: `references/error-resilience.md`, `references/grind-error-resilience.md`
- **카테고리**: 품질/안전
- **현재 상태**: 에러를 `ENV_INFRA`와 `CODE_LOGIC` 두 가지로만 분류한다. 실제로는 같은 ENV_INFRA라도 "CLI를 찾을 수 없음"과 "네트워크 타임아웃"은 완전히 다른 복구 전략이 필요하다. grind 모드의 10회 재시도에서 에러 유형을 세분화하지 못하면 같은 전략을 반복 시도하여 재시도 예산을 낭비한다.
- **제안 내용**: SDK의 구조화된 에러 계층 (`ClaudeSDKError` → `CLINotFoundError` / `CLIConnectionError` / `ProcessError` / `CLIJSONDecodeError`)을 참고하여 에러 분류를 트리 구조로 세분화:
  ```
  WorkflowError
  ├── ENV_INFRA
  │   ├── TOOL_UNAVAILABLE   (도구/CLI 없음 → 설치/경로 확인)
  │   ├── NETWORK_ERROR      (타임아웃/연결 실패 → 재시도 + 백오프)
  │   ├── RESOURCE_LIMIT     (메모리/디스크/컨텍스트 부족 → 정리 후 재시도)
  │   └── PERMISSION_ERROR   (권한 부족 → 사용자 에스컬레이션)
  ├── CODE_LOGIC
  │   ├── BUILD_FAILURE      (컴파일/타입 에러 → 코드 수정)
  │   ├── TEST_FAILURE       (테스트 실패 → 로직 수정 또는 테스트 수정)
  │   ├── LINT_VIOLATION     (스타일 위반 → 자동 수정)
  │   └── DESIGN_CONFLICT    (설계 충돌 → architect 분석)
  └── WORKFLOW_ERROR
      ├── GATE_FAILURE       (Pre/PostStep 조건 미충족)
      ├── AGENT_TIMEOUT      (에이전트 응답 없음)
      └── STATE_CORRUPTION   (메모리 파일 손상)
  ```
  각 하위 유형에 대해 1차/2차/3차 복구 전략을 매핑.
- **기대 효과**: grind 모드에서 에러 유형별 최적 복구 전략을 즉시 선택할 수 있어 재시도 효율이 크게 향상. failure-log.md의 패턴 분석도 세분화된 유형으로 더 정확해진다.
- **근거**: SDK가 `CLINotFoundError`(설치 문제)와 `CLIConnectionError`(연결 문제)와 `ProcessError`(실행 문제)를 명확히 구분하여 각각 다른 복구 안내를 제공하는 패턴.
- **전문가 합의**: Quality Guardian(주도), Workflow Architect(지지), Prompt Engineer(에러 메시지 템플릿도 유형별로 분리하자고 추가 제안). 전원 합의.

---

### [P-003] Forbidden Rules를 동적 권한 콜백 모델로 확장

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: `SKILL.md` (Global Forbidden Rules 섹션)
- **카테고리**: 품질/안전
- **현재 상태**: Global Forbidden Rules는 정적 목록으로, 모든 상황에서 동일하게 적용된다. 그러나 일부 규칙은 맥락에 따라 세밀한 판단이 필요하다 (예: `curl`은 외부 API 호출은 금지하지만 localhost 테스트 서버 호출은 허용해야 할 수 있음).
- **제안 내용**: SDK의 `can_use_tool` 콜백 패턴을 참고하여 Forbidden Rules를 3계층으로 재구조화:
  1. **ABSOLUTE FORBIDDEN** (절대 금지, 예외 없음): `git push --force`, `rm -rf /`, `DROP TABLE`, `.env` 커밋 — 현재와 동일
  2. **CONTEXT-SENSITIVE** (맥락 검증 후 판단): `curl`/`wget` → 대상이 localhost/테스트 서버인지 검증 후 허용/거부, `ssh` → 명시적으로 허용된 호스트만 가능
  3. **AUDIT-REQUIRED** (실행 가능하나 로깅 필수): 파일 삭제(특정 파일), DB 읽기 전용 쿼리 → 실행하되 감사 로그에 기록
  - 각 계층에 대한 판단 프로토콜을 정의하고, CONTEXT-SENSITIVE 항목은 판단 근거를 memory에 기록
- **기대 효과**: 현재 지나치게 보수적인 규칙으로 인해 사용자가 수동 개입해야 하는 경우를 줄이면서도 안전성을 유지. 특히 테스트 환경 설정 시 localhost curl 호출이 자주 필요한 상황에서 유용.
- **근거**: SDK의 `can_use_tool` 콜백이 도구명, 입력 데이터, 컨텍스트를 받아 allow/deny/modify를 동적으로 결정하는 패턴. 특히 "입력 수정"(위험한 경로를 안전한 경로로 리다이렉트)이 가능한 점이 영감.
- **전문가 합의**: Innovation Scout(주도), DX Specialist(지지 — 사용자 수동 개입 감소), Quality Guardian(ABSOLUTE FORBIDDEN 계층은 절대 약화 불가 조건으로 합의). Prompt Engineer는 CONTEXT-SENSITIVE 판단 시 에이전트에게 주는 지시문 명확성이 중요하다고 강조.

---

### [P-004] 스킬 자율성 수준(Permission Mode) 동적 조절 메커니즘

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-grind, simon-bot-pm
- **대상 파일**: `SKILL.md` (Cross-Cutting Protocols 섹션)
- **카테고리**: DX (개발자 경험)
- **현재 상태**: simon-bot은 여러 단계에서 AskUserQuestion으로 사용자 확인을 받는다. simon-bot-grind는 이를 줄이고 자동 진행을 강화했지만, 자율 수준은 스킬 선택 시 고정된다. 사용자가 작업 중간에 "이제부터 알아서 해줘" 또는 "여기부터는 하나씩 확인하자"와 같이 자율 수준을 변경할 수 없다.
- **제안 내용**: SDK의 Permission Mode (`default` / `acceptEdits` / `plan` / `bypassPermissions`)와 `set_permission_mode()` 동적 변경 패턴을 차용하여, 워크플로 실행 중 자율 수준을 변경할 수 있게 한다.
  - **레벨 정의**:
    - `supervised` (현재 simon-bot 기본): 모든 주요 결정에서 사용자 확인
    - `semi-auto` (현재 simon-bot-pm auto 모드): 결과 보고만, 결정은 자동
    - `full-auto` (현재 simon-bot-grind): 에스컬레이션 전까지 완전 자동
  - 사용자가 워크플로 중간에 자연어로 레벨 전환 가능 ("알아서 해줘" → full-auto, "잠깐, 여기부터 확인하자" → supervised)
  - 현재 자율 수준을 `.claude/memory/autonomy-level.md`에 기록
  - 위험도가 높은 단계(Step 17 Production Readiness, Step 19 PR Review)에서는 자동으로 supervised로 격상
- **기대 효과**: 사용자가 simon-bot vs grind를 선택하는 대신 하나의 워크플로 내에서 자율 수준을 유연하게 조절. 익숙한 작업은 빠르게, 중요한 결정은 신중하게.
- **근거**: SDK의 `ClaudeSDKClient.set_permission_mode()`가 세션 도중에 권한 모드를 동적으로 변경하는 패턴. 이를 워크플로 자율성 수준에 적용.
- **전문가 합의**: DX Specialist(주도), Workflow Architect(위험 단계 자동 격상 조건으로 안전성 확보), Quality Guardian(full-auto에서도 Forbidden Rules는 절대 우회 불가 조건). Prompt Engineer는 자연어 의도 판별 지시문의 예시가 충분해야 한다고 강조.

---

### [P-005] 세션 관리 메타데이터 구조화 — simon-bot-sessions 고도화

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot-sessions
- **대상 파일**: `SKILL.md`
- **카테고리**: DX (개발자 경험)
- **현재 상태**: simon-bot-sessions는 셸 스크립트(`manage-sessions.sh`)를 통해 세션을 관리하며, 상태 정보는 `.claude/memory/` 하위의 개별 마크다운 파일들에 분산되어 있다. 세션의 현재 진행 상태(어떤 Step에 있는지), 마지막 활동 시간, 실패 횟수 등의 메타데이터가 구조화되어 있지 않다.
- **제안 내용**: SDK의 `SDKSessionInfo`와 `list_sessions()` / `get_session_messages()` API 패턴을 참고하여 세션 메타데이터를 JSON으로 구조화:
  ```json
  // .claude/memory/session-meta.json
  {
    "branch": "feat/user-auth",
    "skill": "simon-bot",
    "current_step": 7,
    "current_phase": "B",
    "status": "in_progress",
    "created_at": "2026-03-05T14:00:00",
    "last_activity": "2026-03-05T16:30:00",
    "failure_count": 2,
    "retry_count": 0,
    "autonomy_level": "supervised",
    "output_files": [
      "plan-summary.md",
      "code-design-analysis.md",
      "requirements.md"
    ],
    "pending_decisions": ["DB 인덱스 전략"]
  }
  ```
  - `list` 명령이 이 JSON을 파싱하여 테이블 형태로 보여줌 (Step/Phase 진행도 포함)
  - `resume` 시 메타데이터를 읽어 정확한 Step부터 재개
  - `info`에 세션 타임라인(각 Step 시작/완료 시각) 추가
- **기대 효과**: 세션 복원 시 "어디까지 했는지" 즉시 파악 가능. 여러 세션 비교 시 진행도를 한눈에 확인. 컨텍스트 윈도우 분할 복원 시 정확한 재개 지점 제공.
- **근거**: SDK의 `SDKSessionInfo`가 세션 메타데이터를 구조화하여 프로그래밍 방식으로 조회 가능하게 하는 패턴. `list_sessions()`로 활성 세션 목록을 즉시 가져오는 API.
- **전문가 합의**: DX Specialist(주도), Workflow Architect(컨텍스트 윈도우 경계와 연계하면 복원 정확도 향상), Innovation Scout(향후 대시보드 가능성). 전원 합의.

---

### [P-006] In-Process MCP Tool 패턴 활용 — 워크플로 전용 도구 정의 체계

- **심각도**: HIGH
- **대상 스킬**: simon-bot, simon-bot-pm
- **대상 파일**: `SKILL.md`, `references/phase-b-implementation.md`
- **카테고리**: 신기법 도입
- **현재 상태**: simon-bot 워크플로에서 반복적으로 수행하는 작업들(빌드 확인, 테스트 실행, 파일 존재 검증, 메모리 파일 읽기/쓰기 등)이 매번 Bash 도구를 통한 셸 명령으로 처리된다. 이는 에러 핸들링이 불안정하고, 출력 파싱이 취약하며, 같은 명령이 여러 Step에서 중복된다.
- **제안 내용**: SDK의 `@tool` 데코레이터 + `create_sdk_mcp_server()` 패턴을 참고하여, 워크플로에서 자주 쓰는 작업을 "워크플로 전용 도구"로 정의하는 체계를 도입:
  - **도구 후보 예시**:
    - `workflow_build_check`: 빌드 실행 + 결과 파싱 + 구조화된 성공/실패 반환
    - `workflow_test_run`: 테스트 실행 + 실패 테스트 목록 + 커버리지 정보 반환
    - `workflow_memory_save`: 워크플로 메모리 파일 저장 (경로 규칙 자동 적용)
    - `workflow_gate_check`: PreStep/PostStep Gate 조건 일괄 검증
  - 이 도구들은 `.claude/workflow/scripts/` 하위에 셸 스크립트로 구현하되, 출력을 JSON 등 구조화된 형식으로 표준화
  - SKILL.md에서 각 Step이 이 도구들을 참조하도록 지시문 업데이트
- **기대 효과**: 반복 작업의 일관성 향상. 에러 핸들링 통일. 새로운 Step 추가 시 기존 도구 재사용 가능. 워크플로 디버깅 시 도구 단위로 문제 격리 가능.
- **근거**: SDK가 `@tool("greet", "Greet a user", {"name": str})`처럼 도구를 선언적으로 정의하고, `create_sdk_mcp_server()`로 번들링하는 패턴. 서브프로세스 없이 직접 호출하여 오버헤드를 줄이는 접근.
- **전문가 합의**: Innovation Scout(주도 — MCP 도구 활용 확장 기회), Workflow Architect(구조적 재사용성 향상), Quality Guardian(도구별 에러 처리 표준화 가능). DX Specialist는 도구 목록이 과도하게 늘어나지 않도록 "5-7개 핵심 도구"로 제한할 것을 권장.

---

### [P-007] Agent 역할 정의를 AgentDefinition 패턴으로 구조화

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot, simon-bot-report
- **대상 파일**: `SKILL.md`, `references/phase-a-planning.md`, `references/phase-b-implementation.md`
- **카테고리**: 프롬프트 품질
- **현재 상태**: simon-bot에서 사용하는 에이전트 역할(architect, planner, critic, executor, writer, security-reviewer 등)은 각 Step의 지시문 속에 산재되어 있다. 역할의 도구 접근 범위, 모델 선호도, 프롬프트 톤이 Step마다 조금씩 다르게 기술되어 일관성이 부족하다.
- **제안 내용**: SDK의 `AgentDefinition` 패턴(이름, 설명, 프롬프트, 도구 목록, 모델)을 참고하여, 워크플로에서 사용하는 모든 에이전트 역할을 하나의 레지스트리 파일에 정의:
  ```markdown
  # references/agent-roles.md

  ## architect
  - **Description**: 시스템 전체 구조 설계 및 기술적 의사결정
  - **Core Tools**: Read, Grep, Glob (코드 탐색 위주, 수정 불가)
  - **Model Preference**: opus (복잡한 판단)
  - **Tone**: 비판적, 구조적, 트레이드오프 명시

  ## executor
  - **Description**: 계획에 따른 코드 구현
  - **Core Tools**: Read, Write, Edit, Bash (전체 도구)
  - **Model Preference**: session default
  - **Tone**: 실행 중심, 컨벤션 준수

  ## critic
  - **Description**: 계획/구현의 약점과 모순 탐색
  - **Core Tools**: Read, Grep (읽기 전용)
  - **Model Preference**: opus
  - **Tone**: 회의적, 반대 논거 제시
  ```
  - 각 Step에서는 역할명만 참조하고, 상세 정의는 레지스트리에서 가져옴
  - Agent Team 구성 시 역할 레지스트리에서 자동으로 도구/모델/프롬프트를 로딩
- **기대 효과**: 에이전트 역할의 일관성 확보. 새 역할 추가 시 레지스트리에 한 번만 정의. 역할별 도구 접근 범위가 명시적이어서 보안성 향상. 역할 설명이 중앙화되어 스킬 유지보수 용이.
- **근거**: SDK의 `AgentDefinition`이 에이전트의 description, prompt, tools, model을 하나의 객체로 묶어 정의하는 패턴. 다중 에이전트 오케스트레이션에서 역할이 명확히 분리됨.
- **전문가 합의**: Prompt Engineer(주도), Workflow Architect(역할 중앙화로 구조적 일관성), DX Specialist(역할 목록이 스킬 이해를 돕는 문서 역할도 함). 전원 합의.

---

### [P-008] max_turns 개념 도입 — 에이전트 루프 무한 실행 방지

- **심각도**: MEDIUM
- **대상 스킬**: simon-bot-grind
- **대상 파일**: `SKILL.md`, `references/grind-error-resilience.md`
- **카테고리**: 품질/안전
- **현재 상태**: simon-bot-grind는 모든 재시도 한계를 10으로 설정하고 있다. 그러나 여러 Step에 걸쳐 재시도가 누적되면 (예: Step 5에서 10회 + Step 7에서 10회 + Step 16에서 10회 = 30회 이상) 전체 워크플로의 총 재시도 횟수가 통제 불능이 될 수 있다. Progress Pulse가 부분적으로 이를 완화하지만, 총량 제한은 없다.
- **제안 내용**: SDK의 `max_turns` 개념을 차용하여, 워크플로 전체의 총 재시도 예산(budget)을 도입:
  - **total_retry_budget**: 워크플로 전체에서 소비할 수 있는 총 재시도 횟수 (기본: 50)
  - 각 Step에서 재시도할 때마다 예산에서 차감
  - 예산의 70% 소비 시 사용자에게 경고 (Progress Pulse 연계)
  - 예산 100% 소비 시 강제 에스컬레이션 (사용자가 추가 예산을 부여할 수 있음)
  - config.yaml에 `total_retry_budget: N`으로 설정 가능
- **기대 효과**: 무한 재시도로 인한 시간/비용 낭비 방지. 사용자가 전체 재시도 비용을 사전에 예측/제어 가능. grind 모드의 "끈질김"과 "경제성"의 균형.
- **근거**: SDK의 `max_turns` 파라미터가 에이전트 루프의 최대 반복 횟수를 제한하여 무한 루프를 방지하는 패턴.
- **전문가 합의**: Quality Guardian(주도), DX Specialist(비용 예측 가능성), Workflow Architect(Step별 한계와 총량 한계의 이중 안전망). Innovation Scout는 예산을 Step별로 동적 배분하는 고급 옵션도 제안했으나, 초기 버전은 단순 총량 제한으로 합의.

---

### [P-009] simon-bot-report에 Streaming/점진적 출력 패턴 도입

- **심각도**: LOW
- **대상 스킬**: simon-bot-report
- **대상 파일**: `SKILL.md`
- **카테고리**: DX (개발자 경험)
- **현재 상태**: simon-bot-report는 Step 1-3의 분석이 모두 완료된 후 Step 4에서 전체 보고서를 한 번에 생성하여 출력한다. 분석 시간이 긴 경우 사용자는 긴 대기 시간 동안 진행 상황을 알 수 없다.
- **제안 내용**: SDK의 `AsyncIterator` 스트리밍 패턴을 참고하여, 분석 과정의 중간 결과를 점진적으로 사용자에게 보여주는 "Progressive Disclosure" 패턴 도입:
  - Step 1(탐색) 완료 시: "탐색 완료. N개 파일에서 M개 핵심 모듈 식별. 다음: 코드 설계 분석..." 요약 출력
  - Step 2(설계 분석) 완료 시: 주요 발견 요약 출력 (예: "DDD 패턴 감지, 3개 Bounded Context 식별")
  - Step 3(전문가 토론) 각 팀 완료 시: 팀별 핵심 finding 1줄 요약 출력
  - Step 4에서 최종 보고서를 종합하되, 사용자는 이미 큰 그림을 파악한 상태
- **기대 효과**: 긴 분석 작업 중 사용자의 불안감 해소. 중간에 방향을 수정할 수 있는 기회 제공. 사용자가 분석 과정에 더 몰입.
- **근거**: SDK의 `async for message in query()`가 응답을 스트리밍으로 받아 실시간 처리하는 패턴. 결과를 한 번에 받는 대신 점진적으로 받는 사용자 경험.
- **전문가 합의**: DX Specialist(주도), Prompt Engineer(중간 요약의 톤/분량 가이드라인 필요), Innovation Scout(향후 인터랙티브 분석 방향과 일치). Workflow Architect는 중간 출력이 최종 보고서와 불일치하는 경우를 우려했으나, "중간 출력은 요약/프리뷰이고 최종 보고서가 정본"이라는 원칙으로 해소.

---

### [P-010] simon-bot-pm의 Feature Execution에 Sandbox/격리 설정 명시화

- **심각도**: LOW
- **대상 스킬**: simon-bot-pm
- **대상 파일**: `SKILL.md`, `references/feature-execution.md`
- **카테고리**: 품질/안전
- **현재 상태**: simon-bot-pm의 Phase 4(Feature Execution)에서 각 Feature를 워크트리로 격리하여 실행하지만, 격리 수준(어떤 도구를 제한하는지, 네트워크 접근은 어떻게 하는지)이 명시적으로 정의되어 있지 않다.
- **제안 내용**: SDK의 `SandboxSettings` 패턴을 참고하여, Feature 실행 시 격리 설정을 명시화:
  - 각 Feature Task Spec에 격리 수준 필드 추가:
    - `isolation: "standard"` — 워크트리 격리 + 기본 Forbidden Rules
    - `isolation: "strict"` — 추가로 네트워크 차단, 특정 디렉토리만 접근 가능
    - `isolation: "relaxed"` — 로컬 서버 접근 허용 (E2E 테스트 등)
  - 격리 수준에 따라 에이전트에게 전달하는 도구 목록과 제약사항이 자동 조정
- **기대 효과**: 각 Feature의 위험도에 맞는 격리 수준 적용. 병렬 실행 시 Feature 간 간섭 방지 강화. 보안에 민감한 Feature에 추가 보호 가능.
- **근거**: SDK의 `SandboxSettings`가 Bash 실행의 격리 환경을 구성하는 패턴. 도구 실행 환경의 보안 경계를 명시적으로 정의.
- **전문가 합의**: Quality Guardian(주도), Innovation Scout(지지), DX Specialist(기본값은 "standard"로 추가 설정 없이 동작해야 함). Workflow Architect는 과도한 격리가 개발 속도를 저해할 수 있다고 우려했으나, 기본값이 현재와 동일하므로 영향 없음으로 합의.

---

## Cross-Cutting Observations

### 1. 선언적 정의 vs 절차적 지시문

SDK는 에이전트, 도구, 권한, 에러를 모두 "선언적"으로 정의한다 (`AgentDefinition`, `@tool`, `PermissionMode`, 에러 계층). simon-bot 계열 스킬은 이를 "절차적 지시문" 속에 녹여서 기술하고 있다. 선언적 정의를 분리하면 (역할 레지스트리, Gate 정의, 에러 분류 트리) 스킬의 유지보수성과 확장성이 크게 향상된다.

### 2. 동적 조절 가능성

SDK는 세션 중 permission mode 변경, 모델 변경, MCP 서버 토글 등을 지원한다. simon-bot 계열은 스킬 선택 시점에 대부분의 설정이 고정된다. P-004(자율성 수준 동적 조절)를 시작으로, 워크플로 실행 중 다양한 파라미터를 동적으로 조절할 수 있는 방향으로 발전하면 사용자 경험이 크게 개선된다.

### 3. 구조화된 메타데이터

SDK는 세션 정보를 JSON으로 구조화하여 프로그래밍 방식 접근을 지원한다. simon-bot 계열은 마크다운 파일 중심이어서 파싱이 불편하다. 워크플로 상태, 세션 메타데이터, 에러 로그 등 기계가 읽어야 하는 데이터는 JSON으로, 사람이 읽어야 하는 데이터는 마크다운으로 이원화하면 양쪽 모두에 최적화된다.

### 4. 모든 스킬에 공통 적용 가능한 패턴

- **Gate 패턴** (P-001): simon-bot, grind뿐 아니라 simon-bot-pm의 Phase 전환에도 동일하게 적용 가능
- **에러 분류 세분화** (P-002): 모든 스킬의 에러 복구에 공통 적용
- **역할 레지스트리** (P-007): simon-bot과 simon-bot-report가 같은 역할 정의를 공유하면 일관성 향상

---

## Not Recommended

### 1. Stateless query() 패턴의 직접 도입

SDK의 `query()` 함수는 상태 없이 단발 질의를 수행한다. simon-bot 계열 워크플로는 본질적으로 상태를 유지하며 19단계를 거치는 장기 실행 프로세스이므로, stateless 패턴은 맞지 않는다. 세션 관리와 메모리 파일 시스템이 이미 이 역할을 충분히 수행하고 있다.

**기각 이유**: 워크플로의 핵심 가치인 "단계별 축적과 검증"과 상충.

### 2. Bidirectional Client 인터페이스 도입

SDK의 `ClaudeSDKClient`는 프로그래밍 방식의 양방향 통신을 제공한다. simon-bot은 Claude Code CLI 환경에서 직접 실행되므로 별도의 클라이언트 추상화 계층이 필요 없다. 현재의 에이전트 스폰 + memory 파일 기반 통신이 더 단순하고 적합하다.

**기각 이유**: 불필요한 추상화 계층 추가. 현재 구조에서 동일한 효과를 이미 달성하고 있음.

### 3. Plugin 시스템 도입

SDK의 플러그인 로딩 패턴(`type: "local"`, `path`)은 SDK 수준의 확장성을 위한 것이다. simon-bot 계열은 이미 "references/" 디렉토리로 모듈화되어 있고, 스킬 자체가 하나의 "플러그인"으로 동작한다. 별도의 플러그인 시스템은 과도한 엔지니어링이다.

**기각 이유**: 현재의 references/ 디렉토리 + 스킬 분리 구조가 충분히 모듈적.

### 4. ThinkingConfig (Extended Thinking) 명시적 제어

SDK에서 extended thinking의 on/off를 제어하는 패턴이 있으나, simon-bot은 현재 Claude Code의 기본 thinking 설정을 사용하고 있으며, 이를 스킬 수준에서 제어할 필요성이 낮다. 모델의 추론 품질은 프롬프트 품질로 관리하는 것이 더 적합하다.

**기각 이유**: 스킬 수준에서 제어하기보다는 Claude Code 전역 설정에 맡기는 것이 적절.
