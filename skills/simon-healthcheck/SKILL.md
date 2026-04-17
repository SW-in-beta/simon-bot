---
name: simon-healthcheck
description: "스킬 건강 상태 대시보드 — simon 패밀리 전체의 구조적 품질을 검증하고 대시보드로 출력합니다. Use when: (1) 스킬 상태 확인 ('스킬 상태', 'healthcheck', '스킬 점검', 'skill check'), (2) boost 적용 후 품질 확인, (3) 스킬 파일 수정 후 무결성 검증. 스킬 품질을 빠르게 확인하고 싶을 때 사용하세요."
model: sonnet
---

# simon-healthcheck

simon 패밀리 전체의 구조적 건강 상태를 검증하고 대시보드로 출력한다.

## Instructions

### Step 1: 대상 스킬 탐색

`~/.claude/skills/` 하위에서 simon 패밀리 스킬을 탐색한다:

```bash
ls -d ~/.claude/skills/simon*/  ~/.claude/skills/simon-company/ ~/.claude/skills/simon-presenter/ ~/.claude/skills/_shared/ 2>/dev/null
```

### Step 2: 스킬별 검증

각 스킬 디렉토리에 대해 아래 항목을 검증한다:

#### 2-A: SKILL.md 기본 검증
- **존재 여부**: SKILL.md 파일이 있는가
- **YAML frontmatter**: name, description 필드가 존재하는가
- **줄 수**: 500줄 이내인가 (경계: 450-500줄이면 WARNING)
- **description 트리거**: "Use when:" 패턴이 포함되어 있는가

#### 2-B: Reference 검증
- **참조 경로**: SKILL.md의 **실제 Markdown 링크** `[text](references/file.md)` 또는 명시적 read 지시문(`read references/file.md`)에서 참조하는 경로가 실제로 존재하는가. **오탐 제외 규칙**: ① 코드블록(` ``` `) 내부의 예시 경로, ② 타 스킬 절대경로(`~/.claude/skills/다른스킬/references/...`), ③ 예시 텍스트 내 언급 — 이 세 가지는 검증 대상에서 제외한다.
- **300줄 초과 TOC**: 300줄 초과 reference 파일에 TOC(`## 목차` 또는 `## Table of Contents`)가 있는가
- **미참조 파일**: references/ 디렉토리에 있지만 SKILL.md에서 Markdown 링크로 한 번도 참조하지 않는 파일이 있는가

#### 2-C: Script/Asset 경로 검증

SKILL.md와 references/*.md에서 참조하는 스크립트·자산 경로가 실제 존재하는지 검증한다.

**추출 대상 패턴**:
- 절대 경로: `~/.claude/skills/*/scripts/*.sh`, `~/.claude/skills/*/assets/*` 등
- 상대 경로: `scripts/foo.sh`, `workflow/scripts/bar.sh`, `assets/template.html` 등
- bash/python 실행문: `bash scripts/...`, `python3 scripts/...`, `nohup python3 ~/.claude/skills/...`

**오탐 제외 규칙** (2-B와 동일):
① 코드블록(` ``` `) 내부에서 **패턴 예시로만** 사용된 경로 (실제 실행 커맨드는 코드블록 안이라도 검증 대상)
② 예시 텍스트 내 언급 ("예: `scripts/deploy/`" 같은 설명용)

**검증 항목**:
- **경로 존재**: 참조된 스크립트/자산 파일이 실제로 존재하는가
- **실행 권한**: `.sh` 파일이 실행 권한(`chmod +x`)을 갖고 있는가
- **미참조 스크립트**: scripts/ 디렉토리에 있지만 SKILL.md나 references/에서 한 번도 참조하지 않는 파일이 있는가

#### 2-D: Reference 내용 품질

reference 파일의 내용이 구조화되고 적정 크기를 유지하는지 검증한다.

**검증 항목**:
- **구조화**: 각 reference 파일에 최소 2개 이상의 `##` 이상 헤더가 있는가 (구조 없는 텍스트 덤프 경고)
- **과대 파일**: 500줄 초과 reference 파일 경고 (progressive disclosure 위반 — 분할 권장)
- **내부 링크**: reference 파일 내에서 다른 파일을 참조(`[text](path)`, `read path`)하면 해당 파일이 존재하는가
- **Script 참조 정합성**: reference 파일 내에서 참조하는 스크립트 경로가 실제 존재하는가 (2-C와 동일 기준)

#### 2-E: Shared Protocols 검증
- **Preamble 참조**: `_shared/preamble.md` 참조가 있는가 (simon, grind, review, pm, report, sessions, company에 필수)
- **Expert Panel 참조**: boost 계열 스킬에 `_shared/expert-panel-boost.md` 참조가 있는가

### Step 3: 대시보드 출력

결과를 ASCII 대시보드로 출력한다:

```
=== Simon-Bot Skill Health Dashboard ===

| 스킬 | SKILL.md | 줄 수 | Frontmatter | Description | Ref 경로 | TOC | Script 경로 | Ref 품질 | Preamble | 총점 |
|------|----------|-------|-------------|-------------|----------|-----|------------|---------|----------|------|
| simon | OK | 499 ⚠ | OK | OK | OK | OK | OK | ⚠ 1 | OK | 8/9 |
| simon-grind | OK | 211 | OK | OK | OK | OK | OK | OK | OK | 9/9 |
| ... | | | | | | | | | | |

=== Script/Asset 상세 ===
| 스킬 | 참조 경로 | 존재 | 실행권한 |
|------|----------|------|---------|
| simon-oncall | ~/.claude/skills/buzzvil-slack/scripts/fetch_thread.sh | OK | OK |
| simon-sessions | ~/.claude/skills/simon/workflow/scripts/manage-sessions.sh | OK | OK |

=== Reference 품질 상세 ===
| 스킬 | Reference 파일 | 줄 수 | 헤더 수 | 내부 링크 | 비고 |
|------|---------------|-------|--------|----------|------|
| simon | phase-a-planning.md | 836 ⚠ | 12 | OK | 500줄 초과 — 분할 권장 |
| simon-company | contracts-execution.md | 534 ⚠ | 8 | OK | 500줄 초과 — 분할 권장 |

=== Shared Files ===
| 파일 | 존재 | 줄 수 | 참조하는 스킬 수 |
|------|------|-------|-----------------|
| _shared/preamble.md | OK | 42 | 7 |
| _shared/expert-panel-boost.md | OK | 80 | 2 |

=== Summary ===
Total: {N} skills | PASS: {N} | WARNING: {N} | FAIL: {N}
```

**점수 기준**:
- 각 검증 항목 통과 시 1점 (총 9항목: SKILL.md 존재, 줄 수, Frontmatter, Description, Ref 경로, TOC, Script 경로, Ref 품질, Preamble)
- 9/9 = PASS, 7-8/9 = WARNING, <7 = FAIL
- 줄 수 450-500 = WARNING
- 줄 수 >500 = FAIL
- Script 경로: 1개라도 존재하지 않으면 FAIL, 실행 권한만 없으면 WARNING
- Ref 품질: 500줄 초과 또는 헤더 <2개 파일이 1개라도 있으면 WARNING, 내부 Dead link가 있으면 FAIL

### Step 4: 이슈 상세

FAIL 또는 WARNING 항목이 있으면 상세 내용을 출력한다:

```
=== Issues ===
[WARNING] simon/SKILL.md: 499줄 (500줄 제한에 1줄 여유)
  → 권장: Decision Journal 예시 블록을 cross-cutting-protocols.md로 이동

[FAIL] simon-xxx/SKILL.md: references/foo.md 경로가 존재하지 않음
  → 권장: 파일 생성 또는 참조 제거

[FAIL] simon-oncall/SKILL.md: ~/.claude/skills/buzzvil-slack/scripts/fetch_thread.sh 존재하지 않음
  → 권장: 스크립트 생성 또는 참조 경로 수정

[WARNING] simon-grind/scripts/checkpoint.sh: 실행 권한 없음
  → 권장: chmod +x scripts/checkpoint.sh

[WARNING] simon/references/phase-a-planning.md: 836줄 (500줄 초과) — progressive disclosure 위반
  → 권장: 주제별로 분할하여 별도 reference 파일로 이동

[WARNING] simon-xxx/references/bar.md: ## 헤더가 0개 — 구조화되지 않은 텍스트
  → 권장: 섹션 헤더를 추가하여 구조화

[FAIL] simon-xxx/references/baz.md: 내부 참조 경로 scripts/nonexistent.sh 존재하지 않음
  → 권장: 경로 수정 또는 참조 제거
```

## Global Rules

- 이 스킬은 **읽기 전용**이다. 파일을 수정하지 않고 검증 결과만 출력한다.
- 수정이 필요한 이슈를 발견하면 권장 조치를 제안하되, 직접 수정하지 않는다.
- 사용자가 "수정해줘"라고 요청하면 해당 이슈에 대해서만 Read → Edit로 수정한다.
