# Code Review — Algomind

**Date:** 2026-10-19
**Branch:** `feat/loops-and-world-3` (latest commit `5e396fe`, "feat: add world 3, Loops, with ten levels")
**Reviewer scope:** whole monorepo — `packages/level-contract`, `apps/api`, `apps/web`, `apps/game` (excluding the vendored GUT addon), `packages/design-tokens`, `scripts/`, repo tooling.

## How this review was produced

- Full read of `packages/level-contract/src/*` and the API's auth, levels, catalog, and progress modules.
- Full read of the game's `scripts/` tree and the web app's `src/` tree, with the riskiest claims re-verified line by line in this file (each finding below was confirmed against the actual code; file:line references are real).
- Rule checks: hex colors / `Color(` outside generated files, `level_id ==` special-casing, `localStorage` usage — all clean (details below).

### What was actually run (and what was not)

| Command                                                                          | Result                                                    |
| -------------------------------------------------------------------------------- | --------------------------------------------------------- |
| `make test` (contract 163 tests, API 118 tests incl. the starter-campaign suite) | **all pass**                                              |
| `make lint` (oxlint + prettier)                                                  | **clean, 0 warnings**                                     |
| `make typecheck` (web + api)                                                     | **clean**                                                 |
| `make game-test` / `make check` (needs host Godot)                               | **not run** — GDScript results are from code reading only |

No Godot run, APK build, device test, or browser screenshot was performed for this review.

## Overall assessment

This is a high-quality codebase with unusually strong fundamentals for its size. The three highest-risk areas — the reference simulator/validator/solver, the publish gates, and the auth/session machinery — are the strongest parts. The single rule that defines the project ("one rule set, several implementations") is _enforced, not hoped for_: the GDScript simulator and validator replay every shared fixture with exact trace and issue-set comparison, so a divergence fails CI instead of reaching a player.

No high-severity defects were found. The findings below are two medium robustness/UX bugs and a set of low-severity polish items.

---

## Findings

Severity: **M** = should fix before or shortly after merge, **L** = fix when convenient.

### apps/game

**[M] No single-flight around token refresh can sign the player out** — `scripts/logic/account_client.gd:126-141`
`_fresh_access_token()` refreshes unconditionally when the cached access token is near expiry. Only `AccountSync._running` serializes syncs; a user-driven call (`delete_account`, sign-in flow) racing a background sync can both POST `auth/refresh` with the same refresh token. The server rotates on the first and the second gets 401, which hits `_forget()` (line 139-140) and destroys the _valid, freshly rotated_ session. The player is signed out; local progress survives and re-syncs, but it is reachable in normal use because sync retries on a timer.
_Fix:_ keep a reference to the in-flight refresh inside `AccountClient` and let concurrent callers await the same result (a `_refreshing` flag + queued resumption), then retry once with the new access token.

**[L] Play screen's NEXT button bypasses the unlock check** — `scripts/screens/play.gd:572-575`
`_on_next` navigates to `campaign.next_after(...)` without checking `is_unlocked`, while the world screen gates both its tiles and its Play button. A locked level becomes reachable when a solved level sits after an unsolved one in flattened order (campaign reorder or cross-device merge are both supported), and completing it marks it solved out of order.
_Fix:_ in `_on_next`, check `app.progress.is_unlocked(...)` for the target index and hide/disable NEXT when locked.

**[L] A pending sync request can be silently dropped** — `scripts/logic/account_sync.gd:38-47`
`request()` restarts the debounce timer even while a sync is running; when the timer fires during `_running`, `sync_now` early-returns without re-arming, so the change that requested the sync is not uploaded until the next trigger.
_Fix:_ set a `_pending` flag (or restart the timer) when `sync_now` early-returns, and honor it when the running sync finishes.

**[L] Sync reports "synced" without checking the local write** — `scripts/logic/progress_sync.gd:23-29`
`progress.save()` and `account.save()` return values are ignored; on a disk failure `last_sync_at` still advances and status shows "synced" while the merged state exists only in memory. Non-destructive (the file heals on the next successful save), but the status can lie.
_Fix:_ check both results; on failure return `"failed"` or at least skip stamping `last_sync_at`.

**[L] Destructive fallback in the atomic-save rename path** — `scripts/logic/account.gd:59-61` (also `progress_store.gd:81-83`, `content_store.gd:91-93`)
The pattern "rename fails → remove destination → retry rename" destroys the existing file if the process dies between remove and retry, or if the retry also fails. `ProgressStore` mitigates with the `.bak` copy; `Account` has none, so a double failure loses the refresh token (recoverable by re-login).
_Fix:_ retry onto a fresh temp name without deleting first; if delete-and-retry stays, give `Account` the same `.bak` handling.

**[L] Refresh token stored as plaintext JSON** — `scripts/logic/account.gd:14,49-62`
`user://account.json` holds the long-lived refresh token unencrypted. Acceptable for the current threat model (app-private on Android, and the web build never holds tokens), but worth hardening (keystore plugin or file encryption, documented as obfuscation) before desktop distribution.

**[L] Coroutines can resume after their screen was freed** — `scripts/screens/play.gd:663-718`
The `_run_id` guard correctly blocks stale state changes, but `await get_tree().create_timer(...).timeout` (line 715) is SceneTree-owned: leaving the screen mid-run resumes the coroutine on a freed Control and logs a "resumed after await" error. The `is_inside_tree()` guards in `sign_in.gd:142` and `account.gd:184,223` cannot execute once the instance is gone.
_Fix:_ use a node-owned one-shot `Timer` child (or `create_tween().tween_interval()`) so pending continuations die with the screen.

**[L] Every settings toggle rebuilds the screen and resets scroll** — `scripts/screens/settings.gd:140-146`
`_changed()` re-navigates to `settings`, instantiating a fresh screen. Rebuilding on theme change is necessary; doing it for sound/vibration/run-speed also resets the `ScrollContainer` position.
_Fix:_ rebuild only for theme; update other rows in place.

### apps/api

**[L] Non-null assertions on `par` can 500 the public catalog** — `src/modules/catalog/catalog.service.ts:50,105`
`asPar(version.par)!` assumes every published row carries a parsed par. It is set at publish time, but a row published before that column existed, a hand-migrated database, or a seed regression turns one bad row into a 500 for `/campaign` and `/levels` — the two unauthenticated endpoints every client depends on.
_Fix:_ filter or skip rows whose par fails `asPar`, and log loudly; the publish gate already guarantees par exists for anything newly published.

**[L] Concurrent syncs have no per-user serialization** — `src/modules/me/me.service.ts:32-67`
`sync` runs read-merge-write in a transaction without locking the user's rows, so two concurrent syncs (two devices, or a client retry) can both merge from the same snapshot and the second write silently reverts part of the first. The merge rules make the damage small and self-healing on the next sync, but the idempotency claim is only true per-serialization.
_Fix:_ `SELECT ... FROM "User" WHERE id = $1 FOR UPDATE` at the top of the transaction (same pattern already used in `LevelsService.lock`), or document the serialization assumption.

**[L] In-memory rate limiter is single-instance only** — `src/modules/auth/rate-limiter.ts:7-11`
Correctly documented in code and tracked in `TODO.md` (open items). Listed here so it is visible in one place: move to a shared store before running more than one API instance.

**[L] No security headers on API responses** — `src/app.setup.ts:8-27`
There is no helmet or manual `X-Content-Type-Options`/HSTS. Low impact (JSON API, Swagger docs at `/docs` is the only HTML), but cheap to add, and the docs endpoints inherit it.

**[L] Register rate limit runs after body validation** — `src/modules/auth/auth.controller.ts:49-53`
`parseBody` runs before `this.limit(...)`, so invalid payloads are unthrottled. Noise only (64 kB body cap applies), but swap the order for symmetry with `login`.

Notable things checked and found correct: refresh rotation with family revocation and an atomic claim (`auth.service.ts:96-131`); identical failures for unknown email vs wrong password plus a dummy-hash verify to flatten timing (`auth.service.ts:30-36,88-89`); per-request DB user lookup so password changes take effect immediately (`jwt-auth.guard.ts:14-17`); publish re-evaluating every gate inside the transaction under a `FOR UPDATE` lock (`levels.service.ts:199-204,565-622`); `validate()` storing its summary without moving the draft's `updatedAt` save-token (`levels.service.ts:543-556`); strict payload bounds everywhere (`me.schemas.ts`); ETag + `stale-while-revalidate` on the public catalog (`catalog.controller.ts:18-27`); 64 kB JSON body cap (`app.setup.ts:14`).

### apps/web

**[M] Create world/chapter forms close and clear input even when creation fails** — `src/components/admin/campaign-manager.tsx:88-98,508-515,553-560`
`run()` catches errors and resolves normally, so `onCreate(title).then(() => { setTitle(""); setOpen(false); })` discards the typed title on failure — the error only appears in a page-level notice. The submit buttons never disable, so double-click can create duplicates.
_Fix:_ rethrow from `run()` (or return a boolean); close/clear only on success; add a busy state that disables the button.

**[L] CSRF origin check trusts the client-controllable `x-forwarded-host`** — `src/lib/admin/bff.ts:39-41`
`isSameOrigin` compares `Origin` against `x-forwarded-host ?? host`. Browsers cannot forge that header, so this is not exploitable as CSRF, but any deployment where a proxy passes a client-supplied value through weakens the check to "matches whatever the caller claims".
_Fix:_ compare against an env-derived expected origin, falling back to `host`.

**[L] `Secure` cookie flag depends solely on `NODE_ENV`** — `src/lib/admin/cookie.ts:37-39`
`isSecureCookie()` returns `NODE_ENV === "production"`. A production deployment that doesn't set the env var ships the admin refresh cookie without `Secure`.
_Fix:_ derive from `SITE_URL` starting with `https:` (or an explicit `SECURE_COOKIES` flag), defaulting to true outside local dev.

**[L] No security headers configured** — `next.config.mjs`
No CSP, HSTS, `frame-ancestors`, or `X-Content-Type-Options`. The site loads zero third-party resources (verified), so a strict CSP is cheap and also governs the inline theme script.
_Fix:_ add a `headers()` block; at minimum `nosniff` everywhere and `frame-ancestors 'none'` for `/admin`.

**[L] Proxy re-joins decoded path segments without re-encoding** — `src/lib/admin/bff.ts:~274-294`
`segments.join("/")` uses Next's already-decoded params, so an encoded `?`/`#`/`/` inside a segment changes the upstream path/query structure. The target host is fixed, so this is path confusion on the API, not SSRF (traversal and `auth/*` blocklists still apply).
_Fix:_ `segments.map(encodeURIComponent).join("/")`.

**[L] Session restore retries every 5 s forever during an API outage** — `src/lib/admin/session-manager.ts:213-215`
No backoff or cap: every open admin tab POSTs the refresh endpoint every 5 seconds for the duration of an outage.
_Fix:_ exponential backoff with a cap, or pause until `visibilitychange`.

**[L] Back-button bounce after visiting sign-in with a valid cookie** — `src/components/admin/session-provider.tsx:56-73` + `admin-shell.tsx:45-53`
The `restore: !onSignIn` decision is captured once at mount; an admin who opens `/admin/sign-in` (forced anonymous) then navigates Back gets reloaded to sign-in despite a valid cookie.
_Fix:_ re-run the restore decision when the pathname changes away from sign-in.

**[L] Panel state seeded from props goes silently stale** — `src/components/admin/editor-panels.tsx:616-617,717`
`PreviewPanel` copies `solution` into state on mount, so later edits never appear, and the tried program is lost on every tab switch (remount). `PlaytestPanel`'s commands field keeps its initial hint.
_Fix:_ key the panels on solution identity, or sync via effect.

**[L] N+1 upstream fetches on the public levels page** — `src/lib/campaign.ts:122-130`
`getCampaign` fetches `/levels/:slug` once per published level under `Promise.all` (each revalidated for 60 s). With a few dozen levels this is 30-60 upstream requests per revalidation cycle. Acceptable today; worth a batch endpoint before the catalog grows much.

**[L] Duplication, dead code, a11y, and confirmation consistency**
`TextAction` and `swap`/`move` are duplicated between `campaign-manager.tsx` and `editor-panels.tsx`; `messageOf`/`errorText` are re-implemented in at least six admin files (one shared `components/admin/shared.tsx` would do). `readApiStatus` (`src/lib/api.ts:8-21`) and `authApi` (`src/lib/api/client.ts:43-46`) are exported and never imported — delete. The tool buttons in `editor-panels.tsx:197-212` declare `role="radio"`/`aria-checked` but all four are tab stops and arrow keys do nothing — implement roving tabindex or use `aria-pressed` toggles. Destructive actions are inconsistent: level delete confirms (`levels-list.tsx:127-153`) but world/chapter delete (`campaign-manager.tsx:308-313,352-359`) and raising the minimum client version (which blocks older players, `capabilities.tsx:108-115`) act immediately.

### packages/level-contract

No defects found. Points checked specifically:

- `simulate.ts` — step limit checked before each node and before each primitive inside a loop (lines 145, 156); goal-mid-body success (135-138); wall before boundary ordering; turn wrap `(i+3)%4`; INVALID_INSTRUCTION never skipped; integer-only arithmetic. Matches the documented contract and the GDScript mirror.
- `validate.ts` — never throws on any input (defensive catch at 404-413); unsupported schema version short-circuits (421-435); slot counting treats a malformed node as 1; duplicate/unknown walls still allow later start/goal comparisons.
- `solve.ts` / `solve-repeat.ts` — BFS and the behaviour-table Dijkstra are deterministic per the documented tie-breaking; the FNV-bucketed behaviour dedup compares arrays in full (no hash-collision acceptance); costs saturate at `STEP_CAP = 60000`, far below the `COST_STEPS = 1_000_000` digit boundary, so slots/steps cannot interfere; state space caps at 12×12×4 = 576 so the O(V²) selection is fine.

### packages/design-tokens, scripts, tooling

Clean. `build.mjs` has a `--check` mode wired to `make tokens-check`; token tests exist; `scripts/check-colors.mjs` and the generated-file boundaries held up against grep. The level-lab output files under `scripts/level-lab/out/` are committed artifacts of a design tool — intentional per `TODO.md`, but worth a `.prettierignore`/ownership note if they churn.

### Repository hygiene

**[L] `TODO.md` has drifted from the branch.** Step 3 ("world 3 (Loops)") is listed as not started, but the branch's latest commits add world 3 with ten levels, loops in the editor, dashboard, and publish checks. Several Step-3 boxes and the "How-to-play teaches loops" / "Bump the game version" / "web tests for the publish flow" items are genuinely still open — tick the done ones and carry the rest so the file stays the roadmap it claims to be.

---

## Architecture-rule compliance

| Rule                                                                              | Status                                                                                                                                                                                                              |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| One rule set, several implementations; fixtures pass in both                      | ✅ Enforced by `test_contract_fixtures.gd` replaying every TS fixture with exact trace/issue comparison                                                                                                             |
| Simulation separate from animation/UI; no clock/frame dependence                  | ✅ `PlaySession` precomputes the whole trace in a pure call; `play.gd` only replays events (with a stale-run guard)                                                                                                 |
| Content is data; no `if level_id == ...`                                          | ✅ Grep clean (the first-level coach keys on the campaign `number` field, which is data)                                                                                                                            |
| Published versions immutable; edits create drafts                                 | ✅ `levels.service.ts` state machine (DRAFT/PUBLISHED/SUPERSEDED), delete blocked with history                                                                                                                      |
| Server is the authority                                                           | ✅ Publish re-checks all gates server-side inside one transaction; the web proxy is a pass-through, never an authorizer                                                                                             |
| Auth: short-lived bearer + rotating refresh, tokens never in `localStorage`       | ✅ 900 s access token, rotation + family revocation; web keeps the refresh token in an httpOnly `Path=/admin` cookie and the access token in memory; game keeps it in app-private storage (plaintext — see finding) |
| Colors only from `packages/design-tokens`                                         | ✅ Hex/`Color(` grep hits only `scripts/generated/palette.gd` and `token-colors.generated.ts`                                                                                                                       |
| Local-first progress; only sync uploads; failed sync never touches local data     | ✅ `progress_sync.gd` returns before any request when signed out; merge applied only after a successful server response; tests assert offline/error/malformed responses change nothing locally                      |
| Public site: no tracking, third-party scripts, cookies, runtime third-party fonts | ✅ Verified by the web review; only first-party resources                                                                                                                                                           |

## What the codebase does especially well

1. **Contract parity is tested, not trusted.** Every fixture (valid levels, invalid levels with exact issue sets, runs with full traces, solver cases) executes in both TypeScript and GDScript.
2. **Auth engineering is production-grade on both ends:** rotation with reuse detection, atomic claim on concurrent refresh, dummy-hash timing flattening, per-request role lookup; on the web, single-flight refresh, Web-Lock-serialized cross-tab rotation, fail-closed origin checks, and allowlisted header forwarding.
3. **Storage code is careful:** atomic tmp+rename everywhere, `.bak` rotation plus `.corrupt` quarantine with recovery tests, path-traversal blocking for network-supplied slugs, content validated before replacing a cached copy.
4. **Failure states are first-class** in the game (load errors, notice screens, reduce-motion) and the dashboard (draft conflict UX with `expectedUpdatedAt` + local unsaved-edit backups).
5. **The solver documentation is the code:** both `solve.ts` and `solve-repeat.ts` specify their tie-breaking precisely enough to reimplement, and the GDScript side actually did.

## Suggested priority

1. Game: serialize token refresh (`account_client.gd`) — the only finding that can reach players unprompted.
2. Game: gate NEXT on `is_unlocked` (`play.gd`) and re-arm dropped sync requests (`account_sync.gd`).
3. Web: fix the campaign-manager create forms and add a busy state.
4. Web: add security headers + de-`x-forwarded-host` the origin check (one small PR).
5. API: guard `asPar(...)!` in the catalog; add user-row locking to sync.
6. Repo: reconcile `TODO.md` with the branch before merging to `dev`.

---

## Status (branch `chore/review-fixes-and-standards`)

- **Fixed and tested:** the game's storage, token refresh and sync findings (shared `AtomicFile`, single-flight refresh, no dropped sync requests, save failures reported); the API's catalog, sync and header findings (unusable par rows are skipped and logged, sync takes a per-user row lock, security headers); the web admin's proxy, session and header findings.
- **Refactored under the code standards** (behavior unchanged; see `docs/README_CODE_STANDARDS.md`, section 9): editor panels, campaign manager, level list, level editor, game screen, `levels.service.ts`, `play.gd`. The campaign create and rename forms now close only when the request succeeded, and deleting a world or chapter asks first.
- **Verified:** `make lint`, `make typecheck`, `make test`, `make game-test` (201 tests), `make game-lint`, a web build, an API boot against a local Postgres (all routes mapped, guard returns 401), and 102 debug screenshots identical before and after the `play.gd` split.
- **Not verified:** the per-user row lock in `me.service.ts` against concurrent real requests; the web admin flows in a browser after the refactor; a device.
