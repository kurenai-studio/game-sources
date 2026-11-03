import { TAU } from '../core/math';
import type { BackdropView } from './Backdrop';
import type { Motif } from './Motif';
import { mix, rgba, type Rgb } from './Paint';
import { hash, stars, wrapY } from './SkyParts';

/**
 * Slowblue: act IV's six frames, and the only backdrops in the game with no sky.
 *
 * Every band below this one is a colour the *air* is. There is none here, so
 * these are the colours of the things in the frame instead - the planet, the
 * aurora, the wreckage, and the gold the player has been carrying since the
 * trench floor. Three consequences follow, and all three are physics rather than
 * taste.
 *
 * **There is no fill light.** In an atmosphere, the sky is a second light source:
 * it is what stops the shadow side of anything from being black. Vacuum has no
 * second source, so everything up here is lit hard from one side and unlit on the
 * other, and the umbra - where the first source is gone too - is genuinely black
 * except for the swarm. That is the darkest the campaign ever goes and it is the
 * station immediately before its brightest.
 *
 * **The planet is the composition.** From the first frame of this act the Earth's
 * limb is in shot, and it *rises* through the six stations - the line of air alone
 * at free fall, a twentieth of the frame at the umbra, a tenth by the debris belt,
 * and a quarter at the Overview. The player is not told the camera is going to
 * turn. They watch the world get closer for twenty minutes first.
 *
 * **The atmosphere is a line.** Along that limb sits the one detail this whole act
 * exists to deliver: a bright rim a few pixels thick, warm underneath and
 * blue-white above, which is every place the campaign has been. It is drawn from
 * the first station so that by the time the Overview makes it the subject, the
 * player has been looking at it, unremarked, for the whole act.
 *
 * > Both of those paragraphs were false for four stations out of six, and the way
 * > they were false is worth leaving written down. The `rise` each station passed
 * > ran 0 to 0.54 over the first four, and the limb only crosses the bottom of the
 * > frame at 0.538 - so the planet, the band of air, the day side's weather and the
 * > umbra's cities were all *below the picture* until the well. The act's whole
 * > through-line existed only in the two stations that were looked at. It was
 * > invisible to the suite for the ordinary reason: an absence is not a seam, not a
 * > flat frame and not a blown-out one, and the geometry was drawn correctly - just
 * > off the bottom. The six `rise` values are now the range that actually puts it in
 * > frame, and the Overview's `0.8 + progress * 0.2` is untouched, because that is
 * > the one frame in the act that was already right.
 */

export function drawOrbit(kind: string, motif: Motif, v: BackdropView): void {
  if (v.alpha < 0.01) return;
  switch (kind) {
    case 'freefall':
      return freefall(motif, v);
    case 'aurora':
      return aurora(motif, v);
    case 'umbra':
      return umbra(motif, v);
    case 'debris':
      return debris(motif, v);
    case 'well':
      return well(motif, v);
    case 'overview':
      return overview(motif, v);
  }
}

/**
 * Where the limb sits in the frame, for a given `rise`.
 *
 * One function rather than the three copies of this arithmetic there used to be -
 * the body drew it, the umbra's cities re-derived it to hang themselves off, and
 * the Overview's sunrise re-derived it again to find the horizon to rise over. A
 * number that decides where the planet is cannot live in three places, because
 * moving it in one of them is a silent way to put the cities somewhere the planet
 * is not.
 *
 * `rise` is how far up the frame the planet has come. It is not 0..1 across the
 * act: the useful range starts around 0.4, which is where the band of air along
 * the limb first reaches the bottom of the frame, and the turn is at 1.
 */
function limbY(v: BackdropView, rise: number): number {
  return v.h * (1.28 - rise * 0.52);
}

/**
 * The Earth, and the line of air along it.
 *
 * Shared by all six stations, because it has to be the *same planet* in every one
 * of them - the swarm is coming round it, not visiting six of them - so the limb
 * has one radius for the whole act and only its height in the frame changes.
 *
 * `lit` is how much of the day side is showing. It goes to zero in the umbra,
 * which is the whole of what that station is: the planet is still there, exactly
 * where it was, and there is simply no light on it.
 *
 * Returns where the limb ended up, because everything that sits *on* this planet
 * has to be laid out under it and the alternative is re-deriving `limbY` at the
 * call site - which is the three-copies mistake this act already made once, and
 * which act V then made a fourth time by not deriving it at all: its night side
 * hung its storm cells on a fixed fraction of the screen and put two of the seven
 * above the horizon.
 */
function planet(v: BackdropView, motif: Motif, rise: number, lit: number): number {
  const ctx = v.ctx;
  const r = v.w * 2.6;
  const surfaceY = limbY(v, rise);
  // What is left of the frame under the limb. Everything that sits *on* the
  // planet is laid out across this rather than across a fixed fraction of the
  // screen, because when the limb is low there is barely any of it and the same
  // fraction puts the detail below the bottom edge - which is where the day
  // side's weather and the umbra's cities both were.
  const below = v.h - surfaceY;
  const ground = mix(v.paint.bottom, [3, 8, 20], 0.55);

  // The body. One shallow arc, filled flat - a planet seen from low orbit has no
  // gradient across it worth drawing at this scale, it has a terminator.
  ctx.fillStyle = rgba(ground, (0.5 + lit * 0.45) * v.alpha);
  ctx.beginPath();
  ctx.moveTo(-20, v.h + 20);
  ctx.arc(v.w * 0.5, surfaceY + r, r, -Math.PI * 0.63, -Math.PI * 0.37);
  ctx.lineTo(v.w + 20, v.h + 20);
  ctx.closePath();
  ctx.fill();

  if (lit > 0.02) {
    // The day side, and the weather on it: broad soft patches that scroll with
    // the world, so the planet is turning underneath the swarm rather than being
    // a painted disc. Cheap - three fills - because it is never the subject.
    ctx.save();
    ctx.clip();
    const day = ctx.createLinearGradient(0, surfaceY, 0, v.h);
    day.addColorStop(0, rgba(mix(ground, motif.crest, 0.3), 0.35 * lit * v.alpha));
    day.addColorStop(1, rgba(ground, 0));
    ctx.fillStyle = day;
    ctx.fillRect(0, surfaceY, v.w, v.h - surfaceY);
    if (v.quality > 0.55) {
      ctx.fillStyle = rgba(mix(v.paint.speck, motif.crest, 0.4), 0.1 * lit * v.alpha);
      ctx.beginPath();
      for (let i = 0; i < 5; i++) {
        const h = hash(i * 61);
        const x = (((h + -v.cameraY * 0.00007) % 1.4) - 0.2) * v.w;
        const y = surfaceY + below * (0.12 + h * 0.8);
        ctx.moveTo(x + v.w * 0.2, y);
        ctx.ellipse(x, y, v.w * (0.12 + h * 0.16), v.h * 0.02, 0, 0, TAU);
      }
      ctx.fill();
    }
    ctx.restore();
  }

  // The atmosphere, edge-on: the whole campaign so far, a few pixels thick. Warm
  // at the bottom where the sun is coming through the most air, blue-white above.
  // Drawn in `lighter` so it reads as emission rather than as a painted band.
  ctx.globalCompositeOperation = 'lighter';
  const depth = v.h * (0.055 + rise * 0.03);
  const air = ctx.createLinearGradient(0, surfaceY - depth, 0, surfaceY + depth * 0.25);
  air.addColorStop(0, rgba(mix(motif.crest, [130, 180, 255], 0.55), 0));
  air.addColorStop(0.5, rgba(mix(motif.crest, [140, 190, 255], 0.4), (0.1 + lit * 0.12) * v.alpha));
  air.addColorStop(0.86, rgba(mix(motif.accent, [255, 180, 120], 0.4), (0.08 + lit * 0.18) * v.alpha));
  air.addColorStop(1, rgba(motif.accent, 0));
  ctx.fillStyle = air;
  // Clipped to the limb's own curve, or the band would run straight across a
  // curved horizon - which is the one mistake that makes a planet read as a wall.
  ctx.save();
  ctx.beginPath();
  ctx.moveTo(-20, surfaceY - depth * 1.4);
  ctx.lineTo(v.w + 20, surfaceY - depth * 1.4);
  ctx.lineTo(v.w + 20, v.h + 20);
  ctx.arc(v.w * 0.5, surfaceY + r, r, -Math.PI * 0.37, -Math.PI * 0.63, true);
  ctx.closePath();
  ctx.clip();
  ctx.fillRect(0, surfaceY - depth * 1.5, v.w, depth * 2);
  ctx.restore();
  ctx.globalCompositeOperation = 'source-over';
  return surfaceY;
}

/**
 * Station 1. Free fall.
 *
 * The first frame of the campaign with no air in it at all, and it is built to be
 * *empty*: stars that do not twinkle, the planet low and far off, and nothing
 * else. The player has just had the gesture they have used for three acts stop
 * behaving, and the station's whole job is to give them room to find out what it
 * does now. Anything in the frame would be competing with that.
 */
function freefall(motif: Motif, v: BackdropView): void {
  stars(v, 1, 76, 31, true);
  // The body is still below the frame here and is meant to be - "low and far" is
  // the station's whole composition. What is in shot is the line of air along the
  // limb, along the very bottom edge, which is the thing the act spends six
  // stations bringing up.
  planet(v, motif, 0.45 + v.progress * 0.07, 0.55);
}

/**
 * Station 2. The aurora, from above it.
 *
 * Almost nobody has seen this and it is the reason the station exists: the
 * curtains are *below* the swarm, hanging down into the atmosphere along the
 * field lines, and the green comes up off the planet rather than down from the
 * sky. They are drawn as vertical ribbons with a bright lower edge, waving on a
 * slow phase - which is what a curtain does, because it is following a magnetic
 * field that is itself moving.
 */
function aurora(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  stars(v, 0.9, 60, 37, true);
  planet(v, motif, 0.53 + v.progress * 0.07, 0.3);

  ctx.globalCompositeOperation = 'lighter';
  const green = mix(motif.accent, [90, 255, 170], 0.5);
  const curtains = v.quality > 0.55 ? 5 : 3;
  for (let i = 0; i < curtains; i++) {
    const h = hash(i * 43);
    // Barely moving: an aurora is a thousand kilometres away and the swarm is
    // going round it, not past it.
    const drift = wrapY(v, i, v.h * 0.9, 0.05);
    const baseY = v.h * (0.62 + h * 0.2) + drift * 0.12;
    const x = (((h * 1.3 + t * 0.004) % 1.3) - 0.15) * v.w;
    const wide = v.w * (0.1 + h * 0.14);
    const tall = v.h * (0.2 + h * 0.18);
    // The ribbon: a column whose top fades into nothing and whose bottom is a
    // hard bright edge, because that is where it meets the air it is exciting.
    const g = ctx.createLinearGradient(0, baseY - tall, 0, baseY);
    /*
     * The top stop is the green's own colour at zero, and it used to be a violet
     * `crown` mixed fresh every frame - a third hue for the frame, computed and
     * then handed to the one stop that cannot show it.
     *
     * Measured rather than reasoned, because a zero-alpha stop is not obviously
     * inert: canvas interpolates a gradient in *premultiplied* space, so what the
     * ramp carries from a transparent stop is only what 8-bit rounding leaves
     * behind. Composited over an opaque sky with `lighter`, swapping the violet
     * for pure red moved the frame by **4 of 255 at most, on one channel**, and
     * swapping it for the green by **2** - against **15** for a control with the
     * same stop carrying 0.06 alpha. So the crown was never on the glass, in
     * either aurora, and the visual language it would have broken had it worked
     * is the one thing the campaign does not have: a third hue. Teal, and one
     * warm - and here green, and nothing else.
     */
    g.addColorStop(0, rgba(green, 0));
    g.addColorStop(0.55, rgba(green, 0.05 * v.alpha));
    g.addColorStop(1, rgba(green, (0.14 + h * 0.08) * v.alpha));
    ctx.fillStyle = g;
    ctx.beginPath();
    // A wave along its length, so it reads as a sheet seen edge-on rather than a
    // rectangle. Four columns per curtain is enough to carry the fold.
    for (let k = 0; k <= 4; k++) {
      const u = k / 4;
      const sway = Math.sin(t * 0.12 + i * 2.1 + u * 3.4) * wide * 0.4;
      const cx = x + (u - 0.5) * wide * 2 + sway;
      ctx.moveTo(cx + wide * 0.22, baseY);
      ctx.ellipse(cx, baseY - tall * 0.5, wide * 0.22, tall * 0.5, 0, 0, TAU);
    }
    ctx.fill();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 3. The Earth's shadow.
 *
 * The darkest frame in the game, and the only one that is nearly empty on
 * purpose twice over: there is no sky here *and* the sun is behind the planet, so
 * the single light source the act has had is gone. What is left is the swarm, the
 * stars, and - the one detail that keeps it a place rather than a blank - the
 * cities on the night side, drifting past far below.
 *
 * That detail is doing real work. It is the first time since the trench floor
 * that the game shows anything made by people, it arrives at the exact moment the
 * player is furthest from all of it, and it is never mentioned.
 */
function umbra(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  stars(v, 1, 88, 41, true);
  // `lit` at zero: the planet is exactly where it was and there is no light on it.
  const rise = 0.61 + v.progress * 0.07;
  planet(v, motif, rise, 0);

  if (v.quality <= 0.5) return;
  ctx.globalCompositeOperation = 'lighter';
  // Cities. Small warm clusters on the dark limb, scrolling with the world.
  //
  // Spread across the night side that is actually in frame, which is a band
  // between a twenty-seventh and a fourteenth of the screen deep here. They used
  // to be hung 0.02 to 0.22 of a *screen* below the limb - a spacing that only
  // fits a planet filling the bottom fifth, i.e. the Overview - and were then
  // clipped against the bottom edge, so with the limb where it was all twenty-six
  // failed that clip on every frame and this station drew none of them, ever.
  //
  // There is no clip now because the layout cannot produce one: the furthest a
  // city can fall is 0.92 of the way from the limb to the bottom of the frame.
  // What keeps that true if the limb moves is `e2e/acts.spec.ts`, which counts
  // them.
  const lamp = mix(motif.accent, [255, 190, 110], 0.5);
  const surfaceY = limbY(v, rise);
  const below = v.h - surfaceY;
  ctx.fillStyle = rgba(lamp, 0.5 * v.alpha);
  ctx.beginPath();
  for (let i = 0; i < 26; i++) {
    const h = hash(i * 67);
    const x = (((h + -v.cameraY * 0.00009) % 1.2) - 0.1) * v.w;
    const y = surfaceY + below * (0.06 + hash(i * 13) * 0.86);
    // Clusters rather than points: a city from orbit is a smear with a core.
    const flicker = 0.7 + 0.3 * Math.sin(t * 0.7 + i);
    const r = (0.5 + h * 1.1) * flicker;
    ctx.moveTo(x + r, y);
    ctx.arc(x, y, r, 0, TAU);
    if (h > 0.6) {
      ctx.moveTo(x + r * 2.6, y + 2);
      ctx.arc(x + r * 1.8, y + 2, r * 0.7, 0, TAU);
    }
  }
  ctx.fill();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 4. The debris belt.
 *
 * The one band up here with anything man-made in it, and the only station whose
 * backdrop is *busy*. Everything in it is something that stopped working and kept
 * going anyway: dead panels, spent stages, and the long slow glints of things
 * tumbling end over end, which is how you actually spot debris - not as shapes
 * but as something that flashes once every few seconds and is gone.
 */
function debris(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  stars(v, 0.85, 56, 47, true);
  planet(v, motif, 0.69 + v.progress * 0.05, 0.5);

  if (v.quality <= 0.5) return;
  ctx.globalCompositeOperation = 'lighter';
  // The glints. Each has its own tumble period, and is dark for most of it - a
  // flat panel only catches the sun through a few degrees of its rotation.
  const metal = mix(v.paint.speck, motif.crest, 0.4);
  for (let i = 0; i < 16; i++) {
    const h = hash(i * 71);
    const y = wrapY(v, i, v.h * 0.5, 0.14 + h * 0.1);
    if (y < -12 || y > v.h + 12) continue;
    const x = v.w * (0.05 + hash(i * 29) * 0.9);
    const period = 3 + h * 6;
    const phase = ((t + h * period) % period) / period;
    // sin^8: a hard, brief flash with a long dark side, which is what tumbling
    // wreckage actually looks like from a distance.
    const flash = Math.pow(Math.sin(phase * Math.PI), 8);
    if (flash < 0.02) continue;
    const len = 2 + h * 5;
    ctx.strokeStyle = rgba(metal, 0.6 * flash * v.alpha);
    ctx.lineWidth = 1 + h;
    ctx.beginPath();
    ctx.moveTo(x - len, y - len * 0.4);
    ctx.lineTo(x + len, y + len * 0.4);
    ctx.stroke();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 5. The well.
 *
 * The act's subject with nothing else in the frame: the planet is close now and
 * the bottom of the picture *glows*, because that is where everything is falling
 * toward. There is no debris and no aurora here - what makes this station hard is
 * gravity, and gravity cannot be drawn, so the backdrop draws what it is pulling
 * toward instead and leaves the rest of the frame empty for the standing nodes.
 */
function well(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  stars(v, 0.75, 48, 53, true);
  planet(v, motif, 0.76 + v.progress * 0.04, 0.42);

  // The pull, as light. One very large radial low in the frame, in the violet the
  // zone palette already carries - the only station in the act with a colour of
  // its own rather than a colour of the planet's.
  ctx.globalCompositeOperation = 'lighter';
  const deep = mix(v.paint.bottom, motif.crest, 0.35);
  const cx = v.w * 0.5;
  const cy = v.h * 1.02;
  const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, v.h * 0.85);
  g.addColorStop(0, rgba(deep, 0.16 * v.alpha));
  g.addColorStop(0.45, rgba(deep, 0.05 * v.alpha));
  g.addColorStop(1, rgba(deep, 0));
  ctx.fillStyle = g;
  ctx.fillRect(0, v.h * 0.2, v.w, v.h * 0.8);
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 6. The Overview - the turn.
 *
 * The whole planet, the whole atmosphere, and nothing else. This is the frame the
 * campaign has been climbing toward for four acts, and everything about it is
 * subtraction: no debris, no aurora, no cities, no glints. The limb is at its
 * highest, the air along it is at its brightest, and the sun comes back round the
 * edge of the world as the station runs - which is the one thing in this backdrop
 * that *arrives*, and it arrives on `progress`, so it lands as the player crosses
 * the last empty sections.
 *
 * The camera turn itself is not here. It belongs to the transition
 * (`render/Overview.ts`); this is the picture it turns *into*.
 */
function overview(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  stars(v, 0.6 * (1 - v.progress * 0.5), 40, 59, true);
  planet(v, motif, 0.8 + v.progress * 0.2, 0.55 + v.progress * 0.45);

  // Sunrise round the limb. A wide, very soft radial coming up from one side of
  // the planet's edge, strengthening across the station.
  if (v.progress <= 0.02) return;
  ctx.globalCompositeOperation = 'lighter';
  const warm = mix(motif.accent, [255, 220, 170], 0.4);
  const surfaceY = limbY(v, 0.8 + v.progress * 0.2);
  const sx = v.w * 0.78;
  const g = ctx.createRadialGradient(sx, surfaceY, 0, sx, surfaceY, v.w * 0.9);
  g.addColorStop(0, rgba(warm, 0.22 * v.progress * v.alpha));
  g.addColorStop(0.4, rgba(warm, 0.07 * v.progress * v.alpha));
  g.addColorStop(1, rgba(warm, 0));
  ctx.fillStyle = g;
  ctx.fillRect(0, surfaceY - v.h * 0.5, v.w, v.h);
  ctx.globalCompositeOperation = 'source-over';
}

/** Exported for the act V module, which opens on the same planet from the same side. */
export { planet as drawPlanet };
export type { Rgb };
