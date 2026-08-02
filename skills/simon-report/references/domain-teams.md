# Domain Expert Teams

Step 3에서 사용하는 도메인 전문가 팀의 구성, 역할, 분석 항목.

## 팀 구성

**config.yaml의 experts 설정 참조.** 없으면 기본 전문가 사용.

**단일 통합 전문가 팀 생성** (Agent Teams 제약: 세션당 1팀):

`TeamCreate(team_name="domain-expert-review", description="도메인 전문가 통합 리뷰 팀")`

활성화된 도메인의 전문가를 하나의 팀에 모두 포함시킨다. 도메인팀별 구성원은 동일하되, 하나의 공유 작업 목록에서 도메인별로 작업을 분리한다.

팀원 spawn (병렬, `team_name="domain-expert-review"`):

- **Data 서브그룹** (auto-detect — DB/캐시/스토리지 관련 코드 감지 시):
  - rdbms-expert, cache-expert, nosql-expert
  - 토론 초점: 데이터 일관성, 캐시 전략, 스토리지 정합성

- **Integration 서브그룹** (auto-detect — API/비동기/외부연동 감지 시):
  - sync-api-expert, async-expert, external-integration-expert, messaging-expert
  - 토론 초점: 동기/비동기 경계, 에러 전파, 장애 격리

- **Safety 서브그룹** (always):
  - appsec-expert, stability-expert
  - 토론 초점: 보안 경계, 장애 복구, 입력 검증

- **Ops 서브그룹** (auto-detect — 인프라/성능/동시성 관련 코드 감지 시):
  - infra-expert, observability-expert, performance-expert, concurrency-expert
  - 토론 초점: 운영 안정성, 관측 가능성, 성능 병목

- **Code Design 서브그룹** (always — Step 2 결과 활용):
  - convention-expert, idiom-expert, design-pattern-expert, testability-expert
  - 토론 초점: 레포 컨벤션 준수, 설계 패턴, 테스트 가능성
  - Step 2의 `.claude/reports/code-design-{topic-slug}.md` 활용

> **Agent Teams Fallback**: Agent Teams 미활성 시, 각 전문가를 개별 `Agent(subagent_type="general-purpose")` subagent로 spawn하고, 결과를 오케스트레이터가 취합하여 교차 검증한다.

## 공통 원칙

**환각 방지 원칙 (모든 전문가 에이전트에 적용):**
- 읽지 않은 코드에 대해 추측하지 않는다. 파일은 반드시 Read 도구로 열어본 후에 의견을 제시한다.
- 코드를 직접 확인하지 못한 부분에 대해서는 "미확인" 또는 "추가 확인 필요"로 명시한다.

**Findings 품질 원칙 — "깊이 > 수량" (P-008):**
- 구체적 근거가 있는 5건이 모호한 설명의 20건보다 낫다
- 각 finding에 필수 포함: (1) 구체적 코드 위치, (2) 왜 문제인지, (3) 영향 범위
- 포함 금지: 추측성 보고, 변경하지 않은 코드에 대한 일반 조언
- MEDIUM 10개 이상 시 영향도 기준 상위 5개만 활성 처리, 나머지 backlog

**에이전트 도구 접근 범위 (P-011):**
- 분석/리뷰 에이전트: 허용(Read, Glob, Grep), 금지(Edit, Write, 변경성 Bash)
- 각 전문가 spawn prompt에 "코드를 읽고 분석만 하세요. 수정하지 마세요."를 포함

**Agent Teams Fallback**: Agent Teams가 비활성 상태이면 `~/.claude/skills/simon-dev/references/agent-teams.md`의 Fallback 섹션에 따라 subagent fallback을 적용한다.

## 도메인 서브그룹별 토론 프로세스 (3단계)

- Task "{domain}-분석": 각 teammate가 독립적으로 주제 관련 코드 검토 → 도메인별 findings 작성
- Task "{domain}-토론": 다른 teammate의 findings를 읽고 직접 반박/보강 토론
- Task "{domain}-합의": 팀 합의 도출 → 서브그룹별 findings 작성 (CRITICAL/HIGH/MEDIUM severity)

## CRITICAL Severity Voting 검증 (Safety Team)

- Task 3에서 CRITICAL severity 후보가 나오면, Safety Team이 해당 항목에 대해 2-3회 독립 분석을 수행한다.
- 각 독립 분석은 코드를 다시 Read로 읽고, 이전 분석 결과를 참조하지 않은 상태에서 severity를 판정한다.
- 독립 분석 결과가 일관되게 CRITICAL로 판정되는 경우에만 CRITICAL을 확정한다.
- Voting 합의 실패 시 (예: 3회 중 1회만 CRITICAL) severity를 HIGH로 재평가하고, 재평가 근거를 findings에 기록한다.
- 이 검증은 CRITICAL의 남발을 방지하고, 정말 중대한 이슈만 CRITICAL로 분류되도록 하기 위함이다.

## 팀에 전달할 컨텍스트

- Step 1의 탐색 결과 (`.claude/reports/exploration-{topic-slug}.md`)
- Step 2의 코드 설계 분석 (`.claude/reports/code-design-{topic-slug}.md`)
- 분석 주제 설명

## 중간 보고 (Progressive Disclosure) — 서브그룹별 완료 시

- 각 서브그룹이 "{domain}-합의" Task를 마칠 때마다, 사용자에게 서브그룹별 핵심 finding 1줄 요약을 출력한다.
  - 예: "Safety 서브그룹 완료: 입력 검증 누락 1건 CRITICAL, 세션 관리 이슈 1건 HIGH"
  - 예: "Data 서브그룹 완료: 캐시 무효화 전략 부재 1건 HIGH"
- 이 중간 출력은 진행 상황 프리뷰이며, 최종 보고서가 정본이다.

## Lead의 Cross-team Synthesis

- 5개 서브그룹의 findings를 통합
- 도메인 간 충돌 식별
- 최종 통합 분석 작성

## Findings 출력 형식

- **발견사항**: CRITICAL / HIGH / MEDIUM 심각도 (팀 합의 기반)
- **권장사항**: 구체적 주의점이나 개선 방향
- **토론 근거**: 어떤 전문가가 어떤 논거로 해당 severity에 합의했는지
