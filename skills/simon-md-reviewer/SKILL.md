---
name: simon-md-reviewer
description: "마크다운 파일을 열어 리뷰·수정 루프를 실행합니다. Orca 터미널 안에서 실행 중이면 Orca 에디터의 인라인 리뷰 노트(Send notes to an agent) 루프를, 아니면 Obsidian에서 `%%코멘트%%` 루프를 사용합니다. Use when: MD 파일 경로가 주어지거나 ('리뷰해줘', 'Obsidian으로 보자', 'Orca에서 보자', 'MD 리뷰' 등), 세션에서 MD를 새로 작성한 뒤 보면서 수정하고 싶을 때 사용하세요. Don't use when: 다른 스킬(simon-study, simon-report 등)이 자체 리뷰 루프를 가진 경우 — 해당 스킬의 루프를 따르세요."
---

# simon-md-reviewer

마크다운 파일을 에디터에서 열어 리뷰하고, 피드백을 Claude가 반영하는 리뷰 루프. 실행 환경에 따라 두 모드 중 하나로 동작한다:

- **Orca 모드**: Orca 터미널 세션 안에서 실행 중일 때. Orca 에디터에서 열고, 인라인 리뷰 노트("Send notes to an agent")로 피드백을 받는다. 문서가 코멘트 문법으로 오염되지 않고, 앱 전환이 없다.
- **Obsidian 모드**: 그 외. Obsidian에서 열고 `%%코멘트%%`로 피드백을 받는다.

두 에디터 모두 파일 시스템을 감시하므로, Claude가 MD를 수정하면 자동으로 다시 로드된다.

## 언제 사용하나

- MD 파일 경로를 직접 지정하며 "리뷰해줘", "열어줘"
- 세션에서 MD를 작성한 뒤 "이거 보면서 수정하자"
- 다른 스킬 밖에서 독립적으로 MD 리뷰가 필요할 때

> 다른 스킬(simon-study, simon-oncall, simon-report, simon)이 실행 중이고 해당 스킬 내부에 리뷰 Phase가 있다면, 그 스킬의 리뷰 루프를 따른다. 이 스킬은 독립 호출 전용이다.

## 모드 선택

```bash
if [ "$TERM_PROGRAM" = "Orca" ] && [ -n "$ORCA_WORKSPACE_ID" ]; then
  MODE=orca
else
  MODE=obsidian
fi
```

- 사용자가 "Obsidian으로 열어줘"라고 명시하면 Orca 안에서도 Obsidian 모드를 쓴다 (vault 백링크·그래프가 필요한 문서 등).
- Orca 모드는 **Orca 터미널 세션 안**에서만 성립한다. Orca 앱이 떠 있어도 이 세션이 Orca 밖이면 리뷰 노트가 이 에이전트에게 전송되지 않으므로 Obsidian 모드를 쓴다.

---

## Phase 1: 대상 MD 파일 결정 (공통)

### 경우 A — 경로가 주어진 경우

사용자가 MD 파일 경로를 제공했으면 바로 Phase 2로 진행한다.

### 경우 B — 경로가 없는 경우

사용자에게 무엇을 MD로 작성할지 확인한다:

1. **세션 컨텍스트에서 생성**: 대화 중 분석/정리한 내용을 MD로 구조화
2. **사용자가 내용 지시**: "이 주제에 대해 정리해줘" → MD 작성

MD 작성 가이드라인:

- 한국어 작성, 기술 용어는 영어 병기
- Obsidian callout 활용 (아래 레퍼런스 참조)
- mermaid 다이어그램으로 복잡한 관계 시각화
- 섹션마다 핵심 메시지를 먼저, 상세 내용은 뒤에

### 작업 경로 (모드별)

| 모드 | 작업 경로 | 이유 |
|------|----------|------|
| Obsidian | `~/claude-reports/{topic-slug}.md` (vault) | Obsidian은 vault 내 파일만 연다 |
| Orca | `{워크스페이스 루트}/claude-reports/{topic-slug}.md` | `orca file open`은 워크스페이스 상대경로만 허용 (절대경로 → `invalid_relative_path` 에러) |

Orca 모드 세부:

- 리뷰 대상이 **이미 워크스페이스 안**에 있으면(레포 문서 등) 복사 없이 제자리에서 연다. 확정 후에도 제자리에 둔다.
- vault 파일이나 신규 보고서는 워크스페이스의 `claude-reports/`에 사본을 만들어 작업하고, 확정 시 vault로 이동한다 (Phase 4).
- `claude-reports/` 생성 시 git 오염 방지를 위해 self-ignoring `.gitignore`를 함께 만든다:

```bash
WORKSPACE_ROOT=$(orca worktree current --json | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['worktree']['path'])")
mkdir -p "$WORKSPACE_ROOT/claude-reports"
printf '*\n' > "$WORKSPACE_ROOT/claude-reports/.gitignore"
```

### Obsidian Callout 레퍼런스

| 문법 | 용도 |
|------|------|
| ` ```mermaid ` | 플로우, 시퀀스, 상태 다이어그램 |
| ` ```math ` | KaTeX 수식 |
| `> [!info]` | 정보 강조 |
| `> [!warning]` | 경고 |
| `> [!danger]` | 에러/위험 |
| `> [!success]` | 성공/완료 |
| `> [!tip]` | 팁/조언 |
| `> [!quote] 출처` | 인용 |
| `> [!example]` | 예시 |
| `> [!abstract]` | 요약/개요 |
| `> [!note]- 제목` | 접이식 (기본 접힘) |
| `> [!note]+ 제목` | 접이식 (기본 펼침) |

**비교 표현**: 마크다운 표(table) 사용
**타임라인**: 순서 목록 또는 표
**단계별 절차**: 번호 목록
**KPI/수치**: 볼드 텍스트 또는 callout 조합

> Orca 프리뷰의 callout 렌더링 여부는 미확인이다. Orca에서 blockquote로만 보여도 문법은 유효하며, vault행 문서의 최종 목적지는 Obsidian이므로 callout을 그대로 쓴다.

---

## Phase 2-A: Orca에서 열기 (Orca 모드)

```bash
orca file open --path claude-reports/{file}.md --json
```

- 경로는 **워크스페이스 상대경로**로 넘긴다. 응답의 `"opened": true`로 성공을 확인한다.
- 실패하면 (CLI 미설치, 워크스페이스 미인식 등) Obsidian 모드로 전환한다.

사용자에게 안내:

> Orca 에디터에서 파일을 열었습니다. 편한 방법으로 리뷰해주세요 (병행 가능):
>
> 1. **리뷰 노트 (권장)**: 프리뷰에서 문장을 선택해 코멘트를 답니다. 노트는 우측 사이드바 Source Control 패널의 Notes에 쌓이고, 다 달았으면 **"Send notes to an agent"**로 이 터미널의 에이전트에게 전송해주세요.
> 2. **직접 수정**: 에디터에서 바로 고치셔도 됩니다 (autosave).
> 3. 본문에 `%%코멘트%%`를 남기셔도 됩니다.
>
> 노트를 전송하시거나, **'리뷰 완료'**라고 말씀해주세요.
>
> 마크다운 경로: {markdown_file}

## Phase 2-B: Obsidian에서 열기 (Obsidian 모드)

### Vault ID 확인

Obsidian은 vault를 ID로 관리한다. `obsidian.json`에서 vault ID를 읽는다:

```bash
VAULT_ID=$(python3 -c "
import json
config = json.load(open('$HOME/Library/Application Support/obsidian/obsidian.json'))
for vid, info in config['vaults'].items():
    if 'claude-reports' in info.get('path', ''):
        print(vid)
        break
")
```

### 파일을 vault에 배치

MD 파일이 vault(`~/claude-reports/`) 외부에 있으면 복사한다:

```bash
VAULT_DIR="$HOME/claude-reports"
if [[ "$MARKDOWN_FILE" != "$VAULT_DIR"/* ]]; then
  cp "$MARKDOWN_FILE" "$VAULT_DIR/$(basename "$MARKDOWN_FILE")"
  MARKDOWN_FILE="$VAULT_DIR/$(basename "$MARKDOWN_FILE")"
fi
```

### 파일 열기

```bash
FILE_NAME=$(basename "$MARKDOWN_FILE" .md)
open "obsidian://open?vault=$VAULT_ID&file=$FILE_NAME"
```

사용자에게 안내:

> Obsidian에서 파일을 열었습니다.
> 내용을 확인하시고, 수정이 필요한 곳에 `%%코멘트%%`를 남겨주세요.
> 완료되면 **'리뷰 완료'**라고 말씀해주세요.
>
> **사용법**: 편집 모드에서 수정할 부분 옆에 `%%` 사이에 코멘트를 작성합니다.
> ```
> 평균 응답 시간은 **200ms**입니다. %%150ms로 수정해주세요%%
> 성능이 양호합니다. %%근거 데이터를 추가해주세요%%
> ```
>
> 마크다운 경로: {markdown_file}

### Fallback (Obsidian 미설치)

`/Applications/Obsidian.app`이 없으면 터미널에 마크다운 내용을 출력하고, 사용자와 대화형으로 피드백을 수집한다. 피드백을 받으면 MD를 수정하고 다시 출력 → 사용자가 "확정"할 때까지 반복.

---

## Phase 3: 피드백 루프

### 피드백 입력 채널

| 모드 | 채널 | 트리거 |
|------|------|--------|
| Orca | 리뷰 노트가 채팅 메시지로 도착 (파일·라인·인용 포함) | 도착 즉시 처리 |
| Orca | 본문 `%%코멘트%%` + 직접 수정 | 사용자가 '리뷰 완료' |
| Obsidian | 본문 `%%코멘트%%` | 사용자가 '리뷰 완료' |

Orca 모드에서는 노트 전송과 '리뷰 완료'가 섞여 올 수 있다. 어느 쪽이든 아래 Step 0부터 동일하게 처리한다.

### Step 0: 처리 전 파일 재독 (필수)

Orca 에디터는 autosave라서 사용자가 직접 고친 내용이 이미 파일에 반영돼 있을 수 있다. **Edit 전에 반드시 Read로 최신 내용을 다시 읽는다.** 세션 초반에 읽어둔 버전을 기준으로 수정하면 사용자의 직접 편집을 덮어쓴다. (Obsidian 모드에서도 동일하게 적용.)

### Step 1: 피드백 수집

- **Orca 노트 메시지**: 메시지에 담긴 노트들(파일·라인·인용·코멘트)을 처리 목록으로 쓴다. 파일에서 `%%코멘트%%`도 함께 스캔해 병합한다.
- **'리뷰 완료' 트리거**: Read로 파일을 읽어 `%%...%%` 코멘트를 모두 찾는다.

피드백이 하나도 없으면:

> 코멘트가 없습니다. 보고서를 그대로 확정합니다.

→ Phase 4로 진행.

### Step 2: 이전 라운드 변경 마킹 초기화

피드백을 처리하기 전, 이전 라운드에서 추가한 변경 표시 callout을 먼저 제거한다.

```python
import re, pathlib
p = pathlib.Path(md_file)
content = p.read_text()
# 이전 라운드의 변경 표시 callout만 제거 (다른 [!note] callout은 보존)
content = re.sub(r'> \[!note\] 🔴 아래 섹션 수정됨\n\n?', '', content)
p.write_text(content)
```

> 과거 버전에서 `<span style="color:red">` 방식이 함께 쓰였다면, 해당 태그가 포함된 파일은 수동으로 정리해야 한다 (아래 Step 3 주의사항 참조).

### Step 3: 피드백 처리

각 피드백(노트 또는 `%%코멘트%%`)에 대해:

1. 피드백의 위치(라인·인용)와 주변 텍스트로 컨텍스트를 파악
2. 내용에서 의도를 자연어로 판단 — 별도 intent 태그 불필요
   - "수정해줘", "~로 바꿔" → 해당 내용 수정
   - "왜?", "근거?", "이게 뭔가요?" → 답변/설명 추가
   - "더 자세히", "예시 추가" → 섹션 확장
3. **변경하거나 새로 추가한 내용의 바로 위에 변경 표시 callout을 한 줄 추가한다**:
   ```
   > [!note] 🔴 아래 섹션 수정됨

   (변경된/추가된 내용)
   ```
   - 인라인 단어·문장 수정: 해당 문단 바로 위에 callout 한 줄
   - 새 문단·섹션·리스트 추가: 추가된 블록 바로 위에 callout 한 줄
   - 연속된 변경: 하나의 callout으로 범위를 묶음 (중첩 callout 생성 금지)
   - callout과 본문 사이 빈 줄 1칸 유지
4. `%%코멘트%%`로 온 피드백은 처리 후 태그를 제거한다 (Edit 도구). 노트로 온 피드백은 파일에 없으므로 제거할 것이 없다.

> [!danger] raw HTML 태그 삽입 금지
> `<span>`, `<div>`, `<mark>` 등 raw HTML 태그로 변경 내용을 감싸지 말 것.
> CommonMark/Obsidian 파서는 여러 줄 HTML 블록을 만나면 그 내부의 블록 레벨 MD
> (callout, 표, 리스트, 코드 펜스 등)를 일체 파싱하지 않으므로, 이후 문법이 통째로 깨진다.
> 색상·강조는 callout 마킹만으로 충분하다.

모든 피드백을 한 번에 처리한다. 에디터가 파일 변경을 감지하여 자동 리로드.

### Step 4: 반복

**Orca 모드** 안내:

> {N}개 피드백을 처리했습니다. 에디터에서 확인해주세요.
> 추가 노트를 달아 **"Send notes to an agent"**로 전송하시거나, 완료되었으면 **'확정'**이라고 말씀해주세요.

**Obsidian 모드** 안내:

> {N}개 코멘트를 처리했습니다. Obsidian에서 확인해주세요.
> 추가 코멘트가 있으면 `%%코멘트%%`로 남기고 **'리뷰 완료'**라고 말씀해주세요.
> 완료되었으면 **'확정'**이라고 말씀해주세요.

사용자가 **"확정"**이라고 하면 Phase 4로 진행.

---

## Phase 4: 확정

1. 남아 있는 `%%...%%` 코멘트가 있다면 모두 제거 (정리)
2. **Orca 모드에서 vault행 문서인 경우** (Phase 1에서 워크스페이스 `claude-reports/`에 사본을 만든 경우): 최종본을 vault로 이동하고 워크스페이스 사본을 정리한다. 원본이 vault에서 복사돼 온 파일이면 원본을 덮어쓴다.

   ```bash
   mv "$WORKSPACE_ROOT/claude-reports/{file}.md" "$HOME/claude-reports/{file}.md"
   ```

   워크스페이스 내부 문서(레포 문서 등)였다면 이동하지 않는다.
3. 최종 마크다운 경로를 안내

> 리뷰를 완료했습니다.
> 최종 마크다운: {markdown_file}
>
> - Confluence 개인 워크스페이스에 게시할까요? (`/simon-publish`)
> - 개인 지식 베이스(wiki)에 저장할까요? (`/simon-brain-update`)
