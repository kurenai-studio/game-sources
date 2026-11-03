import { TAU } from '../core/math';
import type { BackdropView } from './Backdrop';
import { rgba, type Rgb } from './Paint';

/**
 * Slowblue: the four primitives every sky in the campaign is built from.
 *
 * Acts II and III are two modules - `Sky.ts` and `Upper.ts` - because they are two
 * different places, but they are one continuous climb and they have to look like
 * one. Sharing the parts is how that is guaranteed rather than hoped for: the
 * anvil at 11 km and the tropopause at 11 km are the *same altitude* seen from
 * either side of a handover, and if their cloud were lumped by two different
 * functions the seam would show at exactly the moment the campaign most needs it
 * not to.
 *
 * All four are stateless and world-anchored, which is the rule the backdrops in
 * `Backdrop.ts` already obey: scenery you move through, never a pattern laid on
 * the glass.
 */

/** Wraps a world-anchored element into the visible band at its own rate. */
export function wrapY(v: BackdropView, index: number, span: number, rate: number): number {
  const period = v.h + span * 2;
  const raw = index * span - v.cameraY * rate;
  return (((raw % period) + period) % period) - span;
}

/** Stable 0..1 from an integer. Keeps every backdrop free of stored state. */
export function hash(i: number): number {
  let h = Math.imul(i ^ 0x9e3779b9, 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 13), 0xc2b2ae35);
  return ((h >>> 8) & 0xffff) / 0xffff;
}

/**
 * A bank of cloud, drawn as one lumpy fill rather than as a stack of circles.
 *
 * The lumps are arcs on a shared path, so a whole deck is one fill however many
 * it has: the same economy the stone uses, for the same reason. `flat` squashes
 * the bank, which is the entire difference between a fair-weather cumulus and the
 * spreading sheet at the top of a storm.
 */
export function bank(
  v: BackdropView,
  cx: number,
  cy: number,
  width: number,
  colour: Rgb,
  alpha: number,
  seed: number,
  flat = 0.42,
): void {
  const ctx = v.ctx;
  ctx.fillStyle = rgba(colour, alpha * v.alpha);
  ctx.beginPath();
  const lumps = 5;
  for (let i = 0; i < lumps; i++) {
    const t = i / (lumps - 1) - 0.5;
    const h = hash(seed * 31 + i);
    // Fullest in the middle, ragged at the ends: a bank has shoulders.
    const swell = 1 - Math.abs(t) * 1.35;
    const r = width * (0.2 + 0.22 * h) * Math.max(0.24, swell);
    const x = cx + t * width;
    const y = cy - r * flat * (0.5 + h * 0.7);
    ctx.moveTo(x + r, y);
    ctx.ellipse(x, y, r, r * flat, 0, 0, TAU);
  }
  ctx.fill();
}

/**
 * A field of stars, in magnitudes.
 *
 * Shared by every station above the squall, because the sky stops being blue
 * gradually and the stars have to arrive the same way - `depth` is how black it
 * is, and a star is only drawn once the sky behind it is dark enough to have
 * shown it. That ordering is what makes the ascent read as one continuous thing
 * rather than as a stack of pictures: the same stars, and more of them each
 * station, from the top of the weather to the Karman line.
 *
 * `frozen` holds the whole field still - no drift and no twinkle. It is a fact
 * about the scene rather than about the viewer: above the Karman line there is no
 * atmosphere left to make a star scintillate, so the stations that draw vacuum
 * ask for it and the ones that draw air do not.
 */
export function stars(
  v: BackdropView,
  depth: number,
  count: number,
  seed: number,
  frozen = false,
): void {
  if (depth <= 0.02 || v.quality <= 0.5) return;
  const ctx = v.ctx;
  const t = frozen ? 0 : v.time;
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = rgba(v.paint.speck, 0.6 * depth * v.alpha);
  ctx.beginPath();
  for (let i = 0; i < count; i++) {
    const h = hash(i * 31 + seed);
    // Brightest first: at any depth the sky has shown you the brightest ones.
    const magnitude = hash(i * 47 + seed);
    if (magnitude > depth * 1.25) continue;
    const x = h * v.w;
    // Anchored to the world at a rate you can only just detect. The sky is not
    // painted on the glass; it is very, very far away.
    const y = wrapY(v, i, v.h * 0.55, 0.03);
    // Crowded toward the top: that is where the atmosphere is thinnest.
    const lift = y - v.h * 0.15 * (1 - magnitude);
    const twinkle = frozen ? 1 : 0.78 + 0.22 * Math.sin(t * (0.4 + h * 0.5) + i * 2.2);
    const r = (0.45 + (1 - magnitude) * 1.05) * twinkle;
    ctx.moveTo(x + r, lift);
    ctx.arc(x, lift, r, 0, TAU);
  }
  ctx.fill();
  ctx.globalCompositeOperation = 'source-over';
}
