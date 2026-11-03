import { limitScale } from '../core/math';
import { MAIN_FACTION, type Agent } from './Agent';
import type { SwarmSimulation } from './SwarmSimulation';
import type { WaterSampler } from './SwarmSimulation';

/**
 * Slowblue: the one thing in the game that hunts you - and the one you still cannot
 * touch directly.
 *
 * A hunter is heavy: water drags it at roughly a third of the coupling a fish feels,
 * so shoving one off its line costs a real, committed stroke rather than a flick.
 * That is the whole design of it. Every other hazard asks "can you steer"; this one
 * asks "will you spend the water you were going to steer with". It cannot be killed,
 * only out-swum, out-waited, or pushed.
 */
/**
 * Slowblue: what the thing hunting you *is*.
 *
 * This used to be read off the medium in the renderer - `medium.kind === 'air'`
 * picked a raptor and everything else got a shark - which worked for exactly as
 * long as the campaign had two hunters and each act had one medium. Act V has
 * three media inside one act and a threat of its own, and the blend in
 * `World.medium` flips its `kind` halfway across a station, so the medium test
 * would have swapped the animal mid-chase.
 *
 * It is a property of the predator now, set once at spawn from what the level
 * author actually wrote. The renderer branches on this and on nothing else.
 */
export type PredatorForm =
  /** Act I and act VII: the pelagic shark. `render/Hunter.ts`. */
  | 'shark'
  /** Act II: the falcon. `render/Raptor.ts`. */
  | 'raptor'
  /**
   * Act V: a burning piece of the vehicle. `render/Ember.ts`.
   *
   * Not an animal, and that is the point of it - nothing hunts at two hundred
   * kilometres. It ablates more slowly than the swarm does, so it overtakes,
   * and what it takes it takes by being in the way while on fire.
   */
  | 'ember';

export interface Predator {
  x: number;
  y: number;
  vx: number;
  vy: number;
  /** Body half-length in px; also the reach of a strike. */
  size: number;
  /** How far it can notice the shoal. */
  sense: number;
  /** Seconds until it can take another individual. */
  cooldown: number;
  /** 0..1, spikes on a strike. Renderer only. */
  lunge: number;
  /** Seconds it has had nothing to chase. Drives the return to patrol. */
  idle: number;
  homeX: number;
  homeY: number;
  phase: number;
  sectionId: number;
  /**
   * Slowblue: the falcon.
   *
   * Every threat in act I arrived from the direction the shoal was already
   * facing - it swims up the course and the rock, the funnel and the hunter are
   * all *ahead*. A stooping hunter enters from behind and overtakes, which makes
   * it the first hazard in the game you cannot see by looking where you are
   * going. Mechanically that is one change with three consequences: it starts
   * behind the flock, it is faster than one, and when it loses interest it
   * carries on up the course and leaves instead of sweeping back and forth.
   *
   * It is the same hunter with its patrol turned through ninety degrees. Nothing
   * else about it is new, and that is deliberate: the shoal's flight response,
   * the strike cooldown and the player's one lever on it all still read.
   */
  stoop: boolean;
  /** Which silhouette this is, and the only thing the renderer branches on. */
  form: PredatorForm;
  /**
   * Slowblue: how fast this thing is being taken apart, in body radius per second.
   * Zero for anything alive, which is the shark and the raptor.
   *
   * An ember is a fragment ablating, and the first build of it had no end: it
   * spawned behind the swarm, caught up, and then simply *stayed*, because a
   * stoop only leaves when it has had nothing in sense range for a couple of
   * seconds and a swarm is a large thing to lose. Measured over three seeds of
   * act V, one fragment lived 11 629 frames - three and a quarter minutes of a
   * hazard that was supposed to overtake and be gone.
   *
   * The fix is the fiction, which is usually the sign that it is the right one.
   * A fragment does not give up and it does not leave; **it burns out.** So the
   * body shrinks at a constant rate, and because `BITE_REACH` is a multiple of
   * `size`, the thing gets less dangerous exactly as visibly as it gets smaller.
   * The answer to an ember is to survive it rather than to out-run it, which is
   * the only answer this act's swarm has anyway - it cannot out-run anything, it
   * is being carried.
   */
  burn: number;
}

/** Seconds between strikes. Long enough that a tight shoal survives a pass. */
export const BITE_COOLDOWN = 1.35;
/** Seconds a freshly spawned hunter cannot strike for. */
export const SPAWN_GRACE = 0.6;
/** Reach of a strike, as a multiple of body size. */
const BITE_REACH = 1.5;
/** After this long with nothing in range, a hunter goes back to patrolling. */
const GIVE_UP = 2.5;
/** Half-width of the patrol sweep, as a fraction of the play field. */
const PATROL_SWEEP = 0.3;
const MAX_ACCEL = 620;
/** How much faster than its cruise a stooping hunter closes on a target. */
const STOOP_RUSH = 1.5;
/** ...and how fast it carries on up the course once it has given up. */
const STOOP_CRUISE = 0.8;
/**
 * Seconds an ember takes to ablate from its authored size to nothing.
 *
 * Thirty is not a round number chosen for tidiness: at act V's paces the swarm
 * covers 700 to 1400 px in that time, which is one to two sections. So a fragment
 * is a hazard for about as long as the thing it broke off is still on the screen,
 * and then the frame is clear again. Much shorter and it is a flash rather than a
 * threat; much longer and it stops being an event and becomes weather.
 */
const EMBER_LIFE = 30;
/** Below this the fragment is dust, which is what the player is already carrying. */
const EMBER_GONE = 3;

export class PredatorSystem {
  readonly predators: Predator[] = [];
  private readonly water = { x: 0, y: 0 };

  reset(): void {
    this.predators.length = 0;
  }

  spawn(
    x: number,
    y: number,
    size: number,
    sectionId: number,
    phase: number,
    stoop = false,
    form: PredatorForm = 'shark',
  ): Predator {
    const p: Predator = {
      x,
      y,
      vx: 0,
      vy: 0,
      size,
      sense: 300,
      // A short grace on arrival, so a hunter that spawns on top of the shoal does
      // not open with a free strike the player had no chance to avoid.
      cooldown: SPAWN_GRACE,
      lunge: 0,
      idle: GIVE_UP,
      homeX: x,
      homeY: y,
      phase,
      sectionId,
      stoop,
      form,
      burn: form === 'ember' ? size / EMBER_LIFE : 0,
    };
    this.predators.push(p);
    return p;
  }

  /** `dir` is the course direction: -1 climbing, +1 falling. See `World.u`. */
  prune(behindY: number, dir: -1 | 1 = -1): void {
    for (let i = this.predators.length - 1; i >= 0; i--) {
      if ((this.predators[i]!.y - behindY) * dir < 0) this.predators.splice(i, 1);
    }
  }

  /**
   * Steps every hunter and returns the individuals taken this step.
   * `speed`, `coupling` and `width` come from tuning so the debug panel can move them.
   */
  update(
    dt: number,
    swarm: SwarmSimulation,
    water: WaterSampler,
    width: number,
    speed: number,
    coupling: number,
    /** The act's course direction. A stoop that gives up leaves *up the course*. */
    dir: -1 | 1 = -1,
  ): Agent[] {
    const taken: Agent[] = [];
    let ablated = false;
    for (const p of this.predators) {
      // Ablation, before anything else this frame: a fragment that has finished
      // burning does not get one more chance to take an individual on its way out.
      if (p.burn > 0) {
        p.size -= p.burn * dt;
        if (p.size <= EMBER_GONE) {
          ablated = true;
          continue;
        }
      }
      p.phase += dt * 0.55;
      p.cooldown = Math.max(0, p.cooldown - dt);
      p.lunge = Math.max(0, p.lunge - dt * 2.2);

      // --- pick a target: nearest individual inside the sense radius ---
      let target: Agent | null = null;
      let bestD2 = p.sense * p.sense;
      for (const a of swarm.agents) {
        if (!a.alive || a.faction !== MAIN_FACTION) continue;
        const dx = a.x - p.x;
        const dy = a.y - p.y;
        const d2 = dx * dx + dy * dy;
        if (d2 < bestD2) {
          bestD2 = d2;
          target = a;
        }
      }

      let wantX: number;
      let wantY: number;
      if (target !== null) {
        p.idle = 0;
        const d = Math.sqrt(bestD2) || 1;
        // A stoop is a dive: it closes faster than a patrolling hunter can, which
        // is what makes catching up from behind a real threat rather than a slow
        // chase the flock simply out-climbs.
        const rush = p.stoop ? STOOP_RUSH : 1;
        wantX = ((target.x - p.x) / d) * speed * rush;
        wantY = ((target.y - p.y) / d) * speed * rush;
      } else if (p.stoop) {
        p.idle += dt;
        // A stoop that found nothing keeps going up the course and out of the
        // frame. It does not come back, because a threat that overtakes you twice
        // is a threat you can wait out, and waiting is what act II already costs
        // you height for.
        wantX = Math.sin(p.phase * 0.6) * speed * 0.18;
        // Signed, like `prune` above it. Hard-coded -Y was correct while the only
        // stoops in the campaign were in an act that climbs, and would have sent a
        // falling act's hunter back down the course into the swarm it had just
        // given up on - the one behaviour this comment says it must not have.
        wantY = dir * speed * STOOP_CRUISE;
      } else {
        p.idle += dt;
        // Patrol: a slow horizontal sweep across its own band. Predictable on
        // purpose - a hunter you cannot read is just random attrition.
        const sweepX = p.homeX + Math.sin(p.phase) * width * PATROL_SWEEP;
        const dx = sweepX - p.x;
        const dy = p.homeY - p.y;
        const d = Math.hypot(dx, dy) || 1;
        const cruise = speed * (p.idle > GIVE_UP ? 0.42 : 0.6);
        wantX = (dx / d) * cruise;
        wantY = (dy / d) * cruise;
      }

      let ax = (wantX - p.vx) * 2.4;
      let ay = (wantY - p.vy) * 2.4;

      // --- the player's only lever on a hunter ---
      water.sample(p.x, p.y, this.water);
      ax += (this.water.x - p.vx) * coupling;
      ay += (this.water.y - p.vy) * coupling;

      // Walls: soft push, then a hard stop. The soft push alone loses to a strong
      // enough current, and a hunter shoved off-screen is a hazard that vanished.
      // Pinning one against the wall with water is legitimate play; losing it is not.
      if (p.x < p.size) ax += (p.size - p.x) * 12;
      else if (p.x > width - p.size) ax -= (p.x - (width - p.size)) * 12;

      const as = limitScale(ax, ay, MAX_ACCEL);
      p.vx += ax * as * dt;
      p.vy += ay * as * dt;
      const vs = limitScale(p.vx, p.vy, speed * (p.stoop ? 1.35 * STOOP_RUSH : 1.35));
      p.vx *= vs;
      p.vy *= vs;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      const minX = p.size * 0.5;
      const maxX = width - p.size * 0.5;
      if (p.x < minX) {
        p.x = minX;
        p.vx = Math.max(0, p.vx);
      } else if (p.x > maxX) {
        p.x = maxX;
        p.vx = Math.min(0, p.vx);
      }

      // --- strike ---
      if (p.cooldown > 0 || target === null) continue;
      const reach = p.size * BITE_REACH;
      if (bestD2 > reach * reach) continue;
      target.alive = false;
      taken.push(target);
      p.cooldown = BITE_COOLDOWN;
      p.lunge = 1;
    }
    // Swept once, after the loop, so nothing is spliced out from under the
    // iteration. The list is never longer than a handful.
    if (ablated) {
      for (let i = this.predators.length - 1; i >= 0; i--) {
        if (this.predators[i]!.size <= EMBER_GONE) this.predators.splice(i, 1);
      }
    }
    return taken;
  }
}
