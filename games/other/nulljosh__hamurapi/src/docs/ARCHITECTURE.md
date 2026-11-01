# Architecture

One game, four places to play it: a browser, a Mac, an iPhone and a terminal.

The rules are small. A city is a short record: the year, people, grain, land and the price of land. Each year you give three orders. The game checks the orders are possible, then plays the year: it pays for land, sets aside food and seed, rolls the harvest, lets the rats in, counts who starved, lets new people in, and maybe sends a plague.

Those rules are written three times, in Python, Swift and JavaScript. All three use the same random number generator (SplitMix64, with our own way of turning its output into dice), so one seed gives one game everywhere. Each port can print a single number for 200 robot games. The numbers must match. That is the guard against drift.

Everything else sits on top of the rules: the story, the robot king, the drawn city, the sound.

## The rules and the robot

| File | What it owns |
|---|---|
| `hamurapi.py` | The rules in Python: `check()` refuses bad orders, `step()` plays a year, `grade()` scores the reign. Also the terminal game and the `--demo` self-check. |
| `ruler.py` | The robot king. Three tuned knobs, the sweep that tuned them, `--bench` and `--golden`. |
| `app/App/Game.swift` | The same rules in Swift, plus the three difficulty levels. |
| `app/App/Ruler.swift` | The same robot in Swift. The demo and the tests use it. |
| `web/play/rules.js` | The same rules, robot and story logic in JavaScript. Run it with node to check the numbers. |

## The story

| File | What it owns |
|---|---|
| `art/story.json` | Every word of the story: the opening, two turning points, ten events with two choices each, four endings, four hints. The one place to edit. |
| `app/App/Story.swift` | Reads the story, picks the event for a year, applies a choice to the city. |
| `web/play/rules.js` | Does the same on the web (`omenFor`, `canAfford`, `applyChoice`). |

`art/build.py` copies `story.json` into the app and the web game, so both read the same file.

## The app (Mac and iPhone)

| File | What it owns |
|---|---|
| `app/App/GameModel.swift` | The game around the rules: title, story card, orders, report, grade. Modes, difficulty, saving, the demo, staged screenshots. |
| `app/App/Views.swift` | Every screen: the top bar, the panels, settings, how to play, credits. |
| `app/App/Scene.swift` | Draws the city from a snapshot of the game: sky, town, river, fields, people, the year playing out, weather. |
| `app/App/Sprites.swift` | Loads the sprite images by name. |
| `app/App/Theme.swift` | Colours, button styles, the glass panels. |
| `app/App/Feel.swift` | Music, sound effects and haptics. |
| `app/App/HamurapiApp.swift` | The app's one window. |
| `app/Hamurapi.icon` | The Icon Composer icon, in three layers. Built by `art/build.py`. |
| `app/Tests/HamurapiTests.swift` | The rules, the two golden numbers, the benchmarks, saving, the story, every sprite and sound. |
| `app/project.yml` | The xcodegen spec: one app for iOS 17 and macOS 14, one test bundle. |

## The web game and the site

| File | What it owns |
|---|---|
| `web/index.html` | The landing page. The top of it is the game itself. |
| `web/play/index.html` | The web game: screens, settings, saving, the demo. Mirrors `GameModel.swift` and `Views.swift`. |
| `web/play/scene.js` | Draws the city on a canvas. A line-for-line port of `Scene.swift`. |
| `web/play/sprites.png`, `sprites.json` | Every sprite on one sheet, and where each one sits. |
| `web/play/audio/` | The music and the sounds. |
| `web/play/manifest.webmanifest`, `sw.js` | Make the web game installable and playable with no internet. |
| `web/privacy.html` | The privacy page the store listing links to. |
| `web/trailer.mp4`, `web/shots/` | The trailer and screenshots on the landing page. |
| `wrangler.toml` | Serves `web/` at hamurapi.heyitsmejosh.com. Deploy with `npx wrangler deploy`. |

## The App Store

| File | What it owns |
|---|---|
| `metadata/` | The store name, subtitle, description and keywords. |
| `screenshots/iphone`, `screenshots/mac` | The store screenshots, taken by the two scripts in `art/`. |
| `.asc/workflow.json` | `asc workflow run ship-ios VERSION:x.y.z`, then `ship-mac`. |
| `app/ExportOptions-*.plist`, `app/Hamurapi-macOS.entitlements` | Signing and the Mac sandbox. |

## The art

Nothing here is drawn by hand or recorded. It is all code.

| File | What it owns |
|---|---|
| `art/build.py` | Draws every sprite as a grid of letters, shades and outlines them, writes them for the app and the web, draws the icon, copies the story. |
| `art/make_audio.py` | Writes the music loop and ten sound effects from sine waves and noise. |
| `art/shots_mac.sh`, `art/shots_ios.sh` | Take screenshots of staged moments on the Mac and in the simulator. |
| `art/trailer.sh` | Records the Mac app and cuts the trailer. |
| `art/qa_web.mjs` | Plays whole games in headless Chrome by clicking the real buttons, and checks the landing page. |

## Checks

`.github/workflows/test.yml` runs the Python self-check, a scripted terminal game, both golden numbers in Python and JavaScript, the Swift tests on a Mac runner, and a check that every file the README points at exists.
