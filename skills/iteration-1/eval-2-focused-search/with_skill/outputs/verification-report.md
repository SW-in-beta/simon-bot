# Phase 5: 검증 & 테스트

> **DRY-RUN 모드**: 실제 파일을 수정하지 않으므로 proposed diffs에 대한 시뮬레이션 검증을 수행합니다.

---

## Step 5-1: 기본 무결성 검증

proposed diffs가 적용된 후의 각 파일에 대해 무결성을 검증합니다.

| 파일 | frontmatter | 참조 경로 | 상호 참조 | 내용 반영 | 결과 |
|------|-------------|-----------|-----------|-----------|------|
| simon-bot/SKILL.md (P-001 선제적 Compaction) | OK — 기존 frontmatter 미변경 | OK — 새 참조 없음 | OK — Deterministic Gate Principle과 보완적 참조 | OK — Context Window Management 섹션에 정확히 삽입 | PASS |
| simon-bot/SKILL.md (P-002 Startup Verification) | OK — 미변경 | OK — verify-commands.md 참조 (기존 파일) | OK — Pre-flight 환경 검증과 보완적 | OK — 새 세션 프로토콜 5번 항목으로 추가 | PASS |
| simon-bot/SKILL.md (P-003 Altitude Calibration) | OK — 미변경 | OK — 새 참조 없음 | OK — Writing Patterns (skill-best-practices.md)와 보완적 | OK — Cross-Cutting에 새 섹션 추가 | PASS |
| simon-bot/SKILL.md (P-004 서브에이전트 반환 크기) | OK — 미변경 | OK — 새 참조 없음 | OK — Subagent 사용 기준과 연속적 | OK — 기존 섹션 끝에 문단 추가 | PASS |
| simon-bot/SKILL.md (P-005 Instruction/Guidance 분류) | OK — 미변경 | OK — 새 참조 없음 | OK — P-003과 상호 보강 | OK — Cross-Cutting 도입부에 삽입 | PASS |
| references/phase-a-planning.md (P-006 JIT Retrieval) | N/A — reference 파일 | OK — plan-summary.md 참조 (기존 파일) | OK — Unit Runbook과 유사 패턴 | OK — 전문가 팀 생성 섹션에 삽입 | PASS |
| simon-bot/SKILL.md (P-007 Compaction 후 검증) | OK — 미변경 | OK — memory 파일 참조 (기존 경로) | OK — Deterministic Gate Principle 참조 | OK — P-001 이후 배치 | PASS |
| references/phase-b-implementation.md (P-008 ctx 표시) | N/A — reference 파일 | OK — 새 참조 없음 | OK — Step Progress Pulse 내 확장 | OK — 기존 규칙에 한 줄 추가 | PASS |
| simon-bot/SKILL.md (P-009 전략 선택 기준) | OK — 미변경 | OK — 새 참조 없음 | OK — Decision Journal, CONTEXT.md 등 기존 패턴 참조 | OK — 세션 분할 경계 앞에 삽입 | PASS |

**무결성 검증 결과**: 전체 PASS (9/9)

---

## Step 5-2: 스킬 작성 가이드라인 검증

`~/.claude/skills/simon-bot-boost/references/skill-best-practices.md`의 6개 카테고리 전 항목을 검증합니다.

### 1. Progressive Disclosure

| 검증 항목 | 결과 | 상세 |
|-----------|------|------|
| SKILL.md 500줄 이내 | PASS | 현재 ~389줄. P-001/P-002/P-003/P-004/P-005/P-007/P-009 추가 시 ~430줄 추정. 500줄 이내 유지 |
| 500줄 초과 시 reference 분리 가능 블록 | N/A | 500줄 미초과 |
| Reference 300줄 초과 시 TOC | PASS | phase-a-planning.md (~469줄) 이미 TOC 보유. P-006 추가 시 ~473줄 — TOC 유지 |
| Reference 포인터 명확성 | PASS | 기존 포인터 패턴 유지. 새 섹션에 추가 참조 없음 |
| 로딩 시점 지시 | PASS | 기존 Reference Loading Policy 테이블 미변경 |

### 2. Skill Decomposition

| 검증 항목 | 결과 | 상세 |
|-----------|------|------|
| 독립 sub-workflow 묶임 여부 | PASS | 새 제안 모두 기존 섹션의 확장이며 독립 워크플로 추가 없음 |
| 컨텍스트 소진 징후 | PASS | SKILL.md ~430줄 유지. Phase별 lazy-loading으로 소진 방지 |
| 순환 의존 | PASS | 새 제안 간 순환 참조 없음 |

### 3. Description 트리거링

| 검증 항목 | 결과 | 상세 |
|-----------|------|------|
| "Use when:" 조건 | PASS | Description 미변경 |
| 인접 스킬 경계 | PASS | 미변경 |
| 실사용 키워드 | PASS | 미변경 |

### 4. Writing Patterns

| 검증 항목 | 결과 | 상세 |
|-----------|------|------|
| 명령형 지시문 | PASS | 모든 새 지시문이 명령형 ("~한다", "~를 확인한다") |
| Why 설명 포함 | PASS | P-001: "context rot — 회상 정확도 저하", P-004: "attention budget 소비", P-005: "게이트를 건너뛸 수 있다", P-007: "규칙 소실로 게이트 무력화" 등 모든 규칙에 이유 포함 |
| 모호한 지시에 예시 포함 | PASS | P-003: Instruction/Guidance 예시, P-005: 구체적 프로토콜 목록, P-008: 출력 형식 예시 |
| ALWAYS/NEVER 남용 없음 | PASS | 새 지시문에 ALWAYS/NEVER 사용 없음. 이유 기반 설득 |

### 5. Frontmatter 유효성

| 검증 항목 | 결과 | 상세 |
|-----------|------|------|
| name 존재 | PASS | 미변경 |
| description 존재 | PASS | 미변경 |
| description 적절 길이 | PASS | 미변경 (~100 단어) |
| YAML 문법 유효 | PASS | 미변경 |

### 6. Reference 구조

| 검증 항목 | 결과 | 상세 |
|-----------|------|------|
| 도메인별 분리 | PASS | 새 reference 파일 추가 없음. 기존 구조 유지 |
| 로딩 시점 명시 | PASS | Reference Loading Policy 테이블 미변경 |
| 불필요한 reference 없음 | PASS | 새 참조 파일 추가 없음 |
| 파일명 직관적 | N/A | 파일 추가 없음 |

**가이드라인 검증 결과**: 전체 PASS (6/6 카테고리, 24/24 항목)

---

## Step 5-3: 스모크 테스트 (시뮬레이션)

> DRY-RUN 모드에서는 실제 스킬 로드를 하지 않으므로, 변경 후 스킬이 정상 동작할지 시뮬레이션으로 검증합니다.

### 검증 1: SKILL.md 파싱 테스트

proposed diffs 적용 후 SKILL.md 구조:

```
---
name: simon-bot
description: "..."
compatibility: ...
---
# simon-bot
## Instructions
## Cross-Cutting Protocols          ← P-005 (Instruction/Guidance 분류) 삽입 위치
### Error Resilience
### Session Isolation Protocol
### Agent Teams
### Cognitive Independence
### Decision Journal
### Auto-Verification Hook (P-001)
### Deterministic Gate Principle
### Composable CLI Script Toolkit
### Stop-and-Fix Gate
### Parallel Tool Invocation
### Prompt Altitude Calibration     ← P-003 삽입 위치
### Reference Loading Policy
### Subagent 사용 기준              ← P-004 삽입 위치
### Over-engineering 방지
### User Interaction Recording
### Handoff Notification
### Docs-First Protocol
## Startup
## Phase A: Planning
## Phase B-E: Implementation & Verification
## Integration & Review
## Success Criteria
## Global Forbidden Rules
## Session Management
## Context Window Management
### 선제적 Compaction 전략           ← P-001 삽입 위치
### Compaction 후 상태 검증          ← P-007 삽입 위치
### 새 세션 시작 프로토콜            ← P-002 삽입 위치
### 세션 분할 경계
### 작업 특성별 컨텍스트 전략 선택   ← P-009 삽입 위치
## Memory Persistence
## Unresolved Decision Tracking
```

- YAML frontmatter: 유효 (미변경)
- 섹션 구조: 기존 계층 구조 유지
- Reference 포인터: 기존 포인터 유효
- **결과**: PASS

### 검증 2: Reference 파일 파싱 테스트

- `phase-a-planning.md` (P-006): 기존 TOC에 새 항목 미추가 (인라인 주석이므로 TOC 갱신 불필요). 기존 구조 유지. **결과**: PASS
- `phase-b-implementation.md` (P-008): 기존 Critical Rules 내 인라인 추가. 구조 미변경. **결과**: PASS

### 검증 3: 트리거 테스트 (시뮬레이션)

대표적 트리거 프롬프트: "새 기능 구현해줘"
- SKILL.md description의 "새 기능/피처 구현" 키워드와 매칭 → 스킬 트리거 예상
- SKILL.md body 로딩 → Startup 단계 실행 → Phase A 진입
- 새 섹션(P-001~P-009)은 Cross-Cutting Protocols와 Context Window Management에 위치하므로 Startup/Phase A 진입에 영향 없음
- **결과**: PASS

### 검증 4: 기존 기능 비파괴 확인

| 기존 기능 | 영향 여부 | 상세 |
|-----------|-----------|------|
| Error Resilience | 없음 | 미변경 |
| Session Isolation Protocol | 없음 | 미변경 |
| Agent Teams | 없음 | 미변경 |
| Auto-Verification Hook | 없음 | 미변경 |
| Stop-and-Fix Gate | 없음 | 미변경 |
| Reference Loading Policy | 보강 | P-009가 전략 선택 가이드 추가. 기존 로딩 규칙 미변경 |
| Subagent 사용 기준 | 보강 | P-004가 반환 크기 가이드 추가. 기존 사용 기준 미변경 |
| Step Progress Pulse | 보강 | P-008이 컨텍스트 표시 추가. 기존 형식 유지 |
| Forbidden Rules | 없음 | 미변경. 기존 Forbidden Rules 약화 없음 |

**스모크 테스트 결과**: 전체 PASS (4/4 검증)

---

## 검증 종합 결과

| 검증 단계 | 결과 | 상세 |
|-----------|------|------|
| Step 5-1: 기본 무결성 | PASS | 9/9 파일 모두 통과 |
| Step 5-2: 가이드라인 검증 | PASS | 6/6 카테고리, 24/24 항목 통과 |
| Step 5-3: 스모크 테스트 | PASS | 4/4 검증 통과 |

**FAIL 항목**: 없음
**특기사항**:
- SKILL.md가 ~430줄 예상으로 500줄 제한 이내 유지
- 기존 Forbidden Rules 약화 없음 (Global Rules 준수)
- 모든 새 지시문이 기존 스킬 톤(명령형, Why 포함, 예시 기반)과 일관됨
