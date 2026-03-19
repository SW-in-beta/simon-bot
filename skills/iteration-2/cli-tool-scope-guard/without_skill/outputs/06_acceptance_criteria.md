# 인수 기준 (Acceptance Criteria)

## 1. 기본 변환 기능

### AC-1.1: CSV 파일을 JSON 배열로 변환
- **Given**: 유효한 CSV 파일이 존재할 때
- **When**: `csv2json input.csv` 실행
- **Then**: stdout에 JSON 배열이 출력된다
- **Then**: 각 행은 헤더를 키로 사용하는 JSON 오브젝트이다
- **Then**: 종료 코드 0으로 정상 종료한다

### AC-1.2: 출력 파일 지정
- **Given**: 유효한 CSV 파일이 존재할 때
- **When**: `csv2json input.csv -o output.json` 실행
- **Then**: output.json 파일에 JSON이 저장된다

### AC-1.3: stdin 입력 지원
- **Given**: CSV 데이터가 파이프로 전달될 때
- **When**: `cat input.csv | csv2json` 실행
- **Then**: stdout에 JSON 배열이 출력된다

### AC-1.4: 헤더 없는 CSV 처리
- **Given**: 헤더 행이 없는 CSV 파일이 존재할 때
- **When**: `csv2json input.csv --no-header` 실행
- **Then**: 키가 "0", "1", "2" 등 인덱스 기반인 JSON 오브젝트가 출력된다

## 2. 인코딩 자동 감지

### AC-2.1: UTF-8 파일 자동 처리
- **Given**: UTF-8 인코딩 CSV 파일이 존재할 때
- **When**: `csv2json input.csv` 실행
- **Then**: 한글/일본어 등 다국어 문자가 깨지지 않고 JSON으로 출력된다

### AC-2.2: EUC-KR 파일 자동 감지 및 변환
- **Given**: EUC-KR 인코딩 CSV 파일이 존재할 때
- **When**: `csv2json input.csv` 실행
- **Then**: UTF-8로 변환된 JSON이 출력된다
- **Then**: 한글 문자가 정상적으로 표시된다

### AC-2.3: 인코딩 수동 지정
- **Given**: 자동 감지가 실패하는 CSV 파일이 존재할 때
- **When**: `csv2json input.csv --encoding euc-kr` 실행
- **Then**: 지정된 인코딩으로 디코딩하여 UTF-8 JSON을 출력한다

### AC-2.4: 인코딩 감지 정보 표시
- **Given**: 유효한 CSV 파일이 존재할 때
- **When**: `csv2json input.csv --verbose` 실행
- **Then**: stderr에 감지된 인코딩명과 신뢰도가 표시된다

## 3. 컬럼 필터링

### AC-3.1: 컬럼 이름 기반 필터링
- **Given**: 헤더가 "name,email,age,password"인 CSV 파일이 존재할 때
- **When**: `csv2json input.csv --columns "name,email"` 실행
- **Then**: 출력 JSON의 각 오브젝트에 "name"과 "email" 키만 존재한다

### AC-3.2: 컬럼 인덱스 기반 필터링
- **Given**: 4개 컬럼의 CSV 파일이 존재할 때
- **When**: `csv2json input.csv --columns "0,2"` 실행
- **Then**: 첫 번째와 세 번째 컬럼만 포함된 JSON이 출력된다

### AC-3.3: 컬럼 제외 필터링
- **Given**: 헤더가 "name,email,age,password"인 CSV 파일이 존재할 때
- **When**: `csv2json input.csv --exclude-columns "password"` 실행
- **Then**: "password" 키를 제외한 JSON이 출력된다

### AC-3.4: 존재하지 않는 컬럼 지정 시 에러
- **Given**: 헤더가 "name,email"인 CSV 파일이 존재할 때
- **When**: `csv2json input.csv --columns "name,phone"` 실행
- **Then**: "phone" 컬럼을 찾을 수 없다는 에러 메시지가 stderr에 출력된다
- **Then**: 종료 코드 1로 종료한다

## 4. 대용량 파일 스트리밍

### AC-4.1: 스트리밍 모드 NDJSON 출력
- **Given**: 대용량 CSV 파일이 존재할 때
- **When**: `csv2json large.csv --stream --format ndjson` 실행
- **Then**: 각 행이 독립된 JSON 오브젝트로 한 줄씩 출력된다
- **Then**: 모든 행이 처리될 때까지 출력이 계속된다

### AC-4.2: 메모리 사용량 제한
- **Given**: 1GB 이상의 CSV 파일이 존재할 때
- **When**: 스트리밍 모드로 처리할 때
- **Then**: 프로세스 메모리 사용량이 100MB를 초과하지 않는다

### AC-4.3: 진행률 표시
- **Given**: 대용량 CSV 파일이 존재할 때
- **When**: `csv2json large.csv --progress` 실행
- **Then**: stderr에 처리된 행 수 또는 바이트 진행률이 주기적으로 표시된다

## 5. 에러 처리

### AC-5.1: 존재하지 않는 파일
- **Given**: 존재하지 않는 파일 경로가 지정될 때
- **When**: `csv2json nonexistent.csv` 실행
- **Then**: "파일을 찾을 수 없습니다" 에러 메시지가 stderr에 출력된다
- **Then**: 종료 코드 1로 종료한다

### AC-5.2: 잘못된 CSV 형식
- **Given**: 손상된 CSV 파일이 존재할 때
- **When**: `csv2json broken.csv` 실행
- **Then**: 에러 발생 행 번호와 함께 에러 메시지가 출력된다

### AC-5.3: 도움말 표시
- **When**: `csv2json --help` 실행
- **Then**: 모든 옵션과 사용법이 표시된다

### AC-5.4: 버전 표시
- **When**: `csv2json --version` 실행
- **Then**: 버전 정보가 출력된다
