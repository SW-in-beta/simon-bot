# Error Resilience Protocol (Cross-Cutting — ALL Steps)

사용자가 명시적으로 중단을 요청하지 않는 한 워크플로를 중단하지 않는다. 에러는 학습과 복구의 기회이다.

어떤 단계에서든 명령어 실행(빌드, 테스트, 타입체크, 린트 등)이 실패하면:

## Step 0: 실패 유형 분류

모든 실패를 먼저 분류한다. 분류 없이 재시도하면 동일한 실패를 반복하게 된다.

에러 분류 트리의 키워드 매칭(`connection refused`, `assert`, `expected.*but got` 등)은 본질적으로 결정론적 작업이다. CLI 스크립트(`classify-error.sh` 등)가 있으면 키워드 기반 자동 분류를 먼저 수행하고, LLM은 분류 결과만 받아 복구 전략을 선택한다. 결정론적으로 분류할 수 없는 복합 에러만 LLM이 직접 분석한다.

### 에러 분류 트리

```
WorkflowError
├── ENV_INFRA — 인프라/환경 문제로 코드 수정으로 해결 불가
│   ├── TOOL_UNAVAILABLE — 도구/CLI 미설치 또는 버전 불일치
│   │   예: `command not found`, `version mismatch`
│   │   1차 복구: 도구 설치 시도 (asdf, brew, apt)
│   │   2차 복구: 해당 도구 없이 진행 가능한 대안 탐색
│   │
│   ├── NETWORK_ERROR — 타임아웃, 연결 실패
│   │   예: `connection refused`, `ECONNREFUSED`, `timeout`
│   │   1차 복구: 재시도 (최대 3회, 지수 백오프)
│   │   2차 복구: 네트워크 의존 없는 로컬 대안 사용
│   │
│   ├── RESOURCE_LIMIT — 메모리, 디스크, 컨텍스트 부족
│   │   예: `no space left on device`, `OOMKilled`, 컨텍스트 압축 발생
│   │   1차 복구: 불필요한 리소스 정리 (docker prune, 캐시 삭제)
│   │   2차 복구: 리소스 사용량 줄이는 방식으로 전환 (배치 크기 축소 등)
│   │
│   └── PERMISSION_ERROR — 권한 부족
│       예: `permission denied` (시스템 파일/디렉토리)
│       1차 복구: 접근 가능한 경로로 우회
│       2차 복구: 사용자에게 권한 부여 요청
│
├── CODE_LOGIC — 코드 버그/설계 문제로 코드 수정으로 해결 가능
│   ├── BUILD_FAILURE — 컴파일, 타입 에러
│   │   예: `compilation failed`, `type mismatch`, `cannot find module`
│   │   1차 복구: 에러 메시지 기반 코드 수정 (executor)
│   │   2차 복구: architect가 Root Cause Analysis 후 설계 수준 수정
│   │
│   ├── TEST_FAILURE — 테스트 실패
│   │   예: `assert`, `expected.*but got`
│   │   1차 복구: 실패 테스트 분석 → 구현 코드 수정
│   │   2차 복구: 테스트 의도 재검토 → 테스트/구현 모두 재설계
│   │
│   ├── LINT_VIOLATION — 스타일, 포맷 위반
│   │   예: lint 경고/에러
│   │   1차 복구: auto-fix 도구 실행 (gofmt, eslint --fix 등)
│   │   2차 복구: 수동 수정
│   │
│   └── DESIGN_CONFLICT — 설계 충돌
│       예: 기존 아키텍처와 구현 방식 불일치
│       1차 복구: plan-summary.md 재확인 후 구현 수정
│       2차 복구: architect 판단 → Step 1-B로 회귀
│
└── WORKFLOW_ERROR — 워크플로 자체의 실패
    ├── GATE_FAILURE — Pre/PostStep 조건 미충족
    │   예: 검증 게이트 미통과, 필수 파일 미생성
    │   1차 복구: 해당 Step 재실행
    │   2차 복구: 이전 Step부터 재실행
    │
    ├── AGENT_TIMEOUT — 에이전트 응답 없음
    │   예: subagent가 일정 시간 내 완료되지 않음
    │   1차 복구: agent 재spawn
    │   2차 복구: 작업을 직접 수행
    │
    └── STATE_CORRUPTION — 메모리 파일 손상
        예: .claude/memory/*.md 파일 손상 또는 불일치
        1차 복구: git diff 기반으로 상태 재구성
        2차 복구: 마지막 정상 상태(커밋)부터 재개
```

### 자동 판별 키워드

- ENV_INFRA 패턴: `connection refused`, `Cannot connect to the Docker daemon`, `port already in use`, `command not found`, `ECONNREFUSED`, `timeout`, `no space left on device`, `permission denied` (시스템 파일), `unhealthy`, `OOMKilled`, `docker: Error`, `compose.*failed`
- CODE_LOGIC 패턴: `assert`, `expected.*but got`, `undefined`, `TypeError`, `SyntaxError`, `cannot find module`, `does not exist`, `compilation failed`, `type mismatch`
- WORKFLOW_ERROR 패턴: `gate check failed`, `agent timeout`, `file not found` (memory 파일), `invalid state`

**혼합 상황 판별:** 에러 메시지에 여러 패턴이 있으면 ENV_INFRA → WORKFLOW_ERROR → CODE_LOGIC 순으로 우선 처리한다. 인프라가 안 되면 코드 수정도 의미 없기 때문이다.

## ENV_INFRA 실패 처리 (환경/인프라 자동 복구)

환경 문제는 코드를 고쳐도 해결되지 않으므로, 인프라 복구에 집중한다. 위의 에러 분류 트리에서 하위 유형(TOOL_UNAVAILABLE, NETWORK_ERROR, RESOURCE_LIMIT, PERMISSION_ERROR)을 먼저 식별한 후, 해당 유형의 1차/2차 복구 전략을 시도한다. 하위 유형별 전략으로 해결되지 않으면 아래 Ladder로 에스컬레이션한다.

**자동 복구 Ladder (최대 5회):**

| 시도 | 복구 전략 |
|------|----------|
| 1 | **기본 재시작**: `setup-test-env.sh` 재실행. Docker면 `docker compose restart` |
| 2 | **클린 재시작**: `docker compose down && docker compose up -d`. npm이면 `rm -rf node_modules && npm install` |
| 3 | **볼륨/캐시 초기화**: `docker compose down -v && docker compose up -d`. 포트 충돌이면 충돌 프로세스 식별 후 사용자에게 보고 |
| 4 | **이미지 재빌드**: `docker compose build --no-cache && docker compose up -d`. 네트워크 재생성 |
| 5 | **전략 전환**: 환경 없이 가능한 테스트만 실행 (unit test only, mock 기반) |

**5회 모두 실패 시:**
- 테스트를 **SKIP** 처리하고 build + typecheck는 계속 진행
- `.claude/memory/test-env-status.md`에 실패 상세 기록
- 사용자에게 AskUserQuestion으로 알림:
  - "테스트 환경(Docker/DB 등) 구축에 실패했습니다. build/typecheck는 통과합니다. 테스트 없이 진행할까요?"
  - 선택지: 테스트 없이 계속 / 환경 직접 수정 후 재시도 / 워크플로 중단

**핵심 원칙: 환경 문제로 워크플로 전체가 멈추는 것을 방지한다. 테스트가 안 되더라도 build/typecheck/리뷰는 진행 가능하다.**

## CODE_LOGIC 실패 처리 (에스컬레이션)

위의 에러 분류 트리에서 하위 유형(BUILD_FAILURE, TEST_FAILURE, LINT_VIOLATION, DESIGN_CONFLICT)을 먼저 식별한 후, 해당 유형의 1차/2차 복구 전략을 시도한다.

1. 에러 출력을 읽고 하위 유형을 분류한다
2. 해당 유형의 1차 복구 전략을 시도한다 (최대 3회)
3. 1차 복구 실패 시 2차 복구 전략을 시도한다 (최대 3회 추가)
4. 6회 모두 실패 시 사용자에게 AskUserQuestion으로 상황 보고 + 선택지 제시:
   - 다른 접근법으로 재시도
   - 해당 단계를 건너뛰고 다음으로 진행
   - **simon-bot-grind로 전환** — 현재 상태를 유지한 채 재시도 한계를 10으로 상향하고 자동 진단/전략 전환을 활성화한다. 전환 시 `.claude/memory/failure-log.md`와 `.claude/memory/checkpoints.md`를 초기화하고, grind의 Escalation Ladder를 Attempt 1부터 시작한다.
   - 워크플로 중단 (사용자가 명시적으로 선택한 경우에만)

## WORKFLOW_ERROR 실패 처리

워크플로 자체의 실패(게이트 미통과, 에이전트 무응답, 상태 파일 손상)는 위의 에러 분류 트리에서 하위 유형을 식별한 후 복구한다.

1. GATE_FAILURE: 해당 Step을 재실행한다. 재실패 시 이전 Step부터 재실행한다.
2. AGENT_TIMEOUT: agent를 재spawn한다. 재실패 시 작업을 직접 수행한다.
3. STATE_CORRUPTION: git diff 기반으로 상태를 재구성한다. 불가능하면 마지막 정상 커밋부터 재개한다.

## 공통 원칙

에러 발생 시 다음 순서를 따른다:

1. **즉시 분류**: 에러 출력에서 실패 유형(ENV_INFRA / CODE_LOGIC / WORKFLOW_ERROR)을 식별한다.
   분류 없이 수정하면 환경 문제에 코드를 고치는 등 방향이 엇나가기 때문이다.
2. **유형별 복구 실행**: ENV_INFRA는 환경 복구 Ladder, CODE_LOGIC은 코드 수정 Ladder를 적용한다.
   ENV_INFRA에 코드 수정을 시도하면 증상만 가리고 근본 원인이 남기 때문이다.
3. **Ladder 소진 후 사용자 보고**: 자동 복구가 모두 실패하면 AskUserQuestion으로 선택지를 제시한다.
   자동 복구 여지가 남아 있는 상태에서 사용자에게 보고하면 불필요한 중단이 발생하기 때문이다.

에러를 무시하고 다음 Step으로 진행하면 미수정 실패가 누적되어 디버깅 비용이 기하급수적으로 증가한다 (Stop-and-Fix Gate 참조).

### Recovery Progress Pulse

에러 복구 중 각 단계에서 사용자에게 1줄 상태를 출력한다:

```
[Recovery] ENV_INFRA: 기본 재시작 시도 (1/5)
[Recovery] ENV_INFRA: 기본 재시작 실패 → 클린 재시작 시도 (2/5)
[Recovery] CODE_LOGIC/TEST_FAILURE: 에러 기반 코드 수정 시도 (2/6) — assert: expected 200 got 404
[Recovery] CODE_LOGIC: 1차 전략 실패 → 2차 전략(Root Cause Analysis) 전환 (4/6)
```

AskUserQuestion이 아닌 단순 텍스트 출력으로, 사용자를 중단시키지 않되 복구 진행 상황의 가시성을 확보한다.

**적용 범위:** build 실패, test 실패, typecheck 실패, lint 실패, docker 명령 실패, git 명령 실패, script 실행 실패 등 모든 종류의 명령어 실행 실패에 적용
