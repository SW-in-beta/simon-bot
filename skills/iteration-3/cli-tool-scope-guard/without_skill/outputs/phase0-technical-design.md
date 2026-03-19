# Phase 0: 기술 설계 - CSV to JSON CLI 도구

## 기술 스택 선택

### 언어: Python 3.10+
**선택 이유:**
- `chardet`/`charset-normalizer` 라이브러리로 인코딩 감지가 성숙
- `csv` 표준 라이브러리의 스트리밍 지원이 우수
- CLI 배포 시 `pip install`로 간편 설치
- 빠른 프로토타이핑과 풍부한 생태계

### 핵심 라이브러리
| 라이브러리 | 용도 | 비고 |
|---|---|---|
| `click` | CLI 인터페이스 | argparse보다 선언적, 조합 용이 |
| `charset-normalizer` | 인코딩 감지 | chardet보다 빠르고 정확 |
| `orjson` | JSON 직렬화 | 표준 json 대비 5-10배 빠름 |
| `csv` (stdlib) | CSV 파싱 | 스트리밍 지원, 표준 라이브러리 |

## 아키텍처 설계

### 모듈 구조
```
csv2json/
├── __init__.py
├── __main__.py          # python -m csv2json 진입점
├── cli.py               # Click CLI 정의
├── encoding.py          # 인코딩 감지 및 변환
├── reader.py            # CSV 스트리밍 리더
├── filter.py            # 컬럼 필터링 로직
├── writer.py            # JSON 출력 (array, ndjson)
└── errors.py            # 커스텀 예외 정의

tests/
├── __init__.py
├── conftest.py          # 공통 fixture (샘플 CSV 파일 등)
├── test_encoding.py
├── test_reader.py
├── test_filter.py
├── test_writer.py
└── test_cli.py          # 통합 테스트
```

### 데이터 흐름
```
입력(파일/stdin)
    │
    ▼
┌──────────────┐
│ 인코딩 감지   │  charset-normalizer로 파일 앞부분 샘플링 (8KB)
│ (encoding.py) │  → 감지된 인코딩으로 TextIOWrapper 생성
└──────┬───────┘
       │  텍스트 스트림
       ▼
┌──────────────┐
│ CSV 리더     │  csv.reader/DictReader로 행 단위 이터레이터
│ (reader.py)  │  → 헤더 추출, 행 생성 (generator)
└──────┬───────┘
       │  Dict[str, str] 이터레이터
       ▼
┌──────────────┐
│ 컬럼 필터    │  include/exclude 적용
│ (filter.py)  │  → 컬럼 rename 적용
└──────┬───────┘
       │  Dict[str, str] 이터레이터 (필터링됨)
       ▼
┌──────────────┐
│ JSON 출력    │  ndjson: 행마다 json + newline
│ (writer.py)  │  array: 수동으로 [, comma, ] 스트리밍
└──────┬───────┘
       │
       ▼
  출력(stdout/파일)
```

### 핵심 설계 결정

#### 1. 스트리밍 파이프라인 (Generator 체인)
모든 처리 단계를 Python generator로 구현하여 메모리 효율을 보장한다.
```python
# 의사코드
rows = read_csv(detect_encoding(open(file, 'rb')))
filtered = apply_filter(rows, columns, exclude)
write_json(filtered, output, format='ndjson')
```

#### 2. 인코딩 감지 전략
- 파일 앞부분 8KB만 읽어서 인코딩을 감지 (전체 파일을 읽지 않음)
- BOM이 있으면 BOM 기반으로 즉시 판단
- BOM이 없으면 charset-normalizer로 통계적 감지
- 감지 신뢰도가 낮으면 (< 0.5) 경고 메시지 출력 후 UTF-8 폴백

#### 3. JSON Array 스트리밍 출력
전체를 메모리에 모으지 않고 스트리밍으로 출력:
```
1. "[" 출력
2. 첫 번째 행: json 출력
3. 이후 행: ",\n" + json 출력
4. "]" 출력
```

#### 4. 에러 처리 전략
- 잘못된 행(컬럼 수 불일치): `--strict` 모드에서는 에러, 기본은 경고 후 스킵
- 파일을 찾을 수 없음: 명확한 에러 메시지와 종료코드 1
- 인코딩 변환 실패: `errors='replace'`로 대체 문자 사용 (경고 출력)

## CLI 인터페이스 설계

```
csv2json [OPTIONS] [INPUT_FILE]

Arguments:
  INPUT_FILE              입력 CSV 파일 (생략 시 stdin)

Options:
  -o, --output FILE       출력 파일 (생략 시 stdout)
  -f, --format TEXT       출력 형식: json | ndjson (기본: json)
  -d, --delimiter TEXT    CSV 구분자 (기본: ,)
  -e, --encoding TEXT     입력 인코딩 (기본: auto)
  --no-header             첫 행을 헤더로 사용하지 않음
  -c, --columns TEXT      포함할 컬럼 (콤마 구분)
  -x, --exclude TEXT      제외할 컬럼 (콤마 구분)
  --rename TEXT            컬럼 이름 변경 (old:new 형식, 콤마 구분)
  --strict                잘못된 행에서 에러 발생
  -q, --quiet             진행률/경고 메시지 숨김
  --version               버전 출력
  -h, --help              도움말 출력
```

### 종료 코드
| 코드 | 의미 |
|---|---|
| 0 | 성공 |
| 1 | 입력 파일 오류 (파일 없음, 권한 등) |
| 2 | 잘못된 옵션/인수 |
| 3 | 파싱 오류 (strict 모드) |
