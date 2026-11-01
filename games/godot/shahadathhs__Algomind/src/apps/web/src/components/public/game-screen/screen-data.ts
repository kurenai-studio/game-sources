/** The numbers a drawn game screen shows besides the board and the tape (from the real level). */
export type ScreenData = {
  levelNumber: string;
  levelTitle: string;
  /** The most commands the level allows. */
  budget: number;
  /** The figures of the solved screen. */
  stats: { used: number; limit: number; steps: number; best: number };
};
