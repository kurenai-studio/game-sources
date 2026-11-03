import { TAU } from '../core/math';
import type { CarrierKind } from '../config/levels';

/**
 * Slowblue: the five carriers with no body plan, and the campaign's one real secret.
 *
 * `FishShapes.ts` and `Flock.ts` each describe an *animal* - a spine with a
 * travelling wave, a wing planform sampled root to tip - because a shoal and a
 * flock are made of animals and the whole reason they read at eleven pixels is
 * that every number in those files describes something anatomical.
 *
 * Nothing after the anvil is an animal. What goes up from the top of the storm is
 * what a bird was *carrying*, and from there the campaign's cargo is spores, then
 * the gold itself, then meteor dust, then water, then plankton. None of those has
 * a front, a back, a gait or a heading, and drawing them as though they did would
 * be the loudest lie the game could tell - it would say the player is still
 * steering creatures, and the entire point of the second half is that they never
 * were.
 *
 * So this file describes the opposite thing: **five ways of being a particle**.
 * Each is a handful of numbers about how a very small thing sits in a medium, and
 * the difference between them is entirely the difference between the media.
 *
 * ## The three properties that carry it
 *
 * **Elongation.** A spore tumbles and is drawn round. A grain of meteor dust is
 * moving at eight kilometres a second and is drawn as a streak along its own
 * velocity. Everything else is somewhere between, and the axis is *how much the
 * medium is doing to it* - which is the campaign's whole subject, in one number.
 *
 * **Halo.** How much light the thing throws into the medium around it. Zero for a
 * plankter in daylight, and the largest in the game for the gold in vacuum, where
 * the swarm is not merely lit but is the only light source in the frame.
 *
 * **Facet.** Whether it is a smooth blob or a hard-edged crystal. This is the one
 * property that is not a gradient: ice has flat planes and water does not, and a
 * droplet drawn faceted looks like a bug rather than like a droplet.
 *
 * All five are drawn as a *single path per batch*, exactly as the fish and the
 * birds are, so a swarm of four hundred motes is still one fill. Nothing here
 * costs state, and none of it is readable by the simulation: two carriers with
 * identical physics look nothing alike, which is the point.
 */

export interface Carrier {
  key: string;
  /** Base radius multiplier against the shared agent size. */
  size: number;
  /**
   * How far the body is stretched along its own velocity, as a multiple of
   * `size` at full speed. 0 is a perfect circle at any speed.
   */
  stretch: number;
  /** Speed (px/s) at which `stretch` is fully applied. */
  stretchAt: number;
  /**
   * Radius of the glow thrown around each individual, as a multiple of `size`.
   * 0 draws no halo at all, which is right for anything in daylight.
   */
  halo: number;
  /** Peak alpha of that halo. */
  haloAlpha: number;
  /**
   * Number of flat facets on the outline. 0 is a smooth ellipse; 6 is a crystal.
   * Ice is the only thing in the campaign that gets this.
   */
  facets: number;
  /**
   * How much the individual's own size varies with its wander phase, 0..1. A
   * field of identical dots reads as a texture rather than as a population, and
   * this is the cheapest possible cure - the same job the fish's two-tint split
   * and the birds' desynchronised wingbeat do.
   */
  vary: number;
  /**
   * How much the thing twinkles as it turns, 0..1. Real for anything faceted or
   * wet - a crystal or a droplet catches the light through a few degrees of its
   * tumble and is dark the rest of the time - and zero for anything that emits
   * its own light, because emission does not care which way you are facing.
   */
  glint: number;
}

/**
 * The five, in campaign order. Read down the `stretch` column and you have the
 * arc of the whole second half: tumbling, then falling, then burning, then
 * falling again, then settling.
 */
const CARRIERS: Record<string, Carrier> = {
  /**
   * Act III. Spores, seeds, aerosols and ice nuclei - the first carrier with no
   * body plan at all, and the one that is most nearly *nothing*. It is round
   * because a spore has no preferred direction, small because it is, and it
   * glints because half of what is up there at 25 km is crystal.
   */
  motes: {
    key: 'motes',
    size: 0.62,
    stretch: 0.5,
    stretchAt: 220,
    halo: 2.6,
    haloAlpha: 0.1,
    facets: 5,
    vary: 0.5,
    glint: 0.55,
  },
  /**
   * Act IV. The gold itself, with nothing left around it.
   *
   * This is the carrier the whole campaign has been about, seen for the first
   * time with no carrier around it - and in vacuum it is the only light source
   * in the frame, so it has the largest halo in the game by a long way and no
   * glint at all. A thing that emits does not care which way it is facing.
   *
   * It is drawn perfectly round. Nothing up here is being deformed by anything.
   */
  lights: {
    key: 'lights',
    size: 0.72,
    stretch: 0.18,
    stretchAt: 300,
    halo: 4.4,
    haloAlpha: 0.22,
    facets: 0,
    vary: 0.34,
    glint: 0,
  },
  /**
   * Act V. The same gold, burning.
   *
   * The one carrier in the campaign that is genuinely *fast*, and the only one
   * whose silhouette is a line rather than a point: a grain of meteor dust is
   * ablating along its own velocity vector, so it is drawn as a streak that gets
   * longer the faster it is going. At rest it is a mote again, which is exactly
   * what happens to it at the bottom of act V.
   */
  dust: {
    key: 'dust',
    size: 0.66,
    // The largest in the game. This is what re-entry looks like.
    stretch: 3.4,
    stretchAt: 260,
    halo: 3.6,
    haloAlpha: 0.2,
    facets: 0,
    vary: 0.45,
    glint: 0,
  },
  /**
   * Act VI. Ice crystals, then droplets, then one joined body of water.
   *
   * Faceted, because it starts as crystal, and wet, because it ends as water -
   * so it is the only carrier with both `facets` and a high `glint`, and it is
   * the one that most obviously *catches* light rather than making it. Stretched
   * a little along its fall, because a raindrop is not a sphere.
   */
  droplets: {
    key: 'droplets',
    size: 0.78,
    stretch: 1.1,
    stretchAt: 240,
    halo: 1.8,
    haloAlpha: 0.08,
    facets: 4,
    vary: 0.4,
    // The highest in the game: rain is a field of things flashing on and off.
    glint: 0.8,
  },
  /**
   * Act VII. Plankton, larvae and marine snow, going home.
   *
   * The softest thing in the campaign and the only one that is drawn *larger*
   * than the swarm that started it: marine snow is aggregate, loose and slow.
   * The halo comes back - not because it is bright but because it is the only
   * light left down there - and the glint goes almost to nothing, because
   * nothing at four thousand metres is catching a sun.
   */
  plankton: {
    key: 'plankton',
    size: 0.92,
    stretch: 0.35,
    stretchAt: 160,
    halo: 2.2,
    haloAlpha: 0.14,
    facets: 0,
    vary: 0.62,
    glint: 0.12,
  },
};

/** Whether this act's carrier is drawn here rather than as a fish or a bird. */
export function isParticle(carrier: CarrierKind): boolean {
  return carrier in CARRIERS;
}

export function carrierFor(carrier: CarrierKind): Carrier {
  return CARRIERS[carrier] ?? CARRIERS.motes!;
}

/** Every particle carrier, for the tests and the admin surface. */
export const PARTICLE_CARRIERS: Carrier[] = Object.values(CARRIERS);

/**
 * Traces one individual into the caller's path.
 *
 * The whole batch is one `fill()`, so this must not touch `fillStyle`, must not
 * begin or close a path, and must leave nothing on the context - exactly the
 * contract `traceFish` and `traceBird` already keep.
 *
 * `vx`/`vy` are the individual's velocity, which is the only orientation any of
 * these five has: a particle has no heading of its own, it has whatever the
 * medium is doing to it. That is why nothing here is steered state the way the
 * birds' bearing is - there is nothing to steer.
 */
export function traceCarrier(
  ctx: CanvasRenderingContext2D,
  c: Carrier,
  x: number,
  y: number,
  r: number,
  vx: number,
  vy: number,
  phase: number,
  time: number,
): void {
  const speed = Math.hypot(vx, vy);
  // Size wander, so a field of these reads as a population and not a texture.
  const wobble = 1 + c.vary * 0.5 * Math.sin(time * 0.7 + phase * TAU);
  // ...and the glint: a hard, brief flash with a long dark side, which is what a
  // tumbling crystal or a falling droplet actually does.
  const flash =
    c.glint <= 0
      ? 1
      : 1 - c.glint + c.glint * Math.pow(Math.sin(time * 1.6 + phase * TAU) * 0.5 + 0.5, 3) * 2;
  const rr = Math.max(0.35, r * c.size * wobble * flash);

  // Elongation along the velocity. At rest every one of these is round, which is
  // the honest thing: a particle is only a streak because something is moving it.
  const t = speed <= 0 ? 0 : Math.min(1, speed / c.stretchAt);
  const long = rr * (1 + c.stretch * t);
  const ang = speed > 0.01 ? Math.atan2(vy, vx) : 0;

  if (c.facets <= 0) {
    ctx.moveTo(x + long, y);
    ctx.ellipse(x, y, long, rr, ang, 0, TAU);
    return;
  }
  // A crystal: flat planes rather than a curve. Rotated by its own phase so no
  // two are presenting the same face, which is most of what stops a field of
  // faceted things from looking like a tiling.
  const spin = ang + phase * TAU;
  for (let i = 0; i <= c.facets; i++) {
    const a = spin + (i / c.facets) * TAU;
    // Alternate vertices sit slightly in, so the outline has corners with real
    // angles in them instead of being a smooth polygon pretending to be ice.
    const reach = i % 2 === 0 ? 1 : 0.78;
    const px = x + Math.cos(a) * long * reach;
    const py = y + Math.sin(a) * rr * reach;
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
}
