# Scoundrel — Audio

This documents the game's sound: the decisions locked in the audio design interview, every
sound and when it plays, the file contract, the mix and its controls, the architecture, and
where the audio comes from. It complements [`design.md`](design.md) (the rules engine) and
[`ui.md`](ui.md) (the screens). Keep all three in sync with the code.

The plan that builds it is
[`superpowers/plans/2026-09-24-audio.md`](superpowers/plans/2026-09-24-audio.md), the record of
intent and progress. **This file is the record of what ships.**

> ## Where this stands, 2026-09-24
>
> **The sound effects, music, cues and torch all play, and the player controls their volume.**
> - **The 29 sound effects,** in `assets/audio/sfx/`, synthesized by
>   `audio-source/`. They play on their animations' beats (`a00041d`) and were signed off by ear
>   in listening rounds 1 (heard alone) and 2 (in play).
> - **The music, both cues and the torch loop,** in `assets/audio/music/` and
>   `ambience/` (`c62b309`), playing in the game (`4d0a625`) and verified from the in-game sound
>   log. **Signed off by ear in listening round 3**, after one pass that rebuilt the torch and
>   the fist and brought the music down a notch (`8af222e`).
> - **The pure `audio` package** (`e49a6bb`…`b8e7f74`, `c658e86`, `f6b11d4`, `29bb050`), which
>   decides what each moment sounds like and sequences the music, and `AudioControls`
>   (`6cccf54`), which keeps the volume and saves it.
> - **The controls** (`71eddaa`…`8491e49`):
>   - the title's MUSIC and SOUND plates, with a line under them saying what M does;
>   - M to mute from any screen;
>   - the levels saved in `~/.scoundrel/audio.settings`;
>   - the audio silent while the window is minimised, but keeping time with the picture;
>   - `SCOUNDREL_NO_AUDIO=1` to run without a device.
>
>   The user signed off the plates' placement from the screenshots on 2026-09-24.
>
> Every section below carries a **Status** line. It said **planned** until the part was built,
> then **shipped** with the commit that shipped it. **Nothing is planned any more:** every
> section is shipped, or *decided* for the locked design. **The synthesized audio is final:** on
> 2026-09-24 the user decided to keep every sound, so no replacement will be sourced (see
> **Sourcing**). **Released in 2.1.0** (2026-09-24), merged from the `audio` branch in PR #18.

## Locked decisions (from the design interview)

**Status: decided** (interview 2026-09-23; planning decisions approved 2026-09-24).

- **Crunchy lo-fi.** Grounded sounds (thuds, steel, glass, fire) with a retro edge: sample-rate
  reduction, mild bit-crushing, a low-pass. Not pure chiptune, which reads as cheerful against a
  torchlit dungeon.
- **One sound per moment.** The game is fast: cards act on press, and a click during an
  animation skips it. So every moment gets exactly one sound, and any sound that would always
  coincide with another is cut. The list below is closed; push back on additions.
- **Sound follows the picture.** A sound plays on its animation's beat, not when the engine
  applies the move. A skipped animation plays its pending sound at once, so every action
  sounds exactly once however fast you click.
- **Two tracks and two cues.** A menu track and a run track on the same theme (the menu is the
  run track stripped back), plus win and death cues. The run track is slow and brooding. All
  three modes share it, and the tutorial sounds like a normal run.
- **The picture cuts, the music doesn't.** Screen transitions stay cuts (`ui.md`). Music
  crossfades instead: audio is a deliberate exception, like the smooth torch backdrop.
- **Placeholder-first.** Claude synthesizes every sound so the whole game is wired and timed,
  then the user listens and weak sounds are replaced from approved sources (see **Sourcing**).
  *Settled 2026-09-24: after three listening rounds the user kept every synthesized sound as
  final, so none is replaced.*
- **Claude can't hear.** Audio is verified by measurement and by an in-game sound log; the user
  is the ear (see **Verification**).

## The sounds

**Status: shipped.** The choice of sound is in `Sound` and `SfxChoice` (`c7c2251`), and the game
plays it (`a00041d`). The torch loop plays too (`4d0a625`).

| Sound | Plays when | Weighted by |
|---|---|---|
| **Click** | A menu button is pressed: title, mode select, ledger, trophies, and the end-of-run panel | — |
| **Flip** | Each card dealt into the room lands. A deal's flips are shaped as one riffle | its place in the deal |
| **Sweep** | A room is avoided | — |
| **Equip** | A weapon lands on the rail | weapon value |
| **Weapon kill** | The blade lands on a monster: a *blade* weighted by the weapon, plus a *thud* only if damage got through | weapon; damage let through |
| **Strike** | A monster is fought bare-handed (both blows in one sound) | monster value |
| **Drink** | A potion pours, **including at full health** (it heals 0 but is still a drink) | potion value |
| **Spill** | A wasted potion (the second in a room) spills | — |
| **Chime** | TROPHIES UNLOCKED appears on the end panel | — |
| **Torch** | Always: a crackle loop on every screen, quietly under the music | follows the torch's brightness |

**Deliberately silent:**
- Buttons pressed **during a run**: the Avoid plate, the fight/weapon chooser, the tutorial
  callout's NEXT and SKIP. The sound that follows each press covers it. The abandon question
  that ESC opens mid-run follows the same rule: KEEP PLAYING and ABANDON RUN are silent, and
  abandoning cuts to the title, where the menu track takes over.
- A weapon wearing down: `WeaponDegraded` fires in the same instant as every weapon kill.
- The old weapon being discarded: it happens inside equipping.
- A heal: it would sit on the drink.
- Taking damage: it's folded into the hit. A clean weapon kill is crisp; one that costs health
  lands heavier.
- A new best score: the win cue covers it.

### Weights and versions

Each sound is one recipe, rendered at up to three weights as separate files. A heavier weight
has more low end, a longer tail and more layers. A small pitch change by exact value separates
cards that share a weight: ±4% across the weight, lighter values higher. The nudge restarts in
each weight, because the file already says "heavier".

| Scale | Light | Medium | Heavy |
|---|---|---|---|
| Weapon (equip, blade) | 2–4 | 5–7 | 8–10 |
| Potion (drink) | 2–4 | 5–7 | 8–10 |
| Monster (strike) | 2–5 | 6–10 | 11–14 |
| Damage let through (thud) | 1–4 | — | 5+ (0 = no thud) |

- **Weight comes from value only.** Weapons aren't split into edged and blunt, creatures have
  no body types or voices, and a card sounds the same in clubs and spades.
- **Frequent sounds get 2–3 versions**, picked at random and never the same one twice in a row.
  An identical sound repeated reads as mechanical (the "machine-gun effect"), and a full run
  deals 44+ cards and fights 26 monsters.
- **Frequent sounds also vary on every play:** ±2% pitch, and up to 10% quieter, never louder
  than the file was mastered. These are the flip, blade, thud and fist, the sounds with more
  than one version. The ±4% nudge, ±2% pitch and 10% volume are starting values for the
  listening rounds.
- **A deal is a riffle, not a volley.** The cards land exactly one frame (83 ms) apart, and in
  round 1 four even, separate flips on that beat sounded like a machine gun, twice. So:
  - Each flip is a swish that swells in over 25 ms and settles over about 0.35 s, and the
    flips of a deal overlap.
  - Each later card plays quieter (0, −2.2, −4.2, −6 dB) and a touch lower (1.5% per card)
    than the one before (`SfxChoice.RIFFLE_GAIN` / `RIFFLE_PITCH`, via `flip(card)`). Past the
    fourth card it keeps the last step.

  The user chose this by ear over one sound per deal and over sounding the first card alone.
- **Rare moments have one version on purpose.** Sounding identical every time is what makes the
  spill, the chime and the cues recognisable.

## Timing

**Status: shipped.** `Beats` reads each beat off its effect (`abddca8`), `PendingCues` holds
the sounds (`4b63cd0`), and `BoardView` fires them (`a00041d`). Measured in the running game,
every beat below lands within a frame. A skipped deal plays one flip, and a sound still
pending when an effect is skipped or cut into plays at once.

The beats are read from the effect classes, which run at 12 fps (one frame = 83 ms). Times are from the start of each effect. Figures re-derived from the constants on
2026-09-24.

| Sound | Beat | Source |
|---|---|---|
| Strike | 0 ms; the two blows are 83 ms apart, both in one file | `Barehanded.HIT_FRAMES` |
| Weapon kill | 167 ms, as the blade lands | `WeaponKill.SLASH_START` |
| Equip | 250 ms, landing on the rail | `CardFlight.EQUIP` |
| Sweep | 0 ms; the room is gone at 250 ms | `CardFlight.AVOID` |
| Drink | 417 ms, as it pours, through the existing `onPour` hook | `PotionDrink.POUR_START` |
| Spill | 250 ms | `PotionSpill.SPILL_START` |
| Flips | The deal starts once the effect ends. Card *n* lands at 250 / 333 / 417 / 500 ms | `CardFlight.dealTo` |
| Click | On press, as the plate sinks, not on release | `PressGesture.press` |

- **The killing blow runs at half speed** (`BoardView.effectRate` = 0.5), so its beat lands
  twice as late. Beats are measured on the effect's own clock, never hard-coded.
- **Skipping:** any click during an animation calls `BoardView.skip()`
  (`GameScreen.java:185–186`), which plays every pending sound once. A skipped deal plays **one**
  flip, not four at once.

## Music and ambience

**Status: shipped** (`c62b309`, `4d0a625`, `29bb050`). Every sequence below was verified from the
in-game sound log, the death and win through the F9 lab. Signed off in listening round 3, after
the torch was rebuilt and the music brought down a notch (`8af222e`).

**Composition** (`audio-source/music.py`, where the note data lives):

- D minor, 64 BPM, 16-bar loops of exactly 60 s.
- Two bars per chord: i–VI–iv–V, i–VI–VII–V, using A major for the pull home.
- Loops are seamless by construction. Anything ringing past the end is folded back onto the
  start, and sustained parts complete whole cycles per loop.

| Track | Content |
|---|---|
| Run | A detuned drone on D and A, breathing slowly; the theme plucked sparsely (two answering eight-bar phrases, Karplus-Strong strings); a soft heartbeat on each chord's root, with a knock so small speakers carry it |
| Menu | The same theme stripped back: the drone and the melody's strong-beat notes only, softer; no heartbeat |
| Win cue (5.5 s) | The theme's A→D opening, then a rising D-major arpeggio over a warm D-major chord: the minor theme resolving to major (a Picardy third) |
| Death cue (7.5 s) | A low toll, then a line sinking to the bottom while the drone slides down a semitone and dies |
| Torch (20 s, mono) | A wood fire's crackle: bursts of one to eight sharp snaps, thicker when the flame flares, and the odd pop, over a low murmur of flame under 350 Hz. The crackle carries about 86% of its loudness. On every screen at the **SOUND** level (a sound of the room, so turning music off leaves it burning), guttering with the torch |

**Loudness targets, as heard** (integrated, K-weighted): menu −28, run −26, win −24, death −25,
torch −41. The sound effects' loudest moments are about −12 to −25.
- **Round 3 brought the music down a notch** (6 dB, one MUSIC step) because the effects were
  hard to hear under it. The effects couldn't come up instead, because the loudest blade
  already peaks at −1.04 dBFS against the −1 ceiling.
- **The torch is set by its loudest moment:** a crackle is mostly silence. At −41 integrated,
  its loudest 50 ms is about −27, which is as loud as the old hissing torch ever got and just
  under the quietest effect.

**In the F9 lab:** R toggles the run track, X plays the death with its music and guttering torch,
and V plays a win with its cue and chime. Either can be heard without ending a real run, which
would record it.

**Sequences:**
- **Between menus:** the menu track plays on, **without restarting**, across the title, mode
  select, ledger and trophies.
- **Menu ↔ run:** a short crossfade (1 s to start with) while the picture cuts. It uses an
  equal-power curve, so the middle of the fade doesn't dip in loudness.
- **Death** (real runs only; the tutorial has no death sequence, per `GameScreen.java:1001`).
  It follows `DeathCinematic`:
  - The run music plays through the flare, the shake and the settle.
  - It fades out with the torch going out, from 1.25 s to 2.75 s. The torch crackle follows the
    torch's own brightness down, since its volume is the screen's `backdropLight()`.
  - A beat of silence.
  - The death cue at ≈ 3.42 s, as YOU DIED grows in.
  - Clicking through fades quickly and plays the cue at once if it hasn't played yet, never
    twice.
- **Win:** the end panel appears immediately, while the winning move is still animating. So the
  run music fades when the board goes idle, then the win cue plays.
- **The chime** (only if a trophy was unlocked) waits for **both** the end panel and this run's
  cue to finish, after a win or a death, so it never lands on top of either. Clicking through a
  death puts the panel up at once, and the chime then waits for the death cue. A cue ending
  from an earlier run is ignored.
- **The end panel is quiet:** only the torch. The menu track returns on MAIN MENU, TROPHIES or
  THE LEDGER; the run track restarts on NEW GAME.

## Mix and controls

**Status: shipped**, and verified in the running game from the sound log and screenshots:
- The levels, gains, mute and settings file: `AudioSettings` and `AudioSettingsStore`
  (`4e98b05`), and `AudioControls` (`6cccf54`).
- The plates and M: `71eddaa` and `63a8c84`.
- The M line under the plates: `61475a7`.
- Minimised, silent but keeping time: `8491e49`. It came third: first a hold (`652a013`), then
  audible playing on (`c3f94c9`). See below.
- The no-device switch: `c0b45d9`.

The plates' placement was signed off by the user from the screenshots.

- **Two plates on the title, MUSIC and SOUND**, in one row under the four menu buttons.
  - **Layout:** the column's 10 px gap above and between them, together exactly the column's
    width, and the back plate's 36 px height, so they read as settings rather than places to
    go. The geometry is in `ScreenArt` and headless-tested.
  - **Pips:** each plate shows its level as three pips. A lit pip is gold and an empty one is
    a sunk slot; muted, the lit pips turn grey. All three colours were already in the palette.
  - **The M line:** under the row, always there, since nothing else says M exists. It reads
    "M TO MUTE ALL", or "MUTED · M TO UNMUTE" while muted (`Labels.muteHint`).
  - **Cycling:** each plate cycles up through three levels and wraps to OFF on release, like
    any menu button. **Changing a level also un-mutes**, since turning a volume is a request
    to hear it.
  - **Clicks:** MUSIC clicks on press like every button. SOUND clicks on release instead, at
    its new level, so the click is how you hear the level you chose; at OFF it's silent.
- **Level gains:** 3 = 0 dB, 2 = −6 dB, 1 = −12 dB, 0 = off. On first launch music is at 2 and
  sound at 3, so music sits below the effects.
- **M mutes and unmutes everything from any screen**, the F9 lab included. It's checked in
  `ScoundrelGame.render()` beside F11. During a run the event feed shows "Sound off" or
  "Sound on" (`FeedText.mute`), since nothing else on the board would show it.
  - A cue already playing follows the level every frame, so M silences a death cue that's
    under way. Before Task 7, a cue's volume was set once, when it started.
  - **A zero level is silence, not a stopped clock** (`8491e49`). Muted, at OFF or minimised,
    a track keeps running silently and comes back where it would have been; before that, a
    zero level paused it where it stood. A track pauses only when the director takes it out.
    Sounds already playing follow a level change too.
- **Settings file:** `~/.scoundrel/audio.settings`, one versioned line of tab-separated
  key=value tokens (`v=1	music=2	sound=3	muted=false`), the shape of a run-log line.
  - A missing file, or one that isn't version 1, means the defaults.
  - In a version-1 file, a bad value falls back for that key alone.
  - The store throws on a read or write failure, as its siblings do. `AudioControls` catches
    it: a failed read means the defaults, and a failed save keeps the change for the session.
    Either way it logs one line.
  - It's loaded in `ScoundrelGame.create()` and saved on every change.
  - **The full progress reset doesn't touch it:** it's a setting, not progress. `ProgressTest`
    pins this.
- **Minimised, the audio is silent but keeps time with the picture** (`8491e49`).
  - **The backend:** LibGDX 1.14.2 calls `pause()` on minimise, but it keeps rendering and
    streaming (read in the backend's source, and seen at 146 frames a second while minimised).
  - **How:** `ScoundrelGame.pause()` / `resume()` tell `AudioControls`, which reports zero
    gains while minimised without touching the saved levels. The streams run on at zero, so
    the music comes back mid-track, and a cue that came due while the window was down has
    played out unheard.
  - **How it got here:** the user's call, in two steps.
    - As first built (`652a013`), the audio was held until the window came back. The user
      pointed out that this could play a death cue minutes after its death.
    - It was then left playing out loud (`c3f94c9`). The user asked for silence instead: the
      audio keeps time, but isn't heard.
  - **Verified from the log:**
    - On the title, a second into a minimise: "2 streams running, loudest at volume 0.000".
    - In the lab: the death cue came due at +3.42 s while minimised and ended there (`cue
      ended DEATH`). On restore the levels came back, and nothing started late.
- **No audio device means silence, never a crash.**
  - **The fallback:** LibGDX 1.14.2 already switches to a silent mock when OpenAL can't start
    ("Couldn't initialize audio, disabling audio", checked in the jar). Every load and play is
    also guarded, so a missing or bad file is silent plus one log line.
  - **Simulating it:** `SCOUNDREL_NO_AUDIO=1` (or `-Dscoundrel.no.audio=true`) starts the game
    on that mock. The sound log's first line names the backend ("on MockAudio").
  - **Verified on the mock:** the plates, M, a real Standard run's first room, every lab effect
    but the chime, the death and win cues, and a minimise. The minimise ran under the first
    design (the hold, since replaced); a minimise now only sets gains of zero, which the mock
    takes like any other. There were no exceptions,
    and `crash.log` was unchanged.
  - **The chime:** the mock never reports a stream finished, so after a win it never comes.
    With no device nothing is audible, so nothing is lost.
- **Mix targets** (all enforced by `check.py`, for the streams since Task 6):
  - Every file peaks at or below −1 dBFS. For OGG that's measured on the **decoded** file, since
    Vorbis overshoots by about 0.2 dB.
  - At most 5 ms of silence at the start of a sound effect.
  - Tails decay to silence, with no DC offset.
  - **Each sound effect has a loudness target, measured as heard**: its loudest 50 ms after
    ITU-R BS.1770 K-weighting. The weighting counts deep bass for less and the range above
    about 2 kHz for more, the way the ear does. Plain RMS, used first, left the thud 7 dB
    under the blade it plays beneath, and round 1 heard it as barely there.
  - **Targets are relative to one another:**
    - The two kills are the loudest, between −12 and −15 dBFS as heard: the weapon kill's blade
      and thud, and the bare-handed fist. Round 3 raised the fist by 3.5–4.5 dB, since a
      bare-handed kill always costs health.
    - The equip, sweep, spill, drink and chime sit between −15.5 and −20.
    - The click is at −23 and the flips at −25, because they come on every menu press or four
      at a time.

    The live values are in `audio-source/recipes.py`, tuned by ear.
  - Music sits below the sound effects.

## Architecture

**Status: shipped.**
- **The pure half:** `e49a6bb`…`b8e7f74`, `c658e86`, `f6b11d4`, `29bb050` and `6cccf54`.
- **The sound-effect wiring** (`Beats`, `SoundBank`, `BoardView`, `PixelScreen.pressAt`):
  `abddca8` and `a00041d`.
- **The music wiring** (`MusicDeck`, the director in `ScoundrelGame`, `GameScreen`'s calls):
  `4d0a625`.
- **The controls:** `71eddaa`…`8491e49`.

The sound log shipped too.

The engine already exposes everything audio needs. `apply(state, move)` returns the events,
and the effects already have their beats. Nothing in `model` or `rules` changes.

```mermaid
flowchart LR
  subgraph pure["audio (pure, gated)"]
    SC[SfxChoice]
    MD[MusicDirector]
    AC[AudioControls]
    AS[AudioSettings]
  end
  subgraph gl["screens + ScoundrelGame (LibGDX)"]
    GS[GameScreen]
    BV[BoardView]
    PS[PixelScreen]
    SB[SoundBank]
    DK[MusicDeck]
    SG[ScoundrelGame]
  end
  E[ScoundrelEngine.apply] -->|MoveResult events| GS
  GS -->|what: SfxChoice| BV
  BV -->|when: beat or skip| SB
  PS -->|menu click on press| SB
  GS -->|run / dying / idle / end| MD
  SG -->|tick each frame| MD
  MD -->|stream gains + one-shots| DK
  SG -->|torch gain = level x backdropLight| DK
  SG -->|M, the title's plates| AC
  AC -->|loaded, saved| AS
  AS --> SB
  AS --> DK
```

- **`audio`**: a new pure package with no LibGDX, held to the coverage gate like the other pure
  packages (`CoverageGateTest` enforces it). It decides *what* plays:
  - `Sound`: the closed list of ten effects and the file contract.
  - `Weight` and `Scale`: the value bands and the pitch nudge.
  - `SfxChoice`, with `VariantPicker`, turns events into `Sfx` (file, pitch, volume).
  - `PendingCues`: holds sounds for their beats.
  - `MusicDirector`: sequences the tracks and cues.
  - `AudioSettings` and `AudioSettingsStore`: the volume. `AudioControls`: the volume through a
    session, read at launch and saved on change, where a disk failure stops being a crash.

  It references only `rules`. Timing that lives in `screens` (the death sequence's constants)
  is passed in.
- **`screens`** decides *when*:
  - `Beats` is a pure, tested helper that reads each beat from the effect classes.
  - `BoardView` holds each effect's sounds for its beat, and schedules a flip for each newly
    dealt card as it lands. On `skip()`, or when a new effect cuts in, it plays everything
    still waiting at once.
  - `SoundBank` plays the sound effects at the player's volume and caps how many copies of each
    play at once (`Sound.voices()`: four flips, one chime, two of the rest). It owns the one
    shared `SfxChoice`. A file that won't load, or a play that fails, is logged and silent.
  - `PixelScreen.pressAt()` plays the menu click as a pressed plate sinks. `GameScreen` lets
    only its end panel click.
  - `MusicDeck` streams the five `StreamFile`s. Once a frame it carries out the director's
    commands (restart a track, play a cue, the chime through the bank) and sets each stream's
    volume. A cue that can't play reports itself finished at once, so the chime never waits
    forever.
  - `GameScreen` tells the director what only it sees: a death (on `DeathCinematic`'s own
    timings), the panel settling, a win, trophies, and a new run begun in place.
  - The F9 animation lab plays the same sounds through the same `BoardView`, from the events
    the game would report, and has music keys (R, X, V) with its own torch light.
- **`ScoundrelGame`** owns the bank, the deck, the director and the settings (`AudioControls`),
  like `Theme` and `Sprites`.
  - Screens reach them through `game.sounds()`, `game.music()` and `game.audioSettings()`.
  - Every screen switch tells the director run or menus, and each frame passes the showing
    screen's board idleness and torch light. That's what lets music survive screen changes.
  - It polls M and applies each change to the bank and the deck. Its `pause()` / `resume()`
    silence the audio while minimised, through `AudioControls`, and the streams keep time.
- **Launch switches** (`LaunchSwitch`, in the root package): each one is on with its
  environment variable set to `1`, which `gradlew lwjgl3:run` passes through, or its `-D`
  property for a jar.
  - **`SCOUNDREL_AUDIO_LOG=1`** (`-Dscoundrel.audio.log=true`) turns on the sound log. It logs
    every play, effect start, deal, skip, cut-in, level change, cue level and minimise, with
    seconds since launch (`screens/AudioLog`). This is how the GL-side timing is verified.
  - **`SCOUNDREL_NO_AUDIO=1`** (`-Dscoundrel.no.audio=true`) simulates a machine with no
    audio device.

## Asset contract

**Status:** the list of names is in code (`Sound.allFiles()`, `c7c2251`). The 29 sound-effect
files exist, synthesized (`81cc0a3`), and `AudioAssetsTest` holds them to the list
(`7542da4`). The five streamed files exist too (`c62b309`, 3.2 MB). `AudioAssetsTest` holds them
to `StreamFile` (each must be an Ogg stream, with nothing stray in their folders or in
`assets/audio/`).

**File names are the contract**, like the sprite region names. Unweighted sounds are
`<sound>_<version>`; weighted ones are `<sound>_<weight>_<version>`, where the weight is
`light`, `medium` or `heavy`. The Java side's list is `Sound.allFiles()` (`c7c2251`), which
`SoundTest` pins to the table below by hand. `AudioAssetsTest` checks the folder matches it
**exactly**: a stray file fails too, because everything in `assets/` ships.

**Sound effects**, in `assets/audio/sfx/`. WAV, 16-bit PCM, mono, 44.1 kHz. **29 files:**

| Sound | Files | Count |
|---|---|---|
| click | `click_1` | 1 |
| flip | `flip_1` … `flip_3` | 3 |
| sweep | `sweep_1` | 1 |
| equip | `equip_{light,medium,heavy}_1` | 3 |
| blade | `blade_{light,medium,heavy}_{1,2}` | 6 |
| thud | `thud_{light,heavy}_{1,2}` | 4 |
| fist (strike) | `fist_{light,medium,heavy}_{1,2}` | 6 |
| drink | `drink_{light,medium,heavy}_1` | 3 |
| spill | `spill_1` | 1 |
| chime | `chime_1` | 1 |

**Streamed audio**, OGG Vorbis at 44.1 kHz. Music is stereo; the torch is mono. **5 files:**
`assets/audio/music/{menu,run,win,death}.ogg` and `assets/audio/ambience/torch.ogg`.

**Why the files are committed rather than built:** the sprite atlas is built by Gradle and
gitignored, but audio is rendered by Python (numpy plus an OGG encoder). CI and anyone building
the game shouldn't need either, so the renders are committed and a test guards the contract.

## Regenerating the audio

**Status: shipped** (`6d2e267`, `81cc0a3`, `c62b309`).

```bash
python -m pip install --user -r audio-source/requirements.txt   # numpy 2.5.3, soundfile 0.14.0
python audio-source/render.py      # renders assets/audio/ (about 15 s; OGGs rewritten only if their audio changed)
python audio-source/check.py       # measures every file; non-zero exit on any failure (about 20 s)
python audio-source/audition.py    # builds audio-source/build/audition.html to listen to
```

`audio-source/README.md` describes each script.

- **`audio-source/`** sits outside `assets/`, like `art-source/`.
- **Recipes use fixed seeds**, so the same seed gives the same audio. That's why the
  requirements pin exact versions. A WAV is byte-identical. An OGG isn't, because libsndfile
  gives each Ogg stream a random serial number, but its decoded audio is, and that's what
  `check.py` compares. libsndfile's Vorbis encoder is fed in blocks, since it overflows the
  stack when handed a minute of stereo at once.
- **Audition pages and scratch renders go in `audio-source/build/`** (gitignored), never in
  `assets/`.
- **A replaced placeholder is never rendered over.** Its name goes in
  `audio-source/replaced.txt`, which `render.py` skips and `check.py` stops comparing against a
  fresh render.

## Sourcing

**Status: closed with nothing replaced.** On 2026-09-24 the user decided to keep every
synthesized sound as final ("I like the audio we have"), so every file is *approved* and none is
sourced. The rules below and `audio-source/replaced.txt` stay in place in case that ever changes.

Every sound is ours (synthesized). Had a replacement been wanted, it could have come from:

- **CC0:** no credit needed.
- **CC-BY:** credited in `assets/audio/CREDITS.txt`, created with the first CC-BY file.
- **AI-generated:** disclosed alongside the Claude collaboration in portfolio material, with the
  tool's commercial terms checked on the day it's used and the date recorded.
- **Paid packs or a commission.**
- **Never non-commercial (NC) licences**, so a future sale never forces a re-source.

**The ledger.** Status goes *planned* → *placeholder* → *approved* or *replaced*, with source,
author and licence recorded on replacement.

| Files | Status | Source | Licence |
|---|---|---|---|
| `sfx/*` (29) | **approved** in round 1 (heard alone; the flips, blade and thud were rebuilt on the way) and round 2 (in play), 2026-09-24. `fist_*` (6) were rebuilt and raised in round 3 ("very silent", `8af222e`) and approved there | synth | ours |
| `ambience/torch` | **approved** in round 3, 2026-09-24, after a rebuild ("too much white noise, not enough crackle", `8af222e`) | synth | ours |
| `music/menu`, `music/run` | **approved** in round 3, 2026-09-24, a notch quieter (`8af222e`) | synth | ours |
| `music/win`, `music/death` | **approved** in round 3, 2026-09-24, a notch quieter (`8af222e`) | synth | ours |

## Verification

**Status:** the unit tests, `AudioAssetsTest`, `check.py` and the in-game sound log are in force
for the sound effects and streams. Listening rounds 1 (heard alone), 2 (in play) and 3 (the
music, cues and torch) signed them off.

- **Pure logic is unit-tested first:** weights, versions, event-to-sound mapping, pending cues,
  the music director, the settings and their controls. Eleven test classes in
  `core/src/test/java/.../audio` (`AudioAssetsTest` among them), plus the `ProgressTest` guard.
  `core:check` gates it; measured when Task 8 closed, `audio` had 100% line and 99.4% branch
  coverage. The screens' pure helpers (`Beats`, `AudioLog`) and the root's `LaunchSwitch` are
  tested the same way.
- **`AudioAssetsTest`** (JUnit, using the JDK's `javax.sound.sampled`, no LibGDX) checks the
  file set, format, peak and leading silence of the sound effects.
- **`check.py`** measures what Java can't: loudness against each target, silent tails, DC,
  length, versions that aren't near-copies, and the committed files matching a fresh render. It
  also reports brightness by weight. For the streams, it measures the **decoded** OGG:
  - Peak at or under −1 dBFS.
  - Integrated loudness on target.
  - A cue's start and silent tail.
  - Each loop's seam: the sample step across the wrap, and whether encoding added
    high-frequency energy there compared with the source, which is seamless by construction.
- **Timing in the game** is checked from the sound log during a run driven by the
  `run-scoundrel` skill, compared against **Timing** above to within one render frame.
- **Whether it sounds right is the user's call**, in three listening rounds: the sounds alone,
  the sounds in play, then the music and sequences. Claude never claims how something sounds.
