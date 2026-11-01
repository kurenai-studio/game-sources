import { ScoreDisplay } from './score-display';
import { type PanelContent, StatePanel } from './state-panel';

interface GameOverlayProps {
  scoreText: string;
  isScoreVisible: boolean;
  panelContent: PanelContent | null;
  onPrimaryAction: () => void;
}

export function GameOverlay({
  scoreText,
  isScoreVisible,
  panelContent,
  onPrimaryAction,
}: GameOverlayProps) {
  return (
    <>
      <ScoreDisplay scoreText={scoreText} isVisible={isScoreVisible} />
      <StatePanel content={panelContent} onPrimaryAction={onPrimaryAction} />
    </>
  );
}
