# Workflow Gotchas & Red Flags

Claude가 이 워크플로에서 반복적으로 범하는 실수. 각 항목은 실제 실패에서 추출되었다. Step 20(Self-Improvement)에서 새 gotcha를 추가하여 세션을 거듭할수록 축적한다.

## Gotchas

### G-WF-001: 계획 밖 파일 조용히 수정
executor가 plan-summary.md의 Files Changed에 없는 파일을 "관련 파일이니까" 수정한다. → Plan Immutability 절차를 따른다 (phase-b-implementation.md Critical Rules).

### G-WF-002: Behavioral Check 없이 Step 17 통과 시도
"빌드+테스트 통과 = 완료"로 판단하여 Behavioral Check의 verify command를 실행하지 않는다. → done_when_checks에 `verified: false` 항목이 있으면 G-PROD Gate FAIL.

### G-WF-003: 인터뷰에서 코드로 확인 가능한 사항을 질문
"어떤 프레임워크를 사용하나요?" 등 code-design-analysis.md로 답할 수 있는 질문을 한다. → Interview Guard + Anti-patterns 목록 참조.

### G-WF-004: compaction 후 workflow-state.json 재로딩 누락
compaction 후 현재 Step을 기억에 의존하여 이전 Step을 반복하거나 건너뛴다. → State-Driven Execution 루틴: 매 턴 시작 시 workflow-state.json 읽기 필수.

### G-WF-005: 전문가 finding을 severity 확인 없이 전부 수정
MEDIUM finding까지 모두 수정하여 scope creep이 발생한다. → CRITICAL → 계획 수정, HIGH → 주의사항 추가, MEDIUM → 기록만.

### G-WF-006: 기존 코드 패턴 불일치를 확인 없이 버그로 단정
if 브랜치와 else 브랜치에서 다른 변수명 패턴을 발견하고, git blame 확인 없이 "버그"로 단정하여 수정한다. → Intent-Before-Fix Gate (Critical Rules): git blame → git show → 커밋 전체 확인 후 의도적 설계 여부를 판단한 뒤 수정 여부를 결정한다.

### G-WF-007: 단일 레이어 함수 분석으로 최종 동작 단정
cpccpm.Throttle()이 ThrottleBy=100을 반환하는 것만 보고 "이 함수는 100을 반환한다"고 결론낸 사례처럼, 한 레이어의 반환값만 보고 시스템 전체 동작을 단정한다. → "이 함수가 X를 반환한다"고 주장하려면: (1) 해당 함수의 반환값을 직접 확인, (2) 그 함수를 호출하는 caller 코드를 grep으로 찾아 반환값이 어떻게 가공되는지 확인, (3) 최종 사용처(로그 출력, API 응답 등)까지 추적. 한 레이어만 읽고 결론 내는 것은 "검증했다"에 해당하지 않는다.

### G-WF-008: 가설 고착 — 동일 방향 3회 실패 후 가설 리셋 없이 재시도
첫 가설이 틀렸음을 시사하는 신호(동일 에러 반복, STALL 감지)에도 불구하고 같은 방향으로 계속 재시도한다. grind의 10회 재시도 환경에서 "열심히 했지만 결국 같은 방법을 10번 시도한 것"이 되는 사례. → 동일 전략으로 3회 연속 실패 시: "현재 접근의 근본 가정이 무엇인가?"를 명시적으로 자문하고, 대안 가설을 최소 2개 도출한다. grind에서는 grind-cross-cutting.md의 Hypothesis Reset Protocol을 따른다.

## Red Flags (워크플로 미준수 징후)

이 징후가 보이면 워크플로가 올바르게 실행되고 있지 않다. 즉시 멈추고 원인을 파악한다:

- workflow-state.json 갱신 없이 3개 이상의 Step을 진행함
- Plan에 없는 파일을 조용히 수정하고 있음
- "나중에 테스트 작성하겠다"고 기록함
- 100줄 이상 코드를 작성했는데 빌드/테스트를 실행하지 않음
- Step 6 Purpose Alignment을 "명백히 통과"로 건너뜀
- 전문가 리뷰에서 CRITICAL을 보고도 다음 Step으로 진행함
- 검증 단계를 건너뛰려 하지만 변경 범위가 작지 않음
- 스펙과 기존 코드가 충돌하는데 Confusion Management 없이 임의 해석으로 진행함
