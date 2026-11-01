import type { LaneIndex } from '../types/input';

/**
 * Lane utility class - represents a discrete lane position.
 * Provides helper methods for lane operations.
 */
export class Lane {
  private readonly index: LaneIndex;

  constructor(index: LaneIndex) {
    this.index = index;
  }

  /**
   * Get the lane index.
   */
  getIndex(): LaneIndex {
    return this.index;
  }

  /**
   * Clamp a value to valid lane indices.
   */
  static clamp(index: number): LaneIndex {
    if (index <= 0) return 0;
    if (index >= 2) return 2;
    return 1;
  }
}
