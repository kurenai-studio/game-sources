import type { BackdropView } from './Backdrop';
import type { Motif } from './Motif';
import { drawPlanet } from './Orbit';
import { mix, rgba } from './Paint';
import { bank, hash, stars, wrapY } from './SkyParts';

/**
 * Slowblue: act V's six frames - the campaign coming back.
 *
 * Everything in the render layer so far has been about *leaving*: light running
 * out, sound thinning, the ground receding, the sky going black. This is the
 * first module where all of that reverses, and it reverses in one specific order
 * that the whole act is built on.
 *
 * **The planet stops being scenery and becomes the floor.** Act IV drew the Earth
 * as a limb across the bottom of the frame, and `Orbit.drawPlanet` is reused here
 * unchanged for the first three stations - the same curve, the same radius, the
 * same band of air along it - because the swarm has not gone anywhere else. It
 * keeps rising the whole way, from act IV's last frame at `rise` 1.0 to 1.38 at
 * the end of the aurora, until the body fills the bottom of the picture and stops
 * being a thing in the frame at all; and from the plasma on there is no limb,
 * because what is below is simply *below*, which is what arriving means.
 *
 * > That paragraph was three separate lies and they are worth leaving written
 * > down, because none of them is visible to any assertion in the suite. The act
 * > opened at `rise` 0.86 against act IV's closing 1.0, so the limb **stepped 61 px
 * > back down the frame** at the campaign's turn - the planet retreating at the
 * > first frame of the act about falling into it. The night side then passed a bare
 * > constant, so the horizon sat at 0.781h and did not move for the whole station,
 * > measured at 0.781h at all four of its sections. And the aurora had no planet at
 * > all, three stations before the prose says it goes. The instrument agrees with
 * > the arithmetic to three decimals wherever the limb is drawn, which is how all
 * > three were found: an absence, a freeze and a step are none of them a seam.
 *
 * **The air comes back as something you can see.** From the night side onward
 * every station has more in the frame than the one before it - airglow, then
 * curtains, then fire, then dust, then cloud - which is the exact inverse of the
 * emptying act III spent six stations on.
 *
 * **It gets hot, once.** The plasma is the only frame in the game that is warm,
 * and it is deliberately the loudest thing the renderer ever does. Everything
 * after it cools toward the grey of the first raincloud, which is where act VI
 * begins.
 */

export function drawReentry(kind: string, motif: Motif, v: BackdropView): void {
  if (v.alpha < 0.01) return;
  switch (kind) {
    case 'deorbit':
      return deorbit(motif, v);
    case 'nightside':
      return nightside(motif, v);
    case 'auroraBelow':
      return auroraBelow(motif, v);
    case 'plasma':
      return plasma(motif, v);
    case 'meteordust':
      return meteordust(motif, v);
    case 'nucleus':
      return nucleus(motif, v);
  }
}

/**
 * Streaming: the picture of speed, and act V's shared signature.
 *
 * Everything from the deorbit down is passing the swarm faster than anything has
 * in the campaign, and it all leaves the frame the same way - *upward*, because
 * this is the first act that falls. `rate` is how fast, `warm` how much of the
 * fire is on it. Shared by four stations so that going faster reads as one
 * continuous thing rather than as four separate effects.
 */
function streaks(v: BackdropView, rate: number, colour: [number, number, number], alpha: number): void {
  const ctx = v.ctx;
  if (v.quality <= 0.5) return;
  ctx.globalCompositeOperation = 'lighter';
  ctx.lineCap = 'round';
  ctx.strokeStyle = rgba(colour, alpha * v.alpha);
  ctx.lineWidth = 1.2;
  ctx.beginPath();
  for (let i = 0; i < 34; i++) {
    const h = hash(i * 83);
    const y = wrapY(v, i, v.h * 0.22, rate * (0.7 + h * 0.8));
    const x = v.w * (0.02 + hash(i * 19) * 0.96);
    const len = v.h * (0.04 + h * 0.14) * rate * 0.5;
    ctx.moveTo(x, y);
    // Trailing back up the frame: the swarm is going down, so everything else
    // appears to go up.
    ctx.lineTo(x + (h - 0.5) * 6, y - len);
  }
  ctx.stroke();
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 1. The deorbit.
 *
 * Still orbit, and drawn with orbit's own planet, unchanged: this is the last
 * frame of act IV as much as the first of act V, and the handover works because
 * nothing about the picture announces it. The one difference is the direction of
 * travel, and the only thing that says so is that the stars have begun to slide
 * the other way.
 */
function deorbit(motif: Motif, v: BackdropView): void {
  stars(v, 0.9, 64, 31, true);
  // The same limb act IV ended on, and it starts at exactly the height it ended
  // at: `Overview` closes on rise 1.0 and this opens on 1.0. The handover between
  // two acts is the one place in the campaign where a step in this number cannot
  // be read as the planet moving, because the picture is cut there anyway - so it
  // was 0.86, and the Earth fell 61 px away from the swarm on the first frame of
  // the act that falls into it.
  drawPlanet(v, motif, 1 + v.progress * 0.1, 0.5);
  streaks(v, 0.5, mix(v.paint.speck, motif.crest, 0.4), 0.05);
}

/**
 * Station 2. The night side.
 *
 * Coming down over the unlit half, and the last genuinely quiet frame in the
 * campaign's second half. The only light in it is the swarm and, far below,
 * weather lighting itself up from the inside - which is the first time the game
 * shows the player the thing they are about to be flying *through*.
 */
function nightside(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  stars(v, 1, 76, 37, true);
  // Still climbing. This used to be a bare constant - the one station on this
  // planet whose horizon did not move at all, for 3590 px of course, in the act
  // whose subject is that the ground is coming up.
  const surfaceY = drawPlanet(v, motif, 1.1 + v.progress * 0.16, 0);
  const below = v.h - surfaceY;

  if (v.quality <= 0.5) return;
  ctx.globalCompositeOperation = 'lighter';
  // Storms, seen from above at night: a cell lights up from the inside for a
  // fraction of a second and goes out. Nothing else in the frame moves.
  //
  // Laid out under the limb rather than at a fixed height in the frame, which is
  // the same correction act IV's cities needed and for the same reason: these sit
  // *on* the planet, so they belong to whatever is left of the picture under it.
  // At 0.72h..0.96h against a horizon at 0.781h, two of the seven were centred
  // above the limb and a third bloomed across it - lightning in vacuum, on every
  // frame of the station, and nothing in the suite is in a position to notice a
  // storm cell in the wrong place.
  const flash = mix(motif.accent, [200, 225, 255], 0.5);
  for (let i = 0; i < 7; i++) {
    const h = hash(i * 97);
    const r = v.w * (0.06 + h * 0.08);
    // Clear of the limb by its own glow radius *and* by the sag of the horizon
    // across the frame, so no part of a cell is ever in the vacuum - not at the
    // middle of the picture and not at its edges, where the ground is lower. The
    // sag is a property of the planet rather than of the screen: at a radius of
    // 2.6 w it is w/21, near enough a twentieth of the width.
    const clear = r + v.w * 0.05;
    const y = surfaceY + clear + Math.max(0, below - clear - r) * hash(i * 13);
    const x = (((hash(i * 31) + -v.cameraY * 0.00012) % 1.2) - 0.1) * v.w;
    const period = 4 + h * 7;
    const phase = ((t + h * period) % period) / period;
    // A hard, brief bloom: sin^12 is dark for nine tenths of its cycle.
    const glow = Math.pow(Math.sin(phase * Math.PI), 12);
    if (glow < 0.02) continue;
    const g = ctx.createRadialGradient(x, y, 0, x, y, r);
    g.addColorStop(0, rgba(flash, 0.5 * glow * v.alpha));
    g.addColorStop(1, rgba(flash, 0));
    ctx.fillStyle = g;
    ctx.fillRect(x - r, y - r, r * 2, r * 2);
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 3. The aurora, from inside it.
 *
 * The same light act IV looked down on, met from underneath - and the first
 * moment in the campaign where the player is somewhere they have already been.
 * Nothing marks it. The curtains that were ribbons hanging below the swarm are
 * now full-height columns going past it, which is what an aurora is when you are
 * in the middle of one rather than above it.
 *
 * It is the last calm band before the air arrives, and it is the most beautiful
 * thing in act V on purpose: the loudest frame in the game is next, and it needs
 * something quiet immediately in front of it.
 */
function auroraBelow(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const t = v.time;
  stars(v, 0.7, 46, 43, true);
  // The last limb in the campaign, at the top of its climb: two hundred
  // kilometres is above the airglow layer and well above where an aurora starts,
  // so the ground and its line of air are under the curtains, not behind them.
  // This station had no planet at all, three stations before the module's own
  // header says the limb goes.
  drawPlanet(v, motif, 1.26 + v.progress * 0.12, 0);

  ctx.globalCompositeOperation = 'lighter';
  const green = mix(motif.accent, [80, 255, 165], 0.45);
  const columns = v.quality > 0.55 ? 7 : 4;
  // Half the curtain's length, and the same 1.2 screens the old rectangle stood
  // in - so what changed is the shape of the falloff and not how much frame a
  // curtain occupies.
  const tall = v.h * 0.6;
  for (let i = 0; i < columns; i++) {
    const h = hash(i * 59);
    // Full height, and rising through the frame: the swarm is falling past them.
    const drift = wrapY(v, i, v.h * 1.3, 0.3 + h * 0.2);
    const x = v.w * (0.05 + hash(i * 23) * 0.9) + Math.sin(t * 0.15 + i * 1.7) * v.w * 0.04;
    const wide = v.w * (0.03 + h * 0.06);
    /*
     * A radial gradient in a squashed frame, and not a rectangle filled with a
     * vertical one - which is what this was, and which is the same defect as the
     * anvil's light band turned through ninety degrees.
     *
     * The old fill ran its emission *down* the column, correctly edgeless at both
     * ends where the stops reach zero, and then let `fillRect` supply the other
     * two edges, where nothing was fading toward anything. A curtain is 23 to 70
     * px wide and 1.2 screens tall, so both of those edges are in shot for the
     * whole height of the picture: a shape with no sides is a `fillRect` through a
     * live gradient however the gradient runs. Measured as **11.07 luminance units
     * of coherent column step** with every sampled row of the frame agreeing on
     * the sign, against a campaign that reads 0 to 4.69 - and 9.36 on a second
     * curtain in the same frame. On the glass it was flat green stripes with hard
     * vertical sides, in the station the act calls the most beautiful thing in it.
     *
     * The seam pass could never have caught it. It scans rows for a step every
     * column agrees on, and this is a step every *row* agrees on: the two are
     * transposes and the suite only had one of them. `e2e/acts.spec.ts` has both
     * now.
     *
     * The two circles are offset along the major axis on purpose, which is the one
     * thing a linear gradient could do here and a centred radial could not: the
     * bright point sits below the middle, so the fade upward is long and the fade
     * downward is short. That is the same asymmetry the old 0.55 stop had, and it
     * is where the emission actually is - strongest where the particles are
     * hitting the densest air, which is below.
     */
    ctx.save();
    ctx.translate(x, drift);
    ctx.scale(wide / tall, 1);
    // Peak alpha up from 0.06+h·0.05, and the factor is arithmetic rather than
    // taste: a cone over an ellipse is a third of the cylinder over it, where the
    // old fill was a slab of constant alpha across its whole width and a triangle
    // only down its length - so the same numbers laid down about half the light.
    // The station is the quiet one immediately in front of the loudest frame in
    // the game and the fix is not allowed to cost it a twentieth of its
    // brightness. Checked on the frame rather than assumed: the four sections read
    // 32.8, 32.7, 33.8 and 31.9 before and 32.1, 32.0, 33.2 and 31.1 after, and
    // the missing two thirds of a unit is the planet's unlit body standing where
    // sky used to be. Horizontal spread is *up*, 17.2/10.8/6.9 to 18.0/13.6/7.5
    // across the three bands, because a slab of constant alpha has none.
    const g = ctx.createRadialGradient(0, tall * 0.2, 0, 0, 0, tall);
    g.addColorStop(0, rgba(green, (0.115 + h * 0.095) * v.alpha));
    // The green's own colour at zero, where a violet `crown` used to be mixed
    // every frame for a stop that cannot carry it. Act IV's aurora had the same
    // dead line and the measurement is there.
    g.addColorStop(1, rgba(green, 0));
    ctx.fillStyle = g;
    // Square in the squashed frame, so it is the curtain's own bounding box on
    // the screen; the corners are past the last stop and therefore already zero.
    ctx.fillRect(-tall, -tall, tall * 2, tall * 2);
    ctx.restore();
  }
  streaks(v, 0.9, green, 0.07);
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 4. Re-entry.
 *
 * The loudest frame in the game, and the only one that is hot. Everything is on
 * fire, the sky behind it has gone white, and the swarm is the brightest thing
 * there is - which is literally true here rather than a lighting choice: at this
 * point the carried gold is a meteor, and a meteor is a light source.
 *
 * Three layers and nothing else. A shock front bowed across the frame ahead of
 * the swarm, the wake streaming back up past it, and the whole picture pulsing on
 * the breath - because the one thing this station must not do is become noise.
 * The breath is what keeps the loudest moment in the campaign a meditative one.
 */
function plasma(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const fire = mix(motif.base, [255, 140, 40], 0.5);
  const core = mix(motif.crest, [255, 240, 210], 0.4);

  // The shock: a broad bowed wash across the lower frame, which is where the air
  // the swarm is compressing actually is.
  const shockY = v.h * (0.62 - v.progress * 0.12);
  const g = ctx.createRadialGradient(v.w * 0.5, shockY + v.h * 0.5, 0, v.w * 0.5, shockY + v.h * 0.5, v.h * 0.9);
  g.addColorStop(0, rgba(core, 0.3 * v.alpha));
  g.addColorStop(0.35, rgba(fire, 0.22 * v.alpha));
  g.addColorStop(1, rgba(fire, 0));
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, v.w, v.h);

  // The wake. Fast, long and warm - the fastest thing the renderer draws.
  streaks(v, 2.4, mix(fire, core, 0.4), 0.16);

  // ...and the pulse. Slow, on the breath, and the reason this station is not
  // just a bright rectangle: the fire swells and settles at the rate the whole
  // game has been breathing at since the trench floor.
  if (v.quality > 0.55) {
    // The real breath, not a sine that happens to be slow. `t * 0.57` was an
    // 11-second period only by coincidence of reading and drifted out of phase
    // with the bed within a minute; `v.breath` is the clock itself.
    const swell = v.breath;
    for (let i = 0; i < 3; i++) {
      const y = v.h * (0.5 + i * 0.16) - v.progress * v.h * 0.1;
      bank(v, v.w * 0.5, y, v.w * (1.3 + i * 0.4), fire, (0.05 + swell * 0.05) / (1 + i), i * 11, 0.18);
    }
  }
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Station 5. Cooling.
 *
 * The fire is going out. What is left is a warm grey haze with the last of the
 * orange in the bottom of it, and dust - which is what the swarm has become, and
 * what every noctilucent cloud on the planet is built on. Act III's fifth station
 * has been quietly promising this frame from eighty kilometres up.
 *
 * The first station in the act with weather in it: cloud tops, very far below,
 * lit from above for the first time since the anvil.
 */
function meteordust(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const warm = mix(v.paint.bottom, motif.accent, 0.35);
  const grey = mix(v.paint.mid, motif.base, 0.45);

  // The last of the fire, low and going.
  const emberY = v.h * (0.86 + v.progress * 0.14);
  const g = ctx.createLinearGradient(0, emberY - v.h * 0.5, 0, v.h);
  g.addColorStop(0, rgba(warm, 0));
  g.addColorStop(1, rgba(warm, (0.28 - v.progress * 0.18) * v.alpha));
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = g;
  ctx.fillRect(0, emberY - v.h * 0.5, v.w, v.h);
  streaks(v, 1.3, warm, 0.08);
  ctx.globalCompositeOperation = 'source-over';

  // Cloud tops, a very long way down and coming up. The first weather the player
  // has seen from *above* since the anvil, and the last time they will.
  const deckY = v.h * (1.02 - v.progress * 0.24);
  for (let i = 0; i < 5; i++) {
    const h = hash(i * 29);
    const x = (hash(i * 47) * 1.3 - 0.15) * v.w;
    const y = deckY + wrapY(v, i, v.h * 0.4, 0.12) * 0.14;
    if (y > v.h + v.h * 0.3) continue;
    bank(v, x, y, v.w * (0.4 + h * 0.4), grey, 0.16 + h * 0.08, i * 7, 0.2);
  }
}

/**
 * Station 6. The nucleus.
 *
 * Cold, wet and grey: the dust has finished being a meteor and started being the
 * thing a raindrop condenses on. The whole of act VI is in this frame in
 * miniature - the deck the swarm is about to fall into, seen from just above it,
 * with the first hint of rain already coming out of its underside.
 *
 * There are no stars. This is the first frame since the anvil with a *ceiling* to
 * it, and losing the stars is how the campaign says the sky is closed again.
 */
function nucleus(motif: Motif, v: BackdropView): void {
  const ctx = v.ctx;
  const white = mix(v.paint.speck, motif.crest, 0.3);
  const shade = mix(v.paint.mid, motif.base, 0.5);

  // The deck the swarm is falling into. It rises through the station until it
  // fills the bottom half of the frame, which is where act VI opens.
  const deckY = v.h * (0.72 - v.progress * 0.3);
  const floor = ctx.createLinearGradient(0, deckY - v.h * 0.1, 0, v.h);
  floor.addColorStop(0, rgba(white, 0));
  floor.addColorStop(0.45, rgba(mix(white, shade, 0.4), 0.4 * v.alpha));
  floor.addColorStop(1, rgba(shade, 0.6 * v.alpha));
  ctx.fillStyle = floor;
  ctx.fillRect(0, deckY - v.h * 0.1, v.w, v.h - deckY + v.h * 0.1);

  for (let i = 0; i < 6; i++) {
    const h = hash(i * 37);
    const x = (hash(i * 53) * 1.3 - 0.15) * v.w;
    const y = deckY + wrapY(v, i, v.h * 0.36, 0.22) * 0.3;
    if (y < deckY - v.h * 0.3 || y > v.h + v.h * 0.3) continue;
    // Lit tops, shadowed flanks: the last time in the campaign the light comes
    // from above the cloud rather than through it.
    bank(v, x, y + v.w * 0.05, v.w * (0.36 + h * 0.34), shade, 0.24, i * 5, 0.34);
    bank(v, x, y, v.w * (0.36 + h * 0.34), white, 0.2 + h * 0.08, i * 3, 0.34);
  }

  // The first rain in the campaign, coming out of the underside of the deck a
  // long way below. Faint, and it is the whole of the next act.
  if (v.quality <= 0.55) return;
  ctx.globalCompositeOperation = 'lighter';
  ctx.strokeStyle = rgba(mix(v.paint.tracer, white, 0.4), 0.08 * v.progress * v.alpha);
  ctx.lineWidth = 1;
  ctx.beginPath();
  for (let i = 0; i < 40; i++) {
    const h = hash(i * 61);
    const x = v.w * hash(i * 11);
    const y = deckY + v.h * (0.1 + h * 0.5);
    if (y > v.h) continue;
    ctx.moveTo(x, y);
    ctx.lineTo(x + 2, y + 8 + h * 12);
  }
  ctx.stroke();
  ctx.globalCompositeOperation = 'source-over';
}
