import Phaser from 'phaser';
import { ROOM_BOUNDS } from '@/game/config';
import type { EnemyKind, EnemySnapshot } from '@/game/types';

interface EnemyConfig {
  hp: number;
  speed: number;
  contactDamage: number;
  texture: string;
  scale: number;
}

const ENEMY_CONFIG: Record<EnemyKind, EnemyConfig> = {
  siltling: { hp: 40, speed: 138, contactDamage: 12, texture: 'enemy-siltling', scale: 1 },
  wickspitter: { hp: 60, speed: 82, contactDamage: 8, texture: 'enemy-wickspitter', scale: 1 },
  knellguard: { hp: 100, speed: 76, contactDamage: 14, texture: 'enemy-knellguard', scale: 1.08 },
  ashmoth: { hp: 34, speed: 120, contactDamage: 10, texture: 'enemy-ashmoth', scale: 1 },
  chimewraith: { hp: 70, speed: 64, contactDamage: 12, texture: 'enemy-chimewraith', scale: 1.04 },
  tollmother: { hp: 920, speed: 62, contactDamage: 20, texture: 'boss-tollmother', scale: 1.28 },
};

export interface EnemyCallbacks {
  shoot(enemy: EnemyEntity, angle: number, speed: number, damage: number): void;
  radial(enemy: EnemyEntity, count: number, speed: number, damage: number, offset?: number): void;
  summon(type: Exclude<EnemyKind, 'tollmother'>, x: number, y: number): void;
}

export class EnemyEntity extends Phaser.Physics.Arcade.Sprite {
  readonly entityId: string;
  readonly kind: EnemyKind;
  readonly maxHp: number;
  readonly contactDamage: number;
  hp: number;
  aiState = 'roam';
  /** What a Tollmother calls in at her second phase. */
  summonKind: Exclude<EnemyKind, 'tollmother'> = 'siltling';
  private staggerUntil = 0;
  private nextActionAt: number;
  private stateEndsAt = 0;
  private strafeDirection: number;
  private phase = 1;
  private summoned = false;
  private readonly baseSpeed: number;
  private readonly callbacks: EnemyCallbacks;

  constructor(
    scene: Phaser.Scene,
    entityId: string,
    kind: EnemyKind,
    x: number,
    y: number,
    callbacks: EnemyCallbacks,
    now: number,
    difficulty = 1,
    hpOverride?: number,
  ) {
    const config = ENEMY_CONFIG[kind];
    super(scene, x, y, config.texture);
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.entityId = entityId;
    this.kind = kind;
    this.baseSpeed = config.speed * Math.min(1.35, difficulty);
    this.maxHp = hpOverride ?? Math.round(config.hp * difficulty);
    this.hp = this.maxHp;
    this.contactDamage = Math.round(config.contactDamage * Math.min(1.35, difficulty));
    this.callbacks = callbacks;
    this.nextActionAt = now + 500;
    this.strafeDirection = entityId.charCodeAt(entityId.length - 1) % 2 === 0 ? 1 : -1;
    this.setScale(config.scale);
    this.setDepth(18);
    this.setCircle(
      kind === 'tollmother' ? 35 : 17,
      kind === 'tollmother' ? 13 : 15,
      kind === 'tollmother' ? 15 : 16,
    );
    this.setBounce(kind === 'siltling' ? 0.35 : 0.1);
  }

  updateAi(time: number, player: Phaser.Physics.Arcade.Sprite): void {
    if (!this.active || this.hp <= 0) return;
    if (time < this.staggerUntil) {
      this.setVelocity(0, 0);
      return;
    }
    const angle = Phaser.Math.Angle.Between(this.x, this.y, player.x, player.y);
    const distance = Phaser.Math.Distance.Between(this.x, this.y, player.x, player.y);

    switch (this.kind) {
      case 'siltling':
        this.updateSiltling(time, angle, distance);
        break;
      case 'wickspitter':
        this.updateWickspitter(time, angle, distance);
        break;
      case 'knellguard':
        this.updateKnellguard(time, angle, distance, player);
        break;
      case 'ashmoth':
        this.updateAshmoth(time, angle);
        break;
      case 'chimewraith':
        this.updateChimewraith(time, angle, player);
        break;
      case 'tollmother':
        this.updateBoss(time, angle, distance);
        break;
    }

    const body = this.body as Phaser.Physics.Arcade.Body;
    if (
      this.aiState === 'charge' &&
      (body.blocked.left || body.blocked.right || body.blocked.up || body.blocked.down)
    ) {
      this.aiState = 'stunned';
      this.stateEndsAt = time + 720;
      this.setVelocity(0, 0);
      this.setTint(0x819192);
    }
  }

  /** Freeze in place until `until` (the toll bell) and push back the next attack. */
  stagger(until: number): void {
    this.staggerUntil = Math.max(this.staggerUntil, until);
    this.nextActionAt = Math.max(this.nextActionAt, until + 250);
    if (this.kind === 'chimewraith' && this.aiState !== 'drift') this.reappear('drift');
    this.setVelocity(0, 0);
  }

  takeDamage(amount: number, projectileAngle?: number): { killed: boolean; applied: number } {
    if (!this.active || this.hp <= 0) return { killed: false, applied: 0 };
    // A fading chimewraith is between places and cannot be hit.
    if (this.kind === 'chimewraith' && this.aiState === 'veiled') return { killed: false, applied: 0 };
    let applied = amount;
    if (this.kind === 'knellguard' && this.aiState !== 'stunned' && projectileAngle !== undefined) {
      const body = this.body as Phaser.Physics.Arcade.Body;
      const facing = body.velocity.lengthSq() > 1 ? body.velocity.angle() : this.rotation;
      const incoming = Phaser.Math.Angle.Wrap(projectileAngle - facing);
      if (Math.abs(incoming) > Math.PI * 0.65) applied *= 0.4;
    }
    applied = Math.min(this.hp, applied);
    this.hp = Math.max(0, this.hp - applied);
    this.setTintFill(0xf2eee2);
    this.scene.time.delayedCall(72, () => {
      if (this.active) this.restoreStateTint();
    });
    return { killed: this.hp <= 0, applied };
  }

  snapshot(): EnemySnapshot {
    return {
      id: this.entityId,
      type: this.kind,
      hp: Number(this.hp.toFixed(3)),
      maxHp: this.maxHp,
      x: Number(this.x.toFixed(3)),
      y: Number(this.y.toFixed(3)),
      state: this.aiState,
    };
  }

  private updateSiltling(time: number, angle: number, distance: number): void {
    if (this.aiState === 'recovery' && time < this.stateEndsAt) {
      this.setVelocity(this.body?.velocity.x ?? 0, this.body?.velocity.y ?? 0);
      return;
    }
    if (this.aiState === 'recovery') this.aiState = 'roam';
    if (distance < 150 && time >= this.nextActionAt) {
      this.aiState = 'lunge';
      this.stateEndsAt = time + 260;
      this.nextActionAt = time + 1_200;
      this.scene.physics.velocityFromRotation(angle, 250, this.body?.velocity);
      return;
    }
    if (this.aiState === 'lunge') {
      if (time < this.stateEndsAt) return;
      this.aiState = 'recovery';
      this.stateEndsAt = time + 420;
      this.setVelocity(0, 0);
      return;
    }
    const wobble = Math.sin(time / 260 + this.entityId.length) * 0.34;
    this.scene.physics.velocityFromRotation(angle + wobble, this.baseSpeed, this.body?.velocity);
  }

  private updateWickspitter(time: number, angle: number, distance: number): void {
    if (this.aiState === 'windup') {
      this.setVelocity(0, 0);
      if (time >= this.stateEndsAt) {
        [-0.24, 0, 0.24].forEach((offset) => this.callbacks.shoot(this, angle + offset, 255, 10));
        this.aiState = 'roam';
        this.nextActionAt = time + 1_350;
        this.clearTint();
      }
      return;
    }
    if (time >= this.nextActionAt) {
      this.aiState = 'windup';
      this.stateEndsAt = time + 440;
      this.setTint(0xd99458);
      return;
    }
    const radial = distance < 190 ? -1 : distance > 340 ? 1 : 0;
    const motionAngle = radial === 0 ? angle + (Math.PI / 2) * this.strafeDirection : angle;
    this.scene.physics.velocityFromRotation(
      motionAngle,
      this.baseSpeed * (radial === 0 ? 0.8 : radial),
      this.body?.velocity,
    );
  }

  private updateKnellguard(
    time: number,
    angle: number,
    distance: number,
    player: Phaser.GameObjects.Components.Transform,
  ): void {
    if (this.aiState === 'telegraph') {
      this.setVelocity(0, 0);
      if (time >= this.stateEndsAt) {
        this.aiState = 'charge';
        this.stateEndsAt = time + 560;
        const chargeAngle = Phaser.Math.Angle.Between(this.x, this.y, player.x, player.y);
        this.setRotation(chargeAngle);
        this.scene.physics.velocityFromRotation(chargeAngle, 350, this.body?.velocity);
        this.clearTint();
      }
      return;
    }
    if (this.aiState === 'charge') {
      if (time < this.stateEndsAt) return;
      this.aiState = 'stunned';
      this.stateEndsAt = time + 720;
      this.setTint(0x819192);
      this.setVelocity(0, 0);
      return;
    }
    if (this.aiState === 'stunned') {
      if (time < this.stateEndsAt) return;
      this.aiState = 'roam';
      this.nextActionAt = time + 1_400;
      this.clearTint();
    }
    const aligned = Math.abs(this.x - player.x) < 72 || Math.abs(this.y - player.y) < 72;
    if (aligned && distance < 430 && time >= this.nextActionAt) {
      this.aiState = 'telegraph';
      this.stateEndsAt = time + 620;
      this.setTint(0xc85d55);
      return;
    }
    this.scene.physics.velocityFromRotation(angle, this.baseSpeed, this.body?.velocity);
  }

  // Ashmoth: flits in short dashes at angles around the player, then hovers.
  private updateAshmoth(time: number, angle: number): void {
    if (this.aiState === 'dash') {
      if (time < this.stateEndsAt) return;
      this.aiState = 'hover';
      this.stateEndsAt = time + 380;
    }
    if (this.aiState === 'hover' && time < this.stateEndsAt) {
      const body = this.body as Phaser.Physics.Arcade.Body;
      this.setVelocity(body.velocity.x * 0.9, body.velocity.y * 0.9);
      return;
    }
    // jitter comes from the clock and the entity id, so replays stay identical
    const jitter = Math.sin(time * 0.0137 + this.entityId.length * 1.7) * 0.9 * this.strafeDirection;
    this.aiState = 'dash';
    this.stateEndsAt = time + 340;
    this.scene.physics.velocityFromRotation(angle + jitter, this.baseSpeed * 2.1, this.body?.velocity);
  }

  // Chimewraith: drifts, fades out (cannot be hit), reappears beside the
  // player and rings a two-shot volley after a short glow.
  private updateChimewraith(
    time: number,
    angle: number,
    player: Phaser.GameObjects.Components.Transform,
  ): void {
    if (this.aiState === 'veiled') {
      this.setVelocity(0, 0);
      if (time < this.stateEndsAt) return;
      const side = angle + Math.PI + (Math.PI / 2) * this.strafeDirection;
      const x = Phaser.Math.Clamp(
        player.x + Math.cos(side) * 190,
        ROOM_BOUNDS.left + 50,
        ROOM_BOUNDS.right - 50,
      );
      const y = Phaser.Math.Clamp(
        player.y + Math.sin(side) * 190,
        ROOM_BOUNDS.top + 50,
        ROOM_BOUNDS.bottom - 50,
      );
      this.setPosition(x, y);
      this.strafeDirection *= -1;
      this.reappear('chiming');
      this.stateEndsAt = time + 420;
      this.setTint(0x9fd6d2);
      return;
    }
    if (this.aiState === 'chiming') {
      this.setVelocity(0, 0);
      if (time < this.stateEndsAt) return;
      const aim = Phaser.Math.Angle.Between(this.x, this.y, player.x, player.y);
      this.callbacks.shoot(this, aim - 0.09, 300, 11);
      this.callbacks.shoot(this, aim + 0.09, 300, 11);
      this.aiState = 'drift';
      this.nextActionAt = time + 2_100;
      this.clearTint();
      return;
    }
    if (time >= this.nextActionAt) {
      this.aiState = 'veiled';
      this.stateEndsAt = time + 480;
      this.setAlpha(0.25);
      this.setVelocity(0, 0);
      return;
    }
    this.scene.physics.velocityFromRotation(
      angle + (Math.PI / 2) * this.strafeDirection,
      this.baseSpeed,
      this.body?.velocity,
    );
  }

  private reappear(state: string): void {
    this.aiState = state;
    this.setAlpha(1);
    this.clearTint();
  }

  private updateBoss(time: number, angle: number, distance: number): void {
    const healthRatio = this.hp / this.maxHp;
    const newPhase = healthRatio > 0.65 ? 1 : healthRatio > 0.3 ? 2 : 3;
    if (newPhase !== this.phase) {
      this.phase = newPhase;
      this.aiState = `phase-${newPhase}`;
      this.nextActionAt = time + 900;
      this.setTint(newPhase === 3 ? 0xc64e4e : 0xd5b378);
      if (newPhase === 2 && !this.summoned) {
        this.summoned = true;
        this.callbacks.summon(this.summonKind, this.x - 80, this.y + 20);
        this.callbacks.summon(this.summonKind, this.x + 80, this.y + 20);
      }
    }
    if (time >= this.nextActionAt) {
      if (this.phase === 1) {
        for (let offset = -2; offset <= 2; offset += 1)
          this.callbacks.shoot(this, angle + offset * 0.22, 250, 12);
        this.nextActionAt = time + 1_650;
      } else if (this.phase === 2) {
        this.callbacks.radial(this, 10, 225, 12, time / 1200);
        this.nextActionAt = time + 1_450;
      } else {
        this.callbacks.radial(this, 12, 285, 13, time / 700);
        this.callbacks.shoot(this, angle, 370, 16);
        this.nextActionAt = time + 1_050;
      }
    }
    const desiredDistance = 245;
    const radial = distance < desiredDistance - 45 ? -1 : distance > desiredDistance + 65 ? 1 : 0;
    const motionAngle = radial === 0 ? angle + Math.PI / 2 : angle;
    this.scene.physics.velocityFromRotation(
      motionAngle,
      this.baseSpeed * (radial === 0 ? 0.72 : radial),
      this.body?.velocity,
    );
  }

  private restoreStateTint(): void {
    this.clearTint();
    if (this.kind === 'wickspitter' && this.aiState === 'windup') this.setTint(0xd99458);
    else if (this.kind === 'knellguard' && this.aiState === 'telegraph') this.setTint(0xc85d55);
    else if (this.kind === 'knellguard' && this.aiState === 'stunned') this.setTint(0x819192);
    else if (this.kind === 'chimewraith' && this.aiState === 'chiming') this.setTint(0x9fd6d2);
    else if (this.kind === 'tollmother' && this.phase >= 2)
      this.setTint(this.phase === 3 ? 0xc64e4e : 0xd5b378);
  }
}
