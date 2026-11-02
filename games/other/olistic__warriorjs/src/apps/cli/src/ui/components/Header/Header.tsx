import { Box, Text } from 'ink';
import type React from 'react';

interface HeaderProps {
  warriorName: string;
  towerName: string;
  levelNumber?: number;
  score?: number;
}

export default function Header({
  warriorName,
  towerName,
  levelNumber,
  score,
}: HeaderProps): React.ReactElement {
  return (
    <Box flexDirection="row" justifyContent="space-between" width="100%">
      <Text bold>{'0={==> WarriorJS'}</Text>
      <Box gap={1}>
        <Text bold>{warriorName}</Text>
        <Text dimColor>{'·'}</Text>
        <Text>{towerName}</Text>
        {levelNumber !== undefined && (
          <>
            <Text dimColor>{'·'}</Text>
            <Text dimColor>{`Level ${levelNumber}`}</Text>
          </>
        )}
        {score !== undefined && (
          <>
            <Text dimColor>{'·'}</Text>
            <Text dimColor>{`Score ${score}`}</Text>
          </>
        )}
      </Box>
    </Box>
  );
}
