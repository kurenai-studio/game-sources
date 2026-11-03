# Lessons

Bugs and dead ends from the build. Each entry states the symptom, the cause and the
guard that should stay in place.

## 1. The ball tunnelled out of the cabinet

**Symptom:** a fast ball disappeared past a side or top wall; the table looked sealed but
the ball was outside.

**Cause:** thin static boxes plus a high-speed ball. At 60 Hz or with a hard flipper
impulse, the ball's per-step displacement exceeded the collider thickness, so the solver
never saw the overlap.

**Fix:** four layers — thin walls, a hard inner-face clamp (`x = ±4.58`,
`z ≥ -10.45`), lower backstops and a glass ceiling — plus a 22 units/s speed clamp before
and after `world.step`. The clamp is not cosmetic; 22/120 ≈ 0.18 units/step is below the
0.32 ball radius.

**Regression guard:** fire 60 units/s test shots into the left, right and top walls and
assert the ball stays inside; lower-side seam shots may need the recovery path, which
must not cost a ball. A 30-second random-flipper run must not produce an out-of-table
position.

## 2. The left wall did not bounce

**Symptom:** the ball hit the left wall and lost its horizontal velocity instead of
rebounding.

**Cause:** the old lower-side funnel geometry and low wall restitution; the ball was
being escorted along a guide rather than reflected.

**Fix:** wall restitution 0.80, the funnel removed, and the lower third rebuilt. A probe
with incoming `vx = -5.0` returned `vx ≈ +2.0`.

**Regression guard:** test both side walls at low and high speed; the horizontal velocity
must reverse sign after the hit.

## 3. The side outlanes were not fun

**Symptom:** the user reported that the ball "almost always" escaped down the side rails.

**Cause:** the original outlane funnels acted as one-way chutes to the drain. That is
faithful to some real machines but hostile in a short browser session with three balls.

**Fix:** delete the funnels; add inlane return guides, inward/up-table slingshots and
sealed side lanes at `x = ±3.0`, so only the centre flipper gap drains.

**Do not "restore realism" by reopening the outlanes without adding posts and retesting.**
The reference deliberately favours playability. If a harder mode is wanted, add guarded
outlanes as a separate configuration, not by deleting the seals.

## 4. The right-side pinch point wedged the ball

**Symptom:** the ball came to rest between the right bumper/slingshot/peg and the
shooter-lane divider.

**Cause:** those objects were almost flush with the divider at `x = 3.6`; the gap was
narrower than a ball in places.

**Fix:** move the right-side objects inboard, keep more than one ball diameter of
clearance, and add the right backstop at `x = 3.24` (outside the shooter lane).

**Regression guard:** drop a ball at several right-side coordinates with zero velocity and
confirm the watchdog recovers it; inspect the clearance numerically, not just on a
screenshot.

## 5. Bumper and peg colliders were lying down

**Symptom:** the ball rolled over a visual post as if it were a flat disc.

**Cause:** `CANNON.Cylinder` is built along Z. The visual posts were upright, but the raw
shapes were not rotated.

**Fix:** `addUprightCylinder` adds the shape with a quaternion of `-π/2` about X.

**Regression guard:** after adding any post, collide with it from the side and confirm a
radial bounce, not a ramp.

## 6. "BALL UNSTUCK" was a lie

**Symptom:** the toast said the ball was unstuck, but it stayed wedged.

**Cause:** the old rescue applied a small impulse after 5.5 s. A ball pinned by geometry
absorbs that impulse and stays put; the UI announced success before checking the result.

**Fix:** a displacement watchdog. Track an anchor; if the ball stays within 0.8 units for
3.5 s, call `recoverBall("auto")`, which respawns it in the railgun. The toast only fires
after the respawn.

**Lesson:** never announce a recovery before the state actually changes. UI confirmation
must follow the state transition, not the timer.

## 7. The watchdog must not steal a cradle

**Symptom (risk):** a player holding a flipper to trap the ball would trigger recovery.

**Fix:** `updateBallRecovery` returns early when either flipper is active, when the ball is
on a loop rail, or when it is in the shooter lane.

**Regression guard:** hold a flipper with the ball trapped for more than 4 s; it must stay
on the flipper.

## 8. A re-armed target can materialise inside the ball

**Symptom (risk):** after a bank clear, the target bodies were restored on a fixed 3 s
timer regardless of where the ball was.

**Fix:** `resetTargets` checks a 1.05-unit box around the bank and below `y = 1.3`; if the
ball is there, it clears the timer and retries in 900 ms.

**Regression guard:** park the ball on the target bank, clear the bank from a test hook,
and confirm the re-arm is deferred until the ball leaves.

## 9. Collision-callback exceptions repeat every step

**Symptom:** `TypeError: Cannot read properties of undefined (reading 'cooldown')` from a
Cannon `collide` callback, repeated on every solver step.

**Cause:** a listener ran before/without the object it expected, inside `world.step`.

**Fix:** guard the ball identity and phase first, keep the object in a closure that is
fully built before the listener is attached, and never mutate arrays from inside the
callback. The final headless runs logged zero exceptions.

**Regression guard:** run with DevTools/CDP exception capture, not only `console.log`; an
exception inside `world.step` can be swallowed by the loop and still corrupt state.

## 10. Body type transitions are easy to get wrong

The ball is `DYNAMIC` in play, `KINEMATIC` on a loop rail, and `STATIC` after a drain.
Every transition must set `mass`, call `updateMassProperties()`, and restore
`collisionResponse` on the way back. Forgetting the mass on a rail exit makes the ball
weightless; forgetting `collisionResponse` after a drain makes it ghost through the
table.

**Regression guard:** capture and release a loop, then drain, then respawn; each state
must collide normally.

## 11. Camera and HUD break at unfamiliar aspects

The camera uses five aspect bands (`0.72`, `0.95`, `1.25`, `1.75`). The HUD uses
breakpoints at `1380`, `1080`, `900`, `560` and a short-desktop rule. These are separate
systems: resizing can fix the canvas and still clip the right panel.

**Regression guard:** check 1600 × 1000, 768 × 1024, 390 × 844 and 320 × 568; assert no
horizontal overflow and that the scores drawer is reachable below 900 px.

## 12. CDN "upgrades" are migrations

Three r128 uses `outputEncoding`, `THREE.sRGBEncoding` and
`PMREMGenerator.fromEquirectangular`; Cannon 0.6.2 uses `Body.KINEMATIC`,
`SAPBroadphase`, `Cylinder` along Z and shape offsets. A newer library will not just
work. Pin the versions and treat an upgrade as a rewrite-and-retest task.

## 13. Cached `script.js` hides fixes

Pages and browsers can serve an older `script.js` for a short window. During the build, a
"still broken" report turned out to be a stale asset. Verify the deployed file content
(e.g. grep for a new symbol) and hard-refresh before debugging code that is already fixed.

## 14. Score import is an injection boundary

Names are rendered into the DOM and exported to JSON. `sanitizeScoreEntry` strips
`<>&"'`, collapses whitespace, caps length at 14 and clamps numeric fields; imports are
capped at 2 MB. Do not replace `textContent` with `innerHTML` for archive data.

## 15. Self-test counts and docs drift together

`selfTest` asserts 3 bumpers, 4 targets, 2 loops, 2 flippers and 16 total checks. Adding
a table object without updating the self-test produces a false failure; updating the
self-test without the docs produces a false handoff. Change both in the same commit. The
same applies to the byte-identical template in `skills/neon-horizon-2088/assets/template/`.

## What regresses most often

1. **Physics feel** after any change to tilt, timestep, restitution or speed clamp.
2. **Lane geometry** after moving a bumper/sling/peg — new pinch points.
3. **Side containment** after editing walls or seals.
4. **Target re-arm** after changing the timer or bank logic.
5. **Camera/HUD** after adding a panel or changing a breakpoint.
6. **Docs links and template bytes** after editing a source file.
7. **CDN availability** — the app has no offline fallback.
