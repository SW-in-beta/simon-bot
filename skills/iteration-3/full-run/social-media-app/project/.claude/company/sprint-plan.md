# Sprint Plan: Picstory

## Sprint 1 (Walking Skeleton) — 프로젝트 초기 설정 + 인증 + 게시물 기본
```
F1: 프로젝트 초기 설정 (DevOps) — S — 프로젝트 scaffolding, Prisma, Tailwind 설정
F2: DB 스키마 + 마이그레이션 (DBA) — M — 전체 Prisma 스키마 + 시드 데이터
F3: 인증 시스템 (Backend) — M — NextAuth 설정, 회원가입/로그인 API
F4: 인증 UI (Frontend) — M — 로그인/회원가입 페이지, 인증 상태 관리
F5: 게시물 API (Backend) — M — 게시물 CRUD API, 이미지 업로드
F6: 메인 피드 + 게시물 작성 UI (Frontend) — L — 피드 페이지, 게시물 카드, 작성 폼
```

## Sprint 2 (Core Social) — 소셜 기능 + 프로필 + 알림
```
F7: 좋아요/댓글 API (Backend) — M — 좋아요 토글, 댓글 CRUD
F8: 팔로우 API (Backend) — S — 팔로우/언팔로우, 팔로워 목록
F9: 알림 API (Backend) — M — 알림 생성/조회/읽음 처리
F10: 프로필 + 소셜 UI (Frontend) — L — 프로필 페이지, 좋아요/댓글 UI, 팔로우 버튼
F11: 알림 + 검색 UI (Frontend) — M — 알림 페이지, 사용자 검색
```

## Sprint 3 (Polish) — 마무리 + QA + 배포
```
F12: 프로필 편집 + 게시물 삭제 (Backend+Frontend) — M
F13: DevOps (Docker, CI/CD) — M — Dockerfile, docker-compose, GitHub Actions
F14: QA 통합 테스트 — M — E2E 시나리오, 보안 검증
```

## Dependencies
- F2 → F3, F5, F7, F8, F9 (DB 스키마 필요)
- F3 → F4 (인증 API 필요)
- F5 → F6 (게시물 API 필요)
- F7, F8 → F10 (소셜 API 필요)
- F9 → F11 (알림 API 필요)
