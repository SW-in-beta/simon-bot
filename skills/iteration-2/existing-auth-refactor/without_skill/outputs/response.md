# Claude Code Response (Without Skill)

---

인증 시스템을 세션 기반에서 JWT + OAuth2로 전면 리팩토링하는 건 상당히 큰 작업이네요. 5개 서비스에 걸쳐 있다면 먼저 현재 상태를 정확히 파악하는 게 중요합니다.

우선 모노레포 구조와 현재 인증 관련 코드를 살펴봐도 될까요? 몇 가지 확인하고 싶은 것들이 있습니다:

1. **현재 인증 구조 파악**
   - 세션 관리가 어떻게 되어 있는지 (Redis? DB? 인메모리?)
   - 인증 미들웨어/데코레이터가 어떤 형태인지
   - 관련 5개 서비스가 어떤 것들인지
   - 서비스 간 인증 전파가 어떻게 되는지 (내부 API 호출 시)

2. **API 호환성 범위**
   - 외부 클라이언트(모바일 앱, 웹 프론트엔드)가 현재 세션 쿠키를 어떻게 사용하는지
   - 기존 API 응답 형태를 유지해야 하는 범위

이런 정보가 있으면 구체적인 마이그레이션 전략을 세울 수 있습니다.

일반적으로 이런 규모의 인증 리팩토링은 아래와 같은 접근을 추천합니다:

---

## 권장 접근 방식

### Phase 1: 듀얼 인증 레이어 구축
기존 세션과 JWT를 동시에 지원하는 미들웨어를 만듭니다. 요청에 JWT가 있으면 JWT로, 세션 쿠키가 있으면 세션으로 인증합니다. 이렇게 하면 클라이언트가 점진적으로 마이그레이션할 수 있습니다.

```
// 의사 코드
func AuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // 1. JWT 토큰 확인 (Authorization: Bearer ...)
        if token := extractBearerToken(r); token != "" {
            claims, err := validateJWT(token)
            if err == nil {
                ctx := context.WithValue(r.Context(), userKey, claims)
                next.ServeHTTP(w, r.WithContext(ctx))
                return
            }
        }
        // 2. 폴백: 기존 세션 확인
        if session := getSession(r); session != nil {
            ctx := context.WithValue(r.Context(), userKey, session.User)
            next.ServeHTTP(w, r.WithContext(ctx))
            return
        }
        // 3. 인증 실패
        http.Error(w, "Unauthorized", 401)
    })
}
```

### Phase 2: JWT 토큰 서비스 구현
- Access Token (짧은 만료, 예: 15분) + Refresh Token (긴 만료, 예: 7일) 구조
- 토큰 발급/갱신/폐기 엔드포인트
- 서비스 간 통신용 내부 JWT (서비스 계정)

### Phase 3: OAuth2 Provider 추가
- Authorization Code Grant (웹), PKCE (모바일/SPA)
- Google, Kakao 등 소셜 로그인 연동
- OAuth2 클라이언트 등록/관리 시스템

### Phase 4: 기존 세션 마이그레이션 및 제거
- 기존 세션 기반 로그인 시 자동으로 JWT 발급
- 클라이언트 업데이트 후 세션 레이어 제거
- 모니터링으로 세션 사용률 추적

---

## 주의사항

- **토큰 저장소**: Refresh Token 폐기를 위한 블랙리스트/화이트리스트 필요 (Redis 추천)
- **서비스 간 인증**: 내부 서비스 호출은 JWT propagation 또는 별도의 서비스 토큰 사용
- **하위 호환성**: 기존 API 엔드포인트의 응답 형태는 변경하지 않고, 인증 방식만 교체
- **보안**: JWT secret 관리 (vault 등), 토큰 만료 정책, CORS 설정 등

---

모노레포의 현재 구조를 보여주시면 더 구체적인 구현 방안을 제시할 수 있습니다. 어떤 서비스들이 관련되어 있는지, 현재 인증 코드가 어디에 있는지 알려주시겠어요?
