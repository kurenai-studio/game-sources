#!/usr/bin/env python3
"""Galaxy Shooter online backend — accounts, guest play, global leaderboard.

Pure Python 3.10+ standard library (http.server + sqlite3). No pip installs.

Run:
    python server.py                    # http://127.0.0.1:8900
    PORT=8900 SECRET=change-me python server.py

API:
    GET  /api/health                      -> {"status": "ok"}
    POST /api/auth/register {username, password}          -> {token, user}
    POST /api/auth/login    {username, password}          -> {token, user}
    POST /api/auth/guest    {display_name}                -> {token, user}
    GET  /api/me            (Bearer token)                -> {user}
    POST /api/scores        (Bearer token) {score, level} -> {ok, best}
    GET  /api/leaderboard?limit=50                        -> {entries: [...]}

Passwords are stored as PBKDF2-HMAC-SHA256 hashes with per-user salts.
Tokens are HMAC-signed (header.payload.signature, JWT-style) and expire
after 30 days. CORS is open so the Godot Web export can call the API.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import sqlite3
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

DB_PATH = Path(os.environ.get("GALAXY_DB", Path(__file__).with_name("galaxy.sqlite3")))
SECRET = os.environ.get("GALAXY_SECRET", "dev-secret-change-in-production")
TOKEN_TTL = 30 * 24 * 3600
PBKDF2_ROUNDS = 120_000


# --------------------------------------------------------------------------
# database
# --------------------------------------------------------------------------
def db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with db() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                display_name TEXT NOT NULL,
                password_hash TEXT,               -- NULL for guest accounts
                salt TEXT,
                is_guest INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL
            );
            CREATE TABLE IF NOT EXISTS scores (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL REFERENCES users(id),
                score INTEGER NOT NULL,
                level INTEGER NOT NULL,
                created_at INTEGER NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_scores_score ON scores(score DESC);
            """
        )


# --------------------------------------------------------------------------
# auth helpers
# --------------------------------------------------------------------------
def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _unb64(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def make_token(user_id: int) -> str:
    header = _b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    payload = _b64(json.dumps({"sub": user_id, "exp": int(time.time()) + TOKEN_TTL}).encode())
    sig = _b64(hmac.new(SECRET.encode(), f"{header}.{payload}".encode(), hashlib.sha256).digest())
    return f"{header}.{payload}.{sig}"


def verify_token(token: str) -> int | None:
    try:
        header, payload, sig = token.split(".")
        expected = _b64(hmac.new(SECRET.encode(), f"{header}.{payload}".encode(), hashlib.sha256).digest())
        if not hmac.compare_digest(sig, expected):
            return None
        data = json.loads(_unb64(payload))
        if int(data["exp"]) < int(time.time()):
            return None
        return int(data["sub"])
    except Exception:
        return None


def hash_password(password: str, salt: bytes) -> str:
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, PBKDF2_ROUNDS).hex()


def public_user(row: sqlite3.Row) -> dict:
    return {"id": row["id"], "username": row["username"],
            "display_name": row["display_name"], "is_guest": bool(row["is_guest"])}


# --------------------------------------------------------------------------
# HTTP handler
# --------------------------------------------------------------------------
class Handler(BaseHTTPRequestHandler):
    server_version = "GalaxyShooterBackend/1.0"

    # -- plumbing ------------------------------------------------------
    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def _json(self, payload: dict, status: int = 200) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _body(self) -> dict:
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 64 * 1024:
                return {}
            return json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception:
            return {}

    def _auth_user(self) -> sqlite3.Row | None:
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return None
        user_id = verify_token(auth[7:].strip())
        if user_id is None:
            return None
        with db() as conn:
            return conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()

    def do_OPTIONS(self) -> None:  # CORS preflight (Godot Web export)
        self.send_response(204)
        self._cors()
        self.end_headers()

    # -- routes --------------------------------------------------------
    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/health":
            self._json({"status": "ok", "game": "galaxy-shooter"})
        elif parsed.path == "/api/me":
            user = self._auth_user()
            if user is None:
                self._json({"error": "Unauthorized"}, 401)
            else:
                self._json({"user": public_user(user)})
        elif parsed.path == "/api/leaderboard":
            self._leaderboard(parsed)
        else:
            self._json({"error": "Not found"}, 404)

    def do_POST(self) -> None:
        route = urlparse(self.path).path
        if route == "/api/auth/register":
            self._register()
        elif route == "/api/auth/login":
            self._login()
        elif route == "/api/auth/guest":
            self._guest()
        elif route == "/api/scores":
            self._submit_score()
        else:
            self._json({"error": "Not found"}, 404)

    # -- endpoints -----------------------------------------------------
    def _register(self) -> None:
        body = self._body()
        username = str(body.get("username", "")).strip().lower()
        password = str(body.get("password", ""))
        display = str(body.get("display_name", "")).strip() or username
        if len(username) < 3 or not username.replace("_", "").isalnum():
            self._json({"error": "Username must be 3+ characters (letters, numbers, _)."}, 400)
            return
        if len(password) < 6:
            self._json({"error": "Password must be at least 6 characters."}, 400)
            return
        salt = os.urandom(16)
        try:
            with db() as conn:
                cur = conn.execute(
                    "INSERT INTO users (username, display_name, password_hash, salt, is_guest, created_at)"
                    " VALUES (?, ?, ?, ?, 0, ?)",
                    (username, display[:30], hash_password(password, salt), salt.hex(), int(time.time())),
                )
                user_id = cur.lastrowid
        except sqlite3.IntegrityError:
            self._json({"error": "That username is already taken."}, 409)
            return
        with db() as conn:
            row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        self._json({"token": make_token(user_id), "user": public_user(row)}, 201)

    def _login(self) -> None:
        body = self._body()
        username = str(body.get("username", "")).strip().lower()
        password = str(body.get("password", ""))
        with db() as conn:
            row = conn.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
        if row is None or row["password_hash"] is None:
            self._json({"error": "Invalid username or password."}, 401)
            return
        candidate = hash_password(password, bytes.fromhex(row["salt"]))
        if not hmac.compare_digest(candidate, row["password_hash"]):
            self._json({"error": "Invalid username or password."}, 401)
            return
        self._json({"token": make_token(row["id"]), "user": public_user(row)})

    def _guest(self) -> None:
        body = self._body()
        display = str(body.get("display_name", "")).strip()[:30] or "Guest Pilot"
        suffix = _b64(os.urandom(6)).lower()
        username = f"guest_{suffix}"
        with db() as conn:
            cur = conn.execute(
                "INSERT INTO users (username, display_name, password_hash, salt, is_guest, created_at)"
                " VALUES (?, ?, NULL, NULL, 1, ?)",
                (username, display, int(time.time())),
            )
            user_id = cur.lastrowid
            row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        self._json({"token": make_token(user_id), "user": public_user(row)}, 201)

    def _submit_score(self) -> None:
        user = self._auth_user()
        if user is None:
            self._json({"error": "Unauthorized — log in or play as guest first."}, 401)
            return
        body = self._body()
        try:
            score = max(0, min(int(body.get("score", 0)), 100_000_000))
            level = max(1, min(int(body.get("level", 1)), 10_000))
        except (TypeError, ValueError):
            self._json({"error": "score and level must be numbers."}, 400)
            return
        with db() as conn:
            conn.execute(
                "INSERT INTO scores (user_id, score, level, created_at) VALUES (?, ?, ?, ?)",
                (user["id"], score, level, int(time.time())),
            )
            best = conn.execute(
                "SELECT MAX(score) AS best FROM scores WHERE user_id = ?", (user["id"],)
            ).fetchone()["best"]
        self._json({"ok": True, "best": best})

    def _leaderboard(self, parsed) -> None:
        try:
            limit = max(1, min(int(parse_qs(parsed.query).get("limit", ["50"])[0]), 200))
        except ValueError:
            limit = 50
        with db() as conn:
            rows = conn.execute(
                """
                SELECT u.display_name AS name, u.is_guest AS guest,
                       MAX(s.score) AS score, MAX(s.level) AS level,
                       COUNT(s.id) AS games
                FROM scores s JOIN users u ON u.id = s.user_id
                GROUP BY s.user_id
                ORDER BY score DESC
                LIMIT ?
                """,
                (limit,),
            ).fetchall()
        entries = [
            {"rank": i + 1, "name": r["name"], "is_guest": bool(r["guest"]),
             "score": r["score"], "level": r["level"], "games": r["games"]}
            for i, r in enumerate(rows)
        ]
        self._json({"entries": entries})

    def log_message(self, format: str, *args) -> None:
        pass


def main() -> None:
    init_db()
    port = int(os.environ.get("PORT", "8900"))
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print(f"Galaxy Shooter backend running at http://0.0.0.0:{port}")
    print("Endpoints: /api/health /api/auth/* /api/scores /api/leaderboard")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
