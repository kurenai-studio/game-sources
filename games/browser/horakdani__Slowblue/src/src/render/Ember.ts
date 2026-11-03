import { TAU, clamp } from '../core/math';
import { mix, rgba, type Rgb, type ZonePaint } from './Paint';

/**
 * Slowblue: the thing that hunts you at two hundred kilometres, and it is not alive.
 *
 * Act V needed a threat and had two to borrow from, and both of them are animals.
 * A pelagic shark at the Karman line is the exact mistake act II was rebuilt to
 * undo - the water's clothes on somebody else's sky - and a falcon in vacuum is
 * the same mistake wearing feathers. Nothing hunts up here. Nothing *lives* up
 * here.
 *
 * What is up here is the vehicle, coming apart. A fragment with a worse
 * mass-to-area ratio than the swarm has ablates more slowly, sheds less speed,
 * and therefore comes up on the swarm from behind with the air in front of it
 * already white. It is not chasing anything. It is simply on a slightly better
 * trajectory than you are, and it is on fire.
 *
 * Everything about the three is parallel and nothing is shared:
 *
 * | | the hunter | the raptor | the ember |
 * | --- | --- | --- | --- |
 * | body | a spine carrying a travelling wave | a rigid airframe | a shard that tumbles |
 * | steers by | swimming | flying | **nothing. It cannot steer** |
 * | threat field | the water going dark round it | its shadow, crossing yours | its own light, and the soot |
 * | commitment | the body *stiffens* | the wings **fold** | the shock cap **goes white** |
 *
 * The last two rows are the file. A shark and a falcon are both *deciding*, and
 * the whole craft of drawing them is drawing the decision. A fragment decides
 * nothing - so its commit tell is not a posture, it is **physics**: the air piled
 * up in front of it brightens as it comes into the swarm's own wake, and that is
 * the half-second of warning the player gets. It is also the only predator in the
 * campaign that is *brighter* than what is around it, which is the one honest way
 * to be legible against both the night side's black and the plasma's white.
 */

export interface EmberView {
  ctx: CanvasRenderingContext2D;
  paint: ZonePaint;
  /** The station's accent, so the fire belongs to this altitude. */
  accent: Rgb;
  time: number;
  quality: number;
}

/** The warm signal all three predators share. See `Hunter.ts`. */
const WARN: Rgb = [255, 104, 92];
/** The hot end of the fire: the shock cap and the core of the wake. */
const HOT: Rgb = [255, 226, 186];
/** Soot. What ablation actually leaves behind, and the ember's dark half. */
const SOOT: Rgb = [26, 16, 18];
/** Threat radius, as a multiple of body size. The same 5.5 as the other two. */
const DREAD = 5.5;
/**
 * Strike radius, as a multiple of body size. `PredatorSystem.BITE_REACH` is 1.5;
 * the drawn arc sits a hair outside it, exactly as the hunter's and the raptor's
 * do - the range of the thing that takes your carriers is information the player
 * is owed, and act V does not get to be the act that hides it.
 */
const STRIKE = 1.9;
/** Body half-length and half-width as multiples of size. A shard, not a body. */
const LEN = 1.35;
const WID = 1.05;
/** Turns per second of tumble. Slow: this is a panel, not a spark. */
const TUMBLE = 0.19;

/**
 * The shard, as one closed outline in its own frame.
 *
 * One silhouette for every ember in the game, and that is deliberate. The
 * variety comes from the tumble - each fragment carries its own phase, so no two
 * are ever at the same angle - and a second outline would buy nothing at the
 * fifteen pixels these are actually seen at. The shape is a torn structural
 * panel: three long straight edges that used to be a join, and one ragged run
 * where it came away from whatever it was bolted to.
 */
const SHARD: readonly (readonly [number, number])[] = [
  [1, 0.12],
  [0.42, 0.86],
  [-0.28, 1],
  [-0.86, 0.5],
  [-1, -0.16],
  [-0.54, -0.72],
  [-0.1, -0.62],
  [0.34, -0.9],
  [0.8, -0.54],
];

/**
 * The threat field.
 *
 * The hunter darkens its water because fear underwater is the room closing; the
 * raptor casts a shadow because that is what actually reaches a bird first. Up
 * here neither is available - there is no room and there is no light to block -
 * so what arrives first is **the heat and the soot**, in that order: a warm core
 * on the fragment itself and a dirty ring outside it where the ablation trail has
 * spread. It reads as a bright thing on the night side and as a dark ring in the
 * plasma, which is the whole reason it is drawn as both at once.
 */
export function drawEmberThreat(
  v: EmberView,
  x: number,
  y: number,
  size: number,
  lunge: number,
): void {
  const ctx = v.ctx;
  const dread = size * DREAD;

  const heat = ctx.createRadialGradient(x, y, size * 0.8, x, y, dread);
  heat.addColorStop(0, rgba(mix(WARN, HOT, 0.35 + lunge * 0.4), 0.16 + lunge * 0.16));
  // The soot. It is what makes this legible against a white sky, and it is the
  // only part of act V's threat that is not made of light.
  heat.addColorStop(0.52, rgba(SOOT, 0.13 + lunge * 0.1));
  heat.addColorStop(1, rgba(SOOT, 0));
  ctx.fillStyle = heat;
  ctx.beginPath();
  ctx.arc(x, y, dread, 0, TAU);
  ctx.fill();

  const strike = size * STRIKE * (1 + lunge * 0.12);
  ctx.save();
  ctx.setLineDash([4, 9]);
  ctx.lineDashOffset = -v.time * 7.2;
  ctx.strokeStyle = rgba(mix(WARN, HOT, lunge * 0.6), 0.18 + lunge * 0.44);
  ctx.lineWidth = 1 + lunge * 1.2;
  ctx.beginPath();
  ctx.arc(x, y, strike, 0, TAU);
  ctx.stroke();
  ctx.restore();
}

/**
 * One ember. `dx,dy` is its unit heading, `lunge` 0..1 is how hot the shock cap
 * in front of it has got, and `beat` carries the tumble - which is the one thing
 * on this drawing that is *not* tied to the heading, because a fragment's
 * attitude and its trajectory have nothing to do with each other.
 */
export function drawEmber(
  v: EmberView,
  x: number,
  y: number,
  dx: number,
  dy: number,
  size: number,
  lunge: number,
  beat: number,
): void {
  const ctx = v.ctx;
  const detail = v.quality > 0.5;

  // The tumble runs at a constant rate and never stops. It would be a better
  // *tell* if it slowed on the strike - that is what the other two silhouettes
  // do with their bodies - and it would be a lie: nothing is steering this, so
  // nothing can settle it. What brightens instead is the air.
  const spin = beat * TUMBLE;
  const tx = Math.cos(spin);
  const ty = Math.sin(spin);
  const len = size * LEN;
  const wid = size * WID;
  const at = (along: number, across: number): [number, number] => [
    x + tx * along * len - ty * across * wid,
    y + ty * along * len + tx * across * wid,
  ];

  const shard = (): void => {
    ctx.beginPath();
    for (let i = 0; i < SHARD.length; i++) {
      const p = at(SHARD[i]![0], SHARD[i]![1]);
      if (i === 0) ctx.moveTo(p[0], p[1]);
      else ctx.lineTo(p[0], p[1]);
    }
    ctx.closePath();
  };

  // --- the wake ----------------------------------------------------------
  // Behind the *heading*, not behind the body. A tumbling fragment leaves its
  // trail on the trajectory it is on, and drawing the two out of alignment is
  // most of what makes this read as debris rather than as an animal.
  if (v.quality > 0.4) {
    const tail = size * (5.5 + lunge * 5);
    const wake = ctx.createLinearGradient(x, y, x - dx * tail, y - dy * tail);
    wake.addColorStop(0, rgba(mix(WARN, HOT, 0.5), 0.4 + lunge * 0.3));
    wake.addColorStop(0.35, rgba(WARN, 0.16 + lunge * 0.14));
    wake.addColorStop(1, rgba(mix(WARN, SOOT, 0.7), 0));
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = wake;
    ctx.beginPath();
    const half = size * (0.85 + lunge * 0.25);
    ctx.moveTo(x - dy * half, y + dx * half);
    ctx.lineTo(x + dy * half, y - dx * half);
    // A trail that tapers to a point reads as a comet; one that tapers to a
    // narrow band and then stops reads as something burning up, which is the
    // difference between a decoration and the fiction this act is made of.
    ctx.lineTo(x - dx * tail + dy * half * 0.22, y - dy * tail - dx * half * 0.22);
    ctx.lineTo(x - dx * tail - dy * half * 0.22, y - dy * tail + dx * half * 0.22);
    ctx.closePath();
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  // --- the shock cap: the commit tell ------------------------------------
  // Air piled up in front of a blunt body, and the only warning the player gets.
  // It is an arc rather than a fill because the gap between the cap and the
  // fragment is the single thing that says "this is going fast" - a stand-off
  // distance is what a bow shock *is*.
  const stand = size * (0.95 + lunge * 0.35);
  ctx.strokeStyle = rgba(mix(WARN, HOT, 0.3 + lunge * 0.7), 0.3 + lunge * 0.62);
  ctx.lineWidth = 1.2 + lunge * 2.6;
  ctx.beginPath();
  const facing = Math.atan2(dy, dx);
  ctx.arc(x + dx * stand * 0.25, y + dy * stand * 0.25, stand, facing - 1.05, facing + 1.05);
  ctx.stroke();

  // --- the body -----------------------------------------------------------
  // Dark, and dark on purpose. Everything else in this act's peak station is
  // white-hot, so a threat made of light would disappear into the frame it is
  // most dangerous in. What burns is the rim.
  const dark = mix(mix(v.paint.rock, SOOT, 0.55), v.paint.rockRim, 0.18);
  const face = ctx.createLinearGradient(
    x + dx * size * 1.2,
    y + dy * size * 1.2,
    x - dx * size * 1.2,
    y - dy * size * 1.2,
  );
  // The leading face is the one being eaten, so it is the lit one - and which
  // face that is changes as the shard tumbles, which is the whole animation.
  face.addColorStop(0, rgba(mix(dark, WARN, 0.45 + lunge * 0.25), 1));
  face.addColorStop(0.45, rgba(dark, 1));
  face.addColorStop(1, rgba(mix(dark, [0, 0, 0], 0.4), 1));
  shard();
  ctx.fillStyle = face;
  ctx.fill();

  ctx.strokeStyle = rgba(mix(mix(v.paint.speck, v.accent, 0.35), HOT, 0.35 + lunge * 0.5), 0.5 + lunge * 0.4);
  ctx.lineWidth = 1 + lunge * 0.8;
  ctx.stroke();

  if (detail) {
    // --- the tear -------------------------------------------------------
    // One bright line across the shard, from the ragged corner to the far edge.
    // It is where it came away from the airframe, and it is the mark that stops
    // a dark polygon from reading as a hole punched in the sky.
    ctx.strokeStyle = rgba(mix(WARN, HOT, 0.4), 0.34 + lunge * 0.3);
    ctx.lineWidth = 1;
    ctx.beginPath();
    const a = at(-0.1, -0.62);
    const b = at(0.42, 0.86);
    ctx.moveTo(a[0], a[1]);
    ctx.lineTo(b[0], b[1]);
    ctx.stroke();

    // --- what it is shedding ---------------------------------------------
    // Three short streaks coming off the trailing corners, on the heading
    // again. Ablation is the fragment being taken apart, and it is the reason
    // this hazard is temporary in a way the hunter never was - `Predator.burn`
    // takes the body apart at a constant rate, so everything on this drawing
    // shrinks with it and the thing visibly stops being able to reach you.
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(mix(WARN, HOT, 0.55), 0.2 + lunge * 0.28);
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let i = 0; i < 3; i++) {
      const off = ((beat * 0.9 + i * 0.37) % 1);
      const side = (i - 1) * 0.7;
      const from = at(-0.9 + side * 0.2, side);
      const run = size * (1.6 + off * 3.4);
      ctx.moveTo(from[0], from[1]);
      ctx.lineTo(from[0] - dx * run, from[1] - dy * run);
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
  }

  // --- the hot point ------------------------------------------------------
  // The stagnation point: the one place on a re-entering body that is properly
  // white, and this silhouette's answer to the other two animals' eye. It is not
  // looking at anything, which is exactly why it is on the leading edge rather
  // than on the shard - it moves as the fragment tumbles under it.
  const glint = clamp(0.45 + lunge * 0.55, 0, 1);
  ctx.fillStyle = rgba(mix(HOT, [255, 255, 255], lunge * 0.7), glint);
  ctx.beginPath();
  ctx.arc(x + dx * size * 0.55, y + dy * size * 0.55, 1.3 + lunge * 1.1, 0, TAU);
  ctx.fill();
}
