#!/usr/bin/env bash
# render-report.sh — 마크다운 보고서를 브라우저에서 열기 위한 CLI 진입점

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="${SCRIPT_DIR}/assets"
SERVER_PY="${SCRIPT_DIR}/server.py"
TEMPLATE_HTML="${SCRIPT_DIR}/template.html"

DEFAULT_PORT=3847
MAX_PORT_ATTEMPTS=10

# --- 기본값 ---
OPEN_BROWSER=true
PORT=""
NO_SERVER=false
MARKDOWN_FILE=""

# --- 인자 파싱 ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --open)
            OPEN_BROWSER=true
            shift
            ;;
        --no-open)
            OPEN_BROWSER=false
            shift
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --no-server)
            NO_SERVER=true
            shift
            ;;
        -*)
            echo "알 수 없는 옵션: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "$MARKDOWN_FILE" ]]; then
                MARKDOWN_FILE="$1"
            else
                echo "마크다운 파일이 이미 지정되었습니다: $MARKDOWN_FILE" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# --- 마크다운 파일 검증 ---
if [[ -z "$MARKDOWN_FILE" ]]; then
    echo "사용법: render-report.sh <markdown-file> [--open] [--port N] [--no-server]" >&2
    exit 1
fi

# 절대 경로로 변환
if [[ "$MARKDOWN_FILE" != /* ]]; then
    MARKDOWN_FILE="$(cd "$(dirname "$MARKDOWN_FILE")" && pwd)/$(basename "$MARKDOWN_FILE")"
fi

if [[ ! -f "$MARKDOWN_FILE" ]]; then
    echo "오류: 파일을 찾을 수 없습니다: $MARKDOWN_FILE" >&2
    exit 1
fi

if [[ "$MARKDOWN_FILE" != *.md ]]; then
    echo "오류: .md 파일만 지원합니다: $MARKDOWN_FILE" >&2
    exit 1
fi

# --- 코멘트 파일 경로 결정 ---
MARKDOWN_DIR="$(dirname "$MARKDOWN_FILE")"
MARKDOWN_BASENAME="$(basename "$MARKDOWN_FILE" .md)"
COMMENTS_FILE="${MARKDOWN_DIR}/${MARKDOWN_BASENAME}-comments.json"

# --- --no-server 모드: 정적 HTML 생성 후 종료 ---
if [[ "$NO_SERVER" == true ]]; then
    OUTPUT_HTML="${MARKDOWN_DIR}/${MARKDOWN_BASENAME}.html"
    MARKDOWN_CONTENT=$(cat "$MARKDOWN_FILE")

    if [[ -f "$TEMPLATE_HTML" ]]; then
        # template.html에서 플레이스홀더 치환 + CSS/JS 인라인
        /usr/bin/python3 -c "
import sys, json, os

template = open('${TEMPLATE_HTML}', 'r').read()
md_content = open('${MARKDOWN_FILE}', 'r').read()
escaped = json.dumps(md_content)

html = template.replace('{{MARKDOWN_CONTENT_JSON}}', escaped)
html = html.replace('{{MARKDOWN_PATH}}', '${MARKDOWN_FILE}')
html = html.replace('{{REPORT_TITLE}}', '${MARKDOWN_BASENAME}')
html = html.replace('{{SERVER_MODE}}', 'false')

# 정적 모드: CSS/JS를 인라인으로 삽입
css_path = os.path.join('${ASSETS_DIR}', 'style.css')
js_path = os.path.join('${ASSETS_DIR}', 'report.js')
if os.path.isfile(css_path):
    css = open(css_path, 'r').read()
    html = html.replace('<link rel=\"stylesheet\" href=\"/assets/style.css\">', '<style>' + css + '</style>')
if os.path.isfile(js_path):
    js = open(js_path, 'r').read()
    html = html.replace('<script src=\"/assets/report.js\"></script>', '<script>' + js + '</script>')

print(html)
" > "$OUTPUT_HTML"
    else
        # template.html이 없으면 최소한의 HTML 생성
        /usr/bin/python3 -c "
import sys, json
md_content = open('${MARKDOWN_FILE}', 'r').read()
escaped = json.dumps(md_content)
print(f'''<!DOCTYPE html>
<html><head><meta charset=\"utf-8\"><title>${MARKDOWN_BASENAME}</title>
<script src=\"https://cdn.jsdelivr.net/npm/marked/marked.min.js\"></script>
</head><body>
<div id=\"content\"></div>
<script>
const md = {escaped};
document.getElementById(\"content\").innerHTML = marked.parse(md);
</script></body></html>''')
" > "$OUTPUT_HTML"
    fi
    echo "정적 HTML 생성 완료: $OUTPUT_HTML" >&2
    echo "{\"html_file\": \"${OUTPUT_HTML}\", \"comments_file\": \"${COMMENTS_FILE}\"}"
    exit 0
fi

# --- 포트 결정 (자동 할당) ---
find_available_port() {
    local port="${1:-$DEFAULT_PORT}"
    local attempts=0
    while [[ $attempts -lt $MAX_PORT_ATTEMPTS ]]; do
        if ! lsof -i ":$port" -sTCP:LISTEN >/dev/null 2>&1; then
            echo "$port"
            return 0
        fi
        port=$((port + 1))
        attempts=$((attempts + 1))
    done
    echo "오류: 사용 가능한 포트를 찾을 수 없습니다 (${1:-$DEFAULT_PORT}-$((port - 1)))" >&2
    return 1
}

if [[ -z "$PORT" ]]; then
    PORT=$(find_available_port "$DEFAULT_PORT")
else
    if lsof -i ":$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
        echo "오류: 포트 $PORT 이 이미 사용 중입니다" >&2
        exit 1
    fi
fi

# --- 서버 프로세스 정리를 위한 trap ---
SERVER_PID=""
cleanup() {
    if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# --- server.py 백그라운드 실행 ---
/usr/bin/python3 "$SERVER_PY" \
    --port "$PORT" \
    --markdown "$MARKDOWN_FILE" \
    --assets-dir "$ASSETS_DIR" \
    --script-dir "$SCRIPT_DIR" &
SERVER_PID=$!

# 서버 시작 대기 (최대 3초)
for i in $(seq 1 30); do
    if curl -s -o /dev/null "http://localhost:${PORT}/meta" 2>/dev/null; then
        break
    fi
    sleep 0.1
done

# --- 브라우저 오픈 ---
if [[ "$OPEN_BROWSER" == true ]]; then
    open "http://localhost:${PORT}" 2>/dev/null || true
fi

# --- JSON 출력 ---
echo "{\"url\": \"http://localhost:${PORT}\", \"comments_file\": \"${COMMENTS_FILE}\", \"pid\": ${SERVER_PID}}"

# 서버가 종료될 때까지 대기
wait "$SERVER_PID" 2>/dev/null || true
