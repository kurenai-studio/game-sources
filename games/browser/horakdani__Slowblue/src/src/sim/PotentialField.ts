/**
 * Slowblue: what a stroke becomes when there is no medium left to push.
 *
 * Above the Karman line the sentence the game is built on runs out of one of its
 * words. "You control the medium that carries them" needs a medium, and there is
 * not one - so act IV keeps the *verb* and replaces the noun. A stroke still lays
 * something into the world that the carried life then obeys; what it lays is a
 * gravity well, and what the life does is fall around it.
 *
 * Three properties make that read as the same game rather than as a second one:
 *
 *   1. **It is still indirect.** Nothing here touches an individual. A well is a
 *      shape in space, the motes are in free fall, and the player is never doing
 *      anything but changing what "straight ahead" means locally.
 *   2. **It is still deposited, and it still fades.** The same grammar as the
 *      flow field: a stroke leaves something behind, that something has a
 *      half-life, and steering is the business of laying the next one before the
 *      last one has gone. `potentialHalfLife` is simply much longer than any
 *      medium's, because nothing up here dissipates anything.
 *   3. **It is late.** A current moves a body inside a second. A well *bends* a
 *      trajectory, which takes as long as it takes - which is exactly the act's
 *      subject. One bad stroke stays correctable and stops being correctable
 *      cheaply, and that is the difference between "letting go" and "steering".
 *
 * ## The profile, and why it has a hole in the middle
 *
 * Acceleration is zero at the centre of a well, peaks at `CORE` of the way out,
 * and falls smoothly to zero at the rim. A 1/r^2 law would be more honest and
 * completely unplayable: it is singular, so a mote that arrives near the centre
 * is fired across the screen, and everything the player lays becomes a trap that
 * eats the swarm. A bump profile has the two properties this needs instead -
 * bodies *orbit* it rather than collapsing into it, and its reach is finite, so
 * a well laid on one side of the screen is not quietly steering the other side.
 *
 * Entirely deterministic and stateless per step: same strokes, same seed, same
 * trajectories, so a replay is a replay and the sweeps can measure it.
 */

/** A laid gravity well. Positive `strength` attracts; negative pushes away. */
export interface Well {
  x: number;
  y: number;
  /** Peak acceleration (px/s^2) this well can apply, before its own decay. */
  strength: number;
  /** How far it reaches (px). Nothing outside this is touched at all. */
  radius: number;
  /** 0..1 - what is left of it. Multiplies `strength`. */
  life: number;
  /**
   * A well the *course* owns rather than one the hand laid. It never decays and
   * it is never evicted to make room, because it is scenery: act IV's `node`
   * sections are gravity the level author put there, and a hazard that faded
   * while the player was still approaching it would be a hazard that lied.
   */
  standing?: boolean;
}

/**
 * Where the profile peaks, as a fraction of the radius.
 *
 * Small enough that the well reads as a point the swarm falls toward, large
 * enough that the calm centre is a place a mote can actually sit. At 0.3 a well
 * laid on a drifting cloud gathers it into a slow rosette, which is the picture
 * this act is for.
 */
export const CORE = 0.3;

/**
 * Most wells alive at once.
 *
 * Not a memory limit - it is a design limit. Without it a player who scribbles
 * lays forty overlapping wells whose sum is a smooth mush with no shape in it,
 * and the act stops rewarding the one thing it asks for, which is placing a
 * small number of things deliberately. Past the cap the weakest is dropped, so
 * scribbling costs you your own earliest, best-aimed work.
 */
export const MAX_WELLS = 24;

export class PotentialField {
  readonly wells: Well[] = [];

  reset(): void {
    this.wells.length = 0;
  }

  /**
   * Lays a well. If the field is full the faintest one goes, never the newest -
   * a player who is still drawing has to keep what they have just aimed.
   */
  add(x: number, y: number, strength: number, radius: number, standing = false): Well {
    const well: Well = standing
      ? { x, y, strength, radius, life: 1, standing: true }
      : { x, y, strength, radius, life: 1 };
    if (this.wells.length >= MAX_WELLS) {
      // Only the player's own work is ever evicted. A standing well is the course
      // and cannot be scribbled away.
      let weakest = -1;
      for (let i = 0; i < this.wells.length; i++) {
        const w = this.wells[i]!;
        if (w.standing === true) continue;
        if (
          weakest < 0 ||
          w.life * Math.abs(w.strength) <
            this.wells[weakest]!.life * Math.abs(this.wells[weakest]!.strength)
        ) {
          weakest = i;
        }
      }
      if (weakest >= 0) this.wells.splice(weakest, 1);
    }
    this.wells.push(well);
    return well;
  }

  /** Exponential decay on the same half-life grammar the flow field uses. */
  step(dt: number, halfLife: number): void {
    const decay = Math.pow(0.5, dt / Math.max(0.05, halfLife));
    for (let i = this.wells.length - 1; i >= 0; i--) {
      const w = this.wells[i]!;
      if (w.standing === true) continue;
      w.life *= decay;
      // Below a fortieth it is doing nothing a player could see or feel.
      if (w.life < 0.025) this.wells.splice(i, 1);
    }
  }

  /**
   * Adds this field's acceleration at a point into `out`. Accumulating rather
   * than assigning, exactly like `CurrentField.addTo`, so several fields can be
   * summed without any of them knowing about the others.
   */
  addTo(x: number, y: number, out: { x: number; y: number }): void {
    for (const w of this.wells) {
      const dx = w.x - x;
      const dy = w.y - y;
      // Cheap rejection first: most wells are nowhere near most motes.
      if (dx > w.radius || dx < -w.radius || dy > w.radius || dy < -w.radius) continue;
      const d2 = dx * dx + dy * dy;
      const r2 = w.radius * w.radius;
      if (d2 >= r2 || d2 === 0) continue;
      const d = Math.sqrt(d2);
      const u = d / w.radius;
      // Zero at the centre, peak at CORE, zero at the rim. See the note above.
      const rise = u < CORE ? u / CORE : 1;
      const fall = (1 - u) * (1 - u);
      const a = w.strength * w.life * rise * fall;
      out.x += (dx / d) * a;
      out.y += (dy / d) * a;
    }
  }

  /**
   * Drops wells the camera has left behind. `dir` is the course direction, so
   * the same call works on the climb and on the fall. See `World.u`.
   */
  prune(behindY: number, dir: -1 | 1 = -1): void {
    for (let i = this.wells.length - 1; i >= 0; i--) {
      const w = this.wells[i]!;
      if ((w.y + dir * w.radius - behindY) * dir < 0) this.wells.splice(i, 1);
    }
  }

  /** Mean live strength - the debug overlay's one-number health check. */
  meanStrength(): number {
    if (this.wells.length === 0) return 0;
    let s = 0;
    for (const w of this.wells) s += Math.abs(w.strength) * w.life;
    return s / this.wells.length;
  }
}
