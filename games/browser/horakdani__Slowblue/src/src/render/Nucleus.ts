import { TAU, clamp, lerp } from '../core/math';
import { filmHash, filmRamp, type Film, type FilmView } from './Films';
import { mix, rgba, type Rgb } from './Paint';

/**
 * Slowblue: the gold comes back out of the fire.
 *
 * Act V ends where §9 says it does: *the glowing dust cools and becomes a
 * condensation nucleus* - which is what every noctilucent cloud on the planet is
 * actually built on, and is why act III's fifth station foreshadowed this one.
 * The handover is a change of state rather than a change of place, and the film
 * is built to be watched as one.
 *
 * The move the whole thing turns on is small and it is not a loss. For five
 * minutes the swarm has been the brightest thing in the game - white-hot, at
 * eight kilometres a second, with a plasma trail on every grain. When that goes
 * out, what is left glowing inside each one is **the gold**, and it was in there
 * the whole time. The heat was hiding it. §3 says the golden life-spark is the
 * campaign's one visual constant; this is the only act that could have made a
 * liar of that, and instead it is the act that proves it.
 *
 * Four movements, on the film's own clock, deterministic, no random calls:
 *
 *   1. `slow`  - the air arrives. Every trail retracts: the streak behind a grain
 *                is the distance it covered in the last tenth of a second, so a
 *                thing decelerating from a meteor's speed to a dust grain's draws
 *                its own braking without being told to. By the end of the movement
 *                nothing in the frame is moving faster than it falls.
 *   2. `cool`  - the light goes out, in the order light actually leaves a hot
 *                body: white, then orange, then ember, then nothing. As the shell
 *                dims the core stops being outshone, and the gold is simply there.
 *   3. `seed`  - vapour finds them. A droplet grows out from each cooled grain - a
 *                ring first, then a body with the gold sitting *inside* it - and
 *                the last of the ember is quenched in the water that grew over it.
 *                Halfway through, light reaches the lowest drop from below and
 *                climbs the frame: the deck is a light before it is a shape.
 *   4. `cloud` - the droplets **meet**. They pair off with their nearest neighbour,
 *                converge, and coalesce; thirty-two drops become sixteen and
 *                sixteen become eight, each survivor carrying the volume of what
 *                it absorbed. The deck takes them in from the bottom up, and the
 *                sun crosses it from the left - the first light from above since
 *                the Karman line. Act VI opens on the frame the last pair merges.
 *
 * ## What merges, and what does not
 *
 * The water merges. The gold does not, and that is the whole reason the last
 * movement is a merge rather than a drift: two drops that coalesce end up as one
 * drop with **two nuclei in it**, which is literally true of a cloud droplet and
 * is this film's one sentence said a second time, in the last place it could be.
 * So the count of bodies of water halves twice and the count of gold never
 * changes at all: thirty-two motes come out of the fire and thirty-two motes are
 * still in the frame when act VI opens - some of them in water, some of them
 * already resting on the cloud. Each one keeps its own size, its own colour and
 * its own alpha; what changes is only how many shells there are for them to be
 * inside, and by the end there are eight.
 *
 * Thirty-two, and the count is the one number in the film that is not free: a
 * merge tree is the only structure here that cares what it is, and a power of two
 * halves cleanly twice and leaves nobody standing at the end of a round with no
 * one left to meet.
 *
 * ## Reduced motion
 *
 * Nothing is dropped. The frame never moves and the fastest element in it is a
 * grain slowing down, so `still` takes out the vapour's shimmer and the deck's
 * slow roll and keeps every movement - including the meetings, which are the
 * subject and not the texture. A film about deceleration cannot be made calmer by
 * removing the deceleration.
 *
 * What `still` must **not** take is the breath. The last frame is held, and a held
 * frame is the one picture in the game that breathes; a reduced-motion player was
 * getting a completely dead one, because the only thing moving in it was the
 * deck's roll and the roll is vestibular. So the breath drives two things that
 * have nothing to do with the vestibular system - the deck's crest rises and
 * settles by about a percent of the frame, and every drop swells by two and a
 * half - and neither is switched off by `still`. Both are exactly neutral at
 * `breath = 0.5`, so a frame drawn without a breath is the frame this file
 * composes.
 *
 * ## High contrast
 *
 * This is the brightest picture in the game, and the thing that has to be read in
 * it is a gold dot two pixels across sitting on a sunlit cloud top. That is the
 * same collision that produced the white-gold bug below, arriving a second time
 * through a setting rather than through a blend mode - and it has the same
 * constraint on its answer: §3 makes the gold the campaign's one visual constant,
 * so it may be outlined but it may never be recoloured, dimmed or moved.
 *
 * So the deck loses the sunlight along its crest and gains it in its shadowed
 * flank - the range of the background widens downward, away from the gold rather
 * than through it - and every cooled core is given a dark rim on its own edge, on
 * the same ramp the fire goes out on. An outline is the only tool that raises a
 * small bright object's contrast without changing what colour it is, which is
 * exactly the property this frame needs.
 *
 * The rest of the setting is the usual division. The one full-screen wash in the
 * film - the sun lying across the crest zone - is a softener and comes down to a
 * third. What goes *up* is the two edges the last movement is actually made of:
 * the drawn crest line, which is where the sun meets the cloud, and the caustic
 * inside each drop, which is where the light comes out the far side of it. Both
 * are strokes and points rather than fields, so raising them costs the frame no
 * brightness anywhere the gold has to be read.
 */

/** Movement lengths, in seconds. */
export const NUCLEUS_SLOW = 2.6;
export const NUCLEUS_COOL = 3.8;
export const NUCLEUS_SEED = 3.6;
export const NUCLEUS_CLOUD = 5.6;

/** The frame the swarm stops being a meteor. */
export const NUCLEUS_COOL_AT = NUCLEUS_SLOW;
/** The frame the gold is visible again. The audio's turn belongs here. */
export const NUCLEUS_SEED_AT = NUCLEUS_COOL_AT + NUCLEUS_COOL;
export const NUCLEUS_CLOUD_AT = NUCLEUS_SEED_AT + NUCLEUS_SEED;
export const NUCLEUS_TOTAL = NUCLEUS_CLOUD_AT + NUCLEUS_CLOUD;
/**
 * Film seconds the cloud is held before act VI opens into it.
 *
 * Placed on the frame the last pair of drops finishes merging, which is a little
 * over half way through the movement - the same fraction of it the handover has
 * always sat at. What is still moving after that is the deck finishing its rise
 * and the sun finishing its crossing, so act VI opens into a frame that is
 * settling rather than one that is waiting.
 */
export const NUCLEUS_TAIL = 3.0;

export type NucleusPhase = 'idle' | 'slow' | 'cool' | 'seed' | 'cloud';

/** Meteor dust, as act V's last band draws it: the orange going out of it. */
const EMBER_SKY: Rgb = [20, 12, 24];
const EMBER_LOW: Rgb = [107, 74, 82];
/** The nucleus band, as act VI's first frame draws it: cold, wet and grey. */
const COLD_SKY: Rgb = [58, 70, 82];
const DECK: Rgb = [154, 168, 180];
/** The temperatures a cooling grain passes through, in order. */
const HOT: Rgb = [255, 250, 236];
const FIRE: Rgb = [255, 152, 72];
const ASH: Rgb = [104, 110, 120];
/** Water, once there is any: pale, cool, and refracting rather than glowing. */
const DROP: Rgb = [214, 232, 246];
/** Pod-gold. It was inside the fire the whole time. */
const MOTE: Rgb = [255, 233, 178];
/** The first daylight since the Karman line, on the top of the deck. */
const SUN: Rgb = [255, 248, 226];

/** Grains in the swarm. A power of two, because the last movement halves it twice. */
const GRAINS = 32;

/**
 * The fall, as three numbers.
 *
 * `ENTRY` is what act V was flown at, `TERMINAL` is what a dust grain does in
 * still air, and `BRAKE` is how long the air takes to make the second true of
 * something that was doing the first. Position is the integral of that decay, so
 * the braking is one curve rather than a sequence of states, and the streak drawn
 * behind each grain is its own derivative.
 */
const ENTRY = 340;
const TERMINAL = 9;
const BRAKE = 0.7;

/** How far a grain has fallen at time `t`, in px. */
function fallen(t: number): number {
  return TERMINAL * t + (ENTRY - TERMINAL) * BRAKE * (1 - Math.exp(-t / BRAKE));
}

/** How fast it is falling at time `t`, in px/s. */
function falling(t: number): number {
  return TERMINAL + (ENTRY - TERMINAL) * Math.exp(-t / BRAKE);
}

/*
 * ---------------------------------------------------------------------------
 * The swarm, and who meets whom.
 * ---------------------------------------------------------------------------
 *
 * Every grain is placed by a hash of its own index, exactly as the other six
 * films place theirs, and everything below is arithmetic on those placements.
 * It is worked out once, when the module loads, because *which drop meets which*
 * is a fact about this swarm rather than about this frame: recomputing it per
 * frame would be the same answer at sixty times the price, and storing it as
 * state the film mutates would be the one thing the film contract forbids. What
 * `draw` reads is a constant, and every body's position stays a pure function of
 * the clock.
 */

/** Where the swarm is spread, as fractions of the frame: across, and down. */
const SPREAD_X = 0.62;
const SPREAD_Y = 0.34;

/**
 * The metric the pairing is worked out in.
 *
 * Both axes measured as fractions of the frame's **width**, because in a frame
 * held upright the swarm's vertical spread comes out at a bit under three
 * quarters of its horizontal one. Nothing hangs on the exact figure - the only
 * job this distance has is to make neighbours neighbours, so that a pair of drops
 * drifts into contact instead of crossing the screen to find each other.
 */
const NEAR_Y = 0.74;

/** Each grain's radius, and its volume, which is the thing that is conserved. */
const SIZE: number[] = [];
const VOL: number[] = [];
/** Where it starts, in the film's own units: -0.5..0.5 across, 0..1 down. */
const ACROSS: number[] = [];
const DOWN: number[] = [];
for (let i = 0; i < GRAINS; i++) {
  const r = 1.5 + filmHash(i * 23) * 1.9;
  SIZE.push(r);
  VOL.push(r * r * r);
  ACROSS.push(filmHash(i * 37 + 5) - 0.5);
  DOWN.push(filmHash(i * 53 + 11));
}

/** One round of coalescence: who each body meets, who survives it, and where. */
interface Meeting {
  /** The body this one meets, or -1 if it is not in this round. */
  mate: number[];
  /** True for the drop that comes out of the meeting. */
  keeps: boolean[];
  /** The meeting point, in the units the grains are placed in. Shared by the pair. */
  x: number[];
  y: number[];
}

/**
 * Pairs a set of drops off, closest two first.
 *
 * Closest-pair-first rather than lowest-index-first, and the difference is
 * visible: taking them in index order leaves the last two stragglers on opposite
 * sides of the frame with nobody nearer, and a drop crossing the whole screen to
 * meet another one is not condensation, it is a magnet. Thirty-two bodies, sixteen
 * passes, once at load.
 *
 * The bigger drop is the one that survives - it has the most of itself to keep -
 * and the meeting point is the pair's centre of *volume*, so the big one holds
 * most of its ground and the small one does most of the travelling. That is both
 * what momentum does and what reads: the eye follows the thing that moved.
 */
function meetUp(members: number[], x: number[], y: number[], vol: number[]): Meeting {
  const mate = new Array<number>(GRAINS).fill(-1);
  const keeps = new Array<boolean>(GRAINS).fill(false);
  const mx = x.slice();
  const my = y.slice();
  const left = members.slice();
  while (left.length > 1) {
    let ia = 0;
    let ib = 1;
    let best = Infinity;
    for (let a = 0; a < left.length; a++) {
      for (let b = a + 1; b < left.length; b++) {
        const dx = (x[left[a]] - x[left[b]]) * SPREAD_X;
        const dy = (y[left[a]] - y[left[b]]) * NEAR_Y;
        const d = dx * dx + dy * dy;
        if (d < best) {
          best = d;
          ia = a;
          ib = b;
        }
      }
    }
    const p = left[ia];
    const q = left[ib];
    const big = vol[p] >= vol[q] ? p : q;
    const small = big === p ? q : p;
    mate[p] = q;
    mate[q] = p;
    keeps[big] = true;
    const w = vol[big] / (vol[big] + vol[small]);
    const cx = x[small] + (x[big] - x[small]) * w;
    const cy = y[small] + (y[big] - y[small]) * w;
    mx[p] = cx;
    mx[q] = cx;
    my[p] = cy;
    my[q] = cy;
    // `ib` is always the higher index of the two, so it comes out first.
    left.splice(ib, 1);
    left.splice(ia, 1);
  }
  return { mate, keeps, x: mx, y: my };
}

const FIRST = meetUp(
  Array.from({ length: GRAINS }, (_, i) => i),
  ACROSS,
  DOWN,
  VOL,
);
/** The drop each grain's water is in after the first round. */
const HOST1 = FIRST.keeps.map((k, i) => (k ? i : FIRST.mate[i]));
const ROUND2: number[] = [];
const VOL1: number[] = [];
for (let i = 0; i < GRAINS; i++) {
  VOL1.push(FIRST.keeps[i] ? VOL[i] + VOL[FIRST.mate[i]] : 0);
  if (FIRST.keeps[i]) ROUND2.push(i);
}
const SECOND = meetUp(ROUND2, FIRST.x, FIRST.y, VOL1);

const MATE = FIRST.mate;
const KEEP = FIRST.keeps;
const MATE2 = SECOND.mate;
const KEEP2 = SECOND.keeps;
const MEET1X = FIRST.x;
const MEET1Y = FIRST.y;
/** Where each grain's water ends up, which is its round-one drop's meeting point. */
const MEET2X = HOST1.map((h) => SECOND.x[h]);
const MEET2Y = HOST1.map((h) => SECOND.y[h]);
/** The one drop each grain's *gold* is inside when the film is over. */
const HOST = HOST1.map((h) => (SECOND.keeps[h] || SECOND.mate[h] < 0 ? h : SECOND.mate[h]));

/**
 * Where each mote sits inside whatever drop it ends up in.
 *
 * A pair's two nuclei are seated on opposite sides of the drop they made - which
 * is why the angle is drawn from the pair rather than from the body - so a merge
 * never ends with one mote hidden behind another. The second round then brings
 * two such axes into one drop at unrelated angles, and four lights in one shell
 * is what a coalesced droplet looks like from close enough to count them.
 */
const SEAT_A: number[] = [];
const SEAT_R: number[] = [];
for (let i = 0; i < GRAINS; i++) {
  const pair = MATE[i] >= 0 ? Math.min(i, MATE[i]) : i;
  SEAT_A.push(
    filmHash(pair * 71 + 13) * TAU + (KEEP[i] ? 0 : Math.PI) + (filmHash(i * 103 + 9) - 0.5) * 0.6,
  );
  SEAT_R.push(0.3 + filmHash(i * 97 + 3) * 0.16);
}

/**
 * How big body `j`'s drop is, given how far the two meetings have gone.
 *
 * Volume is what is carried across, not radius: two equal drops make one of
 * about one and a quarter times the width, not two, and the difference between
 * those two numbers is the difference between coalescence and inflation. The
 * absorbed body's volume drains at the same rate the survivor's fills, so the
 * water in the frame is constant through both rounds and the drop that is being
 * taken in holds its shape until the last moment and then goes.
 */
function dropRadius(j: number, fuse1: number, fuse2: number): number {
  let vol = VOL[j];
  const m1 = MATE[j];
  if (m1 >= 0) vol = KEEP[j] ? vol + VOL[m1] * fuse1 : vol * (1 - fuse1);
  if (KEEP[j]) {
    const m2 = MATE2[j];
    if (m2 >= 0) {
      const partner = VOL[m2] + VOL[MATE[m2]] * fuse1;
      vol = KEEP2[j] ? vol + partner * fuse2 : vol * (1 - fuse2);
    }
  }
  return Math.cbrt(vol);
}

/**
 * Everything about this frame that every body reads. Worked out once per frame,
 * so the two passes over the swarm cannot disagree about what time it is.
 */
interface Beat {
  /** How far the swarm has fallen, px. */
  fall: number;
  /** 0..1 through the fire going out, the water arriving, and the light from below. */
  cool: number;
  wet: number;
  rising: number;
  /** The two meetings: how far each pair has closed, and how far it has merged. */
  close1: number;
  fuse1: number;
  close2: number;
  fuse2: number;
  /** How far the deck has risen, and how far the sun has crossed it. */
  deck: number;
  dawn: number;
  /** The deck's slow roll, which is the one thing `still` takes out of it. */
  roll: number;
  /** The held frame's breath, as a multiplier on every drop. Neutral at 0.5. */
  swell: number;
}

/** Where one body is this frame, how big its drop is, and how far the deck has it. */
interface Placed {
  x: number;
  y: number;
  /** The drop's radius in grain units. Zero once it has been absorbed. */
  rad: number;
  /** 0..1 how far the deck has taken it in: 1 is water that is now cloud. */
  recv: number;
  /** The crest under it, which is the line it is being taken in at. */
  crest: number;
}

export class Nucleus implements Film {
  private t = -1;

  readonly anchor = [0.28, 0.5] as const;

  get active(): boolean {
    return this.t >= 0;
  }

  get phase(): NucleusPhase {
    if (this.t < 0) return 'idle';
    if (this.t < NUCLEUS_COOL_AT) return 'slow';
    if (this.t < NUCLEUS_SEED_AT) return 'cool';
    if (this.t < NUCLEUS_CLOUD_AT) return 'seed';
    return 'cloud';
  }

  /**
   * 0..1 how far the frame has left act V behind.
   *
   * Slower than the space films' and deliberately so: this ending begins *inside*
   * the world it is replacing - the same grains, still falling at the same speed -
   * and a hard cut on the first frame would throw away the one continuity the
   * handover is made of.
   */
  get veil(): number {
    if (this.t < 0) return 0;
    return clamp(filmRamp(this.t, 0, NUCLEUS_SLOW * 1.15) * 0.93, 0, 0.93);
  }

  /** True once the fire is out and the gold is showing. */
  get cooled(): boolean {
    return this.t >= NUCLEUS_SEED_AT;
  }

  get settled(): boolean {
    return this.t >= NUCLEUS_SEED_AT;
  }

  /**
   * False, and it is worth saying why, because this is the brightest picture in
   * the game. The deck's top edge never rises above about two thirds of the frame
   * and the heading sits at 0.15 - so what is actually behind the title here is
   * `COLD_SKY`, which is a dark grey-blue, and pale ink is right on it.
   */
  readonly daylight = false;

  /** True once the cloud has been held long enough for act VI to open into it. */
  get handedOver(): boolean {
    return this.t >= NUCLEUS_CLOUD_AT + NUCLEUS_TAIL;
  }

  begin(): void {
    if (this.t >= 0) return;
    this.t = 0;
  }

  reset(): void {
    this.t = -1;
  }

  /** Holds on the last frame rather than ending. */
  update(dt: number): void {
    if (this.t < 0) return;
    this.t = Math.min(NUCLEUS_TOTAL, this.t + dt);
  }

  draw(v: FilmView): void {
    if (this.t < 0) return;
    const ctx = v.ctx;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    this.drawAir(v);
    this.drawDeck(v);
    this.drawVapour(v);
    this.drawGrains(v);
    ctx.restore();
  }

  /** How far the deck has come up. Read by the deck and by the drops falling into it. */
  private deckRise(): number {
    return filmRamp(this.t, NUCLEUS_SEED_AT, NUCLEUS_SEED + NUCLEUS_CLOUD * 0.6);
  }

  /** How far the sun has crossed the deck. Zero until the last movement. */
  private daybreak(): number {
    return filmRamp(this.t, NUCLEUS_CLOUD_AT, NUCLEUS_CLOUD * 0.62);
  }

  /** The deck's slow lateral roll. */
  private roll(v: FilmView): number {
    return Math.sin(v.time * 0.11) * v.w * 0.03;
  }

  /**
   * The height of one deck band, and the half of the breath that is in the cloud.
   *
   * The deck rises and settles by a bit over a percent of the frame on the swell.
   * It is scaled by the band's own rise, so nothing breathes before there is a
   * cloud to breathe, and it is deliberately *not* gated on `still`: once reduced
   * motion has stopped the roll this is the only movement left in a held frame,
   * and reduced motion is not a reason to stop a picture being alive.
   */
  private deckBase(v: FilmView, p: number, k: number): number {
    return v.h * (1.06 - p * (0.3 + k * 0.17)) - (v.breath - 0.5) * v.h * 0.012 * p;
  }

  /** How tall the band's own relief is. The far ones are flatter. */
  private deckAmp(v: FilmView, k: number): number {
    return v.h * (0.028 + k * 0.016);
  }

  /** One band's crest at `x`: two harmonics, so a cloud top is not a sine wave. */
  private crest(
    v: FilmView,
    x: number,
    base: number,
    amp: number,
    k: number,
    i: number,
    roll: number,
  ): number {
    const u = (x + roll * (1 + k * 1.6)) / Math.max(1, v.w);
    return (
      base -
      Math.sin(u * (3.1 + k * 1.9) + i * 2.3) * amp -
      Math.sin(u * (7.7 + k * 2.1) + 1.1) * amp * 0.45
    );
  }

  /** The near crest at `x`: the line a falling drop stops being separate at. */
  private receiving(v: FilmView, x: number, p: number, roll: number): number {
    return this.crest(v, x, this.deckBase(v, p, 0), this.deckAmp(v, 0), 0, 0, roll);
  }

  /**
   * The ground of the film: ember turning to cold grey.
   *
   * One gradient, two ends, and the whole of the act's transformation is in the
   * interpolation between them - act V's last palette and act VI's first, mixed
   * on a single number. The colour arrives from the *bottom* first, because that
   * is where the water is and the direction the swarm is going.
   */
  private drawAir(v: FilmView): void {
    const ctx = v.ctx;
    const a = filmRamp(this.t, 0, NUCLEUS_SLOW * 1.1);
    if (a <= 0.01) return;
    const high = filmRamp(this.t, NUCLEUS_COOL_AT * 0.6, NUCLEUS_COOL + NUCLEUS_SEED);
    const low = filmRamp(this.t, 0, NUCLEUS_SLOW + NUCLEUS_COOL * 0.8);
    const g = ctx.createLinearGradient(0, 0, 0, v.h);
    g.addColorStop(0, rgba(mix(EMBER_SKY, COLD_SKY, high), 0.97 * a));
    g.addColorStop(0.55, rgba(mix(mix(EMBER_SKY, EMBER_LOW, 0.5), COLD_SKY, high * 0.9), 0.95 * a));
    g.addColorStop(1, rgba(mix(EMBER_LOW, DECK, low), 0.94 * a));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, v.w, v.h);
  }

  /**
   * The cloud, arriving from below, and the light that arrives across it.
   *
   * Filled bands with a drawn crest, rather than soft radial mounds. The mounds
   * were the first cut and they read as fog: three wide, low-alpha gradients over
   * a grey background make a grey background. What a cloud top actually is, seen
   * from just above it, is a *silhouette with a lit edge* - an opaque body that
   * hides what is behind it and catches the sun along its crest - so that is what
   * these are. Drawn back to front, the far ones higher, paler and flatter, which
   * is the whole of the perspective.
   *
   * The lit edge is the movement's claim and it used to be made by a single
   * additive band at nine hundredths of an alpha: the first top-down light in the
   * campaign since the Karman line, delivered as a haze you had to be told about.
   * So the sun is a **stroke** now, one along each crest, brightest at the end it
   * comes from and arriving across the deck over the movement - which is what
   * sunrise on a cloud top does and is a thing an edge can say and a wash cannot.
   * `source-over` and not `lighter`: this is the brightest background in the game
   * and additive cream on it is white, which is the same bug the gold has.
   */
  private drawDeck(v: FilmView): void {
    const ctx = v.ctx;
    const p = this.deckRise();
    if (p <= 0.01) return;
    /*
     * In high contrast the deck's own range opens *downward*.
     *
     * The crest keeps much less of the sun and the flank goes much further toward
     * the cold sky, so the cloud reads as a body with a lit top and a dark
     * underside rather than as a bright field - and the background under a gold
     * grain drops by more than the grain could ever gain. Widening the deck's range
     * upward instead would have been the obvious move and it is the wrong one: the
     * crest is already within a few values of the gold. What does go up is the
     * drawn crest line, because that is an edge rather than a field.
     */
    const roll = this.roll(v);
    const dawn = this.daybreak();
    // Two bands at low quality rather than one. The third is perspective and can
    // go; dropping to a single band leaves the movement with no depth at all.
    const layers = v.quality > 0.55 ? 3 : 2;
    for (let i = layers - 1; i >= 0; i--) {
      // 1 is the furthest deck, 0 the nearest.
      const k = i / (layers - 1);
      const base = this.deckBase(v, p, k);
      const amp = this.deckAmp(v, k);
      const tint = mix(DECK, SUN, 0.06 + k * 0.3);
      const g = ctx.createLinearGradient(0, base - amp * 2.4, 0, base + v.h * 0.45);
      // The crest, the body, and the shadowed flank underneath it.
      g.addColorStop(0, rgba(mix(tint, SUN, 0.4), 0.96 * p));
      g.addColorStop(0.14, rgba(tint, 0.94 * p));
      g.addColorStop(1, rgba(mix(DECK, COLD_SKY, 0.4 + k * 0.2), 0.92 * p));
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.moveTo(-24, v.h + 24);
      for (let x = -24; x <= v.w + 24; x += 14) {
        ctx.lineTo(x, this.crest(v, x, base, amp, k, i, roll));
      }
      ctx.lineTo(v.w + 24, v.h + 24);
      ctx.closePath();
      ctx.fill();

      // The sun on this crest. One stroke, and the light in it is a horizontal
      // gradient rather than a constant, so the sun-side of the band is lit
      // before the far side is and the terminator crosses the deck as the
      // movement runs. The far bands take less of it: they are further from the
      // light and from the viewer, and a uniformly lit deck is a painted flat.
      if (dawn > 0.005) {
        const reach = dawn * 2.3;
        const a = 0.5 * p * (1 - k * 0.35);
        const sweep = ctx.createLinearGradient(0, 0, v.w, 0);
        sweep.addColorStop(0, rgba(SUN, a * clamp(reach, 0, 1)));
        sweep.addColorStop(0.5, rgba(SUN, a * clamp(reach - 0.75, 0, 1)));
        sweep.addColorStop(1, rgba(SUN, a * clamp(reach - 1.3, 0, 1)));
        ctx.strokeStyle = sweep;
        ctx.lineWidth = 1.5 * (1 - k * 0.3);
        ctx.beginPath();
        for (let x = -24; x <= v.w + 24; x += 14) {
          const y = this.crest(v, x, base, amp, k, i, roll);
          if (x === -24) ctx.moveTo(x, y);
          else ctx.lineTo(x, y);
        }
        ctx.stroke();
      }
    }
    // ...and the air above the crest zone carrying a little of it. A softener, and
    // it is what the whole claim used to rest on; now that the crests are drawn it
    // only has to say which way is up, so it is down by a third and down again in
    // high contrast, where a full-screen wash is the thing being asked for less of.
    ctx.globalCompositeOperation = 'lighter';
    const line = this.deckBase(v, p, 1);
    const lit = ctx.createLinearGradient(0, line - v.h * 0.12, 0, line + v.h * 0.12);
    lit.addColorStop(0, rgba(SUN, 0));
    lit.addColorStop(0.5, rgba(SUN, 0.06 * p * (0.25 + dawn * 0.75)));
    lit.addColorStop(1, rgba(SUN, 0));
    ctx.fillStyle = lit;
    ctx.fillRect(0, line - v.h * 0.12, v.w, v.h * 0.24);
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The water arriving, before there is anything to see it on.
   *
   * Very faint horizontal wisps drifting up past the grains. They are the only
   * thing in the film that says *where the droplets come from*, and they have to
   * be nearly invisible: vapour you can see is already cloud. At low quality the
   * pass thins to two wisps rather than going, because "where the water came
   * from" is content and the wisp count is only texture.
   */
  private drawVapour(v: FilmView): void {
    const ctx = v.ctx;
    const p = filmRamp(this.t, NUCLEUS_COOL_AT + NUCLEUS_COOL * 0.5, NUCLEUS_COOL * 0.6);
    const gone = filmRamp(this.t, NUCLEUS_CLOUD_AT, NUCLEUS_CLOUD * 0.7);
    const a = p * (1 - gone);
    if (a <= 0.01) return;
    const wisps = v.quality > 0.5 ? 4 : 2;
    const t = v.time;
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(DROP, 0.05 * a);
    ctx.lineWidth = 9;
    ctx.beginPath();
    for (let i = 0; i < wisps; i++) {
      const seed = filmHash(i * 61 + 5);
      const y = v.h * (0.3 + seed * 0.5) - ((t * 5 + seed * 90) % 120);
      for (let x = -20; x <= v.w + 20; x += 26) {
        const wy = y + Math.sin(x * 0.012 + i * 1.9) * 7;
        if (x === -20) ctx.moveTo(x, wy);
        else ctx.lineTo(x, wy);
      }
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
  }

  /** Everything the swarm reads off the clock this frame. */
  private beat(v: FilmView): Beat {
    const t = this.t;
    return {
      fall: fallen(t),
      // Independent ramps, overlapping deliberately: a grain is still cooling
      // while the first vapour reaches it.
      cool: filmRamp(t, NUCLEUS_COOL_AT * 0.75, NUCLEUS_COOL),
      wet: filmRamp(t, NUCLEUS_SEED_AT, NUCLEUS_SEED * 0.85),
      rising: filmRamp(t, NUCLEUS_SEED_AT + NUCLEUS_SEED * 0.3, NUCLEUS_SEED * 0.85),
      // Each meeting closes first and merges second, and the merge starts before
      // the closing finishes - two drops are already one body for the last third
      // of their approach, which is the only part of coalescence that is quick.
      close1: filmRamp(t, NUCLEUS_CLOUD_AT, NUCLEUS_CLOUD * 0.25),
      fuse1: filmRamp(t, NUCLEUS_CLOUD_AT + NUCLEUS_CLOUD * 0.16, NUCLEUS_CLOUD * 0.17),
      close2: filmRamp(t, NUCLEUS_CLOUD_AT + NUCLEUS_CLOUD * 0.28, NUCLEUS_CLOUD * 0.2),
      fuse2: filmRamp(t, NUCLEUS_CLOUD_AT + NUCLEUS_CLOUD * 0.38, NUCLEUS_CLOUD * 0.16),
      deck: this.deckRise(),
      dawn: this.daybreak(),
      roll: this.roll(v),
      swell: 1 + (v.breath - 0.5) * 0.05,
    };
  }

  /**
   * Where body `i` is, how big its drop is, and how far the cloud has taken it.
   *
   * The whole of the last movement is in the two nested interpolations: a body
   * moves toward the point it meets its neighbour at, and then that point moves
   * toward the point *it* meets its neighbour at. Nothing is stored between
   * frames and nothing integrates - hand it a time and it draws the same picture,
   * which is what lets the gold pass over the swarm a second time and land in
   * exactly the same places the water did.
   *
   * The drops also sink a little as they merge, because four grains of water fall
   * faster than one does, and that is what carries them into the deck.
   */
  private place(v: FilmView, i: number, b: Beat): Placed {
    const ux = lerp(lerp(ACROSS[i], MEET1X[i], b.close1), MEET2X[i], b.close2);
    const uy = lerp(lerp(DOWN[i], MEET1Y[i], b.close1), MEET2Y[i], b.close2);
    const x = v.x + ux * v.w * SPREAD_X;
    const fell =
      v.y -
      v.h * 0.3 +
      uy * v.h * SPREAD_Y +
      b.fall +
      (b.close1 * 0.4 + b.close2 * 0.6) * v.h * 0.02;
    // The deck receiving them: below the near crest a drop stops being a separate
    // body, over about eighty pixels, and settles onto the line rather than
    // falling through it. The boundary between "grains" and "cloud" dissolves
    // from the bottom of the frame up, which is the direction the cloud came from,
    // and it is never finished - the last frame is held on a crest with some of
    // the swarm taken in and some of it still coming down onto it.
    const line = this.receiving(v, x, b.deck, b.roll);
    const recv = clamp((fell - line - v.h * 0.008) / (v.h * 0.095), 0, 1);
    return {
      x,
      y: lerp(fell, line - 1.5, recv),
      rad: dropRadius(i, b.fuse1, b.fuse2),
      recv,
      crest: line,
    };
  }

  /**
   * The grains: braking, cooling, seeding, meeting, and being taken in.
   *
   * All four movements are the same thirty-two objects with a handful of numbers
   * read off the film's clock, which is why the transformation reads as one thing
   * happening rather than as five effects taking turns.
   *
   * Two passes, and the second one exists for a single reason: **the gold is
   * drawn after all of the water, everywhere in the frame**. Drawn body by body
   * it was safe from its own shell and not from the next drop's, and once drops
   * start merging there are shells wide enough to reach a neighbour's core. A
   * pass of its own is the only arrangement in which nothing in this film can
   * ever be painted over the campaign's one visual constant.
   */
  private drawGrains(v: FilmView): void {
    const ctx = v.ctx;
    const b = this.beat(v);
    const speed = falling(this.t);
    // The shell's colour, in the order a hot body actually loses light.
    const shell = b.cool < 0.5 ? mix(HOT, FIRE, b.cool * 2) : mix(FIRE, ASH, (b.cool - 0.5) * 2);
    const shellAlpha = 1 - b.cool * 0.72;
    // The last of the fire, quenched. The halo is the grain's own heat and water
    // is what takes heat out of things, so it leaves on the ramp the droplet
    // arrives on - which also means the final movement is not carrying thirty-two
    // radial gradients that have nothing left to say.
    const ember = shellAlpha * (1 - b.wet * 0.9);
    // The trail, which is the grain's own speed and nothing else, fading out with
    // it rather than being switched off at a threshold. It is a meteor at the
    // first frame and a dust grain by the third second, and the only thing that
    // changed is the number this line reads.
    const drift = clamp((speed - 12) / 34, 0, 1);
    const trail = drift * drift * (3 - 2 * drift);

    // --- the fire, and the water ------------------------------------------
    for (let i = 0; i < GRAINS; i++) {
      const g = this.place(v, i, b);
      if (g.y < -50 || g.y > v.h + 50) continue;
      const r = SIZE[i];

      if (trail > 0.004) {
        ctx.globalCompositeOperation = 'lighter';
        ctx.strokeStyle = rgba(shell, 0.36 * shellAlpha * trail);
        ctx.lineWidth = Math.max(0.9, r * 0.7);
        ctx.beginPath();
        ctx.moveTo(g.x, g.y - speed * 0.1);
        ctx.lineTo(g.x, g.y);
        ctx.stroke();
        ctx.globalCompositeOperation = 'source-over';
      }
      /*
       * The fire, as a *halo* rather than as a body, with the core drawn in its
       * own colour in the pass after this one.
       *
       * This was the other way round once - a bright disc with the gold hidden
       * behind it - and it cost the film the only thing it exists to say. Two
       * things went wrong at once and they compound. A filled white disc simply
       * covers a smaller gold one; and drawn `lighter` over act VI's grey deck,
       * which is the brightest background in the game, gold at any alpha adds to
       * something already near white and comes out white. The frame that was
       * supposed to prove the campaign's one visual constant survives re-entry
       * was a field of white dots.
       *
       * So the heat is a glow around the grain, additive because heat is, and the
       * gold is a `source-over` fill in the middle, because a mote is an object
       * and not a light source once it has stopped burning. It is the same
       * reveal - everything in front of it goes out - drawn in the order that
       * makes it visible.
       */
      if (ember > 0.03) {
        ctx.globalCompositeOperation = 'lighter';
        const heat = ctx.createRadialGradient(g.x, g.y, 0, g.x, g.y, r * 3.4);
        heat.addColorStop(0, rgba(shell, 0.85 * ember));
        heat.addColorStop(0.34, rgba(shell, 0.4 * ember));
        heat.addColorStop(1, rgba(shell, 0));
        ctx.fillStyle = heat;
        ctx.beginPath();
        ctx.arc(g.x, g.y, r * 3.4, 0, TAU);
        ctx.fill();
        ctx.globalCompositeOperation = 'source-over';
      }

      // The droplet. A ring first - the surface arriving - then a body, and the
      // body swells and settles on the breath, because a drop is the one thing in
      // the last picture that has a volume and a held frame breathes.
      if (b.wet > 0.02 && g.rad > 0.12) {
        const rr = g.rad * (1.6 + b.wet * 2.6) * b.swell;
        const left = 1 - g.recv;
        ctx.strokeStyle = rgba(DROP, 0.3 * b.wet * left);
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.arc(g.x, g.y, rr, 0, TAU);
        ctx.stroke();
        const body = ctx.createRadialGradient(g.x - rr * 0.3, g.y - rr * 0.35, 0, g.x, g.y, rr);
        body.addColorStop(0, rgba(DROP, 0.3 * b.wet * left));
        body.addColorStop(0.7, rgba(DROP, 0.12 * b.wet * left));
        body.addColorStop(1, rgba(DROP, 0));
        ctx.fillStyle = body;
        ctx.beginPath();
        ctx.arc(g.x, g.y, rr, 0, TAU);
        ctx.fill();

        /*
         * The light on the drop, from below and then from above.
         *
         * One fill, two movements. In `seed` it comes from underneath and it is
         * the colour of the deck, because the cloud is a light source before it
         * is a shape and the lowest drop is the first to know that - the sweep
         * runs bottom to top and gets there a movement ahead of the deck itself.
         * In `cloud` the same fill walks around to the top of the drop and turns
         * to sunlight, gated on how near the crest the drop is and on how far the
         * terminator has come across the frame, so a drop takes the sun at the
         * moment the deck under it does.
         */
        const near = clamp(1 - (g.crest - g.y) / (v.h * 0.3), 0, 1);
        const across = clamp(b.dawn * 2.3 - (g.x / Math.max(1, v.w)) * 1.15, 0, 1);
        const climb = clamp((b.rising - (1 - clamp(g.y / v.h, 0, 1)) * 0.9) * 3, 0, 1);
        const glow = (climb * 0.42 * (1 - b.dawn * 0.7) + across * near * 0.5) * b.wet * left;
        if (glow > 0.03) {
          const gy = g.y + rr * (0.52 - b.dawn * 1.04);
          const tint = mix(DECK, SUN, b.dawn);
          const wash = ctx.createRadialGradient(g.x, gy, 0, g.x, gy, rr * 0.95);
          wash.addColorStop(0, rgba(tint, clamp(glow, 0, 1)));
          wash.addColorStop(1, rgba(tint, 0));
          ctx.fillStyle = wash;
          ctx.beginPath();
          ctx.arc(g.x, g.y, rr, 0, TAU);
          ctx.fill();
        }

        /*
         * The caustic, and the reason the gold is not simply a dot with a ring
         * round it.
         *
         * A droplet is a lens. Light that gets past the mote converges on the far
         * side of the shell from wherever it came in, and that focus - not the
         * mote - is the brightest point in the body of the drop. One small hard
         * disc, down and to the right of centre, opposite the highlight the body
         * gradient puts up and to the left: the two together are what say there
         * is a curved surface here and the gold is behind it.
         *
         * > The first cut moved the core itself instead, a pixel or so toward
         * > where refraction would put its image, and it was wrong for a reason
         * > worth keeping: §3 makes the gold the one thing in the campaign that
         * > never moves, and a film cannot argue that by moving it. Drawing what
         * > the water does to the light *around* the mote says the same thing and
         * > leaves the constant alone.
         */
        ctx.fillStyle = rgba(mix(DROP, MOTE, 0.5), 0.42 * b.wet * left);
        ctx.beginPath();
        ctx.arc(g.x + rr * 0.36, g.y + rr * 0.42, Math.max(0.6, rr * 0.17), 0, TAU);
        ctx.fill();
      }
    }

    // --- and the gold, last, over all of it -------------------------------
    for (let i = 0; i < GRAINS; i++) {
      const g = this.place(v, i, b);
      // Its seat inside whatever drop now holds it. The offset is a fraction of
      // *that* drop's radius and it opens as the pair closes, so a mote sits on
      // its own grain until there is a shared body to sit inside, and then takes
      // its side of it. Its own size never changes: the water merged, the light
      // did not.
      const host = dropRadius(HOST[i], b.fuse1, b.fuse2) * (1.6 + b.wet * 2.6) * b.swell;
      const off = host * SEAT_R[i] * b.close1;
      const x = g.x + Math.cos(SEAT_A[i]) * off;
      const y = g.y + Math.sin(SEAT_A[i]) * off;
      if (y < -50 || y > v.h + 50) continue;
      const core = SIZE[i] * (0.72 + b.cool * 0.18);
      ctx.beginPath();
      ctx.arc(x, y, core, 0, TAU);
      /*
       * ...and in high contrast, a dark rim on it rather than a different gold.
       *
       * Two things about how, and the first cut got both wrong. It is **stroked on
       * the core's own edge**, not filled behind it: a disc a couple of pixels
       * wider than a two-pixel body is a plate, and drawn under a grain that is
       * still glowing it punched a black hole through the middle of the heat.
       * Half of a stroke's width falls inside the fill that follows, so the rim
       * costs the gold nothing.
       *
       * And it **arrives as the fire leaves**, on `cool`, which is the same ramp
       * the shell dims on. While the grain is burning it is white-hot on a dark
       * ember sky and needs no help; it is only once it is a cold speck over a
       * sunlit cloud that the background is the problem. One number does both,
       * which is why the transformation still reads as one thing happening.
       */
      ctx.fillStyle = rgba(MOTE, 0.72 + b.cool * 0.28);
      ctx.fill();
    }
  }
}
