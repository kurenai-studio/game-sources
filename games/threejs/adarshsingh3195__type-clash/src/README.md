# ⌨️ Type Clash — Type Fast. Fight Smart.

A 3D typing combat game for laptop/PC. Type each word, press **SPACE** to attack, and beat the CPU fighter.

**Play online:** `https://<your-username>.github.io/type-clash/` (replace with your link)

## Features
- Word-by-word typing engine: finish the word, then press SPACE (no auto-submit)
- Combos, critical hits, health bars, CPU opponent (Easy / Medium / Hard, target WPM 25–80)
- 4 arenas with their own scenery and fighter colours: Cyber Neon, Inferno, Frost, Toxic
- Live HUD: WPM, accuracy, mistakes, combo, on-screen keyboard
- Sound on/off, pause (Esc), level unlocks and bests saved in LocalStorage

## Two ways to run
| Version | Folder | How |
|---|---|---|
| Browser | root `index.html` | open it, or use GitHub Pages (needs internet for Three.js) |
| Windows desktop app | `desktop/` | see `desktop/README.md` (`npm install`, `npm start`, `npm run dist`) |

## How it works
- **Spacebar logic:** letters build a `typed` string; SPACE is the only submit key. If `typed === activeWord` the word is consumed once and one attack is queued, otherwise it counts as a mistake and resets the combo. Key-repeat is ignored and SPACE never scrolls the page.
- **Damage:** `(6 + wordLength × 0.9) × (1 + 0.1 × min(combo, 10))`, doubled on a critical hit (perfect word on every 5th combo step).
- **CPU AI:** attacks every `60 / (targetWPM × difficultySpeed)` seconds with random jitter; tunables are in the `CFG` object.
- **WPM:** `(characters in accepted words + spaces) / 5 / minutes`. **Accuracy:** correct keystrokes / total keystrokes.
- **Storage:** LocalStorage keys `tc1` (progress), `tc1s` (sound), `tc1t` (arena).

## Known limitations
Procedural fighters (no rigged models), no analytics screen or match history yet, simple Web Audio sounds, built for keyboards (not phones), not tested on every browser.

## Tech
HTML5, CSS3, JavaScript, Three.js r128, Web Audio API, LocalStorage, Electron (desktop build).
