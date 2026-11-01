import { useEffect } from 'react';
import type { Action } from 'src/types/game';
import { TICK_MS } from 'src/utils/difficulty';

/**
 * Dispatches a `TICK` action on an interval while active.
 *
 * @param active - Whether the clock is running.
 * @param dispatch - Stable game action dispatcher.
 */
export function useTimer(
  active: boolean,
  dispatch: (action: Action) => void,
): void {
  useEffect(() => {
    if (!active) {
      return;
    }

    const id = setInterval(() => {
      dispatch({ type: 'TICK' });
    }, TICK_MS);

    return () => {
      clearInterval(id);
    };
  }, [active, dispatch]);
}
