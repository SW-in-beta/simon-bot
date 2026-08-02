# Global Forbidden Rules (공통 참조)

simon 스킬 패밀리 전체에서 공유하는 금지 규칙. 모든 스킬은 이 파일을 참조한다.

## 되돌릴 수 없는 작업 — 안전한 대안을 사용한다

아래 작업은 실행 후 되돌릴 수 없고 모든 항목에 안전한 대안이 존재한다. **Enforcement 열을 반드시 확인한다** — `HOOK`으로 표시된 항목만 `forbidden-guard.sh` PreToolUse 훅이 명령어 문자열 매칭으로 결정론적 차단하며, 컨텍스트 압축이나 장시간 세션에서도 우회되지 않는다. `LLM-SELF`는 명령어 텍스트만으로 판별이 불가능해 훅 매칭 규칙이 없는 항목이므로, 자기 판단에 전적으로 의존한다 — 여기가 실제로 뚫리는 지점이니 더 주의한다.

| 위험 작업 | 위험성 | 안전한 대안 | Enforcement |
|---|---|---|---|
| `git push --force` | 다른 사람의 커밋 영구 삭제 | `git push --force-with-lease` | HOOK |
| `git merge` to main/master | 리뷰 없이 프로덕션 변경 | PR을 통해 병합 | HOOK |
| `rm -rf` | 복구 불가능한 삭제 | 개별 파일 삭제 + 삭제 전 확인 | HOOK |
| `DROP TABLE` / `TRUNCATE` | 데이터 영구 손실 | 트랜잭션 내 soft delete 또는 백업 후 진행 | HOOK |
| `.env`/시크릿 커밋 | git 히스토리에 영구 기록 | `.gitignore`에 추가 + env.example 커밋 | HOOK |
| `chmod 777` | 전체 권한 부여로 보안 경계 파괴 | 최소 필요 권한만 부여 (`chmod 644`, `755`) | HOOK |
| `eval` with untrusted input | RCE 취약점 | 입력 검증 후 명시적 명령 실행 | HOOK |
| `curl \| sh` / `wget \| sh` | 원격 코드 검증 없이 실행 | 다운로드 → 검토 → 실행 분리 | HOOK |
| 테스트에서 실제 DB/외부 API 호출 | 프로덕션 데이터 손상 | mock/stub 사용 (localhost 테스트 DB는 CONTEXT-SENSITIVE 참조) | **LLM-SELF** — 명령어만으로 "테스트 맥락"을 판별할 수 없어 훅 규칙이 없다. 비-localhost 호스트 차단은 mysql/psql CONTEXT-SENSITIVE 규칙이 부분 커버한다 |

## PR 생성 규칙 — Draft 필수, simon-code-review 외 직접 생성 금지

| 위험 작업 | 위험성 | 안전한 대안 |
|---|---|---|
| `gh pr create` (--draft 없이) | 불완전한 코드가 리뷰 가능 상태로 공개 | 반드시 `gh pr create --draft` 사용 |
| simon/grind/pm이 직접 `gh pr create` 실행 | Step 18-19(리뷰 시퀀스 생성 + 인라인 리뷰)가 누락됨 | Step 19에서 simon-code-review 스킬을 호출하여 PR 생성을 위임 |

> `gh pr create`는 **simon-code-review 스킬 내부에서만** 실행한다. simon/simon-grind/simon-pm이 직접 실행하는 것은 금지다. 만약 어떤 이유로 직접 실행해야 하는 경우, 반드시 `--draft` 플래그를 포함해야 한다.

## CONTEXT-SENSITIVE — 대상을 검증한 후 판단

실행 전에 대상이 안전한지(localhost, 테스트 서버, 로컬 DB 등) 확인한다. 판단 근거를 `.claude/memory/audit-log.md`에 기록한다.

- `curl`/`wget` to external endpoints — 대상이 localhost 또는 테스트 서버인지 확인 후 실행. 프로덕션 엔드포인트는 ABSOLUTE FORBIDDEN.
- `mysql`/`psql`/`redis-cli`/`mongosh` — 대상이 로컬 개발용 DB인지 확인 후 실행. 프로덕션/스테이징 DB는 ABSOLUTE FORBIDDEN.
- `ssh`/`scp` — 현재 hook이 대상 무관 전체 차단한다 (구현이 문서보다 보수적). 필요 시 사용자에게 직접 실행을 요청한다. (`sftp`는 hook 정규식에 미포함 — 대상 검증 후 판단하는 기존 원칙 그대로 적용)

## AUDIT-REQUIRED — 실행 가능하나 감사 로그에 기록

기록은 `audit-logger.sh` PostToolUse hook이 자동 수행한다 (git 레포 안에서는 `{SESSION_DIR}/memory/audit-log.md`, 밖에서는 `~/.claude/memory/audit-log.md`). 판단 근거·사유 등 맥락 정보는 에이전트가 보완 기록한다. (새 세션부터 활성)

의도치 않은 부작용을 추적하기 위해 실행 내역을 `.claude/memory/audit-log.md`에 기록한다.

- 특정 파일 삭제 (`rm` 단일 파일) — 삭제 대상과 사유를 기록
- DB 읽기 전용 쿼리 (SELECT) — 쿼리 내용과 대상 DB를 기록
- 환경 변수 변경 — 변경 전후 값을 기록

## LLM Self-Check 항목 (hook으로 강제 불가능 — 매 Step 자기 검증)

아래 항목은 의미론적 판단이라 bash hook으로 차단할 수 없다. "hook이 자동 차단하는" 위 계층들과 달리, 에이전트가 Step 종료 시 스스로 점검해야 한다:
- **Git Diff 기반 스코프 검증**: 리뷰/검증 Step 진입 시 변경 파일만 대상으로 작업했는가
- **Auto-Verification Hook 준수**: 소스코드 수정 후 빌드/린트가 실행되었는가 (실행 자체는 auto-verify.sh가 강제하나, 결과 반영은 판단 영역)
- **Anti-Hallucination**: 읽지 않은 파일에 대해 의견을 제시하지 않았는가 — 위반 감지 시 즉시 중단하고 Read
