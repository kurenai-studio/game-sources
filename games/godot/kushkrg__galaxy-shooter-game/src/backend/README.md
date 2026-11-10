# Galaxy Shooter — Backend

Accounts, guest play, score submission and the global leaderboard for the
Galaxy Shooter game. **Pure Python 3.10+ standard library** — no pip installs.

## Run

```bash
python server.py                       # http://0.0.0.0:8900
PORT=8080 python server.py             # custom port
GALAXY_SECRET='a-long-random-secret' python server.py   # production secret
GALAXY_DB=/path/to/galaxy.sqlite3 python server.py      # custom DB location
```

The SQLite database is created automatically on first run.

## Test

```bash
python test_backend.py     # 5 end-to-end tests against a real HTTP server
```

## API

| Method | Endpoint | Auth | Body / Notes |
| --- | --- | --- | --- |
| GET | `/api/health` | – | `{"status": "ok"}` |
| POST | `/api/auth/register` | – | `{username, password, display_name?}` → `201 {token, user}`; `409` if the username is taken |
| POST | `/api/auth/login` | – | `{username, password}` → `{token, user}`; `401` on bad credentials |
| POST | `/api/auth/guest` | – | `{display_name}` → guest `{token, user}` (`user.is_guest = true`) |
| GET | `/api/me` | Bearer | Current user |
| POST | `/api/scores` | Bearer | `{score, level}` → `{ok, best}` (the player's personal best) |
| GET | `/api/leaderboard?limit=50` | – | Best score per player, ranked: `{entries: [{rank, name, is_guest, score, level, games}]}` |

## Security notes

- Passwords: PBKDF2-HMAC-SHA256 (120k rounds) with per-user random salts.
- Tokens: JWT-style `header.payload.signature`, HMAC-SHA256 with
  `GALAXY_SECRET`, 30-day expiry. **Always set `GALAXY_SECRET` in production.**
- Serve behind HTTPS in production (any reverse proxy works) — the Godot Web
  export can only call an `https://` API from an `https://` page.
- CORS is open (`*`) so the game can be hosted on any static host.
