import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import ResultScreen from './ResultScreen.js';

describe('ResultScreen', () => {
  test('renders success message when passed', () => {
    const { lastFrame } = render(
      <ResultScreen
        passed={true}
        levelNumber={3}
        hasNextLevel={true}
        scoreParts={{ warrior: 10, timeBonus: 5, clearBonus: 3 }}
        totalScore={18}
        grade={0.9}
        isEpic={false}
        previousScore={100}
      />,
    );
    const output = lastFrame()!;
    expect(output).toContain('Success');
    expect(output).toContain('Warrior Score: 10');
    expect(output).toContain('Time Bonus: 5');
    expect(output).toContain('Clear Bonus: 3');
  });

  test('renders failure message when not passed', () => {
    const { lastFrame } = render(
      <ResultScreen
        passed={false}
        levelNumber={3}
        hasNextLevel={true}
        scoreParts={{ warrior: 0, timeBonus: 0, clearBonus: 0 }}
        totalScore={0}
        grade={0}
        isEpic={false}
        previousScore={100}
      />,
    );
    const output = lastFrame()!;
    expect(output).toContain('failed');
  });

  test('renders congratulations when tower complete', () => {
    const { lastFrame } = render(
      <ResultScreen
        passed={true}
        levelNumber={5}
        hasNextLevel={false}
        scoreParts={{ warrior: 20, timeBonus: 10, clearBonus: 5 }}
        totalScore={35}
        grade={1.0}
        isEpic={false}
        previousScore={200}
      />,
    );
    const output = lastFrame()!;
    expect(output).toContain('CONGRATULATIONS');
  });
});
