import { TAU, clamp } from '../core/math';
import { filmHash, filmRamp, type Film, type FilmView } from './Films';
import { mix, rgba, type Rgb } from './Paint';

/**
 * Slowblue: where the water stops being carried and starts swimming.
 *
 * §10's last line is the handover: *the river reaches the estuary; where fresh
 * water meets salt, the gold reappears as small living forms - plankton and
 * larvae.* It is the campaign's second transformation of the same substance and
 * the exact mirror of the first: act I ended with life being let go of, and this
 * is life being taken up again, in the one place on Earth where fresh water and
 * sea water are the same body of water.
 *
 * The fact the film is built to deliver is **motion the player did not cause**.
 * For six acts every metre anything moved was the medium moving it - that is the
 * game's one sentence - and `Karman` is the film that says so hardest, drawing a
 * swarm that keeps its speed because nothing is acting on it. Here, for the first
 * time since the trench floor, something in the frame moves *itself*.
 *
 * Which means the swim has to be a **velocity**, not a wobble. Every body holds a
 * heading, swims along it at its own speed, and is drawn pointing where it is
 * going; the water is still pouring downstream underneath all of them and they
 * are visibly losing less ground to it every second. A field of dots vibrating in
 * place is not that claim - it is jitter, and jitter is what being carried looks
 * like. Nothing says any of this. The player watches the population stop sinking,
 * and act VII opens.
 *
 * Four movements, on the film's own clock, deterministic, no random calls:
 *
 *   1. `widen`   - the banks go, and the current goes with them. The two dark
 *                  edges act VI's brook has been confined by slide off the sides
 *                  of the frame, and the streamlines that ran between them - tight,
 *                  parallel, ripping - fan out, slacken and lose the direction they
 *                  had nothing left to take it from. A channel becomes a plane.
 *   2. `salt`    - the halocline. Fresh water is lighter than salt and rides over
 *                  it, so the sea arrives as a *wedge from underneath* rather than
 *                  as a colour change: the bottom of the frame goes blue and dark
 *                  while the top stays green, and the boundary between them is a
 *                  real, visible, shimmering surface that rises. The river's load
 *                  of silt drops out of the slack water and hangs there.
 *   3. `quicken` - the gold takes a heading. Each droplet's core leaves its shell,
 *                  grows the anatomy that moves it, and sets off *upward* - toward
 *                  the light, across the drift - which is what plankton in an
 *                  estuary spend their lives doing and is the oldest journey there
 *                  is.
 *   4. `open`    - the sea. The surface recedes upward into a bright ceiling and
 *                  shafts come down through it, the silt in them turns them into
 *                  something you can see, the interface catches specular where they
 *                  land on it, and the current lets go. Act VII's first station is
 *                  a sunlit shallow, and this is it - the fullest frame in the
 *                  film, because it is the one the next act opens into.
 *
 * ## Two clocks
 *
 * The film runs on two, and the difference between them is the whole reason the
 * held frame works. `t` is the choreography: it clamps at `ESTUARY_TOTAL`, so the
 * movements arrive once and then stop arriving, and every ramp, envelope and fade
 * in the file reads it. `beating` never clamps, and the animals are on it - the
 * cilia, the tails, the surge of each stroke and the ground each stroke covers.
 *
 * A single clamped clock is what the first cut had, and on the last frame it
 * stopped every animal in the water dead, mid-stroke, under a title. That is not a
 * held picture; it is a photograph of a picture, and it un-says the only thing the
 * film has to say. Under a single `update(t)` the two clocks are identical, which
 * is why the position pin in `tests/films.test.ts` can still compare a frame
 * against itself.
 *
 * ## Reduced motion
 *
 * The swim is kept and is never damped: it is the film's entire argument, and a
 * reduced-motion player who is shown a field of stationary dots has been shown a
 * different ending. So every body's position is a function of the film's own two
 * clocks and of nothing else - no `v.time` anywhere near it - and the frame is
 * identical either way, which is exactly what that test asserts.
 *
 * What `still` takes is the vestibular texture that rides the renderer's clock:
 * the shimmer travelling along the halocline, the specular sliding along it with
 * the crests, and the shafts' sway. Those hold their positions rather than being
 * removed. Nothing that arrives stops arriving.
 *
 * ## High contrast
 *
 * The second of the two films with a lit background, and it has the same rule as
 * `Nucleus`: the gold is outlined, never recoloured. What is different is where the
 * contrast is actually short. The bodies sit low in a frame whose bottom is deep
 * blue, so they are not badly off; the two things that are, are the **halocline**
 * and the last movement's light. The halocline is the film's one piece of physics
 * and it is drawn as three traces at a sixth of an alpha over water almost its own
 * colour - so those roughly double, and so does the specular that runs along them.
 * The ceiling wash and the shafts are the frame's softeners, and they come down,
 * exactly as the sun's bloom does in the two films above the atmosphere. The sea
 * below the line deepens with them, which is free separation for every body in
 * front of it.
 *
 * The silt is the one element the setting pulls in both directions at once, and it
 * is worth saying why: a grain of silt is an object with an edge and the light on
 * it is a wash, so the grains go up and their glare comes down. What is left is
 * more silt and less haze, which is the setting's whole sentence in one system.
 */

/** Movement lengths, in seconds. */
export const ESTUARY_WIDEN = 2.6;
export const ESTUARY_SALT = 3.4;
export const ESTUARY_QUICKEN = 3.8;
/**
 * The longest movement, and the one with the most in it.
 *
 * A last movement made of two washes and a recolour is a film that has finished
 * arguing and is waiting to end, and length only makes that worse. This is the
 * frame act VII opens into, so it is the one that has to be full - light, what the
 * light lands on, and a population that has stopped being carried - and it is long
 * because there is that much to arrive, not because there is that much to wait
 * through.
 */
export const ESTUARY_OPEN = 5;

export const ESTUARY_SALT_AT = ESTUARY_WIDEN;
/** The frame the gold starts moving by itself. The audio's turn belongs here. */
export const ESTUARY_QUICKEN_AT = ESTUARY_SALT_AT + ESTUARY_SALT;
export const ESTUARY_OPEN_AT = ESTUARY_QUICKEN_AT + ESTUARY_QUICKEN;
export const ESTUARY_TOTAL = ESTUARY_OPEN_AT + ESTUARY_OPEN;
/**
 * Film seconds the open sea is held before act VII opens into it.
 *
 * It is also, exactly, how long the water takes to let go: the drift decays over
 * this same beat, so the frame the next act is allowed to open on is the first
 * frame in six acts where nothing is being carried at all.
 */
export const ESTUARY_TAIL = 2.8;

export type EstuaryPhase = 'idle' | 'widen' | 'salt' | 'quicken' | 'open';

/** The river, as act VI's last band draws it. The green going out of it. */
const RIVER_HIGH: Rgb = [32, 70, 79];
const RIVER_LOW: Rgb = [63, 147, 160];
/** Fresh water's own tint, from above: green, and a little brown with the land in it. */
const FRESH: Rgb = [86, 122, 96];
/** The sea, as act VII's first band draws it. */
const SALT_HIGH: Rgb = [44, 125, 142];
const SALT_LOW: Rgb = [13, 60, 80];
/** The bank: the last land in the campaign, and it is a silhouette. */
const BANK: Rgb = [18, 34, 28];
/** Light on the interface, and later on the surface overhead. */
const GLINT: Rgb = [214, 244, 248];
/** Pod-gold, which is about to become an animal again. */
const LIFE: Rgb = [255, 233, 178];
/** The droplet shells the gold is leaving. */
const DROP: Rgb = [206, 232, 240];
/** Suspended sediment: the land, still in the water, on its way out of the story. */
const SILT: Rgb = [196, 214, 200];

/**
 * What the water is doing, in px/s: downstream, and a little across the frame.
 *
 * One pair of numbers rather than three copies of them, because it is one river.
 * Everything the water has hold of - the bodies, the silt, the one drawn close -
 * multiplies `carried` by these, so the day somebody changes what the current is
 * doing, nothing in the frame is left behind moving at the old speed.
 */
const DRIFT_DOWN = 26;
const DRIFT_ACROSS = 4;

/** Individuals in the water. Half plankton, half larvae. */
const LIVES = 34;
/** Grains of suspended sediment. Few, because each one is barely a pixel. */
const GRAINS = 30;
/** Shafts coming down through the water in the last movement. */
const SHAFTS = 4;
/** Specular highlights travelling along the interface under them. */
const SPECULARS = 5;
/** Cilia on a plankter in the field, and on the one drawn close. */
const CILIA = 7;
const NEAR_CILIA = 14;

export class Estuary implements Film {
  /** The choreography. Clamps, so a movement arrives once. */
  private t = -1;
  /**
   * The animals' own clock, which never clamps.
   *
   * Everything a living thing does with it keeps happening on the held frame:
   * strokes are taken, ground is covered, tails beat. See the file header.
   */
  private beating = -1;

  readonly anchor = [0.3, 0.6] as const;

  get active(): boolean {
    return this.t >= 0;
  }

  get phase(): EstuaryPhase {
    if (this.t < 0) return 'idle';
    if (this.t < ESTUARY_SALT_AT) return 'widen';
    if (this.t < ESTUARY_QUICKEN_AT) return 'salt';
    if (this.t < ESTUARY_OPEN_AT) return 'quicken';
    return 'open';
  }

  /**
   * 0..1 how far the frame has left act VI behind.
   *
   * The gentlest of the seven, and it has to be: the live world under this film
   * is running water and the film's first movement is *the same running water
   * with the banks taken off it*. There is no frame here that is a cut.
   */
  get veil(): number {
    if (this.t < 0) return 0;
    return clamp(filmRamp(this.t, 0, ESTUARY_WIDEN * 1.25) * 0.92, 0, 0.92);
  }

  /** True once the gold is swimming rather than being carried. */
  get alive(): boolean {
    return this.t >= ESTUARY_QUICKEN_AT;
  }

  get settled(): boolean {
    return this.t >= ESTUARY_QUICKEN_AT;
  }

  /**
   * False. The top of the frame here is fresh water going over to `SALT_HIGH`,
   * which is a mid-dark blue-green - the same value act VI's own stations print
   * their titles over - and the surface glow the last movement adds is a long way
   * short of daylight.
   */
  readonly daylight = false;

  /** True once the sea has been held long enough for act VII to open into it. */
  get handedOver(): boolean {
    return this.t >= ESTUARY_OPEN_AT + ESTUARY_TAIL;
  }

  begin(): void {
    if (this.t >= 0) return;
    this.t = 0;
    this.beating = 0;
  }

  reset(): void {
    this.t = -1;
    this.beating = -1;
  }

  /**
   * Holds on the last frame rather than ending - but only the choreography holds.
   *
   * The second clock runs on past the end of the film for as long as the picture
   * is on screen, because the subject of the picture is that these things move
   * themselves and a still one has stopped being the subject.
   */
  update(dt: number): void {
    if (this.t < 0) return;
    this.t = Math.min(ESTUARY_TOTAL, this.t + dt);
    this.beating += dt;
  }

  /** Where the halocline sits, in px down the frame. Rises as the salt arrives. */
  private interface(v: FilmView): number {
    const wedge = filmRamp(this.t, ESTUARY_SALT_AT, ESTUARY_SALT * 0.95);
    const sink = filmRamp(this.t, ESTUARY_OPEN_AT, ESTUARY_OPEN);
    // Off the bottom edge, up to a little above the middle, and then away again
    // as the frame becomes all sea and there is no longer a boundary to draw.
    return v.h * (1.08 - wedge * 0.62 - sink * 0.5);
  }

  /**
   * How present the interface is, 0..1.
   *
   * One number, read by the traces that draw the surface and by the specular that
   * lands on it, so that the light on a thing can never outlive the thing.
   */
  private brine(): number {
    const p = filmRamp(this.t, ESTUARY_SALT_AT * 0.7, ESTUARY_SALT * 0.5);
    const gone = filmRamp(this.t, ESTUARY_OPEN_AT, ESTUARY_OPEN * 0.6);
    return p * (1 - gone);
  }

  /**
   * How much light is coming down through the water, 0..1.
   *
   * Also one number and four readers: the ceiling and the shafts that are the
   * light, the specular where a shaft meets the interface, the silt that is the
   * only reason a shaft is visible at all, and every body that swims through one.
   * The last movement is a single event, so it is a single ramp.
   */
  private light(): number {
    return filmRamp(this.t, ESTUARY_QUICKEN_AT + ESTUARY_QUICKEN * 0.5, ESTUARY_OPEN * 0.9);
  }

  draw(v: FilmView): void {
    if (this.t < 0) return;
    const ctx = v.ctx;
    ctx.save();
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const line = this.interface(v);
    const light = this.light();
    this.drawWater(v, line);
    this.drawCurrents(v);
    this.drawBanks(v);
    this.drawHalocline(v, line);
    this.drawSpecular(v, line, light);
    this.drawOpen(v, light);
    this.drawSilt(v, light);
    this.drawLives(v, light);
    this.drawNear(v, light);
    ctx.restore();
  }

  /**
   * The ground of the film: green over blue, with the boundary between them where
   * the halocline actually is.
   *
   * Two gradients rather than one, meeting on a moving line, because a single
   * gradient cannot have an *edge* in it - and the edge is the subject. Above the
   * line the water keeps the river's colour to the last frame it has any; below
   * it, the sea.
   */
  private drawWater(v: FilmView, line: number): void {
    const ctx = v.ctx;
    const a = filmRamp(this.t, 0, ESTUARY_WIDEN * 1.2);
    if (a <= 0.01) return;
    const open = filmRamp(this.t, ESTUARY_OPEN_AT, ESTUARY_OPEN * 0.8);

    // Fresh, above. It loses its green as the last of the river is left behind.
    if (line > 0) {
      const fresh = ctx.createLinearGradient(0, 0, 0, Math.max(1, line));
      fresh.addColorStop(0, rgba(mix(mix(RIVER_HIGH, FRESH, 0.35), SALT_HIGH, open), 0.96 * a));
      fresh.addColorStop(1, rgba(mix(RIVER_LOW, SALT_HIGH, open * 0.7), 0.94 * a));
      ctx.fillStyle = fresh;
      ctx.fillRect(0, 0, v.w, line + 1);
    }
    // Salt, below, and it is the direction of travel: darker and bluer the further
    // down the frame it goes, because that is where act VII is. High contrast
    // deepens it, which costs the picture nothing - the sea really does go dark
    // downward - and buys separation for every body drawn in front of it.
    if (line < v.h) {
      const deep = 0.55;
      const salt = ctx.createLinearGradient(0, line, 0, v.h);
      salt.addColorStop(0, rgba(SALT_HIGH, 0.96 * a));
      salt.addColorStop(0.45, rgba(mix(SALT_HIGH, SALT_LOW, deep), 0.96 * a));
      salt.addColorStop(1, rgba(SALT_LOW, 0.97 * a));
      ctx.fillStyle = salt;
      ctx.fillRect(0, line, v.w, v.h - line + 1);
    }
  }

  /**
   * The current, losing its channel.
   *
   * The first movement used to be carried entirely by the banks' absence, which
   * meant the water itself - two thirds of the frame - did not change at all while
   * the thing the movement is about happened to it. But a channel is not its
   * sides; a channel is what the sides *do to the flow*, and that is visible.
   *
   * So: streamlines. In the brook they are bunched into the middle of the frame,
   * near vertical, and rippling at a high frequency, because fast water in a
   * narrow section is. As the section opens they fan apart, tilt away from each
   * other, and their ripple grows long and slack - the same volume of water across
   * ten times the width has to slow down, and slow water has long waves in it.
   * Then they fade, because on a plane there is nothing left for a streamline to
   * be parallel to. The last of the river is the last of its texture.
   */
  private drawCurrents(v: FilmView): void {
    const ctx = v.ctx;
    const spread = filmRamp(this.t, 0, ESTUARY_WIDEN * 1.35);
    const left = 1 - filmRamp(this.t, ESTUARY_WIDEN * 0.8, ESTUARY_SALT * 0.6);
    const a = (0.5 + spread * 0.5) * left;
    if (a <= 0.02) return;
    const lines = v.quality > 0.5 ? 7 : 4;

    ctx.globalCompositeOperation = 'lighter';
    // Not a softener: a hairline is an edge, and this setting pays for edges. Up,
    // and thinner in proportion, so more of the frame's contrast lands on fewer
    // pixels rather than on a wider smear of the same total light.
    ctx.strokeStyle = rgba(GLINT, 0.075 * a);
    ctx.lineWidth = 1.1;
    for (let i = 0; i < lines; i++) {
      const seed = filmHash(i * 43 + 7);
      const lane = (i + 0.5) / lines - 0.5;
      const from = v.x + lane * v.w * (0.5 + spread * 1.1);
      // Each lane leans further out the wider the water gets, so the set opens
      // like a fan rather than sliding sideways as a block.
      const splay = lane * spread * v.w * 0.55;
      const amp = (2 + seed * 3) * (1 + spread * 3.2);
      const wave = 0.03 - spread * 0.021;
      ctx.beginPath();
      for (let y = -20; y <= v.h + 20; y += 22) {
        const k = (y + 20) / (v.h + 40);
        const x = from + splay * k + Math.sin(y * wave + seed * 6.2 + i) * amp;
        if (y === -20) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * The banks, leaving.
   *
   * The last land the campaign has, and it gets two and a half seconds and no
   * detail at all. Each side is one filled irregular edge that slides outward and
   * fades - a river mouth opening, seen from inside the water. What is left when
   * they are gone is a plane with no sides, which is the first thing a sea is.
   */
  private drawBanks(v: FilmView): void {
    const ctx = v.ctx;
    const gone = filmRamp(this.t, 0, ESTUARY_WIDEN);
    const a = 1 - gone;
    if (a <= 0.02) return;
    // A third of the frame each side at the first frame, off the edge by the last.
    const reach = v.w * 0.3 * (1 - gone) - gone * v.w * 0.14;
    ctx.fillStyle = rgba(BANK, 0.9 * a);
    for (const side of [-1, 1]) {
      const edge = side < 0 ? 0 : v.w;
      ctx.beginPath();
      ctx.moveTo(edge, -20);
      for (let i = 0; i <= 10; i++) {
        const p = i / 10;
        // Deterministic ragged edge: a bank is not a straight line, and two
        // harmonics are enough for the eye to accept it as one that was eroded.
        const jag = 0.62 + 0.38 * Math.sin(p * 7.3 + (side < 0 ? 0 : 2.1)) * 0.5
          + 0.18 * Math.sin(p * 17 + 1.4);
        ctx.lineTo(edge + side * reach * jag, -20 + p * (v.h + 40));
      }
      ctx.lineTo(edge, v.h + 20);
      ctx.closePath();
      ctx.fill();
    }
  }

  /**
   * The interface's own surface, at `x`, for trace `n`.
   *
   * Split out because two things stand on this line - the traces that draw the
   * surface and the specular that slides along it - and neither may invent its own
   * version of it. A highlight sitting a few pixels off the surface it is supposed
   * to be lying on is the single most legible way to make a real boundary look
   * painted on the glass.
   */
  private crest(x: number, line: number, t: number, n: number): number {
    return (
      line +
      n * 3 +
      Math.sin(x * 0.017 + t * 0.5 + n * 1.5) * (3 + n * 1.5) +
      Math.sin(x * 0.006 - t * 0.29) * 5
    );
  }

  /**
   * The halocline: the surface inside the water.
   *
   * This is the film's one piece of physics and it is drawn as physics. Fresh
   * water is about two and a half per cent lighter than sea water, so it does not
   * mix into it - it *floats on* it, and the boundary is sharp enough to see, to
   * swim through, and to catch light on. Three traces a few pixels apart, never
   * one, for the same reason `Surfacing`'s waterline is three: a single stroke
   * across the screen is a UI divider, and this is a surface.
   */
  private drawHalocline(v: FilmView, line: number): void {
    const ctx = v.ctx;
    const a = this.brine();
    if (a <= 0.02 || line > v.h + 20 || line < -20) return;
    const t = v.time;

    ctx.globalCompositeOperation = 'lighter';
    // The mixing layer: a soft band, because the boundary is sharp and not
    // infinitely sharp, and the light that gets caught on it lives in here. It is
    // also a softener sitting exactly where the frame's one hard edge is, so high
    // contrast takes most of it and gives it back to the traces.
    const band = ctx.createLinearGradient(0, line - v.h * 0.05, 0, line + v.h * 0.04);
    band.addColorStop(0, rgba(GLINT, 0));
    band.addColorStop(0.5, rgba(GLINT, 0.1 * a));
    band.addColorStop(1, rgba(GLINT, 0));
    ctx.fillStyle = band;
    ctx.fillRect(0, line - v.h * 0.05, v.w, v.h * 0.09);

    // The surface itself. Three traces, and this is the film's one piece of
    // physics: fresh water floating on salt, sharp enough to see and to swim
    // through. In high contrast it is the first thing paid for.
    for (let trace = 0; trace < 3; trace++) {
      ctx.strokeStyle = rgba(GLINT, (0.16 - trace * 0.04) * a);
      ctx.lineWidth = 1 + trace * 0.9;
      ctx.beginPath();
      for (let x = -12; x <= v.w + 12; x += 10) {
        const y = this.crest(x, line, t, trace);
        if (x === -12) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Specular, travelling along the interface.
   *
   * The file has been calling the halocline "the film's one piece of physics" for
   * two acts and then not drawing the one consequence of it anybody has ever
   * actually seen: a moving boundary between two densities, with light above it,
   * *glitters*. Not everywhere - only where a wave crest happens to be turned
   * toward the light, which is a narrow band that slides along the surface as the
   * wave train passes under it.
   *
   * So each highlight is a short dash lying **on** `crest` rather than near it, it
   * brightens on the crests and goes out in the troughs, and it brightens again
   * where it passes under a shaft, because a highlight is the light source seen in
   * a mirror and off the shafts there is no source to see. It exists only while
   * both the interface and the light do: it is the product of the two, and it
   * cannot outlive either.
   */
  private drawSpecular(v: FilmView, line: number, light: number): void {
    const ctx = v.ctx;
    const a = this.brine() * light;
    if (a <= 0.01 || line > v.h + 20 || line < -20) return;
    const t = v.time;
    const span = v.w + 60;

    ctx.globalCompositeOperation = 'lighter';
    ctx.lineWidth = 1.4;
    for (let i = 0; i < SPECULARS; i++) {
      const seed = filmHash(i * 97 + 13);
      // Travelling: the highlight is not a thing on the water, it is a place the
      // water is briefly the right shape, and that place moves with the waves.
      const x = ((((seed * span + t * 26) % span) + span) % span) - 30;
      // How high the surface is under it, off the same function that draws the
      // surface: a crest is turned toward the light and a trough is not, so the
      // highlight is on when the wave is up and off when it is not. Reading the
      // height rather than re-deriving the phase is why `crest` exists.
      const face = clamp((line - this.crest(x, line, t, 0)) / 8, 0, 1);
      const len = 5 + seed * 9;
      // The same physics as the halocline's own traces: an edge, so it goes up.
      ctx.strokeStyle = rgba(
        GLINT,
        a * face * (0.18 + this.shaftLight(v, x, t) * 0.55),
      );
      ctx.beginPath();
      ctx.moveTo(x - len, this.crest(x - len, line, t, 0));
      ctx.lineTo(x + len, this.crest(x + len, line, t, 0));
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /** How many shafts there are. Degraded rather than dropped: see `drawOpen`. */
  private shaftCount(v: FilmView): number {
    return v.quality > 0.55 ? SHAFTS : 2;
  }

  /**
   * Which of the four shafts the `k`th drawn one is.
   *
   * The cheap tier takes every other one rather than the first two, so a low
   * quality frame is lit across its whole width instead of down its left-hand
   * third - and it takes them by the *same* index, so a shaft does not move across
   * the frame when the tier changes under it.
   */
  private shaftIndex(v: FilmView, k: number): number {
    return v.quality > 0.55 ? k : k * 2;
  }

  /** Where shaft `k` comes down, in px across the frame. */
  private shaftAt(v: FilmView, k: number, t: number): number {
    const i = this.shaftIndex(v, k);
    const seed = filmHash(i * 71 + 3);
    return v.w * (0.14 + i * 0.24 + seed * 0.08) + Math.sin(t * 0.16 + i) * 9;
  }

  /**
   * 0..1 how much shaft light lands at `x`. Zero between the shafts.
   *
   * Quadratic falloff off the axis of the nearest one, which is close enough to a
   * cross-section of the radial gradient the shaft is actually drawn with, and it
   * is the reason the silt, the specular and the bodies all agree about where the
   * light is instead of each having an opinion.
   */
  private shaftLight(v: FilmView, x: number, t: number): number {
    let most = 0;
    const n = this.shaftCount(v);
    for (let k = 0; k < n; k++) {
      const d = (x - this.shaftAt(v, k, t)) / (v.w * 0.17);
      const f = 1 - d * d;
      if (f > most) most = f;
    }
    return most > 0 ? most : 0;
  }

  /**
   * The last movement: the sea opens.
   *
   * A bright ceiling receding upward off the top of the frame, and shafts coming
   * down through it. This is the picture act VII's first station is played in, and
   * it is the last daylight in the campaign - everything after it goes down.
   *
   * Both elements are the one thing in the film that breathes on the held frame.
   * A sunlit shallow is lit through a surface that is still moving even when
   * nothing else is, so the ceiling and the shafts reach a little further on the
   * swell and a little less off it - two and a half per cent, which is felt rather
   * than seen and is exactly zero at `breath = 0.5`.
   */
  private drawOpen(v: FilmView, p: number): void {
    const ctx = v.ctx;
    if (p <= 0.01) return;
    const t = v.time;
    // Both elements below are wide additive washes over a lit background, which is
    // the shape of thing high contrast removes everywhere in the campaign. Cut to a
    // third rather than dropped: without any of it the sea has no ceiling and the
    // last movement stops being "the surface receding" at all.
    const soft = 1;
    const swell = 1 + (v.breath - 0.5) * 0.05;
    ctx.globalCompositeOperation = 'lighter';

    // The surface, going away above. It never becomes a line - it becomes a glow
    // that is further off every frame, which is what leaving one looks like.
    const ceil = ctx.createLinearGradient(0, -v.h * 0.1, 0, v.h * (0.34 + p * 0.1) * swell);
    ceil.addColorStop(0, rgba(GLINT, 0.24 * p * soft));
    ceil.addColorStop(0.45, rgba(GLINT, 0.07 * p * soft));
    ceil.addColorStop(1, rgba(GLINT, 0));
    ctx.fillStyle = ceil;
    ctx.fillRect(0, 0, v.w, v.h * 0.46);

    /*
     * Shafts, as stretched pools of light rather than as shapes.
     *
     * Two goes at this were wrong in the same way and it is worth writing down,
     * because it is a Canvas2D trap rather than a taste question. A `fillRect`
     * down to 0.8 of the height put a hard horizontal edge across the whole
     * frame where four columns stopped at once. Tapering the same fill into a
     * triangle fixed that and produced something worse: a linear gradient is
     * anchored in *space*, not to the path it fills, so as the triangle
     * narrowed it sampled only the gradient's bright middle - and four shafts
     * turned into four hard-edged bright threads pointing at the sea floor.
     *
     * A radial gradient has no edges in any direction and needs no path at all.
     * Squashed along x and stretched along y it is a shaft; centred just above
     * the surface it is a shaft *from* the surface, which is what these are.
     *
     * The low quality tier halves the count rather than skipping the pass, which
     * it used to do. Three other systems read where these are - the silt in them,
     * the specular under them, the bodies crossing them - so switching the whole
     * geometry off took the light out of half the movement to save four fills.
     */
    const n = this.shaftCount(v);
    for (let k = 0; k < n; k++) {
      const seed = filmHash(this.shaftIndex(v, k) * 71 + 3);
      const x = this.shaftAt(v, k, t);
      const reach = v.w * (0.13 + seed * 0.07) * swell;
      const tall = 2.4 + seed * 1.6;
      ctx.save();
      ctx.translate(x, -v.h * 0.04);
      ctx.scale(1, tall);
      const g = ctx.createRadialGradient(0, 0, 0, 0, 0, reach);
      g.addColorStop(0, rgba(GLINT, 0.075 * p * soft));
      g.addColorStop(0.45, rgba(GLINT, 0.03 * p * soft));
      g.addColorStop(1, rgba(GLINT, 0));
      ctx.fillStyle = g;
      ctx.fillRect(-reach, -reach, reach * 2, reach * 2);
      ctx.restore();
    }
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Where grain `i` of suspended sediment is.
   *
   * An estuary is where a river's load stops being carried - the water slows, the
   * salt makes the fine particles clump, and the land the river has been taking
   * apart for six hundred kilometres hangs in the slack and settles out. It is the
   * defining fact about the place and the film did not have it.
   *
   * It earns its keep twice over. It is texture in the water for the three
   * movements that had none, and it is the reason the shafts are visible at all:
   * a beam of light in clear water is invisible, and every shaft anyone has ever
   * photographed underwater is a photograph of what was floating in it.
   *
   * Wrapped in both axes rather than culled, because a field that thins is a field
   * that was a one-off, and the river upstream keeps supplying this one. The wrap
   * span is wider than the frame at both ends, so a grain always crosses the seam
   * off-screen.
   */
  private grain(v: FilmView, i: number, carried: number): { x: number; y: number; r: number } {
    const spanX = v.w + 40;
    const spanY = v.h * 1.16;
    const size = filmHash(i * 31 + 3);
    return {
      x:
        ((((filmHash(i * 59 + 7) * spanX + carried * DRIFT_ACROSS) % spanX) + spanX) % spanX) - 20,
      y: ((((filmHash(i * 17 + 9) * spanY + carried * DRIFT_DOWN) % spanY) + spanY) % spanY)
        - v.h * 0.08,
      r: 0.45 + size * 1.15,
    };
  }

  /**
   * The silt, in two passes.
   *
   * The first is the material: pale grains, drawn over the water rather than added
   * to it, because sediment is opaque and the whole point of it is that it makes
   * water less clear. The second is what the light does to the same grains inside
   * a shaft, and only inside one - additive, and only the grains the shafts
   * actually reach.
   *
   * High contrast pulls the two apart, which is the neatest statement of the
   * setting anywhere in this file: the grains go **up**, because a grain is an
   * object with an edge, and the glare on them comes **down**, because a wash of
   * pale light over pale water is exactly what this setting exists to remove. The
   * frame ends up with more silt in it and less haze.
   */
  private drawSilt(v: FilmView, light: number): void {
    const ctx = v.ctx;
    const a = filmRamp(this.t, ESTUARY_SALT_AT * 0.5, ESTUARY_SALT);
    if (a <= 0.02) return;
    const n = v.quality > 0.6 ? GRAINS : Math.round(GRAINS * 0.45);
    const carried = this.carried(this.t);

    ctx.fillStyle = rgba(SILT, 0.13 * a);
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const g = this.grain(v, i, carried);
      if (g.y < -4 || g.y > v.h + 4) continue;
      ctx.moveTo(g.x + g.r, g.y);
      ctx.arc(g.x, g.y, g.r, 0, TAU);
    }
    ctx.fill();

    if (light <= 0.01) return;
    const t = v.time;
    ctx.globalCompositeOperation = 'lighter';
    ctx.fillStyle = rgba(GLINT, 0.3 * light * a);
    ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const g = this.grain(v, i, carried);
      if (g.y < -4 || g.y > v.h + 4) continue;
      if (this.shaftLight(v, g.x, t) < 0.3) continue;
      ctx.moveTo(g.x + g.r, g.y);
      ctx.arc(g.x, g.y, g.r, 0, TAU);
    }
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
  }

  /**
   * Seconds of carrying the water has done by `tt`, on the choreography clock.
   *
   * The drift used to be `26 * t` flat, all film long, which had two costs. It
   * culled half the population off the bottom of the frame by the end - thinning
   * the one movement that wants to be full - and, worse, it made the film's last
   * word "the water is still winning". The sea opening is the water letting go, so
   * the current decays to a dead stop across the same beat act VII waits out: the
   * frame the next act is allowed to open on is the first frame in six acts with
   * nothing being carried in it.
   *
   * Returned as a *time* rather than a distance so that everything the water moves
   * - the bodies, the silt, the one drawn close - takes it in its own px/s and
   * they cannot drift apart. It is the exact integral of a velocity that holds and
   * then falls linearly to zero, so it never steps and never reverses.
   */
  private carried(tt: number): number {
    const slack = ESTUARY_TAIL;
    const past = clamp(tt - ESTUARY_OPEN_AT, 0, slack);
    return Math.min(tt, ESTUARY_OPEN_AT) + past - (past * past) / (2 * slack);
  }

  /**
   * Seconds of swimming an animal has done by `ta`, on the animals' clock.
   *
   * The integral of the same smoothstep `filmRamp` builds, so a body accelerates
   * out of its shell rather than starting at speed, and then holds what it has.
   * Multiplied by a body's own px/s this is the distance it has actually covered
   * under its own power - the number the whole film is about - and because it is
   * on the unclamped clock, that distance keeps growing after the choreography has
   * finished. The animals do not know the film ended.
   */
  private stroked(ta: number): number {
    const over = ESTUARY_QUICKEN * 0.65;
    const u = clamp((ta - ESTUARY_QUICKEN_AT) / over, 0, 1);
    return over * (u * u * u - u * u * u * u * 0.5) + Math.max(0, ta - ESTUARY_QUICKEN_AT - over);
  }

  /**
   * Where body `i` is, and what phase of its stroke it is on.
   *
   * Three things are happening to one pair of coordinates and keeping them as
   * three terms is what makes the change legible:
   *
   *   * **The water.** `carried` px/s, down and a little sideways, the same for
   *     every body because it is the same water. It never stops until the sea
   *     opens, and the player never caused any of it.
   *   * **The swim.** A heading the animal holds and a speed it holds along it -
   *     a real velocity, with a real net displacement, aimed *up*, across the
   *     drift. The heading turns slowly on its own curvature, so the path is an
   *     arc rather than a ruled line and no two are the same arc.
   *   * **The stroke.** A surge along the heading and a scull across it, both on
   *     the same phase as the animal's own anatomy, so that the tail beat and the
   *     ground covered are one wave and not two. This is the difference between a
   *     tail that beats and a tail that *does* something: the body is quickest at
   *     the middle of each kick and coasts between them, and its head swings the
   *     other way as it goes, which is what a thing that swims by bending looks
   *     like from the side.
   *
   * The swim is handed back separately as `sx`/`sy`, because those two are the
   * body and the other two are the body plus the river, and only one of them is
   * the direction it is pointing. See `drawLives`.
   *
   * The heading is up because plankton are heavier than the water they live in.
   * Left alone, every one of them sinks out of the light and dies; staying in the
   * top few metres is a thing each of them does, all its life, with its own body,
   * against a medium that is always taking it somewhere else. That is not a
   * flourish chosen for this film - it is the oldest working example of the
   * sentence the film exists to end on, and it is why the population climbs while
   * the current pours down through it.
   *
   * The lean folded into the heading aims each body slightly back toward the middle
   * of the frame, where the shafts come down. That is phototaxis, it is the same
   * instinct as the climb, and it is also what keeps the population inside the
   * picture instead of walking out of the sides of it - a composition rule and a
   * fact about the animal that happen to be the same rule.
   *
   * The arc is closed-form rather than integrated: a body turning at a constant
   * rate travels a circular arc, and the chord of one is its arc length times
   * `sinc` of half the angle swept, laid along the mean heading. `sinc` is written
   * out with its own guard because the limit at zero curvature is 1 and the
   * quotient there is not - and half the population turns barely at all.
   */
  private place(
    v: FilmView,
    i: number,
    tt: number,
    ta: number,
  ): { x: number; y: number; sx: number; sy: number; beat: number } {
    const seed = filmHash(i * 23);
    const side = filmHash(i * 37 + 5);
    const lead = filmHash(i * 53 + 11);
    const aim = filmHash(i * 67 + 19);
    const curl = filmHash(i * 89 + 29);

    const x0 = v.x + (side - 0.5) * v.w * 0.76;
    const y0 = v.y - v.h * 0.24 + lead * v.h * 0.44;

    const effort = filmRamp(tt, ESTUARY_QUICKEN_AT, ESTUARY_QUICKEN * 0.65);
    const water = this.carried(tt);
    const swum = this.stroked(ta);
    const speed = 18 + seed * 22;
    const lean = (0.5 - x0 / Math.max(1, v.w)) * 1.1;
    const heading = -TAU / 4 + lean + (aim - 0.5) * 0.9;
    const half = (curl - 0.5) * 0.11 * swum;
    const chord = Math.abs(half) < 1e-4 ? 1 : Math.sin(half) / half;
    const along = heading + half;
    const gone = swum * speed * chord;

    // Stroke rate rises with size, and so does speed, which is what keeps the
    // surge under the swim: a body never sculls backwards between beats.
    const rate = 1.4 + seed * 1.6;
    const beat = ta * rate * (i % 2 === 0 ? 3.1 : 2.4) + i * 1.7;
    const surge = Math.sin(beat) * 1.8 * effort;
    const scull = Math.cos(beat * 0.5 + i) * 3 * effort;
    const sx = Math.cos(along) * (gone + surge) - Math.sin(along) * scull;
    const sy = Math.sin(along) * (gone + surge) + Math.cos(along) * scull;

    return { x: x0 + water * DRIFT_ACROSS + sx, y: y0 + water * DRIFT_DOWN + sy, sx, sy, beat };
  }

  /**
   * The gold, becoming animals.
   *
   * Two body plans, alternating. A plankter is radial - a body with cilia and no
   * front, but with a *direction*, which is not the same thing - and a larva has a
   * head and a beating tail. Both are drawn pointing along a finite difference of
   * `place`, exactly as `Circle.drawShoal` points act I's fish, and that one line
   * of arithmetic is the clearest signal in the frame that something is alive: a
   * body that faces where it is going was steered, and a body that does not was
   * dropped there. A tail beating while the head stares off in a fixed direction
   * is a wind sock with a motor in it.
   *
   * `shell` is the droplet the core came out of, and it fades as the swim comes
   * up. Nothing pops: for about a second there is a droplet with something moving
   * inside it, which is exactly what a larva in an egg is.
   *
   * They are drawn far larger than `Carriers.plankton` draws them in play, for the
   * same reason `Surfacing` draws its leapers at four times the shoal's size: this
   * is the one moment in the act where a single individual is big enough to be
   * recognised as one. See `drawNear` for the one that is bigger still.
   */
  private drawLives(v: FilmView, light: number): void {
    const ctx = v.ctx;
    const tt = this.t;
    const ta = this.beating;
    const swim = filmRamp(tt, ESTUARY_QUICKEN_AT, ESTUARY_QUICKEN * 0.65);
    const shell = 1 - filmRamp(tt, ESTUARY_QUICKEN_AT, ESTUARY_QUICKEN * 0.5);
    const lt = v.time;

    for (let i = 0; i < LIVES; i++) {
      const here = this.place(v, i, tt, ta);
      const x = here.x;
      const y = here.y;
      if (y < -30 || y > v.h + 30 || x < -30 || x > v.w + 30) continue;
      // Heading, from where it was a twentieth of a second ago. Both clocks step
      // back together, so on the held frame this is still the animal's own motion
      // and not a remembered one.
      //
      // Off `sx`/`sy` - the swim - and not off the frame position, which is the
      // swim plus the river. A fish holding station in a current faces upstream,
      // not at the bank it is losing ground to, and the difference is not cosmetic
      // here: the slowest bodies spend part of every stroke going backwards over
      // the ground, so a heading taken from the track flipped them end for end
      // twice a second. What a body points at is what it is doing.
      const was = this.place(v, i, tt - 0.05, ta - 0.05);
      const dx = here.sx - was.sx;
      const dy = here.sy - was.sy;
      const mag = Math.hypot(dx, dy);
      // Until it is swimming there is no swim to point along, and a carried thing
      // faces the way it is being taken, which is down.
      const hx = mag > 1e-3 ? dx / mag : 0;
      const hy = mag > 1e-3 ? dy / mag : 1;

      const seed = filmHash(i * 23);
      const size = 4.4 + seed * 3.6;
      // The shell it is leaving. Drawn first, so the body comes out of it.
      if (shell > 0.02) {
        const rr = size * 1.5;
        ctx.strokeStyle = rgba(DROP, 0.26 * shell);
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.arc(x, y, rr, 0, TAU);
        ctx.stroke();
        const body = ctx.createRadialGradient(x - rr * 0.3, y - rr * 0.3, 0, x, y, rr);
        body.addColorStop(0, rgba(DROP, 0.24 * shell));
        body.addColorStop(1, rgba(DROP, 0));
        ctx.fillStyle = body;
        ctx.beginPath();
        ctx.arc(x, y, rr, 0, TAU);
        ctx.fill();
      }

      /*
       * Drawn in the gold's own colour, not added to the water's.
       *
       * These were `lighter` once, which is what every other film in the
       * campaign does with the gold and is right in every one of them - because
       * every one of them is dark. This frame is not: an estuary in daylight is
       * the second brightest background in the game, and gold added to a lit
       * teal comes out white. A field of white dots is not the gold coming back
       * as something alive, it is the gold going missing in the act whose whole
       * job is to bring it back.
       *
       * A plankter is also simply not a light source. The halo goes on
       * separately and stays small; the body is an object, and objects occlude.
       *
       * What may brighten it is light landing on it. A body crossing a shaft
       * picks one up, and that is the only place in the film the gold changes
       * value - which is not the gold changing, and is the reason the shafts read
       * as being in front of and behind things rather than painted on the glass.
       */
      const lit = this.shaftLight(v, x, lt) * light;
      const glow = 0.5 + swim * 0.4;
      if (swim > 0.02) {
        ctx.globalCompositeOperation = 'lighter';
        const halo = ctx.createRadialGradient(x, y, 0, x, y, size * 2.4);
        const peak = 0.16 * swim * (1 + lit * 1.7);
        halo.addColorStop(0, rgba(LIFE, clamp(peak, 0, 1)));
        halo.addColorStop(1, rgba(LIFE, 0));
        ctx.fillStyle = halo;
        ctx.beginPath();
        ctx.arc(x, y, size * 2.4, 0, TAU);
        ctx.fill();
        ctx.globalCompositeOperation = 'source-over';
      }
      ctx.fillStyle = rgba(LIFE, clamp(glow * (0.94 + lit * 0.22), 0, 1));
      ctx.strokeStyle = rgba(LIFE, clamp(glow * (0.6 + lit * 0.3), 0, 1));
      ctx.lineWidth = 1.2;
      if (i % 2 === 0) this.tracePlankter(ctx, x, y, size, swim, here.beat, hx, hy);
      else this.traceLarva(ctx, x, y, size, swim, here.beat, hx, hy);
    }
  }

  /**
   * A plankter: a round body with cilia, and no front - but a direction.
   *
   * The cilia only appear with the swim, because before the third movement this is
   * a bead of gold in a droplet and has no anatomy. They do not beat together.
   * They beat in a *metachronal wave*, which is the thing a ciliate actually does
   * and the reason it goes anywhere: the stroke runs round the body from the end
   * that is leading to the end that is trailing, so the phase of a cilium is its
   * own angle measured against the direction of travel. A ring of hairs pulsing in
   * unison is a sea urchin having a fright; a wave running backward along a body
   * is propulsion, and it is legible at eight pixels.
   *
   * Each hair also sweeps as it extends rather than only lengthening, because the
   * power stroke of a cilium is a sweep and the recovery is a fold - and a segment
   * that only grows and shrinks reads as a spike, not as a limb.
   */
  private tracePlankter(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    size: number,
    swim: number,
    phase: number,
    hx: number,
    hy: number,
  ): void {
    ctx.beginPath();
    ctx.arc(x, y, size * (0.5 + swim * 0.16), 0, TAU);
    ctx.fill();
    if (swim <= 0.05) return;
    const heading = Math.atan2(hy, hx);
    ctx.beginPath();
    for (let i = 0; i < CILIA; i++) {
      const a = (i / CILIA) * TAU;
      const ph = phase - (a - heading) * 1.9;
      const reach = size * (0.95 + 0.35 * swim) * (1 + 0.32 * Math.sin(ph));
      const sweep = Math.sin(ph) * 0.26;
      const r0 = size * 0.55;
      ctx.moveTo(x + Math.cos(a) * r0, y + Math.sin(a) * r0);
      ctx.lineTo(x + Math.cos(a + sweep) * reach, y + Math.sin(a + sweep) * reach);
    }
    ctx.stroke();
  }

  /**
   * A larva: a head, and a tail that beats it forward.
   *
   * The tail is the whole reason this body plan is in the film. A ciliate's motion
   * is a shimmer and could be read as the water moving it; a beating tail cannot
   * be read as anything except an animal deciding to go somewhere, and that is the
   * sentence act VII opens on.
   *
   * Which only works if the head is pointed at where it is going and the tail is
   * behind it. Both are built off the heading here: the body ellipse is rotated
   * onto it, the three segments run *back* along it, and the travelling wave is
   * thrown across it. The lag between segments is what makes it a wave rather than
   * a hinge - the same idea as the fish's spine, at a twentieth of the size and a
   * tenth of the cost - and the phase is the same one the body surges on, so the
   * kick and the ground it covers are one motion.
   */
  private traceLarva(
    ctx: CanvasRenderingContext2D,
    x: number,
    y: number,
    size: number,
    swim: number,
    phase: number,
    hx: number,
    hy: number,
  ): void {
    ctx.beginPath();
    ctx.ellipse(x, y, size * 0.62, size * 0.44, Math.atan2(hy, hx), 0, TAU);
    ctx.fill();
    if (swim <= 0.05) return;
    ctx.beginPath();
    ctx.moveTo(x - hx * size * 0.5, y - hy * size * 0.5);
    for (let i = 1; i <= 3; i++) {
      const k = i / 3;
      const back = size * (0.5 + k * 1.5);
      const kick = Math.sin(phase - k * 1.6) * size * 0.5 * k * swim;
      ctx.lineTo(x - hx * back - hy * kick, y - hy * back + hx * kick);
    }
    ctx.stroke();
  }

  /** Where the one drawn close is. Same three terms as `place`, one body. */
  private placeNear(
    v: FilmView,
    tt: number,
    ta: number,
  ): { x: number; y: number; sx: number; sy: number; beat: number } {
    const effort = filmRamp(tt, ESTUARY_QUICKEN_AT, ESTUARY_QUICKEN * 0.7);
    const swum = this.stroked(ta);
    const half = 0.055 * swum * 0.5;
    const chord = Math.abs(half) < 1e-4 ? 1 : Math.sin(half) / half;
    const along = -TAU / 4 - 0.3 + half;
    const gone = swum * 19 * chord;
    const beat = ta * 2.9 + 0.7;
    const scull = Math.cos(beat * 0.5) * 6 * effort;
    const sx = Math.cos(along) * gone - Math.sin(along) * scull;
    const sy = Math.sin(along) * gone + Math.cos(along) * scull;
    return {
      x: v.w * 0.17 + this.carried(tt) * DRIFT_ACROSS + sx,
      y: v.h * 0.46 + this.carried(tt) * DRIFT_DOWN + sy,
      sx,
      sy,
      beat,
    };
  }

  /**
   * One of them, close enough to see.
   *
   * `Surfacing` ends on fourteen fish at four times the shoal's size, and the note
   * under that decision is that a campaign about a swarm has to show the player a
   * single member of it at least once, big enough to be an animal rather than a
   * dot. This film cites that note and then draws thirty-four bodies of eight
   * pixels, none of which can carry it.
   *
   * So: one, low and to the left of where the swarm was left, coming up on its own
   * out of the bottom third while the sea opens above it. It is not a different
   * kind of thing and it is not the hero of anything - it is drawn with the same
   * three terms of motion as every body in the field, it swims the same way, and
   * it is subject to the same water. What it has is twice the size and twice the
   * cilia, each of them individually legible, carrying the metachronal wave slowly
   * enough that the player can see the stroke run round it and understand what has
   * been moving all thirty-four of them for the last five seconds.
   *
   * It comes up to size across the third movement rather than being there from the
   * first frame, and it starts a beat after the field does, because that movement's
   * subject is the transformation and one large body landing on top of it would be
   * competing with it. The size is the film choosing to show one, not the body
   * being nearer the camera - it takes the river at the river's own px/s like
   * everything else in the water - which is the same licence `Surfacing` takes when
   * it draws leapers at four times the shoal without moving them four times closer.
   *
   * It breathes with the light on the held frame - three per cent, and nothing at
   * `breath = 0.5` - because a single animal at rest in a still picture that does
   * not breathe is a specimen.
   */
  private drawNear(v: FilmView, light: number): void {
    const ctx = v.ctx;
    const up = filmRamp(this.t, ESTUARY_QUICKEN_AT + 0.4, ESTUARY_QUICKEN * 0.8);
    if (up <= 0.02) return;
    const here = this.placeNear(v, this.t, this.beating);
    const x = here.x;
    const y = here.y;
    if (x < -90 || x > v.w + 90 || y < -90 || y > v.h + 90) return;
    const was = this.placeNear(v, this.t - 0.05, this.beating - 0.05);
    const heading = Math.atan2(here.sy - was.sy, here.sx - was.sx);
    const size = 13.5 * up * (1 + (v.breath - 0.5) * 0.06);
    const lit = this.shaftLight(v, x, v.time) * light;

    ctx.globalCompositeOperation = 'lighter';
    const halo = ctx.createRadialGradient(x, y, 0, x, y, size * 2.2);
    const peak = 0.13 * up * (1 + lit * 1.7);
    halo.addColorStop(0, rgba(LIFE, clamp(peak, 0, 1)));
    halo.addColorStop(1, rgba(LIFE, 0));
    ctx.fillStyle = halo;
    ctx.beginPath();
    ctx.arc(x, y, size * 2.2, 0, TAU);
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';

    ctx.fillStyle = rgba(LIFE, clamp(up * (0.9 + lit * 0.2), 0, 1));
    ctx.strokeStyle = rgba(LIFE, clamp(up * (0.62 + lit * 0.3), 0, 1));
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.arc(x, y, size * 0.56, 0, TAU);
    ctx.fill();

    // Individually legible, and curved: a cilium bends along its length in the
    // power stroke and folds on the recovery, so the control point is thrown
    // tangentially and the tip lands ahead of the root. Straight segments at this
    // size read as a starburst.
    ctx.beginPath();
    for (let i = 0; i < NEAR_CILIA; i++) {
      const a = (i / NEAR_CILIA) * TAU;
      const ph = here.beat * 1.6 - (a - heading) * 2.2;
      const sweep = Math.sin(ph) * 0.34;
      const reach = size * (0.95 + 0.34 * Math.cos(ph));
      const r0 = size * 0.56;
      const mid = size * 0.8;
      ctx.moveTo(x + Math.cos(a) * r0, y + Math.sin(a) * r0);
      ctx.quadraticCurveTo(
        x + Math.cos(a + sweep * 0.6) * mid,
        y + Math.sin(a + sweep * 0.6) * mid,
        x + Math.cos(a + sweep) * reach,
        y + Math.sin(a + sweep) * reach,
      );
    }
    ctx.stroke();
  }
}
