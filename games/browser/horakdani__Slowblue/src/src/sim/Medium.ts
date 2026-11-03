import type { MediumKind, Tuning } from '../config/tuning';
import { lerp } from '../core/math';

/**
 * Slowblue: the medium, as one number set.
 *
 * The whole game is `acc += (mediumVel - vel) * coupling` - the player pushes the
 * medium, the medium drags the body. Everything the campaign changes about the
 * game is a property of that medium: how hard it grips (`coupling`), how long it
 * keeps a laid current (`flowHalfLife`), how fast it can be made to move
 * (`flowMaxSpeed`), and how fast the carried life makes way on its own
 * (`migrationSpeed`).
 *
 * **There is exactly one verb in this game, and the medium is not allowed to
 * change it.** Act II shipped once with its own: a lift field, a downward pull,
 * and a flock that fell out of the sky unless the player found a thermal. It
 * measured well and it played as a different game bolted to the side of this one -
 * the hand stopped steering and started hunting. What is left is what should have
 * been there from the start: air is water with the density taken out, and the
 * campaign is legible in how the medium *answers* rather than in what it asks for.
 *
 * ## `vacuum`, and why one number carries act IV
 *
 * Seven media and one gesture. The gesture is a stroke, and above a hundred
 * kilometres there is nothing for a stroke to push - so the stroke lays a
 * *gravity well* instead, and the motes fall around it. That is not a second
 * input mode with a switch in front of it. It is one number, `vacuum`, which says
 * how much of this medium is not there:
 *
 *   * `0`   - every stroke is momentum, and the medium drags bodies (acts I, II,
 *             III, VI, VII).
 *   * `1`   - no drag at all, nothing self-propels, and a stroke lays potential
 *             (act IV).
 *   * `0.4` - both, in proportion (act V, station by station, as the air comes
 *             back).
 *
 * `World.injectStroke` splits a stroke by it, `SwarmSimulation` reads it as
 * `ballistic` to stop the boids terms from acting as engines, and act V's
 * stations blend their medium across themselves (`Level.mediumTo`), so the
 * handover from gravity back to wind has no frame on which it happened.
 *
 * Resolved from `Tuning` on demand and never cached across steps, so the debug
 * panel's live edits keep working exactly as they do for water.
 */
export interface Medium {
  kind: MediumKind;
  /** How strongly the medium drags an individual toward its own velocity (1/s). */
  coupling: number;
  /** Seconds for a laid current to lose half its speed. */
  flowHalfLife: number;
  /** Ceiling on laid current speed (px/s). */
  flowMaxSpeed: number;
  /** Unaided self-drive up the course (px/s). See `Tuning.migrationSpeed`. */
  migrationSpeed: number;
  /**
   * The force behind that drive (1/s), for free individuals. Anchored rings
   * keep the water's force in every medium - a held body of life is held.
   */
  migrationForce: number;
  /**
   * Inertia added per rescued individual - what growth costs in manoeuvrability.
   *
   * This is **added mass**, and it is the one number in the medium table with a
   * physical argument behind it. A body accelerating through a fluid drags a
   * volume of that fluid with it, and the penalty is proportional to the fluid's
   * density: a shoal that has doubled really is hauling a great deal of water it
   * was not hauling before. Air is about a thousandth as dense, so the same
   * doubling costs a flock a fraction of what it costs a shoal - which is also
   * why act II can afford to be the act where the rings are worth taking. In
   * vacuum it costs almost nothing, and in a river it costs more than in the sea.
   */
  inertiaPerAgent: number;
  /**
   * How far behind the camera an individual can fall before it is gone, in px
   * past the trailing edge of the screen.
   *
   * Water is unforgiving here and should be: a fish dragged out of the shoal by
   * the current *is* out of the shoal. Air is looser - a bird that drops off the
   * back of a flock is still flying, and catches up - and vacuum is looser again,
   * because nothing up there is being taken anywhere by anything.
   */
  stragglerMargin: number;
  /**
   * Multiplier on the pace a *caged* individual schools at, applied to the
   * boids' target speed while `anchored` and lifted the moment a rescue clears
   * it. Rescue never reads a captive's speed, so nothing scored moves.
   *
   * Air needs one because a bird's silhouette makes every reversal legible in a
   * way a fish's never did: every steering term aims at the full 118 px/s, and
   * inside a ring a few body-lengths wide that is a body caroming wall to wall -
   * reported as the ringed birds vibrating and jumping. At about half pace a
   * held flock visibly mills instead. Water keeps 1, and not out of caution:
   * act I's numbers are defended digit-for-digit (see decision 50), and a
   * narrow body milling hard reads as a shoal being caged, which was right.
   */
  heldCruise: number;
  /**
   * 0..1 - how much of this medium is not there. See the note above.
   *
   * It does three things at once, and they are the same thing said three ways:
   * a stroke lays this fraction of itself as potential rather than momentum,
   * the swarm's own steering stops acting as an engine in that proportion, and
   * the renderer knows to draw a field instead of a current.
   */
  vacuum: number;
  /** What a stroke mostly deposits. Derived from `vacuum`; the blend is the truth. */
  deposit: 'momentum' | 'potential';
  /**
   * Slowblue: how hard this medium objects to being outrun. Zero almost everywhere,
   * and the whole of act V's missing verb.
   *
   * ## The report this exists because of
   *
   * *"I can descend with the swarm much faster than the background and the
   * obstacles scroll up. There is nothing exciting in that - the top of the course
   * basically never catches up with me, so I can never die."*
   *
   * Measured, that is exactly right and it is right by construction. `World.step`
   * advances the camera at the station's forced drift and then takes the *greater*
   * of that and the swarm's own position, with no upper bound - so a hand that
   * pushes forward drags the camera with it, takes 156-284 % more ground than the
   * drift on act V's middle stations, and pins `behindFraction` at 0.620 against a
   * strand line of 0.94. The one failure of position in the game is therefore
   * unreachable for anybody who pushes. Pushing forward was free.
   *
   * ## Why the fix is here and not in the camera
   *
   * The obvious answer is to stop the camera following, and it is wrong three
   * times over. It makes the reported symptom *worse* - every parallax plane reads
   * `viewCameraY`, so pinning the camera slows the background the player already
   * says is too slow. It breaks the input: `FlowField` is a camera-anchored grid
   * about one screen tall, so a swarm far past the leading edge is steering a grid
   * it is no longer inside, silently. And this repo has already run that experiment
   * once - see `World.advanceView`, where a cap on the follow moved the careful
   * bot's score from 1473 to 1209 while the flailing bot's *rose* from 700 to 984.
   * The camera's motion is a picture; the camera's position is a rule.
   *
   * So the rule is the medium's, which is also the only place the fiction allows.
   * Act V's stated verb is **brake, and accept the medium**, and a body that
   * outruns the air it is falling through does not get slowed by the air - it gets
   * *heated* by it. Over `Tuning.terminalFactor` times the station's own drift, the
   * swarm starts to ablate, leading edge first, at this many carriers a second per
   * whole terminal of over-speed. Nothing stops the player going fast. It costs.
   *
   * ## Why it is zero in five of the seven
   *
   * `space` is zero because there is nothing there to be outrun - which is why act
   * V's deorbit is the free station and should be. `water` is zero because act I is
   * defended digit for digit and act VII must not grow a threat in its last
   * minutes. `air` and `thinAir` are zero because acts II and III are climbs: a
   * body going up is already paying, and nothing has measured them. `cloud` is zero
   * because act VI reads it too, and act V's own §9 has just finished saying that
   * changing an act without measuring it is the mistake.
   *
   * That leaves the three media a body actually **falls** through, and the number
   * differs because the media do: 3 in the plasma, where outrunning the air sets
   * the swarm on fire; 0.6 in cloud, where it is torn rather than burnt; 0.5 in
   * running water, set at the point where the campaign is already letting go.
   *
   * One of those was zero for an afternoon on a measurement that went stale the
   * same day, and it is worth keeping: act VI *before* its rebuild charged for
   * rushing all by itself - 0.83 of the world's own travel against a careful
   * hand's 1.08, nine station restarts against one - because twenty-four sections
   * of dense weather punish a hurry. Rebuilt to sixty-one sections with two rests
   * a station, it stopped: the same hand measured 1.33 and one restart. **The
   * rests are what made the fall free again**, which is the whole length plan
   * handing this rule its own reason to exist.
   */
  drag: number;
}

/**
 * The seven media, as multipliers on the two number sets that are swept.
 *
 * Water and air resolve to the exact tuning fields they always did, so the table
 * below cannot move a digit of the shipped two acts. Everything past the anvil is
 * expressed against the air's numbers, because that is what those media *are* -
 * air with more or less of itself in it - and stating them as multipliers is what
 * makes the density curve of the whole campaign readable in one place.
 */
export function mediumFor(kind: MediumKind, t: Tuning): Medium {
  switch (kind) {
    case 'air':
      return {
        kind,
        coupling: t.airCoupling,
        flowHalfLife: t.airFlowHalfLife,
        flowMaxSpeed: t.airFlowMaxSpeed,
        migrationSpeed: t.airMigrationSpeed,
        migrationForce: t.airMigrationForce,
        inertiaPerAgent: t.inertiaPerAgent * 0.45,
        stragglerMargin: 210,
        heldCruise: 0.55,
        vacuum: 0,
        deposit: 'momentum',
        // A climb. See `Medium.drag`.
        drag: 0,
      };

    case 'thinAir':
      return {
        kind,
        coupling: t.thinCoupling,
        flowHalfLife: t.thinFlowHalfLife,
        // A body of moving air with nothing to slow it can be made to go faster
        // than one at sea level - and it has to be, because the layers the act is
        // built on are themselves moving at a jet stream's pace.
        flowMaxSpeed: t.airFlowMaxSpeed * 1.2,
        migrationSpeed: t.thinMigrationSpeed,
        // Weak, because it is the only thing here that is not the medium: a mote
        // has no wings, and the small drive it does have is what stops the swarm
        // from being pure cargo.
        migrationForce: t.airMigrationForce * 0.7,
        inertiaPerAgent: t.inertiaPerAgent * 0.18,
        stragglerMargin: 280,
        heldCruise: 0.6,
        vacuum: 0,
        deposit: 'momentum',
        drag: 0,
      };

    case 'space':
      return {
        kind,
        // The one zero in the table, and the whole act is in it. Nothing drags
        // anything: a mote's velocity is its own until a gravity well bends it.
        coupling: 0,
        flowHalfLife: t.thinFlowHalfLife,
        flowMaxSpeed: t.airFlowMaxSpeed,
        // Nothing propels a mote in vacuum. Ballistic means ballistic.
        migrationSpeed: 0,
        migrationForce: 0,
        inertiaPerAgent: t.inertiaPerAgent * 0.05,
        stragglerMargin: 520,
        heldCruise: 0.75,
        vacuum: 1,
        deposit: 'potential',
        // Nothing to outrun. The deorbit is the one station in act V where going
        // fast is free, and that is the correct reading of vacuum.
        drag: 0,
      };

    case 'plasma':
      return {
        kind,
        // Re-entry: the air arrives, and it arrives hard. Grip climbs back past
        // the thin air's and the gust it lays dies much faster, because there is
        // suddenly something up here to dissipate it in.
        coupling: t.airCoupling * 0.72,
        flowHalfLife: t.airFlowHalfLife * 1.25,
        flowMaxSpeed: t.airFlowMaxSpeed * 1.1,
        migrationSpeed: t.airMigrationSpeed * 0.7,
        migrationForce: t.airMigrationForce * 0.85,
        inertiaPerAgent: t.inertiaPerAgent * 0.28,
        stragglerMargin: 300,
        heldCruise: 0.6,
        // Still a third empty. Act V's stations blend this toward `cloud`, so the
        // last of the gravity input fades out under the player's hand.
        vacuum: 0.34,
        deposit: 'momentum',
        // The only non-zero in the table. See `Medium.drag`.
        drag: 3,
      };

    case 'cloud':
      return {
        kind,
        // Saturated air is the densest sky there is, and it is the first medium
        // on the way down that answers a stroke the way the sea did.
        coupling: t.airCoupling * 1.15,
        flowHalfLife: t.airFlowHalfLife * 0.85,
        flowMaxSpeed: t.airFlowMaxSpeed * 0.92,
        migrationSpeed: t.airMigrationSpeed * 1.1,
        migrationForce: t.airMigrationForce,
        inertiaPerAgent: t.inertiaPerAgent * 0.5,
        stragglerMargin: 230,
        heldCruise: 0.6,
        vacuum: 0,
        deposit: 'momentum',
        /*
         * Saturated air, and a fifth of the plasma's objection - because nothing is
         * on fire at twelve kilometres. What a body outrunning the rain gets is
         * torn rather than burnt, and the campaign spends the same carriers on it.
         *
         * This was zero for an afternoon, on a measurement that was true and went
         * stale in the same day. Act VI *before* it was rebuilt already charged for
         * rushing - a pushing hand made 0.83 of the world's own travel against a
         * careful one's 1.08, and took nine station restarts for it - because 24
         * sections of dense weather punish a hurry all by themselves. Rebuilt to 61
         * sections with two rests a station, it stopped doing that: the same hand
         * measured 1.33 and one restart. **The rests are what made the fall free
         * again.** A measurement is about the thing as it was when it was taken.
         */
        drag: 0.6,
      };

    case 'stream':
      return {
        kind,
        // Running water. It grips harder than the sea and forgets faster, which
        // is the difference between an ocean current and a river: the whole
        // medium is already going somewhere, so what the player adds is a nudge
        // on top of a much larger thing.
        coupling: t.flowCoupling * 1.24,
        flowHalfLife: t.flowDecayHalfLife * 0.8,
        flowMaxSpeed: t.flowMaxSpeed * 1.1,
        migrationSpeed: t.migrationSpeed * 1.15,
        migrationForce: t.migrationForce,
        inertiaPerAgent: t.inertiaPerAgent * 1.15,
        // A droplet that leaves the flow is gone almost at once - it is the one
        // medium that is narrower than the screen.
        stragglerMargin: 110,
        heldCruise: 1,
        vacuum: 0,
        deposit: 'momentum',
        // The gentlest of the three, and it is act VII that sets it. `stream` is
        // act VI's last two stations and act VII's salt line - one station from the
        // three that cannot be lost at all - so the number is chosen at the point
        // where the campaign is already letting go. At 1.2 a blind hand took 97
        // station restarts in the homecoming, which is the campaign's release
        // becoming its hardest act; at 0.5 it takes none and pays 33 carriers.
        drag: 0.5,
      };

    default:
      // Water reads the exact fields act I always read, so the abstraction cannot
      // move a single digit of the shipped game: same object, same numbers.
      return {
        kind: 'water',
        coupling: t.flowCoupling,
        flowHalfLife: t.flowDecayHalfLife,
        flowMaxSpeed: t.flowMaxSpeed,
        migrationSpeed: t.migrationSpeed,
        migrationForce: t.migrationForce,
        inertiaPerAgent: t.inertiaPerAgent,
        stragglerMargin: 140,
        heldCruise: 1,
        vacuum: 0,
        deposit: 'momentum',
        /*
         * Zero, and the only one of the three descending media that stays zero.
         *
         * Two reasons and they are the same shape. Act I is a climb whose numbers
         * are defended digit for digit, and rushing a climb buys nothing anyway -
         * measured, a hand that pushes act I forever makes 0.98 of the ground a
         * careful one does. And act VII's last three stations are pure water,
         * cannot be lost at all, and are the end of the journey: giving the water
         * a terminal would put a price on the one part of the campaign whose whole
         * subject is that nothing is being asked any more.
         */
        drag: 0,
      };
  }
}

/**
 * Two media, mixed. Used by a station that names where it starts and where it
 * ends (`Level.mediumTo`), so the re-entry act's return of the air is continuous
 * rather than a step at every station line.
 *
 * `kind` follows whichever side is more than half, because the things that read
 * it are categorical - which bed the audio plays, which silhouette the renderer
 * draws - and a categorical answer cannot be blended. Everything that decides how
 * the game *feels* is a number here and is interpolated.
 */
export function blendMedium(a: Medium, b: Medium, t: number): Medium {
  if (t <= 0) return a;
  if (t >= 1) return b;
  const vacuum = lerp(a.vacuum, b.vacuum, t);
  return {
    kind: t < 0.5 ? a.kind : b.kind,
    coupling: lerp(a.coupling, b.coupling, t),
    flowHalfLife: lerp(a.flowHalfLife, b.flowHalfLife, t),
    flowMaxSpeed: lerp(a.flowMaxSpeed, b.flowMaxSpeed, t),
    migrationSpeed: lerp(a.migrationSpeed, b.migrationSpeed, t),
    migrationForce: lerp(a.migrationForce, b.migrationForce, t),
    inertiaPerAgent: lerp(a.inertiaPerAgent, b.inertiaPerAgent, t),
    stragglerMargin: lerp(a.stragglerMargin, b.stragglerMargin, t),
    heldCruise: lerp(a.heldCruise, b.heldCruise, t),
    drag: lerp(a.drag, b.drag, t),
    vacuum,
    deposit: vacuum >= 0.5 ? 'potential' : 'momentum',
  };
}
