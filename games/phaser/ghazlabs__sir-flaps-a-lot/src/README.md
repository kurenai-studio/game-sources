# Sir Flaps-a-Lot

A Flappy Bird-inspired browser game built with PhaserJS where a noble geometric knight flaps through castle hazards.

This repository is designed as an open-source contribution exercise project. The codebase stays intentionally small so contributors can practice real pull request workflows with game-focused tasks.

**Play the demo:** [https://ghazlabs.github.io/sir-flaps-a-lot/](https://ghazlabs.github.io/sir-flaps-a-lot/) — open it in your browser and give the knight a flap; no install required.

## Who This Is For

- First-time open-source contributors who want a practical JavaScript project.
- Developers learning Phaser scene architecture and browser game loops.
- Maintainers running contribution workshops or pair-programming sessions.

## Tech Stack

- Vanilla JavaScript (ES modules)
- PhaserJS via npm package
- Vite for local development/build

## Quick Start

1. Install dependencies:

   ```bash
   npm install
   ```

2. Run the game locally:

   ```bash
   npm run dev
   ```

3. Open the local URL shown in your terminal.

## Available Scripts

- `npm run dev` - Start local dev server
- `npm run start` - Alias to `dev` for contributor convenience
- `npm run build` - Build production bundle
- `npm run preview` - Preview production build locally
- `npm run lint` - Run ESLint checks
- `npm run lint:fix` - Run ESLint with automatic fixes
- `npm run format` - Format files with Prettier
- `npm run format:check` - Verify formatting with Prettier
- `npm run test` - Run Vitest test suite

## Project Structure

```text
sir-flaps-a-lot/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── pull_request_template.md
│   └── workflows/
├── ASSETS.md
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── ROADMAP.md
├── SUPPORT.md
├── index.html
├── package.json
├── src/
│   ├── game.js
│   └── scenes/
│       ├── LoreScene.js
│       ├── MenuScene.js
│       ├── GameScene.js
│       └── GameOverScene.js
└── eslint.config.js
```

## Open Source Docs

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Support](SUPPORT.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)
- [Asset Attribution](ASSETS.md)

Issue and pull request templates live in `.github/`.

## Contribution Notes

- `src/scenes/LoreScene.js`: Intro story and transition into the menu.
- `src/scenes/MenuScene.js`: Main title/instructions scene.
- `src/scenes/GameScene.js`: Core loop (physics, obstacles, score, difficulty).
- `src/scenes/GameOverScene.js`: End screen and restart/menu flow.
- `src/game.js`: Phaser configuration, constants, and scene registration.

Good first contribution ideas:

- Balance tuning for flap strength, obstacle spawn timing, and gap sizes.
- Visual polish to medieval obstacle styling.
- Add optional sound effects and mute toggle.
