import Phaser from 'phaser';
import { BASE_STATS, ITEM_BY_ID } from '@/game/data/items';
import { gameEvents } from '@/game/events';
import { BELL } from '@/game/systems/bell';
import { generateDungeon } from '@/game/systems/dungeon';
import type { GameScene } from '@/game/scenes/GameScene';
import type { GameDebugBridge, GameDebugSnapshot, GameTestControls } from '@/game/types';

function menuSnapshot(): GameDebugSnapshot {
  const dungeon = generateDungeon('MOURNWELL', 5);
  const room = dungeon.rooms[0];
  if (!room) throw new Error('Unable to create the menu debug snapshot');
  return {
    schemaVersion: 1,
    phase: 'menu',
    seed: 'MOURNWELL',
    tick: 0,
    floor: 1,
    summary: {
      hp: BASE_STATS.maxHp,
      maxHp: BASE_STATS.maxHp,
      enemyCount: 0,
      bulletCount: 0,
      currentRoom: room.id,
      itemIds: [],
      attributes: {
        attack: BASE_STATS.damage,
        fireRate: Number((1000 / BASE_STATS.fireInterval).toFixed(2)),
        projectileSpeed: BASE_STATS.shotSpeed,
        moveSpeed: BASE_STATS.moveSpeed,
        range: BASE_STATS.range,
      },
    },
    player: {
      x: 480,
      y: 340,
      facing: 'south',
      invulnerable: false,
      active: false,
      visible: false,
      renderable: false,
    },
    room: { id: room.id, index: room.index, kind: room.kind, cleared: true, doorsOpen: true, doors: [] },
    counts: { enemies: 0, playerProjectiles: 0, enemyProjectiles: 0, pickups: 0 },
    bell: { ready: true, readyInMs: 0, cost: BELL.cost, tolls: 0 },
    enemies: [],
    inventory: [],
    stats: { ...BASE_STATS },
    dungeon,
    run: { kills: 0, pickups: 0, roomsCleared: 0, elapsedMs: 0, damageDealt: 0, damageTaken: 0 },
    metrics: { fps: 0, entityCount: 0 },
  };
}

function clone(snapshot: GameDebugSnapshot): GameDebugSnapshot {
  return structuredClone(snapshot);
}

export function createDebugBridge(game: Phaser.Game): GameDebugBridge {
  let latest = menuSnapshot();
  const subscribers = new Set<(snapshot: GameDebugSnapshot) => void>();
  gameEvents.on('snapshot', (snapshot) => {
    latest = clone(snapshot);
    subscribers.forEach((listener) => listener(clone(latest)));
  });
  gameEvents.on('phase', (phase) => {
    latest = { ...latest, phase };
    subscribers.forEach((listener) => listener(clone(latest)));
  });

  const getScene = (): GameScene => game.scene.getScene('GameScene') as GameScene;
  const afterFrame = async (): Promise<GameDebugSnapshot> =>
    new Promise((resolve, reject) =>
      requestAnimationFrame(() => {
        try {
          const scene = getScene();
          // a reset may have stopped the scene since this was requested
          const live = scene.sys.isActive() || scene.sys.isPaused();
          resolve(clone(live ? scene.getDebugSnapshot() : latest));
        } catch (error) {
          reject(error instanceof Error ? error : new Error(String(error)));
        }
      }),
    );
  const nextFrame = async (): Promise<void> =>
    new Promise((resolve) => requestAnimationFrame(() => resolve()));

  const query = new URLSearchParams(window.location.search);
  const qaControlsEnabled = import.meta.env.DEV && query.get('qa') === '1';
  let resetQueue = Promise.resolve();
  let test: GameTestControls | undefined;
  if (qaControlsEnabled) {
    test = {
      reset(options) {
        const operation = resetQueue.then(async () => {
          const runScene = getScene();
          if (runScene.scene.isActive() || runScene.scene.isPaused()) {
            game.scene.stop('GameScene');
            await nextFrame();
          }
          const created = new Promise<void>((resolve) => {
            runScene.events.once(Phaser.Scenes.Events.CREATE, () => resolve());
          });
          if (game.scene.isActive('MenuScene')) game.scene.stop('MenuScene');
          game.scene.start('GameScene', options);
          await created;
          return afterFrame();
        });
        resetQueue = operation.then(
          () => undefined,
          () => undefined,
        );
        return operation;
      },
      pause() {
        getScene().pauseGame();
        return Promise.resolve(clone(getScene().getDebugSnapshot()));
      },
      async resume() {
        getScene().resumeGame();
        return afterFrame();
      },
      async clearRoom() {
        getScene().debugClearRoom();
        return afterFrame();
      },
      async grantItem(itemId) {
        if (!ITEM_BY_ID.has(itemId)) throw new Error(`Unknown item: ${itemId}`);
        getScene().debugGrantItem(itemId);
        return afterFrame();
      },
      async spawnEnemy(type, options) {
        getScene().debugSpawnEnemy(type, options);
        return afterFrame();
      },
      async spawnItem(itemId, options) {
        if (!ITEM_BY_ID.has(itemId)) throw new Error(`Unknown item: ${itemId}`);
        getScene().debugSpawnItem(itemId, options);
        return afterFrame();
      },
      async damagePlayer(amount) {
        getScene().debugDamagePlayer(Math.max(0, Math.min(10_000, amount)));
        return afterFrame();
      },
      async enterRoom(roomId) {
        getScene().debugEnterRoom(roomId);
        return afterFrame();
      },
    };
  }

  const bridge: GameDebugBridge = {
    apiVersion: 1,
    build: { version: __APP_VERSION__, qaControlsEnabled },
    get state() {
      try {
        const scene = getScene();
        if (scene?.currentRoom) latest = scene.getDebugSnapshot();
      } catch {
        // Menu state is intentionally available before the run scene exists.
      }
      return clone(latest);
    },
    ready: () => Promise.resolve(clone(latest)),
    getSnapshot: () => bridge.state,
    subscribe(listener) {
      subscribers.add(listener);
      return () => subscribers.delete(listener);
    },
    ...(test ? { test } : {}),
  };
  return Object.freeze(bridge);
}
