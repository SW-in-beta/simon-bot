# Phase 0: 구현 계획 - CSV to JSON CLI 도구

## TDD 구현 순서

TDD(Red-Green-Refactor) 사이클을 준수하여 아래 순서로 구현한다.
각 단계에서 실패하는 테스트를 먼저 작성하고, 통과하는 최소 코드를 작성한 뒤, 리팩토링한다.

---

### Phase 1: 프로젝트 셋업
- [ ] 프로젝트 디렉토리 구조 생성
- [ ] `pyproject.toml` 설정 (의존성, 빌드, entry_points)
- [ ] 개발 환경 구성 (pytest, ruff, mypy)
- [ ] CI 기본 설정 (lint + test)

### Phase 2: 인코딩 감지 모듈 (`encoding.py`)
**TDD 사이클:**
1. RED: UTF-8 파일의 인코딩을 감지하는 테스트 작성 → 실패 확인
2. GREEN: 기본 인코딩 감지 함수 구현 → 통과 확인
3. RED: UTF-8 BOM 파일 감지 테스트 → 실패
4. GREEN: BOM 감지 로직 추가 → 통과
5. RED: EUC-KR/CP949 파일 감지 테스트 → 실패
6. GREEN: charset-normalizer 통합 → 통과
7. RED: 신뢰도 낮은 경우 UTF-8 폴백 테스트 → 실패
8. GREEN: 폴백 로직 구현 → 통과
9. RED: 사용자 지정 인코딩 테스트 → 실패
10. GREEN: 인코딩 오버라이드 옵션 구현 → 통과
11. REFACTOR: 중복 제거, 인터페이스 정리

**테스트 데이터:**
- fixtures/utf8.csv, fixtures/utf8-bom.csv, fixtures/euc-kr.csv 등 준비

### Phase 3: CSV 리더 모듈 (`reader.py`)
**TDD 사이클:**
1. RED: 기본 CSV 파일을 Dict 이터레이터로 읽는 테스트 → 실패
2. GREEN: csv.DictReader 기반 generator 구현 → 통과
3. RED: 커스텀 구분자(탭, 세미콜론) 테스트 → 실패
4. GREEN: delimiter 파라미터 지원 → 통과
5. RED: 헤더 없는 CSV 테스트 → 실패
6. GREEN: no_header 모드 구현 (col_0, col_1, ... 자동 생성) → 통과
7. RED: 빈 파일 처리 테스트 → 실패
8. GREEN: 빈 파일 예외 처리 → 통과
9. RED: 잘못된 행(컬럼 수 불일치) 테스트 → 실패
10. GREEN: strict/lenient 모드 구현 → 통과
11. REFACTOR

### Phase 4: 컬럼 필터링 모듈 (`filter.py`)
**TDD 사이클:**
1. RED: 특정 컬럼 include 테스트 → 실패
2. GREEN: include 필터 구현 → 통과
3. RED: 특정 컬럼 exclude 테스트 → 실패
4. GREEN: exclude 필터 구현 → 통과
5. RED: 존재하지 않는 컬럼 지정 시 에러 테스트 → 실패
6. GREEN: 유효성 검사 구현 → 통과
7. RED: 컬럼 rename 테스트 → 실패
8. GREEN: rename 로직 구현 → 통과
9. RED: include + rename 조합 테스트 → 실패
10. GREEN: 파이프라인 조합 구현 → 통과
11. REFACTOR

### Phase 5: JSON 출력 모듈 (`writer.py`)
**TDD 사이클:**
1. RED: Dict 리스트를 JSON Array로 출력하는 테스트 → 실패
2. GREEN: JSON Array 출력 구현 → 통과
3. RED: NDJSON 형식 출력 테스트 → 실패
4. GREEN: NDJSON 출력 구현 → 통과
5. RED: 스트리밍 JSON Array 출력 테스트 (메모리 사용량 검증) → 실패
6. GREEN: 스트리밍 JSON Array 구현 → 통과
7. RED: 빈 입력 처리 테스트 → 실패
8. GREEN: 빈 입력 시 빈 배열/빈 출력 → 통과
9. REFACTOR

### Phase 6: CLI 통합 (`cli.py`)
**TDD 사이클:**
1. RED: 기본 실행 (파일 → stdout) 통합 테스트 → 실패
2. GREEN: Click CLI 기본 구조 구현 → 통과
3. RED: 모든 옵션 조합 테스트 → 실패
4. GREEN: 옵션 파싱 및 모듈 연결 → 통과
5. RED: stdin 입력 테스트 → 실패
6. GREEN: stdin 지원 구현 → 통과
7. RED: 에러 케이스 통합 테스트 (파일 없음, 잘못된 옵션) → 실패
8. GREEN: 에러 처리 및 종료 코드 구현 → 통과
9. REFACTOR

### Phase 7: 대용량 파일 스트리밍 검증
- [ ] 1GB 테스트 CSV 생성 스크립트 작성
- [ ] 메모리 프로파일링 테스트 (memory_profiler 또는 tracemalloc)
- [ ] 처리 시간 벤치마크
- [ ] 메모리 사용량 100MB 이하 확인

### Phase 8: 패키징 및 배포
- [ ] pyproject.toml entry_points 설정 (`csv2json` 커맨드)
- [ ] README 작성
- [ ] `--version` 옵션 구현

---

## 예상 일정

| 단계 | 예상 소요 |
|---|---|
| Phase 1: 프로젝트 셋업 | 0.5일 |
| Phase 2: 인코딩 감지 | 1일 |
| Phase 3: CSV 리더 | 0.5일 |
| Phase 4: 컬럼 필터링 | 0.5일 |
| Phase 5: JSON 출력 | 0.5일 |
| Phase 6: CLI 통합 | 1일 |
| Phase 7: 스트리밍 검증 | 0.5일 |
| Phase 8: 패키징 | 0.5일 |
| **합계** | **5일** |

## 리스크 및 대응

| 리스크 | 영향 | 대응 |
|---|---|---|
| 인코딩 감지 정확도 부족 | 중 | 샘플 크기 조정, 사용자 오버라이드 옵션 제공 |
| JSON Array 스트리밍 시 유효하지 않은 JSON 생성 | 상 | 중간 중단 시에도 유효한 JSON 보장 (signal handler) |
| orjson이 특정 플랫폼에서 설치 안 됨 | 하 | 표준 json 모듈 폴백 구현 |
| 매우 큰 단일 행 (긴 텍스트 셀) | 중 | 행 단위 처리이므로 영향 제한적, 경고 출력 |
