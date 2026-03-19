# API Contract: InstaClone

## Error Response Format (공통)
```json
{ "error": { "code": "ERROR_CODE", "message": "Human readable message" } }
```

## Auth

### POST /api/auth/signup
- Request: `{ "email": "string", "username": "string", "password": "string" }`
- Response 201: `{ "user": { "id": number, "email": "string", "username": "string" }, "token": "jwt_string" }`
- Response 400: `{ "error": { "code": "VALIDATION_ERROR", "message": "..." } }`
- Response 409: `{ "error": { "code": "DUPLICATE_EMAIL", "message": "..." } }`

### POST /api/auth/login
- Request: `{ "email": "string", "password": "string" }`
- Response 200: `{ "user": { "id": number, "email": "string", "username": "string" }, "token": "jwt_string" }`
- Response 401: `{ "error": { "code": "INVALID_CREDENTIALS", "message": "..." } }`

### GET /api/auth/me
- Headers: `Authorization: Bearer {token}`
- Response 200: `{ "user": { "id": number, "email": "string", "username": "string", "bio": "string" } }`
- Response 401: `{ "error": { "code": "UNAUTHORIZED", "message": "..." } }`

## Posts

### POST /api/posts
- Headers: `Authorization: Bearer {token}`
- Request: `multipart/form-data { image: File, caption?: string }`
- Response 201: `{ "post": { "id": number, "imageUrl": "string", "caption": "string", "createdAt": "string" } }`
- Response 400: `{ "error": { "code": "IMAGE_REQUIRED", "message": "..." } }`

### GET /api/posts/feed
- Headers: `Authorization: Bearer {token}`
- Query: `?page=1&limit=20`
- Response 200: `{ "posts": [{ "id", "imageUrl", "caption", "createdAt", "user": { "id", "username" }, "likesCount": number, "commentsCount": number, "isLiked": boolean }], "hasMore": boolean }`

### GET /api/posts/:id
- Response 200: `{ "post": { "id", "imageUrl", "caption", "createdAt", "user": { "id", "username" }, "likesCount", "commentsCount", "isLiked", "comments": [{ "id", "content", "createdAt", "user": { "id", "username" } }] } }`
- Response 404: `{ "error": { "code": "POST_NOT_FOUND" } }`

### DELETE /api/posts/:id
- Headers: `Authorization: Bearer {token}`
- Response 200: `{ "success": true }`
- Response 403: `{ "error": { "code": "FORBIDDEN" } }`

## Likes

### POST /api/posts/:id/like
- Headers: `Authorization: Bearer {token}`
- Response 200: `{ "liked": boolean, "likesCount": number }`

## Comments

### POST /api/posts/:id/comments
- Headers: `Authorization: Bearer {token}`
- Request: `{ "content": "string" }`
- Response 201: `{ "comment": { "id", "content", "createdAt", "user": { "id", "username" } } }`
- Response 400: `{ "error": { "code": "CONTENT_REQUIRED" } }`

## Users

### GET /api/users/:username
- Response 200: `{ "user": { "id", "username", "bio", "postsCount", "followersCount", "followingCount", "isFollowing": boolean, "posts": [{ "id", "imageUrl", "caption" }] } }`
- Response 404: `{ "error": { "code": "USER_NOT_FOUND" } }`

### PUT /api/users/profile
- Headers: `Authorization: Bearer {token}`
- Request: `{ "username"?: string, "bio"?: string }`
- Response 200: `{ "user": { "id", "username", "bio" } }`

## Follows

### POST /api/users/:id/follow
- Headers: `Authorization: Bearer {token}`
- Response 200: `{ "following": boolean }`
- Response 400: `{ "error": { "code": "CANNOT_FOLLOW_SELF" } }`

## Notifications

### GET /api/notifications
- Headers: `Authorization: Bearer {token}`
- Response 200: `{ "notifications": [{ "id", "type": "like|comment|follow", "actor": { "id", "username" }, "post"?: { "id", "imageUrl" }, "read": boolean, "createdAt": "string" }] }`

### PUT /api/notifications/read
- Headers: `Authorization: Bearer {token}`
- Response 200: `{ "success": true }`
