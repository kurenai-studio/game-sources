# Deploying Algomind (Render + Neon + Vercel)

> **Status: live.** The API (Render and Neon) and the web app (Vercel) were deployed and checked on 2026-10-18 (details below). The Render deploy hook and the Vercel rebuild hook are configured as GitHub secrets, but the automated deploy path through them has not run yet. Provider UIs change; check each provider's current documentation, and correct this file afterwards.

## Live deployment

| Piece              | Where                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------ |
| Website            | https://playalgomind.vercel.app (placeholder pages: landing, download, a noindex `/admin`) |
| API                | https://algomind-api.onrender.com                                                          |
| API docs (Swagger) | https://algomind-api.onrender.com/docs                                                     |
| API health         | `/v1/health` (liveness) and `/v1/health/ready` (database)                                  |

Checked on 2026-10-18: the API answers liveness and readiness with the database up; the website serves every page; the website's `/admin` page reads `READY` from the live API; `robots.txt` disallows `/admin`.

## Overview

| Piece                | Host                                                                                                                                                                                                                 | Notes                                                                            |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| API (`apps/api`)     | Render web service, built from a Dockerfile                                                                                                                                                                          | One instance while rate limiting is in-process (login, refresh, change-password) |
| Database             | Neon PostgreSQL                                                                                                                                                                                                      | Backups enabled; same region family as the API                                   |
| Web app (`apps/web`) | Vercel                                                                                                                                                                                                               | Public site and `/admin` in one project                                          |
| Game                 | GitHub Releases hold the Android build (APK only, not on Google Play). The browser build is attached to the same releases as `algomind-web-*.tar.gz` and served by the site at `/play` (fetched at site build time). |                                                                                  |

> **Single instance only.** If rate limits live in the API's memory, a second instance would double the limits and split their counters. Move the limiter to a shared store before scaling out.

> **Free tiers sleep.** A free Render service spins down when idle and takes a while to wake. The game must treat that as a delay, not a failure (retry with backoff), and the dashboard should show a loading state. Move to a paid instance before a public launch.

## 1. Database (Neon)

1. Create a project in a region near the Render region.
2. Copy the connection string (`postgresql://…?sslmode=require`).
3. Use the **direct** connection (a host without `-pooler`): migrations run when the container starts, and a connection pooler can interfere with them. If the string ends with `&channel_binding=require`, remove that part and keep `?sslmode=require`; the Node driver may not accept it.
4. Keep it out of git. It becomes `DATABASE_URL` on Render.

## 2. API (Render)

1. Connect the repository and create the service from the blueprint (`render.yaml`) or manually: Docker runtime, Dockerfile in `apps/api`, health check at `/v1/health`.
2. Restrict rebuilds to changes under `apps/api/**` and `packages/**` (the blueprint does this).
3. Set environment variables. Today the API reads:
   - `NODE_ENV=production`
   - `DATABASE_URL` (from Neon; required, there is no default)
   - `CORS_ORIGINS` (the exact web origin, comma-separated for several, no trailing slash: `https://playalgomind.vercel.app`)

   - `JWT_ACCESS_SECRET` (signs access tokens; at least 32 characters; required in production, the blueprint generates it)
   - `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASS` (first run only: the first admin is created when no admin exists; the API refuses to start in production without them while there is no admin, or with a password under 12 characters; the first sign-in forces a new password, after which you can remove both)
   - `WEB_REVALIDATE_URL` and `REVALIDATE_SECRET` (optional; `https://playalgomind.vercel.app/api/revalidate` and a random string of at least 16 characters). After a publish, unpublish, or reorder the API calls this address so the public `/levels` page refreshes at once; without them it still refreshes on its own every minute. Put the same secret in Vercel as `REVALIDATE_SECRET`.
   - `TRUST_PROXY=1` (Render has one reverse proxy; without it every client looks like the proxy and rate limits collapse into one bucket)
   - `CONTACT_NAME`, `CONTACT_EMAIL`, `CONTACT_GITHUB`, `CONTACT_WEBSITE`, `CONTACT_ISSUES` (optional): the contact details the public `/contact` page starts with, used once while no contact row exists. After that the dashboard's Contact page edits them, and these settings are ignored. Without them the page says no address is published until an admin fills it in.
   - `SEED_STARTER_CAMPAIGN` (optional: `true`, `false`, or unset). Unset, production creates the starter campaign (twenty worlds, forty-eight chapters, and one hundred thirteen published levels, plus the daily pool of published levels outside the campaign and the default badges, each level checked by the validator and solver, with a recorded "seed" playtest and a client-registry row) once, while the database has no levels at all, so a fresh install is playable and the public `/levels` page is not empty. `true` adds any missing starter level on every start (use it once to bring an existing database up to a new campaign); `false` never creates them. Seeding only adds, never edits or deletes, and skips anything that exists by slug. Each level goes in its own database transaction, so a slow or far-away database cannot time out one big transaction, and a start that stops half way carries on from the missing levels at the next start. In production the seed runs in the background after the API is listening (checking a hundred levels takes a minute or two on a small instance, and a host that sees no open port for that long fails the deploy), so the levels appear one after another; elsewhere the start waits for it. A seed that stops is logged as an error and the API keeps running. The blueprint does not set it.
   - Optional: `ACCESS_TOKEN_TTL_SECONDS` (default 900) and `REFRESH_TOKEN_TTL_DAYS` (default 7)

   Added when the features land: `WEB_REVALIDATE_URL` with `WEB_REVALIDATE_SECRET` so publish can revalidate public pages.

4. The start command applies migrations (`prisma migrate deploy`) and then starts the server. Do not use `prisma db push` or `migrate dev` in production.
5. Create a deploy hook and an API key for CI (see [CI.md](CI.md)). Consider disabling auto-deploy so the hook is the only path and CD verifies the deploy that runs.

## 3. Web app (Vercel)

1. Import the repository; set the root directory to `apps/web` with the workspace install.
2. Set environment variables: `API_BASE_URL` (server-side, `https://algomind-api.onrender.com/v1`; the only one the site needs today) and, optionally, `SITE_URL` (the public origin used in the sitemap and metadata; it defaults to `https://playalgomind.vercel.app`, so set it only for a custom domain). Optional: `REVALIDATE_SECRET` (the same value as the API's; enables `POST /api/revalidate`).
3. Add a Deploy Hook for `main` and store it as the `VERCEL_DEPLOY_HOOK` secret in GitHub so the site rebuilds after a new release is published (and, later, after a new web export).
4. Confirm `/admin` routes are not indexed and public pages render without JavaScript.

## 4. Smoke test

```sh
BASE=https://algomind-api.onrender.com
curl $BASE/v1/health                      # first call after a sleep can be slow
curl $BASE/v1/health/ready                # {"status":"ok","database":"up"}
# Once those routes exist:
curl $BASE/v1/levels                      # public catalog (published only)
curl -i $BASE/v1/admin/levels             # expect 401 without a token

# The website reads the API server-side; its admin page reports the result:
curl -s https://playalgomind.vercel.app/admin | grep -o 'READY\|UNREACHABLE'
```

Once the dashboard exists: sign in to `/admin`, create a level, validate it, publish it, and confirm it appears in `GET /v1/levels`, on the public catalog page, and in the game.

## 5. Point the game at it

The Android build receives the API URL at build time from the `API_BASE_URL` repository variable. It must be HTTPS and end in `/v1`. A build without a URL should behave as a clean offline game using only bundled levels.

## Operations

- **New migration:** commit and push; CI applies it to a test database, and the start command applies it in production.
- **New app version (a release that adds a mechanic):** `make version v=X.Y.Z`, merge to `main`, and let CI deploy. On start the API registers that version in the client registry with the mechanics it supports (it is not flagged minimum while another minimum exists). Publishing checks each level's mechanics against the **minimum** version, so a new loop level cannot be published until a version that supports `repeat` is the minimum. In the dashboard open Capabilities and choose Make minimum on the new version; that drops support for apps older than it, so do it once those apps have had time to update.
- **Rotate secrets:** change `JWT_ACCESS_SECRET` in Render (access tokens stop working until clients refresh) and rotate the seeded admin password.
- **Backups:** enable and test restoring from Neon backups before publishing real content.
- **Rollback:** redeploy an earlier deploy from Render's events; unpublish a bad level from the dashboard.
- **Logs and health:** use Render logs and the health endpoint; add uptime monitoring for the API and web.
