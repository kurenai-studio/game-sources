# hamurapi

Hamurapi is Hamurabi (1968) as a game you can watch. The store name Hamurabi was taken, so the product is Hamurapi everywhere; only the credit to the 1968 game, the bundle ID `com.nulljosh.hamurabi`, the Worker name, the `HAMURABI_*` env vars and the web storage keys keep the old spelling. Web, Mac, iPhone, terminal. Public repo `nulljosh/hamurapi`, live at hamurapi.heyitsmejosh.com.

- The rules exist three times: `hamurapi.py`, `app/App/Game.swift`, `web/play/rules.js`. Change all three together. Two golden numbers prove they agree (639940 robot, 390695 story). If you change a rule, the dice order or the robot's knobs, recompute both and update every place they appear: `ruler.py --golden`, `rules.js` (GOLDEN, STORY_GOLDEN), `HamurapiTests.swift`, the CI workflow, README, WHITEPAPER
- Never use a language's own random functions in the rules. Use the SplitMix draws (`int`, `chance`). Today's game depends on one seed meaning one game everywhere
- `ruler.py` is the robot. `KNOBS` came from `--sweep`; rerun it if the rules change and copy the knobs to `Ruler.swift` and `rules.js`
- The scene is drawn twice: `app/App/Scene.swift` and `web/play/scene.js`. They are meant to match line for line. Change both
- Art is code. `python3 art/build.py` draws every sprite and the icon and copies `art/story.json` into the app and the web. `uv run --with numpy art/make_audio.py` writes the sounds. Never hand-edit files under `app/App/Sprites`, `web/play/sprites.*`, `app/Hamurapi.icon` or the two `story.json` copies
- Every word of the story lives in `art/story.json`. Plain words, short sentences, no em dashes
- `app/` is xcodegen (`xcodegen generate`, no checked-in xcodeproj). Staged screenshots: launch with `HAMURABI_SHOT=title|card|orders|report|plague|over`
- Test before pushing: `python3 hamurapi.py --demo && node web/play/rules.js && (cd app && xcodebuild test -scheme Hamurapi -destination platform=macOS)`. For anything on the web, also `node art/qa_web.mjs` with `python3 -m http.server 8765 --directory web` running
- A push deploys nothing. `npx wrangler deploy` ships `web/`. When web files change, bump `CACHE` in `web/play/sw.js`
- Docs: README, `docs/ARCHITECTURE.md` (a row per file), `WHITEPAPER.md` (the rules and the math). Update them in the same commit as the code
- No sand or beige in the art or the UI. Off-white, ink and the terracotta accent `#b5502c`

## The loop

Current state and next steps: `docs/LOOP-HANDOFF.md`.
