import { TAU, clamp } from '../core/math';
import { BIRDS, traceBird } from './Flock';
import { filmHash, filmRamp, type Film, type FilmView } from './Films';
import { mix, rgba, type Rgb } from './Paint';

/**
 * Slowblue: the gift at the top of the air.
 *
 * Act I's ending is an arrival. Six thousand metres of climbing toward light,
 * paid off with the one thing the water never had - a sky, and a horizon, and
 * air. It works because it gives the player the thing the whole act was about.
 *
 * The first act II ending did not do that. It faded the blue out, held on a dark
 * frame and let some motes go, which is a *diagram* of a handover rather than a
 * reward for eighty kilometres of flying. Worse, it withheld the one thing act II
 * had spent the entire climb earning.
 *
 * Because there is a payoff up here and it is the best one in the game: **from
 * the top of the atmosphere you can finally see the atmosphere.** The whole act
 * has been a slow argument about a medium that gives less the higher you go, and
 * the last thing the player is shown is that medium from the outside - the Earth
 * as a curve, and the entire sky they just climbed through resolved into one
 * bright line a fortieth of the frame thick along the top of it. Everything the
 * game has ever happened in, at once, thinner than the flock is wide.
 *
 * Five movements, on the renderer's own clock, deterministic, no random calls
 * anywhere, holding on the final frame so the results dialog arrives over a
 * picture rather than instead of one:
 *
 *   1. `hold`    - the wind stops. The last shreds of the anvil sheet the flock
 *                  has been flying through stream back past it, slow, stop, and
 *                  go out. The flock levels and locks its wings. That is the
 *                  first true stillness in a game about staying inside moving
 *                  air, and it is a thing the player *watches happen* rather
 *                  than a thing the frame simply is.
 *   2. `clear`   - the air runs out. The last haze drains off the bottom of the
 *                  frame, the sky goes to black above, and the stars resolve in
 *                  order of brightness - not switched on, *arrived at*.
 *   3. `limb`    - the world becomes a shape. The Earth's curve draws itself
 *                  across the bottom of the frame, and the air above it resolves
 *                  into the thin graded band this act has been inside all along.
 *   4. `sunrise` - the light comes back. The sun rises *through* the limb: the
 *                  disc is cut by the planet's own circle, so what the player
 *                  sees is a horizon being cleared rather than a shape growing.
 *                  Then one slow sweep crosses the frame, catching every wing.
 *   5. `carry`   - the hold. The flock glides along the limb, and a thin line of
 *                  pod-gold rises out of it and keeps going, past the top of the
 *                  frame, where there is no longer anything to fly in. That is
 *                  the handover, and it is also act III's first frame.
 *
 * > The fourth movement spent a long time not happening. The disc was drawn after
 * > the world, with a comment saying the world occluded it by draw ordering - and
 * > the ordering said the opposite, so the sun was painted on top of the planet
 * > every frame and never met the horizon at all. What it did instead was open
 * > from radius zero in the middle of the sky, which is a dot expanding. A
 * > comment cannot occlude anything; a clip can, and the geometry is now shared
 * > by the two methods that need to agree about where the edge is.
 *
 * ## Reduced motion
 *
 * Four of the five movements are things arriving - a field of stars filling in,
 * an arc opening under a band, a disc crossing a line, a stream leaving - and
 * none of those is vestibular, so none of them changes. What goes is the star
 * twinkle and the flutter along each shred, which are texture.
 *
 * The one real question is the first movement, because a full-frame flow of torn
 * cloud is exactly the thing this setting exists to spare a body, and it is also
 * the only movement whose *subject* is that flow coming to rest. Taking it out
 * would take the movement out. So it is shortened in space rather than in time:
 * the shreds run a fifth as far, and because each one is drawn as a smear of the
 * ground it is covering, they come out a fifth as long for free. The deceleration
 * stays entirely legible and there is no screen-scale motion left in the frame to
 * be pulled along by - which is arguably the truer of the two pictures anyway,
 * since what this movement is about is a flow that is nearly over.
 *
 * ## High contrast
 *
 * The film ends on black, so nothing here is light on light - but two things in it
 * are *dim* on black, and dim on black is the same problem wearing the other sign.
 * The band is one of them and it is the whole point of the picture. It has almost
 * no headroom left in brightness, because at a fortieth of the frame it is already
 * drawn nearly opaque to buy back what the thinness costs, so what this setting
 * does instead is **flatten its falloff**: the whole thickness of the band comes up
 * to the value of its hottest end, which turns a graded glow into a ribbon with a
 * boundary, and the hairline under it goes hard. Its thinness is the fact the
 * picture exists to deliver, so width is the one axis nothing may touch.
 *
 * The other is the flock: the birds fade as the air runs out, which is the film
 * saying they cannot go on, and at the bottom of that fade thirteen unlit wings on
 * space are very close to nothing at all. They keep the fade and get a floor under
 * it. The closing trace, which is the last thing on screen and the first thing act
 * III opens over, trades its soft flank for its core - same two fills, weighted the
 * other way.
 *
 * What comes off is the sunrise's halo. It is a bloom the width of the screen over
 * the darkest frame in act II, which is exactly the wash that flattens a band a
 * fortieth of the screen tall into the black around it.
 */

/** Movement lengths, in seconds. */
export const RELEASE_HOLD = 1.9;
export const RELEASE_CLEAR = 2.4;
export const RELEASE_LIMB = 2.9;
export const RELEASE_SUNRISE = 3.1;
export const RELEASE_CARRY = 4.6;

export const RELEASE_CLEAR_AT = RELEASE_HOLD;
export const RELEASE_LIMB_AT = RELEASE_CLEAR_AT + RELEASE_CLEAR;
/** The moment the sun clears the limb. The audio's resolution belongs here. */
export const RELEASE_SUNRISE_AT = RELEASE_LIMB_AT + RELEASE_LIMB;
export const RELEASE_CARRY_AT = RELEASE_SUNRISE_AT + RELEASE_SUNRISE;
export const RELEASE_TOTAL = RELEASE_CARRY_AT + RELEASE_CARRY;
/** Film seconds the stream is held before act III opens on it. See `Surfacing.SURFACE_TAIL`. */
export const RELEASE_TAIL = 2.6;

export type ReleasePhase = 'idle' | 'hold' | 'clear' | 'limb' | 'sunrise' | 'carry';

/** The one place in the game that is allowed to be space. */
const VOID: Rgb = [2, 3, 10];
const STAR: Rgb = [235, 242, 255];
/** Pod-gold: the carried life keeps the colour the rings had. */
const MOTE: Rgb = [255, 233, 178];
/** Birds against the dark: pale, cool, unlit. */
const WING: Rgb = [226, 238, 250];
/**
 * The anvil sheet, one stop brighter than the zone paints it.
 *
 * Act II ends at eleven kilometres, where the bright thing in the frame is the
 * top of the storm *below* the flock (`AIR_SPECS.anvil`, `bottom`). The shreds in
 * the first movement are the last of it, so they are its colour - the film keeps
 * its own copy rather than reading `v.paint`, because what movement 1 is about is
 * the air the flock has just left, not the air it happens to be in.
 */
const SHRED: Rgb = [186, 208, 232];

/**
 * The atmosphere, from outside it, in five stops.
 *
 * This is the picture the act exists to arrive at, so the colours are the real
 * ones rather than a gradient that looks nice: the troposphere reddened by the
 * whole depth of itself, the ozone layer's own blue above that, then the last of
 * the scattering going violet and out. Nothing in the game has ever been drawn
 * with this much saturation and nothing else ever will be - it is one band a
 * fortieth of the screen tall, and its scarcity is most of its force.
 */
const AIR_BAND: readonly (readonly [number, Rgb])[] = [
  [0, [255, 146, 72]],
  [0.22, [255, 208, 150]],
  [0.44, [186, 226, 255]],
  [0.7, [86, 150, 240]],
  [1, [30, 40, 120]],
];
/** The ground under the band: dark, blue, and not detailed. It is night down there. */
const EARTH: Rgb = [8, 22, 48];
const SUN: Rgb = [255, 246, 214];

/**
 * How thick the whole atmosphere is drawn, as a fraction of the frame height.
 *
 * A fortieth, which is twenty-one pixels on a phone, and it is the number three
 * paragraphs of this file are about. It spent a while written as `0.075` while
 * every comment near it claimed a fortieth; the comments were right and the code
 * was three times too generous, which is the one way this picture can be wrong
 * without looking broken. What the thinness costs in legibility is bought back in
 * saturation below, because saturation is free and width is the thesis.
 */
const AIR_THICK = 0.025;

/**
 * The heading the flock holds until it leans away: up, and a little across.
 *
 * Two consumers, one fact. `drawFlock` points the birds along it and `drawShreds`
 * streams the torn cloud back down it, because the cloud is the medium the flock
 * is moving through and the two cannot disagree about which way that is.
 */
const GLIDE_X = 0.35;
const GLIDE_Y = -1;

/** Gliding birds in the closing line. */
const GLIDERS = 13;
/** Motes in the rising stream. */
const MOTES = 32;
/** Stars in the field. */
const STARS = 64;
/** Torn cloud still streaming past in the first movement. */
const SHREDS = 9;

export class Release implements Film {
  private t = -1;

  /**
   * The middle of the frame, and a little high: the flock has to have air under
   * it and the rising stream has to have somewhere to go.
   */
  readonly anchor = [0.3, 0.74] as const;

  get active(): boolean {
    return this.t >= 0;
  }

  get phase(): ReleasePhase {
    if (this.t < 0) return 'idle';
    if (this.t < RELEASE_CLEAR_AT) return 'hold';
    if (this.t < RELEASE_LIMB_AT) return 'clear';
    if (this.t < RELEASE_SUNRISE_AT) return 'limb';
    if (this.t < RELEASE_CARRY_AT) return 'sunrise';
    return 'carry';
  }

  /**
   * 0..1 how completely the film has replaced the world. The renderer dims the
   * live layers against it exactly as it fades the underwater ones against
   * `Surfacing.sky` - one number, one meaning.
   */
  get night(): number {
    return filmRamp(this.t, RELEASE_CLEAR_AT, RELEASE_CLEAR * 0.85);
  }

  /** How far the air has run out, 0..1. Drives the sky, the stars and the shreds. */
  private get empty(): number {
    if (this.t < 0) return 0;
    return filmRamp(this.t, 0, RELEASE_HOLD + RELEASE_CLEAR);
  }

  /**
   * The darkening the live world takes under the film. Non-zero from the first
   * movement: the light leaving is the film's subject, and a world that stays
   * bright under a sky going out is a stage with the houselights on.
   */
  get dusk(): number {
    if (this.t < 0) return 0;
    return clamp(this.empty * 0.55 + this.night * 0.4, 0, 0.92);
  }

  /**
   * How far the film has taken the frame off the live world.
   *
   * `dusk`, under the name the other six know it by. This one is deliberately
   * non-zero from the first movement rather than from the last: what the film is
   * *about* is the light leaving, so the world it is standing on has to lose it
   * at the same time.
   */
  get veil(): number {
    return this.dusk;
  }

  /** True once the night is deep enough for a title to sit in it. */
  get settled(): boolean {
    return this.night > 0.35;
  }

  /** Space. The sun is a sliver on the limb and the heading is nowhere near it. */
  readonly daylight = false;

  /** True once the flock has let go of what it was carrying. */
  get released(): boolean {
    return this.t >= RELEASE_CARRY_AT;
  }

  /** True once the rising motes have been held long enough for act III to take them. */
  get handedOver(): boolean {
    return this.t >= RELEASE_CARRY_AT + RELEASE_TAIL;
  }

  begin(): void {
    if (this.t >= 0) return;
    this.t = 0;
  }

  reset(): void {
    this.t = -1;
  }

  /** Holds on the last frame rather than ending: the dialog arrives over a picture. */
  update(dt: number): void {
    if (this.t < 0) return;
    this.t = Math.min(RELEASE_TOTAL, this.t + dt);
  }

  draw(v: FilmView): void {
    if (this.t < 0) return;
    const ctx = v.ctx;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const empty = this.empty;
    // The shreds go under the darkening rather than over it: they are the live
    // world's own last light, so the thing that takes the light has to take them.
    if (this.t < RELEASE_CLEAR_AT + 0.4) this.drawShreds(v);
    this.drawSpace(v, empty);
    this.drawStars(v, empty);
    if (this.t > RELEASE_LIMB_AT - 0.4) this.drawWorld(v);
    if (this.t > RELEASE_SUNRISE_AT - 0.2) this.drawSun(v);
    this.drawFlock(v, empty);
    // Last, and over the birds: the gold is what the frame is about by now, and
    // a wing crossing in front of it is the film changing its mind at the end.
    if (this.released) this.drawStream(v);
    ctx.restore();
  }

  /**
   * Where the planet is this frame. One circle, and everything on the horizon is
   * measured off it.
   *
   * `drawWorld` draws it, `drawWorld` has to keep the band off the *inside* of it,
   * and `drawSun` has to be cut by it. Three uses, so it cannot be three private
   * guesses: a sun clearing a limb it is not actually touching is precisely what
   * happens when the code that draws the horizon and the code that rises through
   * it each own a copy of the number.
   *
   * A bigger radius later in the movement is a flatter horizon, i.e. the player
   * still climbing away from it.
   */
  private limb(v: FilmView): { cx: number; cy: number; r: number; p: number } {
    const p = filmRamp(this.t, RELEASE_LIMB_AT - 0.4, RELEASE_LIMB * 0.8);
    const r = v.w * (1.9 + p * 1.4);
    // The planet's centre, far below the frame.
    return { cx: v.w * 0.5, cy: v.h * (0.93 + 0.22 * (1 - p)) + r, r, p };
  }

  /**
   * Clips to everything the planet is not: the frame, with the Earth punched out
   * of it by a subpath wound the other way.
   *
   * Two things need this and both would be wrong without it. The sun has to be
   * cut by the horizon or it is not rising through anything. And the band is a
   * radial gradient on the planet's own centre, which **clamps to its first stop
   * inside its inner radius** - so a fill that reaches below the limb paints the
   * whole Earth the colour of the hottest end of its own atmosphere. That is the
   * same trap `tests/canvas.ts` keeps `ccw` around for, and it had the night side
   * of this planet lit warm.
   */
  private clipToSpace(v: FilmView, g: { cx: number; cy: number; r: number }): void {
    const ctx = v.ctx;
    ctx.beginPath();
    ctx.rect(0, 0, v.w, v.h);
    // Its own subpath, wound the other way. The `moveTo` is not decoration: an
    // arc appended to an open subpath is joined to it by a line first, and a
    // clip is not a place to be relying on that line cancelling itself out.
    ctx.moveTo(g.cx + g.r, g.cy);
    ctx.arc(g.cx, g.cy, g.r, 0, TAU, true);
    ctx.clip();
  }

  /**
   * Movement 1: the wind stops, and it stops in front of you.
   *
   * The flock has spent the act inside the top of a storm, so what is still going
   * past it at the start of the film is the anvil sheet, torn into filaments and
   * smeared along the direction of travel - which is what cloud looks like from
   * above when you are moving through it faster than it is moving.
   *
   * Every filament decelerates at a constant rate and is finished with a fifth of
   * the movement still to run, so the stillness is *held* rather than merely
   * reached - a flow that stops on the last frame of its own movement has not
   * stopped, it has been cut. And the distance is measured backwards from where
   * each shred comes to rest rather than forwards from where it starts, which is
   * the only arrangement that guarantees the stop happens somewhere the player is
   * looking. Measured forwards, most of them were off the bottom of the frame
   * before the deceleration was half done, and what the movement came to was a
   * flush of streaks leaving and then an empty frame that had never visibly
   * stopped. Measured backwards, all nine are on screen for the whole of it.
   *
   * Their light then goes out on `empty` rather than on their own clock, because
   * it is not the wind that takes it - it is the air, and the air is what the
   * second movement is about. They are gone a fifth of a second into it.
   */
  private drawShreds(v: FilmView): void {
    const fade = clamp(1 - (this.empty - 0.18) * 3.3, 0, 1);
    if (fade <= 0.01) return;
    const ctx = v.ctx;
    // Backwards along the heading, normalised: the medium goes past the animal in
    // exactly the direction the animal is not going.
    const mag = Math.hypot(GLIDE_X, GLIDE_Y);
    const dx = GLIDE_X / mag;
    const dy = GLIDE_Y / mag;
    // How much of the run is left. Speed is 2(1-u) of its own start, i.e. one
    // deceleration held all the way to zero, which is a thing coming to rest
    // rather than a thing being faded out while still moving.
    const u = clamp(this.t / (RELEASE_HOLD * 0.8), 0, 1);
    const left = (1 - u) * (1 - u);
    const count = v.quality <= 0.5 ? 5 : SHREDS;
    const t = v.time;

    ctx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < count; i++) {
      const seed = filmHash(i * 23 + 5);
      const lane = filmHash(i * 37 + 13);
      const drop = filmHash(i * 53 + 29);
      // Where this one stops, and how far back up the flow it still is.
      const gone = v.h * (0.2 + seed * 0.3);
      const cx = v.w * (-0.1 + lane * 1.2) + dx * gone * left;
      const cy = v.h * (0.05 + drop * 0.95) + dy * gone * left;
      // The drawn length is a smear: the shred, plus the ground it is covering
      // while you look at it. So the filaments visibly shorten as they slow and
      // end as the torn wisps they always were - which is most of what makes the
      // stop legible, and it is the same honesty rule the motes' streaks obey in
      // the last movement.
      const len = v.h * (0.035 + seed * 0.055) + gone * (1 - u) * 0.22;
      // Alpha along the filament, so it has torn ends rather than cut ones, and
      // the bright part is off-centre: nothing torn is symmetrical.
      const g = ctx.createLinearGradient(
        cx - dx * len * 0.5,
        cy - dy * len * 0.5,
        cx + dx * len * 0.5,
        cy + dy * len * 0.5,
      );
      const peak = 0.22 * fade * (0.55 + seed * 0.7);
      g.addColorStop(0, rgba(SHRED, 0));
      g.addColorStop(0.3 + seed * 0.3, rgba(SHRED, peak));
      g.addColorStop(1, rgba(SHRED, 0));
      ctx.strokeStyle = g;
      ctx.lineWidth = 0.9 + seed * 1.8;
      ctx.beginPath();
      for (let k = 0; k <= 5; k++) {
        const along = (k / 5 - 0.5) * len;
        // A kink from the index, so no two shreds are the same line, plus a
        // flutter from the clock, which is the only part of this reduced motion
        // takes out.
        const off =
          Math.sin(k * 1.7 + i * 2.3) * (1.6 + seed * 3) +
          Math.sin(t * 1.1 + i + k * 0.7) * 1.1;
        const px = cx + dx * along - dy * off;
        const py = cy + dy * along + dx * off;
        if (k === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Movements 1-2, and the film's ground: the blue running out.
   *
   * It deepens from the top, because that is the direction the air thins in and
   * the direction the flock has been going for eighty kilometres. By the end of
   * the second movement the frame is space with a haze at the bottom of it.
   */
  private drawSpace(v: FilmView, empty: number): void {
    const ctx = v.ctx;
    const reach = v.h * (0.62 + 0.5 * empty);
    const g = ctx.createLinearGradient(0, 0, 0, reach);
    g.addColorStop(0, rgba(VOID, 0.86 * empty));
    g.addColorStop(0.6, rgba(VOID, 0.6 * empty));
    g.addColorStop(1, rgba(VOID, 0));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, v.w, reach);
  }

  /**
   * The stars resolve in order of brightness.
   *
   * Which is what actually happens when a sky darkens, and it is the whole reason
   * this is a movement rather than a fade: a field that appears all at once is a
   * texture being switched on, and a field that fills in from the brightest is a
   * sky you are watching come out. `born` is one comparison against the star's
   * own magnitude, and it does all of that work.
   *
   * A low-quality frame keeps the brightest third of them rather than none. The
   * field carries a movement, and a movement cannot be a quality tier - the whole
   * of the second half of this film is a dark frame, and a dark frame with nothing
   * in it is not the same picture with less detail, it is a different one. Cutting
   * on magnitude rather than on index means what survives is exactly the top of
   * the same order the movement arrives in, so it is the same sky, shorter.
   */
  private drawStars(v: FilmView, empty: number): void {
    const ctx = v.ctx;
    const presence = clamp(empty * 1.15, 0, 1);
    if (presence <= 0.02) return;
    const faintest = v.quality <= 0.5 ? 0.24 : 1;
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = rgba(STAR, 0.62 * presence);
    ctx.beginPath();
    for (let i = 0; i < STARS; i++) {
      const magnitude = filmHash(i * 13);
      if (magnitude > faintest) continue;
      const born = clamp(presence * 1.35 - magnitude, 0, 1);
      if (born <= 0) continue;
      const x = filmHash(i * 31) * v.w;
      const hy = filmHash(i * 47 + 7);
      // Crowded toward the top: the dark is deepest where the air is thinnest.
      const y = hy * hy * v.h * 0.78;
      const tw = 0.76 + 0.24 * Math.sin(v.time * (0.45 + magnitude) + i * 2.2);
      const r = (0.45 + (1 - magnitude) * 1.15) * born * tw;
      if (r <= 0.05) continue;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Movement 3, and the reason the whole file exists.
   *
   * The curve of the planet, and above it the atmosphere as a band a fortieth of
   * the frame thick. The arc *settles* rather than appearing: its radius opens
   * outward as it arrives, so the horizon reads as something the player is rising
   * away from rather than as a shape that was drawn on the glass.
   *
   * The band is the thing to look at. A radial gradient centred on the planet's
   * own centre gives a curved gradient in one fill and needs no per-strip maths at
   * all, because that is exactly what a limb *is*. It is drawn very nearly opaque:
   * at a fortieth of the frame there is not enough of it for anything to be paid
   * for in area, so it is all paid for in saturation - additive at this alpha, the
   * hot end of `AIR_BAND` arrives on screen as the colour it actually is.
   *
   * The one thing that breathes on the held frame is this band's thickness, by
   * three per cent, which is under the threshold of a thing you watch and over the
   * threshold of a thing you feel. It is the right object for it: the atmosphere
   * is what the act was inside, and a held frame in this game breathes.
   */
  private drawWorld(v: FilmView): void {
    const ctx = v.ctx;
    const g = this.limb(v);
    const p = g.p;
    if (p <= 0.01) return;
    const air = v.h * AIR_THICK * p * (1 + (v.breath - 0.5) * 0.06);

    // High contrast cannot make this brighter - it is already close to opaque -
    // so it flattens the falloff instead: the whole thickness comes up to the
    // value of its hottest end, and a graded glow becomes a ribbon with an edge.
    const peak = 0.92;
    const falloff = 0.52;
    ctx.save();
    // ...and the band must not reach below the horizon. See `clipToSpace`.
    this.clipToSpace(v, g);
    ctx.globalCompositeOperation = 'lighter';
    const glow = ctx.createRadialGradient(g.cx, g.cy, g.r, g.cx, g.cy, g.r + air);
    for (const [stop, colour] of AIR_BAND) {
      glow.addColorStop(stop, rgba(colour, (peak - stop * falloff) * p));
    }
    glow.addColorStop(1, rgba(AIR_BAND[4]![1], 0));
    ctx.fillStyle = glow;
    const top = g.cy - g.r - air;
    ctx.fillRect(0, top, v.w, Math.max(0, v.h - top));
    ctx.restore();

    // ...and the planet under it, which is night and has no detail in it. A
    // textured Earth would be a different game's screenshot, and an airglow arc
    // or a terminator would be a second thin line competing with the one thin
    // line the picture exists to deliver.
    ctx.fillStyle = rgba(EARTH, 0.9 * p);
    ctx.beginPath();
    ctx.arc(g.cx, g.cy, g.r, -Math.PI * 0.72, -Math.PI * 0.28);
    ctx.lineTo(v.w + 40, v.h + 40);
    ctx.lineTo(-40, v.h + 40);
    ctx.closePath();
    ctx.fill();

    // One hairline on the edge itself: the surface is a hard line from up here,
    // and it is the only hard edge in the picture - which is why high contrast
    // spends most of what it has on it.
    ctx.strokeStyle = rgba(mix(AIR_BAND[1]![1], STAR, 0.4), 0.32 * p);
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(g.cx, g.cy, g.r, -Math.PI * 0.72, -Math.PI * 0.28);
    ctx.stroke();
  }

  /**
   * Movement 4: the sun clears the limb, and the light comes back.
   *
   * The disc is a fixed size and it *travels*. It starts with its top edge exactly
   * tangent to the horizon under it - zero area, nothing to pop - and rises until
   * about a third of it is showing, cut the whole way by the planet's own circle.
   * That cut is the movement: a circle whose bottom is a horizon is a sunrise, and
   * a circle that grows is a dot.
   *
   * The climb is the one ramp in this film that is not a smoothstep. From orbit a
   * limb crossing has nothing to accelerate and nothing to settle into - it is the
   * observer that is moving, at the speed they were already going - so it is
   * linear, and easing it would be a lie the eye can actually see at this size.
   *
   * Then the sweep, which is the point of the rest of it: a band of light crossing
   * left to right that brightens whatever it is over, so it passes the birds one
   * at a time and each of them lights as it goes. It is the only moment in the
   * game where a single individual is picked out of the flock, and it lasts about
   * a second.
   */
  private drawSun(v: FilmView): void {
    const ctx = v.ctx;
    const g = this.limb(v);
    const p = filmRamp(this.t, RELEASE_SUNRISE_AT - 0.2, RELEASE_SUNRISE * 0.7);
    const rr = v.w * 0.072;
    const x = v.w * 0.72;
    // Where the horizon actually is under the sun, which is not where it is under
    // the middle of the frame: the limb curves, and a disc cut by a circle has to
    // start from that circle or it starts from a guess.
    const dx = x - g.cx;
    const surface = g.cy - Math.sqrt(Math.max(1, g.r * g.r - dx * dx));
    const climb = clamp((this.t - RELEASE_SUNRISE_AT + 0.2) / (RELEASE_SUNRISE * 0.72), 0, 1);
    const y = surface + rr - climb * rr * 0.75;
    ctx.globalCompositeOperation = 'lighter';

    // The bloom around it, wide and weak: the sun at the top of the atmosphere
    // has no haze to bloom in, so almost all of this is the eye rather than air.
    // It is also the one full-screen wash in the film, so high contrast takes most
    // of it: an eye artefact over the black the band has to be read against is
    // precisely the thing that stops it being read. It is not clipped - glare is
    // in the observer, and the observer can see the planet.
    const soft = 1;
    const halo = ctx.createRadialGradient(x, y, 0, x, y, v.w * (0.35 + p * 0.55));
    halo.addColorStop(0, rgba(SUN, 0.5 * p * soft));
    halo.addColorStop(0.25, rgba(mix(SUN, AIR_BAND[0]![1], 0.5), 0.16 * p * soft));
    halo.addColorStop(1, rgba(SUN, 0));
    ctx.fillStyle = halo;
    ctx.fillRect(0, 0, v.w, v.h);

    // The disc, cut by the Earth. Its brightness does not ramp: a sun does not
    // fade up, and it does not have to here, because at the start of the climb
    // there is none of it above the line to fade.
    ctx.save();
    this.clipToSpace(v, g);
    ctx.fillStyle = rgba(SUN, 0.95);
    ctx.beginPath();
    ctx.arc(x, y, rr, 0, TAU);
    ctx.fill();
    ctx.restore();

    // The sweep. A soft vertical band crossing the frame once, and it is the only
    // moving light in the ending.
    const cross = clamp((this.t - RELEASE_SUNRISE_AT - 0.5) / 1.5, 0, 1);
    if (cross > 0 && cross < 1) {
      const swell = Math.sin(cross * Math.PI);
      const bx = v.w * (1.15 - cross * 1.5);
      const wide = v.w * 0.3;
      const sweep = ctx.createLinearGradient(bx - wide, 0, bx + wide, 0);
      sweep.addColorStop(0, rgba(SUN, 0));
      sweep.addColorStop(0.5, rgba(SUN, 0.1 * swell));
      sweep.addColorStop(1, rgba(SUN, 0));
      ctx.fillStyle = sweep;
      ctx.fillRect(bx - wide, 0, wide * 2, v.h);
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Movement 5, and the point of the whole film: the carried life goes on alone.
   *
   * The motes rise from where the flock stopped, accelerating - a wing is exactly
   * what they no longer need - on staggered starts, so the release reads as a
   * stream rather than as a firework. Once the early ones leave the frame the
   * stream keeps running at a trickle, and what is left is the trace.
   *
   * The trace is the last image of act II and the first image of act III, and for
   * a long time it was neither, because it was twenty-eight pixels of gold at nine
   * hundredths of an alpha - a held frame that read as empty black with the birds
   * gone. It is two plumes rather than one column, which is the only way a thin
   * line on a dark ground is ever legible: a soft flank so it has air around it
   * instead of an edge, and inside that a narrow core, bright, which is the line
   * itself. High contrast trades the first for the second. It breathes by three
   * per cent, with the band.
   *
   * None of it is additive. The gold is the campaign's one visual constant and the
   * rule for it is `source-over`, last, opaque, because additive gold burns to
   * white over anything already bright. This film is the one that could have got
   * away with breaking it - over black the two modes give the same numbers - which
   * is exactly why it does not: the only place they diverge here is where the
   * trace crosses the sunrise's halo, and that is the frame the act ends on.
   */
  private drawStream(v: FilmView): void {
    const ctx = v.ctx;
    const since = this.t - RELEASE_CARRY_AT;
    for (let i = 0; i < MOTES; i++) {
      const seed = (i * 0.6180339887) % 1;
      const u = since - seed * 2.6;
      if (u <= 0) continue;
      const climb = 66 * u + 46 * u * u;
      const x = v.x + (seed - 0.5) * 26 + Math.sin(u * 1.7 + i) * (4 + seed * 5);
      const y = v.y - 6 - climb;
      if (y < -30) continue;
      const fade = clamp(u * 2.6, 0, 1) * clamp((y + 20) / (v.h * 0.3), 0, 1);
      if (fade <= 0.01) continue;
      const r = 1.1 + seed * 1.4;
      ctx.fillStyle = rgba(MOTE, 0.9 * fade);
      ctx.beginPath();
      ctx.arc(x, y, r, 0, TAU);
      ctx.fill();
      // The streak is the distance it covered in the last tenth of a second: the
      // same honesty rule every entrained mote in the game obeys.
      const vy = 66 + 92 * u;
      ctx.strokeStyle = rgba(MOTE, 0.4 * fade);
      ctx.lineWidth = Math.max(0.8, r * 0.7);
      ctx.beginPath();
      ctx.moveTo(x, y + vy * 0.1);
      ctx.lineTo(x, y);
      ctx.stroke();
    }

    // The line they leave: soft flank first, so it has air around it rather than
    // an edge, then the narrow core, which is the line itself.
    const settle = clamp(since / 1.6, 0, 1);
    const swell = 1 + (v.breath - 0.5) * 0.06;
    this.drawPlume(v, v.w * 0.075 * swell, 0.13 * settle);
    this.drawPlume(v, v.w * 0.016 * swell, 0.3 * settle);
  }

  /**
   * One layer of the trace: a wedge, closing to nothing at the release point and
   * opening out through the top of the frame.
   *
   * A wedge rather than a column for two reasons, and the second one is the
   * reason. Thirty-two motes with a lateral spread and a hundred pixels a second
   * of climb leave a plume, not a bar. And a bar has to *end* somewhere: this one
   * ended ten pixels above the release point, on a straight horizontal edge fifty
   * pixels wide, which was invisible at nine hundredths of an alpha and would not
   * have stayed invisible at three tenths. On a frame the player sits on for as
   * long as they like, that would have been the only ruled line in the picture. A
   * wedge that closes to a nib where the motes leave has no edge to find.
   *
   * The gradient runs across it, so the sides are soft and the nib - where the
   * shape is narrower than the gradient's own core - stays at full value. Which is
   * correct: the brightest part of a stream is where it comes from.
   */
  private drawPlume(v: FilmView, half: number, alpha: number): void {
    const ctx = v.ctx;
    const foot = Math.max(0, v.y - 10);
    const root = half * 0.12;
    const g = ctx.createLinearGradient(v.x - half, 0, v.x + half, 0);
    g.addColorStop(0, rgba(MOTE, 0));
    g.addColorStop(0.5, rgba(MOTE, alpha));
    g.addColorStop(1, rgba(MOTE, 0));
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.moveTo(v.x - root, foot);
    ctx.lineTo(v.x - half, 0);
    ctx.lineTo(v.x + half, 0);
    ctx.lineTo(v.x + root, foot);
    ctx.closePath();
    ctx.fill();
  }

  /**
   * The flock, at rest and then leaving.
   *
   * They lock their wings in the first movement and hold that line through the
   * whole film - `amount` 0 is the one number the second movement is made of -
   * and only at the end do they lean over and glide away *along* the limb rather
   * than up. Down is no longer a failure up here; there is nothing above them to
   * fail toward. Drawn at half again the in-game size, because this is the one
   * moment a single bird is big enough to be recognised as one.
   */
  private drawFlock(v: FilmView, empty: number): void {
    const ctx = v.ctx;
    const leave = clamp((this.t - RELEASE_CARRY_AT + 0.6) / (RELEASE_CARRY * 0.9), 0, 1);
    const spread = leave * leave * (3 - 2 * leave);
    // The sweep of movement 4 crossing the frame, so a bird lights as it passes.
    const cross = clamp((this.t - RELEASE_SUNRISE_AT - 0.5) / 1.5, 0, 1);
    const sweepX = cross > 0 && cross < 1 ? v.w * (1.15 - cross * 1.5) : -1e6;

    for (let i = 0; i < GLIDERS; i++) {
      const seed = filmHash(i * 19);
      const lane = (((i * 5) % GLIDERS) - (GLIDERS - 1) / 2) / GLIDERS;
      // A skein: one bird in front and the rest trailing back off both shoulders.
      // The first version laid them along a single horizontal line, which is the
      // one arrangement thirteen birds must never be in - it reads as a rung, not
      // a flock. The vertical drop has to be comparable to the horizontal spread
      // before the eye accepts it as a formation at all.
      // ...and it is a *ragged* skein: each bird sits a little off its slot, or
      // thirteen of them make a chevron drawn with a ruler.
      const sx = v.x + lane * v.w * 0.52 + (seed - 0.5) * 26;
      const sy =
        v.y + Math.abs(lane) * v.h * 0.15 * (0.78 + seed * 0.44) + seed * 16 - v.h * 0.04;
      // ...opening into a long glide out to one side, and very slightly down.
      const x = sx + spread * v.w * (0.4 + seed * 0.25);
      const y = sy + spread * (26 + seed * 30);
      if (y > v.h + 30 || x > v.w + 60) continue;
      const hx = GLIDE_X + spread * 0.9;
      const hy = GLIDE_Y + spread * 0.55;
      const mag = Math.hypot(hx, hy) || 1;
      // Two species, so the closing line is visibly the flock the player
      // assembled rather than thirteen copies of one bird.
      const bird = BIRDS[i % 3 === 0 ? 2 : 0]!;
      const size = (14 + seed * 5) * (1 - spread * 0.2);
      const lit = clamp(1 - Math.abs(x - sweepX) / (v.w * 0.26), 0, 1);
      // They dim as the air goes, because that is the film saying they cannot go
      // on. High contrast keeps the fade and puts a floor under it - the statement
      // is that the flock is *leaving*, not that it is invisible, and thirteen
      // unlit wings against space are nearly the second thing already.
      const fade = clamp(0.5 + empty * 0.45 - spread * 0.3, 0, 1);
      if (fade <= 0.03) continue;
      ctx.fillStyle = rgba(mix(WING, SUN, lit * 0.7), Math.min(1, fade + lit * 0.35));
      ctx.beginPath();
      // amount 0: wings locked. The film's whole first movement is that number.
      traceBird(ctx, x, y, hx / mag, hy / mag, size, size * 0.15, bird, 0, 0, true);
      ctx.fill();
    }
  }
}
