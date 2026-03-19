# 시스템 아키텍처 설계

## 1. 전체 아키텍처 개요

```
                    ┌─────────────────────────────────────┐
                    │            사용자 (브라우저)            │
                    └──────────────┬──────────────────────┘
                                   │ HTTPS
                    ┌──────────────▼──────────────────────┐
                    │         Cloudflare CDN / WAF         │
                    │     (정적 에셋, 이미지 캐싱, 보안)       │
                    └──────┬────────────────┬──────────────┘
                           │                │
              ┌────────────▼───┐    ┌───────▼──────────┐
              │  Vercel Edge   │    │  이미지 CDN       │
              │  (Next.js SSR) │    │  (S3 + CloudFront)│
              └────────┬───────┘    └──────────────────┘
                       │ API Calls
              ┌────────▼───────────────────────────────┐
              │              API 서버                    │
              │         (Next.js API Routes)            │
              │                                        │
              │  ┌───────────┐  ┌───────────────────┐  │
              │  │   Auth    │  │   Business Logic  │  │
              │  │ Middleware│  │     Services       │  │
              │  └───────────┘  └───────────────────┘  │
              │                                        │
              │  ┌───────────┐  ┌───────────────────┐  │
              │  │   Rate    │  │   Image Upload    │  │
              │  │  Limiter  │  │    Service         │  │
              │  └───────────┘  └───────────────────┘  │
              └────┬──────┬──────────┬─────────────────┘
                   │      │          │
          ┌────────▼──┐ ┌─▼────┐  ┌──▼──────────┐
          │PostgreSQL │ │Redis │  │  AWS S3      │
          │   (DB)    │ │      │  │ (이미지 저장) │
          └───────────┘ └──────┘  └─────────────┘
```

## 2. 프론트엔드 아키텍처

### 2.1 디렉토리 구조 (Next.js App Router)

```
src/
├── app/                        # Next.js App Router
│   ├── (auth)/                 # 인증 관련 레이아웃 그룹
│   │   ├── login/
│   │   │   └── page.tsx
│   │   ├── signup/
│   │   │   └── page.tsx
│   │   └── layout.tsx          # 인증 페이지 공통 레이아웃
│   ├── (main)/                 # 메인 앱 레이아웃 그룹
│   │   ├── feed/
│   │   │   └── page.tsx        # 홈 피드
│   │   ├── explore/
│   │   │   └── page.tsx        # 탐색
│   │   ├── post/
│   │   │   ├── [id]/
│   │   │   │   └── page.tsx    # 게시물 상세
│   │   │   └── new/
│   │   │       └── page.tsx    # 새 게시물 작성
│   │   ├── profile/
│   │   │   ├── [username]/
│   │   │   │   ├── page.tsx    # 사용자 프로필
│   │   │   │   ├── followers/
│   │   │   │   │   └── page.tsx
│   │   │   │   └── following/
│   │   │   │       └── page.tsx
│   │   │   └── edit/
│   │   │       └── page.tsx    # 프로필 편집
│   │   ├── notifications/
│   │   │   └── page.tsx        # 알림
│   │   ├── search/
│   │   │   └── page.tsx        # 검색
│   │   └── layout.tsx          # 메인 레이아웃 (네비게이션 바)
│   ├── api/                    # API Routes
│   │   ├── auth/
│   │   ├── users/
│   │   ├── posts/
│   │   ├── feed/
│   │   ├── notifications/
│   │   └── search/
│   ├── layout.tsx              # 루트 레이아웃
│   └── globals.css
├── components/                 # 공용 컴포넌트
│   ├── ui/                     # shadcn/ui 기본 컴포넌트
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── dialog.tsx
│   │   ├── avatar.tsx
│   │   └── ...
│   ├── feed/                   # 피드 관련 컴포넌트
│   │   ├── FeedPost.tsx
│   │   ├── FeedPostSkeleton.tsx
│   │   ├── LikeButton.tsx
│   │   ├── CommentSection.tsx
│   │   └── PostActions.tsx
│   ├── post/                   # 게시물 관련 컴포넌트
│   │   ├── ImageUploader.tsx
│   │   ├── PostDetail.tsx
│   │   └── PostGrid.tsx
│   ├── profile/                # 프로필 관련 컴포넌트
│   │   ├── ProfileHeader.tsx
│   │   ├── FollowButton.tsx
│   │   └── UserListItem.tsx
│   ├── notification/           # 알림 관련 컴포넌트
│   │   ├── NotificationItem.tsx
│   │   └── NotificationBadge.tsx
│   ├── layout/                 # 레이아웃 컴포넌트
│   │   ├── Navbar.tsx
│   │   ├── BottomNav.tsx
│   │   └── Sidebar.tsx
│   └── common/                 # 공통 컴포넌트
│       ├── InfiniteScroll.tsx
│       ├── ImageWithFallback.tsx
│       ├── TimeAgo.tsx
│       └── EmptyState.tsx
├── hooks/                      # 커스텀 훅
│   ├── useAuth.ts
│   ├── useFeed.ts
│   ├── useFollow.ts
│   ├── useLike.ts
│   ├── useNotifications.ts
│   └── useInfiniteScroll.ts
├── lib/                        # 유틸리티
│   ├── api.ts                  # API 클라이언트
│   ├── auth.ts                 # 인증 유틸
│   ├── db.ts                   # Prisma 클라이언트
│   ├── s3.ts                   # S3 유틸
│   ├── validators.ts           # 입력값 검증
│   └── constants.ts            # 상수
├── types/                      # TypeScript 타입
│   ├── user.ts
│   ├── post.ts
│   ├── notification.ts
│   └── api.ts
└── prisma/                     # Prisma 스키마
    ├── schema.prisma
    └── migrations/
```

### 2.2 상태 관리 전략

```
┌─────────────────────────────────────────────┐
│              상태 관리 계층                     │
├─────────────────────────────────────────────┤
│                                             │
│  서버 상태 (React Query / TanStack Query)    │
│  ├── 피드 데이터 (무한 쿼리)                   │
│  ├── 게시물 상세                              │
│  ├── 사용자 프로필                             │
│  ├── 알림 목록                               │
│  └── 검색 결과                               │
│                                             │
│  클라이언트 상태 (Zustand)                     │
│  ├── 인증 상태 (현재 사용자, 토큰)              │
│  ├── UI 상태 (모달, 토스트)                    │
│  └── 임시 상태 (업로드 진행률)                  │
│                                             │
│  URL 상태 (Next.js Router)                   │
│  ├── 현재 페이지                              │
│  ├── 검색 쿼리                               │
│  └── 필터 파라미터                             │
│                                             │
└─────────────────────────────────────────────┘
```

## 3. 백엔드 아키텍처

### 3.1 레이어 구조

```
┌──────────────────────────────────────────┐
│              API Layer                    │
│   (Route Handlers, Request Validation)   │
├──────────────────────────────────────────┤
│           Middleware Layer                │
│   (Auth, Rate Limit, Error Handler)      │
├──────────────────────────────────────────┤
│            Service Layer                 │
│   (Business Logic, Domain Rules)         │
├──────────────────────────────────────────┤
│          Repository Layer                │
│   (Data Access, Prisma Queries)          │
├──────────────────────────────────────────┤
│         Infrastructure Layer             │
│   (DB, Redis, S3, External Services)     │
└──────────────────────────────────────────┘
```

### 3.2 주요 서비스

| 서비스 | 책임 |
|--------|------|
| AuthService | 회원가입, 로그인, 토큰 관리 |
| UserService | 프로필 CRUD, 사용자 검색 |
| PostService | 게시물 CRUD, 이미지 처리 |
| FeedService | 홈 피드, 탐색 피드 조회 |
| FollowService | 팔로우/언팔로우, 팔로워/팔로잉 조회 |
| LikeService | 좋아요 추가/취소, 좋아요 목록 |
| CommentService | 댓글 CRUD |
| NotificationService | 알림 생성, 조회, 읽음 처리 |
| ImageService | 이미지 업로드, 리사이징, 삭제 |

## 4. 이미지 처리 파이프라인

```
┌────────┐    ┌──────────────┐    ┌───────────────┐    ┌──────────┐
│ 클라이언트│───>│ 클라이언트 측   │───>│  API 서버      │───>│  AWS S3  │
│        │    │ 리사이징       │    │  (검증/메타)    │    │          │
└────────┘    │ max 1080px   │    │               │    └────┬─────┘
              │ WebP 변환     │    └───────────────┘         │
              └──────────────┘                               │
                                                    ┌────────▼─────┐
                                                    │  CloudFront  │
                                                    │  CDN 캐싱     │
                                                    └──────────────┘
```

### 이미지 처리 상세:
1. **클라이언트 측**: browser-image-compression으로 이미지 리사이징 (최대 1080px)
2. **업로드**: Presigned URL을 통한 직접 S3 업로드 (서버 부하 감소)
3. **저장**: 원본 + 썸네일(300x300) 두 가지 버전 저장
4. **제공**: CloudFront CDN을 통해 최적화된 이미지 제공

## 5. 알림 시스템 아키텍처

### MVP (폴링 방식)
```
┌──────────┐  30초 간격 폴링   ┌───────────┐    ┌───────┐
│ 클라이언트 │──────────────────>│ API 서버   │───>│ Redis │
│          │<──────────────────│ GET /count │<───│ 카운터 │
└──────────┘  unread_count     └───────────┘    └───────┘
```

### 향후 (WebSocket 방식)
```
┌──────────┐   WebSocket      ┌───────────┐    ┌───────┐
│ 클라이언트 │<═══════════════>│ WS 서버    │───>│ Redis │
│          │  실시간 알림 푸시   │           │<───│ Pub/Sub│
└──────────┘                  └───────────┘    └───────┘
```

## 6. 보안 아키텍처

```
요청 흐름:

[브라우저] ──HTTPS──> [Cloudflare WAF] ──> [Rate Limiter] ──> [Auth Middleware]
                          │                     │                    │
                     DDoS 방어            Redis 기반            JWT 검증
                     SQL Injection        요청 제한              사용자 식별
                     XSS 방어
```

### 보안 체크리스트:
- HTTPS 필수 (HSTS)
- JWT: HS256 → RS256 (비대칭키) 권장
- 비밀번호: bcrypt (cost factor 12)
- CSRF 보호: SameSite Cookie
- Content Security Policy (CSP) 헤더
- 이미지 업로드: 파일 타입 검증 (매직 바이트), EXIF 제거
- Rate Limiting: Redis sliding window
- SQL Injection: Prisma ORM (parameterized queries)
- XSS: React 기본 이스케이핑 + DOMPurify

## 7. 배포 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                    GitHub                            │
│                      │                               │
│              GitHub Actions CI/CD                    │
│              ┌───────┴────────┐                      │
│              │                │                      │
│        ┌─────▼─────┐  ┌──────▼──────┐              │
│        │  Vercel    │  │   Railway   │              │
│        │ (Next.js)  │  │ (PostgreSQL │              │
│        │ 프론트+API  │  │  + Redis)   │              │
│        └────────────┘  └─────────────┘              │
│                                                     │
│        ┌────────────┐  ┌─────────────┐              │
│        │ Cloudflare │  │   AWS S3    │              │
│        │    CDN     │  │ (이미지)     │              │
│        └────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────┘
```

### 환경 구성:
| 환경 | 용도 | 배포 트리거 |
|------|------|-------------|
| Development | 개발자 로컬 | - |
| Staging | 테스트 및 QA | develop 브랜치 push |
| Production | 운영 | main 브랜치 merge |

## 8. 모니터링 및 관찰성

| 영역 | 도구 | 용도 |
|------|------|------|
| 에러 추적 | Sentry | 프론트엔드/백엔드 에러 |
| 로깅 | Vercel Logs / Pino | 구조화된 로그 |
| APM | Vercel Analytics | 성능 모니터링 |
| 인프라 | Railway Metrics | DB/Redis 모니터링 |
| 업타임 | Better Uptime | 서비스 가용성 |
