# Sprint Plan: InstaClone

## Sprint 1 (Walking Skeleton) - 인증 + 게시물 + 피드

```
Sprint 1 ─┬─ [F1: 초기 설정 + DB] (DevOps+DBA)
           ├─ [F2: 인증 API] (Backend) ← depends F1
           ├─ [F3: 인증 UI] (Frontend) ← depends F2
           ├─ [F4: 게시물 API] (Backend) ← depends F2
           └─ [F5: 피드+업로드 UI] (Frontend) ← depends F3,F4
```

실행 순서: F1 → F2,F4 (병렬) → F3,F5 (순차)
Walking Skeleton 목표: 가입 → 로그인 → 사진 업로드 → 피드 조회

## Sprint 2 (Core Social) - 팔로우 + 좋아요 + 댓글 + 프로필

```
Sprint 2 ─┬─ [F6: 소셜 API] (Backend)
           └─ [F7: 프로필+소셜 UI] (Frontend) ← depends F6
```

## Sprint 3 (Engagement + Hardening) - 알림 + 보완 + 배포

```
Sprint 3 ─┬─ [F8: 알림 API+UI] (Backend+Frontend)
           ├─ [F9: 프로필수정+삭제] (Backend+Frontend)
           └─ [F10: Docker+CI/CD] (DevOps)
```
