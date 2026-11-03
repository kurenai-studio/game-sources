import { makeAct, type Act, type Level, type RingSpec, type SectionSpec } from './levels';
import { ZONE_SPACE } from './zones';

/**
 * Slowblue: act IV - orbit.
 *
 * ## The act where the sentence loses a word
 *
 * "You do not control the creatures. You control the medium that carries them."
 * Above a hundred kilometres there is no medium, and this act is what the game
 * does about that: it keeps the **verb** and replaces the noun. A stroke still
 * lays something into the world that the carried life then obeys. What it lays is
 * a gravity well, and what the life does is fall around it.
 *
 * The player is told none of this. `Medium.vacuum` is 1 here, so `World.injectStroke`
 * puts the whole of every stroke into `PotentialField` instead of the flow field,
 * and the first drag of act IV simply does something else than it did at the
 * Karman line. That is the entire tutorial, and it is why act III's last station
 * is empty: a discovery needs somewhere quiet to happen.
 *
 * ## What is different to play, in one sentence each
 *
 *   * **Nothing damps anything.** `coupling` is zero, so a mote's velocity is its
 *     own until something bends it. Momentum is conserved for the first time in
 *     the campaign.
 *   * **Nothing self-propels.** `migrationSpeed` is zero. Every metre the swarm
 *     makes up the course is a metre something gave it.
 *   * **Correction is late.** A current moves a body inside a second; a well
 *     bends a trajectory over ten. A bad stroke stays correctable and stops being
 *     correctable cheaply, and that lateness is the act's subject.
 *   * **Nothing ends.** No `depleted`, no `sweptAway`, no missed ring closes a
 *     campaign here - a station simply begins again, for time and score. See
 *     `sim/Failure.ts`.
 *
 * ## This act was the thinnest in the campaign, and that is what this rebuild is
 *
 * The circuit measured 72 authored minutes with no difficulty arc in it, and the
 * fault was never the hour - it was the distribution. Acts I and II ask something
 * every seventeen seconds. **Act IV asked every fifty-five, which is the thinnest
 * water in the game outside act VII's dilation.** Eighteen sections, twelve
 * obstacles, 1.1 a minute. See [docs/DESIGN-LENGTH.md](../../docs/DESIGN-LENGTH.md),
 * which is the measurement, the decision, the arithmetic, and act V's two passes
 * as the pilot everything here is copied from.
 *
 * So: **18 sections to 56, 12 obstacles to 43, 11.4 authored minutes to 20.6**,
 * at `pace`, `roughness` and `swirl` that are byte-for-byte what they were. The
 * game does not get faster; there is more of it, and what there is more of asks
 * more.
 *
 * Two rules came out of act V's rebuild measured rather than chosen, and both
 * cost that act four completions in seven when they were got wrong:
 *
 *   * **A station ends on a rest**, because `World.pressure` ramps the forced
 *     drift by up to 55 % across a station and peaks at its own end. The rest is
 *     where the swarm pays that ground back. It is not decoration and it is not
 *     spare; moving it to the middle measured 42.6 restarts a run against a
 *     baseline of 1.2.
 *   * **and its last demand is not a gate.** A compulsory ring asks the swarm to
 *     stop and hold a body still, which is the exact opposite of what the pressure
 *     peak asks. The old three-section stations never collided the two because
 *     they all happened to end on a `coast`; two of them - the Debris Belt and the Well -
 *     ended on a wall, and one of those walls carried a required ring.
 *
 * A doubled station therefore gets **two** rests, one in each half, and the
 * mid-station breath is an addition rather than a move. The last one carries an
 * ordinary ring rather than a compulsory one - see `landing` below, which is the
 * one thing in this file `coast` could not be made to do.
 *
 * ## The rhythm: gravity comes in clusters, and the cluster is what grew
 *
 * This act used to be laid on the campaign's 820 px metronome: one thing, 820 px,
 * the next thing, 820 px, for eighteen sections. That was wrong here before it was
 * wrong anywhere else, because a `node` has a radius of 0.34 to 0.42 of the width
 * and its influence is therefore over about 330 px before the next section starts.
 * On an even metronome a station is a queue of independent puzzles, and act IV's
 * whole claim - that up here the medium and the input are the same object - never
 * gets to be true of two sections at once.
 *
 * So the metronome went, and every station became **a long fall, then two things
 * close enough together that the first one is still bending you when the second
 * arrives.** 320 px is the number that was built on: at that spacing two wells of
 * radius 0.42 are summed by the same `PotentialField` the player's own hand
 * deposits into, and the swarm's path through the pair is one curve rather than
 * two corrections.
 *
 * **The doubling is spent on that sentence rather than on a second copy of it.**
 * A station is two movements now - A, a breath, and B - and the thing that
 * escalates across the act is how many things are in a cluster:
 *
 *   * Free Fall    - clusters of two and three, at 320-340 px
 *   * The Aurora   - three, and the first of them is already moving
 *   * The Umbra    - three, with the pair inside it half a cycle out of step
 *   * Debris Belt  - four, twice, and two of them walking against each other
 *   * The Well     - four, and the last one is a gap inside a well
 *
 * The long falls pay for it and are the other half of the rhythm: 980 to 1180 px
 * in front of each station's first demand, 560 to 620 across its middle, and 420
 * to 480 to land on. That is 29 950 px against the old act's 15 740, and it still
 * runs at the same six paces.
 *
 * ## The second axis: nine of these do not stand still, and orbit is where that
 * is least of a special effect
 *
 * Every obstacle in the first three acts stands still, which made the whole
 * difficulty of this game spatial - read the shape, lay the line, arrive. Act V's
 * rebuild added the other axis as a modifier rather than an alphabet
 * (`MotionSpec` in `levels.ts`), so any of the seventy shapes the game draws can
 * move for one line each. Nine sections here carry it.
 *
 * It is worth more in this act than in the one it was built for, and the reason is
 * physical rather than aesthetic. **Everything up here is in orbit, which means
 * everything up here is already moving**; the only reason a piece of debris looks
 * still is that the swarm happens to be on the same track. A chunk on a slightly
 * different inclination is not still. It walks across the track and back, once a
 * revolution, forever, and nothing damps it - so a walking mass in vacuum is not
 * an effect laid over the place, it is what the place is. Below the Karman line a
 * moving obstacle needs a wind to explain it. Here the explanation is the setting.
 *
 * And it lands exactly on the act's own verb. *Aim ahead of them* was always a
 * sentence about a target that will have moved by the time the trajectory gets
 * there; until this rebuild the only thing that moved was the swarm.
 *
 *   * **An aperture breathes.** Authored **shut** - the `gap` written down is the
 *     narrowest it ever is - so the corridor sweep, which never advances a clock,
 *     is already checking the worst frame. Up here it is two streams on periods
 *     that do not quite match, lining up twice a minute. It is allowed only on the
 *     shapes that are one wall with one hole (`arc`, `strait`, and a `node` that
 *     has a lane through it); `tests/motion.test.ts` holds that line.
 *   * **A mass walks.** `Section.envelope` carries the union of everywhere it ever
 *     is and the sweep reads that, so the guarantee is the strong one: there is a
 *     line past it whenever you arrive, not only on the beat.
 *   * **A scissor is two masses on one clock and opposite halves of it.** There is
 *     no phase at which either is where you last saw it. The Debris Belt, which is the
 *     one station in the campaign made of things people left behind, and therefore
 *     the only place two derelicts tumbling against each other is a fact rather
 *     than a set-piece.
 *   * **A counter-phase pair is two breathing gaps two breaths apart**, the second
 *     shut while the first is open, so taking the first the moment it opens arrives
 *     at the second at its narrowest. It is in the Umbra, in the dark, where
 *     neither gap can be read early - and where the act's own demand (commit before
 *     you can see) and this one (do not commit yet) are the same question asked
 *     from both ends.
 *
 * They arrive in teaching order and each one is introduced alone: the first
 * aperture is in Free Fall at 0.50 of the width with nothing else in the frame,
 * the first walking mass is one station later with the ring in a channel it can
 * never reach, and the pair and the scissor are two stations after that.
 *
 * ## The ring grammar: the reward is never on the line you are already on
 *
 * The act's verb is *aim ahead of them* (DESIGN-ASCENT §8), and its rings used to
 * sit where every other act's sit - at the section's own centre, a couple of
 * hundred pixels in front of it, which is to say on the line the swarm was already
 * holding. Nothing was being asked for.
 *
 * The rule is that each compulsory ring's `x` is **a long way from the previous
 * compulsory ring's `x`**, across station boundaries as well as inside them. The
 * act runs 0.50, 0.24, 0.72, 0.30 | 0.78, 0.26, 0.70 | 0.28, 0.74, 0.30 | 0.70,
 * 0.35, 0.74, 0.28 | 0.68, 0.36, 0.74, 0.26, 0.64 - nineteen of them, no step
 * under a third of the width except the one the Well is allowed. Every ring is still
 * on the line its own section asks for - the demand is never "guess" - but in a
 * medium with no drag, a reward on the far side of the field means the arc that
 * takes it had to be started before the section carrying it was on screen.
 *
 * The corridor sweep allows 45 px of lateral per 100 px of course, and that is
 * what decides where the compulsory rings go rather than taste: **a cluster
 * carries one of them, not two.** 320 px buys 128 px of lateral and half the field
 * is 195, so a reward the swarm cannot be aimed at is not a grammar, it is a bug.
 * The tightest budget any consecutive pair gets is 202 px against a 164 px step,
 * in Free Fall. The one exception is the pair in the Well, whose two rings are 125 px
 * apart across 320 - and that station has no geometry in it at all, so the rings'
 * own radii cover the rest.
 *
 * **Nineteen compulsory rings across 20.6 minutes is 0.92 a minute, where the old
 * act had 1.05.** That is fewer per minute on an act that is twice as long, and it
 * is deliberate for the reason act V wrote down: a compulsory ring is this act's
 * main way of losing a station, and a station is now 3.4 minutes rather than 1.7.
 *
 * ## Six stations
 *
 *   1. **Free Fall** - momentum, alone, with almost nothing in the
 *      way. The teaching station keeps its share of the silence: six obstacles in
 *      3.8 minutes, where the rest of the act runs at nine and ten.
 *   2. **The Aurora** - the first thing up here that can hurt a mote,
 *      and the first thing in the act that walks.
 *   3. **The Umbra** - the Earth's own shadow, the darkest frame in
 *      the game, and the counter-phase pair, which is a timing demand authored
 *      where timing cannot be read.
 *   4. **The Debris Belt** - the act's densest station, the only one
 *      with anything man-made in it, and the scissor.
 *   5. **The Well** - the slingshot, the deepest bow in the campaign, and
 *      a lane inside a well that will not hold still.
 *   6. **The Overview** - the emotional peak of the campaign, and the
 *      one station in this rebuild that did not gain a single pixel. See below.
 *
 * ## The Overview, and why it is authored as almost nothing
 *
 * The camera turns for the first time, the whole Earth appears, and the entire
 * atmosphere - everything this game has ever happened in - resolves into one
 * bright line a few pixels thick. Motion stops. Only the breath and a very fine
 * internal tone are left, and **no results screen arrives.**
 *
 * A station that has anything to *do* in it cannot carry that. So the last one
 * here is two sections of open vacuum, one optional ring between them, its pace
 * is the lowest in the campaign, and its nodes are gone. It is also the longest
 * fall in the act, 1000 px then 1600: the rhythm's own way of saying that nothing
 * else is coming, with the emptiness spent *after* the last thing rather than
 * before it. The work of the station is done by `render/Overview.ts` and by what the
 * player has already spent forty minutes climbing.
 *
 * **The length plan explicitly stops at its door.** Every other station here is
 * two to three times what it was; this one is untouched, because the only thing
 * that could be added to it is something to do, and the whole of it is that there
 * is nothing to do. It is 2.7 minutes of the act's 20.6 now rather than 2.7 of
 * 11.4, which means the rebuild has quietly made the silence a smaller fraction of
 * the act - and that is the right direction, because the silence is measured
 * against how long you have been working, and you have been working twice as long.
 *
 * The handover is the campaign turning over: the motes' trajectory bends back
 * toward Earth, and from here the game runs downward.
 */

/**
 * The long fall that opens a station or crosses its middle: open vacuum, and one
 * compulsory ring a long way across the field from the last one.
 *
 * This replaces the `breath` every station used to end on, which was 940 px of
 * vacuum with an optional ring in the middle of it. A breath was the right idea
 * on a metronome, where nothing else in the station was ever open; on this act's
 * rhythm the open ground is the rhythm, and the section that carries it is where
 * the ring grammar has room to actually cross the field.
 */
function coast(spacing: number, x: number, count: number, scale = 1.5): SectionSpec {
  return { kind: 'open', spacing, rings: [{ x, dy: 0, count, required: true, scale }] };
}

/**
 * The rest a station ends on, and the one place in this act an open section does
 * *not* carry a compulsory ring.
 *
 * `coast` would have done for this and it was what shipped, on the reasoning that
 * open vacuum is open vacuum. It is not: `World.pressure` peaks at a station's own
 * end, so the landing is where the swarm buys back the ground the ramp took, and a
 * required ring there asks it to stop and hold a body still at the exact moment it
 * is furthest behind. Act V measured the pair of mistakes - no landing at all, and
 * a gate on the last demand - at 42.6 and 15.4 restarts a run against a baseline of
 * 1.2. The ring stays, because the grammar is what makes the emptiness readable;
 * only the demand comes off it.
 */
function landing(spacing: number, x: number, count: number): SectionSpec {
  return { kind: 'open', spacing, rings: [{ x, dy: -60, count, scale: 1.5 }] };
}

/**
 * A compulsory ring, on the line the section already asks for - and, in this act,
 * a long way from where the last one was. See the ring grammar above.
 */
function must(x: number, dy: number, count: number, scale = 1.45): RingSpec {
  return { x, dy, count, required: true, scale };
}

/**
 * The breath, as a period. Named here rather than passed, because a section that
 * pulsed on some other clock would be a second rhythm in a game that has one.
 *
 * The reach is small on purpose. An aperture is authored shut and only opens, so
 * `reach` is not difficulty, it is *legibility* - how obviously the thing is
 * breathing when you are eleven seconds from it. At 0.055 the gap moves 43 px
 * across a cycle, which reads at a glance and never turns a wall into a door that
 * was not authored.
 */
const PULSE = { kind: 'aperture', reach: 0.055 } as const;

/**
 * One mass, walking. No phase: an unauthored moving section takes a beat derived
 * from where it sits on the course, so no two of them in the campaign are ever in
 * step and none is memorisable (`tests/motion.test.ts`).
 */
const WALK = { kind: 'drift', reach: 0.06 } as const;

/**
 * Two masses on one clock and opposite halves of it: the scissor.
 *
 * A single walking mass asks "aim where the gap will be". A pair of them a few
 * hundred pixels apart, one going out while the other comes back, asks something
 * else: **there is no phase at which both are where you last saw them.** A line
 * laid for the first is always the wrong line for the second, and the only way
 * through is to lay the line the pair will have made by the time you arrive -
 * which in an act with no damping is a line laid a whole cluster early.
 *
 * It is safe for the same reason a single drift is: `Section.envelope` carries the
 * union of everywhere each mass ever is, and the corridor sweep reads that, so a
 * lane exists past both at every phase rather than merely on the beat.
 */
const WALK_OUT = { kind: 'drift', reach: 0.06, phase: 0 } as const;
const WALK_BACK = { kind: 'drift', reach: 0.06, phase: 0.5 } as const;

/**
 * Two breathing gaps, and the second is shut while the first is open.
 *
 * Taking the first one the moment it opens puts the swarm at the second one at its
 * narrowest; waiting a beat costs ground against the drift. In water that choice
 * is made in the second before the gate. Here a correction takes about ten of the
 * cycle's eleven seconds, so the choice is made before either gap is on screen -
 * which is why this pair is in the dark station rather than anywhere it could be
 * eyeballed.
 */
const PULSE_OPEN = { kind: 'aperture', reach: 0.055, phase: 0.25 } as const;
const PULSE_SHUT = { kind: 'aperture', reach: 0.055, phase: 0.75 } as const;

export const ORBIT_LEVELS: Level[] = [
  {
    key: 'freefall',
    name: 'Free Fall',
    depthMeters: -140000,
    subtitle: 'Nothing pulls you back',
    zone: ZONE_SPACE,
    medium: 'space',
    decor: 'void',
    /*
     * The gentlest pace in the whole campaign, and the reason is the input rather
     * than the altitude: the player has just had the one thing they have done for
     * three acts stop working, and they need a station to find out what replaced
     * it before anything at all is asked of them.
     */
    pace: 0.3,
    // Vacuum has no noise in it. `roughness` is the medium's turbulence and there
    // is no medium, so it is zero here and stays low for the whole act - the only
    // thing that moves a mote up here is a trajectory.
    roughness: 0,
    swirl: 0,
    /*
     * 320, 1180, 320, 340, 560, 760, 340, 320, 480 - 4620 px, and the only station
     * in the act with three open sections in it.
     *
     * Its long fall is written *between* the first two sections rather than in
     * front of them, which is the one place the act's shape is bent, and the
     * reason is that a first section has no previous section to be spaced from.
     * `ObstacleSystem` starts every course at `FIRST_SECTION_OFFSET`, so the
     * number authored on section 0 is counted in the act's length and never
     * applied to the course: a station written 1180, 320, 320, ... would put its
     * node 960 px in, standing inside the opening screen before the run has begun.
     * The 320 that cannot be applied is written first instead.
     *
     * It keeps its share of the silence. Six obstacles across 3.8 minutes where
     * the rest of the act runs at nine and ten, because this is the station where
     * the player finds out that a stroke has stopped shoving and started bending,
     * and that discovery needs room to be got wrong in four or five times. What it
     * gained is a second movement: the same three lessons, met again with one of
     * them moving.
     */
    sections: [
      // The first thirty seconds of act IV: one very wide ring in the middle of
      // the field and nothing else in the frame at all. The lesson is that a
      // stroke no longer shoves - it *bends* - and it is taught by there being
      // room to fail at it four or five times without consequence.
      coast(320, 0.5, 10, 1.7),
      {
        // The first arc, and it is barely bowed. A player who aims straight at it
        // still gets through; what they notice is that they arrived late and
        // sideways, which is the whole act in one section. Nothing it carries is
        // compulsory: this is the one wall in the act that is here to be missed,
        // and its ring sits 240 px in front of it rather than behind, so what is
        // lost by missing it is arithmetic rather than the line into the node.
        kind: 'arc',
        centre: 0.58,
        gap: 0.62,
        bow: 0.1,
        spacing: 1180,
        rings: [{ x: 0.58, dy: 240, count: 9, scale: 1.3 }],
      },
      {
        // The first node, 320 px behind the first arc, which is the act's cluster
        // in its teaching form: the answer arrives while the question is still on
        // screen. Weak, wide, and pulling *inward* with a ring in its calm centre,
        // so the first standing gravity the player meets is something that helps -
        // they learn what a well does by being carried by one before they are ever
        // asked to escape one. On the old metronome it turned up 820 px later,
        // long after the arc had stopped being the thing they were thinking about.
        kind: 'node',
        centre: 0.24,
        radius: 0.42,
        strength: 74,
        spacing: 320,
        rings: [must(0.24, 0, 11, 1.5)],
      },
      {
        /*
         * The hulk, and the reason it is in the teaching station.
         *
         * Orbit's splittable mass had never been authored in orbit. It sat in the
         * act's alphabet as the one knowingly-unused entry in the campaign, and
         * `tests/geometry.test.ts` carried an exemption for it - which is how an
         * act goes ten minutes on five shapes without anybody noticing that the
         * sixth was a cost rather than a spare part. Act V borrowed it first.
         *
         * It is here rather than deeper in because splitting a body and putting it
         * back together is a *habit* rather than a difficulty, and this act is the
         * worst place in the campaign to be learning one late: nothing damps
         * anything, so a swarm that comes out of the two channels in two pieces
         * stays in two pieces until something bends it back. Met 340 px behind a
         * well that is already pulling it left, the left channel is the one it is
         * being handed.
         *
         * A ring in each channel and neither compulsory - they are 0.74 of the
         * width apart, which is the splittable mass's exception to this game's
         * ring spacing and means the opposite of what a close pair means: no body
         * covers both, and taking both is what the split is *for*.
         */
        kind: 'hulk',
        centre: 0.56,
        radius: 0.095,
        spacing: 340,
        rings: [
          { x: 0.16, dy: -160, count: 10, scale: 1.35 },
          { x: 0.9, dy: -160, count: 10, scale: 1.35 },
        ],
      },
      // The breath, and the seam between the station's two movements. Everything
      // in front of it is act IV being taught; everything behind it is the same
      // three lessons with the world no longer holding still.
      coast(560, 0.72, 10),
      {
        /*
         * The first thing in this act that moves, and it is deliberately the
         * easiest one to miss.
         *
         * The slowest station in the campaign, a gap authored at 0.50 of the width
         * - wider than anything the act asks for later - and a compulsory ring 250
         * px in front of it. A player who never notices that it is breathing still
         * goes through, because what is authored is the shut phase. A player who
         * does notice has just learned the act's second question without being
         * told it, and has about eleven seconds to decide what to do about it,
         * which in a medium with no drag is exactly one correction.
         */
        kind: 'arc',
        centre: 0.3,
        gap: 0.5,
        bow: 0.1,
        spacing: 760,
        motion: PULSE,
        rings: [must(0.3, 250, 10)],
      },
      {
        // The act's narrows, at its widest anywhere: two debris streams converging
        // into a lane, and the mouth starts inside the field on both sides. See
        // the Umbra for what happens when it does not.
        kind: 'strait',
        centre: 0.64,
        gap: 0.48,
        mouth: 0.34,
        depth: 200,
        spacing: 340,
        rings: [{ x: 0.64, dy: 225, count: 10, scale: 1.3 }],
      },
      {
        // The station's last demand, and it carries no gate - see the header. A
        // well that pushes, with the debris that collected at its radius drawn as
        // a line through it, so the first repelling node the player meets is one
        // they can *see*. The invisible pair is the Well's, four stations later, and
        // it only works because of this one.
        kind: 'node',
        centre: 0.34,
        radius: 0.4,
        strength: -84,
        gap: 0.5,
        spacing: 320,
        rings: [{ x: 0.34, dy: 0, count: 10, scale: 1.4 }],
      },
      landing(480, 0.5, 10),
    ],
  },
  {
    key: 'aurora',
    name: 'The Aurora',
    depthMeters: -180000,
    subtitle: 'The light that burns',
    zone: ZONE_SPACE + 1,
    medium: 'space',
    decor: 'void',
    pace: 0.34,
    roughness: 0,
    swirl: 0,
    /*
     * Seen from above, which almost nobody has. The curtains are *below* the
     * swarm, and what makes them a hazard rather than scenery is what they
     * actually are: the place where the solar wind is being dumped into the top
     * of the atmosphere along the field lines. It is the first thing since the
     * anvil's raptors that can take a mote, and the last for the rest of the act.
     *
     * 980, 320, 320, 620, 600, 340, 340, 320, 480, 450, 440 - 5210 px. Two
     * movements, each of them a curtain and then two things too close behind it to
     * be thought about separately, and the station's two halves are the same
     * sentence with one word changed: in A the cluster is a wall and a well, and
     * in B the wall is walking.
     *
     * It closes on a **couplet** - 480 px and then 450, with the two gaps a third
     * of the width from each other. That distance is chosen against the one thing
     * this game has always been about: the current you laid three seconds ago is
     * not the current you are on, and up here it is the trajectory you set fifteen
     * seconds ago. Neither half carries a compulsory ring. The first is excused
     * because building the line for the second gate and holding a body inside a
     * ring are two demands on one section; the second because a station does not
     * end on a gate.
     */
    sections: [
      {
        // The first curtain, and it is generous: three doors, all wide. The one it
        // asks for is the right-hand one, where the last compulsory ring was at
        // 0.30 - a step of nearly half the field, given 2180 px of course to be
        // made in, which is the gentle version of what this act's rings do.
        kind: 'flare',
        gaps: [0.22, 0.5, 0.78],
        gap: 0.24,
        spacing: 980,
        rings: [must(0.78, 190, 10)],
      },
      {
        // The act's ramp is the bow, and every climbing station carries its own
        // step of it. This is the second station's, and the first arc a player who
        // aims straight at it does not get through.
        //
        // 320 px behind the curtain, which for this pair is the point: the door
        // taken decides the line into the arc, and there is no room to change it.
        kind: 'arc',
        centre: 0.34,
        gap: 0.5,
        bow: 0.18,
        spacing: 320,
        rings: [{ x: 0.34, dy: 220, count: 10, scale: 1.3 }],
      },
      {
        // ...and the third thing in the cluster, which is what this act's doubling
        // bought. A well that pushes, sitting on the far side of the field from the
        // arc's mouth, so the correction that took the mouth is the correction it
        // spends the next ten seconds undoing.
        kind: 'node',
        centre: 0.68,
        radius: 0.36,
        strength: -92,
        spacing: 320,
        rings: [{ x: 0.68, dy: 0, count: 10, scale: 1.4 }],
      },
      coast(620, 0.26, 10),
      {
        // The second curtain. Its doors are offset from the first one's by about a
        // fiftieth of the width, which is not enough to be a new shape and is
        // exactly enough that a line remembered from the first one arrives on the
        // wrong side of a door post.
        kind: 'flare',
        gaps: [0.2, 0.48, 0.78],
        gap: 0.24,
        spacing: 600,
        rings: [{ x: 0.2, dy: 185, count: 10, scale: 1.35 }],
      },
      {
        /*
         * The first thing in the act that walks.
         *
         * A hulk on a slightly different inclination: 0.06 of the width either
         * way, on the breath's own eleven seconds, which up here is a fair drawing
         * of what a piece of debris in a crossing orbit actually does. Its two
         * channel rings are 0.74 of the width apart and both optional, and what
         * moves is not the rings - it is how much room there is to get to them.
         *
         * It is introduced alone, in a station whose other demands are all still,
         * and with no compulsory ring anywhere near it: the first time a player
         * meets a moving mass should cost a count and not a station.
         */
        kind: 'hulk',
        centre: 0.42,
        radius: 0.1,
        spacing: 340,
        motion: WALK,
        rings: [
          { x: 0.1, dy: -165, count: 10, scale: 1.35 },
          { x: 0.84, dy: -165, count: 10, scale: 1.35 },
        ],
      },
      {
        // A breathing narrows, and the act's first collision of two demands: the
        // gap in front of you is moving and the mass behind you has just decided
        // which side of it you came out on. The compulsory ring is on the far side
        // of the field from the coast's, so the only body that takes it left the
        // curtain through the right-hand door.
        kind: 'strait',
        centre: 0.7,
        gap: 0.46,
        mouth: 0.28,
        depth: 200,
        spacing: 340,
        motion: PULSE,
        rings: [must(0.7, 230, 11)],
      },
      {
        // A puller, with its ring 235 px past the eye rather than on it. `node`
        // places its well 16 px forward of the section line, so a ring authored at
        // dy 0 sits just *behind* the attractor - in a medium with no damping the
        // well spends the hold pulling the swarm forward off the thing it is being
        // asked to hold. It is optional here; the compulsory version of the same
        // mistake is what the Well's first section is written around.
        kind: 'node',
        centre: 0.3,
        radius: 0.34,
        strength: 90,
        spacing: 320,
        rings: [{ x: 0.3, dy: -235, count: 10, scale: 1.4 }],
      },
      {
        // The couplet's first half. 480 px at pace 0.34 is about twenty seconds,
        // which sounds like plenty and is not: the second gate's mouth is a third
        // of the field away, a correction here takes ten of those seconds to
        // arrive, and by then this arc is behind the swarm. The line for the
        // second one has to be laid before entering this one.
        kind: 'arc',
        centre: 0.66,
        gap: 0.48,
        bow: 0.16,
        spacing: 480,
        rings: [{ x: 0.66, dy: -210, count: 10 }],
      },
      {
        kind: 'arc',
        centre: 0.32,
        gap: 0.46,
        bow: 0.14,
        spacing: 450,
        rings: [{ x: 0.32, dy: 205, count: 11, scale: 1.35 }],
      },
      landing(440, 0.5, 10),
    ],
  },
  {
    key: 'umbra',
    name: 'The Umbra',
    depthMeters: -240000,
    subtitle: "The Earth's own shadow",
    zone: ZONE_SPACE + 2,
    medium: 'space',
    decor: 'void',
    pace: 0.38,
    roughness: 0,
    swirl: 0,
    /*
     * The darkest frame in the game by a long way: the swarm passes into the cone
     * of the planet's shadow, and for four minutes the gold it is carrying is the
     * only light source there is. Everything else in the frame is inferred from
     * it - the debris is lit by the swarm, and where the swarm is not, there is
     * nothing to see at all.
     *
     * Mechanically that makes this the station about **committing early**, because
     * the geometry arrives later than anywhere else in the campaign. So its gaps
     * are the widest in the act - 0.46 to 0.52 where the Debris Belt runs 0.44 - and
     * what is hard here is knowing rather than fitting.
     *
     * 1080, 320, 320, 560, 600, 580, 520, 340, 570, 320, 420 - 5630 px. The 1080
     * in front of the first arc is the act's long fall at full length, and a fall
     * through a frame with nothing lit in it reads as much longer than one that has
     * stars to be measured against.
     *
     * ### The one number in the station that is not about spacing
     *
     * The 570 between the arc and the narrows in the second movement is two breaths
     * at this pace, and it is the only spacing in the act chosen in seconds rather
     * than in pixels. See `PULSE_OPEN`/`PULSE_SHUT`: those two gaps are half a
     * cycle out of step, so the second is shut while the first is open, and a swarm
     * that takes the first the moment it opens arrives at the second at its
     * narrowest. It is a timing demand, authored in the one station where nothing
     * can be timed by eye - which is the point of it and also the reason both gaps
     * are 0.48 or wider. The demand is *when*, and it is not allowed to also be
     * *whether it fits*.
     */
    sections: [
      {
        kind: 'arc',
        centre: 0.28,
        gap: 0.52,
        bow: 0.22,
        spacing: 1080,
        rings: [must(0.28, 225, 11)],
      },
      {
        // The station's own sentence: a throat the player has to be lined up
        // with before they can see it. Everywhere else in the act the geometry
        // arrives in time to be read; here it does not, and that is the dark.
        //
        // Its mouth is 210 px deep rather than the archetype's 250. At 320 px
        // behind an arc, a 250 px mouth begins while the arc's own wings are still
        // arriving, and two sections' debris at the same altitude is a wall nobody
        // authored.
        // `mouth` is a *half*-width, so at 0.52 the right shoulder started 55 px
        // off the field and only entered it 110 px into a 210 px funnel: the act's
        // one 'hold a narrow line' section was a single wall for the first half of
        // its own mouth. 0.40 puts the shoulders at 86 and 398, symmetric about a
        // 390 px field, which is what the shape is for.
        kind: 'strait',
        centre: 0.62,
        gap: 0.48,
        mouth: 0.4,
        depth: 210,
        spacing: 320,
        rings: [{ x: 0.62, dy: 215, count: 11, scale: 1.3 }],
      },
      {
        // Third in the cluster, and unlit: a well with no debris ringing it, met
        // in the dark 320 px behind a funnel the swarm is still inside. There is
        // nothing at all to see here and the trajectory changes anyway.
        kind: 'node',
        centre: 0.34,
        radius: 0.38,
        strength: -96,
        spacing: 320,
        rings: [{ x: 0.34, dy: 0, count: 11, scale: 1.4 }],
      },
      coast(560, 0.74, 11),
      {
        // An auroral curtain inside the Earth's shadow, which is not a licence:
        // the aurora is *brightest* on the night side, because that is where the
        // tail dumps its particles. It is the only thing in this station other than
        // the swarm that emits any light, so it is also the only section here whose
        // geometry can be read before it arrives - which is what the two behind it
        // are measured against.
        kind: 'flare',
        gaps: [0.24, 0.52, 0.8],
        gap: 0.26,
        spacing: 600,
        rings: [{ x: 0.8, dy: 190, count: 11, scale: 1.35 }],
      },
      {
        // Three committed lines with no rest between them, in the frame where a
        // row is not visible until the swarm's own light reaches it. The ring is at
        // the first row's door, 60 px in front of it, because a chicane's demand
        // starts before its geometry does.
        kind: 'shrapnel',
        gap: 0.48,
        rows: 3,
        swing: 0.13,
        first: -1,
        spacing: 580,
        rings: [{ x: 0.37, dy: 480, count: 11, scale: 1.3 }],
      },
      {
        kind: 'hulk',
        centre: 0.56,
        radius: 0.095,
        spacing: 520,
        rings: [
          { x: 0.18, dy: -160, count: 11, scale: 1.35 },
          { x: 0.9, dy: -160, count: 11, scale: 1.35 },
        ],
      },
      {
        // The counter-phase pair, first half: open at the top of the cycle. Its
        // ring is the station's last compulsory one and it is on this half rather
        // than the second, so the demand the pair actually makes - wait a beat -
        // is never asked for and paid for on the same section.
        kind: 'arc',
        centre: 0.3,
        gap: 0.5,
        bow: 0.2,
        spacing: 340,
        motion: PULSE_OPEN,
        rings: [must(0.3, 215, 11)],
      },
      {
        // ...and the second half, 570 px later, which is two breaths at this pace
        // and therefore arrives shut for anybody who took the first one on sight.
        // The gaps are also a third of the width apart, so this is a couplet as
        // well - the same demand written in both units at once, which is the only
        // place in the act that happens.
        kind: 'strait',
        centre: 0.64,
        gap: 0.48,
        mouth: 0.32,
        depth: 200,
        spacing: 570,
        motion: PULSE_SHUT,
        rings: [{ x: 0.64, dy: 210, count: 11, scale: 1.3 }],
      },
      {
        // The station's last demand: a puller with its ring past the eye, and no
        // gate on it. After two gaps that had to be waited for, something that
        // simply carries the swarm.
        kind: 'node',
        centre: 0.48,
        radius: 0.4,
        strength: 104,
        spacing: 320,
        rings: [{ x: 0.48, dy: -240, count: 11, scale: 1.4 }],
      },
      landing(420, 0.5, 11),
    ],
  },
  {
    key: 'debris',
    name: 'The Debris Belt',
    depthMeters: -320000,
    subtitle: 'What we left behind',
    zone: ZONE_SPACE + 3,
    medium: 'space',
    decor: 'void',
    pace: 0.42,
    roughness: 0,
    swirl: 0,
    /*
     * The one band in the campaign with anything man-made in it, and the act's
     * densest station. Everything here is something that stopped working and kept
     * going anyway, which is the quietest thing this game says about people.
     *
     * It is also where the act's ramp lands. Act IV does not escalate by narrowing
     * any more than act III did - its gaps stay wide - it escalates on **how early
     * you have to have decided**, which is `bow`, and the bow steps 0.22 to 0.34
     * here. Every other station in the act steps 0.02 to 0.08. The Well's arc is
     * deeper by eight hundredths because the ramp is not allowed to run downhill,
     * but the station that changes what the act costs is this one.
     *
     * 1080, 320, 340, 620, 560, 620, 360, 360, 400, 380, 320, 440 - 5800 px, ten
     * obstacles, and 2.95 a minute against the act's 2.1. Both of its movements are
     * clusters of four: the ramp's bow, a well, a hulk and a chicane in the first,
     * and a curtain, the scissor, a narrows and a well in the second.
     *
     * ### The scissor, and why it is here rather than anywhere else
     *
     * Two hulks 360 px apart, walking on opposite halves of one clock. It is the
     * hardest thing in the act and it is authored in the only station where it is
     * not a set-piece: a debris belt is by definition a place where things nobody
     * is flying any more are crossing each other's tracks. The Aurora taught the
     * single walking mass with nothing else in the frame; this is that object
     * doubled rather than a new one to learn, and there is no phase at which
     * either of them is where you last saw it.
     */
    sections: [
      {
        kind: 'arc',
        centre: 0.7,
        gap: 0.44,
        bow: 0.34,
        spacing: 1080,
        rings: [must(0.7, 235, 12)],
      },
      {
        // The gap is inside the thing pushing you out of it. A negative
        // `strength` is a well that repels, and its lane sits on its own centre,
        // so the correction that gets the swarm into the lane is the correction
        // the well spends the next ten seconds undoing.
        kind: 'node',
        centre: 0.38,
        radius: 0.34,
        strength: -112,
        gap: 0.44,
        spacing: 320,
        rings: [{ x: 0.38, dy: 240, count: 12, scale: 1.3 }],
      },
      {
        // Third in the cluster: a mass to split on, 340 px behind a well that has
        // just pushed the swarm off the lane it was holding. Both channels are
        // open and the body arriving at them is not one body any more.
        kind: 'hulk',
        centre: 0.64,
        radius: 0.095,
        spacing: 340,
        rings: [
          { x: 0.2, dy: -160, count: 12, scale: 1.35 },
          { x: 0.9, dy: -160, count: 12, scale: 1.35 },
        ],
      },
      {
        // Three committed lines and the first movement's last word. Its ring is at
        // the first gap, 60 px in front of the first row, because a chicane's
        // demand starts before its geometry does: this is one of two compulsory
        // rings in the act that have to be held *entering* something rather than
        // clear of it, and the two rows after it are what the holding is for.
        kind: 'shrapnel',
        gap: 0.46,
        rows: 3,
        swing: 0.15,
        first: -1,
        spacing: 620,
        rings: [must(0.35, 480, 12)],
      },
      coast(560, 0.74, 12),
      {
        kind: 'flare',
        gaps: [0.2, 0.5, 0.8],
        gap: 0.26,
        spacing: 620,
        rings: [{ x: 0.8, dy: 190, count: 12, scale: 1.35 }],
      },
      {
        // The scissor, out. Its swept envelope runs 0.218 to 0.582 of the width,
        // which is what the corridor sweep reads rather than the authored circles -
        // both channels stay open at every phase, and what changes is which of them
        // the line laid at the curtain was ever going to reach.
        kind: 'hulk',
        centre: 0.4,
        radius: 0.1,
        spacing: 360,
        motion: WALK_OUT,
        rings: [
          { x: 0.1, dy: -165, count: 12, scale: 1.35 },
          { x: 0.84, dy: -165, count: 12, scale: 1.35 },
        ],
      },
      {
        // ...and back. One ring, in the right-hand channel, and it is the wrong one
        // for a swarm that came down the left of the first hulk - which is the
        // whole sentence: the pair does not have a line through it, it has a line
        // through the shape the pair is going to be.
        kind: 'hulk',
        centre: 0.6,
        radius: 0.095,
        spacing: 360,
        motion: WALK_BACK,
        rings: [{ x: 0.86, dy: -160, count: 12, scale: 1.35 }],
      },
      {
        kind: 'strait',
        centre: 0.28,
        gap: 0.46,
        mouth: 0.28,
        depth: 200,
        spacing: 400,
        rings: [must(0.28, 225, 12)],
      },
      {
        // A breathing gate at the densest point in the act, 380 px behind a funnel
        // the swarm is only just out of. It is authored shut at 0.46, so it is
        // still the widest thing in the station.
        kind: 'arc',
        centre: 0.66,
        gap: 0.46,
        bow: 0.3,
        spacing: 380,
        motion: PULSE,
        rings: [{ x: 0.66, dy: 215, count: 12, scale: 1.3 }],
      },
      {
        // The station's last demand, and no gate on it: a puller with its ring
        // past the eye, which after four things in a row is the first object in
        // three hundred seconds that is on the swarm's side.
        kind: 'node',
        centre: 0.36,
        radius: 0.36,
        strength: 98,
        spacing: 320,
        rings: [{ x: 0.36, dy: -240, count: 12, scale: 1.4 }],
      },
      landing(440, 0.5, 12),
    ],
  },
  {
    key: 'well',
    name: 'The Well',
    depthMeters: -400000,
    subtitle: 'Where everything falls',
    zone: ZONE_SPACE + 4,
    medium: 'space',
    decor: 'void',
    pace: 0.44,
    roughness: 0,
    swirl: 0,
    /*
     * The station named after gravity, and its body is made of nothing else.
     *
     * It used to be a node, an arc and a breath, which is to say it was mostly
     * geometry with a well standing next to it. What it opens with now is two
     * `node` sections 320 px apart with opposite signs and **no debris in either**
     * - a `node` with no `gap` field emits no blobs at all - so for the first and
     * only time in the campaign **the hazard is invisible and is made of the same
     * stuff as the cure.** The player's own hand deposits into the same
     * `PotentialField` these two are standing in, and there is nothing else in the
     * frame to blame.
     *
     * Two opposed wells that close together is a slingshot. The first pulls in,
     * the second pushes away, their fields are summed rather than met in turn, and
     * the only line through the pair is a curve that uses the first to set up the
     * second. It needs no new archetype and no new code: it is two sections that
     * already existed, at a spacing nobody had tried.
     *
     * 1080, 320, 620, 780, 340, 340, 620, 460, 620, 450, 460 - 6090 px, and the
     * longest station in the act by pixels rather than by minutes. Its second
     * movement is the last hard thing in the climb: the deepest bow in the campaign,
     * a hulk, a lane that will not hold still, a chicane, a narrows, and then the
     * act's last couplet, which is where it stops asking.
     *
     * ### The lane inside the well
     *
     * The third thing in the second cluster is a `node` with a `gap` and an
     * `aperture` on it: a well that pushes the swarm out of the only way through
     * itself, and the way through breathes. It is the act's own object doing the
     * act's new trick, in the station the object is named after, and it is the last
     * new idea in the climb - everything after it is this act's existing vocabulary
     * being said one more time and then let go of.
     */
    sections: [
      {
        kind: 'node',
        centre: 0.68,
        radius: 0.42,
        strength: 138,
        spacing: 1080,
        // 240 px past the well's eye rather than on it. `node` places its well 16 px
        // forward of the section line, so a ring authored at dy 0 sits just *behind*
        // the attractor - in a medium with no damping the well spends the hold
        // pulling the swarm forward off the thing it is being asked to hold.
        rings: [must(0.68, -240, 12, 1.4)],
      },
      {
        // The other sign, 320 px on. Each well is 164 px in radius and their
        // centres are 320 apart, so their edges meet with no neutral vacuum
        // between them: from the moment the first has hold of the swarm, what it
        // is falling through is the sum of the two rather than either of them.
        // 0.34 or a wider spacing and the station is two puzzles again.
        //
        // This is the act's one exception to "a cluster carries one compulsory
        // ring": these two are 125 px apart across 80 px of course, which is well
        // outside the sweep's lateral budget, and it holds only because there is no
        // geometry anywhere in the pair and the rings' own radii cover the rest.
        kind: 'node',
        centre: 0.36,
        radius: 0.42,
        strength: -132,
        spacing: 320,
        rings: [must(0.36, 0, 12, 1.4)],
      },
      coast(620, 0.74, 12),
      {
        // The act's ramp is `bow`, and the Debris Belt stepped it 0.22 -> 0.34. A 0.02
        // step after that made 'the last hard thing in the climb' the thinnest
        // station in the act; 0.42 is a real step, and the gap opens by the same
        // two hundredths so the demand stays commitment rather than width.
        //
        // Its ring is on the far side of the field from the coast's, so the only
        // swarm that takes it is one that started turning a full long fall ago.
        kind: 'arc',
        centre: 0.26,
        gap: 0.46,
        bow: 0.42,
        spacing: 780,
        rings: [must(0.26, 240, 13)],
      },
      {
        kind: 'hulk',
        centre: 0.48,
        radius: 0.1,
        spacing: 340,
        rings: [
          { x: 0.12, dy: -165, count: 12, scale: 1.35 },
          { x: 0.86, dy: -165, count: 12, scale: 1.35 },
        ],
      },
      {
        // A well that pushes, with the debris that collected at its radius drawn
        // as a line through it - and the line breathes. Authored shut at 0.50 of
        // the width, which is the widest aperture in the act, because this one is
        // asking for two things at once: be in the lane, and be in it while
        // something is pushing you out of the lane. The gap is not also the
        // question.
        kind: 'node',
        centre: 0.5,
        radius: 0.38,
        strength: -100,
        gap: 0.5,
        spacing: 340,
        motion: PULSE,
        rings: [{ x: 0.5, dy: 230, count: 12, scale: 1.3 }],
      },
      {
        // The act's last chicane, and its ring is at the first row's door 60 px in
        // front of it. Three committed lines is a shape act IV can only ask for
        // where it has just been given somewhere to build the line from, which is
        // what the 620 px in front of it is.
        kind: 'shrapnel',
        gap: 0.46,
        rows: 3,
        swing: 0.14,
        first: 1,
        spacing: 620,
        rings: [must(0.64, 480, 13)],
      },
      {
        kind: 'strait',
        centre: 0.66,
        gap: 0.46,
        mouth: 0.32,
        depth: 200,
        spacing: 460,
        rings: [{ x: 0.66, dy: 225, count: 12, scale: 1.3 }],
      },
      {
        // The act's last couplet, and the last thing the climb asks for: 450 px
        // between two mouths a third of the width apart, in the fastest water in
        // the act, with no compulsory ring on either. Everything the act has said
        // about laying a line before the thing it is for, said once more with
        // nothing at stake except the count.
        kind: 'arc',
        centre: 0.3,
        gap: 0.48,
        bow: 0.34,
        spacing: 620,
        rings: [{ x: 0.3, dy: -210, count: 12 }],
      },
      {
        kind: 'arc',
        centre: 0.64,
        gap: 0.46,
        bow: 0.32,
        spacing: 450,
        rings: [{ x: 0.64, dy: 205, count: 12, scale: 1.35 }],
      },
      landing(460, 0.5, 12),
    ],
  },
  {
    key: 'overview',
    name: 'The Overview',
    depthMeters: -460000,
    subtitle: 'Where the whole of it shows',
    zone: ZONE_SPACE + 5,
    medium: 'space',
    decor: 'void',
    /*
     * The emotional peak of the campaign, and the station that asks for the least.
     *
     * Everything that has been escalating for four acts stops here. The pace is
     * the lowest in the game, there are no nodes, there is no geometry at all, and
     * the last section has nothing in it - because the camera is about to turn,
     * the whole Earth is about to arrive, and the entire atmosphere the player has
     * spent forty minutes climbing is about to resolve into one bright line a few
     * pixels thick. A station with anything to do in it could not carry that.
     *
     * No results screen arrives. The handover is the campaign turning over: from
     * the next act the game runs downward.
     *
     * **The rebuild that doubled the other five stations did not touch this one,
     * by a pixel.** It is the only station in the act with nothing in it, and the
     * only lever the length plan has is putting something in a station.
     */
    pace: 0.24,
    roughness: 0,
    swirl: 0,
    // Two sections, and they are the two longest falls in the act: 1000 then
    // 1600, where the rest of the act runs in clusters of 320. Every other
    // station here is a long fall *into* something. This one is the long fall
    // with the something taken out, and 2600 px at pace 0.24 is two and a half
    // minutes in which nothing at all is going to happen.
    //
    // Slowblue: it was 1400 then 1200, and the ring was compulsory. Both were wrong
    // for what this station is. A compulsory ring in an act whose failure policy
    // is `restart` means the campaign's emotional peak could be taken away for
    // missing a *reward* - the frame the whole act climbs toward, re-flown, for
    // failing something with no next line to be drawn from. And 1400 px at pace
    // 0.24 put 86 s of nothing in front of the ring and 74 s behind it, so the
    // emptiest station in the game spent its long half before its only event
    // rather than after. The station's 2600 px is unchanged; what moved is which
    // side of the ring the silence is on.
    sections: [
      { kind: 'open', spacing: 1000, rings: [{ x: 0.7, dy: 0, count: 12, scale: 1.6 }] },
      // The last section of the climb, and there is nothing in it at all. This
      // is where the camera turns, and it is now the longest empty run in the
      // campaign - which is what the turn is for.
      { kind: 'open', spacing: 1600 },
    ],
  },
];

/**
 * Act IV: six stations, the Karman line to the top of the arc.
 *
 * The last act that climbs. Its failure policy is the upper acts' - a station
 * begins again rather than a campaign ending - which for this act is not a
 * softening but the design: a scattered swarm, a missed node or a bad trajectory
 * costs time and score and never the journey.
 *
 * That policy is also what the rebuild's arithmetic has to be read against. A
 * station is 3.4 minutes now rather than 1.7, so the price of losing one has
 * doubled - and the budget doubled with it rather than being left behind. It is a
 * rate now: `restartsForMinutes` reads the act's own authored length, so this act
 * carries three attempts where it carried two. See DESIGN-LENGTH §10.
 */
export const ACT_ORBIT: Act = makeAct('orbit', ORBIT_LEVELS, {
  carrier: 'lights',
});
