# Cross-Model Verification Protocol

## 목적

단일 모델(Claude)의 검증 한계를 보완하기 위해 Codex(OpenAI)를 교차검증 레이어로 추가한다.
두 모델이 독립적으로 동일한 코드를 분석하여 합의하면 신뢰도가 상승하고,
불일치하면 추가 검토가 필요한 지점이 명시된다 — Monte Carlo 원리의 cross-model 확장이다.

서로 다른 학습 데이터, 아키텍처, 추론 방식을 가진 모델이 독립적으로 같은 결론에 도달하면,
단일 모델의 N회 반복 검증보다 구조적으로 더 높은 신뢰도를 제공한다.

## 트리거 기준

| 단계 | 조건 | 교차검증 | 방식 |
|------|------|:---:|------|
| Step 7 (P-003) | CRITICAL/HIGH findings 1+ | 조건부 | `codex review` |
| Step 7 (P-003) | 보안 관련 변경 | 조건부 | `codex challenge` (adversarial) |
| Step 12 (Full Change Review) | **항상** | 항상 | `codex review` |
| Step 17 (Production Readiness) | Diff > 100줄 | 조건부 | `codex review` |
| simon-bot-review (전체 리뷰) | **항상** | 항상 | `codex review` + reconciliation |
| Grind Tier 2+ (4회+ 실패) | 전략 전환 전 | 조건부 | `codex-companion.mjs task` (rescue) |

### 보안 관련 변경 감지

`config.yaml`의 `high_impact_paths` 또는 diff에서 다음 패턴이 감지되면 보안 관련으로 분류한다:

- 경로: auth/, security/, crypto/, middleware/auth, rbac/
- 키워드: token, session, password, secret, permission, credential, api_key
- 마이그레이션: DROP, DELETE, ALTER + 권한/인증 테이블
- 파일: .env, credentials, key 관련 파일 변경

## 호출 방식

### Review 모드 (구조적 코드 리뷰)

```bash
codex review --base {base_branch} \
  -c 'model_reasoning_effort="xhigh"' \
  --enable web_search_cached \
  "{custom_instructions}"
```

- 5분 타임아웃 (300000ms)
- Gate verdict: **PASS** (P1 마커 없음) / **FAIL** (P1 마커 발견)
- `{custom_instructions}`에 현재 단계의 검증 초점을 전달한다

**custom_instructions 예시 (단계별)**:
- Step 7: `"CRITICAL/HIGH 이슈 독립 검증. 보안, 정확성, 성능 관점으로 분석."`
- Step 12: `"전체 변경사항의 일관성, 설계 품질, 잠재적 문제 분석."`
- Step 17: `"프로덕션 배포 전 최종 검증. 보안, 데이터 무결성, 성능 위험 집중."`
- simon-bot-review: `"PR diff 독립 코드 리뷰. 보안, 정확성, 성능, 설계 관점."`

### Challenge 모드 (adversarial 검증)

```bash
codex exec "{adversarial_prompt}" \
  -s read-only \
  -c 'model_reasoning_effort="xhigh"' \
  --enable web_search_cached \
  --json
```

- 보안 관련 변경에만 적용
- 공격자 관점에서 취약점, race condition, 인증 우회, 데이터 유출 경로를 탐색
- 5분 타임아웃

### Rescue 모드 (대안 진단 — grind 전용)

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task \
  --effort xhigh \
  "{diagnosis_prompt}"
```

- Grind Tier 2+ (Attempt 4+) 에서 전략 전환 전 독립 근본원인 분석
- Claude의 진단과 비교하여 불일치 시 Codex 진단을 우선 시도한다
  (기존 Claude 진단은 이미 3회 실패했으므로 다른 관점이 필요하다)

## Reconciliation 프로토콜

Codex 결과와 Claude 결과를 대조하여 CROSS-MODEL RECONCILIATION 리포트를 생성한다:

```markdown
### Cross-Model Reconciliation
- **Codex Gate**: PASS | FAIL
- **Agreement**: N/M findings (X%)
- **Both found**: [공통 발견 — 높은 신뢰도]
- **Only Codex**: [Codex만 발견 → `[CODEX-ONLY]` 태깅, 추가 검토 필요]
- **Only Claude**: [Claude만 발견 → 유지하되 confidence 하향]
- **Confidence**: HIGH (>80% 일치) | MEDIUM (50-80%) | LOW (<50% → 사용자 검토 필요)
```

### Reconciliation 규칙

1. **Both found**: 양 모델이 독립적으로 동일 이슈를 발견 → `[CROSS-MODEL-CONFIRM]` 태깅. 최고 신뢰도. findings의 severity 유지.
2. **Only Codex**: Claude가 놓친 이슈 → `[CODEX-ONLY]` 태깅. Claude의 verifier가 해당 코드 위치를 재분석. 재현 확인 시 findings에 추가.
3. **Only Claude**: Codex가 놓친 이슈 → 기존 severity 유지하되 `[CLAUDE-ONLY]` 태깅.
4. **Severity 불일치**: 양 모델이 같은 이슈를 발견했지만 severity가 다르면 → `[SEVERITY-CROSS-DISPUTED]` 태깅, **높은 쪽을 채택**한다.
5. **Confidence LOW (<50%)**: 자동 수정 금지. 사용자에게 불일치 사항을 제시하여 판단을 요청한다.

### Finding 매칭 기준

"같은 이슈"를 판별할 때 파일+라인 번호의 정확한 일치를 요구하지 않는다.
동일한 **코드 패턴/함수**에 대해 **동일 카테고리**(보안/성능/정확성/설계)의 지적이면 매칭한다.

### 리포트 저장

- simon-bot: `.claude/memory/unit-{name}/cross-model-reconciliation.md`
- simon-bot-review: `{SESSION_DIR}/memory/cross-model-reconciliation.md`

## Codex 호출 실패 시

Codex CLI 호출이 실패하면 (타임아웃, 네트워크 오류, 인증 실패 등):

1. 실패 사유를 기록한다
2. Claude 단독 검증으로 fallback — 기존 워크플로를 그대로 진행한다
3. `[CODEX-UNAVAILABLE]` 태깅으로 교차검증 미실행을 명시한다
4. Step 17 / simon-bot-review에서 교차검증 미실행을 Review Readiness Dashboard에 표시한다

**교차검증은 추가 품질 레이어이지 필수 게이트가 아니다. Codex 실패로 워크플로가 중단되어서는 안 된다.**
