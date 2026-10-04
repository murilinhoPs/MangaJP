#!/usr/bin/env python3
"""Local manga-ocr HTTP sidecar for MangaJP M1.1.

The Flutter default [MangaOcrEngine] POSTs crop PNG/JPEG bytes to `/ocr`.
Weights stay in this process — the app does not embed torch. Flutter web
needs CORS (`Access-Control-Allow-Origin: *`) because Chrome is a different
origin than this sidecar.

Reuse the M0.3 bake-off venv (same kha-white/manga-ocr, 20.75% CER):

  source tools/cer_bakeoff/.venv/bin/activate
  python3 tools/manga_ocr_sidecar/serve.py

Android emulator follow-up (not this PR): `--host 0.0.0.0` and
`MANGA_OCR_URL=http://10.0.2.2:8765`.
"""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ENGINE_ID = "manga_ocr"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8765
MODEL = "kha-white/manga-ocr-base"


def load_recognizer():
    try:
        from manga_ocr import MangaOcr
    except ImportError as exc:
        raise SystemExit(
            "manga-ocr not installed. "
            "source tools/cer_bakeoff/.venv/bin/activate && "
            "pip install -r tools/cer_bakeoff/requirements.txt"
        ) from exc
    return MangaOcr(pretrained_model_name_or_path=MODEL, force_cpu=True)


def make_handler(recognize):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

        def do_OPTIONS(self):
            self.send_response(204)
            self._cors()
            self.end_headers()

        def do_GET(self):
            if self.path.split("?", 1)[0] != "/health":
                self._json(404, {"error": "not found"})
                return
            self._json(200, {"ok": True, "engine_id": ENGINE_ID})

        def do_POST(self):
            if self.path.split("?", 1)[0] != "/ocr":
                self._json(404, {"error": "not found"})
                return
            length = int(self.headers.get("Content-Length", "0") or "0")
            body = self.rfile.read(length)
            if not body:
                self._json(400, {"error": "empty body"})
                return
            suffix = ".png"
            ctype = (self.headers.get("Content-Type") or "").lower()
            if "jpeg" in ctype or "jpg" in ctype:
                suffix = ".jpg"
            with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
                tmp.write(body)
                path = tmp.name
            try:
                text = recognize(path)
            except Exception as exc:  # noqa: BLE001 — surface engine errors as HTTP 500
                self._json(500, {"error": str(exc)})
                return
            finally:
                Path(path).unlink(missing_ok=True)
            self._json(200, {"text": text or "", "engine_id": ENGINE_ID})

        def _cors(self):
            # Flutter web (Chrome) posts from a different origin than this sidecar.
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")

        def _json(self, status, payload):
            raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(raw)))
            self._cors()
            self.end_headers()
            self.wfile.write(raw)

    return Handler


def main(argv=None):
    parser = argparse.ArgumentParser(description="manga-ocr HTTP sidecar for MangaJP")
    parser.add_argument("--host", default=DEFAULT_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--lazy", action="store_true", help="load weights on first /ocr")
    args = parser.parse_args(argv)

    mocr = None
    if not args.lazy:
        print("loading manga-ocr…", file=sys.stderr)
        mocr = load_recognizer()
        print("ready", file=sys.stderr)

    def recognize(path: str) -> str:
        nonlocal mocr
        if mocr is None:
            mocr = load_recognizer()
        return mocr(path)

    server = ThreadingHTTPServer((args.host, args.port), make_handler(recognize))
    print(f"manga-ocr sidecar http://{args.host}:{args.port}", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
