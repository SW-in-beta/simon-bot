# Review Strategy (Step 2 상세)

## 목차
- [리뷰 사이클 카운터](#리뷰-사이클-카운터)
- [CONNECTED 모드 Blind-First 2-Pass](#connected-모드-blind-first-2-pass)
- [인라인 코멘트 작성](#인라인-코멘트-작성)
- [영향 분석 Pass](#영향-분석-pass)
- [Review Summary Body](#review-summary-body)
- [대규모 PR 처리](#대규모-pr-처리)
- [리뷰 제출](#리뷰-제출)
- [Fallback](#fallback)

## 리뷰 사이클 카운터

**리뷰 사이클 카운터 초기화**: `echo "1" > {SESSION_DIR}/memory/review-cycle-counter.md`. 최초 리뷰는 R1이다. 이후 Step 4-B에서 피드백을 처리할 때마다 +1 증가한다. 모든 코멘트(인라인 리뷰, 대댓글)에 `[R{N}]` 접두사를 붙여 리뷰 사이클을 식별한다.

For inline comment format, read [inline-review-format.md](inline-review-format.md).

## CONNECTED 모드 Blind-First 2-Pass

CONNECTED 모드에서는 구현자(simon-bot)가 생성한 review-sequence.md의 프레이밍에 anchoring되지 않도록 **Blind-First 2-Pass**를 적용한다. 리뷰가 "구현 보고서의 재포맷팅"이 아닌 "독립적 문제 발견"이 되도록 한다.

**Pass 1 (Blind)**: review-sequence.md를 읽기 **전에** diff만으로 분석
1. PR diff 확인: `gh pr diff {pr_number}`
2. diff만으로 발견한 이슈에 **독립 severity(CRITICAL/HIGH/MEDIUM)를 판정**하고,
   의문점, 설계 질문과 함께 `.claude/memory/blind-review-notes.md`에 저장.
   severity 판정 시 review-sequence.md의 구현자 판단에 의존하지 않는다 —
   이 시점에서 review-sequence.md를 아직 읽지 않았으므로 자연스럽게 독립적이다.
2-A. **작성자 유보 탐지**: PR description, 코드 주석, 커밋 메시지에서 작성자 본인이
   의문을 제기하거나 유보를 표현한 부분을 탐색한다.
   - **탐색 대상**: "~해도 괜찮을 것 같다", "고민", "TODO", "확실하지 않", "대안으로",
     "통합/분리 여부", "오버엔지니어링", "과한 것 같", "의문", "논의 필요" 등의 패턴
   - **처리**: 발견된 유보 사항을 blind-review-notes.md에 `[AUTHOR-DOUBT]` 태깅으로
     별도 기록한다. 이 항목은 6번(Adversarial Self-Check)에서 특별 검토 대상이 된다.
   - **의미**: 작성자가 스스로 확신하지 못하는 결정은, 리뷰어가 "구현되어 있으니 맞겠지"로
     넘기면 안 되는 가장 높은 우선순위의 검토 대상이다.
3. **기존 패턴 스캔**: diff에서 새로 도입되거나 변경된 주요 패턴을 추출하고, 코드베이스에 이미 더 적합한 대안이 존재하는지 능동적으로 탐색한다. 발견 결과를 blind-review-notes.md에 추가한다.
   - **스캔 대상**: 필드 타입(모델 필드, 스키마), 디자인 패턴(Factory, Strategy 등), 유틸리티 함수/클래스, 에러 핸들링 방식, 설정/상수 관리 방식
   - **탐색 방법**: Grep/Glob으로 코드베이스 내 유사 키워드 검색. 예: diff에 `CharField(choices=...)` → `EnumField`, `ChoiceField`, `custom_fields` 등을 검색
   - **판단 기준**: 코드베이스에 동일 목적의 커스텀 구현이 이미 존재하면, 새 코드가 그것을 사용하지 않은 이유가 있는지 확인 → 이유가 불명확하면 리뷰 포인트로 기록
4. **공식 문서 검증**: diff에서 사용된 라이브러리/프레임워크 API를 식별하고, 공식 문서와 대조하여 deprecated API, anti-pattern, 더 나은 대안이 있는지 사전에 파악한다. LLM의 학습 데이터는 최신이 아닐 수 있으므로, 버전 지원 여부나 권장 패턴에 대한 판단은 반드시 공식 문서로 fact-check한다 — 문서를 확인하지 않은 채 "이 버전에서는 미지원"과 같은 주장을 하면 안 된다.
   - **검증 대상**: diff에서 새로 사용되거나 변경된 라이브러리/프레임워크 API 호출, 설정 패턴, 타입/필드 선택
   - **검증 방법**: context7 MCP(`resolve-library-id` → `query-docs`)로 라이브러리 문서를 조회한다. context7에서 해당 라이브러리를 찾지 못하면 WebSearch + WebFetch로 공식 문서 사이트를 직접 확인한다
   - **검증 항목**: (a) 사용된 API가 현재 프로젝트의 라이브러리 버전에서 deprecated되었는지, (b) 공식 문서가 권장하는 대안 API/패턴이 있는지, (c) 알려진 anti-pattern에 해당하는지
   - **발견 사항 기록**: blind-review-notes.md에 추가하고, 인라인 리뷰의 리뷰 포인트에 공식 문서 URL과 함께 포함한다
5. 각 변경 단위의 핵심 파일/라인 번호 매핑 — diff의 실제 라인 번호와 정확히 일치시킨다
6. **Adversarial Self-Check**: blind-review-notes.md 작성 완료 후, 제출 전에 아래를
   수행한다. 현재 구현을 "읽고 이해했으므로 합리적으로 보인다"는 정당화 편향을 방지한다.
   a. blind-review-notes.md에서 "현재 구현이 적절하다"고 판단한 각 항목에 대해 자문:
      - "이 구현의 **반대 방향**(예: 분리→통합, 추상화→직접 구현)이 더 나은 구체적 시나리오가 있는가?"
      - "이 판단의 근거가 **코드/문서에서 직접 확인**된 것인가, 아니면 '이 접근법이 합리적으로 보인다'는 직관인가?"
      - "만약 이 코드를 **경력 1년차 개발자**가 작성했다면, 동일하게 '적절하다'고 판단할 것인가?"
   b. `[AUTHOR-DOUBT]` 태깅 항목은 반드시 위 자문을 거친다 — 작성자 본인이 의문을
      제기한 부분에서 리뷰어가 정당화 방향으로 결론 내는 것은 리뷰의 가치를 훼손한다.
      자문 결과 정당화 근거가 직관 기반이면, severity를 최소 HIGH로 상향하고
      인라인 코멘트에 `[AUTHOR-DOUBT — 추가 검토 권장]`을 명시한다.
   c. 자문 결과를 blind-review-notes.md의 각 항목에 `[SELF-CHECK: PASS/FLAG]`로 기록한다.

**Pass 2 (Informed)**: review-sequence.md를 읽고 대조
1. `review-sequence.md` 읽기
2. Pass 1의 의문점 중 review-sequence.md로 해소된 것과 해소되지 않은 것을 구분
3. **Severity 불일치 검출**: Pass 1의 독립 severity와 review-sequence.md의 severity가
   다른 항목은 `[SEVERITY-DISPUTED]` 태깅 — 인라인 코멘트에 양쪽 판정을 병기하여
   리뷰어가 왜 판단이 다른지 확인할 수 있게 한다
4. **해소되지 않은 의문점은 반드시 리뷰 코멘트에 포함** — 구현자가 미처 설명하지 못한 부분일 수 있음
5. Pass 1에서 발견한 이슈와 review-sequence.md의 "전문가 검증 완료 이슈"가 일치하면 `[INDEPENDENT-CONFIRM]` 태깅

#### Pre-Landing Review Checklist

##### Pass 1 (CRITICAL — 반드시 먼저 검토)
1. **SQL & Data Safety**: raw SQL 사용 여부, 마이그레이션 롤백 가능성, 데이터 손실 위험
2. **Race Conditions & Concurrency**: 공유 상태 접근, 동시성 이슈, lock 부재
3. **LLM Trust Boundary**: 사용자 입력이 프롬프트에 직접 삽입되는지, LLM 출력 검증 없이 사용되는지
4. **Enum & Value Completeness**: 새로 추가된 enum/const 값이 모든 switch/case에 반영되었는지 — **diff 외부 코드도 Grep으로 탐색하여 모든 참조 지점을 확인한다** (이 카테고리만 diff 내부 리뷰로 불충분)

##### Pass 2 (INFORMATIONAL — Pass 1 완료 후)
5. **Conditional Side Effects**: if/else 분기에서 한 쪽만 side effect가 있는 패턴
6. **Magic Numbers & String Coupling**: 하드코딩된 값, 문자열 기반 분기
7. **Dead Code & Consistency**: 사용되지 않는 코드, import, 불일치 패턴
8. **Test Gaps**: 새 코드 경로에 테스트가 없는 부분

체크리스트 결과를 review-payload의 body에 `### Pre-Landing Checklist` 섹션으로 포함한다.

> **STANDALONE 모드**: review-sequence.md를 자체 생성하므로 Blind-First 불필요. diff 분석이 곧 독립 리뷰. 단, **기존 패턴 스캔**은 Step 0-B의 agent 지시사항에 포함되어 있으므로 반드시 수행한다.

## 인라인 코멘트 작성

각 변경 단위의 **대표 파일 1-2개**에 집중하여 풍부한 맥락의 인라인 코멘트를 작성하고, 나머지 파일은 간단한 역할 설명만 추가한다. **삭제된 코드도 리뷰 대상이다** — 파일 삭제, 코드 제거, 로직 변경에 따른 라인 삭제에 대해 삭제 사유, 잔존 참조, 삭제된 로직의 신규 코드 반영 여부 등 리뷰 포인트가 있으면 `side: "LEFT"`로 인라인 코멘트를 작성한다. 코멘트 양식은 `inline-review-format.md`를 따른다.

**[GATE — 양식 준수 체크리스트]** 코멘트 작성 완료 후, review-payload.json 제출 전에 아래를 확인한다:
- [ ] **테스트 파일**: 모든 테스트 파일 코멘트가 `검증 범위`(Happy Path / Edge Case / Error Case) 양식을 사용하는가? 자유 형식 금지.
- [ ] **영향 분석**: 영향 분석 Pass에서 식별된 파일에 `[영향 분석: ...]` 양식의 인라인 코멘트가 review-payload.json의 comments 배열에 포함되어 있는가? Summary body에만 텍스트로 언급하고 인라인 코멘트를 누락하는 것은 금지.
- [ ] **삭제된 코드**: diff에서 삭제된 파일/라인 중 리뷰 포인트가 있는 항목에 `side: "LEFT"` 인라인 코멘트가 포함되어 있는가? "삭제된 파일이라 코멘트 불가"라고 판단하는 것은 금지.

#### Documentation Staleness Detection

diff의 변경된 함수/API 시그니처를 추출 후, 프로젝트 .md 파일에서 해당 참조를 Grep 탐색한다.
코드 변경 + .md 미변경 = `[DOC-STALENESS]` INFORMATIONAL flag.
API 시그니처, 설정 키, CLI 플래그 등 외부 인터페이스 변경에만 적용. 내부 구현 변경은 대상 아님.

## 영향 분석 Pass

변경된 코드에 대한 인라인 리뷰 완료 후, 변경되지 않았지만 영향받을 수 있는 코드를 식별하여 동일하게 인라인 코멘트를 작성한다.

**탐색 범위:**
1. **직접 호출자(Callers)**: 변경된 함수/메서드를 호출하는 코드 (Grep 탐색)
2. **인터페이스 소비자**: 변경된 인터페이스/타입을 구현하거나 사용하는 코드
3. **공유 상태 독자**: 변경된 코드가 수정하는 공유 상태(DB 스키마, 캐시 키, 설정값 등)를 읽는 코드
4. **데이터 흐름 하류**: 변경된 함수의 반환값을 소비하는 코드

**탐색 깊이**: 1-depth (직접 관계만). 전체 호출 트리가 아닌 직접 연결만 확인한다.

**필터링**: 탐색된 코드 중 실제로 동작 변화가 발생할 수 있는 것만 코멘트 대상으로 선별한다. 단순히 "이 함수를 호출한다"만으로는 부족하고, "이 변경으로 인해 기존 동작이 달라질 수 있는 구체적 이유"가 있어야 한다.

**코멘트 작성**: `inline-review-format.md`의 영향 분석 양식을 따른다. review-payload.json의 comments 배열에 변경 코드 리뷰 코멘트와 함께 포함한다.

**CONNECTED 모드**: review-sequence.md에 `영향 분석` 섹션이 있으면 이를 활용하여 탐색 범위를 좁힌다. 없으면 독자적으로 탐색한다.

**대상 제외**: 테스트 파일, 자동 생성 파일, 단순 re-export는 제외.

## Review Summary Body

`review-payload.json`의 `body`에 종합 개요를 삽입한다 (빈 문자열로 두지 않는다):

```markdown
## Review Summary

### 변경 개요
- **변경 단위**: {N}개 ({단위 이름 나열})
- **파일**: {수정 N}개, {추가 N}개

### 리뷰 순서 (권장)
1. `{file}` — {이유}
...

### 핵심 리뷰 포인트
- ⚠️ **{severity}**: {issue 요약} (`{file:line}`)
...

### 발견 이슈 통계
| Severity | 건수 |
|----------|------|
| CRITICAL | {N} |
| HIGH | {N} |
| MEDIUM | {N} |

### 알려진 트레이드오프
- {의도적 결정 사항}

### Architecture Impact (STANDARD+ 경로만)

code-design-analysis.md가 있으면 분석 기준점으로 활용한다. SMALL 경로에서는 이 섹션을 생략한다.

- **의존성 방향**: [OK/CONCERN] 이 변경이 도입하는 새 import/의존성이 기존 의존성 방향(상위→하위)을 유지하는가?
- **모듈 경계**: [OK/CONCERN] 변경된 코드가 기존 모듈의 책임 범위를 넘어서는가?
- **확장성 영향**: [OK/CONCERN] 이 변경이 시스템의 확장 지점(인터페이스, 추상화)을 강화/약화하는가?
- **데이터 흐름 변경**: [OK/CONCERN] 데이터의 생성-전파-소비 경로가 변경되어 기존 캐싱/인덱싱 전략에 영향이 있는가?

CONCERN이 있는 항목은 인라인 코멘트에도 해당 위치에 코멘트를 추가하여, 아키텍처 영향이 코드 수준에서 어떻게 나타나는지 구체적으로 지적한다.

### 영향 분석 요약
- **영향받는 파일**: {N}개 (변경되지 않았지만 영향 가능)
- **주요 영향 포인트**:
  - ⚠️ {영향 요약} (`{file:line}`) — {필요 조치}
  - ...
```

review-sequence.md의 findings 매핑 테이블(P-009)이 있으면 이를 활용하여 핵심 리뷰 포인트와 통계를 자동 생성한다. `[VERIFIED]` 태그가 붙은 finding은 "전문가 리뷰에서 확인됨"으로 표기한다.

## 대규모 PR 처리

변경 파일이 100개를 초과하는 PR은 전체 파일에 균등하게 리뷰하는 것보다 핵심 파일에 집중하는 것이 효과적이다.

**전략:**
1. 변경 파일을 영향도 기준으로 3단계로 분류:
   - **Core**: 비즈니스 로직, API 핸들러, 데이터 모델 (상세 리뷰)
   - **Support**: 설정, 유틸리티, 타입 정의 (간략 리뷰)
   - **Generated**: 마이그레이션, 스냅샷, lock 파일 (존재 확인만)
2. Core 파일에 리뷰 시간의 80%를 집중
3. Review Summary에 "리뷰 범위" 섹션을 추가하여 어떤 파일을 상세/간략/스킵했는지 투명하게 밝힌다

## 리뷰 제출

`.claude/memory/review-payload.json` 구성 후 제출:
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --method POST \
  --input .claude/memory/review-payload.json
```

**review-payload.json 구조:**
```json
{
  "body": "## Review Summary\n\n**변경 요약**: 인증 미들웨어 리팩토링 + JWT 검증 로직 개선\n**리뷰 결과**: COMMENT (수정 요청 2건)\n\n### 주요 발견\n- `verify_token()`에서 만료 토큰 처리 누락 (HIGH)\n- 에러 응답 포맷 불일치 (MEDIUM)",
  "event": "COMMENT",
  "comments": [
    {
      "path": "src/example.py",
      "line": 42,
      "body": "**[변경 단위 1: 제목]**\n\n..."
    },
    {
      "path": "src/removed_module.py",
      "line": 15,
      "side": "LEFT",
      "body": "**[변경 단위 2: 모듈 제거]**\n\n삭제된 코드에 대한 리뷰..."
    }
  ]
}
```

## Fallback

인라인 리뷰 API 호출이 실패하면 (line 매핑 오류 등), 변경 단위별 PR 일반 코멘트로 대체한다:
```bash
gh pr comment {pr_number} --body "{변경 단위 리뷰 내용}"
```
이 경우 사용자에게 fallback이 적용되었음을 알린다.
