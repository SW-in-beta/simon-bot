# Simulated Edits — Prompt Engineering Overview Boost

이 파일은 실제 스킬 파일을 수정하지 않고, 적용할 변경사항을 시뮬레이션한 기록입니다.

---

## Edit 1: simon-bot/references/agent-teams.md — P-001 적용

**위치**: 줄 27 이후 ("최종 결과물 경로와 형식을 지정" 다음)

**추가할 내용**:

```markdown
### XML 태그 구조화 패턴 (권장)

에이전트에게 복잡한 지시를 전달할 때, 역할/컨텍스트/지시를 XML 태그로 구분하면 Claude가 각 영역의 경계를 명확히 인식하여 역할 준수율이 향상된다. Anthropic의 프롬프트 엔지니어링 가이드에서 "XML tags help Claude parse complex prompts unambiguously"라고 권고한다.

**패턴:**

```
<role>보안 전문가. 코드의 보안 취약점을 식별하고 개선안을 제시한다.</role>
<context>
- Step 7에서 구현 완료된 코드를 검증하는 단계
- plan-summary.md와 실제 코드를 교차 확인
- 변경된 파일만 대상 (git diff 기반)
</context>
<instructions>
1. 입력 검증 누락 확인
2. SQL injection 위험 점검
3. findings를 CRITICAL/HIGH/MEDIUM으로 분류하여 기록
</instructions>
```

**적용 기준:**
- 에이전트 역할이 복잡하거나 컨텍스트가 많을 때 사용
- 단순 1줄 역할 정의는 기존 자연어 방식으로 충분
- `<role>`, `<context>`, `<instructions>` 태그 이름을 일관되게 사용
```

---

## Edit 2: simon-bot/references/phase-b-implementation.md — P-002 적용

**위치**: 줄 138 ("Auto-Verification Hook" 항목) 이후, Critical Rules 섹션 내

**추가할 내용**:

```markdown
- **Step Self-check**: 각 Step 완료 전, 해당 Step의 목표(SKILL.md Phase B-E 요약 테이블의 "핵심" 열)를 다시 확인하고, 결과가 목표에 부합하는지 1줄 판단을 decision-journal.md에 기록한다. 부합하지 않으면 수정 후 다음 Step으로 진행한다. Auto-Verification Hook이 기계적 정합성(빌드/린트)을 검증한다면, Self-check는 논리적 정합성(의도 대비 결과)을 검증한다.
```

---

## Edit 3: simon-bot/SKILL.md — P-001 참조 추가

**위치**: 줄 71 ("Parallel Tool Invocation" 섹션) 전

**추가할 내용**:

```markdown
### Agent Role Definition (XML 태그 구조화)

복잡한 역할의 에이전트를 spawn할 때, `<role>`, `<context>`, `<instructions>` XML 태그로 지시를 구분한다. Claude가 역할/컨텍스트/지시 경계를 명확히 인식하여 준수율이 높아진다. 상세 패턴은 [agent-teams.md](references/agent-teams.md)의 "XML 태그 구조화 패턴" 섹션 참조.
```

---

## Edit 4: simon-bot/SKILL.md — P-003 적용 (frontmatter description 완화)

**위치**: 줄 3 (frontmatter description)

**변경 전**:
```yaml
description: "19-step 딥 워크플로 — 계획, 구현, 검증을 최고 수준의 엄격함으로 수행합니다. Use when: (1) 새 기능/피처 구현 (\"피처 구현해줘\", \"새 기능 만들어줘\", \"코드 작성해줘\"), (2) 전문가 리뷰 패널이 필요한 체계적 계획 수립, (3) git worktree 기반 병렬 실행, (4) PR 전 종합 코드 검증이 필요할 때. 코드 변경이 수반되는 모든 중대한 작업에 이 스킬을 사용하세요."
```

**변경 후**:
```yaml
description: "19-step 딥 워크플로 — 계획, 구현, 검증을 최고 수준의 엄격함으로 수행합니다. Use when: (1) 새 기능/피처 구현 (\"피처 구현해줘\", \"새 기능 만들어줘\", \"코드 작성해줘\"), (2) 전문가 리뷰 패널이 필요한 체계적 계획 수립, (3) git worktree 기반 병렬 실행, (4) PR 전 종합 코드 검증이 필요할 때. 체계적인 계획·검증 파이프라인이 필요한 중대한 코드 변경 작업에 사용하세요. 1-2 파일의 단순 수정은 이 스킬 없이 직접 처리가 효율적입니다."
```

**변경 이유**: Claude 4.6에서 과다 트리거 방지. Anthropic 가이드의 "dial back aggressive language" 권고 반영. "모든 중대한 작업에" → "체계적인 계획·검증 파이프라인이 필요한 중대한 코드 변경 작업에"로 완화하여 스코프를 구체화.

---

## 변경 요약

| 제안 | 파일 | 변경 유형 | 변경량 |
|------|------|----------|--------|
| P-001 | agent-teams.md | 섹션 추가 | ~20줄 |
| P-001 | SKILL.md (Cross-Cutting) | 섹션 추가 | ~4줄 |
| P-002 | phase-b-implementation.md | 규칙 추가 | ~2줄 |
| P-003 | SKILL.md (frontmatter) | description 수정 | 1줄 |
