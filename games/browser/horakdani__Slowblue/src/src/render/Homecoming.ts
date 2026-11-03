import { TAU } from '../core/math';
import type { BackdropView } from './Backdrop';
import type { Motif } from './Motif';
import { mix, rgba, type Rgb } from './Paint';
import { hash, wrapY } from './SkyParts';

/**
 * Slowblue: act VII's six frames - the campaign closing its own circle.
 *
 * These are act I's waters met going the other way, and the whole module is built
 * on one inversion that nothing in the game ever explains.
 *
 * **The light is behind you now.** Every water backdrop in `Backdrop.ts` put its
 * light *ahead*, because the surface was where the shoal was going. Here the
 * surface is what the swarm is leaving, so the light is at the top of the frame
 * and it drains upward and out across six stations - which is why the last three
 * of these have no external light in them at all.
 *
 * **What is left is the swarm's own.** Act I's rock is lit from above by a
 * surface six thousand metres away. Act VII's is lit from *inside* by what the
 * player has been carrying since the estuary, so as the daylight goes the frame
 * does not go black - it goes warm. That is the single visual statement the
 * ending makes, and it is made entirely in the backdrops and the motif table
 * rather than in any text.
 *
 * **The last frame is the first frame.** `trenchHome` is `Backdrop.walls` with
 * the gold added: the same violet-black, the same vents, the same embers, and the
 * palette is within a few values of the one the campaign opened on. The player is
 * supposed to notice that themselves, and the game never says it.
 */

export function drawHomecoming(kind: string, motif: Motif, v: BackdropView): void {
  if (v.alpha < 0.01) return;
  switch (kind) {
    case 'brackish':
      return brackish(motif, v);
    case 'sunlitFall':
      return sunlitFall(motif, v);
    case 'twilightFall':
      return twilightFall(motif, v);
    case 'deepsea':
      return deepsea(motif, v);
    case 'snow':
      return snow(motif, v);
    case 'trenchHome':
      return trenchHome(motif, v);
  }
}

/**
 * Marine snow: the campaign's last shared element, and the thing that makes act
 * VII a descent rather than act I upside down.
 *
 * Every speck falls at the swarm's own pace, so for the first time in the game
 * the world is not going past the player - it is going *with* them. `density`
 * grows through the act, because that is what actually happens: marine snow is
 * what is left of everything that lived nearer the surface, and there is more of
 * it the deeper you go.
 */
function falling(v: BackdropView, density: number, colour: Rgb, alpha: number): void {
  const ctx = v.ctx;
  if (v.quality <= 0.5) return;
  const t = v.time;
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = rgba(colour, alpha * v.alpha);
  ctx.beginPath();
  const n = Math.round(46 * density);
  for (let i = 0; i < n; i++) {
    const h = hash(i * 73);
    /*
     * Descending with the swarm rather than streaming past it, which is the whole
     * point of the station: for the first time the player is going with the world
     * instead of through it.
     *
     * Slowblue: rate 1 in `wrapY` is an element standing *still in the water*, not one
     * moving with the camera - so 0.9 to 1.25 meant the snow was world-anchored at
     * best and rising at worst, and on the measured spread three specks in four
     * were travelling upward. A flake that falls with the swarm is one that barely
     * moves on the glass, which is a rate near zero.
     */
    const y = wrapY(v, i, v.h * 0.3, 0.1 + h * 0.22);
    const x = v.w * hash(i * 19) + Math.sin(t * 0.18 + i * 0.7) * 7;
    const r = 0.6 + h * 1.8;
    ctx.moveTo(x + r, y);
    ctx.arc(x, y, r, 0, TAU);
  }
  ctx.fill();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * The gold, alive again - and the one element in act VII that is not falling.
 *
 * `falling` is what is *left* of life nearer the surface; this is life itself,
 * hanging in the water at the depth it lives at while the swarm sinks past it, so
 * its `wrapY` rate is at and just above 1 where the snow's is near zero. A body
 * that holds its depth reads as alive for that reason alone, before anything is
 * drawn: everything else in seven acts either streams past the player or falls
 * with them.
 *
 * They pulse, out of phase with each other, on one shared path - so a whole plane
 * of larvae is one fill however many there are, the same economy the vents and
 * the snow use. Nothing here allocates.
 */
function drifting(
  v: BackdropView,
  colour: Rgb,
  alpha: number,
  n: number,
  rate: number,
  size: number,
  seed: number,
): void {
  const ctx = v.ctx;
  const t = v.time;
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = rgba(colour, alpha * v.alpha);
  ctx.beginPath();
  for (let i = 0; i < n; i++) {
    const h = hash(i * seed);
    const y = wrapY(v, i, v.h * 0.34, rate + h * 0.14);
    const x = v.w * hash(i * seed + 7) + Math.sin(t * 0.4 + i * 1.7) * 11;
    const r = size * (0.55 + h);
    // A bell, contracting and relaxing: the whole of what a larva does, and the
    // one thing in the frame with its own clock rather than the camera's.
    //
    // The `moveTo` is not decoration. Without it every bell is joined to the last
    // one by the line `ellipse` opens with, and twenty of them fill the frame with
    // one enormous polygon - which is what the first build of this did, and it
    // took the station's mean from 84 to 112 before anybody looked at the frame.
    ctx.moveTo(x + r, y);
    ctx.ellipse(x, y, r, r * (0.72 + 0.28 * Math.sin(t * 1.1 + i * 2.3)), 0, 0, TAU);
  }
  ctx.fill();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 1. The salt line.
 *
 * The last frame with air over it. Fresh water riding on salt, the surface still
 * visible overhead, and the first living things the campaign has had since the
 * shoal broke through it - plankton, drifting up past the swarm because the swarm
 * is going down.
 *
 * Slowblue: that last clause was true of the comment and of nothing on the screen.
 * The station drew the receding surface, the caustics under it and marine snow,
 * and act VI's estuary hands over to it on the design's own sentence - *where
 * fresh water meets salt, the gold reappears as small living forms* - so the one
 * thing this station is *for* was the one thing missing from it. Measured, the
 * middle third of the frame read 2.78 / 1.72 / 1.80 across its three sections,
 * which is the vacuum's range: the deorbit reads 0.80 and those are stations
 * whose subject is that there is nothing there. Two planes of them now, near and
 * far, and they are the first thing since the surface that is neither weather nor
 * wreckage.
 */
function brackish(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const light = mix(v.paint.speck, motif.accent, 0.3);

  // The surface, above and receding: the mirror of act I's approaching ceiling.
  const ceilY = v.h * (0.16 - v.progress * 0.3);
  const sky = ctx.createLinearGradient(0, ceilY - v.h * 0.2, 0, ceilY + v.h * 0.5);
  ctx.globalCompositeOperation = 'lighter';
  sky.addColorStop(0, rgba(light, (0.26 - v.progress * 0.18) * v.alpha));
  sky.addColorStop(1, rgba(light, 0));
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, v.w, ceilY + v.h * 0.5);

  // The caustic net on the underside of it, going out as the swarm sinks. Act I's
  // surface earned this picture; this is the last time the campaign draws it.
  if (v.quality > 0.55 && ceilY > -v.h * 0.3) {
    ctx.strokeStyle = rgba(light, (0.05 - v.progress * 0.04) * v.alpha);
    ctx.lineWidth = 1.3;
    ctx.beginPath();
    for (let i = 0; i < 5; i++) {
      const base = ceilY + i * 26;
      for (let x = -10; x <= v.w + 10; x += 16) {
        const y = base + Math.sin(x * 0.019 + t * 0.36 + i) * 9 + Math.sin(x * 0.007 - t * 0.2) * 12;
        if (x === -10) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
    }
    ctx.stroke();
  }
  ctx.globalCompositeOperation = 'source-over';

  // The living gold: the far plane always, the near one where there is a phone to
  // draw it on, which is the same rung `falling`'s third plane is held to.
  const alive = mix(v.paint.speck, motif.accent, 0.6);
  drifting(v, alive, 0.14, 30, 1, 2.4, 23);
  if (v.quality > 0.55) drifting(v, alive, 0.24, 14, 1.1, 5, 41);

  falling(v, 0.5, light, 0.1);
}

/**
 * Station 2. The sunlit zone, from above.
 *
 * Act I's blue met going the other way, and the last station with real daylight
 * in it. The shafts come down from behind the swarm rather than reaching toward
 * it - the same light, the same water, and the direction of the whole campaign
 * reversed in one detail.
 */
function sunlitFall(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const light = mix(v.paint.speck, motif.crest, 0.3);

  ctx.globalCompositeOperation = 'lighter';
  const wash = ctx.createLinearGradient(0, -v.h * 0.05, 0, v.h * 0.75);
  wash.addColorStop(0, rgba(light, (0.12 - v.progress * 0.07) * v.alpha));
  wash.addColorStop(1, rgba(light, 0));
  ctx.fillStyle = wash;
  ctx.fillRect(0, 0, v.w, v.h * 0.75);

  /*
   * Shafts from above, and they *shorten* through the station: this is the light
   * running out, drawn as it actually runs out.
   *
   * Slowblue: they used to be `fillRect`s filled by a gradient running *across* them,
   * which makes the two sides edgeless and leaves nothing at all varying down the
   * column - so each shaft ended at full strength in the space of one pixel, at
   * exactly the row `end` puts it. That is act VI's canopy one act on and the
   * third time the campaign has shipped the same defect: measured inside a
   * shaft's own columns, the largest step in the frame is 5.0 to 7.2 units and it
   * lands on that shaft's own `end` to three decimals. No sweep could see it -
   * `seam` and `rib` want the whole frame to agree and a shaft is a seventh of the
   * width - and the local step act VI built and threw away is swamped here by the
   * swarm, which reads 8 to 23 in the same columns.
   *
   * So the shaft is a fade in every direction instead: a radial gradient in a
   * squashed frame - the nacreous lens and the aurora curtain, stood on end - with
   * the circle pushed *up* its own axis so the bright part is off the top of the
   * frame and the long tail is the one running down the water. The fill dies at
   * the same `end` the rect used to stop at, so the light still runs out on the
   * station's own schedule; it just no longer has a bottom.
   */
  if (v.quality > 0.5) {
    for (let i = 0; i < 5; i++) {
      const h = hash(i * 43);
      const x = v.w * (0.08 + ((i * 0.27 + h * 0.1) % 0.86));
      const half = v.w * (0.06 + h * 0.05);
      const end = v.h * (0.75 - v.progress * 0.4) * (0.7 + h * 0.4);
      // How far up its own length the light sits, and the length that keeps the
      // fade dying where `end` always was.
      const bias = 0.35;
      const span = end / (1 - bias);
      const g = ctx.createRadialGradient(0, -bias, 0, 0, -bias, 1);
      /*
       * Twice the peak of the rectangle it replaces, and the multiplier is
       * arithmetic rather than taste: the old fill was a constant alpha all the
       * way down the shaft's middle, and this one falls off linearly from 0.65 of
       * peak at the top of the frame to nothing at `end`, which averages 0.325.
       * The same number would have laid down a third of the light.
       */
      g.addColorStop(0, rgba(light, (0.085 + h * 0.05) * v.alpha));
      g.addColorStop(1, rgba(light, 0));
      ctx.save();
      ctx.transform(1, 0, Math.sin(t * 0.05 + i) * 0.14, 1, 0, 0);
      ctx.translate(x, 0);
      ctx.scale(half, span);
      ctx.fillStyle = g;
      // The unit box the gradient reaches zero on, and no larger: every side of
      // this rect is at alpha 0, and so is every corner.
      ctx.fillRect(-1, -bias - 1, 2, 2);
      ctx.restore();
    }
  }
  ctx.globalCompositeOperation = 'source-over';

  falling(v, 0.7, light, 0.11);
}

/**
 * Station 3. The twilight zone.
 *
 * The boundary act I's light line drew from underneath, met from above. There it
 * was the last depth that could still see structure in the surface; here it is
 * the last depth where there is anything overhead to see. Below this line the
 * only light in the campaign is the one the player brought.
 */
function twilightFall(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const light = mix(v.paint.speck, motif.accent, 0.4);
  const edgeY = v.h * (0.3 - v.progress * 0.42);

  ctx.globalCompositeOperation = 'lighter';
  const wash = ctx.createLinearGradient(0, -v.h * 0.1, 0, edgeY + v.h * 0.3);
  wash.addColorStop(0, rgba(light, (0.07 - v.progress * 0.06) * v.alpha));
  wash.addColorStop(1, rgba(light, 0));
  ctx.fillStyle = wash;
  ctx.fillRect(0, 0, v.w, Math.max(0, edgeY + v.h * 0.3));

  // Three broken traces, exactly as act I's light line drew them - the same
  // boundary, the same dashes, and the swarm is passing through it downward.
  if (edgeY > -v.h * 0.2) {
    ctx.lineCap = 'round';
    for (let band = 0; band < 3; band++) {
      ctx.strokeStyle = rgba(light, (0.045 - band * 0.01) * (1 - v.progress) * v.alpha);
      ctx.lineWidth = 1.1 + band * 1.2;
      ctx.beginPath();
      let drawing = false;
      for (let x = -8; x <= v.w + 8; x += 7) {
        const gap = (Math.floor(x / 7) + band * 5) % 13 < 2;
        const y = edgeY + band * 5 + Math.sin(x * 0.024 + t * 0.11 + band) * 7;
        if (gap) drawing = false;
        else if (!drawing) {
          ctx.moveTo(x, y);
          drawing = true;
        } else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
  }
  ctx.globalCompositeOperation = 'source-over';

  falling(v, 0.9, light, 0.12);
}

/**
 * Station 4. The deep sea.
 *
 * The first station that cannot be lost, and the first with nothing overhead at
 * all. Act I's black water was *empty on purpose* and this is its answer: the
 * same darkness, the same bioluminescence coming up out of it - and a warmth in
 * the middle of the frame that act I's version could not have had, because in act
 * I nothing down here was carrying a light.
 */
function deepsea(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const live = mix(v.paint.speck, motif.accent, 0.5);

  ctx.globalCompositeOperation = 'lighter';
  // Bioluminescence: long dark cycles with one slow swell, world-anchored so a
  // light that came up beside the swarm stays where it was. Act I's `empty`, and
  // the campaign is quoting itself.
  for (let i = 0; i < 10; i++) {
    const y = wrapY(v, i, 240, 0.9);
    if (y < -30 || y > v.h + 30) continue;
    const period = 5.5 + hash(i * 31) * 5;
    const phase = ((t + hash(i * 7) * period) % period) / period;
    const glow = Math.pow(Math.sin(phase * Math.PI), 4);
    if (glow < 0.02) continue;
    const x = v.w * (0.05 + hash(i * 13 + 2) * 0.9);
    const r = 2 + hash(i * 3) * 3;
    const halo = ctx.createRadialGradient(x, y, 0, x, y, r * 7);
    halo.addColorStop(0, rgba(live, 0.45 * glow * v.alpha));
    halo.addColorStop(0.25, rgba(live, 0.1 * glow * v.alpha));
    halo.addColorStop(1, rgba(live, 0));
    ctx.fillStyle = halo;
    ctx.fillRect(x - r * 7, y - r * 7, r * 14, r * 14);
  }
  ctx.globalCompositeOperation = 'source-over';

  // Pressure: the sides close in, very slightly, edgeless, exactly as the trench
  // floor's do. The campaign is walking back into its own first frame.
  const sides = ctx.createLinearGradient(0, 0, v.w, 0);
  sides.addColorStop(0, rgba(v.paint.bottom, 0.34 * v.alpha));
  sides.addColorStop(0.46, rgba(v.paint.bottom, 0));
  sides.addColorStop(0.54, rgba(v.paint.bottom, 0));
  sides.addColorStop(1, rgba(v.paint.bottom, 0.34 * v.alpha));
  ctx.fillStyle = sides;
  ctx.fillRect(0, 0, v.w, v.h);

  falling(v, 1.1, live, 0.12);
}

/**
 * Station 5. Marine snow.
 *
 * The one frame in the game where the whole world is falling the way the player
 * is, and the station that exists entirely for that picture. Everything in it
 * descends at the swarm's own pace: for the first time in seven acts the player
 * is not passing through the world, they are going down with it.
 *
 * There is nothing else in the frame. That is the design.
 */
function snow(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const warm = mix(v.paint.speck, motif.accent, 0.45);

  // The one light source: the swarm, implied by a very soft warm rise in the
  // middle of the frame. Nothing else is lit, because nothing else can be.
  ctx.globalCompositeOperation = 'lighter';
  const g = ctx.createRadialGradient(v.w * 0.5, v.h * 0.42, 0, v.w * 0.5, v.h * 0.42, v.h * 0.6);
  g.addColorStop(0, rgba(warm, 0.06 * v.alpha));
  g.addColorStop(1, rgba(warm, 0));
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, v.w, v.h);
  ctx.globalCompositeOperation = 'source-over';

  // Three planes of it, at very slightly different rates, so the descent has
  // depth in it rather than being one sheet of dots.
  falling(v, 1.6, warm, 0.16);
  falling({ ...v, cameraY: v.cameraY * 0.72 }, 1.2, v.paint.speck, 0.1);
  if (v.quality > 0.55) falling({ ...v, cameraY: v.cameraY * 1.35 }, 0.8, warm, 0.07);
}

/**
 * Station 6. The trench floor.
 *
 * Six thousand metres, and the first frame of the game.
 *
 * This is `Backdrop.walls` with one thing added. The same violet-black pressure
 * closing in from both sides with no edge in it anywhere, the same floor gradient,
 * the same three vents on their slow flicker, the same embers climbing a black
 * wall - because it is the same trench, and the palette it is drawn in is within
 * a few values of the one the campaign opened on.
 *
 * What is added is the gold. In act I the vents were the only warm thing down
 * here; now the player is carrying more light than the vents have, and the floor
 * comes up to meet it. The camera and the background dissolve into the title
 * screen from here, and only then does the player understand that they did not
 * play a one-way ascent but a circuit.
 */
function trenchHome(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  const dark = mix(v.paint.bottom, motif.base, 0.7);

  // Pressure, both sides, edgeless. Act I's numbers.
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

  // ...and the floor. In act I this closed the slot *behind* the shoal; here it
  // is ahead, rising, and it is the last thing in the campaign.
  const floorY = v.h * (1.02 - v.progress * 0.3);
  const floor = ctx.createLinearGradient(0, v.h, 0, floorY - v.h * 0.3);
  floor.addColorStop(0, rgba(dark, 0.7 * v.alpha));
  floor.addColorStop(1, rgba(dark, 0));
  ctx.fillStyle = floor;
  ctx.fillRect(0, Math.max(0, floorY - v.h * 0.3), v.w, v.h);

  ctx.globalCompositeOperation = 'lighter';
  // The vents, on act I's own flicker. Three per screen at most, dim enough to be
  // a colour in the wall rather than a light in the room.
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

    if (v.quality <= 0.55) continue;
    // Embers, still rising. The one thing in this frame that goes the other way
    // from everything else, exactly as it did in act I.
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

  // The floor coming up warm to meet what the player is carrying. This is the one
  // thing act I's trench did not have, and it is the whole ending.
  const glow = ctx.createLinearGradient(0, v.h, 0, floorY - v.h * 0.42);
  glow.addColorStop(0, rgba(motif.accent, 0.14 * v.progress * v.alpha));
  glow.addColorStop(1, rgba(motif.accent, 0));
  ctx.fillStyle = glow;
  ctx.fillRect(0, Math.max(0, floorY - v.h * 0.42), v.w, v.h);
  ctx.globalCompositeOperation = 'source-over';

  falling(v, 0.9, mix(v.paint.speck, motif.accent, 0.5), 0.12);
}
