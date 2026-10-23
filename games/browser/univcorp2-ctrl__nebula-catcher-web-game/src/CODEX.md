# Agent notes

This repository is designed to be safely modified by coding agents.

## Commands

- Install: `npm install`
- Develop: `npm run dev`
- Verify all: `npm run check`
- Build only: `npm run build`

## Important paths

- Game rules: `src/gameLogic.js`
- Rendering and input: `src/main.js`
- Styles: `src/styles.css`
- Unit tests: `tests/gameLogic.test.js`
- CI: `.github/workflows/ci.yml`
- GitHub Pages deploy: `.github/workflows/pages.yml`
- Cloudflare Pages deploy: `.github/workflows/cloudflare-pages.yml`

## Constraints

- Keep the app static and deployable from `dist/`.
- Do not commit API tokens, account IDs, or domain secrets.
- Keep tests deterministic by putting pure logic in `src/gameLogic.js`.
