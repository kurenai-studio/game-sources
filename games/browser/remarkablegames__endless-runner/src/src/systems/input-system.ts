import { SoundManager } from '../audio';
import { Player } from '../entities/player';
import type { InputDirection } from '../types/input';

/**
 * Maps abstract input directions to player actions.
 */
export class InputSystem {
  private readonly player: Player;
  private readonly soundManager: SoundManager;

  constructor(player: Player, soundManager: SoundManager) {
    this.player = player;
    this.soundManager = soundManager;
  }

  /**
   * Apply a single directional input to the player.
   */
  handleDirection(direction: InputDirection) {
    switch (direction) {
      case 'LEFT': {
        const lane = Math.max(0, this.player.getCurrentLane() - 1) as 0 | 1 | 2;
        if (this.player.switchLane(lane)) {
          this.soundManager.move.play();
        }
        break;
      }

      case 'RIGHT': {
        const lane = Math.min(2, this.player.getCurrentLane() + 1) as 0 | 1 | 2;
        if (this.player.switchLane(lane)) {
          this.soundManager.move.play();
        }
        break;
      }

      case 'UP': {
        if (this.player.startJump()) {
          this.soundManager.jump.play();
        }
        break;
      }

      case 'DOWN': {
        if (this.player.startDuck()) {
          this.soundManager.duck.play();
        }
        break;
      }
    }
  }
}
