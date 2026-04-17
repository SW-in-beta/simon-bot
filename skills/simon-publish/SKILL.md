---
name: simon-publish
description: "MD 파일을 Confluence 개인 워크스페이스에 자동 분류하여 게시합니다. Use when: (1) simon-md-reviewer 완료 후 게시할 때, (2) '/simon-publish'로 직접 호출할 때, (3) '컨플루언스에 올려줘', '워크스페이스에 게시', '문서 발행', 'publish', '이거 올려줘' 등의 요청. MD 리뷰 완료 후 게시 의사를 밝힐 때, 또는 작성한 보고서/분석 결과를 Confluence에 정리하고 싶을 때도 이 스킬을 사용하세요."
---

# Confluence 자동 게시

simon-md-reviewer로 확정된 마크다운(또는 임의의 MD 파일)을 사용자의 Confluence 개인 워크스페이스에 게시한다.
콘텐츠를 분석하여 적절한 카테고리 페이지 아래에 자동 배치하고, Confluence가 지원하는 형식으로 정리한다.

## 상수

| 항목 | 값 |
|------|-----|
| Space key | `~5a537e6bf7743b54fe415095` |
| Space URL | https://buzzvil.atlassian.net/wiki/spaces/~5a537e6bf7743b54fe415095/overview |
| Scripts 경로 | `~/.claude/skills/buzzvil-confluence/scripts/` |

---

## Phase 1: MD 파일 결정

| 상황 | 행동 |
|------|------|
| simon-md-reviewer 직후 | 확정된 MD 경로를 그대로 사용 |
| `/simon-publish <path>` | 인자로 받은 경로 사용 |
| 경로 없이 호출 | 사용자에게 경로 확인 |

MD 파일을 Read 도구로 읽어 제목(첫 번째 `# ` 헤딩)과 본문을 파악한다.

---

## Phase 2: 카테고리 자동 분류

### 2-1. 콘텐츠 분석

MD의 제목, 소제목, 본문 키워드를 종합하여 카테고리를 추론한다.
하나의 카테고리가 확신될 때만 자동 배정하고, 애매하면 후보 2-3개를 제시하여 사용자가 선택하게 한다.

**판단 힌트** (콘텐츠에 따라 유연하게 판단 — 이 목록은 예시):

| 키워드/패턴 | 카테고리 후보 |
|-------------|---------------|
| 코드 분석, 아키텍처, 로직, 리팩토링, DDD, 서비스 내부 | 코드 분석 |
| Claude, AI, LLM, 프롬프트, 에이전트, 스킬 | AI & Claude |
| RFC, 기술 제안, 설계 문서, ADR | RFC |
| 스터디, 학습, TIL, 개념 정리 | 스터디 노트 |
| 장애, 온콜, 인시던트, 포스트모템 | 장애 분석 |
| 회의록, 미팅, 논의, 싱크 | 회의록 |
| 기획, PRD, 요구사항, 스펙 | 기획 문서 |
| 데이터, 쿼리, 분석, 메트릭 | 데이터 분석 |

이 목록에 딱 맞지 않는 주제라면, 내용의 핵심 주제어로 자연스러운 카테고리명을 생성한다.

### 2-2. 기존 카테고리 확인

개인 워크스페이스에 이미 어떤 페이지들이 있는지 조회한다:

```bash
~/.claude/skills/buzzvil-confluence/scripts/search.sh \
  -s "~5a537e6bf7743b54fe415095" -n 25
```

검색 결과에서 카테고리 역할을 하는 페이지(짧은 제목, 상위 페이지 성격)를 식별한다.

- **매칭 카테고리 존재**: 해당 페이지 ID를 parent로 사용
- **매칭 카테고리 없음**: 새 카테고리 페이지를 생성

```bash
~/.claude/skills/buzzvil-confluence/scripts/create_page.sh \
  --space "~5a537e6bf7743b54fe415095" \
  --title "<카테고리명>" \
  --body "<카테고리명> 관련 문서를 정리하는 페이지입니다."
```

> 새 카테고리를 만들 때는 사용자에게 먼저 확인받는다.

### 2-3. 사용자 확인

분류 결과를 보고하고 확인받는다:

> 카테고리: **AI & Claude** (기존)
> 제목: **Claude Code 스킬 시스템 분석**
>
> 이대로 게시할까요?

사용자가 카테고리를 변경하거나 제목을 수정하고 싶다면 반영한다.

---

## Phase 3: 중복 확인

해당 카테고리 아래에 동일 제목 페이지가 있는지 검색:

```bash
~/.claude/skills/buzzvil-confluence/scripts/search.sh \
  -q "<페이지 제목>" -s "~5a537e6bf7743b54fe415095"
```

**동일 제목 발견 시** 사용자에게 선택지 제시:
- (A) 기존 페이지 업데이트 (내용 전체 교체)
- (B) 새 페이지로 생성 (제목에 날짜 추가: `<제목> (YYYY-MM-DD)`)
- (C) 취소

---

## Phase 4: MD 정리 및 게시

### 4-1. Confluence 호환 정리

`create_page.sh`와 `update_page.sh`가 MD를 Confluence storage format으로 변환하지만,
일부 MD 요소는 Confluence에서 제대로 렌더링되지 않는다. 게시 전에 임시 사본을 만들어 정리한다:

1. 원본 MD를 `/tmp/simon-publish-<timestamp>.md`로 복사
2. 아래 변환을 적용:

| 원본 요소 | 변환 |
|-----------|------|
| `:::comparison`, `:::timeline` 등 커스텀 블록 | 일반 마크다운 섹션 (헤딩 + 본문)으로 변환 |
| ` ```mermaid ` | 코드 블록으로 유지 (Confluence 코드 매크로로 렌더링됨) |
| ` ```math ` | 코드 블록으로 유지 |
| 중첩 리스트 (2단계 이상) | 1단계까지만 유지, 나머지는 들여쓰기 텍스트로 |
| `![alt](url)` 이미지 | `[alt](url)` 링크로 변환 |
| HTML 태그 | 제거 |

3. 정리된 임시 파일을 게시에 사용한다.

### 4-2. 게시 실행

**새 페이지 생성:**
```bash
~/.claude/skills/buzzvil-confluence/scripts/create_page.sh \
  --space "~5a537e6bf7743b54fe415095" \
  --title "<제목>" \
  --parent <카테고리-페이지-ID> \
  --file "/tmp/simon-publish-<timestamp>.md"
```

**기존 페이지 업데이트:**
```bash
~/.claude/skills/buzzvil-confluence/scripts/update_page.sh \
  <page-id> --file "/tmp/simon-publish-<timestamp>.md"
```

### 4-3. 정리

게시 후 임시 파일을 삭제한다:
```bash
rm -f /tmp/simon-publish-<timestamp>.md
```

---

## Phase 5: 완료 보고

게시 성공 후 다음을 출력:

> Confluence에 게시 완료
> - 카테고리: **<카테고리명>** (기존/신규)
> - 페이지: **<제목>**
> - URL: <게시된 페이지 URL>
