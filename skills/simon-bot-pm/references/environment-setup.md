# Environment Setup Detail

Phase 3의 상세 프로세스. SKILL.md에서 참조한다.

---

## Scope Guard

Feature Spec에 명시된 환경 구성만 수행한다. Spec에 없는 추상화 레이어, 유틸리티 모듈, 미래를 위한 확장 포인트 등을 선제적으로 만들지 않는다. 실제로 필요해지는 시점에 추가하는 것이 복잡성을 낮게 유지하는 방법이다.

## 3-A: Project Scaffolding (Greenfield Only)

`executor` 에이전트로 프로젝트 뼈대 생성:
- 디렉토리 구조
- 패키지 매니저 초기화 (package.json, go.mod, requirements.txt 등)
- 기본 설정 파일 (.gitignore, .editorconfig, linter 설정 등)
- CI/CD 기본 설정 (해당 시)
- README.md 초안

## 3-B: Dependencies & Tooling

PRD의 기술 스택에 따라:
- 핵심 의존성 설치
- 개발 도구 설정 (테스트 프레임워크, 린터 등)
- 빌드 스크립트 설정
- 빌드 + 초기 테스트 통과 확인

## 3-C: Git Setup

- Git 초기화 (greenfield) 또는 브랜치 생성 (existing)
  - **Existing 프로젝트 브랜치 생성 시 필수 패턴**:
    ```bash
    git fetch origin {base_branch} && git checkout -b {branch-name} origin/{base_branch}
    ```
    로컬 `{base_branch}`에서 브랜치를 생성하면 원격에 이미 머지된 커밋을 놓칠 수 있다.
- 초기 커밋
- `.claude/workflow/` 설정 (simon-bot 인프라)

## 3-D: 환경 검증

- 빌드 성공 확인
- 테스트 실행 가능 확인
- 개발 서버 기동 확인 (해당 시)

Save: 환경 세팅 결과를 `.claude/pm/progress.md`에 기록

### Phase 3 완료 시 상태 저장

Phase 3 완료 시 `state.json`을 갱신하여 Phase 4 진입 준비를 기록한다:
- `current_phase`: 4
- `completed_phases`: [0, 1, 2, 3]
- `env_verified`: true
- `load_files`: Phase 4에서 필요한 파일 목록 (prd.md, tasks.json, constitution.md, tasks/*/spec.md)
