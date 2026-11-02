import { Text, useStdout } from 'ink';
import type React from 'react';

export default function Divider(): React.ReactElement {
  const { stdout } = useStdout();
  return <Text dimColor>{'─'.repeat(stdout.columns || 80)}</Text>;
}
