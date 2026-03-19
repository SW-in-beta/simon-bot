# Constitution: Picstory

## Core Principles
1. 사용자 경험 최우선 — 직관적이고 아름다운 인터페이스
2. 보안은 타협 불가 — 비밀번호 해싱, JWT 인증, 입력 검증
3. 단순함을 추구 — YAGNI/KISS, 필요한 것만 구현
4. 반응형 디자인 — 모바일 퍼스트, 모든 디바이스에서 사용 가능

## Quality Gates
- 테스트 커버리지: 80% 이상
- TRP 3라운드 통과 필수
- OWASP Top 10 기본 준수
- 빌드 + 린트 0 에러

## Constraints
- 기술 스택: Next.js (App Router) + TypeScript
- DB: SQLite (Prisma ORM) — MVP 규모에 적합
- 이미지 저장: 로컬 파일시스템 (MVP)
- 배포: Docker 컨테이너
- 시간 제약: 단일 세션 내 완성
