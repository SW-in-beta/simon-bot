# Global Forbidden Rules (공통 참조)

simon-bot 스킬 패밀리 전체에서 공유하는 금지 규칙. 모든 스킬은 이 파일을 참조한다.

## 되돌릴 수 없는 작업 — 안전한 대안을 사용한다

아래 작업은 실행 후 되돌릴 수 없다. 모든 항목에 안전한 대안이 존재하며, `forbidden-guard.sh` PreToolUse 훅이 결정론적으로 차단하므로 컨텍스트 압축이나 장시간 세션에서도 우회되지 않는다.

| 위험 작업 | 위험성 | 안전한 대안 |
|---|---|---|
| `git push --force` | 다른 사람의 커밋 영구 삭제 | `git push --force-with-lease` |
| `git merge` to main/master | 리뷰 없이 프로덕션 변경 | PR을 통해 병합 |
| `rm -rf` | 복구 불가능한 삭제 | 개별 파일 삭제 + 삭제 전 확인 |
| `DROP TABLE` / `TRUNCATE` | 데이터 영구 손실 | 트랜잭션 내 soft delete 또는 백업 후 진행 |
| `.env`/시크릿 커밋 | git 히스토리에 영구 기록 | `.gitignore`에 추가 + env.example 커밋 |
| `chmod 777` | 전체 권한 부여로 보안 경계 파괴 | 최소 필요 권한만 부여 (`chmod 644`, `755`) |
| `eval` with untrusted input | RCE 취약점 | 입력 검증 후 명시적 명령 실행 |
| `curl \| sh` / `wget \| sh` | 원격 코드 검증 없이 실행 | 다운로드 → 검토 → 실행 분리 |
| 테스트에서 실제 DB/외부 API 호출 | 프로덕션 데이터 손상 | mock/stub 사용 (localhost 테스트 DB는 CONTEXT-SENSITIVE 참조) |

## Runtime Guard (P-008)

에이전트가 지시문을 잊거나 무시하는 것을 구조적으로 방지한다:
- **Git Diff 기반 스코프 검증**: 리뷰/검증 Step 진입 시 변경 파일만 대상으로 작업
- **Auto-Verification Hook 준수 확인**: 소스코드 수정 후 빌드/린트 실행 여부 재확인
- **Anti-Hallucination**: 읽지 않은 파일에 대한 의견 제시를 감지하면 즉시 중단하고 Read 실행

## CONTEXT-SENSITIVE — 대상을 검증한 후 판단

실행 전에 대상이 안전한지(localhost, 테스트 서버, 로컬 DB 등) 확인한다. 판단 근거를 `.claude/memory/audit-log.md`에 기록한다.

- `curl`/`wget` to external endpoints — 대상이 localhost 또는 테스트 서버인지 확인 후 실행. 프로덕션 엔드포인트는 ABSOLUTE FORBIDDEN.
- `mysql`/`psql`/`redis-cli`/`mongosh` — 대상이 로컬 개발용 DB인지 확인 후 실행. 프로덕션/스테이징 DB는 ABSOLUTE FORBIDDEN.
- `ssh`/`scp`/`sftp` — 대상이 로컬 테스트 환경인지 확인 후 실행. 프로덕션 서버는 ABSOLUTE FORBIDDEN.

## AUDIT-REQUIRED — 실행 가능하나 감사 로그에 기록

의도치 않은 부작용을 추적하기 위해 실행 내역을 `.claude/memory/audit-log.md`에 기록한다.

- 특정 파일 삭제 (`rm` 단일 파일) — 삭제 대상과 사유를 기록
- DB 읽기 전용 쿼리 (SELECT) — 쿼리 내용과 대상 DB를 기록
- 환경 변수 변경 — 변경 전후 값을 기록
