import { getGradeLetter } from '@warriorjs/scoring';
import { Box, Text } from 'ink';
import type React from 'react';

interface ResultScreenProps {
  passed: boolean;
  levelNumber: number;
  hasNextLevel: boolean;
  scoreParts: { warrior: number; timeBonus: number; clearBonus: number };
  totalScore: number;
  grade: number;
  isEpic: boolean;
  previousScore: number;
}

export default function ResultScreen({
  passed,
  levelNumber,
  hasNextLevel,
  scoreParts,
  totalScore,
  grade,
  isEpic,
  previousScore,
}: ResultScreenProps): React.ReactElement {
  if (!passed) {
    return (
      <Text
        color={'red'}
      >{`You failed level ${levelNumber}. Update your code and try again.`}</Text>
    );
  }

  const successMessage = hasNextLevel
    ? 'Success! You have found the stairs.'
    : 'CONGRATULATIONS! You have climbed to the top of the tower.';

  return (
    <Box flexDirection="column">
      <Text color={'green'}>{successMessage}</Text>
      <Box flexDirection="column" marginTop={1}>
        <Text>
          {'Warrior Score: '}
          <Text color={'yellow'}>{scoreParts.warrior}</Text>
        </Text>
        <Text>
          {'Time Bonus: '}
          <Text color={'yellow'}>{scoreParts.timeBonus}</Text>
        </Text>
        <Text>
          {'Clear Bonus: '}
          <Text color={'yellow'}>{scoreParts.clearBonus}</Text>
        </Text>
        {isEpic && (
          <Text>
            {'Level Grade: '}
            <Text color={'yellow'}>{getGradeLetter(grade)}</Text>
          </Text>
        )}
        <Text>
          {'Total Score: '}
          <Text
            color={'yellow'}
          >{`${previousScore} + ${totalScore} = ${previousScore + totalScore}`}</Text>
        </Text>
      </Box>
    </Box>
  );
}
