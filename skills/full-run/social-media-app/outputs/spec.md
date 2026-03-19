# Feature Specification: InstaClone

## Vision
인스타그램과 유사한 소셜 미디어 웹앱. 사용자가 사진을 올리고, 다른 사용자를 팔로우하며, 좋아요/댓글로 소통하고, 최신순 피드와 알림 기능을 통해 소셜 경험을 제공한다.

## Target Users
- 사진을 공유하고 소셜 네트워킹을 즐기는 일반 사용자
- 예상 규모: 소규모 (수백 명 수준, SQLite 적합)

## Goals
- 직관적인 사진 공유 플랫폼 제공
- 팔로우 기반 소셜 그래프 구축
- 실시간성 있는 알림으로 참여 유도

## Non-Goals
- 스토리/릴스 등 동영상 기능
- 다이렉트 메시지 (DM)
- 해시태그 검색/탐색 탭
- 광고 시스템
- 모바일 네이티브 앱

---

## User Stories

### P1 (Must-have - MVP)

**US-001: 회원가입**
- As a 사용자, I want to 이메일과 비밀번호로 회원가입할 수 있다, so that 서비스를 이용할 수 있다.
- Size: S
- Acceptance Criteria:
  - Given 가입 페이지에 접속했을 때
  - When 이메일, 비밀번호, 사용자 이름을 입력하고 가입 버튼을 클릭하면
  - Then 계정이 생성되고 로그인 상태가 된다
  - Given 이미 존재하는 이메일로 가입 시도 시
  - Then 중복 에러 메시지가 표시된다

**US-002: 로그인/로그아웃**
- As a 사용자, I want to 이메일과 비밀번호로 로그인/로그아웃할 수 있다, so that 내 계정에 접근할 수 있다.
- Size: S
- Acceptance Criteria:
  - Given 로그인 페이지에 접속했을 때
  - When 올바른 이메일/비밀번호를 입력하면
  - Then JWT 토큰이 발급되고 메인 피드로 이동한다
  - Given 잘못된 비밀번호 입력 시
  - Then 인증 실패 에러가 표시된다

**US-003: 사진 게시물 업로드**
- As a 사용자, I want to 사진과 캡션을 올릴 수 있다, so that 내 사진을 공유할 수 있다.
- Size: M
- Acceptance Criteria:
  - Given 로그인 상태에서 업로드 페이지에 접속했을 때
  - When 사진 파일을 선택하고 캡션을 입력 후 게시 버튼을 클릭하면
  - Then 게시물이 생성되고 피드에 표시된다
  - Given 사진 파일 없이 게시 시도 시
  - Then 사진 필수 에러가 표시된다

**US-004: 피드 조회 (최신순)**
- As a 사용자, I want to 팔로우한 사용자들의 게시물을 최신순으로 볼 수 있다, so that 관심 있는 콘텐츠를 확인할 수 있다.
- Size: M
- Acceptance Criteria:
  - Given 로그인 후 메인 피드에 접속했을 때
  - When 피드를 스크롤하면
  - Then 팔로우한 사용자 + 내 게시물이 최신순으로 표시된다
  - Given 팔로우한 사용자가 없을 때
  - Then 빈 상태 메시지가 표시된다

**US-005: 팔로우/언팔로우**
- As a 사용자, I want to 다른 사용자를 팔로우/언팔로우할 수 있다, so that 관심 있는 사용자의 콘텐츠를 볼 수 있다.
- Size: S
- Acceptance Criteria:
  - Given 다른 사용자의 프로필을 볼 때
  - When 팔로우 버튼을 클릭하면
  - Then 해당 사용자를 팔로우하고 버튼이 '언팔로우'로 변경된다
  - When 언팔로우 버튼을 클릭하면
  - Then 팔로우가 해제된다

**US-006: 좋아요**
- As a 사용자, I want to 게시물에 좋아요를 누를 수 있다, so that 마음에 드는 콘텐츠에 반응할 수 있다.
- Size: S
- Acceptance Criteria:
  - Given 게시물을 볼 때
  - When 좋아요 버튼을 클릭하면
  - Then 좋아요가 추가되고 카운트가 증가한다
  - When 이미 좋아요한 게시물의 좋아요 버튼을 클릭하면
  - Then 좋아요가 취소되고 카운트가 감소한다

**US-007: 댓글**
- As a 사용자, I want to 게시물에 댓글을 달 수 있다, so that 의견을 나눌 수 있다.
- Size: S
- Acceptance Criteria:
  - Given 게시물의 댓글 입력란에 접근했을 때
  - When 댓글을 입력하고 등록 버튼을 클릭하면
  - Then 댓글이 게시물에 표시된다
  - Given 빈 댓글 등록 시도 시
  - Then 에러 메시지가 표시된다

**US-008: 사용자 프로필 페이지**
- As a 사용자, I want to 프로필 페이지에서 내 게시물과 정보를 볼 수 있다, so that 내 활동을 한눈에 확인할 수 있다.
- Size: M
- Acceptance Criteria:
  - Given 프로필 페이지에 접속했을 때
  - Then 사용자 이름, 게시물 수, 팔로워 수, 팔로잉 수, 게시물 그리드가 표시된다

**US-009: 알림**
- As a 사용자, I want to 나에게 발생한 이벤트(좋아요, 댓글, 팔로우)를 알림으로 받을 수 있다, so that 소셜 활동을 놓치지 않을 수 있다.
- Size: M
- Acceptance Criteria:
  - Given 다른 사용자가 내 게시물에 좋아요/댓글을 달거나 나를 팔로우했을 때
  - Then 알림 목록에 해당 이벤트가 추가된다
  - Given 알림 페이지에 접속했을 때
  - Then 최신순으로 알림 목록이 표시된다

### P2 (Nice-to-have)

**US-010: 프로필 수정**
- As a 사용자, I want to 이름과 소개를 수정할 수 있다, so that 프로필을 관리할 수 있다.
- Size: S

**US-011: 게시물 삭제**
- As a 사용자, I want to 내 게시물을 삭제할 수 있다, so that 원치 않는 콘텐츠를 제거할 수 있다.
- Size: S

### P3 (Out of scope for MVP)
- 스토리/릴스
- DM
- 해시태그
- 탐색 탭
- 프로필 사진 변경

---

## Functional Requirements

- FR-001: JWT 기반 인증 (access token)
- FR-002: 사진 업로드 시 로컬 파일시스템(public/uploads/)에 저장
- FR-003: 피드는 팔로우한 사용자 + 자기 게시물, 최신순 정렬
- FR-004: 좋아요는 토글 방식 (한 게시물에 한 번만)
- FR-005: 알림은 좋아요/댓글/팔로우 이벤트 생성
- FR-006: 비밀번호는 bcrypt 해시 저장
- FR-007: API 응답은 JSON 형식, 에러 코드 통일

---

## Edge Cases

- EC-001: 자기 자신을 팔로우 시도 → 거부
- EC-002: 동일 게시물에 중복 좋아요 → 토글 처리
- EC-003: 지원하지 않는 파일 형식 업로드 → 에러 (jpg, png, gif, webp만 허용)
- EC-004: 삭제된 게시물에 좋아요/댓글 시도 → 404 에러
- EC-005: 빈 캡션 허용 (사진만 올리기 가능)

---

## Key Entities

- User (id, email, password_hash, username, bio, created_at)
- Post (id, user_id, image_url, caption, created_at)
- Follow (id, follower_id, following_id, created_at)
- Like (id, user_id, post_id, created_at)
- Comment (id, user_id, post_id, content, created_at)
- Notification (id, user_id, actor_id, type, post_id, read, created_at)

---

## Success Criteria

- SC-001: 회원가입 → 사진 업로드 → 피드 확인 흐름이 동작한다
- SC-002: 팔로우 → 피드에 해당 사용자 게시물 표시된다
- SC-003: 좋아요/댓글 시 알림이 생성된다
- SC-004: 모든 API 응답 시간 < 500ms
- SC-005: 전체 테스트 통과 (0 failures)
