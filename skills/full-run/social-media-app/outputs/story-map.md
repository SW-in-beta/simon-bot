# Story Map: InstaClone

## 사용자 여정 기반 기능 계층

```
Activity:   [가입/인증]              [콘텐츠 공유]           [소셜 활동]             [관리/알림]
              |                        |                      |                      |
Tasks:      이메일 가입              사진 업로드              팔로우/언팔로우         알림 확인
            로그인/로그아웃           피드 조회               좋아요                 프로필 관리
                                     게시물 상세             댓글
              |                        |                      |                      |
Stories:    US-001 회원가입          US-003 사진 업로드      US-005 팔로우          US-009 알림
(P1)        US-002 로그인/로그아웃   US-004 피드 조회        US-006 좋아요          US-008 프로필 페이지
                                                            US-007 댓글
              |                        |                      |                      |
Stories:                             US-011 게시물 삭제                             US-010 프로필 수정
(P2)
```

---

## Walking Skeleton (Sprint 1 목표)

핵심 흐름의 최소 구현:
1. 회원가입 (US-001) → 로그인 (US-002)
2. 사진 업로드 (US-003)
3. 피드 조회 (US-004)

이 세 가지가 끝에서 끝까지 동작하면 Walking Skeleton 완성.

---

## Release Plan

### Release 1 (Walking Skeleton): Sprint 1
- US-001: 회원가입
- US-002: 로그인/로그아웃
- US-003: 사진 업로드
- US-004: 피드 조회 (일단 모든 게시물 최신순)

### Release 2 (Core Social): Sprint 2
- US-005: 팔로우/언팔로우
- US-006: 좋아요
- US-007: 댓글
- US-008: 프로필 페이지
- US-004 개선: 팔로우 기반 피드 필터링

### Release 3 (Engagement): Sprint 3
- US-009: 알림
- US-010: 프로필 수정
- US-011: 게시물 삭제

### Release 4 (Hardening): Sprint 4
- 보안 강화
- 성능 최적화
- CI/CD + Docker
