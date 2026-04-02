# Report Viewer 통합 가이드

보고서를 생성하는 스킬(simon-study, simon-oncall, simon-bot-report, simon-bot)이 HTML Report Viewer를 사용하기 위한 공유 프로토콜.

> **전제조건**: `~/.claude/skills/_shared/report-viewer/render-report.sh`가 설치되어 있어야 한다. 설치 전이면 이 프로토콜을 건너뛰고 기존 방식(마크다운 출력)으로 동작한다.

## Report Viewer 활성화 확인

```bash
REPORT_VIEWER="$HOME/.claude/skills/_shared/report-viewer/render-report.sh"
if [ -x "$REPORT_VIEWER" ]; then
  VIEWER_AVAILABLE=true
else
  VIEWER_AVAILABLE=false
fi
```

## Phase: HTML 렌더링 + 브라우저 오픈

마크다운 보고서 저장 직후에 이 Phase를 실행한다.

**조건**: `$VIEWER_AVAILABLE == true`

```bash
~/.claude/skills/_shared/report-viewer/render-report.sh "{markdown_file}" --open
```

출력 예시:
```json
{ "url": "http://localhost:3847", "comments_file": "/path/to/report-comments.json", "pid": 12345 }
```

사용자에게 안내:
> 보고서를 브라우저에서 열었습니다: http://localhost:{port}
> 내용을 확인하시고 코멘트를 남겨주세요. 완료되면 '리뷰 완료'라고 말씀해주세요.
> 마크다운 경로: {markdown_file}

**Fallback** (`$VIEWER_AVAILABLE == false`):
기존 방식대로 터미널에 마크다운 내용을 출력하고, AskUserQuestion으로 피드백을 수집한다.

## Phase: 코멘트 피드백 루프

사용자가 "리뷰 완료"라고 말하면 실행한다.

**1. 코멘트 읽기**

```bash
COMMENTS_FILE="{markdown_dir}/{markdown_basename}-comments.json"
```

Read 도구로 `$COMMENTS_FILE`을 읽는다. 파일이 없거나 비어 있으면:
> 코멘트가 없습니다. 보고서를 그대로 확정합니다.

**2. 코멘트 처리**

각 코멘트의 `intent`에 따라 처리:

| intent | 처리 |
|--------|------|
| `fix` | 해당 섹션을 마크다운에서 수정 (Edit) |
| `question` | 답변을 해당 섹션 아래에 추가 |
| `expand` | 추가 분석 수행 후 섹션 확장 |
| `approve` | 처리 불필요, status를 resolved로 변경 |

**3. 마크다운 업데이트**

수정된 내용을 마크다운 파일에 Edit으로 반영한다. 마크다운이 정본이므로 여기가 먼저다.

**4. HTML 재생성**

```bash
~/.claude/skills/_shared/report-viewer/render-report.sh "{markdown_file}" --open
```

**5. 코멘트 상태 업데이트**

처리된 코멘트의 `status`를 `"resolved"`로 변경하여 `$COMMENTS_FILE`에 다시 저장한다.

**6. 반복**

사용자에게 안내:
> N개 코멘트를 처리했습니다. 업데이트된 보고서를 확인해주세요.
> 추가 코멘트가 있으면 브라우저에서 남기고 '리뷰 완료'라고 말씀해주세요.
> 완료되었으면 '확정'이라고 말씀해주세요.

사용자가 "확정"이라고 하면 리뷰 루프를 종료한다.

## 마크다운 작성 가이드라인

Report Viewer와 함께 사용하는 마크다운은 두 가지 역할을 한다:
1. **AI 컨텍스트 정본**: 다음 세션에서 Claude가 읽는 상세 문서
2. **HTML 렌더링 소스**: 사용자가 시각적으로 보는 문서

따라서 마크다운 작성 시:
- 상세하게 작성한다 — AI가 다음 작업의 컨텍스트로 사용할 수 있어야 함
- 커스텀 블록 문법을 적극 활용한다 — 내용에 가장 효과적인 시각화 방식을 선택
- 프레젠테이션처럼 구성한다 — 섹션마다 핵심 메시지를 먼저, 상세 내용은 뒤에
- mermaid 다이어그램을 적극 사용한다 — 복잡한 흐름이나 관계는 항상 다이어그램으로

### 커스텀 블록 사용 가이드

어떤 내용에 어떤 블록을 쓸지:

| 내용 유형 | 추천 블록 | 예시 |
|-----------|-----------|------|
| 데이터 흐름, 아키텍처 | ` ```mermaid ` (flowchart) | 서비스 간 호출 흐름 |
| 시간순 이벤트 | `:::timeline` | 장애 타임라인, 프로젝트 마일스톤 |
| A vs B 비교 | `:::comparison` | 방안 비교, before/after |
| 주의사항 | `:::callout[warning]` | 하위 호환성 경고, 보안 이슈 |
| KPI / 핵심 수치 | `:::metric[label]` | 에러율, 응답 시간, 커버리지 |
| 단계별 절차 | `:::steps` | 마이그레이션 순서, 배포 절차 |
| 여러 관점 병렬 제시 | `:::tabs` | 언어별 코드, 환경별 설정 |
| 긴 상세 내용 | `:::collapse[title]` | SQL 쿼리 전문, 상세 로그 |
| 외부 인용 | `:::quote[source]` | Confluence 문서, Slack 메시지 |

## 스킬별 통합 위치

| 스킬 | 마크다운 저장 시점 | HTML 렌더링 위치 | 기존 리뷰 방식 |
|------|-------------------|-----------------|---------------|
| simon-study | Phase 3 보고서 출력 | Phase 3 직후 | Phase 3 이후 종료 → 리뷰 루프 추가 |
| simon-oncall | Phase 4 산출물 작성 | Phase 4 직후 | Phase 5 추가 분석 → 리뷰 루프로 대체 |
| simon-bot-report | Step 4-C 출력 | Step 4-C 직후 | Step 5 순차 리뷰 → 리뷰 루프로 대체 |
| simon-bot | plan-summary.md 저장 | 저장 직후 | 사용자 확인 → 리뷰 루프 추가 |
