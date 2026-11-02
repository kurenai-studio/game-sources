import { Box, Text } from 'ink';
import type React from 'react';
import { useState } from 'react';

import { type GameContext } from '../../../Game.js';
import type Profile from '../../../Profile.js';
import type Tower from '../../../Tower.js';
import { formatRelativeTime } from '../../../utils/formatRelativeTime.js';
import ConfirmPrompt from '../ConfirmPrompt/index.js';
import ErrorMessage from '../ErrorMessage/index.js';
import SelectPrompt from '../SelectPrompt/index.js';
import TextPrompt from '../TextPrompt/index.js';

type WizardStep =
  | { type: 'choose-profile' }
  | { type: 'create-name'; from?: 'new' | 'choose-profile'; initialValue?: string }
  | { type: 'create-name-error' }
  | { type: 'create-language'; warriorName: string; initialIndex?: number }
  | {
      type: 'create-tower';
      warriorName: string;
      language: 'javascript' | 'typescript';
      initialIndex?: number;
    }
  | {
      type: 'create-confirm-replace';
      warriorName: string;
      language: 'javascript' | 'typescript';
      tower: Tower;
    };

interface ProfileWizardProps {
  context: GameContext;
  suggestedName: string;
  initialStep: 'new' | 'choose-profile';
  onComplete: (profile: Profile) => void;
  onCancel: () => void;
  onError: (message: string) => void;
}

export default function ProfileWizard({
  context,
  suggestedName,
  initialStep,
  onComplete,
  onCancel,
  onError,
}: ProfileWizardProps): React.ReactElement | null {
  const [step, setStep] = useState<WizardStep>(
    initialStep === 'choose-profile'
      ? { type: 'choose-profile' }
      : { type: 'create-name', from: 'new' },
  );
  const [history, setHistory] = useState<React.ReactElement[]>([]);

  const pushHistory = (question: string, answer: string) => {
    setHistory((prev) => [
      ...prev,
      <Text key={prev.length}>
        <Text bold>{question}</Text> {answer}
      </Text>,
    ]);
  };

  const popHistory = () => {
    setHistory((prev) => prev.slice(0, -1));
  };

  const renderStep = (): React.ReactElement | null => {
    switch (step.type) {
      case 'choose-profile': {
        const items: (
          | { label: string; description?: string; value: Profile | 'new' }
          | { separator: true }
        )[] = [
          ...context.profiles.map((p) => ({
            label: p.toString(),
            description: p.lastPlayedAt
              ? `last played ${formatRelativeTime(p.lastPlayedAt)}`
              : undefined,
            value: p as Profile | 'new',
          })),
          { separator: true as const },
          { label: 'New profile', value: 'new' as const },
        ];
        return (
          <SelectPrompt
            key="choose-profile"
            message="Your sword awaits. Which warrior answers the call?"
            items={items}
            onSelect={(value) => {
              if (value === 'new') {
                pushHistory('Your sword awaits. Which warrior answers the call?', 'New profile');
                setStep({ type: 'create-name', from: 'choose-profile' });
              } else {
                onComplete(value);
              }
            }}
          />
        );
      }

      case 'create-name':
        return (
          <TextPrompt
            key="create-name"
            message="Every legend needs a name. Enter one for your warrior:"
            defaultValue={suggestedName}
            initialValue={step.initialValue}
            onSubmit={(name) => {
              if (!name) {
                setStep({ type: 'create-name-error' });
                return;
              }
              pushHistory('Every legend needs a name. Enter one for your warrior:', name);
              setStep({ type: 'create-language', warriorName: name });
            }}
            onCancel={() => {
              popHistory();
              if (step.from === 'choose-profile') {
                setStep({ type: 'choose-profile' });
              } else {
                onCancel();
              }
            }}
          />
        );

      case 'create-name-error':
        return (
          <ErrorMessage
            key="create-name-error"
            message="A warrior without a name is just a shadow. Try again."
            onDismiss={() => setStep({ type: 'create-name' })}
          />
        );

      case 'create-language': {
        const items: { label: string; value: 'typescript' | 'javascript' }[] = [
          { label: 'TypeScript (recommended)', value: 'typescript' },
          { label: 'JavaScript', value: 'javascript' },
        ];
        return (
          <SelectPrompt
            key="create-language"
            message="Choose your language:"
            items={items}
            initialIndex={step.initialIndex}
            onSelect={(value) => {
              const label = value === 'typescript' ? 'TypeScript' : 'JavaScript';
              pushHistory('Choose your language:', label);
              setStep({
                type: 'create-tower',
                warriorName: step.warriorName,
                language: value,
              });
            }}
            onCancel={() => {
              popHistory();
              setStep({ type: 'create-name', initialValue: step.warriorName });
            }}
          />
        );
      }

      case 'create-tower': {
        const items = context.towers.map((t) => ({ label: t.toString(), value: t }));
        return (
          <SelectPrompt
            key="create-tower"
            message="Choose a tower:"
            items={items}
            initialIndex={step.initialIndex}
            onSelect={(tower) => {
              const profile = context.onCreateProfile(step.warriorName, step.language, tower);
              if (context.onIsExistingProfile(profile)) {
                pushHistory('Choose a tower:', tower.toString());
                setStep({
                  type: 'create-confirm-replace',
                  warriorName: step.warriorName,
                  language: step.language,
                  tower,
                });
              } else {
                profile.makeProfileDirectory();
                onComplete(profile);
              }
            }}
            onCancel={() => {
              popHistory();
              const languageIndex = step.language === 'typescript' ? 0 : 1;
              setStep({
                type: 'create-language',
                warriorName: step.warriorName,
                initialIndex: languageIndex,
              });
            }}
          />
        );
      }

      case 'create-confirm-replace':
        return (
          <Box flexDirection="column">
            <Text>{`A warrior named ${step.warriorName} is already climbing ${step.tower}.`}</Text>
            <ConfirmPrompt
              message="Do you want to replace your existing profile for this tower?"
              onConfirm={(yes) => {
                if (!yes) {
                  onError('Unable to continue without a profile.');
                  return;
                }
                const profile = context.onCreateProfile(
                  step.warriorName,
                  step.language,
                  step.tower,
                );
                onComplete(profile);
              }}
            />
          </Box>
        );
    }
  };

  return (
    <Box flexDirection="column">
      {history}
      {renderStep()}
    </Box>
  );
}
