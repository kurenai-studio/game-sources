# Architecture

Brick Breaker Resume is a static Vite site. A build step turns the résumé `.docx` into `public/assets/resume.json`; in the browser, `main.js` draws the start screen from that data and loads Phaser 3 only once a player picks a look. There is no server-side code: nginx on a GCP VM serves the built `dist/` folder.

The diagrams use the shared palette from the portfolio's [workspace architecture](https://github.com/natezimm/nathanzimmerman.com/blob/main/docs/architecture.md), which also shows how this game fits among the other projects.

## System context

```mermaid
flowchart LR
  Player["Player<br/>desktop or phone browser"] -->|"HTTPS"| Site["resume.nathanzimmerman.com<br/>static site on nginx"]
  Portfolio["nathanzimmerman.com<br/>portfolio"] -->|"links to"| Site
  Owner["Résumé owner"] -->|"edits"| Docx["Résumé .docx<br/>in this repo"]
  Docx -->|"parsed at build time"| Site
  Site --> Storage["Browser localStorage<br/>theme, high score"]

  classDef user fill:#f8fafc,stroke:#475569,color:#0f172a
  classDef site fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
  classDef data fill:#fef3c7,stroke:#b45309,color:#78350f
  class Player,Owner user
  class Site,Portfolio site
  class Docx,Storage data
```

## Containers and runtime

Everything runs in the player's browser. The page owns the DOM (start screen, HUD, settings and the bricks themselves); Phaser owns physics and draws the ball, paddle and trails on a transparent canvas laid over the bricks.

```mermaid
flowchart LR
  Player["Player<br/>mouse, touch, keyboard"] --> Page["index.html + main.js<br/>start screen, HUD, settings"]
  Page -->|"dynamic import on Play"| Phaser["Phaser 3 scene<br/>src/game.js"]
  Phaser --> Physics["Arcade physics<br/>ball, paddle, brick bodies"]
  Page --> Layout["Brick layout<br/>wall or typeset"]
  Phaser --> Layout
  Layout -->|"fetch"| Data["resume.json<br/>public/assets"]
  Layout --> Bricks["DOM bricks<br/>src/brickDom.js"]
  Page --> Storage["localStorage<br/>theme, high score"]

  classDef user fill:#f8fafc,stroke:#475569,color:#0f172a
  classDef client fill:#dcfce7,stroke:#15803d,color:#14532d
  classDef data fill:#fef3c7,stroke:#b45309,color:#78350f
  class Player user
  class Page,Phaser,Physics,Layout,Bricks client
  class Data,Storage data
```

## Résumé to bricks

The flow that carries the most design: one document becomes two complete layouts that agree on every word, so a theme switch mid-game keeps what the player has broken.

```mermaid
sequenceDiagram
  autonumber
  participant Build as npm run build
  participant Parser as generate_resume_json.js
  participant Page as main.js + overlay.js
  participant Layout as brickLayout.js / typeset.js
  participant Scene as Phaser scene (game.js)
  participant Bricks as bricks.js

  Build->>Parser: prebuild hook
  Parser->>Parser: Mammoth converts .docx to HTML, JSDOM reads it
  Parser-->>Build: resume.json, a list of { tag, text }
  Note over Page: In the browser
  Page->>Layout: calculateBrickLayouts(['typeset', 'wall'])
  Layout-->>Page: both layouts, each word with its wordIndex
  Page->>Page: render both looks, split at the seam
  Page->>Scene: player picks a side, Phaser is imported and booted
  Scene->>Bricks: createBricksFromResume()
  Bricks->>Layout: calculateBrickLayout() for the active theme
  Bricks->>Bricks: one DOM brick + one static physics body per word
  Scene->>Bricks: ball hits a brick
  Bricks->>Bricks: remove it, add its wordIndex to brokenWords, score by row
  Note over Scene,Bricks: Theme switched mid-game
  Scene->>Bricks: rebuildBricks()
  Bricks->>Layout: lay out again in the new look
  Bricks->>Bricks: skip every wordIndex in brokenWords
```

## Delivery pipeline

```mermaid
flowchart LR
  PR["Pull request<br/>or push to main"] --> Gate["ci job<br/>npm run quality"]
  Gate --> Format["Prettier + ESLint"]
  Gate --> Unit["Jest with<br/>coverage thresholds"]
  Gate --> E2E["Playwright on the<br/>production build"]
  Gate --> Artifact["dist/ artifact"]
  Artifact -->|"main only"| Deploy["deploy job<br/>pinned SSH host key"]
  Deploy -->|"rsync"| VM["GCP VM<br/>/var/www/brick-breaker"]
  VM --> Health["curl health check<br/>resume.nathanzimmerman.com"]

  classDef repo fill:#eef2ff,stroke:#4338ca,color:#312e81
  classDef delivery fill:#f3e8ff,stroke:#7e22ce,color:#581c87
  classDef server fill:#ffedd5,stroke:#c2410c,color:#7c2d12
  classDef site fill:#e0f2fe,stroke:#0369a1,color:#0c4a6e
  class PR repo
  class Gate,Format,Unit,E2E,Artifact,Deploy delivery
  class VM server
  class Health site
```

## Source boundaries

- `main.js` wires startup: theme, start screen, and the on-demand Phaser import.
- `src/game.js` is the scene lifecycle and gameplay; `src/state.js` holds per-scene state; `src/config.js` and `src/constants.js` hold configuration and each look's defaults.
- `src/brickLayout.js` (wall) and `src/typeset.js` (paper page) compute layouts; `src/brickDom.js` renders bricks for both the start screen and the game; `src/bricks.js` pairs them with physics bodies and handles hits.
- `src/ui.js`, `src/settings.js` and `src/overlay.js` are the DOM UI, settings modal and start screen.
- `scripts/` parses the résumé. It is CommonJS and runs only at build time.

## Quality gates

`npm run quality` runs Prettier, ESLint, Jest with coverage thresholds (`jest.config.cjs`), and Playwright against the production build at desktop and phone sizes. The Playwright web server runs `npm run build`, so the résumé parser runs too.

## Deferred follow-ups

Phaser module boundaries stay as they are for now. Later work can separate rendering adapters from game rules more strictly and add a typed schema for `resume.json`.
