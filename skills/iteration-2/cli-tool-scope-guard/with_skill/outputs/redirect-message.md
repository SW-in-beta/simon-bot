# 리다이렉트 메시지

## 대상 프로젝트
CSV 파일을 읽어서 JSON으로 변환하는 CLI 도구 (인코딩 자동 감지, 컬럼 필터링, 대용량 파일 스트리밍 지원)

## 리다이렉트 권장

이 프로젝트에는 **simon-company가 과합니다.**

### 왜 simon-company가 과한가?

1. **불필요한 팀이 너무 많음**: 9개 팀 중 5개(Design, Frontend, DBA, DevOps, ML)가 완전히 불필요합니다. 다중 팀 조율, 팀간 Contract 정의, Cross-Review 등의 오버헤드가 실제 가치를 창출하지 못합니다.

2. **중량급 프로세스 과잉**: 8단계 파이프라인, Triple Review Protocol(3라운드 검토), planner-critic-architect 3인 검증, Expert Panel Review 등은 대규모 서비스를 위한 것입니다. CLI 도구 하나에 적용하면 산출물 작성/검토 시간이 구현 시간의 수배가 됩니다.

3. **Sprint 사이클 불필요**: Feature 3-4개인 프로젝트에 Sprint 분할, Sprint Review/Retro, Re-planning 사이클은 오버엔지니어링입니다.

### 권장 대안

| 스킬 | 적합도 | 이유 |
|------|--------|------|
| **simon-bot-pm** | 가장 적합 | PM이 요구사항 정리 + Backend 구현 관리. 소규모 프로젝트에 최적화 |
| **simon-bot** | 적합 | 단일 개발자가 직접 TDD로 구현. 가장 빠른 결과물 |

### 사용자 응답

사용자가 simon-company 진행을 원하므로, 축소된 팀(PM, CTO, Backend, QA)으로 Phase 0을 완료합니다.
