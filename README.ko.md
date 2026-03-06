# simon-bot

[English](./README.md)

[Claude Code](https://claude.com/claude-code)용 모듈형 스킬 패밀리 — 심층 구현 워크플로우부터 프로젝트 관리, 분석 보고서, 자기 개선까지.

## 스킬

| 스킬 | 설명 |
|------|------|
| `/simon-bot` | 19단계 심층 워크플로우 — 최고 수준의 엄밀함으로 코드를 계획하고 구현하며 검증합니다 |
| `/simon-bot-grind` | 열일모드 — 모든 재시도 한계를 10으로 설정, 자동 진단/복구/전략 전환 |
| `/simon-bot-sessions` | 세션 관리 — 워크트리 기반 작업 세션 조회, 이어서 작업, 삭제 |
| `/simon-bot-boost` | 외부 리소스 분석 — 링크(블로그, GitHub, 논문)를 읽고 스킬 개선을 제안합니다 |
| `/simon-bot-pm` | 프로젝트 매니저 — PRD를 통해 전체 앱을 기획하고 simon-bot 인스턴스에 작업을 분배합니다 |
| `/simon-bot-report` | 사전 분석 보고서 — 전문가 팀 토론을 통한 RFC, 현황 분석, 커스텀 포맷 문서 |

## 주요 기능

- **범위 우선 계획** — 계획 수립 전에 기존 코드와 git 히스토리를 먼저 분석합니다
- **19단계 품질 파이프라인** — 범위 검증부터 프로덕션 준비까지 전 과정을 다룹니다
- **병렬 실행** — 독립적인 작업 단위를 격리된 git worktree에서 동시에 실행합니다
- **5개 도메인 전문가 팀** — 22명의 전문가가 팀별 토론과 합의를 통해 리뷰합니다 (Safety, Code Design, Data, Integration, Ops)
- **Code Design 사전 분석** — 컨벤션, 관용구, 패턴, 테스트 가능성 전문가들이 레포를 사전 분석합니다
- **인터랙티브 가이드 리뷰** — 계획과 매핑된 코드 리뷰, 변경 전/후 풍부한 맥락 제공
- **TDD 필수** — 모든 구현에서 RED→GREEN→REFACTOR 사이클을 강제합니다
- **CONTEXT.md** — 세션별 한눈에 보는 작업 요약 문서 (git 제외, 각 단계마다 자동 갱신)
- **성공 기준 체크리스트** — Step 17과 PR 생성 전에 검증하는 명시적 완료 게이트
- **컨텍스트 효율적** — 스크립트가 결정적 작업을 처리하고, 메모리 파일이 컨텍스트 손실을 방지합니다
- **PR 리뷰어 친화적** — 작업을 작은 단위로 분할합니다 (3-5개 파일, 최대 200줄)
- **자기 개선** — 회고 피드백이 자동으로 다음 실행을 개선합니다
- **안전 설계** — force push, 실제 DB/API 접근, 파괴적 명령을 사용하지 않습니다

## 아키텍처

```
skills/
├── simon-bot/
│   ├── SKILL.md                    # 핵심 19단계 워크플로우
│   └── references/                 # 페이즈별 상세 파일
│       ├── phase-a-planning.md
│       ├── phase-b-implementation.md
│       ├── integration-and-review.md
│       ├── agent-teams.md
│       ├── error-resilience.md
│       └── ...
├── simon-bot-grind/
│   ├── SKILL.md                    # Grind 오버라이드 (simon-bot 확장)
│   └── references/
├── simon-bot-sessions/
│   └── SKILL.md
├── simon-bot-boost/
│   └── SKILL.md
├── simon-bot-pm/
│   ├── SKILL.md                    # 7단계 PM 파이프라인
│   └── references/
└── simon-bot-report/
    └── SKILL.md
```

스킬은 **모듈형** 구조입니다: 각 SKILL.md에 핵심 지침이 포함되고, 상세 내용은 `references/` 하위 디렉토리로 분리됩니다. 참조 파일은 페이즈별로 필요할 때만 로드되어 컨텍스트 소비를 최소화합니다.

공통 프로토콜(Error Resilience, Agent Teams, Decision Trail, Auto-Verification Hook)은 스킬 간 공유되며, 핵심 `simon-bot` 스킬에 한 번만 정의됩니다.

설치 경로: `~/.claude/skills/`

## 설치

```bash
git clone https://github.com/yourname/simon-bot
cd simon-bot
chmod +x install.sh
./install.sh
```

설치되는 항목:
- 6개 스킬 전체 → `~/.claude/skills/simon-bot*/`
- 프로젝트 워크플로우 파일 → `.claude/workflow/` (설정, 프롬프트, 스크립트, 템플릿)

### 프로젝트 전용 설치

특정 프로젝트에 워크플로우 파일만 필요한 경우:

```bash
./install.sh --project-only
```

## 사용법

Claude Code에서:

```
/simon-bot implement user authentication with JWT
```

또는 자연어로:

```
simon-bot으로 결제 시스템 구현해줘
```

### 스킬 선택 가이드

| 상황 | 스킬 |
|------|------|
| 기능 구현 또는 버그 수정 | `/simon-bot` |
| 실패하면 안 되는 복잡한 코드베이스, 많은 재시도 필요 | `/simon-bot-grind` |
| 이전 작업 세션 이어서 하기 또는 관리 | `/simon-bot-sessions` |
| 유용한 아티클/레포를 발견 — simon-bot 스킬 개선 | `/simon-bot-boost` |
| 전체 앱 빌드 또는 멀티 피처 프로젝트 관리 | `/simon-bot-pm` |
| RFC, 아키텍처 분석, 현황 보고서 필요 (코드 변경 없음) | `/simon-bot-report` |

## 워크플로우 (simon-bot)

### Phase A: 계획 (대화형)

| 단계 | 에이전트 | 역할 |
|------|----------|------|
| **0** | `architect` | 범위 검증 — 기존 코드, 최소 변경, 리뷰 경로 결정 |
| **1-A** | `explore-medium` → `analyst` → **Code Design Team** | 프로젝트 분석 + 레포 컨벤션/패턴/관용구 사전 분석 |
| **1-B** | `planner` | 인터뷰 모드 → 작업 단위 분할 + 계획 수립 |
| **2** | `critic` ↔ `planner` (Agent Team) | 직접 토론으로 계획 리뷰 (최대 3회) |
| **3** | `architect` (Agent Team) | critic 리뷰의 메타 검증 |
| **4** | `architect` (Agent Team) | 과잉 설계 점검 (YAGNI/KISS) |
| **4-B** | 5개 도메인 전문가팀 | 구현 전 계획 사전 리뷰 — 팀별 토론으로 우려사항 도출 |

Step 0에서 리뷰 경로를 선택합니다:

| 경로 | 단계 | 적합한 작업 |
|------|------|-------------|
| **SMALL** | 5→6→7→8→17 | 버그 수정, 소규모 기능 |
| **STANDARD** | 5→6→7→...→17 | 대부분의 기능 개발 |
| **LARGE** | 5→6→7→...→17 + 추가 분석 | 아키텍처 변경 |

### Phase B-E: 구현 및 검증 (자율 실행)

`ralph + ultrawork` 모드로 자동 실행됩니다.

**Pre-Phase: Base Branch Sync** — 최신 `origin/main` (또는 `master`)을 fetch한 후, 사용자가 입력한 브랜치명으로 worktree를 생성합니다. `CONTEXT.md` (git 제외 작업 문서)를 생성하여 계획 요약, 전문가 우려사항, 성공 기준 체크리스트를 기록합니다.

각 Unit은 격리된 git worktree에서 실행됩니다.

| 단계 | 에이전트 | 역할 |
|------|----------|------|
| **Pre** | `setup-test-env.sh` | 테스트 환경 세팅 — 미설치 시 자동 설치 |
| **5** | `executor` | 구현 — **TDD 필수** (RED→GREEN→REFACTOR) |
| **6** | `architect` | 목적 정합성 리뷰 |
| **7-A** | 5개 도메인 전문가팀 | 실제 diff 기반 버그/보안/성능 팀 토론 검증 |
| **7-B** | `architect` | Step 4-B 사전 우려사항 대조, 누락 항목 보완 |
| **8** | `architect` | 회귀 검증 |
| **9** | `architect` → `executor` | 파일/함수 분할 |
| **10** | `architect` → `executor` | 통합/재사용 리뷰 |
| **11** | `architect` | 부작용 점검 |
| **12** | `code-reviewer` | 전체 변경 사항 리뷰 |
| **13** | `architect` → `executor` | 불필요한 코드 정리 |
| **14** | `code-reviewer` | 코드 품질 평가 |
| **15** | `architect` | 흐름 검증 (백엔드/데이터/에러/이벤트 흐름) |
| **16** | `architect` | MEDIUM 이슈 해결 |
| **17** | `architect` + `security-reviewer` | 프로덕션 준비 완료 확인 |

### 마무리

| 단계 | 역할 |
|------|------|
| **통합** | 사용자 지정 브랜치에 커밋 → 충돌 해결 → 빌드/테스트 확인 |
| **18** | 작업 보고서 (변경 전후 흐름, 트레이드오프, 리스크, 테스트) |
| **18-B** | 리뷰 시퀀스 — 변경사항을 논리적 단위로 그룹핑, 계획과 매핑 |
| **19** | **인터랙티브 가이드 리뷰 → 성공 기준 검증 → PR 생성** |

## simon-bot-grind

simon-bot을 최대 집요함으로 확장합니다:

- **모든 재시도 한계 = 10** — 쉽게 포기하지 않습니다
- **에스컬레이션 래더** — 단순 수정 → 근본 원인 분석 → 전략 전환 → 최후의 수단
- **자동 진단** — 실패 추적, 패턴 감지, 전략 전환
- **체크포인트** — 전략 전환 전 `git tag checkpoint-step{N}-attempt{M}`로 안전한 롤백 보장
- **진행 감지** — 2회 연속 정체 시 즉시 전략 전환
- **총 재시도 예산** — 전체 워크플로우에서 50회 재시도, 70% 도달 시 경고
- **신뢰도 점수** — 모든 에이전트 출력에 신뢰도 + 영향도 태깅

## simon-bot-pm

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

복잡도에 따라 각 기능에 `simon-bot` 또는 `simon-bot-grind`를 자동 할당합니다. 소규모 작업은 simon-bot으로 직접 리다이렉트하는 Scope Guard를 포함합니다.

## simon-bot-report

코드 변경 없이 구현 전 분석 문서를 생성합니다:

- **문서 유형**: RFC, 현황 분석, 커스텀 포맷
- **전문가 팀 토론**: simon-bot과 동일한 5개 도메인 전문가 구조 사용
- **인터랙티브 가이드 리뷰**: 섹션별 리뷰와 사용자 피드백
- **원활한 핸드오프**: 리뷰 후 분석 결과를 컨텍스트로 simon-bot 또는 simon-bot-pm 실행 가능

## simon-bot-boost

외부 리소스(블로그 포스트, GitHub 레포, 논문, 아티클)를 읽고 simon-bot 스킬을 개선합니다:

- **5인 전문가 패널**: Workflow Architect, Prompt Engineer, Innovation Scout, Quality & Safety Guardian, DX Specialist
- **전체 스킬 대상**: 5개 스킬 파일 + 참조 파일 전체 분석
- **사용자 제어**: 모든 개선 제안은 적용 전 명시적 승인 필요
- **변경 추적**: 적용된 모든 변경은 `.claude/boost/applied-log.md`에 기록

## 세션 관리

`/simon-bot-sessions` 커맨드로 여러 Claude Code 세션에 걸친 작업을 관리할 수 있습니다.

| 커맨드 | 설명 |
|--------|------|
| `/simon-bot-sessions list` | 활성 워크트리 세션 목록 |
| `/simon-bot-sessions info feat/add-auth` | 세션 상세 정보 (커밋, 메모리 파일, 상태) |
| `/simon-bot-sessions delete feat/add-auth` | 세션 삭제 (워크트리 + 브랜치) |
| `/simon-bot-sessions resume feat/add-auth` | 이전 작업 이어서 진행 (맥락 복원) |
| `/simon-bot-sessions pr feat/add-auth` | 세션에서 PR 생성 |

또는 쉘 스크립트를 직접 사용:

```bash
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh list
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh info <branch>
bash ~/.claude/skills/simon-bot/workflow/scripts/manage-sessions.sh delete <branch>
```

## 전문가 패널 (5개 도메인팀)

전문가들은 개별 리뷰가 아닌 **팀 내 토론**을 통해 합의 기반으로 우려사항을 도출합니다.

### 팀 구성

| 팀 | 멤버 | 활성화 | 토론 초점 |
|----|------|--------|----------|
| **Safety** | appsec, auth, infrasec, stability | 항상 (appsec+stability) | 보안 경계, 인증 우회, 장애 복구 |
| **Code Design** | convention, idiom, design-pattern, testability | 항상 (convention+idiom) | 레포 컨벤션, 언어 관용구, 설계 패턴, 테스트 가능성 |
| **Data** | rdbms, cache, nosql | auto-detect (min 2) | 데이터 일관성, 캐시 무효화, 스토리지 정합성 |
| **Integration** | sync-api, async, external-integration, messaging | auto-detect (min 2) | 동기/비동기 경계, 에러 전파, 장애 격리 |
| **Ops** | infra, observability, performance, concurrency | auto-detect (min 2) | 운영 안정성, 관측 가능성, 성능 |

## 커스터마이징

### config.yaml

임계값, 반복 제한, 전문가 설정을 조정할 수 있습니다:

```yaml
model_policy: opus              # 전체 에이전트 모델
language: ko                    # 보고서 언어

unit_limits:
  max_files: 5
  max_lines: 200

size_thresholds:
  function_lines: 50
  file_lines: 300

loop_limits:
  critic_planner: 3
  step4b_critical: 2
  step7b_recheck: 1
  step7_8: 2
  step6_executor: 3
  step16: 3

expert_panel:
  mode: agent-team
  discussion_rounds: 2
  require_consensus: true

test_env:
  check_before_test: true
  skip_on_missing: true
```

### 전문가 프롬프트

`.claude/workflow/prompts/*.md`에서 전문가 리뷰 기준을 수정할 수 있습니다 (22개 전문가 프롬프트).

### 회고

이전 피드백은 `.claude/memory/retrospective.md`에 저장되며, 이후 실행 시 자동으로 참조됩니다.

## 안전 규칙

다음 작업은 **어떠한 경우에도 절대 금지**됩니다:

- `git push --force` — 어떤 상황에서도 사용 불가
- `main`/`master`에 직접 병합 — PR만 허용
- `rm -rf` — 파괴적 삭제 금지
- 실제 DB 접근 — `mysql`, `psql`, `redis-cli`, `mongosh`
- 실제 API 호출 — 외부 엔드포인트로의 `curl`, `wget`
- 실제 서버 접근 — `ssh`, `scp`, `sftp`
- 시크릿 커밋 — `.env`, 자격 증명, API 키
- 실제 외부 시스템을 사용한 테스트 — mock/stub만 허용

## 요구 사항

- [Claude Code](https://claude.com/claude-code) v2.0+
- Git

## 라이선스

MIT
