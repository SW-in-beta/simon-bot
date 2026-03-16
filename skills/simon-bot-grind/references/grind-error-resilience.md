# Grind Error Resilience (Enhanced — 10 Attempts)

> Base protocol: `~/.claude/skills/simon-bot/references/error-resilience.md`
> 이 문서는 simon-bot의 Error Resilience Protocol을 열일모드로 확장합니다.

## Error Classification Tree

실패를 정확히 분류해야 올바른 복구 전략을 선택할 수 있다. 잘못된 분류는 시간 낭비로 이어진다
(예: 네트워크 문제에 코드를 수정하면 해결되지 않는다).

에러 발생 시 아래 트리를 따라 가장 구체적인 하위 유형으로 분류한다:

```
ERROR
├── ENV_INFRA (환경/인프라 — 코드 수정으로 해결 불가)
│   ├── TOOL_UNAVAILABLE — 빌드 도구, 런타임, CLI 없음/버전 불일치
│   │   → 복구: 설치/버전 맞추기, asdf/nvm 등 버전 매니저 활용
│   ├── NETWORK_ERROR — 패키지 다운로드 실패, API 타임아웃, DNS 실패
│   │   → 복구: 재시도 대기, 미러/캐시 사용, 오프라인 모드 시도
│   ├── DOCKER_ERROR — 컨테이너 시작 실패, 이미지 빌드 실패, 볼륨/포트 충돌
│   │   → 복구: ENV_INFRA 복구 Ladder 적용
│   ├── PERMISSION_ERROR — 파일/디렉토리 권한, Docker 소켓 접근
│   │   → 복구: 권한 수정, 실행 컨텍스트 확인
│   └── RESOURCE_EXHAUSTION — 디스크 부족, 메모리 부족, 포트 고갈
│       → 복구: 정리(prune), 리소스 확보
│
├── CODE_LOGIC (코드/로직 — 코드 수정으로 해결)
│   ├── BUILD_FAILURE — 컴파일 에러, 타입 에러, import 누락
│   │   → 복구: 에러 메시지 기반 직접 수정
│   ├── TEST_FAILURE — 테스트 assertion 실패, 테스트 타임아웃
│   │   → 복구: 로직 수정 (테스트가 아닌 구현을 수정)
│   ├── LINT_FORMAT — 린터/포매터 위반
│   │   → 복구: 자동 수정 도구 실행 또는 수동 수정
│   ├── RUNTIME_ERROR — 실행 중 패닉, nil pointer, 예외
│   │   → 복구: 디버깅 → 방어 코드 또는 로직 수정
│   └── LOGIC_ERROR — 코드는 실행되지만 결과가 틀림
│       → 복구: 요구사항 재확인 → 알고리즘/로직 수정
│
└── WORKFLOW_ERROR (워크플로 자체의 실패)
    ├── GATE_FAILURE — 검증 게이트 미통과, 필수 파일 미생성
    │   → 복구: 해당 Step 재실행 (max 3), 실패 시 이전 Step부터 재실행
    ├── AGENT_TIMEOUT — subagent/팀원이 응답 없음
    │   → 복구: agent 재spawn (max 3), 실패 시 작업을 직접 수행
    └── STATE_CORRUPTION — .claude/memory/*.md 파일 손상 또는 불일치
        → 복구: git diff 기반 상태 재구성, 불가능하면 마지막 정상 커밋부터 재개
```

분류 후 해당 유형(ENV_INFRA / CODE_LOGIC / WORKFLOW_ERROR)의 복구 전략을 적용한다. **모호한 경우 ENV_INFRA → WORKFLOW_ERROR → CODE_LOGIC 순으로 우선 처리한다** (simon-bot 기본 프로토콜과 동일).

에러 분류 트리의 키워드 매칭은 결정론적 작업이다. CLI 스크립트(`classify-error.sh` 등)가 있으면 키워드 기반 자동 분류를 먼저 수행하고, LLM은 분류 결과만 받아 복구 전략을 선택한다. grind의 재시도가 최대 10회이므로, 매번 에러 로그를 LLM이 읽는 것보다 CLI로 분류 결과만 받는 것이 컨텍스트 절약에 효과적이다.

## ENV_INFRA 실패 처리 (최대 10회)

| 시도 | 복구 전략 |
|------|----------|
| 1 | **기본 재시작**: `setup-test-env.sh` 재실행. Docker면 `docker compose restart` |
| 2 | **클린 재시작**: `docker compose down && docker compose up -d`. npm이면 `rm -rf node_modules && npm install` |
| 3 | **볼륨/캐시 초기화**: `docker compose down -v && docker compose up -d`. pip면 `pip cache purge && pip install` |
| 4 | **이미지 재빌드**: `docker compose build --no-cache && docker compose up -d` |
| 5 | **네트워크 재생성**: `docker network prune -f && docker compose up -d`. 포트 충돌이면 충돌 프로세스 식별 |
| 6 | **시스템 정리**: `docker system prune -f` (미사용 이미지/컨테이너 제거) → 재시도 |
| 7 | **Architect 진단**: `architect` spawn → 환경 문제 Root Cause Analysis → 복구 스크립트 생성 → 실행 |
| 8 | **대체 환경**: Docker 대신 로컬 서비스 시도, 또는 testcontainers 등 대안 탐색 |
| 9 | **최소 환경**: 환경 의존 테스트를 제외하고 unit test만 실행. mock 기반으로 전환 |
| 10 | **Last Stand**: architect + executor 협업으로 완전히 다른 테스트 전략 시도 |

**10회 모두 실패 시:**
- 테스트를 **SKIP** 처리하고 build + typecheck는 계속 진행
- `.claude/memory/test-env-status.md` + `.claude/memory/failure-log.md`에 기록
- AskUserQuestion: "테스트 환경 10회 시도 실패. build/typecheck는 통과합니다."

## WORKFLOW_ERROR 실패 처리 (최대 10회)

WORKFLOW_ERROR도 동일한 10회 escalation ladder를 따른다:

| 시도 | 복구 전략 |
|------|----------|
| 1 ~ 3 | **Step/Agent 재시도**: 해당 Step 재실행 또는 agent 재spawn. GATE_FAILURE면 누락 파일 생성 확인 후 재실행, AGENT_TIMEOUT이면 agent 재spawn, STATE_CORRUPTION이면 memory 파일 재생성 |
| 4 ~ 6 | **Architect 워크플로 진단**: `architect` spawn → 워크플로 상태(memory 파일, 게이트 조건, agent 의존성) 분석 → 근본 원인 파악 후 수정 |
| 7 ~ 9 | **Git 기반 상태 재구성**: `git diff`/`git log` 기반으로 마지막 정상 상태를 파악하고 memory 파일 및 워크플로 상태를 재구성. 필요 시 마지막 정상 커밋부터 재개 |
| 10 | **Last Stand**: architect + executor 협업으로 워크플로 우회 경로 시도. 실패 시 → Human Escalation via `.claude/memory/escalation-report.md` |

**10회 모두 실패 시:**
- `.claude/memory/failure-log.md`에 워크플로 실패 이력 기록
- AskUserQuestion: "워크플로 오류 10회 시도 실패. 상태 재구성이 불가합니다."

## CODE_LOGIC 실패 처리 (Auto-Diagnosis Escalation Ladder)

1. **핵심 행동 원칙 적용** — 에러 출력을 읽고 즉시 분류 → Escalation Ladder 완주 → Ladder 소진 후 선택지 제시 (위 "핵심 행동 원칙" 참조).
2. **Auto-Diagnosis Escalation Ladder** (아래 참조): 10회까지 자동 재시도

### Anti-Hardcoding 원칙

재시도가 늘어날수록 "일단 테스트만 통과시키자"는 유혹이 커진다. 하지만 하드코딩된 해결책은
다른 입력에서 깨지고, 결국 더 큰 재작업을 부른다.

- **테스트를 통과시키기 위해 특정 테스트 입력값을 하드코딩하지 않는다.** 모든 유효한 입력에 대해 올바르게 동작하는 일반적 해결책을 구현한다.
- **테스트가 부정확하다고 판단되면, 테스트를 우회하거나 무시하지 않고 이를 사용자에게 보고한다.** (AskUserQuestion: "이 테스트의 기대값이 요구사항과 불일치하는 것 같습니다: [근거]")
- 예외: 사용자가 명시적으로 "임시 해결책 OK"라고 허용한 경우에만 허용

## Escalation Ladder (per step)

단계적으로 접근 강도를 높이는 이유: 대부분의 실패는 단순한 원인이므로 가벼운 수정으로 빠르게 해결하고,
그래도 안 되면 점진적으로 깊은 분석과 대담한 전략 전환으로 넘어간다.

| Attempt | Action | 이 단계의 이유 |
|---------|--------|--------------|
| 1 ~ 3 | Simple retry: `executor` fixes the immediate issue (동일 컨텍스트) | 대부분의 실패는 단순한 실수 — 빠른 수정이 가장 효율적 |
| 4 ~ 6 | **Root Cause Analysis**: **fresh executor subagent** spawn → 실패 결과(에러 메시지, 실패 테스트)만 전달, 이전 추론 과정은 차단 (What-not-Why Handoff). architect가 진단 후 fresh executor가 deeper fix 적용 | 같은 실수가 반복되면 표면이 아닌 근본 원인을 찾아야 함. 새 컨텍스트는 기존 가정에 오염되지 않은 시각을 제공 |
| 7 ~ 9 | **Strategy Pivot**: **fresh architect + executor** spawn → 원래 요구사항 + 실패 이력(what)만 전달, 접근 방식(why)은 차단. 새 architect가 2-3개 대안 제시, 가장 다른 접근법 선택, checkpoint에서 재시작 | 같은 전략으로 6번 실패 + 같은 사고방식도 오염됨. 코드 롤백만으로 부족 — 사고방식도 리셋해야 함 |
| 10 (final) | **Last Stand**: 완전 fresh context — 최소 정보(요구사항 + 최종 에러)만 전달한 새 architect + executor. If fails → Human Escalation via `.claude/memory/escalation-report.md` | 마지막 시도 — 모든 가용 자원 투입 + 완전한 인지적 독립 |

> **Fresh Context 원칙** (`context-separation.md` 참조): Attempt 4+에서 spawn하는 에이전트에게 결과(What: 에러 메시지, 실패 테스트, git diff)는 전달하되 추론(Why: 이전 접근법의 판단 근거, 실패 분석)은 차단한다. 이전 에이전트의 사고 패턴이 새 에이전트를 오염시키면 fresh context의 이점이 상실된다.

**Progress Detection 연계**: 진전 없는 재시도가 2회 연속되면 현재 tier를 건너뛰고 다음 tier로 즉시 이동한다 (상세: grind-cross-cutting.md의 Progress Detection 참조).

## 핵심 행동 원칙

grind의 차별점은 자동 복구 능력이다. 다음 순서를 따른다:

1. **분류 먼저**: 에러 출력에서 유형(ENV_INFRA / CODE_LOGIC / WORKFLOW_ERROR)을 즉시 식별한다.
   잘못된 분류(예: 네트워크 문제에 코드 수정)는 시간을 낭비하기 때문이다.
2. **Escalation Ladder 완주**: Attempt 1에서 10까지 단계적으로 강도를 높이며 자동 복구한다.
   자동 복구 여지가 남아 있는 상태에서 사용자에게 보고하면 grind의 가치가 낭비되기 때문이다.
3. **Ladder 소진 후 선택지 제시**: 10회 모두 실패하면 AskUserQuestion으로 사용자에게 선택지를 제시한다.
   (사용자가 중간에 명시적으로 중단을 요청하면 즉시 중단한다.)

## Test Environment Setup (Enhanced)

- Exit code 1 (toolchain 실패) → max 10 attempts:
  - Attempt 1-3: Clean install
  - Attempt 4-6: Alternative package manager
  - Attempt 7-8: Architect diagnoses environment
  - Attempt 9: Minimal dependency install
  - Attempt 10: Last stand — architect workaround
- Exit code 2 (ENV_INFRA) → 위 ENV_INFRA 복구 Ladder 적용 (10회)
