# Nebula Catcher

![Generated game hero](docs/assets/generated-readme-hero.png)

Nebula Catcher is a tiny browser game built as a static Vite web app. Move the ship, catch stars, avoid meteors, and try to beat your high score.

![Architecture diagram](docs/architecture.svg)

## Public deployment targets

| Target | Status | URL pattern |
| --- | --- | --- |
| GitHub Pages | Configured by `.github/workflows/pages.yml` | `https://<github-owner>.github.io/nebula-catcher-web-game/` |
| Cloudflare Pages | Configured by `.github/workflows/cloudflare-pages.yml` after Secrets are added | `https://nebula-catcher-web-game.pages.dev` |
| Cloudflare custom domain | Connect from Cloudflare Pages dashboard after project creation | Your owned Cloudflare domain |

## Game controls

- Keyboard: left/right arrows or A/D.
- Touch or mouse: tap/drag inside the game canvas.
- Start/restart: button, Space, or Enter.

## Architecture and processing flow

```mermaid
flowchart LR
    U[Player input] --> B[Browser]
    B --> C[Canvas renderer: src/main.js]
    C --> L[Game rules: src/gameLogic.js]
    L --> C
    C --> H[HUD and localStorage high score]
    G[GitHub Actions] --> N[npm install]
    N --> Q[Lint]
    Q --> V[Vitest]
    V --> D[Vite build]
    D --> A[dist artifact]
    A --> P[GitHub Pages]
    A --> CF[Cloudflare Pages]
    CF --> CD[Cloudflare custom domain]
```

The app is intentionally static: no server, no database, no external runtime dependency. Production hosting only needs the generated `dist/` directory.

## Quick start

```bash
npm install
npm run dev
```

## Test and build

```bash
npm run check
```

See [`docs/setup.md`](docs/setup.md) for step-by-step setup and [`docs/architecture.md`](docs/architecture.md) for architecture notes.
