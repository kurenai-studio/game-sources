# Algomind — Game App Screens

Concept renders of every screen in the Android game, in both themes (light and dark). They are design targets, not final art: fonts are placeholders and values will be tuned when the visual-design doc and tokens are written.

Overview sheets: [overview-light.png](overview-light.png) · [overview-dark.png](overview-dark.png)

Individual screens (390 × 844, 2x): `screens/light/` and `screens/dark/`.

| # | Screen | Purpose and states |
|---|---|---|
| 01 | Menu | Wordmark, hero board, Play (primary), Levels, Settings, Account |
| 02 | Worlds | List of worlds: solved, current, locked, and not-downloaded states; continue button |
| 03 | World | One world: its chapters, each with level tiles that carry a picture of the level's board, its number and its state (solved with stars, current, locked and faint); three tiles to a row. Concept renders: `screens/world-boards/` |
| 04 | Tutorial | Level 1 with a coach callout teaching the first command |
| 05 | Game, ready | Editing a program: tape, command palette, Step / Run / Reset |
| 06 | Game, running | Tape slides under the read-head; Continue, Step, Reset |
| 07 | Game, failed | Plain-language reason, hit wall marked, failing command marked, Edit program |
| 08 | Game, solved | Result stats (commands, steps, best), Next level, Replay, Levels |
| 09 | Hint | Hint text over the game, Next hint, Close |
| 10 | Pause | Resume (primary), Restart, How to play, Settings, Back to levels |
| 11 | Settings | Sound, music, vibration, reduce motion, run speed, theme (system / light / dark) |
| 12 | Sign in | Optional account; guest play is the default |
| 13 | Account | Signed in: sync status, progress summary, Sync now, Sign out, Delete account |
| 14 | Load error | Level could not load; Retry, play a downloaded level |
| 15 | Update required | Level needs a newer app version (unsupported mechanic or schema) |

## Not in this set

- **Leaderboard:** out of scope until the score and verification design exists.
- **Admin dashboard:** five key screens are rendered under `dashboard/` (below); the remaining dashboard screens (sign in, home, capabilities, import, audit log, settings) are listed in the dashboard plan and not yet rendered.
- **Motion:** the tape sliding, the read-head, and run animation are described in the design doc, not shown in still images.

## Depth concept (new theme, UI, and 2.5D board)

A whole-app concept, not only the board: chunky tiles and buttons with thickness, a recessed tape, a board plate with soft shadows, light and dark themes, and a patrolling guard with its route shown. It uses the depth tokens (`packages/design-tokens/tokens.json`, key `depth`), which are not yet used by the shipped screens. Plan: [../README_3D_VIEW_PLAN.md](../README_3D_VIEW_PLAN.md). Regenerate with `node scripts/concept-3d/depth.mjs`.

| Image | Light | Dark |
|---|---|---|
| Overview | [depth/overview-light.png](depth/overview-light.png) | [depth/overview-dark.png](depth/overview-dark.png) |
| Menu | [depth/light/01-menu.png](depth/light/01-menu.png) | [depth/dark/01-menu.png](depth/dark/01-menu.png) |
| Worlds | [depth/light/02-worlds.png](depth/light/02-worlds.png) | [depth/dark/02-worlds.png](depth/dark/02-worlds.png) |
| Game, ready | [depth/light/03-ready.png](depth/light/03-ready.png) | [depth/dark/03-ready.png](depth/dark/03-ready.png) |
| Game, running | [depth/light/04-running.png](depth/light/04-running.png) | [depth/dark/04-running.png](depth/dark/04-running.png) |
| Game, failed | [depth/light/05-failed.png](depth/light/05-failed.png) | [depth/dark/05-failed.png](depth/dark/05-failed.png) |
| Game, solved | [depth/light/06-solved.png](depth/light/06-solved.png) | [depth/dark/06-solved.png](depth/dark/06-solved.png) |
| Large boards (9 by 7, 12 by 10) | [depth/compare-large-board-light.png](depth/compare-large-board-light.png) | [depth/compare-large-board-dark.png](depth/compare-large-board-dark.png) |

### The depth look in the game (renders, not drawings)

Made by the game itself (`make game-shots`, Look: depth) on a Mac, in `depth/game/`: the menu ([light](depth/game/home-light.png), [dark](depth/game/home-dark.png)), the world list ([light](depth/game/worlds-light.png)), a world's levels ([dark](depth/game/world-dark.png)), the play screen ready ([light](depth/game/play-ready-light.png)), running at 412 wide ([dark](depth/game/play-running-dark-412.png)), failed ([dark](depth/game/play-failed-dark.png)) and solved ([light](depth/game/play-solved-light.png)), the biggest board on the smallest phone ([dark, 360 wide](depth/game/play-big-board-dark-360.png)), the hint ([dark](depth/game/hint-dark.png)), settings ([dark](depth/game/settings-dark.png)), sign-in ([light, 360 wide](depth/game/sign-in-light-360.png)), the leaderboard ([dark](depth/game/leaderboard-dark.png)), and badges ([light](depth/game/badges-light.png)).

### The public site in the depth look (real pages, Chrome)

In `depth/web/`: the landing page at [desktop](depth/web/landing-desktop-light.png) and as the drawn game screen on a phone ([390 light](depth/web/landing-screen-390-light.png)), the landing at 360 wide in dark with JavaScript disabled ([360 dark, no JS](depth/web/landing-360-dark-nojs.png)), the levels page ([390 light](depth/web/levels-390-light.png)), the download page ([390 dark](depth/web/download-390-dark.png)), and how to play ([390 light](depth/web/how-to-play-390-light.png)). The share image (the Open Graph and Twitter preview of every page) is drawn the same way: [share image](depth/web/share-image-light.png). The admin dashboard is unchanged and flat.

## 2.5D board concept (first try, superseded)

The first concept changed only the board and left the flat UI around it. The owner judged it did not look good. Its camera findings still hold; its screens are kept until the depth concept is decided.

Concept renders of the game screen with an extruded, flat-shaded board (proposal, not adopted; see [../README_3D_VIEW_PLAN.md](../README_3D_VIEW_PLAN.md)). Only the board differs from the screens above. Regenerate with `node scripts/concept-3d/render.mjs`.

| Image | Light | Dark |
|---|---|---|
| Overview | [3d/overview-light.png](3d/overview-light.png) | [3d/overview-dark.png](3d/overview-dark.png) |
| Game, ready | [3d/light/01-game-ready.png](3d/light/01-game-ready.png) | [3d/dark/01-game-ready.png](3d/dark/01-game-ready.png) |
| Game, running | [3d/light/02-game-running.png](3d/light/02-game-running.png) | [3d/dark/02-game-running.png](3d/dark/02-game-running.png) |
| Game, failed | [3d/light/03-game-failed.png](3d/light/03-game-failed.png) | [3d/dark/03-game-failed.png](3d/dark/03-game-failed.png) |
| Game, solved | [3d/light/04-game-solved.png](3d/light/04-game-solved.png) | [3d/dark/04-game-solved.png](3d/dark/04-game-solved.png) |
| Camera options | [3d/compare-camera-light.png](3d/compare-camera-light.png) | [3d/compare-camera-dark.png](3d/compare-camera-dark.png) |
| Large board (12 by 10) | [3d/compare-large-board-light.png](3d/compare-large-board-light.png) | [3d/compare-large-board-dark.png](3d/compare-large-board-dark.png) |

## Web renders

The public site is planned in [../README_WEB_PLAN.md](../README_WEB_PLAN.md). Renders (placeholders for version, size, hash, release notes, and QR):

| Page | Light | Dark |
|---|---|---|
| Landing, desktop | [web/light/landing-desktop.png](web/light/landing-desktop.png) | [web/dark/landing-desktop.png](web/dark/landing-desktop.png) |
| Landing, mobile | [web/light/landing-mobile.png](web/light/landing-mobile.png) | [web/dark/landing-mobile.png](web/dark/landing-mobile.png) |
| Download, desktop | [web/light/download-desktop.png](web/light/download-desktop.png) | [web/dark/download-desktop.png](web/dark/download-desktop.png) |
| Download, mobile | [web/light/download-mobile.png](web/light/download-mobile.png) | [web/dark/download-mobile.png](web/dark/download-mobile.png) |

## Dashboard renders

The dashboard is planned in [../README_DASHBOARD_PLAN.md](../README_DASHBOARD_PLAN.md). Renders at 1440 px wide (names and numbers are placeholders):

| Screen | Light | Dark |
|---|---|---|
| Levels | [dashboard/light/01-levels.png](dashboard/light/01-levels.png) | [dashboard/dark/01-levels.png](dashboard/dark/01-levels.png) |
| Level editor (Board tab) | [dashboard/light/02-editor.png](dashboard/light/02-editor.png) | [dashboard/dark/02-editor.png](dashboard/dark/02-editor.png) |
| Publish review | [dashboard/light/03-publish.png](dashboard/light/03-publish.png) | [dashboard/dark/03-publish.png](dashboard/dark/03-publish.png) |
| Version history | [dashboard/light/04-history.png](dashboard/light/04-history.png) | [dashboard/dark/04-history.png](dashboard/dark/04-history.png) |
| Campaign structure | [dashboard/light/05-campaign.png](dashboard/light/05-campaign.png) | [dashboard/dark/05-campaign.png](dashboard/dark/05-campaign.png) |
