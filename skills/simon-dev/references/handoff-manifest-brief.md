# Handoff Manifest — Distilled Brief Schema

## distilled_brief 스키마

```json
{
  "distilled_brief": {
    "what_was_done": "한 문장 — 완료된 작업 요약",
    "key_decisions": ["결정 1 (선택 + 기각 이유)", "결정 2"],
    "critical_constraints": ["수신 스킬이 반드시 알아야 하는 제약 1~3개"],
    "do_not_retry": ["이미 시도하여 실패한 접근법 — 재시도 금지"],
    "recommended_entry": "수신 스킬의 권장 진입점 (예: Step 7, Phase B)"
  }
}
```

## 작성 규칙

- `do_not_retry`는 `/rewind + re-prompt` 패턴의 구조적 구현 — "approach A를 시도했으나 foo 모듈이 해당 인터페이스를 노출하지 않음. B로 직행할 것"을 남긴다
- `key_decisions`는 Decision Journal에서 기각 이유가 있는 항목만 포함 (단순 선택은 제외)
- `critical_constraints`는 최대 3개로 제한
- 발신 스킬은 transfer_files를 생성하기 전에 distilled_brief를 먼저 작성한다 — 무엇이 중요한지 판단한 후 파일을 선택하는 순서
- 수신 스킬은 transfer_files를 읽기 전에 distilled_brief를 먼저 처리한다

## 금지 항목 (Why Pollution)

수신 스킬의 독립 판단을 오염시키는 항목:
- 실패한 시도 상세 설명 (failure-log.md는 `block_files`에 추가, 요약만 `do_not_retry`에)
- Agent Team 토론 요약 ("architect가 이렇게 말했다")
- 인터뷰 대화 내용
