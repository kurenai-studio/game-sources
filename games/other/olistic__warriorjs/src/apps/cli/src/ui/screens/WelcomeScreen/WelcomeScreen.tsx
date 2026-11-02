import { Box, Text } from 'ink';
import type React from 'react';

import WarriorArt from '../../components/WarriorArt/index.js';
import formatDirectory from './utils/formatDirectory.js';

interface WelcomeScreenProps {
  version: string;
  directory: string;
}

export default function WelcomeScreen({
  version,
  directory,
}: WelcomeScreenProps): React.ReactElement {
  return (
    <Box gap={3}>
      <WarriorArt />
      <Box flexDirection="column" marginTop={1}>
        <Box gap={1}>
          <Text bold>WarriorJS</Text>
          <Text dimColor>{version}</Text>
        </Box>
        <Text dimColor>Write code. Fight enemies. Climb the tower.</Text>
        <Text dimColor>{formatDirectory(directory)}</Text>
      </Box>
    </Box>
  );
}
