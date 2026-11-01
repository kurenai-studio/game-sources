import {
  DUCK_DURATION,
  DUCK_HEIGHT_REDUCTION,
  JUMP_DURATION,
  JUMP_HEIGHT,
  LANE_TRANSITION_DURATION,
} from '../config/game-constants';
import type { LaneIndex } from '../types/input';
import type { PlayerAction } from '../types/obstacle';

/**
 * Player class - represents the player character entity.
 */
export class Player {
  private currentLane: LaneIndex = 1;
  private targetLane: LaneIndex = 1;
  private isJumping = false;
  private isDucking = false;
  private jumpProgress = 0;
  private duckProgress = 0;
  private verticalPosition = 0;
  private targetVerticalPosition = 0;
  private laneTransitionProgress = 0;
  private currentAction: PlayerAction = 'NONE';

  getCurrentLane(): LaneIndex {
    return this.currentLane;
  }

  getTargetLane(): LaneIndex {
    return this.targetLane;
  }

  isSwitchingLanes(): boolean {
    return this.currentLane !== this.targetLane;
  }

  getIsJumping(): boolean {
    return this.isJumping;
  }

  getIsDucking(): boolean {
    return this.isDucking;
  }

  getJumpProgress(): number {
    return this.jumpProgress;
  }

  getDuckProgress(): number {
    return this.duckProgress;
  }

  getVerticalPosition(): number {
    return this.verticalPosition;
  }

  getCurrentAction(): PlayerAction {
    return this.currentAction;
  }

  switchLane(lane: LaneIndex): boolean {
    if (this.isSwitchingLanes() || this.isJumping || this.isDucking) {
      return false;
    }

    if (lane === this.currentLane) {
      return false;
    }

    this.targetLane = lane;
    this.laneTransitionProgress = 0;
    this.currentAction = 'LANE_CHANGE';
    return true;
  }

  startJump(): boolean {
    if (this.isJumping || this.isDucking || this.isSwitchingLanes()) {
      return false;
    }

    this.isJumping = true;
    this.jumpProgress = 0;
    this.targetVerticalPosition = JUMP_HEIGHT;
    this.currentAction = 'JUMP';
    return true;
  }

  startDuck(): boolean {
    if (this.isJumping) {
      return false;
    }

    if (this.isDucking) {
      this.duckProgress = 0;
      this.targetVerticalPosition = -DUCK_HEIGHT_REDUCTION;
      this.currentAction = 'DUCK';
      return true;
    }

    if (this.isSwitchingLanes()) {
      return false;
    }

    this.isDucking = true;
    this.duckProgress = 0;
    this.targetVerticalPosition = -DUCK_HEIGHT_REDUCTION;
    this.currentAction = 'DUCK';
    return true;
  }

  update(deltaTime: number) {
    if (this.isSwitchingLanes()) {
      this.laneTransitionProgress += deltaTime / LANE_TRANSITION_DURATION;
      if (this.laneTransitionProgress >= 1) {
        this.currentLane = this.targetLane;
        this.laneTransitionProgress = 0;
        this.currentAction = 'NONE';
      }
    }

    if (this.isJumping) {
      this.jumpProgress += deltaTime / JUMP_DURATION;
      if (this.jumpProgress >= 1) {
        this.isJumping = false;
        this.jumpProgress = 0;
        this.verticalPosition = 0;
        this.targetVerticalPosition = 0;
        this.currentAction = 'NONE';
      } else {
        this.verticalPosition =
          Math.sin(this.jumpProgress * Math.PI) * JUMP_HEIGHT;
      }
    }

    if (this.isDucking) {
      this.duckProgress += deltaTime / DUCK_DURATION;
      if (this.duckProgress >= 1) {
        this.isDucking = false;
        this.duckProgress = 0;
        this.verticalPosition = 0;
        this.targetVerticalPosition = 0;
        this.currentAction = 'NONE';
      } else {
        this.verticalPosition = -this.duckProgress * DUCK_HEIGHT_REDUCTION;
      }
    }

    if (!this.isJumping && !this.isDucking) {
      this.verticalPosition +=
        (this.targetVerticalPosition - this.verticalPosition) * 0.2;
    }
  }

  getInterpolatedX(lanePositions: Record<LaneIndex, number>): number {
    if (!this.isSwitchingLanes()) {
      return lanePositions[this.currentLane];
    }

    const startX = lanePositions[this.currentLane];
    const endX = lanePositions[this.targetLane];
    return startX + (endX - startX) * this.laneTransitionProgress;
  }

  reset() {
    this.currentLane = 1;
    this.targetLane = 1;
    this.isJumping = false;
    this.isDucking = false;
    this.jumpProgress = 0;
    this.duckProgress = 0;
    this.verticalPosition = 0;
    this.targetVerticalPosition = 0;
    this.laneTransitionProgress = 0;
    this.currentAction = 'NONE';
  }
}
