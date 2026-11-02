import { getGradeLetter } from '@warriorjs/scoring';
import { Box, Text } from 'ink';
import type React from 'react';

interface TowerCompleteScreenProps {
  averageGrade: number;
  levelGrades: Record<string, number>;
}

export default function TowerCompleteScreen({
  averageGrade,
  levelGrades,
}: TowerCompleteScreenProps): React.ReactElement {
  return (
    <Box flexDirection="column">
      <Text>
        {'Your average grade for this tower is: '}
        <Text color={'yellow'}>{getGradeLetter(averageGrade)}</Text>
      </Text>
      <Box flexDirection="column" marginTop={1}>
        {Object.keys(levelGrades)
          .sort()
          .map((levelNumber) => (
            <Text key={levelNumber}>
              {'  Level '}
              {levelNumber}
              {': '}
              <Text color={'yellow'}>{getGradeLetter(levelGrades[levelNumber]!)}</Text>
            </Text>
          ))}
      </Box>
      <Text dimColor>{'\nTo practice a level, use the -l option.'}</Text>
    </Box>
  );
}
