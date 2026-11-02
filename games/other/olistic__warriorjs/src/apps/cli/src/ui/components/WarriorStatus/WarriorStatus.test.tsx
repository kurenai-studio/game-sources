import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import WarriorStatus from './WarriorStatus.js';

describe('WarriorStatus', () => {
  test('renders health and score', () => {
    const { lastFrame } = render(<WarriorStatus health={12} maxHealth={20} score={25} />);
    const output = lastFrame()!;
    expect(output).toContain('❤');
    expect(output).toContain('12/20');
    expect(output).toContain('◆');
    expect(output).toContain('25');
  });
});
