# Algomind — Implementation Plan

> **Working rule:** Build the full architecture first, thinly, then grow the content. The contract, API, dashboard, game loader, and CI/CD exist before the catalog does. Levels are added one at a time from the dashboard afterwards. Do not build every future feature before you have a fun puzzle.

## 1. Delivery strategy

Implement in vertical slices. Each phase should leave the repository runnable, green in CI, and demonstrable. The schedule is intentionally omitted; finish each phase's acceptance criteria before moving on.

### Recommended order

1. Lock the core rules and set up the repository, tooling, and CI so quality is enforced from the first commit.
2. Define the level contract: schema, shared validator, reference simulator, and fixtures.
3. Build the API and versioned level storage.
4. Build the admin dashboard so levels can be authored and published.
5. Build the game: simulation, remote and cached level loading, and the player UI.
6. Connect everything end to end and build the public website.
7. Author the starter campaign from the dashboard, polish, and playtest.
8. Deploy and release.

The architecture is complete after step 6 with only a handful of test levels. The catalog then grows through the dashboard without code changes.

## Phase 0 — Product rules, repository, and tooling

### Tasks

- Confirm the core mechanic.
- Define the initial command set and exact movement/collision rules.
- Define win, failure, reset, and step-limit behavior.
- Sketch the first few levels on paper.
- Create the repository with `apps/api`, `apps/web`, `apps/game`, `packages/level-contract`, and `packages/design-tokens`.
- Set up the pnpm workspace, `Makefile` (single command surface), `.env.example`, and `VERSION`.
- Configure Husky, lint-staged, commitlint, and commitizen with cz-git; configure prettier and the chosen linters.
- Add GitHub Actions with the quality gates for every app (even while the apps are skeletons), Dependabot, and issue and PR templates.
- Create the design token source (light and dark) with generators for the Godot palette and web CSS, and a CI drift check.
- Write the anti-slop visual rules from [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md) into AGENTS.md, so every contributor and AI tool follows them.
- Choose and bundle the font (open license) for both the game and the web app.
- Add AGENTS.md, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md, LICENSE, a root README, and the CI and deployment docs.
- Adopt the branching model: work on `dev`, pull request into `main`.

### Deliverables

- One-page rules document or a completed gameplay section.
- A repository where `make lint`, `make test`, and CI pass on empty skeletons.
- At least three hand-designed level sketches illustrating tutorial, basic obstacle, and a slightly more challenging combination.

### Exit criteria

- Two people could read the rules and agree on what happens for the same command sequence.
- A commit that breaks lint, types, tests, or the commit-message format is rejected locally and in CI.
- No online account, leaderboard, or public-site dependency is needed to test the concept.

## Phase 1 — Level contract and reference simulator

### Tasks

- Define `schemaVersion` and the first JSON Schema.
- Implement the TypeScript validator, the reference simulator, and the solver (shortest program for the initial command set) in `packages/level-contract`.
- Create valid and invalid level fixtures, and programs with expected outcomes and step traces.
- Define the `requires.mechanics` capability model and the reference-solution format.
- Implement the equivalent validator and simulator in GDScript inside a minimal Godot project, and run every fixture there with GUT.
- The TypeScript package is consumed from its built `dist/`, so CI and Docker builds must build it before any dependent type check, test, or build.

### Deliverables

- Documented schema and fixtures.
- **Status:** the TypeScript contract (126 tests) and the GDScript validator and simulator (every `levels` and `runs` fixture) are done and pass the same fixtures. Solver fixtures are TypeScript-only. Remaining: wiring the contract into the API, the dashboard, and the game's level loading.
- The same fixture suite passing in TypeScript and in GDScript.

### Exit criteria

- Repeated identical runs produce identical outcomes in both implementations.
- Adding a fixture requires adding data, not changing code.
- A disagreement between the two simulators fails CI.

**Do not add commands or mechanics until the first command set creates satisfying puzzles.**

## Phase 2 — NestJS API and database

### Tasks

- Initialize the NestJS service with typed configuration and OpenAPI docs.
- Connect PostgreSQL with Prisma; commit migrations; ignore the generated client.
- Implement `AdminUser`, `Level`, and `LevelVersion`, and a seed for the first admin.
- Implement health/readiness checks.
- Implement admin authentication with hashed passwords, token rotation, rate limiting, and server-side authorization.
- Implement worlds, chapters, and campaign ordering; the public `/v1/campaign` tree; and the admin seed on startup.
- Implement draft CRUD, validate (including solvability, solver par, and compatibility), playtest records with content hashes, publish with all gates, unpublish, version history, restore, duplicate, import and export, the capabilities registry, and the audit log.
- Implement public `GET /v1/levels` and `GET /v1/levels/:slug`, never exposing drafts or reference solutions.
- Ensure publication is transactional and published versions are immutable.
- Add structured error responses, request validation, and structured logs.
- Add the Dockerfile and a Docker Compose service for local PostgreSQL.

### Deliverables

- API can store drafts, publish a level version, list published levels, and retrieve a selected published version.
- Migrations apply from a clean database.
- Automated tests cover publishing behavior and authorization (Vitest, no database); public/private access and the database constraints are checked against a real PostgreSQL in CI and by hand.
- **Status:** implemented except automated tests and the web revalidation call after publish. Auth, worlds and chapters, ordering, drafts and versions, validate, the publish gates, unpublish, restore, duplicate, import and export, playtests, the client registry, the audit log, and the public catalog exist (route list in [README_ARCHITECTURE.md](README_ARCHITECTURE.md), section 7.1). Behavior was checked by hand against a real PostgreSQL (clean migration, every gate failing alone, the public catalog, round trips, DB constraints), not by an automated suite.

### Exit criteria

- Public clients cannot retrieve drafts or reference solutions.
- Unauthenticated users cannot mutate content.
- Invalid or unsolvable content cannot be published.
- Editing/publishing a level creates a new version rather than rewriting the previous published version.

## Phase 3 — Admin dashboard (in `apps/web`)

Build a modest editor that helps create valid content. Do not build a general-purpose game engine inside the browser.

### Tasks

- Set up `apps/web` with the `(public)` and `(admin)` route groups and shared UI tokens.
- Create sign-in and protected `/admin` routes; mark admin routes `noindex`.
- Build the screens listed in [README_DASHBOARD_PLAN.md](README_DASHBOARD_PLAN.md): level list, editor tabs, publish review with diff, version history, campaign structure, capabilities, import, audit log, and settings.
- Create the level list with thumbnail, placement, status, difficulty, playtest state, and updated timestamp.
- Build create/edit forms for level metadata.
- Build a board editor for placing start, goal, walls, and any mechanic already supported by the contract.
- Add command availability, constraints, goal, hint, and reference-solution controls.
- Add draft save and server validation display with field-level errors.
- Add a live preview that runs the reference simulator, including stepping through the reference solution.
- Add a publish confirmation that displays the version to be published, and unpublish confirmation and version history.
- Handle unsaved changes, save status, and API errors.

### Deliverables

- An administrator can author, validate, preview, and publish a level without hand-editing JSON.
- Validation errors point to the problem and suggest a correction.

### Exit criteria

- Save draft and publish are separate actions.
- The API, not only the browser, enforces validation and permissions.
- Published content can be identified and traced to an immutable version.
- Preview results match the fixture expectations.

## Phase 4 — Game client

**Status: every planned screen, the download path, and optional accounts with sync are built.** Done: Menu, Worlds (solved, current, locked, and not-downloaded states) and World, the gameplay screen (ready, running, paused, failed, solved) with the board renderer, automaton, and tape editor, the first-run coach on level 1, Hint, Pause, How to play, Settings (sound, music, vibration, reduce motion, run speed, theme), Load error, and Update required; sound and music generated in code, vibration, and run speed (never above 0.25 s a step); a bundled 9-level campaign loaded from data through the validator; hints on the starter levels; local progress in a versioned, atomically written save with backup recovery; the networked half: the API base URL from the `algomind/network/api_base_url` project setting (CI fills it; `ALGOMIND_API_BASE_URL` overrides it in debug builds), the public catalog and each level fetched from `/v1/campaign` and `/v1/levels/:slug` (public routes only), every level checked by the validator before it is stored, a cache on the device keyed by slug and level version that a bad response can never replace, offline and unreadable-response states with Retry, levels needing a newer game shown as Update required, and the served par on the result. Sign in and Account (phase 8) are built too. Not done: any run on a device or as an APK. The game only follows its own reduce-motion setting because Godot cannot read the phone's. Verified on a desktop with host Godot only; 169 GUT tests.

### Tasks

- Build the gameplay screen first, fully, in both themes and every state (ready, running, failed, solved), before the other screens; add a debug-only screenshot path to the Godot build.
- Create the Godot main scene, board renderer, automaton representation, and tape-based command editor.
- Wire the simulation (from Phase 1) to the UI through signals; keep logic independent of animation.
- Implement Run, Step, Reset, success, failure, and step-limit handling.
- Configure the API base URL by environment/build configuration.
- Fetch the public catalog and a level's current published version; validate it with the client validator.
- Add loading, no-network, not-found, unsupported-schema, unsupported-mechanic, and retry states.
- Cache downloaded levels by ID and version; never replace a valid cache with an invalid response.
- Bundle a small set of starter levels so first launch works offline.
- Store local progress in a versioned, interruption-safe save format: completions keyed by stable level ID, best metrics with the level version they came from, last played level, and settings.
- Add basic temporary UI and test at phone-sized viewports.

### Deliverables

- A complete playable flow from app launch to success/retry using levels published from the dashboard.
- GUT tests for simulation, validation, caching, and loading.

### Exit criteria

- UI animation cannot change the simulation result.
- Invalid or unsupported remote content fails visibly without crashing.
- The game does not call admin routes.
- Controls are usable without a mouse.

## Phase 5 — End-to-end flow and public website

### Tasks

- Build the launch pages of the public site in `apps/web` per [README_WEB_PLAN.md](README_WEB_PLAN.md): landing, download (GitHub Releases data, QR code, install steps), how to play, privacy, contact. The level catalog and `/play` (web export) come after launch.
- Add on-demand revalidation after publish and unpublish.
- Add sitemap and `robots.ts` that exclude `/admin`.
- Run the end-to-end workflow: dashboard → API → database → game and public site.
- Add smoke tests for sign-in and the publish flow.

### Deliverables

- A newly published, compatible level becomes available in the game and on the public site without a rebuild of the app or the API.

### Exit criteria

- Publish version 1, play it, publish version 2, and confirm the client can fetch version 2 without an app release.
- Offline behavior is predictable and a bad response cannot corrupt cached data.
- Unpublishing removes the level from new catalog results but does not falsely claim to erase previously cached copies.
- Public pages work without JavaScript, apart from the user-started game.

## Phase 6 — Starter campaign, quality, and design polish

### Tasks

- Author the starter levels one at a time in the dashboard, each solved with a reference solution and playtested.
- Apply the visual design guide to the game, public site, and dashboard, in both themes.
- Capture every screen in [design/SCREENS.md](design/SCREENS.md) at 390×844, 360×640, and 412×915 in both themes, and fix what the visual checklist flags.
- Test on at least one real Android device plus different viewport sizes.
- Tune board scale, command controls, spacing, typography, and animation duration.
- Add audio/motion settings if they are in the MVP.
- Improve onboarding and level-specific hints.
- Playtest each level with someone who did not design it.
- Remove unnecessary menus and options.
- Test keyboard navigation and focus states in the dashboard.

### Deliverables

- A curated starter campaign, coherent game visuals, a usable dashboard, and a polished public site.

### Exit criteria

- Every published starter level has been solved in a clean playtest.
- Players can identify the goal, understand commands, and recover from failure.
- Critical buttons and fields have loading/error/disabled states.

## Phase 7 — Deployment and release

### Tasks

- Create separate environment configuration for local, staging (if used), and production.
- Deploy the API (Render), database (Neon) with backups, and web (Vercel).
- Configure HTTPS, CORS, allowed origins, logging, and health checks.
- Add the CD jobs: wait-for-live API deploy, web rebuild hook, Android build, and rolling and versioned releases.
- Configure the Android signing key and secrets as documented in [CI.md](CI.md).
- Remove secrets from repository history if any were accidentally committed; rotate affected credentials.
- Seed a few published levels and create the admin account.
- Add screenshots, a short gameplay recording, an architecture diagram, and the project README.
- Document setup, migrations, tests, deployment, known limitations, and decisions.

### Deliverables

- A working deployed system and reproducible developer setup.
- A versioned release with an Android build, produced by `make release v=X.Y.Z`.

### Exit criteria

- Another developer can follow the setup instructions on a clean checkout.
- Production does not rely on local files or development credentials.
- The deployed Vercel and Render URLs are recorded in the docs and injected into the builds.
- The project clearly distinguishes working features from planned features.

## Phase 8 — Optional accounts and cloud sync (after the core release)

**Status: built.** API: registration, `/v1/me/progress` with the merge, `/v1/me/settings`, and account deletion, with tests for the merge rules and authorization (see [README_ARCHITECTURE.md](README_ARCHITECTURE.md) section 7.2). Game: Sign in and Account screens, a sync that is the only code allowed to upload progress (signed out it makes no request at all, a failed sync never touches local data), a rotating refresh token kept in the app's private storage, retry with growing waits, and account deletion that asks for the password. Not run on a device yet.

### Tasks

- Add player registration (`PLAYER` role) using the existing auth system, with the same bearer, refresh, and auto-logout behavior.
- Add `LevelProgress` and `PlayerSettings` tables and the `/v1/me/*` endpoints with an idempotent server-side merge.
- Add sign-in, sign-out, and account deletion to the game, and a background `Sync` component that is the only code allowed to upload progress.
- Sync after sign-in, after a level completion, on app start, and when connectivity returns; retry with backoff.
- Keep signed-out play fully offline for progress.

### Deliverables

- A player can sign in on a second device and receive merged progress.

### Exit criteria

- Merge follows the documented policy (union, recalculated unlocks, better metrics, newest settings).
- A failed or interrupted sync never removes or corrupts local progress.
- Repeating a sync does not change the result.
- Signed-out play makes no progress uploads.
- Account deletion removes server-side progress.

## 2. Release gates

### Foundation gate

Do not start feature work in an app until its lint, type check, test, and build gates run in CI.

### Contract gate

Do not build the dashboard, API validation, or game loader until the schema and the shared fixture suite are stable enough to version and pass in both implementations.

### Content gate

Do not author a large catalog until the end-to-end flow (author, publish, fetch, play) works. Add levels one at a time after that.

### Prototype gate

Do not expand the command set or mechanics until several authored levels have been played and the core mechanic feels worth expanding.

### Online gate

Do not build player accounts or cloud progress sync until remote level delivery and caching work reliably. The save format and data model are sync-ready earlier, so this gate adds a feature, not a migration.

### Leaderboard gate

Do not expose competitive scores until the score formula, level-version policy, and server-side verification model are designed. Client-sent scores alone are not trustworthy.

## 3. Testing checklist by risk

### Gameplay correctness

- Empty program and maximum-length program.
- Turn without movement and movement at each board boundary.
- Wall collision.
- Repeated reset/run cycles.
- Program ends before the goal.
- Instruction or step safety limit.
- Invalid start and goal positions.
- Unsupported command or goal type.
- Every contract fixture in both TypeScript and GDScript.

### Content workflow

- Save a valid draft.
- Save invalid data and see actionable errors.
- Attempt to publish invalid or unsolvable data through a direct API request.
- Publish, edit, and republish a level.
- Confirm previous published versions remain unchanged.
- Unpublish and verify public catalog behavior.
- Confirm unauthorized requests are rejected.
- Confirm the public API never returns reference solutions.

### Network and caching

- Slow network.
- API unavailable on first launch.
- API unavailable after level download.
- Timeout and retry.
- Malformed JSON.
- Unsupported `schemaVersion` or required mechanic.
- A new published version with the same level ID.
- A level removed from the public catalog but still present in local cache.

### UI and device behavior

- Small and large phone viewports.
- Touch targets and one-handed use.
- Text wrapping and longer title text.
- App pause/resume during a simulation.
- Sound muted and reduced-motion behavior.
- Dashboard keyboard navigation and unsaved changes.
- Public pages with JavaScript disabled.

## 4. Suggested issue labels

- `gameplay`: game rules, simulation, player loop.
- `content`: level data, schema, tutorial level design.
- `web`: public site and admin dashboard (Next.js).
- `api`: NestJS routes and business rules.
- `database`: schema and migrations.
- `design`: visuals, sound, interaction.
- `quality`: tests, accessibility, errors, performance, tooling.
- `deployment`: hosting, CI/CD, environment configuration, operations.
- `later`: explicitly out of MVP scope.

## 5. Avoid scope traps

Do not implement all of these just to make the architecture look sophisticated: microservices, Kubernetes, Redis, queues, WebSockets, multiplayer, social profiles, daily challenges, analytics pipelines, advanced role management, cloud saves, and leaderboards. Build the contract, the dashboard-managed publishing flow, and a good player experience first.

## 6. Definition of done for an MVP feature

A feature is done when:

- Its expected behavior and failure states are defined.
- Its implementation matches this documentation or the docs are updated to match the final decision.
- Relevant logic has automated tests.
- It passes lint, formatting, type checks, and the full CI pipeline.
- Loading, empty, error, and unauthorized states are handled where applicable.
- It works in the target viewport/device.
- It contains no committed secrets or debug-only bypasses.
- It can be explained clearly in the project README.
