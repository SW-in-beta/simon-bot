#!/usr/bin/env python3
"""simon-monitor 테스트용 목 이벤트 생성기.

두 가지 모드:
1. --all: 모든 이벤트를 한번에 생성 (대시보드 정적 테스트)
2. --live: 1-3초 간격으로 이벤트를 순차 생성 (실시간 스트리밍 테스트)

Usage:
  python3 generate-mock-events.py --session /path/to/session --all
  python3 generate-mock-events.py --session /path/to/session --live
"""

import argparse
import json
import os
import time
import uuid
from datetime import datetime, timedelta, timezone


def ts(offset_seconds=0):
    """현재 시각 + offset의 ISO 8601 타임스탬프."""
    dt = datetime.now(timezone.utc) + timedelta(seconds=offset_seconds)
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def uid():
    return str(uuid.uuid4())


def make_events():
    """simon STANDARD 워크플로를 시뮬레이션하는 이벤트 시퀀스."""
    t = 0
    events = []

    def add(step, etype, title, data=None, dt=2):
        nonlocal t
        events.append({
            "id": uid(), "timestamp": ts(t), "skill": "simon",
            "step": step, "type": etype, "title": title,
            "data": data or {}
        })
        t += dt

    # Workflow start — 전체 스텝 정의 포함
    add(None, "workflow_start", "워크플로 시작", {
        "skill": "simon", "branch": "feat/add-auth", "task": "JWT 기반 인증 기능 추가",
        "scope": "STANDARD", "session_id": "feat/add-auth", "parent_session_id": None,
        "workflow_steps": [
            {"phase": "A", "id": "0", "title": "범위 분석", "desc": "변경 범위를 분석하고 실행 경로(SMALL/STANDARD/LARGE)를 결정합니다"},
            {"phase": "A", "id": "1-A", "title": "프로젝트 분석", "desc": "코드베이스 구조를 탐색하고 코드 설계팀이 컨벤션을 분석합니다"},
            {"phase": "A", "id": "1-B", "title": "플랜 작성", "desc": "STICC 프레임워크 기반으로 구현 계획을 수립합니다"},
            {"phase": "A", "id": "1-B-ext", "title": "플랜 렌더링", "desc": "플랜을 HTML로 렌더링하여 브라우저에서 리뷰합니다"},
            {"phase": "A", "id": "2", "title": "플랜 내부 리뷰", "desc": "설계자·비평자·아키텍트가 직접 토론하여 플랜을 검증합니다"},
            {"phase": "A", "id": "3", "title": "메타 검증", "desc": "교차 검증으로 플랜의 일관성과 완전성을 확인합니다"},
            {"phase": "A", "id": "4", "title": "과잉설계 점검", "desc": "YAGNI/KISS 원칙에 따라 불필요한 복잡성을 제거합니다"},
            {"phase": "A", "id": "4-B", "title": "도메인 전문가 리뷰", "desc": "데이터·통합·보안·운영·설계 5개 도메인팀이 교차 검토합니다"},
            {"phase": "A", "id": "calibration", "title": "Phase A 검증 게이트", "desc": "계획 단계의 모든 산출물이 존재하는지 검증합니다"},
            {"phase": "B", "id": "5", "title": "구현 (TDD)", "desc": "RED→GREEN→REFACTOR 사이클로 테스트 주도 개발합니다"},
            {"phase": "B", "id": "6", "title": "목적 정합성", "desc": "구현 결과가 요구사항과 일치하는지 검증합니다"},
            {"phase": "B", "id": "7", "title": "버그/보안/성능 리뷰", "desc": "도메인팀이 코드의 보안·성능·버그를 검토합니다"},
            {"phase": "B", "id": "8", "title": "회귀 검증", "desc": "Step 7 수정이 기존 동작을 깨뜨리지 않았는지 확인합니다"},
            {"phase": "B", "id": "9", "title": "파일/함수 분리", "desc": "너무 큰 파일이나 함수를 적절히 분리합니다"},
            {"phase": "B", "id": "10", "title": "통합/재사용 리뷰", "desc": "기존 코드와의 통합 가능성과 재사용성을 검토합니다"},
            {"phase": "B", "id": "11", "title": "부작용 점검", "desc": "변경이 다른 모듈에 미치는 영향을 확인합니다"},
            {"phase": "B", "id": "12", "title": "전체 변경 리뷰", "desc": "코드 리뷰어가 모든 변경사항을 종합 검토합니다"},
            {"phase": "B", "id": "13", "title": "데드코드 정리", "desc": "사용되지 않는 코드를 제거합니다"},
            {"phase": "B", "id": "14", "title": "코드 품질 평가", "desc": "코드 품질 기준에 따라 전체 코드를 평가합니다"},
            {"phase": "B", "id": "15", "title": "흐름 검증", "desc": "실행 흐름이 설계 의도와 일치하는지 확인합니다"},
            {"phase": "B", "id": "16", "title": "MEDIUM 이슈 해결", "desc": "중간 심각도 이슈들을 해결합니다"},
            {"phase": "B", "id": "17", "title": "프로덕션 준비 검증", "desc": "Done-When 체크를 통과하여 프로덕션 배포 가능 여부를 확인합니다"},
            {"phase": "review", "id": "18-A", "title": "작업 보고서 작성", "desc": "Before/After 다이어그램과 트레이드오프를 정리합니다"},
            {"phase": "review", "id": "18-B", "title": "리뷰 순서 설계", "desc": "아키텍트가 논리적 변경 단위와 리뷰 순서를 결정합니다"},
            {"phase": "review", "id": "19", "title": "코드 리뷰 핸드오프", "desc": "simon-code-review에 위임하여 Draft PR과 인라인 리뷰를 진행합니다"}
        ]
    })

    # Phase A: Planning
    # Step 0: Scope Challenge
    add("A/0", "step_start", "Scope Challenge 시작", {"description": "변경 범위 분석, 실행 경로 결정"})
    add("A/0", "subagent_spawn", "architect 서브에이전트 시작", {
        "agent_name": "architect", "agent_type": "general-purpose",
        "task": "git 히스토리 분석, 최소 변경 결정, scope 분류", "background": False
    }, dt=5)
    add("A/0", "subagent_result", "architect 결과", {
        "agent_name": "architect",
        "summary": "기존 user 패키지에 auth 모듈 추가. 변경 예상: 12파일, 2패키지 간 의존성.",
        "key_findings": ["user 패키지에 이미 basic auth 존재", "JWT 라이브러리 의존성 추가 필요", "기존 테스트 15개 수정 필요"],
        "duration_ms": 8000
    }, dt=3)
    add("A/0", "decision", "실행 경로 결정: STANDARD", {
        "decision": "STANDARD path 선택",
        "rationale": "변경 파일 12개, 2개 패키지 간 의존성 존재, 기존 테스트 수정 필요",
        "alternatives": [
            {"option": "SMALL", "rejected_reason": "변경 범위가 SMALL 기준(~5 파일) 초과"},
            {"option": "LARGE", "rejected_reason": "새 서비스가 아닌 기존 서비스 확장"}
        ]
    })
    add("A/0", "step_complete", "Scope Challenge 완료", {
        "summary": "STANDARD path 결정. 12파일 변경, 2패키지 의존성.",
        "artifacts": [], "duration_ms": 18000
    })

    # 스킵 이벤트: STANDARD 경로에서 생략되는 Phase A 스텝들
    add("A/1-B-ext", "step_skip", "플랜 렌더링 스킵", {"reason": "사용자가 CLI에서 직접 리뷰 중이므로 브라우저 렌더링 불필요. 플랜 내용은 터미널 출력으로 확인됨."}, dt=0)
    add("A/3", "step_skip", "메타 검증 스킵", {"reason": "Step 2 내부 리뷰에서 planner·critic·architect 3자 토론이 충분히 진행됨. 교차 검증 항목이 이미 Step 2에서 커버되어 별도 실행 불필요."}, dt=0)
    add("A/4", "step_skip", "과잉설계 점검 스킵", {"reason": "Step 0에서 STANDARD 경로로 결정 시 변경 범위가 명확함 (12파일, 기존 서비스 확장). 새로운 추상화 레이어 도입이 없어 과잉설계 위험 낮음."}, dt=0)

    # Step 1-A: Project Analysis + Code Design
    add("A/1-A", "step_start", "프로젝트 분석 + 코드 설계 분석", {
        "description": "프로젝트 구조 스캔, graphify 그래프 참조, Code Design Team 분석"
    })
    add("A/1-A", "subagent_spawn", "구조 탐색 에이전트 시작", {
        "agent_name": "project-analyzer", "agent_type": "Explore",
        "task": "프로젝트 구조 분석: 디렉토리 구조, DI 설정, 인증 관련 코드 탐색", "background": False
    }, dt=8)
    add("A/1-A", "subagent_result", "구조 탐색 완료", {
        "agent_name": "project-analyzer",
        "summary": "Go DDD 프로젝트. 3개 바운디드 컨텍스트(user, campaign, billing).",
        "explored_paths": [
            {"path": "cmd/server/main.go", "reason": "엔트리포인트 및 DI 구성 확인", "detail": "wire.Build()로 의존성 주입. 현재 BasicAuthMiddleware 등록됨"},
            {"path": "domain/", "reason": "도메인 레이어 구조 파악", "detail": "user/, campaign/, billing/ 3개 aggregate. 각각 entity.go + repository.go 인터페이스"},
            {"path": "infra/repository/", "reason": "저장소 구현체 확인", "detail": "PostgreSQL 기반. sqlx 사용. user_repo.go, campaign_repo.go 등 5개 파일"},
            {"path": "middleware/auth.go", "reason": "기존 인증 로직 분석", "detail": "BasicAuthMiddleware 구조체. Header에서 Base64 디코딩 후 DB 조회. 67줄"},
            {"path": "go.mod", "reason": "의존성 확인", "detail": "Go 1.24.3. 주요 의존성: sqlx, chi, zap, wire. JWT 라이브러리 미등록"},
            {"path": "internal/config/", "reason": "설정 구조 확인", "detail": "환경변수 기반 설정. config.go에 DB, Redis(미사용), Port 등"}
        ],
        "file_stats": {"files_read": 23, "lines_scanned": 4812, "packages_found": 12},
        "key_findings": [
            "cmd/server/main.go — wire.Build()로 DI 구성, BasicAuthMiddleware 등록됨",
            "domain/ — user, campaign, billing 3개 바운디드 컨텍스트",
            "infra/repository/ — PostgreSQL + sqlx, 5개 구현체",
            "middleware/auth.go — BasicAuth 67줄, 토큰 기반 인증 없음",
            "go.mod — JWT 라이브러리 미등록 (추가 필요)"
        ],
        "duration_ms": 12000
    }, dt=3)

    add("A/1-A", "expert_panel", "코드 설계팀 분석", {
        "panel_name": "코드 설계팀",
        "opinions": [
            {"role": "코드 컨벤션", "role_desc": "프로젝트의 기존 코딩 규칙과 네이밍 패턴 준수를 검토합니다", "opinion": "기존 프로젝트의 DDD 레이어 구조를 유지해야 합니다. domain/auth/ 하위에 새 aggregate 추가.", "severity": "INFO",
             "references": ["domain/user/entity.go — 기존 엔티티 네이밍 패턴 참조", "domain/user/repository.go — 인터페이스 정의 패턴"]},
            {"role": "언어 관용구", "role_desc": "Go 언어 고유의 관용적 표현과 최신 문법 활용을 검토합니다", "opinion": "Go 1.24의 range-over-func 패턴 적용 가능하나, 기존 코드와 일관성 유지가 더 중요합니다.", "severity": "MEDIUM",
             "references": ["go.mod — Go 1.24.3 확인", "domain/campaign/service.go — 기존 for-range 패턴 사용 중"]},
            {"role": "설계 패턴", "role_desc": "아키텍처 패턴과 디자인 패턴의 적절한 적용을 검토합니다", "opinion": "Repository 패턴이 이미 사용 중. TokenRepository 인터페이스를 domain 레이어에 정의하세요.", "severity": "INFO",
             "references": ["infra/repository/user_repo.go — Repository 구현 패턴", "domain/user/repository.go — 인터페이스 위치"]},
            {"role": "테스트 설계", "role_desc": "테스트 용이성, 모킹 전략, 커버리지 목표를 검토합니다", "opinion": "인터페이스 기반 DI 유지. Mock 생성이 용이하도록 인터페이스를 consumer 패키지에 정의하세요. 기존 testutil/ 패턴 활용.", "severity": "INFO",
             "references": ["testutil/mock_user_repo.go — 기존 Mock 패턴", "domain/user/service_test.go — 테스트 구조 참조"]}
        ],
        "consensus": "DDD 패턴 유지, TokenRepository 인터페이스 추가, 기존 testutil 패턴 활용",
        "action_items": ["domain/auth/ 디렉토리 생성", "TokenRepository 인터페이스 정의", "기존 테스트 패턴 따르기"]
    }, dt=5)

    add("A/1-A", "artifact", "requirements.md 생성", {
        "file": "requirements.md", "action": "created",
        "summary": "3개 핵심 요구사항 (JWT 발급/검증/갱신), 2개 비기능 요구사항 (성능, 보안)"
    })
    add("A/1-A", "artifact", "code-design-analysis.md 생성", {
        "file": "code-design-analysis.md", "action": "created",
        "summary": "DDD 패턴 분석, 컨벤션 가이드, 테스트 전략"
    })
    add("A/1-A", "step_complete", "프로젝트 분석 완료", {
        "summary": "DDD 아키텍처 확인, Code Design Team 합의 완료",
        "artifacts": ["requirements.md", "code-design-analysis.md"], "duration_ms": 45000
    })

    # Step 1-B: Plan Creation
    add("A/1-B", "step_start", "플랜 작성", {"description": "STICC 프레임워크 기반 계획 수립"})
    add("A/1-B", "subagent_spawn", "planner 시작", {
        "agent_name": "planner", "agent_type": "general-purpose",
        "task": "STICC 프레임워크 기반 구조화된 플랜 작성", "background": False
    }, dt=15)
    add("A/1-B", "subagent_result", "planner 결과", {
        "agent_name": "planner",
        "summary": "5단계 구현 계획 수립. Done-When 체크 8개 정의.",
        "key_findings": ["JWT 발급 → 검증 → 갱신 순서로 구현", "기존 basic auth와 공존 필요 (마이그레이션 기간)", "테스트 커버리지 80% 이상 목표"],
        "duration_ms": 25000
    })
    add("A/1-B", "artifact", "plan-summary.md 생성", {
        "file": "plan-summary.md", "action": "created",
        "summary": "5단계 구현 계획, Done-When 체크 8개, NOT in scope 3개"
    })
    add("A/1-B", "step_complete", "플랜 작성 완료", {
        "summary": "STICC 기반 플랜 완성. 사용자 리뷰 대기.",
        "artifacts": ["plan-summary.md"], "duration_ms": 30000
    })

    # Steps 2-4: Plan Review
    add("A/2", "step_start", "플랜 리뷰: 내부 토론", {"description": "planner + critic + architect 직접 토론"})
    add("A/2", "expert_panel", "플랜 내부 리뷰", {
        "panel_name": "플랜 리뷰팀",
        "opinions": [
            {"role": "설계자", "role_desc": "구현 계획의 구조와 단계별 실행 순서를 수립합니다", "opinion": "JWT 갱신 로직은 별도 서비스로 분리하는 것이 좋겠습니다.", "severity": "MEDIUM"},
            {"role": "비평자", "role_desc": "계획의 허점, 누락된 요구사항, 리스크를 지적합니다", "opinion": "basic auth와의 공존 기간이 명시되지 않았습니다. 마이그레이션 전략이 필요합니다.", "severity": "HIGH"},
            {"role": "아키텍트", "role_desc": "시스템 아키텍처 관점에서 기술 선택과 구조를 검토합니다", "opinion": "token 저장소로 Redis를 사용하면 성능 이점이 있지만, 현재 인프라에 Redis가 없습니다. 우선 DB 기반으로 시작합시다.", "severity": "MEDIUM"}
        ],
        "consensus": "DB 기반 token 저장, 마이그레이션 전략 추가, 갱신 로직은 같은 서비스 내 별도 패키지",
        "action_items": ["마이그레이션 전략 섹션 추가", "token 저장소 인터페이스 설계 (추후 Redis 전환 가능하도록)"]
    }, dt=10)
    add("A/2", "step_complete", "플랜 내부 리뷰 완료", {
        "summary": "2회 토론 후 합의. 마이그레이션 전략 추가됨.",
        "artifacts": ["plan-summary.md"], "duration_ms": 20000
    })

    # Step 4-B: Expert Plan Review
    add("A/4-B", "step_start", "전문가 플랜 리뷰", {"description": "5개 도메인팀 교차 검토"})
    add("A/4-B", "expert_panel", "도메인 전문가팀 리뷰", {
        "panel_name": "도메인 전문가팀",
        "opinions": [
            {"role": "데이터", "role_desc": "데이터 무결성, PII 처리, 저장 정책을 검토합니다", "opinion": "JWT payload에 PII를 포함하지 않도록 주의하세요. user_id만 포함 권장.", "severity": "MEDIUM"},
            {"role": "통합", "role_desc": "외부 시스템 연동 포인트와 API 호환성을 검토합니다", "opinion": "API Gateway와의 통합 포인트를 확인해야 합니다. 현재 Gateway에서 basic auth 헤더를 파싱하고 있습니다.", "severity": "HIGH"},
            {"role": "보안", "role_desc": "인증/인가, 암호화, 키 관리 등 보안 취약점을 검토합니다", "opinion": "JWT secret rotation 전략이 없습니다. CRITICAL: 키 유출 시 대응 방안 필요.", "severity": "CRITICAL"},
            {"role": "운영", "role_desc": "배포, 모니터링, 설정 관리 등 운영 편의성을 검토합니다", "opinion": "token 만료 시간 설정을 환경변수로 관리하세요. 운영 중 조정이 필요할 수 있습니다.", "severity": "LOW"},
            {"role": "코드 설계", "role_desc": "코드 구조, 패턴 적용, 확장성을 검토합니다", "opinion": "middleware/auth.go를 리팩토링하여 AuthStrategy 인터페이스를 도입하면 basic/JWT를 유연하게 전환할 수 있습니다.", "severity": "MEDIUM"}
        ],
        "consensus": "보안 CRITICAL 이슈 우선 해결 (secret rotation), 통합 HIGH 이슈 확인 필요",
        "action_items": ["JWT secret rotation 메커니즘 설계 추가", "API Gateway 통합 포인트 분석", "PII 미포함 정책 문서화"]
    }, dt=12)
    add("A/4-B", "artifact", "expert-plan-concerns.md 생성", {
        "file": "expert-plan-concerns.md", "action": "created",
        "summary": "1 CRITICAL (secret rotation), 1 HIGH (API Gateway), 3 MEDIUM, 1 LOW"
    })
    add("A/4-B", "step_complete", "전문가 리뷰 완료", {
        "summary": "CRITICAL 1건 (secret rotation) → 플랜 수정. HIGH 1건 → 경고 추가.",
        "artifacts": ["expert-plan-concerns.md"], "duration_ms": 25000
    })

    # Phase A Calibration Gate
    add("A/calibration", "gate_pass", "Phase A Calibration 통과", {
        "gate_name": "Phase A Calibration Checklist",
        "checks": [
            {"name": "requirements.md 존재", "passed": True},
            {"name": "plan-summary.md 존재", "passed": True},
            {"name": "Done-When 체크 정의됨", "passed": True},
            {"name": "expert-plan-concerns.md 존재", "passed": True},
            {"name": "scope 분류 완료", "passed": True},
            {"name": "NOT in scope 정의됨", "passed": True},
            {"name": "파일 변경 목록 작성됨", "passed": True}
        ],
        "passed_count": 7, "total_count": 7
    })

    # Phase B: Implementation
    add("B/5", "step_start", "구현 (TDD)", {"description": "RED → GREEN → REFACTOR 사이클"})
    add("B/5", "subagent_spawn", "executor 서브에이전트 시작", {
        "agent_name": "executor", "agent_type": "general-purpose",
        "task": "TDD 기반 JWT 인증 구현. code-design-analysis.md 컨벤션 준수.",
        "background": True
    }, dt=30)
    add("B/5", "subagent_result", "executor 결과", {
        "agent_name": "executor",
        "summary": "JWT 발급/검증/갱신 구현 완료. 테스트 12개 추가, 모두 통과.",
        "key_findings": [
            "domain/auth/token.go — JWT 토큰 엔티티",
            "domain/auth/service.go — 인증 서비스 (발급/검증/갱신)",
            "infra/repository/token_repo.go — PostgreSQL 기반 토큰 저장소",
            "middleware/jwt_auth.go — JWT 인증 미들웨어",
            "12 테스트 추가 (커버리지 87%)"
        ],
        "duration_ms": 120000
    })
    add("B/5", "step_complete", "구현 완료", {
        "summary": "4개 파일 생성, 2개 파일 수정. 테스트 12개, 커버리지 87%.",
        "artifacts": ["domain/auth/token.go", "domain/auth/service.go", "infra/repository/token_repo.go", "middleware/jwt_auth.go"],
        "duration_ms": 130000
    })

    # Phase B 스킵: Step 6 (목적 정합성)
    add("B/6", "step_skip", "목적 정합성 스킵", {"reason": "Step 5 executor가 TDD 사이클 내에서 요구사항 대비 테스트를 작성하여, 구현 자체가 요구사항과 정합성을 보장함. 별도 검증 불필요."}, dt=0)

    # Step 7: Bug/Security/Performance Review
    add("B/7", "step_start", "버그/보안/성능 리뷰", {"description": "도메인팀 코드 리뷰"})
    add("B/7", "expert_panel", "코드 리뷰 패널", {
        "panel_name": "코드 리뷰 전문가팀",
        "opinions": [
            {"role": "보안 리뷰", "role_desc": "코드의 보안 취약점, 인증 결함, 민감 정보 노출을 검토합니다", "opinion": "JWT secret이 하드코딩됨! 환경변수로 이동 필요. secret rotation은 구현됐으나 graceful rotation (이전 키로도 검증)이 빠져있음.", "severity": "CRITICAL"},
            {"role": "성능 리뷰", "role_desc": "불필요한 연산, DB 조회 최적화, 응답 시간 개선을 검토합니다", "opinion": "토큰 검증 시 매번 DB 조회. 블랙리스트만 DB에서 확인하고, 유효한 토큰은 시그니처 검증만으로 충분.", "severity": "HIGH"},
            {"role": "버그 리뷰", "role_desc": "경쟁 조건, 엣지 케이스, 로직 오류를 검토합니다", "opinion": "token 갱신 시 race condition 가능성. 동시 갱신 요청에 대한 처리 필요.", "severity": "MEDIUM"}
        ],
        "consensus": "CRITICAL 1건 즉시 수정, HIGH 1건 수정 후 진행",
        "action_items": ["환경변수 기반 secret 관리로 전환", "graceful rotation 추가", "블랙리스트 기반 검증으로 변경"]
    }, dt=8)
    add("B/7", "step_complete", "코드 리뷰 완료. 2건 수정 필요.", {
        "summary": "CRITICAL 1건 (secret 하드코딩), HIGH 1건 (불필요한 DB 조회) 발견",
        "artifacts": [], "duration_ms": 15000
    })

    # Phase B 스킵: Steps 8-16 (STANDARD 경로에서 Step 7 수정 후 직접 Step 17으로)
    add("B/8", "step_skip", "회귀 검증 스킵", {"reason": "Step 7에서 발견된 CRITICAL/HIGH 이슈 수정 시 기존 테스트 전체를 실행하여 회귀를 확인함. 12개 기존 테스트 + 12개 신규 테스트 모두 통과 확인됨."}, dt=0)
    add("B/9", "step_skip", "파일/함수 분리 스킵", {"reason": "새로 생성된 4개 파일 모두 단일 책임 원칙 준수. 가장 큰 파일(service.go)이 89줄로 분리 기준(200줄) 미달."}, dt=0)
    add("B/10", "step_skip", "통합/재사용 리뷰 스킵", {"reason": "기존 middleware/auth.go의 AuthStrategy 인터페이스로 통합 완료. 중복 코드 없음. Step 7 코드 리뷰에서 확인됨."}, dt=0)
    add("B/11", "step_skip", "부작용 점검 스킵", {"reason": "JWT 인증은 기존 BasicAuth와 독립적으로 동작. middleware 레벨에서 분기되어 다른 모듈에 영향 없음. import 분석 결과 새 패키지를 참조하는 기존 코드 없음."}, dt=0)
    add("B/12", "step_skip", "전체 변경 리뷰 스킵", {"reason": "Step 7에서 Security/Performance/Bug 3인 리뷰 완료. STANDARD 경로에서는 Step 7 리뷰가 Step 12를 대체."}, dt=0)
    add("B/13", "step_skip", "데드코드 정리 스킵", {"reason": "신규 코드만 추가된 상황. 기존 BasicAuth 코드는 마이그레이션 기간 동안 유지 필요하므로 제거 대상 아님."}, dt=0)
    add("B/14", "step_skip", "코드 품질 평가 스킵", {"reason": "Step 7 리뷰에서 코드 품질 관련 MEDIUM 이하 이슈만 발견됨. 커버리지 87%로 목표(80%) 초과 달성."}, dt=0)
    add("B/15", "step_skip", "흐름 검증 스킵", {"reason": "TDD 사이클에서 JWT 발급→검증→갱신 전체 흐름을 테스트로 검증 완료. integration test 2개가 end-to-end 흐름 커버."}, dt=0)
    add("B/16", "step_skip", "MEDIUM 이슈 해결 스킵", {"reason": "Step 7에서 발견된 MEDIUM 이슈(race condition) 1건은 현재 단일 인스턴스 운영 환경에서 발생 가능성 극히 낮음. Phase B 완료 후 별도 이슈로 추적하기로 결정."}, dt=0)

    # Review 스킵: 18-B
    add("review/18-B", "step_skip", "리뷰 순서 설계 스킵", {"reason": "변경된 논리적 단위가 하나(인증 모듈)뿐이므로 리뷰 순서 설계가 불필요. 단일 변경 단위로 PR 리뷰 가능."}, dt=0)

    # Step 17: Production Readiness
    add("B/17", "step_start", "프로덕션 준비 검증", {"description": "architect + security-reviewer 최종 검증"})
    add("B/17", "gate_pass", "Done-When Checks 통과", {
        "gate_name": "Done-When Checks",
        "checks": [
            {"name": "JWT 발급 기능 동작", "passed": True},
            {"name": "JWT 검증 기능 동작", "passed": True},
            {"name": "JWT 갱신 기능 동작", "passed": True},
            {"name": "Secret rotation 지원", "passed": True},
            {"name": "기존 basic auth 호환", "passed": True},
            {"name": "테스트 커버리지 80%+", "passed": True},
            {"name": "보안 리뷰 통과", "passed": True},
            {"name": "API Gateway 통합 확인", "passed": True}
        ],
        "passed_count": 8, "total_count": 8
    })
    add("B/17", "step_complete", "프로덕션 준비 완료", {
        "summary": "Done-When 8/8 통과. 프로덕션 준비 완료.",
        "artifacts": [], "duration_ms": 10000
    })

    # Review: Step 18
    add("review/18-A", "step_start", "작업 보고서 작성", {"description": "writer 서브에이전트가 Before/After 다이어그램, 트레이드오프 정리"})
    add("review/18-A", "subagent_spawn", "writer 시작", {
        "agent_name": "writer", "agent_type": "general-purpose",
        "task": "변경 사항 보고서 작성 — Before/After, 트레이드오프, 리스크", "background": False
    }, dt=10)
    add("review/18-A", "subagent_result", "writer 결과", {
        "agent_name": "writer",
        "summary": "보고서 작성 완료. Before/After 다이어그램 포함.",
        "key_findings": ["인증 흐름 변경 다이어그램", "성능 영향 분석 (토큰 검증 latency -40%)", "마이그레이션 가이드"],
        "duration_ms": 15000
    })
    add("review/18-A", "artifact", "feat-add-auth-report.md 생성", {
        "file": "feat-add-auth-report.md", "action": "created",
        "summary": "변경 보고서: 아키텍처 다이어그램, 성능 분석, 마이그레이션 가이드 포함"
    })
    add("review/18-A", "step_complete", "보고서 작성 완료", {
        "summary": "Before/After 다이어그램, 트레이드오프, 마이그레이션 가이드 포함",
        "artifacts": ["feat-add-auth-report.md"], "duration_ms": 20000
    })

    # Step 19: Handoff to simon-code-review
    add("review/19", "step_start", "코드 리뷰 핸드오프", {"description": "simon-code-review에 위임"})
    add("review/19", "decision", "simon-code-review CONNECTED 모드 호출", {
        "decision": "simon-code-review를 CONNECTED 모드로 호출",
        "rationale": "review-sequence.md가 생성되어 있으므로 CONNECTED 모드 자동 감지",
        "alternatives": [{"option": "STANDALONE", "rejected_reason": "review-sequence.md 존재 시 항상 CONNECTED"}]
    })
    add("review/19", "step_complete", "코드 리뷰 위임 완료", {
        "summary": "simon-code-review가 Draft PR 생성, 인라인 리뷰, CI Watch 수행 예정",
        "artifacts": ["review-sequence.md"], "duration_ms": 5000
    })

    # Workflow complete
    add(None, "workflow_complete", "워크플로 완료", {
        "status": "success",
        "summary": "JWT 인증 기능 구현 완료. Draft PR 생성, 코드 리뷰 진행 중.",
        "duration_ms": sum(e.get("data", {}).get("duration_ms", 0) for e in events if e.get("data", {}).get("duration_ms")),
        "artifacts": ["requirements.md", "plan-summary.md", "expert-plan-concerns.md",
                      "code-design-analysis.md", "feat-add-auth-report.md", "review-sequence.md"]
    })

    return events


def main():
    parser = argparse.ArgumentParser(description="Mock event generator for simon-monitor testing")
    parser.add_argument("--session", required=True, help="Session directory for events.jsonl")
    parser.add_argument("--all", action="store_true", help="Write all events at once")
    parser.add_argument("--live", action="store_true", help="Write events with delays (simulates real-time)")
    parser.add_argument("--delay", type=float, default=1.5, help="Delay between events in live mode (default: 1.5s)")
    args = parser.parse_args()

    if not args.all and not args.live:
        print("Error: specify --all or --live", file=sys.stderr)
        sys.exit(1)

    os.makedirs(args.session, exist_ok=True)
    events_file = os.path.join(args.session, "events.jsonl")

    # 기존 파일 초기화
    with open(events_file, "w") as f:
        pass

    events = make_events()
    print(f"이벤트 {len(events)}개 생성 → {events_file}")

    if args.all:
        with open(events_file, "w") as f:
            for event in events:
                f.write(json.dumps(event, ensure_ascii=False) + "\n")
        print("완료")
    else:
        for i, event in enumerate(events):
            with open(events_file, "a") as f:
                f.write(json.dumps(event, ensure_ascii=False) + "\n")
            print(f"  [{i+1}/{len(events)}] {event['type']}: {event['title']}")
            if i < len(events) - 1:
                time.sleep(args.delay)
        print("완료")


if __name__ == "__main__":
    import sys
    main()
