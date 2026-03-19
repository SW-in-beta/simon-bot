# Test Plan: Picstory

## 1. Test Scope
- 대상: 전체 애플리케이션 (인증, 게시물 CRUD, 소셜 기능, 알림)
- 제외: 성능 테스트 (MVP 규모에서 불필요), E2E 브라우저 테스트 (Playwright 미설정)

## 2. Test Strategy

### Unit Tests (Phase 4 완료)
- Zod 유효성 검증 스키마: 6 test suites, 41 tests
- UI 컴포넌트 (Button, Input, Avatar, EmptyState): 렌더링, 이벤트, 상태 테스트
- 유틸리티 함수 (formatRelativeTime, cn): 포맷팅 로직 테스트
- 커버리지 목표: 80%+

### Integration Tests (수동 검증)
- 회원가입 → 로그인 → 게시물 작성 → 피드 조회 E2E 흐름
- 좋아요/댓글 → 알림 생성 → 알림 조회 흐름
- 팔로우 → 피드에 게시물 표시 흐름

### Security Tests
- 비밀번호 bcrypt 해싱 확인
- JWT 세션 관리 확인
- 이미지 업로드 타입/크기 검증
- 입력 검증 (Zod 스키마)
- 파일 소유권 확인 (게시물 삭제 시 작성자만 가능)

## 3. Pass Criteria
- 전체 41 tests PASS
- Build 성공 (0 errors)
- 보안 취약점 CRITICAL 없음
