---
name: simon-brain-query
description: 개인 지식 베이스(Obsidian wiki vault) 통합 검색. ~/Obsidian/*-wiki/ 패턴의 모든 vault를 동적으로 감지하여 질문에 답변합니다. '내 위키에서 찾아줘', '브레인에 물어봐', 'brain query', '지식베이스 검색', '위키 검색', '내가 정리한 거에서', '예전에 정리했던', '이전에 공부했던' 같은 요청에 사용하세요. simon-oncall, simon-study, simon-dev 등 다른 스킬이 사전 지식을 조회할 때도 이 스킬의 검색 로직을 활용할 수 있습니다.
---

# simon-brain-query

Obsidian wiki vault들을 통합 검색하여 사전에 축적된 지식으로 질문에 답변한다.

vault 목록은 하드코딩하지 않는다. `~/Obsidian/*-wiki/` 글로브 패턴으로 매번 동적 감지하므로, vault가 추가되거나 삭제되어도 자동 반영된다.

## Trigger

- `/simon-brain-query {질문}` — 직접 호출
- `/simon-brain-query` (질문 없음) — 무엇을 검색할지 질문
- 다른 스킬에서 사전 지식 조회 시 내부적으로 검색 로직 참조

## Instructions

### Step 1: Vault 동적 감지

```bash
ls -d ~/Obsidian/*-wiki/ 2>/dev/null
```

감지된 vault 목록을 통보한다:

```
[Brain] 활성 vault 감지:
- buzzvil-wiki (320 documents)
- ai-wiki (5 documents)
- infra-wiki (0 documents)
```

문서 수는 각 vault의 `wiki/INDEX.md`에서 `> **N documents**` 패턴으로 추출한다.

vault가 0개면: "활성 vault가 없습니다. ~/Obsidian/ 아래에 *-wiki 디렉토리를 생성하세요."

### Step 2: 키워드 추출 및 검색

질문에서 핵심 키워드를 추출하고, 두 단계로 검색한다.

**2-A: INDEX.md + TAGS.md 스캔 (빠른 매칭)**

각 vault의 `wiki/INDEX.md`와 `wiki/TAGS.md`를 읽고 질문 키워드와 매칭되는 문서를 식별한다. INDEX.md는 테이블 형식이므로 Keywords 컬럼을 중심으로 스캔한다.

이 단계에서 관련 vault와 후보 문서 목록을 파악한다.

**2-B: ripgrep 심층 검색 (INDEX에 없는 경우)**

INDEX.md 매칭이 불충분하면 ripgrep으로 wiki/ 내부를 직접 검색한다:

```bash
# 각 vault에서 키워드 검색
rg -l "keyword1|keyword2" ~/Obsidian/{vault-name}/wiki/ --type md
```

Grep 도구를 사용하여 검색한다 (bash의 rg 대신).

### Step 3: 관련 문서 읽기

후보 문서들을 읽되, 효율을 위해 다음 순서를 따른다:

1. 가장 관련도 높은 문서 2-3개를 먼저 읽기
2. 그 문서의 `[[wikilinks]]`를 따라가며 추가 관련 문서 확인
3. 필요하면 추가 문서를 더 읽기 (최대 5-7개)

### Step 4: 크로스-vault 연결 감지

여러 vault에서 관련 문서를 찾았으면, vault 간 연결을 명시한다.

예시:
```
[Cross-vault] buzzvil-wiki의 "ArgoCD 배포 절차"와 
              infra-wiki의 "Kubernetes Deployment 개념"이 연결됩니다.
```

이 연결 정보는 각 vault의 `wiki/GRAPH.md`도 참조하여 보강한다.

### Step 5: 합성 답변

검색 결과를 바탕으로 질문에 답변한다. 답변에는 반드시 출처를 명시한다:

```
[답변 내용]

---
출처:
- buzzvil-wiki: adserver/multi-reward-api-architecture.md
- buzzvil-wiki: adserver/cpa-conversion-event-routing.md  
- infra-wiki: kubernetes/deployment-strategies.md
```

**답변이 불충분할 때**: 위키에서 충분한 정보를 찾지 못했으면 솔직히 밝히고, 어떤 vault에서 어떤 키워드로 검색했는지 알려준다.

### Step 6: 가치 있는 합성 저장 제안

답변이 여러 소스를 종합한 가치 있는 합성이면, 해당 vault의 `wiki/synthesis/`에 저장할지 **제안**한다 (자동 저장하지 않음):

```
이 답변은 3개 소스를 종합한 합성입니다.
buzzvil-wiki/wiki/synthesis/multireward-conversion-flow.md로 저장할까요?
```

사용자가 동의하면 저장하고 INDEX.md를 갱신한다.

## 다른 스킬에서의 활용

simon-oncall, simon-study, simon-dev 등이 작업 시작 전 사전 지식을 조회하려면, 이 스킬의 Step 1~4를 참조하여 관련 vault를 검색한다. 별도 스킬 호출 없이 같은 검색 패턴을 사용하면 된다:

```
1. ls -d ~/Obsidian/*-wiki/ 로 vault 감지
2. 관련 vault의 INDEX.md에서 키워드 매칭
3. 후보 문서 읽기
4. 사전 지식으로 활용
```

## 사용 예시

```bash
# 직접 질문
/simon-brain-query biddersvc의 AdvancedBid에서 multi-reward 처리 흐름은?

# 키워드 검색
/simon-brain-query CKA 시험에서 자주 나오는 NetworkPolicy 문제

# 크로스-도메인 질문
/simon-brain-query ArgoCD 롤링 업데이트와 K8s deployment strategy 비교

# vault 상태 확인
/simon-brain-query
```
