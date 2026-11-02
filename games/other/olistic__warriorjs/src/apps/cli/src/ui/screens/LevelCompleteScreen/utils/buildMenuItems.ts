import { type LevelCompleteChoice, type LevelReport } from '../../../../types.js';

export default function buildMenuItems(
  report: LevelReport,
): { label: string; value: LevelCompleteChoice }[] {
  if (report.passed) {
    return [
      report.hasNextLevel
        ? { label: 'Next level', value: 'next-level' }
        : { label: 'Enter epic mode', value: 'epic-mode' },
      { label: 'Review turns', value: 'review' },
      { label: 'Stay and hone', value: 'stay' },
    ];
  }

  return [
    { label: 'Try again', value: 'try-again' },
    { label: 'Review turns', value: 'review' },
    ...(report.hasClue && !report.isShowingClue
      ? [{ label: 'Reveal clues', value: 'clue' as const }]
      : []),
  ];
}
