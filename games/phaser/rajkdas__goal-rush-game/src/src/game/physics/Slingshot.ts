/**
 * GOAL RUSH — Slingshot.
 *
 * A static triangle whose angled face kicks the ball up-field on contact.
 * Kick is a fixed velocity along the face normal (arcade snappy), gated by
 * a cooldown so the ball is launched once per touch, not per physics frame.
 */

import * as Phaser from 'phaser';
import { PALETTE } from '../config/game.config';
import { SLINGSHOT as CFG } from '../config/game.config';
import type { SlingDef } from '../config/table.config';
import type { BallRef } from './types';

export class Slingshot {
  private lastKick = -9999;

  constructor(
    private scene: Phaser.Scene,
    private def: SlingDef,
    private particles: Phaser.GameObjects.Particles.ParticleEmitter
  ) {
    // Static triangular body from vertices.
    const centroid = this.centroid(def.points);
    const verts = def.points.map((p) => ({ x: p.x - centroid.x, y: p.y - centroid.y }));
    scene.matter.add.fromVertices(centroid.x, centroid.y, verts, {
      isStatic: true,
      restitution: 0.4,
      friction: 0,
      label: def.label,
    });

    // Neon visual on top.
    const g = scene.add.graphics().setDepth(4);
    g.fillStyle(PALETTE.bgPanel, 1);
    g.fillPoints(def.points, true);
    g.lineStyle(2.5, PALETTE.magenta, 1);
    g.strokePoints(def.points, true);
    g.lineStyle(1.2, PALETTE.white, 0.5);
    g.strokePoints(def.points, true);
  }

  canKick(time: number): boolean {
    return time - this.lastKick >= CFG.cooldownMs;
  }

  kick(ball: BallRef, time: number): void {
    this.lastKick = time;
    ball.setVelocity(this.def.kickDir.x * CFG.kick, this.def.kickDir.y * CFG.kick);
    this.particles.explode(
      8,
      Phaser.Math.Linear(ball.x, this.def.points[0].x, 0.5),
      Phaser.Math.Linear(ball.y, this.def.points[0].y, 0.5)
    );
    this.scene.cameras.main.shake(60, 0.0022);
  }

  private centroid(points: { x: number; y: number }[]): { x: number; y: number } {
    const x = points.reduce((s, p) => s + p.x, 0) / points.length;
    const y = points.reduce((s, p) => s + p.y, 0) / points.length;
    return { x, y };
  }
}
