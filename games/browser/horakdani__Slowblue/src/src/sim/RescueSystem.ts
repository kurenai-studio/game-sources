import type { Agent } from './Agent';
import { MAIN_FACTION, podSpecies } from './Agent';
import type { SwarmSimulation } from './SwarmSimulation';

export interface Pod {
  /** Also the faction id of its members. Always >= 1. */
  id: number;
  x: number;
  y: number;
  radius: number;
  initialCount: number;
  members: Agent[];
  /** Seconds of sustained contact with the main shoal. */
  contact: number;
  /** 0..1 - how much of the required shoal presence is currently inside the ring. */
  presence: number;
  merged: boolean;
  /** Counts down after a merge; renderer uses it for the wave pulse. */
  flash: number;
  /**
   * Slowblue: a dashed ring is not an invitation, it is a gate.
   *
   * Leaving one behind ends the dive. That is the whole reason the campaign can
   * be *authored* rather than tuned: a required ring is a fixed point the level
   * knows the player will be standing on, so the next line can be drawn from it.
   * Everything about a required ring is therefore made generous - a wider ring, a
   * smaller fraction of the shoal, and never a position off the section's own
   * line - because the punishment for missing it is total.
   */
  required: boolean;
}

/** Floor on how many main-shoal agents must be inside the pod ring. */
export const CONTACT_AGENTS = 8;
/**
 * ...and the fraction of the *current* shoal that must be inside it.
 *
 * Slowblue: a flat threshold was the single worst balance bug found by the sweeps. Six
 * agents is trivially satisfied by a scattered shoal drifting past, so rescues
 * happened *to* the player rather than being chosen, and "detour for a pod" was free.
 * Scaling with shoal size means a pod always costs a deliberate commitment of the
 * body you actually have - and makes a big shoal harder to feed, not easier.
 */
export const CONTACT_FRACTION = 0.28;
/**
 * ...and the smaller fraction a *required* ring asks for.
 *
 * A ring that ends the run has to be clearable by a shoal that is merely pointed
 * at it, not by one that is threaded through its centre: the skill this game is
 * about is holding a body of fish somewhere, and the dashed ring prices that at
 * "most of the front of the shoal", not "all of it".
 */
export const REQUIRED_FRACTION = 0.2;
/** Seconds of sustained contact needed to merge. Long enough to be a decision. */
export const CONTACT_HOLD = 0.7;
/** ...and the shorter hold a required ring asks for. */
export const REQUIRED_HOLD = 0.5;

/** Agents needed inside the ring for a shoal of `shoalCount`. */
export function contactRequirement(shoalCount: number, fraction = CONTACT_FRACTION): number {
  // Epsilon: 100 * 0.28 is 28.000000000000004 in binary floating point.
  return Math.max(CONTACT_AGENTS, Math.ceil(shoalCount * fraction - 1e-9));
}

/**
 * Slowblue: growth is the risk/reward loop. A pod is stationary and sits off the safe
 * line, so taking it means holding the shoal somewhere expensive for ~0.7s while
 * the camera keeps advancing. Merging is never automatic on touch.
 */
export class RescueSystem {
  readonly pods: Pod[] = [];
  /** Last computed contact requirement - shown in the debug panel. */
  lastRequirement = CONTACT_AGENTS;
  private nextId = 1;

  reset(): void {
    this.pods.length = 0;
    this.lastRequirement = CONTACT_AGENTS;
    this.nextId = 1;
  }

  spawn(
    swarm: SwarmSimulation,
    x: number,
    y: number,
    count: number,
    radius = 62,
    required = false,
  ): Pod {
    const id = this.nextId++;
    // Each pod is a different kind of fish, and stays one after it merges.
    const members = swarm.spawnPod(id, x, y, count, podSpecies(id), radius);
    const pod: Pod = {
      id,
      x,
      y,
      radius,
      initialCount: members.length,
      members,
      contact: 0,
      presence: 0,
      merged: false,
      flash: 0,
      required,
    };
    this.pods.push(pod);
    return pod;
  }

  /** Returns pods merged during this step. */
  update(
    dt: number,
    swarm: SwarmSimulation,
    shoalCount = swarm.aliveCount(MAIN_FACTION),
    fraction = CONTACT_FRACTION,
  ): Pod[] {
    const merged: Pod[] = [];
    this.lastRequirement = contactRequirement(shoalCount, fraction);
    for (const pod of this.pods) {
      if (pod.flash > 0) pod.flash = Math.max(0, pod.flash - dt);
      if (pod.merged) continue;
      const required = contactRequirement(shoalCount, pod.required ? REQUIRED_FRACTION : fraction);
      const hold = pod.required ? REQUIRED_HOLD : CONTACT_HOLD;
      const alive = pod.members.filter((m) => m.alive && m.faction === pod.id);
      if (alive.length === 0) {
        pod.merged = true;
        continue;
      }
      let near = 0;
      const r2 = pod.radius * pod.radius;
      swarm.hash.forEachNear(pod.x, pod.y, (a) => {
        if (!a.alive || a.faction !== MAIN_FACTION) return;
        const dx = a.x - pod.x;
        const dy = a.y - pod.y;
        if (dx * dx + dy * dy <= r2) near++;
      });
      // The hash cell may be smaller than the ring, so also allow a direct count.
      if (near < required) {
        near = 0;
        for (const a of swarm.agents) {
          if (!a.alive || a.faction !== MAIN_FACTION) continue;
          const dx = a.x - pod.x;
          const dy = a.y - pod.y;
          if (dx * dx + dy * dy <= r2) near++;
        }
      }
      // Presence drives the ring's weight on screen, so the player can see how much
      // more of the shoal a pod is asking for before any timer starts.
      pod.presence = Math.min(1, near / required);
      if (near >= required) pod.contact += dt;
      else pod.contact = Math.max(0, pod.contact - dt * 1.6);

      if (pod.contact >= hold) {
        for (const m of alive) {
          m.faction = MAIN_FACTION;
          m.anchorRadius = 0;
          m.anchored = false;
          m.age = 0;
        }
        pod.merged = true;
        pod.flash = 0.75;
        merged.push(pod);
      }
    }
    return merged;
  }

  /**
   * Removes pods the camera has left behind, and reports the ones that were never
   * absorbed. An optional ring is simply lost; a required one ends the run, which
   * is the caller's decision to make, not this system's.
   *
   * `dir` is the course direction: -1 while the campaign climbs, +1 once it turns
   * over. Everything about a ring is the same in both - only which side of the
   * screen counts as "gone" changes.
   */
  prune(behindY: number, dir: -1 | 1 = -1): Pod[] {
    const missed: Pod[] = [];
    for (let i = this.pods.length - 1; i >= 0; i--) {
      const pod = this.pods[i]!;
      if ((pod.y - behindY) * dir < 0) {
        if (!pod.merged) {
          missed.push(pod);
          for (const m of pod.members) if (m.faction === pod.id) m.alive = false;
          // Marked merged so a pod that survives one more frame for its flash is
          // never reported twice.
          pod.merged = true;
        }
        if (pod.flash <= 0) this.pods.splice(i, 1);
      }
    }
    return missed;
  }
}
