import type { ObstacleType } from '../types/obstacle';

interface ObstacleSpawn {
  /** Lane offset from player's current lane (0 = same lane) */
  laneOffset: number;
  /** Z offset from spawn point */
  zOffset: number;
  /** Type of obstacle */
  type: ObstacleType;
}

class ObstaclePattern {
  private readonly spawns: ObstacleSpawn[];
  private readonly minRunDuration: number;
  private readonly difficulty: number;

  constructor(
    spawns: ObstacleSpawn[],
    minRunDuration: number,
    difficulty: number,
  ) {
    this.spawns = spawns;
    this.minRunDuration = minRunDuration;
    this.difficulty = Math.max(0, Math.min(1, difficulty));
  }

  /**
   * Get all spawn points.
   */
  getSpawns(): ObstacleSpawn[] {
    return [...this.spawns];
  }

  /**
   * Get minimum run duration before this pattern can appear.
   */
  getMinRunDuration(): number {
    return this.minRunDuration;
  }

  /**
   * Get difficulty rating (0-1).
   */
  getDifficulty(): number {
    return this.difficulty;
  }

  /**
   * Check if this pattern is avoidable.
   * A pattern is avoidable if not all 3 lanes are blocked at the same Z.
   */
  isAvoidable(): boolean {
    const lanesByZ = new Map<number, Set<number>>();

    for (const spawn of this.spawns) {
      const zKey = spawn.zOffset;
      const lanesAtZ = lanesByZ.get(zKey) ?? new Set<number>();
      lanesByZ.set(zKey, lanesAtZ);
      // Normalize lane offset to absolute lane (0, 1, 2)
      // For validation, we just check if all 3 lanes would be blocked
      lanesAtZ.add(spawn.laneOffset + 1); // Center at 1
    }

    // Check if any Z position blocks all 3 lanes
    for (const lanes of lanesByZ.values()) {
      if (lanes.size >= 3) {
        return false;
      }
    }

    return true;
  }
}

/**
 * Default obstacle patterns for spawning.
 */
export const DEFAULT_PATTERNS: ObstaclePattern[] = [
  // Single center (easy)
  new ObstaclePattern([{ laneOffset: 0, zOffset: 0, type: 'GROUND' }], 0, 0.2),

  // Single left (easy)
  new ObstaclePattern([{ laneOffset: -1, zOffset: 0, type: 'GROUND' }], 0, 0.2),

  // Single right (easy)
  new ObstaclePattern([{ laneOffset: 1, zOffset: 0, type: 'GROUND' }], 0, 0.2),

  // Double sides with gap in middle (medium)
  new ObstaclePattern(
    [
      { laneOffset: -1, zOffset: 0, type: 'GROUND' },
      { laneOffset: 1, zOffset: 0, type: 'GROUND' },
    ],
    15,
    0.5,
  ),

  // Alternating obstacles (medium)
  new ObstaclePattern(
    [
      { laneOffset: 0, zOffset: 0, type: 'GROUND' },
      { laneOffset: -1, zOffset: -10, type: 'GROUND' },
    ],
    25,
    0.6,
  ),

  // Airborne center obstacle requiring duck (medium)
  new ObstaclePattern(
    [{ laneOffset: 0, zOffset: 0, type: 'AIRBORNE' }],
    18,
    0.5,
  ),

  // Full lane barrier (hard)
  new ObstaclePattern(
    [{ laneOffset: 0, zOffset: 0, type: 'FULL_LANE' }],
    35,
    0.7,
  ),

  // Three obstacles in sequence (hard)
  new ObstaclePattern(
    [
      { laneOffset: 0, zOffset: 0, type: 'GROUND' },
      { laneOffset: -1, zOffset: -8, type: 'GROUND' },
      { laneOffset: 1, zOffset: -16, type: 'GROUND' },
    ],
    50,
    0.8,
  ),
];
