import { Box } from 'ink';
import type React from 'react';

import { type LevelContext, type LevelReplay } from '../../../types.js';
import Divider from '../Divider/index.js';
import FloorMap from '../FloorMap/index.js';
import Header from '../Header/index.js';

interface LevelLayoutProps {
  replay: LevelReplay;
  context: LevelContext;
  children: React.ReactNode;
}

export default function LevelLayout({
  replay,
  context,
  children,
}: LevelLayoutProps): React.ReactElement {
  const lastTurnEvents = replay.turns[replay.turns.length - 1];
  const lastEvent = lastTurnEvents?.[lastTurnEvents.length - 1];

  return (
    <Box flexDirection="column" width="100%">
      <Header
        warriorName={context.warriorName}
        towerName={context.towerName}
        levelNumber={context.levelNumber}
        score={context.totalScore}
      />
      <Box flexDirection="column">{lastEvent && <FloorMap floorMap={lastEvent.floorMap} />}</Box>
      <Divider />
      {children}
    </Box>
  );
}
