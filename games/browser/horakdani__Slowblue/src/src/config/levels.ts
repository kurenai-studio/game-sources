import {
  RESTART_ON_FAILURE,
  restartsForMinutes,
  type FailureMode,
  type FailurePolicy,
} from '../sim/Failure';
import type { LayerSpec } from '../sim/LayeredFlow';
import type { MediumKind } from './tuning';

/**
 * Slowblue: the campaign.
 *
 * The prototype generated an endless course from a seed. That is a good way to
 * prove a simulation and a bad way to teach one: nothing could be *authored*, so
 * no single moment could be made to land, and the generator could - and did -
 * place a ring behind a wall the shoal had no line to.
 *
 * A level is a hand-written list of sections. Every number here is deliberate and
 * every one is checked by `tests/levels.test.ts`: a flood fill proves each section
 * has a route through it, and a lateral-reach check proves the *next* thing the
 * player must be lined up with is reachable from the last one at the pace that
 * level runs at. Nothing in this file can ship an impossible obstacle.
 *
 * Coordinates are fractions of the play field's width, so a level looks the same
 * on every phone. `dy` values are in pixels along the course, positive = closer to
 * the player (met earlier), negative = further ahead.
 */

/** A ring of fish waiting to be absorbed. */
export interface RingSpec {
  /** Centre, as a fraction of width. */
  x: number;
  /** Offset from the section's line. Positive is met before the obstacle. */
  dy: number;
  count: number;
  /**
   * A dashed ring is a gate you must actually pass through: miss it and the dive
   * is over. Required rings are placed on the line the section already asks for,
   * never off it - the demand is "commit properly", never "guess".
   */
  required?: boolean;
  /** Ring radius multiplier. Required rings are drawn and sized more generously. */
  scale?: number;
}

/**
 * Slowblue: how a section's geometry moves, if it moves at all.
 *
 * Every obstacle in the first six acts stands still, so the whole difficulty of
 * this game is spatial: read the shape, lay the line, arrive. That is one axis,
 * and it was the only one - which is most of why the campaign stopped getting
 * harder after act II with sixty sections still to go.
 *
 * This is the second axis, and it is deliberately **a modifier rather than an
 * alphabet**. The first plan here was two new `kind`s per act - fourteen new
 * silhouettes, fourteen builders, fourteen sets of paint - and it was the wrong
 * shape twice over: it is a month of work, and it would have made "the gap
 * moves" a property of six specific rocks instead of a thing the game can say
 * about any of the seventy shapes it already draws. A pulsing `veil` in the
 * upper air and a walking `plume` in the plasma cost one line each now.
 *
 * Two rules hold the whole feature up, and both are tested:
 *
 *   1. **What is authored is the worst case.** An `aperture` is authored *shut* -
 *      `gap` is the narrowest the gap ever gets - and the motion only ever opens
 *      it. So the corridor sweep, which builds the course statically, is already
 *      checking the hardest phase without knowing anything about time. A moving
 *      obstacle cannot smuggle an impossible frame past the safety net.
 *   2. **A `drift` is swept.** Its authored position is the middle of its travel,
 *      so there is no single worst phase; `Section.envelope` carries the union of
 *      everywhere it ever is, and the sweep reads that instead. The guarantee is
 *      then stronger than it needs to be - there is a line past it whenever you
 *      arrive - which is the right side to err on.
 *
 * The clock is the *simulation's*, not the breath's. `World.breathTime` is
 * wall-clock (see its comment: it runs on over a pause, so the picture and the
 * bed never drift apart from the player's own breathing), and geometry driven by
 * it would move while the game was paused and would not replay from a seed. The
 * period is still the breath's eleven seconds, because that is the rate this
 * whole game is built at - it is the same rhythm arriving in a third sense.
 */
export interface MotionSpec {
  /**
   * `aperture`: the two sides of the section move apart and back together, so a
   * gap that is authored shut breathes open. The pivot is the geometry's own
   * centroid, which is why this belongs only on the shapes that are one wall
   * with one hole in it - a multi-door `sheet` or `flare` would push its outer
   * doors wide and pinch its middle one. `tests/motion.test.ts` holds that line.
   *
   * `drift`: the whole body walks sideways and back. One mass, one translation,
   * and the demand is the game's oldest one made literal - the line you laid
   * three seconds ago is not the line you are on, and now neither is the gap.
   */
  kind: 'aperture' | 'drift';
  /**
   * Peak excursion, as a fraction of the field width. An `aperture` opens by
   * twice this (each side takes half); a `drift` travels this far either way.
   */
  reach: number;
  /** Seconds per cycle. Defaults to the breath's eleven. */
  period?: number;
  /**
   * Where in the cycle this section starts, in turns: 0 is the authored phase,
   * 0.5 is exactly against it.
   *
   * Left out, a moving section takes a phase derived from where it is on the
   * course, so no two of them are ever in step and none of them is memorisable.
   * That is the right default and it makes one thing impossible: **two sections
   * moving against each other.** A mass walking left while the mass 400 px
   * behind it walks right is a channel that opens and closes, and it is the only
   * demand in the campaign that cannot be answered by picking a line and holding
   * it - you have to pick the line the pair will make, and there is no phase at
   * which both are where you last saw them.
   *
   * Authoring the phase also makes the section *learnable*, which is the point:
   * a hazard on a clock you can read is a demand, and a hazard on a clock you
   * cannot is a slot machine. The pair below is on the breath, like everything
   * else in this game, so the clock is one the player is already breathing.
   */
  phase?: number;
}

interface SpecBase {
  rings?: RingSpec[];
  /** Distance from the previous section. Defaults to `SECTION_SPACING`. */
  spacing?: number;
  /** How this section's geometry moves. Absent everywhere the world stands still. */
  motion?: MotionSpec;
}

/**
 * A hunter placed by hand: where it waits, how big it is, and whether it comes
 * from in front or from behind.
 */
interface HunterSpec {
  x: number;
  dy: number;
  size: number;
  /**
   * A stooping hunter: it enters from *behind* and overtakes. Every threat in
   * act I arrives from the direction the shoal is already facing; a raptor does
   * not, which is the point of it. See `PredatorSystem` and DESIGN-ASCENT §4.
   */
  stoop?: boolean;
}

/**
 * Slowblue: two alphabets, one grammar.
 *
 * The first six kinds are the water's, and they are the shapes rock makes: a wall
 * with a hole in it, a mass to split on, a funnel, a chicane, a standing current,
 * a hunter. The last six are the air's, and **none of them is one of the water's
 * with a different colour on it** - that was the single loudest thing wrong with
 * the first act II, where a cloud-belt gate arrived as the same chain of beads the
 * trench floor is built from.
 *
 * Cloud is not rock and does not make rock's shapes. It piles into towers, spreads
 * into decks with holes torn in them, tears into scattered fractus, and stands
 * still in a lens over a rotor. So the air gets its own six, and the mapping
 * between the two alphabets is a mapping of *demands* rather than of silhouettes:
 *
 * | water     | air      | what it asks for                              |
 * | --------- | -------- | --------------------------------------------- |
 * | `gate`    | `bank`   | commit to one gap, early                      |
 * | `rock`    | `tower`  | split the body and re-form it                 |
 * | `narrows` | `pass`   | hold a narrow line under converging walls     |
 * | `drift`   | `wisps`  | three lines in a row, no time to settle       |
 * | `vortex`  | `rotor`  | spend the medium on the medium                |
 * | `predator`| `raptor` | keep a shape while something hunts it         |
 *
 * Geometry for all six is in `ObstacleSystem.build*Cloud`; the paint that makes
 * them cloud rather than pale stone is `Motif.material` and `RockPaint`.
 */
export type SectionSpec = SpecBase &
  (
    | { kind: 'open' }
    | { kind: 'gate'; centre: number; gap: number }
    | { kind: 'rock'; centre: number; radius: number; teeth?: boolean }
    | { kind: 'narrows'; centre: number; gap: number; mouth?: number; depth?: number }
    | { kind: 'drift'; gap: number; rows: number; swing: number; first?: -1 | 1 }
    | {
        kind: 'vortex';
        centre: number;
        gap: number;
        radius: number;
        spin: -1 | 1;
        strength: number;
      }
    | { kind: 'predator'; centre: number; radius: number; hunters: HunterSpec[] }
    // --- act II: the air. Cloud, in the shapes cloud actually takes. ---
    /** A cumulus deck across the course with one hole torn in it. */
    | { kind: 'bank'; centre: number; gap: number; depth?: number }
    /**
     * One towering cumulus, taller than it is wide, with a channel either side.
     * The air's splittable mass - see `SPLITTABLE` in `World.ts`.
     */
    | { kind: 'tower'; centre: number; radius: number; height?: number }
    /** Two cloud shoulders converging into a slot, entered from below. */
    | { kind: 'pass'; centre: number; gap: number; mouth?: number; depth?: number }
    /** Torn fractus in staggered rows: two or three committed lines, no rest. */
    | { kind: 'wisps'; gap: number; rows: number; swing: number; first?: -1 | 1 }
    /**
     * A lenticular cloud standing over its own rotor. The lens is the marker and
     * the rotor is the hazard, which is the whole reason a lenticular is the one
     * cloud pilots are taught to read from a distance.
     */
    | {
        kind: 'rotor';
        centre: number;
        gap: number;
        radius: number;
        spin: -1 | 1;
        strength: number;
      }
    /**
     * A cloud street: two long lines of cloud running *along* the course with a
     * corridor between them, entered through a short mouth.
     *
     * Slowblue: the one archetype in the campaign that is not an aperture.
     *
     * Everything else on the course is a hole to be at the x of when the centroid
     * crosses one line - the demand is over in a frame, and how long the geometry
     * lasts is scenery. A street reverses that: the mouth is generous, and then
     * the flock has to *stay* somewhere for six or seven hundred pixels while
     * `AmbientFlow` pushes it sideways twice. Nothing before it has asked for a
     * held line rather than a placed one, and only the air can ask: a cloud street
     * is what a soaring bird actually crosses country on, and it is the single
     * reason a glider can fly five hundred kilometres without circling once.
     *
     * It replaces `pass` in act II rather than joining it. `pass` is the same
     * "hold a line" demand compressed into 240 px, and an act with two names for
     * one thing is exactly the complaint this pass is answering.
     *
     * `length` is how far the corridor runs, in px along the course. The section's
     * line sits at the *exit*, so the whole street is behind the flock by the time
     * it is scored - see `ObstacleSystem.prune`, which keys on that line.
     */
    | { kind: 'street'; centre: number; gap: number; length?: number; mouth?: number }
    /** Birds of prey working a cloud edge. */
    | { kind: 'raptor'; centre: number; radius: number; hunters: HunterSpec[] }
    // --- act III: the upper air. Ice, in the shapes ice actually takes. ---
    /**
     * Slowblue: a third alphabet, and the same grammar again.
     *
     * The rule act II established is that a medium does not get to borrow another
     * medium's silhouettes, and the upper atmosphere is where that rule earns its
     * keep twice over. There is no cloud above the tropopause in any sense a
     * person on the ground would recognise - what there is is *ice*, in crystals,
     * and ice is neither rock nor vapour. It is flat planes and hard edges, it is
     * lit from one side and dark on the other, and it comes in curtains and
     * columns rather than in piles and walls.
     *
     * | water     | air      | upper air | what it asks for                     |
     * | --------- | -------- | --------- | ------------------------------------ |
     * | `gate`    | `bank`   | `veil`    | commit to one gap, early             |
     * | `rock`    | `tower`  | `column`  | split the body and re-form it        |
     * | `narrows` | `pass`   | `throat`  | hold a narrow line under a squeeze   |
     * | `drift`   | `wisps`  | `flurry`  | three lines in a row, no time to rest|
     * | `vortex`  | `rotor`  | `eddy`    | spend the medium on the medium       |
     * | `predator`| `raptor` | `shear`   | choose, and live with the choice     |
     *
     * The last row is the interesting one. There are no hunters at thirty
     * kilometres - nothing up there eats anything - so act III's sixth archetype
     * replaces the act's antagonist rather than reskinning it, and what it
     * replaces it with is the act's own subject: a band boundary with two or
     * three ways through it, where the layer you come out in is the layer that
     * carries you for the next thirty seconds. See `sim/LayeredFlow.ts`.
     */
    /** A curtain of ice across the course with one torn gap in it. */
    | { kind: 'veil'; centre: number; gap: number; depth?: number }
    /** A rising column of crystal: the upper air's splittable mass. */
    | { kind: 'column'; centre: number; radius: number; height?: number }
    /** Two crystal shoulders closing into a slot, entered from below. */
    | { kind: 'throat'; centre: number; gap: number; mouth?: number; depth?: number }
    /** Scattered crystal in staggered rows: two or three committed lines, no rest. */
    | { kind: 'flurry'; gap: number; rows: number; swing: number; first?: -1 | 1 }
    /** A standing eddy at a layer boundary, marked by a lens of ice over it. */
    | {
        kind: 'eddy';
        centre: number;
        gap: number;
        radius: number;
        spin: -1 | 1;
        strength: number;
      }
    /**
     * A layer boundary, drawn as a full-width crystal line with two or three
     * doors in it. `gaps` are the door centres as fractions of width; `gap` is
     * how wide each of them is.
     */
    | { kind: 'shear'; gaps: number[]; gap: number }
    // --- act IV: orbit. Debris and gravity, in the shapes vacuum actually takes. ---
    /**
     * Slowblue: a fourth alphabet, and the first one that is not made of weather.
     *
     * Rock is a hull, cloud is a pile, ice is a regular line of facets. Debris is
     * none of those: it is **sparse**. Nothing up here erodes, nothing condenses
     * and nothing sticks together, so what is in orbit is a scatter of hard
     * chunks of wildly different sizes with real vacuum between them - and that
     * sparseness is the point rather than a softening. Act IV's danger was never
     * "can you fit through", because you always can. It is that you cannot turn.
     *
     * | water     | air      | upper air | orbit      | what it asks for            |
     * | --------- | -------- | --------- | ---------- | --------------------------- |
     * | `gate`    | `bank`   | `veil`    | `arc`      | commit to one gap, early    |
     * | `rock`    | `tower`  | `column`  | `hulk`     | split the body and re-form  |
     * | `narrows` | `pass`   | `throat`  | `strait`   | hold a narrow line          |
     * | `drift`   | `wisps`  | `flurry`  | `shrapnel` | three lines, no time to rest|
     * | `vortex`  | `rotor`  | `eddy`    | `node`     | spend the medium on itself  |
     * | `predator`| `raptor` | `shear`   | `flare`    | the act's own antagonist    |
     *
     * Two rows are worth reading twice. `node` is a **standing gravity well**
     * placed by the course rather than by the player - the same object the hand
     * lays, owned by the world, which is the cleanest possible statement that the
     * medium and the input are one thing up here. And `flare` replaces the
     * predator rather than reskinning it: nothing in orbit hunts, so act IV's
     * sixth archetype is the one thing up there that can actually hurt a mote,
     * which is the aurora it is flying through.
     */
    /**
     * An orbital gate: a wall *bowed along the course*, with its opening off the
     * straight line in. Aiming at the hole does not work - by the time you are
     * lined up you are past it - so it has to be entered on an arc that was
     * started earlier. The one archetype in the game that asks for a curve.
     */
    | { kind: 'arc'; centre: number; gap: number; bow: number }
    /** A dead hulk: orbit's splittable mass, and the hardest edge in the game. */
    | { kind: 'hulk'; centre: number; radius: number }
    /** Two debris streams converging into a lane, entered from behind. */
    | { kind: 'strait'; centre: number; gap: number; mouth?: number; depth?: number }
    /** Shattered debris in staggered rows: three committed lines, no rest. */
    | { kind: 'shrapnel'; gap: number; rows: number; swing: number; first?: -1 | 1 }
    /**
     * A standing gravity well the course owns. `strength` is peak acceleration in
     * px/s^2 and is signed: positive pulls in, negative pushes away.
     */
    | { kind: 'node'; centre: number; radius: number; strength: number; gap?: number }
    /**
     * An auroral curtain: a full-width sheet of charged air with two or three
     * ways through it. `gaps` are the door centres, `gap` how wide each is.
     */
    | { kind: 'flare'; gaps: number[]; gap: number }
    // --- act V: re-entry. Three kinds, and the act borrows the rest on purpose. ---
    /**
     * Slowblue: the one act that does *not* get an alphabet of its own, and why.
     *
     * Every act so far has had six archetypes nobody else may use, on the rule
     * that a medium never borrows another medium's silhouettes. Act V breaks that
     * rule deliberately, because **act V is the transformation**: it starts in
     * vacuum and ends in cloud, and its whole subject is one medium turning into
     * another under the player's hand.
     *
     * So it opens on orbit's debris, ends on the air's cloud, and gets exactly
     * three shapes of its own for the part in the middle that is neither - the
     * part where the air arrives at eight kilometres a second and sets fire to
     * everything the player is carrying. An act about becoming something else
     * cannot be authored out of one vocabulary without lying about what it is.
     *
     * The medium does the same thing in the same order: `Level.mediumTo` blends
     * `space` into `plasma` into `cloud` across the six stations, so the input
     * itself stops being gravity and becomes wind with no frame on which it
     * happened. See `sim/Medium.ts`.
     */
    /**
     * A bow shock: a wall bowed *toward* the swarm, so its middle arrives first.
     * The mirror of act IV's `arc`, and the mirror is the point - orbit asked you
     * to commit early to a hole that ran away from you; re-entry gives you a hole
     * that comes to meet you and asks you to brake.
     */
    | { kind: 'shock'; centre: number; gap: number; bow: number }
    /** An ablation plume: a long burning column, and the act's splittable mass. */
    | { kind: 'plume'; centre: number; radius: number; height?: number }
    /**
     * An ionisation sheet: a full-width band of charged air with doors in it.
     * `gaps` are the door centres, `gap` how wide each is.
     */
    | { kind: 'sheet'; gaps: number[]; gap: number }
    /**
     * Slowblue: the threat that returns, and the fourth thing act V's rebuild was
     * scoped around.
     *
     * The campaign has six hunters in it and all six are in acts I and II, so
     * the only thing in this game with intent disappears a quarter of the way
     * round and never comes back. That is most of why the back half stopped
     * escalating: from act III on, nothing in the world is *doing* anything -
     * it is all geometry standing still, waiting to be flown past.
     *
     * The obvious fix was a `hunters: []` entry on a `plume`, and it is wrong.
     * The renderer used to pick its silhouette off the medium, so act V would
     * have got the water's shark - **a pelagic shark at two hundred kilometres
     * is precisely the image act II's eleven-kilometre ceiling exists to
     * prevent**. And nothing hunts up here, so an animal of any kind would be a
     * lie about the place.
     *
     * What is actually up here is the vehicle, coming apart. A fragment with a
     * worse mass-to-area ratio than the swarm has ablates more slowly, decelerates
     * less, and therefore **catches up from behind, burning**. So act V's threat
     * is always a stoop, it is not alive, and it is the one predator in the game
     * that is brighter than what is around it. See `render/Ember.ts`.
     *
     * `centre`/`radius` are the burnt stub it comes off - small on purpose, so
     * the player reads the thing overtaking them rather than the thing in front.
     */
    | { kind: 'ember'; centre: number; radius: number; hunters: HunterSpec[] }
    // --- act VI: rain. The first solid things since act I, and the first green. ---
    /**
     * Slowblue: a fifth alphabet, and the first one made of *living* things.
     *
     * Act VI falls from cloud to the sea through the one part of the world that
     * is neither: a forest and the water running out of it. So it opens on act
     * II's cloud - the same banks and towers, met from underneath for the first
     * time - and then meets three shapes nothing in the campaign has had, because
     * nothing in the campaign has been near anything alive since the trench.
     *
     * | water     | air      | rain        | what it asks for                  |
     * | --------- | -------- | ----------- | --------------------------------- |
     * | `gate`    | `bank`   | `downpour`  | commit to one gap, early          |
     * | `rock`    | `tower`  | `canopy`    | split the body and re-form it     |
     * | `narrows` | `pass`   | `boulder`   | hold a line through running water |
     *
     * `boulder` is the closest the campaign comes to repeating itself, and it is
     * allowed to, because a stone in a mountain brook *is* the same object as a
     * stone on the trench floor - the same rock, six thousand metres up and with
     * the water going the other way. That is the act's whole subject arriving in
     * the geometry: the player is nearly home, and things are starting to look
     * like things they know.
     */
    /** A curtain of falling water with one gap of lighter rain in it. */
    | { kind: 'downpour'; centre: number; gap: number; depth?: number }
    /** A tree: the canopy's splittable mass, and the first living obstacle. */
    | { kind: 'canopy'; centre: number; radius: number; height?: number }
    /** Stones in running water, with the channel between them. */
    | { kind: 'boulder'; centre: number; gap: number; radius: number }
    // --- act VII: the homecoming. The first things in the game that are soft. ---
    /**
     * Slowblue: a sixth alphabet, and the one the campaign had been getting away
     * without.
     *
     * Act VII's own file opens by insisting **this is not act I reversed**, and
     * then authors the whole act out of act I's rock: four `gate`s, one `rock`,
     * one `narrows`, one `vortex`. Every other act in the campaign was held to
     * "a medium does not get to borrow another medium's silhouettes" and this one
     * was not, on the technicality that water is water. The technicality is true
     * and the result is still that the last act of the journey is the first act
     * of it with the lights down.
     *
     * What is actually down there is not stone. Below the sunlit zone the ocean
     * is the largest habitat on the planet and almost nothing in it is hard: it
     * is gelatinous, it is metres long, it is 95 % water, and it does not sit on
     * the bottom - it hangs. So act VII gets two shapes and both of them are
     * bodies:
     *
     * | water     | homecoming | what it asks for                            |
     * | --------- | ---------- | ------------------------------------------- |
     * | `gate`    | `drape`    | come through somewhere, and it hardly matters |
     * | `rock`    | `bloom`    | drift around it rather than split on it     |
     *
     * Neither of them closes the course. That is the act's rule and it is the
     * point of the act: from the salt line down, **nothing in the water is a wall
     * any more**, and the campaign spends its last twenty minutes proving it.
     * `tests/descent.test.ts` holds the number.
     */
    /**
     * A siphonophore: a hanging curtain of strands, and the longest animal there
     * is. Met from above on a falling course, so what arrives first is the top of
     * it and the ways through are visible the whole way down.
     *
     * `strands` are the x centres of the hanging parts as fractions of width;
     * `reach` is how far each one hangs, in px along the course.
     */
    | { kind: 'drape'; strands: number[]; reach?: number }
    /**
     * A bloom: a loose swarm of medusae, soft and wide apart. The act's mass, and
     * the only one in the campaign a body is meant to *drift through the gaps of*
     * rather than split on - which is why it is not in `SPLITTABLE` and why it is
     * authored with more open water in it than body.
     */
    | { kind: 'bloom'; centre: number; radius: number; spread?: number }
  );

/** Which decorative life a level is dressed with. Never touches the simulation. */
/**
 * What grows in the background of a station.
 *
 * The first six are the sea, and they are what the whole set used to be - which
 * is why the campaign's new acts were all authored as `meadow` and why seagrass,
 * sea fans and a passing leviathan were being drawn in the stratosphere, in
 * vacuum and inside a re-entry plasma sheath. `void` is the honest theme for
 * everywhere nothing grows, and it is not an absence of content: §7 says the
 * picture empties out on the way up, and act IV's composition is the planet, the
 * stars and the swarm with nothing else in the frame at all.
 */
export type DecorTheme =
  | 'kelp'
  | 'meadow'
  | 'jelly'
  | 'abyss'
  | 'garden'
  | 'trench'
  /** Nothing grows here: thin air, space, plasma, open sky. */
  | 'void'
  /** Leaves, from underneath. Act VI's forest. */
  | 'canopy'
  /** Running fresh water: bubbles and surface ripple, and nothing alive. */
  | 'stream';

export interface Level {
  key: string;
  name: string;
  /**
   * The station's distance below the surface, in metres. Negative is height
   * *above* the sea, so one signed number carries the whole campaign: 6000 on the
   * trench floor, 0 at the waterline, -100000 at the Karman line.
   */
  depthMeters: number;
  /** One quiet line under the station title, naming what changed on the ascent. */
  subtitle: string;
  /** Which zone palette this level is painted in. */
  zone: number;
  /** The medium this level is played in. Absent means water: all of act I. */
  medium?: MediumKind;
  /**
   * The medium this station is turning *into*, blended across it by
   * `World.levelProgress`.
   *
   * Slowblue: the re-entry act is the one place the game changes its own input rule,
   * and a switch would be a lie - the air does not arrive, it thickens. So a
   * station names where it starts and where it ends and the medium is resolved
   * continuously between them, which means the potential-to-momentum handover in
   * act V happens over about a minute of play and has no frame on which it
   * "happened". See `blendMedium`.
   */
  mediumTo?: MediumKind;
  decor: DecorTheme;
  /** Multiplies the forced camera drift. Under 1 the level is calmer than default. */
  pace: number;
  /** Multiplies the ocean's own current. */
  roughness: number;
  /**
   * Multiplies every standing current the level lays down.
   *
   * "Every standing current" is `vortex`, `rotor` and `eddy` and nothing else -
   * they are the only three kinds that push a `VortexHint`, and `World.water` is
   * the only reader. **A station with none of those three must author 0**, or the
   * number is a claim about the water that nothing can make true.
   *
   * Slowblue: seventeen of the forty-two stations carried a non-zero `swirl` over an
   * empty vortex list, including two acts that say in their headers how much their
   * standing currents matter. It read as content and was arithmetic on nothing.
   * `tests/geometry.test.ts` holds the rule now, in both directions.
   */
  swirl: number;
  /**
   * Horizontal atmospheric layers, if this station has them. See `LayeredFlow`.
   *
   * Act III's stations all do, and nothing else in the campaign does - this is
   * the field that makes the upper air a different verb rather than a different
   * colour. Scaled by `roughness`, so the same layer table can be dialled up
   * station by station without rewriting it.
   */
  layers?: LayerSpec;
  /**
   * Overrides the act's failure mode for this station alone.
   *
   * Exactly one thing in the campaign needs it, and it needs it badly: act VII's
   * second half cannot be lost, while its first half still can. See
   * `sim/Failure.ts`.
   */
  failure?: FailureMode;
  sections: SectionSpec[];
}

const BREATH: SectionSpec = { kind: 'open', spacing: 900 };

/**
 * Six stations on one ascent. The mechanics still teach from simple to precise,
 * while the environment travels the other way: trench floor -> black water ->
 * midnight current -> blue rise -> light line -> surface.
 *
 * What escalates, in order of how much it costs the player:
 *   1. how wide the gaps are         (0.56 -> 0.24 of the width)
 *   2. how far apart consecutive lines are laterally
 *   3. how many rings are mandatory   (1 -> 4 per level)
 *   4. what else is in the water      (nothing -> current -> hunters)
 * Pace only moves from 0.72 to 1.0 across the whole game. The game is not
 * supposed to get faster; it is supposed to ask for more precision.
 */
export const LEVELS: Level[] = [
  {
    key: 'trench-floor',
    name: 'Trench Floor',
    depthMeters: 6000,
    subtitle: 'Where light cannot reach',
    zone: 0,
    decor: 'trench',
    pace: 0.72,
    roughness: 0.6,
    swirl: 0,
    sections: [
      // Nothing but water and one ring in the middle of it. The only thing this
      // section can teach is the only thing the player needs first: drag the
      // water, the shoal follows, hold it somewhere on purpose.
      {
        kind: 'open',
        spacing: 760,
        rings: [{ x: 0.5, dy: 0, count: 10, required: true, scale: 1.5 }],
      },
      { kind: 'gate', centre: 0.5, gap: 0.58, rings: [{ x: 0.5, dy: -240, count: 8 }] },
      {
        kind: 'gate',
        centre: 0.34,
        gap: 0.5,
        rings: [{ x: 0.34, dy: 210, count: 10, required: true, scale: 1.35 }],
      },
      {
        // First rock. One ring in each channel, and only the wider one is asked
        // for - splitting the shoal is shown here, never demanded here.
        kind: 'rock',
        centre: 0.52,
        radius: 0.15,
        rings: [
          { x: 0.16, dy: -120, count: 9, required: true, scale: 1.3 },
          { x: 0.85, dy: -120, count: 9 },
        ],
      },
      {
        kind: 'narrows',
        centre: 0.55,
        gap: 0.4,
        mouth: 0.46,
        depth: 210,
        rings: [{ x: 0.55, dy: 250, count: 11, required: true, scale: 1.3 }],
      },
      { kind: 'gate', centre: 0.66, gap: 0.52, rings: [{ x: 0.66, dy: -230, count: 10 }] },
      BREATH,
    ],
  },
  {
    key: 'black-water',
    name: 'Black Water',
    depthMeters: 4000,
    subtitle: 'Open water of the abyss',
    zone: 1,
    decor: 'abyss',
    pace: 0.78,
    roughness: 0.75,
    swirl: 0,
    sections: [
      {
        kind: 'gate',
        centre: 0.28,
        gap: 0.46,
        rings: [{ x: 0.28, dy: 200, count: 10, required: true, scale: 1.3 }],
      },
      // First chicane: two rows, a short swing, so the lesson is "a laid current
      // outlives the gap you laid it for" and not "cross the field twice".
      { kind: 'drift', gap: 0.46, rows: 2, swing: 0.13, first: 1 },
      {
        kind: 'rock',
        centre: 0.44,
        radius: 0.17,
        teeth: true,
        rings: [
          { x: 0.14, dy: -130, count: 10, required: true, scale: 1.25 },
          { x: 0.82, dy: -130, count: 10 },
        ],
      },
      {
        kind: 'narrows',
        centre: 0.38,
        gap: 0.34,
        mouth: 0.5,
        depth: 230,
        rings: [{ x: 0.38, dy: 260, count: 12, required: true, scale: 1.25 }],
      },
      { kind: 'gate', centre: 0.7, gap: 0.44, rings: [{ x: 0.7, dy: -220, count: 10 }] },
      {
        kind: 'gate',
        centre: 0.3,
        gap: 0.42,
        rings: [{ x: 0.3, dy: 190, count: 11, required: true, scale: 1.25 }],
      },
      BREATH,
    ],
  },
  {
    key: 'midnight-current',
    name: 'Midnight Current',
    depthMeters: 2500,
    subtitle: 'The first current upward',
    zone: 1,
    decor: 'jelly',
    pace: 0.84,
    roughness: 0.9,
    swirl: 0.75,
    sections: [
      // The first standing current in the game, and it is a gentle one sitting in
      // a wide gate: the shape of the hazard is legible before it can cost you.
      {
        kind: 'vortex',
        centre: 0.5,
        gap: 0.5,
        radius: 0.34,
        spin: 1,
        strength: 78,
        rings: [{ x: 0.5, dy: 250, count: 10, required: true, scale: 1.3 }],
      },
      { kind: 'drift', gap: 0.44, rows: 3, swing: 0.14, first: -1 },
      {
        kind: 'rock',
        centre: 0.56,
        radius: 0.18,
        teeth: true,
        rings: [
          { x: 0.16, dy: -140, count: 11, required: true, scale: 1.2 },
          { x: 0.86, dy: -140, count: 11 },
        ],
      },
      {
        kind: 'narrows',
        centre: 0.62,
        gap: 0.32,
        mouth: 0.5,
        depth: 240,
        rings: [{ x: 0.62, dy: 265, count: 12, required: true, scale: 1.2 }],
      },
      {
        kind: 'vortex',
        centre: 0.36,
        gap: 0.44,
        radius: 0.3,
        spin: -1,
        strength: 92,
        rings: [{ x: 0.36, dy: 240, count: 11, required: true, scale: 1.2 }],
      },
      { kind: 'gate', centre: 0.68, gap: 0.42, rings: [{ x: 0.68, dy: -210, count: 11 }] },
      BREATH,
    ],
  },
  {
    key: 'blue-rise',
    name: 'The Blue Rise',
    depthMeters: 1000,
    subtitle: 'The first trace of light',
    zone: 2,
    decor: 'garden',
    pace: 0.9,
    roughness: 1,
    swirl: 0.9,
    sections: [
      {
        kind: 'gate',
        centre: 0.24,
        gap: 0.4,
        rings: [{ x: 0.24, dy: 200, count: 11, required: true, scale: 1.2 }],
      },
      { kind: 'drift', gap: 0.4, rows: 3, swing: 0.15, first: 1 },
      {
        kind: 'vortex',
        centre: 0.58,
        gap: 0.4,
        radius: 0.32,
        spin: -1,
        strength: 105,
        rings: [{ x: 0.58, dy: 250, count: 12, required: true, scale: 1.2 }],
      },
      {
        kind: 'rock',
        centre: 0.48,
        radius: 0.19,
        teeth: true,
        rings: [
          { x: 0.15, dy: -150, count: 12, required: true, scale: 1.15 },
          { x: 0.84, dy: -150, count: 12, required: true, scale: 1.15 },
        ],
      },
      {
        kind: 'narrows',
        centre: 0.44,
        gap: 0.3,
        mouth: 0.52,
        depth: 250,
        rings: [{ x: 0.44, dy: 270, count: 12, required: true, scale: 1.15 }],
      },
      { kind: 'gate', centre: 0.74, gap: 0.38, rings: [{ x: 0.74, dy: -200, count: 12 }] },
      BREATH,
    ],
  },
  {
    key: 'light-line',
    name: 'The Light Line',
    depthMeters: 200,
    subtitle: 'The edge of darkness',
    zone: 2,
    decor: 'meadow',
    pace: 0.95,
    roughness: 1.1,
    swirl: 1,
    sections: [
      {
        kind: 'vortex',
        centre: 0.3,
        gap: 0.38,
        radius: 0.3,
        spin: 1,
        strength: 112,
        rings: [{ x: 0.3, dy: 240, count: 12, required: true, scale: 1.15 }],
      },
      {
        kind: 'vortex',
        centre: 0.7,
        gap: 0.38,
        radius: 0.3,
        spin: -1,
        strength: 112,
        rings: [{ x: 0.7, dy: 240, count: 12, required: true, scale: 1.15 }],
      },
      { kind: 'drift', gap: 0.38, rows: 3, swing: 0.16, first: -1 },
      {
        kind: 'rock',
        centre: 0.5,
        radius: 0.2,
        teeth: true,
        rings: [
          { x: 0.14, dy: -150, count: 12, required: true, scale: 1.15 },
          { x: 0.86, dy: -150, count: 12, required: true, scale: 1.15 },
        ],
      },
      {
        kind: 'narrows',
        centre: 0.56,
        gap: 0.28,
        mouth: 0.52,
        depth: 260,
        rings: [{ x: 0.56, dy: 280, count: 13, required: true, scale: 1.15 }],
      },
      {
        kind: 'vortex',
        centre: 0.42,
        gap: 0.36,
        radius: 0.32,
        spin: 1,
        strength: 120,
        rings: [{ x: 0.42, dy: 245, count: 12 }],
      },
      BREATH,
    ],
  },
  {
    key: 'surface',
    name: 'The Surface',
    depthMeters: 0,
    subtitle: 'Break through into light',
    zone: 3,
    decor: 'kelp',
    pace: 1,
    roughness: 1.2,
    swirl: 1,
    sections: [
      {
        kind: 'predator',
        centre: 0.5,
        radius: 0.13,
        hunters: [{ x: 0.5, dy: -320, size: 16 }],
        rings: [{ x: 0.2, dy: 230, count: 12, required: true, scale: 1.15 }],
      },
      { kind: 'drift', gap: 0.36, rows: 3, swing: 0.16, first: 1 },
      {
        kind: 'predator',
        centre: 0.62,
        radius: 0.14,
        hunters: [
          { x: 0.28, dy: -300, size: 17 },
          { x: 0.76, dy: -430, size: 17 },
        ],
        rings: [{ x: 0.5, dy: 240, count: 13, required: true, scale: 1.15 }],
      },
      {
        kind: 'vortex',
        centre: 0.36,
        gap: 0.34,
        radius: 0.32,
        spin: -1,
        strength: 125,
        rings: [{ x: 0.36, dy: 250, count: 13, required: true, scale: 1.15 }],
      },
      {
        kind: 'narrows',
        centre: 0.6,
        gap: 0.26,
        mouth: 0.52,
        depth: 270,
        rings: [{ x: 0.6, dy: 285, count: 14, required: true, scale: 1.15 }],
      },
      {
        kind: 'rock',
        centre: 0.48,
        radius: 0.2,
        teeth: true,
        rings: [
          { x: 0.14, dy: -160, count: 13, required: true, scale: 1.15 },
          { x: 0.85, dy: -160, count: 13 },
        ],
      },
      { kind: 'open', spacing: 960 },
    ],
  },
];

export interface ScriptEntry {
  level: number;
  /** 0-based index inside its own level. */
  step: number;
  spec: SectionSpec;
}

/**
 * Slowblue: which way along the world's Y axis a course runs.
 *
 * -1 is up - toward smaller Y - and it is what the first four acts do, because
 * the first four acts are a climb. +1 is down, and it arrives at the top of the
 * atmosphere when the whole campaign turns over.
 *
 * It is one number rather than a scatter of `if (descending)` branches for a
 * reason worth stating: every one of those branches is a place where the camera,
 * the pruning, the strand line and the section crossing could disagree about
 * which way "behind" is, and four systems disagreeing about that is a course that
 * silently deletes itself. `World.u()` turns a world Y into a *course* coordinate
 * where larger is always further ahead, and everything downstream reads that.
 */
export type CourseDirection = -1 | 1;

/**
 * Slowblue: what is carrying the light, this act.
 *
 * The campaign's one real secret is that the player was never steering the fish.
 * They were helping the same gold along, and the thing holding it changed seven
 * times on the way round. This is that list, and it is a *rendering* decision
 * from end to end: every carrier is the same `SwarmSimulation`, the same agents,
 * the same boids terms and the same rescue rings. What differs is the silhouette
 * drawn at each position and how it is lit.
 *
 * Keeping it on the act rather than in the renderer means the audio bed, the
 * admin surface and the campaign screen all read the same field, and none of
 * them has to map a level key to a shape.
 */
export type CarrierKind =
  /** Act I: a shoal. */
  | 'fish'
  /** Act II: a flock. */
  | 'birds'
  /** Act III: spores, seeds and ice - the first carrier with no body plan. */
  | 'motes'
  /** Act IV: the gold itself, with nothing left around it. */
  | 'lights'
  /** Act V: the same gold, burning. */
  | 'dust'
  /** Act VI: ice crystals, then droplets, then one body of water. */
  | 'droplets'
  /** Act VII: plankton, larvae and marine snow, going home. */
  | 'plankton';

export interface ActOptions {
  direction?: CourseDirection;
  carrier?: CarrierKind;
  failure?: FailurePolicy;
}

/**
 * Slowblue: an act. The campaign above is act I - the water. The ascent adds more,
 * and each is the same shape: a list of levels, flattened into one script the
 * course builder walks. Everything that used to read the module-level water
 * globals can take an act instead; the globals below stay as act I's, so the
 * shipped game keeps reading the exact objects it always read.
 */
export interface Act {
  key: string;
  levels: Level[];
  /** Every authored section in play order. Section ids index straight into this. */
  script: ScriptEntry[];
  totalSections: number;
  /** Which way this act's course runs. See `CourseDirection`. */
  direction: CourseDirection;
  /** What the renderer draws at each agent position. See `CarrierKind`. */
  carrier: CarrierKind;
  /**
   * What going wrong means here: the station begins again. One rule, every act -
   * see `sim/Failure.ts`. A station may soften it to `none`; nothing hardens it.
   */
  failure: FailurePolicy;
  /**
   * How many stations this act attempt may put back before it is over.
   *
   * Derived from the act's own authored length rather than fixed at two - see
   * `restartsForMinutes`. It is computed here, once, because this is the only
   * place that has both the sections and the paces, and because a number that
   * three call sites each work out for themselves is a number that will disagree
   * with itself inside a month.
   */
  restarts: number;
}

/**
 * The act's authored length in minutes: every section's spacing over the drift
 * its own station runs at.
 *
 * The act's first spacing is dropped because it is never walked - every course
 * starts at `FIRST_SECTION_OFFSET`, so the number authored on script index 0 is
 * counted in the length and never travelled. `tools/stations.sweep.ts` prints the
 * same arithmetic per station.
 */
function authoredMinutes(script: ScriptEntry[], levels: Level[]): number {
  let seconds = 0;
  script.forEach((entry, i) => {
    if (i === 0) return;
    const px = entry.spec.spacing ?? 820;
    // `worldSpeed`'s default, inlined: this is a property of the *authored* course
    // and must not move when the debug panel drags the live tuning about.
    seconds += px / (68 * levels[entry.level]!.pace);
  });
  return seconds / 60;
}

export function makeAct(key: string, levels: Level[], options: ActOptions = {}): Act {
  const script = levels.flatMap((level, li) =>
    level.sections.map((spec, step) => ({ level: li, step, spec })),
  );
  return {
    key,
    levels,
    script,
    totalSections: script.length,
    direction: options.direction ?? -1,
    carrier: options.carrier ?? 'fish',
    // The campaign's one failure rule, and the only place it is stated. Every act
    // takes it by saying nothing, so "a failure costs the station" cannot drift
    // into being true of six acts and false of the seventh - which is exactly what
    // it was while the default here was `END_ON_FAILURE` and five act files each
    // opted out of it by hand. See `sim/Failure.ts`.
    failure: options.failure ?? RESTART_ON_FAILURE,
    restarts: restartsForMinutes(authoredMinutes(script, levels)),
  };
}

/** Act I. `levels` is the same array as `LEVELS` - one campaign, two names. */
export const ACT_WATER: Act = makeAct('water', LEVELS);

export const LEVEL_SCRIPT: ScriptEntry[] = ACT_WATER.script;

export const TOTAL_SECTIONS = ACT_WATER.totalSections;

/** Which level a section belongs to; clamped, so it is safe past the end. */
export function levelOfSectionIn(act: Act, sectionId: number): number {
  const entry = act.script[sectionId];
  if (entry !== undefined) return entry.level;
  return act.levels.length - 1;
}

export function levelAtIn(act: Act, index: number): Level {
  return act.levels[Math.max(0, Math.min(act.levels.length - 1, index))]!;
}

export function levelAt(index: number): Level {
  return levelAtIn(ACT_WATER, index);
}

/**
 * Where a station is, written the way the banner says it.
 *
 * Negative metres are height above the sea, so the *sign* is what decides
 * whether this line is a depth or an altitude. The range form - `X → 0 M` - is
 * for a station whose subject is *reaching* the waterline, and it is written
 * from wherever the act came from.
 *
 * It lives here rather than inline in the renderer because it got two acts
 * wrong. The range used to be keyed on "is this the act's last station", which
 * is true of act I and of nothing else: act VI's estuary printed a raw
 * `-400 → 0 M`, and act VII's trench floor, six thousand metres *down*,
 * announced that it was going to zero. Both are one line of text on the frame
 * that names the place, both were wrong in the shipped build, and neither could
 * be caught by a test while the string was built inside a draw call.
 */
export function stationDepthLabel(levels: readonly Level[], index: number): string {
  const level = levels[Math.max(0, Math.min(levels.length - 1, index))]!;
  const metres = (m: number): string =>
    m < 0 ? `▲ ${Math.abs(m).toLocaleString('en-US')}` : m.toLocaleString('en-US');
  // Arriving at the surface, from wherever this act started.
  if (level.depthMeters === 0 && index > 0) {
    return `${metres(levels[index - 1]!.depthMeters)} → 0 M`;
  }
  return `${metres(level.depthMeters)} M`;
}

/** First section id of a level. Used by the banner, the admin surface and the tests. */
export function levelStartSectionIn(act: Act, index: number): number {
  return act.script.findIndex((e) => e.level === index);
}
