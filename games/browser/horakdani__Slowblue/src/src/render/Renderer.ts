import { LEVELS, levelAtIn, type Level } from '../config/levels';
import { TAU, clamp, lerp } from '../core/math';
import { Rng } from '../core/rng';
import { MAIN_FACTION } from '../sim/Agent';
import { MAX_AGENTS } from '../sim/SwarmSimulation';
import type { Blob } from '../sim/ObstacleSystem';
import { CORE as POTENTIAL_CORE } from '../sim/PotentialField';
import type { SimEvent, World } from '../sim/World';
import { drawBackdrop } from './Backdrop';
import { BANNER_LIFE, drawBanner } from './Banner';
import { carrierFor, isParticle, traceCarrier } from './Carriers';
import type { CarrierKind } from '../config/levels';
import { Decor } from './Decor';
import { SPECIES, speciesAt, traceFish } from './FishShapes';
import { BEARING, BIRDS, beatAmount, beatPhase, birdAt, steerBearing, traceBird } from './Flock';
import { drawEmber, drawEmberThreat } from './Ember';
import { drawHunter, drawThreat } from './Hunter';
import { drawRaptor, drawRaptorThreat } from './Raptor';
import { type Plane, type StrataView, drawStrata, hasStrata } from './Strata';
import {
  MOTIFS,
  isSoft,
  motifFor,
  motifForIn,
  motifForSection,
  motifsForAct,
  type Motif,
} from './Motif';
import {
  blendPaint,
  brighten,
  clonePaint,
  css,
  mix,
  paintFor,
  rgba,
  temper,
  type Rgb,
  type ZonePaint,
} from './Paint';
import { Circle } from './Circle';
import { Estuary } from './Estuary';
import { Karman } from './Karman';
import { Nucleus } from './Nucleus';
import { Overview } from './Overview';
import { filmForAct, type Film, type FilmKind } from './Films';
import { Release } from './Release';
import { paintStone } from './RockPaint';
import { invalidateStoneMasses, stoneMasses } from './Stone';
import { Surfacing } from './Surfacing';
import { drawWhirl } from './Whirl';
import type { PredatorForm } from '../sim/PredatorSystem';

/**
 * What the thing hunting you *is*, and the only branch the renderer takes on it.
 *
 * This was `medium.kind === 'air' ? raptor : shark` in two places, which held
 * for exactly as long as the campaign had two threats and every act had one
 * medium. Act V has three media inside one act - `World.medium` blends them, and
 * the blend's `kind` flips halfway across a station - so the medium test would
 * have swapped the animal mid-chase. The silhouette is a property of the
 * predator now, written by the level author and carried from the spawn.
 *
 * Nothing is shared between the three but the position they are drawn at. See
 * `Hunter.ts`, `Raptor.ts` and `Ember.ts`, each of which opens by saying why it
 * could not have been one of the others with a different colour on it.
 */
const BODY: Record<PredatorForm, typeof drawHunter> = {
  shark: drawHunter,
  raptor: drawRaptor,
  ember: drawEmber,
};

const THREAT: Record<PredatorForm, typeof drawThreat> = {
  shark: drawThreat,
  raptor: drawRaptorThreat,
  ember: drawEmberThreat,
};

/**
 * Base radius of a particle carrier, before its own `size` and the individual's
 * `variation`.
 *
 * Deliberately smaller than a fish is long. A shoal is a hundred *animals* and
 * has to read as such at eleven pixels; a swarm of spores is a hundred specks and
 * reading as specks is the whole job - the moment one of them is big enough to
 * have a shape, the player starts looking at it instead of at the body of them.
 */
const PARTICLE_RADIUS = 3.2;

export interface RenderDebugFlags {
  showField: boolean;
  showHash: boolean;
  showStats: boolean;
}

export interface RenderStyle {
  /**
   * 0.3..1 multiplier on tracer and speck counts, and the atmosphere budget.
   *
   * No longer a setting anyone chose. `main.adaptQuality` moves it at runtime, so
   * unlike everything else in here it can change in the middle of a frame's worth
   * of work - which is why `setStyle` fits the populations instead of reseeding.
   */
  quality: number;
}

/**
 * Trail length per tracer. Long enough that a vortex visibly curls - a short trail
 * is a straight tick, and a field of straight ticks reads as rain, not as water.
 */
const TRAIL = 9;

interface Particle {
  x: number;
  y: number;
  /** Ring buffer of past positions, so a streak shows curvature, not just speed. */
  tx: Float32Array;
  ty: Float32Array;
  head: number;
  filled: number;
  life: number;
  maxLife: number;
  /** Per-tracer brightness, so the field reads as texture rather than as marks. */
  tone: number;
}

interface Speck {
  x: number;
  y: number;
  r: number;
  a: number;
  /** 0 = close to the camera and fast, 1 = far away and slow. */
  depth: number;
}

interface Effect {
  kind: 'loss' | 'rescue' | 'reform' | 'bite' | 'ring' | 'ringLost' | 'restart';
  x: number;
  y: number;
  life: number;
  maxLife: number;
  value: number;
}

const FLOW_PARTICLES = 190;
const SPECKS = 130;
/** Shake decays to a tenth of its value in this many seconds. */
const SHAKE_HALF_LIFE = 0.16;
/**
 * Slowblue: the camera is allowed to flinch, never to shout.
 *
 * The prototype's shake was tuned for an arcade game - 13px on a phone held at
 * arm's length is a jolt, and a jolt is the exact opposite of the thing this
 * version is trying to be. Everything that used to shake still shakes; it does it
 * about a third as hard and settles half a second slower, so an impact reads as
 * the water taking the blow rather than as the screen being hit.
 */
const MAX_SHAKE = 5.5;
/** How far down the screen the "distance haze" reaches. Ahead is up. */
const FOG_HEIGHT = 0.26;

/**
 * Where the right-hand readout column starts, measured down from the top inset.
 *
 * Not a taste number. It is the stylesheet's own arithmetic for the line both
 * corner buttons are clear of - ten of air under the inset, the pause button,
 * eight between, the mixer button, then eight more - and `.ui-mix` is pinned to
 * the same line with the same sum, because a drawer that opened over its own
 * button would be the same defect one layer up. `--reach` is 44.
 *
 * The canvas cannot ask the stylesheet for it, so the two have to agree by
 * hand, and `e2e/chrome.spec.ts` is what checks that they still do.
 */
const HUD_COLUMN_TOP = 10 + 44 + 8 + 44 + 8;

/**
 * How far the progress rail's counter rides above the rail's top end.
 *
 * Named because two places have to agree on it: the counter is drawn this far
 * above `top`, and `top` is floored this far below the column so that the counter
 * lands under it. Written twice as a literal, the floor and the label drift apart
 * the first time either is nudged, and on every screen tall enough to be developed
 * on, the drift is invisible.
 */
const COUNTER_RISE = 14;

/**
 * The row the streak badge owns, measured down from `HUD_COLUMN_TOP`.
 *
 * Its own height at the widest moment it has - `drawStreak` pops the face from
 * 12 px to 16 and settles it back over 0.45 s - plus the same eight of air the
 * column already keeps between itself and the buttons above it.
 *
 * The rail is floored below this rather than below the badge's *live* box, and
 * that is the whole of the decision: the badge comes and goes with the streak,
 * and a rail that dropped 24 px the moment a streak started - and climbed back
 * when it broke - would be a worse thing to look at than the collision it fixes.
 */
const STREAK_ROW = 16 + 8;

/**
 * Slowblue: Canvas2D renderer. Deliberately cheap - no blur filters, no shadowBlur, one
 * path fill per batch. Control latency beats fidelity, so anything that could cost a
 * frame is out; everything that is one more fill of an already-built path is in.
 *
 * The two tricks doing most of the work are additive compositing for anything that
 * emits light (glow, pods, effects) and a small stack of parallax layers behind the
 * water. Neither costs a measurable frame; together they are the difference between
 * "shapes on a gradient" and "something lit, underwater, with distance in it".
 *
 * Everything colour-related comes from the live zone palette rather than a literal,
 * because the palette is how the game says "you are somewhere else now".
 */
export class Renderer {
  private ctx: CanvasRenderingContext2D;
  private dpr = 1;
  private w = 0;
  private h = 0;
  private particles: Particle[] = [];
  private effects: Effect[] = [];
  private specks: Speck[] = [];
  private rng = new Rng(0xc0ffee);
  private sample = { x: 0, y: 0 };
  private insets = { top: 0, bottom: 0, left: 0, right: 0 };
  private paint: ZonePaint = clonePaint(paintFor(0));
  private style: RenderStyle = {
    quality: 1,
  };
  private shake = 0;
  /** Full-screen white flash, 0..1. Used only for a re-form and a record. */
  private flash = 0;
  /** Level banner: seconds of life left, which level it names, and its title. */
  private bannerLife = 0;
  private bannerLevel = 0;
  private bannerFinal = false;
  /** Whether the picture under the banner is daylit. Set once, in `showBanner`. */
  private bannerDark = false;
  /**
   * Every ending in the campaign, in the order the circuit plays them.
   *
   * They are never live at once: `ingest` begins the one belonging to the act
   * that just completed and `syncZone` resets all of them, so "which film is on
   * screen" is a search of seven booleans rather than a field anyone maintains.
   * Each owns its own clock and holds on its own last frame; the title over one
   * waits for its own `settled`, because a heading over a picture the film is
   * still building is a caption on an unfinished sentence.
   *
   * The list is a list rather than seven fields for the reason the admin surface
   * reads `CAMPAIGN_ACTS` rather than a hand-maintained one: the seam between
   * "the film exists" and "the renderer knows about it" is exactly where an
   * ending goes missing, and it went missing once already (see `Films.ts`).
   */
  private readonly films: readonly (readonly [FilmKind, Film])[] = [
    ['surfacing', new Surfacing()],
    ['release', new Release()],
    ['karman', new Karman()],
    ['overview', new Overview()],
    ['nucleus', new Nucleus()],
    ['estuary', new Estuary()],
    ['circle', new Circle()],
  ];
  /** Which act is being drawn. Decides which film a completion starts. */
  private actKey = 'water';
  /**
   * True when finishing this act finishes the *game* rather than handing over.
   *
   * Only the last act of a circuit, and any act opened on its own through the
   * `?act=` door or the admin surface. Without it every completed act raised a
   * MISSION COMPLETE over its last station, which inside a seven-act campaign is
   * a lie told six times.
   */
  finale = true;
  private bannerPending = -1;
  private lastZone = 0;
  /**
   * The level's visual identity, and the one it is crossfading out of. A zone says
   * how deep you are and is shared by two levels; a motif is what *this* level is.
   */
  /**
   * The levels of the act being played. Act I's six unless a world says
   * otherwise, so every reader below - the banner, the rail, the altimeter -
   * counts the stations of the act the player is actually in.
   */
  private levels: readonly Level[] = LEVELS;
  private motif: Motif = motifFor(0);
  private motifFrom: Motif = motifFor(0);
  private motifFade = 1;
  private motifLevel = 0;
  /** Blobs bucketed by motif, so each level's rock is still one union fill. */
  private stoneBuckets: Blob[][] = Array.from(
    { length: Math.max(MOTIFS.length, motifsForAct('air').length) },
    () => [],
  );
  /** The decorative life in the water. Reads nothing, changes nothing. */
  private decor = new Decor();
  /** 1 -> 0 after a broken streak: the progress rail cools instead of flashing. */
  private streakFade = 0;
  /** 0..1 red edge glow driven by the nearest hunter. */
  private menace = 0;
  /** Screen-space gradients that only change on resize. */
  private vignette: CanvasGradient | null = null;
  /** Which (species, faction) body batches have anyone in them this frame. */
  private present = new Uint8Array(Math.max(SPECIES.length, BIRDS.length) * 2);

  /*
   * Per-bird steering state, indexed by the agent's slot in the simulation's
   * fixed pool. The one deliberate exception to "everything the flock does is
   * computed from state the simulation already keeps": a heading with yaw
   * inertia is state by definition - see `steerBearing` in Flock.ts. NaN in
   * `birdHead` marks a slot with no history; `birdSeen` holds the agent's age at
   * the last drawn frame, so a recycled slot (age went backwards) or a bird
   * culled offscreen long enough to have really moved starts fresh instead of
   * slewing in from a stale pose. Water never touches these.
   */
  private birdHead = new Float32Array(MAX_AGENTS).fill(Number.NaN);
  private birdRoll = new Float32Array(MAX_AGENTS);
  private birdPace = new Float32Array(MAX_AGENTS);
  private birdSeen = new Float32Array(MAX_AGENTS);

  /**
   * The renderer's own clock, in wall-clock seconds since the canvas came up.
   *
   * `world.run.time` stops the instant a run ends, which is correct for the water and
   * wrong for anything that has to keep moving *after* the last step - and the whole
   * ending happens after the last step.
   */
  private clock = 0;

  /**
   * 0..1 swell of the 11-second breath. Pushed in from `main` every frame.
   *
   * It is not derived here, and that is deliberate twice over. The bed and the picture
   * have to breathe as one thing, so there is one value and one clock; and that clock has
   * to be wall-clock seconds, which `render`'s own `dt` is not - it is `fixedDt` plus the
   * frame cost, so a breath advanced by it ran two to three times too fast. See the note
   * in `main.ts`'s `onRender`.
   *
   * What it touches is deliberately tiny - the light gains about a fifth on an inhale, and
   * the vignette closes about a tenth on an exhale. Anything larger stops being something
   * the player entrains to and becomes something they watch, and something they watch is
   * something they get bored of.
   */
  breath = 0.5;

  /** 0..1 opacity of the one-shot "you can drag the water" hint. */
  hintAlpha = 0;
  hintPhase = 0;
  /** Cleared while a shell screen is up, so the readout never sits under a dialog. */
  hudVisible = true;
  /**
   * How many station restarts a whole act attempt gets, or 0 for a run that is
   * not one.
   *
   * Set by `main.ts` at `startRun`, and deliberately not read off the world: the
   * world is handed how many restarts are *left* at the start of this run, which
   * for a campaign resumed after two failures is zero. Drawing "0 of 0" would tell
   * the player there was never anything to lose, on the exact run where the next
   * mistake is the act. This is the denominator, and it does not move.
   *
   * Zero for the `?act=` door, an admin jump and the probes, none of which are
   * flying an attempt - see `World.restartBudget`.
   */
  attemptsTotal = 0;
  /**
   * Top of the right-hand readout column, in CSS pixels, as the last frame drew
   * it. Read from outside so `e2e/chrome.spec.ts` can put it next to the corner
   * buttons' own rectangles - the canvas and the shell lay out in the same units
   * and in the same corner, and nothing else in this project can see both.
   */
  hudColumnTop = 0;
  /**
   * Top of the progress rail's counter, in CSS pixels, as the last frame drew it.
   * Exposed for the same reason and to the same test as `hudColumnTop`: it is the
   * highest thing the rail paints, it stands in the same corner as the two buttons,
   * and on a window short enough it used to be drawn underneath them.
   */
  railCounterTop = 0;
  /**
   * Bottom of the streak badge as the last frame drew it, and zero on a frame that
   * had nothing to say. The third rectangle in that corner, exposed for the same
   * test: the counter has to clear the badge as well as the buttons, and the badge
   * is the one of the three whose height moves while it is on screen.
   */
  streakBadgeBottom = 0;

  constructor(private readonly canvas: HTMLCanvasElement) {
    const ctx = canvas.getContext('2d', { alpha: false });
    if (ctx === null) throw new Error('Canvas2D unavailable');
    this.ctx = ctx;
  }

  setInsets(insets: { top: number; bottom: number; left: number; right: number }): void {
    this.insets = insets;
  }

  /**
   * What the drawing believes the cutout is.
   *
   * Read by the test API only. The DOM chrome and the canvas chrome dodge the
   * notch through two entirely separate mechanisms - CSS custom properties and
   * this object - and the failure worth catching is the one where the CSS moves
   * and the canvas does not, which is invisible from the outside.
   */
  get safeInsets(): { top: number; bottom: number; left: number; right: number } {
    return this.insets;
  }

  setStyle(style: RenderStyle): void {
    const densityChanged = style.quality !== this.style.quality;
    this.style = style;
    if (densityChanged) this.fitParticles();
  }

  /**
   * Grow or shrink the decorative populations to the current budget, in place.
   *
   * Deliberately not `seedParticles`, which throws both fields away and scatters
   * new ones. That is the right thing at a resize or at the first frame of a run,
   * and the wrong thing here: the budget now moves *during* a run, whenever
   * `adaptQuality` decides the frame rate is asking for it, and a full reseed is
   * every mote on the screen jumping at once - at the exact moment the machine is
   * already struggling, which is when it is most likely to be read as a fault.
   *
   * Shrinking drops the tail; growing tops up. Nothing already on screen moves.
   */
  private fitParticles(): void {
    const q = clamp(this.style.quality, 0.3, 1);
    const tracers = Math.round(FLOW_PARTICLES * q);
    while (this.particles.length > tracers) this.particles.pop();
    while (this.particles.length < tracers) this.particles.push(this.newParticle(true));
    const specks = Math.round(SPECKS * q);
    while (this.specks.length > specks) this.specks.pop();
    while (this.specks.length < specks) this.specks.push(this.newSpeck());
  }

  /** Jumps the palette straight to a zone. Used on restart, so runs never bleed. */
  syncZone(zoneIndex: number): void {
    this.paint = clonePaint(paintFor(zoneIndex));
    this.lastZone = zoneIndex;
    this.bannerLife = 0;
    this.bannerPending = -1;
    this.shake = 0;
    this.flash = 0;
    for (const [, film] of this.films) film.reset();
    this.menace = 0;
    this.effects.length = 0;
  }

  /**
   * Everything that has to be true at the first frame of a run: the palette of the
   * level being started, and a fresh field of decorative life dressed for it.
   */
  syncRun(world: World): void {
    // The world's act, never act I's globals: a run can open on any station of
    // either act (the admin surface starts them mid-script), and a first frame
    // dressed in the wrong act is a first frame in the wrong game.
    this.levels = world.act.levels;
    this.actKey = world.act.key;
    const level = levelAtIn(world.act, world.levelIndex);
    this.syncZone(level.zone);
    this.decor.reset(world.seed, level.decor, world.viewCameraY, world.direction);
    this.motifLevel = world.levelIndex;
    this.motif = motifForIn(world.act.key, this.motifLevel);
    this.motifFrom = this.motif;
    this.motifFade = 1;
    this.showBanner(world.levelIndex, false);
  }

  /** Raises the level title over the open water a level opens with. */
  private showBanner(level: number, final: boolean): void {
    this.bannerLevel = level;
    this.bannerFinal = final;
    this.bannerLife = BANNER_LIFE;
    // Dark ink over a daylit picture, pale ink everywhere else - decided once,
    // here, rather than every frame the banner is up. Act I's ending is the only
    // film that ever answers yes, and it answers yes from the frame the banner
    // is raised onward, so this is the behaviour it always had; what it is not is
    // an ink colour that could change underneath a heading that is already up.
    this.bannerDark = this.films.some(([, f]) => f.active && f.daylight);
  }

  resize(cssWidth: number, cssHeight: number, dpr: number): void {
    // A change of *width* is the one that rescales the world: `World.resize` moves
    // every blob's x and r by the ratio, and the cached stone silhouettes are keyed
    // on those blobs and hold world coordinates. Drop them here rather than in the
    // simulation, because they are the renderer's cache and the simulation has no
    // business knowing it exists. Width only: the quality ladder calls this method
    // to change the dpr several times a run, and rebuilding every hull for that
    // would be work for nothing.
    if (cssWidth !== this.w) invalidateStoneMasses();
    this.dpr = dpr;
    this.w = cssWidth;
    this.h = cssHeight;
    this.canvas.width = Math.round(cssWidth * dpr);
    this.canvas.height = Math.round(cssHeight * dpr);
    this.canvas.style.width = `${cssWidth}px`;
    this.canvas.style.height = `${cssHeight}px`;
    this.seedParticles();
    this.buildGradients();
  }

  /**
   * The vignette never changes shape, so it is built once per resize rather than
   * allocated 60 times a second. The palette-dependent gradients cannot be cached
   * this way - they move with the zone crossfade - but they are one object each.
   */
  private buildGradients(): void {
    const ctx = this.ctx;
    const cx = this.w * 0.5;
    const cy = this.h * 0.52;
    const inner = Math.min(this.w, this.h) * 0.42;
    const outer = Math.hypot(this.w, this.h) * 0.62;
    const g = ctx.createRadialGradient(cx, cy, inner, cx, cy, outer);
    g.addColorStop(0, 'rgba(0,0,0,0)');
    g.addColorStop(0.55, 'rgba(0,0,0,0.16)');
    g.addColorStop(1, 'rgba(0,0,0,0.34)');
    this.vignette = g;
  }

  private seedParticles(): void {
    const q = clamp(this.style.quality, 0.3, 1);
    this.particles = [];
    const tracers = Math.round(FLOW_PARTICLES * q);
    for (let i = 0; i < tracers; i++) this.particles.push(this.newParticle(true));
    this.specks = [];
    const specks = Math.round(SPECKS * q);
    for (let i = 0; i < specks; i++) this.specks.push(this.newSpeck());
  }

  /**
   * One mote of silt.
   *
   * Three depth bands. Silt drifting a metre from your eye and silt hanging in the
   * dark behind the rocks cannot scroll at the same rate, or the water is a flat
   * sheet with dots on it.
   */
  private newSpeck(): Speck {
    const depth = this.rng.next();
    return {
      x: this.rng.next() * this.w,
      y: this.rng.next() * this.h * 3,
      r: (0.5 + this.rng.next() * 1.9) * (1 - depth * 0.55),
      a: (0.05 + this.rng.next() * 0.18) * (1 - depth * 0.5),
      depth,
    };
  }

  private newParticle(spread: boolean): Particle {
    const life = 1.6 + this.rng.next() * 2.4;
    const x = this.rng.next() * this.w;
    const y = spread ? this.rng.next() * this.h : this.h + 10;
    return {
      x,
      y,
      tx: new Float32Array(TRAIL),
      ty: new Float32Array(TRAIL),
      head: 0,
      filled: 0,
      life: spread ? this.rng.next() * life : life,
      maxLife: life,
      tone: 0.45 + this.rng.next() * 0.55,
    };
  }

  private respawn(p: Particle): void {
    p.x = this.rng.next() * this.w;
    p.y = this.rng.next() * this.h;
    p.head = 0;
    p.filled = 0;
    p.maxLife = 1.6 + this.rng.next() * 2.4;
    p.life = p.maxLife;
    p.tone = 0.45 + this.rng.next() * 0.55;
  }

  ingest(events: SimEvent[]): void {
    for (const e of events) {
      switch (e.type) {
        case 'loss':
          this.effects.push({
            kind: 'loss',
            x: e.x,
            y: e.y,
            life: 0.5,
            maxLife: 0.5,
            value: e.value,
          });
          // Severity 0 is a straggler quietly culled off-screen; it must not shake.
          if (e.value >= 1) this.addShake(0.9);
          break;
        case 'bite':
          this.effects.push({ kind: 'bite', x: e.x, y: e.y, life: 0.6, maxLife: 0.6, value: 0 });
          this.addShake(2.4);
          break;
        case 'rescue':
          this.effects.push({
            kind: 'rescue',
            x: e.x,
            y: e.y,
            life: 0.9,
            maxLife: 0.9,
            value: e.value,
          });
          break;
        // Slowblue: clearing a section used to flash a full-width line across the
        // screen, and breaking a streak flashed a red one. Both were arcade
        // scoreboard grammar - a rule drawn *over* the water to announce a number -
        // and both are gone. The progress rail says where you are continuously,
        // the audio says a section landed, and the streak badge already lives in
        // the corner. Nothing needs to interrupt the picture to say so.
        case 'gate':
          break;
        case 'streakBreak':
          this.streakFade = 1;
          break;
        case 'reform':
          this.effects.push({ kind: 'reform', x: e.x, y: e.y, life: 1, maxLife: 1, value: 0 });
          this.flash = Math.min(1, this.flash + 0.22);
          break;
        case 'ring':
          this.effects.push({ kind: 'ring', x: e.x, y: e.y, life: 1.3, maxLife: 1.3, value: 0 });
          break;
        case 'ringLost':
          this.effects.push({
            kind: 'ringLost',
            x: e.x,
            y: e.y,
            life: 1.6,
            maxLife: 1.6,
            value: 0,
          });
          break;
        case 'level':
          this.showBanner(e.value, false);
          break;
        /*
         * The station begins again, and until this case existed nothing in the
         * game said so.
         *
         * Measured, not assumed: `e2e/response.spec.ts` fires every event of the
         * union at its own station and reads what the glass does about it, and a
         * restart was the only one that moved nothing here and put no voice on a
         * track - in the thirty stations of acts III to VI, which is where most
         * of the campaign's failures happen. What the player got was a cut: the
         * camera a station's worth of water away from where it had been, the
         * shoal back at full strength, and no statement anywhere that this was a
         * setback rather than a glitch.
         *
         * The banner is the answer rather than something new, because it is
         * already this game's sentence for "this station, from here" - the same
         * heading, over the same water, that the station opened with. What is
         * added to it is the settle below: three rings closing onto the line the
         * shoal re-enters on, in the tracer colour, because a restart is the
         * water taking you back and the tracer is what the water is drawn in.
         * Not the pod colour, which is the reward, and nothing red, which is the
         * hunter.
         */
        case 'restart':
          this.showBanner(e.value, false);
          this.effects.push({
            kind: 'restart',
            x: e.x,
            y: e.y,
            life: 1.5,
            maxLife: 1.5,
            value: 0,
          });
          break;
        case 'complete':
          // No flash and no banner here. The sequence has its own bloom, and it comes
          // three seconds later, at the moment it means something. Which sequence
          // is the act's own: the water breaches, the air lets go, the camera turns
          // - and an act with no film of its own gets none rather than another
          // act's. See `Films.ts`.
          this.bannerPending = e.value;
          this.filmFor(filmForAct(this.actKey))?.begin();
          break;
        case 'zone':
          break;
        case 'fail':
          this.addShake(3.6);
          break;
      }
    }
  }

  private addShake(amount: number): void {
    this.shake = Math.min(MAX_SHAKE, this.shake + amount);
  }

  /**
   * The ending currently on screen, if any, and whether it has reached the frame
   * the next act may open on.
   *
   * `main.ts` reads `handedOver` instead of counting seconds on a `setTimeout`,
   * and that is not a refinement - it is the fix for a real mismatch. The films
   * advance on `frameDt`, which is deliberately *not* wall-clock time (see the
   * note in `main.ts`'s `onRender`), so a timer set in real seconds and a film
   * measured in frame seconds disagree by whatever the frame cost happens to be.
   * The film is the thing that knows when it is done; nothing else can.
   */
  get film(): { kind: FilmKind; phase: string; handedOver: boolean } | null {
    const live = this.films.find(([, f]) => f.active);
    if (live === undefined) return null;
    return { kind: live[0], phase: live[1].phase, handedOver: live[1].handedOver };
  }

  /** The instance a kind names, or null while the act still ends on a cut. */
  private filmFor(kind: FilmKind | null): Film | null {
    if (kind === null) return null;
    return this.films.find(([k]) => k === kind)?.[1] ?? null;
  }

  /** Fires the celebratory flash from outside the sim (a new personal record). */
  celebrate(): void {
    this.flash = Math.min(1, this.flash + 0.5);
  }

  render(world: World, alpha: number, dt: number, debug: RenderDebugFlags, fps: number): void {
    const ctx = this.ctx;
    this.clock += dt;
    this.updatePalette(world, dt);
    this.updateMenace(world, dt);

    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    this.drawBackground(world);

    // Shake is applied *after* the background so the screen edges never show through.
    if (this.shake > 0.05) {
      const k = this.shake;
      ctx.translate(this.rng.signed() * k, this.rng.signed() * k);
      this.shake *= Math.pow(0.1, dt / SHAKE_HALF_LIFE);
    } else {
      this.shake = 0;
    }

    // Once a film has the frame, the live world goes with it. Fading the layers
    // underneath is what keeps an ending from being a double exposure - a shoal
    // and a set of canyon walls showing through a sky - and every film says how
    // far that has gone with one number, on its own clock and in its own terms.
    // They differ by an order of magnitude and each difference is the film: the
    // surfacing's is the sky arriving, the release's runs from its first frame
    // because the light leaving is its whole subject, the overview's runs hardest
    // and earliest because it is the only one that rotates and two frames of a
    // tilted horizon over an untilted course would show the seam - and the
    // circle's is the shallowest in the game, because what is underneath it is
    // the same trench in the same palette and there is nothing there to hide.
    const veil = this.veil;
    if (veil > 0) ctx.globalAlpha = Math.max(0, 1 - veil);
    this.drawSpecks(world);
    this.drawDecor(world, dt, 0);
    this.drawVortices(world);
    this.drawFlowParticles(world, dt);
    if (debug.showField) this.drawFieldVectors(world);
    if (debug.showHash) this.drawHash(world);
    this.drawWake(world);
    this.drawPotential(world);
    this.drawObstacles(world);
    this.drawDecor(world, dt, 1);
    // The light is in the water *in front of* the rock and behind the fish, which
    // is the same place the decorative layer's near half and the distance haze go,
    // and for the same reason: the shoal is the one thing that always stays crisp.
    this.drawPlane(world, 'mid');
    this.drawDepthHaze();
    this.drawPods(world);
    // The threat field goes under the shoal so it can never wash the fish out; the
    // animals themselves go over it, because a hunter working a shoal is above it in
    // the water and reading as *behind* it made the one antagonist in the game
    // disappear into its own victims.
    this.drawThreats(world);
    this.drawAgents(world, alpha, dt);
    this.drawPredators(world);
    this.drawEffects(world, dt);
    ctx.globalAlpha = 1;

    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    for (const [, film] of this.films) film.update(dt);
    // The vignette, the dread and the distance haze are all properties of the
    // *live world*, so they leave with it: once the ascent is over the pressure
    // of the deep goes too, and once any film owns the frame none of the three
    // has anything to be a property of. One number, read after the update so the
    // film and the world it is replacing are on the same frame.
    const shot = this.veil;
    // Every full-screen fill is pure fill rate, which is exactly what a weak GPU has
    // least of - so the Low setting drops the ones that are only atmosphere.
    if (this.vignette !== null && this.style.quality > 0.6 && shot < 0.98) {
      // ...and the other half of the breath: the edges close a little on the exhale.
      // Paired with the caustics gaining on the inhale, the screen opens and settles
      // without anything in it moving.
      ctx.globalAlpha = (1 - shot) * (0.9 + 0.12 * (1 - this.breath));
      ctx.fillStyle = this.vignette;
      ctx.fillRect(0, 0, this.w, this.h);
      ctx.globalAlpha = 1;
    }
    if (this.flash > 0.002) {
      ctx.globalCompositeOperation = 'lighter';
      ctx.fillStyle = `rgba(140,200,225,${(this.flash * 0.32).toFixed(3)})`;
      ctx.fillRect(0, 0, this.w, this.h);
      ctx.globalCompositeOperation = 'source-over';
      this.flash *= Math.pow(0.02, dt / 0.35);
    }
    for (const [, film] of this.films) {
      if (film.active) this.drawFilm(world, film);
    }
    if (this.menace > 0.01 && shot < 0.4) this.drawMenace();
    // `hudVisible` only, now. There was a player-facing HUD switch in front of
    // this as well, and it was not the switch it looked like: this gate wraps the
    // whole of `drawHud`, and `drawHud` is where the stranding warning is drawn -
    // the dark and the red that say the shoal is going off the bottom of the
    // screen. Turning off "the readout" turned off the only warning that a run is
    // being lost, which is not a preference, it is a way to lose without being
    // told. What people wanted from it - a clean picture when nothing is at stake -
    // is what `hudVisible` already does, from the mode rather than from a list.
    if (this.hudVisible) {
      this.drawHud(world, debug, fps);
      // The rail belongs to a campaign act; the `?act=` door and an admin jump
      // draw no route. Zeroed rather than left standing, so the reading a test
      // takes is of this frame - the same rule `drawStreak` follows for the badge.
      if (world.campaign) this.drawProgress(world, dt);
      else this.railCounterTop = 0;
    }
    // The closing title waits for its own ground. Every other banner opens a
    // station; this one closes an act, and it belongs over the sky the water
    // ending rises into, the dark the air ending settles into, the held Earth
    // after the turn has finished moving - whichever picture the film that is
    // running has finished building. Each one says so itself, because only it
    // knows. `finale` is what stops the banner claiming the campaign is over at
    // the end of every act; inside a circuit only the seventh one is.
    if (this.bannerPending >= 0 && this.films.some(([, f]) => f.active && f.settled)) {
      this.showBanner(this.bannerPending, this.finale);
      this.bannerPending = -1;
    }
    if (this.bannerLife > 0) this.drawLevelBanner(dt);
    if (this.hintAlpha > 0) this.drawHint(dt);
  }

  private updatePalette(world: World, dt: number): void {
    const zone = world.zone;
    if (zone !== this.lastZone) this.lastZone = zone;
    // The motif turns over on the same clock as the decorative life, and for the
    // same reason: a level's water should have finished changing by the time its
    // first obstacle arrives, not while the player is inside it.
    this.levels = world.act.levels;
    const level = world.levelIndex;
    if (level !== this.motifLevel) {
      this.motifFrom = this.motif;
      this.motif = motifForIn(world.act.key, level);
      this.motifLevel = level;
      this.motifFade = 0;
    }
    this.motifFade = Math.min(1, this.motifFade + dt * 0.4);
    // Time-based crossfade rather than a section-based one: the palette should be
    // moving *while* the new archetype arrives, not snap when it is cleared. Slow:
    // a colour change you can catch happening is a colour change you notice, and
    // being noticed is not what a palette is for.
    blendPaint(this.paint, paintFor(zone), Math.min(1, dt * 0.28));
  }

  /** The decorative layer. One update, two draws, nothing read back. */
  private drawDecor(world: World, dt: number, layer: 0 | 1): void {
    if (this.style.quality <= 0.5) return;
    // Nothing grows in the air. The budget this frees is exactly what `Sky.ts`
    // spends, so act II is not a more expensive frame than act I - it is the same
    // frame with the decorative life swapped for weather.
    if (world.medium.kind === 'air') return;
    if (layer === 0) {
      this.decor.setTheme(levelAtIn(world.act, world.levelIndex).decor);
      this.decor.update(world.viewCameraY, this.h, dt, this.style.quality);
    }
    this.decor.draw(
      this.ctx,
      this.paint,
      this.w,
      this.h,
      world.viewCameraY,
      world.run.time,
      layer,
    );
  }

  /**
   * One of the two depth planes. See `Strata.ts` for what they are and why a
   * picture needs them rather than needing more light.
   *
   * Crossfaded exactly the way the backdrop above it is, and skipped entirely on
   * the stations that have no plan - which today is forty-one of the forty-two, so
   * the common case is one predicate and a return.
   */
  private drawPlane(world: World, plane: Plane): void {
    if (this.style.quality <= 0.5) return;
    const f = this.motifFade;
    const from = this.motifFrom;
    const to = this.motif;
    if (!hasStrata(to.backdrop) && !(f < 1 && hasStrata(from.backdrop))) return;
    if (f < 1) drawStrata(from.backdrop, this.strataView(world, 1 - f), plane);
    drawStrata(to.backdrop, this.strataView(world, f), plane);
  }

  private strataView(world: World, alpha: number): StrataView {
    return {
      ctx: this.ctx,
      paint: this.paint,
      w: this.w,
      h: this.h,
      cameraY: world.viewCameraY,
      time: world.run.time,
      progress: world.levelProgress,
      alpha,
      quality: this.style.quality,
    };
  }

  /** Nearest hunter to the shoal, as a 0..1 dread value on the screen edges. */
  private updateMenace(world: World, dt: number): void {
    let target = 0;
    const preds = world.predators.predators;
    if (preds.length > 0) {
      const c = world.swarm.centroid(MAIN_FACTION);
      if (c.count > 0) {
        let best = Infinity;
        for (const p of preds) best = Math.min(best, Math.hypot(p.x - c.x, p.y - c.y));
        target = clamp(1 - best / 260, 0, 1);
      }
    }
    this.menace += (target - this.menace) * Math.min(1, dt * 3);
  }

  /**
   * Slowblue: the water is the zone's colour, washed with the level's own.
   *
   * The wash is folded into the gradient's stops rather than laid over the top as
   * a fourth full-screen fill: a level tint that costs a whole pass of fill rate
   * would be the first thing dropped on a weak phone, and it is the cheapest
   * identity in the game. Two levels sharing a zone are the case it exists for -
   * the Blue Deep and the Vortex Garden are painted from the same palette and must
   * not be the same colour.
   */
  private drawBackground(world: World): void {
    const ctx = this.ctx;
    const p = this.paint;
    const from = this.motifFrom;
    const to = this.motif;
    const f = this.motifFade;
    const amount = lerp(from.washAmount, to.washAmount, f);
    const tint = mix(from.wash, to.wash, f);
    const g = ctx.createLinearGradient(0, 0, 0, this.h);
    // Depth cue: the water gets darker toward the bottom, i.e. behind you. The
    // wash fades out with it, so the level's colour is strongest ahead of you.
    g.addColorStop(0, css(mix(p.top, tint, amount)));
    g.addColorStop(0.55, css(mix(p.mid, tint, amount * 0.6)));
    g.addColorStop(1, css(mix(p.bottom, tint, amount * 0.25)));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, this.w, this.h);

    if (this.style.quality > 0.5) {
      const view = {
        ctx,
        paint: p,
        w: this.w,
        h: this.h,
        cameraY: world.viewCameraY,
        time: world.run.time,
        progress: world.levelProgress,
        alpha: 1,
        quality: this.style.quality,
        breath: this.breath,
      };
      // Only ever two, and only for the couple of seconds a level change lasts.
      if (f < 1) drawBackdrop(from.backdrop, from, { ...view, alpha: 1 - f });
      drawBackdrop(to.backdrop, to, { ...view, alpha: f });
    }
    // The far plane is a mass *in* the water, so it goes over the backdrop and
    // under the caustics - light on the surface falls across it like it falls
    // across everything else at that distance.
    this.drawPlane(world, 'far');
    this.drawCaustics(world);
  }

  /**
   * Caustic bands. Two strokes of different width per band instead of one fat one:
   * a single 44px stroke has a hard edge at both sides and reads as a painted
   * stripe, which is exactly what it looked like.
   *
   * Wide additive strokes are pure fill rate, so the count is deliberately mean -
   * three passes over five bands cost about 15% of the frame on their own.
   */
  private drawCaustics(world: World): void {
    /*
     * Caustics are sunlight refracted through a surface overhead, so they belong
     * to the two media in the campaign that have one: the sea, and the brook.
     *
     * Slowblue: this was a deny-test on `air` alone, written when the campaign was two
     * acts and the only other medium was water. Five media have been added since
     * and every one of them fell through it, so the shipped build drew underwater
     * light bands in thin air, in vacuum, inside a re-entry plasma sheath and over
     * the Earth's own shadow - the station whose whole argument is that the swarm
     * is the only light source in the frame. An allow-test cannot go stale that
     * way, which is the same case `tests/geometry.test.ts` makes for allow-listing
     * the alphabets.
     */
    const lit = world.medium.kind === 'water' || world.medium.kind === 'stream';
    if (!lit) return;
    const ctx = this.ctx;
    const p = this.paint;
    const t = world.run.time;
    const bands = this.style.quality > 0.6 ? 4 : 2;
    ctx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < bands; i++) {
      const y =
        ((-world.viewCameraY * 0.35 + i * 268 + Math.sin(t * 0.2 + i) * 30) % (this.h + 300)) - 150;
      // The band's own swell, times the breath. The caustics are the brightest thing on
      // the screen that belongs to nothing in particular, which makes them the right
      // place to put the breath: the whole picture gains light on an inhale without any
      // single object in it appearing to change.
      const swell =
        (0.72 + 0.28 * Math.sin(t * 0.17 + i * 1.7)) * (0.88 + 0.24 * this.breath);
      ctx.beginPath();
      ctx.moveTo(-20, y);
      ctx.bezierCurveTo(this.w * 0.3, y + 40, this.w * 0.7, y - 40, this.w + 20, y + 10);
      for (const [width, alphaK] of [
        [40, 0.008],
        [14, 0.012],
      ] as const) {
        ctx.strokeStyle = rgba(p.speck, alphaK * swell);
        ctx.lineWidth = width;
        ctx.stroke();
      }
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  private drawSpecks(world: World): void {
    const ctx = this.ctx;
    const p = this.paint;
    const density = p.speckDensity;
    const base = -world.viewCameraY;
    // One path per depth band, so the whole layer is three fills.
    for (let band = 0; band < 3; band++) {
      const lo = band / 3;
      const hi = (band + 1) / 3;
      const rate = 0.75 - band * 0.26;
      const scroll = base * rate;
      const wrap = this.h * 3;
      ctx.beginPath();
      let drew = false;
      let alpha = 0;
      for (let i = 0; i < this.specks.length; i++) {
        const s = this.specks[i]!;
        if (s.depth < lo || s.depth >= hi) continue;
        // Density is a property of the zone, so the deep genuinely empties out.
        if (i / this.specks.length > density) continue;
        const y = ((s.y + scroll) % wrap) - this.h;
        if (y < -10 || y > this.h + 10) continue;
        ctx.moveTo(s.x + s.r, y);
        ctx.arc(s.x, y, s.r, 0, TAU);
        alpha = s.a;
        drew = true;
      }
      if (!drew) continue;
      ctx.fillStyle = rgba(p.speck, alpha * (1 - band * 0.22));
      ctx.fill();
    }
  }

  /**
   * A standing current is already visible in the tracers - it is the same water. What
   * is drawn on top of it is the *structure* of that water: where it is fastest, which
   * way it turns, and where it stops mattering. See `Whirl.ts`.
   */
  private drawVortices(world: World): void {
    const scale = world.tuning.vortexStrength;
    if (scale <= 0) return;
    const view = {
      ctx: this.ctx,
      paint: this.paint,
      accent: this.motif.accent,
      time: world.run.time,
      quality: this.style.quality,
    };
    /*
     * Drawn at exactly the strength the swarm is about to feel: the section's own
     * number, the global tuning knob, and the level's `swirl`.
     *
     * Slowblue: `swirl` was missing here and the comment argued it away - "every level
     * that places a current also turns its own swirl on, so this is the water the
     * player will actually feel". The first half is true and the second does not
     * follow: `World.water` samples `vortexStrength * level.swirl`, and only two
     * stations in the campaign author `swirl: 1`. Everywhere else the picture was
     * stronger than the physics, by two times at the Cliff and by two and a fifth
     * at the Passage - which is the one thing a standing current must never be,
     * because a lenticular is the cloud a pilot is taught to read from a distance
     * and the whole archetype is a promise about what is underneath it.
     */
    const swirl = world.level.swirl;
    // Both lists, for the reason `ObstacleSystem.prune` gives: the field stops
    // sampling a current well before the frame stops showing it.
    for (const list of [world.currents.vortices, world.currents.retired]) {
      for (const v of list) {
        const y = world.viewY(v.y);
        if (y < -v.radius - 40 || y > this.h + v.radius + 40) continue;
        drawWhirl(view, v.x, y, v.radius, v.strength * scale * swirl, v.phase);
      }
    }
  }


  /**
   * Flow visualisation: passive tracers advected by the total water, drawn as short
   * trails. A single-frame segment was sub-pixel at ambient speeds (~0.9px), which
   * made the ocean's own current completely invisible - the trail is what makes a
   * current legible before it moves the shoal, and what makes a vortex look like one.
   */
  private drawFlowParticles(world: World, dt: number): void {
    const ctx = this.ctx;
    ctx.lineCap = 'round';
    // Advected faster than real time so a slow current still paints a visible trail.
    const stretch = 2.4;
    const tracer = this.paint.tracer;
    for (const p of this.particles) {
      p.life -= dt;
      if (p.life <= 0 || p.x < -30 || p.x > this.w + 30 || p.y < -30 || p.y > this.h + 30) {
        this.respawn(p);
        continue;
      }
      world.water.sample(p.x, world.viewToWorldY(p.y), this.sample);
      const speed = Math.hypot(this.sample.x, this.sample.y);
      p.x += this.sample.x * dt * stretch;
      p.y += this.sample.y * dt * stretch;
      p.tx[p.head] = p.x;
      p.ty[p.head] = p.y;
      p.head = (p.head + 1) % TRAIL;
      if (p.filled < TRAIL) p.filled++;
      if (speed < 2.5 || p.filled < 3) continue;

      const a = clamp(speed / 170, 0.16, 1) * 0.3 * p.tone * clamp(p.life / 0.6, 0, 1);
      // Two passes: the older half dimmer, which tapers the streak without paying
      // for a per-segment stroke or a gradient.
      const half = Math.max(2, Math.ceil(p.filled / 2));
      for (let pass = 0; pass < 2; pass++) {
        const from = pass === 0 ? 0 : half - 1;
        const to = pass === 0 ? half : p.filled;
        if (to - from < 2) continue;
        const alpha = pass === 0 ? a * 0.38 : a;
        ctx.strokeStyle = rgba(tracer, alpha);
        ctx.lineWidth = pass === 0 ? 0.7 : 0.8 + a * 2.2;
        ctx.beginPath();
        for (let i = from; i < to; i++) {
          // Oldest first: head points at the next write slot.
          const idx = (p.head + TRAIL - p.filled + i) % TRAIL;
          if (i === from) ctx.moveTo(p.tx[idx], p.ty[idx]);
          else ctx.lineTo(p.tx[idx], p.ty[idx]);
        }
        ctx.stroke();
      }
    }
  }

  private drawWake(world: World): void {
    const ctx = this.ctx;
    ctx.lineCap = 'round';
    ctx.globalCompositeOperation = 'lighter';
    // The wake borrows the zone's tracer colour, because it is the same substance:
    // the finger's stroke, briefly visible in whatever the medium is.
    const tint = this.paint.tracer;
    for (const w of world.wake) {
      const t = clamp(w.life / 0.42, 0, 1);
      const len = 16 + w.strength * 30;
      const y = world.viewY(w.y);
      ctx.strokeStyle = rgba(tint, t * t * 0.26 * w.strength);
      ctx.lineWidth = 2 + w.strength * 5 * t;
      ctx.beginPath();
      ctx.moveTo(w.x - w.dx * len, y - w.dy * len);
      ctx.lineTo(w.x, y);
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Slowblue: the one input in the campaign that had no picture.
   *
   * Everywhere else a stroke is answered by something the player can see - the
   * wake, the tracers advecting, the standing currents turning. In vacuum the flow
   * field is identically zero, so the tracers are a no-op and the only response to
   * a drag is `drawWake`, a directional streak, which is the visual grammar of
   * *momentum* for an input that lays a static potential. `grep -rn potential
   * src/render src/debug` returned nothing at all before this function existed:
   * the player's own wells, and three of act IV's four standing ones, were
   * invisible objects in an act whose stated tutorial is that the new rule is
   * learned from the visual response and from nowhere else.
   *
   * Two rings, at the profile's peak and at its edge, because those are the two
   * radii that mean anything - `CORE` is where the pull is strongest and the
   * radius is where it stops entirely. A laid well is drawn in the tracer colour,
   * which is the colour of everything else the hand does; a standing one is drawn
   * in the obstacle rim, because it belongs to the course. That difference is the
   * only help act IV's teaching node needs: the frame stays empty, and the thing
   * carrying the swarm is finally something rather than nothing.
   */
  private drawPotential(world: World): void {
    if (world.medium.vacuum <= 0) return;
    const wells = world.potential.wells;
    if (wells.length === 0) return;
    const ctx = this.ctx;
    ctx.globalCompositeOperation = 'lighter';
    for (const w of wells) {
      const y = world.viewY(w.y);
      if (y < -w.radius - 40 || y > this.h + w.radius + 40) continue;
      const bright =
        0.1 * w.life * Math.min(1, Math.abs(w.strength) / 200) * world.medium.vacuum;
      if (bright < 0.002) continue;
      const tint = w.standing === true ? this.paint.rockRim : this.paint.tracer;
      for (const [radius, weight] of [
        [w.radius * POTENTIAL_CORE, 1],
        [w.radius, 0.45],
      ] as const) {
        ctx.strokeStyle = rgba(tint, bright * weight);
        ctx.lineWidth = w.strength < 0 ? 1.2 : 2.2;
        ctx.beginPath();
        ctx.arc(w.x, y, radius, 0, TAU);
        ctx.stroke();
      }
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Obstacles are grouped by level motif and painted as continuous unions. Their
   * shape stays readable, but detail is intentionally sparse: one soft lower edge
   * and one uninterrupted vertical tone transition. Repeated bands, cracks and
   * per-blob decoration made walls feel assembled from fragments.
   */
  private drawObstacles(world: World): void {
    // The act's own motif table, so an air mass is painted as the air's material.
    // Bucketing by water motifs here is exactly the bug that hung slabs of
    // midnight basalt in the cloud belt.
    const table = motifsForAct(world.act.key);
    const buckets = this.stoneBuckets;
    for (const bucket of buckets) bucket.length = 0;
    // `retired` first, so what the course has finished with is painted under what
    // it has not. Those sections are out of the simulation and still on screen -
    // the water is carrying them off the bottom of the frame, which is what a
    // rock left behind does. See `ObstacleSystem.prune`.
    for (const s of [world.obstacles.retired, world.obstacles.sections]) {
      for (const section of s) {
        if (section.blobs.length === 0) continue;
        const motif = motifForSection(world.act.key, section.level, section.zone);
        const bucket = buckets[motif.index]!;
        for (const b of section.blobs) bucket.push(b);
      }
    }
    for (let i = 0; i < buckets.length; i++) {
      if (buckets[i]!.length > 0) this.drawStone(world, buckets[i]!, table[i]!);
    }
  }

  /** One level's obstacle material. Everything about how it is lit lives in RockPaint. */
  private drawStone(world: World, blobs: Blob[], motif: Motif): void {
    paintStone(
      {
        ctx: this.ctx,
        paint: this.paint,
        motif,
        cameraY: world.viewCameraY,
        h: this.h,
        time: this.clock,
        quality: this.style.quality,
      },
      stoneMasses(blobs, motif.verts, motif.vertsSmall, motif.jag, isSoft(motif.material)),
    );
  }

  /**
   * Distance haze over the top of the screen, which is where the course arrives
   * from. Rocks fade up out of the dark instead of being switched on at the edge.
   * Drawn after the obstacles and before the shoal, so the shoal always stays crisp.
   */
  private drawDepthHaze(): void {
    if (this.style.quality <= 0.6) return;
    const ctx = this.ctx;
    const height = this.h * FOG_HEIGHT;
    const g = ctx.createLinearGradient(0, 0, 0, height);
    g.addColorStop(0, rgba(this.paint.top, 0.62));
    g.addColorStop(0.5, rgba(this.paint.top, 0.24));
    g.addColorStop(1, rgba(this.paint.top, 0));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, this.w, height);
  }

  /**
   * Slowblue: dashed means you must, solid means you may.
   *
   * The two kinds of ring do the same thing mechanically, and one of them can end
   * the run, so they cannot look alike. The mandatory one is a turning dashed ring
   * with a second ring inside it and a tick at each quarter - it reads as a dial,
   * something to be *aligned with* - and it starts breathing faster as the water
   * carries it toward the bottom of the screen, which is the only warning the game
   * gives and the only one it needs. The optional one is a thin unbroken circle
   * that never moves. Neither ever uses a colour the water does not already have.
   */
  private drawPods(world: World): void {
    const ctx = this.ctx;
    const pod = this.paint.pod;
    const boost = 0;
    ctx.globalCompositeOperation = 'lighter';
    for (const p of world.rescue.pods) {
      const y = world.viewY(p.y);
      if (y < -160 || y > this.h + 160) continue;
      if (!p.merged) {
        const hold = clamp(p.contact / (p.required ? 0.5 : 0.7), 0, 1);
        // Ring weight = how much of the shoal is inside vs how much this pod asks for.
        // The player can read "not enough of you yet" before any timer appears.
        const presence = clamp(p.presence, 0, 1);
        // Urgency: 0 while the ring is comfortably ahead, 1 as it leaves the screen.
        const urgency = p.required ? clamp((y - this.h * 0.55) / (this.h * 0.42), 0, 1) : 0;
        const breath = Math.sin(world.run.time * (2.2 + urgency * 7)) * 0.5 + 0.5;
        const pulse = 1 + urgency * breath * 0.05;
        const r = p.radius * pulse;

        // A soft pool of light inside the ring, brightening as the shoal commits.
        const glow = ctx.createRadialGradient(p.x, y, 0, p.x, y, r);
        const core =
          0.03 + presence * 0.09 + hold * 0.1 + (p.required ? 0.02 + urgency * 0.06 * breath : 0);
        glow.addColorStop(0, rgba(pod, core));
        glow.addColorStop(1, rgba(pod, 0));
        ctx.fillStyle = glow;
        ctx.beginPath();
        ctx.arc(p.x, y, r, 0, TAU);
        ctx.fill();

        if (p.required) {
          ctx.setLineDash([11, 13]);
          ctx.lineDashOffset = -world.run.time * 22;
          ctx.strokeStyle = rgba(pod, 0.3 + presence * 0.3 + urgency * 0.16 * breath + boost);
          ctx.lineWidth = 2.2 + presence * 1.8 + boost * 4;
          ctx.beginPath();
          ctx.arc(p.x, y, r, 0, TAU);
          ctx.stroke();
          // Inner ring, turning the other way: the dial the shoal is lining up with.
          ctx.lineDashOffset = world.run.time * 14;
          ctx.setLineDash([5, 16]);
          ctx.lineWidth = 1.2;
          ctx.strokeStyle = rgba(pod, 0.16 + presence * 0.24);
          ctx.beginPath();
          ctx.arc(p.x, y, r * 0.72, 0, TAU);
          ctx.stroke();
          ctx.setLineDash([]);
          // Four ticks outside it, so the ring has an orientation to read at a
          // glance even when it is mostly off the top of the screen.
          ctx.lineWidth = 1.4;
          ctx.strokeStyle = rgba(pod, 0.2 + presence * 0.3);
          ctx.beginPath();
          for (let i = 0; i < 4; i++) {
            const a = (i / 4) * TAU + world.run.time * 0.25;
            ctx.moveTo(p.x + Math.cos(a) * (r + 5), y + Math.sin(a) * (r + 5));
            ctx.lineTo(p.x + Math.cos(a) * (r + 12), y + Math.sin(a) * (r + 12));
          }
          ctx.stroke();
        } else {
          ctx.strokeStyle = rgba(pod, 0.13 + presence * 0.22 + hold * 0.2 + boost);
          ctx.lineWidth = 1.1 + presence * 1.2 + hold * 1.2 + boost * 4;
          ctx.beginPath();
          ctx.arc(p.x, y, r, 0, TAU);
          ctx.stroke();
        }
        if (hold > 0) {
          ctx.strokeStyle = rgba(brighten(pod, 0.35), 0.9);
          ctx.lineWidth = 3;
          ctx.beginPath();
          ctx.arc(p.x, y, r, -Math.PI / 2, -Math.PI / 2 + TAU * hold);
          ctx.stroke();
        }
      } else if (p.flash > 0) {
        const t = 1 - p.flash / 0.75;
        ctx.strokeStyle = rgba(brighten(pod, 0.4), (1 - t) * 0.7);
        ctx.lineWidth = 6 * (1 - t);
        ctx.beginPath();
        ctx.arc(p.x, y, p.radius + t * 180, 0, TAU);
        ctx.stroke();
      }
    }
    ctx.globalCompositeOperation = 'source-over';
    ctx.lineDashOffset = 0;
  }

  /** The hunter view, shared by the two passes a predator is drawn in. */
  private hunterView(): {
    ctx: CanvasRenderingContext2D;
    paint: ZonePaint;
    accent: Rgb;
    time: number;
    quality: number;
  } {
    return {
      ctx: this.ctx,
      paint: this.paint,
      accent: this.motif.accent,
      time: this.clock,
      quality: this.style.quality,
    };
  }

  /**
   * Dread and reach, under the shoal. Every hunter's field is drawn before any body, so
   * two overlapping washes never darken a third animal's silhouette.
   */
  private drawThreats(world: World): void {
    const preds = world.predators.predators;
    if (preds.length === 0) return;
    const view = this.hunterView();
    const margin = 60;
    for (const p of preds) {
      const y = world.viewY(p.y);
      const reach = p.size * 5.5;
      if (y < -reach - margin || y > this.h + reach + margin) continue;
      THREAT[p.form](view, p.x, y, p.size, p.lunge);
    }
  }

  /**
   * The animals. See `Hunter.ts` for what a predator is made of now and why it stopped
   * being a red wedge.
   */
  private drawPredators(world: World): void {
    const preds = world.predators.predators;
    if (preds.length === 0) return;
    const view = this.hunterView();
    for (const p of preds) {
      const y = world.viewY(p.y);
      if (y < -p.size * 4 || y > this.h + p.size * 4) continue;
      const speed = Math.hypot(p.vx, p.vy);
      const dx = speed < 1 ? 0 : p.vx / speed;
      const dy = speed < 1 ? -1 : p.vy / speed;
      // The beat runs faster the harder the animal is working, and its phase is
      // its own, so two predators in one section never move in step.
      const beat = this.clock * (2.2 + speed / 90) + p.phase * 3;
      BODY[p.form](view, p.x, y, dx, dy, p.size, p.lunge, beat);
    }
  }

  /**
   * Two additive glow batches, then one body batch per (species, faction, tint).
   *
   * Species is what makes a grown shoal look assembled rather than cloned, and each
   * one is a genuinely different silhouette from above - a stubby disc reads as a
   * different animal to a needle even when the palette has moved. Within a species
   * the fish are split into two tints on their wander phase, because a hundred
   * identical outlines still read as a stamped pattern.
   */
  private drawAgents(world: World, alpha: number, dt: number): void {
    const ctx = this.ctx;
    // Slowblue: high contrast has to know which way to push. Act I's shoal is pale on
    // dark water, so brightening it is right; act II's flock is a *silhouette* on
    // a bright sky for half the act, and brightening that walks it toward the
    // background. Push away from the sky rather than toward the light.
    const main: Rgb = this.paint.shoal;
    const pod: Rgb = brighten(this.paint.pod, 0.15);
    /*
     * Slowblue: what the carried life *is*, and the one place the campaign's secret
     * lives in code.
     *
     * The player was never steering the fish. They were helping the same golden
     * spark along, and the thing holding it changed seven times on the way round -
     * so the carrier is read off `Act.carrier` rather than off the medium, and it
     * is a **render-side decision from end to end**. Every act is the same
     * `SwarmSimulation`, the same agents, the same boids terms and the same rescue
     * rings; what differs is the silhouette drawn at each position.
     *
     * Two of the seven are animals and have anatomy (`FishShapes`, `Flock`). The
     * other five have no body plan at all and are drawn by `Carriers.ts`, because
     * a spore, a spark, a grain of meteor dust, a raindrop and a plankter do not
     * have a front - and drawing them as though they did would say the player is
     * still steering creatures, which is the one thing the second half is about
     * not being true.
     */
    const carrier = world.act.carrier;
    if (isParticle(carrier)) {
      this.drawParticles(world, alpha, carrier, main, pod);
      return;
    }
    const air = carrier === 'birds';
    const table = air ? BIRDS : SPECIES;

    // Slowblue: **no glow in air.** A shoal is a light source in a dark medium and an
    // additive smear under it is honest; a bird is a silhouette, and a silhouette
    // that glows is a sticker. The legibility the glow was buying now comes from
    // the palette instead - the flock is dark against a bright sky and bright
    // against a dark one - which is both cheaper and what a bird actually is.
    if (!air) {
      ctx.globalCompositeOperation = 'lighter';
      this.glowBatch(world, alpha, true, this.paint.shoalGlow, this.paint.shoalGlowAlpha * 0.9);
      this.glowBatch(world, alpha, false, pod, 0.1);
      ctx.globalCompositeOperation = 'source-over';
    }

    // One scan to find out which batches exist at all, so an empty species never
    // costs a pass over six hundred agent slots.
    this.present.fill(0);
    for (const a of world.swarm.agents) {
      if (!a.alive) continue;
      const s = a.species < table.length ? a.species : 0;
      this.present[s * 2 + (a.faction === MAIN_FACTION ? 0 : 1)] = 1;
    }
    // The beat runs on the simulation clock, so it stops dead when paused.
    const clock = world.swarm.time;
    for (let s = 0; s < table.length; s++) {
      const sp = table[s]!;
      for (const isMain of [true, false] as const) {
        if (this.present[s * 2 + (isMain ? 0 : 1)] === 0) continue;
        const base = temper(isMain ? main : pod, sp.tint);
        if (air) {
          // One fill for the whole species. A bird is one colour: no second pass,
          // no dark primaries, no tip in another shade - see `Flock.ts`. The
          // two-tint phase split the fish use buys nothing here either, because
          // what keeps a flock from stamping is that no two birds are at the same
          // point of the same wingbeat.
          this.birdBatch(world, alpha, isMain, s, clock, base, dt);
          continue;
        }
        this.bodyBatch(world, alpha, isMain, s, clock, temper(base, -0.18), true);
        this.bodyBatch(world, alpha, isMain, s, clock, temper(base, 0.18), false);
      }
    }
  }

  /**
   * One bird species, one faction, one fill.
   *
   * Everything that makes the flock look alive is computed here from state the
   * simulation already keeps, and none of it costs a byte of storage:
   *
   *   - the **beat phase** is the sim clock times a rate that rises with speed,
   *     offset per individual so no two birds are in step (a synchronised flock
   *     is a screensaver) and *scaled* per individual, so they are not even at
   *     the same tempo;
   *   - the **roll** is the steered heading's own yaw rate, which is clamped at
   *     the source - and a flock that banks into its turns is the single biggest
   *     difference between birds and sprites being slid around.
   *
   * The one thing that is *not* free is the heading itself: it is per-bird
   * state with a turn-rate limit on it (`birdHead` and friends above), because
   * every stateless version of it - raw velocity, blended velocity - has been
   * reported as jitter by a player. See `steerBearing` in Flock.ts.
   */
  private birdBatch(
    world: World,
    alpha: number,
    isMain: boolean,
    species: number,
    clock: number,
    colour: Rgb,
    dt: number,
  ): void {
    const ctx = this.ctx;
    const bird = birdAt(species);
    const fingers = this.style.quality > 0.6;
    const flap = beatAmount(this.breath, bird.glide);
    ctx.fillStyle = css(colour);
    ctx.beginPath();
    let drew = false;
    const agents = world.swarm.agents;
    for (let i = 0; i < agents.length; i++) {
      const a = agents[i]!;
      if (!a.alive || (a.faction === MAIN_FACTION) !== isMain) continue;
      if ((a.species < BIRDS.length ? a.species : 0) !== species) continue;
      const x = a.px + (a.x - a.px) * alpha;
      const y = world.viewY(a.py + (a.y - a.py) * alpha);
      if (y < -30 || y > this.h + 30) continue;
      const speed = Math.hypot(a.vx, a.vy);
      // Slowblue: **a bird cannot turn in a frame.** The heading is steered state -
      // `bearing`'s wheel-and-blend target, approached under a yaw-rate clamp -
      // because both stateless versions of this line were reported as jitter:
      // raw velocity spun the held birds on their own noise (decision 51), and
      // the blended target still snapped for any bird that was fast *and*
      // incoherent, which is every bird boxed in a ring and the whole flock the
      // moment nobody is herding it. See `steerBearing` in Flock.ts.
      //
      // A slot whose agent changed (age went backwards) or whose bird has been
      // offscreen long enough to have genuinely moved starts fresh.
      if (a.age < this.birdSeen[i]! || a.age - this.birdSeen[i]! > 0.5) {
        this.birdHead[i] = Number.NaN;
      }
      this.birdSeen[i] = a.age;
      const prev = this.birdHead[i]!;
      const fresh = !Number.isFinite(prev);
      const angle = steerBearing(prev, a.vx, a.vy, clock, a.phase, dt);
      this.birdHead[i] = angle;
      const dx = BEARING.x;
      const dy = BEARING.y;
      // Banking, read off the steered heading's own yaw rate. The step above is
      // clamped, so the roll cannot flicker the span the way the old per-step
      // displacement term did; the deadband keeps the station-holding wheel and
      // straight cruise flat-winged, and the smoothing lets a bank build and
      // release like a movement rather than a switch.
      const yaw = fresh || dt <= 0 ? 0 : (angle - prev) / dt;
      const rollTarget = clamp((Math.abs(yaw) - 0.12) * 0.8, 0, 1);
      const roll = fresh
        ? rollTarget
        : this.birdRoll[i]! + (rollTarget - this.birdRoll[i]!) * Math.min(1, dt * 7);
      this.birdRoll[i] = roll;
      // The pace the *silhouette* reads - body length, beat effort - is the
      // low-passed speed, because the instantaneous one carries the wander term,
      // and per-frame noise in a drawn dimension is exactly the vibration this
      // batch keeps being reported for.
      const pace = fresh
        ? speed
        : this.birdPace[i]! + (speed - this.birdPace[i]!) * Math.min(1, dt * 5);
      this.birdPace[i] = pace;
      const scale = a.variation;
      // Narrower in the body than a fish of the same nominal length, and by a
      // lot: a bird is a fuselage with wings on it, so the body carries about a
      // quarter of the length where a fish's carries a third, and everything else
      // in the silhouette is span. Get this wrong and the flock reads as moths.
      // Slowblue: **birds are drawn much smaller than fish, and it is not a taste.**
      //
      // A shoal and a flock are the same hundred bodies, but a bird is two and a
      // half times wider than it is long where a fish is a third as wide - so at
      // the same nominal length a flock covers roughly seven times the area of a
      // shoal, and act II's frame filled up with wings. Sized by the footprint
      // rather than by the length, a bird ends up at about 19 px across and 8 px
      // long against a fish's 12.5 x 3.4, which is *smaller* on the longest axis
      // and still the more visible of the two.
      //
      // It also buys back the picture the act is about: at this size the flock is
      // an object being steered through weather instead of a mass that hides it,
      // and a ring of held birds is legible as a ring.
      const len = (6.9 + clamp(pace / 90, 0, 1.5) * 1.9) * scale * bird.len;
      const wid = 0.93 * scale * bird.wid;
      // The wingbeat runs on the simulation clock like everything else, so a
      // paused flock holds its wings where they were. `variation` is a narrow
      // 0.92-1.08, so it is widened before it is used as a tempo: at its raw
      // width every bird beats at visibly the same rate, which is the one thing
      // a flock never does.
      //
      // Slowblue: **the rate must not depend on anything that changes per frame**,
      // and this line used to read `(1.9 + speed / 200)`. Phase here is
      // `clock * rate`, and `clock` grows without bound - so a rate that moves at
      // all retroactively rewrites the entire accumulated phase. Twenty seconds
      // into a run, the ordinary frame-to-frame wobble in an agent's speed (the
      // boids wander term alone is worth a few px/s) moved the rate by ~0.025 and
      // therefore the phase by *three radians*, every frame. On a fish that reads
      // as a tail flicking; on a bird, where the phase drives the span, it is the
      // whole silhouette snapping to a new width sixty times a second. It looked
      // exactly like what it was: vibration.
      //
      // "Beats harder when working harder" is kept, but as *amplitude*, which is
      // bounded and cannot accumulate. A one-percent wobble in amplitude is
      // invisible; a one-percent wobble in rate is a strobe.
      const beat = beatPhase(clock, bird, scale, a.phase);
      // ...and each bird eases off and picks up on its own slow cycle, so the
      // flock ripples instead of breathing as one body. A function of the clock,
      // so it is as smooth as the beat it scales.
      const own = 0.76 + 0.24 * Math.sin(clock * 0.31 + a.phase * 3.7);
      const effort = 0.86 + 0.14 * clamp(pace / 120, 0, 1);
      traceBird(ctx, x, y, dx, dy, len, wid, bird, beat, flap * own * effort, fingers, roll);
      drew = true;
    }
    if (drew) ctx.fill();
  }

  /**
   * The five carriers that are not animals: one halo pass and one body pass.
   *
   * Deliberately much simpler than the fish and the bird paths, and that is not a
   * saving - it is what these things *are*. A shoal needs two tints and a species
   * table because a hundred identical spindles read as a stamp; a cloud of spores
   * does not, because a cloud of spores genuinely is a cloud of nearly identical
   * things and the variation it needs is in size and glint rather than in shape.
   * `Carriers.ts` carries all of that per individual, from the wander phase the
   * simulation already keeps, so this stays two fills for the whole swarm.
   *
   * The halo is the one thing worth arguing about, and it is drawn for four of
   * the five: in vacuum, in re-entry, in rain and on the way home the swarm is
   * the brightest thing in the frame or the only thing lit at all, so an additive
   * smear under it is honest in exactly the way it was honest for the shoal and
   * dishonest for the flock (see the note above `drawAgents`).
   */
  private drawParticles(
    world: World,
    alpha: number,
    kind: CarrierKind,
    main: Rgb,
    pod: Rgb,
  ): void {
    const ctx = this.ctx;
    const c = carrierFor(kind);
    const clock = world.swarm.time;

    /*
     * The halo, and why it is three passes rather than one.
     *
     * A halo drawn as a single flat-filled circle is a *disc*, not a glow, and
     * that distinction is invisible for four acts and then ruins two. Over water
     * and sky the background is bright enough that an added fifth of gold blends
     * into it; over the black of act IV it is a hard-edged brown plate around
     * every mote, and the carrier the whole campaign is about looked like it had
     * been printed on dirty paper.
     *
     * Three concentric batched fills at a third of the alpha each give a stepped
     * falloff instead: the centre still reaches the full value, the edge reaches
     * a third of it, and there is no rim anywhere. It is a cone rather than a
     * true gaussian, and it costs three fills per faction rather than one - not
     * three per *agent*, which is what a real radial gradient would have cost,
     * and which is why this game draws no per-individual gradients anywhere.
     */
    if (c.halo > 0 && this.style.quality > 0.5) {
      const rings = [1, 0.66, 0.38];
      ctx.globalCompositeOperation = 'lighter';
      for (const isMain of [true, false] as const) {
        ctx.fillStyle = rgba(
          isMain ? this.paint.shoalGlow : pod,
          (c.haloAlpha * (isMain ? this.paint.shoalGlowAlpha * 2.2 : 0.5)) / rings.length,
        );
        for (const ring of rings) {
          ctx.beginPath();
          let drew = false;
          for (const a of world.swarm.agents) {
            if (!a.alive || (a.faction === MAIN_FACTION) !== isMain) continue;
            const x = a.px + (a.x - a.px) * alpha;
            const y = world.viewY(a.py + (a.y - a.py) * alpha);
            if (y < -30 || y > this.h + 30) continue;
            const r = PARTICLE_RADIUS * a.variation * c.size * c.halo * ring;
            ctx.moveTo(x + r, y);
            ctx.arc(x, y, r, 0, TAU);
            drew = true;
          }
          if (drew) ctx.fill();
        }
      }
      ctx.globalCompositeOperation = 'source-over';
    }

    for (const isMain of [true, false] as const) {
      ctx.fillStyle = css(isMain ? main : pod);
      ctx.beginPath();
      let drew = false;
      for (const a of world.swarm.agents) {
        if (!a.alive || (a.faction === MAIN_FACTION) !== isMain) continue;
        const x = a.px + (a.x - a.px) * alpha;
        const y = world.viewY(a.py + (a.y - a.py) * alpha);
        if (y < -30 || y > this.h + 30) continue;
        traceCarrier(ctx, c, x, y, PARTICLE_RADIUS * a.variation, a.vx, a.vy, a.phase, clock);
        drew = true;
      }
      if (drew) ctx.fill();
    }
  }

  /** Soft ellipse per individual, stretched along its heading. One fill per batch. */
  private glowBatch(
    world: World,
    alpha: number,
    isMain: boolean,
    colour: Rgb,
    strength: number,
  ): void {
    const ctx = this.ctx;
    ctx.fillStyle = rgba(colour, strength);
    ctx.beginPath();
    let drew = false;
    for (const a of world.swarm.agents) {
      if (!a.alive || (a.faction === MAIN_FACTION) !== isMain) continue;
      const x = a.px + (a.x - a.px) * alpha;
      const y = world.viewY(a.py + (a.y - a.py) * alpha);
      if (y < -30 || y > this.h + 30) continue;
      const speed = Math.hypot(a.vx, a.vy);
      // Faster individuals leave a longer smear of light: the flock's speed is
      // legible from the glow alone, before you read a single body. The glow keeps
      // each shape's proportions, so a stubby disc glows round and a needle glows
      // as a line. Water only: see `drawAgents` for why the air has no glow.
      const sp = speciesAt(a.species);
      const stretch = (5.8 + clamp(speed / 90, 0, 1.6) * 4.4) * sp.len * a.variation;
      const across = 3.4 * sp.wid * a.variation;
      const rot = speed < 1 ? -Math.PI / 2 : Math.atan2(a.vy, a.vx);
      ctx.moveTo(x + stretch, y);
      ctx.ellipse(x, y, stretch, across, rot, 0, TAU);
      drew = true;
    }
    if (drew) ctx.fill();
  }

  /**
   * One species, one faction, one tint: a top-down fish per agent, all in one fill.
   * `evenPhase` picks which half of the wander phases this batch owns.
   */
  private bodyBatch(
    world: World,
    alpha: number,
    isMain: boolean,
    species: number,
    clock: number,
    colour: Rgb,
    evenPhase: boolean,
  ): void {
    const ctx = this.ctx;
    const sp = speciesAt(species);
    // Fins are the most expensive part of the outline and the first thing that is
    // invisible on a small or slow device.
    const fins = this.style.quality > 0.6;
    ctx.fillStyle = css(colour);
    ctx.beginPath();
    let drew = false;
    for (const a of world.swarm.agents) {
      if (!a.alive || (a.faction === MAIN_FACTION) !== isMain) continue;
      if ((a.species < SPECIES.length ? a.species : 0) !== species) continue;
      if (a.phase < Math.PI !== evenPhase) continue;
      const x = a.px + (a.x - a.px) * alpha;
      const y = world.viewY(a.py + (a.y - a.py) * alpha);
      if (y < -30 || y > this.h + 30) continue;
      const speed = Math.hypot(a.vx, a.vy);
      let dx = a.vx;
      let dy = a.vy;
      if (speed < 1) {
        dx = 0;
        dy = -1;
      } else {
        dx /= speed;
        dy /= speed;
      }
      // Faster individuals stretch, and beat their tail faster: the shoal's effort
      // is readable from the animation before you read a single position.
      const scale = a.variation;
      // Slowblue: a third bigger than the hundred-fish version. The run now starts with 25
      // individuals spaced far enough apart to keep the shoal's footprint, and at the
      // old size that read as a scatter of specks rather than as a shoal - fewer fish
      // have to be *bigger* fish, or the thing the player is steering stops looking
      // like one animal made of many.
      const len = (12.5 + clamp(speed / 90, 0, 1.5) * 4.6) * scale * sp.len;
      const wid = 3.4 * scale * sp.wid;
      // Slowblue: constant rate, for the reason written out in full in `birdBatch` -
      // a phase of `clock * rate` cannot survive a rate that moves, because the
      // clock is unbounded and the whole accumulated phase moves with it. This
      // was here first and the shoal has always had it: the tail was flicking to
      // a new position every frame rather than sweeping. It is far more obvious
      // on a wing than on a tail, which is why it took the birds to find it.
      const beat = clock * TAU * 1.5 * sp.beat * clamp(1 + (scale - 1) * 3, 0.8, 1.25) + a.phase * 2;
      traceFish(ctx, x, y, dx, dy, len, wid, sp, beat, fins);
      drew = true;
    }
    if (drew) ctx.fill();
  }

  private drawEffects(world: World, dt: number): void {
    const ctx = this.ctx;
    ctx.globalCompositeOperation = 'lighter';
    for (let i = this.effects.length - 1; i >= 0; i--) {
      const e = this.effects[i]!;
      e.life -= dt;
      if (e.life <= 0) {
        this.effects.splice(i, 1);
        continue;
      }
      const t = 1 - e.life / e.maxLife;
      const y = world.viewY(e.y);
      if (e.kind === 'loss') {
        // A puff of scattered light, not a disc: something came apart here.
        const r = 3 + t * 13;
        ctx.strokeStyle = `rgba(150,178,196,${((1 - t) * 0.42).toFixed(3)})`;
        ctx.lineWidth = 1 + (1 - t) * 1.4;
        ctx.beginPath();
        ctx.arc(e.x, y, r, 0, TAU);
        ctx.stroke();
      } else if (e.kind === 'bite') {
        // A strike gets its own colour. It is the one loss the player did not cause
        // by steering, so it must not look like a rock.
        ctx.strokeStyle = `rgba(255,72,84,${((1 - t) * 0.7).toFixed(3)})`;
        ctx.lineWidth = 3 * (1 - t);
        ctx.beginPath();
        ctx.arc(e.x, y, 6 + t * 46, 0, TAU);
        ctx.stroke();
        for (let s = 0; s < 5; s++) {
          const ang = e.x * 0.7 + s * 1.257;
          const from = 8 + t * 30;
          const to = from + 10 * (1 - t);
          ctx.beginPath();
          ctx.moveTo(e.x + Math.cos(ang) * from, y + Math.sin(ang) * from);
          ctx.lineTo(e.x + Math.cos(ang) * to, y + Math.sin(ang) * to);
          ctx.stroke();
        }
      } else if (e.kind === 'rescue') {
        ctx.strokeStyle = rgba(brighten(this.paint.pod, 0.45), (1 - t) * 0.5);
        ctx.lineWidth = 4 * (1 - t);
        ctx.beginPath();
        ctx.arc(e.x, y, 20 + t * 220, 0, TAU);
        ctx.stroke();
        ctx.strokeStyle = rgba(brighten(this.paint.pod, 0.7), (1 - t) * 0.3);
        ctx.lineWidth = 2 * (1 - t);
        ctx.beginPath();
        ctx.arc(e.x, y, 12 + t * 128, 0, TAU);
        ctx.stroke();
      } else if (e.kind === 'ring') {
        // A held ring closes: three rings collapsing inward onto the point where
        // the shoal committed. The opposite shape to a loss, on purpose.
        for (let i = 0; i < 3; i++) {
          const k = clamp(t * 1.6 - i * 0.18, 0, 1);
          if (k <= 0) continue;
          const r = 150 * (1 - k) + 14;
          ctx.strokeStyle = rgba(brighten(this.paint.pod, 0.4), (1 - k) * 0.34);
          ctx.lineWidth = 1 + (1 - k) * 2.4;
          ctx.beginPath();
          ctx.arc(e.x, y, r, 0, TAU);
          ctx.stroke();
        }
      } else if (e.kind === 'ringLost') {
        // ...and a lost one opens and keeps going. The run is already over by the
        // time this is on screen; it is the picture the player is left with.
        const r = 30 + t * 340;
        ctx.strokeStyle = `rgba(255,132,108,${((1 - t) * 0.5).toFixed(3)})`;
        ctx.lineWidth = 2 + (1 - t) * 3;
        ctx.setLineDash([9, 13]);
        ctx.lineDashOffset = -t * 40;
        ctx.beginPath();
        ctx.arc(e.x, y, r, 0, TAU);
        ctx.stroke();
        ctx.setLineDash([]);
      } else if (e.kind === 'restart') {
        // Three rings closing, wide and slow: `ring` is the same verb played in a
        // third of the time and twice the alpha, because that one is a reward and
        // this one is the water settling. They are deliberately the same shape -
        // the game has one gesture for "this is gathering back together" and a
        // restart is that sentence said quietly.
        for (let i = 0; i < 3; i++) {
          const k = clamp(t * 1.35 - i * 0.22, 0, 1);
          if (k <= 0) continue;
          const r = 300 * (1 - k) + 20;
          // Squared, so the ring is at its faintest exactly as it lands rather
          // than stopping at a visible edge on the frame it disappears.
          ctx.strokeStyle = rgba(this.paint.tracer, (1 - k) * (1 - k) * 0.3);
          ctx.lineWidth = 1 + (1 - k) * 2.2;
          ctx.beginPath();
          ctx.arc(e.x, y, r, 0, TAU);
          ctx.stroke();
        }
      } else if (e.kind === 'reform') {
        // Two arcs sweeping inward and closing: the shape of the verb it rewards.
        const r = 210 * (1 - t) + 26;
        const span = Math.PI * 0.42 * (1 - t * 0.35);
        // Hits at full strength and fades: feedback for an action must be immediate,
        // and a sin() swell peaks a third of a second after the thing you did.
        ctx.strokeStyle = `rgba(160,222,235,${(Math.pow(1 - t, 0.7) * 0.7).toFixed(3)})`;
        ctx.lineWidth = 2 + (1 - t) * 3;
        for (const dir of [0, Math.PI]) {
          ctx.beginPath();
          ctx.arc(e.x, y, r, dir - span, dir + span);
          ctx.stroke();
        }
      }
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Dread, on the screen edges.
   *
   * Slowblue: this used to be a bright red glow, which is the visual grammar of a health
   * bar - the game shouting a state at the player. Fear in water is the opposite of a
   * light coming on: the room closes and the colour drains out of the edges. So the
   * wash is now a dark one with barely any red left in it, and the only thing that
   * brightens as a hunter closes is the hunter.
   */
  private drawMenace(): void {
    const ctx = this.ctx;
    const a = this.menace;
    const cx = this.w * 0.5;
    const cy = this.h * 0.5;
    const g = ctx.createRadialGradient(
      cx,
      cy,
      Math.min(this.w, this.h) * 0.3,
      cx,
      cy,
      Math.max(this.w, this.h) * 0.74,
    );
    g.addColorStop(0, 'rgba(28,2,10,0)');
    g.addColorStop(0.6, `rgba(28,2,10,${(a * 0.2).toFixed(3)})`);
    g.addColorStop(1, `rgba(34,3,12,${(a * 0.46).toFixed(3)})`);
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, this.w, this.h);
    // One thin warm line right at the edge, so the darkening reads as a threat rather
    // than as the screen dimming.
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = `rgba(255,72,72,${(a * 0.07).toFixed(3)})`;
    ctx.lineWidth = 3;
    ctx.strokeRect(1.5, 1.5, this.w - 3, this.h - 3);
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * What is left of the readouts, and what is not.
   *
   * There used to be a column in the top-left corner: the shoal count, the
   * score, and the metres travelled, stacked over the water. Three numbers that
   * are each true, and together they are the game asking to be read instead of
   * watched - which is the one thing a screen made entirely of one continuous
   * picture of water cannot afford. The count warmed toward red as the shoal
   * neared collapse, the score counted up, the metres carried an arrow so the
   * ascent and the fall could be told apart. All of it is gone.
   *
   * Nothing that is a *signal* went with it. The dark rising off the bottom edge
   * when the shoal is being left behind is still here, because that is the one
   * "you are losing" warning in the game and it is spatial rather than written -
   * it is a thing happening to the picture, not a number about it. The score is
   * still counted, still banked and still reported on the screen after the run,
   * where reading is what a player is doing anyway.
   */
  private drawHud(world: World, debug: RenderDebugFlags, fps: number): void {
    const ctx = this.ctx;
    const x = 14 + this.insets.left;
    const y = 20 + this.insets.top;
    const right = this.w - 14 - this.insets.right;
    const contrast = 0;
    ctx.font = '500 12px ui-sans-serif, system-ui, sans-serif';
    ctx.fillStyle = `rgba(216,251,255,${(0.42 + contrast).toFixed(2)})`;
    ctx.textBaseline = 'top';
    ctx.textAlign = 'left';

    // The right column starts below the buttons that own that corner.
    //
    // The gate count went the way of the rest of the readouts. A bare `0` sitting
    // in the corner of the water for the first half of every run says nothing a
    // player can act on, and with the mixer button beside it, it read as a stray
    // glyph rather than a number. Gates are still counted and still reported on
    // the results screen. The streak badge stays: it only appears once there is
    // something to say, and it says it about a thing the player just did.
    //
    // It used to start at `y + 58`, which cleared *the pause button* - true when
    // that was the only thing up there, and quietly false from the day the mixer
    // button was put under it. The badge has been drawn straight through the
    // mixer button ever since, and the store screenshots are where it showed:
    // `×1.00` with a speaker sitting in the middle of it. Neither instrument
    // could see it - `chrome.spec` measures the DOM's own rectangles and never
    // the canvas under them, and the screen census reads the glass and knows
    // nothing about what is layered over it.
    this.hudColumnTop = this.insets.top + HUD_COLUMN_TOP;
    ctx.textAlign = 'right';
    this.drawStreak(world, right, this.hudColumnTop);
    ctx.textAlign = 'left';

    // Level with the streak badge on the other side, and clear of the same
    // buttons: the top-left 40 px belong to the admin toggle in a dev build, and
    // a readout drawn underneath a control is a readout nobody can check.
    this.drawAttempts(world, x, this.hudColumnTop);

    // Being left behind: the only "you are losing" signal, and it is spatial.
    //
    // Slowblue: this used to start at the strand line itself, which is two thirds of a
    // second before the run ends - a verdict, not a warning. The ocean's drift is now
    // genuinely faster than a shoal swimming on its own (see `Tuning.migrationSpeed`),
    // so falling back is a slow, ordinary thing the player has to notice and correct.
    // The dark rises from the bottom edge as the shoal sinks past four fifths of the
    // screen, and only turns red once the water is actually taking them.
    /*
     * Slowblue: it was `viewY(centroid.y) / this.h`, a raw screen fraction, and drawn
     * at the bottom edge - and both halves of that are the climb's answer written
     * as if it were everyone's.
     *
     * On a climb, behind *is* the bottom, so the two agreed and nobody noticed. On
     * a fall, behind is the **top**: `behindLine` sits at `cameraY + 0.1H` and the
     * camera holds the swarm at 0.38 of the frame, so `viewY/h` could never reach
     * 0.78 and the threshold was unreachable by construction. Measured on act V,
     * 240 s, a hand doing nothing at all: act I paints this on 19.9 % of frames and
     * act V on **0.00 %**. Three of the seven acts - every act that falls - have
     * been shipping with no "you are losing" signal at all, and one of them is the
     * act a player has just reported as impossible to die in.
     *
     * `behindFraction` is the number that already knows which way the act runs, and
     * the gradient is drawn at whichever edge is actually behind.
     */
    const centroid = world.swarm.centroid(MAIN_FACTION);
    const falling = world.direction > 0;
    const sink =
      centroid.count > 0
        ? clamp((world.behindFraction(world.viewY(centroid.y)) - 0.78) / 0.16, 0, 1)
        : 0;
    // The act's own grace, not a copy of it. This was a literal 0.7, which is
    // `RESTART_ON_FAILURE.strandGrace` written out a second time - and the whole
    // reason `FailurePolicy` exists is that an act is allowed to move it. A bar
    // that fills at a rate the rule does not use is a bar that lies.
    const taken = clamp(world.run.strandedFor / Math.max(0.01, world.act.failure.strandGrace), 0, 1);
    if (sink > 0.01 || taken > 0.01) {
      const height = 90 + sink * 90;
      const edge = falling ? 0 : this.h;
      const g = ctx.createLinearGradient(0, edge, 0, falling ? height : this.h - height);
      const warm = Math.max(sink * sink * 0.34, taken * 0.5);
      g.addColorStop(0, `rgba(${Math.round(120 + 135 * taken)},${Math.round(30 + 66 * taken)},48,${warm.toFixed(3)})`);
      g.addColorStop(1, 'rgba(120,30,48,0)');
      ctx.fillStyle = g;
      ctx.fillRect(0, falling ? 0 : this.h - height, this.w, height);
    }

    /*
     * ...and the other edge, which is the one act V needed and never had.
     *
     * The swarm can outrun the medium it is falling through, and past
     * `Tuning.terminalFactor` the medium starts taking it apart from the front -
     * see `Medium.drag` and `World.updateAblation`. That cost has to arrive as a
     * *warning* and not as a receipt, for exactly the reason the note above says
     * the strand gradient starts early: a player who cannot see it coming has not
     * been given a demand, they have been charged.
     *
     * So it is the same gradient, the same shape and the same warm, drawn at the
     * edge the swarm is running toward rather than the one it is falling away
     * from. Two edges, two dangers, one visual language - and on a fall they are
     * the top and the bottom of the same frame, which is what makes the act
     * legible: the frame closes in from whichever side you are getting wrong.
     */
    if (world.ablating > 0.01) {
      const hot = clamp(world.ablating, 0, 1);
      const height = 70 + hot * 110;
      const edge = falling ? this.h : 0;
      const g = ctx.createLinearGradient(0, edge, 0, falling ? this.h - height : height);
      // Warmer and brighter than the strand's, because this one is fire rather
      // than water closing - the same [255,104,92] the three predators are
      // allowed, met here as the air instead of as an animal.
      g.addColorStop(0, `rgba(255,${Math.round(120 - 40 * hot)},92,${(0.06 + hot * hot * 0.4).toFixed(3)})`);
      g.addColorStop(1, 'rgba(255,120,92,0)');
      ctx.fillStyle = g;
      ctx.fillRect(0, falling ? this.h - height : 0, this.w, height);
    }

    if (debug.showStats) {
      // Twenty pixels lower than it used to sit, to leave the attempt marks the
      // row they are drawn on. `?debug=1` is the only thing that sees this.
      ctx.font = '500 11px ui-monospace, monospace';
      ctx.fillStyle = 'rgba(160,255,200,0.75)';
      ctx.fillText(`${fps.toFixed(0)} fps`, x, y + 76);
      ctx.fillText(`spread ${world.swarm.spread().toFixed(0)}`, x, y + 90);
      ctx.fillText(`mass ${world.massFactor.toFixed(2)}`, x, y + 104);
      ctx.fillText(`zone ${world.zone} · ${world.predators.predators.length} hunters`, x, y + 118);
    }
  }

  /**
   * One act as one vertical run. Unlike the old per-level rail it does not reset
   * inside an act: the marker starts at the act's first station and moves through
   * six station nodes to the arrow at the far end.
   *
   * Slowblue: the rail is drawn along the act's own course direction. It was written
   * when the campaign was two acts and a climb, and every line of it said so - the
   * fill grew upward, the nodes were laid out from the bottom, the chevron pointed
   * up, the counter carried a `↑`, and the two end labels assumed the last station
   * is the highest one. Three of the seven acts fall (`Act.direction === 1`), and
   * on those three the rail drew the journey upside down: act VII printed the
   * trench floor six thousand metres *above* the estuary it starts in, with the
   * fill climbing toward it. `World.direction` is the sign this needs, it has
   * always been on the world, and the HUD readout above already reads it.
   */
  private drawProgress(world: World, dt: number): void {
    const ctx = this.ctx;
    const stationProgress = clamp(world.levelProgress, 0, 1);
    const stations = this.levels.length;
    const p = clamp((world.levelIndex + stationProgress) / stations, 0, 1);
    const x = this.w - 9 - this.insets.right;
    /*
     * A quarter of the way down the glass, but never up into the corner the
     * buttons and the streak badge already own.
     *
     * The rail is proportional and everything else in that corner is not: the two
     * buttons are a fixed stack under the top inset and the badge hangs on the
     * column line under them, so a short enough window brings the rail up into
     * both. Measured on the shipped build, the counter's ink crosses the mixer
     * button's bottom edge below 480 CSS pixels of height - and an iPad window is
     * resizable, which no phone screen this was written for ever was. Half a
     * 12.9" landscape window is 512, half an 11" is 417.
     *
     * This is the third thing standing in that corner: the badge was given the
     * column line when the mixer button appeared under the pause button, and the
     * rail never got the memo. Flooring the top rather than dropping the counter,
     * because between a proportional element and a fixed one it is the
     * proportional one that should yield - at the 320 px floor `main.ts` clamps
     * to, this still leaves 98 px of rail and 16 between the six station nodes.
     *
     * The badge's row is part of the floor and that was learned the hard way: a
     * floor of `HUD_COLUMN_TOP + COUNTER_RISE` clears the buttons and puts the
     * counter on exactly the badge's own line, which is a collision with `×1.00`
     * bought with a collision with a speaker icon. Measured at 1024x400: 23 px of
     * overlap across, 9 down.
     */
    const top =
      this.insets.top + Math.max(this.h * 0.25, HUD_COLUMN_TOP + STREAK_ROW + COUNTER_RISE);
    const bottom = this.h * 0.78;
    this.railCounterTop = top - COUNTER_RISE;
    /*
     * Which end of the rail this act starts from.
     *
     * Slowblue: the rail anchored everything on `bottom` - the fill, the six nodes,
     * the head and the chevron all grew upward, because up was the only way
     * anything went when this was written. Three acts fall (`direction: 1`; see
     * `CourseDirection` in `config/levels`), and on those three the route begins
     * at the *top* of the rail and works down. One signed pair here rather than
     * an `if (descending)` at each of the four places that put something on the
     * rail, for the same reason `World.u()` exists: four branches agreeing is not
     * something a reader can check by looking.
     */
    const from = world.direction < 0 ? bottom : top;
    const to = world.direction < 0 ? top : bottom;
    const reach = to - from;
    const tint = this.paint.tracer;
    const contrast = 0;
    /*
     * A broken streak cools the rail for a moment instead of drawing a red line
     * over the water: the feedback lands in the one element that is already about
     * how the run is going. That part of the design is unchanged; what changed is
     * that it now happens.
     *
     * It used to read `warm * (1 - streakFade)`, and it could not do anything at
     * all: `RunState.noteLoss` sets the streak to zero in the same step it reports
     * the break, so the warmth this was fading out was already nought by the frame
     * the renderer heard about it. The fade therefore has to come off the rail's
     * own brightness, which is the one number a break can still move - and the dip
     * is deep and short, three quarters of the line's alpha given back over about
     * two thirds of a second.
     *
     * It is a thin thing on purpose and it measures like one: the rail is under
     * two pixels wide, so `e2e/response.spec.ts`'s block pass cannot see it at any
     * brightness and the spec aims a strip at the rail's own columns instead.
     */
    this.streakFade = Math.max(0, this.streakFade - dt * 1.4);
    const cool = this.streakFade;
    const warm = clamp(world.run.streak / 8, 0, 1);

    // The unbroken route, then the water already covered. It fills along the
    // course - upward on the four acts that climb, downward on the three that fall.
    ctx.strokeStyle = rgba(tint, 0.1 + contrast);
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x, top);
    ctx.lineTo(x, bottom);
    ctx.stroke();

    ctx.strokeStyle = rgba(
      brighten(tint, warm * 0.5),
      (0.34 + warm * 0.22) * (1 - cool * 0.75) + contrast,
    );
    ctx.lineWidth = 1.8;
    ctx.beginPath();
    ctx.moveTo(x, from);
    ctx.lineTo(x, from + reach * p);
    ctx.stroke();

    // Six destination nodes. The act's last station is the wide one, and it sits
    // at the far end of the rail rather than always at the top of it: the surface
    // in act I, the Karman line in act III, the trench floor again in act VII.
    for (let i = 1; i <= stations; i++) {
      const ty = from + (reach * i) / stations;
      const done = i / stations <= p + 1e-6;
      const radius = i === stations ? 3.2 : 2;
      ctx.fillStyle = rgba(tint, done ? 0.52 + contrast : 0.12 + contrast);
      ctx.beginPath();
      ctx.arc(x, ty, radius, 0, TAU);
      if (done) ctx.fill();
      else {
        ctx.strokeStyle = rgba(tint, i === stations ? 0.3 + contrast : 0.14 + contrast);
        ctx.lineWidth = 1;
        ctx.stroke();
      }
    }

    // The shoal's head on the route.
    const hy = from + reach * p;
    ctx.fillStyle = rgba(brighten(tint, 0.4), 0.6 + contrast);
    ctx.beginPath();
    ctx.arc(x, hy, 2.4, 0, TAU);
    ctx.fill();

    // A small chevron on the far end of the rail, pointing along the course: it
    // makes the direction readable even before the fill moves. Up for the four
    // acts that climb, down for the three that fall - and on those three it sits
    // at the bottom, because that is where the act is going.
    ctx.strokeStyle = rgba(brighten(tint, 0.25), 0.42 + contrast);
    ctx.lineWidth = 1.2;
    const barb = to - world.direction * 5;
    ctx.beginPath();
    ctx.moveTo(x - 3.5, barb);
    ctx.lineTo(x, to);
    ctx.lineTo(x + 3.5, barb);
    ctx.stroke();

    ctx.save();
    ctx.textAlign = 'right';
    ctx.font = '600 9px ui-sans-serif, system-ui, sans-serif';
    ctx.fillStyle = rgba(tint, 0.32 + contrast);
    // The same claim the HUD arrow makes, in the rail's own lighter weight.
    const arrow = world.direction < 0 ? '↑' : '↓';
    ctx.fillText(
      `${arrow} ${String(world.levelIndex + 1).padStart(2, '0')}/${stations}`,
      x + 2,
      top - COUNTER_RISE,
    );
    ctx.font = '500 8px ui-sans-serif, system-ui, sans-serif';
    ctx.fillStyle = rgba(tint, 0.24 + contrast);
    // The rail's two end labels are the act's own extremes, placed by the act's
    // own direction. Four acts climb, and for those the last station is the top
    // one - act I runs 6000 m up to the surface, act II the surface up to the
    // tropopause - which is what this always drew. Three acts fall, and for those
    // it is the other way round: act VII opens in the estuary at 20 m and ends on
    // the trench floor at 6000 m, and a trench floor belongs at the bottom of a
    // rail rather than six thousand metres above the water it started in.
    const fmt = (m: number): string => `${Math.abs(m).toLocaleString('en-US')} m`;
    const first = this.levels[0]!.depthMeters;
    const last = this.levels[this.levels.length - 1]!.depthMeters;
    ctx.fillText(fmt(world.direction < 0 ? last : first), x + 2, top + 13);
    ctx.fillText(fmt(world.direction < 0 ? first : last), x + 2, bottom + 12);
    ctx.restore();
  }

  /** The multiplier badge. Only on screen while it is worth something. */
  /**
   * What the act attempt has left, in the top-left corner, and only once it has
   * lost something.
   *
   * Slowblue: an act is one attempt with two station restarts in it
   * (`sim/Failure.ts`), and a budget the player cannot see is a budget that
   * arrives as a surprise - the third failure would end an act with no warning
   * that the first two had been counted. So it is drawn. But it follows the same
   * rule as the streak badge, for the same reason: **nothing appears while there
   * is nothing to say.** A player who has not failed sees empty water, which is
   * every player for most of every act, and the corner stays as clean as it was.
   *
   * Two marks rather than a number, because two is a quantity a glance reads and
   * a numeral is a thing you have to interpret. Spent ones stay drawn as outlines:
   * "one left of two" is the fact, and a mark that vanished would only say "one".
   * The last one runs warm, because at that point the next mistake is the act.
   */
  private drawAttempts(world: World, x: number, top: number): void {
    const total = this.attemptsTotal;
    const left = clamp(Math.round(world.restartsLeft), 0, total);
    // Nothing spent, nothing to say - and nothing at all in water that cannot be
    // lost, or in a run that is not an act attempt, where the idea does not apply.
    if (total === 0 || left >= total || world.failureMode === 'none') return;
    const ctx = this.ctx;
    const warm = left <= 1;
    const r = 3;
    for (let i = 0; i < total; i++) {
      const cx = x + r + i * (r * 2 + 6);
      const spent = i >= left;
      ctx.beginPath();
      ctx.arc(cx, top + r, r, 0, TAU);
      if (spent) {
        ctx.strokeStyle = 'rgba(216,251,255,0.22)';
        ctx.lineWidth = 1;
        ctx.stroke();
      } else {
        ctx.fillStyle = warm ? 'rgba(255,196,150,0.78)' : 'rgba(216,251,255,0.6)';
        ctx.fill();
      }
    }
  }

  private drawStreak(world: World, right: number, top: number): void {
    const run = world.run;
    this.streakBadgeBottom = 0;
    if (run.streak <= 0) return;
    const ctx = this.ctx;
    // Pops on change, then settles: the badge must be noticed exactly once per step.
    const pop = clamp(1 - run.sinceStreakChange / 0.45, 0, 1);
    const size = 12 + pop * 4;
    this.streakBadgeBottom = top + size;
    ctx.font = `700 ${size.toFixed(1)}px ui-sans-serif, system-ui, sans-serif`;
    const heat = clamp(run.streak / 8, 0, 1);
    ctx.fillStyle = `rgba(${Math.round(180 + 75 * heat)},${Math.round(250 - 40 * heat)},${Math.round(255 - 120 * heat)},${(0.55 + 0.4 * pop).toFixed(2)})`;
    ctx.fillText(`×${run.multiplier.toFixed(2)}`, right, top);
  }

  private drawLevelBanner(dt: number): void {
    this.bannerLife -= dt;
    drawBanner({
      ctx: this.ctx,
      w: this.w,
      h: this.h,
      levels: this.levels,
      index: this.bannerLevel,
      life: this.bannerLife,
      final: this.bannerFinal,
      dark: this.bannerDark,
    });
  }

  /** How far the frame has been taken off the live world by whatever is running. */
  private get veil(): number {
    let most = 0;
    for (const [, film] of this.films) {
      if (film.active && film.veil > most) most = film.veil;
    }
    return most;
  }

  /**
   * Everything a film needs from the renderer, which is one point.
   *
   * The whole of what this function decides is *where the swarm is*, because
   * every ending in the campaign happens where the player left their life rather
   * than in the middle of the screen: the surface breaks over the shoal, the
   * flock lets go where it stopped, the gold stalls above where it was thrown,
   * and the trench floor is lit by the motes that actually landed on it. The band
   * it is allowed to sit in belongs to the film - the surfacing needs a sky above
   * it, the overview needs a planet below it - so the film states its own and
   * this only clamps.
   */
  private drawFilm(world: World, film: Film): void {
    const c = world.swarm.centroid(MAIN_FACTION);
    const [lo, hi] = film.anchor;
    const x = c.count > 0 ? c.x : this.w * 0.5;
    const y =
      c.count > 0
        ? clamp(world.viewY(c.y), this.h * lo, this.h * hi)
        : this.h * (lo + hi) * 0.5;
    film.draw({
      ctx: this.ctx,
      paint: this.paint,
      w: this.w,
      h: this.h,
      time: this.clock,
      x,
      y,
      breath: this.breath,
      quality: this.style.quality,
    });
  }

  private drawHint(dt: number): void {
    const ctx = this.ctx;
    this.hintPhase += dt * 0.55;
    const t = this.hintPhase % 1;
    const cx = this.w * 0.5;
    const cy = this.h * 0.42;
    const rx = this.w * 0.26;
    const a = this.hintAlpha * Math.sin(Math.min(1, t * 1.6) * Math.PI) * 0.55;
    if (a <= 0) return;
    ctx.strokeStyle = `rgba(214,248,255,${a.toFixed(3)})`;
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let i = 0; i <= 24; i++) {
      const p = (i / 24) * t;
      const px = cx - rx + p * rx * 2;
      const py = cy + Math.sin(p * Math.PI) * -26;
      if (i === 0) ctx.moveTo(px, py);
      else ctx.lineTo(px, py);
    }
    ctx.stroke();
    const hx = cx - rx + t * rx * 2;
    const hy = cy + Math.sin(t * Math.PI) * -26;
    ctx.fillStyle = `rgba(230,252,255,${(a * 1.4).toFixed(3)})`;
    ctx.beginPath();
    ctx.arc(hx, hy, 7, 0, TAU);
    ctx.fill();
  }

  private drawFieldVectors(world: World): void {
    const ctx = this.ctx;
    const f = world.field;
    ctx.strokeStyle = 'rgba(120,255,190,0.5)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let cy = 0; cy < f.rows; cy++) {
      const wy = f.originY + (cy + 0.5) * f.cell;
      const sy = world.viewY(wy);
      if (sy < -f.cell || sy > this.h + f.cell) continue;
      for (let cx = 0; cx < f.cols; cx++) {
        const sx = (cx + 0.5) * f.cell;
        world.water.sample(sx, wy, this.sample);
        const m = Math.hypot(this.sample.x, this.sample.y);
        if (m < 2) continue;
        const s = Math.min(f.cell * 0.9, m * 0.06) / m;
        ctx.moveTo(sx, sy);
        ctx.lineTo(sx + this.sample.x * s, sy + this.sample.y * s);
      }
    }
    ctx.stroke();
  }

  private drawHash(world: World): void {
    const ctx = this.ctx;
    const cs = world.swarm.hash.cellSize;
    ctx.strokeStyle = 'rgba(255,120,220,0.35)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (const c of world.swarm.hash.debugCells()) {
      const sy = world.viewY(c.cy * cs);
      if (sy < -cs || sy > this.h + cs) continue;
      ctx.rect(c.cx * cs, sy, cs, cs);
    }
    ctx.stroke();
  }
}
