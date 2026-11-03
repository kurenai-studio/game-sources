import { ACT_COUNT, CAMPAIGN } from '../config/campaign';
import { clamp } from '../core/math';

/**
 * Slowblue: the circuit, as a line with stops on it.
 *
 * Everything about this campaign is stated in words on the title screen - seven
 * acts, one circuit, from the floor of the trench back to it - and for a long
 * time nothing in the shipped build ever *showed* it. It has been drawn four
 * ways now: as an act list, which makes a round trip look like a ladder; as a
 * dial, which is true about the order and silent about everything else; as a
 * cross-section of the world with a hairline through it, which was a diagram
 * wearing an illustration; and as a stack of platforms, which was an
 * illustration wearing a diagram.
 *
 * This is a transit line. Forty-two stops on one closed route, drawn the way
 * every underground in the world draws itself, because that grammar was invented
 * for exactly this problem and nothing has beaten it since: a line of constant
 * weight, stops at a constant interval with a wider one where one service hands
 * over to the next, corners at one radius, and the names set beside the line
 * rather than on it.
 *
 * ## The shape, and why it is that shape
 *
 * A rounded rectangle stood on end. The route climbs the left side, crosses the
 * top, comes down the right and closes along the bottom - so the picture keeps
 * the one thing the tower and the cross-section were both for: **up is up**. The
 * trench floor is at the bottom, orbit is across the top, and the two ends of the
 * journey meet along the bottom edge, because act I station 1 and act VII station
 * 6 are the same six-thousand-metre trench floor.
 *
 * The campaign is also a palindrome, and the shape says so without being told:
 * act I and act VII sit at the same height on opposite sides, and so do II and
 * VI, and III and V. Act IV is across the top on its own, because the turn is a
 * place that is only visited once.
 *
 * ## What is *not* here
 *
 * No weather, no strata, no picture of what any station looks like. A map that
 * draws what a place looks like is competing with the game, which draws it for
 * real and for four minutes at a time. What a map is for is where things are,
 * which of them are behind you, and how to get to the next one.
 *
 * ## What this file is in
 *
 * Box units: a `MAP_W` by `MAP_H` picture with `y` growing downward, which is
 * what SVG wants, and one number - `t`, the distance travelled round the route -
 * that everything on the line is placed by. The shell sets that box as its
 * `viewBox` and adds nothing.
 *
 * It is deliberately pure and deliberately DOM-free. The shell draws SVG out of
 * it; a test reads the same numbers.
 */

/**
 * The box every number in this file is in.
 *
 * It is wider than the route by a long way, and all of that is the names. The
 * box was three hundred and twenty units for a while, which is a shape that
 * suits the route and starves the type: the picture is drawn to fit the height
 * of a phone, so a box unit lands somewhere near nine tenths of a pixel, and an
 * act's name set at nine and a half units came out at eight pixels with its
 * altitudes under it at six. Nobody reads six pixels. They were not small
 * because the type was set small; they were small because there was nowhere for
 * them to be bigger.
 *
 * So the box grew and the route did not. The extra sixty-four units are gutter,
 * split unevenly - the right-hand names are the long ones - and the type spends
 * every one of them.
 */
export const MAP_W = 384;
export const MAP_H = 480;

/**
 * The route, as a rounded rectangle stood on end.
 *
 * Its width is the width of the line and nothing else: six stops across the top
 * at `STOP_STEP`, plus the two corners. What decides where it *sits* is the
 * names - an act's name is set outside the line on the side its stops are on,
 * and the longest of them, "The Homecoming", is act VII and therefore on the
 * right. So the route stands left of the middle of the box, far enough left
 * that the widest word on the right still clears the edge and no further, since
 * every unit given to one gutter is taken from the other.
 *
 * The height is everything the box has, less the room the top label needs.
 */
const LEFT_X = 120;
const RIGHT_X = 246;
const TOP_Y = 62;
const CORNER = 20;
/**
 * ...and the run the circuit closes along, which is the only one of the four
 * anything outside this file has ever needed.
 *
 * It is the trench floor. Act I station 1 and act VII station 6 are the same six
 * thousand metres of water and this is the height they are both at, so a world
 * that wants to put rock under the route has to put it here and nowhere else.
 */
export const BOTTOM_Y = 442;

/** The four runs of it, in the order the route travels them. */
const SIDE = BOTTOM_Y - TOP_Y - 2 * CORNER;
const CROSS = RIGHT_X - LEFT_X - 2 * CORNER;
const BEND = (Math.PI * CORNER) / 2;

/** Once round. Every stop, every act and every link is a range of this. */
export const ROUTE_LENGTH = 2 * SIDE + 2 * CROSS + 4 * BEND;

/**
 * The gap between two stops of the same act, everywhere on the route.
 *
 * One interval, not one per run: a line whose stops bunch up on the corners and
 * spread out on the straights is a line that looks like it means something by it.
 * Eighteen stops fit the side and six fit the top at the same spacing, which is
 * not a coincidence - it is what `LEFT_X` and `RIGHT_X` were chosen for.
 */
export const STOP_STEP = 16;

/**
 * ...and the extra distance where one act hands over to the next.
 *
 * The line used to run all forty-two stops at one interval, which is correct
 * about the journey and useless about its parts: seven acts drawn as one
 * unbroken chain of beads read as one act with forty-two stations in it, and the
 * names beside the line were the only thing saying otherwise. A boundary is now
 * more than twice an ordinary interval, so the stops fall into seven groups
 * before anything is read - which is what every transit map in the world does at
 * the point where one service ends and another begins.
 *
 * It is spacing rather than a break: the line itself is continuous, because the
 * journey is.
 */
export const ACT_GAP = 21;

/** One authored station, as a stop on the line. */
export interface AtlasStation {
  /** Index into `CAMPAIGN`. */
  act: number;
  /** Station index inside that act. */
  station: number;
  /** Index into the whole campaign, 0..`TOTAL_STATIONS` - 1. */
  index: number;
  /** The level's own key. */
  key: string;
  /** Straight off the level: metres below the sea, negative for height above it. */
  depthMeters: number;
  /** How far round the route it stands. */
  t: number;
}

/** One act, as a stretch of the line. */
export interface AtlasAct {
  /** Index into `CAMPAIGN`. */
  act: number;
  /** Index of its first station into `CIRCUIT_ATLAS`, and how many it has. */
  first: number;
  count: number;
  /** The stretch it owns, from its first stop to its last. */
  from: number;
  to: number;
  /** Which run of the route it is on: -1 climbing, 0 across the top, 1 coming home. */
  side: -1 | 0 | 1;
  /** Where its name is set, and how the type is anchored there. */
  labelX: number;
  labelY: number;
  anchor: 'start' | 'middle' | 'end';
  /** The altitudes it covers, as the map prints them. */
  range: string;
  /**
   * The rectangle that picks this act, in the same box as everything else here.
   *
   * The seven acts used to be chosen from a strip of numerals under the picture,
   * which is a second copy of the map with the map taken out of it: seven equal
   * targets that say nothing about where the acts are, sitting under a drawing
   * whose whole subject is where the acts are. Now the picture is the control,
   * and this is the part of it each act answers to - its stretch of line and the
   * name beside it, taken together.
   *
   * The seven do not overlap, which is what `ACT_GAP` bought: the spacing that
   * separates the groups of stops is the same spacing that keeps a thumb aimed
   * at act II out of act I.
   */
  hit: { x: number; y: number; w: number; h: number };
}

/**
 * A stretch of line between two acts.
 *
 * Seven of them for seven acts, because the last one joins act VII back to act I
 * along the bottom of the picture - and that is not a loose end being tidied up,
 * it is the circuit closing. It lights when the act behind it is finished, like
 * every other link, which means the bottom of the map is dark until somebody has
 * actually been all the way round.
 */
export interface AtlasLink {
  from: number;
  to: number;
  /** The stretch it covers. `to` may run past `ROUTE_LENGTH`; the point wraps. */
  fromT: number;
  toT: number;
  /** True for the one that closes the circuit. */
  closes: boolean;
}

/**
 * A point on the route, `t` units along it from the bottom of the left side.
 *
 * Eight pieces: four runs and four corners, in travelling order. Nothing outside
 * this function needs to know the route is a rectangle.
 */
export function routePoint(t: number): { x: number; y: number } {
  let s = ((t % ROUTE_LENGTH) + ROUTE_LENGTH) % ROUTE_LENGTH;
  if (s < SIDE) return { x: LEFT_X, y: BOTTOM_Y - CORNER - s };
  s -= SIDE;
  if (s < BEND) {
    const a = (s / BEND) * (Math.PI / 2);
    return {
      x: LEFT_X + CORNER * (1 - Math.cos(a)),
      y: TOP_Y + CORNER - CORNER * Math.sin(a),
    };
  }
  s -= BEND;
  if (s < CROSS) return { x: LEFT_X + CORNER + s, y: TOP_Y };
  s -= CROSS;
  if (s < BEND) {
    const a = (s / BEND) * (Math.PI / 2);
    return {
      x: RIGHT_X - CORNER + CORNER * Math.sin(a),
      y: TOP_Y + CORNER * (1 - Math.cos(a)),
    };
  }
  s -= BEND;
  if (s < SIDE) return { x: RIGHT_X, y: TOP_Y + CORNER + s };
  s -= SIDE;
  if (s < BEND) {
    const a = (s / BEND) * (Math.PI / 2);
    return {
      x: RIGHT_X - CORNER + CORNER * Math.cos(a),
      y: BOTTOM_Y - CORNER + CORNER * Math.sin(a),
    };
  }
  s -= BEND;
  if (s < CROSS) return { x: RIGHT_X - CORNER - s, y: BOTTOM_Y };
  s -= CROSS;
  const a = (s / BEND) * (Math.PI / 2);
  return {
    x: LEFT_X + CORNER - CORNER * Math.sin(a),
    y: BOTTOM_Y - CORNER + CORNER * Math.cos(a),
  };
}

/** A stretch of the route, sampled. The corners are why this is not two points. */
export function routeCurve(from: number, to: number): { x: number; y: number }[] {
  const steps = Math.max(2, Math.ceil(Math.abs(to - from) / 4) + 1);
  const out: { x: number; y: number }[] = [];
  for (let i = 0; i < steps; i++) out.push(routePoint(from + ((to - from) * i) / (steps - 1)));
  return out;
}

/**
 * Which way the route is travelling at `t`, in degrees, `0` pointing right.
 *
 * Read off the line rather than worked out from which piece of it `t` lands in:
 * a unit either side and the angle between them, which is one expression for all
 * eight pieces and cannot disagree with `routePoint` about where the line goes.
 * Over a unit of a twenty-unit corner that is three degrees of chord, which is
 * far less than the eye can see in an arrowhead.
 */
export function routeHeading(t: number): number {
  const a = routePoint(t - 0.5);
  const b = routePoint(t + 0.5);
  return (Math.atan2(b.y - a.y, b.x - a.x) * 180) / Math.PI;
}

/**
 * Where a handover is arrowed, and which way the arrow points.
 *
 * The picture says which way round the journey goes in the order of the acts and
 * in nothing else, which is an order you have to already know the acts to read.
 * So the line is arrowed - and the seams are where, because a seam is the one
 * stretch of line with no stop on it: the arrow lands in a gap that was already
 * empty, midway between the last stop of one act and the first of the next,
 * eighteen units clear of either.
 *
 * Seven of them for seven handovers, so the direction is stated once per act all
 * the way round rather than in one place the eye may not land on - and the
 * seventh is the closing seam along the bottom, which is the one that says the
 * route comes back rather than stopping.
 */
export function linkArrow(link: AtlasLink): { x: number; y: number; angle: number } {
  const t = (link.fromT + link.toT) / 2;
  return { ...routePoint(t), angle: routeHeading(t) };
}

/**
 * Which run of the route an act is on: -1 climbing, 0 across the top, 1 home.
 *
 * The middle act is the turn and is across the top on its own, because the turn
 * is a place that is only visited once; everything before it climbs and
 * everything after it comes down. Derived rather than written out, so the
 * picture follows the campaign if an act is ever added at either end of it.
 */
const TURN_ACT = Math.floor(ACT_COUNT / 2);
function runOf(act: number): -1 | 0 | 1 {
  return act < TURN_ACT ? -1 : act > TURN_ACT ? 1 : 0;
}

/** Where each run begins, and how much line it has to give. */
function runStart(side: -1 | 0 | 1): number {
  return side === -1 ? 0 : side === 0 ? SIDE + BEND : SIDE + 2 * BEND + CROSS;
}
function runLength(side: -1 | 0 | 1): number {
  return side === 0 ? CROSS : SIDE;
}

/**
 * How far along the route every stop stands, laid out one run at a time.
 *
 * Each run is centred on its own side, its acts are set down in play order at
 * `STOP_STEP`, and `ACT_GAP` is added wherever one act hands over to the next -
 * so the eighteen stops of the climb are three groups of six rather than one
 * chain of eighteen. Nothing is spaced across a corner: the bend is already
 * longer than any gap this file draws.
 */
const STOP_T: readonly number[] = (() => {
  const out: number[] = [];
  for (const side of [-1, 0, 1] as const) {
    const acts: number[] = [];
    for (let act = 0; act < ACT_COUNT; act++) if (runOf(act) === side) acts.push(act);
    const stops = acts.reduce((n, act) => n + CAMPAIGN[act]!.act.levels.length, 0);
    const span = (stops - 1) * STOP_STEP + (acts.length - 1) * ACT_GAP;
    let t = runStart(side) + (runLength(side) - span) / 2;
    for (const act of acts) {
      for (let i = 0; i < CAMPAIGN[act]!.act.levels.length; i++, t += STOP_STEP) out.push(t);
      t += ACT_GAP;
    }
  }
  return out;
})();

/** How far along the route the station with this index stands. */
function stopT(index: number): number {
  return STOP_T[index] ?? 0;
}

/**
 * How far an act reaches, written the way the map prints it.
 *
 * One unit for both ends, chosen by the bigger of them, because "0.06 → 11 KM"
 * is not a thing anybody says about the height of a cloud - and kilometres only
 * where the act actually leaves the water, because a trench is six thousand
 * metres deep and has never once been six kilometres deep. Read off the levels
 * rather than authored, so it cannot drift from the campaign.
 */
function rangeOf(act: number): string {
  const levels = CAMPAIGN[act]!.act.levels;
  const a = levels[0]!.depthMeters;
  const b = levels[levels.length - 1]!.depthMeters;
  const km = Math.min(a, b) < 0 && Math.max(Math.abs(a), Math.abs(b)) >= 1000;
  const show = (m: number): number => (km ? Math.round(Math.abs(m) / 1000) : Math.abs(m));
  return `${show(a)} → ${show(b)} ${km ? 'KM' : 'M'}`;
}

/** The forty-two stops, placed. Built once; nothing mutates it. */
export const CIRCUIT_ATLAS: readonly AtlasStation[] = (() => {
  const stops: AtlasStation[] = [];
  let index = 0;
  for (let act = 0; act < ACT_COUNT; act++) {
    const levels = CAMPAIGN[act]!.act.levels;
    for (let station = 0; station < levels.length; station++, index++) {
      const level = levels[station]!;
      stops.push({
        act,
        station,
        index,
        key: level.key,
        depthMeters: level.depthMeters,
        t: stopT(index),
      });
    }
  }
  return stops;
})();

/** How far the name of an act is set from the line it names. */
const LABEL_GAP = 12;

/**
 * How far a target reaches past the stops it is for.
 *
 * Half a gap along the line, so the seven meet without overlapping and every
 * point of the picture that belongs to an act is inside that act's target.
 *
 * The turn gets more, and needs it: six stops across the top is a stretch two
 * hundred units wide and none tall, and the shortest viewport the map is drawn
 * in would leave it under the forty-four pixels a control is allowed to be. It
 * takes the room out of the space above the line, where its own name is, and
 * still clears the acts either side of it - which is asserted rather than
 * eyeballed, because it is four and a half units of clearance.
 */
const HIT_PAD = ACT_GAP / 2;
const TURN_PAD = 18;

/** The seven acts, as seven stretches of the line, with their names placed. */
export const CIRCUIT_ACTS: readonly AtlasAct[] = (() => {
  const bands: AtlasAct[] = [];
  let first = 0;
  for (let act = 0; act < ACT_COUNT; act++) {
    const count = CAMPAIGN[act]!.act.levels.length;
    const from = CIRCUIT_ATLAS[first]!.t;
    const to = CIRCUIT_ATLAS[first + count - 1]!.t;
    const mid = routePoint((from + to) / 2);
    const side = runOf(act);
    // Across the top the name goes above the line and reads across it; up the
    // sides it goes outside, and the type turns its back on the line.
    const labelY = side === 0 ? TOP_Y - 26 : mid.y;
    const a = routePoint(from);
    const b = routePoint(to);
    const top = Math.min(a.y, b.y);
    const bottom = Math.max(a.y, b.y);
    // The target is the act's own quarter of the picture: on the sides, the
    // whole width from the outer edge of the names to just past the line; across
    // the top, the six stops and the name above them.
    const hit =
      side === 0
        ? {
            x: Math.min(a.x, b.x) - HIT_PAD,
            y: labelY - TURN_PAD,
            w: Math.abs(b.x - a.x) + 2 * HIT_PAD,
            h: TOP_Y + TURN_PAD - (labelY - TURN_PAD),
          }
        : {
            x: side === -1 ? 4 : RIGHT_X - 14,
            y: top - HIT_PAD,
            w: side === -1 ? LEFT_X + 14 - 4 : MAP_W - 4 - (RIGHT_X - 14),
            h: bottom - top + 2 * HIT_PAD,
          };
    bands.push({
      act,
      first,
      count,
      from,
      to,
      side,
      labelX: side === -1 ? LEFT_X - LABEL_GAP : side === 1 ? RIGHT_X + LABEL_GAP : mid.x,
      labelY,
      anchor: side === -1 ? 'end' : side === 1 ? 'start' : 'middle',
      range: rangeOf(act),
      hit,
    });
    first += count;
  }
  return bands;
})();

/** The seven links, the last of which is the circuit closing along the bottom. */
export const ATLAS_LINKS: readonly AtlasLink[] = (() => {
  const links: AtlasLink[] = [];
  for (let act = 0; act < ACT_COUNT; act++) {
    const to = (act + 1) % ACT_COUNT;
    const closes = to === 0;
    links.push({
      from: act,
      to,
      fromT: CIRCUIT_ACTS[act]!.to,
      toT: CIRCUIT_ACTS[to]!.from + (closes ? ROUTE_LENGTH : 0),
      closes,
    });
  }
  return links;
})();

/**
 * The two skins of the world, and how much of a globe they are allowed to be.
 *
 * Two of the seven acts are under the sea - the first and the last - and one is
 * outside the air: act IV, which is a hundred and forty to four hundred and
 * sixty kilometres up. Nothing in the drawing said so. Forty-two identical stops
 * ran past seven names, and a player had to read "6000 → 0 M" against
 * "0 → 11 KM" against "140 → 460 KM" to work out that the route starts in water,
 * leaves it, and later leaves the air as well.
 *
 * So the world is drawn behind the line, as the two surfaces the route crosses:
 * the sea, and the top of the air. They are curved because they are the skins of
 * a planet, and they are concentric because they are skins of the *same* planet
 * - one centre, two radii, which is the whole of what this file knows about the
 * shape of the world and is enough to place a route on it.
 *
 * Neither is labelled. A caption saying SEA LEVEL over an arc with water under
 * it is a drawing that does not trust itself; what says it instead is the water
 * - a filled band under the lower arc, with the trench and the homecoming in it
 * - and the dark above the upper one, with orbit in it. Two colours and two
 * curves, and the picture is doing the talking.
 *
 * ## Why this half of the file is in pixels
 *
 * Everything above is in box units, because the route is a fixed drawing and the
 * box is what it is drawn in. The world is not: it is behind the whole screen,
 * edge to edge, and a screen is whatever size it is. Drawn inside the box, the
 * water stopped where the picture stopped - two vertical rules down the map and
 * two horizontal ones across it - and a world with a frame around it is a
 * diagram of a world rather than the thing the route is standing on.
 *
 * So the surfaces take a frame: where the box landed on the screen and how big
 * it was drawn, and how much screen there is to fill. The route's rails still
 * decide the two heights; the screen decides everything else.
 */

/** Where the route leaves the water, and comes back to it. In box units. */
export const SEA_Y = (() => {
  const cross = (act: number): number => {
    const a = CIRCUIT_ACTS[act];
    const b = CIRCUIT_ACTS[act + 1];
    if (a === undefined || b === undefined) return BOTTOM_Y;
    return routePoint((a.to + b.from) / 2).y;
  };
  // Going up out of the water between act I and act II, back into it between act
  // VI and act VII. They are the same height by construction; averaged so that
  // they stay one waterline if the campaign ever stops being symmetric.
  return (cross(0) + cross(ACT_COUNT - 2)) / 2;
})();

/**
 * ...and where it leaves the air.
 *
 * Half a stop above the highest stop on the sides, which is where the climb ends
 * - and the climb ends at exactly a hundred kilometres, because act III is "the
 * thinning" and a hundred kilometres is where the air is agreed to have stopped.
 * So on the way up this line is drawn where the campaign actually crosses it,
 * to the metre.
 *
 * On the way down it is a claim about acts rather than about metres: the fall
 * starts at three hundred and eighty kilometres, so act V's first stops are
 * still outside the air the picture puts them inside of. That is the cost of one
 * arc at one height on a map whose two sides are not the same scale - the climb
 * spends eighteen stops getting to a hundred kilometres and the fall spends two
 * coming back from four hundred - and it is the right cost to pay: the line the
 * player reads off this map is "orbit is the act that is outside", which is
 * true, and the alternative is a boundary that is wrong on both sides instead of
 * one.
 */
export const SPACE_Y = (() => {
  const sides = CIRCUIT_ATLAS.filter((s) => CIRCUIT_ACTS[s.act]?.side !== 0);
  const top = Math.min(...sides.map((s) => routePoint(s.t).y));
  return (top + TOP_Y + CORNER) / 2;
})();

/** The middle of the route's two rails, which the world is symmetric about. */
const GLOBE_X = (LEFT_X + RIGHT_X) / 2;
/** Half the distance between them: the two places a surface has to be exact. */
const RAIL_HALF = (RIGHT_X - LEFT_X) / 2;

/**
 * How far the horizon falls from the middle of the screen to the side of it, as
 * a fraction of the width it has to cross.
 *
 * A fraction rather than a radius, because a radius is only a curve once you
 * know how much of it you are looking at: five hundred units of radius reads as
 * a horizon across a phone and as a beach ball across a desktop. Six per cent is
 * the width of the band this can live in - flatter and it is a rule ruled across
 * the screen, which says the sea is a level and not a surface; rounder and there
 * is a ball behind the map, which turns the picture back into the cross-section
 * it stopped being on purpose.
 */
const WORLD_SAG = 0.06;

/**
 * Where the box ended up on the screen, and how much screen there is around it.
 *
 * All of it in the same pixels - the ones `getBoundingClientRect` speaks, so the
 * caller measures rather than computes and nothing here needs to know how the
 * shell lays a screen out.
 */
export interface WorldFrame {
  /** Pixels to a box unit: how big the map is being drawn. */
  scale: number;
  /** Where box unit (0, 0) sits. */
  x: number;
  y: number;
  /** The picture the world has to fill, from (0, 0). */
  width: number;
  height: number;
}

/**
 * Where the centre of this world is, in the frame's own pixels.
 *
 * Struck from the waterline, because that is the surface the sag is quoted
 * about and the one the eye reads as *the* horizon. Everything else about the
 * world is measured from here, which is what keeps the two surfaces concentric:
 * one centre, two radii, two skins of the same planet.
 */
function globeCentre(frame: WorldFrame): { x: number; y: number } {
  // sagitta = w² / 8r, solved for the sag this world is allowed - and never
  // tighter than the rails it has to pass through, or there is no circle at all.
  const half = RAIL_HALF * frame.scale;
  const r = Math.max(frame.width / (8 * WORLD_SAG), half * 2);
  return {
    x: frame.x + GLOBE_X * frame.scale,
    y: frame.y + SEA_Y * frame.scale + Math.sqrt(r * r - half * half),
  };
}

/** How far the surface that meets the rails at `railY` is from that centre. */
export function worldRadius(frame: WorldFrame, railY: number): number {
  const centre = globeCentre(frame);
  return Math.hypot(centre.y - (frame.y + railY * frame.scale), RAIL_HALF * frame.scale);
}

/** Where that surface stands, at this `x` across the screen. */
export function worldY(frame: WorldFrame, railY: number, x: number): number {
  const centre = globeCentre(frame);
  const r = worldRadius(frame, railY);
  const dx = x - centre.x;
  return centre.y - Math.sqrt(Math.max(0, r * r - dx * dx));
}

/**
 * The swell: how far the sea leaves its own circle, and how often.
 *
 * Two of this world's three surfaces are agreements and one of them is water.
 * The trench floor is rock and the top of the air is a number somebody settled
 * on - a hundred kilometres, which is why it is drawn dashed - and both of those
 * are honestly a smooth curve. The sea is not. It is the only surface here that
 * is a *substance with a top*, and the only one anything floats on, and drawn as
 * a clean circular arc it read as the third of three tone boundaries rather than
 * as the one the boat is sitting on.
 *
 * So it gets a ripple, and a small one: about a unit of rise on a fourteen-unit
 * wave, which at the size the map is drawn is a line that is visibly not
 * straight and is nowhere near a drawing of waves. There is a real ceiling on
 * this and it is not taste - the arc runs the whole width of the screen behind
 * forty-two stops and seven names, and a swell big enough to be a *shape* is a
 * texture competing with the map. What is wanted is the smallest deviation that
 * says "water", which is roughly the point at which the eye stops reading the
 * line as ruled.
 *
 * In box units, like everything else the picture owns rather than the screen:
 * the boat that rests on this line is thirty-two of them, so the two keep their
 * proportion to each other at every size the map is drawn at.
 */
const SWELL_RISE = 1.15;
const SWELL_RUN = 14;

/** How far the crests of that swell stand above the mean surface, in pixels. */
export function swellRise(frame: WorldFrame): number {
  return SWELL_RISE * frame.scale;
}

/**
 * ...and the height of the water at its highest, at this `x`.
 *
 * What anything floating is placed on. A hull put on the mean line would have
 * the crests drawn straight through it, which is the one thing the surface's own
 * stroke must never do to the one object standing on it - so the boat rides the
 * crests instead, and the troughs fall away underneath it. Any span of hull as
 * long as a wave meets a crest whatever the phase, so it is resting rather than
 * hovering.
 */
export function seaCrestY(frame: WorldFrame, x: number): number {
  return worldY(frame, SEA_Y, x) - swellRise(frame);
}

/**
 * How much swell a surface has, which is none unless it is the sea.
 *
 * Compared against `SEA_Y` by identity, and that is sound rather than lucky:
 * `SEA_Y` is a module constant and every caller passes the constant itself.
 */
function swellOf(frame: WorldFrame, railY: number): number {
  return railY === SEA_Y ? swellRise(frame) : 0;
}

/**
 * One surface across the whole screen, as the commands that draw it, in either
 * direction and never as two different curves.
 *
 * Forward for a face and for the top of a band; backwards for the underside of
 * the layer that closes against it. Both legs are generated here, from the same
 * numbers, because the moment the air's bottom edge and the water's top edge are
 * written out separately they are two curves that agree until they do not.
 *
 * A surface with no swell is a single circular arc with its sweep flag flipped
 * to come back - the same radius, the same ends, the identical curve travelled
 * the other way. Sampling that would have worked and would have put a polygon of
 * a circle underneath a circle, which shows at the edges of a wide screen.
 *
 * The sea is that circle cut into half-waves, each drawn as one quadratic whose
 * control point sits twice the rise off the arc, alternating. Three things fall
 * out of that construction and all three are why it is the construction:
 *
 *   - A quadratic reaches half way to its control point, so twice the rise
 *     gives exactly the rise.
 *   - Consecutive half-waves are smooth without being told to be. The tangent
 *     leaving a node is the reflection of the tangent arriving at it as long as
 *     the controls alternate about the curve, so the swell is a wave and not a
 *     row of scallops with corners between them.
 *   - It is symmetric in its own parameter, so the backward leg is the same
 *     quadratic with its ends swapped and its control untouched. Exactly, not
 *     nearly.
 *
 * Which half-wave is a crest is counted from the left edge of the screen and
 * never from the direction of travel, for that last reason: a crest at some `x`
 * has to be a crest on both legs.
 */
function surfaceRun(frame: WorldFrame, railY: number, back: boolean): string {
  const rise = swellOf(frame, railY);
  const at = (x: number): string => `${x.toFixed(2)} ${worldY(frame, railY, x).toFixed(2)}`;
  if (rise <= 0) {
    const r = worldRadius(frame, railY).toFixed(2);
    return `A ${r} ${r} 0 0 ${back ? 0 : 1} ${at(back ? 0 : frame.width)}`;
  }
  const n = Math.max(2, Math.round(frame.width / (SWELL_RUN * frame.scale * 0.5)));
  // The last node is the edge of the screen itself rather than `n` steps of a
  // rounded step: a band closes against `frame.width`, and a hundredth of a
  // pixel short of it is a hairline of page down the side of the world.
  const node = (k: number): number => (k >= n ? frame.width : (k * frame.width) / n);
  const out: string[] = [];
  for (let i = 0; i < n; i++) {
    const j = back ? n - 1 - i : i;
    const mid = (node(j) + node(j + 1)) / 2;
    const lift = (j % 2 === 0 ? -2 : 2) * rise;
    const c = `${mid.toFixed(2)} ${(worldY(frame, railY, mid) + lift).toFixed(2)}`;
    out.push(`Q ${c} ${at(node(back ? j : j + 1))}`);
  }
  return out.join(' ');
}

/**
 * One surface, all the way across the screen, crossing the rails at `railY`.
 *
 * Struck as a circle rather than as a quadratic through three points, because
 * these are the horizons of a sphere and the two curves are not the same where
 * it matters - at the edges of the screen, which is the only place the eye can
 * tell. What the sea then does to that circle is `surfaceRun`'s business.
 */
export function worldFacePath(frame: WorldFrame, railY: number): string {
  return `M 0 ${worldY(frame, railY, 0).toFixed(2)} ${surfaceRun(frame, railY, false)}`;
}

/**
 * ...and the same surface as a band: everything on one side of it.
 *
 * `to` is the edge of the screen the band closes against - the bottom for the
 * water, the top for the dark. The band is what carries the meaning; the face on
 * top of it is only the edge the band happens to have.
 */
export function worldBandPath(frame: WorldFrame, railY: number, to: number): string {
  return `${worldFacePath(frame, railY)} L ${frame.width.toFixed(2)} ${to} L 0 ${to} Z`;
}

/**
 * ...and the layer between two of them, which is the one this file forgot.
 *
 * The water closed against the bottom of the screen and the dark against the top,
 * and the air in between was whatever those two left - which is to say it was the
 * page, and a band that is the absence of the other two is a band nobody can see
 * is a band. Three levels are only three levels if the middle one is also made of
 * something. So the air gets a skin of its own: the top surface forward, and the
 * bottom one run backwards to close the shape.
 *
 * Backwards is the whole of the trick, and it is `surfaceRun`'s to keep: the
 * underside of the air has to be the same curve as the top of the water, down to
 * the last crest, or the two bands disagree along the one line in this picture
 * the eye is already following.
 */
export function worldLayerPath(frame: WorldFrame, topRailY: number, bottomRailY: number): string {
  return (
    `${worldFacePath(frame, topRailY)} ` +
    `L ${frame.width.toFixed(2)} ${worldY(frame, bottomRailY, frame.width).toFixed(2)} ` +
    `${surfaceRun(frame, bottomRailY, true)} Z`
  );
}

/** Where an act is entered: the stop its line arrives at, and its link lands on. */
export function entryOf(act: number): AtlasStation | undefined {
  const band = CIRCUIT_ACTS[act];
  return band === undefined ? undefined : CIRCUIT_ATLAS[band.first];
}

/** Stations ever cleared, per act key. What the profile stores. */
export type StationRecord = Readonly<Record<string, number>>;

/**
 * How many stations of one act have ever been cleared. Clamped, never trusted.
 *
 * The record comes off disk, so a value that is not a number is a value this
 * function has to survive rather than one it may assume away - and `clamp` is not
 * that guard: `NaN` compares false against both ends and comes out the other side
 * still `NaN`, which would put an `r="NaN"` on every stop in the picture.
 */
export function clearedIn(stations: StationRecord, act: number): number {
  const info = CAMPAIGN[act];
  if (info === undefined) return 0;
  const stored = stations[info.act.key];
  if (typeof stored !== 'number' || !Number.isFinite(stored)) return 0;
  return clamp(Math.floor(stored), 0, info.act.levels.length);
}

/** True once this exact station has been cleared. Drives every filled stop. */
export function stationCleared(
  stations: StationRecord,
  point: { act: number; station: number },
): boolean {
  return point.station < clearedIn(stations, point.act);
}

/**
 * How far along its own stretch an act has been flown, or `null` for none of it.
 *
 * An act is cleared as a prefix - the profile stores a count, not a set - so the
 * lit part of a stretch always starts where the line arrives. It ends *at* the
 * last stop reached rather than past it, because the stop is the claim: that is
 * where the player got to.
 */
export function actFlownTo(stations: StationRecord, act: number): number | null {
  const band = CIRCUIT_ACTS[act];
  if (band === undefined) return null;
  const done = clearedIn(stations, act);
  if (done <= 0) return null;
  return CIRCUIT_ATLAS[band.first + Math.min(done, band.count) - 1]!.t;
}

/** True once a link has been earned: the act that leads into it is finished. */
export function linkFlown(stations: StationRecord, link: AtlasLink): boolean {
  const band = CIRCUIT_ACTS[link.from];
  return band !== undefined && clearedIn(stations, link.from) >= band.count;
}

/** Stations cleared across the whole circuit, out of `TOTAL_STATIONS`. */
export function stationsCleared(stations: StationRecord): number {
  let total = 0;
  for (let act = 0; act < ACT_COUNT; act++) total += clearedIn(stations, act);
  return total;
}

/** Acts finished outright - every station of them - out of `ACT_COUNT`. */
export function actsCleared(stations: StationRecord): number {
  let total = 0;
  for (let act = 0; act < ACT_COUNT; act++) {
    if (clearedIn(stations, act) >= CAMPAIGN[act]!.act.levels.length) total++;
  }
  return total;
}
