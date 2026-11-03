# Testing

## Status of this release

Two different bodies of evidence exist. They must not be conflated.

| Evidence | When | Status |
| --- | --- | --- |
| Static checker (`scripts/check.mjs`) | Documentation commit, 2026-11-02 | **OK 93 checks** |
| Skill checker | Documentation commit, 2026-11-02 | **OK 8 files, 0.22 MB** |
| In-browser self-test (16 checks) | Documentation commit, 2026-11-02; headless Chrome/SwiftShader | Passed 16/16 |
| Headless gameplay matrix (§3) | v1.0.0 build, headless Chrome/SwiftShader | Passed as recorded |
| Manual browser matrix (§4) | v1.0.0 build, headless viewports | Passed as recorded |
| Real mobile device / Safari / Firefox | — | **Not verified** |

The headless gameplay harness is not committed. The documentation commit re-ran the
static checks and the in-page self-test against the current source, but did **not**
re-run the full gameplay matrix; the application source was untouched. If you change
`script.js` or `style.css`, re-run §3/§4 yourself.

There is no CI workflow in the repository. The checker is a local gate.

## 1. Commands

```sh
cd ~/Projects/neon-horizon-2088
node --check script.js
node scripts/check.mjs
node ~/.config/opencode/skills/skill-publish/scripts/check-skill.mjs skills/neon-horizon-2088
python3 -m http.server 8080
```

Open `http://localhost:8080/` for a manual pass and
`http://localhost:8080/?selftest=1` for the built-in self-test.

## 2. Static results

`scripts/check.mjs` verifies required release files, local `index.html` references,
relative Markdown links, JavaScript syntax, JSON parsing, skill frontmatter, the
no-absolute-path rule, the README documentation index and byte-identical skill templates.

Expected output:

```text
OK <n> checks
```

For the documentation release the actual output was:

```text
OK 93 checks
OK neon-horizon-2088 — "neon-horizon-2088", 8 files, 0.22 MB
```

Failure output is one `FAIL` line per problem followed by `FAILED <n> checks, <m>
failure(s)` and exit code 1.

The skill checker validates the directory name, frontmatter, file count/size and scans
non-documentation files for credential patterns. Expected:

```text
OK neon-horizon-2088 — "neon-horizon-2088", <n> files, <x.xx> MB
```

The self-test is separate and needs a browser:

```text
[NEON HORIZON self-test] 16/16
```

## 3. Headless gameplay reference run (v1.0.0)

Method: local `python3 -m http.server`, headless Chrome with SwiftShader, DevTools
Protocol. The page exposed `window.NEON_HORIZON`; tests drove `startGame`, `launchBall`,
`setFlipper`, `getSnapshot`, `_debug.ballBody` and `_debug.world`.

Verified in that run:

- Full-charge railgun launch through the curved lane guide, around the top and back down.
- Hyper-loop capture, rail ride and flipper-side release.
- Bumper hit: light flash, material pulse, spark burst, outward kick, upright collider.
- Drop-target hit, bank clear, multiplier increase and delayed re-arm.
- Left/right flipper motion and momentum transfer.
- Slingshot snap inward and up-table.
- Drain → ball countdown → respawn; three drains → game over.
- Left and right wall rebound with reversed horizontal velocity.
- Return guides feed side balls back to the flippers.
- Sealed side outlanes; a forced centre drain still starts the countdown and game over.
- Glass ceiling keeps a popped ball under the glass.
- Table-escape recovery preserves the ball count.
- Automatic anti-trap recovery after 3.5 s of no progress.
- Manual **R** and **RECOVER STUCK BALL** recovery preserve score and ball count.
- Game-over summary, auto-archive and rank.
- `neon_horizon_scores.json` export and merge import.
- Callsign, mute and leaderboard persistence across reload.
- Mobile touch launch and touch flippers.
- Viewport resize 1600 × 1000 → 768 × 1024 → 390 × 844 → 320 × 568.
- 60 units/s test shots into the left, right and top walls stay inside the table.
- A 30-second aggressive random-flipper run produced no out-of-table ball or floor
  fall-through.
- A 25-second random run produced no side drains.
- **0** uncaught exceptions and **0** console errors in the final run.

Recorded self-test breakdown: 16/16 — score formatter, time formatter, callsign
sanitiser, Three.js loaded, Cannon.js loaded, table tilt, 3 cores, 4 drop targets, 2
loops, 2 flippers, ball collider, physics world, leaderboard storage, JSON
serialisability, audio API, export filename.

## 4. Manual matrix

| Area | Test | Expected | Reference run |
| --- | --- | --- | --- |
| Desktop | 1600 × 1000 load | Hero, HUD, left and right panels visible; no overflow | pass |
| Tablet | 768 × 1024 | Left panel hidden; right panel stacked/drawer; canvas fits | pass |
| Mobile | 390 × 844 | Touch pads visible; scores drawer works; no overflow | pass |
| Small mobile | 320 × 568 | Launch and flippers reachable; HUD not clipped | pass |
| Keyboard | Space hold/release | Charge meter fills; release launches | pass |
| Keyboard | `Z` / `←` and `/` / `→` | Left/right flippers | pass |
| Keyboard | `R`, `M`, `H`, `Esc` | Recover, mute, help, close | R and H pass; M-key and Esc not separately verified |
| Keyboard | typing in callsign | Game shortcuts do not fire while an input is focused | not separately verified (guard in `onKeyDown`) |
| Pointer | Drag up on **LAUNCH** | Adds charge; release fires | hold/release pass; drag boost not separately measured |
| Pointer | Canvas halves / flip pads | Corresponding flipper fires | not separately verified (handlers inspected) |
| Persistence | Reload after a session | Callsign, mute, scores remain; fresh table | pass |
| Persistence | Blocked/empty storage | Game still runs; no crash | not separately verified |
| Audio | First gesture | Context starts; no autoplay error | pass (API) |
| Audio | Mute / unmute / reload | Master gain 0/0.62; preference persists | pass |
| Audio | Tab hidden / visible | Ambient drops to 0.15 and returns | not separately verified |
| Audio | Perceptual mix | Balanced, no clipping | **not verified** (headless, no listening test) |
| Scores | Export | `neon_horizon_scores.json` downloads and parses | pass |
| Scores | Import valid file | Entries merge; no duplicates | pass |
| Scores | Import bad file | Toast rejection; archive unchanged | not separately verified (guard in `importScoresFile`) |
| Scores | Import > 2 MB | Rejected before parsing | not separately verified (guard in `importScoresFile`) |
| Recovery | Parked ball | Auto-recovery after 3.5 s; ball count unchanged | pass |
| Recovery | Flipper cradle | Watchdog does not steal the ball | pass |
| Reduced motion | `prefers-reduced-motion` | CSS animations effectively stop | CSS inspected; **not** manually tested |
| Accessibility | Screen reader / keyboard-only | HUD readable, dialogs announced, table not navigable | **not audited** |

## 5. Stress and boundary tests

| Test | Expected | Reference run |
| --- | --- | --- |
| 60 units/s into left/right wall | Position stays inside; velocity reverses | pass |
| 60 units/s into top wall | Position stays inside; velocity reverses | pass |
| 60 units/s into lower-side seals | Stays inside or recovers to railgun | pass |
| 30 s random flippers | No escape, no floor fall-through, no exception | pass |
| 25 s random play | No side drains (sealed outlanes) | pass |
| Forced outside position | `recoverBall("auto")`; ball count unchanged | pass |
| Target re-arm with ball on bank | Deferred until ball leaves | not separately verified (guard in `resetTargets`) |
| Three-ball game | Game-over modal, archive entry, rank | pass |

These are demonstration runs, not exhaustive proofs. Physics is deterministic only in
step size; frame timing and `Math.random` still vary.

## 6. Known gaps

- **Safari and Firefox** were not automated. The code uses standard Canvas, WebGL, Web
  Audio and pointer events, but that is reasoning, not a test.
- **Real mobile hardware** was not used. Headless viewport emulation does not prove touch
  latency, GPU behaviour or audio unlock on iOS.
- **Audio quality** was checked at the API/exception level, not by listening on multiple
  devices.
- **Screen readers** were not used. The canvas is `aria-hidden`; the HUD and dialogs are
  DOM, but no accessibility audit was performed.
- **Reduced motion** is CSS-only; the Three.js scene keeps animating.
- **Long sessions** beyond ~30 s of stress were not measured for memory growth.
- **Score integrity** is local; import validation prevents malformed data, not forgery.
- **The headless harness is not in the repository**, so the gameplay rows are not
  reproducible with a single command. The static checker is.

## 7. How to re-verify after a change

1. `node --check script.js` and `node scripts/check.mjs`.
2. Serve and open `?selftest=1`; confirm 16/16 and no console exception.
3. Run §3 rows that touch your change (physics changes: wall, bumper, flipper, recovery;
   UI changes: all four viewports).
4. Re-run export/import and reload persistence.
5. If you changed a source file, refresh the skill template copy and re-run the template
   byte comparison.
6. Update this file with the date and what was actually run.
