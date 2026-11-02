import { Box, Text, useInput } from 'ink';
import type React from 'react';
import { useState } from 'react';

interface SelectChoice<T> {
  label: string;
  value: T;
  description?: string;
  separator?: false;
}

interface SelectSeparator {
  separator: true;
}

type SelectItem<T> = SelectChoice<T> | SelectSeparator;

interface SelectPromptProps<T> {
  message: string;
  items: SelectItem<T>[];
  initialIndex?: number;
  onSelect: (value: T) => void;
  onCancel?: () => void;
}

export default function SelectPrompt<T>({
  message,
  items,
  initialIndex = 0,
  onSelect,
  onCancel,
}: SelectPromptProps<T>): React.ReactElement {
  const choices = items.filter((item): item is SelectChoice<T> => !item.separator);
  const [selectedIndex, setSelectedIndex] = useState(initialIndex);
  const [submitted, setSubmitted] = useState(false);

  useInput((_input, key) => {
    if (submitted) return;

    if (key.escape && onCancel) {
      onCancel();
      return;
    }

    if (key.return) {
      setSubmitted(true);
      onSelect(choices[selectedIndex]!.value);
      return;
    }

    if (key.upArrow) {
      setSelectedIndex((prev) => (prev > 0 ? prev - 1 : choices.length - 1));
    }

    if (key.downArrow) {
      setSelectedIndex((prev) => (prev < choices.length - 1 ? prev + 1 : 0));
    }
  });

  if (submitted) {
    const answer = choices[selectedIndex]!.label;
    return message ? (
      <Text>
        <Text bold>{message}</Text> {answer}
      </Text>
    ) : (
      <Text>{answer}</Text>
    );
  }

  let choiceIndex = 0;
  return (
    <Box flexDirection="column">
      {message ? <Text bold>{message}</Text> : null}
      {items.map((item, index) => {
        if (item.separator) {
          return (
            // biome-ignore lint/suspicious/noArrayIndexKey: static item list
            <Text key={`sep-${index}`} dimColor>
              {'───'}
            </Text>
          );
        }
        const currentChoiceIndex = choiceIndex++;
        const isSelected = currentChoiceIndex === selectedIndex;
        return (
          // biome-ignore lint/suspicious/noArrayIndexKey: static item list
          <Box key={`choice-${index}`} flexDirection="column">
            <Box gap={1}>
              <Text color={isSelected ? 'yellow' : undefined}>{isSelected ? '❯' : ' '}</Text>
              <Text dimColor={!isSelected}>{item.label}</Text>
            </Box>
            {item.description ? (
              <Text dimColor>
                {'  '}
                {item.description}
              </Text>
            ) : null}
          </Box>
        );
      })}
    </Box>
  );
}
