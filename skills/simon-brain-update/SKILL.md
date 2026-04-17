# simon-brain-update

simon* 스킬이 생성한 MD 파일을 받아, 내용 기반으로 적합한 vault를 자동 판별하고 `raw/`에 복사한 뒤 wiki를 업데이트한다.

## Trigger

- `/simon-brain-update {파일경로}` — 특정 파일을 brain에 업데이트
- simon-md-reviewer에서 "확정" 후 자동 호출 (파이프라인 연동)
- `/simon-brain-update` (경로 없음) — 최근 claude-reports/ 파일 목록 제시 후 선택

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

### Step 1: 파일 읽기

대상 MD 파일을 Read 도구로 읽는다.

### Step 2: Vault 판별 (중복 허용)

1. `ls -d ~/Obsidian/*-wiki/`로 활성 vault 목록을 감지한다
2. 각 vault의 `CLAUDE.md`를 읽어 도메인 태그와 카테고리를 파악한다
3. 파일 내용과 각 vault의 도메인을 대조하여 매칭 판별한다

판별 기준은 각 vault CLAUDE.md의 "Domain Tags" 섹션에서 동적으로 가져온다. 새 vault가 추가되면 그 vault의 CLAUDE.md에 정의된 태그가 자동으로 판별 기준에 포함된다.

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

어떤 방식을 원하시나요?
```

**판별 결과 통보:**
```
[Brain Update] 판별 결과:
- ✅ buzzvil-wiki (시그널: DDD, lineitem, adserver)
- ✅ ai-wiki (시그널: Claude Code, CLAUDE.md)
- ❌ infra-wiki

변경하려면 알려주세요. 그대로 진행합니다.
```

### Step 3: raw/ 복사

판별된 각 vault의 `raw/`에 파일을 복사한다.

```bash
# 파일명 결정: 원본 파일명 유지 (타임스탬프 suffix 추가하여 중복 방지)
TIMESTAMP=$(date +%Y%m%d)
BASENAME=$(basename "$FILE_PATH" .md)
DEST_NAME="${BASENAME}-${TIMESTAMP}.md"

# 각 vault에 복사
cp "$FILE_PATH" "$VAULT/raw/$DEST_NAME"
```

**중복 감지**: 같은 날 같은 이름의 파일이 이미 raw/에 있으면 덮어쓰지 말고 사용자에게 알린다.

### Step 3-B: 기존 지식과 충돌 감지

ingest 전에, 새 문서가 기존 wiki와 충돌하는지 확인한다. 이 단계가 중요한 이유: 잘못된 정보가 wiki에 들어가면 이후 brain-query 결과의 신뢰도가 떨어진다.

**감지 방법:**
1. Grep 도구로 새 문서의 핵심 키워드를 해당 vault의 `wiki/`에서 검색
2. 매칭되는 기존 문서가 있으면 읽고 비교
3. 충돌 유형 판별:

**충돌 유형별 처리:**

| 유형 | 설명 | 처리 |
|------|------|------|
| **내용 보강** | 기존 문서에 새 정보 추가 | 자동으로 기존 문서 업데이트 |
| **수치/팩트 차이** | 같은 주제지만 숫자·결론이 다름 | 사용자에게 판단 요청 |
| **완전 중복** | 이미 동일 내용이 위키에 있음 | 사용자에게 알리고 skip 제안 |
| **관점 차이** | 같은 주제의 다른 분석 | 양쪽 모두 유지, 모순 표시 |

**수치/팩트 차이 발견 시:**
```
[충돌 감지] buzzvil-wiki/wiki/adserver/cpa-conversion-flow.md와 내용 차이 발견:

기존: "CPA 전환 이벤트는 3개 경로로 수신된다 (Web, SDK, MMP)"
신규: "CPA 전환 이벤트는 4개 경로로 수신된다 (Web, SDK, MMP, S2S Direct)"

어떻게 처리할까요?
  A) 신규 내용으로 기존 문서 업데이트
  B) 기존 내용 유지, 신규 문서는 보강 정보만 추가
  C) 양쪽 모두 기록 + [이견] 표시
```

### Step 4: Ingest 실행

**역할 분리**: LLM은 판단이 필요한 작업(문서 작성, 카테고리 판별, wikilinks 결정)만 수행하고, 기계적인 인덱싱은 스크립트가 처리한다.

각 vault에 대해 순차 실행:

**LLM이 하는 것 (판단 필요):**
1. 해당 vault의 CLAUDE.md 읽기
2. raw/{파일명} 읽기
3. 카테고리 판별
4. `wiki/{category}/{slug}.md` 생성 또는 업데이트 (YAML 프론트매터 포함)
5. 관련 문서에 `[[wikilinks]]` 추가
6. `log.md`에 append

**스크립트가 하는 것 (결정론적):**
```bash
python3 ~/.claude/skills/simon-brain-update/scripts/index-kb.py ~/Obsidian/{vault-name}
```
이 스크립트가 wiki/ 디렉토리를 스캔하여 INDEX.md, TAGS.md, GRAPH.md를 **100% 정확하게** 재생성한다. LLM이 이 3개 파일을 직접 편집하는 것은 **금지**한다.

**스크립트 전체 vault 일괄 실행:**
```bash
python3 ~/.claude/skills/simon-brain-update/scripts/index-kb.py
# 인자 없으면 ~/Obsidian/*-wiki/ 전체 처리
```

### Step 5: 완료 리포트

```
[Dispatch 완료]
파일: {원본 파일명}

buzzvil-wiki:
  - raw/에 저장: {파일명}
  - 생성된 wiki 문서: adserver/lineitem-xxx.md (신규)
  - 업데이트된 wiki 문서: adserver/ddd-patterns.md (+2 [[wikilinks]])
  - INDEX.md: 1개 행 추가
  - 처리 시간: ~2분

ai-wiki:
  - raw/에 저장: {파일명}
  - 생성된 wiki 문서: tools/claude-code-skills.md (신규)
  - INDEX.md: 1개 행 추가
```

## 사용 예시

```bash
# simon-report 결과물 brain에 업데이트
/simon-brain-update ~/claude-reports/simon-report-adserver-ddd.md

# simon-study 결과물 brain에 업데이트
/simon-brain-update ~/claude-reports/simon-study-claude-tool-use.md

# 최근 파일 목록에서 선택
/simon-brain-update
```

## 연동: simon-md-reviewer

simon-md-reviewer의 Phase 4 "확정" 후 자동으로 이 스킬을 호출하려면:
- simon-md-reviewer Phase 4에서 `/simon-brain-update {파일경로}` 제안
- 사용자가 "brain에 업데이트해줘" 또는 "yes"라고 하면 실행
