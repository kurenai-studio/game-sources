/**
 * Slowblue: every number that changes how the water and the swarm *feel* lives here.
 * The debug panel mutates this object live; nothing else may hardcode feel values.
 */

/**
 * Which medium a level is played in.
 *
 * The campaign is one gesture through seven of them, and the list below is the
 * whole arc of the game read as a density curve: sea, sky, the top of the sky,
 * nothing at all, and then the same list backwards as the air comes back. The
 * numbers a kind resolves to live in `Tuning`; see `src/sim/Medium.ts`.
 *
 *   * `water`   - act I, and the second half of act VII. The densest thing here.
 *   * `air`     - act II. Water with the density taken out of it.
 *   * `thinAir` - act III. Air with most of *that* taken out again: a stroke
 *                 barely grips, and what it lays lasts most of a minute.
 *   * `space`   - act IV. There is no medium. A stroke lays gravity instead, and
 *                 nothing drags a body toward anything.
 *   * `plasma`  - act V. The air coming back, at eight kilometres a second.
 *   * `cloud`   - act VI's first half: saturated air, the densest sky there is.
 *   * `stream`  - act VI's last stations. Running water grips harder than the sea.
 */
export type MediumKind = 'water' | 'air' | 'thinAir' | 'space' | 'plasma' | 'cloud' | 'stream';

export interface Tuning {
  // --- water ---
  /** Water velocity (px/s) injected per gesture sample at the impulse centre. */
  flowStrength: number;
  /** Base gesture radius in px. Modulated down by finger speed. */
  flowRadius: number;
  /** Seconds for an undisturbed flow cell to lose half its speed. */
  flowDecayHalfLife: number;
  /** Neighbour blending per second. Spreads a stroke into a coherent current. */
  flowDiffusion: number;
  /** Hard ceiling on water speed (px/s). Stops a flick from producing nonsense. */
  flowMaxSpeed: number;
  /**
   * Extra decay rate per 1000 px/s of local water speed - turbulent dissipation.
   * This is what makes a hard flick a *short, precise* tool instead of a mess:
   * violent water dies fast, gentle water lingers.
   */
  flowTurbulence: number;
  /** How strongly water drags an agent toward the local water velocity (1/s). */
  flowCoupling: number;
  /** Peak speed (px/s) of the ocean's own current. 0 = dead still water. */
  ambientStrength: number;
  /** How much of the pressure escalation is spent roughening the ocean. */
  ambientRamp: number;

  // --- swarm ---
  alignment: number;
  cohesion: number;
  separation: number;
  separationRadius: number;
  perceptionRadius: number;
  obstacleAvoidance: number;
  /** Seconds of velocity look-ahead used for obstacle prediction. */
  avoidLookahead: number;
  /** Self-propulsion toward the migration direction (1/s). */
  migrationForce: number;
  /**
   * How fast the shoal swims up the course on its own (px/s).
   *
   * This is the single number that decides whether the ocean is a threat. It used to
   * be `cruiseSpeed`, which is the speed every *boid* term aims at - so a shoal left
   * completely alone swam at about the speed of the forced drift, the camera's monotone
   * follow locked onto it, and the strand line could never reach a shoal that was not
   * physically blocked. Keeping it well under `worldSpeed` is what makes the water the
   * player lays the reason they are still on screen.
   */
  migrationSpeed: number;
  cruiseSpeed: number;
  maxSpeed: number;
  maxAccel: number;
  /** Organic wander amplitude (px/s^2). */
  noise: number;
  agentCount: number;

  // --- world ---
  /** Forced camera drift (px/s): the pressure that makes stalling a real cost. */
  worldSpeed: number;
  /** Extra drift fraction gained per 10000px travelled. The endgame clock. */
  pressureRamp: number;
  /**
   * How many times its own station's drift a swarm may make before the medium
   * starts taking it apart. See `Medium.drag`, which is zero in five of the seven
   * media, so this does nothing at all outside act V's middle.
   *
   * 1.0 would mean "you may never be faster than the water", which is not a game,
   * it is a rail - the whole point of a stroke is that it moves the swarm. What is
   * wanted is a band the player can spend and get back: below this the fall is
   * free, above it the fall is on the clock.
   */
  terminalFactor: number;
  /**
   * Seconds of flying under the terminal that pay off one carrier's worth of heat.
   *
   * Deliberately generous against `Medium.drag`'s rate, and for the same reason
   * `strandedFor` decays at twice the speed it accumulates: a pressure the player
   * cannot get out from under is not a demand, it is a countdown.
   */
  ablationCool: number;
  /** Inertia added per rescued agent - growth must cost manoeuvrability. */
  inertiaPerAgent: number;
  /** Radius (px) of a rescue pod's contact ring. */
  rescueRadius: number;
  /** Fraction of the current shoal that must be inside the ring to make contact. */
  rescueFraction: number;

  // --- air (act II onward; water reads the fields above) ---
  /*
   * Slowblue: the air used to be a different *game* - a lift field, gravity, and a
   * flock that fell out of the sky unless the player found a thermal. It was
   * mechanically sound and it was the wrong game: Slowblue's one verb is "steer the
   * medium and the life in it follows", and an act that replaces that verb with
   * "hunt for the resource" is a second game wearing the first one's clothes.
   *
   * So the air is now the water's physics with the water's density taken out of
   * it. Same stroke, same drag term, same forced drift making the clock; what
   * changes is *how the medium answers* - a lighter grip, a gust that outlives
   * the hand that laid it, and a flock that is faster and cheaper to carry than a
   * shoal. Every number below is one of those four sentences.
   */
  /**
   * How strongly air drags an individual (1/s), against the water's
   * `flowCoupling`. Lower, because thin air has less to push with: a stroke
   * *persuades* a flock where the same stroke *shoves* a shoal, and the
   * difference is felt as glide rather than as weakness.
   */
  airCoupling: number;
  /**
   * Seconds for a laid gust to lose half its speed. **Longer than the water's**,
   * which is the one place air is the more generous medium: there is almost
   * nothing up here to dissipate a moving body of air, so a stroke drawn once
   * across the glass keeps working long after the finger has left it. This is
   * what makes act II the calmer act to play with the same fingers.
   */
  airFlowHalfLife: number;
  /**
   * Ceiling on laid air speed (px/s). Above the water's, because wind is the one
   * thing in nature that is unambiguously faster than current - and because the
   * flock itself flies faster, so the medium has to be able to out-run it.
   */
  airFlowMaxSpeed: number;
  /**
   * Unaided self-drive up the course in air (px/s), against the water's
   * `migrationSpeed`.
   *
   * **Lower than the water's**, which is the opposite of what it sounds like it
   * should be, and it is the number that decides whether act II is a game. This
   * is decision 37 one medium up: a body of life that makes way faster than the
   * drift that carries the camera can never be left behind, so nothing the player
   * does matters. Started at 92 - a bird flies faster than a fish, which is true
   * and irrelevant - and measured, a flock with *no input at all* survived 96
   * seconds, cleared five sections and collected forty birds from rings it merely
   * drifted through. At 48 doing nothing is over in twenty-five seconds and the
   * skill multiplier is 22x, against the water sweep's 18x. The wind is what
   * carries a flock up here; wings only keep it from falling behind.
   */
  airMigrationSpeed: number;
  /** The migration force in air (1/s). Wings bite harder than fins. */
  airMigrationForce: number;

  // --- thin air (act III onward) ---
  /*
   * Slowblue: three numbers, and they are the same three sentences the air is made
   * of, said harder. Above the tropopause there is a fortieth of the atmosphere
   * left and then a thousandth of it; a stroke has almost nothing to push with,
   * what it does push keeps moving because there is nothing to stop it, and a
   * spore has no wings at all. The act's whole verb - wait, then choose a layer -
   * falls out of those three, which is why it needs no fourth.
   */
  /** How strongly the upper atmosphere drags a mote (1/s). Barely at all. */
  thinCoupling: number;
  /** Seconds for a laid current to halve up here. The longest in the game. */
  thinFlowHalfLife: number;
  /**
   * Unaided drive up the course for a mote (px/s).
   *
   * Deliberately tiny, and for the reason `airMigrationSpeed` is small squared: a
   * spore does not fly. Everything that lifts it is the medium, so a station is
   * won by putting the swarm in the band that is going the right way, and lost by
   * sitting in the one that is not.
   */
  thinMigrationSpeed: number;

  // --- space (act IV) ---
  /*
   * There is no medium here, so these are not medium numbers - they are the
   * numbers of the thing that replaces it. A touch lays a gravity well, the
   * motes fall around it, and nothing damps anything. See `sim/PotentialField.ts`.
   */
  /** Peak acceleration (px/s^2) at the mouth of a laid gravity well. */
  potentialStrength: number;
  /** Radius (px) a laid well reaches. Wide: gravity has no edge. */
  potentialRadius: number;
  /** Seconds for a well to lose half its pull. Long enough to be a decision. */
  potentialHalfLife: number;

  // --- hazards ---
  /** Multiplies every standing current the course lays down. 0 = calm course. */
  vortexStrength: number;
  /** A hunter's cruise speed (px/s). Compare `cruiseSpeed` - it should out-run a drifting shoal. */
  predatorSpeed: number;
  /**
   * How strongly water drags a hunter. Deliberately far below `flowCoupling`: a
   * hunter is heavy, so pushing one aside costs a real stroke, not a flick.
   */
  predatorCoupling: number;
  /** How hard an individual breaks away from a nearby hunter. */
  predatorFear: number;
}

export const DEFAULT_TUNING: Tuning = {
  flowStrength: 300,
  flowRadius: 86,
  flowDecayHalfLife: 1.05,
  flowDiffusion: 3.2,
  flowMaxSpeed: 420,
  flowTurbulence: 0,
  flowCoupling: 3.4,
  ambientStrength: 55,
  ambientRamp: 0.5,

  alignment: 1.5,
  // Cohesion + a wide perception radius measurably beat the alternatives in the
  // headless sweep: tighter shoal, fewer stragglers culled, longer runs.
  cohesion: 1.35,
  separation: 3.4,
  // Slowblue: spacing is how a 25-strong shoal keeps the footprint the course is authored
  // around. The gaps in `levels.ts` run from 0.58 to 0.26 of the width, and precision
  // only means something if the shoal is wide enough to have to be aimed: at the old
  // 13 px spacing a 25-fish shoal was 33 px across, went through everything, and every
  // play style scored the same. At 25 px it is ~73 px across - the same as the hundred
  // fish this game was tuned with - and careful play is worth 1.65x a panic-flick
  // again. Measured over 11 seeds; see decision 38.
  separationRadius: 25,
  perceptionRadius: 83,
  obstacleAvoidance: 9,
  avoidLookahead: 0.45,
  migrationForce: 1.5,
  migrationSpeed: 75,
  cruiseSpeed: 118,
  maxSpeed: 300,
  maxAccel: 900,
  noise: 55,
  // Slowblue: a hundred fish filled a third of a phone screen with one solid mass, which
  // hides the two things the game is actually about - the shape the water pushes the
  // shoal into, and the fact that individuals are being lost. 72 reads as a shoal
  // rather than as a blob, and it makes a rescued pod of a dozen a visible event.
  //
  // It is also as far down as the number can go. Measured over 15 seeds, the skill
  // ordering holds at 72 (careful play scores 1.8x a panic-flick) and *inverts* at 60
  // (0.94x): below about seventy the shoal is small enough that attrition ends a
  // careful run before its patience can pay for anything. See decision 38.
  agentCount: 25,

  worldSpeed: 68,
  // Lowered from 1.6 when the course grew four depth zones: at 1.6 the camera
  // out-ran a competent shoal at ~5000px, which is section 6 - so nothing past the
  // first zone was reachable by anyone, and three quarters of the game was content
  // nobody would ever see. See IMPLEMENTATION_NOTES, decision 13.
  pressureRamp: 1.15,
  // Slowblue: 1.25 rather than something tighter, measured on `tools/rush.sweep.ts`.
  // See `Medium.drag` for the report this answers and for why the fix is the
  // medium's rather than the camera's.
  terminalFactor: 1.6,
  ablationCool: 0.55,
  inertiaPerAgent: 0.012,
  rescueRadius: 62,
  rescueFraction: 0.32,

  // The air, owned by `tools/air.sweep.ts` - the same harness and the same
  // scripted players act I is measured with, which is the clearest single
  // statement that the two acts are now one game.
  airCoupling: 2.5,
  airFlowHalfLife: 1.7,
  airFlowMaxSpeed: 520,
  airMigrationSpeed: 48,
  airMigrationForce: 1.7,

  // The upper atmosphere, owned by `tools/thin.sweep.ts`.
  thinCoupling: 1.15,
  thinFlowHalfLife: 3.4,
  thinMigrationSpeed: 20,

  // Vacuum, owned by `tools/space.sweep.ts`.
  /*
   * Swept, not chosen. `tools/space.sweep.ts`'s well grid, eleven seeds, act IV's
   * 36 sections in 240 s:
   *
   *   pull=150  6.3 sections    pull=300  9.0 sections
   *   pull=210  7.2 sections    pull=420 11.0 sections
   *
   * Monotone and clean, and the half-life barely moves it - which is the useful
   * half of the finding: what act IV is short of is *pull*, not persistence. 300
   * is a quarter more ground for a quarter more gravity, and it is deliberately
   * not 420: past about there the swarm arrives at a laid well fast enough to
   * swing round it and come back, and the input stops reading as "throw them that
   * way" and starts reading as "trap them there".
   */
  potentialStrength: 300,
  potentialRadius: 150,
  potentialHalfLife: 2.6,

  vortexStrength: 1,
  predatorSpeed: 132,
  predatorCoupling: 1.15,
  predatorFear: 5,
};

export const TUNING_LIMITS: Record<keyof Tuning, [number, number, number]> = {
  flowStrength: [0, 1200, 5],
  flowRadius: [20, 260, 2],
  flowDecayHalfLife: [0.1, 4, 0.05],
  flowDiffusion: [0, 12, 0.1],
  flowMaxSpeed: [80, 1500, 10],
  flowTurbulence: [0, 8, 0.1],
  flowCoupling: [0, 12, 0.1],
  ambientStrength: [0, 200, 1],
  ambientRamp: [0, 2, 0.05],
  alignment: [0, 6, 0.05],
  cohesion: [0, 6, 0.05],
  separation: [0, 12, 0.05],
  separationRadius: [4, 40, 0.5],
  perceptionRadius: [10, 120, 1],
  obstacleAvoidance: [0, 30, 0.25],
  avoidLookahead: [0, 1.5, 0.01],
  migrationForce: [0, 8, 0.05],
  migrationSpeed: [0, 300, 2],
  cruiseSpeed: [0, 300, 2],
  maxSpeed: [40, 700, 5],
  maxAccel: [100, 3000, 10],
  noise: [0, 300, 1],
  agentCount: [20, 500, 5],
  worldSpeed: [0, 250, 1],
  pressureRamp: [0, 4, 0.1],
  terminalFactor: [1, 3, 0.05],
  ablationCool: [0, 3, 0.05],
  inertiaPerAgent: [0, 0.03, 0.0005],
  rescueRadius: [30, 140, 2],
  rescueFraction: [0.05, 0.6, 0.01],
  airCoupling: [0, 12, 0.1],
  airFlowHalfLife: [0.1, 4, 0.05],
  airFlowMaxSpeed: [80, 1500, 10],
  airMigrationSpeed: [0, 300, 2],
  airMigrationForce: [0, 8, 0.05],
  thinCoupling: [0, 12, 0.05],
  thinFlowHalfLife: [0.1, 8, 0.1],
  thinMigrationSpeed: [0, 300, 1],
  potentialStrength: [0, 900, 5],
  potentialRadius: [40, 500, 5],
  potentialHalfLife: [0.2, 10, 0.1],
  vortexStrength: [0, 3, 0.05],
  predatorSpeed: [0, 320, 2],
  predatorCoupling: [0, 8, 0.05],
  predatorFear: [0, 20, 0.25],
};

export const TUNING_KEYS = Object.keys(DEFAULT_TUNING) as (keyof Tuning)[];

export function cloneTuning(t: Tuning): Tuning {
  return { ...t };
}

/** Merges a (possibly partial, possibly hostile) JSON blob onto defaults. */
export function sanitizeTuning(input: unknown, base: Tuning = DEFAULT_TUNING): Tuning {
  const out = cloneTuning(base);
  if (typeof input !== 'object' || input === null) return out;
  const rec = input as Record<string, unknown>;
  for (const key of TUNING_KEYS) {
    const v = rec[key];
    if (typeof v === 'number' && Number.isFinite(v)) {
      const [min, max] = TUNING_LIMITS[key];
      out[key] = Math.min(max, Math.max(min, v));
    }
  }
  return out;
}
