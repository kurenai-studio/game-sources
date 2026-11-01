import { useEffect } from 'react';
import { useBestScore } from 'src/hooks/useBestScore';
import type { GameOverReason, Mode } from 'src/types/game';
import { success } from 'websfx';

import { Button } from '../Button';
import { Confetti } from '../Confetti';

export interface GameOverProps {
  mode: Mode;
  score: number;
  reason: GameOverReason | null;
  onAgain: () => void;
  onMenu: () => void;
}

/**
 * End-of-run screen: final score, best score, record celebration, and
 * actions to replay or return to the menu.
 *
 * @param props - Finished run details and navigation callbacks.
 * @returns The rendered game-over screen.
 */
export function GameOver({
  mode,
  score,
  reason,
  onAgain,
  onMenu,
}: GameOverProps) {
  const { best, record } = useBestScore(mode, score);

  useEffect(() => {
    if (record) {
      success();
    }
  }, [record]);

  return (
    <section className="flex w-full max-w-xl flex-col items-center gap-6 px-6 text-center">
      {record && <Confetti />}

      <div>
        <p className="text-sm font-medium tracking-widest text-slate-500 uppercase dark:text-slate-400">
          {mode === 'timed' ? 'Timed run' : 'Classic run'}
        </p>
        <h1 className="mt-1 text-4xl font-bold text-slate-900 dark:text-slate-100">
          {reason === 'timeout' ? "Time's up!" : 'Game Over'}
        </h1>
      </div>

      <div>
        <p className="text-6xl font-bold text-sky-600 dark:text-sky-400">
          {score}
        </p>
        <p className="mt-1 text-sm tracking-wider text-slate-500 uppercase dark:text-slate-400">
          Rounds cleared
        </p>
      </div>

      {record && (
        <p
          role="status"
          className="text-lg font-semibold text-amber-500 dark:text-amber-400"
        >
          New record!
        </p>
      )}

      <p className="text-sm text-slate-600 dark:text-slate-400">Best: {best}</p>

      <div className="flex flex-wrap justify-center gap-3">
        <Button variant="primary" onClick={onAgain}>
          Play again
        </Button>
        <Button variant="secondary" onClick={onMenu}>
          Menu
        </Button>
      </div>
    </section>
  );
}
