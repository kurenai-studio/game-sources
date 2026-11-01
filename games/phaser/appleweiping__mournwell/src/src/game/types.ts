export type Direction = 'north' | 'south' | 'east' | 'west';
export type RoomKind = 'start' | 'combat' | 'treasure' | 'boss';
export type GamePhase = 'boot' | 'menu' | 'running' | 'paused' | 'dead' | 'victory';
export type EnemyKind = 'siltling' | 'wickspitter' | 'knellguard' | 'ashmoth' | 'chimewraith' | 'tollmother';
export type RunFixture = 'normal' | 'single-enemy' | 'loot' | 'boss' | 'descent' | 'death';

export interface Vector2Like {
  x: number;
  y: number;
}

export interface RoomNode {
  id: string;
  index: number;
  x: number;
  y: number;
  kind: RoomKind;
  distance: number;
  neighbors: Partial<Record<Direction, string>>;
  visited: boolean;
  cleared: boolean;
  rewardClaimed: boolean;
}

export interface DungeonLayout {
  seed: string;
  rooms: RoomNode[];
  startId: string;
  treasureId: string;
  bossId: string;
}

export interface PlayerStats {
  maxHp: number;
  damage: number;
  fireInterval: number;
  shotSpeed: number;
  moveSpeed: number;
  range: number;
  luck: number;
  projectiles: number;
  spread: number;
  pierce: number;
  homing: number;
  projectileScale: number;
}

export interface ItemEffectSummary {
  damage?: number;
  fireRate?: number;
  moveSpeed?: number;
  range?: number;
  maxHp?: number;
  projectiles?: number;
  pierce?: number;
  homing?: number;
}

export interface ItemDefinition {
  id: string;
  name: string;
  epithet: string;
  description: string;
  color: number;
  glyph: string;
  effectSummary: ItemEffectSummary;
}

export type Inventory = Record<string, number>;

export interface EnemySnapshot {
  id: string;
  type: EnemyKind;
  hp: number;
  maxHp: number;
  x: number;
  y: number;
  state: string;
}

export interface DebugDoorSnapshot {
  direction: Direction;
  targetRoomId: string;
  locked: boolean;
}

export interface GameDebugSnapshot {
  schemaVersion: 1;
  phase: GamePhase;
  seed: string;
  tick: number;
  floor: number;
  summary: {
    hp: number;
    maxHp: number;
    enemyCount: number;
    bulletCount: number;
    currentRoom: string;
    itemIds: string[];
    attributes: {
      attack: number;
      fireRate: number;
      projectileSpeed: number;
      moveSpeed: number;
      range: number;
    };
  };
  player: {
    x: number;
    y: number;
    facing: Direction;
    invulnerable: boolean;
    active: boolean;
    visible: boolean;
    renderable: boolean;
  };
  room: {
    id: string;
    index: number;
    kind: RoomKind;
    cleared: boolean;
    doorsOpen: boolean;
    doors: DebugDoorSnapshot[];
  };
  counts: {
    enemies: number;
    playerProjectiles: number;
    enemyProjectiles: number;
    pickups: number;
  };
  bell: {
    ready: boolean;
    readyInMs: number;
    cost: number;
    tolls: number;
  };
  enemies: EnemySnapshot[];
  inventory: Array<{
    id: string;
    stacks: number;
    effects: ItemEffectSummary;
  }>;
  stats: PlayerStats;
  dungeon: DungeonLayout;
  run: {
    kills: number;
    pickups: number;
    roomsCleared: number;
    elapsedMs: number;
    damageDealt: number;
    damageTaken: number;
  };
  metrics: {
    fps: number;
    entityCount: number;
  };
}

export interface GameResult {
  victory: boolean;
  seed: string;
  kills: number;
  pickups: number;
  roomsCleared: number;
  elapsedMs: number;
  damageDealt: number;
  damageTaken: number;
}

export interface GameTestControls {
  reset(options: { seed: string; fixture?: RunFixture }): Promise<GameDebugSnapshot>;
  pause(): Promise<GameDebugSnapshot>;
  resume(): Promise<GameDebugSnapshot>;
  clearRoom(): Promise<GameDebugSnapshot>;
  grantItem(itemId: string): Promise<GameDebugSnapshot>;
  spawnEnemy(type: EnemyKind, options?: { hp?: number; x?: number; y?: number }): Promise<GameDebugSnapshot>;
  spawnItem(itemId: string, options?: { x?: number; y?: number }): Promise<GameDebugSnapshot>;
  damagePlayer(amount: number): Promise<GameDebugSnapshot>;
  enterRoom(roomId: string): Promise<GameDebugSnapshot>;
}

export interface GameDebugBridge {
  apiVersion: 1;
  build: {
    version: string;
    qaControlsEnabled: boolean;
  };
  readonly state: GameDebugSnapshot;
  ready(): Promise<GameDebugSnapshot>;
  getSnapshot(): GameDebugSnapshot;
  subscribe(listener: (state: GameDebugSnapshot) => void): () => void;
  test?: GameTestControls;
}

export interface UiState {
  snapshot: GameDebugSnapshot;
}

export const OPPOSITE_DIRECTION: Record<Direction, Direction> = {
  north: 'south',
  south: 'north',
  east: 'west',
  west: 'east',
};

export const DIRECTION_VECTOR: Record<Direction, Vector2Like> = {
  north: { x: 0, y: -1 },
  south: { x: 0, y: 1 },
  east: { x: 1, y: 0 },
  west: { x: -1, y: 0 },
};
