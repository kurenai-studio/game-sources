import { render } from 'ink-testing-library';
import { describe, expect, test } from 'vitest';

import Header from './Header.js';

describe('Header', () => {
  test('renders warrior name and tower info', () => {
    const { lastFrame } = render(
      <Header warriorName="Aldric" towerName="The Narrow Path" levelNumber={3} score={125} />,
    );
    const output = lastFrame()!;
    expect(output).toContain('WarriorJS');
    expect(output).toContain('Aldric');
    expect(output).toContain('The Narrow Path');
    expect(output).toContain('Level 3');
    expect(output).toContain('125');
  });

  test('renders without level/score when not provided', () => {
    const { lastFrame } = render(<Header warriorName="Aldric" towerName="The Narrow Path" />);
    const output = lastFrame()!;
    expect(output).toContain('Aldric');
    expect(output).not.toContain('Level');
  });
});
