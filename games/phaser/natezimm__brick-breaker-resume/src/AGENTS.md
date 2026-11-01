# Brick Breaker Resume agent guide

## Scope and workspace

This is a static Phaser 3 game built with Vite. Resume text becomes breakable bricks; browser storage holds the theme and high score. It is linked from the separately maintained portfolio in `../nathanzimmerman.com` and deployed at `resume.nathanzimmerman.com`.

The portfolio and this repo are independent Git repositories, alongside the other portfolio projects (`../wheelhouse`, `../know-ball`, `../rabbit-ears`). Read each repo's guide before editing it. Check the working tree and preserve unrelated changes. See `docs/architecture.md` for design context; keep this guide aligned with executable configuration.

## Where to work

- `index.html` and `main.js`: browser entry and UI wiring. Phaser is imported and started only after the Start button is clicked.
- `src/game.js`: scene lifecycle and gameplay; `src/state.js`: scene-owned runtime state; `src/config.js` and `src/constants.js`: Phaser configuration and shared constants.
- `src/bricks.js`, `src/brickLayout.js`, and `src/textures.js`: brick creation, layout, and generated textures. The game and start overlay share the layout calculation.
- `src/typeset.js`: the Paper (typeset) layout; `src/brickDom.js`: DOM rendering of bricks, ghosts, and page marks shared by the overlay and the game.
- `src/ui.js`, `src/settings.js`, and `src/overlay.js`: DOM UI, settings, and overlays; `styles/*.css` are linked directly from `index.html` (`style.css` is only a placeholder). `styles/base.css` holds tokens and shared geometry, `styles/themes.css` the surfaces of each look, and `styles/fonts.css` the self-hosted Newsreader import.
- `scripts/generate_resume_json.js`: CommonJS resume parser using Mammoth and JSDOM.
- `public/assets/Nathan Zimmerman Resume.docx`: resume source; `public/assets/resume.json`: generated data. The browser fetches them as `assets/...`, which Vite serves from `public/`.
- `tests/`: Jest units, including `mockScene.js` and `setupTests.js`; `e2e/brick-breaker.spec.js`: real-browser gameplay checks.

## Commands and runtime caveat

Run commands from the repository root. Node 22 everywhere: `.nvmrc` (which CI reads), `engines` in `package.json`, and the Dockerfile's build image. Change them together.

- Install: `npm ci`.
- Develop: `npm run dev` (port **8080**, automatically opens a browser).
- Build: `npm run build` produces `dist/`; `npm start` previews the build.
- Regenerate resume data: `npm run generate:resume`. Both development and build commands invoke this through lifecycle hooks.
- Unit tests: `npm test`; target a file with `npm test -- --runInBand tests/bricks.test.js`.
- Lint/coverage: `npm run lint` and `npm run test:coverage`.
- Browser tests: `npm run test:e2e`; install Chromium with `npx playwright install chromium` if needed.
- Full CI gate: `npm run quality` runs formatting, lint, Jest coverage, and Playwright; Playwright invokes the production build and resume generation.
- Documentation-only checks: `npx prettier --check <files>`.

## Behavior to preserve

- Update resume source or parser logic before regenerating JSON; direct JSON edits are overwritten by the next development/build run. The parser emits an array of `{ tag, text }` entries, with one `li` entry per list item; review the tracked `public/assets/resume.json` diff after regeneration.
- The two themes are complete looks, not recolors. `dark` (the default) is Glass: the justified wall of glowing bricks. `light` is Paper: the résumé typeset as a printed page, one word per brick. `document.documentElement.dataset.theme` selects the layout, and `THEME_LOOKS` in `src/constants.js` holds each look's defaults.
- Every brick carries a `wordIndex`, its word's position in the résumé, which is the same in both layouts. Switching themes mid-game rebuilds the remaining bricks from `state.brokenWords`; keep that index stable when changing either layout. Everything on the Paper page is a brick: the rule under the contact line and the bullet dots are keyed `rule-N` and `dot-N`, and exist only in that layout.
- The typeset layout measures words with the same font strings the DOM renders (`TYPESET_FAMILIES`). Change a typeface in `src/typeset.js` and `styles/base.css` together. Newsreader ships from `@fontsource-variable/newsreader` so the Content Security Policy can stay on `'self'`.
- The Phaser canvas is transparent; the page paints the backdrop behind it. Ball and paddle glow is drawn by the trail graphics in `src/game.js`.
- The HUD (`#hud`: lives, controls, score) is DOM, styled per look in `styles/components.css`. `state.livesBalls` entries and `state.scoreText` are small adapters over it created in `src/ui.js`, so game logic still pops a life and updates a score label. `src/settings.js` publishes `--ball-color`, `--paddle-color`, and `--paddle-width` on the root for the life pips and the settings preview.
- The start screen renders both looks at once. Each `.look-pane` carries `data-look` (which applies that look's tokens regardless of the page theme) and a `.look-resume[data-mode]` naming its layout; panes are clipped at `--split`. A mouse leans the seam by hovering (CSS); a finger or pen drags it (`enableSeamDrag` in `src/overlay.js`). Choosing a side applies the theme, sweeps `--split` to that edge, and starts Phaser after the sweep.
- Preserve pause/resume and countdown behavior, settings-modal auto-pause, resize handling, mouse/touch controls, scoring, and persisted high scores.
- Access active scene state through the helpers in `src/state.js`; the exported `gameState` singleton is a fallback, while gameplay attaches its own state to the scene.
- Render resume text with `textContent` and retain validation of stored theme, high score, and asset paths. Other gameplay settings are currently session-only.
- Browser modules use ES imports. The resume parser and ESLint config use CommonJS; Jest transforms application imports with Babel (`jest.config.cjs`, `babel.config.cjs`). Changing package module type affects these boundaries.

## Verification and delivery

Run checks appropriate to the change, using `npm run quality` for broad application changes. Use `tests/mockScene.js` for logic tests and Playwright for canvas/DOM integration on desktop and mobile. Coverage thresholds live in `jest.config.cjs`. Report failures and unrun checks; format only changed files.

Playwright hardcodes port **4173**, shared with the sibling repos, and reuses an existing server outside CI. Stop unrelated preview servers before testing and run sibling browser suites sequentially to avoid testing the wrong app.

`.github/workflows/ci.yml` runs CI on pull requests and pushes to `main`, then deploys the built `dist/` artifact to GCP only for successful pushes to `main`. The deploy job refuses to run without the `GCP_KNOWN_HOSTS` secret and pins the VM's host key. Keep deployment within the requested scope and edit sources rather than generated build/test output.

README images live in `docs/images/`. `docs/architecture.md` holds the Mermaid diagrams, using the classDef palette shared with the portfolio; the README embeds its containers diagram, so change both together.
