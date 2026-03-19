# 데이터 모델 설계

## 1. ERD (Entity Relationship Diagram)

```
┌──────────────────┐       ┌──────────────────┐
│      users       │       │      posts       │
├──────────────────┤       ├──────────────────┤
│ id          (PK) │──┐    │ id          (PK) │
│ email            │  │    │ author_id   (FK) │──┐
│ password_hash    │  │    │ image_url        │  │
│ username         │  │    │ thumbnail_url    │  │
│ display_name     │  ├───>│ caption          │  │
│ profile_image_url│  │    │ location         │  │
│ bio              │  │    │ like_count       │  │
│ website_url      │  │    │ comment_count    │  │
│ follower_count   │  │    │ is_edited        │  │
│ following_count  │  │    │ created_at       │  │
│ post_count       │  │    │ updated_at       │  │
│ username_changed │  │    │ deleted_at       │  │
│ is_active        │  │    └──────────────────┘  │
│ created_at       │  │                           │
│ updated_at       │  │    ┌──────────────────┐  │
│ deleted_at       │  │    │     follows      │  │
└──────────────────┘  │    ├──────────────────┤  │
                      │    │ id          (PK) │  │
                      ├───>│ follower_id (FK) │  │
                      ├───>│ following_id(FK) │  │
                      │    │ created_at       │  │
                      │    └──────────────────┘  │
                      │                           │
                      │    ┌──────────────────┐  │
                      │    │      likes       │  │
                      │    ├──────────────────┤  │
                      │    │ id          (PK) │  │
                      ├───>│ user_id     (FK) │  │
                      │    │ post_id     (FK) │<─┤
                      │    │ created_at       │  │
                      │    └──────────────────┘  │
                      │                           │
                      │    ┌──────────────────┐  │
                      │    │    comments      │  │
                      │    ├──────────────────┤  │
                      │    │ id          (PK) │  │
                      ├───>│ author_id   (FK) │  │
                      │    │ post_id     (FK) │<─┘
                      │    │ content          │
                      │    │ created_at       │
                      │    │ deleted_at       │
                      │    └──────────────────┘
                      │
                      │    ┌──────────────────┐
                      │    │  notifications   │
                      │    ├──────────────────┤
                      │    │ id          (PK) │
                      ├───>│ recipient_id(FK) │
                      ├───>│ actor_id    (FK) │
                      │    │ type             │
                      │    │ post_id     (FK) │
                      │    │ comment_id  (FK) │
                      │    │ is_read          │
                      │    │ created_at       │
                      │    └──────────────────┘
                      │
                      │    ┌──────────────────┐
                      │    │ refresh_tokens   │
                      │    ├──────────────────┤
                      │    │ id          (PK) │
                      └───>│ user_id     (FK) │
                           │ token_hash       │
                           │ expires_at       │
                           │ is_revoked       │
                           │ created_at       │
                           └──────────────────┘
```

## 2. 테이블 상세 정의

### 2.1 users (사용자)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 사용자 고유 ID |
| email | VARCHAR(255) | NOT NULL, UNIQUE | 이메일 |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt 해싱된 비밀번호 |
| username | VARCHAR(20) | NOT NULL, UNIQUE | 사용자명 (3~20자, 영문/숫자/밑줄) |
| display_name | VARCHAR(50) | NOT NULL | 표시 이름 |
| profile_image_url | VARCHAR(512) | NULL | 프로필 이미지 URL |
| bio | VARCHAR(150) | NULL | 자기소개 |
| website_url | VARCHAR(255) | NULL | 웹사이트 URL |
| follower_count | INTEGER | NOT NULL, DEFAULT 0 | 팔로워 수 (비정규화) |
| following_count | INTEGER | NOT NULL, DEFAULT 0 | 팔로잉 수 (비정규화) |
| post_count | INTEGER | NOT NULL, DEFAULT 0 | 게시물 수 (비정규화) |
| username_changed_at | TIMESTAMPTZ | NULL | 사용자명 최종 변경일 |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | 계정 활성 여부 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성 시간 |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 수정 시간 |
| deleted_at | TIMESTAMPTZ | NULL | 소프트 삭제 시간 |

**인덱스:**
- `idx_users_email` - UNIQUE ON (email) WHERE deleted_at IS NULL
- `idx_users_username` - UNIQUE ON (username) WHERE deleted_at IS NULL
- `idx_users_username_trgm` - GIN (username gin_trgm_ops) -- 검색용
- `idx_users_display_name_trgm` - GIN (display_name gin_trgm_ops) -- 검색용

---

### 2.2 posts (게시물)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 게시물 고유 ID |
| author_id | UUID | NOT NULL, FK(users.id) | 작성자 ID |
| image_url | VARCHAR(512) | NOT NULL | 원본 이미지 URL |
| thumbnail_url | VARCHAR(512) | NOT NULL | 썸네일 이미지 URL |
| caption | TEXT | NULL | 캡션 (최대 2,200자) |
| location | VARCHAR(100) | NULL | 위치 정보 |
| like_count | INTEGER | NOT NULL, DEFAULT 0 | 좋아요 수 (비정규화) |
| comment_count | INTEGER | NOT NULL, DEFAULT 0 | 댓글 수 (비정규화) |
| is_edited | BOOLEAN | NOT NULL, DEFAULT false | 수정 여부 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성 시간 |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 수정 시간 |
| deleted_at | TIMESTAMPTZ | NULL | 소프트 삭제 시간 |

**인덱스:**
- `idx_posts_author_id` - ON (author_id, created_at DESC) WHERE deleted_at IS NULL
- `idx_posts_created_at` - ON (created_at DESC) WHERE deleted_at IS NULL
- `idx_posts_explore` - ON (like_count DESC, created_at DESC) WHERE deleted_at IS NULL -- 탐색 피드용

---

### 2.3 follows (팔로우)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 고유 ID |
| follower_id | UUID | NOT NULL, FK(users.id) | 팔로우 하는 사용자 |
| following_id | UUID | NOT NULL, FK(users.id) | 팔로우 받는 사용자 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성 시간 |

**제약조건:**
- `uq_follows_pair` - UNIQUE ON (follower_id, following_id)
- `chk_follows_no_self` - CHECK (follower_id != following_id)

**인덱스:**
- `idx_follows_follower` - ON (follower_id, created_at DESC)
- `idx_follows_following` - ON (following_id, created_at DESC)

---

### 2.4 likes (좋아요)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 고유 ID |
| user_id | UUID | NOT NULL, FK(users.id) | 좋아요 한 사용자 |
| post_id | UUID | NOT NULL, FK(posts.id) | 좋아요 받은 게시물 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성 시간 |

**제약조건:**
- `uq_likes_user_post` - UNIQUE ON (user_id, post_id)

**인덱스:**
- `idx_likes_post_id` - ON (post_id, created_at DESC) -- 좋아요 목록 조회
- `idx_likes_user_id` - ON (user_id, post_id) -- 좋아요 여부 확인

---

### 2.5 comments (댓글)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 고유 ID |
| author_id | UUID | NOT NULL, FK(users.id) | 작성자 ID |
| post_id | UUID | NOT NULL, FK(posts.id) | 게시물 ID |
| content | VARCHAR(1000) | NOT NULL | 댓글 내용 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성 시간 |
| deleted_at | TIMESTAMPTZ | NULL | 소프트 삭제 시간 |

**인덱스:**
- `idx_comments_post_id` - ON (post_id, created_at ASC) WHERE deleted_at IS NULL

---

### 2.6 notifications (알림)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 고유 ID |
| recipient_id | UUID | NOT NULL, FK(users.id) | 알림 수신자 |
| actor_id | UUID | NOT NULL, FK(users.id) | 알림 행위자 |
| type | VARCHAR(20) | NOT NULL | 알림 유형 (like, comment, follow) |
| post_id | UUID | NULL, FK(posts.id) | 관련 게시물 (like, comment) |
| comment_id | UUID | NULL, FK(comments.id) | 관련 댓글 (comment) |
| is_read | BOOLEAN | NOT NULL, DEFAULT false | 읽음 여부 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성 시간 |

**제약조건:**
- `chk_notification_type` - CHECK (type IN ('like', 'comment', 'follow'))
- `chk_notification_no_self` - CHECK (recipient_id != actor_id)

**인덱스:**
- `idx_notifications_recipient` - ON (recipient_id, created_at DESC)
- `idx_notifications_unread` - ON (recipient_id) WHERE is_read = false

---

### 2.7 refresh_tokens (리프레시 토큰)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|----------|------|
| id | UUID | PK, DEFAULT gen_random_uuid() | 고유 ID |
| user_id | UUID | NOT NULL, FK(users.id) | 사용자 ID |
| token_hash | VARCHAR(255) | NOT NULL, UNIQUE | 토큰 해시값 |
| expires_at | TIMESTAMPTZ | NOT NULL | 만료 시간 |
| is_revoked | BOOLEAN | NOT NULL, DEFAULT false | 폐기 여부 |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성 시간 |

**인덱스:**
- `idx_refresh_tokens_hash` - UNIQUE ON (token_hash)
- `idx_refresh_tokens_user` - ON (user_id) WHERE is_revoked = false

---

## 3. 비정규화 전략

성능을 위해 다음 카운터 필드를 비정규화한다:

| 테이블 | 컬럼 | 동기화 방식 |
|--------|------|-------------|
| users | follower_count | follows 테이블 INSERT/DELETE 트리거 |
| users | following_count | follows 테이블 INSERT/DELETE 트리거 |
| users | post_count | posts 테이블 INSERT/DELETE 트리거 |
| posts | like_count | likes 테이블 INSERT/DELETE 트리거 |
| posts | comment_count | comments 테이블 INSERT/DELETE 트리거 |

카운터 불일치 방지를 위한 주기적 보정 배치 작업 필요 (일 1회).

## 4. 피드 쿼리 전략

### 홈 피드 쿼리 (최신순)
```sql
SELECT p.*, u.username, u.display_name, u.profile_image_url
FROM posts p
JOIN users u ON p.author_id = u.id
WHERE p.author_id IN (
  SELECT following_id FROM follows WHERE follower_id = :current_user_id
  UNION ALL
  SELECT :current_user_id  -- 자신의 게시물 포함
)
AND p.deleted_at IS NULL
AND p.created_at < :cursor
ORDER BY p.created_at DESC
LIMIT :limit;
```

팔로잉 수가 많은 경우 성능 이슈가 발생할 수 있으므로, 향후 Fan-out on write 패턴 또는 Redis Timeline 도입을 고려한다.

## 5. Redis 활용 계획

| 키 패턴 | 용도 | TTL |
|---------|------|-----|
| `user:{id}:unread_notifications` | 읽지 않은 알림 수 | 없음 |
| `post:{id}:liked_by:{user_id}` | 좋아요 여부 캐시 | 1시간 |
| `session:blacklist:{token_hash}` | 로그아웃된 토큰 | 토큰 만료시간 |
| `ratelimit:{user_id}:{endpoint}` | Rate Limiting | 윈도우 크기 |
