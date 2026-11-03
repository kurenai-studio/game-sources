import type { BackdropView } from './Backdrop';
import type { Motif } from './Motif';
import { mix, rgba, type Rgb } from './Paint';
import { bank, hash, stars, wrapY } from './SkyParts';

/**
 * Slowblue: act III's six skies - `Sky.ts` one atmosphere further out.
 *
 * The same three rules hold as everywhere else in the render layer: never a
 * colour the palette does not already have, a fraction of the contrast of the
 * swarm and the rings, and anchored to the world so it is scenery you climb
 * through rather than a pattern on the glass. Two things are specific to up here,
 * and both come from the physics rather than from taste.
 *
 * **The sky stops being a colour.** Air scatters sunlight, and there is
 * monotonically less of it: at the tropopause there is a quarter of the
 * atmosphere overhead, at the mesopause about a thousandth of a per cent, and at
 * the Karman line effectively none. So these six backdrops run from "blue with
 * the whole troposphere hazing below it" to "black, with the planet's own thin
 * bright rim along the bottom", and the stars arrive gradually through all of it
 * on one shared `depth` parameter. Nothing here is night. Every one of these is a
 * picture taken in the afternoon.
 *
 * **The layered flow is drawn.** This is the one act whose *mechanic* is visible
 * in its backdrop, and it has to be: the swarm is carried by bands of wind moving
 * at different speeds and in opposite directions, and a player who cannot see
 * where a boundary is cannot choose a layer. So four of the six draw the shear
 * directly - as streaked ice at the jet, as the lens of a standing wave at the
 * nacreous station, as combed filaments at the mesopause - and the drift rate of
 * each streak is the *sign of the wind in that band*. The picture is the meter.
 *
 * The two most beautiful stations in the game are in here, and they used to be
 * act II's. Nothing with wings has ever been to either, so they were given to a
 * carrier that can actually be there; the pictures did not change, only who is in
 * them. See `config/thinning.ts`.
 */

export function drawUpper(kind: string, motif: Motif, v: BackdropView): void {
  if (v.alpha < 0.01) return;
  switch (kind) {
    case 'jet':
      return jet(motif, v);
    case 'ozone':
      return ozone(motif, v);
    case 'nacre':
      return nacre(motif, v);
    case 'blacksky':
      return blacksky(motif, v);
    case 'noctilucent':
      return noctilucent(motif, v);
    case 'line':
      return line(motif, v);
  }
}

/**
 * The bands, drawn as what actually makes them visible: ice being dragged.
 *
 * Shared by the three stations with strong layers in them. Each streak belongs to
 * a band, and its horizontal drift rate carries that band's sign - so a player
 * looking at the picture can see which way the air is going before the swarm is
 * in it, which is the whole of what act III asks them to decide. It is
 * deliberately *not* sampled from `LayeredFlow`: the renderer draws the same
 * repeating stack the simulation runs on, from the same station data, and a
 * backdrop that had to reach into the sim to know what to draw would be a
 * backdrop that stops working the moment it is drawn off-screen.
 */
function shear(v: BackdropView, colour: Rgb, rows: number, strength: number, seed: number): void {
  const ctx = v.ctx;
  const t = v.time;
  ctx.lineCap = 'round';
  for (let i = 0; i < rows; i++) {
    const h = hash(i * 29 + seed);
    const y = wrapY(v, i, v.h * 0.34, 0.1 + h * 0.06);
    if (y < -20 || y > v.h + 20) continue;
    // Alternating sign, because that is what a shear profile is: the band above
    // goes the other way from the band below.
    const dir = i % 2 === 0 ? 1 : -1;
    const slide = t * strength * dir * (0.5 + h);
    const len = v.w * (0.3 + h * 0.5);
    const x = (((slide + h * v.w * 2) % (v.w + len * 2)) + v.w + len * 2) % (v.w + len * 2) - len;
    ctx.strokeStyle = rgba(colour, (0.05 + h * 0.06) * v.alpha);
    ctx.lineWidth = 0.8 + h * 2;
    ctx.beginPath();
    ctx.moveTo(x, y);
    // Very shallow: air at these speeds smears ice into lines, not into lumps.
    ctx.quadraticCurveTo(x + len * 0.5, y + (h - 0.5) * 8, x + len, y);
    ctx.stroke();
  }
}

/**
 * Station 1. The tropopause, seen from its own ceiling.
 *
 * Eleven kilometres is where the weather stops, and the picture says so by having
 * two halves that do not belong together: below, the entire troposphere as one
 * hazy floor with the anvil the flock came out of still in it; above, the first
 * sky in the campaign with nothing in it at all.
 *
 * The signature is the **streaking**. This is the fastest air on the planet, and
 * cirrus at this altitude is ice being dragged at two hundred knots - so the
 * ice here is drawn as lines rather than as cloud, and they are the first thing
 * in the game that moves sideways because the *medium* does.
 */
function jet(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const white = mix(v.paint.bottom, motif.crest, 0.4);
  const cold = mix(v.paint.top, motif.base, 0.35);

  // The troposphere below: everything the campaign has happened in so far, as one
  // soft floor that sinks away as the station climbs.
  const floorY = v.h * (0.66 + v.progress * 0.26);
  const floor = ctx.createLinearGradient(0, floorY - v.h * 0.34, 0, v.h);
  floor.addColorStop(0, rgba(white, 0));
  floor.addColorStop(1, rgba(white, 0.42 * v.alpha));
  ctx.fillStyle = floor;
  ctx.fillRect(0, floorY - v.h * 0.34, v.w, v.h - floorY + v.h * 0.34);

  // The last anvil, a long way down and going further. The flock is still under
  // it somewhere, which is the quietest handover note in the campaign.
  if (v.quality > 0.55) {
    bank(v, v.w * 0.42, floorY + v.h * 0.06, v.w * 1.1, white, 0.1, 3, 0.14);
  }

  // The dark above. Not black - there is still a quarter of the atmosphere over
  // this - but the first sky whose top is emptier than anything below it.
  const space = ctx.createLinearGradient(0, 0, 0, v.h * 0.66);
  space.addColorStop(0, rgba(cold, 0.6 * v.alpha));
  space.addColorStop(1, rgba(cold, 0));
  ctx.fillStyle = space;
  ctx.fillRect(0, 0, v.w, v.h * 0.66);

  ctx.globalCompositeOperation = 'lighter';
  shear(v, white, v.quality > 0.55 ? 9 : 5, 26, 0);
  ctx.globalCompositeOperation = 'source-over';

  stars(v, 0.3 + v.progress * 0.16, 34, 5);
}

/**
 * Station 2. Twenty kilometres, and the deepest blue there is.
 *
 * Ozone absorbs in the red, so the little light that scatters back at this height
 * comes back bluer than anywhere below - this is the last station whose sky is a
 * blue rather than a black with some blue left in it, and the picture is built to
 * spend that while it still has it.
 *
 * It is also the first station with a gravity wave, so the wave gets its first
 * and faintest drawing here: a single very broad vertical undulation in the haze
 * below, breathing on the same eleven-second clock the simulation runs on. The
 * player is not told what it is. Three stations later they will know.
 */
function ozone(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const blue = mix(v.paint.mid, motif.base, 0.4);
  const pale = mix(v.paint.bottom, motif.crest, 0.35);

  stars(v, 0.46 + v.progress * 0.16, 40, 13);

  // The haze floor, much lower and much thinner than the jet's.
  const floorY = v.h * (0.78 + v.progress * 0.18);
  const floor = ctx.createLinearGradient(0, floorY - v.h * 0.4, 0, v.h);
  floor.addColorStop(0, rgba(pale, 0));
  floor.addColorStop(0.7, rgba(mix(pale, blue, 0.4), 0.2 * v.alpha));
  floor.addColorStop(1, rgba(pale, 0.4 * v.alpha));
  ctx.fillStyle = floor;
  ctx.fillRect(0, floorY - v.h * 0.4, v.w, v.h - floorY + v.h * 0.4);

  ctx.globalCompositeOperation = 'lighter';
  // The first wave, drawn as three very long, very shallow lines in the haze -
  // the shape of air going up and down over a mountain range a hundred kilometres
  // upwind, which is exactly what it is.
  if (v.quality > 0.5) {
    ctx.lineCap = 'round';
    for (let i = 0; i < 3; i++) {
      const y = wrapY(v, i, v.h * 0.5, 0.09);
      if (y < -40 || y > v.h + 40) continue;
      ctx.strokeStyle = rgba(pale, 0.055 * v.alpha);
      ctx.lineWidth = 2.4 + i;
      ctx.beginPath();
      for (let x = -12; x <= v.w + 12; x += 18) {
        // One long wavelength, drifting on the campaign's own breath: the carrier
        // the whole act runs on, and `LayeredFlow`'s vertical term runs on the
        // same eleven seconds. `t * 0.05` was a 126-second period, which is six
        // times slower than anything else in the game and reads as not moving.
        const yy = y + Math.sin(x * 0.0052 + i * 1.9 + v.breath * 0.9) * (10 + i * 5);
        if (x === -12) ctx.moveTo(x, yy);
        else ctx.lineTo(x, yy);
      }
      ctx.stroke();
    }
  }
  shear(v, pale, v.quality > 0.55 ? 7 : 4, 18, 31);
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 3. The stratosphere, and the most beautiful thing in the sky.
 *
 * Nacreous cloud forms at about 25 km in air cold enough for the ice crystals to
 * come out all the same size - which is why it *diffracts*, and why the colour in
 * it runs in bands along the lens rather than sitting on it. It only appears when
 * the sun is a few degrees below the horizon, so the frame is a black daytime sky
 * with one warm band underneath it, and the cloud is lit from below by a sun that
 * has already set for everyone on the ground.
 *
 * This is also the one station in the campaign where the mechanic and the scenery
 * are the same object. A nacreous cloud does not sit in a wave, it *is* one -
 * air forced over a mountain range oscillates for hundreds of kilometres
 * downwind, and where a crest lifts it past its frost point a lens of ice appears
 * and hangs there, stationary, while the air pours through. So the station where
 * the gravity wave doubles is the station where the player can see it, and act
 * III needs no tutorial text because of this picture.
 *
 * Two things keep it from becoming a poster: the iridescence is drawn as a *shift
 * along* each lens rather than as a rainbow across it, and its peak alpha is
 * under a tenth. This is a station the player flies through, not a wallpaper.
 */
function nacre(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;

  // The sun's own band, low and warm, under a sky that is already night.
  const glowY = v.h * (0.72 + v.progress * 0.2);
  const warm = ctx.createLinearGradient(0, glowY - v.h * 0.4, 0, v.h);
  warm.addColorStop(0, rgba(mix(v.paint.bottom, motif.accent, 0.2), 0));
  warm.addColorStop(0.62, rgba(mix(v.paint.bottom, motif.crest, 0.35), 0.4 * v.alpha));
  warm.addColorStop(1, rgba(mix(motif.crest, [255, 150, 90], 0.45), 0.5 * v.alpha));
  ctx.fillStyle = warm;
  ctx.fillRect(0, glowY - v.h * 0.4, v.w, v.h - glowY + v.h * 0.4);

  stars(v, 0.55 + v.progress * 0.2, 44, 11);

  /*
   * The lenses. Long, thin, almost horizontal, and barely moving: a standing wave
   * in the stratosphere is a cloud that stays where it is while the air pours
   * through it, so these are the slowest things in the act by an order.
   *
   * Each one is a radial gradient drawn in a squashed frame, and not an ellipse
   * filled with a gradient, and that difference is the whole picture. The first
   * version ran its iridescence *along* the lens - correctly edgeless at both
   * tips, where the stops reach zero - and then let `ctx.ellipse` supply the
   * other two edges, which nothing was fading toward. A lens here is up to one
   * and a half screens wide, so both of those edges run out of the frame: the
   * shape has no sides in view, and a shape with no sides in view is a `fillRect`
   * through a live gradient by another name. Measured at **4.0 to 4.9 luminance
   * units** along the lens's own top edge, at every one of the station's four
   * sections, in the act's best picture - and in the one station whose entire
   * subject is a cloud that has no hard edge anywhere in it.
   *
   * Same class as the anvil's light band and the squall's break (§18, act II
   * review), one step further out: there the rectangle cut the gradient, here the
   * geometry did.
   *
   * The colour still shifts *along* the lens rather than banding across it, and
   * now it can actually be seen doing it: the stops run crest → accent → nothing
   * outward from a centre that drifts along the major axis, and on a ten-to-one
   * ellipse "outward" is along for all but the last few pixels. Same peak alpha
   * as before - under a tenth, because this is a station the player flies through
   * and not a wallpaper - and still one gradient per lens, which is the count the
   * allocation probe budgets for.
   */
  ctx.globalCompositeOperation = 'lighter';
  for (let i = 0; i < 7; i++) {
    const h = hash(i * 19);
    const y = wrapY(v, i, v.h * 0.5, 0.06 + h * 0.03);
    if (y < -60 || y > v.h + 60) continue;
    const cx = (hash(i * 37) * 1.2 - 0.1) * v.w;
    const wide = v.w * (0.3 + h * 0.45);
    const tall = wide * (0.055 + h * 0.05);
    // Where along the lens the light is, drifting the way a real one does as the
    // crystals turn.
    const from = ((Math.sin(t * 0.06 + i) * 0.5 + 0.5) * 0.4 - 0.2) * wide;
    ctx.save();
    ctx.translate(cx, y);
    ctx.rotate(Math.sin(i) * 0.05);
    ctx.scale(1, tall / wide);
    // Green in the body, rose toward the lit edge, which is what the motif has
    // said about this cloud since it was written and what the old two-point
    // gradient could not commit to: with the centre drifting along the major
    // axis, the rose sits closer to one end than the other and reads as an edge
    // that is lit rather than as a halo round the whole lens.
    const g = ctx.createRadialGradient(from, 0, 0, from, 0, wide);
    g.addColorStop(0, rgba(motif.accent, (0.05 + h * 0.045) * v.alpha));
    g.addColorStop(0.5, rgba(motif.crest, (0.045 + h * 0.04) * v.alpha));
    g.addColorStop(1, rgba(motif.base, 0));
    ctx.fillStyle = g;
    // Square in the squashed frame, so it is the lens's own bounding box on the
    // screen; the corners are past the last stop and therefore already zero.
    ctx.fillRect(from - wide, -wide, wide * 2, wide * 2);
    ctx.restore();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 4. Fifty kilometres. Stars in daylight.
 *
 * There is about a thousandth of the atmosphere left and nothing up here scatters
 * anything, so this is the first frame in the campaign that is *black in the
 * afternoon* - the sun is fully up and the sky is gone anyway. The station's
 * whole design is subtraction: no cloud, no haze above the limb, and the only
 * structure in the frame is the shear itself and the airglow layer resolving into
 * a line far below.
 *
 * The reason it is not literally black is that a completely black frame stops
 * reading as a place and starts reading as a rendering failure. What keeps it a
 * place is the airglow: the atmosphere faintly emitting its own light, which is
 * the thing astronauts describe as a green line around the Earth, and which is
 * about to become the whole bottom of the frame two stations from now.
 */
function blacksky(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const cold = mix(v.paint.mid, motif.base, 0.5);

  stars(v, 0.82, 54, 17);

  ctx.globalCompositeOperation = 'lighter';
  // The airglow, seen edge-on and still well below: one narrow band, and the
  // first appearance of the layer this act ends by leaving.
  const glowY = v.h * (0.86 + v.progress * 0.12);
  const glow = ctx.createLinearGradient(0, glowY - v.h * 0.2, 0, glowY + v.h * 0.1);
  glow.addColorStop(0, rgba(cold, 0));
  glow.addColorStop(0.62, rgba(mix(cold, motif.accent, 0.5), 0.11 * v.alpha));
  glow.addColorStop(1, rgba(cold, 0));
  ctx.fillStyle = glow;
  ctx.fillRect(0, glowY - v.h * 0.2, v.w, v.h * 0.3);

  // The shear, and almost nothing else. Two winds and no slow band between them,
  // which is this station's design in the level file too - so the picture has the
  // fewest, longest, fastest streaks in the act.
  shear(v, mix(v.paint.speck, motif.crest, 0.4), v.quality > 0.55 ? 6 : 4, 34, 61);
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 5. The mesopause: the last cloud in the atmosphere.
 *
 * Noctilucent cloud is ice condensed on meteor dust at about 82 km, and it is
 * lit long after every other cloud on the planet has gone dark, because at that
 * height the sun is still up. It is combed by the wind at the top of the
 * atmosphere into fine parallel bands - which is why it looks like nothing else
 * in the sky, and why it is drawn here as *filaments* rather than as lumps.
 *
 * There is nothing above this. The top of the frame is the last of the air, the
 * bottom is the airglow, and the first hint of the planet's own curve sits under
 * it, because that is what the ending opens on. The dust every one of those
 * crystals is grown on came in from space and burned on the way - which is
 * exactly what the swarm becomes two acts from now, and is the quietest piece of
 * foreshadowing in the campaign.
 */
function noctilucent(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;

  stars(v, 0.95, 60, 23);

  // The airglow: a thin band low in the frame, and the one green in the game.
  const glowY = v.h * (0.8 + v.progress * 0.14);
  ctx.globalCompositeOperation = 'lighter';
  const glow = ctx.createLinearGradient(0, glowY - v.h * 0.16, 0, glowY + v.h * 0.08);
  glow.addColorStop(0, rgba(motif.accent, 0));
  glow.addColorStop(0.6, rgba(mix(motif.accent, [120, 255, 190], 0.4), 0.1 * v.alpha));
  glow.addColorStop(1, rgba(motif.accent, 0));
  ctx.fillStyle = glow;
  ctx.fillRect(0, glowY - v.h * 0.16, v.w, v.h * 0.24);

  // The bands. Fine, parallel, gently waved, at three distances - the wave
  // pattern is the actual mechanism (gravity waves breaking at the mesopause)
  // and it is also what makes them read as one sheet rather than as streaks.
  for (let plane = 0; plane < 3; plane++) {
    if (plane === 2 && v.quality <= 0.55) continue;
    const rate = 0.05 + plane * 0.035;
    const rows = 7;
    for (let i = 0; i < rows; i++) {
      const h = hash(i * 13 + plane * 101);
      const y = wrapY(v, i + plane * 3, v.h * 0.26, rate);
      if (y < -20 || y > v.h + 20) continue;
      // Brightest where the sheet is thickest, and it fades out toward the top of
      // the frame, where there is no longer any cloud to be lit.
      const depth = 1 - Math.max(0, 1 - y / v.h) * 0.55;
      ctx.strokeStyle = rgba(
        mix(motif.crest, motif.base, plane * 0.3),
        (0.05 + h * 0.06) * depth * v.alpha,
      );
      ctx.lineWidth = 0.8 + h * 1.4 - plane * 0.2;
      ctx.beginPath();
      for (let x = -10; x <= v.w + 10; x += 12) {
        // Two wavelengths, because a real gravity-wave train has a long carrier
        // and a short ripple riding on it.
        const yy =
          y +
          Math.sin(x * 0.014 + h * 6 + t * 0.05) * (5 + h * 6) +
          Math.sin(x * 0.055 - h * 3) * 1.6;
        if (x === -10) ctx.moveTo(x, yy);
        else ctx.lineTo(x, yy);
      }
      ctx.stroke();
    }
  }
  ctx.globalCompositeOperation = 'source-over';

  // The planet, beginning to have an edge. One very shallow arc at the bottom of
  // the frame - not the reveal, which belongs to act IV, but the promise of it:
  // this is where the world starts to be a shape.
  limb(v, v.h * (1.06 + v.progress * 0.06), mix(v.paint.bottom, [4, 10, 26], 0.5), 0.55);
}

/**
 * Station 6. The Karman line, and the end of the air.
 *
 * A hundred kilometres is not a wall and not a place - it is defined as the
 * altitude at which a wing would have to fly faster than orbital velocity to hold
 * anything up, which is a physicist's way of saying the air has stopped being
 * able to carry things. So this is the emptiest frame in the game: no cloud, no
 * haze, no shear worth drawing, and stars that do not twinkle, because there is
 * no longer any atmosphere between them and the swarm to make them.
 *
 * What is left is the planet. The limb is closer and harder than it was at the
 * mesopause, and above it sits the thin bright line of the whole atmosphere seen
 * edge-on - every place the campaign has been so far, a few pixels thick. Act IV
 * opens on that line. This station is the moment before the player understands
 * what they are looking at.
 */
function line(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;

  // No twinkle: the atmosphere that made stars shimmer is underneath the swarm
  // now. `still` is what turns it off, so this station simply always reads still.
  stars(v, 1, 70, 29, true);

  const limbY = v.h * (0.94 + v.progress * 0.08);
  ctx.globalCompositeOperation = 'lighter';
  // The atmosphere, edge-on: one bright line along the top of the planet, warm
  // at the bottom and blue-white above it, and thin enough to be shocking.
  const air = ctx.createLinearGradient(0, limbY - v.h * 0.09, 0, limbY + v.h * 0.02);
  air.addColorStop(0, rgba(mix(motif.crest, [140, 190, 255], 0.5), 0));
  air.addColorStop(0.55, rgba(mix(motif.crest, [150, 200, 255], 0.4), 0.14 * v.alpha));
  air.addColorStop(0.85, rgba(mix(motif.accent, [255, 190, 130], 0.35), 0.2 * v.alpha));
  air.addColorStop(1, rgba(motif.accent, 0));
  ctx.fillStyle = air;
  ctx.fillRect(0, limbY - v.h * 0.09, v.w, v.h * 0.11);
  ctx.globalCompositeOperation = 'source-over';

  // ...and the planet itself under it, black and hard-edged.
  limb(v, limbY, mix(v.paint.bottom, [2, 5, 14], 0.6), 0.8);
}

/**
 * The Earth's edge: one very shallow arc across the bottom of the frame.
 *
 * Shared by the two stations that have the planet in them, because it has to be
 * the *same* curve at the mesopause and at the Karman line - the player is
 * eighteen kilometres higher, not somewhere else, and a limb that changed radius
 * between two stations would quietly say the world had been redrawn.
 */
function limb(v: BackdropView, y: number, colour: Rgb, alpha: number): void {
  const ctx = v.ctx;
  const r = v.w * 2.4;
  ctx.fillStyle = rgba(colour, alpha * v.alpha);
  ctx.beginPath();
  ctx.moveTo(-20, v.h + 20);
  ctx.arc(v.w * 0.5, y + r, r, -Math.PI * 0.62, -Math.PI * 0.38);
  ctx.lineTo(v.w + 20, v.h + 20);
  ctx.closePath();
  ctx.fill();
}
