import { makeAct, type Act, type Level, type RingSpec, type SectionSpec } from './levels';
import { ZONE_THIN } from './zones';

/**
 * Slowblue: act III - the thinning.
 *
 * ## The act that is about waiting
 *
 * Eleven kilometres to a hundred, and the carrier has no body plan at all. What
 * goes up from the top of the anvil is what a bird was carrying rather than the
 * bird: spores, seeds, aerosols, ice nuclei. Every one of those is a real thing
 * that really is up there - the stratosphere is full of dust that got lifted and
 * has not come down yet - and none of them can swim, fly, or do anything about
 * where it is going. That is the act's whole design in one sentence.
 *
 * So the verb changes for the first time since the trench floor, and it changes
 * without the input changing. The stroke is the same stroke. What is different is
 * that up here the stroke is *small* - `thinCoupling` is a third of the water's
 * grip - and the medium is *enormous*: the upper atmosphere separates into deep
 * horizontal layers moving at very different speeds and in opposite directions,
 * and a thing with no engine that gets into the right one is simply taken where
 * that layer is going.
 *
 * **Wait, and choose a layer.** The hand still lays a current, but the current is
 * now a correction inside something much larger than itself, and the skill is
 * picking which large thing to be inside. See `sim/LayeredFlow.ts` for the field
 * and for why its vertical component runs on the eleven-second breath.
 *
 * ## Six stations, and two of them are inherited
 *
 * The Nacreous and The Noctilucent used to be act II's last two, flown by birds. No
 * bird has ever been to either - there is no air at 25 km to fly in, let alone at
 * 82 - and they are the two most beautiful places in the game, so they were not
 * cut, they were given to a carrier that can actually be there. That is the
 * single largest structural change the campaign made, and it is the one that
 * makes the rest of it honest.
 *
 *   1. **The Jet Stream** (11 km) - the tropopause, and the fastest air on Earth.
 *   2. **Ozone Blue** (20 km) - the deepest blue there is, and the first wave.
 *   3. **The Nacreous** (25 km) - nacreous cloud, which *is* a standing wave made
 *      visible, so the station where the wave matters most is the one where the
 *      player can see it.
 *   4. **The Black Sky** (50 km) - stars in daylight. Almost nothing left to steer.
 *   5. **The Noctilucent** (82 km) - the last cloud on the planet.
 *   6. **The Line** (100 km) - the Karman line. The winds go to nearly nothing,
 *      and the act ends on the discovery that a stroke has stopped working.
 *
 * ## The rebuild, and the one thing it was not allowed to spend
 *
 * The circuit was measured in `docs/DESIGN-LENGTH.md` and the fault was not the
 * hour, it was the distribution: acts I and II ask something every seventeen
 * seconds and this act asked something every forty-seven. Act V was rebuilt first
 * as the pilot - 10.9 authored minutes to 26.5 at byte-identical pace - and this
 * act is the second, at **10.2 minutes to 22.3 and thirteen obstacles to
 * forty-seven**, with `pace`, `roughness`, `swirl` and every `layers` block
 * untouched to the digit.
 *
 * The thing that could not be spent is the emptiness. Act III was the thinnest
 * act in the campaign *on purpose*: it opens on a long arrival and the whole of
 * it is about patience, so filling the silences would have deleted the reason it
 * is a separate act at all. So none of the new length came from there. **Every
 * station's arrival is still the longest unbroken empty run in the game**, and
 * what changed is what happens after it:
 *
 * | | before | after |
 * | --- | ---: | ---: |
 * | sections | 20 | 65 |
 * | obstacles | 13 | 47 |
 * | authored minutes | 10.2 | 22.3 |
 * | obstacles a minute | 1.3 | 2.1 |
 * | moving sections | 0 | 11 |
 * | the arrivals, as a share of the act | 67 % | 28 % |
 *
 * That last row is the whole rebuild in one number. The arrivals are 10 600 px
 * against the old 11 400 - eight hundred pixels lighter across the entire act, and
 * spent on the fourth escalation axis below rather than on content. Nothing was
 * filled in. There is simply now something on the other side of them.
 *
 * **2.1 obstacles a minute is the bottom of the band the plan asked for, and the
 * arithmetic says it has to be.** A station is 2 000-odd pixels of arrival before
 * its first decision plus two rests, which is a minute and a half of nearly
 * nothing at this act's pace whatever else is in the station. Reaching act V's
 * 2.3 would mean pulling the decisions inside 420 px, and 420 px is this act's
 * floor for the reason given under the rhythm below.
 *
 * ## The rhythm: the drift comes first, and now it comes twice
 *
 * Every station in this file used to be authored the way every other act is
 * authored - things to do, then a rest - and the rest was a 900 px empty section
 * at the end of the list, laid on the campaign's one 820 px metronome. For an act
 * about waiting that is backwards. Up here the long empty stretch is not a
 * recovery from the station, it *is* the station: it is where the swarm sits in a
 * band and finds out where the band is taking it, and the decisions are what the
 * stretch delivers it to.
 *
 * So the empty section opens a station, and the decisions arrive close together
 * at the end of it. A doubled station is that sentence **said twice**:
 *
 *   - **the arrival**, 2 020 to 2 280 px of open air with a single wide ring
 *     floating in it - one `open` section plus the run out of it, and two `open`
 *     sections at the jet - in which nothing is asked and the bands do all of the
 *     moving;
 *   - **the first movement**, three decisions 420 to 560 px apart, which is act
 *     III exactly as it already was;
 *   - **the wait**, a second `open` at 420 px plus the long run out of it, a
 *     little over a thousand pixels in all: half the arrival, and the one place in
 *     a four-minute station the phone can go down;
 *   - **the second movement**, four to six decisions at 420 to 460 - the tightest
 *     thing act III does, and where the station's hardest question is;
 *   - **the landing**, 320 px of nothing.
 *
 * Two of those are new and both were measured rather than chosen, on act V, and
 * the measurements are in DESIGN-LENGTH §7. **A station ends on a rest**, because
 * a station's pressure ramp peaks at its own end and the rest is where the swarm
 * pays back the ground the ramp takes; and **a station's last demand never
 * carries a compulsory ring**, because a ring asks a body to stop and hold still
 * at exactly the moment the world is asking it to keep up. Built without the
 * first, act V measured 42.6 restarts a run against a baseline of 1.2; without
 * the second, 15.4; without either, 35.6.
 *
 * The landing is deliberately the shortest rest in the act, and that is act III
 * arithmetic rather than a softening: **it is joined to the next station's
 * arrival**, so the seam between two stations is 320 px of landing plus 2 100 px
 * of drift, and it is still by a long way the longest empty run in the game. The
 * old file made the same point by having no landing at all. It has one now
 * because the measurement says the ramp needs it, and it is small because the
 * thing on the other side of it is enormous.
 *
 * `tests/descent.test.ts` sums an act's length from these numbers rather than
 * assuming a flat spacing, so redistributing the minutes is free and spending
 * more of them is not.
 *
 * ### 420 px is the floor, and it is a floor in time
 *
 * Two decisions 420 px apart in a medium where a stroke has a third of the
 * water's grip is tight in *time* and not in width, and time is the only currency
 * this act charges in. It is about fifteen seconds at this act's pace, which is
 * one and a third breaths - long enough to lay one current and not long enough to
 * lay two. Nothing in this file goes below it, in either movement, at any station.
 *
 * ## The ring grammar: wide and rare
 *
 * Act III's demand is time and never precision, and its rings say so. Every other
 * act scales a compulsory ring at 1.2 to 1.35; this one runs **1.45 to 1.6** on a
 * compulsory ring and 1.4 to 1.55 on an optional one, and there are twenty-two
 * compulsory ones across six stations. That is **fewer per minute
 * than the act had before** - 0.99 against 1.08 - on a course with three and a
 * half times as much in it, which is the same correction act V's rebuild made and
 * for the same reason: a compulsory ring is the main way of losing a station, and
 * a station is now twice as expensive to lose.
 *
 * Three rules follow the ring rather than the section:
 *
 *   - a compulsory ring after a `shear` sits **at the door it is asking for**,
 *     never on the section's centre line, so choosing a band and taking the
 *     reward are one act rather than two;
 *   - never two compulsory rings on one section. A compulsory ring wants 28 % of
 *     the swarm held for 0.7 s, so a second one beside it asks for 56 % in two
 *     places at once, which is not a demand, it is a wall. The nacreous column
 *     had exactly that pair and one of its two rings is optional now;
 *   - the widths run *opposite* to the demand. The widest rings in the act are in
 *     the first station and the last, where almost nothing is being asked; the
 *     narrowest are in the middle, which is where act III asks the swarm to be in
 *     two places at once.
 *
 * **Act V's paired ring is deliberately not imported.** Two rings a third of the
 * width apart on one line is that act's answer to *scatter*, which is act V's
 * danger and not this one's - up here a scattered swarm is only a slow one. Act
 * III pays for width by making a single ring enormous instead, which is the same
 * idea in the one unit this act is allowed to spend.
 *
 * ## The second axis: eleven of these do not stand still
 *
 * Every obstacle in this act used to stand still, and this is the act with the
 * best claim to the opposite: **waiting for a gap to open is already its verb.**
 * `MotionSpec` is a modifier on a section rather than an alphabet of its own, so
 * each of these costs one line - see `levels.ts`, and act V's file for where they
 * were built.
 *
 *   - **An aperture breathes.** Seven of them, every one on a veil, authored
 *     **shut** - `gap` is the narrowest the door ever is - so the corridor sweep,
 *     which never advances a clock, is already checking the hardest phase. What
 *     the timing buys is *width*, which is the one thing this act refuses to
 *     charge for: arrive on the open half and the door is generous, arrive on the
 *     shut half and it is an ordinary act III door. The reach is 0.06 against act
 *     V's 0.055 for exactly that reason.
 *   - **A mass walks**, and the first one is the jet stream itself. See `MEANDER`.
 *   - **A scissor is two masses on opposite halves of one clock**, at the Black
 *     Sky, where the station already has exactly two winds and no third place to
 *     stand. See `WALK_OUT`/`WALK_BACK`.
 *   - **A counter-phase pair is two breathing doors, the second shut while the
 *     first is open**, at the mesopause, which is the station whose whole subject
 *     is waiting. See `PULSE_OPEN`/`PULSE_SHUT`.
 *
 * **The halved breath is act V's and stays there.** It is the only one of that
 * act's new devices this one refuses, and the reason is specific rather than
 * timid: up here the breath is not merely a section's clock, it is *the medium's*
 * - `LayeredFlow`'s whole vertical component runs on `BREATH_PERIOD`, so the lift
 * carrying the swarm toward a door is on the same eleven seconds the door is on.
 * A door at 5.5 would be the one thing in this act out of step with the air, and
 * an act that teaches the player to read a rhythm cannot then lie about it once.
 *
 * ## The ramp, and how it differs from the two acts below
 *
 * Act I and act II both escalate by *narrowing*: the gaps close from 0.58 to 0.26
 * of the width. Act III deliberately does not - its narrowest gap is 0.34, wider
 * than act II's last three stations - because the thing it is asking for is not
 * accuracy of placement. It escalates on three other axes instead:
 *
 *   1. **The wind gets stronger and the layers get thinner**, so being in the
 *      wrong one costs more and takes less time to happen.
 *   2. **The gravity wave arrives and then dominates**, so vertical progress goes
 *      from free to conditional on timing.
 *   3. **The grip goes on falling**, so the correction available to the hand
 *      shrinks against everything it is correcting.
 *
 * The rebuild adds a fourth that is drawn in spacing rather than in numbers:
 * **the arrival contracts as the air thins.** It is 1 100 + 1 180 px at the
 * tropopause and 1 000 + 1 020 at the mesopause, and the Karman line has none at
 * all. The same course, less and less time to think about it, and nothing about
 * it announced.
 *
 * `tests/thinning.test.ts` holds the first three, and holds the corridor sweep
 * that every act in the game has to pass.
 *
 * ## The pace band, and why it is half of act I's
 *
 * Every `pace` below runs between 0.36 and 0.46, against act I's 0.72-1.0 and act
 * II's 0.85-1.14. That is not the upper air being generous. It is the only band
 * the act can be played in at all, and the number that says so is the **forward
 * ceiling**: with the forced drift switched off entirely, a competent hand makes
 * 57 px/s up the course in thin air (`tools/thin.sweep.ts`). The bands cost about
 * 11 px/s of that on their own, which is the tax the act is *for*.
 *
 * The first version of this file carried act I's pace shape straight over, so the
 * drift ran `68 * 0.7..1.0 * (1 + pressure)` = 48 to 105 px/s against a 57 px/s
 * ceiling. The act was not hard; it was arithmetically impossible, and every
 * scripted run in the repo died `sweptAway` inside the first two stations however
 * well it was flown. The mistake was inherited rather than chosen: `worldSpeed`
 * is one number for the whole campaign, and it had never been re-derived for a
 * medium with a third of the water's grip carrying something with a quarter of
 * its drive. A mote is not a fish and cannot be chased at a fish's pace.
 *
 * At the band below, the drift opens each station at about half the ceiling and
 * peaks near four fifths of it, which leaves a competent hand real ground to make
 * and still collects anything that stops - a drifting mote self-drives at 20 px/s
 * (`thinMigrationSpeed`) and is under the drift from the first frame, so the
 * ending the act does have stays reachable.
 *
 * The band is also nearly **flat**, which the ramp above already demanded and the
 * old one quietly contradicted: act III escalates on counterflow, band thinness
 * and the wave's authority. Pace is not one of its three axes, and a station that
 * hurried the player more would be arguing with the act's own subject. **The
 * rebuild did not touch a digit of it**, which is the whole point of the exercise:
 * the game does not get faster, there is more of it.
 */

/**
 * Open air with one wide ring in it - the act's one piece of furniture, and it
 * plays three parts now.
 *
 * It was `breath()`, it was 900 px, and it closed a station. Then it opened one,
 * at a fixed 1 100 px. It is an argument now because a doubled station uses this
 * shape three times at three lengths: **the arrival** at the head, about 1 000 to
 * 1 100 and followed by another thousand of run before anything is asked; **the
 * wait** in the middle, about 420, which is the mid-station breath the length
 * plan calls for; and **the landing** at 320, which exists because a station's
 * pressure ramp peaks at its own end and is short because the next station's
 * arrival is immediately behind it.
 *
 * The ring is wide and deliberately *not* compulsory - it is the only reward in
 * the act that is offered rather than asked for, which is the correct thing to
 * put in front of a player who is not steering yet.
 *
 * Not to be read as act I's `drift` section kind, which is a chicane and is one
 * of the twelve shapes this act is forbidden to use.
 */
function drift(spacing: number, x: number, count: number, scale = 1.4): SectionSpec {
  return { kind: 'open', spacing, rings: [{ x, dy: -60, count, scale }] };
}

/**
 * A compulsory ring, on the line the section already asks for - and after a
 * `shear`, on the *door* it is asking for. The default width is act III's own:
 * see the ring grammar above for why it sits above the campaign's 1.2 to 1.35.
 */
function must(x: number, dy: number, count: number, scale = 1.5): RingSpec {
  return { x, dy, count, required: true, scale };
}

/**
 * The breath, as a period, and the widest thing this act ever gives away.
 *
 * A door authored shut that opens on the eleven seconds the player is already
 * breathing. Named here rather than passed, because a section that pulsed on some
 * other clock would be a second rhythm in a game that has one - and up here that
 * would be worse than untidy, because the medium itself is on this clock.
 *
 * The reach is 0.06 where act V's is 0.055, and the extra is the point: this is
 * the one act whose charter forbids escalating by narrowing, so an aperture here
 * is not a gap that closes on you, it is **width handed to whoever timed the
 * arrival**. Every one of them is on a `veil`, which is one wall with one hole in
 * it - `tests/motion.test.ts` keeps apertures off the multi-door shapes, and in
 * this alphabet that is `shear` and `flurry`.
 */
const PULSE = { kind: 'aperture', reach: 0.06 } as const;

/**
 * The jet stream meanders, so the jet stream's boundary walks.
 *
 * This is the first moving obstacle in act III and it is the only one in the
 * campaign that is a physical fact rather than a device: a real jet stream is a
 * Rossby wave, and the band's edge slides thousands of kilometres north and south
 * over days. A `shear` cannot breathe - it has two or three doors and an aperture
 * pivots on the widest of them, so the outer ones would open while the rest
 * pinched shut, which is the one way this feature can author something narrower
 * than the sweep checked. `tests/motion.test.ts` forbids it. But a curtain can
 * *walk*, and walking is the truer thing for this one to do anyway.
 *
 * The reach is 0.04 rather than the 0.05 the masses get, because a drift's
 * envelope is what the corridor sweep reads: a walking curtain narrows every one
 * of its doors by twice the reach at once, where a walking column narrows one
 * channel and widens the other.
 */
const MEANDER = { kind: 'drift', reach: 0.04 } as const;

/** A single mass that walks: aim at where the channel is going to be. */
const WALK = { kind: 'drift', reach: 0.05 } as const;

/**
 * Two masses on one clock and opposite halves of it: the scissor.
 *
 * A single walking mass asks "aim where the channel will be". A pair of them a
 * few hundred pixels apart, one going out while the other comes back, asks
 * something else: **there is no phase at which both are where you last saw them.**
 * A line laid for the first is always the wrong line for the second.
 *
 * It is safe for the same reason a single drift is - `Section.envelope` carries
 * the union of everywhere each mass ever is, and the corridor sweep reads that,
 * so a lane exists past both at every phase and not merely on the beat.
 *
 * It is at the Black Sky because that station already has exactly two winds and
 * no slow band between them, and two columns walking against each other is that
 * fact turned into objects the player can see.
 */
const WALK_OUT = { kind: 'drift', reach: 0.05, phase: 0 } as const;
const WALK_BACK = { kind: 'drift', reach: 0.05, phase: 0.5 } as const;

/**
 * Two breathing doors, and the second is shut while the first is open.
 *
 * Two breaths apart, so taking the first one the moment it opens arrives at the
 * second at its narrowest, and waiting one beat costs ground against the drift
 * and arrives on the open half of both. It is the only place in the campaign
 * where being early is a mistake, and it is at the mesopause because that is the
 * station whose stated demand is *wait*.
 */
const PULSE_OPEN = { kind: 'aperture', reach: 0.06, phase: 0.25 } as const;
const PULSE_SHUT = { kind: 'aperture', reach: 0.06, phase: 0.75 } as const;

export const THIN_LEVELS: Level[] = [
  {
    key: 'jet',
    name: 'The Jet Stream',
    depthMeters: -11000,
    subtitle: 'The fastest air there is',
    zone: ZONE_THIN,
    medium: 'thinAir',
    decor: 'void',
    // The gentlest pace in the campaign, and for the same reason the trench floor
    // is act I's: the player has just been handed a medium that answers
    // differently and needs a station to find out how before anything is asked of
    // them. See the note above for why the whole band sits here.
    pace: 0.38,
    // Low, everywhere in this act. `roughness` is the medium's *noise*, and thin
    // air is the quietest medium in the campaign - what moves a mote up here is
    // organisation, not turbulence. The organisation is `layers`, and it is in
    // px/s rather than in multiples of this.
    roughness: 0.45,
    swirl: 0,
    /*
     * The jet stream is a real river of air a few hundred kilometres wide moving
     * at two hundred knots, with much slower air above and below it. This is that,
     * as three bands: a fast one, a slow one, and one going gently the other way.
     * No gravity wave yet - one new idea per station.
     *
     * The numbers are in px/s and they are deliberately of the same order as the
     * ocean's own current in act I (55 px/s). A band has to be something the
     * player *works with* - measured at 150 the crosswind was stronger than any
     * stroke could hold a line against, and the act became eleven seeded runs of
     * correcting sideways and never once pushing forward.
     */
    layers: {
      height: 640,
      winds: [72, 16, -26],
    },
    /*
     * 1100, 1180, 420, 560, 500, 440, 700, 460, 440, 440, 320 - 6560 px, and the
     * longest station in the act at 4.2 minutes. It is also the emptiest, at 1.7
     * obstacles a minute against the act's 2.1, and both facts have the same
     * cause: **this is the one station whose arrival is two empty sections rather
     * than one.** Two thousand two hundred and eighty pixels of open air with the
     * bands already running underneath it is eighty-eight seconds in which the
     * only thing that happens is the swarm being carried sideways by something the
     * player did not do. That is the entire lesson of act III and it takes no
     * words at all.
     *
     * It costs a third of the station and it was not touched. What the rebuild
     * added is on the far side of it: a breathing door, a walking boundary, a
     * splittable column and a closing couplet, where there used to be one shear.
     */
    sections: [
      drift(1100, 0.34, 9),
      {
        // The second empty, and the widest ring in the game: still be somewhere on
        // purpose after a minute of being carried. It is a compulsory ring in a
        // section with no geometry in it at all, which is the only place in the
        // campaign that happens, and it is how this act says what it wants before
        // it has asked for anything.
        kind: 'open',
        spacing: 1180,
        rings: [must(0.5, 0, 10, 1.6)],
      },
      {
        // The act's own archetype, introduced as gently as it can be: two doors,
        // both wide, and nothing compulsory on it. Taking the right door is not
        // punished - it just puts the swarm somewhere the next band has to be
        // argued with.
        kind: 'shear',
        spacing: 420,
        gaps: [0.28, 0.72],
        gap: 0.3,
        rings: [{ x: 0.28, dy: 190, count: 10, scale: 1.4 }],
      },
      {
        /*
         * The first door in the campaign that breathes, and it is here for the
         * same reason act V put its first one in the deorbit: the slowest station
         * in the act, at nearly its widest gap, with nothing else in the frame.
         *
         * A player who does not notice that it is opening still gets through - it
         * is authored shut and 0.46 of the width is a wide door by this act's own
         * standards - and a player who does notice has just learned act III's
         * second question without being told it. Waiting for a gap to open is the
         * only demand in the campaign that is *already* this act's verb.
         */
        kind: 'veil',
        centre: 0.7,
        gap: 0.46,
        spacing: 560,
        motion: PULSE,
        rings: [must(0.7, 205, 10, 1.55)],
      },
      {
        // Three doors this time, and the middle one is the one asked for - so the
        // line that took the swarm through the left door of the shear two sections
        // back is the wrong line here. Nothing about the geometry says so; the wind
        // in the band it left you in does.
        kind: 'shear',
        spacing: 500,
        gaps: [0.22, 0.52, 0.82],
        gap: 0.26,
        rings: [{ x: 0.52, dy: 185, count: 10, scale: 1.45 }],
      },
      // The wait. Four hundred and forty pixels of nothing in the middle of a
      // station, which is one decision's worth of course spent on none.
      drift(440, 0.44, 10, 1.45),
      {
        /*
         * The jet stream meanders - see `MEANDER`. The whole layer boundary walks
         * sideways while the swarm closes on it, which is what a Rossby wave
         * actually does to a real jet, and it is the first thing in this campaign
         * that moves.
         *
         * The compulsory ring is 190 px in front of it and does not move. So the
         * demand is legible from a long way back: the reward stands still and what
         * changes is which door is under it by the time you arrive.
         */
        kind: 'shear',
        spacing: 700,
        gaps: [0.26, 0.66],
        gap: 0.3,
        motion: MEANDER,
        rings: [must(0.66, 190, 11, 1.5)],
      },
      {
        // The upper air's splittable mass. Cirrus really does grow in columns at
        // the tropopause, and this is the act's first one - a ring in each channel
        // and neither of them asked for, because splitting a body in a medium with
        // a third of the water's grip is a demand on its own the first time.
        kind: 'column',
        centre: 0.5,
        radius: 0.085,
        height: 3,
        spacing: 460,
        rings: [
          { x: 0.15, dy: -150, count: 11, scale: 1.4 },
          { x: 0.85, dy: -150, count: 11, scale: 1.4 },
        ],
      },
      {
        // The couplet, and the first one in the act: this throat and the veil 440
        // px after it have their gaps a third of the width apart, which at this
        // act's grip is too far to cross once you are in the first one. The line
        // for the second has to be laid before entering the first. Neither half
        // carries a compulsory ring - the first because building the next line and
        // holding a body still are opposite demands, the second because a station
        // does not end on a gate.
        kind: 'throat',
        centre: 0.34,
        gap: 0.4,
        mouth: 0.6,
        depth: 235,
        spacing: 440,
        rings: [{ x: 0.34, dy: 250, count: 11, scale: 1.45 }],
      },
      {
        kind: 'veil',
        centre: 0.67,
        gap: 0.46,
        spacing: 440,
        rings: [{ x: 0.67, dy: 205, count: 11, scale: 1.4 }],
      },
      // The landing. Short, because the next station's arrival is immediately
      // behind it and the two together are the longest empty run in the game.
      drift(320, 0.5, 10, 1.5),
    ],
  },
  {
    key: 'ozone',
    name: 'Ozone Blue',
    depthMeters: -20000,
    subtitle: 'The slowest wave',
    zone: ZONE_THIN + 1,
    medium: 'thinAir',
    decor: 'void',
    pace: 0.4,
    roughness: 0.5,
    swirl: 0,
    /*
     * Twenty kilometres, and the first gravity wave. It is deliberately weak -
     * about a third of what the nacreous station runs - because the player has to
     * be able to *notice* that the air is going up and down before they can be
     * asked to time anything against it. A wave introduced at full strength is
     * indistinguishable from turbulence.
     */
    layers: {
      height: 560,
      winds: [60, -34, 24, -16],
      waveAmplitude: 15,
      waveLength: 1150,
    },
    /*
     * 1060, 1080, 480, 460, 420, 620, 440, 440, 420, 420, 320 - 6160 px, 3.8
     * minutes, eight obstacles.
     *
     * The arrival is 2 140 px against the jet's 2 280, and from here it loses forty
     * more at every station: the air is thinner as the act climbs, so there is less
     * of it to wait in. It is still a full traverse of the course with nothing in
     * it - the drift ends on the right at 0.68 and the veil opens on the left at
     * 0.32 - which is the one thing this act does that nothing else in the campaign
     * does at all.
     *
     * The station's second movement is its first with time added to it, and that
     * is the whole design of it. The first is a door, a boundary and a funnel; the
     * second is the same three with the door *breathing*, a mass to split on
     * between them, and a couplet on the end. No shape here is new to the act.
     * What is new is that one of them is now on a clock.
     */
    sections: [
      drift(1060, 0.68, 9),
      {
        kind: 'veil',
        centre: 0.32,
        gap: 0.5,
        spacing: 1080,
        rings: [must(0.32, 200, 10, 1.55)],
      },
      {
        kind: 'shear',
        spacing: 480,
        gaps: [0.24, 0.5, 0.78],
        gap: 0.26,
        rings: [must(0.5, 185, 11, 1.5)],
      },
      {
        // A wide mouth over a slot, on the far side of the course from the shear's
        // compulsory door. The funnel is the one shape up here that cannot be
        // waited out - its walls converge whether or not the swarm has decided
        // anything - so it is what the first movement lands on.
        kind: 'throat',
        centre: 0.7,
        gap: 0.4,
        mouth: 0.62,
        depth: 240,
        spacing: 460,
        rings: [{ x: 0.7, dy: 250, count: 11, scale: 1.45 }],
      },
      drift(420, 0.4, 10, 1.45),
      {
        // The same door as the station's opener, on the far side of the course,
        // breathing. It is the second aperture in the act and the first one with a
        // wave under it: the lift is on the same eleven seconds the door is, so a
        // swarm that lets the air carry it arrives lined up without having counted
        // anything. That is the whole argument for putting apertures in this act
        // and nowhere is it cheaper to make than here, where the wave is weak
        // enough to be watched.
        kind: 'veil',
        centre: 0.64,
        gap: 0.44,
        spacing: 620,
        motion: PULSE,
        rings: [must(0.64, 205, 11, 1.5)],
      },
      {
        // Two channels round a mass, and one of them asked for. The rings are 0.7
        // of the width apart, which is the splittable mass's own grammar and the
        // opposite of a pair on one line: no body covers both, so taking both is a
        // decision to come apart and put itself back together.
        kind: 'column',
        centre: 0.52,
        radius: 0.09,
        height: 3,
        spacing: 440,
        rings: [
          must(0.16, -150, 11, 1.45),
          { x: 0.86, dy: -150, count: 11, scale: 1.4 },
        ],
      },
      {
        kind: 'shear',
        spacing: 440,
        gaps: [0.2, 0.5, 0.8],
        gap: 0.26,
        rings: [{ x: 0.5, dy: 185, count: 11, scale: 1.45 }],
      },
      {
        // The couplet, running the other way round from the jet's: the door first
        // and the funnel second, so the line has to be laid *into* a mouth rather
        // than out of one.
        kind: 'veil',
        centre: 0.28,
        gap: 0.46,
        spacing: 420,
        rings: [{ x: 0.28, dy: 205, count: 11, scale: 1.4 }],
      },
      {
        kind: 'throat',
        centre: 0.61,
        gap: 0.4,
        mouth: 0.6,
        depth: 235,
        spacing: 420,
        rings: [{ x: 0.61, dy: 250, count: 11, scale: 1.45 }],
      },
      drift(320, 0.5, 10, 1.5),
    ],
  },
  {
    key: 'nacre',
    name: 'The Nacreous',
    depthMeters: -25000,
    subtitle: 'The wave you can see',
    zone: ZONE_THIN + 2,
    medium: 'thinAir',
    decor: 'void',
    pace: 0.42,
    roughness: 0.55,
    swirl: 0.7,
    /*
     * The stratosphere, and the one station in the campaign where the mechanic and
     * the scenery are the same object.
     *
     * A nacreous cloud is not a cloud that happens to sit in a wave - it *is* the
     * wave, made visible: air forced over a mountain range oscillates for hundreds
     * of kilometres downwind, and where a crest lifts the air past its frost point
     * a lens of ice appears and hangs there, stationary, while the air pours
     * through it. So this is the station where the gravity wave doubles and where
     * the player can, for the first and only time, *see* the thing they have been
     * timing against. There is no tutorial text anywhere in this game and this
     * station is why act III does not need one.
     */
    layers: {
      height: 520,
      winds: [66, -44, 28],
      waveAmplitude: 34,
      waveLength: 1050,
    },
    /*
     * 1040, 1060, 480, 460, 420, 600, 460, 440, 440, 420, 420, 320 - 6560 px, 3.8
     * minutes, nine obstacles, and five compulsory rings, which is as many as any
     * station in the act has.
     *
     * **The first walking mass is here.** The jet's meander is the first thing in
     * the act that moves at all, and it is a boundary rather than a body - there is
     * no way round it, only through it. This is the first moving thing the swarm
     * can pass on either side, and the ordering is not arbitrary: a thing that moves
     * is only a demand if the player can tell it apart from the medium moving *them*.
     * The jet has no gravity wave in it at all, so nothing there is ambiguous; and
     * this is the one station where the wave is drawn, so a mass walking against it
     * can be read rather than guessed at. The station in between has a wave and no
     * way to see it, so it gets a breathing door and no moving mass at all.
     *
     * Two columns, then, one still and one walking, with 1 480 px and a rest
     * between them: the same object twice, and the difference between them is the
     * whole of what the second axis is.
     */
    sections: [
      drift(1040, 0.3, 10),
      {
        // A lens over its own eddy, which is exactly what a lenticular is. The
        // marker is the cloud and the hazard is what is turning under it, and
        // nothing in this act ever moves one without the other - an aperture or a
        // drift here would slide the ice off the rotor it is the sign of, which is
        // the one lie this act cannot afford to tell.
        kind: 'eddy',
        centre: 0.5,
        gap: 0.46,
        radius: 0.32,
        spin: 1,
        strength: 86,
        spacing: 1060,
        rings: [{ x: 0.5, dy: 245, count: 11, scale: 1.4 }],
      },
      {
        kind: 'shear',
        spacing: 480,
        gaps: [0.22, 0.62],
        gap: 0.26,
        rings: [must(0.62, 185, 11, 1.5)],
      },
      {
        // The still column, and the narrowest pair in the act at 1.45: a ring the
        // swarm has to be split across cannot be as forgiving as one it drifts
        // into, or the split stops being a decision.
        //
        // Slowblue: both of these used to be compulsory. That is 56 % of the swarm
        // held in two places at once, which is not a demand, it is a wall - the
        // same correction act V's plasma made to its plume. The right one is
        // optional now and the demand is unchanged for anyone who was managing it.
        kind: 'column',
        centre: 0.46,
        radius: 0.095,
        // Authored rather than defaulted, which it was until the act's rhythm
        // moved it. `crystalColumn` sizes its plates from a hash of where the
        // section lands, so at the default 2.6 the shaft's own extent and its
        // widest plate were within a few pixels of each other and which way
        // round they came out was a function of the section's Y. 3.0 puts the
        // column's height clear of its widest plate wherever the act puts it,
        // which is the property `tests/thinning.test.ts` is actually asking for.
        height: 3,
        spacing: 460,
        rings: [
          must(0.15, -150, 12, 1.45),
          { x: 0.85, dy: -150, count: 12, scale: 1.45 },
        ],
      },
      drift(420, 0.5, 10, 1.45),
      {
        kind: 'veil',
        centre: 0.62,
        gap: 0.46,
        spacing: 600,
        motion: PULSE,
        rings: [must(0.62, 205, 12, 1.5)],
      },
      {
        /*
         * ...and the same shaft, walking.
         *
         * A column drifting 0.05 of the width either way, with a channel on each
         * side and the compulsory ring in the wide one. The ring never moves and
         * the shaft does, so what the walk changes is the room rather than the
         * target - which is the legible version of this demand and the one it has
         * to be taught in.
         *
         * Its envelope runs 0.23 to 0.57 of the width, which leaves the optional
         * ring at 0.14 clear at the worst phase by about a body's width. That is
         * the corridor sweep's job rather than a comfort - `Section.envelope` is
         * what it reads - but a number this tight is worth writing next to the
         * thing it is about.
         */
        kind: 'column',
        centre: 0.4,
        radius: 0.085,
        height: 3,
        spacing: 460,
        motion: WALK,
        rings: [
          must(0.78, -150, 12, 1.45),
          { x: 0.14, dy: -150, count: 12, scale: 1.4 },
        ],
      },
      {
        kind: 'shear',
        spacing: 440,
        gaps: [0.2, 0.5, 0.8],
        gap: 0.24,
        rings: [{ x: 0.5, dy: 185, count: 12, scale: 1.45 }],
      },
      {
        // The last funnel before the station's couplet, and the compulsory ring is
        // 265 px back - which is 15 px in front of the mouth. The reward is for
        // entering lined up rather than for having survived, which is act IV's
        // construction and the right one wherever a shape converges.
        kind: 'throat',
        centre: 0.36,
        gap: 0.36,
        mouth: 0.62,
        depth: 250,
        spacing: 440,
        rings: [must(0.36, 265, 12, 1.45)],
      },
      {
        // The station's couplet, and the only one in the act whose *first* half is
        // a turning current: the rotor is still spinning under the swarm while the
        // line for the veil 420 px later is being laid. Neither half is compulsory.
        kind: 'eddy',
        centre: 0.3,
        gap: 0.44,
        radius: 0.3,
        spin: -1,
        strength: 92,
        spacing: 420,
        rings: [{ x: 0.3, dy: 240, count: 12, scale: 1.4 }],
      },
      {
        kind: 'veil',
        centre: 0.63,
        gap: 0.46,
        spacing: 420,
        rings: [{ x: 0.63, dy: 205, count: 12, scale: 1.4 }],
      },
      drift(320, 0.5, 11, 1.5),
    ],
  },
  {
    key: 'blacksky',
    name: 'The Black Sky',
    depthMeters: -50000,
    subtitle: 'Stars in daylight',
    zone: ZONE_THIN + 3,
    medium: 'thinAir',
    decor: 'void',
    pace: 0.44,
    roughness: 0.6,
    swirl: 0.8,
    /*
     * Fifty kilometres. There is about a thousandth of the atmosphere left, the
     * sky is black in broad daylight, and the bands have gone from being currents
     * to being the only thing that exists.
     *
     * **Two winds instead of four**, and that is the station's whole design. Every
     * layer stack below this one has a slow band in it somewhere - a place to sit
     * and think. This one does not: there is a fast wind and there is a fast wind
     * going the other way, so every moment is spent in one of them and the
     * question is never "shall I move" but only "which".
     *
     * So this is the station that carries the act's `flurry`, and the two facts are
     * the same fact. A `shear` asks that question once, at a line, and then the
     * answer is made; two staggered lines with no room between them ask it twice in
     * a medium with a third of the water's grip, which is the sentence above turned
     * into geometry rather than restated.
     *
     * Slowblue: `flurry` was implemented, documented in the alphabet table, allowed by
     * `tests/geometry.test.ts` and authored by nobody. `shear` was six of act III's
     * thirteen obstacle sections and `shear` plus `eddy` was nine of them, so the
     * upper air asked for two things across ten minutes - and the one demand it was
     * missing is the one that costs *time* rather than width, which is the only
     * currency this act charges in.
     */
    layers: {
      height: 500,
      winds: [80, -56],
      waveAmplitude: 40,
      waveLength: 980,
    },
    /*
     * 1020, 1040, 460, 460, 420, 580, 460, 440, 440, 420, 420, 320 - 6480 px, 3.6
     * minutes, nine obstacles and five compulsory rings: with the mesopause, the
     * densest thing in the act.
     *
     * **The scissor is here**, and it is the same argument the two winds are. A
     * station with no slow band in it has no phase at which standing still is an
     * answer, so its hardest object is a pair of masses that between them are never
     * where they were: 580 px into the first and 460 px on to the second, one
     * walking out while the other walks back. See `WALK_OUT`/`WALK_BACK`.
     *
     * Four hundred and sixty pixels at this pace is fifteen and a half seconds,
     * which is one breath and a third - so the pair is met a little over a cycle
     * apart and its two halves are half a cycle out of step. The second mass has
     * always crossed by the time the swarm gets to it.
     */
    sections: [
      drift(1020, 0.7, 10),
      {
        /*
         * Loose crystal in staggered lines: the act's chicane, and the first of
         * the two it has.
         *
         * **Two rows, not three**, and that is the measurement rather than the
         * archetype's default. A chicane costs one committed lateral move per row,
         * and up here a lateral move is the one thing the hand is worst at -
         * `thinCoupling` is a third of the water's grip, so what is cheap in act I
         * is expensive here in exactly the currency this act charges in. Measured
         * over eleven seeds on `tools/finish.sweep.ts`: three rows took the act
         * from 11/11 finished to 8/11 and its restarts from 1.3 a run to 11.1, and
         * two rows land at 11/11 and 2.7 - which is the act costing more than it
         * did, which is the point, without costing the act.
         *
         * Wide with it: 78 px of lane common to both rows, against act I's 62 to
         * 78, because act III's charter is that it never escalates by narrowing.
         * What it charges is the 196 px between the rows, which at this pace is
         * about six seconds of not being able to wait.
         */
        kind: 'flurry',
        spacing: 1040,
        gap: 0.46,
        rows: 2,
        swing: 0.13,
        first: 1,
        // 88 px in front of the first row, which is act IV's construction for a
        // chicane ring: a chicane's demand starts before its geometry does, so the
        // reward is for entering lined up rather than for having survived.
        rings: [must(0.74, 284, 12, 1.5)],
      },
      {
        // ...and then a ring on the far left, 460 px later. Nothing in the station
        // stops the swarm crossing; the wind in the band the chicane left it in is
        // what decides whether it can, which is the one idea this station has and
        // the reason it has only two winds.
        kind: 'eddy',
        centre: 0.36,
        gap: 0.42,
        radius: 0.3,
        spin: -1,
        strength: 98,
        spacing: 460,
        rings: [must(0.36, 240, 12, 1.5)],
      },
      {
        kind: 'veil',
        centre: 0.66,
        gap: 0.44,
        spacing: 460,
        motion: PULSE,
        rings: [{ x: 0.66, dy: 205, count: 12, scale: 1.4 }],
      },
      drift(420, 0.5, 10, 1.45),
      {
        // The scissor, out. Compulsory ring on the right, in the channel this one
        // opens as it goes.
        kind: 'column',
        centre: 0.4,
        radius: 0.085,
        height: 3,
        spacing: 580,
        motion: WALK_OUT,
        rings: [
          must(0.78, -150, 12, 1.45),
          { x: 0.14, dy: -150, count: 12, scale: 1.4 },
        ],
      },
      {
        // ...and back. No compulsory ring on it, and the reason is the couplet's:
        // this is the second half of a pair whose demand is the pair, and holding a
        // body still inside a ring while the room in front of it is walking the
        // other way is two demands on one section.
        kind: 'column',
        centre: 0.58,
        radius: 0.085,
        height: 3,
        spacing: 460,
        motion: WALK_BACK,
        rings: [{ x: 0.16, dy: -150, count: 12, scale: 1.4 }],
      },
      {
        // Three doors, and the compulsory one is the far right - which is where the
        // scissor's second mass has just been standing.
        kind: 'shear',
        spacing: 440,
        gaps: [0.2, 0.5, 0.8],
        gap: 0.24,
        rings: [must(0.8, 185, 12, 1.45)],
      },
      {
        // The station's last compulsory ring, and 0.46 rather than the far left it
        // wants to be. The shear's ring is at 0.8 and this is 440 px later: at the
        // corridor sweep's own pessimistic lateral budget - 0.45 px across for
        // every px along - a body leaving the shear's right-hand door has 191 px of
        // travel to spend and this costs 156 of it. Any further left and the
        // traverse stops being a demand and becomes a coin toss on which door the
        // shear was taken through.
        kind: 'veil',
        centre: 0.46,
        gap: 0.46,
        spacing: 440,
        rings: [must(0.46, 200, 12, 1.5)],
      },
      {
        // The couplet: a funnel and then a rotor, 420 px and a third of the width
        // apart. It is the only one in the act whose second half has a current
        // turning in it, so the line laid before the mouth has to survive being
        // spun once on the way out of it.
        kind: 'throat',
        centre: 0.32,
        gap: 0.38,
        mouth: 0.6,
        depth: 245,
        spacing: 420,
        rings: [{ x: 0.32, dy: 260, count: 12, scale: 1.45 }],
      },
      {
        kind: 'eddy',
        centre: 0.65,
        gap: 0.42,
        radius: 0.28,
        spin: 1,
        strength: 94,
        spacing: 420,
        rings: [{ x: 0.65, dy: 240, count: 12, scale: 1.4 }],
      },
      drift(320, 0.5, 11, 1.5),
    ],
  },
  {
    key: 'noctilucent',
    name: 'The Noctilucent',
    depthMeters: -82000,
    subtitle: 'The last cloud there is',
    zone: ZONE_THIN + 4,
    medium: 'thinAir',
    decor: 'void',
    pace: 0.46,
    roughness: 0.65,
    swirl: 0.9,
    /*
     * The mesopause: ice crystals grown on meteor dust, glowing electric blue
     * against a black sky because the sun is still on them hours after it has gone
     * from everything on the ground. There is no cloud above this one anywhere on
     * the planet, and the dust every one of those crystals is grown on came in
     * from space and burned on the way - which is exactly what the swarm is about
     * to become two acts from now, and is the quietest piece of foreshadowing in
     * the campaign.
     *
     * The hardest station in the act, and its demand is timing at its purest: the
     * wave is at full strength, the bands are the thinnest they have been, and the
     * gaps are *wider* than the station before it. Nothing here is asking for a
     * steadier hand. It is asking the player to wait.
     */
    layers: {
      height: 470,
      winds: [86, -66, 44, -28],
      waveAmplitude: 46,
      waveLength: 900,
    },
    /*
     * 1000, 1020, 480, 460, 420, 620, 690, 460, 440, 420, 420, 320 - 6750 px, 3.6
     * minutes, nine obstacles.
     *
     * The arrival is the shortest in the act - 2 020 px against the jet's 2 280 -
     * which is the contraction the rebuild runs on, drawn in the one unit this
     * station cares about. There is less air up here and less time in it.
     *
     * **The counter-phase pair is here**, at 620 and 690 px, and 690 px at this
     * pace is twenty-two seconds, which is two breaths. The station whose whole
     * subject is waiting gets the one object in the campaign where being early is
     * a mistake. See `PULSE_OPEN`/`PULSE_SHUT`.
     *
     * The 460 after it is the act's second chicane, and the Black Sky's note on the
     * first one is the reason it is allowed to exist. What was measured there was
     * *rows*: three rows in one chicane cost the act three completions in eleven
     * and two rows cost none. This is two rows, with a wider lane than that one,
     * four stations later, in a station that has just spent 1 310 px on two doors
     * that open and shut. A second chicane in the act is a different quantity from
     * a third row in a chicane, and only one of the two has been measured.
     */
    sections: [
      drift(1000, 0.5, 10),
      {
        kind: 'eddy',
        centre: 0.66,
        gap: 0.44,
        radius: 0.32,
        spin: -1,
        strength: 106,
        spacing: 1020,
        rings: [{ x: 0.66, dy: 248, count: 12, scale: 1.4 }],
      },
      {
        kind: 'shear',
        spacing: 480,
        gaps: [0.2, 0.5, 0.8],
        gap: 0.22,
        rings: [must(0.2, 190, 12, 1.45)],
      },
      {
        // The narrowest corridor in the act at 0.34, and it is at the station with
        // the widest wave. What is being asked for is still time rather than
        // precision: the gap is wider than act II's last three stations and the
        // wave will take the swarm past it twice while they wait for the right half
        // of a breath. A wide mouth over a narrow slot asks for time *in* the mouth
        // rather than accuracy at the line, which is the act's currency - which is
        // why the funnel is the shape this act repeats most after its own shear.
        kind: 'throat',
        centre: 0.38,
        gap: 0.34,
        mouth: 0.66,
        depth: 260,
        spacing: 460,
        rings: [must(0.38, 270, 13, 1.45)],
      },
      drift(420, 0.46, 11, 1.45),
      {
        /*
         * The counter-phase pair, front half, open at the top of the cycle.
         *
         * Taking this one the moment it opens puts the swarm at the second one at
         * its narrowest; waiting a beat costs ground against the drift and arrives
         * on the open half of both. It is the couplet's demand - lay the line for
         * the second gate before entering the first - moved out of space and into
         * time, which is the only place act III has ever charged anything.
         */
        kind: 'veil',
        centre: 0.34,
        gap: 0.46,
        spacing: 620,
        motion: PULSE_OPEN,
        rings: [must(0.34, 205, 13, 1.5)],
      },
      {
        kind: 'veil',
        centre: 0.64,
        gap: 0.44,
        spacing: 690,
        motion: PULSE_SHUT,
        rings: [{ x: 0.64, dy: 200, count: 13, scale: 1.4 }],
      },
      {
        // The second chicane in the act, staggered the other way from the Black
        // Sky's - the first row met is on the left here - and wider, because the
        // wave is at full strength under it and the swarm is being moved whether or
        // not it decides anything. The ring is 88 px in front of the first row, on
        // that row's own door.
        kind: 'flurry',
        spacing: 460,
        gap: 0.5,
        rows: 2,
        swing: 0.12,
        first: -1,
        rings: [{ x: 0.3, dy: 284, count: 13, scale: 1.45 }],
      },
      {
        kind: 'shear',
        spacing: 440,
        gaps: [0.24, 0.56, 0.86],
        gap: 0.22,
        rings: [must(0.56, 185, 13, 1.45)],
      },
      {
        // The couplet the act ends its hardest station on, and it is the plainest
        // one in the file: a door and a funnel, 420 px and a third of the width
        // apart, with nothing moving and nothing compulsory. After 1 300 px of
        // doors on a clock, a pair that only asks to be read is the harder-earned
        // rest of the two.
        kind: 'veil',
        centre: 0.3,
        gap: 0.46,
        spacing: 420,
        rings: [{ x: 0.3, dy: 205, count: 13, scale: 1.4 }],
      },
      {
        kind: 'throat',
        centre: 0.63,
        gap: 0.36,
        mouth: 0.62,
        depth: 250,
        spacing: 420,
        rings: [{ x: 0.63, dy: 260, count: 13, scale: 1.45 }],
      },
      drift(320, 0.5, 11, 1.5),
    ],
  },
  {
    key: 'line',
    name: 'The Line',
    depthMeters: -100000,
    subtitle: 'Where the air runs out',
    zone: ZONE_THIN + 5,
    medium: 'thinAir',
    decor: 'void',
    // The one station in the campaign whose numbers *fall*. Everything that has
    // been escalating for three acts runs down here instead, because what this
    // station is about is an absence - so it is also the only pace in the act
    // that is lower than the station before it.
    pace: 0.36,
    roughness: 0.3,
    swirl: 0,
    /*
     * A hundred kilometres. The Karman line is not a wall and not a place - it is
     * defined as the altitude at which you would have to fly faster than orbital
     * velocity for a wing to hold you up, which is a physicist's way of saying
     * "the air has stopped being able to carry anything".
     *
     * So the layers run *down* to almost nothing. The bands are still there and
     * still going opposite ways, and they are now so weak that riding one buys
     * almost no ground - which is the last thing act III teaches and the first
     * thing act IV needs the player to already know. The station is short, wide
     * and nearly empty, and it ends on a section with nothing in it at all.
     */
    layers: {
      height: 900,
      winds: [18, -12, 8],
      waveAmplitude: 14,
      waveLength: 1400,
    },
    /*
     * 1160, 460, 420, 700, 440, 420, 1100 - 4700 px, 3.2 minutes, five obstacles,
     * and one compulsory ring in the whole station.
     *
     * It is the one station in the act that closes on nothing instead of opening
     * on it, and the reason is the same one the empty section at the bottom of
     * the list already gave: the act ends on the discovery that a stroke has
     * stopped doing anything, and a discovery needs somewhere quiet to happen
     * *after* it. An arrival at the front here would put the quiet before the
     * discovery, which is a station with a rest in it rather than an ending. The
     * mid-station rest is still there, at 420, because the ramp needs one.
     *
     * **Its alphabet runs down as well**, and that is the quietest thing in the
     * file: five obstacles and only two shapes between them, where every other
     * station here has four or five. There is not enough air left up here to make
     * a funnel out of, or a column, or a rotor. What is left is a boundary and a
     * curtain, twice each, and then nothing.
     */
    sections: [
      {
        // 1160 px after the mesopause's landing, so the seam still breathes even
        // though this station has no arrival of its own. The ring is 1.6, which is
        // the width of the one in the jet's second section and the only other one
        // that wide in the file: the numbers run down here, and the rings run back
        // up to where the act started.
        kind: 'shear',
        spacing: 1160,
        gaps: [0.3, 0.7],
        gap: 0.3,
        rings: [must(0.3, 190, 12, 1.6)],
      },
      {
        kind: 'veil',
        centre: 0.6,
        gap: 0.5,
        spacing: 460,
        rings: [{ x: 0.6, dy: -230, count: 12, scale: 1.4 }],
      },
      drift(420, 0.44, 11, 1.5),
      {
        // The last breathing door in the campaign's climb, and it is barely
        // breathing: 0.03 of the width either side against the act's usual 0.06.
        // Everything else here is running down and there is no reason for this to
        // be the exception - what it is for is that the player should meet one of
        // these once more, in air too thin to make much of it, and notice that it
        // has almost stopped.
        kind: 'veil',
        centre: 0.36,
        gap: 0.5,
        spacing: 700,
        motion: { kind: 'aperture', reach: 0.03 },
        rings: [{ x: 0.36, dy: 220, count: 12, scale: 1.45 }],
      },
      {
        kind: 'shear',
        spacing: 440,
        gaps: [0.26, 0.74],
        gap: 0.3,
        rings: [{ x: 0.26, dy: 190, count: 12, scale: 1.55 }],
      },
      {
        // The last ice in the campaign's climb, and the last couplet: 420 px behind
        // the shear's left door and a third of the width across from it. Nothing
        // after it is asked for.
        kind: 'veil',
        centre: 0.59,
        gap: 0.5,
        spacing: 420,
        rings: [{ x: 0.59, dy: 225, count: 12, scale: 1.5 }],
      },
      // ...and then nothing, for 1100 px. This is the arrival every other station
      // in the act opens with, spent at the end instead, and it is the last thing
      // act III does.
      { kind: 'open', spacing: 1100, rings: [{ x: 0.5, dy: -120, count: 11 }] },
    ],
  },
];

/**
 * Act III: six stations, the tropopause to the Karman line.
 *
 * **The first act that does not end runs.** Above the anvil a mistimed breath
 * begins the station again rather than the campaign, which is the failure arc the
 * design lays out - hard failure thins out with altitude the same way the air
 * does. It is also the only honest way to hold the act's own rule that bad timing
 * costs position and time and never life: a sinking cell at the mesopause really
 * can take a swarm backwards faster than a hand can push it forward, and the
 * answer to that is a setback rather than a deletion.
 *
 * That rule is the one thing the rebuild made more expensive rather than less. A
 * station was 1.7 minutes when this was written and it is 3.2 to 4.2 now, so the
 * price of a lost station has roughly doubled - and the budget moved with it. It
 * is not a constant any more: `restartsForMinutes` reads the act's own authored
 * length, so this act carries three attempts where it used to carry two, and act I
 * still carries two because it is still ten minutes. See DESIGN-LENGTH §10.
 */
export const ACT_THIN: Act = makeAct('thin', THIN_LEVELS, {
  carrier: 'motes',
});
