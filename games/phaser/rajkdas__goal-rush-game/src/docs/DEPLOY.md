# 🚀 Host GOAL RUSH for free — step-by-step (Render)

This guide takes the game from this workspace to a **public demo URL on Render's
free tier** in about 15–20 minutes. Everything deploy-specific is already wired
into the project:

| What | Where | Why |
|---|---|---|
| Render blueprint | `render.yaml` | Auto-configures the service (build, start, env vars) — near one-click deploy |
| Cloud start script | `npm run start:cloud` | Syncs the SQLite schema → seeds demo scores → boots the Node server |
| Demo leaderboard seed | `scripts/seed-demo.mjs` | The Hall of Fame is never empty on a fresh boot |
| Postinstall hook | `prisma generate` in `package.json` | Prisma client regenerates automatically during `npm install` |
| Node runtime pin | `engines` + `NODE_VERSION` | Next.js 16 needs Node ≥ 20.9 |
| Env example | `.env.example` | Documents `DATABASE_URL` without leaking anything |

**What the free tier gives you (and its honest limits):**

- ✅ $0/month, HTTPS URL (`https://goal-rush-xxxx.onrender.com`), custom domain support, no credit card required.
- 😴 The service **sleeps after 15 minutes** with no visitors. The next visitor waits **~50–60 s** for the cold start (you'll see the Render loading page). After that it's fast.
- 💾 The disk is **ephemeral**: every reboot (deploy, wake-from-sleep, host restart) wipes the SQLite file. `start:cloud` recreates and re-seeds it automatically, so the leaderboard resets to the 6 demo scores on each boot — perfectly fine for a demo, not for real persistence.
- 🧠 Builds run on a small instance (512 MB RAM). This project builds fine, but see Troubleshooting if a build is ever killed.

---

## Step 0 — Prerequisites (2 min)

1. A **GitHub** account → [github.com/signup](https://github.com/signup)
2. A **Render** account (sign in *with GitHub*, no card) → [dashboard.render.com](https://dashboard.render.com)
3. The deployable copy of the code: use **`goal-rush-deploy.zip`** (provided in `download/`). It contains the full project minus build junk, with all the deploy files included.

## Step 1 — Put the code on GitHub (5 min)

Download and unzip `goal-rush-deploy.zip` on your machine, then in a terminal:

```bash
cd goal-rush          # the unzipped folder
git init -b main
git add .
git commit -m "GOAL RUSH — pinball x slots demo"
```

Create an **empty** repository on GitHub: [github.com/new](https://github.com/new) →
name it e.g. `goal-rush` → **do not** add a README/.gitignore/license → Create.

Then push (replace `<you>` with your GitHub username):

```bash
git remote add origin https://github.com/<you>/goal-rush.git
git push -u origin main
```

> If `git push` asks for a password, GitHub wants a **Personal Access Token**,
> not your account password (GitHub → Settings → Developer settings →
> Tokens). Or use GitHub Desktop / VS Code's "Publish to GitHub" button,
> which handles auth for you.

## Step 2 — Create the Render service (2 min)

**Easy path — Blueprint (recommended):**

1. On [dashboard.render.com](https://dashboard.render.com) click **New + → Blueprint**.
2. Pick your `goal-rush` repository → **Connect**.
3. Render detects `render.yaml` and shows the service it will create
   (`goal-rush`, Node runtime, free plan, Singapore region).
4. Click **Apply** — done. All settings below are applied automatically.

**Manual path (if you prefer clicking):** **New + → Web Service** → connect the
repo → set:

| Setting | Value |
|---|---|
| Runtime | **Node** |
| Region | Singapore (or whatever's closest to your audience) |
| Build Command | `npm install && npm run build` |
| Start Command | `npm run start:cloud` |
| Health Check Path | `/api` |
| Instance Type | **Free** |
| Env var `DATABASE_URL` | `file:/tmp/goalrush.db` |
| Env var `NODE_VERSION` | `22.11.0` |
| Env var `NEXT_TELEMETRY_DISABLED` | `1` |

## Step 3 — First deploy (5–10 min)

Watch **Events** / **Logs** in the Render dashboard. A healthy deploy looks like:

1. `==> Cloning from GitHub...`
2. `npm install` — ~2–5 min (Prisma generates its client via the postinstall hook)
3. `next build` — ~1–3 min (Turbopack compiles the game)
4. `==> Starting service...` then from `start:cloud`:
   - `prisma db push` → *The database is already in sync* / *Your database is now in sync*
   - `[seed] inserted 6 demo scores into the Hall of Fame`
   - `✓ Ready in ...` on `http://0.0.0.0:<port>`
5. Status flips to **Live**. Open the URL — the neon title screen should load,
   the Hall of Fame shows the 6 seeded scores, and submitting a score works.

Share `https://goal-rush-xxxx.onrender.com` — it plays on desktop and phones
(touch controls + gamepad supported).

## Step 4 — Keep it warm & polish (optional)

- **Avoid the 60 s cold start for your demo day:** create a free monitor at
  [uptimerobot.com](https://uptimerobot.com) that pings your URL every
  10 minutes (HTTP monitor). A ping every ≤14 min keeps Render from sleeping.
  The leaderboard API `/api/leaderboard` is a perfect ping target.
- **Custom domain:** Render → your service → **Custom Domains** → add
  `play.yourdomain.com` and point a CNAME record at Render. TLS is automatic,
  free tier included.
- **Redeploys are automatic:** every `git push` to `main` rebuilds and ships.

---

## Troubleshooting

| Symptom | Cause & fix |
|---|---|
| Build killed, log shows `Killed` or exit code **137** | Out of memory (free instances have 512 MB). Click **Manual Deploy → Clear build cache & deploy** and retry; if it keeps failing, pause heavy local processes and try off-peak, or upgrade to Starter ($7/mo) which builds with 2 GB. |
| Build error `Node X is not supported` / engine warnings | Set env var `NODE_VERSION=22.11.0` (Blueprint sets it for you). |
| `/api/leaderboard` returns 500 | The SQLite file didn't get created. Check Logs for `prisma db push` output in the start command; confirm `DATABASE_URL` is exactly `file:/tmp/goalrush.db`. |
| First request after idle hangs ~1 min | Normal free-tier cold start. Use UptimeRobot (Step 4) to prevent sleeping. |
| `429 Too many submissions` while testing | The API rate-limits 1 submit / 5 s per IP. Wait 5 s between test submissions. |
| Push rejected by GitHub | You're pushing to a repo that isn't empty or auth failed — see the PAT note in Step 1. |
| `prisma db push` says data loss would occur | Expected on a wiped disk (fresh table); `--accept-data-loss` is already in the script, so this only appears if you run it manually. |

## Alternatives to Render (all free-ish)

| Host | Free offer | Catch |
|---|---|---|
| **Koyeb** | 1 free web service | 512 MB RAM, sleeps too; similar setup (Build `npm run build`, Run `npm run start:cloud`) |
| **Railway** | $5 one-time trial credit (no card) | Great DX, but credit runs out in ~a month of uptime |
| **Vercel** | Best-in-class free hosting for Next.js | The leaderboard needs a serverless DB — swap SQLite for [Turso](https://turso.tech) (free) + Prisma driver adapters; ~1 h of extra work |
| **Fly.io** | Small VMs, pay-as-you-go | Now requires a card; overkill for a demo |

> Why Render is the recommended default: zero-config SQLite, a real always-on
> Node process (no serverless quirks for the Phaser game shell), blueprint file
> already in the repo, and no credit card.

## What actually happens on boot (for the curious)

```
npm run start:cloud
 ├─ prisma db push          # create/repair the Score table in /tmp/goalrush.db
 ├─ node scripts/seed-demo.mjs  # if empty: ZAI 18750 · ACE 14200 · MLS 9875 · KIX 6400 · PIN 4125 · NEO 2380
 └─ node .next/standalone/server.js  # Next.js standalone server, binds $PORT (Render injects it)
```

Local production check (optional, on any machine with the code):

```bash
npm install
npm run build
DATABASE_URL=file:/tmp/goalrush-local.db PORT=3000 npm run start:cloud
```

> One caveat for **Windows** locals: the `build`/`start` scripts use POSIX `cp`
> and `NODE_ENV=` syntax. WSL or Git Bash handles them; native cmd/PowerShell
> won't. On Render (Linux) it's a non-issue.
