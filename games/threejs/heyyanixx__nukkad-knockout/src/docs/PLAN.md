# PLAN: "Nukkad Knockout" — my own simpler fighter (inspired by browser fighting games)

## Why this stack
fightkaro uses Three.js + 5 MB of 3D models. For a simpler, fast-loading version a **2D HTML5 Canvas + vanilla JavaScript (ES modules), built with Vite** is the best fit: no engine, ~30 KB total, works on cheap phones, easy for a BCA student to read and change. Fighters are drawn procedurally (shapes), sounds are generated with WebAudio — zero image/audio files to license.

## Scope (v1)
- 10 fighters (fictional archetypes; Carry Mintu is a labelled parody; HEYY ANISH = owner as secret boss): Chaiwala Chhotu, Auto Anna, Dadi No. 1, Headshot Hero, Jelly Wall Jojo, Loot Goblin, Streamer Sid, Vlogger Vicky, Carry Mintu, HEYY ANISH. Each: own speed / jump / damage / reach / meter gain + own move names + a unique super.
- Modes: 1P vs CPU (Easy/Normal/Hard), 2P on one keyboard.
- Moves: walk, jump, crouch, block (hold back; crouch-block for lows), punch, kick, grab (+ throw break), specials →P, →K, ↓K sweep, combos P,P,P · P,P,K · K,K, air punch/kick, super at 100 % meter.
- Rules: 60 fps fixed step, 100 HP, 60 s timer, best of 3, combo scaling, meter gain on hit/block, KO slow-mo, time-over decision.
- Screens: title → select (fighter, opponent, mode, CPU level, stage) → fight → pause → round/KO banners → win screen (rematch / select).
- 3 stages: Chai Tapri Night, Patang Terrace, Nukkad Junction (railway) + random chaos events (cow, power cut, rain, kite, lag, low gravity).
- Mute + music toggle, WebAudio SFX and a simple beat.
- Mobile: touch stick + 4 buttons, landscape, rotate prompt, PWA (manifest + service worker = installable + offline).
- Skipped (future): online play (WebRTC DataChannel + a tiny signalling server), more fighters, sprite art.

## Files
```
index.html            screens + canvas + touch UI
src/main.js           boot, screen flow, game loop (fixed 1/60 step)
src/fighter.js        Fighter class: state machine, physics, attacks
src/moves.js          frame data table + combo chains
src/roster.js         4 fighters (stats, colours, names)
src/combat.js         hit detection, blocking, damage, meter
src/ai.js             CPU brain with 3 difficulty profiles
src/input.js          keyboard (P1/P2 maps) + touch → same input object
src/render.js         drawing fighters, stages, effects
src/hud.js / audio.js HUD bars/timer, WebAudio SFX + music
public/manifest.webmanifest, public/sw.js, public/icons
test/*.test.js        node --test unit tests for the logic
```

## Steps
1. Logic first (moves, fighter, combat, ai) as pure modules → unit tests with `node --test`.
2. Rendering + HUD + screens → play in a real browser (headless Chrome via Playwright) with scripted keyboard and touch input; check FPS, hits, blocks, AI, rounds.
3. PWA + mobile polish → screenshots desktop + phone landscape.
4. Publish to heyyanixx-fight.sites.tab.bot, push the source to a new GitHub repo with README (Hinglish + English) and MIT licence.
