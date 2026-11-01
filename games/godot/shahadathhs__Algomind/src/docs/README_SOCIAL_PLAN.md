# Algomind — Points, Leaderboards, Daily Challenge, Sharing, and Player Management

> **Purpose:** Plan the features that make Algomind a complete game beyond the campaign: verified points, leaderboards, a daily challenge, sharing, and the dashboard tools to run them.  
> **Status:** built: verified submissions and points, player management, a player-chosen display name and profile, leaderboards (with reports and admin moderation), the daily challenge with its pool, sharing, achievements, level statistics, and stars on level tiles (see section 6). Not built: friend groups, season snapshots with badge rewards, and the Android system share sheet. Decisions in section 1 were made on 2026-10-19. The rules these features rely on are in [README_GAME_RULES.md](README_GAME_RULES.md).

## 1. Decisions

| #   | Decision                                                                                                                                                                                                                                                                                                                                              |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Leaderboards, a daily challenge, and sharing leave the "not included" list. Accounts are required for them and everything is opt-in. Real-time multiplayer and player-versus-player stay out. Community levels stay out.                                                                                                                              |
| 2   | Points are score, never currency: no shop, no spending, no purchases. Per-level points come from matching par, with a smaller bonus for fewer steps.                                                                                                                                                                                                  |
| 3   | A player appears on a leaderboard only after opting in with a display name. An anonymous mode is available. The email is never shown to other players.                                                                                                                                                                                                |
| 4   | A "day" is a UTC day, for the daily challenge and its streaks.                                                                                                                                                                                                                                                                                        |
| 5   | Sharing is a spoiler-free text result card plus a link page. No image upload and no sharing of levels.                                                                                                                                                                                                                                                |
| 6   | Order of work: finish the `REPEAT` editor UI and the reworked level curriculum first, then phases 1 and 2 below. Points and a daily challenge are only worth building on good levels.                                                                                                                                                                 |
| 7   | No social media integration of any kind: no third-party sign-in, no SDKs or platform APIs, no share buttons that load outside code. Sharing uses the phone's own share menu (Android) or the browser's share option or a copied link (web), and a link to Algomind's own page. "Social" in this plan means in-game features on Algomind's own server. |

## 2. Rules these features must keep

- **Local-first.** Signed-out play uploads nothing. Sync stays the only code allowed to upload progress, and a failed sync never touches local data.
- **The server is the authority.** A score is never trusted: the client submits the _program_, and the server validates it with `validateProgram` and re-runs it with the reference simulator. Par is computed once per level version at publish time, never per submission.
- **No tracking, no third-party scripts, no cookies** on the public site. Statistics for the author come from submissions, not from analytics.
- **Versioned scoring.** A result is stored against the level _version_ and the points rule version that scored it. Results from different level versions are never compared.
- **Privacy.** The privacy page is updated in the same change that ships any of this, in plain terms: what an opted-in profile stores, who can see it, and how to delete it.
- **House style.** Color only from the design tokens; every state has a shape or label; no gradients, glow, or shadows; no motivational copy or exclamation marks.
- **Both themes.** Every new screen, page, and preview image (points and result, profile, leaderboards, daily challenge, sharing, and the dashboard pages) works in light and dark, using only the generated token colors. Rewards are cosmetic and never colors: badges, titles, and ranks. Unlockable color themes are out, because the house style has one palette and one accent.

## 3. Pillars

### 3.1 Verified submissions and points

**Submission.** `POST /v1/me/submissions` takes `{ levelSlug, levelVersion, program }` and is idempotent on the program hash. The server checks that the level version is published, runs `validateProgram` and `simulate`, and stores the verified slots and steps. A failed program is not a submission.

**Formula (versioned, edited in the dashboard).** Per level: a base by difficulty; a bonus for matching par (full) or coming within a few slots (partial); a smaller bonus for fewer steps; more for the first clear. Stars (1 to 3) come from the same result. A rule change creates a new rule-set version and never rewrites history.

**Ledger.** `PointsLedger(user, reason, delta, levelSlug, levelVersion, ruleVersion, createdAt)` is append-only. Totals are derived. The client shows a provisional score offline and reconciles to the server's total at sync.

**Ranks and badges.** Ranks come from total points. Achievements are data-driven from the dashboard (for example first loop level, seven-day streak, par on ten levels). Rewards are cosmetic: badges and titles.

### 3.2 Daily challenge

- `DailyChallenge(dateUtc, levelVersionId, ruleSetVersion)`: one fixed puzzle per UTC day, unlimited attempts, best result counts.
- The level comes from a separate **daily pool**, not the campaign, so players do not meet it early. The pool needs many good levels; this is why the curriculum comes first.
- The dashboard has a calendar scheduler. A daily goes through the same publish gate as a level (valid, solved, par checked, playtested). A fallback rotation from the pool means no day is ever empty.
- **Streaks:** consecutive UTC days, with one grace day per week.
- **Offline:** the client caches the next few days. A result is submitted at the next sync.

### 3.3 Leaderboards

- **Boards:** global all-time points; weekly and monthly seasons; per level (fewest slots, then fewest steps); per daily challenge; optional friend groups by invite code.
- **Ranking:** verified results only; ties broken by the earliest verified time; a player sees their own rank and the entries around it, with pagination.
- **Seasons** close and archive with a snapshot; rewards are badges.
- **Performance:** per-period rollup tables updated when points are awarded, not recomputed per request. The API runs as one instance with an in-memory rate limiter, so a shared limiter is a prerequisite before scaling out.
- **Safety:** opt-in, display name only, anonymous mode. The admin can hide, rename, or ban an entry. Reports go to a moderation queue. A block list refuses obvious names.

### 3.4 Sharing

- **Result card:** plain text such as "Algomind Daily, 2026-10-19: 7 slots, par 5". No emoji, no solution, no board.
- **Link page:** `/s/<short code>` on the public site, server-rendered with a preview image through the existing Open Graph pipeline. It leads to Download or Play. The code is random and carries no personal data.
- **Out of scope:** sharing levels, and any in-app messaging.

### 3.5 Dashboard extensions

| Area               | Feature                                                                                                                                                              |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Players**        | List (search, filter by status, sort by last active, points, levels cleared) and detail (account, progress, points history, sessions, settings, sync status).        |
| **Player actions** | Revoke sessions, reset progress, clear or set a display name, suspend and unsuspend, delete the account, export one player's data. Each is written to the audit log. |
| **Points rules**   | Versioned rule sets with a preview of what a rule would have awarded.                                                                                                |
| **Achievements**   | Create and edit badges and their conditions.                                                                                                                         |
| **Daily**          | Calendar scheduler, pool management, fallback rotation, publish gate.                                                                                                |
| **Leaderboards**   | Season control, hide, rename, ban, snapshot archive, moderation queue.                                                                                               |
| **Level stats**    | Per level: completion rate, average slots against par, where players stop. Aggregates only, no individual tracking.                                                  |

## 4. Data and API

**New tables:** `Submission`, `PointsLedger`, `PointsRuleSet`, `Achievement`, `PlayerAchievement`, `DailyChallenge`, `StreakState`, `LeaderboardPeriod`, `LeaderboardEntry`, `ShareLink`, `Report`. `User` gains a status, a last-active time, and a display name.

**Player API:** `POST /v1/me/submissions`, `GET /v1/me/points`, `GET /v1/daily`, `GET /v1/leaderboards/...`, `PUT /v1/me/profile`, `POST /v1/share`.

**Admin API:** `/v1/admin/players`, `/points-rules`, `/achievements`, `/daily`, `/leaderboards/moderation`, `/reports`.

Every endpoint is server-authoritative, rate limited, and audited. Tokens never go in `localStorage`.

## 5. Phases

| Phase | Delivers                                                                                                        | Depends on                       |
| ----- | --------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| 0     | `REPEAT` editor UI, dashboard and publish gates for loops, reworked level curriculum, database reset and reseed | the contract work (done)         |
| 1     | Verified submissions, the points ledger with a versioned formula, stars, and the result screen                  | phase 0                          |
| 2     | Player management in the dashboard                                                                              | independent; can run alongside 1 |
| 3     | Leaderboards (global, per level, seasons), opt-in profile, moderation                                           | phase 1                          |
| 4     | Daily challenge: scheduler, pool, streaks, daily board                                                          | phase 1 and a large level pool   |
| 5     | Sharing: result cards, link pages, preview images                                                               | phases 3 and 4                   |
| 6     | Achievements, profile screen, level statistics, polish                                                          | the rest                         |

Each phase ends in something playable, tested, and documented, and meets the "definition of done" in [README_IMPLEMENTATION_PLAN.md](README_IMPLEMENTATION_PLAN.md), with screenshots in both themes at the three phone sizes (and the web pages with JavaScript disabled).

## 6. What is built

**Verified points and player management** (phases 1 and 2)

- **Scoring** lives in `packages/level-contract` (`scoring.ts`) with a GDScript mirror (`scripts/contract/scoring.gd`); both pass the fixtures in `fixtures/scoring`. Rule set 1: a base by difficulty (10, 20, 30), 10 for par slots or fewer, 5 for within two slots of par, 5 for par steps, 10 for the first clear; stars are 3 at par, 2 within two slots, otherwise 1. A rule change is a new version made in the dashboard (Points) and applies to results from then on.
- **Submissions** (`POST /v1/me/submissions`): the server validates the program for the exact level version, runs it, and scores it. A level's points only go up, by the amount a better result adds, and the same program is never awarded twice, even from two devices at once. The ledger is append-only (a database trigger refuses updates).
- **The game** keeps the best program per level in `PlayerResults` and sends it only through the sync (`ProgressSync` stays the only uploader); signed out, nothing is sent.
- **Player management** (dashboard, Players): list, detail, and the audited actions. Suspending refuses sign-in and every live token at once. Resetting progress takes points back with ledger entries and does not touch the player's device.

**Profile, leaderboards, daily challenge, sharing, badges, statistics** (phases 3 to 6)

- **Profile** (`GET`, `PUT /v1/me/profile`; game screen Profile): a display name (3 to 20 characters, unique ignoring case, checked against a short block list and impersonating words), the choice to appear on leaderboards (off until chosen), a hidden-name mode that shows "Anonymous", and a rank from total points (Novice to Master; titles only). Opting in needs a name or hidden-name mode.
- **Leaderboards** (`GET /v1/leaderboards/points|levels/:slug|daily/:date`; game screen Leaderboard): points all time, this week (Monday start) and this month, all in UTC; a level's board and a day's board rank by fewest slots, then fewest steps, then earliest, on the current published version only. Only opted-in, active, un-hidden players appear. A signed-in caller also gets their own place with the rows around it. Players report a name (`POST /v1/leaderboards/report`); the dashboard Reports page lets an admin dismiss, clear the name, or hide the player, and the Players page can hide or show anyone. Weekly and monthly boards are computed from the append-only ledger, so no snapshot is stored.
- **Daily challenge** (`GET /v1/daily`, `GET /v1/me/daily`; game screen Daily): one level per UTC day. An admin schedules a day in the dashboard (Daily); a day with no schedule falls back to a deterministic rotation over the daily pool that never repeats within a cycle. The pool is 19 published levels with no chapter (11 plain, 8 needing a loop), outside the campaign, so players meet one only on its day; a campaign level cannot join the pool and a pool level cannot be placed in a chapter. A solve claims the day with `dailyDate` (today or up to seven days back, for a late sync). Streaks count consecutive days and forgive one missed day in any seven. The game caches today and the next three days, so the daily is playable offline, and the result goes up through the sync.
- **Sharing** (`POST /v1/me/share`, `GET /v1/share/:code`; the solved screen's Share and the public page `/s/<code>`): a share link is a random code with a verified result and no name, email, or account id. The page shows the level's board, the result in words, one Play in the browser button and a Download link, works with JavaScript off, and has a share image. The game copies the result card to the clipboard (with the link when signed in and online).
- **Badges** (`GET /v1/me/achievements`; game screen Badges; dashboard Badges): 12 default badges with rules as data (levels solved, stars, par levels, points, streak, daily solves, one named level). The server awards them after each verified result and never takes one back; the dashboard edits, adds, and switches them off.
- **Level statistics** (dashboard, Statistics): per published level, the solvers, the average slots, results at par and within two slots, and the drop-off from the previous level, from verified results only.
- **Stars on level tiles**: the world screen draws 1 to 3 stars on a solved level, from the server's answer when a sync has reported it, otherwise from the best local result against the bundled par.
- **Privacy**: deleting an account removes its results, badges, share links, and the reports made by or about it; the admin data export includes them; the privacy page describes what an opted-in profile stores and who sees it.
- **Not built:** friend groups by invite code; season snapshots and badge rewards for season winners; the Android system share sheet (it needs a plugin; Share copies text); and the browser build has none of these screens (it is offline-only by design).

## 7. Risks

- **Scope.** Phases 1 and 2 together make a coherent release; the rest can follow.
- **Fairness.** Par changes when a level's content changes, so every score is keyed to a level version.
- **Moderation.** Display names are the main attack surface. Mitigation: opt-in, anonymous mode, admin rename and ban, a block list.
- **Cost and scale.** One instance with an in-memory limiter. Rollup tables keep reads cheap; move the limiter to a shared store before scaling out.
- **Content.** A daily challenge needs a deep pool of good levels. Until the curriculum exists, phase 4 would run out.
