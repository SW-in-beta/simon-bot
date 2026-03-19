# Simon-Bot Skills 개선 분석 보고서

**분석 대상**: claude-code-sdk-python (anthropics/claude-agent-sdk-python)
**분석 일자**: 2026-03-06
**목적**: SDK의 기능을 활용하여 simon-bot 스킬 패밀리의 개선점 도출

---

## 1. 분석 요약

claude-agent-sdk-python은 Claude Code와 프로그래매틱하게 상호작용하기 위한 공식 Python SDK이다. 이 SDK가 제공하는 핵심 기능들(Hooks, Custom MCP Tools, ClaudeSDKClient, Session Management, Thinking Configuration 등)을 simon-bot 스킬 패밀리와 대조 분석하여, 현재 스킬들이 활용하지 못하고 있는 기능적 갭과 개선 가능성을 식별했다.

### 핵심 발견 요약

| 우선순위 | 개선 영역 | 관련 스킬 | 임팩트 |
|---------|----------|----------|--------|
| P1 | Hook 기반 안전장치 자동화 | simon-bot, grind | 높음 |
| P1 | Custom MCP Tool로 워크플로 도구 내재화 | 전체 | 높음 |
| P2 | Session History API 활용 | simon-bot-sessions | 중간 |
| P2 | Thinking Configuration 활용 | simon-bot, grind | 중간 |
| P2 | Permission 시스템 프로그래매틱 제어 | simon-bot, grind, pm | 중간 |
| P3 | Subagent Lifecycle Hook 활용 | simon-bot, grind, pm | 낮음-중간 |
| P3 | Sandbox 설정 활용 | simon-bot, grind | 낮음-중간 |

---

## 2. 상세 개선 제안

### 2.1 [P1] Hook 기반 안전장치 자동화

**현재 상태**: simon-bot의 Global Forbidden Rules는 텍스트 지시문으로만 존재한다. `git push --force`, `rm -rf`, `DROP TABLE`, 실제 DB/API 접근 등을 금지하지만, 이는 LLM의 지시문 준수에 의존하는 "소프트" 가드레일이다.

**SDK가 제공하는 기능**: `PreToolUse` Hook으로 Bash 명령어를 실행 전에 프로그래매틱하게 검사하고, 위험한 패턴이 감지되면 `permissionDecision: "deny"`로 실행 자체를 차단할 수 있다. 이는 LLM이 지시문을 무시하더라도 물리적으로 실행이 불가능한 "하드" 가드레일이다.

**구체적 적용 방안**:

```
PreToolUse Hook에서 차단할 패턴 목록:
- Bash: "git push --force", "git push -f", "rm -rf", "DROP TABLE", "TRUNCATE"
- Bash: "chmod 777", "curl | sh", "wget | sh"
- Bash: regex로 실제 DB 접속 명령어 (mysql, psql, redis-cli, mongosh + 호스트 포함)
- Bash: regex로 실제 외부 서버 접속 (ssh, scp, sftp + 호스트 포함)
- Bash: "eval" + 변수 조합
- Write: ".env" 파일 경로 감지 시 차단
- Bash: "git merge" + "main"/"master" 패턴
```

**영향받는 스킬**: simon-bot (Global Forbidden Rules), simon-bot-grind (동일 규칙 + 10회 재시도로 인한 위험 증가)

**구현 난이도**: 중간 -- Hook 함수 자체는 단순하나, simon-bot이 현재 Python SDK 기반이 아닌 Claude Code CLI 직접 호출 방식이라면 아키텍처 변경이 필요

**기대 효과**: 안전성 대폭 강화. 특히 simon-bot-grind의 10회 재시도 환경에서 반복 시도 중 위험한 명령이 실행될 확률을 0으로 만듦

---

### 2.2 [P1] Custom MCP Tool로 워크플로 도구 내재화

**현재 상태**: simon-bot은 워크플로 관리를 위해 Bash 스크립트(`manage-sessions.sh`)를 호출하고, 파일 기반 상태 관리(`.claude/memory/*.md`, `.claude/pm/state.json`)를 사용한다. 이 방식은 동작하지만, 구조화되지 않은 텍스트 파싱에 의존하고 에러 처리가 취약하다.

**SDK가 제공하는 기능**: `@tool` 데코레이터와 `create_sdk_mcp_server()`로 Python 함수를 MCP 도구로 등록할 수 있다. 이 도구들은 in-process로 실행되어 subprocess 오버헤드가 없고, 타입 안전하며, 에러 처리가 체계적이다.

**구체적 적용 방안**:

(A) **워크플로 상태 관리 도구**:
```
@tool("workflow_status", "현재 워크플로 상태 조회/갱신", {...})
@tool("checkpoint_create", "체크포인트 생성", {...})
@tool("checkpoint_rollback", "체크포인트로 롤백", {...})
@tool("failure_log", "실패 기록 추가/조회", {...})
```
- simon-bot-grind의 failure-log.md, checkpoints.md를 구조화된 도구로 대체
- JSON 기반 상태 관리로 파싱 오류 제거

(B) **세션 관리 도구**:
```
@tool("session_list", "워크트리 세션 목록", {})
@tool("session_info", "세션 상세 정보", {"branch": str})
@tool("session_delete", "세션 삭제", {"branch": str})
@tool("session_resume", "세션 복원 컨텍스트 로드", {"branch": str})
```
- simon-bot-sessions의 manage-sessions.sh를 Python MCP 도구로 대체
- 셸 스크립트 파싱 대신 구조화된 JSON 반환

(C) **PM 프로젝트 관리 도구**:
```
@tool("pm_task_update", "작업 상태 업데이트", {"task_id": str, "status": str})
@tool("pm_progress", "진행 현황 조회", {})
@tool("pm_dependency_check", "의존성 체크", {"task_id": str})
```
- simon-bot-pm의 tasks.json, state.json 관리를 도구로 추상화

**영향받는 스킬**: 전체

**구현 난이도**: 높음 -- 기존 Bash 스크립트 로직을 Python으로 이식하고, SDK 기반 실행 구조로 전환 필요

**기대 효과**:
- 에러 처리 강화 (is_error 플래그, 구조화된 에러 메시지)
- 상태 관리 신뢰성 향상 (텍스트 파싱 -> JSON)
- 디버깅 용이성 (Python 스택 트레이스 vs 셸 스크립트 에러)

---

### 2.3 [P2] Session History API 활용

**현재 상태**: simon-bot-sessions는 `manage-sessions.sh` 스크립트로 워크트리 세션을 관리한다. 세션 이력은 `.claude/memory/` 파일에 수동으로 기록되며, 이전 대화 내용을 복원하려면 메모리 파일을 읽어야 한다.

**SDK가 제공하는 기능** (v0.1.46+):
- `list_sessions()`: 과거 세션 목록 조회
- `get_session_messages()`: 특정 세션의 전체 대화 이력 조회

**구체적 적용 방안**:

(A) **세션 복원 강화**:
- `resume` 명령 시 `.claude/memory/` 파일 + SDK Session History를 함께 조회
- 실제 대화 이력에서 마지막 실행 Step, 발생한 에러, 사용자 피드백을 자동 추출
- 현재는 메모리 파일에 기록되지 않은 컨텍스트가 유실되는데, 세션 이력으로 보완 가능

(B) **회고 품질 향상**:
- Step 20(Self-Improvement)에서 세션 이력 전체를 분석하여 더 정확한 회고 작성
- 사용자가 실제로 어떤 피드백을 주었는지 원문 기반으로 확인 가능

(C) **세션 분석 대시보드**:
- `list` 명령에서 각 세션의 실제 대화 턴 수, 도구 사용 횟수, 비용 정보 제공
- 워크플로 효율성 트래킹

**영향받는 스킬**: simon-bot-sessions (직접), simon-bot/grind (간접 -- 세션 복원 시)

**구현 난이도**: 낮음 -- SDK 함수 호출만으로 구현 가능

**기대 효과**: 세션 복원의 정확도와 풍부함 향상, 컨텍스트 유실 최소화

---

### 2.4 [P2] Thinking Configuration 활용

**현재 상태**: simon-bot 스킬들은 에이전트 생성 시 모델만 지정하고(`architect`, `executor` 등), thinking 깊이를 제어하지 않는다. 모든 Step에서 동일한 thinking 수준이 적용된다.

**SDK가 제공하는 기능** (v0.1.36+):
- `ThinkingConfigAdaptive`: 상황에 따라 자동 조절
- `ThinkingConfigEnabled`: 특정 토큰 수만큼 thinking 활성화
- `ThinkingConfigDisabled`: thinking 비활성화
- `effort`: "low" / "medium" / "high" / "max"

**구체적 적용 방안**:

| Step | 현재 | 제안 | 근거 |
|------|------|------|------|
| Step 0 (Scope Challenge) | 기본 | effort: "high" | 범위 판별은 정확도가 중요 |
| Step 1-A (Analysis) | 기본 | thinking: enabled, high tokens | 코드 분석에 깊은 추론 필요 |
| Step 5 (Implementation) | 기본 | thinking: adaptive | 구현 복잡도에 따라 유동적 |
| Step 5 Build Retry (grind) | 기본 | effort: "max" | 빌드 실패 진단에 최대 추론력 |
| Step 7 (Review) | 기본 | effort: "high" | 버그/보안 발견에 높은 추론력 |
| Step 12 (Full Review) | 기본 | thinking: enabled, max tokens | 전체 코드 리뷰에 최대 깊이 |
| Step 18 (Report) | 기본 | effort: "medium" | 보고서 작성은 중간 수준 |

**영향받는 스킬**: simon-bot, simon-bot-grind

**구현 난이도**: 낮음 -- ClaudeAgentOptions에 파라미터 추가만으로 구현

**기대 효과**: 각 Step의 특성에 맞는 추론 깊이로 품질 향상 + 불필요한 thinking 감소로 비용 절감

---

### 2.5 [P2] Permission 시스템 프로그래매틱 제어

**현재 상태**: simon-bot은 `permission_mode`를 별도로 관리하지 않는다. Claude Code의 기본 permission 동작에 의존하며, 각 Step에서 필요한 도구를 암시적으로 사용한다.

**SDK가 제공하는 기능**:
- `permission_mode`: 'default' / 'acceptEdits' / 'bypassPermissions'
- `allowed_tools`: 특정 도구만 허용
- `set_permission_mode()`: 대화 중 동적 변경
- `PermissionRequest` Hook: 권한 요청 시 프로그래매틱 결정

**구체적 적용 방안**:

(A) **Phase별 Permission 격리**:
```
Phase A (Planning): allowed_tools=["Read", "Grep", "Glob"] -- 읽기 전용
Phase B (Implementation): allowed_tools=["Read", "Write", "Edit", "Bash"], permission_mode="acceptEdits"
Phase C (Review): allowed_tools=["Read", "Grep", "Glob"] -- 다시 읽기 전용
Integration: allowed_tools=["Read", "Write", "Edit", "Bash", "Git"]
```
- 계획 단계에서 실수로 코드를 변경하는 것을 방지
- 리뷰 단계에서 리뷰어가 직접 코드를 수정하는 것을 방지

(B) **simon-bot-report 읽기 전용 강제**:
- 현재 Global Rules로 "코드를 수정하지 않음"이라고 명시하지만, 소프트 가드레일
- `allowed_tools`에서 Write/Edit/Bash를 제거하면 하드 가드레일

(C) **grind의 동적 Permission**:
- Attempt 1-3 (Simple Fix): 기본 permission
- Attempt 7-9 (Strategy Pivot): 더 넓은 permission (구조 변경 허용)
- `set_permission_mode()`로 에스컬레이션 단계에 따라 동적 조정

**영향받는 스킬**: simon-bot, simon-bot-grind, simon-bot-pm, simon-bot-report

**구현 난이도**: 중간

**기대 효과**: 각 단계에 맞는 최소 권한 원칙 적용, 실수로 인한 코드 변경 방지

---

### 2.6 [P2] PostToolUse Hook으로 실행 결과 모니터링

**현재 상태**: simon-bot-grind의 failure-log.md는 에이전트가 자발적으로 실패를 기록하는 방식이다. 도구 실행 실패를 놓치거나 기록하지 않을 수 있다.

**SDK가 제공하는 기능**:
- `PostToolUse` Hook: 모든 도구 실행 후 결과를 검사
- `PostToolUseFailure` Hook: 도구 실행 실패 시 자동 트리거
- `continue_: False` + `stopReason`: 치명적 오류 시 실행 중단

**구체적 적용 방안**:

(A) **자동 실패 기록**:
```
PostToolUseFailure Hook:
- 모든 도구 실패를 자동으로 failure-log.md에 기록
- 에이전트의 자발적 기록에 의존하지 않음
- 실패 패턴 자동 감지 (같은 명령어 반복 실패 등)
```

(B) **빌드/테스트 결과 자동 분석**:
```
PostToolUse Hook (Bash matcher):
- 빌드 명령 결과에서 에러 패턴 자동 추출
- 테스트 실패 시 실패한 테스트 목록 자동 기록
- grind의 Auto-Diagnosis 시스템에 자동 피드
```

(C) **위험 감지 및 자동 중단**:
```
PostToolUse Hook:
- 프로덕션 DB 연결 시도 감지 시 즉시 중단 (continue_: False)
- 디스크 용량 부족 감지 시 경고
- 무한 루프 패턴 감지 (같은 명령 5회 이상 반복)
```

**영향받는 스킬**: simon-bot-grind (주로), simon-bot

**구현 난이도**: 중간

**기대 효과**: 실패 추적의 완전성 보장, 자동 진단 시스템의 정확도 향상

---

### 2.7 [P2] SubagentStart/Stop Hook으로 에이전트 팀 관리 강화

**현재 상태**: simon-bot의 Agent Teams는 Agent Teams 기능(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)에 의존하며, 팀원의 생성/종료를 직접 추적하지 않는다.

**SDK가 제공하는 기능** (v0.1.29+):
- `SubagentStart` Hook: subagent 시작 시 `agent_id`, `agent_type` 제공
- `SubagentStop` Hook: subagent 종료 시 `agent_transcript_path` 제공

**구체적 적용 방안**:

(A) **에이전트 실행 추적**:
```
SubagentStart Hook:
- 에이전트 시작 시 agent_id, agent_type, 시작 시각 기록
- 동시 실행 에이전트 수 추적
- 리소스 사용 모니터링

SubagentStop Hook:
- 에이전트 종료 시 실행 시간 계산
- transcript_path에서 에이전트 출력 자동 수집
- 실패한 에이전트 자동 감지
```

(B) **Agent Team 토론 품질 보장**:
- 토론 팀원이 예상보다 빨리 종료되면 재생성
- 토론 시간이 너무 길면 중재 개입

(C) **PM 스킬의 Feature Execution 모니터링**:
- 각 Feature에 할당된 에이전트의 실행 상태를 실시간 추적
- 실패한 에이전트를 자동으로 grind 모드로 재시작

**영향받는 스킬**: simon-bot (Agent Teams), simon-bot-pm (Feature Execution), simon-bot-grind

**구현 난이도**: 중간

**기대 효과**: 에이전트 실행의 가시성과 제어력 향상

---

### 2.8 [P3] Sandbox 설정으로 실행 환경 격리

**현재 상태**: simon-bot은 Global Forbidden Rules로 위험한 명령을 금지하지만, 실행 환경 자체는 격리되지 않는다.

**SDK가 제공하는 기능**:
```
SandboxSettings:
  enabled: bool
  autoAllowBashIfSandboxed: bool
  excludedCommands: List[str]
  network: SandboxNetworkConfig (Unix socket, local binding 제어)
  ignoreViolations: SandboxIgnoreViolations
```

**구체적 적용 방안**:
- simon-bot 실행 시 sandbox 활성화
- 네트워크 접근을 로컬로 제한 (외부 API/DB 접근 물리적 차단)
- `excludedCommands`로 위험 명령어 목록 관리
- `autoAllowBashIfSandboxed: true`로 샌드박스 내에서는 Bash 자동 허용 (워크플로 속도 향상)

**영향받는 스킬**: simon-bot, simon-bot-grind

**구현 난이도**: 낮음

**기대 효과**: 환경 수준 격리로 안전성 최대화, 동시에 샌드박스 내 자동 허용으로 워크플로 속도 유지

---

### 2.9 [P3] PreCompact Hook으로 컨텍스트 관리 개선

**현재 상태**: simon-bot은 Context Window Management 섹션에서 세션 분할 경계를 정의하고, 컨텍스트 부족 시 메모리 파일을 저장한다. 하지만 컨텍스트 압축(compact) 시 어떤 정보가 유지되는지 제어하지 못한다.

**SDK가 제공하는 기능**:
- `PreCompact` Hook: 컨텍스트 압축 전에 트리거, `custom_instructions`로 압축 시 유지할 핵심 정보 지정 가능

**구체적 적용 방안**:
```
PreCompact Hook:
- 현재 실행 중인 Step 번호와 상태를 custom_instructions에 주입
- 핵심 결정사항(plan-summary, code-design-analysis)의 요약을 주입
- grind의 failure-log 요약을 주입
- 압축 후에도 워크플로 연속성이 유지되도록 보장
```

**영향받는 스킬**: simon-bot (Context Window Management), simon-bot-grind (재시도가 많아 컨텍스트 소비 빠름)

**구현 난이도**: 낮음

**기대 효과**: 컨텍스트 압축 시 워크플로 핵심 정보 보존, 세션 분할 없이 더 오래 실행 가능

---

### 2.10 [P3] MCP Server Runtime 관리

**현재 상태**: simon-bot은 Context7 MCP를 Step 1-A에서 라이브러리 문서 조회에 사용하지만, MCP 서버 연결 실패 시 에러 처리가 명시적이지 않다.

**SDK가 제공하는 기능** (v0.1.46+):
- `add_mcp_server()`: 런타임에 MCP 서버 추가
- `remove_mcp_server()`: 런타임에 MCP 서버 제거
- `get_mcp_status()`: MCP 서버 연결 상태 조회
- `reconnect_mcp_server()`: 실패한 서버 재연결
- `toggle_mcp_server()`: 서버 활성화/비활성화

**구체적 적용 방안**:
- Step 1-A 시작 시 Context7 MCP 서버 연결 상태 확인
- 연결 실패 시 자동 재연결 시도
- 불필요한 MCP 서버는 비활성화하여 리소스 절약
- Phase별로 필요한 MCP 서버만 동적으로 활성화

**영향받는 스킬**: simon-bot (Context7 사용), simon-bot-report (Context7 사용)

**구현 난이도**: 낮음

**기대 효과**: MCP 연결 안정성 향상, 리소스 효율화

---

## 3. 아키텍처 전환 고려사항

위 개선 제안들의 대부분은 **simon-bot 스킬이 Python SDK 기반 런처에서 실행되는 구조**를 전제로 한다. 현재 simon-bot 스킬들은 Claude Code CLI의 slash command / skill 시스템 위에서 동작하므로, SDK 기능을 완전히 활용하려면 다음과 같은 아키텍처 전환이 필요하다.

### 3.1 단계적 전환 전략

**Phase 1 (즉시 적용 가능 -- 스킬 텍스트 개선)**:
- 현재 구조를 유지하면서, SDK의 개념을 스킬 지시문에 반영
- 예: thinking 깊이 관련 지시를 에이전트 생성 시 명시적으로 추가
- 예: Phase별 allowed_tools를 지시문으로 명시

**Phase 2 (Python 런처 도입)**:
- simon-bot 워크플로를 오케스트레이션하는 Python 스크립트 작성
- SDK의 `ClaudeSDKClient`를 사용하여 각 Step을 프로그래매틱하게 실행
- Hook 시스템으로 안전장치 적용
- Custom MCP Tool로 상태 관리 도구 등록

**Phase 3 (완전 SDK 기반)**:
- 모든 에이전트 생성/관리를 SDK로 전환
- 전체 19-step 파이프라인을 Python 코드로 오케스트레이션
- 실시간 모니터링 대시보드 구축 가능

### 3.2 전환 시 주의사항

- **Agent Teams 호환성**: SDK의 subagent 기능과 Claude Code의 Agent Teams 기능은 별개. SDK의 subagent hook은 Agent Teams 팀원의 lifecycle도 추적 가능한지 확인 필요
- **Worktree 관리**: SDK는 `cwd` 옵션으로 작업 디렉토리를 지정할 수 있어, worktree 기반 격리와 호환 가능
- **비용 추적**: SDK의 `ResultMessage.total_cost_usd`로 각 Step/에이전트의 비용을 정밀하게 추적 가능

---

## 4. 구현 우선순위 권고

### 즉시 반영 가능 (스킬 텍스트 수준)

1. **Phase별 도구 제한 명시**: 각 Phase에서 사용 가능한 도구를 명시적으로 열거 (기존 지시문 강화)
2. **Thinking 깊이 지시 추가**: 각 Step에서 에이전트 생성 시 thinking 깊이 힌트 추가
3. **세션 복원 시 대화 이력 활용**: simon-bot-sessions의 resume 플로우에서 Claude 세션 이력 참조 지시 추가

### 중기 (Python 런처 구축 시)

4. **PreToolUse Hook으로 Forbidden Rules 하드코딩** -- 안전성 최대 개선
5. **PostToolUseFailure Hook으로 자동 실패 기록** -- grind의 Auto-Diagnosis 신뢰성 향상
6. **Custom MCP Tool로 상태 관리 도구 구축** -- 에러 처리, 구조화된 데이터

### 장기 (완전 SDK 기반 전환 시)

7. **Sandbox 설정으로 환경 격리**
8. **SubagentStart/Stop Hook으로 에이전트 팀 모니터링**
9. **PreCompact Hook으로 컨텍스트 압축 최적화**
10. **MCP Server Runtime 관리**

---

## 5. 결론

claude-agent-sdk-python은 simon-bot 스킬 패밀리가 현재 "지시문 기반 소프트 가드레일"로 처리하는 많은 영역을 "프로그래매틱 하드 가드레일"로 전환할 수 있는 도구를 제공한다. 가장 임팩트가 큰 개선은 다음 두 가지이다:

1. **Hook 기반 안전장치**: Global Forbidden Rules를 PreToolUse Hook으로 물리적 차단 구현
2. **Custom MCP Tool**: 워크플로 상태 관리를 구조화된 도구로 대체

이 두 가지만으로도 안전성과 신뢰성이 크게 향상되며, 나머지 개선사항은 점진적으로 적용할 수 있다. 다만, 이 모든 개선의 전제는 simon-bot 워크플로를 Python SDK 기반으로 오케스트레이션하는 런처를 구축하는 것이므로, 아키텍처 전환 계획을 먼저 수립하는 것을 권장한다.
