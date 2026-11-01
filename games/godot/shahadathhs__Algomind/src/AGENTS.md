# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project

Algomind: a programming puzzle game. The player builds a program from instruction tiles, runs it, and guides an automaton to the target. Monorepo:

- `apps/game`: Godot 4 (GDScript), Android first.
- `apps/api`: NestJS + Prisma + PostgreSQL.
- `apps/web`: Next.js. `(public)` route group is the public site (download first); `(admin)` is the level dashboard.
- `packages/level-contract`: JSON Schema, TypeScript types, validator, reference simulator, solver, shared fixtures.
- `packages/design-tokens`: the only source of colors; generates the Godot palette and web CSS.
- `docs/`: the specification. It is the source of truth; read the relevant file before changing behavior.

Read `docs/README_PROJECT_OVERVIEW.md` for scope. Do not add features from its "not included" list. Never claim you ran Godot, exported a build, or tested on a device unless you actually did.

## Branching and commits

Work on `dev`; changes reach `main` through a pull request. Commits follow **Conventional Commits** (enforced by commitlint in the `commit-msg` hook). The `pre-commit` hook runs lint-staged (oxlint and prettier). Never skip hooks (`--no-verify`) and never commit secrets. Do not commit or push unless the user asks, and never run `make release` (it commits and pushes).

## Commands

`make` is the command surface (run `make help`). CI runs the same commands.

```sh
make setup          # one-time: .env, deps, database, migrations, Godot cache
make check          # everything CI runs (needs host Godot and uv for the game targets)
make lint           # oxlint + prettier --check
make format         # prettier --write
make typecheck      # tsc in every TypeScript package
make test           # TypeScript tests (no database needed)
make game-test      # GDScript tests (GUT, includes the contract fixtures); make game-docker-test runs them in a container
make tokens         # regenerate the Godot palette and web CSS from design tokens
make tokens-check   # fail if generated token files are out of date
make size-check     # fail if a source file is over 450 lines (lists files over 300)
make api-dev        # API at :8000 (starts the database)
make web-dev        # web at :3000
make up / make down # everything in containers
make game-apk       # debug APK via the Godot container
make version v=X.Y.Z  # write a new version into every file that carries it (no git)
```

After any change run the targets that cover it. Docs in `docs/` must match the code; update them in the same change.

## Architecture rules (do not break)

- **One rule set, several implementations.** The reference simulator (TypeScript) and the GDScript simulator implement the same rules. Every fixture in `packages/level-contract/fixtures` must pass in both. Never fix a disagreement in only one.
- **Simulation is separate from animation and UI.** It never depends on frame rate, network, or time. Animations display simulation events.
- **Content is data.** No `if level_id == ...` branches. Placement (world, chapter, order) is campaign data, separate from level versions.
- **Published versions are immutable.** Edits create a new draft version. Draft is a `LevelVersion` row.
- **Server is the authority.** Validate on the API even when the client validates. Hiding UI is not authorization.
- **Auth:** short-lived bearer access token plus rotating refresh token, automatic logout. Tokens never go in `localStorage`.
- **Colors come only from `packages/design-tokens`.** A grep for hex colors or `Color(` outside the generated files and the token source must find nothing.
- **Local-first progress.** Signed-out play uploads nothing. Sync is the only code allowed to upload progress, and a failed sync never touches local data.
- **No tracking, third-party scripts, cookies, or runtime third-party fonts** on the public site.

## Code shape rules

File size, module structure, and reuse are specified in `docs/README_CODE_STANDARDS.md`. When writing code:

- Hand-written source files stay under 300 lines (450 is the review-reject ceiling).
- One exported React component per `.tsx` file; the file is named after the component.
- Extract shared helpers, hooks, and components on the second copy; never paste between files.
- Any edit to an oversized file splits or extracts the part being touched; do not grow it.

## Visual rules (the house style)

The design system is **Instruction Tape**; the full rules are in `docs/README_VISUAL_DESIGN.md`. When touching UI:

> **Depth direction (approved, not yet built).** The owner approved a depth version of this style (soft shadows, face shading, keys with a lip, a 2.5D board): `docs/README_VISUAL_DESIGN.md` section 14 and `docs/README_3D_VIEW_PLAN.md`. The rules below describe the shipped code. Work on the depth track follows section 14, which allows soft shadows, a ground gradient, face shading, and the 2.5D board and keeps the other bans (no glow, blur on content, particles, glass, or emoji). Do not mix the two styles on one screen.

- The unit is the tile: square with the top-right corner chamfered. Board cells are square.
- One accent: signal yellow, used as a fill with ink on top; never as text or a line on the light ground.
- Exactly one primary (yellow) button per screen. Secondary actions are outlined tiles; tertiary are underlined text.
- No gradients, glow, drop shadows, glass, blur, particles, bevels, or 3D. No cards; group with spacing and a small caption. No card inside a card.
- No taglines, two-tone headlines, motivational copy, questions to the player, exclamation marks, or emoji.
- Color is never the only signal; every state also has a shape, icon, number, or label.
- Both themes (light and dark) are first-class; check every screen in both.
- No animation over 250 ms (except the result screen); nothing loops while idle; support reduce motion.
- Do not borrow another project's fonts, palette, wordmark, or corner style.
- Prefer deleting to adding. If unsure between two options, build both small and compare them.

## Verify before you claim

You cannot judge a design you have not seen. For UI work, capture screenshots at 390×844, 360×640, and 412×915 in both themes, look at each, and list what is wrong before reporting a screen done. For web work, also check the page with JavaScript disabled.

## Quality

- Lint is **oxlint** plus prettier. There is no ESLint (TypeScript 7 has no JS compiler API for typescript-eslint).
- The API is an ES module project built with **SWC**; the Nest CLI is not used (it needs the TypeScript compiler API). The API has focused Vitest tests (`pnpm --filter @algomind/api test`, run by `make test`; no database needed): publish gates, authorization, sessions, and the progress merge. The web app has no unit tests; `make web-smoke` drives the dashboard publish flow in Chrome against a running API and web app (local only, not part of `make check`). The contract (`packages/level-contract`), the design tokens, and the game's GDScript tests also remain. Prisma's generated client is not committed; `make api-generate` creates it.
- Type checking uses the native `tsc` (TypeScript 7).
- Tests for logic you add; the simulator, validator, solver, and publish gates are the highest-risk areas.
- A feature is done when it meets the "definition of done" in `docs/README_IMPLEMENTATION_PLAN.md`.
