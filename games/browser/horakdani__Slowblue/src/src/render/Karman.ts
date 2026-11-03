import { TAU, clamp } from '../core/math';
import { filmHash, filmRamp, type Film, type FilmView } from './Films';
import { rgba, type Rgb } from './Paint';

/**
 * Slowblue: the stroke that does nothing.
 *
 * Act III ends at the Karman line, and §7 says what happens there in one
 * sentence: *the player's first stroke makes no wind, and the motes carry on
 * anyway, on the momentum they already had.* That is the entire teaching for act
 * IV, it arrives with no text, and this film is what it looks like.
 *
 * The other endings are gifts - a sky, a sunrise, a whole planet. This one is a
 * **subtraction**, and it is the only film in the game built out of an absence.
 * Everything it shows is something the player has watched work for three acts,
 * shown once more not working, and then taken out of the frame:
 *
 *   1. `thin`   - the last air drains. The haze along the bottom of the frame
 *                 sinks and thins, the black comes down from the top, and the ice
 *                 act III left in the air is still being carried by it. On the
 *                 last frame of the movement the ice **stops dead**, mid-drift,
 *                 and stays exactly where it was for the rest of the film. Nothing
 *                 announces it. That stop is the first half of the lesson.
 *   2. `vacuum` - seven tenths of a second in which nothing arrives. No cue, no
 *                 new element, no ramp starting: the ice that stopped is still
 *                 stopped, the sky goes on resolving behind it, and the film
 *                 waits. It is the shortest movement in the game and the only one
 *                 whose content is that it has none - and it is here because the
 *                 gesture in the next movement has to land in a frame the player
 *                 has *already watched* go inert. The ice stopping, the hand
 *                 appearing and the sound changing used to fall on one frame, and
 *                 three things at once is a coincidence rather than a consequence.
 *   3. `stroke` - a hand draws the game's own gesture across that dead frame. This
 *                 is deliberately the arc `Renderer.drawHint` has been showing
 *                 since the first thirty seconds of act I, in the colour it draws
 *                 it in, because the player has to recognise it as *the thing they
 *                 do* rather than read it as an effect. One small puff of the last
 *                 air answers the first tenth of it and dies inside half a second.
 *                 After that the stroke crosses the whole frame and the world does
 *                 not respond to any of it. The laid current stays drawn, and
 *                 nothing is in it.
 *   4. `coast`  - the motes carry on. They were already moving when the film
 *                 started, they are moving at exactly the same speed now, and they
 *                 rise into the laid arc and through it without bending. Their
 *                 streaks are the shortest in the game and never change length,
 *                 which is what constant velocity looks like when it is drawn
 *                 honestly. Everything else in the frame leaves during it.
 *
 * Act IV opens into the coast, so the first frame the player is given control of
 * is a swarm already moving with nothing pushing it - which is act IV.
 *
 * ## What the coast is allowed to do
 *
 * Stasis is the thesis, and for a while the coast was the thesis taken literally:
 * every ramp in the film finished inside six seconds and then eight more ran with
 * nothing arriving in any of them. That is not a coast. It is a held frame with a
 * slow swarm on it, and thirty-odd pixels a second among motionless stars for
 * eight seconds reads as the game having stopped rather than as the world having.
 *
 * So the coast has events, and every one of them obeys the rule the film is about:
 * **nothing accelerates, and nothing is added.** Each is a subtraction on its own
 * slow clock, and they are spaced so that no two of them are ever the same beat -
 *
 *   * the swarm reaches the laid arc on almost exactly the frame the movement
 *     opens, and spends the next four and a third seconds crossing it, unbent.
 *     That is the sentence the third movement wrote, and the coast is where it is
 *     proved rather than claimed;
 *   * at eight and a fifth the last hairline of atmosphere along the bottom edge
 *     fades out, over most of two seconds, and the frame has no medium left in it
 *     at all;
 *   * at eleven and three tenths - a few tenths after the body of the swarm is
 *     through it - the arc goes as well. The stroke outlasts its own usefulness
 *     by five seconds and then stops being there.
 *
 * The one thing that *arrives* is the sky. The star field deliberately does not
 * finish with the third movement: about a quarter of its magnitudes are still to
 * come when the coast opens, and they resolve one at a time right through it,
 * none of them much over half a pixel across, so something is still filling in
 * while everything else is leaving - the last of them lands on the frame act IV
 * is handed. What is there at the end is the film's three terms with the player's
 * two taken away: a sky, ice that stopped, and gold that did not.
 *
 * `v.paint` is not read anywhere in this file, and that is the film rather than
 * an omission: the live palette is the colour of a medium, and from the second
 * movement on this picture does not have one.
 *
 * > There were four movements here once before and they were not these four. The
 * > extra one was on the end, it was called `open`, and it was the coast again
 * > with the star field finished and the band gone off the bottom edge - and
 * > **no player would ever have seen a frame of it**, because the handover fired
 * > inside the third. The handover has to fall in the *last*
 * > movement of a film or the film has content nobody can reach; every other
 * > ending in the game already did that and this one did not, which is why
 * > `tests/films.test.ts` now asserts it for all seven. What was really wrong is
 * > that `open` was never a movement: it was the coast continuing. Both of the
 * > things it wanted to show - the sky finishing and the last of the air going -
 * > happen inside the coast now, on their own clocks, in front of a player who is
 * > still holding the frame.
 *
 * ## The held frame
 *
 * Two things breathe on it, and they are the same thing twice: the swarm's own
 * glow, by three per cent, and the motes inside it, by two. Nothing else is
 * allowed to, and that is a composition rather than a saving - the ice is dead,
 * the arc has gone and the air has gone, so the only thing in the picture that
 * changes at all is the only thing in it that is alive.
 *
 * ## Reduced motion
 *
 * Nothing here is dropped, because nothing here is vestibular: the frame never
 * moves, the camera never turns, and the fastest thing in the picture is a mote
 * covering three pixels a tenth of a second. What `still` takes out is the star
 * twinkle, exactly as it does in `Release`. The ice's drift and its stop are
 * *kept* - they are the lesson, not decoration, and a player on reduced motion is
 * owed the lesson - and so is every event in the coast, which is why all four of
 * them are on the film's own clock rather than on `v.time`.
 *
 * ## High contrast
 *
 * This film is an argument with three terms in it - a gesture, ice that stops, and
 * a swarm that does not bend - and a player who cannot see any one of them is not
 * shown a dimmer version of the argument. They are shown a screen where nothing
 * happens. So all three go up hard: the hand's arc roughly doubles and thickens,
 * the ice keeps most of its light instead of fading to a sixth of it, and the
 * motes and their constant streaks brighten.
 *
 * Two things come the other way, and both are softeners. The glow the swarm sits
 * in is a wash whose only job is to make thirty separate dots read as one body,
 * so it comes down to a third and the motes it was doing that with go up instead.
 * And the air leaving must **not** be given back: its geometry - an eighth of the
 * frame at the first frame, two and a half pixels along the bottom edge at the
 * last - is the film telling the player the medium ran out, so the thinning is
 * untouched and only the alpha rises, with a floor of three pixels so what is
 * left is still a line rather than a rounding error. A thicker band would be a
 * different sentence.
 */

/** Movement lengths, in seconds. */
export const KARMAN_THIN = 2.4;
/**
 * The movement with nothing in it.
 *
 * Long enough that the frame is read as inert rather than as paused between two
 * things, short enough that it is never suspected of being a load. Seven tenths
 * is about forty frames, which is roughly twice what it takes for the eye to stop
 * expecting the next event.
 */
export const KARMAN_VACUUM = 0.7;
export const KARMAN_STROKE = 3.2;
/**
 * The longest single movement of any film in the game, and it has to be: it is
 * the one the handover happens inside, it is the one act IV opens into, and
 * nothing in it speeds up or slows down. A coast that ends is not a coast; a
 * coast with nothing happening in it is not one either, it is a still.
 */
export const KARMAN_COAST = 8.8;

/**
 * The frame the air gives out.
 *
 * The ice freezes here, with no easing and no cue on it, and then the film says
 * nothing for the length of `KARMAN_VACUUM`. Everything else in the picture is
 * the consequence of this one moment.
 */
export const KARMAN_VACUUM_AT = KARMAN_THIN;
/** The frame the hand appears, into a picture that has been dead for a beat. */
export const KARMAN_STROKE_AT = KARMAN_VACUUM_AT + KARMAN_VACUUM;
/** The frame the hand has finished drawing and nothing has answered it. */
export const KARMAN_COAST_AT = KARMAN_STROKE_AT + KARMAN_STROKE;
export const KARMAN_TOTAL = KARMAN_COAST_AT + KARMAN_COAST;
/**
 * Film seconds the coast is watched before act IV opens into it.
 *
 * The longest wait of the seven endings, and the reason is arithmetic rather than
 * taste: the coast's last event starts at five seconds into the movement and
 * takes nearly two more, and the frame the next act opens is the frame this film
 * is reset in. A tail that came before them would have been a tail that made them
 * unreachable - which is exactly the mistake the note above this class records.
 *
 * What the player gets for it is the whole of the point: the swarm keeps its
 * speed with nothing acting on it for seven seconds, long enough to believe, and
 * then gets the controls back while it is still doing that.
 */
export const KARMAN_TAIL = 6.9;

export type KarmanPhase = 'idle' | 'thin' | 'vacuum' | 'stroke' | 'coast';

/** Space, as act IV draws it. Shared with `Release` and `Overview` by value. */
const VOID: Rgb = [2, 3, 10];
const STAR: Rgb = [235, 242, 255];
/** Pod-gold. The carried life has been this colour since the first rescue ring. */
const MOTE: Rgb = [255, 233, 178];
/** Act III's ice: what is left in the air, and what stops when the air does. */
const ICE: Rgb = [198, 226, 246];
/**
 * The hint's own colour, and it has to be exactly this.
 *
 * `Renderer.drawHint` draws the game's one instruction in `rgba(214,248,255,a)`.
 * The whole force of the third movement is that the player recognises the shape
 * and the colour as *theirs* before they notice nothing happened, so this is a
 * quotation rather than a palette choice.
 */
const HAND: Rgb = [214, 248, 255];

/**
 * The atmosphere, edge-on, in five stops.
 *
 * The same table `Release` and `Overview` use, and the same reason for copying it
 * rather than importing it: this is the third of four times the player sees this
 * band, and a change to act II's ending must not silently redraw act III's.
 */
const AIR_BAND: readonly (readonly [number, Rgb])[] = [
  [0, [255, 146, 72]],
  [0.22, [255, 208, 150]],
  [0.44, [186, 226, 255]],
  [0.7, [86, 150, 240]],
  [1, [30, 40, 120]],
];

/**
 * When the last hairline of air goes out, and how long it takes to.
 *
 * Stated against the start of the coast rather than in absolute seconds, so that
 * retiming the movement carries its events with it. Two seconds into the coast is
 * late enough that the player has stopped expecting anything from the bottom of
 * the frame, and the fade is slow enough that there is no frame you could point
 * at and call the one it happened on.
 */
const AIR_GOES_AT = KARMAN_COAST_AT + 1.9;
const AIR_GOES_OVER = 1.7;
/**
 * ...and when the stroke itself goes.
 *
 * Five seconds into the coast, which is a few tenths after the body of the swarm
 * has finished crossing it. The order is the composition: the arc waits until the
 * thing it failed to move is through, and then it is not there either.
 */
const ARC_GOES_AT = KARMAN_COAST_AT + 5;
const ARC_GOES_OVER = 1.8;

/** Motes in the coasting stream. */
const MOTES = 30;
/** Ice grains left in the last of the air. */
const GRAINS = 26;
/** Stars in the field. */
const STARS = 96;

/**
 * The coast, in pixels per second.
 *
 * Slow, and deliberately the slowest thing any film in the game moves, because
 * the streak drawn behind it is the distance covered in the last tenth of a
 * second and that number has to stay honest. Under three pixels behind a
 * two-pixel mote reads as motion; it does not read as *thrust*, which is the
 * point.
 *
 * The value is set by the one composition problem the coast has. The swarm is
 * given the frame to cross and it must still be *in* the frame when act IV takes
 * it: at this speed the body starts in the lower half, lies across the middle
 * when the arc goes, and is three hundred and fifty pixels further on at the
 * handover with every mote of it still on screen. At thirty-four - which is what
 * this was, chosen when act IV opened five seconds earlier than it does now -
 * about a third of the swarm had gone over the top edge by then, and the frame it
 * opened into had a hole in it exactly where the thing the player had been
 * holding together for seventeen minutes used to be.
 */
export const KARMAN_COAST_SPEED = 27;

export class Karman implements Film {
  private t = -1;

  /**
   * Low, and one of the narrowest bands in the game.
   *
   * The coast is one body crossing most of a screen in a straight line for eight
   * and a half seconds, so where it starts is what decides whether any of it is
   * still on screen when act IV opens - and a swarm that began the film in the
   * top third has left over the top edge before the handover, which is a hole in
   * the frame exactly where the next act puts the thing the player is holding.
   * Starting low also gives the film the picture it wants: gold in the lower half
   * with the last of the air under it, rising away from both.
   *
   * The camera holds the swarm at 0.62 of the height on a climbing act, so the
   * band is built around that number rather than around the middle of the frame.
   * A run that ended with the swarm where the camera keeps it is not clamped at
   * all; only one that surged ahead of the camera or fell behind it is moved.
   */
  readonly anchor = [0.56, 0.74] as const;

  get active(): boolean {
    return this.t >= 0;
  }

  get phase(): KarmanPhase {
    if (this.t < 0) return 'idle';
    if (this.t < KARMAN_VACUUM_AT) return 'thin';
    if (this.t < KARMAN_STROKE_AT) return 'vacuum';
    if (this.t < KARMAN_COAST_AT) return 'stroke';
    return 'coast';
  }

  /**
   * 0..1 how far the frame has left act III behind.
   *
   * Fast and early, like the overview's, and for a related reason: what is under
   * this film is a course full of ice and layered wind, and the film's whole
   * subject is that none of that is there any more. Two frames of a jet stream
   * under a vacuum would be the seam showing.
   */
  get veil(): number {
    if (this.t < 0) return 0;
    return clamp(filmRamp(this.t, 0, KARMAN_THIN * 0.92) * 0.95, 0, 0.95);
  }

  /** True once the hand has been answered by nothing. The lesson has landed. */
  get taught(): boolean {
    return this.t >= KARMAN_COAST_AT;
  }

  /** True once the picture is space and a title may sit over it. */
  get settled(): boolean {
    return this.t >= KARMAN_COAST_AT;
  }

  /** Space. What light is left is a hairline along the very bottom edge. */
  readonly daylight = false;

  /** True once the coast has been watched long enough for act IV to open into it. */
  get handedOver(): boolean {
    return this.t >= KARMAN_COAST_AT + KARMAN_TAIL;
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
    this.t = Math.min(KARMAN_TOTAL, this.t + dt);
  }

  draw(v: FilmView): void {
    if (this.t < 0) return;
    const ctx = v.ctx;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    this.drawSpace(v);
    this.drawStars(v);
    this.drawLimb(v);
    this.drawIce(v);
    this.drawStroke(v);
    this.drawGlow(v);
    this.drawSwarm(v);
    ctx.restore();
  }

  /** The ground of the film: black, arriving from the top as the air goes. */
  private drawSpace(v: FilmView): void {
    const ctx = v.ctx;
    const a = filmRamp(this.t, 0, KARMAN_THIN * 0.95);
    if (a <= 0.01) return;
    // Deepest at the top and thinnest at the bottom, because that is the
    // direction the air actually thins in and the direction the swarm is going.
    // High contrast closes it to opaque. The cheapest contrast there is in a frame
    // this dark is taking the live world's last few per cent out from behind it.
    const deep = 0;
    const g = ctx.createLinearGradient(0, 0, 0, v.h);
    g.addColorStop(0, rgba(VOID, (0.97 + deep * 0.03) * a));
    g.addColorStop(0.72, rgba(VOID, (0.93 + deep * 0.07) * a));
    g.addColorStop(1, rgba(VOID, (0.7 + deep * 0.24) * a));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, v.w, v.h);
  }

  /**
   * The stars, resolving in order of brightness. The same rule `Release` uses,
   * with one difference that is the coast's whole answer to being empty.
   *
   * There are two clocks on this field rather than one. `shown` is how much light
   * the sky has, and it is finished by the middle of the third movement, so the
   * picture does not go on getting brighter behind a swarm that is supposed to be
   * the only thing changing. `resolved` is how much of the sky is *there*, and it
   * is still climbing at thirteen seconds: about a quarter of the magnitudes have
   * yet to arrive when the coast opens, and they come one at a time all the way to
   * the handover, each of them a fraction of a pixel across and each of them born
   * out of nothing rather than switched on, because `born` scales the radius as
   * well as gating it. Nobody watches that happen. Everybody notices that the
   * frame is not dead.
   */
  private drawStars(v: FilmView): void {
    if (v.quality <= 0.4) return;
    const ctx = v.ctx;
    const shown = filmRamp(this.t, KARMAN_THIN * 0.4, KARMAN_THIN + KARMAN_STROKE * 0.6);
    if (shown <= 0.02) return;
    const resolved = 0.6 + 0.207 * filmRamp(this.t, KARMAN_COAST_AT, KARMAN_COAST * 0.8);
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = rgba(STAR, 0.66 * shown);
    ctx.beginPath();
    for (let i = 0; i < STARS; i++) {
      const magnitude = filmHash(i * 13);
      const born = clamp(shown * resolved * 1.4 - magnitude, 0, 1);
      if (born <= 0) continue;
      const x = filmHash(i * 31) * v.w;
      // Crowded toward the top: the dark is deepest where the air is thinnest.
      const hy = filmHash(i * 47 + 7);
      const y = hy * hy * v.h * 0.88;
      const tw = 0.78 + 0.22 * Math.sin(v.time * (0.42 + magnitude) + i * 2.2);
      const r = (0.42 + (1 - magnitude) * 1.1) * born * tw;
      if (r <= 0.05) continue;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The last of the atmosphere: a band along the bottom that sinks, thins, and
   * finally is not there.
   *
   * One radial gradient on a planet centre far below the frame, which is what a
   * limb physically is and what both of the other space films draw. What is
   * different here is that it is *leaving*, in two separate acts. Over the first
   * three movements it sinks onto the bottom edge and thins from an eighth of the
   * frame to two and a half pixels - the player is not told the air ran out, they
   * watch it - and then, two seconds into the coast and long after they have
   * stopped looking at the bottom of the screen, the hairline that is left fades
   * out over most of two more. That second event is the only thing in the film
   * that removes an element outright, and it is deliberately the quietest.
   *
   * > It used to sink further than it thinned, so by the middle of the third
   * > movement the whole band was below the bottom edge - a hairline nobody could
   * > see going out, in a film whose subject is the medium leaving. The sink now
   * > lands the band exactly on the edge and stops there, which is both the
   * > correct picture and the only one where the last event has anything to
   * > happen to.
   */
  private drawLimb(v: FilmView): void {
    const ctx = v.ctx;
    // How far the air has gone, over the first three movements rather than one.
    const gone = filmRamp(this.t, 0, KARMAN_THIN + KARMAN_STROKE * 0.9);
    // ...and then the separate, later event: the last of it going out.
    const out = filmRamp(this.t, AIR_GOES_AT, AIR_GOES_OVER);
    if (out >= 1) return;
    const r = v.w * 2.4;
    const cx = v.w * 0.5;
    // Sinking: the horizon drops as the swarm rises off it, and comes to rest with
    // the band lying exactly along the bottom edge - `0.965 + 0.035` is 1.
    const cy = v.h * (0.965 + gone * 0.035) + r;
    // Thinning: an eighth of the frame at the start, two and a half pixels at the
    // end. High contrast raises the floor and nothing else about the shape,
    // because the shape is the sentence: the air is *going*. Three pixels is still
    // a hairline.
    const air = Math.max(1.5, v.h * 0.115 * (1 - gone * 0.975));
    const lit = 1 - out;

    ctx.globalCompositeOperation = 'lighter';
    const glow = ctx.createRadialGradient(cx, cy, r, cx, cy, r + air);
    for (const [stop, colour] of AIR_BAND) {
      glow.addColorStop(stop, rgba(colour, (0.62 - stop * 0.42) * (1 - gone * 0.55) * lit));
    }
    glow.addColorStop(1, rgba(AIR_BAND[4]![1], 0));
    ctx.fillStyle = glow;
    // A ring, never a disc: a radial gradient clamps to its first stop everywhere
    // inside its inner radius, so a filled circle paints the whole planet orange.
    ctx.beginPath();
    ctx.arc(cx, cy, r + air, 0, TAU);
    ctx.arc(cx, cy, r, 0, TAU, true);
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The ice act III was flying in, and the frame it stops on.
   *
   * Every grain drifts on the last of the wind for the first movement and then
   * holds its position for the remaining twelve seconds. There is no easing on
   * the stop and no cue on it: the air simply runs out, and a thing that was being
   * carried is not being carried any more. It is the cheapest effect in the film
   * and the one that does the most work, and the whole of the second movement
   * exists to give it a frame of its own before the hand arrives on top of it.
   *
   * It is also the one thing the film subtracts nothing from. The air goes, the
   * stroke goes; ice left in vacuum is still there, and it is still there on the
   * held frame, which is what makes the held frame an argument rather than a sky.
   */
  private drawIce(v: FilmView): void {
    if (v.quality <= 0.5) return;
    const ctx = v.ctx;
    // The clock the wind runs on: it stops when the air does, and everything
    // downstream of this line is frozen by that one `Math.min`.
    const wind = Math.min(this.t, KARMAN_VACUUM_AT);
    // ...and they fade as the light goes with the air, but never all the way out.
    // In high contrast they barely fade at all: a grain the player cannot see
    // cannot be seen to have stopped, and the stop is half of what this film is
    // for.
    const lit = 1 - filmRamp(this.t, 0, KARMAN_THIN + KARMAN_STROKE) * 0.62;
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = rgba(ICE, 0.4 * lit);
    ctx.beginPath();
    for (let i = 0; i < GRAINS; i++) {
      const seed = filmHash(i * 17);
      const lane = filmHash(i * 29 + 3);
      // Bands, going different ways at different speeds - act III's own picture of
      // the upper atmosphere, in its last two seconds of being true.
      const dir = lane < 0.5 ? 1 : -1;
      const speed = (26 + seed * 54) * dir;
      const x = ((seed * v.w + speed * wind) % (v.w + 60) + v.w + 60) % (v.w + 60) - 30;
      const y = v.h * (0.12 + lane * 0.78) + Math.sin(i * 2.3) * 14;
      const r = 0.7 + seed * 1.3;
      ctx.moveTo(x + r, y);
      ctx.arc(x, y, r, 0, TAU);
    }
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The gesture, the world's answer to it, and - eight seconds later - its own
   * disappearance.
   *
   * The arc is `Renderer.drawHint`'s, at the same proportions and in the same
   * colour, because it has to be recognised rather than read. It draws across the
   * frame over about a second and a half and then holds, empty, while the swarm
   * rises into it.
   *
   * It is laid a third of the frame above the swarm, and that number is doing
   * compositional work rather than decorative: the head of the body arrives at it
   * within a twentieth of a second of the movement turning over, and the rest
   * takes four and a third more to pass through, so the longest stretch of the
   * film is spent watching gold cross a line that is supposed to move it and does
   * not. Then it goes. A current laid in water decays to a floor and
   * sits there; there is nothing up here to hold one, so this one does not fade
   * to a residue, it stops being drawn - which is the same sentence the ice
   * refuses to say and the reason the two are on opposite sides of the argument.
   *
   * The puff is the whole of the third movement. The first tenth of the stroke
   * gets three short tracers, exactly as every stroke in the game has for three
   * acts, and they die inside half a second and are never replaced. That is the
   * last wind in the campaign's climb, and it is over before the hand has crossed
   * a fifth of the screen.
   */
  private drawStroke(v: FilmView): void {
    if (this.t < KARMAN_STROKE_AT) return;
    const ctx = v.ctx;
    const since = this.t - KARMAN_STROKE_AT;
    // Drawn over the first half of the movement, then left where it was.
    const drawn = clamp(since / (KARMAN_STROKE * 0.5), 0, 1);
    // Two decays, and they mean different things. The first is the current
    // thinning the way a laid one does; the second is the coast's last event, and
    // it goes to exactly nothing.
    const decay = 1 - filmRamp(this.t, KARMAN_COAST_AT, KARMAN_COAST * 0.55) * 0.42;
    const trace = decay * (1 - filmRamp(this.t, ARC_GOES_AT, ARC_GOES_OVER));
    if (trace <= 0.004) return;
    // A third of the frame above the swarm, so the motes rise into it, cross it
    // and come out the other side unbent. Floored clear of the closing banner at
    // 0.15 of the height, which a run that ended high on screen would otherwise
    // draw the game's own gesture straight through.
    const cy = Math.max(v.h * 0.26, v.y - v.h * 0.31);
    const cx = v.w * 0.5;
    const rx = v.w * 0.31;
    const lift = v.h * 0.045;

    // The gesture has to be *recognised*, not merely present - the third movement
    // does not work at all if the player does not read this as the thing they have
    // been doing for three acts. It is the first thing high contrast spends on.
    ctx.globalCompositeOperation = 'lighter';
    ctx.strokeStyle = rgba(HAND, 0.34 * trace);
    ctx.lineWidth = 2;
    ctx.beginPath();
    for (let i = 0; i <= 26; i++) {
      const p = (i / 26) * drawn;
      const px = cx - rx + p * rx * 2;
      const py = cy - Math.sin(p * Math.PI) * lift;
      if (i === 0) ctx.moveTo(px, py);
      else ctx.lineTo(px, py);
    }
    ctx.stroke();

    // The hand itself, while it is still moving.
    if (drawn < 1) {
      const hx = cx - rx + drawn * rx * 2;
      const hy = cy - Math.sin(drawn * Math.PI) * lift;
      ctx.fillStyle = rgba(HAND, 0.72);
      ctx.beginPath();
      ctx.arc(hx, hy, 6, 0, TAU);
      ctx.fill();
    }

    /*
     * The last wind in the game, and it is gone before the hand is a fifth of
     * the way across.
     *
     * Three tracers, *trailing* the hand rather than reaching out in front of
     * it, and that is a correction: they were anchored to fixed points near the
     * start of the arc and drawn forward, so on the frames the hand had barely
     * moved they lay across it and pointed the way it was going. Which reads as
     * the stroke working - the exact opposite of the film. Air the hand has
     * pushed is *behind* the hand, and a tracer is the streak something moving
     * leaves, so the head is ahead of the tail and both are behind the finger.
     */
    const puff = clamp(since / 0.55, 0, 1);
    if (puff < 1) {
      const alive = 1 - puff;
      ctx.lineWidth = 1.4;
      for (let i = 0; i < 3; i++) {
        // Behind the hand, and further behind it the older the tracer is.
        const p = Math.max(0, drawn - 0.05 - i * 0.045);
        const px = cx - rx + p * rx * 2;
        const py = cy - Math.sin(p * Math.PI) * lift + (i - 1) * 8;
        // The tracer is how far the air carried what was in it. It starts at a
        // stroke's worth and collapses into its own head, which is what a medium
        // giving out looks like from inside it.
        const len = 26 * alive;
        if (len < 0.6) continue;
        ctx.strokeStyle = rgba(HAND, 0.42 * alive * alive * (1 - i * 0.22));
        ctx.beginPath();
        ctx.moveTo(px - len, py);
        ctx.lineTo(px, py);
        ctx.stroke();
      }
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The light the swarm is sitting in, and the one thing on the held frame that
   * moves without going anywhere.
   *
   * Thirty gold points on black are thirty gold points; the eye reads confetti,
   * not a body, and the body is what the player has been holding together since
   * the trench floor. One wide, very faint warm gradient travelling with them at
   * their own speed is the whole of the fix, and it costs a single gradient fill.
   *
   * It is also where the film breathes. Three per cent on the radius, off
   * `v.breath`, which is nothing to watch and everything to feel on a frame whose
   * every other element has finished changing - and it is exactly neutral at 0.5,
   * so the swell is a swell rather than a bias.
   *
   * In high contrast it comes down to a third. A full-screen wash whose entire
   * purpose is to stop separate bright things having edges between them is the
   * exact thing that setting exists to give back, and the motes take the light it
   * gives up.
   */
  private drawGlow(v: FilmView): void {
    const ctx = v.ctx;
    // Centred a little below the leading edge, where the body actually is: the
    // tail is cubed, so most of the swarm is within a twentieth of the frame of
    // its own head.
    const gy = v.y - v.h * 0.06 - KARMAN_COAST_SPEED * this.t;
    const r = v.h * 0.2 * (1 + (v.breath - 0.5) * 0.06);
    const a = 0.09;
    ctx.globalCompositeOperation = 'lighter';
    const wash = ctx.createRadialGradient(v.x, gy, 0, v.x, gy, r);
    wash.addColorStop(0, rgba(MOTE, a));
    wash.addColorStop(0.45, rgba(MOTE, a * 0.34));
    wash.addColorStop(1, rgba(MOTE, 0));
    ctx.fillStyle = wash;
    ctx.fillRect(v.x - r, gy - r, r * 2, r * 2);
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The motes, on the momentum they already had.
   *
   * There is no acceleration term anywhere in this function and that is the whole
   * point of it: position is `start - speed * t`, the streak behind each one is
   * the distance it covered in the last tenth of a second and therefore never
   * changes length, and the stroke crossing the frame does not appear in the
   * arithmetic at all. Compare `Release`, where the stream accelerates away from
   * the flock, and `Overview`, where it is on a parabola. Three films, three
   * different laws, each one drawn honestly.
   *
   * They keep the footprint the player was holding them in, and that is a
   * correction. The first cut spread them along the direction of travel across
   * nearly two screens, on the reasoning that a long enough stream always has
   * some of itself in frame - and what it produced was **evenly scattered dust**,
   * because that is what a uniform distribution over a whole screen is. The body
   * of life the player had spent seventeen minutes holding together dissolved on
   * the frame the film started, which is the opposite of what the handover says.
   * It is a swarm with a short tail of stragglers now, and it stays one.
   *
   * The sideways drift is on its own hash channel, and that is the second
   * correction. It came off the same number as the lateral *position*, so the
   * motes on the left all went left and the ones on the right all went right at
   * a rate proportional to how far out they were - which is not diffusion, it is
   * a linear shear, and over thirteen seconds it pulled the body into a bow tie.
   * Where a mote is and where it is wandering are two independent facts about it.
   */
  private drawSwarm(v: FilmView): void {
    const ctx = v.ctx;
    // The gold breathes and nothing else in the frame does. By the held frame the
    // air has gone and the arc has gone, the ice is dead by construction, and two
    // per cent on a two-pixel dot is the only thing left in the picture that
    // changes - which is exactly the reading: what is alive is what is carried.
    const swell = 1 + (v.breath - 0.5) * 0.04;
    ctx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < MOTES; i++) {
      const seed = filmHash(i * 23);
      const side = filmHash(i * 37 + 5);
      const along = filmHash(i * 53 + 11);
      // Each mote keeps its own small sideways velocity, unrelated to where in the
      // body it happens to be. Nothing converges, because nothing is pulling them
      // together any more.
      const drift = (filmHash(i * 41 + 19) - 0.5) * 9;
      const x = v.x + (side - 0.5) * v.w * 0.34 + drift * this.t;
      // A body, and behind it a tail: `along` is cubed so most of the swarm sits
      // near the anchor and a few are strung out behind, which is what a swarm
      // that has been carried for an act actually looks like.
      const tail = along * along * along;
      const y = v.y - v.h * 0.11 + tail * v.h * 0.46 - KARMAN_COAST_SPEED * this.t;
      if (y < -40 || y > v.h + 40) continue;
      const a = 0.55 + seed * 0.45;
      // The third term of the argument: they do not bend. In high contrast the body
      // goes opaque and the streak gains most of its weight, because a streak that
      // never changes length is the only evidence in the frame that nothing is
      // pushing - and it is drawn at a third of an alpha it can afford to lose.
      const r = (1.1 + seed * 1.3) * swell;
      ctx.fillStyle = rgba(MOTE, 0.86 * a);
      ctx.beginPath();
      ctx.arc(x, y, r, 0, TAU);
      ctx.fill();
      // Constant. The one line in the file that would have to change if anything
      // up here were pushing them.
      ctx.strokeStyle = rgba(MOTE, 0.3 * a);
      ctx.lineWidth = Math.max(0.8, r * 0.6);
      ctx.beginPath();
      ctx.moveTo(x - drift * 0.1, y + KARMAN_COAST_SPEED * 0.1);
      ctx.lineTo(x, y);
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }
}
