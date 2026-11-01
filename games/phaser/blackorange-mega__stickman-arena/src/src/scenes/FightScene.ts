import Phaser from "phaser";
import { BODY_WIDTH, GAME_HEIGHT, GAME_WIDTH, GROUND_Y } from "../config";
import { GameContent } from "../ContentLoader";
import { Fighter, type AttackKind } from "../Fighter";
import { InputManager } from "../InputManager";
import { StatusBars } from "../ui/StatusBars";
import { Effects } from "../ui/Effects";
import type { StageDef } from "../types";

/** The core gameplay scene: one stage = one fight against one opponent. */
export class FightScene extends Phaser.Scene {
  private content!: GameContent;
  private stage!: StageDef;

  private player!: Fighter;
  private enemy!: Fighter;
  private playerBars!: StatusBars;
  private enemyBars!: StatusBars;
  private input2!: InputManager;
  private effects!: Effects;

  /** Throttles enemy AI decisions so it doesn't act every single frame. */
  private aiTimer = 0;
  /** Re-decides whether the enemy commits to a block, periodically. */
  private enemyGuardTimer = 0;
  private enemyGuardDecision = false;
  /** Set true once the round ends, to freeze input and avoid double-transitions. */
  private roundOver = false;

  constructor() {
    super("Fight");
  }

  create(): void {
    this.roundOver = false;
    this.aiTimer = 0;
    this.enemyGuardTimer = 0;
    this.enemyGuardDecision = false;

    this.content = this.registry.get("content") as GameContent;
    const stageIndex = this.registry.get("stageIndex") as number;
    this.stage = this.content.campaign.stages[stageIndex];

    this.buildArena();

    // Spawn fighters on opposite sides.
    const playerDef = this.content.getCharacter(this.content.campaign.player);
    const enemyDef = this.content.getCharacter(this.stage.enemy);
    this.player = new Fighter(this, GAME_WIDTH * 0.3, playerDef, 1);
    this.enemy = new Fighter(this, GAME_WIDTH * 0.7, enemyDef, this.stage.difficulty);

    this.physics.add.collider(this.player, this.enemy);

    // HUD
    this.playerBars = new StatusBars(this, this.player, "left");
    this.enemyBars = new StatusBars(this, this.enemy, "right");
    this.input2 = new InputManager(this);
    this.effects = new Effects(this);

    this.showStageBanner(stageIndex);
  }

  private buildArena(): void {
    this.cameras.main.setBackgroundColor(this.stage.background);

    // Distant floor line + ground slab.
    this.add
      .rectangle(GAME_WIDTH / 2, GROUND_Y + 35, GAME_WIDTH, 70, 0x000000, 0.35)
      .setOrigin(0.5, 0.5);
    this.add
      .line(0, 0, 0, GROUND_Y, GAME_WIDTH, GROUND_Y, 0xffffff, 0.18)
      .setOrigin(0, 0)
      .setLineWidth(2);

    // Keep fighters inside the screen horizontally.
    this.physics.world.setBounds(BODY_WIDTH / 2, 0, GAME_WIDTH - BODY_WIDTH, GAME_HEIGHT);

    // Invisible static ground so gravity has something to land on.
    const ground = this.add.rectangle(GAME_WIDTH / 2, GROUND_Y + 6, GAME_WIDTH, 12, 0x000000, 0);
    this.physics.add.existing(ground, true);
    this.children.bringToTop(ground);
    this.groundBody = ground;
  }

  private groundBody!: Phaser.GameObjects.Rectangle;

  private showStageBanner(stageIndex: number): void {
    const title = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 - 30, `STAGE ${stageIndex + 1}\n${this.stage.name}`, {
        fontSize: "44px",
        color: "#ffffff",
        align: "center",
        fontStyle: "bold",
      })
      .setOrigin(0.5)
      .setDepth(2000);
    const sub = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2 + 40, this.stage.intro ?? "", {
        fontSize: "18px",
        color: "#cfd8dc",
        align: "center",
        wordWrap: { width: GAME_WIDTH - 160 },
      })
      .setOrigin(0.5)
      .setDepth(2000);

    // Freeze the fight briefly while the banner shows.
    this.roundOver = true;
    this.time.delayedCall(1500, () => {
      this.tweens.add({
        targets: [title, sub],
        alpha: 0,
        duration: 350,
        onComplete: () => {
          title.destroy();
          sub.destroy();
          this.roundOver = false;
        },
      });
    });
  }

  update(_time: number, delta: number): void {
    // Colliders need a ground reference each step (added once, kept here cheap).
    this.physics.collide(this.player, this.groundBody);
    this.physics.collide(this.enemy, this.groundBody);

    // Always keep fighters facing each other.
    this.player.faceTowards(this.enemy.x);
    this.enemy.faceTowards(this.player.x);

    this.playerBars.update();
    this.enemyBars.update();

    if (this.roundOver) {
      this.player.moveHorizontally(0);
      this.enemy.moveHorizontally(0);
      return;
    }

    this.handlePlayerInput();
    this.updateEnemyAI(delta);
    this.resolveHits();
    this.checkRoundEnd();
  }

  private handlePlayerInput(): void {
    if (!this.player.isAlive) return;

    this.player.setGuard(this.input2.guard);

    const dir = (this.input2.left ? -1 : 0) + (this.input2.right ? 1 : 0);
    this.player.moveHorizontally(dir as -1 | 0 | 1);

    if (this.input2.consumeJump()) this.player.jump();
    if (this.input2.consumeLight()) this.startAttack(this.player, "light");
    if (this.input2.consumeHeavy()) this.startAttack(this.player, "heavy");
    if (this.input2.consumeSpecial()) this.startAttack(this.player, "special");
  }

  /** Kick off an attack and, if it actually starts, draw its swing arc. */
  private startAttack(fighter: Fighter, kind: AttackKind): boolean {
    if (fighter.tryAttack(kind)) {
      this.effects.swing(fighter.x, fighter.y, fighter.facing, kind);
      return true;
    }
    return false;
  }

  private updateEnemyAI(delta: number): void {
    if (!this.enemy.isAlive || !this.player.isAlive) {
      this.enemy.setGuard(false);
      this.enemy.moveHorizontally(0);
      return;
    }

    const dx = this.player.x - this.enemy.x;
    const dist = Math.abs(dx);
    const reach = this.enemy.def.attacks.heavy.range;
    // Harder stages react faster.
    const reactionMs = Math.max(180, 520 - this.stage.difficulty * 120);

    // Reactive blocking: when the player swings at close range, tougher enemies
    // commit to a block more often. Re-decide periodically so it isn't perfect.
    this.enemyGuardTimer -= delta;
    const underThreat = this.player.isAttacking && dist < reach * 1.15;
    if (underThreat) {
      if (this.enemyGuardTimer <= 0) {
        this.enemyGuardTimer = 450;
        this.enemyGuardDecision =
          this.enemy.stamina > 20 && Math.random() < 0.2 + this.stage.difficulty * 0.18;
      }
    } else {
      this.enemyGuardDecision = false;
    }
    this.enemy.setGuard(this.enemyGuardDecision);
    if (this.enemy.guarding) {
      this.enemy.moveHorizontally(0);
      return; // can't move or attack while blocking
    }

    this.aiTimer -= delta;

    if (dist > reach * 0.9) {
      // Close the gap.
      this.enemy.moveHorizontally(dx > 0 ? 1 : -1);
    } else {
      this.enemy.moveHorizontally(0);
      if (this.aiTimer <= 0 && !this.enemy.isAttacking) {
        this.aiTimer = reactionMs;
        this.chooseEnemyAttack();
      }
    }

    // Occasional hop to look less robotic.
    if (Phaser.Math.Between(0, 1000) < 4) this.enemy.jump();
  }

  private chooseEnemyAttack(): void {
    const e = this.enemy;
    const roll = Math.random();
    // Prefer the special when it's affordable and a bit of luck lands.
    if (e.stamina >= e.def.special.staminaCost && roll < 0.25) {
      if (this.startAttack(e, "special")) return;
    }
    if (e.stamina >= e.def.attacks.heavy.staminaCost && roll < 0.6) {
      if (this.startAttack(e, "heavy")) return;
    }
    this.startAttack(e, "light");
  }

  /** Check both fighters' active attack frames and apply damage on contact. */
  private resolveHits(): void {
    this.tryHit(this.player, this.enemy);
    this.tryHit(this.enemy, this.player);
  }

  private tryHit(attacker: Fighter, defender: Fighter): void {
    const attack = attacker.takeActiveHit();
    if (!attack || !defender.isAlive) return;

    const dx = defender.x - attacker.x;
    const inFront = Math.sign(dx) === attacker.facing || dx === 0;
    const inRange = Math.abs(dx) <= attack.range + BODY_WIDTH * 0.5;
    const sameHeight = Math.abs(defender.y - attacker.y) < 130;

    if (inFront && inRange && sameHeight) {
      const result = defender.receiveDamage(attack.damage, attacker.facing);
      const contactX = (attacker.x + defender.x) / 2;
      this.effects.spark(contactX, defender.y - 96, result.guarded);
      this.effects.damageNumber(defender.x, defender.y - 150, result.damage, result.guarded);
      const intensity = result.guarded ? 0.003 : attack.damage > 20 ? 0.012 : 0.006;
      this.cameras.main.shake(90, intensity);
    }
  }

  private checkRoundEnd(): void {
    if (this.roundOver) return;

    if (!this.player.isAlive) {
      this.endRound(false);
    } else if (!this.enemy.isAlive) {
      this.endRound(true);
    }
  }

  private endRound(playerWon: boolean): void {
    this.roundOver = true;
    const stageIndex = this.registry.get("stageIndex") as number;
    const isLastStage = stageIndex >= this.content.campaign.stages.length - 1;

    if (!playerWon) {
      this.time.delayedCall(1200, () =>
        this.scene.start("Result", { win: false, stage: stageIndex + 1 })
      );
      return;
    }

    if (isLastStage) {
      this.time.delayedCall(1200, () => this.scene.start("Result", { win: true }));
      return;
    }

    // Advance to the next stage.
    this.flashBanner("STAGE CLEARED!");
    this.time.delayedCall(1500, () => {
      this.registry.set("stageIndex", stageIndex + 1);
      this.scene.restart();
    });
  }

  private flashBanner(text: string): void {
    this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT / 2, text, {
        fontSize: "52px",
        color: "#ffd54f",
        fontStyle: "bold",
      })
      .setOrigin(0.5)
      .setDepth(2000);
  }
}
