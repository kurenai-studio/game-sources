import { Text } from 'ink';
import type React from 'react';

import { brandColor } from '../../theme.js';

const art = [
  // A warrior holding a sword.
  '       ▌',
  ' ▐▛██▜▌▌',
  '▝▜████▛▛',
  '  ▘▘▝▝',
].join('\n');

export default function WarriorArt(): React.ReactElement {
  return <Text color={brandColor}>{art}</Text>;
}
