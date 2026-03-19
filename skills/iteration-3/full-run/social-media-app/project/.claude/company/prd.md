# PRD: Picstory - Social Media Web App

## 1. Overview
인스타그램 스타일의 소셜 미디어 웹앱. 사진 공유, 팔로우, 좋아요/댓글, 알림 기능을 제공한다.

## 2. Goals & Non-Goals
**Goals**: 사진 기반 소셜 네트워킹 MVP 구현
**Non-Goals**: 실시간 채팅, AI 추천, 스토리 기능

## 3. User Stories & AC
→ spec.md 참조 (US-001~US-012, P1 9개 / P2 3개)

## 4. Story Map & Release Plan
→ story-map.md 참조

## 5. Technical Architecture
→ architecture.md 참조 (Next.js 15 + TypeScript + Prisma + SQLite)

## 6. Design System
→ design/ 참조 (wireframes, tokens, components)

## 7. Data Model
→ db-schema.md 참조 (6 tables: users, posts, likes, comments, follows, notifications)

## 8. Infrastructure
→ deployment/infra-blueprint.md 참조 (Docker + CI/CD)

## 9. Constraints & Principles
→ constitution.md 참조

## 10. Success Criteria
- 회원가입 → 로그인 → 게시물 작성 → 피드 조회 흐름 정상 동작
- 좋아요/댓글/팔로우 시 알림 생성
- 테스트 커버리지 80%+
- 빌드 + 린트 0 에러
