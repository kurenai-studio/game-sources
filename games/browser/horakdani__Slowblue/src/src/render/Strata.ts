import { clamp, lerp } from '../core/math';
import type { BackdropKind } from './Motif';
import { mix, parseHex, rgba, type Rgb, type ZonePaint } from './Paint';

/**
 * Slowblue: the planes a picture is made of.
 *
 * Every other surface in this renderer draws an object at the distance the
 * simulation put it, and there are exactly two such distances: the course, and the
 * water behind the course. That is why a station reads flat. It is not a shortage
 * of light - a full-frame bloom pass was built to prove that and it made the
 * picture worse, because a filter applied to every pixel equally cannot say which
 * pixels are near - it is a shortage of *planes*.
 *
 * A flat-vector picture gets its depth from three things and none of them is blur:
 * how big a thing is, how far its tone has fallen toward the background, and how
 * fast it goes past. This file is those three as a small number of discrete planes
 * rather than a continuum, because discrete is what reads as flat vector:
 *
 *   far   ~0.34x  one mass, large and simple, tone pulled most of the way to the
 *                 water behind it, and the weakest edge in the frame
 *   mid   ~1x     the light itself and what it hangs in, in hard steps
 *
 * ## Why this is a table
 *
 * The first version of this file was three hundred lines for one station, which is
 * not a plan for forty-two of them. What replaced it is the shape `Motif.ts`
 * already uses: four plane *primitives* - a mass, a fan of beams, veils of
 * suspended matter, bands running the way the course runs - and one table entry
 * per station saying which of them it has and at what numbers.
 *
 * The reverted `Radiance.ts` was a forty-two line table too, and the table was
 * never what was wrong with it: it tabulated a *filter*. Applied to planes the
 * same skeleton is the right answer, because a plane is the thing a filter could
 * not be - it knows how far away it is.
 *
 * So an act is one plane family, tuned six ways, and the tuning is the act's
 * story. In act I the mass is the same mass all the way up and only its tone
 * changes: near-black faceted stone on the trench floor, and by the surface a pale
 * sunlit shoulder that is *lighter* than the water it stands in. The light does
 * the opposite journey and arrives from the other side - a vent plume from below
 * that dies as the shoal climbs away from it, then nothing at all, then dust in a
 * current, then the first sun, then sun that runs out at a depth, then daylight.
 * Six pictures, one family, one number moving through them.
 *
 * ## The third plane, and why there isn't one
 *
 * There was a `near` plane at 2.6x: dark contoured bodies - medusae, salp chains -
 * passing very close down the outer fifth of each edge. On a still frame it was the
 * best thing here. In motion it was the worst, and the reason is the same number
 * that made it work: 2.6x is what proves a body is not on the course, because every
 * obstacle scrolls at exactly 1x - and it is also what turns the body into
 * something *falling*. Two dark shapes dropping down the left and right edges of a
 * frame do not read as a camera moving through water. They read as debris, and
 * debris is what act I is least about.
 *
 * The cue that made it legible and the cue that made it wrong were one cue. That is
 * not a calibration problem, so it was removed rather than slowed down: at a rate
 * close enough to the course to stop falling, it would have been back to being an
 * obstacle.
 *
 * ## Scope
 *
 * Act I. `SPECS` holds the stations that have been drawn; `hasStrata` is a lookup
 * in it, and the renderer skips the whole pass for a station that is not there
 * yet, so the acts arrive one at a time without the others paying for it.
 */

/** Which of the two planes a call is drawing. */
export type Plane = 'far' | 'mid';

export interface StrataView {
  ctx: CanvasRenderingContext2D;
  paint: ZonePaint;
  w: number;
  h: number;
  cameraY: number;
  time: number;
  /** 0..1 through the current station. The second colour is a function of it. */
  progress: number;
  /** Crossfade weight while a level change is in flight. */
  alpha: number;
  /** 0.4..1. The suspended matter in the mid plane is what a weak phone loses. */
  quality: number;
}

/* -------------------------------------------------------------------------- */
/*  what a station's planes are made of                                       */
/* -------------------------------------------------------------------------- */

/**
 * A colour named out of the zone palette rather than written down: two palette
 * keys and how far between them. Everything in the far plane is coloured this way,
 * so a mass is always *the water's own colour at another distance* and can never
 * disagree with the zone it stands in - the crossfade between two stations then
 * costs nothing, because the palette is already being interpolated.
 */
type PaintKey = 'top' | 'mid' | 'bottom' | 'rock' | 'rockRim' | 'speck';
type Tone = [PaintKey, PaintKey, number];

/** A value that moves across the station: what it is at progress 0, then at 1. */
type Ramp = [number, number];

/** Base fraction of the frame, and how much of that again is dealt per element. */
type Spread = [number, number];

/**
 * The far plane: one mass, anchored to a frame edge, arriving every `spacing`.
 *
 * `span` is the number this whole plane turned on. It was 2.2 - a mass more than
 * twice the height of the screen - and the first frame of it was exactly what
 * `Backdrop.walls` warns about. Not the tone or the edge, both as faint as
 * intended: at that size *no camera position shows its top*, so what is on the
 * glass is a slice through a flank, one long near-vertical boundary running off
 * both edges of the frame. That is a wall whatever the file drawing it calls it.
 * Under 1 the mass always arrives, peaks and leaves as one object you can see the
 * ends of, and a thing you can see the ends of is not a boundary.
 */
interface MassSpec {
  /** Parallax rate. Far below 1, which is what proves it is not on the course. */
  rate: number;
  /** Screen pixels between one mass and the next. See `gapFor`. */
  spacing: number;
  /** Height as a fraction of the frame. Must stay under 1. */
  span: number;
  /** Width as a fraction of the frame. */
  width: Spread;
  shape: 'ridge' | 'facet';
  /** The body colour, out of the palette. */
  body: Tone;
  fill: number;
  /**
   * Contour alpha.
   *
   * The rule is that the furthest plane gets the weakest edge, and the two darkest
   * stations are where that rule needs its exception written down. Between
   * `#010108` and `#170d34` there is not enough range in the hadal palette for a
   * *fill* to describe a shape - the mass is a tonal shift you have to hunt for -
   * so down there the edge is what carries the silhouette and the fill stays as
   * flat as ever. That is the opposite of adding contrast to the mass: a line is
   * how flat vector draws a thing it cannot afford to shade.
   */
  rim: number;
  /** How far the contour colour is pulled off the body toward the rim colour. */
  rimMix?: number;
  /** Draw the contour in the station's second colour rather than the rock's. */
  rimTint?: boolean;
}

/**
 * A fan of light from above, in hard steps.
 *
 * Each beam is three nested wedges and the falloff is the *step* between them,
 * alphas going by roughly a factor of two rather than easing, because a ramp you
 * cannot find the edges of is a gradient and a gradient is the one thing this
 * whole file exists instead of. They converge on a source above and off to one
 * side, so a station has a light *direction* rather than a light level.
 *
 * This one is allowed to be anchored to the glass, and the reason is the only
 * thing that makes it different from `VentSpec`: the sun does not go past.
 */
interface BeamSpec {
  from: 'above';
  count: number;
  /** Half-width at the root. */
  base: Spread;
  /** How far into the frame the beams reach, as a fraction of its height. */
  reach: Ramp;
  /** Sideways convergence on the source. 0 leaves the fan parallel. */
  lean: number;
  /** Alpha of the innermost wedge. */
  strength: Ramp;
  /** 0..1: how much the beams end at *different* depths - light running out. */
  ragged: number;
  /** Speed of the fan's own drift. Zero under reduced motion regardless. */
  drift: number;
}

/**
 * Light out of a hole in the seabed.
 *
 * Slowblue: this started as the beam fan pointed the other way, and on the trench
 * floor that put a pale wedge in each bottom corner of the frame that never moved.
 * Clipped by the frame edges, screen-anchored while everything around them
 * scrolled - which does not read as light at all. It reads as a rendering fault,
 * and that is what it was called the first time anyone else saw it.
 *
 * The mistake was conceptual rather than a bad number, so it is worth stating: a
 * shaft from above may be glued to the glass because the sun is far enough away
 * that it never goes past. A vent is a *place*, on rock the shoal is climbing
 * away from, and a place goes past like every other place. So this is
 * world-anchored, arrives every `spacing` of its own travel, is not drawn at all
 * while its vent is outside the frame - and is never allowed within a fifth of a
 * frame edge, because a lit wedge cut off by the edge of the play field is the
 * exact shape this station lost its canyon walls for.
 */
interface VentSpec {
  from: 'below';
  count: number;
  base: Spread;
  /** How far the plume rises above its vent, as a fraction of the frame. */
  reach: Ramp;
  /** Alpha of the innermost wedge. Falls, because the shoal is leaving. */
  strength: Ramp;
  drift: number;
  /** Screen pixels between one vent and the next. */
  spacing: number;
  /** Parallax rate of the vent itself. Between the far plane and the course. */
  rate: number;
}

/** Broad columns of suspended matter: the water the light is in, as a shape. */
interface VeilSpec {
  count: number;
  width: number;
  alpha: number;
  sway: number;
  /** How far down the frame the columns hold together. 1 is the whole of it. */
  reach: number;
}

/**
 * Long ribbons running the way the course runs. The current, as a poster draws it.
 *
 * `length` is deliberately more than the frame and the ends are points rather than
 * cuts. The first version was a straight-sided quad shorter than the screen, which
 * on the glass is a *rectangle*: five of them at three different depths gave the
 * Drift a stack of translucent boxes with hard horizontal lids, and where two
 * overlapped the lid got brighter and read as a panel. A ribbon has to be longer
 * than what you can see of it and it has to taper, or it is a shape rather than a
 * flow.
 */
interface BandSpec {
  count: number;
  rate: number;
  /** Screen pixels between one ribbon and the next before wrapping. */
  spacing: number;
  width: number;
  /** As a fraction of the frame. Over 1, so most ends are off the glass. */
  length: number;
  alpha: number;
}

interface StationSpec {
  /**
   * The station's one second colour, and the only colour in this file that is not
   * already in the zone palette. One per station, held to one: two accent colours
   * in a flat picture is not richness, it is an argument.
   */
  tint: string;
  /**
   * Exponent on `progress` before anything reads it. 2 puts most of the change in
   * the last third of the station, which is what a light that *arrives* does; 1 is
   * a plain ramp, and below 1 the change happens early and then holds.
   */
  curve: number;
  /**
   * How much of the second colour is in the mid plane's paint, at progress 0 and
   * 1. The rest is the water's own suspended-matter colour, so a station's light
   * is by construction the water lit rather than a colour laid over it.
   *
   * The default is where the Blue Rise landed. A vent needs more: the trench
   * floor's ember mixed only halfway into a violet speck comes out *pink*, which
   * is not a colour anything down there could be.
   */
  blend?: Ramp;
  far?: MassSpec;
  beams?: BeamSpec;
  vents?: VentSpec;
  veils?: VeilSpec;
  bands?: BandSpec;
}

/** Where the mid plane's paint sits between the water's speck and the tint. */
const BLEND: Ramp = [0.45, 0.85];

/**
 * Act I, from the trench floor to the surface.
 *
 * Read the `body` column downward and it is the whole ascent in one number: 0.72
 * of the way to the dark, then 0.45 in the black water where a mass is barely
 * more than an absence, then 0.95, then 0.88, then 0.94 - and at the surface the
 * mix changes ends entirely and the mass is pulled *toward* `top`, so the same
 * stone that was a hole in the water six stations ago is now the palest thing in
 * the frame.
 *
 * Read `tint` downward and it is the same climb told by the light: ember, then a
 * cold blue that is only ever a contour, then sand, then the first amber, then
 * gold, then daylight.
 */
const SPECS: Partial<Record<BackdropKind, StationSpec>> = {
  /*
   * The trench floor. The only warmth in the campaign that comes from *below*, and
   * the only station whose light gets weaker as it goes: `strength` falls from
   * 0.075 to 0.02 because the vents are what the shoal is climbing away from.
   *
   * Its mass is the one place in act I where a contour would be a mistake to
   * strengthen. This station already had filled silhouettes down both edges once
   * and lost them for being read as obstacles; what makes this version safe is not
   * that it is fainter but that it is *one* mass, on one side, that arrives and
   * leaves. `gapFor` is what enforces the "one" part, and `VentSpec` is the same
   * lesson learned a second time about the light.
   */
  walls: {
    tint: '#ff8a4c',
    curve: 0.7,
    blend: [0.86, 0.96],
    far: {
      rate: 0.3,
      spacing: 2400,
      span: 0.7,
      width: [0.2, 0.12],
      shape: 'facet',
      body: ['bottom', 'mid', 0.72],
      fill: 0.72,
      rim: 0.34,
      rimMix: 0.55,
    },
    vents: {
      from: 'below',
      count: 2,
      base: [0.055, 0.03],
      reach: [0.46, 0.24],
      strength: [0.075, 0.02],
      drift: 0.09,
      spacing: 1900,
      rate: 0.55,
    },
  },

  /*
   * Black water, which owes the player nothing to look at, and now owes it one
   * thing: a mass going past in the dark, and no light of any kind on it.
   *
   * This is the only station in the act with a far plane and no mid plane at all,
   * and that is the point rather than an omission - an empty station between two
   * full ones is what makes the full ones read as full. The body is pulled only
   * 0.45 toward `mid`, so the mass is darker than the water at the bottom of the
   * frame and barely separates from it at the top; what actually says it is there
   * is a contour in the station's own cold blue, at 0.14, which is the faintest
   * edge in act I. You notice the abyss has a shape in it about a second after it
   * arrives, which is the correct amount of late.
   */
  void: {
    tint: '#7f9dff',
    curve: 1,
    far: {
      rate: 0.32,
      spacing: 3900,
      span: 0.8,
      width: [0.24, 0.1],
      shape: 'facet',
      body: ['bottom', 'mid', 0.45],
      fill: 0.8,
      rim: 0.24,
      rimMix: 0.6,
      rimTint: true,
    },
  },

  /*
   * The Drift. Its mass is the lowest and widest in the act - stone the current
   * has been polishing for a long time, which is what `Motif`'s `scoured` material
   * says about the rock in front of it - and its mid plane is the current itself:
   * four ribbons at 0.72x, each a tapered lens with a narrower one inside it,
   * because a step is how this file draws a falloff.
   *
   * The second colour is sand rather than any kind of blue. Every other colour in
   * the midnight zone is blue, so a blue accent here would have been a tone and
   * not a colour, and what the current is actually carrying down from above is
   * silt.
   */
  stream: {
    tint: '#d8c9a6',
    curve: 1,
    far: {
      rate: 0.36,
      spacing: 2800,
      span: 0.52,
      width: [0.3, 0.16],
      shape: 'ridge',
      body: ['bottom', 'mid', 0.95],
      fill: 0.55,
      rim: 0.3,
      rimMix: 0.5,
    },
    bands: { count: 4, rate: 0.72, spacing: 620, width: 0.035, length: 1.25, alpha: 0.035 },
  },

  /*
   * The Blue Rise: the station this file was prototyped on, and every number in it
   * is the one that was looked at and approved. It is left alone on purpose - the
   * table has to be able to hold the picture that justified building it, and if
   * generalising the code had quietly moved this station's numbers there would be
   * nothing to check the other five against.
   *
   * Warm is not what four hundred metres of seawater does to sunlight; red is the
   * first thing water takes. It is here because the act is a climb toward air and
   * the second colour has to be the thing being climbed toward, and the honesty is
   * bought back by `curve: 2` - at the bottom of the station there is almost none
   * of it, and by the top it is the loudest thing in the frame. The player watches
   * the sun arrive over a thousand metres instead of finding it already there.
   */
  rise: {
    tint: '#ffbc70',
    curve: 2,
    far: {
      rate: 0.34,
      spacing: 3400,
      span: 0.85,
      width: [0.3, 0.16],
      shape: 'ridge',
      body: ['bottom', 'mid', 0.88],
      fill: 0.62,
      rim: 0.22,
    },
    beams: {
      count: 3,
      from: 'above',
      base: [0.12, 0.06],
      reach: [0.52, 0.86],
      lean: 0.5,
      strength: [0.012, 0.07],
      ragged: 0,
      drift: 0.055,
    },
    veils: { count: 3, width: 0.075, alpha: 0.026, sway: 0.07, reach: 1 },
  },

  /*
   * The Light Line: the last depth where light holds together into columns before
   * dissolving. `ragged` is the station - the beams end at four different depths
   * around 0.46 of the frame, so the boundary the level is named for is *where the
   * light stops* rather than a line drawn across the picture. Nothing horizontal is
   * drawn here at all; a hard rule across the frame in the middle band is the one
   * shape this game cannot afford, because the HUD is made of them.
   *
   * The veils stop at 0.5 for the same reason the backdrop's dust does: below the
   * boundary there is nothing left up there to catch.
   */
  'light-line': {
    tint: '#ffd98e',
    curve: 1.4,
    far: {
      rate: 0.34,
      spacing: 3000,
      span: 0.78,
      width: [0.28, 0.14],
      shape: 'ridge',
      body: ['bottom', 'mid', 0.94],
      fill: 0.58,
      rim: 0.2,
    },
    beams: {
      count: 4,
      from: 'above',
      base: [0.085, 0.045],
      reach: [0.34, 0.52],
      lean: 0.34,
      strength: [0.03, 0.062],
      ragged: 0.5,
      drift: 0.045,
    },
    veils: { count: 3, width: 0.06, alpha: 0.022, sway: 0.06, reach: 0.5 },
  },

  /*
   * The Surface, and the one station where the mass changes sides of the palette.
   * `body` mixes from `mid` toward `top` rather than up from `bottom`, so the
   * shoulder of reef at the frame edge is *lighter* than the water below it - which
   * is what forty metres of daylight does to stone, and is also the whole payoff of
   * reading this column downward from the trench floor.
   *
   * It is drawn low - `span` 0.5, the shortest in the act - because by here the
   * seabed is a long way underneath and a mass that filled the frame would be
   * claiming otherwise. The beams are the opposite: the longest reach in act I,
   * past the bottom of the frame at the end of the station.
   */
  surface: {
    tint: '#fff4c2',
    curve: 1.2,
    far: {
      rate: 0.34,
      spacing: 2600,
      span: 0.5,
      width: [0.32, 0.16],
      shape: 'ridge',
      body: ['mid', 'top', 0.3],
      fill: 0.5,
      rim: 0.2,
    },
    beams: {
      count: 4,
      from: 'above',
      base: [0.115, 0.055],
      reach: [0.72, 1.05],
      lean: 0.62,
      strength: [0.05, 0.085],
      ragged: 0.12,
      drift: 0.05,
    },
    veils: { count: 3, width: 0.08, alpha: 0.03, sway: 0.05, reach: 1 },
  },
};

/** The table, with every second colour parsed once at module load. */
const STRATA = new Map<BackdropKind, { spec: StationSpec; tint: Rgb }>(
  (Object.entries(SPECS) as [BackdropKind, StationSpec][]).map(([kind, spec]) => [
    kind,
    { spec, tint: parseHex(spec.tint) },
  ]),
);

export function hasStrata(kind: BackdropKind): boolean {
  return STRATA.has(kind);
}

/** Every station with planes, for the table's own tests. */
export function plannedStations(): BackdropKind[] {
  return [...STRATA.keys()];
}

export function drawStrata(kind: BackdropKind, v: StrataView, plane: Plane): void {
  const entry = STRATA.get(kind);
  if (entry === undefined) return;
  if (v.alpha <= 0.01) return;
  const { spec, tint } = entry;

  if (plane === 'far') {
    if (spec.far !== undefined) mass(v, spec.far, tint);
    return;
  }

  /*
   * `source-over`, not `lighter`, and set rather than assumed - this pass runs
   * straight after the obstacles and what they leave the context in is their
   * business.
   *
   * Additive is how a glow is drawn and a glow is exactly what these stations do
   * not want: over a teal already high in green and blue, adding warm light lifts
   * the red channel a little and washes the rest, so the shaft comes out pale,
   * hazy and the same hue as the water it is in. A flat fill at a printable alpha
   * *replaces* some of that teal instead of adding to it, so the hue actually
   * moves - which is the only reason a second colour is here at all. It is also
   * what a screen print does, and that is the language.
   */
  v.ctx.globalCompositeOperation = 'source-over';
  const p = Math.pow(clamp(v.progress, 0, 1), spec.curve);
  /*
   * The second colour, mixed into the water's own suspended-matter colour and
   * getting purer as the station runs. One computation for the whole mid plane, so
   * every element in it is lit by the same light by construction.
   */
  const blend = spec.blend ?? BLEND;
  const lit = mix(v.paint.speck, tint, lerp(blend[0], blend[1], p));
  if (spec.bands !== undefined && v.quality > 0.65) bands(v, spec.bands, lit);
  if (spec.vents !== undefined) vents(v, spec.vents, lit, p);
  if (spec.beams !== undefined) beams(v, spec.beams, lit, p);
  if (spec.veils !== undefined && v.quality > 0.65) veils(v, spec.veils, lit);
  v.ctx.globalCompositeOperation = 'source-over';
}

/* -------------------------------------------------------------------------- */
/*  the primitives                                                            */
/* -------------------------------------------------------------------------- */

/** Stable 0..1 from an integer. Keeps the whole file free of stored state. */
function hash(i: number): number {
  let h = Math.imul(i ^ 0x9e3779b9, 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 13), 0xc2b2ae35);
  return ((h >>> 8) & 0xffff) / 0xffff;
}

function tone(paint: ZonePaint, t: Tone): Rgb {
  return mix(paint[t[0]], paint[t[1]], t[2]);
}

/** Wraps a world-anchored element into the visible band at its own parallax rate. */
function wrapY(v: StrataView, index: number, span: number, rate: number): number {
  const period = v.h + span * 2;
  const raw = index * span - v.cameraY * rate;
  return (((raw % period) + period) % period) - span;
}

/**
 * The distance between two masses, and the one thing about the far plane that is
 * not a matter of taste.
 *
 * A single mass at a frame edge is a landmark. Two of them, one down each edge at
 * the same time, is a corridor - which is the exact shape this game removed from
 * the trench floor after players steered around it and lost width they always had.
 * Every station's `spacing` is already comfortably more than a frame, but "already
 * comfortably" is a statement about the screens it was looked at on, so the floor
 * is enforced here in terms of the frame itself and the table cannot get it wrong
 * on a display nobody tested.
 */
function gapFor(v: StrataView, s: MassSpec, span: number): number {
  return Math.max(s.spacing, (v.h + span) * 1.25);
}

/**
 * The far plane: a mass in the water.
 *
 * A station of open water has no scale in it - the shoal, the rings and the rock
 * all arrive at the same rate and leave at the same rate, so nothing in the frame
 * says how far the station has come. A mass that takes most of a level to go past
 * says it continuously, and says it without a number.
 *
 * One polygon, one flat colour taken from *between* two ends of the water
 * gradient, so the same fill is lighter than the water at the bottom of the frame
 * and darker than it at the top. That is what distance does in the sea, it is
 * free, and it is why this plane needs no contrast of its own: the mass separates
 * from the water by being flatter than the water is, not by being darker. The
 * contour exists only to keep the summit from dissolving where the fill crosses
 * the water's own tone.
 */
function mass(v: StrataView, s: MassSpec, tint: Rgb): void {
  const ctx = v.ctx;
  const span = v.h * s.span;
  const gap = gapFor(v, s, span);
  const index = Math.floor((v.cameraY * s.rate - v.h) / gap);
  const body = tone(v.paint, s.body);
  const rim = mix(body, s.rimTint === true ? tint : v.paint.rockRim, s.rimMix ?? 0.3);

  for (let n = index; n <= index + 2; n++) {
    const sy = n * gap - v.cameraY * s.rate;
    if (sy > v.h + span || sy < -span) continue;
    const right = hash(n * 3 + 1) > 0.5;
    // Wider than it is tall, which is what a seamount is and what a wall is not.
    const width = v.w * (s.width[0] + hash(n * 7) * s.width[1]);

    ctx.beginPath();
    profile(ctx, v, s.shape, n, sy, span, width, right);
    ctx.fillStyle = rgba(body, s.fill * v.alpha);
    ctx.fill();
    ctx.strokeStyle = rgba(rim, s.rim * v.alpha);
    ctx.lineWidth = 1.2;
    ctx.stroke();
  }
}

/**
 * One mass outline, from the frame edge up over a shoulder and back. Every vertex
 * comes from `hash`, so the same mass is the same shape every time it is drawn and
 * no state has to be kept for it.
 *
 * Two shapes, which are two materials rather than two levels of detail:
 *
 *   ridge   a raised cosine, roughened. A mass has a top rather than a point.
 *   facet   straight flanks and a coarse jag: fractured stone, unweathered.
 *
 * There was a third - `terrace`, the same shoulder quantised into treads and
 * risers, meant as what a long time in a current does to sedimentary rock. On the
 * glass it was a stack of rectangles in the corner of the frame. Steps read as
 * geometry rather than as stone at this scale, and this file already knows what
 * happens when scenery reads as geometry, so the Drift's mass is a low smooth
 * ridge instead - which is what `Motif` says `scoured` is anyway.
 */
function profile(
  ctx: CanvasRenderingContext2D,
  v: StrataView,
  shape: MassSpec['shape'],
  seed: number,
  sy: number,
  span: number,
  width: number,
  right: boolean,
): void {
  const edge = right ? v.w : 0;
  const inward = right ? -1 : 1;
  const steps = shape === 'facet' ? 6 : 11;
  // Fractured stone gets more than twice the roughness, and it is load-bearing:
  // six straight segments over most of a frame will happily line up into one long
  // diagonal, and one long diagonal is the shape this file exists to avoid.
  const rough = shape === 'facet' ? 0.38 : 0.16;
  ctx.moveTo(edge, sy + span * 0.5);
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    const shoulder =
      shape === 'facet' ? 1 - Math.abs(2 * t - 1) ** 1.4 : Math.sin(t * Math.PI) ** 0.72;
    const jag = (hash(seed * 61 + i * 13) - 0.5) * rough;
    const out = width * clamp(shoulder + jag, 0, 1.1);
    ctx.lineTo(edge + inward * out, sy + span * (0.5 - t));
  }
  ctx.lineTo(edge, sy - span * 0.5);
  ctx.closePath();
}

/**
 * The three nested wedges every beam is made of. Outermost and faintest first, and
 * the alphas step by roughly a factor of two rather than easing: the three are
 * meant to be *seen* as three.
 */
const WEDGES: readonly (readonly [number, number])[] = [
  [1, 0.34],
  [0.55, 0.66],
  [0.24, 1],
];

/** The light from above. */
function beams(v: StrataView, s: BeamSpec, lit: Rgb, p: number): void {
  const ctx = v.ctx;
  const t = v.time;
  const rootY = -20;
  const reach = v.h * lerp(s.reach[0], s.reach[1], p);
  const strength = lerp(s.strength[0], s.strength[1], p);
  const last = Math.max(1, s.count - 1);

  for (let i = 0; i < s.count; i++) {
    const drift = Math.sin(t * s.drift + i * 1.9) * v.w * 0.05;
    const apexX = v.w * (0.12 + (i * 0.78) / last) + drift;
    const lean = (apexX / v.w - 0.42) * v.w * s.lean;
    const base = v.w * (s.base[0] + hash(i * 17) * s.base[1]);
    // Where this beam gives out. `ragged` is the Light Line's whole subject: light
    // that ends at four different depths is a boundary you cannot draw a line along.
    const endY = reach * (1 - s.ragged * hash(i * 23 + 5));

    for (const [spread, weight] of WEDGES) {
      const half = base * spread;
      ctx.beginPath();
      ctx.moveTo(apexX - half * 0.35, rootY);
      ctx.lineTo(apexX + half * 0.35, rootY);
      ctx.lineTo(apexX + lean + half, endY);
      ctx.lineTo(apexX + lean - half, endY);
      ctx.closePath();
      ctx.fillStyle = rgba(lit, strength * weight * v.alpha);
      ctx.fill();
    }
  }
}

/**
 * The light out of a vent, which is a thing in the water rather than a light level.
 *
 * The same three nested wedges as a beam and nothing else in common: the root is a
 * world position that scrolls down the frame and off it as the shoal climbs, the
 * plume rises *from* that root, and when the vent is not in the frame this draws
 * nothing at all. Two plumes per vent, side by side, because a vent field is a
 * crack rather than a point - and both of them well inside the frame, which is not
 * a taste decision either: see `VentSpec`.
 */
function vents(v: StrataView, s: VentSpec, lit: Rgb, p: number): void {
  const ctx = v.ctx;
  const t = v.time;
  const reach = v.h * lerp(s.reach[0], s.reach[1], p);
  const strength = lerp(s.strength[0], s.strength[1], p);
  const index = Math.floor((v.cameraY * s.rate - v.h) / s.spacing);

  for (let n = index; n <= index + 2; n++) {
    const rootY = n * s.spacing - v.cameraY * s.rate;
    if (rootY < 0 || rootY - reach > v.h) continue;
    // Never nearer a side than a fifth of the frame.
    const mouth = v.w * (0.22 + hash(n * 11 + 3) * 0.56);
    for (let i = 0; i < s.count; i++) {
      const drift = Math.sin(t * s.drift + i * 1.9 + n) * v.w * 0.03;
      const apexX = mouth + (i - (s.count - 1) / 2) * v.w * 0.08 + drift;
      const base = v.w * (s.base[0] + hash(n * 7 + i * 17) * s.base[1]);
      const endY = rootY - reach * (0.7 + hash(n * 13 + i) * 0.5);

      for (const [spread, weight] of WEDGES) {
        const half = base * spread;
        ctx.beginPath();
        // Narrow at the vent, spreading as it rises: the opposite of a sun shaft.
        ctx.moveTo(apexX - half * 0.28, rootY);
        ctx.lineTo(apexX + half * 0.28, rootY);
        ctx.lineTo(apexX + half, endY);
        ctx.lineTo(apexX - half, endY);
        ctx.closePath();
        ctx.fillStyle = rgba(lit, strength * weight * v.alpha);
        ctx.fill();
      }
    }
  }
}

/**
 * The water the light is in: broad columns of suspended matter, filled rather than
 * stroked. The backdrops draw hairlines here at alpha 0.009 and they are invisible
 * on every panel this game has been looked at on; a column that is a *shape* costs
 * the same and can actually be seen.
 */
function veils(v: StrataView, s: VeilSpec, lit: Rgb): void {
  const ctx = v.ctx;
  const t = v.time;
  const last = Math.max(1, s.count - 1);
  const foot = v.h * s.reach + 20;
  for (let i = 0; i < s.count; i++) {
    const sway = Math.sin(t * s.sway + i * 2.3);
    const x = v.w * (0.2 + (i * 0.6) / last) + sway * v.w * 0.04;
    const half = v.w * s.width;
    ctx.beginPath();
    ctx.moveTo(x - half * 0.5, -20);
    ctx.bezierCurveTo(x + half, v.h * 0.3, x - half, v.h * 0.7, x + half * 0.4, foot);
    ctx.lineTo(x + half * 1.4, foot);
    ctx.bezierCurveTo(x, v.h * 0.7, x + half * 2, v.h * 0.3, x + half * 0.5, -20);
    ctx.closePath();
    ctx.fillStyle = rgba(lit, s.alpha * v.alpha);
    ctx.fill();
  }
}

/**
 * Ribbons of current, running the way the course runs.
 *
 * Two nested shapes rather than a stroke with a soft edge, for the same reason the
 * beams are three: the falloff is a step you can find the edge of. Each is a
 * six-point lens - a point at each end, full width across the middle - sheared
 * sideways along its own length, which is a ribbon. The straight-sided quad it
 * replaced was a rectangle, and five rectangles at three depths is a stack of
 * panels rather than a current.
 */
function bands(v: StrataView, s: BandSpec, lit: Rgb): void {
  const ctx = v.ctx;
  const len = v.h * s.length;
  for (let i = 0; i < s.count; i++) {
    const y = wrapY(v, i, s.spacing, s.rate);
    if (y + len * 0.5 < -40 || y - len * 0.5 > v.h + 40) continue;
    const x = v.w * (0.08 + hash(i * 3 + 1) * 0.84);
    const shear = (hash(i * 5) - 0.5) * v.w * 0.18;
    const half = v.w * s.width * (0.6 + hash(i * 7) * 0.8);
    const top = y - len * 0.5;
    const bottom = y + len * 0.5;
    // Where the ribbon reaches full width: the middle three fifths of its length.
    const upper = top + len * 0.2;
    const lower = bottom - len * 0.2;
    const at = (f: number): number => x + shear * (f - 0.5) * 2;
    for (const [spread, weight] of [
      [1, 0.5],
      [0.42, 1],
    ] as const) {
      const w = half * spread;
      ctx.beginPath();
      ctx.moveTo(at(0), top);
      ctx.lineTo(at(0.2) + w, upper);
      ctx.lineTo(at(0.8) + w, lower);
      ctx.lineTo(at(1), bottom);
      ctx.lineTo(at(0.8) - w, lower);
      ctx.lineTo(at(0.2) - w, upper);
      ctx.closePath();
      ctx.fillStyle = rgba(lit, s.alpha * weight * v.alpha);
      ctx.fill();
    }
  }
}
