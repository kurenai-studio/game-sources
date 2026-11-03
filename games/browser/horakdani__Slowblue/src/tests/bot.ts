import { ACT_WATER, type Act } from '../src/config/levels';
import { ACT_AIR } from '../src/config/ascent';
import { ACT_THIN } from '../src/config/thinning';
import { DEFAULT_TUNING, type Tuning } from '../src/config/tuning';
import { World } from '../src/sim/World';
import type { Section } from '../src/sim/ObstacleSystem';
import { H, W } from './helpers';

/**
 * Slowblue: scripted stand-in players. Not AI, not a solver - a fixed, dumb policy so
 * that "does skill move the needle" can be measured instead of asserted.
 */

export interface RunResult {
  seconds: number;
  gates: number;
  rescued: number;
  lost: number;
  reforms: number;
  endCount: number;
  endSpread: number;
  score: number;
  reason: string | null;
  /** Campaign only: how far the run got, and what it held on the way. */
  level: number;
  levelsCleared: number;
  ringsHeld: number;
  completed: boolean;
  /** Peak height made up the course, in px. The air probes' progress metric. */
  distance: number;
  /**
   * Highest section id cleared. The progress metric for any act that restarts
   * stations rather than ending runs - see `sim/Failure.ts`. `distance` freezes
   * across a restart and `gates` double-counts a re-flown section; this does
   * neither, so it is the only one of the three that means the same thing in
   * every act.
   */
  progress: number;
  /** Stations begun again. Zero in acts I and II by construction. */
  restarts: number;
}

export type Policy = (world: World, dt: number) => void;

export const passive: Policy = () => {};

/** Widest stretch of water on a horizontal line. */
export function widestGap(world: World, lineY: number): { centre: number; width: number } {
  let best = { centre: W * 0.5, width: 0 };
  let runStart: number | null = null;
  for (let x = 4; x <= W - 4; x += 6) {
    const open = world.obstacles.hit(x, lineY, 1) === null;
    if (open && runStart === null) runStart = x;
    if ((!open || x > W - 10) && runStart !== null) {
      const width = x - runStart;
      if (width > best.width) best = { centre: runStart + width / 2, width };
      runStart = null;
    }
  }
  return best;
}

/**
 * The next wall the shoal actually has to get through.
 *
 * Slowblue: the bot used to aim at `section.lineY` - the section's scoring line - which
 * is only the same thing as "the next wall" for the flat archetypes. A chicane is
 * three staggered rows and a funnel is a converging corridor; aiming at the scoring
 * line means aiming *past* the wall in front of you and swimming straight into it.
 * That is a defect in the measuring instrument, not in the game: it made every
 * multi-row section look unplayable in the sweep. A human looks at the nearest wall.
 */
export function nextWallY(section: Section, centroidY: number, dir: -1 | 1 = -1): number {
  let best = section.lineY;
  let bestDy = Infinity;
  for (const b of section.blobs) {
    // How far up the *course* this blob is. Positive means still ahead.
    const dy = (b.y - centroidY) * dir;
    if (dy <= 10) continue;
    if (dy < bestDy) {
      bestDy = dy;
      best = b.y;
    }
  }
  return best;
}

export interface BotStyle {
  /** Gesture duration for the same 110px stroke: small = flick, large = slow drag. */
  strokeDt: number;
  /** Only steer once the section is this close. Infinity = steer early. */
  reactDistance: number;
  /** Detour to collect rescue pods, whenever no compulsory ring is pending. */
  greedy: boolean;
  /**
   * Detour for an *optional* pod even while a compulsory ring is pending, as long
   * as the pod is met first.
   *
   * Slowblue: this is a second greed and not a stronger one, and it exists because
   * `greedy` measures nothing on the authored campaign. There, a dashed ring is
   * almost always pending - they are dense and they sit on the line the section
   * already asks for - so `greedy`'s "only when nothing is being asked of me"
   * condition is nearly never true, and the greedy bot collects 1.06x the careful
   * bot's fish. That is not the design being safe, it is the instrument being
   * switched off.
   *
   * The choice the authored campaign actually offers is the one the level files
   * describe: plain rings sit *off* the line and are worth a detour. Taking one
   * means leaving the course, spending the ocean's patience, and arriving at the
   * dashed ring late - which is a real decision with a real risk, and is what this
   * flag expresses.
   *
   * `greedy` is deliberately left exactly as it was: the generated-water probe it
   * drives is act I's balance canary and its reading is defended digit-for-digit.
   */
  detour: boolean;
  /** Steer for gaps only, and treat mandatory rings as if they were scenery. */
  ignoreRings: boolean;
  /**
   * Actively steer away from mandatory rings.
   *
   * Slowblue: `ignoreRings` is not enough to falsify "a missed ring ends the run",
   * because a required ring is placed on the line the section already asks for -
   * a bot flying the gaps correctly collects most of them without meaning to,
   * which is the design working. Only a player who refuses one can prove the
   * ending exists.
   */
  dodgeRings: boolean;
  /**
   * Slowblue: the player who never stops pushing forward.
   *
   * Every other policy in this file - and every probe in `e2e/` - gates its
   * forward stroke on `behindFraction > 0.5..0.62`, which is to say **it stops
   * pushing the moment it reaches the camera's anchor**. That was a reasonable
   * model of a careful hand and it turned out to make the whole repo blind to the
   * one thing a real player reported doing: driving the swarm down a falling act
   * as hard as it will go, ahead of the course, permanently.
   *
   * It was blind in a way that could not be noticed, either. `World.step`'s camera
   * follow pins the swarm at exactly the anchor for anyone who pushes, so
   * `behindFraction > 0.62` is unconditionally true and the gate never fired -
   * measured at 0.620 on every act and every style. A gate that is always open
   * looks exactly like no gate at all until the day something bounds the thing it
   * was gating on.
   *
   * A rusher strokes diagonally, which is what a thumb actually does: the same
   * lateral correction as the careful hand, with the forward component always on.
   */
  rush: boolean;
  /**
   * Slowblue: a rusher that reads the frame and brakes.
   *
   * The point of a cost is that it can be avoided, and the only way to know
   * whether it can is to measure a hand that tries. `careful` never goes fast
   * enough to be charged and `rush` never stops - between them they prove that
   * the extremes behave, and neither of them is the interesting player.
   *
   * This one pushes exactly as hard as `rush` until `World.ablating` says the
   * medium has started taking the swarm apart, and then it strokes *backwards*
   * along the course until it stops. That is act V's stated verb - **brake, and
   * accept the medium** - written as eleven lines of policy, and if this hand
   * cannot fly the act faster than the careful one and cheaper than the blind one,
   * the mechanic is a rail rather than a demand.
   */
  brake: boolean;
}

export function makeAimBot(style: Partial<BotStyle> = {}): Policy {
  const strokeDt = style.strokeDt ?? 0.09;
  const react = style.reactDistance ?? Infinity;
  const greedy = style.greedy ?? false;
  const detour = style.detour ?? false;
  const ignoreRings = style.ignoreRings ?? false;
  const dodgeRings = style.dodgeRings ?? false;
  const rush = style.rush ?? false;
  const brake = style.brake ?? false;
  let cooldown = 0;
  return (world, dt) => {
    cooldown -= dt;
    if (cooldown > 0) return;
    cooldown = 0.1;
    const c = world.swarm.centroid();
    if (c.count === 0) return;
    const next = world.obstacles.sections.find((s) => !s.passed && world.u(s.lineY) > world.u(c.y));
    if (next === undefined) return;

    const wallY = nextWallY(next, c.y, world.direction);
    let targetX = widestGap(world, wallY).centre;
    // A dashed ring is not a detour any more, it is the course: a player who
    // ignores one loses the run, so the stand-in player has to steer for it too.
    // Anything less and the probe would be measuring a game nobody can play.
    const ring = ignoreRings || dodgeRings ? null : requiredRing(world, c.y);
    if (dodgeRings) {
      const avoid = requiredRing(world, c.y);
      // Keep flying the section, just never through the ring: the far edge of the
      // widest gap from it.
      if (avoid !== null) targetX = avoid.x < W * 0.5 ? W * 0.92 : W * 0.08;
    }
    if (ring !== null) targetX = ring.x;
    else if (greedy) {
      const pod = world.rescue.pods.find(
        (p) => !p.merged && world.u(p.y) > world.u(c.y) && world.u(p.y) - world.u(c.y) < 420,
      );
      if (pod !== undefined) targetX = pod.x;
    }
    // The authored campaign's actual offer: an optional ring off the line, met
    // before the dashed one the section is asking for. Taking it means arriving
    // late at something compulsory, which is the whole of the trade.
    if (detour) {
      const early = world.rescue.pods.find(
        (p) =>
          !p.merged &&
          !p.required &&
          world.u(p.y) > world.u(c.y) &&
          world.u(p.y) - world.u(c.y) < 460 &&
          (ring === null || world.u(p.y) < world.u(ring.y)),
      );
      if (early !== undefined) targetX = early.x;
    }
    const errX = targetX - c.x;
    const screenY = world.worldToScreenY(c.y);
    const withinReach = ring !== null || world.u(next.lineY) - world.u(c.y) < react;
    // Sitting in the ring is what absorbs it, so stop pushing forward once the
    // shoal is on top of one.
    const onRing = ring !== null && Math.abs(c.y - ring.y) < 90;

    const push = Math.max(-110, Math.min(110, errX));
    if (brake && world.ablating > 0.35) {
      // Against the course, and only laterally corrected: a braking stroke that
      // still steers is not braking, it is turning.
      world.injectStroke(c.x, c.y, c.x, c.y - world.direction * 90, strokeDt);
      return;
    }
    if (rush || brake) {
      // One diagonal stroke, every time, and the only thing that stops it is a
      // ring the swarm is already sitting in - a rusher still has to let a
      // compulsory ring close or it is not playing the game, it is falling.
      if (!onRing) world.injectStroke(c.x, c.y, c.x + push, c.y + world.direction * 90, strokeDt);
      return;
    }
    if (withinReach && Math.abs(errX) > 12) {
      world.injectStroke(c.x, c.y, c.x + push, c.y, strokeDt);
    } else if (world.behindFraction(screenY) > 0.62 && !onRing) {
      world.injectStroke(c.x, c.y, c.x, c.y + world.direction * 90, strokeDt);
    }
  };
}

/** The nearest un-absorbed mandatory ring ahead of the shoal, if there is one. */
export function requiredRing(world: World, centroidY: number): { x: number; y: number } | null {
  let best: { x: number; y: number } | null = null;
  let bestDy = Infinity;
  for (const p of world.rescue.pods) {
    if (p.merged || !p.required) continue;
    // Distance up the course. Negative means the swarm is already past it.
    const dy = world.u(p.y) - world.u(centroidY);
    if (dy < -140 || dy > 700) continue;
    if (dy < bestDy) {
      bestDy = dy;
      best = { x: p.x, y: p.y };
    }
  }
  return best;
}

/**
 * Slowblue: deliberately splits the shoal around rock sections to take the pod in each
 * side channel, then squeezes it back together. Exists to answer one question:
 * is splitting a *tactic* (pays off) or just a thing that can happen?
 */
export function makeSplitBot(): Policy {
  const fallback = makeAimBot({ strokeDt: 0.4, greedy: true });
  let cooldown = 0;
  return (world, dt) => {
    const c = world.swarm.centroid();
    if (c.count === 0) return;
    // A central mass with a channel either side, in whichever medium: the water's
    // rock and the air's cumulus tower are the same tactical object, and a probe
    // that only knows the water's name silently stops being a split bot in act II.
    // The list is `SPLITTABLE` in `World.ts` and has to stay it - the acts above
    // the anvil grew three more of these masses and this find silently ignored
    // every one, which is the failure mode the comment above already names.
    const SPLIT_KINDS = new Set(['rock', 'tower', 'column', 'plume', 'canopy']);
    const rock = world.obstacles.sections.find(
      (s) =>
        SPLIT_KINDS.has(s.kind) &&
        !s.passed &&
        world.u(s.lineY) > world.u(c.y) &&
        world.u(s.lineY) - world.u(c.y) < 700,
    );
    if (rock === undefined) {
      fallback(world, dt);
      return;
    }
    cooldown -= dt;
    if (cooldown > 0) return;
    cooldown = 0.1;

    // The big central blob is what the shoal has to be split around.
    let core = rock.blobs[0]!;
    for (const b of rock.blobs) if (b.r > core.r) core = b;
    // ...and the two pods mark where the channels actually are. Aiming the halves at
    // a fixed +-110px offset instead put them into the rock's shoulders: measured, the
    // bot took 24 rock deaths a run against the careful bot's 9, and died at 19s.
    const channels = rock.podHints.map((p) => p.x).sort((a, b) => a - b);
    const leftLane = channels[0] ?? core.x - core.r * 1.4;
    const rightLane = channels[channels.length - 1] ?? core.x + core.r * 1.4;

    const approach = world.u(rock.lineY) - world.u(c.y);
    const spread = world.swarm.spread();
    // Every stroke carries a forward component: stalling in front of a rock is how
    // the first version of this bot died at 18s.
    const forward =
      world.direction *
      (world.behindFraction(world.worldToScreenY(c.y)) > 0.55 ? 70 : 25);

    if (approach > 420) {
      // Line the shoal up with the rock's centre, or there is nothing to split around.
      const err = Math.max(-100, Math.min(100, core.x - c.x));
      world.injectStroke(c.x, c.y, c.x + err, c.y + forward, 0.35);
      return;
    }
    if (approach > 200) {
      // Prise it apart: one current per channel, aimed where the channel is.
      world.injectStroke(c.x - 25, c.y, leftLane, c.y + forward, 0.3);
      world.injectStroke(c.x + 25, c.y, rightLane, c.y + forward, 0.3);
      return;
    }
    if (spread > 92) {
      // Past the rock: squeeze the halves back into one body.
      world.injectStroke(c.x - 135, c.y + forward, c.x - 25, c.y + forward, 0.3);
      world.injectStroke(c.x + 135, c.y + forward, c.x + 25, c.y + forward, 0.3);
      return;
    }
    world.injectStroke(c.x, c.y, c.x, c.y + world.direction * 90, 0.4);
  };
}

/**
 * Slowblue: there is no act II probe pair, and that is the point.
 *
 * There used to be: a climb bot that hunted thermals and a glide bot that pumped
 * height, because act II had a second verb in it and needed its own instruments
 * to measure. The thermals are gone (see `config/ascent.ts`), so what measures
 * act II is exactly what measures act I - `makeAimBot` and `makeSplitBot`, with
 * nothing added and nothing told about the medium.
 *
 * That is the acceptance test for the whole change, and it is a stronger one than
 * any number the sweep prints: if act I's policies fly act II without being
 * taught anything, the two acts really are one game.
 */
/**
 * Slowblue: the probe plays *generated* water by default.
 *
 * The design questions the sweep answers - does skill separate, is a pod a choice,
 * is splitting a verb - are questions about the simulation, and they need water
 * nobody has hand-tuned to be honest. The authored campaign is measured separately,
 * by `playCampaign`, where the question is a different one: can it be flown at all.
 */
export function playRun(
  seed: number,
  policy: Policy,
  overrides: Partial<Tuning> = {},
  maxSeconds = 120,
  campaign = false,
  act: Act = ACT_WATER,
): RunResult {
  // Slowblue: this used to pin `agentCount: 100` so the probe never wobbled when the
  // default moved. It also meant every balance number in this repo was measured on a
  // shoal the shipped game does not deal - so the pin is gone and the probes run the
  // real defaults. Anything that wants a specific size passes it in `overrides`.
  const world = new World(W, H, seed, { ...DEFAULT_TUNING, ...overrides }, campaign, act);
  const dt = 1 / 60;
  for (let i = 0; i < maxSeconds * 60 && world.run.phase === 'running'; i++) {
    policy(world, dt);
    world.step(dt);
  }
  return {
    seconds: Number(world.run.time.toFixed(1)),
    gates: world.run.gates,
    rescued: world.run.rescued,
    lost: world.run.lost,
    reforms: world.run.reforms,
    endCount: world.shoalCount,
    endSpread: Number(world.averageSpread.toFixed(1)),
    score: world.run.score,
    reason: world.run.reason,
    level: world.run.level,
    levelsCleared: world.run.levelsCleared,
    ringsHeld: world.run.ringsHeld,
    completed: world.run.completed,
    distance: Math.round(world.run.distance),
    progress: world.run.furthestSection + 1,
    restarts: world.run.restarts,
  };
}

/** One run of the authored campaign, given as much time as the campaign takes. */
export function playCampaign(seed: number, policy: Policy, maxSeconds = 600): RunResult {
  return playRun(seed, policy, {}, maxSeconds, true);
}

/** One run of the authored air act. The act II analogue of `playCampaign`. */
export function playAir(
  seed: number,
  policy: Policy,
  overrides: Partial<Tuning> = {},
  maxSeconds = 900,
): RunResult {
  return playRun(seed, policy, overrides, maxSeconds, true, ACT_AIR);
}

/** One run of the authored upper-air act. */
export function playThin(
  seed: number,
  policy: Policy,
  overrides: Partial<Tuning> = {},
  maxSeconds = 900,
): RunResult {
  return playRun(seed, policy, overrides, maxSeconds, true, ACT_THIN);
}

/**
 * Slowblue: act III's own probe, and the only one in the repo about *when* rather
 * than *where*.
 *
 * ## What this bot used to measure, and why the answer was always zero
 *
 * The first version tested the claim as the design first stated it: **the same
 * stroke is worth more if it is made in the right half of the breath.** It pushed
 * long into rising air and short into sinking air, against a control that pushed
 * the same regardless, on identical cadence and identical mean effort.
 *
 * It measured 0.87 - timing *cost* the player ground - and no value of
 * `LayeredFlow.SINK` moved it, because the claim is false in this simulation and
 * cannot be tuned into being true. Everything the swarm feels arrives as one
 * velocity: `water = laid + wave`, and a body is dragged toward it. Distance over
 * a fixed time at a fixed cadence is therefore a *linear* functional of that sum,
 * and correlating your half of it with the medium's half cannot change the
 * expectation of a linear functional. Measured across eleven seeds, pushing with
 * the lift scored 20.6 sections, pushing *against* it 21.3, and ignoring it 20.9:
 * three ways of spending the same effort, worth the same to three decimal places.
 *
 * ## What it measures now, which is the act's actual verb
 *
 * The design's own sentence for act III is not "push at the right moment", it is
 * **wait, and choose a layer** - and choosing is worth something, because the
 * bands run at up to 86 px/s while the best a hand can do up here is 57. Being in
 * the right one is worth more than any stroke, and it is a *lateral* problem.
 *
 * The nonlinearity that makes reading the air pay is the one the game has had
 * since the trench floor: **a stroke is one stroke, and it goes one way.** A hand
 * spent holding station is not spent getting into position. So rising air is not
 * worth more push - it is worth not *having* to push, which frees the same hand
 * to cross a band boundary, line up on a ring, or leave a wind that is taking the
 * swarm the wrong way. Sinking air is when that freedom is spent holding on.
 *
 * That reallocation was measured too, and it does not pay either: 21.9 sections
 * against 24.5 for the same hand ignoring the wave. **So there is no stroke
 * policy that turns the gravity wave into a bonus**, and the design document has
 * been corrected rather than the number tuned - see DESIGN-ASCENT §7. What the
 * wave is, and what act III's tests now assert, is a *force*: it really moves the
 * swarm, a net-lift cell really carries it and a net-sink cell really takes
 * ground away, and being caught in the wrong one costs position and time. That
 * is worth reading, and it is worth drawing. It is not worth a stroke schedule.
 *
 * `timed` is kept, defaulting off, so the finding stays reproducible: anyone who
 * wonders whether the wave could be surfed can run the fork rather than rederive
 * it. The default policy is the one that measures best and is act III's competent
 * player everywhere in the repo.
 */
export function makeWaveBot(
  style: Partial<BotStyle> & { timed?: boolean; invert?: boolean } = {},
): Policy {
  const timed = style.timed ?? false;
  const sign = style.invert === true ? -1 : 1;
  const strokeDt = style.strokeDt ?? 0.35;
  /** The one stroke length both bots use, so effort can never differ. */
  const PUSH = 90;
  /**
   * How much lateral error each bot will carry before it spends its stroke
   * sideways. The timed bot's two average the blind bot's one, so the comparison
   * is about *allocation* and never about how much work is being done.
   */
  const BLIND_SLACK = 22;
  const LIFTED_SLACK = 6;
  const SINKING_SLACK = 38;
  let cooldown = 0;
  return (world, dt) => {
    cooldown -= dt;
    if (cooldown > 0) return;
    cooldown = 0.1;
    const c = world.swarm.centroid();
    if (c.count === 0) return;
    const next = world.obstacles.sections.find((s) => !s.passed && world.u(s.lineY) > world.u(c.y));
    if (next === undefined) return;

    const ring = requiredRing(world, c.y);
    const targetX =
      ring !== null ? ring.x : widestGap(world, nextWallY(next, c.y, world.direction)).centre;
    const errX = targetX - c.x;

    // Negative is upward. On a station with no wave at all both bots read zero
    // and behave identically, which is what makes the comparison a measurement of
    // the wave rather than of the stations that happen to have one.
    const lift = timed ? world.layers.waveAt(c.y, world.breathTime) * sign : 0;
    const slack = lift < -1 ? LIFTED_SLACK : lift > 1 ? SINKING_SLACK : BLIND_SLACK;

    if (Math.abs(errX) > slack) {
      const push = Math.max(-110, Math.min(110, errX));
      world.injectStroke(c.x, c.y, c.x + push, c.y, strokeDt);
      return;
    }
    world.injectStroke(c.x, c.y, c.x, c.y + world.direction * PUSH, strokeDt);
  };
}

/**
 * Slowblue: the bot that disproved act IV's verb, kept as the control that does it.
 *
 * ## What it was written to show
 *
 * `makeAimBot` is the stand-in player for every act with a medium in it, and it
 * is correct in all of them: it pushes when the swarm has fallen behind, and the
 * medium's drag takes the push away again, so pushing is a thing you do
 * continuously and the bot's bang-bang cadence is exactly how the game is played.
 *
 * The suspicion was that none of that survives vacuum, on two arguments that both
 * sound right:
 *
 *   1. **A stroke lays an attractor, not a shove.** A well is a *place*, and a
 *      body with no drag that falls into one does not stop there - it falls
 *      through, comes back, and orbits. A well laid ninety pixels ahead of the
 *      swarm, which is what the aim bot lays, is therefore not a push forward.
 *      It is a tether.
 *   2. **Momentum is kept.** So the gesture ought to be "start it, and then do
 *      not touch it" - which was the sentence the design gave act IV, and which
 *      no bot in the repo was saying.
 *
 * So this bot says it: it reads the swarm's *velocity* rather than its position,
 * lays a well a long way ahead - far enough that the swarm is still accelerating
 * toward it when the well's own half-life takes it away, so what is left is speed
 * rather than a captured orbit - and then waits.
 *
 * ## What it measured
 *
 * **It lost, and it lost monotonically.** Eleven seeds, 300 s, act IV's 36
 * sections, at the shipped `potentialStrength`: this bot at its default 300 px
 * lead cleared 2.0, at a 150 px lead and half the wait 3.0, at a 460 px lead and
 * a longer wait **0.0** - against the aim bot's 10.2. Every step toward letting
 * go cost ground, and the purest form of it made none at all in five minutes.
 *
 * That is a real answer rather than a failed instrument, and the design took it:
 * act IV's verb is now *aim ahead of them* (DESIGN-ASCENT §8), because what is
 * actually different about vacuum is *when* a stroke has to be made, not how
 * rarely. This bot stays because a fact needs something to keep being measured
 * by - `tools/space.sweep.ts` runs it as the control, and `tests/orbit.test.ts`
 * pins the ordering so the verb and the physics cannot drift apart again in
 * silence.
 */
export function makeOrbitBot(
  style: { lead?: number; hold?: number; cruise?: number; strokeDt?: number } = {},
): Policy {
  /** How far ahead the well is laid, in px. Well outside the swarm's own radius. */
  const lead = style.lead ?? 300;
  /** Seconds between strokes. Long: this is an act about letting go. */
  const hold = style.hold ?? 0.9;
  /** Forward speed (px/s) the bot is happy with. Above this it does nothing. */
  const cruise = style.cruise ?? 70;
  const strokeDt = style.strokeDt ?? 0.16;
  let cooldown = 0;
  return (world, dt) => {
    cooldown -= dt;
    if (cooldown > 0) return;
    const c = world.swarm.centroid();
    if (c.count === 0) return;
    cooldown = hold;

    // Mean forward speed, in course coordinates: positive is toward the front.
    let vy = 0;
    let n = 0;
    for (const a of world.swarm.agents) {
      if (!a.alive || a.faction !== 0) continue;
      vy += a.vy;
      n++;
    }
    const forward = n > 0 ? (-world.direction * vy) / n : 0;

    // Where the course wants the swarm to be across the frame. Same reading as
    // every other bot: the ring if one is pending, otherwise the widest gap.
    const next = world.obstacles.sections.find((s) => !s.passed && world.u(s.lineY) > world.u(c.y));
    const ring = requiredRing(world, c.y);
    let targetX = c.x;
    if (ring !== null) targetX = ring.x;
    else if (next !== undefined) targetX = widestGap(world, nextWallY(next, c.y, world.direction)).centre;

    const errX = Math.max(-160, Math.min(160, targetX - c.x));
    // Already at cruise and on line: let go. This branch is the act.
    if (forward >= cruise && Math.abs(errX) < 40) return;
    // The well goes a long way ahead and off to the side it wants: one gesture
    // that says both "keep going" and "over there", which is the only gesture
    // this game has ever had.
    const ahead = forward >= cruise ? lead * 0.35 : lead;
    world.injectStroke(c.x, c.y, c.x + errX, c.y + world.direction * ahead, strokeDt);
  };
}

export function mean(xs: number[]): number {
  return xs.reduce((a, b) => a + b, 0) / xs.length;
}

/**
 * One style across every seed, with a **fresh bot for each**.
 *
 * Slowblue: all five sweep tools built one policy and then ran the whole seed list
 * through it, so any bot carrying state - `makeAimBot`'s stroke clock,
 * `makeWaveBot`'s phase, `makeOrbitBot`'s cruise memory - started seed two
 * wherever seed one left it. The runs were not independent, which is a
 * methodological fault whatever it does to the numbers: a mean over eleven
 * correlated samples does not have the error bar it looks like it has, and the
 * same tool run twice against the same code could not be relied on to agree,
 * which is exactly the property a regression instrument is for.
 *
 * DESIGN-ASCENT §18 recorded the symptom - two tables in that document quoting
 * 8.6 and 9.2 for the same act - as a wart to be lived with. This is the fix,
 * in one place, so no tool can be written the old way by accident.
 */
export function perSeed<T>(make: () => Policy, play: (seed: number, policy: Policy) => T): T[] {
  return SEEDS.map((seed) => play(seed, make()));
}

/**
 * The water every probe is measured on.
 *
 * Slowblue: this was five seeds, and five is not enough to defend the margins the probes
 * assert. Seed-to-seed score variation is 0.4-0.6 of the mean - larger than most of the
 * differences being compared - so a single unlucky course could turn "careful play beats
 * flailing by 30%" red without anything about the game having changed. Measured across
 * shoal sizes, the five-seed answer swung between 1.16x and 1.88x while the eleven-seed
 * answer for the same configuration stayed inside a tenth. Eleven costs about a second
 * per probe and buys an assertion that means what it says.
 */
export const SEEDS = [11, 202, 3003, 40004, 55555, 7, 91, 1234, 60606, 8888, 42];
