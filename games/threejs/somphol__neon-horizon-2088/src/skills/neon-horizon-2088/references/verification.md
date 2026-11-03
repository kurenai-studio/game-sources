# Verification

Two layers: static checks that can run anywhere, and a browser matrix that must be run
against a live page. The release used headless Chrome with SwiftShader over CDP; the full
harness is **not** packaged, so treat the browser rows as a procedure, not an automated
suite.

## 1. Static checks

```sh
cd ~/Projects/neon-horizon-2088
node --check script.js
node scripts/check.mjs
node ~/.config/opencode/skills/skill-publish/scripts/check-skill.mjs skills/neon-horizon-2088
```

Expected:

```text
OK <n> checks
OK neon-horizon-2088 — "neon-horizon-2088", <n> files, <x.xx> MB
```

Reference release: `OK 93 checks` and `OK neon-horizon-2088 — "neon-horizon-2088", 8 files, 0.22 MB`.

`scripts/check.mjs` asserts:

- required files exist (`index.html`, `style.css`, `script.js`, `README.md`, `AGENTS.md`,
  `LICENSE`, `.nojekyll`, the four docs, the skill files, the social card);
- every local `src`/`href` in `index.html` resolves;
- every relative Markdown link in the root docs, `docs/` and `skills/` resolves;
- `node --check` passes for every `.js`/`.mjs` file;
- every `.json` file parses;
- the skill template contains exactly `index.html`, `style.css`, `script.js` and each is
  byte-identical to the release source;
- `SKILL.md` has frontmatter with `name`, a description of at least 20 characters and a
  `version`;
- no Markdown under `docs/` or `skills/` contains an absolute personal home path;
- `README.md` links all five release docs and the skill.

An exit code of 1 prints one `FAIL` line per problem and a `FAILED …` summary. The check
does not test physics, rendering or audio.

Template integrity can also be checked directly:

```sh
cmp index.html skills/neon-horizon-2088/assets/template/index.html
cmp style.css  skills/neon-horizon-2088/assets/template/style.css
cmp script.js  skills/neon-horizon-2088/assets/template/script.js
```

All three must be silent (exit 0).

## 2. Serve and self-test

```sh
python3 -m http.server 8080
# open http://localhost:8080/?selftest=1
```

Expected console output:

```text
[NEON HORIZON self-test] 16/16
NEON HORIZON 2088 online · Three.js r128 · Cannon.js 0.6.2
```

Expected globals:

```js
window.__SELFTEST__.pass === 16
window.__SELFTEST__.total === 16
window.NEON_HORIZON.version === "1.0.0"
```

The 16 checks: score formatter, time formatter, callsign sanitiser, Three.js loaded,
Cannon.js loaded, table group tilted, three plasma cores, four drop targets, two
hyper-loops, two flippers, ball collider, physics world, leaderboard storage, scores
serialisable, audio synthesiser and export filename.

If the boot screen says `SYSTEM FAULT`, the CDN libraries did not load; the self-test
cannot run.

## 3. Browser matrix

Run each row on the live page. "Reference run" records what was verified for v1.0.0 in
headless Chrome; it is not re-executed by `scripts/check.mjs`.

| # | Check | How | Expected | Reference run |
| --- | --- | --- | --- | --- |
| 1 | Boot | load `/` | Hero overlay, HUD live, no console exception | pass |
| 2 | Start | enter callsign, submit | Start overlay leaves; 3 balls; phase `ready` | pass |
| 3 | Charge/launch | hold Space ~1.4 s, release | Charge reaches ~100%, ball travels up the shooter lane, phase `play` | pass |
| 4 | Launch pad | hold the **LAUNCH** pad, drag up, release | Same as #3; touch pointer events | hold/release pass; drag boost not separately measured |
| 5 | Left flipper | `Z` or `←` | Left arm sweeps up; ball redirects | pass |
| 6 | Right flipper | `/` or `→` | Right arm sweeps up; ball redirects | pass |
| 7 | Touch flippers | tap/click canvas halves or flip pads | Corresponding flipper fires | pass |
| 8 | Bumper | drive ball into a core | Flash, sparks, +500 × multiplier, outward kick | pass |
| 9 | Drop targets | hit one, then clear four | Node sinks (+900); bank clear +5000, multiplier +1, re-arm after 3 s | pass |
| 10 | Hyper-loop | send ball into the lit entrance | Capture, rail ride, exit bonus (+2500 / +500), ball returns | pass |
| 11 | Slingshot | hit a sling | Inward/up-table kick, +120 | pass |
| 12 | Drain | send ball through the centre gap | Ball lost, countdown, respawn with ball count decremented | pass |
| 13 | Game over | lose three balls | Summary modal, final score, archive rank, score in leaderboard | pass |
| 14 | Recovery | park the ball in a corner for 3.5 s | Ball returns to railgun; ball count unchanged; toast after recovery | pass |
| 15 | Manual recovery | press `R` / **RECOVER STUCK BALL** | Same as #14, immediate | pass |
| 16 | Escape recovery | force the ball outside the table | Returns to railgun without losing a ball | pass |
| 17 | Wall rebound | shoot into left and right walls | Horizontal velocity reverses; ball stays on table | pass |
| 18 | Wall stress | 60 units/s shots at left, right, top, lower-side walls | Left/right/top stay within `x ±4.58`, `z ≥ -10.45`; a lower-seam escape recovers to the railgun | pass |
| 19 | Target re-arm | park a ball on the bank, clear it | Re-arm deferred until the ball leaves | not separately verified (guard in `resetTargets`) |
| 20 | Export | **SAVE HIGH SCORE** | Downloads `neon_horizon_scores.json`; valid JSON | pass |
| 21 | Import | load an archive with valid and invalid entries | Valid entries merge; negative/markup entries are sanitised or rejected | pass |
| 22 | Persistence | reload after a session | Callsign, mute and leaderboard survive; a fresh table starts | pass |
| 23 | Mute | `M` or audio button | Master muted/unmuted; preference persists | pass |
| 24 | Audio lifecycle | first gesture, then hide the tab | Context starts; ambient drops on hidden and returns | context pass; visibility not separately verified |
| 25 | Help/pause | `H`, then close | Help opens, game pauses, resume restores play | pass |
| 26 | Desktop layout | 1600 × 1000 | Left controls and right scores panels visible | pass |
| 27 | Tablet layout | 768 × 1024 | Left panel hidden; right panel below 1080 | pass |
| 28 | Mobile layout | 390 × 844 | Touch pads visible; scores drawer opens; no horizontal overflow | pass |
| 29 | Small mobile | 320 × 568 | HUD fits; launch/flip reachable; no overflow | pass |
| 30 | Exceptions | DevTools/CDP during a 30 s run | 0 uncaught exceptions, 0 console errors | pass |

The reference run also did a 25-second random run with no side drains and a 30-second
aggressive random-flipper run with no out-of-table ball or floor fall-through.

## 4. Ad-hoc probes

With the page loaded, the automation surface allows deterministic probes:

```js
// Snapshot
NEON_HORIZON.getSnapshot();
// { phase, score, multiplier, balls, targetsDown, loops, bumperHits, best, entries,
//   charge, ball: { x, y, z, vx, vy, vz, onRail, visible } }

// Start and launch
NEON_HORIZON.startGame();
NEON_HORIZON.launchBall(0.8);

// Place a ball and set a velocity (debug only)
const b = NEON_HORIZON._debug.ballBody;
b.type = 1; b.mass = 0.25; b.updateMassProperties(); b.collisionResponse = true;
b.position.set(0, 0.4, 2.5); b.velocity.set(0, 0, -8);
b.wakeUp();
NEON_HORIZON.game.phase = "play";
```

Expected after a wall shot: `getSnapshot().ball.x`/`z` remain inside the hard boundary and
the corresponding velocity component reverses sign. Expected after the recovery probe:
`phase` returns to `ready` and the ball sits near `(4.3, 0.35, 9.35)`.

## 5. Release checks

```sh
node scripts/check.mjs
git status --short
git log --oneline -1
git push origin main
```

Then verify over HTTPS:

```sh
curl -s -o /dev/null -w '%{http_code}\n' https://somphol.github.io/neon-horizon-2088/
curl -s -o /dev/null -w '%{http_code}\n' https://somphol.github.io/neon-horizon-2088/script.js
```

Both `200`. Open the live `?selftest=1` and repeat the 16/16 check; Pages may serve the
previous build for a short window.

## 6. What this does not prove

- Safari, Firefox and real mobile GPUs.
- Subjective audio mix quality or loudness.
- Screen-reader usability; the canvas is `aria-hidden`.
- Long-session stability beyond the 30-second stress runs.
- Fairness or difficulty balance for every player.
- Score authenticity; the archive is local and unauthenticated.

Record any unrun row as "not verified". Do not copy the reference column into a new
project without actually running it.
