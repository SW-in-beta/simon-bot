# API 설계 (RESTful API)

## 공통 사항

### 기본 URL
```
https://api.snapshare.app/v1
```

### 인증
- Bearer Token (JWT) 방식
- `Authorization: Bearer <access_token>`
- 인증 불필요 엔드포인트: 회원가입, 로그인, 공개 프로필 조회

### 응답 형식
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "cursor": "next_cursor_value",
    "has_more": true
  }
}
```

### 에러 응답 형식
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "사용자명은 3자 이상이어야 합니다",
    "details": [
      {
        "field": "username",
        "message": "최소 3자 이상 입력해주세요"
      }
    ]
  }
}
```

### HTTP 상태 코드
| 코드 | 의미 |
|------|------|
| 200 | 성공 |
| 201 | 생성 성공 |
| 204 | 삭제 성공 (본문 없음) |
| 400 | 잘못된 요청 |
| 401 | 인증 실패 |
| 403 | 권한 없음 |
| 404 | 리소스 없음 |
| 409 | 충돌 (중복) |
| 429 | Rate Limit 초과 |
| 500 | 서버 에러 |

---

## 1. 인증 (Auth)

### POST /auth/signup
회원가입
```
Request Body:
{
  "email": "user@example.com",
  "password": "SecureP@ss1",
  "username": "john_doe",
  "display_name": "John Doe"
}

Response 201:
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "john_doe",
      "display_name": "John Doe",
      "profile_image_url": null,
      "created_at": "2026-03-07T00:00:00Z"
    },
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "expires_in": 900
    }
  }
}
```

### POST /auth/login
로그인
```
Request Body:
{
  "email": "user@example.com",
  "password": "SecureP@ss1"
}

Response 200:
{
  "success": true,
  "data": {
    "user": { ... },
    "tokens": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "expires_in": 900
    }
  }
}
```

### POST /auth/logout
로그아웃 (인증 필요)
```
Request Body:
{
  "refresh_token": "eyJ..."
}

Response 204: (본문 없음)
```

### POST /auth/refresh
토큰 갱신
```
Request Body:
{
  "refresh_token": "eyJ..."
}

Response 200:
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "expires_in": 900
  }
}
```

---

## 2. 사용자 (Users)

### GET /users/:username
사용자 프로필 조회
```
Response 200:
{
  "success": true,
  "data": {
    "id": "uuid",
    "username": "john_doe",
    "display_name": "John Doe",
    "profile_image_url": "https://cdn.snapshare.app/profiles/uuid.webp",
    "bio": "사진 찍는 것을 좋아합니다",
    "website_url": "https://johndoe.com",
    "post_count": 42,
    "follower_count": 1234,
    "following_count": 567,
    "is_following": false,
    "is_followed_by": true
  }
}
```

### PATCH /users/me
내 프로필 수정 (인증 필요)
```
Request Body (multipart/form-data):
{
  "display_name": "John Updated",
  "username": "john_updated",
  "bio": "새로운 자기소개",
  "website_url": "https://new-site.com",
  "profile_image": <file>
}

Response 200:
{
  "success": true,
  "data": {
    "id": "uuid",
    "username": "john_updated",
    "display_name": "John Updated",
    "profile_image_url": "https://cdn.snapshare.app/profiles/uuid-v2.webp",
    "bio": "새로운 자기소개",
    "website_url": "https://new-site.com"
  }
}
```

### GET /users/:username/posts
사용자의 게시물 목록 조회
```
Query Parameters:
  cursor (optional): 페이지네이션 커서
  limit (optional, default=12): 한 번에 가져올 개수

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "image_url": "https://cdn.snapshare.app/posts/uuid.webp",
      "thumbnail_url": "https://cdn.snapshare.app/posts/uuid-thumb.webp",
      "like_count": 42,
      "comment_count": 7,
      "created_at": "2026-03-06T12:00:00Z"
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

---

## 3. 게시물 (Posts)

### POST /posts
게시물 작성 (인증 필요)
```
Request Body (multipart/form-data):
{
  "image": <file>,
  "caption": "오늘의 풍경 #sunset",
  "location": "서울, 한국"
}

Response 201:
{
  "success": true,
  "data": {
    "id": "uuid",
    "image_url": "https://cdn.snapshare.app/posts/uuid.webp",
    "thumbnail_url": "https://cdn.snapshare.app/posts/uuid-thumb.webp",
    "caption": "오늘의 풍경 #sunset",
    "location": "서울, 한국",
    "author": {
      "id": "uuid",
      "username": "john_doe",
      "display_name": "John Doe",
      "profile_image_url": "https://cdn.snapshare.app/profiles/uuid.webp"
    },
    "like_count": 0,
    "comment_count": 0,
    "is_liked": false,
    "created_at": "2026-03-07T10:00:00Z"
  }
}
```

### GET /posts/:id
게시물 상세 조회 (인증 필요)
```
Response 200:
{
  "success": true,
  "data": {
    "id": "uuid",
    "image_url": "https://cdn.snapshare.app/posts/uuid.webp",
    "caption": "오늘의 풍경 #sunset",
    "location": "서울, 한국",
    "author": {
      "id": "uuid",
      "username": "john_doe",
      "display_name": "John Doe",
      "profile_image_url": "..."
    },
    "like_count": 42,
    "comment_count": 7,
    "is_liked": true,
    "is_edited": false,
    "created_at": "2026-03-07T10:00:00Z",
    "updated_at": "2026-03-07T10:00:00Z"
  }
}
```

### PATCH /posts/:id
게시물 수정 (인증 필요, 본인만)
```
Request Body:
{
  "caption": "수정된 캡션",
  "location": "부산, 한국"
}

Response 200:
{
  "success": true,
  "data": { ... (게시물 상세) }
}
```

### DELETE /posts/:id
게시물 삭제 (인증 필요, 본인만)
```
Response 204: (본문 없음)
```

---

## 4. 피드 (Feed)

### GET /feed
홈 피드 (인증 필요)
```
Query Parameters:
  cursor (optional): 페이지네이션 커서
  limit (optional, default=10): 한 번에 가져올 개수

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "image_url": "https://cdn.snapshare.app/posts/uuid.webp",
      "caption": "오늘의 풍경",
      "location": "서울, 한국",
      "author": {
        "id": "uuid",
        "username": "jane_smith",
        "display_name": "Jane Smith",
        "profile_image_url": "..."
      },
      "like_count": 42,
      "comment_count": 7,
      "is_liked": false,
      "recent_comments": [
        {
          "id": "uuid",
          "content": "멋진 사진이네요!",
          "author": {
            "username": "another_user",
            "profile_image_url": "..."
          },
          "created_at": "2026-03-07T11:00:00Z"
        }
      ],
      "created_at": "2026-03-07T10:00:00Z"
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

### GET /explore
탐색 피드 (인증 필요)
```
Query Parameters:
  cursor (optional): 페이지네이션 커서
  limit (optional, default=24): 한 번에 가져올 개수

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "thumbnail_url": "https://cdn.snapshare.app/posts/uuid-thumb.webp",
      "like_count": 100,
      "comment_count": 20
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

---

## 5. 팔로우 (Follow)

### POST /users/:username/follow
팔로우 (인증 필요)
```
Response 200:
{
  "success": true,
  "data": {
    "is_following": true,
    "follower_count": 1235,
    "following_count": 568
  }
}
```

### DELETE /users/:username/follow
언팔로우 (인증 필요)
```
Response 200:
{
  "success": true,
  "data": {
    "is_following": false,
    "follower_count": 1234,
    "following_count": 567
  }
}
```

### GET /users/:username/followers
팔로워 목록 조회
```
Query Parameters:
  cursor (optional): 페이지네이션 커서
  limit (optional, default=20): 한 번에 가져올 개수

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "username": "follower_user",
      "display_name": "Follower User",
      "profile_image_url": "...",
      "is_following": true
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

### GET /users/:username/following
팔로잉 목록 조회
```
(팔로워 목록과 동일한 응답 구조)
```

---

## 6. 좋아요 (Like)

### POST /posts/:id/like
좋아요 추가 (인증 필요)
```
Response 200:
{
  "success": true,
  "data": {
    "is_liked": true,
    "like_count": 43
  }
}
```

### DELETE /posts/:id/like
좋아요 취소 (인증 필요)
```
Response 200:
{
  "success": true,
  "data": {
    "is_liked": false,
    "like_count": 42
  }
}
```

### GET /posts/:id/likes
좋아요한 사용자 목록 조회
```
Query Parameters:
  cursor (optional)
  limit (optional, default=20)

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "username": "liker_user",
      "display_name": "Liker User",
      "profile_image_url": "...",
      "is_following": false
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

---

## 7. 댓글 (Comment)

### POST /posts/:id/comments
댓글 작성 (인증 필요)
```
Request Body:
{
  "content": "멋진 사진이네요!"
}

Response 201:
{
  "success": true,
  "data": {
    "id": "uuid",
    "content": "멋진 사진이네요!",
    "author": {
      "id": "uuid",
      "username": "commenter",
      "display_name": "Commenter",
      "profile_image_url": "..."
    },
    "created_at": "2026-03-07T12:00:00Z"
  }
}
```

### GET /posts/:id/comments
댓글 목록 조회
```
Query Parameters:
  cursor (optional)
  limit (optional, default=20)

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "content": "첫 번째 댓글",
      "author": {
        "id": "uuid",
        "username": "user1",
        "display_name": "User 1",
        "profile_image_url": "..."
      },
      "created_at": "2026-03-07T10:30:00Z"
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

### DELETE /comments/:id
댓글 삭제 (인증 필요, 본인 댓글 또는 게시물 작성자)
```
Response 204: (본문 없음)
```

---

## 8. 알림 (Notification)

### GET /notifications
알림 목록 조회 (인증 필요)
```
Query Parameters:
  cursor (optional)
  limit (optional, default=20)

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "type": "like",
      "actor": {
        "id": "uuid",
        "username": "liker",
        "display_name": "Liker",
        "profile_image_url": "..."
      },
      "post": {
        "id": "uuid",
        "thumbnail_url": "..."
      },
      "is_read": false,
      "created_at": "2026-03-07T12:00:00Z"
    },
    {
      "id": "uuid",
      "type": "comment",
      "actor": { ... },
      "post": { ... },
      "comment_preview": "멋진 사진이...",
      "is_read": false,
      "created_at": "2026-03-07T11:30:00Z"
    },
    {
      "id": "uuid",
      "type": "follow",
      "actor": { ... },
      "post": null,
      "is_read": true,
      "created_at": "2026-03-07T11:00:00Z"
    }
  ],
  "meta": {
    "cursor": "next_cursor",
    "has_more": true
  }
}
```

### POST /notifications/read
알림 읽음 처리 (인증 필요)
```
Request Body:
{
  "notification_ids": ["uuid1", "uuid2"]
}
// 또는 전체 읽음 처리:
{
  "read_all": true
}

Response 200:
{
  "success": true,
  "data": {
    "read_count": 5
  }
}
```

### GET /notifications/unread-count
읽지 않은 알림 수 조회 (인증 필요)
```
Response 200:
{
  "success": true,
  "data": {
    "unread_count": 3
  }
}
```

---

## 9. 검색 (Search)

### GET /search/users
사용자 검색 (인증 필요)
```
Query Parameters:
  q (required): 검색어 (최소 1자)
  limit (optional, default=20)

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "username": "john_doe",
      "display_name": "John Doe",
      "profile_image_url": "...",
      "is_following": false
    }
  ]
}
```

---

## Rate Limiting

| 엔드포인트 그룹 | 제한 | 윈도우 |
|-----------------|------|--------|
| POST /auth/* | 5회 | 1분 |
| POST /posts | 10회 | 1시간 |
| POST /*/like | 60회 | 1분 |
| POST /*/comments | 30회 | 1분 |
| POST /*/follow | 30회 | 1분 |
| GET /* (일반) | 100회 | 1분 |

Rate Limit 헤더:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1709827200
```
