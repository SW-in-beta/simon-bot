# Constitution: InstaClone

## Core Principles
1. 사용자 경험 최우선 - 직관적이고 반응형인 UI
2. 보안은 타협 불가 - 비밀번호 해싱, JWT 인증, 입력 검증
3. 단순함 우선 - YAGNI/KISS 원칙, 과도한 엔지니어링 금지
4. TDD 준수 - 실패하는 테스트 없이 프로덕션 코드를 작성하지 않는다

## Quality Gates
- 테스트 커버리지: 80% 이상
- TRP 3라운드 통과 필수
- API 응답 시간: < 500ms
- 빌드 성공 + 린트 통과
- 에러 응답 형식 통일 (code + message)
- SQL Injection 방지 (파라미터화 쿼리)
- XSS 방지 (입력 검증 + 출력 이스케이프)

## Constraints
- 기술 스택: Next.js 14+ (App Router), React, Tailwind CSS, SQLite (better-sqlite3), JWT
- 이미지 저장: 로컬 파일시스템 (public/uploads/)
- 외부 서비스 의존 없음 (클라우드 스토리지, 외부 DB 등)
- 단일 서버 배포 (모놀리식)
- 피드 알고리즘: 최신순 정렬만 (추천 알고리즘 없음)
