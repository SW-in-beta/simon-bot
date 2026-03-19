# Phase 0: 요구사항 분석 - CSV to JSON CLI 도구

## 프로젝트 개요
CSV 파일을 읽어서 JSON 형식으로 변환하는 커맨드라인 도구.
인코딩 자동 감지, 컬럼 필터링, 대용량 파일 스트리밍을 핵심 기능으로 지원한다.

## 기능 요구사항

### FR-1: CSV 파일 읽기 및 JSON 변환
- CSV 파일을 입력받아 JSON 형식으로 출력한다
- 첫 번째 행을 헤더(키)로 사용하거나, 헤더 없는 모드를 지원한다
- 구분자(delimiter) 지정 가능 (기본값: 콤마)
- 출력 형식: JSON Array 또는 JSON Lines (NDJSON)
- 출력 대상: stdout 또는 파일 지정

### FR-2: 인코딩 자동 감지
- 입력 파일의 문자 인코딩을 자동으로 감지한다
- 지원 인코딩: UTF-8, UTF-8 BOM, EUC-KR, CP949, Shift_JIS, ISO-8859-1, UTF-16 등
- 감지된 인코딩을 UTF-8로 변환하여 처리한다
- 사용자가 인코딩을 명시적으로 지정할 수 있는 옵션도 제공한다

### FR-3: 컬럼 필터링
- 특정 컬럼만 선택하여 변환할 수 있다 (include 방식)
- 특정 컬럼을 제외하고 변환할 수 있다 (exclude 방식)
- 컬럼 이름 또는 인덱스(0-based)로 지정 가능
- 컬럼 이름 변경(rename/alias) 지원

### FR-4: 대용량 파일 스트리밍
- 파일 전체를 메모리에 올리지 않고 스트리밍 방식으로 처리한다
- 수 GB 크기의 파일도 일정한 메모리 사용량으로 처리 가능해야 한다
- JSON Lines(NDJSON) 형식 출력 시 행 단위 스트리밍
- JSON Array 형식 출력 시에도 스트리밍 기반으로 점진적 출력

## 비기능 요구사항

### NFR-1: 성능
- 1GB CSV 파일을 1분 이내에 변환 (로컬 SSD 기준)
- 메모리 사용량: 파일 크기와 무관하게 100MB 이하 유지

### NFR-2: 사용성
- 직관적인 CLI 인터페이스 (--help로 모든 옵션 확인 가능)
- 에러 메시지는 원인과 해결 방법을 포함
- 진행률 표시 (stderr, --quiet 옵션으로 비활성화 가능)

### NFR-3: 호환성
- macOS, Linux 지원
- Python 3.10+ 또는 Go 1.21+ (기술 선택에 따라)
- pip install 또는 단일 바이너리로 배포 가능

## 사용 시나리오

### 시나리오 1: 기본 변환
```
csv2json input.csv > output.json
```

### 시나리오 2: 특정 컬럼만 추출
```
csv2json input.csv --columns name,email,phone -o output.json
```

### 시나리오 3: 인코딩이 다른 파일 처리
```
csv2json euc-kr-file.csv --encoding auto -o output.json
```

### 시나리오 4: 대용량 파일 스트리밍
```
csv2json huge-file.csv --format ndjson | head -100
```

### 시나리오 5: 컬럼 제외 및 구분자 지정
```
csv2json data.tsv --delimiter '\t' --exclude-columns password,secret
```

### 시나리오 6: 파이프라인 사용
```
cat input.csv | csv2json --format ndjson | jq '.name'
```
