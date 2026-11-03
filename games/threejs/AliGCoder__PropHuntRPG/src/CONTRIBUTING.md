# Contributing

Thanks for helping build PropHunt RPG!

## Setup

```bash
npm install
npm run dev
npm test
```

## Guidelines

- **Keep simulation code three.js-free** (`game/HostServer.js`, `game/rules.js`,
  `game/Bots.js`, `world/*`, `skills/*`) so it stays testable in Node.
- **Balance numbers go in `src/game/rules.js`.** Don't hard-code them elsewhere.
- **Content is data.** Prefer adding entries to `PropCatalog.js` / `abilities.js`
  over special-case code.
- Match the existing style: ES modules, tabs, spaces inside parentheses
  (three.js style), small focused classes.
- Add or extend a test in `tests/` for any rules or host change.

## Pull requests

1. Fork the repo and create a branch: `feat/<thing>` or `fix/<thing>`.
2. Run `npm test && npm run build` before pushing. CI runs the same steps.
3. Describe gameplay changes from the player's point of view, and include a
   screenshot for anything visual.

## Reporting bugs

Open an issue with the bug template. Include your browser, whether the game
ran on WebGPU or WebGL 2 (shown on the main menu), and console errors.
