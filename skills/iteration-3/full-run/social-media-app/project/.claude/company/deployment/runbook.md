# Runbook: Picstory

## 장애 시나리오별 대응

### 1. 앱 서버 응답 없음
- 증상: GET /api/health 실패
- 진단: docker logs picstory-app
- 대응: docker-compose restart app
- 에스컬레이션: 15분 내 미해결 시 → 수동 디버깅

### 2. DB 연결 실패
- 증상: 500 에러, Prisma connection error
- 진단: SQLite 파일 권한 확인, 디스크 공간 확인
- 대응: 컨테이너 재시작, 볼륨 마운트 확인

### 3. 이미지 업로드 실패
- 증상: 게시물 작성 시 500 에러
- 진단: uploads 디렉토리 권한, 디스크 공간
- 대응: mkdir -p public/uploads && chmod 755 public/uploads

## 배포 체크리스트

### Pre-Deploy
- [ ] npm test 통과
- [ ] npm run build 성공
- [ ] .env 환경 변수 설정 확인
- [ ] NEXTAUTH_SECRET 프로덕션 값으로 변경

### Deploy
- [ ] docker-compose build
- [ ] docker-compose up -d
- [ ] curl http://localhost:3000/api/health → 200 OK

### Post-Deploy
- [ ] 회원가입 → 로그인 수동 확인
- [ ] 게시물 작성 확인
- [ ] 에러 로그 확인

## 롤백 절차
1. docker-compose down
2. 이전 이미지로 롤백: docker-compose up -d --no-build
3. 헬스체크 확인
