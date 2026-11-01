# Phase 08 — Audio and polish · status

**State:** done — merged in [#31](https://github.com/LuchoC-Dev/little-spaceship/pull/31), with both dead cues wired on 25/08/2026
**Updated:** 22/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

1. **Sound effects.** Six categories — shoot, impact, explosion, power-up, bomb, UI — synthesised
   procedurally, generator and runtime both described below.
2. **Level music**, synthesised and looping. The boss-entry change is written and ready
   (`AudioSystem`/`MusicTrack.BOSS`, the asset itself) but has no trigger yet — see Blocked.
3. **Volume controls.** Master/music/effects sliders in `OptionsScreen`, wired to `GameSettings`,
   persisted through libGDX `Preferences` (`load()` once at startup, `save()` on every change) —
   the same API resolves to a file on desktop and to `localStorage` under TeaVM with no
   backend-specific code needed here.
4. **Browser audio unlock.** `AudioSystem.unlock()` flips a boolean the first time any menu button
   fires — `MenuEntries.add`'s click/activate handler, which by construction only ever runs inside
   a real user gesture. Every `playSfx`/`playMusic` call before that is a silent no-op, not a crash;
   confirmed the very first `MenuScreen` (reached from `create()`, no gesture yet) stays silent and
   the first click already plays `Sfx.UI_SELECT`.

## In progress

5. **Essential animations.** Not started this session. The player-ship side of this — respawn blink,
   damage flash, the power-up aura ring — already existed from phase 06 and needed no change. What
   is missing (enemy spawn telegraph, enemy hit flash, enemy explosion) hits the exact same missing
   seam as `Sfx.EXPLOSION` below: `core` gives no signal for "an enemy was hit" or "an enemy died",
   only that it silently stops appearing in `forEachSprite`. Deferred rather than built on a guess.

## Blocked

**`Sfx.EXPLOSION` has no trigger**, and neither does the boss music swap. Both need something
`WorldView` cannot give today:

- An enemy dying leaves no trace at all — `CleanupSystem` destroys the entity outright, with no
  `GameEvent` and no persistent state change. A `PlayerStatus`/`WorldView` diff can detect every
  other MVP sound honestly (see the decision below for why), but "an enemy died, here, of this
  size" is not something a diff can approximate — the entity is just gone, same as one that flew off
  the top of the screen. **Requesting from `core-domain`:** a `GameEvent` implementation —
  `EnemyDestroyed(float x, float y, ...)` or similar, position included — emitted from
  `CleanupSystem` at the point it currently just calls `world.destroyEntity`. The sink is already
  wired and ready: `PlayScreen` passes `event -> { }` to `Simulation`, exactly the seam this needs.
- `WorldView.bossStatus()` does not exist on `main` yet — it is on `feat/boss`, not merged as of
  this session. `AudioSystem`/`MusicTrack.BOSS` and the asset are ready; the one missing line is
  `if (view.bossStatus().present() && !wasPresent) audio.playMusic(MusicTrack.BOSS)` in `PlayScreen`,
  which cannot compile against `main` today. Trivial to add once `feat/boss` merges — left as a
  one-line follow-up, not a redesign.

Neither blocks the acceptance criteria that matter for this session: every other action in the flow
has audible feedback, and both gaps are the same one seam, not two separate asks.

## Decisions taken while implementing

**Audio is synthesised, not sourced**, per the plan's own framing. Generator:
`game/src/main/java/.../game/tools/audio/` (`Wav`, `Synth`, `GenerateAudio`) — plain Java, no
`javax.sound`, no third-party dependency, so nothing here needs a TeaVM compatibility check even
though it never runs there. Run by hand with `./gradlew :game:generateAudio`, output committed
under `assets/audio/{sfx,music}/`, the same pattern `docs/design/mockups/build.py` and
`docs/design/fx/build-explosions.py` already use for generated, committed art: deterministic from a
fixed seed, re-run only when the recipe itself changes, never part of `build` or `test`. A build
step wired into every clean checkout was considered and rejected for the same reason those two
precedents reject it — it would re-run on every build for files that only change when the generator
does.

**Audio drives off frame-over-frame `WorldView`/`PlayerStatus` diffs, not `GameEvent`**, for
everything except the one gap above. `core.domain.event.GameEvent` has zero implementations and
`PlayScreen` still passes `event -> { }` — unchanged this session, since there is nothing to route
yet. The concern phase 06's review raised about diffing — score alone cannot tell a kill from a
maxed-pickup bonus — turned out not to block audio: none of the six `PickupSystem` kinds need score
at all. Each one changes a `PlayerStatus` field nothing else touches — `lives` only rises from the
extra-life pickup, `bombs` only rises from the bomb-recharge pickup (and only falls from spending
one, a clean single-tick decrement confirmed by reading `BombSystem`), `shieldActive` only flips on
from the shield pickup, `attachmentId` only leaves `""` from the attachment pickup, and
`invulnerabilitySource` reaching `POWERUP` only happens from that one pickup. A hit is equally
unambiguous: `invulnerabilitySource` transitioning to `DAMAGE` or `RESPAWN` is `DamageSystem`'s own
"a hit actually landed" signal, confirmed by reading it — the early `return` when the player is
already invulnerable means no diff can double-count a hit that had no effect. Shooting is detected
by counting `shot-p1`/`shot-p2` sprites per frame and firing once the count rises — an approximation
(a multi-shot volley plays one cue, not one per projectile) accepted as correct rather than a
shortcut, since one cue per volley is what a player actually expects to hear.

`AudioDirector` (`game/.../adapter/audio/AudioDirector.java`) is the one place this diffing lives,
separate from `WorldRenderer` even though both walk `SpriteVisitor`: it is a second full traversal
of drawable entities per frame, on top of the renderer's own — accepted because nothing in it
allocates, and `CLAUDE.md`'s actual constraint is allocation, not traversal count.

**No menu music track.** `docs/planning/02-mvp-functional-spec.md`'s audiovisual section names only
level music and the boss-entry change — no menu track. `LittleSpaceshipGame.setScreen` stops music
for every screen except `PlayScreen`, so "returning to menu" is silence, which is itself the audible
change the acceptance criterion asks for.

**`GameSettings.save()` calls `Preferences.flush()` on every slider change**, including every
intermediate value while a `Slider` is being dragged (`scene2d` fires `ChangeEvent` continuously
during a drag, not just on release). Accepted for the MVP: it is UI-thread, not per-frame simulation
work, and the effects slider does not persist-on-drag issue observed to cause any stutter on desktop
during verification. Worth debouncing if it ever shows up as a problem on the web target, where
`localStorage` writes are synchronous.

## Notes for whoever comes next

- Generated WAV assets are committed at `assets/audio/sfx/*.wav` and `assets/audio/music/*.wav`.
  Re-run `./gradlew :game:generateAudio` after touching anything in
  `game/src/main/java/.../game/tools/audio/`.
- `Sfx.EXPLOSION` and `MusicTrack.BOSS` are both fully wired on the `game` side and waiting for
  `core` — see Blocked above for exactly what to ask for.
- Verified on the real desktop window (LWJGL3), not inferred from reading the code: the menu loads
  silently before any click, `PLAY` transitions to Ship Select with no exception and no
  `AudioSystem` error logged (a missing/broken asset logs one), and the generated WAVs were played
  directly through Windows' audio subsystem (`System.Media.SoundPlayer.PlaySync`, outside libGDX
  entirely) — `level.wav` measured ~6.9s against an expected 6.72s, confirming the file holds real,
  correctly-timed audio rather than silence or a corrupt header. Did not confirm by ear; this
  sandboxed environment has no audio capture. Phase 09's real-browser pass is still the first time
  anyone actually listens to this.
