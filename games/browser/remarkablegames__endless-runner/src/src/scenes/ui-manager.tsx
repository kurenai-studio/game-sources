import { SoundManager } from '../audio';
import { GameStateEnum } from '../types/game-state';
import { GameOverlay, type PanelContent } from '../ui';

type ButtonMode = 'start' | 'resume' | 'restart';
type OverlayPanelContent = PanelContent & {
  mode: ButtonMode;
};

/**
 * Lightweight DOM UI for game states and score.
 */
export class UIManager {
  private readonly uiOverlay = document.getElementById(
    'ui-overlay',
  ) as HTMLDivElement;
  private readonly soundManager: SoundManager;
  private readonly startRun: () => void;
  private readonly resumeRun: () => void;
  private buttonMode: ButtonMode = 'start';
  private lastRenderedState: GameStateEnum | null = null;
  private lastRenderedScore = Number.NaN;

  constructor(
    soundManager: SoundManager,
    startRun: () => void,
    resumeRun: () => void,
  ) {
    this.soundManager = soundManager;
    this.startRun = startRun;
    this.resumeRun = resumeRun;
    this.updateOverlay('', false, null);
  }

  /**
   * Update score and visible panel based on game state.
   */
  render(state: GameStateEnum, score: number) {
    const roundedScore = Math.floor(score);
    if (
      state === this.lastRenderedState &&
      roundedScore === this.lastRenderedScore
    ) {
      return;
    }

    this.lastRenderedState = state;
    this.lastRenderedScore = roundedScore;

    const panelContent = this.getPanelContent(state, roundedScore);
    if (panelContent !== null) {
      this.buttonMode = panelContent.mode;
    }

    this.updateOverlay(
      `Distance ${String(roundedScore)}m`,
      state !== GameStateEnum.Start,
      panelContent,
    );
  }

  /**
   * Cleanup DOM nodes.
   */
  dispose() {
    this.uiOverlay.remove();
  }

  private handlePrimaryAction() {
    this.soundManager.click.play();

    if (this.buttonMode === 'start') {
      this.startRun();
      return;
    }

    if (this.buttonMode === 'resume') {
      this.resumeRun();
      return;
    }

    this.startRun();
  }

  private getPanelContent(
    state: GameStateEnum,
    roundedScore: number,
  ): OverlayPanelContent | null {
    if (state === GameStateEnum.Start) {
      return {
        title: 'Endless Runner',
        message:
          '3 lanes. Jump or duck to avoid obstacles. Survive as speed ramps up.',
        buttonLabel: 'Start Run',
        mode: 'start',
      };
    }

    if (state === GameStateEnum.Paused) {
      return {
        title: 'Paused',
        message: 'Press P or Esc to resume.',
        buttonLabel: 'Resume',
        mode: 'resume',
      };
    }

    if (state === GameStateEnum.GameOver) {
      return {
        title: 'Game Over',
        message: `Final distance ${String(roundedScore)}m. Press R to restart.`,
        buttonLabel: 'Restart',
        mode: 'restart',
      };
    }

    return null;
  }

  private updateOverlay(
    scoreText: string,
    isScoreVisible: boolean,
    panelContent: PanelContent | null,
  ) {
    this.uiOverlay.replaceChildren(
      <GameOverlay
        scoreText={scoreText}
        isScoreVisible={isScoreVisible}
        panelContent={panelContent}
        onPrimaryAction={() => {
          this.handlePrimaryAction();
        }}
      />,
    );
  }
}
