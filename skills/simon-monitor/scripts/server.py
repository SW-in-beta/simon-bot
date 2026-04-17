#!/usr/bin/env python3
"""simon-monitor SSE server — events.jsonl을 감시하여 브라우저에 실시간 스트리밍."""

import argparse
import json
import os
import sys
import time
import glob
import uuid
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse, parse_qs

SKILL_DIR = Path(__file__).resolve().parent.parent
DASHBOARD_PATH = SKILL_DIR / "assets" / "dashboard.html"


def find_sessions():
    """모든 세션 디렉토리에서 events.jsonl이 있는 세션 찾기."""
    sessions = []
    patterns = [
        os.path.expanduser("~/.claude/projects/*/sessions/**/events.jsonl"),
    ]
    for pattern in patterns:
        for events_file in glob.glob(pattern, recursive=True):
            session_dir = os.path.dirname(events_file)  # session root (events.jsonl 위치)
            stat = os.stat(events_file)
            # 세션 정보 추출
            parts = Path(events_file).parts
            try:
                proj_idx = parts.index("projects") + 1
                sess_idx = parts.index("sessions") + 1
                project = parts[proj_idx]
                session = parts[sess_idx]
            except (ValueError, IndexError):
                project = "unknown"
                session = os.path.basename(session_dir)

            # 첫 이벤트에서 스킬 정보 읽기
            skill = "unknown"
            task = ""
            try:
                with open(events_file) as f:
                    first_line = f.readline().strip()
                    if first_line:
                        first_event = json.loads(first_line)
                        if first_event.get("type") == "workflow_start":
                            skill = first_event.get("data", {}).get("skill", "unknown")
                            task = first_event.get("data", {}).get("task", "")
            except (json.JSONDecodeError, OSError):
                pass

            sessions.append({
                "path": session_dir,
                "project": project,
                "session": session,
                "skill": skill,
                "task": task,
                "modified": stat.st_mtime,
                "size": stat.st_size,
            })

    sessions.sort(key=lambda s: s["modified"], reverse=True)
    return sessions


class StateWatcher:
    """workflow-state.json을 감시하여 합성 이벤트를 생성하는 클래스."""

    def __init__(self, session_dir):
        self.session_dir = session_dir
        self.state_file = os.path.join(session_dir, "memory", "workflow-state.json")
        self._last_mtime = None
        self._last_state = None

    def _load_state(self):
        try:
            with open(self.state_file) as f:
                return json.load(f)
        except (OSError, json.JSONDecodeError):
            return None

    def _get_covered_steps(self, events_file):
        """events.jsonl에서 이미 커버된 step ID 집합을 반환."""
        covered = set()
        if not os.path.exists(events_file):
            return covered
        try:
            with open(events_file) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        event = json.loads(line)
                        step = event.get("step")
                        if step:
                            covered.add(step)
                    except json.JSONDecodeError:
                        continue
        except OSError:
            pass
        return covered

    def _make_event(self, skill, step, event_type, title, extra_data=None):
        data = {"source": "state-watch"}
        if extra_data:
            data.update(extra_data)
        now = time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime())
        return {
            "id": str(uuid.uuid4()),
            "timestamp": now,
            "skill": skill,
            "step": step,
            "type": event_type,
            "title": title,
            "data": data,
        }

    def poll(self, events_file):
        """상태 파일을 폴링하고 새 합성 이벤트 목록을 반환. 이벤트 없으면 빈 리스트."""
        if not os.path.exists(self.state_file):
            return []

        try:
            current_mtime = os.stat(self.state_file).st_mtime
        except OSError:
            return []

        if current_mtime == self._last_mtime:
            return []

        new_state = self._load_state()
        if new_state is None:
            return []

        old_state = self._last_state
        self._last_mtime = current_mtime
        self._last_state = new_state

        if old_state is None:
            # 최초 로드 — 이벤트 생성 없이 기준선만 기록
            return []

        skill = new_state.get("skill", "unknown")
        step_results = new_state.get("step_results", {})
        covered = self._get_covered_steps(events_file)
        events = []

        old_completed = set(old_state.get("completed_steps", []))
        new_completed = set(new_state.get("completed_steps", []))
        for step_id in sorted(new_completed - old_completed):
            step_key = step_id
            if step_key in covered:
                continue
            result = step_results.get(step_id, {})
            extra = {}
            if result.get("status"):
                extra["status"] = result["status"]
            if result.get("verdict"):
                extra["verdict"] = result["verdict"]
            if result.get("artifacts"):
                extra["artifacts"] = result["artifacts"]
            events.append(self._make_event(
                skill, step_key, "step_complete",
                f"Step {step_id} completed", extra
            ))

        old_current = old_state.get("current_step")
        new_current = new_state.get("current_step")
        if new_current and new_current != old_current:
            step_key = new_current
            if step_key not in covered:
                events.append(self._make_event(
                    skill, step_key, "step_start",
                    f"Step {new_current} started"
                ))

        old_skipped = set(old_state.get("skipped_steps", []))
        new_skipped = set(new_state.get("skipped_steps", []))
        for step_id in sorted(new_skipped - old_skipped):
            step_key = step_id
            if step_key in covered:
                continue
            events.append(self._make_event(
                skill, step_key, "step_skip",
                f"Step {step_id} skipped"
            ))

        return events


class MonitorHandler(BaseHTTPRequestHandler):
    """HTTP 요청 핸들러."""

    def log_message(self, format, *args):
        """로그 출력 억제 (SSE 폴링이 로그를 도배하므로)."""
        pass

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        params = parse_qs(parsed.query)

        if path == "/":
            self._serve_dashboard()
        elif path == "/api/events/stream":
            self._stream_events()
        elif path == "/api/events/history":
            self._serve_event_history()
        elif path == "/api/sessions":
            self._serve_sessions()
        elif path == "/api/session-info":
            self._serve_session_info()
        else:
            self.send_error(404)

    def _serve_dashboard(self):
        """dashboard.html 서빙."""
        try:
            with open(DASHBOARD_PATH, "rb") as f:
                content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", len(content))
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(500, "dashboard.html not found")

    def _stream_events(self):
        """SSE 스트림 — events.jsonl 감시 + 실시간 전송."""
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        session_dir = self.server.session_dir
        events_file = os.path.join(session_dir, "events.jsonl")
        state_watcher = self.server.state_watcher
        last_pos = 0

        try:
            while True:
                if os.path.exists(events_file):
                    with open(events_file) as f:
                        f.seek(last_pos)
                        new_lines = f.readlines()
                        if new_lines:
                            for line in new_lines:
                                line = line.strip()
                                if line:
                                    try:
                                        json.loads(line)  # validate
                                        self.wfile.write(f"data: {line}\n\n".encode())
                                    except json.JSONDecodeError:
                                        continue
                            self.wfile.flush()
                            last_pos = f.tell()

                # state-watch 합성 이벤트 확인
                synthetic_events = state_watcher.poll(events_file)
                if synthetic_events:
                    try:
                        with open(events_file, "a") as f:
                            for event in synthetic_events:
                                line = json.dumps(event, ensure_ascii=False)
                                f.write(line + "\n")
                                self.wfile.write(f"data: {line}\n\n".encode())
                        self.wfile.flush()
                        last_pos = os.path.getsize(events_file)
                    except (OSError, BrokenPipeError):
                        pass

                # heartbeat (keep connection alive)
                try:
                    self.wfile.write(b": heartbeat\n\n")
                    self.wfile.flush()
                except BrokenPipeError:
                    break

                time.sleep(0.5)

        except (BrokenPipeError, ConnectionResetError):
            pass

    def _serve_event_history(self):
        """모든 기존 이벤트를 JSON 배열로 반환."""
        session_dir = self.server.session_dir
        events_file = os.path.join(session_dir, "events.jsonl")
        events = []

        if os.path.exists(events_file):
            with open(events_file) as f:
                for line in f:
                    line = line.strip()
                    if line:
                        try:
                            events.append(json.loads(line))
                        except json.JSONDecodeError:
                            continue

        content = json.dumps(events, ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", len(content))
        self.end_headers()
        self.wfile.write(content)

    def _serve_sessions(self):
        """사용 가능한 세션 목록 반환."""
        sessions = find_sessions()
        content = json.dumps(sessions, ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", len(content))
        self.end_headers()
        self.wfile.write(content)

    def _serve_session_info(self):
        """현재 모니터링 중인 세션 정보."""
        info = {
            "session_dir": self.server.session_dir,
            "events_file_exists": os.path.exists(
                os.path.join(self.server.session_dir, "events.jsonl")
            ),
        }
        content = json.dumps(info, ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", len(content))
        self.end_headers()
        self.wfile.write(content)


def main():
    parser = argparse.ArgumentParser(description="simon-monitor dashboard server")
    parser.add_argument("--session", help="Session directory to monitor")
    parser.add_argument("--port", type=int, default=3847, help="Server port (default: 3847)")
    parser.add_argument("--list-sessions", action="store_true", help="List available sessions and exit")
    args = parser.parse_args()

    if args.list_sessions:
        sessions = find_sessions()
        if not sessions:
            print("모니터링 가능한 세션이 없습니다.")
            return

        print(f"{'#':<3} {'스킬':<14} {'세션':<30} {'작업':<30}")
        print("-" * 80)
        for i, s in enumerate(sessions):
            print(f"{i+1:<3} {s['skill']:<14} {s['session']:<30} {s['task'][:30]:<30}")
            print(f"    {s['path']}")
        return

    if not args.session:
        # 가장 최근 세션 자동 선택
        sessions = find_sessions()
        if sessions:
            args.session = sessions[0]["path"]
            print(f"자동 선택: {args.session}")
        else:
            print("Error: --session 필요 (또는 기존 세션이 있어야 합니다)", file=sys.stderr)
            sys.exit(1)

    # 세션 디렉토리 존재 확인 (없으면 생성)
    os.makedirs(args.session, exist_ok=True)

    server = HTTPServer(("127.0.0.1", args.port), MonitorHandler)
    server.session_dir = args.session
    server.state_watcher = StateWatcher(args.session)

    print(f"simon-monitor 시작: http://localhost:{args.port}")
    print(f"세션: {args.session}")
    print("Ctrl+C로 종료")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n종료")
        server.server_close()


if __name__ == "__main__":
    main()
