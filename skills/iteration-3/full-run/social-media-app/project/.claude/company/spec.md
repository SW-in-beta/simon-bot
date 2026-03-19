# Feature Specification: Picstory

## Overview
인스타그램 스타일의 소셜 미디어 웹앱. 사용자가 사진을 업로드하고, 다른 사용자를 팔로우하며, 좋아요/댓글로 소통할 수 있다. 피드는 최신순으로 표시되며, 알림 기능으로 사용자 간 상호작용을 실시간으로 전달한다.

## Target Users
- 사진을 공유하고 소셜 네트워킹을 즐기는 일반 사용자
- 예상 사용자 규모: 수백~수천 명 (MVP)

## User Stories

### P1 - Must Have (MVP)

**US-001: 이메일 회원가입**
As a 신규 사용자, I want to 이메일과 비밀번호로 회원가입을, so that 서비스를 이용할 수 있다.
- Given 회원가입 페이지에 접속했을 때
- When 이메일, 비밀번호, 사용자명을 입력하고 가입 버튼을 클릭하면
- Then 계정이 생성되고 자동 로그인된다
- Edge case: 중복 이메일 → 에러 메시지, 약한 비밀번호 → 유효성 검사 안내

**US-002: 로그인/로그아웃**
As a 가입된 사용자, I want to 이메일과 비밀번호로 로그인/로그아웃을, so that 내 계정에 안전하게 접근할 수 있다.
- Given 로그인 페이지에 접속했을 때
- When 올바른 이메일과 비밀번호를 입력하면
- Then JWT 토큰이 발급되고 메인 피드로 이동한다
- Edge case: 잘못된 비밀번호 → "이메일 또는 비밀번호가 잘못되었습니다" 에러

**US-003: 사진 게시물 작성**
As a 로그인된 사용자, I want to 사진과 캡션을 올려 게시물을 작성, so that 나의 순간을 공유할 수 있다.
- Given 게시물 작성 페이지에 접속했을 때
- When 사진을 선택하고 캡션을 입력 후 게시 버튼을 클릭하면
- Then 게시물이 생성되고 내 프로필과 팔로워 피드에 표시된다
- Edge case: 이미지 없이 게시 시도 → 에러, 너무 큰 파일 → 용량 제한 안내

**US-004: 피드 조회 (최신순)**
As a 로그인된 사용자, I want to 내가 팔로우하는 사용자들의 게시물을 최신순으로 볼 수 있도록, so that 최근 소식을 확인할 수 있다.
- Given 메인 피드 페이지에 접속했을 때
- When 페이지가 로드되면
- Then 팔로우한 사용자들의 게시물이 최신순으로 표시된다 (무한 스크롤)
- Edge case: 팔로우한 사용자가 없으면 → 추천 사용자 목록 표시

**US-005: 좋아요**
As a 로그인된 사용자, I want to 게시물에 좋아요를 누를 수 있도록, so that 마음에 드는 콘텐츠에 반응할 수 있다.
- Given 피드에서 게시물을 보고 있을 때
- When 하트 아이콘을 클릭하면
- Then 좋아요가 토글되고 좋아요 수가 업데이트된다
- Edge case: 이미 좋아요 누른 게시물 → 좋아요 취소

**US-006: 댓글**
As a 로그인된 사용자, I want to 게시물에 댓글을 달 수 있도록, so that 다른 사용자와 소통할 수 있다.
- Given 게시물 상세 페이지에서
- When 댓글을 입력하고 전송 버튼을 누르면
- Then 댓글이 게시물에 추가되고 실시간으로 표시된다
- Edge case: 빈 댓글 → 전송 불가

**US-007: 팔로우/언팔로우**
As a 로그인된 사용자, I want to 다른 사용자를 팔로우/언팔로우, so that 관심 있는 사용자의 게시물을 피드에서 볼 수 있다.
- Given 다른 사용자의 프로필 페이지에서
- When 팔로우 버튼을 클릭하면
- Then 해당 사용자를 팔로우하고 버튼이 '팔로잉'으로 변경된다
- Edge case: 자기 자신 팔로우 → 불가

**US-008: 프로필 페이지**
As a 사용자, I want to 내 프로필과 다른 사용자의 프로필을 볼 수 있도록, so that 게시물 목록과 팔로워/팔로잉 수를 확인할 수 있다.
- Given 프로필 페이지에 접속했을 때
- When 페이지가 로드되면
- Then 프로필 사진, 사용자명, 자기소개, 게시물 수, 팔로워/팔로잉 수, 게시물 그리드가 표시된다

**US-009: 알림**
As a 로그인된 사용자, I want to 나에게 온 좋아요, 댓글, 팔로우 알림을 볼 수 있도록, so that 다른 사용자의 반응을 놓치지 않는다.
- Given 알림 페이지에 접속했을 때
- When 페이지가 로드되면
- Then 최신 알림이 시간순으로 표시된다 (좋아요, 댓글, 팔로우)
- Edge case: 알림이 없으면 → "아직 알림이 없습니다" 표시

### P2 - Nice to Have

**US-010: 프로필 편집**
As a 로그인된 사용자, I want to 프로필 사진, 사용자명, 자기소개를 수정, so that 내 프로필을 관리할 수 있다.
- Given 프로필 편집 페이지에서
- When 정보를 수정하고 저장 버튼을 클릭하면
- Then 프로필이 업데이트된다

**US-011: 게시물 삭제**
As a 게시물 작성자, I want to 내 게시물을 삭제, so that 더 이상 원치 않는 콘텐츠를 제거할 수 있다.
- Given 내 게시물 상세 페이지에서
- When 삭제 버튼을 클릭하고 확인하면
- Then 게시물이 삭제되고 관련 좋아요, 댓글도 삭제된다

**US-012: 사용자 검색**
As a 사용자, I want to 사용자명으로 다른 사용자를 검색, so that 관심 있는 사용자를 찾을 수 있다.
- Given 검색 페이지에서
- When 검색어를 입력하면
- Then 사용자명이 매칭되는 사용자 목록이 표시된다

### P3 - Future

**US-013: 게시물 북마크**
**US-014: 다이렉트 메시지**
**US-015: 해시태그**

## Functional Requirements

- FR-001: 인증은 JWT 기반으로 구현
- FR-002: 이미지 업로드는 최대 5MB, JPEG/PNG만 허용
- FR-003: 피드는 커서 기반 페이지네이션 (20개씩)
- FR-004: 비밀번호는 bcrypt로 해싱
- FR-005: 알림은 좋아요, 댓글, 팔로우 3가지 유형
- FR-006: 반응형 디자인 (모바일/태블릿/데스크톱)

## Key Entities
- User (id, email, username, password_hash, display_name, bio, avatar_url)
- Post (id, user_id, image_url, caption, created_at)
- Like (id, user_id, post_id, created_at)
- Comment (id, user_id, post_id, content, created_at)
- Follow (id, follower_id, following_id, created_at)
- Notification (id, user_id, actor_id, type, post_id?, created_at, read)

## Success Criteria
- 회원가입 → 로그인 → 게시물 작성 → 피드 조회 흐름이 정상 동작
- 팔로우한 사용자의 게시물만 피드에 표시
- 좋아요/댓글 시 실시간 알림 생성
- 페이지 로딩 3초 이내
- 테스트 커버리지 80% 이상
