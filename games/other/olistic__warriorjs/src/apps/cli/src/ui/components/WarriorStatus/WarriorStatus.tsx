import { Box, Text } from 'ink';
import type React from 'react';

interface WarriorStatusProps {
  health: number;
  maxHealth: number;
  score: number;
}

export default function WarriorStatus({
  health,
  maxHealth,
  score,
}: WarriorStatusProps): React.ReactElement {
  return (
    <Box gap={2}>
      <Text color="red">{`❤ ${health}/${maxHealth}`}</Text>
      <Text color="yellow">{`◆ ${score}`}</Text>
    </Box>
  );
}
