import { ALL_ZONES, type Palette } from '../config/zones';
import { lerp } from '../core/math';

export type Rgb = [number, number, number];

/**
 * A zone palette with every colour pre-parsed to numbers.
 *
 * Zone transitions are a continuous crossfade, so the renderer interpolates a whole
 * palette every frame. Doing that on `#rrggbb` strings would mean parsing a dozen
 * hex values 60 times a second for no reason; this is parsed once, at module load.
 */
export interface ZonePaint {
  top: Rgb;
  mid: Rgb;
  bottom: Rgb;
  shoal: Rgb;
  shoalGlow: Rgb;
  shoalGlowAlpha: number;
  pod: Rgb;
  rock: Rgb;
  rockRim: Rgb;
  tracer: Rgb;
  speck: Rgb;
  speckDensity: number;
}

export function parseHex(hex: string): Rgb {
  const h = hex.replace('#', '');
  const full =
    h.length === 3
      ? h
          .split('')
          .map((c) => c + c)
          .join('')
      : h;
  return [
    parseInt(full.slice(0, 2), 16),
    parseInt(full.slice(2, 4), 16),
    parseInt(full.slice(4, 6), 16),
  ];
}

/** Accepts `rgba(r,g,b,a)` (the glow colours) and returns the triple plus alpha. */
function parseRgba(value: string): { rgb: Rgb; alpha: number } {
  const nums = value
    .replace(/[^0-9.,-]/g, '')
    .split(',')
    .map(Number);
  return {
    rgb: [nums[0] ?? 255, nums[1] ?? 255, nums[2] ?? 255],
    alpha: nums[3] ?? 1,
  };
}

/** `pod` is stored as a bare "r,g,b" string in the zone table. */
function parseTriple(value: string): Rgb {
  const nums = value.split(',').map(Number);
  return [nums[0] ?? 255, nums[1] ?? 255, nums[2] ?? 255];
}

function toPaint(p: Palette): ZonePaint {
  const glow = parseRgba(p.shoalGlow);
  return {
    top: parseHex(p.top),
    mid: parseHex(p.mid),
    bottom: parseHex(p.bottom),
    shoal: parseHex(p.shoal),
    shoalGlow: glow.rgb,
    shoalGlowAlpha: glow.alpha,
    pod: parseTriple(p.pod),
    rock: parseHex(p.rock),
    rockRim: parseHex(p.rockRim),
    tracer: p.tracer,
    speck: parseHex(p.speck),
    speckDensity: p.speckDensity,
  };
}

export const ZONE_PAINT: ZonePaint[] = ALL_ZONES.map((z) => toPaint(z.palette));

export function paintFor(zoneIndex: number): ZonePaint {
  return ZONE_PAINT[Math.max(0, Math.min(ZONE_PAINT.length - 1, zoneIndex))]!;
}

export function clonePaint(p: ZonePaint): ZonePaint {
  return {
    top: [...p.top],
    mid: [...p.mid],
    bottom: [...p.bottom],
    shoal: [...p.shoal],
    shoalGlow: [...p.shoalGlow],
    shoalGlowAlpha: p.shoalGlowAlpha,
    pod: [...p.pod],
    rock: [...p.rock],
    rockRim: [...p.rockRim],
    tracer: [...p.tracer],
    speck: [...p.speck],
    speckDensity: p.speckDensity,
  };
}

function lerpRgbInto(out: Rgb, to: Rgb, t: number): void {
  out[0] = lerp(out[0], to[0], t);
  out[1] = lerp(out[1], to[1], t);
  out[2] = lerp(out[2], to[2], t);
}

/** Moves `current` a fraction `t` of the way toward `target`, in place. */
export function blendPaint(current: ZonePaint, target: ZonePaint, t: number): void {
  lerpRgbInto(current.top, target.top, t);
  lerpRgbInto(current.mid, target.mid, t);
  lerpRgbInto(current.bottom, target.bottom, t);
  lerpRgbInto(current.shoal, target.shoal, t);
  lerpRgbInto(current.shoalGlow, target.shoalGlow, t);
  lerpRgbInto(current.pod, target.pod, t);
  lerpRgbInto(current.rock, target.rock, t);
  lerpRgbInto(current.rockRim, target.rockRim, t);
  lerpRgbInto(current.tracer, target.tracer, t);
  lerpRgbInto(current.speck, target.speck, t);
  current.shoalGlowAlpha = lerp(current.shoalGlowAlpha, target.shoalGlowAlpha, t);
  current.speckDensity = lerp(current.speckDensity, target.speckDensity, t);
}

export function css(rgb: Rgb): string {
  return `rgb(${Math.round(rgb[0])},${Math.round(rgb[1])},${Math.round(rgb[2])})`;
}

export function rgba(rgb: Rgb, alpha: number): string {
  return `rgba(${Math.round(rgb[0])},${Math.round(rgb[1])},${Math.round(rgb[2])},${alpha.toFixed(3)})`;
}

/** Pushes a colour toward white; used by the high-contrast setting. */
export function brighten(rgb: Rgb, amount: number): Rgb {
  return [lerp(rgb[0], 255, amount), lerp(rgb[1], 255, amount), lerp(rgb[2], 255, amount)];
}

/** Blends two colours. Allocates, so keep it out of per-agent loops. */
export function mix(a: Rgb, b: Rgb, t: number): Rgb {
  return [lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t)];
}

/**
 * Nudges a colour along the cool/warm axis without changing how bright it is.
 * Used to give the shoal two subtly different tints, so a hundred identical darts
 * read as a body of individuals rather than as a stamped pattern.
 */
export function temper(rgb: Rgb, amount: number): Rgb {
  return [
    clamp255(rgb[0] + amount * 26),
    clamp255(rgb[1] + amount * 4),
    clamp255(rgb[2] - amount * 22),
  ];
}

function clamp255(v: number): number {
  return v < 0 ? 0 : v > 255 ? 255 : v;
}

/**
 * Perceived brightness, 0..255. Rec. 709 weights, because green carries most of
 * what the eye calls "light" - which is why a saturated blue sky and a pale grey
 * cloud can have the same number in a naive average and look nothing alike.
 *
 * Used to decide which way "more contrast" points: see `Renderer.contrast`, and
 * `tests/zones.test.ts`, which uses it to assert that the ascent gets darker.
 */
export function luminance([r, g, b]: Rgb): number {
  return r * 0.2126 + g * 0.7152 + b * 0.0722;
}
