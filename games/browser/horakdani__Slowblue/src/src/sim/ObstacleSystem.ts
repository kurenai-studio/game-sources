import { ACT_WATER, levelAtIn, type Act, type MotionSpec, type ScriptEntry } from '../config/levels';
import { sectionKindFor, zoneForSection, type SectionKind } from '../config/zones';
import { Rng } from '../core/rng';
import { BREATH_PERIOD } from './Breath';
import type { PredatorForm } from './PredatorSystem';

const TAU = Math.PI * 2;

export type { SectionKind };

/**
 * The air's six. See `SectionSpec` in `config/levels.ts` for what each one asks of
 * the player; the geometry is `build*Cloud` below, and the one rule under all of
 * it is that **cloud does not make rock's shapes**.
 */
export type CloudKind = 'bank' | 'tower' | 'pass' | 'wisps' | 'rotor' | 'raptor' | 'street';

/**
 * The upper air's six. Ice rather than cloud - see `SectionSpec` in
 * `config/levels.ts` for the mapping and `build*Crystal` below for the geometry.
 */
export type CrystalKind = 'veil' | 'column' | 'throat' | 'flurry' | 'eddy' | 'shear';

/**
 * Orbit's six. Debris and gravity rather than weather - see `SectionSpec` in
 * `config/levels.ts` for the mapping and `debris*` below for the geometry. The
 * one rule under all of it is that **vacuum is sparse**: nothing up here sticks
 * to anything, so a line of debris has real gaps in it and the demand is never
 * "can you fit".
 */
export type DebrisKind = 'arc' | 'hulk' | 'strait' | 'shrapnel' | 'node' | 'flare';

/**
 * Re-entry's three. Act V is the transformation, so it opens on orbit's debris,
 * closes on the air's cloud, and owns only the shapes for the part in between -
 * see `SectionSpec` in `config/levels.ts`.
 */
export type PlasmaKind = 'shock' | 'plume' | 'sheet' | 'ember';

/**
 * Rain's three. Act VI opens on the air's cloud, met from underneath, and then
 * meets the first living things in the campaign - see `SectionSpec` in
 * `config/levels.ts`.
 */
export type RainKind = 'downpour' | 'canopy' | 'boulder';

/**
 * The homecoming's two. Act VII is the one act that was never given an alphabet
 * of its own, and the one whose subject - settling, and nothing being able to be
 * lost - is contradicted by every wall in it. These are soft bodies rather than
 * geometry, and the rule under both of them is that **neither closes the course**:
 * see `SectionSpec` in `config/levels.ts` and `home*` below.
 */
export type HomeKind = 'drape' | 'bloom';

/** Authored levels add one archetype the generator has no use for: empty water. */
export type SectionArchetype =
  | SectionKind
  | CloudKind
  | CrystalKind
  | DebrisKind
  | PlasmaKind
  | RainKind
  | HomeKind
  | 'open';

export interface Blob {
  x: number;
  y: number;
  r: number;
  /**
   * Where this circle sits when its section is at phase zero. Present only on the
   * blobs of a moving section (`Section.motion`), absent on every other blob in
   * the game.
   *
   * It exists because motion has to be **absolute rather than incremental**. A
   * blob that is nudged by a delta every frame accumulates float error, and worse,
   * it cannot survive `World.resize`, which multiplies every x by a ratio: a home
   * position that was not scaled with it would drag the rock back to where the
   * portrait screen had been. One authored origin, one phase, one position - and
   * the renderer builds its silhouette from this rather than from `x`, so a moving
   * mass is cached once and translated rather than rebuilt sixty times a second.
   */
  hx?: number;
}

/**
 * Slowblue: a section that does not stand still. See `MotionSpec` in
 * `config/levels.ts` for what the two kinds ask of the player and why this is a
 * modifier on a section rather than an alphabet of its own.
 *
 * **The motion is lateral, always.** Nothing here touches y, and that is what
 * keeps the rest of the engine from having to know about any of it: `lineY`,
 * `minY`/`maxY`, `entryY`/`exitY`, the pruning, the retire-and-cull line and the
 * split-and-re-form window are all y quantities, and every one of them stays
 * exactly as true of a walking rock as of a still one. A hazard that moved *along*
 * the course would invalidate all six.
 */
export interface SectionMotion {
  kind: 'aperture' | 'drift';
  /** Peak excursion in px. */
  reach: number;
  /** Seconds per cycle. */
  period: number;
  /**
   * Where in the cycle this section starts, 0..1, derived from its own line so no
   * two moving sections in a course ever breathe in unison. A campaign where
   * every aperture opened on the same beat would read as one machine rather than
   * as a world.
   */
  phase: number;
  /**
   * Which way each blob goes, as -1, 0 or +1, in `blobs` order.
   *
   * Resolved once at build time against the geometry's own centroid rather than
   * per frame, because the centroid *moves* once the thing is open: a sign
   * recomputed each frame would flip for the blobs nearest the middle and tear
   * the wall in half. A `drift` is all +1 - one body, one translation.
   */
  way: Int8Array;
}

export interface PodHint {
  x: number;
  y: number;
  count: number;
  /** A dashed ring: the run ends if the camera leaves it behind un-absorbed. */
  required?: boolean;
  /** Radius multiplier on the tuned rescue radius. */
  scale?: number;
}

export interface VortexHint {
  x: number;
  y: number;
  radius: number;
  strength: number;
}

export interface HunterHint {
  x: number;
  y: number;
  size: number;
  /** Enters from behind the flock and overtakes it. See `PredatorSystem`. */
  stoop?: boolean;
  /**
   * Which silhouette the section asked for. Absent is the shark, which is what
   * the generated course and act I both want. See `PredatorForm`.
   */
  form?: PredatorForm;
}

/**
 * A standing gravity well the course owns, rather than one the player laid.
 *
 * Act IV's `node`. It is the same `Well` the hand deposits and it is summed by the
 * same field, which is the whole reason it belongs here rather than in a hazard
 * system of its own: in vacuum the medium *is* the input, so a hazard made of
 * gravity and a stroke made of gravity have to be the same object or the act is
 * telling the player two different stories about what space is.
 */
export interface WellHint {
  x: number;
  y: number;
  radius: number;
  /** Peak acceleration (px/s^2). Positive pulls in, negative pushes away. */
  strength: number;
}

export interface Section {
  id: number;
  kind: SectionArchetype;
  /** Index of the depth zone this section belongs to. */
  zone: number;
  /** Which authored level this section came from. -1 for generated water. */
  level: number;
  /** Index inside that level. */
  step: number;
  /** Crossing this world Y counts the section as cleared. */
  lineY: number;
  minY: number;
  maxY: number;
  /**
   * The two ends of the section's geometry *in course order*: `entryY` is the
   * edge met first and `exitY` the edge left last.
   *
   * On a climb they are `maxY` and `minY`; on a descent they are the other way
   * round. They exist so the things that reason about where the swarm is
   * relative to a section - the split-and-re-form window, the content spawn line -
   * can be written once instead of twice with the inequalities flipped.
   */
  entryY: number;
  exitY: number;
  blobs: Blob[];
  /**
   * How this section moves, or null for the still ones - which is all but a
   * handful of the campaign. See `SectionMotion`.
   */
  motion: SectionMotion | null;
  /**
   * Everywhere a `drift` ever is, as a static union of circles. Empty for every
   * other section, including an `aperture`.
   *
   * The corridor sweep builds a course and never advances a clock, so it reads
   * the authored phase - which is exactly the right thing for an `aperture`,
   * authored shut, and exactly the wrong thing for a `drift`, authored in the
   * middle of its travel. This is what the sweep reads instead: if a line exists
   * past the union of every position the mass ever holds, then a line exists past
   * it whenever the player actually arrives.
   */
  envelope: Blob[];
  passed: boolean;
  /**
   * Where this section wants rescue pods. A rock section places one in each side
   * channel: taking both requires actually splitting the shoal and re-forming it,
   * which is what turns "the shoal can split" into a decision worth making.
   */
  podHints: PodHint[];
  /** Standing currents this section owns. Water as an obstacle. */
  vortexHints: VortexHint[];
  /** Hunters that patrol this section's band. */
  hunterHints: HunterHint[];
  /** Standing gravity wells this section owns. Act IV only. */
  wellHints: WellHint[];
  /** Set once the shoal has been seen to split and re-form on this section. */
  reformed: boolean;
}

export const SECTION_SPACING = 820;
const FIRST_SECTION_OFFSET = 640;

/**
 * Slowblue: every obstacle is a union of circles. Circles give trivially cheap
 * collision *and* trivially cheap predictive avoidance, and a chain of them still
 * reads as an organic rock.
 *
 * Which archetype a section uses is not decided here - `sectionKindFor` reads it off
 * the depth zone, so "what the ocean can build" is a property of how deep you are.
 */
export class ObstacleSystem {
  readonly sections: Section[] = [];
  /**
   * Sections the course has finished with that are still in shot.
   *
   * Scenery, and nothing else: they are out of `activeBlobs`, so they neither
   * collide nor steer, and out of everything that reads `sections`, so no scoring,
   * palette or split-and-reform rule can see them. They exist because the moment
   * the simulation stops needing a rock is not the moment the player stops
   * looking at it. See `prune`.
   */
  readonly retired: Section[] = [];
  /** Blobs in the live band around the camera; rebuilt when sections change. */
  activeBlobs: Blob[] = [];
  private nextId = 0;
  private frontierY: number;
  private rng: Rng;

  /**
   * Authored levels drive the course when this is set; the seeded generator is
   * kept for the headless sweeps, which need water nobody has hand-tuned.
   *
   * `act` is not readonly, because the admin surface plays act II out of the same
   * world act I is running in (see `World.setAct`). Nothing in a shipped run ever
   * writes it: a course is built from one script and the script is chosen before
   * the first section exists.
   */
  constructor(
    public width: number,
    seed: number,
    readonly scripted = false,
    public act: Act = ACT_WATER,
  ) {
    this.rng = new Rng(seed ^ 0x5eed);
    this.frontierY = FIRST_SECTION_OFFSET * this.dir;
  }

  /** Which way this course runs. -1 up, +1 down. See `CourseDirection`. */
  private get dir(): number {
    return this.act.direction;
  }

  /**
   * A world Y `dy` px *back down the course* from `y` - the direction the swarm
   * arrives from, so a positive `dy` in a level file always means "met earlier"
   * whether the course climbs or falls.
   *
   * Every authored offset goes through this, which is what lets acts VI and VII
   * be written in exactly the same grammar as acts I and II instead of in a
   * mirror-image one nobody could proofread.
   */
  private back(y: number, dy: number): number {
    return y - this.dir * dy;
  }

  /** The other way: `dy` px further *along* the course, past the section's line. */
  private fwd(y: number, dy: number): number {
    return y + this.dir * dy;
  }

  /**
   * `startSection` is the admin surface's whole trick, and it is deliberately the
   * smallest one available: the course is built from the script index the run is
   * *told* to start at, so section N is simply the first thing built, at the same
   * place section 0 would have been. Everything downstream - the level index, the
   * palette, the banner, the medium - is derived from the sections in the list, so
   * none of it needs to know a jump happened.
   */
  reset(width: number, seed: number, startSection = 0): void {
    this.width = width;
    this.rng = new Rng(seed ^ 0x5eed);
    this.sections.length = 0;
    this.retired.length = 0;
    this.activeBlobs = [];
    this.nextId = this.scripted ? Math.max(0, Math.min(this.act.totalSections - 1, startSection)) : 0;
    this.frontierY = FIRST_SECTION_OFFSET * this.dir;
  }

  /** True once every authored section has been built. Nothing follows a campaign. */
  get scriptExhausted(): boolean {
    return this.scripted && this.nextId >= this.act.totalSections;
  }

  /**
   * Builds course up to `targetY`, which is a point ahead of the camera. On a
   * climb that is a smaller Y and on a descent a larger one; `dir` is the only
   * place that distinction is written down.
   */
  ensureAhead(targetY: number): void {
    let changed = false;
    const dir = this.dir;
    while ((this.frontierY - targetY) * dir < 0) {
      if (this.scriptExhausted) break;
      this.sections.push(this.build(this.nextId, this.frontierY));
      this.nextId++;
      // `spacing` is the distance from the previous section, so the empty section
      // that closes every level can be given room on both sides of it.
      const next: ScriptEntry | undefined = this.scripted
        ? this.act.script[this.nextId]
        : undefined;
      this.frontierY += dir * (next?.spec.spacing ?? SECTION_SPACING);
      changed = true;
    }
    if (changed) this.rebuildActive();
  }

  /**
   * Retires sections the camera has left behind, and finally drops the retired
   * ones once they are off the screen.
   *
   * Slowblue: `behindY` is keyed to `lineY`, the scoring line - not to `maxY`, the
   * geometry's rearmost point. Three of the six archetypes reach *behind* their own
   * line (a narrows funnel by 240px, a chicane by 200px), and on `maxY` those
   * sections were dropped from the list while the shoal was still ~20px short of
   * the line. Crossing them then paid nothing: clearing a funnel was worth zero
   * score, silently, for every player. Pruning on the line keeps exactly as much
   * geometry as that section needs and not a pixel more - a blanket "keep
   * everything longer" would instead leave rocks alive behind the shoal, quietly
   * culling stragglers that used to swim free.
   *
   * And that is exactly why leaving the list cannot be the same event as leaving
   * the picture. `behindY` sits a tenth of a screen *inside* the trailing edge, so
   * a section dropped there is deleted with a fifth of the frame still under it:
   * the water was still carrying the rock down and it blinked out instead of
   * swimming out. So a dropped section moves to `retired` rather than vanishing -
   * out of `activeBlobs`, out of every rule that reads `sections`, and still
   * drawn - and it is let go for good on `cullY`, keyed to `exitY`, the edge that
   * leaves the frame last with its radius already in it.
   *
   * `cullY` defaults to `behindY`, which is the old behaviour for every caller that
   * has no screen to speak of. See `World.courseCullLine` for the real one.
   */
  prune(behindY: number, cullY = behindY): void {
    let removed = 0;
    const dir = this.dir;
    while (this.sections.length > 0 && (this.sections[0]!.lineY - behindY) * dir < 0) {
      this.retired.push(this.sections.shift()!);
      removed++;
    }
    while (this.retired.length > 0 && (this.retired[0]!.exitY - cullY) * dir < 0) {
      this.retired.shift();
    }
    if (removed > 0) this.rebuildActive();
  }

  /** Highest zone index among live sections - what the renderer paints. */
  get currentZone(): number {
    let z = 0;
    for (const s of this.sections) z = Math.max(z, s.zone);
    return z;
  }

  /** Re-derives the active blob list after something mutated section geometry. */
  refreshActive(): void {
    this.rebuildActive();
  }

  private rebuildActive(): void {
    const blobs: Blob[] = [];
    for (const s of this.sections) for (const b of s.blobs) blobs.push(b);
    this.activeBlobs = blobs;
  }

  /**
   * Resolves an authored `MotionSpec` against geometry that now exists.
   *
   * Everything decided here is decided *once*: which way each blob goes, where it
   * goes back to, and where in the cycle this section starts. The per-frame pass
   * below is then four multiplies per blob and no branches, which is what lets a
   * moving obstacle cost nothing worth measuring.
   */
  private setMotion(s: Section, spec: MotionSpec): void {
    if (s.blobs.length === 0) return;
    const reach = spec.reach * this.width;
    const way = new Int8Array(s.blobs.length);
    if (spec.kind === 'drift') {
      way.fill(1);
    } else {
      /*
       * The pivot is **the hole**, found as the widest space between consecutive
       * circles - not the geometry's centroid.
       *
       * The centroid is the obvious answer and it is wrong the moment a gap is
       * off-centre, which most of them are: a wall with its hole at 0.34 has a
       * short run to the left of it and a long one to the right, so the centroid
       * sits somewhere out in the long run, and every circle between the hole and
       * the centroid gets told to move *inward*. The aperture would close on the
       * one phase the sweep never looks at. Finding the hole instead is exact for
       * every shape this is allowed on, symmetric or not.
       */
      const xs = s.blobs.map((b) => b.x).sort((p, q) => p - q);
      let pivot = xs[0]!;
      let widest = -1;
      for (let i = 0; i + 1 < xs.length; i++) {
        const span = xs[i + 1]! - xs[i]!;
        if (span > widest) {
          widest = span;
          pivot = (xs[i]! + xs[i + 1]!) * 0.5;
        }
      }
      for (let i = 0; i < s.blobs.length; i++) {
        const dx = s.blobs[i]!.x - pivot;
        way[i] = Math.abs(dx) < 1 ? 0 : dx < 0 ? -1 : 1;
      }
    }
    for (const b of s.blobs) b.hx = b.x;
    s.motion = {
      kind: spec.kind,
      reach,
      period: spec.period ?? BREATH_PERIOD,
      // Authored wins. An unauthored phase is keyed to where the section is
      // rather than to what number it is, so it survives the admin surface
      // starting a run in the middle of an act - but a pair that is supposed to
      // move *against* each other cannot be left to that, which is what
      // `MotionSpec.phase` is for.
      phase: spec.phase ?? puffPick(s.lineY, s.id),
      way,
    };
    if (spec.kind === 'drift') this.buildEnvelope(s, reach);
  }

  /** The union of every position a drifting mass holds. See `Section.envelope`. */
  private buildEnvelope(s: Section, reach: number): void {
    for (const b of s.blobs) {
      // Close enough together that consecutive copies overlap, so the union is one
      // solid band rather than a row of beads with gaps a sweep could walk through.
      const steps = Math.max(2, Math.ceil((reach * 2) / Math.max(4, b.r * 0.8)));
      const step = (reach * 2) / steps;
      /*
       * ...and then a little fatter than the circle it copies.
       *
       * A row of discs spaced `step` apart does not quite cover the band the disc
       * actually sweeps: it misses a lens between every pair, deepest at the
       * middle, `r - sqrt(r^2 - (step/2)^2)` tall. That is two or three pixels
       * against a four-pixel sweep cell, so it would have been invisible in every
       * test and wrong in exactly the direction that matters - an envelope that
       * under-covers is a sweep approving a corridor the rock walks into. Padding
       * by the sagitta makes the union a strict superset of the swept band, which
       * is the only version of this worth having.
       */
      const pad = b.r - Math.sqrt(Math.max(0, b.r * b.r - step * step * 0.25));
      for (let i = 0; i <= steps; i++) {
        s.envelope.push({ x: b.x - reach + step * i, y: b.y, r: b.r + pad });
      }
    }
  }

  /**
   * Walks every moving section to time `t`, in seconds of *simulated* time.
   *
   * `activeBlobs` holds the same objects the sections do, so nothing is rebuilt
   * and nothing is allocated: collision, predictive avoidance and the renderer all
   * read the new positions the moment this returns. Retired sections move too -
   * they are off the course and still on the screen, and a rock that froze on its
   * way out of frame would be the most obvious tell in the game.
   */
  animate(t: number): void {
    for (const list of [this.sections, this.retired]) {
      for (const s of list) {
        const m = s.motion;
        if (m === null) continue;
        const u = Math.sin(TAU * (t / m.period + m.phase));
        // An aperture is authored *shut*, so its swing is one-sided: 0 at the
        // closed phase, `reach` at the open one. A drift is centred, so its swing
        // is signed and the authored position is the middle of the travel.
        const swing = m.kind === 'aperture' ? (u + 1) * 0.5 * m.reach : u * m.reach;
        for (let i = 0; i < s.blobs.length; i++) {
          const b = s.blobs[i]!;
          b.x = b.hx! + m.way[i]! * swing;
        }
      }
    }
  }

  /**
   * `hit`, but reading the swept envelope of anything that drifts.
   *
   * The corridor sweep's question is "is there a line past this at *any* arrival
   * time", which is a different question from the one the simulation asks sixty
   * times a second, and this is the only place the difference is expressed.
   */
  hitSwept(x: number, y: number, forgiveness = 0.9): Blob | null {
    for (const s of this.sections) {
      const list = s.envelope.length > 0 ? s.envelope : s.blobs;
      for (const b of list) {
        const rr = b.r * forgiveness;
        const dx = x - b.x;
        const dy = y - b.y;
        if (dx * dx + dy * dy < rr * rr) return b;
      }
    }
    return null;
  }

  private build(id: number, y: number): Section {
    const entry = this.scripted ? this.act.script[id] : undefined;
    if (entry !== undefined) return this.buildSpec(id, y, entry);
    const rng = this.rng.fork(id);
    // Difficulty ramps over ~12 sections, then plateaus: a ceiling, not a wall.
    const diff = Math.min(1, id / 12);
    const kind = sectionKindFor(id);
    switch (kind) {
      case 'gate':
        return this.buildGate(id, y, diff, rng);
      case 'rock':
        return this.buildRock(id, y, diff, rng);
      case 'narrows':
        return this.buildNarrows(id, y, diff, rng);
      case 'drift':
        return this.buildDrift(id, y, diff, rng);
      case 'vortex':
        return this.buildVortex(id, y, diff, rng);
      case 'predator':
        return this.buildPredator(id, y, diff, rng);
    }
  }

  /**
   * Slowblue: an authored section.
   *
   * The same six archetypes as the generator, but every dimension comes from the
   * level file instead of from a seed and a difficulty ramp. Two things are
   * deliberately *not* carried over from the generated versions: the loose boulder
   * a generated chicane drops just past its own gap (it sat on the only line
   * through the next row, which is the single most common way the old course
   * produced something that could not be flown), and the rescue pod parked off the
   * safe line as bait - a ring that can end the run is never bait.
   */
  private buildSpec(id: number, y: number, entry: ScriptEntry): Section {
    const W = this.width;
    const spec = entry.spec;
    const zone = levelAtIn(this.act, entry.level).zone;
    const blobs: Blob[] = [];
    const vortexHints: VortexHint[] = [];
    const hunterHints: HunterHint[] = [];
    const wellHints: WellHint[] = [];

    switch (spec.kind) {
      case 'open':
        break;
      case 'gate':
        this.gateWalls(blobs, spec.centre * W, spec.gap * W, y);
        break;
      case 'rock':
        this.rockMass(blobs, spec.centre * W, spec.radius * W, y, spec.teeth ?? false);
        break;
      case 'narrows': {
        const gap = spec.gap * W;
        const mouth = (spec.mouth ?? 0.5) * W;
        const depth = spec.depth ?? 230;
        const centre = spec.centre * W;
        const r = Math.max(14, W * 0.045);
        // Converging walls, entered from +Y. Step count is derived from the radius
        // so the funnel is a wall and not a row of beads with water between them.
        const span = Math.hypot(mouth - gap * 0.5, depth);
        const steps = Math.max(7, Math.ceil(span / (r * 0.75)));
        for (let i = 0; i <= steps; i++) {
          const t = i / steps;
          const half = mouth + (gap * 0.5 - mouth) * t;
          const yy = this.back(y, (1 - t) * depth);
          blobs.push({ x: centre - half, y: yy, r });
          blobs.push({ x: centre + half, y: yy, r });
        }
        this.gateWalls(blobs, centre, gap, y, r * 0.9);
        break;
      }
      case 'drift': {
        const gap = spec.gap * W;
        const r = Math.max(13, W * 0.038);
        let side = spec.first ?? 1;
        for (let row = 0; row < spec.rows; row++) {
          const yy = this.back(y, (spec.rows - 1 - row) * 196);
          const centre = clampX(W * 0.5 + side * spec.swing * W, W);
          this.gateWalls(blobs, centre, gap, yy, r);
          side = (side === 1 ? -1 : 1) as -1 | 1;
        }
        break;
      }
      case 'vortex':
        this.gateWalls(blobs, spec.centre * W, spec.gap * W, y);
        vortexHints.push({
          x: spec.centre * W,
          y: this.fwd(y, spec.gap * W * 0.16),
          radius: spec.radius * W,
          strength: spec.spin * spec.strength,
        });
        break;
      case 'predator':
        this.rockMass(blobs, spec.centre * W, spec.radius * W, y, true);
        for (const h of spec.hunters) {
          hunterHints.push({
            x: clampX(h.x * W, W),
            y: this.back(y, h.dy),
            size: h.size,
            stoop: h.stoop ?? false,
            form: 'shark',
          });
        }
        break;

      // --- the air's six ---
      case 'bank':
        this.cloudDeck(blobs, spec.centre * W, spec.gap * W, y, W * 0.075, spec.depth ?? 150);
        break;
      case 'tower':
        this.cloudTower(blobs, spec.centre * W, spec.radius * W, y, spec.height ?? 2.3);
        break;
      case 'pass':
        this.cloudPass(
          blobs,
          spec.centre * W,
          spec.gap * W,
          (spec.mouth ?? 0.5) * W,
          y,
          spec.depth ?? 240,
        );
        break;
      case 'wisps': {
        let side = spec.first ?? 1;
        for (let row = 0; row < spec.rows; row++) {
          const yy = this.back(y, (spec.rows - 1 - row) * 196);
          const centre = clampX(W * 0.5 + side * spec.swing * W, W);
          // Torn cloud is small cloud: a third of a bank's puff, with nothing
          // behind it. Two or three of these in a row is the act's chicane - the
          // spray's is two and the cliff's is three, which is the shape's own ramp.
          this.cloudDeck(blobs, centre, spec.gap * W, yy, W * 0.042, 0);
          side = (side === 1 ? -1 : 1) as -1 | 1;
        }
        break;
      }
      case 'rotor':
        // Lenticular: the same deck flattened until it is a lens, which is what a
        // standing wave makes of a cloud - and the one cloud a pilot is taught to
        // read from a distance, because of exactly what is turning underneath it.
        this.cloudDeck(blobs, spec.centre * W, spec.gap * W, y, W * 0.062, 0, 0.34);
        vortexHints.push({
          x: spec.centre * W,
          y: this.fwd(y, spec.gap * W * 0.16),
          radius: spec.radius * W,
          strength: spec.spin * spec.strength,
        });
        break;
      case 'street':
        this.cloudStreet(
          blobs,
          spec.centre * W,
          spec.gap * W,
          y,
          spec.length ?? 660,
          (spec.mouth ?? 0.52) * W,
        );
        break;
      case 'raptor':
        this.cloudTower(blobs, spec.centre * W, spec.radius * W, y, 1.7);
        for (const h of spec.hunters) {
          hunterHints.push({
            x: clampX(h.x * W, W),
            y: this.back(y, h.dy),
            size: h.size,
            stoop: h.stoop ?? false,
            form: 'raptor',
          });
        }
        break;

      // --- act III: the upper air's six ---
      case 'veil':
        this.crystalCurtain(
          blobs,
          [spec.centre],
          spec.gap * W,
          y,
          W * 0.036,
          spec.depth ?? 130,
        );
        break;
      case 'column':
        this.crystalColumn(blobs, spec.centre * W, spec.radius * W, y, spec.height ?? 2.6);
        break;
      case 'throat':
        this.crystalThroat(
          blobs,
          spec.centre * W,
          spec.gap * W,
          (spec.mouth ?? 0.5) * W,
          y,
          spec.depth ?? 235,
        );
        break;
      case 'flurry': {
        let side = spec.first ?? 1;
        for (let row = 0; row < spec.rows; row++) {
          const yy = this.back(y, (spec.rows - 1 - row) * 196);
          const centre = clampX(W * 0.5 + side * spec.swing * W, W);
          // Loose crystal: half the curtain's grain size and no second row, so
          // a run of these reads as scatter rather than as a stack of walls. Two
          // rows in the upper air, where a lateral move is the expensive thing.
          this.crystalCurtain(blobs, [centre / W], spec.gap * W, yy, W * 0.024, 0);
          side = (side === 1 ? -1 : 1) as -1 | 1;
        }
        break;
      }
      case 'eddy':
        // The lens over the eddy: one thin, flat crystal sheet. Ice is what makes
        // a standing wave visible up here, exactly as lenticular cloud does lower
        // down - the marker is not the hazard, it is the sign the hazard is there.
        this.crystalCurtain(blobs, [spec.centre], spec.gap * W, y, W * 0.03, 0, 0.3);
        vortexHints.push({
          x: spec.centre * W,
          y: this.fwd(y, spec.gap * W * 0.16),
          radius: spec.radius * W,
          strength: spec.spin * spec.strength,
        });
        break;
      case 'shear':
        // The act's own archetype: a layer boundary with two or three doors in
        // it. Every door is a different place to come out, and where you come out
        // decides which wind carries you for the next half minute.
        this.crystalCurtain(blobs, spec.gaps, spec.gap * W, y, W * 0.034, 96);
        break;

      // --- act IV: orbit's six ---
      case 'arc':
        this.debrisArc(blobs, spec.centre * W, spec.gap * W, y, spec.bow * W);
        break;
      case 'hulk':
        this.debrisHulk(blobs, spec.centre * W, spec.radius * W, y);
        break;
      case 'strait':
        this.debrisStrait(
          blobs,
          spec.centre * W,
          spec.gap * W,
          (spec.mouth ?? 0.5) * W,
          y,
          spec.depth ?? 250,
        );
        break;
      case 'shrapnel': {
        let side = spec.first ?? 1;
        for (let row = 0; row < spec.rows; row++) {
          const yy = this.back(y, (spec.rows - 1 - row) * 210);
          const centre = clampX(W * 0.5 + side * spec.swing * W, W);
          this.debrisLine(blobs, centre, spec.gap * W, yy, W * 0.019);
          side = (side === 1 ? -1 : 1) as -1 | 1;
        }
        break;
      }
      case 'node':
        // The medium as the hazard, and in vacuum the medium is gravity - so the
        // hazard is a well, and it is the same object the player's own hand lays.
        // Debris rings it at the radius where a real one would have collected.
        if (spec.gap !== undefined) this.debrisLine(blobs, spec.centre * W, spec.gap * W, y, W * 0.022);
        wellHints.push({
          x: clampX(spec.centre * W, W),
          y: this.fwd(y, spec.radius * W * 0.1),
          radius: spec.radius * W,
          strength: spec.strength,
        });
        break;
      case 'flare':
        this.debrisCurtain(blobs, spec.gaps, spec.gap * W, y);
        break;

      // --- act V: the three shapes of re-entry ---
      case 'shock':
        // The mirror of an `arc`: bowed *toward* the swarm, so its middle is met
        // first and the way through opens as you slow into it.
        this.debrisArc(blobs, spec.centre * W, spec.gap * W, y, -spec.bow * W);
        break;
      case 'plume':
        this.plasmaPlume(blobs, spec.centre * W, spec.radius * W, y, spec.height ?? 2.8);
        break;
      case 'sheet':
        this.plasmaSheet(blobs, spec.gaps, spec.gap * W, y);
        break;
      case 'ember':
        // A short burnt stub of the vehicle, and then the pieces of it that are
        // still coming. The mass is deliberately small: this section's demand is
        // the thing overtaking you, not the thing standing in front of you, and a
        // full plume here would have the player reading the wrong hazard.
        this.plasmaPlume(blobs, spec.centre * W, spec.radius * W, y, 1.5);
        for (const h of spec.hunters) {
          hunterHints.push({
            x: clampX(h.x * W, W),
            y: this.back(y, h.dy),
            size: h.size,
            // Act V's threat always overtakes. See the `ember` note in
            // `levels.ts`: a fragment that ablates more slowly than the swarm
            // does is *behind* it and catching up, which is the only direction
            // this hazard makes physical sense from.
            stoop: h.stoop ?? true,
            form: 'ember',
          });
        }
        break;

      // --- act VI: the three shapes of coming down ---
      case 'downpour':
        this.rainCurtain(blobs, spec.centre * W, spec.gap * W, y, spec.depth ?? 140);
        break;
      case 'canopy':
        this.canopyTree(blobs, spec.centre * W, spec.radius * W, y, spec.height ?? 2.2);
        break;
      case 'boulder':
        this.brookStones(blobs, spec.centre * W, spec.gap * W, spec.radius * W, y);
        break;

      // --- act VII: the two soft ones ---
      case 'drape':
        this.homeDrape(blobs, spec.strands, y, spec.reach ?? 300);
        break;
      case 'bloom':
        this.homeBloom(blobs, spec.centre * W, spec.radius * W, y, spec.spread ?? 1);
        break;
    }

    const podHints: PodHint[] = (spec.rings ?? []).map((ring) => ({
      x: clampX(ring.x * W, W),
      y: this.back(y, ring.dy),
      count: ring.count,
      required: ring.required ?? false,
      scale: ring.scale ?? 1,
    }));

    const built = section(
      id,
      spec.kind,
      y,
      blobs,
      podHints,
      vortexHints,
      hunterHints,
      wellHints,
      this.dir,
      { zone, level: entry.level, step: entry.step },
    );
    if (spec.motion !== undefined) this.setMotion(built, spec.motion);
    return built;
  }

  /** Wall from each edge up to the gap. The one shape every archetype is built of. */
  private gateWalls(out: Blob[], centre: number, gap: number, y: number, radius = 0): void {
    const r = radius > 0 ? radius : Math.max(16, this.width * 0.05);
    chain(out, -r, centre - gap * 0.5, y, r);
    chain(out, centre + gap * 0.5, this.width + r, y, r);
  }

  /** A central mass with two lobes, and optionally a tooth on each edge. */
  private rockMass(out: Blob[], cx: number, R: number, y: number, teeth: boolean): void {
    out.push({ x: cx, y, r: R });
    out.push({ x: cx - R * 0.62, y: this.back(y, R * 0.55), r: R * 0.5 });
    out.push({ x: cx + R * 0.66, y: this.fwd(y, R * 0.5), r: R * 0.46 });
    if (!teeth) return;
    const tooth = this.width * 0.06;
    out.push({ x: -tooth * 0.35, y: this.fwd(y, R * 1.6), r: tooth });
    out.push({ x: this.width + tooth * 0.35, y: this.back(y, R * 1.6), r: tooth });
  }

  /**
   * Slowblue: cloud, as collision geometry.
   *
   * Everything in act I is a *chain*: circles of one radius, evenly spaced, on one
   * line. That is right for rock, whose silhouette is a hull anyway, and it is the
   * single reason the first act II read as pale masonry hanging in the sky - a
   * cumulus is not a wall, it is a pile.
   *
   * So a cloud run is the same primitive with the two things a pile has and a wall
   * does not: **the puffs differ in size, and they do not sit on the line.** Both
   * come from a position hash rather than from the section's rng, so a cloud is the
   * same cloud every time the course rebuilds it, exactly like `chain`'s wobble.
   *
   * `stop` is the edge the run must not cross - the gap the level authored. Puffs
   * are pulled back so their *rim* lands on it rather than their centre, which is
   * what keeps a soft edge from quietly eating a corridor the flood fill has
   * already approved. `taper` shrinks them toward that edge: a hole in a deck is
   * torn, and the torn end is where the cloud is thinnest.
   */
  private cloudRun(
    out: Blob[],
    from: number,
    stop: number,
    y: number,
    r: number,
    taper = 0.5,
    flat = 1,
  ): void {
    const dir = stop >= from ? 1 : -1;
    const len = Math.abs(stop - from);
    if (len <= 1) return;
    for (let travelled = 0; ; ) {
      const t = Math.min(1, travelled / len);
      const scale = 1 + (taper - 1) * t;
      const pick = puffPick(from + dir * travelled, y);
      const rad = Math.max(6, r * scale * (0.8 + pick * 0.55));
      // Centre pulled back so the rim, not the centre, is what meets the gap.
      const reach = travelled + rad;
      const x = from + dir * (reach > len ? Math.max(0, len - rad) : travelled);
      out.push({ x, y: y + (pick - 0.5) * r * 1.15 * flat, r: rad });
      if (reach > len) return;
      travelled += Math.max(4, r * scale * 0.6);
    }
  }

  /**
   * A cumulus deck across the course with one hole torn in it - the air's gate.
   *
   * Two rows rather than one, offset up the course and down in x, because a deck
   * has depth: a bank you can see the far side of is a line of cloud, and a line of
   * cloud is a fence. `flat` squashes the whole thing into a lens for the rotor.
   */
  private cloudDeck(
    out: Blob[],
    centre: number,
    gap: number,
    y: number,
    r: number,
    depth: number,
    flat = 1,
  ): void {
    const W = this.width;
    const left = centre - gap * 0.5;
    const right = centre + gap * 0.5;
    this.cloudRun(out, -r * 0.5, left, y, r, 0.5, flat);
    this.cloudRun(out, W + r * 0.5, right, y, r, 0.5, flat);
    if (depth <= 0) return;
    // The second row is drawn *back* along the course and stops short of the same
    // gap, so the hole through the deck is a short tunnel rather than a doorway.
    const inset = r * 0.5;
    const behind = this.back(y, depth);
    this.cloudRun(out, -r * 0.5, left - inset, behind, r * 0.82, 0.6, flat);
    this.cloudRun(out, W + r * 0.5, right + inset, behind, r * 0.82, 0.6, flat);
  }

  /**
   * A towering cumulus: the air's splittable mass.
   *
   * It is authored *tall*, which is the whole difference between this and a rock.
   * A rock is a lump with two lobes; a cumulus congestus is a column with a wide
   * base, a waist where it has been eaten into by dry air, and a crown that
   * spreads. `height` is that column's length as a multiple of its radius.
   */
  private cloudTower(out: Blob[], cx: number, R: number, y: number, height: number): void {
    const reach = R * height;
    // Base at +Y (met first), crown ahead of the line. The lean is keyed to the
    // tower's own position: cumulus leans with the wind, and always the same way
    // for the same cloud.
    const lean = (puffPick(cx, y) - 0.5) * R * 0.5;
    const profile = [1, 0.94, 0.78, 0.66, 0.58, 0.72] as const;
    for (let i = 0; i < profile.length; i++) {
      const t = i / (profile.length - 1);
      const rr = R * profile[i]!;
      const yy = this.back(y, reach * 0.34 - reach * t);
      const pick = puffPick(cx + i * 37, yy);
      out.push({ x: cx + lean * t, y: yy, r: rr });
      // One offset shoulder per level, alternating sides: this is what stops the
      // stack from hulling into a sausage.
      const side = i % 2 === 0 ? -1 : 1;
      out.push({
        x: cx + lean * t + side * rr * 0.52,
        y: yy + rr * (pick - 0.5) * 0.5,
        r: rr * (0.5 + pick * 0.24),
      });
    }
    // Edge cloud, so the two channels are channels and not open sky.
    const edge = this.width * 0.055;
    out.push({ x: -edge * 0.3, y: this.fwd(y, reach * 0.5), r: edge });
    out.push({ x: this.width + edge * 0.3, y: this.back(y, reach * 0.35), r: edge });
  }

  /**
   * Two cloud shoulders converging into a slot, entered from below - the air's
   * narrows. The walls are built of the same puffs as a deck, so what closes in on
   * the flock is vapour rather than a funnel with sides.
   */
  private cloudPass(
    out: Blob[],
    centre: number,
    gap: number,
    mouth: number,
    y: number,
    depth: number,
  ): void {
    const r = Math.max(15, this.width * 0.05);
    const steps = Math.max(6, Math.ceil(Math.hypot(mouth - gap * 0.5, depth) / (r * 0.8)));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const half = mouth + (gap * 0.5 - mouth) * t;
      const yy = this.back(y, (1 - t) * depth);
      // Toward the slot the cloud thins - a gap in weather is a gap because the
      // air there is dry, and dry air is where cloud stops.
      const rr = r * (1 - t * 0.34);
      for (const side of [-1, 1] as const) {
        const x = centre + side * half;
        const pick = puffPick(x, yy);
        // Pulled outward by its own radius so the authored slot stays the slot.
        out.push({
          x: x + side * rr * (0.55 + pick * 0.3),
          y: yy + (pick - 0.5) * rr * 0.7,
          r: rr * (0.85 + pick * 0.4),
        });
      }
    }
    this.cloudDeck(out, centre, gap, y, r * 0.95, 0);
  }

  /**
   * Slowblue: a cloud street, and the one thing on the course that is not a hole.
   *
   * Every other archetype in the game is an *aperture*: the swarm has to be at
   * one x when its centroid crosses one line, and everything else about the
   * geometry is scenery. That is true of a gate, a bank, a veil, an arc and a
   * shock alike, which is the deepest reason seven acts of different silhouettes
   * still played as one act - the demand was over in a frame every time.
   *
   * A street is the same cloud asked for something else. The mouth opens the full
   * width, converges over a couple of hundred pixels, and then simply *runs* -
   * two lines of vapour going the way the flock is going, six or seven hundred
   * pixels of it, with the corridor between them. Nothing has to be threaded.
   * What has to happen is that the flock is still in there at the far end, and
   * `AmbientFlow` changes sign about twice across that distance (a 480 px octave
   * on a 390 px field), so holding it is work for the whole run rather than for
   * one moment of it.
   *
   * The steps are deliberately coarse - `r * 0.9` against a deck's `r * 0.6` -
   * because this is by far the longest run of blobs on the course and a street
   * built at a deck's grain would cost more circles than the station around it.
   * They still overlap by a tenth of a diameter, which is what the flood fill
   * needs to read them as a wall rather than as a row of beads with sky between.
   */
  private cloudStreet(
    out: Blob[],
    centre: number,
    gap: number,
    y: number,
    length: number,
    mouth: number,
  ): void {
    const r = Math.max(15, this.width * 0.052);
    const half = gap * 0.5;
    // The mouth is a third of the street at most: a funnel that went on for half
    // of it would be a `pass` with a tail, and the tail is the whole archetype.
    const throat = Math.min(Math.max(150, length * 0.3), length * 0.45);
    const run = length - throat;
    for (const side of [-1, 1] as const) {
      const x = centre + side * half;
      for (let t = 0; t <= run; t += r * 0.9) {
        const yy = this.back(y, t);
        const pick = puffPick(x + t, yy);
        // Pushed outward by a fraction of its own radius, so the authored
        // corridor stays the corridor rather than being eaten by the softness.
        out.push({ x: x + side * r * (0.45 + pick * 0.3), y: yy, r: r * (0.82 + pick * 0.36) });
      }
    }
    // The mouth: the same two lines opening back out to `mouth`. At the widths
    // act II authors this at the shoulders run off both edges of the field, which
    // is correct and is why there is no deck across the entry - a street is
    // entered from anywhere and left from one place.
    const steps = Math.max(5, Math.ceil(throat / (r * 0.9)));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const hw = half + (mouth - half) * t;
      const yy = this.back(y, run + throat * t);
      for (const side of [-1, 1] as const) {
        const x = centre + side * hw;
        const pick = puffPick(x, yy);
        out.push({ x: x + side * r * 0.5, y: yy, r: r * (0.85 + pick * 0.3) });
      }
    }
  }

  /**
   * Slowblue: ice, as collision geometry.
   *
   * Cloud is a pile of large soft puffs that do not sit on their own line. Ice is
   * the opposite of every part of that: **many small blobs, on the line, evenly
   * spaced, and all nearly the same size.** A curtain of crystal is a regular
   * thing - it is what you get when a single air mass freezes out at a single
   * temperature - and its regularity is exactly what tells the player at a glance
   * that they have left the weather.
   *
   * The grain (`r`) is roughly a third of a cloud puff's and about a fifth of a
   * rock bead's, so the same authored gap reads as a *finer* obstacle without the
   * corridor being any narrower. That matters: act III is not harder than act II
   * in the width it asks for, it is harder in the timing, and the geometry must
   * not quietly say otherwise.
   *
   * Determinism comes from `puffPick` on world position, exactly as cloud's does,
   * so a curtain is the same curtain on every rebuild and every replay.
   */
  private crystalRun(
    out: Blob[],
    from: number,
    stop: number,
    y: number,
    r: number,
    flat = 1,
  ): void {
    const dir = stop >= from ? 1 : -1;
    const len = Math.abs(stop - from);
    if (len <= 1) return;
    // Overlapping by a fifth: a curtain has to be a wall to the flood fill even
    // though it reads as separate crystals, or the corridor sweep would approve a
    // route straight between two of them that the player cannot actually take.
    const step = Math.max(3, r * 1.6);
    const n = Math.max(1, Math.ceil(len / step));
    for (let i = 0; i <= n; i++) {
      const travelled = (len * i) / n;
      const x = from + dir * travelled;
      const pick = puffPick(x, y);
      // Small variance only. A crystal field with cloud's size spread reads as
      // gravel, and gravel is a thing act I already owns.
      const rad = r * (0.86 + pick * 0.3);
      out.push({ x, y: y + (pick - 0.5) * r * 0.9 * flat, r: rad });
    }
  }

  /**
   * A curtain of ice across the course with one or more doors torn in it.
   *
   * `doors` are centres as fractions of width. One door is the act's gate; two or
   * three is its `shear`, which is the same shape asked to carry a decision -
   * every door opens into the same next layer, and *where along it* you arrive is
   * what the layer then does with you.
   */
  private crystalCurtain(
    out: Blob[],
    doors: number[],
    gap: number,
    y: number,
    r: number,
    depth: number,
    flat = 1,
  ): void {
    const W = this.width;
    const edges = doors
      .map((d) => ({ lo: d * W - gap * 0.5, hi: d * W + gap * 0.5 }))
      .sort((a, b) => a.lo - b.lo);
    let cursor = -r;
    for (const door of edges) {
      this.crystalRun(out, cursor, Math.max(cursor, door.lo), y, r, flat);
      cursor = Math.max(cursor, door.hi);
    }
    this.crystalRun(out, cursor, W + r, y, r, flat);
    if (depth <= 0) return;
    // A second, finer curtain a little back down the course, offset inward, so a
    // door is a short passage rather than a slot in a sheet of paper.
    const behind = this.back(y, depth);
    const inset = r * 1.1;
    let back = -r;
    for (const door of edges) {
      this.crystalRun(out, back, Math.max(back, door.lo - inset), behind, r * 0.8, flat);
      back = Math.max(back, door.hi + inset);
    }
    this.crystalRun(out, back, W + r, behind, r * 0.8, flat);
  }

  /**
   * A rising column of crystal: the upper air's splittable mass.
   *
   * Where a cumulus tower is a pile with a waist and a spreading crown, this is a
   * *shaft* - even from base to top, because what makes an ice column is air
   * going up a chimney at one speed and freezing out along all of it. It is
   * authored taller and thinner than either the rock or the tower, so the two
   * channels either side of it are wider than anything since the trench floor,
   * which is deliberate: act III asks for its precision in time, not in width.
   */
  private crystalColumn(out: Blob[], cx: number, R: number, y: number, height: number): void {
    const reach = R * height;
    const grain = Math.max(6, R * 0.42);
    const steps = Math.max(6, Math.ceil(reach / (grain * 1.35)));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const yy = this.back(y, reach * 0.35 - reach * t);
      const pick = puffPick(cx + i * 53, yy);
      // A slight taper toward the top, and facets alternating either side: a
      // crystal shaft is not a cylinder, it is a stack of plates.
      const rr = R * (1 - t * 0.22) * (0.82 + pick * 0.3);
      out.push({ x: cx, y: yy, r: rr });
      const side = i % 2 === 0 ? -1 : 1;
      out.push({ x: cx + side * rr * 0.62, y: yy, r: rr * (0.42 + pick * 0.2) });
    }
    // Edge crystal, so the two channels are channels and not open sky.
    const edge = this.width * 0.05;
    out.push({ x: -edge * 0.35, y: this.fwd(y, reach * 0.45), r: edge });
    out.push({ x: this.width + edge * 0.35, y: this.back(y, reach * 0.3), r: edge });
  }

  /**
   * Two crystal shoulders converging into a slot, entered from below - the upper
   * air's narrows. Built of the curtain's own grain, so what closes in on the
   * swarm is the same ice everything else up here is made of.
   */
  private crystalThroat(
    out: Blob[],
    centre: number,
    gap: number,
    mouth: number,
    y: number,
    depth: number,
  ): void {
    const r = Math.max(9, this.width * 0.03);
    const steps = Math.max(8, Math.ceil(Math.hypot(mouth - gap * 0.5, depth) / (r * 1.2)));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const half = mouth + (gap * 0.5 - mouth) * t;
      const yy = this.back(y, (1 - t) * depth);
      const rr = r * (1 - t * 0.2);
      for (const side of [-1, 1] as const) {
        const x = centre + side * half;
        const pick = puffPick(x, yy);
        // Pulled outward by its own radius, so the authored slot stays the slot.
        out.push({ x: x + side * rr * 0.5, y: yy, r: rr * (0.9 + pick * 0.25) });
      }
    }
    this.crystalCurtain(out, [centre / this.width], gap, y, r, 0);
  }

  /**
   * Slowblue: debris, as collision geometry.
   *
   * Three media have made three kinds of line. Rock is a chain of equal beads;
   * cloud is a pile of large soft puffs off their own line; ice is many small
   * facets *on* the line, evenly spaced and nearly equal. Debris is the one that
   * is not a line at all.
   *
   * Nothing in orbit erodes, condenses, settles or sticks. What is up there is
   * whatever was left, in whatever size it broke into, spread along a shared
   * trajectory - so a debris run is **sparse, and wildly unequal**: a few large
   * hulks, a lot of small chips, vacuum between all of them, and no two the same
   * size. The vertical scatter is large for the same reason: things in slightly
   * different orbits are at slightly different altitudes forever.
   *
   * That sparseness is act IV's design rather than a softening of it. The demand
   * here is never "can you fit through" - you always can, and the flood fill will
   * say so. It is that a mote in free fall cannot turn, so the gap you can see is
   * one you had to start arcing toward ten seconds ago.
   */
  private debrisRun(out: Blob[], from: number, stop: number, y: number, r: number): void {
    const dir = stop >= from ? 1 : -1;
    const len = Math.abs(stop - from);
    if (len <= 1) return;
    // Spacing is a multiple of the grain rather than a fraction of it, which is
    // what puts real vacuum between the pieces. Everything else on the course
    // overlaps its neighbour; this is the one thing in the game that does not.
    const step = Math.max(6, r * 3.4);
    const n = Math.max(1, Math.ceil(len / step));
    for (let i = 0; i <= n; i++) {
      const travelled = (len * i) / n;
      const x = from + dir * travelled;
      const pick = puffPick(x, y);
      const size = puffPick(x + 977, y - 641);
      // Cubed, so most pieces are chips and a few are hulks. A linear spread
      // reads as gravel; this reads as a break-up.
      const rad = Math.max(4, r * (0.3 + 2.6 * size * size * size));
      out.push({ x, y: y + (pick - 0.5) * r * 5, r: rad });
    }
  }

  /**
   * A line of debris across the course with one or more ways through it.
   *
   * `doors` are centres as fractions of width - one for a plain line, two or
   * three for the auroral curtain. Unlike the ice curtain there is no second row:
   * a debris field has no depth to it, because nothing holds it together.
   */
  private debrisCurtain(out: Blob[], doors: number[], gap: number, y: number): void {
    const W = this.width;
    const r = Math.max(7, W * 0.02);
    const edges = doors
      .map((d) => ({ lo: d * W - gap * 0.5, hi: d * W + gap * 0.5 }))
      .sort((a, b) => a.lo - b.lo);
    let cursor = -r;
    for (const door of edges) {
      this.debrisRun(out, cursor, Math.max(cursor, door.lo), y, r);
      cursor = Math.max(cursor, door.hi);
    }
    this.debrisRun(out, cursor, W + r, y, r);
  }

  /** One line of debris with a single hole. Used by the chicane's rows. */
  private debrisLine(out: Blob[], centre: number, gap: number, y: number, r: number): void {
    const W = this.width;
    this.debrisRun(out, -r, centre - gap * 0.5, y, r);
    this.debrisRun(out, W + r, centre + gap * 0.5, y, r);
  }

  /**
   * An orbital gate: the one archetype in the game that asks for a *curve*.
   *
   * The wall is bowed along the course - its two halves sweep back from the
   * opening by `bow` - so the hole is not reachable in a straight line from where
   * the swarm meets the section. Aim at it and the geometry arrives before the
   * swarm does; the only way through is an arc laid early, which in vacuum means
   * a well placed off to one side and a good deal of patience.
   *
   * This is act IV's entire subject expressed as one shape, and it is why the act
   * needs no tutorial for its new input: the first `arc` teaches, by failing to
   * be aimable, that aiming has stopped being the verb.
   */
  private debrisArc(out: Blob[], centre: number, gap: number, y: number, bow: number): void {
    const W = this.width;
    const r = Math.max(8, W * 0.022);
    const half = gap * 0.5;
    for (const side of [-1, 1] as const) {
      const from = centre + side * half;
      const to = side < 0 ? -r : W + r;
      const span = Math.abs(to - from);
      const n = Math.max(3, Math.ceil(span / (r * 3.4)));
      for (let i = 0; i <= n; i++) {
        const t = i / n;
        const x = from + (to - from) * t;
        // A parabola whose *tips* are met first and whose opening lies deepest
        // along the course: the mouth is the only part of this wall the swarm can
        // reach without already turning, and it has to be turning before the tips
        // arrive. `bow` is positive here and negative for act V's `shock`, which
        // is the same parabola the other way up - see `case 'shock'`.
        //
        // Slowblue: this term was `-bow` and every one of the five written
        // descriptions of the shape - this comment, `levels.ts`'s `arc` and
        // `shock`, `ObstacleSystem.buildSpec`'s shock case and act V's aurora -
        // described the mirror of what it built. With the sign inverted an arc's
        // wing tips sat *further along* the course than its mouth, so the deeper
        // the bow the less the wall blocked, and act IV's one declared escalation
        // axis ran backwards. Measured with `tools/finish.sweep.ts`: orbit went
        // 0/11 finished to 3/11, furthest section 4.2/18 to 11.5/18.
        const yy = this.back(y, bow * t * t);
        const pick = puffPick(x, yy);
        const size = puffPick(x + 311, yy + 733);
        out.push({
          x,
          y: yy + (pick - 0.5) * r * 3,
          r: Math.max(4, r * (0.35 + 2.2 * size * size * size)),
        });
      }
    }
  }

  /**
   * A dead hulk: orbit's splittable mass, and the hardest edge in the game.
   *
   * Everything else the campaign asks the swarm to split around is soft or
   * granular - a worn rock, a cumulus, a crystal shaft. This is a manufactured
   * object that stopped working, so it is the one mass built from a *few large
   * pieces at angles to each other* rather than from a graded run, and it keeps
   * a debris halo of the chips it shed.
   */
  private debrisHulk(out: Blob[], cx: number, R: number, y: number): void {
    out.push({ x: cx, y, r: R });
    out.push({ x: cx - R * 0.78, y: this.back(y, R * 0.72), r: R * 0.44 });
    out.push({ x: cx + R * 0.7, y: this.fwd(y, R * 0.66), r: R * 0.4 });
    out.push({ x: cx + R * 0.2, y: this.fwd(y, R * 1.25), r: R * 0.26 });
    // The chips it shed, still travelling with it, spread along the same orbit.
    for (let i = 0; i < 7; i++) {
      const pick = puffPick(cx + i * 149, y + i * 89);
      const spin = puffPick(cx - i * 71, y - i * 53);
      out.push({
        x: clampX(cx + (pick - 0.5) * R * 5.5, this.width),
        y: this.back(y, (spin - 0.5) * R * 4.5),
        r: Math.max(4, R * (0.06 + pick * 0.12)),
      });
    }
    // Edge debris, so the two channels are channels and not open sky.
    const edge = this.width * 0.045;
    out.push({ x: -edge * 0.4, y: this.fwd(y, R * 1.7), r: edge });
    out.push({ x: this.width + edge * 0.4, y: this.back(y, R * 1.7), r: edge });
  }

  /**
   * Two debris streams converging into a lane - orbit's narrows. The walls are
   * the same sparse chunks as everything else up here, so what closes in is a
   * thinning of the way through rather than a funnel with sides.
   */
  private debrisStrait(
    out: Blob[],
    centre: number,
    gap: number,
    mouth: number,
    y: number,
    depth: number,
  ): void {
    const r = Math.max(7, this.width * 0.021);
    const steps = Math.max(6, Math.ceil(Math.hypot(mouth - gap * 0.5, depth) / (r * 2.6)));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const half = mouth + (gap * 0.5 - mouth) * t;
      const yy = this.back(y, (1 - t) * depth);
      for (const side of [-1, 1] as const) {
        const x = centre + side * half;
        const pick = puffPick(x, yy);
        const size = puffPick(x + 419, yy + 257);
        // Pulled outward by its own radius, so the authored lane stays the lane.
        out.push({
          x: x + side * r * (0.6 + pick * 0.5),
          y: yy + (pick - 0.5) * r * 2.4,
          r: Math.max(4, r * (0.4 + 2 * size * size * size)),
        });
      }
    }
    this.debrisLine(out, centre, gap, y, r);
  }

  /**
   * Slowblue: plasma, as collision geometry.
   *
   * The one material in the game that is *not a thing*. Rock, cloud, ice and
   * wreckage are all objects the swarm can hit; a shock front is a region of air
   * that has been compressed until it glows, and what it does to a mote is not
   * impact but ablation. Geometrically that makes it the densest, finest and most
   * *continuous* run on the course - the opposite of debris, which is what it is
   * turning back into air out of.
   *
   * So the grain is small and the spacing is tight, and the vertical scatter is
   * almost nothing: a shock front is a surface, and surfaces are smooth.
   */
  private plasmaRun(out: Blob[], from: number, stop: number, y: number, r: number): void {
    const dir = stop >= from ? 1 : -1;
    const len = Math.abs(stop - from);
    if (len <= 1) return;
    const step = Math.max(3, r * 1.4);
    const n = Math.max(1, Math.ceil(len / step));
    for (let i = 0; i <= n; i++) {
      const travelled = (len * i) / n;
      const x = from + dir * travelled;
      const pick = puffPick(x, y);
      out.push({ x, y: y + (pick - 0.5) * r * 0.6, r: r * (0.9 + pick * 0.2) });
    }
  }

  /** A band of ionised air across the course with doors burned through it. */
  private plasmaSheet(out: Blob[], doors: number[], gap: number, y: number): void {
    const W = this.width;
    const r = Math.max(8, W * 0.026);
    const edges = doors
      .map((d) => ({ lo: d * W - gap * 0.5, hi: d * W + gap * 0.5 }))
      .sort((a, b) => a.lo - b.lo);
    let cursor = -r;
    for (const door of edges) {
      this.plasmaRun(out, cursor, Math.max(cursor, door.lo), y, r);
      cursor = Math.max(cursor, door.hi);
    }
    this.plasmaRun(out, cursor, W + r, y, r);
  }

  /**
   * An ablation plume: re-entry's splittable mass.
   *
   * A body coming in at eight kilometres a second does not have a wake, it has a
   * *tail* - a long, narrow, tapering column of glowing gas streaming back the way
   * it came. So this is authored the opposite way round from every other column in
   * the game: widest at its head, thinning to nothing behind it, and it is the
   * only mass in the campaign whose two channels get *wider* as you pass it.
   */
  private plasmaPlume(out: Blob[], cx: number, R: number, y: number, height: number): void {
    const reach = R * height;
    const grain = Math.max(5, R * 0.34);
    const steps = Math.max(8, Math.ceil(reach / (grain * 1.1)));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      // t = 0 is the head, met first; the tail streams back down the course.
      //
      // Slowblue: the two terms were the other way round, so the thin tail arrived
      // first and the wide head last - the channels narrowed as the swarm passed,
      // which is what every other mass in the game does and the exact opposite of
      // the sentence above this function.
      const yy = this.back(y, reach * 0.25 - reach * t);
      const pick = puffPick(cx + i * 41, yy);
      const rr = R * (1 - t * 0.82) * (0.85 + pick * 0.3);
      if (rr < 3) break;
      out.push({ x: cx, y: yy, r: rr });
      if (t < 0.5) {
        const side = i % 2 === 0 ? -1 : 1;
        out.push({ x: cx + side * rr * 0.55, y: yy, r: rr * (0.4 + pick * 0.2) });
      }
    }
    // Edge fire, so the two channels are channels and not open sky.
    const edge = this.width * 0.05;
    out.push({ x: -edge * 0.35, y: this.fwd(y, reach * 0.35), r: edge });
    out.push({ x: this.width + edge * 0.35, y: this.back(y, reach * 0.25), r: edge });
  }

  /**
   * Slowblue: rain, as collision geometry.
   *
   * A downpour is not a wall and not a pile - it is a *vertical* thing, and that
   * is the one property this whole act turns on. Every obstacle in the game so
   * far has been laid across the course; falling water runs along it. So a rain
   * curtain is drawn as a set of short columns rather than as a line of beads,
   * and what it asks of the swarm is to find the slot of lighter rain between two
   * heavier shafts.
   *
   * It is also the first archetype whose geometry points the way the swarm is
   * going, which is exactly what the act is about: from here everything in the
   * world is falling too.
   */
  private rainCurtain(
    out: Blob[],
    centre: number,
    gap: number,
    y: number,
    depth: number,
  ): void {
    const W = this.width;
    const r = Math.max(8, W * 0.028);
    const left = centre - gap * 0.5;
    const right = centre + gap * 0.5;
    for (const [from, stop] of [
      [-r, left],
      [W + r, right],
    ] as const) {
      const dir = stop >= from ? 1 : -1;
      const len = Math.abs(stop - from);
      if (len <= 1) continue;
      /*
       * The columns overlap by a fifth and every one of them has a bead within a
       * few pixels of the section's own line.
       *
       * Slowblue: the step was `r * 1.5`, i.e. further apart than a bead is wide, and
       * the shaft was 2 to 4 beads distributed over `depth` - so a quarter of the
       * columns had nothing at the line at all, and the act's own "commit to one
       * gap" archetype had real holes in the part that is supposed to be solid. It
       * is the same failure `crystalRun` was written to prevent and documents in as
       * many words: a wall made of beads with water between them is not a wall, it
       * is a suggestion, and a curtain of falling water is exactly the shape where
       * the player will believe it.
       */
      const step = Math.max(4, r * 1.1);
      const n = Math.max(1, Math.ceil(len / step));
      for (let i = 0; i <= n; i++) {
        const x = from + dir * (len * i) / n;
        const pick = puffPick(x, y);
        // A shaft: three or four beads down the course rather than one across it,
        // and never two, because at two the `k / shaft - 0.3` offsets straddle the
        // line instead of landing on it.
        const shaft = Math.max(3, Math.round(3 + pick));
        for (let k = 0; k < shaft; k++) {
          out.push({
            x,
            y: this.back(y, depth * (k / shaft - 0.3)),
            r: r * (0.75 + pick * 0.35),
          });
        }
      }
    }
  }

  /**
   * A tree: act VI's splittable mass, and the first living obstacle in the game.
   *
   * Everything the campaign has asked the swarm to split around has been widest
   * where it was met. A tree is the opposite: a narrow trunk, and a crown that
   * spreads *above* it - which on a descending course means the wide part is met
   * first and the way round opens up as the swarm falls past. That inversion is
   * the entire reason this is not act I's rock with leaves on it.
   */
  private canopyTree(out: Blob[], cx: number, R: number, y: number, height: number): void {
    const reach = R * height;
    // The crown, met first: a spreading mass of foliage.
    for (let i = 0; i < 5; i++) {
      const pick = puffPick(cx + i * 67, y + i * 31);
      const t = i / 4;
      out.push({
        x: cx + (pick - 0.5) * R * 1.5,
        y: this.back(y, reach * 0.28 - reach * 0.16 * t),
        r: R * (0.5 + pick * 0.4),
      });
    }
    // ...and the trunk under it, thin and straight, with the two ways round.
    const trunk = Math.max(5, R * 0.2);
    const steps = Math.max(4, Math.ceil(reach / (trunk * 2.4)));
    for (let i = 0; i <= steps; i++) {
      out.push({ x: cx, y: this.fwd(y, (reach * 0.5 * i) / steps), r: trunk });
    }
    // Undergrowth at the edges, so the two channels are channels.
    const edge = this.width * 0.05;
    out.push({ x: -edge * 0.35, y: this.fwd(y, reach * 0.4), r: edge });
    out.push({ x: this.width + edge * 0.35, y: this.back(y, reach * 0.25), r: edge });
  }

  /**
   * Stones in running water, and the closest the campaign comes to repeating
   * itself - deliberately.
   *
   * A boulder in a mountain brook is the same object as a stone on the trench
   * floor: the same rock, six thousand metres higher, with the water going the
   * other way. So this is built with `rockMass`'s own grammar rather than a new
   * one, because inventing a fifth silhouette for a thing that genuinely is a
   * rock would be the campaign lying to look varied. What is different is that
   * there are *two* of them with the channel between, which is what a brook is.
   */
  private brookStones(out: Blob[], centre: number, gap: number, R: number, y: number): void {
    for (const side of [-1, 1] as const) {
      const cx = centre + side * (gap * 0.5 + R);
      out.push({ x: cx, y, r: R });
      const pick = puffPick(cx, y);
      out.push({
        x: cx + side * R * 0.6,
        y: this.back(y, R * (0.4 + pick * 0.5)),
        r: R * (0.45 + pick * 0.2),
      });
      out.push({ x: cx - side * R * 0.5, y: this.fwd(y, R * 0.55), r: R * 0.4 });
    }
    // The banks: a brook has sides, and they are the one place in this act where
    // the course really does narrow.
    const bank = this.width * 0.07;
    out.push({ x: -bank * 0.25, y, r: bank });
    out.push({ x: this.width + bank * 0.25, y: this.back(y, R * 0.8), r: bank });
  }

  /**
   * Slowblue: soft bodies, as collision geometry.
   *
   * Five materials have made five kinds of line, and every one of them is a wall
   * with something missing from it: rock chains, cloud piles, ice rules a line of
   * facets, debris scatters, plasma runs continuous. All five close the course
   * somewhere, because all five are things that stop a body.
   *
   * A siphonophore does not stop anything. It is forty metres long, it is
   * ninety-five per cent water, and what it does to a swarm of larvae is take a
   * few of them and let the rest through - so the geometry has to be made of
   * **threads with real water between them**, hanging *along* the course rather
   * than laid across it, and it has to be authored so that the way past is never
   * a question. Act VII's rule is that nothing in it closes the course, and this
   * is the shape that rule was written for.
   *
   * `strands` are x centres as fractions of width. Met from above, because act
   * VII falls: the section's line is at the *bottom* of the curtain, so the whole
   * thing is behind the swarm by the time it is scored.
   */
  private homeDrape(out: Blob[], strands: number[], y: number, reach: number): void {
    const W = this.width;
    // Thicker than the first cut of this, which tapered to a four-pixel thread.
    // A strand the swarm's own avoidance sails past without ever being deflected
    // is not a soft obstacle, it is decoration with a collision mask - and act
    // VII already has a decor layer for things that are only there to be seen.
    const r = Math.max(9, W * 0.031);
    for (const s of strands) {
      const x0 = clampX(s * W, W);
      const steps = Math.max(4, Math.ceil(reach / (r * 1.35)));
      for (let i = 0; i <= steps; i++) {
        const t = i / steps;
        const yy = this.back(y, reach * (1 - t));
        const pick = puffPick(x0 + i * 61, yy);
        // A tentacle drifts. The lateral wander is small, keyed to position like
        // everything else here, and it is what stops three strands from reading
        // as three rules drawn with a straightedge.
        const x = x0 + Math.sin(t * 3.1 + s * 7) * r * 1.6 + (pick - 0.5) * r * 0.8;
        // The bell is at the top - the float the whole animal hangs from - and
        // the strand thins along its length without ever thinning to nothing.
        const rr = r * (t < 0.14 ? 1.9 - t * 4.4 : 0.98 - t * 0.3) * (0.88 + pick * 0.24);
        if (rr < 2) break;
        out.push({ x, y: yy, r: rr });
      }
    }
  }

  /**
   * A bloom of medusae: act VII's mass, and the only one in the campaign the
   * swarm is meant to go *through* rather than round.
   *
   * Every other splittable mass in the game is one body with two channels either
   * side, and being split on it is the scoring verb (`SPLITTABLE` in `World.ts`,
   * which this is deliberately not in). A bloom is the opposite arrangement of
   * the same idea: several small bodies with water between all of them, so the
   * swarm neither splits nor threads - it drifts through, losing a little at the
   * edges, which is exactly what happens to plankton in one.
   *
   * `spread` opens the bodies apart without making any of them bigger, so a
   * denser bloom and a wider one are two different authoring decisions rather
   * than one number doing both jobs badly.
   */
  private homeBloom(out: Blob[], cx: number, R: number, y: number, spread: number): void {
    // Seven bells, laid on a fixed lattice that is then jittered by position, so
    // a bloom is the same bloom on every rebuild and no two of them are alike.
    const lattice = [
      [-1, -0.62],
      [0.34, -0.9],
      [-0.46, 0.1],
      [0.86, 0.16],
      [-0.94, 0.78],
      [0.12, 0.72],
      [0.72, 1.14],
    ] as const;
    for (const [ux, uy] of lattice) {
      const pick = puffPick(cx + ux * 311, y + uy * 733);
      const size = puffPick(cx - ux * 149, y - uy * 89);
      const x = clampX(cx + ux * R * 1.75 * spread + (pick - 0.5) * R * 0.5, this.width);
      const yy = this.back(y, -uy * R * 1.5 - (pick - 0.5) * R * 0.6);
      // A medusa is round and they are not all the same age. No lobes and no
      // shoulder: a bell is one dome, and giving it a second one would make it
      // a small cloud, which is a material this act does not have.
      out.push({ x, y: yy, r: Math.max(7, R * (0.34 + size * 0.5)) });
    }
  }

  /** Situation 1: an offset wide gate. Teaches "the water carries them sideways". */
  private buildGate(id: number, y: number, diff: number, rng: Rng): Section {
    const W = this.width;
    const gap = W * (0.44 - 0.16 * diff);
    const side = rng.next() < 0.5 ? -1 : 1;
    const centre = W * 0.5 + side * (W * 0.5 - gap * 0.5 - W * 0.08) * rng.range(0.55, 1);
    const r = Math.max(16, W * 0.05);
    const blobs: Blob[] = [];
    chain(blobs, -r, centre - gap * 0.5, y, r);
    chain(blobs, centre + gap * 0.5, W + r, y, r);
    return section(id, 'gate', y, blobs, []);
  }

  /** Situation 2: a central rock. The shoal must split and re-merge. */
  private buildRock(id: number, y: number, diff: number, rng: Rng): Section {
    const W = this.width;
    const R = W * (0.19 + 0.07 * diff);
    const cx = W * 0.5 + rng.signed() * W * 0.06;
    const blobs: Blob[] = [
      { x: cx, y, r: R },
      { x: cx - R * 0.65, y: y + R * 0.55, r: R * 0.55 },
      { x: cx + R * 0.7, y: y - R * 0.5, r: R * 0.5 },
    ];
    // Edge teeth so the side channels are channels, not open ocean.
    const tooth = W * 0.07;
    blobs.push({ x: -tooth * 0.3, y: y - R * 1.6, r: tooth });
    blobs.push({ x: W + tooth * 0.3, y: y + R * 1.6, r: tooth });
    // One pod in the middle of each side channel. The channels are ~0.5W apart, which
    // is wider than a healthy shoal, so a single body can reach one of them and a
    // split body can reach both. That gap is the whole point of this section.
    const podY = y - R * 1.25;
    const podHints: PodHint[] = [
      { x: clampX((cx - R) * 0.5, W), y: podY, count: 9 + rng.int(0, 5) },
      { x: clampX(W - (W - cx - R) * 0.5, W), y: podY, count: 9 + rng.int(0, 5) },
    ];
    return section(id, 'rock', y, blobs, podHints);
  }

  /** Situation 3: a risky choke with a pod parked just off the safe line. */
  private buildNarrows(id: number, y: number, diff: number, rng: Rng): Section {
    const W = this.width;
    const gap = W * (0.28 - 0.1 * diff);
    const side = rng.next() < 0.5 ? -1 : 1;
    const centre = W * 0.5 + side * W * 0.16;
    const r = Math.max(14, W * 0.045);
    const blobs: Blob[] = [];
    // Two converging walls: a funnel entered from +Y, so late corrections fail.
    // Step count is derived from the radius, not hardcoded: with 7 steps the blobs
    // sat ~47px apart with r=17.5, leaving 12px gaps the shoal could swim straight
    // through - the funnel has to be a wall, not a row of beads.
    const wideHalf = W * 0.52;
    const span = Math.hypot(wideHalf - gap * 0.5, 240);
    const steps = Math.max(7, Math.ceil(span / (r * 0.75)));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const half = wideHalf + (gap * 0.5 - wideHalf) * t;
      const yy = y + (1 - t) * 240;
      blobs.push({ x: centre - half, y: yy, r });
      blobs.push({ x: centre + half, y: yy, r });
    }
    chain(blobs, -r, centre - gap * 0.5 - r, y, r * 0.9);
    chain(blobs, centre + gap * 0.5 + r, W + r, y, r * 0.9);
    const podX = centre - side * gap * 0.42 + side * W * 0.02;
    const podHints: PodHint[] = [
      { x: clampX(podX, W), y: y - 150, count: 14 + Math.round(rng.next() * 8) },
    ];
    return section(id, 'narrows', y, blobs, podHints);
  }

  /**
   * Situation 4: a chicane. Three offset gates in a row, alternating sides.
   *
   * Every other archetype asks for one committed line; this one asks for three in a
   * row with no time to let the water settle between them, which is where the
   * one-second half-life of a laid current stops being an abstraction.
   */
  private buildDrift(id: number, y: number, diff: number, rng: Rng): Section {
    const W = this.width;
    const gap = W * (0.42 - 0.13 * diff);
    const r = Math.max(13, W * 0.038);
    const blobs: Blob[] = [];
    let side = rng.next() < 0.5 ? -1 : 1;
    let midCentre = W * 0.5;
    for (let row = 0; row < 3; row++) {
      const yy = y + (1 - row) * 196;
      // 0.62 of the full offset: a chicane, not three full-width crossings. At the
      // full swing the shoal had to cross the whole play field twice inside 400px of
      // forward travel, which is not a line the water can be laid fast enough for.
      const centre = W * 0.5 + side * (W * 0.5 - gap * 0.5 - W * 0.05) * 0.62;
      if (row === 1) midCentre = centre;
      chain(blobs, -r, centre - gap * 0.5, yy, r);
      chain(blobs, centre + gap * 0.5, W + r, yy, r);
      // A loose boulder just past the gap, so the racing line is not the straight one.
      blobs.push({
        x: clampX(centre - side * gap * 0.34, W),
        y: yy - 92,
        r: r * rng.range(1.1, 1.5),
      });
      side = -side;
    }
    const podHints: PodHint[] = [
      { x: clampX(midCentre + side * gap * 0.3, W), y: y - 268, count: 10 + rng.int(0, 5) },
    ];
    return section(id, 'drift', y, blobs, podHints);
  }

  /**
   * Situation 5: a gate with a standing vortex sitting in the gap.
   *
   * The eye of the vortex is calm and the rim is not, so the clean line is the narrow
   * one straight through the middle - and the shoal is wider than the eye. Either
   * spend water fighting the spin, or thread it and accept that the edges of your
   * shoal get thrown. The first hazard in the game made of the same stuff as the cure.
   */
  private buildVortex(id: number, y: number, diff: number, rng: Rng): Section {
    const W = this.width;
    const gap = W * (0.46 - 0.1 * diff);
    const side = rng.next() < 0.5 ? -1 : 1;
    const centre = W * 0.5 + side * W * 0.1 * rng.range(0.3, 1);
    const r = Math.max(15, W * 0.048);
    const blobs: Blob[] = [];
    chain(blobs, -r, centre - gap * 0.5, y, r);
    chain(blobs, centre + gap * 0.5, W + r, y, r);
    const spin = rng.next() < 0.5 ? -1 : 1;
    const vortexHints: VortexHint[] = [
      {
        x: centre,
        y: y - gap * 0.16,
        radius: gap * 0.72,
        strength: spin * (100 + 60 * diff),
      },
    ];
    // The pod sits on the side the spin carries you toward: reading the rotation is
    // worth something, rather than being pure tax.
    const podHints: PodHint[] = [
      { x: clampX(centre + spin * gap * 0.5, W), y: y - gap * 0.95, count: 11 + rng.int(0, 5) },
    ];
    return section(id, 'vortex', y, blobs, podHints, vortexHints);
  }

  /** Situation 6: open water, a central rock to break the shoal on, and a hunter. */
  private buildPredator(id: number, y: number, diff: number, rng: Rng): Section {
    const W = this.width;
    const R = W * (0.14 + 0.04 * diff);
    const cx = W * 0.5 + rng.signed() * W * 0.12;
    const tooth = W * 0.075;
    const blobs: Blob[] = [
      { x: cx, y, r: R },
      { x: cx + R * 0.72 * (rng.next() < 0.5 ? -1 : 1), y: y + R * 0.6, r: R * 0.5 },
      { x: -tooth * 0.25, y, r: tooth },
      { x: W + tooth * 0.25, y, r: tooth },
    ];
    const zone = zoneForSection(id);
    const count = zone.index >= 3 ? 2 : 1;
    const hunterHints: HunterHint[] = [];
    for (let i = 0; i < count; i++) {
      hunterHints.push({
        x: clampX(W * (count === 1 ? rng.range(0.3, 0.7) : i === 0 ? 0.26 : 0.74), W),
        y: y - 300 - i * 130,
        size: 15 + 5 * diff,
      });
    }
    // Bait: the pod is parked inside the hunter's patrol band on purpose.
    const podHints: PodHint[] = [
      { x: clampX(W * rng.range(0.25, 0.75), W), y: y - 430, count: 12 + rng.int(0, 6) },
    ];
    return section(id, 'predator', y, blobs, podHints, [], hunterHints);
  }

  /** First blob containing the point, or null. Slightly forgiving on radius. */
  hit(x: number, y: number, forgiveness = 0.9): Blob | null {
    for (const b of this.activeBlobs) {
      const rr = b.r * forgiveness;
      const dx = x - b.x;
      const dy = y - b.y;
      if (dx * dx + dy * dy < rr * rr) return b;
    }
    return null;
  }

  /**
   * Predictive avoidance: repel from the surface, and repel harder if the agent's
   * projected position is inside. Radial-only, so it stays predictable for the
   * player - a shoal that dodges cleverly is a shoal the player cannot read.
   */
  avoid(
    x: number,
    y: number,
    vx: number,
    vy: number,
    lookahead: number,
    margin: number,
    out: { x: number; y: number },
  ): void {
    out.x = 0;
    out.y = 0;
    const fx = x + vx * lookahead;
    const fy = y + vy * lookahead;
    for (const b of this.activeBlobs) {
      const reach = b.r + margin;
      const dx = x - b.x;
      const dy = y - b.y;
      if (Math.abs(dx) > reach + 60 || Math.abs(dy) > reach + 60) continue;
      const d = Math.hypot(dx, dy) || 0.0001;
      let w = 0;
      if (d < reach) w = 1 - (d - b.r) / margin;
      const pdx = fx - b.x;
      const pdy = fy - b.y;
      const pd = Math.hypot(pdx, pdy);
      if (pd < b.r + margin * 0.5) w = Math.max(w, 1.15 - pd / (b.r + margin * 0.5));
      if (w <= 0) continue;
      // Unit direction * weight (no 1/d term): force stays bounded and readable.
      const s = Math.min(2, w) / d;
      out.x += dx * s;
      out.y += dy * s;
    }
  }

  /** Marks sections cleared once the swarm's centroid crosses their line. */
  updateProgress(centroidY: number): Section[] {
    const cleared: Section[] = [];
    const dir = this.dir;
    for (const s of this.sections) {
      if (!s.passed && (centroidY - s.lineY) * dir > 40) {
        s.passed = true;
        cleared.push(s);
      }
    }
    return cleared;
  }
}

function clampX(x: number, width: number): number {
  return Math.min(width * 0.92, Math.max(width * 0.08, x));
}

function section(
  id: number,
  kind: SectionArchetype,
  lineY: number,
  blobs: Blob[],
  podHints: PodHint[],
  vortexHints: VortexHint[] = [],
  hunterHints: HunterHint[] = [],
  wellHints: WellHint[] = [],
  dir = -1,
  authored?: { zone: number; level: number; step: number },
): Section {
  let minY = Infinity;
  let maxY = -Infinity;
  for (const b of blobs) {
    minY = Math.min(minY, b.y - b.r);
    maxY = Math.max(maxY, b.y + b.r);
  }
  for (const v of vortexHints) {
    minY = Math.min(minY, v.y - v.radius);
    maxY = Math.max(maxY, v.y + v.radius);
  }
  // A standing well is geometry too: it is the whole of what a `node` section is,
  // so a section built only from one must still own the space it bends.
  for (const w of wellHints) {
    minY = Math.min(minY, w.y - w.radius);
    maxY = Math.max(maxY, w.y + w.radius);
  }
  // Pods deliberately do *not* widen a section's extent. `minY`/`maxY` are the
  // section's geometry, and the split-and-re-form window is measured off them:
  // letting a ring 250px up the course stretch that window turned an accidental
  // An empty section is still a place on the course: it owns the water it sits in.
  if (!Number.isFinite(minY)) {
    minY = lineY - 60;
    maxY = lineY + 60;
  }
  return {
    id,
    kind,
    zone: authored?.zone ?? zoneForSection(id).index,
    level: authored?.level ?? -1,
    step: authored?.step ?? 0,
    lineY,
    minY,
    maxY,
    // Climbing, the swarm meets the largest Y first; falling, the smallest.
    entryY: dir < 0 ? maxY : minY,
    exitY: dir < 0 ? minY : maxY,
    blobs,
    motion: null,
    envelope: [],
    passed: false,
    podHints,
    vortexHints,
    hunterHints,
    wellHints,
    reformed: false,
  };
}

/**
 * Stable 0..1 from a world position: what gives every puff its own size and sag
 * without a single random call. Same cloud, every rebuild, every replay.
 */
function puffPick(x: number, y: number): number {
  let h = Math.imul(Math.round(x) | 0, 0x27d4eb2d) ^ Math.imul(Math.round(y) | 0, 0x165667b1);
  h = Math.imul(h ^ (h >>> 13), 0x9e3779b1);
  return ((h >>> 8) & 0xffff) / 0xffff;
}

function chain(out: Blob[], x0: number, x1: number, y: number, r: number): void {
  if (x1 <= x0) return;
  const step = Math.max(4, r * 0.6);
  const n = Math.max(1, Math.ceil((x1 - x0) / step));
  for (let i = 0; i <= n; i++) {
    const x = x0 + ((x1 - x0) * i) / n;
    // Tiny vertical jitter keyed to position: organic silhouette, still deterministic.
    const wob = Math.sin(x * 0.05 + y * 0.01) * r * 0.18;
    out.push({ x, y: y + wob, r });
  }
}
