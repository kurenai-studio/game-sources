import {
  ACT_WATER,
  levelAtIn,
  levelOfSectionIn,
  levelStartSectionIn,
  type Act,
} from '../config/levels';
import { DEFAULT_TUNING, cloneTuning, type Tuning } from '../config/tuning';
import { clamp } from '../core/math';
import { MAIN_FACTION, type Agent } from './Agent';
import { AmbientFlow } from './AmbientFlow';
import { CurrentField } from './CurrentField';
import type { FailureMode } from './Failure';
import { FlowField } from './FlowField';
import { LayeredFlow } from './LayeredFlow';
import { blendMedium, mediumFor, type Medium } from './Medium';
import { ObstacleSystem, SECTION_SPACING, type HunterHint } from './ObstacleSystem';
import { PotentialField } from './PotentialField';
import { PredatorSystem } from './PredatorSystem';
import { RescueSystem } from './RescueSystem';
import { RunState, failureThreshold } from './RunState';
import type { Threat } from './SwarmSimulation';
import { SwarmSimulation, type SwarmContext, type WaterSampler } from './SwarmSimulation';

export type SimEventType =
  | 'loss'
  | 'rescue'
  | 'gate'
  | 'fail'
  | 'reform'
  | 'bite'
  // There was a `streak` here, between these two, and nothing in the game has
  // ever pushed one or listened for one. It went when the union stopped being a
  // list of names and became the thing `tests/response.test.ts` holds both
  // switches to: a member nobody emits is a member every exhaustiveness check has
  // to be told to ignore.
  | 'streakBreak'
  | 'zone'
  /** A new authored level begins. `value` is its index. */
  | 'level'
  /** A required ring was absorbed. */
  | 'ring'
  /** ...or left behind, which ends the dive. */
  | 'ringLost'
  /** The last section of the last level was cleared. */
  | 'complete'
  /** A station began again instead of the run ending. `value` is its index. */
  | 'restart';

export interface SimEvent {
  type: SimEventType;
  x: number;
  y: number;
  value: number;
}

export interface WakeSample {
  x: number;
  y: number;
  dx: number;
  dy: number;
  life: number;
  strength: number;
}

/**
 * Camera keeps the swarm here vertically, as a fraction of the screen measured
 * from the *trailing* edge - the bottom on a climb, the top on a descent.
 *
 * One fraction rather than two, because the composition is the same picture
 * either way round: most of the frame is what is coming, a third of it is what
 * has been left, and the body of life sits on the line between them.
 */
const CAMERA_ANCHOR = 0.62;
/**
 * How much faster than the water the *drawn* camera may close on the simulated
 * one, as a multiple of the drift. See `advanceView` for what it is for and for
 * the measurements behind the number.
 */
const CAMERA_CATCH_UP = 3;
/**
 * How far *outside* the frame course geometry is still kept, in px.
 *
 * `RockPaint` culls a mass 90px off screen, so this is a shade wider on purpose:
 * the painter is what decides an obstacle has been seen for the last time, and
 * the simulation never takes that decision away from it.
 */
const COURSE_CULL_PAD = 120;
const FLOW_CELL = 24;
const FLOW_MARGIN_CELLS = 3;
const WAKE_LIFE = 0.42;
/** Mean distance from the centroid that counts as "the shoal is in two pieces". */
const SPLIT_SPREAD = 112;
/** ...and the value it must come back under to count as re-formed. */
const REFORM_SPREAD = 78;
/**
 * Only archetypes with a central mass to go round can pay a split-and-reform.
 *
 * The rule, rather than the list: **one axial mass with a channel either side**.
 * Every act that has such a shape is in here, because the verb belongs to the
 * shape and not to the act that happens to own it.
 *
 * Slowblue: this was every section. A panicking shoal sits near the split threshold all
 * run, so it crossed and re-crossed by accident on funnels and chicanes - the
 * scripted panic-flicker banked as many re-form bonuses as the bot that split on
 * purpose, which turns the bonus into a reward for losing control. Widening the
 * spread thresholds instead killed the deliberate tactic too; restricting *where*
 * a split counts leaves the verb intact and takes the accident away.
 *
 * Slowblue, later and worse: the restriction was written as a list of the four kinds
 * that existed when it was written, and the campaign then grew three more masses
 * that meet the rule exactly - `column` in the upper air, `plume` in the plasma,
 * `canopy` in the forest. All three are authored with a ring in *each* channel and
 * one of them says in its own comment that the far ring is "the reward for having
 * split cleanly". Nothing paid it. Measured before this line changed: the far
 * channel was absorbed 0 times in eleven runs at the aurora's plume, 0 in ten at
 * the plasma's and 0 in nine at the meteor dust's, and act V banked 0.18 reforms a
 * run, every one of them on the nucleus `tower` - the one splittable mass it
 * borrows from act II.
 *
 * `bloom` stays out and its reason is written where it is authored: a medusa
 * swarm is meant to be drifted *through*, not split on. `hulk` stays out because
 * no station authors one.
 */
const SPLITTABLE: ReadonlySet<string> = new Set([
  'rock',
  'predator',
  'tower',
  'raptor',
  'column',
  'plume',
  'canopy',
  // Slowblue: `hulk` used to be excluded on the honest technicality that no station
  // authored one. Act V's deorbit does now - a ring in each channel, one of them
  // compulsory - so it is the same object as everything else in this list and
  // leaving it out would have made the deorbit the one splittable mass in the
  // campaign that pays nothing for being split.
  'hulk',
]);
/** How far past a section the shoal still gets credit for re-forming on it. */
const REFORM_TRAIL = 520;
/** Radius (px) and velocity kick (px/s) of the panic a rock strike sends outward. */
const PANIC_RADIUS = 34;
const PANIC_KICK = 55;
/** What the sweeps' generated water counts as, so the level knobs stay neutral. */
const GENERATED_LEVEL = { pace: 1, roughness: 1, swirl: 1 };
/** Drift multiplier while the shoal is working an unheld required ring. */
const RING_EASE = 0.3;
/** How close the shoal has to be, in px, for the ocean to ease off. */
const RING_EASE_REACH = 300;

/**
 * Slowblue: the whole simulation, headless. No canvas, no DOM, no timers.
 * Everything the renderer needs is readable state; everything the loop needs is
 * `step(dt)`. That split is what makes seed replay and unit tests possible.
 */
export class World {
  width: number;
  height: number;
  tuning: Tuning;
  seed: number;

  field: FlowField;
  ambient: AmbientFlow;
  currents = new CurrentField();
  /**
   * Act IV's input. Empty in every other act, because `Medium.vacuum` is zero
   * there and `injectStroke` never lays anything into it.
   */
  potential = new PotentialField();
  /** Act III's banded upper air. Inert unless a station authors `layers`. */
  layers = new LayeredFlow();

  /**
   * The clock the breath is read from, in seconds.
   *
   * Slowblue: this is deliberately *not* `run.time`, and the difference matters for
   * exactly one system. The breath is addressed to the player rather than to the
   * swarm (see `sim/Breath.ts`), so it runs on wall-clock time - it keeps going
   * over a pause, over an ending and on the title screen, and `main.ts` overwrites
   * this field from that clock every frame so the picture, the audio bed and act
   * III's gravity wave are provably the same phase rather than three clocks that
   * agree at the start of a session.
   *
   * Headless - the tests and the sweeps - never overwrites it, so it advances
   * with the simulation and everything stays deterministic and replayable.
   */
  breathTime = 0;

  /** Which level the layer stack was last configured for. */
  private layerLevel = -1;
  swarm: SwarmSimulation;
  obstacles: ObstacleSystem;
  rescue = new RescueSystem();
  predators = new PredatorSystem();
  run = new RunState();

  /**
   * Slowblue: the single source of truth for "how fast is the water here".
   * The player's currents, the ocean's own current, and the standing currents the
   * course lays down. Everything that needs water - the swarm, the hunters, the
   * tracer particles, the debug overlay - goes through this one sampler, which is
   * why nothing in the game can tell whose water is pushing it.
   */
  readonly water: WaterSampler = {
    sample: (x, y, out) => {
      this.field.sample(x, y, out);
      this.ambient.addTo(x, y, this.run.time, this.currentAmbientStrength, out);
      this.currents.addTo(x, y, out, this.tuning.vortexStrength * this.level.swirl);
      // Act III's banded air. Zero everywhere else, because no other station
      // authors layers - so this line costs one null check per sample in every
      // act that is not the upper atmosphere.
      //
      // Deliberately *not* scaled by `roughness`. Those are two different things
      // and conflating them cost a whole balance pass: `roughness` is how noisy
      // the medium is, and the layers are how it is *organised*. A station wants
      // to say "the wind here is 72 px/s going right" in px/s, not as a fraction
      // of a turbulence dial - and the first version, which multiplied the two,
      // shipped 150 px/s crosswinds that no stroke could hold a line against.
      this.layers.addTo(x, y, this.breathTime, 1, out);
    },
  };

  /** Rebuilt each step from the live hunters; the swarm only sees positions. */
  private threats: Threat[] = [];

  cameraY = 0;
  /**
   * Where the camera was before the step that is currently being drawn - the other
   * end of the interpolation the drawing reads through `viewCameraY`.
   *
   * Not a rendering detail that leaked into the simulation: this is one half of a
   * state the sim owns, and the fish already keep the same pair (`px`, `py`). It
   * only exists here because nothing outside can reconstruct it.
   */
  prevCameraY = 0;
  /** Individuals the run started with; the mass model measures growth from here. */
  startCount = 0;
  events: SimEvent[] = [];
  wake: WakeSample[] = [];
  /** Simulated seconds since the last gesture sample. Drives the idle hint. */
  sinceInput = Infinity;
  hasInput = false;
  gestureCount = 0;
  gestureLengthTotal = 0;

  private contentSpawned = new Set<number>();
  /**
   * Stooping hunters that have been armed and not yet released. See
   * `spawnDueContent` for why they cannot be spawned with everything else, and
   * `releaseStoops` for when they are.
   */
  private pendingStoops: (HunterHint & { sectionId: number; order: number })[] = [];
  private spreadAccum = 0;
  private spreadSamples = 0;
  /** Section id the shoal is currently split on, if any. */
  private splitOnSection: number | null = null;

  /** False only for the headless sweeps, which measure on generated water. */
  readonly campaign: boolean;

  /**
   * Which act's script this world plays. Act I unless the ascent says otherwise.
   *
   * Swappable only through `setAct`, and only between runs: the act decides what
   * every section on the course is, so changing it under a live course would leave
   * the list holding sections from a script that no longer exists.
   */
  act: Act;

  /**
   * Script index this run was started at. Zero in every real run; the admin
   * surface sets it to drop the player straight onto one section.
   */
  startSection = 0;

  /**
   * How many individuals this run opens with, or null for the tuned default.
   *
   * The campaign sets it: an act opens with what the previous one handed over,
   * which is the only mechanical statement the whole game makes of its premise.
   * Clamped by `CampaignController.population` before it gets here, so a player
   * who has collected four hundred motes still arrives with a swarm the phone
   * can draw - see the note on population scaling in `meta/Campaign.ts`.
   */
  startPopulation: number | null = null;

  /**
   * How many station restarts this run opens with, and how many are left.
   *
   * Set from outside before `reset`, exactly as `startPopulation` is, and
   * unbounded until something sets it - because the budget is a *campaign* rule
   * and not a fact about water. Two restarts per act attempt is what
   * `sim/Failure.ts` states and what `CampaignController.attemptsLeft` remembers
   * across an interruption; `main.ts` hands the number down at `startRun`, and the
   * world's only job is to spend it.
   *
   * The default is what everything that is not flying a circuit gets: the `?act=`
   * door, an admin jump, and the headless probes. That is deliberate for the
   * probes above all. They are fixed-time instruments - give two policies the same
   * T seconds and compare - and a rule that *ends* a run turns T into a variable,
   * which does not measure the game better, it removes the control variable from
   * every comparison in the suite. The simulation is what they are for, and the
   * simulation is not what changed.
   */
  restartBudget = Infinity;
  /** What is left of it. Reset from `restartBudget` by every `reset`. */
  restartsLeft = Infinity;

  constructor(
    width: number,
    height: number,
    seed: number,
    tuning: Tuning = DEFAULT_TUNING,
    campaign = true,
    act: Act = ACT_WATER,
  ) {
    this.width = width;
    this.height = height;
    this.seed = seed;
    this.tuning = cloneTuning(tuning);
    this.act = act;
    this.field = new FlowField(width, height, FLOW_CELL, FLOW_MARGIN_CELLS);
    this.ambient = new AmbientFlow(seed, width);
    this.swarm = new SwarmSimulation(seed);
    this.obstacles = new ObstacleSystem(width, seed, campaign, act);
    this.campaign = campaign;
    this.reset(seed);
  }

  /**
   * Points this world at another act. Takes effect at the next `reset`, and takes
   * the obstacle system with it - the two must never disagree about which script
   * a section id indexes into.
   */
  setAct(act: Act): void {
    this.act = act;
    this.obstacles.act = act;
  }

  reset(seed = this.seed, startSection = 0): void {
    this.seed = seed;
    this.startSection = startSection;
    this.restartsLeft = Math.max(0, this.restartBudget);
    this.field.clear();
    this.field.originY = 0;
    this.ambient = new AmbientFlow(seed, this.width);
    this.currents.reset();
    this.potential.reset();
    this.layers.set(null, 0);
    this.layerLevel = -1;
    this.swarm.reset(seed);
    this.obstacles.reset(this.width, seed, startSection);
    this.rescue.reset();
    this.predators.reset();
    this.run.reset();
    this.contentSpawned.clear();
    this.pendingStoops.length = 0;
    this.threats = [];
    this.events = [];
    this.wake = [];
    this.sinceInput = Infinity;
    this.hasInput = false;
    this.gestureCount = 0;
    this.gestureLengthTotal = 0;
    this.spreadAccum = 0;
    this.spreadSamples = 0;
    this.splitOnSection = null;
    // The drift multiplier, cleared - which it always should have been. It survived a
    // reset, so a restart of "the same water" could open with the eased drift the
    // *previous* run's last ring left behind. Measured on the playability probe, the
    // numbers do not move; correctness, not balance.
    this.ringEase = 1;
    this.heat = 0;
    this.overTerminal = 0;
    this.courseSpeed = 0;
    this.ablating = 0;
    this.lastCourseU = null;
    this.cameraY = -this.height * this.anchorFraction;
    // A jump, not a step: nothing may interpolate across it, and nothing may ease
    // into it either.
    this.prevCameraY = this.cameraY;
    this.drawCameraY = Number.NaN;
    this.field.shiftTo(this.cameraY - FLOW_MARGIN_CELLS * FLOW_CELL);
    this.swarm.spawnShoal(
      Math.round(this.startPopulation ?? this.tuning.agentCount),
      this.width * 0.5,
      0,
      Math.min(this.width, this.height) * 0.11,
    );
    this.startCount = this.swarm.aliveCount(MAIN_FACTION);
    this.run.peakCount = this.startCount;
    this.obstacles.ensureAhead(this.buildLine);
    this.spawnDueContent();
  }

  /** How far ahead of the camera the course is built. */
  private get buildLine(): number {
    return this.cameraY + this.act.direction * this.height * 1.6;
  }

  /**
   * The world Y at the trailing edge of the live band: past this, sections,
   * rings, hunters and standing currents are gone. The camera keeps a whole
   * screen of what has been left behind on a climb; the same, mirrored, falling.
   */
  private get behindLine(): number {
    return this.cameraY + this.height * (this.act.direction < 0 ? 0.9 : 0.1);
  }

  /**
   * The second, later line: where a section stops being *drawn*, which is the
   * trailing edge of the screen itself plus the painter's own margin.
   *
   * Slowblue: obstacles left the world on `behindLine` with everything else, and
   * `behindLine` sits a tenth of a screen *inside* the frame - it is a line about
   * the shoal, not about the picture. So a rock the water was still carrying down
   * was deleted with a good fifth of the frame under it, and the player watched
   * the course blink out instead of swim out.
   *
   * It cannot be fixed by moving `behindLine`: that line is what keeps rocks from
   * living on behind the shoal, steering it and culling stragglers that used to
   * swim free, and the act I canary in `tests/playability.test.ts` measures the
   * difference to nine digits. So the section still leaves the course exactly when
   * it always did, and only its picture stays - see `ObstacleSystem.retired`.
   *
   * Rings, hunters and standing currents keep the single line, where their timing
   * is authored rather than incidental: a required ring has to be lost while it is
   * still in shot, because losing it is what ends the dive.
   */
  private get courseCullLine(): number {
    return this.act.direction < 0
      ? this.cameraY + this.height + COURSE_CULL_PAD
      : this.cameraY - COURSE_CULL_PAD;
  }

  /**
   * Slowblue: a resize rescales the world horizontally instead of just widening it.
   *
   * Rotating the phone, or an iOS URL bar collapsing, used to leave the shoal and
   * the course at their old absolute X - which on a narrower viewport means the
   * shoal is now inside a wall and gets flung across the screen. Everything with an
   * X is scaled by the same ratio, so the run survives the reflow intact and the
   * course keeps its proportions.
   */
  resize(width: number, height: number): void {
    const ratio = this.width > 0 ? width / this.width : 1;
    const wasHeight = this.height;
    this.width = width;
    this.height = height;
    this.obstacles.width = width;
    this.ambient.width = width;
    if (ratio !== 1) {
      for (const a of this.swarm.agents) {
        a.x *= ratio;
        a.px *= ratio;
        a.vx *= ratio;
        a.anchorX *= ratio;
        a.anchorRadius *= ratio;
      }
      for (const p of this.rescue.pods) {
        p.x *= ratio;
        p.radius *= ratio;
      }
      for (const p of this.predators.predators) {
        p.x *= ratio;
        p.homeX *= ratio;
      }
      for (const v of this.currents.vortices) {
        v.x *= ratio;
        v.radius *= ratio;
      }
      // Retired sections too: they are off the course but still on screen, and a
      // reflow that rescaled everything except them would visibly wrench the last
      // rock sideways on its way out of the frame.
      //
      // ...and the hints beside the rocks, which is the half this forgot. A section
      // is built long before it is reached and carries where its rings, hunters,
      // currents and wells go; those coordinates were left at the old width, so a
      // section built in portrait and *entered* in landscape put its content where
      // the portrait screen had been. Rotating the other way is the one that costs
      // a run: a hint at x = 1180 in an 820-wide world spawns its ring off the right
      // edge, and a required ring that leaves the frame un-absorbed ends the dive
      // (`ringLost`, `endOrRestart`). Radii follow their live counterparts - the
      // vortex and the well have one and it scales, the hunter's `size` does not,
      // because a live predator's does not either.
      for (const list of [this.obstacles.sections, this.obstacles.retired]) {
        for (const s of list) {
          for (const b of s.blobs) {
            b.x *= ratio;
            b.r *= ratio;
            // A moving blob is positioned from its home rather than from where it
            // is, so the home has to come along or the next frame drags the rock
            // back to where the portrait screen had been. Same bug as the one the
            // silhouette cache had, one layer down. See `Blob.hx`.
            if (b.hx !== undefined) b.hx *= ratio;
          }
          for (const b of s.envelope) {
            b.x *= ratio;
            b.r *= ratio;
          }
          if (s.motion !== null) s.motion.reach *= ratio;
          for (const p of s.podHints) p.x *= ratio;
          for (const h of s.hunterHints) h.x *= ratio;
          for (const v of s.vortexHints) {
            v.x *= ratio;
            v.radius *= ratio;
          }
          for (const w of s.wellHints) {
            w.x *= ratio;
            w.radius *= ratio;
          }
        }
      }
      this.obstacles.refreshActive();
      for (const w of this.wake) w.x *= ratio;
    }
    /*
     * A turn of the device may not change how far behind the shoal is.
     *
     * Everything that decides what is still part of the run is a fraction of the
     * SCREEN - `behindLine` at 0.9 of it, the strand line the run ends on, the
     * camera's own anchor - so a frame that loses a third of its height moves the
     * shoal down the glass unless the camera moves with it. That is the whole of
     * the iPad rotation bug, and it is worse than it looks: measured on the
     * shipped build at 820x1180, one rotation to landscape threw the shoal from
     * 0.62 of the frame to 0.90, which is `behindLine` itself. On that line the
     * course retires *around the shoal* into `retired`, where a rock is still
     * drawn and no longer collides or steers - "the obstacles stopped affecting
     * the shoal", exactly as it was reported - stragglers are culled at the
     * trailing edge, and rings drop off the back. Three rotations cost ten fish
     * and two rings in a headless run nobody was playing.
     *
     * The shoal's own fraction rather than the anchor's, and that distinction is
     * the whole of the second attempt at this: holding the anchor is right only
     * while the shoal is on it, and a shoal that has fallen behind - the one case
     * where any of this can end a run - is precisely the one that is not.
     *
     * The follow in `step` cannot do it, and deliberately: it is monotone (`u`),
     * so it only ever moves the camera *forward* along the course, and reframing
     * after a shrink asks it to go back. A resize is not the run rewinding, it is
     * the same water in a different window, so the camera is set here rather than
     * left to the rule that exists to stop it rewinding.
     */
    if (wasHeight > 0 && height !== wasHeight) {
      const c = this.swarm.centroid(MAIN_FACTION);
      if (c.count > 0) this.cameraY = c.y - height * ((c.y - this.cameraY) / wasHeight);
      // Nothing to hold the frame on: keep the anchor line where it was, which is
      // where the next live centroid would put it anyway.
      else this.cameraY += (wasHeight - height) * this.anchorFraction;
      // Re-anchoring is a jump, and a jump is the one thing the frame between two
      // steps must not smooth: interpolating across it - or easing into it - would
      // draw the reframing as a slide back down the course, which is the very
      // motion this reframing exists to prevent.
      this.prevCameraY = this.cameraY;
      this.drawCameraY = Number.NaN;
    }
    // A new grid means losing in-flight currents; acceptable, resize is rare - and
    // the origin comes off the camera that was just re-anchored, which is what the
    // next step would set it to anyway.
    this.field = new FlowField(width, height, FLOW_CELL, FLOW_MARGIN_CELLS);
    this.field.originY = this.cameraY - FLOW_MARGIN_CELLS * FLOW_CELL;
  }

  /** Live individuals under player control. */
  get shoalCount(): number {
    return this.swarm.aliveCount(MAIN_FACTION);
  }

  /**
   * Shoal size at which this run ends. Based on the *starting* shoal, not the peak:
   * keying it to the peak would mean rescuing fish raised your own failure bar, which
   * punishes the growth the game is asking for.
   *
   * ...and capped at twice the default shoal, because in a *campaign* the starting
   * shoal is the carried mass. The sentence above is exactly right for one run and
   * quietly false across seven acts: `startCount` is what the last act handed over,
   * so a player who has rescued well arrives at act VII with 96 and a failure bar
   * of 38, against 12 for a player who arrived with 25. That is the peak-keying the
   * paragraph rejects, one act removed - the growth has just been laundered through
   * an act boundary. The cap holds the bar at 19 and leaves every start population
   * up to 50 exactly where it was.
   */
  get failureThreshold(): number {
    return failureThreshold(Math.min(this.startCount, this.tuning.agentCount * 2));
  }

  /** Index of the level being played. */
  get levelIndex(): number {
    for (const s of this.obstacles.sections) if (!s.passed && s.level >= 0) return s.level;
    return this.run.level;
  }

  get level(): { pace: number; roughness: number; swirl: number } {
    return this.campaign ? levelAtIn(this.act, this.levelIndex) : GENERATED_LEVEL;
  }

  /**
   * The medium the current level is played in. Water for every act I level and
   * for the generated sweeps, so the shipped game resolves to the exact tuning
   * fields it always read. Re-resolved on demand: the debug panel edits tuning
   * live, and a cached medium would go quietly stale under it.
   */
  get medium(): Medium {
    if (!this.campaign) return mediumFor('water', this.tuning);
    const level = levelAtIn(this.act, this.levelIndex);
    const from = mediumFor(level.medium ?? 'water', this.tuning);
    if (level.mediumTo === undefined || level.mediumTo === level.medium) return from;
    // A station that names where it ends is a station the medium changes *across*.
    // This is the whole of act V's input handover: gravity gives way to wind over
    // about a minute of play, with no frame on which the rule swapped.
    return blendMedium(from, mediumFor(level.mediumTo, this.tuning), this.levelProgress);
  }

  /**
   * Slowblue: pressure is per level now, not per run.
   *
   * On the endless course this was a single ramp over the whole distance, which is
   * the right shape for a score attack and the wrong one for a campaign: it meant
   * the sixth level was hard because of how long you had been playing rather than
   * because of what was in it, and it meant a player who took the first level
   * slowly arrived at the second one already behind. It resets at every level, so
   * difficulty is a property of the water in front of you and nothing else.
   */
  get pressure(): number {
    if (!this.campaign) {
      return Math.min(2.5, (this.tuning.pressureRamp * this.run.distance) / 10000);
    }
    return Math.min(0.55, this.tuning.pressureRamp * 0.5 * this.levelProgress);
  }

  /**
   * 0..1 through the level currently being played, continuously.
   *
   * Slowblue: this used to step once per section, which is fine for the difficulty
   * ramp that reads it and useless for the rail the HUD draws from it - a progress
   * indicator that jumps in sixths is a counter, not a progress indicator. The
   * fractional part is how far the shoal has closed on the next section's line,
   * measured against the standard spacing, so it advances with the water.
   */
  get levelProgress(): number {
    const index = this.levelIndex;
    const level = this.act.levels[index];
    if (level === undefined) return 0;
    const steps = Math.max(1, level.sections.length);
    for (const s of this.obstacles.sections) {
      if (s.passed || s.level !== index) continue;
      const c = this.swarm.centroid(MAIN_FACTION);
      const toLine = c.count > 0 ? this.u(s.lineY) - this.u(c.y) : SECTION_SPACING;
      const frac = clamp(1 - toLine / SECTION_SPACING, 0, 1);
      return clamp((s.step + frac) / steps, 0, 1);
    }
    // Nothing of this level left in the list: it is finished, or about to be.
    return 1;
  }

  /**
   * Slowblue: the ocean waits at a dashed ring.
   *
   * A required ring asks the player to stop going forward and hold a body of fish
   * still for half a second, while the same forced drift that punishes stalling is
   * running. Measured, that combination killed the scripted player by `sweptAway`
   * on every seed - the game was demanding two opposite things at once. Easing the
   * drift while the shoal is on an unheld ring turns the ring into the one place
   * in the game where time relaxes, which is also exactly how it should feel.
   */
  ringEase = 1;

  /** Forced camera drift right now: the level's own pace, plus its escalation. */
  get currentWorldSpeed(): number {
    return this.tuning.worldSpeed * this.level.pace * (1 + this.pressure) * this.ringEase;
  }

  /**
   * The same drift with the ring's easing taken back out: the pace this station
   * *means*, rather than the pace it happens to be running at this instant.
   *
   * `ringEase` drops the drift to 0.3 while the swarm is working an unheld
   * compulsory ring, which is the one place in the game where time relaxes. The
   * terminal is measured against this rather than against `currentWorldSpeed`,
   * because a terminal that eased with the drift would make a ring the *hottest*
   * place on the course - a swarm arriving at an ordinary pace would be at three
   * times a collapsed terminal, and the game would be burning the player for the
   * one thing it has just slowed down to let them do.
   */
  get driftSpeed(): number {
    return this.tuning.worldSpeed * this.level.pace * (1 + this.pressure);
  }

  /**
   * Slowblue: how far past the medium's terminal the swarm is going, in px/s. Zero
   * in five of the seven media, and therefore in the whole of every act but V.
   *
   * See `Medium.drag` for the player report this answers, the measurement behind
   * it, and why the fix could not be the camera. In one line: the camera takes the
   * greater of its own drift and the swarm's own position, so going faster than
   * the world was free, and the only failure of position in the game was
   * unreachable for anyone who did it.
   */
  overTerminal = 0;
  /**
   * The swarm's own pace along the course, smoothed. Public because it is the
   * honest reading of the reported symptom - "I go faster than the world" is
   * `courseSpeed / driftSpeed`, and `tools/rush.sweep.ts` prints it.
   */
  courseSpeed = 0;
  /**
   * 0..1 for the picture: how far past the terminal the swarm is, capped at one
   * whole terminal over. The renderer draws the frame's leading edge hot on it.
   */
  ablating = 0;
  /** Carriers the medium has taken this run. Reported by `tools/rush.sweep.ts`. */
  ablated = 0;
  /**
   * 0..1, and what it is a fraction of is **one carrier**. It fills while the
   * swarm is over the terminal, drains while it is under, and each time it fills
   * the medium takes the individual furthest out in front. See `updateAblation`.
   *
   * Public because the picture has to show it. A cost the player cannot see
   * coming is attrition, not a demand - which is the same argument the threat
   * ring in `Hunter.ts` is drawn for.
   */
  heat = 0;
  /** Where the centroid was on the course last step, for the speed it made. */
  private lastCourseU: number | null = null;

  /** Mechanical demand rises by station even while the campaign climbs toward light. */
  get currentAmbientStrength(): number {
    return (
      this.tuning.ambientStrength *
      this.level.roughness *
      (1 + this.pressure * this.tuning.ambientRamp)
    );
  }

  get massFactor(): number {
    const extra = Math.max(0, this.shoalCount - this.startCount);
    return 1 + extra * this.medium.inertiaPerAgent;
  }

  get averageSpread(): number {
    return this.spreadSamples === 0 ? 0 : this.spreadAccum / this.spreadSamples;
  }

  /**
   * The zone the player is *in*, which is the next section they have to survive -
   * not the deepest one cleared. The water has to change colour before the new
   * archetype arrives, otherwise the palette is a receipt instead of a warning.
   */
  get zone(): number {
    for (const s of this.obstacles.sections) if (!s.passed) return s.zone;
    return this.run.zone;
  }

  /** Section id the player is currently working on; drives the palette crossfade. */
  get sectionId(): number {
    for (const s of this.obstacles.sections) if (!s.passed) return s.id;
    return 0;
  }

  worldToScreenY(worldY: number): number {
    return worldY - this.cameraY;
  }

  screenToWorldY(screenY: number): number {
    return screenY + this.cameraY;
  }

  /**
   * How far into the pending step the frame being drawn is. 1 means "the state the
   * simulation is in", which is what everything that never calls this gets.
   */
  private viewAlpha = 1;

  /**
   * The frame's own alpha, set once per frame before anything is drawn.
   *
   * The fish have always been interpolated with it - `a.py + (a.y - a.py) * alpha` -
   * and the camera never was, and that is not a small inconsistency: a frame drawn
   * from a camera at step N and fish at step N + alpha is a picture of two different
   * moments. The simulation runs on a fixed 1/60 s step and the display does not
   * hand out frames on that grid, so a frame that runs 0 or 2 steps used to move the
   * whole course by nothing or by double while the shoal moved smoothly through it.
   * That is the "the course jitters but the shoal does not" report, and it needs no
   * dropped frame to show up - a phone holding a clean 60 is enough, because the
   * beat between the display and the accumulator drifts either way.
   */
  setViewAlpha(alpha: number): void {
    this.viewAlpha = alpha;
  }

  /**
   * Where the drawing's camera has got to. `NaN` until a frame establishes it, and
   * reset to `NaN` by anything that moves the camera by hand, so a jump the player
   * is *supposed* to see - a new run, a rotation - is never eased into.
   */
  private drawCameraY = Number.NaN;

  /**
   * The drawn camera closes on the simulated one instead of being it.
   *
   * The anchor is read off the shoal's centroid, and neither the centroid nor the
   * follow that chases it is continuous. Two ways it jumps, and the player meets
   * both: the step that kills the fish at the back moves the centroid forward by
   * everything they were holding it back by, and a shoal steered past the anchor
   * line puts the target in front of a camera that had drifted ahead of it. The
   * monotone follow then closes either gap *in one step*. Measured over three real
   * runs: the ordinary step is 1.6 px and the worst single step was 99.7 px - a
   * twelfth of the screen in a sixtieth of a second. Reported from an iPad as the
   * background surging as the shoal is steered, and it is the more distracting of
   * the two judders because it is tied to the player's own hand.
   *
   * **This is the picture's problem and it is fixed in the picture**, which is not
   * where it was tried first. The same ceiling inside `step` reads beautifully and
   * measurably breaks the game: the rate the course arrives at hangs off this
   * follow, so capping it takes the reward away from the player who earned it -
   * the steering bot's score fell from 1473 to 1209 while the flailing bot's rose
   * from 700 to 984, and no value of the constant left both that probe and the
   * detour-costs-ground claim standing. The camera's *motion* is a picture; the
   * camera's *position* is a rule. Only the first one is eased here.
   *
   * The ceiling is a multiple of the drift rather than a spring, so ordinary
   * follow - the 99th percentile step is 2.62 px against a ~5 px ceiling - is not
   * touched at all and only a discontinuity is spread out. What it costs is stated
   * plainly: for about a third of a second after a big loss the drawing is behind
   * the simulation, up to ~120 px, so the shoal looks a little further ahead than
   * the rules have it. That is the safe direction to be wrong in - the line that
   * ends a run is *behind* the shoal - and it is the same lag any camera in any
   * game has.
   */
  advanceView(alpha: number, dt: number): void {
    this.viewAlpha = alpha;
    const target = this.prevCameraY + (this.cameraY - this.prevCameraY) * alpha;
    const reach = target - this.drawCameraY;
    if (!Number.isFinite(reach)) {
      this.drawCameraY = target;
      return;
    }
    const cap = this.currentWorldSpeed * CAMERA_CATCH_UP * dt;
    this.drawCameraY += Math.abs(reach) <= cap ? reach : Math.sign(reach) * cap;
  }

  /**
   * The camera as the *drawing* sees it. The simulation keeps reading `cameraY`.
   *
   * Falls back to the interpolated simulation camera when no frame has run
   * `advanceView` - which is every headless test, every sweep and the screenshot
   * pass, and they should all see the camera the rules see.
   */
  get viewCameraY(): number {
    return Number.isFinite(this.drawCameraY)
      ? this.drawCameraY
      : this.prevCameraY + (this.cameraY - this.prevCameraY) * this.viewAlpha;
  }

  /**
   * World to screen for the renderer, which is a different question from
   * `worldToScreenY` and has to stay one: that one answers "where is this now",
   * which is what a rule inside the step needs, and this one answers "where is this
   * in the frame being drawn". Mixing them would put a render-time number inside
   * the simulation and take replay by seed with it.
   */
  viewY(worldY: number): number {
    return worldY - this.viewCameraY;
  }

  /**
   * Screen to world for a finger, which has to agree with what the finger can see.
   *
   * The drawn camera lags the simulated one for a third of a second after a jump
   * (see `advanceView`), and a stroke laid through the simulation's camera in that
   * window would land up to ~120 px from where the player put it - in the one
   * moment they are most likely to be reacting to something. The water they stir
   * is the water they are looking at.
   */
  viewToWorldY(screenY: number): number {
    return screenY + this.viewCameraY;
  }

  /**
   * Slowblue: the course coordinate. Larger is always further ahead.
   *
   * Four acts climb and three fall, and the difference between them is exactly
   * one sign. Written as `if (descending)` it would be one sign in about twenty
   * places - the camera follow, the section crossing, three prunes, the straggler
   * cull, the strand line, the spawn line, the re-form window - and the failure
   * mode of getting one of them wrong is not a visible bug. It is a course that
   * deletes itself in front of the player, or a section that can never be
   * cleared, on one act, on one direction, silently.
   *
   * So there is one function. Everything that means "further along" compares
   * `u()` values, and the sign lives here.
   */
  u(worldY: number): number {
    return worldY * this.act.direction;
  }

  /** Which way this act runs: -1 climbing, +1 falling. */
  get direction(): -1 | 1 {
    return this.act.direction;
  }

  /**
   * What going wrong means here: the station's own answer if it has one, and the
   * act's otherwise. See `sim/Failure.ts`.
   *
   * Read per step rather than cached, because the one station in the campaign
   * that overrides it - act VII's descent into the trench - has to take effect
   * the moment the player crosses into it.
   */
  get failureMode(): FailureMode {
    if (!this.campaign) return 'end';
    return levelAtIn(this.act, this.levelIndex).failure ?? this.act.failure.mode;
  }

  /**
   * Slowblue: the one place a run can go wrong, so the three endings can never
   * disagree about what going wrong does.
   *
   * `none` does nothing at all - the failure is still *computed*, so the HUD warms
   * and the shade rises either way, and the mode decides only what happens at the
   * end of that. `restart` puts the swarm back at the top of the station for time
   * and score, while the act attempt has a restart left. `end` is what is left
   * when it does not, and what generated water always does.
   *
   * The budget is checked here rather than inside `restartStation`, because the
   * two outcomes are different *endings* and this is the function that owns which
   * ending a failure gets. `restartStation` restarts; it does not decide.
   */
  private endOrRestart(
    reason: 'depleted' | 'sweptAway' | 'ringMissed',
    x: number,
    y: number,
    severity: number,
  ): void {
    const mode = this.failureMode;
    if (mode === 'none') {
      this.run.strandedFor = 0;
      return;
    }
    if (mode === 'restart' && this.restartsLeft > 0) {
      this.restartStation();
      return;
    }
    this.run.fail(reason);
    this.events.push({ type: 'fail', x, y, value: severity });
  }

  /**
   * Slowblue: the station begins again.
   *
   * The upper acts do not end runs, and this is what they do instead. It is a
   * genuine setback rather than a rescue: the course is rebuilt from the
   * station's first section, the swarm goes back to the line it entered on with
   * the population it entered on, and every bit of ground, every ring and the
   * whole streak made since then is gone. What survives is the campaign - the
   * clock, which never stopped, and the score less `restartCost`.
   *
   * That is the exact shape the design asks for above the tropopause: bad play
   * costs *position and time*, and never the journey.
   */
  restartStation(): void {
    const index = this.levelIndex;
    const from = Math.max(0, levelStartSectionIn(this.act, index));
    // Spent here rather than in the caller, so that the debug surface and the
    // tests, which call this directly, cannot restart for free.
    this.restartsLeft = Math.max(0, this.restartsLeft - 1);
    this.run.noteRestart(this.act.failure.restartCost);

    // Everything spatial, exactly as a fresh run builds it - but `run` is left
    // alone, because the run is what is being preserved.
    this.startSection = from;
    this.field.clear();
    this.field.originY = 0;
    this.currents.reset();
    this.potential.reset();
    this.layers.set(null, 0);
    this.layerLevel = -1;
    this.swarm.reset(this.seed);
    this.obstacles.reset(this.width, this.seed, from);
    this.rescue.reset();
    this.predators.reset();
    this.contentSpawned.clear();
    this.pendingStoops.length = 0;
    this.threats = [];
    this.wake = [];
    this.splitOnSection = null;
    this.ringEase = 1;
    this.heat = 0;
    this.overTerminal = 0;
    this.courseSpeed = 0;
    this.ablating = 0;
    this.lastCourseU = null;
    this.cameraY = -this.height * this.anchorFraction;
    // A jump, not a step: nothing may interpolate across it, and nothing may ease
    // into it either.
    this.prevCameraY = this.cameraY;
    this.drawCameraY = Number.NaN;
    this.field.shiftTo(this.cameraY - FLOW_MARGIN_CELLS * FLOW_CELL);
    this.swarm.spawnShoal(
      Math.round(this.startPopulation ?? this.tuning.agentCount),
      this.width * 0.5,
      0,
      Math.min(this.width, this.height) * 0.11,
    );
    this.startCount = this.swarm.aliveCount(MAIN_FACTION);
    this.obstacles.ensureAhead(this.buildLine);
    this.spawnDueContent();

    // Reported last, and that is the whole of why it moved down here: an event
    // carries a *world* position, and everything that answers one converts it
    // through the camera. Posted before the reset, this said "the middle of the
    // frame the player just lost", and by the time anything drew it the camera
    // had jumped a station's worth of water - so the one cue that says where you
    // now are would have been drawn a long way off screen.
    this.events.push({ type: 'restart', x: this.width * 0.5, y: 0, value: index });
  }

  /**
   * Where the camera holds the swarm, as a fraction of screen height from the
   * top. `CAMERA_ANCHOR` is measured from the trailing edge, so a falling act
   * mirrors it and the picture keeps the same proportions.
   */
  private get anchorFraction(): number {
    return this.act.direction < 0 ? CAMERA_ANCHOR : 1 - CAMERA_ANCHOR;
  }

  /**
   * 0..1: how far behind the front of the frame a screen position is. 0 is the
   * leading edge, 1 the trailing one. The strand line is stated in it, so it does
   * not have to know which way the act runs.
   */
  behindFraction(screenY: number): number {
    const f = this.height > 0 ? screenY / this.height : 0;
    return this.act.direction < 0 ? f : 1 - f;
  }

  /**
   * Slowblue: the only way the player touches the simulation.
   * A gesture segment becomes momentum in the water. Fast strokes are narrow and
   * strong, slow strokes are wide and weak - one mapping, no gesture recogniser,
   * so vortices and braking fall out of the same rule as a straight drag.
   */
  injectStroke(x0: number, y0: number, x1: number, y1: number, dtSec: number): void {
    const T = this.tuning;
    const dx = x1 - x0;
    const dy = y1 - y0;
    const len = Math.hypot(dx, dy);
    this.sinceInput = 0;
    this.hasInput = true;
    if (len < 0.01 || dtSec <= 0) return;
    this.gestureLengthTotal += len;

    const speed = len / dtSec;
    const u = clamp(speed / 1400, 0, 1);
    const strength = T.flowStrength * (0.35 + 1.75 * u);
    const radius = T.flowRadius * (1.55 - 0.85 * u);
    const ux = dx / len;
    const uy = dy / len;

    // How much of this stroke the medium cannot carry. 0 everywhere but act IV
    // and the top of act V, where it rises to 1 and the same gesture starts
    // laying gravity instead. Nothing branches on a mode: both halves are always
    // run and one of them is usually multiplied by zero.
    const vacuum = this.medium.vacuum;

    if (vacuum < 1) {
      const momentum = 1 - vacuum;
      // Resample the segment so a fast flick still lays a continuous current.
      const spacing = Math.max(6, radius * 0.35);
      const steps = Math.max(1, Math.ceil(len / spacing));
      const per = (strength * momentum) / Math.sqrt(steps);
      for (let i = 1; i <= steps; i++) {
        const t = i / steps;
        const x = x0 + dx * t;
        const y = y0 + dy * t;
        this.field.addImpulse(x, y, ux * per, uy * per, radius);
      }
    }
    if (vacuum > 0) this.layPotential(x0, y0, dx, dy, len, u, vacuum);

    this.wake.push({
      x: x1,
      y: y1,
      dx: ux,
      dy: uy,
      life: WAKE_LIFE,
      strength: 0.35 + 0.65 * u,
    });
  }

  /**
   * The vacuum half of a stroke: a short chain of gravity wells along it, getting
   * stronger toward the end.
   *
   * The ramp is the whole design of the gesture. A single well at the fingertip
   * would make the act a game of tapping where you want the swarm to be, which is
   * direct control with an extra step in front of it. A *gradient* - faint where
   * the finger started, strongest where it stopped - means a drag throws the
   * swarm along itself, which is the same sentence the player has been saying
   * with their hand since the trench floor. It simply takes ten seconds to
   * finish saying it up here.
   *
   * A slow drag lays a long, gentle slope; a flick lays one hard well. Same
   * speed-to-shape mapping as the water, for the same reason: one gesture
   * grammar, two consequences.
   */
  private layPotential(
    x0: number,
    y0: number,
    dx: number,
    dy: number,
    len: number,
    fast: number,
    share: number,
  ): void {
    const T = this.tuning;
    const radius = T.potentialRadius * (0.7 + 0.55 * (1 - fast));
    // One well per third of a radius, capped: a stroke is a slope, not a wall.
    const steps = Math.max(1, Math.min(4, Math.round(len / (radius * 0.34))));
    const peak = T.potentialStrength * (0.55 + 0.75 * fast) * share;
    for (let i = 1; i <= steps; i++) {
      const t = i / steps;
      // Quadratic ramp: the far end of the stroke is where the swarm is asked to go.
      this.potential.add(x0 + dx * t, y0 + dy * t, (peak * t * t) / Math.sqrt(steps), radius);
    }
  }

  step(dt: number): void {
    const T = this.tuning;
    // Before anything can move it. The 'over' branch below returns without touching
    // the camera, which is exactly why this is above the branch rather than beside
    // the line that moves it: a still camera has to read as still, not as stale.
    this.prevCameraY = this.cameraY;
    if (this.run.phase === 'over') {
      // Water keeps living after failure so the restart never feels frozen.
      this.stepField(dt);
      this.currents.step(dt);
      this.potential.step(dt, T.potentialHalfLife);
      this.decayWake(dt);
      return;
    }

    this.run.time += dt;
    // Before the swarm reads the water or the rocks: what a moving obstacle is
    // worth depends entirely on collision and avoidance seeing *this* frame's
    // geometry rather than the last one's. `run.time` and not `breathTime` - see
    // `MotionSpec`: the simulation's clock stops when the game does and replays
    // from a seed, and the wall clock does neither.
    this.obstacles.animate(this.run.time);
    this.breathTime += dt;
    this.run.sinceStreakChange += dt;
    this.sinceInput += dt;
    this.syncLayers();
    this.stepField(dt);
    this.currents.step(dt);
    this.potential.step(dt, T.potentialHalfLife);
    this.decayWake(dt);

    this.threats.length = 0;
    for (const p of this.predators.predators) this.threats.push(p);

    const medium = this.medium;
    const ctx: SwarmContext = {
      water: this.water,
      obstacles: this.obstacles,
      tuning: T,
      width: this.width,
      migrationX: 0,
      // The one direction the carried life drives itself in: along the course.
      migrationY: this.act.direction,
      migrationSpeed: medium.migrationSpeed,
      massFactor: this.massFactor,
      threats: this.threats,
      coupling: medium.coupling,
      migrationForce: medium.migrationForce,
      heldCruise: medium.heldCruise,
      ballistic: medium.vacuum,
    };
    // Handed over only when there is anything in it, so every other act's
    // per-agent loop is byte-for-byte the one it always ran.
    if (this.potential.wells.length > 0) ctx.accel = this.potential;
    this.swarm.step(dt, ctx);

    for (const eaten of this.predators.update(
      dt,
      this.swarm,
      this.water,
      this.width,
      T.predatorSpeed,
      T.predatorCoupling,
      this.act.direction,
    )) {
      if (eaten.faction === MAIN_FACTION) this.noteLoss(eaten.x, eaten.y, 2);
      this.events.push({ type: 'bite', x: eaten.x, y: eaten.y, value: 0 });
    }

    this.resolveCollisions();
    for (const pod of this.rescue.update(dt, this.swarm, this.shoalCount, T.rescueFraction)) {
      this.run.noteRescue(pod.initialCount);
      this.events.push({ type: 'rescue', x: pod.x, y: pod.y, value: pod.initialCount });
      if (pod.required) {
        this.run.noteRing();
        this.events.push({ type: 'ring', x: pod.x, y: pod.y, value: pod.initialCount });
      }
    }

    const c = this.swarm.centroid(MAIN_FACTION);
    if (c.count > 0) {
      // Ground made along the course, whichever way it runs. The swarm always
      // spawns at y = 0, so on a climb this is exactly the `-c.y` it always was.
      this.run.distance = Math.max(this.run.distance, this.u(c.y));
      this.run.peakCount = Math.max(this.run.peakCount, c.count);
      const spread = this.swarm.spread(MAIN_FACTION);
      this.spreadAccum += spread;
      this.spreadSamples++;
      this.run.noteSpread(spread);
      this.updateSplitReform(spread, c.y);
      // Before the pruning and before the failure checks, because what it does is
      // take carriers: a swarm emptied by the medium has to reach the 40 % floor
      // in the same step the floor is read, not one after it.
      this.updateAblation(c, dt);
    } else {
      this.lastCourseU = null;
    }

    // Credit progress before anything is pruned, so a section can never be dropped
    // in the same step that should have counted it. See `ObstacleSystem.prune` for
    // the other half of that bug.
    if (c.count > 0) this.creditProgress(c.y);

    this.updateRingEase(c.x, c.y, c.count > 0, dt);

    // Camera: forced drift plus a monotone follow. Never rewinds.
    // The drift escalates with distance so a strong player still meets a wall
    // instead of cruising forever - pressure, not a difficulty curve of content.
    this.cameraY += this.act.direction * this.currentWorldSpeed * dt;
    if (c.count > 0) {
      const target = c.y - this.height * this.anchorFraction;
      if (this.u(target) > this.u(this.cameraY)) this.cameraY = target;
    }
    this.field.shiftTo(this.cameraY - FLOW_MARGIN_CELLS * FLOW_CELL);
    this.obstacles.ensureAhead(this.buildLine);
    const behind = this.behindLine;
    this.obstacles.prune(behind, this.courseCullLine);
    for (const pod of this.rescue.prune(behind, this.act.direction)) {
      this.run.missedPods++;
      if (!pod.required) continue;
      // The one ending the campaign adds. It fires here, at the moment the ring
      // leaves the screen, so the player watches the thing that ends the run.
      this.events.push({ type: 'ringLost', x: pod.x, y: pod.y, value: 0 });
      if (this.failureMode === 'none') continue;
      this.endOrRestart('ringMissed', pod.x, pod.y, 2);
      return;
    }
    this.currents.prune(behind, this.act.direction);
    this.currents.retire(this.cameraY, this.height);
    this.predators.prune(behind, this.act.direction);
    this.potential.prune(behind, this.act.direction);
    this.spawnDueContent();
    if (c.count > 0) this.releaseStoops(c.y);

    this.cullStragglers();
    this.run.recomputeScore(this.shoalCount);

    const policy = this.act.failure;
    if (this.shoalCount < this.failureThreshold) {
      this.endOrRestart('depleted', c.x, c.y, 0);
      return;
    }
    if (c.count > 0) {
      const behindNow = this.behindFraction(this.worldToScreenY(c.y));
      if (behindNow > policy.strandLine) this.run.strandedFor += dt;
      else this.run.strandedFor = Math.max(0, this.run.strandedFor - dt * 2);
      if (this.run.strandedFor > policy.strandGrace) this.endOrRestart('sweptAway', c.x, c.y, 1);
    }
  }

  /** Marks sections the shoal has cleared and banks what they are worth. */
  private creditProgress(centroidY: number): void {
    for (const s of this.obstacles.updateProgress(centroidY)) {
      this.run.furthestSection = Math.max(this.run.furthestSection, s.id);
      /*
       * The cohesion clause is priced against the body the act was *handed*, and
       * not priced at all where the campaign has stopped having an opinion.
       *
       * `startCount` rather than `shoalCount` for the same reason
       * `failureThreshold` uses it: the rule both of them exist to keep is that
       * growth must never raise the bar, and a limit that tracked the live count
       * would move under the player mid-station every time they took a ring. What
       * a station may charge for is holding together the body it was given.
       *
       * Keying it here is also what keeps act I bit-identical: a fresh campaign
       * starts at 25, `sqrt(25/25)` is 1, and the limit is the 100 it has always
       * been. Only a carried mass widens it.
       */
      const advanced = this.run.noteGate(
        this.failureMode === 'none' ? Infinity : this.startCount,
      );
      this.events.push({
        type: advanced ? 'gate' : 'streakBreak',
        x: this.width * 0.5,
        y: s.lineY,
        value: this.run.streak,
      });
      if (s.zone > this.run.zone) {
        this.run.zone = s.zone;
        this.events.push({ type: 'zone', x: this.width * 0.5, y: s.lineY, value: s.zone });
      }
      if (s.level < 0) continue;
      // A level ends when its last section is behind you. The banner for the next
      // one is raised here, in the open water the level file leaves for it.
      const lastOfLevel =
        levelOfSectionIn(this.act, s.id + 1) !== s.level || s.id + 1 >= this.act.totalSections;
      if (!lastOfLevel) continue;
      this.run.noteLevel(s.level);
      if (s.id + 1 >= this.act.totalSections) {
        this.run.complete();
        this.events.push({ type: 'complete', x: this.width * 0.5, y: s.lineY, value: s.level });
        return;
      }
      this.events.push({ type: 'level', x: this.width * 0.5, y: s.lineY, value: s.level + 1 });
    }
  }

  /**
   * Points the layer stack at whichever station is being played, anchored to that
   * station's own first section.
   *
   * Anchoring matters: the bands repeat every `height` px forever, so without a
   * per-station origin the same authored winds would land at different altitudes
   * depending on how far the player had travelled to get there - and a station
   * whose first ring sits in a leftward band on one run and a rightward one on
   * the next is a station nobody can learn.
   */
  private syncLayers(): void {
    if (!this.campaign) return;
    const index = this.levelIndex;
    if (index === this.layerLevel) return;
    this.layerLevel = index;
    const spec = levelAtIn(this.act, index).layers ?? null;
    if (spec === null) {
      this.layers.set(null, 0);
      return;
    }
    // The first live section of this station, or the swarm's own position if the
    // course has not built one yet (a jump straight onto a station, from admin).
    let origin = this.swarm.centroid(MAIN_FACTION).y;
    for (const s of this.obstacles.sections) {
      if (s.level === index) {
        origin = s.lineY;
        break;
      }
    }
    this.layers.set(spec, origin);
  }

  /** Eases the forced drift toward `RING_EASE` while the shoal is on a live ring. */
  private updateRingEase(cx: number, cy: number, valid: boolean, dt: number): void {
    let target = 1;
    if (valid) {
      for (const p of this.rescue.pods) {
        if (p.merged || !p.required) continue;
        // How far up the course the ring still is. Positive means "not there yet".
        const dy = this.u(p.y) - this.u(cy);
        // Only ahead of, or right on, the ring: past it the ocean picks back up.
        if (dy < -p.radius || dy > RING_EASE_REACH) continue;
        const dx = Math.abs(cx - p.x);
        if (dx > RING_EASE_REACH) continue;
        target = RING_EASE;
        break;
      }
    }
    this.ringEase += (target - this.ringEase) * Math.min(1, dt * 2.4);
  }

  private stepField(dt: number): void {
    const T = this.tuning;
    const medium = this.medium;
    this.field.step(dt, medium.flowHalfLife, T.flowDiffusion, medium.flowMaxSpeed, T.flowTurbulence);
  }

  private decayWake(dt: number): void {
    for (let i = this.wake.length - 1; i >= 0; i--) {
      const w = this.wake[i]!;
      w.life -= dt;
      if (w.life <= 0) this.wake.splice(i, 1);
    }
  }

  /**
   * Slowblue: collisions panic the neighbours.
   *
   * Without this, attrition was inert - a smaller shoal is lighter and turns better,
   * so losing individuals made the game *easier* and the "shoal fell apart" ending was
   * unreachable by any scripted style. A strike now scatters the fish around it, which
   * widens the shoal, which exposes more of it to the same rock. Careless play
   * compounds into a collapse; careful play never sees this code at all.
   */
  /**
   * One place where an individual stops existing, so the streak, the counters and
   * the feedback event can never disagree about it. `severity` is what the renderer
   * and the audio use to decide how hard to hit: 0 = quietly culled, 2 = eaten.
   */
  private noteLoss(x: number, y: number, severity: number): void {
    const broke = this.run.noteLoss(1, severity >= 1);
    this.events.push({ type: 'loss', x, y, value: severity });
    if (broke) this.events.push({ type: 'streakBreak', x, y, value: 0 });
  }

  private resolveCollisions(): void {
    for (const a of this.swarm.agents) {
      if (!a.alive) continue;
      if (this.obstacles.hit(a.x, a.y) === null) continue;
      a.alive = false;
      if (a.faction === MAIN_FACTION) this.noteLoss(a.x, a.y, 1);

      const px = a.x;
      const py = a.y;
      this.swarm.hash.forEachNear(px, py, (o) => {
        if (!o.alive) return;
        const dx = o.x - px;
        const dy = o.y - py;
        const d2 = dx * dx + dy * dy;
        if (d2 > PANIC_RADIUS * PANIC_RADIUS || d2 === 0) return;
        const d = Math.sqrt(d2);
        const falloff = 1 - d / PANIC_RADIUS;
        o.vx += (dx / d) * PANIC_KICK * falloff;
        o.vy += (dy / d) * PANIC_KICK * falloff;
      });
    }
  }

  /**
   * Slowblue: what it costs to outrun the medium, and the answer to the one thing
   * this game never asked a descending player for.
   *
   * The report was *"I can descend much faster than the background and the
   * obstacles scroll up, so the top of the course never catches up and I can never
   * die."* Both halves are true and the second follows from the first: `step`
   * advances the camera at the station's drift and then takes the greater of that
   * and the swarm's own position, so a pushing hand drags the world along with it
   * and `behindFraction` pins at the anchor, 0.620, against a strand line of 0.94.
   * There was no forward constraint anywhere in the step.
   *
   * What is *not* done about it: the camera. Bounding the follow was tried in this
   * repo once already (`advanceView`, where it moved the careful bot's score from
   * 1473 to 1209 and the flailing bot's the other way), it slows every parallax
   * plane in the frame - which is the symptom the player is complaining about,
   * made worse - and it walks the swarm out of `FlowField`'s camera-anchored grid,
   * where a stroke stops steering at all, silently.
   *
   * So the rule belongs to the medium, which is the only place act V's own verb
   * allows: **brake, and accept the medium.** A body that outruns the air it is
   * falling through is not slowed by that air, it is *heated* by it. Past
   * `terminalFactor` times the station's drift the swarm begins to ablate - and it
   * ablates from the front, because the front is what is hitting the air. Nothing
   * here stops the player going fast. It simply stops being free.
   *
   * Three properties worth keeping:
   *
   *   * **It is off unless the medium says otherwise.** `Medium.drag` is 0 in
   *     water, air, thin air, vacuum, cloud and stream, so this whole method is
   *     one multiply and a branch in six of the seven media, and act I cannot move
   *     by a float.
   *   * **It is recoverable.** Heat drains whenever the swarm is under the
   *     terminal, at `ablationCool`. A pressure that cannot be got out from under
   *     is a countdown rather than a demand - the same argument `strandedFor`'s
   *     two-times decay is written for.
   *   * **It ends through the door that already exists.** Sustained over-speed
   *     empties the swarm into the 40 % floor and the station begins again. No new
   *     failure reason, no new ending: the failure system is on the do-not-reopen
   *     list and this change does not need it to move.
   */
  private updateAblation(c: { x: number; y: number; count: number }, dt: number): void {
    const drag = this.medium.drag;
    const here = this.u(c.y);
    const was = this.lastCourseU;
    this.lastCourseU = here;
    if (drag <= 0 || was === null || dt <= 0) {
      this.overTerminal = 0;
      this.courseSpeed = 0;
      this.heat = 0;
      this.ablating = 0;
      return;
    }
    const terminal = this.driftSpeed * this.tuning.terminalFactor;
    /*
     * Smoothed, and it has to be. A centroid's frame-to-frame derivative is mostly
     * the body breathing: measured on the shipped acts, a *careful* hand's
     * instantaneous course speed crosses 1.25 times the drift on 22 % of steps
     * while its actual ground over the whole run is well under it. Ablating on
     * that would be ablating on noise, and the player would have no idea what they
     * had done wrong because they would not have done anything.
     *
     * A 0.6 s time constant is about two thirds of the ring grace and a twentieth
     * of the breath: long enough that a wobble is invisible and short enough that
     * a deliberate push is answered inside a section.
     */
    const made = (here - was) / dt;
    // A restart teleports the swarm back up the course; that is not a speed.
    const sample = made > 0 && made < terminal * 12 ? made : 0;
    const k = Math.min(1, dt / 0.6);
    this.courseSpeed += (sample - this.courseSpeed) * k;
    this.overTerminal = terminal > 0 ? Math.max(0, this.courseSpeed - terminal) : 0;
    /*
     * Squared, which is both the physics and the design.
     *
     * Convective heating on a re-entering body goes as the cube of the speed, so
     * anything faster than linear is closer to true than linear is. What it buys
     * is the shape this needs: a **soft shoulder and a hard wall.** A hand that
     * drifts a little over the terminal - which a careful hand does, because a
     * centroid is a body and not a point - pays almost nothing, and a hand that
     * decides to outrun the act pays quadratically for it. A linear cost has to be
     * set either high enough to punish good play or low enough to be ignorable;
     * this one does not have to choose.
     */
    if (this.overTerminal > 0) {
      const excess = this.overTerminal / terminal;
      this.heat += excess * excess * drag * dt;
      this.ablating = Math.min(1, excess);
    } else {
      this.ablating = 0;
      this.heat = Math.max(0, this.heat - this.tuning.ablationCool * dt);
    }
    if (this.heat < 1) return;
    this.heat -= 1;
    // The one furthest out in front, because that is the one meeting the air.
    // Same shape as `cullStragglers` at the other end of the body, and the same
    // `noteLoss` severity: a carrier ablating is not a strike, it is erosion.
    let worst: Agent | null = null;
    let worstU = -Infinity;
    for (const a of this.swarm.agents) {
      if (!a.alive || a.faction !== MAIN_FACTION) continue;
      const u = this.u(a.y);
      if (u > worstU) {
        worstU = u;
        worst = a;
      }
    }
    if (worst === null) return;
    worst.alive = false;
    this.ablated++;
    this.noteLoss(worst.x, worst.y, 0);
  }

  /** Individuals dragged far behind the camera are gone, but the run continues. */
  private cullStragglers(): void {
    const margin = this.medium.stragglerMargin;
    const limit =
      this.act.direction < 0
        ? this.cameraY + this.height + margin
        : this.cameraY - margin;
    const limitU = this.u(limit);
    for (const a of this.swarm.agents) {
      if (!a.alive || a.faction !== MAIN_FACTION) continue;
      if (this.u(a.y) < limitU) {
        a.alive = false;
        this.noteLoss(a.x, a.y, 0);
      }
    }
  }

  /**
   * Pods, standing currents and hunters all appear at the same moment: when their
   * section comes within one and a bit screens of the camera. Spawning them earlier
   * would let a hunter wander out of its own band before the player ever sees it.
   */
  /**
   * Releases every armed stoop the swarm has now drawn level with, *behind* it.
   *
   * The authored `dy` stops being a place the bird waits and becomes the line that
   * triggers it, which is what a `dy` on an ambush from behind can usefully mean.
   * It is put behind the centroid: inside `PredatorSystem`'s 300 px sense radius,
   * so it acquires on its first frame, and inside the prune margin, so it is not
   * deleted before it has moved. 300 px would be outside the prune line and the
   * hunter would be removed on the next step, which is the failure this replaced.
   *
   * Slowblue: "behind" was 170 px, flat, and that number was measured on a *climbing*
   * act. The camera holds a climb at 0.62 of the frame and `behindLine` at 0.9, so
   * there are 0.28 of a screen to play with; a fall is held at 0.33 with the line
   * at 0.10, which is 0.23 - and on a 640 px frame 0.23 of a screen is 147. Every
   * fragment released in act V on a short viewport was therefore spawned *behind
   * the cull line* and deleted on the next step. Measured: embers that lived one
   * frame, in among ones that lived thousands.
   *
   * So the offset comes from the room that actually exists rather than from a
   * constant: half the distance to the line, capped at the old 170. Half, because
   * a fragment released *on* the line is one lagging frame from being pruned
   * anyway.
   */
  private releaseStoops(centroidY: number): void {
    if (this.pendingStoops.length === 0) return;
    const here = this.u(centroidY);
    const room = Math.max(0, here - this.u(this.behindLine));
    const back = Math.min(170, room * 0.5);
    for (let i = this.pendingStoops.length - 1; i >= 0; i--) {
      const h = this.pendingStoops[i]!;
      if (here < this.u(h.y)) continue;
      this.pendingStoops.splice(i, 1);
      this.predators.spawn(
        h.x,
        centroidY - this.act.direction * back,
        h.size,
        h.sectionId,
        h.order * 1.7,
        true,
        h.form ?? 'shark',
      );
    }
  }

  private spawnDueContent(): void {
    const spawnAhead = this.u(this.cameraY + this.act.direction * this.height * 1.7);
    for (const s of this.obstacles.sections) {
      if (this.contentSpawned.has(s.id)) continue;
      // Not yet: the section's far edge is still more than 1.7 screens ahead.
      if (this.u(s.exitY) > spawnAhead) continue;
      this.contentSpawned.add(s.id);
      for (const p of s.podHints) {
        this.rescue.spawn(
          this.swarm,
          p.x,
          p.y,
          p.count,
          this.tuning.rescueRadius * (p.scale ?? 1),
          p.required ?? false,
        );
      }
      // Act IV's `node`: gravity the level author placed. Same field, same
      // profile and same summation as anything the hand lays - which is the
      // point of it, because in vacuum the medium and the input are one thing.
      for (const w of s.wellHints) {
        this.potential.add(w.x, w.y, w.strength, w.radius, true);
      }
      for (const v of s.vortexHints) {
        this.currents.add({
          x: v.x,
          y: v.y,
          radius: v.radius,
          strength: v.strength,
          sectionId: s.id,
          phase: 0,
        });
      }
      let i = 0;
      for (const h of s.hunterHints) {
        /*
         * A stoop is not spawned here. It is *armed* here and released later.
         *
         * Slowblue: content spawns 1.7 screens ahead of the camera, and the swarm sits
         * 0.62 of a screen behind that - so everything in this loop arrives about
         * 1 300 to 1 430 px in front of the flock. That is right for a patrol,
         * which is supposed to be waiting where the level author put it, and it is
         * fatal for the one hazard in the campaign whose entire design is that it
         * **overtakes from behind**: a stooping raptor was being built a screen and
         * a third *ahead* of its target, outside its own 300 px sense radius, and
         * a target-less stoop then cruises up the course at 0.8 of its speed - away
         * from the flock. Measured on three seeds, act II's Passage stoop never
         * came within 1 041 px of the flock and took zero individuals in its whole
         * life; the Anvil's was caught only because the flock closed on *it*, fifty
         * seconds and 1 300 px later, at the wrong section, head-on. The one hazard
         * in the game that comes from behind had never once come from behind.
         */
        if (h.stoop === true) {
          this.pendingStoops.push({ ...h, sectionId: s.id, order: i });
          i++;
          continue;
        }
        this.predators.spawn(
          h.x,
          h.y,
          h.size,
          s.id,
          i * 1.7,
          h.stoop ?? false,
          h.form ?? 'shark',
        );
        i++;
      }
    }
  }

  /**
   * Slowblue: split-and-reform detection.
   *
   * "The shoal can be split" was already true, but nothing told the player it was a
   * tactic rather than an accident. Hysteresis on the shoal's spread while it is on a
   * section: cross SPLIT_SPREAD and you are split; come back under REFORM_SPREAD
   * before leaving the section and the run acknowledges it, once, with a score bonus
   * and a visible pulse. No meta layer - it is in-run feedback that teaches a verb.
   */
  private updateSplitReform(spread: number, centroidY: number): void {
    // The window extends well past the obstacle: tearing the shoal apart happens at
    // the rock, but putting it back together is the part that takes room.
    // Only on something there are two ways round: splitting across a funnel mouth or
    // a chicane row is not a tactic, it is the shoal coming apart.
    const here = this.u(centroidY);
    const onSection = this.obstacles.sections.find(
      (s) =>
        SPLITTABLE.has(s.kind) &&
        here > this.u(s.entryY) - 160 &&
        here < this.u(s.exitY) + REFORM_TRAIL,
    );
    if (onSection === undefined) {
      this.splitOnSection = null;
      return;
    }
    if (this.splitOnSection === null) {
      if (!onSection.reformed && spread > SPLIT_SPREAD) this.splitOnSection = onSection.id;
      return;
    }
    if (this.splitOnSection !== onSection.id) {
      this.splitOnSection = null;
      return;
    }
    if (spread < REFORM_SPREAD) {
      onSection.reformed = true;
      this.splitOnSection = null;
      this.run.noteReform();
      this.events.push({ type: 'reform', x: this.width * 0.5, y: centroidY, value: onSection.id });
    }
  }

  takeEvents(): SimEvent[] {
    if (this.events.length === 0) return [];
    const out = this.events;
    this.events = [];
    return out;
  }
}
