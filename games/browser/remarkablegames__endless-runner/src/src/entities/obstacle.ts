import type { LaneIndex } from '../types/input';
import type { ObstacleType } from '../types/obstacle';

/**
 * Obstacle class - represents an environmental hazard.
 * Tracks position, type, and avoidance requirements.
 */
export class Obstacle {
  private readonly id: string;
  private lane: LaneIndex;
  private type: ObstacleType;
  private zPosition: number;
  private isActive: boolean;

  constructor(
    id: string,
    lane: LaneIndex,
    type: ObstacleType,
    zPosition: number,
  ) {
    this.id = id;
    this.lane = lane;
    this.type = type;
    this.zPosition = zPosition;
    this.isActive = true;
  }

  /**
   * Get the obstacle ID.
   */
  getId(): string {
    return this.id;
  }

  /**
   * Get the current lane.
   */
  getLane(): LaneIndex {
    return this.lane;
  }

  /**
   * Get the obstacle type.
   */
  getType(): ObstacleType {
    return this.type;
  }

  /**
   * Get the Z position.
   */
  getZPosition(): number {
    return this.zPosition;
  }

  /**
   * Check if the obstacle is active.
   */
  getIsActive(): boolean {
    return this.isActive;
  }

  /**
   * Check if this obstacle requires a jump to avoid.
   */
  requiresJump(): boolean {
    return this.type === 'GROUND';
  }

  /**
   * Check if this obstacle requires a duck to avoid.
   */
  requiresDuck(): boolean {
    return this.type === 'AIRBORNE';
  }

  /**
   * Check if this obstacle requires a lane change to avoid.
   */
  requiresLaneChange(): boolean {
    return this.type === 'FULL_LANE';
  }

  /**
   * Update the Z position (moving toward player).
   * @param deltaZ - Distance to move
   */
  moveForward(deltaZ: number) {
    this.zPosition -= deltaZ;
  }

  /**
   * Deactivate the obstacle.
   */
  deactivate() {
    this.isActive = false;
  }

  /**
   * Reactivate the obstacle with new parameters.
   */
  reactivate(lane: LaneIndex, type: ObstacleType, zPosition: number) {
    this.lane = lane;
    this.type = type;
    this.zPosition = zPosition;
    this.isActive = true;
  }
}
