# Every wave, and who places it

**This file is generated. Do not edit it by hand.** `tools/build-level-docs.js` writes it from
`assets/data/waves.json` and every `assets/data/level-NN.json`, and `.github/workflows/ci.yml`
fails if it drifts.

`waves.json` is **one shared file across every level** and its ids are global. A new wave needs an
id nothing here already uses, and a wave already here can be placed again instead of copied — an
edit to it then lands on every placement below.

| wave | lasts | spawns | entities | archetypes | placed by |
|---|---|---|---|---|---|
| `l1-opening-calm` | 9.0 s | 2 | 2 | `enemy-basic` | `level-01` #1 at 0.0 s |
| `l1-first-basics` | 13.0 s | 5 | 11 | `enemy-basic` | `level-01` #2 at 9.0 s |
| `l1-light-and-fast` | 11.0 s | 6 | 10 | `enemy-light` | `level-01` #3 at 22.0 s |
| `l1-combined-formations` | 12.0 s | 7 | 17 | `enemy-basic` `enemy-light` | `level-01` #4 at 33.0 s |
| `l1-tanks-and-priority` | 12.0 s | 5 | 11 | `enemy-tank` `enemy-basic` `enemy-light` | `level-01` #5 at 45.0 s |
| `l1-super-fast` | 9.0 s | 6 | 8 | `enemy-rush` | `level-01` #6 at 57.0 s |
| `l1-heavy-carrier` | 15.0 s | 4 | 6 | `enemy-carrier` `enemy-light` `enemy-basic` | `level-01` #7 at 66.0 s |
| `l1-evolved-shooters` | 12.0 s | 5 | 11 | `enemy-shooter` `enemy-basic` | `level-01` #8 at 81.0 s |
| `l1-high-pressure` | 11.0 s | 8 | 20 | `enemy-basic` `enemy-light` `enemy-shooter` `enemy-rush` | `level-01` #9 at 91.0 s |
| `l1-twin-carriers-attachment` | 14.0 s | 7 | 9 | `enemy-carrier` `enemy-rush` `enemy-shooter` | `level-01` #10 at 100.5 s |
| `l1-brief-rest` | 6.0 s | 1 | 1 | `enemy-basic` | `level-01` #11 at 114.5 s |
| `l1-final-escalation` | 13.5 s | 12 | 30 | `enemy-basic` `enemy-light` `enemy-tank` `enemy-shooter` `enemy-rush` | `level-01` #12 at 120.5 s |
| `test-path-turn` | 12.0 s | 1 | 1 | `enemy-tank` | **unplaced** |
| `test-path-mirror` | 12.0 s | 2 | 2 | `enemy-tank` | **unplaced** |
| `test-path-wait` | 12.0 s | 1 | 1 | `enemy-tank` | **unplaced** |
| `test-path-loop` | 15.0 s | 1 | 1 | `enemy-tank` | **unplaced** |
| `test-path-oscillate` | 13.0 s | 1 | 1 | `enemy-tank` | **unplaced** |
| `test-cross` | 9.0 s | 2 | 2 | `enemy-basic` | **unplaced** |
| `test-slide-descend` | 10.0 s | 2 | 2 | `enemy-basic` | **unplaced** |
| `test-dive-retreat` | 12.0 s | 1 | 1 | `enemy-basic` | **unplaced** |
| `test-hold-line` | 10.0 s | 1 | 1 | `enemy-shooter` | **unplaced** |
| `test-sweep-width` | 11.0 s | 1 | 1 | `enemy-shooter` | **unplaced** |
| `test-basic-family` | 16.0 s | 3 | 3 | `enemy-basic` | **unplaced** |
| `test-light-family` | 12.0 s | 4 | 4 | `enemy-light` | **unplaced** |
| `test-shooter-family` | 16.0 s | 2 | 2 | `enemy-shooter` | **unplaced** |
| `test-rush-family` | 17.0 s | 5 | 5 | `enemy-rush` | **unplaced** |
| `test-tank-family` | 20.0 s | 3 | 3 | `enemy-tank` | **unplaced** |
| `test-carrier-family` | 30.0 s | 3 | 3 | `enemy-carrier` | **unplaced** |

**`unplaced`** is a wave no level uses. Not an error — `waves.json` is a library — but it is dead
content until something places it, and nothing else in the repository would tell you.

Archetypes come from `assets/data/enemies.json` (6 of them) and formations from `assets/data/formations.json`.
Each level's own document has the rest: the pacing, the roster, the checks.
