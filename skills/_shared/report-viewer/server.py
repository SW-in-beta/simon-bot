"""
server.py — 마크다운 보고서 로컬 HTTP 서버

Python 표준 라이브러리만 사용. 마크다운 파일을 브라우저에서 열람하고
인라인 코멘트를 JSON으로 저장/조회하는 API를 제공한다.

엔드포인트:
  GET  /           — template.html에 마크다운을 삽입한 HTML 서빙
  GET  /assets/*   — CSS, JS, vendor 파일 서빙
  POST /comments   — 코멘트 JSON 저장
  GET  /comments   — 저장된 코멘트 조회
  GET  /meta       — 보고서 메타데이터
"""

import argparse
import json
import mimetypes
import os
import sys
from datetime import datetime, timezone
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import unquote

# MIME 타입 보강
mimetypes.add_type("text/css", ".css")
mimetypes.add_type("application/javascript", ".js")
mimetypes.add_type("application/json", ".json")
mimetypes.add_type("image/svg+xml", ".svg")
mimetypes.add_type("font/woff2", ".woff2")
mimetypes.add_type("font/woff", ".woff")


def parse_args():
    parser = argparse.ArgumentParser(description="Report Viewer 로컬 서버")
    parser.add_argument("--port", type=int, required=True, help="서버 포트")
    parser.add_argument("--markdown", type=str, required=True, help="마크다운 파일 절대 경로")
    parser.add_argument("--assets-dir", type=str, required=True, help="assets 디렉토리 경로")
    parser.add_argument("--script-dir", type=str, required=True, help="스크립트 루트 디렉토리 경로")
    return parser.parse_args()


class ReportHandler(BaseHTTPRequestHandler):
    markdown_path: str = ""
    assets_dir: str = ""
    script_dir: str = ""
    comments_path: str = ""
    report_title: str = ""

    def log_message(self, format, *args):
        pass

    def _set_headers(self, status=200, content_type="text/html; charset=utf-8", extra_headers=None):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, v)
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(204)

    def do_GET(self):
        path = unquote(self.path)

        if path == "/" or path == "":
            self._serve_index()
        elif path.startswith("/assets/"):
            self._serve_asset(path)
        elif path == "/comments":
            self._serve_comments()
        elif path == "/meta":
            self._serve_meta()
        elif path == "/markdown-raw":
            self._serve_markdown_raw()
        else:
            self._set_headers(404, "text/plain; charset=utf-8")
            self.wfile.write(b"404 Not Found")

    def do_POST(self):
        path = unquote(self.path)

        if path == "/comments":
            self._save_comments()
        elif path == "/save-markdown":
            self._save_markdown()
        else:
            self._set_headers(404, "text/plain; charset=utf-8")
            self.wfile.write(b"404 Not Found")

    def _serve_index(self):
        template_path = os.path.join(self.script_dir, "template.html")

        try:
            markdown_content = self._read_file(self.markdown_path)
        except FileNotFoundError:
            self._set_headers(500, "text/plain; charset=utf-8")
            self.wfile.write(f"마크다운 파일을 찾을 수 없습니다: {self.markdown_path}".encode("utf-8"))
            return

        markdown_json = json.dumps(markdown_content, ensure_ascii=False)

        if os.path.isfile(template_path):
            try:
                template = self._read_file(template_path)
                html = template.replace("{{MARKDOWN_CONTENT_JSON}}", markdown_json)
                html = html.replace("{{MARKDOWN_PATH}}", self.markdown_path)
                html = html.replace("{{REPORT_TITLE}}", self.report_title)
                html = html.replace("{{SERVER_MODE}}", "true")
            except Exception as e:
                self._set_headers(500, "text/plain; charset=utf-8")
                self.wfile.write(f"template.html 처리 오류: {e}".encode("utf-8"))
                return
        else:
            html = self._generate_fallback_html(markdown_json)

        self._set_headers(200, "text/html; charset=utf-8")
        self.wfile.write(html.encode("utf-8"))

    def _generate_fallback_html(self, markdown_json):
        return f"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{self.report_title}</title>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
         max-width: 900px; margin: 0 auto; padding: 2rem; line-height: 1.6; color: #1a1a1a; }}
  pre {{ background: #f5f5f5; padding: 1rem; border-radius: 6px; overflow-x: auto; }}
  code {{ font-family: "SF Mono", "Fira Code", monospace; font-size: 0.9em; }}
  h1, h2, h3 {{ border-bottom: 1px solid #eee; padding-bottom: 0.3em; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ border: 1px solid #ddd; padding: 8px 12px; text-align: left; }}
  th {{ background: #f8f8f8; }}
</style>
</head>
<body>
<div id="content"></div>
<script>
const md = {markdown_json};
document.getElementById("content").innerHTML = marked.parse(md);
</script>
</body>
</html>"""

    def _serve_asset(self, path):
        relative = path.lstrip("/")  # "assets/style.css"
        file_path = os.path.join(self.script_dir, relative)
        file_path = os.path.normpath(file_path)

        # 경로 탈출 방지
        if not file_path.startswith(os.path.normpath(self.script_dir)):
            self._set_headers(403, "text/plain; charset=utf-8")
            self.wfile.write(b"403 Forbidden")
            return

        if not os.path.isfile(file_path):
            self._set_headers(404, "text/plain; charset=utf-8")
            self.wfile.write(f"404 파일 없음: {relative}".encode("utf-8"))
            return

        mime_type, _ = mimetypes.guess_type(file_path)
        if mime_type is None:
            mime_type = "application/octet-stream"

        try:
            with open(file_path, "rb") as f:
                data = f.read()
            self._set_headers(200, mime_type)
            self.wfile.write(data)
        except Exception as e:
            self._set_headers(500, "text/plain; charset=utf-8")
            self.wfile.write(f"파일 읽기 오류: {e}".encode("utf-8"))

    def _serve_comments(self):
        if os.path.isfile(self.comments_path):
            try:
                data = self._read_file(self.comments_path)
                self._set_headers(200, "application/json; charset=utf-8")
                self.wfile.write(data.encode("utf-8"))
            except Exception as e:
                self._set_headers(500, "application/json; charset=utf-8")
                self.wfile.write(json.dumps({"error": str(e)}).encode("utf-8"))
        else:
            # 코멘트 파일이 없으면 빈 구조 반환
            empty = json.dumps({
                "report": self.markdown_path,
                "comments": []
            }, ensure_ascii=False, indent=2)
            self._set_headers(200, "application/json; charset=utf-8")
            self.wfile.write(empty.encode("utf-8"))

    def _save_comments(self):
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode("utf-8"))
        except (json.JSONDecodeError, ValueError) as e:
            self._set_headers(400, "application/json; charset=utf-8")
            self.wfile.write(json.dumps({"error": f"잘못된 JSON: {e}"}).encode("utf-8"))
            return

        try:
            with open(self.comments_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

            self._set_headers(200, "application/json; charset=utf-8")
            self.wfile.write(json.dumps({
                "status": "saved",
                "path": self.comments_path,
                "count": len(data.get("comments", []))
            }, ensure_ascii=False).encode("utf-8"))
        except Exception as e:
            self._set_headers(500, "application/json; charset=utf-8")
            self.wfile.write(json.dumps({"error": f"저장 실패: {e}"}).encode("utf-8"))

    def _serve_meta(self):
        generated_at = datetime.now(timezone.utc).astimezone().isoformat()
        meta = {
            "markdown_path": self.markdown_path,
            "title": self.report_title,
            "generated_at": generated_at,
            "comments_file": self.comments_path,
        }
        self._set_headers(200, "application/json; charset=utf-8")
        self.wfile.write(json.dumps(meta, ensure_ascii=False, indent=2).encode("utf-8"))

    def _save_markdown(self):
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode("utf-8"))
            markdown = data.get("markdown", "")
        except (json.JSONDecodeError, ValueError) as e:
            self._set_headers(400, "application/json; charset=utf-8")
            self.wfile.write(json.dumps({"error": f"잘못된 요청: {e}"}).encode("utf-8"))
            return

        try:
            with open(self.markdown_path, "w", encoding="utf-8") as f:
                f.write(markdown)
            self._set_headers(200, "application/json; charset=utf-8")
            self.wfile.write(json.dumps({
                "status": "saved",
                "path": self.markdown_path
            }, ensure_ascii=False).encode("utf-8"))
        except Exception as e:
            self._set_headers(500, "application/json; charset=utf-8")
            self.wfile.write(json.dumps({"error": f"저장 실패: {e}"}).encode("utf-8"))

    def _serve_markdown_raw(self):
        try:
            content = self._read_file(self.markdown_path)
            self._set_headers(200, "text/plain; charset=utf-8")
            self.wfile.write(content.encode("utf-8"))
        except FileNotFoundError:
            self._set_headers(404, "text/plain; charset=utf-8")
            self.wfile.write(b"404 Markdown file not found")

    @staticmethod
    def _read_file(path):
        with open(path, "r", encoding="utf-8") as f:
            return f.read()


def main():
    args = parse_args()

    markdown_path = os.path.abspath(args.markdown)
    if not os.path.isfile(markdown_path):
        print(f"오류: 마크다운 파일을 찾을 수 없습니다: {markdown_path}", file=sys.stderr)
        sys.exit(1)

    markdown_dir = os.path.dirname(markdown_path)
    markdown_basename = os.path.splitext(os.path.basename(markdown_path))[0]
    comments_path = os.path.join(markdown_dir, f"{markdown_basename}-comments.json")
    report_title = markdown_basename

    # 핸들러 클래스에 설정 주입
    ReportHandler.markdown_path = markdown_path
    ReportHandler.assets_dir = os.path.abspath(args.assets_dir)
    ReportHandler.script_dir = os.path.abspath(args.script_dir)
    ReportHandler.comments_path = comments_path
    ReportHandler.report_title = report_title

    server = HTTPServer(("127.0.0.1", args.port), ReportHandler)
    print(f"서버 시작: http://localhost:{args.port}", file=sys.stderr)
    print(f"마크다운: {markdown_path}", file=sys.stderr)
    print(f"코멘트: {comments_path}", file=sys.stderr)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        print("\n서버 종료", file=sys.stderr)


if __name__ == "__main__":
    main()
