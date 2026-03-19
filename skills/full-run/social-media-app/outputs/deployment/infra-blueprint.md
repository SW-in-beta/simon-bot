# Infrastructure Blueprint: InstaClone

## Architecture
```
Client (Browser)
    |
    v
[Next.js App Server (Node.js)]
    |
    +--> SQLite (file-based DB)
    +--> Local filesystem (image uploads)
```

## Deployment Strategy
- Docker single container (standalone Next.js)
- docker-compose for local/staging
- Volume mounts for data persistence (DB + uploads)

## CI/CD Pipeline
```
Push → Lint → Test → Build → Docker Build → Deploy
```

## Monitoring
- Health check: /api/auth/me (responds 401 = healthy)
- Docker healthcheck configured (30s interval)

## Rollback
1. docker-compose down
2. Restore previous image tag
3. docker-compose up -d
