마크다운 파일에서 헤딩(`#`, `##`, `###` 등)을 추출해 목차(Table of Contents)를 자동 생성하는 Node.js CLI 도구를 제안드립니다.

---

## 프로젝트 구조

```
md-toc/
├── package.json
├── bin/
│   └── md-toc.js        # CLI 진입점
└── lib/
    └── toc-generator.js  # 핵심 로직
```

## 핵심 설계

### 1. `package.json`

- `name`: `md-toc`
- `bin` 필드에 `md-toc` 커맨드 등록
- 외부 의존성 없이 Node.js 내장 모듈(`fs`, `path`)만 사용
- `commander` 패키지 하나만 추가하여 CLI 인자 파싱 (선택사항 -- 직접 `process.argv` 파싱도 가능)

### 2. `lib/toc-generator.js` -- 핵심 로직

**동작 방식:**

1. 마크다운 파일을 읽어 줄 단위로 분리
2. 코드 블록(`` ``` ``) 안의 내용은 무시 (토글 플래그로 추적)
3. `^#{1,6}\s+(.+)$` 정규식으로 헤딩 라인 추출
4. `#` 개수로 레벨 결정, 텍스트에서 앵커 ID 생성
5. 레벨에 따라 들여쓰기된 마크다운 링크 목록 생성

**앵커 ID 생성 규칙** (GitHub 호환):
- 소문자 변환
- 공백을 `-`로 대체
- 특수문자 제거
- 중복 헤딩은 `-1`, `-2` 접미사 추가

**출력 예시:**
```markdown
- [Introduction](#introduction)
  - [Getting Started](#getting-started)
    - [Installation](#installation)
    - [Configuration](#configuration)
  - [Usage](#usage)
```

### 3. `bin/md-toc.js` -- CLI 인터페이스

**사용법:**
```bash
md-toc <file.md> [options]
```

**옵션:**
| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--min-level <n>` | 최소 헤딩 레벨 (예: 2면 `##`부터) | `1` |
| `--max-level <n>` | 최대 헤딩 레벨 | `6` |
| `--insert` | 파일 내 `<!-- toc -->` 마커 위치에 목차 삽입 | `false` |
| `--output <file>` | 결과를 파일로 저장 | stdout |
| `--no-link` | 앵커 링크 없이 텍스트만 출력 | `false` |

**동작 모드:**
- **기본**: 목차를 stdout에 출력
- **`--insert`**: 원본 파일에서 `<!-- toc -->` ... `<!-- /toc -->` 사이에 목차를 삽입/갱신
- **`--output`**: 지정 파일에 목차 저장

### 4. 에러 처리

- 파일이 존재하지 않을 때: 명확한 에러 메시지 + exit code 1
- 헤딩이 없을 때: "No headings found" 경고 출력
- 인코딩: UTF-8 기본

## 사용 예시

```bash
# 목차 출력
npx md-toc README.md

# h2~h4만 포함
npx md-toc README.md --min-level 2 --max-level 4

# 파일에 직접 삽입
npx md-toc README.md --insert

# 글로벌 설치 후 사용
npm install -g md-toc
md-toc docs/guide.md
```

## 구현 시 고려사항

- **코드 블록 무시**: 펜스드 코드 블록(`` ``` ``) 내부의 `#`은 헤딩으로 인식하지 않아야 합니다.
- **HTML 태그 제거**: 헤딩 텍스트에 포함된 인라인 HTML은 앵커 생성 시 제거해야 합니다.
- **인라인 코드/링크**: 헤딩 내 `` `code` ``나 `[link](url)` 형식은 텍스트만 추출합니다.
- **중복 헤딩 처리**: 같은 이름의 헤딩이 여러 개면 GitHub 방식으로 `-1`, `-2` 등 접미사를 붙입니다.

---

이 정도면 실용적이면서도 간결한 CLI 도구가 됩니다. 구현을 진행할까요?
