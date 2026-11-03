import { TAU, clamp } from '../core/math';
import { mix, rgba, type Rgb, type ZonePaint } from './Paint';

/**
 * Slowblue: the thing that hunts you in the air.
 *
 * Act II shipped once with the water's hunter in it - the same top-down pelagic
 * shark, snout and lunate tail and all, cruising at eleven kilometres. It was the
 * clearest single symptom of an act that had been given the water's clothes: a
 * predatory fish in the sky is not a stylisation, it is a category error, and no
 * amount of palette work fixes it.
 *
 * So the air gets its own animal, and `Hunter.ts` goes back to being the water's
 * alone. Everything about the two is parallel and nothing is shared, because the
 * whole point is that they are different animals:
 *
 * | | the hunter | the raptor |
 * | --- | --- | --- |
 * | body | a spine carrying a travelling wave | a rigid airframe |
 * | threat field | the water going dark around it | its shadow, crossing yours |
 * | commitment | the body *stiffens* into a straight line | the wings **fold** |
 *
 * That last row is the one worth the file. A shark commits by going rigid, which
 * is a subtle thing to draw. A falcon commits by pulling its wings in until it is
 * a teardrop with a beak, and it is the most recognisable posture in the animal
 * kingdom - so `lunge` here does not tint the outline, it **changes what animal
 * shape you are looking at**: broad, fingered and soaring at rest, swept into a
 * dart the instant it means it. The player reads the commitment from the
 * silhouette alone, at flock distance, before any warning colour arrives.
 */

export interface RaptorView {
  ctx: CanvasRenderingContext2D;
  paint: ZonePaint;
  /** The station's accent, so the eye and the lunge rim belong to this sky. */
  accent: Rgb;
  time: number;
  quality: number;
}

/** The one warm colour a raptor is allowed. Spent on the arc, the rim and the eye. */
const WARN: Rgb = [255, 104, 92];
/** Threat radius, as a multiple of body size. Matches the water hunter's. */
const DREAD = 5.5;
/**
 * Strike radius, as a multiple of body size. `PredatorSystem.BITE_REACH` is 1.5;
 * the drawn arc sits a hair outside it so the line is visible rather than exactly
 * on the frame where an individual is already gone.
 */
const STRIKE = 1.9;
/**
 * Body length and half-width as multiples of size.
 *
 * The half-width is the number that was wrong first. At 0.34 the fuselage was a
 * fifth as wide as the animal was long, the broad wing sat on top of it, and the
 * whole silhouette read as a seal rather than as a bird - which is exactly the
 * failure `Flock.ts` had to be rescued from, one animal at a time.
 */
const LEN = 2;
const WID = 0.26;

/** Stations from wing root to tip, as in `Flock.ts`. */
const STATIONS = [0, 0.3, 0.58, 0.82, 1] as const;
/** Nose ahead of the origin, tail base behind it. Same frame as the flock. */
const NOSE = 0.6;
const TAIL_BASE = -0.4;
const SHOULDER = 0.22;

/**
 * The two postures, and everything in between.
 *
 * A soaring raptor holds a broad wing square to the air with the primaries split
 * into fingers; a stooping one folds until the span has halved and the whole
 * outline is one swept teardrop. Both are the same five stations, so `lunge`
 * simply interpolates - which means there is no frame where the animal is
 * neither, and no popping between two drawings.
 */
const SOAR_SPAN = 7.4;
const STOOP_SPAN = 3.4;
const SOAR_LEAD = [0, 0.05, 0.12, 0.21, 0.31] as const;
const STOOP_LEAD = [0, 0.17, 0.42, 0.7, 0.98] as const;
// Broader than any bird in the flock and nowhere near as broad as it first was:
// a soaring raptor's root chord is about half its body length, not two thirds.
const SOAR_CHORD = [0.5, 0.46, 0.37, 0.26, 0.16] as const;
const STOOP_CHORD = [0.4, 0.28, 0.16, 0.08, 0.05] as const;
/** How far the head projects, and its half-width. Small: a raptor is all wing. */
const HEAD = 0.14;
const HEAD_WIDE = 0.72;

/*
 * The wing, resolved for the animal being drawn right now. Module-level for the
 * same reason `Flock.ts` does it: this runs per raptor per frame and must not
 * allocate. Single-threaded, never re-entered.
 */
const wAcross = [0, 0, 0, 0, 0];
const wLead = [0, 0, 0, 0, 0];
const wTrail = [0, 0, 0, 0, 0];
const wOut = new Float64Array(64);
let wCount = 0;

let fx = 0;
let fy = 0;
let fdx = 0;
let fdy = 0;
let fnx = 0;
let fny = 0;
let flen = 0;
let fwid = 0;
let shape: CanvasRenderingContext2D;

function frame(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  dx: number,
  dy: number,
  size: number,
): void {
  shape = ctx;
  fx = x;
  fy = y;
  fdx = dx;
  fdy = dy;
  fnx = -dy;
  fny = dx;
  flen = size * LEN;
  fwid = size * WID;
}

function at(along: number, across: number): [number, number] {
  const ax = along * flen;
  const ac = across * fwid;
  return [fx + fdx * ax + fnx * ac, fy + fdy * ax + fny * ac];
}

function put(along: number, across: number, first = false): void {
  const p = at(along, across);
  if (first) shape.moveTo(p[0], p[1]);
  else shape.lineTo(p[0], p[1]);
}

function putQ(cAlong: number, cAcross: number, along: number, across: number): void {
  const c = at(cAlong, cAcross);
  const p = at(along, across);
  shape.quadraticCurveTo(c[0], c[1], p[0], p[1]);
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/**
 * Resolve the wing for this `lunge` and this instant of the beat, and walk it
 * once into `wOut` - root, out the leading edge, round the tip, back along the
 * trailing edge. The left wing is that list reversed, exactly as in `Flock.ts`,
 * so the two sides are guaranteed identical.
 */
function wing(lunge: number, beat: number, fingers: boolean): void {
  // A raptor on patrol barely beats; the beat also dies away as it folds, because
  // a stooping bird is not flying, it is falling on purpose.
  const work = 0.16 * (1 - lunge) * (1 - Math.cos(beat)) * 0.5;
  const span = lerp(SOAR_SPAN, STOOP_SPAN, lunge);
  const shoulder = NOSE - SHOULDER;
  for (let i = 0; i < STATIONS.length; i++) {
    const u = STATIONS[i]!;
    wAcross[i] = span * u * (1 - work);
    const back = lerp(SOAR_LEAD[i]!, STOOP_LEAD[i]!, lunge) + work * 0.3 * u * u;
    const chord = lerp(SOAR_CHORD[i]!, STOOP_CHORD[i]!, lunge) * (1 - work * 0.4 * u);
    // The arm bows forward, and it bows less the more the bird is folded.
    const bow = 0.05 * Math.sin(u * Math.PI) * (1 - lunge);
    wLead[i] = shoulder - back + bow;
    wTrail[i] = shoulder - back - chord;
  }
  wAcross[0] = 1;

  wCount = 0;
  const emit = (along: number, across: number): void => {
    wOut[wCount * 2] = along;
    wOut[wCount * 2 + 1] = across;
    wCount++;
  };
  for (let i = 0; i < STATIONS.length; i++) emit(wLead[i]!, wAcross[i]!);
  emit(wTrail[4]!, wAcross[4]!);
  for (let i = STATIONS.length - 2; i >= 0; i--) {
    // Fingered primaries, and they close as the bird folds: the slots are what a
    // wing uses to soar, and a stooping falcon has no use for them at all.
    const slots = fingers ? Math.round(2.6 * (1 - lunge)) : 0;
    if (slots > 0 && i >= 2) {
      const steps = i === 3 ? Math.min(2, slots) : Math.max(1, slots - 1);
      for (let k = 0; k < steps; k++) {
        const t = (k + 1) / (steps + 1);
        const along = lerp(wTrail[i + 1]!, wTrail[i]!, t);
        const across = lerp(wAcross[i + 1]!, wAcross[i]!, t);
        emit(along + 0.13 * (1 - lunge), across);
        emit(along, across);
      }
    }
    emit(wTrail[i]!, wAcross[i]!);
  }
}

/**
 * The threat field.
 *
 * The water's hunter darkens its own patch of ocean, because fear underwater is
 * the room closing. In air nothing closes - what a bird under a raptor actually
 * gets is **the shadow**, and it arrives before the bird does. So the dread here
 * is one soft dark ellipse cast down the course, growing and sharpening as the
 * animal commits, and the strike distance is the same dashed arc act I earned:
 * the range of the thing that eats you is information the player is owed.
 */
export function drawRaptorThreat(
  v: RaptorView,
  x: number,
  y: number,
  size: number,
  lunge: number,
): void {
  const ctx = v.ctx;
  // Down the course - the same direction every other shadow in the game falls,
  // because the light in this world comes from the way the player is going.
  const sy = y + size * (2.2 - lunge * 1.6);
  const r = size * DREAD * (0.62 + lunge * 0.2);
  const shade = ctx.createRadialGradient(x, sy, 0, x, sy, r);
  // A shadow, not a stain: the darkest thing a sky can do is be less bright.
  const dark = mix(v.paint.mid, [4, 6, 14], 0.55 + lunge * 0.2);
  shade.addColorStop(0, rgba(dark, 0.16 + lunge * 0.2));
  shade.addColorStop(0.5, rgba(dark, 0.07 + lunge * 0.1));
  shade.addColorStop(1, rgba(dark, 0));
  ctx.fillStyle = shade;
  ctx.beginPath();
  ctx.ellipse(x, sy, r, r * 0.72, 0, 0, TAU);
  ctx.fill();

  const strike = size * STRIKE * (1 + lunge * 0.12);
  const turn = v.time * 0.6;
  ctx.save();
  ctx.setLineDash([4, 9]);
  ctx.lineDashOffset = -turn * 12;
  ctx.strokeStyle = rgba(WARN, 0.16 + lunge * 0.42);
  ctx.lineWidth = 1 + lunge * 1.2;
  ctx.beginPath();
  ctx.arc(x, y, strike, 0, TAU);
  ctx.stroke();
  ctx.restore();
}

/**
 * One raptor. `dx,dy` is its unit heading, `lunge` 0..1 is how committed it is,
 * and `beat` drives what little wingbeat it has.
 */
export function drawRaptor(
  v: RaptorView,
  x: number,
  y: number,
  dx: number,
  dy: number,
  size: number,
  lunge: number,
  beat: number,
): void {
  const ctx = v.ctx;
  frame(ctx, x, y, dx, dy, size);
  const detail = v.quality > 0.5;
  wing(lunge, beat, detail);

  // A fanned tail closes as the bird folds, exactly as the wings do: a stooping
  // falcon's tail is shut into a blade.
  const tail = lerp(0.4, 0.28, lunge);
  const fork = lerp(1.15, 0.45, lunge);
  const notch = lerp(1.35, 1.02, lunge);
  const tailTip = TAIL_BASE - tail;
  const head = lerp(HEAD, HEAD * 1.3, lunge);

  const body = (): void => {
    ctx.beginPath();
    put(NOSE + head, 0, true);
    putQ(NOSE + head * 0.7, HEAD_WIDE * 1.1, NOSE - 0.05, HEAD_WIDE);
    putQ(wLead[0]! + 0.08, 1, wLead[0]!, 1);
    for (let i = 1; i < wCount; i++) put(wOut[i * 2]!, wOut[i * 2 + 1]!);
    putQ(wTrail[0]! - 0.12, 0.9, TAIL_BASE, 0.6);
    put(tailTip, fork);
    put(TAIL_BASE - tail * notch, 0);
    put(tailTip, -fork);
    put(TAIL_BASE, -0.6);
    putQ(wTrail[0]! - 0.12, -0.9, wOut[(wCount - 1) * 2]!, -wOut[(wCount - 1) * 2 + 1]!);
    for (let i = wCount - 2; i >= 0; i--) put(wOut[i * 2]!, -wOut[i * 2 + 1]!);
    putQ(wLead[0]! + 0.08, -1, NOSE - 0.05, -HEAD_WIDE);
    putQ(NOSE + head * 0.7, -HEAD_WIDE * 1.1, NOSE + head, 0);
    ctx.closePath();
  };

  // --- cast shadow ------------------------------------------------------
  // The animal's own outline, offset down the course. It is what puts the raptor
  // *above* the air the flock is in rather than in the same plane as it - and it
  // is the same shape as the threat field, so the dread and the animal agree.
  if (v.quality > 0.55) {
    ctx.save();
    ctx.translate(dx * -3 + 2, dy * -3 + 6);
    body();
    ctx.fillStyle = rgba(mix(v.paint.mid, [2, 3, 8], 0.6), 0.26);
    ctx.fill();
    ctx.restore();
  }

  // --- body -------------------------------------------------------------
  // Dark against a bright sky and *still* dark against a black one: at altitude
  // the flock is the brightest thing in the frame, so the threat has to be the
  // one shape that is not. Pulled toward the station's rock rim rather than to
  // black, for the same reason the hunter is - a hole is not an animal.
  const dark = mix(mix(v.paint.rock, v.paint.top, 0.45), [6, 5, 10], 0.5);
  const flank = ctx.createLinearGradient(
    x - fnx * size * 1.4,
    y - fny * size * 1.4,
    x + fnx * size * 1.4,
    y + fny * size * 1.4,
  );
  // Countershading, seen from above: the back is the darkest part of the bird and
  // one flank picks up the sky, so the body has roll in it.
  flank.addColorStop(0, rgba(mix(dark, v.paint.speck, 0.26), 1));
  flank.addColorStop(0.52, rgba(dark, 1));
  flank.addColorStop(1, rgba(mix(dark, [0, 0, 0], 0.5), 1));
  body();
  ctx.fillStyle = flank;
  ctx.fill();

  // Rim: cool while it patrols, warm the instant it folds. One stroke, two moods.
  ctx.strokeStyle = rgba(
    mix(mix(v.paint.speck, v.accent, 0.4), WARN, lunge),
    0.34 + lunge * 0.5,
  );
  ctx.lineWidth = 1 + lunge * 0.9;
  ctx.stroke();

  if (v.quality > 0.5) {
    // --- the marks ------------------------------------------------------
    // Dark trailing edge and darker primaries: on almost every soaring raptor
    // the wing is paler in the middle than at its edges, and that band is what
    // the eye uses to read a wing as a wing rather than as a blade.
    // Both quads wound the same way (the left one is emitted in reverse), so a
    // raptor overlapping anything else in the same fill cannot punch a hole in
    // it - the nonzero winding trap `Flock.traceWingTips` documents.
    ctx.fillStyle = rgba(mix(dark, [0, 0, 0], 0.45), 0.85);
    ctx.beginPath();
    put(wLead[3]!, wAcross[3]!, true);
    put(wLead[4]!, wAcross[4]!);
    put(wTrail[4]!, wAcross[4]!);
    put(wTrail[3]!, wAcross[3]!);
    ctx.closePath();
    put(wTrail[3]!, -wAcross[3]!, true);
    put(wTrail[4]!, -wAcross[4]!);
    put(wLead[4]!, -wAcross[4]!);
    put(wLead[3]!, -wAcross[3]!);
    ctx.closePath();
    ctx.fill();

    // A pale nape. Most raptors have one, it sits exactly where the eye already
    // is, and it is the cheapest possible way to say "this end is the head".
    ctx.fillStyle = rgba(mix(v.paint.speck, dark, 0.42), 0.5);
    ctx.beginPath();
    const nape = at(NOSE - 0.14, 0);
    ctx.ellipse(nape[0], nape[1], size * 0.13, size * 0.08, Math.atan2(dy, dx), 0, TAU);
    ctx.fill();

    // Two bars across the tail. A real field mark, two strokes, and the thing
    // that stops a fanned tail from reading as a paper dart.
    ctx.strokeStyle = rgba(mix(dark, [0, 0, 0], 0.4), 0.6);
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let i = 0; i < 2; i++) {
      const t = 0.45 + i * 0.34;
      const half = fork * (0.35 + t * 0.6);
      const along = TAIL_BASE - tail * t;
      put(along, half, true);
      put(along, -half);
    }
    ctx.stroke();
  }

  // --- the eye ----------------------------------------------------------
  // Small, forward, and the only bright point on the animal. A raptor that is
  // looking at your flock is a different sentence to one that happens to be near.
  const glint = clamp(0.5 + lunge * 0.5, 0, 1);
  ctx.fillStyle = rgba(mix(v.paint.speck, WARN, lunge * 0.75), glint);
  ctx.beginPath();
  const eye = at(NOSE - 0.02, 0.5);
  ctx.arc(eye[0], eye[1], 1.2 + lunge * 0.5, 0, TAU);
  ctx.fill();

  // --- the air it tears on the way down ---------------------------------
  if (lunge > 0.02) {
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(mix(v.paint.speck, WARN, 0.4), lunge * 0.2);
    ctx.lineWidth = 1 + lunge * 1.4;
    ctx.beginPath();
    for (const side of [1, -1] as const) {
      put(wTrail[2]!, side * wAcross[2]!, true);
      put(wTrail[2]! - 0.5 - lunge * 0.8, side * wAcross[2]! * 1.15);
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
  }
}
