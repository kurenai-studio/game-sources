import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import TowerCompleteScreen from './TowerCompleteScreen.js';

describe('TowerCompleteScreen', () => {
  test('renders average grade and per-level grades', () => {
    const { lastFrame } = render(
      <TowerCompleteScreen averageGrade={0.95} levelGrades={{ '1': 1.0, '2': 0.9 }} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('average grade');
    expect(output).toContain('Level 1');
    expect(output).toContain('Level 2');
  });
});
