import {
  BOTTOM_Y,
  MAP_H,
  MAP_W,
  SEA_Y,
  SPACE_Y,
  seaCrestY,
  worldY,
  type WorldFrame,
} from './Circuit';

/**
 * Slowblue: what lives at each level of the world the circuit is drawn on.
 *
 * `meta/Circuit.ts` put a world behind the route - the sea, the top of the air,
 * and the two bands they are the edges of - and stopped there on purpose, because
 * the thing it was drawing is a transit line and a transit line does not draw
 * scenery. That was right about the line and wrong about the world: three bands
 * of flat colour separated by two arcs are three bands of flat colour. A player
 * who has not flown the campaign reads them as a gradient. Nothing in the picture
 * says the bottom one is water, the middle one is air and the top one is neither.
 *
 * So each band is given what could only be there. Not an illustration of a
 * station - the game draws those, for real and for four minutes at a time - but
 * the smallest marks that name the medium: a population, which says what the
 * place is full of, and where a band needs one, a single object that says what
 * it is.
 *
 *   - **The water** has fish through the whole of it, at every size from a speck
 *     to something with a shape, and the floor of the trench under them. The fish
 *     are the subject of the game and are drawn the way the game draws them, from
 *     directly above; the floor is where act I begins and act VII ends, and it is
 *     why the bottom of the map is a place rather than an edge.
 *   - **The air** is two things, because the campaign climbs through two. Its
 *     bottom third is act II, nought to eleven kilometres, and has birds in it
 *     and cloud among them - the room the weather on this map is entitled to.
 *     Above that is act III, "The Thinning", and it has the high ice: long flat
 *     filaments, drawn as lines rather than as cloud for the reason
 *     `render/Upper.ts` gives, which is that air at two hundred knots smears ice
 *     into lines and not into lumps.
 *   - **Above the air** there are stars, and one satellite. There is nothing else
 *     up there, which is the point of the band.
 *   - **The sea itself** - the line between the first two - has one boat on it.
 *     The arc was the one edge in this picture doing no work: the water below it
 *     and the air above it each said what they were, and the boundary between
 *     them was left to be inferred from both. Nothing infers a *sea* from a
 *     change of tint. What a sea has that no other line in the world can have is
 *     something floating on it, so that is what it is given, and exactly that:
 *     one hull, which is the only object in the picture that needs a surface to
 *     exist at all. See `SURFACE`.
 *
 * ## The rules these obey, and why there are rules at all
 *
 * A map that grows scenery grows clutter, and this one has forty-two stops and
 * seven names to protect. Four constraints, and everything in this file is
 * downstream of them:
 *
 *   1. **Nothing is drawn where the map has ink.** `ROUTE_INK` is the four
 *      rectangles the route, its stops and its names actually occupy, and
 *      `underRoute` is the test every mark passes before it is placed. A mark
 *      that lands there is not moved out of the way - it is dropped, because a
 *      picture whose furniture shuffles about to avoid the type is a picture with
 *      furniture in it. On a phone that hides most of them and leaves the column
 *      inside the route; on a desktop, where the map is a narrow column in a wide
 *      window, nearly all of them survive and the world fills the room the map is
 *      not using. The wider the screen, the more world there is. That is the
 *      right way round.
 *   2. **Everything is sized in box units.** A cloud is a fraction of the map,
 *      never of the screen, so the world scales with the picture it belongs to
 *      rather than swelling on a desktop.
 *   3. **Everything is placed in the band it belongs to**, by a fraction of that
 *      band's own depth - so a fish is at a depth and not at a pixel, and the
 *      whole population moves when the horizon does. The two exceptions are the
 *      two objects that have to survive the narrowest screen, and they are placed
 *      against the picture instead; see `at` and `PLACED`.
 *   4. **It is authored once and never random.** `hash` is the same stable
 *      integer scramble the backdrops use: the same sky every time the map is
 *      opened, on every machine, which is what stops the picture from being a
 *      different picture on every visit.
 *
 * Like `meta/Circuit.ts` this file is pure and DOM-free. It hands the shell
 * numbers and a handful of unit-sized path strings; the shell turns them into
 * SVG and a test reads the same numbers.
 */

/**
 * Which of the three the mark is in. Only ever the medium, never the act.
 *
 * ...and a fourth that is not a medium at all: `surface` is the seam between two
 * of them, and it is a band with no thickness. A thing on the sea is at a place
 * along it and at no depth in it, so a mark that claims this band is put on the
 * waterline exactly and its `v` is never read - see `bandAt`, which returns the
 * same height for the ceiling and the floor of it, and means it.
 */
export type HabitatBand = 'water' | 'air' | 'space' | 'surface';

/** What the mark is: three populations, and the two built things among them. */
export type HabitatKind = 'fish' | 'cloud' | 'streak' | 'bird' | 'star' | 'satellite' | 'boat';

/**
 * One inhabitant, in the only two coordinates that survive a change of screen.
 *
 * `u` is across the window, because the bands run the whole width of it and
 * always have. `v` is down the mark's own band rather than down the window: the
 * ceiling and the floor of a band are two arcs that move when the map is resized,
 * and a fish authored at a pixel would surface as the screen got shorter.
 */
export interface Life {
  kind: HabitatKind;
  band: HabitatBand;
  /** Across the window: 0 at the left edge, 1 at the right. */
  u: number;
  /** Down its own band: 0 at its ceiling, 1 at its floor. */
  v: number;
  /**
   * ...or, for the two that are placed rather than scattered, straight into the
   * map's own box, in its own units. `u` and `v` are ignored when this is set.
   *
   * Two coordinate systems in one type wants justifying, and the justification is
   * that the two are answers to different questions. A scatter is a population in
   * a medium: it is spread across the window because the window is what the bands
   * cross, and it is at a depth in its band because that is where the thing lives.
   * A landmark is not a population. Its whole job is to be in the one pocket of
   * screen the route has left over, and those pockets are holes in the *picture* -
   * they are the same shape, in box units, at every size the picture is drawn at,
   * and they move about the window as the map is inset into it. Placing a
   * satellite by a fraction of the screen means placing it by a number that lands
   * differently on every device; placing it in the box means placing it where the
   * hole is.
   *
   * `y` is left off by the one thing that floats. A hull's height is not a taste
   * and not a hole in the picture - it is wherever the water is, which is an arc
   * that moves with the frame - so it says where along the picture it is and lets
   * the band answer the other axis. There is no box coordinate that would be
   * right: the surface stands at `SEA_Y` where it crosses the rails and above it
   * everywhere between them, by a couple of units on a phone and less than one on
   * a desktop, and a boat authored at a fixed height is a boat that hovers on one
   * of the two.
   */
  at?: { x: number; y?: number };
  /** How big, in box units - the map's size, not the screen's. */
  size: number;
  /**
   * ...and how tall its drawing is against that, as a fraction.
   *
   * `size` is a width, because every shape in `HABITAT_SHAPES` is one unit wide
   * and none of them is one unit tall. Without this the keep-out has to assume
   * the worst and test a square, which is not a rounding error: a streak of high
   * ice is a seventh as tall as it is long, so a square around it is seven times
   * the mark, and the picture was quietly deleting most of the sky for standing
   * near something it was nowhere near.
   */
  tall: number;
  /** Turned, in degrees. */
  angle: number;
  /** How far away it is, said as ink. */
  alpha: number;
  /** Which drawing of its kind, for the kinds that have more than one. */
  shape: number;
}

/** ...and the same thing once a frame has told it where that is, in pixels. */
export interface PlacedLife extends Life {
  x: number;
  y: number;
  /** Pixels to a shape unit: what the unit drawing is multiplied by. */
  drawn: number;
  /** Zero for a mark the route is standing on. It is dropped, not moved. */
  ink: number;
}

/**
 * The floor of the trench, as the third shell of this planet.
 *
 * `meta/Circuit.ts` has two - the sea and the top of the air - struck from one
 * centre because they are skins of the same world. This is the third and it is
 * struck from the same centre for the same reason, which also gets the geology
 * right for free: a deeper shell has a smaller radius and therefore curves harder,
 * so the floor falls away at the edges of the screen faster than the surface above
 * it does.
 *
 * Its height is not a taste, and it is not a spare unit either side of one. It is
 * *exactly* the run the circuit closes along, because act I station 1 and act VII
 * station 6 are the same six thousand metres of water: the bottom of the route is
 * the floor of the trench, and rock at any other height on this screen would be
 * rock at a depth the campaign never goes to.
 *
 * ## Why it is a tone and not a coastline
 *
 * It was drawn first as rock - a ragged crest with a stroked edge, a couple of
 * units under the seam - and it was wrong in a way that took a screenshot to see.
 * Under the picture the shell keeps a column of type: a count, an act's name, its
 * verb, its sentence and two buttons, all of them centred and most of them the
 * full width of the panel. There is no horizontal line that can be put across
 * that column, at any height, that does not go through a word - the gaps are ten
 * pixels tall on a phone and they move when the copy, the act or the station
 * list changes.
 *
 * So the floor keeps the depth and gives up the edge. No stroke, no ridges: a
 * flat step to a deeper tone, whose top lands under the closing seam, which is a
 * line the picture is already drawing. The one place the boundary is visible is
 * the one place it is already accounted for, and everywhere else it is a change
 * of material rather than a mark - which is the same thing a discrete depth plane
 * has always been in this game.
 */
export const FLOOR_Y = BOTTOM_Y;

/**
 * Where the shell's own column stops and the world may start again, in box units.
 *
 * Below this the panel takes the screen: the act's name, its verb, its arc, the
 * station list and two buttons. Above the box there is the heading. Both are the
 * full width of the picture and neither is anywhere for a fish to be.
 */
const PANEL_Y = MAP_H - 8;

/**
 * The four rectangles the map's own ink is in.
 *
 * Written out rather than derived from `CIRCUIT_ACTS[].hit`, and the difference
 * matters: a hit rectangle is what a *thumb* is allowed to be sloppy about, and it
 * is deliberately generous in one direction and silent in others - it stops at the
 * first and last stop of an act and knows nothing about the corners of the route,
 * the arrowheads on the seams, or the two lines of type under the bottom of the
 * picture. This is the other question: where is there ink. `tests/atlas.test.ts`
 * asserts that every stop, every entry ring, every arrowhead and every label
 * anchor the shell draws falls inside one of these, which is what keeps the two
 * from drifting apart.
 *
 * Four, because the route is a rectangle and its four runs are four different
 * problems: two rails with their names set outside them, a turn across the top
 * with its name above it, and a closing seam along the bottom with the trench
 * floor's name under it.
 */
export const ROUTE_INK: readonly {
  x: number;
  y: number;
  w: number;
  h: number;
}[] = [
  // The climb: acts I to III, their stops, and the names set to the left of them.
  { x: 0, y: 78, w: 136, h: 346 },
  // The fall: acts V to VII, and the long names on the right - "The Homecoming"
  // is the widest word in the picture and it is the reason this gutter is wider.
  { x: 230, y: 78, w: 154, h: 346 },
  // The turn: six stops across the top, the two corners either side of them, and
  // "Orbit" above with its altitudes under it.
  { x: 110, y: 14, w: 146, h: 72 },
  // ...and the seam that closes the circuit, with the arrowhead on it and the
  // name of the place both ends of the journey share.
  { x: 110, y: 414, w: 146, h: 58 },
];

/**
 * True where a mark of this size would land on the picture rather than beside it.
 *
 * Whole-mark rather than centre-point: a cloud whose middle clears a name by a
 * unit still has half a cloud over it. `halfW` and `halfH` are half the mark's
 * reach on each axis, in pixels, and every part of the box it occupies has to be
 * clear.
 *
 * Two half-extents rather than one, and it is the difference between a sky with
 * weather in it and a sky with two clouds in it. Every drawing here is wider than
 * it is tall - a cloud by two to one, a streak of high ice by seven - so a square
 * around one is mostly empty, and a square is what this took until it was
 * measured: marks were being deleted for standing near type they cleared by
 * thirty units.
 *
 * The two axes are not the same question either, which is why the box is tested
 * before the rectangles are and not as two more of them. Sideways, being off the
 * picture is being *free*: that is the margin a wide window leaves either side of
 * a four-hundred-unit column, and it is where most of this world gets to live. Up
 * and down it is the opposite: over the top of the box is the heading and under
 * the bottom is the panel - an act's name, its verb, its sentence, the station
 * list and two buttons - and neither has any room in it at all.
 */
export function underRoute(
  frame: WorldFrame,
  x: number,
  y: number,
  halfW: number,
  halfH: number,
): boolean {
  const left = (x - halfW - frame.x) / frame.scale;
  const right = (x + halfW - frame.x) / frame.scale;
  if (right < 0 || left > MAP_W) return false;
  const top = (y - halfH - frame.y) / frame.scale;
  const bottom = (y + halfH - frame.y) / frame.scale;
  if (top < 0 || bottom > PANEL_Y) return true;
  return ROUTE_INK.some((k) => right > k.x && left < k.x + k.w && bottom > k.y && top < k.y + k.h);
}

/**
 * A stable 0..1 from an integer: the same scramble the backdrops scatter by.
 *
 * Copied rather than imported, and that is the smaller sin of the two available:
 * the original lives in `render/SkyParts.ts` next to a canvas context and a
 * colour type, and reaching into the renderer from `meta/` to borrow six lines of
 * integer arithmetic would put the whole backdrop layer on the far side of an
 * import that only ever wanted a number.
 */
function hash(i: number): number {
  let h = Math.imul(i ^ 0x9e3779b9, 0x85ebca6b);
  h = Math.imul(h ^ (h >>> 13), 0xc2b2ae35);
  return ((h >>> 8) & 0xffff) / 0xffff;
}

/**
 * How many of one kind there are, and the room they are allowed.
 *
 * A population rather than a list of positions, because the number that actually
 * decides how full the world looks is not the count - it is how much of the
 * window the route is not using, and that is only known at layout. So every
 * colony is authored at its widest: enough of them to fill a desktop, spread the
 * whole way across, and on a phone `underRoute` quietly takes most of them back.
 */
interface Colony {
  kind: HabitatKind;
  band: HabitatBand;
  count: number;
  /** The slice of its band it may stand in: 0 at the ceiling, 1 at the floor. */
  from: number;
  to: number;
  /** How big it comes, in box units. Most are the first; a few are the second. */
  small: number;
  large: number;
  /** How tall the drawing is against its width. See `Life.tall`. */
  tall: number;
  /** ...and how much ink that buys, at each end. */
  faint: number;
  solid: number;
  /** How far one may turn from level, in degrees. */
  turn: number;
  /** How many drawings this kind has. */
  shapes: number;
}

const COLONIES: readonly Colony[] = [
  /*
   * Fish, through the whole depth of the water, and the only mark down there.
   *
   * The one thing in this file that is not scenery: it is what the player spends
   * the campaign holding together, and it is drawn from above because that is the
   * camera the game has. They all point roughly the same way for the same reason
   * a school does - a shoal facing seven directions is seven fish.
   *
   * There was a manta ray in here as well, on the argument that every other band
   * gets one big unmistakable object and the water should have one too. It went:
   * at the size a landmark has to be it was the largest shape on the screen after
   * the route itself, and a map does not need a mascot. The symmetry was mine and
   * not the picture's - the water already has a second mark, and it is the floor
   * of the trench. What replaces the ray is more fish across a wider range of
   * sizes, which fills the same room and says the same thing without any one
   * object asking to be looked at.
   */
  {
    kind: 'fish',
    band: 'water',
    count: 21,
    from: 0.1,
    to: 0.88,
    small: 8,
    large: 24,
    tall: 0.36,
    faint: 0.17,
    solid: 0.4,
    turn: 14,
    shapes: 1,
  },
  /*
   * Cloud, in the bottom third of the air - which is act II, and not the bottom
   * tenth, which was a mistake made with a calculator.
   *
   * The reasoning that put them in the tenth is true about the sky and false
   * about this map: the band is eleven hundred kilometres of altitude, weather
   * stops at eleven of them, so weather is one per cent of the band. But the map
   * is not linear in metres and never claimed to be. Act II - nought to eleven
   * kilometres - is drawn a third of the way up the air, because an act gets a
   * share of the *route* rather than a share of the sky. So the room the weather
   * is entitled to here is act II's room, and the honest placement is the one
   * that reads: cloud sitting on the waterline in a strip a few units tall is not
   * weather, it is fog on a lens.
   *
   * Smaller, too, and more of them. A bank three quarters the width of the column
   * inside the route is one object with the picture built round it; at half that
   * there is a sky with cloud in it.
   */
  {
    kind: 'cloud',
    band: 'air',
    count: 17,
    from: 0.58,
    to: 0.93,
    small: 22,
    large: 52,
    tall: 0.46,
    faint: 0.09,
    solid: 0.19,
    turn: 0,
    shapes: 2,
  },
  /*
   * Birds, through the same third and a little above it. Small, because the only
   * thing this mark has to say is "there is air here" and a gull the size of a
   * cloud says something else.
   */
  {
    kind: 'bird',
    band: 'air',
    count: 14,
    from: 0.48,
    to: 0.9,
    small: 8,
    large: 15,
    tall: 0.28,
    faint: 0.22,
    solid: 0.44,
    turn: 9,
    shapes: 1,
  },
  /*
   * ...and, above the weather, the high ice - which is what fills the top of the
   * air, and is the reason nothing else has to.
   *
   * The band above act II is act III, "The Thinning", eleven to a hundred
   * kilometres, and it was empty here on the argument that there is nothing up
   * there. That is wrong twice. There is something up there and the game draws
   * it: `render/Upper.ts` puts streaked ice at the jet, a standing wave at the
   * nacreous station and combed filaments at the mesopause, and it draws all of
   * them as *lines* rather than as cloud, for a reason it states plainly - cirrus
   * at this altitude is ice being dragged at two hundred knots, and air at those
   * speeds smears ice into lines, not into lumps. And it is the one act whose
   * mechanic is its backdrop: the layers are the thing act III asks the player to
   * read.
   *
   * So the top of the air gets the same mark: long, nearly flat, two or three
   * filaments together, at a fraction of the ink of anything below them. They are
   * the widest thing in this file and the flattest, which is exactly why the
   * keep-out had to learn about `tall` before they could exist - a square round a
   * ninety-unit streak is ninety units of sky deleted for a mark seven units
   * thick.
   */
  {
    kind: 'streak',
    band: 'air',
    count: 15,
    from: 0.06,
    to: 0.6,
    small: 34,
    large: 96,
    tall: 0.18,
    faint: 0.1,
    solid: 0.24,
    turn: 2,
    shapes: 2,
  },
  /*
   * Stars, in magnitudes and crowded towards the top.
   *
   * Both of those are `render/SkyParts.ts` - the sky above act III does the same
   * two things for the same reason, and this is the same sky seen from outside
   * it. Most are the smallest the picture can draw and a handful are three times
   * that, which is what a star field is: it is not a scatter of equal dots.
   */
  {
    kind: 'star',
    band: 'space',
    count: 46,
    from: 0.05,
    to: 0.93,
    small: 1.1,
    large: 3.4,
    tall: 1,
    faint: 0.16,
    solid: 0.62,
    turn: 0,
    shapes: 1,
  },
];

/**
 * The one on the water, which is the reason the waterline is a surface and not a
 * change of colour.
 *
 * There was a drilling platform beside it for a while, on the argument that a
 * structure standing *through* the arc is the strongest evidence there is that
 * the arc has two sides. The argument was sound and the picture disagreed: a rig
 * is a busy shape - a deck, four battered legs, a brace, a derrick and a boom -
 * and at the size the column allows, all of that lands as a scribble on the one
 * line the map draws hardest. Two objects were also competing for the same job.
 * One boat says "sea", and having said it, stops.
 *
 * It is placed rather than scattered for the satellite's reason and one more.
 * The satellite's reason: there is one of it, and one of anything cannot be left
 * to a keep-out that deletes most of a colony on a phone. The other is that the
 * waterline is the *worst* run of this picture to scatter along. It crosses the
 * two rails at exactly the height where act I hands over to act II and act VI to
 * act VII - both of those seams carry an arrowhead and both are two stops from a
 * name - so the whole of the sea inside the box is the ninety-four units of
 * column between the rails, and a scatter aimed at it would place one boat in
 * three and throw the rest away.
 *
 * It carries no `y`. The sea is an arc struck from a centre a long way below the
 * frame, so it stands at `SEA_Y` where it meets the rails and a little above it
 * between them - about two and a half box units on a phone, less than one on a
 * desktop - and the band answers that height at whatever `x` it is asked for. A
 * boat authored at a fixed height hovers by two pixels on the screen it was not
 * tried on, and sinks by two on the next.
 *
 * It is level, and that is a rule rather than an oversight: everything else
 * placed here is turned a degree or two off true so that no two marks are the
 * same object, and a hull is the one thing in this picture whose angle would be a
 * claim. Water is level. A boat listing four degrees on a still map is a boat in
 * trouble.
 *
 * It sits a little to the left of the middle of the open water - off the crown of
 * the horizon, which is at `GLOBE_X`, because a boat balanced on the exact top of
 * an arc reads as a boat on a hill - with twenty-four units clear of the rail on
 * one side and thirty-six on the other.
 */
const SURFACE: readonly Life[] = [
  /*
   * A coaster: hull, wheelhouse aft, one mast. Three parts, and the third one is
   * the one that works - a hull alone is a wedge, and a wedge on a line is a
   * wedge on a line. Anything past three at this size is a smudge with ambition.
   */
  {
    kind: 'boat',
    band: 'surface',
    u: 0,
    v: 0,
    at: { x: 176 },
    size: 32,
    tall: 0.84,
    angle: 0,
    alpha: 0.34,
    shape: 0,
  },
];

/**
 * The seven that are placed rather than scattered.
 *
 * A scatter is honest about a population and useless about a phone. It spreads
 * things across the whole window and lets `underRoute` take back whichever the
 * map is standing on, which is exactly right for forty-six stars and exactly
 * wrong for anything there is only one of, or anything too wide to fit where a
 * narrow screen has room: a mark that is only ever there on a desktop is not a
 * mark, it is a reward for having a big monitor.
 *
 * On a phone the picture is as wide as the window, so the only room this world
 * has is the two holes the route leaves in it: the pocket of dark to the right of
 * the turn, and the ninety-four units of column between the two rails. Both are
 * holes in the *picture*, so both are written in box units - see `at` - and every
 * number below is checked against `ROUTE_INK` by hand and again by
 * `tests/habitat.test.ts` on the narrowest frame the map is drawn at.
 *
 * The satellite was placed across the *window* first, at 0.795 of it, which is
 * right about where that pocket sits on the one screen it was tried on and wrong
 * everywhere else - how much window there is above the picture depends on how
 * tall the window is, and on a phone a few pixels taller it floated up out of the
 * map and was dropped.
 */
const PLACED: readonly Life[] = [
  {
    kind: 'satellite',
    band: 'space',
    u: 0,
    v: 0,
    at: { x: 312, y: 34 },
    size: 23,
    tall: 0.53,
    angle: -8,
    alpha: 0.32,
    shape: 0,
  },
  /*
   * ...and four streaks of high ice up the column, which is the whole of act III
   * on a phone.
   *
   * The scattered ones cannot do this job. A streak is the widest mark in the
   * file and the column is ninety-four units across, so the only ones that fit
   * inside it are the small ones, and the odds of a small one being dealt a slot
   * in the middle of the window are odds - the upper air came out with one streak
   * in it, which is a scratch rather than a sky. These four are staggered across
   * the column and up it so that no two line up, and sized to their own height:
   * the widest is at the top where the column is emptiest.
   */
  {
    kind: 'streak',
    band: 'air',
    u: 0,
    v: 0,
    at: { x: 183, y: 118 },
    size: 84,
    tall: 0.18,
    angle: -1.5,
    alpha: 0.2,
    shape: 1,
  },
  {
    kind: 'streak',
    band: 'air',
    u: 0,
    v: 0,
    at: { x: 196, y: 150 },
    size: 56,
    tall: 0.18,
    angle: 1,
    alpha: 0.15,
    shape: 0,
  },
  {
    kind: 'streak',
    band: 'air',
    u: 0,
    v: 0,
    at: { x: 180, y: 182 },
    size: 74,
    tall: 0.18,
    angle: -1,
    alpha: 0.22,
    shape: 1,
  },
  {
    kind: 'streak',
    band: 'air',
    u: 0,
    v: 0,
    at: { x: 168, y: 212 },
    size: 48,
    tall: 0.18,
    angle: 1.5,
    alpha: 0.14,
    shape: 0,
  },
  ...SURFACE,
];

/**
 * Everybody, authored once.
 *
 * Stratified across the window rather than hashed onto it: `i` of `count` gets
 * its own slice of the width and jitters inside it, so a colony spreads instead
 * of clumping. A hash alone gives four birds in one place and a hole where the
 * fifth should be, which reads as a mistake rather than as a flock - and with
 * `underRoute` about to delete whichever of them are over the type, a clump is
 * also how a colony disappears entirely.
 */
export const HABITAT: readonly Life[] = [
  ...COLONIES.flatMap((c, ci) =>
    Array.from({ length: c.count }, (_, i): Life => {
      const seed = ci * 977 + i * 31;
      // How big this one is, and therefore how near: most small, a few large.
      const grown = Math.pow(hash(seed), 1.7);
      return {
        kind: c.kind,
        band: c.band,
        u: (i + 0.16 + 0.68 * hash(seed + 1)) / c.count,
        v: c.from + (c.to - c.from) * hash(seed + 2),
        size: c.small + (c.large - c.small) * grown,
        tall: c.tall,
        angle: (hash(seed + 3) - 0.5) * 2 * c.turn,
        alpha: c.faint + (c.solid - c.faint) * grown,
        shape: Math.floor(hash(seed + 4) * c.shapes) % c.shapes,
      };
    }),
  ),
  ...PLACED,
];

/**
 * The ceiling and the floor of a band, at one place across the window.
 *
 * The surface is the degenerate one and is written as one rather than special-
 * cased anywhere else: its ceiling and its floor are the same line, so any `v` at
 * all lands on the water and the thing that floats has no depth to get wrong. It
 * is the same statement the physics makes - a surface is where a depth runs out.
 *
 * That line is the crests rather than the mean, because the sea has a swell on it
 * and a hull put on the average height of a rippled surface is a hull with the
 * ripples drawn through it. `Circuit.seaCrestY` is the whole of that argument.
 *
 * The other three bands are quoted against the mean surface and stay that way.
 * A fish is not resting on anything, and moving a whole ocean of them by one
 * pixel to agree with a wave nobody can see them near would be arithmetic for
 * its own sake.
 */
function bandAt(frame: WorldFrame, band: HabitatBand, x: number): { top: number; bottom: number } {
  if (band === 'space') return { top: 0, bottom: worldY(frame, SPACE_Y, x) };
  if (band === 'air') {
    return { top: worldY(frame, SPACE_Y, x), bottom: worldY(frame, SEA_Y, x) };
  }
  if (band === 'surface') {
    const crest = seaCrestY(frame, x);
    return { top: crest, bottom: crest };
  }
  return { top: worldY(frame, SEA_Y, x), bottom: worldY(frame, FLOOR_Y, x) };
}

/**
 * Where everybody stands in this frame, in its own pixels, in authored order.
 *
 * Same length every time and never re-ordered, so the shell can build one node
 * per inhabitant once and afterwards only ever move it: a resize and a scroll
 * both change where the world is and neither is a reason to make sixty new
 * elements. A mark the route has landed on comes back with no ink rather than
 * being left out, which is the same rule stated in the one place the shell can
 * act on without counting anything.
 */
export function placeHabitat(frame: WorldFrame): readonly PlacedLife[] {
  return HABITAT.map((life) => {
    // Across the window, or into the picture's own box - the two questions `at`
    // is for. The height is the same choice made once more and separately,
    // because a thing can be placed against the picture on one axis and left to
    // its band on the other: that is what a hull is, and it is the only way the
    // sea's own two marks can be somewhere the route is not and still be on the
    // water. An `at` without a `y` says exactly that and nothing else.
    const x = life.at !== undefined ? frame.x + life.at.x * frame.scale : life.u * frame.width;
    let y: number;
    if (life.at?.y !== undefined) {
      y = frame.y + life.at.y * frame.scale;
    } else {
      const band = bandAt(frame, life.band, x);
      y = band.top + (band.bottom - band.top) * life.v;
    }
    const drawn = life.size * frame.scale;
    /*
     * The box a turned mark actually occupies, which is not the box it was drawn
     * in. A `w` by `h` rectangle turned through `a` has an upright bounding box
     * of `w|cos a| + h|sin a|` by `w|sin a| + h|cos a|`, and at the angles here -
     * fourteen degrees on a fish, two on a streak - the difference is small but
     * it is in the direction that matters: it is the corner of a tilted fish that
     * reaches a name, not its middle.
     */
    const rad = (life.angle * Math.PI) / 180;
    const cos = Math.abs(Math.cos(rad));
    const sin = Math.abs(Math.sin(rad));
    const halfW = (drawn * (cos + life.tall * sin)) / 2;
    const halfH = (drawn * (sin + life.tall * cos)) / 2;
    return {
      ...life,
      x,
      y,
      drawn,
      ink: underRoute(frame, x, y, halfW, halfH) ? 0 : life.alpha,
    };
  });
}

/**
 * The drawings themselves, each one unit wide and centred on nothing but itself.
 *
 * Unit-sized so that placing one is a `transform` and never a new path: the shell
 * writes these once into the document and afterwards only ever moves and scales
 * them, which is what makes a scroll cost four attribute writes a mark instead of
 * fifty path strings.
 *
 * They are strokes and fills in the proportions the rest of the shell already
 * uses - the stroked ones carry `vector-effect` in the stylesheet, so a satellite
 * on a desktop is drawn with the same hairline as a bird on a phone and the whole
 * world stays one weight however big any of it is.
 */
export const HABITAT_SHAPES: Readonly<Record<HabitatKind, readonly string[]>> = {
  /*
   * A fish from directly above: a spindle with a forked tail behind it.
   *
   * The same silhouette `render/FishShapes.ts` traces, with the swimming taken
   * out - the body there is built round a spine carrying a travelling wave, and
   * what is left when nothing is moving is this.
   */
  fish: [
    'M 0.5 0 C 0.2 -0.15 -0.06 -0.16 -0.2 0 C -0.06 0.16 0.2 0.15 0.5 0 Z ' +
      'M -0.16 0 L -0.5 -0.18 L -0.33 0 L -0.5 0.18 Z',
  ],
  /*
   * A bank of cloud, as one lumpy fill on a flat base.
   *
   * `render/SkyParts.ts` builds the real ones the same way and for the same
   * reason: a deck is one shape however many lumps it has, and a stack of
   * separate circles is a stack of separate circles. The first is fair weather
   * with shoulders; the second is the flatter, wider sheet that spreads under a
   * ceiling.
   */
  cloud: [
    'M -0.5 0.22 C -0.5 0.11 -0.41 0.03 -0.31 0.04 C -0.28 -0.1 -0.12 -0.18 0 -0.11 ' +
      'C 0.06 -0.22 0.24 -0.23 0.3 -0.1 C 0.42 -0.12 0.5 -0.02 0.47 0.1 ' +
      'C 0.5 0.14 0.5 0.22 0.46 0.22 Z',
    'M -0.5 0.13 C -0.49 0.05 -0.4 0 -0.3 0.01 C -0.25 -0.08 -0.09 -0.11 0 -0.04 ' +
      'C 0.1 -0.12 0.28 -0.09 0.33 0.02 C 0.43 0.01 0.5 0.06 0.5 0.13 Z',
  ],
  /*
   * High ice, as two or three filaments dragged out nearly flat.
   *
   * Not a cloud with the lumps taken off - a different mark for a different
   * thing, and `render/Upper.ts` is why: above the weather, ice is being pulled
   * through air at two hundred knots, which smears it into lines. Drawn as
   * strokes rather than a fill so that they stay hairlines at any length, and
   * offset from each other rather than parallel, because a comb is a comb and
   * cirrus is not.
   *
   * The first has two filaments, the second three; between them and the size
   * range they are drawn at, no two streaks in the sky are the same object.
   */
  streak: [
    'M -0.5 -0.02 Q -0.08 -0.06 0.44 -0.035 M -0.34 0.05 Q 0.04 0.02 0.5 0.045',
    'M -0.5 -0.05 Q -0.1 -0.085 0.38 -0.06 M -0.44 0.005 Q 0 -0.03 0.5 -0.005 ' +
      'M -0.22 0.06 Q 0.1 0.035 0.46 0.055',
  ],
  /* Two arched wings and the body between them, which is the whole of a bird at
     this size. Stroked, because a filled one at seven units is a smudge. */
  bird: ['M -0.5 0.14 C -0.36 -0.12 -0.14 -0.14 0 0.07 C 0.14 -0.14 0.36 -0.12 0.5 0.14'],
  /* A star is a disc. Magnitude is the size of it and nothing else. */
  star: ['M -0.5 0 A 0.5 0.5 0 1 0 0.5 0 A 0.5 0.5 0 1 0 -0.5 0 Z'],
  /*
   * A coaster in profile, and the one drawing in this file whose origin is not
   * its middle: `y = 0` is the top of the water, because that is where the mark
   * is placed. Everything is above it, and the keel is *on* it.
   *
   * Which is the whole of the second draft. The first put a third of the hull
   * under the line, on the argument that a floating thing displaces water and a
   * drawing that says so is the honest one. On a screen it is not: the sea is a
   * one-pixel stroke drawn over this one - `Shell` puts the horizons last,
   * because a horizon with something in front of it is not a horizon - so what
   * the picture actually showed was a bright line ruled straight through a boat.
   * A hull cut in half by a hairline does not read as displacement. It reads as a
   * mistake, and it reads that way at every size the map is drawn at. Sat on the
   * line instead, the two strokes coincide along the keel and the sea holds the
   * boat up, which is what was wanted from the displacement in the first place.
   *
   * The sea got its swell after that, and the same rule survives it because the
   * mark is placed on the crests rather than on the mean - see `bandAt`. The
   * keel is level and the water under it is not, so the hull touches at the
   * crests it spans and the troughs fall away beneath it, which is what a small
   * boat on a ripple does.
   *
   * Three parts: a hull with a raked bow to the right, a wheelhouse set aft of
   * amidships - which is what makes it a working boat rather than a dinghy with a
   * box on it - and one mast. The mast is the part that does the reading.
   *
   * `tall` is twice the mast rather than the height of the drawing, and that is
   * deliberate. The keep-out is a box about the origin, and the origin here is
   * the waterline rather than the middle - so the only honest number is the one
   * that reaches as far down as the tallest thing reaches up, and it costs
   * nothing but a few units of water nothing was ever going to be drawn in.
   */
  boat: [
    'M -0.42 -0.15 L 0.5 -0.15 L 0.32 0 L -0.36 0 Z ' +
      'M -0.26 -0.15 L -0.26 -0.29 L 0.02 -0.29 L 0.02 -0.15 ' +
      'M -0.12 -0.29 L -0.12 -0.42',
  ],
  /*
   * ...and the one built thing in the picture: a body, a spar each side, two
   * panels with their ribs, and a dish on a mast.
   *
   * Drawn hard and square on purpose. Everything else in this world is a curve -
   * three arcs of a planet, cloud, wings, fish - so the one object that was
   * *made* is the one object with corners on it, and it reads as machinery
   * before it is looked at.
   */
  satellite: [
    'M -0.11 -0.055 L 0.11 -0.055 L 0.11 0.265 L -0.11 0.265 Z ' +
      'M -0.11 0.105 L -0.2 0.105 M 0.11 0.105 L 0.2 0.105 ' +
      'M -0.2 -0.035 L -0.5 -0.035 L -0.5 0.245 L -0.2 0.245 Z ' +
      'M 0.2 -0.035 L 0.5 -0.035 L 0.5 0.245 L 0.2 0.245 Z ' +
      'M -0.4 -0.035 L -0.4 0.245 M -0.3 -0.035 L -0.3 0.245 ' +
      'M 0.3 -0.035 L 0.3 0.245 M 0.4 -0.035 L 0.4 0.245 ' +
      'M 0 -0.055 L 0 -0.175 M -0.09 -0.175 A 0.09 0.09 0 0 1 0.09 -0.175',
  ],
};
