<div align="center">

# simon-bot

**Claude Code를 위한 19단계 심층 구현 엔진**

계획부터 PR까지, 22명의 전문가가 팀 토론으로 검증하는 자율 코딩 워크플로우

[![GitHub Stars](https://img.shields.io/github/stars/SW-in-beta/simon-bot?style=flat-square)](https://github.com/SW-in-beta/simon-bot)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-compatible-blueviolet?style=flat-square)](https://claude.com/claude-code)

[English](./README.md)

</div>

---

## 왜 simon-bot인가?

- **코드 품질을 타협하지 않습니다** — 19단계 파이프라인이 범위 검증부터 프로덕션 준비까지 모든 단계를 강제합니다
- **혼자 리뷰하지 않습니다** — 5개 도메인팀, 22명의 전문가가 팀 내 토론과 합의로 우려사항을 도출합니다
- **실패해도 포기하지 않습니다** — grind 모드는 자동 진단, 전략 전환, 체크포인트 롤백으로 끝까지 해결합니다
- **안전하게 격리됩니다** — 모든 작업은 독립 worktree에서 실행되고, TDD가 필수이며, 파괴적 명령은 차단됩니다

---

## 빠른 시작

```bash
git clone https://github.com/SW-in-beta/simon-bot
cd simon-bot
./install.sh
```

Claude Code에서 바로 사용하세요:

```
/simon-bot implement user authentication with JWT
```

---

## 동작 방식

```mermaid
graph LR
    A["Step 0-4B\n계획 & 전문가 사전 리뷰"] --> B["Step 5\nTDD 구현"]
    B --> C["Step 6-17\n검증 & 리팩토링"]
    C --> D["Step 18-19\n보고서 & PR"]
    style A fill:#e8f4f8,stroke:#2196f3
    style B fill:#e8f5e9,stroke:#4caf50
    style C fill:#fff3e0,stroke:#ff9800
    style D fill:#f3e5f5,stroke:#9c27b0
```

**Phase A** — 기존 코드 분석, 인터뷰, 계획 수립, 전문가 팀 사전 리뷰 (대화형)<br>
**Phase B-E** — TDD 구현, 5개 팀 검증, 리팩토링, 회귀 테스트 (자율 실행)<br>
**마무리** — 인터랙티브 가이드 리뷰, 성공 기준 체크리스트 검증, PR 생성

---

## 스킬

| 스킬 | 설명 |
|------|------|
| `/simon-bot` | 19단계 심층 워크플로우 — 계획, 구현, 검증을 최고 수준의 엄밀함으로 수행 |
| `/simon-bot-grind` | 열일모드 — 재시도 한계 10, 자동 진단/복구/전략 전환 |
| `/simon-bot-sessions` | 세션 관리 — worktree 기반 작업 세션 조회, 이어서 작업, 삭제 |
| `/simon-bot-boost` | 외부 리소스 분석 — 링크를 읽고 스킬 개선을 제안 |
| `/simon-bot-pm` | 프로젝트 매니저 — PRD 기반 전체 앱 기획, simon-bot 인스턴스에 작업 분배 |
| `/simon-bot-report` | 사전 분석 보고서 — 전문가 팀 토론을 통한 RFC, 현황 분석, 커스텀 포맷 |

### 어떤 스킬을 쓸까?

| 상황 | 스킬 |
|------|------|
| 기능 구현 또는 버그 수정 | `/simon-bot` |
| 실패하면 안 되는 복잡한 코드베이스 | `/simon-bot-grind` |
| 이전 작업 세션 이어서 하기 | `/simon-bot-sessions` |
| 유용한 아티클/레포 발견 — 스킬 개선 | `/simon-bot-boost` |
| 전체 앱 빌드 또는 멀티 피처 프로젝트 | `/simon-bot-pm` |
| RFC, 아키텍처 분석, 보고서 (코드 변경 없음) | `/simon-bot-report` |

---

<details>
<summary><strong>전문가 팀 구조 (5개 도메인팀, 22명)</strong></summary>
<br>

전문가들은 개별 리뷰가 아닌 **팀 내 토론**을 통해 합의 기반으로 우려사항을 도출합니다.

| 팀 | 멤버 | 활성화 | 토론 초점 |
|----|------|--------|----------|
| **Safety** | appsec, auth, infrasec, stability | 항상 (appsec+stability) | 보안 경계, 인증 우회, 장애 복구 |
| **Code Design** | convention, idiom, design-pattern, testability | 항상 (convention+idiom) | 레포 컨벤션, 언어 관용구, 설계 패턴, 테스트 가능성 |
| **Data** | rdbms, cache, nosql | auto-detect (min 2) | 데이터 일관성, 캐시 무효화, 스토리지 정합성 |
| **Integration** | sync-api, async, external-integration, messaging | auto-detect (min 2) | 동기/비동기 경계, 에러 전파, 장애 격리 |
| **Ops** | infra, observability, performance, concurrency | auto-detect (min 2) | 운영 안정성, 관측 가능성, 성능 |
</details>

<details>
<summary><strong>simon-bot-grind 상세</strong></summary>
<br>

simon-bot을 최대 집요함으로 확장합니다:

- 모든 재시도 한계 = 10 — 쉽게 포기하지 않습니다
- **에스컬레이션 래더** — 단순 수정 → 근본 원인 분석 → 전략 전환 → 최후의 수단
- **자동 진단** — 실패 추적, 패턴 감지, 전략 전환
- **체크포인트** — 전략 전환 전 `git tag checkpoint-step{N}-attempt{M}`로 안전한 롤백
- **진행 감지** — 2회 연속 정체 시 즉시 전략 전환
- **총 재시도 예산** — 전체 50회, 70% 도달 시 경고
- **신뢰도 점수** — 모든 에이전트 출력에 신뢰도 + 영향도 태깅
</details>

<details>
<summary><strong>simon-bot-pm 상세</strong></summary>
<br>

7단계 프로젝트 매니저 파이프라인:

| 단계 | 이름 | 역할 |
|------|------|------|
| 0 | Project Setup | 프로젝트 유형 감지, 실행 모드 선택 |
| 1 | Spec-Driven Design | 인터뷰 → Spec(WHAT) → Architecture(HOW) → PRD |
| 2 | Task Breakdown | PRD → 기능 분해 → 의존성 그래프 → 실행 계획 |
| 3 | Environment Setup | 스캐폴딩, 의존성, 설정 |
| 4 | Feature Execution | simon-bot/grind 인스턴스에 기능 분배 (가능한 경우 병렬) |
| 5 | Full Verification | 통합 테스트, 아키텍처 리뷰, 보안 리뷰 |
| 6 | Delivery | 최종 보고서, 가이드 리뷰, PR 생성 |

복잡도에 따라 `simon-bot` 또는 `simon-bot-grind`를 자동 할당합니다.
</details>

<details>
<summary><strong>기타 스킬 상세 (report / boost / sessions)</strong></summary>
<br>

**simon-bot-report** — 코드 변경 없이 구현 전 분석 문서(RFC, 현황 분석, 커스텀 포맷)를 생성합니다. simon-bot과 동일한 5개 도메인 전문가 팀 토론 구조를 사용하며, 리뷰 후 simon-bot / simon-bot-pm으로 원활하게 핸드오프할 수 있습니다.

**simon-bot-boost** — 외부 리소스(블로그, GitHub, 논문)를 읽고 5인 전문가 패널이 스킬 개선을 제안합니다. 모든 제안은 적용 전 명시적 승인이 필요하며 `.claude/boost/applied-log.md`에 기록됩니다.

**simon-bot-sessions** — 여러 Claude Code 세션에 걸친 worktree 기반 작업을 관리합니다: `list` | `info <branch>` | `resume <branch>` | `delete <branch>` | `pr <branch>`
</details>

<details>
<summary><strong>설정 (config.yaml)</strong></summary>
<br>

```yaml
model_policy: opus                    # 전체 에이전트 모델
language: ko                          # 보고서 언어
unit_limits: { max_files: 5, max_lines: 200 }
size_thresholds: { function_lines: 50, file_lines: 300 }
loop_limits:
  critic_planner: 3                   # 계획 리뷰 반복
  step4b_critical: 2                  # 전문가 사전 리뷰 재시도
  step7_8: 2                          # 검증 루프
  step16: 3                           # MEDIUM 이슈 해결
expert_panel:
  mode: agent-team
  discussion_rounds: 2
  require_consensus: true
```

전문가 리뷰 기준은 `.claude/workflow/prompts/*.md`에서 수정 가능 (22개 전문가 프롬프트).
회고 피드백은 `.claude/memory/retrospective.md`에 저장되어 다음 실행 시 자동 참조됩니다.
</details>

<details>
<summary><strong>안전 규칙</strong></summary>
<br>

다음 작업은 **어떠한 경우에도 절대 금지**됩니다:

- `git push --force` — 어떤 상황에서도 사용 불가
- `main`/`master`에 직접 병합 — PR만 허용
- `rm -rf` — 파괴적 삭제 금지
- 실제 DB 접근 — `mysql`, `psql`, `redis-cli`, `mongosh`
- 실제 API 호출 — 외부 엔드포인트로의 `curl`, `wget`
- 실제 서버 접근 — `ssh`, `scp`, `sftp`
- 시크릿 커밋 — `.env`, 자격 증명, API 키
- 실제 외부 시스템을 사용한 테스트 — mock/stub만 허용
</details>

---

## 요구 사항

- [Claude Code](https://claude.com/claude-code) v2.0+
- Git

## 라이선스

MIT
