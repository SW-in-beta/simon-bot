# Phase 5: 검증 & 테스트

DRY-RUN 모드이므로 실제 파일 수정 없이, 제안된 변경이 적용되었다고 가정하고 검증 항목을 실행한다.

## Step 5-1: 기본 무결성 검증

변경 대상 파일에 대해 YAML frontmatter, 참조 경로, 상호 참조, 내용 반영을 검증한다.

### 검증 대상 파일

| 파일 | frontmatter | 참조 경로 | 상호 참조 | 내용 반영 | 결과 |
|------|-------------|-----------|-----------|-----------|------|
| simon-bot/SKILL.md | OK (변경 없음) | OK — `references/cross-cutting-protocols.md` 신규 경로 추가, 기존 reference 경로 유지 | OK — grind, pm, sessions 상호 참조 무변경 | OK — P-005 Protocol Recall + P-007 분리 포인터 반영 | PASS |
| simon-bot/references/phase-a-planning.md | N/A | OK — 기존 참조 유지 | N/A | OK — P-002 Example File Paths 추가 | PASS |
| simon-bot/references/phase-b-implementation.md | N/A | OK — 기존 참조 유지 | N/A | OK — P-006 Phase-level Progress Report 추가 | PASS |
| simon-bot/references/docs-first-protocol.md | N/A | OK — 외부 참조 없음 | N/A | OK — P-003 Unknown Escalation 수정 | PASS |
| simon-bot/references/cross-cutting-protocols.md (신규) | N/A | OK — SKILL.md에서 참조 | OK — Error Resilience → error-resilience.md 등 기존 참조 유지 | OK — SKILL.md에서 이동된 내용 | PASS |
| simon-bot-grind/SKILL.md | OK (변경 없음) | OK — 기존 grind-cross-cutting.md 참조 유지 | OK — simon-bot 참조 무변경 | N/A (직접 변경 없음) | PASS |
| simon-bot-grind/references/grind-cross-cutting.md | N/A | OK — 기존 참조 유지 | N/A | OK — P-001 Direction Validation + P-004 Problem Redefinition 추가 | PASS |

### 검증 결과 요약

- PASS: 7/7 파일
- FAIL: 0
- 특이사항: 없음

---

## Step 5-2: 스킬 작성 가이드라인 검증

`~/.claude/skills/simon-bot-boost/references/skill-best-practices.md` 로딩 완료.

### simon-bot SKILL.md (변경 적용 후 가정)

변경 후 예상 줄 수: 389줄 → ~250줄 (P-007 Cross-Cutting 분리 시)

| 카테고리 | 항목 | 결과 | 비고 |
|----------|------|------|------|
| Progressive Disclosure | SKILL.md 500줄 이내 | PASS (~250줄) | P-007 분리 후 대폭 감소 |
| Progressive Disclosure | Reference 300줄 초과 시 TOC | PASS | cross-cutting-protocols.md ~160줄, TOC 불필요 |
| Progressive Disclosure | Reference 포인터 명확 | PASS | "Startup 시 읽기" 로딩 시점 명시 |
| Progressive Disclosure | 로딩 시점 지시 | PASS | Phase별 reference 로딩 정책 유지 |
| Skill Decomposition | 독립 sub-workflow 묶임 여부 | PASS | 19-step pipeline은 긴밀한 파이프라인 |
| Skill Decomposition | 컨텍스트 소진 징후 | PASS | 세션 분할 경계 3곳 정의됨 |
| Skill Decomposition | 순환 의존 | PASS | simon-bot → simon-bot-review 단방향 |
| Description 트리거링 | "Use when:" 조건 | PASS | 4개 트리거 조건 명시 |
| Description 트리거링 | 인접 스킬 경계 구분 | PASS | "코드 변경이 수반되는" 조건으로 report와 구분 |
| Description 트리거링 | 실사용 키워드 | PASS | "피처 구현해줘", "새 기능 만들어줘" 등 포함 |
| Writing Patterns | 명령형 | PASS | "~한다", "~를 실행한다" 형식 일관 |
| Writing Patterns | Why 설명 | PASS | P-005에 "압축 과정에서 규칙이 약화될 수 있기 때문" 등 이유 포함 |
| Writing Patterns | 예시 포함 | PASS | Decision Journal 예시 4개, Progress Report 형식 예시 |
| Writing Patterns | ALWAYS/NEVER 남용 | PASS | 이유 기반 설명으로 전환 완료 (이전 boost에서) |
| Frontmatter 유효성 | name/description 존재 | PASS | |
| Frontmatter 유효성 | description 길이 | PASS | ~100단어 |
| Frontmatter 유효성 | compatibility 정확 | PASS | [Agent, AskUserQuestion, TeamCreate, SendMessage] |
| Frontmatter 유효성 | YAML 문법 | PASS | |
| Reference 구조 | 도메인별 분리 | PASS | phase-a, phase-b, error-resilience 등 |
| Reference 구조 | 로딩 시점 명시 | PASS | Reference Loading Policy 테이블 유지 |
| Reference 구조 | 불필요 파일 없음 | PASS | 모든 reference가 SKILL.md에서 참조됨 |
| Reference 구조 | 300줄 초과 시 TOC | PASS | phase-a-planning.md에 이미 TOC 있음 (이전 boost에서 추가) |

### simon-bot-grind SKILL.md

| 카테고리 | 항목 | 결과 | 비고 |
|----------|------|------|------|
| Progressive Disclosure | SKILL.md 500줄 이내 | PASS (184줄) | 변경 없음 |
| Progressive Disclosure | Reference 포인터 명확 | PASS | |
| Skill Decomposition | 독립 sub-workflow 묶임 | PASS | simon-bot 기반 확장, 독립적이지 않음 |
| Skill Decomposition | 순환 의존 | PASS | grind → simon-bot 단방향 |
| Description 트리거링 | "Use when:" 조건 | PASS | 3개 트리거 조건 |
| Description 트리거링 | 인접 스킬 경계 | PASS | "simon-bot보다 더 강력한 자동 복구" |
| Writing Patterns | 명령형 | PASS | |
| Writing Patterns | Why 설명 | PASS | "같은 접근법의 무의미한 반복을 방지한다" 등 |
| Frontmatter 유효성 | 전체 | PASS | |
| Reference 구조 | 전체 | PASS | grind-cross-cutting.md에 TOC 존재 |

### 검증 결과 요약

- 전체 PASS: 모든 카테고리, 모든 항목
- FAIL: 0건
- 잠재 주의사항: cross-cutting-protocols.md 신규 파일 생성 시 기존 SKILL.md에서 Reference Loading Policy 테이블에 해당 파일 추가 필요 → P-007 diff에 이미 포함됨

---

## Step 5-3: 스모크 테스트

DRY-RUN 모드이므로 실제 스킬 트리거 테스트는 수행하지 않는다. 대신 제안된 변경이 기존 트리거/파싱/로딩 흐름을 깨뜨리지 않는지 정적 분석으로 확인한다.

### simon-bot 스모크 테스트 (정적)

| 검증 항목 | 결과 | 비고 |
|-----------|------|------|
| SKILL.md YAML frontmatter 파싱 가능 | PASS | frontmatter 변경 없음 |
| description 트리거 정상 | PASS | description 변경 없음 |
| Phase A 레퍼런스 로딩 지시 정상 | PASS | phase-a-planning.md 경로 변경 없음 |
| Phase B-E 레퍼런스 로딩 지시 정상 | PASS | phase-b-implementation.md 경로 변경 없음 |
| Cross-Cutting Protocols 접근 가능 | PASS | Startup에서 cross-cutting-protocols.md 로딩 지시 추가 |
| Startup 실행 흐름 변경 없음 | PASS | Startup Steps 1-5 순서 유지 |

### simon-bot-grind 스모크 테스트 (정적)

| 검증 항목 | 결과 | 비고 |
|-----------|------|------|
| SKILL.md YAML frontmatter 파싱 가능 | PASS | frontmatter 변경 없음 |
| Base workflow 참조 (simon-bot SKILL.md) | PASS | 경로 변경 없음 |
| grind-cross-cutting.md 추가 내용 접근 | PASS | 기존 파일에 섹션 추가 |
| Grind Config Overrides 정상 | PASS | 변경 없음 |

### 최종 검증 결과

| 스킬 | 무결성 | 가이드라인 | 스모크 | 종합 |
|------|--------|-----------|--------|------|
| simon-bot | PASS (5파일) | PASS (22항목) | PASS (6항목) | **PASS** |
| simon-bot-grind | PASS (2파일) | PASS (10항목) | PASS (4항목) | **PASS** |

모든 검증 통과. FAIL 항목 없음.
