# simon-bot

[Claude Code](https://claude.com/claude-code)용 19단계 심층 워크플로우 플러그인으로, 최고 수준의 엄밀함으로 코드를 계획하고 구현하며 검증합니다.

[oh-my-claudecode](https://github.com/nicepkg/oh-my-claudecode) 멀티 에이전트 오케스트레이션 기반으로 구축되었습니다.

## 주요 기능

- **범위 우선 계획** — 계획 수립 전에 기존 코드와 git 히스토리를 먼저 분석합니다
- **19단계 품질 파이프라인** — 범위 검증부터 프로덕션 준비까지 전 과정을 다룹니다
- **병렬 실행** — 독립적인 작업 단위를 격리된 git worktree에서 동시에 실행합니다
- **5개 도메인 전문가 팀** — 22명의 전문가가 팀별 토론과 합의를 통해 리뷰합니다 (Safety, Code Design, Data, Integration, Ops)
- **Code Design 사전 분석** — 컨벤션, 관용구, 패턴, 테스트 가능성 전문가들이 레포를 사전 분석합니다
- **인터랙티브 가이드 리뷰** — 계획과 매핑된 코드 리뷰, 변경 전/후 풍부한 맥락 제공
- **컨텍스트 효율적** — 스크립트가 결정적 작업을 처리하고, 메모리 파일이 컨텍스트 손실을 방지합니다
- **PR 리뷰어 친화적** — 작업을 작은 단위로 분할합니다 (3-5개 파일, 최대 200줄)
- **자기 개선** — 회고 피드백이 자동으로 다음 실행을 개선합니다
- **안전 설계** — force push, 실제 DB/API 접근, 파괴적 명령을 사용하지 않습니다

## 변형

| 스킬 | 설명 |
|------|------|
| `/simon-bot` | 표준 19-step 파이프라인 |
| `/simon-bot-grind` | 열일모드 — 모든 재시도 한계를 10으로 설정, 자동 진단/복구/전략 전환 |
| `/simon-bot-sessions` | 세션 관리 — 이전 작업 조회, 이어서 작업, 삭제 |

## 설치

```bash
git clone https://github.com/yourname/simon-bot
cd simon-bot
chmod +x install.sh
./install.sh
```

설치되는 항목:
- 글로벌 스킬 → `~/.claude/skills/simon-bot/SKILL.md`
- 프로젝트 워크플로우 → `.omc/workflow/` (설정, 프롬프트, 스크립트, 템플릿)

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

## 워크플로우

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

**Pre-Phase: Base Branch Sync** — 최신 `origin/main` (또는 `master`)을 fetch한 후, 사용자가 입력한 브랜치명으로 worktree를 생성합니다.

각 Unit은 격리된 git worktree에서 실행됩니다.

| 단계 | 에이전트 | 역할 |
|------|----------|------|
| **Pre** | `setup-test-env.sh` | 테스트 환경 세팅 — 미설치 시 자동 설치 |
| **5** | `executor` | 구현 (전문가 우려사항 + Code Design 분석 반영) |
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
| **19** | **인터랙티브 가이드 리뷰 → PR 생성** |

## Step 19: 인터랙티브 가이드 리뷰

Step 19는 모든 구현/검증이 완료된 후 사용자와 진행하는 대화형 코드 리뷰입니다. **PR은 리뷰 후에 생성됩니다.**

### 19-A: 리뷰 개요 (계획 매핑 기반)

단순 통계가 아닌, **계획과 구현의 매핑**을 보여줍니다:

- **계획 요약 리마인드** — 원래 목표와 핵심 요구사항
- **구현 매핑 테이블** — 계획의 각 Unit이 어떤 변경 단위로 구현되었는지
- **변경 단위 간 관계도** — 변경들이 어떻게 맞물리는지 흐름 설명
- **리뷰 순서 안내** — 왜 이 순서로 진행하는지 (상류→하류)

### 19-B: 순차 리뷰 (풍부한 맥락 제공)

각 논리적 변경 단위마다 다음 맥락을 제공합니다:

| 항목 | 설명 |
|------|------|
| **계획 매핑** | "이 변경은 계획의 [Unit N]을 구현합니다" |
| **변경 전 상태** | 기존 코드의 역할, 동작 방식, 한계점 |
| **변경 내용** | 어떤 부분을 어떻게 개선/추가했는지 |
| **핵심 코드 diff** | Before/After (중요 부분 발췌) |
| **다른 변경과의 연관** | 이전/이후 변경 단위와의 관계 |
| **리뷰 포인트** | 주의 깊게 봐야 할 부분 |
| **전문가 우려사항 반영** | 관련 우려가 어떻게 반영되었는지 |
| **트레이드오프** | 설계 결정과 그 이유 |

각 단위에 대해 **OK / 수정 요청 / 질문** 피드백을 수집합니다.

### 19-C: PR 생성 및 마무리

리뷰 완료 후 사용자가 선택합니다:

- **Draft PR 생성** — `gh pr create --draft`
- **Ready PR 생성** — `gh pr create` (바로 Ready 상태)
- **추가 수정 필요** — 19-B로 돌아가 추가 리뷰

Step 18 보고서 내용이 PR description에 포함됩니다.

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

## 흐름도

```
Startup: 브랜치명 입력 (사용자가 직접 지정)
        │
Step 0: Scope Challenge
  └─ git history + what exists → SMALL / STANDARD / LARGE
        │
Phase A (대화형)
  ├─ 1-A 분석 + Code Design Team (컨벤션, 관용구, 패턴, 테스트 가능성)
  ├─ 1-B 계획 수립 (Unit 분할, NOT in scope, Unresolved)
  ├─ 2-4 리뷰 루프 (Agent Team: planner ↔ critic ↔ architect)
  └─ 4-B 전문가 사전 리뷰 (5개 도메인팀 토론)
        │
Pre-Phase: Base Branch Sync
  └─ git fetch origin main → origin/main 기준 worktree 생성
        │ ralph + ultrawork 시작
        ▼
Phase B-E (자율 실행, worktree 격리)
  Pre: 테스트 환경 세팅 (미설치 시 자동 설치)
  ┌─────────────────┐  ┌─────────────────┐
  │ worktree/unit-1 │  │ worktree/unit-2 │  ← 병렬
  │ Step 5~17       │  │ Step 5~17       │
  └────────┬────────┘  └────────┬────────┘
           └──────┬─────────────┘
                  ▼
          worktree/unit-3 (1,2에 의존)
                  │
                  ▼
          통합 (커밋, 빌드, 테스트)
                  │
                  ▼
          보고서 → 리뷰 시퀀스
                  │
                  ▼
          인터랙티브 가이드 리뷰 (19-A → 19-B → 19-C)
                  │
                  ▼
          PR 생성 → feedback.md
                    (세션 간 영속 기록)
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

### 리뷰 경로별 팀 활성화

| 경로 | 활성화 팀 |
|------|----------|
| SMALL | Safety + Code Design (always 멤버만) |
| STANDARD | Safety + Code Design + auto-detect된 Data/Integration/Ops |
| LARGE | 전체 + extended failure mode analysis |

### 전문가 개입 시점

전문가들은 워크플로우에서 **두 번** 개입합니다:
1. **Step 4-B** (계획 사전 리뷰): 팀 내 토론으로 계획의 우려사항 도출 (CRITICAL/HIGH/MEDIUM)
2. **Step 7** (구현 검증): 실제 diff 기반 팀 검증 + 사전 우려사항 누락 여부 대조

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

`.omc/workflow/prompts/*.md`에서 전문가 리뷰 기준을 수정할 수 있습니다 (22개 전문가 프롬프트).

### 회고

이전 피드백은 `.omc/memory/retrospective.md`에 저장되며, 이후 실행 시 자동으로 참조됩니다.

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
- [oh-my-claudecode](https://github.com/nicepkg/oh-my-claudecode) v4.0+
- Git

## 라이선스

MIT
