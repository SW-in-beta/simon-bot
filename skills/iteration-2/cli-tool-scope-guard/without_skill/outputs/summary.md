# Phase 0 산출물 요약

## 프로젝트: csv2json CLI 도구

CSV 파일을 JSON으로 변환하는 CLI 도구의 Phase 0 (초기 기획/평가) 산출물이다.
인코딩 자동 감지, 컬럼 필터링, 대용량 파일 스트리밍을 핵심 기능으로 한다.

## 생성된 파일 목록

| 번호 | 파일명 | 설명 |
|------|--------|------|
| 1 | `01_project_overview.md` | 프로젝트 개요 - 목적, 배경, 핵심 기능, 대상 사용자, 사용 예시 |
| 2 | `02_scope_definition.md` | 범위 정의서 - In/Out Scope, 가정 사항, 마일스톤 초안 |
| 3 | `03_technical_assessment.md` | 기술 평가서 - 기술 스택 선정(Go), 라이브러리, 아키텍처 설계, 패키지 구조, 기술적 도전 과제, 테스트 전략 |
| 4 | `04_team_composition.md` | 팀 구성 - 규모 평가, 역할 정의, 필요 역량, 의사소통 계획 |
| 5 | `05_risk_analysis.md` | 리스크 분석서 - 기술/일정/프로젝트 리스크 7건, 리스크 매트릭스 |
| 6 | `06_acceptance_criteria.md` | 인수 기준 - 기능별 Given/When/Then 형식의 인수 테스트 시나리오 |
| 7 | `07_work_breakdown.md` | 작업 분해 구조 (WBS) - 5개 마일스톤, 세부 태스크, 일정 추정 |

## 핵심 결정 사항

- **언어**: Go (단일 바이너리, 크로스 플랫폼, 표준 라이브러리 활용)
- **CLI 프레임워크**: cobra
- **인코딩 감지**: chardet + golang.org/x/text
- **예상 공수**: 8일 (1인 개발 기준)
- **팀 구성**: 1인 개발 권장 (Go 시니어)
- **주요 리스크**: 인코딩 감지 오탐(R1), 범위 확장(R7)

## 파일 위치
모든 파일은 아래 경로에 저장되어 있다:
```
/Users/simon.lee/.claude/skills/simon-company-workspace/iteration-2/cli-tool-scope-guard/without_skill/outputs/
```
