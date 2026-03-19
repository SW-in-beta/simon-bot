# Boost Expert Panel (6인 전문가 패널)

simon-bot-boost, simon-bot-auto-boost, simon-bot-boost-review에서 공유하는 전문가 패널 구성.

## Expert 1: Workflow Architect (워크플로 설계 전문가)

관점: 작업 흐름의 구조적 완성도

분석 항목:
- 단계(Step)의 추가/제거/병합/순서 변경 가능성
- 병렬 실행 최적화 기회
- 불필요한 병목이나 중복 단계 식별
- 새로운 검증 게이트나 체크포인트 도입 가능성
- Phase 간 전환 로직 개선

## Expert 2: Prompt Engineer (프롬프트 엔지니어링 전문가)

관점: 에이전트 지시문의 명확성과 효과

분석 항목:
- 에이전트 역할 정의의 구체성과 명확성
- 지시문의 모호한 부분이나 해석 여지가 큰 부분
- Few-shot 예제 추가가 도움될 부분
- 에이전트 간 커뮤니케이션 프로토콜 개선
- Chain-of-thought, structured output 등 프롬프트 기법 활용 기회

## Expert 3: Innovation Scout (기술 혁신 탐색가)

관점: 새로운 도구, 기법, 방법론의 도입 가능성

분석 항목:
- 자료에서 발견한 새로운 패턴이나 기법 중 도입 가능한 것
- 기존에 없는 검증 방법, 분석 도구, 자동화 기회
- 다른 AI 에이전트 프레임워크의 모범 사례 벤치마킹
- MCP 도구 활용 확장 기회
- 최신 LLM 기능 (extended thinking, agent teams 등) 활용 기회

## Expert 4: Quality & Safety Guardian (품질·안전 전문가)

관점: 에러 처리, 안전장치, 품질 보증의 견고함

분석 항목:
- 에러 복구 전략의 빈틈
- 안전장치(forbidden rules, validation)의 누락
- 롤백/복구 메커니즘 개선
- 컨텍스트 윈도우 관리 전략 개선
- 메모리/상태 관리의 데이터 무결성

## Expert 5: Developer Experience (DX) Specialist (개발자 경험 전문가)

관점: 스킬 사용자(= 개발자)의 경험 품질

분석 항목:
- 사용자 인터랙션 흐름의 자연스러움
- 불필요하게 많은 질문이나 확인 요청
- 진행 상황 보고의 명확성
- 세션 관리/복원의 편의성
- 스킬 간 전환(PM->bot, bot->grind 등)의 매끄러움

## Expert 6: Skill Craft Specialist (스킬 설계 전문가)

관점: 스킬 파일 자체의 구조적 품질 — 기능이 아무리 좋아도 스킬로서의 형식이 나쁘면 제대로 트리거되지 않거나, 컨텍스트를 낭비하거나, 후반 단계가 실행되지 않는다.

> **Reference Loading**: 분석 전 `~/.claude/skills/simon-bot-boost/references/skill-best-practices.md` 읽기

분석 항목:
- **Progressive Disclosure**: SKILL.md가 500줄 이내인지, 3단계 로딩(metadata -> body -> references)을 잘 활용하는지
- **Skill Decomposition**: 독립적인 sub-workflow가 하나의 스킬에 묶여 있지 않은지, 컨텍스트 소진으로 후반 단계가 실행되지 않는 징후가 있는지
- **Description 트리거링**: frontmatter description이 적절한 상황에서 트리거를 유도하는지, 과소/과다 트리거 위험이 있는지
- **Reference 구조**: 300줄 초과 reference에 TOC가 있는지, SKILL.md에서 reference로의 포인터가 명확한지
- **Writing Patterns**: 지시문이 명령형인지, Why가 설명되어 있는지, 적절한 예시가 포함되어 있는지
- **Frontmatter 유효성**: name, description, compatibility 등 메타데이터가 정확하고 완전한지

## Agent Team Shared Tasks (3단계 토론)

- **Task 1** (독립 분석): 각 전문가가 자료 + 현재 스킬을 교차 분석하여 개선점 도출
- **Task 2** (교차 토론): 다른 전문가의 발견을 읽고 보강/반박/우선순위 조정 토론
- **Task 3** (합의 도출): 최종 개선 제안 목록을 severity와 영향 범위 기준으로 정리

> **Agent Teams Fallback**: Agent Teams가 비활성 상태이면(`TeamCreate` 실패 시), 각 전문가를 개별 `Agent(subagent_type="general-purpose")` subagent로 spawn한다. 각 subagent에게 동일한 자료 요약과 대상 스킬 내용을 전달하고, findings를 공유 파일 경로(`.claude/boost/expert-findings/`)에 기록한 뒤, 오케스트레이터가 결과를 수집하여 교차 검증한다.
