# Algomind — Project Overview

> **Status:** Product specification / working plan  
> **Project type:** Mobile-first logic puzzle game with a dashboard-managed level catalog and a public website  
> **Title:** Algomind

## 1. Product summary

Algomind is a compact, grid-based logic puzzle game built around a tiny automaton. The player studies a board, plans a short sequence of actions, runs the simulation, and adjusts the plan until the automaton reaches the goal.

The game is intentionally designed around **small, handcrafted puzzles that teach one idea at a time**. A puzzle should feel understandable at first glance and satisfying to solve, while later levels combine familiar rules in less obvious ways.

Rules are defined in [README_GAME_RULES.md](README_GAME_RULES.md).

Levels are **managed from an admin dashboard from day one**. The dashboard is the only place levels are created, validated, previewed, published, and unpublished. The game downloads published level data from an API, so content can be added or revised without rebuilding or redistributing the mobile app, as long as the level uses mechanics the installed client already supports.

The same web application also serves the **public Algomind website**, whose job is to get people to install the Android app: a landing page, a download page (APK from GitHub Releases, no Google Play), a how-to-play page, and legal pages. A level catalog and browser play come later. See [README_WEB_PLAN.md](README_WEB_PLAN.md).

## 2. Product goals

1. Deliver a polished, genuinely playable puzzle game for Android.
2. Make level content data-driven rather than hardcoded into scenes or scripts.
3. Build a small but real full-stack system: Godot client, NestJS API, PostgreSQL, and one Next.js app that holds both the admin dashboard and the public website.
4. Let the developer create, publish, update, and unpublish levels through the dashboard without shipping a new game version for every content change.
5. Establish the full architecture and engineering pipeline (contract, API, dashboard, CI/CD, quality tooling) before the catalog grows, then grow the catalog one level at a time from the dashboard.
6. Demonstrate product ownership: game design, user experience, API and data modeling, deployment, and maintainable implementation.

## 3. Target users

- **Players** who like short, thoughtful logic puzzles, prefer no-pressure single-player sessions, and enjoy planning and improving a solution rather than relying on reflexes. The primary experience is a phone in portrait orientation.
- **Visitors** to the public website who want to learn about the game, browse levels, try it in the browser, or download it.
- **The admin (the developer)**, who authors and publishes levels on a desktop or tablet. The dashboard is an authoring tool, not a second game client.

## 4. Core experience

### Player loop

1. Choose an available level.
2. Inspect the board, start state, goal, obstacles, and available commands.
3. Build or adjust an action sequence.
4. Run the automaton and watch the result.
5. See clear feedback if the run succeeds, fails, or reaches an instruction limit.
6. Retry, reset, or continue to the next unlocked level.

### Content-authoring loop

1. Sign in to the dashboard and create a draft level.
2. Configure its board, entities, rules, instructions, and goal using supported level fields.
3. Validate the data, preview it with the shared reference simulator, and record a reference solution.
4. Publish a new immutable version. Publishing is blocked unless the level validates and its reference solution solves it.
5. The game and the public website fetch the published version through the API.
6. To correct or improve a level, publish another version; players do not need a client rebuild for compatible data changes.

The catalog starts small. A level is added by authoring it in the dashboard, not by editing files or code.

## 5. Product principles

### Simple rules, meaningful choices

Teach mechanics in isolation before combining them. Do not make a level difficult because the rules or controls are unclear.

### Predictable simulation

The same level and same instructions should produce the same result in every implementation (game, dashboard preview, API check). Deterministic behavior makes puzzles fair, levels testable, and score validation more reliable.

### Content is data

Board layout, object placement, supported command limits, goal conditions, hints, and level metadata belong in versioned level data. They should not be special-cased in a scene or hardcoded by level ID.

### Helpful failure

When a run fails, explain the reason in player-friendly language: for example, “The automaton hit a wall,” “No instructions remain,” or “The program stopped before reaching the goal.” Avoid cryptic error codes.

### Honest scope

Build a complete small game on a solid foundation. A small set of excellent puzzles is more valuable than many repetitive levels. Strong architecture and tooling come first; level count comes later.

### Quality is enforced, not intended

Linting, formatting, type checks, tests, commit conventions, and CI gates exist from the first commit. A change that fails them does not merge.

## 6. Platform and technology direction

| Component       | Responsibility                                                                                                                                                         | Planned technology                                            |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Game client     | Gameplay, board rendering, simulation, local settings, cached levels, Android and web export                                                                           | Godot 4.x / GDScript, GUT tests, gdtoolkit (gdlint, gdformat) |
| Web app         | **Admin dashboard** (level authoring, validation, preview, publishing) and **public website** (landing, level catalog, browser play, downloads, legal) in one codebase | Next.js (App Router) / TypeScript / Tailwind                  |
| API             | Authentication, level catalog, validation, publishing, optional player progress                                                                                        | NestJS / TypeScript / REST                                    |
| Database        | Admins, levels, immutable versions, publication state, optional player progress                                                                                        | PostgreSQL                                                    |
| Database access | Migrations and typed persistence                                                                                                                                       | Prisma                                                        |
| Level contract  | JSON Schema, TypeScript types, shared validator, reference simulator, shared fixtures                                                                                  | `packages/level-contract`                                     |
| Design tokens   | Colors and shared values for light and dark themes, generated into the Godot palette and web CSS                                                                       | `packages/design-tokens`                                      |
| Hosting         | API, database, web                                                                                                                                                     | Render (API), Neon (PostgreSQL), Vercel (web)                 |

The game, web app, and API are separate applications. They share the level contract, not runtime code. Godot reimplements the validator and simulator in GDScript and is verified against the same fixtures. Godot does not depend on the Next.js application to retrieve published content.

Engineering standards (hooks, linting, CI/CD, releases) follow the DropGrid project conventions; see [CI.md](CI.md).

## 7. MVP scope

The MVP is complete when it includes:

- A polished core gameplay loop with a small campaign of handcrafted levels, all authored through the dashboard.
- An explicit, versioned JSON level format, shared validator, and reference simulator with common fixtures.
- A functional admin dashboard (see [README_DASHBOARD_PLAN.md](README_DASHBOARD_PLAN.md)): sign-in, create, edit, validate, preview, solver, playtest gate, publish, unpublish, version history, campaign structure (worlds and chapters), import and export, capabilities registry, and audit log.
- An API that exposes published levels publicly and protects draft and admin operations.
- PostgreSQL persistence for levels and versions.
- A game client that fetches published remote levels, caches them, and keeps a small bundled starter set for offline first launch.
- A public website, download first: landing page, download page with install steps and a QR code, how to play, privacy, contact. The level catalog and browser play follow after launch.
- Loading, offline, empty-state, error, and success UI in the game; loading, error, and save states in the dashboard.
- Automated tests for the simulation rules, level-data validation, publication behavior, and API authorization.
- A full CI/CD pipeline, quality tooling, and deployment documentation.

The game is local-first and offline-first: progress saves on the device and nothing requires an account. **Optional accounts with cloud progress sync** follow the core release (the save format, data model, and API are designed for them from the start). The first release does **not** require competitive leaderboards, monetization, multiplayer, a public user-generated-level marketplace, or a complex analytics stack.

## 8. Scope boundaries

### Included

- Single-player puzzles.
- Fixed set of client-supported game mechanics.
- Versioned data-driven levels managed through the dashboard.
- Public website in the same Next.js app as the dashboard.
- A campaign of worlds, chapters, and levels with sequential unlocking, and difficulty metadata.
- Local-first, offline-first progress. Optional accounts that sync progress to the cloud when the player signs in and is online, built after the core release.
- Level caching so previously downloaded content can remain playable during temporary network failure.

### Not included in the initial MVP

- Downloading and executing arbitrary scripts from the server.
- A general-purpose visual programming language.
- Real-time multiplayer or player-versus-player features. (Leaderboards, a daily challenge, and sharing are planned, opt-in, and account-based: [README_SOCIAL_PLAN.md](README_SOCIAL_PLAN.md).)
- Payments, ads, subscriptions, or in-app purchases.
- Player-created levels submitted publicly.
- Real-time collaborative editing.
- Microservices, queues, Redis, WebSockets, or event-driven infrastructure.

## 9. Key success criteria

- A new compatible level can be authored and published from the dashboard without editing game code or rebuilding the client.
- An invalid or unsolvable level cannot be published accidentally.
- The dashboard preview, the API check, and the game produce identical results for the same level and program.
- The mobile client handles loading, API failure, and cached levels without crashing.
- A level remains reproducible: identical initial state and instructions yield identical results.
- A first-time player can understand the controls from onboarding and the first few levels.
- Every merge to `main` passes the same quality gates that run locally.
- The project can be cloned, configured, tested, and run using the documentation.

## 10. Important limitation

Remote level publishing does not mean every future gameplay idea can be added remotely. New layouts, objectives, hints, difficulty settings, and combinations of already implemented mechanics can be data-only changes. A genuinely new mechanic—such as a new type of moving platform or a new command—usually requires a client code update and app release, unless it was deliberately supported by the existing game engine and level schema. The dashboard must only allow publishing mechanics that the deployed client declares support for.

## 11. Suggested repository layout

```text
 Algomind/
 ├── apps/
 │   ├── api/                 # NestJS API (Prisma, PostgreSQL)
 │   ├── web/                 # Next.js: public site + admin dashboard
 │   └── game/                # Godot project
 ├── packages/
 │   ├── level-contract/      # JSON Schema, TS types, validator, reference simulator, fixtures
 │   └── design-tokens/       # Theme tokens (source of truth) and generators for Godot and web
 ├── docs/
 │   ├── README_PROJECT_OVERVIEW.md
 │   ├── README_GAME_RULES.md
 │   ├── README_GAMEPLAY_FEATURES.md
 │   ├── README_VISUAL_DESIGN.md
 │   ├── README_WEB_PLAN.md
 │   ├── README_SOCIAL_PLAN.md
 │   ├── README_ROADMAP.md
 │   ├── README_DASHBOARD_PLAN.md
 │   ├── README_ARCHITECTURE.md
 │   ├── README_CODE_STANDARDS.md
 │   ├── README_IMPLEMENTATION_PLAN.md
 │   ├── CI.md
 │   ├── DEPLOY.md
 │   └── design/              # SCREENS.md and rendered concept screens (light and dark)
 ├── docker/                  # Headless Godot image and helper scripts
 ├── scripts/                 # Version bump and other utilities
 ├── .github/                 # Workflows, Dependabot, issue and PR templates
 ├── .husky/                  # Git hooks
 ├── AGENTS.md  CONTRIBUTING.md  SECURITY.md  CODE_OF_CONDUCT.md  LICENSE
 ├── Makefile                 # Single command surface for every app
 ├── VERSION
 ├── .env.example
 └── README.md                # Setup, commands, screenshots, deployment
```

The Godot project lives in the same repository but remains a distinct application. Use a pnpm workspace for the TypeScript apps and packages (`apps/api`, `apps/web`, `packages/*`); do not force Godot assets or scripts into the JavaScript build system.

## 12. Open decisions to settle before implementation

- Final font (one open-licensed condensed sans) and the app icon. The visual direction (Instruction Tape, with light and dark themes) and the wordmark concept are settled; see [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md).

**Settled** (see [README_GAME_RULES.md](README_GAME_RULES.md) and [README_VISUAL_DESIGN.md](README_VISUAL_DESIGN.md)): the initial command set and rules, portrait-first orientation, local-first progress with optional cloud sync, the visual direction with light and dark themes, and a campaign of worlds and chapters. Production URLs are the default Vercel and Render URLs and become known after the first deployment; a custom domain is optional and can come later.

Do not block the foundation on branding or optional online features.
