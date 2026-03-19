---
name: simon-bot-sync
description: simon-* 스킬 파일 변경 시 ~/simon-bot 레포 자동 동기화 및 README 업데이트. Stop 훅에 의해 자동 트리거 시 백그라운드 에이전트로 실행되어 메인 세션을 방해하지 않습니다. 10분 쿨다운이 적용되어 연속 수정 시 불필요한 반복 동기화를 방지합니다. 수동 호출(/simon-bot-sync)도 가능합니다.
---

# simon-bot-sync

simon-* 스킬 패밀리의 변경사항을 `~/simon-bot` 오픈소스 레포에 동기화하고, README를 전문가 수준으로 업데이트한 뒤, 자동 커밋 & 푸시하는 스킬.

## 트리거

- **자동**: PostToolUse 훅이 `~/.claude/skills/simon-*` 파일 변경을 감지하면 마커 파일 생성 → Stop 훅이 이 스킬 실행 지시 (10분 쿨다운 적용)
- **수동**: `/simon-bot-sync` 명령으로 직접 호출

## 자동 트리거 시 (Stop 훅에 의한 호출)

메인 세션의 컨텍스트를 보호하기 위해, 최소한의 작업만 수행하고 나머지는 백그라운드 Agent에 위임한다.

**메인 세션에서 수행할 작업 (3단계로 즉시 완료):**

1. 마커 삭제 + 쿨다운 타임스탬프 갱신:
   ```bash
   rm -f /tmp/.simon-skill-sync-needed && touch /tmp/.simon-skill-last-sync
   ```

2. 백그라운드 Agent를 spawn (`run_in_background: true`)하여 아래 "동기화 절차" 전체를 위임. Agent prompt에 동기화 절차 섹션 내용을 포함시킨다.

3. 사용자에게 "동기화를 백그라운드에서 시작했습니다"라고 한 줄 안내 후 즉시 턴 종료.

**절대로 메인 세션에서 동기화 절차를 직접 실행하지 않는다.**

## 수동 호출 시

`/simon-bot-sync`로 직접 호출된 경우에도 백그라운드 Agent로 실행한다. 동일한 3단계를 따른다.

## 동기화 절차

이 섹션은 백그라운드 Agent가 수행하는 작업이다.

### Step 1: 동기화 대상 파악

동기화 대상 스킬 목록 (이 목록에 없는 스킬은 동기화하지 않는다):
- `simon-bot`
- `simon-bot-auto-boost`
- `simon-bot-boost`
- `simon-bot-boost-capture`
- `simon-bot-boost-review`
- `simon-bot-grind`
- `simon-bot-pm`
- `simon-bot-report`
- `simon-bot-review`
- `simon-bot-sessions`
- `simon-company`
- `simon-presenter`

**제외 대상:**
- `simon-bot-sync` (이 스킬 자체 — 메타 스킬이므로 레포에 포함하지 않음)
- `*-workspace/` 디렉토리 (로컬 eval 데이터)
- `evals/` 디렉토리 (로컬 eval 데이터)
- `~/.claude/skills/simon-bot/workflow/` (레포의 `workflow/`에서 복사된 것)
- `~/.claude/skills/simon-bot/install.sh` (레포의 `install.sh`에서 복사된 것)

### Step 2: 파일 동기화

각 대상 스킬에 대해 `rsync`로 동기화한다:

```bash
rsync -av --delete \
  --exclude='evals/' \
  --exclude='*-workspace/' \
  ~/.claude/skills/<skill-name>/ ~/simon-bot/skills/<skill-name>/
```

`simon-bot` 스킬은 추가 제외 필요:
```bash
rsync -av --delete \
  --exclude='evals/' \
  --exclude='*-workspace/' \
  --exclude='workflow/' \
  --exclude='install.sh' \
  ~/.claude/skills/simon-bot/ ~/simon-bot/skills/simon-bot/
```

### Step 3: install.sh 업데이트

`~/simon-bot/install.sh`의 `install_skill` 호출 목록을 동기화된 스킬 목록과 일치시킨다.

현재 install.sh에서 `install_skill "..."` 라인들을 찾아, Step 1의 동기화 대상 목록과 비교하여 누락된 스킬을 추가한다.

### Step 4: README 업데이트 — 오픈소스 README 전문가

이 단계에서는 **오픈소스 README 전문가** 역할을 수행한다.

#### 4-1. 정보 수집

모든 동기화된 스킬의 SKILL.md에서 다음을 추출:
- `name`: 스킬 이름
- `description`: 스킬 설명 (frontmatter)
- 핵심 기능 요약 (SKILL.md 본문에서 추출)

#### 4-2. README.md (한국어) 업데이트

기존 README.md 구조를 유지하면서 다음 섹션을 업데이트:
- **스킬 테이블**: 모든 동기화된 스킬 반영 (이전에 없던 스킬 추가, 설명 최신화)
- **"어떤 스킬을 쓸까?" 테이블**: 새 스킬에 대한 사용 시나리오 추가
- **details 섹션**: 새 스킬에 대한 상세 설명 추가, 기존 스킬 설명 최신화

README 작성 원칙:
- 기존 톤과 스타일을 유지 (간결한 한국어, 기술적이지만 접근 가능)
- 뱃지, 헤더, Mermaid 다이어그램 등 기존 구조 보존
- 불필요한 마케팅 문구 지양, 기능 중심 서술
- 스킬 간 관계와 선택 기준을 명확히 전달

#### 4-3. README.en.md (영어) 업데이트

README.md와 동일한 변경사항을 영어로 반영. 기존 영문 README의 톤과 스타일 유지.

### Step 5: Git 커밋 & 푸시

```bash
cd ~/simon-bot
git add -A
```

변경사항이 있는 경우에만 커밋:
```bash
git diff --cached --quiet || git commit -m "sync: 스킬 동기화 ($(date +%Y-%m-%d))"
git push origin main
```

커밋 메시지는 변경 내용에 따라 구체적으로 작성:
- 새 스킬 추가: `feat: <스킬명> 스킬 추가`
- 기존 스킬 수정: `update: <스킬명> 스킬 업데이트`
- 복합 변경: `sync: 스킬 동기화 — <변경 요약>`

### Step 6: 마커 파일 정리

동기화 완료 후 마커 파일을 삭제한다 (자동 트리거 시에는 이미 삭제됨):
```bash
rm -f /tmp/.simon-skill-sync-needed
```

## 주의사항

- 이 스킬은 `~/.claude/skills/` → `~/simon-bot/` 방향의 단방향 동기화만 수행
- 레포에서 직접 수정한 파일이 있다면 덮어써질 수 있으므로, 항상 `~/.claude/skills/`에서 수정할 것
- `workflow/` 디렉토리(prompts, scripts, templates)는 이 스킬의 동기화 대상이 아님 — 별도로 관리
