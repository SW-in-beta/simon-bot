# Phase 0: Company Setup 분석

## 0-A: 프로젝트 유형 판별

**판별 결과: Greenfield (신규 프로젝트)**

- 사용자가 기존 프로젝트의 수정/확장이 아닌 새로운 시스템 구축을 요청
- "고객 데이터를 활용"할 새로운 서비스/도구를 만들려는 의도
- 기존 코드베이스에 대한 언급 없음

## 0-B: 팀 편성 (Dynamic Roster) - 잠정

> 의뢰 모드 인터뷰 전이므로 잠정 편성. 인터뷰 완료 후 확정.

### 잠정 팀 편성 (예상 기준)

| 팀 | 활성 여부 | 판단 근거 |
|----|----------|----------|
| **PM** | O (항상) | 요구사항 정의, 인터뷰 주도 |
| **CTO** | O (항상) | 기술 아키텍처 의사결정 |
| **Design** | O (잠정) | "직원들이 데이터를 쉽게 볼 수 있으면" = 대시보드 UI 필요, "고객 경험" = 고객용 UI 필요 |
| **Frontend** | O (잠정) | 대시보드 UI 구현 |
| **Backend** | O (잠정) | 데이터 처리 API, 비즈니스 로직 |
| **QA** | O (항상) | 테스트 계획, E2E |
| **DBA** | O (잠정) | 고객 데이터 스키마, 분석 쿼리 최적화 |
| **DevOps** | O (잠정) | 배포/인프라 (직원+고객 양쪽 서비스라면 필요) |
| **ML** | ? (미정) | 고객 맞춤 추천이 범위에 포함되면 활성화 |

[Decision] 팀 편성 잠정 -- 인터뷰 완료 전까지 확정 불가. "고객 추천"이 범위에 포함되면 ML팀 추가 활성화 예정.

## 0-C: 실행 모드

**선택: 의뢰 모드 (Discovery Interview Protocol)**

CEO가 사용자의 요청을 분석한 결과 의뢰 모드를 자동 감지하고 제안합니다.

### 의뢰 모드 자동 감지 트리거

다음 조건들이 충족됨:
1. "구체적으로 뭘 만들어야 할지는 잘 모르겠어요" -- 사용자 본인이 불확실성을 명시
2. "좀 더 잘 활용하고 싶어요" -- 추상적인 목표만 있음
3. "뭔가 더 좋은 경험" -- 구체적 기능이 아닌 방향성만 제시
4. 기능 목록, 화면 설계, 기술 요구사항 등 구체적 정보 부재

## 0-D: 초기 상태

> 의뢰 모드에서는 인터뷰 완료 후 roster.json과 state.json을 확정합니다.
> 현 시점에서는 Phase 0 진행 중 상태로 기록합니다.

### state.json (잠정)

```json
{
  "project": "customer-data-platform",
  "projectNameConfirmed": false,
  "phase": "0-C",
  "mode": "discovery",
  "modeAutoDetected": true,
  "modeAutoDetectReason": "사용자가 '구체적으로 뭘 만들어야 할지 모르겠다'고 명시. 추상적 목표만 존재.",
  "projectType": "greenfield",
  "rosterFinalized": false,
  "interviewStatus": "pending",
  "interviewStage": 0,
  "createdAt": "2026-03-07"
}
```

### roster.json (잠정)

```json
{
  "status": "tentative",
  "note": "의뢰 모드 인터뷰 완료 후 확정",
  "teams": {
    "PM": { "active": true, "reason": "항상 활성" },
    "CTO": { "active": true, "reason": "항상 활성" },
    "Design": { "active": true, "tentative": true, "reason": "대시보드/고객 UI 필요 예상" },
    "Frontend": { "active": true, "tentative": true, "reason": "대시보드/고객 UI 구현" },
    "Backend": { "active": true, "tentative": true, "reason": "데이터 API/비즈니스 로직" },
    "QA": { "active": true, "reason": "항상 활성" },
    "DBA": { "active": true, "tentative": true, "reason": "고객 데이터 스키마/분석 쿼리" },
    "DevOps": { "active": true, "tentative": true, "reason": "배포/모니터링" },
    "ML": { "active": null, "tentative": true, "reason": "추천 기능 포함 여부에 따라 결정" }
  }
}
```
