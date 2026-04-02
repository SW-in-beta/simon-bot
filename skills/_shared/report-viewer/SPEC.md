# Report Viewer Infrastructure Spec

구현팀을 위한 요구사항 정의서. simon-bot-pm 또는 simon-company로 구현할 때 이 스펙을 참조한다.

## 아키텍처

```
마크다운 (정본, AI 컨텍스트용)
  ↓ render-report.sh
HTML (사용자 열람 + 인라인 코멘트)
  ↓ 코멘트 동기화
마크다운 (코멘트 반영 후 업데이트)
```

마크다운이 정본(source of truth)이다. HTML은 렌더링 레이어이며, 코멘트를 수집하는 인터페이스 역할을 한다.

## 디렉토리 구조

```
~/.claude/skills/_shared/report-viewer/
├── SPEC.md                  # 이 파일 (요구사항)
├── integration-guide.md     # 스킬 통합 가이드 (각 스킬이 참조)
├── render-report.sh         # CLI 진입점
├── server.py                # 로컬 HTTP 서버 (코멘트 저장 API)
├── template.html            # HTML 레이아웃 셸
├── assets/
│   ├── style.css            # 타이포그래피, 레이아웃, 반응형
│   ├── report.js            # 코멘트 UI, TOC 생성, 커스텀 블록 렌더링
│   └── vendor/              # mermaid.js, highlight.js, katex 등 (CDN fallback)
└── blocks/                  # 커스텀 마크다운 블록 렌더러
    └── README.md            # 커스텀 블록 문법 정의
```

## 핵심 컴포넌트

### 1. render-report.sh

CLI 진입점. 마크다운 파일을 받아 HTML로 변환하고 브라우저에서 연다.

```bash
render-report.sh <markdown-file> [options]
  --open          # 브라우저 자동 오픈 (기본: true)
  --port <N>      # HTTP 서버 포트 (기본: 자동 할당)
  --no-server     # 서버 없이 정적 HTML만 생성 (코멘트 비활성화)
```

동작:
1. 마크다운 파일 경로 검증
2. 마크다운 → HTML 변환 (template.html에 삽입)
3. 로컬 HTTP 서버 시작 (server.py, 백그라운드)
4. `localhost:{port}` 브라우저 오픈
5. 표준 출력: `{ "url": "http://localhost:3847", "comments_file": "/path/to/report-comments.json", "pid": 12345 }`

종료: 사용자가 터미널에서 Ctrl+C 또는 Claude가 서버 PID로 종료.

### 2. server.py — 로컬 HTTP 서버

Python 표준 라이브러리만 사용 (외부 의존성 없음).

엔드포인트:
- `GET /` — HTML 보고서 서빙
- `GET /assets/*` — CSS, JS, 벤더 파일 서빙
- `POST /comments` — 코멘트 저장
- `GET /comments` — 저장된 코멘트 조회
- `GET /meta` — 보고서 메타데이터 (마크다운 경로, 제목 등)

코멘트 저장 경로: `{markdown_dir}/{markdown_basename}-comments.json`
예: `report.md` → `report-comments.json` (같은 디렉토리)

### 3. template.html — HTML 레이아웃

**고정 요소:**
- 헤더: 보고서 제목, 생성일, 스킬 이름
- 사이드바: 자동 생성 TOC (h2, h3 기반), 코멘트 수 뱃지
- 본문 영역: 마크다운 렌더링 결과
- 하단 툴바:
  - "마크다운 경로 복사" 버튼 → 절대 경로를 클립보드에 복사
  - "코멘트 내보내기" 버튼 (서버 없을 때 fallback)
  - "리뷰 완료" 버튼 → 서버에 완료 신호 전송

**반응형:** 모바일에서도 읽을 수 있지만, 주 타겟은 데스크톱 브라우저.

### 4. 인라인 코멘트 시스템

**사용자 인터랙션:**
1. 텍스트 선택 또는 섹션 hover → 코멘트 아이콘 표시
2. 아이콘 클릭 → 코멘트 입력 패널 (오른쪽 사이드 또는 인라인)
3. Intent 선택: fix(수정 요청) / question(질문) / expand(확장 요청) / approve(승인)
4. "저장" → POST /comments → JSON 파일에 자동 저장
5. 저장된 코멘트는 본문 옆에 하이라이트로 표시

**코멘트 데이터 구조:**
```json
{
  "report": "/absolute/path/to/report.md",
  "comments": [
    {
      "id": "c-001",
      "section_id": "핵심-멘탈-모델",
      "section_title": "핵심 멘탈 모델",
      "selected_text": "Quantile은 분위수를 의미한다",
      "comment": "이 설명이 너무 추상적입니다. 실제 우리 코드에서 어떤 의미인지 구체적으로.",
      "intent": "fix",
      "timestamp": "2026-03-31T14:30:00+09:00",
      "status": "pending"
    }
  ]
}
```

### 5. 커스텀 마크다운 블록

표준 마크다운 외에, 풍부한 시각화를 위한 커스텀 블록 문법. AI가 보고서 작성 시 내용에 맞는 블록을 자유롭게 선택한다.

**지원 블록:**

| 문법 | 렌더링 | 용도 |
|------|--------|------|
| ` ```mermaid ` | mermaid.js 다이어그램 | 플로우, 시퀀스, 상태 다이어그램 |
| ` ```math ` | KaTeX 수식 | 수학적 설명 |
| `:::comparison` | 좌우 비교 카드 | 방안 A vs B 비교 |
| `:::timeline` | 수직 타임라인 | 시간순 이벤트 |
| `:::callout[type]` | 강조 박스 (info/warning/error/success) | 주의사항, 핵심 포인트 |
| `:::tabs` | 탭 UI | 여러 관점 병렬 제시 |
| `:::collapse[title]` | 접이식 섹션 | 상세 내용 숨기기 |
| `:::metric[label]` | 큰 숫자 카드 | KPI, 수치 강조 |
| `:::steps` | 번호 스텝 UI | 단계별 절차 |
| `:::quote[source]` | 인용 카드 | Confluence/Slack 인용 |

AI는 이 블록들을 자유롭게 조합한다. 프레젠테이션처럼 내용에 가장 적합한 시각화를 선택하는 것이 원칙이다.

### 6. "마크다운 경로 복사" 버튼

HTML 하단 툴바에 위치. 클릭 시:
1. 보고서의 마크다운 절대 경로를 클립보드에 복사
2. "복사됨!" 토스트 메시지 표시
3. 복사 형식: 경로만 (예: `/Users/simon.lee/.claude/reports/analysis-adpacing.md`)

용도: 사용자가 다음 Claude 프롬프트에 마크다운 경로를 붙여넣어 AI에게 컨텍스트로 전달.

## 코멘트 → 마크다운 동기화

Claude가 코멘트를 처리한 후, 수정된 내용을 마크다운에 반영해야 한다.

흐름:
1. 사용자: "리뷰 완료" → Claude에 알림
2. Claude: `{report}-comments.json` Read
3. Claude: 각 코멘트의 section_id + intent에 따라 마크다운 수정 (Edit)
4. Claude: 수정된 마크다운으로 HTML 재생성 (`render-report.sh --open`)
5. Claude: 처리된 코멘트의 status를 "resolved"로 업데이트

## 비기능 요구사항

- **외부 의존성 없음**: Python 표준 라이브러리 + CDN JS 라이브러리만 사용
- **오프라인 동작**: CDN 실패 시 vendor/ 디렉토리의 로컬 파일 fallback
- **macOS 최적화**: `open` 명령어로 브라우저 실행
- **포트 충돌 방지**: 자동 포트 할당 (기본 3847, 충돌 시 +1)
- **프로세스 정리**: render-report.sh 종료 시 서버 프로세스 자동 정리
- **다크 모드**: 시스템 설정 자동 감지 + 수동 토글

## 디자인 품질 요구사항

이 프로젝트의 HTML/CSS 구현은 **높은 디자인 품질**이 핵심이다. 제네릭한 AI 생성 디자인이 아닌, 프로페셔널한 프레젠테이션 수준의 시각적 완성도를 목표로 한다.

**구현 시 반드시 활용할 스킬:**
- `/design-consultation` — 프로젝트 시작 시 디자인 시스템 (타이포그래피, 색상, 간격, 모션) 정의. DESIGN.md 생성
- `/frontend-design` — template.html, style.css, report.js 등 프론트엔드 코드 작성 시 활용. 독창적이고 세련된 인터페이스 생성
- `/design-review` — 구현 후 시각적 QA. 간격 불일치, 계층 구조 문제, AI slop 패턴 탐지 및 수정
- `/plan-design-review` — 디자인 계획 단계에서 각 디자인 차원을 0-10으로 평가하고 10점으로 만들기 위한 구체적 개선

**디자인 원칙:**
- 기술 문서에 특화된 타이포그래피 (코드와 산문의 조화)
- 프레젠테이션급 시각적 계층 구조 (섹션 간 명확한 분리, 핵심 포인트 강조)
- 커스텀 블록(comparison, timeline, metric 등)은 각각 고유한 시각적 아이덴티티를 가짐
- 인라인 코멘트 UI는 GitHub PR 리뷰 수준의 직관성
- 다크/라이트 모드 모두에서 가독성과 미적 완성도 유지

## 구현 우선순위

1. **MVP**: render-report.sh + server.py + template.html + 기본 CSS + 코멘트 시스템
2. **v1.1**: 커스텀 블록 렌더러 (mermaid, callout, comparison 우선)
3. **v1.2**: 나머지 커스텀 블록 + 다크 모드 + 반응형
