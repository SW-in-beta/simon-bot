# Architecture: Picstory

## Situation
Greenfield 소셜 미디어 웹앱. MVP 규모 (수백~수천 사용자). 사진 업로드, 소셜 기능, 알림이 핵심.

## Task

### 기술 스택
| 영역 | 선택 | 근거 |
|------|------|------|
| Framework | Next.js 15 (App Router) | SSR/SSG + API Routes 통합, React 생태계 |
| Language | TypeScript | 타입 안전성, 개발 생산성 |
| ORM | Prisma | 타입 안전 쿼리, 마이그레이션 관리 |
| DB | SQLite | MVP에 충분, 설정 간단, Prisma 호환 |
| Auth | NextAuth.js (Credentials) | Next.js 통합, JWT 세션 |
| Styling | Tailwind CSS | 유틸리티 퍼스트, 빠른 개발 |
| Image Upload | 로컬 파일시스템 (public/uploads) | MVP 단계, 향후 S3 마이그레이션 가능 |
| Testing | Jest + React Testing Library | Next.js 공식 지원, 컴포넌트 테스트 |
| Form | React Hook Form + Zod | 타입 안전 폼 검증 |

### 대안 비교
| 항목 | 선택 | 대안 1 | 대안 2 |
|------|------|--------|--------|
| DB | SQLite (간단, 무설정) | PostgreSQL (확장성↑, 설정 필요) | MongoDB (스키마 유연, 관계 복잡) |
| Auth | NextAuth.js (통합↑) | Passport.js (유연, 설정 많음) | 직접 구현 (완전 제어, 시간↑) |
| ORM | Prisma (타입 안전) | Drizzle (경량) | TypeORM (레거시) |

### 아키텍처 패턴
- **Monolith (Next.js Full-stack)**: API Routes + React Pages in single app
- **계층 구조**: Pages → API Routes → Services → Prisma (DB)
- **파일 구조**:
```
src/
├── app/                    # Next.js App Router (pages + layouts)
│   ├── (auth)/             # 인증 그룹 (login, register)
│   ├── (main)/             # 메인 앱 그룹 (feed, profile, notifications)
│   ├── api/                # API Routes
│   │   ├── auth/           # 인증 API
│   │   ├── posts/          # 게시물 CRUD
│   │   ├── users/          # 사용자 관리
│   │   ├── comments/       # 댓글
│   │   └── notifications/  # 알림
│   └── layout.tsx          # Root layout
├── components/             # Shared UI components
│   ├── ui/                 # 기본 UI (Button, Input, Card 등)
│   ├── post/               # 게시물 관련 컴포넌트
│   ├── profile/            # 프로필 관련 컴포넌트
│   └── layout/             # 레이아웃 컴포넌트
├── lib/                    # 유틸리티, 서비스
│   ├── prisma.ts           # Prisma client
│   ├── auth.ts             # Auth 설정
│   └── validations.ts      # Zod 스키마
├── types/                  # TypeScript 타입 정의
└── prisma/                 # Prisma 스키마 + 마이그레이션
```

## Intent
- 빠른 MVP 개발: Next.js full-stack으로 FE/BE 분리 없이 한 프로젝트
- 타입 안전성: TypeScript + Prisma + Zod로 end-to-end 타입 보장
- 확장 가능: SQLite → PostgreSQL 마이그레이션, 로컬 → S3 전환 용이

## Concerns
- 이미지 업로드 크기 제한 필요 (5MB)
- SQLite 동시성 제한 — MVP 규모에서는 문제 없음
- 실시간 알림은 polling 방식 (MVP), 향후 WebSocket 전환 가능

## Acceptance Criteria
- 각 팀이 독립적으로 구현 가능한 구조
- API Routes로 FE/BE 경계 명확
- Prisma 스키마가 Data Contract의 단일 소스
