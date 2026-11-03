# CLAUDE.md

**Steel Front** (`tanks-web-arena`) — a browser 7v7 tank battle game in the spirit of World of Tanks, USSR vs Germany 1943. Three.js + TypeScript + Vite, no external assets: maps, buildings, vehicles and sound are procedural. Live at [tanks.miksoft.pro](https://tanks.miksoft.pro).

## Commands

```bash
npm run dev          # Dev server on :5181
npm run build        # tsc --noEmit + vite build → dist/
npm run typecheck    # tsc --noEmit
npm run lint         # / lint:fix
npm run format       # / format:check
npm run check        # typecheck + lint + format:check — before every commit
```

Test URL parameters (`src/game/testHooks.ts`): `?autostart&seed=N&tank=id&map=classic|steppe|swamp|pass|coast&mode=standard|encounter|assault&weather=clear|overcast|dawn|dusk|fog|rain|snow&speed=K&view=top&debug`.

## Architecture

The layout is described in `README.md` (Project structure); the rules and numbers of each area are in `docs/mechanics/`. Key points:

- `src/config/` holds every tunable number; one file per vehicle in `config/vehicles/{ussr,germany}`. Change balance there, not in the systems.
- `src/game/game.ts` is the loop and the round lifecycle; systems (`tank/`, `combat/`, `ai/`, `world/`, `hud/`, `fx/`) are called from it and do not import each other's internals.
- Everything visual is procedural: no files under `public/` except `.htaccess`.
- Deferred plans live in `docs/TODO-progression.md` and `docs/TODO-server.md`.

## Language

Code, comments, docs, commit messages, the changelog and the README are in **English**. The game UI (labels, ribbons, medals, vehicle, map and crew names in `name:` fields and HUD texts) stays in **Russian**. When a doc or comment quotes a UI string, keep it in Russian and gloss it in English once, e.g. «Мимо» (Miss).

## Pull Request Checklist

Branches are named after the release they ship in: `release/X.Y.Z` (e.g. `release/0.2.1`). Work for an upcoming release goes into its branch; another PR meant for that release is merged into it, not into `main`.

Before opening a PR:

1. Bump `"version"` in `package.json` (`npm version X.Y.Z --no-git-tag-version` updates `package-lock.json` too): almost always **patch**; **minor** only for noticeable new features or gameplay changes; **major** practically never.
2. Add a section for that version to the top of `CHANGELOG.md` in the existing format: `## X.Y.Z`, a one-sentence summary for a release with several changes, then `### Patch Changes` or `### Minor Changes`, then short one-line bullets (under ~100 characters), e.g. `- Bots: scouts no longer drive into the enemy base`. It is written for players: only what they can see, the most important first, no files, functions or internals; small fixes of the same release are not listed. English only, UI labels translated ("Repair kit", not «Ремкомплект»).
3. `npm run check` passes.

## Release

Only after the version-bump PR is merged into `main`: tag the merge commit `v<version>` and create the GitHub release (title = tag, body = that version's `CHANGELOG.md` section without the `## X.Y.Z` heading, marked latest) in one command:
`gh release create v0.1.0 --target main --title v0.1.0 --notes-file <section.md> --latest`.

The push to `main` deploys the site by itself (`.github/workflows/deploy.yml`, FTP); `gh workflow run deploy.yml` re-deploys without a code change.
