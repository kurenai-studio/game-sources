import Phaser from 'phaser';
import { MOVE, TILE } from '../config';
import { moveCircle } from '../core/collision';
import { DEG, rayCircle, wrapAngle } from '../core/geometry';
import type { Difficulty } from '../levels/campaigns';
import type { HostileSlot, HostileType, Temperament } from '../levels/types';
import type { Door } from './Door';
import { drawDowned, drawFigure, type FigureStyle } from './figures';
import type { NoiseEvent } from './Noise';
import type { World } from './World';

export type EnemyState = 'idle' | 'alert' | 'combat' | 'down';

/** What an enemy needs from the scene it lives in. */
export interface EnemyContext {
  world: World;
  player: { x: number; y: number; alive: boolean; inDark: boolean };
  /** Fires from the enemy along `angle` (several pellets for a shotgun); the scene resolves hits. */
  shoot(e: Enemy, angle: number, pellets?: number): void;
  /** A sound the enemy makes (footsteps, a shout). Shouts alert other enemies. */
  noise(e: Enemy, radius: number, kind: NoiseEvent['kind']): void;
}

const RADIUS = 11;
const HALF_FOV = 60 * DEG;
const VIEW_LIT = 440;
const VIEW_DARK = 190;
/** Always noticed at this distance, whichever way they face. */
const VIEW_CLOSE = 46;
const SPEED_PATROL = 52;
const SPEED_ALERT = 88;
/** Pushers move fast (and loud) towards a fight. */
const SPEED_PUSH = 108;
const TURN = 4.5;
const REACTION: Record<HostileType, number> = { lookout: 0.45, patroller: 0.6, hider: 0.3, heavy: 0.5 };
/** Someone already aimed at a doorway reacts quicker. */
const REACTION_HOLDING = 0.28;
/** Chance to hold rather than push, when not set by the level. */
const HOLD_CHANCE: Record<HostileType, number> = { lookout: 0.7, patroller: 0.3, hider: 1, heavy: 0 };
/** Plate carriers: one more hit than everyone else at that rank. */
const HEAVY_EXTRA_HP = 1;
/** Rifles: heavies fire a little more often. */
const HEAVY_FIRE_RATE = 0.8;
/** How far (in tiles) a holder looks for a spot covering its door, and the distances it likes. */
const HOLD_SEARCH = 5;
const HOLD_MIN = 2.5 * TILE;
const HOLD_MAX = 6.5 * TILE;
const LOOK_AROUND = 2.6;
/** Hiders hold fire until the operator is this close, then open up with a shotgun. */
const HIDER_RANGE = 5 * TILE;
const HIDER_PELLETS = 6;

const STYLE: FigureStyle = { body: 0x991b1b, chest: 0xdc2626, head: 0x2b2b2b, gun: true };
/** A grey vest plate over the red marks someone who takes more than one hit. */
const VEST_CHEST = 0x52525b;
/** How long a wounded enemy is thrown off its aim. */
const FLINCH = 0.4;
/** Helmet, dark plate carrier, rifle. */
const HEAVY_STYLE: FigureStyle = { body: 0x450a0a, chest: 0x3f3f46, head: 0x374151, gun: true, longGun: true };

/**
 * A hostile. Readable rather than clever: Idle (post or patrol), Alert (investigates a noise)
 * and Combat (sees you: turns, reacts, shoots). Noise moves them from Idle to Alert, which is
 * what makes careful play pay off.
 *
 * Gunfire and shouts split them by temperament: pushers come for you, holders take a spot
 * covering the door you'd come through and wait for you there.
 *
 * Hiders never move: they wait behind cover, track you silently and only fire, with a shotgun,
 * once you're close. They punish rushing into a room.
 */
export class Enemy {
  readonly prop = false;
  readonly kind = 'suspect' as const;
  state: EnemyState = 'idle';
  x: number;
  y: number;
  facing: number;
  wasHit = false;
  readonly temperament: Temperament;
  /** Damage left before going down. */
  hp: number;
  /**
   * Somewhere the enemy has been sent (to destroy evidence, say). On the way and once there it
   * ignores the operator; `atErrand` says it has arrived.
   */
  errand: { x: number; y: number } | null = null;
  /** Has seen the operator or heard a fight (a shot, a shout, glass), not just a footstep. */
  alarmed = false;
  atErrand = false;
  private errandSpeed = SPEED_PUSH;
  private flinch = 0;

  private post: { x: number; y: number; facing: number };
  private route: { x: number; y: number }[];
  private routeIndex = 0;
  private path: { x: number; y: number }[] = [];
  private goal: { x: number; y: number } | null = null;
  private investigate: { x: number; y: number } | null = null;
  private pushing = false;
  /** A fight heard by a holder, waiting for a spot to be chosen. */
  private threat: { x: number; y: number } | null = null;
  /** Where a holder has dug in, and the doorway it watches. */
  private hold: { x: number; y: number; facing: number } | null = null;
  private lastSeen: { x: number; y: number } | null = null;
  private sightTime = 0;
  private lostTime = 0;
  private reactTimer = 0;
  /** Seconds left knocked senseless by a blast. */
  private stunned = 0;
  private fireTimer = 0;
  private lookTimer = 0;
  private stepTimer = 0;
  private time = Math.random() * 10;
  private downTime = 0;

  private container: Phaser.GameObjects.Container;
  private gfx: Phaser.GameObjects.Graphics;

  constructor(private scene: Phaser.Scene, readonly type: HostileType, slot: HostileSlot, depth: number, private difficulty: Difficulty) {
    this.x = slot.tx * TILE;
    this.y = slot.ty * TILE;
    this.facing = slot.facing * DEG;
    this.post = { x: this.x, y: this.y, facing: this.facing };
    this.route = (slot.route ?? []).map((p) => ({ x: p.tx * TILE, y: p.ty * TILE }));
    this.temperament = slot.temperament ?? (Math.random() < HOLD_CHANCE[type] ? 'holder' : 'pusher');
    this.hp = difficulty.toughness + (type === 'heavy' ? HEAVY_EXTRA_HP : 0);
    this.gfx = scene.add.graphics();
    drawFigure(this.gfx, this.style);
    // Hiders crouch behind their cover; heavies are bulkier.
    if (type === 'hider') this.gfx.setScale(0.9);
    if (type === 'heavy') this.gfx.setScale(1.1);
    this.container = scene.add.container(this.x, this.y, [this.gfx]).setDepth(depth).setVisible(false);
  }

  get alive(): boolean {
    return this.state !== 'down';
  }

  hitTest(ox: number, oy: number, dx: number, dy: number): number {
    return this.alive ? rayCircle(ox, oy, dx, dy, this.x, this.y, RADIUS) : Infinity;
  }

  private get style(): FigureStyle {
    if (this.type === 'heavy') return HEAVY_STYLE;
    return {
      ...STYLE,
      longGun: this.type === 'hider',
      chest: this.difficulty.toughness > 1 ? VEST_CHEST : STYLE.chest,
    };
  }

  /**
   * Takes `damage` from a shot fired at (fromX, fromY). Returns true if it took them down. A hit
   * that doesn't flinches them off their aim and turns them towards the shooter.
   */
  hit(damage = 1, fromX = this.x, fromY = this.y): boolean {
    if (!this.alive) return false;
    this.wasHit = true;
    this.hp -= damage;
    if (this.hp > 0) {
      this.flinch = FLINCH;
      this.reactTimer = Math.max(this.reactTimer, FLINCH);
      this.fireTimer = Math.max(this.fireTimer, FLINCH);
      if (fromX !== this.x || fromY !== this.y) this.facing = Math.atan2(fromY - this.y, fromX - this.x);
      this.sightTime = 1;
      return false;
    }
    this.state = 'down';
    this.gfx.clear().setRotation(0);
    drawDowned(this.gfx, this.style);
    // The fall: knocked back along the shot and twisting as they go down.
    const away = Math.atan2(this.y - fromY, this.x - fromX);
    this.gfx.setScale(1.25);
    this.scene.tweens.add({ targets: this.gfx, scale: 1, duration: 260, ease: 'Quad.Out' });
    if (fromX !== this.x || fromY !== this.y) {
      this.scene.tweens.add({ targets: this, x: this.x + Math.cos(away) * 6, y: this.y + Math.sin(away) * 6, duration: 200, ease: 'Quad.Out' });
      this.scene.tweens.add({ targets: this.container, rotation: this.container.rotation + Phaser.Math.FloatBetween(-0.6, 0.6), duration: 260, ease: 'Quad.Out' });
    }
    return true;
  }

  /** Knocked senseless by a blast for `seconds`. */
  stun(seconds: number): void {
    if (!this.alive) return;
    this.stunned = Math.max(this.stunned, seconds);
    this.sightTime = 0;
  }

  /** Sends the enemy straight to (x, y), whatever else is going on. */
  sendTo(x: number, y: number, speed = SPEED_PUSH): void {
    this.errand = { x, y };
    this.errandSpeed = speed;
    this.atErrand = false;
    this.goal = null;
    this.hold = null;
    this.threat = null;
  }

  /** The errand is done: back to the fight. */
  release(): void {
    this.errand = null;
    this.atErrand = false;
    this.goal = null;
    this.state = 'alert';
  }

  /** Called for every noise in the level. */
  hear(e: NoiseEvent): void {
    if (!this.alive || this.state === 'combat') return;
    // Their own side's footsteps aren't interesting; shouts, shots, doors and you are.
    if (e.source === 'world' && e.kind !== 'shout' && e.kind !== 'shot' && e.kind !== 'glass') return;
    if (Math.hypot(e.x - this.x, e.y - this.y) > e.radius) return;
    // Once dug in, a holder stays put whatever it hears; a hider never leaves its cover.
    if (this.hold) return;
    if (this.type === 'hider') {
      this.state = 'alert';
      return;
    }
    const fight = e.kind === 'shot' || e.kind === 'shout' || e.kind === 'glass';
    if (fight) this.alarmed = true;
    this.state = 'alert';
    this.goal = null;
    this.lookTimer = 0;
    if (fight && this.temperament === 'holder') {
      this.threat = { x: e.x, y: e.y };
      this.investigate = null;
      return;
    }
    this.pushing = fight;
    this.investigate = { x: e.x + Phaser.Math.Between(-12, 12), y: e.y + Phaser.Math.Between(-12, 12) };
  }

  /** True while dug in at its spot, aimed at the doorway. */
  private get dugIn(): boolean {
    return !!this.hold && Math.hypot(this.hold.x - this.x, this.hold.y - this.y) < 8;
  }

  /** @param visible whether the operator can currently see this enemy */
  update(dt: number, ctx: EnemyContext, visible: boolean): void {
    this.container.setVisible(visible);
    if (!this.alive) {
      // Fall and fade, but stay readable as a body.
      this.container.setPosition(this.x, this.y);
      this.downTime += dt;
      this.container.setAlpha(Math.max(0.55, 1 - this.downTime * 0.25));
      return;
    }
    this.time += dt;
    // Stunned by a blast: reeling, not seeing, moving or shooting, then up and alert.
    if (this.stunned > 0) {
      this.stunned -= dt;
      this.gfx.rotation = this.stunned > 0 ? Math.sin(this.time * 9) * 0.35 * Math.min(1, this.stunned) : 0;
      this.container.setPosition(this.x, this.y);
      if (this.stunned <= 0 && this.state === 'idle') this.state = 'alert';
      return;
    }
    if (this.flinch > 0) {
      this.flinch -= dt;
      this.gfx.rotation = this.flinch > 0 ? Math.sin(this.flinch * 60) * 0.25 : 0;
    }

    if (this.errand) {
      this.atErrand = this.walkTo(this.errand, this.errandSpeed, dt, ctx);
      this.container.setPosition(this.x, this.y);
      this.container.rotation = this.facing;
      return;
    }

    const p = ctx.player;
    const dx = p.x - this.x, dy = p.y - this.y;
    const dist = Math.hypot(dx, dy);
    const toPlayer = Math.atan2(dy, dx);
    let sees = false;
    if (p.alive && dist < (p.inDark ? VIEW_DARK : VIEW_LIT)) {
      const inCone = Math.abs(wrapAngle(toPlayer - this.facing)) < HALF_FOV;
      if ((dist < VIEW_CLOSE || inCone || this.state === 'combat') && ctx.world.lineOfSight(this.x, this.y, p.x, p.y)) sees = true;
    }

    if (sees) {
      this.lastSeen = { x: p.x, y: p.y };
      this.lostTime = 0;
      // Closer, already alert or dug in and aimed means noticing faster.
      const notice = (this.dugIn ? 0.06 + dist / 2400 : (this.state === 'alert' ? 0.12 : 0.35) + dist / 1600) * this.difficulty.notice;
      this.sightTime += dt;
      if (this.state !== 'combat' && this.sightTime >= notice) this.enterCombat(ctx);
    } else {
      this.sightTime = Math.max(0, this.sightTime - dt * 0.5);
    }

    switch (this.state) {
      case 'idle':
        this.updateIdle(dt, ctx);
        break;
      case 'alert':
        this.updateAlert(dt, ctx);
        break;
      case 'combat':
        this.updateCombat(dt, ctx, sees, toPlayer);
        break;
    }

    this.container.setPosition(this.x, this.y);
    this.container.rotation = this.facing;
  }

  private enterCombat(ctx: EnemyContext): void {
    this.state = 'combat';
    this.alarmed = true;
    this.reactTimer = (this.dugIn ? REACTION_HOLDING : REACTION[this.type]) * this.difficulty.reaction;
    this.fireTimer = 0;
    this.path = [];
    this.goal = null;
    if (this.type === 'lookout') ctx.noise(this, 420, 'shout');
  }

  private updateIdle(dt: number, ctx: EnemyContext): void {
    if (this.type === 'hider') {
      // Still, behind cover, watching their arc.
      this.turnTo(this.post.facing + Math.sin(this.time * 0.4) * 12 * DEG, dt, 0.8);
      return;
    }
    if (this.type === 'patroller' && this.route.length) {
      const target = this.route[this.routeIndex];
      if (this.walkTo(target, SPEED_PATROL, dt, ctx)) this.routeIndex = (this.routeIndex + 1) % this.route.length;
      return;
    }
    // Back at the post if an investigation took them away; then a slow scan of their arc.
    if (Math.hypot(this.post.x - this.x, this.post.y - this.y) > 6) {
      this.walkTo(this.post, SPEED_PATROL, dt, ctx);
      return;
    }
    const scan = this.post.facing + Math.sin(this.time * 0.6) * 22 * DEG;
    this.turnTo(scan, dt, 1.2);
  }

  private updateAlert(dt: number, ctx: EnemyContext): void {
    if (this.type === 'hider') {
      this.turnTo(this.post.facing + Math.sin(this.time * 0.8) * 18 * DEG, dt, 2);
      return;
    }
    if (this.threat) {
      this.hold = this.chooseHold(this.threat, ctx.world);
      this.threat = null;
    }
    if (this.hold) {
      // Get into position, then stay aimed at the doorway with only a slight scan.
      if (!this.walkTo(this.hold, SPEED_ALERT, dt, ctx)) return;
      this.turnTo(this.hold.facing + Math.sin(this.time * 1.1) * 10 * DEG, dt, 3);
      return;
    }
    if (this.investigate) {
      if (this.walkTo(this.investigate, this.pushing ? SPEED_PUSH : SPEED_ALERT, dt, ctx)) {
        this.investigate = null;
        this.lookTimer = LOOK_AROUND;
      }
      return;
    }
    if (this.lookTimer > 0) {
      this.lookTimer -= dt;
      this.facing = wrapAngle(this.facing + dt * 1.8 * Math.sign(Math.sin(this.time * 0.9)));
      return;
    }
    this.state = 'idle';
    this.goal = null;
    this.pushing = false;
  }

  private updateCombat(dt: number, ctx: EnemyContext, sees: boolean, toPlayer: number): void {
    if (!sees) {
      this.lostTime += dt;
      if (this.lostTime > 0.7 && this.lastSeen) {
        // Lost them: holders go back to covering their door, pushers chase, hiders stay put.
        this.state = 'alert';
        this.goal = null;
        if (!this.hold && this.type !== 'hider') {
          this.investigate = this.lastSeen;
          this.pushing = true;
        }
      }
      return;
    }
    this.turnTo(toPlayer, dt, TURN);
    // A hider tracks you silently and holds fire until you're close.
    const hider = this.type === 'hider';
    if (hider && Math.hypot(ctx.player.x - this.x, ctx.player.y - this.y) > HIDER_RANGE) return;
    this.reactTimer -= dt;
    const aligned = Math.abs(wrapAngle(toPlayer - this.facing)) < 12 * DEG;
    if (this.reactTimer > 0 || !aligned) return;
    this.fireTimer -= dt;
    if (this.fireTimer <= 0) {
      const [min, max] = this.difficulty.fireInterval;
      this.fireTimer = Phaser.Math.FloatBetween(min, max) * (hider ? 1.3 : this.type === 'heavy' ? HEAVY_FIRE_RATE : 1);
      const error = (Math.random() + Math.random() - 1) * this.difficulty.spread * DEG;
      ctx.shoot(this, this.facing + error, hider ? HIDER_PELLETS : 1);
    }
  }

  /**
   * Picks a spot to dig in: on this side of the door a threat would come through, a few tiles
   * back from it, with a clear view of the doorway. With no door in between, it covers the
   * direction of the noise from where it stands.
   */
  private chooseHold(threat: { x: number; y: number }, world: World): { x: number; y: number; facing: number } {
    const route = world.findPath(this.x, this.y, threat.x, threat.y) ?? [];
    let door: Door | undefined;
    for (const p of route) {
      door = world.doorAtTile(Math.floor(p.x / TILE), Math.floor(p.y / TILE));
      if (door) break;
    }
    if (!door) return { x: this.x, y: this.y, facing: Math.atan2(threat.y - this.y, threat.x - this.x) };

    const side = (x: number, y: number) => Math.sign(door!.spec.orientation === 'h' ? y - door!.cy : x - door!.cx);
    const mySide = side(this.x, this.y);
    let best = { x: this.x, y: this.y, score: -Infinity };
    const tx0 = Math.floor(this.x / TILE), ty0 = Math.floor(this.y / TILE);
    for (let ty = ty0 - HOLD_SEARCH; ty <= ty0 + HOLD_SEARCH; ty++) {
      for (let tx = tx0 - HOLD_SEARCH; tx <= tx0 + HOLD_SEARCH; tx++) {
        if (world.solid(tx, ty) || world.doorAtTile(tx, ty) || world.isOutdoor(tx, ty)) continue;
        const cx = (tx + 0.5) * TILE, cy = (ty + 0.5) * TILE;
        if (side(cx, cy) !== mySide) continue;
        const d = Math.hypot(cx - door.cx, cy - door.cy);
        if (d < HOLD_MIN || d > HOLD_MAX) continue;
        // Sight line to a point just short of the door leaf, on our side of it.
        const ax = door.cx + ((cx - door.cx) / d) * 10, ay = door.cy + ((cy - door.cy) / d) * 10;
        if (!world.lineOfSight(cx, cy, ax, ay)) continue;
        // Prefer further back from the door, close to where they already are, with some variety.
        const score = d - Math.hypot(cx - this.x, cy - this.y) * 0.5 + Math.random() * 24;
        if (score > best.score) best = { x: cx, y: cy, score };
      }
    }
    return { x: best.x, y: best.y, facing: Math.atan2(door.cy - best.y, door.cx - best.x) };
  }

  /** Walks towards `target` along a path; returns true on arrival. */
  private walkTo(target: { x: number; y: number }, speed: number, dt: number, ctx: EnemyContext): boolean {
    if (Math.hypot(target.x - this.x, target.y - this.y) < 6) return true;
    if (!this.goal || this.goal.x !== target.x || this.goal.y !== target.y) {
      this.goal = target;
      this.path = ctx.world.findPath(this.x, this.y, target.x, target.y) ?? [];
      if (!this.path.length) {
        // Unreachable: give up on it.
        this.goal = null;
        return true;
      }
      this.path[this.path.length - 1] = { ...target };
    }
    const next = this.path[0];
    if (!next) return true;

    // Doors in the way get opened, then waited for.
    const door = ctx.world.doorAtTile(Math.floor(next.x / TILE), Math.floor(next.y / TILE));
    if (door?.blocksMovement) {
      if (door.state === 'closed' && Math.hypot(door.cx - this.x, door.cy - this.y) < TILE * 1.6) {
        const radius = door.toggle(this.x, this.y);
        ctx.noise(this, radius, 'door');
      }
      this.turnTo(Math.atan2(next.y - this.y, next.x - this.x), dt, TURN);
      if (door.state === 'open') return false;
    }

    // Stop short rather than walk into the operator.
    if (Math.hypot(ctx.player.x - this.x, ctx.player.y - this.y) < MOVE.radius * 2 + 4) return false;

    const dx = next.x - this.x, dy = next.y - this.y;
    const d = Math.hypot(dx, dy);
    if (d < 4) {
      this.path.shift();
      return this.path.length === 0;
    }
    const step = Math.min(d, speed * dt);
    const moved = moveCircle(this.x, this.y, (dx / d) * step, (dy / d) * step, MOVE.radius, TILE, ctx.world.solid);
    this.x = moved.x;
    this.y = moved.y;
    this.turnTo(Math.atan2(dy, dx), dt, TURN);

    this.stepTimer -= dt;
    if (this.stepTimer <= 0) {
      this.stepTimer = speed > SPEED_PATROL ? 0.38 : 0.55;
      ctx.noise(this, speed > SPEED_PATROL ? 260 : 190, 'step');
    }
    return false;
  }

  private turnTo(angle: number, dt: number, rate: number): void {
    const diff = wrapAngle(angle - this.facing);
    this.facing = wrapAngle(this.facing + Phaser.Math.Clamp(diff, -rate * dt, rate * dt));
  }
}
