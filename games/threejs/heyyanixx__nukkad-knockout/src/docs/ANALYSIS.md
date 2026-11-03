# REA: fightkaro.com ("Sansad Showdown — Indian Politics Fighter")

Read on 1 Nov 2026 (IST) by passive inspection only: the public HTML, its JS/CSS bundles, the web manifest, response headers and the requests a normal browser makes on load. No fuzzing, no auth bypass, no use of the multiplayer backend.

## 1. What it is
A browser fighting game, "Tekken-style 3D fighting game parody of Indian politics" (its own manifest says this). Plays in landscape on phones (touch stick + buttons) and on desktop with a keyboard. Credit link on the select screen: Instagram @shivmbuilds.

## 2. Features seen
- Screens: Loading ("Loading neta assets…") → Title ("PRESS ENTER / CLICK TO START", "TAP TO START") → Character select → Fight → Result → Rematch / Character select.
- Roster: 6 playable caricatures (modi, rahul, didi, trump, yogi, nitin) + a locked BOSS (mbapu) + RANDOM tile. Each fighter has a name per move (e.g. "GST SWEEP!") and its own super cinematic.
- Stages: Sansad, Jantar Mantar, Desi Sadak (key T cycles).
- CPU difficulty: Easy / Normal / Hard (keys 1/2/3).
- HUD: portraits, HP bar with a red "trail", round-win pips, 60 s timer, combo counters, "SHAKTI" super meter per side, pause button, a "news desk" ticker gag (two TV anchors commenting live).
- Pause = "CHAI BREAK ☕" (Resume / Sound on-off / Quit to select).
- Result = a fake newspaper front page ("THE DAILY JUMLA") with headline, photo, caption and a "YOU WIN!" stamp.
- Online: "PLAY WITH A FRIEND" → Host a room (code, Share on WhatsApp, Copy link) or Join with a code.
- Extras: "SHANTI" peace meter (a pacifist challenge: stand close without attacking for 20 s / block 5 times), boss unlock stats saved in localStorage (`sansad-showdown:bapu-v1`), rotate-phone prompt, iPhone "swipe up / Add to Home Screen" tip, haptics via `navigator.vibrate` on mobile, dynamic resolution drop on slow phones.

## 3. Controls (from the page's own help text)
Keyboard: A/D move, W jump, S crouch, hold back = block, J punch, K kick, I or J+K grab, L/Space super, Esc pause, M music, N mute.
Specials: →J, →K, ↓K (sweep). Combos: J,J,J · J,J,K · J,K,K · K,K · ↓J,J · ↓J,K.
Touch: virtual stick (up = jump, down = crouch, back = block) + PUNCH / KICK / GRAB / SUPER buttons.

## 4. Tech stack
| Layer | What it uses | Evidence |
|---|---|---|
| Build | Vite (hashed `/assets/*-hash.js`, modulepreload polyfill) | file names, preload polyfill code |
| Language | TypeScript compiled to ES modules (Babel class-field helpers) | bundle shape |
| Rendering | **Three.js r186** (WebGL), shadows, tone mapping, particles, shockwaves | `three-BbEF-ZsN.js` (698 KB) carries REVISION "186" |
| Models | Rigged **GLB** characters, Draco-compressed, separate lighter mobile set | `/models/modi.glb` 2.67 MB, `/models/mobile/modi.glb` 1.45 MB, `draco_decoder.wasm` |
| Animation | Named clips per move (jab, cross, uppercut, palm, flyingkick, sweep, throw, hurricane…) time-mapped onto frame data | clip table `{clip,start,hit,end}` |
| UI | Plain HTML/CSS overlays on top of one `<canvas id="game">`, Google Fonts (Bebas Neue, Teko) | index.html |
| Audio | WebAudio, ~55 mp3 SFX + music beds, suspended when tab hidden | 115 mp3 references, AudioContext |
| Online | **WebRTC DataChannels** peer-to-peer: `ctrl` (ordered) + `input` (unordered, `maxRetransmits:0`); signalling by HTTP long-poll to `/api/room` (create / join / answer / poll / close, room codes ≤6 chars, room expiry 10 min); ICE/TURN list from `/api/ice`; ICE restart on drop | `rooms-DUFxC0eJ.js` (13 KB) |
| Hosting | Vercel (static + serverless `/api/*`) | `server: Vercel`, `x-vercel-*` headers |
| Analytics | Google Analytics 4 (`G-8K3H62CSPH`), click events on every button | gtag code, network log |
| PWA | Web manifest (fullscreen, landscape, icons 192/512). **No service worker** (`/sw.js` → 404), so no offline play | manifest + 404 |

Total first load on desktop: ~1.1 MB JS (three + game + rooms) + 46 KB CSS + 2 GLB models (~5 MB) + faces PNGs (~80 KB each).

## 5. Game mechanics (numbers read from the bundle)
- Fixed simulation step **1/60 s**; frame data in frames. Arena half-width 6.5 units; fighters push each other apart under 0.72 units.
- HP 100 (boss 200, boss also gets 1 revive and takes ×0.65 damage).
- Round timer **60 s**, first to **2 round wins** (draw gives both a win).
- Damage = base × character damageMul (e.g. 1.08) × combo scaling **max(0.5, 0.88^comboHits)**.
- Meter 0–100: on hit attacker +(dmg×0.9 + 2), defender +(dmg×0.6); on block attacker +2, defender +3. Super needs 100.
- Blocking: hold back while grounded; standing block stops high + mid, crouch block stops low only. Throws can't be blocked; pressing grab during the opponent's grab startup = **throw break**.
- Throws: per-character cinematic, 12–16 damage.
- Move table (startup / active / recovery frames, damage, height):

| Move | Input | S/A/R | Dmg | Height | Notes |
|---|---|---|---|---|---|
| jab | J | 5/3/10 | 5 | high | chains → cross (J) or kick (K) |
| cross | J,J | 6/3/12 | 6 | high | chains → uppercut (J) / finisher (K) |
| uppercut | J,J,J or ↓J,J | 9/4/20 | 11 | mid | knockdown, launch |
| kick | K | 9/4/15 | 9 | mid | chains → roundhouse (K) |
| roundhouse | K,K | 11/5/22 | 13 | high | knockdown, big push |
| finisher | J,J,K | 10/4/20 | 12 | mid | knockdown |
| lowJab | ↓J | 6/3/11 | 4 | low | chains → uppercut / sweep |
| sweep | ↓K | 11/4/20 | 8 | low | knockdown |
| special1 | →J | 13/4/19 | 13 | mid | lunge 1.8, knockdown |
| special2 | →K | 15/5/20 | 14 | mid | flying kick, knockdown |
| airPunch / airKick | J/K in air | 4–6/30/0 | 7 / 10 | mid | one per jump |
| grab | I or J+K | 6/3/24 | — | — | reach 0.95 |

- CPU AI = a "plan" state machine (approach, wait, retreat, block, lowBlock, jumpIn, attack sequences, super) re-decided every *reaction* seconds:

| Level | reaction | blockChance | punishChance | aggression | breakChance | superChance |
|---|---|---|---|---|---|---|
| easy | 0.42 s | 0.18 | 0.20 | 0.45 | 0.08 | 0.35 |
| normal | 0.26 s | 0.45 | 0.50 | 0.65 | 0.30 | 0.70 |
| hard | 0.14 s | 0.75 | 0.85 | 0.80 | 0.60 | 1.0 |

The boss additionally "reads" incoming attacks (85 % chance) and blocks low/high correctly.

## 6. Architecture (inferred)
`main.ts` boots Three.js renderer + scene → asset loader (GLB per fighter, on demand, with a "DOWNLOADING NETA…" bar) → screen state machine (`title | select | online | battle | result`) → `Battle` (round manager: wins, round, timer) → two `Fighter` objects (state: idle/walk/crouch/jump/attack/hitstun/blockstun/knockdown/getup/ko/super/victory, input buffer, meter) + `CpuBrain` or a remote input source → collision/hit resolver (reach + height check, trade rules, grab priority) → renderer/animation mapping + particles + HUD DOM updates. Online play sends inputs over the unreliable DataChannel (input-sync style netcode; exact delay/rollback scheme not visible in the minified code).

## 7. What I could not determine
- The server code behind `/api/room` and `/api/ice` (serverless, not public) and which TURN provider it uses. I did not call the backend beyond what the page does on load.
- Exact online netcode (input delay vs rollback): the minified bundle doesn't make it clear and I didn't play an online match.
- Exact super damage per character (each super is its own cinematic class).
- Art pipeline for the GLB characters (likely AI/3D-generated heads on a shared rig; not provable from the files).

## 8. Screenshots
`fk-1-title.png`, `fk-2-select.png`, `fk-3-fight.png`, `fk-4-attack.png` in this folder (headless Chrome, 1280×720, software WebGL so the frame rate there is not representative).
