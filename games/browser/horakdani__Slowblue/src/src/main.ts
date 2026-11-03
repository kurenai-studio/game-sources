import { AdminPanel } from './debug/AdminPanel';
import { AudioEngine } from './audio/AudioEngine';
import { bedFor } from './audio/Beds';
import { DebugPanel, copyOrDownload, loadStoredTuning } from './debug/DebugPanel';
import { GameLoop } from './core/GameLoop';
import { InputController } from './input/InputController';
import { CampaignController } from './meta/Campaign';
import { ProfileStore, runResult, type RecordDelta } from './meta/Profile';
import { Renderer, type RenderDebugFlags, type RenderStyle } from './render/Renderer';
import { filmForAct, NO_FILM_BEAT } from './render/Films';
import { Shell, type ShellScreen } from './ui/Shell';
import { LocalTelemetry } from './telemetry/LocalTelemetry';
import { World } from './sim/World';
import { breathAt } from './sim/Breath';
import { clamp } from './core/math';
import { ACT_WATER, levelAtIn, levelStartSectionIn, type Act } from './config/levels';
import { actByKey } from './config/campaign';
import { AUDIO_TRACK_KEYS, loadSettings, saveSettings, type Settings } from './config/settings';
import { haptic } from './platform/Haptics';
import type { HapticCueName } from './platform/Haptics';
import { registerServiceWorker } from './platform/pwa';
import { DEFAULT_IDENT_VARIANT, playDigitalTulpaIdent } from './brand/digital-tulpa';

const HINT_DELAY = 2;
/** Seconds the world freezes on a hunter's strike. Long enough to feel, short enough to forgive. */
const HITSTOP = 0.07;

type Mode = 'attract' | 'playing' | 'paused' | 'over';

interface SlowblueTestApi {
  world: World;
  restart: (seed?: number) => void;
  start: (seed?: number) => void;
  /**
   * Opens one station of one act, exactly as the admin surface's list does.
   *
   * The same call, deliberately: `World.reset(seed, section)` on its own leaves
   * the renderer dressed for whatever was on screen before - wrong palette, wrong
   * motif, wrong banner - and a station inspected in the previous station's
   * clothes is not the station. Counts as a jump, so it advances no circuit and
   * touches no record.
   */
  jump: (actKey: string, station?: number, seed?: number) => void;
  metrics: () => Record<string, number | string | null | boolean>;
  exportTelemetry: () => string;
  /** Steps the sim and draws one frame without the rAF loop (inspection only). */
  advance: (seconds: number) => void;
  /**
   * Fires one cue by hand.
   *
   * Not a convenience. Judging whether the eleven cues are distinguishable is
   * the F2 gate, and several of them cannot be reached by playing in any
   * reasonable time: `circuitClosed` is seven acts of trench floor away,
   * `actHandover` needs a campaign, and `ringLost` needs a deliberate failure.
   * A hand cannot compare two buzzes it has to earn an hour apart.
   */
  buzz: (name: HapticCueName) => void;
  /**
   * What a frame costs on this device, readable from a build that cannot open the
   * debug panel.
   *
   * The door this surface was cut for: an installed PWA launches from its
   * home-screen icon with no query string, so `?debug=1`
   * is unreachable and the ⚙ panel - which is where `p95 work` has lived since f0.12 -
   * cannot be opened on the device the number is about. `metrics()` was no help: it
   * reports `fps` and the rendered `dpr` and has never carried the percentiles.
   *
   * `mpx` is here because it is the term that actually varies between the devices
   * being compared. This renderer is fill-bound - `e2e/measure.spec.ts` puts the sim
   * at 0.52 ms against 4.12 ms of drawing per unit of area on a headless desktop - so
   * a phone row and a tablet row are not comparable until the backing store each one
   * was drawing is written next to them. An iPad's canvas is roughly four to six
   * times an iPhone SE's, which is a bigger multiplier than the whole headroom the
   * F0 gate measured.
   *
   * The window is 300 frames, so a reading taken less than five seconds after
   * anything changed is a blend. `pinQuality` throws the window away for that reason;
   * after calling it, play for five seconds before believing this.
   */
  perf: () => Record<string, number | boolean>;
  /**
   * Holds the quality ladder still, or lets it go again (`null`).
   *
   * Pinning at rung 0 is why any of this exists: the ladder makes the gate
   * unanswerable by quietly retreating to a cheaper picture, so a measurement has to
   * hold the picture still first.
   *
   * Pinning at an *arbitrary* rung is the other half, and it is a measurement
   * instrument rather than a convenience. Rungs 2 and 3 differ in one thing only -
   * `dpr` 1 against 0.8, the same particle budget - so two readings across that step
   * are two areas of the same picture on the same silicon, and the pair solves
   * `frame = sim + area * draw` for a device instead of borrowing the split from a
   * headless browser. Rung 4 (0.7) is a third point to check that against.
   *
   * The ⚙ panel's row of pins works the same lever, and is the way this is actually
   * reached on a tablet - a console there means a Mac and a cable. This door stays
   * because it reaches rungs the row does not offer, and because `perf()` beside it
   * is scriptable.
   */
  pinQuality: (rung?: number | null) => void;
}

declare global {
  interface Window {
    __slowblue?: SlowblueTestApi;
  }
}

const canvas = document.getElementById('game') as HTMLCanvasElement | null;
const stage = document.getElementById('stage');
const probe = document.getElementById('safe-probe');
if (canvas === null || stage === null) throw new Error('#game canvas missing');

/**
 * The backing store the frame was asked to fill, in megapixels.
 *
 * Read off the canvas rather than multiplied back out of the ratio, because the two
 * axes are rounded separately. It sits here, next to the element, because both readers
 * of it - `perf()` and the ⚙ panel - are a thousand lines further down and would
 * otherwise each carry their own copy of the arithmetic.
 */
const backingMpx = (): number => (canvas.width * canvas.height) / 1e6;

const params = new URLSearchParams(location.search);
/**
 * The two dev surfaces, and why neither of them opens by itself any more.
 *
 * Both used to be on for the whole of `import.meta.env.DEV`, which meant that
 * the only way to look at this game while building it was through a column of
 * forty sliders down the left of the screen and four lines of green telemetry
 * over the water. That is the right default for tuning a flow field and the
 * wrong one for everything else - most of the work here is looking at a picture
 * and deciding whether it is any good, and neither of these can be judged with
 * the instruments bolted to the front of them.
 *
 * So the tuning panel is asked for now, in dev exactly as in a shipped build:
 * `?debug=1`. Nothing about it changed except who opens it.
 *
 * The admin surface is the other way round, and it earns it: it is one button
 * in the corner rather than a column down the side, and what is behind it -
 * every station, section and sound, one click away - is how anything in this
 * game gets looked at twice without playing six acts to reach it. That is a
 * tool for building the game, so it opens with the dev server.
 */
const debugEnabled = params.has('debug');
/** The admin surface: every station, section and sound, one click away. */
const adminEnabled = import.meta.env.DEV || params.has('admin');
/**
 * Slowblue: dev door into any act while the campaign is being built (`?act=thin`).
 *
 * Not a shipped entry point - the title screen starts the campaign at act I and
 * the acts hand over to each other - but every act key in `config/campaign.ts`
 * opens here, with its own medium, palette, carrier and direction, because the
 * only thing this line chooses is which script the world is pointed at.
 *
 * The parameter's *presence* is what matters, not the act it names: `?act=water`
 * is a jump into act I, not the campaign starting at act I. They play the same
 * water, and everything else about them differs - a jump advances no circuit and
 * touches no record - so the two cannot be told apart by the act alone.
 */
const actParam = params.get('act');
const actDoor = actParam !== null;
const act = actByKey(actParam ?? ACT_WATER.key);

const renderer = new Renderer(canvas);
const tuning = loadStoredTuning();
const settings = loadSettings();
const profileStore = new ProfileStore();
const audio = new AudioEngine();
const startSeed = readSeedParam() ?? randomSeed();
const world = new World(window.innerWidth, window.innerHeight, startSeed, tuning, true, act);
// The world owns a clone; keep one mutable object so the panel edits the live sim.
world.tuning = tuning;

const telemetry = new LocalTelemetry();
const flags: RenderDebugFlags = { showField: false, showHash: false, showStats: debugEnabled };

let mode: Mode = 'attract';
/** Where on `QUALITY_RUNGS` the frame rate has put us, and the two dials it sets. */
let qualityRung = 0;
let particleScale = 1;
let dprScale = 1;
let hintShown = false;
let renderedDpr = 0;
/**
 * Holds the scaler at rung 0 for the length of a measurement. Debug panel only, off by
 * default, never persisted.
 *
 * The frame-time budget asks whether this device can hold *the whole picture* under 16.7 ms, and
 * the scaler is precisely what makes that question unanswerable: two and a half seconds
 * under 45 fps and the game is quietly drawing fewer particles at a lower resolution, so
 * the frame time recovers and the reading says the device is fine. It is fine at the
 * picture it retreated to, which is not the thing being asked.
 */
let qualityPinned = false;
let lowFpsFor = 0;
let highFpsFor = 0;
let hitstop = 0;
let lastPhase: 'running' | 'over' = world.run.phase;
/** Wall-clock seconds the breath is read from. Never reset - see `updateAudioBed`. */
let breathClock = 0;
/** `performance.now()` at the previous rendered frame, for the real-time delta. */
let lastFrameMs = performance.now();
/**
 * True while the admin surface's sound tab is up. Everything `updateAudioBed`
 * pushes below the breath is a value it writes sixty times a second, which is
 * exactly what a slider on the other side of it cannot survive.
 */
let audioOverride = false;
/**
 * True while the in-game mixer drawer is up: the water is held and the sound is not.
 *
 * A drawer that let the run carry on underneath it would be a drawer nobody dares
 * open in act I - it covers most of a phone, and a hunter does not wait - and one
 * that *paused* would park the audio graph and silence the layer being levelled.
 * Freezing the step and leaving `mode` alone gives both: the picture holds, the
 * HUD stays, `updateAudioBed` goes on running from `onRender`, and the bed
 * carries on breathing while somebody takes a minute over a slider.
 */
let mixHold = false;
/** What the loop's clock was before the admin sheet froze it. See `setFrozen`. */
let frozenFrom = 1;
/**
 * Slowblue: the one thing that happens after a run ends - the next act's first frame,
 * or the results screen - and the two clocks it has to get right.
 *
 * It is waited out on the render loop rather than on a `setTimeout`, and that is
 * a fix rather than a style. An ending that has a film has to wait for *the
 * film*, and the films do not advance in wall-clock seconds: they are stepped by
 * `frameDt`, which is the fixed step plus the frame's own cost, so a second of
 * film is somewhere between half and a whole second of real time depending on
 * what the device is doing. Counting the wait in real seconds meant the next act
 * opened while the film was still running on a fast frame, and left the player
 * looking at a held frame for several seconds on a slow one. Now the film says
 * when it is finished and nothing else has an opinion; an act with no film falls
 * back to a plain beat, which is the only case a clock is the right answer for.
 *
 * It also has to be cancellable. Both waits are seconds long, and in that window
 * the player can still restart with `r` and the admin surface can still jump
 * somewhere - a wait left pending then fires into a run that has nothing to do
 * with the one that scheduled it and switches the act out from under it.
 */
interface AfterRun {
  /** Real seconds still to wait when there is no film to wait for. */
  beat: number;
  /** True while this wait is for a film to reach its handover frame. */
  film: boolean;
  then: () => void;
}

let afterRun: AfterRun | null = null;
/**
 * Set on the frame the seventh act completes, and read once by the screen that
 * follows it. The results screen after a closed circuit is not an act's ending -
 * it is the campaign's - and this is how it knows.
 */
let closedCircuit: { score: number; carried: number; cycles: number } | null = null;

function clearAfterRun(): void {
  afterRun = null;
}

/**
 * Queues the one post-run wait, replacing any that is already pending.
 *
 * A film is only waited for when one is actually running, which means the act
 * has one *and* the run reached its end - a failed act plays no ending, so it
 * gets the beat instead however many films its act owns.
 */
function scheduleAfterRun(beat: number, film: boolean, then: () => void): void {
  afterRun = { beat, film, then };
}

/** Called once per rendered frame while a run is over. `dt` is real seconds. */
function updateAfterRun(dt: number): void {
  const wait = afterRun;
  if (wait === null) return;
  if (mode !== 'over') {
    afterRun = null;
    return;
  }
  if (wait.film) {
    // The film owns the clock. `film` going null would mean it was reset out from
    // under us, which only a new run does - and that clears this anyway.
    if (renderer.film?.handedOver !== true) return;
  } else {
    wait.beat -= dt;
    if (wait.beat > 0) return;
  }
  afterRun = null;
  wait.then();
}

const input = new InputController(canvas, world, {
  onGestureStart: () => {
    telemetry.noteFirstInput();
    hintShown = true;
  },
  onStroke: (speed01, pan) => {
    if (mode === 'playing') audio.stroke(speed01, pan);
  },
});

/**
 * Where the next run starts, when it is not the beginning. Set by the admin
 * surface and kept across restarts - "play this water again" after a jump has to
 * mean the same station - and cleared by quitting to the title, which is the one
 * gesture that says "back to the actual game".
 */
let startAt: { act: Act; section: number } | null = null;

/**
 * Slowblue: the campaign, and the one rule that keeps it out of everything else.
 *
 * Each act is already a complete run - a world, a course, a score, an ending -
 * and `CampaignController` is deliberately headless: it owns no world, starts
 * nothing and reads no clock. So the whole of "seven acts are one game" is the
 * four places below that ask it what to play and tell it what happened, and
 * nothing in the simulation, the renderer or the shell knows a campaign exists.
 *
 * Resumed from the profile if there is one, so the title screen's first button
 * continues a circuit that was put down rather than restarting it. A save is
 * written at every station boundary and nowhere finer - see `meta/Campaign.ts`
 * for why a *mid*-station checkpoint would be a savegame of a simulation, and why
 * a station boundary is not.
 */
const campaign = CampaignController.from(profileStore.profile.saved);

/**
 * True while the run in progress is one the campaign is actually flying.
 *
 * An admin jump and the `?act=` dev door both play real acts in the real world,
 * and neither of them may advance a circuit or touch a record: the point of a
 * jump is to *see* the thing. This is the one condition that separates them.
 */
function inCampaign(): boolean {
  return startAt === null && !actDoor;
}

/**
 * `?seed=N` pins the *first* run of the session, so a shared link opens on exactly
 * the water it promises. After that the game deals normally - a seed parameter is a
 * way to reproduce one course, not a way to lock the game to it.
 */
let pendingSeed: number | null = readSeedParam();
function takeSeed(): number {
  const s = pendingSeed;
  pendingSeed = null;
  return s ?? randomSeed();
}

const shell = new Shell(stage, settings, profileStore.profile, {
  onStart: () => startRun(takeSeed()),
  onStartAct: (actIndex) => {
    // A fresh circuit entered at a later act, carrying what the acts before it
    // would have handed over. Zero cargo would open act VI with eighteen
    // droplets and no explanation; `population` gives it the shoal act I deals,
    // which is the only honest stand-in for a journey that was not flown.
    startAt = null;
    campaign.begin(actIndex, tuning.agentCount);
    profileStore.saveCampaign(campaign.state);
    shell.setProfile(profileStore.profile);
    startRun(takeSeed());
  },
  onResume: () => resume(),
  onPause: () => pause(),
  onRestart: (sameSeed) => startRun(sameSeed ? world.seed : takeSeed()),
  onQuit: () => toTitle(),
  onSettingsChange: (next) => applySettings(next),
  onResetProgress: () => {
    profileStore.reset();
    // The profile is not the only thing this game writes down. `tide.telemetry.v1`
    // holds a row per run - seed, act, how it ended, how long it took - and a
    // button that says it is erasing the whole journey and then leaves a record of
    // every run in it behind is lying to somebody who may have asked precisely
    // because the device is shared.
    telemetry.clear();
    shell.setProfile(profileStore.profile);
  },
  onMixer: (open) => {
    mixHold = open;
  },
  onPress: (bright) => {
    void audio.unlock().then((ready) => {
      if (ready) audio.ui(bright);
    });
  },
});

const loop = new GameLoop({
  fixedDt: 1 / 60,
  maxStepsPerFrame: 5,
  onStep: (dt) => {
    // The title is a held first frame, not a run nobody started. Apart from
    // avoiding invisible losses and completed courses behind the menu, this
    // guarantees that pressing Start always begins from the reset state shown.
    if (mode !== 'playing' || mixHold) return;
    if (hitstop > 0) {
      hitstop -= dt;
      return;
    }
    world.step(dt);
  },
  onRender: (alpha, stats) => {
    const frameDt =
      mode === 'paused' || mode === 'attract'
        ? 0
        : Math.min(0.05, loop.fixedDt + stats.frameMs / 1000);
    // Slowblue: `frameDt` is not wall-clock time and never was - it is `fixedDt` *plus* the
    // frame cost, which is roughly 2x real time at 60 fps and 3x at 120. Every effect
    // that reads it is a decay or a fade that was tuned against it, so it stays as it is.
    // Anything that has to happen at a *stated* rate needs the real clock: the breath
    // claims 11 seconds and the bubble stream claims a rate per second, and measured on
    // the real loop, both were running about three times too fast.
    const now = performance.now();
    const realDt = Math.min(0.25, Math.max(0, (now - lastFrameMs) / 1000));
    lastFrameMs = now;
    const events = world.takeEvents();
    handleEvents(events);
    // Phase watched here (not inside the step) so a failure triggered from
    // anywhere - including the debug surface - still closes the run.
    if (world.run.phase !== lastPhase) {
      lastPhase = world.run.phase;
      if (lastPhase === 'over') onRunEnded();
    }
    // ...and the wait that follows it, on the same clock the film is drawn on.
    updateAfterRun(realDt);
    updateFilmAudio();
    renderer.ingest(events);
    renderer.hudVisible = mode === 'playing';
    updateAudioBed(realDt);
    // ...and whether there is a context at all yet, which is what the corner
    // button off-run is drawn from and what a press on it means. Pushed like the
    // bed is, for the same reason: it changes under the player's first gesture
    // and nothing else redraws the shell at that moment. See `Shell.silent`.
    shell.setSoundLocked(!audio.unlocked);
    updateHint(frameDt);
    // One breath value, computed once, pushed to both the bed and the picture. They have
    // to be in phase or neither of them does anything, and two clocks cannot be.
    renderer.breath = breathAt(breathClock);
    // The frame's place between two simulation steps, handed to the world before
    // anything is drawn from it. The fish have always been drawn with it; this is
    // what puts the camera - and therefore the whole course - on the same moment.
    //
    // `realDt` rather than `frameDt`, because the drawn camera's ceiling is stated
    // in pixels per second and has to mean the same thing at 60 and at 120.
    world.advanceView(alpha, realDt);
    renderer.render(world, alpha, frameDt, flags, stats.fps);
    panel?.update();
    admin?.update();
    adaptQuality(stats.fps, frameDt);
  },
});

function buildDebugPanel(): DebugPanel {
  const built = new DebugPanel({
      tuning,
      flags,
      getStats: () => loop.stats,
      // `renderedDpr` and not `devicePixelRatio * dprScale`: the panel has to report the
      // ratio the backing store was actually allocated at, which is the clamped one.
      getQuality: () => ({
        rung: qualityRung,
        rungs: QUALITY_RUNGS.length,
        dpr: renderedDpr,
        mpx: backingMpx(),
      }),
      getQualityPin: () => (qualityPinned ? qualityRung : null),
      setQualityPin: pinQualityAt,
      getZone: () => world.zone,
      getSeed: () => world.seed,
      restart: (seed) => startRun(seed ?? world.seed),
      setTimeScale: (v) => {
        loop.timeScale = v;
      },
      getTimeScale: () => loop.timeScale,
      exportTelemetry: () => {
        void copyOrDownload('slowblue-telemetry.json', JSON.stringify(telemetry.snapshot(), null, 2));
      },
      clearTelemetry: () => telemetry.clear(),
  });
  document.querySelector('.slowblue-debug')?.classList.add('enabled');
  // Get out of the debug panel's corner. Both of them: there are two buttons on
  // the glass now, stacked, and moving only the top one leaves the mixer under
  // the debug toggle where nothing can press it.
  for (const b of document.querySelectorAll<HTMLElement>('.ui-corner')) {
    b.style.setProperty('right', '58px');
  }
  // The green overlay is the panel's other half, and it was wired to the same
  // switch at boot. Built late, it has to be turned on late too.
  flags.showStats = true;
  return built;
}
let panel = debugEnabled ? buildDebugPanel() : null;

function buildAdminPanel(): AdminPanel {
  return new AdminPanel({
      audio,
      play: (nextAct, section) => {
        startAt = { act: nextAct, section };
        startRun(takeSeed());
      },
      audible: (track) => settings.audio[track].enabled && settings.audio[track].volume > 0,
      unmuteAll: () => {
        const next = { ...settings.audio };
        for (const key of AUDIO_TRACK_KEYS) {
          next[key] = { enabled: true, volume: Math.max(0.6, next[key].volume) };
        }
        applySettings({ ...settings, audio: next, muted: false });
      },
      setAudioOverride: (on) => {
        audioOverride = on;
        // Hand the bed back the way the game left it, so closing the tab mid-run
        // does not leave a shimmer hanging on a slider nobody is touching.
        if (!on) audio.setRingHold(0, 0);
      },
      setFrozen: (frozen) => {
        // Restore what the clock was, not 1: the tuning panel next door owns a
        // slow-motion button, and a run being read at 0.25x should still be at
        // 0.25x when the sheet closes.
        if (frozen) frozenFrom = loop.timeScale;
        loop.timeScale = frozen ? 0 : frozenFrom;
        if (!frozen) loop.resync();
      },
      here: () => ({
        act: world.act.key,
        level: world.levelIndex,
        section: world.sectionId,
        medium: world.medium.kind,
      }),
  });
}
let admin = adminEnabled ? buildAdminPanel() : null;

/**
 * The way into both panels on a device, where there is no address bar to type in.
 *
 * `?debug=1` and `?admin` are the doors everywhere else, and an installed PWA has
 * neither: it launches from its home-screen icon with no query string, so on the one
 * device the numbers are actually about, both surfaces are unreachable. The `perf`
 * and `pinQuality` doors on `__slowblue` were cut for that same wall - but a console
 * on a Mac is a poor way to work a panel, and the act switcher is the thing a round
 * on a phone needs most.
 *
 * A gesture rather than a button, because a button that is always there is a button
 * that ships. Three fingers held still for a second and a half, and never while a run
 * is live: this game is stirred with one finger and occasionally two, a third held
 * that long is not something a player does by accident, and off-run there is no water
 * to disturb anyway. Nothing is persisted - a reload is the way back out, which also
 * means a player who somehow found it cannot keep it.
 */
const ADMIN_GESTURE_FINGERS = 3;
const ADMIN_GESTURE_MS = 1500;
let adminGestureTimer = 0;

function cancelAdminGesture(): void {
  if (adminGestureTimer === 0) return;
  window.clearTimeout(adminGestureTimer);
  adminGestureTimer = 0;
}

function openDebugSurfaces(): void {
  panel ??= buildDebugPanel();
  admin ??= buildAdminPanel();
}

function randomSeed(): number {
  return (Math.random() * 0xffffffff) >>> 0;
}

function readSeedParam(): number | null {
  const raw = params.get('seed');
  if (raw === null) return null;
  const n = Number(raw);
  return Number.isFinite(n) ? n >>> 0 : null;
}

function readInsets(): { top: number; bottom: number; left: number; right: number } {
  if (probe === null) return { top: 0, bottom: 0, left: 0, right: 0 };
  const cs = getComputedStyle(probe);
  return {
    top: parseFloat(cs.paddingTop) || 0,
    bottom: parseFloat(cs.paddingBottom) || 0,
    left: parseFloat(cs.paddingLeft) || 0,
    right: parseFloat(cs.paddingRight) || 0,
  };
}

/**
 * The descent, cheapest loss first.
 *
 * There used to be a Quality setting here - auto, high, low - and it was three
 * kinds of wrong at once. `high` returned auto's own numbers and its only real
 * effect was to switch the rescue below *off*, so the option named for the best
 * picture was strictly worse than the default. `low` was the only thing in the
 * game that ever lowered the particle budget, which made the one dial that
 * actually saves a weak phone reachable only by a player who went looking for a
 * technical menu and guessed right. And `auto`, the default everybody was on,
 * could only drop the resolution, because the scaler had no other move.
 *
 * So the ladder is the setting now, and the order is the whole design: the
 * drawing is thinned twice before the resolution is touched at all. A phone that
 * has lost some of its marine snow still looks like this game; a phone rendered
 * at 0.7 looks like a photograph of it. The bottom two rungs together are what
 * `low` used to do in one jump - the floor of a slope rather than a switch nobody
 * found.
 */
const QUALITY_RUNGS: readonly { particles: number; dpr: number }[] = [
  { particles: 1, dpr: 1 },
  // Past 0.6 the renderer drops fins, fingers, halos and the four-band gradients.
  { particles: 0.55, dpr: 1 },
  // ...and past 0.5 the decorative layer stops being drawn at all.
  { particles: 0.45, dpr: 1 },
  { particles: 0.45, dpr: 0.8 },
  { particles: 0.45, dpr: 0.7 },
];

function resize(): void {
  const w = Math.max(240, Math.round(window.innerWidth));
  const h = Math.max(320, Math.round(window.innerHeight));
  const dpr = clamp(window.devicePixelRatio || 1, 1, 2) * dprScale;
  renderer.setInsets(readInsets());
  renderer.resize(w, h, dpr);
  renderedDpr = dpr;
  if (w !== world.width || h !== world.height) world.resize(w, h);
}

/**
 * What the renderer is told about how to draw, assembled in one place.
 *
 * Two callers with nothing else in common: a settings change, and the frame-rate
 * scaler moving `particleScale` mid-run. Building the object twice is how the
 * scaler used to be able to forget a field.
 */
function renderStyle(): RenderStyle {
  return {
    quality: particleScale,
  };
}

function applySettings(next: Settings): void {
  Object.assign(settings, next);
  saveSettings(settings);
  renderer.setStyle(renderStyle());
  audio.setMuted(settings.muted);
  audio.setLevels(settings.audio);
  // Unconditional. Whether this change needs to be drawn is a question about who
  // originated it, which only the shell can answer - and it does, in `setSettings`.
  // The screen-name test that used to stand here could not: it named the settings
  // screen, so the mixer drawer on the glass, which lives on `playing`, had every
  // fader torn out from under the drag that was moving it.
  shell.setSettings(settings);
}

/** Slowblue: if the device cannot hold the frame, spend resolution, never latency. */
/**
 * Move to a rung. Only the dials that actually changed are paid for.
 *
 * A particle step is a `setStyle` and nothing else; a resolution step is a
 * `resize`, which reallocates the backing store and rebuilds the cached
 * gradients. Doing both on every rung would make the two cheap steps cost what
 * the expensive one costs.
 */
function setQualityRung(next: number): void {
  const rung = QUALITY_RUNGS[next]!;
  const dprChanged = rung.dpr !== dprScale;
  qualityRung = next;
  particleScale = rung.particles;
  dprScale = rung.dpr;
  renderer.setStyle(renderStyle());
  if (dprChanged) resize();
}

/**
 * Holds the ladder at a rung, or lets it go again (`null`).
 *
 * One body, two callers - the ⚙ panel's row of pins and `__slowblue.pinQuality` ask
 * the same thing, and a second copy of this would be a second place to forget the
 * sample window. It was two: the panel could only pin rung 0, so it carried its own
 * shorter version of this.
 */
function pinQualityAt(rung: number | null): void {
  if (rung === null) {
    qualityPinned = false;
  } else {
    // Climbing back is what the scaler does over eight seconds of good frames; a
    // measurement cannot wait for that, and a pin that left the run three rungs down
    // from where it was asked for would be a pin that lies about what it pinned.
    setQualityRung(clamp(Math.round(rung), 0, QUALITY_RUNGS.length - 1));
    qualityPinned = true;
  }
  // The scaler's own patience, restarted. Leaving these standing means a release can
  // step down 2.5 s later on evidence gathered while the ladder was held.
  lowFpsFor = 0;
  highFpsFor = 0;
  // ...and the 300 frames the ring took at whatever the ladder had retreated to,
  // which would otherwise be averaged into the reading the pin was flipped to take.
  loop.resetSamples();
}

/**
 * The frame-rate rescue, and the way back up from it.
 *
 * Going down was all this ever did, and that was the second half of the old
 * setting's problem: one bad stretch - an act with weather in it, a phone that
 * got hot, another tab compiling something - permanently spent a step of picture
 * quality for the rest of the session, and nothing ever gave it back. With five
 * rungs instead of two that would compound into a game that quietly got uglier
 * the longer anyone played it.
 *
 * So it climbs back, and the two thresholds are deliberately far apart. The
 * frame rate a rung buys is, by construction, only just better than the rate
 * that cost it, so a narrow band would step down and up forever - and every one
 * of those steps is visible. Down at 45 after two and a half seconds; up at 58
 * after eight.
 */
function adaptQuality(fps: number, dt: number): void {
  if (qualityPinned || fps === 0) return;
  if (fps < 45) {
    highFpsFor = 0;
    if (qualityRung >= QUALITY_RUNGS.length - 1) return;
    lowFpsFor += dt;
    if (lowFpsFor > 2.5) {
      setQualityRung(qualityRung + 1);
      lowFpsFor = 0;
    }
    return;
  }
  lowFpsFor = Math.max(0, lowFpsFor - dt);
  if (fps > 58 && qualityRung > 0) {
    highFpsFor += dt;
    if (highFpsFor > 8) {
      setQualityRung(qualityRung - 1);
      highFpsFor = 0;
    }
  } else {
    highFpsFor = Math.max(0, highFpsFor - dt);
  }
}

/**
 * The two continuous audio signals: where in the campaign we are, and how full the ring
 * currently being worked is. Both are pushed every frame rather than fired on an
 * event, because both are things the player is *doing*, not things that happened.
 */
/** `dt` here is real seconds, not the renderer's `frameDt`. See `onRender`. */
function updateAudioBed(dt: number): void {
  audio.tick(dt);
  // The breath runs on wall-clock time, not run time, so the bed and the picture keep
  // breathing together on the title screen, through a pause and over the ending - it is
  // addressed to the player rather than to the shoal.
  breathClock += dt;
  audio.setBreath(breathAt(breathClock));
  if (audioOverride) return;
  pushBed();
  if (mode !== 'playing') {
    audio.setRingHold(0, 0);
    return;
  }
  let hold = 0;
  let presence = 0;
  let pan = 0;
  for (const pod of world.rescue.pods) {
    if (pod.merged || !pod.required) continue;
    const contact = pod.contact / 0.5;
    // Pan follows the ring that is furthest along, so the shimmer never jumps between
    // two rings while the player is holding one of them.
    if (contact >= hold) pan = panOf(pod.x);
    hold = Math.max(hold, contact);
    presence = Math.max(presence, pod.presence);
  }
  audio.setRingHold(hold, presence, pan);
}

/**
 * Which of the eight beds the station is in, and how far through its act it is.
 *
 * The whole of the game's opinion about the mix, in four lines. `bedFor` needs the
 * act as well as the medium because two acts are flown in water and mean opposite
 * things by it - see `audio/Beds.ts` - and the arc is act progress rather than
 * anything about altitude, because it is the one quantity every act has and every
 * bed can read as its own.
 *
 * The bug this replaced is worth naming. Depth used to be `1 - ascent` for
 * everything that was not air, which is correct for act I and backwards for act
 * VII: the last act descends from twenty metres to the trench floor, and the bed
 * spent the whole of it getting *brighter* while the picture went dark. Now the
 * direction is the bed's own (`AudioEngine.setBed`), and act VII sinks.
 *
 * It also runs while the shell is up, not only while a run is in progress, so the
 * title screen and the pause screen are in the room the player left rather than in
 * act I's.
 */
function pushBed(): void {
  const station = levelAtIn(world.act, world.levelIndex);
  const arc = (world.levelIndex + world.levelProgress) / world.act.levels.length;
  audio.setBed(bedFor(world.act.key, world.medium.kind), arc, station.depthMeters);
  shell.setBed(audio.currentBed);
}

/** World x -> -1..1 stereo position. Everything localised in the mix goes through this. */
function panOf(x: number): number {
  return world.width > 0 ? clamp((x / world.width) * 2 - 1, -1, 1) : 0;
}

function updateHint(dt: number): void {
  const wantHint =
    mode === 'playing' && !hintShown && !world.hasInput && world.run.time > HINT_DELAY;
  const target = wantHint ? 1 : 0;
  renderer.hintAlpha += (target - renderer.hintAlpha) * Math.min(1, dt * 4);
  if (world.hasInput) hintShown = true;
}

/**
 * Slowblue: the campaign, written down. Once per station, and nowhere else.
 *
 * The whole of "a cleared station stays cleared" is these five lines. `station` is
 * the next one to play, so what lands on disk is a place to resume rather than a
 * receipt for somewhere the player has already been - which is the off-by-one this
 * feature is entirely made of, and it is settled at the one call site rather than
 * argued about at four.
 *
 * A jump and the `?act=` door check out here for the same reason they check out of
 * the records: the point of a jump is to *see* a station, and a circuit that was
 * put down in act V may not be moved by somebody looking at act II's water.
 *
 * The station record goes with it. It used to be written only when a run ended,
 * which was fine while a lost run was the only way out of an act - and is not fine
 * now that a failure restarts the station instead, because then the map would only
 * learn what the player had cleared if they flew the act all the way to its end.
 * It is a high-water mark (`Math.max` inside), so writing it six times an act
 * cannot overstate anything.
 */
function checkpoint(station: number): void {
  if (!inCampaign()) return;
  campaign.checkpoint(world.run, station, world.shoalCount);
  profileStore.saveCampaign(campaign.state);
  profileStore.recordStations(world.act.key, station);
  shell.setProfile(profileStore.profile);
}

/**
 * One of the act attempt's restarts, spent.
 *
 * The sim spends its own copy of the budget the moment it puts the station back;
 * this is the campaign's copy, which is the one that survives the app being
 * closed. They are seeded from each other at `startRun` and can only disagree for
 * the length of one frame.
 */
function campaignRestart(): void {
  if (!inCampaign()) return;
  campaign.noteRestart();
  profileStore.saveCampaign(campaign.state);
}

/**
 * What the campaign has to write down, before anything is heard or felt.
 *
 * These two are bookkeeping and the rest of `handleEvents` is presentation, and
 * they are separated because the presentation half is rightly gated on
 * `mode === 'playing'` - a hunter's bite that lands the frame a dialog opens must
 * not be heard behind it - while the bookkeeping half must not be gated on
 * anything. `takeEvents` empties the queue whether or not anybody reads it, so an
 * early return *discards* what it was handed, and the frame most likely to hit one
 * is the frame the app goes to the background. That is precisely the frame this
 * whole feature exists for: a station cleared or a restart spent in the last tick
 * before a phone is locked has to be on disk, not dropped because the shell had
 * already changed screens.
 */
function recordEvents(events: ReturnType<World['takeEvents']>): void {
  for (const e of events) {
    if (e.type === 'level') checkpoint(e.value);
    else if (e.type === 'restart') campaignRestart();
  }
}

function handleEvents(events: ReturnType<World['takeEvents']>): void {
  recordEvents(events);
  if (mode !== 'playing') return;
  for (const e of events) {
    switch (e.type) {
      case 'rescue':
        audio.rescue(e.value, panOf(e.x));
        haptic('rescue');
        break;
      case 'reform':
        audio.reform();
        haptic('reform');
        break;
      case 'gate':
        audio.gate(e.value);
        break;
      case 'streakBreak':
        audio.streakBreak();
        break;
      case 'loss':
        audio.loss(e.value, panOf(e.x));
        break;
      case 'bite':
        audio.bite(panOf(e.x));
        haptic('bite');
        hitstop = HITSTOP;
        break;
      // Nothing, and measured rather than assumed. A zone boundary inside a
      // station is answered continuously and by two channels already - the
      // palette crossfades across it and the bed follows it down - so the event
      // exists for anything that needs the *moment*, and nothing does.
      // `AudioEngine.zone` is still there and still reachable from the admin
      // surface, which is where a cue nobody fires belongs.
      case 'zone':
        break;
      // The save for this one is written in `recordEvents`, above, which is not
      // gated on the mode. What is left here is what the player hears and feels.
      case 'level':
        audio.level(e.value);
        haptic('level');
        break;
      case 'restart':
        audio.restart();
        haptic('restart');
        break;
      case 'ring':
        audio.ring(panOf(e.x));
        haptic('ring');
        break;
      case 'ringLost':
        audio.ringLost();
        haptic('ringLost');
        break;
      case 'complete':
        audio.complete();
        haptic('complete');
        // The closing cue is not fired here. It belongs on the frame its movement
        // actually turns on - the breach, the sunrise, the closed disc - and the
        // film is the only thing that knows when that is. See `updateFilmAudio`.
        break;
      case 'fail':
        break;
    }
  }
}

/**
 * The film's own cue, on the film's own frame.
 *
 * Each ending has one moment that is the sound - the shoal crossing the
 * waterline, the sun clearing the limb, the Earth closing into a disc - and the
 * cue has to land on it. It used to be a `setTimeout` counted from the frame the
 * last section was cleared, which is the wrong clock twice over: the films
 * advance on `frameDt` rather than on wall time, and a device holding a different
 * frame rate put the sound somewhere else in the picture. Watching the phase
 * change costs one string compare a frame and cannot drift.
 */
let filmPhase = '';

function updateFilmAudio(): void {
  const film = renderer.film;
  const now = film === null ? '' : `${film.kind}:${film.phase}`;
  if (now === filmPhase) return;
  filmPhase = now;
  // Defensive even though the title now holds the world still: an ending nobody
  // earned does not get an ending's sound.
  if (mode === 'attract') return;
  switch (now) {
    case 'surfacing:breach':
      audio.surface();
      break;
    case 'release:sunrise':
      audio.release();
      break;
    // The frame the air stops carrying anything, which is the frame the ice in
    // it stops. Everything the cue does after that is get quieter.
    case 'karman:stroke':
      audio.airless();
      break;
    case 'overview:line':
      audio.overview();
      break;
    // The frame the fire goes out and the gold is visible inside it.
    case 'nucleus:seed':
      audio.nucleus();
      break;
    // The frame the gold starts moving by itself.
    case 'estuary:quicken':
      audio.estuary();
      break;
    // The frame the settled gold begins playing the journey back. One whole
    // movement ahead of act VII's own cue, and its tails are meant to run into it:
    // a seam between the recapitulation and `circle()` is the one thing this film
    // cannot have.
    case 'circle:remember':
      audio.remembrance();
      break;
    // The frame the first fish arrives out of the dark.
    case 'circle:gather':
      audio.circle();
      break;
    // The frame the carried light starts being put down, over a cue that is still
    // holding the root.
    case 'circle:vigil':
      audio.vigil();
      break;
    default:
      break;
  }
}

function onRunEnded(): void {
  if (mode === 'attract') {
    // The title screen keeps a run going behind the menu; when it dies, deal a new one.
    world.reset(randomSeed());
    lastPhase = 'running';
    renderer.syncRun(world);
    return;
  }
  const slowRatio =
    loop.stats.totalFrames === 0 ? 0 : loop.stats.slowFrames / loop.stats.totalFrames;
  telemetry.endRun(world, loop.stats.fps, slowRatio);
  const result = runResult(world.run, world.run.zone);
  // A run the admin surface dropped into the fifth station is not a run the player
  // flew, so it does not touch their records. Neither is one the `?act=` door
  // opened, and that half was missing: the door checked out of the *campaign* but
  // still wrote to the profile, so an act jumped into and played badly could take
  // a personal best with it. `inCampaign` is the one condition, and now both
  // readers ask it. The results screen still shows what happened - the point of a
  // jump is to see the thing - it is only the profile that stays honest.
  const records: RecordDelta = inCampaign()
    ? profileStore.record(result)
    : { score: false, depth: false, gates: false };
  // ...and how far into this particular act it got, which is the one thing the
  // circuit screen draws that no other field can answer. `run.level` is the
  // furthest station reached rather than a count of clears, so an act III retry
  // cannot claim ground it did not take.
  if (inCampaign()) profileStore.recordStations(world.act.key, world.run.level);
  shell.setProfile(profileStore.profile);

  /*
   * Slowblue: the seam between two acts, and the reason it is here rather than in the
   * shell.
   *
   * An act that was flown to its end is not a run that finished - it is a
   * handover, and the campaign has six of them. So a completed act inside a live
   * campaign never reaches the results screen at all: the film plays out to its
   * own end, the controller folds in the score and the carried life, and the next
   * act begins on the same seed continuing from what arrived. The player is not
   * asked anything and nothing is put over the picture.
   *
   * The seventh act is the exception, because after it there is no next one. That
   * one closes the circuit, banks it, and hands back to the title - which is where
   * the last frame was always going.
   */
  const endedAct = world.act.key;
  if (inCampaign() && world.run.completed) {
    const carried = world.shoalCount;
    if (campaign.advance(world.run, carried)) {
      profileStore.saveCampaign(campaign.state);
      shell.setProfile(profileStore.profile);
      setMode('over');
      shell.hideChrome();
      // The handover gets the whole of the outgoing act's film before the next
      // one opens. What it must never be is a dialog.
      scheduleAfterRun(NO_FILM_BEAT, filmForAct(endedAct) !== null, () => startRun(takeSeed()));
      haptic('actHandover');
      return;
    }
    // The circuit closed. Trench floor to trench floor, and the only screen in
    // the game that reports the journey rather than the leg.
    const total = campaign.total(0);
    profileStore.recordCampaign(total, carried);
    shell.setProfile(profileStore.profile);
    /*
     * ...unless the player has asked for the circle to keep turning.
     *
     * §11 unlocks continuous circuit mode after a full campaign, and this is the
     * whole of it: the seventh act hands back to the first exactly as the other
     * six hand on, so the one screen in an otherwise unbroken journey goes away.
     * It costs nothing to implement because `render/Circle.ts` was already built
     * for it - the film dissolves the trench floor into act I's first frame, and
     * with this on that dissolve stops being a metaphor and becomes the cut.
     *
     * The circuit is still banked first. A player running the loop is playing
     * for records like anyone else, and each closed circle counts.
     */
    if (settings.circuit) {
      campaign.begin(0, carried);
      profileStore.saveCampaign(campaign.state);
      shell.setProfile(profileStore.profile);
      setMode('over');
      shell.hideChrome();
      scheduleAfterRun(NO_FILM_BEAT, filmForAct(endedAct) !== null, () => startRun(takeSeed()));
      haptic('circuitClosed');
      return;
    }
    closedCircuit = { score: total, carried, cycles: profileStore.profile.cycles };
  } else if (inCampaign() && !world.run.completed) {
    /*
     * The act attempt is over: two stations were put back and a third failure
     * came anyway.
     *
     * This is the one place a campaign run ends without finishing its act, and it
     * is where the difference between *dying* and *being interrupted* is actually
     * made. Nothing runs when an app is killed, so an interruption leaves the last
     * station checkpoint standing and the player comes back to it. A death runs
     * this, and this writes the act's own beginning over that checkpoint.
     *
     * No flag, no "was this exit clean" test, and nothing to get wrong about a
     * crash - a crash simply does not reach this line. The known cost is that
     * killing the app *before* dying keeps the station, which is a trade the design
     * takes deliberately: the alternative charges every real interruption for the
     * few that were not.
     */
    campaign.loseAct();
    profileStore.saveCampaign(campaign.state);
    shell.setProfile(profileStore.profile);
  }

  setMode('over');
  // Nothing on the glass but the water for the length of the ending.
  shell.hideChrome();
  // The ending gets a beat to itself. A ring opening, or a shoal coming apart, is
  // the last thing the run says; putting a dialog over it half a second later
  // turns it into a transition. The mode is already 'over', so nothing the player
  // does in the meantime touches the water.
  // A completed act gets its whole ending - the surfacing's beat of sky, the
  // release's beat of night, the overview's held Earth - before anything is asked
  // of the player again. That wait *is* the reward; a results dialog dropped over
  // it would be the game taking it back.
  const hasFilm = world.run.completed && filmForAct(endedAct) !== null;
  const circuit = closedCircuit;
  closedCircuit = null;
  scheduleAfterRun(world.run.completed ? NO_FILM_BEAT : 1.2, hasFilm, () => {
    shell.show('over', {
      result,
      records,
      reason: world.run.reason,
      seed: world.seed,
      act: endedAct,
      ...(circuit === null ? {} : { circuit }),
    });
  });
  // A completed dive and a missed ring have already said their piece through the
  // sim events; only the two silent endings need the fail chord.
  if (!world.run.completed && world.run.reason !== 'ringMissed') audio.fail();
  if (records.score && result.score > 0) {
    renderer.celebrate();
    window.setTimeout(() => audio.record(), 700);
  }
  haptic('runEnd');
}

function setMode(next: Mode): void {
  mode = next;
}

function startRun(seed: number): void {
  clearAfterRun();
  let section = startAt?.section ?? 0;
  // Unbounded unless a circuit says otherwise, and set on *every* run rather than
  // only on the campaign's, because it is a field on a long-lived world: a jump
  // taken after a campaign run would otherwise inherit that run's remaining
  // restarts and end a dev inspection on its third mistake.
  world.restartBudget = Infinity;
  if (startAt !== null) world.setAct(startAt.act);
  else if (inCampaign()) {
    // The campaign decides what is played and what it opens with. `startPopulation`
    // is the only mechanical statement the whole game makes of its own premise:
    // an act begins with what the last one handed over.
    world.setAct(campaign.act);
    world.startPopulation = campaign.population(tuning.agentCount);
    // ...and how many restarts this act attempt has left, which is a campaign
    // fact rather than a run one: a station put back before the player closed the
    // app stays put back. See `meta/Campaign.ts`.
    world.restartBudget = campaign.attemptsLeft;
    campaign.beginRun();
    // ...and *where* it opens, which is the other half of the same statement now
    // that the save names a station. The world is rebuilt from the station's own
    // first section by the same call that builds any run - the seed and the
    // section are the whole of the restore, and there is no simulation state in
    // it. `levelStartSectionIn` answers -1 for a station that no longer exists,
    // which the clamp reads as the top of the act.
    section = Math.max(0, levelStartSectionIn(campaign.act, campaign.stationIndex));
  }
  world.reset(seed, section);
  // Whether finishing *this* act finishes the game. Inside a circuit only the
  // seventh does; an act opened on its own is its own whole thing and ends like
  // one. The banner over the ending is the only thing that reads it, and getting
  // it wrong told the player the campaign was over six times.
  renderer.finale = !inCampaign() || !campaign.hasNext;
  // How many restarts a whole attempt gets, which is the denominator the corner
  // marks are drawn from. Zero outside a circuit: a jump is not an attempt.
  // The act's own budget, not a constant: a twenty-six-minute act carries more
  // than a ten-minute one. See `restartsForMinutes`.
  renderer.attemptsTotal = inCampaign() ? campaign.act.restarts : 0;
  lastPhase = 'running';
  hintShown = false;
  hitstop = 0;
  renderer.hintAlpha = 0;
  renderer.syncRun(world);
  telemetry.beginRun(world.seed);
  loop.resync();
  if (loop.timeScale === 0) loop.timeScale = 1;
  setMode('playing');
  shell.show('playing');
  void audio.unlock();
}

function pause(): void {
  if (mode !== 'playing') return;
  setMode('paused');
  shell.show('paused');
  audio.suspend();
}

function resume(): void {
  if (mode !== 'paused') return;
  setMode('playing');
  shell.show('playing');
  loop.resync();
  audio.resume();
}

function toTitle(): void {
  clearAfterRun();
  // Quitting is the one gesture that means "back to the game as shipped": whatever
  // the admin surface last jumped to is forgotten here, act included.
  startAt = null;
  // ...and the campaign goes back to wherever it was actually saved. Quitting out
  // of act V does not restart the circuit - the save is the record of where the
  // player got to, and the title screen's first button continues from it.
  campaign.state = CampaignController.from(profileStore.profile.saved).state;
  world.startPopulation = null;
  world.setAct(act);
  world.reset(randomSeed());
  lastPhase = 'running';
  hitstop = 0;
  renderer.syncRun(world);
  loop.resync();
  setMode('attract');
  shell.show('title');
  audio.resume();
}

window.addEventListener('resize', resize);
window.addEventListener('orientationchange', () => setTimeout(resize, 120));
window.visualViewport?.addEventListener('resize', resize);
document.addEventListener('visibilitychange', () => {
  // Never burn battery or fast-forward the sim in a background tab.
  if (document.hidden) {
    loop.stop();
    audio.suspend();
    if (mode === 'playing') pause();
  } else {
    loop.resync();
    loop.start();
    if (mode !== 'paused') audio.resume();
  }
});
/*
 * The window that is still on screen and is no longer the player's.
 *
 * On a phone the lifecycle is the handler above and nothing else: leaving the app
 * hides the page. On an iPad it is half of one. Split View and Slide Over leave the
 * game visible, drawing and *simulating* while the player is typing in the app next
 * to it - the page never goes hidden, so nothing fires, and a hunter clears the
 * shoal behind a message being written. A notification shade pulled down over a run
 * and a call banner are the same gap on both devices.
 *
 * `blur` is the event for that state, and `InputController` has trusted it for
 * exactly this reason since long before there was an app: it drops every live
 * pointer when the page loses focus. This is the other half of the same event -
 * losing focus also pauses the run.
 *
 * Only the run. The title screen keeps its water moving next to another app on
 * purpose, and coming back does not unpause: the player says when they are ready,
 * which is the rule backgrounding already follows and `e2e/unlock.spec.ts` states.
 * Backgrounding fires both events, in this order; `pause()` is idempotent, so the
 * `visibilitychange` behind this one finds a game that is already paused.
 */
window.addEventListener('blur', () => {
  if (mode === 'playing') pause();
});
// The three-finger hold that opens the panels on a device. See `openDebugSurfaces`.
document.addEventListener(
  'touchstart',
  (e) => {
    // Any change in the number of fingers restarts the question, so a fourth finger
    // is not three and a hand put down one finger at a time still counts from the
    // moment the third arrives.
    cancelAdminGesture();
    if (mode === 'playing' || e.touches.length !== ADMIN_GESTURE_FINGERS) return;
    adminGestureTimer = window.setTimeout(() => {
      adminGestureTimer = 0;
      openDebugSurfaces();
    }, ADMIN_GESTURE_MS);
  },
  { passive: true },
);
document.addEventListener('touchend', cancelAdminGesture, { passive: true });
document.addEventListener('touchcancel', cancelAdminGesture, { passive: true });
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    shell.escape();
    return;
  }
  if (e.key === 'p' || e.key === 'P') {
    if (mode === 'playing') pause();
    else if (mode === 'paused') resume();
    return;
  }
  if (e.key === 'r' || e.key === 'R') {
    if (mode === 'playing' || mode === 'over' || mode === 'paused') startRun(world.seed);
    return;
  }
  if ((e.key === ' ' || e.key === 'Enter') && mode === 'attract') {
    const active = document.activeElement;
    // Do not steal the key from whichever shell button already has focus - and
    // never start a run from a screen that has not offered one. The ident had to
    // learn the same thing; see its `onKey`.
    if (shell.current === 'title' && (active === null || active === document.body)) {
      startRun(randomSeed());
    }
  }
});
// Every real gesture is a chance to wake Web Audio again. Mobile Safari can move
// the context to `interrupted` after a tab/app switch, even if the first unlock
// succeeded, so these listeners deliberately are not one-shot.
document.addEventListener('pointerdown', () => void audio.unlock(), { capture: true });
// ...and the *end* of a touch, because for a finger the start of one is not a
// gesture at all. Browsers grant user activation on `pointerdown` only for a mouse;
// a touch earns it at `pointerup`/`touchend`. So on a phone the listener above
// creates a context it is not allowed to start, and a tap on the canvas mid-run -
// which has no `click` behind it, unlike every shell button - could never bring a
// stopped one back. Both, because WebKit has historically keyed its audio unlock
// to `touchend` itself. `unlock()` is idempotent; see `e2e/unlock.spec.ts`.
document.addEventListener('pointerup', () => void audio.unlock(), { capture: true });
document.addEventListener('touchend', () => void audio.unlock(), { capture: true });
/**
 * ...and the keyboard, which was not covered and had to be.
 *
 * A player at a desk skips the studio ident with the space bar as readily as with
 * the mouse, and that keystroke is a user gesture like any other - but it never
 * reached anything that opened the audio context, so the whole opening played
 * silent for them and the water only arrived under their first click. The ident
 * eats keystrokes on purpose (see its `onKey`: one press must not both dismiss it
 * and start a run behind it), which is why this is on `window` in the capture
 * phase and registered *here* - above `playDigitalTulpaIdent`, so it is in the
 * queue before the listener that stops the event travelling.
 */
window.addEventListener('keydown', () => void audio.unlock(), { capture: true });

const introParam = params.get('intro');

applySettings(settings);
resize();
loop.start();
shell.show('title');
/**
 * The ident plays in full, always.
 *
 * It used to consult a stored reduced-motion setting, and the result was that most
 * phones never saw it: that setting seeded itself from `prefers-reduced-motion`,
 * iOS puts Reduce Motion one tap into Accessibility, and plenty of people leave it
 * on for reasons that have nothing to do with this game. What they got instead was
 * a logo that appeared and vanished in 1.2 seconds - which reads as a bug, and was
 * reported as one. The setting is gone now and the ident is unaffected either way:
 * it is a seven-second fade with a two-pixel eye performance inside it, and there
 * was never any vestibular load in it to suppress.
 *
 * `?intro=reduced` still opens the quiet variant, because it is worth being able to
 * look at - it is the brand package's own option, set here from the URL and from
 * nothing else. `?intro=summon` and `?intro=reveal` open the two performances
 * directly; which one a plain launch gets is `DEFAULT_IDENT_VARIANT`'s call, and it
 * is the studio's to make rather than this game's.
 */
playDigitalTulpaIdent({
  variant: introParam === 'reveal' || introParam === 'summon' ? introParam : DEFAULT_IDENT_VARIANT,
  reducedMotion: introParam === 'reduced',
  force: introParam !== null,
  skip: params.has('skipIntro'),
});
/**
 * ...and the water is asked for the moment it clears.
 *
 * Where the browser allows it - a desktop one, or any launch the player has
 * already touched - the beds come up on their own six-second fade
 * (`AudioEngine.build`) and the title screen is not a silent screen. Where it
 * does not, this is a no-op and the first real gesture is what opens the
 * context: the `pointerdown` and `keydown` listeners above are on `window` in
 * the capture phase for exactly that, and they are not one-shot.
 */
window.addEventListener('digitaltulpa:introcomplete', () => void audio.unlock(), { once: true });
registerServiceWorker();

// Small, stable surface for the e2e smoke test and for on-device poking.
window.__slowblue = {
  world,
  restart: (seed) => startRun(seed ?? world.seed),
  start: (seed) => startRun(seed ?? takeSeed()),
  jump: (actKey, station = 0, seed) => {
    const target = actByKey(actKey);
    startAt = { act: target, section: Math.max(0, levelStartSectionIn(target, station)) };
    startRun(seed ?? world.seed);
  },
  metrics: () => ({
    mode,
    screen: shell.current satisfies ShellScreen,
    // Which act is actually on the glass, and where the circuit thinks it is.
    // A handover is the one thing in this game that changes the first without
    // the player doing anything, so both have to be readable from outside.
    act: world.act.key,
    actIndex: campaign.actIndex,
    // Where a reload would put the player: the station the circuit is saved at,
    // which is the next one to start rather than the last one cleared. The only
    // way an outside observer can check the off-by-one this feature is made of.
    station: campaign.stationIndex,
    // Restarts left in this act attempt, and what the sim is actually working
    // from. They are seeded from each other and may differ for one frame.
    attempts: campaign.attemptsLeft,
    restartsLeft: world.restartsLeft,
    campaign: inCampaign(),
    cargo: campaign.state.cargo,
    banked: campaign.state.banked,
    actsCleared: campaign.state.actsCleared,
    cycles: profileStore.profile.cycles,
    phase: world.run.phase,
    reason: world.run.reason,
    // Which ending is on screen and which of its movements. The films own their
    // own clocks, so this is the only honest way for anything outside to know
    // where one has got to - `e2e/acts.spec.ts` shoots a frame per movement off
    // it rather than guessing at wall-clock marks that would be wrong by the
    // frame cost. See `render/Films.ts`.
    film: renderer.film?.kind ?? null,
    filmPhase: renderer.film?.phase ?? null,
    filmHandedOver: renderer.film?.handedOver ?? false,
    count: world.shoalCount,
    score: world.run.score,
    gates: world.run.gates,
    streak: world.run.streak,
    multiplier: world.run.multiplier,
    zone: world.zone,
    level: world.levelIndex,
    levelsCleared: world.run.levelsCleared,
    ringsHeld: world.run.ringsHeld,
    completed: world.run.completed,
    requiredRings: world.rescue.pods.filter((p) => p.required && !p.merged).length,
    rescued: world.run.rescued,
    lost: world.run.lost,
    gestures: world.gestureCount,
    fieldMeanSpeed: world.field.meanSpeed(),
    centroidX: world.swarm.centroid().x,
    centroidY: world.swarm.centroid().y,
    spread: world.swarm.spread(),
    cameraY: world.cameraY,
    time: world.run.time,
    fps: loop.stats.fps,
    hint: renderer.hintAlpha,
    // Where the canvas put its right-hand column this frame, so a test can hold
    // it against the DOM buttons standing over the same corner. See
    // `HUD_COLUMN_TOP` and `e2e/chrome.spec.ts`.
    hudColumnTop: renderer.hudColumnTop,
    // The other two things standing in that corner, for the same test: the top of
    // the progress rail's counter, and the bottom of the streak badge it has to
    // clear on a window short enough to bring them together. See `drawProgress`.
    railCounterTop: renderer.railCounterTop,
    streakBadgeBottom: renderer.streakBadgeBottom,
    dpr: renderedDpr,
    // The audio handshake, from outside. Three fields rather than one, because the
    // failure this exists to catch is silent by construction: an unlock that never
    // ran, a context stuck in `suspended` or WebKit's `interrupted`, and a graph
    // that is running but has never put a voice on a track all look identical from
    // here otherwise - no exception, no console error, and no sound. See
    // `e2e/unlock.spec.ts` and `AudioEngine.voicesPlayed`.
    audioState: audio.contextState,
    audioRunning: audio.running,
    // ...and whether the browser ever let it run, which `audioState` cannot say
    // once a pause has parked the graph: both read `suspended`, and only one of
    // them is a game that has never made a sound. See `AudioEngine.unlocked`.
    audioUnlocked: audio.unlocked,
    audioVoices: audio.voicesPlayed,
    pointers: input.activePointers,
    // The cutout as the *canvas* understands it, which is not the same question
    // as what the stylesheet does with it. See e2e/safearea.spec.ts.
    insetTop: renderer.safeInsets.top,
    insetRight: renderer.safeInsets.right,
    insetBottom: renderer.safeInsets.bottom,
    insetLeft: renderer.safeInsets.left,
    predators: world.predators.predators.length,
    vortices: world.currents.vortices.length,
    bestScore: profileStore.profile.bestScore,
    seed: world.seed,
  }),
  exportTelemetry: () => JSON.stringify(telemetry.snapshot()),
  advance: (seconds) => {
    const steps = Math.max(1, Math.round(seconds / loop.fixedDt));
    for (let i = 0; i < steps; i++) world.step(loop.fixedDt);
    renderer.ingest(world.takeEvents());
    renderer.render(world, 0, loop.fixedDt, flags, loop.stats.fps);
    // The bed as well as the picture. This hook exists so a station can be looked
    // at without the rAF loop, and which room the station is in is part of the
    // station - a probe that drew act VI and left act I's mixer on screen would
    // be reporting a state the game never has.
    pushBed();
  },
  buzz: (name) => haptic(name),
  perf: () => ({
    // The gate's own number, in the gate's own words. See `GameLoopStats`.
    p95WorkMs: loop.stats.frameP95Ms,
    p95GapMs: loop.stats.intervalP95Ms,
    fps: loop.stats.fps,
    rung: qualityRung,
    rungs: QUALITY_RUNGS.length,
    pinned: qualityPinned,
    dpr: renderedDpr,
    cssW: world.width,
    cssH: world.height,
    // The area term, in megapixels: what the frame was actually asked to fill.
    mpx: backingMpx(),
  }),
  pinQuality: (rung) => pinQualityAt(rung ?? null),
};
