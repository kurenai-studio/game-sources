import { useGame } from 'src/hooks/useGame';

import { Game } from '../Game';
import { GameOver } from '../GameOver';
import { Menu } from '../Menu';
import { SoundToggle } from '../SoundToggle';

export function App() {
  const { state, start, toggle, again, toMenu } = useGame();

  const playing = state.phase !== 'menu' && state.phase !== 'gameover';

  return (
    <main className="flex min-h-dvh w-full touch-manipulation flex-col items-center justify-center gap-8 bg-white px-2 py-8 text-slate-900 sm:px-4 dark:bg-slate-900 dark:text-slate-100">
      <div className="fixed top-3 right-3 z-10 sm:top-5 sm:right-5">
        <SoundToggle />
      </div>
      {state.phase === 'menu' && <Menu onStart={start} />}
      {playing && <Game state={state} onToggle={toggle} />}
      {state.phase === 'gameover' && (
        <GameOver
          mode={state.mode}
          score={state.score}
          reason={state.reason}
          onAgain={again}
          onMenu={toMenu}
        />
      )}
    </main>
  );
}
