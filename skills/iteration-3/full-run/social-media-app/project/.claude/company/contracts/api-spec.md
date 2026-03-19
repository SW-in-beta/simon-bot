# API Contract: Picstory

## Error Response Format (공통)
```json
{ "error": { "code": "ERROR_CODE", "message": "Human readable message" } }
```

## Auth

### POST /api/auth/register
- Request: `{ "email": "string", "username": "string", "password": "string" }`
- Response 201: `{ "user": { "id": "cuid", "email": "string", "username": "string" } }`
- Response 400: `{ "error": { "code": "VALIDATION_ERROR", "message": "string" } }`
- Response 409: `{ "error": { "code": "DUPLICATE_EMAIL", "message": "string" } }`

### POST /api/auth/login (NextAuth Credentials)
- Handled by NextAuth.js signIn()

### GET /api/auth/session
- Handled by NextAuth.js getServerSession()

## Posts

### GET /api/posts/feed?cursor={cursor}&limit=20
- Auth: Required
- Response 200: `{ "posts": [PostWithAuthor], "nextCursor": "string | null" }`

### POST /api/posts
- Auth: Required
- Request: multipart/form-data `{ "image": File, "caption": "string" }`
- Response 201: `{ "post": Post }`
- Response 400: `{ "error": { "code": "VALIDATION_ERROR" } }`

### GET /api/posts/:id
- Response 200: `{ "post": PostWithDetails }`
- Response 404: `{ "error": { "code": "NOT_FOUND" } }`

### DELETE /api/posts/:id
- Auth: Required (owner only)
- Response 200: `{ "success": true }`
- Response 403: `{ "error": { "code": "FORBIDDEN" } }`

## Likes

### POST /api/posts/:id/like
- Auth: Required
- Response 200: `{ "liked": true, "likeCount": number }`

### DELETE /api/posts/:id/like
- Auth: Required
- Response 200: `{ "liked": false, "likeCount": number }`

## Comments

### GET /api/posts/:id/comments?cursor={cursor}&limit=20
- Response 200: `{ "comments": [CommentWithAuthor], "nextCursor": "string | null" }`

### POST /api/posts/:id/comments
- Auth: Required
- Request: `{ "content": "string" }`
- Response 201: `{ "comment": CommentWithAuthor }`

## Users

### GET /api/users/:username
- Response 200: `{ "user": UserProfile }`
- Response 404: `{ "error": { "code": "NOT_FOUND" } }`

### GET /api/users/:username/posts?cursor={cursor}&limit=20
- Response 200: `{ "posts": [Post], "nextCursor": "string | null" }`

### PUT /api/users/me
- Auth: Required
- Request: multipart/form-data `{ "displayName"?, "bio"?, "avatar"?: File }`
- Response 200: `{ "user": UserProfile }`

### GET /api/users/search?q={query}
- Response 200: `{ "users": [UserSearchResult] }`

## Follow

### POST /api/users/:username/follow
- Auth: Required
- Response 200: `{ "following": true }`

### DELETE /api/users/:username/follow
- Auth: Required
- Response 200: `{ "following": false }`

## Notifications

### GET /api/notifications?cursor={cursor}&limit=20
- Auth: Required
- Response 200: `{ "notifications": [NotificationWithActor], "nextCursor": "string | null" }`

### PUT /api/notifications/read
- Auth: Required
- Response 200: `{ "success": true }`

### GET /api/notifications/unread-count
- Auth: Required
- Response 200: `{ "count": number }`

## Shared Types

```typescript
interface Post {
  id: string;
  imageUrl: string;
  caption: string | null;
  createdAt: string; // ISO 8601
  author: { id: string; username: string; avatarUrl: string | null };
  _count: { likes: number; comments: number };
  isLiked: boolean;
}

interface UserProfile {
  id: string;
  username: string;
  displayName: string | null;
  bio: string | null;
  avatarUrl: string | null;
  _count: { posts: number; followers: number; following: number };
  isFollowing: boolean;
}

interface Comment {
  id: string;
  content: string;
  createdAt: string;
  author: { id: string; username: string; avatarUrl: string | null };
}

interface Notification {
  id: string;
  type: "LIKE" | "COMMENT" | "FOLLOW";
  read: boolean;
  createdAt: string;
  actor: { id: string; username: string; avatarUrl: string | null };
  post?: { id: string; imageUrl: string };
}
```
