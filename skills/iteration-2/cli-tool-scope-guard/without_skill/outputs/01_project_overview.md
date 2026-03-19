# 프로젝트 개요: csv2json CLI 도구

## 프로젝트명
csv2json - CSV to JSON 변환 CLI 도구

## 프로젝트 목적
CSV 파일을 JSON 형식으로 변환하는 명령줄 도구를 개발한다.
인코딩 자동 감지, 컬럼 필터링, 대용량 파일 스트리밍 처리를 핵심 기능으로 지원한다.

## 배경 및 필요성
- 데이터 파이프라인에서 CSV-to-JSON 변환은 빈번하게 발생하는 작업이다
- 다양한 인코딩(EUC-KR, Shift-JIS, UTF-8 BOM 등)의 CSV 파일을 안전하게 처리할 필요가 있다
- 수 GB 이상의 대용량 CSV 파일을 메모리 부족 없이 처리해야 하는 현실적 요구가 있다
- 기존 도구들은 인코딩 감지 + 스트리밍 + 컬럼 필터링을 통합 제공하지 않는다

## 핵심 기능 요약

| 기능 | 설명 |
|------|------|
| CSV 파싱 | RFC 4180 호환 CSV 파싱 (따옴표, 이스케이프 처리) |
| JSON 출력 | 배열 형태 또는 NDJSON(줄 단위 JSON) 출력 지원 |
| 인코딩 자동 감지 | 파일 헤더 분석을 통한 인코딩 자동 판별 및 UTF-8 변환 |
| 컬럼 필터링 | 특정 컬럼만 선택하여 변환 (이름 또는 인덱스 기반) |
| 대용량 스트리밍 | 파일 전체를 메모리에 올리지 않고 스트리밍 방식으로 처리 |

## 대상 사용자
- 데이터 엔지니어
- 백엔드 개발자
- 데이터 분석가 (CLI 사용 가능한)
- CI/CD 파이프라인 자동화 스크립트

## 사용 예시 (목표)
```bash
# 기본 변환
csv2json input.csv -o output.json

# 컬럼 필터링
csv2json input.csv --columns "name,email,age"

# 인코딩 명시 (자동 감지 우회)
csv2json input.csv --encoding euc-kr

# 대용량 파일 NDJSON 스트리밍 출력
csv2json large.csv --stream --format ndjson > output.jsonl

# stdin/stdout 파이프라인
cat input.csv | csv2json --columns "id,value" > output.json
```
