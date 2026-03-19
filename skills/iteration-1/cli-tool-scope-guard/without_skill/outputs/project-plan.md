# 프로젝트 계획: CSV-to-JSON CLI 도구

## 개요

- **프로젝트 규모**: 소규모 유틸리티
- **인원**: 개발자 1명
- **기간**: 2~3일 (약 18시간)
- **권장 언어**: Go (크로스 플랫폼 바이너리 배포 용이, 스트리밍 처리 강점)

## 기술 스택 (Go 기준)

| 구성 요소 | 선택지 |
|-----------|--------|
| CLI 프레임워크 | `cobra` 또는 `flag` (표준) |
| CSV 파싱 | `encoding/csv` (표준) |
| JSON 출력 | `encoding/json` (표준) |
| 인코딩 감지 | `github.com/saintfish/chardet` + `golang.org/x/text/encoding` |
| 테스트 | `testing` (표준) + `testify/assert` |

## TDD 기반 개발 단계

### Day 1: 기반 구조 + 핵심 기능 (약 8시간)

**Step 1. 프로젝트 초기화 (1시간)**
- Go 모듈 초기화
- CLI 프레임워크 설정 (`--input`, `--output`, `--columns`, `--encoding` 플래그)
- 기본 `--help` 출력 확인

**Step 2. 기본 CSV-to-JSON 변환 (3시간, TDD)**
- RED: 단순 CSV 입력 -> JSON 출력 테스트 작성
- GREEN: `encoding/csv`로 파싱, `encoding/json`으로 출력
- REFACTOR: 파서/변환기 인터페이스 분리

**Step 3. 컬럼 필터링 (2시간, TDD)**
- RED: `--columns name,age` 플래그로 특정 컬럼만 출력하는 테스트
- GREEN: 헤더 기반 컬럼 인덱스 매핑 + 필터링 구현
- REFACTOR: 존재하지 않는 컬럼명 에러 처리

**Step 4. 인코딩 자동 감지 (2시간, TDD)**
- RED: EUC-KR/Shift_JIS 인코딩 CSV 파일 -> UTF-8 JSON 변환 테스트
- GREEN: chardet로 감지 -> golang.org/x/text로 디코딩
- REFACTOR: `--encoding` 수동 지정 옵션 추가 (감지 실패 fallback)

### Day 2: 스트리밍 + 마무리 (약 8시간)

**Step 5. 대용량 스트리밍 (4시간, TDD)**
- RED: 메모리 제한 환경에서 대용량 CSV 처리 테스트
- GREEN: 행 단위 읽기 -> 행 단위 JSON 출력 (NDJSON 모드 지원)
- REFACTOR: `--format` 플래그 (`array` | `ndjson`) 선택 옵션
- stdin/stdout 파이프 지원

**Step 6. 에러 처리 + 엣지 케이스 (2시간)**
- 빈 파일, 헤더만 있는 파일, 비정형 행(컬럼 수 불일치)
- 바이너리 파일 입력 감지 및 거부
- 명확한 에러 메시지 출력

**Step 7. 통합 테스트 + 문서화 (2시간)**
- E2E 테스트: 실제 파일 입출력
- README 작성: 설치, 사용법, 예제
- 테스트 커버리지 80% 이상 확인

### Day 3 (필요시): 배포 준비 (약 2시간)

- GoReleaser 설정 (멀티 플랫폼 빌드)
- GitHub Actions CI 설정
- 첫 릴리스 태깅

## CLI 인터페이스 설계 (예시)

```
csv2json [flags] <input.csv>

Flags:
  -o, --output <file>      출력 파일 (기본: stdout)
  -c, --columns <cols>     출력할 컬럼 (쉼표 구분, 예: name,age)
  -e, --encoding <enc>     입력 파일 인코딩 (기본: auto)
  -f, --format <fmt>       출력 형식: array | ndjson (기본: array)
  -d, --delimiter <char>   CSV 구분자 (기본: ,)
      --pretty             JSON 들여쓰기 출력
  -h, --help               도움말
  -v, --version            버전
```

## 완료 기준 (Definition of Done)

- [ ] 기본 CSV -> JSON 변환 동작
- [ ] 인코딩 자동 감지 (UTF-8, EUC-KR, Shift_JIS 등)
- [ ] `--columns` 플래그로 컬럼 필터링
- [ ] 대용량 파일(1GB+) 처리 시 메모리 사용량 일정
- [ ] 테스트 커버리지 80% 이상
- [ ] `--help` 문서화
