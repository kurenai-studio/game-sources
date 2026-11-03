import Phaser from 'phaser';
import { MOVE, TILE } from '../config';
import { moveCircle } from '../core/collision';
import { rayCircle, wrapAngle } from '../core/geometry';
import type { CivilianSlot } from '../levels/types';
import { drawDowned, drawFigure, type FigureStyle } from './figures';
import type { NoiseEvent } from './Noise';
import type { World } from './World';

export type CivilianState = 'idle' | 'cower' | 'flee' | 'secured' | 'down';

const RADIUS = 11;
const FLEE_SPEED = 120;
/** Seconds of holding E next to someone to get them on the ground. */
export const SECURE_TIME = 0.8;

const STYLE: FigureStyle = { body: 0xa16207, chest: 0xfacc15, head: 0x7c5a3c };

/**
 * Civilians panic: on gunfire they either freeze where they are or run for somewhere away from
 * it, which can put them in the line of fire or a doorway. Holding E next to one secures them.
 */
export class Civilian {
  readonly prop = false;
  readonly kind = 'civilian' as const;
  state: CivilianState = 'idle';
  x: number;
  y: number;
  facing = Math.random() * Math.PI * 2;
  wasHit = false;
  /** 0..1 while the operator is securing them. */
  secureProgress = 0;

  private path: { x: number; y: number }[] = [];
  private container: Phaser.GameObjects.Container;
  private gfx: Phaser.GameObjects.Graphics;

  /** @param hostage held where they are: kneeling, and never runs */
  constructor(scene: Phaser.Scene, slot: CivilianSlot, depth: number, readonly hostage = false) {
    this.x = slot.tx * TILE;
    this.y = slot.ty * TILE;
    if (hostage) this.state = 'cower';
    this.gfx = scene.add.graphics();
    this.container = scene.add.container(this.x, this.y, [this.gfx]).setDepth(depth).setVisible(false);
    this.redraw();
  }

  get alive(): boolean {
    return this.state !== 'down';
  }

  get canBeSecured(): boolean {
    return this.state === 'idle' || this.state === 'cower' || this.state === 'flee';
  }

  hitTest(ox: number, oy: number, dx: number, dy: number): number {
    return this.alive ? rayCircle(ox, oy, dx, dy, this.x, this.y, RADIUS) : Infinity;
  }

  /** Any hit takes a civilian down. Returns true if this hit did. */
  hit(): boolean {
    if (!this.alive) return false;
    this.state = 'down';
    this.wasHit = true;
    this.redraw();
    return true;
  }

  secure(): void {
    this.state = 'secured';
    this.path = [];
    this.redraw();
  }

  hear(e: NoiseEvent, world: World): void {
    if (this.state !== 'idle' || this.hostage) return;
    if (e.kind !== 'shot' && e.kind !== 'shout' && e.kind !== 'glass') return;
    if (Math.hypot(e.x - this.x, e.y - this.y) > e.radius) return;
    if (Math.random() < 0.5) {
      this.state = 'cower';
    } else {
      this.state = 'flee';
      this.path = this.fleePath(e, world);
      if (!this.path.length) this.state = 'cower';
    }
    this.redraw();
  }

  update(dt: number, world: World, visible: boolean, px: number, py: number): void {
    this.container.setVisible(visible);
    if (this.state === 'flee') {
      const next = this.path[0];
      if (!next) {
        this.state = 'cower';
        this.redraw();
      } else {
        const dx = next.x - this.x, dy = next.y - this.y, d = Math.hypot(dx, dy);
        if (d < 5) this.path.shift();
        else {
          const step = Math.min(d, FLEE_SPEED * dt);
          const m = moveCircle(this.x, this.y, (dx / d) * step, (dy / d) * step, MOVE.radius, TILE, world.solid);
          this.x = m.x;
          this.y = m.y;
          this.facing = Math.atan2(dy, dx);
        }
      }
    } else if (this.state === 'idle' || this.state === 'cower') {
      // Keep an eye on the operator once they're in the room.
      if (visible) {
        const to = Math.atan2(py - this.y, px - this.x);
        this.facing = wrapAngle(this.facing + Phaser.Math.Clamp(wrapAngle(to - this.facing), -3 * dt, 3 * dt));
      }
    }
    this.container.setPosition(this.x, this.y);
    this.container.rotation = this.facing;
  }

  /** Somewhere reachable a few rooms away from the danger. */
  private fleePath(e: NoiseEvent, world: World): { x: number; y: number }[] {
    const away = Math.atan2(this.y - e.y, this.x - e.x);
    for (let attempt = 0; attempt < 12; attempt++) {
      const a = away + Phaser.Math.FloatBetween(-1, 1);
      const r = Phaser.Math.FloatBetween(4, 9) * TILE;
      const tx = Math.floor((this.x + Math.cos(a) * r) / TILE), ty = Math.floor((this.y + Math.sin(a) * r) / TILE);
      if (world.solid(tx, ty) || world.isOutdoor(tx, ty)) continue;
      const path = world.findPath(this.x, this.y, (tx + 0.5) * TILE, (ty + 0.5) * TILE, false);
      if (path && path.length > 2) return path;
    }
    return [];
  }

  private redraw(): void {
    const g = this.gfx;
    g.clear();
    if (this.state === 'down') {
      drawDowned(g, STYLE);
      return;
    }
    const scale = this.state === 'cower' || this.state === 'secured' ? 0.85 : 1;
    this.gfx.setScale(scale);
    drawFigure(g, { ...STYLE, handsUp: this.state === 'cower' || this.state === 'idle', restrained: this.state === 'secured' });
  }
}
