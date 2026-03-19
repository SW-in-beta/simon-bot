---
name: simon-bot-healthcheck
description: "스킬 건강 상태 대시보드 — simon-bot 패밀리 전체의 구조적 품질을 검증하고 대시보드로 출력합니다. Use when: (1) 스킬 상태 확인 ('스킬 상태', 'healthcheck', '스킬 점검', 'skill check'), (2) boost 적용 후 품질 확인, (3) 스킬 파일 수정 후 무결성 검증. 스킬 품질을 빠르게 확인하고 싶을 때 사용하세요."
---

# simon-bot-healthcheck

simon-bot 패밀리 전체의 구조적 건강 상태를 검증하고 대시보드로 출력한다.

## Instructions

### Step 1: 대상 스킬 탐색

`~/.claude/skills/` 하위에서 simon-bot 패밀리 스킬을 탐색한다:

```bash
ls -d ~/.claude/skills/simon-bot*/  ~/.claude/skills/simon-company/ ~/.claude/skills/simon-presenter/ ~/.claude/skills/_shared/ 2>/dev/null
```

### Step 2: 스킬별 검증

각 스킬 디렉토리에 대해 아래 항목을 검증한다:

#### 2-A: SKILL.md 기본 검증
- **존재 여부**: SKILL.md 파일이 있는가
- **YAML frontmatter**: name, description 필드가 존재하는가
- **줄 수**: 500줄 이내인가 (경계: 450-500줄이면 WARNING)
- **description 트리거**: "Use when:" 패턴이 포함되어 있는가

#### 2-B: Reference 검증
- **참조 경로**: SKILL.md에서 `references/` 또는 `_shared/`를 참조하는 경로가 실제로 존재하는가
- **300줄 초과 TOC**: 300줄 초과 reference 파일에 TOC(`## 목차` 또는 `## Table of Contents`)가 있는가
- **미참조 파일**: references/ 디렉토리에 있지만 SKILL.md에서 한 번도 참조하지 않는 파일이 있는가

#### 2-C: Shared Protocols 검증
- **Preamble 참조**: `_shared/preamble.md` 참조가 있는가 (simon-bot, grind, review, pm, report, sessions, company에 필수)
- **Expert Panel 참조**: boost 계열 스킬에 `_shared/expert-panel-boost.md` 참조가 있는가

### Step 3: 대시보드 출력

결과를 ASCII 대시보드로 출력한다:

```
=== Simon-Bot Skill Health Dashboard ===

| 스킬 | SKILL.md | 줄 수 | Frontmatter | Description | Ref 경로 | TOC | Preamble | 총점 |
|------|----------|-------|-------------|-------------|----------|-----|----------|------|
| simon-bot | OK | 499 ⚠ | OK | OK | OK | OK | OK | 7/7 |
| simon-bot-grind | OK | 211 | OK | OK | OK | OK | OK | 7/7 |
| simon-bot-review | OK | 365 | OK | OK | OK | OK | OK | 7/7 |
| ... | | | | | | | | |

=== Shared Files ===
| 파일 | 존재 | 줄 수 | 참조하는 스킬 수 |
|------|------|-------|-----------------|
| _shared/preamble.md | OK | 42 | 7 |
| _shared/expert-panel-boost.md | OK | 80 | 2 |

=== Summary ===
Total: {N} skills | PASS: {N} | WARNING: {N} | FAIL: {N}
```

**점수 기준**:
- 각 검증 항목 통과 시 1점
- 7/7 = PASS, 5-6/7 = WARNING, <5 = FAIL
- 줄 수 450-500 = WARNING
- 줄 수 >500 = FAIL

### Step 4: 이슈 상세

FAIL 또는 WARNING 항목이 있으면 상세 내용을 출력한다:

```
=== Issues ===
[WARNING] simon-bot/SKILL.md: 499줄 (500줄 제한에 1줄 여유)
  → 권장: Decision Journal 예시 블록을 cross-cutting-protocols.md로 이동

[FAIL] simon-bot-xxx/SKILL.md: references/foo.md 경로가 존재하지 않음
  → 권장: 파일 생성 또는 참조 제거
```

## Global Rules

- 이 스킬은 **읽기 전용**이다. 파일을 수정하지 않고 검증 결과만 출력한다.
- 수정이 필요한 이슈를 발견하면 권장 조치를 제안하되, 직접 수정하지 않는다.
- 사용자가 "수정해줘"라고 요청하면 해당 이슈에 대해서만 Read → Edit로 수정한다.
