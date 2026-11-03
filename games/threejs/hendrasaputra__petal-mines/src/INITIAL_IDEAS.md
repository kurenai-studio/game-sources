# 3D Minesweeper

GAME DESIGN DOCUMENT · VERSION 1.0 · HYBRID PROGRESSION

Three.js

TypeScript

Pixel Plays-inspired

Browser-first

## 1. Product vision

Working title: Minefield — A Tiny World of Logic

A minimalist, isometric Minesweeper game that starts with the familiar 2D experience and gradually introduces a third dimension.

Players begin on a single floating tile board. As they progress, additional floors appear. Eventually, the floors become interconnected, and the player graduates to true volumetric puzzles where every cell can have neighbors above, below, and around it.

The goal is to make 3D spatial reasoning feel like a natural extension of Minesweeper, rather than introducing complicated rules immediately.

[［32×32］ドット絵　マップ素材　ゆめかわ - ドット絵　まゆ子 - BOOTH](https://images.openai.com/static-rsc-4/1M8LT4P_jvtdbnIaOuY3RITeZtYdmpCk1DaUBc5Mo51B6Yqikp2OJfkYyTmP1BVBjSdyHsnvzwsFlowsDCfGo7DExnKqNIq_6laVJTGU7NXb_7wZR8OaVKc9Ht9jkIL8dUlbA7DxRrnw4K_ZA3haNs2bRy7zuKiY5PcixiDAo5A?purpose=inline)

[The adventure of TFC CREATE - Minecraft Modpack](https://images.openai.com/static-rsc-4/acGX-rqqh_T94hUCacS5rceryhvjFTvdQlYg3EexZJw4uFasKRih8PbW2l_aFqT8awVZUccfosWRL37HWFU7fTtL8qd9OQVJaC2ozD80fwHF9jQPRCbkAgN_aLFNtj0zyAYnd1Y8M0Wvp6EbepwKVhoxKUlmYlRFBCDm5jyEqk8?purpose=inline)

[Octree Cube | JuneLee Architecture](https://images.openai.com/static-rsc-4/3-VGo5pylKJX_odLcuUjHQg6fVUD5y9NaAYrDpax8iQqCMLg1LXz2vE6Xa5d7r3le3GgpoEWa1oQA0ykGdKyB4z-17EYUPl9NN2tpcWMKZ0GXQRov8FdZFLyR41AX5IOqCZhgEvpdlK8WrFKGe6Zqgz5e0dF3btbln_A_LS2uho?purpose=inline)

12

Visual direction references: miniature pixel-art dioramas progressing from one floating board to a layered structure and a 3D volume. These are illustrative references, not final game mockups.

### The experience should have five defining principles

- One clear physical action: Reveal a tile, mark a suspected mine, or navigate the structure.
- Progressive complexity: Each new dimension introduces a small, understandable change in the rules.
- Fair logical puzzles: The campaign prioritizes puzzles solvable through deduction, not forced guessing.
- Tactile miniature world: Tiles, layers, and camera movement behave like physical objects.
- Visual restraint: A floating object against a white background, with limited UI and subtle feedback.

### Relationship to Pixel Plays

The [Pixel Plays repository](https://github.com/amirmushichge/pixel-plays?utm_source=chatgpt.com) uses its own dependency-free software rasterizer rather than Three.js. Its design principles include a 360×280 render canvas, orthographic perspective, Bayer dithering, limited shading, long hard shadows, and a miniature floating-world composition.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://github.com\&sz=32)

GitHub



Our game should use Three.js for geometry and interaction, while recreating those rendering characteristics through materials and a low-resolution postprocessing pipeline. The architecture will be independent of the Pixel Plays engine, but closely aligned with its visual philosophy.

## 2. Hybrid progression: the foundation

The progression should consist of four stages, each introducing a new mental model.

## From 2D to 3D

Player learning journey

Foundation

2D logic

Elevation

Layer navigation

Connection

Vertical clues

Volume

Full 3D logic

| Stage         | Player learns                          | Rule introduced                  |
| ------------- | -------------------------------------- | -------------------------------- |
| 1. Foundation | Traditional Minesweeper                | 8 surrounding neighbors          |
| 2. Elevation  | Multiple floors and spatial navigation | Each floor initially independent |
| 3. Connection | Deduction across floors                | New vertical clue types          |
| 4. Volume     | Complete spatial reasoning             | Up to 26 neighboring cells       |

This is the central game design decision: the rules change in clearly signposted stages, but the basic reveal-and-flag interaction stays the same throughout.

## 3. Detailed puzzle mechanics

### Stage 1 — Foundation

A traditional Minesweeper game rendered as a floating physical board.

Each cell has eight possible neighbors in the same plane. The player can reveal a cell or place a flag. Revealing an empty cell cascades into adjacent safe cells; revealing a mine ends the run.

The first reveal is guaranteed safe and should ideally be a zero cell when the board configuration permits it.

Classic Minesweeper interaction

Playable rule demo

3 remaining

RevealFlag

2

2

2

Tap tiles to reveal or flag

&#x20;Reset

This small illustration demonstrates reveal/flag states and mine clues; the production game will add zero propagation, chording, and safe-first-click generation.

### Stage 2 — Elevation

The game becomes a stack of two or more boards. Each floor has its own mine distribution.

At this stage:

- A normal number still counts only adjacent mines on the same floor.
- Floors are independent for the purpose of clue calculations.
- Players can switch floors, collapse the stack, or separate the floors vertically.
- The global mine counter covers all floors.
- Completing the entire structure wins the puzzle.

No cross-floor adjacency exists yet. This distinction must be explicit in the tutorial.

### Stage 3 — Connection

Now we introduce three-dimensional clues, but keep traditional 2D numbers.

A normal number continues to represent mines among the eight same-floor neighbors. A special clue with an arrow represents mines in a different neighborhood.

Proposed clue language

# 3

Local

3 mines in surrounding 8

## 2

Above

2 mines in 3×3 area above

## 1

Below

1 mine in 3×3 area below

For vertical clues, define the target region precisely: all nine coordinates in the 3×3 footprint on the immediately adjacent floor, including the directly aligned position, clipped at board boundaries. A vertical clue never includes mines from its own floor.

Special clues are fixed properties of safe cells. Their type must be visible when revealed, and the rules overlay must clearly show their target neighborhoods.

During this stage, introduce them gradually: first upward clues, then downward clues, then levels that require both.

### Stage 4 — Volume

The player enters true 3D Minesweeper.

The board is no longer treated as a set of independent 2D puzzles. Each cell can have neighbors in all three dimensions.

A revealed cell counts mines among the 26 surrounding positions:

Below

9 neighbors

Current

8 neighbors

Above

9 neighbors

9 below + 8 on the current floor + 9 above = 26 possible neighbors for an interior cell.

The underlying rule becomes:

\\[ N(x,y,z)=\sum\_{\substack{dx,dy,dz\in\\{-1,0,1\\}\\\\(dx,dy,dz)\ne(0,0,0)}} M(x+dx,y+dy,z+dz) \\]

where \\(M\\) returns 1 for an in-bounds mine and 0 otherwise.

In this mode, traditional clue numbers may reach 26. The interface therefore needs to support two-digit values, not just the usual 1–8.

Players must isolate slices of the volume to interact with internal cells. Solid opaque cubes alone would make hidden positions impossible to inspect.

### Common game rules

The following rules should stay consistent across modes:

| Situation              | Behavior                                                                          |
| ---------------------- | --------------------------------------------------------------------------------- |
| First reveal           | Guaranteed safe; zero when feasible                                               |
| Reveal a numbered cell | Show the clue for its configured neighborhood                                     |
| Reveal zero            | Recursively reveal adjacent safe cells using that mode's reveal-neighborhood rule |
| Flag cell              | Toggle the flagged state without revealing                                        |
| Chord                  | Reveal unflagged neighbors if adjacent flagged count equals the clue              |
| Incorrect chord        | May trigger a mine; confirmation is optional in casual mode                       |
| Reveal mine            | Game over in standard mode                                                        |
| Win condition          | All non-mine cells revealed                                                       |
| All mines flagged      | Not sufficient to win by itself                                                   |
| Restart                | New attempt with the same seed                                                    |
| New puzzle             | Generate a new seeded board                                                       |

One important choice: zero propagation and chording should operate on the clue's defined neighborhood, not an unrelated adjacency set. For special vertical clues, this means a vertical zero may reveal cells in its indicated target footprint. This rule must be consistent and documented.

## 4. Difficulty balancing and campaign design

Mine density alone is a poor measure of difficulty, especially when moving from eight neighbors to 26.

A more robust system should measure board size, topology, mine density, number of cross-layer deductions, and the amount of reasoning needed to complete the puzzle.

### Proposed difficulty presets

| Mode          | Grid  | Mines | Estimated density |
| ------------- | ----- | ----- | ----------------- |
| Tutorial      | 5×5×1 | 3     | 12%               |
| Beginner      | 7×7×1 | 6     | 12.2%             |
| Explorer      | 6×6×2 | 9     | 12.5%             |
| Layered       | 8×8×3 | 26    | 13.5%             |
| Connected     | 8×8×3 | 22    | 11.5%             |
| Volume Intro  | 5×5×3 | 7     | 9.3%              |
| Volume Expert | 7×7×4 | 24    | 12.2%             |

These are proposed starting values, not validated difficulty settings. The volumetric modes intentionally start with lower density because the number of possible neighbors is much higher.

### Campaign structure

Chapter 1 — The Surface

Levels 1–8. Classic Minesweeper fundamentals, flags, zero propagation, and chording.

Chapter 2 — The Descent

Levels 9–16. Two and three independent floors, floor isolation, exploded views, and navigation.

Chapter 3 — Hidden Connections

Levels 17–24. Upward and downward clues, deductions that combine information across floors.

Chapter 4 — The Core

Levels 25–32. Full 3D adjacency, volume slicing, two-digit clues, and complex deduction.

Each chapter should contain one tutorial level, several normal puzzles, and a final challenge level. Completion unlocks the next chapter, but free-play mode should permit players to access any unlocked rule set.

### Puzzle solvability

The campaign's strongest quality requirement should be fair deduction.

A puzzle generator should:

1. Generate a deterministic mine layout from a seed, configured dimensions, and safe starting coordinate.
2. Compute each cell's clues using the selected rules.
3. Simulate deductions through a solver that understands those rules.
4. Reject layouts where the solver cannot finish without guessing.
5. Measure logical complexity and assign a difficulty score.

The solver should use a hierarchy of strategies: basic single-clue inference, overlapping constraint inference, and bounded constraint enumeration. For the MVP, avoid relying on brute-force solving of an entire large board.

For generation that cannot find a no-guess layout within its attempt budget, use a prevalidated campaign seed or report generation failure. Do not silently substitute a guessing-required board in a mode advertised as no-guess.

## 5. Visual design system

We should preserve the philosophy of Pixel Plays while designing original visuals specifically for Minesweeper.

### A. Art direction

[Voxel Art - Variados :: Behance](https://images.openai.com/static-rsc-4/fJ7cML7jf4aeEm9V37IOmjdDJ6hbImG4bDdn9FTKlAzciw8Y4sECBkRo_EfaBkqO9Bw546O13cW1060cvnVy3aqcB9H7AC79UCUV6vkWXyTkOkdtrloDT-eUCupqSVdTJ3V2ncZ7-_VR92So5mG81mnzhYC6GQwPS6em0h6kMQg?purpose=inline)

[Octree Cube | JuneLee Architecture](https://images.openai.com/static-rsc-4/3-VGo5pylKJX_odLcuUjHQg6fVUD5y9NaAYrDpax8iQqCMLg1LXz2vE6Xa5d7r3le3GgpoEWa1oQA0ykGdKyB4z-17EYUPl9NN2tpcWMKZ0GXQRov8FdZFLyR41AX5IOqCZhgEvpdlK8WrFKGe6Zqgz5e0dF3btbln_A_LS2uho?purpose=inline)

[［32×32］ドット絵　マップ素材　ゆめかわ - ドット絵　まゆ子 - BOOTH](https://images.openai.com/static-rsc-4/1M8LT4P_jvtdbnIaOuY3RITeZtYdmpCk1DaUBc5Mo51B6Yqikp2OJfkYyTmP1BVBjSdyHsnvzwsFlowsDCfGo7DExnKqNIq_6laVJTGU7NXb_7wZR8OaVKc9Ht9jkIL8dUlbA7DxRrnw4K_ZA3haNs2bRy7zuKiY5PcixiDAo5A?purpose=inline)

15

The game world should look like a handcrafted pixel-art sculpture.

The visual system should be based on six constraints:

- Pure-white or warm-white environment with no detailed backdrop.
- Fixed orthographic camera at the start of gameplay.
- Low-resolution pixel rendering with nearest-neighbor scaling.
- Limited per-material color ramps and directional lighting.
- Strong silhouettes with visible tile elevation.
- Small, deliberate animations that preserve pixel readability.

### B. Color palette

Canvas

\#FAF9F6

Unrevealed

\#C7D6BF

Revealed

\#E9DFC8

Tile edge

\#82998F

Shadow

\#817B9B

Highlight

\#F3DFAD

Flag

\#C56859

Ink

\#343B43

Proposed starting palette. Rendering shaders should derive several shades from each base color rather than using these colors alone.

Color must reinforce gameplay but should never be the sole means of communicating state. Mine numbers need distinct shapes or readable text, particularly for two-digit clues.

### C. Scene composition

Desktop layout blueprint

MINEFIELD

MINES 024

02:34

FLOOR 2 / 3

Conceptual composition, not a final rendered screenshot. The actual board will be a Three.js scene, with minimal HTML controls around it.

The layout should reserve most of the viewport for the puzzle. Controls appear along the outer edges rather than overlaying important tiles.

For phones, the top status bar should be condensed, the board should occupy the central area, and the most important actions should move to a bottom toolbar.

### D. Rendering specifications

| Property            | Recommendation                                                |
| ------------------- | ------------------------------------------------------------- |
| Camera              | Orthographic, \~30° elevation, 45° azimuth                    |
| Internal resolution | Adaptive, starting around 360×280                             |
| Upscaling           | Nearest-neighbor                                              |
| Materials           | Unlit or quantized diffuse shading                            |
| Shading             | Four discrete tonal levels                                    |
| Dithering           | 4×4 Bayer pattern                                             |
| Shadows             | Hard directional shadows, cast screen-right                   |
| Edges               | Dark depth-sensitive outlines with restrained warm highlights |
| Animation           | Short, stepped or pixel-snapped transitions                   |
| Color space         | Explicit sRGB output handling                                 |
| Background          | Warm white, no gradient                                       |

The dither should be applied selectively. Text, numbers, flags, and clue symbols must remain crisp, using a pixel font or pixel-compatible glyph atlas.

A key trade-off is resolution: a strict 360×280 internal render can make 8×8 or 10×10 boards unreadable. The pixel-art pass should therefore adapt to the number of visible cells and screen dimensions while preserving integer scaling where possible.

### E. Motion language

Use animation only when it communicates an event.

| Event         | Animation                                       |
| ------------- | ----------------------------------------------- |
| Reveal        | Tile lowers or flips, exposing the clue         |
| Flag          | Small flag rises with a short overshoot         |
| Zero cascade  | Sequential tile reveals across the neighborhood |
| Floor change  | Active floor highlights; others fade            |
| Explode stack | Layers move vertically apart                    |
| Rotate        | Camera snaps smoothly between 90° viewpoints    |
| Mine hit      | Brief impact, pixel particles, board freeze     |
| Win           | Completed structure gently rises and settles    |

Animations should be fast enough not to delay logical play. There should be a reduced-motion setting that removes unnecessary movement and transitions.

## 6. Interaction model

The player should be able to navigate complex puzzles without learning a complex control scheme.

### Desktop

| Action           | Control                                  |
| ---------------- | ---------------------------------------- |
| Reveal           | Left-click                               |
| Flag             | Right-click                              |
| Chord            | Middle-click or dedicated modifier       |
| Rotate           | Drag outside board or drag with modifier |
| Zoom             | Mouse wheel                              |
| Floor selection  | Number keys / floor selector             |
| Explode/collapse | `E`                                      |
| X-ray            | `X`                                      |
| Restart          | `R`, with confirmation                   |
| Pause            | `Esc`                                    |

### Mobile

A two-mode interaction system is safer than trying to overload gestures.

In Reveal mode, a tap reveals. In Flag mode, a tap toggles a flag. Long-press can optionally flag a tile, but the visible mode selector remains the primary control.

Dragging on an empty part of the scene rotates the board. Pinching zooms. The user can select floors through a persistent floor selector.

### Camera and layer visibility

The camera should offer three navigation presets:

FocusExplodeX-Ray

Focus: make one floor fully interactive and dim the others.

Important technical behavior: All picking must respect visibility and floor selection. A nearly transparent tile on an inactive floor must not intercept clicks intended for an active floor.

## 7. Technical architecture

### Recommended stack

| Layer       | Technology                               | Role                                     |
| ----------- | ---------------------------------------- | ---------------------------------------- |
| Language    | TypeScript                               | Strong typing for rules and game states  |
| Application | Vite + vanilla TypeScript                | Small, fast browser application          |
| Rendering   | Three.js                                 | 3D scene and camera                      |
| Effects     | Custom shaders / Three.js render targets | Pixelation, quantization, dithering      |
| UI          | HTML + CSS                               | Menus, overlays, settings, accessibility |
| State       | Dedicated game controller                | Deterministic state transitions          |
| Persistence | LocalStorage                             | Progress, settings, records              |
| Testing     | Vitest + Playwright                      | Logic correctness and browser behavior   |
| Hosting     | Static deployment                        | GitHub Pages or Vercel                   |

A framework such as React is optional, not necessary for the first version.

### System architecture

\#chatgpt-mermaid-\_r_86d\_{font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;font-size:14px;fill:rgb(13, 13, 13);}@keyframes edge-animation-frame{from{stroke-dashoffset:0;}}@keyframes dash{to{stroke-dashoffset:0;}}#chatgpt-mermaid-\_r_86d\_ .edge-animation-slow{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 50s linear infinite;stroke-linecap:round;}#chatgpt-mermaid-\_r_86d\_ .edge-animation-fast{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 20s linear infinite;stroke-linecap:round;}#chatgpt-mermaid-\_r_86d\_ .error-icon{fill:rgba(255, 255, 255, 0.96);}#chatgpt-mermaid-\_r_86d\_ .error-text{fill:rgb(13, 13, 13);stroke:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ .edge-thickness-normal{stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ .edge-thickness-thick{stroke-width:3.5px;}#chatgpt-mermaid-\_r_86d\_ .edge-pattern-solid{stroke-dasharray:0;}#chatgpt-mermaid-\_r_86d\_ .edge-thickness-invisible{stroke-width:0;fill:none;}#chatgpt-mermaid-\_r_86d\_ .edge-pattern-dashed{stroke-dasharray:3;}#chatgpt-mermaid-\_r_86d\_ .edge-pattern-dotted{stroke-dasharray:2;}#chatgpt-mermaid-\_r_86d\_ .marker{fill:rgba(13, 13, 13, 0.494);stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_86d\_ .marker.cross{stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_86d\_ svg{font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;font-size:14px;}#chatgpt-mermaid-\_r_86d\_ p{margin:0;}#chatgpt-mermaid-\_r_86d\_ .label{font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ .cluster-label text{fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ .cluster-label span{color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ .cluster-label span p{background-color:transparent;}#chatgpt-mermaid-\_r_86d\_ .label text,#chatgpt-mermaid-\_r_86d\_ span{fill:rgb(13, 13, 13);color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ .node rect,#chatgpt-mermaid-\_r_86d\_ .node circle,#chatgpt-mermaid-\_r_86d\_ .node ellipse,#chatgpt-mermaid-\_r_86d\_ .node polygon,#chatgpt-mermaid-\_r_86d\_ .node path{fill:rgb(222, 236, 248);stroke:rgb(1, 105, 204);stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ .rough-node .label text,#chatgpt-mermaid-\_r_86d\_ .node .label text,#chatgpt-mermaid-\_r_86d\_ .image-shape .label,#chatgpt-mermaid-\_r_86d\_ .icon-shape .label{text-anchor:middle;}#chatgpt-mermaid-\_r_86d\_ .node .katex path{fill:#000;stroke:#000;stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ .rough-node .label,#chatgpt-mermaid-\_r_86d\_ .node .label,#chatgpt-mermaid-\_r_86d\_ .image-shape .label,#chatgpt-mermaid-\_r_86d\_ .icon-shape .label{text-align:center;}#chatgpt-mermaid-\_r_86d\_ .node.clickable{cursor:pointer;}#chatgpt-mermaid-\_r_86d\_ .root .anchor path{fill:rgba(13, 13, 13, 0.494)!important;stroke-width:0;stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_86d\_ .arrowheadPath{fill:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_86d\_ .edgePath .path{stroke:rgba(13, 13, 13, 0.494);stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ .flowchart-link{stroke:rgba(13, 13, 13, 0.494);fill:none;}#chatgpt-mermaid-\_r_86d\_ .edgeLabel{background-color:rgb(255, 255, 255);text-align:center;}#chatgpt-mermaid-\_r_86d\_ .edgeLabel p{background-color:rgb(255, 255, 255);}#chatgpt-mermaid-\_r_86d\_ .edgeLabel rect{opacity:0.5;background-color:rgb(255, 255, 255);fill:rgb(255, 255, 255);}#chatgpt-mermaid-\_r_86d\_ .labelBkg{background-color:rgba(255, 255, 255, 0.5);}#chatgpt-mermaid-\_r_86d\_ .cluster rect{fill:rgba(255, 255, 255, 0.96);stroke:rgba(13, 13, 13, 0.08);stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ .cluster text{fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ .cluster span{color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ div.mermaidTooltip{position:absolute;text-align:center;max-width:200px;padding:2px;font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;font-size:12px;background:rgba(255, 255, 255, 0.96);border:1px solid rgba(13, 13, 13, 0.08);border-radius:2px;pointer-events:none;z-index:100;}#chatgpt-mermaid-\_r_86d\_ .flowchartTitleText{text-anchor:middle;font-size:18px;fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_86d\_ rect.text{fill:none;stroke-width:0;}#chatgpt-mermaid-\_r_86d\_ .icon-shape,#chatgpt-mermaid-\_r_86d\_ .image-shape{background-color:rgb(255, 255, 255);text-align:center;}#chatgpt-mermaid-\_r_86d\_ .icon-shape p,#chatgpt-mermaid-\_r_86d\_ .image-shape p{background-color:rgb(255, 255, 255);padding:2px;}#chatgpt-mermaid-\_r_86d\_ .icon-shape .label rect,#chatgpt-mermaid-\_r_86d\_ .image-shape .label rect{opacity:0.5;background-color:rgb(255, 255, 255);fill:rgb(255, 255, 255);}#chatgpt-mermaid-\_r_86d\_ .label-icon{display:inline-block;height:1em;overflow:visible;vertical-align:-0.125em;}#chatgpt-mermaid-\_r_86d\_ .node .label-icon path{fill:currentColor;stroke:revert;stroke-width:revert;}#chatgpt-mermaid-\_r_86d\_ .node .neo-node{stroke:rgb(1, 105, 204);}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].node rect,#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].cluster rect,#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].node polygon{stroke:url(#chatgpt-mermaid-\_r_86d\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].swimlane.cluster rect{filter:none;}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].node path{stroke:url(#chatgpt-mermaid-\_r_86d\_-gradient);stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].node .outer-path{filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].node .neo-line path{stroke:rgb(1, 105, 204);filter:none;}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].node circle{stroke:url(#chatgpt-mermaid-\_r_86d\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].node circle .state-start{fill:#000000;}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].icon-shape .icon{fill:url(#chatgpt-mermaid-\_r_86d\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_86d\_ [data-look="neo"].icon-shape .icon-neo path{stroke:url(#chatgpt-mermaid-\_r_86d\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_86d\_ .node text{font-size:14px;font-weight:600;letter-spacing:normal;fill:rgb(1, 105, 204);}#chatgpt-mermaid-\_r_86d\_ .edgeLabels text{font-size:13px;font-weight:600;letter-spacing:-0.08px;fill:rgb(1, 105, 204);}#chatgpt-mermaid-\_r_86d\_ .node tspan[font-weight="normal"],#chatgpt-mermaid-\_r_86d\_ .edgeLabels tspan[font-weight="normal"]{font-weight:600;}#chatgpt-mermaid-\_r_86d\_ .edgeLabel .label rect{opacity:1;rx:13px;ry:13px;fill:rgb(255, 255, 255);stroke:rgb(1, 105, 204);stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ .node rect,#chatgpt-mermaid-\_r_86d\_ .node circle,#chatgpt-mermaid-\_r_86d\_ .node ellipse,#chatgpt-mermaid-\_r_86d\_ .node polygon,#chatgpt-mermaid-\_r_86d\_ .node path{fill:rgb(222, 236, 248);stroke:rgba(0, 0, 0, 0.1);stroke-width:1px;}#chatgpt-mermaid-\_r_86d\_ .node rect{rx:16px;ry:16px;}#chatgpt-mermaid-\_r_86d\_ .mermaid-decision .label-container{fill:rgb(255, 255, 255);stroke:rgb(1, 105, 204);stroke-dasharray:2,2;}#chatgpt-mermaid-\_r_86d\_ .edgePaths .flowchart-link{stroke:rgba(13, 13, 13, 0.494);stroke-width:1px;stroke-linecap:round;stroke-linejoin:round;}#chatgpt-mermaid-\_r_86d\_ .marker{fill:rgba(13, 13, 13, 0.494);stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_86d\_ :root{--mermaid-font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;}Input ControllerGame ControllerPuzzle EngineTopology & Clue RulesGenerator & SolverGame StateThree.js SceneHTML UIPixel Render PipelinePersistenceLevel Configuration

The core design requirement is that the puzzle engine must know nothing about Three.js.

It should accept actions, evaluate rules, and return state changes. Three.js should only visualize those state changes.

This separation allows the same puzzle to be tested without a renderer, replayed deterministically, or eventually displayed in other visual formats.

### Suggested repository structure

```

3d-minesweeper/
├── public/
│   ├── fonts/
│   ├── audio/
│   └── icons/
├── src/
│   ├── main.ts
│   ├── core/
│   │   ├── types.ts
│   │   ├── board.ts
│   │   ├── topology.ts
│   │   ├── clueRules.ts
│   │   ├── generator.ts
│   │   ├── solver.ts
│   │   ├── reveal.ts
│   │   └── gameController.ts
│   ├── rendering/
│   │   ├── Scene.ts
│   │   ├── Camera.ts
│   │   ├── TileInstances.ts
│   │   ├── LayerView.ts
│   │   ├── Picking.ts
│   │   ├── PixelPass.ts
│   │   └── Animation.ts
│   ├── input/
│   │   ├── PointerController.ts
│   │   └── KeyboardController.ts
│   ├── ui/
│   │   ├── HUD.ts
│   │   ├── Menu.ts
│   │   └── Tutorial.ts
│   ├── progression/
│   │   ├── levels.ts
│   │   └── campaign.ts
│   ├── persistence/
│   │   └── storage.ts
│   └── styles/
├── tests/
│   ├── unit/
│   └── e2e/
├── index.html
├── package.json
└── vite.config.ts

```

### Core data model

A cell is identified by its position `(x, y, z)`, and the game maintains separate logical and visual states.

```

type GameMode =
  | "classic"
  | "layered"
  | "connected"
  | "volume";

type CellId = number;

interface Position3D {
  x: number;
  y: number;
  z: number;
}

interface Cell {
  id: CellId;
  position: Position3D;
  mine: boolean;
  revealed: boolean;
  flagged: boolean;
  clue: number;
  clueType: "local" | "above" | "below" | "volume";
}

interface LevelConfig {
  id: string;
  mode: GameMode;
  width: number;
  height: number;
  depth: number;
  mineCount: number;
  seed: string;
  firstReveal: Position3D;
  requireLogicalSolvability: boolean;
}

interface GameState {
  status: "ready" | "playing" | "won" | "lost";
  cells: Cell[];
  revealedCount: number;
  flaggedCount: number;
  elapsedMs: number;
  activeFloor: number;
  level: LevelConfig;
}

```

For larger boards, typed arrays can replace object-per-cell storage internally without changing the public game interface.

### Topology and adjacency

The most important abstraction is a topology-aware clue evaluator.

```

type Neighborhood = (
  position: Position3D,
  level: LevelConfig
) => Position3D[];

function volumeNeighbors(
  p: Position3D,
  level: LevelConfig
): Position3D[] {
  const result: Position3D[] = [];

  for (let dz = -1; dz <= 1; dz++) {
    for (let dy = -1; dy <= 1; dy++) {
      for (let dx = -1; dx <= 1; dx++) {
        if (dx === 0 && dy === 0 && dz === 0) {
          continue;
        }

        const x = p.x + dx;
        const y = p.y + dy;
        const z = p.z + dz;

        if (
          x >= 0 && x < level.width &&
          y >= 0 && y < level.height &&
          z >= 0 && z < level.depth
        ) {
          result.push({ x, y, z });
        }
      }
    }
  }

  return result;
}

```

The other neighborhood functions should use the same interface:

- `localNeighbors()` — eight possible neighbors on the same floor.
- `aboveNeighbors()` — up to nine cells on the floor immediately above.
- `belowNeighbors()` — up to nine cells on the floor immediately below.
- `volumeNeighbors()` — up to 26 cells in the 3D volume.

These functions are pure and can be unit tested exhaustively.

An important nuance: clue topology and zero-propagation topology should be configurable separately, even if the initial rules use the same neighborhoods. That prevents future rules from requiring changes to core game logic.

## 8. Rendering architecture

The recommended rendering pipeline is:

\#chatgpt-mermaid-\_r_876\_{font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;font-size:14px;fill:rgb(13, 13, 13);}@keyframes edge-animation-frame{from{stroke-dashoffset:0;}}@keyframes dash{to{stroke-dashoffset:0;}}#chatgpt-mermaid-\_r_876\_ .edge-animation-slow{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 50s linear infinite;stroke-linecap:round;}#chatgpt-mermaid-\_r_876\_ .edge-animation-fast{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 20s linear infinite;stroke-linecap:round;}#chatgpt-mermaid-\_r_876\_ .error-icon{fill:rgba(255, 255, 255, 0.96);}#chatgpt-mermaid-\_r_876\_ .error-text{fill:rgb(13, 13, 13);stroke:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ .edge-thickness-normal{stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ .edge-thickness-thick{stroke-width:3.5px;}#chatgpt-mermaid-\_r_876\_ .edge-pattern-solid{stroke-dasharray:0;}#chatgpt-mermaid-\_r_876\_ .edge-thickness-invisible{stroke-width:0;fill:none;}#chatgpt-mermaid-\_r_876\_ .edge-pattern-dashed{stroke-dasharray:3;}#chatgpt-mermaid-\_r_876\_ .edge-pattern-dotted{stroke-dasharray:2;}#chatgpt-mermaid-\_r_876\_ .marker{fill:rgba(13, 13, 13, 0.494);stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_876\_ .marker.cross{stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_876\_ svg{font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;font-size:14px;}#chatgpt-mermaid-\_r_876\_ p{margin:0;}#chatgpt-mermaid-\_r_876\_ .label{font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ .cluster-label text{fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ .cluster-label span{color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ .cluster-label span p{background-color:transparent;}#chatgpt-mermaid-\_r_876\_ .label text,#chatgpt-mermaid-\_r_876\_ span{fill:rgb(13, 13, 13);color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ .node rect,#chatgpt-mermaid-\_r_876\_ .node circle,#chatgpt-mermaid-\_r_876\_ .node ellipse,#chatgpt-mermaid-\_r_876\_ .node polygon,#chatgpt-mermaid-\_r_876\_ .node path{fill:rgb(222, 236, 248);stroke:rgb(1, 105, 204);stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ .rough-node .label text,#chatgpt-mermaid-\_r_876\_ .node .label text,#chatgpt-mermaid-\_r_876\_ .image-shape .label,#chatgpt-mermaid-\_r_876\_ .icon-shape .label{text-anchor:middle;}#chatgpt-mermaid-\_r_876\_ .node .katex path{fill:#000;stroke:#000;stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ .rough-node .label,#chatgpt-mermaid-\_r_876\_ .node .label,#chatgpt-mermaid-\_r_876\_ .image-shape .label,#chatgpt-mermaid-\_r_876\_ .icon-shape .label{text-align:center;}#chatgpt-mermaid-\_r_876\_ .node.clickable{cursor:pointer;}#chatgpt-mermaid-\_r_876\_ .root .anchor path{fill:rgba(13, 13, 13, 0.494)!important;stroke-width:0;stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_876\_ .arrowheadPath{fill:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_876\_ .edgePath .path{stroke:rgba(13, 13, 13, 0.494);stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ .flowchart-link{stroke:rgba(13, 13, 13, 0.494);fill:none;}#chatgpt-mermaid-\_r_876\_ .edgeLabel{background-color:rgb(255, 255, 255);text-align:center;}#chatgpt-mermaid-\_r_876\_ .edgeLabel p{background-color:rgb(255, 255, 255);}#chatgpt-mermaid-\_r_876\_ .edgeLabel rect{opacity:0.5;background-color:rgb(255, 255, 255);fill:rgb(255, 255, 255);}#chatgpt-mermaid-\_r_876\_ .labelBkg{background-color:rgba(255, 255, 255, 0.5);}#chatgpt-mermaid-\_r_876\_ .cluster rect{fill:rgba(255, 255, 255, 0.96);stroke:rgba(13, 13, 13, 0.08);stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ .cluster text{fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ .cluster span{color:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ div.mermaidTooltip{position:absolute;text-align:center;max-width:200px;padding:2px;font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;font-size:12px;background:rgba(255, 255, 255, 0.96);border:1px solid rgba(13, 13, 13, 0.08);border-radius:2px;pointer-events:none;z-index:100;}#chatgpt-mermaid-\_r_876\_ .flowchartTitleText{text-anchor:middle;font-size:18px;fill:rgb(13, 13, 13);}#chatgpt-mermaid-\_r_876\_ rect.text{fill:none;stroke-width:0;}#chatgpt-mermaid-\_r_876\_ .icon-shape,#chatgpt-mermaid-\_r_876\_ .image-shape{background-color:rgb(255, 255, 255);text-align:center;}#chatgpt-mermaid-\_r_876\_ .icon-shape p,#chatgpt-mermaid-\_r_876\_ .image-shape p{background-color:rgb(255, 255, 255);padding:2px;}#chatgpt-mermaid-\_r_876\_ .icon-shape .label rect,#chatgpt-mermaid-\_r_876\_ .image-shape .label rect{opacity:0.5;background-color:rgb(255, 255, 255);fill:rgb(255, 255, 255);}#chatgpt-mermaid-\_r_876\_ .label-icon{display:inline-block;height:1em;overflow:visible;vertical-align:-0.125em;}#chatgpt-mermaid-\_r_876\_ .node .label-icon path{fill:currentColor;stroke:revert;stroke-width:revert;}#chatgpt-mermaid-\_r_876\_ .node .neo-node{stroke:rgb(1, 105, 204);}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].node rect,#chatgpt-mermaid-\_r_876\_ [data-look="neo"].cluster rect,#chatgpt-mermaid-\_r_876\_ [data-look="neo"].node polygon{stroke:url(#chatgpt-mermaid-\_r_876\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].swimlane.cluster rect{filter:none;}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].node path{stroke:url(#chatgpt-mermaid-\_r_876\_-gradient);stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].node .outer-path{filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].node .neo-line path{stroke:rgb(1, 105, 204);filter:none;}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].node circle{stroke:url(#chatgpt-mermaid-\_r_876\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].node circle .state-start{fill:#000000;}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].icon-shape .icon{fill:url(#chatgpt-mermaid-\_r_876\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_876\_ [data-look="neo"].icon-shape .icon-neo path{stroke:url(#chatgpt-mermaid-\_r_876\_-gradient);filter:drop-shadow( 1px 2px 2px rgba(185,185,185,1));}#chatgpt-mermaid-\_r_876\_ .node text{font-size:14px;font-weight:600;letter-spacing:normal;fill:rgb(1, 105, 204);}#chatgpt-mermaid-\_r_876\_ .edgeLabels text{font-size:13px;font-weight:600;letter-spacing:-0.08px;fill:rgb(1, 105, 204);}#chatgpt-mermaid-\_r_876\_ .node tspan[font-weight="normal"],#chatgpt-mermaid-\_r_876\_ .edgeLabels tspan[font-weight="normal"]{font-weight:600;}#chatgpt-mermaid-\_r_876\_ .edgeLabel .label rect{opacity:1;rx:13px;ry:13px;fill:rgb(255, 255, 255);stroke:rgb(1, 105, 204);stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ .node rect,#chatgpt-mermaid-\_r_876\_ .node circle,#chatgpt-mermaid-\_r_876\_ .node ellipse,#chatgpt-mermaid-\_r_876\_ .node polygon,#chatgpt-mermaid-\_r_876\_ .node path{fill:rgb(222, 236, 248);stroke:rgba(0, 0, 0, 0.1);stroke-width:1px;}#chatgpt-mermaid-\_r_876\_ .node rect{rx:16px;ry:16px;}#chatgpt-mermaid-\_r_876\_ .mermaid-decision .label-container{fill:rgb(255, 255, 255);stroke:rgb(1, 105, 204);stroke-dasharray:2,2;}#chatgpt-mermaid-\_r_876\_ .edgePaths .flowchart-link{stroke:rgba(13, 13, 13, 0.494);stroke-width:1px;stroke-linecap:round;stroke-linejoin:round;}#chatgpt-mermaid-\_r_876\_ .marker{fill:rgba(13, 13, 13, 0.494);stroke:rgba(13, 13, 13, 0.494);}#chatgpt-mermaid-\_r_876\_ :root{--mermaid-font-family:Inter,-apple-system,"system-ui","Segoe UI",sans-serif;}3D Tile GeometryQuantized MaterialsOrthographic Scene RenderLow-Resolution RenderTargetSelective Dither / Edge PassNearest-Neighbor UpscaleFinal CanvasHTML HUD / TextScreen Composition

### Geometry

Use `InstancedMesh` for repeated tiles, with separate instance batches for opaque, transparent, and highlighted states.

Every tile consists of a simple beveled or extruded cube shape. The top surface represents the tile, while side faces provide physical depth.

For flags, mine icons, and numbers, use a small number of reusable geometries or textures. Avoid creating hundreds of unique geometries.

### Performance considerations

The renderer should have:

- Instanced tile geometry and pooled transient effects.
- Raycasting only when necessary, primarily on pointer events.
- A camera system that updates when navigation changes.
- Optional capped pixel rendering resolution on lower-end devices.
- Adaptive effects if frame rate degrades.
- Proper disposal of buffers, materials, and render targets on scene changes.

An initial performance target is 60 FPS on mainstream desktop hardware and 30–60 FPS on capable mobile devices, to be verified through testing.

### Text and glyph rendering

Numbers are central to Minesweeper. They cannot be treated as decorative labels.

For the first version, use a small pixel-compatible glyph atlas and render number glyphs on top of revealed cells. Ensure that two-digit clues remain legible.

For advanced modes, show the relevant neighborhood when a player selects a clue. This is particularly important when a clue represents 26 possible neighbors.

### Lighting and pixel fidelity

Use one main directional light, a restrained ambient contribution, and quantized shading.

To retain the Pixel Plays aesthetic, avoid conventional smooth PBR lighting. Hard shadows and controlled tonal ramps are more important than physical realism.

The goal is not to imitate the Pixel Plays software renderer line-for-line, but to produce a visually comparable result while preserving the flexibility of Three.js.

## 9. MVP scope

I recommend dividing the work into a core playable release and a hybrid progression milestone.

The core release establishes that the game is enjoyable and that the visual style works. The hybrid milestone demonstrates the actual product differentiation.

### Phase 1 — Game foundation

ENGINE AND PLAYABLE CLASSIC BOARD

MVP delivery checklist

0/24 completed

Phase 1 — Foundation

Set up Three.js + TypeScript + Vite

Create orthographic pixel-art renderer

Implement classic board, mine generation and safe first reveal

Implement reveal, flags, zero propagation, chord and win/loss states

Add HUD, restart, timer and mine counter

Add unit tests for classic rules

Phase 2 — Layered Boards

Support multiple independent floors

Add active floor selection and highlighting

Implement exploded and collapsed stack views

Implement floor-sensitive raycasting

Add navigation for mouse, keyboard and touch

Add save and resume

Phase 3 — Hybrid Logic

Implement above and below clue rules

Implement full 26-neighbor volume rules

Add clue neighborhood visualization

Implement logical solver for all rule types

Add curated campaign levels and progression

Validate no-guess puzzles and replayable seeds

Phase 4 — Release Quality

Implement adaptive pixel resolution

Polish tile animations and sound

Add tutorial onboarding

Add accessibility and reduced-motion support

Run desktop/mobile browser tests

Measure and improve rendering performance

Reset Copy checklist

### MVP feature boundary

| Feature                     | Initial playable release | Hybrid milestone |
| --------------------------- | ------------------------ | ---------------- |
| Classic Minesweeper         | Yes                      | Yes              |
| 3D pixel-art renderer       | Yes                      | Yes              |
| Multiple floors             | Yes                      | Yes              |
| Floor navigation            | Yes                      | Yes              |
| Cross-layer clues           | No                       | Yes              |
| 26-neighbor volume          | No                       | Yes              |
| Logical solvability testing | Basic validation         | Full solver      |
| Campaign                    | Introductory levels      | Four chapters    |
| Daily challenges            | Later                    | Later            |
| Multiplayer                 | No                       | No               |
| Puzzle editor               | No                       | No               |

The hybrid milestone is the first release that should be described publicly as a complete hybrid 3D Minesweeper experience.

## 10. Acceptance criteria and testing

### Puzzle engine

The logical core is release-ready when:

- Every generated board contains exactly the configured number of mines.
- The first reveal cannot trigger a mine.
- Local, vertical, and volumetric neighbor counts match independently calculated test fixtures.
- Boundary cells never count nonexistent neighbors.
- Zero propagation terminates correctly and never automatically reveals a mine.
- Chording uses the configured clue neighborhood and handles incorrect flags correctly.
- Winning requires revealing every non-mine cell.
- Seeds reproduce identical boards and clues under the same engine version.
- The campaign solver can complete every shipped no-guess level using supported logical deductions.

### Rendering and usability

The interactive experience is release-ready when:

- All visible tile states are distinguishable without relying on color alone.
- Camera rotation and layer explosion do not alter logical cell coordinates.
- Picking targets the intended tile, including when floors overlap.
- Occluded internal cells can be reached through slicing or floor isolation.
- Numbers remain legible on supported desktop and mobile viewports.
- Touch interactions do not accidentally reveal tiles during camera movement.
- Reduced-motion mode is honored.
- The game remains responsive at the largest supported MVP board size.

### Automated testing approach

Use Vitest for the pure game engine, seeded generation, state transitions, and topology rules. Add property-based tests for board invariants and adjacency symmetry where applicable.

Use Playwright for full-browser interaction: clicks, right-clicks, touch gestures, keyboard controls, save/resume, and campaign progression.

Visual regression tests should compare representative render states: unrevealed tiles, numbered tiles, flags, exploded layers, X-ray mode, and game-over state.

## 11. Key engineering risks

| Risk                                   | Severity | Mitigation                                           |
| -------------------------------------- | -------- | ---------------------------------------------------- |
| 3D cells are hard to inspect           | High     | Floor isolation and exploded view from the beginning |
| Small pixel numbers become unreadable  | High     | Adaptive resolution and glyph atlas                  |
| True 3D puzzles feel unfair            | High     | Solver-validated campaign puzzles                    |
| Special clues confuse players          | High     | Chapter tutorials and visible neighborhood previews  |
| Rendered cells intercept wrong clicks  | High     | Logical picking filters by active layer              |
| Too many visual effects reduce clarity | Medium   | Strict minimal design system                         |
| Solvability checking becomes expensive | Medium   | Bounded solver, offline generation and curated seeds |
| Mobile interactions feel awkward       | Medium   | Explicit reveal/flag modes and touch testing         |

Of these, I would prioritize validating layer interaction and puzzle solvability before spending substantial effort on decorative environments or animations.

## 12. Recommended execution strategy

I would build this as a standalone Three.js game inspired by Pixel Plays, rather than inserting it directly into the existing Pixel Plays engine.

That preserves the reference aesthetic while allowing us to support camera controls, transparent layers, instanced geometry, and true 3D interactions without fighting the assumptions of the original fixed-camera software renderer.

The implementation sequence should prioritize the logical engine first, a playable 3D board second, and the hybrid progression system third. Visual polish should be iterative, but the basic pixel-rendering pipeline should be established early so that all interaction decisions are tested against the intended appearance.

### Decisions to lock for development

| Product         | Standalone browser game                    |
| --------------- | ------------------------------------------ |
| Core experience | Classic → Layered → Connected → Volume     |
| Renderer        | Three.js + pixelation pipeline             |
| Style           | Minimal isometric pixel diorama            |
| Gameplay        | Logic-first, no guessing in campaign       |
| Architecture    | Pure puzzle engine separated from renderer |
| Launch target   | Responsive desktop and mobile web          |
| Backend         | None required for MVP                      |

The first substantial proof of concept should demonstrate three things together: a recognizable Pixel Plays-style floating board, smooth navigation through three physical floors, and Minesweeper mechanics that remain fully readable and predictable.

Once those work, the same architecture can support the more ambitious cross-layer and volumetric rule sets without redesigning the game from scratch.