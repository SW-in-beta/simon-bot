# Story Map: Picstory

## Activity → Task → Story Hierarchy

```
Activity:   [가입/인증]           [콘텐츠]              [소셜]               [알림/관리]
              |                     |                    |                     |
Tasks:      이메일 가입           게시물 작성           팔로우/언팔로우       알림 조회
            로그인/로그아웃       피드 조회              좋아요                프로필 관리
                                  게시물 상세            댓글
                                                        프로필 조회
                                                        사용자 검색
              |                     |                    |                     |
Stories:    US-001 이메일 가입    US-003 사진 게시      US-007 팔로우/언팔    US-009 알림
(P1)        US-002 로그인/로그아웃 US-004 피드 조회     US-005 좋아요         US-008 프로필 페이지
                                                        US-006 댓글
              |                     |                    |                     |
Stories:                          US-011 게시물 삭제    US-012 사용자 검색    US-010 프로필 편집
(P2)
              |                     |                    |
Stories:                          US-015 해시태그       US-013 북마크
(P3)                                                    US-014 DM
```

## Walking Skeleton (Release 1 - Sprint 1 목표)
핵심 흐름의 최소 구현:
1. 가입 (US-001) → 로그인 (US-002) → 게시물 작성 (US-003) → 피드 조회 (US-004)

## Release Plan
- **Release 1** (Walking Skeleton): US-001~004 — 가입, 로그인, 게시, 피드
- **Release 2** (Core Social): US-005~009 — 좋아요, 댓글, 팔로우, 프로필, 알림
- **Release 3** (Enhancement): US-010~012 — 프로필 편집, 게시물 삭제, 검색
- **Release 4** (Future): US-013~015 — 북마크, DM, 해시태그
