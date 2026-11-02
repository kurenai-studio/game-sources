# Contributing to GOAL RUSH

Thanks for your interest in improving GOAL RUSH — a pinball × slots arcade hybrid
built with Next.js 16, Phaser 3.90 + Matter.js, and Prisma/SQLite.

## Getting started (local dev)

```bash
git clone https://github.com/rajkdas/goal-rush-game.git
cd goal-rush-game
npm install          # postinstall runs prisma generate
cp .env.example .env # adjust DATABASE_URL if you like (default: file:./db/custom.db)
npm run db:push      # create/sync the SQLite leaderboard schema
npm run dev          # http://localhost:3000
```

> Windows: run the commands above from **Git Bash or WSL** — the `build`/`start`
> scripts use POSIX `cp` and `NODE_ENV=` syntax that native PowerShell won't parse.

## Before you open a PR

Run all three locally; CI runs the same checks:

```bash
npm run lint         # ESLint (eslint-config-next)
npx tsc --noEmit     # full type-check
npm run build        # next build (standalone output)
```

If you change table geometry or physics, also run the regression probe:

```bash
bun scripts/probe-loop.ts   # left-orbit loop must reach a flipper with zero stalls
```

## Code style

- TypeScript strict mode; avoid `any` in new code.
- [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`).
- All game tuning lives in `src/game/config/` (`table.config.ts`, `game.config.ts`,
  `slots.config.ts`) — prefer data changes over hard-coded values in scenes.
- Slot math changes must update `docs/MATH.md` and re-run
  `bun scripts/rtp-simulation.ts` (writes `docs/RTP-RESULTS.md`).

## Reporting bugs

Open a GitHub issue using the **bug report** template (include OS, browser and a
screenshot; `?debug=1` shows the physics wireframe). Security issues go through
[SECURITY.md](SECURITY.md) — never in a public issue.
