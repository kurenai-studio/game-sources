import { Box, Text } from 'ink';
import type React from 'react';

interface ScrubberProps {
  currentTurn: number;
  totalTurns: number;
  speed: number;
  mode: 'playback' | 'review';
  isPlaying: boolean;
}

export default function Scrubber({
  currentTurn,
  totalTurns,
  speed,
  mode,
  isPlaying,
}: ScrubberProps): React.ReactElement {
  const turnDisplay = `Turn ${currentTurn}/${totalTurns - 1}`;

  if (mode === 'playback') {
    return (
      <Box gap={2}>
        <Text dimColor>{turnDisplay}</Text>
        <Box gap={1}>
          <Text dimColor>{'[tab]'}</Text>
          {[1, 2, 4].map((s) => (
            <Text key={s} dimColor={s !== speed} bold={s === speed}>
              {`${s}x`}
            </Text>
          ))}
        </Box>
        <Text dimColor>{isPlaying ? '[space] pause' : '[space] play'}</Text>
        <Text dimColor>{'[s] skip'}</Text>
      </Box>
    );
  }

  return (
    <Box gap={2}>
      <Text dimColor>{turnDisplay}</Text>
      <Text dimColor>{'[←/→] step'}</Text>
      <Text dimColor>{'[esc] go back'}</Text>
    </Box>
  );
}
