import { Box } from 'ink';
import type React from 'react';
import { useMemo } from 'react';

import { type LevelContext, type LevelReplay } from '../../../types.js';
import Divider from '../../components/Divider/index.js';
import FloorMap from '../../components/FloorMap/index.js';
import Header from '../../components/Header/index.js';
import LogArea from '../../components/LogArea/index.js';
import Scrubber from '../../components/Scrubber/index.js';
import WarriorStatus from '../../components/WarriorStatus/index.js';
import { usePlayback } from '../../hooks/usePlayback.js';

interface PlayScreenProps {
  replay: LevelReplay;
  context: LevelContext;
  reviewMode?: boolean;
  onPlaybackComplete: () => void;
}

export default function PlayScreen({
  replay,
  context,
  reviewMode,
  onPlaybackComplete,
}: PlayScreenProps): React.ReactElement {
  const turnsWithInitial = useMemo(
    () => [[replay.initialState], ...replay.turns],
    [replay.initialState, replay.turns],
  );
  const { state } = usePlayback(turnsWithInitial, onPlaybackComplete, reviewMode);
  const { cursor } = state;
  const currentEvent = turnsWithInitial[cursor.turn]?.[cursor.event];

  return (
    <Box flexDirection="column" width="100%">
      <Header
        warriorName={context.warriorName}
        towerName={context.towerName}
        levelNumber={context.levelNumber}
        score={context.totalScore}
      />
      <Box flexDirection="column">
        {currentEvent && (
          <>
            <FloorMap floorMap={currentEvent.floorMap} />
            {currentEvent.warriorStatus && (
              <WarriorStatus
                health={currentEvent.warriorStatus.health}
                maxHealth={context.maxHealth}
                score={currentEvent.warriorStatus.score}
              />
            )}
          </>
        )}
      </Box>
      <Divider />
      <Box flexDirection="column" height={10}>
        <LogArea turns={turnsWithInitial} cursor={cursor} mode={state.mode} />
      </Box>
      <Divider />
      <Scrubber
        currentTurn={cursor.turn}
        totalTurns={turnsWithInitial.length}
        speed={state.speed}
        mode={state.mode}
        isPlaying={state.isPlaying}
      />
    </Box>
  );
}
