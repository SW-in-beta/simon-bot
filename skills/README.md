# simon-bot

Deep workflow skill with quality pipeline for Claude Code.

계획 → 전문가 사전 리뷰 → 구현 → 검증 → 인터랙티브 코드 리뷰 → PR까지 전 과정을 자동화합니다.

## 사용법

```
/simon-bot
```

Claude Code에서 위 명령어를 입력하면 워크플로가 시작됩니다.

## 변형

| 스킬 | 설명 |
|------|------|
| `/simon-bot` | 표준 19-step 파이프라인 |
| `/simon-bot-grind` | 열일모드 — 모든 재시도 한계를 10으로 설정, 자동 진단/복구/전략 전환 |
| `/simon-bot-sessions` | 세션 관리 — 이전 작업 조회, 이어서 작업, 삭제 |

## 워크플로 개요

### Phase A: Planning (사용자 인터랙티브)

| Step | 이름 | 설명 |
|------|------|------|
| 0 | Scope Challenge | git 히스토리 분석, 최소 변경 범위 결정, 리뷰 경로 선택 (SMALL/STANDARD/LARGE) |
| 1-A | Project Analysis + Code Design | 프로젝트 구조 스캔, 스택 분석, Code Design Team이 레포 컨벤션/패턴/공식 권장사항 사전 분석 |
| 1-B | Plan Creation | 유닛 분할 (max 5파일, 200줄), 의존성 그래프, 구현 순서 결정 |
| 2 | Plan Review | critic이 계획 검토, planner와 직접 토론으로 수정 (max 3회) |
| 3 | Meta Verification | architect가 critic 리뷰를 교차 검증 |
| 4 | Over-engineering Check | YAGNI/KISS 관점에서 과도한 설계 검출 |
| **4-B** | **Expert Plan Review** | **5개 도메인팀 전문가들이 팀 내 토론으로 계획의 우려사항/위험요소 사전 식별** |

### Phase B-E: Implementation & Verification (자동, 병렬 background agents)

각 유닛은 독립된 git worktree에서 실행되며, 독립 유닛은 병렬 처리됩니다.

| Step | 이름 | 설명 |
|------|------|------|
| 5 | Implementation | 전문가 우려사항 + Code Design 분석 반영하며 구현 |
| 6 | Purpose Alignment | 구현이 요구사항과 일치하는지 확인 |
| 7-A | Expert Verification | 5개 도메인팀이 실제 diff 기반으로 보안/버그/성능 검증 |
| 7-B | Concern Cross-check | Step 4-B 사전 우려사항 대조, 누락 항목 보완 |
| 8 | Regression Check | Step 7 수정이 기존 기능을 깨뜨리지 않았는지 확인 |
| 9 | File/Function Split | 과대 함수/파일 분리 (50줄/300줄 기준) |
| 10 | Integration/Reuse | 중복 코드 발견 및 재사용 리팩토링 |
| 11 | Side Effect Check | 리팩토링이 동작을 변경하지 않았는지 확인 |
| 12 | Full Change Review | 전체 diff 코드 리뷰 |
| 13 | Dead Code Cleanup | 미사용 코드 제거 |
| 14 | Code Quality | 최종 코드 품질 평가 |
| 15 | Flow Verification | 백엔드/데이터/에러 흐름 정상 동작 확인 |
| 16 | MEDIUM Issues | 축적된 MEDIUM 이슈 일괄 처리 |
| 17 | Production Readiness | 최종 체크리스트 (빌드, 테스트, 보안) |

### Finalization

| Step | 이름 | 설명 |
|------|------|------|
| Integration | 통합 | 모든 유닛 커밋 통합, 충돌 해결, 빌드/테스트 통과 확인 |
| 18 | Work Report | 작업 보고서 생성 (Before/After, 트레이드오프, 리스크 등) |
| 18-B | Review Sequence | 변경사항을 논리적 변경 단위로 그룹핑, 계획과 매핑 |
| **19** | **Interactive Guided Review** | **계획 매핑 기반 인터랙티브 코드 리뷰 → PR 생성** |

## Step 19: 인터랙티브 가이드 리뷰

Step 19는 사용자와의 대화형 코드 리뷰 단계입니다.

### 19-A: 리뷰 개요 (계획 매핑 기반)

단순 통계가 아닌, **계획과 구현의 매핑**을 보여줍니다:

- **계획 요약 리마인드**: 원래 목표와 핵심 요구사항
- **구현 매핑 테이블**: 계획의 각 Unit이 어떤 변경 단위로 구현되었는지
- **변경 단위 간 관계도**: 변경들이 어떻게 맞물리는지 흐름 설명
- **리뷰 순서 안내**: 왜 이 순서로 진행하는지

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

리뷰 완료 후 PR을 생성합니다 (리뷰 전에 PR을 생성하지 않음):

- **Draft PR 생성** 또는 **Ready PR 생성** 선택
- Step 18 보고서 내용을 PR description에 포함
- 피드백은 `.claude/memory/feedback.md`에 영속 기록

## 리뷰 경로

| 경로 | 포함 Step | 용도 |
|------|-----------|------|
| SMALL | 5-8, 17 | 간단한 변경, 빠른 검증 |
| STANDARD | 5-17 전체 | 일반적인 기능 구현 |
| LARGE | 5-17 + 확장 분석 | 대규모 변경, 실패 모드 분석 포함 |

**참고:** Step 4-B(전문가 사전 리뷰)와 Step 19(인터랙티브 리뷰)는 모든 경로에서 실행됩니다.

## 전문가 패널 (5개 도메인팀)

전문가들은 개별 리뷰가 아닌 **팀 내 토론**을 통해 합의 기반으로 우려사항을 도출합니다.

### 팀 구성

| 팀 | 멤버 | 활성화 | 토론 초점 |
|----|------|--------|----------|
| **Safety** | appsec, auth, infrasec, stability | 항상 (appsec+stability) | 보안 경계, 인증 우회, 장애 복구 |
| **Code Design** | convention, idiom, design-pattern, testability | 항상 (convention+idiom) | 레포 컨벤션, 언어 관용구, 설계 패턴 |
| **Data** | rdbms, cache, nosql | auto-detect (min 2) | 데이터 일관성, 캐시 무효화, 스토리지 정합성 |
| **Integration** | sync-api, async, external-integration, messaging | auto-detect (min 2) | 동기/비동기 경계, 에러 전파, 장애 격리 |
| **Ops** | infra, observability, performance, concurrency | auto-detect (min 2) | 운영 안정성, 관측 가능성, 성능 |

### 팀 활성화 규칙

| 리뷰 경로 | 활성화 팀 |
|-----------|----------|
| SMALL | Safety + Code Design (always 멤버만) |
| STANDARD | Safety + Code Design + auto-detect된 Data/Integration/Ops |
| LARGE | 전체 + extended failure mode analysis |

### 전문가 개입 시점

전문가들은 **두 번** 개입합니다:
1. **Step 4-B** (사전 리뷰): 계획 검토 → 팀 내 토론으로 우려사항 도출 (CRITICAL/HIGH/MEDIUM)
2. **Step 7** (검증): 실제 구현(diff) 검증 + 사전 우려사항 누락 여부 대조

## 설정

`config.yaml`에서 커스터마이즈 가능합니다.

```yaml
# 주요 설정
model_policy: default           # 세션 기본 모델 사용
language: ko                    # 보고서 언어

# 유닛 제한
unit_limits:
  max_files: 5                  # 유닛당 최대 파일 수
  max_lines: 200                # 유닛당 최대 변경 줄 수

# 루프 제한
loop_limits:
  critic_planner: 3             # Step 2: 계획 수정 최대 반복
  step4b_critical: 2            # Step 4-B: CRITICAL 우려 시 계획 수정 최대 반복
  step7b_recheck: 1             # Step 7-B: 누락 우려 fix 후 재검증 최대 반복
  step7_8: 2                    # Step 7-8: 리뷰-리그레션 최대 반복
  step6_executor: 3             # Step 6: executor auto-fix 최대 시도
  step16: 3                     # Step 16: MEDIUM 이슈 해결 최대 반복

# 코드 크기 기준
size_thresholds:
  function_lines: 50
  file_lines: 300

# 전문가 패널
expert_panel:
  mode: agent-team              # 팀 토론 모드
  discussion_rounds: 2          # 팀 내 토론 라운드 수
  require_consensus: true       # severity 합의 필요 여부
```

## 디렉토리 구조

```
~/.claude/skills/simon-bot/
├── SKILL.md                    # 워크플로 정의
├── README.md                   # 이 파일
├── install.sh                  # 설치 스크립트
└── workflow/
    ├── config.yaml             # 기본 설정
    ├── prompts/                # 전문가 프롬프트 (22개)
    │   ├── appsec-expert.md
    │   ├── auth-expert.md
    │   ├── cache-expert.md
    │   ├── convention-expert.md
    │   ├── design-pattern-expert.md
    │   ├── idiom-expert.md
    │   ├── ...
    │   └── testability-expert.md
    ├── scripts/                # 검증 스크립트
    │   ├── check-sizes.sh
    │   ├── extract-diff.sh
    │   ├── find-dead-code.sh
    │   ├── manage-sessions.sh
    │   ├── run-tests.sh
    │   ├── setup-test-env.sh
    │   ├── typecheck.sh
    │   └── verify-build.sh
    └── templates/
        └── report-template.md  # 보고서 템플릿

{project}/.claude/
├── workflow/                   # 프로젝트별 워크플로 (install.sh로 생성)
├── memory/                     # 실행 메모리 (세션별 독립)
│   ├── branch-name.md
│   ├── plan-summary.md
│   ├── requirements.md
│   ├── code-design-analysis.md # Code Design Team 분석 결과
│   ├── expert-plan-concerns.md # Step 4-B 전문가 우려사항
│   ├── review-sequence.md      # Step 18-B 리뷰 시퀀스
│   ├── review-progress.md      # Step 19 리뷰 진행 상태
│   ├── feedback.md             # 영속 피드백 기록
│   ├── retrospective.md
│   └── unit-{name}/
└── reports/                    # 작업 보고서
```

## 세션 관리

```bash
# 세션 목록 확인
/simon-bot-sessions list

# 특정 세션 상세 정보
/simon-bot-sessions info feat/add-auth

# 세션 삭제
/simon-bot-sessions delete feat/add-auth

# 이전 세션 이어서 작업
/simon-bot-sessions resume feat/add-auth
```

## 설치

```bash
# 전역 + 프로젝트 초기화
bash ~/.claude/skills/simon-bot/install.sh

# 프로젝트만 초기화
bash ~/.claude/skills/simon-bot/install.sh --project-only

# 전역만 설치
bash ~/.claude/skills/simon-bot/install.sh --global
```
