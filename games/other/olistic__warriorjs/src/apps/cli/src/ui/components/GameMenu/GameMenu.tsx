import path from 'node:path';
import { Box, Text, useApp } from 'ink';
import Link from 'ink-link';
import type React from 'react';
import { useEffect, useRef, useState } from 'react';

import { type GameContext } from '../../../Game.js';
import type Profile from '../../../Profile.js';
import { type GameMenuStep } from '../../../types.js';
import WelcomeScreen from '../../screens/WelcomeScreen/index.js';
import Divider from '../Divider/index.js';
import ErrorMessage from '../ErrorMessage/index.js';
import ProfileWizard from '../ProfileWizard/index.js';
import SelectPrompt from '../SelectPrompt/index.js';
import getWarriorNameSuggestions from './utils/getWarriorNameSuggestions.js';

interface GameMenuProps {
  context: GameContext;
  onStart: (profile: Profile, levelNumber: number) => void;
}

export default function GameMenu({ context, onStart }: GameMenuProps): React.ReactElement {
  const { exit } = useApp();
  const [step, setStep] = useState<GameMenuStep | null>(() => {
    if (context.error || context.profile) return null; // handled in mount effect
    if (context.needsProfileSetup) {
      return context.profiles.length > 0
        ? { type: 'wizard', initialStep: 'choose-profile' as const }
        : { type: 'start' as const };
    }
    return null;
  });
  const [history, setHistory] = useState<React.ReactElement[]>([]);
  const [finalMessage, setFinalMessage] = useState<React.ReactElement | null>(null);
  const [suggestedName] = useState(() => getWarriorNameSuggestions()[0]);
  const initialized = useRef(false);

  const pushHistory = (element: React.ReactElement) => {
    setHistory((prev) => [...prev, element]);
  };

  const popHistory = () => {
    setHistory((prev) => prev.slice(0, -1));
  };

  function showFinalMessage(element: React.ReactElement) {
    setFinalMessage(element);
  }

  useEffect(() => {
    if (finalMessage) {
      exit();
    }
  }, [finalMessage, exit]);

  function handleProfileReady(selectedProfile: Profile) {
    context.onProfileSelected(selectedProfile);

    try {
      if (selectedProfile.isEpic()) {
        if (context.practiceLevel) {
          if (!selectedProfile.tower.hasLevel(context.practiceLevel)) {
            showFinalMessage(
              <ErrorMessage
                message={`Level ${context.practiceLevel} doesn't exist. This tower has ${selectedProfile.tower.levels.length} levels.`}
              />,
            );
            return;
          }
          onStart(selectedProfile, context.practiceLevel);
        } else {
          onStart(selectedProfile, 1);
        }
      } else {
        if (context.practiceLevel) {
          showFinalMessage(
            <ErrorMessage message="The -l option is only available in epic mode. Remove it to play normally." />,
          );
          return;
        }

        if (selectedProfile.levelNumber === 0) {
          context.onPrepareNextLevel();
          const readmePath = selectedProfile.getReadmeFilePath();
          showFinalMessage(
            <Box flexDirection="column">
              <Divider />
              <Text bold>
                {'Level 1 is ready. See '}
                <Link url={`file://${path.resolve(readmePath)}`} fallback={false}>
                  {readmePath}
                </Link>
                {' for instructions.'}
              </Text>
            </Box>,
          );
          return;
        }

        onStart(selectedProfile, selectedProfile.levelNumber);
      }
    } catch (err: unknown) {
      showFinalMessage(<ErrorMessage message={err instanceof Error ? err.message : String(err)} />);
    }
  }

  useEffect(() => {
    if (initialized.current) return;
    initialized.current = true;

    if (context.error) {
      showFinalMessage(<ErrorMessage message={context.error} />);
    } else if (context.profile && !context.needsProfileSetup) {
      handleProfileReady(context.profile);
    }
  });

  const renderStep = (): React.ReactElement | null => {
    if (!step) return null;

    switch (step.type) {
      case 'start': {
        const items = [
          { label: 'Venture forth', value: 'start' },
          { label: 'Retreat', value: 'quit' },
        ];
        return (
          <SelectPrompt
            message="A tower of enemies awaits. Do you dare enter?"
            items={items}
            onSelect={(value) => {
              if (value === 'start') {
                pushHistory(
                  <Text key={history.length}>
                    <Text bold>A tower of enemies awaits. Do you dare enter?</Text> Venture forth
                  </Text>,
                );
                setStep({ type: 'wizard', initialStep: 'new' });
              } else {
                showFinalMessage(<Text>Even the bravest need a moment to prepare.</Text>);
              }
            }}
          />
        );
      }

      case 'wizard':
        return (
          <ProfileWizard
            context={context}
            suggestedName={suggestedName!}
            initialStep={step.initialStep}
            onComplete={(selectedProfile) => handleProfileReady(selectedProfile)}
            onCancel={() => {
              popHistory();
              setStep({ type: 'start' });
            }}
            onError={(message) => showFinalMessage(<ErrorMessage message={message} />)}
          />
        );
    }
  };

  return (
    <Box flexDirection="column">
      <WelcomeScreen version={context.version} directory={context.runDirectoryPath} />
      <Divider />
      {history}
      {renderStep()}
      {finalMessage}
    </Box>
  );
}
