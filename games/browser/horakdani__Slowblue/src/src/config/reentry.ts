import { makeAct, type Act, type Level, type RingSpec, type SectionSpec } from './levels';
import { ZONE_REENTRY } from './zones';

/**
 * Slowblue: act V - the fallback.
 *
 * ## The first act that goes down
 *
 * The campaign turns over at the Overview and this is the other side of it. Everything
 * about the course runs backwards from here - `direction` is +1, the camera holds
 * the swarm a third of the way down the frame instead of two thirds, and every
 * authored `dy` still means "met earlier", because `World.u()` and
 * `ObstacleSystem.back()` carry the sign so the level files do not have to. This
 * file is written in exactly the same grammar as act I's.
 *
 * ## The act that is a transformation
 *
 * Act V is the only one in the campaign with no alphabet of its own, and that is
 * the design rather than a shortcut. It **starts in vacuum and ends in cloud**:
 * the first station is still orbit - debris, standing gravity, arcs - and the last
 * is already weather, with the same banks and wisps act II was flown through. In
 * between are the three shapes that belong to neither, for the part where the air
 * arrives at eight kilometres a second and sets fire to what the player is
 * carrying. An act about becoming something else cannot be authored out of one
 * vocabulary without lying about what it is.
 *
 * The medium does the same thing on the same schedule. Every station names where
 * it starts and where it ends (`Level.mediumTo`), and `World.medium` blends the
 * two across it - so `vacuum` runs 1 -> 0.34 -> 0 over about four minutes of play,
 * and the input stops being gravity and becomes wind **with no frame on which it
 * happened**. There is no switch, no prompt and no mode. The player's hand simply
 * starts getting answered faster.
 *
 * ## This act is the pilot for the campaign's length, and it was measured first
 *
 * The whole circuit ran 72 minutes and had no difficulty arc: the narrowest gap
 * in the game sits at 0.22-0.28 in every act that has gaps, act VI's is *wider*
 * than the trench floor's, and all six hunters in the campaign are in acts I and
 * II. The thing that was actually wrong was not the hour, it was the
 * distribution - acts I and II ask something every seventeen seconds and act IV
 * asks every fifty-five. See [docs/DESIGN-LENGTH.md](../../docs/DESIGN-LENGTH.md),
 * which is the measurement, the decision and the arithmetic.
 *
 * Act V is where the answer is being tried, because it is mid-density, it is
 * behind the paywall so a bad experiment does not damage the demo, and it already
 * borrows from both neighbouring alphabets, so a new demand can be tried in more
 * than one material inside one act.
 *
 * **The baseline was taken before a line of this was edited** - `npm run sweep`,
 * 2026-08-14, on the 24-section act: `careful` finished 11/11 in 423 s with 0.73
 * restarts, and `flick` 2/11, which is the panic-flicker bot rather than the act.
 *
 * The first pass took it to 57 sections and 20.8 minutes, and measured 0.338
 * restarts a section on `tools/length.sweep.ts` - eight times the old act V and
 * three and a half times *easier* than act I, which is the band a rebuilt act is
 * supposed to land in. Getting there took one failed build and four measurements;
 * `docs/DESIGN-LENGTH.md` §7 has all of them, including the one that says the
 * plan for this act's shape was wrong.
 *
 * ### And then it was played, and the verdict was that it had not landed
 *
 * The pilot was flown end to end on a phone and the report was two sentences:
 * *it is not harder, and it does not take longer.* Both are defensible against
 * the numbers and that is what makes them worth writing down.
 *
 *   - **The circuit barely moved.** Act V is a seventh of the campaign, so
 *     doubling it took the authored hour to 82 minutes - and a competent hand
 *     runs about three quarters of the authored time, because `World.pressure`
 *     adds up to 55 % to the drift across a station. Fifty-six real minutes
 *     became sixty-two. Nobody feels six minutes in an hour.
 *   - **The difficulty went into *length*, not into demand.** Every new section
 *     in the first pass was another instance of a shape the act already had. More
 *     shocks is more act V; it is not a harder act V.
 *
 * So this file has had a second pass, and the second pass is about what a section
 * *asks* rather than how many of them there are. Four things are new:
 *
 *   1. **The ember**, and it is the one the plan named and the first pass did not
 *      build - a threat, in an act that had none, in the half of the campaign that
 *      had none. Five of them. See the `ember` sections below.
 *   2. **The scissor**: two walking masses on opposite halves of one clock, so the
 *      lane between them is never straight. Two of them.
 *   3. **The counter-phase pair**: two breathing gaps where the second is shut
 *      while the first is open, which is the couplet's demand moved into time.
 *   4. **The breath halved**, once, at the peak.
 *
 * ...and the length went up again with them: **73 sections, 26.5 minutes**, from
 * 24 and 10.9 where this started.
 *
 * Measured (`tools/length.sweep.ts`, seven seeds): 5/7 finished, 19.7 restarts a
 * run, 0.270 a section, and **157 carriers taken by the embers** against act I's
 * 121 and every other act's zero. The restart rate went *down* from the first
 * pass's 0.338 and that is the instrument rather than the act - the scripted bot
 * is blind to predators, so five hunters moved its restart count from 19.3 to
 * 19.7. `taken` is the column that had to be added to see this pass at all, and
 * `docs/DESIGN-LENGTH.md` §9 is the whole reckoning.
 *
 * Three things changed in the first pass and nothing else did:
 *
 *   1. **The act got longer at exactly the same pace.** The `pace` of all six
 *      stations is byte-for-byte what it was. The game does not get faster; there
 *      is more of it.
 *   2. **The stations even out.** They ran 0.8 to 2.9 minutes; doubling each in
 *      place would have given a 5.8-minute deorbit carrying four obstacles. They
 *      are 3.7 to 5.1 now, which also means the price of a lost station - this
 *      act restarts rather than ends - roughly doubles.
 *   3. **Obstacle density goes from 1.6 a minute to 2.3**, spent where the pace
 *      allows it. It cannot go much further and that is arithmetic rather than
 *      taste: density is speed over spacing, the speed is frozen, and the deorbit
 *      at 23 px/s would have to stack two obstacles inside one screen height to
 *      reach act I's 3.5. What the slow stations get instead is their `open`
 *      sections spent - the deorbit was 2.9 minutes carrying two obstacles, and
 *      half of its four sections were empty water.
 *
 * ## Two movements, two rests, and a station that does not end on a gate
 *
 * A doubled station that is twice as much of the same thing is a station that
 * drags. So each one is **A, a breath, and B**: A speaks the act's established
 * language, B is where that station's hardest question arrives, and the empty
 * section between them is the one place the player can put the phone down inside
 * a four-minute station.
 *
 * The plan was for that mid-station breath to be the rest each station already
 * had, *moved* from the end of the station to its middle - it costs no length
 * that way. **That was wrong, and it was wrong by a factor of five.** Built that
 * way the act measured 35.6 restarts a run against the old act's 1.2, and every
 * one of them was `sweptAway` rather than a missed ring or an emptied swarm: the
 * swarm was simply being left behind. Two changes, measured one at a time, put it
 * back - together they are 6.8, and neither is worth half of what the pair is:
 *
 *   - **The rest at the end was never decoration.** It is where the swarm pays
 *     back the ground it loses under a station's pressure ramp, which peaks at
 *     the station's own end. So a doubled station gets *two* rests, one in each
 *     half, and the mid-station breath is an addition rather than a move.
 *   - **A station does not end on a compulsory ring.** The pressure peak and a
 *     ring are opposite demands - one says keep up, the other says stop and hold
 *     a body still - and the old four-section stations never collided them
 *     because they all ended on empty medium. Every station's last *demand* now
 *     carries an ordinary ring, and the gate is somewhere the swarm still has
 *     room to recover from.
 *
 * That is 28 compulsory rings rather than 33, and 1.37 a minute against the old
 * act's 1.65 - fewer per minute than before, on an act that is twice as long and
 * twice as expensive to lose. It is the one number in this rebuild that went
 * *down*, and it went down because a measurement said so.
 *
 * **The plasma keeps half of its exception.** It is the only station with no
 * rest in its *middle* - fourteen demands in a row - but it lands like the rest
 * of them, because the version that did not cost two completions in seven.
 *
 * ## The rhythm: the medium schedule, drawn as spacing
 *
 * Every act in the campaign used to be laid on the same 820 px metronome, so an
 * act's rhythm was whatever its section count happened to be, and act V said its
 * one idea in the medium and nowhere else. It says it in the spacing now: **the
 * contraction is `mediumTo` drawn in pixels**, the same curve, on the same six
 * stations, in the units the player actually feels.
 *
 * Falling into an atmosphere, things stop being far apart. So the gaps run 1080 px
 * at the deorbit, close station by station to 560 in the plasma, and open again to
 * 1300 at the last section of the nucleus as the swarm slows into weather. The
 * per-station totals are 5860, 7730, 8725, 10 640, 11 615 and 8620 - 53 190 px, and
 * `tests/reentry.test.ts` sums them.
 *
 * It reads at two scales, because it is one rule applied twice. Inside a station
 * the gaps contract as well, so each station opens on its widest and closes on
 * its narrowest; and each station's widest is narrower than the last one's, all
 * the way down to the plasma. The plasma is the one exception and it is the
 * interesting one: at [640, 620, 600, 580, 560 x 9, 580, 600, 620, 660, 700] it is
 * flat, because it is already on the floor and has nothing left to contract into,
 * and its last gap is the widest thing in the station. That widening is where the
 * act turns over. Nothing else in the campaign has a station where the sections
 * come this fast for this long.
 *
 * Two numbers inside stations break the contraction on purpose and both are the
 * same device: the back half of a **scissor** is pulled in to couplet spacing in
 * the middle of a station rather than at its end - 560 px at the aurora and again
 * in the plasma. A tight gap is how this act says "these two are one demand", and
 * it now says it in the middle of a sentence as well as at the end of one.
 *
 * ### ...and the contraction now has a punchline
 *
 * Three stations close on a **couplet**: two sections four hundred-odd pixels
 * apart with their gaps a third of the width from each other. That distance is
 * chosen against the one thing this game has always been about - the current you
 * laid three seconds ago is not the current you are on - so the line for the
 * second gate has to be laid *before entering the first*. It is the act's
 * contraction taken to its conclusion rather than a new idea bolted on, and it
 * costs no engine code at all: `spacing` has no floor and never did.
 *
 * Neither half of a couplet carries a compulsory ring, and the two halves are
 * excused for different reasons. The first is not asked for one because holding a
 * body inside a ring and already building the line out of it are two demands on
 * one section at the tightest spacing in the act, which is not a couplet, it is a
 * wall. The second is not asked because a couplet is where a station ends, and a
 * station does not end on a gate. The couplet is the demand; the ring beside it
 * is the pay.
 *
 * ## The ring grammar: two rings on one line
 *
 * The campaign's default is one compulsory ring at the section's own centre about
 * 200 px in front of it, and act V used to have that and only that, eighteen times
 * over. It asks for a **tight** swarm, which is the right thing to ask for almost
 * everywhere and the wrong thing to ask for here, because this act's danger is not
 * death - it cannot end a run - it is **scatter**, and the answer to scatter is not
 * a smaller body.
 *
 * So sections carry two rings on one `dy`, between 0.25 and 0.35 of the width
 * apart: the compulsory one on the aperture the section was already asking for,
 * an optional one beside it. A swarm that has stayed wide and together crosses
 * both on the same line and takes both. A scattered one takes neither cleanly,
 * because its halves arrive at different times and neither of them is 28 % of
 * anything. It is the only place in the campaign that pays for width.
 *
 * Never two compulsory rings on one line. A compulsory ring wants 28 % of the whole
 * swarm inside it for 0.7 s, so a second one beside it asks for 56 % in two places
 * at once, which is not a demand, it is a wall. The plasma's plume had exactly that
 * pair and one of its two rings is now optional.
 *
 * The count went from 18 compulsory rings to 31, which is *fewer per minute* -
 * 1.17 against 1.65 - and that is the correction described two sections up
 * rather than a softening for its own sake. A compulsory ring is this act's main
 * way of losing a station, and the station is now twice as expensive to lose.
 *
 * ## The second axis: seventeen of these do not stand still
 *
 * Every obstacle in the first six acts stands still, which made the whole
 * difficulty of this game spatial - read the shape, lay the line, arrive. That is
 * one axis and it was the only one. Act V has the other: seventeen sections here
 * are authored with `motion` (see `MotionSpec` in `levels.ts`), and it is a
 * *modifier on a section* rather than an alphabet of its own, so the seventy
 * shapes the game already draws can all have it for one line each.
 *
 *   - **An aperture breathes.** The gap opens and closes on the breath's own
 *     eleven seconds. It is authored **shut** - `gap` is the narrowest it ever
 *     gets - so the corridor sweep, which never advances a clock, is already
 *     checking the hardest phase. The demand is to arrive lined up on the open
 *     half of the cycle, and the way to shift your arrival is to brake, which is
 *     the verb this act is about anyway.
 *   - **A mass walks.** A plume or a tower that slides sideways while you close
 *     on it: the game's oldest sentence made literal, because now the *gap* is
 *     not where it was either. Its authored position is the middle of its travel
 *     and `Section.envelope` carries the union of everywhere it ever is, so the
 *     sweep's guarantee is the strong one - there is a line past it whenever you
 *     arrive, not just when you arrive on the beat.
 *   - **A scissor is two masses on opposite halves of one clock.** The second
 *     pass's answer to the complaint that the first one added length rather than
 *     demand: one walking mass asks you to aim where the gap will be, and a pair
 *     of them walking against each other means there is no phase at which either
 *     is where you last saw it. See `WALK_OUT`/`WALK_BACK`.
 *   - **A counter-phase pair is the couplet, in time.** Two breathing gaps two
 *     breaths apart, the second shut while the first is open. It is the only place
 *     in the campaign where being early is a mistake. See `PULSE_OPEN`/`PULSE_SHUT`.
 *
 * They arrive in teaching order: the first aperture is in the deorbit, the
 * slowest station in the act, at its widest gaps; the first walking mass is two
 * stations later, at the aurora, where it is one of two channels round a plume
 * and the compulsory ring is in the channel it is *not* walking into; and the
 * first scissor is the very next section after it, which is the same object
 * doubled rather than a new one to learn.
 *
 * ## Six stations
 *
 *   1. **The Deorbit** - still orbit. One long burn, and the trajectory
 *      bends until it stops being an orbit and becomes a fall. The widest gaps in
 *      the act and still the quietest station in it: five obstacles in 4.2
 *      minutes, where it used to be two in 2.9. The campaign's last unwritten
 *      shape is here - orbit's `hulk`, authored for the first time anywhere.
 *   2. **The Night Side** - coming down over the unlit half. The
 *      last quiet station in the campaign's second half, the first couplet, and
 *      **the first thing that hunts the swarm since act II**.
 *   3. **Aurora** - through the curtains rather than over them, which is the same
 *      light act IV looked down on, met from underneath. The last debris in the
 *      act is here, and so is the first thing in the campaign that walks - twice,
 *      because the first scissor is here too.
 *   4. **The Plasma** - the loudest frame in the game. The air is here
 *      and it is on fire. Seventeen obstacles, 10 640 px, two embers, and no rest
 *      anywhere in it.
 *   5. **The Meteor Dust** - cooling. The gold has stopped burning and
 *      started being dust, and the gaps start opening again. The longest station
 *      in the act, and the counter-phase pair is here because it needs the room.
 *   6. **The Nucleus** - and that dust is what a raindrop condenses on,
 *      which is what act III's fifth station was quietly promising. The act relaxes
 *      all the way out: its last gap is the longest anywhere in act V.
 *
 * ## What can go wrong, and what it costs
 *
 * The danger is not primarily death - this act cannot end a run either. It is
 * **scatter**: the swarm arrives at the plasma spread out, loses its stragglers to
 * the margin, and comes out of it as much less than it went in. What the player is
 * asked for is to slow the swarm without tearing it apart, which is the one thing
 * they have never been asked for before, because until the Overview nothing in this
 * game had momentum worth braking.
 *
 * ## The fourth demand, which the first pass named and did not build
 *
 * A threat that returns, in the act's own material. It was left out of the pilot
 * on purpose and the reason was written down: `HunterSpec` is generic and the
 * `PredatorSystem` would have carried it, but the renderer picked its silhouette
 * off the medium - `air` got a raptor and everything else got a shark - and a
 * shark at two hundred kilometres is precisely the image the anvil's
 * eleven-kilometre ceiling exists to prevent.
 *
 * It is built now, and it is not an animal. **The ember** is a piece of the
 * vehicle with a worse mass-to-area ratio than the swarm has: it ablates more
 * slowly, sheds less speed, and therefore comes up from behind with the air in
 * front of it already white. Nothing about it is chasing anything. See
 * `render/Ember.ts` for the silhouette and why it could not have been either of
 * the other two with a different colour on it, and `PredatorForm` for the branch
 * that used to be a guess about the medium and is now a fact about the predator.
 *
 * Five of them across the four stations from the night side to the meteor dust -
 * two in the plasma, one everywhere else - and they are the first things to hunt
 * this swarm in thirty stations. The one measurement
 * behind the placement: the campaign's six hunters were all in acts I and II, so
 * the only thing in this world with intent disappeared a quarter of the way round
 * and never came back. That is most of why the back half stopped escalating.
 *
 * ## The verb finally has teeth
 *
 * The act's verb, since it was first written, is **brake, and accept the medium**.
 * It was flown again after the second pass and the report was that the fall is
 * free: *"I can descend much faster than the background and the obstacles scroll
 * up, so the top of the course never catches up and I can never die."*
 *
 * Right, and right by construction. `World.step` takes the greater of its own
 * drift and the swarm's position, with no upper bound, so a hand that pushes drags
 * the world along with it and the only failure of position in the game is
 * unreachable. Measured on `tools/rush.sweep.ts`: a rushing hand made 2.29 times
 * the world's own travel through this act, twice the careful hand's ground, and
 * paid **nothing**. Act I is immune to the same hand - 0.98 - because rushing a
 * climb buys nothing. It is falling that was free.
 *
 * The answer is `Medium.drag`, and it is not in this file: past 1.6 times a
 * station's own drift the air begins taking the swarm apart from the front. What
 * *is* in this file is where it applies - the four stations whose medium is
 * `plasma`, which is to say the middle of the act. **The deorbit stays free
 * because it is vacuum and there is nothing there to outrun, and the nucleus stays
 * free because it is the release.** The act's shape is now the same statement
 * three times over: the fall is free at the top, the air takes hold in the middle,
 * and it lets go at the bottom.
 *
 * ## What is still not measured
 *
 * **Nobody has flown the second pass or the terminal on a phone.** Four things to
 * watch, and all four are what these passes traded away: whether an ember arriving
 * from behind reads as pressure or as an ambush in an act whose whole subject is
 * braking; whether the plasma at 3.7 minutes with no middle is a peak or an
 * endurance test (deliberately the smallest share of the new length, for exactly
 * this reason); whether losing a five-minute station is a setback or the end of
 * the evening, given `RESTARTS_PER_ACT` is 2 and was set when an act was ten
 * minutes long; and whether the heat at the frame's leading edge is read as a
 * warning in time, or only understood afterwards. The last one is the whole of
 * whether the terminal is a demand or a tax - the bots say a hand that watches it
 * beats one that does not, and a bot is not a player.
 */

/**
 * A station's breath, and the gap it sits behind.
 *
 * The spacing used to be baked in at 920 px in all five places this was called,
 * which made the rest every station gets exactly the rest every other station
 * gets. The rest is part of the rhythm now, so it is an argument - and since the
 * rebuild it sits in the middle of its station rather than at the end of it.
 */
function breath(spacing: number, x: number, count: number): SectionSpec {
  return { kind: 'open', spacing, rings: [{ x, dy: -60, count }] };
}

/** A compulsory ring, on the line the section already asks for. */
function must(x: number, dy: number, count: number, scale = 1.35): RingSpec {
  return { x, dy, count, required: true, scale };
}

/**
 * Two rings on one line: the compulsory one at `x`, an optional one `apart` of
 * the width beside it, both on the same `dy`. Act V's own grammar - see the
 * header.
 *
 * `apart` is signed and is kept between 0.25 and 0.35 of the width. Closer than
 * that and an ordinary body covers both without having been asked for anything;
 * wider and no body covers both at all, so the line stops being a reward for
 * width and becomes a choice between two rings.
 *
 * The second ring is never `required`, in any caller, ever.
 *
 * It is, however, nearly as *wide*. An optional ring asks for 0.28 of the swarm
 * held for 0.7 s where a compulsory one asks 0.20 for 0.5 s, so at the default
 * radius the free half of this line is strictly the harder half - and above about
 * sixty-six carriers 0.28 of the swarm does not physically fit inside 62 px, which
 * is most of act V. A line authored to reward width has to be holdable at both
 * ends or it is not a line, it is a compulsory ring with a decoration beside it.
 */
function pair(x: number, apart: number, dy: number, count: number, scale = 1.35): RingSpec[] {
  return [
    { x, dy, count, required: true, scale },
    { x: x + apart, dy, count: count - 1, scale: scale - 0.15 },
  ];
}

/**
 * The breath, as a period. Named here rather than passed, because a section that
 * pulsed on some other clock would be a second rhythm in a game that has one.
 */
const PULSE = { kind: 'aperture', reach: 0.055 } as const;

/**
 * The breath, halved.
 *
 * 5.5 s is not a second rhythm and that distinction is the whole reason this is
 * allowed to exist: it is the same eleven seconds counted twice, the way a bar of
 * music is still the bar when you play eighths in it. What it buys is the one
 * escalation an aperture has that costs nothing else - **the open half of the
 * cycle is half as long** - and it is spent once, in the plasma, on the tightest
 * spacing in the act. Anywhere slower it would read as a flicker rather than as
 * a thing to time.
 */
const HALF_BREATH = { kind: 'aperture', reach: 0.05, period: 5.5 } as const;

/**
 * Two masses on one clock and opposite halves of it: the scissor.
 *
 * A single walking mass asks "aim where the gap will be". A pair of them a few
 * hundred pixels apart, one going out while the other comes back, asks something
 * the campaign has never asked: **there is no phase at which both are where you
 * last saw them.** A line laid for the first is always the wrong line for the
 * second, and the only way through is to lay the line the pair will have made by
 * the time you get there.
 *
 * It is safe for the same reason a single drift is - `Section.envelope` carries
 * the union of everywhere each mass ever is, and the corridor sweep reads that,
 * so a lane exists past both of them at every phase and not merely on the beat.
 * The guarantee is stronger than the demand, which is the right way round.
 */
const WALK_OUT = { kind: 'drift', reach: 0.06, phase: 0 } as const;
const WALK_BACK = { kind: 'drift', reach: 0.06, phase: 0.5 } as const;

/**
 * Two breathing gaps, and the second is shut while the first is open.
 *
 * The couplet's demand is spatial - lay the line for the second gate before
 * entering the first - and this is the same sentence in time. Taking the first
 * one the moment it opens puts the swarm at the second one at its narrowest;
 * waiting a beat costs ground against the drift. It is the only place in the
 * campaign where being early is a mistake.
 */
const PULSE_OPEN = { kind: 'aperture', reach: 0.055, phase: 0.25 } as const;
const PULSE_SHUT = { kind: 'aperture', reach: 0.055, phase: 0.75 } as const;

/**
 * A piece of the vehicle, still coming down.
 *
 * `at` is where the swarm has to *reach* before it is released, not where it
 * waits - see `World.releaseStoops`: act V's threat always overtakes, so the
 * authored `dy` is a trigger line rather than a place, and the fragment is put
 * into the world behind the swarm the moment that line is crossed. `x` is where
 * across the field it comes up.
 */
function ember(
  centre: number,
  radius: number,
  x: number,
  at: number,
  size: number,
  spacing: number,
  rings: RingSpec[],
): SectionSpec {
  return {
    kind: 'ember',
    centre,
    radius,
    hunters: [{ x, dy: at, size }],
    spacing,
    rings,
  };
}

export const REENTRY_LEVELS: Level[] = [
  {
    key: 'deorbit',
    name: 'The Deorbit',
    depthMeters: -380000,
    subtitle: 'The orbit that becomes a fall',
    zone: ZONE_REENTRY,
    // Still orbit, and only just beginning to be anything else. A station that
    // named a different medium here would throw away the one thing the handover
    // has: the player arrives still holding act IV's hand.
    medium: 'space',
    mediumTo: 'space',
    decor: 'void',
    pace: 0.34,
    roughness: 0,
    swirl: 0,
    /*
     * 1080, 860, 760, 720, 680, 640, 600, 520 - 5860 px. This is the top of the
     * contraction: the medium here is still pure vacuum, `vacuum` has not begun
     * to fall, and the spacing says the same thing the medium does.
     *
     * The opener is the widest gap in the act and everything behind it is pulled
     * in hard. At pace 0.34 a minute is expensive: written at its old spacings
     * with its landing back it came to 4.7 minutes carrying four obstacles, which
     * is the emptiest thing in the campaign outside act VII. **Pulled in, it is
     * still by some way the most spacious station in act V, and the unit that says
     * so is seconds rather than pixels** - its tightest gap is 22 s where the
     * plasma's is 11.8. That is the same reading the plasma's floor is defended
     * with, and act V needs it in both directions because its paces run 0.34 to
     * 0.70.
     *
     * It stays the quietest station in the act, and that is the point of it: five
     * obstacles across 4.2 minutes against the plasma's sixteen across 3.5. What
     * it lost was not its room, it was the second of its two empty sections - a
     * station cannot be *about* having room in it if half of it is nothing.
     */
    sections: [
      {
        // The burn. One very wide arc and nothing else - the trajectory bends,
        // and the only thing the player has to do is let it.
        //
        // 1120 px is the widest gap in the act and it is spent on nothing, which
        // is the point of it: the act's own ring grammar is taught here, in empty
        // vacuum, where being asked for two rings on one line and failing at it
        // costs the player a count and no more.
        kind: 'open',
        spacing: 1080,
        rings: pair(0.4, 0.3, 0, 11, 1.6),
      },
      {
        kind: 'arc',
        centre: 0.44,
        gap: 0.56,
        bow: 0.16,
        spacing: 860,
        rings: [{ x: 0.44, dy: -250, count: 10 }],
      },
      {
        /*
         * The act's one standing hazard, and it pushes.
         *
         * A negative `strength` is a well that repels, and `PotentialField` peaks
         * its profile at 0.3 of the radius - so this is a hill with a calm point on
         * top of it, and the ring is on that point. Holding a body somewhere it is
         * being pushed out of is act V's stated subject, scatter, written as an
         * object; the act had the subject in its prose, in its ring grammar and in
         * nowhere the world itself did anything about.
         *
         * It was +88, a puller, which is the one thing this act should not have:
         * a well that gathers the swarm is the act's danger solving itself. One
         * ring rather than two either way - a `pair()` across a field this strong
         * would be asking for width and for a point at the same second.
         */
        kind: 'node',
        centre: 0.6,
        radius: 0.38,
        strength: -96,
        spacing: 760,
        rings: [must(0.6, 0, 11, 1.5)],
      },
      // The rest, and it is in the middle of the station now rather than at the
      // end of it. Everything before this is act IV's language; everything after
      // it is the first thing act V has to say for itself.
      breath(720, 0.34, 10),
      {
        /*
         * The first thing in this campaign that moves.
         *
         * It is here rather than at the peak on purpose: the slowest station in
         * the act, at almost its widest gap, with nothing else in the frame and a
         * compulsory ring 250 px in front of it. A player who does not notice
         * that it is breathing still gets through - it is authored shut and 0.42
         * of the width is passable at the closed phase - and a player who does
         * notice has just learned the act's second question without being told it.
         */
        kind: 'arc',
        centre: 0.5,
        gap: 0.42,
        bow: 0.14,
        spacing: 680,
        motion: PULSE,
        rings: [must(0.5, 250, 11)],
      },
      {
        /*
         * The dead hulk, and the first splittable mass in act V's first half.
         *
         * Orbit's own alphabet has six shapes in it and act V borrowed five; this
         * is the sixth, and it had never been authored anywhere in the campaign -
         * `tests/geometry.test.ts` carried it as the one knowingly-unused entry in
         * any act's alphabet. An unused shape is a cost rather than a spare part,
         * and the deorbit is exactly where it belongs: the hardest edge in the
         * game, met in the widest water in the act, on the last station that is
         * still honestly in orbit.
         *
         * A ring in each channel, one of them compulsory. Splitting the body and
         * putting it back together is act I's oldest tactic and act V had one
         * place to practise it before the plasma; it has two now.
         */
        kind: 'hulk',
        centre: 0.5,
        radius: 0.1,
        spacing: 640,
        rings: [must(0.12, -150, 11), { x: 0.88, dy: -150, count: 11, scale: 1.35 }],
      },
      {
        // A funnel to close the station on: the walls start off-field and
        // converge, so the whole of it is holding rather than finding.
        kind: 'strait',
        centre: 0.42,
        gap: 0.46,
        mouth: 0.72,
        depth: 250,
        spacing: 600,
        rings: [{ x: 0.42, dy: 255, count: 11, scale: 1.35 }],
      },
      // The landing. See the header: a station gets two rests now, and this is
      // the one that was measured back into existence.
      breath(520, 0.5, 11),
    ],
  },
  {
    key: 'nightside',
    name: 'The Night Side',
    depthMeters: -300000,
    subtitle: 'The dark half of the world',
    zone: ZONE_REENTRY + 1,
    // The first thinning of the vacuum. `vacuum` starts falling here, so a stroke
    // begins - very slightly - to push as well as to bend.
    medium: 'space',
    mediumTo: 'plasma',
    decor: 'void',
    pace: 0.4,
    roughness: 0.15,
    swirl: 0,
    /*
     * 1000, 940, 880, 820, 780, 740, 700, 660, 440, 400, 370 - 7730 px. The first
     * contraction, and for eight sections it is a patient one: 340 px lost across
     * seven gaps, because the air has only just started arriving and the rhythm is
     * only just starting to notice.
     *
     * And then the floor drops out of it. The last two are 440 and 400, less than
     * two thirds of anything before them, and they are the act's first couplet -
     * two gates a third of the width apart with no time between them to find the
     * second one. The station's shape is the whole act's shape in miniature: a
     * long patient contraction and then the thing it was contracting toward.
     *
     * It is also where **the first thing that hunts you since act II arrives**,
     * and it arrives exactly where the medium starts to change. See the `ember`
     * below: the fiction and the mechanic are the same event.
     */
    sections: [
      {
        // The pair here is two doors of the same curtain: the compulsory ring on
        // the middle door, the optional one on the left. Both sit 195 px in front
        // of the sheet, so a body wide enough to hold the line arrives already
        // lined up on two of the three ways through and goes through both of them.
        kind: 'flare',
        gaps: [0.24, 0.52, 0.8],
        gap: 0.24,
        spacing: 1000,
        rings: pair(0.52, -0.28, 195, 11),
      },
      {
        // The optional ring sits just *outside* the arc's mouth, which is the
        // hardest version of this act's demand and the reason it is optional: take
        // it and the swarm is wide and off the line with 225 px to gather.
        kind: 'arc',
        centre: 0.68,
        gap: 0.5,
        bow: 0.2,
        spacing: 940,
        rings: pair(0.68, -0.28, 225, 11),
      },
      {
        // Orbit's chicane, and the only one in the act: three staggered rows, three
        // committed lines, no time to settle between them. It is the shape act V
        // borrows from above rather than from ahead, and it is the last of them -
        // everything from the plasma on is either act V's own or the air's.
        kind: 'shrapnel',
        gap: 0.44,
        rows: 3,
        swing: 0.12,
        first: -1,
        spacing: 880,
        rings: [{ x: 0.5, dy: -250, count: 12, scale: 1.35 }],
      },
      {
        kind: 'strait',
        centre: 0.4,
        gap: 0.44,
        mouth: 0.72,
        depth: 250,
        spacing: 820,
        rings: [must(0.4, 260, 12)],
      },
      breath(780, 0.5, 11),
      /*
       * The first ember, and the first threat in the campaign since act II's
       * anvil - thirty stations and about forty minutes of play ago.
       *
       * It is here rather than in the plasma for two reasons and they agree. The
       * fiction: this is the station where `mediumTo` first says something other
       * than where it started, so it is the first place in the act with any air in
       * it at all, and a fragment cannot burn in vacuum. And the teaching: the
       * night side is the last quiet water in act V, so the one thing in this act
       * that comes from *behind* gets introduced with nothing else in the frame,
       * one fragment, at the smallest size the act uses.
       *
       * The trigger is 260 px before the section's own line, which at this pace is
       * about ten seconds of warning - the ember comes up the course behind the
       * swarm while the stub of vehicle it broke off is still ahead of it.
       */
      ember(0.5, 0.07, 0.5, 260, 15, 740, [{ x: 0.5, dy: 175, count: 12, scale: 1.35 }]),
      {
        /*
         * A breathing arc, and the night side's own version of the deorbit's.
         *
         * The deorbit taught this at 0.42 of the width with nothing else on the
         * screen. Here it is behind an ember that is still overtaking, which is
         * the act's first collision of two demands: the gap in front of you is
         * moving and the thing behind you is not going to wait for it.
         */
        kind: 'arc',
        centre: 0.3,
        gap: 0.44,
        bow: 0.14,
        spacing: 700,
        motion: PULSE,
        rings: [must(0.3, 230, 12)],
      },
      {
        // The second curtain, and its doors are offset from the first one's by
        // about a sixth of the width - so the line that took the opener through
        // the middle door arrives here against solid air.
        kind: 'flare',
        gaps: [0.2, 0.5, 0.78],
        gap: 0.23,
        spacing: 660,
        rings: [{ x: 0.5, dy: 190, count: 12, scale: 1.35 }],
      },
      {
        /*
         * The couplet, and the first one in the campaign.
         *
         * 440 px at pace 0.4 is about sixteen seconds from this arc to the next,
         * and the two gaps are 0.38 of the width apart. Sixteen seconds is not the
         * problem; the problem is that a current laid *at* this gate is a current
         * that is still pushing when the next one arrives, so the only line that
         * takes both is one that was already leaning right on the way through here.
         *
         * No compulsory ring on it. See the header: the first half of a couplet
         * asks the player to be building the next line, and a ring asks them to be
         * holding this one.
         */
        kind: 'arc',
        centre: 0.28,
        gap: 0.42,
        bow: 0.14,
        spacing: 440,
        rings: [{ x: 0.28, dy: -220, count: 11 }],
      },
      {
        kind: 'arc',
        centre: 0.66,
        gap: 0.4,
        bow: 0.12,
        spacing: 400,
        rings: [{ x: 0.66, dy: 210, count: 12, scale: 1.35 }],
      },
      breath(370, 0.5, 11),
    ],
  },
  {
    key: 'auroraBelow',
    name: 'The Aurora',
    depthMeters: -200000,
    subtitle: 'From the inside now',
    zone: ZONE_REENTRY + 2,
    medium: 'plasma',
    mediumTo: 'plasma',
    decor: 'void',
    pace: 0.48,
    roughness: 0.4,
    swirl: 0,
    /*
     * The same light act IV looked down on, met from underneath - and the first
     * time in the campaign the player recognises somewhere they have been. It is
     * also the last calm band before the air arrives, and it is deliberately the
     * most beautiful thing in the act: what comes next is the loudest frame in
     * the game, and it needs something quiet immediately in front of it.
     *
     * Mechanically this is the station where the medium is *half* there. `vacuum`
     * is 0.34, so a stroke lays a third of itself as gravity and two thirds as
     * wind, and neither habit works on its own. Nothing tells the player this.
     *
     * 920, 880, 840, 800, 760, 720, 680, 560, 640, 600, 480, 440, 405 - 8725 px,
     * and the first station whose widest gap is under a thousand. It is also where
     * the two alphabets are made to overlap: an `arc` opens it, orbit's last shape
     * and the deepest into the act any debris gets, and the `shock` that is its
     * mirror stands one section behind it. Half a medium, and both halves of the
     * vocabulary, in one station.
     *
     * The 560 in the middle of that list is the one number that does not belong to
     * the contraction: it is the back half of **the scissor**, and it is pulled in
     * to couplet spacing on purpose, in the middle of a station rather than at its
     * end. See the two `plume`s below.
     */
    sections: [
      {
        // Orbit's shape, three hundred kilometres lower than it belongs. Bowed
        // less than the night side's, because the point of it here is the
        // recognition rather than the difficulty.
        kind: 'arc',
        centre: 0.34,
        gap: 0.52,
        bow: 0.16,
        spacing: 920,
        rings: pair(0.34, 0.3, 235, 12),
      },
      {
        // ...and the mirror of it, 880 px later. An arc's mouth runs away from the
        // swarm and a shock's comes to meet it, and this is the only place in the
        // campaign where they are close enough together to be read as one gesture.
        kind: 'shock',
        centre: 0.56,
        gap: 0.48,
        bow: 0.14,
        spacing: 880,
        rings: [must(0.56, 230, 12)],
      },
      {
        // Two channels round a mass, which is a different thing from a pair on one
        // line: these are 0.69 of the width apart, and no body holds both. One is
        // compulsory and the other is the reward for having split cleanly.
        // The plumes run the other way from act II's towers: the act's own note is
        // that the last ones are it running itself down, so 3.0 -> 3.2 -> 2.4.
        kind: 'plume',
        centre: 0.46,
        radius: 0.1,
        height: 3,
        spacing: 840,
        rings: [
          { x: 0.16, dy: -155, count: 12, scale: 1.35 },
          { x: 0.85, dy: -155, count: 12, scale: 1.35 },
        ],
      },
      breath(800, 0.4, 11),
      {
        // Orbit's shape again, and the second-to-last debris anywhere in act V -
        // the last one is the first half of this station's couplet, nine hundred
        // pixels further down. Two arcs bracketing the plumes is the station's
        // whole subject in its geometry: the medium is half here, and so is the
        // vocabulary.
        kind: 'arc',
        centre: 0.3,
        gap: 0.46,
        bow: 0.14,
        spacing: 760,
        rings: [{ x: 0.3, dy: -230, count: 12, scale: 1.35 }],
      },
      {
        // The second breathing gap, and the first one that is off-centre - so the
        // wall opens asymmetrically about a hole at 0.38 rather than about the
        // middle of the field. That is the case the motion pivot had to be built
        // for; see `setMotion`.
        kind: 'shock',
        centre: 0.38,
        gap: 0.44,
        bow: 0.16,
        spacing: 720,
        motion: PULSE,
        rings: [must(0.38, 225, 12)],
      },
      {
        /*
         * The first thing in the campaign that walks, and the front half of the
         * first scissor.
         *
         * A plume drifting 0.06 of the width either way, with a channel on each
         * side of it and the compulsory ring in the left one - the channel it is
         * *not* walking into when it walks right. So the demand is legible: the
         * ring never moves, and what moves is how much room there is to get to it.
         *
         * Its envelope runs 0.47 to 0.77 of the width, which leaves the optional
         * ring at 0.86 clear by 35 px at the worst phase. That is not a comfort,
         * it is the corridor sweep's job - `Section.envelope` is what it reads -
         * but a number this tight is worth writing next to the thing it is about.
         */
        kind: 'plume',
        centre: 0.62,
        radius: 0.09,
        height: 2.8,
        spacing: 680,
        motion: WALK_OUT,
        rings: [must(0.2, -150, 12), { x: 0.86, dy: -150, count: 12, scale: 1.35 }],
      },
      {
        /*
         * ...and the back half of it, 560 px later and walking the other way.
         *
         * The two masses are on the same eleven-second clock and opposite halves
         * of it, so when the first has walked right the second has walked left,
         * and the lane the pair leaves is never straight. Nothing in the campaign
         * before this has asked the player to aim at a place that does not exist
         * yet in *two* directions at once, and it is the reason `MotionSpec.phase`
         * was built: with the default phase - keyed to where a section happens to
         * sit on the course - this pair would be a coincidence rather than a shape.
         *
         * No compulsory ring, and the reason is the couplet's reason. This is the
         * second half of a pair whose demand is the pair, and holding a body still
         * inside a ring while the room in front of it is walking is two demands on
         * one section at the tightest spacing in the station.
         */
        kind: 'plume',
        centre: 0.38,
        radius: 0.085,
        height: 2.6,
        spacing: 560,
        motion: WALK_BACK,
        rings: [{ x: 0.8, dy: -145, count: 12, scale: 1.35 }],
      },
      /*
       * The second ember, in the first station that is properly in plasma.
       *
       * The night side's came up the middle at fifteen; this one comes up at 0.35
       * of the width, which is where a swarm that has just been walked left by the
       * scissor is. It is the same object arriving where the section in front of
       * it has put you, and that is the difference between a hazard and a
       * composition.
       */
      ember(0.62, 0.075, 0.35, 280, 16, 640, [{ x: 0.55, dy: 170, count: 12, scale: 1.35 }]),
      breath(600, 0.5, 11),
      {
        // The station's couplet: orbit's shape and act V's own, 480 px apart, the
        // two gaps 0.36 of the width from each other. The last debris in the act
        // is the first half of it.
        kind: 'arc',
        centre: 0.3,
        gap: 0.4,
        bow: 0.12,
        spacing: 480,
        rings: [{ x: 0.3, dy: -215, count: 11 }],
      },
      {
        kind: 'shock',
        centre: 0.66,
        gap: 0.38,
        bow: 0.16,
        spacing: 440,
        rings: [{ x: 0.66, dy: 200, count: 12, scale: 1.35 }],
      },
      breath(405, 0.5, 11),
    ],
  },
  {
    key: 'plasma',
    name: 'The Plasma',
    depthMeters: -80000,
    subtitle: 'The air arrives',
    zone: ZONE_REENTRY + 3,
    medium: 'plasma',
    mediumTo: 'plasma',
    decor: 'void',
    // The fastest station in the act, and the only place in the campaign's second
    // half where the pace goes *up*. Everything after this slows down and stays
    // slow: the difficulty peak is not the finale.
    //
    // Slowblue: 0.70 rather than 0.62, because at 0.62 it was the *same speed* as act
    // VI's Downpour, which claims the same superlative in its own file. Two
    // files cannot both hold it. The descent's declared peak is this station, so
    // this one takes the pace and act VI's claim is scoped to act VI.
    pace: 0.7,
    roughness: 0.85,
    swirl: 0,
    /*
     * The loudest frame in the game. Everything is on fire, the sky behind it has
     * gone white, and the swarm is brighter than anything else can be.
     *
     * The demand is **braking without scattering**, and the composition is built
     * for it: shocks bowed toward the player so the way through opens as they slow
     * into them, plumes to split on, sheets that ask for a line rather than for a
     * hole, and then the first cloud in the act.
     *
     * 640, 620, 600, 580, then nine at 560, then 580, 600, 620, 660, 700 - 10 640 px
     * across eighteen sections, and the tightest station in the campaign by a long
     * way. It is flat rather than contracting because it is already at the floor.
     *
     * That floor is measured in **seconds**, and it has to be: three couplets in
     * this act are shorter than 560 px and the night side's is 400. Spacing is
     * not comparable across stations running at different paces, and act V's run
     * from 0.34 to 0.70 - four hundred pixels at the night side's drift is 14.7
     * seconds, and five hundred and sixty at the plasma's is 11.8. Nothing in the
     * act arrives faster than that, and `tests/reentry.test.ts` says so in the
     * unit the player actually feels. The closing 660 is the first widening.
     *
     * **It is still the only station with no rest in its middle**, and that is
     * what is left of a claim that used to be larger. "No breath anywhere in it"
     * was true of this station at four sections and forty-eight seconds, and it
     * was one of the two things that made the rebuilt act unflyable: held to at
     * fourteen sections it cost two completions in seven and four restarts a run,
     * measured against the identical act with one open section on the end of it.
     * So the plasma is sixteen demands with nowhere to stop in the middle of
     * them, and then it lands like everything else. The peak of a ten-minute act
     * could be a station you cannot put down. The peak of a twenty-minute one is
     * a station you cannot put down *until it is over*.
     *
     * ### ...and it is the station that did *not* get the act's new length
     *
     * The second pass grew act V by a quarter and grew this station by two
     * sections, which is the smallest share of it anywhere. That is deliberate and
     * it is the one place the length plan was argued *against*. Every other
     * station here has rests in it, so making it longer makes it longer; this one
     * has none, so making it longer makes it **harder in a way nothing measures** -
     * the doc's own open question is whether the plasma at three minutes with no
     * middle is the peak of the act or an endurance test, and that question has
     * not been answered on a phone yet. Doubling a station while its one known
     * risk is still unmeasured is how you find out too late. It is 3.5 minutes
     * and it can go up when somebody has actually flown it.
     *
     * The two sections it did get are both new *demands* rather than more of the
     * same: the back half of a scissor, and two embers.
     */
    sections: [
      {
        kind: 'shock',
        centre: 0.5,
        gap: 0.44,
        bow: 0.22,
        spacing: 640,
        rings: [must(0.5, 245, 12)],
      },
      {
        // Both of these used to be compulsory, on the same `dy`, 0.7 of the width
        // apart: 56 % of the swarm held in two places at once, at the fastest pace
        // in the act. The right one is optional now and the demand is unchanged
        // for anyone who was actually managing it.
        kind: 'plume',
        centre: 0.36,
        radius: 0.115,
        height: 3.2,
        spacing: 620,
        rings: [
          { x: 0.14, dy: -160, count: 13, scale: 1.35 },
          { x: 0.84, dy: -160, count: 13, scale: 1.35 },
        ],
      },
      {
        // The pair at the peak, and both rings are inside doors: the compulsory
        // one on the left door of the sheet, the optional one just inside the
        // right. A body wide enough to hold 0.34 of the width goes through the
        // sheet in two places.
        kind: 'sheet',
        gaps: [0.26, 0.62],
        gap: 0.24,
        spacing: 600,
        rings: pair(0.26, 0.3, 200, 13),
      },
      {
        // A breathing gap at 580 px and pace 0.70, which is twelve seconds from
        // the section in front of it - very nearly one whole cycle. So this one is
        // met at close to the same phase every run, and what varies is where the
        // *player* is when they meet it. That is the difference between a hazard
        // on a clock and a slot machine, and it is why the period is the breath's
        // rather than something chosen to be awkward.
        kind: 'shock',
        centre: 0.44,
        gap: 0.4,
        bow: 0.2,
        spacing: 580,
        motion: PULSE,
        rings: [must(0.44, 235, 13)],
      },
      {
        // The plasma's scissor, and the tighter of the two: 560 px at pace 0.70 is
        // 11.8 seconds, which is one breath. So the pair is met almost exactly a
        // cycle apart and its two halves are half a cycle out of step - the second
        // mass has always crossed to the other side by the time the swarm gets to
        // it. The aurora taught this at 17 seconds with a rest behind it.
        kind: 'plume',
        centre: 0.6,
        radius: 0.1,
        height: 3,
        spacing: 560,
        motion: WALK_OUT,
        rings: [must(0.2, -150, 13), { x: 0.88, dy: -150, count: 13, scale: 1.35 }],
      },
      {
        kind: 'plume',
        centre: 0.4,
        radius: 0.095,
        height: 2.8,
        spacing: 560,
        motion: WALK_BACK,
        rings: [{ x: 0.84, dy: -145, count: 13, scale: 1.35 }],
      },
      {
        kind: 'sheet',
        gaps: [0.34, 0.7],
        gap: 0.22,
        spacing: 560,
        rings: [must(0.34, 195, 13)],
      },
      /*
       * An ember in the tightest water in the campaign.
       *
       * Eleven point eight seconds between sections, a swarm that has just been
       * walked across the field by the scissor, and a fragment coming up behind it
       * at 0.24 of the width. There is no version of this the player gets to solve
       * by stopping: the ember is behind, the shock is in front, and the only
       * answer act V has ever had is to keep the body wide and let it be pushed.
       *
       * It is the loudest thing in the loudest frame in the game, and it is the
       * moment the whole rebuild was for.
       */
      ember(0.5, 0.075, 0.24, 300, 17, 560, [{ x: 0.7, dy: 165, count: 13, scale: 1.35 }]),
      {
        // The breath, halved. See `HALF_BREATH`: the same clock counted twice, so
        // the gap is open for 2.75 seconds at a time instead of 5.5, met at 11.8
        // seconds' spacing - two full cycles, so it is still the same phase every
        // run. It is spent once and it is spent here.
        kind: 'shock',
        centre: 0.56,
        gap: 0.38,
        bow: 0.24,
        spacing: 560,
        motion: HALF_BREATH,
        rings: [must(0.56, 230, 13)],
      },
      {
        kind: 'plume',
        centre: 0.4,
        radius: 0.105,
        height: 2.9,
        spacing: 560,
        rings: [
          { x: 0.14, dy: -150, count: 13, scale: 1.35 },
          { x: 0.82, dy: -150, count: 13, scale: 1.35 },
        ],
      },
      {
        // The plasma's couplet, and the only one in the act that is not at the end
        // of its station - because at 560 px the whole station is already couplet
        // spacing and this is simply the pair whose gaps are furthest apart. First
        // half, no compulsory ring, as everywhere.
        kind: 'shock',
        centre: 0.3,
        gap: 0.4,
        bow: 0.18,
        spacing: 560,
        rings: [{ x: 0.3, dy: -210, count: 12 }],
      },
      {
        kind: 'sheet',
        gaps: [0.32, 0.68],
        gap: 0.22,
        spacing: 560,
        rings: [must(0.68, 190, 13)],
      },
      {
        kind: 'shock',
        centre: 0.48,
        gap: 0.4,
        bow: 0.22,
        spacing: 560,
        motion: PULSE,
        rings: [must(0.48, 225, 13)],
      },
      /*
       * The second ember, and the last one that arrives while anything is still
       * on fire. It comes up at 0.78 - the far side from the first - so the two of
       * them between them have crossed the whole field, and a player who learned
       * "they come up the left" from the one at the peak has learned the wrong
       * thing about a hazard that is not steering.
       *
       * 580 px is the first widening in the station. The ember is what the extra
       * twenty pixels are spent on.
       */
      ember(0.44, 0.07, 0.78, 265, 17, 580, [{ x: 0.34, dy: 160, count: 13, scale: 1.35 }]),
      {
        kind: 'plume',
        centre: 0.6,
        radius: 0.1,
        height: 2.8,
        spacing: 600,
        motion: { kind: 'drift', reach: 0.07 },
        rings: [{ x: 0.18, dy: -150, count: 13, scale: 1.35 }],
      },
      {
        kind: 'sheet',
        gaps: [0.3, 0.66],
        gap: 0.22,
        spacing: 620,
        rings: pair(0.3, 0.32, 195, 13),
      },
      {
        // The first cloud in the act, and it is *inside the fire*. Eighty
        // kilometres is not an arbitrary place to put it: it is where noctilucent
        // cloud is, the only altitude in the world where weather and re-entry
        // share a sky, and it is the same eighty kilometres act III's fifth
        // station is flown at. The air has arrived; this is what it brought.
        kind: 'bank',
        centre: 0.5,
        gap: 0.46,
        spacing: 660,
        rings: [{ x: 0.5, dy: 215, count: 13, scale: 1.35 }],
      },
      // And then it lands, at 700 - the third step of the widening this station
      // turns over on. See the header: the claim that this one has no rest in it
      // was written about a station of forty-eight seconds, and it cost two
      // completions in seven when it was held to at two minutes fifty-two.
      breath(700, 0.5, 12),
    ],
  },
  {
    key: 'meteordust',
    name: 'The Meteor Dust',
    depthMeters: -40000,
    subtitle: 'What is left after the fire',
    zone: ZONE_REENTRY + 4,
    // The air, arriving properly. From here the input is wind and the last of the
    // gravity goes out of it under the player's hand.
    medium: 'plasma',
    mediumTo: 'cloud',
    decor: 'void',
    pace: 0.56,
    roughness: 0.7,
    swirl: 0,
    /*
     * Cooling. The orange goes out of it, the glow stops being fire and starts
     * being warmth, and what the swarm has become is dust - which is exactly what
     * every noctilucent cloud on the planet is built on, and is why act III's
     * fifth station foreshadows this one from eighty kilometres up.
     *
     * The last plumes in the campaign are here, and they are half the size of the
     * plasma's: the act is running itself down.
     *
     * 620, 650, 680, 700, 720, 750, 780, 800, 810, 830, 850, 870, 890, 900, 765 -
     * 11 615 px, and the only station in the act whose gaps open from the first one
     * to the last (the closing rest is the one step back in, and a rest is not a
     * gap). The 620 is deliberately the second tightest gap in act V and it comes
     * straight out of a station that had no breath in it: the relaxation is a slope
     * the swarm is let down, not a door it is shown through.
     *
     * It is the **longest station in act V** at five minutes, and it is the right
     * one to be: it is the only one whose whole shape is release, so length here
     * buys the cooling rather than more pressure. The act's peak stays three and a
     * half minutes and this is five - which is the same statement the paces make,
     * written in the other unit.
     */
    sections: [
      {
        kind: 'plume',
        centre: 0.58,
        radius: 0.095,
        height: 2.4,
        spacing: 620,
        rings: [must(0.17, -150, 13), { x: 0.84, dy: -150, count: 13, scale: 1.35 }],
      },
      {
        kind: 'sheet',
        gaps: [0.34, 0.68],
        gap: 0.28,
        spacing: 650,
        rings: [must(0.34, 200, 13)],
      },
      {
        kind: 'shock',
        centre: 0.46,
        gap: 0.42,
        bow: 0.18,
        spacing: 680,
        motion: PULSE,
        rings: [must(0.46, 215, 13)],
      },
      {
        // The last walking mass in the act, and the only one whose compulsory ring
        // is on the side it walks *toward*. By here the demand can be stated
        // plainly: the room you are aiming at is closing while you cross to it.
        kind: 'plume',
        centre: 0.34,
        radius: 0.09,
        height: 2.2,
        spacing: 700,
        motion: { kind: 'drift', reach: 0.06 },
        rings: [must(0.72, -145, 13)],
      },
      /*
       * The last ember in act V, and the one that is not a surprise.
       *
       * By here the player has met three of them and knows the shape of the thing:
       * it comes from behind, it does not steer, and the only answer is to not be
       * where it is going. So this one is authored as a *statement* rather than as
       * a question - the widest run-up any ember gets, in the station where
       * everything is cooling, and it is the last time in the campaign that
       * anything hunts the swarm at all.
       *
       * The fiction closes here too. Below forty kilometres a fragment this size
       * has finished ablating; what comes down after this is dust, which is what
       * the player is carrying.
       */
      ember(0.5, 0.07, 0.55, 285, 16, 720, [{ x: 0.42, dy: 180, count: 13, scale: 1.35 }]),
      breath(750, 0.5, 12),
      {
        // Torn cloud: the one shape in act II's alphabet that means *scattered*,
        // and the act meets it at the exact moment the swarm has become dust.
        //
        // The rings are 260 px past the line, so the pair is taken in open air on
        // the far side of the chicane: three committed lines with no rest, and
        // then the act asks whether the body that came out of them is still wide.
        //
        // Slowblue: the compulsory one was at 0.40 and that single number carried
        // about half of act V's restarts. The three rows leave doors at 0.63,
        // 0.37 and 0.63 of the width; their x-ranges intersect only over 0.42 to
        // 0.58, so 0.55 is a line that threads all three and 0.40 is a line that
        // threads none - the swarm was being asked to leave the chicane through a
        // wall. The chicane itself is not the cost and its numbers do not move.
        kind: 'wisps',
        gap: 0.42,
        rows: 3,
        swing: 0.13,
        first: 1,
        spacing: 780,
        rings: pair(0.55, 0.3, -260, 13),
      },
      {
        kind: 'sheet',
        gaps: [0.3, 0.64],
        gap: 0.26,
        spacing: 800,
        rings: [must(0.3, 195, 13)],
      },
      {
        kind: 'plume',
        centre: 0.55,
        radius: 0.085,
        height: 2,
        spacing: 810,
        rings: [
          { x: 0.18, dy: -145, count: 12, scale: 1.35 },
          { x: 0.86, dy: -145, count: 12, scale: 1.35 },
        ],
      },
      {
        /*
         * The counter-phase pair, and the act's last new idea.
         *
         * Two breathing gaps 830 and 850 px apart - about 22 seconds, or two
         * breaths - authored half a cycle out of step, so **the second one is shut
         * while the first one is open**. Taking the first the moment it opens puts
         * the swarm at the second at its narrowest; waiting one beat costs ground
         * against the drift and arrives on the open half of both.
         *
         * It is the couplet's demand moved from space into time. The couplet says
         * lay the line for the second gate before entering the first; this says
         * choose *when* to enter the first, and it is the only place in the
         * campaign where being early is a mistake. It is here rather than in the
         * plasma because it needs room to be read in - at 560 px it would be a
         * reflex, and this act's subject is braking.
         */
        kind: 'shock',
        centre: 0.42,
        gap: 0.44,
        bow: 0.16,
        spacing: 830,
        motion: PULSE_OPEN,
        rings: [must(0.42, 205, 12)],
      },
      {
        kind: 'shock',
        centre: 0.6,
        gap: 0.42,
        bow: 0.14,
        spacing: 850,
        motion: PULSE_SHUT,
        rings: [{ x: 0.6, dy: 195, count: 12, scale: 1.35 }],
      },
      {
        // The last plume in the campaign, and the smallest. Two channels, no
        // compulsory ring in either: the act has stopped asking and is only
        // showing now.
        kind: 'plume',
        centre: 0.45,
        radius: 0.08,
        height: 1.9,
        spacing: 870,
        rings: [
          { x: 0.14, dy: -140, count: 12, scale: 1.35 },
          { x: 0.8, dy: -140, count: 12, scale: 1.35 },
        ],
      },
      {
        // The station's couplet is the widest in the act - 890 and 900 px - which
        // is to say it is barely one. The device is being let go of, the same way
        // everything else here is.
        kind: 'shock',
        centre: 0.4,
        gap: 0.44,
        bow: 0.16,
        spacing: 890,
        rings: [{ x: 0.4, dy: -200, count: 12 }],
      },
      {
        kind: 'shock',
        centre: 0.66,
        gap: 0.4,
        bow: 0.14,
        spacing: 900,
        rings: [{ x: 0.66, dy: 205, count: 12, scale: 1.35 }],
      },
      breath(765, 0.5, 11),
    ],
  },
  {
    key: 'nucleus',
    name: 'The Nucleus',
    depthMeters: -12000,
    subtitle: 'What the rain grows on',
    zone: ZONE_REENTRY + 5,
    // Fully weather. The handover is complete and nothing announced it.
    medium: 'cloud',
    mediumTo: 'cloud',
    decor: 'void',
    pace: 0.5,
    roughness: 0.6,
    swirl: 0,
    /*
     * Cold, wet and grey. The dust has finished being a meteor and started being
     * the thing a raindrop condenses on, and the whole of act VI is in this
     * palette in miniature.
     *
     * Authored entirely out of act II's cloud, and that is the point of it: the
     * player has come all the way back to a medium they know, from the other
     * direction, and the only new thing in the frame is that everything is falling.
     *
     * 880, 930, 980, 1040, 1100, 1160, 1230, 1300 - 8620 px, and the only station
     * in the act that opens the whole way through. Every other station in act V
     * closes; this one is the release, and its last gap is the longest anywhere
     * here. The act ends on 1300 px of open cloud with one ring in it, which is
     * rather more than the distance act I's first station uses to teach the game,
     * spent on nothing at all except arriving somewhere.
     */
    sections: [
      {
        kind: 'bank',
        centre: 0.34,
        gap: 0.5,
        spacing: 880,
        rings: pair(0.34, 0.3, 210, 13),
      },
      {
        kind: 'tower',
        centre: 0.54,
        radius: 0.12,
        spacing: 930,
        rings: [
          { x: 0.16, dy: -150, count: 13, scale: 1.35 },
          { x: 0.85, dy: -150, count: 13, scale: 1.35 },
        ],
      },
      breath(980, 0.5, 12),
      {
        kind: 'pass',
        centre: 0.46,
        gap: 0.42,
        mouth: 0.52,
        depth: 240,
        spacing: 1040,
        rings: [must(0.46, 255, 14)],
      },
      {
        // The last breathing gap in the act, and the widest: 0.48 shut, in cloud,
        // at 1100 px of run-up. It is the same object the deorbit taught, met
        // again at the other end of the act with everything else gone quiet - the
        // one place the player can actually *watch* one of these work.
        kind: 'bank',
        centre: 0.6,
        gap: 0.48,
        spacing: 1100,
        motion: PULSE,
        rings: [must(0.6, 230, 13)],
      },
      {
        // Torn cloud, and the last chicane in act V. Two rows rather than the
        // meteor dust's three and a wide gap in both: it is the shape that means
        // *scattered*, met one last time in the station where being scattered has
        // stopped costing anything. The act says the same word twice and means
        // something different by it the second time.
        kind: 'wisps',
        gap: 0.46,
        rows: 2,
        swing: 0.12,
        first: -1,
        spacing: 1160,
        rings: [{ x: 0.5, dy: -240, count: 12, scale: 1.35 }],
      },
      {
        // A tower that walks, with no compulsory ring anywhere near it. The act's
        // last obstacle asks for nothing and moves anyway, which is the note the
        // whole descent ends on: the world does not stop being a place when it
        // stops asking you for something.
        kind: 'tower',
        centre: 0.4,
        radius: 0.11,
        spacing: 1230,
        motion: { kind: 'drift', reach: 0.05 },
        rings: [{ x: 0.74, dy: -150, count: 12 }],
      },
      // The last section of act V. Open cloud, one ring, and then the rain.
      { kind: 'open', spacing: 1300, rings: [{ x: 0.5, dy: -90, count: 12 }] },
    ],
  },
];

/**
 * Act V: six stations, orbit to the top of the weather, **falling**.
 *
 * The first act with `direction: 1`. Everything downstream of that - the camera
 * anchor, the pruning, the strand line, the spawn line, the section crossing -
 * reads it through `World.u()` and needs no branch of its own, which is the whole
 * reason the direction abstraction was built before any of this act existed.
 */
export const ACT_REENTRY: Act = makeAct('reentry', REENTRY_LEVELS, {
  direction: 1,
  carrier: 'dust',
});
