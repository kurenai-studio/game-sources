import { CAMPAIGN } from '../config/campaign';
import type { Level } from '../config/levels';
import { parseHex, type Rgb } from './Paint';

/** Every act's levels, keyed by act key. The DEV table check walks this. */
const ACT_LEVELS: Record<string, Level[]> = Object.fromEntries(
  CAMPAIGN.map((a) => [a.act.key, a.act.levels]),
);

/**
 * Slowblue: what a level *is*, in one table.
 *
 * The zone palette says how far the ascent has opened - four of them, shared by
 * six levels. A level has a name, and a name is a promise: the trench floor owes
 * the player walls, black water owes them emptiness, and the surface owes light.
 *
 * A motif is the level's identity applied to the two things that fill the screen:
 * the water behind everything (`backdrop`, `wash`) and the rock in it (everything
 * else). It is layered *over* the zone palette rather than replacing it, so depth
 * still reads as depth and the crossfade between zones still works.
 *
 * Nothing here is readable by the simulation. Two levels with identical geometry
 * would play identically and look nothing alike, which is the point.
 */

/** The water's own signature. One per level, and no two levels share one. */
export type BackdropKind =
  /** The ascent's end: the water ceiling approaches and opens into light. */
  | 'surface'
  /** The last edge of usable light, suspended in the water below the surface. */
  | 'light-line'
  /** The Drift: the current itself, drawn as long streaks going past. */
  | 'stream'
  /** Black water: nothing. Deliberately, expensively, nothing. */
  | 'void'
  /** The Blue Rise: broad water columns and bubbles travelling upward. */
  | 'rise'
  /** The trench floor: canyon walls down both edges, and heat in the cracks. */
  | 'walls'
  // --- act II: the air. Implemented in `Sky.ts`, dispatched from `Backdrop.ts`. ---
  /** Just off the water: crests, foam and torn spray, sinking as the station climbs. */
  | 'spray'
  /** A sea cliff going past, and the seabird colony on it. */
  | 'cliff'
  /** The fair-weather cumulus field, seen across the tops rather than from under. */
  | 'cumulus'
  /** The flyway: cloud streets running the way the course runs, and other flocks. */
  | 'passage'
  /** The one station where the medium can be seen: curtains and falling water. */
  | 'squall'
  /** The top of the weather, spreading because it cannot rise. */
  | 'anvil'
  // --- act III: the upper air. Implemented in `Upper.ts`. ---
  /** The tropopause: the whole troposphere seen from its own ceiling. */
  | 'jet'
  /** 20 km. The deepest blue there is, and the last one that is a blue. */
  | 'ozone'
  /** The stratosphere: a black sky in daylight, and cloud lit from underneath. */
  | 'nacre'
  /** 50 km. Stars in daylight, and the airglow layer resolving below. */
  | 'blacksky'
  /** The mesopause. Stars, airglow, and the last cloud in the atmosphere. */
  | 'noctilucent'
  /** The Karman line: nothing at all, and the first stars that do not twinkle. */
  | 'line'
  // --- act IV: orbit. Implemented in `Orbit.ts`. ---
  /** Free fall: the planet's limb below, and the first frame with no air in it. */
  | 'freefall'
  /** The aurora, seen from above it: curtains coming up off the bottom of the frame. */
  | 'aurora'
  /** The Earth's shadow. The swarm is the only light source there is. */
  | 'umbra'
  /** The debris belt: the one band up here with anything man-made in it. */
  | 'debris'
  /** The well: the frame's floor glows, because that is where everything falls. */
  | 'well'
  /** The turn. The whole planet, and the atmosphere as one bright line along it. */
  | 'overview'
  // --- act V: the fallback. Implemented in `Reentry.ts`. ---
  /** The deorbit: still orbit, and the planet no longer beside you but beneath. */
  | 'deorbit'
  /** The night side: the unlit half, with weather lighting itself up far below. */
  | 'nightside'
  /** The aurora from inside it, which is the first place the player recognises. */
  | 'auroraBelow'
  /** Re-entry: the loudest frame in the game, and the only one that is hot. */
  | 'plasma'
  /** Cooling. The fire goes out and what is left is dust falling into weather. */
  | 'meteordust'
  /** The nucleus: the first cloud from above, and the whole of act VI in one frame. */
  | 'nucleus'
  // --- act VI: the rain. Implemented in `Rain.ts`. ---
  /** Cirrus, falling through it: the last ice in the campaign. */
  | 'cirrusFall'
  /** The anvil from underneath - the first place the player has been before. */
  | 'underanvil'
  /** The downpour: the first backdrop whose lines run the way the course runs. */
  | 'downpour'
  /** The canopy: the first green, and the first ceiling made of leaves. */
  | 'canopyFall'
  /** The brook: running water, stone, and the bank going past. */
  | 'brook'
  /** The estuary: the river opening out, and the sea taking over. */
  | 'estuary'
  // --- act VII: the homecoming. Implemented in `Homecoming.ts`. ---
  /** The salt line: fresh water over salt, and the haze where they mix. */
  | 'brackish'
  /** The sunlit zone, from above: act I's light met going the other way. */
  | 'sunlitFall'
  /** The twilight zone: the last of the light, going out below rather than above. */
  | 'twilightFall'
  /** The deep sea: nothing, and the first station that cannot be lost. */
  | 'deepsea'
  /** Marine snow: the one frame where the whole world falls with the player. */
  | 'snow'
  /** The trench floor, again. The last frame of the campaign and the first. */
  | 'trenchHome';

/**
 * What a level's stone is *made of*.
 *
 * Slowblue: every mass in the game used to be filled with one vertical gradient and a
 * soft shadow, which is a photograph of a rock at dusk: correct, and completely
 * inert. Material is the difference between "a dark shape" and "obsidian" - it
 * decides how the crest catches light, how many sediment bands cross the body, and
 * what is allowed to grow on the outline.
 */
export type StoneMaterial =
  /** Fractured volcanic glass. Hard, faceted, and lit only from inside. */
  | 'obsidian'
  /** Bare basalt, in water with nothing above it. The one unlit material. */
  | 'basalt'
  /** Rock the current has been polishing for a long time: smooth, banded, dusty. */
  | 'scoured'
  /** Living crust. The first level on the ascent where the stone is inhabited. */
  | 'crust'
  /** Stone furred with new growth, at the depth where growth first becomes possible. */
  | 'furred'
  /** Warm stone close enough to the surface to be lit from above. */
  | 'sunlit'
  /**
   * Cloud, as a mass. The one material that is *lighter* than the air around it,
   * which is why `RockPaint` has to be told not to darken it - every other stone
   * in the game is a hole in the light and this one is the opposite.
   */
  | 'cloud'
  /**
   * Ice, at altitude. Act III's mass, and the one material in the game with a
   * *hard* edge on a luminous body: a stratospheric crystal is faceted, it is
   * lit from one side by a sun below the horizon, and it refracts rather than
   * scatters - so it takes cloud's rule about not being darkened and adds
   * cloud's opposite about not being soft.
   */
  | 'ice'
  /**
   * Wreckage in vacuum. Act IV's mass, and the only *manufactured* material in
   * the game: nothing up here was worn by anything, so it keeps whatever edge it
   * broke with. It is lit by exactly one light and has no fill light at all, so
   * the side facing away from the sun is not dark, it is **black** - and in the
   * umbra the only light there is is the swarm itself.
   */
  | 'wreck'
  /**
   * Living jelly, in deep water. Act VII's material, and the only one in the
   * game that is *alive*.
   *
   * It shares cloud's one structural property - it is brighter than what
   * surrounds it, so it must never be pulled toward black - and shares nothing
   * else. A cumulus is opaque and lit from above; a medusa is translucent and
   * lit from *inside*, by the same gold the player has been carrying for six
   * acts, which is the whole reason act VII can afford a material this soft at
   * the depth where act I had bare basalt.
   */
  | 'medusa';

/**
 * Slowblue: which materials are lighter than the medium around them.
 *
 * Every mass in this game is a hole in the light except these, and almost every
 * decision in `RockPaint` forks on it: whether to darken the body, whether to
 * draw strata and fractures or lobes and an underside, whether the crest gets a
 * hard rim or a wide glow. It is one predicate rather than five `=== 'cloud'`
 * comparisons because it was five, and act VII's jelly would have been painted
 * as a rock by the four of them that were missed.
 */
export function isSoft(material: StoneMaterial): boolean {
  return material === 'cloud' || material === 'medusa';
}

/** What grows on - or is lit inside - the exposed crest of a level's rock. */
export type Fringe =
  | 'none'
  /** A mineral seam. The only fringe that emits rather than reflects. */
  | 'vein'
  /** Sediment trailing off the crest, downstream. */
  | 'silt'
  /** Polyps: dots and one stubby branch. */
  | 'coral'
  /** Blades long enough to lean in the current. */
  | 'kelp'
  /** Short sparse tufts on sunlit stone. */
  | 'weed';

export interface Motif {
  key: string;
  /** Position in `MOTIFS`, which is also the index of the level it dresses. */
  index: number;
  /** Outline vertices for a big mass, and for the beads a wall is chained from. */
  verts: number;
  vertsSmall: number;
  /** How far the outline wanders off the circle, as a fraction of the radius. */
  jag: number;
  /** Stone tones: the lit crest, and the mass under it. Mixed with the zone's rock. */
  crest: Rgb;
  base: Rgb;
  /** A low-intensity environmental accent; used by the trench backdrop vents. */
  accent: Rgb;
  material: StoneMaterial;
  fringe: Fringe;
  /** Sediment bands drawn across a big mass. 0 leaves the body plain. */
  strata: number;
  /**
   * How hard the crest is rim-lit, 0..1.4. This is the campaign's light budget in
   * one number: the trench floor is barely picked out of the dark, and by the
   * surface the top of every rock has daylight on it.
   */
  sheen: number;
  /**
   * 0..1: how much open sky is lighting the whole mass, not just its crest.
   * Water is 0 - forty metres down, a body is a silhouette however sunlit its
   * rim - and the air's stone is 1, because a sea stack at noon is not a hole in
   * the daylight. `RockPaint` scales its near-black pulls by this.
   */
  daylight: number;
  backdrop: BackdropKind;
  /** Laid into the background gradient itself, so it costs nothing to draw. */
  wash: Rgb;
  /**
   * How hard the wash is pushed into the gradient's stops, 0..1 - and **zero is a
   * legal answer**, which is the one thing this field did not used to be able to
   * say.
   *
   * The wash exists for act I, and `Renderer.drawBackground` says so: six levels
   * are painted from four zone palettes there, so two stations sharing one have
   * nothing but this to tell them apart. That is visible in the table when it is
   * measured - `tools/palette.sweep.ts`, in OkLCh - because the only washes in the
   * campaign that carry a real *hue* shift are act I's shared-zone pairs, at 61 and
   * 58 degrees off their own zone mid. Every act after it gives each station its
   * own zone, the mechanism has nothing left to separate, and the thirty authored
   * washes degenerate into a tone: 24 of them sit within 6 degrees of the mid they
   * are laid over and move it almost entirely in lightness.
   *
   * Which is how twelve stations came to declare a wash that is their own zone's
   * `mid`, **byte for byte** - a column filled in rather than authored. Mixing the
   * middle stop with itself is arithmetically nothing (0.0000 in OkLab, against
   * 0.0009 to 0.0371 for the other thirty), but the *other two* stops still get
   * pulled toward it, so the level tint that adds no colour goes on charging the
   * gradient 10 to 16 per cent of its vertical range. Those twelve rendered a
   * flatter water than the zone table authored, and no test could see it: every
   * instrument in the suite reduces a pixel to luminance first, and this defect
   * has no edge in it.
   *
   * So they declare zero. A station may have no colour of its own - most of them
   * genuinely do not, because their zone already is their colour - but it may not
   * pay for one it is not getting. `tests/palette.test.ts` holds the line.
   */
  washAmount: number;
}

interface MotifSpec extends Omit<Motif, 'index' | 'crest' | 'base' | 'accent' | 'wash' | 'daylight'> {
  crest: string;
  base: string;
  accent: string;
  wash: string;
  /** Defaults to 0: underwater. The air table sets it. */
  daylight?: number;
}

/**
 * Six levels, one calm material language. Colour carries the level identity while
 * the silhouettes remain related: broad, smooth and worn by the same water.
 *
 * `sheen` and `fringe` climb together on purpose. They are the ascent told through
 * the rock alone: unlit fractured glass on the trench floor, bare basalt in the
 * black water, then polish, then crust, then growth, then daylight.
 */
const SPECS: MotifSpec[] = [
  {
    key: 'trench-floor',
    verts: 15,
    vertsSmall: 11,
    jag: 0.028,
    crest: '#6b4699',
    // Violet-black rather than black. The trench floor is the first rock the player
    // ever sees, and a mass with no tone in it at all reads as a hole in the water
    // instead of as the thing they have to steer around.
    base: '#150a2b',
    accent: '#ff8a4c',
    material: 'obsidian',
    fringe: 'vein',
    strata: 1,
    sheen: 0.55,
    backdrop: 'walls',
    wash: '#2a0f3f',
    washAmount: 0.24,
  },
  {
    key: 'black-water',
    verts: 16,
    vertsSmall: 12,
    jag: 0.032,
    crest: '#41558f',
    base: '#080e22',
    accent: '#7f9dff',
    material: 'basalt',
    fringe: 'none',
    strata: 2,
    sheen: 0.34,
    backdrop: 'void',
    wash: '#12245c',
    washAmount: 0.16,
  },
  {
    key: 'midnight-current',
    verts: 18,
    vertsSmall: 12,
    jag: 0.018,
    crest: '#4d8c92',
    base: '#08222a',
    accent: '#8fe4dc',
    material: 'scoured',
    fringe: 'silt',
    strata: 3,
    sheen: 0.6,
    backdrop: 'stream',
    wash: '#0e6f77',
    washAmount: 0.18,
  },
  {
    key: 'blue-rise',
    verts: 18,
    vertsSmall: 12,
    jag: 0.045,
    crest: '#5fa3aa',
    base: '#071d28',
    accent: '#8fe4dc',
    material: 'crust',
    fringe: 'coral',
    strata: 2,
    sheen: 0.78,
    backdrop: 'rise',
    wash: '#0d6976',
    washAmount: 0.18,
  },
  {
    key: 'light-line',
    verts: 16,
    vertsSmall: 12,
    jag: 0.035,
    crest: '#579176',
    base: '#0a2118',
    accent: '#79c39a',
    material: 'furred',
    fringe: 'kelp',
    strata: 2,
    sheen: 0.96,
    backdrop: 'light-line',
    wash: '#1f6a4e',
    washAmount: 0.2,
  },
  {
    key: 'surface',
    verts: 17,
    vertsSmall: 12,
    jag: 0.022,
    crest: '#9ccdd6',
    base: '#102d37',
    accent: '#fff4c2',
    material: 'sunlit',
    fringe: 'weed',
    strata: 3,
    sheen: 1.3,
    backdrop: 'surface',
    wash: '#36b4c8',
    washAmount: 0.24,
  },
];

function toMotif(s: MotifSpec, index: number): Motif {
  return {
    ...s,
    index,
    daylight: s.daylight ?? 0,
    crest: parseHex(s.crest),
    base: parseHex(s.base),
    accent: parseHex(s.accent),
    wash: parseHex(s.wash),
  };
}

export const MOTIFS: Motif[] = SPECS.map(toMotif);

/**
 * Act II's six. **Every mass in the air is cloud** - there is no rock above the
 * waterline in this game, because a pale slab of stone hanging in the sky was the
 * single loudest thing wrong with the first version of the act.
 *
 * That makes this table read differently from the water's. Down there `material`
 * carried the level identity and colour followed it; up here the material is one
 * thing all the way up and what carries the station is *what the light is doing
 * to it*: full daylight on the top of a cumulus, a storm's flat grey, the last
 * warm underlight on a stratospheric cloud from a sun below the horizon, and
 * finally ice at the edge of space glowing on its own against black. `sheen` and
 * `daylight` are the whole ascent in two numbers, and both of them fall.
 *
 * `jag` runs high everywhere: a cumulus is lumps, and a smooth capsule painted
 * white reads as a dirigible. Collision stays on the blob circles with its usual
 * forgiveness, so a soft edge that wanders outward is exactly the edge a player
 * should be allowed to brush.
 */
const AIR_SPECS: MotifSpec[] = [
  {
    key: 'spray',
    verts: 17,
    vertsSmall: 12,
    // Shreds torn off the sea are the raggedest cloud in the act.
    jag: 0.13,
    crest: '#ffffff',
    base: '#c3d9e8',
    accent: '#ffe6b0',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 1.5,
    daylight: 1,
    backdrop: 'spray',
    wash: '#7fb2d2',
    washAmount: 0.2,
  },
  {
    key: 'cliff',
    verts: 18,
    vertsSmall: 12,
    // Orographic cloud is cloud that has been pushed into a shape by the ground,
    // so it is smoother along its length and raggeder at its ends than anything
    // that grew where it stands.
    jag: 0.1,
    crest: '#ffffff',
    base: '#bdd3e4',
    accent: '#ffe0a8',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 1.42,
    daylight: 1,
    backdrop: 'cliff',
    wash: '#79aacd',
    washAmount: 0.19,
  },
  {
    key: 'cumulus',
    verts: 19,
    vertsSmall: 13,
    jag: 0.11,
    crest: '#ffffff',
    base: '#b3cadf',
    accent: '#fff2cc',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 1.35,
    daylight: 1,
    backdrop: 'cumulus',
    wash: '#7fb4e0',
    washAmount: 0.18,
  },
  {
    key: 'passage',
    verts: 19,
    vertsSmall: 13,
    // Cloud streets: torn cumulus organised into long parallel lines by the same
    // wind the flock is riding. Raggeder than a deck, and drawn out along it.
    jag: 0.125,
    crest: '#f6fbff',
    base: '#a4bfd8',
    accent: '#ffeecc',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 1.2,
    daylight: 0.92,
    backdrop: 'passage',
    wash: '#4d7cae',
    washAmount: 0.2,
  },
  {
    key: 'squall',
    verts: 19,
    vertsSmall: 13,
    jag: 0.12,
    crest: '#dfe8f2',
    base: '#7d8a99',
    accent: '#a9c6e0',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 0.85,
    daylight: 0.75,
    backdrop: 'squall',
    wash: '#4e5d6e',
    washAmount: 0.24,
  },
  {
    key: 'anvil',
    verts: 18,
    vertsSmall: 12,
    // Flatter lumps than the cumulus stations: an anvil is a cloud that has been
    // ironed against a ceiling, so it keeps a little wander and no more.
    jag: 0.07,
    crest: '#f4f9ff',
    base: '#a9bdd6',
    accent: '#dbe8ff',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 1.05,
    daylight: 0.85,
    backdrop: 'anvil',
    wash: '#4b6da4',
    washAmount: 0.2,
  },
];

export const AIR_MOTIFS: Motif[] = AIR_SPECS.map(toMotif);

/**
 * Slowblue: act III's six, and the campaign's one change of *material*.
 *
 * Acts I and II have two materials between them - rock, which is a hole in the
 * light, and cloud, which is the opposite. The upper atmosphere has a third, and
 * it is the reason act III looks like nowhere else: **ice**. Everything solid
 * above the tropopause is a crystal, and a crystal is neither of the other two.
 * It does not scatter light the way vapour does and it does not block it the way
 * stone does - it *refracts*, which means a hard bright edge on one side, a dark
 * body, and a second bright edge where the light comes out again.
 *
 * So `jag` collapses across this table. Cloud runs at 0.10-0.13 because a cumulus
 * is lumps; ice runs at 0.02-0.06 because a crystal is flat planes, and the
 * silhouette difference between "wandering" and "faceted" is the single clearest
 * signal that the carrier is no longer flying through weather.
 *
 * `daylight` keeps falling and reaches zero at the Karman line, where there is
 * nothing overhead to be lit by. Below it, `sheen` does the opposite of what it
 * did in act II: it *rises* toward the top, because the less sky there is the
 * more of what light remains lands directly on the ice instead of being scattered
 * out of it first.
 */
const THIN_SPECS: MotifSpec[] = [
  {
    key: 'jet',
    verts: 18,
    vertsSmall: 12,
    // The last cloud with any softness in it: cirrus at the tropopause is ice
    // already, but ice being *dragged* at two hundred knots, so it streaks.
    jag: 0.06,
    crest: '#ffffff',
    base: '#9dbfe2',
    accent: '#cfe6ff',
    material: 'ice',
    fringe: 'none',
    strata: 0,
    sheen: 1.15,
    daylight: 0.8,
    backdrop: 'jet',
    wash: '#1d3f74',
    washAmount: 0.2,
  },
  {
    key: 'ozone',
    verts: 16,
    vertsSmall: 11,
    jag: 0.04,
    crest: '#e8f4ff',
    base: '#6f93c4',
    accent: '#a9d0ff',
    material: 'ice',
    fringe: 'none',
    strata: 0,
    sheen: 1.2,
    daylight: 0.6,
    backdrop: 'ozone',
    wash: '#123061',
    washAmount: 0.22,
  },
  {
    key: 'nacre',
    verts: 20,
    vertsSmall: 13,
    // A nacreous cloud is a thin, drawn-out lens rather than a pile - it is a
    // wave in the stratosphere made visible, and waves are smooth.
    jag: 0.05,
    // Mother-of-pearl: the iridescence is real and comes from ice crystals all
    // the same size diffracting a low sun. Rose on the lit edge, green in the
    // body, and it has to stay quiet or the station becomes a poster.
    crest: '#ffd6e4',
    base: '#8f86bd',
    accent: '#b8f0d8',
    material: 'ice',
    fringe: 'none',
    strata: 0,
    sheen: 1.05,
    daylight: 0.4,
    backdrop: 'nacre',
    wash: '#3b3364',
    washAmount: 0.22,
  },
  {
    key: 'blacksky',
    verts: 14,
    vertsSmall: 10,
    // The hardest silhouette in the game. At 50 km a crystal has nothing around
    // it to soften an edge, so the edge is exactly what the geometry says it is.
    jag: 0.02,
    crest: '#dfe9ff',
    base: '#5d6a9a',
    accent: '#9fb4ff',
    material: 'ice',
    fringe: 'none',
    strata: 0,
    sheen: 1.3,
    daylight: 0.22,
    backdrop: 'blacksky',
    wash: '#141a3c',
    washAmount: 0.2,
  },
  {
    key: 'noctilucent',
    verts: 20,
    vertsSmall: 13,
    // Filaments and billows, not lumps: noctilucent cloud is combed into bands by
    // the wind at the mesopause, which is most of why it looks like nothing else.
    jag: 0.04,
    // The one mass in the campaign that is brighter than every light source
    // around it. Electric blue, because eighty kilometres up the ice is still in
    // sunlight and everything else in the frame is not.
    crest: '#dcf4ff',
    base: '#4ea3d8',
    accent: '#9fe4ff',
    material: 'ice',
    fringe: 'none',
    strata: 0,
    sheen: 1.35,
    // No daylight at all: the light on this cloud comes from under the horizon.
    daylight: 0.14,
    backdrop: 'noctilucent',
    wash: '#0d2c4e',
    washAmount: 0.2,
  },
  {
    key: 'line',
    verts: 12,
    vertsSmall: 9,
    // A hundred kilometres up there is no weather and no cloud. What is left is
    // dust with ice frozen onto it, and it is as hard-edged as this game gets.
    jag: 0.015,
    crest: '#b9d6f2',
    base: '#2f4d76',
    accent: '#7fb0e2',
    material: 'ice',
    fringe: 'none',
    strata: 0,
    sheen: 1.4,
    // Zero. There is no sky here to light anything with.
    daylight: 0,
    backdrop: 'line',
    wash: '#061224',
    washAmount: 0.16,
  },
];

export const THIN_MOTIFS: Motif[] = THIN_SPECS.map(toMotif);

/**
 * Slowblue: act IV's six, and the campaign's one *manufactured* material.
 *
 * Three acts of weather and stone, and then this: everything solid in orbit is
 * wreckage. Nothing up here was worn by water, packed by wind or grown by
 * freezing, so it keeps whatever edge it broke with - `jag` is the lowest in the
 * campaign and `verts` the fewest, because a hulk is a few flat panels and not an
 * outline that wanders.
 *
 * What actually carries these six is the **light**, and it does something no act
 * below could. There is no sky here, so there is no fill light: a body in vacuum
 * is lit by one source on one side and by *nothing at all* on the other. That is
 * what `daylight: 0` means everywhere in this table, and it is why the umbra
 * works - inside the Earth's shadow the sun is gone too, and the only light left
 * in the frame is the gold the player has been carrying since the trench floor.
 * `sheen` is the whole act's arc in one number: it collapses into the shadow and
 * comes back for the turn.
 */
const SPACE_SPECS: MotifSpec[] = [
  {
    key: 'freefall',
    verts: 11,
    vertsSmall: 8,
    jag: 0.05,
    crest: '#cfe0ff',
    base: '#28344a',
    accent: '#ffd98a',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 1.2,
    daylight: 0,
    backdrop: 'freefall',
    wash: '#050b1c',
    washAmount: 0.16,
  },
  {
    key: 'aurora',
    verts: 11,
    vertsSmall: 8,
    jag: 0.045,
    // The one green in the campaign, and it is on the *obstacles* rather than in
    // the sky: an auroral curtain is emitting, so what is in it glows.
    crest: '#b6ffd8',
    base: '#1d4a3a',
    accent: '#7bffc0',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 1.3,
    daylight: 0,
    backdrop: 'aurora',
    wash: '#063020',
    washAmount: 0.2,
  },
  {
    key: 'umbra',
    verts: 10,
    vertsSmall: 7,
    jag: 0.04,
    // Lit by the swarm and by nothing else, so the crest is the *gold's* colour
    // rather than the sun's, and the body is as near black as the game goes.
    crest: '#ffdca0',
    base: '#0a0d16',
    accent: '#ffc878',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    // The lowest sheen in the campaign. There is nothing here to be lit by.
    sheen: 0.5,
    daylight: 0,
    backdrop: 'umbra',
    wash: '#01020a',
    washAmount: 0.12,
  },
  {
    key: 'debris',
    verts: 9,
    vertsSmall: 7,
    // The hardest silhouette in the game. A panel that sheared off something is a
    // straight line, and this is as close to one as circles get.
    jag: 0.03,
    crest: '#dde4f2',
    base: '#4a5162',
    accent: '#b9c4da',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 1.35,
    daylight: 0,
    backdrop: 'debris',
    wash: '#0b1020',
    washAmount: 0.16,
  },
  {
    key: 'well',
    verts: 10,
    vertsSmall: 7,
    jag: 0.04,
    crest: '#e0c2ff',
    base: '#33224a',
    accent: '#c8a6e6',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 1.15,
    daylight: 0,
    backdrop: 'well',
    wash: '#1a0c26',
    washAmount: 0.2,
  },
  {
    key: 'overview',
    verts: 11,
    vertsSmall: 8,
    jag: 0.045,
    // Earthlight. Coming back round the planet's day side, the fill light is the
    // planet - which is the one moment in the campaign where the world lights the
    // thing looking at it, and the reason this is the only warm-blue in the act.
    crest: '#d8ecff',
    base: '#274866',
    accent: '#bfe0ff',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 1.4,
    daylight: 0,
    backdrop: 'overview',
    wash: '#0d2444',
    washAmount: 0.2,
  },
];

export const SPACE_MOTIFS: Motif[] = SPACE_SPECS.map(toMotif);

/**
 * Slowblue: act V's six, and the only table in the campaign that gets *hotter*.
 *
 * Everything has been cooling and emptying for four acts. This is where that
 * reverses, violently: the air comes back at eight kilometres a second and what
 * it does to the carried gold is turn it into a meteor. So `sheen` climbs to the
 * highest value in the game at the plasma and then falls away, and the materials
 * change under it - wreckage at the top, `cloud` at the bottom, and the two
 * stations in between are the transformation itself.
 *
 * The act has no material of its own for the same reason it has no alphabet of
 * its own: it *is* the handover. Plasma is drawn as cloud that is emitting rather
 * than reflecting, which is what plasma is, and `daylight` climbing back from 0 to
 * 1 across the six is the sky returning - the exact number act III spent six
 * stations spending.
 */
const REENTRY_SPECS: MotifSpec[] = [
  {
    key: 'deorbit',
    verts: 11,
    vertsSmall: 8,
    jag: 0.045,
    crest: '#cfe0ff',
    base: '#2b3a52',
    accent: '#ffd08a',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 1.25,
    daylight: 0,
    backdrop: 'deorbit',
    wash: '#071429',
    washAmount: 0.16,
  },
  {
    key: 'nightside',
    verts: 10,
    vertsSmall: 7,
    jag: 0.04,
    crest: '#ffe0a8',
    base: '#141c2c',
    accent: '#ffc888',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 0.7,
    daylight: 0,
    backdrop: 'nightside',
    wash: '#030a14',
    washAmount: 0.14,
  },
  {
    key: 'auroraBelow',
    verts: 12,
    vertsSmall: 9,
    jag: 0.05,
    // Inside the curtain rather than above it, so the green is on everything.
    crest: '#c8ffe4',
    base: '#1f5c48',
    accent: '#8dffcc',
    material: 'wreck',
    fringe: 'none',
    strata: 0,
    sheen: 1.3,
    daylight: 0.15,
    backdrop: 'auroraBelow',
    wash: '#083a26',
    washAmount: 0.2,
  },
  {
    key: 'plasma',
    verts: 15,
    vertsSmall: 11,
    // Softening: a shock front is a surface of gas, not a fractured panel. This is
    // the frame where the campaign's edges stop being hard for good.
    jag: 0.09,
    crest: '#fffbe8',
    base: '#c25a1e',
    accent: '#ffd9a0',
    // Cloud, not wreckage: plasma is air, and the one thing that makes it read as
    // fire rather than as weather is that it is *emitting*, which is `sheen`.
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    // The brightest thing in the campaign. Everything here is its own light source.
    sheen: 1.6,
    daylight: 0.5,
    backdrop: 'plasma',
    wash: '#7a2408',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'meteordust',
    verts: 16,
    vertsSmall: 11,
    jag: 0.11,
    crest: '#ffe4c0',
    base: '#7a5a5e',
    accent: '#ffc9a0',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 1.15,
    daylight: 0.7,
    backdrop: 'meteordust',
    wash: '#4a3038',
    washAmount: 0.24,
  },
  {
    key: 'nucleus',
    verts: 18,
    vertsSmall: 12,
    // Fully cloud again, at act II's own jag: the player is back in weather, and
    // the silhouettes say so before the palette does.
    jag: 0.12,
    crest: '#f4f8fb',
    base: '#9aa8b4',
    accent: '#d6e8f8',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 1,
    daylight: 0.9,
    backdrop: 'nucleus',
    wash: '#5e6c78',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
];

export const REENTRY_MOTIFS: Motif[] = REENTRY_SPECS.map(toMotif);

/**
 * Slowblue: act VI's six, and the campaign's first *living* material.
 *
 * The arc here is the one the whole descent is for: cloud, then water, then wood
 * and leaf, then stone under running water. `daylight` climbs back to 1 for the
 * first time since the anvil, and then starts to fall again at the estuary -
 * because the last two acts are going back under the sea, and the light has to
 * start leaving before the player notices it is leaving.
 *
 * `jag` climbs the whole way. Vacuum was 0.03 and a forest is the raggedest thing
 * in the game: nothing here was made or eroded, it *grew*, and growth is the one
 * process that does not smooth anything.
 */
const RAIN_SPECS: MotifSpec[] = [
  {
    key: 'cirrus',
    verts: 18,
    vertsSmall: 12,
    jag: 0.06,
    crest: '#ffffff',
    base: '#9dbfe2',
    accent: '#dceaf6',
    material: 'ice',
    fringe: 'none',
    strata: 0,
    sheen: 1.1,
    daylight: 0.85,
    backdrop: 'cirrusFall',
    wash: '#4a6f96',
    washAmount: 0.2,
  },
  {
    key: 'underanvil',
    verts: 18,
    vertsSmall: 12,
    // Act II's anvil jag exactly, because it is act II's anvil.
    jag: 0.07,
    crest: '#f2f8fc',
    base: '#8e99a6',
    accent: '#c6dcf0',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    // Underneath a storm rather than on top of one, so the light is coming
    // through it rather than landing on it: the same cloud, half as bright.
    sheen: 0.72,
    daylight: 0.6,
    backdrop: 'underanvil',
    wash: '#5a6674',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'downpour',
    verts: 17,
    vertsSmall: 12,
    jag: 0.1,
    crest: '#eaf6ff',
    base: '#79899a',
    accent: '#b4d6f4',
    material: 'cloud',
    fringe: 'none',
    strata: 0,
    sheen: 0.8,
    daylight: 0.7,
    backdrop: 'downpour',
    wash: '#546472',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'canopy',
    verts: 22,
    vertsSmall: 14,
    // The raggedest silhouette in the campaign. A tree is not a shape, it is a
    // few thousand leaves, and the outline has to say so.
    jag: 0.17,
    crest: '#9ecb7a',
    base: '#2e3c26',
    accent: '#d8f0dc',
    // Living wood and leaf. It takes `crust`'s rules - a body with things growing
    // on it - which is the closest the existing material set gets, and the only
    // place in the campaign where that is a description rather than a compromise.
    material: 'crust',
    fringe: 'coral',
    strata: 1,
    sheen: 1.05,
    daylight: 1,
    backdrop: 'canopyFall',
    wash: '#41563a',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'brook',
    verts: 15,
    vertsSmall: 11,
    // Stone worn by fast water: smoother than the trench's obsidian and rounder
    // than anything since act I, because that is what a river does to rock.
    jag: 0.035,
    crest: '#8fb6ac',
    base: '#33413f',
    accent: '#ccf4ee',
    material: 'scoured',
    fringe: 'weed',
    strata: 3,
    sheen: 1.2,
    daylight: 1,
    backdrop: 'brook',
    wash: '#3d6f6e',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'estuary',
    verts: 16,
    vertsSmall: 11,
    jag: 0.05,
    crest: '#5d9aa4',
    base: '#22383c',
    accent: '#c4eff4',
    material: 'furred',
    fringe: 'kelp',
    strata: 2,
    sheen: 1.05,
    // The light beginning to leave again, and it is the first sign anywhere that
    // the campaign is going back under.
    daylight: 0.8,
    backdrop: 'estuary',
    wash: '#256271',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
];

export const RAIN_MOTIFS: Motif[] = RAIN_SPECS.map(toMotif);

/**
 * Slowblue: act VII's six, and the campaign closing its own circle.
 *
 * The table runs act I's materials backwards - and it **stops being made of
 * rock two stations in**, which is the act's whole subject arriving in the
 * paint. The salt line still has stone in it, because an estuary mouth does.
 * From the sunlit zone down there is nothing hard in the water at all: the two
 * stations that still carry an obstacle carry `medusa`, and the three below them
 * carry nothing to paint. What the reversal is *for* is the last entry, which is
 * deliberately within a few values of the first entry in `MOTIFS` - the last
 * frame of the campaign and the first frame of it are supposed to be the same
 * picture, and that is the only place the symmetry has to be exact.
 *
 * What is different is what is *lighting* them. Act I's rock is lit from above by
 * a surface six thousand metres away, so `sheen` falls with depth. Act VII's is
 * lit from *inside* by what the player is carrying, so `accent` stays warm all
 * the way down and `sheen` barely falls at all - the deeper the swarm goes, the
 * more of the light in the frame is its own.
 */
const HOME_SPECS: MotifSpec[] = [
  {
    key: 'brackish',
    verts: 16,
    vertsSmall: 11,
    jag: 0.05,
    crest: '#6fb4bd',
    base: '#0d2b34',
    accent: '#ffe0a8',
    material: 'furred',
    fringe: 'kelp',
    strata: 2,
    sheen: 1.1,
    daylight: 0.4,
    backdrop: 'brackish',
    wash: '#1a5f74',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'sunlit',
    // Rounder than anything else in the game, and barely wandering off the
    // circle: a bell is a dome, and the jag that makes stone look worn makes a
    // medusa look chewed.
    verts: 19,
    vertsSmall: 14,
    jag: 0.015,
    crest: '#cfe9ee',
    base: '#0d3a48',
    accent: '#ffe4a8',
    material: 'medusa',
    fringe: 'none',
    strata: 0,
    sheen: 1.25,
    // Daylight, on a body that is mostly water: the sunlit zone is the one place
    // in act VII where the light is still coming from outside the swarm.
    daylight: 0.55,
    backdrop: 'sunlitFall',
    wash: '#0a6c80',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'twilight',
    verts: 18,
    vertsSmall: 13,
    jag: 0.018,
    crest: '#9fd3cf',
    base: '#06212a',
    accent: '#ffd892',
    material: 'medusa',
    fringe: 'none',
    strata: 0,
    sheen: 1,
    // The light has gone from above, so what is left lighting these is the gold
    // inside them - which is also what is inside the swarm.
    daylight: 0.14,
    backdrop: 'twilightFall',
    wash: '#053241',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'midnightHome',
    verts: 16,
    vertsSmall: 12,
    jag: 0.03,
    crest: '#41558f',
    base: '#040816',
    accent: '#ffce8c',
    material: 'basalt',
    fringe: 'none',
    strata: 2,
    // Lit by the swarm rather than by the surface, so it does not collapse the
    // way act I's basalt did at the same depth.
    sheen: 0.72,
    daylight: 0,
    backdrop: 'deepsea',
    wash: '#050d28',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'snow',
    verts: 15,
    vertsSmall: 11,
    jag: 0.03,
    crest: '#8f6bc4',
    base: '#050110',
    accent: '#ffca8c',
    material: 'basalt',
    fringe: 'none',
    strata: 1,
    sheen: 0.8,
    daylight: 0,
    backdrop: 'snow',
    wash: '#08061c',
    // The zone's own mid: no tint to apply, so none is charged for. See `washAmount`.
    washAmount: 0,
  },
  {
    key: 'trenchHome',
    verts: 15,
    vertsSmall: 11,
    // Act I's trench floor, digit for digit - the same fifteen vertices and the
    // same 0.028 wander. This is the same rock.
    jag: 0.028,
    crest: '#6b4699',
    base: '#150a2b',
    accent: '#ff8a4c',
    material: 'obsidian',
    fringe: 'vein',
    strata: 1,
    // A little brighter than act I's 0.55: the vents are the same, and what has
    // changed is that the player brought a light with them.
    sheen: 0.7,
    daylight: 0,
    backdrop: 'trenchHome',
    wash: '#2a0f3f',
    washAmount: 0.24,
  },
];

export const HOME_MOTIFS: Motif[] = HOME_SPECS.map(toMotif);

/**
 * The motif table an act dresses its levels with. Positional, like the water
 * table always was - motif i dresses level i of that act.
 */
const ACT_MOTIFS: Record<string, Motif[]> = {
  water: MOTIFS,
  air: AIR_MOTIFS,
  thin: THIN_MOTIFS,
  orbit: SPACE_MOTIFS,
  reentry: REENTRY_MOTIFS,
  rain: RAIN_MOTIFS,
  home: HOME_MOTIFS,
};

export function motifsForAct(actKey: string): Motif[] {
  return ACT_MOTIFS[actKey] ?? MOTIFS;
}

export function motifForIn(actKey: string, levelIndex: number): Motif {
  const table = motifsForAct(actKey);
  return table[Math.max(0, Math.min(table.length - 1, levelIndex))]!;
}

if (import.meta.env.DEV) {
  // The tables are positional: motif i dresses level i. A level added without a
  // motif would silently inherit the trench's, which is the kind of bug that
  // survives to a screenshot. With seven acts this is checked for all of them at
  // once rather than act by act, so adding the eighth cannot forget to add a check.
  for (const [actKey, levels] of Object.entries(ACT_LEVELS)) {
    const table = motifsForAct(actKey);
    for (let i = 0; i < levels.length; i++) {
      if (table[i]?.key !== levels[i]!.key) {
        throw new Error(`${actKey} motif ${i} does not match level ${levels[i]!.key}`);
      }
    }
  }
}

export function motifFor(levelIndex: number): Motif {
  return MOTIFS[Math.max(0, Math.min(MOTIFS.length - 1, levelIndex))]!;
}

/**
 * Sections built by the seeded generator (the sweeps, and anything past the end of
 * the campaign) carry no level, so they borrow the motif of the level that owns
 * their progression zone.
 */
const ZONE_MOTIF = [0, 2, 3, 5];

/**
 * Slowblue: act-aware on purpose, and it was a bug that it ever was not. This used to
 * index the water table unconditionally, so every mass in act II was painted as
 * the water level with the same index - a cloud-belt gate arrived as a slab of
 * scoured midnight basalt hanging in the sky. The `material: 'cloud'` path in
 * `RockPaint` existed and was simply never reached by a real frame.
 */
export function motifForSection(actKey: string, level: number, zone: number): Motif {
  if (level >= 0) return motifForIn(actKey, level);
  return motifFor(ZONE_MOTIF[Math.max(0, Math.min(ZONE_MOTIF.length - 1, zone))]!);
}
