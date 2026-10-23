import * as Config from '../config.js';

export default class MatchManager {
  constructor() {
    this.reset();
  }

  reset() {
    this.round = 1;
    this.playerScore = 0;
    this.aiScore = 0;
  }

  recordRoundWin(winner) {
    if (winner === 'player') {
      this.playerScore++;
    } else {
      this.aiScore++;
    }
  }

  isMatchOver() {
    return this.playerScore >= Config.ROUNDS_TO_WIN ||
           this.aiScore >= Config.ROUNDS_TO_WIN ||
           this.round > Config.MAX_ROUNDS;
  }

  getMatchWinner() {
    if (this.playerScore > this.aiScore) return 'player';
    if (this.aiScore > this.playerScore) return 'ai';
    return null;
  }

  nextRound() {
    this.round++;
  }

  getRoundData(winner) {
    return {
      winner,
      playerScore: this.playerScore,
      aiScore: this.aiScore,
      round: this.round,
    };
  }

  getMatchData() {
    return {
      playerWon: this.getMatchWinner() === 'player',
      playerScore: this.playerScore,
      aiScore: this.aiScore,
    };
  }
}
