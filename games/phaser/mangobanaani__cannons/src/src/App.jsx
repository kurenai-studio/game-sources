import React, { useState, useCallback } from 'react';
import Menu from './components/Menu.jsx';
import GameCanvas from './components/GameCanvas.jsx';
import HUD from './components/HUD.jsx';
import RoundOver from './components/RoundOver.jsx';
import GameOver from './components/GameOver.jsx';
import { useGameEvents } from './hooks/useGameEvents.js';

export default function App() {
  const [screen, setScreen] = useState('menu');
  const [difficulty, setDifficulty] = useState('medium');
  const [hudData, setHudData] = useState(null);
  const [roundData, setRoundData] = useState(null);
  const [matchData, setMatchData] = useState(null);

  const handleStartGame = useCallback((diff) => {
    setDifficulty(diff);
    setScreen('game');
    setHudData(null);
    setRoundData(null);
    setMatchData(null);
  }, []);

  const handleHudUpdate = useCallback((data) => {
    setHudData(data);
  }, []);

  const handleRoundOver = useCallback((data) => {
    setRoundData(data);
    setScreen('roundOver');
  }, []);

  const handleMatchOver = useCallback((data) => {
    setMatchData(data);
    setScreen('gameOver');
  }, []);

  const handleNextRound = useCallback(() => {
    setScreen('game');
    setRoundData(null);
  }, []);

  const handleMainMenu = useCallback(() => {
    setScreen('menu');
    setHudData(null);
    setRoundData(null);
    setMatchData(null);
  }, []);

  useGameEvents({
    onHudUpdate: handleHudUpdate,
    onRoundOver: handleRoundOver,
    onMatchOver: handleMatchOver,
    active: screen === 'game',
  });

  return (
    <div style={{ position: 'relative', width: 800, height: 600 }}>
      {screen === 'menu' && (
        <Menu onStart={handleStartGame} />
      )}

      {(screen === 'game' || screen === 'roundOver') && (
        <>
          <GameCanvas difficulty={difficulty} />
          {hudData && screen === 'game' && <HUD data={hudData} />}
        </>
      )}

      {screen === 'roundOver' && roundData && (
        <RoundOver
          data={roundData}
          onNextRound={handleNextRound}
        />
      )}

      {screen === 'gameOver' && (
        <GameOver
          data={matchData}
          onPlayAgain={() => handleStartGame(difficulty)}
          onMainMenu={handleMainMenu}
        />
      )}
    </div>
  );
}
