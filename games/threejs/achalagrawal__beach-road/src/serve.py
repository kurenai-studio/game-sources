"""Local dev server for Beach Road: plain static files with caching turned off,
so edits to the JS modules show up on a normal reload.

    python3 serve.py          # http://localhost:5173
    python3 serve.py 8080     # another port
"""
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def log_message(self, *args):
        pass


port = int(sys.argv[1]) if len(sys.argv) > 1 else 5173
handler = partial(NoCacheHandler, directory=str(Path(__file__).parent))
print(f'Beach Road running at http://localhost:{port}')
ThreadingHTTPServer(('127.0.0.1', port), handler).serve_forever()
