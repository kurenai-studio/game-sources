/**
 * Slowblue: all sound is synthesised, no assets.
 *
 * Two reasons, both practical. A prototype that has to open on a phone over a LAN
 * cannot afford a megabyte of samples before the first frame; and every sound here
 * is parameterised by the thing that caused it - a stroke's pitch follows the
 * finger's speed, a loss thud gets duller as the shoal thins - which a sample bank
 * cannot do without a sample per case.
 *
 * The rewrite for the campaign changed what the engine is *for*. It used to be an
 * arcade feedback layer: short, bright, transient-heavy, one sound per event. Now
 * the bed is the point and the events are guests in it. Four things do that work:
 *
 *   1. A generated convolution reverb. Everything except the sub goes through a
 *      six-second tail, which is what turns a two-second bell into a room.
 *   2. A drone stack tuned to one chord that never resolves and never changes, with
 *      three amplitude LFOs at incommensurable rates - 0.037, 0.053 and 0.071 Hz -
 *      so the bed takes about seven minutes to repeat a state and never lands on a
 *      beat you could count.
 *   3. No attack transients anywhere. Every voice fades in over at least 40 ms, so
 *      nothing in the game can click, and the compressor is there for the one case
 *      that can still stack: nine individuals dying in one frame. The single exception
 *      is a bubble, whose whole life is shorter than that floor; see `bubble()`.
 *   4. The water has no noise in it. It used to be its largest layer - brown noise under
 *      a 300 Hz lowpass - which is an honest description of deep water and a rumble to
 *      listen to; demoting it to a whisper did not help, because a hiss is a hiss at any
 *      level and is the one texture that never stops. The water is now *only* drops:
 *      individual Minnaert resonators whose pitch comes from a bubble radius rather than
 *      from a number anybody chose. See `Bubbles.ts` and `startBed`.
 *
 * ...and one voice that is none of those things: a whale, on its own mixer track, once
 * or twice a minute, gliding. See `Whale.ts`.
 *
 * The whole engine is inert until `unlock()` is called from a real user gesture,
 * because every mobile browser requires that, and it is a no-op wherever
 * `AudioContext` does not exist (Node, the headless probe, the sweeps).
 *
 * ## Eight beds
 *
 * Everything above describes act I, and for a long time it described the whole game:
 * there were two beds, water and air, and the five acts past the anvil fell through
 * to the water's branch. That put a stream of bubbles at 25 km, a whale in vacuum,
 * and the same rain in the trench as in the cloud. The picture had seven acts; the
 * mix had one and a half.
 *
 * Now every act has its own, `audio/Beds.ts` is the table that says which, and the
 * shape of the engine changed in three places to hold them:
 *
 *   1. **`tick` dispatches on the bed** rather than branching on water-or-air. Each
 *      bed runs its own set of Poisson schedulers over its own voices - crystals and
 *      shear in act III, a heartbeat and whistlers in act IV, drops and a shower in
 *      act VI - and each of those voices is a physical model in a module of its own,
 *      with a test file, exactly as the bubbles and the wings already were.
 *   2. **The three continuous layers are retargeted, never rebuilt.** The chord, the
 *      high layer and the bell cannot be swapped at an act boundary without a seam,
 *      so there is one of each for the whole session and a bed change ramps their
 *      frequency, filter and level over four seconds. An act change is a dissolve.
 *   3. **Two held voices exist that only one bed uses each** - act IV's breath and
 *      act V's plasma sheath. Both are built silent at unlock and faded up by the
 *      bed that wants them, which is the same trick the ring shimmer has always used
 *      and is far cheaper than building a graph per act.
 *
 * The one rule the whole table obeys: **act I does not change.** Its numbers are
 * defended digit-for-digit elsewhere in this project and they are defended here too.
 * Everything below either quotes them or is written against them.
 */

import {
  AUDIO_TRACK_KEYS,
  BED_TRACK_KEYS,
  defaultAudioSettings,
  isBedTrack,
  type AudioSettings,
  type AudioTrackKey,
} from '../config/settings';
import {
  bubbleDuration,
  bubbleFrequency,
  bubbleLevel,
  bubbleRadius,
  bubbleRise,
} from './Bubbles';
import {
  wingDuration,
  wingFrequency,
  wingLevel,
  wingQ,
  wingSpan,
} from './Wings';
import { bedSpec, type BedKey, type BedSpec } from './Beds';
import {
  crystalDuration,
  crystalFall,
  crystalFrequency,
  crystalLevel,
  crystalRate,
  crystalSize,
  infrasoundGap,
  infrasoundSwell,
  shearBand,
  shearGap,
} from './Crystals';
import { breathVoice, heartBeat, heartRate, whistlerGap, whistlerShower } from './Void';
import { sheathCorner, sheathLevel, shockGap, shockRoll, spark, sparkRate } from './Plasma';
import {
  dropDuration,
  dropFrequency,
  dropImpactHz,
  dropLevel,
  dropRadius,
  dropRate,
  dropRise,
  patterGrain,
  patterRate,
  sheetAt,
} from './Raindrops';
import {
  riffleDuration,
  riffleFrequency,
  riffleLevel,
  riffleRadius,
  riffleRate,
  riffleRise,
  stoneGap,
  stoneKnock,
} from './Riffle';
import { flake, snowRate } from './Snow';
import {
  grainPan,
  rescueVoice,
  type RescueBand,
  type RescueGrains,
  type RescueNote,
  type RescueVoice,
} from './Rescues';
import { whaleGap, whalePhrase, type WhaleCall } from './Whale';
import { ROOT_HZ, SCALE, degreeHz, snapHz } from './Scale';
import { SilentLoop } from './SilentLoop';

type Ctor = new () => AudioContext;

function contextCtor(): Ctor | null {
  const g = globalThis as { AudioContext?: Ctor; webkitAudioContext?: Ctor };
  return g.AudioContext ?? g.webkitAudioContext ?? null;
}

/**
 * What the sound is *for*, declared to iOS - and the one lever that reaches it.
 *
 * The obvious place for this is Swift, an `AVAudioSession` category set in the
 * app delegate, and it does not work: WebKit sets its own category when a page
 * starts playing and overwrites whatever the shell asked for, so a native line
 * here would not add anything - it would hide the fact that the answer is on the
 * page. The Audio Session API is the switch that survives.
 *
 * The value is `playback`, and it has been `ambient` in between, which was wrong
 * in a way only a phone could show. `ambient` respects the hardware silent switch,
 * and the argument for it was that a phone set to silent is a person who has said
 * no. In practice it is a person who keeps their phone on silent all day and
 * opened a game whose whole design is a sound bed: the web build shipped with
 * `ambient`, and the first report from a phone was "no sound, in any browser" -
 * every iOS browser being WebKit, every one of them obeyed the switch. Nobody
 * looks at the switch when a game is quiet; they decide the game is broken.
 * `playback` is heard, at the cost of pausing the player's own music, and the
 * corner button is the no that the switch was standing in for. `auto` when
 * nothing is audible, so a fully muted mixer neither holds a session open for
 * silence nor stops someone's music for it.
 */
function setAudioSession(audible: boolean): void {
  const nav = globalThis.navigator as
    | (Navigator & { audioSession?: { type: string } })
    | undefined;
  try {
    if (nav?.audioSession !== undefined) nav.audioSession.type = audible ? 'playback' : 'auto';
  } catch {
    /* experimental API: Web Audio still works without it */
  }
}

interface TrackRoute {
  /** Direct signal into the compressor. */
  dry: GainNode;
  /** Independently levelled send into the shared convolution tail. */
  wet: GainNode;
}

// `SCALE`, `ROOT_HZ` and the snapping rule now live in `Scale.ts`, because the
// voices that most needed them are the ones that were not written in degrees.

/**
 * A cue's degree, held inside the table.
 *
 * `scaleSemi` runs forever in both directions and the cues must not: a degree is
 * an authored number here, and one that ran off the end would transpose an ending
 * rather than fail. The clamp is what the cues have always done; it is only named
 * because three of them were doing it in three copies of the same expression.
 */
function clampDegree(degree: number): number {
  return Math.min(SCALE.length - 1, Math.max(0, degree));
}

/**
 * Scheduled bubble *events* per second at the surface, breath halfway. A gurgle counts
 * as one event and brings two to five bubbles with it, so the audible rate is about a
 * third higher than this number.
 *
 * The band was found by simulating the scheduler over a minute at each end of the
 * campaign, and the two failure modes either side of it are both obvious. Down around
 * one bubble a second the water is a dripping tap - and a dripping tap makes people
 * tense rather than calm, because each event is separate enough to be *counted*. Up
 * past five or six it is an aquarium pump. These constants keep the audible rate
 * between about 2.0/s (deep, inhaling) and 3.5/s (at the surface, exhaling), which with
 * the reverb tail behind every one reads as a body of moving water rather than as a
 * countable stream of blips. Median pitch moves 450 Hz on the trench floor to 700 Hz at
 * the surface, which is `bubbleRadius` doing its job.
 */
const BUBBLE_RATE = 2.2;
/**
 * Scheduled wingbeat *events* per second in the air, at the same neutral point
 * BUBBLE_RATE is quoted at. Lower than the water's, because a beat is a bigger,
 * broader sound than a bubble and because the air is the thinner medium in every
 * other respect too - it would be strange for it to be the busier one.
 *
 * A "beat" here is a whole flock's worth: one scheduled event brings two to four
 * wings with it (see `beats`), spread over a fifth of a second, because a hundred
 * birds never beat in unison and the smear is most of what makes it read as a
 * flock rather than as one bird overhead.
 */
const WING_RATE = 1.5;
/** Peak gain of a mid-sized wing. */
const WING_GAIN = 0.05;
/** A flock event is 2 to 2 + this - 1 wings. */
const WING_CLUSTER = 3;

/** Peak gain of a mid-sized bubble. A twentieth of a bell. */
const BUBBLE_GAIN = 0.028;
/** Chance that a scheduled event is a whole gurgle instead of one bubble. */
const BUBBLE_CLUSTER = 0.12;
/** A gurgle is 2 to 2 + this - 1 bubbles. */
const GURGLE_EXTRA = 4;
/**
 * Peak gain of the loudest call in a whale phrase.
 *
 * Twice a bubble and about the level of a bell, which sounds like a lot for something in
 * the background and is not: the call is three sine partials with a 0.95 reverb send and
 * an attack a second long, so almost all of that energy arrives as room rather than as
 * signal. It has to be able to be *heard over the drone* - a whale you have to strain for
 * is a whale nobody notices - and the drone's chord sits right underneath it.
 */
const WHALE_GAIN = 0.085;

// --- the other seven beds ------------------------------------------------
//
// Every number below is quoted against the five above, which are act I's and are
// not up for revision. Where a voice is meant to sit at the same apparent level as
// one of act I's it is *not* given the same gain - a 4 kHz crystal at a bubble's
// gain is about eight decibels louder to the ear than the bubble is, because that
// is where hearing peaks - so the high voices are trimmed and the very low ones
// are pushed. Measured by ear against the bell, which is the one thing in the mix
// that appears in all eight beds.

/** Act III. One ice crystal, ringing. About a bubble, high up where the ear is best. */
const CRYSTAL_GAIN = 0.016;
/**
 * The gain at the top of the graph. Every other level in this file is relative to it,
 * so the whole game's loudness is this number and the limiter behind it.
 */
const MASTER_GAIN = 14;
/** Act III. One layer sliding past another, over ten to twenty seconds. */
const SHEAR_GAIN = 0.02;
/** Act III. The planet's waveguide. Low enough that most phones will not reproduce it. */
const INFRA_GAIN = 0.06;
/** Act IV. The heartbeat, which should be felt and not identified. */
const HEART_GAIN = 0.075;
/** Act IV. The breath, held, running off the game's own breath clock. */
const BREATH_GAIN = 0.026;
/** Act IV. One whistler, descending. */
const WHISTLER_GAIN = 0.02;
/** Act V. The sheath at its worst - the loudest continuous thing in the game. */
const SHEATH_GAIN = 0.055;
/** Act V. One grain of heat shield, leaving. */
const SPARK_GAIN = 0.009;
/** Act V. The bow shock, passing. */
const SHOCK_GAIN = 0.06;
/** Act VI. One raindrop's entrained bubble. Small, because there are fifteen a second. */
const DROP_GAIN = 0.012;
/** Act VI. One drop on a leaf. Quieter again: this layer is texture, not events. */
const PATTER_GAIN = 0.005;
/** The brook. Twenty a second, so quieter still than the rain. */
const RIFFLE_GAIN = 0.009;
/** The brook. One cobble, moved. */
const STONE_GAIN = 0.045;
/** Act VII. One flake of marine snow, passing. The quietest voice in the campaign. */
const FLAKE_GAIN = 0.011;

/**
 * Seconds a bed change takes to arrive.
 *
 * Long on purpose. The three held layers are retargeted rather than rebuilt, and
 * four seconds is slower than any station transition in the game, so the chord of
 * the act you are leaving is still resolving into the chord of the act you are
 * entering when the banner has already gone. Nothing in the campaign is allowed a
 * frame on which it happened; this is that rule, in the mixer.
 */
const BED_FADE = 4;

/** The bed voices `preview` can audition. See that method for why it exists. */
export type PreviewVoice =
  | 'bubble'
  | 'gurgle'
  | 'hush'
  | 'wing'
  | 'flock'
  | 'gust'
  | 'thunder'
  | 'whale'
  | 'bowl'
  | 'crystal'
  | 'shear'
  | 'infrasound'
  | 'heart'
  | 'whistler'
  | 'spark'
  | 'shock'
  | 'drop'
  | 'patter'
  | 'riffle'
  | 'stone'
  | 'flake';

export class AudioEngine {
  private ctx: AudioContext | null = null;
  private tracks: Partial<Record<AudioTrackKey, TrackRoute>> = {};
  private noise: AudioBuffer | null = null;
  private bedNodes: AudioScheduledSourceNode[] = [];
  /** The one voice that is held rather than triggered: the ring shimmer. */
  private ringOsc: OscillatorNode | null = null;
  private ringOsc2: OscillatorNode | null = null;
  private ringGain: GainNode | null = null;
  /** Where the ring being worked is, horizontally. Null on browsers with no panner. */
  private ringPan: AudioParam | null = null;
  private levels: AudioSettings = defaultAudioSettings();
  /** The master switch. See `setMuted`. */
  private muted = false;
  private lastLoss = 0;
  private lastStroke = 0;
  private failed = false;
  /** The pre-iOS-17 half of `setAudioSession`. See `SilentLoop`. */
  private readonly keepAlive = new SilentLoop();
  /**
   * True once the browser has actually let the context run, at any point in the
   * session. Never goes back to false.
   *
   * Not `running`, and the difference is the whole reason it is here. `running` is
   * false on a launch nobody has touched *and* on a paused screen, and those are
   * opposite situations: the first is a game that has never made a sound and whose
   * corner button should be offering one, the second is a game the player parked
   * and whose corner button is still a mute. See `unlocked` and `Shell.setSoundLocked`.
   */
  private started = false;
  /**
   * True while *this engine* is the reason the context is not running.
   *
   * The flag that separates the two ways a context stops, which from the state
   * alone are the same event: the game parked it (a pause, a hidden tab) or the
   * system took it (a call, Siri). Only the second one is a bug to recover from -
   * resuming out of the first would restart the bed under a paused game, which is
   * the pause not working. See `onStateChange`.
   */
  private parked = false;
  /** Voices that have reached a mixer track. The proof of audibility; see `voicesPlayed`. */
  private voices = 0;
  /** Counts down to the bed's next bell. Advanced by `tick`. */
  private toBowl = 12;
  private bowlDegree = 0;
  /** 0..1, how dark the bed is. Falls throughout the ascent; smoothed, never stepped. */
  private depth = 0;
  /**
   * The one bed parameter the breath still opens and closes. Held as a reference because
   * the breath comes from the game's clock rather than from an LFO in the audio graph -
   * the picture and the sound have to breathe as one thing or neither of them works.
   *
   * It used to be three; the other two belonged to the water's noise layers, and the
   * water has no noise layers any more. On that track the breath now moves the bubble
   * *rate* instead, which is a rhythmic cue rather than a spectral one.
   */
  private padFilterParam: AudioParam | null = null;
  /** 0..1 breath swell, held so the bubble rate can read it. */
  private breath = 0.5;
  /** Seconds to the next bubble. Redrawn from an exponential after every one. */
  private toBubble = 0.4;
  /** Seconds to the next flock beat. */
  private toWing = 0.6;
  /** 0 just above the waves, 1 at the tropopause. Biases wing size. */
  private altitude = 0;
  /** Alternates the exhale gurgle left and right. A sound in the middle has no room. */
  private hushSide = 1;
  /** Seconds to the next whale phrase. */
  private toWhale = 26;
  /** Seconds to the next gust of wind. Air only. */
  private toGust = 5;
  /** Seconds to the next distant thunder. Air only, and only where there is weather. */
  private toThunder = 34;
  /** Seconds of "the air is running out" left after `release()`. Thins the wings. */
  private releaseQuiet = 0;

  // --- the bed ------------------------------------------------------------

  /** Which of the eight beds is playing. See `Beds.ts`. */
  private bedKey: BedKey = 'deep';
  private bed: BedSpec = bedSpec('deep');
  /** 0..1, how far through its act the station is. Each bed reads it differently. */
  private arc = 0;
  /**
   * The station's altitude in metres, negative above the sea.
   *
   * Only the brook reads it, and it has to: running water appears at the end of
   * act VI and again at the start of act VII, so "how far through the act" says
   * nothing useful about how fast the water is going. Four hundred metres up a
   * mountain it is a riffle; at the mouth it is not.
   */
  private meters = 0;
  /** Seconds since the engine started, for the rain's own sheet clock. */
  private clock = 0;

  // The retargetable half of the bed. One of each for the session; a bed change
  // ramps them rather than rebuilding, which is what makes an act change a
  // dissolve. See `applyVoicing`.
  private padGain: AudioParam | null = null;
  private padVoices: OscillatorNode[] = [];
  private shimmerGain: AudioParam | null = null;
  private shimmerFreq: AudioParam | null = null;
  private shimmerQ: AudioParam | null = null;
  private shimmerRate: AudioParam | null = null;
  private shimmerLfoDepth: AudioParam | null = null;
  private shimmerSweepDepth: AudioParam | null = null;
  /** Act IV only: the breath, held, in two bands. Silent in the other seven beds. */
  private breathBody: { gain: AudioParam; freq: AudioParam } | null = null;
  private breathAir: { gain: AudioParam; freq: AudioParam } | null = null;
  /** Act V only: the plasma sheath, held. The one broadband layer in the game. */
  private sheath: { gain: AudioParam; freq: AudioParam } | null = null;

  // Scheduler clocks, one per scheduled voice. All Poisson-ish: the interval is
  // redrawn after every event, so no layer has a rate the ear can lock onto.
  private toCrystal = 3;
  private toShear = 9;
  private toInfra = 34;
  private toHeart = 1.5;
  private toWhistler = 22;
  private toSpark = 0.5;
  private toShock = 13;
  private toDrop = 0.1;
  private toPatter = 0.1;
  private toRiffle = 0.06;
  private toStone = 16;
  private toFlake = 2.5;
  /** Alternates marine snow left and right. A snowfall from one side is a leak. */
  private snowSide = 1;

  get running(): boolean {
    return this.ctx !== null && this.ctx.state === 'running';
  }

  /**
   * Whether anything has ever opened the context. See `started`.
   *
   * The one question the shell has to be able to ask, because the answer decides
   * what its sound button *means*: while this is false the game is silent no
   * matter what the settings say, and a press there can only sensibly mean "let
   * me hear it".
   */
  get unlocked(): boolean {
    return this.started;
  }

  /**
   * The context's own state, verbatim, or `'none'` before one exists.
   *
   * Includes WebKit's non-standard `'interrupted'`, which is the whole reason this
   * is a string rather than a boolean: `running` cannot tell "no gesture yet" apart
   * from "a phone call arrived and the context never came back", and those are
   * different bugs with the same symptom.
   */
  get contextState(): string {
    return this.ctx === null ? 'none' : (this.ctx.state as string);
  }

  /**
   * How many voices have actually reached the mixer since the engine was built.
   *
   * The one number that separates a working audio engine from a silent one, and the
   * reason it exists is `e2e/unlock.spec.ts`. Every failure mode this engine has -
   * a context that never resumed, a bed dealing into an undeclared track, a mixer
   * left at zero, a `contextCtor` that returned null - produces exactly the same
   * observable behaviour from outside: no exception, no console error, and no
   * sound. A test that only asserts the handshake did not throw is a test that
   * passes on a game nobody can hear.
   *
   * Counted in `connectTrack`, after the route lookup, because a voice that fails to
   * find its track is a voice that was never audible.
   */
  get voicesPlayed(): number {
    return this.voices;
  }

  /**
   * Must be called from inside a user-gesture handler. Safe to call repeatedly.
   *
   * Safari can leave a context suspended (or in its non-standard `interrupted`
   * state) after a tab switch. Returning the result lets UI sounds wait until the
   * context is genuinely running instead of disappearing during `resume()`.
   */
  async unlock(): Promise<boolean> {
    if (this.failed) return false;
    // A gesture is the player asking for sound, so whatever parked the engine is
    // over. See `parked`.
    this.parked = false;
    setAudioSession(this.hasAudibleTrack());
    // Inside the gesture, before anything async: the loop's first `play()` is only
    // allowed here, and every later one leans on it having happened.
    this.keepAlive.hold(this.hasAudibleTrack());
    if (this.ctx === null) {
      const Ctx = contextCtor();
      if (Ctx === null) {
        this.failed = true;
        return false;
      }
      try {
        this.ctx = new Ctx();
        this.build();
      } catch {
        this.failed = true;
        this.ctx = null;
        return false;
      }
    }
    if (!this.running) this.prime();
    return this.ensureRunning();
  }

  /**
   * The master switch, applied where the per-track levels are.
   *
   * Silence lands as every track's gain going to zero rather than as the graph
   * being torn down: the beds are continuous, the ramps in `setLevels` are what
   * keeps them from clicking, and a player who unmutes wants the mix they had
   * back, at the point the water has reached - not a bed starting over.
   */
  setMuted(muted: boolean): void {
    if (this.muted === muted) return;
    this.muted = muted;
    this.setLevels(this.levels);
  }

  setLevels(levels: AudioSettings): void {
    this.levels = levels;
    setAudioSession(this.hasAudibleTrack());
    // Only ever *stops* the loop from here. Starting it belongs to a gesture or a
    // return from a park, and settings are applied once at boot, before either.
    if (!this.hasAudibleTrack()) this.keepAlive.release();
    const ctx = this.ctx;
    if (ctx === null) return;
    const t = ctx.currentTime;
    for (const key of AUDIO_TRACK_KEYS) {
      const route = this.tracks[key];
      if (route === undefined) continue;
      const target = this.trackGain(key);
      // How fast a level change lands.
      //
      // The bed tracks used to ramp at 0.9, which is roughly three seconds to
      // settle - written for the bed *drifting* between stations, and wrong for
      // the thing that actually moves these gains: a player pressing a switch in
      // the mixer. A press that takes three seconds to be heard reads as a
      // control that did not work, and the player presses it again. 0.08 is
      // still a ramp - it is what keeps a square-edged mute from clicking - but
      // it is a ramp inside the same tenth of a second as the press.
      const timeConstant = isBedTrack(key) ? 0.08 : 0.05;
      route.dry.gain.setTargetAtTime(target, t, timeConstant);
      route.wet.gain.setTargetAtTime(target, t, timeConstant);
    }
  }

  private hasAudibleTrack(): boolean {
    return AUDIO_TRACK_KEYS.some((key) => this.trackAudible(key));
  }

  private trackAudible(key: AudioTrackKey): boolean {
    if (this.muted) return false;
    const level = this.levels[key];
    return level.enabled && level.volume > 0;
  }

  private trackGain(key: AudioTrackKey): number {
    if (this.muted) return 0;
    const level = this.levels[key];
    if (!level.enabled) return 0;
    return level.volume * (isBedTrack(key) ? 0.62 : 1);
  }

  /** Parks the audio graph while the tab is hidden or the game is paused. */
  suspend(): void {
    // Before the call, not after: the `statechange` this causes arrives while the
    // suspend is still in flight, and it has to find the flag already set.
    this.parked = true;
    this.keepAlive.release();
    if (this.ctx?.state === 'running') void this.ctx.suspend().catch(() => undefined);
  }

  resume(): void {
    this.parked = false;
    // Never before the first gesture: a loop started from here on a page nobody
    // has touched would be refused, and is not what this method is asking for.
    if (this.started) this.keepAlive.hold(this.hasAudibleTrack());
    void this.ensureRunning();
  }

  /**
   * WebKit's own account of why the sound stopped - and the only one there is.
   *
   * An interruption is the one way this game goes silent that nothing else can
   * see. A call banner or a Siri invocation puts the context into WebKit's
   * non-standard `interrupted` state without hiding the page, so
   * `visibilitychange` never fires, the loop keeps running, the picture keeps
   * moving, and the bed is gone until the player happens to touch the glass. On
   * the title screen, which is where a phone gets left, that is forever.
   *
   * `ensureRunning` has known how to get out of `interrupted` since long before
   * this: the gap was that nothing called it. This is the caller.
   *
   * **Only `interrupted` is recovered from, and `suspended` deliberately is not.**
   * A suspended context is one that somebody asked for - this engine (see
   * `parked`), the browser's autoplay policy on a page nobody has touched, or a
   * test holding it down - and resuming out of all three would be this engine
   * arguing with whoever asked. The interruption is the only one with no author.
   *
   * That one line is also the reentry guard, which is worth writing down because
   * the obvious implementation is a flag. `ensureRunning` gets out of
   * `interrupted` by calling `suspend()` itself, and a suspend fires this - so a
   * handler that acted on every not-running state would call itself once per
   * step, and a `recovering` flag is how you stop it. Both were built; the flag
   * came out. It was doing nothing the state test was not already doing, and it
   * had a cost the state test does not: a dropped event. Nothing here ever
   * *produces* `interrupted` - only the system does - so a second one arriving
   * inside the first recovery is a real interruption, and the flag's job would
   * have been to throw it away.
   */
  private onStateChange(): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    if (ctx.state === 'running') {
      this.started = true;
      return;
    }
    if ((ctx.state as string) !== 'interrupted') return;
    // The game wants silence, and an interruption on top of a pause changes
    // nothing about that; the resume it is waiting for is a player's.
    if (this.parked) return;
    // Nothing has ever been allowed to run, so there is nothing to bring back:
    // only a real gesture can open a context that has never opened.
    if (!this.started) return;
    void this.ensureRunning();
  }

  /**
   * Starts one silent frame synchronously inside the touch/click handler. This is
   * the long-standing iOS Web Audio unlock handshake; it is inaudible and is only
   * needed when the context is not already running.
   */
  private prime(): void {
    const ctx = this.ctx;
    if (ctx === null || ctx.state === 'closed') return;
    try {
      const source = ctx.createBufferSource();
      source.buffer = ctx.createBuffer(1, 1, ctx.sampleRate);
      source.connect(ctx.destination);
      source.start();
    } catch {
      /* resume below is still worth trying */
    }
  }

  /** Handles both the standard suspended state and WebKit's `interrupted` state. */
  private async ensureRunning(): Promise<boolean> {
    const ctx = this.ctx;
    if (ctx === null || ctx.state === 'closed') return false;
    if (ctx.state === 'running') {
      this.started = true;
      return true;
    }
    try {
      // WebKit documents this state in practice but not in AudioContextState's
      // TypeScript union. A suspend/resume cycle is its supported recovery path.
      // The suspend fires a `statechange` of its own; `onStateChange` ignores it,
      // and the note there is why that is the whole of the reentry story.
      if ((ctx.state as string) === 'interrupted') await ctx.suspend();
      await ctx.resume();
    } catch {
      // A later real gesture calls unlock again; one failed resume must not make
      // the audio engine permanently give up for the rest of the session.
    }
    if ((ctx.state as string) !== 'running') return false;
    this.started = true;
    return true;
  }

  /**
   * Slowblue: which of the eight beds is playing, and where in its own arc it is.
   *
   * The one call the game makes about the bed, pushed every frame from
   * `main.updateAudioBed`. Three arguments and each does a different job:
   *
   *   * `key` selects the bed. Changing it retargets the three held layers over
   *     four seconds (`applyVoicing`) and lets `tick` start dealing the new bed's
   *     voices immediately - the scheduled half changes at once and the sustained
   *     half dissolves, which is what a room changing around you sounds like.
   *   * `arc01` is 0 at an act's first station and 1 at its last, and **each bed
   *     reads it as its own quantity**: as depth for act I (falling, because the
   *     act rises out of the dark), as depth again for act VII but the other way
   *     up (it sinks), as height for acts II and III, as how much of the fire is
   *     left for act V. One number, seven meanings, because the thing they all
   *     have in common is "how far through this place are we".
   *   * `meters` is the station's altitude, negative above the sea. Only the brook
   *     uses it; see the field.
   *
   * Nothing here is smoothed. `arc01` already moves continuously with the station
   * progress, and the things that read it are either scheduled (so they resample
   * it once per event) or already ramped.
   */
  setBed(key: BedKey, arc01: number, meters = 0): void {
    const arc = Math.max(0, Math.min(1, arc01));
    this.arc = arc;
    this.meters = meters;
    // The two legacy signals, derived rather than pushed. Every voice that was
    // written against them - bubble radius, wing span, whale register, the bell's
    // darkness - keeps working unchanged, and the direction of act VII is fixed in
    // the one line that was wrong: it descends, so its water gets *darker*.
    this.depth = key === 'homecoming' ? arc : key === 'deep' ? 1 - arc : 0;
    this.altitude = key === 'flight' || key === 'thin' ? arc : 0;
    if (key === this.bedKey) return;
    this.bedKey = key;
    this.bed = bedSpec(key);
    this.applyVoicing(BED_FADE);
    // Bring the next bell forward. A player who has just arrived somewhere new
    // should hear the room they are in inside a breath, not in forty seconds.
    this.toBowl = Math.min(this.toBowl, 5);
  }

  /** Which bed is playing. The shell reads it to label the in-game mixer. */
  get currentBed(): BedKey {
    return this.bedKey;
  }

  /**
   * How fast the water is going, 0..1. The brook's own parameter.
   *
   * Four hundred metres up a mountain the stream folds over on itself twenty
   * times a second and the bed is bright and dense; at the mouth it has stopped
   * doing that entirely. `Riffle.ts` reads this for both the bubble size and the
   * rate, so the handover from act VI to act VII is a river slowing down.
   */
  private get flow(): number {
    return Math.max(0, Math.min(1, Math.max(0, -this.meters) / 400));
  }

  /**
   * How much of the cloud the swarm is in is actually *water*, 0 to 1.
   *
   * The rain bed covers eleven kilometres of act VI and the top of it is not rain.
   * Cirrus at -11 000 m is ice being dragged and Under the Anvil at -9 000 m is
   * the inside of a cloud, and both of them were playing fifteen drops a second
   * and a layer literally named *Leaf patter* - the same mix as the forest floor,
   * at the altitude a jet cruises at. `bedFor` cannot tell them apart because they
   * are all `cloud`; the altitude can, and `setBed` already carries it.
   *
   * 0 above about 3.2 km, 0.46 at the downpour, 1 at the canopy and at the
   * `meters = 0` the admin surface and the tests deal at, so nothing that
   * auditions a bed by hand changes.
   */
  private get wet(): number {
    return Math.max(0, Math.min(1, (3200 - Math.max(0, -this.meters)) / 2600));
  }

  /**
   * The one held voice: a shimmer that rises while the shoal is filling a dashed
   * ring. It is not a progress bar with a sound attached - the pitch is what the
   * player is holding, so letting the shoal drift out audibly lets it fall.
   *
   * The interval it climbs, and the register it climbs in, are the act's
   * (`RescueVoice.hold`). It is the only continuous voice the player *plays*, so
   * leaving it identical in all eight acts would have meant the one sound they
   * make most often was the one sound that never told them where they were: a
   * fifth in the sea, two octaves higher and narrower in the upper air, a fourth
   * and very low on the way home.
   */
  setRingHold(progress01: number, presence01: number, pan = 0): void {
    const ctx = this.ctx;
    const gain = this.ringGain;
    if (ctx === null || gain === null || this.ringOsc === null || this.ringOsc2 === null) return;
    const p = Math.max(0, Math.min(1, progress01));
    const presence = Math.max(0, Math.min(1, presence01));
    const t = ctx.currentTime;
    const target = presence * 0.012 + p * 0.03;
    gain.gain.setTargetAtTime(target, t, 0.09);
    this.ringPan?.setTargetAtTime(Math.max(-1, Math.min(1, pan * 0.7)), t, 0.4);
    // Up an interval over the hold, in the same scale everything else is in.
    const hold = rescueVoice(this.bedKey).hold;
    const semi = hold.from + (hold.to - hold.from) * p;
    const hz = ROOT_HZ * 8 * hold.octave * Math.pow(2, semi / 12);
    this.ringOsc.frequency.setTargetAtTime(hz, t, 0.12);
    this.ringOsc2.frequency.setTargetAtTime(hz * 1.5, t, 0.12);
  }

  /**
   * The breath, pushed from the game's own clock every frame. See `sim/Breath.ts`.
   *
   * Three parameters, chosen because they are the three that carry "a body of water
   * with something moving in it" rather than "a sound getting louder": the level of
   * the water itself, the corner it is filtered at, and the corner the chord is
   * filtered at. Nothing changes pitch, and nothing changes fast - the whole swing
   * happens over five and a half seconds, so it is felt and not heard.
   *
   * The swell is all the engine needs. The *sign* of the breath used to come in
   * beside it, because the hush was cued on the turn - an out-breath that starts and
   * a sound that starts at the same instant. The hush left the breath together with
   * the mode that gated it, and is auditioned from the admin surface instead (see
   * `hush`), so the second argument went with it.
   */
  setBreath(swell01: number): void {
    const s = Math.max(0, Math.min(1, swell01));
    // Held unconditionally, because the bubble rate reads it and the bubbles are
    // scheduled from `tick` rather than from the audio graph.
    this.breath = s;
    const ctx = this.ctx;
    if (ctx === null) return;
    const t = ctx.currentTime;
    // 0.25 s is short against an 11 s cycle, so the parameter tracks the breath
    // rather than lagging it, and long enough that no step in the caller can click.
    this.padFilterParam?.setTargetAtTime(this.bed.drone.cutoff * (0.8 + 0.4 * s), t, 0.35);
    // ...and in orbit the breath is not a modulation of something else, it is a
    // voice. See `startBreathVoice`.
    if (this.bedKey === 'orbit') {
      const v = breathVoice(s);
      const audible = this.trackAudible('ocean') ? 1 : 0;
      this.breathBody?.gain.setTargetAtTime(BREATH_GAIN * v.bodyGain * audible, t, 0.3);
      this.breathBody?.freq.setTargetAtTime(v.bodyHz, t, 0.4);
      this.breathAir?.gain.setTargetAtTime(BREATH_GAIN * 0.5 * v.airGain * audible, t, 0.3);
      this.breathAir?.freq.setTargetAtTime(v.airHz, t, 0.4);
    }
  }

  /**
   * The exhale, as a sound - and as drops, not as air.
   *
   * This was a six-second noise swell, which is what a hush is: broadband, soft, panned
   * to one side. It was the most obviously ASMR thing in the mix and it had to go for the
   * same reason the water's noise layers did - any hiss at all is a texture that never
   * stops, and something that never stops is something the ear cannot let go of.
   *
   * What replaced it kept the one property that mattered while it was still cued: the
   * *timing*. A sound that begins on the instant an out-breath begins was the entrainment
   * cue this whole feature existed for, and a handful of large, low drops from one side
   * did that job while still being water. The side flips on every play, which is the rest
   * of it - a near-field asymmetry is what makes a small sound feel close.
   *
   * Every bed has one, and every bed's is made of its own material - drops in the
   * sea, a swish of feathers in the air, one ice crystal in the stratosphere, a
   * handful of rain, a fold of the stream. Two beds have none, and both refusals
   * are the point: in orbit the breath *is* a held voice already
   * (`startBreathVoice`), and in the plasma the sheath's own filter opens and
   * closes on it, so a cue on top would be the third thing saying the same word.
   *
   * Nothing in the game cues it any more. The mode that fired it on every out-breath
   * is gone, and the sound outlived it: six mediums' worth of material and two
   * deliberate silences are worth keeping playable, so the only door into it now is
   * `preview` and the admin rows that call it.
   */
  private hush(): void {
    if (!this.trackAudible('ocean')) return;
    this.hushSide = -this.hushSide;
    const side = this.hushSide;
    switch (this.bedKey) {
      case 'flight':
        // The exhale in air is a glide - wings locked, air over feathers - so the cue
        // is one long soft swish from one side, not drops. Same timing, same
        // alternation, the medium's own material.
        this.burst('ocean', 520, 3.4, 0.018, 'bandpass', 0.5, 330, 0.8, side * 0.75);
        return;
      case 'thin':
        // One crystal, from one side, and nothing else. In the emptiest bed in the
        // game the cue has to be a single object or it is not thin any more.
        this.crystal(crystalSize(0.75 + Math.random() * 0.25, this.altitude), side * 0.7, CRYSTAL_GAIN);
        return;
      case 'orbit':
      case 'fire':
        return;
      case 'rain':
        for (let i = 0; i < 5; i++) {
          const r = dropRadius(0.6 + Math.random() * 0.4, 1);
          this.drop(r, side * (0.5 + Math.random() * 0.45), DROP_GAIN * 1.3, i * 0.05 + Math.random() * 0.06);
        }
        return;
      case 'brook':
        for (let i = 0; i < 6; i++) {
          const r = riffleRadius(0.55 + Math.random() * 0.45, this.flow);
          this.riffle(r, side * (0.45 + Math.random() * 0.45), RIFFLE_GAIN * 1.5, i * 0.04 + Math.random() * 0.05);
        }
        return;
      default:
        // Deliberately the big end of the range: an exhale is low, so its drops are too.
        for (let i = 0; i < 3; i++) {
          const r = bubbleRadius(0.72 + Math.random() * 0.28, this.depth);
          this.bubble(r, side * (0.6 + Math.random() * 0.3), BUBBLE_GAIN * 0.9, i * 0.11 + Math.random() * 0.08);
        }
    }
  }

  /**
   * Advances the slow, scheduled part of the bed. Call once per frame.
   *
   * Each bed deals its own outside, and the dispatch is the whole reason this
   * method exists: the water deals bubbles and, rarely, a whale; the air deals
   * wingbeats, gusts and - where there is weather to make it - distant thunder;
   * the stratosphere deals four crystals a minute and almost nothing else.
   *
   * The failure this replaced is worth remembering, because it is what an
   * unowned `else` branch looks like from the player's side. The whale used to be
   * scheduled by "not air", which meant it went on singing through the upper
   * stratosphere, through vacuum, through a re-entry plasma sheath and through
   * rain: five acts of an animal that cannot be in any of them.
   */
  tick(dt: number): void {
    if (!this.running) return;
    this.clock += dt;
    this.releaseQuiet = Math.max(0, this.releaseQuiet - dt);
    switch (this.bedKey) {
      case 'flight':
        this.updateWings(dt);
        this.updateGusts(dt);
        this.updateThunder(dt);
        break;
      case 'thin':
        this.updateCrystals(dt);
        this.updateShear(dt);
        this.updateInfrasound(dt);
        break;
      case 'orbit':
        this.updateHeart(dt);
        this.updateWhistlers(dt);
        break;
      case 'fire':
        this.updateSheath();
        this.updateCooling();
        this.updateSparks(dt);
        this.updateShocks(dt);
        break;
      case 'rain':
        this.updateDrops(dt);
        this.updatePatter(dt);
        this.updateThunder(dt, true);
        break;
      case 'brook':
        this.updateRiffle(dt);
        this.updateStones(dt);
        break;
      case 'homecoming':
        this.updateBubbles(dt);
        this.updateSnow(dt);
        this.updateWhale(dt);
        this.updateResolve();
        break;
      default:
        this.updateBubbles(dt);
        this.updateWhale(dt);
    }
    if (!this.trackAudible('ambience')) return;
    this.toBowl -= dt;
    if (this.toBowl > 0) return;
    // The bell's interval is the bed's own (`BellVoicing.gap`), and it runs from act
    // VII's 18-38 to act IV's 38-74. It is the only voice in the bed with an onset, so
    // how often it arrives is the difference between "a room with something in it" and
    // "a room" - and it is never on a beat, for the reason `SCALE` has no leading tone.
    const [lo, hi] = this.bed.bell.gap;
    this.toBowl = lo + Math.random() * (hi - lo);
    // A slow walk through the scale rather than a random pick: consecutive bells
    // are a step apart, which is what makes an unaccompanied note sound intended.
    this.bowlDegree = Math.max(0, Math.min(6, this.bowlDegree + (Math.random() < 0.5 ? -1 : 1)));
    this.bowl('ambience', this.bowlDegree, 0.05 - this.depth * 0.015);
  }

  private build(): void {
    const ctx = this.ctx;
    if (ctx === null) return;

    // The only notification a page gets that a call took its sound away. Bound
    // here rather than in `unlock` because this runs exactly once per context,
    // and `unlock` runs on every touch. See `onStateChange`.
    ctx.addEventListener('statechange', () => this.onStateChange());

    const master = ctx.createGain();
    // Measured, not felt: with the old 0.9 here the bed settled at about -45 dBFS RMS
    // with peaks near -30 dBFS (a tap on the analyser after the compressor, 390 px
    // wide Chromium, act I), which is 15 to 20 dB under any page a browser plays and
    // is why the game could not be heard at a comfortable system volume. Every voice
    // is mixed against every other, so the fix is one number at the top rather than
    // forty at the bottom.
    // It was 7 for one release and still read as faint on a laptop: 14 settles act I at
    // about -20 dBFS RMS with peaks held under the limiter, which is where a page that
    // plays sound for a living sits.
    master.gain.value = MASTER_GAIN;
    // A compressor is the cheapest insurance against a rock strike that kills nine
    // individuals in one frame turning into nine overlapping thuds at full scale.
    const comp = ctx.createDynamicsCompressor();
    comp.threshold.value = -14;
    comp.ratio.value = 6;
    comp.attack.value = 0.02;
    comp.release.value = 0.4;
    // ...and a limiter behind it, because a compressor with a 20 ms attack lets the
    // first few milliseconds of a strike through, and at this master level those
    // milliseconds reach the converter. Fast, hard, and set where nothing in the
    // game should ever be asked to go: eight under full scale, so the converter keeps
    // headroom for the ringing of the limiter itself.
    const limiter = ctx.createDynamicsCompressor();
    limiter.threshold.value = -8;
    limiter.knee.value = 0;
    limiter.ratio.value = 20;
    limiter.attack.value = 0.003;
    limiter.release.value = 0.15;
    master.connect(comp).connect(limiter).connect(ctx.destination);

    this.noise = this.makeNoise(ctx);

    // The room. One convolver for the whole game: a per-voice reverb is a per-voice
    // FFT, and this is a phone.
    const convolver = ctx.createConvolver();
    convolver.buffer = this.makeImpulse(ctx, 5.5);
    const wet = ctx.createGain();
    wet.gain.value = 0.55;
    // Take the top off the tail: a bright reverb sounds like a tiled room, and the
    // game is trying to sound like forty metres of water.
    const wetTone = ctx.createBiquadFilter();
    wetTone.type = 'lowpass';
    wetTone.frequency.value = 1500;
    wet.connect(convolver).connect(wetTone).connect(master);

    for (const key of AUDIO_TRACK_KEYS) {
      const dry = ctx.createGain();
      const trackWet = ctx.createGain();
      // Bed tracks start silent and get their deliberate first-touch fade below.
      const initial = isBedTrack(key) ? 0 : this.trackGain(key);
      dry.gain.value = initial;
      trackWet.gain.value = initial;
      dry.connect(master);
      trackWet.connect(wet);
      this.tracks[key] = { dry, wet: trackWet };
    }

    this.startBed();
    this.startBreathVoice();
    this.startSheathVoice();
    this.startRingVoice();
    // Whatever bed the game is already standing in, applied instantly rather than
    // faded: this runs under the player's first touch, so there is no previous bed
    // for it to dissolve out of. Every act change after this one is a four-second
    // crossfade (`applyVoicing`).
    this.applyVoicing(0.01);
    // Ramp every bed layer in rather than snapping it on under the player's first
    // touch. Their independent targets make the settings mixer live immediately.
    for (const key of BED_TRACK_KEYS) {
      const route = this.tracks[key];
      route?.dry.gain.setTargetAtTime(this.trackGain(key), ctx.currentTime, 2.2);
      route?.wet.gain.setTargetAtTime(this.trackGain(key), ctx.currentTime, 2.2);
    }
  }

  /**
   * Two seconds of brown-ish noise, reused by every water sound in the game - and
   * the only buffer in it that loops, which is why it is also the only place a
   * loop *seam* can exist.
   *
   * Seven voices set `loop = true` on this one buffer, and four of them are long
   * enough to reach the end of it and start again: the shimmer, in all eight beds,
   * every 1.18 s; act IV's held breath every 1.67 s, in the quietest act in the
   * campaign; act V's sheath every 3.64 s; and act III's shear, six to twenty times
   * per gesture, through a bandpass narrow enough to ring. So the seam was being
   * crossed roughly once a second for the entire length of a session.
   *
   * The integrator used to start from `last = 0`, which is a fine way to make two
   * seconds of brown noise and a poor way to make two seconds that join up. The
   * value at the last sample is wherever a random walk had wandered to; the value at
   * the first is near zero; and the wrap between them is a step. Measured over two
   * hundred buffers: **the step averaged 0.153 against a mean sample-to-sample
   * movement of 0.036 - four and a half times an ordinary transition, and only 1.6 dB
   * below the whole signal's RMS.** A step is broadband by definition and this signal
   * is not, so the excess lands where the ear is listening: through an 8 kHz highpass
   * the seam peaked 3.2 dB above the loudest ordinary millisecond in the same buffer.
   * Not a bang - a tick, at 0.85 Hz, forever, which is worse, because a periodic tick
   * is one the ear finds and then cannot stop finding.
   *
   * The fix is to make the buffer genuinely periodic rather than to crossfade the
   * seam, which would have cost a stretch of correlated noise for nothing. A leaky
   * integrator is a stable one-pole filter, so if its *input* is periodic its output
   * is too, once the state has settled - and the state settles in about 50 samples
   * (the pole is at 1/1.02). Keep the white sequence, run the integrator over the
   * tail of it first so that the state entering sample 0 is the state the wrap will
   * hand it, and the last sample flows into the first the way every other pair of
   * samples does. Measured the same way afterwards: the step is 0.030, which is
   * *below* an ordinary transition, and the 8 kHz seam sits 2.2 dB under the buffer's
   * own worst millisecond. It costs one extra pass over 2 s of samples, once, at
   * unlock.
   */
  private makeNoise(ctx: AudioContext): AudioBuffer {
    const len = Math.floor(ctx.sampleRate * 2);
    const buf = ctx.createBuffer(1, len, ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
    // Forty times the filter's own settling length, so what is left of the transient
    // is smaller than a float can hold.
    const warm = Math.min(len, 2000);
    let last = 0;
    for (let i = len - warm; i < len; i++) last = (last + 0.02 * data[i]!) / 1.02;
    // Leaky integrator: brown-ish noise, which is what water actually sounds like.
    // In place - each sample's white value is read before its brown value overwrites it.
    for (let i = 0; i < len; i++) {
      last = (last + 0.02 * data[i]!) / 1.02;
      data[i] = last * 3.2;
    }
    return buf;
  }

  /**
   * A generated impulse response: noise under an exponential decay, with the two
   * channels decorrelated so the tail has width. Cheap, and it costs nothing to
   * ship - the alternative is a 400 kB wav for a game that is otherwise 60 kB.
   */
  private makeImpulse(ctx: AudioContext, seconds: number): AudioBuffer {
    const len = Math.floor(ctx.sampleRate * seconds);
    const buf = ctx.createBuffer(2, len, ctx.sampleRate);
    for (let ch = 0; ch < 2; ch++) {
      const data = buf.getChannelData(ch);
      let last = 0;
      for (let i = 0; i < len; i++) {
        const t = i / len;
        // A short fade-in on the tail as well: an impulse that starts at full
        // amplitude gives every note a metallic edge on its first millisecond.
        const swell = Math.min(1, i / (ctx.sampleRate * 0.03));
        const decay = Math.pow(1 - t, 2.6);
        const white = Math.random() * 2 - 1;
        last = (last + 0.35 * white) / 1.35;
        data[i] = last * decay * swell * 1.6;
      }
    }
    return buf;
  }

  /**
   * The bed: a three-note drone that never changes, filtered noise for the body of
   * the water, and a shimmer far above both. Every layer has its own slow LFO on a
   * rate that shares no factor with the others, so the sum never repeats inside a
   * session and there is no pulse to lock onto.
   */
  private startBed(): void {
    const ctx = this.ctx;
    if (ctx === null || this.noise === null) return;

    // --- the water itself -------------------------------------------------
    //
    // Slowblue: the water has no noise in it at all, and it took two passes to get there.
    //
    // It began as one layer: brown noise under a 300 Hz lowpass at 0.42. That is an
    // honest description of forty metres of ocean and the wrong sound to listen to,
    // because broadband low noise is not calm, it is weight. The first fix kept the noise
    // and demoted it - a near-inaudible body, a quiet moving band an octave and a half up,
    // and a stream of Minnaert bubbles over the top. Listened to, the demotion was not
    // enough: any noise floor at all reads as a *hiss*, and a hiss is the one texture
    // nobody finds restful. It does not matter how quiet it is; it is broadband, so it is
    // always there, and something that is always there is something the ear stops being
    // able to ignore.
    //
    // So the water is now *only* the drops. There is no bed layer here to start - the
    // whole track is scheduled, one bubble at a time, by `updateBubbles`. What used to be
    // the body of the water is covered by the drone's own 55 Hz root, which is a tone and
    // therefore has somewhere to be rather than being everywhere at once.
    //
    // The two consequences worth knowing: the breath no longer has a noise level or a
    // filter corner to open on this track, so it acts on the *bubble rate* instead
    // (`updateBubbles`), which is a better cue anyway - it is rhythmic rather than
    // spectral. And the exhale hush, which was a six-second noise swell, is now a gurgle:
    // drops, on the turn of the breath, from alternating sides.

    // --- the chord --------------------------------------------------------
    //
    // One stack for the whole session. Every bed voices it differently - see
    // `Beds.ts` and `applyVoicing` - and none of them replaces it, because a chord
    // that stops and another that starts is a seam, and there are no seams in this
    // campaign. The values below are act I's and are what the game opens on.
    const padGain = ctx.createGain();
    padGain.gain.value = 0.055;
    const padFilter = ctx.createBiquadFilter();
    padFilter.type = 'lowpass';
    padFilter.frequency.value = 520;
    padGain.connect(padFilter);
    // A little of the drone into the room, so the chord has a tail behind it.
    this.connectTrack(padFilter, 'drone', 1);
    this.padFilterParam = padFilter.frequency;
    this.padGain = padGain.gain;
    // Root, fifth, octave, and the fifth again an octave up: an open chord with no
    // third in it, so it is neither major nor minor and cannot suggest a mood.
    const voices: [number, number, number][] = [
      [ROOT_HZ, -4, 0.037],
      [ROOT_HZ * 1.5, 6, 0.053],
      [ROOT_HZ * 2, -7, 0.071],
      [ROOT_HZ * 3, 5, 0.043],
    ];
    for (const [hz, detune, rate] of voices) {
      const osc = ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.value = hz;
      osc.detune.value = detune;
      const g = ctx.createGain();
      g.gain.value = 0.5;
      this.slowLfo(rate, 0.45, g.gain);
      osc.connect(g).connect(padGain);
      osc.start();
      this.padVoices.push(osc);
      this.bedNodes.push(osc);
    }

    // --- the shimmer above it --------------------------------------------
    const air = ctx.createBufferSource();
    air.buffer = this.noise;
    air.loop = true;
    air.playbackRate.value = 1.7;
    const airFilter = ctx.createBiquadFilter();
    airFilter.type = 'bandpass';
    airFilter.frequency.value = 1500;
    airFilter.Q.value = 1.6;
    const airGain = ctx.createGain();
    airGain.gain.value = 0.05;
    air.connect(airFilter).connect(airGain);
    this.connectTrack(airGain, 'shimmer', 1);
    // The two LFO depths are held as params of their own, because a bed that drops
    // the shimmer to a fifth of act I's level (orbit does) would otherwise be
    // swamped by a modulation written for act I's.
    this.shimmerLfoDepth = this.slowLfo(0.017, 0.045, airGain.gain);
    this.shimmerSweepDepth = this.slowLfo(0.029, 420, airFilter.frequency);
    this.shimmerGain = airGain.gain;
    this.shimmerFreq = airFilter.frequency;
    this.shimmerQ = airFilter.Q;
    this.shimmerRate = air.playbackRate;

    air.start();
    this.bedNodes.push(air);
  }

  /**
   * The bed's three sustained layers, moved to wherever the current bed wants
   * them. `seconds` is 0 at unlock and `BED_FADE` at every act change after it.
   *
   * `setTargetAtTime`'s argument is a time *constant*, not a duration - the ramp
   * is exponential and reaches about 95% in three of them - so the fade is
   * divided by three here. That is the difference between an act change that has
   * arrived by the time the banner clears and one that is still creeping four
   * seconds later.
   */
  private applyVoicing(seconds: number): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const t = ctx.currentTime;
    const tau = Math.max(0.01, seconds / 3);
    const { drone, shimmer } = this.bed;
    this.padGain?.setTargetAtTime(drone.gain, t, tau);
    this.padFilterParam?.setTargetAtTime(drone.cutoff, t, tau);
    // The detune pattern is act I's, scaled: alternating signs so no two voices
    // beat in the same direction, and a bed with a wide `spread` is four things
    // nearly agreeing rather than four things in tune. See act V.
    const pattern = [-4, 6, -7, 5];
    for (let i = 0; i < this.padVoices.length; i++) {
      const osc = this.padVoices[i];
      if (osc === undefined) continue;
      osc.frequency.setTargetAtTime(ROOT_HZ * drone.partials[i]!, t, tau);
      osc.detune.setTargetAtTime((pattern[i]! * drone.spread) / 6, t, tau);
    }
    this.shimmerGain?.setTargetAtTime(shimmer.gain, t, tau);
    this.shimmerFreq?.setTargetAtTime(shimmer.hz, t, tau);
    this.shimmerQ?.setTargetAtTime(shimmer.q, t, tau);
    this.shimmerRate?.setTargetAtTime(shimmer.rate, t, tau);
    this.shimmerLfoDepth?.setTargetAtTime(shimmer.gain * 0.9, t, tau);
    this.shimmerSweepDepth?.setTargetAtTime(shimmer.hz * 0.28, t, tau);
    // The two beds that own a held voice each fade theirs up; the other six fade
    // both down to nothing. Building them per act would be a graph rebuild inside
    // a running station, which is the one thing an audio graph cannot do quietly.
    const inOrbit = this.bedKey === 'orbit' ? 1 : 0;
    this.breathBody?.gain.setTargetAtTime(BREATH_GAIN * inOrbit, t, tau);
    this.breathAir?.gain.setTargetAtTime(BREATH_GAIN * 0.5 * inOrbit, t, tau);
    if (this.bedKey !== 'fire') this.sheath?.gain.setTargetAtTime(0, t, tau);
  }

  /**
   * One bubble. A sine whose pitch sweeps *upward* as it decays, which is what a bubble
   * does and what no filtered noise burst can imitate.
   *
   * This is the one voice in the engine that is allowed under the 40 ms attack floor, and
   * the exception is not a compromise - it is the same reasoning. That floor exists so
   * nothing in the game *clicks*, and it was written for the event cues, whose job is to
   * be noticed. A bubble's entire life is 20-200 ms; a 40 ms attack on a 40 ms sound is
   * not a soft bubble, it is no bubble. The attack is a fifth of the duration and never
   * below 6 ms, the level is a twentieth of a bell's, and the whole thing is a sine - so
   * there is no edge and no harmonic for an attack to expose.
   */
  private bubble(
    radiusMm: number,
    pan: number,
    gain: number,
    delay = 0,
    track: AudioTrackKey = 'ocean',
  ): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const f0 = bubbleFrequency(radiusMm);
    const dur = bubbleDuration(radiusMm);
    const t = ctx.currentTime + delay;
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(f0, t);
    osc.frequency.exponentialRampToValueAtTime(f0 * bubbleRise(radiusMm), t + dur);
    const g = ctx.createGain();
    const peak = Math.max(0.0002, gain * bubbleLevel(radiusMm));
    const attack = Math.max(0.006, dur * 0.2);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(g);
    // A generous send: a bubble with no tail is a bubble in a bucket. It is also what
    // turns a countable stream of blips into one continuous body of water, because each
    // one is still in the room when the next three arrive.
    this.connectTrack(g, track, 0.9, pan);
    osc.start(t);
    osc.stop(t + dur + 0.05);
  }

  /**
   * A gurgle: several bubbles of different sizes inside a fifth of a second.
   *
   * A single bubble is a *bloop*; the sound the ear reads as water is a handful of them
   * arriving together with their radii spread, because that is what one pocket of air
   * breaking up actually produces. Rare enough to stay an event - see `BUBBLE_CLUSTER`.
   */
  private gurgle(pan: number, gain: number): void {
    const n = 2 + Math.floor(Math.random() * GURGLE_EXTRA);
    for (let i = 0; i < n; i++) {
      const r = bubbleRadius(Math.random(), this.depth);
      // Spread across the cluster rather than stacked: overlapping onsets sum into a
      // peak, and the compressor should not be doing the work a schedule can do.
      this.bubble(r, pan + (Math.random() - 0.5) * 0.5, gain * 0.7, i * 0.028 + Math.random() * 0.03);
    }
  }

  /**
   * One wingbeat: a band of noise where the wing's trailing edge sheds it.
   *
   * The contrast with `bubble()` is the point of the whole act. A bubble is a
   * *resonator*, so it is a sine that rings and rises. A wing is an edge dragging
   * air, so it is noise inside a band - and where a bubble's pitch climbs as it
   * shrinks, a wing's band falls through the stroke as the tip decelerates into
   * the turn. Same file structure, same discipline, opposite physics.
   *
   * The attack is the other difference, and it is the reason this does not go
   * through `burst()`. Water swells; a wing *arrives*. A third of the duration
   * spent swelling - which is right for every water sound in the game - turns a
   * beat into a sigh. An eighth keeps the onset, and a wing is broadband noise
   * with no partial for a fast attack to expose, so nothing clicks.
   */
  private wing(
    spanM: number,
    pan: number,
    gain: number,
    delay = 0,
    track: AudioTrackKey = 'ocean',
  ): void {
    const ctx = this.ctx;
    if (ctx === null || this.noise === null) return;
    const f0 = wingFrequency(spanM);
    const dur = wingDuration(spanM);
    const t = ctx.currentTime + delay;
    const src = ctx.createBufferSource();
    src.buffer = this.noise;
    src.loop = true;
    src.playbackRate.value = 0.85 + Math.random() * 0.3;
    const f = ctx.createBiquadFilter();
    f.type = 'bandpass';
    f.Q.value = wingQ(spanM);
    f.frequency.setValueAtTime(f0, t);
    // Down a fourth over the stroke: the tip is fastest in the middle and stops at
    // the turn, so the band it sheds falls as the beat ends.
    f.frequency.exponentialRampToValueAtTime(f0 * 0.72, t + dur);
    const g = ctx.createGain();
    const peak = Math.max(0.0002, gain * wingLevel(spanM));
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + dur * 0.12);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g);
    // The same generous send the water gets, for the same reason: it is what turns
    // countable events into one body of air with a flock inside it.
    this.connectTrack(g, track, 0.9, pan);
    src.start(t);
    src.stop(t + dur + 0.05);
  }

  /**
   * A flock beat: several wings of different spans inside a fifth of a second.
   *
   * A single wing is one bird overhead. What reads as a *flock* is a handful of
   * beats arriving almost together with their spans spread, because a hundred
   * birds are never in unison - the smear is the sound of the number of them.
   */
  private beats(pan: number, gain: number): void {
    const n = 2 + Math.floor(Math.random() * WING_CLUSTER);
    for (let i = 0; i < n; i++) {
      const span = wingSpan(Math.random(), this.altitude);
      this.wing(span, pan + (Math.random() - 0.5) * 0.7, gain * 0.72, i * 0.045 + Math.random() * 0.05);
    }
  }

  /**
   * The wingbeat stream, and the one place the breath is *diegetic*.
   *
   * The water got busier on the exhale. The air does the opposite: **the flock
   * beats on the inhale and glides on the exhale.** That is not a mirrored knob,
   * it is what a bird does - flapping is the work of climbing and gliding is the
   * rest between - and it means a player breathing with the game hears a hundred
   * wings go quiet every time they breathe out. Free entrainment, and the most
   * ASMR thing in the act comes out of the physics rather than out of a sample.
   *
   * Poisson-ish, like the bubbles, so there is no rate the ear can lock onto -
   * which for wings matters even more than it did for water, because a flock
   * beating in lockstep is a helicopter.
   */
  private updateWings(dt: number): void {
    if (!this.trackAudible('ocean')) return;
    this.toWing -= dt;
    if (this.toWing > 0) return;
    // `breath` is 1 fully inhaled: the busy half is the in-breath.
    const beating = 0.55 + 0.75 * this.breath;
    // Thinner air higher up, and fewer, larger, slower birds in it. After the
    // release the flock is gliding out of the act, so the stream all but stops.
    const thin = (1 - this.altitude * 0.3) * (this.releaseQuiet > 0 ? 0.22 : 1);
    const rate = WING_RATE * beating * thin;
    this.toWing = -Math.log(1 - Math.random() * 0.999) / Math.max(0.15, rate);
    const pan = (Math.random() * 2 - 1) * 0.8;
    if (Math.random() < 0.55) {
      this.beats(pan, WING_GAIN);
      return;
    }
    this.wing(wingSpan(Math.random(), this.altitude), pan, WING_GAIN);
  }

  /**
   * One gust of wind: a broad soft swell that leans darker as it dies, the way
   * moving air heard from inside it actually behaves. Above the cloud deck a thin
   * whistle rides on top - wind through feathers is a high, narrow thing, and it
   * is the only part of a gust that survives into the anvil.
   */
  private gust(pan: number): void {
    const alt = this.altitude;
    const dur = 2.4 + Math.random() * 1.8;
    const hz = 340 + Math.random() * 260 + alt * 180;
    // On `motion`, not with the flock. The wind and the birds in it are two
    // different things, and act II is the first bed with both - a player who
    // wants the wind without a hundred wingbeats over it can now have it.
    this.burst('motion', hz, dur, 0.02 + Math.random() * 0.012, 'bandpass', 0.55, hz * 0.62, 0.7, pan);
    if (alt > 0.35 && Math.random() < 0.4 + alt * 0.4) {
      const whistle = 1900 + Math.random() * 1100;
      this.burst('motion', whistle, dur * 0.7, 0.006 + alt * 0.005, 'bandpass', 3.2, whistle * 0.85, 0.85, pan);
    }
  }

  /**
   * The gust stream. Poisson like everything scheduled, and cued to the *exhale*:
   * the flock beats on the in-breath and glides on the out-breath, so the out-breath
   * is where the air itself gets to speak - the same half of the cycle the water
   * gave its bubbles, occupied by the medium's own voice instead of the carried
   * life's. Higher up the gusts come rarer and thinner; by the anvil the air is
   * nearly out of things to say, which is the act's whole arc in one scheduler.
   */
  private updateGusts(dt: number): void {
    if (!this.trackAudible('motion')) return;
    this.toGust -= dt;
    if (this.toGust > 0) return;
    const exhaling = 0.7 + 0.6 * (1 - this.breath);
    const thin = 1 - this.altitude * 0.45;
    const rate = 0.12 * exhaling * thin;
    this.toGust = -Math.log(1 - Math.random() * 0.999) / Math.max(0.03, rate);
    this.gust((Math.random() * 2 - 1) * 0.85);
  }

  /**
   * Distant thunder: three staggered low swells and a breath of sub under them,
   * everything sent deep into the room. No crack - a crack is a transient, and
   * this engine does not do transients; thunder heard from kilometres away is
   * all roll and no edge, which is exactly the sound that fits.
   */
  private thunder(near = false): void {
    const pan = (Math.random() * 2 - 1) * 0.7;
    // Under the cloud rather than over it, the storm keeps a little of its top
    // end and arrives sooner - the difference between weather you are climbing
    // past and weather you are inside. Still no crack: even overhead, this engine
    // does not do transients, and the swells are still seconds long.
    const b = near ? 1.5 : 1;
    this.burst('whale', 150 * b, 2.6, 0.055, 'lowpass', 0.7, 70 * b, 0.9, pan);
    // The later swells arrive from slightly elsewhere: a roll is the same sound
    // reflected off different air.
    this.burst('whale', 110 * b, 3.4, 0.045, 'lowpass', 0.6, 55 * b, 0.95, pan * 0.4, near ? 0.45 : 0.7);
    this.burst('whale', 85 * b, 4.2, 0.03, 'lowpass', 0.6, 48 * b, 0.95, -pan * 0.5, near ? 1.1 : 1.6);
    // The sub under the roll: E1 falling to D1. It was 44 falling to 36, which is
    // four and a half seconds of a sustained sine a hundred cents off the scale and
    // eleven hertz away from beating against the drone's own root. Felt rather than
    // heard is not the same as exempt - a beat is the one thing the ear finds at any
    // level, and it finds it faster down here than anywhere else.
    this.tone('whale', ROOT_HZ * 0.75, 4.5, 0.035, 'sine', 0.2, ROOT_HZ * 2 / 3, 1.2, 0.7, pan * 0.3);
  }

  /**
   * The thunder schedule, and it runs twice in the campaign for opposite reasons.
   *
   * In act II it is **altitude-gated**: only the squall and the anvil over it have
   * weather in them. The spray is too low, the cumulus field too fair, and above
   * the anvil there is nothing overhead at all - the two stratospheric stations
   * are silent because at 25 and 82 km there is nothing to make a sound, which is
   * the mix saying what the palette says.
   *
   * In act VI (`near`) there is no gate, because the whole act is inside the
   * weather. It is the same storm met from underneath, which is what act VI's
   * second station is about, and nothing anywhere tells the player that.
   */
  private updateThunder(dt: number, near = false): void {
    if (!this.trackAudible('whale')) return;
    if (near) {
      this.toThunder -= dt;
      if (this.toThunder > 0) return;
      this.toThunder = 24 + Math.random() * 40;
      this.thunder(true);
      return;
    }
    const alt = this.altitude;
    /*
     * Slowblue: this window was `0.2 .. 0.65`, peaking at 0.42, and `arc01` is 0 at an
     * act's first station and 1 at its last - so on act II's shipped six stations
     * thunder came in over the Cliff, peaked dead centre of the *fair-weather
     * cumulus field*, and was silent in the Squall and the Anvil. The exact inverse
     * of the paragraph above it, and the loudest identity mismatch in the mix.
     *
     * The numbers were right for the act II that existed when they were written -
     * six stations reaching to 82 km, which put the storm two thirds of the way up.
     * The Cliff and The Passage were inserted and the top two stations were given to act
     * III, and nothing re-derived the one place in the audio that reads a position
     * rather than a bed. It is the same shape as every other fossil in this
     * codebase: a surface built for one cut of the campaign and never asked again.
     */
    if (alt < 0.6) return;
    this.toThunder -= dt;
    if (this.toThunder > 0) return;
    // Densest in the squall itself (alt ~0.75): the interval tightens as the act
    // climbs into the weather and relaxes again as it climbs out of it - at the
    // anvil, alt 1.0, `inStorm` is 0.107 and the interval relaxes to 1.31x base.
    const inStorm = 1 - Math.abs(alt - 0.75) / 0.28;
    this.toThunder = (26 + Math.random() * 44) * (1.4 - 0.8 * Math.max(0, inStorm));
    this.thunder();
  }

  /**
   * The bubble stream. Poisson-ish: an interval drawn fresh after every bubble, so there
   * is no rate the ear can lock onto, which is the whole difference between a spring and
   * an aquarium pump.
   *
   * One thing modulates the rate, and it is the breath: it goes up on the exhale
   * (`breathAt` is pushed in by `setBreath`). Rising with the out-breath is deliberate -
   * it is the entrainment cue one layer up from a voice, and it is what makes the water
   * sound like it is agreeing with you.
   */
  private updateBubbles(dt: number): void {
    if (!this.trackAudible('ocean')) return;
    this.toBubble -= dt;
    if (this.toBubble > 0) return;
    // Livelier as the campaign climbs - but only mildly, because depth is already
    // carried by bubble *size* (`bubbleRadius`), and a deep station that also went quiet
    // fell straight into the dripping-tap failure the rate band exists to avoid.
    const lively = 1 - this.depth * 0.22;
    // The exhale is the busy half. `breath` is 1 fully inhaled, so this is its inverse.
    const exhaling = 0.8 + 0.4 * (1 - this.breath);
    const rate = BUBBLE_RATE * lively * exhaling;
    this.toBubble = -Math.log(1 - Math.random() * 0.999) / Math.max(0.2, rate);
    const pan = (Math.random() * 2 - 1) * 0.75;
    if (Math.random() < BUBBLE_CLUSTER) {
      this.gurgle(pan, BUBBLE_GAIN);
      return;
    }
    this.bubble(bubbleRadius(Math.random(), this.depth), pan, BUBBLE_GAIN);
  }

  /**
   * One whale call: a fundamental that *glides*, two harmonics above it, and a slow
   * vibrato across all three.
   *
   * The three things that make this an animal rather than a synthesiser, in order of how
   * much they matter:
   *
   *   1. **The glide.** `exponentialRampToValueAtTime` across the whole duration, a third
   *      to a fifth. A whale moan does not hold a pitch, and a held pitch with vibrato on
   *      it is unmistakably a machine.
   *   2. **The harmonics are inharmonic.** 2.01x and 3.02x rather than exactly 2 and 3.
   *      A perfectly harmonic stack fuses into one bright tone; a couple of cents out and
   *      the partials beat slowly against each other, which is what a body resonating
   *      sounds like as opposed to an oscillator bank.
   *   3. **The envelope is longer than the sound is loud.** Attack and release are each
   *      about a fifth of the call, so it swells out of the bed and sinks back into it.
   *      Nothing in this game arrives, and a whale least of all.
   *
   * Deep into the reverb (0.95 send), because distance is the whole point: the animal is
   * never near, and a whale with a dry signal is a whale in the room with you.
   */
  private whaleCall(call: WhaleCall, gain: number, near = false): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const t = ctx.currentTime + call.delay;
    // Act VII's animal is close, and closeness in this engine is a *send*, not a
    // level: 0.95 of the signal into a six-second tail is what "a long way off"
    // has always meant here, so two thirds of that is what "beside you" means.
    const wet = near ? 0.62 : 0.95;
    const dur = call.duration;
    const g = ctx.createGain();
    const peak = Math.max(0.0002, gain * call.gain);
    const edge = dur * 0.22;
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + edge);
    g.gain.setValueAtTime(peak, t + dur - edge);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    // One lowpass over the whole call, sweeping with the glide: a moan gets darker as it
    // falls, because the water between you and it takes the top off first.
    const tone = ctx.createBiquadFilter();
    tone.type = 'lowpass';
    tone.Q.value = 0.7;
    tone.frequency.setValueAtTime(call.hz * 6, t);
    tone.frequency.exponentialRampToValueAtTime(Math.max(120, call.glideTo * 4.5), t + dur);
    g.connect(tone);
    this.connectTrack(tone, 'whale', wet, call.pan);
    // A single slow vibrato shared by every partial, so they move as one body.
    const vib = ctx.createOscillator();
    vib.frequency.value = 0.9 + Math.random() * 1.4;
    const vibDepth = ctx.createGain();
    // In cents, via `detune`: a fixed Hz depth would be a wobble at the bottom of the
    // glide and nothing at the top.
    vibDepth.gain.value = 14 + Math.random() * 12;
    vib.connect(vibDepth);
    vib.start(t);
    vib.stop(t + dur + 0.1);
    for (const [mult, level] of [
      [1, 1],
      [2.01, 0.3],
      [3.02, 0.12],
    ] as const) {
      const osc = ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(call.hz * mult, t);
      osc.frequency.exponentialRampToValueAtTime(call.glideTo * mult, t + dur);
      vibDepth.connect(osc.detune);
      const partial = ctx.createGain();
      partial.gain.value = level;
      osc.connect(partial).connect(g);
      osc.start(t);
      osc.stop(t + dur + 0.1);
    }
  }

  /**
   * The whale, scheduled. One phrase, then a minute or two of nothing.
   *
   * The gap is the sound. A whale that answers itself every ten seconds is a car alarm;
   * the reason a recording of one is affecting is that you wait for it, and this schedule
   * exists to make the player wait.
   */
  private updateWhale(dt: number): void {
    if (!this.trackAudible('whale')) return;
    this.toWhale -= dt;
    if (this.toWhale > 0) return;
    // Act VII's whale is the same animal, near. It is the one voice in the game
    // whose *distance* changes, and it changes once, in the last act, because the
    // thing that was calling from a long way off in act I is answering now.
    const near = this.bedKey === 'homecoming';
    this.toWhale = whaleGap(Math.random) * (near ? 0.55 : 1);
    for (const call of whalePhrase(Math.random, this.depth)) {
      this.whaleCall(call, WHALE_GAIN * (near ? 1.25 : 1), near);
    }
  }

  // --- act III: ice, shear and the waveguide -------------------------------

  /**
   * One ice crystal, ringing.
   *
   * A sine, like a bubble, and the opposite of one in the two ways that matter:
   * its pitch **falls** through the ring instead of rising, and it lasts a second
   * and a half instead of a twentieth of one. Those two differences alone are
   * enough for the ear to file it under glass rather than water, which is the
   * whole job - act III must not sound like act I with the volume down.
   *
   * A second partial a fifth above, a fifth of the level, dying first: that is
   * what a plate does and what a single sine cannot fake.
   */
  private crystal(
    sizeUm: number,
    pan: number,
    gain: number,
    delay = 0,
    track: AudioTrackKey = 'ocean',
  ): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const f0 = crystalFrequency(sizeUm);
    const dur = crystalDuration(sizeUm);
    const fall = crystalFall(sizeUm);
    const peak = Math.max(0.0002, gain * crystalLevel(sizeUm));
    const t = ctx.currentTime + delay;
    for (const [mult, level, span] of [
      [1, 1, 1],
      [1.5, 0.22, 0.55],
    ] as const) {
      const osc = ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(f0 * mult, t);
      osc.frequency.exponentialRampToValueAtTime(f0 * mult * fall, t + dur * span);
      const g = ctx.createGain();
      g.gain.setValueAtTime(0.0001, t);
      // 40 ms, which is the engine's floor. Ice has an onset; it does not swell.
      g.gain.exponentialRampToValueAtTime(peak * level, t + 0.04);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur * span);
      osc.connect(g);
      this.connectTrack(g, track, 0.95, pan);
      osc.start(t);
      osc.stop(t + dur * span + 0.05);
    }
  }

  private updateCrystals(dt: number): void {
    if (!this.trackAudible('ocean')) return;
    this.toCrystal -= dt;
    if (this.toCrystal > 0) return;
    const rate = crystalRate(this.altitude);
    this.toCrystal = -Math.log(1 - Math.random() * 0.999) / Math.max(0.06, rate);
    this.crystal(
      crystalSize(Math.random(), this.altitude),
      (Math.random() * 2 - 1) * 0.85,
      CRYSTAL_GAIN,
    );
  }

  /**
   * One layer sliding past another: a very narrow band of noise that sweeps
   * between two pitches while travelling across the stereo field.
   *
   * The only sound in the game whose stereo position moves under its own steam
   * (the ring shimmer's follows the player's hand, which is not the same thing),
   * and it has to: a layer is *going somewhere* and that is the act's entire
   * subject. Ten to twenty seconds, which makes it the slowest single gesture
   * Slowblue contains.
   */
  private shear(): void {
    const ctx = this.ctx;
    if (ctx === null || this.noise === null) return;
    const band = shearBand(Math.random, this.altitude);
    const t = ctx.currentTime;
    const dur = band.duration;
    const src = ctx.createBufferSource();
    src.buffer = this.noise;
    src.loop = true;
    src.playbackRate.value = 1.4 + Math.random() * 0.6;
    const f = ctx.createBiquadFilter();
    f.type = 'bandpass';
    f.Q.value = band.q;
    f.frequency.setValueAtTime(band.fromHz, t);
    f.frequency.exponentialRampToValueAtTime(band.toHz, t + dur);
    const g = ctx.createGain();
    const peak = Math.max(0.0002, SHEAR_GAIN * band.gain);
    g.gain.setValueAtTime(0.0001, t);
    // A third in, a third out. Nothing about a layer arrives.
    g.gain.exponentialRampToValueAtTime(peak, t + dur * 0.35);
    g.gain.setValueAtTime(peak, t + dur * 0.6);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g);
    const route = this.tracks.motion;
    if (route === undefined) return;
    if (typeof ctx.createStereoPanner === 'function') {
      const panner = ctx.createStereoPanner();
      panner.pan.setValueAtTime(band.pan, t);
      panner.pan.linearRampToValueAtTime(band.panTo, t + dur);
      g.connect(panner).connect(route.dry);
    } else {
      g.connect(route.dry);
    }
    const send = ctx.createGain();
    send.gain.value = 0.85;
    g.connect(send).connect(route.wet);
    src.start(t);
    src.stop(t + dur + 0.1);
  }

  private updateShear(dt: number): void {
    if (!this.trackAudible('motion')) return;
    this.toShear -= dt;
    if (this.toShear > 0) return;
    this.toShear = shearGap(Math.random);
    this.shear();
  }

  /**
   * The stratosphere is the planet's waveguide, and this is what comes down it.
   *
   * Two sine partials a fifth apart, twenty-six to forty-eight hertz, ten to
   * twenty seconds long, sagging as they go, ninety-five per cent into the room.
   * On a phone speaker most of it is inaudible and that is correct - it is
   * infrasound, and the part of it a person hears is the top edge.
   */
  private infrasound(): void {
    const s = infrasoundSwell(Math.random, this.altitude);
    const gain = INFRA_GAIN * s.gain;
    this.tone('whale', s.hz, s.duration, gain, 'sine', 0, s.glideTo, s.duration * 0.3, 0.95, s.pan);
    this.tone(
      'whale',
      s.hz * 1.5,
      s.duration * 0.8,
      gain * 0.3,
      'sine',
      s.duration * 0.15,
      s.glideTo * 1.5,
      s.duration * 0.3,
      0.95,
      -s.pan * 0.6,
    );
  }

  private updateInfrasound(dt: number): void {
    if (!this.trackAudible('whale')) return;
    this.toInfra -= dt;
    if (this.toInfra > 0) return;
    this.toInfra = infrasoundGap(Math.random);
    this.infrasound();
  }

  // --- act IV: breath, heartbeat, radio ------------------------------------

  /**
   * The breath, held. Act IV's body layer and the only bed voice in the game
   * that is not a thing in the world.
   *
   * Two bands of the shared noise buffer with their own filters, built silent and
   * faded up by `applyVoicing` when the orbit bed selects them. `setBreath`
   * pushes their levels and corners every frame off the game's own breath clock,
   * so what the player hears is their own breathing coming back to them - which
   * is what §13 asks for and is also, on headphones, the most intimate thing the
   * mix does anywhere in the campaign.
   */
  private startBreathVoice(): void {
    const ctx = this.ctx;
    if (ctx === null || this.noise === null) return;
    const make = (hz: number, q: number, pan: number): { gain: AudioParam; freq: AudioParam } => {
      const src = ctx.createBufferSource();
      src.buffer = this.noise;
      src.loop = true;
      src.playbackRate.value = 1.2;
      const f = ctx.createBiquadFilter();
      f.type = 'bandpass';
      f.frequency.value = hz;
      f.Q.value = q;
      const g = ctx.createGain();
      g.gain.value = 0;
      src.connect(f).connect(g);
      this.connectTrack(g, 'ocean', 0.35, pan);
      src.start();
      this.bedNodes.push(src);
      return { gain: g.gain, freq: f.frequency };
    };
    // The two are panned slightly apart, which is what a breath heard from inside
    // a helmet does - the body of it is everywhere and the air of it is near one
    // ear. A centred breath is a breath in a speaker.
    this.breathBody = make(240, 1.1, -0.18);
    this.breathAir = make(1900, 2.4, 0.22);
  }

  /**
   * One beat: lub, then dub, 0.14 s apart.
   *
   * Both under 50 Hz and both pure sines with a 40 ms swell, so there is nothing
   * for the ear to *identify* - a heartbeat you can name is a horror cue. On a
   * phone speaker this is almost entirely inaudible; on headphones it is felt in
   * the chest, which is the only place a heartbeat has ever been heard from.
   */
  private heart(): void {
    for (const thump of heartBeat()) {
      this.tone(
        'motion',
        thump.hz,
        thump.duration,
        HEART_GAIN * thump.gain,
        'sine',
        thump.delay,
        thump.hz * 0.78,
        0.04,
        0.3,
      );
    }
  }

  private updateHeart(dt: number): void {
    if (!this.trackAudible('motion')) return;
    this.toHeart -= dt;
    if (this.toHeart > 0) return;
    // The one voice in the engine that is *not* Poisson. A heart keeps time, and
    // taking that away from it is taking away the thing it is. The rate falls
    // across the act instead, which is the player settling.
    this.toHeart = 60 / heartRate(this.arc);
    this.heart();
  }

  /**
   * One whistler: lightning heard through the magnetosphere.
   *
   * A descending glide, three to five octaves, one and a half to three seconds -
   * and the descent is **`1/sqrt(f)` in shape**, not exponential, because that is
   * the real dispersion relation and it is why a whistler sags fast at the top
   * and crawls at the bottom. Approximated here as a chain of short exponential
   * segments, which is close enough to be right and cheap enough to be a phone.
   *
   * Bandpassed noise rather than a sine, narrow: a whistler is a radio signal
   * played through a speaker, so it has hiss in it, and it is the one voice in
   * the game where that is the correct texture rather than the forbidden one.
   */
  private whistler(w: ReturnType<typeof whistlerShower>[number]): void {
    const ctx = this.ctx;
    if (ctx === null || this.noise === null) return;
    const t = ctx.currentTime + w.delay;
    const dur = w.duration;
    const src = ctx.createBufferSource();
    src.buffer = this.noise;
    src.loop = true;
    src.playbackRate.value = 2.4;
    const f = ctx.createBiquadFilter();
    f.type = 'bandpass';
    f.Q.value = 14;
    f.frequency.setValueAtTime(w.fromHz, t);
    // Eight segments of `f(u) = from / (1 + u * (from/to - 1))^2`, which is the
    // dispersion curve sampled. One exponential ramp end to end reads as a slide
    // whistle; this reads as something arriving from a long way away.
    const steps = 8;
    for (let i = 1; i <= steps; i++) {
      const u = i / steps;
      const k = 1 + u * (Math.sqrt(w.fromHz / w.toHz) - 1);
      f.frequency.exponentialRampToValueAtTime(w.fromHz / (k * k), t + dur * u);
    }
    const g = ctx.createGain();
    const peak = Math.max(0.0002, WHISTLER_GAIN * w.gain);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + 0.12);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g);
    this.connectTrack(g, 'whale', 0.9, w.pan);
    src.start(t);
    src.stop(t + dur + 0.05);
  }

  private updateWhistlers(dt: number): void {
    if (!this.trackAudible('whale')) return;
    this.toWhistler -= dt;
    if (this.toWhistler > 0) return;
    this.toWhistler = whistlerGap(Math.random);
    for (const w of whistlerShower(Math.random)) this.whistler(w);
  }

  // --- act V: the sheath, the sparks and the shock -------------------------

  /**
   * The plasma sheath, held: the one continuous broadband layer in the game.
   *
   * Built silent at unlock and faded up only by act V, for the reason the file
   * header gives - a hiss is a hiss at any level, and this engine spends that
   * rule exactly once, on the act §13 allows to be loud. What keeps it from being
   * the rumble the water's noise layer was is in `updateSheath`: it breathes, and
   * it goes out.
   */
  private startSheathVoice(): void {
    const ctx = this.ctx;
    if (ctx === null || this.noise === null) return;
    const src = ctx.createBufferSource();
    src.buffer = this.noise;
    src.loop = true;
    // Slow: the noise buffer is brown-ish already, and playing it back under rate
    // takes it further down, which is where a re-entry roar actually lives.
    src.playbackRate.value = 0.55;
    const f = ctx.createBiquadFilter();
    f.type = 'lowpass';
    f.frequency.value = 300;
    f.Q.value = 0.7;
    const g = ctx.createGain();
    g.gain.value = 0;
    src.connect(f).connect(g);
    this.connectTrack(g, 'ocean', 0.5);
    src.start();
    this.bedNodes.push(src);
    this.sheath = { gain: g.gain, freq: f.frequency };
  }

  /**
   * Where the fire is, pushed every frame.
   *
   * Two things move: the level, which peaks at the plasma station and is gone by
   * the nucleus, and the filter corner, which opens on the in-breath and closes
   * on the out-breath over five and a half seconds each way. A roar that moves
   * with your own chest is the one kind of broadband noise people find restful.
   */
  private updateSheath(): void {
    const ctx = this.ctx;
    const sheath = this.sheath;
    if (ctx === null || sheath === null) return;
    const audible = this.trackAudible('ocean');
    const t = ctx.currentTime;
    sheath.gain.setTargetAtTime(audible ? SHEATH_GAIN * sheathLevel(this.arc) : 0, t, 0.8);
    sheath.freq.setTargetAtTime(sheathCorner(this.arc, this.breath), t, 0.5);
  }

  /**
   * The fire going out, in the tuning.
   *
   * Act V's chord opens twenty-two cents wide - four voices *nearly* agreeing,
   * which is the sound of something too hot to hold a pitch - and closes back to
   * six across the act. It is the slowest and least noticeable thing in the mix
   * and it is doing the act's whole argument: nobody hears a detune parameter,
   * and everybody hears four seconds of act V's last station being calmer than
   * its fourth without being able to say why.
   */
  private updateCooling(): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const heat = sheathLevel(this.arc);
    const spread = 6 + (this.bed.drone.spread - 6) * heat;
    const pattern = [-4, 6, -7, 5];
    const t = ctx.currentTime;
    for (let i = 0; i < this.padVoices.length; i++) {
      this.padVoices[i]?.detune.setTargetAtTime((pattern[i]! * spread) / 6, t, 1.5);
    }
  }

  /**
   * The one chord in the game that resolves, and the last thing the campaign does.
   *
   * Across the final third of act VII the pad's lowest voice walks down an octave
   * to 27.5 Hz, which is the bottom of hearing and is where `circle()` lands four
   * minutes later. Nothing in Slowblue has ever come to rest - `SCALE` has no leading
   * tone in it precisely so that nothing can - and this is the single exception,
   * spent on the one moment the game has finished.
   */
  private updateResolve(): void {
    const ctx = this.ctx;
    const root = this.padVoices[0];
    if (ctx === null || root === undefined) return;
    const t = Math.max(0, (this.arc - 0.66) / 0.34);
    root.frequency.setTargetAtTime(ROOT_HZ * (1 - 0.5 * t), ctx.currentTime, 2.5);
  }

  /** One grain of heat shield, leaving. A crackle with the click taken out. */
  private sparkGrain(
    track: AudioTrackKey = 'shimmer',
    pan?: number,
    gain = SPARK_GAIN,
    delay = 0,
  ): void {
    const s = spark(Math.random, this.arc);
    this.burst(
      track,
      s.hz,
      s.duration,
      gain * s.gain,
      'bandpass',
      4.5,
      s.hz * 0.7,
      0.9,
      pan ?? s.pan,
      delay,
    );
  }

  private updateSparks(dt: number): void {
    if (!this.trackAudible('shimmer')) return;
    this.toSpark -= dt;
    if (this.toSpark > 0) return;
    this.toSpark = -Math.log(1 - Math.random() * 0.999) / Math.max(0.3, sparkRate(this.arc));
    this.sparkGrain();
  }

  /** The bow shock, passing: three low swells from slightly different places. */
  private shock(): void {
    for (const s of shockRoll(Math.random, this.arc)) {
      this.burst(
        'motion',
        s.hz,
        s.duration,
        SHOCK_GAIN * s.gain,
        'lowpass',
        0.65,
        s.sweepTo,
        0.9,
        s.pan,
        s.delay,
      );
    }
  }

  private updateShocks(dt: number): void {
    if (!this.trackAudible('motion')) return;
    this.toShock -= dt;
    if (this.toShock > 0) return;
    this.toShock = shockGap(Math.random, this.arc);
    this.shock();
  }

  // --- act VI: rain, which is bubbles ---------------------------------------

  /**
   * One raindrop: the splash, and then the bubble the splash trapped.
   *
   * The bubble is what you actually hear - see `Raindrops.ts` - so it is the loud
   * half and the impact is a fifth of it, a very short broad band an octave
   * above. Underneath the ring it is inaudible as itself and it is the whole
   * difference between rain and a wind chime.
   */
  private drop(
    radiusMm: number,
    pan: number,
    gain: number,
    delay = 0,
    track: AudioTrackKey = 'ocean',
  ): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const f0 = dropFrequency(radiusMm);
    const dur = dropDuration(radiusMm);
    const t = ctx.currentTime + delay;
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(f0, t);
    osc.frequency.exponentialRampToValueAtTime(f0 * dropRise(radiusMm), t + dur);
    const g = ctx.createGain();
    const peak = Math.max(0.0002, gain * dropLevel(radiusMm));
    // A fifth of the duration, floored at 4 ms. The same exception `bubble` takes
    // and for the same reason: a 40 ms attack on a 20 ms sound is not a soft drop,
    // it is no drop.
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + Math.max(0.004, dur * 0.2));
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(g);
    this.connectTrack(g, track, 0.9, pan);
    osc.start(t);
    osc.stop(t + dur + 0.05);
    this.burst(
      track,
      dropImpactHz(radiusMm),
      dur * 0.7,
      peak * 0.2,
      'bandpass',
      0.8,
      0,
      0.7,
      pan,
      delay,
    );
  }

  private updateDrops(dt: number): void {
    if (!this.trackAudible('ocean')) return;
    this.toDrop -= dt;
    if (this.toDrop > 0) return;
    const sheet = sheetAt(this.clock);
    const wet = this.wet;
    const rate = dropRate(sheet, this.breath) * (0.15 + 0.85 * wet);
    this.toDrop = -Math.log(1 - Math.random() * 0.999) / Math.max(2, rate);
    // Above the freezing level the drop is not a drop. Act III's crystal is the
    // voice the engine already owns for suspended ice, and the Cirrus is the last
    // ice in the campaign - so the same track deals a crystal instead, and the top
    // of act VI stops sounding like its bottom.
    if (wet < 0.1) {
      this.crystal(crystalSize(Math.random(), 0.8), (Math.random() * 2 - 1) * 0.8, CRYSTAL_GAIN);
      return;
    }
    this.drop(dropRadius(Math.random(), sheet), (Math.random() * 2 - 1) * 0.85, DROP_GAIN);
  }

  /** One drop on a leaf: no bubble, no pitch, and drier than anything in the sea. */
  private patter(): void {
    const p = patterGrain(Math.random, sheetAt(this.clock));
    this.burst('shimmer', p.hz, p.duration, PATTER_GAIN * p.gain, 'bandpass', p.q, 0, 0.75, p.pan);
  }

  private updatePatter(dt: number): void {
    if (!this.trackAudible('shimmer')) return;
    // There are no leaves at nine kilometres. This layer belongs to the bottom
    // half of the act - the downpour, the canopy - and it was playing over the
    // cirrus and the anvil, which is the one sound in the mix that names a place
    // the swarm is nowhere near.
    if (this.wet < 0.5) return;
    this.toPatter -= dt;
    if (this.toPatter > 0) return;
    const rate = patterRate(sheetAt(this.clock));
    this.toPatter = -Math.log(1 - Math.random() * 0.999) / Math.max(3, rate);
    this.patter();
  }

  // --- the brook ------------------------------------------------------------

  /** One bubble folded under by running water. The same voice as act I's, small. */
  private riffle(
    radiusMm: number,
    pan: number,
    gain: number,
    delay = 0,
    track: AudioTrackKey = 'ocean',
  ): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const f0 = riffleFrequency(radiusMm);
    const dur = riffleDuration(radiusMm);
    const t = ctx.currentTime + delay;
    const osc = ctx.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(f0, t);
    osc.frequency.exponentialRampToValueAtTime(f0 * riffleRise(radiusMm), t + dur);
    const g = ctx.createGain();
    const peak = Math.max(0.0002, gain * riffleLevel(radiusMm));
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(peak, t + Math.max(0.004, dur * 0.25));
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(g);
    this.connectTrack(g, track, 0.85, pan);
    osc.start(t);
    osc.stop(t + dur + 0.05);
  }

  private updateRiffle(dt: number): void {
    if (!this.trackAudible('ocean')) return;
    this.toRiffle -= dt;
    if (this.toRiffle > 0) return;
    const rate = riffleRate(this.flow, this.breath);
    this.toRiffle = -Math.log(1 - Math.random() * 0.999) / Math.max(3, rate);
    // In pairs and threes rather than singly: water folds over in one place
    // several times before it moves on, and a perfectly even stream of single
    // bubbles is a fizz. This is the gurgle argument, at twenty a second.
    const pan = (Math.random() * 2 - 1) * 0.8;
    const n = Math.random() < 0.35 ? 2 + Math.floor(Math.random() * 2) : 1;
    for (let i = 0; i < n; i++) {
      this.riffle(
        riffleRadius(Math.random(), this.flow),
        pan + (Math.random() - 0.5) * 0.3,
        RIFFLE_GAIN,
        i * 0.012 + Math.random() * 0.02,
      );
    }
  }

  /**
   * One cobble, moved a few centimetres by the current.
   *
   * The last percussive thing in the campaign, and the one sound that says the
   * water has a floor - which is what act VII's first station is about.
   */
  private stone(): void {
    const s = stoneKnock(Math.random);
    this.tone('whale', s.hz, s.duration, STONE_GAIN * s.gain, 'sine', 0, s.glideTo, 0.04, 0.55, s.pan);
    // A little body over it, brief and dull: a stone is not a tone.
    this.burst(
      'whale',
      s.hz * 3.2,
      s.duration * 0.5,
      STONE_GAIN * s.gain * 0.35,
      'bandpass',
      2.2,
      s.hz * 2,
      0.5,
      s.pan,
    );
  }

  private updateStones(dt: number): void {
    if (!this.trackAudible('whale')) return;
    this.toStone -= dt;
    if (this.toStone > 0) return;
    this.toStone = stoneGap(Math.random);
    this.stone();
  }

  // --- act VII: the snow ----------------------------------------------------

  /**
   * One flake of marine snow, passing.
   *
   * The only voice in the game whose pitch falls the whole way down and never
   * arrives: the envelope runs out before the glide does, so nothing about it
   * resolves. A very quiet, high, soft thing going past your ear and away, and
   * the sides alternate - see `Snow.ts`.
   */
  private snowflake(
    track: AudioTrackKey = 'motion',
    pan?: number,
    gain = FLAKE_GAIN,
    delay = 0,
  ): void {
    const f = flake(Math.random, this.depth, this.snowSide);
    this.snowSide = -this.snowSide;
    this.tone(
      track,
      f.hz,
      f.duration,
      gain * f.gain,
      'sine',
      delay,
      f.glideTo,
      f.duration * 0.3,
      0.95,
      pan ?? f.pan,
    );
  }

  private updateSnow(dt: number): void {
    if (!this.trackAudible('motion')) return;
    this.toFlake -= dt;
    if (this.toFlake > 0) return;
    const rate = snowRate(this.depth);
    this.toFlake = -Math.log(1 - Math.random() * 0.999) / Math.max(0.08, rate);
    this.snowflake();
  }

  /**
   * One oscillator modulating one parameter, very slowly. Started immediately.
   *
   * Returns the depth control, so a caller whose base value changes with the bed
   * can scale the modulation with it - see `applyVoicing`. Most callers ignore it.
   */
  private slowLfo(rateHz: number, depth: number, target: AudioParam): AudioParam | null {
    const ctx = this.ctx;
    if (ctx === null) return null;
    const lfo = ctx.createOscillator();
    lfo.frequency.value = rateHz;
    const g = ctx.createGain();
    g.gain.value = depth;
    lfo.connect(g).connect(target);
    lfo.start();
    this.bedNodes.push(lfo);
    return g.gain;
  }

  /** The held ring voice, started silent and never stopped. */
  private startRingVoice(): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const gain = ctx.createGain();
    gain.gain.value = 0;
    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 2200;
    gain.connect(filter);
    // The one held voice gets a panner it keeps, so the shimmer comes from the ring the
    // player is actually working rather than from the middle of the head. It is the
    // only place in the game where the stereo position *moves*, and it moves at the
    // speed the ring approaches, which is slow enough to read as parallax.
    if (typeof ctx.createStereoPanner === 'function') {
      const panner = ctx.createStereoPanner();
      this.ringPan = panner.pan;
      filter.connect(panner);
      this.connectTrack(panner, 'objectives', 1);
    } else {
      this.connectTrack(filter, 'objectives', 1);
    }
    const a = ctx.createOscillator();
    a.type = 'sine';
    a.frequency.value = ROOT_HZ * 8;
    const b = ctx.createOscillator();
    b.type = 'sine';
    b.frequency.value = ROOT_HZ * 12;
    b.detune.value = 4;
    a.connect(gain);
    b.connect(gain);
    a.start();
    b.start();
    this.ringOsc = a;
    this.ringOsc2 = b;
    this.ringGain = gain;
    this.bedNodes.push(a, b);
  }

  private now(): number {
    return this.ctx?.currentTime ?? 0;
  }

  /**
   * Connects one voice to a mixer track. Dry and reverberated signals pass through
   * paired gains; a tail already accumulated in the shared room decays naturally.
   *
   * `pan` is -1..1 and applies to the dry signal only. The wet send stays centred on
   * purpose: a reverb tail that follows its source around the stereo field is a room
   * that moves, and the whole point of one convolver for the entire game is that there
   * is a single fixed room everything happens inside. Panning the dry and centring the
   * tail is also, conveniently, how distance actually sounds.
   */
  private connectTrack(source: AudioNode, track: AudioTrackKey, wet = 0, pan = 0): void {
    const ctx = this.ctx;
    const route = this.tracks[track];
    if (route === undefined) return;
    // One integer, on the path every voice in the game takes. See `voicesPlayed`.
    this.voices++;
    // Slowblue: every sound in the game used to arrive at the exact centre of the head,
    // which is the one thing no sound in a body of water ever does. A stroke now comes
    // from where the finger is, a bell from somewhere in the room, and the hush from
    // alternating sides. One node per voice, and it is the single largest change in how
    // close the game sounds. No `StereoPannerNode` (old WebKit) means mono, which is a
    // degradation rather than a failure.
    let dry: AudioNode = route.dry;
    if (ctx !== null && Math.abs(pan) >= 0.02 && typeof ctx.createStereoPanner === 'function') {
      const panner = ctx.createStereoPanner();
      panner.pan.value = Math.max(-1, Math.min(1, pan));
      panner.connect(route.dry);
      dry = panner;
    }
    source.connect(dry);
    if (wet <= 0 || ctx === null) return;
    const send = ctx.createGain();
    send.gain.value = wet;
    source.connect(send).connect(route.wet);
  }

  /**
   * One decaying voice. `attack` is never allowed below 40 ms, which is the single
   * change that makes the whole game sound soft rather than snappy.
   */
  private tone(
    track: AudioTrackKey,
    hz: number,
    duration: number,
    gain: number,
    type: OscillatorType = 'sine',
    delay = 0,
    glideTo = 0,
    attack = 0.05,
    wet = 0.6,
    pan = 0,
  ): void {
    const ctx = this.ctx;
    if (ctx === null) return;
    const t = ctx.currentTime + delay;
    const osc = ctx.createOscillator();
    osc.type = type;
    osc.frequency.setValueAtTime(hz, t);
    if (glideTo > 0) osc.frequency.exponentialRampToValueAtTime(glideTo, t + duration);
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(Math.max(0.0002, gain), t + Math.max(0.04, attack));
    g.gain.exponentialRampToValueAtTime(0.0001, t + duration);
    osc.connect(g);
    this.connectTrack(g, track, wet, pan);
    osc.start(t);
    osc.stop(t + duration + 0.1);
  }

  /** One filtered noise swell. Every water sound in the game is one of these. */
  private burst(
    track: AudioTrackKey,
    filterHz: number,
    duration: number,
    gain: number,
    type: BiquadFilterType = 'bandpass',
    q = 1,
    sweepTo = 0,
    wet = 0.5,
    pan = 0,
    delay = 0,
  ): void {
    const ctx = this.ctx;
    if (ctx === null || this.noise === null) return;
    const t = ctx.currentTime + delay;
    const src = ctx.createBufferSource();
    src.buffer = this.noise;
    src.loop = true;
    src.playbackRate.value = 0.8 + Math.random() * 0.4;
    const f = ctx.createBiquadFilter();
    f.type = type;
    f.Q.value = q;
    f.frequency.setValueAtTime(filterHz, t);
    if (sweepTo > 0) f.frequency.exponentialRampToValueAtTime(sweepTo, t + duration);
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    // A third of the sound is its swell: a noise burst with a fast attack is a
    // hiss, and the same burst with a slow one is water moving.
    g.gain.exponentialRampToValueAtTime(Math.max(0.0002, gain), t + duration * 0.35);
    g.gain.exponentialRampToValueAtTime(0.0001, t + duration);
    src.connect(f).connect(g);
    this.connectTrack(g, track, wet, pan);
    src.start(t);
    src.stop(t + duration + 0.1);
  }

  /**
   * A singing bowl: the fundamental, a fifth, and a struck partial two octaves up
   * that dies first. Long enough to still be in the room when the next thing
   * happens, which is what makes the game feel continuous rather than eventful.
   */
  private bowl(
    track: AudioTrackKey,
    degree: number,
    gain = 0.05,
    delay = 0,
    pan = 0,
    octave = 1,
  ): void {
    // The bed's own bell takes the bed's voicing; the cues do not. `surface()`,
    // `circle()` and the rest are authored moments whose register and intervals are
    // the point of them, and an act that quietly moved them an octave would be
    // rewriting the campaign's endings from the mixer. The one cue that *does* move
    // is the ring, which passes its act's own register in as `octave` - see
    // `Rescues.ts`, and note that it is the only caller that passes anything.
    const voicing = track === 'ambience' ? this.bed.bell : bedSpec('deep').bell;
    // How the deep water darkens the bell, and the one number in this engine that
    // was detuning the game rather than colouring it.
    //
    // It used to be `hz * (1 - depth * 0.25)`: a continuous multiplier from 1.0 down
    // to 0.75, which is a fourth. Both *ends* of that are musical - unity and a fourth
    // are both intervals - and everything between them is not. On the trench floor the
    // bell was fine; halfway up the ascent it rang 31 cents flat, and at depth 0.35 it
    // was a full quarter tone off, held for five and a half seconds, underneath a drone
    // that does not move. It reached every bell in the campaign and, through this
    // method, `level`, `surface`, `complete`, `remembrance` and `circle` as well.
    //
    // The intent survives exactly: deeper is lower. It is spent in whole scale steps
    // now instead of in cents, so a descent walks the bell *down the scale* - two steps
    // over the full depth, which is within a few cents of the fourth the old ratio
    // reached at the bottom. `scaleSemi` is what makes it legal to go below the root.
    const hz = degreeHz(
      clampDegree(degree) - Math.round(this.depth * 2),
      voicing.octave * octave,
    );
    // The bed's own tail, normalised against the deep bed's 5.5 s. A longer tail is
    // what puts the next thing that happens inside the same sound as this one.
    const hold = voicing.hold / 5.5;
    // The struck partial is spread a little wider than the fundamental, which is how a
    // real bowl behaves - the high partials are directional and the body is not.
    this.tone(track, hz, 5.5 * hold, gain, 'sine', delay, 0, 0.09, 0.85, pan * 0.6);
    this.tone(
      track,
      hz * 1.5,
      4.2 * hold,
      gain * 0.42,
      'sine',
      delay + 0.02,
      0,
      0.12,
      0.85,
      pan * 0.8,
    );
    // ...and act IV has none at all. A struck partial is the sound of something
    // being *hit*, and §13's bell is a resonance rather than an instrument.
    if (voicing.strike <= 0) return;
    this.tone(
      track,
      hz * 4,
      1.6,
      gain * 0.16 * voicing.strike,
      'sine',
      delay + 0.01,
      0,
      0.05,
      0.9,
      pan,
    );
  }

  private note(
    track: AudioTrackKey,
    degree: number,
    duration: number,
    gain: number,
    delay = 0,
    pan = 0,
  ): void {
    this.tone(
      track,
      degreeHz(clampDegree(degree)),
      duration,
      gain,
      'sine',
      delay,
      0,
      0.06,
      0.7,
      pan,
    );
  }

  // --- game events -------------------------------------------------------

  /**
   * `speed01` is the normalised finger speed, so a flick is brighter than a sweep.
   * `pan` is -1..1, from where on the screen the finger actually is.
   *
   * Slowblue: the stroke is the only sound in the game the player *plays*, so it is where
   * the ASMR pass had the most to gain, and the change is a rule rather than a texture:
   * **a slow stroke gets the silk and a fast one does not.**
   *
   * The low swell underneath is unchanged - the finger is moving water and moving water
   * in the dark is a low sound. What is new is a second, much quieter voice in the
   * 2.6-5.2 kHz band, the register every whispered and brushed sound lives in, whose
   * level goes as `(1 - speed)^2`. It is inaudible on a flick and it is the loudest
   * thing about a stroke drawn slowly across the glass. Nothing about the game's balance
   * changes; the player is simply rewarded for the hand the game wants them to have, by
   * the one channel that can reward it without a number on screen.
   */
  stroke(speed01: number, pan = 0): void {
    if (!this.running || !this.trackAudible('movement')) return;
    const t = this.now();
    // Rate limit: pointermove fires far faster than a swell can decay, and stacking
    // swells is how a hand on the glass turns into a roar.
    if (t - this.lastStroke < 0.16) return;
    this.lastStroke = t;
    const u = Math.max(0, Math.min(1, speed01));
    // What the finger is moving. The one place the player touches the mix sixty
    // times a minute, so it is the one place the medium has to be audible without
    // anyone being told - a hand in thin air cannot sound like a hand in the sea,
    // and in vacuum it must not sound like it is moving anything at all.
    switch (this.bedKey) {
      case 'flight':
      case 'rain': {
        // Higher, shorter and breathier than the water's low swell.
        const hz = 380 + u * 900;
        this.burst('movement', hz, 0.36 + u * 0.18, 0.02 + u * 0.045, 'bandpass', 0.6, hz * 0.55, 0.5, pan * 0.5);
        break;
      }
      case 'thin': {
        // Thinner again, and narrow: at 25 km there is barely enough air for a
        // hand to find, so what comes back is a whisper of a band rather than a
        // body of anything.
        const hz = 900 + u * 1600;
        this.burst('movement', hz, 0.5 + u * 0.2, 0.008 + u * 0.02, 'bandpass', 2.4, hz * 0.7, 0.8, pan * 0.6);
        break;
      }
      case 'orbit': {
        // Nothing is moved, so nothing answers - except the field the stroke
        // lays, which is not air and does not rush. A single very quiet sine,
        // high, with a long tail: the stroke's *potential*, not its wake.
        //
        // The only stroke in the game with a definite pitch, and it rings for
        // nearly two seconds, so §2's rule applies to it and to none of the other
        // five. It used to slide continuously from 660 to 1100 Hz with the speed of
        // the finger, which is every microtone in a ninth; snapped, the same gesture
        // is a five-note ladder up the pentatonic that the player can hear
        // themselves climbing. Nothing else about the mapping changes - a faster
        // hand is still a higher note.
        this.tone('movement', snapHz(ROOT_HZ * (12 + u * 8)), 1.6 + u * 0.6, 0.006 + u * 0.008, 'sine', 0, 0, 0.3, 1, pan * 0.7);
        break;
      }
      case 'fire': {
        // Dense, hot air. It answers hardest of anything in the campaign and it
        // answers dark, because everything above a kilohertz here is on fire.
        const hz = 260 + u * 520;
        this.burst('movement', hz, 0.44 + u * 0.2, 0.03 + u * 0.055, 'lowpass', 1.1, hz * 0.45, 0.5, pan * 0.5);
        break;
      }
      case 'brook': {
        // Running water, and the hand is across the top of it: bright, short, and
        // the only stroke in the game with any fizz in it.
        const hz = 520 + u * 900;
        this.burst('movement', hz, 0.3 + u * 0.16, 0.022 + u * 0.04, 'bandpass', 0.9, hz * 1.6, 0.55, pan * 0.5);
        break;
      }
      default: {
        const hz = 180 + u * 420;
        this.burst('movement', hz, 0.5 + u * 0.2, 0.028 + u * 0.05, 'lowpass', 0.7, hz * 0.5, 0.45, pan * 0.5);
      }
    }
    // The silk. Squared, so it falls away fast: the reward is for a hand that is
    // genuinely slow, not for one that is merely not flicking.
    const slow = (1 - u) * (1 - u);
    if (slow < 0.06) return;
    const silk = 2600 + slow * 2600;
    this.burst(
      'movement',
      silk,
      1.1 + slow * 0.8,
      0.009 * slow,
      'bandpass',
      0.9,
      silk * 0.55,
      0.85,
      // Wider than the swell it sits over. High content is what the ear localises, so
      // this is the layer that has to be where the finger is.
      pan * 0.95,
    );
  }

  /** `severity` 0 culled, 1 rock, 2 eaten. `pan` is where on screen it happened. */
  loss(severity: number, pan = 0): void {
    if (!this.running || !this.trackAudible('danger')) return;
    const t = this.now();
    if (t - this.lastLoss < 0.07) return;
    this.lastLoss = t;
    if (severity >= 2) {
      this.burst('danger', 150, 0.42, 0.13, 'lowpass', 0.9, 60, 0.7, pan * 0.6);
      this.tone('danger', 82, 0.5, 0.09, 'sine', 0, 0, 0.05, 0.8, pan * 0.4);
    } else if (severity >= 1) {
      this.burst('danger', 240, 0.3, 0.07, 'lowpass', 0.8, 110, 0.6, pan * 0.7);
    } else {
      // A straggler culled off the back. The quietest sound in the game, and now the
      // one that says *where* - which is the whole information it was ever carrying.
      this.burst('danger', 700, 0.24, 0.018, 'bandpass', 1.1, 0, 0.5, pan);
    }
  }

  /** A section cleared. `streak` raises the interval, so a run audibly climbs. */
  gate(streak: number): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    const degree = Math.min(SCALE.length - 2, streak);
    this.note('objectives', degree, 2.4, 0.038);
    this.note('objectives', degree + 2, 1.8, 0.02, 0.09);
  }

  streakBreak(): void {
    if (!this.running || !this.trackAudible('danger')) return;
    this.tone('danger', ROOT_HZ * 3, 1.4, 0.03, 'sine', 0, ROOT_HZ * 2, 0.12, 0.7);
  }

  /**
   * A pod joining you: the game's one reward, in the act's own material.
   *
   * This used to be four lines with act I's numbers in them, played in all
   * forty-two stations - two notes, a bright band opening upward, and that is a
   * shoal of fish being let out into forty metres of water. It played unchanged in
   * vacuum and in a plasma sheath.
   *
   * What is here now is the same gesture read out of `Rescues.ts`, and the second
   * half of it is the part that matters: **the act's own grain voice, converging.**
   * Six wingbeats in the air, nine raindrops in the rain, ten small bubbles in the
   * brook, five flakes of marine snow on the way home - dealt from the full width
   * of the stereo field and collapsing onto the ring. Everything else in this
   * engine that plays a handful of grains at once spreads them *outward*, because
   * that is what something coming apart does; this is the one place they come
   * together, and a field closing is the most legible way a mix can say "this is
   * one thing now".
   *
   * Act IV has no grains and no band at all. §13 leaves breath, heartbeat and a
   * fine internal resonance up there, and a burst of noise announcing a rescue
   * would be the loudest lie in the campaign.
   */
  rescue(count: number, pan = 0): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    const voice = rescueVoice(this.bedKey);
    const size = Math.min(1, count / 18);
    for (const note of voice.notes) {
      // The third note is the size of the pod: a big rescue gets the interval on
      // top of it, a small one does not. Act I's rule, kept everywhere.
      if (note.big === true && size <= 0.6) continue;
      this.rescueNote(note, voice, pan);
    }
    if (voice.band !== null) this.rescueBand(voice.band, pan);
    this.rescueGrains(voice.grains, pan);
  }

  /**
   * A dashed ring held. The warmest sound in the game, and the only full chord.
   *
   * Fires on the same frame as `rescue` - a required pod is a rescue *and* a ring -
   * so the two are one sound and the table voices them together. The three bowls
   * are spread across the ring's own position rather than stacked at the centre, so
   * an arpeggio that used to arrive as one block opens outward from where the
   * player is holding their fish.
   *
   * In act IV they are not bowls. A struck partial is the sound of something being
   * *hit*, and nothing up there can be hit, so its ring is three pure tones
   * entering seconds apart with second-long swells and no onset anywhere.
   */
  ring(pan = 0): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    const voice = rescueVoice(this.bedKey);
    for (const note of voice.ring.notes) {
      if (voice.ring.struck) {
        this.bowl('objectives', note.degree, note.gain, note.delay, pan * note.pan, voice.octave);
      } else {
        this.rescueNote(note, voice, pan);
      }
    }
    if (voice.ring.band !== null) this.rescueBand(voice.ring.band, pan);
  }

  /** One note of a rescue, in the act's own register. */
  private rescueNote(note: RescueNote, voice: RescueVoice, pan: number): void {
    this.tone(
      'objectives',
      degreeHz(clampDegree(note.degree), voice.octave),
      note.duration,
      note.gain,
      'sine',
      note.delay,
      0,
      voice.attack,
      voice.wet,
      pan * note.pan,
    );
  }

  /**
   * The swell under a rescue, and the one number in it worth naming: `to`.
   *
   * Six of the eight beds sweep it *upward*, which is the sound of something
   * opening. Act VI's falls, because rain does not open, it lands - and act VII's
   * falls furthest, because that act's whole subject is letting things settle.
   */
  private rescueBand(band: RescueBand, pan: number): void {
    this.burst(
      'objectives',
      band.hz,
      band.duration,
      band.gain,
      'bandpass',
      band.q,
      band.to,
      band.wet,
      pan * band.pan,
    );
  }

  /** The act's own material, arriving from the edges and finishing on the ring. */
  private rescueGrains(grains: RescueGrains | null, pan: number): void {
    if (grains === null || grains.voice === null) return;
    for (let i = 0; i < grains.count; i++) {
      const at = grainPan(i, grains.count, grains.spread, pan);
      // Front-loaded: the outermost grains set off first, so they all land together.
      const delay = (i / Math.max(1, grains.count - 1)) * grains.span;
      switch (grains.voice) {
        case 'bubble':
          this.bubble(bubbleRadius(Math.random(), this.depth), at, grains.gain, delay, 'objectives');
          break;
        case 'wing':
          this.wing(wingSpan(Math.random(), this.altitude), at, grains.gain, delay, 'objectives');
          break;
        case 'crystal':
          this.crystal(crystalSize(Math.random(), this.altitude), at, grains.gain, delay, 'objectives');
          break;
        case 'drop':
          this.drop(dropRadius(Math.random(), 1), at, grains.gain, delay, 'objectives');
          break;
        case 'riffle':
          this.riffle(riffleRadius(Math.random(), this.flow), at, grains.gain, delay, 'objectives');
          break;
        case 'flake':
          this.snowflake('objectives', at, grains.gain, delay);
          break;
        case 'spark':
          this.sparkGrain('objectives', at, grains.gain, delay);
          break;
      }
    }
  }

  /** ...and one left behind. Low, slow, and it takes the room down with it. */
  ringLost(): void {
    if (!this.running || !this.trackAudible('danger')) return;
    this.tone('danger', ROOT_HZ * 2, 3.4, 0.075, 'sine', 0, ROOT_HZ * 0.75, 0.2, 0.9);
    this.tone('danger', ROOT_HZ * 3, 2.6, 0.04, 'sine', 0.1, ROOT_HZ, 0.24, 0.9);
    this.burst('danger', 420, 2.6, 0.05, 'lowpass', 0.6, 70, 0.8);
  }

  reform(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    for (let i = 0; i < 4; i++) this.note('objectives', i * 2, 2.2, 0.028, i * 0.1);
    this.burst('objectives', 600, 1.6, 0.022, 'bandpass', 0.7, 1800, 0.8);
  }

  /** A hunter took one. Distinct from a rock: lower, wetter, and it lands late. */
  bite(pan = 0): void {
    if (!this.running || !this.trackAudible('danger')) return;
    // Filtered noise and a sine, not a sawtooth. A hunter is still the ugliest
    // sound in the game; it is no longer the loudest, and it no longer buzzes.
    this.burst('danger', 320, 0.5, 0.1, 'lowpass', 3.5, 90, 0.5, pan * 0.8);
    // A2 falling to A1. It used to fall to 52 Hz, which is 97 cents below A1 and
    // therefore a G# - the leading tone, the single interval `Scale.ts` exists to
    // keep out of the game, arriving on the one cue the player least wants to hear
    // resolve. 52 was a rounded number rather than a chosen one; the gesture it was
    // reaching for is an octave, and an octave is what it does now.
    this.tone('danger', ROOT_HZ * 2, 0.6, 0.07, 'triangle', 0, ROOT_HZ, 0.04, 0.6, pan * 0.5);
  }

  /** A new level. A swell that arrives under the banner and leaves after it. */
  level(index: number): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    this.bowl('objectives', Math.min(6, index), 0.05);
    this.tone('objectives', ROOT_HZ * 2, 6, 0.045, 'sine', 0, 0, 1.4, 0.9);
    this.burst('objectives', 200, 5, 0.035, 'lowpass', 0.5, 900, 0.9);
  }

  /**
   * The station begins again: the same water, from the line it was entered on.
   *
   * The one event in `SimEventType` that reached the end of act VI with nothing
   * on either channel answering it (`e2e/response.spec.ts`), and it is not a
   * small one - it is what a failure *is* in acts III to VI, thirty of the
   * campaign's forty-two stations. A silent one reads as the game having lost
   * its place.
   *
   * Three things keep it from being a failure sting. It descends onto the root
   * rather than away from it, which is a settle and not an alarm. It is voiced in
   * sines rather than in bowls, because a bowl is a struck partial and nothing
   * here is struck - the water simply takes the shoal back. And it is on the
   * objectives track rather than danger, so a player who has turned the hunters
   * down still hears which water they are in; the mixer is the one place this
   * cue must not be able to go missing.
   */
  restart(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    this.note('objectives', 4, 2.2, 0.03);
    this.note('objectives', 2, 2.6, 0.026, 0.26);
    this.note('objectives', 0, 3.4, 0.022, 0.58);
    // The room closing for a moment underneath, and opening again with the swell.
    // Noise, so §2's tuning rule has nothing to say about it.
    this.burst('objectives', 300, 2.2, 0.03, 'lowpass', 0.6, 80, 0.75);
    this.tone('objectives', ROOT_HZ * 2, 5, 0.028, 'sine', 0.1, 0, 1.3, 0.9);
  }

  /** The campaign flown to its end. */
  complete(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    for (let i = 0; i < 5; i++) {
      this.bowl('objectives', i + 2, 0.05 - i * 0.005, i * 0.55);
    }
    this.tone('objectives', ROOT_HZ * 2, 9, 0.05, 'sine', 0, 0, 2, 1);
  }

  /**
   * The breach: the frame the shoal actually leaves the water.
   *
   * Every other sound in the game is filtered *down*, because everything else in the
   * game happens under forty metres of ocean. This is the one sound allowed to open
   * upward - a swell whose filter sweeps from 260 Hz to 2.6 kHz, which is what
   * surfacing sounds like - and the highest interval the scale contains. It is the only
   * time Slowblue resolves anything.
   */
  surface(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    this.burst('objectives', 260, 2.8, 0.055, 'lowpass', 0.7, 2600, 0.9);
    this.bowl('objectives', 7, 0.05);
    this.bowl('objectives', 9, 0.038, 0.24);
    this.tone('objectives', ROOT_HZ * 8, 5.5, 0.022, 'sine', 0.35, 0, 1.4, 1);
  }

  /**
   * The top of the air: act II's ending cue, and the counterpart to `surface()`
   * rather than its opposite.
   *
   * It used to be written as pure subtraction - the tropopause as the medium
   * giving out, so the sound gave out with it - and that was correct about the
   * physics and wrong about the moment. What is actually on screen here is the
   * sun clearing the limb of the Earth (`Release.ts`, movement 4): the light
   * comes *back*. So the cue is the widest and quietest thing the engine can
   * make. A low open fifth that swells over four seconds under everything -
   * the only sustained low note in the game that is not the bed - then four
   * bowls climbing an octave and a half with tails long enough to overlap into
   * one chord, and a very high sine left hanging where the last one lands.
   *
   * The wingbeat stream is still damped underneath it (`releaseQuiet`), because
   * the flock genuinely has stopped flying; what fills the space it leaves is
   * the room, not another event. Cued at the sunrise, not at the cleared
   * section.
   */
  release(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    this.releaseQuiet = 12;
    // The swell: no attack anyone can locate, a long way under everything else.
    this.tone('objectives', ROOT_HZ, 9, 0.03, 'sine', 0, 0, 4, 0.6);
    this.tone('objectives', ROOT_HZ * 1.5, 9, 0.022, 'sine', 0.4, 0, 4.2, 0.6);
    this.bowl('objectives', 5, 0.042, 0.9, -0.4);
    this.bowl('objectives', 7, 0.04, 1.9, 0.3);
    this.bowl('objectives', 9, 0.034, 2.9, -0.2);
    this.bowl('objectives', 12, 0.028, 3.9, 0.4);
    // One breath of air moving over the whole thing, opening rather than closing.
    this.burst('objectives', 900, 6.5, 0.016, 'bandpass', 0.6, 3400, 1);
    this.tone('objectives', ROOT_HZ * 12, 9, 0.012, 'sine', 4.4, 0, 2.6, 1);
  }

  /**
   * The camera turn: act IV's ending cue, and the quietest event in the game.
   *
   * §13 is explicit that in space there is no conventional external sound - only
   * breath, heartbeat and a very fine internal resonance - and this is the moment
   * that rule exists for. So there is no bowl, no burst and no noise of any kind
   * here: three of the four voices are above 1 kHz, they are *sine* partials
   * rather than struck bodies, and the loudest of them is a third of a bowl. What
   * the player hears is closer to the ringing you notice in a silent room than to
   * an instrument, which is the correct sound for a picture whose subject is that
   * everything is very far away.
   *
   * The one low voice is not a note. It is a fifth under everything, so quiet it
   * is felt rather than placed, and it is what keeps four high sines from reading
   * as a chime. Cued at the closed disc, not at the cleared section.
   */
  overview(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    // Below the picture: two octaves down, no attack anybody can locate.
    this.tone('objectives', ROOT_HZ * 0.5, 14, 0.02, 'sine', 0, 0, 5.5, 0.5);
    // The resonance. A perfect fifth and its octave, entering a long way apart
    // and holding past the end of the film, panned wide because a sound with no
    // source is the only kind space has.
    this.tone('objectives', ROOT_HZ * 16, 11, 0.014, 'sine', 0.6, 0, 3.4, 1, -0.5);
    this.tone('objectives', ROOT_HZ * 24, 10, 0.011, 'sine', 2.4, 0, 3.8, 1, 0.5);
    this.tone('objectives', ROOT_HZ * 32, 9, 0.007, 'sine', 4.2, 0, 4.2, 1, -0.2);
  }

  /**
   * The Karman line: act III's ending cue, and the only one in the game that is
   * a subtraction.
   *
   * `render/Karman.ts` is a film about an absence - a stroke is drawn and the
   * world does not answer it - and a cue that *arrives* would contradict the
   * picture it is on. So this is the wind going out: one band of noise sweeping
   * downward and closing, and nothing after it except the two things §13 says
   * are all that is left up there. The high sine is deliberately the same
   * partial `overview()` opens on, three acts early and a great deal quieter,
   * so the sound of space is something the player has heard before by the time
   * the camera turns.
   */
  airless(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    // The last of the air, leaving. A band that both falls and narrows, which is
    // what a medium running out actually does to anything moving through it.
    this.burst('objectives', 900, 5.5, 0.03, 'bandpass', 1.4, 90, 0.7);
    // ...and then nothing but the room. One fifth, very low, felt rather than
    // placed, and one partial left ringing where the air used to be.
    this.tone('objectives', ROOT_HZ * 0.75, 11, 0.016, 'sine', 1.6, 0, 4.5, 0.5);
    this.tone('objectives', ROOT_HZ * 16, 8, 0.01, 'sine', 3.2, 0, 3.2, 1, 0.3);
  }

  /**
   * The nucleus: act V's ending cue, and the campaign's loudest sound cooling.
   *
   * Act V is the one place §13 allows to be loud, and the film is that permission
   * being withdrawn: the plasma goes out and what is left is water. So the cue is
   * a long low roll that loses its top end - the same downward filter sweep the
   * re-entry bed is built on, run out to eight seconds - crossed near the end by
   * the first two bowls since the anvil. They are struck low and wet, because
   * what they are announcing is a cloud.
   */
  nucleus(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    // The fire, going out. Loud by this game's standards and gone by the fourth
    // second, which is exactly how long the grains take to stop burning.
    this.burst('objectives', 1600, 4.2, 0.05, 'lowpass', 0.8, 120, 0.85);
    this.tone('objectives', ROOT_HZ, 8, 0.026, 'sine', 0, ROOT_HZ * 0.6, 1.2, 0.7);
    // Water. Two bowls a fourth apart, arriving as the last of the heat leaves.
    this.bowl('objectives', 3, 0.04, 4.6);
    this.bowl('objectives', 5, 0.034, 6.2, 0.3);
  }

  /**
   * The estuary: act VI's ending cue, and the first bubble voice since act I.
   *
   * §13's arc is `... rain -> river -> bubble`, and this is where the river
   * becomes the bubble. The stream is still running underneath - one wide band
   * of moving water that never quite stops - and over it the game's own rescue
   * interval comes back for the first time in five acts, because what is
   * happening on screen is life being taken up again.
   */
  estuary(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    // The river, widening: the filter opens rather than closes, which is the
    // opposite of every other water sound in the game and is what a mouth is.
    this.burst('objectives', 240, 6, 0.038, 'bandpass', 0.7, 1200, 0.8);
    // The salt arriving underneath it.
    this.tone('objectives', ROOT_HZ * 1.5, 7.5, 0.024, 'sine', 0.8, 0, 2.6, 0.6);
    // ...and the gold moving by itself. Three bowls climbing, quick and small -
    // this is the only cue in the second half of the campaign that hurries.
    this.bowl('objectives', 5, 0.036, 2.8, -0.3);
    this.bowl('objectives', 7, 0.034, 3.4, 0.2);
    this.bowl('objectives', 10, 0.03, 4, -0.1);
  }

  /**
   * The journey, told back: act VII's third movement, and the only cue in the game
   * made out of other cues.
   *
   * `render/Circle.ts`'s `remember` is the settled gold, at rest on the trench
   * floor and now the only light in the picture, playing the whole circuit back
   * over the dark water: six echoes rising and dissolving in sequence, one per act,
   * each of them a single gesture lifted from that act's own ending film. The
   * picture quotes their *geometry* and repaints it in the trench's violet. This
   * quotes their *sound* and repaints it at a whisper - every voice below is taken
   * from the method named beside it, at a third of its gain or less, so the
   * recapitulation sits under the room rather than in it.
   *
   * Two things put each voice where its echo is. It arrives just under the echo's
   * visual peak, which crests about `0.7 + i` seconds into the movement; and the
   * pan walks left to right across the six, because the echoes are laid out along
   * the arc of the circuit and the sound should cross the frame with them.
   *
   * **Act VII gets no voice, and that is the whole point of the movement.** The
   * seventh memory is the room the player is sitting in - the `homecoming` bed,
   * still playing underneath this, with its lowest pad voice already walking down
   * to 27.5 Hz (`updateResolve`). So nothing is struck in the last second of the
   * movement, and what is still sounding there is nothing but tails coming apart
   * into the bed - which is as near as an instrument that rings for five seconds
   * gets to the silence the picture holds. By the time the first fish arrives the
   * room is all there is, and it is `circle()` that arrives into it.
   *
   * This is a movement inside an ending rather than an ending, so it is **not in
   * `ENDING_SOUNDS`** - that list is the seven acts' final cues, asserted by name
   * and order in `tests/admin.test.ts`, and it gains no entry for this.
   */
  remembrance(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    // I - the breach (`surface`). The one filter in the game that opens upward, and
    // the only reason to spend the first echo on a band of noise: a player who has
    // heard act I's ending recognises this before they can say what it is. Run out
    // short and stopped well below the breach's 2.6 kHz - it is remembered from the
    // bottom of the sea, and nothing down here gets that bright.
    this.burst('objectives', 260, 1.7, 0.017, 'lowpass', 0.7, 1400, 0.9, -0.6, 0.11);
    // II - the top of the air (`release`). Two of its four climbing bowls, in its
    // own order, with the seventh between them kept and the four seconds taken
    // out. The climb is what act II's ending *is*; the patience is not quotable in
    // one second, so it is the interval that has to carry the memory.
    this.bowl('objectives', 5, 0.013, 1.4, -0.36);
    this.bowl('objectives', 9, 0.01, 1.72, -0.3);
    // III - the Karman line (`airless`). One partial at 880 Hz and nothing beside
    // it. That cue is the only subtraction in the game and this is the note it
    // leaves behind - the same one `overview()` opens on an act later - so a sweep
    // here would be act III with the air still in it. Its echo on screen is the one
    // that does not move, in `still` or out of it, and this is that.
    this.tone('objectives', ROOT_HZ * 16, 4.4, 0.0033, 'sine', 2.25, 0, 0.45, 1, -0.12);
    // IV - the camera turn (`overview`). The apogee of the sequence, and the echo
    // that holds longest, so these are the two longest voices in the cue: the top
    // and the bottom of that stack, and nothing in between them, which is what a
    // picture of everything being very far away sounds like.
    this.tone('objectives', ROOT_HZ * 32, 5.6, 0.0023, 'sine', 3.3, 0, 0.45, 1, 0.12);
    // ...and its floor an octave up from where `overview()` puts it. That cue's low
    // voice sits at 27.5 Hz, and 27.5 Hz is exactly where act VII's pad has walked
    // its own root by the time this film plays: doubling a note that has been held
    // for minutes is a slow beat, not a memory. 55 Hz is the octave the pad has
    // just vacated, it stays empty for the length of the film, and a voice that low
    // has no location anyway - which is why `overview()` never pans it and this
    // does not either.
    this.tone('objectives', ROOT_HZ, 6.6, 0.0066, 'sine', 3.1, 0, 0.6, 0.5);
    // V - the nucleus. The downward sweep that is act V's ending, run out to two
    // seconds, and the first of the two bowls that arrive as the last of the heat
    // leaves. On screen this echo is a streak whose tail shortens as it falls until
    // it is a single point of gold sinking into the bed it became; the sweep and
    // the bowl after it are the same sentence.
    this.burst('objectives', 1600, 2.1, 0.016, 'lowpass', 0.8, 120, 0.85, 0.36, 3.96);
    this.bowl('objectives', 3, 0.012, 4.85, 0.42);
    // VI - the estuary. Its three bowls are the only cue in the second half of the
    // campaign that hurries, and heard from six thousand metres further down they
    // hurry more and carry less: the gaps close to a fifth of a second and the
    // gains go under the third this cue allows itself. They are also the last thing
    // struck in the movement, on purpose - everything after them is the room.
    this.bowl('objectives', 5, 0.01, 5.2, 0.5);
    this.bowl('objectives', 7, 0.009, 5.38, 0.66);
    this.bowl('objectives', 10, 0.008, 5.56, 0.56);
  }

  /**
   * The circle closing: act VII's ending, and the last sound in the campaign.
   *
   * It is `surface()` with the resolution taken out of it, and that is the whole
   * design. Act I's ending is the one moment Slowblue resolves anything - a filter
   * opening upward, the highest interval in the scale - and this is the same
   * gesture arriving at the bottom of the sea instead of the top: the same
   * intervals, struck in the same order, filtered *down* rather than up, and
   * ending on the root rather than above it. A player who has heard the first
   * one will not be able to say why the last one is familiar.
   *
   * There is nothing below that root, and it is a decision rather than a gap. The
   * obvious way to make an ending bigger is a voice an octave under it - but act
   * VII's bed has spent the act's last third walking its own lowest pad voice down
   * to 27.5 Hz (`updateResolve`), so that octave is already occupied, by a detuned
   * oscillator that has been holding for minutes. Two sines four cents apart at
   * 27.5 Hz beat once every sixteen seconds, and this cue's root rings for
   * fourteen: the campaign would end on a single slow throb, on the one note it
   * spent seven acts earning the right to land on. The cue plays the root in two
   * octaves, the bed is holding the third underneath it, and the room is three
   * octaves deep without anything being added here.
   */
  circle(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    // Down, not up. The mirror of the breach's 260 Hz -> 2.6 kHz sweep.
    this.burst('objectives', 2200, 5.5, 0.03, 'lowpass', 0.6, 180, 0.9);
    // The breach's two bowls, in the same order, an octave lower and slower.
    this.bowl('objectives', 4, 0.046, 0.4);
    this.bowl('objectives', 6, 0.04, 1.6, -0.2);
    // ...and it comes to rest on the root. Nothing in this game has ever done
    // that, because nothing in it had finished before.
    this.tone('objectives', ROOT_HZ * 2, 12, 0.03, 'sine', 3, 0, 4.5, 0.8);
    this.tone('objectives', ROOT_HZ, 14, 0.022, 'sine', 3.4, 0, 5, 0.6);
  }

  /**
   * The light put down: act VII's sixth movement, and the last thing the campaign
   * strikes.
   *
   * `render/Circle.ts`'s `vigil` is the shoal already one body and the carried
   * light being set down - the bed glow dimming on three smoothsteps about 0.6,
   * 1.6 and 2.6 seconds into the movement, with nothing moving between them but
   * the breath. Three bowls, struck on those three frames and stepping *down* to
   * the root: the audible form of putting something heavy down in three legs
   * rather than dropping it. Everything the movement does for its first seconds is
   * these three strikes, and that is the point of it.
   *
   * What is holding underneath by then is `circle()`'s last two voices and nothing
   * else - its burst and both its bowls are long gone - so the descent is chosen
   * against a bare root drone: 110 Hz and 55 Hz, five seconds into tails that run
   * to the handover and past it. It opens on degree 6, which is the pitch
   * `circle()` itself last struck, so the first step picks the light up exactly
   * where the cue put it down; it passes through the fifth; and it lands on degree
   * 0, which adds no note to the room at all - the last bowl in Slowblue confirms the
   * one that is already in it. Read as intervals - a minor third above the octave,
   * a fifth, a root - the three strikes are a minor triad falling onto its own
   * root, which is the nearest thing to a cadence a scale with no leading tone in
   * it can make, and act VII is the one place in the game worth spending it.
   * `bowl()`'s depth darkening scales the whole set together, so the shape holds
   * wherever in the trench the film is played from.
   *
   * It is a diminuendo, which looks backwards for an arrival and is not. The
   * picture loses light on every one of these strikes; and what is being arrived
   * at here is not the note but the silence the note is set down into, so the root
   * is the quietest bowl in the cue. All three are struck in the same place, a
   * little off centre: this is one gesture repeated, not three events.
   *
   * A movement inside an ending rather than an ending, so it is **not in
   * `ENDING_SOUNDS`** - see `remembrance()`, which is not in it for the same
   * reason.
   */
  vigil(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    // The first leg: the pitch `circle()` last struck, picked back up.
    this.bowl('objectives', 6, 0.03, 0.6, -0.12);
    // The second: the fifth, and the only step that is neither where the light was
    // nor where it is going.
    this.bowl('objectives', 3, 0.024, 1.6, -0.12);
    // ...and down onto the root, quietest of the three, where the cue already is.
    this.bowl('objectives', 0, 0.019, 2.6, -0.12);
  }

  /** Kept for the old zone signal; the campaign uses `level` instead. */
  zone(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    this.tone('objectives', ROOT_HZ * 2, 4, 0.04, 'sine', 0, 0, 1.2, 0.9);
  }

  fail(): void {
    if (!this.running || !this.trackAudible('danger')) return;
    this.setRingHold(0, 0);
    this.tone('danger', ROOT_HZ * 2, 4.5, 0.07, 'sine', 0, ROOT_HZ * 0.7, 0.3, 0.95);
    this.burst('danger', 400, 3.5, 0.055, 'lowpass', 0.6, 60, 0.8);
  }

  record(): void {
    if (!this.running || !this.trackAudible('objectives')) return;
    for (let i = 0; i < 4; i++) this.bowl('objectives', i + 3, 0.04, i * 0.4);
  }

  /**
   * The bed's own voices, one at a time.
   *
   * Every *event* in the engine is already a public method, because something in the
   * game fires it. The bed is the opposite: bubbles, wings, the whale and the bell are
   * scheduled from `tick` on their own Poisson clocks, which is exactly right for a
   * room and useless for hearing what one of them actually sounds like - a whale is
   * once or twice a minute by design. This is the one door into them, it plays them
   * with the same parameters the scheduler would (so what you hear is what ships, at
   * the current depth and altitude), and nothing in the game calls it.
   */
  preview(voice: PreviewVoice): void {
    if (!this.running) return;
    switch (voice) {
      case 'bubble':
        this.bubble(bubbleRadius(Math.random(), this.depth), 0, BUBBLE_GAIN);
        break;
      case 'gurgle':
        this.gurgle((Math.random() * 2 - 1) * 0.75, BUBBLE_GAIN);
        break;
      case 'hush':
        this.hush();
        break;
      case 'wing':
        this.wing(wingSpan(Math.random(), this.altitude), 0, WING_GAIN);
        break;
      case 'flock':
        this.beats((Math.random() * 2 - 1) * 0.8, WING_GAIN);
        break;
      case 'gust':
        this.gust((Math.random() * 2 - 1) * 0.85);
        break;
      case 'thunder':
        this.thunder();
        break;
      case 'whale':
        for (const call of whalePhrase(Math.random, this.depth)) {
          this.whaleCall(call, WHALE_GAIN);
        }
        break;
      case 'bowl':
        this.bowlDegree = Math.max(0, Math.min(6, this.bowlDegree + (Math.random() < 0.5 ? -1 : 1)));
        this.bowl('ambience', this.bowlDegree, 0.05 - this.depth * 0.015);
        break;
      case 'crystal':
        this.crystal(crystalSize(Math.random(), this.altitude), (Math.random() * 2 - 1) * 0.85, CRYSTAL_GAIN);
        break;
      case 'shear':
        this.shear();
        break;
      case 'infrasound':
        this.infrasound();
        break;
      case 'heart':
        this.heart();
        break;
      case 'whistler':
        for (const w of whistlerShower(Math.random)) this.whistler(w);
        break;
      case 'spark':
        this.sparkGrain();
        break;
      case 'shock':
        this.shock();
        break;
      case 'drop':
        this.drop(dropRadius(Math.random(), sheetAt(this.clock)), (Math.random() * 2 - 1) * 0.85, DROP_GAIN);
        break;
      case 'patter':
        this.patter();
        break;
      case 'riffle':
        this.riffle(riffleRadius(Math.random(), this.flow), (Math.random() * 2 - 1) * 0.8, RIFFLE_GAIN);
        break;
      case 'stone':
        this.stone();
        break;
      case 'flake':
        this.snowflake();
        break;
    }
  }

  ui(bright = true): void {
    if (!this.running || !this.trackAudible('interface')) return;
    this.tone(
      'interface',
      ROOT_HZ * (bright ? 8 : 6),
      0.7,
      0.025,
      'sine',
      0,
      0,
      0.04,
      0.5,
    );
  }

  dispose(): void {
    this.keepAlive.dispose();
    for (const n of this.bedNodes) {
      try {
        n.stop();
      } catch {
        /* already stopped */
      }
    }
    this.bedNodes = [];
    this.ringOsc = null;
    this.ringOsc2 = null;
    this.ringGain = null;
    this.ringPan = null;
    this.padFilterParam = null;
    this.padGain = null;
    this.padVoices = [];
    this.shimmerGain = null;
    this.shimmerFreq = null;
    this.shimmerQ = null;
    this.shimmerRate = null;
    this.shimmerLfoDepth = null;
    this.shimmerSweepDepth = null;
    this.breathBody = null;
    this.breathAir = null;
    this.sheath = null;
    void this.ctx?.close().catch(() => undefined);
    this.ctx = null;
    this.tracks = {};
  }
}
