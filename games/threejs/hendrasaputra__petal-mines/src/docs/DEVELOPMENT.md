# Development guide

Petal is a standalone, mobile-first Three.js + TypeScript + Vite game with original procedural pink voxel geometry and a quiet pastel interface. No account, backend, runtime CDN or downloaded assets are required.

## Local setup

Use Node.js 22.12+, 24, or 26+. The same commands work in macOS/Linux Terminal and Windows PowerShell:

```sh
npm ci
npm run dev
npm test
npm run build
npm run preview
```

Deploy `dist/` to a static host. Serve over HTTP(S), rather than opening the HTML file directly. A phone on the same network can use the dev server's printed Network URL. Local saves belong to that browser and URL origin; changing port or device starts a separate save.

## Code and verification

- `src/engine.ts`: pure rules, topology, seeded generation, exact retry and board validation.
- `src/solver.ts`: visible-information deductions on a copy of the game.
- `src/campaign.ts`: fixed, versioned no-guess levels and lessons.
- `src/storage.ts`: versioned save envelopes and migration.
- `src/gestures.ts`: testable pointer state, separated from WebGL.
- `src/scene.ts`: geometry, labels, inspection highlights, camera and active-floor picking.
- `src/main.ts`: UI, progression, hints and browser storage.

Run `npm test` and `npm run build`. See [validation report](../VALIDATION.md) for test coverage, browser checks and limits. The build has a non-blocking chunk-size warning for Three.js (approximately 134 kB gzip).

[INITIAL_IDEAS.md](../INITIAL_IDEAS.md) preserves the original design document verbatim. The current scope ends at Connected. Inspired by the procedural isometric dioramas of [Pixel Plays](https://github.com/amirmushichge/pixel-plays); no source code, music or visual assets were copied.

## Publishing

See [GitHub Pages deployment](DEPLOYMENT.md) for the workflow, custom domain and DNS instructions.

## License

The project is distributed under the [MIT License](../LICENSE). Dependencies retain their own licenses.
