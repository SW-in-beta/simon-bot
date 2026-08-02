---
name: simon-boost-review
description: "축적된 스킬 개선 인사이트 리뷰 & 적용 — simon-boost-capture로 수집된 개선안을 검토하고 스킬에 반영합니다. Use when: (1) '쌓인 인사이트 리뷰하자', '개선점 확인', '캡처된 거 처리해줘', (2) simon-boost-capture 완료 후 개선안을 적용하고 싶을 때, (3) 'boost review', '인사이트 적용', '개선점 반영' 같은 표현, (4) 스킬 개선 아이디어를 모아서 한번에 처리하고 싶을 때. 캡처된 스킬 개선안을 실제로 적용하는 모든 상황에서 이 스킬을 사용하세요."
compatibility:
  tools: [Agent, AskUserQuestion]
  skills: [simon-dev, simon-grind, simon-pm, simon-report, simon-sessions, simon-company]
---

# simon-boost-review

`simon-boost-capture`로 축적된 스킬 개선 인사이트를 리뷰하고 적용하는 스킬.

캡처 단계에서 이미 분석이 완료된 인사이트를 사용자와 함께 검토하고, 승인된 개선안을 실제 스킬 파일에 반영한다. 전문가 패널 분석 없이, 이미 분석된 리포트 기반으로 빠르게 진행한다.

> **Expert Panel**: 이 스킬은 전문가 패널을 직접 실행하지 않는다 (capture 단계에서 분석 완료). 패널 구성 상세는 `~/.claude/skills/_shared/expert-panel-boost.md` 참조.

## Insights 경로

`~/.claude/boost/insights/` — simon-boost-capture와 공유하는 경로.

## Insight 파일 형식

capture가 생성하는 리포트의 구조. 이 형식을 기준으로 파싱한다.

**파일명**: `{YYYY-MM-DD}-{HHmm}-{slug}.md`

**Frontmatter** (필터링·대시보드에 사용):

```yaml
---
status: pending          # pending | applied | rejected | deferred
severity: HIGH           # CRITICAL | HIGH | MEDIUM | LOW
target_skill: simon  # 대상 스킬 이름
target_section: Step 5   # 대상 단계/섹션
captured_at: 2025-01-15T14:30:00+09:00
---
```

severity 판정 기준: `~/.claude/skills/_shared/expert-panel-boost.md`의 Proposal Severity Rubric을 따른다.

**본문 섹션**:

| 섹션 | 용도 |
|------|------|
| `# {제목}` | 대시보드 표시용 제목 |
| `## 관찰` | 세션에서 발생한 구체적 상황 |
| `## 현재 스킬 코드 분석` | 문제가 되는 스킬 코드, 파일 경로·섹션 명시 |
| `## 개선 제안` | before/after 포함 구체적 변경안 |
| `## 기대 효과` | 변경 시 예상되는 개선 |
| `## 영향 범위` | 다른 스킬·워크플로에 미치는 영향 |

**Step별 참조 방식**:
- Step 1 (로딩): frontmatter의 `status`로 필터링
- Step 2 (대시보드): frontmatter의 `severity`, `target_skill`, `captured_at` + 본문 `# 제목`
- Step 3 (리뷰): 본문 전체 (`관찰` ~ `영향 범위`)
- Step 4 (적용): `현재 스킬 코드 분석`의 파일 경로 + `개선 제안`의 변경안

## Target Skills

> **Reference Loading**: 분석 대상 목록은 `~/.claude/skills/_shared/boost-target-skills.md`를 읽는다 — 실제 대상은 `ls ~/.claude/skills/simon*/SKILL.md` 스캔이 SSoT다 (simon-boost/auto-boost와 동일, 수동 목록 drift 방지).

references/ 디렉토리의 하위 파일들과 `_shared/*.md`도 대상에 포함.

## Step 1: Pending Insights 로딩

`~/.claude/boost/insights/`에서 리포트를 읽는다.

- `status: pending` 우선
- `status: deferred`도 포함 (이전에 보류한 것)
- `status: applied` / `rejected`는 제외

인사이트가 없으면:
> 처리할 인사이트가 없습니다. 작업 중 개선점을 발견하면 simon-boost-capture로 기록해주세요.

## Step 2: 인사이트 대시보드

전체 현황을 제시:

```
## Pending Insights ({N}건)

| # | 심각도 | 대상 스킬 | 제목 | 캡처일 |
|---|--------|-----------|------|--------|
| 1 | HIGH   | simon | Step 5 테스트 탐색 실패 반복 | 2025-01-15 |
| 2 | MEDIUM | simon-pm | 태스크 분해 기준 모호 | 2025-01-14 |

어떤 인사이트부터 검토할까요? (전체 순서대로 / 번호 선택 / 심각도 높은 순)
```

## Step 3: Severity 기반 배치 리뷰

인사이트별로 **실시간 검증**을 먼저 수행한다: 대상 스킬 파일을 Read하여 리포트 작성 이후 변경이 있었는지 확인
- 이미 수정되었으면 → 안내 후 자동 기각, 다음으로
- 여전히 유효하면 → 아래 severity 기반 배치로 판단 요청

expert-panel-boost.md의 Proposal Severity Rubric 기준:
- **CRITICAL / HIGH / 전문가 간 이견 항목** → 하나씩 인사이트 리포트 전체(관찰, 분석, 제안)를 상세히 제시하고 개별 확인
- **MEDIUM** → 클러스터(주제) 단위로 묶어 요약 설명 후 일괄 확인 — 클러스터 내 취사선택 가능
- **LOW + 전문가 전원 동의** → 자동 적용하고 최종 요약에서 사후 보고 (사용자가 이의 시 롤백)
- 확인 질문은 AskUserQuestion으로 수행

**판단 옵션:**
- **적용**: 제안대로 (또는 수정 후) 적용
- **보류**: 나중에 다시 (`status: deferred`)
- **기각**: 불필요 (`status: rejected`, 사유 기록)

## Step 4: Apply

적용 대상 인사이트를 모아 스킬 파일에 반영한다.

**4-A: 변경 계획**
- 같은 파일에 대한 여러 인사이트는 한 번에 적용
- 변경 순서: references/ → SKILL.md (의존성 방향)

**4-B: 변경 미리보기**

각 파일의 변경 사항을 사용자에게 보여준다:

```
~/.claude/skills/simon-dev/SKILL.md
  - Line 58: Step 1-A에 새로운 분석 항목 추가

~/.claude/skills/simon-dev/references/phase-b-implementation.md
  - Section "Step 5": 검증 게이트 강화
```

사용자 승인 후 Edit 도구로 적용.

**4-C: 변경 기록**

`~/.claude/boost/applied-log.md`에 기록:

```markdown
## [YYYY-MM-DD] Insight Review
- **I-001**: {제목} → 적용 (simon SKILL.md)
- **I-002**: {제목} → 기각 (이유: ...)
```

## Step 5: Verification

변경된 모든 파일에 대해 검증:

1. **기본 무결성**: YAML frontmatter, reference 경로, 스킬 간 상호 참조
2. **내용 반영 확인**: Read로 재확인하여 의도대로 반영되었는지

FAIL 항목이 있으면 즉시 수정.

## Step 6: Status Update & Summary

1. 처리된 인사이트 파일의 frontmatter `status` 업데이트:
   - 적용 → `applied`
   - 보류 → `deferred`
   - 기각 → `rejected`

2. 최종 요약:

```
## Review Complete

**처리**: {N}건
- 적용: {N}건
- 보류: {N}건
- 기각: {N}건

### 적용된 변경
- simon: {변경 요약}
- ...

### 남은 pending
- {N}건 (다음 리뷰에서 처리)
```

## Rules

- 스킬 파일 수정 시 Read → Edit 순서 (Write 덮어쓰기 금지)
- 사용자 확인 없이 스킬 파일을 수정하지 않음
- 기존 스킬의 Global Forbidden Rules는 절대 약화시키지 않음
- 변경 기록(applied-log.md)은 항상 유지
- 인사이트 리포트의 status는 처리 후 반드시 업데이트
