import { TAU, clamp } from '../core/math';
import { filmHash, filmRamp, type Film, type FilmView } from './Films';
import { mix, rgba, type Rgb } from './Paint';

/**
 * Slowblue: the camera turns.
 *
 * This is the emotional peak of the campaign and the only place in the game where
 * the frame itself moves. Everything else Slowblue has ever done has been inside one
 * unbroken shot pointed the way the swarm is going - the water scrolls, the camera
 * does not. Four acts of that is what makes eight seconds of this mean anything.
 *
 * What the turn is *for* is a single fact, and the whole film is built to deliver
 * it and then get out of the way: **the entire atmosphere is a line a few pixels
 * thick.** Act I's six thousand metres of ocean, act II's eleven kilometres of
 * weather, act III's climb to the Karman line - forty minutes of play, every
 * frame of it, is that bright rim around the disc. Nothing says so. The player is
 * shown the thing and left with it.
 *
 * `Release.ts` has drawn the same rim since act II's ending, deliberately: by the
 * time it becomes the subject here it is something the player half-recognises
 * rather than something new, which is the difference between a reveal and a
 * reminder.
 *
 * Five movements, on the renderer's own clock, deterministic, no random calls
 * anywhere:
 *
 *   1. `arrest` - motion stops. Four acts of forward drift run out of the frame:
 *                 the last of the ice `Karman` left coasting goes down past the
 *                 swarm, its streaks shortening to nothing as the camera matches
 *                 it, and the last thing the campaign does before the turn is
 *                 come to rest.
 *   2. `turn`   - the camera comes off the direction of travel and swings onto
 *                 the planet. The limb, which has sat along the bottom edge for
 *                 six stations, rolls up and around, and the frame rotates with
 *                 it - once, visibly, and never again.
 *   3. `whole`  - the arc closes. The horizon that was too big to be a shape
 *                 resolves into a disc, the sun goes down behind it - in orbit
 *                 that happens every forty-five minutes, and it is the difference
 *                 between a terminator that *crosses* and a shadow that was
 *                 already there - and everything the player has flown in is
 *                 suddenly one object with an edge.
 *   4. `line`   - the rim. Every other element loses what light it had, the band
 *                 does not, and for three and a half seconds the brightest thing
 *                 on the screen is the atmosphere seen edge-on: hard and warm
 *                 where the sun is, thinning to the cold self-lit glow the night
 *                 side of the air has of its own. Nothing moves but the breath
 *                 and the last of the sunset, which is too slow to watch.
 *   5. `fall`   - the direction of the campaign turns with the camera. The gold
 *                 that has risen since the trench floor reaches the top of its
 *                 arc, stalls, and leans over toward the disc - bending inward as
 *                 it goes, with the first of the air arriving warm on whatever is
 *                 lowest. That is act V's first frame, and it is ballistic, which
 *                 is act IV's own physics rather than a special case for the
 *                 ending.
 *
 * ## Reduced motion
 *
 * The roll is the one element that is dropped rather than damped. Everything else
 * here is a fade, a scale or an object going where it was already going, and those
 * are kept: a player who cannot take a rotating horizon should still be given the
 * picture the rotation was for. What they get instead is the same composition
 * arriving without the swing - the disc closes, the rim lights, and the camera was
 * simply already pointed at it. The shed ice keeps its motion for the same reason
 * `Karman`'s does: it is the first movement's only content, and a still frame of
 * it is a still frame of nothing.
 *
 * Nothing in this film twinkles, at any setting. There is no air up here to make
 * a star flicker, act IV's six backdrops all draw their fields frozen for exactly
 * that reason, and a sky that shimmered only during the ending would be the one
 * frame in the act that forgot where it was.
 *
 * ## High contrast
 *
 * **This is the one film in the game where the setting mostly subtracts, and it has
 * to be.** Everywhere else, more contrast means drawing the subject harder. Here the
 * subject is a line about four device pixels thick whose legibility is not a
 * property of the line at all: the fourth movement works because every other element
 * loses its light while the band keeps it, so what the eye is actually reading is a
 * *ratio*. Brightening the star field, the day side and the gold would raise every
 * term of that ratio at once and leave the picture exactly as hard to read, having
 * spent the whole budget - and the thing the player is meant to look at would be
 * competing with the best part of two hundred brighter stars.
 *
 * So the stars come down by more than half, the lit half of the Earth dims, the
 * glow inside the limb and the warm wash the falling gold lays on it come down with
 * it, and what goes up is the band itself and the hairline on the planet's edge.
 * That hairline is the boundary between everything the game has happened in and
 * everything else, and it is also, mechanically, the dark side of the only edge the
 * band has: a thin bright line against a lit disc is legible in exactly the
 * proportion that the disc ends cleanly. The band's **thickness is never touched**
 * here or anywhere - it is the fact the whole campaign has been climbing toward, and
 * widening it to make it easier to see would be answering a different question.
 */

/** Movement lengths, in seconds. */
export const OVERVIEW_ARREST = 2.1;
export const OVERVIEW_TURN = 4.4;
export const OVERVIEW_WHOLE = 4;
export const OVERVIEW_LINE = 3.6;
export const OVERVIEW_FALL = 4.8;

export const OVERVIEW_TURN_AT = OVERVIEW_ARREST;
export const OVERVIEW_WHOLE_AT = OVERVIEW_TURN_AT + OVERVIEW_TURN;
/** The frame the whole Earth is first a closed shape. The audio's swell belongs here. */
export const OVERVIEW_LINE_AT = OVERVIEW_WHOLE_AT + OVERVIEW_WHOLE;
/** The stall: the gold stops rising. From here the campaign runs downward. */
export const OVERVIEW_FALL_AT = OVERVIEW_LINE_AT + OVERVIEW_LINE;
export const OVERVIEW_TOTAL = OVERVIEW_FALL_AT + OVERVIEW_FALL;
/**
 * Film seconds the fall is watched before act V opens into it.
 *
 * Longer than the other two films' tails, and that is the point of the station:
 * the gold has to be visibly *going somewhere else* before the game turns round
 * and follows it. See `Surfacing.SURFACE_TAIL` for why this is on the film's own
 * clock rather than on a timer.
 */
export const OVERVIEW_TAIL = 3.2;

export type OverviewPhase = 'idle' | 'arrest' | 'turn' | 'whole' | 'line' | 'fall';

/** Space, as act IV draws it. Shared with `Release` by value, not by import. */
const VOID: Rgb = [2, 3, 10];
const STAR: Rgb = [235, 242, 255];
/** Pod-gold. The carried life has been this colour since the first rescue ring. */
const MOTE: Rgb = [255, 233, 178];
/** Ice, at the value `Karman` left it: the same grains, four acts later. */
const ICE: Rgb = [198, 226, 246];
/** The day side: ocean-dominated, because it is. */
const DAY: Rgb = [46, 86, 132];
/** The night side, which is not black - it is the day side with the light off. */
const NIGHT: Rgb = [7, 14, 30];
const SUN: Rgb = [255, 246, 214];

/**
 * The atmosphere, edge-on, in five stops.
 *
 * The same table `Release.ts` uses, and it must stay the same: this is the second
 * time the player sees this band and the whole force of it is that it is the one
 * they saw at the top of the air, from further away. Copied rather than imported
 * for the same reason the two films do not share a base class - a change to act
 * II's ending must not silently redraw act IV's.
 */
const AIR_BAND: readonly (readonly [number, Rgb])[] = [
  [0, [255, 146, 72]],
  [0.22, [255, 208, 150]],
  [0.44, [186, 226, 255]],
  [0.7, [86, 150, 240]],
  [1, [30, 40, 120]],
];

/**
 * Airglow: the colour the air is when nothing is lighting it.
 *
 * Taken out of the band's own two cold stops rather than chosen, because it is
 * not a new thing in the frame - it is what is left of the same five stops after
 * the sun has gone off them. The upper atmosphere emits on its own all night, and
 * this is the only reason the fourth movement has anything at all on the dark
 * three-fifths of its subject.
 */
const AIRGLOW: Rgb = mix(AIR_BAND[2]![1], AIR_BAND[3]![1], 0.55);

/** Motes in the held swarm. */
const MOTES = 34;
/** Grains of `Karman`'s ice still going past when the film opens. */
const SHED = 30;
/**
 * The faint field, and the bright one.
 *
 * More stars than any other scene has, and the reason is the turn: they are the
 * only fixed reference in the frame, so they are the only thing that can *show* a
 * rotation rather than merely undergo one. Split in two because a field of one
 * value is a texture and a rotating texture reads as noise: the thirty-four bright
 * ones are what the eye actually tracks round the turn, and the hundred and fifty
 * faint ones are the depth they are tracked against.
 */
const STARS = 150;
const BRIGHT = 34;

/**
 * The turn, in radians: how far it swings and how much of that it gives back.
 *
 * Module-level because the star field's overscan is derived from the peak rather
 * than measured off the current angle - see `drawStars`.
 */
const ROLL_SWING = 0.62;
const ROLL_SETTLE = 0.49;

/**
 * The sun, as an angle about the globe's centre, and where it goes.
 *
 * It starts where act IV's backdrop has had it for six stations - up and to the
 * right, coming round the limb - and sets by about twenty degrees across the third
 * movement. `SUN_DRIFT` is the residue that keeps crossing through the held frame,
 * far too slowly to be watched and just enough that the last picture in the act is
 * not a photograph.
 */
const SUN_AT = -0.86;
const SUN_SWEEP = 0.34;
const SUN_DRIFT = 0.08;

/**
 * The swarm's arc, as fractions of the height, and the one asymmetry in the film.
 *
 * `CLIMB` is a real climb: about a quarter of the frame, decelerating the whole
 * way, so that by the fourth movement the gold is visibly higher than the player
 * left it and visibly no longer going anywhere. The first cut of this gave them a
 * rise of thirty-eight pixels over fourteen seconds, which is arithmetically an arc
 * and is, on a screen, a group of dots sitting still.
 *
 * `FALL` is larger than `CLIMB`, and that is not a cheat about gravity. A symmetric
 * parabola takes as long to come down as it took to go up, and the film has four
 * seconds left, not fourteen - but more to the point, the design's word is that the
 * trajectory *bends* back toward Earth. A bent trajectory is what a deorbit is, the
 * player's own last stroke laid the well that bent it, and the asymmetry is the
 * campaign changing direction rather than a mote falling off a table.
 */
const CLIMB = 0.24;
const FALL = 0.85;

/** The planet, as the three numbers every pass after the turn is drawn against. */
interface Globe {
  cx: number;
  cy: number;
  r: number;
}

/** One mote at an instant. Two passes need this and neither of them owns it. */
interface Mote {
  x: number;
  y: number;
  r: number;
  a: number;
  /** Vertical speed in px/s, signed. The streak is this and nothing else. */
  vy: number;
  /** 0..1 of the fall the mote itself has done, which is not the film's clock. */
  f: number;
}

export class Overview implements Film {
  private t = -1;

  /**
   * The narrowest band of the seven, and lower than the other two space films.
   *
   * The swarm climbs about a quarter of the frame from here before it stalls, and
   * the station title sits at 0.15 - a stall that lands on the banner puts the
   * campaign's last upward movement behind a caption. It also needs room *below*
   * it for a planet to arrive in.
   */
  readonly anchor = [0.42, 0.58] as const;

  get active(): boolean {
    return this.t >= 0;
  }

  get phase(): OverviewPhase {
    if (this.t < 0) return 'idle';
    if (this.t < OVERVIEW_TURN_AT) return 'arrest';
    if (this.t < OVERVIEW_WHOLE_AT) return 'turn';
    if (this.t < OVERVIEW_LINE_AT) return 'whole';
    if (this.t < OVERVIEW_FALL_AT) return 'line';
    return 'fall';
  }

  /**
   * 0..1 how far the film has taken the frame off the live world.
   *
   * The renderer dims the live layers against this exactly as it does against
   * `Surfacing.sky` and `Release.dusk`. It runs early and fast, because the live
   * world is a course scrolling upward and this film is about to rotate: two
   * frames of a tilted horizon over an untilted course would show the seam.
   */
  get veil(): number {
    if (this.t < 0) return 0;
    return clamp(filmRamp(this.t, 0, OVERVIEW_ARREST * 0.85) * 0.97, 0, 0.97);
  }

  /**
   * True once the disc is closed and the rim is lit: the composition the whole
   * film exists to deliver has arrived, and a title may sit over it.
   */
  get settled(): boolean {
    return this.t >= OVERVIEW_LINE_AT;
  }

  /** Space, and deliberately the darkest frame in the game outside the trench. */
  readonly daylight = false;

  /** True once the gold has stalled and started to fall. Act V's first frame. */
  get turned(): boolean {
    return this.t >= OVERVIEW_FALL_AT;
  }

  /** True once the fall has been watched long enough for act V to open into it. */
  get handedOver(): boolean {
    return this.t >= OVERVIEW_FALL_AT + OVERVIEW_TAIL;
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
    this.t = Math.min(OVERVIEW_TOTAL, this.t + dt);
  }

  /**
   * How far round the camera has come, in radians.
   *
   * It overshoots and settles - a camera that arrives exactly on its mark is a
   * camera on rails, and this one is supposed to read as a thing being turned.
   * The residual tilt is deliberate and small: the held frame must not be the
   * composition the act was played in, or the turn did not happen, and it must
   * not be visibly crooked either, or it reads as a bug.
   */
  private roll(): number {
    if (this.t < 0) return 0;
    const swing = filmRamp(this.t, OVERVIEW_TURN_AT, OVERVIEW_TURN * 0.42);
    const settle = filmRamp(this.t, OVERVIEW_TURN_AT + OVERVIEW_TURN * 0.45, OVERVIEW_TURN * 0.5);
    // Peaks at about thirty-five degrees and settles to about seven. The residual
    // has to be small enough that the held frame does not read as crooked and
    // large enough that it is visibly not the frame the act was played in.
    return swing * ROLL_SWING - settle * ROLL_SETTLE;
  }

  /**
   * Where the sun is, as an angle about the globe's own centre.
   *
   * In the camera's frame rather than the screen's, like everything else drawn
   * inside the roll: the sun is as world-fixed as the planet is, so when the frame
   * turns they turn together and this angle does not know about the roll at all.
   *
   * What it does know about is that a body in low orbit gets a sunset every
   * three-quarters of an hour. The third movement spends about twenty degrees of
   * one, which is what makes the terminator arrive as a thing crossing the disc
   * rather than as a shape the disc was drawn with.
   */
  private sun(): number {
    return (
      SUN_AT +
      filmRamp(this.t, OVERVIEW_WHOLE_AT, OVERVIEW_WHOLE * 0.9) * SUN_SWEEP +
      filmRamp(this.t, OVERVIEW_LINE_AT, OVERVIEW_LINE + OVERVIEW_FALL) * SUN_DRIFT
    );
  }

  /**
   * The planet, as three numbers that carry the whole turn.
   *
   * At the film's first frame these are the geometry act IV's backdrop has been
   * drawing for six stations - a radius two and a half screens wide, centred far
   * below the frame, so the arc is nearly flat along the bottom. By the third
   * movement the radius has come down to something that fits, and the centre has
   * risen into the frame. The player is not moved; the *camera* is, and a horizon
   * that becomes a disc is what that looks like.
   */
  private globe(v: FilmView): Globe {
    // Deliberately *after* the roll rather than under it. The second movement is
    // a horizon tilting, which is the most legible rotation there is; the third
    // is that horizon closing into a shape. Done at once - which is how this was
    // written first - the roll lands on a circle, and a rotating circle looks
    // like a circle sliding sideways. The order is most of the film.
    const close = filmRamp(this.t, OVERVIEW_WHOLE_AT, OVERVIEW_WHOLE * 0.85);
    // ...and one more, slower, so the disc keeps easing back through the held
    // frame instead of parking. Very small: it is the difference between a
    // photograph and a shot.
    const drift = filmRamp(this.t, OVERVIEW_LINE_AT, OVERVIEW_LINE + OVERVIEW_FALL);
    const wide = v.w * 2.6;
    // Fits whichever way round the screen is, because "the whole Earth appears"
    // is the line in the design and a disc running off the bottom edge is not it.
    const tight = Math.min(v.w * 0.44, v.h * 0.225) * (1 - drift * 0.09);
    const r = wide + (tight - wide) * close;
    const cx = v.w * 0.5;
    // The limb starts where act IV's backdrop has been drawing it for six
    // stations, so the film's first frame is continuous with the station's last,
    // and ends holding the disc whole in the lower half of the frame.
    const from = v.h * 0.76;
    const to = v.h * (0.735 + drift * 0.02) - tight;
    return { cx, cy: from + (to - from) * close + r, r };
  }

  draw(v: FilmView): void {
    if (this.t < 0) return;
    const ctx = v.ctx;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    this.drawSpace(v);

    // The turn. Everything from here down is in the camera's frame rather than
    // the screen's, which is the whole reason this film has a `save`/`restore`
    // around it and none of the others do.
    const roll = this.roll();
    if (roll !== 0) {
      ctx.translate(v.w * 0.5, v.h * 0.5);
      ctx.rotate(roll);
      ctx.translate(-v.w * 0.5, -v.h * 0.5);
    }

    this.drawStars(v);
    const g = this.globe(v);
    this.drawLimb(v, g);
    this.drawBody(v, g);
    // In front of the planet, because that is where it is: the ice is the only
    // object in this film that is not effectively at infinity.
    this.drawShed(v);
    this.drawSwarm(v, g);
    ctx.restore();
  }

  /** The ground of the whole film: black, and rather more of it as the frame opens. */
  private drawSpace(v: FilmView): void {
    const ctx = v.ctx;
    const a = clamp(filmRamp(this.t, 0, OVERVIEW_ARREST * 0.9), 0, 1);
    if (a <= 0.01) return;
    ctx.fillStyle = rgba(VOID, 0.96 * a);
    ctx.fillRect(0, 0, v.w, v.h);
  }

  /**
   * The star field, and the one place the turn can actually be *seen*.
   *
   * A planet rotating in frame is ambiguous - it could be the planet turning. A
   * star field rotating with it is not: stars are the only fixed thing there is,
   * so if they move, the camera moved.
   *
   * Two passes, split by magnitude, and what the split is *for* is that the two
   * halves of a star field do different work. Thirty-four bright ones are few
   * enough to be individuals, which is what an eye tracks a rotation with. The
   * hundred and fifty faint ones behind them are two magnitudes down and cannot be
   * tracked at all, so they are put where they do their own job instead: pulled
   * onto one shallow diagonal, which gives the field a *direction*, and a direction
   * turning through thirty-five degrees is legible in a way that a uniform scatter
   * of dots is not.
   *
   * There is no parallax in here and there must not be. A camera rotating about its
   * own axis gets none from anything at infinity, so depth up here is a fact about
   * brightness and about nothing else, and faking the other kind would be putting
   * the one lie into the only frame in the game whose whole job is fixed reference.
   *
   * > The overscan used to be applied only on frames where the roll was actually
   * > non-zero, which is exactly the frame the second movement starts on: a
   * > hundred and fifty stars were distributed over the viewport, and then, in one
   * > frame, over an area three times larger. The field did not rotate into the
   * > turn. It was replaced by a different, sparser field on the frame the turn
   * > began, and then held that thinner sky through the whole of the picture the
   * > film is actually about. The pad is the film's own peak swing now, on every
   * > frame including the ones with no swing in them, and there are a fifth more
   * > stars to fill it.
   */
  private drawStars(v: FilmView): void {
    const ctx = v.ctx;
    const a = clamp(filmRamp(this.t, 0, OVERVIEW_ARREST), 0, 1);
    if (a <= 0.02) return;
    // Enough field to cover the corners of the frame at full swing, on every
    // frame including the ones with no swing in them. Derived rather than dialled:
    // it is the bounding box of a rotated rectangle, so it is exactly as much
    // overscan as the turn can possibly need and no more.
    const padX = Math.max(0, (v.w * Math.cos(ROLL_SWING) + v.h * Math.sin(ROLL_SWING) - v.w) * 0.5);
    const padY = Math.max(0, (v.w * Math.sin(ROLL_SWING) + v.h * Math.cos(ROLL_SWING) - v.h) * 0.5);
    const spanX = v.w + padX * 2;
    const spanY = v.h + padY * 2;
    ctx.globalCompositeOperation = 'lighter';

    // The faint field: smaller, cooler, and something like a seventh of a bright
    // star's light once the area is counted. Gathered onto the diagonal by cubing
    // the offset, which leaves the extremes where they were and pulls everything
    // else toward the line - so the sky thins out of a band rather than stopping
    // at the edge of one, and there is no drawn shape anywhere in it.
    if (v.quality > 0.4) {
      ctx.fillStyle = rgba(mix(STAR, AIRGLOW, 0.4), 0.6 * a);
      ctx.beginPath();
      for (let i = 0; i < STARS; i++) {
        const along = filmHash(i * 31);
        const off = filmHash(i * 47 + 7) * 2 - 1;
        const x = -padX + along * spanX;
        const y = -padY + (0.5 + (0.5 - along) * 0.34 + off * off * off * 0.33) * spanY;
        const r = 0.42 + filmHash(i * 13) * 0.62;
        ctx.moveTo(x + r, y);
        ctx.arc(x, y, r, 0, TAU);
      }
      ctx.fill();
    }

    // The bright ones, scattered flat across the whole field - the band is a
    // statement about how much faint light there is in a direction, not about
    // where the nearest thirty-four stars happen to be. These are the ones the
    // turn is read on, so they are the last thing dropped: at the quality tier
    // that skips the faint field they are still here, because a movement that
    // cannot be seen at all is worse than a movement drawn thin.
    ctx.fillStyle = rgba(STAR, 0.9 * a);
    ctx.beginPath();
    for (let i = 0; i < BRIGHT; i++) {
      const magnitude = filmHash(i * 71 + 3);
      const x = -padX + filmHash(i * 97 + 11) * spanX;
      const y = -padY + filmHash(i * 59 + 29) * spanY;
      const r = 0.8 + (1 - magnitude) * 1.6;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Movement 1. The frame's own motion, dying.
   *
   * `arrest` is the only movement in the film about nothing arriving, and a set of
   * fade-ups is not a way to draw a stop. What is drawn instead is the thing the
   * player has been travelling *past* for four acts: the last of the ice `Karman`
   * left coasting - it has no air to slow it and never had - running down the frame
   * faster than the course did, and shortening to nothing as the camera comes to
   * match the swarm.
   *
   * Nothing here is decelerating. The camera is, and the grains are the only
   * objects near enough to say so: everything else in this film is a planet or a
   * star, and neither of those shows a change of speed. Each grain gets its own
   * multiple of the run so the field pulls apart as it slows, which is what depth
   * looks like when the only thing that varies is distance.
   */
  private drawShed(v: FilmView): void {
    const ctx = v.ctx;
    const s = clamp(this.t / OVERVIEW_ARREST, 0, 1);
    // Cubic ease-out: the speed is exactly zero at the end of the movement rather
    // than merely small, so the frame stops rather than drifting into the turn.
    const gone = 1 - Math.pow(1 - s, 3);
    const a = (1 - filmRamp(this.t, OVERVIEW_ARREST * 0.5, OVERVIEW_ARREST * 0.4)) * 0.34;
    if (a <= 0.004) return;
    // The run is the course's own scroll and rather more: `worldSpeed` moves the
    // world at something under a hundred and fifty pixels a second by the end of
    // act IV, and a grain a few hundred metres off the swarm crosses the frame at
    // two or three times whatever the planet behind it is doing. That ratio is the
    // entire reason this element is here, so it is drawn rather than averaged out.
    const run = v.h * 0.2;
    const speed = ((3 * run) / OVERVIEW_ARREST) * (1 - s) * (1 - s);

    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(ICE, a);
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let i = 0; i < SHED; i++) {
      const near = 0.6 + filmHash(i * 83 + 13) * 0.8;
      const x = filmHash(i * 101 + 29) * v.w;
      // Spread over rather more than a frame, so a grain leaving the bottom is
      // replaced by one that was above the top rather than by a hole.
      const y = (filmHash(i * 61 + 7) * 1.45 - 0.4) * v.h + gone * run * near;
      if (y < -20 || y > v.h + 20) continue;
      // The streak is the distance covered in the last tenth of a second, the same
      // honesty rule every moving thing in this film obeys - so the whole field
      // draws its own speed, and what the player watches go out is the streaks.
      const len = speed * near * 0.1;
      ctx.moveTo(x, y - len);
      ctx.lineTo(x, y);
    }
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
  }

  /** The band's path: an annulus, and it has to be one. See `drawLimb`. */
  private ring(
    ctx: CanvasRenderingContext2D,
    g: Globe,
    outer: number,
    from: number,
    to: number,
  ): void {
    ctx.beginPath();
    ctx.arc(g.cx, g.cy, outer, from, to);
    ctx.arc(g.cx, g.cy, g.r, to, from, true);
  }

  /**
   * The line. Everything above is staging for this.
   *
   * Radial gradients centred on the planet's own centre, which curve with the limb
   * for free and are what a limb physically is - the same construction
   * `Release.drawWorld` uses, at a tenth of the thickness, because from here the
   * air really is that thin. Drawn *under* the body so the planet's edge cuts them
   * cleanly: an atmosphere that overlaps its own planet is a glow, and a glow is
   * not what this picture is about.
   *
   * Two passes, because a limb is two things. **Airglow** first: the upper
   * atmosphere emits on its own, all the way round, brightest not at the surface
   * but near the top of the band where the emission actually happens - which is the
   * inverse of the daylight stack and the reason the ring never goes out. Then
   * **scattered sunlight** over it, in wedges of one gradient whose weight follows
   * the cosine off the sun, so the band is hard and warm on the day side and thins
   * into that glow going round. The wedges share the airglow's two radii exactly:
   * the band is one ring with a varying load on it, never a ring drawn twice.
   *
   * That load arrives with the *shape*. While the limb still fills the screen there
   * is no sun side and no night side in frame - a horizon seen from inside it is all
   * at one solar angle - so the band is uniform, which is also what it has been for
   * the six stations before this one. The difference opens as the disc closes and
   * there is somewhere for it to be.
   *
   * The whole thing brightens through the fourth movement while everything else
   * fades, so the moment the player is looking at the thinnest object in the game
   * is the moment it is also the brightest.
   */
  private drawLimb(v: FilmView, g: Globe): void {
    const ctx = v.ctx;
    const p = filmRamp(this.t, OVERVIEW_TURN_AT, OVERVIEW_TURN * 0.7);
    if (p <= 0.01) return;
    // The band gains a fifth of itself over the held frame, and the breath moves
    // it by a fiftieth. Both are deliberately below the threshold of a thing you
    // watch and above the threshold of a thing you feel.
    const lit = 1 + filmRamp(this.t, OVERVIEW_LINE_AT, OVERVIEW_LINE * 0.6) * 0.22;
    const swell = 1 + (v.breath - 0.5) * 0.04;
    // Thin, and thinner as the world gets further away: at the held frame this is
    // between three and six device pixels on a phone. That is the fact.
    const air = Math.max(2.5, g.r * 0.026) * p * swell;
    const outer = g.r + air;

    ctx.globalCompositeOperation = 'lighter';
    // A *ring*, and it has to be one. A radial gradient clamps to its first stop
    // everywhere inside its inner radius, so filling the whole circle paints the
    // entire planet in the innermost colour of the atmosphere - which is orange.
    // That was invisible for exactly as long as the body's fill happened to cover
    // it, and the frame the camera rotated it stopped covering it.
    const night = ctx.createRadialGradient(g.cx, g.cy, g.r, g.cx, g.cy, outer);
    night.addColorStop(0, rgba(AIRGLOW, 0.06 * p * lit));
    night.addColorStop(0.55, rgba(AIRGLOW, 0.24 * p * lit));
    night.addColorStop(1, rgba(AIRGLOW, 0));
    ctx.fillStyle = night;
    this.ring(ctx, g, outer, 0, TAU);
    ctx.fill();

    // One gradient for the whole ring, and the wedges carry their weight on the
    // alpha rather than each mixing their own. Two reasons, and the second is the
    // real one: thirty gradients a frame to draw one ring is a silly way to spend a
    // budget, and a stop mixed per wedge is a *colour* step at every boundary,
    // where an alpha is only a brightness step - and the eye finds a hue seam on a
    // smooth band at about a third of the size it finds a brightness one.
    const glow = ctx.createRadialGradient(g.cx, g.cy, g.r, g.cx, g.cy, outer);
    for (const [stop, colour] of AIR_BAND) {
      glow.addColorStop(stop, rgba(colour, (0.8 - stop * 0.52) * p * lit));
    }
    glow.addColorStop(1, rgba(AIR_BAND[4]![1], 0));
    ctx.fillStyle = glow;
    const sun = this.sun();
    // How much of the sun side / night side difference is in frame at all: none of
    // it while the limb is bigger than the screen, all of it once the disc has a far
    // edge. The same ramp `globe` closes the shape on, because it is the same fact.
    const round = filmRamp(this.t, OVERVIEW_WHOLE_AT, OVERVIEW_WHOLE * 0.85);
    // Enough wedges that no step between two of them survives being drawn: the
    // cosine is steepest at the terminator, which is also exactly where the eye is,
    // so the count is set by that and not by the average. This is the pass that
    // degrades - at low quality the same cosine is served coarsely rather than
    // dropped, because which side of the world the sun is on is most of what this
    // band has to say.
    const wedges = v.quality > 0.5 ? 48 : 16;
    for (let i = 0; i < wedges; i++) {
      const from = (i / wedges) * TAU;
      const to = ((i + 1) / wedges) * TAU;
      // Lambert off the sub-solar point, raised a little so the day side keeps its
      // edge instead of washing evenly round into the night.
      const face = 0.5 + 0.5 * Math.cos((from + to) * 0.5 - sun);
      const day = 1 - round * (1 - Math.pow(face, 1.5));
      if (day <= 0.004) continue;
      ctx.globalAlpha = day;
      this.ring(ctx, g, outer, from, to);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The Earth itself: a terminator and two flat tones, and no detail at all.
   *
   * A textured, cloud-mapped, recognisable planet would be a different game's
   * screenshot, and worse, it would give the player something to look *at* in the
   * frame whose whole subject is a line along its edge. So the disc is
   * deliberately the least interesting object in its own shot.
   */
  private drawBody(v: FilmView, g: Globe): void {
    const ctx = v.ctx;
    const p = filmRamp(this.t, 0, OVERVIEW_ARREST * 0.7);
    if (p <= 0.01) return;
    ctx.save();
    ctx.beginPath();
    ctx.arc(g.cx, g.cy, g.r, 0, TAU);
    ctx.clip();

    // Night, everywhere, first. Filled to the clip's own bounding box rather than
    // to the viewport, because the frame is rotated by this point and a viewport
    // rectangle drawn in the camera's space no longer covers the screen's corners.
    ctx.fillStyle = rgba(NIGHT, 0.97 * p);
    ctx.fillRect(g.cx - g.r, g.cy - g.r, g.r * 2, g.r * 2);

    // ...and the day side over it, from wherever the sun currently is, with a soft
    // terminator. The sun moves; the camera moves as well, and the two are
    // separate facts - see `sun()` for why a shadow that never crosses anything is
    // the one thing a planet seen from orbit is never doing.
    //
    // In high contrast it recedes. The disc is already "deliberately the least
    // interesting object in its own shot"; this is that sentence taken one step
    // further, because the band is drawn *against* the lit half and every point of
    // brightness the day side keeps is a point of separation the line loses.
    const sunlit = 1;
    const sun = this.sun();
    const sx = g.cx + Math.cos(sun) * g.r * 0.95;
    const sy = g.cy + Math.sin(sun) * g.r * 0.95;
    const day = ctx.createRadialGradient(sx, sy, 0, sx, sy, g.r * 1.9);
    day.addColorStop(0, rgba(mix(DAY, SUN, 0.28), 0.95 * p * sunlit));
    day.addColorStop(0.42, rgba(DAY, 0.82 * p * sunlit));
    day.addColorStop(0.72, rgba(mix(DAY, NIGHT, 0.7), 0.5 * p * sunlit));
    day.addColorStop(1, rgba(NIGHT, 0));
    ctx.fillStyle = day;
    ctx.fillRect(g.cx - g.r, g.cy - g.r, g.r * 2, g.r * 2);

    // The same airglow the band is made of, seen from underneath: the air stands
    // over the night side too, and against an unlit hemisphere the little it emits
    // is the difference between a planet and a hole cut in the star field. It is
    // laid all the way round rather than only on the dark side, because limb
    // brightening is not a property of the night - the day half simply has too
    // much light on it for this to show. Additive and inside the clip, so it is a
    // ring just inside the edge and nothing anywhere else.
    ctx.globalCompositeOperation = 'lighter';
    const rim = ctx.createRadialGradient(g.cx, g.cy, g.r * 0.62, g.cx, g.cy, g.r);
    rim.addColorStop(0, rgba(AIRGLOW, 0));
    rim.addColorStop(1, rgba(AIRGLOW, 0.1 * p));
    ctx.fillStyle = rim;
    ctx.fillRect(g.cx - g.r, g.cy - g.r, g.r * 2, g.r * 2);
    ctx.globalCompositeOperation = 'source-over';
    ctx.restore();

    /*
     * One hairline on the edge. The only hard line in the picture, and it is the
     * boundary between everything the game has happened in and everything else.
     *
     * High contrast strengthens it and **must not widen it past the band it is
     * edging**. The first cut of this went to two pixels at 0.85, which on a phone
     * is six device pixels of near-white laid over an atmosphere that is four -
     * and the whole picture came back as a white ring round a dark disc. The band
     * is graded on purpose, from the troposphere's own red to the last of the
     * scattering, and an edge thick enough to cover it is not an aid to reading
     * this frame. It is a different frame. Most of what the setting spends here
     * goes into `drawLimb`'s own brightness instead.
     */
    ctx.strokeStyle = rgba(mix(AIR_BAND[2]![1], STAR, 0.35), 0.28 * p);
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(g.cx, g.cy, g.r, 0, TAU);
    ctx.stroke();
  }

  /**
   * One mote's whole ballistic state, as two halves of one motion that meet at the
   * stall with the same position and the same velocity - zero.
   *
   * Ballistic is the point rather than a flourish: act IV is the act where a stroke
   * stops being a shove and becomes a *place*, and the last thing it does is show
   * the player where the last one they made was always going to put them. Nothing
   * is pushing this arc. The motes coast, stall, and come over - one continuous
   * parabola, no cut, no switch of mode.
   *
   * Returns null for a mote that is off the frame or has nothing left to draw, so
   * both passes cull on the same arithmetic instead of each guessing at it.
   */
  private mote(v: FilmView, g: Globe, i: number): Mote | null {
    const seed = filmHash(i * 23);
    const side = filmHash(i * 37 + 5);
    const depth = filmHash(i * 53 + 11);
    // Staggered starts, so the swarm arrives at the top over about a second
    // rather than as one object.
    const tt = this.t + seed * 0.6;
    const s = clamp(tt / OVERVIEW_FALL_AT, 0, 1);
    const climb = v.h * CLIMB;
    const fall = v.h * FALL;
    // Ease-out to a dead stop: velocity is exactly zero at the stall.
    const up = climb * (2 * s - s * s);
    const f = Math.max(0, (tt - OVERVIEW_FALL_AT) / OVERVIEW_FALL);
    const down = fall * f * f;
    // The held frame breathes here as well as on the band: the swarm's own spread
    // opens and closes by a fortieth, which on thirty-four dots is a body drawing
    // breath rather than a group of dots changing size.
    const spread = 1 + (v.breath - 0.5) * 0.05;
    // A swarm, not a rung. Thirty-four dots on one horizontal line is the
    // arrangement they must never be in, and it is what a single lane index
    // gives you: the vertical spread has to be comparable to the horizontal
    // before the eye reads a body rather than a row.
    const lateral = v.x + (side - 0.5) * v.w * 0.42 * spread;
    // ...and as they come over, the lane bends toward the middle of the disc. A
    // deorbit is a corridor rather than a spray: the well the player's own last
    // stroke laid is under the centre of that circle, so the swarm narrows as it
    // goes, and the narrowing is the first thing act V's entry is made of.
    const x = lateral + (down / fall) * (g.cx - lateral) * 0.34;
    const y = v.y + (depth - 0.5) * v.h * 0.12 * spread - up + down;
    if (y > v.h + 40 || y < -60) return null;

    // They dim as the fourth movement takes the frame, because the line is
    // supposed to be the brightest thing in it - and come back up as they fall,
    // because by then they are the only thing moving. Only a quarter, though:
    // gold at half alpha stops being gold and becomes khaki, and the one colour
    // that has to survive all seven acts cannot go grey at the campaign's peak.
    //
    // The per-mote spread underneath that is a depth cue and is kept narrow for the
    // same reason. It used to run from 0.55, which was harmless while the swarm was
    // over black and is not once it is over a lit planet: a mote at 0.55 laid on the
    // day side comes out as the average of gold and ocean, which is grey.
    const quiet = 1 - filmRamp(this.t, OVERVIEW_LINE_AT, OVERVIEW_LINE * 0.7) * 0.25;
    const back = f <= 0 ? 0 : filmRamp(this.t, OVERVIEW_FALL_AT, OVERVIEW_FALL * 0.5) * 0.5;
    const a = clamp((quiet + back) * (0.72 + seed * 0.28), 0, 1);
    if (a <= 0.02) return null;
    // The streak is the distance covered in the last tenth of a second, so it
    // shortens to nothing at the stall and grows downward afterwards. The
    // direction of that one line is the whole handover.
    const vy = f > 0 ? (2 * fall * f) / OVERVIEW_FALL : (-2 * climb * (1 - s)) / OVERVIEW_FALL_AT;
    return { x, y, r: 1.2 + seed * 1.5, a, vy, f };
  }

  /**
   * The carried life, at the top of its arc.
   *
   * `v.x`/`v.y` anchor the start, so the gold leaves from where the player actually
   * left it. Nothing is re-centred for the camera: they were already there.
   *
   * Three passes, and the order is the whole reason there are three. The air comes
   * first, additive, because it is light. The gold goes on top of it in
   * `source-over`, because it is not: additive gold laid over the lit half of a
   * planet is not brighter gold, it is white, and the one colour the campaign has
   * carried since the first rescue ring cannot be allowed to leave the frame as
   * whatever the disc underneath it happened to sum to. Against the black it looks
   * the same either way, which is exactly how this went unnoticed until the motes
   * started crossing the Earth. Then the wash, last and wide.
   */
  private drawSwarm(v: FilmView, g: Globe): void {
    const ctx = v.ctx;
    const falling = this.t - OVERVIEW_FALL_AT;

    if (falling > 0) {
      // The first of the air, on whatever is lowest. Not a recolour of the gold and
      // never one - this is a separate thing arriving *in front of* each mote, in
      // the band's own bottom stop, which is the colour act V spends five minutes
      // in. Drawn ahead of the motes rather than behind them because that is where
      // it physically is: what glows on the way in is the air being compressed, and
      // the compression is in front.
      ctx.globalCompositeOperation = 'lighter';
      const limb = g.cy - g.r;
      const reach = v.h * 0.3;
      for (let i = 0; i < MOTES; i++) {
        const m = this.mote(v, g, i);
        if (m === null) continue;
        // Off the mote's own fall rather than off the film's clock: the starts are
        // staggered, so the ones that left first are both lower and further into
        // it, and the front of the swarm should light before the back of it does.
        const heat = clamp((m.y - (limb - reach)) / reach, 0, 1) * clamp(m.f * 2, 0, 1);
        if (heat <= 0.03) continue;
        ctx.strokeStyle = rgba(AIR_BAND[0]![1], 0.22 * heat * m.a);
        ctx.lineWidth = Math.max(0.9, m.r * 0.8);
        ctx.beginPath();
        ctx.moveTo(m.x, m.y);
        ctx.lineTo(m.x, m.y + m.r * 2.2 + heat * 7);
        ctx.stroke();
      }
    }

    ctx.globalCompositeOperation = 'source-over';
    for (let i = 0; i < MOTES; i++) {
      const m = this.mote(v, g, i);
      if (m === null) continue;
      ctx.fillStyle = rgba(MOTE, 0.88 * m.a);
      ctx.beginPath();
      ctx.arc(m.x, m.y, m.r, 0, TAU);
      ctx.fill();
      if (Math.abs(m.vy) < 2) continue;
      ctx.strokeStyle = rgba(MOTE, 0.32 * m.a);
      ctx.lineWidth = Math.max(0.8, m.r * 0.65);
      ctx.beginPath();
      ctx.moveTo(m.x, m.y - m.vy * 0.1);
      ctx.lineTo(m.x, m.y);
      ctx.stroke();
    }

    // As they come over, the light they cast reaches the disc: one faint warm
    // wash on the limb below them. The gold is going home and the picture says so
    // half a movement before the motes do. It is a softener - a wide, pale,
    // additive field whose whole job is to stop the swarm and the planet having an
    // edge between them - so high contrast takes most of it back.
    if (falling > 0) {
      ctx.globalCompositeOperation = 'lighter';
      const glow = clamp(falling / OVERVIEW_FALL, 0, 1) * 0.14;
      const gy = g.cy - g.r;
      const wash = ctx.createRadialGradient(v.x, gy, 0, v.x, gy, v.w * 0.5);
      wash.addColorStop(0, rgba(MOTE, glow));
      wash.addColorStop(1, rgba(MOTE, 0));
      ctx.fillStyle = wash;
      ctx.fillRect(0, gy - v.h * 0.3, v.w, v.h * 0.6);
      ctx.globalCompositeOperation = 'source-over';
    }
  }
}
