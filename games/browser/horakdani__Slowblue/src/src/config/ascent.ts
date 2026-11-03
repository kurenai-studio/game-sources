import { ZONE_AIR } from './zones';
import { makeAct, type Act, type Level, type RingSpec, type SectionSpec } from './levels';

/**
 * Slowblue: act II - the air.
 *
 * ## What this act is now, and what it was
 *
 * The first act II had its own verb. It had a lift field, a downward pull, and a
 * flock that fell out of the sky unless the player found a thermal, so the hand
 * stopped steering the medium and started hunting for a resource. It measured
 * well. It was a different game wearing this one's clothes, and it has been taken
 * out.
 *
 * What is here instead is the sentence the whole project is built on, one medium
 * up: **you do not control the birds, you control the air.** Same stroke, same
 * drag, same clock. A flock is herded exactly as a shoal is herded, which is why
 * act I's scripted players fly this act without being taught anything new - and
 * that fact is the acceptance test, not a nice property (`tools/air.sweep.ts`).
 *
 * ## Six stations, and where the birds stop
 *
 * The act runs from the wave tops to the top of the weather, and **it ends at
 * eleven kilometres**, which is the second thing about it worth defending.
 *
 * It used to run to eighty-two, through the stratosphere to the noctilucent cloud
 * at the mesopause. Those are the two most beautiful stations in the game and
 * they are still in it - they are act III's, one carrier later. What was wrong
 * was not the places, it was who was in them: nothing with wings has ever flown
 * at 82 km and nothing ever will, because there is no air there to fly in. A bird
 * at the mesopause is the one image in this campaign that would have told the
 * player the world was made up. The anvil is where weather stops, it is roughly
 * where the highest-flying bird ever recorded was found, and it is therefore
 * exactly where the flock has to hand over.
 *
 *   1. **The Spray** (60 m) - haze off the sea, torn shreds of cloud.
 *   2. **The Cliff** (300 m) - the coast, and the first solid thing in the air.
 *   3. **The Cumulus Field** (1 200 m) - the fair-weather cumulus field.
 *   4. **The Passage** (2 500 m) - the altitude birds actually migrate at.
 *   5. **The Squall** (4 000 m) - rain, and the first air that turns.
 *   6. **The Anvil** (11 000 m) - the top of the storm, where the air runs out.
 *
 * ## The length, and the one argument this file used to win
 *
 * Act II was the shortest act in the campaign - 30 600 px, 7.7 minutes - and this
 * file's own defence of that number was good enough to be quoted in
 * `tests/descent.test.ts`: it is 36 sections, the second-most anywhere, so it is
 * also the *densest*, and the eight thousand pixels it would have taken to make it
 * ten minutes would have been eight thousand pixels of empty crossing added to the
 * act that has the least need of them.
 *
 * That argument still holds and it is the reason this rebuild looks the way it
 * does. `docs/DESIGN-LENGTH.md` measured the circuit and found the fault was the
 * *distribution* rather than the hour, and act V went first: 24 sections to 73,
 * 10.9 authored minutes to 26.5, at byte-for-byte the same pace. Act II is the
 * second, and the recipe transfers with one change:
 *
 * > **Act II's new minutes are content, not crossing.** The three intervals below
 * > are unchanged, the pace of all six stations is unchanged, and the act simply
 * > has more systems in it. What that costs is the one number that did not fall:
 * > it is **91 sections, 78 obstacles, 21.7 authored minutes and 3.6 obstacles a
 * > minute**, where the campaign-wide target for a rebuilt act was 2.0 to 2.5.
 *
 * Act II is allowed to miss that target and act V was not, and the reason is
 * arithmetic rather than affection. 2.4 obstacles a minute over a 3.6-minute
 * station is one demand every twenty-five seconds. Act I - which is frozen, and is
 * the metronome every other act is heard against - asks every seventeen. An act II
 * thinner than the act in front of it is not a rebuilt act II, it is a different
 * act with this one's stations in it, and **this is the act a purchase is decided
 * on**: it has to show the game that is being bought, which means showing it
 * arriving at the rate it actually arrives at.
 *
 * So what got harder is what a section *asks*, and all of it is new here:
 *
 *   - **seven breathing gaps** (`PULSE`), two of them **streets**, which is the
 *     only obstacle in the game whose geometry moves while the flock is still
 *     inside it;
 *   - **four walking masses** (`WALK`), and **two scissors** - a pair of them on
 *     opposite halves of one clock, at the cliff and again at the anvil;
 *   - **one counter-phase pair** in the squall, two breaths apart, which is the
 *     only place in this act where being early is a mistake;
 *   - **six couplets**, one closing every station;
 *   - and **seven hunters** against three, across six `raptor` sections. Half the
 *     campaign's hunters used to be here and the other half in act I; the back
 *     half of the circuit has act V's embers now, so
 *     act II is no longer the last thing in the game with intent in it - it is the
 *     place the player learns what intent looks like.
 *
 * ## The rhythm: legs and rests
 *
 * Weather does not arrive on a metronome. It comes in systems with open sky
 * between them, and a flight across country is legs and rests rather than a queue
 * of obstacles. Act II used to be laid on the campaign's flat 820 px spacing,
 * which is the deepest single reason six different alphabets played as one act:
 * the shape of the demand changed from station to station and the interval never
 * did, so the ear heard one metronome under all of it.
 *
 * So every station is authored as **tight pairs with long crossings between
 * them**. Four intervals now, and each of them means something:
 *
 *   - **520 to 620** is inside one weather system. Two sections that close means
 *     the first gust is still in the air when the second thing arrives, which is
 *     what makes a pair one decision rather than two.
 *   - **480 to 500** is the **couplet**, and it is new. Closer than one system:
 *     two gaps a third of the width apart with no time between them, so the line
 *     for the second has to be laid before entering the first. It is the tightest
 *     interval in the act by design and it is the one place the act got tighter,
 *     because spacing is not gap width and this act's gaps do not move.
 *   - **1 200 to 1 500** is a crossing. Nothing is in it, and that is the point:
 *     it is the leg between systems, and it is where the shape of what just
 *     happened becomes legible. It grows through the act because the act's pace
 *     does - a 1 220 px leg is 21 seconds at the spray and 16 at the anvil, and
 *     what is being held constant is roughly the time rather than the distance.
 *   - **980** is the street's slot. A street's corridor runs *back* from its own
 *     line, so the leg behind it has to be longer than the cloud in it is; 640 px
 *     of corridor in a 980 px leg leaves the previous section 300 px of clear
 *     air. Stations with no street spend the slot on their widest lateral move,
 *     which is the other thing that genuinely needs length.
 *
 * The stations sum to 12 570, 14 100, 14 300, 14 290, 14 890 and 16 700 px -
 * **86 850 px**, which at this act's paces is 3.6, 3.8, 3.7, 3.5, 3.4 and 3.6
 * minutes. They are deliberately level in *time* and not in pixels: this is the
 * fastest act in the game (pace 0.85 to 1.14 against act III's 0.36 to 0.46), so a
 * station that matched the spray's pixel count at the anvil's pace would be a
 * minute shorter than it.
 *
 * ## Two movements, two rests, and a station that does not end on a gate
 *
 * Every station is **A, a breath, and B**. A is the act as it was; B is where that
 * station's hardest question arrives; the empty section between them is the one
 * place inside three and a half minutes the player can put the phone down.
 *
 * The plan for this shape had the mid-station rest be the rest each station
 * already had, *moved* to the middle - it costs no length that way. Act V measured
 * that and it was wrong by a factor of five: built that way it ran 35.6 restarts a
 * run against the old act's 1.2, and every one of them was the swarm being left
 * behind rather than a missed ring. So, measured, and true here without needing to
 * be measured again:
 *
 *   - **A station gets two rests**, one in each half, and the mid-station breath
 *     is an addition rather than a move. The rest at the end is where the flock
 *     pays back the ground a station's pressure ramp takes, and that ramp peaks at
 *     the station's own end.
 *   - **A station does not end on a compulsory ring.** The pressure peak and a
 *     dashed ring are opposite demands - one says keep up, the other says stop and
 *     hold a body still. Every station's last demand here is a couplet and neither
 *     half of a couplet is ever dashed.
 *
 * ## The street, and the one ring in the game that is not a receipt
 *
 * `street` is the act's seventh archetype and the only thing on this course that
 * is not an aperture. Everything else asks the flock to be at one x when the
 * centroid crosses one line, and how long the geometry lasts is scenery. A street
 * asks it to *still be* in a corridor six or seven hundred pixels later, while
 * `AmbientFlow` changes sign about twice across that distance.
 *
 * There are six of them now rather than three, two each in stations 3, 4 and 6.
 * `wisps` survives in stations 1 and 2 and only there, because torn fog off the
 * sea and off a headland genuinely is scatter rather than a corridor, and drawing
 * it as one would be a lie about what the weather is doing. `pass` survives
 * everywhere: it is act II's narrow moment, and a street is that same "hold a
 * line" demand stretched, so only one of the two is allowed to be narrow. No
 * street in the act goes below 0.42 of the width while the anvil's pass is at 0.28.
 *
 * And the reward moves. Everywhere else in the campaign a compulsory ring sits a
 * couple of hundred pixels behind a hole the flock has already gone through, so
 * what it rewards is a thing already done - it is a receipt. A street's ring sits
 * at the corridor's own centre, half the street's length back from the line, in
 * the middle of the thing being held. It is the act's grammar in one number.
 *
 * ## The second axis: seventeen of these do not stand still
 *
 * Every obstacle in this act used to stand still, which made the whole of its
 * difficulty spatial - read the shape, lay the line, arrive. `MotionSpec` is the
 * other axis and it is **a modifier on a section** rather than an alphabet of its
 * own, so every shape act II already draws can have it for one line.
 *
 *   - **An aperture breathes.** Authored *shut* - `gap` is the narrowest it ever
 *     gets - so the corridor sweep, which never advances a clock, is already
 *     checking the hardest phase. It goes only on the shapes that are one wall
 *     with one hole in them: a `bank`, a `pass`, a `street`. Never a `wisps`,
 *     which has three doors and would pinch the middle one shut.
 *   - **A mass walks.** A `tower` that slides sideways while the flock closes on
 *     it. Its authored position is the middle of its travel and `Section.envelope`
 *     carries the union of everywhere it ever is, so the sweep's guarantee is the
 *     strong one: there is a line past it whenever you arrive, not only on the beat.
 *   - **A scissor is two masses on opposite halves of one clock.** One walking
 *     tower asks you to aim where the channel will be; a pair of them walking
 *     against each other means there is no phase at which either is where you last
 *     saw it. See `WALK_OUT`/`WALK_BACK`.
 *   - **A counter-phase pair is the couplet, in time.** Two breathing gaps two
 *     breaths apart, the second shut while the first is open. See
 *     `PULSE_OPEN`/`PULSE_SHUT`, and the squall, which is where the act has the
 *     room for it.
 *
 * They arrive in teaching order, and the order is the same one act V used: the
 * first breathing gap is in the spray, the slowest station in the act, at almost
 * its widest gap with nothing else in the frame; the first walking tower is four
 * sections later in the same station; the first scissor is at the cliff, which is
 * the same object doubled rather than a new one to learn; and the breathing street
 * waits for the cumulus, because a corridor that moves is only legible to somebody
 * who already knows what a corridor is.
 *
 * **A breathing street is the act's own contribution to this axis.** Every other
 * moving thing in the game finishes moving before the demand is over, because the
 * demand is over in a frame. A street is 560 to 680 px of corridor, which at these
 * paces is nine to eleven seconds - one breath - so the walls open and come back
 * in *while the flock is between them*. Nothing else in the campaign can say that,
 * and it costs one line.
 *
 * ## The authoring grammar
 *
 * Four rules, and `tests/ascent.test.ts` holds all four.
 *
 * **1. Every obstacle is cloud.** Seven archetypes of it (`SectionSpec`), and not
 * one of them is one of the water's with a different colour on it. There is no
 * rock anywhere in act II - the last stone in the game is the one the shoal
 * breaks the surface past at the end of act I.
 *
 * **2. Rings work exactly as they do below.** Dashed rings are compulsory and sit
 * on the line the section already asks for; plain rings sit off it and are worth
 * a detour. This is the act's biggest single change: act II used to have no
 * compulsory ring at all, on a theory about failure modes thinning out with
 * altitude, and what that actually bought was an act with nothing to *do* in it
 * but avoid things. The one exception is the street, above, and it is an
 * exception about *where* the ring is rather than about what it costs.
 *
 * **And never two dashed rings on one section.** Two of the act's towers used to
 * demand both channels at once, with a written argument for it - a demanded split
 * needs a whole crossing to be one body again. Act V measured what that costs:
 * a compulsory ring asks for 28 % of the flock held still for 0.7 s, so two of
 * them is 56 % in two places at the same instant, which is not a demand, it is a
 * wall. Every tower here dashes one channel and offers the other.
 *
 * **3. The ramp is gaps, then rings, then weather.** Narrowest gap per station
 * goes 0.56 -> 0.28 of the width; compulsory rings go 6 -> 10; and what else is in
 * the air arrives in order - nothing, a tower to split on, a rotor, a raptor,
 * then both at once. Pace moves 0.85 -> 1.14, which is act I's discipline with
 * the wind's own numbers: the game does not get faster, it asks for more
 * precision, and the medium it asks in is windier than the sea from the start.
 *
 * **4. Every station closes on a couplet and then on its longest crossing.** The
 * last section is one empty leg with a ring in it, at 1 300 to 1 500 px the
 * longest thing in the station, and the demand in front of it is two gaps five
 * hundred pixels apart with nothing dashed on either. It is where the player finds
 * out what the new sky looks like with nothing in front of it, and it is also the
 * run-in to the next station - which is why the station after it is allowed to
 * open on a tight pair without that pair arriving on top of anything.
 */

/**
 * The standard closing breath: open air, nothing asked, one ring in it.
 *
 * `spacing` is the station's own last leg rather than a constant, because the
 * breath is the crossing now. It was 900 px in every station of every act, and a
 * rest that is the same length every time is a bar line rather than a rest.
 *
 * Called twice per station since the rebuild - once in the middle and once at the
 * end - and the two are never the same length, for the same reason.
 */
function breath(x: number, count: number, spacing: number): SectionSpec {
  return { kind: 'open', spacing, rings: [{ x, dy: -60, count }] };
}

/** A compulsory ring, on the line the section already asks for. */
function must(x: number, dy: number, count: number, scale = 1.25): RingSpec {
  return { x, dy, count, required: true, scale };
}

/**
 * The breath, as a period, and the only clock anything in this act moves on.
 *
 * `reach` is the peak excursion as a fraction of the field width, and an aperture
 * takes it on both sides - so a gap authored at 0.40 opens to 0.50 and comes back.
 * A tenth of the field is enough to be unmistakable in a frame the flock is
 * already 0.38 of the width across, and small enough that the *authored* number is
 * still the one that describes the section.
 */
const PULSE = { kind: 'aperture', reach: 0.05 } as const;

/**
 * A mass that walks: one tower, one translation, back and forth on the breath.
 *
 * The game's oldest sentence made literal - the line you laid three seconds ago is
 * not the line you are on - except that now the channel is not where it was
 * either. Safe by construction rather than by care: `Section.envelope` carries the
 * union of everywhere the mass ever is, and the corridor sweep reads that.
 */
const WALK = { kind: 'drift', reach: 0.05 } as const;

/**
 * Two masses on one clock and opposite halves of it: the scissor.
 *
 * A single walking tower asks "aim where the channel will be". A pair of them six
 * hundred pixels apart, one going out while the other comes back, asks the thing
 * this campaign has never asked: **there is no phase at which both are where you
 * last saw them.** A line laid for the first is always the wrong line for the
 * second, and the only way through is to lay the line the pair will have made by
 * the time you arrive.
 *
 * An authored phase is a sharp tool - it is also a phase that *repeats*, where the
 * default is keyed to where a section sits on the course so no two moving things
 * in the campaign are ever in step - so it is only ever written down to make a
 * pair. `tests/motion.test.ts` asserts exactly that: every authored phase has a
 * partner in its own station, half a cycle away, of the same kind.
 */
const WALK_OUT = { kind: 'drift', reach: 0.05, phase: 0 } as const;
const WALK_BACK = { kind: 'drift', reach: 0.05, phase: 0.5 } as const;

/**
 * Two breathing gaps, and the second is shut while the first is open.
 *
 * The couplet's demand is spatial - lay the line for the second gate before
 * entering the first - and this is the same sentence in time. Taking the first the
 * moment it opens arrives at the second at its narrowest; waiting one beat costs
 * ground against the drift and arrives on the open half of both. It is the only
 * place in this act where being early is a mistake.
 *
 * It needs a whole number of breaths between the two, which is what makes the
 * squall the station for it: 1 580 px at pace 1.06 is 21.9 seconds, and the breath
 * is 11. That is a longer leg than anything else in the act, which is why this is
 * spent once.
 */
const PULSE_OPEN = { kind: 'aperture', reach: 0.05, phase: 0.25 } as const;
const PULSE_SHUT = { kind: 'aperture', reach: 0.05, phase: 0.75 } as const;

export const AIR_LEVELS: Level[] = [
  {
    key: 'spray',
    name: 'The Spray',
    // Negative metres are height above the sea. The shell reads the sign.
    depthMeters: -60,
    subtitle: 'Just off the water',
    zone: ZONE_AIR,
    medium: 'air',
    decor: 'void',
    // The gentlest wind in the act, and still stronger than the trench floor's
    // current: the player has just been handed a medium that answers differently
    // and needs a station to find out how before anything is asked of them.
    pace: 0.85,
    roughness: 0.65,
    swirl: 0,
    /*
     * 760, 540, 1240, 580, 980, 1150 | 560, 620, 1220, 580, 1240, 1300, 500, 1300
     * - 12 570 px, and 3.6 minutes at the slowest pace in the act.
     *
     * The bar is where the mid-station breath is, and everything to the left of it
     * is the station exactly as it shipped: the opener, the deck, the shreds, the
     * tower, the wide lateral move. Everything to the right is the same five
     * shapes asked a second time with the act's second axis switched on, which is
     * the whole design of this rebuild in one station - **more of act II is more
     * act II; a breathing deck and a walking tower are not.**
     *
     * The three intervals are legible here because the station is slow enough to
     * hear them: 540-620 is inside one system, 1 220-1 300 is a crossing, and the
     * 500 at the end is the couplet, which is 8.7 seconds and the tightest thing
     * the player has met anywhere in two acts.
     */
    sections: [
      {
        // The first ten seconds of the act. Open air, one wide ring, and the
        // widest hole in the campaign: the only thing this section teaches is
        // that the same stroke still works up here, and it teaches it alone.
        //
        // 760 is act I's opening leg to the pixel. The two acts open on the same
        // interval on purpose - it is the last thing the player is given that is
        // exactly what it was in the water.
        kind: 'open',
        spacing: 760,
        rings: [must(0.5, 0, 10, 1.5)],
      },
      // ...and then the rhythm departs from act I's immediately. 540 px is inside
      // one system: the ring above is still being left when this hole arrives.
      {
        kind: 'bank',
        centre: 0.5,
        gap: 0.62,
        spacing: 540,
        rings: [{ x: 0.5, dy: -240, count: 8 }],
      },
      {
        // First shreds torn off the deck. Wide gaps, two rows - the chicane
        // arrives early in this act because a laid gust *lasts* up here, so the
        // lesson lands as generosity rather than as pressure.
        //
        // The act's first crossing, and it is placed here so the first empty leg
        // in act II comes before anything has gone wrong rather than after.
        //
        // Slowblue: the swing was 0.12 against a 0.58 gap, which means the two rows'
        // openings overlapped over 0.34 of the width - 133 px, wider than the flock
        // - so one x went through both rows and the act's declared chicane asked
        // for nothing at all. `wisps` was a dead mechanic in both of the two places
        // act II authors it. 0.19 leaves 79 px common, which is act I's first
        // chicane to the pixel: still the generous end, and now a line.
        kind: 'wisps',
        spacing: 1240,
        gap: 0.58,
        rows: 2,
        swing: 0.19,
        first: 1,
        rings: [{ x: 0.5, dy: -250, count: 8 }],
      },
      {
        // The act's splittable mass, and the shape a rock cannot be: taller than
        // it is wide. One ring in each channel and only one of them asked for -
        // splitting the flock is shown here, never demanded here.
        //
        // 580: the shreds and the tower are one system. Two rows of fractus reach
        // 200 px back from their own line, so this is as close as the pair can be
        // authored without the two geometries touching.
        // `height` is the only field that changes how far a mass runs *along* the
        // course, and it was authored once in seven level files - so every tower,
        // plume and canopy in the campaign was one shape scaled by radius. Act II's
        // fifteen ramp it 2.0 -> 2.9 and never once step back, which is the axis
        // the archetype exists for: the channels get longer to hold rather than
        // narrower to find.
        kind: 'tower',
        spacing: 580,
        centre: 0.52,
        radius: 0.11,
        height: 2,
        rings: [must(0.16, -120, 9, 1.35), { x: 0.86, dy: -120, count: 9, scale: 1.35 }],
      },
      // 980, and this is the station with no street to spend it on: the compulsory
      // ring above is at 0.16 and this one is at 0.66, which is half the field
      // laterally. A move that wide is the other thing that genuinely needs length.
      { kind: 'bank', centre: 0.66, gap: 0.56, spacing: 980, rings: [must(0.66, 210, 9, 1.35)] },
      // The breath, and it is in the middle of the station now. Everything before
      // it is act II as it shipped; everything after it is the act's second axis.
      breath(0.3, 8, 1150),
      {
        /*
         * The first thing in this act that moves, and it is here for the reason
         * act V's first aperture is in its deorbit: the slowest station in the
         * act, at nearly its widest gap, with nothing else in the frame and a
         * dashed ring 205 px behind it.
         *
         * It is authored **shut** at 0.58, which is passable at every phase, so a
         * player who does not notice that it is breathing still gets through - and
         * a player who does notice has just learned the act's second question
         * without having been told there was one.
         */
        kind: 'bank',
        centre: 0.42,
        gap: 0.58,
        spacing: 560,
        motion: PULSE,
        rings: [must(0.42, 205, 9, 1.35)],
      },
      {
        // The same chicane mirrored - `first: -1` where the opener was `1` - so
        // the two rows lean the other way and the line that took the first one is
        // the line that misses this one. Two rows again rather than three: the
        // shape's own ramp belongs to the cliff, and repeating a chicane at the
        // same size is what makes it a shape rather than an event.
        kind: 'wisps',
        spacing: 620,
        gap: 0.58,
        rows: 2,
        swing: 0.21,
        first: -1,
        rings: [{ x: 0.5, dy: -250, count: 9 }],
      },
      {
        /*
         * The first walking mass in the air.
         *
         * A tower that slides 0.05 of the width either way while the flock closes
         * on it, with a channel on each side and the dashed ring in the left one.
         * The demand is legible because the ring never moves: what moves is how
         * much room there is to get to it.
         *
         * A whole crossing in front of it on purpose. A walking mass met at pair
         * spacing is a reflex; met at 1 220 px it is a thing to watch first, and
         * watching it is the entire lesson.
         */
        kind: 'tower',
        spacing: 1220,
        centre: 0.5,
        radius: 0.105,
        height: 2.05,
        motion: WALK,
        rings: [must(0.15, -125, 10, 1.35), { x: 0.87, dy: -125, count: 10, scale: 1.35 }],
      },
      {
        // A deck with a deep tunnel through it. `depth` is the second row drawn
        // *back* along the course, and it was authored nowhere in seven level
        // files - every deck in the campaign was the default 150. At 220 the hole
        // is a short tunnel rather than a doorway, which asks the flock to hold
        // the line it committed to rather than to find one. Same gap, different
        // demand, no new shape.
        kind: 'bank',
        centre: 0.76,
        gap: 0.56,
        depth: 220,
        spacing: 580,
        rings: [{ x: 0.76, dy: -215, count: 9 }],
      },
      {
        // ...and its opposite, one crossing later: `depth: 0` is a deck one puff
        // thick, torn out of the haze, with no tunnel at all. The pair of them is
        // the cheapest variation in this file and the only one that is about how
        // *long* a hole is rather than how wide.
        kind: 'bank',
        centre: 0.3,
        gap: 0.6,
        depth: 0,
        spacing: 1240,
        rings: [must(0.3, 215, 10, 1.35)],
      },
      {
        // The couplet's first half. No dashed ring on it, and that is the rule
        // rather than a kindness: holding a body inside a ring and already
        // building the line out of it are two demands on one section, and the
        // couplet is the second of them.
        kind: 'bank',
        centre: 0.66,
        gap: 0.58,
        spacing: 1300,
        rings: [{ x: 0.66, dy: 205, count: 10, scale: 1.35 }],
      },
      {
        // ...and the second, 500 px later with its gap 0.34 of the width across
        // the field. 500 px at this pace is 8.7 seconds, which is not the problem;
        // the problem is that a gust laid *at* the first gap is still pushing when
        // this one arrives, so the only line that takes both was already leaning
        // left on the way through the first.
        kind: 'bank',
        centre: 0.32,
        gap: 0.56,
        spacing: 500,
        rings: [{ x: 0.32, dy: -200, count: 9 }],
      },
      breath(0.5, 9, 1300),
    ],
  },
  {
    key: 'cliff',
    name: 'The Cliff',
    depthMeters: -300,
    subtitle: 'Where the wind meets the wall',
    zone: ZONE_AIR + 1,
    medium: 'air',
    decor: 'void',
    pace: 0.9,
    roughness: 0.78,
    swirl: 0.62,
    /*
     * The headland. A sea cliff is the first place on the ascent where the air is
     * doing something because of the *ground*: wind hitting a wall has nowhere to
     * go but up, which is why every seabird colony in the world is on one and why
     * this station can introduce the rotor without introducing weather.
     *
     * So the composition is orographic throughout - cap cloud clinging along the
     * top of the headland, a standing rotor in its lee, and torn sea fog blowing
     * through the gap. There is no rock in it, because there is no rock anywhere
     * above the waterline in this game; the cliff itself is in the backdrop, where
     * the flock passes it rather than threading it.
     *
     * Its rhythm is the orography too. The cap and the rotor are one system and
     * are authored 520 px apart, which is the tightest pair in the act; everything
     * after them is spaced like open coast.
     *
     * 560, 520, 1200, 980, 600, 1300 | 560, 1240, 620, 1300, 600, 1400, 1320, 480,
     * 1420 - 14 100 px and 3.8 minutes, the longest station in the act in the unit
     * that matters, which is not pixels: the anvil is 2 600 px longer and finishes
     * a quarter of a minute sooner. The second
     * movement is where **the scissor** is, and a scissor needs the room: two
     * walking towers 620 px apart is ten seconds, which is very nearly one whole
     * breath, so the pair is met almost exactly a cycle apart with its two halves
     * half a cycle out of step.
     */
    sections: [
      // Cap cloud lying along the headland: a wide deck, met early, with the one
      // hole in it on the seaward side where the air is still smooth.
      { kind: 'bank', centre: 0.62, gap: 0.5, spacing: 560, rings: [must(0.62, 210, 9, 1.3)] },
      {
        // The lee rotor, and the act's first turning air. Deliberately gentler
        // than the squall's and sitting in a wide gap: the shape of the hazard is
        // legible a full station before it can cost anything.
        //
        // 520 because a lee rotor is not near the cap cloud, it is *caused* by it:
        // the two are one piece of weather and the interval says so.
        kind: 'rotor',
        spacing: 520,
        centre: 0.36,
        gap: 0.52,
        radius: 0.3,
        spin: -1,
        strength: 62,
        rings: [{ x: 0.36, dy: 230, count: 9 }],
      },
      {
        // The crossing out of the lee and along the coast.
        kind: 'tower',
        spacing: 1200,
        centre: 0.48,
        radius: 0.115,
        height: 2.15,
        // The compulsory channel is the seaward one. It was the left, at x = 58.5,
        // which is on top of the lit ridge the backdrop uses to say "cliff" - the
        // one station in the game with land in the frame, and the one whose own
        // header says the headland is scenery the flock passes rather than
        // geometry it threads. Nothing moves but which of the two is dashed.
        rings: [{ x: 0.15, dy: -130, count: 10, scale: 1.3 }, must(0.85, -130, 10, 1.3)],
      },
      {
        // Sea fog torn off the top of the cliff. Three rows here against the
        // spray's two, because this is the station where the shape ramps and a
        // chicane that never grows is a chicane the player has met once.
        //
        // 980 for the same reason the spray's fifth section has it: fog reaching
        // 200 px back off a tower's crown wants its own room, and this station has
        // no street to spend the slot on. Three rows reach 392 px rather than 196,
        // which still leaves 463 px of clear air in front of the tower above.
        kind: 'wisps',
        spacing: 980,
        gap: 0.54,
        rows: 3,
        swing: 0.2,
        first: -1,
        rings: [{ x: 0.5, dy: -250, count: 9 }],
      },
      // The fog and the last deck are the station's second pair: the same air,
      // 600 px apart, and the deck is what the fog was torn off.
      { kind: 'bank', centre: 0.3, gap: 0.5, spacing: 600, rings: [must(0.3, 200, 10, 1.3)] },
      breath(0.68, 8, 1300),
      {
        // A breathing cap, on the seaward side where the first one was. Orographic
        // cloud really does do this - a cap sits on the wind speed and thins when
        // the wind eases - so the one shape in this station that the ground is
        // making is also the one that is allowed to move.
        kind: 'bank',
        centre: 0.72,
        gap: 0.52,
        spacing: 560,
        motion: PULSE,
        rings: [must(0.72, 205, 10, 1.3)],
      },
      {
        /*
         * The scissor, front half.
         *
         * Two towers on the same eleven-second clock and opposite halves of it: by
         * the time the first has walked right the second has walked left, and the
         * lane the pair leaves is never straight. It is here rather than later
         * because the cliff is the last station before the act starts asking for
         * lines instead of holes, and because a scissor learned in a wide gap is a
         * scissor the anvil can ask for again at 0.40 of the width.
         *
         * The dashed ring is in the left channel - the one this mass is *not*
         * walking into when it walks right - so what moves is the room to reach a
         * ring that does not.
         */
        kind: 'tower',
        spacing: 1240,
        centre: 0.42,
        radius: 0.1,
        height: 2.2,
        motion: WALK_OUT,
        rings: [must(0.13, -135, 10, 1.3), { x: 0.78, dy: -135, count: 10, scale: 1.3 }],
      },
      {
        // ...and the back half, 620 px later and walking the other way. No dashed
        // ring, for the couplet's reason: this is the second half of a pair whose
        // demand *is* the pair, and holding a body still inside a ring while the
        // room in front of it is walking is two demands on one section.
        kind: 'tower',
        spacing: 620,
        centre: 0.6,
        radius: 0.1,
        height: 2.2,
        motion: WALK_BACK,
        rings: [{ x: 0.22, dy: -130, count: 10, scale: 1.3 }],
      },
      {
        // The last `wisps` in the act, and the third row is the point of it: fog
        // off the headland met a second time from the other side, one crossing
        // after a pair of towers that were not where they looked.
        kind: 'wisps',
        spacing: 1300,
        gap: 0.54,
        rows: 3,
        swing: 0.22,
        first: 1,
        rings: [{ x: 0.5, dy: -250, count: 10 }],
      },
      {
        // The second rotor, 600 px behind the fog: a lee wave does not come alone
        // and the pair says so. Spun the other way from the first, which is the
        // only thing in this station that reverses.
        kind: 'rotor',
        spacing: 600,
        centre: 0.52,
        gap: 0.5,
        radius: 0.32,
        spin: 1,
        strength: 72,
        rings: [must(0.52, 240, 10, 1.3)],
      },
      {
        // A deep cap on the far side of the field: 210 px of tunnel, met after the
        // longest crossing in the station.
        kind: 'bank',
        centre: 0.26,
        gap: 0.5,
        depth: 210,
        spacing: 1400,
        rings: [must(0.26, 200, 11, 1.3)],
      },
      // The couplet, and the tightest in the act at 480 px - 7.8 seconds. The two
      // gaps are 0.34 of the width apart and neither is dashed.
      {
        kind: 'bank',
        centre: 0.68,
        gap: 0.52,
        spacing: 1320,
        rings: [{ x: 0.68, dy: 200, count: 11, scale: 1.3 }],
      },
      {
        kind: 'bank',
        centre: 0.34,
        gap: 0.5,
        spacing: 480,
        rings: [{ x: 0.34, dy: -195, count: 10 }],
      },
      breath(0.5, 9, 1420),
    ],
  },
  {
    key: 'cumulus',
    name: 'The Cumulus Field',
    depthMeters: -1200,
    subtitle: 'Where the clouds are built',
    zone: ZONE_AIR + 2,
    medium: 'air',
    decor: 'void',
    pace: 0.94,
    roughness: 0.9,
    swirl: 0,
    /*
     * The fair-weather field, and the first station with a street in it. Cumulus
     * lines up downwind the moment there is any wind to line up in, and the field
     * is where a player first sees the two states of the same cloud: a pile to go
     * round, and a pair of lines to fly between.
     *
     * 540, 540, 1000, 1240, 580, 1350 | 560, 1300, 600, 1300, 620, 1400, 1320,
     * 500, 1450 - 14 300 px, 3.7 minutes.
     *
     * Two streets, and the second one **breathes**. That is the station's whole
     * second movement: the first street is 560 px of corridor to be held, and the
     * second is 600 px of corridor whose walls move while the flock is between
     * them. It is the only demand in the campaign that is not over in a frame, and
     * this is where it can be shown - the field is stable air, which is what makes
     * streets at all, and there is no rotor in the station to argue with it.
     */
    sections: [
      { kind: 'bank', centre: 0.28, gap: 0.5, spacing: 540, rings: [must(0.28, 200, 9)] },
      {
        // The deck and the tower are one system, 540 apart: this is what the deck
        // above turns into when it keeps growing, and the pair says so.
        kind: 'tower',
        spacing: 540,
        centre: 0.5,
        radius: 0.12,
        height: 2.3,
        rings: [must(0.15, -140, 10), { x: 0.85, dy: -140, count: 10, scale: 1.25 }],
      },
      {
        // The act's first street, and the first thing in the campaign that is not
        // a hole. 560 px of corridor is deliberately the shortest one in the act:
        // it is long enough that `AmbientFlow` reverses inside it once, which is
        // the whole demand, and short enough to be survivable the first time.
        //
        // The gap is 0.48 against this station's narrowest of 0.40. A corridor
        // held for 560 px at the width of a momentary slot is not a harder version
        // of the same thing, it is a different and worse thing.
        //
        // 1 000 of leg for 560 of cloud leaves the tower above 440 px of clear air.
        kind: 'street',
        spacing: 1000,
        centre: 0.46,
        gap: 0.48,
        length: 560,
        // Half the street's length back from the line, so the ring is at the
        // middle of the corridor rather than behind its exit.
        rings: [must(0.46, 280, 10)],
      },
      {
        // First pass: two shoulders closing on a slot. In cloud a funnel has no
        // walls, it has sides that thin out - which is why the geometry is
        // forgiving here and the *line* is not.
        //
        // The crossing sits here rather than earlier so the street and the pass
        // are 1 240 px apart. They are the two halves of one idea and the act
        // cannot afford to have them read as a chicane.
        kind: 'pass',
        spacing: 1240,
        centre: 0.4,
        gap: 0.4,
        mouth: 0.5,
        depth: 230,
        rings: [must(0.4, 260, 11)],
      },
      {
        kind: 'bank',
        centre: 0.72,
        gap: 0.46,
        spacing: 580,
        rings: [{ x: 0.72, dy: -220, count: 10 }],
      },
      breath(0.3, 9, 1350),
      {
        // A breathing deck, and the run-in to the breathing street: the same
        // motion on the shape the player already knows, one crossing before it
        // arrives on the shape they do not.
        kind: 'bank',
        centre: 0.34,
        gap: 0.46,
        spacing: 560,
        motion: PULSE,
        rings: [must(0.34, 205, 10)],
      },
      {
        /*
         * The breathing street, and the act's own answer to the second axis.
         *
         * Every other moving thing in this game finishes moving before the demand
         * is over, because the demand is one frame long: be at this x when the
         * centroid crosses this line. A street is not that. 600 px of corridor at
         * pace 0.94 is 9.4 seconds, and the breath is 11 - so the walls open and
         * come back in **while the flock is inside them**, once, and there is
         * nowhere in the corridor to be that is not affected by it.
         *
         * Authored shut at 0.46, so the sweep is already checking the version with
         * no help in it: what the motion adds is a window, not a requirement. The
         * ring is where a street's ring always is, at the corridor's own middle.
         */
        kind: 'street',
        spacing: 1300,
        centre: 0.54,
        gap: 0.46,
        length: 600,
        motion: PULSE,
        rings: [must(0.54, 300, 11)],
      },
      {
        // A walking tower 600 px out of a corridor, which is the one transition
        // this station has that the spray's could not: the flock leaves a held
        // line straight into a mass that is not where it was. The dashed channel
        // is the far one, so the demand is to cross the field to a ring while the
        // room to do it in is moving.
        kind: 'tower',
        spacing: 600,
        centre: 0.42,
        radius: 0.11,
        height: 2.35,
        motion: WALK,
        rings: [{ x: 0.11, dy: -140, count: 10, scale: 1.25 }, must(0.84, -140, 11)],
      },
      {
        kind: 'pass',
        spacing: 1300,
        centre: 0.62,
        gap: 0.42,
        mouth: 0.52,
        depth: 235,
        rings: [must(0.62, 255, 11)],
      },
      {
        // The station's third tower and its tallest: 2.4 against the field's 2.3.
        // Neither channel is dashed - the flock has been asked to split twice
        // already here and this one is the pay.
        kind: 'tower',
        spacing: 620,
        centre: 0.48,
        radius: 0.12,
        height: 2.4,
        rings: [
          { x: 0.14, dy: -145, count: 11, scale: 1.25 },
          { x: 0.84, dy: -145, count: 11, scale: 1.25 },
        ],
      },
      {
        kind: 'bank',
        centre: 0.24,
        gap: 0.44,
        depth: 200,
        spacing: 1400,
        rings: [must(0.24, 200, 11)],
      },
      // The couplet: 0.68 and 0.34, which is 0.34 of the width apart, 500 px and
      // 7.8 seconds. Nothing dashed on either half.
      {
        kind: 'bank',
        centre: 0.68,
        gap: 0.44,
        spacing: 1320,
        rings: [{ x: 0.68, dy: 200, count: 11, scale: 1.25 }],
      },
      {
        kind: 'bank',
        centre: 0.34,
        gap: 0.42,
        spacing: 500,
        rings: [{ x: 0.34, dy: -195, count: 10 }],
      },
      breath(0.5, 10, 1450),
    ],
  },
  {
    key: 'passage',
    name: 'The Passage',
    depthMeters: -2500,
    subtitle: 'The way everything is going',
    zone: ZONE_AIR + 3,
    medium: 'air',
    decor: 'void',
    pace: 1,
    roughness: 1.02,
    swirl: 0.7,
    /*
     * Two and a half kilometres, which is the altitude birds actually migrate at,
     * and the last station in the campaign where the air is something a body can
     * live in. Everything above this is survived rather than inhabited.
     *
     * Its composition is the one piece of the ascent that is about *company*.
     * Long parallel lines of torn cloud running the way the course runs - the
     * flyway, drawn as weather - and the act's raptors working it, because a
     * migration route is exactly where something would wait. Mechanically that
     * makes this the station where the flock is asked to hold a shape along a
     * corridor rather than thread a hole, which nothing before it has asked for.
     *
     * That sentence used to be a claim the station did not keep: it was authored
     * as three staggered holes, which is a chicane and is exactly what everything
     * else in the game already was. It opens on a street now, and the sentence is
     * true - 640 px of corridor, entered anywhere and left in one place.
     *
     * 980, 540, 1220, 540, 580, 1400 | 560, 1300, 600, 1300, 620, 1400, 1300, 500,
     * 1450 - 14 290 px, 3.5 minutes. Two streets and two raptors, and they are
     * paired the same way both times: the hunter is the section immediately behind
     * the corridor, because the one place a flock cannot answer a threat is the
     * one place it is not allowed to leave.
     */
    sections: [
      {
        // The flyway. The longest street in the act, and it is first rather than
        // buried because the station's whole subject is the route: the flock is
        // put in the line before it is shown who else uses it.
        kind: 'street',
        spacing: 980,
        centre: 0.5,
        gap: 0.46,
        length: 640,
        rings: [must(0.5, 320, 10)],
      },
      {
        // The first raptor, and it comes from *behind*. Everything in acts I and
        // II so far arrives from the direction the flock is already facing; this
        // does not, which is the whole point of it.
        //
        // 540: the raptor is on the street. It is the one pair in the act where
        // the second thing is a consequence of the first rather than the same
        // weather twice.
        //
        // The stoop is at 460 rather than 600 so that it enters 80 px *after* the
        // street's exit. A hunter materialising inside the corridor would be the
        // one place in act II where a threat came out of cloud rather than out of
        // sky, and the corridor is the last place that can be allowed to happen.
        kind: 'raptor',
        spacing: 540,
        centre: 0.3,
        radius: 0.1,
        hunters: [{ x: 0.46, dy: 460, size: 14, stoop: true }],
        rings: [must(0.72, 220, 10)],
      },
      {
        // The crossing, and the flyway's open middle.
        kind: 'pass',
        spacing: 1220,
        centre: 0.56,
        gap: 0.38,
        mouth: 0.5,
        depth: 235,
        rings: [must(0.56, 255, 11)],
      },
      {
        kind: 'rotor',
        spacing: 540,
        centre: 0.4,
        gap: 0.44,
        radius: 0.3,
        spin: 1,
        strength: 88,
        rings: [{ x: 0.4, dy: 235, count: 10 }],
      },
      {
        // Pass, rotor and tower inside 1 120 px: the densest run in act II, at the
        // station whose subject is traffic. It is authored as a run and not as
        // three sections because the three of them are one weather system that has
        // grown - a slot, the turning air under it, and the cloud doing the turning.
        kind: 'tower',
        spacing: 580,
        centre: 0.54,
        radius: 0.125,
        height: 2.5,
        // One channel dashed and the other offered. Both used to be dashed here,
        // with an argument for it - a demanded split needs a whole crossing to be
        // one body again - and the argument was answered by measurement rather
        // than by taste: 28 % of the flock held still in two places at once is
        // 56 %, which is a wall and not a demand. See the header, rule 2.
        rings: [must(0.16, -145, 11), { x: 0.86, dy: -145, count: 11, scale: 1.25 }],
      },
      breath(0.34, 9, 1400),
      {
        kind: 'bank',
        centre: 0.3,
        gap: 0.44,
        spacing: 560,
        motion: PULSE,
        rings: [must(0.3, 205, 11)],
      },
      {
        // The second street, and the flyway proper: 620 px of corridor with the
        // second raptor waiting at the end of it.
        kind: 'street',
        spacing: 1300,
        centre: 0.58,
        gap: 0.44,
        length: 620,
        rings: [must(0.58, 310, 11)],
      },
      {
        // ...and the ambush, which is the other half of what a migration route is.
        // This one does not stoop: it is already in front, in the clear air the
        // corridor opens into, and it is placed 150 px past the line so that the
        // flock meets it in the first frame after it stops being held.
        kind: 'raptor',
        spacing: 600,
        centre: 0.44,
        radius: 0.1,
        hunters: [{ x: 0.28, dy: -150, size: 15 }],
        rings: [{ x: 0.78, dy: 215, count: 11, scale: 1.25 }],
      },
      {
        kind: 'tower',
        spacing: 1300,
        centre: 0.42,
        radius: 0.12,
        height: 2.55,
        motion: WALK,
        rings: [{ x: 0.12, dy: -145, count: 11, scale: 1.25 }, must(0.84, -145, 11)],
      },
      {
        kind: 'rotor',
        spacing: 620,
        centre: 0.64,
        gap: 0.42,
        radius: 0.32,
        spin: -1,
        strength: 92,
        rings: [must(0.64, 240, 11)],
      },
      {
        kind: 'bank',
        centre: 0.26,
        gap: 0.42,
        depth: 200,
        spacing: 1400,
        rings: [must(0.26, 205, 11)],
      },
      // The couplet, and the only one in the act whose first half is a slot rather
      // than a deck: a pass at 0.64 and a deck at 0.32, 500 px and 7.4 seconds
      // apart. Coming out of a funnel already leaning is a harder thing to do than
      // coming out of a hole already leaning, which is why it is here and not
      // earlier.
      {
        kind: 'pass',
        spacing: 1300,
        centre: 0.64,
        gap: 0.4,
        mouth: 0.52,
        depth: 240,
        rings: [{ x: 0.64, dy: 255, count: 12, scale: 1.25 }],
      },
      {
        kind: 'bank',
        centre: 0.32,
        gap: 0.42,
        spacing: 500,
        rings: [{ x: 0.32, dy: -200, count: 11 }],
      },
      breath(0.5, 10, 1450),
    ],
  },
  {
    key: 'squall',
    name: 'The Squall',
    depthMeters: -4000,
    subtitle: 'The air becomes visible',
    zone: ZONE_AIR + 4,
    medium: 'air',
    decor: 'void',
    pace: 1.06,
    roughness: 1.15,
    swirl: 0.8,
    /*
     * The one station in the act with no street in it, and that is a statement
     * rather than an omission: cloud streets form in stable air with a wind, and a
     * thunderstorm is the opposite of stable. What a squall has instead is cells,
     * so this station is authored as cells - a pair, a long crossing of rain, and
     * another pair - which is the same rhythm read as weather rather than as a
     * flight plan.
     *
     * 540, 540, 1300, 1080, 580, 1450 | 560, 1580, 660, 1300, 580, 1400, 1320,
     * 500, 1500 - 14 890 px, 3.4 minutes.
     *
     * The 1 580 is the longest leg anywhere in act II and it is the only spacing in
     * this file that was chosen as a *duration*: at pace 1.06 it is 21.9 seconds,
     * which is two breaths, and two breaths is what makes **the counter-phase
     * pair** work. See `PULSE_OPEN`. Everything else in the station is the act's
     * ordinary three intervals.
     */
    sections: [
      {
        // The first rotor of the station, and it is deliberately a gentle one in a
        // wide gap: the shape of the hazard is legible before it can cost anything.
        // Rain is drawn on this station, so the one place the medium can be *seen*
        // is the one place it first turns.
        kind: 'rotor',
        spacing: 540,
        centre: 0.5,
        gap: 0.48,
        radius: 0.32,
        spin: 1,
        strength: 84,
        rings: [must(0.5, 250, 10)],
      },
      // The rotor and the deck under it are the first cell, 540 apart.
      { kind: 'bank', centre: 0.26, gap: 0.44, spacing: 540, rings: [must(0.26, 200, 10)] },
      {
        // Out of the first cell and across the rain to the second.
        kind: 'tower',
        spacing: 1300,
        centre: 0.56,
        radius: 0.13,
        height: 2.7,
        rings: [must(0.16, -150, 11), { x: 0.86, dy: -150, count: 11, scale: 1.25 }],
      },
      {
        // 0.16 to 0.62 across the field, into the narrowest slot the act has had
        // so far. The station has no street to spend its long slot on and this is
        // the move that needs it.
        kind: 'pass',
        spacing: 1080,
        centre: 0.62,
        gap: 0.34,
        mouth: 0.5,
        depth: 240,
        rings: [must(0.62, 265, 12)],
      },
      {
        kind: 'rotor',
        spacing: 580,
        centre: 0.34,
        gap: 0.42,
        radius: 0.3,
        spin: -1,
        strength: 98,
        rings: [{ x: 0.34, dy: 240, count: 11 }],
      },
      breath(0.66, 9, 1450),
      {
        /*
         * The counter-phase pair, front half, and the act's last new idea.
         *
         * Two breathing gaps 1 580 px apart - 21.9 seconds, or two breaths -
         * authored half a cycle out of step, so **the second one is shut while the
         * first one is open**. Taking this one the moment it opens puts the flock
         * at the next one at its narrowest; waiting a beat costs ground against
         * the drift and arrives on the open half of both.
         *
         * It is the couplet's demand moved from space into time. The couplet says
         * lay the line for the second gate before entering the first; this says
         * choose *when* to enter the first, and it is the only place in the act
         * where being early is a mistake. It is in the squall rather than the anvil
         * because it needs a leg long enough to be read in, and the squall is the
         * station whose own shape is already a long crossing of rain.
         */
        kind: 'bank',
        centre: 0.44,
        gap: 0.42,
        spacing: 560,
        motion: PULSE_OPEN,
        rings: [must(0.44, 205, 11)],
      },
      {
        // ...and the back half, on the other side of the rain, and a slot rather
        // than a deck. Two breaths of empty air is the longest anything in this
        // act asks the player to hold an intention across, which is what the
        // demand needs and is also what makes it survivable: there is nothing else
        // in the leg to spend attention on.
        kind: 'pass',
        spacing: 1580,
        centre: 0.6,
        gap: 0.38,
        mouth: 0.5,
        depth: 240,
        motion: PULSE_SHUT,
        rings: [must(0.6, 255, 12)],
      },
      {
        // A raptor working the back of the second cell. It stoops from 430 px
        // behind, which at this pace is about six seconds of warning, and it is
        // the only hunter in the campaign that arrives in rain.
        kind: 'raptor',
        spacing: 660,
        centre: 0.36,
        radius: 0.1,
        hunters: [{ x: 0.52, dy: 430, size: 15, stoop: true }],
        rings: [{ x: 0.72, dy: 215, count: 11, scale: 1.25 }],
      },
      {
        // The dashed channel is the right one, and that is not a preference: at
        // 0.13 it was, and the rotor 580 px behind it wants 0.64, which is half
        // the field crossed in 190 px of travel between the two rings. The
        // campaign's chain check in `tests/geometry.test.ts` reads exactly that
        // question - can *one body* take the compulsory rings in order - and it is
        // the only thing in this file that a corridor sweep would have approved
        // and a player could not have flown.
        kind: 'tower',
        spacing: 1300,
        centre: 0.48,
        radius: 0.115,
        height: 2.75,
        motion: WALK,
        rings: [{ x: 0.13, dy: -150, count: 11, scale: 1.25 }, must(0.85, -150, 12)],
      },
      {
        // The strongest rotor in the act before the anvil's, 580 px behind a mass
        // that was walking: turning air met by a body that has just been pulled
        // sideways by something else.
        kind: 'rotor',
        spacing: 580,
        centre: 0.64,
        gap: 0.4,
        radius: 0.31,
        spin: 1,
        strength: 104,
        rings: [must(0.64, 240, 12)],
      },
      {
        kind: 'bank',
        centre: 0.28,
        gap: 0.4,
        depth: 215,
        spacing: 1400,
        rings: [must(0.28, 205, 11)],
      },
      // The couplet: a slot at 0.40 and a deck at 0.72, 0.32 of the width apart,
      // 500 px and 6.9 seconds. The tightest couplet in the act so far, and it
      // arrives where the station has finished asking for anything else.
      {
        kind: 'pass',
        spacing: 1320,
        centre: 0.4,
        gap: 0.36,
        mouth: 0.52,
        depth: 240,
        rings: [{ x: 0.4, dy: 260, count: 12, scale: 1.25 }],
      },
      {
        kind: 'bank',
        centre: 0.72,
        gap: 0.38,
        spacing: 500,
        rings: [{ x: 0.72, dy: -200, count: 11 }],
      },
      breath(0.5, 10, 1500),
    ],
  },
  {
    key: 'anvil',
    name: 'The Anvil',
    depthMeters: -11000,
    subtitle: 'Where the weather stops',
    zone: ZONE_AIR + 5,
    medium: 'air',
    decor: 'void',
    pace: 1.14,
    roughness: 1.3,
    swirl: 0.9,
    /*
     * Eleven kilometres, the top of the storm, and the last station anything with
     * wings gets to have. Above the anvil the air stops being able to hold a bird
     * up - so this is where the flock's part of the campaign ends, and the act's
     * hardest station is deliberately its last rather than its middle.
     *
     * Four raptors: two stoops and two ambushes. The stoop is the one hazard in the
     * game that comes from behind - it is armed at its authored line and released
     * 170 px down the course from the flock, because a hunter spawned with
     * everything else arrives 1 300 px *ahead* of its target and a stoop that
     * overtakes from in front is not a stoop (see `World.releaseStoops`). The
     * ambushes wait in the clear air the corridors open into.
     *
     * 540, 980, 580, 540, 1220, 1500 | 560, 1400, 620, 1400, 640, 1400, 600, 1400,
     * 1320, 500, 1500 - 16 700 px and 3.6 minutes, which is the longest station in
     * the act by a third of a screen and the *fourth* longest in seconds. That gap
     * between the two units is what pace 1.14 buys, and it is the reason this file
     * quotes minutes everywhere it can.
     *
     * The crossings are the longest in the act, and that is meteorology rather
     * than padding: an anvil is one system spread across a whole sky, not five
     * small ones in a row, so what is between things up here is more sky. What
     * makes it the hardest station is what it asks inside those legs - the act's
     * narrowest slot at 0.28, a street that breathes, the scissor a second time,
     * and something hunting through all of it.
     */
    sections: [
      {
        kind: 'raptor',
        spacing: 540,
        centre: 0.34,
        radius: 0.1,
        hunters: [
          { x: 0.5, dy: 620, size: 15, stoop: true },
          // -140 rather than -420. At -420 this bird was built 141 px *inside* the
          // next section's street, which is the one thing this act's own grammar
          // forbids in as many words - a threat coming out of cloud rather than out
          // of sky, in the corridor that is the least able to afford it. It is also
          // the one hunter in the act that reliably engages, so it is the one that
          // most needs to be where the act says hunters may be.
          { x: 0.22, dy: -140, size: 15 },
        ],
        rings: [must(0.7, 230, 11)],
      },
      {
        // The narrowest street, and the longest: 0.42 of the width held for 680 px,
        // with two raptors' worth of disturbance still in the air behind it. That
        // is the ramp this archetype gets - the act never narrows a corridor to the
        // width of a slot, it makes the player hold one for longer.
        //
        // Streets at the top of a storm are the real thing too: the anvil is where
        // the outflow spreads, and what spreads runs in lines.
        kind: 'street',
        spacing: 980,
        centre: 0.56,
        gap: 0.42,
        length: 680,
        rings: [must(0.56, 340, 11)],
      },
      {
        // 580 out of the corridor and straight into turning air, which is the one
        // transition this act has not asked for before: the flock leaves a held
        // line with no crossing to re-form on.
        kind: 'rotor',
        spacing: 580,
        centre: 0.6,
        gap: 0.4,
        radius: 0.32,
        spin: -1,
        strength: 108,
        rings: [must(0.6, 250, 12)],
      },
      {
        kind: 'tower',
        spacing: 540,
        centre: 0.48,
        radius: 0.14,
        height: 2.9,
        rings: [must(0.14, -160, 12), { x: 0.85, dy: -160, count: 12, scale: 1.25 }],
      },
      {
        // The act's narrowest slot, and the only thing in the first movement with a
        // full crossing in front of it.
        kind: 'pass',
        spacing: 1220,
        centre: 0.44,
        gap: 0.28,
        mouth: 0.52,
        depth: 250,
        rings: [must(0.44, 270, 12)],
      },
      // The mid-station breath, and the longest rest in the act. It is here because
      // everything in front of it is the hardest run act II has - five sections
      // inside 3 860 px with a hunter in the first of them - and everything behind
      // it is harder still.
      breath(0.32, 10, 1500),
      {
        kind: 'bank',
        centre: 0.36,
        gap: 0.4,
        spacing: 560,
        motion: PULSE,
        rings: [must(0.36, 205, 12)],
      },
      {
        // The second breathing street, and the last corridor in the act. 640 px at
        // pace 1.14 is 8.3 seconds against the breath's eleven, so the walls do not
        // quite complete a cycle while the flock is in here - which means where in
        // the cycle it *enters* decides whether the corridor is opening or closing
        // around it for the whole run. The cumulus's version, met once the player
        // knows what a corridor costs.
        kind: 'street',
        spacing: 1400,
        centre: 0.46,
        gap: 0.44,
        length: 640,
        motion: PULSE,
        rings: [must(0.46, 320, 12)],
      },
      {
        // The third raptor, and the second stoop: 440 px behind this line is 180 px
        // in front of the street's exit, so it is armed as the flock leaves the
        // corridor and arrives while it is still one line rather than one body.
        kind: 'raptor',
        spacing: 620,
        centre: 0.64,
        radius: 0.105,
        hunters: [{ x: 0.38, dy: 440, size: 16, stoop: true }],
        rings: [{ x: 0.28, dy: 215, count: 12, scale: 1.25 }],
      },
      {
        // The scissor returns, and this is what it was taught at the cliff for: the
        // same pair of walking towers, in the narrowest air in the act, with a
        // raptor still in the frame behind them. Nothing about the shape is new;
        // everything around it is.
        kind: 'tower',
        spacing: 1400,
        centre: 0.42,
        radius: 0.115,
        height: 2.9,
        motion: WALK_OUT,
        rings: [must(0.86, -155, 12), { x: 0.12, dy: -155, count: 12, scale: 1.25 }],
      },
      {
        kind: 'tower',
        spacing: 640,
        centre: 0.62,
        radius: 0.115,
        height: 2.9,
        motion: WALK_BACK,
        rings: [{ x: 0.22, dy: -150, count: 12, scale: 1.25 }],
      },
      {
        // The strongest turning air in the campaign's first half.
        kind: 'rotor',
        spacing: 1400,
        centre: 0.44,
        gap: 0.38,
        radius: 0.33,
        spin: 1,
        strength: 112,
        rings: [must(0.44, 245, 12)],
      },
      {
        // The last raptor in act II, and the last thing that hunts this carrier at
        // all - the next hunter in the campaign is act V's ember, thirty stations
        // and half a circuit away. It is an ambush rather than a stoop, so the
        // flock meets it head on, which is the only way for this act to finish
        // with the threat in front of the player rather than behind them.
        kind: 'raptor',
        spacing: 600,
        centre: 0.56,
        radius: 0.1,
        hunters: [{ x: 0.68, dy: -140, size: 16 }],
        rings: [{ x: 0.24, dy: 210, count: 12, scale: 1.25 }],
      },
      {
        // The last slot, and the last dashed ring in the air.
        kind: 'pass',
        spacing: 1400,
        centre: 0.32,
        gap: 0.3,
        mouth: 0.5,
        depth: 245,
        rings: [must(0.32, 260, 13)],
      },
      // The act's last couplet, and its tightest in seconds: 500 px at pace 1.14 is
      // 6.5 s, with the two gaps 0.34 of the width apart. Neither is dashed. It is
      // the whole act in two sections - no new shape, no narrower hole, and the
      // line for the second one has to exist before the first one is entered.
      {
        kind: 'bank',
        centre: 0.66,
        gap: 0.38,
        spacing: 1320,
        rings: [{ x: 0.66, dy: 200, count: 12, scale: 1.25 }],
      },
      {
        kind: 'bank',
        centre: 0.32,
        gap: 0.36,
        spacing: 500,
        rings: [{ x: 0.32, dy: -195, count: 12 }],
      },
      // The last section of the air. Open sky with one wide ring in it and
      // nothing else - the flock's wings have already stopped working by the time
      // the player crosses this line, and what happens next is `render/Release.ts`
      // handing what they carried to act III. It is the act's longest leg, which
      // is the only ending an act about crossing country can have.
      { kind: 'open', spacing: 1500, rings: [{ x: 0.5, dy: -80, count: 10 }] },
    ],
  },
];

/** Act II: six stations, the wave tops to the top of the weather. */
export const ACT_AIR: Act = makeAct('air', AIR_LEVELS, { carrier: 'birds' });
