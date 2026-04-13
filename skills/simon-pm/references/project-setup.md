# Project Setup Detail

Phase 0의 상세 프로세스. SKILL.md에서 참조한다.

---

## 0-A: 단일 통합 확인

사용자 요청에서 프로젝트 유형(Greenfield/Existing)과 실행 모드(자동/승인)를 AI가 추론하고, 한 번에 제시하여 교정받는다. 별도의 AskUserQuestion을 여러 번 나누지 않는다.

```
[Default] 프로젝트 설정:
- 유형: {Greenfield|Existing} — {추론 근거}
- 실행 모드: 자동 진행 — 완료 즉시 다음 작업으로 (중간 보고만)
- 변경하려면 알려주세요.
```

사용자가 교정하면 반영, 교정 없으면 기본값으로 진행.

Existing인 경우:
- `graphify-out/GRAPH_REPORT.md` 존재 시: `~/.claude/skills/_shared/graphify-context.md` 읽기 → god nodes/communities로 프로젝트 구조 선파악
- 코드베이스 탐색 (`explore-medium`)으로 현황 파악 — 그래프가 있으면 관련 community 중심으로 탐색 범위 축소
- "simon-report로 사전 분석 보고서를 먼저 작성할까요?" (선택사항, 한 번만 질문)

## 0-B: 초기 상태 저장

```json
// .claude/pm/state.json
{
  "phase": 0,
  "project_type": "greenfield|existing",
  "execution_mode": "auto|approval",
  "created_at": "timestamp",
  "tasks_total": 0,
  "tasks_completed": 0
}
```
