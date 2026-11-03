import { TAU, clamp } from '../core/math';
import { mix, rgba, type Rgb, type ZonePaint } from './Paint';

/**
 * Slowblue: the thing that hunts you, drawn as an animal.
 *
 * It used to be a six-point wedge with a red outline and a red disc round it, which
 * is a hazard marker: the player read "danger, radius 88px" and never once read
 * "there is a shark in the water". That is a bad trade in a game whose entire pitch
 * is that the ocean is a place. A predator is the only antagonist in the campaign and
 * the only thing in it with intent, so it gets a real silhouette from directly above:
 * pointed snout, widest at the pectorals, a narrow peduncle, and a lunate tail with a
 * long upper lobe - the outline you recognise from a photograph taken from a boat.
 *
 * What it does *not* get is a new colour. Red was doing the work of shape; now the
 * shape does that work, and the warm signal is spent only on the two things the
 * player has to react to: how close the mouth is, and whether it is committing.
 *
 * The threat field is two rings, not one wash:
 *   - a soft shadow out at sensing distance, which is dread, and
 *   - a thin bright arc at the distance a strike actually lands, which is a rule.
 * Hiding either one turns a readable hazard into a slot machine.
 */

export interface HunterView {
  ctx: CanvasRenderingContext2D;
  paint: ZonePaint;
  /** The level's accent, so the eye and the lunge rim belong to this water. */
  accent: Rgb;
  time: number;
  quality: number;
}

/** The one warm colour a hunter is allowed. Used on arcs and on a committed body. */
const WARN: Rgb = [255, 104, 92];
/** Threat wash radius, as a multiple of body size. Matches the old bubble. */
const DREAD = 5.5;
/**
 * Strike radius, as a multiple of body size. `PredatorSystem.BITE_REACH` is 1.5;
 * the drawn arc sits a hair outside it so the line is visible rather than exactly
 * on the frame where an individual is already gone.
 */
const STRIKE = 1.9;
/** Body length and width as multiples of size. */
const LEN = 2.15;
const WID = 0.62;
/** Phase lag down the spine: what makes the flex a travelling wave. */
const LAG = 2.2;

/** Half-widths sampled nose (0) to tail base (1), as fractions of the half-width. */
const PROFILE = [0.1, 0.44, 0.5, 0.28, 0.1] as const;
const SPINE = [0, 0.18, 0.42, 0.68, 1] as const;
const NOSE = 0.66;
const TAIL_BASE = -0.34;
const TAIL = 0.4;

export function drawThreat(
  v: HunterView,
  x: number,
  y: number,
  size: number,
  lunge: number,
): void {
  const ctx = v.ctx;
  const dread = size * DREAD;

  // Dread reads as the water going out, not as a light coming on. A predator darkens
  // its own patch of ocean; the shoal stays the brightest thing on screen, which is
  // the only way this can be added without competing with the fish.
  const shade = ctx.createRadialGradient(x, y, size * 1.2, x, y, dread);
  shade.addColorStop(0, rgba(WARN, 0.05 + lunge * 0.07));
  shade.addColorStop(0.55, `rgba(24,2,8,${(0.1 + lunge * 0.08).toFixed(3)})`);
  shade.addColorStop(1, 'rgba(24,2,8,0)');
  ctx.fillStyle = shade;
  ctx.beginPath();
  ctx.arc(x, y, dread, 0, TAU);
  ctx.fill();

  // The strike distance: dashed, turning, and it tightens visibly when the hunter
  // commits. This is the one piece of the old red circle worth keeping, moved in to
  // where it tells the truth.
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

  // ...and the outer boundary of the dread, as one thin ring so the wash has an edge
  // to be read against on a bright palette.
  ctx.strokeStyle = rgba(WARN, 0.05 + lunge * 0.06);
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(x, y, dread, 0, TAU);
  ctx.stroke();
}

/**
 * One hunter. `dx,dy` is its unit heading; `beat` drives the spine wave, so a
 * cruising hunter and a committed one are visibly doing different things with their
 * bodies rather than just moving at different speeds.
 */
export function drawHunter(
  v: HunterView,
  x: number,
  y: number,
  dx: number,
  dy: number,
  size: number,
  lunge: number,
  beat: number,
): void {
  const ctx = v.ctx;
  const len = size * LEN;
  const wid = size * WID;
  const nx = -dy;
  const ny = dx;
  // A big fish is stiff. It flexes less than a dart and sweeps its tail slower, and
  // it stiffens further as it commits - the last metre of a strike is a straight line.
  const swim = 0.3 * (1 - lunge * 0.45);

  const at = (along: number, across: number): [number, number] => [
    x + dx * along * len + nx * across * wid,
    y + dy * along * len + ny * across * wid,
  ];
  const flex = (s: number): number => swim * Math.pow(s, 1.5) * Math.sin(beat - s * LAG);

  const body = (): void => {
    ctx.beginPath();
    const noseFlex = flex(0);
    ctx.moveTo(...at(NOSE, noseFlex + PROFILE[0]!));
    for (let i = 1; i < SPINE.length; i++) {
      const s = SPINE[i]!;
      ctx.lineTo(...at(NOSE - s, flex(s) + PROFILE[i]!));
    }
    // Lunate tail: the upper lobe is markedly longer than the lower one. That
    // asymmetry is most of what makes the silhouette read as a fast open-water
    // predator rather than as a big version of the fish it is chasing.
    const tip = TAIL_BASE - TAIL;
    const tipFlex = flex(1.3);
    ctx.lineTo(...at(tip - TAIL * 0.22, tipFlex + 1.5));
    ctx.lineTo(...at(TAIL_BASE - TAIL * 0.3, flex(1.05)));
    ctx.lineTo(...at(tip, tipFlex - 1.15));
    for (let i = SPINE.length - 1; i >= 1; i--) {
      const s = SPINE[i]!;
      ctx.lineTo(...at(NOSE - s, flex(s) - PROFILE[i]!));
    }
    ctx.lineTo(...at(NOSE, noseFlex - PROFILE[0]!));
    ctx.closePath();
  };

  // --- cast shadow -------------------------------------------------------
  // Offset down the course, i.e. behind the light the whole level is lit by. It is
  // what puts the animal above the water column instead of in the same plane as it.
  if (v.quality > 0.55) {
    ctx.save();
    ctx.translate(dx * -2 + 1.5, dy * -2 + 4);
    body();
    ctx.fillStyle = 'rgba(0,0,0,0.34)';
    ctx.fill();
    ctx.restore();
  }

  // --- body --------------------------------------------------------------
  // Dark, but never black: a silhouette that reads as a hole in the water is the
  // mistake the old wedge made, and the deep palettes are almost black already, so the
  // body is lifted toward the rock's *rim* colour rather than toward its shadow.
  const dark = mix(mix(v.paint.rock, v.paint.rockRim, 0.42), [3, 2, 6], 0.34);
  const flank = ctx.createLinearGradient(
    x - nx * wid * 1.6,
    y - ny * wid * 1.6,
    x + nx * wid * 1.6,
    y + ny * wid * 1.6,
  );
  // Countershading, the way it looks from above: the back is nearly black and the
  // flank picks up a little of the water, so the body has a roll to it.
  flank.addColorStop(0, rgba(mix(dark, v.paint.speck, 0.3), 1));
  flank.addColorStop(0.5, rgba(dark, 1));
  flank.addColorStop(1, rgba(mix(dark, [0, 0, 0], 0.55), 1));
  body();
  ctx.fillStyle = flank;
  ctx.fill();

  // Rim: cool while it cruises, warm the instant it commits. One stroke, two moods.
  ctx.strokeStyle = rgba(
    mix(mix(v.paint.speck, v.accent, 0.4), WARN, lunge),
    0.4 + lunge * 0.5,
  );
  ctx.lineWidth = 1.1 + lunge * 0.9;
  ctx.stroke();

  if (v.quality > 0.5) {
    // --- fins ------------------------------------------------------------
    // Pectorals swept back from the widest part of the body, and a dorsal seen edge
    // on: from directly above a dorsal fin is a slim dark lens on the spine, and
    // that lens is the single most recognisable mark on the animal.
    ctx.fillStyle = rgba(mix(dark, [0, 0, 0], 0.35), 0.95);
    ctx.beginPath();
    const root = flex(SPINE[2]!);
    for (const side of [1, -1] as const) {
      ctx.moveTo(...at(NOSE - SPINE[2]!, root + PROFILE[2]! * 0.85 * side));
      ctx.lineTo(...at(NOSE - SPINE[2]! - 0.34, root + (PROFILE[2]! + 1.35) * side));
      ctx.lineTo(...at(NOSE - SPINE[2]! - 0.46, root + PROFILE[3]! * 1.1 * side));
      ctx.closePath();
    }
    const dorsalRoot = flex(0.5);
    ctx.moveTo(...at(NOSE - 0.4, dorsalRoot));
    ctx.lineTo(...at(NOSE - 0.62, dorsalRoot + 0.2));
    ctx.lineTo(...at(NOSE - 0.86, dorsalRoot));
    ctx.lineTo(...at(NOSE - 0.62, dorsalRoot - 0.2));
    ctx.closePath();
    ctx.fill();

    // --- the spine --------------------------------------------------------
    // One pale line down the middle of the back. It is what stops a dark body from
    // reading as a gap in the water, and it flexes with everything else.
    ctx.strokeStyle = rgba(mix(v.paint.speck, v.accent, 0.35), 0.17 + lunge * 0.22);
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let i = 0; i < SPINE.length; i++) {
      const s = SPINE[i]!;
      const p = at(NOSE - s * 1.04, flex(s));
      if (i === 0) ctx.moveTo(p[0], p[1]);
      else ctx.lineTo(p[0], p[1]);
    }
    ctx.stroke();

    // --- gill slits -------------------------------------------------------
    ctx.strokeStyle = rgba(mix(dark, [0, 0, 0], 0.6), 0.7);
    ctx.lineWidth = 0.9;
    ctx.beginPath();
    for (let i = 0; i < 3; i++) {
      const s = 0.26 + i * 0.07;
      const half = PROFILE[1]! * 0.78;
      ctx.moveTo(...at(NOSE - s, flex(s) + half));
      ctx.lineTo(...at(NOSE - s - 0.05, flex(s) + half * 0.55));
    }
    ctx.stroke();
  }

  // --- the eye -----------------------------------------------------------
  // Small, and the only bright point on the animal. A predator that is looking at
  // your shoal is a different sentence to a predator that happens to be nearby.
  const glint = clamp(0.45 + lunge * 0.55, 0, 1);
  ctx.fillStyle = rgba(mix(v.paint.speck, WARN, lunge * 0.7), glint);
  ctx.beginPath();
  const eye = at(NOSE - 0.18, flex(0.18) + PROFILE[1]! * 0.72);
  ctx.arc(eye[0], eye[1], 1.3 + lunge * 0.5, 0, TAU);
  ctx.fill();

  // --- the wake it leaves when it commits ---------------------------------
  if (lunge > 0.02) {
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(mix(v.paint.speck, WARN, 0.45), lunge * 0.22);
    ctx.lineWidth = 1 + lunge * 1.6;
    ctx.beginPath();
    for (const side of [1, -1] as const) {
      const from = at(TAIL_BASE - TAIL * 0.4, side * 0.8);
      const to = at(TAIL_BASE - TAIL * 1.9 - lunge * 0.7, side * 1.9);
      ctx.moveTo(from[0], from[1]);
      ctx.lineTo(to[0], to[1]);
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
  }
}
