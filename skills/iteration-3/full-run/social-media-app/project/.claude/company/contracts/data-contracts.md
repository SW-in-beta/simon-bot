# Data Contract: Picstory

## users table → User API response
| DB Column | API Field | Transform |
|-----------|-----------|-----------|
| id | id | 그대로 |
| email | email | 프로필 API에서 비노출 |
| username | username | 그대로 |
| password_hash | - | 절대 노출 금지 |
| display_name | displayName | camelCase 변환 |
| bio | bio | 그대로 |
| avatar_url | avatarUrl | camelCase 변환 |
| created_at | createdAt | ISO 8601 |

## posts table → Post API response
| DB Column | API Field | Transform |
|-----------|-----------|-----------|
| id | id | 그대로 |
| user_id | author | User 객체로 join |
| image_url | imageUrl | camelCase 변환 |
| caption | caption | 그대로 |
| created_at | createdAt | ISO 8601 |
| (aggregated) | _count.likes | COUNT(likes) |
| (aggregated) | _count.comments | COUNT(comments) |
| (computed) | isLiked | 현재 사용자의 좋아요 여부 |

## Shared Types
- ID: cuid string
- DateTime: ISO 8601
- Pagination: cursor-based `{ cursor?: string, limit: number }`
