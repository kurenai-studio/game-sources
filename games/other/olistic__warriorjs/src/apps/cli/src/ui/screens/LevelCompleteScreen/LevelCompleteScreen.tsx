import path from 'node:path';
import { Text } from 'ink';
import Link from 'ink-link';
import type React from 'react';
import { useMemo } from 'react';

import {
  type LevelCompleteAction,
  type LevelCompleteChoice,
  type LevelContext,
  type LevelReplay,
  type LevelReport,
} from '../../../types.js';
import Divider from '../../components/Divider/index.js';
import LevelLayout from '../../components/LevelLayout/index.js';
import ResultScreen from '../../components/ResultScreen/index.js';
import SelectPrompt from '../../components/SelectPrompt/index.js';
import buildMenuItems from './utils/buildMenuItems.js';

interface LevelCompleteScreenProps {
  replay: LevelReplay;
  context: LevelContext;
  report: LevelReport;
  action: LevelCompleteAction;
  onSelect: (value: LevelCompleteChoice) => void;
}

export default function LevelCompleteScreen({
  replay,
  context,
  report,
  action,
  onSelect,
}: LevelCompleteScreenProps): React.ReactElement {
  const menuItems = useMemo(() => buildMenuItems(report), [report]);

  return (
    <LevelLayout replay={replay} context={context}>
      <ResultScreen {...report} />
      <Divider />
      {action.type === 'prompt' && (
        <SelectPrompt message="" items={menuItems} onSelect={onSelect} />
      )}
      {action.type === 'next-level' && (
        <Text bold>
          {'See '}
          <Link url={`file://${path.resolve(action.readmePath)}`} fallback={false}>
            {action.readmePath}
          </Link>
          {' for instructions.'}
        </Text>
      )}
      {action.type === 'clue' && (
        <Text bold>
          {'See '}
          <Link url={`file://${path.resolve(action.readmePath)}`} fallback={false}>
            {action.readmePath}
          </Link>
          {' for the clues.'}
        </Text>
      )}
      {action.type === 'stay' && (
        <Text bold>You stayed on the current level. Aim for more points next time.</Text>
      )}
      {action.type === 'epic-mode' && <Text bold>Run warriorjs again to play epic mode.</Text>}
    </LevelLayout>
  );
}
