import { NEVER_FAILS } from '../sim/Failure';
import { makeAct, type Act, type Level, type RingSpec } from './levels';
import { ZONE_HOME } from './zones';

/**
 * Slowblue: act VII — the homecoming.
 *
 * ## This is not act I reversed
 *
 * It is the same water, and it is deliberately not the same act. This file used
 * to open on that sentence and then contradict it in the next hundred lines: four
 * `gate`s, one `rock`, one `narrows` and one `vortex`, which is act I's alphabet
 * with the lights turned down. Five things are different now, and all five are
 * the point.
 *
 * **The water is soft.** Below the sunlit zone almost nothing in the ocean is
 * hard. It is gelatinous, it is metres long, it is 95 % water, and it hangs
 * rather than sits, so this act is authored out of the two shapes that are
 * bodies: `drape`, a siphonophore hanging *along* the course with real water
 * between its strands, and `bloom`, a loose swarm of medusae with more open
 * water in it than animal. Neither of them may close the course — that is the
 * act's rule and `ObstacleSystem.homeDrape` and `homeBloom` are built for it.
 * The only stone in the act is at the salt line, where act VI's brook arrives,
 * and it runs out inside that one station; see below.
 *
 * **The carrier drifts rather than swims.** Plankton, larvae and marine snow do
 * not go anywhere on their own — `migrationSpeed` is the water's, but what the
 * player is steering has no intention. Act I was about holding a body of life
 * together against things that would take it apart; this is about letting it
 * settle, together.
 *
 * **The rhythm dilates and never comes back.** See below. Every other act in the
 * campaign has a rhythm that is a *shape*, some pattern of tight and loose that
 * repeats. This one's is a direction.
 *
 * **The second half has nothing in it.** Not "thins out": nothing. Stations 4, 5
 * and 6 contain no obstacle section whatsoever, only open water with rings
 * drifting in it. The obstacle count per station is 10, 10, 8, 0, 0, 0, and the
 * last three zeroes are the design's "the hazards thin out and then stop" taken
 * at its word rather than approximated with a wide gate.
 *
 * **The second half cannot be lost.** `Level.failure` is `'none'` from the deep
 * sea onward — not a difficulty setting and not anything the player switched on,
 * but the campaign declining to have an opinion any more. A player who stops
 * steering in the last three stations still arrives. See `sim/Failure.ts`.
 *
 * ## The length rebuild, and why all of it is above the deep sea
 *
 * The circuit was measured and found to be an hour that was not badly *long* but
 * badly *divided* — acts I and II ask something every seventeen seconds and act
 * IV every fifty-five (`docs/DESIGN-LENGTH.md`). Act V was rebuilt first, from
 * 10.9 authored minutes to 26.5 at byte-for-byte the same pace, and the recipe it
 * proved is what this act has now been given: more sections, no faster, and the
 * new sections asking things the act could not ask before.
 *
 * Act VII is the one act in the campaign where that recipe cannot simply be
 * applied end to end, because **half of it is authored silence and the silence is
 * the point.** So the whole rebuild lands above the salt line's own horizon:
 *
 *   - The first three stations go from 3, 3 and 3 sections to **13, 12 and 10**,
 *     and from 1.1, 1.3 and 1.5 minutes to 4.4, 4.5 and 4.7. They are the
 *     stations that can still be lost, so they are the stations that can still
 *     be *given* something.
 *   - The last three are untouched, to the pixel. 2700, 3000 and 3300 px at
 *     paces 0.34, 0.28 and 0.22, no obstacle in any of them, `failure: 'none'`
 *     on all three. Filling those would delete the reason this act exists.
 *
 * 18 sections became 44 and 12.1 authored minutes became 21.9. The obstacle
 * density runs **2.3, 2.2, 1.7, 0, 0, 0** a minute — read it as a row and it is
 * the act's whole argument, which is that everything here is a quantity that
 * falls to zero and stays there. Across the act it averages 1.3, and it cannot
 * be more: a third of act VII is eight minutes of open water and that is a
 * decision rather than a shortfall.
 *
 * ## The rhythm: dilation, all the way to a stop
 *
 * Every section in the campaign used to sit 820 px from the last one, so an act's
 * ten minutes were divided into equal parts by default rather than by anybody's
 * decision. Act VII divides them the way it divides everything else. The gaps get
 * larger monotonically from the salt line to the trench floor, and they never
 * shorten once, because the act *is* the campaign slowing down and stopping:
 *
 *   | station        | sum  | intervals                     |
 *   | -------------- | ---- | ----------------------------- |
 *   | brackish       | 8320 | 640, thirteen times           |
 *   | sunlit         | 8160 | 680, twelve times             |
 *   | twilight       | 7675 | 700 to 835, fifteen at a time |
 *   | midnightHome   | 2700 | 880, 900, 920                 |
 *   | snow           | 3000 | 980, 1000, 1020               |
 *   | trenchHome     | 3300 | 1050, 1100, 1150              |
 *
 * 33 155 px in all. What the rebuild changed is only how many times each interval
 * is spoken: the intervals themselves still only ever grow, and the tightest one
 * in the act came in from 700 px to 640 because the salt line is the one place
 * where the river's insistence is still supposed to be audible.
 *
 * The first two stations hold a single interval each rather than growing inside
 * themselves, because a river has a rhythm and the sea does not: the dilation is
 * a thing the *ocean* does, so it starts where the fresh water runs out. From the
 * twilight down every section is further from its neighbour than the one before.
 *
 * There is no `breath()` helper in this act. Six acts end each station on one
 * long empty section with a ring in it and name that helper for the rest it is;
 * here the rests are inlined, because from the deep sea down every section is one
 * and a word that means "punctuation" would be lying about nine of them.
 *
 * ## The four demands, in the two shapes that are animals
 *
 * Act V proved that a moving section is a modifier rather than an alphabet — one
 * optional `MotionSpec` field on any of the seventy shapes the game draws (see
 * `levels.ts`). What it costs here is four lines, and what it buys is the only
 * kind of difficulty this act is allowed to have, because **gap widths do not
 * tighten and nothing may close the course.** So the water moves instead.
 *
 *   - **A bloom that walks** (`SWAY`). A swarm of medusae is made of the same
 *     stuff as the thing the player is steering and goes where the water goes, so
 *     of the seventy shapes in this game it is the one that has the least excuse
 *     for standing still. It is the first moving thing in the act and it is in
 *     the salt line, at the widest water, with a ring on the far side of it.
 *   - **A bloom that pulses** (`PULSE`). An aperture opens the widest space
 *     inside a body and closes it again on the breath's own eleven seconds, which
 *     for a bell is not a metaphor: it is how a medusa swims. The channel through
 *     the middle of the bloom is the one that breathes.
 *   - **The scissor** (`SWAY_OUT` / `SWAY_BACK`). Two curtains on one clock and
 *     opposite halves of it. A single drifting mass asks the player to aim where
 *     the lane will be; a pair walking against each other means there is no phase
 *     at which either is where it was last looked at.
 *   - **The counter-phase pair** (`PULSE_OPEN` / `PULSE_SHUT`). Two curtains 715
 *     px apart, which is less than the height of the screen, breathing exactly
 *     out of step — so the player can see both at once and one of them is always
 *     shut. Act V put its pair two breaths apart and had to argue about arrival
 *     times; this one is a single picture.
 *
 * All four are safe by construction and not by care: an aperture is authored
 * **shut**, so the corridor sweep is already looking at its narrowest frame, and
 * a drift's `Section.envelope` carries the union of everywhere it ever is. See
 * `tests/motion.test.ts`, which also holds the rule that an authored phase is
 * only ever half of a pair.
 *
 * ## The couplet, met at the moment act V had already let go of it
 *
 * The fifth demand act V proved is two sections close enough together that the
 * line for the second has to be laid before entering the first, and **this act's
 * own law forbids it**: nothing in act VII is ever closer to its neighbour than
 * the thing before it was. So the couplet lives where the act is tightest, which
 * is the bottom of the salt line — two blooms 640 px apart with their lanes 0.34
 * of the width from each other, and no required ring on either.
 *
 * 640 px at pace 0.46 prices out at twenty seconds, which would be no couplet at
 * all if the price were honest. It is not: the last three stations of this act
 * are authored at fifty seconds a section and measure twenty-four, because from
 * the rain down the carrier's own drive is two and a half to three and a quarter
 * times the authored drift and the camera takes the greater of the two (see the
 * marine snow's note below, and the drive-over-drift table in `config/tuning.ts`).
 * At the rate the swarm actually crosses this water those two blooms are about
 * ten seconds apart, which is act V's couplet exactly.
 *
 * ## The ring grammar: six, and then the asking stops
 *
 * 92 of the campaign's hundred-odd obstacle sections carried one required ring at
 * the section's own centre, 185 to 265 px in front of it. Act VII keeps **six
 * required rings, and it kept the same six while the act grew four times longer**:
 * three in the salt line, two in the sunlit zone, one in the twilight and none at
 * all below it. The count of demands runs 3, 2, 1, 0, 0, 0, which is the same
 * shape as the failure arc and the same shape as the rhythm.
 *
 * That is the one number in this rebuild that did not move, and it did not move
 * on purpose. Act V's own measurement is that a doubled station and a compulsory
 * ring pull against each other — a station's pressure ramp peaks at its end and a
 * ring asks the swarm to stop and hold still — and it cost that act two
 * completions in seven before it was found. Here the conclusion is stronger,
 * because a station that cannot close the course has nothing to *hold* the player
 * with except a ring: six in twenty-eight obstacles is six moments where this act
 * insists, spread over twenty minutes, and everything else is offered.
 *
 * They are the widest rings in the game (`scale` 1.6 to 1.75, against act I's
 * 1.15 to 1.5) and no station's last demand carries one, which is act V's rule
 * and is checked by nothing but this sentence.
 *
 * Below the twilight every ring is optional: drifting, worth taking, and costing
 * nothing to miss. That is the whole of what the last three stations ask.
 *
 * Which is why the optional ones are wide here too — `scale: 1.5`, under every
 * required ring in the act and over every ring anywhere else. An optional ring
 * asks for 0.28 of the swarm held for 0.7 s where a required one asks 0.20 for
 * 0.5 s, and the number of bodies that physically fit inside an unscaled 62 px
 * ring does not grow with the swarm — so at the sixty to ninety carriers a player
 * arrives here with, an unscaled optional ring is not a gentle reward, it is
 * impossible. Fifteen of the forty-four sections in this act have nothing in them
 * but one of these; if they cannot be taken, the last three stations contain
 * nothing at all rather than "no demands".
 *
 * ## Six stations, and the circle closing
 *
 *   1. **The Salt Line** — brackish water, and the gold has come back
 *      as something alive for the first time since the surface. The last four
 *      stones in the campaign are here and they get smaller until there are none.
 *   2. **The Sunlit Zone** — act I's blue, met going the other way,
 *      and the busiest water in the act: five curtains and five blooms.
 *   3. **The Twilight Zone** — the light starting to go, and the last
 *      station with anything in it at all.
 *   4. **The Deep Sea** — nothing can be lost from here.
 *   5. **Marine Snow** — the one station in the game where the whole
 *      world is falling the way the player is. For the first time the swarm is not
 *      passing through the world; it is descending with it.
 *   6. **The Trench Floor** — six thousand metres, and the first frame
 *      of the game. The last golden motes reach the floor, small fish gather
 *      around them, and out of that light the first shoal forms.
 *
 * The last palette is act I's first, to within a few values, and the final frame
 * dissolves into the title screen. Only then does the player understand that they
 * did not play a one-way ascent but a circuit.
 */

/**
 * A compulsory ring, on the line the section already asks for.
 *
 * The default scale is the widest in the campaign, and deliberately: a required
 * ring in this act is not a target, it is a thing the player would have to work
 * to miss. There are six of them in forty-four sections.
 */
function must(x: number, dy: number, count: number, scale = 1.6): RingSpec {
  return { x, dy, count, required: true, scale };
}

/**
 * ...and the other kind, which is nearly all of them.
 *
 * Named for what it is rather than for what it is not: `may` is the act's whole
 * register, and writing thirty-eight of these out as object literals with the
 * same `scale: 1.5` on every one of them was how the file used to hide the fact
 * that its ring grammar is one decision made once.
 */
function may(x: number, dy: number, count = 14, scale = 1.5): RingSpec {
  return { x, dy, count, scale };
}

/**
 * A bell's own stroke, as an aperture.
 *
 * A medusa swims by opening and closing, on about the rhythm this whole game is
 * built at, so of the four acts that could have been given a breathing gap this
 * is the one where the mechanism and the animal are the same fact. What opens is
 * the widest space *inside* the body — `setMotion` finds the hole rather than the
 * centroid — which on a bloom is the channel the swarm most wants, and on a
 * two-strand curtain is the lane between the strands.
 *
 * 0.05 of the width each way. It is authored shut, so nothing about it can be
 * narrower than what the corridor sweep already checked; what it can do is be
 * *wider* if the player arrives on the right half of the breath.
 */
const PULSE = { kind: 'aperture', reach: 0.05 } as const;

/**
 * A mass carried sideways, which in this act is the least remarkable thing an
 * obstacle could possibly do.
 *
 * Every other act had to justify a walking obstacle; here the two shapes are a
 * jelly and a swarm of jellies, neither of which has anywhere to be, and the one
 * that does not move is the one making a claim. The reach is 0.055 of the width
 * either way and the authored position is the middle of the travel, so the sweep
 * reads the union (`Section.envelope`) rather than one frame of it.
 */
const SWAY = { kind: 'drift', reach: 0.055 } as const;

/**
 * The scissor: two curtains on one clock and opposite halves of it.
 *
 * A single walking mass asks the player to aim where the lane will be. A pair of
 * them, one going out while the other comes back, asks something else — there is
 * no phase at which both are where they were last looked at, so the line that
 * took the swarm through the first is always the wrong line for the second.
 *
 * A drifting drape translates as one body, so its lanes keep their widths and
 * only their *positions* move. That is the difference between this and the
 * aperture, and it is why the act can afford both: one moves the door, the other
 * changes its size.
 */
const SWAY_OUT = { kind: 'drift', reach: 0.055, phase: 0 } as const;
const SWAY_BACK = { kind: 'drift', reach: 0.055, phase: 0.5 } as const;

/**
 * Two curtains breathing exactly out of step.
 *
 * Act V invented this as the couplet moved from space into time and had to argue
 * about arrival: two gates two breaths apart, so that taking the first the moment
 * it opens reaches the second at its narrowest. Act VII gets the argument for
 * free, because 715 px is less than the height of the phone — **both curtains are
 * on the screen at once, and one of them is always shut.** Nothing has to be
 * remembered and nothing has to be timed from a beat that has left the frame; it
 * is one picture, and it is the only place in the campaign where waiting is the
 * answer.
 */
const PULSE_OPEN = { kind: 'aperture', reach: 0.05, phase: 0.25 } as const;
const PULSE_SHUT = { kind: 'aperture', reach: 0.05, phase: 0.75 } as const;

export const HOME_LEVELS: Level[] = [
  {
    key: 'brackish',
    name: 'The Salt Line',
    depthMeters: 20,
    subtitle: 'Where the fresh turns salt',
    zone: ZONE_HOME,
    // The last of the river, becoming the first of the sea. Same continuous
    // handover grammar act V used for the air: the medium is resolved across the
    // station rather than switched at its line.
    medium: 'stream',
    mediumTo: 'water',
    decor: 'kelp',
    pace: 0.46,
    roughness: 0.6,
    swirl: 0,
    /*
     * 640 px between sections, thirteen times over: the tightest interval in the
     * act and the only one in it that ever repeats. This station is still running
     * at the river's rhythm, and the river is the one part of act VII that has
     * somewhere to be. Everything after this is further apart than this, forever.
     *
     * 8320 px, 4.4 minutes, ten obstacles. It was three sections and one obstacle,
     * and what it gained is the thing the whole station is about: **the stone runs
     * out inside it.** Act VI ends in a brook full of boulders and act VII begins
     * where that brook meets the sea, so the salt line does what an estuary
     * actually does — it drops what it was carrying, coarsest first. Four rocks at
     * 0.145, 0.13, 0.11 and 0.09 of the width, and then nothing hard ever again.
     *
     * None of them has `teeth`. That flag is what puts a stub of rock on each edge
     * of the field to make the side channels channels, and it is exactly the thing
     * this act is not allowed to do: a mass with two wide ways round it is a body,
     * and a mass with the edges closed off is a wall.
     */
    sections: [
      // The arrival, and the handover from act VI's estuary. One very wide
      // required ring in open water: the first thing this act does is give
      // something to a swarm that has just come down a brook.
      { kind: 'open', spacing: 640, rings: [must(0.5, 0, 14, 1.7)] },
      {
        /*
         * The first of the last stones, and the biggest.
         *
         * A ring in each channel and one of them compulsory, 0.68 of the width
         * apart — the splittable-mass grammar, where two rings on one line mean
         * the opposite of what they mean everywhere else in this act. No body
         * holds both; taking both means splitting and re-forming, which is act
         * I's oldest verb, heard here for the last time in the campaign.
         */
        kind: 'rock',
        centre: 0.44,
        radius: 0.145,
        rings: [must(0.14, -145, 14), may(0.82, -145)],
        spacing: 640,
      },
      {
        // The first bloom, and it is off to one side with the whole left half of
        // the field open beside it: the shape is introduced where ignoring it
        // costs nothing at all. Both rings are in the clear water, 0.28 of the
        // width apart on one line, which is the act's other pair grammar - close
        // enough that a body that has stayed wide takes both and a scattered one
        // takes neither cleanly.
        kind: 'bloom',
        centre: 0.68,
        radius: 0.085,
        spread: 1,
        rings: [may(0.12, 0), may(0.4, 0, 13)],
        spacing: 640,
      },
      {
        // The second stone, smaller, and on the other side. Nothing required on
        // it: the demand was made once, and this is the same demand offered.
        kind: 'rock',
        centre: 0.58,
        radius: 0.13,
        rings: [may(0.18, -145), may(0.86, -145, 13)],
        spacing: 640,
      },
      // The mid-station breath. Act V measured what happens when a doubled
      // station is given no rest until its end - 42.6 restarts a run against a
      // baseline of 1.2 - so this is an addition rather than the landing moved.
      { kind: 'open', spacing: 640, rings: [may(0.4, -70)] },
      {
        /*
         * The first moving thing in act VII, and the first walking mass in this
         * half of the campaign that is not a piece of a burning spacecraft.
         *
         * It is here for the same reason act V's first aperture is in its
         * slowest station: introduce the new axis where the water is widest and
         * the consequence of missing it is a count rather than a station. The
         * bloom drifts 0.055 of the width either way and its envelope runs 0.04
         * to 0.60; the ring is at 0.85, clear of it by 104 px at every phase, so
         * the demand is legible - the ring never moves and what moves is how much
         * room there is to get to it.
         */
        kind: 'bloom',
        centre: 0.34,
        radius: 0.07,
        spread: 1.5,
        motion: SWAY,
        rings: [may(0.85, 0)],
        spacing: 640,
      },
      {
        kind: 'rock',
        centre: 0.5,
        radius: 0.11,
        rings: [may(0.16, -145), may(0.84, -145, 13)],
        spacing: 640,
      },
      {
        // The first breathing thing in the act. On a bloom the aperture opens the
        // widest space *between the bells* - which is the channel the swarm was
        // going to use anyway - so what the player sees is a swarm of medusae
        // pulsing, and what the water does is the same thing the picture does.
        //
        // Neither ring is inside the animal, and that is the one authoring rule a
        // breathing shape adds: what moves is where the bells are, so a ring left
        // in a channel is a ring that is clear on the phase the corridor sweep
        // checks and swallowed on the phase it never sees. One out in the open
        // water beside it, one 140 px past the line - come out of the pulse in the
        // middle - and the breath is left to be read rather than aimed at.
        kind: 'bloom',
        centre: 0.62,
        radius: 0.075,
        spread: 1.3,
        motion: PULSE,
        rings: [may(0.2, 0), may(0.5, -140, 13)],
        spacing: 640,
      },
      {
        /*
         * The last stone in the campaign, and the smallest of the four.
         *
         * It carries the third and last required ring of the station because of
         * what it is rather than because of where it is: this is the final time
         * anything in this game asks the shoal to come apart and put itself back
         * together, and the ring is in the channel that pays for it. Everything
         * in the water after this line is soft.
         */
        kind: 'rock',
        centre: 0.46,
        radius: 0.09,
        rings: [must(0.18, -150, 14), may(0.84, -150, 13)],
        spacing: 640,
      },
      {
        // Dense, centred and big: the one bloom in the act with a real way round
        // it on both sides and no reason to prefer either. The ring is past the
        // line, so the choice costs nothing and is not scored.
        kind: 'bloom',
        centre: 0.46,
        radius: 0.09,
        spread: 1,
        rings: [may(0.5, -140)],
        spacing: 640,
      },
      {
        /*
         * The couplet, first half. See the header: this act's law is that nothing
         * ever comes closer together, so the couplet is authored at the tightest
         * interval the act has rather than at act V's four hundred pixels, and it
         * is the two lanes rather than the two spacings that make it one.
         *
         * The lane here is the open left third; the lane at the next section is at
         * 0.6, and 0.34 of the width is exactly far enough that the water has to
         * be moving the swarm across before it has finished coming past this one.
         * No required ring on either half - the demand is the pair.
         */
        kind: 'bloom',
        centre: 0.66,
        radius: 0.075,
        spread: 1.2,
        rings: [may(0.26, 0)],
        spacing: 640,
      },
      {
        kind: 'bloom',
        centre: 0.28,
        radius: 0.07,
        spread: 1.3,
        rings: [may(0.6, 0)],
        spacing: 640,
      },
      // The landing. A station ends on a rest and its last demand is not a gate:
      // both halves of that were measured on act V's pilot, one at a time, and
      // together they were worth five restarts in six.
      { kind: 'open', spacing: 640, rings: [may(0.44, -70)] },
    ],
  },
  {
    key: 'sunlit',
    name: 'The Sunlit Zone',
    depthMeters: 150,
    subtitle: 'The light we left behind',
    zone: ZONE_HOME + 1,
    medium: 'water',
    decor: 'meadow',
    pace: 0.44,
    roughness: 0.55,
    swirl: 0,
    /*
     * Act I's blue, met going the other way. The player climbed through this light
     * in the second half of the first act and has not seen daylight in water since.
     *
     * It is the busiest station of act VII and it is the only one that is busy:
     * ten things in the water, five curtains and five blooms, and every one of
     * them is an animal a swarm of larvae passes through rather than round. 680 px
     * apart, still one interval for the whole station, because the sea has only
     * just started and the dilation is the sea's.
     *
     * This is where the act's two shapes are actually taught against each other. A
     * bloom is a body with water in it and a drape is water with bodies hanging in
     * it, so they fail in opposite ways: the bloom costs a few individuals to
     * anyone who goes through the middle of it, and the drape costs a few to
     * anyone who picks the wrong lane and then stays in it - a strand hangs
     * *along* the course, so touching one is not an event, it is a duration.
     */
    sections: [
      {
        /*
         * The first soft thing that hangs, and the wide one of the act's five:
         * two strands, a 203 px lane between them, and 320 px of hang. Four evenly
         * spread strands were tried here and cost more than every wall in act I
         * put together. A strand is not a wall and must not be priced like one.
         *
         * Slowblue: three strands at a 132 px pitch was the other failure, and it was
         * invisible because it looks like the cautious answer. Every agent is
         * repelled out to blob radius plus 66 px, so at the widest slice of that
         * drape only 18 px of the 390 px row was water not already pushing the
         * swarm away: the shape could not be touched, could not be threaded, and
         * cost exactly nothing under any bot style at any population. It was not
         * underpriced, it was illegible - a curtain the player reads as a wall and
         * the simulation reads as a corridor too narrow to aim at. Two strands is
         * the "come through somewhere, and it hardly matters" the alphabet table
         * promises, with 98 px of genuinely open water to come through.
         */
        kind: 'drape',
        strands: [0.22, 0.78],
        reach: 320,
        // Hung under the gap rather than placed in front of the curtain. A drape
        // has no line to commit to, so the ring marks a *column* of water instead:
        // aiming at it from above is coming down the gap, which is the only demand
        // the shape makes and the gentlest way of making it. The optional one is
        // out in the narrow right-hand lane, which is the one place in the act
        // where going for a reward can actually brush an animal.
        rings: [must(0.5, 0, 14, 1.7), may(0.91, 150, 13)],
        spacing: 680,
      },
      {
        // Centred and dense, with a hundred pixels of clear water on each side and
        // nothing to choose between them - so the two rings are not a line, they
        // are a sequence: one out to the left at the bloom's own depth, the other
        // out to the right and 110 px past it. A body that takes both has crossed
        // the whole field through the water the bloom is not in.
        kind: 'bloom',
        centre: 0.5,
        radius: 0.085,
        spread: 1,
        rings: [may(0.13, 0), may(0.87, -110, 13)],
        spacing: 680,
      },
      {
        // Three strands, unevenly placed: a 101 px slot on the left and a 164 px
        // lane on the right, so the demand is "choose a lane" rather than "thread
        // the middle". The ring in the slot is worth a few individuals and is
        // optional for that reason - it is the act's stated bargain, offered where
        // the alternative is free.
        //
        // The wide lane is 0.42 of the width and no drape in this act has one
        // narrower. Measured: a three-strand curtain's best lane loses about 66 px
        // at the row where the bells are, so 0.38 of the width came out at 78 px
        // of open water - under the 88 px the act already had, and gap width is
        // the one lever this rebuild is not allowed to pull.
        kind: 'drape',
        strands: [0.14, 0.4, 0.82],
        reach: 240,
        rings: [may(0.61, 0), may(0.27, 120, 13)],
        spacing: 680,
      },
      {
        // The second walking bloom, and the first one met with something else in
        // the frame. Its envelope reaches 0.59 of the width at the far phase; the
        // ring at 0.85 is clear of that by 103 px, which is not a comfort - the
        // corridor sweep reads the envelope and is the thing that guarantees it -
        // but a number this tight is worth writing next to the thing it is about.
        kind: 'bloom',
        centre: 0.3,
        radius: 0.075,
        spread: 1.6,
        motion: SWAY,
        rings: [may(0.85, 0)],
        spacing: 680,
      },
      // The mid-station breath, and it lands between the two halves of the
      // station's argument: everything above it is one animal at a time, and
      // everything below it is two of them on one clock.
      { kind: 'open', spacing: 680, rings: [may(0.5, -70)] },
      {
        /*
         * The scissor, front half - and the first thing in this act that cannot be
         * answered by picking a line and holding it.
         *
         * Two curtains 680 px apart on the same eleven-second clock and opposite
         * halves of it. A drifting drape moves as one body, so its lanes keep
         * their widths: what the pair does is put the same three lanes in two
         * different places, and the place they are in when the swarm arrives at
         * the second is the mirror of the place they were in at the first.
         *
         * `MotionSpec.phase` is authored on both, which is the only reason this is
         * a shape rather than a coincidence - the default phase is keyed to where
         * a section sits on the course, and two masses that happen to be out of
         * step are not a scissor. `tests/motion.test.ts` allows an authored phase
         * for exactly this and checks that it has a partner.
         *
         * Measured at 0.48 of the width, the second of the pair closes over that
         * line entirely at one phase of the breath while the first never does.
         * That is the whole demand in one number: a line that took the swarm past
         * the front curtain is, at some arrival times, not a line at all at the
         * back one - and the corridor sweep reads the swept envelope of both, so
         * there is always another one.
         */
        kind: 'drape',
        strands: [0.3, 0.68],
        reach: 280,
        motion: SWAY_OUT,
        rings: [may(0.49, -130)],
        spacing: 680,
      },
      {
        // ...and the back half, walking the other way. Its ring is out in the
        // right-hand margin rather than in the lane, because by here the lane is
        // not a place: it is wherever the pair has left it.
        kind: 'drape',
        strands: [0.34, 0.72],
        reach: 280,
        motion: SWAY_BACK,
        rings: [may(0.9, -130, 13)],
        spacing: 680,
      },
      {
        // The densest bloom in the act, and the station's second and last required
        // ring. It is in the clear water beside the animal rather than in it:
        // going round costs nothing and pays, which is the opposite bargain from
        // the slot two sections up, and the act makes both of them once.
        kind: 'bloom',
        centre: 0.6,
        radius: 0.09,
        spread: 1.1,
        rings: [must(0.16, 0, 14, 1.75), may(0.62, -150, 13)],
        spacing: 680,
      },
      {
        // The curtain with no obvious lane: four ways through, none of them wide,
        // none of them better. It is the one drape in the act that does not answer
        // the question it asks, and it is deliberately the one with nothing
        // required anywhere near it.
        kind: 'drape',
        strands: [0.24, 0.46, 0.72],
        reach: 200,
        rings: [may(0.09, 0), may(0.88, -120, 13)],
        spacing: 680,
      },
      {
        // Small bells spread wide: 11 % of the row closed, and more water inside
        // the animal than around it. The ring is past the line rather than in the
        // middle, so what is paid for is coming out of it together.
        kind: 'bloom',
        centre: 0.46,
        radius: 0.06,
        spread: 1.9,
        rings: [may(0.5, -110)],
        spacing: 680,
      },
      {
        // The station's last demand, so it carries nothing required: a short
        // curtain with 160 px of hang and three real ways past it. The act has
        // started letting go, one parameter at a time - the reach is the only
        // dimension a drape thins in, and this is the first of three that get
        // shorter until there are none.
        kind: 'drape',
        strands: [0.38, 0.74],
        reach: 160,
        rings: [may(0.17, 0)],
        spacing: 680,
      },
      { kind: 'open', spacing: 680, rings: [may(0.62, -80)] },
    ],
  },
  {
    key: 'twilight',
    name: 'The Twilight Zone',
    depthMeters: 800,
    subtitle: 'The last trace of light',
    zone: ZONE_HOME + 2,
    medium: 'water',
    decor: 'jelly',
    pace: 0.4,
    roughness: 0.45,
    swirl: 0,
    /*
     * The last station in the campaign with anything in it. From the next one on
     * there is nothing in the water at all, so this is where the game quietly
     * stops being a game, and it does it a station before it says so.
     *
     * It is also the first station whose sections grow apart *inside* it: 700,
     * 715, 730, 745, 760, 775, 790, 805, 820, 835, fifteen pixels at a time, nine
     * times. The two above it held one interval each because they were still the
     * river's; the dilation is the sea's, and this is where the sea takes over -
     * and it takes over as an arithmetic progression rather than as a gesture,
     * because the three stations under it do the same thing faster.
     *
     * Eight obstacles in 4.7 minutes, which is 1.7 a minute against the salt
     * line's 2.3. The station is not thinner by accident: the density falling
     * across the act's three living stations is the only difficulty curve act VII
     * has, and it runs the wrong way on purpose.
     */
    sections: [
      {
        // The same animal as the sunlit zone's, and a different one to read:
        // three strands, unevenly placed, hanging 180 px against the salt line's
        // 320. One obvious wide lane on the right and two slots on the left, so
        // the demand is "choose a lane" - and the act thins in the only dimension
        // a drape has, which is the reach rather than the strand count.
        //
        // Every number on this section is the shipped act's, to the pixel. It used
        // to carry the last compulsory ring in the campaign; that ring has moved
        // five sections down, to the far side of the station's rest, and nothing
        // else about the shape moved with it.
        kind: 'drape',
        strands: [0.2, 0.36, 0.78],
        reach: 180,
        rings: [may(0.57, 0), may(0.28, 90, 13)],
        spacing: 700,
      },
      {
        kind: 'bloom',
        centre: 0.66,
        radius: 0.08,
        spread: 1.2,
        rings: [may(0.2, 0)],
        spacing: 715,
      },
      {
        /*
         * The counter-phase pair, and the act's one new idea.
         *
         * Two curtains hung about the same lane at 0.48 of the width, breathing on
         * the same eleven seconds exactly half a cycle apart, so **one of them is
         * always shut.** Measured at that lane, over one breath, this one runs
         * 120, 114, 100, 86, 80, 100 px of open water and the next one runs 56,
         * 64, 76, 90, 96, 76 - exact mirrors that cross in the middle of the bar.
         * There is no moment at which they are the same width.
         *
         * Act V built this demand as two gates two breaths apart and had to reason
         * about arrival times to make it true. Here the pair is 715 px apart and
         * the phone is 844 px tall, so the argument is not needed - both curtains
         * are in the frame together and the player can watch the far one close
         * while the near one opens. Taking the first the moment it opens arrives
         * at the second at its narrowest; waiting one beat costs ground against the
         * drift and takes both. It is the only place in the campaign where being
         * early is a mistake.
         */
        kind: 'drape',
        strands: [0.26, 0.7],
        reach: 260,
        motion: PULSE_OPEN,
        rings: [may(0.48, 0)],
        spacing: 730,
      },
      {
        // ...and the narrow one, shut while the other is open: 56 px of lane at
        // the phase its partner is at 120, and 96 when its partner is at 80. The
        // ring is on the same lane at the same 0.48, because the whole demand is
        // that nothing about *where* has changed - only about when.
        kind: 'drape',
        strands: [0.3, 0.66],
        reach: 260,
        motion: PULSE_SHUT,
        rings: [may(0.48, 0)],
        spacing: 745,
      },
      // The mid-station breath, and it is the fifth of ten sections rather than
      // the sixth on purpose: a rest in each half is act V's rule, and a rest at
      // the exact midpoint belongs to the half it opens rather than the one it
      // closes.
      { kind: 'open', spacing: 760, rings: [may(0.5, -70)] },
      {
        // The last compulsory ring in the campaign, and the last thing anything
        // ever asks the player for. It asks them to go round something soft, on
        // the side where there is a quarter of the field of open water: the game's
        // final demand is one it would be difficult to fail.
        //
        // It comes *after* the station's rest, which no other required ring in the
        // act does, and that is the shape rather than an accident: the campaign
        // stops, asks one more time, and then never asks again. Thirteen sections
        // follow it and not one of them requires anything.
        kind: 'bloom',
        centre: 0.34,
        radius: 0.075,
        spread: 1.4,
        rings: [must(0.82, 0, 14, 1.75), may(0.5, -150, 13)],
        spacing: 775,
      },
      {
        kind: 'bloom',
        centre: 0.28,
        radius: 0.06,
        spread: 1.8,
        rings: [may(0.78, 0)],
        spacing: 790,
      },
      {
        /*
         * The last moving thing in the campaign: a whole curtain walking, with no
         * required ring anywhere near it. The ring is 130 px past the line rather
         * than in a lane, because a drifting drape carries its lanes with it - so
         * the demand is to aim at where the water will have taken the animal, and
         * then to come out somewhere specific. It is the act's oldest sentence
         * said one last time: you do not control the fish, you control the ocean.
         *
         * Two strands rather than three, and the reason is the safety net rather
         * than the picture. The corridor sweep reads a drifting section through
         * `Section.envelope` - the union of everywhere it ever is - so a walking
         * curtain's lanes are 43 px narrower to the sweep than to the player, and
         * the same three strands that measure 108 px of open water at any instant
         * came out at 68 under the sweep, against the 88 this act shipped with.
         * The lane the player meets is what the picture is; the lane the sweep
         * meets is what the promise is, and the promise is the one that binds.
         */
        kind: 'drape',
        strands: [0.26, 0.7],
        reach: 150,
        motion: SWAY,
        rings: [may(0.35, -130)],
        spacing: 805,
      },
      {
        // The last obstacle in the campaign, and it asks for nothing: a wider
        // spread over smaller bells, so there is more water between them than in
        // any bloom above it. Optional rings only.
        // Smaller bells spread wider. At radius 0.07 / spread 1.25 the envelope
        // landed almost exactly on the sunlit bloom's - 15.3 % closed against
        // 15.4 %, and a *narrower* widest lane - so 'the same animal and less of
        // it' was true of the prose and of nothing on the screen. 0.055 / 1.9
        // measures 11.7 % closed and opens a real 68 px channel through the middle
        // where there were 44, which makes the campaign's last obstacle one the
        // swarm goes through rather than past.
        kind: 'bloom',
        centre: 0.44,
        radius: 0.055,
        spread: 1.9,
        rings: [may(0.44, 0), may(0.8, -80, 13)],
        spacing: 820,
      },
      { kind: 'open', spacing: 835, rings: [may(0.6, -80)] },
    ],
  },
  {
    key: 'midnightHome',
    name: 'The Deep Sea',
    depthMeters: 2500,
    subtitle: 'Nothing can be lost from here',
    zone: ZONE_HOME + 3,
    medium: 'water',
    decor: 'abyss',
    pace: 0.34,
    roughness: 0.35,
    swirl: 0,
    /**
     * The second half begins, and this is where the campaign stops being able to
     * take anything away. `failure: 'none'` - not a difficulty setting and not
     * anything the player asked for. This is the game declining to have an opinion
     * any more, three stations from the end, because the design's failure arc runs
     * out here and the last thing this campaign is about is whether you were good
     * enough.
     *
     * There is nothing in the water from this line down. A station that cannot be
     * lost and still has a wide gate in it is a station making a gesture at
     * difficulty it has already given up on, which is what was here before.
     *
     * Slowblue: and it is the one part of this act the length rebuild did not
     * touch. The first three stations went from nine sections to thirty-five; these
     * three are unchanged to the pixel, because the whole reason act VII is worth
     * having is that it stops, and a rebuild that filled its silence to hit a
     * minute count would have been the plan eating the thing the plan was for.
     */
    failure: 'none',
    sections: [
      { kind: 'open', spacing: 880, rings: [{ x: 0.5, dy: -60, count: 15, scale: 1.5 }] },
      { kind: 'open', spacing: 900, rings: [{ x: 0.3, dy: -80, count: 15, scale: 1.5 }] },
      { kind: 'open', spacing: 920, rings: [{ x: 0.66, dy: -90, count: 15, scale: 1.5 }] },
    ],
  },
  {
    key: 'snow',
    name: 'Marine Snow',
    depthMeters: 4000,
    subtitle: 'The whole world is sinking',
    zone: ZONE_HOME + 4,
    medium: 'water',
    decor: 'abyss',
    pace: 0.28,
    roughness: 0.25,
    swirl: 0,
    failure: 'none',
    /*
     * The one station in the game where the whole world is falling the way the
     * player is. Marine snow is what is left of everything that lived nearer the
     * surface, drifting down for weeks - and because it descends at the swarm's
     * own pace, it is the first time in the campaign the player is not passing
     * *through* the world but going with it.
     *
     * Nothing in the water and a kilometre of it between rings. The level file
     * prices that at about fifty seconds and it measures about twenty-four, and
     * the difference is not a rounding error: the camera takes the *greater* of
     * the forced drift and the swarm's own follow, and from the rain down the
     * carrier's drive is two and a half to three and a quarter times the authored
     * drift. In the last three stations the swarm sets the clock and `pace` is a
     * statement about the water rather than about the pacing. It is still the
     * right shape - each station slower than the last - and the picture is still
     * what the player is doing; it is half a minute rather than a whole one. See
     * the drive-over-drift table in `config/tuning.ts`.
     *
     * That measurement is also what the salt line's couplet is priced against: the
     * authored second is not the second the player spends, everywhere in this act.
     */
    sections: [
      { kind: 'open', spacing: 980, rings: [{ x: 0.44, dy: -60, count: 15, scale: 1.5 }] },
      { kind: 'open', spacing: 1000, rings: [{ x: 0.62, dy: -80, count: 16, scale: 1.5 }] },
      { kind: 'open', spacing: 1020, rings: [{ x: 0.36, dy: -90, count: 16, scale: 1.5 }] },
    ],
  },
  {
    key: 'trenchHome',
    name: 'The Trench Floor',
    depthMeters: 6000,
    subtitle: 'Where it began',
    zone: ZONE_HOME + 5,
    medium: 'water',
    decor: 'trench',
    // The slowest water in the campaign. Nothing is hurrying anything any more.
    pace: 0.22,
    roughness: 0.2,
    swirl: 0,
    failure: 'none',
    /*
     * Six thousand metres, and the first frame of the game.
     *
     * **No score chase and no hard obstacle**, which the design states plainly and
     * which this station takes literally: there is nothing in the water at all.
     * Three sections of open trench, the last of which has nothing in it
     * whatsoever, because what happens there is `render/Homecoming.ts` - the last
     * golden motes reach the floor, small fish gather around them, and out of that
     * light the first shoal forms.
     *
     * 1050, 1100, 1150: the three widest intervals in the campaign, at the slowest
     * pace in it. The act does not end on a beat, it ends by running out of things
     * to be, and the arithmetic of that is a gap that keeps growing until there is
     * nothing on the far side of it.
     */
    sections: [
      { kind: 'open', spacing: 1050, rings: [{ x: 0.5, dy: -60, count: 16, scale: 1.5 }] },
      { kind: 'open', spacing: 1100, rings: [{ x: 0.34, dy: -70, count: 16, scale: 1.5 }] },
      // The last section of the campaign, and there is nothing in it. This is
      // where the circle closes.
      { kind: 'open', spacing: 1150 },
    ],
  },
];

/**
 * Act VII: six stations, the estuary to the trench floor, falling.
 *
 * The act policy is the campaign's own - a station restart, inherited from
 * `makeAct` rather than named here - and the last three stations override it to
 * `'none'`, so the first half can still be got wrong and the second half cannot
 * be. That split is the whole failure arc of the campaign arriving at its end.
 */
export const ACT_HOME: Act = makeAct('home', HOME_LEVELS, {
  direction: 1,
  carrier: 'plankton',
});

/** Re-exported so nothing has to reach into `sim/Failure` to name the last water. */
export { NEVER_FAILS };
