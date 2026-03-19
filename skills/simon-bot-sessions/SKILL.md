---
name: simon-bot-sessions
description: "작업 세션 관리 — git 이력·워크트리·브랜치·메모리 파일을 종합하여 작업 현황을 파악하고, 이전 작업을 대화형으로 이어갑니다. Use when: (1) 작업 현황 확인 (\"세션 목록\", \"어디까지 했지\", \"뭐 하고 있었지\", \"현황\"), (2) 이전 작업 이어가기 (\"이어서 해줘\", \"계속해줘\", \"resume\"), (3) 세션 삭제 (\"세션 정리\", \"삭제해줘\"), (4) 피드백 전달 (\"피드백 반영해줘\"). 작업 현황 파악이나 재개가 필요할 때 사용하세요."
compatibility:
  tools: [AskUserQuestion]
  skills: [simon-bot, simon-bot-grind, simon-company, git-push-pr]
---

# simon-bot Sessions

> **도구 제한**: 이 스킬은 세션 관리용이다. 프로젝트 소스 코드를 Edit/Write하지 않는다. 세션 메타데이터 파일만 수정한다.

작업 세션 관리 스킬. **Git 이력을 1차 소스(SSoT)**로 활용하여 작업 현황을 파악하고 이전 작업을 대화형으로 재개합니다.

> **Why: Git 이력을 SSoT로 사용하는 이유** — 워크트리는 삭제될 수 있고 메모리 파일은 불완전할 수 있지만, 커밋 히스토리는 영구적이기 때문이다. 어떤 소스가 유실되더라도 git log만 있으면 작업 흐름을 재구성할 수 있다.

> **Why: 다층 소스 스캔 이유** — 단일 소스(예: 워크트리만)에 의존하면 삭제된 워크트리의 세션을 놓치고, 메모리 파일만 보면 커밋되지 않은 작업을 놓치기 때문이다. 워크트리·브랜치·메모리 파일·git 이력을 모두 스캔해야 누락 없이 세션을 탐지할 수 있다.

## Instructions

스크립트 경로: `~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh`

> **Shared Protocols**: `~/.claude/skills/_shared/preamble.md` 읽기 — Session Isolation, Error Resilience, Forbidden Rules, Agent Teams, Cognitive Independence 공통 프로토콜 포함.

### Session Isolation Protocol (확장 — Sessions 전용)

> **Why: 홈 디렉토리에 격리하는 이유** — 프로젝트 디렉토리에 저장하면 git에 의도치 않게 포함되거나, worktree 삭제 시 세션 데이터가 함께 사라지기 때문이다. 홈 디렉토리의 고정 경로에 격리하면 워크트리 생명주기와 무관하게 세션 데이터가 보존된다.

세션 탐지 시 아래 두 곳을 모두 스캔해야 한다:

**세션 데이터 위치:**
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
SESSIONS_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions"
```

**세션 디렉토리 구조:**
```
~/.claude/projects/{project-slug}/sessions/
├── feat-add-auth/          # simon-bot 세션 (branch name)
│   └── memory/
├── feat-add-db/            # simon-bot 세션 (branch name)
│   └── memory/
├── pm-20260313-143000/     # simon-bot-pm 세션 (timestamp)
│   └── pm/
└── company-20260313-150000/ # simon-company 세션 (timestamp)
    └── company/
```

**호환성**: 기존 프로젝트 디렉토리의 `.claude/memory/`, `.claude/pm/`, `.claude/company/`도 fallback으로 스캔한다 (마이그레이션 전 세션 지원).

### 명령 판별

| 의도 | 키워드 | 실행 |
|------|--------|------|
| 작업 현황 | "목록", "list", "현황", "어디까지", "뭐 하고 있었지", args 없음 | `list` flow |
| 세션 상세 | "정보", "info", "상세", 브랜치명 언급 | `info {branch}` |
| 세션 삭제 | "삭제", "delete", "제거", "정리" | `delete {branch}` |
| 이어서 작업 | "이어서", "continue", "resume", "피드백" | `resume` flow |
| PR 생성 | "PR", "풀리퀘스트", "push" | `pr` flow |

---

### list - 작업 현황

스크립트 + 홈 디렉토리 세션 스캔으로 다층 소스(현재 브랜치 git log, 워크트리, 피처 브랜치, 상태 파일, 체크리스트)를 수집하고, 커밋 메시지 패턴을 해석하여 작업 흐름을 재구성한 뒤, 현황 대시보드를 출력한다.

> **Reference Loading**: 세부 구현(스크립트 실행, 커밋 패턴 해석, 대시보드 출력 형식)은 [session-commands.md](references/session-commands.md)의 "list 명령 상세" 섹션을 읽고 따른다.

---

### resume - 대화형 작업 재개

`list` flow로 현황을 파악한 뒤, AskUserQuestion으로 작업을 선택하고, 선택된 세션의 컨텍스트(세션 데이터, State Integrity Check, Context Dashboard)를 복원하여 작업을 재개한다.

핵심 흐름: 현황 파악 → 작업 선택 → 방향 확인 → 맥락 복원 (State Integrity Check 포함) → 작업 실행

**자동 진행 강화**: Resume Default 자동 진행 조건(세션 1개 + 정상 + 24h 이내) 충족 시, 방향 확인(Step 3)도 생략한다. workflow-state.json의 next_step을 읽어 자동으로 해당 Step부터 진행하고 1줄 통보만 출력한다: `[Resume] {branch} — Step {N}({Step명})부터 이어갑니다.` 방향 확인은 blocked 상태이거나 에러 중단인 경우에만 유지한다 — "이어서 해줘"라는 사용자의 의도는 이미 명백하기 때문이다.

> **Reference Loading**: 세부 구현(작업 선택 UI, 방향 확인 질문, 맥락 복원 절차, Context Dashboard 형식, State Integrity Check, Handoff Manifest 감지)은 [session-commands.md](references/session-commands.md)의 "resume 명령 상세" 및 "State Integrity Check" 섹션을 읽고 따른다.

---

### info - 세션 상세

```bash
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh info {branch-name}
```

브랜치명이 없으면 사용자에게 물어봄 (AskUserQuestion).
현재 브랜치도 조회 가능 (예: `info main`).

### delete - 세션 삭제

```bash
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh delete {branch-name}
```

삭제 전 반드시 사용자에게 확인 (AskUserQuestion):
- "정말 `{branch-name}` 세션을 삭제하시겠습니까? (워크트리 + 브랜치 모두 제거됨)"

### pr - PR 생성

1. `info {branch-name}`으로 세션 상태 확인
2. 해당 워크트리에 커밋되지 않은 변경이 있으면 커밋
3. 브랜치를 원격에 push
4. `/git-push-pr` 스킬 호출하여 Draft PR 생성

---

### 세션 메타데이터 (session-meta.json)

각 세션 디렉토리의 `{SESSIONS_DIR}/{session-id}/memory/session-meta.json`에 세션 메타데이터를 JSON으로 관리합니다. fallback: 워크트리의 `.claude/memory/session-meta.json`.

```json
{
  "branch": "feat/some-feature",
  "skill": "simon-bot",
  "current_phase": "B",
  "current_step": 7,
  "total_steps": 19,
  "status": "in_progress",
  "created_at": "2026-03-05T10:00:00+09:00",
  "last_activity": "2026-03-05T14:30:00+09:00",
  "last_completed_step": {
    "number": 6,
    "name": "Purpose Alignment Check",
    "result": "PASS"
  },
  "failure_count": 0,
  "pending_issues": { "critical": 0, "high": 2 },
  "test_status": { "passing": 47, "total": 50, "skipped": 3 }
}
```

**갱신 시점:**
- `resume` 시 `last_activity` 업데이트
- Step 완료 시 `current_step`, `last_completed_step` 업데이트
- 테스트 실행 후 `test_status` 업데이트
- 작업 완료/중단 시 `status` 변경 (`in_progress` | `paused` | `completed` | `failed`)

**메타데이터 자동 생성:**
- resume 시 메타데이터가 없으면 `.claude/memory/` 파일들과 git 이력에서 추출하여 자동 생성
- `CONTEXT.md`에서 Phase/Step 파싱, `git log`에서 `last_activity` 추정

### 스킬 자동 판별 (resume 시)

`session-meta.json`의 `skill` 필드로 해당 스킬의 재개 프로토콜을 결정한다. 필드가 없으면 세션 디렉토리 구조로 추론한다.

> **Reference Loading**: 판별 규칙 상세(스킬별 매핑, 디렉토리 기반 추론, 배포 진행 중 감지)는 [session-commands.md](references/session-commands.md)의 "스킬 자동 판별" 섹션을 읽고 따른다.
