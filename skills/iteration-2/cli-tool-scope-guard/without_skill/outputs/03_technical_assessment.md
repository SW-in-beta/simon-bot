# 기술 평가서 (Technical Assessment)

## 1. 기술 스택 선정

### 1.1 언어: Go

**선정 사유:**
- 단일 바이너리 배포가 가능하여 CLI 도구에 최적
- 크로스 컴파일 지원 (Linux, macOS, Windows)
- 표준 라이브러리의 `encoding/csv`, `encoding/json`이 성숙하고 성능이 우수
- 스트리밍 처리에 적합한 `io.Reader`/`io.Writer` 인터페이스
- 메모리 사용량이 적고 GC 오버헤드가 낮음
- 팀 내 Go 사용 경험 보유 (adpacingsvc 등)

**대안 검토:**

| 언어 | 장점 | 단점 | 결론 |
|------|------|------|------|
| Python | chardet 등 인코딩 감지 라이브러리 풍부 | 단일 바이너리 배포 어려움, 런타임 의존 | 탈락 |
| Rust | 최고 성능, 메모리 안전성 | 학습 곡선, 개발 속도 느림 | 탈락 |
| Node.js | npm 생태계 활용 | 런타임 의존, 메모리 사용량 높음 | 탈락 |

### 1.2 주요 라이브러리

| 라이브러리 | 용도 | 비고 |
|-----------|------|------|
| `encoding/csv` (표준) | CSV 파싱 | RFC 4180 호환, 스트리밍 지원 |
| `encoding/json` (표준) | JSON 출력 | `json.Encoder`로 스트리밍 출력 |
| `github.com/spf13/cobra` | CLI 프레임워크 | 서브커맨드, 플래그, 도움말 자동 생성 |
| `github.com/saintfish/chardet` | 인코딩 감지 | ICU 기반 chardet Go 포팅 |
| `golang.org/x/text/encoding` | 인코딩 변환 | EUC-KR, Shift-JIS 등 → UTF-8 변환 |
| `golang.org/x/text/transform` | 스트리밍 인코딩 변환 | `io.Reader` 래핑으로 스트리밍 변환 |

### 1.3 빌드 및 배포
- Go Modules (`go.mod`)로 의존성 관리
- GoReleaser로 크로스 플랫폼 빌드 및 GitHub Releases 배포
- GitHub Actions CI/CD

## 2. 아키텍처 설계 (초안)

```
┌─────────────────────────────────────────────────────┐
│                    CLI Layer (cobra)                 │
│  플래그 파싱, 입출력 설정, 에러 핸들링               │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Core Pipeline                       │
│                                                      │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐          │
│  │ Encoding │→ │ CSV       │→ │ Column   │→ JSON    │
│  │ Detector │  │ Reader    │  │ Filter   │  Writer  │
│  │ +Decoder │  │ (stream)  │  │          │          │
│  └──────────┘  └───────────┘  └──────────┘          │
│                                                      │
│  모든 단계가 io.Reader/io.Writer 기반 스트리밍        │
└─────────────────────────────────────────────────────┘
```

### 2.1 처리 흐름
1. **입력**: 파일 경로 또는 stdin으로 `io.Reader` 획득
2. **인코딩 감지**: 첫 8KB 샘플링 → 인코딩 판별 → `transform.NewReader`로 UTF-8 디코딩 Reader 래핑
3. **CSV 파싱**: `csv.NewReader`로 행 단위 스트리밍 읽기
4. **컬럼 필터링**: 헤더 행 기반으로 필요한 컬럼 인덱스 결정, 각 행에서 해당 컬럼만 추출
5. **JSON 출력**: 배열 모드 또는 NDJSON 모드로 `json.Encoder` 사용하여 스트리밍 출력

### 2.2 메모리 모델
- 스트리밍 모드: 한 번에 1행만 메모리에 보유 → O(1) 메모리
- 배열 모드 (기본): 스트리밍 출력이지만 JSON 배열 래핑 필요 → 여전히 O(1) 메모리 (행별 flush)
- 인코딩 감지용 버퍼: 최대 8KB 고정

## 3. 패키지 구조 (초안)

```
csv2json/
├── cmd/
│   └── root.go          # cobra 루트 커맨드, 플래그 정의
├── internal/
│   ├── encoding/
│   │   ├── detector.go  # 인코딩 자동 감지
│   │   └── decoder.go   # 인코딩 디코더 (Reader 래핑)
│   ├── csv/
│   │   └── reader.go    # CSV 스트리밍 리더 (구분자 감지 포함)
│   ├── filter/
│   │   └── column.go    # 컬럼 필터링 로직
│   └── json/
│       └── writer.go    # JSON/NDJSON 스트리밍 라이터
├── main.go
├── go.mod
├── go.sum
├── Makefile
├── .goreleaser.yml
└── .github/
    └── workflows/
        └── ci.yml
```

## 4. 기술적 도전 과제

### 4.1 인코딩 감지 정확도
- **문제**: chardet은 짧은 텍스트에서 오탐 가능성이 있음
- **대응**: 감지 신뢰도(confidence)가 낮을 경우 UTF-8로 폴백, `--encoding` 수동 지정 지원

### 4.2 JSON 배열 스트리밍 출력
- **문제**: JSON 배열 `[{...}, {...}, ...]`은 전체를 메모리에 모아야 할 것 같지만, 그렇지 않음
- **대응**: 첫 행 전에 `[` 출력, 행마다 JSON 오브젝트 출력 (두 번째 행부터 `,` 접두), 마지막에 `]` 출력

### 4.3 구분자 자동 감지
- **문제**: 탭, 세미콜론, 파이프 등 다양한 구분자 사용 파일 존재
- **대응**: 첫 몇 행 분석하여 후보 구분자별 컬럼 수 일관성 검사, 가장 일관된 구분자 선택

### 4.4 stdin + 인코딩 감지 충돌
- **문제**: stdin은 seek 불가 → 인코딩 감지용 샘플을 읽으면 되돌릴 수 없음
- **대응**: `io.TeeReader` 또는 버퍼에 샘플을 저장한 후 `io.MultiReader`로 원본 스트림 복원

## 5. 테스트 전략
- 단위 테스트: 각 패키지(encoding, csv, filter, json)별 독립 테스트
- 통합 테스트: 전체 파이프라인 end-to-end 테스트
- 테스트 픽스처: 다양한 인코딩의 샘플 CSV 파일 준비
- 벤치마크 테스트: 대용량 파일 처리 성능 및 메모리 사용량 측정
- TDD 준수: Red-Green-Refactor 사이클 엄격 적용
