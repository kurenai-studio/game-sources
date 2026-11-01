import type { GameState } from 'src/types/game';

import { Grid } from '../Grid';
import { Hud } from '../Hud';

export interface GameProps {
  state: GameState;
  onToggle: (index: number) => void;
}

/**
 * The running game: heads-up display, playfield, and result feedback.
 *
 * @param props - Live game state and the cell toggle handler.
 * @returns The rendered game screen.
 */
export function Game({ state, onToggle }: GameProps) {
  const count = state.phase === 'input' ? state.pattern.length : null;

  return (
    <section className="flex w-full max-w-xl flex-col gap-4 text-center">
      <Hud round={state.round} count={count} timeLeft={state.timeLeft} />

      <Grid
        gridSize={state.gridSize}
        pattern={state.pattern}
        selection={state.selection}
        phase={state.phase}
        result={state.result}
        onToggle={onToggle}
      />

      <div aria-live="polite" className="min-h-8 text-lg font-semibold">
        {state.phase === 'feedback' && (
          <p
            className={
              state.result === 'correct'
                ? 'text-emerald-600 dark:text-emerald-400'
                : 'text-red-500'
            }
          >
            {state.result === 'correct' ? 'Correct!' : 'Wrong!'}
          </p>
        )}
      </div>
    </section>
  );
}
