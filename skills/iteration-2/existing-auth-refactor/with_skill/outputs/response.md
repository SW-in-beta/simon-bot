# Simulated simon-bot-pm Response

## User Request (Original)

> "우리 회사 모노레포에서 인증 시스템을 전면 리팩토링하고 싶어. 현재 세션 기반인데 JWT로 바꾸고, OAuth2도 추가하고, 기존 API 호환성도 유지해야 해. 관련 서비스가 5개 정도 있어."

---

## Scope Guard Check

**판단 근거:**

| 기준 | 분석 | 결과 |
|------|------|------|
| 기능(Feature) 수 | JWT 전환, OAuth2 추가, API 호환성 레이어, 서비스별 마이그레이션(5개) 등 최소 4-5개 이상 | 3개 이상 -- PM 적용 |
| 예상 변경 파일 수 | 인증 코어 + 5개 서비스 + 미들웨어 + 테스트 = 최소 30개 이상 예상 | 15개 이상 -- PM 적용 |
| 기능 간 의존성 | JWT 코어 -> OAuth2 -> 서비스 마이그레이션 -> 호환성 레이어 (강한 의존 체인) | 있음 -- PM 적용 |
| PRD/작업 분해 필요 | 5개 서비스 조율, 호환성 전략 필요 | 필요 -- PM 적용 |

**결론: simon-bot-pm 적용이 적합합니다. 모든 기준 충족.**

---

## Phase 0: Project Setup

### Phase 0-A: 프로젝트 유형 AUTO-DETECT

> **[PM]** 프로젝트 유형을 자동 판별했습니다.
>
> **Existing Project** (기존 프로젝트 리팩토링)
> - 근거: "리팩토링", "현재 세션 기반인데 JWT로 바꾸고", "기존 API 호환성 유지", "관련 서비스가 5개"
> - 새로 만드는 것이 아니라, 기존 인증 시스템을 전환하는 작업입니다.
>
> 맞나요?

*[사용자가 "맞아"라고 응답한다고 가정]*

---

#### simon-bot-report 제안 (Existing Project 전용)

> **[PM]** 기존 프로젝트 리팩토링이니, 본격적인 인터뷰 전에 코드베이스를 먼저 분석하면 더 정확한 기획이 가능합니다.
>
> **simon-bot-report로 사전 분석 보고서를 먼저 작성할까요?**
>
> 분석 보고서에서는 다음을 파악합니다:
> - 현재 세션 기반 인증의 구조와 코드 위치
> - 5개 관련 서비스의 인증 의존 관계
> - 기존 API 엔드포인트 및 세션 사용 패턴
> - 리팩토링 시 영향받는 파일/모듈 규모
>
> 1. **예** - 사전 분석 후 인터뷰 진행 (추천)
> 2. **아니오** - 바로 인터뷰 시작

*[이 시뮬레이션에서는 사용자가 "아니오, 바로 진행하자"라고 응답한다고 가정하고 Phase 1로 진행]*

---

### Phase 0-B: 실행 모드 선택

> **[PM]** 각 기능 구현이 완료될 때마다 어떻게 진행할까요?
>
> 1. **자동 진행**: 완료 즉시 다음 작업으로 자동 진행 (중간 보고만)
> 2. **승인 후 진행**: 각 기능 완료 시 결과를 보고하고 승인 후 다음 작업 진행
>
> 인증 시스템은 보안에 민감하므로 단계별 확인을 원하시면 2번을 추천드립니다.

*[사용자가 "2번 승인 후 진행"이라고 응답한다고 가정]*

---

### Phase 0-C: 초기 상태 (저장될 내용)

```json
// .claude/pm/state.json
{
  "phase": 0,
  "project_type": "existing",
  "execution_mode": "approval",
  "created_at": "2026-03-05T...",
  "tasks_total": 0,
  "tasks_completed": 0
}
```

---

## Phase 1: PRD Creation (Interactive)

### Round 1: 비전 / 동기 확인 (2 questions)

> **[PM]** 인증 시스템 리팩토링을 체계적으로 진행하겠습니다. 몇 가지 질문으로 요구사항을 구체화하겠습니다.
>
> 첫 메시지에서 이미 많은 정보를 주셨네요. 정리하면:
> - 세션 기반 -> JWT 전환
> - OAuth2 추가
> - 기존 API 호환성 유지
> - 관련 서비스 5개
>
> 여기서 좀 더 구체화가 필요한 부분을 여쭤볼게요.
>
> **Q1.** 이 리팩토링의 핵심 동기가 무엇인가요? 예를 들어:
> - 마이크로서비스 간 인증 통합이 필요해서?
> - 모바일/SPA 클라이언트 지원을 위해?
> - 보안 강화 (세션 하이재킹 방지 등)?
> - 스케일링 이슈 (세션 스토어 부하)?
> - 또는 다른 이유?
>
> **Q2.** 관련 서비스 5개를 간략히 알려주실 수 있나요? (서비스 이름과 역할 정도면 충분합니다)

*[사용자 응답 예시]*
> "모바일 앱이 추가되면서 JWT가 필요하고, 외부 파트너 연동을 위해 OAuth2도 필요해. 서비스는 user-service, api-gateway, admin-service, notification-service, billing-service 이렇게 5개야."

---

### Round 2: 범위 / 호환성 (3 questions)

> **[PM]** 모바일 앱 지원과 외부 파트너 연동이 핵심 동기군요. 범위와 호환성에 대해 몇 가지 더 여쭤보겠습니다.
>
> **Q3.** 기존 API 호환성 유지 관련 -- 현재 세션 기반 API를 사용하는 클라이언트가 어떤 것들인가요? (웹 프론트엔드, 내부 서비스 간 호출 등) 호환성을 얼마나 오래 유지해야 하나요? (예: 전환 기간 3개월 후 세션 완전 제거, 또는 무기한 병행)
>
> **Q4.** OAuth2는 어떤 flow를 지원해야 하나요?
> - Authorization Code (외부 파트너용?)
> - Client Credentials (서비스 간 통신?)
> - PKCE (모바일 앱용?)
> - 또는 OAuth2 Provider로서 동작? Consumer로서 동작? 둘 다?
>
> **Q5.** 5개 서비스를 동시에 전환하나요, 아니면 단계적으로 (예: api-gateway 먼저 -> 나머지 순차)?

*[사용자 응답 예시]*
> "웹 프론트엔드가 세션을 쓰고 있어서 3개월 정도 병행 운영 필요해. OAuth2는 우리가 Provider 역할이고 Authorization Code + Client Credentials 두 개. 전환은 api-gateway를 먼저 하고 나머지를 순차적으로 하고 싶어."

---

### Round 3: 기술 요구사항 / 우선순위 (3 questions)

> **[PM]** 명확합니다. 기술적인 부분과 우선순위를 확인하겠습니다.
>
> **Q6.** JWT 관련 기술 결정:
> - Access Token + Refresh Token 패턴을 사용할 건가요?
> - 토큰 저장소는 어떻게 할 건가요? (Redis 블랙리스트? DB?)
> - 토큰 만료 시간에 대한 요구사항이 있나요?
>
> **Q7.** 현재 세션은 어디에 저장되어 있나요? (Redis, DB, 인메모리 등) 그리고 세션에 담겨있는 주요 데이터는 무엇인가요? (이건 코드를 보면 파악할 수 있을 수도 있지만, 혹시 특별히 알려주실 것이 있으면)
>
> **Q8.** 우선순위를 확인하고 싶습니다. 아래 기능들의 우선순위를 정해주실 수 있나요?
> - JWT 인증 코어 (토큰 발급/검증/갱신)
> - OAuth2 Provider (Authorization Code + Client Credentials)
> - 기존 세션 호환성 레이어 (병행 운영)
> - 서비스별 마이그레이션 (5개 서비스)
> - 보안 강화 (rate limiting, 토큰 revocation 등)

*[사용자 응답 예시]*
> "Access + Refresh Token 쓸 거고 Redis 블랙리스트. 세션은 지금 Redis에 저장. 우선순위는 JWT 코어 > 호환성 레이어 > 서비스 마이그레이션 > OAuth2 > 보안 강화 순이야."

---

### Round 4: 세부 확인 / 마무리 (2 questions)

> **[PM]** 거의 다 왔습니다. 마지막으로 두 가지만 확인하겠습니다.
>
> **Q9.** 테스트와 검증 관련 -- 현재 인증 관련 테스트가 있나요? (단위 테스트, 통합 테스트 등) 그리고 이번 리팩토링에서 특별히 검증하고 싶은 시나리오가 있나요? (예: 토큰 만료 후 자동 갱신, 동시 로그인 제한 등)
>
> **Q10.** 이 리팩토링의 범위에서 명시적으로 **제외**할 것이 있나요? 예를 들어:
> - SSO (Single Sign-On) 연동?
> - 소셜 로그인 (Google, Kakao 등)?
> - 2FA (이중 인증)?
> - 기존 사용자 비밀번호 마이그레이션?

*[사용자 응답 예시]*
> "테스트는 단위 테스트가 좀 있어. 동시 로그인 제한은 기존에도 있어서 JWT에서도 유지해야 해. 소셜 로그인이랑 2FA는 이번 범위 밖이야. SSO는 나중에 할 거라 구조만 확장 가능하게."

---

> **[PM]** 충분한 정보가 모였습니다. 이제 PRD를 작성하겠습니다.

*(여기서 `planner` 에이전트에게 인터뷰 내용 전체를 전달하여 PRD를 생성합니다)*

---

### Phase 1-B: PRD 생성 결과

> **[PM]** PRD를 작성했습니다. 리뷰해주세요.

```markdown
# PRD: 인증 시스템 리팩토링 (Session -> JWT + OAuth2)

## 1. Overview
- **비전**: 모노레포 인증 시스템을 세션 기반에서 JWT 기반으로 전환하고 OAuth2 Provider 기능을 추가하여, 모바일 앱과 외부 파트너 연동을 지원한다.
- **배경과 동기**: 모바일 앱 출시에 따라 stateless 인증(JWT)이 필요하고, 외부 파트너 API 연동을 위해 표준 OAuth2 Provider 역할이 요구됨. 기존 웹 프론트엔드의 세션 기반 인증은 3개월 병행 운영 후 단계적 제거.
- **대상 사용자**: 웹 프론트엔드 사용자, 모바일 앱 사용자, 외부 파트너 개발자, 내부 서비스(5개)

## 2. Goals & Non-Goals

### Goals
- 세션 기반 인증을 JWT(Access + Refresh Token) 기반으로 전환
- OAuth2 Provider 구현 (Authorization Code, Client Credentials flow)
- 기존 세션 API와 3개월간 병행 운영 가능한 호환성 레이어 제공
- 5개 서비스(user-service, api-gateway, admin-service, notification-service, billing-service) 순차 마이그레이션
- 기존 동시 로그인 제한 기능 JWT 환경에서도 유지
- SSO 확장 가능한 아키텍처 설계

### Non-Goals
- 소셜 로그인 (Google, Kakao 등) 연동
- 2FA (이중 인증) 구현
- 기존 사용자 비밀번호 마이그레이션/정책 변경
- SSO 실제 구현 (구조만 확장 가능하게)

## 3. User Stories
- **웹 사용자**: 기존과 동일하게 로그인/로그아웃하며, 전환 기간 동안 서비스 중단 없이 이용한다.
- **모바일 사용자**: JWT로 인증하고, 토큰 만료 시 자동 갱신되어 끊김 없이 이용한다.
- **외부 파트너**: OAuth2 Authorization Code flow로 사용자 인증을 연동하거나, Client Credentials로 서비스 간 API를 호출한다.
- **내부 서비스**: JWT 토큰을 검증하여 요청을 처리하며, 서비스 간 호출 시 Client Credentials 토큰을 사용한다.
- **관리자**: admin-service에서 토큰 revocation, 클라이언트 관리 등을 수행한다.

## 4. Feature Inventory

### Must-have
| ID | 기능 | 설명 | 우선순위 |
|----|------|------|----------|
| F1 | JWT 인증 코어 | 토큰 발급/검증/갱신, Access+Refresh Token, Redis 블랙리스트 | P0 |
| F2 | 세션-JWT 호환성 레이어 | 기존 세션 API 유지하면서 JWT 병행, 3개월 병행 운영 | P0 |
| F3 | api-gateway 마이그레이션 | 첫 번째 서비스 전환, JWT 미들웨어 적용 | P1 |
| F4 | 나머지 서비스 마이그레이션 | user-service, admin-service, notification-service, billing-service | P1 |
| F5 | OAuth2 Provider | Authorization Code + Client Credentials flow, 클라이언트 등록/관리 | P2 |

### Nice-to-have
| ID | 기능 | 설명 | 우선순위 |
|----|------|------|----------|
| F6 | 보안 강화 | Rate limiting, 고급 토큰 revocation, 감사 로그 | P3 |

## 5. Technical Requirements
- **기술 스택**: 기존 모노레포 스택 유지 (코드베이스 탐색으로 확인 필요)
- **JWT**: Access Token + Refresh Token 패턴, RS256 or HS256 서명
- **토큰 저장소**: Redis (블랙리스트 방식 -- revoked 토큰만 저장)
- **세션 저장소**: 기존 Redis (호환성 기간 동안 유지)
- **OAuth2**: RFC 6749 준수, Authorization Code flow + Client Credentials flow
- **동시 로그인 제한**: Redis 기반 active token 추적으로 기존 기능 유지
- **아키텍처**: SSO 확장을 고려한 인증 모듈 분리 설계

## 6. Constraints & Assumptions
- **제약**: 기존 API 스펙 변경 불가 (호환성 기간 중), 5개 서비스 동시 중단 불가 (순차 마이그레이션)
- **가정**: Redis 인프라는 이미 존재, 기존 단위 테스트 일부 존재, api-gateway가 인증의 첫 진입점

## 7. Success Criteria
- [ ] JWT 토큰 발급/검증/갱신이 정상 동작
- [ ] 기존 세션 기반 API가 호환성 레이어를 통해 그대로 동작
- [ ] api-gateway에서 JWT 인증 미들웨어가 정상 동작
- [ ] 나머지 4개 서비스가 JWT 기반으로 전환 완료
- [ ] OAuth2 Authorization Code + Client Credentials flow 동작
- [ ] 동시 로그인 제한이 JWT 환경에서도 유지
- [ ] 전체 빌드 성공, 기존 테스트 + 신규 테스트 모두 통과
- [ ] 보안 리뷰 통과 (CRITICAL 이슈 0건)
```

---

### Phase 1-C: PRD 리뷰

> **[PM]** 위 PRD를 확인해주세요.
>
> 1. **승인** -- 이대로 진행
> 2. **수정 요청** -- 특정 섹션 수정이 필요
> 3. **추가 논의** -- 더 논의하고 싶은 주제가 있음
>
> 수정할 부분이 있으면 말씀해주세요.

---

## Summary: Phase 0 ~ Phase 1 Flow Recap

```
사용자 요청 수신
    |
    v
[Scope Guard] -- 4/4 기준 충족 --> simon-bot-pm 적용
    |
    v
[Phase 0-A] AUTO-DETECT: "existing" (리팩토링, 기존 코드, 전환 키워드)
    |         --> 사용자에게 확인만 받음 (별도 질문 안 함)
    |
    v
[Phase 0-A] simon-bot-report 제안 (existing project 전용)
    |         --> 사용자가 "아니오" 선택
    |
    v
[Phase 0-B] 실행 모드 선택
    |         --> 사용자가 "승인 후 진행" 선택
    |
    v
[Phase 0-C] state.json 초기화
    |
    v
[Phase 1-A] 인터뷰 (4 rounds, 10 questions)
    |         Round 1: 비전/동기 (Q1-Q2)
    |         Round 2: 범위/호환성 (Q3-Q5)
    |         Round 3: 기술/우선순위 (Q6-Q8)
    |         Round 4: 세부/마무리 (Q9-Q10)
    |
    v
[Phase 1-B] PRD 생성 (planner agent)
    |
    v
[Phase 1-C] PRD 리뷰 --> 승인 시 Phase 2로 진행
```

### Key Observations (시뮬레이션 분석)

**Scope Guard:**
- 4개 기준 모두 충족하여 PM 워크플로가 정당화됨
- 리다이렉트 판단 없이 바로 진행

**Phase 0-A (AUTO-DETECT):**
- "리팩토링", "현재~바꾸고", "기존 API" 등의 키워드로 "existing" 자동 판별
- 사용자에게 질문하지 않고 판별 결과만 제시 + 확인 요청 (스킬 지시 준수)

**simon-bot-report 제안:**
- Existing project이므로 사전 분석 보고서를 제안함 (스킬 지시 준수)
- 사용자가 거절하면 Phase 1로 바로 진행

**Phase 0-B (실행 모드):**
- 보안 민감 프로젝트이므로 "승인 후 진행" 추천을 함께 제시

**Phase 1 인터뷰 (Interview Guard 준수):**
- **4 rounds, 10 questions** -- 스킬의 "Existing: 3-4 라운드, 8-12개 질문" 가이드 범위 내
- Round 1 (2Q): 사용자가 이미 말한 내용을 정리하고, 아직 모르는 동기와 서비스 구성만 질문
- Round 2 (3Q): 호환성 기간, OAuth2 flow 상세, 마이그레이션 전략 (비즈니스 결정 중심)
- Round 3 (3Q): JWT 기술 결정, 현재 세션 구조, 우선순위 확인
- Round 4 (2Q): 테스트/검증, Out of scope 확인으로 마무리
- **이미 답한 내용을 다시 묻지 않음** (Interview Guard)
- **비즈니스 결정과 우선순위에 집중** (Interview Guard)
- 한 번에 2-3개 질문씩 (스킬 지시 준수)

**PRD:**
- 인터뷰 내용을 빠짐없이 반영
- Must-have 5개 Feature + Nice-to-have 1개
- Non-Goals 명시 (소셜 로그인, 2FA, SSO 실제 구현)
- 우선순위가 사용자 지정 순서와 일치
