# Fordline — history

What was built when, and the decisions along the way. The commit messages
hold the detail; this is the thread through them. Dates are the owner's
local time.

## 30 October 2026: a playable game first

| Commit | What |
|---|---|
| `0cab6d9` | The first playable build, 39 minutes after the first message: a five-battle campaign of river crossings, flags and resolve, flank and rear hits, rally, rewards between battles; a phone layout; a web build; 1,204 checks |
| `3eb5e33` | A study of luck against skill, and the first fixes from it: slower fights, red arrows for enemy intent, morale on the field |
| `80617df` | Fatigue, an enemy line that keeps its share of the front, a reserve |
| `f5b013a` | Waypoints, in the owner's tap scheme rather than the first proposal |
| `ed0abac` | Quick battle: five scenarios, three stars each |
| `60b3e17` | Published from CI to GitHub Pages, as an installable web app |

Decisions: Godot, so one codebase serves phones and the web. The look is
the toy: hundreds of soldiers in blocks. Measure balance with computer
players of rising skill instead of guessing it.

## 31 October: open source, eras and castles

| Commit | What |
|---|---|
| `5fdff05` | One public repo under MIT, built and published by CI |
| `a9b2bf1` | Map previews on every briefing, an in-battle menu, an enemy that moves up to hold its flags |
| `d0d17b7` | Pike and Shot: muskets, era tabs, five scenarios |
| `bfa56d2` | Sieges: walls, gates to ram or bombard, a garrison AI, three siege battles |

Decisions: packs by era; combat only, no economy or building; the
designer's free hand on content, with quick battles as the place to try
variants.

## 1 November: grand battles, an architecture, and measuring for real

| Commit | What |
|---|---|
| `c1678a8` | A drag became an arrow (stand here, face that way) on every device; grand battles: a field bigger than the screen with a camera and minimap, armies arriving by road, divisions on their own command, Gettysburg's first day and Waterloo, squares against horse |
| `1ad2c28` | The architecture: a core engine, modules, content packs, every one a two-way door; air as things in flight between ground units, aircraft as flights that come back, navies as units on water; history serves the fun |
| `f545ff5` | One loop for every battle: the tests had been stepping at 1/15 s while the game steps at 1/30, a different game (6 of 15 campaign battles changed winner). Order logs and replays, 44 recorded battles, measures of play per time horizon, the AI audit |
| `fcfd310`, `c00ef9c` | Recorded battles per platform: Linux and macOS differ in the last bits of their maths, and the battle grows them into different outcomes |
| `8224604` | Ten bugs from a bug hunt (input over the minimap and the bars, Two Narrow Bridges, a general mourned twice, texts, saves, a way out of a campaign) and a fixed warning measure |

Decisions: keep the core the game we started with; a rule that data
switches on is core, a whole mechanic is a module; fail when a battle is
built, never silently; no reinforcement learning yet, a planner first.

## 2 November: documentation and sharing

The docs map ([`README.md`](README.md)) and this history. The owner's
prompt log moved to his private notebook, reached here through a
gitignored symlink, the way his other projects share with it.

## Open

- A better AI (line concentration, holding ground, a person-paced
  commander, an in-battle planner): `tsleung/fordline` pull request 1.
- The architecture's migration past step 2 (kinds as data, packs,
  fortifications as the first module): `ARCHITECTURE.md`, "Migration".
