# Expert Findings Output Schema

모든 전문가 에이전트가 공유하는 구조화된 출력 형식. Cross-team Synthesis의 일관성과 CRITICAL severity의 신뢰도를 보장한다.

## Analysis Process

각 변경된 코드 블록에 대해 다음 순서로 분석한다:

1. **OBSERVE**: Before/After/Delta를 사실로만 기술한다. 해석하지 않는다.
2. **TRACE**: 영향 범위를 추적한다 — caller, callee, 데이터 흐름, 상태 변경.
3. **HYPOTHESIZE**: 잠재적 문제를 가설로 제시한다. "~할 수 있다"로 표현.
4. **VERIFY**: 가설을 코드에서 검증한다.
   - 성립 → finding 작성
   - 성립하지 않음 → 보고하지 않음

**VERIFY 없이 HYPOTHESIZE만으로 finding을 작성하지 마라.** 가설을 세우고 코드에서 확인하는 과정을 거쳐야 추측성 보고를 방지할 수 있다.

## Subtle Bug Detection Heuristics

분석 시 다음 패턴을 특히 주의하여 탐색한다. 공통 패턴은 모든 도메인 전문가가 적용하고, 도메인 전용 패턴은 해당 도메인만 적용한다.

### 공통 (모든 도메인)

1. **Behavioral Cascade**: 변경이 호출 체인 하류에서 예상과 다른 동작을 유발하는가?
2. **Implicit Contract Violation**: 명시되지 않은 암묵적 계약(타입 의미론, 캐시 초기화 순서, 호출 순서 가정)을 깨뜨리는가?
3. **Silent Failure**: 에러를 삼키거나 기본값으로 조용히 대체하여 문제를 숨기는가?
4. **Partial Operation Failure**: 다단계 작업의 중간에서 실패 시 부분적으로 완료된 상태가 남는가? (예: DB 업데이트 성공 + 캐시 무효화 실패)
5. **Boundary Condition**: 경계값(0, 빈 컬렉션, 최대값, null)에서 기대와 다른 동작이 발생하는가?

### Safety 전용

6. **Security Boundary Erosion**: 인증/인가/검증 경로를 우회하거나 약화시키는가?

### Data/Ops 전용

7. **State Corruption Window**: 동시 접근 시 상태 불일치를 만들 수 있는 시간 창이 존재하는가?
8. **Resource Lifecycle**: 리소스(연결, 파일 핸들, 락)가 모든 코드 경로에서 올바르게 획득-사용-해제되는가?

## Findings Schema

각 전문가는 발견사항을 아래 형식으로 작성한다:

```
FINDING_ID: {domain}-{seq}        # 예: safety-001, data-003
SEVERITY: CRITICAL | HIGH | MEDIUM
CONFIDENCE: HIGH | MEDIUM | LOW
FILE: {path}:{line}               # 관련 파일과 라인
ISSUE: (1-2 sentences)            # 발견된 문제
EVIDENCE: (코드 스니펫 또는 참조)  # 근거
RECOMMENDATION: (구체적 수정 방안)
CROSS_DOMAIN: (다른 도메인에 영향 여부와 대상)
VERIFICATION_STATUS: PENDING     # Verification Layer 결과: VERIFIED | UNVERIFIED | PENDING
ACCEPTANCE_STATUS: PENDING       # 수용 추적: PENDING | ACCEPTED | REJECTED | MODIFIED | DEFERRED
ACCEPTANCE_REASON:               # 상태 변경 사유 (상태 변경 시 기록)
```

## Severity Calibration Guide

> **Single Source of Truth**: Severity 판정 기준과 경계 사례 원칙은 `review-rubric.md`에 정의되어 있다.
> 이 섹션은 경계 사례의 **코드 예시**만 제공하여 판정 감각을 보조한다.

### Severity Boundary Examples

교과서적 사례가 아닌, 실제 코드 리뷰에서 마주치는 경계 사례의 판단 기준:

**Example 1: CRITICAL — 단일 라인 인증 체크 제거**
```python
# Before
def get_user_data(request):
    if not request.user.is_authenticated:
        raise PermissionDenied()
    return UserData.objects.get(user=request.user)

# After (1줄 제거)
def get_user_data(request):
    return UserData.objects.get(user=request.user)
```
- WHY CRITICAL: 인증 경계가 완전히 제거됨. 미인증 사용자가 모든 데이터에 접근 가능.
- WHY NOT HIGH: "특정 조건에서만 오동작"이 아니라 모든 요청에서 보안 경계가 없음.

**Example 2: HIGH — 캐시 무효화 누락**
```go
func UpdateUserProfile(id int, data Profile) error {
    err := db.Update("users", id, data)
    // cache.Invalidate("user:" + strconv.Itoa(id)) ← 삭제됨
    return err
}
```
- WHY HIGH: DB는 갱신되지만 캐시에 이전 데이터가 남아 사용자에게 오래된 정보 표시. TTL 만료 전까지 지속.
- WHY NOT CRITICAL: 데이터 손실 없음, 보안 경계 파괴 아님, 시간이 지나면 자연 해소.
- WHY NOT MEDIUM: 사용자에게 직접 잘못된 데이터가 보이므로 "잠재적" 수준이 아님.

**Example 3: 경계 사례 — 타입 불일치 (컨텍스트 의존)**
- 컴파일 타임에 잡히면 → **MEDIUM**: strict mode에서 빌드 실패. 배포 전 발견 보장.
- 런타임에만 드러나면 → **HIGH**: 타입 체크가 없으면 프로덕션에서 예상치 못한 형변환 결과 발생.

## CRITICAL Severity Voting (검증)

CRITICAL severity 후보가 나오면, 해당 항목에 대해 독립 검증을 수행한다:
1. 해당 코드를 다시 Read로 읽고, 이전 분석을 참조하지 않은 상태에서 severity를 재판정
2. 재판정도 CRITICAL이면 확정
3. 재판정이 HIGH이면 → HIGH로 하향, 하향 근거를 findings에 기록

이 검증은 CRITICAL 남발을 방지하고, 진짜 중대한 이슈만 CRITICAL로 분류되도록 한다.
