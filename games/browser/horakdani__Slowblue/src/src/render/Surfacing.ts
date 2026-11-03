import { TAU, clamp, lerp } from '../core/math';
import { speciesAt, traceFish } from './FishShapes';
import type { Film, FilmView } from './Films';
import { mix, rgba, type Rgb } from './Paint';

/**
 * Slowblue: the gift at the end of the ascent.
 *
 * Six stations, six thousand metres, and the old ending was a white sheet wiped down
 * the screen in one and nine tenths of a second followed by a results dialog. That is
 * a transition, not an arrival - and arrival is the only thing the whole campaign has
 * been promising. The shoal has been climbing toward light since the trench floor; the
 * player is owed the light.
 *
 * So this is a small film, and it is the one place in the game allowed to be
 * spectacular. It is built in four movements, each of which is a sentence the game has
 * been setting up for six levels:
 *
 *   1. `lift`   - the pressure comes off. The water pales, and the refracted net of
 *                 the surface resolves overhead for the first time in the game.
 *   2. `ascent` - the ceiling comes down to meet the shoal. Shafts converge on it,
 *                 and every bubble in the water goes the same way it is going.
 *   3. `breach` - contact. One bloom, spray thrown off the crossing point, and rings
 *                 opening outward on a plane that is suddenly horizontal.
 *   4. `sky`    - above water: sun, haze, a calm sea in perspective, glitter on the
 *                 swell, and the shoal breaking clear of it in slow arcs.
 *
 * Two rules keep it from being a cutscene bolted onto a game. It is drawn by the same
 * renderer in the same frame budget - gradients, strokes, no buffers, no filters - and
 * it is entirely deterministic: no random calls, so the ending looks the same every
 * time it is earned, and it holds on its final frame instead of ending on a cut.
 *
 * ## High contrast
 *
 * This is the only ending in the game with daylight in it, and that is exactly what
 * makes it the hardest of the seven to read: the last movement is white fish over
 * bright water under a hazy sun, and almost everything in it is light on light. So
 * the answer here is mostly **subtraction**. The sun's wide bloom and the band of
 * haze along the horizon are both full-screen washes whose entire job is to stop two
 * bright things having an edge between them - which is the thing this setting exists
 * to give back - so they come down to about a third. What goes *up* is the two edges
 * the picture is actually made of: the waterline, which is what the whole ascent has
 * been climbing toward, and the shaded underside of every leaping fish, which is all
 * that separates a white body from the water it just left.
 */

/** Movement lengths, in seconds. */
export const SURFACE_LIFT = 1.3;
export const SURFACE_ASCENT = 1.9;
export const SURFACE_BREACH = 0.55;
export const SURFACE_SKY = 3.9;
/** When the shoal actually crosses the waterline. The audio breach is cued off this. */
export const SURFACE_BREACH_AT = SURFACE_LIFT + SURFACE_ASCENT;
export const SURFACE_SKY_AT = SURFACE_BREACH_AT + SURFACE_BREACH;
export const SURFACE_TOTAL = SURFACE_SKY_AT + SURFACE_SKY;
/**
 * How long the sky is held before the next act is allowed to open over it.
 *
 * On the film's own clock, like everything else here. It used to be counted in
 * wall-clock seconds by a `setTimeout` in `main.ts`, and the two clocks are not
 * the same one: the film advances on `frameDt`, which is a fixed step plus the
 * frame's cost. The gap between them was several seconds of a held frame.
 */
export const SURFACE_TAIL = 2.6;
/**
 * Seconds the above-water world takes to fade up over the water. Short: the renderer
 * dissolves the underwater layers against this, and a long crossfade between two whole
 * worlds is a double exposure rather than a transition.
 */
const SKY_FADE = 0.6;

export type SurfacePhase = 'idle' | 'lift' | 'ascent' | 'breach' | 'sky';

/** Above water the palette is no longer the ocean's. This is the only place that is true. */
const SKY_HIGH: Rgb = [104, 182, 214];
const SKY_MID: Rgb = [170, 216, 230];
const HAZE: Rgb = [255, 234, 198];
const SUN: Rgb = [255, 250, 232];
const SEA_FAR: Rgb = [96, 172, 190];
const SEA_NEAR: Rgb = [18, 74, 98];
const FOAM: Rgb = [240, 253, 255];
/** Underwater light, used by the first two movements. Cool, and it gets paler. */
const GLOW: Rgb = [226, 252, 255];

/**
 * How high above the horizon the sun sits, as a fraction of the sky's height. Low: a
 * high sun has no reflection to speak of, and the column of light it lays across the
 * swell is the thing that makes the sea look like water rather than like a gradient.
 */
const SUN_HEIGHT = 0.24;
/** Fish clearing the surface at the end. Enough to read as a shoal, not as a fountain. */
const LEAPERS = 14;

/**
 * A ring on the water: an ellipse with the perfection taken out of it.
 *
 * `ctx.ellipse` gives a shape with two axes of symmetry and no history, which on water
 * reads as vector art. Two harmonics off the radius are enough to make the same ring
 * look like something that was disturbed by an object.
 */
function ripple(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  wobble: number,
): void {
  const steps = 30;
  ctx.beginPath();
  for (let i = 0; i <= steps; i++) {
    const a = (i / steps) * TAU;
    const k = 1 + wobble * (Math.sin(a * 3 + cx * 0.01) * 0.6 + Math.sin(a * 5 + 1.7) * 0.4);
    const x = cx + Math.cos(a) * rx * k;
    const y = cy + Math.sin(a) * ry * k;
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.closePath();
}

export class Surfacing implements Film {
  private t = -1;

  /**
   * High in the frame, because the surface has to break with a sky above it.
   * The widest band of the seven: act I's shoal can be anywhere when it arrives.
   */
  readonly anchor = [0.24, 0.8] as const;

  get active(): boolean {
    return this.t >= 0;
  }

  get phase(): SurfacePhase {
    if (this.t < 0) return 'idle';
    if (this.t < SURFACE_LIFT) return 'lift';
    if (this.t < SURFACE_BREACH_AT) return 'ascent';
    if (this.t < SURFACE_SKY_AT) return 'breach';
    return 'sky';
  }

  /** 0..1 opacity of the above-water world. Also how far the ocean has been left. */
  get sky(): number {
    if (this.t < SURFACE_SKY_AT) return 0;
    return clamp((this.t - SURFACE_SKY_AT) / SKY_FADE, 0, 1);
  }

  /**
   * How far the film has taken the frame off the live world.
   *
   * The same number as `sky`, under the name the other six know it by: above
   * water there is no water, so the ocean's layers go out exactly as fast as the
   * sky comes up. This is the one film where the two are the same fact.
   */
  get veil(): number {
    return this.sky;
  }

  /** True once there is enough sky for a title to sit over it. */
  get settled(): boolean {
    return this.sky > 0.35;
  }

  /**
   * The only ending in the campaign with a daylit sky in it, and therefore the
   * only one the closing title is printed in dark ink over. Everything else up
   * the circuit ends on space, cloud seen from above at the wrong height for a
   * heading, or the trench floor.
   */
  get daylight(): boolean {
    return this.sky > 0.35;
  }

  /** True once, on the frame the shoal breaks the surface. */
  get breached(): boolean {
    return this.t >= SURFACE_BREACH_AT;
  }

  /** True once the sky has been held long enough for act II to open over it. */
  get handedOver(): boolean {
    return this.t >= SURFACE_SKY_AT + SURFACE_TAIL;
  }

  begin(): void {
    if (this.t >= 0) return;
    this.t = 0;
  }

  reset(): void {
    this.t = -1;
  }

  /** Holds on the last frame rather than ending: the dialog arrives over a picture. */
  update(dt: number): void {
    if (this.t < 0) return;
    this.t = Math.min(SURFACE_TOTAL, this.t + dt);
  }

  draw(v: FilmView): void {
    if (this.t < 0) return;
    const ctx = v.ctx;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const lift = clamp(this.t / SURFACE_LIFT, 0, 1);
    const rise = clamp((this.t - SURFACE_LIFT) / SURFACE_ASCENT, 0, 1);
    // Ease out: the ceiling arrives fast and then takes its time about the last few
    // metres, which is what makes the contact feel met rather than hit.
    const eased = 1 - Math.pow(1 - rise, 2.2);
    const lineY = lerp(-v.h * 0.14, v.y - 8, eased);
    const sky = this.sky;

    if (sky < 1) {
      const under = 1 - sky;
      this.drawLift(v, lift, under);
      if (rise > 0) this.drawCeiling(v, lineY, eased, under);
      this.drawBubbles(v, lift, rise, under);
    }
    if (this.phase === 'breach') this.drawBreach(v, lineY);
    if (sky > 0) this.drawSky(v, sky);
    ctx.restore();
  }

  /**
   * Movement 1. The water gives up its pressure: it pales from the top down, and the
   * refracted mesh of the surface - a thing no level below this one has ever shown -
   * resolves out of nothing high on the screen.
   */
  private drawLift(v: FilmView, p: number, under: number): void {
    const ctx = v.ctx;
    const a = p * under;
    ctx.globalCompositeOperation = 'lighter';
    const wash = ctx.createLinearGradient(0, 0, 0, v.h * 0.92);
    wash.addColorStop(0, rgba(GLOW, 0.3 * a));
    wash.addColorStop(0.45, rgba(GLOW, 0.1 * a));
    wash.addColorStop(1, rgba(GLOW, 0));
    ctx.fillStyle = wash;
    ctx.fillRect(0, 0, v.w, v.h);

    if (v.quality <= 0.55) {
      ctx.globalCompositeOperation = 'source-over';
      return;
    }
    // The caustic net: two families of long, shallow sines crossing each other. Their
    // interference is what light looks like on the underside of moving water, and it
    // costs two paths.
    const t = v.time;
    const net = v.h * 0.52;
    ctx.strokeStyle = rgba(GLOW, 0.045 * a);
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    for (let i = 0; i < 7; i++) {
      const base = (i / 7) * net;
      for (let x = -10; x <= v.w + 10; x += 14) {
        const y =
          base +
          Math.sin(x * 0.021 + t * 0.5 + i * 1.3) * 12 +
          Math.sin(x * 0.008 - t * 0.31) * 16;
        if (x === -10) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
    }
    for (let i = 0; i < 5; i++) {
      const bx = ((i + 0.5) / 5) * v.w;
      for (let y = -10; y <= net + 30; y += 16) {
        const x = bx + Math.sin(y * 0.02 + t * 0.4 + i) * 18 + Math.sin(y * 0.007 - t * 0.2) * 22;
        if (y === -10) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Movement 2. The ceiling itself: a bright field above a moving waterline, with
   * shafts converging on the point the shoal is going to come through. The line is
   * three traces a few pixels apart, never one - a single stroke across the screen is
   * a UI divider, and this is a surface.
   */
  private drawCeiling(v: FilmView, lineY: number, eased: number, under: number): void {
    const ctx = v.ctx;
    const t = v.time;
    const a = under;
    ctx.globalCompositeOperation = 'lighter';

    // Snell's window: the sky is a bright circle overhead, brightest straight up.
    const window = ctx.createRadialGradient(
      v.x,
      lineY - v.h * 0.05,
      0,
      v.x,
      lineY - v.h * 0.05,
      v.w * (0.5 + eased * 0.45),
    );
    window.addColorStop(0, rgba(GLOW, (0.24 + eased * 0.3) * a));
    window.addColorStop(0.55, rgba(GLOW, (0.08 + eased * 0.12) * a));
    window.addColorStop(1, rgba(GLOW, 0));
    ctx.fillStyle = window;
    ctx.fillRect(0, 0, v.w, Math.max(1, lineY + v.h * 0.3));

    // Shafts. Filled with a horizontal gradient so they have no sides, and leaned so
    // they converge on the crossing point instead of standing like columns.
    for (let i = 0; i < 5; i++) {
      const spread = (i / 4 - 0.5) * v.w * 1.15;
      const x = v.x + spread * (1 - eased * 0.35);
      const wide = v.w * (0.1 + 0.03 * Math.sin(t * 0.2 + i));
      const peak = (0.03 + eased * 0.06) * a;
      const g = ctx.createLinearGradient(x - wide, 0, x + wide, 0);
      g.addColorStop(0, rgba(GLOW, 0));
      g.addColorStop(0.5, rgba(GLOW, peak));
      g.addColorStop(1, rgba(GLOW, 0));
      ctx.save();
      ctx.transform(1, 0, (-spread * 0.5) / Math.max(1, v.h), 1, 0, 0);
      ctx.fillStyle = g;
      ctx.fillRect(x - wide, lineY, wide * 2, v.h);
      ctx.restore();
    }

    // The waterline. Three traces, and in high contrast they are the picture: the
    // surface is the one edge six thousand metres of climbing has been aimed at.
    for (let band = 0; band < 3; band++) {
      ctx.strokeStyle = rgba(GLOW, (0.2 + eased * 0.24 - band * 0.05) * a);
      ctx.lineWidth = 1.3 + band * 1.5;
      ctx.beginPath();
      for (let x = -12; x <= v.w + 12; x += 8) {
        const y =
          lineY +
          band * 4 +
          Math.sin(x * 0.03 + t * 0.9 + band * 1.6) * (2.5 + band) +
          Math.sin(x * 0.011 - t * 0.5) * 4;
        if (x === -12) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /** Air leaving for the surface, faster and denser as the surface gets closer. */
  private drawBubbles(v: FilmView, lift: number, rise: number, under: number): void {
    if (v.quality <= 0.5) return;
    const ctx = v.ctx;
    const t = v.time;
    const count = 22;
    const speed = 0.22 + rise * 0.5;
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(GLOW, (0.1 + lift * 0.16) * under);
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let i = 0; i < count; i++) {
      // Deterministic spread around the shoal, widening with distance travelled.
      const seed = (i * 0.6180339887) % 1;
      const cycle = ((t * speed + seed + i * 0.037) % 1 + 1) % 1;
      const climb = cycle * (v.h * 0.75);
      const x = v.x + (seed - 0.5) * v.w * (0.35 + cycle * 0.5) + Math.sin(cycle * 7 + i) * 6;
      const y = v.y - climb;
      if (y < -8) continue;
      const r = (1.2 + seed * 2.6) * (1 - cycle * 0.45);
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Movement 3. Contact. Short by design: a bloom that is gone before it can dazzle,
   * spray thrown off the crossing point, and the first horizontal rings in the game.
   */
  private drawBreach(v: FilmView, lineY: number): void {
    const ctx = v.ctx;
    const p = clamp((this.t - SURFACE_BREACH_AT) / SURFACE_BREACH, 0, 1);
    const bloom = Math.pow(Math.sin(p * Math.PI), 1.6);
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = rgba(FOAM, bloom * 0.5);
    ctx.fillRect(0, 0, v.w, v.h);

    // Rings on a plane that has just become horizontal: wide, flat ellipses.
    for (let i = 0; i < 3; i++) {
      const k = clamp(p * 1.5 - i * 0.22, 0, 1);
      if (k <= 0) continue;
      ctx.strokeStyle = rgba(FOAM, (1 - k) * 0.5);
      ctx.lineWidth = 1 + (1 - k) * 3;
      ripple(ctx, v.x, lineY, 20 + k * v.w * 0.75, 6 + k * v.h * 0.13, 0.04);
      ctx.stroke();
    }

    if (v.quality > 0.5) {
      // Spray. Every drop is on its own parabola, thrown outward and up, and drawn as
      // the streak it would leave rather than as a dot.
      ctx.strokeStyle = rgba(FOAM, (1 - p) * 0.6);
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      for (let i = 0; i < 26; i++) {
        const seed = (i * 0.7548776662) % 1;
        const ang = -Math.PI * (0.15 + seed * 0.7);
        const vel = (140 + seed * 220) * (0.6 + (i % 3) * 0.2);
        const age = p * SURFACE_BREACH;
        const dx = Math.cos(ang) * vel * age;
        const dy = Math.sin(ang) * vel * age + 380 * age * age;
        const px = v.x + dx;
        const py = lineY + dy;
        const tail = 0.045;
        const bx = v.x + Math.cos(ang) * vel * (age - tail);
        const by = lineY + Math.sin(ang) * vel * (age - tail) + 380 * (age - tail) * (age - tail);
        ctx.moveTo(bx, by);
        ctx.lineTo(px, py);
      }
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Movement 4. Above water.
   *
   * This is the only frame in Slowblue with a horizon in it, and the composition is built
   * around that: haze and sun above, a sea in perspective below, and the shoal - which
   * the player has been holding together for six thousand metres - breaking clear of
   * the water in front of it.
   */
  private drawSky(v: FilmView, s: number): void {
    const ctx = v.ctx;
    const skyT = this.t - SURFACE_SKY_AT;
    const t = v.time;
    // The camera settles a little, as if the shoal were coming to rest. Small enough
    // to be felt rather than seen.
    const settle = (1 - Math.pow(1 - clamp(skyT / SURFACE_SKY, 0, 1), 3)) * 10;
    const horizon = v.h * 0.4 + settle;
    const sunX = v.x * 0.35 + v.w * 0.42;
    const sunY = horizon - (horizon + v.h * 0.1) * SUN_HEIGHT;

    // --- the air ----------------------------------------------------------
    const air = ctx.createLinearGradient(0, 0, 0, horizon);
    air.addColorStop(0, rgba(SKY_HIGH, s));
    air.addColorStop(0.62, rgba(SKY_MID, s));
    air.addColorStop(1, rgba(HAZE, s));
    ctx.fillStyle = air;
    ctx.fillRect(0, 0, v.w, horizon + 1);

    // --- the sea ----------------------------------------------------------
    // The first stop carries the haze down into the water: sea and air have to meet in
    // light, or the horizon becomes a drawn line with a white edge on it.
    const sea = ctx.createLinearGradient(0, horizon, 0, v.h);
    sea.addColorStop(0, rgba(mix(SEA_FAR, HAZE, 0.4), s));
    sea.addColorStop(0.12, rgba(SEA_FAR, s));
    sea.addColorStop(0.4, rgba([56, 132, 156], s));
    sea.addColorStop(1, rgba(SEA_NEAR, s));
    ctx.fillStyle = sea;
    ctx.fillRect(0, horizon, v.w, v.h - horizon + 1);

    ctx.globalCompositeOperation = 'lighter';
    // The sun: a disc inside a bloom inside a haze. Three fills, and the only warm
    // light source the game ever shows.
    //
    // The bloom and the horizon band below it are the two softeners in the frame,
    // and in high contrast they are most of what is wrong with it: both are wide,
    // additive and pale, so both lift the whole picture toward white and take the
    // edges out of it. Cut rather than removed - a sun with no bloom at all is a
    // sticker, which is the note on the disc below.
    const soft = 1;
    const bloom = ctx.createRadialGradient(sunX, sunY, 0, sunX, sunY, v.w * 0.7);
    bloom.addColorStop(0, rgba(SUN, 0.42 * s * soft));
    bloom.addColorStop(0.18, rgba(HAZE, 0.16 * s * soft));
    bloom.addColorStop(1, rgba(HAZE, 0));
    ctx.fillStyle = bloom;
    ctx.fillRect(0, 0, v.w, v.h);
    // The disc itself has no edge: a hard circle in a hazy sky reads as a sticker.
    const disc = v.w * 0.05;
    const core = ctx.createRadialGradient(sunX, sunY, 0, sunX, sunY, disc);
    core.addColorStop(0, rgba(SUN, 0.95 * s));
    core.addColorStop(0.62, rgba(SUN, 0.7 * s));
    core.addColorStop(1, rgba(SUN, 0));
    ctx.fillStyle = core;
    ctx.fillRect(sunX - disc, sunY - disc, disc * 2, disc * 2);

    // Haze along the horizon, so the sea and the air meet in light rather than on a
    // drawn line. The line itself is never stroked.
    const band = ctx.createLinearGradient(0, horizon - v.h * 0.06, 0, horizon + v.h * 0.05);
    band.addColorStop(0, rgba(HAZE, 0));
    band.addColorStop(0.5, rgba(HAZE, 0.16 * s * soft));
    band.addColorStop(1, rgba(HAZE, 0));
    ctx.fillStyle = band;
    ctx.fillRect(0, horizon - v.h * 0.06, v.w, v.h * 0.11);

    // --- the swell, in perspective ----------------------------------------
    // Rows crowd together toward the horizon, so a flat plane of strokes reads as a
    // sea going away from you. The glitter is the same rows, brightened where the
    // sun's reflection would land.
    const rows = v.quality > 0.6 ? 26 : 14;
    const depth = v.h - horizon;
    ctx.lineWidth = 1.1;
    for (let i = 1; i <= rows; i++) {
      const k = i / rows;
      const y = horizon + Math.pow(k, 2.1) * depth;
      const amp = 1 + k * 5;
      const fade = 0.05 + k * 0.1;
      ctx.strokeStyle = rgba(FOAM, fade * s);
      ctx.beginPath();
      for (let x = -10; x <= v.w + 10; x += 18) {
        const wy = y + Math.sin(x * (0.02 - k * 0.008) + t * 0.4 + i) * amp;
        if (x === -10) ctx.moveTo(x, wy);
        else ctx.lineTo(x, wy);
      }
      ctx.stroke();

      // Glitter: three dashes per row inside the sun's column, spreading as the sea
      // gets nearer. This is the detail that makes the water look like it is moving.
      const spread = v.w * (0.03 + k * 0.28);
      ctx.strokeStyle = rgba(SUN, (0.12 + k * 0.3) * s);
      ctx.lineWidth = 1 + k * 1.6;
      ctx.beginPath();
      for (let g = 0; g < 3; g++) {
        const seed = ((i * 7 + g * 13) % 17) / 17;
        const gx = sunX + (seed - 0.5) * 2 * spread + Math.sin(t * 0.9 + i + g) * 3;
        const len = 3 + k * 9;
        const gy = y + Math.sin(gx * 0.02 + t * 0.4 + i) * amp;
        ctx.moveTo(gx - len * 0.5, gy);
        ctx.lineTo(gx + len * 0.5, gy);
      }
      ctx.stroke();
    }

    // --- rings left by the breach -----------------------------------------
    const restX = v.x;
    const restY = horizon + depth * 0.34;
    for (let i = 0; i < 3; i++) {
      const age = clamp((skyT + 0.35 - i * 0.5) / 3.4, 0, 1);
      if (age <= 0) continue;
      ctx.strokeStyle = rgba(FOAM, (1 - age) * 0.24 * s);
      ctx.lineWidth = 1 + (1 - age) * 1.6;
      ripple(ctx, restX, restY, 30 + age * v.w * 0.55, 8 + age * depth * 0.2, 0.05);
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';

    if (v.quality > 0.5) this.drawLeapers(v, skyT, s, restX, restY, depth);
  }

  /**
   * The shoal clearing the water.
   *
   * Seven fish on staggered parabolas, each one a spindle drawn along its own
   * velocity, with a ring where it went up and a ring where it comes down. It is the
   * last thing the game shows the player and the only image in it of a fish that is
   * not being carried by water - which is the point of the whole ascent.
   */
  private drawLeapers(
    v: FilmView,
    skyT: number,
    s: number,
    x0: number,
    y0: number,
    depth: number,
  ): void {
    const ctx = v.ctx;
    for (let i = 0; i < LEAPERS; i++) {
      const seed = (i * 0.6180339887) % 1;
      // Staggered, not simultaneous: a shoal comes out of the water in ones and twos,
      // and the whole set has to have arced and gone before the sequence holds.
      const start = 0.12 + i * 0.16 + seed * 0.22;
      const span = 1.1 + seed * 0.5;
      const u = (skyT - start) / span;
      if (u <= 0 || u >= 1) continue;
      // Lanes are dealt in a stride coprime with the count, so the fish that are in the
      // air at the same moment are spread across the water instead of queueing up in
      // one column - which is exactly what consecutive lanes produced.
      const lane = (((i * 5) % LEAPERS) - (LEAPERS - 1) / 2) / LEAPERS;
      const dir = lane >= 0 ? 1 : -1;
      const reach = v.w * (0.12 + seed * 0.2) * dir;
      const height = depth * (0.2 + seed * 0.14);
      const base = y0 + lane * depth * 0.28;
      const x = x0 + lane * v.w * 0.62 + reach * u;
      const y = base - Math.sin(u * Math.PI) * height;
      // Velocity of the parabola, for the body's angle. Analytic, so the fish always
      // points exactly where it is going, including at the top of the arc.
      const vx = reach;
      const vy = -Math.cos(u * Math.PI) * Math.PI * height;
      const speed = Math.hypot(vx, vy) || 1;
      const dx = vx / speed;
      const dy = vy / speed;
      const fade = Math.sin(u * Math.PI);
      // The same outline the shoal is drawn with, at four times the size. Anything
      // hand-rolled here reads as a paper dart, and this is the one moment in the game
      // where a single fish is big enough on screen to be recognised as one.
      const sp = speciesAt(i % 2 === 0 ? 0 : 3);
      const len = (13 + seed * 9) * sp.len;
      const wid = (3.4 + seed * 1.8) * sp.wid;
      // Tail beat scaled to the arc: it kicks hardest as it leaves the water.
      const beat = skyT * 9 + i * 1.7;
      ctx.beginPath();
      traceFish(ctx, x, y, dx, dy, len, wid, sp, beat, true);
      ctx.fillStyle = rgba(FOAM, (0.55 + fade * 0.4) * s);
      ctx.fill();
      // A shaded underside, so a white fish on bright water still has a body - and
      // in high contrast it is the only thing separating the two, because they are
      // both nearly white. This is the same move `Renderer.contrast` makes for the
      // live shoal: push away from the background rather than toward the light,
      // and here the background is above the fish's own value, so the answer is
      // down. An outline, not a recolour: the fish stays the colour it is.
      ctx.strokeStyle = rgba(SEA_NEAR, 0.35 * s);
      ctx.lineWidth = 1;
      ctx.stroke();

      // The ring it left on the way out, opening on the plane it is going to land on.
      ctx.globalCompositeOperation = 'lighter';
      ctx.strokeStyle = rgba(FOAM, (1 - u) * 0.34 * s);
      ctx.lineWidth = 1.3;
      ctx.beginPath();
      ctx.ellipse(x0 + lane * v.w * 0.62, base, 7 + u * 30, 2 + u * 8, 0, 0, TAU);
      ctx.stroke();
      ctx.globalCompositeOperation = 'source-over';
    }
  }
}
