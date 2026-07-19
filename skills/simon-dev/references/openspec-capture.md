# OpenSpec Spec Capture (조건부 프로토콜)

대상 레포에 `openspec/` 디렉토리가 초기화되어 있으면, 구현 결과를 레포에 커밋되는 **행위계약 스펙(behavior contract)**으로 남긴다. simon-dev의 `plan-summary.md`는 SESSION_DIR에 저장되는 개인·임시 기록인 반면, openspec 스펙은 레포에 커밋되어 팀이 공유하는 영속 산출물이다. 스펙 통일성을 위해 직접 작성하지 않고 **openspec 스킬을 호출**한다 (stock 스킬은 `~/.claude/skills/openspec-propose`·`openspec-archive-change`에 전역 설치됨. 레포에 자체 버전이 있으면 project-level이 우선).

## 활성 조건 (gate)

`[ -d "$(git rev-parse --show-toplevel)/openspec" ] && command -v openspec`. 둘 중 하나라도 없으면 이 프로토콜 전체를 skip하고 1줄 통보(`[OpenSpec] openspec/ 미초기화 — 스펙 캡처 건너뜀`). `openspec init`은 자동 실행하지 않는다.

## 스펙 저장 위치 (모두 대상 레포 안)

- 작업 중 → `openspec/changes/<branch-name>/` (proposal.md, design.md, tasks.md, specs/ 델타)
- archive 후 → `openspec/specs/<capability>/spec.md`에 델타 병합 + `openspec/changes/archive/YYYY-MM-DD-<branch-name>/`로 이동

## 두 시점에서 openspec 스킬 호출

1. **Propose** (Phase A Calibration 통과 직후): plan-summary.md를 입력으로 `openspec-propose` 스킬을 호출한다 — 중복 작성을 피하려고 plan을 그대로 매핑한다 (End State[Behavior Changes]→spec 델타, Files Changed→design.md, Done-When→tasks.md). change 이름은 branch-name과 일치시킨다. behavior-contract 원칙 준수: spec.md에는 외부 관찰 가능 행위만, 타입/함수/필드명·공식·패키지 경로는 design.md로 (레포 `openspec/AGENTS.md` 규칙을 따른다). 생성된 `openspec/changes/<name>/` 파일은 Integration Stage에서 코드와 함께 커밋된다.

2. **Archive** (Integration Stage 통과 후, Step 18 직전): tasks.md 완료 항목을 `- [x]`로 갱신한 뒤 `openspec-archive-change` 스킬을 호출하여 델타를 `openspec/specs/`로 병합하고 change를 archive로 이동한다. 이 변경은 후속 커밋으로 PR에 포함되어, PR 하나에 코드 + 최종 스펙이 함께 리뷰된다.
   - **머지 후 archive를 선호하면**: 이 단계를 skip하고 `changes/<name>/` 델타만 PR에 포함시킨다(델타 자체가 리뷰 산출물이며, 머지 후 `openspec archive`를 수동 실행). config `interaction_mode: ship`은 자동 archive, 그 외에는 델타-only가 안전하다.

**openspec-apply-change는 호출하지 않는다** — 구현은 Phase B가 소유한다. openspec은 스펙 기록 용도로만 쓴다. 본 프로토콜은 Narration-Trap 방지 불변식의 적용 대상이다 (스킬 호출 복귀 후 다음 단계 tool call을 먼저 emit).
