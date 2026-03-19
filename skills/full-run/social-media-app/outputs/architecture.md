# Architecture: InstaClone

## Situation
Greenfield 소셜 미디어 웹앱. 사진 공유, 팔로우, 좋아요/댓글, 알림 기능이 필요.
소규모 프로젝트로 단일 서버에서 운영. 외부 서비스 의존 없이 자체 완결적.

## Task

### 기술 스택
| 영역 | 기술 | 근거 |
|------|------|------|
| Framework | Next.js 14+ (App Router) | SSR/SSG + API Routes로 풀스택 단일 프로젝트 |
| UI | React 18 + Tailwind CSS | 컴포넌트 기반 + 유틸리티 CSS |
| Database | SQLite (better-sqlite3) | 설치 불필요, 파일 기반, 소규모에 적합 |
| Auth | JWT (jsonwebtoken) + bcrypt | 무상태 인증, 비밀번호 해싱 |
| Image Storage | 로컬 파일시스템 (public/uploads/) | 단순함, 외부 의존 없음 |
| Validation | zod | 타입 안전한 스키마 검증 |
| Testing | Jest + React Testing Library | 표준적인 테스트 프레임워크 |

### 아키텍처 패턴
- **모놀리식 풀스택**: Next.js App Router로 프론트엔드 + API를 하나의 프로젝트에서 관리
- **계층형 구조**:
  ```
  app/ (Pages - UI 렌더링)
    ├── (auth)/ - 인증 관련 페이지
    ├── feed/ - 메인 피드
    ├── profile/ - 프로필
    ├── notifications/ - 알림
    └── api/ - API Routes
         ├── auth/ - 인증 API
         ├── posts/ - 게시물 API
         ├── users/ - 사용자 API
         └── notifications/ - 알림 API
  lib/
    ├── db.ts - DB 연결 + 초기화
    ├── auth.ts - JWT 유틸리티
    └── validations.ts - Zod 스키마
  components/ - 재사용 컴포넌트
  ```

## Intent
- 단일 프로젝트로 개발/배포 단순화
- Next.js API Routes로 별도 백엔드 서버 불필요
- SQLite로 DB 서버 설치/관리 부담 제거
- Tailwind CSS로 빠른 UI 개발

## Concerns
- SQLite 동시성 제한 (단일 writer) → 소규모이므로 문제 없음
- 이미지 로컬 저장 → 서버 마이그레이션 시 파일 이전 필요
- JWT refresh token 미적용 → MVP 범위에서는 충분

## Acceptance Criteria
- 각 팀이 독립적으로 API/UI를 구현할 수 있는 구조
- Contract 기반으로 프론트엔드와 백엔드가 연동 가능
- 빌드 시 타입 에러 0건
