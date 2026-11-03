import { TAU } from '../core/math';
import { BREATH_INHALE, breathFlow } from './Breath';

/**
 * Slowblue: the upper atmosphere, as the thing that is actually carrying you.
 *
 * Act III has a problem the first three media do not. A stroke barely grips up
 * here and a spore has no wings, so if the swarm's progress came from the swarm,
 * the act would be a slow version of act II with the fun taken out. It does not.
 * **Above the tropopause the air is organised**, in a way it is not lower down:
 * it separates into deep horizontal layers that move at very different speeds and
 * in opposite directions, and a thing with no engine that gets into the right one
 * is simply taken where that layer is going.
 *
 * That is the act's verb, and it is a genuinely different one without being a
 * different game: **wait, and pick a layer.** The hand still does what it has
 * always done - lay a current - but the current is now a small correction inside
 * something enormous, and the skill is choosing which enormous thing to be inside.
 *
 * ## Two fields, and why the second one is the breath
 *
 * **Bands.** A repeating stack of horizontal layers, each with its own sideways
 * wind, cycling up the course forever. They are repeating rather than authored
 * one at a time because that is what the real thing is - the atmosphere does not
 * have six named layers at authored altitudes, it has a shear profile - and
 * because it means a station is authored by saying "the winds here are these"
 * rather than by placing forty rectangles.
 *
 * **The gravity wave.** A standing vertical oscillation, and it is tied to the
 * eleven-second breath the whole game has been running on since act I.
 *
 * That is the one piece of this design that needs defending, because "the
 * mountain wave happens to have the period of a human exhale" is not a physical
 * claim and is not offered as one. It is the opposite: the breath is the only
 * clock in this game derived from the player's body rather than from the world
 * (see `sim/Breath.ts`), and act III is the act about waiting. Giving the wait a
 * period the player is *already entrained to* means the timing is learnable
 * without a single instruction, a meter or a beat marker - by the time the swarm
 * needs lifting, the player has been breathing with the picture for twenty
 * minutes. A stroke laid while the air is going up gains altitude; the same
 * stroke half a cycle later spends it. Nothing says so. It is simply true, and it
 * is discoverable in about two breaths.
 *
 * Everything here is a pure function of position and time - no state, no random
 * calls - so replays match, the sweeps can measure it, and the renderer can draw
 * the bands by sampling exactly what the simulation samples.
 */

export interface LayerSpec {
  /** Thickness of one band, in px of course. */
  height: number;
  /**
   * Sideways wind speeds (px/s), cycled up the course. Signed: negative is left.
   *
   * The list *is* the station's design. Two entries with opposite signs is a
   * choice between two directions; four with one strong entry is a river with
   * eddies either side of it.
   */
  winds: number[];
  /** Peak vertical speed of the gravity wave (px/s). 0 turns it off. */
  waveAmplitude?: number;
  /** Distance between one rising cell and the next (px). */
  waveLength?: number;
}

const DEFAULT_WAVE_LENGTH = 1100;

/**
 * How much weaker the **exhale** half of the wave is than the inhale half.
 *
 * Slowblue: this asymmetry is the mechanic, and which half it damps is the whole of
 * it. A symmetric wave integrates to zero everywhere and is texture. Damped on
 * one half of the *breath*, a cell that rises on the inhale is a cell with **net
 * lift in it**, and the cell half a wavelength away - which rises on the exhale
 * instead - has exactly as much net sink. The field sums to nothing across space,
 * which is what makes it a choice rather than a lift: there is somewhere better
 * to be, and somewhere worse, and they are the same size.
 *
 * It damps the exhale rather than the descent, and that was a real bug for as
 * long as it did the latter. "Scale down whichever way the air is currently
 * going" damps the *downward* half of every cell, so every cell in the field came
 * out net-lifting - and because the exhale is the longer half of the breath, the
 * cells the design calls sinking lifted the hardest of all. The whole field was a
 * free elevator that paid best where the player was supposed to leave. Damping a
 * half of the cycle instead makes the two families exactly equal and opposite,
 * which is what `netLiftAt` now returns and what `tests/thinning.test.ts` asserts.
 *
 * It is also the truth about the thing being modelled. A mountain wave's ascent
 * really is sharper and faster than its descent - that asymmetry is the entire
 * reason wave soaring exists, and why glider pilots climb to thirty thousand feet
 * in air that would otherwise average out to nothing - and here the sharp half is
 * the inhale, which is the shorter half of the clock the whole game runs on.
 *
 * The value comes from act III's measured forward economy rather than from taste.
 * A competent hand makes **57 px/s** up the course in thin air
 * (`tools/thin.sweep.ts`, forward ceiling), and the act's own rule is that bad
 * timing costs position and time and never life - so no cell may sink faster than
 * a player can climb. At 0.32 the deepest station's wave nets 7 px/s either way
 * over a breath and peaks at 46, comfortably inside the hand.
 */
const SINK = 0.32;

/**
 * How much of a band's edge is spent blending into its neighbour, as a fraction
 * of the band height.
 *
 * Not zero, and the reason is mechanical rather than aesthetic: a hard boundary
 * means an individual straddling it gets two different winds a pixel apart, which
 * tears a swarm in half along a line the player cannot see. A third of the band
 * spent in transition makes the boundary a *place* - somewhere with a bit of both
 * winds in it, that can be sat in deliberately while a decision is made.
 */
const EDGE = 0.34;

/** Smoothstep on 0..1. */
function ease(u: number): number {
  const x = u < 0 ? 0 : u > 1 ? 1 : u;
  return x * x * (3 - 2 * x);
}

export class LayeredFlow {
  private spec: LayerSpec | null = null;

  /**
   * Where the stack is anchored in world space. Set once per level so a station's
   * first band starts at its first section rather than at an arbitrary offset -
   * without it, the same authored winds would land differently depending on how
   * far the player had travelled to get there.
   */
  originY = 0;

  set(spec: LayerSpec | null, originY = this.originY): void {
    this.spec = spec;
    this.originY = originY;
  }

  get active(): boolean {
    return this.spec !== null && (this.spec.winds.length > 0 || (this.spec.waveAmplitude ?? 0) > 0);
  }

  get layers(): LayerSpec | null {
    return this.spec;
  }

  /**
   * Which band a world Y is in, as a continuous number: the integer part is the
   * band index and the fraction is how far through it. The renderer draws its
   * boundary lines from this, so what is on screen is exactly what is simulated.
   */
  bandAt(y: number): number {
    const s = this.spec;
    if (s === null || s.height <= 0) return 0;
    return (y - this.originY) / s.height;
  }

  /** The sideways wind at a world Y, with the boundaries blended. */
  windAt(y: number): number {
    const s = this.spec;
    if (s === null || s.winds.length === 0 || s.height <= 0) return 0;
    const n = s.winds.length;
    const band = this.bandAt(y);
    const index = Math.floor(band);
    const frac = band - index;
    const here = s.winds[((index % n) + n) % n]!;
    // Only the last `EDGE` of a band blends, and it blends into the next one up
    // the course. Everywhere else a band is exactly what it says it is.
    if (frac < 1 - EDGE) return here;
    const next = s.winds[(((index + 1) % n) + n) % n]!;
    return here + (next - here) * ease((frac - (1 - EDGE)) / EDGE);
  }

  /**
   * The gravity wave's vertical speed at a world Y and a wall-clock time.
   *
   * Negative is upward, because the campaign's climb runs toward -Y. The spatial
   * term is a cosine, so half the cells are rising while the other half sink - a
   * wave that lifted everywhere at once would be a tide, and a tide can be waited
   * out anywhere. Having to be in the *right cell* at the right moment is what
   * makes this a decision rather than a pause.
   *
   * The inhale is stronger than the exhale (`SINK`), which is what turns "the air
   * here goes up and then down again" into "the air here goes up, and the air a
   * wavelength away goes down". Without it the whole field averages out and the
   * act has nothing in it but scenery.
   */
  waveAt(y: number, time: number): number {
    const s = this.spec;
    if (s === null) return 0;
    const amp = s.waveAmplitude ?? 0;
    if (amp === 0) return 0;
    const length = s.waveLength ?? DEFAULT_WAVE_LENGTH;
    const phase = Math.cos((TAU * (y - this.originY)) / length);
    const flow = breathFlow(time);
    // Damped on the exhale, everywhere at once - never on "whichever way this
    // cell happens to be going", which lifts the whole field. See `SINK`.
    return -amp * flow * phase * (flow < 0 ? SINK : 1);
  }

  /**
   * Net vertical drift a body sitting at this altitude would accumulate over one
   * whole breath, in px/s. Negative is lift.
   *
   * The one number that says what a cell is *worth*, and the renderer's cue for
   * how to draw it: a cell with net lift gets its tracers drawn rising, and the
   * player learns to read the picture rather than a meter. Computed rather than
   * sampled so it is exact and free of phase.
   */
  netLiftAt(y: number): number {
    const s = this.spec;
    if (s === null) return 0;
    const amp = s.waveAmplitude ?? 0;
    if (amp === 0) return 0;
    const length = s.waveLength ?? DEFAULT_WAVE_LENGTH;
    const phase = Math.cos((TAU * (y - this.originY)) / length);
    // The closed form of `waveAt` integrated over one whole breath. The inhale
    // carries `rise` of area and the exhale `fall`, and damping the exhale by
    // `SINK` leaves a signed residue that the spatial cosine then decides the
    // direction of - so the two families of cell are exactly equal and opposite
    // and the field sums to nothing across a wavelength.
    const rise = BREATH_INHALE * (2 / 3);
    const fall = (1 - BREATH_INHALE) * (2 / 3);
    return amp * phase * (fall * SINK - rise);
  }

  /**
   * Adds this field into a velocity accumulator. Same shape as `AmbientFlow.addTo`
   * and `CurrentField.addTo`, so `World.water` can sum all three and nothing in
   * the swarm can tell whose air is pushing it - which is the whole point.
   */
  addTo(
    _x: number,
    y: number,
    time: number,
    strength: number,
    out: { x: number; y: number },
  ): void {
    if (this.spec === null || strength === 0) return;
    out.x += this.windAt(y) * strength;
    out.y += this.waveAt(y, time) * strength;
  }
}
