import { Box, Text, useInput } from 'ink';
import type React from 'react';
import { useState } from 'react';

interface TextPromptProps {
  message: string;
  defaultValue?: string;
  initialValue?: string;
  onSubmit: (value: string) => void;
  onCancel?: () => void;
}

export default function TextPrompt({
  message,
  defaultValue = '',
  initialValue = '',
  onSubmit,
  onCancel,
}: TextPromptProps): React.ReactElement {
  const [value, setValue] = useState(initialValue);
  const [submitted, setSubmitted] = useState(false);

  useInput((input, key) => {
    if (submitted) return;

    if (key.return) {
      const result = value || defaultValue;
      setSubmitted(true);
      onSubmit(result);
      return;
    }

    if (key.backspace || key.delete) {
      setValue((prev) => prev.slice(0, -1));
      return;
    }

    if (key.escape && onCancel) {
      onCancel();
      return;
    }

    // Ignore control characters.
    if (key.ctrl || key.meta || key.escape) return;
    if (key.upArrow || key.downArrow || key.leftArrow || key.rightArrow) return;
    if (key.tab) return;

    setValue((prev) => prev + input);
  });

  if (submitted) {
    const display = value || defaultValue;
    return (
      <Text>
        <Text bold>{message}</Text> {display}
      </Text>
    );
  }

  return (
    <Box gap={1}>
      <Text bold>{message}</Text>
      {value ? (
        <Text>{value}</Text>
      ) : defaultValue ? (
        <Text dimColor>{`(${defaultValue})`}</Text>
      ) : null}
    </Box>
  );
}
