import { makeAct, type Act, type Level, type RingSpec, type SectionSpec } from './levels';
import { ZONE_RAIN } from './zones';

/**
 * Slowblue: act VI - the rain.
 *
 * ## Reunion, and the one act where the rings change meaning
 *
 * Everything that has happened since the anvil has been a scattering. The flock
 * released what it carried, the motes came apart in the upper air, and the plasma
 * tore whatever was left into dust. This act puts it back together, and it does
 * that by turning the campaign's oldest mechanic inside out:
 *
 * **A rescue ring here gathers scattered droplet groups back.** The same object,
 * the same physics, the same ring the trench floor introduced - and for six acts
 * it has meant "more of you". In this one it means "you again". Nothing in the
 * code changes, and nothing needs to: the meaning is carried entirely by the
 * carrier and by where the player has just been.
 *
 * Growth here makes the group more stable and heavier to steer, which is the
 * `stream` medium's own `inertiaPerAgent` - the highest in the campaign. Coming
 * back together costs manoeuvrability, and that is the right cost for it.
 *
 * ## Six stations, and three media
 *
 *   1. **Cirrus** (11 km) - ice again, briefly, and the top of the weather from
 *      above it for the last time.
 *   2. **Under the Anvil** (9 km) - **the same cloud act II climbed over, from
 *      underneath.** The first moment the campaign lets the player recognise
 *      somewhere they have been, and it is never remarked on.
 *   3. **The Downpour** (2 km) - gravity takes over from wind.
 *   4. **The Canopy** (100 m) - the first green in the game, and the
 *      first solid obstacle since act I.
 *   5. **The Mountain Brook** (400 m) - running water, and the medium changes to `stream`:
 *      it grips harder than the sea and forgets faster, because the whole medium
 *      is already going somewhere and what the player adds is a nudge on top.
 *   6. **The Estuary** (0 m) - the separate drops have become one
 *      flowing body, and where the fresh water meets the salt the gold comes back
 *      as something alive.
 *
 * The altitudes are not monotone and that is not a mistake: the brook is at four
 * hundred metres and the canopy at a hundred, because a mountain stream starts
 * *above* the forest it runs down through. The campaign's continuity is the
 * journey rather than the number.
 *
 * ## This act was rebuilt to act V's recipe, and it was rebuilt for one fault
 *
 * The measurement is [docs/DESIGN-LENGTH.md](../../docs/DESIGN-LENGTH.md): the
 * circuit is an hour, the hour is not the problem, and the *distribution* of it
 * is. Act VI's own line in that table was the sharpest one in it - **its
 * narrowest gap was 0.36, wider than the trench floor's 0.26**, six acts in. The
 * campaign peaked in act II and then spent forty minutes coming down.
 *
 * The fault is real and the obvious fix is the wrong one. Gap widths do **not**
 * tighten here and precision is not the lever: the swarm's own lateral reach is a
 * hard floor under gap width, and squeezing toward it is the cheapest and most
 * frustrating difficulty there is. 0.36 is still the narrowest thing in this act
 * and it is still in the brook. What changed is what a section *asks*:
 *
 *   - **an aperture** - a door authored shut that breathes open on the breath's
 *     own eleven seconds. Seven of them, at least one in every station.
 *   - **a walking mass** - a column, a tower, a tree or a boulder that slides
 *     sideways while the swarm closes on it. The `Section.envelope` carries the
 *     union of everywhere it ever is and the corridor sweep reads that, so the
 *     guarantee is the strong one: there is a line past it whenever you arrive.
 *   - **the scissor** - two walking masses on one clock and opposite halves of
 *     it, so the lane between them is never straight. Twice: two cumulus towers
 *     under the anvil, two trees in the canopy.
 *   - **the counter-phase pair** - two breathing gaps two breaths apart, the
 *     second shut while the first is open. Once, in the downpour, on two rain
 *     curtains.
 *   - **the couplet** - two sections four hundred-odd pixels apart with their
 *     gaps a third of the width from each other, so the line for the second has
 *     to be laid before entering the first. One at the end of five stations; the
 *     estuary has finished asking by then and its gaps only widen.
 *
 * **24 sections -> 61, 9.7 authored minutes -> 21.2, 17 obstacles -> 48.** The
 * `pace`, `roughness` and `swirl` of all six stations are byte-for-byte what they
 * were: the act does not get faster, there is more of it.
 *
 * ### ...and the fall in this act was already paid for
 *
 * Act V's rebuild found that a falling act is *free*: the camera takes the greater
 * of its own drift and the swarm's position, so a hand that pushes forward drags
 * the world with it and the one failure of position in this game is unreachable by
 * anybody who pushes (DESIGN-LENGTH §10). The fix is `Medium.drag` - past 1.6 times
 * a station's own drift, the medium starts taking the swarm apart from the front -
 * and act VI falls, so it looked like it needed one.
 *
 * **It was turned on for `cloud` and `stream`, measured, and turned back off**,
 * which is the more useful result. Rushing this act is *already* slower than
 * flying it carefully: 11 932 px against 15 182 over five minutes, at 0.83 of the
 * world's own travel against 1.08, with nine station restarts against one. The
 * thing charging for speed here is the course. Turned on, the terminal cost act VI
 * 1 296 carriers and 92 restarts for a fault it does not have.
 *
 * That is what the long quiets below are authored against, and it is why they can
 * be long: this act's crossings are not free ground, because what is waiting at
 * the end of one is a burst nobody arrives at tidily in a hurry.
 *
 * ## The rhythm: squalls
 *
 * Every act used to be laid on the same 820 px metronome, and for this one that
 * was not merely uniform, it was wrong about the weather. Rain does not fall
 * evenly and it does not arrive on a beat. It comes in bursts with quiet between
 * them, and this is the one act whose subject is weather the swarm is *inside*
 * rather than weather it is crossing.
 *
 * So act VI alternates hard, and it is the only act that does: **two things
 * almost on top of each other, then a long quiet, then two more.** The gaps run
 * from 380 px to 1400, and the alternation rather than either number is the
 * point - a station is heard as burst, rest, burst, rest, which is what standing
 * under a shower head of a sky actually sounds like.
 *
 * Per-station totals: 7280, 7470, 7490, 7190, 7630, 7370 - **44 430 px**, and
 * they even out where they used to run 2800 to 3940. Two are still deliberate
 * rather than arithmetic. **The Downpour** is the act's hardest station and keeps
 * the shortest quiets in the campaign - nothing in it is further than 880 px from
 * the thing before it, where every other station here has a crossing of 1180 or
 * more - because it is the part of the journey that is genuinely falling.
 * **The Estuary** is the longest at 4.1 minutes and the thinnest at 1.7 obstacles a
 * minute, because an estuary opens out, and the last station of the last act that
 * asks for anything should stop asking before it ends.
 *
 * `tests/descent.test.ts` sums the authored spacings and holds every act's length
 * against a band. Act VI belongs in that suite's `REBUILT` set now, next to act
 * V: an act that has been through this recipe is not an act that is still ten
 * minutes long, and widening the band for everybody would leave the check unable
 * to fail for either kind of act.
 *
 * ## Two movements, two rests, and a station that does not end on a gate
 *
 * A doubled station that is twice as much of the same thing is a station that
 * drags. So each one here is **A, a breath, and B**: A speaks the station's
 * established language, B is where its hardest question arrives, and the empty
 * section between them is the one place the phone can go down mid-station.
 *
 * The mid-station breath is an *addition*, not the landing moved, and that is a
 * measurement rather than a preference. Act V was built the other way first - the
 * rest taken from the end of the station and spent in the middle - and it cost
 * 42.6 restarts a run against a baseline of 1.2, every one of them the swarm
 * being left behind rather than a missed ring. A station's pressure ramp peaks at
 * the station's own end, and the rest at the end is where the swarm pays back the
 * ground the ramp takes. Two rules came out of it and both hold here:
 *
 *   - **every station ends on an `open`**, and
 *   - **no station's last demand carries a compulsory ring.** A pressure peak
 *     says keep up; a compulsory ring says stop and hold a body still. In five
 *     stations that last demand is the second half of a couplet, which is excused
 *     twice over; in the estuary it is the widest gate in the act with a free ring
 *     on it, because by then the act has stopped asking altogether.
 *
 * That is 32 compulsory rings against the old 18, which is **fewer per minute** -
 * 1.5 against 1.9 - on an act that is twice as long and twice as expensive to
 * lose. It is the one count in this rebuild that went down.
 *
 * ## The ring grammar: plural, and in order
 *
 * This is the act where the rescue ring changes meaning. For six acts it has
 * meant *more of you*; here it means *you again* - the rings gather back the
 * droplet groups that the last three acts scattered. And it was authored exactly
 * like every other act's: one ring, on the line, behind the hole. The act's one
 * idea was in its prose and in nothing the player's hand ever did.
 *
 * So on four sections of this act a compulsory ring is no longer a ring. It is
 * **a run of three, taken in sequence** - two optional ones leading in from
 * further back and drifting across the width, and the compulsory one last, on the
 * aperture the section was already asking for. Gathering is a phrase rather than a
 * grab: the line that collects all three is one continuous sweep across the
 * course, and the line that collects only the compulsory one is a straight line
 * with nothing wrong with it. Nobody is punished for the short version.
 *
 * Four sections and not forty-eight, and the four are the ones with room. A
 * phrase 420 px long needs 420 px of clear course behind the section carrying it,
 * so a phrase only ever sits on the far side of a quiet: two of the downpour's
 * curtains, one of the canopy's and the estuary's last funnel, which are 700, 840,
 * 1230 and 1010 px behind the thing in front of them. Everything met in a burst
 * carries one wide ring instead. Where the burst and the phrase collide, the burst
 * wins.
 *
 * The sweep is 0.24 of the width and the leaders are at 300 px and 120 px, which
 * is what it takes for the three to be three things. It was 0.07 to 0.09 across 85
 * and 170 px, and at those numbers the three rings overlapped into one blob
 * narrower than a single ring is wide: a dead straight line held on the compulsory
 * x sat inside both leaders for four seconds against a 0.7 s hold, so the phrase
 * and the short version were the same line. Both leaders are scaled too, because
 * an *optional* ring asks 0.28 of the swarm for 0.7 s against a compulsory one's
 * 0.20 for 0.5 s - the free half of the act's signature idea was its hard half,
 * and above about sixty-six carriers it was not takeable at all. Measured before
 * this pass: 0 of 9 leaders merged in a full run of the act.
 *
 * **Never two compulsory rings on one section.** One asks for 28 % of the swarm
 * held inside 62 px for 0.7 s; two beside each other asks for 56 % in two places
 * at once, which is not a demand, it is a wall. The canopy's second tree had
 * exactly that pair - it was the only section in the campaign with a compulsory
 * ring in *each* channel of a splittable mass - and the right-hand one is optional
 * now. Its geometry does not move: the 273 px between the two rings was measured
 * and defended, and what was wrong was never where they were.
 *
 * The campaign's other rule about two rings on one `dy` - keep them 0.25 to 0.35
 * of the width apart, close enough that a body that has stayed wide covers both
 * and far enough that an ordinary one does not - has no instance in this act at
 * all, and that is the right answer here rather than an omission: act VI buys
 * width with the phrase instead, which is a run of three across the course and is
 * strictly the harder version of the same ask.
 *
 * Every same-`dy` pair in this file is therefore the *other* thing: a **splittable
 * mass** - column, tower, canopy - with a ring in each channel, two thirds of the
 * width apart on purpose. No body covers both; one is the demand and the other is
 * the reward for having split cleanly and come back together. `boulder` is not on
 * that list and never carries a pair. Two stones in a brook are a door with a
 * mid-stream pier in it, not a mass to split on.
 *
 * ## What can go wrong
 *
 * A light checkpoint system: this act still restarts a station rather than ending
 * a run. It is the last act that asks for anything at all - and a station is 3.1
 * to 4.1 minutes now rather than 1.1 to 2.2, so what a restart costs has roughly
 * doubled at the same time as the course got harder. That is the known risk of
 * this whole plan, it is taken knowingly, and `RESTARTS_PER_ACT` is a decision
 * for the player rather than for the author of an act.
 */

/**
 * A station's breath, and the gap it sits behind.
 *
 * The spacing used to be baked in at 900 px everywhere this was called, which
 * made every station's rest exactly every other station's rest. The rest is part
 * of the rhythm now, so it is an argument - and since the rebuild every station
 * gets two of them, one in each half.
 */
function breath(spacing: number, x: number, count: number): SectionSpec {
  // Scaled for the same reason every other optional ring in this act is: a free
  // ring costs 0.28 of the swarm held for 0.7 s, and act VI is flown at sixty to
  // a hundred and twenty carriers.
  return { kind: 'open', spacing, rings: [{ x, dy: -60, count, scale: 1.3 }] };
}

/** A compulsory ring, on the line the section already asks for. */
function must(x: number, dy: number, count: number, scale = 1.3): RingSpec {
  return { x, dy, count, required: true, scale };
}

/** Keeps a drifting run of rings inside the field the shoal can actually be in. */
function across(x: number): number {
  return Math.min(0.88, Math.max(0.12, x));
}

/**
 * A gathering run: two optional rings leading in, and the compulsory one last.
 *
 * `drift` is how far across the width the *first* ring sits from the last one, so
 * the run sweeps rather than stacks. The leaders are at 300 px and 120 px further
 * back down the course, and the sweep closes as it goes - the second leader is at
 * 0.35 of the drift rather than at half of it - because a body being gathered
 * converges, and a run of three evenly spaced points is a queue.
 *
 * Slowblue: this was a sweep in its own docstring and a column of overlapping rings in
 * its arithmetic. The leaders were at `drift` and `drift * 2` with drifts between
 * 0.07 and 0.09 of the width, which is 27 to 35 px a step against a 62 px ring
 * radius - so consecutive centres were 89 to 92 px apart with 124 to 133 px of
 * summed radius, the three rings were one overlapping blob 55 to 70 px wide, and a
 * dead straight line held on the compulsory x covered the far leader by 41 % and
 * the near one by 61 %. Both are over `CONTACT_FRACTION`, for about four seconds
 * against a 0.7 s hold. There was no phrase: the act's one new idea was in its
 * prose and in nothing the player's hand ever did, which is the exact sentence the
 * header above uses about the version before it.
 *
 * The 85/170 px offsets were defended on the grounds that act VI's tightest
 * sections are 380 px apart. No `gather()` was ever authored at a 380 or 470 px
 * section; the four that exist are at 700, 840, 1230 and 1010 px, and each of them
 * lands its far leader at least 180 px past the geometry in front of it. The
 * sites with no room to be a phrase are single rings, under the rule this file
 * states where the downpour's `pass` states it: the burst wins.
 *
 * Both leaders carry a width. An unscaled optional ring asks 0.28 of the swarm for
 * 0.7 s where the compulsory one asks 0.20 for 0.5 s, and act VI is flown at sixty
 * to a hundred and twenty carriers - above about sixty-six, 0.28 of them does not
 * fit inside 62 px at all. Measured before this change: 0 of 9 leaders merged in a
 * full act VI run.
 */
function gather(x: number, dy: number, drift: number, count = 10): RingSpec[] {
  return [
    { x: across(x + drift), dy: dy + 300, count: 4, scale: 1.15 },
    { x: across(x + drift * 0.35), dy: dy + 120, count: 4, scale: 1.15 },
    must(x, dy, count, 1.3),
  ];
}

/**
 * The breath, as a period. Named here rather than passed, because a section that
 * pulsed on some other clock would be a second rhythm in a game that has one.
 *
 * A door authored **shut**: `gap` is the narrowest it ever gets, so the corridor
 * sweep - which builds a course and never advances a clock - is already looking
 * at the hardest phase. The demand is to arrive lined up on the open half of the
 * cycle, and in an act that falls the way to shift your arrival is to stop
 * hurrying, which is what `Medium.drag` has just started charging for anyway.
 *
 * Only ever on a shape with **one** door. It pushes its circles away from the
 * widest space between them, which is the hole when there is exactly one hole and
 * the middle of the field when there are two - so a multi-door shape would open
 * its outer doors and pinch its middle one shut on the one phase nothing checks.
 * `tests/motion.test.ts` holds that line; act VI has no multi-door shape at all,
 * but the three splittable masses in its alphabet - column, tower, canopy - are
 * two-channel and are given `WALK` instead for exactly this reason.
 */
const PULSE = { kind: 'aperture', reach: 0.055 } as const;

/**
 * A mass that walks: the game's oldest sentence made literal.
 *
 * The current you laid three seconds ago is not the current you are on - and now
 * the gap is not where it was either. Its authored position is the middle of its
 * travel and `Section.envelope` carries the union of everywhere it ever is, so
 * the sweep's guarantee is the strong one: there is a line past it whenever you
 * arrive, not only when you arrive on the beat.
 */
const WALK = { kind: 'drift', reach: 0.055 } as const;

/**
 * Two masses on one clock and opposite halves of it: the scissor.
 *
 * A single walking mass asks "aim where the gap will be". A pair of them four or
 * five hundred pixels apart, one going out while the other comes back, asks
 * something else: **there is no phase at which both are where you last saw them.**
 * A line laid for the first is always the wrong line for the second, and the only
 * way through is to lay the line the pair will have made by the time you get there.
 *
 * An authored phase is a sharp tool - it is also a phase that *repeats*, where the
 * default is keyed to where a section sits on the course so no two of them are
 * ever in step. So the rule is narrow and `tests/motion.test.ts` checks it: a
 * phase is only ever written down as one half of a pair in the same station.
 */
const WALK_OUT = { kind: 'drift', reach: 0.055, phase: 0 } as const;
const WALK_BACK = { kind: 'drift', reach: 0.055, phase: 0.5 } as const;

/**
 * Two breathing gaps, and the second is shut while the first is open.
 *
 * The couplet's demand is spatial - lay the line for the second gate before
 * entering the first - and this is the same sentence in time. Taking the first
 * one the moment it opens arrives at the second at its narrowest; waiting a beat
 * costs ground against the drift. It is the only place in the campaign where
 * being early is a mistake, and act VI is where it belongs a second time: rain
 * genuinely does come and go on a period, and this is the only pair of objects in
 * the game that is two of the same thing.
 */
const PULSE_OPEN = { kind: 'aperture', reach: 0.055, phase: 0.25 } as const;
const PULSE_SHUT = { kind: 'aperture', reach: 0.055, phase: 0.75 } as const;

export const RAIN_LEVELS: Level[] = [
  {
    key: 'cirrus',
    name: 'The Cirrus',
    depthMeters: -11000,
    subtitle: 'Ice, one more time',
    zone: ZONE_RAIN,
    medium: 'cloud',
    decor: 'void',
    pace: 0.46,
    roughness: 0.5,
    swirl: 0,
    /*
     * Eleven kilometres, falling. The swarm passes back through the altitude the
     * flock handed over at, and what is here is what was here then: ice being
     * dragged. So this station is authored in act III's own crystal alphabet, and
     * it is the last ice in the campaign.
     */
    /*
     * 820, 1180, 470, 640, 820, 400, 780, 440, 700, 430, 600 - 7280 px, 3.9
     * minutes, and the act's one gentle opening: a long arrival, a long quiet, and
     * only then the pair. Everything below this station comes in bursts, and a
     * station that opened in bursts would have nothing to be a burst against.
     *
     * Both of the act's moving demands are taught here, in its slowest water, one
     * after the other and with nothing else in the frame: the breathing door at
     * §5 and the first walking mass in the campaign's second half at §6. Ice being
     * dragged is what cirrus *is* - the one thing everybody knows about this cloud
     * is that it is the shape of a wind - so the act's new axis arrives as a fact
     * about the material rather than as a mechanic.
     */
    sections: [
      {
        kind: 'open',
        spacing: 820,
        rings: [must(0.5, 0, 12, 1.5)],
      },
      {
        kind: 'veil',
        spacing: 1180,
        centre: 0.42,
        gap: 0.54,
        rings: [{ x: 0.42, dy: -240, count: 11, scale: 1.3 }],
      },
      {
        // 470 px behind the veil: the act's first burst, and the last ice in the
        // campaign arriving with no room to think between its two halves.
        kind: 'column',
        spacing: 470,
        centre: 0.56,
        radius: 0.09,
        rings: [must(0.18, -140, 12), { x: 0.84, dy: -140, count: 12, scale: 1.3 }],
      },
      // The mid-station breath, and it is an addition rather than the landing
      // moved - see the header. Everything before it is the act as it shipped;
      // everything after it is what this act did not used to be able to say.
      breath(640, 0.32, 11),
      {
        /*
         * The first thing in this act that moves, and it is a door.
         *
         * Here rather than at the peak on purpose: the slowest station in the act,
         * a wide gap, nothing else in the frame, and a compulsory ring 235 px in
         * front of it so the line is laid before the door is read. A player who
         * never notices that it is breathing still gets through - it is authored
         * shut and 0.5 of the width is passable at the closed phase - and a player
         * who does notice has learned the act's second question without being told
         * it.
         *
         * The ring is *in front* of this one where every other veil in the station
         * carries its ring past the line. That is the difference between the two
         * jobs a ring does here: behind a still door it pays for having taken the
         * door, and in front of a moving one it is where you commit from.
         */
        kind: 'veil',
        spacing: 820,
        centre: 0.34,
        gap: 0.5,
        motion: PULSE,
        rings: [must(0.34, 235, 12)],
      },
      {
        /*
         * ...and 400 px later, the first mass in the campaign that walks.
         *
         * A column sliding 0.055 of the width either way, with a channel on each
         * side of it. The compulsory ring is in the left channel and the column
         * walks into it and out of it again, so the demand is legible: the ring
         * never moves, and what moves is how much room there is to get to it.
         *
         * It is met inside a burst rather than in the open, which is the whole
         * reason the breathing door in front of it is authored at 0.5 - the two
         * new ideas are back to back and only one of them is allowed to be tight.
         */
        kind: 'column',
        spacing: 400,
        centre: 0.6,
        radius: 0.09,
        motion: WALK,
        rings: [must(0.2, -140, 12), { x: 0.86, dy: -140, count: 12, scale: 1.3 }],
      },
      {
        kind: 'veil',
        spacing: 780,
        centre: 0.66,
        gap: 0.52,
        rings: [must(0.66, -235, 12)],
      },
      {
        kind: 'column',
        spacing: 440,
        centre: 0.42,
        radius: 0.095,
        rings: [
          { x: 0.16, dy: -140, count: 12, scale: 1.3 },
          { x: 0.82, dy: -140, count: 12, scale: 1.3 },
        ],
      },
      {
        /*
         * The station's couplet, and the first one in the act.
         *
         * 430 px at pace 0.46 is about fourteen seconds from this door to the next,
         * and the two gaps are 0.34 of the width apart. Fourteen seconds is not the
         * problem; the problem is that a current laid *at* this door is still
         * pushing when the next one arrives, so the only line that takes both is
         * one that was already leaning right on the way through here.
         *
         * Neither half carries a compulsory ring, and the two are excused for
         * different reasons. The first is not asked for one because building the
         * next line and holding a body inside a ring are two demands on one
         * section at the tightest spacing the station has. The second is not asked
         * because a couplet is where a station ends, and a station does not end on
         * a gate.
         */
        kind: 'veil',
        spacing: 700,
        centre: 0.3,
        gap: 0.5,
        rings: [{ x: 0.3, dy: -235, count: 11, scale: 1.3 }],
      },
      {
        kind: 'veil',
        spacing: 430,
        centre: 0.64,
        gap: 0.52,
        rings: [{ x: 0.64, dy: -230, count: 12, scale: 1.3 }],
      },
      breath(600, 0.5, 11),
    ],
  },
  {
    key: 'underanvil',
    name: 'Under the Anvil',
    depthMeters: -9000,
    subtitle: 'The same cloud, from below',
    zone: ZONE_RAIN + 1,
    medium: 'cloud',
    decor: 'void',
    pace: 0.52,
    roughness: 0.7,
    swirl: 0,
    /*
     * The quietest and best idea in the second half of the campaign: this is the
     * same anvil act II climbed over, seen from underneath. The player flew across
     * the top of this cloud forty minutes ago and has been to space since.
     *
     * It is authored in act II's cloud alphabet for exactly that reason - the same
     * banks, the same towers, the same pass - and nothing anywhere marks the
     * moment. If the player notices, they notice; the campaign does not tell them.
     */
    /*
     * 470, 480, 1250, 1170, 900, 430, 480, 1150, 440, 700 - 7470 px, 3.5 minutes.
     * The first three are act II's kinds and act II's rings, digit for digit, and
     * they stay that way: this is the recognition and nothing may mark it. Only
     * the spacing was ever act VI's, because the rhythm is the weather rather than
     * the cloud, and the weather down here is not what it was on the way up.
     *
     * What the second half adds is also act II's alphabet - there is no fourth
     * shape in this station and there is not going to be - but it is doing
     * something act II's cloud never did: **it moves.** That is the honest
     * difference between the two visits rather than a decoration on top of one.
     * From above, an anvil is a floor. From inside the updraught that is building
     * it, the towers are going up and sideways at once, and the gap between two of
     * them is a thing with a period. The recognition is still not remarked on; the
     * cloud simply behaves like what it is, which it could not do while the player
     * was standing on its lid.
     */
    sections: [
      { kind: 'bank', spacing: 470, centre: 0.36, gap: 0.5, rings: [must(0.36, 210, 12)] },
      {
        kind: 'tower',
        spacing: 480,
        centre: 0.54,
        radius: 0.12,
        rings: [must(0.16, -150, 12), { x: 0.85, dy: -150, count: 12, scale: 1.3 }],
      },
      {
        // The burst is bank-into-tower, and the quiet is behind the tower rather
        // than in front of it. Which way round matters here and it is arithmetic
        // rather than taste: the tower's compulsory ring is in its *left* channel
        // at 0.16 and the pass's is at 0.6, so the two are 172 px apart across the
        // field. At the 480 px this gap was first authored at, only 75 px of course
        // separates the two rings once their own offsets are counted, and no body
        // crosses 172 px of width in 75 px of course. The corridor sweep's ring
        // chain says so, which is the entire reason it exists.
        kind: 'pass',
        spacing: 1250,
        centre: 0.6,
        gap: 0.4,
        mouth: 0.52,
        depth: 240,
        rings: [must(0.6, 255, 13)],
      },
      breath(1170, 0.7, 11),
      {
        // A cumulus deck with a hole in it that opens and shuts. Act II crossed
        // three of these and every one of them stood still, because from above a
        // deck is a floor with a door in it. From below it is the underside of a
        // thing that is being built, and the hole in it is where the air is
        // going - so the same silhouette breathing is the same cloud told the
        // truth about rather than a new object.
        kind: 'bank',
        spacing: 900,
        centre: 0.62,
        gap: 0.48,
        motion: PULSE,
        rings: [must(0.62, 205, 12)],
      },
      {
        /*
         * The scissor's front half, 430 px behind the deck.
         *
         * Two towers on the same eleven-second clock and opposite halves of it: by
         * the time the first has walked right the second has walked left, and the
         * lane the pair leaves is never straight. It is here rather than in the
         * canopy because this is the station where a walking mass is *explicable* -
         * cumulus congestus is a column of air going up, and the one thing a
         * building tower does is lean.
         *
         * A ring in each channel, the compulsory one on the left. They are 0.66 of
         * the width apart, which no body covers: on a splittable mass that is the
         * point of a pair rather than a mistake in one - split, take both, come
         * back together.
         */
        kind: 'tower',
        spacing: 430,
        centre: 0.46,
        radius: 0.11,
        motion: WALK_OUT,
        rings: [must(0.16, -150, 12), { x: 0.82, dy: -150, count: 12, scale: 1.3 }],
      },
      {
        // ...and the back half, 480 px later and walking the other way. No
        // compulsory ring: holding a body still inside one while the room in front
        // of it is walking is two demands on one section, and the pair is already
        // the demand.
        kind: 'tower',
        spacing: 480,
        centre: 0.56,
        radius: 0.1,
        motion: WALK_BACK,
        rings: [{ x: 0.2, dy: -145, count: 12, scale: 1.3 }],
      },
      {
        kind: 'pass',
        spacing: 1150,
        centre: 0.4,
        gap: 0.42,
        mouth: 0.5,
        depth: 240,
        rings: [must(0.4, 250, 13)],
      },
      {
        // The station's couplet: the pass's slot at 0.4 and this deck's hole at
        // 0.72, 440 px apart. Neither half carries a compulsory ring - the second
        // is the station's last demand, and a station does not end on a gate.
        kind: 'bank',
        spacing: 440,
        centre: 0.72,
        gap: 0.46,
        rings: [{ x: 0.72, dy: 200, count: 12, scale: 1.3 }],
      },
      breath(700, 0.5, 11),
    ],
  },
  {
    key: 'downpour',
    name: 'The Downpour',
    depthMeters: -2000,
    subtitle: 'Everything is going down',
    zone: ZONE_RAIN + 2,
    medium: 'cloud',
    decor: 'void',
    // The act's fastest station: this is the part of the journey that is actually
    // *falling*. Not the campaign's - act V's Plasma station is faster and says so in its
    // own file, and for a while both files claimed the superlative at the identical
    // pace 0.62 and the identical roughness 0.85.
    pace: 0.6,
    roughness: 0.85,
    swirl: 0,
    /*
     * Out of the bottom of the cloud, and gravity takes over from wind. The
     * curtains here run *with* the course rather than across it, which is the
     * first time in the game the obstacles point where the player is going.
     */
    /*
     * 430, 700, 430, 840, 880, 880, 440, 840, 830, 460, 760 - 7490 px, 3.1
     * minutes, nine obstacles, and 2.9 a minute: the densest station in the act by
     * half again, and the only one anywhere in the campaign's second half that
     * hurries. Nothing in it is further than 880 px from the thing before it,
     * where every other station here has a crossing of 1180 or more - the rain
     * does not come in squalls with sky between them, it just comes. That is why
     * it is also the shortest station in the act at three minutes: a station with
     * no long quiet in it cannot be a long station as well.
     *
     * It is where the gathering run starts. The three stations above this one were
     * scattering; from here the act is putting the swarm back together, and the
     * rings say so before any of the prose does.
     *
     * And it is where the two curtains breathe against each other. See §5 and §6:
     * the counter-phase pair is the act's own idea in the act's own material,
     * because two rain curtains are the only pair of objects in this game that is
     * genuinely two of the same thing.
     */
    sections: [
      {
        kind: 'downpour',
        spacing: 430,
        centre: 0.5,
        // 0.50, 0.46 and 0.48 against the 0.46/0.42/0.44 these were authored at.
        // `rainCurtain` used to leak - a quarter of its columns had no bead at the
        // section line and neighbouring shafts did not touch - so the real opening
        // was wider than the number, everywhere, by an amount nobody chose. Closing
        // the holes without widening the gap would have been a silent difficulty
        // rise of exactly the size of the bug.
        gap: 0.5,
        // One wide ring, not a run: 430 px behind the last thing there is no
        // course to gather *along*, and a phrase needs somewhere to be a phrase.
        rings: [must(0.5, 215, 13, 1.3)],
      },
      {
        kind: 'downpour',
        spacing: 700,
        centre: 0.3,
        gap: 0.46,
        rings: gather(0.3, 220, 0.24),
      },
      {
        // A single ring, not a run, and the reason is the rhythm rather than the
        // shape: at 430 px behind the downpour above it there is no course left to
        // gather *along*. A phrase needs somewhere to be a phrase. This is the
        // rule wherever the two collide - the burst wins, and the station's other
        // sections carry the gathering.
        kind: 'pass',
        spacing: 430,
        centre: 0.44,
        gap: 0.38,
        mouth: 0.52,
        depth: 245,
        rings: [must(0.44, 260, 14)],
      },
      breath(840, 0.56, 12),
      {
        /*
         * The counter-phase pair, and the act's hardest single idea.
         *
         * Two rain curtains 880 px apart - about twenty-two seconds at this pace,
         * or two breaths - authored half a cycle out of step, so **the second one
         * is shut while the first one is open**. Taking this one the moment it
         * opens puts the swarm at the next one at its narrowest; waiting one beat
         * costs ground against the drift and arrives on the open half of both.
         *
         * It is the couplet's demand moved from space into time, and it is the one
         * place in the campaign where being early is a mistake. The cost of waiting
         * is real now in a way it was not a week ago: `Medium.drag` has a terminal
         * in `cloud`, so the ground given up here cannot simply be taken back by
         * pushing - the air charges for that, quadratically, from the front.
         *
         * 880 px is the longest gap in the station and both halves of the pair sit
         * on it. That is the trade this station makes: it is the one that hurries,
         * so the one thing in it that needs room is given all the room there is.
         */
        kind: 'downpour',
        spacing: 880,
        centre: 0.62,
        gap: 0.48,
        motion: PULSE_OPEN,
        rings: [must(0.62, 210, 13)],
      },
      {
        kind: 'downpour',
        spacing: 880,
        centre: 0.32,
        gap: 0.46,
        motion: PULSE_SHUT,
        rings: [{ x: 0.32, dy: 205, count: 13, scale: 1.3 }],
      },
      {
        kind: 'pass',
        spacing: 440,
        centre: 0.56,
        gap: 0.4,
        mouth: 0.52,
        depth: 240,
        rings: [must(0.56, 255, 13)],
      },
      {
        // The station's second phrase, and it has 325 px of clear course behind
        // its far leader once the pass in front of it is counted. That number is
        // the whole reason a gathering run is a rare thing here rather than the
        // default: it is 420 px long, and most of this station is 440.
        kind: 'downpour',
        spacing: 840,
        centre: 0.36,
        gap: 0.48,
        rings: gather(0.36, 215, 0.24),
      },
      {
        // The couplet: this curtain's door at 0.3 and the pass's slot at 0.62,
        // 460 px apart. Neither half carries a compulsory ring.
        kind: 'downpour',
        spacing: 830,
        centre: 0.3,
        gap: 0.48,
        rings: [{ x: 0.3, dy: 210, count: 13, scale: 1.3 }],
      },
      {
        kind: 'pass',
        spacing: 460,
        centre: 0.62,
        gap: 0.42,
        mouth: 0.5,
        depth: 240,
        rings: [{ x: 0.62, dy: 250, count: 13, scale: 1.3 }],
      },
      breath(760, 0.5, 12),
    ],
  },
  {
    key: 'canopy',
    name: 'The Canopy',
    depthMeters: -100,
    subtitle: 'The first green',
    zone: ZONE_RAIN + 3,
    medium: 'cloud',
    decor: 'canopy',
    pace: 0.54,
    roughness: 0.6,
    swirl: 0,
    /*
     * The first green in the game and the first solid obstacle since act I - and
     * the first living thing the swarm has been near since it left the sea.
     *
     * A tree is met crown-first on a descending course, so the wide part arrives
     * before the narrow one and the way round *opens* as the swarm falls past it.
     * Every other splittable mass in the campaign does the opposite.
     */
    /*
     * 480, 1230, 470, 900, 950, 460, 520, 940, 460, 780 - 7190 px, 3.3 minutes.
     * The station keeps its shape exactly: burst, a long quiet, burst, and it
     * opens and closes on a tree.
     *
     * The second half is the act's second scissor and it means something different
     * from the first one. Under the anvil two towers walk because the air is
     * building them. Here two trees walk because it is **raining on them** - the
     * one place in this game where a moving obstacle is a thing the player has
     * actually stood underneath. Nothing else in the campaign gets to be that
     * ordinary.
     */
    sections: [
      {
        kind: 'canopy',
        spacing: 480,
        centre: 0.5,
        radius: 0.11,
        rings: [must(0.17, -150, 13), { x: 0.84, dy: -150, count: 13, scale: 1.3 }],
      },
      {
        kind: 'downpour',
        spacing: 1230,
        centre: 0.36,
        gap: 0.48,
        rings: gather(0.36, 215, 0.24),
      },
      {
        /*
         * Centred, because `canopyTree` jitters its crown from a hash of x and at
         * 0.62 the two channels measured 213 px and 93 px - the only channel under
         * 113 px on any two-ring mass in the campaign, at the one section that
         * *demands* the split. Swept: 0.48 gives 143/141, which is act I's own
         * light-line grammar. The rings and the 273 px between them do not move.
         *
         * Slowblue: what does move is that the right-hand one is no longer
         * compulsory. This was the only section in the campaign with a compulsory
         * ring in each channel of a splittable mass, and a compulsory ring asks for
         * 28 % of the swarm inside 62 px for 0.7 s - so a pair of them asked for
         * 56 % in two places at once, which is not a demand, it is a wall. The
         * split is still the section's whole subject and the pay for taking both
         * halves is unchanged; what is gone is the version where taking only one
         * of them lost the station.
         */
        kind: 'canopy',
        spacing: 470,
        centre: 0.48,
        radius: 0.115,
        rings: [must(0.16, -155, 14), { x: 0.86, dy: -155, count: 14, scale: 1.3 }],
      },
      breath(900, 0.5, 12),
      {
        // Rain through a hole in the leaves, opening and closing. It is the act's
        // own shape carrying the act's own new idea, and it is here rather than in
        // the downpour station because that one is already carrying the pair - a
        // breathing curtain met alone reads as weather, and two of them met
        // together read as a clock.
        kind: 'downpour',
        spacing: 950,
        centre: 0.64,
        gap: 0.48,
        motion: PULSE,
        rings: [must(0.64, 210, 13)],
      },
      {
        // The canopy's scissor, front half. A tree walking is the only moving
        // obstacle in this game whose motion needs no explaining at all.
        kind: 'canopy',
        spacing: 460,
        centre: 0.56,
        radius: 0.095,
        motion: WALK_OUT,
        rings: [must(0.18, -150, 13), { x: 0.86, dy: -150, count: 13, scale: 1.3 }],
      },
      {
        // ...and the back half, 520 px later. No compulsory ring: the pair is the
        // demand, and the free ring is in the channel the second tree is walking
        // *out of* rather than into.
        kind: 'canopy',
        spacing: 520,
        centre: 0.44,
        radius: 0.09,
        motion: WALK_BACK,
        rings: [{ x: 0.82, dy: -145, count: 13, scale: 1.3 }],
      },
      {
        // The station's couplet, and both halves of it are rain: two curtains 460
        // px apart with their doors 0.34 of the width from each other. Neither
        // carries a compulsory ring, and the second one is where the station stops
        // asking.
        kind: 'downpour',
        spacing: 940,
        centre: 0.3,
        gap: 0.5,
        rings: [{ x: 0.3, dy: 215, count: 13, scale: 1.3 }],
      },
      {
        kind: 'downpour',
        spacing: 460,
        centre: 0.64,
        gap: 0.48,
        rings: [{ x: 0.64, dy: 210, count: 13, scale: 1.3 }],
      },
      breath(780, 0.5, 12),
    ],
  },
  {
    key: 'brook',
    name: 'The Mountain Brook',
    depthMeters: -400,
    subtitle: 'Water that carries you',
    zone: ZONE_RAIN + 4,
    // Running water. It grips harder than the sea and forgets faster, because the
    // whole medium is already going somewhere - what the player adds is a nudge on
    // top of something much larger than the nudge.
    medium: 'stream',
    decor: 'stream',
    // Under the downpour's, so the act keeps one fastest station.
    pace: 0.56,
    roughness: 0.75,
    swirl: 0.7,
    /*
     * Four hundred metres, which is *above* the canopy, and that is not an error:
     * a mountain stream starts above the forest it runs down through. The
     * campaign's continuity is the journey rather than the altitude.
     *
     * This is the station where the separate drops start visibly becoming one
     * thing, and mechanically it is where growth starts to be felt - `stream` has
     * the highest `inertiaPerAgent` in the game, so a group that has gathered
     * everything is genuinely heavier to steer than one that has not.
     */
    /*
     * 560, 1180, 380, 900, 980, 460, 1020, 900, 450, 800 - 7630 px, 3.3 minutes.
     *
     * **380 px between the vortex and the narrows is still the tightest gap in the
     * act**, and it is still placed exactly there on purpose: `stream` has the
     * highest `inertiaPerAgent` in the campaign, so a group that has taken every
     * gathering run since the downpour is genuinely heavier than one that has not,
     * and 380 px is not enough course to correct a heavy body twice. The obstacle
     * in this station is having gathered.
     *
     * Nothing punishes the player for it and nothing says it out loud. A small
     * group threads the pair; a large one arrives at the second gap still leaning
     * from the first, loses a few at the bank, and is still a large group.
     *
     * The gap the design memo actually complained about is 0.36, and it is that
     * narrows, and it does not move. Precision is not this act's lever and never
     * was - the swarm's own lateral reach is a hard floor under gap width and
     * squeezing toward it buys frustration rather than difficulty. What the second
     * half of the station adds instead is a stone that will not stay put and a
     * channel that will not stay open.
     */
    sections: [
      {
        kind: 'boulder',
        spacing: 560,
        centre: 0.4,
        gap: 0.42,
        radius: 0.11,
        // 560 px behind the station line and 380 in front of the narrows: the
        // tightest run in the act has no room for a phrase either. The burst wins.
        rings: [must(0.4, 240, 13, 1.3)],
      },
      {
        kind: 'vortex',
        spacing: 1180,
        centre: 0.56,
        gap: 0.44,
        radius: 0.3,
        spin: -1,
        strength: 96,
        rings: [must(0.56, 245, 14)],
      },
      {
        // A channel that is already narrow when you meet it, which is this
        // station's written point: a heavy gathered body cannot correct twice in
        // 380 px, so the second correction must not be the one that finds the slot.
        kind: 'narrows',
        spacing: 380,
        centre: 0.46,
        gap: 0.36,
        mouth: 0.38,
        depth: 245,
        rings: [must(0.46, 265, 15)],
      },
      breath(900, 0.34, 13),
      {
        /*
         * A stone that will not stay put, and the demand the design memo named
         * this act's material for.
         *
         * It is one mass rather than a scissor, because the pair has already been
         * asked for twice by here and because a brook is not a machine: what a
         * boulder in running water actually does is get shouldered downstream by
         * it. The compulsory ring is 240 px in front, on the channel's *home*
         * centre - so the line is laid at where the door was, and the door has
         * moved by the time the swarm arrives.
         *
         * The banks travel with it and that is deliberate rather than tolerated. A
         * brook has sides and they are the one place in this act where the course
         * really does narrow; a walking stone that left its banks behind would be a
         * rock in a corridor rather than water going somewhere. At 0.055 of the
         * width neither edge of the field is ever uncovered - the runs are
         * continuous from off-field inward, so the whole bank slides rather than
         * opening a sliver at the frame.
         */
        kind: 'boulder',
        spacing: 980,
        centre: 0.56,
        gap: 0.44,
        radius: 0.1,
        motion: WALK,
        rings: [must(0.56, 240, 13, 1.3)],
      },
      {
        // 460 px behind the walking stone, and the only second vortex in the act.
        // A standing current is the one hazard here the player cannot see the edge
        // of, so it is spent where the section in front of it has just put the
        // swarm somewhere it did not choose.
        kind: 'vortex',
        spacing: 460,
        centre: 0.34,
        gap: 0.46,
        radius: 0.26,
        spin: 1,
        strength: 90,
        rings: [{ x: 0.34, dy: 240, count: 13, scale: 1.3 }],
      },
      {
        // The act's one breathing *funnel*. A `narrows` is converging walls with a
        // slot at the bottom, and the slot is the widest space between its
        // circles, so the whole funnel opens and closes about its own throat - the
        // one shape in the campaign where an aperture moves a wall the swarm is
        // already inside rather than one it is approaching.
        //
        // 0.4 shut, which is wider than the 0.36 in the station's first half. The
        // difficulty here is the timing and not the width, and authoring it
        // narrower would have been the exact mistake this rebuild is written
        // against.
        kind: 'narrows',
        spacing: 1020,
        centre: 0.6,
        gap: 0.4,
        mouth: 0.46,
        depth: 240,
        motion: PULSE,
        rings: [must(0.6, 255, 14)],
      },
      {
        // The station's couplet: the stones' channel at 0.34 and the last funnel's
        // slot at 0.66, 450 px apart. Neither half carries a compulsory ring.
        kind: 'boulder',
        spacing: 900,
        centre: 0.34,
        gap: 0.46,
        radius: 0.105,
        rings: [{ x: 0.34, dy: 235, count: 13, scale: 1.3 }],
      },
      {
        kind: 'narrows',
        spacing: 450,
        centre: 0.66,
        gap: 0.42,
        mouth: 0.5,
        depth: 235,
        rings: [{ x: 0.66, dy: 250, count: 13, scale: 1.3 }],
      },
      breath(800, 0.5, 12),
    ],
  },
  {
    key: 'estuary',
    name: 'The Estuary',
    depthMeters: 0,
    subtitle: 'Where the river arrives',
    zone: ZONE_RAIN + 5,
    medium: 'stream',
    decor: 'kelp',
    // Running itself down into the sea. The last station of the last act that
    // asks for anything.
    pace: 0.44,
    roughness: 0.5,
    swirl: 0,
    /*
     * Where the fresh water meets the salt. The separate drops are one flowing
     * body now, the banks open out, and the last thing act VI does is hand over:
     * the gold reappears as small living forms - plankton and larvae - and act VII
     * begins with something alive in it for the first time since the surface.
     *
     * Authored wide and easy on purpose. The difficulty peak of this campaign was
     * four acts ago.
     */
    /*
     * 440, 500, 570, 650, 750, 870, 1010, 1180, 1400 - 7370 px, 4.1 minutes, and
     * the only station in the campaign whose gaps do nothing but get longer. Every
     * other station in this act alternates; this one has stopped alternating,
     * which is what an estuary is. Nine numbers, each larger than the one before
     * it, ending on the longest quiet anywhere in act VI.
     *
     * It is the longest station here and the thinnest - seven obstacles across
     * four minutes, 1.7 a minute against the downpour's 2.9 - and both of those
     * are the same decision. Length in the *release* station buys the release
     * rather than more pressure. The act's peak is three stations back and it
     * stays there.
     *
     * There is one arrival left in it: 440 px is the tightest thing in the
     * station and it is its first gap, so the estuary is entered on a burst and
     * then never asked for one again.
     */
    sections: [
      {
        kind: 'boulder',
        spacing: 440,
        centre: 0.5,
        gap: 0.48,
        radius: 0.09,
        // The estuary's phrase is on its narrows, where the station has finally
        // opened out enough to carry one. This one is a ring.
        rings: [must(0.5, 235, 13, 1.3)],
      },
      {
        kind: 'gate',
        spacing: 500,
        centre: 0.36,
        gap: 0.52,
        rings: [must(0.36, 215, 13)],
      },
      {
        kind: 'narrows',
        spacing: 570,
        centre: 0.58,
        gap: 0.5,
        mouth: 0.5,
        depth: 230,
        rings: [{ x: 0.58, dy: 250, count: 13, scale: 1.3 }],
      },
      breath(650, 0.4, 13),
      {
        // The last walking mass in the campaign, and the gentlest: 0.045 of the
        // width rather than 0.055, on the widest channel any of them has. By here
        // the demand can be stated without being asked - the world does not stop
        // being a place when it stops being a question.
        kind: 'boulder',
        spacing: 750,
        centre: 0.42,
        gap: 0.46,
        radius: 0.09,
        motion: { kind: 'drift', reach: 0.045 },
        rings: [must(0.42, 235, 13, 1.3)],
      },
      {
        // The last breathing gap in the act, and the widest: 0.54 shut, at 870 px
        // of run-up, in water that has stopped hurrying. It is the same object the
        // cirrus taught seventeen minutes ago, met again with everything else gone
        // quiet - the one place the player can actually *watch* one of these work.
        kind: 'gate',
        spacing: 870,
        centre: 0.62,
        gap: 0.54,
        motion: PULSE,
        rings: [must(0.62, 205, 14)],
      },
      {
        // 0.50 rather than the 0.44 this funnel was first authored at, because at
        // 0.44 it carried the act's second-tightest real slot at 134 px - in the
        // station whose whole subject is opening out. The number stayed wrong for
        // as long as it did because a `narrows` reads as tight whatever its gap is,
        // which is the argument for measuring rather than looking.
        //
        // The act's last gathering run is here, on the last funnel, sweeping right
        // to left where the other three sweep left to right: the body is being
        // gathered from the bank it has been running along. 455 px of clear course
        // sits behind its far leader, which is more than any of the other three
        // gets.
        kind: 'narrows',
        spacing: 1010,
        centre: 0.46,
        gap: 0.5,
        mouth: 0.5,
        depth: 230,
        rings: gather(0.46, 255, -0.24),
      },
      {
        // The last demand in act VI, and it asks for nothing: an optional ring on
        // the widest gate in the act. A station does not end on a gate, and this
        // is the last station that could have.
        kind: 'gate',
        spacing: 1180,
        centre: 0.54,
        gap: 0.56,
        rings: [{ x: 0.54, dy: 200, count: 15, scale: 1.4 }],
      },
      // The last section of act VI. Open water, and then the sea.
      { kind: 'open', spacing: 1400, rings: [{ x: 0.5, dy: -100, count: 14, scale: 1.3 }] },
    ],
  },
];

/**
 * Act VI: six stations, the top of the weather to the sea, falling.
 *
 * The last act with a difficulty in it. Its failure policy is still a station
 * restart - the design's "light checkpoint system" - and act VII takes even that
 * away halfway through.
 */
export const ACT_RAIN: Act = makeAct('rain', RAIN_LEVELS, {
  direction: 1,
  carrier: 'droplets',
});
