# Cognitive Independence (인지적 독립성)

검증 에이전트가 진정한 독립성을 유지하기 위한 프로토콜. 구조적 분리(별도 subagent)만으로는 부족하다 — 인지적 독립이 필요하다.

> **참조**: 이 프로토콜은 simon/SKILL.md의 Cross-Cutting Protocol이며, Phase B-E의 검증 단계(Step 6, 7, 17)와 simon-grind의 Escalation Ladder, simon-code-review의 CONNECTED 모드에서 적용된다.

## Monte Carlo Verification Principle

독립 검증의 이론적 기반. 통계학의 Monte Carlo 방법에서 착안한 원리로, 아래 4대 핵심 원칙이 **왜** 독립 Sub-agent를 요구하는지를 설명한다:

- **원리**: N개의 독립 시행이 동일 결론에 수렴하면, 그 결론의 신뢰도는 개별 시행보다 높다. 독립 시행의 수렴이 핵심이다.
- **적용 조건**: 각 시행이 진정으로 독립적이어야 한다 — 앞선 시행의 결론이 다음 시행에 영향을 주면 "독립"이 아니므로 수렴의 의미가 퇴색된다.
- **워크플로 내 구현**:
  - Blind-First Protocol = 독립 시행을 보장하는 메커니즘 (이전 결론을 차단)
  - Fresh Subagent = 진정한 독립 컨텍스트를 제공하는 구조적 장치
  - Verification Layer = 2회 독립 시행 + 수렴 확인. `[INDEPENDENT-CONFIRM]` = 수렴 신호
  - Devil's Advocate = 추가 독립 시행 (false negative 탐지 목적)
- **Agent Teams를 검증에 사용하지 않는 이유**: Agent Team의 SendMessage를 통한 의견 교환은 시행 간 독립성을 파괴한다. 한 팀원의 초기 의견이 다른 팀원의 분석을 오염시켜 확증 편향(confirmation bias)의 경로가 된다. 에이전트 유형 선택은 `agent-teams.md`의 Agent Selection Framework을 참조한다.

이 원리가 적용되지 않는 경우:
- 결정론적 검증 (빌드, 테스트) — 코드 실행 1회로 확정 가능하므로 독립 시행 불필요
- 토론/합의 도출 — 독립성보다 상호 참조가 더 가치 있는 경우 (Agent Teams 사용)

## 핵심 원칙

### 1. Blind-First (독립 분석 우선)

검증자에게 이전 findings/결론을 먼저 보여주지 않는다. 코드/산출물을 독립적으로 분석한 후, 이전 findings와 대조하는 2-phase 프로세스를 따른다.

**적용 패턴:**
- Phase 1 (Blind): 코드/diff만 전달. "이 코드에서 이슈를 독립적으로 찾으라."
- Phase 2 (Cross-check): 이전 findings 공개 + 대조. 일치하면 `[INDEPENDENT-CONFIRM]`, 불일치하면 `[DISPUTED]`.

**적용 대상:**
- Step 7 Verification Layer (P-003) — verifier가 finding 확인 시
- Step 7-A impl-review — 도메인팀이 expert-plan-concerns와 대조 시
- simon-code-review CONNECTED 모드 — review-sequence.md 읽기 전 diff 분석

**적용 제외:**
- 결정론적 검증 (빌드, 테스트 실행) — 코드 실행으로 확인 가능한 것은 인간 판단이 아니므로 Blind-First 불필요

### 2. Adversarial Default (반증 탐색 기본 태도)

검증자의 기본 태도는 "이것이 틀렸을 가능성을 적극 탐색"이다. "맞는지 확인해"가 아니라 "틀린 이유를 찾아라"로 프레이밍한다.

**프롬프트 패턴:**
> "이 finding/구현이 잘못되었을 가능성을 적극적으로 탐색하세요. 확인이 아닌 반증이 당신의 임무입니다."

**적용 대상:**
- Step 7 Verification Layer — verifier 프롬프트
- Step 17 Production Readiness — auditor 프롬프트
- Devil's Advocate agent (Step 7 이후)

### 3. Fresh Subagent (구현 과정 미목격 에이전트)

검증이 필요한 시점에서 구현 과정을 목격하지 않은 새 에이전트를 사용한다. 같은 모델이라도 별도 컨텍스트 윈도우에서 시작하면 다른 관점을 가진다.

**적용 대상:**
- Step 6 Purpose Alignment — plan-summary.md + git diff만 받는 alignment-checker
- Step 17 Production Readiness — plan-summary.md + 최종 diff + verify-commands.md만 받는 auditor
- simon-grind Escalation Ladder — Attempt 4+에서 새 executor, Attempt 7+에서 새 architect+executor

**Fresh Agent에게 전달하는 것:**
- 결과물: 코드 diff, plan-summary.md, 테스트 결과, 에러 메시지
- 사실: 파일 구조, 의존성 관계, 빌드 결과

**Fresh Agent에게 전달하지 않는 것:**
- 추론 과정: "왜 이렇게 구현했는지", "어떤 대안을 검토했는지"
- 이전 에이전트의 판단: findings, severity 평가, 우선순위

### 4. What-not-Why Handoff (결과 전달, 추론 차단)

에이전트 간 핸드오프 시 결과(What)는 전달하되 추론 과정(Why)은 차단한다. 이전 에이전트의 사고 패턴이 새 에이전트를 오염시키지 않도록 한다.

**전달 O (What):**
- 에러 메시지, 실패한 테스트 목록, 빌드 로그
- git diff, 변경된 파일 목록
- plan-summary.md, 요구사항

**차단 X (Why):**
- "이 접근법이 실패한 이유는 ~라고 판단했다"
- "~를 시도했지만 ~때문에 안 됐다"
- inline-issues.md의 추론 부분 (재현 조건은 전달, 해석은 차단)

**적용 대상:**
- simon-grind: Escalation Ladder에서 fresh context spawn 시
- Step 7 → Step 7 Devil's Advocate 전달 시
- Step 18 → Step 19 (simon-code-review) 전달 시 (Blind-First와 결합)

### Contrastive 적용 제한 (CP-007)

Contrastive Prompting(정답/오답 동시 생성) 기법을 Fresh Subagent에 적용할 때 다음 제약을 준수한다. "잘못된 구현 예시"가 이전 에이전트의 실패한 시도를 노출하면 What-not-Why Handoff를 직접 위반하여 인지적 독립성이 파괴되기 때문이다.

**허용**: 현재 구현과 무관한 범용 예시 — 공식 문서, 업계 표준, 프레임워크 best practices에서 인용된 정답/안티패턴 쌍
**금지**: 현재 구현의 이전 실패 시도를 "잘못된 예시"로 사용하는 것 — 이전 실패 패턴이 Fresh Subagent의 추론을 오염시킬 수 있다

**검증 불가 영역 제한**: 코드로 직접 확인 불가능한 영역(외부 서비스 동작, 운영 환경 의존 부분)에서 AI가 생성한 "틀릴 수 있는 이유"는 검증 수단이 없으므로 채택하지 않는다. `[외부 의존성 — 확인 불가]` 태그를 사용하고 contrastive 검증을 건너뛴다.

## 비용 가이드라인

Cognitive Independence 적용은 추가 토큰을 소비한다. 다음 기준으로 비용을 통제한다:

| 상황 | 적용 수준 | 에이전트 유형 |
|------|----------|-------------|
| CRITICAL/HIGH finding 검증 | Full (Blind-First + Adversarial + Fresh) | Sub-agent (Monte Carlo) |
| 주요 게이트 (Step 6, 7, 17) | Full | Sub-agent (Monte Carlo) |
| 도메인 전문가 토론 (Step 1-A, 4-B, 7-A Phase 2) | N/A (토론은 Cognitive Independence 미적용) | Agent Team (Six Hats) |
| 결정론적 검증 (빌드, 테스트) | 미적용 | 직접 (subagent 없음) |
| MEDIUM finding | 미적용 (Verification Layer에서도 CRITICAL/HIGH만) | 직접 (subagent 없음) |

## Step × 원칙 적용 매트릭스

어떤 Step에서 어떤 원칙이 적용되는지 빠르게 참조하기 위한 매트릭스:

| Step/상황 | Blind-First | Adversarial Default | Fresh Subagent | What-not-Why |
|-----------|:-----------:|:-------------------:|:--------------:|:------------:|
| Step 5 Test-Spec Gate | - | - | ✓ | ✓ |
| Step 6 Purpose Alignment | - | - | ✓ | ✓ |
| Step 7 Verification Layer | ✓ | ✓ | ✓ | - |
| Step 7 Devil's Advocate | - | ✓ | ✓ | ✓ |
| Step 17 Production Readiness | - | ✓ | ✓ | ✓ |
| Grind Escalation (Attempt 4+) | - | - | ✓ | ✓ |
| Grind Escalation (Attempt 7+) | - | - | ✓ | ✓ |
| simon-code-review CONNECTED | ✓ | - | - | - |
| 결정론적 검증 (빌드/테스트) | - | - | - | - |
