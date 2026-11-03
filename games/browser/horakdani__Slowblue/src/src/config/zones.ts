/**
 * Every course piece the generator can produce.
 * `gate` / `rock` / `narrows` are the original three; the rest arrive with progress.
 */
export type SectionKind = 'gate' | 'rock' | 'narrows' | 'drift' | 'vortex' | 'predator';

export interface Palette {
  /** Vertical background gradient, surface -> behind you. */
  top: string;
  mid: string;
  bottom: string;
  shoal: string;
  shoalGlow: string;
  pod: string;
  rock: string;
  rockRim: string;
  /** Tracer colour as an RGB triple, so alpha can be computed per streak. */
  tracer: [number, number, number];
  speck: string;
  /** Multiplies the drifting speck density; the deep is emptier. */
  speckDensity: number;
}

export interface Zone {
  index: number;
  key: string;
  name: string;
  /** First section id that belongs to this zone. */
  fromSection: number;
  /** Section kinds, cycled in order. The cycle *is* the zone's rhythm. */
  pool: SectionKind[];
  palette: Palette;
}

/**
 * A zone before it knows where it sits in the list.
 *
 * Slowblue: `Zone.index` has to equal the zone's position in `ALL_ZONES`, because
 * `Level.zone` is that position and `paintFor` indexes straight into the parsed
 * paint table with it. With four zones that was a fact you could hold in your
 * head. With forty across seven acts it is a fact that gets quietly broken by
 * anyone inserting a station, and the symptom is an act painted in another act's
 * colours - which looks like an art bug and is a bookkeeping one. So indices are
 * *stamped* below and never written by hand.
 */
interface ZoneSpec {
  key: string;
  name: string;
  /** Water only: the first generated section id this band owns. */
  fromSection?: number;
  /** Water only: what the generator may build here. */
  pool?: SectionKind[];
  palette: Palette;
}

/**
 * What a zone outside act I answers when the *generator* asks what it can build.
 *
 * Nothing, in practice: `zoneForSection` walks `ZONES` alone, because that
 * function answers "what can the generator build at this depth" and the
 * generator only ever builds water. Every band past act I is authored.
 */
const AUTHORED_ONLY: SectionKind[] = ['gate', 'rock', 'narrows'];

function stamp(specs: ZoneSpec[], from: number): Zone[] {
  return specs.map((s, i) => ({
    index: from + i,
    key: s.key,
    name: s.name,
    fromSection: s.fromSection ?? Number.MAX_SAFE_INTEGER,
    pool: s.pool ?? AUTHORED_ONLY,
    palette: s.palette,
  }));
}

/**
 * Slowblue: zones are bands of the campaign.
 *
 * Act I's four rise with progress and their light rises with them: violet-black
 * hadal water gives way to midnight blue, then living cyan, then the bright
 * surface. The first zone is deliberately a fixed gate -> rock -> narrows cycle:
 * it is the tutorial, and a tutorial must not shuffle.
 */
const WATER_SPECS: ZoneSpec[] = [
  {
    key: 'hadal',
    name: 'The Hadal Zone',
    fromSection: 0,
    pool: ['gate', 'rock', 'narrows'],
    palette: {
      top: '#170d34',
      mid: '#09061d',
      bottom: '#010108',
      shoal: '#f0e7ff',
      shoalGlow: 'rgba(189,132,255,0.15)',
      pod: '255,174,126',
      rock: '#05010e',
      rockRim: '#34205a',
      tracer: [203, 172, 255],
      speck: '#ddccff',
      speckDensity: 0.38,
    },
  },
  {
    key: 'midnight',
    name: 'The Midnight Zone',
    fromSection: 4,
    pool: ['drift', 'rock', 'gate', 'vortex', 'rock', 'narrows'],
    palette: {
      top: '#0a2353',
      mid: '#050f2d',
      bottom: '#010511',
      shoal: '#e2efff',
      shoalGlow: 'rgba(114,173,255,0.14)',
      pod: '255,188,116',
      rock: '#04091b',
      rockRim: '#1d356f',
      tracer: [150, 193, 255],
      speck: '#c8dcff',
      speckDensity: 0.56,
    },
  },
  {
    key: 'blue',
    name: 'The Blue Zone',
    fromSection: 9,
    pool: ['predator', 'rock', 'narrows', 'vortex', 'drift', 'rock', 'gate', 'predator'],
    palette: {
      top: '#086174',
      mid: '#043644',
      bottom: '#011722',
      shoal: '#ddfff8',
      shoalGlow: 'rgba(84,239,220,0.14)',
      pod: '255,207,124',
      rock: '#04191f',
      rockRim: '#14606a',
      tracer: [139, 239, 226],
      speck: '#b9f6eb',
      speckDensity: 0.82,
    },
  },
  {
    key: 'surface',
    name: 'The Sunlit Zone',
    fromSection: 16,
    pool: ['vortex', 'rock', 'predator', 'narrows', 'drift', 'rock', 'predator', 'vortex'],
    palette: {
      top: '#21a7bc',
      mid: '#0a7185',
      bottom: '#03334b',
      shoal: '#efffff',
      shoalGlow: 'rgba(151,245,255,0.16)',
      pod: '255,222,142',
      rock: '#082632',
      rockRim: '#327f91',
      tracer: [190, 244, 255],
      speck: '#dcfbff',
      speckDensity: 1.08,
    },
  },
];

/**
 * Slowblue: the air's bands, and the two things that make them read instantly.
 *
 * **The gradient is upside down.** In water `top` is the direction of the
 * surface, so the palette gets *lighter* ahead of you and darker behind. Above
 * the waves that flips: ahead is up, up is thinner, and thinner is darker. Every
 * air palette from the cliffs onward therefore has its dark end at the top and
 * its haze at the bottom, which is why a single frame of act II can never be
 * mistaken for act I even at a thumbnail. The spray is the one exception and it
 * is not an inconsistency - at sixty metres the dark thing in the frame really is
 * the sea underneath you.
 *
 * **They go out on the way up, and that is physics rather than mood.** Sky is
 * blue because there is air overhead to scatter sunlight in it, and there is
 * monotonically less of it the higher you go. `tests/zones.test.ts` asserts the
 * monotonicity across the whole climb, because "the ascent gets darker" is a
 * claim about numbers and can be checked instead of believed.
 *
 * **The flock changes sides halfway up, and that is the same fact again.** A bird
 * seen against a bright sky is a dark shape - that is what the word silhouette
 * means. So `shoal` is *dark* for the stations flown under daylight and *pale*
 * for the ones flown above the weather, where the sky is going out and the birds
 * are the only thing the sun is still fully on. The flip happens coming out of
 * the top of the squall, it crossfades with everything else in the palette, and
 * it is the clearest single statement the colour makes: below the weather you
 * watch the flock against the light, above it the flock *is* the light.
 */
const AIR_SPECS: ZoneSpec[] = [
  {
    key: 'spray',
    name: 'The Spray',
    palette: {
      // Sea-level light, and the brightest frame in the game: a pale morning sky
      // above, and the sea they just came out of catching all of it underneath.
      top: '#c6dfee',
      mid: '#a8cee2',
      bottom: '#3d6c88',
      shoal: '#22384a',
      shoalGlow: 'rgba(40,64,86,0.16)',
      pod: '150,92,38',
      rock: '#dceaf4',
      rockRim: '#ffffff',
      tracer: [226, 243, 255],
      speck: '#ffffff',
      speckDensity: 1.15,
    },
  },
  {
    key: 'cliff',
    name: 'The Cliff',
    palette: {
      // A few hundred metres, and the first frame in the game with land in it.
      // The inversion has begun - the sky above is already deeper than the haze
      // over the water - but only just, because at this height it has barely
      // started to be true.
      top: '#467bab',
      mid: '#8ab5d3',
      bottom: '#c6dcea',
      shoal: '#233b52',
      shoalGlow: 'rgba(38,62,86,0.16)',
      pod: '154,94,38',
      rock: '#d4e3ee',
      rockRim: '#ffffff',
      tracer: [236, 246, 255],
      speck: '#ffffff',
      speckDensity: 1.1,
    },
  },
  {
    key: 'cumulus',
    name: 'The Cumulus Field',
    palette: {
      top: '#3d75ad',
      mid: '#79aacf',
      bottom: '#c3dcec',
      shoal: '#26405a',
      shoalGlow: 'rgba(44,70,96,0.15)',
      pod: '160,98,40',
      rock: '#c9d8e4',
      rockRim: '#ffffff',
      tracer: [255, 255, 255],
      speck: '#ffffff',
      speckDensity: 0.95,
    },
  },
  {
    key: 'passage',
    name: 'The Passage',
    palette: {
      // Two and a half kilometres: the altitude birds actually migrate at, and
      // the last one in the game where the air is something a body can live in.
      // The blue has gone hard and the haze below it is thinning out.
      top: '#2a5488',
      mid: '#5f8fbc',
      bottom: '#a8c4da',
      shoal: '#1d3149',
      shoalGlow: 'rgba(36,58,82,0.15)',
      pod: '150,92,38',
      rock: '#bfd2e2',
      rockRim: '#f4fbff',
      tracer: [246, 251, 255],
      speck: '#f2f8ff',
      speckDensity: 1.02,
    },
  },
  {
    key: 'squall',
    name: 'The Squall',
    palette: {
      // The one bruised palette in the game. Cloud stays the bright thing in it -
      // a storm is dark because of what is *between* you and the light, and the
      // vapour you are flying through still has the light on top of it.
      top: '#313d4e',
      mid: '#4d5b6d',
      bottom: '#7e8b9b',
      // The tightest contrast in the act: a dark flock against a dark sky. The
      // sky is lifted a little and the flock pushed down until they clear 3:1,
      // because this is the one station where a silhouette could get lost.
      shoal: '#16202c',
      shoalGlow: 'rgba(32,44,60,0.15)',
      rock: '#8f9dae',
      rockRim: '#d5dfea',
      pod: '138,84,34',
      tracer: [206, 222, 245],
      speck: '#e8eefc',
      speckDensity: 1.3,
    },
  },
  {
    key: 'anvil',
    name: 'The Anvil',
    palette: {
      // Out of the top of the weather. The frame's dark end is nearly space
      // already; its bright end is the anvil sheet you climbed through, receding.
      //
      // This is the one station where the monotone darkening and the local truth
      // pull against each other: a squall is a dark place to be, and coming out
      // of the top of one *feels* like arriving in the light. The ascent's
      // argument wins, and it wins honestly - at 11 km the sky overhead really is
      // several stops darker than anything at 4 km, and the bright thing here is
      // below you and getting further away.
      top: '#0b1440',
      mid: '#21406f',
      bottom: '#8aa5c6',
      shoal: '#eef4ff',
      shoalGlow: 'rgba(226,238,255,0.2)',
      pod: '255,226,170',
      rock: '#cfdcee',
      rockRim: '#ffffff',
      tracer: [236, 246, 255],
      speck: '#ffffff',
      speckDensity: 0.6,
    },
  },
];

/**
 * Slowblue: act III, the upper atmosphere, and the last light going out.
 *
 * Six bands from the top of the weather to the Karman line, and they finish the
 * argument the air's six started: there is less and less overhead to scatter
 * anything in, so the sky stops being a colour and becomes an absence. The last
 * of them is very nearly pure black, and it has to be - a hundred kilometres up
 * there is no sky at all, and the game has spent two acts earning the right to
 * show that rather than assert it.
 *
 * `rock` is the obstacle colour, and up here obstacles are ice. It stays the
 * brightest entry in every one of these palettes, which is literally true: at
 * these altitudes the only thing left in sunlight is the crystal.
 */
const THIN_SPECS: ZoneSpec[] = [
  {
    key: 'jet',
    name: 'The Jet Stream',
    palette: {
      // 11 km. The tropopause, and the fastest air on the planet. There is still
      // a haze below - it is the whole troposphere, seen from its ceiling.
      top: '#060d2e',
      mid: '#16305c',
      bottom: '#6d8cb4',
      shoal: '#fff3cf',
      shoalGlow: 'rgba(255,226,150,0.22)',
      pod: '255,222,150',
      rock: '#bcd6ef',
      rockRim: '#ffffff',
      tracer: [190, 220, 255],
      speck: '#e8f2ff',
      speckDensity: 0.55,
    },
  },
  {
    key: 'ozone',
    name: 'Ozone Blue',
    palette: {
      // 20 km. Ozone absorbs in the red, so the little light that scatters here
      // comes back bluer than anywhere below - the deepest blue in the game, and
      // the last one that is a blue rather than a black with blue in it.
      top: '#04081f',
      mid: '#0e2350',
      bottom: '#4d6f9e',
      shoal: '#ffeec4',
      shoalGlow: 'rgba(255,220,140,0.22)',
      pod: '255,216,140',
      rock: '#a9c8e8',
      rockRim: '#f2f9ff',
      tracer: [160, 200, 250],
      speck: '#d8e8ff',
      speckDensity: 0.45,
    },
  },
  {
    key: 'nacre',
    name: 'The Nacreous',
    palette: {
      // 25 km. The sky is black overhead in daylight, and the only warm colour
      // left in the world is under the horizon - which is what lights the cloud.
      top: '#05070f',
      mid: '#111a3c',
      bottom: '#4a4270',
      shoal: '#fff0d2',
      shoalGlow: 'rgba(255,214,160,0.22)',
      pod: '255,214,198',
      rock: '#a795c6',
      rockRim: '#ffe4f0',
      tracer: [198, 186, 235],
      speck: '#e7dcff',
      speckDensity: 0.4,
    },
  },
  {
    key: 'blacksky',
    name: 'The Black Sky',
    palette: {
      // 50 km. Nothing scatters. The frame is stars, the swarm, and whatever ice
      // the swarm is passing - and the only reason it is not literally black is
      // that a completely black frame stops reading as a place.
      top: '#02030a',
      mid: '#070c22',
      bottom: '#221f45',
      shoal: '#ffeec8',
      shoalGlow: 'rgba(255,212,140,0.24)',
      pod: '255,220,160',
      rock: '#8f9fc8',
      rockRim: '#dfe9ff',
      tracer: [140, 156, 205],
      speck: '#cdd8ff',
      speckDensity: 0.3,
    },
  },
  {
    key: 'noctilucent',
    name: 'The Noctilucent',
    palette: {
      // 82 km, and the last cloud there is: ice on meteor dust, glowing electric
      // blue against a black sky because the sun is still on it hours after it
      // has gone from everything else.
      top: '#01020a',
      mid: '#030818',
      bottom: '#0a2440',
      shoal: '#ffeec0',
      shoalGlow: 'rgba(255,214,140,0.24)',
      pod: '255,232,190',
      rock: '#79c4f2',
      rockRim: '#e6f7ff',
      tracer: [168, 214, 255],
      speck: '#dff1ff',
      speckDensity: 0.26,
    },
  },
  {
    key: 'line',
    name: 'The Line',
    palette: {
      // 100 km. The Karman line is not a place - it is where the air stops being
      // able to hold anything up, which is exactly the sentence act III has been
      // making. The darkest palette in the campaign, and the last one with any
      // atmosphere in it at all.
      top: '#000105',
      mid: '#01030c',
      bottom: '#04101f',
      shoal: '#ffeeba',
      shoalGlow: 'rgba(255,208,120,0.26)',
      pod: '255,226,170',
      rock: '#4a7fb4',
      rockRim: '#c3ddf5',
      tracer: [120, 168, 220],
      speck: '#c7dcf5',
      speckDensity: 0.2,
    },
  },
];

/**
 * Slowblue: act IV, and the only palettes in the game with no sky in them.
 *
 * Every band below this one is a colour the *air* is. There is no air here, so
 * these are the colours of the things in the frame instead: the gold the player
 * has been carrying since the trench floor, the green of an aurora seen from
 * above it, the total black of the Earth's own shadow, and finally the planet.
 *
 * The gold does most of the work. It is the campaign's one continuous motif, and
 * this is the act where it is the *only* thing on screen - so `shoal` and `pod`
 * are the same warm light in all six bands, and the sky behind them changes from
 * nothing to nothing.
 */
const SPACE_SPECS: ZoneSpec[] = [
  {
    key: 'freefall',
    name: 'Free Fall',
    palette: {
      top: '#000104',
      mid: '#01020a',
      bottom: '#040a1c',
      shoal: '#ffe9a8',
      shoalGlow: 'rgba(255,206,110,0.28)',
      pod: '255,222,150',
      rock: '#3a4d6b',
      rockRim: '#9db4d4',
      tracer: [110, 140, 190],
      speck: '#c2d4f0',
      speckDensity: 0.18,
    },
  },
  {
    key: 'aurora',
    name: 'The Aurora',
    palette: {
      // Seen from above, which almost nobody has: the curtains are *below* the
      // swarm and the green comes up off the bottom of the frame.
      top: '#000308',
      mid: '#02160e',
      bottom: '#0a4a2c',
      shoal: '#ffeeb4',
      shoalGlow: 'rgba(255,214,120,0.3)',
      pod: '255,226,160',
      rock: '#2f6f56',
      rockRim: '#8ff0bd',
      tracer: [120, 240, 180],
      speck: '#bdf5da',
      speckDensity: 0.3,
    },
  },
  {
    key: 'umbra',
    name: 'The Umbra',
    palette: {
      // The Earth's shadow, and the darkest frame in the game by a long way. The
      // swarm is the only light source; everything else is inferred from it.
      top: '#000002',
      mid: '#000105',
      bottom: '#01040d',
      shoal: '#ffe6a0',
      shoalGlow: 'rgba(255,198,96,0.34)',
      pod: '255,216,140',
      rock: '#1b2436',
      rockRim: '#4f627f',
      tracer: [70, 92, 130],
      speck: '#8ea4c6',
      speckDensity: 0.12,
    },
  },
  {
    key: 'debris',
    name: 'The Debris Belt',
    palette: {
      // Grey. The one band up here with anything man-made in it, and the one
      // whose obstacles are hard-edged rather than luminous.
      top: '#000105',
      mid: '#02040e',
      bottom: '#0a1020',
      shoal: '#ffeaac',
      shoalGlow: 'rgba(255,206,110,0.28)',
      pod: '255,220,150',
      rock: '#5c6478',
      rockRim: '#c3cbdc',
      tracer: [130, 143, 168],
      speck: '#b6bfd2',
      speckDensity: 0.22,
    },
  },
  {
    key: 'well',
    name: 'The Well',
    palette: {
      // The deepest part of the gravity field the act is played in, drawn as the
      // one warm thing in vacuum: the frame's bottom glows because that is where
      // everything is falling toward.
      top: '#010004',
      mid: '#0a0410',
      bottom: '#301638',
      shoal: '#fff0bc',
      shoalGlow: 'rgba(255,216,130,0.32)',
      pod: '255,228,170',
      rock: '#54406e',
      rockRim: '#c8a6e6',
      tracer: [176, 130, 220],
      speck: '#dcc4f5',
      speckDensity: 0.2,
    },
  },
  {
    key: 'overview',
    name: 'The Overview',
    palette: {
      // The turn. The whole planet arrives at the bottom of the frame and the
      // atmosphere resolves into one bright line along it - which is the entire
      // campaign so far, seen edge-on and a few pixels thick.
      top: '#000106',
      mid: '#020714',
      bottom: '#123055',
      shoal: '#fff2c8',
      shoalGlow: 'rgba(255,224,150,0.3)',
      pod: '255,232,180',
      rock: '#3f6f9e',
      rockRim: '#bfe0ff',
      tracer: [150, 196, 244],
      speck: '#d8ecff',
      speckDensity: 0.24,
    },
  },
];

/**
 * Slowblue: act V, and the only place in the game that is allowed to be hot.
 *
 * The campaign has been getting colder and emptier for four acts. This is where
 * that reverses, violently: the air comes back at eight kilometres a second, and
 * what it does to the carried gold is turn it into a meteor. The palettes go
 * black -> green -> white-hot -> orange -> grey, which is the temperature curve
 * of a real re-entry read straight off, and the last of them is the first cloud
 * of the way home.
 */
const REENTRY_SPECS: ZoneSpec[] = [
  {
    key: 'deorbit',
    name: 'The Deorbit',
    palette: {
      top: '#000106',
      mid: '#020612',
      bottom: '#0b1c33',
      shoal: '#ffeeb8',
      shoalGlow: 'rgba(255,214,130,0.28)',
      pod: '255,226,166',
      rock: '#3c5672',
      rockRim: '#a8c2e0',
      tracer: [130, 168, 214],
      speck: '#cbdcf2',
      speckDensity: 0.26,
    },
  },
  {
    key: 'nightside',
    name: 'The Night Side',
    palette: {
      // Coming down over the unlit half. The only light in the frame is the swarm
      // and, far below, weather lighting itself up from the inside.
      top: '#000004',
      mid: '#01030c',
      bottom: '#06121f',
      shoal: '#ffeaa8',
      shoalGlow: 'rgba(255,204,104,0.32)',
      pod: '255,218,150',
      rock: '#2a3850',
      rockRim: '#7d94b4',
      tracer: [96, 126, 168],
      speck: '#a8bcd8',
      speckDensity: 0.2,
    },
  },
  {
    key: 'auroraBelow',
    name: 'The Aurora',
    palette: {
      // Through the curtains rather than over them. This is the last calm band
      // before the air arrives, and it is the most beautiful thing in act V.
      top: '#00080a',
      mid: '#042418',
      bottom: '#0e5a38',
      shoal: '#fff0bc',
      shoalGlow: 'rgba(255,220,140,0.3)',
      pod: '255,230,170',
      rock: '#37806a',
      rockRim: '#9dfcd0',
      tracer: [130, 250, 190],
      speck: '#c6ffe4',
      speckDensity: 0.34,
    },
  },
  {
    key: 'plasma',
    name: 'The Plasma',
    palette: {
      // The loudest frame in the game. Everything is on fire and the sky behind
      // it has gone white, because at this point the swarm *is* the light source
      // and it is brighter than anything else can be.
      top: '#2a0a04',
      mid: '#7a2408',
      bottom: '#e8873a',
      shoal: '#fffbe8',
      shoalGlow: 'rgba(255,180,80,0.4)',
      pod: '255,244,214',
      rock: '#c25a1e',
      rockRim: '#ffd9a0',
      tracer: [255, 190, 120],
      speck: '#ffe6bc',
      speckDensity: 0.75,
    },
  },
  {
    key: 'meteordust',
    name: 'The Meteor Dust',
    palette: {
      // Cooling. The orange is going out of it and what is left is the dust that
      // every noctilucent cloud on the planet is built on - which is where act VI
      // starts, and is not a coincidence.
      top: '#140c18',
      mid: '#33202e',
      bottom: '#6b4a52',
      shoal: '#ffe4c0',
      shoalGlow: 'rgba(255,196,130,0.3)',
      pod: '255,214,168',
      rock: '#7a5a5e',
      rockRim: '#e2bfae',
      tracer: [222, 176, 156],
      speck: '#f0d8c8',
      speckDensity: 0.6,
    },
  },
  {
    key: 'nucleus',
    name: 'The Nucleus',
    palette: {
      // Cold, wet and grey: the dust has finished being a meteor and started
      // being the thing a raindrop condenses on. The whole of act VI is in this
      // palette in miniature.
      top: '#3a4652',
      mid: '#5e6c78',
      bottom: '#9aa8b4',
      shoal: '#f4f8fb',
      shoalGlow: 'rgba(214,232,248,0.24)',
      pod: '224,208,168',
      rock: '#b0bcc6',
      rockRim: '#e8f0f6',
      tracer: [212, 228, 242],
      speck: '#eef4fa',
      speckDensity: 0.9,
    },
  },
];

/**
 * Slowblue: act VI, and the first act that is played downward.
 *
 * The gradient turns over with it. For five acts `top` has been the direction of
 * travel; from here `bottom` is, so the palettes are built to get *deeper* toward
 * the bottom of the frame - which is where the sea is. The arc runs grey through
 * green: cloud, rain, forest, river, and the brackish colour of a river arriving.
 */
const RAIN_SPECS: ZoneSpec[] = [
  {
    key: 'cirrus',
    name: 'The Cirrus',
    palette: {
      top: '#2c4a6e',
      mid: '#6a89a8',
      bottom: '#c8d8e2',
      shoal: '#ffffff',
      shoalGlow: 'rgba(206,234,255,0.26)',
      pod: '206,190,150',
      rock: '#dceaf2',
      rockRim: '#ffffff',
      tracer: [226, 240, 250],
      speck: '#f4fbff',
      speckDensity: 0.7,
    },
  },
  {
    key: 'underanvil',
    name: 'Under the Anvil',
    palette: {
      // The same cloud act II climbed over, from underneath - which is the first
      // moment the campaign lets the player recognise somewhere they have been.
      top: '#404c5c',
      mid: '#5a6674',
      bottom: '#78838f',
      shoal: '#f2f8fc',
      shoalGlow: 'rgba(198,220,240,0.22)',
      pod: '198,178,138',
      rock: '#8e99a6',
      rockRim: '#d4dee8',
      tracer: [204, 220, 238],
      speck: '#e6eef6',
      speckDensity: 1.1,
    },
  },
  {
    key: 'downpour',
    name: 'The Downpour',
    palette: {
      top: '#455360',
      mid: '#546472',
      bottom: '#657787',
      shoal: '#eaf6ff',
      shoalGlow: 'rgba(180,214,244,0.24)',
      pod: '190,172,132',
      rock: '#79899a',
      rockRim: '#c2d2e2',
      tracer: [188, 212, 236],
      speck: '#dceaf6',
      speckDensity: 1.4,
    },
  },
  {
    key: 'canopy',
    name: 'The Canopy',
    palette: {
      // The first green in the game, and the first obstacle since act I that is
      // a solid thing rather than weather.
      top: '#31402e',
      mid: '#41563a',
      bottom: '#5d7a4c',
      shoal: '#eefaf0',
      shoalGlow: 'rgba(190,236,196,0.22)',
      pod: '190,176,120',
      rock: '#2e3c26',
      rockRim: '#7f9c62',
      tracer: [186, 226, 190],
      speck: '#d8f0dc',
      speckDensity: 1.2,
    },
  },
  {
    key: 'brook',
    name: 'The Mountain Brook',
    palette: {
      // Running water for the first time. Bright, hard, and full of stone.
      top: '#2a4a4e',
      mid: '#3d6f6e',
      bottom: '#69a099',
      shoal: '#f0feff',
      shoalGlow: 'rgba(180,244,238,0.24)',
      pod: '208,190,140',
      rock: '#33413f',
      rockRim: '#8fb6ac',
      tracer: [176, 234, 226],
      speck: '#ccf4ee',
      speckDensity: 1.25,
    },
  },
  {
    key: 'estuary',
    name: 'The Estuary',
    palette: {
      // Where the fresh water meets the sea, and where the gold turns back into
      // something alive. The green is going out of it and the blue is coming in.
      top: '#20464f',
      mid: '#256271',
      bottom: '#3f93a0',
      shoal: '#eafcff',
      shoalGlow: 'rgba(160,236,244,0.24)',
      pod: '255,214,150',
      rock: '#22383c',
      rockRim: '#5d9aa4',
      tracer: [158, 226, 234],
      speck: '#c4eff4',
      speckDensity: 1.15,
    },
  },
];

/**
 * Slowblue: act VII, and the campaign closing its own circle.
 *
 * These are act I's four bands, run backwards and softened. The sunlit zone, the
 * blue, the midnight and the hadal violet-black arrive in reverse order, and the
 * last palette in the game is deliberately within a few values of the first one -
 * because the last frame of the campaign and the first frame of it are supposed
 * to be the same picture, and the player is supposed to notice that themselves.
 *
 * What is different is what is *in* them. Act I's water is lit from above by a
 * surface six thousand metres away; act VII's is lit from inside by what the
 * player is carrying. So `shoal` stays warm all the way down, and the specks -
 * marine snow, falling with the swarm rather than past it - stay dense where act
 * I's were sparse.
 */
const HOME_SPECS: ZoneSpec[] = [
  {
    key: 'brackish',
    name: 'The Salt Line',
    palette: {
      top: '#2c7d8e',
      mid: '#1a5f74',
      bottom: '#0d3c50',
      shoal: '#fff4d8',
      shoalGlow: 'rgba(255,226,160,0.22)',
      pod: '255,224,158',
      rock: '#0d2b34',
      rockRim: '#3c8090',
      tracer: [176, 240, 246],
      speck: '#d8f8ff',
      speckDensity: 1.2,
    },
  },
  {
    key: 'sunlit',
    name: 'The Sunlit Zone',
    palette: {
      top: '#1e9db2',
      mid: '#0a6c80',
      bottom: '#032e44',
      shoal: '#fff6e0',
      shoalGlow: 'rgba(255,228,168,0.2)',
      pod: '255,226,164',
      rock: '#07222e',
      rockRim: '#2d7686',
      tracer: [186, 242, 252],
      speck: '#dcfbff',
      speckDensity: 1.05,
    },
  },
  {
    key: 'twilight',
    name: 'The Twilight Zone',
    palette: {
      top: '#0a5c6e',
      mid: '#053241',
      bottom: '#01141f',
      shoal: '#fff0d0',
      shoalGlow: 'rgba(255,216,150,0.2)',
      pod: '255,214,146',
      rock: '#04161d',
      rockRim: '#155764',
      tracer: [142, 224, 232],
      speck: '#bceef6',
      speckDensity: 0.8,
    },
  },
  {
    key: 'midnightHome',
    name: 'The Deep Sea',
    palette: {
      top: '#0a2049',
      mid: '#050d28',
      bottom: '#01040f',
      shoal: '#ffeec4',
      shoalGlow: 'rgba(255,208,136,0.2)',
      pod: '255,206,140',
      rock: '#040816',
      rockRim: '#1b3062',
      tracer: [150, 190, 250],
      speck: '#cfe0ff',
      speckDensity: 0.62,
    },
  },
  {
    key: 'snow',
    name: 'Marine Snow',
    palette: {
      // The one band in the game with more specks than anything else in it. Every
      // one of them is falling the way the swarm is falling, which is the whole
      // visual idea of the station: for the first time the player is not passing
      // through the world, they are descending with it.
      top: '#140c30',
      mid: '#08061c',
      bottom: '#01010a',
      shoal: '#ffeec6',
      shoalGlow: 'rgba(255,204,140,0.2)',
      pod: '255,202,140',
      rock: '#050110',
      rockRim: '#2c1d52',
      tracer: [206, 186, 255],
      speck: '#f0e8ff',
      speckDensity: 1.5,
    },
  },
  {
    key: 'trenchHome',
    name: 'The Trench Floor',
    palette: {
      // Act I's first palette, to within a few values, and lit warm instead of
      // cold. This is the last frame of the campaign and the first frame of it.
      top: '#170d34',
      mid: '#09061d',
      bottom: '#010108',
      shoal: '#ffe9b8',
      shoalGlow: 'rgba(255,198,120,0.22)',
      pod: '255,196,126',
      rock: '#05010e',
      rockRim: '#34205a',
      tracer: [214, 186, 255],
      speck: '#e6d8ff',
      speckDensity: 0.9,
    },
  },
];

export const ZONES: Zone[] = stamp(WATER_SPECS, 0);
export const AIR_ZONES: Zone[] = stamp(AIR_SPECS, ZONES.length);
export const THIN_ZONES: Zone[] = stamp(THIN_SPECS, ZONES.length + AIR_ZONES.length);
export const SPACE_ZONES: Zone[] = stamp(
  SPACE_SPECS,
  ZONES.length + AIR_ZONES.length + THIN_ZONES.length,
);
export const REENTRY_ZONES: Zone[] = stamp(
  REENTRY_SPECS,
  ZONES.length + AIR_ZONES.length + THIN_ZONES.length + SPACE_ZONES.length,
);
export const RAIN_ZONES: Zone[] = stamp(
  RAIN_SPECS,
  ZONES.length +
    AIR_ZONES.length +
    THIN_ZONES.length +
    SPACE_ZONES.length +
    REENTRY_ZONES.length,
);
export const HOME_ZONES: Zone[] = stamp(
  HOME_SPECS,
  ZONES.length +
    AIR_ZONES.length +
    THIN_ZONES.length +
    SPACE_ZONES.length +
    REENTRY_ZONES.length +
    RAIN_ZONES.length,
);

/** Every palette the campaign can paint, in play order. Indexed by `Level.zone`. */
export const ALL_ZONES: Zone[] = [
  ...ZONES,
  ...AIR_ZONES,
  ...THIN_ZONES,
  ...SPACE_ZONES,
  ...REENTRY_ZONES,
  ...RAIN_ZONES,
  ...HOME_ZONES,
];

/** Zone index of the first band of an act's table. Level files read these. */
export const ZONE_WATER = ZONES[0]!.index;
export const ZONE_AIR = AIR_ZONES[0]!.index;
export const ZONE_THIN = THIN_ZONES[0]!.index;
export const ZONE_SPACE = SPACE_ZONES[0]!.index;
export const ZONE_REENTRY = REENTRY_ZONES[0]!.index;
export const ZONE_RAIN = RAIN_ZONES[0]!.index;
export const ZONE_HOME = HOME_ZONES[0]!.index;

export function zoneForSection(sectionId: number): Zone {
  let z = ZONES[0]!;
  for (const candidate of ZONES) {
    if (sectionId >= candidate.fromSection) z = candidate;
  }
  return z;
}

/** Section kind for a given id: the owning zone's cycle, offset from its own start. */
export function sectionKindFor(sectionId: number): SectionKind {
  const zone = zoneForSection(sectionId);
  const offset = sectionId - zone.fromSection;
  return zone.pool[offset % zone.pool.length]!;
}
