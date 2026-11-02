import { Box, Text, useInput } from 'ink';
import type React from 'react';
import { useState } from 'react';

interface ConfirmPromptProps {
  message: string;
  defaultValue?: boolean;
  onConfirm: (value: boolean) => void;
}

export default function ConfirmPrompt({
  message,
  defaultValue = false,
  onConfirm,
}: ConfirmPromptProps): React.ReactElement {
  const [submitted, setSubmitted] = useState(false);
  const [result, setResult] = useState(defaultValue);

  useInput((input, key) => {
    if (submitted) return;

    if (input === 'y' || input === 'Y') {
      setResult(true);
      setSubmitted(true);
      onConfirm(true);
      return;
    }

    if (input === 'n' || input === 'N') {
      setResult(false);
      setSubmitted(true);
      onConfirm(false);
      return;
    }

    if (key.return) {
      setSubmitted(true);
      onConfirm(defaultValue);
    }
  });

  if (submitted) {
    return (
      <Text>
        <Text bold>{message}</Text> {result ? 'Yes' : 'No'}
      </Text>
    );
  }

  const hint = defaultValue === true ? 'Y/n' : 'y/N';
  return (
    <Box gap={1}>
      <Text bold>{message}</Text>
      <Text dimColor>{`(${hint})`}</Text>
    </Box>
  );
}
