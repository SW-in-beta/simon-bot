# simon-brain-update

simon* 스킬 결과물이나 웹 URL을 받아, 내용 기반으로 적합한 vault를 자동 판별하고 `raw/`에 원본을 저장한 뒤 wiki로 정제한다.

## Trigger

- `/simon-brain-update {파일경로}` — 로컬 MD 파일 처리
- `/simon-brain-update {URL}` — 단일 웹 URL 처리 (공식 문서, 블로그, 기술 아티클)
- `/simon-brain-update` — 최근 claude-reports/ 파일 목록 제시
- 대화 중 여러 URL/파일 리스트가 주어지면 대량 처리(Bulk) 모드로 전환

## 입력 형태

| 타입 | 예시 | Step 1 처리 |
|------|------|-------------|
| A. 로컬 MD | `~/claude-reports/report.md` | Read |
| B. 단일 URL | `https://claude.com/blog/...` | WebFetch → raw/에 저장 |
| C. URL 리스트 | 여러 URL (5+ 개) | 서브에이전트 분산 수집 |

## Vault 감지

vault 목록은 하드코딩하지 않는다. 매번 동적으로 감지한다:

```bash
ls -d ~/Obsidian/*-wiki/ 2>/dev/null
```

각 vault의 `CLAUDE.md`를 읽어 도메인과 시그널 키워드를 파악한다. vault가 추가·삭제되어도 자동 반영.

## Instructions

### Step 0: 업로드 의사 확인

**이 스킬은 사용자의 명시적 요청 없이 자동 실행하지 않는다.**

다른 스킬(simon-md-reviewer 등) 완료 후에도 brain 업데이트는 **제안만** 한다:
```
리뷰가 완료되었습니다. 이 문서를 brain에 업데이트할까요? (/simon-brain-update)
```
사용자가 "yes", "업데이트해줘", "brain에 넣어줘" 등으로 동의하면 진행한다.

### Step 1: 입력 수집

입력 타입에 따라 분기:

**Type A (로컬 MD)**: Read 도구로 파일 내용을 읽는다.

**Type B (웹 URL)**: WebFetch로 원본 markdown을 수집한다.
- prompt: "Return the full document verbatim as plain markdown. Do not summarize, translate, or truncate. Preserve all code blocks, tables, frontmatter exactly as-is."
- 리다이렉트 발생 시 대상 URL 재fetch. 메타에 "Redirected from: {original URL}" 표기.
- raw/ 저장 규칙은 Step 3 참조.

**Type C (URL 리스트, 5+)**:
- 20~30개 단위로 묶어 병렬 서브에이전트에 분산 (Phase 1: 원본 수집만)
- 각 서브에이전트는 raw/에 원본 저장만 담당. 번역·요약 금지.
- 전부 수집된 후 Step 2~4 진행 (Phase 2: wiki 정제)

### Step 2: Vault 판별 (중복 허용)

1. `ls -d ~/Obsidian/*-wiki/`로 활성 vault 목록을 감지한다
2. 각 vault의 `CLAUDE.md`를 읽어 도메인 태그와 카테고리를 파악한다
3. 파일 내용 (또는 URL 도메인 + 제목)과 각 vault의 도메인을 대조하여 매칭 판별한다

판별 기준은 각 vault CLAUDE.md의 "Domain Tags" 섹션에서 동적으로 가져온다.

**매칭 없음 (시그널 감지 실패 시):**

어떤 vault에도 시그널이 감지되지 않으면:
1. 문서 주제를 1줄로 요약
2. 가장 근접한 vault + 해당 vault 내 새 카테고리 추가 제안
3. 또는 새 vault 생성 제안
4. 사용자가 선택 후 진행

```
[Dispatch] 기존 vault에 맞는 시그널을 찾지 못했습니다.
주제: "React Server Components와 서버 사이드 렌더링 패턴"

제안:
  A) ai-wiki에 새 카테고리 "frontend-patterns/" 추가 후 저장
  B) 새 vault "frontend-wiki" 생성
  C) 직접 vault과 카테고리 지정
```

**판별 결과 통보:**
```
[Brain Update] 판별 결과:
- ✅ buzzvil-wiki (시그널: DDD, lineitem, adserver)
- ✅ ai-wiki (시그널: Claude Code, CLAUDE.md)
- ❌ infra-wiki

변경하려면 알려주세요. 그대로 진행합니다.
```

### Step 3: raw/ 저장

판별된 각 vault의 `raw/`에 원본을 저장한다.

**로컬 파일 네이밍**: `{basename}-{YYYYMMDD}.md`

**웹 URL 네이밍**: `{source-prefix}-{type}-{slug}.md`

| 소스 | prefix | 예시 |
|------|--------|------|
| code.claude.com/docs (Claude Code 공식 문서) | `cc-doc-` | `cc-doc-memory.md` |
| code.claude.com/docs/agent-sdk (SDK) | `cc-doc-sdk-` | `cc-doc-sdk-overview.md` |
| claude.com/blog (Claude Code 관련) | `cc-blog-` | `cc-blog-session-management.md` |
| claude.com/blog (기타 제품/사용 사례) | `claude-blog-` | `claude-blog-advisor-strategy.md` |
| anthropic.com/engineering | `engr-` | `engr-building-effective-agents.md` |
| 기타 도메인 | `{domain-abbr}-{type}-` | 사용자와 확정 |

**파일 최상단 메타**:
```
> **Source:** {URL} · Fetched: YYYY-MM-DD
---
```
그 아래 원본 내용 전체.

**불변 원칙**: raw 파일은 절대 수정·번역·요약하지 않는다. 한국어 변환은 Step 4에서 wiki를 만들 때만 수행한다.

**중복 감지**: 같은 이름 파일이 이미 raw/에 있으면 덮어쓰지 말고 사용자에게 알린다.

### Step 3-B: 기존 지식과 충돌 감지

ingest 전에, 새 문서가 기존 wiki와 충돌하는지 확인한다.

**감지 방법**:
1. Grep으로 새 문서의 핵심 키워드를 해당 vault의 `wiki/`에서 검색
2. 매칭되는 기존 문서가 있으면 읽고 비교
3. 충돌 유형 판별:

| 유형 | 설명 | 처리 |
|------|------|------|
| **내용 보강** | 기존 문서에 새 정보 추가 | 자동으로 기존 문서 업데이트 |
| **수치/팩트 차이** | 같은 주제지만 숫자·결론이 다름 | 사용자에게 판단 요청 |
| **완전 중복** | 이미 동일 내용이 위키에 있음 | 사용자에게 알리고 skip 제안 |
| **관점 차이** | 같은 주제의 다른 분석 | 양쪽 모두 유지, 모순 표시 |

### Step 4: Ingest 실행 (raw → wiki)

**필수 첫 단계**: 해당 vault의 `CLAUDE.md`를 반드시 읽어 카테고리 체계·네이밍 규칙·규정 태그를 파악한다. 카테고리는 임의 생성 금지.

**역할 분리**: LLM은 판단이 필요한 작업만 수행하고, 기계적인 인덱싱은 스크립트가 처리한다.

**LLM이 하는 것 (판단 필요)**:
1. vault의 `CLAUDE.md` 읽기 (카테고리 목록, 문서 포맷, 네이밍 규칙 확인)
2. raw/{파일명} 읽기
3. 카테고리 판별 — CLAUDE.md의 공식 카테고리 중 선택. 새 카테고리가 필요하면 **먼저 사용자 확인 후 CLAUDE.md를 업데이트**한다.
4. 파일명 규칙:
   - 기본: `wiki/{category}/{slug}.md`
   - 한 카테고리에 대량(10+) 동일 프로덕트 문서가 쌓이는 경우: prefix로 구분 (예: `wiki/tools/cc-{slug}.md`)
   - 서브디렉토리는 CLAUDE.md에 명시된 경우에만 허용
5. YAML 프론트매터 필수 (CLAUDE.md 포맷 따름)
6. 관련 문서에 `[[wikilinks]]` 추가
7. `log.md`에 한 줄 추가

**금지**:
- CLAUDE.md를 읽지 않고 임의 카테고리 생성
- 서브디렉토리 무단 생성
- raw/ 파일 편집

**스크립트가 하는 것 (결정론적)**:
```bash
python3 ~/.claude/skills/simon-brain-update/scripts/index-kb.py ~/Obsidian/{vault-name}
# 인자 없으면 ~/Obsidian/*-wiki/ 전체 처리
```
이 스크립트가 wiki/ 디렉토리를 스캔하여 INDEX.md, TAGS.md, GRAPH.md를 재생성한다. LLM이 이 3개 파일을 직접 편집하는 것은 **금지**한다.

### Step 5: 완료 리포트

```
[Dispatch 완료]
입력: {파일경로 또는 URL}

{vault-name}:
  - raw/에 저장: {파일명}
  - 생성된 wiki 문서: {category}/{slug}.md (신규)
  - 업데이트된 wiki 문서: {category}/{other}.md (+2 [[wikilinks]])
  - INDEX.md: 1개 행 추가
  - 처리 시간: ~2분
```

## 대량 처리 (Bulk Mode)

10개 이상의 URL·파일을 한 번에 처리할 때 엄수할 흐름:

1. **사전 범위 확정**: 포함/제외할 URL 목록을 사용자와 확정
2. **네이밍 컨벤션 확정**: Step 3 prefix 테이블 준수. 새 prefix는 사용자 승인 필요
3. **Phase 1 — 원본 수집**: 20~30개씩 서브에이전트 분산. 각 에이전트는 raw/에 저장만 담당 (번역·요약 금지)
4. **Phase 1 완료 확인**: 모든 raw 파일 생성 확인
5. **Phase 2 — wiki 정제**: 각 raw를 읽어 CLAUDE.md 카테고리에 맞는 wiki 문서 생성 (서브에이전트 분산 가능)
6. **최종**: `index-kb.py` 한 번만 실행

Phase 1과 Phase 2를 **섞지 않는다**. 원본 보존이 먼저, 정제가 나중이다.

## 사용 예시

```bash
# 로컬 simon-report 결과
/simon-brain-update ~/claude-reports/simon-report-adserver-ddd.md

# 단일 URL
/simon-brain-update https://claude.com/blog/building-effective-agents

# 최근 파일 목록에서 선택
/simon-brain-update

# 대량 처리 (대화 중 URL 리스트 제공)
"이 10개 블로그 URL을 전부 brain에 넣어주세요: ..."
```

## 연동: simon-md-reviewer

simon-md-reviewer의 Phase 4 "확정" 후 자동으로 이 스킬을 호출하려면:
- simon-md-reviewer Phase 4에서 `/simon-brain-update {파일경로}` 제안
- 사용자가 "brain에 업데이트해줘" 또는 "yes"라고 하면 실행
