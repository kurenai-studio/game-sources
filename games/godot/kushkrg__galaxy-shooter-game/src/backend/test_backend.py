"""Tests for the Galaxy Shooter backend. Run: python -m unittest -v
Uses a throwaway SQLite DB and a real HTTP server on an ephemeral port."""
import json, os, sys, tempfile, threading, unittest, urllib.request, urllib.error
from pathlib import Path

os.environ["GALAXY_DB"] = str(Path(tempfile.mkdtemp()) / "test.sqlite3")
os.environ["GALAXY_SECRET"] = "test-secret"
sys.path.insert(0, str(Path(__file__).parent))
import server  # noqa: E402


def call(method, path, body=None, token=None):
    req = urllib.request.Request(BASE + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Content-Type": "application/json",
                                          **({"Authorization": "Bearer " + token} if token else {})})
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


class BackendTests(unittest.TestCase):
    def test_health(self):
        status, data = call("GET", "/api/health")
        self.assertEqual(status, 200); self.assertEqual(data["status"], "ok")

    def test_register_login_and_score_flow(self):
        status, data = call("POST", "/api/auth/register", {"username": "pilot1", "password": "secret1", "display_name": "Pilot One"})
        self.assertEqual(status, 201); token = data["token"]
        status, data = call("POST", "/api/auth/register", {"username": "pilot1", "password": "secret1"})
        self.assertEqual(status, 409)
        status, data = call("POST", "/api/auth/login", {"username": "pilot1", "password": "wrong"})
        self.assertEqual(status, 401)
        status, data = call("POST", "/api/auth/login", {"username": "pilot1", "password": "secret1"})
        self.assertEqual(status, 200)
        status, data = call("POST", "/api/scores", {"score": 5000, "level": 3}, token)
        self.assertEqual(status, 200); self.assertEqual(data["best"], 5000)
        status, data = call("POST", "/api/scores", {"score": 3000, "level": 2}, token)
        self.assertEqual(data["best"], 5000)

    def test_guest_and_leaderboard_order(self):
        _, g = call("POST", "/api/auth/guest", {"display_name": "Guest Ace"})
        self.assertTrue(g["user"]["is_guest"])
        call("POST", "/api/scores", {"score": 9000, "level": 5}, g["token"])
        _, r = call("POST", "/api/auth/register", {"username": "pilot2", "password": "secret2"})
        call("POST", "/api/scores", {"score": 7000, "level": 4}, r["token"])
        status, data = call("GET", "/api/leaderboard?limit=10")
        names = [e["name"] for e in data["entries"]]
        self.assertEqual(names[0], "Guest Ace")
        self.assertEqual(data["entries"][0]["score"], 9000)
        self.assertLess(names.index("Guest Ace"), names.index("pilot2"))

    def test_score_requires_auth(self):
        status, _ = call("POST", "/api/scores", {"score": 1, "level": 1})
        self.assertEqual(status, 401)
        status, _ = call("POST", "/api/scores", {"score": 1, "level": 1}, "bad.token.here")
        self.assertEqual(status, 401)

    def test_validation(self):
        status, _ = call("POST", "/api/auth/register", {"username": "ab", "password": "secret1"})
        self.assertEqual(status, 400)
        status, _ = call("POST", "/api/auth/register", {"username": "validname", "password": "123"})
        self.assertEqual(status, 400)


if __name__ == "__main__":
    server.init_db()
    httpd = server.ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
    BASE = f"http://127.0.0.1:{httpd.server_address[1]}"
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    unittest.main(argv=[sys.argv[0], "-v"])
