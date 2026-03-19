# Infrastructure Blueprint: Picstory

## Architecture
```
Client (Browser)
    ↓
Next.js App (Node.js)
    ↓
SQLite (embedded)
    ↓
Local Filesystem (uploads/)
```

## Deployment Strategy
- Small 규모: Docker 컨테이너 단일 서버 배포
- docker-compose로 로컬 개발 환경 통합

## CI/CD Pipeline
```
Push → Lint → Type Check → Unit Test → Build → Docker Build → Deploy
```

## Monitoring
- Health check endpoint: GET /api/health
- 기본 로깅: console (JSON format)
- 에러 트래킹: 로그 기반

## Environment
- Development: 로컬 (npm run dev)
- Production: Docker container
- 환경 변수: DATABASE_URL, NEXTAUTH_SECRET, NEXTAUTH_URL
