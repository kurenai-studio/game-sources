import { useEffect, useRef } from 'react';
import { getGame } from '../game/PhaserGame.js';

export function useGameEvents({ onHudUpdate, onRoundOver, onMatchOver, active }) {
  const callbacksRef = useRef({ onHudUpdate, onRoundOver, onMatchOver });
  callbacksRef.current = { onHudUpdate, onRoundOver, onMatchOver };

  useEffect(() => {
    if (!active) return;

    let cleanup = null;

    const poll = setInterval(() => {
      const game = getGame();
      if (!game || !game.events) return;

      const hudHandler = (data) => callbacksRef.current.onHudUpdate?.(data);
      const roundHandler = (data) => callbacksRef.current.onRoundOver?.(data);
      const matchHandler = (data) => callbacksRef.current.onMatchOver?.(data);

      game.events.on('hud-update', hudHandler);
      game.events.on('round-over', roundHandler);
      game.events.on('match-over', matchHandler);

      clearInterval(poll);

      cleanup = () => {
        game.events.off('hud-update', hudHandler);
        game.events.off('round-over', roundHandler);
        game.events.off('match-over', matchHandler);
      };
    }, 100);

    return () => {
      clearInterval(poll);
      if (cleanup) cleanup();
    };
  }, [active]);
}
