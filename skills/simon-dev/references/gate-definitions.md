# Gate Definitions (게이트 정의)

simon 워크플로에서 사용되는 모든 게이트의 정의. 각 게이트는 품질과 안전성을 결정론적으로 강제하는 체크포인트다.

## 게이트 일람표

| Gate ID | 트리거 시점 | 통과 조건 | 실패 시 조치 | 스크립트 |
|---------|-----------|----------|------------|---------|
| **G-CAL** | Phase A 종료 (Phase B 진입 전) | Calibration Checklist 9개 항목 전체 충족 | 미충족 항목의 해당 Step으로 회귀 후 자동 보완 | `calibration-check.sh` |
| **G-STEP** | Step 전환 시 | verify-commands.md의 빌드/린트/테스트 통과 | 다음 Step 진입 차단 → 수정 후 재검증 | verify-commands.md 참조 |
| **G-STOP** | Edit/Write 후 (소스코드) | 빌드 + 린트 + 타입체크 통과 | Stop-and-Fix → 수정 완료까지 다음 작업 차단 | `auto-verify.sh` |
| **G-HOOK** | PostToolUse (Edit/Write) | auto-verify.sh exit 0 | exit 1 → Stop-and-Fix Gate 진입 | `auto-verify.sh` |
| **G-PHASE-B** | Phase B 진입 시 | plan-summary.md 존재 + G-CAL 통과 | Phase A로 회귀 | — |
| **G-INT** | Integration Stage 진입 시 | 모든 Unit 완료 + 전체 빌드 + 전체 테스트 통과 | 미완료 Unit 실행 또는 실패 수정 | — |
| **G-PROD** | Step 17 Production Readiness | 테스트 0 fail + 빌드 성공 + 보안 CRITICAL 0 + HIGH 우려 전부 반영 + 커버리지 ≥ 80% | Minor: auto-fix, Major: Phase 회귀, Critical: Step 1-B | — |

## 상세 정의

### G-CAL: Phase A Calibration Checklist

**트리거**: Phase A 모든 Step 완료 후, Phase B 진입 직전.

**검증 항목 (9개)**:

| # | 항목 | 확인 방법 |
|---|------|----------|
| 1 | 코드베이스 탐색 완료 | `requirements.md` + `code-design-analysis.md` 존재 및 비어있지 않음 |
| 2 | 인터뷰 완료 | `plan-summary.md`에 Unresolved decisions이 비어있거나 구현에 영향 없음 |
| 3 | 파일 경로 포함 | Task 섹션 + End State Files Changed에 구체적 파일 경로 |
| 4 | AC 3분할 | Code Changes / Tests / Quality Gates 섹션 모두 존재 |
| 5 | Files Changed 테이블 | File \| Action \| Summary 형식 존재 |
| 6 | Behavior Changes | Before → After 형식 존재 |
| 7 | Test Targets | 테스트 대상 파일 패턴 명시 |
| 8 | Done-When Checks | 각 Unit별 기계적 검증 조건 명시 |
| 9 | Behavioral Checks | Behavior Changes의 검증 가능 항목이 Done-When Behavioral Checks에 포함 |

**실패 시**: 사용자에게 보고하지 않고 해당 Step을 자동 재실행하여 보완. ship 모드에서는 자동 보정 시도 후 빌드/테스트 실패만 정지.

**스크립트**: `calibration-check.sh` — 파일 존재 여부, 섹션 존재 여부 등 결정론적 검증을 수행.

### G-STEP: Step Transition Gate

**트리거**: 각 Step 완료 후 다음 Step으로 전환할 때.

**통과 조건**: verify-commands.md에 정의된 검증 명령이 모두 통과.

**실패 시**: 다음 Step 진입 차단. Stop-and-Fix Gate와 동일하게 수정 후 재검증 필수.

### G-STOP: Stop-and-Fix Gate

**트리거**: 소스코드 파일에 대한 Edit/Write 실행 후.

**통과 조건**: 빌드, 린트, 타입체크, 테스트 중 하나라도 실패하면 미통과.

**핵심 규칙**:
- 수정 완료 전까지 다음 파일 수정, 다음 Step 진입, 사용자 보고 등 **어떤 작업도 불가**
- "나중에 고치겠다"는 허용되지 않음 — 미수정 실패는 누적되어 디버깅 비용이 기하급수적 증가
- 수정 후 **동일 검증 명령 재실행**(Fix-Verify Loop)으로 통과 확인
- 재실행에서도 실패 시 Error Resilience 프로토콜 적용

**예외**: ENV_INFRA로 테스트 실행 자체가 불가능한 경우, 사용자 명시적 승인 후에만 테스트 SKIP 가능. build + typecheck는 반드시 통과 필요.

**적용 제외**: `.md`, `.json` 설정 파일, 커밋 메시지 등 비소스코드.

**스크립트**: `auto-verify.sh` — PostToolUse hook으로 자동 실행.

### G-HOOK: Auto-Verification Hook

**트리거**: hooks.PostToolUse에 등록. Edit/Write 도구 실행 후 자동 발동.

**동작 흐름**:
1. `$TOOL_NAME`이 Edit/Write가 아니면 → exit 0 (skip)
2. `$FILE_PATH` 확장자가 `.md/.json/.yaml`이면 → exit 0 (비소스코드)
3. verify-commands.md에서 빌드/린트 명령 추출 후 실행
4. 실패 시 exit 1 → Claude Code가 실패 감지 → G-STOP 진입

**스크립트**: `auto-verify.sh` — settings.json의 `hooks.PostToolUse`에 등록.

```json
{
  "hooks": {
    "PostToolUse": [{
      "type": "command",
      "command": ".claude/workflow/scripts/auto-verify.sh"
    }]
  }
}
```

### G-PHASE-B: Phase B Entry Gate

**트리거**: Phase A 완료 후 Phase B 진입 시.

**통과 조건**:
- `plan-summary.md`가 존재하고 비어있지 않음
- G-CAL(Calibration Checklist) 9개 항목 전체 통과

**실패 시**: Phase A로 회귀하여 누락 항목 보완.

### G-INT: Integration Gate

**트리거**: 모든 Unit 구현 완료 후 Integration Stage 진입 시.

**통과 조건**:
- 모든 Unit의 Step 17 완료
- 전체 빌드 성공
- 전체 테스트 스위트 통과
- Working Example 재실행 통과 (P-007)

**실패 시**:
- 미완료 Unit → 해당 Unit 실행 재개
- 빌드/테스트 실패 → executor 수정 후 재검증
- Working Example 실패 → executor 수정 → 재검증 (max 3회)

### G-PROD: Production Readiness Gate

**트리거**: Step 17, Fresh Context에서 production-readiness-auditor가 검증.

**통과 조건**:

| 항목 | 기준 |
|------|------|
| 테스트 | 전체 테스트 스위트 통과 (0 failures) |
| 빌드 | 빌드 성공 + 타입체크 통과 |
| 보안 | CRITICAL finding 0건 |
| 전문가 우려 | HIGH 이상 전부 반영 |
| 커버리지 | 80% 이상 (측정 가능 시) |
| AC 충족 | Success Criteria 각 항목 PASS |

**Verdict 형식**: 각 항목에 대해 PASS/FAIL/NEEDS-HUMAN-REVIEW로 판정. "전반적으로 양호" 포괄 판정 금지.

**실패 시**:
- Minor FAIL → executor auto-fix
- Major FAIL → 관련 Phase로 회귀
- Critical FAIL → Step 1-B 회귀

## Deterministic Gate Principle

게이트 검증에서 파일 존재 확인, 빌드/린트/테스트 실행, 패턴 매칭, 카운터 비교 등 결정론적으로 수행 가능한 작업은 bash 스크립트를 우선 사용한다. LLM은 스크립트 실행 결과(PASS/FAIL + 실패 항목)만 받아 후속 판단(수정 방향, 전략 전환)에 집중한다.

결정론적 검증을 LLM 기억에 의존하면, 컨텍스트 압축 시 규칙이 소실되어 게이트가 무력화될 수 있다.

## 게이트 적용 경로별 매트릭스

| Gate | STANDARD | LARGE |
|------|:--------:|:-----:|
| G-CAL | O | O |
| G-STEP | O | O |
| G-STOP | O | O |
| G-HOOK | O | O |
| G-PHASE-B | O | O |
| G-INT | O | O |
| G-PROD | O | O |

모든 게이트는 경로(STANDARD/LARGE)에 관계없이 적용된다.
