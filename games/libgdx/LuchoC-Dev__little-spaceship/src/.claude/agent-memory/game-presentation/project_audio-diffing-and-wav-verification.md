---
name: audio-diffing-and-wav-verification
description: why PlayerStatus diffing turned out sufficient for almost every MVP sound despite phase 06's score-ambiguity concern, and how to verify generated/played audio without ears in this sandbox
metadata:
  type: project
---

Built in phase 08 (`docs/plan/08-audio-and-polish/`), while `core.domain.event.GameEvent` still had
zero implementations.

**Phase 06's review worried that a snapshot diff can't tell a kill from a maxed-pickup bonus, because
both add to `score`. That concern turned out not to block audio at all** — none of the six
`PickupSystem` kinds need `score` as the signal. Each one changes a `PlayerStatus` field nothing else
touches: `lives` only rises from the extra-life pickup, `bombs` only rises from bomb-recharge (and
only falls from spending one — confirmed by reading `BombSystem`, a clean single-tick decrement, no
two-step state machine to worry about), `shieldActive` only flips on from the shield pickup,
`attachmentId` only leaves `""` from the attachment pickup, `invulnerabilitySource` reaching
`POWERUP` only happens from that one pickup. A hit is equally unambiguous:
`invulnerabilitySource` transitioning to `DAMAGE` or `RESPAWN` is `DamageSystem`'s own "a hit
actually landed" signal — its early `return` when the player is already invulnerable means a diff
can never double-count a hit that had no game effect. **The one real gap is an enemy dying**:
`CleanupSystem` calls `world.destroyEntity` with no event and no persistent state anywhere a
`WorldView` diff could catch — the entity is just gone, indistinguishable from one that flew off
the top of the screen. That is the one place this project's audio actually needed a `core` event
(`EnemyDestroyed(x, y, ...)`, requested but not built as of this session).

**Verifying generated/played audio in this sandbox, with no ears and no headless-audio tooling**:
`System.Media.SoundPlayer` (a .NET class, callable inline from `powershell -NoProfile -Command`) can
`.PlaySync()` a WAV file directly through the OS's default output device, completely outside libGDX.
Timing the call with `[System.Diagnostics.Stopwatch]` and comparing elapsed time against the WAV's
expected duration (computed from the generator's own parameters) confirms the file holds real,
correctly-timed audio rather than silence or a truncated/corrupt header — a `~6.9s` measured
playback against a `4 bars * 4 beats * 0.42s = 6.72s` expected length was the actual evidence used,
not just "the generator ran without throwing". This is a different, complementary check from the
existing screenshot technique (`[[windows-desktop-screenshot-verification]]`): the screenshot
technique confirms the *game* loaded and played something without an exception; this confirms the
*asset itself* is not empty or malformed. Neither one is literally "an agent heard the sound" — say
so explicitly when reporting, since audio is exactly the category where "it compiles" and "the log
has no error" prove far less than they do for rendering.
