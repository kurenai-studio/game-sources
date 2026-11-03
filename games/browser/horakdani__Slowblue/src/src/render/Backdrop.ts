import { TAU } from '../core/math';
import { drawSky } from './Sky';
import { drawOrbit } from './Orbit';
import { drawRain } from './Rain';
import { drawReentry } from './Reentry';
import { drawHomecoming } from './Homecoming';
import { drawUpper } from './Upper';
import type { BackdropKind, Motif } from './Motif';
import { mix, rgba, type Rgb, type ZonePaint } from './Paint';

/**
 * Slowblue: the water each level is played in.
 *
 * This is the layer between the background gradient and everything that matters,
 * and it is the one place the game is allowed to say what a level *is* at full
 * screen size. It obeys the same three rules as the decorative life, which is why
 * it can be this large without becoming noise:
 *
 *   - it never uses a colour the zone palette does not already have,
 *   - it runs at a fraction of the contrast of the shoal, the rock and the rings,
 *   - it is anchored to the world and parallaxed, so it is scenery you move
 *     through rather than a pattern laid on the glass.
 *
 * Everything here is cheap on purpose - a handful of paths per level, no blur, no
 * second buffer - because a full-screen layer is pure fill rate and fill rate is
 * exactly what the weakest phone this has to run on has least of.
 *
 * Slowblue: the second pass gave every level *depth* rather than more stuff. The first
 * version drew one plane of decoration per level, so the water was a backdrop in the
 * theatrical sense: a painted cloth at a fixed distance. Every level now has at least
 * two planes moving at different rates, and the detail that carries the level's name -
 * embers in the trench, glitter on the current, the caustic net under the surface - is
 * on the plane the player is closest to. Two layers at different speeds is the entire
 * difference between a picture of the deep and being in it.
 */

export interface BackdropView {
  ctx: CanvasRenderingContext2D;
  paint: ZonePaint;
  w: number;
  h: number;
  cameraY: number;
  time: number;
  /** 0..1 through the current station. The surface uses it as an approach cue. */
  progress: number;
  /** Crossfade weight while a level change is in flight. */
  alpha: number;
  /** 0.4..1. The second plane and the fine detail are what a weak phone loses. */
  quality: number;
  /**
   * 0..1 swell of the campaign's 11-second breath. The same value the audio bed,
   * the vignette and the caustics run on.
   *
   * Slowblue: this field did not exist, so no backdrop could read the breath however
   * much it wanted to - and two of them wanted to. The re-entry sheath and the
   * upper air's gravity wave both carried a comment saying they pulse on the
   * breath and both ran a private sine instead, one of them at a 126-second
   * period. A clock the whole mix is built on cannot be reachable by one surface
   * and not by the rest of the picture.
   */
  breath: number;
}

/** Wraps a world-anchored element into the visible band at its own parallax rate. */
function wrapY(v: BackdropView, index: number, span: number, rate: number): number {
  const period = v.h + span * 2;
  const raw = index * span - v.cameraY * rate;
  return (((raw % period) + period) % period) - span;
}

/** Stable 0..1 from an integer. Keeps every backdrop free of stored state. */
function hash(i: number): number {
  let h = Math.imul(i ^ 0x9e3779b9, 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 13), 0xc2b2ae35);
  return ((h >>> 8) & 0xffff) / 0xffff;
}

/**
 * A shaft of light: filled with a *horizontal* gradient, so it has no sides at all -
 * brightest along its own axis, gone before its edge. Leaning is a shear on the
 * transform rather than a rotated quad, so the shaft stays vertical at its root.
 *
 * Slowblue: the first version of every light column in this file was a hard-edged quad
 * with a vertical gradient, and every one of them read as architecture: flat polygons
 * with straight sides, lit from nowhere. This is the fix, shared by four levels.
 */
function shaft(
  v: BackdropView,
  x: number,
  half: number,
  fromY: number,
  toY: number,
  colour: Rgb,
  peak: number,
  lean: number,
): void {
  const ctx = v.ctx;
  const g = ctx.createLinearGradient(x - half, 0, x + half, 0);
  g.addColorStop(0, rgba(colour, 0));
  g.addColorStop(0.5, rgba(colour, peak * v.alpha));
  g.addColorStop(1, rgba(colour, 0));
  ctx.save();
  ctx.transform(1, 0, lean / Math.max(1, v.h), 1, 0, 0);
  ctx.fillStyle = g;
  ctx.fillRect(x - half, fromY, half * 2, toY - fromY);
  ctx.restore();
}

export function drawBackdrop(kind: BackdropKind, motif: Motif, v: BackdropView): void {
  if (v.alpha < 0.01) return;
  switch (kind) {
    case 'surface':
      return surface(motif, v);
    case 'light-line':
      return lightLine(motif, v);
    case 'stream':
      return stream(v);
    case 'void':
      return empty(motif, v);
    case 'rise':
      return rise(v);
    case 'walls':
      return walls(motif, v);
    // Act II's air lives in `Sky.ts` and act III's upper atmosphere in `Upper.ts`,
    // both dispatched here so the renderer keeps one entry point and the crossfade
    // between a water level and an air one is the same two-draw blend as any other
    // level change.
    case 'spray':
    case 'cliff':
    case 'cumulus':
    case 'passage':
    case 'squall':
    case 'anvil':
      return drawSky(kind, motif, v);
    case 'jet':
    case 'ozone':
    case 'nacre':
    case 'blacksky':
    case 'noctilucent':
    case 'line':
      return drawUpper(kind, motif, v);
    case 'freefall':
    case 'aurora':
    case 'umbra':
    case 'debris':
    case 'well':
    case 'overview':
      return drawOrbit(kind, motif, v);
    case 'deorbit':
    case 'nightside':
    case 'auroraBelow':
    case 'plasma':
    case 'meteordust':
    case 'nucleus':
      return drawReentry(kind, motif, v);
    case 'cirrusFall':
    case 'underanvil':
    case 'downpour':
    case 'canopyFall':
    case 'brook':
    case 'estuary':
      return drawRain(kind, motif, v);
    case 'brackish':
    case 'sunlitFall':
    case 'twilightFall':
    case 'deepsea':
    case 'snow':
    case 'trenchHome':
      return drawHomecoming(kind, motif, v);
  }
}

/**
 * The Surface. During the last station the water ceiling physically approaches: a
 * moving, refracted horizon that was not visible anywhere in the five waters below
 * it. Its slow descent is the large-scale promise; the surfacing sequence is the
 * moment the shoal finally passes through it.
 *
 * The signature of this level is the caustic web - two families of shallow sines
 * crossing each other on the underside of moving water. It is the one thing in the
 * game that only exists because there is air up there.
 */
function surface(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const scroll = -v.cameraY * 0.1;
  const approach = v.progress * v.progress * (3 - 2 * v.progress);
  const ceilingY = v.h * (-0.11 + approach * 0.29);
  const light = mix(v.paint.speck, motif.accent, 0.3);

  ctx.globalCompositeOperation = 'lighter';
  // The ceiling grows from a distant wash into a sheet of white-blue light.
  const sky = ctx.createLinearGradient(0, ceilingY - v.h * 0.22, 0, ceilingY + v.h * 0.42);
  sky.addColorStop(0, rgba(light, (0.2 + approach * 0.22) * v.alpha));
  sky.addColorStop(0.38, rgba(light, (0.08 + approach * 0.09) * v.alpha));
  sky.addColorStop(1, rgba(light, 0));
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, v.w, Math.min(v.h, ceilingY + v.h * 0.42));

  // The sun, seen through forty metres of water: no disc, just the place the light
  // is coming from. It drifts with the level, so it is a direction, not a fixture.
  const sunX = v.w * (0.34 + 0.1 * Math.sin(t * 0.05));
  const sun = ctx.createRadialGradient(
    sunX,
    ceilingY - v.h * 0.08,
    0,
    sunX,
    ceilingY - v.h * 0.08,
    v.h * 0.55,
  );
  sun.addColorStop(0, rgba(light, (0.07 + approach * 0.1) * v.alpha));
  sun.addColorStop(1, rgba(light, 0));
  ctx.fillStyle = sun;
  ctx.fillRect(0, 0, v.w, ceilingY + v.h * 0.5);

  // Rays widen and strengthen as the shoal closes the final distance, and they all
  // lean away from where the light is.
  for (let i = 0; i < 4; i++) {
    const seed = i * 0.37;
    const x = (((seed + scroll * 0.00018) % 1.4) - 0.2) * v.w;
    const wide = v.w * (0.15 + 0.06 * Math.sin(t * 0.11 + i * 2.1));
    const peak = 0.03 + approach * 0.04 + 0.01 * Math.sin(t * 0.09 + i);
    shaft(v, x, wide, ceilingY, v.h, light, peak, (x - sunX) * 0.45);
  }

  // The caustic web. Two crossing families, world-anchored so it slides past rather
  // than shimmering in place, and strongest right under the ceiling.
  if (v.quality > 0.55) {
    const netY = ceilingY + v.h * 0.06;
    const drift = -v.cameraY * 0.22;
    const period = v.h * 0.66;
    ctx.strokeStyle = rgba(light, (0.035 + approach * 0.045) * v.alpha);
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    for (let i = 0; i < 6; i++) {
      const base = netY + ((((i * 74 + drift) % period) + period) % period);
      for (let x = -10; x <= v.w + 10; x += 16) {
        const y =
          base + Math.sin(x * 0.019 + t * 0.42 + i) * 11 + Math.sin(x * 0.007 - t * 0.26) * 15;
        if (x === -10) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
    }
    for (let i = 0; i < 4; i++) {
      const bx = ((i + 0.5) / 4) * v.w;
      for (let y = ceilingY; y <= ceilingY + v.h * 0.7; y += 20) {
        const x = bx + Math.sin(y * 0.017 + t * 0.33 + i * 1.7) * 20;
        if (y === ceilingY) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }

  // Three nearly coincident wave traces avoid a hard UI-like divider. Their
  // interference is the first unmistakable horizontal form in the campaign.
  ctx.lineCap = 'round';
  for (let band = 0; band < 3; band++) {
    ctx.strokeStyle = rgba(light, (0.09 + approach * 0.13 - band * 0.02) * v.alpha);
    ctx.lineWidth = 1.2 + band * 1.4;
    ctx.beginPath();
    for (let x = -12; x <= v.w + 12; x += 8) {
      const y =
        ceilingY +
        band * 5 +
        Math.sin(x * 0.032 + t * 0.2 + band * 1.7) * (3 + band * 1.2) +
        Math.sin(x * 0.011 - t * 0.13) * 4;
      if (x === -12) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }

  // Air beads make the direction literal: every one travels upward into the moving
  // line and disappears there.
  ctx.strokeStyle = rgba(light, (0.09 + approach * 0.09) * v.alpha);
  ctx.lineWidth = 1;
  ctx.beginPath();
  for (let i = 0; i < 11; i++) {
    const cycle = ((t * (0.035 + (i % 3) * 0.007) + i * 0.137) % 1 + 1) % 1;
    const x = v.w * (0.08 + ((i * 0.217) % 0.84)) + Math.sin(t * 0.17 + i) * 9;
    const y = ceilingY + (1 - cycle) * v.h * 0.72;
    if (y < ceilingY + 8 || y > v.h + 12) continue;
    const r = 1.5 + cycle * 3.2;
    ctx.moveTo(x + r, y);
    ctx.arc(x, y, r, 0, TAU);
  }
  ctx.stroke();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * The Light Line. This is not the surface yet: it is the last depth where light
 * holds together into visible columns before dissolving into black water.
 *
 * Everything in this level is about one boundary, so the boundary is built from four
 * things that disagree slightly about where it is: a wash that stops, shafts that
 * end, three broken traces, and a band of shear just underneath it. Nothing in it is
 * a straight line, and no two elements share a Y.
 */
function lightLine(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const light = mix(v.paint.speck, motif.accent, 0.36);
  // The boundary *approaches* across the station it is named for. It used to be a
  // constant with a 180-second sine on it, which at this act's pace means the one
  // picture in the campaign whose whole subject is a line the player is rising
  // toward drew a line that wandered and never arrived. `v.progress` is the field
  // every act from II to VII already uses for exactly this, and act I read it in
  // one backdrop out of six.
  const edgeY = v.h * (0.46 - v.progress * 0.18) + Math.sin(t * 0.035) * v.h * 0.025;

  ctx.globalCompositeOperation = 'lighter';

  // Light exists above the boundary, but it never becomes the bright ceiling of
  // the final level. The lower half remains in the older, darker water.
  const wash = ctx.createLinearGradient(0, -v.h * 0.05, 0, edgeY + v.h * 0.34);
  wash.addColorStop(0, rgba(light, 0.085 * v.alpha));
  wash.addColorStop(0.55, rgba(light, 0.034 * v.alpha));
  wash.addColorStop(1, rgba(light, 0));
  ctx.fillStyle = wash;
  ctx.fillRect(0, 0, v.w, edgeY + v.h * 0.34);

  // Incomplete shafts, terminating at different depths and all of them short of the
  // boundary: light that is running out, which is what the level is named for.
  for (let i = 0; i < 5; i++) {
    const x = v.w * (0.06 + ((i * 0.29 + 0.06) % 0.9));
    const half = v.w * (0.07 + (i % 2) * 0.03);
    const end = edgeY - v.h * 0.02 + (i % 3) * v.h * 0.05;
    shaft(v, x, half, -20, end, light, 0.03 + (i % 2) * 0.008, Math.sin(t * 0.07 + i * 1.8) * v.w * 0.05);
  }

  // A dim caustic net far above: the surface is up there, and this is the last depth
  // that can still see any structure in it at all.
  if (v.quality > 0.6) {
    ctx.strokeStyle = rgba(light, 0.02 * v.alpha);
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    for (let i = 0; i < 4; i++) {
      const base = v.h * (0.03 + i * 0.06);
      for (let x = -10; x <= v.w + 10; x += 20) {
        const y = base + Math.sin(x * 0.015 + t * 0.3 + i * 1.4) * 9;
        if (x === -10) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }

  // Three broken traces form one organic boundary. Gaps keep it out of the HUD's
  // visual language, and the traces never meet the screen edges at the same Y.
  ctx.lineCap = 'round';
  for (let band = 0; band < 3; band++) {
    ctx.strokeStyle = rgba(light, (0.05 - band * 0.01) * v.alpha);
    ctx.lineWidth = 1.1 + band * 1.2;
    ctx.beginPath();
    let drawing = false;
    for (let x = -8; x <= v.w + 8; x += 7) {
      const gap = ((Math.floor(x / 7) + band * 5) % 13) < 2;
      const y =
        edgeY +
        band * 5 +
        Math.sin(x * 0.024 + t * 0.13 + band) * 7 +
        Math.sin(x * 0.061 - t * 0.08) * 2.5;
      if (gap) {
        drawing = false;
      } else if (!drawing) {
        ctx.moveTo(x, y);
        drawing = true;
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }

  // Dust hanging in the last of the light. Only above the boundary - below it there
  // is nothing to catch - and the one thing in this level that scrolls with the world.
  if (v.quality > 0.55) {
    ctx.fillStyle = rgba(light, 0.09 * v.alpha);
    ctx.beginPath();
    for (let i = 0; i < 16; i++) {
      const y = wrapY(v, i, 90, 0.55);
      if (y > edgeY + 12 || y < -6) continue;
      const x = v.w * hash(i * 7 + 3) + Math.sin(t * 0.2 + i) * 4;
      const r = 0.7 + hash(i * 13) * 1.1;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * The Drift. The level is named after moving water, so the water moves - and it moves
 * at three different rates, which is the only way a moving field reads as *volume*
 * rather than as a slide passing behind glass: long slow ribbons a long way off, a
 * middle layer of them, and fast fine streaks close to the camera.
 */
function stream(v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  ctx.lineCap = 'round';
  ctx.globalCompositeOperation = 'lighter';

  const layers = v.quality > 0.55 ? 3 : 2;
  for (let layer = 0; layer < layers; layer++) {
    // Further layers are slower, dimmer and wider: a ribbon of current seen from
    // further away is a broader, softer thing than one going past your ear.
    const rate = 0.85 + layer * 0.5;
    const dim = 1 - layer * 0.22;
    const count = 4 + layer;
    for (let i = 0; i < count; i++) {
      const index = i + layer * 11;
      const y = wrapY(v, index, 300 - layer * 40, rate);
      const len = (240 + hash(index) * 240) * (1 + layer * 0.1);
      if (y + len < -80 || y - len > v.h + 80) continue;
      const x = v.w * (0.06 + hash(index * 3 + 1) * 0.88);
      const bow = (22 + hash(index * 5) * 30) * (index % 2 === 0 ? 1 : -1);
      const drift = Math.sin(t * 0.14 + index * 1.3) * 22;
      ctx.beginPath();
      ctx.moveTo(x + drift, y + len * 0.5);
      ctx.quadraticCurveTo(x + drift + bow, y, x + drift, y - len * 0.5);
      for (const [width, a] of [
        [14 + layer * 6, 0.012],
        [3.4, 0.019],
      ] as const) {
        ctx.strokeStyle = rgba(v.paint.tracer, a * dim * v.alpha);
        ctx.lineWidth = width;
        ctx.stroke();
      }
    }
  }

  // The shear front: the boundary between two bodies of water travelling at different
  // speeds. One soft wide stroke along a wandering line, which is exactly how it looks
  // from above when silt collects along it.
  const frontY = wrapY(v, 0, 1400, 0.6);
  if (frontY > -140 && frontY < v.h + 140) {
    ctx.beginPath();
    for (let x = -12; x <= v.w + 12; x += 22) {
      const y = frontY + Math.sin(x * 0.006 + 1.4) * 46 + Math.sin(x * 0.017 - t * 0.05) * 14;
      if (x === -12) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    for (const [width, a] of [
      [26, 0.01],
      [5, 0.016],
    ] as const) {
      ctx.strokeStyle = rgba(mix(v.paint.tracer, v.paint.speck, 0.5), a * v.alpha);
      ctx.lineWidth = width;
      ctx.stroke();
    }
  }

  // Fine streaks in the near water, running faster than the camera. These are what
  // make the level feel like it is *going somewhere*, and they are one path.
  if (v.quality > 0.5) {
    ctx.strokeStyle = rgba(v.paint.speck, 0.075 * v.alpha);
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    for (let i = 0; i < 18; i++) {
      const y = wrapY(v, i, 130, 2.1);
      const x = v.w * hash(i * 9 + 5) + Math.sin(t * 0.3 + i) * 7;
      const len = 16 + hash(i * 17) * 34;
      ctx.moveTo(x, y + len * 0.5);
      ctx.quadraticCurveTo(x + (hash(i) - 0.5) * 10, y, x, y - len * 0.5);
    }
    ctx.stroke();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Black Water, which owes the player nothing to look at.
 *
 * Every other level adds something to its water; this one takes it away. One cold
 * glow far ahead - the only thing in the game that suggests a distance rather than
 * a place - and a slow darkening everywhere else. An empty level between two busy
 * ones is what makes the busy ones read as busy.
 *
 * Slowblue: it is not, however, allowed to be *nothing*, because nothing is indistinguishable
 * from a bug in a dark room. It gets the one thing the abyss really has: living light.
 * A handful of pinpricks that come up over seconds, hold, and go out, plus - rarely,
 * and never twice in the same place - one slow pulse from something that is much too
 * far away to matter.
 */
function empty(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const breathe = 0.5 + 0.5 * Math.sin(t * 0.045);
  const g = ctx.createRadialGradient(
    v.w * 0.5,
    -v.h * 0.12,
    0,
    v.w * 0.5,
    -v.h * 0.12,
    v.h * 0.75,
  );
  g.addColorStop(0, rgba(v.paint.speck, (0.02 + 0.012 * breathe) * v.alpha));
  g.addColorStop(1, rgba(v.paint.speck, 0));
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, v.w, v.h);

  // Bioluminescence. Each point owns a long cycle: dark, a slow swell, dark again.
  // They are world-anchored, so a light that came up beside you stays where it was.
  const live = mix(v.paint.speck, motif.accent, 0.5);
  for (let i = 0; i < 10; i++) {
    const y = wrapY(v, i, 240, 0.9);
    if (y < -30 || y > v.h + 30) continue;
    const period = 5.5 + hash(i * 31) * 5;
    const phase = ((t + hash(i * 7) * period) % period) / period;
    // One smooth swell per cycle, dark for most of it: sin^4 spends its time at zero.
    const glow = Math.pow(Math.sin(phase * Math.PI), 4);
    if (glow < 0.02) continue;
    const x = v.w * (0.05 + hash(i * 13 + 2) * 0.9);
    const r = 2 + hash(i * 3) * 3;
    const halo = ctx.createRadialGradient(x, y, 0, x, y, r * 7);
    halo.addColorStop(0, rgba(live, 0.5 * glow * v.alpha));
    halo.addColorStop(0.25, rgba(live, 0.12 * glow * v.alpha));
    halo.addColorStop(1, rgba(live, 0));
    ctx.fillStyle = halo;
    ctx.fillRect(x - r * 7, y - r * 7, r * 14, r * 14);
  }

  // ...and, occasionally, one pulse from something with a body. It never resolves and
  // it never comes closer: a ring that opens once and is gone.
  const pulseIndex = Math.floor(-v.cameraY / 2600);
  const pulseY = wrapY(v, pulseIndex, 2600, 0.75);
  const pulsePhase = ((t * 0.06 + hash(pulseIndex * 17)) % 1 + 1) % 1;
  if (pulsePhase < 0.4 && pulseY > -200 && pulseY < v.h + 200) {
    const k = pulsePhase / 0.4;
    const fade = Math.sin(k * Math.PI);
    ctx.strokeStyle = rgba(live, 0.05 * fade * v.alpha);
    ctx.lineWidth = 1 + (1 - k) * 2;
    ctx.beginPath();
    ctx.arc(v.w * (0.15 + hash(pulseIndex * 5) * 0.7), pulseY, 30 + k * v.w * 0.6, 0, TAU);
    ctx.stroke();
  }
  ctx.globalCompositeOperation = 'source-over';

  // Pressure: the sides close in, very slightly, and never stop. Weak and wide on
  // purpose - the moment an edge darkening has a discernible inner boundary it stops
  // being pressure and starts being a wall the player steers around for nothing.
  const sides = ctx.createLinearGradient(0, 0, v.w, 0);
  sides.addColorStop(0, rgba(v.paint.bottom, 0.4 * v.alpha));
  sides.addColorStop(0.46, rgba(v.paint.bottom, 0));
  sides.addColorStop(0.54, rgba(v.paint.bottom, 0));
  sides.addColorStop(1, rgba(v.paint.bottom, 0.4 * v.alpha));
  ctx.fillStyle = sides;
  ctx.fillRect(0, 0, v.w, v.h);
}

/**
 * The Blue Rise. Broad columns travel in the same direction as the shoal, while small
 * beads visibly climb through them. The curves are much larger and slower than a
 * playable current, so they remain a direction cue rather than a hazard.
 *
 * This is also the level where light first arrives from above rather than from the
 * things in the water, so it gets the campaign's first (very faint) shafts.
 */
function rise(v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const tint = mix(v.paint.tracer, v.paint.speck, 0.42);

  const upper = ctx.createLinearGradient(0, 0, 0, v.h);
  upper.addColorStop(0, rgba(tint, 0.05 * v.alpha));
  upper.addColorStop(0.62, rgba(tint, 0.01 * v.alpha));
  upper.addColorStop(1, rgba(tint, 0));
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = upper;
  ctx.fillRect(0, 0, v.w, v.h);

  // The first light from above in the campaign. Barely there on purpose: this level
  // is the promise of the surface, and the two levels above it are the delivery.
  if (v.quality > 0.55) {
    for (let i = 0; i < 3; i++) {
      const x = v.w * (0.2 + i * 0.3 + 0.04 * Math.sin(t * 0.06 + i));
      // ...and the first light from above in the campaign gets stronger and
      // reaches further as the Blue Rise climbs, rather than sitting at one alpha
      // for the whole station.
      shaft(v, x, v.w * 0.13, -20, v.h * (0.5 + v.progress * 0.2), tint, 0.01 + v.progress * 0.014, v.w * 0.1);
    }
  }

  ctx.lineCap = 'round';
  for (let i = 0; i < 5; i++) {
    const x = v.w * (0.08 + ((i * 0.217) % 0.88));
    const lean = Math.sin(t * 0.08 + i * 1.4) * v.w * 0.065;
    ctx.beginPath();
    ctx.moveTo(x - lean, v.h + 80);
    ctx.bezierCurveTo(x + lean * 1.8, v.h * 0.72, x - lean * 1.5, v.h * 0.26, x + lean, -80);
    for (const [width, alpha] of [
      [22, 0.009],
      [3, 0.027],
    ] as const) {
      ctx.strokeStyle = rgba(tint, alpha * v.alpha);
      ctx.lineWidth = width;
      ctx.stroke();
    }
  }

  // Bubble chains make "up" unambiguous. Their columns meander with the same slow
  // rhythm as the broad flow, but the individual beads rise at different rates.
  ctx.strokeStyle = rgba(tint, 0.075 * v.alpha);
  ctx.lineWidth = 1;
  ctx.beginPath();
  for (let i = 0; i < 16; i++) {
    const speed = 0.018 + (i % 4) * 0.004;
    const cycle = ((t * speed + i * 0.157 - v.cameraY * 0.000035) % 1 + 1) % 1;
    const y = v.h + 30 - cycle * (v.h + 90);
    const column = v.w * (0.1 + ((i * 0.237) % 0.8));
    const x = column + Math.sin(cycle * TAU * 1.6 + i) * (5 + (i % 3) * 3);
    const r = 1.2 + (i % 4) * 0.65;
    ctx.moveTo(x + r, y);
    ctx.arc(x, y, r, 0, TAU);
  }
  ctx.stroke();

  // Plankton caught in the columns, lit from above. The water here is *populated*,
  // which is the difference between this level and the black water below it.
  if (v.quality > 0.5) {
    ctx.fillStyle = rgba(v.paint.speck, 0.1 * v.alpha);
    ctx.beginPath();
    for (let i = 0; i < 22; i++) {
      const y = wrapY(v, i, 110, 1.15);
      const x = v.w * hash(i * 11 + 7) + Math.sin(t * 0.25 + i * 0.7) * 9;
      const r = 0.6 + hash(i * 5) * 1.2;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * The Trench Floor: the deepest water in the game, and the only one with warmth in it.
 *
 * Slowblue: this level used to draw actual canyon walls - filled silhouettes down both
 * edges with a visible face. They were never collidable and they were never meant to
 * be, and that is exactly the problem: a dark shape with a *defined edge* standing in
 * the play field is an obstacle, whatever the code thinks it is. Players read it as
 * one, steered around it, and lost width they always had. Anything drawn at the edges
 * now has to be edgeless, so the whole cliff is gone and what remains is pressure:
 * the light simply runs out toward the sides, on a gradient with no boundary anywhere
 * in it. The trench keeps its identity where identity cannot be mistaken for geometry -
 * in the vents, and in the embers leaving them.
 */
function walls(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const dark = mix(v.paint.bottom, motif.base, 0.7);

  // Two gradients, one per side. No stop is opaque enough to read as a surface and
  // none of them ever stops abruptly, so there is nothing here to steer around.
  for (const side of [0, 1] as const) {
    const from = side === 0 ? 0 : v.w;
    const to = side === 0 ? v.w * 0.34 : v.w * 0.66;
    const g = ctx.createLinearGradient(from, 0, to, 0);
    g.addColorStop(0, rgba(dark, 0.72 * v.alpha));
    g.addColorStop(0.45, rgba(dark, 0.22 * v.alpha));
    g.addColorStop(1, rgba(dark, 0));
    ctx.fillStyle = g;
    ctx.fillRect(side === 0 ? 0 : v.w * 0.66, 0, v.w * 0.34, v.h);
  }

  // ...and one along the floor of the frame, so the slot closes behind the shoal too
  // rather than only at its sides.
  const floor = ctx.createLinearGradient(0, v.h, 0, v.h * 0.72);
  floor.addColorStop(0, rgba(dark, 0.5 * v.alpha));
  floor.addColorStop(1, rgba(dark, 0));
  ctx.fillStyle = floor;
  ctx.fillRect(0, v.h * 0.72, v.w, v.h * 0.28);

  ctx.globalCompositeOperation = 'lighter';
  // Vents. Three per screen at most, on a slow flicker, and dim enough that they
  // are a colour in the wall rather than a light in the room.
  for (let i = 0; i < 3; i++) {
    const y = wrapY(v, i, 520, 0.82);
    if (y < -140 || y > v.h + 140) continue;
    const x = i % 2 === 0 ? v.w * 0.06 : v.w * 0.94;
    const flicker = 0.55 + 0.45 * Math.sin(t * (0.6 + i * 0.23) + i);
    const g = ctx.createRadialGradient(x, y, 0, x, y, 120);
    g.addColorStop(0, rgba(motif.accent, 0.075 * flicker * v.alpha));
    g.addColorStop(0.4, rgba(motif.accent, 0.02 * flicker * v.alpha));
    g.addColorStop(1, rgba(motif.accent, 0));
    ctx.fillStyle = g;
    ctx.fillRect(x - 120, y - 120, 240, 240);

    // Embers: what the vent is actually doing. They rise, they wander, they cool.
    // Warm points climbing a black wall is the whole identity of the trench floor.
    if (v.quality <= 0.55) continue;
    ctx.strokeStyle = rgba(motif.accent, 0.14 * flicker * v.alpha);
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    for (let e = 0; e < 5; e++) {
      const seed = hash(i * 29 + e);
      const cycle = ((t * (0.09 + seed * 0.05) + seed) % 1 + 1) % 1;
      const ey = y - cycle * 210;
      const ex = x + Math.sin(cycle * 5.5 + e) * (8 + cycle * 26) * (i % 2 === 0 ? 1 : -1);
      const len = 3 + (1 - cycle) * 5;
      ctx.moveTo(ex, ey + len);
      ctx.lineTo(ex, ey);
    }
    ctx.stroke();
  }
  ctx.globalCompositeOperation = 'source-over';
}
