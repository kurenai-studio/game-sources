import Phaser from 'phaser';

export interface NoiseEvent {
  x: number;
  y: number;
  /** How far away the sound can be heard, in px. */
  radius: number;
  source: 'player' | 'world';
  kind: 'step' | 'door' | 'shot' | 'shout' | 'glass' | 'reload' | 'other';
}

interface Ripple {
  x: number;
  y: number;
  r0: number;
  r1: number;
  age: number;
  life: number;
  color: number;
  alpha: number;
}

/**
 * Sound as information. Every noise is an event that AI can listen to (enemies arrive with the
 * vertical slice). The player sees their own noise as a ring showing how far it carries, and
 * hears world noises as a vague ripple near the source, even through walls.
 */
export class NoiseSystem {
  private ripples: Ripple[] = [];
  private listeners: ((e: NoiseEvent) => void)[] = [];
  private gfx: Phaser.GameObjects.Graphics;

  constructor(scene: Phaser.Scene, depth: number) {
    this.gfx = scene.add.graphics().setDepth(depth);
  }

  onNoise(fn: (e: NoiseEvent) => void): void {
    this.listeners.push(fn);
  }

  emit(e: NoiseEvent, listenerX: number, listenerY: number): void {
    for (const fn of this.listeners) fn(e);
    if (e.source === 'player') {
      // Quiet sounds (walking) don't get a ring; the ring is there to show what's loud.
      if (e.radius < 100) return;
      this.ripples.push({ x: e.x, y: e.y, r0: 12, r1: e.radius, age: 0, life: 0.45, color: 0x93c5fd, alpha: 0.35 });
      return;
    }
    const d = Math.hypot(e.x - listenerX, e.y - listenerY);
    if (d > e.radius) return;
    // Vague on purpose: you know something is there, not exactly where.
    const jitter = 22;
    const x = e.x + Phaser.Math.FloatBetween(-jitter, jitter);
    const y = e.y + Phaser.Math.FloatBetween(-jitter, jitter);
    this.ripples.push({ x, y, r0: 6, r1: 34, age: 0, life: 0.7, color: 0xffffff, alpha: 0.55 });
    this.ripples.push({ x, y, r0: 2, r1: 20, age: -0.12, life: 0.6, color: 0xffffff, alpha: 0.4 });
  }

  update(dt: number): void {
    const g = this.gfx;
    g.clear();
    this.ripples = this.ripples.filter((r) => (r.age += dt) < r.life);
    for (const r of this.ripples) {
      if (r.age < 0) continue;
      const k = r.age / r.life;
      const radius = r.r0 + (r.r1 - r.r0) * Phaser.Math.Easing.Cubic.Out(k);
      g.lineStyle(2, r.color, r.alpha * (1 - k));
      g.strokeCircle(r.x, r.y, radius);
    }
  }
}
