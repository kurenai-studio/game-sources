import { TAU } from '../core/math';
import { isSoft, type Motif } from './Motif';
import { css, mix, rgba, type Rgb, type ZonePaint } from './Paint';
import { massShift, traceStoneMass, type StoneMass } from './Stone';

/**
 * Slowblue: the rock, as material rather than as silhouette.
 *
 * The obstacles used to be painted with two fills for the whole screen: a soft
 * shadow, then one vertical gradient stretched across every mass at once. That is
 * why they read as holes cut in the water - a shape with no light on its edge and no
 * grain in its body is not a solid, it is an absence. Nothing about the geometry has
 * changed here; what changed is that each mass is now lit, banded and dressed on its
 * own:
 *
 *   - one occlusion pass under everything, so a mass sits *in* the water,
 *   - a per-mass gradient, so the light always comes from up the course,
 *   - a rim light along the crest (`StoneMass.crest`), which is the single thing
 *     that makes stone look like stone,
 *   - sediment bands across the body, and whatever the level's material grows.
 *
 * The whole layer is still additive-free except for the two things that genuinely
 * emit - the crest highlight and the trench's mineral seam - and it is still one
 * path per element. Fill rate is the budget on a phone, and this spends it on the
 * edges, where the eye actually looks, instead of on more full-screen washes.
 */

export interface StoneView {
  ctx: CanvasRenderingContext2D;
  paint: ZonePaint;
  motif: Motif;
  cameraY: number;
  /** Screen height, for the cull. */
  h: number;
  time: number;
  /** 0.4..1. Below ~0.55 the decorative passes are dropped, never the silhouette. */
  quality: number;
}

const NEAR_BLACK: Rgb = [0, 1, 3];
/** Culling slack: a mass this far off screen can still cast its shadow inward. */
const MARGIN = 90;
/** A mass narrower than this gets no bands - a wall bead is not a cliff face. */
const STRATA_MIN_SPAN = 74;

/** Reused every frame: the visible subset, so the cull never allocates. */
const shown: StoneMass[] = [];

export function paintStone(v: StoneView, masses: readonly StoneMass[]): void {
  shown.length = 0;
  const top = v.cameraY - MARGIN;
  const bottom = v.cameraY + v.h + MARGIN;
  for (const mass of masses) {
    if (mass.maxY < top || mass.minY > bottom) continue;
    shown.push(mass);
  }
  if (shown.length === 0) return;

  const ctx = v.ctx;
  const tone = materialTones(v);
  const cloud = isSoft(v.motif.material);
  // A cloud's shadow is not an absence of light, it is sky seen through vapour: a
  // soft cool grey, sitting a little lower than a rock's would (the shade of a
  // cumulus is under it, not behind it). Near-black under a bright mass is the
  // single fastest way to make the sky read as a cave.
  if (cloud) fillAll(ctx, shown, v.cameraY, 2.2, 7, rgba(mix(v.paint.mid, NEAR_BLACK, 0.3), 0.3));
  else fillAll(ctx, shown, v.cameraY, 1.6, 3, rgba(NEAR_BLACK, 0.7 - v.motif.daylight * 0.4));

  for (const mass of shown) {
    /*
     * Slowblue: everything below draws a mass in its own home coordinates, and a
     * moving section is drawn by moving the canvas instead.
     *
     * The alternative was an x offset threaded through `traceStoneMass`, `strata`,
     * `dome`, `fractures`, `fringe` and `crestLight` - six functions, about forty
     * coordinates, and a certainty that one of them would be missed and leave a
     * rim light hanging in the water beside its rock. It also keeps the surface
     * detail *still*: `strata` and `fractures` seed themselves from
     * `mass.centreX`, which is a home coordinate now, so a walking rock keeps its
     * own banding instead of re-hashing it sixty times a second.
     */
    const dx = massShift(mass);
    if (dx !== 0) {
      ctx.save();
      ctx.translate(dx, 0);
    }
    const y0 = mass.minY - v.cameraY;
    const y1 = Math.max(y0 + 1, mass.maxY - v.cameraY);
    const body = ctx.createLinearGradient(0, y0, 0, y1);
    body.addColorStop(0, css(tone.crest));
    body.addColorStop(0.34, css(mix(tone.base, tone.crest, 0.42)));
    body.addColorStop(1, css(tone.deep));
    ctx.beginPath();
    traceStoneMass(ctx, mass, v.cameraY, 0, 0);
    ctx.fillStyle = body;
    ctx.fill();
    if (v.quality > 0.6) {
      if (cloud) {
        // Vapour has no strata, no fracture and no polished dome - what it has is
        // lobes, a shaded underside, and light coming over the top of it.
        cloudLobes(v, mass, tone);
        cloudBase(v, mass, y0, y1);
      } else {
        strata(v, mass, tone, y0, y1);
        dome(v, mass, tone, y0, y1);
        fractures(v, mass, y0, y1);
      }
    }
    if (dx !== 0) ctx.restore();
  }

  // The same save/translate as above, written out rather than wrapped in a
  // helper taking a closure: a closure per mass per frame is an allocation in the
  // render path, and this file is on the wrong side of that rule to be clever.
  if (v.quality > 0.55) {
    for (const mass of shown) {
      const dx = massShift(mass);
      if (dx !== 0) {
        ctx.save();
        ctx.translate(dx, 0);
      }
      fringe(v, mass, tone);
      if (dx !== 0) ctx.restore();
    }
  }
  for (const mass of shown) {
    const dx = massShift(mass);
    if (dx !== 0) {
      ctx.save();
      ctx.translate(dx, 0);
    }
    crestLight(v, mass, tone);
    if (dx !== 0) ctx.restore();
  }
}

interface Tones {
  crest: Rgb;
  base: Rgb;
  deep: Rgb;
  /** The rim light's own colour: the crest tone taken up toward the water's light. */
  rim: Rgb;
  /** What grows on this rock, or what glows in it. */
  growth: Rgb;
}

/**
 * Every tone is derived from the zone palette first and the level's material second,
 * so a level still says how deep it is before it says what it is made of.
 */
function materialTones(v: StoneView): Tones {
  const m = v.motif;
  // Dark, not black. The deep palettes are nearly black to begin with, so pulling the
  // rock all the way down turned every mass into a hole with a shadow under it - the
  // body has to keep enough tone for the gradient across it to be visible at all.
  // Cloud is the one mass in the game that is brighter than what surrounds it, so
  // it is the one that must not be pulled toward black: darkening a cumulus gives
  // you a hole in the sky, which is exactly what every other stone here is for.
  const cloud = isSoft(m.material);
  // `daylight` unwinds the underwater darkening: a sea stack at noon keeps its
  // own colour instead of being pulled toward the silhouette every submerged
  // rock correctly is. Water motifs carry 0 and are untouched digit-for-digit.
  const day = m.daylight;
  const base = cloud
    ? mix(v.paint.rock, m.base, 0.5)
    : mix(mix(v.paint.rock, NEAR_BLACK, 0.52 * (1 - day * 0.8)), m.base, 0.45 + day * 0.2);
  const lit = mix(v.paint.rockRim, m.crest, 0.5);
  const crest = mix(base, lit, 0.2 + m.sheen * 0.22 + day * 0.14);
  return {
    crest,
    base,
    deep: cloud ? mix(base, lit, 0.2) : mix(base, NEAR_BLACK, 0.45 * (1 - day * 0.6)),
    rim: mix(m.crest, v.paint.speck, 0.22 + m.sheen * 0.16),
    growth: mix(v.paint.speck, m.accent, m.fringe === 'vein' ? 0.9 : 0.45),
  };
}

/** One fill over every visible mass. Used for the shadow and the contrast path. */
function fillAll(
  ctx: CanvasRenderingContext2D,
  masses: readonly StoneMass[],
  cameraY: number,
  grow: number,
  offsetY: number,
  style: string,
): void {
  ctx.fillStyle = style;
  ctx.beginPath();
  for (const mass of masses) {
    if (mass.mover !== null) continue;
    traceStoneMass(ctx, mass, cameraY, grow, offsetY);
  }
  ctx.fill();
  // A mass that has walked away from its silhouette cannot join the batch: the
  // whole point of the batch is one path and one fill, and this one needs the
  // canvas moved under it. There are never more than two of these on screen.
  for (const mass of masses) {
    if (mass.mover === null) continue;
    const dx = massShift(mass);
    ctx.save();
    ctx.translate(dx, 0);
    ctx.beginPath();
    traceStoneMass(ctx, mass, cameraY, grow, offsetY);
    ctx.fill();
    ctx.restore();
  }
}

/**
 * Sediment bands across the body, clipped to the mass.
 *
 * Obsidian gets one hard bright facet instead of bands: volcanic glass fractures,
 * it does not settle in layers, and the difference between the two is most of what
 * separates the trench floor from the levels above it.
 */
function strata(v: StoneView, mass: StoneMass, tone: Tones, y0: number, y1: number): void {
  const bands = v.motif.strata;
  if (bands <= 0) return;
  const span = mass.maxX - mass.minX;
  if (span < STRATA_MIN_SPAN) return;
  const ctx = v.ctx;
  const height = y1 - y0;
  const glassy = v.motif.material === 'obsidian';

  ctx.save();
  ctx.beginPath();
  traceStoneMass(ctx, mass, v.cameraY, 0, 0);
  ctx.clip();
  ctx.lineCap = 'butt';
  for (let i = 0; i < bands; i++) {
    const k = (i + 0.75) / (bands + 0.6);
    const y = y0 + height * k;
    // Bowed, and keyed to the mass's own position, so the same rock is banded the
    // same way every time it is rebuilt behind the player.
    const bow = (7 + ((hash2(mass.centreX, mass.centreY + i * 37) * 12) | 0)) * (i % 2 ? -1 : 1);
    ctx.beginPath();
    ctx.moveTo(mass.minX - 8, y);
    ctx.quadraticCurveTo((mass.minX + mass.maxX) * 0.5, y + bow, mass.maxX + 8, y);
    if (glassy) {
      // A fracture, not a layer: one hairline, and it is the only thing obsidian gets.
      ctx.strokeStyle = rgba(tone.rim, 0.07);
      ctx.lineWidth = 1.2;
      ctx.stroke();
    } else {
      // Wide and weak. A narrow dark band across a mass is a seam and reads as two
      // rocks stacked; a wide soft one is sediment.
      ctx.strokeStyle = rgba(i % 2 === 0 ? tone.crest : NEAR_BLACK, 0.09);
      ctx.lineWidth = Math.max(5, height / (bands * 1.6));
      ctx.stroke();
    }
  }
  ctx.restore();
  ctx.lineCap = 'round';
}

/**
 * The inside of a cumulus: one union fill of its own puffs, shrunk and dropped.
 *
 * This is the only interior detail any blob mass in the game gets, and it is only
 * possible because it is a *union*. Decision 28 banned per-blob decoration for
 * good: draw anything per circle and the circles covered by their neighbours
 * still draw, so a fifty-bead wall grows vertebrae. A single path holding every
 * puff, filled once, cannot produce an internal seam - the overlaps merge before
 * a pixel is written.
 *
 * What it buys is the thing a cloud has and a rock does not. A cumulus is lit
 * from above and each cauliflower head shades the one below and behind it, so
 * pulling the same circles down and in and filling them dark leaves exactly the
 * crescent of light that sits on top of every lobe. Two fills, no clip, and the
 * mass stops being a white shape and becomes a pile of them.
 */
function cloudLobes(v: StoneView, mass: StoneMass, tone: Tones): void {
  const lobes = mass.lobes;
  if (lobes.length < 9) return;
  const ctx = v.ctx;
  const shade = mix(tone.base, mix(v.paint.mid, NEAR_BLACK, 0.35), 0.55);
  ctx.save();
  ctx.beginPath();
  traceStoneMass(ctx, mass, v.cameraY, 0, 0);
  ctx.clip();
  // The shadow side: down the course and toward the mass's own centre, which is
  // where the light is coming *from* in every other layer of this file.
  ctx.fillStyle = rgba(shade, 0.3);
  ctx.beginPath();
  for (let i = 0; i < lobes.length; i += 3) {
    const r = lobes[i + 2]! * 0.9;
    const x = lobes[i]!;
    const y = lobes[i + 1]! - v.cameraY;
    const toCentre = Math.sign(mass.centreX - x);
    ctx.moveTo(x + toCentre * r * 0.16 + r, y + r * 0.3);
    ctx.arc(x + toCentre * r * 0.16, y + r * 0.3, r, 0, TAU);
  }
  ctx.fill();
  // ...and the light on top of them, lifted the other way. Additive and weak:
  // this is the sun on vapour, not a rim on a solid.
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = rgba(tone.rim, 0.055 + v.motif.sheen * 0.05);
  ctx.beginPath();
  for (let i = 0; i < lobes.length; i += 3) {
    const r = lobes[i + 2]! * 0.62;
    const x = lobes[i]!;
    const y = lobes[i + 1]! - v.cameraY - lobes[i + 2]! * 0.26;
    ctx.moveTo(x + r, y);
    ctx.arc(x, y, r, 0, TAU);
  }
  ctx.fill();
  ctx.globalCompositeOperation = 'source-over';
  ctx.restore();
}

/**
 * The shaded underside of a cloud mass.
 *
 * One clipped linear gradient over the bottom third: cool, blue-grey, and flat -
 * the base of a cumulus is where the light stops, and it is the detail that makes
 * the difference between a cloud and a white rock. The tone comes from the zone's
 * own mid colour so a storm cloud shades darker than a fair-weather one for free.
 */
function cloudBase(v: StoneView, mass: StoneMass, y0: number, y1: number): void {
  const tall = y1 - y0;
  if (tall < 30) return;
  const ctx = v.ctx;
  const from = y1 - tall * 0.42;
  const shade = mix(v.paint.mid, NEAR_BLACK, 0.22);
  const g = ctx.createLinearGradient(0, from, 0, y1);
  g.addColorStop(0, rgba(shade, 0));
  g.addColorStop(1, rgba(shade, 0.34));
  ctx.save();
  ctx.beginPath();
  traceStoneMass(ctx, mass, v.cameraY, 0, 0);
  ctx.clip();
  ctx.fillStyle = g;
  ctx.fillRect(mass.minX - 4, from, mass.maxX - mass.minX + 8, y1 - from + 2);
  ctx.restore();
}

/**
 * Fractures in a long face.
 *
 * A wall is a chain of circles and hulls into something with one continuous edge and
 * nothing on it. These are short splits running back from the crest into the body, set
 * at deterministic points along it and never longer than half the mass is thick, so
 * they read as a rock face that has been broken rather than as a moulded surface. They
 * point along the crest's own inward normal, so they can never leave the silhouette.
 */
function fractures(v: StoneView, mass: StoneMass, y0: number, y1: number): void {
  const crest = mass.crest;
  const samples = crest.length / 4;
  if (samples < 6) return;
  const thick = Math.min(mass.maxX - mass.minX, y1 - y0);
  if (thick <= 0) return;
  const ctx = v.ctx;
  const reach = Math.min(thick * 0.5, 22);
  ctx.strokeStyle = rgba(NEAR_BLACK, 0.2);
  ctx.lineWidth = 1.2;
  ctx.beginPath();
  let drew = false;
  for (let s = 2; s < samples - 2; s += 5) {
    const i = s * 4;
    const x = crest[i]!;
    const y = crest[i + 1]! - v.cameraY;
    const seed = hash2(x, crest[i + 1]!);
    if (seed < 0.35) continue;
    const len = reach * (0.5 + seed * 0.5);
    const nx = crest[i + 2]!;
    const ny = crest[i + 3]!;
    // Inward, with a slight lean, and bent once: a straight split reads as a scratch.
    const lean = (seed - 0.5) * 0.7;
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(
      x - nx * len * 0.5 - ny * lean * len * 0.4,
      y - ny * len * 0.5 + nx * lean * len * 0.4,
      x - nx * len + ny * lean * len,
      y - ny * len - nx * lean * len,
    );
    drew = true;
  }
  if (drew) ctx.stroke();
}

/**
 * The lit face, inside the outline.
 *
 * A gradient alone gives a mass a *top* and a *bottom*; what it cannot give it is a
 * shoulder. One radial fill centred above the crest, clipped to the silhouette, is
 * enough to turn a flat plate into something with a curve on it - and because it is
 * clipped it can never spill into the water the shoal is steering through.
 */
function dome(v: StoneView, mass: StoneMass, tone: Tones, y0: number, y1: number): void {
  const wide = mass.maxX - mass.minX;
  const tall = y1 - y0;
  const span = Math.min(wide, tall);
  if (span < STRATA_MIN_SPAN * 0.6) return;
  // Compact masses only. A dome of light down the length of a wall is the sheen on a
  // plastic capsule, which is precisely what a chain of circles must not look like.
  if (span / Math.max(wide, tall) < 0.5) return;
  const ctx = v.ctx;
  const cx = (mass.minX + mass.maxX) * 0.5;
  const r = Math.max(mass.maxX - mass.minX, y1 - y0) * 0.62;
  const g = ctx.createRadialGradient(cx, y0 + r * 0.1, 0, cx, y0 + r * 0.1, r);
  g.addColorStop(0, rgba(tone.crest, 0.3 + v.motif.sheen * 0.2));
  g.addColorStop(0.55, rgba(tone.crest, 0.1));
  g.addColorStop(1, rgba(tone.crest, 0));
  ctx.save();
  ctx.beginPath();
  traceStoneMass(ctx, mass, v.cameraY, 0, 0);
  ctx.clip();
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = g;
  ctx.fillRect(cx - r, y0 - r, r * 2, r * 2.2);
  ctx.globalCompositeOperation = 'source-over';
  ctx.restore();
}

/**
 * The lit edge. Two passes: a wide dim halo that bleeds into the water, then a thin
 * bright core on the outline itself. Additive, because an edge catching light is the
 * one place in this layer where something is genuinely emitting toward the camera.
 */
function crestLight(v: StoneView, mass: StoneMass, tone: Tones): void {
  const crest = mass.crest;
  if (crest.length < 8) return;
  const ctx = v.ctx;
  const sheen = v.motif.sheen;
  const samples = crest.length / 4;
  ctx.globalCompositeOperation = 'lighter';
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  // Three chunks rather than one stroke. An edge lit evenly from end to end is piping;
  // the light belongs where the rock actually faces up, which is the middle of the arc.
  const chunk = Math.max(2, Math.ceil(samples / 3));
  // Slowblue: cloud gets the halo and not the core.
  //
  // The thin bright pass is what makes stone read as stone - a hard edge catching
  // hard light. Run it along a cumulus and you get a polished lozenge: the top of
  // a cloud has no edge to catch anything, it has a few metres of vapour that get
  // gradually brighter. So cloud is lit with the wide dim pass alone, twice as
  // wide again and lifted further off the outline, which is a glow rather than a
  // line. Found by looking at a lenticular over the squall and seeing a pebble.
  const passes =
    isSoft(v.motif.material)
      ? ([[9, 0.05, 3.4], [5, 0.05, 1.2]] as const)
      : ([[4.2, 0.075, 1.8], [1.4, 0.3, 0]] as const);
  for (const [width, alpha, lift] of passes) {
    for (let part = 0; part < 3; part++) {
      const from = part * chunk;
      const to = Math.min(samples, from + chunk + 1);
      if (to - from < 2) continue;
      ctx.strokeStyle = rgba(
        tone.rim,
        alpha * (0.55 + sheen * 0.65) * (part === 1 ? 1 : 0.45),
      );
      ctx.lineWidth = width;
      ctx.beginPath();
      for (let s = from; s < to; s++) {
        const i = s * 4;
        const x = crest[i]! + crest[i + 2]! * lift;
        const y = crest[i + 1]! - v.cameraY + crest[i + 3]! * lift;
        if (s === from) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
  }
  ctx.globalCompositeOperation = 'source-over';
}

/** Stride between growth sites, in crest samples, per material. */
const STRIDE: Record<string, number> = {
  none: 0,
  vein: 2,
  silt: 4,
  coral: 3,
  kelp: 3,
  weed: 2,
};

/**
 * Whatever the level's stone carries on its exposed edge.
 *
 * Everything here is planted on a crest sample and points along that sample's own
 * outward normal, so growth leaves the rock at the angle the rock actually faces -
 * which is why it reads as attached rather than as scribbled over the top. All of it
 * is drawn well under the contrast of the shoal and none of it reaches more than
 * about fifteen pixels into the water it borders.
 */
function fringe(v: StoneView, mass: StoneMass, tone: Tones): void {
  const kind = v.motif.fringe;
  const stride = STRIDE[kind] ?? 0;
  if (stride === 0) return;
  const crest = mass.crest;
  if (crest.length < 8) return;
  const ctx = v.ctx;
  const t = v.time;
  const step = stride * 4;

  if (kind === 'vein') {
    // A seam lit from inside the stone: dashes set *behind* the outline, so the light
    // is in the rock rather than on it. The only fringe that emits.
    const pulse = 0.62 + 0.38 * Math.sin(t * 0.7);
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(tone.growth, 0.14 * pulse);
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let i = 0; i < crest.length - step; i += step) {
      const nx = crest[i + 2]!;
      const ny = crest[i + 3]!;
      const x0 = crest[i]! - nx * 3.5;
      const y0 = crest[i + 1]! - v.cameraY - ny * 3.5;
      const j = i + step;
      const x1 = crest[j]! - crest[j + 2]! * 5;
      const y1 = crest[j + 1]! - v.cameraY - crest[j + 3]! * 5;
      ctx.moveTo(x0, y0);
      ctx.quadraticCurveTo((x0 + x1) * 0.5, (y0 + y1) * 0.5 + 3, x1, y1);
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
    return;
  }

  ctx.strokeStyle = rgba(tone.growth, kind === 'silt' ? 0.06 : 0.15);
  ctx.lineWidth = kind === 'silt' ? 1.5 : 1.1;
  ctx.beginPath();
  for (let i = 0; i < crest.length; i += step) {
    const x = crest[i]!;
    const y = crest[i + 1]! - v.cameraY;
    const nx = crest[i + 2]!;
    const ny = crest[i + 3]!;
    const seed = hash2(x, crest[i + 1]!);
    const sway = Math.sin(t * 0.42 + seed * TAU);
    switch (kind) {
      case 'kelp': {
        // Two blades per site, leaning together in the current: a plant, not a comb.
        for (let b = 0; b < 2; b++) {
          const len = 9 + seed * 7 + b * 3;
          const lean = sway * (3 + b * 2.2);
          const tipX = x + nx * len + lean;
          const tipY = y + ny * len;
          ctx.moveTo(x, y);
          ctx.quadraticCurveTo(x + nx * len * 0.5 + lean * 0.2, y + ny * len * 0.5, tipX, tipY);
        }
        break;
      }
      case 'weed': {
        // Short tufts. Sunlit stone with something just starting on it.
        for (let b = -1; b <= 1; b++) {
          const len = 3.5 + seed * 3;
          const ax = nx + b * 0.42;
          const ay = ny + b * 0.18;
          ctx.moveTo(x, y);
          ctx.lineTo(x + ax * len, y + ay * len);
        }
        break;
      }
      case 'coral': {
        // Polyps and one stubby branch, both hugging the outline.
        const r = 1.2 + seed * 1.1;
        ctx.moveTo(x + nx * 2 + r, y + ny * 2);
        ctx.arc(x + nx * 2, y + ny * 2, r, 0, TAU);
        const len = 5 + seed * 4;
        ctx.moveTo(x, y);
        ctx.lineTo(x + nx * len - ny * 1.5, y + ny * len + nx * 1.5);
        break;
      }
      case 'silt': {
        // Sediment leaving the crest downstream: the only fringe that points *back*
        // along the course, which is what makes the water look like it has been
        // moving over this rock for a long time.
        const len = 20 + seed * 14;
        ctx.moveTo(x, y);
        ctx.quadraticCurveTo(x + nx * len * 0.4 + sway * 6, y + len * 0.45, x + sway * 3, y + len);
        break;
      }
    }
  }
  ctx.stroke();
}

/** Stable 0..1 from a world position. Same rock, same growth, every time. */
function hash2(x: number, y: number): number {
  let h = Math.imul(Math.round(x * 2) | 0, 0x27d4eb2d) ^ Math.imul(Math.round(y * 2) | 0, 0x165667b1);
  h = Math.imul(h ^ (h >>> 13), 0x9e3779b1);
  return ((h >>> 8) & 0xffff) / 0xffff;
}
