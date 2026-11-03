import { TAU, clamp } from '../core/math';
import { filmHash, filmRamp, type Film, type FilmView } from './Films';
import { speciesAt, traceFish } from './FishShapes';
import { mix, rgba, type Rgb } from './Paint';

/**
 * Slowblue: the last sentence.
 *
 * §11: *the last golden motes reach the trench floor; small fish gather around
 * them; out of the light the first shoal forms - act I's opening - and the camera
 * and the background dissolve imperceptibly into the title screen. Only now does
 * the player fully understand that they did not play a one-way ascent but a
 * circuit.*
 *
 * This is the only film in the game that hands over to nothing, because there is
 * nothing after it, and it is the only one whose job is to be *unnoticed*. The
 * other six are arrivals - a sky, a sunrise, a whole Earth, a cloud, a sea - and
 * every one of them wants to be looked at. This one wants the player to realise,
 * a second or two late, that they are looking at the first frame of the game.
 *
 * Everything about it is built for that. It is painted out of `v.paint` rather
 * than out of constants, because act VII's last band and act I's first band are
 * the same four colours (`tests/zones.test.ts` asserts it), so the film is
 * already standing in the title screen's palette before it draws anything. The
 * rock is drawn the way act I's rock is drawn. The fish are traced with
 * `FishShapes`, which is act I's own outline and nothing else in the second half
 * of the campaign uses. And the one colour that *is* quoted by value is act I's
 * cold shoal, because the last movement has to land on it exactly.
 *
 * It is also twenty-eight seconds long, and length is the only kind of grandeur
 * an ending like this one is allowed to have. **Duration and meaning, never
 * spectacle.** Nothing here brightens the trench, moves the camera, or does
 * anything a player could point at and call a cutscene; the film gets its size
 * from being willing to take its time over six thousand metres of nothing in
 * particular, which is what the bottom of the sea is and what the whole circuit
 * was flown to get back to.
 *
 * Seven movements, on the film's own clock, deterministic, no random calls:
 *
 *   1. `settle`   - the fall ends. The last marine snow comes down, the motes lose
 *                   the last of their speed, and for the first time since the
 *                   estuary nothing in the frame is descending.
 *   2. `floor`    - the trench. It arrives from below - the same silhouette, the
 *                   same violet-black, the same rim light act I opens on - and the
 *                   gold comes to rest on it. Six thousand metres, closed.
 *   3. `remember` - the light, at rest, plays the journey back over the dark
 *                   water. Six echoes rise and fade along the arc of the circuit,
 *                   one for each act that was crossed to get here, and then eight
 *                   tenths of a second of nothing, which is the seventh.
 *   4. `gather`   - fish. They come out of the dark one at a time, from the edges,
 *                   and turn around the light. They are not a shoal yet; they are
 *                   individuals arriving, which is the only way this image works.
 *   5. `shoal`    - they become one body. This is the picture act I's first frame
 *                   is, and the player has been holding one of these together for
 *                   an hour without ever seeing one form.
 *   6. `vigil`    - the light is put down. Three deliberate steps take the warmth
 *                   out of the bed, the grain the first movement started falling
 *                   finally lands, and one more fish sets out from the dark.
 *   7. `title`    - the picture settles. The shoal lifts off the floor into the
 *                   composition the attract mode holds it in, the gold's warmth
 *                   goes out of it and act I's cold pale comes back, the last one
 *                   comes home, and the frame stops being an ending and is simply
 *                   the game, waiting. Held.
 *
 * ## The recapitulation, and why it is drawn in the wrong colours
 *
 * The third movement is the only retrospection in Slowblue, and it is six gestures
 * long. Each one is lifted from the film that ended the act it belongs to - the
 * three traces of a waterline seen from underneath, a skein of wings crossing,
 * stars resolving in order of brightness, one bright line a couple of pixels
 * thick, a streak whose tail shortens as it slows, drops and the flat rings they
 * open - and **not one of them is repainted in its own act's palette.** Every
 * echo is the trench's own speck violet, warmed a third of the way toward the
 * gold that is remembering it, at three strokes apiece at the very most.
 *
 * That is the whole argument of the movement and it is worth being exact about.
 * Quoting act II's dawn and act IV's daylight by value would put six bright
 * cards into the darkest picture in the game, and the player would be watching a
 * montage - which is a thing another game's ending does, thirty seconds before
 * the credits. **A memory in the trench is lit by the trench.** What survives six
 * thousand metres of water is a shape, not a colour, so shape is all that is
 * quoted; and because the light doing the remembering is the gold on the floor,
 * every shape is tinted by it. The one colour move in the sequence is act V's,
 * where the streak resolves to a point further along that same mix, because act
 * V's sentence is that the thing that was burning was the gold all along.
 *
 * The six anchor points are placed left to right and at heights that climb
 * through acts I to IV and come back down through V and VI, so the movement's
 * composition is the campaign's own profile through the water column, apogee at
 * the act IV echo. Nothing joins them. A drawn thread would make it a diagram,
 * and the eye closes an arc of six points on its own.
 *
 * ## The vigil
 *
 * The sixth movement is a ritual, and it is mostly a movement in which nothing
 * happens. Somebody coming home with something heavy does not set it down in one
 * motion; they set it down in stages, and stop between them. So the bed of light is dimmed in
 * three deliberate steps - the climb, the turn, the fall, one leg of the circuit
 * each - and between the steps the only thing in the frame that changes is the
 * breath. The motes never go out and are never recoloured: what the player
 * carried is set down, not lost.
 *
 * That the movement is nearly empty is the movement. It is the one stretch of the
 * game with no subject in it at all - nothing arrives, nothing is revealed, and
 * the picture is already finished - and putting a fourth thing into it to hold
 * the player's attention would be admitting that the ending needs holding.
 *
 * Two things happen around the edges of it, and both are the film answering
 * itself. The grain of marine snow that starts falling in the first movement
 * lands on the bed here, on the same braking curve the opening field falls on -
 * the last thing still descending anywhere in the campaign, arriving. And one
 * more fish sets out from off the far side of the frame and takes four seconds
 * to cross it, settling into the ring two seconds before the results screen is
 * allowed to arrive. Act VII's own sentence is *nothing hurries you down here;
 * let them settle*, and this is the film keeping it to its own ending.
 *
 * ## Reduced motion
 *
 * Nothing is dropped and nothing is damped. There is no camera move, no rotation
 * and no flash anywhere in this film - the fastest thing in it is a fish - and a
 * player on reduced motion is owed the ending as much as anyone. `still` takes
 * out the snow's sway, the last grain's drift and the mill's wander, all three of
 * which are texture - and all three of which are drawn on the renderer's clock
 * rather than the film's. That is the line this file draws between the two: what
 * runs on `v.time` is weather, and weather is what `still` is for.
 *
 * The recapitulation is held to the same rule, and it needs stating because a
 * memory is exactly the kind of thing a lazy reduced-motion path would freeze
 * into a still. Act II's skein still crosses, because the crossing is what act II
 * was about; what goes is the flutter on its wings, which is drawn on the
 * renderer's clock rather than the film's. Act V's streak still falls and still
 * retracts. Act VI's drops still land and still open their rings. Act III's
 * stars, which do not move in either mode, are the one echo where the stillness
 * *is* the quote. Every one of the six arrives, in order, in both modes. So does
 * the seventeenth fish: it is the last piece of content in the game, and a
 * player who cannot take a moving frame does not get a version of the ending
 * where the last one never comes home.
 *
 * ## High contrast
 *
 * The one film where the setting has a precedent to copy rather than a judgement to
 * make. `RockPaint`'s high-contrast path is "flat fill, bright rim, no texture", and
 * it exists because act I's rock and act I's water are four values apart - which is
 * the same two colours this film is painted in, and the same defect the floor had
 * here already (see `drawFloor`). So the mass is lifted twice as far toward its own
 * rim colour and both hairlines go hard, which is `paintStone` arriving at the same
 * frame by a different route.
 *
 * The fish and the settled gold brighten with it. This is the darkest picture in the
 * campaign at both ends of it, so nothing here is at risk of being light on light,
 * and every element can simply be given more.
 *
 * There are exactly two softeners in the film and both are in the recapitulation:
 * the halo each echo sits in, and the band of light under act IV's line. Both are
 * there to stop a stroke having a hard edge against black, which is the thing this
 * setting exists to give back, so both are cut to about a third - and neither is
 * removed, because a two-pixel line with nothing under it at all is a scratch. The
 * echoes' own strokes go up and thicken to pay for it.
 *
 * The vigil is the one place where the setting and the movement pull against each
 * other, and the movement gives way. Its whole subject is light being dimmed, but
 * the floor it dims to is raised - the gold never falls below four fifths of itself
 * here, against two thirds in the plain frame - because the campaign's one visual
 * constant may be set down and may never be made illegible, and never, in any of the
 * seven films, recoloured.
 */

/** Movement lengths, in seconds. */
export const CIRCLE_SETTLE = 2.4;
export const CIRCLE_FLOOR = 2.8;
/**
 * The recapitulation, and the longest movement in the film.
 *
 * Six echoes at roughly a second apart, never more than two of them on screen at
 * once, and then a hole at the end that the next movement arrives out of. See
 * `drawMemories`.
 */
export const CIRCLE_REMEMBER = 6.6;
export const CIRCLE_GATHER = 4;
export const CIRCLE_SHOAL = 4.2;
export const CIRCLE_VIGIL = 3.4;
export const CIRCLE_TITLE = 5;

export const CIRCLE_FLOOR_AT = CIRCLE_SETTLE;
/** The frame the light starts remembering. Nothing else is moving by then. */
export const CIRCLE_REMEMBER_AT = CIRCLE_FLOOR_AT + CIRCLE_FLOOR;
/** The frame the first fish arrives. The audio's return to act I belongs here. */
export const CIRCLE_GATHER_AT = CIRCLE_REMEMBER_AT + CIRCLE_REMEMBER;
export const CIRCLE_SHOAL_AT = CIRCLE_GATHER_AT + CIRCLE_GATHER;
/** The frame the light starts being put down. */
export const CIRCLE_VIGIL_AT = CIRCLE_SHOAL_AT + CIRCLE_SHOAL;
export const CIRCLE_TITLE_AT = CIRCLE_VIGIL_AT + CIRCLE_VIGIL;
export const CIRCLE_TOTAL = CIRCLE_TITLE_AT + CIRCLE_TITLE;
/**
 * Film seconds the closed circle is held before anything is asked of the player.
 *
 * The longest tail in the game, and it is the one number in this file that is a
 * value judgement rather than a composition. What arrives after it is a results
 * screen - the only one in Slowblue that reports the journey rather than the leg -
 * and it must not arrive while the player is still working out what they are
 * looking at.
 *
 * It is also shorter than `CIRCLE_TITLE`, and that relation is load-bearing
 * rather than incidental: the handover has to fall *inside* the last movement or
 * the film ends up with content nobody can reach, because the frame `handedOver`
 * goes true is the frame everything gets reset. `tests/films.test.ts` asserts it
 * for all seven.
 */
export const CIRCLE_TAIL = 3.4;

export type CirclePhase =
  | 'idle'
  | 'settle'
  | 'floor'
  | 'remember'
  | 'gather'
  | 'shoal'
  | 'vigil'
  | 'title';

/**
 * Act I's shoal, quoted by value.
 *
 * `#f0e7ff` out of `zones.ts`'s hadal band, and the last movement eases onto it
 * exactly. Act VII's water is lit warm - from the inside, by what the player is
 * carrying - and act I's is lit cold, by six thousand metres of nothing. The
 * whole of the seventh movement is that one colour changing back.
 */
const ACT_I_SHOAL: Rgb = [240, 231, 255];
/** ...and its glow, `rgba(189,132,255,0.15)`, which is where the frame ends up. */
const ACT_I_GLOW: Rgb = [189, 132, 255];
/** Pod-gold, arriving at the floor it left from. */
const LIFE: Rgb = [255, 233, 178];

/** Motes coming to rest. The last of the carried life. */
const MOTES = 22;
/** Fish in the shoal that forms. Act I deals twenty-five; this is what arrives first. */
const FISH = 16;
/** Grains of marine snow still falling at the first frame. */
const SNOW = 34;

/**
 * One remembered act: when it rises, how long it is held, how long it takes to
 * go, and where in the water column it sits.
 *
 * `y` is the whole of the movement's composition. It falls through the first four
 * entries and comes back up through the last two, so the six points trace the
 * campaign's own climb and fall against the frame - and the act IV echo, which is
 * the apogee of the circuit, is also the highest and the longest held thing in
 * the sequence. It earned both.
 */
interface Echo {
  /** Seconds into the movement, on `rel`. */
  at: number;
  rise: number;
  hold: number;
  fall: number;
  /** Fraction of the frame height. */
  y: number;
}

/**
 * The six, in order, and the arithmetic that has to hold.
 *
 * Every entry's `at + rise + hold + fall` is at most `CIRCLE_REMEMBER - 0.8`, so
 * the last of them is analytically zero eight tenths of a second before the
 * movement ends. That hole is not a gap in the schedule: it is **the seventh
 * memory**. Act VII is the room the player is sitting in, it does not need a
 * picture, and the first fish comes out of exactly that stillness.
 *
 * The spacing is also chosen so that no more than two echoes are ever alive at
 * once - adjacent entries touch at zero rather than overlapping in threes - which
 * is what keeps the whole movement inside four strokes, four fills and three
 * gradients at its busiest frame.
 */
const ECHOES: readonly Echo[] = [
  { at: 0, rise: 0.7, hold: 0.1, fall: 0.85, y: 0.7 },
  { at: 0.8, rise: 0.7, hold: 0.1, fall: 0.85, y: 0.56 },
  { at: 1.65, rise: 0.7, hold: 0.15, fall: 0.85, y: 0.42 },
  { at: 2.45, rise: 0.7, hold: 0.55, fall: 0.85, y: 0.27 },
  { at: 3.55, rise: 0.7, hold: 0.1, fall: 0.85, y: 0.4 },
  { at: 4.55, rise: 0.55, hold: 0.1, fall: 0.6, y: 0.53 },
];

/**
 * How lit an echo is, 0..1, from the movement's clock alone.
 *
 * `filmRamp` clamps at both ends, so this is exactly 0 before the echo starts and
 * exactly 0 once its fall has run - not "very small". The difference matters:
 * `tests/films.test.ts` counts fills two tenths of a second before the fourth
 * movement and one leaked path would flip a pinned inequality.
 */
function echoLight(rel: number, e: Echo): number {
  return filmRamp(rel, e.at, e.rise) * (1 - filmRamp(rel, e.at + e.rise + e.hold, e.fall));
}

/**
 * The seventeenth fish: when it sets out and how long it takes to cross.
 *
 * Act I deals twenty-five and sixteen of them make the image. This one leaves
 * during the vigil and arrives at 24.8s - inside `title`, and two full seconds
 * before the film hands over, so nothing is still moving across the frame when
 * the results screen is allowed in.
 */
const LAST_AT = CIRCLE_VIGIL_AT + 0.6;
const LAST_SWIM = 4.2;
/** Where it takes its place: the outermost slot on the side it came from. */
const LAST_ANGLE = 0.06 * TAU;

/**
 * The last grain's fall, as the same two numbers the opening snow uses.
 *
 * Position is the integral of an exponentially decaying speed, which is what
 * something settling in still water actually does, normalised so the grain is
 * exactly on the bed after `GRAIN_SPAN` seconds and stays there. The opening
 * field falls on this curve at the top of the film; this is one grain of it,
 * arriving at the bottom.
 */
const GRAIN_BRAKE = 1.15;
const GRAIN_SPAN = 3;
const GRAIN_REACH = 1 - Math.exp(-GRAIN_SPAN / GRAIN_BRAKE);

export class Circle implements Film {
  private t = -1;

  readonly anchor = [0.26, 0.5] as const;

  get active(): boolean {
    return this.t >= 0;
  }

  get phase(): CirclePhase {
    if (this.t < 0) return 'idle';
    if (this.t < CIRCLE_FLOOR_AT) return 'settle';
    if (this.t < CIRCLE_REMEMBER_AT) return 'floor';
    if (this.t < CIRCLE_GATHER_AT) return 'remember';
    if (this.t < CIRCLE_SHOAL_AT) return 'gather';
    if (this.t < CIRCLE_VIGIL_AT) return 'shoal';
    if (this.t < CIRCLE_TITLE_AT) return 'vigil';
    return 'title';
  }

  /**
   * 0..1 how far the frame has left the live world.
   *
   * The slowest and the shallowest of the seven, and the only one that stops well
   * short of covering the world. Every other film replaces somewhere with
   * somewhere else; this one is *the same place*, half a station further down, in
   * the same palette. A hard veil here would be a cut between two frames of
   * identical water, which is the one thing this ending cannot contain.
   *
   * Complete a little over four seconds in - before the light starts remembering
   * anything, so the recapitulation happens in the film's own frame rather than
   * over a world that is still going out.
   */
  get veil(): number {
    if (this.t < 0) return 0;
    return clamp(filmRamp(this.t, 0, CIRCLE_SETTLE + CIRCLE_FLOOR * 0.6) * 0.88, 0, 0.88);
  }

  /**
   * True once the campaign's image is on screen and the film has stopped adding
   * to it. From here on everything that happens is subtraction.
   */
  get closed(): boolean {
    return this.t >= CIRCLE_VIGIL_AT;
  }

  /**
   * True once the shoal starts becoming one body.
   *
   * The closing banner waits for this, and it deliberately does not wait for the
   * recapitulation to be over - it waits for it to be *finished*. A heading over
   * the third movement would caption six memories that are not captioned, which
   * is the one thing that could turn them into a montage.
   */
  get settled(): boolean {
    return this.t >= CIRCLE_SHOAL_AT;
  }

  /** The trench floor: the darkest frame in the campaign, at both ends of it. */
  readonly daylight = false;

  /** True once the circle has been held long enough for the journey to be reported. */
  get handedOver(): boolean {
    return this.t >= CIRCLE_TITLE_AT + CIRCLE_TAIL;
  }

  begin(): void {
    if (this.t >= 0) return;
    this.t = 0;
  }

  reset(): void {
    this.t = -1;
  }

  /** Holds on the last frame rather than ending. */
  update(dt: number): void {
    if (this.t < 0) return;
    this.t = Math.min(CIRCLE_TOTAL, this.t + dt);
  }

  /** How far the floor has arrived, and where the top of it sits. */
  private floorY(v: FilmView): number {
    const p = filmRamp(this.t, CIRCLE_FLOOR_AT - CIRCLE_SETTLE * 0.35, CIRCLE_FLOOR * 0.9);
    // ...and it eases down a little more across the last eight and a half seconds,
    // which is the camera coming to rest rather than the rock moving. The same
    // three per cent it always was, spread over the vigil as well as the hold, so
    // that the frame is already arriving while the light is still being put down.
    const rest = filmRamp(this.t, CIRCLE_VIGIL_AT, CIRCLE_VIGIL + CIRCLE_TITLE);
    return v.h * (1.16 - p * 0.3 + rest * 0.03);
  }

  /** The ridge, as a function of x. Deterministic, and the same every frame. */
  private ridge(v: FilmView, x: number): number {
    const u = x / Math.max(1, v.w);
    return (
      Math.sin(u * 5.1 + 0.7) * v.h * 0.026 +
      Math.sin(u * 11.3 + 2.2) * v.h * 0.014 +
      Math.sin(u * 23.7 + 4.1) * v.h * 0.006
    );
  }

  /**
   * The three steps of the vigil, as one number.
   *
   * The mean of three short smoothsteps a second apart, so what the bed's light
   * actually does is go down, stop, go down, stop, go down - the climb, the turn
   * and the fall, one leg of the circuit set down at a time. A single long ramp
   * over the same interval would look identical in a graph and read as a fade,
   * and a fade is a thing a renderer does rather than a thing a person does.
   */
  private putDown(): number {
    return (
      (filmRamp(this.t, CIRCLE_VIGIL_AT + 0.6, 0.45) +
        filmRamp(this.t, CIRCLE_VIGIL_AT + 1.6, 0.45) +
        filmRamp(this.t, CIRCLE_VIGIL_AT + 2.6, 0.45)) /
      3
    );
  }

  /**
   * The breath, on the ring's radius. Ramped in across the vigil so it never pops.
   *
   * Exactly 1 at `breath = 0.5` by construction, which is not a nicety: the unit
   * tests hold the breath at its midpoint and compare geometry, so any term that
   * did not vanish there would be asserting a swell that is really an offset.
   */
  private breathRing(v: FilmView, tt: number): number {
    return 1 + filmRamp(tt, CIRCLE_VIGIL_AT, CIRCLE_VIGIL) * (v.breath - 0.5) * 0.05;
  }

  /**
   * The body's own slow travel across the frame.
   *
   * Shared by the ring and by the fish that joins it late, so the two agree
   * without either of them knowing about the other. It decays through the held
   * frame and never reaches zero, because a shoal at rest is still working - and
   * because a body that stopped dead would tell the player the film had ended,
   * which is the one thing this ending is not allowed to say.
   */
  private travel(v: FilmView, tt: number, tighten: number): number {
    const calm = 1 - filmRamp(tt, CIRCLE_TITLE_AT, CIRCLE_TITLE * 0.8) * 0.72;
    return Math.sin(tt * 0.34) * v.w * 0.07 * tighten * calm;
  }

  draw(v: FilmView): void {
    if (this.t < 0) return;
    const ctx = v.ctx;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    this.drawWater(v);
    this.drawSnow(v);
    this.drawFloor(v);
    // Between the rock and the gold: a memory in this film is a thing the light on
    // the floor is doing, so it is never painted over the light that is doing it.
    this.drawMemories(v);
    this.drawMotes(v);
    this.drawShoal(v);
    ctx.restore();
  }

  /** The trench, in the palette the title screen is about to be drawn in. */
  private drawWater(v: FilmView): void {
    const ctx = v.ctx;
    const a = filmRamp(this.t, 0, CIRCLE_SETTLE + CIRCLE_FLOOR * 0.5);
    if (a <= 0.01) return;
    const g = ctx.createLinearGradient(0, 0, 0, v.h);
    g.addColorStop(0, rgba(v.paint.top, 0.9 * a));
    g.addColorStop(0.55, rgba(v.paint.mid, 0.94 * a));
    g.addColorStop(1, rgba(v.paint.bottom, 0.96 * a));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, v.w, v.h);
  }

  /**
   * Marine snow, stopping.
   *
   * Act VII's fifth station is a whole band of this - the one place in the game
   * with more specks in it than anything else - and the first movement is that
   * band running out. Every grain slows on the same curve, and the field is
   * thinned to nothing at exactly `CIRCLE_REMEMBER_AT`: the last of it stops on
   * the frame the light starts remembering, so the recapitulation happens in the
   * first completely still water in twenty minutes.
   *
   * One grain is held back from it. See `drawLastGrain`.
   */
  private drawSnow(v: FilmView): void {
    if (v.quality <= 0.45) return;
    const ctx = v.ctx;
    const left = 1 - filmRamp(this.t, CIRCLE_SETTLE * 0.5, CIRCLE_FLOOR + CIRCLE_SETTLE * 0.5);
    if (left <= 0.02) return;
    const lit = 0.3;
    // The fall decays to nothing rather than stopping: `1 - e^-t` integrated is
    // what something settling in still water actually does.
    const drop = 34 * (1 - Math.exp(-this.t / 1.9)) * 1.9;
    const t = v.time;
    ctx.fillStyle = rgba(v.paint.speck, lit * left);
    ctx.beginPath();
    for (let i = 0; i < SNOW; i++) {
      const seed = filmHash(i * 19);
      const x = seed * v.w + Math.sin(t * 0.3 + i) * 5;
      const y = filmHash(i * 41 + 7) * v.h + drop;
      if (y > v.h + 10) continue;
      const r = 0.6 + seed * 1.4;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
  }

  /**
   * The trench floor.
   *
   * One filled silhouette with a rim light along its top edge, in `paint.rock`
   * and `paint.rockRim` - which are, at this point in the campaign, the exact two
   * values act I's first station is drawn in. It arrives from below rather than
   * fading in, because the swarm is descending onto it: what the player is
   * watching is the bottom of the sea coming up to meet them, and that is the
   * literal last movement of a journey that began there.
   */
  private drawFloor(v: FilmView): void {
    const ctx = v.ctx;
    const p = filmRamp(this.t, CIRCLE_FLOOR_AT - CIRCLE_SETTLE * 0.35, CIRCLE_FLOOR * 0.9);
    if (p <= 0.01) return;
    const base = this.floorY(v);

    /*
     * Two ridges, and the near one is not painted in `paint.rock`.
     *
     * That was the first cut and it made the floor invisible: act I's rock is
     * `#05010e` and act I's deep water is `#010108`, four values apart, so a
     * flat fill of one over the other is a shape nobody can see - only the rim
     * hairline showed, hanging in the dark with no mass under it. The shipped
     * game gets away with the same two colours because `RockPaint` puts a rim
     * light and internal shading on every blob; this film draws one silhouette
     * and has to earn its own separation. So the mass is lifted a quarter of the
     * way toward its own rim colour and shaded downward from there, and a second
     * ridge sits behind it, higher and dimmer, which is what gives a silhouette
     * a distance.
     */
    for (const far of [true, false]) {
      const lift = far ? base - v.h * 0.055 : base;
      const body = mix(v.paint.rock, v.paint.rockRim, far ? 0.12 : 0.26);
      const g = ctx.createLinearGradient(0, lift - v.h * 0.05, 0, v.h);
      g.addColorStop(0, rgba(body, 0.97 * p));
      g.addColorStop(1, rgba(v.paint.rock, 0.99 * p));
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.moveTo(-20, v.h + 20);
      for (let x = -20; x <= v.w + 20; x += 12) {
        ctx.lineTo(x, lift - this.ridge(v, x) * (far ? 0.7 : 1));
      }
      ctx.lineTo(v.w + 20, v.h + 20);
      ctx.closePath();
      ctx.fill();

      // The rim. One hairline each, exactly as act I draws its rock, and the
      // only hard edges anywhere in this film.
      ctx.strokeStyle = rgba(v.paint.rockRim, (far ? 0.3 : 0.62) * p);
      ctx.lineWidth = far ? 1 : 1.6;
      ctx.beginPath();
      for (let x = -20; x <= v.w + 20; x += 12) {
        const y = lift - this.ridge(v, x) * (far ? 0.7 : 1);
        if (x === -20) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
  }

  /**
   * Movement 3. The journey, told back.
   *
   * Six gestures, one per act crossed, each one lifted from that act's own ending
   * and repainted in a single colour: the trench's speck violet warmed a third of
   * the way toward the gold that is remembering it. The argument for that is at
   * the top of the file and it is the reason this movement can exist at all in
   * the darkest picture in the game.
   *
   * Everything here is a function of `rel` and nothing else, the pass leaves the
   * frame untouched outside its own window, and an echo whose envelope has run is
   * skipped before it opens a path rather than drawn at an alpha of nothing. The
   * halo is the movement's one decorative element and the only thing in it a
   * quality tier may take: the six gestures are the subject, and a player on a
   * slow phone gets the journey back.
   */
  private drawMemories(v: FilmView): void {
    const rel = this.t - CIRCLE_REMEMBER_AT;
    if (rel < 0 || rel >= CIRCLE_REMEMBER) return;
    const ctx = v.ctx;
    // One colour for the whole recapitulation. Mixed once a frame rather than
    // once an echo, because it is one light source doing all six.
    const tone = mix(v.paint.speck, LIFE, 0.3);
    // Additive, because these are light in water rather than objects in it - and
    // safe here in a way it is not in the bright films, because everything under
    // them is within a few values of black.
    ctx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < ECHOES.length; i++) {
      const e = ECHOES[i]!;
      const a = echoLight(rel, e);
      if (a < 0.001) continue;
      // How far through its own life this echo is, which is what the gestures
      // that go somewhere are driven by.
      const p = clamp((rel - e.at) / (e.rise + e.hold + e.fall), 0, 1);
      // Left to right, and up the water column and back down it.
      const x = v.w * (0.14 + (0.72 * (i + 0.5)) / ECHOES.length);
      const y = v.h * e.y;

      // The halo. One soft radial each, so a stroke a pixel wide has something to
      // sit in instead of an edge against black - which is exactly the kind of
      // wash high contrast is owed back, so it is cut rather than kept.
      if (v.quality > 0.5) {
        const r = v.h * 0.075;
        const halo = ctx.createRadialGradient(x, y, 0, x, y, r);
        halo.addColorStop(0, rgba(tone, 0.07 * a));
        halo.addColorStop(1, rgba(tone, 0));
        ctx.fillStyle = halo;
        ctx.fillRect(x - r, y - r, r * 2, r * 2);
      }

      switch (i) {
        case 0:
          this.echoSurface(v, x, y, a, tone);
          break;
        case 1:
          this.echoSkein(v, x, y, a, p, tone);
          break;
        case 2:
          this.echoStars(v, x, y, a, p, tone);
          break;
        case 3:
          this.echoLine(v, x, y, a, tone);
          break;
        case 4:
          this.echoFall(v, x, y, a, p, tone);
          break;
        default:
          this.echoRings(v, x, y, a, p, tone);
          break;
      }
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Act I: the surface, remembered from underneath.
   *
   * `Surfacing.drawCeiling`'s rule, quoted exactly - three traces a few pixels
   * apart, never one, because a single stroke across a frame is a UI divider and
   * this was a surface. It is the first thing the journey broke through and it is
   * the lowest point of the sequence, which is where it was when the game started.
   */
  private echoSurface(v: FilmView, x: number, y: number, a: number, tone: Rgb): void {
    const ctx = v.ctx;
    const t = v.time;
    const half = v.w * 0.075;
    for (let band = 0; band < 3; band++) {
      ctx.strokeStyle = rgba(tone, (0.3 - band * 0.07) * a);
      ctx.lineWidth = 0.8 + band * 0.6;
      ctx.beginPath();
      for (let k = 0; k <= 10; k++) {
        const px = x - half + (k / 10) * half * 2;
        // The wave is a function of position, so the shape survives `still`; only
        // the drift along it is on the renderer's clock.
        const py = y + band * 2.4 + Math.sin(k * 0.9 + band * 1.6 + t * 0.4) * (1.2 + band * 0.5);
        if (k === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.stroke();
    }
  }

  /**
   * Act II: the ones who could not go on, remembered going on.
   *
   * A skein of five, in the one formation the flock ever held. The traverse is the
   * subject - the whole of act II is a thing crossing an air that is running out -
   * so it runs on the film's clock and a reduced-motion player still watches it
   * cross. What comes off there is the flutter, which is the only part of this
   * that is texture.
   */
  private echoSkein(v: FilmView, x: number, y: number, a: number, p: number, tone: Rgb): void {
    const ctx = v.ctx;
    const half = v.w * 0.07;
    const lead = x - half + p * half * 2;
    const wing = v.w * 0.012;
    ctx.strokeStyle = rgba(tone, 0.26 * a);
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let i = 0; i < 5; i++) {
      // One leader and two arms behind it. Rank is how far back, arm is which side.
      const rank = Math.ceil(i / 2);
      const arm = i === 0 ? 0 : i % 2 === 0 ? 1 : -1;
      const bx = lead - rank * v.w * 0.018;
      const by = y + arm * rank * v.h * 0.011;
      const beat = Math.sin(v.time * 3.4 + i * 1.1) * 0.5 + 0.5;
      const drop = wing * (0.35 + beat * 0.5);
      ctx.moveTo(bx - wing, by + drop);
      ctx.lineTo(bx, by - drop * 0.4);
      ctx.lineTo(bx + wing, by + drop);
    }
    ctx.stroke();
  }

  /**
   * Act III: the sky with nothing left in it but light.
   *
   * `Release`'s own words for what happens at the top of the air are *not
   * switched on, arrived at*, so these do not fade up - they grow out of nothing,
   * brightest first, in the order the eye actually resolves a star field. And
   * they do not move, in `still` or out of it. This is the one echo where the
   * stillness is the quote: there is no medium up there to move anything.
   *
   * One path for all seven, with size carrying brightness, because a fill each
   * would cost the movement its whole budget for a distinction nobody can see at
   * two pixels.
   */
  private echoStars(v: FilmView, x: number, y: number, a: number, p: number, tone: Rgb): void {
    const ctx = v.ctx;
    ctx.fillStyle = rgba(tone, 0.5 * a);
    ctx.beginPath();
    for (let i = 0; i < 7; i++) {
      const mag = 1 - i / 7;
      const born = clamp((p - i * 0.09) / 0.22, 0, 1);
      if (born <= 0) continue;
      const sx = x + (filmHash(i * 83 + 3) - 0.5) * v.w * 0.13;
      const sy = y + (filmHash(i * 97 + 11) - 0.5) * v.h * 0.055;
      const r = (0.5 + mag * 1.5) * born;
      ctx.moveTo(sx + r, sy);
      ctx.arc(sx, sy, r, 0, TAU);
    }
    ctx.fill();
  }

  /**
   * Act IV: everything that ever happened, one thin bright line.
   *
   * The apogee of the sequence and the brightest thing in it, at two CSS pixels,
   * because the original was every frame of the game seen edge-on and `Overview`
   * has never once been allowed to make it thicker. Shallowly curved, so it reads
   * as a limb rather than as a rule.
   *
   * The band under it is a softener and behaves like one: cut hard for high
   * contrast, never dropped for it. A two-pixel line with nothing at all
   * underneath is a scratch on the screen, which is a different picture.
   */
  private echoLine(v: FilmView, x: number, y: number, a: number, tone: Rgb): void {
    const ctx = v.ctx;
    const half = v.w * 0.1;
    const top = y - v.h * 0.006;
    const band = ctx.createLinearGradient(0, top, 0, top + v.h * 0.036);
    band.addColorStop(0, rgba(tone, 0));
    band.addColorStop(0.25, rgba(tone, 0.1 * a));
    band.addColorStop(1, rgba(tone, 0));
    ctx.fillStyle = band;
    ctx.fillRect(x - half * 1.2, top, half * 2.4, v.h * 0.036);

    ctx.strokeStyle = rgba(tone, 0.62 * a);
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let k = 0; k <= 12; k++) {
      const u = k / 12;
      const px = x - half + u * half * 2;
      const py = y - Math.sin(u * Math.PI) * v.h * 0.004;
      if (k === 0) ctx.moveTo(px, py);
      else ctx.lineTo(px, py);
    }
    ctx.stroke();
  }

  /**
   * Act V: what was burning was you, the whole time.
   *
   * A streak coming down whose tail *shortens* as it goes, which is `Nucleus`'s
   * one idea drawn in three lines: the trail behind a grain is the distance it
   * covered in the last instant, so a thing slowing down retracts its own streak
   * without being switched off. It resolves to a single point.
   *
   * That point is the only place in the recapitulation where the colour moves,
   * and it moves along the axis the whole sequence is already on rather than off
   * it - further toward the gold, never to it. Act V's sentence is that the fire
   * and the gold were the same object, and a memory of it that stayed the same
   * violet as the other five would be remembering the wrong half.
   */
  private echoFall(v: FilmView, x: number, y: number, a: number, p: number, tone: Rgb): void {
    const ctx = v.ctx;
    const drop = v.h * 0.09;
    // Ease-out: it arrives fast and finishes slowly, which is what the fall did.
    const e = 1 - Math.pow(1 - p, 2.2);
    const hx = x + (p - 0.5) * v.w * 0.012;
    const hy = y - v.h * 0.045 + drop * e;
    const tail = drop * 0.42 * Math.pow(1 - p, 2.2);
    if (tail > 0.6) {
      ctx.strokeStyle = rgba(tone, 0.4 * a);
      ctx.lineWidth = 1.3;
      ctx.beginPath();
      ctx.moveTo(hx, hy - tail);
      ctx.lineTo(hx, hy);
      ctx.stroke();
    }
    ctx.fillStyle = rgba(mix(tone, LIFE, 0.45), 0.55 * a);
    ctx.beginPath();
    ctx.arc(hx, hy, 1 + p * 1.3, 0, TAU);
    ctx.fill();
  }

  /**
   * Act VI: the way back down.
   *
   * Three short drop-streaks onto one plane, and a flat ring opening where each
   * of them lands - `Surfacing`'s breach rings, remembered six thousand metres
   * down and a fortieth of the size. A drop's streak ends on exactly the frame
   * its ring starts, so the handover from one to the other is the landing rather
   * than a crossfade over it. The rings do not fade individually; they stay open
   * until the whole memory dissolves, because what act VI left behind was a
   * surface with marks on it.
   *
   * Both passes are counted before they are opened. By the end of the echo every
   * drop has landed and by the start of it none has, so a loop that stroked
   * unconditionally would spend two empty paths a frame on either side of the one
   * second in the middle where there is anything to draw.
   */
  private echoRings(v: FilmView, x: number, y: number, a: number, p: number, tone: Rgb): void {
    const ctx = v.ctx;
    const spread = v.w * 0.06;
    const fall = v.h * 0.06;
    let falling = false;
    let open = false;

    for (let i = 0; i < 3; i++) {
      const u = clamp((p - i * 0.15) / 0.42, 0, 1);
      if (u <= 0 || u >= 1) continue;
      if (!falling) {
        ctx.strokeStyle = rgba(tone, 0.38 * a);
        ctx.lineWidth = 1.1;
        ctx.beginPath();
        falling = true;
      }
      const dx = x + (i - 1) * spread;
      const dy = y - fall + u * fall;
      const tail = fall * 0.3 * (1 - u * 0.5);
      ctx.moveTo(dx, dy - tail);
      ctx.lineTo(dx, dy);
    }
    if (falling) ctx.stroke();

    for (let i = 0; i < 3; i++) {
      const w = clamp((p - i * 0.15 - 0.42) / 0.4, 0, 1);
      if (w <= 0) continue;
      if (!open) {
        ctx.strokeStyle = rgba(tone, 0.3 * a);
        ctx.lineWidth = 1;
        ctx.beginPath();
        open = true;
      }
      const dx = x + (i - 1) * spread;
      ctx.ellipse(dx, y, 2 + w * spread * 0.85, 0.8 + w * v.h * 0.007, 0, 0, TAU);
    }
    if (open) ctx.stroke();
  }

  /**
   * The last golden motes, landing - and then being put down.
   *
   * They decelerate onto the rock and then stop, and from that frame on they are
   * the only light source in the picture - which is what the trench floor is, and
   * what act I's first frame is lit by. The breath moves them by a fiftieth,
   * because a held frame in this game breathes and because a bed of settled life
   * is the one thing in the campaign it would be strange not to.
   *
   * The sixth movement happens here: `putDown` takes the bed's glow most of the
   * way out in three steps and eases the motes themselves down onto a floor they
   * never go below. Setting a light down is not switching it off.
   */
  private drawMotes(v: FilmView): void {
    const ctx = v.ctx;
    const base = this.floorY(v);
    // Arrival: fast at the first frame, dead stop by the end of the second
    // movement. Ease-out, so nothing lands on a hard frame.
    const land = filmRamp(this.t, 0, CIRCLE_SETTLE + CIRCLE_FLOOR * 0.55);
    const swell = 1 + (v.breath - 0.5) * 0.06;
    const put = this.putDown();
    // The gold's floor. Two thirds of itself in the plain frame; four fifths under
    // high contrast, where the campaign's one constant may be set down but may not
    // be dimmed past legibility - and is not recoloured either way.
    const full = 0.85;
    const rest = 0.62;
    const warmth = full - (full - rest) * put;

    ctx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < MOTES; i++) {
      const seed = filmHash(i * 23);
      const side = filmHash(i * 37 + 5);
      const x = v.x + (side - 0.5) * v.w * 0.56;
      // Where it comes to rest: on the rock, at its own x, with a little scatter
      // so the bed is a bed and not a line.
      const to = base - this.ridge(v, x) - 3 - seed * 9;
      const from = v.y - v.h * 0.16 + seed * v.h * 0.22;
      const y = from + (to - from) * land;
      if (y < -20 || y > v.h + 20) continue;
      const r = (1.3 + seed * 1.7) * swell;
      ctx.fillStyle = rgba(LIFE, warmth);
      ctx.beginPath();
      ctx.arc(x, y, r, 0, TAU);
      ctx.fill();
    }

    this.drawLastGrain(v, base);

    // The bed's own glow, once it is a bed. Up by the frame the light starts
    // remembering, and down again as it is put down.
    const bedLit = filmRamp(this.t, CIRCLE_FLOOR_AT, CIRCLE_FLOOR);
    if (bedLit > 0.02) {
      const gy = base - v.h * 0.03;
      const reach = v.w * 0.62 * (1 - put * 0.2);
      const glow = ctx.createRadialGradient(v.x, gy, 0, v.x, gy, reach);
      // ...and it cools as the picture becomes act I's. The warm light in this
      // frame is the campaign's; the violet is the trench's own.
      const home = filmRamp(this.t, CIRCLE_TITLE_AT, CIRCLE_TITLE * 0.9);
      const tint = mix(LIFE, ACT_I_GLOW, home * 0.8);
      glow.addColorStop(0, rgba(tint, 0.17 * bedLit * swell * (1 - put * 0.54)));
      glow.addColorStop(1, rgba(tint, 0));
      ctx.fillStyle = glow;
      ctx.fillRect(0, gy - v.h * 0.5, v.w, v.h * 0.8);
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The last grain.
   *
   * One speck of marine snow, held back from the field the film opens on, falling
   * on the same braking curve every other grain fell on and reaching the bed near
   * the end of the vigil. It is the film's first movement answered by its sixth,
   * and it is the last thing anywhere in the campaign that is still descending.
   *
   * It is drawn here rather than in `drawSnow` on purpose: the snow field is
   * weather and a low quality tier is allowed to drop it, and this is content.
   */
  private drawLastGrain(v: FilmView, base: number): void {
    const rel = this.t - CIRCLE_VIGIL_AT;
    if (rel < 0) return;
    const ctx = v.ctx;
    const u = Math.min(1, (1 - Math.exp(-rel / GRAIN_BRAKE)) / GRAIN_REACH);
    const x = v.x + (filmHash(911) - 0.5) * v.w * 0.5;
    const from = -v.h * 0.03;
    const to = base - this.ridge(v, x) - 4;
    // The sway goes out as it arrives, so what lands is not still drifting.
    const sway = Math.sin(v.time * 0.3 + 1.1) * 4 * (1 - u);
    ctx.fillStyle = rgba(v.paint.speck, 0.5);
    ctx.beginPath();
    ctx.arc(x + sway, from + (to - from) * u, 1.5, 0, TAU);
    ctx.fill();
  }

  /**
   * Where fish number `i` is at time `tt`.
   *
   * Split out because the heading is taken from a finite difference of it rather
   * than from a hand-written velocity: the path has four terms in it by the last
   * movement, and a body pointing anywhere except exactly where it is going is
   * the one thing that would make sixteen fish read as sprites.
   */
  private place(v: FilmView, i: number, tt: number): { x: number; y: number } {
    const seed = filmHash(i * 29);
    const lane = ((i * 7) % FISH) / FISH;
    const base = this.floorY(v);
    // Arrival, one at a time, from alternating sides and staggered over most of
    // the movement. A shoal that appears all at once is a shoal that was always
    // there, and the whole point of this movement is watching it not be.
    const start = CIRCLE_GATHER_AT + (i / FISH) * CIRCLE_GATHER * 0.8;
    const arrive = clamp((tt - start) / 2.4, 0, 1);
    const e = 1 - Math.pow(1 - arrive, 2.6);
    const from = seed < 0.5 ? -60 : v.w + 60;
    /*
     * The slot it takes in the body, on a loose ring around the light.
     *
     * §11's word is that the fish *gather around* the motes, and a ring is both
     * what that means and what fixes the shape. The first cut drove x and y from
     * the same `lane`, so every slot sat on one straight line through the frame
     * and sixteen fish arrived as a queue - the rung failure the flock and the
     * leapers both had, in a diagonal. An angle and an independent radius have
     * no such correlation, and the radius comes from its own hash so the ring is
     * a loose cloud rather than a drawn circle.
     */
    // The lift runs over the tail exactly, so it is finished on the frame the
    // results screen is allowed in rather than a fraction of a second after it.
    const rise = filmRamp(tt, CIRCLE_TITLE_AT, CIRCLE_TAIL);
    const tighten = filmRamp(tt, CIRCLE_SHOAL_AT, CIRCLE_SHOAL * 0.8);
    const spread = 1 - tighten * 0.5;
    const ring = filmHash(i * 71 + 13);
    const ang = lane * TAU + seed * 0.9;
    // ...and the ring is the second thing the held frame breathes with. It is the
    // shape the whole game ends on, and a body of fish that is perfectly rigid for
    // five seconds is a photograph of one.
    const rad = v.h * (0.045 + ring * 0.075) * spread * this.breathRing(v, tt);
    /*
     * The shoal's own slow travel, and the reason the fifth movement is called
     * what it is.
     *
     * A body of fish is not sixteen fish in the same place - it is sixteen fish
     * going the same way, and heading is what the eye reads first. Every fish
     * here is pointed along a finite difference of this function, so the way to
     * make them agree is to give the whole body a motion larger than any
     * individual's: as `tighten` comes up, this term grows and the mill below is
     * damped, and the headings converge without a single line about heading.
     */
    const school = this.travel(v, tt, tighten);
    // Wider than it is tall, because the frame is and because a shoal seen from
    // the side is.
    const slotX = v.x + Math.cos(ang) * rad * 1.9 + school;
    const slotY =
      base -
      v.h * 0.13 +
      Math.sin(ang) * rad -
      // The lift into the attract mode's composition: act I opens with the shoal
      // clear of the floor, not sitting on it.
      rise * v.h * 0.16;
    // The mill. It never stops, because a shoal at rest is still working - but it
    // gives way to the body's own movement once there is a body.
    const wander = 1 - tighten * 0.62;
    const mx = Math.sin(tt * (0.5 + seed * 0.4) + i * 1.7) * 11 * wander;
    const my = Math.cos(tt * (0.37 + seed * 0.3) + i * 2.3) * 7 * wander;
    return {
      x: from + (slotX - from) * e + mx * e,
      y: slotY + my * e,
    };
  }

  /**
   * Where the seventeenth fish is at time `tt`.
   *
   * The same ring, the same travel and the same breath as everything already in
   * the body - it takes the outermost slot on the side it came from - reached
   * across the whole width of the frame on a single long ease. Its own path
   * rather than a seventeenth lane in `place`, because it is not arriving in the
   * fourth movement's queue; it is arriving late, alone, and after the picture
   * was finished without it.
   */
  private lastPlace(v: FilmView, tt: number): { x: number; y: number } {
    const base = this.floorY(v);
    const u = clamp((tt - LAST_AT) / LAST_SWIM, 0, 1);
    // Cubic ease-out: most of the crossing is over before the halfway point and
    // the last tenth of it takes a second. Nothing hurries you down here.
    const e = 1 - Math.pow(1 - u, 3);
    const rise = filmRamp(tt, CIRCLE_TITLE_AT, CIRCLE_TAIL);
    const tighten = filmRamp(tt, CIRCLE_SHOAL_AT, CIRCLE_SHOAL * 0.8);
    const rad = v.h * 0.12 * (1 - tighten * 0.5) * this.breathRing(v, tt);
    const slotX = v.x + Math.cos(LAST_ANGLE) * rad * 1.9 + this.travel(v, tt, tighten);
    const slotY = base - v.h * 0.13 + Math.sin(LAST_ANGLE) * rad - rise * v.h * 0.16;
    const from = v.w + 70;
    // A little of the mill, kept once it has taken its slot: it joined a body
    // that is still working, so it works too.
    const sway = Math.sin(tt * 0.42) * 6 * (1 - e * 0.7);
    return { x: from + (slotX - from) * e, y: slotY + sway };
  }

  /**
   * The first shoal, forming - and the last one to reach it.
   *
   * Act I's own outline, from act I's own file, because this is act I's opening
   * image and drawing it with anything else would be the one moment in the
   * campaign where the game blinked. `traceFish` is used by exactly two things in
   * the second half of Slowblue: the leapers at the end of act I's ending, and this.
   */
  private drawShoal(v: FilmView): void {
    if (this.t < CIRCLE_GATHER_AT) return;
    const ctx = v.ctx;
    // Warm at the floor, act I's cold pale by the held frame.
    const home = filmRamp(this.t, CIRCLE_TITLE_AT, CIRCLE_TITLE * 0.9);
    /*
     * ...and in high contrast, exactly the brightening the live shoal is already
     * getting, by the same arithmetic.
     *
     * `Renderer.contrast` asks which side of the background a thing is on and
     * pushes it further that way; act I's shoal is pale on near-black, so the
     * branch it takes is `brighten(colour, 0.5)`. Quoting the number rather than
     * choosing one keeps the promise this whole film is built on: the last frame
     * has to be the title screen's first, and a title screen drawn from a
     * different formula would put a colour step in the one dissolve that must not
     * have one.
     */
    const body = mix(v.paint.shoal, ACT_I_SHOAL, home);

    for (let i = 0; i < FISH; i++) {
      const seed = filmHash(i * 29);
      const start = CIRCLE_GATHER_AT + (i / FISH) * CIRCLE_GATHER * 0.8;
      if (this.t < start) continue;
      const here = this.place(v, i, this.t);
      const was = this.place(v, i, this.t - 0.06);
      const dx = here.x - was.x;
      const dy = here.y - was.y;
      const mag = Math.hypot(dx, dy);
      // A fish that has arrived and is momentarily still still has to point
      // somewhere, and "into the body" is the honest answer.
      const hx = mag > 0.4 ? dx / mag : v.x - here.x >= 0 ? 1 : -1;
      const hy = mag > 0.4 ? dy / mag : 0;
      const fade = clamp((this.t - start) / 1.1, 0, 1);
      const sp = speciesAt(i % 2 === 0 ? 0 : 3);
      const len = (7 + seed * 3.4) * sp.len;
      const wid = (2 + seed * 0.9) * sp.wid;
      const beat = this.t * (5 + seed * 3) + i * 1.7;
      ctx.fillStyle = rgba(body, 0.9 * fade);
      ctx.beginPath();
      traceFish(ctx, here.x, here.y, hx, hy, len, wid, sp, beat, true);
      ctx.fill();
    }

    // ...and the one that set out during the vigil, in the same colour the ring
    // is in, so it comes home on the same ramp rather than in a colour of its
    // own. A shade larger than the others, because it crosses the darkest part of
    // the frame alone and the eye has to be able to find it out there.
    if (this.t < LAST_AT) return;
    const here = this.lastPlace(v, this.t);
    const was = this.lastPlace(v, this.t - 0.06);
    const dx = here.x - was.x;
    const dy = here.y - was.y;
    const mag = Math.hypot(dx, dy);
    const hx = mag > 0.4 ? dx / mag : v.x - here.x >= 0 ? 1 : -1;
    const hy = mag > 0.4 ? dy / mag : 0;
    const sp = speciesAt(0);
    ctx.fillStyle = rgba(body, 0.9 * clamp((this.t - LAST_AT) / 1.2, 0, 1));
    ctx.beginPath();
    traceFish(ctx, here.x, here.y, hx, hy, 11.5 * sp.len, 3 * sp.wid, sp, this.t * 4.2, true);
    ctx.fill();
  }
}
