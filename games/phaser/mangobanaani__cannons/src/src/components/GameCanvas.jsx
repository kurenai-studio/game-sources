import React, { useEffect, useRef } from 'react';
import { createGame, destroyGame, getGame } from '../game/PhaserGame.js';

export default function GameCanvas({ difficulty }) {
  const containerRef = useRef(null);
  const initializedRef = useRef(false);

  useEffect(() => {
    if (!containerRef.current || initializedRef.current) return;
    initializedRef.current = true;

    const game = createGame(containerRef.current);

    game.events.once('ready', () => {
      const scene = game.scene.getScene('GameScene');
      if (scene) {
        scene.setDifficulty(difficulty);
      }
    });

    // If scene is already running, set difficulty
    const checkScene = () => {
      const existing = getGame();
      if (existing && existing.scene) {
        const scene = existing.scene.getScene('GameScene');
        if (scene && scene.scene.isActive()) {
          scene.setDifficulty(difficulty);
        }
      }
    };
    const timer = setTimeout(checkScene, 200);

    return () => {
      clearTimeout(timer);
      initializedRef.current = false;
      destroyGame();
    };
  }, []);

  // Update difficulty if it changes while game is running
  useEffect(() => {
    const game = getGame();
    if (game && game.scene) {
      const scene = game.scene.getScene('GameScene');
      if (scene && scene.scene.isActive()) {
        scene.setDifficulty(difficulty);
      }
    }
  }, [difficulty]);

  return (
    <div
      ref={containerRef}
      style={{ width: 800, height: 600 }}
      data-testid="game-canvas"
    />
  );
}
