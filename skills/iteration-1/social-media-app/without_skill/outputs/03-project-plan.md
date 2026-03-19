# 프로젝트 계획 (Project Plan)

## 개요

- **프로젝트명:** PhotoShare (가칭) - 인스타그램형 소셜 미디어 웹앱
- **예상 기간:** 12주 (3개월)
- **스프린트 주기:** 2주
- **팀 규모:** 8명

---

## 마일스톤 및 스프린트 계획

### Phase 1: 기반 구축 (Sprint 1~2, 4주)

#### Sprint 1 (1~2주차): 프로젝트 셋업 및 인증

**목표:** 개발 환경 구축, 인증 시스템 완성

| 담당 | 태스크 | 예상 공수 |
|------|--------|-----------|
| PM | 프로젝트 킥오프, 도구 세팅 (GitHub, Linear, Slack) | 2d |
| 디자이너 | 디자인 시스템 정의 (컬러, 타이포, 컴포넌트 라이브러리) | 5d |
| 디자이너 | 로그인/회원가입/프로필 편집 와이어프레임 및 UI | 5d |
| FE 리드 | Next.js 프로젝트 초기화, 폴더 구조, ESLint/Prettier 설정 | 2d |
| FE 리드 | shadcn/ui 기반 디자인 시스템 컴포넌트 구현 | 3d |
| FE 리드 | 인증 UI (로그인, 회원가입, 비밀번호 재설정) | 5d |
| FE | 프로필 편집 페이지 UI | 3d |
| BE 리드 | 프로젝트 초기화, DB 스키마 설계 (ERD), API 규격 정의 | 3d |
| BE 리드 | 사용자 모델 + 인증 API (회원가입, 로그인, JWT) | 5d |
| BE | 소셜 로그인 (Google, Apple) OAuth 연동 | 3d |
| BE | 프로필 CRUD API | 2d |
| DevOps | CI/CD 파이프라인 구축 (GitHub Actions) | 2d |
| DevOps | 개발/스테이징 환경 구축 (Docker Compose) | 3d |

**Sprint 1 산출물:**
- 로그인/회원가입/프로필 편집 동작
- CI/CD 파이프라인 가동
- DB 스키마 v1 확정

---

#### Sprint 2 (3~4주차): 게시물 업로드 및 이미지 처리

**목표:** 사진 업로드 및 게시물 CRUD 완성

| 담당 | 태스크 | 예상 공수 |
|------|--------|-----------|
| 디자이너 | 게시물 작성/상세/피드 UI 디자인 | 5d |
| FE 리드 | 이미지 업로드 컴포넌트 (멀티 파일, 미리보기, 진행률) | 4d |
| FE 리드 | 게시물 작성 페이지 (캡션, 해시태그, 멘션) | 3d |
| FE | 게시물 상세 페이지 UI | 3d |
| FE | 이미지 캐러셀 컴포넌트 | 2d |
| BE 리드 | 이미지 업로드 API + S3 연동 | 3d |
| BE 리드 | 이미지 리사이징/압축 파이프라인 (Sharp/Lambda) | 3d |
| BE | 게시물 CRUD API | 3d |
| BE | 해시태그 파싱 및 저장 로직 | 2d |
| DevOps | S3 버킷 + CloudFront CDN 설정 | 2d |

**Sprint 2 산출물:**
- 사진 업로드 및 게시물 작성/수정/삭제 동작
- 이미지 자동 리사이징 및 CDN 배포

---

### Phase 2: 핵심 소셜 기능 (Sprint 3~4, 4주)

#### Sprint 3 (5~6주차): 피드 및 팔로우

**목표:** 홈 피드와 팔로우 시스템 완성

| 담당 | 태스크 | 예상 공수 |
|------|--------|-----------|
| 디자이너 | 프로필 페이지, 팔로워/팔로잉 목록 UI | 3d |
| 디자이너 | 탐색(Explore) 페이지 UI | 2d |
| FE 리드 | 홈 피드 페이지 (무한 스크롤, 커서 페이지네이션) | 4d |
| FE 리드 | 이미지 Lazy Loading + 가상화 최적화 | 2d |
| FE | 프로필 페이지 (게시물 그리드, 팔로워/팔로잉) | 4d |
| FE | 팔로우/언팔로우 버튼 + 팔로우 요청 UI | 3d |
| BE 리드 | 피드 API (최신순, 커서 기반 페이지네이션) | 4d |
| BE 리드 | 피드 캐싱 전략 (Redis) | 2d |
| BE | 팔로우/언팔로우 API | 2d |
| BE | 팔로우 요청 관리 API (비공개 계정) | 2d |
| BE | 프로필 페이지 API (게시물 그리드, 통계) | 2d |

**Sprint 3 산출물:**
- 팔로잉 기반 홈 피드 동작
- 팔로우/언팔로우 동작
- 프로필 페이지 완성

---

#### Sprint 4 (7~8주차): 좋아요, 댓글, 탐색

**목표:** 좋아요/댓글 상호작용 및 탐색 기능 완성

| 담당 | 태스크 | 예상 공수 |
|------|--------|-----------|
| 디자이너 | 알림 페이지 UI 디자인 | 3d |
| 디자이너 | 전체 UI 일관성 점검 및 마이크로 인터랙션 정의 | 2d |
| FE 리드 | 좋아요 기능 (Optimistic UI, 더블클릭 애니메이션) | 3d |
| FE | 댓글 시스템 UI (작성, 목록, 삭제) | 4d |
| FE | 탐색(Explore) 페이지 + 검색 (사용자, 해시태그) | 4d |
| FE | 좋아요 누른 사람 목록 모달 | 2d |
| BE 리드 | 좋아요 API (토글, 목록, 카운트) | 2d |
| BE 리드 | 검색 API (사용자명, 해시태그, 전문 검색) | 3d |
| BE | 댓글 CRUD API | 3d |
| BE | 탐색 페이지 API (공개 게시물 최신순) | 2d |
| QA | 테스트 케이스 작성 (인증, 게시물, 피드, 팔로우) | 3d |
| QA | 기능 테스트 수행 (Sprint 1~3 범위) | 2d |

**Sprint 4 산출물:**
- 좋아요/댓글 전체 동작
- 탐색 및 검색 기능 동작
- QA 1차 테스트 리포트

---

### Phase 3: 알림 및 폴리시 (Sprint 5~6, 4주)

#### Sprint 5 (9~10주차): 알림 시스템 및 실시간 기능

**목표:** 알림 시스템 전체 구현

| 담당 | 태스크 | 예상 공수 |
|------|--------|-----------|
| FE 리드 | 알림 페이지 (목록, 읽음/안읽음, 네비게이션 배지) | 4d |
| FE 리드 | WebSocket 연결 + 실시간 알림 토스트 | 3d |
| FE | 멘션 자동완성 컴포넌트 (게시물 캡션, 댓글) | 3d |
| FE | 반응형 레이아웃 점검 및 모바일 최적화 | 3d |
| BE 리드 | 알림 모델 설계 + 알림 생성 이벤트 시스템 | 3d |
| BE 리드 | WebSocket 서버 구축 (Socket.io) | 3d |
| BE | 알림 API (목록, 읽음 처리, 미읽은 수) | 3d |
| BE | 알림 이벤트 리스너 (좋아요, 댓글, 팔로우, 멘션) | 4d |
| QA | 알림 시나리오 테스트 | 2d |

**Sprint 5 산출물:**
- 전체 알림 시스템 동작 (인앱 + 실시간)
- 멘션 자동완성 동작
- 모바일 반응형 완성

---

#### Sprint 6 (11~12주차): 폴리시, 성능 최적화, 런칭 준비

**목표:** 버그 수정, 성능 최적화, 런칭 준비 완료

| 담당 | 태스크 | 예상 공수 |
|------|--------|-----------|
| FE 리드 | 성능 최적화 (번들 사이즈, LCP, CLS) | 3d |
| FE 리드 | SEO 메타태그 + OG 이미지 | 2d |
| FE | 에러 바운더리 + 빈 상태(Empty State) UI | 2d |
| FE | 접근성 점검 + 키보드 내비게이션 | 2d |
| BE 리드 | Rate Limiting + 보안 점검 | 2d |
| BE 리드 | API 응답 시간 최적화 (쿼리 튜닝, 인덱스) | 3d |
| BE | 에러 핸들링 통일 + 로깅 정비 | 2d |
| BE | 데이터 마이그레이션 스크립트 + 시드 데이터 | 2d |
| DevOps | 프로덕션 환경 구축 + SSL 인증서 | 3d |
| DevOps | 모니터링 (APM, 에러 트래킹) + 알림 설정 | 2d |
| QA | 전체 기능 회귀 테스트 | 3d |
| QA | 성능/부하 테스트 (k6 또는 Artillery) | 2d |
| QA | 크로스 브라우저 테스트 (Chrome, Safari, Firefox) | 2d |
| PM | 런칭 체크리스트 확인 | 1d |
| 디자이너 | 최종 UI/UX 리뷰 및 수정 | 2d |

**Sprint 6 산출물:**
- 프로덕션 배포 완료
- 모니터링 대시보드 가동
- QA 최종 테스트 리포트
- 런칭

---

## 타임라인 요약

```
Week  1-2   [Sprint 1] 프로젝트 셋업 + 인증
Week  3-4   [Sprint 2] 게시물 업로드 + 이미지 처리
Week  5-6   [Sprint 3] 피드 + 팔로우
Week  7-8   [Sprint 4] 좋아요 + 댓글 + 탐색
Week  9-10  [Sprint 5] 알림 시스템
Week 11-12  [Sprint 6] 폴리시 + 성능 최적화 + 런칭
```

---

## 리스크 관리

| 리스크 | 영향도 | 발생 가능성 | 대응 방안 |
|--------|--------|-------------|-----------|
| 이미지 처리 성능 병목 | 높음 | 중간 | 비동기 처리(큐), 사전 리사이징 규격 제한 |
| 실시간 알림 확장성 | 중간 | 중간 | Redis Pub/Sub 도입, 필요 시 별도 알림 서비스 분리 |
| 피드 API 느린 응답 | 높음 | 낮음 | Redis 캐싱, DB 인덱스 최적화, 필요 시 비정규화 |
| 팀원 이탈/병가 | 높음 | 낮음 | 코드 리뷰 문화로 지식 공유, 문서화 |
| 스코프 크리프 | 중간 | 높음 | MVP 범위 엄격 관리, 추가 요구사항은 백로그 |

---

## 데이터 모델 (ERD 개요)

### 핵심 테이블

```
users
  - id (PK, UUID)
  - username (UNIQUE)
  - email (UNIQUE)
  - password_hash
  - name
  - bio
  - profile_image_url
  - website
  - is_private (boolean)
  - created_at, updated_at, deleted_at

posts
  - id (PK, UUID)
  - user_id (FK → users)
  - caption
  - location
  - created_at, updated_at, deleted_at

post_images
  - id (PK, UUID)
  - post_id (FK → posts)
  - image_url
  - order (integer)
  - width, height

follows
  - id (PK)
  - follower_id (FK → users)
  - following_id (FK → users)
  - status (enum: pending, accepted)
  - created_at
  - UNIQUE(follower_id, following_id)

likes
  - id (PK)
  - user_id (FK → users)
  - post_id (FK → posts)
  - created_at
  - UNIQUE(user_id, post_id)

comments
  - id (PK, UUID)
  - user_id (FK → users)
  - post_id (FK → posts)
  - content
  - created_at, deleted_at

hashtags
  - id (PK)
  - name (UNIQUE)

post_hashtags
  - post_id (FK → posts)
  - hashtag_id (FK → hashtags)

notifications
  - id (PK, UUID)
  - recipient_id (FK → users)
  - actor_id (FK → users)
  - type (enum: like, comment, follow, follow_request, mention)
  - post_id (FK → posts, nullable)
  - comment_id (FK → comments, nullable)
  - is_read (boolean)
  - created_at
```

---

## API 엔드포인트 개요

### 인증
- `POST /api/auth/register` - 회원가입
- `POST /api/auth/login` - 로그인
- `POST /api/auth/refresh` - 토큰 갱신
- `POST /api/auth/logout` - 로그아웃
- `POST /api/auth/oauth/:provider` - 소셜 로그인

### 사용자
- `GET /api/users/:username` - 프로필 조회
- `PATCH /api/users/me` - 프로필 수정
- `GET /api/users/search?q=` - 사용자 검색

### 게시물
- `POST /api/posts` - 게시물 작성
- `GET /api/posts/:id` - 게시물 상세
- `PATCH /api/posts/:id` - 게시물 수정
- `DELETE /api/posts/:id` - 게시물 삭제
- `POST /api/posts/:id/images` - 이미지 업로드

### 피드
- `GET /api/feed` - 홈 피드 (최신순)
- `GET /api/explore` - 탐색 피드

### 팔로우
- `POST /api/users/:id/follow` - 팔로우
- `DELETE /api/users/:id/follow` - 언팔로우
- `GET /api/users/:id/followers` - 팔로워 목록
- `GET /api/users/:id/following` - 팔로잉 목록
- `GET /api/follow-requests` - 팔로우 요청 목록
- `POST /api/follow-requests/:id/accept` - 요청 승인
- `POST /api/follow-requests/:id/reject` - 요청 거절

### 좋아요
- `POST /api/posts/:id/like` - 좋아요 토글
- `GET /api/posts/:id/likes` - 좋아요 목록

### 댓글
- `POST /api/posts/:id/comments` - 댓글 작성
- `GET /api/posts/:id/comments` - 댓글 목록
- `DELETE /api/comments/:id` - 댓글 삭제

### 알림
- `GET /api/notifications` - 알림 목록
- `PATCH /api/notifications/:id/read` - 알림 읽음 처리
- `GET /api/notifications/unread-count` - 미읽은 알림 수

### 해시태그
- `GET /api/hashtags/search?q=` - 해시태그 검색
- `GET /api/hashtags/:name/posts` - 해시태그별 게시물
