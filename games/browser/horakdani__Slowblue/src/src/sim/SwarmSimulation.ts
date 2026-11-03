import type { Tuning } from '../config/tuning';
import { limitScale } from '../core/math';
import { Rng } from '../core/rng';
import { MAIN_FACTION, createAgent, type Agent } from './Agent';
import type { ObstacleSystem } from './ObstacleSystem';
import { SpatialHash } from './SpatialHash';

export const MAX_AGENTS = 600;
const WALL_MARGIN = 24;
const WALL_PUSH = 1400;
/** Keeps the whole fish body visibly inside a rescue ring, not only its centre. */
const POD_EDGE_INSET = 10;
/** Flee radius as a multiple of a hunter's body size. */
const FLEE_REACH = 5.5;

/**
 * Total water velocity at a point: the player's currents plus the ocean's own.
 * The swarm only ever sees the sum - it cannot tell whose water is pushing it.
 */
export interface WaterSampler {
  sample(x: number, y: number, out: { x: number; y: number }): void;
}

/**
 * A field that contributes *acceleration* rather than velocity.
 *
 * The difference is the whole of act IV. A `WaterSampler` says "the medium here
 * is moving at this speed", and a body in it is dragged toward that speed - it
 * has a terminal velocity, and steering is immediate. An `AccelSampler` says
 * "there is a slope here", and a body in it accelerates and keeps whatever it
 * accumulates. That is what makes a gravity well something you commit to seconds
 * before it pays, and it is why this cannot be smuggled through the water
 * sampler with a coupling of one.
 */
export interface AccelSampler {
  addTo(x: number, y: number, out: { x: number; y: number }): void;
}

/**
 * Something the shoal actively flees. Kept as a bare shape rather than the predator
 * type so the swarm never has to know what a hunter is.
 */
export interface Threat {
  x: number;
  y: number;
  /** Radius at which the shoal starts breaking away from it. */
  size: number;
}

export interface SwarmContext {
  water: WaterSampler;
  obstacles: ObstacleSystem;
  tuning: Tuning;
  width: number;
  migrationX: number;
  migrationY: number;
  /** Speed the shoal makes up the course unaided. See `Tuning.migrationSpeed`. */
  migrationSpeed: number;
  /** >=1. Rises with shoal size so growth costs manoeuvrability. */
  massFactor: number;
  /** Hunters currently in the world. Absent in isolated unit tests. */
  threats?: readonly Threat[];
  /**
   * The medium's grip (1/s). Defaults to the tuned water coupling, so a test
   * that never mentions a medium is a test running in act I water.
   */
  coupling?: number;
  /**
   * Migration force for *free* individuals (1/s); defaults to the tuned water
   * force. Anchored rings always hold with the water force - a held flock is
   * held the same in every medium.
   */
  migrationForce?: number;
  /**
   * Multiplier on the pace a *caged* individual schools at; defaults to 1,
   * which is act I water exactly as it shipped. See `Medium.heldCruise`.
   */
  heldCruise?: number;
  /**
   * 0..1 - how much of this medium is not there. `Medium.vacuum`; defaults to 0,
   * which is every medium the game has except the one act IV is played in.
   *
   * Every boids term in this file is written as `(want - have) * weight`, which
   * is a *velocity controller*: it does not push a body, it drives its speed to a
   * target and holds it there. That is the right model inside a fluid, because a
   * fluid really does impose a terminal velocity - and it is exactly wrong in
   * vacuum, where it would mean a swarm of dust motes with engines in them,
   * accelerating to cruise speed against nothing and holding it forever.
   *
   * So this number turns the controllers back into forces. The `- have` half
   * fades out with it, the push is cut to about a quarter, and alignment - which
   * in vacuum is nothing but propulsion pointed wherever everyone happens to be
   * going - fades out entirely. What survives is what should: separation and
   * cohesion as weak internal forces, so the swarm holds together as a cloud,
   * and momentum that nothing removes.
   */
  ballistic?: number;
  /**
   * Acceleration fields - act IV's gravity wells. Absent in every other act.
   *
   * Applied *after* the mass divisor, and deliberately: gravity is the one force
   * in physics that does not care how heavy the thing falling is, and it is also
   * the one force in this game that should not get weaker as the player succeeds
   * at collecting life. A swarm that has doubled falls exactly as a swarm that
   * has not.
   */
  accel?: AccelSampler;
}

/**
 * What remains of the velocity-matching half at full vacuum.
 *
 * Deliberately not zero. A swarm with *exactly* no internal damping is a spring
 * network with no losses: cohesion pulls a mote through the centroid, nothing
 * takes the energy out, and it comes back through faster. Measured, that reads as
 * the cloud slowly boiling. A twelfth of the water's damping is far below
 * anything the player can feel as drag and is enough to keep the cloud a cloud.
 */
const BALLISTIC_DAMP = 0.12;
/** ...and how hard the surviving steering pushes, as a fraction of the water's. */
const BALLISTIC_GAIN = 0.28;

const NO_THREATS: readonly Threat[] = [];

/**
 * Slowblue: boids + water drag + predictive avoidance, one fixed step at a time.
 *
 * The single most important line in this file is the flow coupling term:
 * acceleration toward (waterVelocity - velocity). The player never touches a fish;
 * they change the water, and the water drags every individual. Every "silk" moment
 * in the prototype comes out of that term interacting with alignment.
 */
export class SwarmSimulation {
  readonly agents: Agent[] = [];
  readonly hash = new SpatialHash(44);
  private rng: Rng;
  private t = 0;
  private readonly water = { x: 0, y: 0 };
  private readonly avoidOut = { x: 0, y: 0 };
  private readonly accelOut = { x: 0, y: 0 };

  constructor(seed: number) {
    this.rng = new Rng(seed ^ 0xa11e);
    for (let i = 0; i < MAX_AGENTS; i++) this.agents.push(createAgent());
  }

  reset(seed: number): void {
    this.rng = new Rng(seed ^ 0xa11e);
    this.t = 0;
    for (const a of this.agents) {
      a.alive = false;
      a.faction = MAIN_FACTION;
      a.species = 0;
      a.anchorRadius = 0;
      a.anchored = false;
      a.vx = 0;
      a.vy = 0;
      a.age = 0;
    }
  }

  get time(): number {
    return this.t;
  }

  private alloc(): Agent | null {
    for (const a of this.agents) if (!a.alive) return a;
    return null;
  }

  aliveCount(faction?: number): number {
    let n = 0;
    for (const a of this.agents) {
      if (!a.alive) continue;
      if (faction !== undefined && a.faction !== faction) continue;
      n++;
    }
    return n;
  }

  spawnShoal(count: number, cx: number, cy: number, radius: number): void {
    for (let i = 0; i < count; i++) {
      const a = this.alloc();
      if (a === null) return;
      const ang = this.rng.next() * Math.PI * 2;
      const rad = Math.sqrt(this.rng.next()) * radius;
      a.x = cx + Math.cos(ang) * rad;
      a.y = cy + Math.sin(ang) * rad * 1.35;
      a.px = a.x;
      a.py = a.y;
      a.vx = this.rng.signed() * 12;
      a.vy = -30 - this.rng.next() * 20;
      a.faction = MAIN_FACTION;
      a.species = 0;
      a.anchorRadius = 0;
      a.anchored = false;
      a.alive = true;
      a.variation = 0.92 + this.rng.next() * 0.16;
      a.phase = this.rng.next() * Math.PI * 2;
      a.age = 1;
    }
  }

  spawnPod(
    faction: number,
    cx: number,
    cy: number,
    count: number,
    species = 1,
    ringRadius = 62,
  ): Agent[] {
    const out: Agent[] = [];
    const innerRadius = Math.max(0, ringRadius - POD_EDGE_INSET);
    const spawnRadius = Math.min(26, innerRadius * 0.55);
    for (let i = 0; i < count; i++) {
      const a = this.alloc();
      if (a === null) break;
      const ang = this.rng.next() * Math.PI * 2;
      const rad = Math.sqrt(this.rng.next()) * spawnRadius;
      a.x = cx + Math.cos(ang) * rad;
      a.y = cy + Math.sin(ang) * rad;
      a.px = a.x;
      a.py = a.y;
      a.vx = Math.cos(ang) * 20;
      a.vy = Math.sin(ang) * 20;
      a.faction = faction;
      a.species = species;
      a.anchorX = cx;
      a.anchorY = cy;
      a.anchorRadius = ringRadius;
      a.anchored = true;
      a.alive = true;
      a.variation = 0.92 + this.rng.next() * 0.16;
      a.phase = this.rng.next() * Math.PI * 2;
      a.age = 1;
      out.push(a);
    }
    return out;
  }

  step(dt: number, ctx: SwarmContext): void {
    const { tuning: T, water: waterField, obstacles } = ctx;
    const threats = ctx.threats ?? NO_THREATS;
    this.t += dt;
    this.hash.build(this.agents, Math.max(12, T.perceptionRadius));

    const pr2 = T.perceptionRadius * T.perceptionRadius;
    const sepR = T.separationRadius;
    const invMass = 1 / Math.max(1, ctx.massFactor);
    const avoidMargin = Math.max(18, T.perceptionRadius * 0.8);
    const coupling = ctx.coupling ?? T.flowCoupling;
    const migrationForce = ctx.migrationForce ?? T.migrationForce;
    const heldCruise = ctx.heldCruise ?? 1;
    // Vacuum turns the steering controllers into forces. At `ballistic` 0 all
    // three of these are 1, 1 and `T.alignment` - act I water, to the digit.
    const ballistic = ctx.ballistic ?? 0;
    const damp = 1 - ballistic * (1 - BALLISTIC_DAMP);
    const gain = 1 - ballistic * (1 - BALLISTIC_GAIN);
    const alignment = T.alignment * (1 - ballistic);
    // ...and the organic wander goes with them: a jitter nothing damps is a slow
    // random walk out of the swarm.
    const noise = T.noise * (1 - ballistic * 0.8);

    for (const a of this.agents) {
      if (!a.alive) continue;
      a.age += dt;

      let sepX = 0;
      let sepY = 0;
      let aliX = 0;
      let aliY = 0;
      let cohX = 0;
      let cohY = 0;
      let nSame = 0;

      this.hash.forEachNear(a.x, a.y, (o) => {
        if (o === a || !o.alive) return;
        const dx = a.x - o.x;
        const dy = a.y - o.y;
        const d2 = dx * dx + dy * dy;
        if (d2 > pr2) return;
        const d = Math.sqrt(d2) || 0.0001;
        if (d < sepR) {
          const w = (sepR - d) / sepR;
          sepX += (dx / d) * w;
          sepY += (dy / d) * w;
        }
        // Alignment and cohesion only inside a faction: an un-rescued pod must
        // keep its own identity until the player actually merges it.
        if (o.faction === a.faction) {
          aliX += o.vx;
          aliY += o.vy;
          cohX += o.x;
          cohY += o.y;
          nSame++;
        }
      });

      // A caged individual schools at the medium's held pace, not open-water
      // pace - see `Medium.heldCruise` for why, and for why water's is 1.
      const cruise = T.cruiseSpeed * a.variation * (a.anchored ? heldCruise : 1);
      let ax = 0;
      let ay = 0;

      if (sepX !== 0 || sepY !== 0) {
        const s = 1 / Math.hypot(sepX, sepY);
        ax += (sepX * s * cruise * gain - a.vx * damp) * T.separation;
        ay += (sepY * s * cruise * gain - a.vy * damp) * T.separation;
      }
      if (nSame > 0) {
        const avx = aliX / nSame;
        const avy = aliY / nSame;
        const am = Math.hypot(avx, avy);
        if (am > 0.001 && alignment > 0) {
          ax += ((avx / am) * cruise * gain - a.vx * damp) * alignment;
          ay += ((avy / am) * cruise * gain - a.vy * damp) * alignment;
        }
        const dcx = cohX / nSame - a.x;
        const dcy = cohY / nSame - a.y;
        const dm = Math.hypot(dcx, dcy);
        if (dm > 0.001) {
          ax += ((dcx / dm) * cruise * gain - a.vx * damp) * T.cohesion;
          ay += ((dcy / dm) * cruise * gain - a.vy * damp) * T.cohesion;
        }
      }

      if (a.anchored) {
        // Pods hold station: they are a destination, not a moving target.
        const dx = a.anchorX - a.x;
        const dy = a.anchorY - a.y;
        const dm = Math.hypot(dx, dy) || 0.0001;
        const want = Math.min(cruise * 0.45, dm * 2.2);
        ax += ((dx / dm) * want - a.vx) * T.migrationForce * 1.3;
        ay += ((dy / dm) * want - a.vy) * T.migrationForce * 1.3;
      } else {
        // Deliberately *not* `cruise`. A fish that migrates at the speed every boids
        // term aims at is a fish that never needs the player, because it matches the
        // ocean's drift on its own - see `Tuning.migrationSpeed`.
        const drive = ctx.migrationSpeed * a.variation;
        ax += (ctx.migrationX * drive - a.vx) * migrationForce;
        ay += (ctx.migrationY * drive - a.vy) * migrationForce;
      }

      // --- water drag: the entire game's control channel ---
      // A live rescue ring is a cage. Its fish can school inside it, but the
      // player's current cannot transport them before the shoal opens the ring.
      // RescueSystem clears `anchored`, and the very next step gives them the same
      // water coupling as every other member of the main shoal.
      if (!a.anchored) {
        waterField.sample(a.x, a.y, this.water);
        ax += (this.water.x - a.vx) * coupling;
        ay += (this.water.y - a.vy) * coupling;
      }

      obstacles.avoid(a.x, a.y, a.vx, a.vy, T.avoidLookahead, avoidMargin, this.avoidOut);
      if (this.avoidOut.x !== 0 || this.avoidOut.y !== 0) {
        ax += this.avoidOut.x * T.obstacleAvoidance * cruise;
        ay += this.avoidOut.y * T.obstacleAvoidance * cruise;
      }

      // Flight from hunters. Deliberately a hard, local shove rather than a smart
      // evasive manoeuvre: the shoal tearing open around a hunter is the cost the
      // player is being asked to manage, and it has to look like panic, not tactics.
      for (const th of threats) {
        const dx = a.x - th.x;
        const dy = a.y - th.y;
        const reach = th.size * FLEE_REACH;
        if (dx > reach || dx < -reach || dy > reach || dy < -reach) continue;
        const d2 = dx * dx + dy * dy;
        if (d2 > reach * reach || d2 === 0) continue;
        const d = Math.sqrt(d2);
        const w = 1 - d / reach;
        ax += (dx / d) * cruise * w * T.predatorFear;
        ay += (dy / d) * cruise * w * T.predatorFear;
      }

      if (a.x < WALL_MARGIN) ax += ((WALL_MARGIN - a.x) / WALL_MARGIN) * WALL_PUSH;
      else if (a.x > ctx.width - WALL_MARGIN)
        ax -= ((a.x - (ctx.width - WALL_MARGIN)) / WALL_MARGIN) * WALL_PUSH;

      // Deterministic wander: cheaper than noise lookups and replay-safe.
      ax += Math.sin(this.t * 0.9 + a.phase) * noise;
      ay += Math.cos(this.t * 0.73 + a.phase * 1.7) * noise;

      ax *= invMass;
      ay *= invMass;
      // Gravity, after the mass divisor. See `SwarmContext.accel`.
      if (ctx.accel !== undefined && !a.anchored) {
        this.accelOut.x = 0;
        this.accelOut.y = 0;
        ctx.accel.addTo(a.x, a.y, this.accelOut);
        ax += this.accelOut.x;
        ay += this.accelOut.y;
      }
      const as = limitScale(ax, ay, T.maxAccel);
      a.vx += ax * as * dt;
      a.vy += ay * as * dt;
      const vs = limitScale(a.vx, a.vy, T.maxSpeed * a.variation);
      a.vx *= vs;
      a.vy *= vs;

      a.px = a.x;
      a.py = a.y;
      a.x += a.vx * dt;
      a.y += a.vy * dt;

      if (a.anchored) {
        // Station-keeping is intentionally soft so captive fish still look alive,
        // but the ring itself is a hard boundary. Remove only outward velocity at
        // the edge so agents can turn and continue schooling along the inside.
        const dx = a.x - a.anchorX;
        const dy = a.y - a.anchorY;
        const distance = Math.hypot(dx, dy);
        const limit = Math.max(0, a.anchorRadius - POD_EDGE_INSET);
        if (distance > limit) {
          const nx = distance > 0 ? dx / distance : 0;
          const ny = distance > 0 ? dy / distance : 0;
          a.x = a.anchorX + nx * limit;
          a.y = a.anchorY + ny * limit;
          const outward = a.vx * nx + a.vy * ny;
          if (outward > 0) {
            a.vx -= nx * outward;
            a.vy -= ny * outward;
          }
        }
      }
    }
  }

  centroid(faction = MAIN_FACTION): { x: number; y: number; count: number } {
    let x = 0;
    let y = 0;
    let n = 0;
    for (const a of this.agents) {
      if (!a.alive || a.faction !== faction) continue;
      x += a.x;
      y += a.y;
      n++;
    }
    return n === 0 ? { x: 0, y: 0, count: 0 } : { x: x / n, y: y / n, count: n };
  }

  /** Mean distance from the centroid: how scattered the shoal currently is. */
  spread(faction = MAIN_FACTION): number {
    const c = this.centroid(faction);
    if (c.count === 0) return 0;
    let s = 0;
    for (const a of this.agents) {
      if (!a.alive || a.faction !== faction) continue;
      s += Math.hypot(a.x - c.x, a.y - c.y);
    }
    return s / c.count;
  }
}
