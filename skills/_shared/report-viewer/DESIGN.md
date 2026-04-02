# Design System — Report Viewer

## Product Context
- **What this is:** AI 에이전트가 생성한 기술 보고서/분석 문서를 시각적으로 렌더링하고, 인라인 코멘트로 리뷰하는 로컬 HTML 뷰어
- **Who it's for:** 시니어 개발자 1인 (코드 분석, 온콜 보고서, RFC, 학습 보고서 리뷰)
- **Space/industry:** 개발자 도구 / 기술 문서 뷰어. 참조: Stripe Docs, GitHub PR Review, Linear App
- **Project type:** 로컬 HTML 뷰어 (웹 앱이 아님, CDN JS + 로컬 CSS만 사용)

## Aesthetic Direction
- **Direction:** Industrial-Editorial — 기능 중심의 도구적 느낌 + 에디토리얼 타이포그래피의 세련함
- **Decoration level:** Minimal — 타이포그래피와 여백이 모든 일을 함. 커스텀 블록만 시각적 개성
- **Mood:** 모든 픽셀이 목적을 가진 전문 도구. 마케팅 크롬 없이 콘텐츠와 리뷰 기능만 존재. 따뜻하지만 절제된 신뢰감
- **Key insight:** 대부분의 문서 도구가 '발견(discovery)'에 최적화되지만, 이 도구는 '리뷰(review)'에 최적화. 코멘트가 1등 시민

## Typography
- **Display/Hero:** Satoshi (700, 900) — 기하학적 산세리프, 헤딩에서 권위감. Inter/Poppins 등 과용된 폰트와 구별
- **Body:** Instrument Sans (400, 500, 600) — x-height 높아 작은 크기에서도 선명. 기술 문서 가독성 우수
- **UI/Labels:** Instrument Sans (600) — 본문과 동일 패밀리, 웨이트로 구분
- **Data/Tables:** Geist (400, 500, 600, tabular-nums) — 수치 데이터 정렬에 완벽
- **Code:** JetBrains Mono (400, 500) — 코드 가독성의 금본위. 리가쳐 지원
- **Loading:**
  - Satoshi: `https://api.fontshare.com/v2/css?f[]=satoshi@400,500,700,900&display=swap`
  - Instrument Sans: Google Fonts
  - JetBrains Mono: Google Fonts
  - Geist: Google Fonts
- **Scale:**
  - h1: 32px / 700-900 / -0.03em (Satoshi)
  - h2: 24px / 700 / -0.02em (Satoshi)
  - h3: 18px / 700 / -0.01em (Satoshi)
  - body: 15px / 400 / normal (Instrument Sans)
  - small: 13px / 400 (Instrument Sans)
  - caption: 11px / 600 / 0.05em uppercase (Instrument Sans)
  - code: 13px / 400 (JetBrains Mono)
  - data: 14px / 400 tabular-nums (Geist)

## Color
- **Approach:** Restrained — 콘텐츠가 주인공, 색상은 의미를 전달할 때만 등장
- **Primary accent:** `#0D9488` (warm teal) — 링크, 활성 TOC, 코멘트 마커, 포커스 링
  - Dark mode: `#2DD4BF`
  - Soft: `#CCFBF1` / Dark: `#134E4A`
  - Hover: `#0F766E` / Dark: `#5EEAD4`
- **Neutrals (warm gray):**
  - bg: `#FAFAF9` / dark: `#171717`
  - surface: `#FFFFFF` / dark: `#1E1E1E`
  - sidebar: `#F5F5F4` / dark: `#1A1A1A`
  - code-bg: `#F5F5F4` / dark: `#262626`
  - hover: `#F0EFED` / dark: `#2A2A2A`
  - text-primary: `#1C1917` / dark: `#FAFAF9`
  - text-secondary: `#57534E` / dark: `#A8A29E`
  - text-muted: `#A8A29E` / dark: `#78716C`
  - border: `#E7E5E4` / dark: `#2E2E2E`
  - border-strong: `#D6D3D1` / dark: `#404040`
- **Semantic:**
  - success: `#16A34A` / dark: `#4ADE80`
  - warning: `#CA8A04` / dark: `#FACC15`
  - error: `#DC2626` / dark: `#F87171`
  - info: `#2563EB` / dark: `#60A5FA`
- **Comment highlight:**
  - bg: `#FEF3C7` / dark: `#422006`
  - border: `#F59E0B` / dark: `#D97706`
- **Dark mode strategy:** CSS custom properties + `prefers-color-scheme` 자동 감지 + `data-theme` 속성으로 수동 토글. localStorage에 사용자 선택 저장

## Spacing
- **Base unit:** 4px
- **Density:** Comfortable — 기술 문서의 적절한 밀도, 빵빵하지 않음
- **Scale:** 2xs(2px) xs(4px) sm(8px) md(16px) lg(24px) xl(32px) 2xl(48px) 3xl(64px)
- **Key spacing rules:**
  - 섹션 간: 3xl(64px)
  - 헤딩 위: xl(32px), 아래: md(16px)
  - 코드 블록 위아래: lg(24px)
  - 단락 간: md(16px)
  - 사이드바 아이템 간: xs(4px)

## Layout
- **Approach:** Content-first single column + sidebar
- **Structure:** 왼쪽 사이드바(220px, TOC + 리뷰 진행) + 넓은 컨텐츠(1fr) + 오른쪽 코멘트 마진(240px)
- **Max content width:** 본문 영역 내 max-width 없음 (3컬럼 그리드가 제어)
- **Border radius:**
  - sm: 4px (인풋, 코드 블록 내부)
  - md: 8px (카드, 버튼, 인풋)
  - lg: 12px (큰 카드, 모달)
  - full: 9999px (뱃지, 태그)
- **Responsive:** 900px 이하에서 사이드바와 코멘트 마진 숨김, 단일 컬럼

## Motion
- **Approach:** Minimal-functional — 이해를 돕는 경우에만 애니메이션
- **Easing:** enter(ease-out) exit(ease-in) move(ease-in-out)
- **Duration:** micro(50-100ms) short(150-250ms) medium(250-400ms)
- **적용:**
  - TOC 활성 아이템 전환: 150ms ease
  - 코멘트 패널 열림/닫힘: 200ms ease-out
  - 접이식 섹션 토글: 200ms ease-in-out
  - 테마 전환 (배경/텍스트): 200ms ease
  - 토스트 메시지: 300ms slide-up

## Custom Block Visual Identity
각 커스텀 블록은 고유한 시각적 아이덴티티를 가짐:
- **callout:** 왼쪽 3px 보더 + 타입별 배경색 (info=파란, warning=노란, error=빨간, success=초록)
- **comparison:** 2컬럼 카드 그리드, 추천 옵션은 accent 보더 + accent-soft 배경
- **timeline:** 왼쪽 2px 수직선 + accent 원형 마커
- **steps:** accent 원형 숫자 뱃지 + 텍스트
- **metric:** 큰 accent 숫자 + uppercase muted 라벨, 카드 형태
- **tabs:** 상단 탭 버튼 + 패널 전환
- **collapse:** 클릭 가능한 헤더 + 화살표 아이콘 + 접이식 본문
- **quote:** 왼쪽 보더 + 이탤릭 + 소스 라벨

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-31 | Initial design system created | /design-consultation 기반. Agentation/Vibe Annotations 리서치 + Mintlify/Stripe Docs/Linear 참조 |
| 2026-03-31 | Industrial-Editorial aesthetic | 리뷰 도구로서의 기능성 + 기술 문서 읽기 경험의 세련함 양립 |
| 2026-03-31 | Warm Teal accent (#0D9488) | 일반적인 파란색 링크와 차별화, 시맨틱 컬러와 충돌 없음, 다크/라이트 모두 작동 |
| 2026-03-31 | 코멘트 항상 보임 레이아웃 | 리뷰 도구의 핵심 기능을 숨기지 않음. GitHub PR 리뷰처럼 코멘트가 1등 시민 |
| 2026-03-31 | Satoshi + Instrument Sans 조합 | 과용된 Inter/Poppins 회피. Satoshi는 헤딩에서 개성, Instrument Sans는 본문에서 가독성 |
