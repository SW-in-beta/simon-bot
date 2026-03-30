# Session Commands Reference

## list 명령 상세

### Step 1: 컨텍스트 수집

스크립트를 실행하여 4가지 소스에서 데이터를 수집한다:

```bash
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh list
```

**홈 디렉토리 세션 스캔 (추가)**:
```bash
PROJECT_SLUG=$(git rev-parse --show-toplevel | tr '/' '-')
SESSIONS_DIR="${HOME}/.claude/projects/${PROJECT_SLUG}/sessions"
ls -1d "${SESSIONS_DIR}"/*/ 2>/dev/null
```
각 세션 디렉토리의 `memory/session-meta.json` 또는 `pm/state.json` 또는 `company/state.json`을 확인하여 세션 유형과 상태를 파악한다.

스크립트가 출력하는 4개 섹션:
1. **현재 브랜치**: git log 최근 15개 + 미커밋 변경사항
2. **워크트리 세션**: 활성 git worktree 목록
3. **피처 브랜치**: main/master 외 로컬 브랜치
4. **프로젝트 상태 파일**: `.claude/memory/`, `.claude/company/state.json`
5. **활성 체크리스트**: `.claude/company/deployment-checklist.md` 존재 시 체크박스 상태 파싱 (완료/전체 비율, 첫 번째 `[ ]` 항목)

### Step 2: 커밋 메시지 해석

스크립트 출력의 git log에서 아래 패턴을 인식하여 작업 흐름을 재구성한다:

| 커밋 메시지 패턴 | 해석 |
|-----------------|------|
| `feat: Sprint N ...` | simon-company Sprint N 구현 |
| `chore: Phase N ...` | simon-company Phase N 완료/준비 |
| `feat(step-N): ...` | simon-bot Step N 완료 |
| `feat: initial commit` / `chore: Sprint 0 ...` | 프로젝트 초기 설정 |
| `fix: ...` | 버그 수정 (후속 작업) |
| `refactor: ...` | 리팩토링 (후속 작업) |
| `test: ...` | 테스트 추가/수정 |

커밋들을 시간순으로 이어서 "진행 흐름"을 한 줄로 요약한다.
예: `Sprint 0 → Sprint 1~4 → Phase 5 QA → Phase 7 완료 → 후속 수정 2건`

**비규격 커밋 대응:**
위 패턴에 매칭되지 않는 커밋 메시지의 경우:
- 메시지의 핵심 동사로 추론 (added/created → 기능 추가, fixed/resolved → 버그 수정, updated/changed → 수정)
- `git diff --stat {hash}` 변경 파일 패턴으로 보완 (test 파일만 → 테스트, migration → DB 변경)
- 추론 불가 시 커밋 메시지 원문을 그대로 표시

### Step 3: 현황 대시보드 출력

```
=== 작업 현황 ===

[현재 브랜치: {branch}]
  진행 흐름: {커밋 패턴에서 추론한 작업 흐름 요약}
  마지막 커밋: {hash} {message} ({relative time})
  미커밋 변경: {N} files {있으면 주요 변경 파일 나열}

[워크트리 세션]
  {있으면 목록, 없으면 "(없음)"}

[피처 브랜치]
  {main 외 브랜치 + 마지막 커밋, 없으면 "(없음)"}

[프로젝트 상태]
  Memory: {파일 수} | Company: {Phase 정보 또는 "없음"}
  Deployment: {체크리스트 있으면 "Phase X — {다음 항목} ({완료}/{전체} 완료)", 없으면 생략}
===
```

워크트리/브랜치/미커밋 변경이 모두 없고 마지막 커밋이 최종 완료 성격이면:
"현재 진행 중인 작업이 없습니다. 새 작업을 시작하시겠어요?"

---

## resume 명령 상세

### Step 1: 현황 파악

`list` flow를 먼저 실행하여 현재 상태를 파악한다.

### Step 2: 작업 선택 (AskUserQuestion)

#### Resume Default 자동 진행

가장 흔한 시나리오("이어서 계속 진행")에서 불필요한 AskUserQuestion을 제거한다:

**자동 진행 조건** (모두 충족 시):
- 탐지된 세션이 1개
- 세션 상태가 정상 (blocked=false)
- 마지막 활동이 24시간 이내

위 조건이 충족되면 AskUserQuestion 없이 자동 resume:
```
[Resume] {branch} — Step {N}/{total}에서 이어갑니다 ({Step명})
변경하려면 알려주세요.
```

### 방향 확인 생략 조건

Resume Default 자동 진행 조건 충족 시, 방향 확인(Step 3: "구체적으로 어떤 부분을 이어가면 될까요?")도 생략한다 — "이어서 해줘"라는 사용자의 의도는 중단된 지점부터 계속 진행하는 것이며, 자동 진행 조건이 충족된 상황에서 추가 확인은 이미 명백한 정보를 묻는 것이기 때문이다. workflow-state.json의 next_step을 읽어 자동으로 해당 Step부터 진행한다.

예외: `blocked: true` 상태이거나 에러 중단(`status: failed`)인 경우에는 방향 확인을 유지한다.

**AskUserQuestion 유지 조건** (하나라도 해당 시):
- 탐지된 세션이 2개 이상
- 세션 상태가 blocked
- 마지막 활동이 24시간 초과
- 이전 세션에서 에러로 중단됨

파악된 상태에 따라 적절한 질문을 한다:

**워크트리/브랜치가 여러 개인 경우:**
```
어떤 작업을 이어가시겠어요?
1. {branch-1}: {마지막 커밋 요약}
2. {branch-2}: {마지막 커밋 요약}
3. 현재 브랜치({main})에서 계속
4. 새 작업 시작
```

**현재 브랜치만 있는 경우:**
```
현재 브랜치({branch})의 최근 작업:
  {진행 흐름 요약}
  마지막: {마지막 커밋}
  미커밋 변경: {있으면 요약}

어떻게 이어가시겠어요?
1. 이어서 계속 진행
2. 방향 전환 (새 요구사항)
3. 피드백 반영 (수정사항)
4. 새 작업 시작
```

### Step 3: 방향 확인 (AskUserQuestion)

사용자 선택에 따라 구체화:
- **이어서 계속**: "구체적으로 어떤 부분을 이어가면 될까요?" (미커밋 변경이 있으면 언급)
- **방향 전환**: "어떤 방향으로 바꾸고 싶으세요?"
- **피드백 반영**: "어떤 피드백을 반영할까요?"
- **새 작업**: 적절한 스킬 안내 (simon-bot / simon-company)

### Step 4: 맥락 복원

선택된 작업의 컨텍스트를 복원한다.

**워크트리가 있는 경우:**
1. 워크트리 디렉토리로 이동
2. 세션 데이터 읽기: `{SESSIONS_DIR}/{branch-name}/memory/` 파일들 읽기. fallback: `.claude/memory/`
3. Gotchas 자동 로딩 (아래 참조)
4. State Integrity Check 실행 (아래 참조)
5. Context Dashboard 제시

**워크트리가 없는 경우 (현재 브랜치에서 이어가기):**
1. git log에서 작업 흐름 재구성 (Step 2에서 이미 수집)
2. 세션 데이터 읽기: `{SESSIONS_DIR}/{branch-name}/memory/` 파일이 있으면 읽기. fallback: `.claude/memory/`
3. Gotchas 자동 로딩 (아래 참조)
4. PM/Company 세션: `{SESSIONS_DIR}/pm-*/pm/state.json` 또는 `{SESSIONS_DIR}/company-*/company/state.json` 스캔. fallback: `.claude/company/state.json`
5. 배포 체크리스트: company 세션 디렉토리의 `deployment-checklist.md` 확인. fallback: `.claude/company/deployment-checklist.md`
6. `git diff --stat`으로 미커밋 변경사항 확인
7. 종합하여 Context Dashboard 제시

**Context Dashboard (워크트리 세션용):**
```
=== Session Resume: {branch-name} ===
Phase: {A|B|C} ({phase-name}) | Step: {current}/{total} | Path: {SMALL|STANDARD|LARGE}
Last Action: Step {N} 완료 ({description})
Pending Issues: {n} CRITICAL, {n} HIGH
Test Status: {pass}/{total} passing ({skip} skipped)
Uncommitted Changes: {YES/NO}
Recent Commits: {최근 커밋 1줄 요약}
Session Story: {최근 주요 이벤트 3개를 시간순 나열}
Context Files: {읽은 파일 목록}
Next Step: Step {N+1} — {description}
===
```

- Phase/Step 정보는 `session-meta.json` 우선, 없으면 `CONTEXT.md`에서 추출
- Test Status는 마지막 테스트 결과가 기록되어 있을 때만 표시
- Pending Issues가 없으면 해당 줄 생략

### Step 5: 작업 실행

사용자의 요청에 따라 작업을 실행한다:
1. 수정사항은 `executor` 에이전트에게 위임
2. 작업 후 `session-meta.json` 업데이트 (있는 경우)

---

### Gotchas 자동 로딩 (맥락 복원 시)

`~/.claude/projects/{slug}/state/gotchas.jsonl`이 존재하면 로딩한다 — 이전 세션에서 학습된 프로젝트 고유 함정을 재개 시 자동으로 인지한다.

```bash
jq -r '.gotcha' gotchas.jsonl 2>/dev/null | head -20
```

Context Dashboard에 `Known Gotchas: {N}건` 항목을 추가한다.

---

## State Integrity Check

워크트리 세션 복원 시 memory 파일과 실제 상태의 정합성을 검증한다:

1. `plan-summary.md`의 Unit 목록과 `unit-*/` 디렉토리의 일치 여부
2. `CONTEXT.md`의 진행 상태와 실제 memory 파일 존재 여부의 일치
3. `session-meta.json`의 `last_commit_hash`와 실제 git HEAD의 일치
4. (grind) `failure-log.md` 상단의 잔여 budget과 기록된 재시도 횟수의 산술 일치

- 불일치 발견 시: `git log --oneline` 기반으로 실제 진행 상태를 재구성. **Git 이력을 SSoT로 우선**. 자동 복구 불가 시 사용자에게 보고.

**Handoff Manifest 감지:** `.claude/memory/handoff-manifest.json`이 존재하면:
- `from_skill`에서 전환된 컨텍스트임을 인식
- `context_files`를 자동 로딩하여 이전 스킬의 상태 복원
- `failure_context`가 있으면 (bot→grind 전환 시) failure-log.md 초기값으로 사용
- Dashboard에 `Handoff: {from_skill} → {to_skill}` 표시

---

## 스킬 자동 판별 (priority order)

resume 시 아래 우선순위로 스킬을 판별한다. 단순 디렉토리 구조 추론만으로는 bot→grind 전환이나 company→pm 하위 세션을 오판별할 수 있으므로, 교차 검증을 수행한다.

### 판별 우선순위
1. **handoff-manifest.json의 to_skill** (최우선) — 스킬 전환이 진행 중이면 전환 대상 스킬을 사용. handoff가 완료되지 않은 상태에서 resume되었을 수 있기 때문이다.
2. **session-meta.json의 skill** — 명시적 기록
3. **디렉토리 구조 추론** — `pm/` → PM, `company/` → company, `memory/failure-log.md` → grind, 그 외 → simon-bot

### 판별 후 동작
- `simon-bot` → simon-bot Step 재개 프로토콜
- `simon-bot-grind` → grind failure-log, checkpoint, retry budget 복원
- `simon-company` → company state.json 기반 Phase 재개
- `simon-bot-pm` → PM state.json 기반 재개
- **배포 진행 중 감지**: company 세션 디렉토리의 `deployment-checklist.md` 또는 `.claude/company/deployment-checklist.md`에 미완료 항목이 있으면, "simon-company 배포 단계"로 판별

### 교차 검증 (gotcha 방지)

판별된 스킬과 디렉토리 상태가 불일치하면 사용자에게 확인한다:
- skill="simon-bot"이지만 `failure-log.md` + `checkpoints.md` 존재 → "grind로 전환된 세션일 수 있습니다. grind로 재개할까요?"
- skill="simon-bot-pm"이지만 `company/` 디렉토리 존재 → "company 프로젝트의 PM 하위 세션일 수 있습니다. company로 재개할까요?"
- skill="simon-bot-grind"이지만 `failure-log.md` 없음 → "grind 세션이지만 실패 기록이 없습니다. simon-bot으로 재개할까요?"
