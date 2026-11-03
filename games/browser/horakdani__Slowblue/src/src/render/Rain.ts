import { TAU } from '../core/math';
import type { BackdropView } from './Backdrop';
import type { Motif } from './Motif';
import { mix, rgba, type Rgb } from './Paint';
import { bank, hash, wrapY } from './SkyParts';

/**
 * Slowblue: act VI's six frames - coming down through the weather.
 *
 * The whole render layer has been drawing *away* for five acts. This is the one
 * that arrives, and everything in it is built on a single inversion that the
 * player never has to be told about.
 *
 * **The detail is ahead again.** Acts II to V put their scenery behind the swarm,
 * because the ground was the thing receding. Here the ground is the destination,
 * so the busy plane is at the **bottom** of the frame and rises through every
 * station - cloud base, then rain, then treetops, then the bed of a stream. By
 * the estuary the whole lower half of the picture is a place rather than a
 * distance, which is what having arrived looks like.
 *
 * **Everything falls.** The rain, the snow, the leaves and the swarm all move the
 * same way down the frame, and that shared direction is the act's entire visual
 * argument: for six acts the world went past the player, and now the player is
 * going with it.
 */

export function drawRain(kind: string, motif: Motif, v: BackdropView): void {
  if (v.alpha < 0.01) return;
  switch (kind) {
    case 'cirrusFall':
      return cirrusFall(motif, v);
    case 'underanvil':
      return underanvil(motif, v);
    case 'downpour':
      return downpour(motif, v);
    case 'canopyFall':
      return canopyFall(motif, v);
    case 'brook':
      return brook(motif, v);
    case 'estuary':
      return estuary(motif, v);
  }
}

/**
 * Falling rain, shared by the three stations that have any.
 *
 * `rate` is how hard it is coming down and `lean` how much wind is in it. It is
 * drawn *down* the frame, which is the same direction the swarm is going - the
 * exact opposite of act II's squall, where the rain fell past a climbing flock
 * and that opposition was the point. Here they agree, and that is also the point.
 */
function rainfall(v: BackdropView, rate: number, lean: number, colour: Rgb, alpha: number): void {
  const ctx = v.ctx;
  if (v.quality <= 0.5) return;
  const t = v.time;
  ctx.globalCompositeOperation = 'lighter';
  ctx.strokeStyle = rgba(colour, alpha * v.alpha);
  ctx.lineWidth = 1;
  ctx.beginPath();
  const drops = Math.round(60 * rate);
  for (let i = 0; i < drops; i++) {
    const h = hash(i * 89);
    const x = ((hash(i * 17) + t * 0.004 * lean) % 1.2 - 0.1) * v.w;
    /*
     * Falling with the swarm rather than against it, so the whole frame reads as
     * one descent. Nearer drops are longer and faster.
     *
     * Slowblue: `wrapY` subtracts `cameraY * rate`, so on a falling course a positive
     * rate carries an element *up* the screen - rate 1 is an element standing
     * still in the world, which the camera then falls past. This was +1.6 to
     * +3.8, i.e. rain streaming upward, three times faster than the water, in the
     * act called The Rain. A drop has to out-fall the camera, and the sign of
     * that is negative.
     */
    const y = wrapY(v, i, v.h * 0.14, -(0.6 + h * 1.2 * rate));
    const len = (10 + h * 26) * rate;
    ctx.moveTo(x, y);
    ctx.lineTo(x + lean * (3 + h * 5), y + len);
  }
  ctx.stroke();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 1. Cirrus, falling through it.
 *
 * The last ice in the campaign, and the last frame with the sky above it. It is
 * built as the mirror of act III's jet stream on purpose - the same streaked
 * crystal at the same altitude - except that the haze is now *below* and rising,
 * because the swarm is going into it rather than out of it.
 *
 * Slowblue: and for its whole life the mirror was missing the half that has anything
 * in it.
 *
 * `jet` is a floor gradient, a sky gradient, the last anvil as a `bank` and a
 * field of shear lines. This was the same function with the anvil deleted, and
 * what is left of it is two vertical gradients - which have no horizontal spread
 * along a row by construction - plus nine hairlines. Measured on the play field,
 * the middle third read **0.92** at the opening and 1.09 at the late image, in an
 * act where the next emptiest station reads 3.86 and the canopy reads 20.5. That
 * number belongs to the vacuum: the deorbit reads 0.80 and the salt line 0.74,
 * and *those* are stations whose subject is that there is nothing there. This one
 * is named after a cloud.
 *
 * Averaged over five frames a second apart, which is the honest way to read a
 * field that drifts, the four sections were 1.33, 2.83, 2.56 and 1.14 and they
 * are 1.38, 2.89, 2.97 and 1.86 now. The gain is small and it is nearly all in
 * the station's second half, because that is where the anvil has risen far enough
 * to be in the middle third at all - a hooked filament is two pixels of line
 * however long its tail is, and it moves this number far less than it moves the
 * picture.
 *
 * It is also the wrong way up for the act it opens. The file's own rule two
 * screens above is that the busy plane is at the bottom and rises through every
 * station; this read 5.73 at the top against 3.43 at the bottom, the only station
 * in act VI that is heaviest where the sky is.
 *
 * So two things, and the second is the one that matters. The anvil comes back,
 * because the mirror needs it and because the cloud this station is falling
 * toward is the one the *next* station is underneath - the campaign setting up a
 * recognition one frame before it happens. And the ice stops being a ruled line:
 * cirrus at this height is *uncinus*, hooked, ice falling out of the streak and
 * being dragged behind it, which is the shape the word means and the only thing
 * in the frame that can put anything in the middle of it.
 */
function cirrusFall(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const white = mix(v.paint.speck, motif.crest, 0.3);
  const cold = mix(v.paint.top, motif.base, 0.4);

  // The last of the empty sky, above and going.
  const space = ctx.createLinearGradient(0, 0, 0, v.h * 0.5);
  space.addColorStop(0, rgba(cold, (0.45 - v.progress * 0.3) * v.alpha));
  space.addColorStop(1, rgba(cold, 0));
  ctx.fillStyle = space;
  ctx.fillRect(0, 0, v.w, v.h * 0.5);

  // The weather below, rising to meet the swarm across the station.
  const deckY = v.h * (0.86 - v.progress * 0.3);
  const floor = ctx.createLinearGradient(0, deckY - v.h * 0.2, 0, v.h);
  floor.addColorStop(0, rgba(white, 0));
  floor.addColorStop(1, rgba(white, 0.4 * v.alpha));
  ctx.fillStyle = floor;
  ctx.fillRect(0, deckY - v.h * 0.2, v.w, v.h - deckY + v.h * 0.2);

  // The anvil the next station is under, from above and a long way down, sitting
  // on the haze rather than at a fixed height in the frame. `jet` draws the last
  // one of these at the same altitude going the other way, which is what makes
  // the two stations a mirror rather than two pictures of empty sky.
  if (v.quality > 0.55) {
    // On the haze line rather than under it, so it rises into the middle of the
    // frame as the station goes on - which is the one thing in this picture that
    // is genuinely coming up to meet the swarm. Set 0.12h lower first and the
    // opening frame had it off the bottom of the screen entirely.
    bank(v, v.w * 0.44, deckY + v.h * 0.02, v.w * 1.15, white, 0.13, 5, 0.16);
  }

  ctx.globalCompositeOperation = 'lighter';
  // Streaked ice: cirrus at this height is being dragged, and it streaks.
  ctx.lineCap = 'round';
  for (let i = 0; i < (v.quality > 0.55 ? 9 : 5); i++) {
    const h = hash(i * 29);
    const y = wrapY(v, i, v.h * 0.32, 0.16 + h * 0.1);
    if (y < -20 || y > v.h + 20) continue;
    const slide = t * 22 * (i % 2 === 0 ? 1 : -1) * (0.5 + h);
    const len = v.w * (0.3 + h * 0.5);
    const x = (((slide + h * v.w * 2) % (v.w + len * 2)) + v.w + len * 2) % (v.w + len * 2) - len;
    const dir = i % 2 === 0 ? 1 : -1;
    ctx.strokeStyle = rgba(white, (0.05 + h * 0.06) * v.alpha);
    ctx.lineWidth = 0.8 + h * 2;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(x + len * 0.5, y + (h - 0.5) * 8, x + len, y);
    /*
     * The fallstreaks, and they are the whole reason this station has a middle.
     *
     * Ice that leaves a cirrus filament does not fall straight: it drops into
     * slower air and gets left behind, so it hangs off the streak as a comma with
     * its tail pointing *back* along the drift. That is what `uncinus` names and
     * why the old picture read wrong for a reason the numbers found first - a
     * horizontal line a couple of pixels thick occupies two rows of the frame,
     * and the middle third of this station is a hundred and ninety of them.
     *
     * Three per streak, on the same path and the same stroke, so nine streaks
     * still cost nine strokes. They hang a fifth of a screen at most, which is
     * the shallow end of what real fallstreaks do - this is the quietest frame in
     * the act and the ice is not allowed to become weather.
     */
    for (let k = 0; k < 3; k++) {
      const g = hash(i * 29 + k * 7);
      const at = x + len * (0.24 + k * 0.28 + g * 0.12);
      const drop = v.h * (0.06 + g * 0.13);
      ctx.moveTo(at, y + (h - 0.5) * 4);
      // Away from the spine first, then back under it: the tail lags the head
      // because the air below is slower, which is the only reason the shape
      // exists at all.
      ctx.quadraticCurveTo(at - dir * len * 0.06, y + drop * 0.6, at - dir * len * 0.16, y + drop);
    }
    ctx.stroke();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 2. The anvil, from underneath.
 *
 * The quietest idea in the campaign's second half: this is the same cloud act II
 * climbed over, and the player flew across the top of it forty minutes ago and
 * has been to space since. Nothing marks the moment.
 *
 * What makes it read as *underneath* rather than as another cloud station is the
 * light. An anvil seen from below is lit from behind - the sun is on the other
 * side of several kilometres of ice - so the base is dark, the edges are bright,
 * and the one thing you can see clearly is the mamma: the hanging pouches on its
 * underside that only ever form there, and which are the surest sign in the sky
 * that you are under a storm rather than beside one.
 */
function underanvil(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const dark = mix(v.paint.top, motif.base, 0.5);
  const rim = mix(v.paint.speck, motif.crest, 0.35);

  // The ceiling: the underside of the sheet, filling the top of the frame and
  // sinking as the swarm falls away from it.
  const baseY = v.h * (0.12 + v.progress * 0.26);
  const ceiling = ctx.createLinearGradient(0, 0, 0, baseY + v.h * 0.2);
  ceiling.addColorStop(0, rgba(dark, 0.72 * v.alpha));
  ceiling.addColorStop(0.7, rgba(dark, 0.4 * v.alpha));
  ceiling.addColorStop(1, rgba(dark, 0));
  ctx.fillStyle = ceiling;
  ctx.fillRect(0, 0, v.w, baseY + v.h * 0.2);

  // Mamma: the pouches that hang under an anvil and nowhere else. Drawn as a row
  // of soft lobes along the base, each lit on its lower edge by the light coming
  // in underneath the storm.
  if (v.quality > 0.5) {
    for (let i = 0; i < 7; i++) {
      const h = hash(i * 47);
      const x = ((i + 0.5) / 7) * v.w + Math.sin(i * 2.1) * v.w * 0.03;
      const r = v.w * (0.07 + h * 0.05);
      const y = baseY + r * 0.3;
      ctx.fillStyle = rgba(dark, 0.35 * v.alpha);
      ctx.beginPath();
      ctx.ellipse(x, y, r, r * 0.8, 0, 0, TAU);
      ctx.fill();
      ctx.fillStyle = rgba(rim, 0.09 * v.alpha);
      ctx.beginPath();
      ctx.ellipse(x, y + r * 0.24, r * 0.8, r * 0.5, 0, 0, TAU);
      ctx.fill();
    }
  }

  // Light coming in under the storm, far off to one side: the one bright thing in
  // the frame, and the reason this reads as weather rather than as a lid.
  ctx.globalCompositeOperation = 'lighter';
  const gapX = v.w * (0.16 + 0.68 * hash(11));
  const bright = ctx.createRadialGradient(gapX, v.h * 0.98, 0, gapX, v.h * 0.98, v.h * 0.7);
  bright.addColorStop(0, rgba(rim, 0.14 * v.alpha));
  bright.addColorStop(1, rgba(rim, 0));
  ctx.fillStyle = bright;
  ctx.fillRect(0, v.h * 0.3, v.w, v.h * 0.7);
  ctx.globalCompositeOperation = 'source-over';

  rainfall(v, 0.4, 1.6, mix(v.paint.tracer, rim, 0.4), 0.1);
}

/**
 * Station 3. The downpour.
 *
 * Out of the bottom of the cloud, and the first backdrop in the game whose lines
 * run the way the course runs. Everything is vertical: the rain, the shafts of
 * lighter air between the curtains, and the swarm. It is the busiest frame in the
 * act and the only loud one, because after this the campaign is quiet to the end.
 */
function downpour(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const grey = mix(v.paint.mid, motif.base, 0.5);
  const wet = mix(v.paint.tracer, motif.accent, 0.35);

  // The cloud base, now above and receding.
  const baseY = v.h * (-0.1 + v.progress * 0.16);
  const ceiling = ctx.createLinearGradient(0, baseY, 0, baseY + v.h * 0.5);
  ceiling.addColorStop(0, rgba(grey, 0.6 * v.alpha));
  ceiling.addColorStop(1, rgba(grey, 0));
  ctx.fillStyle = ceiling;
  ctx.fillRect(0, 0, v.w, baseY + v.h * 0.5);

  // Curtains: broad soft vertical bands at three distances, each drifting at its
  // own rate. This is the same construction act II's squall used, turned upright.
  for (let i = 0; i < (v.quality > 0.55 ? 5 : 3); i++) {
    const h = hash(i * 23);
    const x = ((hash(i * 7) + -v.cameraY * 0.00004 * (1 + h)) % 1.3 - 0.15) * v.w;
    const wide = v.w * (0.12 + h * 0.18);
    const g = ctx.createLinearGradient(x - wide, 0, x + wide, 0);
    g.addColorStop(0, rgba(grey, 0));
    g.addColorStop(0.5, rgba(grey, (0.14 + h * 0.12) * v.alpha));
    g.addColorStop(1, rgba(grey, 0));
    ctx.fillStyle = g;
    ctx.fillRect(x - wide, 0, wide * 2, v.h);
  }

  // The ground, arriving for the first time in the campaign. Very far off, and
  // only in the last third of the station.
  if (v.progress > 0.4) {
    const groundY = v.h * (1.25 - (v.progress - 0.4) * 0.6);
    const g = ctx.createLinearGradient(0, groundY - v.h * 0.15, 0, v.h);
    g.addColorStop(0, rgba(mix(grey, motif.crest, 0.2), 0));
    g.addColorStop(1, rgba(mix(v.paint.bottom, [40, 60, 40], 0.4), 0.5 * v.alpha));
    ctx.fillStyle = g;
    ctx.fillRect(0, groundY - v.h * 0.15, v.w, v.h - groundY + v.h * 0.15);
  }

  rainfall(v, 1, 2.4, wet, 0.22);
}

/**
 * Station 4. The canopy.
 *
 * The first green in the game, and the first ceiling made of something alive.
 * The swarm is inside a forest now: leaves above and closing, trunks going past
 * at the sides, and light coming down through it in the broken columns that only
 * ever happen under a canopy.
 *
 * The shafts are the same `shaft` idea the trench floor's water used, which is
 * the campaign quietly rhyming with itself two acts before it says so.
 */
function canopyFall(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  /*
   * A canopy from underneath is *dark*, and it took looking at the frame to see
   * that this was not.
   *
   * `leaf` used to be mixed out of the background's own mid-tone toward the
   * motif's base, which for a green station means a green a shade off the green
   * behind it: every element in the function drew correctly, at a contrast of
   * about two levels, and the whole station rendered as one flat field. The
   * shafts of light between the leaves are the picture here, and a shaft needs
   * something dark on both sides of it to be a shaft at all.
   */
  const leaf = mix(v.paint.mid, [8, 22, 12], 0.6);
  const lit = mix(v.paint.speck, motif.crest, 0.3);
  const roofY = v.h * (0.06 + v.progress * 0.2);

  /*
   * Light through the leaves: broken columns, leaning, and moving as the canopy
   * moves. The one warm thing in the act.
   *
   * Slowblue: drawn *before* the canopy, and from the top of the frame rather than
   * from the canopy's own line - which is the third orientation of the one defect
   * this campaign keeps finding, and the largest instance of it yet measured.
   *
   * Each column is a `fillRect` filled with a gradient that runs across it: zero
   * at both sides, brightest down the middle, so the two edges everyone learned
   * to check after act V are genuinely edgeless. The rect's *end* is the edge.
   * Nothing about the fill varies down the column, so starting it at `roofY`
   * turned the shaft on at full strength in the space of one pixel, four times
   * over, all four at the same height. Measured on the pixels as a coherent row
   * step of **19.8** units at the opening and **40.9** by the late image, at the
   * exact `roofY` the arithmetic puts it at, against an anvil defect of 14.0 that
   * this campaign called its worst.
   *
   * No pass in the suite could have reported it and it is worth writing down why,
   * because it is the gap the other two leave. `seam` demands that every column in
   * the play field step together, and a shaft is a fifth of the width; `rib` is
   * the same demand turned onto columns. A partial-width row step *was* built and
   * measured during this review and then thrown away: the swarm, the banner rule
   * and every obstacle silhouette in the game read 20 to 80 units on it, so there
   * is no floor that separates a defect from the picture. On top of that the whole
   * defect lived above 0.23h, and the play field starts at 0.25h because the
   * station banner owns the top fifth of the frame for five seconds.
   *
   * The fix is to make the edge impossible rather than to move it. The shaft now
   * starts off the top of the frame, so it has no end in shot at all, and the
   * canopy is painted over it afterwards - a gradient from nine tenths opaque at
   * the top of the frame to nothing a third of a screen below the leaves. That is
   * an attenuation rather than a cut: the light is at a tenth of itself where the
   * roof is thickest and full below it, which is what a shaft through several
   * metres of leaf actually does, and it says the thing the station is about -
   * that a shaft needs something dark around it to be a shaft - on the one side
   * that was still missing it.
   */
  ctx.globalCompositeOperation = 'lighter';
  if (v.quality > 0.5) {
    for (let i = 0; i < 4; i++) {
      const h = hash(i * 61);
      const x = v.w * (0.1 + ((i * 0.29 + h * 0.1) % 0.82));
      const half = v.w * (0.05 + h * 0.05);
      const g = ctx.createLinearGradient(x - half, 0, x + half, 0);
      g.addColorStop(0, rgba(lit, 0));
      // Up from 0.13 + h·0.09: the top third of every column is now under the
      // canopy that used to start below it, and the frame is not allowed to lose
      // its one warm thing to a fix for its edges. Checked rather than assumed -
      // the four sections read 77.1, 76.0, 75.3 and 75.0 mean before and 78.2,
      // 77.0, 76.5 and 76.4 after, and the horizontal spread through the middle
      // third went 19.5, 20.6, 19.7 and 19.4 to 23.6, 24.3, 23.5 and 22.8.
      g.addColorStop(0.5, rgba(lit, (0.16 + h * 0.11) * v.alpha));
      g.addColorStop(1, rgba(lit, 0));
      ctx.save();
      ctx.transform(1, 0, Math.sin(t * 0.08 + i) * 0.12, 1, 0, 0);
      ctx.fillStyle = g;
      ctx.fillRect(x - half, 0, half * 2, v.h);
      ctx.restore();
    }
  }
  ctx.globalCompositeOperation = 'source-over';

  // The canopy overhead, closing as the swarm falls into it - and the thing that
  // now puts the shafts out where the leaves are thickest.
  const roof = ctx.createLinearGradient(0, 0, 0, roofY + v.h * 0.34);
  roof.addColorStop(0, rgba(leaf, 0.9 * v.alpha));
  roof.addColorStop(1, rgba(leaf, 0));
  ctx.fillStyle = roof;
  ctx.fillRect(0, 0, v.w, roofY + v.h * 0.34);

  // Trunks at the edges, far enough off to be scenery. Drawn as soft gradients
  // with no defined edge - the trench floor's rule, and act II's cliff learned it
  // the hard way: a dark shape with a boundary in the play field is an obstacle.
  for (const side of [0, 1] as const) {
    const from = side === 0 ? 0 : v.w;
    const to = side === 0 ? v.w * 0.16 : v.w * 0.84;
    const g = ctx.createLinearGradient(from, 0, to, 0);
    g.addColorStop(0, rgba(leaf, 0.8 * v.alpha));
    g.addColorStop(1, rgba(leaf, 0));
    ctx.fillStyle = g;
    ctx.fillRect(side === 0 ? 0 : v.w * 0.84, 0, v.w * 0.16, v.h);
  }

  /*
   * Leaf litter, falling with the swarm.
   *
   * Slowblue: the third instance of the sign above, and the one the audit missed. At
   * +1.1 to +1.9 this litter climbed the frame at 42 px/s on the station line and
   * 107 px/s by the end of it, while the rain drawn in the same picture fell at
   * 23 to 44 - two particulate layers of one frame moving opposite ways, in the
   * act whose whole argument is that everything falls. A rate above 1 is a near
   * plane going past on purpose (the brook's bed two stations on, at +2.2 to
   * +3.2); detached litter outrunning the canopy it fell from is not. A leaf lags
   * a falling swarm rather than out-falling it, so this is the marine snow's
   * number, not the brook bed's: barely moving on the glass, the swarm easing by.
   */
  if (v.quality > 0.55) {
    ctx.fillStyle = rgba(mix(leaf, lit, 0.45), 0.38 * v.alpha);
    ctx.beginPath();
    for (let i = 0; i < 20; i++) {
      const h = hash(i * 31);
      const y = wrapY(v, i, v.h * 0.2, 0.12 + h * 0.3);
      const x = v.w * hash(i * 13) + Math.sin(t * 0.5 + i) * 14;
      const r = 1.4 + h * 2.4;
      ctx.moveTo(x + r, y);
      ctx.ellipse(x, y, r, r * 0.45, Math.sin(t * 0.9 + i) * 1.2, 0, TAU);
    }
    ctx.fill();
  }

  rainfall(v, 0.5, 1.2, mix(v.paint.tracer, lit, 0.3), 0.1);
}

/**
 * Station 5. The brook.
 *
 * Running water, and the first medium since act I that grips the way water grips.
 * The picture is built on the one thing that makes a stream read as a stream:
 * **the bed goes past faster than anything else in the frame**. Stones under the
 * surface, streaming light on top of it, and banks at both edges that are the
 * first thing since the trench floor to actually close the course in.
 */
function brook(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const bed = mix(v.paint.bottom, motif.base, 0.55);
  const glint = mix(v.paint.speck, motif.crest, 0.35);

  // The banks. Edgeless gradients, both sides, and the narrowest the campaign
  // gets - a brook really is a place with sides.
  for (const side of [0, 1] as const) {
    const from = side === 0 ? 0 : v.w;
    const to = side === 0 ? v.w * 0.22 : v.w * 0.78;
    const g = ctx.createLinearGradient(from, 0, to, 0);
    g.addColorStop(0, rgba(bed, 0.62 * v.alpha));
    g.addColorStop(0.5, rgba(bed, 0.2 * v.alpha));
    g.addColorStop(1, rgba(bed, 0));
    ctx.fillStyle = g;
    ctx.fillRect(side === 0 ? 0 : v.w * 0.78, 0, v.w * 0.22, v.h);
  }

  // The bed: stones under the water, going past fast. The fastest-scrolling
  // plane in the campaign, because it is the closest thing to the camera.
  if (v.quality > 0.5) {
    for (let i = 0; i < 14; i++) {
      const h = hash(i * 53);
      const y = wrapY(v, i, v.h * 0.28, 2.2 + h);
      if (y < -40 || y > v.h + 40) continue;
      const x = v.w * (0.2 + hash(i * 19) * 0.6);
      const r = v.w * (0.03 + h * 0.06);
      ctx.fillStyle = rgba(bed, 0.3 * v.alpha);
      ctx.beginPath();
      ctx.ellipse(x, y, r, r * 0.7, 0, 0, TAU);
      ctx.fill();
    }
  }

  ctx.globalCompositeOperation = 'lighter';
  // Light on the surface: fine streaks running with the flow, and the one thing
  // in the act that says the water itself is moving rather than the swarm.
  ctx.lineCap = 'round';
  ctx.strokeStyle = rgba(glint, 0.14 * v.alpha);
  ctx.lineWidth = 1.2;
  ctx.beginPath();
  for (let i = 0; i < 26; i++) {
    const h = hash(i * 41);
    const y = wrapY(v, i, v.h * 0.16, 2.8 + h * 1.4);
    const x = v.w * (0.16 + hash(i * 11) * 0.68) + Math.sin(t * 0.6 + i) * 6;
    const len = 14 + h * 34;
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(x + (h - 0.5) * 12, y + len * 0.5, x, y + len);
  }
  ctx.stroke();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 6. The estuary.
 *
 * The river opening out, and the last frame of the campaign that has a sky in it.
 * The banks fall away to nothing, the bed drops out of sight, and what comes up
 * from the bottom of the picture is the sea - a wide, slow, blue-green body with
 * no edges in it anywhere.
 *
 * The one detail that carries it is the **salt wedge**: the visible boundary
 * where the fresh water riding on top meets the denser salt water underneath. It
 * is a real thing in every estuary in the world, it is the last horizontal line
 * the campaign draws, and act VII opens on the other side of it.
 */
function estuary(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const salt = mix(v.paint.bottom, motif.base, 0.4);
  const fresh = mix(v.paint.mid, motif.crest, 0.25);

  // The sea below, rising through the station until it is the whole frame.
  const seaY = v.h * (0.68 - v.progress * 0.5);
  const sea = ctx.createLinearGradient(0, seaY - v.h * 0.16, 0, v.h);
  sea.addColorStop(0, rgba(salt, 0));
  sea.addColorStop(1, rgba(salt, 0.6 * v.alpha));
  ctx.fillStyle = sea;
  ctx.fillRect(0, seaY - v.h * 0.16, v.w, v.h - seaY + v.h * 0.16);

  /*
   * Silt in the water, and the plane the estuary did not have.
   *
   * Everything else in this frame hangs off `seaY`, and `seaY` runs from 0.68h to
   * 0.18h - so by the station's own late image the salt wedge, which the
   * paragraph above calls the one detail that carries the picture, has left
   * through the top of it and what is under it is bare gradient. The lower two
   * thirds measured **0.84 and 3.11** of horizontal spread over five frames,
   * against 6.58 and 7.64 at the same station's opening. It is the spray's defect
   * one act on, with the water arriving instead of leaving: the plane goes, and
   * nothing is left that did not depend on it. The middle third reads 1.33 now -
   * short of the 1.45 the spray's own fix landed on, and reported rather than
   * tuned to, because the alternative is a murky frame in the campaign's quietest
   * handover.
   *
   * It also contradicts the one thing this file says at the top about where act VI
   * puts its detail - *by the estuary the whole lower half of the picture is a
   * place rather than a distance* - in the frame that is supposed to be the
   * arrival, and immediately in front of act VII's salt line, which is empty below
   * on purpose. Two adjacent stations cannot both be that.
   *
   * Silt is what is actually there. A river mouth carries its own bed in
   * suspension and the plume of it is the one thing about an estuary that is
   * visible from orbit, so it is neither an invention nor a second subject: it is
   * the river, still in the frame, after the surface has gone. Drawn as radial
   * gradients in a squashed frame rather than as `bank` lumps, because a mass in
   * water has no side to it - the trench floor's rule, and the shape act V's
   * curtains had to be rebuilt into. It thickens with progress, which is what
   * going down into a plume looks like, and it is the only element here that never
   * reads `seaY`.
   */
  if (v.quality > 0.5) {
    const silt = mix(salt, motif.base, 0.45);
    /*
     * Six, a third of a screen apart, and each about half a screen across.
     *
     * Both numbers were measured rather than chosen. Three plumes 0.52h apart left
     * the late image's middle third between two of them and reading 0.97 against a
     * baseline of 0.84 - the defect with a smaller radius. And a plume nearly two
     * screens wide has almost no variation *along* a row, which is the whole of
     * what was missing here: it darkens the water without giving it a shape. Half
     * a screen is wide enough to be one mass and narrow enough to have a side of
     * the frame it is not on.
     */
    for (let i = 0; i < 6; i++) {
      const h = hash(i * 71);
      const y = wrapY(v, i, v.h * 0.32, 0.3 + h * 0.25);
      const wide = v.w * (0.3 + h * 0.3);
      const tall = v.h * (0.1 + h * 0.08);
      // Only ever *in* the water: a plume standing in the air over the wedge
      // would be the storm cells act V hung in vacuum, one act later.
      if (y + tall < seaY) continue;
      const x = v.w * (0.15 + hash(i * 13) * 0.7) + Math.sin(t * 0.09 + i * 2.3) * v.w * 0.05;
      ctx.save();
      ctx.translate(x, y);
      ctx.scale(1, tall / wide);
      const g = ctx.createRadialGradient(0, 0, 0, 0, 0, wide);
      g.addColorStop(0, rgba(silt, (0.13 + h * 0.1 + v.progress * 0.2) * v.alpha));
      g.addColorStop(1, rgba(silt, 0));
      ctx.fillStyle = g;
      ctx.fillRect(-wide, -wide, wide * 2, wide * 2);
      ctx.restore();
    }
  }

  ctx.globalCompositeOperation = 'lighter';
  // The salt wedge: three nearly coincident traces, so it is an interference
  // rather than a rule. The last horizontal line in the campaign.
  ctx.lineCap = 'round';
  for (let band = 0; band < 3; band++) {
    ctx.strokeStyle = rgba(fresh, (0.09 - band * 0.02) * v.alpha);
    ctx.lineWidth = 1.2 + band * 1.6;
    ctx.beginPath();
    for (let x = -12; x <= v.w + 12; x += 10) {
      const y =
        seaY +
        band * 6 +
        Math.sin(x * 0.014 + t * 0.12 + band) * 6 +
        Math.sin(x * 0.005 - t * 0.07) * 9;
      if (x === -12) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }

  // Silt in the fresh water above it, and the first plankton in the salt below -
  // which is the handover, drawn before it happens. Suspended in the water the
  // swarm is riding, so it goes with it: the same near-zero rate as the leaf
  // litter one station back, and for the same reason. This was +0.9 to +1.7, the
  // fourth and last place the sign got away.
  if (v.quality > 0.55) {
    ctx.fillStyle = rgba(mix(fresh, motif.accent, 0.4), 0.16 * v.alpha);
    ctx.beginPath();
    for (let i = 0; i < 22; i++) {
      const h = hash(i * 37);
      const y = wrapY(v, i, v.h * 0.24, 0.1 + h * 0.3);
      const x = v.w * hash(i * 17) + Math.sin(t * 0.3 + i) * 8;
      const r = 0.8 + h * 1.6;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
  }
  ctx.globalCompositeOperation = 'source-over';

  // The last of the sky, going out at the top of the frame.
  if (v.progress > 0.5) return;
  const skyFade = 1 - v.progress * 2;
  const sky = ctx.createLinearGradient(0, 0, 0, v.h * 0.4);
  sky.addColorStop(0, rgba(mix(v.paint.top, fresh, 0.3), 0.3 * skyFade * v.alpha));
  sky.addColorStop(1, rgba(v.paint.top, 0));
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, v.w, v.h * 0.4);
}
