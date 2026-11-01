export type GameState = 'PLAYING' | 'WON' | 'LOST';

export interface GameStateMachineCallbacks {
  onWin: () => void;
  onLose: () => void;
}

export class GameStateMachine {
  public state: GameState = 'PLAYING';
  private callbacks: GameStateMachineCallbacks;

  constructor(callbacks: GameStateMachineCallbacks) {
    this.callbacks = callbacks;
  }

  /** Called when boss is killed (player wins). */
  onBossKilled(): void {
    console.log('[GameSM] onBossKilled, state=', this.state);
    if (this.state === 'PLAYING') {
      this.state = 'WON';
      console.log('[GameSM] -> WON, calling onWin');
      this.callbacks.onWin();
    } else {
      console.log('[GameSM] ignored (not PLAYING)');
    }
  }

  /** Called when player dies (player loses). */
  onPlayerDied(): void {
    console.log('[GameSM] onPlayerDied, state=', this.state);
    if (this.state === 'PLAYING') {
      this.state = 'LOST';
      console.log('[GameSM] -> LOST, calling onLose');
      this.callbacks.onLose();
    } else {
      console.log('[GameSM] ignored (not PLAYING)');
    }
  }

  isPlaying(): boolean {
    return this.state === 'PLAYING';
  }

  isWon(): boolean {
    return this.state === 'WON';
  }

  isLost(): boolean {
    return this.state === 'LOST';
  }

  isGameOver(): boolean {
    return this.state === 'WON' || this.state === 'LOST';
  }
}
