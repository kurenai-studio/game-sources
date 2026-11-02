import { Box, Text, useInput } from 'ink';
import type React from 'react';
import { useState } from 'react';

interface ErrorMessageProps {
  message: string;
  onDismiss?: () => void;
}

export default function ErrorMessage({
  message,
  onDismiss,
}: ErrorMessageProps): React.ReactElement | null {
  const [dismissed, setDismissed] = useState(false);

  const dismissable = !!onDismiss;

  useInput(
    () => {
      if (dismissed) return;
      setDismissed(true);
      onDismiss!();
    },
    { isActive: dismissable },
  );

  if (dismissed) return null;

  return (
    <Box flexDirection="column">
      <Text color="red">{message}</Text>
      {dismissable && <Text dimColor>Press any key to continue...</Text>}
    </Box>
  );
}
