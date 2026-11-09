#!/usr/bin/env python3
# Sirve youtube/ en http://localhost:8080 con la misma Content-Security-Policy que pone
# YouTube Playables (copiada de su guía de la Test Suite), así lo que falle por la CSP
# falla aquí también. Uso: bash herramientas/youtube.sh && python3 herramientas/youtube-servir.py
import functools
import http.server
import pathlib

CSP = (
    "default-src 'none'; "
    "script-src 'report-sample' 'self' 'unsafe-eval' 'unsafe-inline' blob: "
    "https://www.youtube.com/game_api/v0 https://www.youtube.com/game_api/v0/ "
    "https://www.youtube.com/game_api/v1 https://www.youtube.com/game_api/v1/; "
    "object-src 'none'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
    "img-src 'self' blob: data:; media-src 'self' blob:; "
    "font-src 'self' data: https://fonts.googleapis.com https://fonts.gstatic.com; "
    "connect-src 'self' blob: data:; "
    "sandbox allow-pointer-lock allow-same-origin allow-scripts; "
    "base-uri 'self'; manifest-src 'self'; worker-src 'self' blob:"
)
CARPETA = pathlib.Path(__file__).resolve().parent.parent / "youtube"


class ConCSP(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm"}

    def end_headers(self):
        self.send_header("Content-Security-Policy", CSP)
        # la Test Suite abre el juego dentro de su página: que no quede nada en caché entre pruebas
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()


if not (CARPETA / "index.html").exists():
    raise SystemExit("Falta youtube/: corre antes bash herramientas/youtube.sh")
print("Sirviendo youtube/ en http://localhost:8080  (Ctrl+C para parar)")
http.server.ThreadingHTTPServer(("127.0.0.1", 8080), functools.partial(ConCSP, directory=str(CARPETA))).serve_forever()
