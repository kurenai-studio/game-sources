import Phaser from 'phaser';
import {
  DOOR_SPAN,
  GAME_HEIGHT,
  GAME_WIDTH,
  INVULNERABILITY_MS,
  MAX_ENEMY_PROJECTILES,
  MAX_PLAYER_PROJECTILES,
  ROOM_BOUNDS,
  WALL_THICKNESS,
} from '@/game/config';
import { LAST_FLOOR, floorSeed, floorTheme, type FloorTheme } from '@/game/data/floors';
import { ITEM_BY_ID, ITEM_DEFINITIONS, addItem, deriveStats } from '@/game/data/items';
import { EnemyEntity, type EnemyCallbacks } from '@/game/entities/Enemy';
import { PlayerEntity } from '@/game/entities/Player';
import { ProjectileEntity } from '@/game/entities/Projectile';
import { gameEvents } from '@/game/events';
import { audio } from '@/game/systems/audio';
import { BELL, bellStatus, tollBell } from '@/game/systems/bell';
import { generateDungeon } from '@/game/systems/dungeon';
import { SeededRng } from '@/game/systems/rng';
import {
  DIRECTION_VECTOR,
  OPPOSITE_DIRECTION,
  type Direction,
  type DungeonLayout,
  type EnemyKind,
  type GameDebugSnapshot,
  type GamePhase,
  type GameResult,
  type Inventory,
  type PlayerStats,
  type RoomNode,
  type RunFixture,
} from '@/game/types';

interface RunStats {
  kills: number;
  pickups: number;
  roomsCleared: number;
  damageDealt: number;
  damageTaken: number;
}

interface RunCarry {
  inventory: Inventory;
  hp: number;
  runClockMs: number;
  runStats: RunStats;
  tolls: number;
}

interface GameSceneData {
  seed?: string;
  fixture?: RunFixture;
  floor?: number;
  /** State handed down the well from the previous depth. */
  carry?: RunCarry;
}

const CENTER = { x: GAME_WIDTH / 2, y: GAME_HEIGHT / 2 } as const;
const ROOM_CENTER = {
  x: (ROOM_BOUNDS.left + ROOM_BOUNDS.right) / 2,
  y: (ROOM_BOUNDS.top + ROOM_BOUNDS.bottom) / 2,
};

export class GameScene extends Phaser.Scene {
  phase: GamePhase = 'boot';
  seed = 'MOURNWELL';
  dungeon!: DungeonLayout;
  player!: PlayerEntity;
  hp = 100;
  inventory: Inventory = {};
  stats: PlayerStats = deriveStats(this.inventory);
  currentRoom!: RoomNode;
  doorsOpen = false;
  tick = 0;
  floor = 1;

  private fixture: GameSceneData['fixture'] = 'normal';
  private roomRng!: SeededRng;
  private lootRng!: SeededRng;
  private fxRng!: SeededRng;
  private runClockMs = 0;
  private lastSnapshotAt = 0;
  private transitioning = false;
  private runEnding = false;
  private roomRewardDropped = false;
  private roomsWithoutReward = 0;
  private enemySequence = 0;
  private theme: FloorTheme = floorTheme(1);
  private bellReadyAt = 0;
  private tolls = 0;
  private walls!: Phaser.Physics.Arcade.StaticGroup;
  private closedDoors!: Phaser.Physics.Arcade.StaticGroup;
  private enemies!: Phaser.Physics.Arcade.Group;
  private playerProjectiles!: Phaser.Physics.Arcade.Group;
  private enemyProjectiles!: Phaser.Physics.Arcade.Group;
  private pickups!: Phaser.Physics.Arcade.Group;
  private roomDecorations!: Phaser.GameObjects.Group;
  private roomGraphics!: Phaser.GameObjects.Graphics;
  private doorGraphics!: Phaser.GameObjects.Graphics;
  private vignette!: Phaser.GameObjects.Graphics;
  private runStats: RunStats = {
    kills: 0,
    pickups: 0,
    roomsCleared: 0,
    damageDealt: 0,
    damageTaken: 0,
  };

  constructor() {
    super('GameScene');
  }

  init(data: GameSceneData): void {
    this.seed = sanitizeSeed(data.seed);
    this.fixture = data.fixture ?? 'normal';
    // the 'boss' fixture is the final Tollmother, so beating it ends the run
    this.floor = Phaser.Math.Clamp(data.floor ?? (this.fixture === 'boss' ? LAST_FLOOR : 1), 1, LAST_FLOOR);
    this.theme = floorTheme(this.floor);
    this.phase = 'running';
    const carry = data.carry;
    this.inventory = carry ? { ...carry.inventory } : {};
    this.stats = deriveStats(this.inventory);
    this.hp = carry ? Math.min(carry.hp, this.stats.maxHp) : this.stats.maxHp;
    this.tick = 0;
    this.transitioning = false;
    this.runEnding = false;
    this.roomRewardDropped = false;
    this.roomsWithoutReward = 0;
    this.enemySequence = 0;
    this.runClockMs = carry?.runClockMs ?? (this.fixture === 'boss' ? 486_000 : 0);
    this.bellReadyAt = 0;
    this.tolls = carry?.tolls ?? 0;
    this.runStats = carry
      ? { ...carry.runStats }
      : { kills: 0, pickups: 0, roomsCleared: 0, damageDealt: 0, damageTaken: 0 };
    const layoutSeed = floorSeed(this.seed, this.floor);
    this.dungeon = generateDungeon(layoutSeed);
    this.lootRng = new SeededRng(`${layoutSeed}::loot`);
    this.fxRng = new SeededRng(`${layoutSeed}::fx`);
  }

  create(): void {
    this.cameras.main.setBackgroundColor('#09080b');
    this.cameras.main.setRoundPixels(true);
    this.cameras.main.setBounds(0, 0, GAME_WIDTH, GAME_HEIGHT);
    this.physics.world.setBounds(0, 0, GAME_WIDTH, GAME_HEIGHT);
    this.roomGraphics = this.add.graphics().setDepth(0);
    this.doorGraphics = this.add.graphics().setDepth(8);
    this.vignette = this.add.graphics().setDepth(50).setScrollFactor(0);
    this.vignette.fillStyle(0x050406, 0.33).fillRect(0, 0, GAME_WIDTH, 30);
    this.vignette.fillStyle(0x050406, 0.33).fillRect(0, GAME_HEIGHT - 30, GAME_WIDTH, 30);

    this.walls = this.physics.add.staticGroup();
    this.closedDoors = this.physics.add.staticGroup();
    this.enemies = this.physics.add.group();
    this.playerProjectiles = this.physics.add.group({ maxSize: MAX_PLAYER_PROJECTILES });
    this.enemyProjectiles = this.physics.add.group({ maxSize: MAX_ENEMY_PROJECTILES });
    this.pickups = this.physics.add.group();
    this.roomDecorations = this.add.group();

    this.player = new PlayerEntity(
      this,
      CENTER.x,
      CENTER.y,
      () => this.stats,
      (direction) => this.shootPlayer(direction),
    );
    this.syncViewport();

    this.installCollisions();
    this.currentRoom = this.getRoom(this.dungeon.startId);
    this.loadRoom(this.currentRoom, null, true);
    this.applyFixture();
    this.phase = 'running';
    gameEvents.emit('phase', this.phase);
    gameEvents.emit('toast', {
      title: `Depth ${this.floor === 1 ? 'I' : 'II'} — ${this.theme.name}`,
      subtitle: this.seed,
      duration: 1_500,
    });

    this.publishSnapshot(true);
  }

  override update(_time: number, delta: number): void {
    if (this.phase !== 'running' || this.runEnding || this.transitioning) return;
    const activeDelta = Phaser.Math.Clamp(delta, 0, 100);
    this.runClockMs += activeDelta;
    this.tick += 1;
    this.player.updateControl(this.runClockMs);
    if (this.player.controls.tollPressed()) this.tollBell();
    this.updateEnemies(this.runClockMs);
    this.updateProjectiles(activeDelta);
    this.checkDoorTraversal();
    this.publishSnapshot(this.runClockMs - this.lastSnapshotAt >= 100);
  }

  syncViewport(): void {
    if (!this.player) return;
    if (this.scale.gameSize.width < GAME_WIDTH) {
      this.cameras.main.startFollow(this.player, true, 0.16, 0.16);
      this.cameras.main.setDeadzone(170, 120);
      this.cameras.main.centerOn(this.player.x, this.player.y);
    } else {
      this.cameras.main.stopFollow();
      this.cameras.main.setDeadzone(0, 0);
      this.cameras.main.centerOn(GAME_WIDTH / 2, GAME_HEIGHT / 2);
    }
  }

  pauseGame(): void {
    if (this.phase !== 'running') return;
    this.phase = 'paused';
    this.player.controls.reset();
    gameEvents.emit('phase', this.phase);
    this.publishSnapshot(true);
    // Through the scene manager, not this.scene: the ScenePlugin versions are
    // queued until the next frame, and a queued resume that lands after the
    // scene was stopped (unpause, then restart before the next frame) brings
    // the shut-down scene back to life and kills the game loop.
    this.game.scene.pause(this.scene.key);
  }

  resumeGame(): void {
    if (this.phase !== 'paused') return;
    this.phase = 'running';
    this.game.scene.resume(this.scene.key);
    gameEvents.emit('phase', this.phase);
    this.publishSnapshot(true);
  }

  /**
   * Ring the toll bell: pay resolve, and every enemy in the chamber takes a
   * heavy hit, flinches, and its shots in flight are swept away.
   */
  tollBell(): void {
    if (this.phase !== 'running' || this.runEnding || this.transitioning) return;
    const result = tollBell(this.hp, this.runClockMs, this.bellReadyAt);
    if (!result.rung) {
      audio.bellDenied();
      gameEvents.emit('toast', {
        title: result.blockedBy === 'cooldown' ? 'THE BELL STILL HUMS' : 'TOO LITTLE RESOLVE',
        subtitle: result.blockedBy === 'cooldown' ? 'WAIT FOR THE SILENCE' : `A TOLL COSTS ${BELL.cost}`,
        duration: 700,
      });
      return;
    }
    const paid = this.hp - result.hp;
    this.hp = result.hp;
    this.runStats.damageTaken += paid;
    this.bellReadyAt = result.readyAt;
    this.tolls += 1;
    for (const enemy of this.activeEnemies()) {
      enemy.stagger(result.staggerUntil);
      const hit = enemy.takeDamage(result.damage);
      this.runStats.damageDealt += hit.applied;
      if (hit.killed) this.killEnemy(enemy);
    }
    // after the kills, so embers from a bursting ashmoth are swept away too
    this.enemyProjectiles.clear(true, true);
    this.spawnTollRing(this.player.x, this.player.y);
    audio.bell();
    this.cameras.main.shake(180, 0.006);
    gameEvents.emit('toast', { title: 'THE BELL TOLLS', subtitle: `RESOLVE −${paid}`, duration: 800 });
    this.publishSnapshot(true);
  }

  abandonRun(): void {
    if (this.phase === 'dead' || this.phase === 'victory') return;
    this.finishRun(false);
  }

  getDebugSnapshot(): GameDebugSnapshot {
    const enemies = this.activeEnemies()
      .map((enemy) => enemy.snapshot())
      .sort((left, right) => left.id.localeCompare(right.id));
    const playerProjectiles = this.activeProjectiles(this.playerProjectiles).length;
    const enemyProjectiles = this.activeProjectiles(this.enemyProjectiles).length;
    const doors = (Object.entries(this.currentRoom.neighbors) as Array<[Direction, string]>)
      .map(([direction, targetRoomId]) => ({ direction, targetRoomId, locked: !this.doorsOpen }))
      .sort((left, right) => left.direction.localeCompare(right.direction));
    const elapsedMs = this.elapsedMs();
    const bell = bellStatus(this.hp, this.runClockMs, this.bellReadyAt);
    return {
      schemaVersion: 1,
      phase: this.phase,
      seed: this.seed,
      tick: this.tick,
      floor: this.floor,
      summary: {
        hp: this.hp,
        maxHp: this.stats.maxHp,
        enemyCount: enemies.length,
        bulletCount: playerProjectiles,
        currentRoom: this.currentRoom.id,
        itemIds: Object.keys(this.inventory).sort(),
        attributes: {
          attack: this.stats.damage,
          fireRate: Number((1000 / this.stats.fireInterval).toFixed(2)),
          projectileSpeed: this.stats.shotSpeed,
          moveSpeed: this.stats.moveSpeed,
          range: this.stats.range,
        },
      },
      player: {
        x: Number(this.player.x.toFixed(3)),
        y: Number(this.player.y.toFixed(3)),
        facing: this.player.facing,
        invulnerable: this.player.isInvulnerable(this.runClockMs),
        active: this.player.active,
        visible: this.player.visible,
        renderable: this.player.willRender(this.cameras.main),
      },
      room: {
        id: this.currentRoom.id,
        index: this.currentRoom.index,
        kind: this.currentRoom.kind,
        cleared: this.currentRoom.cleared,
        doorsOpen: this.doorsOpen,
        doors,
      },
      counts: {
        enemies: enemies.length,
        playerProjectiles,
        enemyProjectiles,
        pickups: this.pickups.countActive(true),
      },
      bell: {
        ready: bell.ready,
        readyInMs: bell.readyInMs,
        cost: BELL.cost,
        tolls: this.tolls,
      },
      enemies,
      inventory: Object.entries(this.inventory)
        .map(([id, stacks]) => ({ id, stacks, effects: ITEM_BY_ID.get(id)?.effectSummary ?? {} }))
        .sort((left, right) => left.id.localeCompare(right.id)),
      stats: { ...this.stats },
      dungeon: structuredClone(this.dungeon),
      run: { ...this.runStats, elapsedMs },
      metrics: {
        fps: Number(this.game.loop.actualFps.toFixed(1)),
        entityCount:
          enemies.length + playerProjectiles + enemyProjectiles + this.pickups.countActive(true) + 1,
      },
    };
  }

  debugSpawnEnemy(type: EnemyKind, options: { hp?: number; x?: number; y?: number } = {}): void {
    this.currentRoom.cleared = false;
    this.doorsOpen = false;
    this.spawnEnemy(type, options.x ?? this.player.x + 145, options.y ?? this.player.y, options.hp);
    this.updateDoors();
    this.publishSnapshot(true);
  }

  debugSpawnItem(itemId: string, options: { x?: number; y?: number } = {}): void {
    this.spawnItem(itemId, options.x ?? this.player.x + 90, options.y ?? this.player.y, true);
    this.publishSnapshot(true);
  }

  debugClearRoom(): void {
    for (const enemy of this.activeEnemies()) enemy.destroy();
    this.handleRoomCleared();
  }

  debugGrantItem(itemId: string): void {
    this.collectItem(itemId);
    this.publishSnapshot(true);
  }

  debugDamagePlayer(amount: number): void {
    this.player.invulnerableUntil = 0;
    this.damagePlayer(amount, this.player.x - 1, this.player.y);
    this.publishSnapshot(true);
  }

  debugEnterRoom(roomId: string): void {
    const room = this.getRoom(roomId);
    this.loadRoom(room, null, true);
    this.publishSnapshot(true);
  }

  private installCollisions(): void {
    this.physics.add.collider(this.player, this.walls);
    this.physics.add.collider(this.player, this.closedDoors);
    this.physics.add.collider(this.enemies, this.walls);
    this.physics.add.collider(this.enemies, this.closedDoors);
    this.physics.add.collider(this.enemies, this.enemies);
    this.physics.add.collider(this.playerProjectiles, this.walls, (first, second) => {
      collisionProjectile(first, second)?.destroy();
    });
    this.physics.add.collider(this.playerProjectiles, this.closedDoors, (first, second) => {
      collisionProjectile(first, second)?.destroy();
    });
    this.physics.add.collider(this.enemyProjectiles, this.walls, (first, second) => {
      collisionProjectile(first, second)?.destroy();
    });
    this.physics.add.collider(this.enemyProjectiles, this.closedDoors, (first, second) => {
      collisionProjectile(first, second)?.destroy();
    });
    this.physics.add.overlap(this.playerProjectiles, this.enemies, (first, second) => {
      const projectile = collisionProjectile(first, second);
      const enemy = collisionEnemy(first, second);
      if (projectile && enemy) this.hitEnemy(projectile, enemy);
    });
    this.physics.add.overlap(this.enemyProjectiles, this.player, (first, second) => {
      const shot = collisionProjectile(first, second);
      if (!shot || shot.owner !== 'enemy') return;
      this.damagePlayer(shot.damage, shot.x, shot.y);
      shot.destroy();
    });
    this.physics.add.overlap(this.player, this.enemies, (first, second) => {
      const enemy = collisionEnemy(first, second);
      if (enemy) this.damagePlayer(enemy.contactDamage, enemy.x, enemy.y);
    });
    this.physics.add.overlap(this.player, this.pickups, (first, second) => {
      const pickup = first === this.player ? second : first;
      if (pickup instanceof Phaser.Physics.Arcade.Image) this.collectPickup(pickup);
    });
  }

  private loadRoom(room: RoomNode, from: Direction | null, immediate = false): void {
    this.transitioning = true;
    this.physics.pause();
    this.clearRoomEntities();
    this.currentRoom = room;
    this.currentRoom.visited = true;
    this.roomRewardDropped = false;
    this.roomRng = new SeededRng(`${this.seed}::room::${room.id}`);
    this.drawRoom();
    this.placePlayer(from);

    if (room.kind === 'start') {
      room.cleared = true;
      this.doorsOpen = true;
    } else if (room.kind === 'treasure') {
      room.cleared = true;
      this.doorsOpen = true;
      if (!room.rewardClaimed) {
        const item = this.roomRng.pick(ITEM_DEFINITIONS);
        this.spawnItem(item.id, ROOM_CENTER.x, ROOM_CENTER.y, false);
      }
    } else if (room.cleared) {
      this.doorsOpen = true;
    } else {
      this.doorsOpen = false;
      if (room.kind === 'boss') {
        this.spawnEnemy('tollmother', ROOM_CENTER.x, ROOM_CENTER.y - 60);
        audio.boss();
        gameEvents.emit('toast', {
          title: 'THE TOLLMOTHER',
          subtitle: this.floor === LAST_FLOOR ? 'THE LAST BELL WAKES' : 'THE FIRST BELL WAKES',
          duration: 1_300,
        });
      } else {
        this.spawnCombatWave(room);
      }
    }
    this.updateDoors();
    const complete = (): void => {
      this.transitioning = false;
      if (!this.runEnding && this.phase === 'running') this.physics.resume();
      this.cameras.main.fadeIn(130, 8, 7, 10);
      this.publishSnapshot(true);
    };
    if (immediate) complete();
    else this.time.delayedCall(110, complete);
  }

  private clearRoomEntities(): void {
    this.enemies?.clear(true, true);
    this.playerProjectiles?.clear(true, true);
    this.enemyProjectiles?.clear(true, true);
    this.pickups?.clear(true, true);
    this.roomDecorations?.clear(true, true);
    this.walls?.clear(true, true);
    this.closedDoors?.clear(true, true);
  }

  private drawRoom(): void {
    const graphics = this.roomGraphics;
    graphics.clear();
    graphics.fillStyle(0x0b090d).fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);
    graphics
      .fillStyle(this.currentRoom.kind === 'boss' ? this.theme.bossFloorColor : this.theme.floorColor)
      .fillRoundedRect(
        ROOM_BOUNDS.left,
        ROOM_BOUNDS.top,
        ROOM_BOUNDS.right - ROOM_BOUNDS.left,
        ROOM_BOUNDS.bottom - ROOM_BOUNDS.top,
        18,
      );
    graphics
      .lineStyle(5, this.currentRoom.kind === 'boss' ? this.theme.bossWallColor : this.theme.wallColor, 0.95)
      .strokeRoundedRect(
        ROOM_BOUNDS.left,
        ROOM_BOUNDS.top,
        ROOM_BOUNDS.right - ROOM_BOUNDS.left,
        ROOM_BOUNDS.bottom - ROOM_BOUNDS.top,
        18,
      );
    graphics.lineStyle(1, 0x7f716b, 0.14);
    for (let x = ROOM_BOUNDS.left + 36; x < ROOM_BOUNDS.right; x += 57) {
      graphics.lineBetween(x, ROOM_BOUNDS.top + 12, x - 18, ROOM_BOUNDS.bottom - 10);
    }

    const decorRng = new SeededRng(`${this.seed}::decor::${this.currentRoom.id}`);
    for (let stain = 0; stain < 18; stain += 1) {
      const x = decorRng.int(ROOM_BOUNDS.left + 34, ROOM_BOUNDS.right - 34);
      const y = decorRng.int(ROOM_BOUNDS.top + 34, ROOM_BOUNDS.bottom - 34);
      const radius = decorRng.int(2, 10);
      graphics
        .fillStyle(stain % 5 === 0 ? 0x67363b : 0x09080b, decorRng.float(0.07, 0.2))
        .fillEllipse(x, y, radius * 2, radius);
    }
    for (let crack = 0; crack < 8; crack += 1) {
      const x = decorRng.int(ROOM_BOUNDS.left + 50, ROOM_BOUNDS.right - 50);
      const y = decorRng.int(ROOM_BOUNDS.top + 50, ROOM_BOUNDS.bottom - 50);
      graphics
        .lineStyle(1, 0x97877a, 0.17)
        .beginPath()
        .moveTo(x, y)
        .lineTo(x + decorRng.int(-18, 18), y + decorRng.int(8, 24))
        .lineTo(x + decorRng.int(-24, 24), y + decorRng.int(22, 38))
        .strokePath();
    }
    if (this.currentRoom.kind === 'treasure') {
      graphics.lineStyle(2, 0xd5a15f, 0.35).strokeCircle(ROOM_CENTER.x, ROOM_CENTER.y, 54);
      graphics.lineStyle(1, 0xd5a15f, 0.22).strokeCircle(ROOM_CENTER.x, ROOM_CENTER.y, 70);
    }
    if (this.currentRoom.kind === 'boss') {
      graphics.lineStyle(2, 0xa44449, 0.25).strokeCircle(ROOM_CENTER.x, ROOM_CENTER.y, 125);
      graphics.lineStyle(1, 0xd59a68, 0.18).strokeCircle(ROOM_CENTER.x, ROOM_CENTER.y, 155);
    }
    this.buildWalls();
  }

  private buildWalls(): void {
    const horizontalLength = ROOM_BOUNDS.right - ROOM_BOUNDS.left;
    const verticalLength = ROOM_BOUNDS.bottom - ROOM_BOUNDS.top;
    const halfHorizontal = (horizontalLength - DOOR_SPAN) / 2;
    const halfVertical = (verticalLength - DOOR_SPAN) / 2;
    const centerX = ROOM_CENTER.x;
    const centerY = ROOM_CENTER.y;

    const addHorizontal = (y: number, hasDoor: boolean): void => {
      if (!hasDoor) {
        this.addWall(centerX, y, horizontalLength, WALL_THICKNESS);
        return;
      }
      this.addWall(ROOM_BOUNDS.left + halfHorizontal / 2, y, halfHorizontal, WALL_THICKNESS);
      this.addWall(ROOM_BOUNDS.right - halfHorizontal / 2, y, halfHorizontal, WALL_THICKNESS);
    };
    const addVertical = (x: number, hasDoor: boolean): void => {
      if (!hasDoor) {
        this.addWall(x, centerY, WALL_THICKNESS, verticalLength);
        return;
      }
      this.addWall(x, ROOM_BOUNDS.top + halfVertical / 2, WALL_THICKNESS, halfVertical);
      this.addWall(x, ROOM_BOUNDS.bottom - halfVertical / 2, WALL_THICKNESS, halfVertical);
    };

    addHorizontal(ROOM_BOUNDS.top, Boolean(this.currentRoom.neighbors.north));
    addHorizontal(ROOM_BOUNDS.bottom, Boolean(this.currentRoom.neighbors.south));
    addVertical(ROOM_BOUNDS.left, Boolean(this.currentRoom.neighbors.west));
    addVertical(ROOM_BOUNDS.right, Boolean(this.currentRoom.neighbors.east));
  }

  private addWall(x: number, y: number, width: number, height: number): void {
    const wall = this.walls.create(x, y, 'wall-block') as Phaser.Physics.Arcade.Image;
    wall.setVisible(false).setDisplaySize(width, height).refreshBody();
  }

  private updateDoors(): void {
    this.closedDoors.clear(true, true);
    this.doorGraphics.clear();
    const entries = Object.entries(this.currentRoom.neighbors) as Array<[Direction, string]>;
    for (const [direction] of entries) {
      const { x, y, width, height } = doorGeometry(direction);
      if (!this.doorsOpen) {
        const door = this.closedDoors.create(x, y, 'wall-block') as Phaser.Physics.Arcade.Image;
        door.setVisible(false).setDisplaySize(width, height).refreshBody();
        this.doorGraphics
          .fillStyle(0x32242a)
          .lineStyle(3, 0x0a080b)
          .fillRoundedRect(x - width / 2, y - height / 2, width, height, 5)
          .strokeRoundedRect(x - width / 2, y - height / 2, width, height, 5);
        this.doorGraphics.lineStyle(3, 0x865d4e, 0.8);
        if (direction === 'north' || direction === 'south') {
          for (let offset = -36; offset <= 36; offset += 24)
            this.doorGraphics.lineBetween(x + offset, y - 8, x + offset, y + 8);
        } else {
          for (let offset = -36; offset <= 36; offset += 24)
            this.doorGraphics.lineBetween(x - 8, y + offset, x + 8, y + offset);
        }
      } else {
        this.doorGraphics
          .lineStyle(3, 0xd09457, 0.42)
          .strokeRect(x - width / 2, y - height / 2, width, height);
        this.doorGraphics.fillStyle(0xd89b59, 0.2).fillCircle(x, y, 6);
      }
    }
  }

  private placePlayer(from: Direction | null): void {
    const inset = 42;
    if (!from) this.player.setPosition(ROOM_CENTER.x, ROOM_CENTER.y + 70);
    if (from === 'north') this.player.setPosition(ROOM_CENTER.x, ROOM_BOUNDS.top + inset);
    if (from === 'south') this.player.setPosition(ROOM_CENTER.x, ROOM_BOUNDS.bottom - inset);
    if (from === 'west') this.player.setPosition(ROOM_BOUNDS.left + inset, ROOM_CENTER.y);
    if (from === 'east') this.player.setPosition(ROOM_BOUNDS.right - inset, ROOM_CENTER.y);
    this.player.setVelocity(0, 0);
  }

  private spawnCombatWave(room: RoomNode): void {
    const count = Math.min(6, 2 + Math.floor(room.distance / 2) + this.roomRng.int(0, 2));
    const kinds = this.theme.roster;
    const primary = kinds[room.index % this.theme.primaries] ?? 'siltling';
    for (let index = 0; index < count; index += 1) {
      const kind =
        index === 0 ? primary : this.roomRng.pick(kinds.slice(0, Math.min(kinds.length, 1 + room.distance)));
      let x = this.roomRng.int(ROOM_BOUNDS.left + 75, ROOM_BOUNDS.right - 75);
      let y = this.roomRng.int(ROOM_BOUNDS.top + 70, ROOM_BOUNDS.bottom - 70);
      if (Phaser.Math.Distance.Between(x, y, this.player.x, this.player.y) < 165) {
        x = x < ROOM_CENTER.x ? ROOM_BOUNDS.left + 80 : ROOM_BOUNDS.right - 80;
        y = y < ROOM_CENTER.y ? ROOM_BOUNDS.top + 75 : ROOM_BOUNDS.bottom - 75;
      }
      this.spawnEnemy(kind, x, y);
    }
  }

  private spawnEnemy(type: EnemyKind, x: number, y: number, hpOverride?: number): EnemyEntity {
    this.enemySequence += 1;
    const callbacks: EnemyCallbacks = {
      shoot: (enemy, angle, speed, damage) => this.shootEnemy(enemy, angle, speed, damage),
      radial: (enemy, count, speed, damage, offset) => this.shootRadial(enemy, count, speed, damage, offset),
      summon: (kind, spawnX, spawnY) => {
        if (this.activeEnemies().length < 7) this.spawnEnemy(kind, spawnX, spawnY);
      },
    };
    const difficulty = 1 + this.currentRoom.distance * 0.055 + this.theme.difficultyBonus;
    const enemy = new EnemyEntity(
      this,
      `enemy-${this.currentRoom.id}-${this.enemySequence}`,
      type,
      Phaser.Math.Clamp(x, ROOM_BOUNDS.left + 40, ROOM_BOUNDS.right - 40),
      Phaser.Math.Clamp(y, ROOM_BOUNDS.top + 40, ROOM_BOUNDS.bottom - 40),
      callbacks,
      this.runClockMs,
      difficulty,
      hpOverride,
    );
    enemy.summonKind = this.theme.bossSummon;
    this.enemies.add(enemy);
    return enemy;
  }

  private shootPlayer(direction: Direction): void {
    const availableSlots = MAX_PLAYER_PROJECTILES - this.playerProjectiles.countActive(true);
    if (this.phase !== 'running' || availableSlots <= 0) return;
    const vector = DIRECTION_VECTOR[direction];
    const baseAngle = Math.atan2(vector.y, vector.x);
    const count = Math.min(this.stats.projectiles, availableSlots);
    const offsets =
      count === 1
        ? [0]
        : Array.from({ length: count }, (_, index) =>
            Phaser.Math.Linear(-this.stats.spread, this.stats.spread, index / (count - 1)),
          );
    for (const offset of offsets) {
      const angle = baseAngle + offset;
      const projectile = new ProjectileEntity(
        this,
        this.player.x + Math.cos(angle) * 25,
        this.player.y + Math.sin(angle) * 25,
        'player-projectile',
        {
          owner: 'player',
          damage: this.stats.damage,
          velocityX: Math.cos(angle) * this.stats.shotSpeed,
          velocityY: Math.sin(angle) * this.stats.shotSpeed,
          maxDistance: this.stats.range,
          pierce: this.stats.pierce,
          homing: this.stats.homing,
          scale: this.stats.projectileScale,
        },
      );
      this.playerProjectiles.add(projectile);
      // Arcade Group.add applies group defaults; restore the authored launch velocity afterward.
      projectile.setVelocity(Math.cos(angle) * this.stats.shotSpeed, Math.sin(angle) * this.stats.shotSpeed);
    }
    this.player.nudge(OPPOSITE_DIRECTION[direction], 1.2);
    audio.shot();
  }

  private shootEnemy(enemy: EnemyEntity, angle: number, speed: number, damage: number): void {
    if (this.enemyProjectiles.countActive(true) >= MAX_ENEMY_PROJECTILES || !enemy.active) return;
    const projectile = new ProjectileEntity(this, enemy.x, enemy.y, 'enemy-projectile', {
      owner: 'enemy',
      damage,
      velocityX: Math.cos(angle) * speed,
      velocityY: Math.sin(angle) * speed,
      maxDistance: 620,
    });
    this.enemyProjectiles.add(projectile);
    projectile.setVelocity(Math.cos(angle) * speed, Math.sin(angle) * speed);
    audio.enemyShot();
  }

  private shootRadial(enemy: EnemyEntity, count: number, speed: number, damage: number, offset = 0): void {
    const available = Math.max(0, MAX_ENEMY_PROJECTILES - this.enemyProjectiles.countActive(true));
    const total = Math.min(count, available);
    for (let index = 0; index < total; index += 1) {
      this.shootEnemy(enemy, offset + (Math.PI * 2 * index) / count, speed, damage);
    }
  }

  private updateEnemies(time: number): void {
    for (const enemy of this.activeEnemies()) {
      if (this.fixture === 'boss' && enemy.kind === 'tollmother') {
        enemy.setVelocity(0, 0);
        continue;
      }
      enemy.updateAi(time, this.player);
    }
  }

  private updateProjectiles(delta: number): void {
    const enemies = this.activeEnemies();
    for (const projectile of this.activeProjectiles(this.playerProjectiles))
      projectile.updateMotion(delta, enemies);
    for (const projectile of this.activeProjectiles(this.enemyProjectiles))
      projectile.updateMotion(delta, enemies);
  }

  private hitEnemy(projectile: ProjectileEntity, enemy: EnemyEntity): void {
    if (!projectile.active || !enemy.active) return;
    const body = projectile.body as Phaser.Physics.Arcade.Body | null;
    const velocityAngle = body?.velocity.angle();
    const damage = projectile.damage;
    const impactX = projectile.x;
    const impactY = projectile.y;
    if (!projectile.consumeHit(enemy.entityId)) return;
    const result = enemy.takeDamage(damage, velocityAngle);
    this.runStats.damageDealt += result.applied;
    audio.hit();
    this.cameras.main.shake(42, 0.0017);
    this.spawnImpact(impactX, impactY, enemy.kind === 'tollmother' ? 9 : 5);
    if (result.killed) this.killEnemy(enemy);
  }

  private killEnemy(enemy: EnemyEntity): void {
    if (!enemy.active) return;
    const { x, y, kind } = enemy;
    // an ashmoth comes apart in a ring of slow embers
    if (kind === 'ashmoth') this.shootRadial(enemy, 6, 135, 8, this.runClockMs / 500);
    enemy.destroy();
    this.runStats.kills += 1;
    this.spawnDeathBurst(x, y, kind === 'tollmother' ? 24 : 12);
    this.cameras.main.shake(kind === 'tollmother' ? 260 : 90, kind === 'tollmother' ? 0.008 : 0.003);

    if (kind === 'tollmother' && this.floor < LAST_FLOOR) {
      this.currentRoom.cleared = true;
      this.runStats.roomsCleared += 1;
      for (const survivor of this.activeEnemies()) survivor.destroy();
      this.enemyProjectiles.clear(true, true);
      this.doorsOpen = true;
      this.updateDoors();
      this.spawnDescent(ROOM_CENTER.x, ROOM_CENTER.y);
      audio.door();
      gameEvents.emit('toast', { title: 'THE WELL OPENS', subtitle: 'STEP IN TO DESCEND', duration: 1_600 });
      this.publishSnapshot(true);
      return;
    }

    if (kind === 'tollmother') {
      this.currentRoom.cleared = true;
      this.runStats.roomsCleared += 1;
      this.runEnding = true;
      this.player.controls.reset();
      this.player.setVelocity(0, 0);
      for (const survivor of this.activeEnemies()) survivor.destroy();
      this.enemyProjectiles.clear(true, true);
      this.physics.pause();
      this.time.delayedCall(850, () => this.finishRun(true));
      return;
    }

    if (!this.roomRewardDropped && this.lootRng.bool(0.02 + this.stats.luck)) {
      this.roomRewardDropped = true;
      const item = this.lootRng.pick(ITEM_DEFINITIONS);
      this.spawnItem(item.id, x, y, false);
    }
    if (this.activeEnemies().length === 0) this.time.delayedCall(380, () => this.handleRoomCleared());
  }

  private handleRoomCleared(): void {
    if (this.currentRoom.cleared || this.activeEnemies().length > 0 || this.phase !== 'running') return;
    this.currentRoom.cleared = true;
    this.runStats.roomsCleared += 1;
    this.doorsOpen = true;
    this.enemyProjectiles.clear(true, true);
    this.updateDoors();
    audio.door();
    gameEvents.emit('toast', { title: 'CHAMBER QUIET', subtitle: 'THE SEALS HAVE OPENED', duration: 1_050 });

    if (!this.roomRewardDropped) {
      const guaranteed = this.roomsWithoutReward >= 2;
      if (guaranteed || this.lootRng.bool(0.32 + this.stats.luck)) {
        this.roomRewardDropped = true;
        this.roomsWithoutReward = 0;
        this.spawnChest(ROOM_CENTER.x, ROOM_CENTER.y);
      } else {
        this.roomsWithoutReward += 1;
        if (this.hp < this.stats.maxHp * 0.7 && this.lootRng.bool(0.18))
          this.spawnOil(ROOM_CENTER.x, ROOM_CENTER.y);
      }
    }
    this.publishSnapshot(true);
  }

  private spawnChest(x: number, y: number): void {
    const chest = this.physics.add.image(x, y, 'chest');
    chest
      .setDepth(12)
      .setImmovable(true)
      .setData('pickupType', 'chest')
      .setData('availableAt', this.runClockMs + 240);
    this.pickups.add(chest);
    this.bindPickupLifecycle(chest);
    this.tweens.add({ targets: chest, y: y - 7, duration: 680, yoyo: true, repeat: -1, ease: 'Sine.InOut' });
  }

  private spawnDescent(x: number, y: number): void {
    const well = this.physics.add.image(x, y, 'floor-exit');
    well
      .setDepth(6)
      .setImmovable(true)
      .setData('pickupType', 'descent')
      .setData('availableAt', this.runClockMs + 600);
    this.pickups.add(well);
    this.bindPickupLifecycle(well);
    this.tweens.add({ targets: well, angle: 360, duration: 6_000, repeat: -1 });
  }

  private descend(): void {
    if (this.transitioning || this.runEnding) return;
    this.transitioning = true;
    this.player.controls.reset();
    this.player.setVelocity(0, 0);
    this.physics.pause();
    const carry: RunCarry = {
      inventory: { ...this.inventory },
      hp: this.hp,
      runClockMs: this.runClockMs,
      runStats: { ...this.runStats },
      tolls: this.tolls,
    };
    this.cameras.main.fadeOut(420, 4, 3, 6);
    this.time.delayedCall(440, () => this.scene.restart({ seed: this.seed, floor: this.floor + 1, carry }));
  }

  private spawnTollRing(x: number, y: number): void {
    const rings: Array<[number, number]> = [
      [0, 0xe0b06c],
      [90, 0x9fd6d2],
    ];
    for (const [delay, color] of rings) {
      const ring = this.add.circle(x, y, 18).setStrokeStyle(4, color, 0.85).setDepth(31);
      this.tweens.add({
        targets: ring,
        radius: 520,
        alpha: 0,
        delay,
        duration: 520,
        ease: 'Cubic.Out',
        onComplete: () => ring.destroy(),
      });
    }
  }

  private spawnOil(x: number, y: number): void {
    const oil = this.physics.add.image(x, y, 'oil-pickup');
    oil
      .setDepth(13)
      .setData('pickupType', 'oil')
      .setData('availableAt', this.runClockMs + 200);
    this.pickups.add(oil);
    this.bindPickupLifecycle(oil);
    this.tweens.add({ targets: oil, scale: 1.12, duration: 520, yoyo: true, repeat: -1 });
  }

  private spawnItem(itemId: string, x: number, y: number, immediatelyAvailable: boolean): void {
    const item = ITEM_BY_ID.get(itemId);
    if (!item) throw new Error(`Unknown item: ${itemId}`);
    const pickup = this.physics.add.image(x, y, `item-${item.id}`);
    pickup
      .setDepth(14)
      .setData('pickupType', 'item')
      .setData('itemId', item.id)
      .setData('availableAt', immediatelyAvailable ? this.runClockMs : this.runClockMs + 320);
    this.pickups.add(pickup);
    const halo = this.add.circle(x, y, 30, item.color, 0.11).setDepth(10).setBlendMode(Phaser.BlendModes.ADD);
    pickup.setData('halo', halo);
    this.bindPickupLifecycle(pickup, halo);
    this.tweens.add({
      targets: [pickup, halo],
      y: `-=7`,
      duration: 720,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.InOut',
    });
  }

  private bindPickupLifecycle(
    pickup: Phaser.Physics.Arcade.Image,
    decoration?: Phaser.GameObjects.GameObject,
  ): void {
    pickup.once(Phaser.GameObjects.Events.DESTROY, () => {
      this.tweens.killTweensOf(pickup);
      if (decoration) {
        this.tweens.killTweensOf(decoration);
        decoration.destroy();
      }
    });
  }

  private collectPickup(pickup: Phaser.Physics.Arcade.Image): void {
    if (!pickup.active || this.runClockMs < Number(pickup.getData('availableAt') ?? 0)) return;
    const type = String(pickup.getData('pickupType') ?? '');
    if (type === 'chest') {
      const x = pickup.x;
      const y = pickup.y;
      pickup.destroy();
      const item = this.lootRng.pick(ITEM_DEFINITIONS);
      this.spawnItem(item.id, x, y, false);
      audio.door();
      return;
    }
    if (type === 'descent') {
      this.descend();
      return;
    }
    if (type === 'oil') {
      const healed = Math.min(15, this.stats.maxHp - this.hp);
      this.hp += healed;
      pickup.destroy();
      gameEvents.emit('toast', { title: `RESOLVE +${healed}`, subtitle: 'LAMP OIL', duration: 850 });
      audio.item();
      return;
    }
    if (type === 'item') {
      const itemId = String(pickup.getData('itemId') ?? '');
      const halo = pickup.getData('halo') as Phaser.GameObjects.Arc | undefined;
      halo?.destroy();
      pickup.destroy();
      this.collectItem(itemId);
    }
  }

  private collectItem(itemId: string): void {
    const item = ITEM_BY_ID.get(itemId);
    if (!item) throw new Error(`Unknown item: ${itemId}`);
    const oldMaxHp = this.stats.maxHp;
    this.inventory = addItem(this.inventory, itemId);
    this.stats = deriveStats(this.inventory);
    if (itemId === 'blackwax-knot')
      this.hp = Math.min(this.stats.maxHp, this.hp + (this.stats.maxHp - oldMaxHp));
    this.runStats.pickups += 1;
    this.currentRoom.rewardClaimed = true;
    const stacks = this.inventory[itemId] ?? 1;
    this.player.setTint(item.color);
    this.time.delayedCall(420, () => this.player.active && this.player.clearTint());
    this.spawnImpact(this.player.x, this.player.y, 18, item.color);
    audio.item();
    gameEvents.emit('item', { item, stacks });
    gameEvents.emit('toast', {
      title: `${item.name}${stacks > 1 ? ` ×${stacks}` : ''}`,
      subtitle: item.epithet,
      duration: 1_500,
    });
    this.publishSnapshot(true);
  }

  private damagePlayer(amount: number, sourceX: number, sourceY: number): void {
    if (
      this.phase !== 'running' ||
      this.runEnding ||
      this.transitioning ||
      !Number.isFinite(amount) ||
      amount <= 0 ||
      this.player.isInvulnerable(this.runClockMs)
    )
      return;
    const applied = Math.min(this.hp, amount);
    this.hp = Math.max(0, this.hp - applied);
    this.runStats.damageTaken += applied;
    this.player.setInvulnerable(this.runClockMs + INVULNERABILITY_MS);
    const angle = Phaser.Math.Angle.Between(sourceX, sourceY, this.player.x, this.player.y);
    this.player.applyKnockback(Math.cos(angle) * 280, Math.sin(angle) * 280, this.runClockMs + 130);
    this.cameras.main.shake(130, 0.007);
    this.cameras.main.flash(90, 145, 42, 47, false);
    audio.hurt();
    gameEvents.emit('toast', {
      title: `RESOLVE ${this.hp}/${this.stats.maxHp}`,
      subtitle: `−${applied}`,
      duration: 620,
    });
    if (this.hp <= 0) this.finishRun(false);
  }

  private checkDoorTraversal(): void {
    if (!this.doorsOpen || this.transitioning) return;
    let direction: Direction | null = null;
    if (this.player.y < ROOM_BOUNDS.top - 5) direction = 'north';
    else if (this.player.y > ROOM_BOUNDS.bottom + 5) direction = 'south';
    else if (this.player.x < ROOM_BOUNDS.left - 5) direction = 'west';
    else if (this.player.x > ROOM_BOUNDS.right + 5) direction = 'east';
    if (!direction) return;
    const targetId = this.currentRoom.neighbors[direction];
    if (!targetId) {
      this.player.setPosition(
        Phaser.Math.Clamp(this.player.x, ROOM_BOUNDS.left + 18, ROOM_BOUNDS.right - 18),
        Phaser.Math.Clamp(this.player.y, ROOM_BOUNDS.top + 18, ROOM_BOUNDS.bottom - 18),
      );
      return;
    }
    this.transitioning = true;
    this.player.controls.reset();
    this.player.setVelocity(0, 0);
    this.physics.pause();
    this.cameras.main.fadeOut(100, 6, 5, 8);
    this.time.delayedCall(105, () => this.loadRoom(this.getRoom(targetId), OPPOSITE_DIRECTION[direction]));
  }

  private finishRun(victory: boolean): void {
    if (this.phase === 'dead' || this.phase === 'victory') return;
    this.phase = victory ? 'victory' : 'dead';
    this.physics.pause();
    this.player.controls.reset();
    if (victory) audio.victory();
    const result: GameResult = {
      victory,
      seed: this.seed,
      kills: this.runStats.kills,
      pickups: this.runStats.pickups,
      roomsCleared: this.runStats.roomsCleared,
      elapsedMs: this.elapsedMs(),
      damageDealt: Math.round(this.runStats.damageDealt),
      damageTaken: this.runStats.damageTaken,
    };
    gameEvents.emit('phase', this.phase);
    gameEvents.emit('result', result);
    this.publishSnapshot(true);
  }

  private applyFixture(): void {
    if (this.fixture === 'normal') return;
    if (this.fixture === 'single-enemy') {
      this.currentRoom.kind = 'combat';
      this.currentRoom.cleared = false;
      this.doorsOpen = false;
      this.spawnEnemy('siltling', this.player.x + 150, this.player.y, 18);
      this.updateDoors();
    }
    if (this.fixture === 'loot') {
      this.currentRoom.cleared = true;
      this.doorsOpen = true;
      this.spawnItem('iron-lament', this.player.x + 95, this.player.y, true);
      this.updateDoors();
    }
    if (this.fixture === 'descent') {
      this.currentRoom.kind = 'boss';
      this.currentRoom.cleared = false;
      this.doorsOpen = false;
      this.spawnEnemy('tollmother', this.player.x + 165, this.player.y, 18);
      this.updateDoors();
    }
    if (this.fixture === 'boss') {
      this.runStats = { kills: 16, pickups: 4, roomsCleared: 5, damageDealt: 1_278, damageTaken: 35 };
      this.currentRoom.kind = 'boss';
      this.currentRoom.cleared = false;
      this.doorsOpen = false;
      this.spawnEnemy('tollmother', this.player.x + 165, this.player.y, 18);
      this.updateDoors();
    }
    if (this.fixture === 'death') this.hp = 10;
  }

  private activeEnemies(): EnemyEntity[] {
    return this.enemies
      .getChildren()
      .filter((child): child is EnemyEntity => child instanceof EnemyEntity && child.active);
  }

  private activeProjectiles(group: Phaser.Physics.Arcade.Group): ProjectileEntity[] {
    return group
      .getChildren()
      .filter((child): child is ProjectileEntity => child instanceof ProjectileEntity && child.active);
  }

  private getRoom(id: string): RoomNode {
    const room = this.dungeon.rooms.find((candidate) => candidate.id === id);
    if (!room) throw new Error(`Unknown room: ${id}`);
    return room;
  }

  private elapsedMs(): number {
    return Math.max(0, Math.round(this.runClockMs));
  }

  private publishSnapshot(force: boolean): void {
    if (!force) return;
    this.lastSnapshotAt = this.runClockMs;
    gameEvents.emit('snapshot', this.getDebugSnapshot());
  }

  private spawnImpact(x: number, y: number, count: number, color = 0xe8dfc8): void {
    for (let index = 0; index < count; index += 1) {
      const angle = (Math.PI * 2 * index) / count + this.fxRng.float(-0.18, 0.18);
      const distance = this.fxRng.int(10, 28);
      const particle = this.add.circle(x, y, this.fxRng.float(1.5, 3.2), color, 0.78).setDepth(30);
      this.tweens.add({
        targets: particle,
        x: x + Math.cos(angle) * distance,
        y: y + Math.sin(angle) * distance,
        alpha: 0,
        scale: 0.2,
        duration: this.fxRng.int(170, 360),
        onComplete: () => particle.destroy(),
      });
    }
  }

  private spawnDeathBurst(x: number, y: number, count: number): void {
    const stain = this.add.ellipse(x, y + 8, 20, 9, 0x29151c, 0.62).setDepth(4);
    this.roomDecorations.add(stain);
    stain.once(Phaser.GameObjects.Events.DESTROY, () => this.tweens.killTweensOf(stain));
    this.tweens.add({ targets: stain, scaleX: 2.2, scaleY: 1.5, alpha: 0.22, duration: 420 });
    this.spawnImpact(x, y, count, 0x8f4c4f);
  }
}

function doorGeometry(direction: Direction): { x: number; y: number; width: number; height: number } {
  if (direction === 'north')
    return { x: ROOM_CENTER.x, y: ROOM_BOUNDS.top, width: DOOR_SPAN, height: WALL_THICKNESS };
  if (direction === 'south')
    return { x: ROOM_CENTER.x, y: ROOM_BOUNDS.bottom, width: DOOR_SPAN, height: WALL_THICKNESS };
  if (direction === 'west')
    return { x: ROOM_BOUNDS.left, y: ROOM_CENTER.y, width: WALL_THICKNESS, height: DOOR_SPAN };
  return { x: ROOM_BOUNDS.right, y: ROOM_CENTER.y, width: WALL_THICKNESS, height: DOOR_SPAN };
}

function sanitizeSeed(value: string | undefined): string {
  const normalized = (value ?? 'MOURNWELL')
    .toUpperCase()
    .replace(/[^A-Z0-9-]/g, '')
    .slice(0, 20);
  return normalized || 'MOURNWELL';
}

function collisionProjectile(first: object, second: object): ProjectileEntity | null {
  if (first instanceof ProjectileEntity) return first;
  if (second instanceof ProjectileEntity) return second;
  return null;
}

function collisionEnemy(first: object, second: object): EnemyEntity | null {
  if (first instanceof EnemyEntity) return first;
  if (second instanceof EnemyEntity) return second;
  return null;
}
