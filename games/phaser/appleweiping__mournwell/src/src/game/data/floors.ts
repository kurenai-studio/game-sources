import type { EnemyKind } from '@/game/types';

export type WaveEnemy = Exclude<EnemyKind, 'tollmother'>;

export interface FloorTheme {
  depth: number;
  name: string;
  /** Enemies a combat chamber can roll; the first `primaries` lead a wave. */
  roster: WaveEnemy[];
  primaries: number;
  /** What the Tollmother calls in when she reaches her second phase. */
  bossSummon: WaveEnemy;
  /** Extra difficulty on top of the per-room distance scaling. */
  difficultyBonus: number;
  floorColor: number;
  bossFloorColor: number;
  wallColor: number;
  bossWallColor: number;
}

export const FLOORS: readonly FloorTheme[] = [
  {
    depth: 1,
    name: 'The Bell Archive',
    roster: ['siltling', 'wickspitter', 'knellguard'],
    primaries: 3,
    bossSummon: 'siltling',
    difficultyBonus: 0,
    floorColor: 0x1b171c,
    bossFloorColor: 0x211318,
    wallColor: 0x40363e,
    bossWallColor: 0x5c3037,
  },
  {
    depth: 2,
    name: 'The Drowned Belfry',
    roster: ['ashmoth', 'chimewraith', 'siltling', 'wickspitter', 'knellguard'],
    primaries: 2,
    bossSummon: 'ashmoth',
    difficultyBonus: 0.2,
    floorColor: 0x141a1c,
    bossFloorColor: 0x1b1520,
    wallColor: 0x2e4346,
    bossWallColor: 0x4a3150,
  },
];

export const LAST_FLOOR = FLOORS.length;

export function floorTheme(depth: number): FloorTheme {
  const theme = FLOORS[Math.min(Math.max(1, Math.floor(depth)), LAST_FLOOR) - 1];
  if (!theme) throw new Error(`No floor ${depth}`);
  return theme;
}

/** Seed for a floor's layout; depth 1 keeps the plain run seed so old seeds replay the same. */
export function floorSeed(runSeed: string, depth: number): string {
  return depth <= 1 ? runSeed : `${runSeed}::depth-${depth}`;
}
