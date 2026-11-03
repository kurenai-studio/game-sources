import Phaser from 'phaser';
import { MOVE, TILE } from '../config';
import { DEG, wrapAngle } from '../core/geometry';
import { moveCircle } from '../core/collision';
import { WEAPONS, WeaponState, type WeaponId } from './weapons';

export interface PlayerInput {
  moveX: number;
  moveY: number;
  sprint: boolean;
  /** World-space angle towards the cursor. */
  aimAt: number;
  /** Speed multiplier, e.g. for the brisk walk in the intro. Doesn't make footsteps louder. */
  pace?: number;
}

export interface StepEvent {
  loud: boolean;
}

/** How quickly the operator reaches full speed and comes to a stop (per second). */
const ACCEL = 12;
const DECEL = 16;
/** How quickly the aim eases towards the cursor, before the gun's turn-rate cap. */
const TURN_EASE = 24;

const GUN_LENGTH: Record<WeaponId, number> = { pistol: 17, shotgun: 25, rifle: 26, sniper: 31 };
/** How much a suppressor adds to the barrel. */
const SUPPRESSOR_LENGTH = 6;

export class Player {
  x: number;
  y: number;
  facing = 0;
  /** 0 = rock steady, 1 = all over the place. Drives the laser wobble. */
  instability = 0;
  sprinting = false;
  moving = false;
  /** Light body armour absorbs the first hit; two more take the operator down. */
  armor = 1;
  health = 2;
  weapon: WeaponState;
  /** Fit a suppressor to every carried gun that takes one. */
  suppressors = false;

  private vx = 0;
  private vy = 0;
  private gunKick = 0;
  private weapons = new Map<WeaponId, WeaponState>();
  private container: Phaser.GameObjects.Container;
  private gunGfx: Phaser.GameObjects.Graphics;
  private bodyGfx: Phaser.GameObjects.Graphics;
  private feet: Phaser.GameObjects.Graphics;
  /** Walk cycle, in radians: drives the boots, the shoulders and a little gun bob. */
  private stride = 0;
  private stepTimer = 0;
  private time = 0;
  private hurtTimer = 0;

  constructor(private scene: Phaser.Scene, x: number, y: number, depth: number) {
    this.x = x;
    this.y = y;
    this.weapon = this.equip('pistol');

    const shadow = scene.add.graphics();
    shadow.fillStyle(0x000000, 0.3);
    shadow.fillEllipse(1.5, 2.5, 22, 30);

    // Boots, under everything else; they step in turn as the operator walks.
    this.feet = scene.add.graphics();

    const body = scene.add.graphics();
    this.bodyGfx = body;
    // Vest and shoulders, in the operator's blue.
    body.fillStyle(0x1d4ed8, 1);
    body.fillEllipse(0, 0, 15, 25);
    body.fillStyle(0x3b82f6, 1);
    body.fillEllipse(1, 0, 10, 18);
    body.lineStyle(1, 0x0b1d4a, 0.9);
    body.strokeEllipse(0, 0, 15, 25);
    // Helmet with a light catching its top.
    body.fillStyle(0x1e293b, 1);
    body.fillCircle(1, 0, 6.5);
    body.fillStyle(0xffffff, 0.18);
    body.fillCircle(0, -1.8, 3);
    body.fillStyle(0x93c5fd, 0.9);
    body.fillRect(6, -2.5, 1.5, 5);

    this.gunGfx = scene.add.graphics();
    // The gun and arms sit over the body, so the gun reads clearly from above.
    this.container = scene.add.container(x, y, [shadow, this.feet, body, this.gunGfx]).setDepth(depth);
    this.drawGun();
  }

  get displayObject(): Phaser.GameObjects.Container {
    return this.container;
  }

  get alive(): boolean {
    return this.health > 0;
  }

  /** Takes a hit. Returns true if it took the operator down. */
  damage(): boolean {
    // A shotgun's pellets or two shots in the same instant count as one hit.
    if (!this.alive || this.hurtTimer > 0) return false;
    this.hurtTimer = 0.25;
    if (this.armor > 0) this.armor--;
    else this.health--;
    this.kick(0.6);
    if (!this.alive) {
      // Down: a slump to the floor rather than a cut.
      this.feet.clear();
      this.scene.tweens.add({ targets: this.container, rotation: this.container.rotation + 1.1, scale: 0.86, alpha: 0.65, duration: 420, ease: 'Quad.In' });
    }
    return !this.alive;
  }

  /** The angle the laser (and every shot) actually points: facing plus a slow drift. */
  get aimAngle(): number {
    const t = this.time;
    const n = Math.sin(t * 1.9) * 0.6 + Math.sin(t * 3.3 + 1.3) * 0.3 + Math.sin(t * 5.7 + 2.1) * 0.1;
    return this.facing + this.instability * this.weapon.def.wobble * DEG * n;
  }

  get muzzle(): { x: number; y: number } {
    const len = GUN_LENGTH[this.weapon.def.id] + (this.weapon.suppressed ? SUPPRESSOR_LENGTH : 0);
    return { x: this.x + Math.cos(this.facing) * len, y: this.y + Math.sin(this.facing) * len };
  }

  equip(id: WeaponId): WeaponState {
    let w = this.weapons.get(id);
    if (!w) {
      w = new WeaponState(WEAPONS[id]);
      this.weapons.set(id, w);
    }
    const swapped = !!this.weapon && this.weapon !== w;
    if (swapped) this.weapon.reloadLeft = 0;
    w.suppressed = this.suppressors && w.def.suppressible;
    this.weapon = w;
    if (this.gunGfx) {
      this.drawGun();
      // The new gun comes up into the aim.
      if (swapped) {
        this.gunGfx.setScale(0.6).setAlpha(0.4);
        this.scene.tweens.add({ targets: this.gunGfx, scale: 1, alpha: 1, duration: 180, ease: 'Back.Out' });
      }
    }
    return w;
  }

  update(dt: number, input: PlayerInput, solid: (tx: number, ty: number) => boolean): StepEvent | null {
    this.time += dt;
    this.hurtTimer = Math.max(0, this.hurtTimer - dt);
    const len = Math.hypot(input.moveX, input.moveY);
    const wantsToMove = len > 0;
    const speed = (wantsToMove && input.sprint ? MOVE.sprint : MOVE.walk) * (input.pace ?? 1);
    const tvx = wantsToMove ? (input.moveX / len) * speed : 0;
    const tvy = wantsToMove ? (input.moveY / len) * speed : 0;
    const k = 1 - Math.exp(-(wantsToMove ? ACCEL : DECEL) * dt);
    this.vx += (tvx - this.vx) * k;
    this.vy += (tvy - this.vy) * k;
    if (!wantsToMove && Math.hypot(this.vx, this.vy) < 4) this.vx = this.vy = 0;

    if (this.vx !== 0 || this.vy !== 0) {
      const p = moveCircle(this.x, this.y, this.vx * dt, this.vy * dt, MOVE.radius, TILE, solid);
      // Lose the velocity a wall absorbed, so the operator doesn't "push" against it.
      if (dt > 0) {
        this.vx = (p.x - this.x) / dt;
        this.vy = (p.y - this.y) / dt;
      }
      this.x = p.x;
      this.y = p.y;
    }
    const actual = Math.hypot(this.vx, this.vy);
    this.moving = actual > 20;
    this.sprinting = this.moving && input.sprint && actual > MOVE.walk * 1.1;

    // Aim eases towards the cursor; heavier guns are capped to a slower swing.
    const before = this.facing;
    const diff = wrapAngle(input.aimAt - this.facing);
    const maxStep = this.weapon.def.turnRate * DEG * dt;
    this.facing = wrapAngle(this.facing + Phaser.Math.Clamp(diff * (1 - Math.exp(-TURN_EASE * dt)), -maxStep, maxStep));
    const angularSpeed = Math.abs(wrapAngle(this.facing - before)) / Math.max(dt, 1e-4);
    const turnShake = Math.min(0.3, (angularSpeed / (this.weapon.def.turnRate * DEG)) * 0.3);

    const target = Math.max(this.sprinting ? 1 : this.moving ? 0.35 : 0, turnShake);
    const rate = target > this.instability ? 5 : 3;
    this.instability += (target - this.instability) * Math.min(1, rate * dt);

    this.gunKick *= Math.exp(-18 * dt);
    this.weapon.update(dt);
    this.animate(dt, actual);
    this.container.setPosition(this.x, this.y);
    this.container.rotation = this.facing;

    if (!wantsToMove || !this.moving) {
      this.stepTimer = 0;
      return null;
    }
    this.stepTimer -= dt;
    if (this.stepTimer <= 0) {
      this.stepTimer = this.sprinting ? MOVE.stepSprint : MOVE.stepWalk;
      return { loud: this.sprinting };
    }
    return null;
  }

  /**
   * The walk cycle and the gun: boots step in turn and the shoulders sway with them, faster at a
   * sprint; recoil knocks the gun back; a reload dips and tilts it.
   */
  private animate(dt: number, speed: number): void {
    if (!this.alive) return;
    const pace = Math.min(1, speed / MOVE.walk);
    this.stride += dt * (this.sprinting ? 15 : 10) * Math.min(1, pace + 0.2);
    const swing = Math.sin(this.stride) * pace;
    const f = this.feet;
    f.clear();
    if (pace > 0.05) {
      f.fillStyle(0x0f172a, 0.95);
      f.fillEllipse(swing * 6, -5, 8, 5);
      f.fillEllipse(-swing * 6, 5, 8, 5);
    }
    this.bodyGfx.rotation = swing * 0.07;
    const w = this.weapon;
    const reload = w.reloading ? Math.sin((1 - w.reloadLeft / w.def.reloadTime) * Math.PI) : 0;
    this.gunGfx.x = -this.gunKick * 4 - reload * 3;
    this.gunGfx.y = Math.abs(swing) * 0.8 + reload * 2;
    this.gunGfx.rotation = swing * 0.04 + reload * 0.55;
  }

  /** Recoil: unsettles the aim and knocks the gun back a little. */
  kick(amount: number): void {
    this.instability = Math.min(1.2, this.instability + amount);
    this.gunKick = 1;
  }

  /**
   * The gun and the arms holding it, seen from above and pointing along +x. Each gun has its own
   * silhouette (parts drawn as [from, to, width, colour] along the barrel line), a lit top edge,
   * and hands where you would hold it: both on the grip of a pistol, one on the grip and one on
   * the handguard or pump of a long gun.
   */
  private drawGun(): void {
    const g = this.gunGfx;
    const id = this.weapon.def.id;
    const len = GUN_LENGTH[id];
    const METAL = 0x3a414b, DARK = 0x262b32, WOOD = 0x6b4428, EDGE = 0x9aa5b4;
    const parts: Record<WeaponId, [number, number, number, number][]> = {
      pistol: [[7, 10, 3.6, DARK], [9, len, 3.2, METAL]],
      shotgun: [[5, 9, 4, WOOD], [9, 13, 4.4, METAL], [13, len, 2.4, METAL], [14, 20, 4, WOOD]],
      rifle: [[5, 9, 4, DARK], [9, 15, 4.4, METAL], [15, 22, 3.6, DARK], [22, len, 1.8, METAL]],
      sniper: [[5, 10, 4.2, DARK], [10, 15, 3.8, METAL], [15, len, 2, METAL]],
    };
    const front = { pistol: 10, shotgun: 17, rifle: 18, sniper: 17 }[id];
    const hands: [number, number][] = id === 'pistol' ? [[10, -1.2], [8.6, 1.5]] : [[front, -0.4], [10, 1.6]];
    g.clear();

    // Arms: sleeves from the shoulders to the hands, with a lighter top so they read as round.
    const arm = (sx: number, sy: number, hx: number, hy: number) => {
      g.lineStyle(3.2, 0x1e3a8a, 1);
      g.lineBetween(sx, sy, hx, hy);
      g.lineStyle(1.2, 0x3b63d6, 0.8);
      g.lineBetween(sx, sy - 0.5, hx, hy - 0.5);
    };
    arm(2, -7, hands[0][0], hands[0][1]);
    arm(2, 7, hands[1][0], hands[1][1]);

    // The gun, part by part, each with a lit top edge.
    for (const [x0, x1, w, c] of parts[id]) {
      g.fillStyle(c, 1);
      g.fillRect(x0, -w / 2, x1 - x0, w);
      g.fillStyle(EDGE, c === WOOD ? 0.35 : 0.7);
      g.fillRect(x0, -w / 2, x1 - x0, 0.8);
    }
    if (id === 'sniper') {
      // The scope over the receiver, with a glint on the lens.
      g.fillStyle(0x111418, 1);
      g.fillRect(10, -1.7, 11, 3.4);
      g.fillStyle(EDGE, 0.6);
      g.fillRect(10, -1.7, 11, 0.8);
      g.fillStyle(0x93c5fd, 0.9);
      g.fillRect(20.2, -1.1, 0.9, 2.2);
    }
    if (id === 'rifle') {
      g.fillStyle(DARK, 1);
      g.fillRect(11, -1, 3, 2);
    }
    if (this.weapon.suppressed) {
      g.fillStyle(0x111418, 1);
      g.fillRect(len, -1.9, SUPPRESSOR_LENGTH, 3.8);
      g.fillStyle(EDGE, 0.5);
      g.fillRect(len, -1.9, SUPPRESSOR_LENGTH, 0.8);
    }
    // Gloved hands on top.
    g.fillStyle(0x1c1c20, 1);
    for (const [hx, hy] of hands) g.fillCircle(hx, hy, 1.8);
    g.fillStyle(0xffffff, 0.12);
    for (const [hx, hy] of hands) g.fillCircle(hx - 0.4, hy - 0.6, 0.7);
  }
}
