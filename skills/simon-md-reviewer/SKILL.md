---
name: simon-md-reviewer
description: "마크다운 파일을 Obsidian에서 열어 `%%코멘트%%` 기반 리뷰·수정 루프를 실행합니다. Use when: MD 파일 경로가 주어지거나 ('리뷰해줘', 'Obsidian으로 보자', 'MD 리뷰' 등), 세션에서 MD를 새로 작성한 뒤 Obsidian에서 보면서 수정하고 싶을 때 사용하세요. Don't use when: 다른 스킬(simon-study, simon-report 등)이 자체 리뷰 루프를 가진 경우 — 해당 스킬의 루프를 따르세요."
---

# simon-md-reviewer

마크다운 파일을 Obsidian에서 열어 리뷰하고, `%%코멘트%%`로 피드백을 남기면 Claude가 반영하는 리뷰 루프.

Obsidian은 파일 시스템을 직접 감시하므로, Claude가 MD를 수정하면 자동으로 다시 로드된다. 별도의 서버나 HTML 변환이 필요 없다.

## 언제 사용하나

- MD 파일 경로를 직접 지정하며 "리뷰해줘", "Obsidian으로 열어줘"
- 세션에서 MD를 작성한 뒤 "이거 보면서 수정하자"
- 다른 스킬 밖에서 독립적으로 MD 리뷰가 필요할 때

> 다른 스킬(simon-study, simon-oncall, simon-report, simon)이 실행 중이고 해당 스킬 내부에 리뷰 Phase가 있다면, 그 스킬의 리뷰 루프를 따른다. 이 스킬은 독립 호출 전용이다.

---

## Phase 1: 대상 MD 파일 결정

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

**저장 경로**: Obsidian vault `~/claude-reports/` 안에 저장한다.
- 사용자가 경로를 지정하면 해당 파일을 vault로 복사
- 미지정 시: `~/claude-reports/{topic-slug}.md`

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

---

## Phase 2: Obsidian에서 열기

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

## Phase 3: 코멘트 피드백 루프

사용자가 **"리뷰 완료"**라고 말하면 실행한다.

### Step 1: 코멘트 읽기

Read 도구로 MD 파일을 읽고, `%%...%%` 코멘트를 모두 찾는다.

코멘트가 없으면:

> 코멘트가 없습니다. 보고서를 그대로 확정합니다.

→ Phase 4로 진행.

### Step 2: 이전 라운드 빨간 마킹 초기화

코멘트를 처리하기 전, 이전 라운드에서 추가한 빨간 마킹을 먼저 제거한다.
빨간 마킹을 제거할 때 텍스트 내용은 그대로 유지한다.

```python
import re, pathlib
p = pathlib.Path(md_file)
content = p.read_text()
# <span style="color:red">...</span> 제거 (내용은 보존, 멀티라인 포함)
content = re.sub(r'<span style="color:red">(.*?)</span>', r'\1', content, flags=re.DOTALL)
# 블록 요소용 변경 표시 callout 제거
content = re.sub(r'> \[!note\] 🔴 아래 섹션 수정됨\n', '', content)
p.write_text(content)
```

### Step 3: 코멘트 처리

각 `%%코멘트%%`에 대해:

1. 코멘트의 위치와 주변 텍스트로 컨텍스트를 파악
2. 코멘트 내용에서 의도를 자연어로 판단 — 별도 intent 태그 불필요
   - "수정해줘", "~로 바꿔" → 해당 내용 수정
   - "왜?", "근거?", "이게 뭔가요?" → 답변/설명 추가
   - "더 자세히", "예시 추가" → 섹션 확장
3. **변경하거나 새로 추가한 텍스트를 `<span style="color:red">...</span>`으로 감싼다**
   - 기존 문장/단어 수정: `<span style="color:red">새 텍스트</span>`으로 교체
   - 새 문장/단락 추가: 추가된 내용 전체를 `<span style="color:red">추가 내용</span>`으로 감싸기
   - 섹션 확장: 새로 추가된 부분만 감싸기 (기존 내용은 마킹 불필요)
4. 처리된 `%%코멘트%%` 태그 제거 (Edit 도구)

**블록 요소 처리 (코드 블록, 표 등)**: 코드 펜스나 표 내부는 span 감싸기가 불가능하다. 이런 경우 해당 블록 **바로 위에** 변경 표시 callout을 추가한다:

```
> [!note] 🔴 아래 섹션 수정됨
```

(초기화 시 이 callout도 함께 제거한다 — Step 2의 python script에 `re.sub(r'> \[!note\] 🔴.*\n', '', content)` 추가)

모든 코멘트를 한 번에 처리한다. Obsidian이 파일 변경을 감지하여 자동 리로드.

### Step 4: 반복

사용자에게 안내:

> {N}개 코멘트를 처리했습니다. Obsidian에서 확인해주세요.
> 추가 코멘트가 있으면 `%%코멘트%%`로 남기고 **'리뷰 완료'**라고 말씀해주세요.
> 완료되었으면 **'확정'**이라고 말씀해주세요.

사용자가 **"확정"**이라고 하면 Phase 4로 진행.

---

## Phase 4: 확정

1. 남아 있는 `%%...%%` 코멘트가 있다면 모두 제거 (정리)
2. 최종 마크다운 경로를 안내

> 리뷰를 완료했습니다.
> 최종 마크다운: {markdown_file}
>
> - Confluence 개인 워크스페이스에 게시할까요? (`/simon-publish`)
> - 개인 지식 베이스(wiki)에 저장할까요? (`/simon-brain-update`)
