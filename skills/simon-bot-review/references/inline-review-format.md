# Inline Review Comment Format

인라인 코드 리뷰 코멘트 양식. CONNECTED/STANDALONE 양 모드에서 공통으로 사용한다.

## 최초 리뷰 (Step 2)

각 변경 단위의 대표 파일 1-2개에 아래 양식으로 인라인 코멘트를 작성한다. 나머지 파일은 간단한 역할 설명만 추가한다.

### CONNECTED 모드 양식

```markdown
**[R{cycle}] [변경 단위 N: {제목}]**

**계획 매핑**: {plan-summary의 어떤 Unit/목표를 구현한 것인지 — "이 변경은 계획의 [Unit N: 제목]을 구현합니다"}
**변경 전 상태**: {구체적 코드 동작 수준으로 — 어떤 분기를 타고, 어떤 메서드가 호출되며, 기존 한계가 무엇인지. 신규 생성이면 "신규 생성"}
**변경 내용**: {구체적으로 어떤 부분을 어떻게 개선/추가했는지. 기존 코드베이스의 유사 패턴이 있으면 비교하며 설명}
**관련 변경 단위**: {이전/이후 변경 단위와의 의존/호출/데이터 흐름 관계}
**리뷰 포인트**:
1. {구체적 기술 포인트 — 코드 수준 근거 포함. 예: "elif 체인 순서: SubsetProductFeed → HNS TV(50) → ELEVENTH → default. 우선순위 충돌 없음"}
2. {미수정 사유 — 변경하지 않은 관련 코드가 있으면 왜 안 바꿨는지. 예: "_list_active_products 미수정: get_feed_id_or_parent_feed_id()가 이미 매핑하므로 추가 수정 불필요"}
3. {유사 패턴 비교 — **기존 패턴 스캔**으로 발견한 코드베이스 내 기존 구현/유틸리티/커스텀 필드와의 비교. 기존 대안을 사용하지 않은 경우 그 이유를 명시. 예: "프로젝트에 `common/custom_fields.py`의 `EnumField`가 있으며 `BrandProduct` 모델에서 이미 사용 중 — 새 필드도 EnumField 사용이 적합"}
**전문가 우려사항**: {Step 4-B/7에서 제기된 우려 + 반영 내용. 수용하지 않은 경우 그 이유. 전문가 토론 맥락이 있으면 발췌}
**트레이드오프**: {한계 명시 + 선택 이유, 기존 패턴과의 일관성 근거, 고려한 대안. 예: "서브피드 추가 시 수동 등록 필요 — 기존 패턴(HNS TV, Oliveyoung)과 일관된 접근"}
```

### STANDALONE 모드 양식

`계획 매핑` 대신 `변경 동기`를 사용한다:

```markdown
**[R{cycle}] [변경 단위 N: {제목}]**

**변경 동기**: {왜 이 변경이 필요한지 — 해결하려는 문제, 추가하려는 기능}
**변경 전 상태**: {위와 동일}
**변경 내용**: {위와 동일}
**관련 변경 단위**: {위와 동일}
**리뷰 포인트**:
1. {위와 동일}
2. {위와 동일}
3. {위와 동일}
**전문가 우려사항**: {Step 0에서 architect/writer가 도출한 우려사항 + 반영 내용}
**트레이드오프**: {위와 동일}
```

## 영향 분석 리뷰 (Impact Analysis)

변경되지 않았지만 변경으로 인해 영향받을 수 있는 코드에 대한 인라인 코멘트 양식. 변경 코드 리뷰와 동일한 PR에 포함된다.

### 양식

```markdown
**[R{cycle}] [영향 분석: {영향받는 함수/클래스명}]**

**관련 변경 단위**: {어떤 변경 단위의 어떤 변경이 이 코드에 영향을 미치는지}
**영향받는 이유**: {호출 관계, 데이터 흐름, 공유 상태, 인터페이스 계약 등 구체적 근거}
**현재 동작**: {이 코드가 현재 어떻게 동작하는지 — 변경 전 기준}
**잠재적 영향**: {변경 후 이 코드의 동작이 어떻게 달라질 수 있는지 구체적으로}
**필요 조치**: {확인만 필요 / 수정 필요 / 테스트 추가 필요 / 모니터링 필요}
**리뷰 포인트**:
1. {구체적 기술 포인트 — 코드 수준 근거 포함}
2. {추가 포인트가 있으면}
```

### 예시

```json
{
  "path": "src/service/notification_service.py",
  "line": 35,
  "body": "**[R1] [영향 분석: NotificationService.send_alert()]**\n\n**관련 변경 단위**: 변경 단위 1 — UserStatus 열거형에 `SUSPENDED` 상태 추가\n**영향받는 이유**: `send_alert()`가 `user.status`를 switch/match로 분기하며, 새 상태값(`SUSPENDED`)에 대한 분기가 없음\n**현재 동작**: `UserStatus`의 모든 값에 대해 알림 메시지를 생성하고, `default` 분기에서 일반 메시지를 전송\n**잠재적 영향**: `SUSPENDED` 사용자에게 일반 알림이 전송될 수 있음. 정지된 사용자에게 알림을 보내는 것이 의도된 동작인지 확인 필요\n**필요 조치**: 확인 필요 — SUSPENDED 사용자에게 알림 전송 여부는 비즈니스 결정\n**리뷰 포인트**:\n1. `default` 분기가 안전한 fallback인지 확인 — 현재는 일반 메시지 전송이므로 오동작은 아니지만, 의도하지 않은 알림이 발송될 수 있음\n2. 유사한 status 분기가 `email_service.py:28`에도 존재 — 동일한 영향 가능성"
}
```

### 코멘트 대상 선별 기준

- **포함**: 변경으로 인해 동작 변화가 발생할 수 있는 코드 (분기 누락, 타입 불일치, 계약 변경 등)
- **제외**: 단순 호출 관계만 있고 동작 변화 가능성이 없는 코드, 테스트 파일, 자동 생성 파일

## 테스트 파일 리뷰

> **필수 양식**: 테스트 파일은 보조 파일이라도 반드시 아래 양식을 사용한다. 자유 형식 코멘트는 금지.

리뷰어가 테스트 코드를 열지 않고도 커버리지 충분성을 판단할 수 있어야 한다. review-sequence.md의 "테스트 커버리지 요약" 또는 테스트 코드 직접 분석을 기반으로 작성한다.

```markdown
**[R{cycle}] [변경 단위 N: 테스트]**

**검증 범위**:
- Happy Path: {시나리오 1줄 설명}
- Edge Case: {시나리오 1줄 설명}
- Error Case: {시나리오 1줄 설명}

**의도적 미검증**: {제외한 시나리오 + 사유 — 없으면 생략}
**검증 패턴**: {Mock 대상 등 코드만으로 파악하기 어려운 정보 — 없으면 생략}
```

빈 카테고리는 생략한다. 시나리오당 1줄. 테스트 9개 이상이면 카테고리별 개수 요약 + 주요 시나리오만 기술한다.
assertion 상세 기술, Mock 설정값 나열, 입출력 데이터 반복은 과잉이므로 피한다.

## 피드백 반영 리뷰 (Step 4-C)

수정된 변경 단위에 대해서만 작성한다. 기존 코멘트는 resolve 처리하고, 수정된 코드 위치에 아래 양식으로 새 코멘트를 작성한다.

```markdown
**[R{cycle}] [변경 단위 N: {제목}] — 수정 반영**

**피드백 요약**: {사용자가 요청한 내용 — PR 코멘트 원문 인용}
**변경 전**: {기존 코드 발췌 또는 동작 설명}
**변경 후**: {수정된 코드 발췌 또는 동작 설명}
**영향 범위**: {이 수정이 다른 변경 단위에 미치는 영향. 없으면 "영향 없음"}
```

## review-payload.json 구성 가이드

### Line 번호 매핑

GitHub PR Review API의 `line`은 **diff가 아닌 파일의 실제 라인 번호**를 사용한다.

- **추가된 라인** (`+`): `side: "RIGHT"` (기본값, 생략 가능). diff의 `+` 라인에서 실제 파일 라인 번호를 추출한다.
- **삭제된 라인** (`-`): `side: "LEFT"` (**필수**). diff의 `-` 라인에서 삭제 전 파일의 라인 번호를 추출한다. **파일 전체가 삭제된 경우에도 `side: "LEFT"`로 코멘트를 달 수 있다** — "삭제된 파일이라 코멘트 불가"라고 판단하면 안 된다.

변경 단위의 핵심 변경이 시작되는 라인 (주로 함수/메서드 시그니처 또는 핵심 로직의 첫 줄)을 코멘트 위치로 선택한다. **삭제된 코드도 리뷰 대상이다** — 코드 제거, 모듈 삭제, 로직 변경으로 인한 라인 삭제 등에 대해 삭제 사유, 잔존 참조 확인, 영향 분석 등의 리뷰 포인트가 있으면 반드시 `side: "LEFT"`로 인라인 코멘트를 작성한다.

### 코멘트 크기

- 대표 파일 코멘트: 충분한 맥락을 담되, 마크다운으로 읽기 좋게 구조화
- 보조 파일 코멘트: 1-2줄 역할 설명 ("이 테스트는 변경 단위 1의 새 분기를 검증합니다")
- **테스트 파일 코멘트**: 위의 "## 테스트 파일 리뷰" 섹션의 필수 양식을 따른다.

### 예시

```json
{
  "body": "",
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/domain/service/best_product.py",
      "line": 72,
      "body": "**[R1] [변경 단위 1: ELEVENTH 서브피드 best products 선택 전략 분기 추가]**\n\n**계획 매핑**: Unit 1 — ELEVENTH 서브피드 지원\n**변경 전 상태**:\nELEVENTH 서브피드(1019, 1052, 1053, 1055, 1056)는 `else` 분기를 타며 `get_top_purchased_product_codes(product_feed_id, count)`가 호출됩니다. 서브피드 자체의 event_source가 없어 빈 결과를 반환하는 문제가 있었습니다.\n\n**변경 내용**:\nHNS TV(feed_id=50) 패턴과 동일한 구조로 `elif` 분기를 추가했습니다.\n- 부모 피드 ID(`ELEVENTH_FEED_ID=28`)의 event_source에서 구매 데이터를 조회\n- `ELEVENTH_FEED_PRODUCT_MAPPING[product_feed_id]`로 해당 서브피드의 상품 코드만 필터링\n\n**리뷰 포인트**:\n1. **elif 체인 순서**: SubsetProductFeed → HNS TV(50) → Oliveyoung → ELEVENTH → default 순서. ELEVENTH 서브피드는 SubsetProductFeed가 아니므로 우선순위 충돌 없음\n2. **`_list_active_products` 미수정**: `ProductService.list_products()` 내부에서 `get_feed_id_or_parent_feed_id()`가 이미 ELEVENTH 서브피드를 부모 피드(28)로 매핑하므로 추가 수정 불필요\n3. **HNS TV 패턴과의 차이**: HNS TV는 하드코딩된 parent_id=1을 사용하지만, ELEVENTH는 상수 `ELEVENTH_FEED_ID`를 사용하여 더 명확함\n\n**전문가 우려사항**: 서브피드 추가 시 매핑 누락 가능성 — 현재는 코드 리뷰로 방지, 장기적으로 subset_feed 방식 전환 예정\n**트레이드오프**: 서브피드 추가 시 `ELEVENTH_FEED_PRODUCT_MAPPING`에 수동 등록 필요 — 기존 패턴(HNS TV, Oliveyoung)과 일관된 접근"
    },
    {
      "path": "tests/integration/test_update_best_products.py",
      "line": 84,
      "body": "**[R1] [변경 단위 2: 통합 테스트]**\n\n**검증 범위**:\n- Happy Path: `test_update_best_products_eleventh_subfeed` — ELEVENTH 서브피드(1019)에서 부모 피드(28)의 event_source로 best products 정상 조회\n- Edge Case: `test_update_best_products_eleventh_empty_mapping` — 매핑에 없는 서브피드 ID 입력 시 빈 결과 반환\n- Error Case: `test_update_best_products_eleventh_no_event_source` — 부모 피드에 event_source 없을 때 graceful fallback\n\n**의도적 미검증**: SubsetProductFeed 경로는 기존 테스트에서 커버 (test_subset_product_feed.py:42)\n**검증 패턴**: `get_top_purchased_product_codes`를 Mock하여 서브피드 필터링 로직만 격리 검증"
    },
    {
      "path": "src/legacy/old_handler.py",
      "line": 10,
      "side": "LEFT",
      "body": "**[R1] [변경 단위 3: 레거시 핸들러 제거]**\n\n**변경 동기**: 신규 핸들러로 대체되어 더 이상 사용되지 않음\n**변경 전 상태**: OldHandler가 /api/v1 경로를 처리\n**변경 내용**: 파일 전체 삭제. 호출부는 변경 단위 1에서 NewHandler로 교체\n**관련 변경 단위**: 변경 단위 1(NewHandler 추가)에 의존\n**리뷰 포인트**:\n1. 이 파일을 import하는 코드가 남아있지 않은지 확인 완료 — Grep으로 `old_handler` 참조 0건\n2. 삭제된 코드에 포함된 에러 핸들링 로직이 신규 핸들러에도 동일하게 구현되었는지 확인 필요\n**트레이드오프**: 없음"
    }
  ]
}
```
