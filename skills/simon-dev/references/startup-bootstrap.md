# Startup Bootstrap — Completion Gate

## Prior Context Brief 검색 (Startup 2-B)

사용자 요청에서 추출한 키워드로 `~/.claude/projects/{slug}/state/decisions.jsonl`에서 관련 결정사항을 검색한다:

```bash
# 키워드 추출 후 jq로 decisions.jsonl 검색
jq -s --arg kw "{keyword}" '[.[] | select(.decision | ascii_downcase | contains($kw | ascii_downcase))] | sort_by(.timestamp) | reverse | .[0:5]' decisions.jsonl
```

## Startup Completion Gate

Deterministic Gate Principle 적용. bash로 필수 파일 존재를 확인한 후에만 Phase A 진입.

```bash
echo "=== Startup Completion Gate ==="
test -f "${SESSION_DIR}/memory/workflow-state.json" && echo "OK workflow-state.json" || echo "FAIL workflow-state.json 없음"
test -f "${SESSION_DIR}/memory/session-meta.json" && echo "OK session-meta.json" || echo "FAIL session-meta.json 없음"
```

체크리스트:
- [ ] `${SESSION_DIR}/memory/workflow-state.json` 존재 (필수)
- [ ] `${SESSION_DIR}/memory/session-meta.json` 존재 (필수)

FAIL 항목이 있으면 Phase A 진입을 중단하고 해당 단계(3-C/3-D)로 돌아가 재수행한다.
