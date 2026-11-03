import { TAU } from '../core/math';
import type { Motif } from './Motif';
import type { BackdropView } from './Backdrop';
import { mix, rgba } from './Paint';
import { bank, hash, stars, wrapY } from './SkyParts';

/**
 * Slowblue: the air each station is flown in - `Backdrop.ts` one medium up.
 *
 * The same three rules apply, and they are what let this be full-screen without
 * becoming noise: never a colour the palette does not already have, a fraction of
 * the contrast of the flock and the rings, and anchored to the world so it is
 * scenery you climb through rather than a pattern on the glass.
 *
 * Three things are new, and all three come from the medium rather than from taste.
 *
 * **The horizon is behind you.** Every water backdrop put its light *ahead*,
 * because the surface was the destination. In air the ground is the thing you can
 * see receding, so the detailed plane sits at the bottom of the frame and drains
 * away downward as the act climbs.
 *
 * **Everything here is parallax on a real distance.** A wave is metres away, a
 * cumulus deck is hundreds, a stratospheric lens is tens of kilometres. Their
 * scroll rates come from that and nothing else, so the act gets its depth for
 * free and in the right order - the wave crests tear past while the anvil barely
 * moves and the noctilucent bands are almost nailed to the frame.
 *
 * **The light goes out on the way up, and that is physics.** Sky is blue because
 * there is air overhead to scatter sunlight in it. By the fifth station there is
 * a fortieth of it left and the sky is black in daylight; by the sixth the only
 * lit thing in the frame is ice at the edge of space with the sun still on it.
 * So the last two backdrops are night pictures taken in the afternoon, and they
 * are the two most beautiful things in the game on purpose - the ascent has to
 * pay for itself before the ending does.
 */

export function drawSky(kind: string, motif: Motif, v: BackdropView): void {
  if (v.alpha < 0.01) return;
  switch (kind) {
    case 'spray':
      return spray(motif, v);
    case 'cliff':
      return cliff(motif, v);
    case 'cumulus':
      return cumulus(motif, v);
    case 'passage':
      return passage(motif, v);
    case 'squall':
      return squall(motif, v);
    case 'anvil':
      return anvil(motif, v);
  }
}

/**
 * Station 2. The headland, and the only land in the game.
 *
 * Everything else the campaign is played through is fluid - water, cloud, ice,
 * vacuum, rain - and this is the one station with a *solid* thing in the frame.
 * That is the whole reason the cliff exists: the flock has been flying over an
 * ocean since it left it, and one wall of rock going past says how fast and how
 * high better than any amount of moving water can.
 *
 * It is in the backdrop rather than in the course on purpose, and the rule is
 * `Backdrop.walls`': anything drawn down the edge of the play field has to be
 * edgeless, or players read it as an obstacle and steer around geometry that is
 * not there. So the headland runs down **one** side, its face dissolves into haze
 * long before the middle of the screen, and the thing that makes it a cliff is
 * not its outline but what is happening at the top of it: the wind hits a wall,
 * has nowhere to go but up, and drags torn fog with it.
 */
function cliff(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  // A headland against a bright hazy sky is a *silhouette*, which is why the rock
  // is built from `shoal` - the palette's dark, and the same entry the birds are
  // drawn in. Act II's gradient is upside down (`config/zones.ts`): `bottom` is
  // the haze over the water and `top` is the deepening sky, so the intuitive
  // "dark end of the gradient" is the one colour here that is not dark at all.
  const rock = mix(v.paint.shoal, v.paint.top, 0.3);
  const lit = mix(v.paint.speck, motif.crest, 0.3);
  const haze = mix(v.paint.bottom, lit, 0.45);

  // The sea far below, draining out of the bottom of the frame as the station
  // climbs - the same departure the spray makes, three hundred metres higher.
  const seaY = v.h * (0.82 + v.progress * 0.2);
  const water = ctx.createLinearGradient(0, seaY - v.h * 0.18, 0, v.h);
  water.addColorStop(0, rgba(haze, 0));
  water.addColorStop(1, rgba(mix(rock, haze, 0.5), 0.5 * v.alpha));
  ctx.fillStyle = water;
  ctx.fillRect(0, seaY - v.h * 0.18, v.w, v.h - seaY + v.h * 0.18);

  /*
   * The headland, and the one rule it has to obey.
   *
   * The first cut of this drew the cliff as a filled silhouette clipped to its own
   * ridge line, and it looked exactly right and was exactly the mistake the trench
   * floor already made and documented (`Backdrop.walls`): a dark shape with a
   * *defined edge* standing in the play field is an obstacle, whatever the code
   * thinks it is. Players steer around it and lose width they always had. Measured
   * on the frame, the step in alpha across the ridge was 0.39 - plainly visible,
   * a third of the way across a phone screen, in an act whose sections use the
   * full width.
   *
   * So there is no silhouette. The mass is a horizontal gradient that runs out
   * long before anything could be read as a boundary, and the *identity* is
   * carried by the lit ridge line drawn on top of it - one stroke, one pixel
   * wide, which is a mark rather than a shape and cannot be steered around. Same
   * fix as the trench, arrived at the same way.
   */
  const drift = -v.cameraY * 0.34;
  const edge = v.w * 0.2;
  const ridgeAt = (y: number): number =>
    edge *
    (0.62 + 0.3 * Math.sin((y + drift) * 0.0042) + 0.12 * Math.sin((y + drift) * 0.017 + 1.3));

  const face = ctx.createLinearGradient(0, 0, edge * 1.45, 0);
  face.addColorStop(0, rgba(rock, 0.72 * v.alpha));
  face.addColorStop(0.5, rgba(rock, 0.26 * v.alpha));
  face.addColorStop(1, rgba(rock, 0));
  ctx.fillStyle = face;
  ctx.fillRect(0, 0, edge * 1.45, v.h);

  // The lip of the headland: a *dark* line, not a lit one. At sixty metres over a
  // bright sea the sky is the brightest thing in the frame by a long way, so the
  // top of a cliff is an edge cut out of it - the same reason the flock is drawn
  // in `shoal` down here and only turns pale above the weather. The thin warm
  // highlight sits just inside it, where the sun actually lands.
  if (v.quality > 0.5) {
    for (const [colour, alpha, width, offset] of [
      [rock, 0.4, 2.2, 0],
      [lit, 0.3, 1, -2.4],
    ] as const) {
      ctx.strokeStyle = rgba(colour, alpha * v.alpha);
      ctx.lineWidth = width;
      ctx.beginPath();
      for (let y = -20; y <= v.h + 20; y += 18) {
        const w = ridgeAt(y) + offset;
        if (y === -20) ctx.moveTo(w, y);
        else ctx.lineTo(w, y);
      }
      ctx.stroke();
    }
  }

  ctx.globalCompositeOperation = 'lighter';
  // The colony. Every seabird cliff in the world is on a headland like this one,
  // and this is the only station where the flock has company that is not hunting
  // it: specks working the updraught, wheeling rather than travelling.
  if (v.quality > 0.55) {
    ctx.fillStyle = rgba(lit, 0.3 * v.alpha);
    ctx.beginPath();
    for (let i = 0; i < 18; i++) {
      const h = hash(i * 23);
      const y = wrapY(v, i, v.h * 0.3, 0.34);
      if (y < -10 || y > v.h + 10) continue;
      const orbit = t * (0.3 + h * 0.5) + i;
      const x = ridgeAt(y) * (0.7 + h * 0.5) + Math.cos(orbit) * v.w * (0.03 + h * 0.05);
      const r = 0.9 + h * 1.1;
      ctx.moveTo(x + r, y + Math.sin(orbit) * 7);
      ctx.arc(x, y + Math.sin(orbit) * 7, r, 0, TAU);
    }
    ctx.fill();
  }

  // Fog torn off the top of the wall and carried up. The one thing in the frame
  // that says *why* this station has a rotor in it.
  for (let i = 0; i < 5; i++) {
    const h = hash(i * 41);
    const y = wrapY(v, i, v.h * 0.42, 0.22 + h * 0.1);
    if (y < -v.h * 0.3 || y > v.h + v.h * 0.2) continue;
    const x = ridgeAt(y) * 1.2 + v.w * 0.06 + Math.sin(t * 0.09 + i) * v.w * 0.04;
    bank(v, x, y, v.w * (0.3 + h * 0.3), lit, 0.06 + 0.04 * h, i * 9, 0.3);
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 4. The flyway.
 *
 * Two and a half kilometres is the altitude birds actually migrate at, and this
 * is the one station in the campaign whose subject is *company*. Cloud streets -
 * long parallel lines of torn cumulus, organised by the same wind the flock is
 * riding - run the way the course runs, so for the first time the scenery points
 * where the player is going instead of lying across it.
 *
 * The detail that carries it is the **other flocks**: small skeins, far off,
 * travelling the same way at their own pace. They are the only living thing in
 * the backdrop of any station in the game, and they are what turns a corridor of
 * cloud into a route that things use.
 */
function passage(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const white = mix(v.paint.speck, motif.crest, 0.25);
  const shade = mix(v.paint.mid, motif.base, 0.5);

  // The haze the whole thing sits on, thinning as the station climbs out of it.
  const floorY = v.h * (0.74 + v.progress * 0.2);
  const floor = ctx.createLinearGradient(0, floorY - v.h * 0.3, 0, v.h);
  floor.addColorStop(0, rgba(mix(v.paint.bottom, white, 0.35), 0));
  floor.addColorStop(1, rgba(mix(v.paint.bottom, white, 0.35), (0.42 - v.progress * 0.2) * v.alpha));
  ctx.fillStyle = floor;
  ctx.fillRect(0, floorY - v.h * 0.3, v.w, v.h - floorY + v.h * 0.3);

  // The streets. Each is a chain of lumps drawn *along* the course rather than
  // across it, which is the whole visual difference between this station and the
  // cumulus field below it - there, cloud is a deck you cross; here it is a lane
  // you follow.
  const lanes = v.quality > 0.55 ? 4 : 3;
  for (let lane = 0; lane < lanes; lane++) {
    const h = hash(lane * 17);
    // Nearer lanes are wider, brighter and scroll faster.
    const rate = 0.16 + lane * 0.07;
    const x = v.w * (0.1 + ((lane * 0.29 + h * 0.1) % 0.82));
    const wide = v.w * (0.1 + h * 0.09);
    for (let i = 0; i < 5; i++) {
      const y = wrapY(v, i + lane * 7, v.h * 0.4, rate);
      if (y < -v.h * 0.3 || y > v.h + v.h * 0.3) continue;
      const sway = Math.sin(t * 0.04 + lane * 1.7 + i) * v.w * 0.02;
      // Shadow under, lit top over: the same three-fill light direction the
      // cumulus field uses, so the two stations are obviously the same weather.
      if (v.quality > 0.55) {
        bank(v, x + sway + wide * 0.2, y + wide * 0.42, wide * 1.7, shade, 0.12, lane * 13 + i, 0.5);
      }
      bank(v, x + sway, y, wide * 1.9, white, 0.1 + 0.05 * h, lane * 5 + i, 0.44);
    }
  }

  ctx.globalCompositeOperation = 'lighter';
  // The other flocks. Skeins rather than clusters - a line of specks with a lead
  // point, which is the shape everything that migrates in company actually makes.
  if (v.quality > 0.5) {
    ctx.strokeStyle = rgba(mix(v.paint.shoal, white, 0.55), 0.3 * v.alpha);
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    for (let f = 0; f < 3; f++) {
      const h = hash(f * 53);
      // Slowly overtaking or being overtaken: their rate is near the flock's own,
      // so they hang in the frame the way real company does.
      const y = wrapY(v, f, v.h * 0.75, 0.42 + h * 0.16);
      if (y < -40 || y > v.h + 40) continue;
      const lead = v.w * (0.12 + h * 0.74) + Math.sin(t * 0.06 + f) * v.w * 0.03;
      const span = 5 + Math.floor(h * 4);
      for (let i = 0; i < span; i++) {
        // A V: two arms trailing back from the lead bird.
        const side = i % 2 === 0 ? 1 : -1;
        const step = Math.floor(i / 2) + 1;
        const bx = lead + side * step * (5 + h * 3);
        const by = y + step * (4 + h * 2);
        ctx.moveTo(bx - 2, by);
        ctx.lineTo(bx + 2, by + Math.sin(t * 6 + i + f) * 1.2);
      }
    }
    ctx.stroke();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 1. The sea, from just above it.
 *
 * The whole point of this station is that the player has *just* left the water,
 * so the water has to still be there - close enough to read individual crests,
 * moving fast enough to say how low they are. The crests scroll at the highest
 * rate in the act, which is what makes sixty metres feel like sixty metres, and
 * the sea sinks out of the bottom of the frame as the station goes on. It is the
 * one backdrop in the game that leaves.
 *
 * Slowblue: and for most of its life it left and took the picture with it.
 *
 * Everything here used to hang off `seaY` - the crests, the torn spray, the water
 * gradient itself - and `seaY` ran to 0.96h. So the station's late half was bare
 * sky gradient from the banner to the bottom sixteenth: measured on the play
 * field, the horizontal spread through the middle third fell from 8.44 at the
 * opening to **0.95**, the lowest reading in the first two acts, against 15 to 21
 * for every station of act I at the same point in itself. A vertical gradient has
 * no spread along a row by construction, so that number is not "sparse", it is
 * "there is nothing drawn here at all".
 *
 * It is also the one station in the act with a single plane, in a file whose rule
 * is at least two: the cliff has its fog, the cumulus field its eight banks, the
 * passage its streets, the squall its curtains, the anvil its deck. So the fix is
 * the missing plane rather than a brake on the departure - scud, which is what is
 * actually at this height over an ocean in wind, and which *thickens* as the
 * station climbs into it. The water still leaves. It just no longer leaves the
 * frame empty behind it, and the departure now reads as an arrival somewhere.
 */
function spray(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const sea = mix(v.paint.bottom, motif.base, 0.4);
  const foam = mix(v.paint.speck, motif.crest, 0.25);

  // Held at 0.88h rather than 0.96h. The sea is meant to sink away and it still
  // does, but past this the crest rows are culled faster than they are drawn and
  // the station loses the one thing it is named after two thirds of the way in.
  const seaY = v.h * (0.62 + v.progress * 0.26);
  const water = ctx.createLinearGradient(0, seaY - v.h * 0.12, 0, v.h);
  water.addColorStop(0, rgba(sea, 0));
  water.addColorStop(1, rgba(sea, 0.85 * v.alpha));
  ctx.fillStyle = water;
  ctx.fillRect(0, seaY - v.h * 0.12, v.w, v.h - seaY + v.h * 0.12);

  // Scud: the low torn cloud that lives between sixty and three hundred metres
  // over a windy sea, and the plane this station never had.
  //
  // It is drawn *under* the additive pass on purpose. Everything else in here is
  // `lighter`, because foam on water is light added to it; scud is the opposite -
  // it is opaque, it is between the player and the sky, and adding it would make
  // the frame glow exactly where it should be getting heavier. `flat` is high
  // because scud is torn and stretched by the same wind that is raising the
  // crests, not stacked like a fair-weather cumulus.
  //
  // It is the one element here that does not read `seaY`, which is the whole
  // point: the water's departure cannot take it with it. It grows with progress
  // instead, because that is what climbing into a cloud base looks like from
  // underneath.
  //
  // Two fills rather than the cumulus field's three, and squashed nearly flat.
  // That difference is not economy, it is identity: **station 3 is the cumulus
  // field**, and if this one draws stacked lumps with shadows on a deck under
  // them then two stations of six are the same picture at different altitudes.
  // Scud is what the same water looks like before it has built anything - torn
  // wide and thin by the wind that is raising the crests below it, lit flatly,
  // casting nothing on anything.
  //
  // The count and the span are the cumulus field's, though, and by measurement.
  // Five at a half-screen span read as clumps: their wrap positions collide two
  // to a slot and left whole thirds of the frame with no cloud in them at all -
  // the first cut of this fix moved the middle band from 0.95 to 0.93, which is
  // to say it drew nothing where the hole was.
  const scud = mix(v.paint.speck, v.paint.mid, 0.35);
  const lit = mix(v.paint.speck, motif.crest, 0.15);
  const thicken = 0.55 + v.progress * 0.45;
  for (let i = 0; i < 8; i++) {
    const h = hash(i * 53);
    // Faster than the cliff's fog and the cumulus deck, because this is the
    // nearest cloud in the act - a few hundred metres, not a few thousand.
    const y = wrapY(v, i, v.h * 0.44, 0.26 + h * 0.16);
    if (y < -v.h * 0.3 || y > v.h + v.h * 0.2) continue;
    const x = (hash(i * 17) * 1.3 - 0.15) * v.w + Math.sin(t * 0.07 + i) * v.w * 0.03;
    const wide = v.w * (0.4 + h * 0.4);
    bank(v, x, y, wide, scud, 0.17 * thicken, i * 11, 0.2);
    // The lit top is the half that goes on a weak phone, and the body is the half
    // that cannot: this is the cumulus field's own split, for the same reason.
    // Dropping the whole plane would hand the station back the empty frame this
    // was written to fix, and it would do it on exactly the hardware least able
    // to afford a picture made of nothing.
    if (v.quality > 0.55) {
      bank(v, x + wide * 0.05, y - wide * 0.035, wide * 0.82, lit, 0.13 * thicken, i * 7, 0.16);
    }
  }

  ctx.globalCompositeOperation = 'lighter';
  // Crests: shallow sines, world-anchored, at five rates. Nothing else in the
  // act says "you are barely off the water" this cheaply.
  for (let row = 0; row < 5; row++) {
    const rate = 0.5 + row * 0.16;
    const y = seaY + wrapY(v, row, v.h * 0.24, rate) * 0.5;
    if (y < seaY - 20 || y > v.h + 20) continue;
    const near = (y - seaY) / Math.max(1, v.h - seaY);
    ctx.strokeStyle = rgba(foam, (0.05 + near * 0.14) * v.alpha);
    ctx.lineWidth = 1 + near * 2.2;
    ctx.beginPath();
    for (let x = -10; x <= v.w + 10; x += 14) {
      const yy =
        y + Math.sin(x * 0.021 + t * 0.9 + row) * (3 + near * 7) + Math.sin(x * 0.008 - t * 0.5) * 4;
      if (x === -10) ctx.moveTo(x, yy);
      else ctx.lineTo(x, yy);
    }
    ctx.stroke();
  }

  // Spray torn off the tops. Sparse, and only on the near crests.
  if (v.quality > 0.55) {
    ctx.fillStyle = rgba(foam, 0.16 * v.alpha);
    ctx.beginPath();
    for (let i = 0; i < 22; i++) {
      const h = hash(i);
      const x = h * v.w;
      const y = seaY + wrapY(v, i, v.h * 0.06, 0.75) * 0.4;
      if (y < seaY || y > v.h) continue;
      const r = 0.8 + hash(i * 7) * 1.6;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 3. Over the tops of the fair-weather cumulus field.
 *
 * A cumulus is a column of rising air made visible, so a field of them is a map
 * of the whole lower atmosphere - and the only place in the game where the
 * scenery and the obstacles are the same substance seen at two distances. The
 * deck below is what the banks the flock is threading look like from further off,
 * which is the cheapest possible way to make an obstacle feel like a place.
 *
 * The one detail that carries it is the **shadow on the deck**: each far cloud
 * lays a dark patch on the layer under it, offset the way the light in this game
 * always falls. Take that away and the field is a pattern; leave it in and it is
 * a landscape with weather on it.
 */
function cumulus(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const white = mix(v.paint.speck, motif.crest, 0.2);
  const shade = mix(v.paint.mid, motif.base, 0.45);
  const deckY = v.h * (0.68 + v.progress * 0.24);

  // The haze layer the whole field sits on: everything below the flock is one
  // soft floor, so the clouds have something to be *above*.
  const floor = ctx.createLinearGradient(0, deckY - v.h * 0.22, 0, v.h);
  floor.addColorStop(0, rgba(mix(v.paint.bottom, white, 0.4), 0));
  floor.addColorStop(1, rgba(mix(v.paint.bottom, white, 0.4), 0.5 * v.alpha));
  ctx.fillStyle = floor;
  ctx.fillRect(0, deckY - v.h * 0.22, v.w, v.h - deckY + v.h * 0.22);

  for (let i = 0; i < 8; i++) {
    const h = hash(i * 13);
    // Slow: a cloud deck is hundreds of metres away, so it barely moves.
    const y = wrapY(v, i, v.h * 0.44, 0.18 + h * 0.07);
    if (y < -v.h * 0.4 || y > v.h + v.h * 0.3) continue;
    const x = (hash(i * 29) * 1.3 - 0.15) * v.w;
    const wide = v.w * (0.26 + h * 0.34) * (1 - v.progress * 0.3);
    // Its shadow on the layer under it, first...
    if (v.quality > 0.55) {
      bank(v, x + wide * 0.14, y + wide * 0.5, wide * 0.9, shade, 0.16, i * 5, 0.2);
    }
    // ...then the shadowed flank, then the lit top slightly above it. Three fills
    // and a cloud has a light direction and something to cast a shadow on.
    bank(v, x, y + wide * 0.1, wide, shade, 0.3, i * 3);
    bank(v, x, y, wide, white, 0.17 + 0.08 * h, i);
  }
}

/**
 * Station 5. The air becomes visible.
 *
 * Rain is the one station where the medium can be *seen* rather than inferred
 * from what it does to the flock, and that is why the rotors live here: the
 * player learns what turning air looks like at the moment air is drawable. The
 * streaks lean with their own local wind, so a squall reads before it is felt.
 */
function squall(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const grey = mix(v.paint.mid, motif.base, 0.5);
  const wet = mix(v.paint.tracer, motif.accent, 0.3);

  // Curtains of falling water: soft vertical bands, each leaning its own way.
  for (let i = 0; i < 4; i++) {
    const h = hash(i * 17);
    const x = (hash(i * 5) * 1.2 - 0.1) * v.w;
    const wide = v.w * (0.16 + h * 0.2);
    const g = ctx.createLinearGradient(x - wide, 0, x + wide, 0);
    g.addColorStop(0, rgba(grey, 0));
    g.addColorStop(0.5, rgba(grey, (0.16 + h * 0.12) * v.alpha));
    g.addColorStop(1, rgba(grey, 0));
    ctx.fillStyle = g;
    ctx.fillRect(x - wide, 0, wide * 2, v.h);
  }

  /*
   * Light coming through a break in the deck, far off to one side. A squall that
   * is *only* grey is a filter; a squall with one bright edge is weather.
   *
   * The rectangle starts where the glow has already run out, which is the whole
   * reason the number is written down rather than chosen. It used to start at
   * 0.3h - a fifth of a screen inside the live radius - so the break was cut off
   * flat across the entire width and the frame had a horizontal line in it at
   * exactly 0.3h, measured at 3.9 luminance units and visible on a phone. A radial
   * gradient has no edge in any direction; a `fillRect` through one has four.
   */
  const breakY = v.h * 0.78;
  const reach = v.h * 0.6;
  const breakX = v.w * (0.18 + 0.64 * hash(7));
  const bright = ctx.createRadialGradient(breakX, breakY, 0, breakX, breakY, reach);
  bright.addColorStop(0, rgba(mix(v.paint.speck, motif.accent, 0.4), 0.13 * v.alpha));
  bright.addColorStop(1, rgba(v.paint.speck, 0));
  ctx.fillStyle = bright;
  ctx.fillRect(0, breakY - reach, v.w, v.h - (breakY - reach));

  if (v.quality <= 0.5) return;
  // The rain itself. Falling *down* the screen while the flock climbs up it,
  // which is the only place in the game two things move in opposite directions
  // on purpose - and it is why this station feels like work.
  ctx.globalCompositeOperation = 'lighter';
  ctx.strokeStyle = rgba(wet, 0.2 * v.alpha);
  ctx.lineWidth = 1;
  ctx.beginPath();
  for (let i = 0; i < 90; i++) {
    const h = hash(i * 11);
    const lean = 4 + h * 7;
    const len = 12 + h * 22;
    const x = ((hash(i) + t * 0.02 * (0.5 + h)) % 1.2 - 0.1) * v.w;
    const y = wrapY(v, i, v.h * 0.05, 1.9 + h * 1.4) + ((t * 260 * (0.6 + h)) % v.h);
    const yy = ((y % (v.h + len)) + v.h + len) % (v.h + len) - len;
    ctx.moveTo(x, yy);
    ctx.lineTo(x + lean, yy + len);
  }
  ctx.stroke();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 6. Out of the top of the weather.
 *
 * An anvil spreads because the storm under it has hit a ceiling and cannot rise,
 * so this is the first station whose subject is a *limit*. Below: the sheet,
 * enormous and flat and lit hard from above, with the overshooting top of the
 * storm still pushing a dome through it. Above: the first sky in the game that is
 * emptier than the ground, and the first stars.
 */
function anvil(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const white = mix(v.paint.bottom, motif.crest, 0.35);
  const cold = mix(v.paint.top, motif.base, 0.4);
  const sheetY = v.h * (0.56 + v.progress * 0.3);

  // The overshooting top: the one dome pushing up through the sheet, drawn first
  // so the sheet spreads over its base the way it actually does.
  if (v.quality > 0.55) {
    bank(v, v.w * 0.36, sheetY - v.h * 0.06, v.w * 0.5, white, 0.1, 3, 0.55);
  }
  // The sheet, in three overlapping plates, very flat.
  for (let i = 0; i < 3; i++) {
    const h = hash(i * 23);
    bank(
      v,
      v.w * (0.2 + h * 0.6),
      sheetY + i * v.h * 0.09,
      v.w * (0.75 + h * 0.5),
      white,
      0.13 + 0.06 * h,
      i * 7,
      0.16,
    );
  }
  /*
   * ...and the light lying along the top of it.
   *
   * The gradient peaks *on* the sheet and dies below it, and it has to, because
   * the first cut ran 0 → 0.24 and then stopped where the fill stopped. A linear
   * gradient is only edgeless at the ends it reaches zero at: this one reached its
   * brightest exactly at the bottom of its own `fillRect`, so it left a hard
   * horizontal line the full width of the screen at `sheetY + 0.15h` - measured on
   * the frame at **15.2 luminance units**, by a long way the largest seam in the
   * act, and plainly visible with the storm top a third of a screen below it.
   *
   * Same defect as the estuary's shafts (§18, second visual review, #9) and the
   * squall's break below, and worth naming as a class: a live gradient clipped by
   * the rectangle that draws it. The rule is that the fill has to end where the
   * gradient is already zero, never where it is loudest.
   */
  const lit = ctx.createLinearGradient(0, sheetY - v.h * 0.2, 0, sheetY + v.h * 0.15);
  lit.addColorStop(0, rgba(white, 0));
  // 0.2 / 0.35: the sheet's own top edge, in the gradient's coordinates.
  lit.addColorStop(0.571, rgba(white, 0.24 * v.alpha));
  lit.addColorStop(1, rgba(white, 0));
  ctx.fillStyle = lit;
  ctx.fillRect(0, sheetY - v.h * 0.2, v.w, v.h * 0.35);

  // The dark above. Not black - this is 11 km, not orbit - but the first frame in
  // the campaign where the top of the screen is emptier than the bottom.
  const space = ctx.createLinearGradient(0, 0, 0, v.h * 0.6);
  space.addColorStop(0, rgba(cold, 0.5 * v.alpha));
  space.addColorStop(1, rgba(cold, 0));
  ctx.fillStyle = space;
  ctx.fillRect(0, 0, v.w, v.h * 0.6);

  // The brightest stars only, and only late in the station: this is where the
  // sky first admits there is something behind it.
  stars(v, 0.16 + v.progress * 0.2, 30, 0);
}
